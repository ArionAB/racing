extends Node
## Nivelurile AI (issue #682), partea IEFTINA, din verify_local.sh: tot ce nu
## cere o cursa intreaga. Ecartul pe tur il masoara `tools/ai_skill_gap.sh`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAiSkillWiring.tscn
##   ... -- --sabotaj=implicit   (profilul implicit mutat: trebuie sa pice A)
##   ... -- --sabotaj=selector   (butoanele scoase din ecran: trebuie sa pice D)
##
##   A. PROFILUL IMPLICIT = AI-UL DE DINAINTE, camp cu camp. Valorile de mai jos
##      sunt fostele constante din `AIController` (main d5be197d). Pe ele sunt
##      masurate liniile de baza ale ProbeRace, car_balance.sh si carierei;
##      daca se schimba, acelea trebuie refacute, nu doar cifra de aici.
##   B. FIRUL: `GameState.race_ai_level` ajunge prin `Race._spawn_cars` la
##      FIECARE adversar; -1 si cariera dau profilul implicit; rocket start-ul
##      citeste nivelul pilotului.
##   C. NIVELURILE sunt ordonate pe fiecare buton de condus (Bronz cel mai
##      prudent, Aur cel mai aproape de referinta) si niciunul nu trece de
##      referinta — „toate butoanele la maximum" e chiar referinta.
##   D. SELECTORUL din QUICK RACE si WORLD CUP: butoanele intregi in ecran, de
##      cel putin 56 px, nesuprapuse peste antet, la 1280x720, la un telefon
##      lat (2532x1170 -> 1558x720 cu stretch „expand") si la 4:3; un tap pe
##      buton schimba `GameState.ai_level` (fara sa scrie setarile reale).

const IMPLICIT_EXPECTED := {
	"corner_speed_floor": 0.44, "corner_soft": 0.25, "straight_speed": 1.0, "inside_bias": 0.55,
	"drift_severity": 0.34, "turbo_min_charge": 0.6, "turbo_corner_cut": 0.25,
	"rocket_start_chance": 0.45, "shortcut_chance": 0.4, "overtake_reach": 1.0,
	"mistake_chance": 0.0,
}
## Sensul in care un camp face pilotul MAI BUN (+1 = mai mare e mai rapid).
const FASTER_SIGN := {
	"corner_speed_floor": 1.0, "corner_soft": 1.0, "straight_speed": 1.0, "inside_bias": 1.0,
	"drift_severity": -1.0, "turbo_min_charge": -1.0, "turbo_corner_cut": -1.0,
	"rocket_start_chance": 1.0, "overtake_reach": 1.0, "mistake_chance": -1.0,
}
const RACE_SCENE: String = "res://scenes/race/Race.tscn"
## Pista usoara pentru fir: Dunele (index 0) se construieste repede.
const WIRING_TRACK: int = 0
const SIZES: Array[Vector2] = [Vector2(1280, 720), Vector2(1558, 720), Vector2(1280, 960)]
const MIN_BUTTON_H: float = 56.0

var _sabotage: String = ""
var _fail: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
	AiSkillSelector.persist = false
	# Un cadru de fizica inainte de orice (vezi ProbeTouchZones: `quit()` prea
	# devreme nu opreste bucla sub verify_local.sh).
	await get_tree().process_frame
	await get_tree().physics_frame
	_check_implicit()
	_check_levels()
	await _check_wiring()
	await _check_selector()
	print("")
	if _fail == 0:
		print("VERDICT: OK — profil implicit, fir, ordinea nivelurilor, selector")
	else:
		print("VERDICT: PROBLEMA — %d verificari picate" % _fail)
	get_tree().quit(0 if _fail == 0 else 1)


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fail += 1
	print("  %s %s" % ["ok  " if cond else "PICA", what])


func _check_implicit() -> void:
	print("A. profilul implicit = AI-ul de dinainte de niveluri")
	var s := AiSkill.implicit()
	if _sabotage == "implicit":
		s = AiSkill.new()
		s.corner_speed_floor = 0.47
	for k: String in IMPLICIT_EXPECTED:
		var got := float(s.get(k))
		_ok(got == float(IMPLICIT_EXPECTED[k]), "%s = %s (astept %s)" % [
			k, str(got), str(IMPLICIT_EXPECTED[k])])
	# Campurile resursei sunt EXACT cele de aici: un camp nou cere decizie
	# (si o linie in IMPLICIT_EXPECTED), nu se strecoara.
	var fields: Array[String] = []
	for p in s.get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			fields.append(String(p.name))
	fields.sort()
	var want: Array[String] = []
	for k: String in IMPLICIT_EXPECTED:
		want.append(k)
	want.sort()
	_ok(fields == want, "campurile AiSkill: %s" % ", ".join(PackedStringArray(fields)))


