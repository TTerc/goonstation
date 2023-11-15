// zamu's "mail".
//
// mail in this case is actually just timed gifts sent to the crew,
// through the cargo system.
//
// mail is "locked" to the mob that should receive it,
// via dna (or whatever. todo: update me)
//
// ideally, the amount of mail "per cycle" would vary depending on
// how long since the last one and how many players are online
// ideally every player would get a few pieces of mail over the
// course of an hour (say, every 20 minutes)

/obj/item/random_mail
	name = "mail"
	desc = "A package!"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "mail-1"
	item_state = "gift"
	pressure_resistance = 70
	var/random_icons = TRUE
	var/spawn_type = null
	var/tmp/target_dna = null

	// this is largely copied from /obj/item/a_gift

	New()
		..()
		if (src.random_icons)
			src.icon_state = "mail-[rand(1,3)]"

	attack_self(mob/M as mob)
		if (!ishuman(M))
			boutput(M, SPAN_NOTICE("You aren't human, you definitely can't open this!"))

		if (src.target_dna)
			var/dna = M?.bioHolder?.Uid

			if (!dna || dna != src.target_dna)
				boutput(M, SPAN_NOTICE("This isn't addressed to you! Opening it would be <em>illegal!</em> Also, the DNA lock won't open."))
				return

		if (!src.spawn_type)
			boutput(M, SPAN_NOTICE("[src] was empty! What a rip!"))
			qdel(src)
			return

		var/obj/item/prize = new src.spawn_type
		if (!istype(prize) && prize)
			boutput(M, SPAN_NOTICE("You somehow pull \a [prize] out of \the [src]!"))
			prize.set_loc(get_turf(M))
			qdel(src)
			return

		boutput(M, SPAN_NOTICE("You open the package and pull out \a [prize]."))
		logTheThing(LOG_DIARY, M, "opened their [src] and got \a [prize].")
		M.u_equip(src)
		M.put_in_hand_or_drop(prize)
		qdel(src)





/proc/create_random_mail(where, how_many = 1)

	// [mob] =  (name, rank, dna)
	var/list/crew = list()

	// get a list of all living, connected players
	// that are not in the afterlife bar
	// and which are on the manifest
	for (var/client/C)
		if (!isliving(C.mob) || isdead(C.mob) || !ishuman(C.mob) || inafterlife(C.mob))
			continue

		var/mob/living/carbon/human/M = C.mob
		if (!istype(M)) continue	// this shouldn't be possible given ishuman, but lol

		var/datum/db_record/manifest_record = data_core.general.find_record("id", M.datacore_id)
		if (!manifest_record) continue	// must be on the manifest to get mail, sorry

		// these are all things we will want later
		crew[M] = list(
			name = manifest_record.get_field("name"),
			job = manifest_record.get_field("rank"),
			dna = manifest_record.get_field("dna"),
			)

	// nobody here
	if (crew.len == 0)
		return list()


	// put created items here
	var/list/mail = list()

	for (var/i in 1 to how_many)
		// get one of our living, on-manifest crew members
		var/recipient = crew[pick(crew)]
		var/datum/job/J = find_job_in_controller_by_string(recipient["job"])

		// make a gift for this person
		var/obj/item/random_mail/package = null

		// the probability here can go up as the number of items for jobs increases.
		// right now the job pools are kind of small for some, so only use it sometimes.
		if (prob(50) && length(mail_types_by_job[J.type]))
			var/spawn_type = weighted_pick(mail_types_by_job[J.type])
			package = new(where)
			package.spawn_type = spawn_type
			package.name = "mail for [recipient["name"]] ([recipient["job"]])"
			package.color = J.linkcolor

		else
			// if there are no job specific items or we aren't doing job-specific ones,
			// just throw some random crap in there, fuck it. who cares. not us
			var/spawn_type = weighted_pick(mail_types_everyone)
			package = new(where)
			package.spawn_type = spawn_type
			package.name = "mail for [recipient["name"]]"

		// packages are dna-locked so you can't just swipe everyone's mail like a jerk.
		package.target_dna = recipient["dna"]
		package.desc = "A package for [recipient["name"]]. It has a DNA-based lock, so only [recipient["name"]] can open it."

		mail += package

	return mail













// =======================================================
// Various random items jobs can get via the "mail" system

