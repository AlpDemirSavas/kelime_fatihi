#!/usr/bin/env python3
"""Generate Kelime Fatihi V7's optimized 10,000-level campaign.

The optimizer keeps gameplay fully offline. A Turkish frequency list is used
only at build time to rank mandatory answers. Mandatory answers must either be
manually curated in the project or sufficiently attested in the frequency
source. Rare lexical entries may remain accepted bonus words without being
forced on the player.

Frequency source expected by this script:
  hermitdave/FrequencyWords, content/2016/tr/tr_50k.txt
  Content license: CC BY-SA 4.0 (see THIRD_PARTY_NOTICES.md).
"""
from collections import Counter, defaultdict
from pathlib import Path
from itertools import combinations
import argparse
import hashlib, statistics, json

parser = argparse.ArgumentParser(
    description="Build the globally optimized 10,000-level Kelime Fatihi campaign."
)
parser.add_argument(
    "frequency_list",
    type=Path,
    help="HermitDave FrequencyWords Turkish tr_50k.txt (word + count format).",
)
parser.add_argument(
    "--project",
    type=Path,
    default=Path(__file__).resolve().parents[1],
)
args = parser.parse_args()
P = args.project.resolve()
D = P / "assets" / "dictionary"
F = args.frequency_list.resolve()
if not F.exists():
    raise SystemExit(f"Frequency list not found: {F}")
TR=str.maketrans({'I':'ı','İ':'i','Â':'a','Î':'i','Û':'u','â':'a','î':'i','û':'u'})
ALLOWED=set('abcçdefgğhıijklmnoöprsştuüvyz')
def norm(w): return w.translate(TR).lower().replace('\u0307','').strip()
def read(n):
 return [norm(l.split('#',1)[0]) for l in (D/n).read_text(encoding='utf8').splitlines() if norm(l.split('#',1)[0])]
def sig(w): return ''.join(sorted(w))
def subsets(s):
 c=list(s); out=set()
 for n in range(3,len(c)+1):
  for inds in combinations(range(len(c)),n): out.add(''.join(c[i] for i in inds))
 return out
def target_count(i): return 5 if i<100 else 6 if i<1000 else 7 if i<3000 else 8 if i<5500 else 9 if i<8000 else 10
def overlap(a,b):
 ca=Counter(a); cb=Counter(b); return sum((ca&cb).values())/max(len(a),len(b))

freq={}
for rank,line in enumerate(F.read_text(encoding='utf8').splitlines(),1):
 p=line.rsplit(' ',1)
 if len(p)!=2: continue
 w=norm(p[0]);
 if w and all(c in ALLOWED for c in w): freq.setdefault(w,rank)

blocked=set(read('blocked_words.txt')); blocked_level=set(read('blocked_level_words.txt'))
play=set(read('play_words.txt')); review=set(read('reviewed_expansion_words.txt')); daily=set(read('daily_words.txt')); curated=play|review|daily
level=set(read('level_words.txt'))|{w for w in curated if 3<=len(w)<=9}; level-=blocked|blocked_level
by=defaultdict(list)
for w in level: by[sig(w)].append(w)
for s in by: by[s].sort()

FREQ_LIMIT=40000; THREE_LIMIT=18000
def mandatory_ok(w):
 if w in curated: return True
 r=freq.get(w,10**9)
 return r<=FREQ_LIMIT and (len(w)>=4 or r<=THREE_LIMIT)

sub_cache={}
def all_sub(s):
 if s not in sub_cache:
  x=set()
  for ss in subsets(s): x.update(by.get(ss,()))
  sub_cache[s]=sorted(x,key=lambda w:(-len(w),w))
 return sub_cache[s]
def safe_sub(s): return [w for w in all_sub(s) if mandatory_ok(w)]

def freq_score(w):
 r=freq.get(w)
 if r is None: return 0.0
 return 150*max(0.0,1-(r-1)/FREQ_LIMIT)**0.68

def best_full(s):
 same=[w for w in by[s] if mandatory_ok(w)]
 if not same: return None
 return max(same,key=lambda w:((1 if w in play or w in daily else 0),(1 if w in review else 0),freq_score(w),-len(w),w))

def representative(s):
 # Internal seed label. Prefer recognizable full-length lexical word where possible.
 full=best_full(s)
 if full: return full
 return min(by[s],key=lambda w:(0 if w in curated else 1 if w in freq else 2,freq.get(w,999999),w))

quota={5:999,6:2000,7:2500,8:2500,9:2001}
need={5:6,6:7,7:8,8:9,9:10}
chosen_by_len={}
quality_by_sig={}

