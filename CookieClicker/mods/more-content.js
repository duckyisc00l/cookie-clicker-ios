/*
	Extra content for the iOS app: 4 new buildings after "You", each with 15 tiered upgrades and an
	"Unshackled" prestige upgrade, plus 6 new cookies. Built with the game's own G.Building and G.Upgrade,
	so they show up in the store, save and load, and follow the same rules as everything else.
	The app serves this file right after data.js. Upgrade ids start at 2000 to stay clear of the game's own.
	Art: icons.png and buildings.png are served extended with new columns/rows (see mods/).
*/
G.addData(function(){

	const BUILDINGS=[
		{
			name:`Black hole`,single:`black hole`,plural:`black holes`,actionName:`pulled in`,
			extraName:`[X] extra event horizon`,extraPlural:`[X] extra event horizons`,
			desc:`Pulls in cookies from across the universe and squeezes them into denser, tastier ones.`,
			foolName:`Bottomless jar`,foolPlural:`Bottomless jars`,foolDesc:`A cookie jar so deep, nobody has ever seen the bottom.`,
			cost:2.4e28,cps:4.1e15,
			tiers:[
				[`Spaghettification`,`Cookies stretched infinitely thin are technically the same cookie. Legally, this means unlimited cookies.`],
				[`Accretion sprinkles`,`Matter spiraling in at near light-speed heats up into a glowing ring of rainbow sprinkles.`],
				[`Hawking radiators`,`Your black holes slowly leak warmth back out, which turns out to be the perfect temperature for proofing dough.`],
				[`Event horizon ovens`,`Time stops at the edge, so cookies never burn. They also never finish baking, but we're working on it.`],
				[`Gravitational lensing`,`Bends light around the bakery so every customer sees exactly the cookie they wanted.`],
				[`Supermassive appetite`,`Your black holes have been encouraged to eat more. It's working. Please stand back.`],
				[`Singularity frosting`,`An infinitely dense dollop of frosting. One serving covers about four billion cookies.`],
				[`Wormhole delivery`,`Cookies go in one end and come out in a customer's mouth on the other side of the galaxy. Some assembly required.`],
				[`Dark flour`,`Makes up 85% of all the flour in the universe, yet nobody can see it. Excellent for invisible pastries.`],
				[`Tidal kneading`,`Gravity kneads the dough for you, pulling and stretching it from every direction at once.`],
				[`No-hair theorem`,`Black holes have no hair. That's one less thing to find in the cookies.`],
				[`Quasar ignition`,`Feed a black hole enough cookie dough and it lights up brighter than a trillion suns. Excellent for midnight baking.`],
				[`Information paradox`,`Recipes thrown in never come out, which is great for protecting trade secrets.`],
				[`Kugelblitz`,`A black hole made from pure light instead of matter. Bakes cookies with a satisfying crunch.`],
				[`White hole reversal`,`The opposite of a black hole: nothing goes in, and cookies just keep coming out. Nobody is asking questions.`],
			],
			unshackle:`They were never really holding back.`,
		},
		{
			name:`Galaxy`,single:`galaxy`,plural:`galaxies`,actionName:`spun up`,
			extraName:`[X] extra spiral arm`,extraPlural:`[X] extra spiral arms`,
			desc:`A whole spiral of a billion cookie-stars, slowly turning towards your bank account.`,
			foolName:`Cookie sampler`,foolPlural:`Cookie samplers`,foolDesc:`An assortment of every cookie flavor. Somebody always takes the last good one.`,
			cost:5.5e30,cps:3.3e16,
			tiers:[
				[`Milky Way`,`The original. Named after the milk it was dunked in.`],
				[`Spiral arm conveyor`,`Cookies ride the galaxy's spiral arms all the way out to the shipping docks. It only takes 200 million years.`],
				[`Star nurseries`,`Clouds of gas and sugar where young cookie-stars are born and raised.`],
				[`Galactic core bakery`,`The center of every galaxy is crowded, hot and loud. Perfect for an industrial oven.`],
				[`Dark matter halo`,`An invisible ring of something holds your galaxies together. You suspect it's caramel.`],
				[`Andromeda merger`,`Two galaxies colliding at incredible speed. The cookies inside barely notice, but they do get mixed up nicely.`],
				[`Nebula icing`,`Glowing pastel clouds, light-years wide, piped on in a single swirl.`],
				[`Globular clusters`,`Tight little balls of very old stars. Great for chewy cookies.`],
				[`Interstellar sugar lanes`,`Trade routes between the stars, lined with sugar-coated rest stops.`],
				[`Cosmic web`,`Galaxies are strung together like beads on a necklace, which makes them a lot easier to carry to market.`],
				[`Redshift glaze`,`Cookies moving away from you look slightly redder. Customers say they taste like strawberry.`],
				[`Hubble expansion`,`The universe keeps getting bigger, so there's always room for another bakery.`],
				[`Galactic federation`,`A council of a thousand galaxies has unanimously voted that you deserve more cookies.`],
				[`Laniakea`,`Your galaxies belong to a supercluster whose name means "immeasurable heaven". The real estate is very expensive.`],
				[`The great attractor`,`Something out there is pulling every galaxy towards it. You've decided it's your shop.`],
			],
			unshackle:`Spin it faster.`,
		},
		{
			name:`Multiverse mixer`,single:`multiverse mixer`,plural:`multiverse mixers`,actionName:`stirred`,
			extraName:`[X] extra speed setting`,extraPlural:`[X] extra speed settings`,
			desc:`Stirs every possible universe together into one enormous bowl of cookie batter.`,
			foolName:`Stand mixer`,foolPlural:`Stand mixers`,foolDesc:`Every kitchen's best friend. Also very loud.`,
			cost:1.3e33,cps:2.7e17,
			tiers:[
				[`Infinite whisk`,`A whisk with more wires than there are atoms. Cleaning it is a different universe's problem.`],
				[`Fold in gently`,`Universes are delicate. Fold them in slowly, or physics gets lumpy.`],
				[`Many-worlds batter`,`In every branch of reality, someone is eating one of your cookies. That's a lot of branches.`],
				[`Parallel pantry`,`Ran out of eggs? Borrow some from a universe where you didn't.`],
				[`Quantum creaming`,`Butter and sugar are creamed together and not creamed together until somebody looks.`],
				[`Probability sifter`,`Shakes out the lumpy, unlikely universes, keeping only the smoothest outcomes.`],
				[`Alternate you sous-chefs`,`Hire the versions of you that went to culinary school. They're a little smug about it.`],
				[`Dimensional dough hook`,`Kneads dough in seven directions at once. Two of them you can't see.`],
				[`Reality emulsifier`,`Keeps mutually exclusive universes from separating, like oil and vinegar but much louder.`],
				[`Cross-world taste testers`,`They try every cookie in every universe, and report back on which one is best. It's always yours.`],
				[`Paradox proofing`,`Lets the dough rise before you've mixed it. Saves a lot of time.`],
				[`Omni-flavor extract`,`Every flavor that ever was or could be, in one tiny bottle. Just a drop, please.`],
				[`Universe-scale bowl`,`Your mixing bowl is now larger than the observable universe. Finding a sink for it remains an issue.`],
				[`Turbo setting`,`The mixer was never meant to go this fast. Several universes have been flung against the wall.`],
				[`Everything everywhere all at once`,`Every universe mixed in, every cookie baked, all at the same time. Somehow it still needs to cool on a rack.`],
			],
			unshackle:`Set it to eleven.`,
		},
		{
			name:`Big bang`,single:`big bang`,plural:`big bangs`,actionName:`exploded`,
			extraName:`[X] extra second of creation`,extraPlural:`[X] extra seconds of creation`,
			desc:`Restarts reality from scratch, over and over, keeping only the cookies each time.`,
			foolName:`Party popper`,foolPlural:`Party poppers`,foolDesc:`Celebrate good times with a little explosion of confetti.`,
			cost:3e35,cps:2.2e18,
			tiers:[
				[`Primordial dough`,`In the very first second, everything was a hot, dense ball of cookie dough. Some scientists believe it still is.`],
				[`Cosmic inflation`,`The universe doubled in size a hundred times in a split second. So did your profits.`],
				[`Recombination`,`As the universe cooled, flour and water finally came together. It took about 380,000 years.`],
				[`Background radiation`,`A faint, warm glow left over from the beginning of time. It smells faintly of fresh cookies.`],
				[`First stars`,`The very first stars were huge and very hot. They made excellent ovens.`],
				[`Nucleosynthesis`,`Forging the heavy elements needed for good cookies: carbon, oxygen, and the rare earth metal chocolatium.`],
				[`Big crunch`,`Eventually, the universe collapses back into a single point. Satisfying, but very crumbly.`],
				[`Big bounce`,`After every crunch comes another bang. It's a reliable business model.`],
				[`Fine-tuned constants`,`Tweaked the laws of physics so that cookies come out slightly chewier.`],
				[`Planck-time timer`,`A kitchen timer precise to 10^-44 seconds. Overbaking is now impossible.`],
				[`Baby universes`,`Little pocket universes bud off the big one. They grow up so fast.`],
				[`Eternal inflation`,`New universes keep popping into existence forever, like popcorn in a microwave that never stops.`],
				[`Vacuum decay`,`If the universe falls into a lower energy state, everything is replaced by cookies. You've been rooting for it.`],
				[`Second law repeal`,`Your lawyers successfully argued that entropy shouldn't apply to baked goods.`],
				[`Let there be cookies`,`And there were cookies, and it was good.`],
			],
			unshackle:`Louder this time.`,
		},
	];

	let unshackleCost=19200000000000000;//after "Unshackled You"
	let unshackleParent=`Unshackled You`;
	BUILDINGS.forEach(function(o,n){
		let me=new G.Building({
			name:o.name,single:o.single,plural:o.plural,actionName:o.actionName,
			extraName:o.extraName,extraPlural:o.extraPlural,desc:o.desc,
			foolName:o.foolName,foolPlural:o.foolPlural,foolDesc:o.foolDesc,
			pic:21+n,icon:[36+n,0],
			cost:o.cost,cps:o.cps,
		});
		//the game works out price and output from the building's position; set them to follow the same curve as the last buildings
		me.baseCost=o.cost;
		me.baseCps=o.cps;

		o.tiers.forEach(function(t,i){
			let tier=i+1;
			new G.Upgrade({
				name:t[0],id:2000+n*20+i,q:t[1],
				cost:o.cost*5*G.tiers[tier].price,//the game's tier prices are based on about 5x a building's starting price
				pool:`building`,order:1800+n*100+tier*0.001,tie:me.id,tier:tier,
			});
		});

		unshackleCost*=1.43;
		let unshackle=new G.Upgrade({
			name:`Unshackled ${o.plural}`,id:2000+n*20+15,q:o.unshackle,
			icon:[36+n,35],order:768.02+n*0.001,cost:Math.round(unshackleCost/1e9)*1e9,
			pool:'unshackle',tie:me.id,parents:[unshackleParent],
			desc:`Tiered upgrades for <b>${cap(o.plural)}</b> provide an extra <b>+10%</b> production.<br>Only works with unshackled upgrade tiers.`,
		});
		unshackle.power=0.1;
		unshackleParent=unshackle.name;
	});
	//place the new Unshackled upgrades on the heavenly upgrade map, continuing the ring after "Unshackled You"
	(function(){
		const spots=[[368,662],[272,706],[172,744],[70,772]];
		let prev=864;
		BUILDINGS.forEach(function(o,n){
			const id=2000+n*20+15;
			G.HeavenlyUpgradePositions[id]=spots[n]||[70-(n-3)*100,780];
			G.HeavenlyUpgradeParents[id]=[prev];
			prev=id;
		});
		//safety net: any heavenly upgrade without a spot on the map gets one instead of crashing the heaven screen
		let extra=0;
		for (const me of G.upgrades) if (me && me.pool=='prestige')
		{
			if (!G.HeavenlyUpgradePositions[me.id]) {G.HeavenlyUpgradePositions[me.id]=[-700+(extra%8)*100,1000+Math.floor(extra/8)*100];extra++;}
			if (!G.HeavenlyUpgradeParents[me.id]) G.HeavenlyUpgradeParents[me.id]=[];
		}
	})();

	const COOKIES=[
		[`Stardust snickerdoodles`,`Rolled in cinnamon and a pinch of actual stardust, collected by very patient astronauts.`],
		[`Supernova shortbread`,`Baked in the last few seconds of a dying star. Crumbly, golden and briefly brighter than the whole galaxy.`],
		[`Event horizon brownies`,`So rich and dense that not even light can escape. Hard to photograph for the menu.`],
		[`Comet crinkles`,`Crackled, icy cookies with a long glittery tail of powdered sugar.`],
		[`Big bang biscotti`,`Twice-baked, at the very beginning of time and again just now. Crunchier than anything in this universe.`],
		[`Nebula meringues`,`Light, airy and swirled with every color of a starry gas cloud. Mostly air, but very pretty air.`],
	];
	COOKIES.forEach(function(c,i){
		let cost=1e70*Math.pow(Math.sqrt(10),i);
		new G.Upgrade({
			name:c[0],id:2100+i,q:c[1],icon:[40,i],
			cost:cost,pool:`cookie`,order:10020.9+i*0.001,power:5,
			unlockAt:{cookies:cost/20},
		});
	});
});

