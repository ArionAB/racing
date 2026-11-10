class_name LightningFlash
extends Node
## FULGERUL MUSONULUI (Angkor, Track24, docs/track_briefs/angkor.md §3 „Fulgerul”).
## Efectul nr. 1 din analiza Ignition (`ref_notes/README.md`): o albire scurta a ecranului
## si un varf de lumina pe soare si pe ambient, cu tunetul dupa. Aproape gratis pe mobil:
## un `ColorRect` si doua aduneri pe proprietati existente, zero materiale.
##
## [b]Nu are ceas propriu.[/b] Se aboneaza la [RainCycle] (grupul `rain_cycle`, tiparul
## metronomului: tot ce e ciclic asculta acelasi ceas). La fiecare ploaie noua isi PLANIFICA
## fulgerele — 3-5, deterministe din (seed, numarul ploii), deci aceeasi cursa da aceleasi
## fulgere, iar sondele pot compara rulari. Cat nu ploua, nu face nimic.
##
## [b]Dupa RainCycle, nu in locul lui.[/b] RainCycle rescrie `sun.light_energy` si
## `env.ambient_light_energy` in fiecare cadru (`_apply`). Fulgerul ruleaza DUPA el
## (`process_priority` mai mare) si ADUNA varful peste valoarea scrisa acum — deci nu se
## acumuleaza de la un cadru la altul si se stinge exact in baza ploii.
##
## [b]Fotosensibilitate (obligatoriu, brief §3):[/b]
##   - cel mult un fulger la `min_gap` secunde, plafonat la 2 s (WCAG cere sub 3 pe secunda;
##     noi suntem mult sub);
##   - albirea ecranului plafonata la `OVERLAY_CAP` (niciodata alb plin);
##   - `GameState.reduce_flashes`: fara albire deloc, doar un puls LENT de ambient (urcare in
##     `REDUCED_ATTACK` s), la o fractiune din intensitate.

## Emis la fiecare fulger, cu taria lui (0..1). Pentru sunet / stolul care se ridica.
signal flashed(strength: float)
## Emis la tunet (intarziat dupa fulger cu `thunder_delay`).
signal thunder(strength: float)

const OVERLAY_CAP: float = 0.5
const MIN_GAP_FLOOR: float = 2.0
const REDUCED_ATTACK: float = 0.35
const REDUCED_SCALE: float = 0.4

@export_range(1, 8) var flashes_min: int = 3
@export_range(1, 8) var flashes_max: int = 5
## Cel mai mic interval intre doua fulgere (s); nu coboara sub `MIN_GAP_FLOOR`.
@export_range(2.0, 20.0, 0.1) var min_gap: float = 2.5
## Albirea maxima a ecranului (alfa), plafonata la `OVERLAY_CAP`.
@export_range(0.0, 0.5, 0.01) var overlay_peak: float = 0.38
@export var overlay_color: Color = Color(0.90, 0.92, 1.0)
## Cat sta fulgerul aprins (s), apoi stingerea (s).
@export_range(0.04, 0.4, 0.01) var flash_time: float = 0.12
@export_range(0.1, 1.5, 0.01) var afterglow: float = 0.4
## Varful ADUNAT pe energia soarelui si pe cea ambientala, la taria 1.
@export var sun_spike: float = 1.1
@export var ambient_spike: float = 0.9
## Intarzierea tunetului dupa fulger (s): interval din care se trage per fulger.
@export var thunder_delay: Vector2 = Vector2(0.4, 2.0)
## Sunetul tunetului (optional; fara el se emite doar semnalul).
@export var thunder_stream: AudioStream = null
## Varianta cu pocnet, pentru fulgerul APROPIAT (intarziere sub `close_delay`).
## Fara ea, orice tunet foloseste `thunder_stream`.
@export var thunder_close_stream: AudioStream = null
## Sub cate secunde de intarziere un fulger conteaza „aproape" (lumina si sunetul
## aproape deodata). Din intervalul 0,4-2,0 s al lui `thunder_delay` iese ~1/4 din tunete.
@export var close_delay: float = 0.8
## Volumul tunetului (dB) la taria 1; se scade cu taria fulgerului. Tunetul e un
## strat de fundal: sub motor si sub ghionturi.
@export var thunder_db: float = 0.0
## Sare in seed, ca doua piste cu acelasi RainCycle sa nu aiba aceleasi fulgere.
@export var seed_salt: int = 24

## Pentru sonde: momentele fulgerelor (s de la pornire) si albirea maxima atinsa.
var flash_log: PackedFloat64Array = PackedFloat64Array()
var max_overlay_alpha: float = 0.0
## Pentru sonde: streamul fiecarui tunet redat (in ordine).
var play_log: Array[AudioStream] = []

var _rain: RainCycle = null
var _env: Environment = null
var _sun: DirectionalLight3D = null
var _time: float = 0.0
var _shower: int = 0
var _plan: PackedFloat64Array = PackedFloat64Array()   # momente absolute planificate
var _strength: PackedFloat64Array = PackedFloat64Array()
var _thunders: Array = []                               # [moment, tarie, apropiat]
var _last_flash: float = -1e9
var _last_strength: float = 0.0
var _layer: CanvasLayer = null
var _veil: ColorRect = null
var _player: AudioStreamPlayer = null


