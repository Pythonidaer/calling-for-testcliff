import Foundation
import SwiftData

// Models reference each other by NHL ID rather than by relationship: a full
// import is ~35k rows, and SwiftData's inverse bookkeeping and batch-delete
// restrictions make relationships far slower to replace wholesale.

/// An NHL club identity. Defunct and renamed clubs are separate teams.
@Model public final class RosterTeam {
    /// NHL team ID.
    public var id: String
    public var name: String
    /// Three-letter NHL abbreviation, e.g. `NJD`.
    public var code: String

    public init(id: String, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
}

@Model public final class RosterPlayer {
    /// NHL player ID.
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// A player's record with one team in one pool, e.g. a 1980s Nordique or a
/// current Devil.
@Model public final class RosterMembership {
    /// `Pool.key`: a decade start year such as `"1980"`, or `"current"`.
    /// Stored as a string so it can be used in `#Predicate` filters.
    public var poolKey: String
    /// `RosterTeam.id`.
    public var teamID: String
    /// `RosterPlayer.id`.
    public var playerID: String
    /// `Position` raw values.
    public var positionCodes: [String]

    public var pool: Pool? { Pool(key: poolKey) }
    public var positions: [Position] { positionCodes.compactMap(Position.init(rawValue:)) }

    public init(pool: Pool, teamID: String, playerID: String, positions: [Position]) {
        self.poolKey = pool.key
        self.teamID = teamID
        self.playerID = playerID
        self.positionCodes = positions.map(\.rawValue)
    }
}

/// Details of the imported snapshot. There is at most one.
@Model public final class RosterSnapshot {
    /// The file's `updated` date in `YYYY-MM-DD` form, as shown to players. Not
    /// named `updated`, which Core Data reserves.
    public var snapshotDate: String
    public var historicalDefinition: String
    public var sources: [URL]
    /// Server ETag for the imported download; `nil` for a bundled import.
    public var etag: String?
    public var importedAt: Date

    init(snapshotDate: String, historicalDefinition: String, sources: [URL], etag: String?) {
        self.snapshotDate = snapshotDate
        self.historicalDefinition = historicalDefinition
        self.sources = sources
        self.etag = etag
        self.importedAt = .now
    }
}
