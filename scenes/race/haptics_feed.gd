extends Node
## Vibratie (docs/feel_checklist.md: haptics): impacturi, aterizari dure si
## pornirea turbo-ului, doar pentru JUCATOR, dozate dupa intensitate si cu limita
## de ritm.
##
## TOATE pulsurile trec printr-o singura functie, `pulse()`: acolo se verifica
## setarea, ritmul si se scrie jurnalul (`pulse_log`); abia apoi se cheama `output`
## (telefonul sau maneta). Asa se poate proba fara hardware: sonda inlocuieste
## `output` si citeste `pulse_log`.
##
## Ascultă semnalele masinii jucatorului, nu face poll:
##   - `impact` (perete / masina): durata si amplitudine cresc cu delta-v;
##   - `landed`: cade de la `land_min_fall` m/s in sus;
##   - `boost_started`: un puls mediu fix (click-ul de la pornirea turbo-ului).
##
## Ceasul e REAL (nu cel al jocului): hit-stop-ul coboara `Engine.time_scale`,
## iar limita de ritm trebuie sa ramana in milisecunde adevarate.

## Comutator legat de setare: `GameState.haptics_enabled`. Sondele il pot
## suprascrie fara a atinge fisierul de setari.
var enabled_source: Callable = func() -> bool: return GameState.haptics_enabled
## Cursa ruleaza? (nu vibram in numaratoare si dupa final.) Implicit mereu.
var racing: Callable = func() -> bool: return true
## Ceasul real, in secunde. Sondele il inlocuiesc cu unul simulat.
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
## Iesirea fizica: (durata_ms: int, amplitudine: float) -> void. Implicit telefonul
## si manetele conectate; sonda o inlocuieste cu o captura.
var output: Callable = _platform_output

# --- impact ---
## Sub aceasta delta-v (m/s) un impact nu vibreaza.
@export var impact_min: float = 3.0
## La aceasta delta-v pulsul atinge maximul.
@export var impact_full: float = 20.0
# --- aterizare ---
## Viteza de cadere (m/s) de la care o aterizare vibreaza, si cea care da maximul.
@export var land_min_fall: float = 6.0
@export var land_full_fall: float = 20.0
# --- turbo ---
@export var boost_ms: int = 30
@export var boost_amp: float = 0.5
# --- pulsul ---
## Durata minima / maxima a unui puls (ms). Pulsurile scurte se simt ca lovituri;
## peste ~60 ms devin bazait.
@export var min_ms: int = 15
@export var max_ms: int = 60
## Amplitudinea (0..1) la intensitatea minima si la maxima.
@export var min_amp: float = 0.25
@export var max_amp: float = 1.0
## Cel mult un puls la atatea secunde (ceas real).
@export var min_interval_s: float = 0.15

## Jurnalul pulsurilor care au ajuns la `output` (sonde): {t, ms, amp, kind}.
var pulse_log: Array[Dictionary] = []
## Cate pulsuri au fost refuzate si de ce (sonde): {"off": n, "rate": n, "idle": n}.
var dropped: Dictionary = {"off": 0, "rate": 0, "idle": 0}

## Bordura: pulsuri scurte si slabe cat timp jucatorul calca pe ea, peste
## `kerb_min_speed`, la cel mult unul pe `kerb_interval_s`. 0 amp = oprit.
@export var kerb_min_speed: float = 6.0
@export var kerb_interval_s: float = 0.18
@export var kerb_amp: Vector2 = Vector2(0.15, 0.3)
## Un puls care trece de ultimul cu factorul asta ocoleste limita de rata:
## o izbitura imediat dupa un tic de bordura nu se pierde.
@export var override_ratio: float = 1.5

var _last_t: float = -1.0e9
var _last_amp: float = 0.0
var _kerb_t: float = -1.0e9
var _player: Car


func setup(player: Car) -> void:
	_player = player
	player.impact.connect(_on_impact)
	player.landed.connect(_on_landed)
	player.boost_started.connect(_on_boost)


func _on_impact(_c: Car, kind: StringName, strength: float, _normal: Vector3,
		_point: Vector3, _other: Node) -> void:
	if strength < impact_min:
		return
	var k := clampf((strength - impact_min) / maxf(impact_full - impact_min, 0.01), 0.0, 1.0)
	pulse(int(round(lerpf(min_ms, max_ms, k))), lerpf(min_amp, max_amp, k), kind)


func _on_landed(_c: Car, fall_speed: float) -> void:
	if fall_speed < land_min_fall:
		return
	var k := clampf((fall_speed - land_min_fall)
		/ maxf(land_full_fall - land_min_fall, 0.01), 0.0, 1.0)
	pulse(int(round(lerpf(min_ms, max_ms, k))), lerpf(0.35, max_amp, k), &"land")


func _on_boost(_c: Car) -> void:
	pulse(boost_ms, boost_amp, &"boost")


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player) or not _player.on_kerb or kerb_amp.y <= 0.0:
		return
	var v := Vector3(_player.linear_velocity.x, 0.0, _player.linear_velocity.z).length()
	if v < kerb_min_speed:
		return
	var now := float(clock.call())
	if now - _kerb_t < kerb_interval_s:
		return
	_kerb_t = now
	var k := clampf(inverse_lerp(kerb_min_speed, maxf(_player.max_speed, kerb_min_speed + 1.0), v),
		0.0, 1.0)
	pulse(min_ms, lerpf(kerb_amp.x, kerb_amp.y, k), &"kerb")


## UNICUL punct de iesire. Intoarce true daca pulsul a plecat spre `output`.
func pulse(ms: int, amp: float, kind: StringName = &"") -> bool:
	if not bool(enabled_source.call()):
		dropped["off"] += 1
		return false
	if not bool(racing.call()):
		dropped["idle"] += 1
		return false
	var now := float(clock.call())
	if now - _last_t < min_interval_s and amp < _last_amp * override_ratio:
		dropped["rate"] += 1
		return false
	_last_t = now
	_last_amp = amp
	ms = clampi(ms, min_ms, max_ms)
	amp = clampf(amp, 0.0, 1.0)
	pulse_log.append({"t": now, "ms": ms, "amp": amp, "kind": kind})
	if pulse_log.size() > 64:
		pulse_log.pop_front()
	output.call(ms, amp)
	return true


## Telefon: `Input.vibrate_handheld`; manete: vibratie slaba+puternica proportionala.
## Pe desktop fara maneta nu se intampla nimic.
func _platform_output(ms: int, amp: float) -> void:
	Input.vibrate_handheld(ms, amp)
	for dev in Input.get_connected_joypads():
		Input.start_joy_vibration(dev, amp * 0.6, amp, float(ms) * 0.001)
