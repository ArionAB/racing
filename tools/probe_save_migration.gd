extends Node
## Garda save-ului versionat (#690): id-uri stabile, migrarea v0 -> v1, copia de
## siguranta, idempotenta, id-urile dormante, fisierele stricate / goale / mai
## noi, si regresia de fond — o reordonare a garajului sau o redenumire de pista
## nu schimba ce se incarca. Merge HEADLESS.
##
## Rulare:
##   Godot --headless --path . res://tools/ProbeSaveMigration.tscn
##
## NU atinge save-ul real: fixture-urile stau in `user://probe_tmp/save_migration/`
## si GameState / Career sunt redirectionate acolo inainte de orice load facut de
## sonda. Load-ul din `GameState._ready` (autoload, ruleaza INAINTEA sondei) se
## redirectioneaza doar cu variabila de mediu `TOY_RACER_SAVE_DIR`
## (SaveSchema.dir_override) — verify_local.sh o seteaza.
##
## Fixture-urile v0 sunt scrise DE MANA, cu asteptarile lor (index 3 = autobuz,
## "Monument Valley" = monument_valley): asa o tabela inghetata stricata in
## SaveSchema pica aici, in loc sa fie comparata cu ea insasi.

const DIR := "user://probe_tmp/save_migration/"
const MIN_CHECKS := 150

## Ce insemna un index v0 din `[game] selected_car` (CAR_DATA din oct 2026).
const V0_CARS: Array[String] = ["muscle", "police_sports", "taxi", "bus",
	"firetruck", "buggy", "ambulance", "hotrod", "tow_truck", "monster"]
const V0_DRIVERS: Array[String] = ["blue", "red", "yellow", "green"]
## [nume v0 din TRACK_NAMES, id asteptat, ms]. "Alpii" are id dar pista nu mai
## e in joc (dormanta); "Stramtoarea" n-are id deloc (legacy).
const V0_LAPS: Array = [
	["Dunele", "dunele", 41001], ["Okinawa manual", "okinawa_manual", 41002],
	["Transfagarasan", "transfagarasan", 41003], ["Baikal", "baikal", 41004],
	["Stromboli", "stromboli", 41005], ["Chongqing", "chongqing", 41006],
	["Cappadocia", "cappadocia", 41007], ["Serengeti", "serengeti", 41008],
	["Machu Picchu", "machu_picchu", 41009], ["Fiordland", "fiordland", 41010],
	["Jodhpur", "jodhpur", 41011], ["Kyoto", "kyoto", 41012],
	["Monument Valley", "monument_valley", 41013], ["Okinawa", "okinawa", 41014],
	["Ha Long", "halong", 41015], ["Carrara", "track23", 41016],
	["Angkor", "track24", 41017],
]
const ID_FORMAT := "^[a-z][a-z0-9_]*$"

var _fails: Array[String] = []
var _checks: int = 0
var _real_settings: String
var _real_records: String
var _real_career: String
var _real_ghosts: String


func _ready() -> void:
	_real_settings = GameState.settings_path
	_real_records = GameState.records_path
	_real_career = Career.save_path
	_real_ghosts = Career.ghost_dir
	print("probe_save_migration: autoload-ul a citit %s (%s)" % [_real_settings,
		"REDIRECTIONAT" if _real_settings != GameState.SETTINGS_PATH else "calea reala"])
	var keep := _snapshot_state()
	_clean()
	DirAccess.make_dir_recursive_absolute(DIR)
	GameState.settings_path = DIR + "settings.cfg"
	GameState.records_path = DIR + "records.cfg"
	Career.save_path = DIR + "career.cfg"
	Career.ghost_dir = DIR + "ghosts/"

	_check_ids()
	_check_settings_migration()
	_check_records_migration()
	_check_dormant()
	_check_broken_files()
	_check_newer_version()
	_check_reorder_and_rename()
	_check_ghost()

	_clean()
	GameState.settings_path = _real_settings
	GameState.records_path = _real_records
	Career.save_path = _real_career
	Career.ghost_dir = _real_ghosts
	_restore_state(keep)
	_report()


# ------------------------------------------------------------------ utilitare

func _expect(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
		print("  FAIL: ", msg)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) \
		else PackedByteArray()


func _cfg(path: String) -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(path)
	return cfg


func _rm(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _clean() -> void:
	for sub in [DIR + "ghosts/", DIR]:
		var d := DirAccess.open(sub)
		if d == null:
			continue
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR + "ghosts/"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR))


