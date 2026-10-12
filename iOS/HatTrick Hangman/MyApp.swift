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
                .modifier(WindowSizeLimits())
                .task { await rosterLoader.refresh() }
        }
        .defaultSize(width: WindowSizeLimits.idealWidth, height: WindowSizeLimits.idealHeight)
        .windowResizability(.contentSize)
        .modelContainer(container)
        .environment(rosterLoader)
    }
}

/// Keeps resizable windows (Mac, iPad, visionOS) phone-shaped: the layout is a
/// single portrait column that only adds empty space when wider. iPhone is
/// left alone, since its screen is the window and landscape is shorter than
/// the minimum height.
private struct WindowSizeLimits: ViewModifier {
    static let idealWidth: CGFloat = 420
    static let idealHeight: CGFloat = 800

    func body(content: Content) -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            content
        } else {
            limited(content)
        }
        #else
        limited(content)
        #endif
    }

    private func limited(_ content: Content) -> some View {
        content.frame(
            minWidth: 360, idealWidth: Self.idealWidth, maxWidth: 640,
            minHeight: 640, idealHeight: Self.idealHeight, maxHeight: 1200)
    }
}
