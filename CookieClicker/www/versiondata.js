/*
	the VERSIONDATA object holds information to be used by the live and alpha versions in different ways
	a version will only display HISTORY items with a version number less or equal to its own
*/

const VERSIONDATA={
	DEV:0,
	LIVE:8,
	TEST:8,
	ADLESS:1,
	ALPHA_FEATURES:`Several features have been ported over from the browser version, including all buildings, hundreds of upgrades and achievements, as well as seasons and fortune cookies. More things will be added before this update hits live. Stay tuned!`,
	HISTORY:[
		[8,`05/26/2024`,`Festivities & You`,`
			<b>ported over a large amount of features from the desktop version, such as:</b>|
			all buildings added|
			hundreds of upgrades and achievements added|
			seasons added|
			dragon and Santa added|
			fortune cookies added|
			golden switch added|
			wallpaper/milk selectors added|
			<b>additionally:</b>|
			new save export/import feature; create backups and transfer saves between devices at will|
			new "power clicks" heavenly upgrade|
			new options, such as toggling scary stuff|
			new customizable quick buttons|
			can now dislodge the big cookie|
			replaced tip system on the misc screen|
			the interface has been extensively redesigned!|
			heaps of other tweaks, fixes etc|
		`],
		[7.16,`07/04/2022`,`Scale fix`,`
			fixed a scaling bug introduced by a recent Android update; if this issue subsists, you may need to find "Android System WebView" in the play store and uninstall it
		`],
		[7,`10/05/2020`,`Beta patch!`,`
			switched engines (from Phonegap to Cordova)|
			permanent upgrade slots allow for more upgrades|
			prestige system is now available on live version|
			some achievements are now marked as "shadow"|
			added more info on the stats screen|
			the rest of the game no longer pauses when viewing the prestige screen|
			Lasting fortune, Decisive fate, Divine Sales and Divine Discount should now have effects|
			CpS bug from free buildings has been fixed|
			error messages should be more explicit|
			app should run a bit more smoothly, maybe|
			a bunch of other tweaks and fixes
		`],
		[6,`12/12/2019`,`Prestige!`,`
			added the ascension/prestige system, making the game truly endless (check the Special tab!)|
			<span style="color:#f00;">note: you must switch to the alpha version (in the Misc tab) to access the prestige system</span>|
			added a handful of prestige upgrades (25), with more to come later|
			golden cookie upgrades now work properly|
			cursor upgrade unlock requirements now match browser version|
			"Get lucky" now also affects wrath cookie effects|
			Elder Pledge should now function correctly|
			added achievements such as Builder, Mathematician etc|
			wrinkler offline production bug...possibly fixed?|
			fixed a bug where some particles would stick around|
			bulk-buy option that used to be 25 is now 10|
			new setting to disable the big cookie wobbling|
			new setting to disable the cookies popping in the background
		`],
		[5,`8/08/2019`,`Beta launch!`,`Cookie Clicker turns 6!|game is now on public beta track|thank you to all our patreon backers who helped us with the alpha!`],
		[4,`7/20/2019`,`Alpha patch!`,`added "Tab swipe" option (off by default)|cursor upgrades now correctly increase cookies per click|buildings now properly keep track of how much they've produced|toggles no longer purchased by "Buy all upgrades"|wrinklers no longer wonk out when changing settings|appeasing grandmas now pops all wrinklers|changed store tabs display|"cookies made while away" are now displayed when app is resumed in addition to when app is restarted|changed some display settings which may fix some issues (icon edges, font sizes...) but keep an eye out for any weirdness!`],
		[3,`6/10/2019`,`Alpha patch!`,`golden cookie effects now stack properly|fixed some more issues with golden cookies|fixed some issues with cursor/tap calculation|wrinklers popped are now saved|ad banner has been disabled and will likely remain so for the duration of the alpha`],
		[2,`6/7/2019`,`Alpha patch!`,`added the Bingo center/Research facility, which unlocks research in the special tab|added the Grandmapocalypse, along with wrinklers and wrath cookies|fixed buffs granting incorrect CpS when offline|mouse upgrades ("+1% of your CpS") now apply instantly|golden cookie clicks are now tracked properly|golden cookie should no longer spawn under the ad or menu|CpS achievements now require unbuffed CpS|max buy/sell now displays how much of each building will be bought/sold|replaced the audio system (was using the Media plugin, now uses the WebAudio API)`],
		[1,`5/23/2019`,`Alpha launch!`,`launched a private alpha for our Patreon supporters, with a minimal feature set to make sure we build on a solid base|at this point, the game features 329 upgrades and 317 achievements|the entire Special tab remains to be implemented`],
	],
};