## Starea din memorie pe care sonda o calca (selectia, recordurile, setarile).
func _snapshot_state() -> Dictionary:
	return {"car": GameState.selected_car, "driver": GameState.selected_driver,
		"records": GameState.records.duplicate(),
		"race_records": GameState.race_records.duplicate(),
		"laps": GameState.total_laps, "steer": GameState.steer_sensitivity,
		"sfx": GameState.sfx_volume, "engine": GameState.engine_volume,
		"gfx": GameState.gfx_tier, "haptics": GameState.haptics_enabled,
		"cam": GameState.cam_distance_scale}


func _restore_state(s: Dictionary) -> void:
	GameState.selected_car = s.car
	GameState.selected_driver = s.driver
	GameState.records = s.records
	GameState.race_records = s.race_records
	GameState.total_laps = s.laps
	GameState.steer_sensitivity = s.steer
	GameState.sfx_volume = s.sfx
	GameState.engine_volume = s.engine
	GameState.gfx_tier = s.gfx
	GameState.haptics_enabled = s.haptics
	GameState.cam_distance_scale = s.cam


func _car_id() -> String:
	return String((GameState.CAR_DATA[GameState.selected_car] as CarData).id)


func _driver_id() -> String:
	return String((GameState.DRIVER_DATA[GameState.selected_driver] as DriverData).id)


func _v0_settings(car: int, driver: int) -> String:
	return ("[input]\n\nsteer_sensitivity=1.3\nhaptics=false\n\n[audio]\n\n"
		+ "sfx_volume=0.7\nengine_volume=0.2\n\n[game]\n\nselected_car=%d\n"
		+ "selected_driver=%d\n\n[camera]\n\ndistance_scale=1.2\nheight_scale=1.0\n"
		+ "fov_scale=1.0\nfollow_scale=1.0\n\n[video]\n\ngfx_tier=0\n") % [car, driver]


# ------------------------------------------------------------- A. id-uri

func _check_ids() -> void:
	print("=== A. ID-URI ===")
	var re := RegEx.create_from_string(ID_FORMAT)
	var sets := {
		"masina": GameState.CAR_DATA + [GameState.CAR_DATA_TUKTUK],
		"sofer": GameState.DRIVER_DATA,
	}
	for kind in sets:
		var seen := {}
		for res in sets[kind]:
			var id := String(res.get(&"id"))
			_expect(re.search(id) != null, "%s %s: id '%s' gol sau nu e snake_case"
				% [kind, res.resource_path, id])
			_expect(not seen.has(id), "%s: id dublat '%s'" % [kind, id])
			seen[id] = true
		print("  %s: %d id-uri unice" % [kind, seen.size()])
	var tracks := {}
	for i in GameState.TRACK_SCENES.size():
		var id := GameState.track_key(i)
		_expect(re.search(id) != null, "pista %d: id '%s' nu e snake_case" % [i, id])
		_expect(not tracks.has(id), "pista: id dublat '%s'" % id)
		tracks[id] = true
	print("  piste: %d id-uri unice" % tracks.size())


# ----------------------------------------------- B. settings v0 -> v1

