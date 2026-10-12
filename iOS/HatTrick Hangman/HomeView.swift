import SwiftData
import SwiftUI

/// The start screen: scores and a button to play, or to resume a saved round.
struct HomeView: View {
    @Environment(RosterLoader.self) private var rosterLoader
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

                VStack(spacing: 8) {
                    ScoreboardView()
                    // Always laid out and only faded, so a refresh starting or
                    // finishing doesn't shift the screen.
                    Label {
                        Text("Updating roster…")
                    } icon: {
                        ProgressView()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .opacity(rosterLoader.phase == .refreshing ? 1 : 0)
                    .animation(.default, value: rosterLoader.phase)
                    .accessibilityHidden(rosterLoader.phase != .refreshing)
                }

                Spacer()

                VStack(spacing: 8) {
                    FiltersView()
                        .padding(.bottom, 8)

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
