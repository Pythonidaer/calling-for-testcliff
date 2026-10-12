import Foundation
import SwiftData

/// Imports roster snapshots into SwiftData and refreshes them from the server.
///
/// A download is decoded and validated before the store is touched, and the
/// old roster is replaced in a single save, so a failed or partial refresh
/// never costs the app its last good roster.
@ModelActor public actor RosterStore {
    /// The models to register in the app's `ModelContainer`.
    public static let models: [any PersistentModel.Type] = [
        RosterTeam.self, RosterPlayer.self, RosterMembership.self, RosterSnapshot.self,
    ]

    public enum RefreshResult: Sendable, Equatable {
        /// A new snapshot was imported; carries its `updated` date.
        case updated(String)
        case notModified
    }

    public enum RefreshError: Error {
        case badStatus(Int)
    }

    /// The imported snapshot's `updated` date, or `nil` before the first import.
    public func updated() throws -> String? {
        try currentSnapshot()?.snapshotDate
    }

    /// Imports `rosters.json` data, e.g. a copy bundled with the app. The next
    /// refresh downloads the published copy.
    @discardableResult
    public func importSnapshot(_ data: Data) throws -> String {
        try replace(with: decodeValidated(data), etag: nil)
    }

    /// Downloads the published snapshot and imports it if it changed since the
    /// last refresh.
    public func refresh(from url: URL, session: URLSession = .shared) async throws -> RefreshResult {
        var request = URLRequest(url: url, timeoutInterval: 15)
        if let etag = try currentSnapshot()?.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        if http?.statusCode == 304 { return .notModified }
        guard http?.statusCode == 200 else { throw RefreshError.badStatus(http?.statusCode ?? 0) }

        let file = try decodeValidated(data)
        return .updated(try replace(with: file, etag: http?.value(forHTTPHeaderField: "ETag")))
    }

    /// An in-memory index of the stored roster for filters and player picks,
    /// or `nil` before the first import.
    public func index() throws -> RosterIndex? {
        guard let snapshot = try currentSnapshot() else { return nil }
        let teams = try modelContext.fetch(FetchDescriptor<RosterTeam>())
        let players = try modelContext.fetch(FetchDescriptor<RosterPlayer>())
        let memberships = try modelContext.fetch(FetchDescriptor<RosterMembership>())
        return RosterIndex(
            snapshotDate: snapshot.snapshotDate,
            teams: teams.map { ($0.id, $0.name) },
            playerNames: Dictionary(players.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first }),
            memberships: memberships.compactMap { membership in
                membership.pool.map { ($0, membership.teamID, membership.playerID) }
            })
    }

    private func currentSnapshot() throws -> RosterSnapshot? {
        var descriptor = FetchDescriptor<RosterSnapshot>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func decodeValidated(_ data: Data) throws -> RosterFile {
        let file = try JSONDecoder().decode(RosterFile.self, from: data)
        try file.validate()
        return file
    }

    private func deleteAll<T: PersistentModel>(_: T.Type) throws {
        try modelContext.enumerate(FetchDescriptor<T>(), batchSize: 5000) { modelContext.delete($0) }
    }

    private func replace(with file: RosterFile, etag: String?) throws -> String {
        do {
            // Deleted one by one: batch deletes run immediately, so a failed save
            // would otherwise leave the store empty.
            try deleteAll(RosterSnapshot.self)
            try deleteAll(RosterMembership.self)
            try deleteAll(RosterPlayer.self)
            try deleteAll(RosterTeam.self)

            for (id, team) in file.teams {
                modelContext.insert(RosterTeam(id: id, name: team.name, code: team.code))
            }
            for (id, name) in file.players {
                modelContext.insert(RosterPlayer(id: id, name: name))
            }
            // validate() guarantees every player has recorded positions.
            for (pool, teamPools) in file.pools {
                for (teamID, playerIDs) in teamPools {
                    for playerID in playerIDs {
                        modelContext.insert(RosterMembership(
                            pool: pool,
                            teamID: teamID,
                            playerID: playerID,
                            positions: file.positions[pool]![teamID]![playerID]!))
                    }
                }
            }
            modelContext.insert(RosterSnapshot(
                snapshotDate: file.updated,
                historicalDefinition: file.historicalDefinition,
                sources: file.sources,
                etag: etag))
            try modelContext.save()
            return file.updated
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