func _check_settings_migration() -> void:
	print("=== B. SETTINGS v0 -> v1 ===")
	var path := GameState.settings_path
	var bak := path + ".bak-v0"
	for i in V0_CARS.size():
		_rm(bak)
		var fixture := _v0_settings(i, i % V0_DRIVERS.size())
		_write(path, fixture)
		GameState.selected_car = 0
		GameState.selected_driver = 0
		GameState.load_settings()
		_expect(_car_id() == V0_CARS[i], "selected_car=%d (v0) -> %s, nu %s"
			% [i, V0_CARS[i], _car_id()])
		_expect(_driver_id() == V0_DRIVERS[i % V0_DRIVERS.size()],
			"selected_driver=%d (v0) -> %s, nu %s" % [i % V0_DRIVERS.size(),
			V0_DRIVERS[i % V0_DRIVERS.size()], _driver_id()])
		_expect(_bytes(bak) == fixture.to_utf8_buffer(),
			"masina %d: copia .bak-v0 lipseste sau nu e fisierul vechi neatins" % i)
		var cfg := _cfg(path)
		_expect(int(cfg.get_value("meta", "version", 0)) == SaveSchema.SETTINGS_VERSION,
			"masina %d: fisierul migrat n-are [meta] version" % i)
		_expect(String(cfg.get_value("game", "car", "")) == V0_CARS[i],
			"masina %d: pe disc car='%s'" % [i, cfg.get_value("game", "car", "")])
		_expect(not cfg.has_section_key("game", "selected_car"),
			"masina %d: indexul vechi a ramas pe disc" % i)
	# Restul setarilor trec neatinse.
	_expect(is_equal_approx(GameState.steer_sensitivity, 1.3), "steer_sensitivity pierdut")
	_expect(is_equal_approx(GameState.sfx_volume, 0.7), "sfx_volume pierdut")
	_expect(is_equal_approx(GameState.engine_volume, 0.2), "engine_volume pierdut")
	_expect(is_equal_approx(GameState.cam_distance_scale, 1.2), "distance_scale pierdut")
	_expect(GameState.gfx_tier == 0, "gfx_tier pierdut")
	_expect(not GameState.haptics_enabled, "haptics pierdut")
	# Idempotenta: a doua (si a treia) incarcare nu mai scrie nimic.
	var after_first := _bytes(path)
	var bak_first := _bytes(bak)
	for k in 2:
		GameState.load_settings()
	_expect(_bytes(path) == after_first, "a doua migrare a rescris settings.cfg")
	_expect(_bytes(bak) == bak_first, "a doua migrare a atins copia .bak-v0")
	_expect(_car_id() == V0_CARS[V0_CARS.size() - 1], "a doua incarcare a schimbat masina")
	var cfg2 := ConfigFile.new()
	_expect(SaveSchema.open(path, &"settings", cfg2) == SaveSchema.Status.CURRENT,
		"fisierul migrat nu mai e vazut ca versiunea curenta")
	# Round-trip prin save.
	GameState.selected_car = SaveSchema.index_of(GameState.CAR_DATA, &"buggy")
	GameState.selected_driver = SaveSchema.index_of(GameState.DRIVER_DATA, &"green")
	GameState.save_settings()
	GameState.selected_car = 0
	GameState.selected_driver = 0
	GameState.load_settings()
	_expect(_car_id() == "buggy" and _driver_id() == "green",
		"save + load: %s/%s in loc de buggy/green" % [_car_id(), _driver_id()])
	_rm(bak)


# ------------------------------------------------ C. records v0 -> v1

func _v0_records() -> String:
	var text := "[records]\n\n"
	for row in V0_LAPS:
		text += "%s=%d\n" % [_key(row[0]), row[2]]
	text += "Alpii=39999\nStramtoarea=38888\n\n[race_records]\n\n"
	text += "Dunele@3=130000\nDunele@1=44000\n\"Monument Valley@5\"=290000\n"
	text += "Stramtoarea@3=120000\n"
	return text


## Cheile cu spatiu se scriu intre ghilimele (ca ConfigFile).
func _key(name: String) -> String:
	return "\"%s\"" % name if name.contains(" ") else name


