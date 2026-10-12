import SwiftData
import SwiftUI

/// The start screen: scores and a button to play, or to resume a saved round.
struct HomeView: View {
    @Query private var savedRounds: [SavedRound]
    /// Restores the game screen when the system relaunches the app mid-round.
    @SceneStorage("isPlaying") private var isPlaying = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "figure.hockey")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                    Text("Hat Trick Hangman")
                        .font(.largeTitle.bold())
                    Text("Guess the NHL player, one letter at a time.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                ScoreboardView()

                Spacer()

                VStack(spacing: 8) {
                    Button {
                        isPlaying = true
                    } label: {
                        Label(savedRounds.isEmpty ? "Play" : "Resume Round", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let saved = savedRounds.first {
                        Text("^[\(saved.guesses.count) letter](inflect: true) guessed so far")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationDestination(isPresented: $isPlaying) {
                PlayView()
            }
        }
    }
}
