extends Node
## Garda pasului 2 al carierei: rezervorul sigilat al contratimpului.
## `Car.turbo_recharge = false` => bara NU creste (nici din mers, nici din
## drift), dar arderea merge. Masurat pe masina reala, pe o pista scurta:
##   1. recharge=false, bara 0.3, gaz + drift 6 s: bara ramane 0.3 (1e-4);
##   2. CONTRA-PROBA, recharge=true, aceeasi rulare: bara creste cu >= 0.2
##      (altfel sonda masoara altceva — cifra identica ar fi un mecanism
##      neconectat, nu o garda);
##   3. recharge=false, TURBO tinut 1 s: bara SCADE (arderea nu e stricata).
## In (1) si (2) cerem si cadre de drift reale, ca sa fie dovedit ca drift-ul
## chiar a incercat sa hraneasca bara.
##
## Ruleaza CA SCENA: godot --headless --fixed-fps 60 res://tools/ProbeSealedTurbo.tscn

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const START_CHARGE: float = 0.3
const RUN_SECONDS: float = 6.0

## Gaz mereu; drift apasat cu viraj alternant (stanga/dreapta la 1.5 s), ca
## masina sa intre cu adevarat in drift. `turbo` se comuta din sonda.
class SealedDriver extends CarController:
	var turbo: bool = false
	var drift: bool = true
	var _t: float = 0.0
	func update(delta: float) -> void:
		_t += delta
	func get_steer() -> float:
		return 0.7 if int(_t / 1.5) % 2 == 0 else -0.7
	func get_throttle() -> float:
		return 1.0
	func is_drift_pressed() -> bool:
		return drift
	func is_turbo_pressed() -> bool:
		return turbo

var _track: TrackFromPath
var _fails: int = 0


func _ready() -> void:
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeSealedTurbo"
	_track.custom_theme = "forest"
	_track.custom_half_width = 10.0
	add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame

	print("=== REZERVOR SIGILAT ===")
	var sealed := await _run(false, false, RUN_SECONDS)
	var open := await _run(true, false, RUN_SECONDS)
	var burn := await _run(false, true, 1.0)

	print("  sigilat : bara %.4f -> %.4f (cadre drift %d)" % [START_CHARGE, sealed.end, sealed.drift_frames])
	print("  deschis : bara %.4f -> %.4f (cadre drift %d)" % [START_CHARGE, open.end, open.drift_frames])
	print("  ardere  : bara %.4f -> %.4f (cadre boost %d)" % [START_CHARGE, burn.end, burn.boost_frames])

	_verdict(absf(sealed.end - START_CHARGE) <= 1e-4 and sealed.max_seen <= START_CHARGE + 1e-4,
		"sigilat: bara ramane %.1f (max vazut %.4f)" % [START_CHARGE, sealed.max_seen])
	_verdict(sealed.drift_frames > 30,
		"sigilat: masina a driftat cu adevarat (%d cadre) — drift-ul nu hraneste bara" % sealed.drift_frames)
	_verdict(open.end >= START_CHARGE + 0.2,
		"contra-proba: cu turbo_recharge=true bara creste >= 0.2 (%.3f)" % (open.end - START_CHARGE))
	_verdict(burn.end < START_CHARGE - 0.05 and burn.boost_frames > 10,
		"sigilat + TURBO tinut: bara scade (%.3f) si boost-ul porneste (%d cadre)"
		% [burn.end, burn.boost_frames])

	print("VERDICT: ", "OK" if _fails == 0 else "PROBLEMA (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


## O masina noua pe dreapta de start; intoarce {end, max_seen, drift_frames,
## boost_frames}.
func _run(recharge: bool, hold_turbo: bool, seconds: float) -> Dictionary:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	var at := Vector3(0.0, 0.7, 135.0)
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3(0, 0, -car.max_speed * car.speed_scale * 0.8)
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	car.turbo_recharge = recharge
	car.turbo_charge = START_CHARGE
	var driver := SealedDriver.new()
	driver.turbo = hold_turbo
	driver.drift = not hold_turbo
	car.set_controller(driver)
	var out := {"end": 0.0, "max_seen": START_CHARGE, "drift_frames": 0, "boost_frames": 0}
	for _i in int(seconds * 60.0):
		await get_tree().physics_frame
		out.max_seen = maxf(float(out.max_seen), car.turbo_charge)
		if car.is_drifting:
			out.drift_frames += 1
		if car.is_boosting:
			out.boost_frames += 1
	out.end = car.turbo_charge
	car.queue_free()
	await get_tree().physics_frame
	return out


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1
