import Foundation

/// The roster snapshot as published in `data/rosters.json`.
///
/// Only used to decode and validate a download before it is imported into
/// SwiftData. IDs are the NHL's numeric IDs kept as strings, and `pools` and
/// `positions` are keyed by pool, then by team ID.
struct RosterFile: Codable, Sendable, Equatable {
    typealias TeamID = String
    typealias PlayerID = String

    struct Team: Codable, Sendable, Equatable {
        var name: String
        var code: String
    }

    /// Snapshot date in `YYYY-MM-DD` form.
    var updated: String
    var historicalDefinition: String
    var sources: [URL]
    var teams: [TeamID: Team]
    /// Player display names by player ID.
    var players: [PlayerID: String]
    /// Player IDs for each team, per pool.
    var pools: [Pool: [TeamID: [PlayerID]]]
    /// Recorded positions for each player on each team, per pool.
    var positions: [Pool: [TeamID: [PlayerID: [Position]]]]
}

extension RosterFile {
    enum ValidationError: Error, Equatable {
        case noPlayers
        case missingCurrentPool
        case unknownTeam(TeamID)
        case unknownPlayer(PlayerID)
        case missingPositions(PlayerID)
    }

    /// Checks the snapshot is complete enough to play: the same checks the web
    /// game makes, plus that every pooled team and player exists and has
    /// recorded positions.
    func validate() throws(ValidationError) {
        guard !players.isEmpty else { throw .noPlayers }
        guard pools[.current] != nil, positions[.current] != nil else {
            throw .missingCurrentPool
        }
        for (pool, teamPools) in pools {
            for (teamID, playerIDs) in teamPools {
                guard teams[teamID] != nil else { throw .unknownTeam(teamID) }
                for playerID in playerIDs {
                    guard players[playerID] != nil else { throw .unknownPlayer(playerID) }
                    guard positions[pool]?[teamID]?[playerID] != nil else {
                        throw .missingPositions(playerID)
                    }
                }
            }
        }
    }
}
