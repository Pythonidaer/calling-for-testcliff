import Foundation

public enum Position: String, Codable, Sendable, CaseIterable {
    case center = "C"
    case leftWing = "L"
    case rightWing = "R"
    case defenseman = "D"
    case goalie = "G"

    public var name: String {
        switch self {
        case .center: "Center"
        case .leftWing: "Left wing"
        case .rightWing: "Right wing"
        case .defenseman: "Defenseman"
        case .goalie: "Goalie"
        }
    }
}

/// A player pool: a decade by its start year (1989–90 is in `.decade(1980)`),
/// or the current NHL rosters.
public enum Pool: Hashable, Sendable, Comparable, Codable, CodingKeyRepresentable {
    case decade(Int)
    case current

    public init?(key: String) {
        if key == "current" {
            self = .current
        } else if let year = Int(key) {
            self = .decade(year)
        } else {
            return nil
        }
    }

    /// The key used in `rosters.json` and stored on `RosterMembership.poolKey`.
    public var key: String {
        switch self {
        case .decade(let year): String(year)
        case .current: "current"
        }
    }

    public var codingKey: any CodingKey { PoolCodingKey(stringValue: key) }

    public init?<T: CodingKey>(codingKey: T) {
        self.init(key: codingKey.stringValue)
    }

    public init(from decoder: any Decoder) throws {
        let key = try decoder.singleValueContainer().decode(String.self)
        guard let pool = Pool(key: key) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown pool \(key)"))
        }
        self = pool
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    private struct PoolCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}
