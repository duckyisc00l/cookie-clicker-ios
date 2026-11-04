# Swift rewrite — status notes

Goal: the whole game rewritten in Swift (SwiftUI), as a separate app "Cookie Clicker Swift"
(bundle id com.duckyisc00l.cookieclickerswift) next to the original WKWebView app.
User asked: everything (main game, all mobile features, sugar lumps, extras, 4 minigames),
done batch by batch WITHOUT asking them to continue.

Data: tools/dump.js + dump2.js run the original game in Playwright (tools/harness.js) and dump
G's data; tools/convert.py -> SwiftGame/Resources/GameData.json (typed effects/conditions).
Effects kinds: numeric {p,v,m}, tier {p,b,tu}, syn {p,o,r}, gma {p,b}, sp {p,n} (by upgrade name, in Swift).
Conditions: cookies,cps,milk,b[[id,n]],u[ids],a[ids], s:{k:stat|season|made|sp}.
Rules source: CookieClicker/www/main.js (mobile engine "G"), mods/*.js, desktop minigames in mods/minigames.

Save format = same JSON object as the mobile G.Save(true) so QR/backups move between apps.

## Batches
1. [ ] Engine core: data, pools, cps, buildings, upgrades, achievements, buffs, golden cookies, logic loop, save/load
2. [ ] UI: cookie screen, store, upgrades, stats/achievements, settings, toasts, news ticker
3. [ ] Wrinklers, grandmapocalypse, research, seasons/drops, santa, dragon, ascension + heavenly tree, power clicks, milk/kittens, fortune
4. [ ] Sugar lumps + levels, new buildings content, extras (iCloud backup, QR, Live Activity, keep awake)
5. [ ] Minigames: Garden, Pantheon, Grimoire, Stock Market
6. [ ] Build target in project.yml + workflow, test, ship
