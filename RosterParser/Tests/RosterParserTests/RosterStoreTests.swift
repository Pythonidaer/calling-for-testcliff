import Foundation
import SwiftData
import Testing
@testable import RosterParser

/// Serves canned responses to `RosterStore` and records the requests it sends.
final class StubServer: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responses: [(status: Int, headers: [String: String], body: Data)] = []
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        let next = Self.responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!, statusCode: next.status, httpVersion: nil, headerFields: next.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: next.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor @Suite(.serialized) struct RosterStoreTests {
    let container: ModelContainer
    let store: RosterStore
    let session: URLSession
    let snapshot: Data
    let url = URL(string: "https://example.test/data/rosters.json")!

    init() throws {
        container = try ModelContainer(
            for: Schema(RosterStore.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        store = RosterStore(modelContainer: container)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubServer.self]
        session = URLSession(configuration: configuration)
        snapshot = try Data(contentsOf: publishedSnapshot)
        StubServer.responses = []
        StubServer.requests = []
    }

    func count<T: PersistentModel>(_: T.Type) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<T>())
    }

    @Test func hasNoSnapshotBeforeFirstImport() async throws {
        #expect(try await store.updated() == nil)
    }

    @Test func importsEveryTeamPlayerAndMembership() async throws {
        let file = try JSONDecoder().decode(RosterFile.self, from: snapshot)
        let clock = ContinuousClock()
        let elapsed = try await clock.measure { try await store.importSnapshot(snapshot) }
        print("Imported snapshot in \(elapsed)")

        #expect(try count(RosterTeam.self) == file.teams.count)
        #expect(try count(RosterPlayer.self) == file.players.count)
        #expect(try count(RosterMembership.self) == file.pools.values.flatMap(\.values).joined().count)
        #expect(try await store.updated() == file.updated)
    }

    @Test func queriesCurrentRosterForTeam() async throws {
        try await store.importSnapshot(snapshot)
        let file = try JSONDecoder().decode(RosterFile.self, from: snapshot)
        let (teamID, playerIDs) = try #require(file.pools[.current]?.first)

        let current = Pool.current.key
        let memberships = try ModelContext(container).fetch(FetchDescriptor<RosterMembership>(
            predicate: #Predicate { $0.poolKey == current && $0.teamID == teamID }))
        #expect(Set(memberships.map(\.playerID)) == Set(playerIDs))
        #expect(memberships.allSatisfy { !$0.positions.isEmpty })
    }

    @Test func reimportReplacesInsteadOfDuplicating() async throws {
        try await store.importSnapshot(snapshot)
        let players = try count(RosterPlayer.self)
        let memberships = try count(RosterMembership.self)
        try await store.importSnapshot(snapshot)
        #expect(try count(RosterPlayer.self) == players)
        #expect(try count(RosterMembership.self) == memberships)
        #expect(try count(RosterSnapshot.self) == 1)
    }

    @Test func refreshImportsSnapshotThenSendsETag() async throws {
        StubServer.responses = [
            (200, ["ETag": "\"v1\""], snapshot),
            (304, [:], Data()),
        ]
        let file = try JSONDecoder().decode(RosterFile.self, from: snapshot)
        #expect(try await store.refresh(from: url, session: session) == .updated(file.updated))
        #expect(try await store.refresh(from: url, session: session) == .notModified)
        #expect(StubServer.requests[0].value(forHTTPHeaderField: "If-None-Match") == nil)
        #expect(StubServer.requests[1].value(forHTTPHeaderField: "If-None-Match") == "\"v1\"")
    }

    @Test func invalidDownloadKeepsImportedRoster() async throws {
        let updated = try await store.importSnapshot(snapshot)
        let players = try count(RosterPlayer.self)
        StubServer.responses = [(200, ["ETag": "\"bad\""], Data(#"{"updated":"x"}"#.utf8))]
        await #expect(throws: DecodingError.self) { try await store.refresh(from: url, session: session) }
        #expect(try await store.updated() == updated)
        #expect(try count(RosterPlayer.self) == players)
    }

    @Test func serverErrorKeepsImportedRoster() async throws {
        let updated = try await store.importSnapshot(snapshot)
        StubServer.responses = [(503, [:], Data())]
        await #expect(throws: RosterStore.RefreshError.self) {
            try await store.refresh(from: url, session: session)
        }
        #expect(try await store.updated() == updated)
    }

    @Test func bundledImportDoesNotSendETag() async throws {
        try await store.importSnapshot(snapshot)
        StubServer.responses = [(304, [:], Data())]
        _ = try await store.refresh(from: url, session: session)
        #expect(StubServer.requests[0].value(forHTTPHeaderField: "If-None-Match") == nil)
    }
}