func _check_records_migration() -> void:
	print("=== C. RECORDS v0 -> v1 ===")
	var path := GameState.records_path
	var bak := path + ".bak-v0"
	var fixture := _v0_records()
	_write(path, fixture)
	GameState.load_records()
	_expect(_bytes(bak) == fixture.to_utf8_buffer(), "records.bak-v0 lipseste sau nu e neatins")
	var found := 0
	for row in V0_LAPS:
		var index := TrackInfo.index_of_id(StringName(row[1]))
		_expect(index >= 0, "pista %s (%s) nu mai e in TRACK_SCENES" % [row[0], row[1]])
		if index < 0:
			continue
		found += 1
		_expect(GameState.best_lap(index) == row[2], "%s: best lap %d dupa migrare, nu %d"
			% [row[0], GameState.best_lap(index), row[2]])
	print("  %d recorduri de tur regasite pe id" % found)
	var dunes := TrackInfo.index_of_id(&"dunele")
	var mv := TrackInfo.index_of_id(&"monument_valley")
	GameState.total_laps = 3
	_expect(GameState.best_race(dunes) == 130000, "Dunele@3 pierdut (%d)" % GameState.best_race(dunes))
	GameState.total_laps = 1
	_expect(GameState.best_race(dunes) == 44000, "Dunele@1 pierdut")
	GameState.total_laps = 5
	_expect(GameState.best_race(mv) == 290000, "Monument Valley@5 pierdut")
	GameState.total_laps = 3
	_expect(int(GameState.records.get("alpi", 0)) == 39999, "Alpii: recordul dormant (alpi) pierdut")
	var cfg := _cfg(path)
	_expect(int(cfg.get_value("meta", "version", 0)) == SaveSchema.RECORDS_VERSION,
		"records.cfg migrat n-are [meta] version")
	_expect(int(cfg.get_value("legacy_records", "Stramtoarea", 0)) == 38888,
		"Stramtoarea (fara id) n-a ajuns in legacy_records")
	_expect(int(cfg.get_value("legacy_race_records", "Stramtoarea@3", 0)) == 120000,
		"Stramtoarea@3 n-a ajuns in legacy_race_records")
	for row in V0_LAPS:
		_expect(not cfg.has_section_key("records", row[0]) or row[0] == row[1],
			"numele vechi '%s' a ramas cheie in [records]" % row[0])
	# Idempotenta.
	var after_first := _bytes(path)
	GameState.load_records()
	GameState.load_records()
	_expect(_bytes(path) == after_first, "a doua migrare a rescris records.cfg")
	_expect(_bytes(bak) == fixture.to_utf8_buffer(), "a doua migrare a atins records.bak-v0")
	_expect(GameState.best_lap(mv) == 41013, "a doua incarcare a schimbat recordul")
	# Un record nou se salveaza langa cele vechi, fara sa le stearga.
	_expect(GameState.try_record(dunes, 40000), "try_record nu bate 41001 cu 40000")
	var cfg2 := _cfg(path)
	_expect(int(cfg2.get_value("records", "dunele", 0)) == 40000, "recordul nou nu e pe disc")
	_expect(int(cfg2.get_value("records", "monument_valley", 0)) == 41013,
		"save_records a pierdut un record vechi")
	_expect(int(cfg2.get_value("records", "alpi", 0)) == 39999,
		"save_records a pierdut recordul dormant (alpi)")
	_expect(int(cfg2.get_value("legacy_records", "Stramtoarea", 0)) == 38888,
		"save_records a pierdut legacy_records")
	_rm(bak)


# --------------------------------------------------- D. id-uri dormante

func _check_dormant() -> void:
	print("=== D. ID NECUNOSCUT, DORMANT ===")
	var sp := GameState.settings_path
	_write(sp, "[meta]\n\nversion=1\n\n[game]\n\ncar=\"hovercraft\"\ndriver=\"purple\"\n")
	GameState.selected_car = 5
	GameState.selected_driver = 3
	GameState.load_settings()
	_expect(GameState.selected_car == 0 and GameState.selected_driver == 0,
		"masina/sofer necunoscut: selectia nu a cazut pe 0 (%d/%d)"
		% [GameState.selected_car, GameState.selected_driver])
	GameState.save_settings()
	var cfg := _cfg(sp)
	_expect(String(cfg.get_value("game", "car", "")) == "hovercraft",
		"load + save a sters masina necunoscuta (%s)" % cfg.get_value("game", "car", ""))
	_expect(String(cfg.get_value("game", "driver", "")) == "purple",
		"load + save a sters soferul necunoscut")
	GameState.selected_car = SaveSchema.index_of(GameState.CAR_DATA, &"taxi")
	GameState.save_settings()
	_expect(String(_cfg(sp).get_value("game", "car", "")) == "taxi",
		"dupa o alegere noua, masina dormanta nu face loc celei alese")

	var rp := GameState.records_path
	_write(rp, "[meta]\n\nversion=1\n\n[records]\n\natlantis=12345\n\n[race_records]\n\n"
		+ "atlantis@3=50000\n")
	GameState.load_records()
	var ok := TrackInfo.index_of_id(&"kyoto")
	GameState.try_record(ok, 33333)
	var cfg2 := _cfg(rp)
	_expect(int(cfg2.get_value("records", "atlantis", 0)) == 12345,
		"pista necunoscuta: recordul de tur nu a supravietuit load + save")
	_expect(int(cfg2.get_value("race_records", "atlantis@3", 0)) == 50000,
		"pista necunoscuta: recordul de cursa nu a supravietuit load + save")
	_expect(int(cfg2.get_value("records", "kyoto", 0)) == 33333, "recordul nou lipseste")


# ------------------------------------------- E. fisiere stricate / goale

