extends Node
## ProbeCareerBonus — garda bonusului carierei „NO RETRY" (19 nov 2026).
##
## Decizia dezvoltatorului: bonusul nu mai e specific fiecarei piste; e acelasi
## peste tot — +1 daca termini cursa de cariera fara sa fii ARUNCAT din masina
## si fara sa ceri o repunere (butonul RESET din HUD / actiunea `reset`).
## Izbiturile fara aruncare, hazardele si repunerile AUTOMATE nu costa nimic.
##
## Rulare (ca SCENA, autoload-urile nu se rezolva cu --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCareerBonus.tscn
##   ... -- --sabotaj=NUME   (fiecare trebuie sa PICE contractul lui)
##
## Contractele si sabotajele lor:
##   1. REGULA pe BonusTracker (masina reala, fara pista): aruncarea pierde,
##      RESET-ul pierde, `respawned` singur (repunerea automata) nu; perete,
##      strivit, stropit, lovit nu; pierderea se anunta o singura data.
##        --sabotaj=respawn  tracker-ul ascultat si pe `respawned` (regula veche gresita)
##        --sabotaj=anunt    a doua pierdere re-armeaza anuntul
##   2. REGULA in Race-ul REAL de cariera (Kyoto ca pista activa, Track01 ca
##      scena — usoara): RESET refuzat (numaratoare, ai terminat, cooldown,
##      apasare peste o repunere in curs) pastreaza bonusul; `recover()` si
##      `respawn()` automate il pastreaza; izbiturile il pastreaza; sosirea cu
##      bonus pune bifa si da locul + 1; RESET-ul pornit il pierde; aruncarea
##      reala (`Car._eject`) il pierde; sosirea fara bonus da doar locul si NU
##      sterge bifa castigata inainte.
##        --sabotaj=eject    tracker-ul dezabonat de la `ejected`
##        --sabotaj=reset    orice apasare RESET numarata (si cele refuzate)
##        --sabotaj=auto     repunerea automata (`recovery_started`) numarata
##        --sabotaj=bifa     sosirea fara bonus scrie bifa = rezultatul cursei
##   3. PUNCTELE: fiecare pista din fiecare lume da maxim 4; `max_points()` = 64
##      pe config-ul real; un save cu vechea cheie `challenge=true` se incarca
##      drept bonusul pistei (si pe o pista din lumea 4); schema ramane v1 si
##      cheia de pe disc tot `challenge`.
##        --sabotaj=maxim    o pista in plus in lumea 4 (clona)
##        --sabotaj=cheie    cheia de pe disc redenumita `bonus`
##   4. TEXTELE de pe ecran (literale, nu citite din config): eticheta HUD in
##      ambele stari, mesajul la prima pierdere (ambele cauze) si tacerea la a
##      doua, randul de rezultate in ambele stari, eticheta de pe foaie in ambele
##      stari pe o pista din lumea 1 si una din lumea 4, RACE „/ 4 PTS".
##        --sabotaj=titlu    titlul din config schimbat in „NO RESET"
##   5. NICIUN BONUS IN AFARA CARIEREI: contratimp, Quick Race, World Cup —
##      fara tracker, fara eticheta; `finish_active` in contratimp nu da bonus.
##        --sabotaj=afara    cariera lasata activa cand porneste Quick Race
##
## Nu atinge salvarile reale: `Career.save_path` merge in
## `user://probe_tmp/career_bonus_<pid>/` (ProbeTmp, #722), sters la final.

const ProbeTmp := preload("res://tools/probe_tmp.gd")
const CAR_SCENE := "res://scenes/cars/Car.tscn"
const RACE_SCENE := "res://scenes/race/Race.tscn"
## Scena usoara pe care ruleaza cursele (pista ACTIVA de cariera ramane Kyoto).
const RACE_BENCH := "res://scenes/tracks/Track01.tscn"
const TRACK := &"kyoto"
const WORLD_4_TRACK := &"halong"
## Sub atatea verificari verdictul pica: o sectiune sarita = garda oarba.
const MIN_CHECKS := 145
const SABOTAGES: Array[String] = ["respawn", "anunt", "eject", "reset", "auto",
	"bifa", "maxim", "cheie", "titlu", "afara"]

## Textele asteptate, LITERAL (sabotajul `titlu` trebuie sa le pice).
const HUD_KEPT := "BONUS +1: NO RETRY"
const HUD_LOST := "BONUS LOST"
const FLASH_EJECT_LOST := "EJECTED!\nBONUS LOST"
const FLASH_EJECT := "EJECTED!"
const FLASH_RESET_LOST := "BONUS LOST"
const FLASH_RESPAWN := "MISSED — back on track"
const FLASH_RESPAWN_LOST := "MISSED — back on track\nBONUS LOST"
const RESULT_KEPT := "1ST PLACE +3  ·  NO RETRY +1  =  4 PTS"
const RESULT_LOST := "1ST PLACE +3  ·  BONUS LOST  =  3 PTS"
const SHEET_OPEN := "BONUS +1  ·  NO RETRY\nFinish without an eject or a RESET."
const SHEET_DONE := "BONUS +1  ·  NO RETRY  ·  DONE"

