import Foundation
import SwiftData

/// The player's saved scores, matching the web game: total wins, the current
/// winning streak, and the best streak. There is at most one.
@Model final class Scoreboard {
    var wins = 0
    var streak = 0
    var bestStreak = 0

    init() {}

    func recordWin() {
        wins += 1
        streak += 1
        bestStreak = max(bestStreak, streak)
    }

    /// Any loss, including giving up, ends the streak.
    func recordLoss() {
        streak = 0
    }

    func reset() {
        wins = 0
        streak = 0
        bestStreak = 0
    }

    /// The saved scoreboard, created on first use.
    static func current(in context: ModelContext) throws -> Scoreboard {
        if let scoreboard = try context.fetch(FetchDescriptor<Scoreboard>()).first {
            return scoreboard
        }
        let scoreboard = Scoreboard()
        context.insert(scoreboard)
        return scoreboard
    }
}
