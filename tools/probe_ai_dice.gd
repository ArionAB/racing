extends Node
## ZARUL DE NIVEL al AI-ului: sansa de a citi un hazard si sansa de a lua
## scurtatura, pe un zar cu 6 fete, dupa nivel (BRONZE / SILVER / GOLD).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAiDice.tscn
##   ... -- --sabotaj=sigur    (un nivel cu 6 fete din 6: trebuie sa pice C)
##   ... -- --sabotaj=ordine   (Bronz primeste zarurile Aurului: trebuie sa pice B)
##   ... -- --sabotaj=cadru    (zar dat in fiecare cadru, nu per trecere: pica D)
##   ... -- --sabotaj=surd     (cititorii nu mai intreaba zarul: pica F)
##   ... -- --no-race          (fara cursa reala din F, pentru iterare rapida)
##
## CONTRACTE:
##   A. FARA ZAR = AI-ul de dinainte: profilul implicit citeste mereu, nu da cu
##      zarul, nu-si face rng si nu-si schimba decizia de scurtatura.
##   B. NIVELURILE: zarurile fiecarui nivel sunt intre 1 si 5 fete (niciodata 0
##      = fara zar, niciodata 6 = sigur) si cresc strict Bronz < Argint < Aur,
##      si la hazard, si la scurtatura.
##   C. MEREU UN PARIU, cu sansa nivelului: pe mii de treceri, fiecare nivel
##      citeste hazardul in fete/6 din cazuri (±3 puncte) — deci si rateaza, si
##      nimereste; la fel scurtatura.
##   D. O DATA PER TRECERE: cat hazardul e in raza (intrebat cadru de cadru),
##      verdictul nu se schimba si zarul s-a dat o singura data; dupa o pauza
##      (turul urmator) se da din nou; doua hazarde au zaruri separate.
##   E. PACALIT O DATA: dupa o repunere, hazardele trecerii in curs sunt citite.
##   F. IN CURSA REALA (Kyoto: hazarde pe ceas + furca): la nivel, fiecare AI da
##      cu zarul de hazard si de scurtatura, exista si treceri pe nevazute, si
##      zarul de scurtatura se da din nou la fiecare tur; pe profilul implicit,
##      niciun zar.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const RACE_TRACK: String = "kyoto"
## Secunde de cursa simulate in F: destul cat fiecare AI sa treaca de doua ori
## pe la furca (un tur pe Kyoto ~75 s).
const RACE_SIM_S: float = 240.0
const PASSES: int = 6000
const TOL: float = 0.03

var _sabotage: String = ""
var _no_race: bool = false
var _fail: int = 0


## Un hazard de jucarie: zarul are nevoie doar de un instance id.
class FakeHazard extends RefCounted:
	pass


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
		elif arg == "--no-race":
			_no_race = true
	await get_tree().process_frame
	await get_tree().physics_frame
	_check_implicit()
	_check_levels()
	_check_odds()
	_check_pass()
	_check_respawn()
	if not _no_race:
		await _check_race()
	print("")
	if _fail == 0:
		print("VERDICT: OK — zarul de nivel: fara zar pe implicit, ordine, sansa, o data per trecere, %s"
			% ("FARA cursa reala (--no-race)" if _no_race else "cursa reala"))
	else:
		print("VERDICT: PROBLEMA — %d verificari picate" % _fail)
	get_tree().quit(0 if _fail == 0 else 1)


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fail += 1
	print("  %s %s" % ["ok  " if cond else "PICA", what])


func _level(i: int) -> AiSkill:
	var s := AiSkill.for_level(i)
	if _sabotage == "ordine" and i == 0:
		s = s.duplicate() as AiSkill
		s.hazard_dice = AiSkill.for_level(2).hazard_dice
		s.shortcut_dice = AiSkill.for_level(2).shortcut_dice
	elif _sabotage == "sigur" and i == 2:
		s = s.duplicate() as AiSkill
		s.hazard_dice = 6
		s.shortcut_dice = 6
	return s


## Un pilot fara masina si fara pista: zarul nu are nevoie de ele.
func _pilot(skill: AiSkill, seed_tag: float) -> AIController:
	var ai := AIController.new()
	ai.skill = skill
	ai.line_offset = seed_tag
	return ai


