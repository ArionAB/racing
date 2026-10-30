extends Node
## WORLD CUP: datele cupelor, adversarii trasi fara repetare, punctajul
## cumulat si o cursa reala pornita in modul cupa.
##
## Contractele (decizia dezvoltatorului, 30 oct 2026):
##   1. trei cupe, pistele fiecareia se rezolva; nicio pista in doua cupe; pe
##      dinafara Dunele (Track01), Okinawa manual (Track08), Ha Long (Track22)
##      si Carrara (Track23); restul pistelor sunt toate intr-o cupa;
##   2. la fiecare cupa noua, adversarii sunt trasi aleatoriu si NICIODATA nu
##      apare aceeasi masina de doua ori (nici a jucatorului) — verificat pe
##      fiecare masina a jucatorului x 300 de extrageri, iar garda e armata:
##      lineup-ul vechi (doua autobuze) si unul cu masina jucatorului pica;
##   3. barem 6-5-4-3-2-1, cumulat pe toate cursele cupei;
##   4. Race.tscn real, in cupa: grila foloseste masinile trase (6 masini
##      diferite), titlul rezultatelor numeste cupa, clasamentul final
##      departajeaza egalitatile dupa ultima cursa.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWorldCup.tscn
##   ... -- --no-race   # fara pasul 4 (doar date si aritmetica)

const EXCLUDED: Array[String] = ["Track01", "Track08", "Track22", "Track23"]
## Pista pe care ruleaza pasul 4: cea mai usoara de incarcat. Nu e in nicio
## cupa, dar cursa nu citeste pista din cupa — `track_scene_override` bate.
const RACE_BENCH := "res://scenes/tracks/Track01.tscn"

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== World Cup ===")
	_check_cups()
	_check_lineups()
	_check_points()
	if "--no-race" in OS.get_cmdline_user_args():
		_finish()
		return
	await _check_race()
	_finish()


# ------------------------------------------------------------------ 1. date

func _check_cups() -> void:
	print("-- cupele")
	_check(GameState.WORLD_CUPS.size() == 3, "trei cupe (%d)" % GameState.WORLD_CUPS.size())
	var seen: Dictionary = {}
	for res in GameState.WORLD_CUPS:
		var cup := res as WorldCup
		var names: Array[String] = []
		for i in cup.tracks.size():
			var index := cup.track_index(i)
			_check(index >= 0, "%s: pista '%s' exista" % [cup.display_name, cup.tracks[i]])
			if index < 0:
				continue
			var key := TrackInfo.scene_key(index)
			names.append(key)
			_check(not EXCLUDED.has(key), "%s: %s nu e exclusa" % [cup.display_name, key])
			_check(not seen.has(key), "%s: %s nu e deja in %s"
				% [cup.display_name, key, seen.get(key, "-")])
			seen[key] = cup.display_name
		print("    %s: %s" % [cup.display_name, ", ".join(names)])
		_check(cup.tracks.size() == 4, "%s are 4 curse" % cup.display_name)
	for i in GameState.TRACK_SCENES.size():
		var key := TrackInfo.scene_key(i)
		if not EXCLUDED.has(key):
			_check(seen.has(key), "%s (%s) e intr-o cupa" % [key, GameState.TRACK_NAMES[i]])


# --------------------------------------------------------------- 2. masini

## "" daca lineup-ul respecta contractul, altfel motivul.
static func lineup_problem(lineup: Array[int], player_car: int, count: int) -> String:
	if lineup.size() != count:
		return "are %d masini, nu %d" % [lineup.size(), count]
	var seen: Dictionary = {}
	for car in lineup:
		if car < 0 or car >= GameState.CAR_DATA.size():
			return "index %d in afara garajului" % car
		if car == player_car:
			return "contine masina jucatorului (%d)" % car
		if seen.has(car):
			return "masina %d de doua ori" % car
		seen[car] = true
	return ""


func _check_lineups() -> void:
	print("-- adversarii")
	var count := GameState.ai_count
	# Garda e armata: lineup-ul vechi al cursei rapide repeta autobuzul.
	_check(lineup_problem(Race.AI_CARS, 0, count) != "",
		"sabotaj: Race.AI_CARS (doua autobuze) pica: %s"
			% lineup_problem(Race.AI_CARS, 0, count))
	var with_player: Array[int] = [0, 1, 2, 4, 5]
	_check(lineup_problem(with_player, 0, count) != "",
		"sabotaj: lineup cu masina jucatorului pica")

	var rng := RandomNumberGenerator.new()
	var bad := ""
	var distinct: Dictionary = {}
	var used_by_player0: Dictionary = {}
	for player_car in GameState.CAR_DATA.size():
		for draw in 300:
			rng.seed = player_car * 1000 + draw
			var lineup := GameState.draw_ai_lineup(player_car, count, rng)
			var problem := lineup_problem(lineup, player_car, count)
			if problem != "" and bad == "":
				bad = "jucator %d, extragerea %d: %s" % [player_car, draw, problem]
			distinct[str(lineup)] = true
			if player_car == 0:
				for car in lineup:
					used_by_player0[car] = true
	_check(bad == "", "%d x 300 extrageri fara repetare si fara masina jucatorului%s"
		% [GameState.CAR_DATA.size(), "" if bad == "" else " — " + bad])
	_check(distinct.size() > 100, "extragerile variaza (%d lineup-uri distincte)" % distinct.size())
	_check(used_by_player0.size() == GameState.CAR_DATA.size() - 1,
		"fiecare masina din garaj ajunge adversar (%d din %d)"
			% [used_by_player0.size(), GameState.CAR_DATA.size() - 1])


