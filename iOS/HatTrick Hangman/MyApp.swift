import RosterParser
import SwiftData
import SwiftUI

@main struct MyApp: App {
    static let rosterURL = URL(string: "https://pythonidaer.github.io/calling-for-testcliff/data/rosters.json")!

    /// The player's own data, kept apart from the downloadable roster.
    static let progressModels: [any PersistentModel.Type] = [Scoreboard.self, SavedRound.self]

    let container: ModelContainer
    @State private var rosterLoader: RosterLoader

    init() {
        do {
            // Scores live in their own store, so the roster store can be wiped
            // and downloaded again without losing a player's stats.
            container = try ModelContainer(
                for: Schema(RosterStore.models + Self.progressModels),
                configurations:
                    ModelConfiguration("Rosters", schema: Schema(RosterStore.models)),
                    ModelConfiguration("Scores", schema: Schema(Self.progressModels)))
        } catch {
            fatalError("Could not open the roster store: \(error)")
        }
        _rosterLoader = State(initialValue: RosterLoader(container: container, url: Self.rosterURL))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await rosterLoader.refresh() }
        }
        .modelContainer(container)
        .environment(rosterLoader)
    }
}