for L in range(5,10):
 arr=[]
 for s in by:
  if len(s)!=L: continue
  safe=safe_sub(s)
  if len(safe)<need[L]: continue
  curated_count=sum(w in curated for w in safe)
  full=best_full(s)
  full_bonus=0
  if full:
   full_bonus=850+(400 if full in curated else 0)+freq_score(full)*2
  # Average quality of the best answers this wheel can offer.
  top=sorted(safe,key=lambda w:(1 if w in curated else 0,freq_score(w),len(w)),reverse=True)[:need[L]+4]
  avg=sum((120 if w in curated else 0)+freq_score(w)+len(w)*8 for w in top)/len(top)
  # Wheel letter variety helps visual/gameplay feel; don't make it dominant.
  distinct=len(set(s)); duplicate_penalty=(L-distinct)*22
  q=full_bonus+min(len(safe),45)*22+min(curated_count,12)*65+avg*4-distinct*0-duplicate_penalty
  rep=representative(s)
  arr.append((q,s,rep,len(safe),curated_count,full))
  quality_by_sig[s]=q
 arr.sort(key=lambda x:(-x[0],x[2]))
 if len(arr)<quota[L]: raise RuntimeError((L,len(arr),quota[L]))
 chosen_by_len[L]=arr[:quota[L]]

# Preserve a gradual quality curve, but minimize near-identical adjacent wheels inside small quality bands.
def order_group(items, previous_word=None, band=50):
 out=[]; prev=previous_word
 for start in range(0,len(items),band):
  pool=list(items[start:start+band])
  # start with best item unless prior wheel makes it visually repetitive
  while pool:
   if prev is None:
    pick=0
   else:
    # Mostly minimize overlap; small quality bonus preserves within-band ranking.
    scored=[]
    bestq=pool[0][0]
    for j,item in enumerate(pool):
     q,s,rep,*_=item
     sc=-(overlap(rep,prev))*1000 + (q-bestq)*0.015
     scored.append((sc,-j,j))
    pick=max(scored)[2]
   item=pool.pop(pick); out.append(item); prev=item[2]
 return out

ordered=[]; prev=None
for L in range(5,10):
 grp=order_group(chosen_by_len[L],prev)
 ordered.extend(grp); prev=grp[-1][2]
seeds=[x[2] for x in ordered]
assert len(seeds)==10000 and len({sig(s) for s in seeds})==10000
assert Counter(map(len,seeds))==Counter(quota)

# Build globally balanced mandatory target lists.
usage=Counter(); last_seen={}; targets=[]

def tie(i,w): return int.from_bytes(hashlib.blake2b(f'{i}:{w}:campaign-v7'.encode(),digest_size=8).digest(),'big')/2**64

