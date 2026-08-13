extends Node
## Sonda pentru PathMover: figurantul mobil cu traiectorie desenata de mana.
##
## Doua intrebari, amandoua masurabile:
##   1. PARCURGE curba cu viteza ceruta? (pozitia dupa T secunde vs speed * T)
##   2. Masina care ii sta in cale e IMPINSA, nu strapunsa? Se masoara si
##      impingerea (masina se misca) si separarea minima (centrele nu se
##      intrepatrund niciodata sub suma semigabaritelor).
##
## Ruleaza CA SCENA (masina are nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePathMover.tscn

## Preincarcat, nu prin class_name: numele global intra in cache abia la
## scanarea editorului (sau la --import), iar sonda trebuie sa mearga si pe un
## checkout proaspat, inainte de orice scanare.
const PathMoverScript := preload("res://scenes/props/path_mover.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const MOVER_SPEED: float = 8.0
## Traiectoria: linie dreapta pe axa X, prin pozitia masinii.
const PATH_FROM := Vector3(-30.0, 0.0, 0.0)
const PATH_TO := Vector3(30.0, 0.0, 0.0)
const CAR_AT := Vector3(8.0, 0.1, 0.0)
## Semigabarite pe axa de mers: jumatate din lungimea placeholder-ului (3.4)
## + jumatate din latimea colizerului masinii (2.2), minus tolerata solverului.
const MIN_SEPARATION: float = 3.4 * 0.5 + 2.2 * 0.5 - 0.35

var _mover: Path3D
var _car: Car
var _time: float = 0.0
var _settle: float = 1.0
var _car_start_x: float = 0.0
var _min_gap: float = 1e9
## Pozitia figurantului la t=1s, pentru viteza masurata pe interval — imuna
## la secunda de asezare a suspensiei, in care figurantul merge deja.
var _mark_x: float = NAN
var _moved_check_done: bool = false
var _failed: bool = false


func _ready() -> void:
	_build_ground()
	_build_mover()
	await get_tree().process_frame
	_build_car()


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3.DOWN * 0.5
	ground.add_child(shape)
	add_child(ground)


func _build_mover() -> void:
	_mover = PathMoverScript.new()
	var c := Curve3D.new()
	c.add_point(PATH_FROM)
	c.add_point(PATH_TO)
	_mover.curve = c
	_mover.travel_mode = PathMoverScript.TravelMode.DUS_INTORS
	_mover.speed = MOVER_SPEED
	add_child(_mover)


func _build_car() -> void:
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.global_position = CAR_AT
	# Fara controller si fara cursa activa: masina doar sta pe suspensie in
	# calea figurantului, ca un jucator care a parcat prost.


func _physics_process(delta: float) -> void:
	if _car == null:
		return
	# Intai lasam suspensia sa se aseze; abia apoi incep masuratorile.
	if _settle > 0.0:
		_settle -= delta
		if _settle <= 0.0:
			_car_start_x = _car.global_position.x
		return
	_time += delta
	var body: AnimatableBody3D = _mover.body()

	# 1. Viteza pe curba, masurata pe intervalul t=1..2s, inainte de contactul
	# cu masina: distanta parcursa / timp, fara sa conteze cand a pornit.
	if is_nan(_mark_x) and _time >= 1.0:
		_mark_x = body.global_position.x
	if not _moved_check_done and _time >= 2.0:
		_moved_check_done = true
		var got := (body.global_position.x - _mark_x) / (_time - 1.0)
		print("[parcurs] viteza masurata pe curba: %.2f m/s (ceruta %.1f)" % [
			got, MOVER_SPEED])
		if absf(got - MOVER_SPEED) > 0.5:
			_failed = true
			print("  EGEC: nu tine viteza ceruta pe curba")

	# 2. Separarea minima fata de masina, pe toata durata trecerii.
	var gap := absf(body.global_position.x - _car.global_position.x)
	_min_gap = minf(_min_gap, gap)

	if _time >= 8.0:
		_report()


func _report() -> void:
	set_physics_process(false)
	var pushed := _car.global_position.x - _car_start_x
	print("")
	print("=== PATH MOVER — ciocnire cu masina parcata ===")
	print("impingere masina: %.2f m (start x=%.2f -> %.2f)" % [
		pushed, _car_start_x, _car.global_position.x])
	print("separare minima centre: %.2f m (prag intrepatrundere %.2f m)" % [
		_min_gap, MIN_SEPARATION])
	if pushed < 0.5:
		_failed = true
		print("EGEC: masina NU a fost impinsa — figurantul a trecut prin ea?")
	if _min_gap < MIN_SEPARATION:
		_failed = true
		print("EGEC: intrepatrundere — corpurile s-au suprapus")
	print("VERDICT: %s" % ("EGEC" if _failed else "TRECUT"))
	get_tree().quit(1 if _failed else 0)
