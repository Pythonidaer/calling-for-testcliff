import Foundation
import Observation
import RosterParser
import SwiftData

/// Runs roster refreshes and tracks their progress for the UI.
@Observable final class RosterLoader {
    enum Phase: Equatable {
        case idle
        case refreshing
        /// The last refresh failed. `offline` means the device had no connection.
        case failed(offline: Bool)
    }

    private(set) var phase: Phase = .idle

    private let store: RosterStore
    private let url: URL

    init(container: ModelContainer, url: URL) {
        self.store = RosterStore(modelContainer: container)
        self.url = url
    }

    func refresh() async {
        guard phase != .refreshing else { return }
        phase = .refreshing
        do {
            _ = try await store.refresh(from: url)
            phase = .idle
        } catch {
            print("Roster refresh failed: \(error)")
            phase = .failed(offline: (error as? URLError)?.code == .notConnectedToInternet)
        }
    }
}
