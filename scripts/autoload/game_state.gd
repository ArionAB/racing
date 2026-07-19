extends Node
## Singleton (autoload): stare globala intre scene, puntea touch, setari
## persistate, garaj (masina aleasa) si starea campionatului.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const MENU_SCENE: String = "res://scenes/main_menu/MainMenu.tscn"
const SETTINGS_PATH: String = "user://settings.cfg"
const RECORDS_PATH: String = "user://records.cfg"

## Garajul: toate masinile jucabile. O masina noua = un .tres nou aici.
## Modele: Free Low Poly Vehicles Pack de RgsDev (CC0).
const CAR_DATA: Array[Resource] = [
	preload("res://scenes/cars/data/muscle.tres"),
	preload("res://scenes/cars/data/police_sports.tres"),
	preload("res://scenes/cars/data/taxi.tres"),
	preload("res://scenes/cars/data/bus.tres"),
	preload("res://scenes/cars/data/firetruck.tres"),
]

## Pistele. Primele CHAMP_ROUNDS intra in campionat; restul doar in
## cursa rapida (Atelier = pista custom, editabila in editor).
const TRACK_SCENES: Array[String] = [
	"res://scenes/tracks/Track01.tscn",
	"res://scenes/tracks/Track02.tscn",
	"res://scenes/tracks/Track03.tscn",
	"res://scenes/tracks/Track04.tscn",
]
const TRACK_NAMES: Array[String] = ["Dunele", "Serpentina", "Muntele", "Atelier"]
const CHAMP_ROUNDS: int = 3

## Puncte pe pozitie (locul 1..4).
const CHAMP_POINTS: Array[int] = [10, 7, 4, 2]

# Config cursa.
var total_laps: int = 3
var ai_count: int = 3

# Selectii (masina aleasa se persista).
var selected_car: int = 0
var selected_track: int = 0

# Campionat: 3 curse, punctaj cumulat per "slot" (0 = jucatorul, 1..3 = AI).
var champ_active: bool = false
var champ_round: int = 0
var champ_points: Array[int] = [0, 0, 0, 0]

# Setari utilizator (persistate).
var steer_sensitivity: float = 1.0
var sfx_volume: float = 1.0
var engine_volume: float = 1.0

# Puntea touch. Conventia ecranului: -1 = stanga, +1 = dreapta.
var touch_steer: float = 0.0
var touch_drift: bool = false
var touch_turbo: bool = false

# Best lap per pista (index pista -> milisecunde), persistat.
var records: Dictionary = {}

func _ready() -> void:
	load_settings()
	load_records()

## Returneaza true daca timpul e record nou pe pista respectiva.
func try_record(track_index: int, lap_ms: int) -> bool:
	var best := int(records.get(track_index, 0))
	if best > 0 and lap_ms >= best:
		return false
	records[track_index] = lap_ms
	save_records()
	return true

func best_lap(track_index: int) -> int:
	return int(records.get(track_index, 0)) # 0 = niciun record inca

func load_records() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RECORDS_PATH) != OK:
		return
	for i in TRACK_SCENES.size():
		var ms := int(cfg.get_value("records", str(i), 0))
		if ms > 0:
			records[i] = ms

func save_records() -> void:
	var cfg := ConfigFile.new()
	for track_index in records:
		cfg.set_value("records", str(track_index), records[track_index])
	cfg.save(RECORDS_PATH)

# ------------------------------------------------------------------ flux

func start_quick_race(track_index: int) -> void:
	champ_active = false
	selected_track = track_index
	start_race()

func start_championship() -> void:
	champ_active = true
	champ_round = 0
	champ_points = [0, 0, 0, 0]
	selected_track = 0
	start_race()

## order_slots[rank] = slotul de pe locul rank (0 = jucator).
func record_results(order_slots: Array) -> void:
	for rank in order_slots.size():
		champ_points[int(order_slots[rank])] += CHAMP_POINTS[rank]

func champ_is_last_round() -> bool:
	return champ_round >= CHAMP_ROUNDS - 1

func champ_next_race() -> void:
	champ_round += 1
	selected_track = champ_round
	start_race()

func start_race() -> void:
	reset_touch()
	get_tree().change_scene_to_file(RACE_SCENE)

func go_to_menu() -> void:
	champ_active = false
	reset_touch()
	get_tree().change_scene_to_file(MENU_SCENE)

func reset_touch() -> void:
	touch_steer = 0.0
	touch_drift = false
	touch_turbo = false

# ---------------------------------------------------------------- setari

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	steer_sensitivity = float(cfg.get_value("input", "steer_sensitivity", 1.0))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", 1.0))
	engine_volume = float(cfg.get_value("audio", "engine_volume", 1.0))
	selected_car = clampi(int(cfg.get_value("game", "selected_car", 0)),
		0, CAR_DATA.size() - 1)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "steer_sensitivity", steer_sensitivity)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "engine_volume", engine_volume)
	cfg.set_value("game", "selected_car", selected_car)
	cfg.save(SETTINGS_PATH)
