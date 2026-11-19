extends Node
## ProbeWorldCupSave — garda cupei WORLD CUP salvate (CONTINUE / RESET),
## 19 nov 2026, cererea dezvoltatorului: „un buton de continue si unul de
## reset". Persistenta e in `WorldCupSave` (`world_cup.cfg`), scrisa de
## `GameState.champ_save_progress` la inregistrarea rezultatelor.
##
## Rulare (ca SCENA, autoload-urile nu se rezolva cu --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWorldCupSave.tscn
##   ... -- --sabotaj=NUME   (fiecare trebuie sa PICE contractul lui)
##
## Contractele si sabotajele lor:
##   a. DUS-INTORS: dupa o cursa terminata in Race.tscn real, o citire PROASPATA
##      de pe disc da aceeasi cursa urmatoare (+1), puncte, adversari, masina,
##      nivel.
##        --sabotaj=runda    fisierul rescris cu cursa CURENTA, nu cu urmatoarea
##   b. ID-URI, NU INDICI: pe disc adversarii si masina sunt `CarData.id`, nivelul
##      e `aur`; un save scris de mana, in alta ordine decat garajul, se
##      rezolva exact pe masinile numite.
##        --sabotaj=indici   fisierul rescris cu indicii din CAR_DATA
##   c. NIMIC INAINTE DE PRIMA CURSA TERMINATA; iesirea in mijlocul cursei
##      (cursa reala eliberata nesosita, RESTART din pauza) lasa cursa aceeasi.
##        --sabotaj=devreme  cupa scrisa chiar la START
##        --sabotaj=mijloc   cupa scrisa (cu +1) la iesirea din mijlocul cursei
##   d. CONTINUE din panoul real reface starea exacta (cupa, cursa, puncte,
##      adversari, nivel, masina) peste o memorie „de aplicatie noua", iar
##      Race.tscn real pune pe grila masina salvata, adversarii salvati cu
##      nivelul salvat, pe pista cursei salvate (titlul rezultatelor).
##        --sabotaj=masina   masina jucatorului nerefacuta
##        --sabotaj=nivel    nivelul AI luat din selector, nu din save
##   e. ULTIMA CURSA inregistrata -> cupa stearsa (cealalta cupa ramane); PLAY
##      AGAIN porneste o cupa noua de la zero, fara nimic pe disc.
##        --sabotaj=final    cupa scrisa in loc de stearsa dupa ultima cursa
##   f. RESET pe panoul real: doua atingeri; una + fereastra expirata nu sterge
##      nimic; stergerea atinge DOAR cupa ei, cutia revine pe START fara
##      reconstruire.
##        --sabotaj=reset1   RESET gasit deja armat (o atingere sterge)
##        --sabotaj=toate    RESET sterge si cealalta cupa
##   g. SAVE-URI INVALIDE (cupa, masina, adversar, nivel necunoscut, marimi
##      gresite, alt ai_count, cursa in afara cupei, tipuri gresite, fisier
##      stricat) -> fara CONTINUE, fara crash; versiune viitoare -> nici citita,
##      nici suprascrisa (octet cu octet).
##        --sabotaj=validare mutatiile nu se mai aplica
##        --sabotaj=viitor   fisierul „viitor" scris cu versiunea curenta
##   h. PANOUL, pe noduri reale: START singur fara save; CONTINUE + RESET +
##      randul de stare exact cu save; RESET >= 48 px si mai ingust decat
##      CONTINUE; randul incape; reimprospatare la aratare; focus pe cupa jucata.
##        --sabotaj=panou    panoul citeste alt fisier la reaparitie
##   i. DUPA SOSIRE pauza nu se mai deschide: punctele sunt numarate si pe
##      disc, iar RESTART din pauza ar rejuca aceeasi cursa peste ele.
##        --sabotaj=pauza    zavorul pauzei scos dupa sosire
##
## Captura panoului (o cupa in desfasurare, restul neatinse), CU FEREASTRA:
##   godot --path . res://tools/ProbeWorldCupSave.tscn -- --captura=C:/.../wc.png
##
## Nu atinge salvarile reale: `WorldCupSave.path_override` si
## `GameState.settings_path` merg in `user://probe_tmp/world_cup_save_<pid>/`
## (ProbeTmp, #722), sters la final.

const ProbeTmp := preload("res://tools/probe_tmp.gd")
const RACE_SCENE := "res://scenes/race/Race.tscn"
## Scena usoara pe care ruleaza cursele (pista CUPEI ramane `selected_track`).
const RACE_BENCH := "res://scenes/tracks/Track01.tscn"
## Sub atatea verificari verdictul pica: o sectiune sarita = garda oarba.
const MIN_CHECKS := 96
const SABOTAGES: Array[String] = ["runda", "indici", "devreme", "mijloc", "masina",
	"nivel", "final", "reset1", "toate", "validare", "viitor", "panou", "pauza"]
