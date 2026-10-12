import Hangman
import RosterParser
import SwiftData
import SwiftUI

/// Plays rounds against random players from the stored roster.
///
/// The unfinished round is saved after every guess and resumed when the view
/// opens. Leaving an unfinished round asks whether to keep it for later or
/// discard it; discarding doesn't count as a loss.
struct PlayView: View {
    private struct Round {
        var playerID: String
        /// The player's name as published, accents included, for the result.
        var playerName: String
        var game: HangmanGame
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(RosterLoader.self) private var rosterLoader
    @AppStorage(FilterKeys.decade) private var decade = FilterKeys.all
    @AppStorage(FilterKeys.team) private var team = FilterKeys.all
    @State private var round: Round?
    @State private var confirmingExit = false

    var body: some View {
        Group {
            if let round = Binding($round) {
                // The result appears over the keyboard, on its screen when
                // the round is split across two.
                HangmanView(game: round.game) { _ in
                    result(for: round.wrappedValue)
                }
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Home", systemImage: "chevron.backward", action: exit)
            }
        }
        .confirmationDialog("Leave this round?", isPresented: $confirmingExit, titleVisibility: .visible) {
            Button("Keep for Later") { dismiss() }
            Button("Discard Round", role: .destructive) {
                deleteSavedRound()
                dismiss()
            }
        } message: {
            Text("Discarding the round doesn’t count as a loss.")
        }
        // Runs again once the roster index loads, in case Play was tapped first.
        .task(id: rosterLoader.index == nil) {
            if round == nil { resumeOrStartRound() }
        }
        .onChange(of: round?.game) { old, new in
            guard let new else { return }
            // Record a result once, when a round leaves the playing state.
            if let old, old.answer == new.answer, old.status == .playing, new.status != .playing {
                record(won: new.status == .won)
            }
            saveProgress()
        }
    }

    private func exit() {
        if round?.game.status == .playing {
            confirmingExit = true
        } else {
            dismiss()
        }
    }

    private func result(for round: Round) -> some View {
        VStack(spacing: 12) {
            Text(round.game.status == .won ? "Goal!" : "Game Over")
                .font(.title.bold())
            Text(round.playerName)
                .font(.headline)
            Button("Play Again", action: startRound)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func resumeOrStartRound() {
        do {
            if let saved = try SavedRound.current(in: modelContext) {
                round = Round(playerID: saved.playerID, playerName: saved.playerName, game: saved.game)
            } else {
                startRound()
            }
        } catch {
            print("Could not resume the round: \(error)")
            startRound()
        }
    }

    /// Starts a round with a random player matching the Home filters, avoiding
    /// the player just played when there's anyone else to pick.
    private func startRound() {
        guard let index = rosterLoader.index else { return }
        let pool = index.pool(forDecadeKey: decade)
        var candidates = index.playerIDs(in: pool, team: index.team(forKey: team, in: pool))
        if candidates.count > 1, let previous = round?.playerID {
            candidates.remove(previous)
        }
        guard let playerID = candidates.randomElement(), let name = index.name(of: playerID) else { return }
        withAnimation {
            round = Round(playerID: playerID, playerName: name, game: HangmanGame(answer: name))
        }
    }

    private func record(won: Bool) {
        do {
            let scoreboard = try Scoreboard.current(in: modelContext)
            if won {
                scoreboard.recordWin()
            } else {
                scoreboard.recordLoss()
            }
            try modelContext.save()
        } catch {
            print("Could not record the result: \(error)")
        }
    }

    /// Saves the round while it's being played, and removes it once it ends.
    private func saveProgress() {
        guard let round else { return }
        do {
            let saved = try SavedRound.current(in: modelContext)
            if round.game.status != .playing {
                if let saved { modelContext.delete(saved) }
            } else if let saved {
                saved.playerID = round.playerID
                saved.playerName = round.playerName
                saved.guesses = String(round.game.guessed)
            } else {
                modelContext.insert(SavedRound(
                    playerID: round.playerID,
                    playerName: round.playerName,
                    guesses: String(round.game.guessed)))
            }
            try modelContext.save()
        } catch {
            print("Could not save the round: \(error)")
        }
    }

    private func deleteSavedRound() {
        do {
            if let saved = try SavedRound.current(in: modelContext) {
                modelContext.delete(saved)
                try modelContext.save()
            }
        } catch {
            print("Could not discard the round: \(error)")
        }
    }
}
