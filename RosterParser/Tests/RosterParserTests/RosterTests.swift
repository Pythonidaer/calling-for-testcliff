import Foundation
import Testing
@testable import RosterParser

/// The snapshot the website serves, two levels above this package.
let publishedSnapshot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .appending(path: "../../../data/rosters.json")
    .standardizedFileURL

@Suite struct RosterFileTests {
    let file: RosterFile

    init() throws {
        file = try JSONDecoder().decode(RosterFile.self, from: Data(contentsOf: publishedSnapshot))
    }

    @Test func decodesPublishedSnapshot() throws {
        try file.validate()
        #expect(!file.players.isEmpty)
        #expect(file.pools.keys.contains(.decade(1980)))
        #expect(file.pools.keys.contains(.current))
        #expect(file.teams.values.contains { $0.code == "NJD" })
    }

    @Test func roundTripsPoolKeys() throws {
        let reencoded = try JSONDecoder().decode(RosterFile.self, from: JSONEncoder().encode(file))
        #expect(reencoded == file)
    }

    @Test func rejectsPoolWithUnknownPlayer() throws {
        var file = file
        let teamID = try #require(file.pools[.current]?.keys.first)
        file.pools[.current]?[teamID]?.append("missing")
        #expect(throws: RosterFile.ValidationError.unknownPlayer("missing")) { try file.validate() }
    }

    @Test func rejectsPlayerWithoutPositions() throws {
        var file = file
        let teamID = try #require(file.pools[.current]?.keys.first)
        let playerID = try #require(file.pools[.current]?[teamID]?.first)
        file.positions[.current]?[teamID]?[playerID] = nil
        #expect(throws: RosterFile.ValidationError.missingPositions(playerID)) { try file.validate() }
    }

    @Test func rejectsSnapshotWithoutCurrentRosters() throws {
        var file = file
        file.pools[.current] = nil
        #expect(throws: RosterFile.ValidationError.missingCurrentPool) { try file.validate() }
    }

    @Test func parsesPoolKeys() {
        #expect(Pool(key: "1990") == .decade(1990))
        #expect(Pool(key: "current") == .current)
        #expect(Pool(key: "nineties") == nil)
        #expect(Pool.decade(1920).key == "1920")
    }
}