## Adversarii pe grila in sonda (cursele sunt mai scurte); sloturi = 3.
const AI := 2
## Randul de stare asteptat, LITERAL (vezi `_check_panel`).
const STATUS_EXPECTED := "RACE 3 / 4  ·  2ND  ·  11 PTS  ·  AUTOBUZUL  ·  GOLD"

var _sabotage: String = ""
var _checks: int = 0
var _fails: Array[String] = []
var _failed_contracts: Dictionary = {}
var _tmp_dir: String = ""
var _starts: int = 0
var _real: Dictionary = {}
var _cup_a: WorldCup
var _cup_b: WorldCup


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
	if _sabotage != "" and not SABOTAGES.has(_sabotage):
		printerr("probe_world_cup_save: sabotaj necunoscut '%s' (stiu: %s)" % [
			_sabotage, ", ".join(SABOTAGES)])
		get_tree().quit(2)
		return
	if _sabotage != "":
		print("SABOTAJ: %s" % _sabotage)

	_real = {
		"settings_path": GameState.settings_path,
		"selected_car": GameState.selected_car,
		"selected_track": GameState.selected_track,
		"total_laps": GameState.total_laps,
		"ai_count": GameState.ai_count,
		"ai_level": GameState.ai_level,
		"race_ai_level": GameState.race_ai_level,
	}
	_tmp_dir = ProbeTmp.make("world_cup_save")
	WorldCupSave.path_override = _tmp_dir + WorldCupSave.FILE_NAME
	GameState.settings_path = _tmp_dir + "settings.cfg"
	GameState.race_starter = func() -> void: _starts += 1
	GameState.ai_count = AI
	GameState.total_laps = 1
	_cup_a = GameState.WORLD_CUPS[0] as WorldCup
	_cup_b = GameState.WORLD_CUPS[1] as WorldCup
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captura="):
			await _capture(arg.trim_prefix("--captura="))
			return

	print("== c/a/b. prima cursa: nimic inainte, dus-intors, id-uri")
	await _check_first_race()
	print("== d. CONTINUE prin panou si cursa reala")
	await _check_continue()
	print("== e. ultima cursa sterge cupa; PLAY AGAIN de la zero")
	await _check_last_race()
	print("== f. RESET in doi pasi")
	await _check_reset()
	print("== g. save-uri invalide si versiune viitoare")
	await _check_invalid()
	print("== h. panoul")
	await _check_panel()

	_restore()
	_report()


# ------------------------------------------------------------------ utilitare

func _check(contract: String, ok: bool, what: String) -> void:
	_checks += 1
	print("  %s [%s] %s" % ["OK  " if ok else "PICA", contract, what])
	if not ok:
		_fails.append("[%s] %s" % [contract, what])
		_failed_contracts[contract] = true


func _path() -> String:
	return WorldCupSave.path_override


func _wipe() -> void:
	if FileAccess.file_exists(_path()):
		DirAccess.remove_absolute(_path())


## Fisierul citit PROASPAT de pe disc (ConfigFile nou).
func _raw() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(_path())
	return cfg


func _section(cup: WorldCup) -> String:
	return WorldCupSave.SECTION_PREFIX + String(cup.id)


func _car(id: StringName) -> int:
	return SaveSchema.index_of(GameState.CAR_DATA, id)


func _ids(indices: Array[int]) -> Array:
	var out: Array = []
	for i in indices:
		out.append(String(SaveSchema.id_at(GameState.CAR_DATA, i)))
	return out