# --------------------------------------------------------------- 3. puncte

func _check_points() -> void:
	print("-- punctele")
	_check(GameState.CHAMP_POINTS == [6, 5, 4, 3, 2, 1],
		"barem 6-5-4-3-2-1 (%s)" % str(GameState.CHAMP_POINTS))
	var cup := GameState.WORLD_CUPS[0] as WorldCup
	GameState.champ_cup = cup
	GameState.champ_active = true
	GameState.champ_round = 0
	GameState.champ_points.clear()
	GameState.champ_points.resize(GameState.ai_count + 1)
	var slots := GameState.ai_count + 1
	_check(GameState.champ_rounds() == cup.tracks.size(),
		"cupa are %d curse" % GameState.champ_rounds())
	# Jucatorul castiga mereu; restul se rotesc, ca o eroare de indexare pe
	# pozitiile de jos sa nu treaca neobservata.
	for race in GameState.champ_rounds():
		var order: Array = [0]
		for i in slots - 1:
			order.append(1 + (i + race) % (slots - 1))
		GameState.record_results(order)
	var total := 0
	for p in GameState.champ_points:
		total += int(p)
	_check(total == 21 * GameState.champ_rounds(),
		"total acordat %d = 21 x %d curse" % [total, GameState.champ_rounds()])
	_check(GameState.champ_points[0] == 6 * GameState.champ_rounds(),
		"castigatorul tuturor curselor are %d" % GameState.champ_points[0])
	GameState.champ_round = GameState.champ_rounds() - 1
	_check(GameState.champ_is_last_round(), "ultima cursa e recunoscuta")
	GameState.champ_round = 0
	_check(not GameState.champ_is_last_round(), "prima cursa nu e ultima")


# ---------------------------------------------------------------- 4. cursa

func _check_race() -> void:
	print("-- cursa in cupa")
	var cup := GameState.WORLD_CUPS[1] as WorldCup
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	GameState.total_laps = 1
	GameState.champ_active = true
	GameState.champ_cup = cup
	GameState.champ_round = 0
	GameState.champ_points.clear()
	GameState.champ_points.resize(GameState.ai_count + 1)
	GameState.champ_ai_cars = GameState.draw_ai_lineup(GameState.selected_car,
		GameState.ai_count, rng)
	GameState.selected_track = cup.track_index(0)
	GameState.track_scene_override = RACE_BENCH
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate() as Race
	add_child(race)
	var guard := 0
	while race.cars.size() < GameState.ai_count + 1 and guard < 3000:
		await get_tree().process_frame
		guard += 1
	_check(race.cars.size() == GameState.ai_count + 1,
		"grila are %d masini (dupa %d cadre)" % [race.cars.size(), guard])
	if race.cars.size() < GameState.ai_count + 1:
		return
	var names: Array[String] = []
	for car in race.cars:
		names.append(car.car_name)
	print("    grila: ", ", ".join(names))
	var unique: Dictionary = {}
	for n in names:
		unique[n] = true
	_check(unique.size() == names.size(), "sase masini diferite pe grila")
	var expected: Array[String] = []
	for idx in GameState.champ_ai_cars:
		expected.append((GameState.CAR_DATA[idx] as CarData).display_name)
	_check(names.slice(1) == expected, "adversarii sunt cei trasi pentru cupa")

	# Rezultatele: titlul numeste cupa.
	race.call("_finish_race")
	race.call("_show_results")
	var title := _results_title(race)
	_check(title.begins_with(cup.display_name), "titlul rezultatelor: \"%s\"" % title)

	# Clasamentul final: doua sloturi la egalitate — castiga cel care a
	# terminat mai sus ultima cursa.
	var last: Array = race.get("_final_order")
	var hi: int = last[1]
	var lo: int = last[2]
	for i in GameState.champ_points.size():
		GameState.champ_points[i] = 0
	GameState.champ_points[lo] = 30
	GameState.champ_points[hi] = 30
	race.call("_show_champion")
	var rows := _results_rows(race)
	var first := rows[0] if rows.size() > 0 else ""
	_check(first.contains(race.cars[hi].pilot_name),
		"egalitate la 30: %s (locul 2 in ultima cursa) e inaintea lui %s — \"%s\""
			% [race.cars[hi].pilot_name, race.cars[lo].pilot_name, first])
	_check(_results_title(race).begins_with(cup.display_name + " WINNER"),
		"titlul final: \"%s\"" % _results_title(race))
	GameState.track_scene_override = ""


func _results_title(race: Race) -> String:
	var box: VBoxContainer = race.hud.get("_results_box")
	return (box.get_child(0) as Label).text if box.get_child_count() > 0 else ""


## Numele de pe randurile clasamentului (al doilea Label din fiecare rand).
func _results_rows(race: Race) -> Array[String]:
	var out: Array[String] = []
	var box: VBoxContainer = race.hud.get("_results_box")
	for child in box.get_children():
		if child is HBoxContainer and child.get_child_count() >= 2 \
				and child.get_child(1) is Label:
			out.append((child.get_child(1) as Label).text)
	return out


func _finish() -> void:
	GameState.champ_active = false
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)