func _ready() -> void:
	# Dupa RainCycle (prioritate 0): varful se aduna peste ce a scris el in acest cadru.
	process_priority = 10
	_layer = CanvasLayer.new()
	_layer.layer = 4
	add_child(_layer)
	_veil = ColorRect.new()
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.0)
	_veil.visible = false
	_layer.add_child(_veil)
	if thunder_stream != null:
		_player = AudioStreamPlayer.new()
		_player.stream = thunder_stream
		_player.bus = &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"
		add_child(_player)
	_hook.call_deferred()


func _hook() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"rain_cycle"):
		if n is RainCycle:
			_rain = n as RainCycle
			break
	if _rain == null:
		push_warning("LightningFlash: niciun RainCycle in scena — fara fulgere")
		set_process(false)
		return
	_rain.rain_changed.connect(_on_rain_changed)
	_env = _rain._env
	_sun = _rain._sun
	# Daca pista porneste in plina ploaie (sonda cu --rain), planifica imediat.
	if _rain.rain_factor > 0.0001:
		_on_rain_changed(true)


## La fiecare ploaie noua: N fulgere in fereastra de ploaie plina, cate unul pe felie egala,
## cu pozitia in felie trasa la zar dar cu distanta minima garantata. Deterministe din
## (seed_salt, numarul ploii).
func _on_rain_changed(raining: bool) -> void:
	if not raining:
		_plan.clear()
		_strength.clear()
		return
	_shower += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(seed_salt, _shower))
	var n := rng.randi_range(mini(flashes_min, flashes_max), maxi(flashes_min, flashes_max))
	var gap := maxf(min_gap, MIN_GAP_FLOOR)
	# Fereastra: de la sfarsitul telegrafului pana spre finalul ploii plina.
	var start := _time + maxf(_rain.telegraph * 0.8, 0.5)
	var window := maxf(_rain.rain_hold * 0.85, gap)
	n = mini(n, int(window / gap))
	_plan.clear()
	_strength.clear()
	if n <= 0:
		return
	var slot := window / float(n)
	for k in n:
		var t := start + slot * float(k) + rng.randf() * maxf(slot - gap, 0.0)
		_plan.append(t)
		_strength.append(rng.randf_range(0.65, 1.0))


func _process(delta: float) -> void:
	_time += delta
	# RainCycle isi gaseste mediul in `_collect` (amanat); daca ne-am agatat inainte, luam
	# referintele de la el acum.
	if _env == null and _rain != null:
		_env = _rain._env
	if _sun == null and _rain != null:
		_sun = _rain._sun
	# Fulgere planificate care au sosit (cel mult unul pe cadru, si niciodata sub `gap`).
	var gap := maxf(min_gap, MIN_GAP_FLOOR)
	while not _plan.is_empty() and _plan[0] <= _time:
		var s := _strength[0]
		_plan.remove_at(0)
		_strength.remove_at(0)
		if _time - _last_flash >= gap:
			_fire(s)
	# Tunetele intarziate.
	var i := 0
	while i < _thunders.size():
		if float(_thunders[i][0]) <= _time:
			var ts := float(_thunders[i][1])
			var close := bool(_thunders[i][2])
			_thunders.remove_at(i)
			thunder.emit(ts)
			if _player != null:
				_player.stream = (thunder_close_stream if close and thunder_close_stream != null
					else thunder_stream)
				_player.volume_db = thunder_db + linear_to_db(clampf(ts, 0.05, 1.0))
				_player.play()
				play_log.append(_player.stream)
		else:
			i += 1
	_apply(_intensity())


func _fire(strength: float) -> void:
	_last_flash = _time
	_last_strength = strength
	flash_log.append(_time)
	flashed.emit(strength)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(seed_salt * 7 + _shower, flash_log.size()))
	var delay := rng.randf_range(thunder_delay.x, thunder_delay.y)
	_thunders.append([_time + delay, strength, delay < close_delay])


## Taria curenta a fulgerului (0..1): platou scurt, apoi stingere patratica. In modul redus,
## urcare lenta si tarie scazuta — un puls de lumina, nu o clipire.
func _intensity() -> float:
	var dt := _time - _last_flash
	if dt < 0.0:
		return 0.0
	if GameState.reduce_flashes:
		var total := REDUCED_ATTACK + afterglow * 2.0
		if dt >= total:
			return 0.0
		var up := clampf(dt / REDUCED_ATTACK, 0.0, 1.0)
		var down := 1.0 - clampf((dt - REDUCED_ATTACK) / (afterglow * 2.0), 0.0, 1.0)
		return _last_strength * REDUCED_SCALE * minf(up, down * down)
	if dt < flash_time:
		return _last_strength
	var k := 1.0 - (dt - flash_time) / afterglow
	return _last_strength * maxf(k, 0.0) * maxf(k, 0.0)


func _apply(amount: float) -> void:
	var alpha := 0.0
	if not GameState.reduce_flashes:
		alpha = minf(overlay_peak, OVERLAY_CAP) * amount
	_veil.visible = alpha > 0.001
	_veil.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, alpha)
	max_overlay_alpha = maxf(max_overlay_alpha, alpha)
	if amount <= 0.0:
		return
	# ADUNAT peste ce a scris RainCycle in acest cadru (el ruleaza inainte).
	if _sun != null:
		_sun.light_energy += sun_spike * amount
	if _env != null:
		_env.ambient_light_energy += ambient_spike * amount
