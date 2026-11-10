class_name TutorialDirector
extends Node
## Turul ghidat de la prima pornire (#678): masina de stari a indiciilor.
##
## Un indiciu pe ecran odata: viraj -> gaz -> drift -> turbo (ordinea e in
## `TutorialConfig.steps`). Fiecare trece la urmatorul DOAR cand jucatorul a
## facut gestul lui, nu dupa timp. Gestul se citeste din starea REALA a masinii
## si a controller-ului, nu din butoane:
##   - viraj: comanda netezita a controller-ului (`get_steer`), tinuta;
##   - gaz: masina chiar merge (`throttle_input` > 0 si viteza peste prag);
##   - drift: `Car.is_drifting` adunat in timp — DRIFT apasat fara viteza sau
##     fara viraj nu e drift si nu conteaza;
##   - turbo: bara chiar scade cat `is_boosting` — TURBO cu bara goala, sau
##     arderea gratuita a rocket start-ului, nu conteaza.
## Un gest facut inaintea pasului lui nu conteaza (driftul din pasul de viraj
## nu bifeaza driftul).
##
## Race il ataseaza doar cand `GameState.tutorial_run`; tot ce tine de tur sta
## aici si in TutorialOverlay, Race/HUD au doar carlige.

signal step_changed(step: StringName)

const DEFAULT_CONFIG: TutorialConfig = preload("res://scenes/race/tutorial/tutorial_default.tres")
## Butonul din SETTINGS (textul e aici ca sonda sa-l gaseasca dupa el).
const REPLAY_LABEL: String = "REPLAY TUTORIAL"
const STEP_INTRO: StringName = &"intro"
const STEP_DONE: StringName = &"done"
const STEP_SKIPPED: StringName = &"skipped"

## Sondele: in loc de `GameState.start_race()` (care schimba scena si ar
## inchide sonda) / `GameState.go_to_menu()`.
static var launch_override: Callable = Callable()
static var exit_override: Callable = Callable()

var config: TutorialConfig = DEFAULT_CONFIG
var race: Race
var car: Car
var overlay: TutorialOverlay
## intro (numaratoarea), apoi pasii din config, apoi done / skipped.
var step: StringName = STEP_INTRO
## Progresul pasului curent, 0..1 (bara subtire din cartonas).
var progress: float = 0.0

var _step_i: int = -1
var _step_time: float = 0.0
var _went: bool = false
var _steer_left_s: float = 0.0
var _steer_right_s: float = 0.0
var _drift_s: float = 0.0
var _burned: float = 0.0
var _prev_charge: float = 0.0
var _done_left: float = 0.0


## Indexul pistei turului in GameState.TRACK_SCENES (-1 daca lipseste).
static func track_index(cfg: TutorialConfig = DEFAULT_CONFIG) -> int:
	return TrackInfo.index_of_id(cfg.track_id)


## Porneste turul (invitatia de la prima pornire, SETTINGS). Merge si din
## pauza: arborele se dezgheata inainte de schimbarea scenei.
static func start() -> void:
	var idx := track_index()
	if idx < 0:
		push_error("TutorialDirector: pista '%s' nu e in TRACK_SCENES"
			% DEFAULT_CONFIG.track_id)
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.paused = false
	GameState.champ_active = false
	Career.leave()
	GameState.selected_track = idx
	GameState.tutorial_run = true
	if launch_override.is_valid():
		launch_override.call()
	else:
		GameState.start_race()


## Chemat de Race la sfarsitul lui `_setup_race`, cand `GameState.tutorial_run`.
static func attach(r: Race) -> TutorialDirector:
	var d := TutorialDirector.new()
	d.name = "Tutorial"
	r.add_child(d)
	d.setup(r)
	return d


func setup(r: Race) -> void:
	race = r
	car = r.player
	overlay = TutorialOverlay.new()
	overlay.config = config
	r.hud.add_tutorial_overlay(overlay)
	overlay.bind(r.hud.touch_controls(), r.hud.turbo_bar_rect)
	overlay.skip_pressed.connect(skip)
	overlay.continue_pressed.connect(_exit)
	_refresh_overlay()


## Repornire in aceeasi cursa (sonda; pentru jucator, reluarea e o cursa noua).
func restart() -> void:
	_set_step(-1)
	_went = false
	overlay.visible = true
	_refresh_overlay()


