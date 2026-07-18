extends Node
## Singleton (autoload) cu stare globala intre scene, puntea de input touch
## si setarile persistate. Portat din racing 2D.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const MENU_SCENE: String = "res://scenes/main_menu/MainMenu.tscn"
## user:// = folderul de date per utilizator (pe mobil, sandbox-ul aplicatiei).
const SETTINGS_PATH: String = "user://settings.cfg"

# Config cursa.
var total_laps: int = 3
var ai_count: int = 3

# Setari utilizator (persistate).
var steer_sensitivity: float = 1.0 # scaleaza raspunsul la virare (0.6..1.4)
var sfx_volume: float = 1.0
var engine_volume: float = 1.0

# Puntea touch. Conventia ecranului: -1 = stanga, +1 = dreapta.
var touch_steer: float = 0.0
var touch_drift: bool = false

func _ready() -> void:
	load_settings()

func start_race() -> void:
	reset_touch()
	get_tree().change_scene_to_file(RACE_SCENE)

func go_to_menu() -> void:
	reset_touch()
	get_tree().change_scene_to_file(MENU_SCENE)

func reset_touch() -> void:
	touch_steer = 0.0
	touch_drift = false

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return # prima rulare: valorile implicite
	steer_sensitivity = float(cfg.get_value("input", "steer_sensitivity", 1.0))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", 1.0))
	engine_volume = float(cfg.get_value("audio", "engine_volume", 1.0))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "steer_sensitivity", steer_sensitivity)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "engine_volume", engine_volume)
	cfg.save(SETTINGS_PATH)
