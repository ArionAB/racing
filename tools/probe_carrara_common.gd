extends RefCounted
## Unelte comune pentru sondele tehnice Carrara (sania de lizzatura, derrick-ul).
##
## Fara class_name (nu atinge cache-ul de clase): se preincarca cu
## `const Common := preload("res://tools/probe_carrara_common.gd")`.
##
## Ce da: o podea plata (drumul e y = 0, tot ce e in afara lui e tot y = 0),
## o masina REALA din garaj condusa de WaypointDriver, un inregistrator de cadre
## si analiza loviturii fata de o rulare de CONTROL (aceeasi masina, acelasi
## start, fara hazard). Diferenta fata de control e ce face verdictul: o viteza
## absoluta dupa lovitura nu spune nimic daca nu stii ce ar fi facut masina
## fara ea.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const ROAD_HALF: float = 4.5
const STEP: float = 1.0 / 60.0
## Fereastra de IMPACT (s): ca la sonda macaralei din Chongqing, ca cifrele sa
## fie comparabile cu precedentul.
const IMPACT_WINDOW: float = 0.5
## Cat dupa lovitura se masoara pierderea de timp (s).
const LOSS_WINDOW: float = 8.0


## Cadrele unei rulari, cate un esantion pe pas de fizica.
class Rec:
	var t := PackedFloat64Array()
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	var z := PackedFloat64Array()
	var spd := PackedFloat64Array()
	var up := PackedFloat64Array()
	var yaw := PackedFloat64Array()
	var spin := PackedFloat64Array()
	var crush := PackedFloat64Array()

	func add(time: float, car: Car) -> void:
		t.append(time)
		x.append(car.global_position.x)
		y.append(car.global_position.y)
		z.append(car.global_position.z)
		spd.append(car.horizontal_speed())
		up.append(car.global_transform.basis.y.dot(Vector3.UP))
		var fwd := -car.global_transform.basis.z
		yaw.append(atan2(-fwd.x, -fwd.z))
		spin.append(float(car.get("_spin_left")))
		crush.append(car.crush_time)

	func size() -> int:
		return t.size()


static func make_ground(parent: Node) -> StaticBody3D:
	var g := StaticBody3D.new()
	g.name = "Ground"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1800.0, 1.0, 1800.0)
	cs.shape = box
	g.add_child(cs)
	g.position = Vector3(0.0, -0.5, 0.0)
	parent.add_child(g)
	return g


## Masina `idx` din GameState.CAR_DATA, pe banda x, pornita cu `speed` pe -Z si
## condusa pe banda pana departe.
static func spawn_car(parent: Node, idx: int, x: float, z: float,
		speed: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	parent.add_child(car)
	car.apply_data(GameState.CAR_DATA[idx])
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.7, z))
	car.velocity = Vector3(0.0, 0.0, -speed)
	car.race_active = true
	var drv := WaypointDriver.new()
	var pts: Array[Vector3] = []
	var k := 0
	while z - 40.0 * k > -820.0:
		pts.append(Vector3(x, 0.0, z - 40.0 * float(k + 1)))
		k += 1
	drv.waypoints = pts
	drv.target_speed = speed
	car.set_controller(drv)
	return car


## Primul moment (s) in care progresul (-z) al rularii `r` trece de `p`.
static func time_at_progress(r: Rec, p: float) -> float:
	for i in range(1, r.size()):
		if -r.z[i] >= p:
			var a := -r.z[i - 1]
			var b := -r.z[i]
			var f := (p - a) / maxf(b - a, 0.000001)
			return lerpf(r.t[i - 1], r.t[i], f)
	return INF


