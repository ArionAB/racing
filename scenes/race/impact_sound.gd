extends Node
## Sunetul de contact (docs/feel_checklist.md: impact-layers, scrape-sparks,
## side-rubbing, jump-skill, who-hit-me, ai-ai-hits — partea de sunet).
##
## UN singur nod pe cursa, ca ImpactFeel si HapticsFeed: asculta semnalul comun
## `Car.impact` al TUTUROR masinilor (nu mai exista sunete de impact in `Car`) si
## starea continua a jucatorului (`wall_contact`, `rub_car`...), si hotaraste CINE
## aude CE:
##
##   - perete: jucatorul aude un impact 2D in straturi (tap / crunch / crash dupa
##     putere + corpul `wall_hit`). Masinile AI care se lovesc de pereti raman
##     mute: n-are cine sa le auda din camera de urmarire;
##   - masina <-> masina CU jucatorul: corpul (bump + clinchet) 2D pentru „punch",
##     iar straturile principale POZITIONALE, la punctul de contact impins spre
##     cealalta masina (`positional_spread_m`): se aude din ce parte ai fost lovit;
##   - masina <-> masina FARA jucator: doar in `ai_range_m` de camera, de la
##     `ai_min_strength`, mai incet (`ai_gain_db`), pozitional, cu pauza globala
##     (`ai_interval_s`) — plutonul sunat viu, nu o salva de sunete;
##   - hartaieli: doua bucle (perete, frecare intre masini), doar pentru jucator;
##   - aterizare: `Car.landed` al jucatorului -> AudioManager.play_land();
##   - claxon: cand jucatorul se frecheaza de un AI mai mult de
##     `rub_honk_after_s`, cu sansa `rub_honk_chance` (o singura data pe episod).
##
## Un impact intre doua masini ajunge de DOUA ori (cate o data de la fiecare, cu
## puteri diferite dupa masa): se aduna intr-un tampon si se rezolva la sfarsitul
## tick-ului (prioritate 100, dupa toate masinile), iar perechea ramane tacuta
## `pair_interval_s`. Nu adauga latenta: tot in acelasi tick.

@export_group("Rivali (masina-masina fara jucator)")
## Cat de aproape de camera trebuie sa fie contactul ca sa se auda (m).
@export var ai_range_m: float = 35.0
## Sub aceasta putere (m/s) o ciocnire intre AI nu se aude.
@export var ai_min_strength: float = 3.5
## Cu cat mai incet decat un impact al jucatorului (dB).
@export var ai_gain_db: float = -8.0
## Pauza minima dintre doua sunete AI-AI, oricare pereche (s).
@export var ai_interval_s: float = 0.12

@export_group("Impact")
## Pauza minima dintre doua sunete ale ACEEEASI perechi de masini (s).
@export var pair_interval_s: float = 0.15
## Cat se muta sursa 3D de la punctul de contact spre cealalta masina (m): camera
## sta la ~13 m, iar o diferenta de 1 m nu se aude ca „stanga/dreapta".
@export var positional_spread_m: float = 3.0

@export_group("Hartaieli")
## Viteza de alunecare pe perete (m/s) de la care scrasneste, si cea la care e
## la maxim. Pornirea cere pragul intreg, continuarea 60% din el (histerezis).
@export var scrape_min_speed: float = 2.0
@export var scrape_full_speed: float = 18.0
@export var scrape_db_min: float = -24.0
@export var scrape_db_max: float = -7.0
@export var scrape_pitch_min: float = 0.75
@export var scrape_pitch_max: float = 1.45
## Frecarea intre masini (viteza relativa tangentiala).
@export var rub_min_speed: float = 1.5
@export var rub_full_speed: float = 10.0
@export var rub_db_min: float = -26.0
@export var rub_db_max: float = -10.0
@export var rub_pitch_min: float = 0.8
@export var rub_pitch_max: float = 1.3
## Cat ramane bucla pornita dupa ce contactul s-a pierdut (s): un contact care
## palpaie pe cateva tick-uri nu o opreste.
@export var contact_hold_s: float = 0.06

@export_group("Claxon")
## Cat trebuie sa te freci de un AI ca sa poata claxona (s), si sansa (0..1).
@export var rub_honk_after_s: float = 0.6
@export var rub_honk_chance: float = 0.5

## Cursa ruleaza? Altfel buclele se sting. Implicit mereu.
var racing: Callable = func() -> bool: return true
## Ceasul real (s); sondele il inlocuiesc cu unul simulat.
var clock: Callable = func() -> float: return Time.get_ticks_msec() * 0.001

## Pentru sonde: ultimul plan redat si cate impacturi au fost ignorate de reguli.
var last_plan: Array[Dictionary] = []
var played_count: int = 0
var skipped_ai: int = 0

var _player: Car
var _cars: Array[Car] = []
var _pending: Array[Dictionary] = []
var _pair_until: Dictionary = {}
var _ai_until: float = 0.0
var _scrape_hold: float = 0.0
var _scrape_speed: float = 0.0
var _rub_hold: float = 0.0
var _rub_speed: float = 0.0
var _rub_target: Car = null
var _rub_time: float = 0.0
var _rub_idle: float = 0.0
var _rub_decided: bool = false


func _init() -> void:
	# Dupa toate masinile (prioritate 0): la sfarsitul tick-ului au emis tot ce aveau.
	process_physics_priority = 100


func setup(p_player: Car, p_cars: Array) -> void:
	_player = p_player
	_cars.clear()
	for c in p_cars:
		var car := c as Car
		if car == null or _cars.has(car):
			continue
		_cars.append(car)
		car.impact.connect(_on_impact)
	if not _cars.has(_player):
		_cars.append(_player)
		_player.impact.connect(_on_impact)
	_player.landed.connect(_on_landed)