var _sabotage: String = ""
var _checks: int = 0
var _fails: Array[String] = []
var _failed_contracts: Dictionary = {}
var _real_config: CareerConfig
var _real_save_path: String
var _real_track: int
var _real_laps: int
var _real_ai: int
var _tmp_dir: String = ""
var _career_path: String = ""
## Ce scria mesajul din centru in clipa fiecarui `respawned` / `ejected` al
## jucatorului (handler-ul sondei e legat DUPA al cursei, deci vede textul ei).
var _respawn_flashes: Array[String] = []
var _eject_flashes: Array[String] = []
var _lost_signals: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
	if _sabotage != "" and not SABOTAGES.has(_sabotage):
		printerr("probe_career_bonus: sabotaj necunoscut '%s' (stiu: %s)" % [
			_sabotage, ", ".join(SABOTAGES)])
		get_tree().quit(2)
		return
	if _sabotage != "":
		print("SABOTAJ: %s" % _sabotage)

	_real_config = Career.config
	_real_save_path = Career.save_path
	_real_track = GameState.selected_track
	_real_laps = GameState.total_laps
	_real_ai = GameState.ai_count
	_tmp_dir = ProbeTmp.make("career_bonus")
	_career_path = _tmp_dir + "career.cfg"
	Career.save_path = _career_path
	Career.race_starter = func() -> void: pass
	if _sabotage == "titlu":
		var cfg := _clone_config()
		cfg.bonus_title = "NO RESET"
		_real_config_for_run = cfg
	_fresh()

	print("== 1. regula pe BonusTracker")
	await _check_tracker()
	print("== 2. regula in Race-ul real de cariera")
	await _check_race_kept()
	await _check_race_reset()
	await _check_race_eject()
	print("== 3. punctele")
	_check_points()
	print("== 4. textele (HUD, foaia)")
	await _check_texts()
	print("== 5. niciun bonus in afara carierei")
	await _check_elsewhere()

	_restore()
	_report()


## Config-ul folosit de rulare (cel real, sau clona sabotata de `titlu`).
var _real_config_for_run: CareerConfig = null


# ------------------------------------------------------------------ utilitare

func _check(contract: String, ok: bool, what: String) -> void:
	_checks += 1
	print("  %s [%s] %s" % ["OK  " if ok else "PICA", contract, what.replace("\n", " | ")])
	if not ok:
		_fails.append("[%s] %s" % [contract, what.replace("\n", " | ")])
		_failed_contracts[contract] = true


## Save gol pe disc si in memorie.
func _fresh() -> void:
	Career.leave()
	Career.config = _real_config_for_run if _real_config_for_run != null else _real_config
	if FileAccess.file_exists(_career_path):
		DirAccess.remove_absolute(_career_path)
	Career.load_progress()


