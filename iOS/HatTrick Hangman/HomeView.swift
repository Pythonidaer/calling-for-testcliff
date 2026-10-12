import SwiftData
import SwiftUI

/// The start screen: scores and a button to play, or to resume a saved round.
///
/// On OS 27.1 and later the title and scores and the play button are the
/// primary and secondary sides of an `ArrangementView`, matching the game
/// screen's split on a two-screen iPhone Duo. Earlier systems stack them in
/// one column.
struct HomeView: View {
    @Environment(RosterLoader.self) private var rosterLoader
    @Query private var savedRounds: [SavedRound]
    /// Restores the game screen when the system relaunches the app mid-round.
    @SceneStorage("isPlaying") private var isPlaying = false

    var body: some View {
        NavigationStack {
            arrangement
                .padding()
                .navigationDestination(isPresented: $isPlaying) {
                    PlayView()
                }
        }
    }

    /// Space around each side of the arrangement, inside the screen's padding.
    private static let sidePadding: CGFloat = 16

    @ViewBuilder private var arrangement: some View {
        if #available(iOS 27.1, macOS 27.1, visionOS 27.1, *) {
            // Each side is centered in its own space and padded on every edge,
            // so the two never meet at the divide between them.
            ArrangementView {
                header
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Self.sidePadding)
            } secondary: {
                playControls
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Self.sidePadding)
            }
        } else {
            VStack(spacing: 24) {
                Spacer()
                header
                Spacer()
                playControls
            }
        }
    }

    /// The title, scoreboard and roster refresh note.
    private var header: some View {
        VStack(spacing: 24) {
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
        }
    }

    /// The filters, then Play, or Resume Round with how far the saved round got.
    private var playControls: some View {
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
}
