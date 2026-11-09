// Menus use one sentinel for every decade and every team.
const ALL_FILTER = 'all';

// Roster snapshot. Not a historical decade.
const CURRENT_ROSTER = 'current';

const POSITION_NAMES = Object.freeze({
  C: 'Center',
  L: 'Left wing',
  R: 'Right wing',
  D: 'Defenseman',
  G: 'Goalie',
});

export function availableTeams(data, decade) {
  const teamIds = teamIdsForDecade(data, decade);

  teamIds.sort((leftId, rightId) =>
    data.teams[leftId].name.localeCompare(data.teams[rightId].name),
  );
  return teamIds;
}

export function playerPool(data, decade, team) {
  const playerIds = new Set();

  for (const playersByTeam of decadeRecords(data.pools, decade)) {
    for (const [teamId, rosterPlayerIds] of Object.entries(playersByTeam)) {
      if (!isTeamSelected(team, teamId)) continue;

      for (const playerId of rosterPlayerIds) {
        playerIds.add(playerId);
      }
    }
  }

  return [...playerIds];
}

export function playerDetails(data, playerId, decade, team) {
  const codesByTeam = codesForPlayer(data, playerId, decade, team);
  return sortedDetails(data, codesByTeam);
}

// All decades lists every franchise. One decade lists clubs with a pool in that decade.
function teamIdsForDecade(data, decade) {
  if (decade === ALL_FILTER) {
    return Object.keys(data.teams);
  }

  return Object.keys(data.pools[decade] || {});
}

// Historical appearances only. Current-roster newcomers stay under Current roster.
function decadeRecords(recordsByDecade, decade) {
  if (decade !== ALL_FILTER) {
    return [recordsByDecade[decade] || {}];
  }

  const included = [];

  for (const [decadeKey, records] of Object.entries(recordsByDecade)) {
    if (decadeKey === CURRENT_ROSTER) continue;
    included.push(records);
  }

  return included;
}

function isTeamSelected(teamFilter, teamId) {
  return teamFilter === ALL_FILTER || teamId === teamFilter;
}

function codesForPlayer(data, playerId, decade, team) {
  const codesByTeam = new Map();

  for (const positionsByPlayerByTeam of decadeRecords(data.positions, decade)) {
    for (const [teamId, codesByPlayer] of Object.entries(
      positionsByPlayerByTeam,
    )) {
      const codes = codesByPlayer[playerId];
      if (!isTeamSelected(team, teamId) || !codes) continue;

      let codesForTeam = codesByTeam.get(teamId);

      if (!codesForTeam) {
        codesForTeam = new Set();
        codesByTeam.set(teamId, codesForTeam);
      }

      for (const code of codes) {
        codesForTeam.add(code);
      }
    }
  }

  return codesByTeam;
}

function sortedDetails(data, codesByTeam) {
  const details = [...codesByTeam].map(([teamId, codes]) => ({
    team: data.teams[teamId].name,
    positions: positionLabels(codes),
  }));

  details.sort((left, right) => left.team.localeCompare(right.team));
  return details;
}

function positionLabels(codes) {
  // Unlisted codes stay visible as stored.
  const labels = [...codes].map((code) => POSITION_NAMES[code] || code);
  labels.sort();
  return labels;
}