func _clone_config() -> CareerConfig:
	var out := CareerConfig.new()
	for src in _real_config.worlds:
		var w := CareerWorld.new()
		w.id = src.id
		w.display_name = src.display_name
		w.tracks = src.tracks.duplicate()
		w.free = src.free
		w.points_to_unlock = src.points_to_unlock
		w.rival = src.rival
		w.rival_track = src.rival_track
		out.worlds.append(w)
	out.bonus_title = _real_config.bonus_title
	out.bonus_hint = _real_config.bonus_hint
	out.starting_cars = _real_config.starting_cars.duplicate()
	out.car_rewards = _real_config.car_rewards.duplicate()
	return out


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Asteapta pana `cond` e adevarata (cel mult `max_frames` cadre de fizica).
func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func _collect(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		out.append(child)
		_collect(child, out)


## Cursa reala: Race.tscn pe banc, cu ce a pregatit apelantul in GameState /
## Career. Legaturile sondei la `respawned` / `ejected` vin DUPA ale cursei.
func _start_race() -> Race:
	GameState.track_scene_override = RACE_BENCH
	GameState.total_laps = 1
	if not Career.is_time_trial(): # contratimpul isi pune singur ai_count = 0
		GameState.ai_count = 2
	_respawn_flashes.clear()
	_eject_flashes.clear()
	_lost_signals = 0
	var race := (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(race)
	await get_tree().process_frame
	race.player.respawned.connect(func(_c: Car) -> void:
		_respawn_flashes.append(race.hud.flash_text()))
	race.player.ejected.connect(func(_c: Car, _r: Node3D) -> void:
		_eject_flashes.append(race.hud.flash_text()))
	var tracker := _tracker_of(race)
	if tracker != null:
		tracker.lost_changed.connect(func(_cause: StringName) -> void:
			_lost_signals += 1)
	return race


func _end_race(race: Race) -> void:
	race.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.track_scene_override = ""


func _tracker_of(race: Race) -> BonusTracker:
	return race.get("_bonus_tracker") as BonusTracker


func _hud_label(race: Race) -> Label:
	return race.hud.get("_bonus_label") as Label


## Apasarea RESET / tasta R, exact drumul jocului. Sabotajul `reset` o numara
## si cand e refuzata (bug-ul pe care il prinde contractul 2).
func _press_reset(race: Race) -> void:
	race.call("_on_respawn_requested")
	if _sabotage == "reset" and _tracker_of(race) != null:
		_tracker_of(race).note_reset()


func _cooldown_over(race: Race) -> bool:
	return race.player.can_respawn() and not race.player.is_recovering()


# ------------------------------------------------------- 1. tracker, unitar

func _make_car() -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	return car


func _check_tracker() -> void:
	var player := _make_car()
	var other := _make_car()
	player.is_player = true
	await get_tree().process_frame

	var t := BonusTracker.new()
	add_child(t)
	t.setup(player)
	if _sabotage == "respawn":
		player.respawned.connect(func(_c: Car) -> void: t.note_reset())
	var fired: Array[StringName] = []
	t.lost_changed.connect(func(cause: StringName) -> void: fired.append(cause))
	_check("1", not t.lost and t.evaluate() and t.lost_cause == &"",
		"tracker nou: bonusul intreg")
	# Tot ce NU costa bonusul.
	player.respawned.emit(player)
	_check("1", not t.lost, "`respawned` singur (repunere automata) nu pierde bonusul")
	player.wall_hit.emit(player, 40.0)
	_check("1", not t.lost, "izbitura de perete fara aruncare nu pierde bonusul")
	player.crushed.emit(player, 1.0)
	_check("1", not t.lost, "strivit / ars (`crushed`) nu pierde bonusul")
	player.splashed.emit(player, 0.9)
	_check("1", not t.lost, "stropit de val (`splashed`) nu pierde bonusul")
	player.bumped.emit(player, other, 12.0)
	_check("1", not t.lost, "lovit de alta masina (`bumped`) nu pierde bonusul")
	var other_rag := Node3D.new()
	other.ejected.emit(other, other_rag)
	other_rag.free()
	_check("1", not t.lost, "aruncarea ALTEI masini nu pierde bonusul")
	_check("1", fired.is_empty() and not t.take_announcement(),
		"nimic de anuntat cat bonusul e intreg")
	# Aruncarea jucatorului: pierdut, o singura data.
	var rag := Node3D.new()
	player.ejected.emit(player, rag)
	_check("1", t.lost and not t.evaluate() and t.lost_cause == &"eject",
		"aruncarea jucatorului pierde bonusul (cauza %s)" % t.lost_cause)
	_check("1", fired == [&"eject"], "lost_changed o data, cu cauza eject (%s)" % str(fired))
	_check("1", t.take_announcement(), "prima pierdere se anunta")
	_check("1", not t.take_announcement(), "anuntul se ia o singura data")
	player.ejected.emit(player, rag)
	t.note_reset()
	if _sabotage == "anunt":
		t.set("_unannounced", true)
	_check("1", fired.size() == 1 and t.lost_cause == &"eject",
		"a doua pierdere nu re-emite si nu schimba cauza (%s)" % str(fired))
	_check("1", not t.take_announcement(), "a doua pierdere nu se mai anunta")
	t.queue_free()
	rag.free()

	# RESET-ul pornit: pierdut, cauza reset.
	var t2 := BonusTracker.new()
	add_child(t2)
	t2.setup(player)
	var fired2: Array[StringName] = []
	t2.lost_changed.connect(func(cause: StringName) -> void: fired2.append(cause))
	t2.note_reset()
	_check("1", t2.lost and not t2.evaluate() and t2.lost_cause == &"reset"
		and fired2 == [&"reset"], "RESET-ul cerut pierde bonusul (%s)" % str(fired2))
	_check("1", t2.take_announcement() and not t2.take_announcement(),
		"RESET: anuntat o singura data")
	t2.note_reset()
	_check("1", fired2.size() == 1, "al doilea RESET nu re-emite (%d)" % fired2.size())
	t2.queue_free()
	player.queue_free()
	other.queue_free()
	await get_tree().process_frame


# ------------------------------------------- 2a. cursa reala: bonus pastrat

func _check_race_kept() -> void:
	_fresh()
	Career.start_track(TRACK, Career.Mode.RACE)
	var race := await _start_race()
	var tracker := _tracker_of(race)
	var player := race.player
	_check("2", tracker != null and tracker.get_parent() == race,
		"cursa RACE de cariera are BonusTracker, copil al cursei")
	if tracker == null:
		await _end_race(race)
		return
	if _sabotage == "auto":
		player.recovery_started.connect(func(_c: Car, _s: float) -> void: tracker.note_reset())
	var label := _hud_label(race)
	_check("4", label != null and label.visible and label.text == HUD_KEPT,
		"HUD la start: '%s'" % (label.text if label != null else "<lipsa>"))
	_check("4", label != null and label.modulate.is_equal_approx(RaceHUD.BONUS_COLOR),
		"HUD la start: eticheta verde")

	# RESET in numaratoare: refuzat.
	_check("2", race.state == Race.State.COUNTDOWN, "premisa: cursa e in numaratoare")
	_press_reset(race)
	_check("2", not player.is_recovering() and not tracker.lost,
		"RESET in numaratoare: refuzat, bonusul ramane")
	race.call("_go")
	_check("2", race.state == Race.State.RUNNING, "premisa: cursa ruleaza dupa _go")
	await _physics(3)

	# RESET dupa sosire: refuzat.
	player.finished = true
	_press_reset(race)
	player.finished = false
	_check("2", not player.is_recovering() and not tracker.lost,
		"RESET dupa sosire: refuzat, bonusul ramane")

	# Izbiturile si hazardele pe masina reala, in cursa.
	player.wall_hit.emit(player, 40.0)
	player.crushed.emit(player, 0.8)
	player.splashed.emit(player, 0.9)
	var rival: Car = race.cars[1] if race.cars.size() > 1 else null
	if rival != null:
		player.bumped.emit(player, rival, 10.0)
	_check("2", not tracker.lost, "perete, strivit, stropit, lovit in cursa: bonusul ramane")

	# Repunere automata (ce cheama plasa cursei: rasturnat, impotmolit) +
	# o apasare RESET peste ea: nu e un al doilea „retry".
	_check("2", _cooldown_over(race), "premisa: masina se poate repune")
	player.recover()
	_check("2", player.is_recovering(), "premisa: recover() automat a pornit tranzitia")
	_press_reset(race)
	_check("2", not tracker.lost,
		"RESET apasat peste o repunere automata in curs: bonusul ramane")
	var respawned := await _until(func() -> bool: return _respawn_flashes.size() >= 1, 150)
	_check("2", respawned and not tracker.lost,
		"repunerea automata s-a terminat (`respawned`), bonusul ramane")
	_check("4", _respawn_flashes.size() >= 1 and _respawn_flashes[0] == FLASH_RESPAWN,
		"mesajul repunerii automate, fara BONUS LOST: '%s'" % (
			_respawn_flashes[0] if not _respawn_flashes.is_empty() else "<nimic>"))

	# Imediat dupa repunere: cooldown, deci RESET refuzat de Car.recover().
	_check("2", not player.can_respawn(), "premisa: cooldown dupa repunere")
	_press_reset(race)
	_check("2", not player.is_recovering() and not tracker.lost,
		"RESET in cooldown (refuzat de Car.recover): bonusul ramane")

	# `respawn()` direct (hazardele cu punere in scena, caderea de pe harta).
	await _until(func() -> bool: return _cooldown_over(race), 200)
	player.respawn()
	await _physics(2)
	_check("2", _respawn_flashes.size() >= 2 and not tracker.lost,
		"respawn() automat: bonusul ramane (%d repuneri)" % _respawn_flashes.size())
	_check("2", _lost_signals == 0, "nicio pierdere semnalata (%d)" % _lost_signals)

	# Sosirea cu bonusul intreg.
	var had_bonus := Career.has_bonus(TRACK)
	race.call("_finish_race")
	var place := player.race_position
	var expected := Career.medal_for_position(place) + Career.BONUS_POINTS
	_check("2", not had_bonus and Career.has_bonus(TRACK),
		"sosirea cu bonusul pune bifa pe %s" % TRACK)
	_check("2", int(race.get("_career_points")) == expected,
		"locul %d + bonus = %d puncte in cursa asta (%d)" % [place, expected,
			int(race.get("_career_points"))])
	_check("2", Career.track_points(TRACK) == expected,
		"pe raft: %d (%d)" % [expected, Career.track_points(TRACK)])
	race.call("_show_results")
	var title := _results_title(race)
	_check("4", title.ends_with("NO RETRY +1  =  %d PTS" % expected),
		"rezultatele, bonus pastrat: '%s'" % title)
	# Randul exact, pe locul 1 (fortat: grila nu se alege din sonda).
	player.race_position = 1
	race.set("_career_medal", Career.MEDAL_GOLD)
	race.set("_career_points", Career.MAX_TRACK_POINTS)
	_check("4", race.call("_career_points_text") == RESULT_KEPT,
		"rezultatul, bonus pastrat: '%s'" % race.call("_career_points_text"))
	await _end_race(race)
	Career.leave()


func _results_title(race: Race) -> String:
	var box: VBoxContainer = race.hud.get("_results_box")
	return (box.get_child(0) as Label).text if box != null and box.get_child_count() > 0 else ""


# ------------------------------------------- 2b. cursa reala: RESET cerut

func _check_race_reset() -> void:
	# Continua save-ul din 2a: Kyoto are deja bifa.
	Career.config = _real_config_for_run if _real_config_for_run != null else _real_config
	Career.start_track(TRACK, Career.Mode.RACE)
	var race := await _start_race()
	var tracker := _tracker_of(race)
	var player := race.player
	if tracker == null:
		_check("2", false, "cursa RESET: lipseste BonusTracker")
		await _end_race(race)
		return
	race.call("_go")
	await _physics(3)
	_check("2", _cooldown_over(race), "premisa: masina se poate repune")
	_press_reset(race)
	_check("2", player.is_recovering() and tracker.lost and tracker.lost_cause == &"reset",
		"RESET pornit in cursa: repunerea incepe si bonusul se pierde (cauza %s)"
			% tracker.lost_cause)
	_check("4", race.hud.flash_text() == FLASH_RESET_LOST,
		"mesajul la apasare: '%s'" % race.hud.flash_text())
	var label := _hud_label(race)
	_check("4", label.text == HUD_LOST and label.modulate.is_equal_approx(RaceHUD.BONUS_LOST_COLOR),
		"HUD dupa RESET: '%s', rosu" % label.text)
	# Lizibil pana vine repunerea: tranzitia (RECOVER_S) e mai scurta decat cat
	# sta mesajul plin, iar la 0.9 s mesajul e tot acolo.
	_check("4", Car.RECOVER_S < RaceHUD.FLASH_HOLD_S,
		"RECOVER_S %.2f s < FLASH_HOLD_S %.2f s" % [Car.RECOVER_S, RaceHUD.FLASH_HOLD_S])
	await _physics(54)
	_check("4", _respawn_flashes.is_empty() and race.hud.flash_text() == FLASH_RESET_LOST,
		"la 0.9 s dupa apasare BONUS LOST inca pe ecran ('%s')" % race.hud.flash_text())
	await _until(func() -> bool: return _respawn_flashes.size() >= 1, 120)
	_check("4", _respawn_flashes.size() == 1 and _respawn_flashes[0] == FLASH_RESPAWN_LOST,
		"mesajul repunerii ceruta repeta pierderea: '%s'" % (
			_respawn_flashes[0] if not _respawn_flashes.is_empty() else "<nimic>"))

	# Al doilea RESET: tot repunere, dar nimic nou pe ecran.
	await _until(func() -> bool: return _cooldown_over(race), 200)
	race.hud.flash_message("MARK")
	_press_reset(race)
	_check("2", player.is_recovering() and tracker.lost, "al doilea RESET porneste repunerea")
	_check("4", race.hud.flash_text() == "MARK" and _lost_signals == 1,
		"al doilea RESET nu mai anunta nimic ('%s', %d pierderi)" % [
			race.hud.flash_text(), _lost_signals])
	await _until(func() -> bool: return _respawn_flashes.size() >= 2, 120)
	_check("4", _respawn_flashes.size() == 2 and _respawn_flashes[1] == FLASH_RESPAWN,
		"repunerea de dupa al doilea RESET: mesajul simplu ('%s')" % (
			_respawn_flashes[1] if _respawn_flashes.size() >= 2 else "<nimic>"))

	# Sosirea fara bonus: doar locul; bifa din 2a ramane.
	race.call("_finish_race")
	if _sabotage == "bifa":
		Career._state_for(TRACK).challenge = bool(race.get("_bonus_kept"))
	var place := player.race_position
	_check("2", int(race.get("_career_points")) == Career.medal_for_position(place),
		"bonus pierdut: doar locul %d = %d (%d)" % [place,
			Career.medal_for_position(place), int(race.get("_career_points"))])
	_check("2", Career.has_bonus(TRACK),
		"bonus pierdut acum NU sterge bifa castigata intr-o cursa de dinainte")
	race.call("_show_results")
	_check("4", _results_title(race).ends_with("BONUS LOST  =  %d PTS"
		% Career.medal_for_position(place)), "rezultatele, bonus pierdut: '%s'" % _results_title(race))
	player.race_position = 1
	race.set("_career_medal", Career.MEDAL_GOLD)
	race.set("_career_points", Career.MEDAL_GOLD)
	_check("4", race.call("_career_points_text") == RESULT_LOST,
		"rezultatul, bonus pierdut: '%s'" % race.call("_career_points_text"))
	await _end_race(race)
	Career.leave()


# ------------------------------------------- 2c. cursa reala: aruncarea

func _check_race_eject() -> void:
	Career.start_track(TRACK, Career.Mode.RACE)
	var race := await _start_race()
	var tracker := _tracker_of(race)
	var player := race.player
	if tracker == null:
		_check("2", false, "cursa EJECT: lipseste BonusTracker")
		await _end_race(race)
		return
	if _sabotage == "eject":
		player.ejected.disconnect(Callable(tracker, "_on_ejected"))
	race.call("_go")
	await _physics(3)
	player.call("_eject", Vector3(0.0, 4.0, 6.0), "probe")
	_check("2", player.is_ejected and _eject_flashes.size() == 1,
		"premisa: Car._eject real a aruncat soferul (%d semnale)" % _eject_flashes.size())
	_check("2", tracker.lost and tracker.lost_cause == &"eject",
		"aruncarea reala pierde bonusul (cauza %s)" % tracker.lost_cause)
	_check("4", _eject_flashes.size() == 1 and _eject_flashes[0] == FLASH_EJECT_LOST,
		"mesajul aruncarii care a costat bonusul: '%s'" % (
			_eject_flashes[0] if not _eject_flashes.is_empty() else "<nimic>"))
	_check("4", _hud_label(race).text == HUD_LOST, "HUD dupa aruncare: '%s'" % _hud_label(race).text)
	_check("4", player.eject_hold < RaceHUD.FLASH_HOLD_S,
		"eject_hold %.2f s < FLASH_HOLD_S %.2f s (mesajul sta pana la repunere)" % [
			player.eject_hold, RaceHUD.FLASH_HOLD_S])
	# RESET in timpul aruncarii: Car.recover() refuza, nu e o a doua pierdere.
	_press_reset(race)
	_check("2", not player.is_recovering() and _lost_signals <= 1,
		"RESET in aruncare: refuzat, fara a doua pierdere")
	await _until(func() -> bool: return _respawn_flashes.size() >= 1, 200)
	_check("4", _respawn_flashes.size() == 1 and _respawn_flashes[0] == FLASH_RESPAWN_LOST,
		"repunerea de dupa aruncare repeta pierderea: '%s'" % (
			_respawn_flashes[0] if not _respawn_flashes.is_empty() else "<nimic>"))
	# A doua aruncare: doar „EJECTED!".
	await _physics(3)
	player.call("_eject", Vector3(0.0, 4.0, 6.0), "probe")
	_check("4", _eject_flashes.size() == 2 and _eject_flashes[1] == FLASH_EJECT,
		"a doua aruncare: mesajul simplu ('%s')" % (
			_eject_flashes[1] if _eject_flashes.size() >= 2 else "<nimic>"))
	await _until(func() -> bool: return _respawn_flashes.size() >= 2, 200)
	_check("4", _respawn_flashes.size() == 2 and _respawn_flashes[1] == FLASH_RESPAWN,
		"repunerea de dupa a doua aruncare: mesajul simplu ('%s')" % (
			_respawn_flashes[1] if _respawn_flashes.size() >= 2 else "<nimic>"))
	_check("2", _lost_signals == (0 if _sabotage == "eject" else 1),
		"o singura pierdere semnalata in toata cursa (%d)" % _lost_signals)
	await _end_race(race)
	Career.leave()


# ------------------------------------------------------------- 3. punctele

func _check_points() -> void:
	_fresh()
	var cfg := Career.config
	if _sabotage == "maxim":
		cfg = _clone_config()
		cfg.worlds[3].tracks.append(&"dunele")
		Career.config = cfg
	var tracks := 0
	for world in Career.worlds():
		for id in world.tracks:
			tracks += 1
			Career.set_race_medal(id, Career.MEDAL_GOLD)
			Career.set_bonus(id)
			_check("3", Career.track_points(id) == 4 and Career.MAX_TRACK_POINTS == 4,
				"%s/%s: loc 1 + bonus = 4 (%d)" % [world.id, id, Career.track_points(id)])
	_check("3", tracks == 16, "16 piste in cele 4 lumi (%d)" % tracks)
	_check("3", Career.max_points() == 64, "max_points() = 64 (%d)" % Career.max_points())
	_check("3", Career.points() == Career.max_points(),
		"toate pistele pline = maximul (%d / %d)" % [Career.points(), Career.max_points()])
	Career.config = _real_config_for_run if _real_config_for_run != null else _real_config

	# Un save de dinainte, cu bifa veche `challenge=true`: pe Kyoto (avea
	# provocare) si pe Ha Long (lumea 4, n-avea): ambele sunt acum bonusul.
	Career.leave()
	var old := ConfigFile.new()
	old.set_value("meta", "version", 1)
	old.set_value("track:%s" % TRACK, "race_medal", 2)
	old.set_value("track:%s" % TRACK, "challenge", true)
	old.set_value("track:%s" % WORLD_4_TRACK, "challenge", true)
	old.save(_career_path)
	Career.load_progress()
	_check("3", Career.has_bonus(TRACK) and Career.track_points(TRACK) == 3,
		"save vechi: Kyoto argint + bifa = 3 (%d)" % Career.track_points(TRACK))
	_check("3", Career.has_bonus(WORLD_4_TRACK) and Career.track_points(WORLD_4_TRACK) == 1,
		"save vechi: bifa ramasa pe %s (lumea 4) conteaza = 1 (%d)" % [WORLD_4_TRACK,
			Career.track_points(WORLD_4_TRACK)])
	_check("3", Career.points() == 4, "save vechi: 3 + 1 = 4 puncte (%d)" % Career.points())

	# Pe disc: schema 1, cheia tot `challenge`.
	Career.set_bonus(&"angkor")
	if _sabotage == "cheie":
		var text := FileAccess.get_file_as_string(_career_path).replace("challenge=", "bonus=")
		var f := FileAccess.open(_career_path, FileAccess.WRITE)
		f.store_string(text)
		f.close()
	var disk := ConfigFile.new()
	disk.load(_career_path)
	_check("3", Career.SAVE_VERSION == 1 and int(disk.get_value("meta", "version", -1)) == 1,
		"schema ramane v1 (%s)" % str(disk.get_value("meta", "version", -1)))
	_check("3", disk.get_value("track:angkor", "challenge", false) == true
		and not disk.has_section_key("track:angkor", "bonus"),
		"pe disc bonusul de pe Angkor sta tot sub cheia `challenge`")
	Career.load_progress()
	_check("3", Career.has_bonus(&"angkor") and Career.has_bonus(TRACK),
		"dupa reincarcare bifele raman (Angkor, Kyoto)")
	Career.leave()


# -------------------------------------------------------------- 4. textele

func _check_texts() -> void:
	# Eticheta din HUD, pe un RaceHUD real.
	var hud := RaceHUD.new()
	add_child(hud)
	await get_tree().process_frame
	var label := hud.get("_bonus_label") as Label
	_check("4", label != null and not label.visible, "HUD nou: eticheta ascunsa")
	hud.set_bonus(Career.config.bonus_title)
	_check("4", label.visible and label.text == HUD_KEPT, "HUD set_bonus: '%s'" % label.text)
	hud.set_bonus_lost()
	_check("4", label.visible and label.text == HUD_LOST
		and label.modulate.is_equal_approx(RaceHUD.BONUS_LOST_COLOR),
		"HUD set_bonus_lost: '%s', rosu" % label.text)
	_check("4", Race.eject_flash_text(true) == FLASH_EJECT_LOST
		and Race.eject_flash_text(false) == FLASH_EJECT
		and Race.respawn_flash_text(true) == FLASH_RESPAWN_LOST
		and Race.respawn_flash_text(false) == FLASH_RESPAWN,
		"textele mesajelor de aruncare / repunere")
	hud.queue_free()

	# Foaia pistei: pe FIECARE pista eticheta BONUS si RACE din 4.
	_fresh()
	var panel := CareerPanel.new()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	for world in Career.worlds():
		for id in world.tracks:
			panel._open_sheet(id)
			await get_tree().process_frame
			var labels := _sheet_nodes(panel, "Label")
			var buttons := _sheet_nodes(panel, "Button")
			var bonus: Label = labels.get("BonusLabel")
			var race: Button = buttons.get("RaceButton")
			_check("4", bonus != null and bonus.text == SHEET_OPEN,
				"%s: foaia '%s'" % [id, bonus.text if bonus != null else "<lipsa>"])
			_check("4", race != null and race.text == "RACE\nNO PODIUM YET  ·  0 / 4 PTS",
				"%s: RACE '%s'" % [id, race.text if race != null else "<lipsa>"])
			_check("4", buttons.size() == 3 and not buttons.has("ChallengeButton"),
				"%s: 3 butoane (RACE, TIME TRIAL, BACK), niciun CHALLENGE (%d)" % [id, buttons.size()])
	# Bifa pusa pe o pista din lumea 1 si una din lumea 4.
	var w1: StringName = Career.worlds()[0].tracks[0]
	Career.start_track(w1, Career.Mode.RACE)
	Career.finish_active(3, true)
	Career.leave()
	Career.start_track(WORLD_4_TRACK, Career.Mode.RACE)
	Career.finish_active(5, true)
	Career.leave()
	for case in [[w1, "3RD PLACE  ·  2 / 4 PTS"], [WORLD_4_TRACK, "NO PODIUM YET  ·  1 / 4 PTS"]]:
		var id: StringName = case[0]
		panel._open_sheet(id)
		await get_tree().process_frame
		var bonus: Label = _sheet_nodes(panel, "Label").get("BonusLabel")
		var race: Button = _sheet_nodes(panel, "Button").get("RaceButton")
		_check("4", bonus != null and bonus.text == SHEET_DONE,
			"%s cu bifa: '%s'" % [id, bonus.text if bonus != null else "<lipsa>"])
		_check("4", race != null and race.text == "RACE\n" + String(case[1]),
			"%s cu bifa: RACE '%s'" % [id, race.text if race != null else "<lipsa>"])
	panel.queue_free()
	await get_tree().process_frame


func _sheet_nodes(panel: CareerPanel, cls: String) -> Dictionary:
	var out := {}
	if panel._sheet == null:
		return out
	var nodes: Array[Node] = []
	_collect(panel._sheet, nodes)
	for n in nodes:
		if n.is_class(cls):
			out[n.name] = n
	return out


# ---------------------------------------------- 5. in afara carierei

func _check_elsewhere() -> void:
	_fresh()
	# Contratimp: Career activ, dar nu RACE.
	Career.start_track(TRACK, Career.Mode.TIME_TRIAL)
	_check("5", Career.is_time_trial() and not Career.bonus_active(),
		"contratimpul nu poarta bonusul")
	var tt := await _start_race()
	_check("5", _tracker_of(tt) == null and not _hud_label(tt).visible,
		"contratimp real: fara BonusTracker, fara eticheta")
	await _end_race(tt)
	_check("5", Career.finish_active(1, true) == Career.MEDAL_GOLD
		and not Career.has_bonus(TRACK),
		"finish_active in contratimp nu da bonus si nu pune bifa")
	Career.leave()
	_check("5", Career.finish_active(1, true) == 0, "in afara carierei finish_active da 0")

	# Quick Race: cariera inchisa (o lasa activa doar sabotajul).
	if _sabotage == "afara":
		Career.start_track(TRACK, Career.Mode.RACE)
	GameState.champ_active = false
	_check("5", _sabotage == "afara" or not Career.bonus_active(), "premisa: cariera inchisa")
	var quick := await _start_race()
	_check("5", _tracker_of(quick) == null and not _hud_label(quick).visible,
		"Quick Race real: fara BonusTracker, fara eticheta")
	await _end_race(quick)
	Career.leave()

	# World Cup: cupa reala, prima cursa.
	var cup := GameState.WORLD_CUPS[0] as WorldCup
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	GameState.champ_active = true
	GameState.champ_cup = cup
	GameState.champ_round = 0
	GameState.ai_count = 2
	GameState.champ_points.clear()
	GameState.champ_points.resize(GameState.ai_count + 1)
	GameState.champ_ai_cars = GameState.draw_ai_lineup(GameState.selected_car,
		GameState.ai_count, rng)
	GameState.selected_track = cup.track_index(0)
	var wc := await _start_race()
	_check("5", _tracker_of(wc) == null and not _hud_label(wc).visible,
		"World Cup real: fara BonusTracker, fara eticheta")
	await _end_race(wc)
	GameState.champ_active = false


# ---------------------------------------------------------------- final

func _restore() -> void:
	Career.leave()
	Career.race_starter = Callable()
	Career.config = _real_config
	Career.save_path = _real_save_path
	GameState.selected_track = _real_track
	GameState.total_laps = _real_laps
	GameState.ai_count = _real_ai
	GameState.champ_active = false
	GameState.track_scene_override = ""
	_remove_tmp()


func _remove_tmp() -> void:
	if _tmp_dir == "":
		return
	ProbeTmp.remove(_tmp_dir)
	_tmp_dir = ""


func _exit_tree() -> void:
	_remove_tmp()


func _report() -> void:
	if _checks < MIN_CHECKS:
		_fails.append("doar %d verificari au rulat (minim %d) — garda e oarba" % [
			_checks, MIN_CHECKS])
	print("")
	for f in _fails:
		printerr("probe_career_bonus: ", f)
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
