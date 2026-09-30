extends Node
## Valea USCATA dintre bratele fantanii (Track17, POI C): cine cade acolo e
## repus, nu ramane blocat?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodVale.tscn [-- --fara-zona]
##
## De ce exista: pe scena integrata 4e5b79d9, seed 3, masina jucatorului a
## fost impinsa de pe marginea stanga a bratului de iesire (frac 0.228,
## lat +5) si a cazut in valea cornisei, pe partea USCATA (apa incepe abia la
## est de x ~ -150). Acolo nu era nicio `RespawnZone` (se fac doar pe
## celulele ude) iar peretele cornisei e de 1-4 m: AI-ul a ramas 20 s sub
## 6 m/s (trei `[blocaj]` la 0.237-0.239, apoi repunerea paznicului).
## ProbeRace nu reproduce cazul stabil (orice nod nou in scena schimba
## ordinea fizicii si traiectoria), deci sonda il pune direct: masina cu AI
## in cateva puncte ale vaii, si masoara in cat timp e repusa pe drum.
##
## `--fara-zona` scoate `FantanaValeUscata` (A/B): acolo trebuie sa iasa
## LENT (masurat 30 sep: 10,9 / 2,4 / 0,3 / 10,9 / 11,8 s, repus de paznicul
## AI dupa ~11 s sau urcat anevoie), cu zona toate 5 sub 0,5 s. Prag: pe drum
## in cel mult MAX_BACK s, altfel e cazul de `[blocaj]` din ProbeRace.

const SCENE := "res://scenes/tracks/Track17.tscn"
const CAR_SCENE := "res://scenes/cars/Car.tscn"
const TIMEOUT := 25.0
const MAX_BACK := 3.0
## Punctele: cel din seed 3, plus unul mai spre vest si unul langa apa, pe
## ambele jumatati ale vaii.
const POINTS: Array[Vector3] = [
	Vector3(-159.0, -5.2, 57.3), Vector3(-170.0, -4.6, 58.0),
	Vector3(-150.0, -6.0, 60.5), Vector3(-160.0, -5.0, 66.0),
	Vector3(-178.0, -3.6, 64.0),
]

var tr: Track
var _case := -1
var _car: Car = null
var _t := 0.0
var _respawned := false
var _rows: Array[String] = []
var _stuck := 0


func _ready() -> void:
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	if "--fara-zona" in OS.get_cmdline_user_args():
		var z := tr.get_node_or_null("FantanaValeUscata")
		if z != null:
			tr.remove_child(z)
			z.free()
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	_next()


func _next() -> void:
	if _car != null:
		_car.queue_free()
		_car = null
	_case += 1
	if _case >= POINTS.size():
		for r in _rows:
			print(r)
		print("VERDICT: %s (%d/%d peste %.0f s)" % ["OK" if _stuck == 0 else "BLOCAJ", _stuck, POINTS.size(), MAX_BACK])
		get_tree().quit(0 if _stuck == 0 else 1)
		return
	var p: Vector3 = POINTS[_case]
	p.y = tr._terrain_mesh_y(p.x, p.z) + 0.8
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	_car.position = p
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0] as CarData)
	_car.track = tr
	_car.road_index = tr.closest_index_global(p)
	_car.last_safe_index = _car.road_index
	_car.look_at(p + Vector3(-1, 0, 0), Vector3.UP)
	_car.race_active = true
	var ai := AIController.new()
	_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + _case
	ai.configure(tr, rng)
	_t = 0.0
	_respawned = false
	_car.respawned.connect(func(_c: Car) -> void: _respawned = true)


func _physics_process(delta: float) -> void:
	if _car == null:
		return
	_t += delta
	var on_road := tr.is_on_road(_car.road_index, _car.global_position)
	var p0: Vector3 = POINTS[_case]
	if on_road and _t > 0.2:
		var how := "repus" if _respawned else "a urcat singur"
		var slow := _t > MAX_BACK
		if slow:
			_stuck += 1
		_rows.append("  (%.0f, %.0f): pe drum dupa %.1f s (%s)%s" % [p0.x, p0.z, _t, how, "  <-- LENT" if slow else ""])
		_next()
	elif _t >= TIMEOUT:
		_stuck += 1
		_rows.append("  (%.0f, %.0f): BLOCAT %.0f s, pozitia %s" % [p0.x, p0.z, TIMEOUT, _car.global_position])
		_next()