var/global/mail_types_by_job = list(
	/datum/job/command/captain = list(
		/obj/item/clothing/suit/bedsheet/captain = 2,
		/obj/item/item_box/gold_star = 1,
		/obj/item/stamp/cap = 2,
		/obj/item/cigarbox/gold = 2,
		/obj/item/paper/book/from_file/captaining_101 = 1,
		/obj/item/disk/data/floppy/read_only/communications = 1,
		/obj/item/reagent_containers/food/drinks/bottle/champagne = 3,
		/obj/item/pinpointer/category/pets = 2,
		),

	/datum/job/command/head_of_personnel = list(
		/obj/item/toy/judge_gavel = 3,
		/obj/item/storage/box/id_kit = 2,
		/obj/item/stamp/hop = 3,
		/obj/item/storage/box/trackimp_kit = 1,
		/obj/item/pinpointer/category/pets = 1,
		),

	/datum/job/command/head_of_security = list(
		),

	/datum/job/command/chief_engineer = list(
		/obj/item/rcd_ammo = 10,
		),

	/datum/job/command/research_director = list(
		/obj/item/disk/data/tape/master/readonly = 5,
		/obj/item/aiModule/random = 1,
		),
	/datum/job/command/medical_director = list(
		),


	/datum/job/security/security_officer = list(
		/obj/item/reagent_containers/food/drinks/coffee = 15,
		/obj/item/reagent_containers/food/snacks/donut/custom/random = 15,
		/obj/item/reagent_containers/food/snacks/donut/custom/robust = 1,
		/obj/item/reagent_containers/food/snacks/donut/custom/robusted = 1,
		/obj/item/device/flash = 3,
		/obj/item/clothing/head/helmet/siren = 2,
		/obj/item/handcuffs = 2,
		),
	/datum/job/security/security_officer/assistant = list(
		/obj/item/reagent_containers/food/drinks/coffee = 15,
		/obj/item/reagent_containers/food/snacks/donut/custom/random = 15,
		/obj/item/reagent_containers/food/snacks/donut/custom/robust = 1,
		/obj/item/reagent_containers/food/snacks/donut/custom/robusted = 1,
		/obj/item/device/flash = 3,
		/obj/item/clothing/head/helmet/siren = 2,
		),
	/datum/job/security/detective = list(
		),



	/datum/job/research/scientist = list(
		/obj/item/parts/robot_parts/arm/right/light = 5,
		/obj/item/cargotele = 5,
		/obj/item/disk/data/tape = 5,
		/obj/item/pinpointer/category/artifacts/safe = 20,
		/obj/item/pinpointer/category/artifacts = 1,
		),

	/datum/job/research/medical_doctor = list(
		/obj/item/reagent_containers/mender/brute = 10,
		/obj/item/reagent_containers/mender/burn = 10,
		/obj/item/reagent_containers/mender/both = 5,
		/obj/item/reagent_containers/mender_refill_cartridge/brute = 25,
		/obj/item/reagent_containers/mender_refill_cartridge/burn = 25,
		/obj/item/reagent_containers/mender_refill_cartridge/both = 10,
		/obj/item/item_box/medical_patches/mini_styptic = 10,
		/obj/item/item_box/medical_patches/mini_silver_sulf = 10,
		/obj/item/medicaldiagnosis/stethoscope = 5,
		/obj/item/reagent_containers/hypospray = 2,
		/obj/item/reagent_containers/food/snacks/candy/lollipop/random_medical = 5
		),

	/datum/job/research/roboticist = list(
		/obj/item/reagent_containers/mender/brute = 10,
		/obj/item/reagent_containers/mender/burn = 10,
		/obj/item/reagent_containers/mender/both = 5,
		/obj/item/reagent_containers/mender_refill_cartridge/brute = 25,
		/obj/item/reagent_containers/mender_refill_cartridge/burn = 25,
		/obj/item/reagent_containers/mender_refill_cartridge/both = 10,
		/obj/item/robot_module = 20,
		/obj/item/parts/robot_parts/robot_frame = 15,
		/obj/item/cell/supercell/charged = 10,

		),
	/datum/job/research/geneticist = list(
		),



	/datum/job/engineering/engineer = list(
		/obj/item/chem_grenade/firefighting = 15,
		/obj/item/old_grenade/oxygen = 15,
		/obj/item/chem_grenade/metalfoam = 10,
		/obj/item/cable_coil = 10,
		/obj/item/lamp_manufacturer/organic = 5,
		/obj/item/pen/infrared = 10,
		/obj/item/sheet/steel/fullstack = 2,
		/obj/item/sheet/glass/fullstack = 2,
		/obj/item/rods/steel/fullstack = 2,
		/obj/item/tile/steel/fullstack = 2,
		),

	/datum/job/engineering/quartermaster = list(
		/obj/item/currency/spacecash/hundred = 10,
		/obj/item/currency/spacecash/fivehundred = 7,
		/obj/item/currency/spacecash/tourist = 3,
		/obj/item/stamp/qm = 5,
		/obj/item/cargotele = 3,
		/obj/item/device/appraisal = 4,
		),

	/datum/job/engineering/miner = list(
		/obj/item/device/gps = 5,
		/obj/item/satchel/mining = 10,
		/obj/item/satchel/mining/large = 2,
		),



	/datum/job/civilian/chef = list(
		/obj/item/kitchen/utensil/knife/bread = 5,
		/obj/item/kitchen/utensil/knife/cleaver = 5,
		/obj/item/kitchen/utensil/knife/pizza_cutter = 5,
		/obj/item/reagent_containers/food/drinks/mug = 5,
		/obj/item/reagent_containers/food/drinks/tea = 5,
		/obj/item/reagent_containers/food/drinks/coffee = 5,
		/obj/item/reagent_containers/food/snacks/ingredient/egg = 5,
		/obj/item/reagent_containers/food/snacks/plant/tomato = 5,
		/obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat = 5,
		),

	/datum/job/civilian/bartender = list(
		/obj/item/reagent_containers/food/drinks/drinkingglass = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/cocktail = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/shot = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/flute = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/wine = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/oldf = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/pitcher = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/round = 2,
		/obj/item/reagent_containers/food/drinks/drinkingglass/random_style/filled/sane = 5,
		/obj/item/reagent_containers/food/drinks/bottle/hobo_wine = 4,
		),

	/datum/job/civilian/botanist = list(
		/obj/item/reagent_containers/food/snacks/ingredient/egg/bee = 10,
		/obj/item/plant/herb/cannabis/spawnable = 5,
		/obj/item/seed/alien = 10,
		/obj/item/satchel/hydro = 10,
		/obj/item/satchel/hydro/large = 2,
		/obj/item/reagent_containers/glass/bottle/powerplant = 5,
		/obj/item/reagent_containers/glass/bottle/fruitful = 5,
		/obj/item/reagent_containers/glass/bottle/topcrop = 5,
		/obj/item/reagent_containers/glass/bottle/groboost = 5,
		/obj/item/reagent_containers/glass/bottle/mutriant = 5,
		/obj/item/reagent_containers/glass/bottle/weedkiller = 5,
		/obj/item/reagent_containers/glass/compostbag = 5,
		/obj/item/reagent_containers/glass/happyplant = 1,
		),

	/datum/job/civilian/rancher = list(
		),

	/datum/job/civilian/janitor = list(
		/obj/item/chem_grenade/cleaner = 5,
		/obj/item/sponge = 20,
		/obj/item/spraybottle/cleaner = 10,
		/obj/item/caution = 10,
		/obj/item/reagent_containers/glass/bottle/acetone/janitors = 3,
		/obj/item/mop = 5,
		),

	/datum/job/civilian/chaplain = list(
		/obj/item/bible = 2,
		/obj/item/device/light/candle = 10,
		/obj/item/device/light/candle/small = 15,
		/obj/item/device/light/candle/spooky = 2,
		/obj/item/ghostboard = 5,
		/obj/item/ghostboard/emouija = 1,
		/obj/item/card_box/tarot = 2,
		/obj/item/reagent_containers/glass/bottle/holywater = 3,
		),

	/datum/job/civilian/clown = list(
		/obj/item/reagent_containers/food/snacks/plant/banana = 15,
		/obj/item/storage/box/balloonbox = 5,
		/obj/item/canned_laughter = 15,
		/obj/item/bananapeel = 10,
		/obj/item/toy/sword = 3,
		/obj/item/rubber_hammer = 1,
		/obj/item/balloon_animal/random = 3,
		/obj/item/pen/crayon/rainbow = 2,
		/obj/item/pen/crayon/random = 1,
		/obj/item/storage/goodybag = 3,
		),
	/datum/job/civilian/staff_assistant = list(
		)
	)


