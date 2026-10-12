import SwiftUI
import Testing
@testable import Hangman

/// Ported from the web game's `tests/game.test.js`, plus give-up and display rules.
@Suite struct HangmanGameTests {
    func play(_ answer: String, _ letters: String) -> HangmanGame {
        var game = HangmanGame(answer: answer)
        for letter in letters { game.guess(letter) }
        return game
    }

    @Test func sixMissesDrawAllPartsAndLose() {
        let game = play("Bobby Orr", "ACEFGH")
        #expect(game.status == .lost)
        #expect(game.bodyParts == 6)
    }

    @Test func threeCorrectEarnOneBonusAndSeventhMissLoses() {
        var game = play("Wayne Gretzky", "WAY")
        #expect(game.bonusEarned)
        for letter in "BCDFHI" { game.guess(letter) }
        #expect(game.status == .playing)
        #expect(game.bodyParts == 5)
        #expect(game.missesLeft == 1)
        game.guess("J")
        #expect(game.status == .lost)
        #expect(game.bodyParts == 6)
    }

    @Test func repeatGuessesAndFinishedGamesDoNotChange() {
        let once = play("Al MacInnis", "A")
        var repeated = once
        repeated.guess("A")
        #expect(repeated == once)

        var won = play("Al MacInnis", "ALMCINS")
        #expect(won.status == .won)
        let finished = won
        won.guess("Z")
        #expect(won == finished)
    }

    @Test func wrongLettersBreakBonusRun() {
        let game = play("Wayne Gretzky", "WABY")
        #expect(!game.bonusEarned)
        #expect(game.run == 1)
    }

    @Test func accentsAndPunctuationAreHandled() {
        let game = play("René Test-Name", "RNE")
        #expect(game.bonusEarned)
        #expect(game.answer == "RENE TEST-NAME")
        #expect(HangmanGame(answer: "Mats Sundin Ødegård Łukasz").answer == "MATS SUNDIN ODEGARD LUKASZ")
        #expect(game.isRevealed("-"))
        #expect(game.isRevealed(" "))
    }

    @Test func lowercaseGuessesCountAndNonLettersAreIgnored() {
        var game = play("Bobby Orr", "b")
        #expect(game.guessed == ["B"])
        game.guess("1")
        game.guess("É")
        #expect(game.guessed == ["B"])
    }

    @Test func givingUpLosesWithFullDrawing() {
        var game = play("Wayne Gretzky", "WAY")
        game.giveUp()
        #expect(game.status == .lost)
        #expect(game.bodyParts == 6)
        #expect(game.missesLeft == 0)
    }

    @Test func lettersRevealWhenGuessedOrRoundEnds() {
        var game = play("Bobby Orr", "B")
        #expect(game.isRevealed("B"))
        #expect(!game.isRevealed("O"))
        #expect(game.state(of: "B") == .hit)
        game.guess("Z")
        #expect(game.state(of: "Z") == .miss)
        #expect(game.state(of: "Q") == .unused)
        game.giveUp()
        #expect(game.isRevealed("O"))
    }

    @Test func bonusProgressCapsAtThree() {
        #expect(play("Wayne Gretzky", "WA").bonusProgress == 2)
        #expect(play("Wayne Gretzky", "WAYNE").bonusProgress == 3)
    }
}

@Suite struct HapticFeedbackTests {
    func game(_ answer: String, _ letters: String) -> HangmanGame {
        var game = HangmanGame(answer: answer)
        for letter in letters { game.guess(letter) }
        return game
    }

    func feedback(_ answer: String, from before: String, guess letter: Character) -> SensoryFeedback? {
        let old = game(answer, before)
        var new = old
        new.guess(letter)
        return HangmanView.feedback(from: old, to: new)
    }

    @Test func hitsAndMissesTapWithDifferentWeights() {
        #expect(feedback("Bobby Orr", from: "", guess: "B") == .impact(weight: .light))
        #expect(feedback("Bobby Orr", from: "", guess: "Z") == .impact(weight: .heavy))
    }

    @Test func bonusAndWinPlaySuccess() {
        #expect(feedback("Wayne Gretzky", from: "WA", guess: "Y") == .success)
        #expect(feedback("Al MacInnis", from: "ALMCIN", guess: "S") == .success)
    }

    @Test func lossAndGivingUpPlayError() {
        #expect(feedback("Bobby Orr", from: "ACEFG", guess: "H") == .error)
        let old = game("Bobby Orr", "B")
        var new = old
        new.giveUp()
        #expect(HangmanView.feedback(from: old, to: new) == .error)
    }

    @Test func repeatGuessesAndNewRoundsAreSilent() {
        #expect(feedback("Bobby Orr", from: "B", guess: "B") == nil)
        #expect(HangmanView.feedback(from: game("Bobby Orr", "BZ"), to: HangmanGame(answer: "Al MacInnis")) == nil)
    }
}
