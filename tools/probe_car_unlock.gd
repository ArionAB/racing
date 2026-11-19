extends Node
## ProbeCarUnlock — garda masinilor castigate in cariera (19 nov 2026).
##
## Decizia dezvoltatorului: masinile se CASTIGA in cariera (pistele raman
## deschise peste tot). Garajul de start e Taxi + Buggy; restul vin la praguri
## de puncte de cariera (`career_config.tres`, `CareerCarReward`) si se
## ZAVORASC: o masina castigata nu se mai pierde.
##
## Rulare (ca SCENA, autoload-urile nu se rezolva cu --script):
##   godot --headless --path . res://tools/ProbeCarUnlock.tscn
##   ... -- --sabotaj=NUME   (fiecare trebuie sa PICE contractul lui)
##
## Contractele si sabotajele lor:
##   1. SAVE GOL: deschise sunt exact masinile de start, fiecare masina-
##      recompensa e incuiata, iar config-ul REAL acopera tot garajul (fiecare
##      masina din CAR_DATA e de start sau recompensa).
##        --sabotaj=start   o recompensa scoasa din config (masina ramane deschisa)
##   2. PRAGUL, prin `Career.start_track` (cu `race_starter` de proba) si
##      `finish_active`: la prag - 1 masina e incuiata, la prag e deschisa,
##      `last_unlocked_cars` e exact ea, `car_unlocked` a sunat o data; o cursa
##      in plus nu o mai anunta.
##        --sabotaj=prag    pragul Politiei coborat cu 1 (off-by-one)
##   3. ZAVORUL si PERSISTENTA: dupa reincarcare de pe disc masina ramane; cu
##      pragul ridicat peste punctele curente ramane; cu comutatorul de
##      dezvoltator totul e deschis si `[garage] unlocked` de pe disc nu se
##      schimba; stins, masinile necastigate se incuie la loc.
##        --sabotaj=zavor   masina scoasa din zavor (lacat calculat din puncte)
##        --sabotaj=dev     comutatorul scrie toate masinile in zavor
##   4. GARAJUL, pe noduri reale (`GaragePanel`): SELECT pe o masina incuiata nu
##      schimba `selected_car`, pe una deschisa o schimba; lacatele vizibile =
##      masinile incuiate (si dupa un punct castigat); SELECT spune ce lipseste;
##      7 atingeri pe titlu in 3 s comuta, cele rare nu, atingerea emulata nu se
##      numara de doua ori.
##        --sabotaj=garaj   garda din `_on_select_pressed` ocolita
##        --sabotaj=dublu   atingerile emulate numarate si ele
##   5. `ensure_selected_car`: o selectie incuiata trece pe PRIMA masina de
##      start, DOAR IN MEMORIE — fisierul de setari ramane neatins (meniul
##      ruleaza si in save-ul comun al sondelor: o scriere acolo schimba masina
##      jucatorului in toate cursele de dupa); una deschisa ramane.
##        --sabotaj=ordine  starting_cars inversat in config
##        --sabotaj=scrie   selectia mutata e si salvata, ca in prima varianta
##   6. `validate()`: fiecare regula noua, sabotata in memorie, da exact
##      problema ei; config-ul real e curat; `CareerConfig.new()` da tot doar
##      problema „o lume free".
##        --sabotaj=validare  mutatia nu se mai aplica
##   7. TEXTELE: randul de rezultate („NEW CAR: ...", citit de pe eticheta reala
##      din RaceHUD) si randurile pasaportului (de pe etichetele reale din
##      CareerPanel) contin numele masinii.
##        --sabotaj=text    `last_unlocked_cars` golita inainte de rezultate
##
## Nu atinge salvarile reale: `Career.save_path` si `GameState.settings_path`
## merg in `user://probe_tmp/car_unlock_<pid>/` (ProbeTmp, #722), sters la final.

