import Foundation

/// Which players belong to which team in which pool, for choosing filters and
/// picking players. Mirrors the web game's `pools.js`.
///
/// Built by `RosterStore.index()` off the main thread and small enough to keep
/// in memory, so filter menus and player picks don't query SwiftData.
public struct RosterIndex: Sendable {
    public struct Team: Sendable, Hashable, Identifiable {
        public let id: String
        public let name: String
        /// Whether the club has a current roster; defunct and renamed clubs don't.
        public let isCurrent: Bool
    }

    /// The snapshot's `updated` date in `YYYY-MM-DD` form.
    public let snapshotDate: String
    /// Decades with records, newest first.
    public let decades: [Int]

    private let teams: [String: Team]
    private let playerNames: [String: String]
    /// Player IDs by pool, then by team ID.
    private let members: [Pool: [String: Set<String>]]

    init(
        snapshotDate: String,
        teams: [(id: String, name: String)],
        playerNames: [String: String],
        memberships: [(pool: Pool, teamID: String, playerID: String)]
    ) {
        var members: [Pool: [String: Set<String>]] = [:]
        for membership in memberships {
            members[membership.pool, default: [:]][membership.teamID, default: []].insert(membership.playerID)
        }
        let currentTeams = Set(members[.current, default: [:]].keys)
        self.snapshotDate = snapshotDate
        self.teams = Dictionary(uniqueKeysWithValues: teams.map {
            ($0.id, Team(id: $0.id, name: $0.name, isCurrent: currentTeams.contains($0.id)))
        })
        self.playerNames = playerNames
        self.members = members
        self.decades = members.keys.compactMap { pool in
            if case .decade(let year) = pool { year } else { nil }
        }
        .sorted(by: >)
    }

    /// Teams to offer for a pool, sorted by name. `nil` means all decades,
    /// which offers every team.
    public func teams(in pool: Pool?) -> [Team] {
        let ids = pool.map { Array(members[$0, default: [:]].keys) } ?? Array(teams.keys)
        return ids.compactMap { teams[$0] }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func team(_ id: String) -> Team? {
        teams[id]
    }

    /// Players matching the filters, without duplicates. A `nil` pool means
    /// all decades, which leaves out current rosters; a `nil` team means all
    /// teams.
    public func playerIDs(in pool: Pool?, team: String?) -> Set<String> {
        let groups = pool.map { [members[$0] ?? [:]] }
            ?? members.filter { $0.key != .current }.map(\.value)
        var ids: Set<String> = []
        for group in groups {
            for (teamID, players) in group where team == nil || team == teamID {
                ids.formUnion(players)
            }
        }
        return ids
    }

    /// The player's name as published, accents included.
    public func name(of playerID: String) -> String? {
        playerNames[playerID]
    }
}
