import SwiftData
import SwiftUI

/// Wins, streak and best streak, with a context menu to reset them.
struct ScoreboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scoreboards: [Scoreboard]
    @State private var confirmingReset = false

    var body: some View {
        let scoreboard = scoreboards.first
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        HStack(spacing: 0) {
            stat("Wins", scoreboard?.wins ?? 0)
            Divider()
            stat("Streak", scoreboard?.streak ?? 0)
            Divider()
            stat("Best Streak", scoreboard?.bestStreak ?? 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 10)
        .background(.fill.quinary, in: shape)
        #if !os(macOS)
        .contentShape(.contextMenuPreview, shape)
        #endif
        .contextMenu {
            Button("Reset Stats", systemImage: "arrow.counterclockwise", role: .destructive) {
                confirmingReset = true
            }
        }
        .confirmationDialog(
            "Reset your wins, streak, and best streak?",
            isPresented: $confirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset Stats", role: .destructive, action: reset)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Reset Stats") { confirmingReset = true }
    }

    private func stat(_ label: LocalizedStringKey, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number.precision(.integerLength(2...)))
                .font(.title2.monospacedDigit().bold())
                .contentTransition(.numericText(value: Double(value)))
                .animation(.default, value: value)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func reset() {
        do {
            try Scoreboard.current(in: modelContext).reset()
            try modelContext.save()
        } catch {
            print("Could not reset stats: \(error)")
        }
    }
}