func _exit_tree() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio != null:
		audio.set_loop(&"scrape", false)
		audio.set_loop(&"rub", false)


func _on_impact(car: Car, kind: StringName, strength: float, normal: Vector3,
		point: Vector3, other: Node) -> void:
	_pending.append({"car": car, "kind": kind, "strength": strength,
		"normal": normal, "point": point, "other": other})


func _on_landed(_car: Car, fall_speed: float) -> void:
	last_plan = AudioManager.play_land(fall_speed)


func _physics_process(delta: float) -> void:
	_flush()
	_tick_loops(delta)
	_tick_rub_honk(delta)


# -------------------------------------------------------------- impacturi

func _flush() -> void:
	if _pending.is_empty():
		return
	var events := _pending
	_pending = []
	var merged: Dictionary = {}
	var walls: Array[Dictionary] = []
	for e in events:
		var other := e["other"] as Car
		if e["kind"] == &"car" and other != null:
			var key := _pair_key(e["car"] as Car, other)
			if not merged.has(key) or float(e["strength"]) > float((merged[key] as Dictionary)["strength"]):
				merged[key] = e
		else:
			walls.append(e)
	for key: String in merged:
		_handle_car_hit(key, merged[key] as Dictionary)
	for e in walls:
		_handle_wall_hit(e)


func _pair_key(a: Car, b: Car) -> String:
	var ia := a.get_instance_id()
	var ib := b.get_instance_id()
	return "%d:%d" % [mini(ia, ib), maxi(ia, ib)]


func _handle_car_hit(key: String, e: Dictionary) -> void:
	var a := e["car"] as Car
	var b := e["other"] as Car
	var strength := float(e["strength"])
	var now := float(clock.call())
	if now < float(_pair_until.get(key, 0.0)):
		return
	var point: Vector3 = e["point"]
	# Sursa 3D: punctul de contact tras spre cealalta masina. `normal` arata dinspre
	# obstacol spre masina care a emis evenimentul, deci obstacolul e pe -normal.
	var toward_other := -(e["normal"] as Vector3)
	toward_other.y = 0.0
	var src := point + toward_other.normalized() * positional_spread_m \
		if toward_other.length_squared() > 1e-4 else point
	if a.is_player or b.is_player:
		# `normal` e fata de masina care a emis; daca aceea nu e jucatorul, se inverseaza.
		if not a.is_player:
			src = point - (src - point)
		_pair_until[key] = now + pair_interval_s
		last_plan = AudioManager.play_impact(&"car", strength, src, true)
		played_count += 1
		return
	if strength < ai_min_strength or now < _ai_until \
			or not AudioManager.in_range(point, ai_range_m):
		skipped_ai += 1
		return
	_ai_until = now + ai_interval_s
	_pair_until[key] = now + pair_interval_s
	last_plan = AudioManager.play_impact(&"car", strength, src, true, ai_gain_db, false, 1)
	played_count += 1


func _handle_wall_hit(e: Dictionary) -> void:
	var car := e["car"] as Car
	if car == null or not car.is_player:
		return
	last_plan = AudioManager.play_impact(&"wall", float(e["strength"]))
	played_count += 1


# -------------------------------------------------------------- bucle

func _tick_loops(delta: float) -> void:
	var on := _player != null and is_instance_valid(_player) and bool(racing.call())
	# Perete.
	var thr := scrape_min_speed * (0.6 if _scrape_hold > 0.0 else 1.0)
	if on and _player.wall_contact and _player.wall_scrape_speed > thr:
		_scrape_hold = contact_hold_s
		_scrape_speed = _player.wall_scrape_speed
	else:
		_scrape_hold = maxf(_scrape_hold - delta, 0.0)
	var st := clampf(inverse_lerp(scrape_min_speed, scrape_full_speed, _scrape_speed), 0.0, 1.0)
	AudioManager.set_loop(&"scrape", on and _scrape_hold > 0.0,
		lerpf(scrape_db_min, scrape_db_max, st), lerpf(scrape_pitch_min, scrape_pitch_max, st))
	# Frecare intre masini.
	var rthr := rub_min_speed * (0.6 if _rub_hold > 0.0 else 1.0)
	if on and _player.rub_car != null and _player.rub_speed > rthr:
		_rub_hold = contact_hold_s
		_rub_speed = _player.rub_speed
	else:
		_rub_hold = maxf(_rub_hold - delta, 0.0)
	var rt := clampf(inverse_lerp(rub_min_speed, rub_full_speed, _rub_speed), 0.0, 1.0)
	AudioManager.set_loop(&"rub", on and _rub_hold > 0.0,
		lerpf(rub_db_min, rub_db_max, rt), lerpf(rub_pitch_min, rub_pitch_max, rt))


## Jucatorul se frecheaza de un AI: dupa `rub_honk_after_s` AI-ul poate claxona,
## o singura data pe episod (pauza per masina o tine AudioManager).
func _tick_rub_honk(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or not bool(racing.call()):
		_rub_target = null
		return
	var rc := _player.rub_car
	if rc != null and _player.rub_speed > rub_min_speed and not rc.is_player \
			and rc.controller is AIController:
		_rub_idle = 0.0
		if rc != _rub_target:
			_rub_target = rc
			_rub_time = 0.0
			_rub_decided = false
		_rub_time += delta
		if _rub_time >= rub_honk_after_s and not _rub_decided:
			_rub_decided = true
			if randf() < rub_honk_chance:
				AudioManager.honk(rc.get_instance_id(), rc.global_position)
	else:
		_rub_idle += delta
		if _rub_idle > 0.5:
			_rub_target = null
