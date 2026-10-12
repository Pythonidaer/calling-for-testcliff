import SwiftUI

/// Plays a round of hangman: the framed drawing with its counters, the answer,
/// a letter keyboard and a Give Up button. Letters can also be typed on a
/// hardware keyboard, and guesses play haptic feedback.
///
/// On OS 27.1 and later the board and the controls are the primary and
/// secondary sides of an `ArrangementView`, so a two-screen iPhone Duo can show
/// the drawing on one screen and the keyboard on the other. Earlier systems
/// stack them in one column.
///
/// The view only changes `game`; check `game.status` to react when the round
/// ends. An optional `result` view, such as the answer and a Play Again button,
/// appears over the controls once the round is over, so on two screens it
/// stays with the keyboard. Hits use the environment's tint.
public struct HangmanView<Result: View>: View {
    @Binding var game: HangmanGame
    private let result: (HangmanGame) -> Result
    @FocusState private var focused: Bool

    public init(game: Binding<HangmanGame>, @ViewBuilder result: @escaping (HangmanGame) -> Result) {
        _game = game
        self.result = result
    }

    public var body: some View {
        arrangement
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
            .modifier(GuessFeedback(game: game))
    }

    @ViewBuilder private var arrangement: some View {
        if #available(iOS 27.1, macOS 27.1, visionOS 27.1, *) {
            // Each side fills its own space: the rink and the keys grow with it.
            // Padding on every edge keeps the two sides apart at the divide.
            ArrangementView {
                board(fillsHeight: true)
                    .padding(16)
            } secondary: {
                controls(fillsHeight: true)
                    .padding(16)
            }
        } else {
            VStack(spacing: 16) {
                board(fillsHeight: false)
                Spacer(minLength: 0)
                controls(fillsHeight: false)
            }
        }
    }

    /// What the player watches: the framed drawing and the answer. With
    /// `fillsHeight`, the rink takes whatever height the answer leaves.
    private func board(fillsHeight: Bool) -> some View {
        VStack(spacing: 16) {
            rink(maxDrawingHeight: fillsHeight ? .infinity : 180)

            AnswerView(game: game)
                .id(game.answer)
                .frame(maxWidth: .infinity)
        }
    }

    /// What the player touches: the letter keyboard and Give Up. With
    /// `fillsHeight`, the keys grow to fill the height above Give Up.
    private func controls(fillsHeight: Bool) -> some View {
        VStack(spacing: 16) {
            LetterKeyboard(game: game, fillsHeight: fillsHeight) { game.guess($0) }

            Button("Give Up & Reveal", role: .destructive) {
                game.giveUp()
            }
            .disabled(game.status != .playing)
        }
        // Covers the finished round's keyboard rather than taking space, so
        // the drawing and answer stay where they were.
        .overlay(alignment: .bottom) {
            if game.status != .playing {
                result(game)
            }
        }
    }

    /// The drawing in a rounded frame, with misses left along the top and the
    /// hat-trick count along the bottom.
    private func rink(maxDrawingHeight: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return GallowsView(bodyParts: game.bodyParts)
            // A new round gets a fresh drawing, so the gallows draws in again.
            .id(game.answer)
            .frame(maxHeight: maxDrawingHeight)
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
    @available(visionOS 26.0, *)
    static func feedback(from old: HangmanGame, to new: HangmanGame) -> SensoryFeedback? {
        guard old.answer == new.answer else { return nil }
        if old.status == .playing, new.status == .won { return .success }
        if old.status == .playing, new.status == .lost { return .error }
        if !old.bonusEarned, new.bonusEarned { return .success }
        guard new.guessed.count > old.guessed.count, let letter = new.guessed.last else { return nil }
        return new.state(of: letter) == .hit ? .impact(weight: .light) : .impact(weight: .heavy)
    }
}

extension HangmanView where Result == EmptyView {
    /// A round with no result view; check `game.status` to show one elsewhere.
    public init(game: Binding<HangmanGame>) {
        self.init(game: game) { _ in EmptyView() }
    }
}

/// Plays `HangmanView.feedback` haptics. Earlier visionOS releases have no
/// sensory feedback API, and Vision Pro has no haptics to play anyway.
private struct GuessFeedback: ViewModifier {
    var game: HangmanGame

    func body(content: Content) -> some View {
        if #available(visionOS 26.0, *) {
            content.sensoryFeedback(trigger: game) { old, new in
                HangmanView<EmptyView>.feedback(from: old, to: new)
            }
        } else {
            content
        }
    }
}

#Preview {
    @Previewable @State var game = HangmanGame(answer: "Jean-Gabriel Pageau")
    HangmanView(game: $game)
        .padding()
}
