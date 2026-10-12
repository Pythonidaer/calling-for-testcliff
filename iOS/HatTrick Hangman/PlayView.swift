import Hangman
import RosterParser
import SwiftData
import SwiftUI

/// Plays rounds against random players from the stored roster.
struct PlayView: View {
    private struct Round {
        /// The player's name as published, accents included, for the result.
        var playerName: String
        var game: HangmanGame
    }

    @Environment(\.modelContext) private var modelContext
    @State private var round: Round?

    var body: some View {
        VStack(spacing: 16) {
            ScoreboardView()
            if let round = Binding($round) {
                HangmanView(game: round.game)
                    // Covers the finished round's keyboard rather than taking
                    // space, so the drawing and answer stay where they were.
                    .overlay(alignment: .bottom) {
                        if round.wrappedValue.game.status != .playing {
                            result(for: round.wrappedValue)
                        }
                    }
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .task {
            if round == nil { nextRound() }
        }
        .onChange(of: round?.game.status) { old, new in
            guard old == .playing, let new, new != .playing else { return }
            record(won: new == .won)
        }
    }

    /// Records a finished round once, when it leaves the playing state.
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

    private func result(for round: Round) -> some View {
        VStack(spacing: 12) {
            Text(round.game.status == .won ? "Goal!" : "Game Over")
                .font(.title.bold())
            Text(round.playerName)
                .font(.headline)
            Button("Play Again", action: nextRound)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func nextRound() {
        do {
            let count = try modelContext.fetchCount(FetchDescriptor<RosterPlayer>())
            guard count > 0 else { return }
            var descriptor = FetchDescriptor<RosterPlayer>()
            descriptor.fetchOffset = Int.random(in: 0..<count)
            descriptor.fetchLimit = 1
            guard let player = try modelContext.fetch(descriptor).first else { return }
            withAnimation {
                round = Round(playerName: player.name, game: HangmanGame(answer: player.name))
            }
        } catch {
            print("Could not pick a player: \(error)")
        }
    }
}