## O trecere pe langa `hz`: intrebat `frames` cadre la rand. Intoarce verdictul
## primului cadru si, in `flips`, de cate ori s-a schimbat pe parcurs.
func _pass(ai: AIController, hz: Object, frames: int, flips: Array) -> bool:
	var first := ai._reads_hazard(hz)
	var n := 0
	for _k in frames - 1:
		ai._dice_now += 1.0 / 60.0
		if _sabotage == "cadru":
			ai._haz_reads.clear()
		if ai._reads_hazard(hz) != first:
			n += 1
	flips.append(n)
	return first


func _check_implicit() -> void:
	print("A. fara zar = AI-ul de dinainte de niveluri")
	var s := AiSkill.implicit()
	_ok(s.hazard_dice == 0 and s.shortcut_dice == 0, "profilul implicit n-are zar (0 / 0)")
	var ai := _pilot(s, 0.1)
	var hz := FakeHazard.new()
	var all_read := true
	for _k in 2000:
		ai._dice_now += 5.0
		all_read = all_read and ai._reads_hazard(hz)
	_ok(all_read, "citeste hazardul la fiecare din 2000 de treceri")
	_ok(ai.hazard_rolls.is_empty() and ai._dice_rng == null and ai._haz_reads.is_empty(),
		"niciun zar dat, niciun rng, nicio stare")
	ai.free()


func _check_levels() -> void:
	print("B. nivelurile: 1-5 fete, strict crescator Bronz < Argint < Aur")
	for field: String in ["hazard_dice", "shortcut_dice"]:
		var vals: Array[int] = []
		var in_range := true
		var rising := true
		for i in AiSkill.LEVEL_PATHS.size():
			var v := int(_level(i).get(field))
			vals.append(v)
			in_range = in_range and v >= 1 and v <= 5
			if i > 0 and v <= vals[i - 1]:
				rising = false
		_ok(in_range and rising, "%-14s %s (din 6)" % [field,
			" < ".join(PackedStringArray(vals.map(func(x: int) -> String: return str(x))))])


func _check_odds() -> void:
	print("C. mereu un pariu, cu sansa nivelului (%d treceri)" % PASSES)
	for i in AiSkill.LEVEL_PATHS.size():
		var skill := _level(i)
		var ai := _pilot(skill, 0.07 * float(i + 1))
		var hz := FakeHazard.new()
		var reads := 0
		var takes := 0
		for _k in PASSES:
			ai._dice_now += 10.0
			if ai._reads_hazard(hz):
				reads += 1
			ai._roll_shortcut()
			if ai.prefers_shortcut:
				takes += 1
		var p_read := float(reads) / float(PASSES)
		var p_take := float(takes) / float(PASSES)
		var want_read := float(skill.hazard_dice) / 6.0
		var want_take := float(skill.shortcut_dice) / 6.0
		_ok(absf(p_read - want_read) <= TOL and reads > 0 and reads < PASSES,
			"%-7s citeste hazardul %4.1f%% (zar %d/6 = %4.1f%%), rateaza %d" % [
				AiSkill.LEVEL_NAMES[i], p_read * 100.0, skill.hazard_dice,
				want_read * 100.0, PASSES - reads])
		_ok(absf(p_take - want_take) <= TOL and takes > 0 and takes < PASSES,
			"%-7s ia scurtatura  %4.1f%% (zar %d/6 = %4.1f%%)" % [
				AiSkill.LEVEL_NAMES[i], p_take * 100.0, skill.shortcut_dice,
				want_take * 100.0])
		ai.free()


func _check_pass() -> void:
	print("D. o data per trecere")
	var ai := _pilot(_level(0), 0.2)
	var hz := FakeHazard.new()
	var other := FakeHazard.new()
	var flips: Array = []
	var verdicts: Array[bool] = []
	var passes := 300
	for _k in passes:
		ai._dice_now += 20.0 # turul urmator
		verdicts.append(_pass(ai, hz, 180, flips))
	var flipped := 0
	for n: int in flips:
		flipped += n
	_ok(flipped == 0, "verdictul nu se schimba in timpul trecerii (%d schimbari pe %d treceri x 180 cadre)"
		% [flipped, passes])
	_ok(ai.hazard_rolls.size() == passes, "un singur zar pe trecere (%d zaruri la %d treceri)"
		% [ai.hazard_rolls.size(), passes])
	var seen_true := verdicts.has(true)
	var seen_false := verdicts.has(false)
	_ok(seen_true and seen_false, "de la o trecere la alta zarul iese si „citeste”, si „pe nevazute”")
	# Doua hazarde in raza in acelasi timp: zaruri separate.
	var differ := 0
	for _k in 200:
		ai._dice_now += 20.0
		if ai._reads_hazard(hz) != ai._reads_hazard(other):
			differ += 1
	_ok(differ > 0, "doua hazarde alaturate au zaruri separate (%d din 200 de treceri difera)" % differ)
	ai.free()


