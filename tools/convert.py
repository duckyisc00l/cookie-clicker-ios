# Turns the game's data (dumped from the original game by tools/dump.js) into GameData.json for the Swift app.
import json,re,sys
d=json.load(open(sys.argv[1]))
N=lambda s:re.sub(r'\s+',' ',s)
upById={u['id']:u for u in d['upgrades']}
tierByName={t['name']:(k,t) for k,t in d['tiers'].items()}
unknown=[]
def eff(e,u):
    p,v,m=e
    if not isinstance(v,dict): return {'p':p,'v':v,'m':m or 0}
    f=N(v['fn'])
    bm=re.match(r'building(\d+)[AM]$',p); b=int(bm.group(1)) if bm else None
    if 'tie.unshackleUpgrade' in f:
        tn=tierByName.get(u['tier'])
        return {'p':p,'k':'tier','b':b,'tu':tn[1]['upgrade'] if tn else None}
    m2=re.search(r'v\*\(1\+([\d.]+)\*tie2?\.amount\)',f)
    if m2:
        # the other building is the one named in the upgrade's other effect
        others=[int(re.match(r'building(\d+)',x[0]).group(1)) for x in u['effs'] if x[0]!=p and re.match(r'building\d+',x[0])]
        return {'p':p,'k':'syn','o':others[0],'r':float(m2.group(1))}
    if '(1/(tie.id-1))' in f: return {'p':p,'k':'gma','b':b}
    unknown.append(u['name'])
    return {'p':p,'k':'sp','n':u['name']}
def cond(c,owner,isAch):
    if not c: return None
    o={}
    for k in ['cookies','cps','milk']:
        if c[k]: o[k]=c[k]
    if c['buildings']: o['b']=c['buildings']
    if c['upgrades']: o['u']=c['upgrades']
    if c['achievs']: o['a']=c['achievs']
    s=c['spe']
    if s:
        f=N(s)
        m=re.fullmatch(r"v=>\{?\s*(?:return )?G\.(\w+)>=(\d+);?\s*\}?",f)
        if m: o['s']={'k':'stat','v':m.group(1),'n':float(m.group(2))}
        elif re.fullmatch(r"v=>\{return G\.season=='(\w+)';\}",f): o['s']={'k':'season','v':re.search(r"'(\w+)'",f).group(1)}
        elif 'tie.cookiesMade>=threshold' in f:
            bid=owner['_tie']; tier=owner['tier']; mult=7 if bid==0 else 6 if bid==1 else 0
            n=12+bid+mult+(7 if tier==2 else 14 if tier==3 else 0)
            o['s']={'k':'made','b':bid,'n':10.0**n}
        elif 'G.cookiesHandmade>=' in f:
            t=owner['tier']; t=int(tierByName[t][0]) if isinstance(t,str) else t; o['s']={'k':'stat','v':'cookiesHandmade','n':10.0**(t*2+1)}
        else:
            o['s']={'k':'sp','n':owner['name']}; unknown.append('cond:'+owner['name'])
    return o
# which building a buildingProd achievement is about: from its description "just from <plural>."
plural={b['plural']:b['id'] for b in d['buildings']}
out={'buildings':[],'upgrades':[],'achievs':[],'tiers':d['tiers'],'buffTypes':[],'pools':d['upgradePools'],'heavenlyParents':d['heavenlyParents']}
for b in d['buildings']:
    out['buildings'].append({k:b[k] for k in ['id','name','single','plural','actionName','extraName','extraPlural','desc','pic','icon','baseCost','baseCps','foolName','foolPlural','foolDesc','unshackle']})
for u in d['upgrades']:
    o={k:u.get(k) for k in ['id','name','desc','q','icon','pool','order','cost','power','tier','unimplemented']}
    o['effs']=[eff(e,u) for e in u['effs']]
    if u['costFunc']: o['costK']=N(u['costFunc']['fn'])[:60]
    o['unlock']=cond(u['unlockAt'],u,False)
    out['upgrades'].append(o)
for a in d['achievs']:
    a['_tie']=None
    if a['pool']=='buildingProd':
        m=re.search(r'just from (.+)\.$',re.sub('<[^>]+>','',a['desc'])); a['_tie']=plural[m.group(1)]
    o={k:a[k] for k in ['id','name','desc','q','icon','pool','order','tier','unimplemented']}
    o['unlock']=cond(a['unlockAt'],a,True)
    out['achievs'].append(o)
for t in d['buffTypes']:
    out['buffTypes'].append({k:t[k] for k in ['name','nameD','icon','t','pow','type','stackT','stackPow']}|{'desc':t['desc'] if isinstance(t['desc'],str) else None,'effs':N(t['effsFunc']['fn']) if t['effsFunc'] else None})
json.dump(out,open(sys.argv[2],'w'),separators=(',',':'))
print('special effects/conditions handled in Swift:',sorted(set(unknown)))