func _check_broken_files() -> void:
	print("=== E. FISIERE STRICATE SI GOALE ===")
	var sp := GameState.settings_path
	var rp := GameState.records_path
	var garbage := "[game\nselected_car=\"\u0001 [[[ = = \n"
	for path in [sp, rp]:
		_rm(path + ".corrupt")
		_write(path, garbage)
	GameState.selected_car = 4
	GameState.load_settings() # nu crapa; ramane ce era in memorie
	GameState.load_records()
	_expect(GameState.selected_car == 4, "settings stricat a schimbat selectia")
	_expect(GameState.records.is_empty(), "records stricat a produs recorduri")
	for path in [sp, rp]:
		_expect(_bytes(path + ".corrupt") == garbage.to_utf8_buffer(),
			"%s stricat nu a fost pastrat in .corrupt" % path.get_file())
	GameState.save_settings()
	GameState.try_record(TrackInfo.index_of_id(&"dunele"), 50000)
	_expect(int(_cfg(sp).get_value("meta", "version", 0)) == SaveSchema.SETTINGS_VERSION,
		"dupa un settings stricat, save-ul nu scrie un v1 valid")
	_expect(int(_cfg(rp).get_value("records", "dunele", 0)) == 50000,
		"dupa un records stricat, recordul nou nu se scrie")
	# Gol: e un v0 fara nimic in el.
	for path in [sp, rp]:
		_write(path, "")
	GameState.selected_car = 0
	GameState.load_settings()
	GameState.load_records()
	_expect(GameState.selected_car == 0, "settings gol: selectia nu e 0")
	_expect(GameState.records.is_empty(), "records gol: au aparut recorduri")
	_expect(int(_cfg(sp).get_value("meta", "version", 0)) == SaveSchema.SETTINGS_VERSION,
		"settings gol nu a devenit v1")
	for path in [sp, rp]:
		_rm(path + ".corrupt")
		_rm(path + ".bak-v0")


# ------------------------------------------------ F. versiune mai noua

func _check_newer_version() -> void:
	print("=== F. VERSIUNE MAI NOUA ===")
	var sp := GameState.settings_path
	var rp := GameState.records_path
	var newer_s := "[meta]\n\nversion=99\n\n[game]\n\ncar=\"taxi\"\n\n[audio]\n\nsfx_volume=0.1\n"
	var newer_r := "[meta]\n\nversion=99\n\n[records]\n\ndunele=1\n"
	_write(sp, newer_s)
	_write(rp, newer_r)
	GameState.selected_car = 0
	GameState.load_settings()
	GameState.load_records()
	GameState.save_settings()
	GameState.try_record(TrackInfo.index_of_id(&"kyoto"), 1000)
	_expect(_bytes(sp) == newer_s.to_utf8_buffer(), "settings v99 suprascris")
	_expect(_bytes(rp) == newer_r.to_utf8_buffer(), "records v99 suprascris")
	_expect(not FileAccess.file_exists(sp + ".bak-v99") and not FileAccess.file_exists(sp + ".bak-v0"),
		"v99 a fost tratat ca o migrare")
	# Inapoi la normal: un fisier curent deblocheaza scrierea.
	_rm(sp)
	_rm(rp)
	GameState.load_settings()
	GameState.load_records()
	GameState.save_settings()
	_expect(FileAccess.file_exists(sp), "dupa v99 + fisier lipsa, save-ul ramane blocat")


# -------------------------------------- G. reordonare si redenumire

