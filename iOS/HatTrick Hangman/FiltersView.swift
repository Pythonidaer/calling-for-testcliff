import RosterParser
import SwiftUI

/// `@AppStorage` keys for the player's filters, remembered on this device like
/// the web game's options. Decade and team store `"all"` for no filter, a
/// `Pool.key` for a decade or the current roster, and a team ID.
enum FilterKeys {
    static let league = "filter.league"
    static let decade = "filter.decade"
    static let team = "filter.team"
    static let all = "all"
}

extension RosterIndex {
    /// The pool for a stored decade key, or `nil` (all decades) for `"all"` or
    /// a decade the roster no longer has.
    func pool(forDecadeKey key: String) -> Pool? {
        switch Pool(key: key) {
        case .current: .current
        case .decade(let year) where decades.contains(year): .decade(year)
        default: nil
        }
    }

    /// The team for a stored team key, or `nil` (all teams) for `"all"` or a
    /// team with no records in `pool`.
    func team(forKey key: String, in pool: Pool?) -> String? {
        teams(in: pool).contains { $0.id == key } ? key : nil
    }
}

/// League, decade and team menus, with how many players they leave.
struct FiltersView: View {
    @Environment(RosterLoader.self) private var rosterLoader
    @AppStorage(FilterKeys.league) private var league = League.nhl
    @AppStorage(FilterKeys.decade) private var decade = FilterKeys.all
    @AppStorage(FilterKeys.team) private var team = FilterKeys.all

    var body: some View {
        if let index = rosterLoader.index {
            let pool = index.pool(forDecadeKey: decade)
            let teamID = index.team(forKey: team, in: pool)
            VStack(spacing: 8) {
                leagueMenu
                decadeMenu(index, pool: pool)
                teamMenu(index, pool: pool, teamID: teamID)
                Text("\(index.playerIDs(in: pool, team: teamID).count) players available")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            // Like the web game, a team without records in the new decade
            // resets to all teams.
            .onChange(of: decade) {
                if index.team(forKey: team, in: index.pool(forDecadeKey: decade)) == nil {
                    team = FilterKeys.all
                }
            }
        }
    }

    /// Every league, with only those that have roster data enabled.
    private var leagueMenu: some View {
        Menu {
            ForEach(League.allCases) { option in
                Button {
                    league = option
                } label: {
                    if option == league {
                        Label(option.name, systemImage: "checkmark")
                    } else {
                        Text(option.name)
                    }
                    Text(option.isAvailable ? option.fullName : "Coming Soon")
                }
                .disabled(!option.isAvailable)
            }
        } label: {
            FilterLabel(title: "League", value: league.name)
        }
        // Keeps the row's own colors instead of tinting the whole label.
        .buttonStyle(.plain)
    }

    private func decadeMenu(_ index: RosterIndex, pool: Pool?) -> some View {
        Menu {
            Picker("Decade", selection: $decade) {
                Text("All Decades").tag(FilterKeys.all)
                Text("Current Roster").tag(Pool.current.key)
                ForEach(index.decades, id: \.self) { year in
                    Text(verbatim: "\(year)s").tag(String(year))
                }
            }
        } label: {
            FilterLabel(title: "Decade", value: decadeName(pool))
        }
        // Keeps the row's own colors instead of tinting the whole label.
        .buttonStyle(.plain)
    }

    private func teamMenu(_ index: RosterIndex, pool: Pool?, teamID: String?) -> some View {
        Menu {
            Picker("Team", selection: $team) {
                Text("All Teams").tag(FilterKeys.all)
                ForEach(index.teams(in: pool)) { option in
                    Text(option.isCurrent ? option.name : "\(option.name) (historical)").tag(option.id)
                }
            }
        } label: {
            FilterLabel(title: "Team", value: teamID.flatMap { index.team($0)?.name } ?? "All Teams")
        }
        // Keeps the row's own colors instead of tinting the whole label.
        .buttonStyle(.plain)
    }

    private func decadeName(_ pool: Pool?) -> String {
        switch pool {
        case nil: "All Decades"
        case .current: "Current Roster"
        case .decade(let year): "\(year)s"
        }
    }
}

/// A filter's name and current choice, styled as one row.
private struct FilterLabel: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
                .foregroundStyle(.primary)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(.fill.quinary, in: .rect(cornerRadius: 12))
        .contentShape(.rect)
    }
}
