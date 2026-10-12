import RosterParser
import SwiftData
import SwiftUI

@main struct MyApp: App {
    static let rosterURL = URL(string: "https://pythonidaer.github.io/calling-for-testcliff/data/rosters.json")!

    let container: ModelContainer
    @State private var rosterLoader: RosterLoader

    init() {
        do {
            container = try ModelContainer(for: Schema(RosterStore.models))
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
