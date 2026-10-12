import Foundation

/// A hockey league players can be drawn from. Only the NHL has roster data
/// today; the others are listed, disabled, so the menu is ready for more.
enum League: String, CaseIterable, Identifiable {
    case nhl
    case pwhl
    case ahl
    case khl
    case shl
    case liiga

    var id: Self { self }

    /// The short name shown in menus.
    var name: String {
        switch self {
        case .nhl: "NHL"
        case .pwhl: "PWHL"
        case .ahl: "AHL"
        case .khl: "KHL"
        case .shl: "SHL"
        case .liiga: "Liiga"
        }
    }

    var fullName: String {
        switch self {
        case .nhl: "National Hockey League"
        case .pwhl: "Professional Women’s Hockey League"
        case .ahl: "American Hockey League"
        case .khl: "Kontinental Hockey League"
        case .shl: "Swedish Hockey League"
        case .liiga: "Finnish Liiga"
        }
    }

    /// Whether the app has roster data for the league.
    var isAvailable: Bool {
        self == .nhl
    }
}