func _check_respawn() -> void:
	print("E. pacalit o data, a doua oara se uita")
	var ai := _pilot(_level(0), 0.3)
	var hz := FakeHazard.new()
	var tried := 0
	while ai._reads_hazard(hz) and tried < 200:
		ai._dice_now += 20.0
		tried += 1
	var was_blind := not ai._reads_hazard(hz)
	# Aruncarea si tranzitia de repunere tin mai mult decat pauza unei treceri:
	# tot citit trebuie sa fie, nu zar nou. Repetat, ca un zar norocos sa nu
	# treaca drept regula.
	var always_read := was_blind
	for _k in 60:
		while ai._reads_hazard(hz):
			ai._dice_now += 20.0
		ai._dice_now += AIController.DICE_PASS_GAP_S + 2.0
		ai._on_dice_respawn(null)
		ai._dice_now += 0.5
		always_read = always_read and ai._reads_hazard(hz)
		ai._dice_now += 20.0
	_ok(always_read, "dupa repunere (si una lunga), hazardul trecerii in curs e citit — 60 din 60")
	var blind_again := false
	for _k in 200:
		ai._dice_now += 20.0
		if not ai._reads_hazard(hz):
			blind_again = true
			break
	_ok(blind_again, "la trecerile urmatoare zarul se da din nou (iar poate pierde)")
	ai.free()


func _check_race() -> void:
	print("F. in cursa reala (%s, %d s simulate pe nivel)" % [RACE_TRACK, int(RACE_SIM_S)])
	var track_index := GameState.resolve_track_arg(RACE_TRACK)
	if track_index < 0:
		_ok(false, "pista %s nu exista in lista" % RACE_TRACK)
		return
	for level: int in [0, -1]:
		var label: String = AiSkill.LEVEL_NAMES[level] if level >= 0 else "implicit"
		GameState.selected_car = 0
		GameState.selected_track = track_index
		GameState.champ_active = false
		GameState.total_laps = 99
		GameState.records[GameState.TRACK_NAMES[track_index]] = 1
		GameState.race_ai_level = level
		var race: Node = (load(RACE_SCENE) as PackedScene).instantiate()
		add_child(race)
		(race._rng as RandomNumberGenerator).seed = 7
		GameState.race_ai_level = -1
		var ais: Array[AIController] = []
		for car: Car in race.cars:
			if car == race.player:
				continue
			var ai := car.controller as AIController
			if _sabotage == "surd":
				ai.skill = AiSkill.implicit()
			ais.append(ai)
		var t := 0.0
		while t < RACE_SIM_S:
			await get_tree().physics_frame
			if race.state == Race.State.RUNNING:
				t += 1.0 / 60.0
		var hz_min := 1 << 30
		var sc_min := 1 << 30
		var hz_total := 0
		var hz_blind := 0
		var sc_total := 0
		for ai in ais:
			hz_min = mini(hz_min, ai.hazard_rolls.size())
			sc_min = mini(sc_min, ai.shortcut_rolls.size())
			hz_total += ai.hazard_rolls.size()
			sc_total += ai.shortcut_rolls.size()
			for r in ai.hazard_rolls:
				if r > ai.skill.hazard_dice:
					hz_blind += 1
		print("  %s: %d AI, zaruri de hazard %d (pe nevazute %d, minim %d per AI), de scurtatura %d (minim %d per AI)"
			% [label, ais.size(), hz_total, hz_blind, hz_min, sc_total, sc_min])
		if level >= 0:
			_ok(hz_min >= 1, "%s: fiecare AI a dat cu zarul de hazard" % label)
			_ok(hz_blind >= 1 and hz_blind < hz_total,
				"%s: unele treceri pe nevazute, altele citite (%d din %d)" % [label, hz_blind, hz_total])
			_ok(sc_min >= 2, "%s: zarul de scurtatura se da la fiecare tur (minim %d per AI)" % [label, sc_min])
		else:
			_ok(hz_total == 0 and sc_total == 0, "implicit: niciun zar in cursa")
		race.queue_free()
		await get_tree().physics_frame
		await get_tree().physics_frame