const ProbeTmp := preload("res://tools/probe_tmp.gd")
## Sub atatea verificari verdictul pica: o sectiune sarita = garda oarba.
const MIN_CHECKS := 90
const SABOTAGES: Array[String] = ["start", "prag", "zavor", "dev", "garaj", "dublu",
	"ordine", "scrie", "validare", "text"]

var _sabotage: String = ""
var _checks: int = 0
var _fails: Array[String] = []
var _failed_contracts: Dictionary = {}
var _real_config: CareerConfig
var _real_save_path: String
var _real_settings_path: String
var _real_selected_car: int
var _real_selected_track: int
var _real_dev: bool
var _tmp_dir: String = ""
var _career_path: String = ""
var _settings_path: String = ""
## Masinile anuntate prin `Career.car_unlocked`, in ordine.
var _announced: Array[StringName] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
	if _sabotage != "" and not SABOTAGES.has(_sabotage):
		printerr("probe_car_unlock: sabotaj necunoscut '%s' (stiu: %s)" % [
			_sabotage, ", ".join(SABOTAGES)])
		get_tree().quit(2)
		return
	if _sabotage != "":
		print("SABOTAJ: %s" % _sabotage)

	_real_config = Career.config
	_real_save_path = Career.save_path
	_real_settings_path = GameState.settings_path
	_real_selected_car = GameState.selected_car
	_real_selected_track = GameState.selected_track
	_real_dev = GameState.dev_unlock_all_cars
	_tmp_dir = ProbeTmp.make("car_unlock")
	_career_path = _tmp_dir + "career.cfg"
	_settings_path = _tmp_dir + "settings.cfg"
	Career.save_path = _career_path
	GameState.settings_path = _settings_path
	GameState.dev_unlock_all_cars = false
	Career.car_unlocked.connect(_on_car_unlocked)

	print("== 1. save gol")
	_check_fresh()
	print("== 2. pragul, prin start_track / finish_active")
	_check_threshold()
	print("== 3. zavorul si persistenta")
	_check_latch()
	print("== 4. garajul, pe noduri reale")
	await _check_garage()
	print("== 5. ensure_selected_car")
	_check_ensure()
	print("== 6. validate()")
	_check_validate()
	print("== 7. textele")
	await _check_texts()

	_restore()
	_report()


# ------------------------------------------------------------------ utilitare

func _check(contract: String, ok: bool, what: String) -> void:
	_checks += 1
	print("  %s [%s] %s" % ["OK  " if ok else "PICA", contract, what])
	if not ok:
		_fails.append("[%s] %s" % [contract, what])
		_failed_contracts[contract] = true


func _on_car_unlocked(car_id: StringName) -> void:
	_announced.append(car_id)


## Save gol pe disc si in memorie, cu config-ul `cfg` (implicit cel real).
func _fresh(cfg: CareerConfig = null) -> void:
	Career.leave()
	Career.config = cfg if cfg != null else _real_config
	if FileAccess.file_exists(_career_path):
		DirAccess.remove_absolute(_career_path)
	Career.load_progress()
	Career.last_unlocked_cars.clear()
	GameState.dev_unlock_all_cars = false
	_announced.clear()


## Copie in memorie a config-ului real: lumile si provocarile pe aceleasi
## referinte (nu se ating), listele de masini copiate ca sa poata fi sabotate.
func _clone_config() -> CareerConfig:
	var out := CareerConfig.new()
	out.worlds = _real_config.worlds.duplicate()
	out.challenges = _real_config.challenges.duplicate()
	out.starting_cars = _real_config.starting_cars.duplicate()
	for src in _real_config.car_rewards:
		var reward := CareerCarReward.new()
		reward.car = src.car
		reward.points = src.points
		out.car_rewards.append(reward)
	return out


func _reward_in(cfg: CareerConfig, car_id: StringName) -> CareerCarReward:
	for reward in cfg.car_rewards:
		if reward.car == car_id:
			return reward
	return null


func _car_index(car_id: StringName) -> int:
	return SaveSchema.index_of(GameState.CAR_DATA, car_id)