func _check_levels() -> void:
	print("C. nivelurile, ordonate pe fiecare buton, sub referinta")
	var levels: Array[AiSkill] = []
	for i in AiSkill.LEVEL_PATHS.size():
		levels.append(AiSkill.for_level(i))
	levels.append(load(AiSkill.REFERENCE_PATH) as AiSkill)
	var names := AiSkill.LEVEL_NAMES.duplicate()
	names.append("REFERINTA")
	for k: String in FASTER_SIGN:
		var sign := float(FASTER_SIGN[k])
		var ordered := true
		var vals: Array[String] = []
		for i in levels.size():
			vals.append("%s" % str(levels[i].get(k)))
			if i > 0 and sign * (float(levels[i].get(k)) - float(levels[i - 1].get(k))) < 0.0:
				ordered = false
		_ok(ordered, "%-20s %s" % [k, " <= ".join(PackedStringArray(vals))])


func _check_wiring() -> void:
	print("B. firul GameState -> Race -> fiecare AIController")
	GameState.selected_car = 0
	GameState.selected_track = WIRING_TRACK
	GameState.champ_active = false
	var cases := [
		[2, false, AiSkill.LEVEL_PATHS[2], "GOLD"],
		[0, false, AiSkill.LEVEL_PATHS[0], "BRONZE"],
		[-1, false, "", "fara nivel (sonde, cursa veche)"],
		[2, true, "", "cariera cu GOLD ales -> implicit"],
	]
	for c in cases:
		GameState.race_ai_level = int(c[0])
		Career.active = bool(c[1])
		var race: Node = (load(RACE_SCENE) as PackedScene).instantiate()
		add_child(race)
		await get_tree().physics_frame
		var good := 0
		var rocket_ok := true
		var n := 0
		for car: Car in race.cars:
			if car == race.player:
				continue
			n += 1
			var ai := car.controller as AIController
			var want_path: String = c[2]
			var is_ok: bool = (ai.skill == AiSkill.implicit()) if want_path.is_empty() \
				else (ai.skill.resource_path == want_path)
			if is_ok:
				good += 1
			if AIController.rocket_chance_of(car) != ai.skill.rocket_start_chance:
				rocket_ok = false
		_ok(good == n and n > 0, "%s: %d/%d adversari pe profilul asteptat" % [c[3], good, n])
		_ok(rocket_ok, "%s: rocket start-ul citeste nivelul pilotului" % c[3])
		race.queue_free()
		await get_tree().physics_frame
	Career.active = false
	GameState.race_ai_level = -1


func _check_selector() -> void:
	print("D. selectorul in QUICK RACE si WORLD CUP")
	for size in SIZES:
		for kind in ["QUICK RACE", "WORLD CUP"]:
			var host := Control.new()
			host.size = size
			add_child(host)
			var panel: Control = TrackSelectPanel.new() if kind == "QUICK RACE" \
				else WorldCupPanel.new()
			host.add_child(panel)
			await get_tree().process_frame
			await get_tree().process_frame
			var sel := _find_selector(panel)
			if sel == null:
				_ok(false, "%s %s: selectorul lipseste" % [kind, str(size)])
				host.queue_free()
				continue
			if _sabotage == "selector":
				sel.position.x += size.x
			var screen := Rect2(Vector2.ZERO, size)
			var back := _find_back(panel)
			var inside := true
			var tall := true
			var clear := true
			for b in sel.buttons:
				var r := b.get_global_rect()
				inside = inside and screen.encloses(r)
				tall = tall and r.size.y >= MIN_BUTTON_H
				if back != null:
					clear = clear and not r.intersects(back.get_global_rect())
			_ok(inside and tall and clear, "%-10s %4dx%-4d butoane in ecran=%s, >=56px=%s, fara antet=%s"
				% [kind, int(size.x), int(size.y), inside, tall, clear])
			# Tap pe fiecare nivel: schimba alegerea, un singur buton apasat.
			var taps_ok := true
			for i in sel.buttons.size():
				sel.buttons[i].pressed.emit()
				var pressed := 0
				for b in sel.buttons:
					if b.button_pressed:
						pressed += 1
				taps_ok = taps_ok and GameState.ai_level == i and pressed == 1 \
					and sel.buttons[i].button_pressed
			_ok(taps_ok, "%-10s tap pe BRONZE/SILVER/GOLD -> GameState.ai_level" % kind)
			host.queue_free()
			await get_tree().process_frame
	GameState.ai_level = AiSkill.DEFAULT_LEVEL


func _find_selector(root: Node) -> AiSkillSelector:
	if root is AiSkillSelector:
		return root as AiSkillSelector
	for child in root.get_children():
		var found := _find_selector(child)
		if found != null:
			return found
	return null


func _find_back(root: Node) -> Button:
	if root is Button and (root as Button).text.contains("BACK"):
		return root as Button
	for child in root.get_children():
		var found := _find_back(child)
		if found != null:
			return found
	return null