func _check_reorder_and_rename() -> void:
	print("=== G. REORDONARE GARAJ, REDENUMIRE PISTA ===")
	var sp := GameState.settings_path
	# Garajul inversat (simulat): ce se scrie pentru masina i trebuie sa se
	# citeasca drept ACEEASI resursa din lista reordonata. Un save pe index ar
	# da aici masina de pe pozitia oglindita.
	var reordered: Array = GameState.CAR_DATA.duplicate()
	reordered.reverse()
	var drivers_reordered: Array = GameState.DRIVER_DATA.duplicate()
	drivers_reordered.reverse()
	for i in GameState.CAR_DATA.size():
		GameState.selected_car = i
		GameState.selected_driver = i % GameState.DRIVER_DATA.size()
		GameState.save_settings()
		var cfg := _cfg(sp)
		var j := SaveSchema.index_of(reordered, StringName(cfg.get_value("game", "car", "")))
		_expect(j >= 0 and reordered[j] == GameState.CAR_DATA[i],
			"garaj reordonat: masina %d (%s) se incarca drept %s" % [i,
			GameState.CAR_DATA[i].resource_path.get_file(),
			reordered[j].resource_path.get_file() if j >= 0 else "nimic"])
		var k := SaveSchema.index_of(drivers_reordered,
			StringName(cfg.get_value("game", "driver", "")))
		_expect(k >= 0 and drivers_reordered[k] == GameState.DRIVER_DATA[GameState.selected_driver],
			"soferi reordonati: soferul %d se incarca altfel" % GameState.selected_driver)
	# Pe disc nu exista niciun index: doar id-uri.
	var cfg2 := _cfg(sp)
	_expect(cfg2.get_value("game", "car", null) is String, "pe disc masina nu e un id (text)")
	# Redenumirea pistei (#673), simulata pe resursa incarcata: numele de afis
	# se schimba, recordul ramane.
	var mv := TrackInfo.index_of_id(&"monument_valley")
	var info := TrackInfo.for_track(mv)
	var old_name := info.display_name
	GameState.records.clear()
	GameState.race_records.clear()
	GameState.total_laps = 3
	GameState.try_record(mv, 45678)
	GameState.try_race_record(mv, 145678)
	info.display_name = "Navajo Mesa"
	GameState.load_records()
	_expect(GameState.best_lap(mv) == 45678, "redenumire: best lap pierdut (%d)" % GameState.best_lap(mv))
	_expect(GameState.best_race(mv) == 145678, "redenumire: best race pierdut")
	info.display_name = old_name
	# TRACK_NAMES e const (read-only la rulare); ce se poate verifica e ca nicio
	# cheie de pe disc nu e un nume din lista, deci o redenumire acolo n-are ce atinge.
	var on_disk := _cfg(GameState.records_path)
	for section in ["records", "race_records"]:
		for key: String in on_disk.get_section_keys(section):
			var base := key.substr(0, key.rfind("@")) if key.contains("@") else key
			_expect(not (base in GameState.TRACK_NAMES),
				"cheia '%s' din %s e un nume din TRACK_NAMES" % [key, section])
	_expect(on_disk.has_section_key("records", "monument_valley"),
		"recordul lui Monument Valley nu e pe id")


# ------------------------------------------------------------- H. fantome

func _check_ghost() -> void:
	print("=== H. FANTOMA (v1 pe index -> v2 pe id) ===")
	var samples := PackedFloat32Array([0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1])
	# v1 scris de mana: index 3 = autobuzul in ordinea v0.
	var buf := StreamPeerBuffer.new()
	buf.put_32(1)
	buf.put_utf8_string("kyoto")
	buf.put_32(3)
	buf.put_32(3)
	buf.put_32(20)
	buf.put_32(61000)
	buf.put_32(2)
	buf.put_data(samples.to_byte_array())
	var v1 := GhostData.from_bytes(buf.data_array)
	_expect(v1 != null, "fantoma v1 nu se mai citeste")
	if v1 != null:
		_expect(String(v1.car_id) == "bus", "fantoma v1 index 3 -> %s, nu bus" % v1.car_id)
		_expect(v1.car_index >= 0 and GameState.CAR_DATA[v1.car_index].resource_path.ends_with(
			"bus.tres"), "fantoma v1: car_index nu e autobuzul")
		var v2 := GhostData.from_bytes(v1.to_bytes())
		_expect(v2 != null and String(v2.car_id) == "bus" and v2.total_ms == 61000
			and v2.sample_count() == 2, "fantoma v1 -> v2 -> citire: s-a pierdut ceva")
		_expect(GhostData.file_version(v1.to_bytes()) == GhostData.VERSION,
			"fantoma se scrie tot in versiunea veche")
	# Masina scoasa din joc: fantoma se incarca, iar id-ul se scrie inapoi.
	var ghost := GhostData.new()
	ghost.track_id = &"kyoto"
	ghost.car_index = -1
	ghost.car_id = &"hovercraft"
	ghost.samples = samples
	var back := GhostData.from_bytes(ghost.to_bytes())
	_expect(back != null and back.car_index == -1 and String(back.car_id) == "hovercraft",
		"fantoma cu masina necunoscuta nu supravietuieste load + save")
	if back != null:
		var again := GhostData.from_bytes(back.to_bytes())
		_expect(again != null and String(again.car_id) == "hovercraft",
			"a doua scriere a pierdut masina necunoscuta")


func _report() -> void:
	_expect(_checks >= MIN_CHECKS, "au rulat doar %d verificari (< %d)" % [_checks, MIN_CHECKS])
	print("verificari: %d, esecuri: %d" % [_checks, _fails.size()])
	print("VERDICT: ", "OK" if _fails.is_empty() else "PROBLEMA (%d)" % _fails.size())
	get_tree().quit(0 if _fails.is_empty() else 1)
