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
## cursa rapida.
const TRACK_SCENES: Array[String] = [
	"res://scenes/tracks/Track01.tscn",
	"res://scenes/tracks/Track05.tscn",
	"res://scenes/tracks/Track06.tscn",
	"res://scenes/tracks/Track07.tscn",
	"res://scenes/tracks/Track08.tscn",
]
const TRACK_NAMES: Array[String] = [
	"Dunele", "Okinawa", "Stramtoarea", "Okinawa v2", "Okinawa manual",
]
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

# Camera: FACTORI peste valorile din ChaseCamera, nu cote absolute.
#
# Asa reglajul jucatorului supravietuieste unei schimbari a camerei de baza (si
# invers: cand tunam camera in cod, nu calcam peste preferinta lui), iar
# scalarea per vehicul — autobuzul sta mai departe decat muscle car-ul — ramane
# intacta: se inmulteste, nu se inlocuieste.
var cam_distance_scale: float = 1.0
var cam_height_scale: float = 1.0
var cam_fov_scale: float = 1.0
## Cat de repede se aseaza camera in spatele masinii. Sub 1.0 = mai lenesa.
var cam_follow_scale: float = 1.0

# Puntea touch. Conventia ecranului: -1 = stanga, +1 = dreapta.
var touch_steer: float = 0.0
var touch_drift: bool = false
var touch_turbo: bool = false

# Best lap per pista (nume pista -> milisecunde), persistat. Cheia e numele,
# nu indexul: la stergerea sau reordonarea unei piste, indexul ramas liber era
# mostenit de alta pista si-i afisa recordul altcuiva.
var records: Dictionary = {}

func _ready() -> void:
	load_settings()
	load_records()

## Returneaza true daca timpul e record nou pe pista respectiva.
func try_record(track_index: int, lap_ms: int) -> bool:
	var key := TRACK_NAMES[track_index]
	var best := int(records.get(key, 0))
	if best > 0 and lap_ms >= best:
		return false
	records[key] = lap_ms
	save_records()
	return true

func best_lap(track_index: int) -> int:
	return int(records.get(TRACK_NAMES[track_index], 0)) # 0 = niciun record inca

func load_records() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RECORDS_PATH) != OK:
		return
	for track_name in TRACK_NAMES:
		var ms := int(cfg.get_value("records", track_name, 0))
		if ms > 0:
			records[track_name] = ms

func save_records() -> void:
	var cfg := ConfigFile.new()
	for track_name in records:
		cfg.set_value("records", track_name, records[track_name])
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
	# Limitele sunt cele ale sliderelor din SettingsPanel: un fisier de setari
	# stricat de mana n-are voie sa scoata camera in alta galaxie.
	cam_distance_scale = clampf(
		float(cfg.get_value("camera", "distance_scale", 1.0)), 0.5, 2.0)
	cam_height_scale = clampf(
		float(cfg.get_value("camera", "height_scale", 1.0)), 0.4, 2.0)
	cam_fov_scale = clampf(
		float(cfg.get_value("camera", "fov_scale", 1.0)), 0.7, 1.3)
	cam_follow_scale = clampf(
		float(cfg.get_value("camera", "follow_scale", 1.0)), 0.4, 2.5)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "steer_sensitivity", steer_sensitivity)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "engine_volume", engine_volume)
	cfg.set_value("game", "selected_car", selected_car)
	cfg.set_value("camera", "distance_scale", cam_distance_scale)
	cfg.set_value("camera", "height_scale", cam_height_scale)
	cfg.set_value("camera", "fov_scale", cam_fov_scale)
	cfg.set_value("camera", "follow_scale", cam_follow_scale)
	cfg.save(SETTINGS_PATH)


## Readuce camera la valorile din cod (ChaseCamera), fara sa atinga restul
## setarilor. Exista ca sa se poata iesi dintr-un reglaj gresit fara stergerea
## fisierului de setari.
func reset_camera_settings() -> void:
	cam_distance_scale = 1.0
	cam_height_scale = 1.0
	cam_fov_scale = 1.0
	cam_follow_scale = 1.0
	save_settings()
