import Foundation
import Observation
import RosterParser
import SwiftData

/// Runs roster refreshes, tracks their progress for the UI, and keeps an index
/// of the stored roster for filters and player picks.
@Observable final class RosterLoader {
    enum Phase: Equatable {
        case idle
        case refreshing
        /// The last refresh failed. `offline` means the device had no connection.
        case failed(offline: Bool)
    }

    private(set) var phase: Phase = .idle
    /// The stored roster's index, or `nil` before the first import.
    private(set) var index: RosterIndex?

    private let store: RosterStore
    private let url: URL

    init(container: ModelContainer, url: URL) {
        self.store = RosterStore(modelContainer: container)
        self.url = url
    }

    func refresh() async {
        guard phase != .refreshing else { return }
        // The stored roster is usable while the download runs.
        if index == nil { await loadIndex() }
        phase = .refreshing
        do {
            if case .updated = try await store.refresh(from: url) {
                await loadIndex()
            }
            phase = .idle
        } catch {
            print("Roster refresh failed: \(error)")
            phase = .failed(offline: (error as? URLError)?.code == .notConnectedToInternet)
        }
    }

    private func loadIndex() async {
        do {
            index = try await store.index()
        } catch {
            print("Could not index the roster: \(error)")
        }
    }
}