## Analiza loviturii `hit` fata de `ctrl`, cu atingerea la `t_hit` (s).
static func analyze(hit: Rec, ctrl: Rec, t_hit: float) -> Dictionary:
	var n := mini(hit.size(), ctrl.size())
	var i_hit := 0
	while i_hit < n and hit.t[i_hit] < t_hit:
		i_hit += 1
	if i_hit >= n - 1:
		return {}
	var i_before := maxi(i_hit - 60, 0)
	var v_before := hit.spd[i_before]
	var i_win := mini(i_hit + int(IMPACT_WINDOW / STEP), n - 1)
	var v_min := INF
	for i in range(i_hit, i_win + 1):
		v_min = minf(v_min, hit.spd[i])
	var i_end := mini(i_hit + int(LOSS_WINDOW / STEP), n - 1)
	var v_min3 := INF
	for i in range(i_hit, mini(i_hit + 180, n - 1) + 1):
		v_min3 = minf(v_min3, hit.spd[i])
	var lat_max := 0.0
	var yaw_max := 0.0
	var x_abs_max := 0.0
	var up_min := 1.0
	var v_peak := 0.0
	var spin_max := 0.0
	var crush_max := 0.0
	var y_roll := -INF
	for i in range(i_before, i_hit + 1):
		y_roll = maxf(y_roll, hit.y[i])
	var y_air := -INF
	var flipped_s := 0.0
	var flipped_run := 0.0
	var flipped_run_max := 0.0
	for i in range(i_hit, i_end + 1):
		lat_max = maxf(lat_max, absf(hit.x[i] - ctrl.x[i]))
		yaw_max = maxf(yaw_max, absf(wrapf(hit.yaw[i] - ctrl.yaw[i], -PI, PI)))
		x_abs_max = maxf(x_abs_max, absf(hit.x[i]))
		up_min = minf(up_min, hit.up[i])
		v_peak = maxf(v_peak, hit.spd[i])
		spin_max = maxf(spin_max, hit.spin[i])
		crush_max = maxf(crush_max, hit.crush[i])
		if i <= i_hit + 60:
			y_air = maxf(y_air, hit.y[i])
		# Regula de repunere din race.gd: rasturnata (cos < 0.3) si sub 4 m/s.
		if hit.up[i] < 0.3 and hit.spd[i] < 4.0:
			flipped_s += STEP
			flipped_run += STEP
			flipped_run_max = maxf(flipped_run_max, flipped_run)
		else:
			flipped_run = 0.0
	# Timpul de revenire: ultimul cadru in care viteza e sub 90% din control (si
	# deviatia laterala peste 0.5 m), pana la capatul ferestrei.
	var last_bad := i_hit
	for i in range(i_hit, i_end + 1):
		if hit.spd[i] < 0.9 * ctrl.spd[i] \
				or absf(hit.x[i] - ctrl.x[i]) > 0.5:
			last_bad = i
	var recover_s := INF if last_bad >= i_end else (hit.t[last_bad + 1] - t_hit)
	# Pierderea de timp: cand ajunge CONTROLUL la pozitia la care e masina
	# lovita la capatul ferestrei.
	var p_end := -hit.z[i_end]
	var t_c := time_at_progress(ctrl, p_end)
	var loss := (hit.t[i_end] - t_c) if t_c != INF else INF
	return {
		"v_before": v_before,
		"v_min": v_min,
		"kept": v_min / maxf(v_before, 0.01),
		"v_min3": v_min3,
		"lat_max": lat_max,
		"lat_end": hit.x[i_end] - ctrl.x[i_end],
		"yaw_max_deg": rad_to_deg(yaw_max),
		"yaw_end_deg": rad_to_deg(wrapf(hit.yaw[i_end] - ctrl.yaw[i_end], -PI, PI)),
		"x_abs_max": x_abs_max,
		"up_min": up_min,
		"tilt_max_deg": rad_to_deg(acos(clampf(up_min, -1.0, 1.0))),
		"flipped_s": flipped_s,
		"flipped_run": flipped_run_max,
		"recover_s": recover_s,
		"loss": loss,
		"v_peak": v_peak,
		"spin_max": spin_max,
		"crush_max": crush_max,
		"rise": y_air - y_roll,
		"v_end": hit.spd[i_end],
		"v_end_ctrl": ctrl.spd[i_end],
		"n": n,
	}
