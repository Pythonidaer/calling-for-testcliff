"""Build checked NHL player pools; refresh the open decade/current roster daily.
Historical pools mean regular-season appearances, grouped by season START year.
Sources are NHL's own stats service and roster service. Failures abort the write.
"""
import argparse, concurrent.futures, datetime, json, pathlib, subprocess, time, urllib.parse
ROOT = pathlib.Path(__file__).resolve().parents[1]
STATS = 'https://api.nhle.com/stats/rest/en/'
WEB = 'https://api-web.nhle.com/v1/'

def fetch(url):
    for attempt in range(3):
        p = subprocess.run(['curl','-fsSL','--max-time','45',url],capture_output=True,text=True)
        if p.returncode == 0:
            try: return json.loads(p.stdout)
            except ValueError: pass
        time.sleep(attempt + 1)
    raise RuntimeError('NHL request failed: ' + url)

def report(kind, start, end):
    q=urllib.parse.urlencode({'isAggregate':'false','isGame':'false','start':0,'limit':-1,'cayenneExp':f'seasonId>={start*10000+start+1} and seasonId<={(end)*10000+end+1} and gameTypeId=2'})
    result=fetch(STATS+kind+'/summary?'+q)
    if len(result['data']) != result['total']: raise RuntimeError('Incomplete '+kind+' report')
    return result['data']

def build(refresh=False):
    now=datetime.datetime.now(datetime.timezone.utc)
    open_decade=(now.year//10)*10
    target=ROOT/'data/rosters.json'
    old=json.loads(target.read_text()) if refresh and target.exists() else None
    metadata=fetch(STATS+'team')['data']
    teams={str(t['id']):{'name':t['fullName'],'code':t['triCode']} for t in metadata if t['id'] not in (70,99)}
    seasons=report('team',1917,now.year)
    season_teams={}
    for row in seasons:
        tid=str(row['teamId'])
        if tid not in teams: raise RuntimeError('Unknown team')
        season_teams.setdefault(row['seasonId'],{}).setdefault(teams[tid]['code'],[]).append(tid)
    decades=list(range(1910,open_decade+1,10))
    if old and 'positions' not in old: old=None
    wanted=[open_decade] if old else decades
    jobs=[(kind,d) for d in wanted for kind in ('skater','goalie')]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        futures={ex.submit(report,kind,max(1917,d),min(d+9,now.year)):(kind,d) for kind,d in jobs}
        records={}
        for fut in concurrent.futures.as_completed(futures):
            kind,d=futures[fut]; records[kind,d]=fut.result(); print(kind,d,len(records[kind,d]),flush=True)
    players=old['players'] if old else {}
    pools={d:v for d,v in old['pools'].items() if d not in ('current',str(open_decade))} if old else {}
    positions={d:v for d,v in old['positions'].items() if d not in ('current',str(open_decade))} if old else {}
    for d in wanted:
        grouped={}
        pos={}
        for kind in ('skater','goalie'):
            for row in records[kind,d]:
                if row['gamesPlayed']<1: continue
                pid=str(row['playerId'])
                name=row['skaterFullName' if kind=='skater' else 'goalieFullName']
                if ' ' not in name: raise RuntimeError('Missing full name: '+name)
                players[pid]=name
                for code in row['teamAbbrevs'].split(','):
                    ids=season_teams.get(row['seasonId'],{}).get(code.strip(),[])
                    if len(ids)!=1: raise RuntimeError(f'Ambiguous team {code} / {row["seasonId"]}: {ids}')
                    grouped.setdefault(ids[0],set()).add(pid)
                    position='G' if kind=='goalie' else row.get('positionCode')
                    if position not in ('C','L','R','D','G'): raise RuntimeError('Unknown position '+str(position))
                    pos.setdefault(ids[0],{}).setdefault(pid,set()).add(position)
        pools[str(d)]={tid:sorted(ids,key=lambda p:players[p]) for tid,ids in grouped.items()}
        positions[str(d)]={tid:{pid:sorted(codes) for pid,codes in people.items()} for tid,people in pos.items()}
    # Team summary identifies clubs in the latest recorded NHL season.
    latest=max(season_teams)
    active=[tid for ids in season_teams[latest].values() for tid in ids]
    # NHL standings metadata includes expansion/current clubs even before their first game.
    standings=fetch(WEB+'standings/now')['standings']
    codes={r['teamAbbrev']['default'] for r in standings}
    bycode={teams[tid]['code']:tid for tid in active}
    if not codes: raise RuntimeError('Empty current team list')
    for code in codes:
        if code not in bycode:
            matches=[tid for tid,t in teams.items() if t['code']==code]
            if len(matches)!=1: raise RuntimeError('Cannot resolve current '+code)
            bycode[code]=matches[0]
    def current(code):
        data=fetch(WEB+'roster/'+code+'/current'); people=data.get('forwards',[])+data.get('defensemen',[])+data.get('goalies',[])
        if not people: raise RuntimeError('Empty roster '+code)
        return bycode[code],people
    current_pool={}
    current_positions={}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        for tid,people in ex.map(current,sorted(codes)):
            ids=set()
            current_positions[tid]={}
            for p in people:
                pid=str(p['id']);players[pid]=p['firstName']['default']+' '+p['lastName']['default'];ids.add(pid)
                position=p.get('positionCode')
                if position not in ('C','L','R','D','G'): raise RuntimeError('Unknown current position')
                current_positions[tid][pid]=[position]
            current_pool[tid]=sorted(ids,key=lambda p:players[p])
    pools['current']=current_pool
    positions['current']=current_positions
    used={p for groups in pools.values() for ids in groups.values() for p in ids}
    used_teams={t for groups in pools.values() for t in groups}
    result={'updated':now.date().isoformat(),'historicalDefinition':'Regular-season appearances; decade uses season start year.','sources':[STATS+'team',STATS+'skater/summary',STATS+'goalie/summary',WEB+'roster/{team}/current'],'teams':{tid:t for tid,t in teams.items() if tid in used_teams},'players':{p:players[p] for p in sorted(used)},'pools':pools,'positions':positions}
    target.parent.mkdir(exist_ok=True)
    temp=target.with_suffix('.tmp');temp.write_text(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n');temp.replace(target)
    print('Saved',len(result['players']),'players,',len(result['teams']),'team identities,',len(current_pool),'current clubs',flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--refresh-current',action='store_true');build(p.parse_args().refresh_current)
