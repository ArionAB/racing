extends Node
## Sonda 4-B (Monument Valley, 6 oct 2026): TURBO-ul nu are voie sa scoata masina
## din strivire. Dezvoltatorul a observat la volan ca daca esti strivit si tii
## TURBO iesi din starea de strivit.
##
## Cauza: `Car.crush()` stingea boost-ul O SINGURA DATA, iar daca butonul ramanea
## apasat, `_update_turbo` il reaprindea in tick-ul urmator. `_current_max_speed`
## adauga `turbo_speed_bonus` INAINTE sa inmulteasca cu `crush_factor`, deci
## plafonul strivit urca de la 0.7*vmax la 0.7*(vmax+11); in plus accelerarea
## primea `turbo_accel_bonus`, `_start_boost` adauga +4 m/s si `_punch_scale`
## suprascria turtirea tinuta.
##
## Masuratoarea e pe masina reala, pe o dreapta: masina merge cu aproape viteza
## maxima, e strivita (factor 0.70) si TINE TURBO. Cat dureaza strivirea:
##   - viteza orizontala nu depaseste plafonul strivit calculat din campurile
##     masinii (max_speed * speed_scale * 0.70, nu din `_current_max_speed`) + marja;
##   - `is_boosting` nu e niciodata true;
##   - turtirea (`scale.y` al caroseriei) ramane sub 0.35;
##   - `crush_time` scade monoton la 0 (nu e sters);
##   - bara nu se goleste (nu s-a ars nimic).
## Dupa expirare, cu butonul inca apasat, turbo-ul porneste (nu l-am stricat).
##
## `--sabotaj`: scoate fix-ul la runtime (`crush_blocks_turbo = false`); sonda
## TREBUIE sa pice. Cod: 1 = a picat (garda armata), 3 = a trecut (garda moarta),
## 2 = n-am masurat nimic. Fara sabotaj: 0 = ok, 1 = verdict picat.
##
## Ruleaza CA SCENA: godot --headless --fixed-fps 60 res://tools/ProbeCrushTurbo.tscn [-- --sabotaj]

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const CRUSH_SECONDS: float = 2.0
const CRUSH_FACTOR: float = 0.70
## Marja peste plafonul strivit (m/s): tragerea inapoi e un guvernator, nu perete.
const CAP_MARGIN: float = 1.0

class HoldTurbo extends CarController:
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return 1.0
	func is_turbo_pressed() -> bool:
		return true

var _sabotage: bool = false
var _fails: int = 0


func _ready() -> void:
	_sabotage = "--sabotaj" in OS.get_cmdline_user_args()
	var track := TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	track.add_child(path)
	track.custom_name = "ProbeCrushTurbo"
	track.custom_theme = "forest"
	track.custom_half_width = 10.0
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = track
	var at := Vector3(0.0, 0.7, 135.0)
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	var v0 := car.max_speed * car.speed_scale * 0.97
	car.velocity = Vector3(0, 0, -v0)
	car.route = 0
	car.road_index = track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	car.turbo_charge = 1.0
	car.set_controller(HoldTurbo.new())
	if _sabotage:
		car.crush_blocks_turbo = false
	var vmax_nominal := car.max_speed * car.speed_scale
	var cap := vmax_nominal * CRUSH_FACTOR
	print("=== CRUSH + TURBO%s ===" % (" (SABOTAJ: fix scos)" if _sabotage else ""))
	print("  masina 0: max_speed*scale = %.1f m/s, plafon strivit asteptat %.1f m/s, start %.1f"
		% [vmax_nominal, cap, v0])

	# Rulam 1 s cu turbo tinut si fara strivire (control): turbo-ul chiar merge.
	var ctrl_boost := false
	for _i in 60:
		await get_tree().physics_frame
		ctrl_boost = ctrl_boost or car.is_boosting
	_verdict(ctrl_boost, "control: fara strivire, TURBO tinut aprinde boost-ul")

	car.turbo_charge = 1.0
	car.crush(CRUSH_SECONDS, CRUSH_FACTOR, Vector3(1.55, 0.245, 1.45), 1.0, true)
	var charge0 := car.turbo_charge
	var visual: Node3D = car.get("_visual") as Node3D
	var boosted := 0
	var vmax_seen := 0.0
	var v_late := 0.0
	var squash_max_y := 0.0
	var prev_ct := car.crush_time
	var monotone := true
	var charge_min := charge0
	var frames := int(CRUSH_SECONDS * 60.0) - 6
	for i in frames:
		await get_tree().physics_frame
		var t := float(i + 1) / 60.0
		if car.is_boosting:
			boosted += 1
		var v := car.horizontal_speed()
		if t > 1.2:
			vmax_seen = maxf(vmax_seen, v)
		if absf(t - 1.5) < 0.02:
			v_late = v
		if t > 0.3 and t < 1.4 and visual != null:
			squash_max_y = maxf(squash_max_y, visual.scale.y)
		if car.crush_time > prev_ct + 0.0001:
			monotone = false
		prev_ct = car.crush_time
		charge_min = minf(charge_min, car.turbo_charge)
	_verdict(boosted == 0, "cat dureaza strivirea turbo-ul NU porneste (cadre cu is_boosting: %d)" % boosted)
	_verdict(vmax_seen <= cap + CAP_MARGIN,
		"viteza dupa 1.2 s de strivire <= plafon strivit (max %.1f, plafon %.1f + %.1f)"
		% [vmax_seen, cap, CAP_MARGIN])
	_verdict(visual != null, "caroseria gasita (nod _visual)")
	if visual != null:
		_verdict(squash_max_y <= 0.35, "caroseria ramane turtita (scale.y max %.2f in 0.3..1.4 s)" % squash_max_y)
	_verdict(monotone and car.crush_time > 0.0,
		"crush_time nu e sters/prelungit de turbo (ramas %.2f s, monoton)" % car.crush_time)
	_verdict(charge_min >= charge0 - 0.001, "bara de turbo nu s-a golit (min %.3f din %.3f)" % [charge_min, charge0])
	print("  viteza la 1.5 s: %.1f m/s" % v_late)

	# Dupa expirare, cu butonul inca tinut, turbo-ul porneste.
	for _i in 40:
		await get_tree().physics_frame
	_verdict(car.crush_time <= 0.0, "strivirea a expirat (crush_time %.2f)" % car.crush_time)
	var resumed := false
	for _i in 30:
		await get_tree().physics_frame
		resumed = resumed or car.is_boosting
	_verdict(resumed, "dupa expirare turbo-ul tinut porneste din nou")

	_measured_exit()


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _measured_exit() -> void:
	if _sabotage:
		if _fails > 0:
			print("SABOTAJ: garda a PICAT (%d verdicte) -> armata" % _fails)
			get_tree().quit(1)
		else:
			print("SABOTAJ: garda a TRECUT -> MOARTA")
			get_tree().quit(3)
	else:
		print("VERDICT: ", "OK" if _fails == 0 else "PROBLEME (%d)" % _fails)
		get_tree().quit(1 if _fails > 0 else 0)