## Memoria unei aplicatii proaspat pornite: nicio cupa in curs.
func _forget() -> void:
	GameState.champ_active = false
	GameState.champ_cup = null
	GameState.champ_round = 0
	GameState.champ_points.clear()
	GameState.champ_points.resize(AI + 1)
	GameState.champ_ai_cars.clear()
	GameState.race_ai_level = -1


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Race.tscn real pe banc, cu ce e in GameState (cupa, cursa, masini).
func _start_race() -> Race:
	GameState.track_scene_override = RACE_BENCH
	var race := (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(race)
	await _frames(1)
	return race


func _end_race(race: Race) -> void:
	race.queue_free()
	await _frames(2)
	GameState.track_scene_override = ""


## Cursa reala jucata pana la sosire: rezultatele se inregistreaza (si cupa se
## scrie) prin `_finish_race`, exact drumul jocului.
func _run_finished_race() -> Race:
	var race := await _start_race()
	race.call("_go")
	await _physics(3)
	race.call("_finish_race")
	return race


func _results_title(race: Race) -> String:
	var box: VBoxContainer = race.hud.get("_results_box")
	return (box.get_child(0) as Label).text if box != null and box.get_child_count() > 0 else ""


func _sum(points: Array[int]) -> int:
	var total := 0
	for p in points:
		total += p
	return total


# ------------------------------------- c / a / b. prima cursa a unei cupe

func _check_first_race() -> void:
	_wipe()
	_forget()
	GameState.selected_car = _car(&"taxi")
	GameState.ai_level = 2
	_starts = 0
	GameState.start_championship(_cup_a)
	if _sabotage == "devreme":
		GameState.champ_save_progress()
	_check("c", _starts == 1 and GameState.champ_active and GameState.champ_cup == _cup_a
		and GameState.champ_round == 0, "premisa: START a pornit cupa %s, cursa 1" % _cup_a.id)
	_check("c", not FileAccess.file_exists(_path()) and WorldCupSave.load_entry(_cup_a) == null,
		"la START nu se scrie nimic")

	# Iesire in mijlocul primei curse (aplicatie omorata / MENU): nimic pe disc.
	var race := await _start_race()
	race.call("_go")
	await _physics(20)
	if _sabotage == "mijloc":
		GameState.champ_save_progress()
	await _end_race(race)
	_check("c", WorldCupSave.load_entry(_cup_a) == null,
		"prima cursa parasita nesosita: tot nimic pe disc")
	# RESTART din pauza = aceeasi cursa.
	GameState.start_race()
	_check("c", GameState.champ_round == 0 and WorldCupSave.load_entry(_cup_a) == null,
		"RESTART din pauza: tot cursa 1, nimic pe disc")

	# Prima cursa terminata.
	race = await _run_finished_race()
	var points := GameState.champ_points.duplicate()
	var rivals := GameState.champ_ai_cars.duplicate()
	if _sabotage == "runda":
		var cfg := _raw()
		cfg.set_value(_section(_cup_a), "next_race", GameState.champ_round)
		cfg.save(_path())
	_check("a", FileAccess.file_exists(_path()), "dupa prima cursa terminata fisierul exista")
	var entry := WorldCupSave.load_entry(_cup_a)
	_check("a", entry != null, "citirea proaspata gaseste cupa %s" % _cup_a.id)
	if entry != null:
		_check("a", entry.next_race == 1, "cursa urmatoare = 1 (%d)" % entry.next_race)
		_check("a", entry.points == points and _sum(points) == 6 + 5 + 4,
			"punctele %s = cele din memorie %s, total 15" % [entry.points, points])
		_check("a", entry.ai_cars == rivals, "adversarii %s = %s" % [entry.ai_cars, rivals])
		_check("a", entry.player_car == _car(&"taxi"), "masina = taxi (%d)" % entry.player_car)
		_check("a", entry.ai_level == 2, "nivelul = 2 / GOLD (%d)" % entry.ai_level)
		_check("a", entry.cup == _cup_a, "cupa = %s" % _cup_a.id)
	await _end_race(race)
	if _sabotage == "runda": # sabotajul pica doar contractul lui
		WorldCupSave.store(_cup_a, 1, points, rivals, _car(&"taxi"), 2)

	# b. Ce sta pe disc: id-uri, nu indici.
	var backup := FileAccess.get_file_as_bytes(_path())
	if _sabotage == "indici":
		var cfg := _raw()
		cfg.set_value(_section(_cup_a), "rivals", rivals.duplicate())
		cfg.set_value(_section(_cup_a), "car", _car(&"taxi"))
		cfg.save(_path())
	var raw := _raw()
	var section := _section(_cup_a)
	_check("b", int(raw.get_value("meta", "version", -1)) == WorldCupSave.VERSION,
		"[meta] version=%d" % WorldCupSave.VERSION)
	_check("b", typeof(raw.get_value(section, "car")) == TYPE_STRING
		and raw.get_value(section, "car") == "taxi",
		"masina pe disc = \"taxi\" (%s)" % var_to_str(raw.get_value(section, "car")))
	var raw_rivals: Variant = raw.get_value(section, "rivals")
	var all_strings := raw_rivals is Array
	if all_strings:
		for v: Variant in raw_rivals:
			all_strings = all_strings and typeof(v) == TYPE_STRING
	_check("b", all_strings and raw_rivals == _ids(rivals),
		"adversarii pe disc = id-uri %s (%s)" % [_ids(rivals), var_to_str(raw_rivals)])
	_check("b", raw.get_value(section, "ai_level") == "aur",
		"nivelul pe disc = \"aur\" (%s)" % var_to_str(raw.get_value(section, "ai_level")))
	var text := FileAccess.get_file_as_string(_path())
	_check("b", text.contains("[%s]" % section) and text.contains("car=\"taxi\""),
		"textul fisierului poarta sectiunea si id-ul masinii")
	print("    --- world_cup.cfg ---\n" + text.strip_edges().indent("    ") + "\n    ---")
	# Rezistent la reordonare: un save scris de mana, cu adversarii in alta
	# ordine decat garajul, se rezolva exact pe masinile numite.
	var hand := ConfigFile.new()
	hand.set_value("meta", "version", 1)
	hand.set_value(section, "next_race", 1)
	hand.set_value(section, "points", [6, 4, 5])
	hand.set_value(section, "rivals", ["tow_truck", "ambulance"])
	hand.set_value(section, "car", "monster")
	hand.set_value(section, "ai_level", "bronz")
	hand.save(_path())
	var by_hand := WorldCupSave.load_entry(_cup_a)
	var want: Array[int] = [_car(&"tow_truck"), _car(&"ambulance")]
	_check("b", by_hand != null and by_hand.ai_cars == want
		and by_hand.player_car == _car(&"monster") and by_hand.ai_level == 0,
		"save de mana (tow_truck, ambulance / monster / bronz) -> %s / %d / %d" % [
			by_hand.ai_cars if by_hand != null else [], by_hand.player_car if by_hand != null else -1,
			by_hand.ai_level if by_hand != null else -1])
	# Inapoi la fisierul real al cupei (si fara sabotajul `indici`).
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	f.store_buffer(backup)
	f.close()
	if _sabotage == "indici":
		WorldCupSave.store(_cup_a, 1, points, rivals, _car(&"taxi"), 2)


# --------------------------------------------- d. CONTINUE + cursa reala

func _check_continue() -> void:
	var saved := WorldCupSave.load_entry(_cup_a)
	_check("d", saved != null, "premisa: cupa %s salvata la cursa 2" % _cup_a.id)
	if saved == null:
		return
	# Aplicatie „noua": alta masina in garaj, alt nivel in selector, nicio cupa.
	_forget()
	GameState.selected_car = _car(&"monster")
	GameState.ai_level = 0
	GameState.selected_track = 0
	var panel := WorldCupPanel.new()
	add_child(panel)
	await _frames(2)
	var box: Dictionary = panel.get("_boxes")[_cup_a.id]
	var primary := box.primary as Button
	_check("d", primary.text == "CONTINUE", "cutia %s arata CONTINUE ('%s')" % [_cup_a.id, primary.text])
	_starts = 0
	primary.pressed.emit()
	if _sabotage == "masina":
		GameState.selected_car = _car(&"monster")
	if _sabotage == "nivel":
		GameState.race_ai_level = GameState.ai_level
	_check("d", _starts == 1, "CONTINUE a pornit o cursa (%d)" % _starts)
	_check("d", GameState.champ_active and GameState.champ_cup == _cup_a,
		"cupa activa = %s" % (GameState.champ_cup.id if GameState.champ_cup != null else &"-"))
	_check("d", GameState.champ_round == 1, "cursa = 2 (round %d)" % GameState.champ_round)
	_check("d", GameState.champ_points == saved.points,
		"punctele %s = %s" % [GameState.champ_points, saved.points])
	_check("d", GameState.champ_ai_cars == saved.ai_cars,
		"adversarii %s = %s" % [GameState.champ_ai_cars, saved.ai_cars])
	_check("d", GameState.selected_car == _car(&"taxi"),
		"masina jucatorului = taxi, cea a cupei (%d)" % GameState.selected_car)
	_check("d", GameState.race_ai_level == 2 and GameState.ai_level == 0,
		"nivelul cursei = GOLD din save (%d), selectorul ramane BRONZE (%d)" % [
			GameState.race_ai_level, GameState.ai_level])
	_check("d", GameState.selected_track == _cup_a.track_index(1),
		"pista = a doua din cupa (%d)" % GameState.selected_track)
	var settings := ConfigFile.new()
	settings.load(GameState.settings_path)
	_check("d", settings.get_value("game", "car", "") == "taxi",
		"setarile de pe disc tin aceeasi masina (taxi)")
	panel.queue_free()
	await _frames(1)

	# c (partea a doua): cursa 2 parasita la jumatate — cupa ramane la cursa 2.
	var race := await _start_race()
	race.call("_go")
	await _physics(20)
	if _sabotage == "mijloc":
		GameState.champ_save_progress()
	await _end_race(race)
	var after_exit := WorldCupSave.load_entry(_cup_a)
	_check("c", after_exit != null and after_exit.next_race == 1
		and after_exit.points == saved.points,
		"iesire din mijlocul cursei 2: save-ul arata tot cursa 2 (%d)" % (
			after_exit.next_race if after_exit != null else -1))

	# Cursa reala de dupa CONTINUE.
	race = await _start_race()
	_check("d", race.cars.size() == AI + 1, "grila are %d masini" % race.cars.size())
	if race.cars.size() == AI + 1:
		var player_data := GameState.CAR_DATA[_car(&"taxi")] as CarData
		_check("d", race.player.car_name == player_data.display_name,
			"jucatorul e in %s (%s)" % [player_data.display_name, race.player.car_name])
		var names: Array[String] = []
		var levels_ok := true
		for i in range(1, race.cars.size()):
			names.append(race.cars[i].car_name)
			var ai := race.cars[i].controller as AIController
			levels_ok = levels_ok and ai != null and ai.skill != null \
				and ai.skill.resource_path == AiSkill.LEVEL_PATHS[2]
		var expected: Array[String] = []
		for idx in saved.ai_cars:
			expected.append((GameState.CAR_DATA[idx] as CarData).display_name)
		_check("d", names == expected, "adversarii pe grila %s = cei salvati %s" % [names, expected])
		_check("d", levels_ok, "fiecare AI conduce cu nivelul GOLD (aur.tres)")
	race.call("_go")
	await _physics(3)
	race.call("_finish_race")
	# i. Dupa sosire pauza e inchisa: rezultatele sunt deja numarate si pe disc,
	# iar RESTART din pauza ar rejuca aceeasi cursa peste punctele ei.
	if _sabotage == "pauza":
		race.hud.set("_pause_locked", false)
	race.hud.call("_open_pause")
	var paused := get_tree().paused
	if paused:
		race.hud.call("_close_pause")
	_check("i", not paused, "dupa sosire pauza nu se mai deschide (RESTART ar numara cursa de doua ori)")
	race.call("_show_results")
	var info := TrackInfo.for_track(_cup_a.track_index(1))
	var title := _results_title(race)
	_check("d", title == "%s — RACE 2/%d — %s" % [_cup_a.display_name, _cup_a.tracks.size(),
		info.display_name], "titlul rezultatelor: '%s'" % title)
	var after := WorldCupSave.load_entry(_cup_a)
	_check("a", after != null and after.next_race == 2 and _sum(after.points) == 30,
		"dupa cursa 2: cursa urmatoare 3, 30 de puncte acordate (%s)" % [
			after.points if after != null else []])
	await _end_race(race)


# ------------------------------------------ e. ultima cursa, PLAY AGAIN

func _check_last_race() -> void:
	# Cealalta cupa are si ea un save: ultima cursa a lui A nu are voie sa-l atinga.
	var b_points: Array[int] = [5, 6, 4]
	var b_rivals: Array[int] = [_car(&"bus"), _car(&"buggy")]
	WorldCupSave.store(_cup_b, 1, b_points, b_rivals, _car(&"hotrod"), 1)
	_starts = 0
	GameState.champ_next_race() # cursa 3
	_check("e", _starts == 1 and GameState.champ_round == 2, "NEXT RACE -> cursa 3")
	var race := await _run_finished_race()
	var mid := WorldCupSave.load_entry(_cup_a)
	_check("e", mid != null and mid.next_race == 3, "dupa cursa 3: cursa urmatoare 4")
	await _end_race(race)
	GameState.champ_next_race() # cursa 4, ultima
	_check("e", GameState.champ_is_last_round(), "premisa: cursa 4 e ultima")
	race = await _run_finished_race()
	if _sabotage == "final":
		WorldCupSave.store(_cup_a, GameState.champ_round + 1, GameState.champ_points,
			GameState.champ_ai_cars, GameState.selected_car, GameState.race_ai_level)
	_check("e", WorldCupSave.load_entry(_cup_a) == null and not _raw().has_section(_section(_cup_a)),
		"dupa ultima cursa cupa %s nu mai e in fisier" % _cup_a.id)
	var b := WorldCupSave.load_entry(_cup_b)
	_check("e", b != null and b.points == b_points and b.ai_cars == b_rivals
		and b.player_car == _car(&"hotrod") and b.next_race == 1,
		"cupa %s ramane neatinsa" % _cup_b.id)
	# FINAL STANDINGS, apoi PLAY AGAIN: cupa noua, de la zero.
	race.call("_show_results")
	race.call("_on_results_primary")
	_check("e", bool(race.get("_champion_shown")), "FINAL STANDINGS afisat")
	_starts = 0
	race.call("_on_results_primary")
	_check("e", _starts == 1 and GameState.champ_active and GameState.champ_cup == _cup_a
		and GameState.champ_round == 0 and _sum(GameState.champ_points) == 0,
		"PLAY AGAIN: cupa %s de la cursa 1, 0 puncte" % _cup_a.id)
	var lineup := GameState.champ_ai_cars
	var unique := {}
	for c in lineup:
		unique[c] = true
	_check("e", lineup.size() == AI and unique.size() == AI
		and not lineup.has(GameState.selected_car), "PLAY AGAIN: adversari trasi din nou, valizi %s" % [lineup])
	_check("e", WorldCupSave.load_entry(_cup_a) == null, "PLAY AGAIN nu scrie nimic inainte de prima cursa")
	await _end_race(race)
	GameState.champ_active = false


# --------------------------------------------------------------- f. RESET

func _check_reset() -> void:
	_wipe()
	var a_points: Array[int] = [9, 7, 2]
	var a_rivals: Array[int] = [_car(&"police_sports"), _car(&"firetruck")]
	var b_points: Array[int] = [3, 8, 7]
	var b_rivals: Array[int] = [_car(&"muscle"), _car(&"ambulance")]
	WorldCupSave.store(_cup_a, 2, a_points, a_rivals, _car(&"taxi"), 1)
	WorldCupSave.store(_cup_b, 1, b_points, b_rivals, _car(&"buggy"), 0)
	var panel := WorldCupPanel.new()
	add_child(panel)
	await _frames(2)
	var boxes: Dictionary = panel.get("_boxes")
	var box_a: Dictionary = boxes[_cup_a.id]
	var box_b: Dictionary = boxes[_cup_b.id]
	var reset_a := box_a.reset as Button
	var primary_a := box_a.primary as Button
	_check("f", reset_a.visible and primary_a.text == "CONTINUE", "premisa: %s are CONTINUE + RESET" % _cup_a.id)

	# O atingere, apoi fereastra expira: nimic sters.
	if _sabotage == "reset1":
		(panel.get("_reset_armed") as Dictionary)[_cup_a.id] = 99
	reset_a.pressed.emit()
	_check("f", panel.is_reset_armed(_cup_a) and reset_a.text == "SURE?",
		"prima atingere: RESET armat, scrie SURE? ('%s')" % reset_a.text)
	_check("f", WorldCupSave.load_entry(_cup_a) != null, "prima atingere nu sterge nimic")
	_check("f", not panel.is_reset_armed(_cup_b), "armarea lui %s nu armeaza %s" % [_cup_a.id, _cup_b.id])
	await _frames(60)
	_check("f", panel.is_reset_armed(_cup_a), "dupa ~1 s RESET e tot armat")
	var t := 0
	while panel.is_reset_armed(_cup_a) and t < 600:
		await _frames(1)
		t += 1
	_check("f", not panel.is_reset_armed(_cup_a) and reset_a.text == "RESET",
		"fereastra expira (%d cadre in plus): RESET revine ('%s')" % [t, reset_a.text])
	_check("f", WorldCupSave.load_entry(_cup_a) != null and primary_a.text == "CONTINUE",
		"o atingere + asteptare: cupa %s intacta" % _cup_a.id)

	# Doua atingeri in fereastra: sterge DOAR cupa A.
	reset_a.pressed.emit()
	await _frames(10)
	reset_a.pressed.emit()
	if _sabotage == "toate":
		WorldCupSave.erase(_cup_b.id)
	_check("f", WorldCupSave.load_entry(_cup_a) == null and not _raw().has_section(_section(_cup_a)),
		"a doua atingere sterge cupa %s" % _cup_a.id)
	var b := WorldCupSave.load_entry(_cup_b)
	_check("f", b != null and b.points == b_points and b.ai_cars == b_rivals
		and b.player_car == _car(&"buggy") and b.ai_level == 0 and b.next_race == 1,
		"cupa %s ramane intacta" % _cup_b.id)
	_check("f", primary_a.text == "START" and not reset_a.visible
		and not (box_a.status as Label).visible,
		"cutia %s revine pe START, fara RESET si fara stare" % _cup_a.id)
	_check("f", is_instance_valid(primary_a) and primary_a.is_inside_tree()
		and panel.get("_boxes")[_cup_a.id].primary == primary_a and panel.is_inside_tree(),
		"aceleasi noduri: panoul nu s-a reconstruit")
	_check("f", (box_b.primary as Button).text == "CONTINUE" and (box_b.reset as Button).visible,
		"cutia %s are tot CONTINUE + RESET" % _cup_b.id)
	_check("f", not panel.is_reset_armed(_cup_a), "dupa stergere RESET nu ramane armat")
	panel.queue_free()
	await _frames(1)


# ------------------------------------------------------ g. save-uri invalide

## Sectiunea valida de baza a cupei A (ai_count = AI).
func _base() -> Dictionary:
	return {
		"next_race": 2,
		"points": [11, 13, 4],
		"rivals": ["monster", "hotrod"],
		"car": "taxi",
		"ai_level": "aur",
	}


func _write(section_name: String, values: Dictionary, version: int = 1) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", version)
	for key: String in values:
		cfg.set_value(section_name, key, values[key])
	cfg.save(_path())


func _check_invalid() -> void:
	var panel := WorldCupPanel.new()
	add_child(panel)
	await _frames(1)
	var primary := (panel.get("_boxes")[_cup_a.id] as Dictionary).primary as Button
	# Baza e valida (altfel cazurile de mai jos n-ar dovedi nimic).
	_write(_section(_cup_a), _base())
	panel.refresh()
	_check("g", WorldCupSave.load_entry(_cup_a) != null and primary.text == "CONTINUE",
		"premisa: sectiunea de baza e valida")

	var cases: Array = [
		["cupa necunoscuta", "cup:no_such_cup", {}],
		["masina necunoscuta", "", {"car": "no_such_car"}],
		["adversar necunoscut", "", {"rivals": ["monster", "no_such_car"]}],
		["adversar = index", "", {"rivals": ["monster", 3]}],
		["masina = index", "", {"car": 2}],
		["un adversar lipsa", "", {"rivals": ["monster"]}],
		["un adversar in plus", "", {"rivals": ["monster", "hotrod", "bus"]}],
		["un slot de puncte in plus", "", {"points": [11, 13, 4, 0]}],
		["un slot de puncte lipsa", "", {"points": [11, 13]}],
		["puncte negative", "", {"points": [11, -1, 4]}],
		["puncte text", "", {"points": "lots"}],
		["cursa 0 (nimic jucat)", "", {"next_race": 0}],
		["cursa = numarul de curse", "", {"next_race": 4}],
		["cursa negativa", "", {"next_race": -1}],
		["cursa text", "", {"next_race": "two"}],
		["nivel necunoscut", "", {"ai_level": "platinum"}],
		["nivel ca index", "", {"ai_level": 2}],
		["nivel lipsa", "", {"ai_level": null}],
	]
	for case: Array in cases:
		var what: String = case[0]
		var values := _base()
		var section_name := _section(_cup_a)
		if _sabotage != "validare":
			if String(case[1]) != "":
				section_name = case[1]
			var mutation: Dictionary = case[2]
			for key: String in mutation:
				if mutation[key] == null:
					values.erase(key)
				else:
					values[key] = mutation[key]
		_write(section_name, values)
		_expect_absent(panel, primary, what)

	# ai_count schimbat de la scriere: 3 sloturi pe disc, 6 in joc.
	_write(_section(_cup_a), _base())
	if _sabotage != "validare":
		GameState.ai_count = 5
	_expect_absent(panel, primary, "alt ai_count decat la scriere")
	GameState.ai_count = AI

	# Fisier care nu se parseaza: absent; un store il rescrie de la zero.
	var garbage := "[[[ nu e un config"
	if _sabotage == "validare":
		_write(_section(_cup_a), _base())
	else:
		var f := FileAccess.open(_path(), FileAccess.WRITE)
		f.store_string(garbage)
		f.close()
	_expect_absent(panel, primary, "fisier stricat")
	var p: Array[int] = [1, 2, 3]
	var r: Array[int] = [_car(&"bus"), _car(&"buggy")]
	_check("g", WorldCupSave.store(_cup_a, 1, p, r, _car(&"taxi"), 1)
		and WorldCupSave.load_entry(_cup_a) != null, "store peste un fisier stricat il rescrie valid")
	# O sectiune necunoscuta ramane dormanta cand se scrie alta cupa.
	_write("cup:no_such_cup", _base())
	WorldCupSave.store(_cup_a, 1, p, r, _car(&"taxi"), 1)
	_check("g", _raw().has_section("cup:no_such_cup") and WorldCupSave.load_entry(_cup_a) != null,
		"cupa necunoscuta ramane dormanta in fisier")

	# Versiune viitoare: nu se citeste, nu se suprascrie.
	_write(_section(_cup_a), _base(), WorldCupSave.VERSION if _sabotage == "viitor" else 2)
	var before := FileAccess.get_file_as_bytes(_path())
	_expect_absent(panel, primary, "versiune viitoare (2)")
	_check("g", WorldCupSave.is_read_only(), "fisierul viitor e read-only")
	WorldCupSave.store(_cup_a, 1, p, r, _car(&"taxi"), 1)
	WorldCupSave.erase(_cup_a.id)
	# Si drumul jocului: o cursa terminata intr-o cupa noua.
	_starts = 0
	GameState.start_championship(_cup_b)
	var race := await _run_finished_race()
	await _end_race(race)
	GameState.champ_active = false
	_check("g", FileAccess.get_file_as_bytes(_path()) == before,
		"fisierul viitor ramane identic octet cu octet dupa store, erase si o cursa de cupa")
	panel.queue_free()
	await _frames(1)


func _expect_absent(panel: WorldCupPanel, primary: Button, what: String) -> void:
	_starts = 0
	var entry := WorldCupSave.load_entry(_cup_a)
	panel.refresh()
	var continued := GameState.continue_championship(_cup_a)
	_check("g", entry == null and primary.text == "START" and not continued and _starts == 0,
		"%s: fara CONTINUE ('%s')" % [what, primary.text])
	GameState.champ_active = false


# ------------------------------------------------------------- h. panoul

func _check_panel() -> void:
	_wipe()
	_forget()
	var panel := WorldCupPanel.new()
	add_child(panel)
	await _frames(2)
	var boxes: Dictionary = panel.get("_boxes")
	_check("h", boxes.size() == GameState.WORLD_CUPS.size(),
		"o cutie per cupa (%d)" % boxes.size())
	for cup_res in GameState.WORLD_CUPS:
		var cup := cup_res as WorldCup
		var box: Dictionary = boxes.get(cup.id, {})
		_check("h", not box.is_empty() and (box.primary as Button).text == "START"
			and not (box.reset as Button).visible and not (box.status as Label).visible,
			"fara save: %s are doar START" % cup.id)

	# Save pe cupa A (bus, GOLD, 11 puncte, locul 2), aratat la reaparitie.
	var points: Array[int] = [11, 13, 4]
	var rivals: Array[int] = [_car(&"monster"), _car(&"hotrod")]
	panel.visible = false
	WorldCupSave.store(_cup_a, 2, points, rivals, _car(&"bus"), 2)
	if _sabotage == "panou":
		WorldCupSave.path_override = _tmp_dir + "alt_fisier.cfg"
	GameState.champ_cup = _cup_a
	panel.visible = true
	await _frames(2)
	WorldCupSave.path_override = _tmp_dir + WorldCupSave.FILE_NAME
	var box_a: Dictionary = boxes[_cup_a.id]
	var primary := box_a.primary as Button
	var reset := box_a.reset as Button
	var status := box_a.status as Label
	_check("h", primary.text == "CONTINUE", "la reaparitie: CONTINUE ('%s')" % primary.text)
	_check("h", reset.visible and reset.text == "RESET", "RESET vizibil ('%s')" % reset.text)
	_check("h", status.visible and status.text == STATUS_EXPECTED,
		"randul de stare: '%s'" % status.text)
	_check("h", reset.get_parent() == primary.get_parent()
		and reset.get_index() == primary.get_index() - 1, "RESET sta langa CONTINUE, in stanga lui")
	_check("h", reset.size.y >= 48.0 and primary.size.y >= 48.0,
		"tinte >= 48 px (RESET %.0f, CONTINUE %.0f)" % [reset.size.y, primary.size.y])
	_check("h", reset.size.x < primary.size.x and primary.custom_minimum_size == Vector2(200, 56),
		"RESET mai ingust (%.0f) decat CONTINUE (%.0f), CONTINUE pe marimea lui START"
			% [reset.size.x, primary.size.x])
	var font := status.get_theme_font("font")
	var width := font.get_string_size(status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_check("h", width <= status.size.x, "randul incape (%.0f / %.0f px)" % [width, status.size.x])
	# Cel mai lung rand posibil: cea mai lunga masina, SILVER, 2 cifre.
	var longest := ""
	for data in GameState.CAR_DATA:
		var n := (data as CarData).display_name.to_upper()
		if n.length() > longest.length():
			longest = n
	var worst := "RACE 4 / 4  ·  6TH  ·  99 PTS  ·  %s  ·  SILVER" % longest
	var worst_w := font.get_string_size(worst, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_check("h", worst_w <= status.size.x, "si cel mai lung rand incape (%.0f / %.0f px): %s"
		% [worst_w, status.size.x, worst])
	var focus := get_viewport().gui_get_focus_owner()
	_check("h", focus == primary, "focus pe butonul cupei jucate (%s)" % (
		focus.name if focus != null else "nimic"))
	# Celelalte cupe: tot START.
	var others_ok := true
	for id: StringName in boxes:
		if id != _cup_a.id:
			others_ok = others_ok and (boxes[id].primary as Button).text == "START"
	_check("h", others_ok, "celelalte cupe raman pe START")
	# START pe o cupa fara save: cupa noua, nimic scris.
	_starts = 0
	GameState.ai_level = 1
	(boxes[_cup_b.id].primary as Button).pressed.emit()
	_check("h", _starts == 1 and GameState.champ_cup == _cup_b and GameState.champ_round == 0
		and GameState.race_ai_level == 1 and WorldCupSave.load_entry(_cup_b) == null,
		"START pe %s: cupa noua de la cursa 1, cu nivelul din selector" % _cup_b.id)
	GameState.champ_active = false
	panel.queue_free()
	await _frames(1)


# --------------------------------------------------------------- captura

## PNG cu panoul: prima cupa in desfasurare, restul neatinse. Cere FEREASTRA
## (randarea nu merge headless) si ruleaza singura, nu in paralel cu alt Godot.
func _capture(out: String) -> void:
	_wipe()
	_forget()
	var points: Array[int] = [11, 13, 4]
	var rivals: Array[int] = [_car(&"monster"), _car(&"hotrod")]
	WorldCupSave.store(_cup_a, 2, points, rivals, _car(&"bus"), 2)
	var panel := WorldCupPanel.new()
	add_child(panel)
	await _frames(4)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("probe_world_cup_save: captura %s (%dx%d)" % [out, img.get_width(), img.get_height()])
	_restore()
	get_tree().quit()


# ---------------------------------------------------------------- final

func _restore() -> void:
	GameState.race_starter = Callable()
	GameState.champ_active = false
	GameState.track_scene_override = ""
	for key: String in _real:
		GameState.set(key, _real[key])
	WorldCupSave.path_override = ""
	_remove_tmp()


func _remove_tmp() -> void:
	if _tmp_dir == "":
		return
	ProbeTmp.remove(_tmp_dir)
	_tmp_dir = ""


func _exit_tree() -> void:
	WorldCupSave.path_override = ""
	_remove_tmp()


func _report() -> void:
	if _checks < MIN_CHECKS:
		_fails.append("doar %d verificari au rulat (minim %d) — garda e oarba" % [
			_checks, MIN_CHECKS])
	print("")
	for f in _fails:
		printerr("probe_world_cup_save: ", f)
	var contracts: Array = _failed_contracts.keys()
	contracts.sort()
	if not contracts.is_empty():
		print("contracte picate: %s" % ", ".join(contracts))
	if _fails.is_empty():
		print("VERDICT: OK (%d verificari)" % _checks)
		get_tree().quit()
		return
	print("VERDICT: PROBLEMA (%d din %d verificari)" % [_fails.size(), _checks])
	get_tree().quit(1)
