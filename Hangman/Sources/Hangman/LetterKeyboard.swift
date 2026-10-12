import SwiftUI

/// A key for each letter A–Z, marked correct or wrong once guessed. Uses Liquid
/// Glass where available.
///
/// By default keys are 46pt tall and the keyboard takes only the height it
/// needs. With `fillsHeight`, as on its own side of an arrangement, the keys
/// grow to fill the available height, from 40 to 88pt.
struct LetterKeyboard: View {
    var game: HangmanGame
    var fillsHeight = false
    var onGuess: (Character) -> Void

    private static let spacing: CGFloat = 6
    private static let minimumKeyWidth: CGFloat = 44

    var body: some View {
        if fillsHeight {
            GeometryReader { proxy in
                let rows = Self.rowCount(forWidth: proxy.size.width)
                let height = (proxy.size.height - Self.spacing * CGFloat(rows - 1)) / CGFloat(rows)
                grid(keyHeight: min(88, max(40, height)))
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        } else {
            grid(keyHeight: 46)
        }
    }

    private func grid(keyHeight: CGFloat) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: Self.minimumKeyWidth), spacing: Self.spacing)],
            spacing: Self.spacing
        ) {
            ForEach(HangmanGame.alphabet, id: \.self) { letter in
                key(for: letter, height: keyHeight)
            }
        }
    }

    /// Rows the adaptive grid uses at `width`: as many 44pt columns as fit.
    private static func rowCount(forWidth width: CGFloat) -> Int {
        let columns = max(1, Int((width + spacing) / (minimumKeyWidth + spacing)))
        return (HangmanGame.alphabet.count + columns - 1) / columns
    }

    private func key(for letter: Character, height: CGFloat) -> some View {
        let state = game.state(of: letter)
        return Button {
            onGuess(letter)
        } label: {
            // Colors come from the key style, so each style can set them for its background.
            Text(String(letter))
                .font(height > 60 ? .title2.monospaced().weight(.semibold) : .headline.monospaced())
                .strikethrough(state == .miss)
                .frame(maxWidth: .infinity, minHeight: height)
        }
        .modifier(KeyStyle(state: state))
        // Guessed keys stay enabled so they keep full color; repeat guesses are ignored.
        .disabled(game.status != .playing)
        .accessibilityLabel("Guess \(String(letter))")
        .accessibilityValue(state == .hit ? "Correct" : state == .miss ? "Wrong" : "")
    }
}

/// Glass keys on iOS and macOS 26 and later, with correct letters tinted.
/// visionOS has no glass effect for controls (its windows are already glass),
/// so it uses bordered keys. Earlier systems get outlined keys filled with the
/// tint once correct.
private struct KeyStyle: ViewModifier {
    var state: HangmanGame.LetterState

    func body(content: Content) -> some View {
        #if os(visionOS)
        Group {
            if state == .hit {
                content.buttonStyle(.borderedProminent)
            } else {
                content.buttonStyle(.bordered)
            }
        }
        .buttonBorderShape(.roundedRectangle(radius: 10))
        .opacity(state == .miss ? 0.35 : 1)
        #else
        if #available(iOS 26.0, macOS 26.0, *) {
            content.buttonStyle(GlassKeyStyle(state: state))
        } else {
            content.buttonStyle(OutlinedKeyStyle(state: state))
        }
        #endif
    }
}

#if !os(visionOS)
/// Draws each key's glass as a background shape and the letter on top of it.
/// Letters drawn inside the glass (by the `.glass` button styles or
/// `.glassEffect` on the label) were clipped on narrow keys.
@available(iOS 26.0, macOS 26.0, *)
private struct GlassKeyStyle: ButtonStyle {
    var state: HangmanGame.LetterState

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        configuration.label
            .foregroundStyle(foreground)
            .background {
                shape
                    .fill(.clear)
                    .glassEffect(glass, in: shape)
            }
            .contentShape(shape)
            // Glass alone barely shows the strikethrough, so wrong keys also fade.
            .opacity(state == .miss ? 0.35 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }

    private var glass: Glass {
        state == .hit ? .regular.tint(.accentColor) : .regular
    }

    private var foreground: AnyShapeStyle {
        switch state {
        case .unused: AnyShapeStyle(.primary)
        case .hit: AnyShapeStyle(.white)
        case .miss: AnyShapeStyle(.secondary)
        }
    }
}
#endif

private struct OutlinedKeyStyle: ButtonStyle {
    var state: HangmanGame.LetterState

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6)
        configuration.label
            .foregroundStyle(foreground)
            .background(background, in: shape)
            .overlay {
                if state == .unused {
                    shape.strokeBorder(.primary, lineWidth: 1.5)
                }
            }
            .opacity(configuration.isPressed ? 0.6 : 1)
    }

    private var foreground: AnyShapeStyle {
        switch state {
        case .unused: AnyShapeStyle(.primary)
        case .hit: AnyShapeStyle(.white)
        case .miss: AnyShapeStyle(.secondary)
        }
    }

    private var background: AnyShapeStyle {
        switch state {
        case .unused: AnyShapeStyle(.background)
        case .hit: AnyShapeStyle(.tint)
        case .miss: AnyShapeStyle(.quaternary)
        }
    }
}