for i,seed in enumerate(seeds,1):
 s=sig(seed); words=safe_sub(s); n=target_count(i)
 assert len(words)>=n,(i,seed,len(words),n)
 chosen=[]; remaining=set(words)
 max_three=1 if n<=6 else 2
 desired_cur=min(2,max(1,n//4))
 desired_long=min(n,1 if len(seed)==5 else 2 if len(seed)==6 else 3 if len(seed)==7 else 4)
 full_candidates={w for w in remaining if sig(w)==s}
 # We prefer one full-wheel answer whenever there is a safe one.
 must_full=bool(full_candidates)
 for slot in range(n):
  slots=n-slot; three=sum(len(w)==3 for w in chosen); cur=sum(w in curated for w in chosen); long=sum(len(w)>=5 for w in chosen); has_full=any(sig(w)==s for w in chosen)
  scored=[]
  for w in remaining:
   L=len(w); is_cur=w in curated; is_play=w in play or w in daily; is_full=sig(w)==s
   if L==3 and three>=max_three: continue
   prev_seen=last_seen.get(w)
   recent_window=24 if L==3 else 14
   if prev_seen is not None and i-prev_seen<recent_window:
    nonrecent=sum(1 for x in remaining if last_seen.get(x, -10**9) <= i-(24 if len(x)==3 else 14))
    if nonrecent>=slots: continue
   if desired_long-long>=slots and L<5 and any(len(x)>=5 for x in remaining): continue
   if desired_cur-cur>=slots and not is_cur and any(x in curated for x in remaining): continue
   if must_full and not has_full and slots==1 and not is_full: continue
   score=freq_score(w)
   if is_play: score+=190
   elif w in review: score+=145
   score+={3:-18,4:40,5:60,6:64,7:60,8:52,9:46}[L]
   if is_full: score+=115
   if long<desired_long and L>=5: score+=30
   if cur<desired_cur and is_cur: score+=44
   score-=usage[w]*{3:58,4:45,5:34,6:29,7:26,8:24,9:22}[L]
   prev=last_seen.get(w)
   if prev is not None:
    gap=i-prev
    if gap<50: score-=280
    elif gap<150: score-=120
    elif gap<400: score-=45
   score-=sum(len(x)==L for x in chosen)*7
   score+=tie(i,w)
   scored.append((score,w))
  if not scored:
   # Viability is guaranteed; this only relaxes local mixture constraints.
   for w in remaining:
    L=len(w); is_cur=w in curated; is_full=sig(w)==s
    score=freq_score(w)+(190 if w in play or w in daily else 145 if w in review else 0)+{3:-18,4:40,5:60,6:64,7:60,8:52,9:46}[L]+(115 if is_full else 0)-usage[w]*{3:58,4:45,5:34,6:29,7:26,8:24,9:22}[L]+tie(i,w)
    scored.append((score,w))
  scored.sort(reverse=True); w=scored[0][1]
  chosen.append(w); remaining.remove(w); usage[w]+=1; last_seen[w]=i
 chosen.sort(key=lambda w:(-len(w),w)); targets.append(chosen)

# Reports
old_seeds=read('level_seeds.txt')[:10000]
old_sigs={sig(s) for s in old_seeds}; new_sigs={sig(s) for s in seeds}
letter_sim=[overlap(a,b) for a,b in zip(seeds,seeds[1:])]
target_j=[len(set(a)&set(b))/len(set(a)|set(b)) for a,b in zip(targets,targets[1:])]
lens=Counter(x for arr in targets for x in map(len,arr)); ranks=[freq[w] for arr in targets for w in arr if w in freq]
full_levels=sum(any(sig(w)==sig(seed) for w in arr) for seed,arr in zip(seeds,targets))
cur_levels=sum(any(w in curated for w in arr) for arr in targets)
report={
 'seed_signature_overlap_with_old':len(old_sigs&new_sigs),
 'campaign_wheels_remapped':10000-len(old_sigs&new_sigs),
 'unique_wheels':len(new_sigs),
 'wheel_length_counts':dict(sorted(Counter(map(len,seeds)).items())),
 'all_exact_target_count':all(len(a)==target_count(i) for i,a in enumerate(targets,1)),
 'levels_with_full_wheel_answer':full_levels,
 'levels_with_curated_answer':cur_levels,
 'mandatory_total':sum(map(len,targets)),
 'mandatory_unique':len(usage),
 'mandatory_max_repeat':max(usage.values()),
 'mandatory_ge10':sum(v>=10 for v in usage.values()),
 'mandatory_length_counts':dict(sorted(lens.items())),
 'mandatory_frequency_or_curated_pct':100.0,
 'median_frequency_rank':statistics.median(ranks),
 'adjacent_wheel_similarity_mean':statistics.mean(letter_sim),
 'adjacent_wheel_similarity_p90':statistics.quantiles(letter_sim,n=10)[8],
 'adjacent_wheel_similarity_max':max(letter_sim),
 'adjacent_wheel_similarity_ge075':sum(v>=.75 for v in letter_sim),
 'adjacent_target_jaccard_mean':statistics.mean(target_j),
 'adjacent_target_jaccard_max':max(target_j),
 'most_repeated':usage.most_common(25),
 'examples':{str(i):{'seed':seeds[i-1],'targets':targets[i-1]} for i in [1,10,50,99,100,500,999,1000,1500,2999,3000,4000,5499,5500,6500,7999,8000,9000,9999,10000]},
}
(D / 'level_seeds.txt').write_text('\n'.join(seeds) + '\n', encoding='utf8')
(D / 'level_targets.txt').write_text(
    '\n'.join(f"{sig(seed)}|{','.join(arr)}" for seed, arr in zip(seeds, targets)) + '\n',
    encoding='utf8',
)
(P / 'CAMPAIGN_QUALITY_REPORT.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n',
    encoding='utf8',
)
summary = (
    f"Unique wheels:                         {report['unique_wheels']:,}\n"
    f"Wheel sizes 5/6/7/8/9:                999/2,000/2,500/2,500/2,001\n"
    f"Levels with curated mandatory answer: {report['levels_with_curated_answer']:,}\n"
    f"Levels with full-wheel answer:         {report['levels_with_full_wheel_answer']:,}\n"
    f"Unique mandatory answers:              {report['mandatory_unique']:,}\n"
    f"Maximum mandatory answer repetition:   {report['mandatory_max_repeat']}\n"
    f"Mean adjacent wheel similarity:        {report['adjacent_wheel_similarity_mean']:.4f}\n"
    f"Mandatory frequency/curated coverage:  100%\n"
)
(P / 'CAMPAIGN_QUALITY_REPORT.txt').write_text(summary, encoding='utf8')
print(summary)