func _car_id(index: int) -> StringName:
	return (GameState.CAR_DATA[index] as CarData).id


func _locked_count() -> int:
	var count := 0
	for res in GameState.CAR_DATA:
		if not Career.is_car_unlocked((res as CarData).id):
			count += 1
	return count


func _disk_garage() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(_career_path) != OK:
		return ["<lipsa>"]
	return Array(cfg.get_value("garage", "unlocked", []))


func _collect(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		out.append(child)
		_collect(child, out)


## O cursa de cariera completa pe pista `track`, terminata pe locul `place`.
func _race(track: StringName, place: int) -> int:
	Career.start_track(track, Career.Mode.RACE)
	return Career.finish_active(place)


# -------------------------------------------------------------- 1. save gol

func _check_fresh() -> void:
	var cfg := _real_config
	if _sabotage == "start":
		cfg = _clone_config()
		cfg.car_rewards.erase(_reward_in(cfg, &"hotrod"))
	_fresh(cfg)
	_check("1", Career.garage_unlocked().is_empty(), "save gol: nicio masina zavorata")
	_check("1", Career.config.starting_cars.size() >= 1
		and Career.config.starting_cars[0] == &"taxi",
		"garajul de start incepe cu Taxi (masina de rezerva a unui jucator nou)")
	var open: Array[StringName] = []
	for res in GameState.CAR_DATA:
		var car_id := (res as CarData).id
		if Career.is_car_unlocked(car_id):
			open.append(car_id)
		var accounted := Career.config.starting_cars.has(car_id) \
			or Career.car_reward_for(car_id) != null
		_check("1", accounted, "%s e de start sau recompensa in config-ul real" % car_id)
	var expected: Array[StringName] = []
	for car_id in Career.config.starting_cars:
		expected.append(car_id)
	open.sort()
	expected.sort()
	_check("1", open == expected, "deschise pe save gol = exact masinile de start (%s)"
		% ", ".join(open))
	for reward in Career.config.car_rewards:
		_check("1", not Career.is_car_unlocked(reward.car),
			"%s (la %d puncte) incuiata pe save gol" % [reward.car, reward.points])
	_check("1", Career.config.car_rewards.size() == 8,
		"8 masini de castigat in config-ul real (%d)" % Career.config.car_rewards.size())
	_check("1", Career.earned_car_count() == 2 and Career.garage_size() == 10,
		"pasaportul: 2 / 10 (%d / %d)" % [Career.earned_car_count(), Career.garage_size()])


# ---------------------------------------------------------------- 2. pragul

func _check_threshold() -> void:
	var cfg := _real_config
	if _sabotage == "prag":
		cfg = _clone_config()
		_reward_in(cfg, &"police_sports").points -= 1
	_fresh(cfg)
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	# Pragurile din config-ul REAL: sabotajul muta doar config-ul activ.
	var police := _reward_in(_real_config, &"police_sports").points
	var ambulance := _reward_in(_real_config, &"ambulance").points
	_check("2", ambulance == 3 and police == 6,
		"pragurile reale: Ambulanta 3, Politia 6 (%d, %d)" % [ambulance, police])
	var w := Career.worlds()[0].tracks

	# Locul 1 = 3 puncte: Ambulanta (3) se deschide, Politia (6) nu.
	_race(w[0], 1)
	_check("2", Career.points() == 3, "locul 1 => 3 puncte (%d)" % Career.points())
	_check("2", Career.is_car_unlocked(&"ambulance")
		and Career.last_unlocked_cars == [&"ambulance"] and _announced == [&"ambulance"],
		"la 3 puncte: Ambulanta deschisa, anuntata o data (last %s, semnal %s)"
			% [Career.last_unlocked_cars, _announced])
	# Locul 2 = +2 => 5 = pragul Politiei minus 1.
	_race(w[1], 2)
	_check("2", Career.points() == police - 1, "locul 2 => %d puncte (%d)" % [
		police - 1, Career.points()])
	_check("2", not Career.is_car_unlocked(&"police_sports"),
		"la prag - 1 (%d) Politia e incuiata" % (police - 1))
	_check("2", Career.last_unlocked_cars.is_empty(),
		"cursa fara masina noua: last_unlocked_cars gol (%s)" % str(Career.last_unlocked_cars))
	_check("2", Career.points_missing_for_car(&"police_sports") == 1,
		"Politiei ii lipseste 1 punct (%d)" % Career.points_missing_for_car(&"police_sports"))
	# Locul 3 = +1 => 6 = pragul.
	_announced.clear()
	_race(w[2], 3)
	_check("2", Career.points() == police, "locul 3 => %d puncte (%d)" % [police, Career.points()])
	_check("2", Career.is_car_unlocked(&"police_sports"), "la prag Politia e deschisa")
	_check("2", Career.last_unlocked_cars == [&"police_sports"],
		"last_unlocked_cars = exact Politia (%s)" % str(Career.last_unlocked_cars))
	_check("2", _announced == [&"police_sports"],
		"car_unlocked a sunat o data, pentru Politia (%s)" % str(_announced))
	_check("2", Career.garage_unlocked().has("police_sports"),
		"Politia e in zavor (_garage_unlocked)")
	# Inca o cursa (+1 => 7): Politia nu se mai anunta.
	_announced.clear()
	_race(w[3], 3)
	_check("2", Career.points() == police + 1, "inca un loc 3 => %d (%d)" % [
		police + 1, Career.points()])
	_check("2", _announced.is_empty() and Career.last_unlocked_cars.is_empty(),
		"a doua cursa nu mai anunta Politia (semnal %s, last %s)"
			% [_announced, Career.last_unlocked_cars])
	_check("2", Career.garage_unlocked().count("police_sports") == 1,
		"Politia o singura data in zavor")
	_check("2", started[0] == 4, "4 curse pornite prin start_track (%d)" % started[0])
	Career.leave()
	Career.race_starter = Callable()


# ------------------------------------------------------- 3. zavor si disc

func _check_latch() -> void:
	# Continua starea din 2: 7 puncte, Ambulanta + Politia castigate.
	Career.config = _real_config
	var disk_before := _disk_garage()
	_check("3", disk_before.has("ambulance") and disk_before.has("police_sports"),
		"pe disc, [garage] unlocked are Ambulanta si Politia (%s)" % str(disk_before))
	Career.load_progress()
	_check("3", Career.is_car_unlocked(&"police_sports"),
		"dupa reincarcarea de pe disc Politia ramane deschisa")
	_check("3", not Career.is_car_unlocked(&"hotrod"),
		"dupa reincarcare Hot rod (10) ramane incuiata la %d puncte" % Career.points())

	# Pragul ridicat peste punctele curente: masina castigata ramane.
	var raised := _clone_config()
	_reward_in(raised, &"police_sports").points = 30
	Career.config = raised
	if _sabotage == "zavor":
		Career._garage_unlocked.erase("police_sports")
	_check("3", Career.points() < 30 and Career.is_car_unlocked(&"police_sports"),
		"prag ridicat la 30 (puncte %d): Politia ramane deschisa" % Career.points())
	# Si dupa o reincarcare cu pragul ridicat (zavorul vine de pe disc).
	if _sabotage != "zavor":
		Career.load_progress()
	_check("3", Career.is_car_unlocked(&"police_sports"),
		"prag ridicat + reincarcare: Politia ramane deschisa")
	Career.config = _real_config

	# Comutatorul de dezvoltator: totul deschis, nimic scris.
	var memory_before := Career.garage_unlocked().duplicate()
	disk_before = _disk_garage()
	GameState.dev_unlock_all_cars = true
	if _sabotage == "dev":
		for res in GameState.CAR_DATA:
			var id := String((res as CarData).id)
			if not Career._garage_unlocked.has(id):
				Career._garage_unlocked.append(id)
	_check("3", _locked_count() == 0, "comutatorul aprins: nicio masina incuiata (%d)"
		% _locked_count())
	# O scriere a carierei fara puncte noi (bronz peste aur nu schimba nimic).
	Career.set_race_medal(Career.worlds()[0].tracks[0], Career.MEDAL_BRONZE)
	_check("3", _disk_garage() == disk_before,
		"comutatorul aprins: [garage] unlocked pe disc neschimbat (%s -> %s)"
			% [str(disk_before), str(_disk_garage())])
	_check("3", Career.garage_unlocked() == memory_before,
		"comutatorul aprins: zavorul din memorie neschimbat")
	_check("3", not Career.is_car_earned(&"muscle"),
		"comutatorul nu face Muscle castigata (is_car_earned)")
	GameState.dev_unlock_all_cars = false
	_check("3", not Career.is_car_unlocked(&"muscle") and not Career.is_car_unlocked(&"hotrod"),
		"comutatorul stins: Muscle si Hot rod incuiate la loc")
	_check("3", Career.is_car_unlocked(&"police_sports") and Career.is_car_unlocked(&"taxi"),
		"comutatorul stins: Politia (castigata) si Taxi (start) raman deschise")
	# Un save cu puncte de dinainte de masini primeste masinile la incarcare.
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", Career.SAVE_VERSION)
	cfg.set_value("track:%s" % Career.worlds()[0].tracks[0], "race_medal", 3)
	cfg.set_value("track:%s" % Career.worlds()[0].tracks[1], "race_medal", 3)
	cfg.save(_career_path)
	_announced.clear()
	Career.load_progress()
	_check("3", Career.points() == 6 and Career.is_car_unlocked(&"police_sports")
		and Career.is_car_unlocked(&"ambulance"),
		"save vechi cu 6 puncte: Ambulanta si Politia zavorate la incarcare")
	_check("3", _announced.is_empty(), "zavorul de la incarcare nu anunta nimic (%s)" % str(_announced))
	_check("3", _disk_garage().has("police_sports"),
		"zavorul de la incarcare e scris pe disc (%s)" % str(_disk_garage()))


# ------------------------------------------------------------ 4. garajul

func _check_garage() -> void:
	_fresh()
	var taxi := _car_index(&"taxi")
	var buggy := _car_index(&"buggy")
	var muscle := _car_index(&"muscle")
	GameState.selected_car = taxi
	var panel := GaragePanel.new()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("4", _visible_locks(panel) == _locked_count() and _locked_count() == 8,
		"lacate vizibile = masini incuiate (%d / %d)" % [_visible_locks(panel), _locked_count()])
	_check("4", _lock_on_card(panel, muscle) and not _lock_on_card(panel, taxi),
		"lacatul sta pe cartonasul Muscle, nu pe Taxi")

	# Masina incuiata: se vede, dar SELECT e stins si refuza.
	panel._show(muscle)
	_check("4", panel._name_label.text == "MUSCLE",
		"Muscle incuiata se vede in panou (%s)" % panel._name_label.text)
	_check("4", panel._select.disabled and panel._select.text == "CAREER: 53 MORE PTS",
		"SELECT pe Muscle: stins, '%s'" % panel._select.text)
	if _sabotage == "garaj":
		GameState.dev_unlock_all_cars = true # garda ocolita
	panel._on_select_pressed()
	GameState.dev_unlock_all_cars = false
	_check("4", GameState.selected_car == taxi,
		"SELECT pe masina incuiata nu schimba selectia (%d, astept %d)"
			% [GameState.selected_car, taxi])
	# Masina deschisa: SELECT o alege.
	panel._show(buggy)
	_check("4", not panel._select.disabled and panel._select.text == "SELECT",
		"SELECT pe Buggy: activ ('%s')" % panel._select.text)
	panel._on_select_pressed()
	_check("4", GameState.selected_car == buggy,
		"SELECT pe masina deschisa o alege (%d, astept %d)" % [GameState.selected_car, buggy])
	_check("4", GaragePanel.locked_select_text(1) == "CAREER: 1 MORE PT",
		"singularul: '%s'" % GaragePanel.locked_select_text(1))

	# Un punct castigat reimprospateaza lacatele (progress_changed).
	Career.set_race_medal(Career.worlds()[0].tracks[0], Career.MEDAL_GOLD)
	_check("4", _visible_locks(panel) == 7 and not _lock_on_card(panel, _car_index(&"ambulance")),
		"dupa 3 puncte: Ambulanta fara lacat, 7 lacate (%d)" % _visible_locks(panel))
	panel._show(_car_index(&"police_sports"))
	_check("4", panel._select.text == "CAREER: 3 MORE PTS",
		"SELECT pe Politia la 3 puncte: '%s'" % panel._select.text)

	# Comutatorul ascuns: 4 atingeri reale (mouse + atingerea emulata) nu comuta.
	panel._dev_taps.clear()
	for i in 4:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		panel._on_title_input(mouse)
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		panel._on_title_input(touch)
		if _sabotage == "dublu":
			panel._register_title_tap(Time.get_ticks_msec())
	_check("4", not GameState.dev_unlock_all_cars,
		"4 atingeri (cu evenimentul emulat) nu aprind comutatorul")
	# 7 atingeri rare (1 s intre ele, 6 s in total) nu comuta.
	panel._dev_taps.clear()
	var toggled := false
	for i in 7:
		toggled = panel._register_title_tap(100000 + i * 1000) or toggled
	_check("4", not toggled and not GameState.dev_unlock_all_cars,
		"7 atingeri in 6 s nu comuta")
	# 7 atingeri in 3 s comuta: titlul o spune, lacatele dispar, se salveaza.
	panel._dev_taps.clear()
	toggled = false
	for i in 7:
		toggled = panel._register_title_tap(200000 + i * 400)
	var settings := ConfigFile.new()
	settings.load(_settings_path)
	_check("4", toggled and GameState.dev_unlock_all_cars
		and bool(settings.get_value("debug", "unlock_all_cars", false)),
		"7 atingeri in 2,4 s aprind comutatorul si il salveaza")
	_check("4", panel._title.text == "GARAGE · ALL CARS" and _visible_locks(panel) == 0,
		"aprins: titlul '%s', %d lacate" % [panel._title.text, _visible_locks(panel)])
	panel._show(muscle)
	panel._on_select_pressed()
	_check("4", GameState.selected_car == muscle, "aprins: Muscle se poate alege")
	# Stins cu Muscle (necastigata) selectata: selectia cade pe Taxi.
	panel._dev_taps.clear()
	for i in 7:
		panel._register_title_tap(300000 + i * 400)
	_check("4", not GameState.dev_unlock_all_cars and panel._title.text == "GARAGE",
		"inca 7 atingeri sting comutatorul ('%s')" % panel._title.text)
	_check("4", GameState.selected_car == taxi,
		"stins cu Muscle selectata: selectia trece pe Taxi (%d)" % GameState.selected_car)
	settings = ConfigFile.new()
	settings.load(_settings_path)
	_check("4", String(settings.get_value("game", "car", "")) == "taxi"
			and not bool(settings.get_value("debug", "unlock_all_cars", true)),
		"stins: Taxi si comutatorul stins ajung pe disc ('%s')"
			% settings.get_value("game", "car", ""))
	_check("4", _visible_locks(panel) == _locked_count(),
		"stins: lacatele inapoi (%d / %d)" % [_visible_locks(panel), _locked_count()])
	panel.queue_free()
	await get_tree().process_frame


func _locks_of(panel: GaragePanel) -> Array[Node]:
	var all: Array[Node] = []
	_collect(panel, all)
	return all.filter(func(n: Node) -> bool: return n is GaragePanel.LockMark)


func _visible_locks(panel: GaragePanel) -> int:
	var count := 0
	for lock in _locks_of(panel):
		if (lock as Control).is_visible_in_tree():
			count += 1
	return count


func _lock_on_card(panel: GaragePanel, index: int) -> bool:
	for child in panel._cards[index].get_children():
		if child is GaragePanel.LockMark:
			return (child as Control).visible
	return false


# ------------------------------------------------ 5. ensure_selected_car

func _check_ensure() -> void:
	var cfg := _real_config
	if _sabotage == "ordine":
		cfg = _clone_config()
		cfg.starting_cars.reverse()
	_fresh(cfg)
	var taxi := _car_index(&"taxi")
	var buggy := _car_index(&"buggy")
	GameState.selected_car = _car_index(&"muscle")
	if FileAccess.file_exists(_settings_path):
		DirAccess.remove_absolute(_settings_path)
	Career.ensure_selected_car()
	if _sabotage == "scrie":
		GameState.save_settings()
	_check("5", GameState.selected_car == taxi,
		"Muscle incuiata -> prima masina de start, Taxi (%s)" % _car_id(GameState.selected_car))
	_check("5", not FileAccess.file_exists(_settings_path),
		"ensure_selected_car nu scrie setarile pe disc")
	GameState.selected_car = buggy
	Career.ensure_selected_car()
	_check("5", GameState.selected_car == buggy, "Buggy (deschisa) ramane selectata")
	# O masina castigata ramane si ea.
	Career.set_race_medal(Career.worlds()[0].tracks[0], Career.MEDAL_GOLD)
	GameState.selected_car = _car_index(&"ambulance")
	Career.ensure_selected_car()
	_check("5", GameState.selected_car == _car_index(&"ambulance"),
		"Ambulanta (castigata) ramane selectata")
	Career.config = _real_config


# ------------------------------------------------------------ 6. validate()

func _check_validate() -> void:
	var real := Career.validate(_real_config)
	_check("6", real.is_empty(), "config-ul real e curat (%s)" % ", ".join(real))
	_check("6", Career.validate(_clone_config()).is_empty(), "clona nesabotata e curata")
	var empty := Career.validate(CareerConfig.new())
	_check("6", empty.size() == 1 and "free" in empty[0],
		"CareerConfig.new(): doar problema lumii free (%s)" % ", ".join(empty))

	# [regula, cuvintele care trebuie sa apara in singura problema raportata]
	var cases: Array = [
		["start inexistent", ["masina de start", "masina_fantoma"]],
		["recompensa inexistenta", ["recompensa", "masina_fantoma"]],
		["si start si recompensa", ["ambulance", "si de start si recompensa"]],
		["doua recompense", ["doua recompense", "hotrod"]],
		["points < 1", ["bus", "points"]],
		["recompense fara start", ["starting_cars e gol"]],
	]
	for case in cases:
		var cfg := _clone_config()
		if _sabotage != "validare":
			_mutate(String(case[0]), cfg)
		var problems := Career.validate(cfg)
		var hit := problems.size() == 1
		for word in case[1]:
			hit = hit and String(word) in problems[0]
		_check("6", hit, "%s -> exact problema ei (%s)" % [case[0], ", ".join(problems)])


## Sabotajul in memorie al unei reguli din `Career._validate_cars`.
func _mutate(rule: String, c: CareerConfig) -> void:
	match rule:
		"start inexistent":
			c.starting_cars.append(&"masina_fantoma")
		"recompensa inexistenta":
			c.car_rewards[0].car = &"masina_fantoma"
		"si start si recompensa":
			c.starting_cars.append(&"ambulance")
		"doua recompense":
			var dup := CareerCarReward.new()
			dup.car = &"hotrod"
			dup.points = 12
			c.car_rewards.append(dup)
		"points < 1":
			_reward_in(c, &"bus").points = 0
		"recompense fara start":
			c.starting_cars.clear()


# --------------------------------------------------------------- 7. textele

func _check_texts() -> void:
	_fresh()
	var w := Career.worlds()[0].tracks
	var panel := CareerPanel.new()
	add_child(panel)
	await get_tree().process_frame
	_check("7", panel._next_car_label.text == "NEXT CAR  AMBULANTA  ·  3 MORE POINTS",
		"pasaport, save gol: '%s'" % panel._next_car_label.text)
	_check("7", panel._cars_label.text == "CARS  2 / 10",
		"pasaport, save gol: '%s'" % panel._cars_label.text)
	# 5 puncte (aur + argint): urmeaza Politia, la 1 punct.
	Career.set_race_medal(w[0], Career.MEDAL_GOLD)
	Career.set_race_medal(w[1], Career.MEDAL_SILVER)
	_check("7", panel._next_car_label.text == "NEXT CAR  POLITIA  ·  1 MORE POINT",
		"pasaport la 5 puncte: '%s'" % panel._next_car_label.text)
	_check("7", panel._cars_label.text == "CARS  3 / 10",
		"pasaport la 5 puncte: '%s'" % panel._cars_label.text)
	# Comutatorul nu minte pasaportul: progresul real ramane.
	GameState.dev_unlock_all_cars = true
	panel._refresh()
	_check("7", "POLITIA" in panel._next_car_label.text and panel._cars_label.text == "CARS  3 / 10",
		"comutatorul aprins nu schimba pasaportul ('%s', '%s')"
			% [panel._next_car_label.text, panel._cars_label.text])
	GameState.dev_unlock_all_cars = false
	panel.queue_free()

	# Rezultatele: o cursa care trece pragul Politiei (5 -> 6).
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	_race(w[2], 3)
	if _sabotage == "text":
		Career.last_unlocked_cars.clear()
	var banner := Race.new_cars_text(Career.last_unlocked_cars)
	_check("7", banner == "NEW CAR: POLITIA", "randul de rezultate: '%s'" % banner)
	var hud := RaceHUD.new()
	add_child(hud)
	await get_tree().process_frame
	var rows: Array[Dictionary] = [{"name": "1. Tu (Taxi)", "color": Color.WHITE,
		"right": "", "is_player": true}]
	hud.show_results("RESULTS — TEST\n3RD PLACE +1  =  1 PTS", rows, "BACK TO CAREER", banner)
	var box: VBoxContainer = hud.get("_results_box")
	var label := box.get_node_or_null("NewCarLabel") as Label
	_check("7", label != null and label.visible and "POLITIA" in label.text,
		"eticheta NewCarLabel din RaceHUD arata Politia ('%s')"
			% (label.text if label != null else "<lipsa>"))
	_check("7", box.get_child(0) is Label and box.get_child(1) == label,
		"titlul ramane pe pozitia 0, randul masinii imediat sub el")
	# Fara masina noua: niciun rand in plus (cursa rapida, cupa, contratimp).
	hud.show_results("RESULTS — TEST", rows, "RESTART")
	_check("7", box.get_node_or_null("NewCarLabel") == null,
		"fara masina noua panoul nu are randul NEW CAR")
	_check("7", Race.new_cars_text([&"hotrod", &"tow_truck"]) == "NEW CAR: HOT ROD\nNEW CAR: MACARAUA",
		"doua praguri odata: doua randuri ('%s')"
			% Race.new_cars_text([&"hotrod", &"tow_truck"]).replace("\n", " | "))
	hud.queue_free()
	Career.leave()
	Career.race_starter = Callable()
	await get_tree().process_frame


# ---------------------------------------------------------------- final

func _restore() -> void:
	if Career.car_unlocked.is_connected(_on_car_unlocked):
		Career.car_unlocked.disconnect(_on_car_unlocked)
	Career.leave()
	Career.race_starter = Callable()
	Career.config = _real_config
	Career.save_path = _real_save_path
	GameState.settings_path = _real_settings_path
	GameState.selected_car = _real_selected_car
	GameState.selected_track = _real_selected_track
	GameState.dev_unlock_all_cars = _real_dev
	# Memoria carierei ramane cea a sondei: procesul se inchide imediat, iar un
	# `load_progress` pe calea reala ar putea scrie (zavorul de la incarcare).
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
		printerr("probe_car_unlock: ", f)
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
