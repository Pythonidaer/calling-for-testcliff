import SwiftUI

/// The answer as letter slots, wrapping between words. Letters left unguessed
/// when the round is lost are revealed in red.
///
/// Revealed letters drop into their slots. Letters revealed together, such as
/// repeats of a guess or the rest of the answer after a loss, land left to
/// right. With Reduce Motion, they fade in.
struct AnswerView: View {
    var game: HangmanGame

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Each word's characters with their position in the whole answer.
    private var words: [[(index: Int, character: Character)]] {
        var words: [[(index: Int, character: Character)]] = [[]]
        for (index, character) in game.answer.enumerated() {
            if character == " " {
                words.append([])
            } else {
                words[words.count - 1].append((index, character))
            }
        }
        return words.filter { !$0.isEmpty }
    }

    var body: some View {
        WordWrapLayout(spacing: 14, lineSpacing: 10) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                HStack(spacing: 4) {
                    ForEach(word, id: \.index) { slot(at: $0.index, for: $0.character) }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private func slot(at index: Int, for character: Character) -> some View {
        let guessable = HangmanGame.isGuessable(character)
        let revealed = game.isRevealed(character)
        let missed = guessable && revealed && !game.guessed.contains(character)
        return Text(String(character))
            .foregroundStyle(missed ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
            // Scoped to the letter's own effects, so layout changes elsewhere
            // (like the result card appearing) don't pick up the stagger delay.
            .animation(letterAnimation.delay(0.06 * Double(revealOrder(at: index)))) { letter in
                letter
                    .opacity(revealed ? 1 : 0)
                    .scaleEffect(revealed || reduceMotion ? 1 : 0.4)
                    .offset(y: revealed || reduceMotion ? 0 : -14)
            }
            .font(.title2.monospaced().bold())
            .frame(width: guessable ? 22 : 12)
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) {
                if guessable {
                    Rectangle().frame(height: 2)
                }
            }
    }

    private var letterAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.55)
    }

    /// Where a letter falls among the letters revealed with it: repeats of the
    /// same guess, or all unguessed letters when the round is lost.
    private func revealOrder(at index: Int) -> Int {
        let earlier = game.answer.prefix(index)
        let character = Array(game.answer)[index]
        if game.guessed.contains(character) {
            return earlier.filter { $0 == character }.count
        }
        return earlier.filter { HangmanGame.isGuessable($0) && !game.guessed.contains($0) }.count
    }

    private var accessibilityText: String {
        game.answer.split(separator: " ").map { word in
            word.map { game.isRevealed($0) ? String($0) : "blank" }.joined(separator: ", ")
        }
        .joined(separator: "; ")
    }
}

/// Places words left to right, centered, starting a new line when a word
/// doesn't fit.
struct WordWrapLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = lines(for: subviews, width: proposal.width ?? .infinity)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(for: subviews, width: bounds.width) {
            var x = bounds.midX - line.width / 2
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(for subviews: Subviews, width maxWidth: CGFloat) -> [Line] {
        var lines: [Line] = []
        var current = Line()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > maxWidth, !current.indices.isEmpty {
                lines.append(current)
                current = Line()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { lines.append(current) }
        return lines
    }
}