// =========================================================================
// Items given out to anyone, either when they have no job items or randomly
var/global/mail_types_everyone = list(
	/obj/item/a_gift/festive =2,
	/obj/item/reagent_containers/food/drinks/drinkingglass/random_style/filled/sane = 3,
	/obj/item/reagent_containers/food/snacks/donkpocket_w = 4,
	/obj/item/reagent_containers/food/drinks/cola = 10,
	/obj/item/reagent_containers/food/snacks/candy/chocolate = 5,
	/obj/item/reagent_containers/food/snacks/chips = 5,
	/obj/item/reagent_containers/food/snacks/popcorn = 5,
	/obj/item/reagent_containers/food/snacks/candy/lollipop/random_medical = 4,
	/obj/item/tank/emergency_oxygen = 5,
	/obj/item/wrench = 5,
	/obj/item/crowbar = 5,
	/obj/item/screwdriver = 5,
	/obj/item/weldingtool = 5,
	/obj/item/device/radio = 5,
	/obj/item/currency/spacecash/small = 5,
	/obj/item/currency/spacecash/tourist = 1,
	/obj/item/coin = 5,
	/obj/item/pen/fancy = 3,
	/obj/item/toy/plush = 3,
	/obj/item/toy/figure = 3,
	/obj/item/toy/diploma = 3,
	/obj/item/toy/gooncode = 3,
	/obj/item/toy/cellphone = 3,
	/obj/item/toy/handheld/robustris = 3,
	/obj/item/toy/handheld/arcade = 3,
	/obj/item/toy/ornate_baton = 3,
	)

