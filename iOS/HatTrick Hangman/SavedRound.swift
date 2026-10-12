import Foundation
import Hangman
import SwiftData

/// The unfinished round, saved after every guess so it can be resumed after
/// leaving it or relaunching the app. There is at most one, and it's deleted
/// once the round ends or is discarded.
@Model final class SavedRound {
    var playerID: String
    /// The name as published, accents included. Stored rather than looked up
    /// so a roster refresh can't change or remove the answer mid-round.
    var playerName: String
    /// Guessed letters in order. Replaying them rebuilds misses and the bonus.
    var guesses: String

    init(playerID: String, playerName: String, guesses: String) {
        self.playerID = playerID
        self.playerName = playerName
        self.guesses = guesses
    }

    /// The round as it was when last saved.
    var game: HangmanGame {
        var game = HangmanGame(answer: playerName)
        for letter in guesses { game.guess(letter) }
        return game
    }

    /// The saved round, if there is one.
    static func current(in context: ModelContext) throws -> SavedRound? {
        try context.fetch(FetchDescriptor<SavedRound>()).first
    }
}
