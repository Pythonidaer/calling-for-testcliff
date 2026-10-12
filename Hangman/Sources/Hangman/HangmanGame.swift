import Foundation

/// One round of hangman, following the rules in the web game's `game.js`:
///
/// - Only the letters A–Z are guessed. Spaces and punctuation are shown, and
///   accented letters are guessed without the accent.
/// - Six misses lose the round.
/// - Three correct guesses in a row earn one extra miss, once per round. While
///   the extra miss is in hand, the sixth miss leaves the drawing one part short
///   and the seventh miss loses.
/// - Giving up loses the round.
public struct HangmanGame: Hashable, Sendable {
    public enum Status: Hashable, Sendable {
        case playing, won, lost
    }

    public enum LetterState: Hashable, Sendable {
        case unused, hit, miss
    }

    /// Misses allowed before the bonus, and body parts in the full drawing.
    public static let maxMisses = 6
    /// Correct guesses in a row that earn the bonus miss.
    public static let bonusRun = 3
    /// The letters that can be guessed.
    public static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// The normalized answer: uppercase, with accents removed.
    public private(set) var answer: String
    /// Guessed letters in the order they were chosen.
    public private(set) var guessed: [Character] = []
    public private(set) var misses = 0
    /// Correct guesses since the last miss.
    public private(set) var run = 0
    public private(set) var bonusEarned = false
    public private(set) var status = Status.playing

    public init(answer: String) {
        self.answer = Self.normalize(answer)
    }

    /// Uppercases `text` and removes accents, so `"José Théodore"` becomes
    /// `"JOSE THEODORE"`. Ø and Ł have no decomposed form and map directly.
    public static func normalize(_ text: String) -> String {
        let mapped = text
            .replacingOccurrences(of: "ø", with: "o")
            .replacingOccurrences(of: "Ø", with: "O")
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "L")
        let scalars = mapped.decomposedStringWithCanonicalMapping.unicodeScalars
            .filter { !(0x300...0x36F).contains($0.value) }
        return String(String.UnicodeScalarView(scalars)).uppercased()
    }

    /// Whether `character` is a guessable letter rather than shown punctuation.
    public static func isGuessable(_ character: Character) -> Bool {
        alphabet.contains(character)
    }

    /// Guesses a letter. Ignored once the round is over, for anything other
    /// than A–Z (either case), and for letters already guessed.
    public mutating func guess(_ letter: Character) {
        let letter = Character(letter.uppercased())
        guard status == .playing, Self.isGuessable(letter), !guessed.contains(letter) else { return }
        guessed.append(letter)
        if answer.contains(letter) {
            run += 1
            if run >= Self.bonusRun { bonusEarned = true }
        } else {
            misses += 1
            run = 0
        }
        if answer.allSatisfy({ !Self.isGuessable($0) || guessed.contains($0) }) {
            status = .won
        } else if misses >= allowedMisses {
            status = .lost
        }
    }

    /// Ends the round as a loss.
    public mutating func giveUp() {
        guard status == .playing else { return }
        misses = allowedMisses
        status = .lost
    }

    /// Misses that end the round: six, or seven with the bonus.
    public var allowedMisses: Int { Self.maxMisses + (bonusEarned ? 1 : 0) }

    public var missesLeft: Int { allowedMisses - misses }

    /// Body parts to draw, from 0 to `maxMisses`. The bonus miss holds the
    /// drawing one part short until the round is lost.
    public var bodyParts: Int {
        min(Self.maxMisses, misses - (bonusEarned && misses >= Self.maxMisses ? 1 : 0))
    }

    /// Progress toward the bonus, from 0 to `bonusRun`.
    public var bonusProgress: Int { min(Self.bonusRun, run) }

    public func state(of letter: Character) -> LetterState {
        guard guessed.contains(letter) else { return .unused }
        return answer.contains(letter) ? .hit : .miss
    }

    /// Whether a character of the answer is visible: punctuation always is,
    /// letters once guessed or when the round is over.
    public func isRevealed(_ character: Character) -> Bool {
        !Self.isGuessable(character) || guessed.contains(character) || status != .playing
    }
}
