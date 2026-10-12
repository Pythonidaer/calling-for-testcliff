import Foundation
import SwiftData
import Testing
@testable import RosterParser

/// Ported from the web game's `tests/pools.test.js`, against the published snapshot.
@Suite struct RosterIndexTests {
    let index: RosterIndex

    init() async throws {
        let container = try ModelContainer(
            for: Schema(RosterStore.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = RosterStore(modelContainer: container)
        try await store.importSnapshot(Data(contentsOf: publishedSnapshot))
        index = try #require(try await store.index())
    }

    func teamID(_ name: String) throws -> String {
        try #require(index.teams(in: nil).first { $0.name == name }?.id)
    }

    func names(_ pool: Pool?, _ team: String?) -> Set<String> {
        Set(index.playerIDs(in: pool, team: team).compactMap(index.name(of:)))
    }

    @Test func realHistoricalTeamAndDecadeMembership() throws {
        let nordiques = try teamID("Quebec Nordiques")
        #expect(names(.decade(1980), nordiques).contains("Joe Sakic"))
        #expect(!names(.decade(1980), nordiques).contains("Wayne Gretzky"))
        let avalanche = try teamID("Colorado Avalanche")
        #expect(names(.decade(1990), avalanche).contains("Joe Sakic"))
        #expect(!index.teams(in: .decade(1960)).contains { $0.id == nordiques })
    }

    @Test func allDecadesIsEveryDecadeWithoutCurrentRosters() {
        let all = index.playerIDs(in: nil, team: nil)
        #expect(all.count > 8000)
        #expect(all == Set(index.decades.flatMap { index.playerIDs(in: .decade($0), team: nil) }))
    }

    @Test func currentClubsExcludeHistoricalIdentities() throws {
        let current = index.teams(in: .current)
        #expect(current.count == 32)
        let allCurrent = current.allSatisfy(\.isCurrent)
        #expect(allCurrent)
        #expect(!current.contains { $0.name == "Quebec Nordiques" })
        let nordiques = try teamID("Quebec Nordiques")
        #expect(index.team(nordiques)?.isCurrent == false)
    }

    @Test func decadesAreNewestFirstFromThe1910s() {
        #expect(index.decades.first == index.decades.max())
        #expect(index.decades.last == 1910)
    }

    @Test func everyPooledPlayerHasAFullName() {
        for id in index.playerIDs(in: nil, team: nil).union(index.playerIDs(in: .current, team: nil)) {
            #expect(index.name(of: id)?.contains(" ") == true)
        }
    }

    @Test func teamsSortLikeTheWebGame() {
        let names = index.teams(in: nil).map(\.name)
        let montreal = names.firstIndex(of: "Montréal Canadiens")
        let maroons = names.firstIndex(of: "Montreal Maroons")
        #expect(montreal != nil && maroons != nil)
        #expect(montreal! < maroons!)
    }
}