func is_finished() -> bool:
	return step == STEP_DONE or step == STEP_SKIPPED


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if step == STEP_SKIPPED:
		return
	if step == STEP_DONE:
		if _done_left > 0.0:
			_done_left -= delta
			if _done_left <= 0.0:
				overlay.hide_card()
		return
	if race == null or race.state != Race.State.RUNNING:
		return
	if not _went:
		# Primul tick dupa GO (Race._go tocmai a umplut bara): pornim de la
		# `start_bar`, ca umplerea din mers sa se vada.
		_went = true
		if config.start_bar >= 0.0 and car.turbo_recharge:
			car.turbo_charge = config.start_bar
		_set_step(0)
		_refresh_overlay()
		return
	# Cat masina e repusa, aruncata sau a terminat, nu conduce nimeni: nimic
	# nu se numara (si nici ceasul de impuns nu curge).
	if car.finished or car.is_recovering() or car.is_ejected:
		_prev_charge = car.turbo_charge
		# Peste rezultate cartonasul n-are ce cauta.
		if car.finished:
			overlay.visible = false
		return
	_step_time += delta
	var sub := ""
	match step:
		&"steer":
			sub = _tick_steer(delta)
		&"gas":
			sub = _tick_gas()
		&"drift":
			sub = _tick_drift(delta)
		&"turbo":
			sub = _tick_turbo()
	if progress >= 1.0:
		_set_step(_step_i + 1)
		sub = ""
	_refresh_overlay(sub)


func _tick_steer(delta: float) -> String:
	# +1 = stanga (conventia controller-ului). Comanda netezita: un tap de o
	# clipa nu ajunge la prag, tinut da.
	var s := car.controller.get_steer() if car.controller != null else 0.0
	if s >= config.steer_threshold:
		_steer_left_s += delta
	elif s <= -config.steer_threshold:
		_steer_right_s += delta
	var need := maxf(config.steer_hold_s, 0.001)
	if config.steer_both_sides:
		progress = (minf(_steer_left_s, need) + minf(_steer_right_s, need)) / (2.0 * need)
	else:
		progress = minf((_steer_left_s + _steer_right_s) / need, 1.0)
	return ""


func _tick_gas() -> String:
	var kmh := car.horizontal_speed() * 3.6
	var need := maxf(config.gas_speed_kmh, 0.1)
	# Viteza conteaza doar cu gazul apasat: la vale, pe inertie, nu e gaz.
	if car.throttle_input > 0.0:
		progress = maxf(progress, minf(kmh / need, 1.0))
	return ""


func _tick_drift(delta: float) -> String:
	if car.is_drifting:
		_drift_s += delta
	progress = minf(_drift_s / maxf(config.drift_required_s, 0.001), 1.0)
	# Butonul tinut fara drift: spunem DE CE nu merge, din starea masinii.
	if car.controller != null and car.controller.is_drift_pressed() and not car.is_drifting:
		if car.horizontal_speed() <= car.drift_min_speed:
			return config.drift_sub_speed
		if absf(car.controller.get_steer()) <= 0.25:
			return config.drift_sub_turn
	return ""


func _tick_turbo() -> String:
	var c := car.turbo_charge
	if car.is_boosting and c < _prev_charge:
		_burned += _prev_charge - c
	_prev_charge = c
	progress = minf(_burned / maxf(config.turbo_burn_required, 0.001), 1.0)
	if not car.is_boosting and c <= car.turbo_min_to_fire:
		return config.turbo_sub_empty
	return ""


## Trece la pasul `i` din config (-1 = intro; dupa ultimul = done).
func _set_step(i: int) -> void:
	_step_i = i
	_step_time = 0.0
	progress = 0.0
	_steer_left_s = 0.0
	_steer_right_s = 0.0
	_drift_s = 0.0
	_burned = 0.0
	_prev_charge = car.turbo_charge if car != null else 0.0
	if i < 0:
		step = STEP_INTRO
	elif i >= config.steps.size():
		_finish()
		return
	else:
		step = config.steps[i]
		if step == &"drift" and config.drift_bar_reset >= 0.0 and car.turbo_recharge:
			car.turbo_charge = config.drift_bar_reset
			_prev_charge = car.turbo_charge
	step_changed.emit(step)


func _finish() -> void:
	step = STEP_DONE
	progress = 1.0
	_done_left = config.done_card_s
	GameState.tutorial_done = true
	GameState.save_settings()
	overlay.show_done()
	step_changed.emit(step)


## SKIP: se termina aici. Starea se salveaza (nu-l mai oferim la pornire;
## se reia din SETTINGS) si ne intoarcem in meniu.
func skip() -> void:
	if is_finished():
		return
	step = STEP_SKIPPED
	GameState.tutorial_done = true
	GameState.save_settings()
	overlay.visible = false
	step_changed.emit(step)
	_exit()


func _exit() -> void:
	if exit_override.is_valid():
		exit_override.call()
	else:
		GameState.go_to_menu()


func _refresh_overlay(sub: String = "") -> void:
	if overlay == null or is_finished():
		return
	var nudge := step != STEP_INTRO and _step_time >= config.nudge_after_s
	overlay.show_step(step, maxi(_step_i, 0), config.steps.size(), progress, sub, nudge)
