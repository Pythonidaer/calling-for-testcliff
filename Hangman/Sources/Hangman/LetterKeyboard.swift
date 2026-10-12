import SwiftUI

/// A key for each letter A–Z, marked correct or wrong once guessed. Uses Liquid
/// Glass buttons where available.
struct LetterKeyboard: View {
    var game: HangmanGame
    var onGuess: (Character) -> Void

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 6)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(HangmanGame.alphabet, id: \.self) { letter in
                key(for: letter)
            }
        }
    }

    private func key(for letter: Character) -> some View {
        let state = game.state(of: letter)
        return Button {
            onGuess(letter)
        } label: {
            Text(String(letter))
                .font(.headline.monospaced())
                .strikethrough(state == .miss)
                .foregroundStyle(state == .miss ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity)
        }
        .modifier(KeyStyle(state: state))
        // Guessed keys stay enabled so they keep full color; repeat guesses are ignored.
        .disabled(game.status != .playing)
        .accessibilityLabel("Guess \(String(letter))")
        .accessibilityValue(state == .hit ? "Correct" : state == .miss ? "Wrong" : "")
    }
}

/// Glass keys on OS 26 and later, with correct letters prominent in the tint.
/// Earlier systems get outlined keys filled with the tint once correct.
private struct KeyStyle: ViewModifier {
    var state: HangmanGame.LetterState

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Group {
                if state == .hit {
                    content.buttonStyle(.glassProminent)
                } else {
                    content.buttonStyle(.glass)
                }
            }
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .controlSize(.large)
            // Glass alone barely shows the strikethrough, so wrong keys also fade.
            .opacity(state == .miss ? 0.35 : 1)
        } else {
            content.buttonStyle(OutlinedKeyStyle(state: state))
        }
    }
}

private struct OutlinedKeyStyle: ButtonStyle {
    var state: HangmanGame.LetterState

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6)
        configuration.label
            .frame(minHeight: 46)
            .foregroundStyle(state == .hit ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background(background, in: shape)
            .overlay {
                if state == .unused {
                    shape.strokeBorder(.primary, lineWidth: 1.5)
                }
            }
            .opacity(configuration.isPressed ? 0.6 : 1)
    }

    private var background: AnyShapeStyle {
        switch state {
        case .unused: AnyShapeStyle(.background)
        case .hit: AnyShapeStyle(.tint)
        case .miss: AnyShapeStyle(.quaternary)
        }
    }
}
