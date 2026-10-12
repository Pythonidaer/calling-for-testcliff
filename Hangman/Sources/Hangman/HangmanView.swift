import SwiftUI

/// Plays a round of hangman: the framed drawing with its counters, the answer,
/// a letter keyboard and a Give Up button. Letters can also be typed on a
/// hardware keyboard, and guesses play haptic feedback.
///
/// The view only changes `game`; check `game.status` to react when the round
/// ends. Hits use the environment's tint.
public struct HangmanView: View {
    @Binding var game: HangmanGame
    @FocusState private var focused: Bool

    public init(game: Binding<HangmanGame>) {
        _game = game
    }

    public var body: some View {
        VStack(spacing: 16) {
            rink

            AnswerView(game: game)
                .id(game.answer)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            LetterKeyboard(game: game) { game.guess($0) }

            Button("Give Up & Reveal", role: .destructive) {
                game.giveUp()
            }
            .disabled(game.status != .playing)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(characters: .letters, phases: .down) { press in
            guard press.modifiers.isEmpty || press.modifiers == .shift,
                  let letter = press.characters.first else { return .ignored }
            game.guess(letter)
            return .handled
        }
        .sensoryFeedback(trigger: game) { old, new in
            Self.feedback(from: old, to: new)
        }
    }

    /// The drawing in a rounded frame, with misses left along the top and the
    /// hat-trick count along the bottom.
    private var rink: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return GallowsView(bodyParts: game.bodyParts)
            // A new round gets a fresh drawing, so the gallows draws in again.
            .id(game.answer)
            .frame(maxHeight: 180)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(.fill.quinary, in: shape)
            .overlay(shape.strokeBorder(.primary, lineWidth: 2))
            .overlay(alignment: .topLeading) {
                Text("^[\(game.missesLeft) miss](inflect: true) left")
                    .foregroundStyle(game.missesLeft <= 1 && game.status == .playing ? .red : .primary)
                    .padding(14)
            }
            .overlay(alignment: .bottom) {
                Text(game.bonusEarned
                    ? "Bonus earned: +1 miss"
                    : "Hat trick: \(game.bonusProgress) / \(HangmanGame.bonusRun)")
                    .foregroundStyle(game.bonusEarned ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .padding(14)
            }
            .font(.subheadline.bold())
            .contentTransition(.numericText())
            .animation(.default, value: game.missesLeft)
            .animation(.default, value: game.bonusProgress)
    }

    /// Haptics for a change to the game: a light tap for a correct letter, a
    /// heavier one for a miss, success for the bonus or a win, and error for a
    /// loss, including giving up. Nothing plays when a new round starts.
    static func feedback(from old: HangmanGame, to new: HangmanGame) -> SensoryFeedback? {
        guard old.answer == new.answer else { return nil }
        if old.status == .playing, new.status == .won { return .success }
        if old.status == .playing, new.status == .lost { return .error }
        if !old.bonusEarned, new.bonusEarned { return .success }
        guard new.guessed.count > old.guessed.count, let letter = new.guessed.last else { return nil }
        return new.state(of: letter) == .hit ? .impact(weight: .light) : .impact(weight: .heavy)
    }
}

#Preview {
    @Previewable @State var game = HangmanGame(answer: "Jean-Gabriel Pageau")
    HangmanView(game: $game)
        .padding()
}
