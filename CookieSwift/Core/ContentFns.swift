import Foundation

// The small pieces of code inside the game's content (www/data.js and the app's mods), translated to Swift.
// Each is keyed like the content dump: "<Upgrade|Achiev>:<name>.<field>". The original is in the comment above it.
// Content.swift checks at start-up that every key in Content.json has a translation here.

enum ContentFns {
    static let bools: [String: () -> Bool] = {
        var b: [String: () -> Bool] = [:]
        // v=>{return G.buildingsNmin>=100;}
        b["Upgrade:Milk chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 100 }
        // v=>{return G.buildingsNmin>=150;}
        b["Upgrade:Dark chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 150 }
        // v=>{return G.buildingsNmin>=200;}
        b["Upgrade:White chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 200 }
        // v=>{return G.buildingsNmin>=250;}
        b["Upgrade:Ruby chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 250 }
        // v=>{return G.buildingsNmin>=300;}
        b["Upgrade:Lavender chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 300 }
        // v=>{return G.buildingsNmin>=350;}
        b["Upgrade:Synthetic chocolate green honey butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 350 }
        // v=>{return G.buildingsNmin>=400;}
        b["Upgrade:Royal raspberry chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 400 }
        // v=>{return G.buildingsNmin>=450;}
        b["Upgrade:Ultra-concentrated high-energy chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 450 }
        // v=>{return G.buildingsNmin>=500;}
        b["Upgrade:Pure pitch-black chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 500 }
        // v=>{return G.gcClicksTotal>=7;}
        b["Upgrade:Lucky day.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 7 }
        // v=>{return G.gcClicksTotal>=27;}
        b["Upgrade:Serendipity.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 27 }
        // v=>{return G.gcClicksTotal>=77;}
        b["Upgrade:Get lucky.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 77 }
        // v=>{return G.buildingsNmin>=550;}
        b["Upgrade:Cosmic chocolate butter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 550 }
        // v=>{return G.buildingsNmin>=600;}
        b["Upgrade:Butter biscuit (with butter).unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 600 }
        // v=>{return G.buildingsNmin>=650;}
        b["Upgrade:Everybutter biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 650 }
        // v=>{return G.buildingsNmin>=700;}
        b["Upgrade:Personal biscuit.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 700 }
        // v=>{return G.pledges>=10;}
        b["Upgrade:Sacrificial rolling pins.unlockAt.spe"] = { () -> Bool in G.pledges >= 10 }
        // v=>{return G.buildingsNmin>=100;}
        b["Achiev:Centennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 100 }
        // v=>{return G.buildingsNmin>=150;}
        b["Achiev:Centennial and a half.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 150 }
        // v=>{return G.buildingsNmin>=200;}
        b["Achiev:Bicentennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 200 }
        // v=>{return G.buildingsNmin>=250;}
        b["Achiev:Bicentennial and a half.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 250 }
        // v=>{return G.buildingsNmin>=300;}
        b["Achiev:Tricentennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 300 }
        // v=>{return G.buildingsNmin>=350;}
        b["Achiev:Tricentennial and a half.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 350 }
        // v=>{return G.buildingsNmin>=400;}
        b["Achiev:Quadricentennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 400 }
        // v=>{return G.buildingsNmin>=450;}
        b["Achiev:Quadricentennial and a half.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 450 }
        // v=>{return G.buildingsNmin>=500;}
        b["Achiev:Quincentennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 500 }
        // v=>{return G.gcClicksTotal>=1;}
        b["Achiev:Golden cookie.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 1 }
        // v=>{return G.gcClicksTotal>=7;}
        b["Achiev:Lucky cookie.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 7 }
        // v=>{return G.gcClicksTotal>=27;}
        b["Achiev:A stroke of luck.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 27 }
        // v=>{return G.gcClicksTotal>=77;}
        b["Achiev:Fortune.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 77 }
        // v=>{return G.gcClicksTotal>=777;}
        b["Achiev:Leprechaun.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 777 }
        // v=>{return G.gcClicksTotal>=7777;}
        b["Achiev:Black cat's paw.unlockAt.spe"] = { () -> Bool in G.gcClicksTotal >= 7777 }
        // v=>{return G.wrinklersPopped>=1;}
        b["Achiev:Itchscratcher.unlockAt.spe"] = { () -> Bool in G.wrinklersPopped >= 1 }
        // v=>{return G.wrinklersPopped>=50;}
        b["Achiev:Wrinklesquisher.unlockAt.spe"] = { () -> Bool in G.wrinklersPopped >= 50 }
        // v=>{return G.wrinklersPopped>=200;}
        b["Achiev:Moistburster.unlockAt.spe"] = { () -> Bool in G.wrinklersPopped >= 200 }
        // v=>{return G.buildingsN>=100;}
        b["Achiev:Builder.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 100 }
        // v=>{return G.buildingsN>=500;}
        b["Achiev:Architect.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 500 }
        // v=>{return G.buildingsN>=1000;}
        b["Achiev:Engineer.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 1000 }
        // v=>{return G.buildingsN>=2000;}
        b["Achiev:Lord of Constructs.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 2000 }
        // v=>{return G.buildingsN>=5000;}
        b["Achiev:Grand design.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 5000 }
        // v=>{return G.buildingsN>=7500;}
        b["Achiev:Ecumenopolis.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 7500 }
        // v=>{return G.buildingsN>=10000;}
        b["Achiev:Myriad.unlockAt.spe"] = { () -> Bool in Double(G.buildingsN) >= 10000 }
        // v=>{return G.upgradesN>=20;}
        b["Achiev:Enhancer.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 20 }
        // v=>{return G.upgradesN>=50;}
        b["Achiev:Augmenter.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 50 }
        // v=>{return G.upgradesN>=100;}
        b["Achiev:Upgrader.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 100 }
        // v=>{return G.upgradesN>=200;}
        b["Achiev:Lord of Progress.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 200 }
        // v=>{return G.upgradesN>=300;}
        b["Achiev:The full picture.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 300 }
        // v=>{return G.upgradesN>=400;}
        b["Achiev:When there's nothing left to add.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 400 }
        // v=>{return G.upgradesN>=500;}
        b["Achiev:Kaizen.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 500 }
        // v=>{return G.upgradesN>=600;}
        b["Achiev:Beyond quality.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 600 }
        // v=>{return G.upgradesN>=700;}
        b["Achiev:Oft we mar what's well.unlockAt.spe"] = { () -> Bool in Double(G.upgradesN) >= 700 }
        // v=>G.resets>=1
        b["Achiev:Rebirth.unlockAt.spe"] = { () -> Bool in G.resets >= 1 }
        // v=>G.resets>=10
        b["Achiev:Resurrection.unlockAt.spe"] = { () -> Bool in G.resets >= 10 }
        // v=>G.resets>=100
        b["Achiev:Reincarnation.unlockAt.spe"] = { () -> Bool in G.resets >= 100 }
        // v=>G.resets>=1000
        b["Achiev:Endless cycle.unlockAt.spe"] = { () -> Bool in G.resets >= 1000 }
        // v=>{return G.buildingsNmin>=550;}
        b["Achiev:Quincentennial and a half.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 550 }
        // v=>{return G.buildingsNmin>=600;}
        b["Achiev:Sexcentennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 600 }
        // v=>{return G.buildingsNmin>=650;}
        b["Achiev:Sexcentennial and a half.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 650 }
        // v=>{return G.buildingsNmin>=700;}
        b["Achiev:Septcentennial.unlockAt.spe"] = { () -> Bool in Double(G.buildingsNmin) >= 700 }
        // v=>{return G.reindeerClicksTotal>=1;}
        b["Achiev:Oh deer.unlockAt.spe"] = { () -> Bool in G.reindeerClicksTotal >= 1 }
        // v=>{return G.reindeerClicksTotal>=50;}
        b["Achiev:Sleigh of hand.unlockAt.spe"] = { () -> Bool in G.reindeerClicksTotal >= 50 }
        // v=>{return G.reindeerClicksTotal>=200;}
        b["Achiev:Reindeer sleigher.unlockAt.spe"] = { () -> Bool in G.reindeerClicksTotal >= 200 }
        // v=>{return G.elderWrath>=3;}
        b["Achiev:Grandmapocalypse.unlockAt.spe"] = { () -> Bool in Double(G.elderWrath) >= 3 }
        // v=>{return G.resets>0;}
        b["Upgrade:Heavenly chip secret.unlockAt.spe"] = { G.resets > 0 }
        // v=>{return G.cookiesEarned>=25 && G.season=='christmas';}
        b["Upgrade:A festive hat.unlockAt.spe"] = { G.cookiesEarned >= 25 && G.season == "christmas" }
        // v=>{return G.cookiesEarned>=1000000 && G.Has('How to bake your dragon');}
        b["Upgrade:A crumbly egg.unlockAt.spe"] = { G.cookiesEarned >= 1000000 && G.Has("How to bake your dragon") }
        // v=>{return G.season=='valentines';}  (all seven heart biscuits)
        for n in ["Pure", "Ardent", "Sour", "Weeping", "Golden", "Eternal", "Prism"] {
            b["Upgrade:\(n) heart biscuits.unlockAt.spe"] = { G.season == "valentines" }
        }
        // v=>{var grans=G.buildingsBN['Grandma'];return grans.bought>grans.amount;}
        b["Achiev:Just wrong.unlockAt.spe"] = { let grans = G.buildingsBN["Grandma"]!; return grans.bought > grans.amount }
        // v=>{var pool=G.upgradePools['grandma'];var n=0;for (...){if (pool[i].owned) n++;}return n>=7;}
        b["Achiev:Elder.unlockAt.spe"] = { (G.upgradePools["grandma"] ?? []).filter { $0.owned != 0 }.count >= 7 }
        // same, n>=14
        b["Achiev:Veteran.unlockAt.spe"] = { (G.upgradePools["grandma"] ?? []).filter { $0.owned != 0 }.count >= 14 }
        // v=>{return (G.buildingsN>=3000 && G.upgradesN>=300);}
        b["Achiev:Polymath.unlockAt.spe"] = { G.buildingsN >= 3000 && G.upgradesN >= 300 }
        // v=>{return (G.buildingsN>=4000 && G.upgradesN>=400);}
        b["Achiev:Renaissance baker.unlockAt.spe"] = { G.buildingsN >= 4000 && G.upgradesN >= 400 }
        // v=>{return (G.buildings[0].amount+G.buildings[1].amount)>=777;}
        b["Achiev:The elder scrolls.unlockAt.spe"] = { (G.buildings[0].amount + G.buildings[1].amount) >= 777 }
        // v=>{ for (buildings) { if (amount<=0) return false; } return true; }
        b["Achiev:One with everything.unlockAt.spe"] = { !G.buildings.contains { $0.amount <= 0 } }
        // v=>{ for (i) { if (G.buildings[i].amount<Math.min(128,Math.pow(2,(G.buildings.length-i)-1))) return false; } return true; }
        b["Achiev:Mathematician.unlockAt.spe"] = {
            let n = G.buildings.count
            for (i, bd) in G.buildings.enumerated() { if Double(bd.amount) < min(128, pow(2, Double((n - i) - 1))) { return false } }
            return true
        }
        // v=>{ for (i) { if (G.buildings[i].amount<(G.buildings.length-i)*10) return false; } return true; }
        b["Achiev:Base 10.unlockAt.spe"] = {
            let n = G.buildings.count
            for (i, bd) in G.buildings.enumerated() { if bd.amount < (n - i) * 10 { return false } }
            return true
        }
        // v=>{ for (i in G.upgradeTiers['fortune']) { if (!owned) return false; } return true;}
        b["Achiev:O Fortuna.unlockAt.spe"] = { !(G.upgradeTiers["fortune"] ?? []).contains { $0.owned == 0 } }
        // v=>{ if (G.season=='easter' && G.GetHowManyEggs()>=1) return true; return false;}
        b["Achiev:The hunt is on.unlockAt.spe"] = { G.season == "easter" && G.GetHowManyEggs() >= 1 }
        b["Achiev:Egging on.unlockAt.spe"] = { G.season == "easter" && G.GetHowManyEggs() >= 7 }
        b["Achiev:Mass Easteria.unlockAt.spe"] = { G.season == "easter" && G.GetHowManyEggs() >= 14 }
        b["Achiev:Hide & seek champion.unlockAt.spe"] = { G.season == "easter" && G.GetHowManyEggs() >= Game.easterEggs.count }
        // v=>{ if (G.season=='halloween' && G.GetHowManyHalloweenDrops()>=G.halloweenDrops.length) return true; return false;}
        b["Achiev:Spooky cookies.unlockAt.spe"] = { G.season == "halloween" && G.GetHowManyHalloweenDrops() >= Game.halloweenDrops.count }
        // v=>{ if (G.season=='christmas' && G.GetHowManyReindeerDrops()>=G.reindeerDrops.length) return true; return false;}
        b["Achiev:Let it snow.unlockAt.spe"] = { G.season == "christmas" && G.GetHowManyReindeerDrops() >= Game.reindeerDrops.count }
        // v=>{var pool=G.upgradePools['kitten'];... return n>=10;}
        b["Achiev:Jellicles.unlockAt.spe"] = { (G.upgradePools["kitten"] ?? []).filter { $0.owned != 0 }.count >= 10 }
        // v=>{var building=G.buildings[19];return (building.bought>0 || G.cookiesEarned>=building.baseCost);}
        b["Achiev:Cookie Clicker.unlockAt.spe"] = { let bd = G.buildings[19]; return bd.bought > 0 || G.cookiesEarned >= bd.baseCost }
        return b
    }()

    /// effect functions (eff[1] when eff[2]==2)
    static let effs: [String: (Double) -> Double] = [
        // v=>{return v*(1+0.03*G.santaLevel);}
        "Upgrade:Santa's legacy.effs.0.1": { v in v * (1 + 0.03 * Double(G.santaLevel)) },
        // v=>{ var day=Math.floor((Date.now()-G.runStart)/1000/10)*10/60/60/24; day=Math.max(0,Math.min(day,100)); var n=(1-Math.pow(1-day/100,3))*0.1; return v*(1+n); }
        "Upgrade:Century egg.effs.0.1": { v in
            var day = ((nowMs() - G.runStart) / 1000 / 10).rounded(.down) * 10 / 60 / 60 / 24
            day = max(0, min(day, 100))
            let n = (1 - pow(1 - day / 100, 3)) * 0.1
            return v * (1 + n)
        },
        // v=>{return v+(1+0.02*G.buildings[1].amount);}
        "Upgrade:One mind.effs.0.1": { v in v + (1 + 0.02 * Double(G.buildings[1].amount)) },
        "Upgrade:Communal brainsweep.effs.0.1": { v in v + (1 + 0.02 * Double(G.buildings[1].amount)) },
        // v=>{return v+(1+0.05*G.buildings[10].amount);}
        "Upgrade:Elder Pact.effs.0.1": { v in v + (1 + 0.05 * Double(G.buildings[10].amount)) },
        // v=>{return v*(1+(G.season=='easter'?0.02:0));}
        "Upgrade:Starspawn.effs.0.1": { v in v * (1 + (G.season == "easter" ? 0.02 : 0)) },
        "Upgrade:Starterror.effs.0.1": { v in v * (1 + (G.season == "halloween" ? 0.02 : 0)) },
        "Upgrade:Starlove.effs.0.1": { v in v * (1 + (G.season == "valentines" ? 0.02 : 0)) },
        // v=>{return v*(1+(G.season=='fools'?0.05:0));}
        "Upgrade:Startrade.effs.0.1": { v in v * (1 + (G.season == "fools" ? 0.05 : 0)) },
        // v=>{return v*(1+0.5+0.1*(G.Has('Residual luck')?G.goldenCookieUpgrades.filter(me=>me.owned).length:0));}
        "Upgrade:Golden switch [off].effs.0.1": { v in
            v * (1 + 0.5 + 0.1 * (G.Has("Residual luck") ? Double(G.goldenCookieUpgrades.filter { $0.owned != 0 }.count) : 0))
        },
        // v=>{return v*Math.pow(0.99,G.buildings[0].amount/100);}
        "Upgrade:Five-finger discount.effs.0.1": { v in v * pow(0.99, Double(G.buildings[0].amount) / 100) },
    ]

    /// power:()=>... (heart biscuits)
    static let powers: [String: () -> Double] = {
        var p: [String: () -> Double] = [:]
        // ()=>{return 2+(G.Has('Starlove')?1:0);}
        for n in ["Pure", "Ardent", "Sour", "Weeping", "Golden", "Eternal", "Prism"] {
            p["Upgrade:\(n) heart biscuits.power"] = { 2 + (G.Has("Starlove") ? 1 : 0) }
        }
        return p
    }()

    static let costs: [String: (Upgrade) -> Double] = {
        var c: [String: (Upgrade) -> Double] = [:]
        // (me)=>{return G.cookiesPsUnbuffed*60*30*((G.dragonLevel<G.dragonLevels.length-1)?1:0.1);}
        for n in ["Dragon scale", "Dragon claw", "Dragon fang", "Dragon teddy bear"] {
            c["Upgrade:\(n).costFunc"] = { _ in G.cookiesPsUnbuffed * 60 * 30 * ((G.dragonLevel < G.dragonLevels.count - 1) ? 1 : 0.1) }
        }
        // (me)=>{return Math.min(me.cost,G.cookiesPsUnbuffed*60*60*24);}
        for n in 100...104 {
            c["Upgrade:Fortune #\(n).costFunc"] = { me in min(me.cost, G.cookiesPsUnbuffed * 60 * 60 * 24) }
        }
        // ()=>{ return Math.pow(8,Math.min(G.pledges+2,14)); }
        c["Upgrade:Elder Pledge.costFunc"] = { _ in pow(8, min(G.pledges + 2, 14)) }
        // (me)=>{return Math.max(1000000,G.cookiesPsUnbuffed*60*60);}
        c["Upgrade:Wrinkler ambergris.costFunc"] = { _ in max(1000000, G.cookiesPsUnbuffed * 60 * 60) }
        // (me)=>{return G.cookiesPs*60*60;}
        c["Upgrade:Golden switch [off].costFunc"] = { _ in G.cookiesPs * 60 * 60 }
        c["Upgrade:Golden switch [on].costFunc"] = { _ in G.cookiesPs * 60 * 60 }
        return c
    }()

    /// func: called when bought (or, for heavenly upgrades, after every ascension)
    static let funcs: [String: (Upgrade, Bool) -> Void] = [
        // function(){ var drop=choose(G.santaDrops); G.unlock(drop); G.toast(`In the festive hat, you find...`,`a festive test tube<br>and <b>`+drop+`</b>.`,G.upgradesBN[drop].icon,1); G.pingScreen('special'); }
        "Upgrade:A festive hat.func": { _, _ in
            let drop = choose(Game.santaDrops)
            G.unlock(drop)
            G.toast("In the festive hat, you find...", "a festive test tube<br>and <b>" + drop + "</b>.", G.upgradesBN[drop]!.icon, true)
            G.pingScreen("special")
        },
        // function(){G.pingScreen('special');}
        "Upgrade:A crumbly egg.func": { _, _ in G.pingScreen("special") },
        // (me)=>{ var cookies=G.cookies*0.05; G.toast(`Chocolate egg`,`The egg bursts into <b>${B(cookies)}</b> cookies!`,me.icon,true); G.Earn(cookies); }
        "Upgrade:Chocolate egg.func": { me, _ in
            let c = G.cookies * 0.05
            G.toast("Chocolate egg", "The egg bursts into <b>\(B(c))</b> cookies!", me.icon, true)
            G.earn(c)
        },
        // e=>{G.pingScreen('special');}
        "Upgrade:Bingo center/Research facility.func": { _, _ in G.pingScreen("special") },
        // (me)=>{G.unlock('Elder Pledge');}
        "Upgrade:Elder Pact.func": { _, _ in G.unlock("Elder Pledge") },
        // (me)=>{ G.elderWrath=0; G.collectWrinklers(); G.pledges++; G.win('Elder nap'); if (G.pledges>=5) G.win('Elder slumber');
        //   G.pledgeT=Date.now()+G.getPledgeDuration()*1000; G.unlock('Elder Covenant'); me.owned=0; G.toast(me.name,'Grandmatriarchs appeased.',me.icon,true); }
        "Upgrade:Elder Pledge.func": { me, _ in
            G.elderWrath = 0
            G.collectWrinklers()
            G.pledges += 1
            G.win("Elder nap")
            if G.pledges >= 5 { G.win("Elder slumber") }
            G.pledgeT = nowMs() + G.getPledgeDuration() * 1000
            G.unlock("Elder Covenant")
            me.owned = 0
            G.toast(me.name, "Grandmatriarchs appeased.", me.icon, true)
        },
        // (me)=>{ G.elderWrath=0; G.collectWrinklers(); G.pledgeT=0; G.win('Elder calm'); G.toggleOff('Elder Covenant');G.toggleOn('Revoke Elder Covenant'); G.toast(me.name,'Grandmapocalypse ended.',me.icon,true); }
        "Upgrade:Elder Covenant.func": { me, _ in
            G.elderWrath = 0
            G.collectWrinklers()
            G.pledgeT = 0
            G.win("Elder calm")
            G.toggleOff("Elder Covenant"); G.toggleOn("Revoke Elder Covenant")
            G.toast(me.name, "Grandmapocalypse ended.", me.icon, true)
        },
        // (me)=>{ G.toggleOff('Revoke Elder Covenant');G.toggleOn('Elder Covenant'); G.toast(me.name,'Covenant has been revoked...',me.icon,true); }
        "Upgrade:Revoke Elder Covenant.func": { me, _ in
            G.toggleOff("Revoke Elder Covenant"); G.toggleOn("Elder Covenant")
            G.toast(me.name, "Covenant has been revoked...", me.icon, true)
        },
        // (me)=>{ for (var i in G.seasons){G.seasons[i].triggerUpgrade.unlock();} }
        "Upgrade:Season switcher.func": { _, _ in for s in G.seasonsList { s.triggerUpgrade.unlock() } },
        // (me)=>{G.unlock('Golden switch [off]');}
        "Upgrade:Golden switch.func": { _, _ in G.unlock("Golden switch [off]") },
        // (me)=>{ G.toggleOff('Golden switch [off]');G.toggleOn('Golden switch [on]'); }
        "Upgrade:Golden switch [off].func": { _, _ in G.toggleOff("Golden switch [off]"); G.toggleOn("Golden switch [on]") },
        // (me)=>{ G.toggleOff('Golden switch [on]');G.toggleOn('Golden switch [off]'); }
        "Upgrade:Golden switch [on].func": { _, _ in G.toggleOff("Golden switch [on]"); G.toggleOn("Golden switch [off]") },
    ]

    static let upgradeTexts: [String: (Upgrade) -> String] = [
        // me=>{ return `Current boost: <b>+${B((me.getComputedEff('cpsM',1)-1)*100,1)}%</b>`; }
        "Upgrade:Century egg.preDescFunc": { me in "Current boost: <b>+\(B((me.getComputedEff("cpsM", 1) - 1) * 100, 1))%</b>" },
        // me=>{ Math.seedrandom(G.seed+'-blasphemouse'); if (Math.random()<0.3) {...`Absolutely blasphemouse!`} else {`Absolutely blasphemous!`} }
        "Upgrade:Mice clicking mice.qFunc": { _ in
            JSMath.seedrandom(G.seed + "-blasphemouse")
            let r = JSMath.random() < 0.3
            JSMath.seedrandom()
            return r ? "Absolutely blasphemouse!" : "Absolutely blasphemous!"
        },
        "Upgrade:Tombola computing.qFunc": { _ in tombola() },
    ]

    static let achievTexts: [String: (Achiev) -> String] = [
        // me=>{ (moves the #parade element) return me.desc; }
        "Achiev:Cookie Clicker.descFunc": { me in me.desc },
        // me=>{ let x=G.T; return `Everyone's here.<span id="parade" style="...background:url(img/parade.png) -${x}px ${G.T%20<10?0:32}px;..."></span>...Won't you have some cookies too?`; }
        "Achiev:Cookie Clicker.qFunc": { _ in
            "Everyone's here.<span id=\"parade\" style=\"position:absolute;left:-11px;right:-11px;height:32px;background:url(img/parade.png) -\(G.T)px \(G.T % 20 < 10 ? 0 : 32)px;display:block;\"></span><span style=\"margin-bottom:32px;display:block;\"></span>Won't you have some cookies too?"
        },
    ]

    /// Tombola computing's flavor text. The original has two bugs (`choose[...]` instead of `choose([...])`),
    /// which print "undefined"; kept as is.
    static func tombola() -> String {
        JSMath.seedrandom(G.seed + "-tombolacomputing")
        let n1 = Int((JSMath.random() * 100).rounded(.down)), n2 = Int((JSMath.random() * 100).rounded(.down))
        let n3 = Int((JSMath.random() * 100).rounded(.down)), n4 = Int((JSMath.random() * 100).rounded(.down))
        let lines = Int((JSMath.random() * 5 + 2).rounded(.down))
        let prizes = ["\(lines) lines of javascript", "one free use of Math.random()", "one qubit, whatever that is", "one half-eaten cookie", "a brand new vacuum cleaner", "most of one room-temperature cup of orange soda", "one really good sandwich", "one handful of pocket lint", "someone's mostly clean hairpiece", "a trip to a fancy restaurant", "the knowledge of those numbers", "a furtive glance at the news ticker", "another ticket, half-price", "all-you-can-eat moldy bread", "one lifetime supply of oxygen", "the color undefined", "increased intellect for a limited time", "an ancient runesword", "the throne of a far-away country", "the position of Mafia capo. Good luck", "one free time-travel week-end", "something beautiful", "the deed to some oil well", "one hamburger made out of the animal, plant, or person of your choice", "the last surviving undefined", "a deep feeling of accomplishment", "a fleeting tinge of entertainment", "a vague sense of unease", "deep existential dread", "one extra week added to your lifespan", "breathe manually", "blink right here and now", "one meeting with any famous person, living or dead, in your next dream", "one very nice dream", "a wacky sound effect", "45 seconds of moral flexibility", "hundreds and thousands, also known as \"sprinkles\"", "one circle, triangle, square or other simple geometric shape, of average dimensions", "just this extra bit of randomness", "the extra push you needed to turn your life around", "a good fright", "one secret superpower", "a better luck next time", "an irrational phobia of tombola tickets", "one whole spider", "an increased sense of self-worth and determination", "inner peace", "one double-XP week-end in the MMORPG of your choice", "a little piece of the universe, represented by the trillions of atoms that make up this very ticket", "food poisoning", "the Moon! Well, conceptually", "a new car, baby", "a new catchphrase", "an intrusive thought of your choice", "- ...aw man, it just cuts off there", "the director spot for the next big hit movie", "really good-looking calves", "one genuine pirate golden doubloon", "\"treasure and riches\", or something", "one boat, sunken", "baby shoes, never worn", "direct lineage to some King or Queen", "innate knowledge of a dead language you'll never encounter", "the melody of a song you don't know the words to", "white noise", "mild physical impairment", "a new pair of lips", "things, and such", "one popular expression bearing your name", "one typo", "one get-out-of-jail-free card", "the rest of your life... for now", "one polite huff", "a condescending stare", "one cursed monkey paw", "true love, probably", "an interesting factoid about the animal, country, TV show or celebrity of your choice", "a pop culture reference", "minutes of fun", "the etymology of the word \"tombola\" - it's Italian for \"a tumble\"", "nothing. You lost, sorry"]
        let str = "(Your ticket reads \(n1) \(n2) \(n3) \(n4), entitling you to " + choose(prizes) + ".)"
        JSMath.seedrandom()
        return "Like quantum computing, but more fun.<br>\(str)"
    }
}
