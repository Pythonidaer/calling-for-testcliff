import SwiftUI

/// The gallows and figure, drawn from the web game's SVG so both look alike.
///
/// Lines trace themselves in like pen strokes: the gallows when the view
/// appears, and each body part as it's added. Parts added together (such as
/// when giving up) draw one after another. With Reduce Motion, they fade in.
struct GallowsView: View {
    var bodyParts: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frameDrawn = false
    /// Parts shown before the latest change, so new parts draw in order.
    @State private var previousParts = 0

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / Self.viewBox.width, proxy.size.height / Self.viewBox.height)
            ZStack {
                // The rope draws last but sits under the beam, so their overlap stays clean.
                stroke(Self.rope, scale: scale, drawn: frameDrawn, style: AnyShapeStyle(.secondary))
                    .animation(drawAnimation.delay(0.2 * Double(Self.frame.count)), value: frameDrawn)
                ForEach(Self.frame.indices, id: \.self) { index in
                    stroke(Self.frame[index], scale: scale, drawn: frameDrawn, style: AnyShapeStyle(.primary))
                        .animation(drawAnimation.delay(0.2 * Double(index)), value: frameDrawn)
                }
                ForEach(Self.parts.indices, id: \.self) { index in
                    stroke(Self.parts[index], scale: scale, drawn: index < bodyParts, style: AnyShapeStyle(.primary))
                        .animation(drawAnimation.delay(0.3 * Double(max(0, index - previousParts))), value: bodyParts)
                }
            }
        }
        .aspectRatio(Self.viewBox.width / Self.viewBox.height, contentMode: .fit)
        .onAppear { frameDrawn = true }
        .onChange(of: bodyParts) { _, parts in previousParts = parts }
        .accessibilityElement()
        .accessibilityLabel("Gallows with \(bodyParts) of \(HangmanGame.maxMisses) body parts")
    }

    private var drawAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.35)
    }

    private func stroke(_ path: Path, scale: CGFloat, drawn: Bool, style: AnyShapeStyle) -> some View {
        ViewBoxShape(path: path, scale: scale)
            .trim(from: 0, to: drawn || reduceMotion ? 1 : 0)
            .stroke(style, style: StrokeStyle(lineWidth: 7 * scale, lineCap: .square))
            .opacity(reduceMotion && !drawn ? 0 : 1)
    }

    // Paths in the SVG's coordinate space (viewBox "28 12 198 188").
    nonisolated private static let viewBox = CGRect(x: 28, y: 12, width: 198, height: 188)

    /// Base, upright and beam, then brace, in drawing order. The rope follows.
    private static let frame = [
        line((42, 184), (193, 184)),
        line((65, 184), (65, 25), (181, 25)),
        line((65, 55), (96, 25)),
    ]

    private static let rope = line((181, 25), (181, 53))

    /// Head, body, two arms and two legs, in the order they appear.
    private static let parts = [
        // Starts at the top so the head draws down from the rope.
        Path { path in
            path.addArc(center: CGPoint(x: 181, y: 70), radius: 17,
                        startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
        },
        line((181, 87), (181, 134)),
        line((181, 98), (151, 118)),
        line((181, 98), (211, 118)),
        line((181, 134), (156, 168)),
        line((181, 134), (206, 168)),
    ]

    private static func line(_ points: (CGFloat, CGFloat)...) -> Path {
        Path { $0.addLines(points.map { CGPoint(x: $0.0, y: $0.1) }) }
    }

    /// Maps a path in viewBox coordinates into the view at `scale`.
    private struct ViewBoxShape: Shape {
        let path: Path
        let scale: CGFloat

        func path(in rect: CGRect) -> Path {
            path.applying(CGAffineTransform(translationX: -viewBox.minX, y: -viewBox.minY)
                .concatenating(CGAffineTransform(scaleX: scale, y: scale))
                .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
        }
    }
}

#Preview {
    @Previewable @State var parts = 0
    VStack {
        GallowsView(bodyParts: parts)
        Button("Add part") { parts = (parts + 1) % 7 }
        Button("All parts") { parts = 6 }
    }
    .padding()
}
