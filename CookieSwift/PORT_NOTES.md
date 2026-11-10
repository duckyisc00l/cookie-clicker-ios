# Cookie Clicker - full Swift port (second, line-by-line attempt)

User asked (2026-11-09): "Make the entire app into 100% swift code and 1:1 okay put some real effort".
Rule: do it batch by batch WITHOUT asking the user to continue. User is non-technical.

## Approach
- New code lives in `CookieSwift/` (the old quick port in `SwiftGame/` is reference only, delete at the end).
- Engine: translate www/main.js + www/lib/main.js function by function, same names (global `G`).
- Content: tools in /home/claude/swiftport/port: capture.js + dump.js run the original in Playwright and
  dump every Building/Upgrade/Achiev exactly as defined (content_raw.json) + JS source of the 139
  function snippets (content_fns.json) + final objects for checking (content_final.json).
  Swift replicates the G.Upgrade/G.Achiev constructors and maps snippet keys to hand-written closures.
- Layout: the original lays out a 320px-wide page scaled to the screen (scale = width/320, G.h = height/scale).
  Swift UI uses the same 320-wide coordinates, scaled.
- Mods to fold in: mods/more-content.js (4 buildings, tiers, unshackled, cookies, news), sugar-lumps.js,
  minigame-bridge.js (achievs 2300+, 14 buff types, effects, hooks), reminders.js (auto-harvest, garden msgs),
  hd-art.js (use hd/*.webp images at original sizes).
- Testing: no Swift compiler here (swift.org blocked). CI on macOS: compile, engine parity test vs JS fixtures,
  iOS simulator screenshots compared with Playwright screenshots of the web app.

## main.js map (line numbers)
1-310 helpers/format | 316 Init | 342 Save/Load | 547 Reset | 759 settings | 890 inputs | 1046 build HTML |
1109 quick buttons | 1135 particles | 1319 ticker | 1990 hidden slots/toyPins | 2149 buffs | 2460 shimmers |
3131 tabs/screens/BG | 3263 cookie screen (big cookie, freeCookie, quick buttons) | ... | 4064 setStoreSection |
4140 special screen: ascending 4147, showAscend 4199 | ~4470-6026 other screens | 6026 setScreen/popup/toast |
6201 wrinklers | 6610 pets/santa/dragon | 6983 seasons | 7300 economics computeCps | 7620 buildings |
7944 tiers | 7976 milks | 8035 upgrades | 8644 achievs | 8806 afterData | 8934 Logic | 9075 Draw

## Progress
- [x] Core/JS.swift (seedrandom ARC4 exact, B, BT, sayTime, romanize, jsString...)
- [x] Core/Objects.swift (Building, Upgrade, Achiev, Tier, UnlockAt, Eff, Milk)
- [x] Core/Game.swift (state, pools, computeCps, power clicks, costs, doUnlocks)
- [x] Core/Buffs.swift, Core/Shimmers.swift
- [ ] Content loader + fns, tiers, milks, AllBGs
- [ ] Save/Load/Reset, settings, ticker, wrinklers, santa, dragon, seasons, ascend, research, Logic, Draw
- [ ] lumps, minigames, extras
- [ ] UI
