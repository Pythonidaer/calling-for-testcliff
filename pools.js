export function availableTeams(data,decade){const ids=decade==='all'?Object.keys(data.teams):Object.keys(data.pools[decade]||{});return ids.sort((a,b)=>data.teams[a].name.localeCompare(data.teams[b].name));}
export function playerPool(data,decade,team){const groups=decade==='all'?Object.entries(data.pools).filter(([d])=>d!=='current').map(([,v])=>v):[data.pools[decade]||{}];const ids=new Set();for(const group of groups)for(const [id,players]of Object.entries(group))if(team==='all'||id===team)for(const pid of players)ids.add(pid);return [...ids];}
const positionNames={C:'Center',L:'Left wing',R:'Right wing',D:'Defenseman',G:'Goalie'};
export function playerDetails(data,playerId,decade,team){
 const groups=decade==='all'?Object.entries(data.positions).filter(([d])=>d!=='current'): [[decade,data.positions[decade]||{}]];
 const matches=new Map();
 for(const [,group]of groups)for(const [tid,people]of Object.entries(group))if((team==='all'||team===tid)&&people[playerId]){if(!matches.has(tid))matches.set(tid,new Set());for(const code of people[playerId])matches.get(tid).add(code);}
 return [...matches].map(([tid,codes])=>({team:data.teams[tid].name,positions:[...codes].map(code=>positionNames[code]||code).sort()})).sort((a,b)=>a.team.localeCompare(b.team));
}