/*
	More news ticker headlines. Mixed in with the game's own: whenever the game picks a "News :" headline,
	about a third of the time one of these is shown instead (only ones that fit what you own).
*/
G.addData(function(){
	const BUILDING_NEWS={
		'Cursor':[
			`News : local cursor clicks so fast it briefly achieves flight; "it was the best four seconds of my life", it reportedly said.`,
			`News : cursors unionize, demand ergonomic mouse pads and one (1) paid day off per century.`,
		],
		'Grandma':[
			`News : grandmas' knitting circle accidentally produces a scarf long enough to wrap the moon. "It gets cold up there", they explain.`,
			`News : study finds 98% of grandmas believe you look thin and should have another cookie. The other 2% were busy baking.`,
		],
		'Farm':[
			`News : cookie farmers report bumper crop of chocolate chips; scarecrows replaced with very stern gingerbread men.`,
			`News : farmers' market now sells only cookies, cookie seeds, and pamphlets on how to grow more cookies.`,
		],
		'Mine':[
			`News : miners strike chocolate vein so pure it hums faintly. Experts advise "do not lick the walls".`,
			`News : deepest cookie mine yet reaches Earth's molten caramel core.`,
		],
		'Factory':[
			`News : factory conveyor belt reaches top speed; cookies now leave the factory before they're made.`,
			`News : robot workers vote to rename factory "The Snackery". Management "unsure how they learned to vote".`,
		],
		'Bank':[
			`News : cookie bank introduces "crumb-back" credit card. Cardholders report sticky wallets.`,
			`News : economists warn of cookie bubble; cookie bankers respond by eating the economists' cookies.`,
		],
		'Temple':[
			`News : temple monks achieve enlightenment, immediately ask if there are any more cookies.`,
			`News : ancient prophecy uncovered: "and on the final day, there shall be milk". Scholars thrilled.`,
		],
		'Wizard tower':[
			`News : wizard accidentally turns himself into a cookie, says it's "honestly an improvement".`,
			`News : spell to summon infinite cookies works perfectly, causes mild cookie flooding in three counties.`,
		],
		'Shipment':[
			`News : cookie shipment lands on wrong planet; locals declare it "the best thing to ever fall from the sky".`,
			`News : space truckers demand cookie-proof cupholders after 900th crumb-related engine failure.`,
		],
		'Alchemy lab':[
			`News : alchemists finally turn lead into gold, are disappointed it isn't chocolate.`,
			`News : philosopher's stone found to be a very old, very hard cookie. Still edible, say alchemists.`,
		],
		'Portal':[
			`News : portal briefly opens into a dimension made entirely of milk. Cleanup crews optimistic.`,
			`News : tourists flock to portals for "dimension hopping holidays"; most come back with souvenir cookies.`,
		],
		'Time machine':[
			`News : time travelers warn about the year 3000. "Not because of anything bad. It's just there are so many cookies."`,
			`News : time machine used to give past self a cookie; past self eats it before you finish explaining.`,
		],
		'Antimatter condenser':[
			`News : scientists discover anti-cookies; eating one and a cookie together results in "a very loud snack".`,
			`News : antimatter condenser leaks, replaces small region of the countryside with exact opposite of a bakery.`,
		],
		'Prism':[
			`News : prisms produce a new color never seen before. Experts name it "cookie".`,
			`News : rainbow lawsuit settled out of court; prisms agree to share credit for "making light delicious".`,
		],
		'Chancemaker':[
			`News : local man wins lottery 41 times in a row, thanks nearby chancemaker, receives cookies as prize every time.`,
			`News : chancemakers predict 100% chance of cookies tomorrow. Meteorologists give up.`,
		],
		'Fractal engine':[
			`News : fractal engine produces a cookie that contains a smaller cookie that contains a smaller cookie. Nobody has reached the bottom.`,
			`News : mathematicians baffled as fractal cookies turn out to have infinite surface area but still fit in a jar.`,
		],
		'Javascript console':[
			`News : programmer types "cookies++" into console; "nothing happened", he reports, from under a pile of cookies.`,
			`News : software update for cookie console fixes 3 bugs, adds 11 new ones, and somehow also adds sprinkles.`,
		],
		'Idleverse':[
			`News : idleverse discovered where everyone plays a game about clicking on a very large potato.`,
			`News : visitors from a neighboring idleverse ask what a "cookie" is, leave four hours later with forty.`,
		],
		'Cortex baker':[
			`News : cortex baker solves every math problem ever written, demands only cookies and "a little quiet".`,
			`News : cortex baker writes a novel; critics call it "brilliant, but mostly about cookies".`,
		],
		'You':[
			`News : clone of you asks clone of you to pass the cookies; both reach for the same one. Diplomatic crisis averted.`,
			`News : "There can't be too many of me", says you, through 600,000 mouths at once.`,
		],
		'Black hole':[
			`News : black hole bakery sends apologies to the three galaxies it ate "by accident". Says it "thought they were cookies".`,
			`News : astronomers detect black hole burping. Smells like chocolate chips, report nearby satellites.`,
			`News : black hole tourism booming; visitors report spending a week there and coming home 40 years later.`,
			`News : physicists confirm what goes into your black holes never comes out, except as slightly denser cookies.`,
			`News : leading scientist asks you to "please stop feeding the black holes". Black holes visibly disappointed.`,
		],
		'Galaxy':[
			`News : night sky now mostly cookies; stargazers say the constellations "look a lot more delicious lately".`,
			`News : galaxy collision causes largest cookie spill in recorded history. Cleanup expected to take 4 billion years.`,
			`News : new star chart renames the Big Dipper "the Big Dunker".`,
			`News : alien civilizations finally make contact, only to ask which galaxy has the best cookies. It's yours.`,
			`News : astronomers fired after discovering that every star they ever studied was a very distant cookie.`,
		],
		'Multiverse mixer':[
			`News : multiverse mixer set to "high" splashes three universes onto the ceiling.`,
			`News : residents of mixed-up universes report minor side effects including "talking dogs" and "Tuesday happening twice".`,
			`News : the multiverse is now 87% cookie batter, according to a survey nobody asked for.`,
			`News : alternate version of you who never made cookies files formal complaint about "being left out".`,
			`News : philosophers argue whether a universe stirred into batter still counts as a universe. Cookie bakers say "it counts as dessert".`,
		],
		'Big bang':[
			`News : universe restarted for the 9,000th time this week; residents say "you get used to it".`,
			`News : physicists finally learn what caused the big bang: someone wanted cookies. It was you.`,
			`News : each new big bang now starts with a short message: "this universe brought to you by your cookie empire".`,
			`News : time officially restarted again; calendars printed with "year 0" sell out instantly.`,
			`News : "Let there be cookies", says booming voice; there are cookies. Again.`,
		],
	};
	const GENERAL_NEWS=[
		`News : cookie now the official unit of measurement in 34 countries. "One cookie" is roughly the size of a cookie.`,
		`News : world's longest cookie stretches across two continents; nobody is sure which end to start eating from.`,
		`News : dentists' convention cancelled after all attendees left to buy cookies.`,
		`News : local cat knocks cookie off table, makes direct eye contact, refuses to apologize.`,
		`News : study shows people who eat cookies are 100% more likely to have eaten a cookie.`,
		`News : milk sales surge; cows ask for "a little appreciation, maybe a thank-you card".`,
		`News : new smartphone app lets you click a cookie on the go. Productivity experts "deeply concerned".`,
		`News : cookie emoji declared the most used emoji of the year, narrowly beating "crying-laughing face eating cookie".`,
		`News : world leaders meet to discuss global cookie shortage; cookie shortage turns out to be one guy who ate them all.`,
		`News : baking-themed reality show reaches 400th season; contestants have started living in the tent.`,
		`News : scientists clone world's first cookie; it tastes "exactly the same, but somehow more smug".`,
		`News : cookie crumbs now detectable in every snowflake, raindrop and cloud on Earth, say climatologists.`,
		`News : town renames itself "Cookieville" for tax reasons; residents "fully support the decision".`,
		`News : cookie jar declared historical monument, can no longer legally be opened. Public outraged.`,
		`News : marathon runners now refuel with cookies; finish times worse, mood "significantly better".`,
		`News : fortune cookie predicts it will be eaten. Fortune cookie correct.`,
		`News : new cookie-scented cologne a hit with dogs, less so with humans.`,
		`News : traffic jam on highway caused by overturned cookie truck turns into impromptu picnic.`,
		`News : record-breaking cookie stack reaches 2 miles high before being eaten by a passing pigeon.`,
		`News : kids around the world unanimously vote that broccoli should be replaced with cookies. Parents "considering it".`,
		`News : astronauts report Earth now visibly cookie-shaped from orbit.`,
		`News : local bakery opens; immediately bought out by your cookie empire. Local bakery "honestly relieved".`,
		`News : psychologists coin new term, "cookie-brain", for the condition of thinking about cookies all the time. Patients deny everything while eating cookies.`,
		`News : cookie-flavored toothpaste recalled after customers swallowed it on purpose.`,
		`News : museum unveils painting of a cookie; critics praise "the bold use of chocolate".`,
		`News : weather forecast predicts light crumbs in the morning, heavy cookie showers by afternoon.`,
		`News : school cafeterias now serve cookies with every meal, as a side, and as the main course.`,
		`News : "I clicked a cookie once and now I can't stop", admits famous celebrity in tell-all interview.`,
		`News : ancient cave paintings reveal early humans also clicked on cookies. Archaeologists "not at all surprised anymore".`,
		`News : your cookie empire now officially bigger than the economy of everything else, combined.`,
	];
	const original=G.getTicker;
	G.getTicker=function(){
		const pick=original.apply(this,arguments);
		if (typeof pick!=='string' || pick.indexOf('News :')!==0 || Math.random()>=0.35) return pick;
		const extra=[];
		for (const name in BUILDING_NEWS){if (G.buildingsBN[name] && G.buildingN(name)>0) extra.push(...BUILDING_NEWS[name]);}
		if (G.cookiesEarned>=100000) extra.push(...GENERAL_NEWS);
		return extra.length?choose(extra):pick;
	};
});
