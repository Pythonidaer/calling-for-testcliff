import Playgrounds
import RosterParser
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(RosterLoader.self) private var rosterLoader
    @Query private var snapshots: [RosterSnapshot]

    var body: some View {
        if !snapshots.isEmpty {
            // A stored roster stays playable; background refreshes only add a note.
            HomeView()
                .safeAreaInset(edge: .top) {
                    if rosterLoader.phase == .refreshing {
                        Label {
                            Text("Updating roster…")
                        } icon: {
                            ProgressView()
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
        } else if case .failed(let offline) = rosterLoader.phase {
            ContentUnavailableView {
                Label("Couldn’t Load Rosters", systemImage: offline ? "wifi.slash" : "exclamationmark.triangle")
            } description: {
                Text(offline
                    ? "Connect to the internet to download NHL rosters."
                    : "The roster download didn’t work. Try again in a moment.")
            } actions: {
                Button("Try Again") {
                    Task { await rosterLoader.refresh() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ProgressView("Loading rosters…")
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Schema(RosterStore.models + MyApp.progressModels),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    ContentView()
        .modelContainer(container)
        .environment(RosterLoader(container: container, url: MyApp.rosterURL))
}

#Playground {
    _ = 1 + 2
}
