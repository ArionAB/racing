extends Node
## Sonda telecabinei (Chongqing, brief §3 „riscul nr. 2"): poate o masina
## REALA (Car.tscn, RigidBody3D cu suspensie pe raycast) sa stea pe o
## cabina-platforma mobila (AnimatableBody3D, sync_to_physics sub Jolt) pe o
## traversare de 150 m orizontal si +25 m urcare in 8 s, si sa plece pe roti
## la etajul de sus? Verdictul decide intre platforma si fallback-ul din brief
## (cabinele ca obstacole mobile).
##
## Pista-test din TrackFromPath: o bucla cu dreapta de jos pe z=0 (y=0) si
## dreapta de sus pe z=-172 (y=25); cablul leaga cele doua drepte, cu un turn
## la mijloc. Masina A e asezata pe cabina in fereastra de imbarcare; masina
## B ajunge la peron dupa plecare.
##
##  (i)   A ramane pe podea toata traversarea: abaterea pozitiei ei fata de
##        cabina < 0.5 m orizontal, rotile pe podea, fara cadere.
##  (ii)  la sosire A iese pe drum si isi gaseste indexul pe etajul de sus in
##        < 1 s (indexul e pe cota 25), apoi e „pe sosea" sus.
##  (iii) plecarea/sosirea nu o arunca: |viteza verticala| < 6 m/s tot drumul.
##  (iv)  B, ajunsa dupa fereastra, nu e la bord si ramane pe peron.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCableway.tscn
## Iese cu cod 1 la orice verdict picat.

const CablewayScript := preload("res://scenes/hazards/cableway_hazard.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const POINTS: Array[Vector3] = [
	Vector3(-80, 0, 0), Vector3(100, 0, 0), Vector3(170, 3, -50),
	Vector3(190, 12, -120), Vector3(150, 25, -172), Vector3(60, 25, -172),
	Vector3(0, 25, -172), Vector3(-80, 20, -130), Vector3(-120, 10, -60),
	Vector3(-110, 2, -15),
]
const BOTTOM := Vector3(60, 0, -14)
const MID := Vector3(60, 13, -89)
const TOP := Vector3(60, 25, -164)
const DOCK_BOTTOM := Vector3(60, 0, -8)
const MAX_DRIFT: float = 0.5
const MAX_VY: float = 6.0
const UPPER_MIN_Y: float = 24.0

var _track: ProbeTrack
var _hazard: CablewayScript
var _fails: int = 0


## Pista-test cu parapetul deschis pe latura golfului: `_rail_segments` nu e
## export pe TrackFromPath (e declaratie per pista, ca pe Alpi), iar fara gol
## cabina ar cara masina PRIN zidul de pe buza etajului de sus — masurat:
## aruncata cu 13 m/s la sosire. Pe Chongqing statia sta pe o banda
## TrackBranch, ale carei jonctiuni deschid parapetul singure.
class ProbeTrack extends TrackFromPath:
	var rails: Array[Vector4] = []
	func _rail_segments() -> Array[Vector4]:
		return rails


class ProbeDriver extends CarController:
	var throttle: float = 0.0
	func get_throttle() -> float:
		return throttle
	func get_steer() -> float:
		return 0.0


func _ready() -> void:
	_track = ProbeTrack.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeCableway"
	_track.custom_theme = "forest"
	_track.custom_half_width = 6.0
	add_child(_track)
	await get_tree().process_frame
	# GOLFUL: fara declaratie, media cotelor drumului ridica un deal intre cele
	# doua etaje prin care cabina ar zbura (masurat: teren la 23 m sub un cablu
	# la 15). O rapa-cornisa de 25 m pe latura golfului a etajului de sus sapa
	# terenul la cota cheiului — pe Chongqing acolo e apa. Pe aceeasi latura,
	# parapetul se deschide (RAIL_NONE), altfel zidul de pe buza sta intre
	# cabina si drum.
	var upper := _upper_range()
	var side := _gulf_side()
	_track.custom_ravines = [Vector4(upper.x, upper.y, TOP.y - BOTTOM.y, side)]
	_track.custom_cornice_ravines = [0]
	_track.rails = [Vector4(upper.x, upper.y, float(Track.RAIL_NONE), side)]
	_track.rebuild()
	await get_tree().process_frame
	print("  etajul de sus: fractii %.3f..%.3f, latura golfului %+.0f" % [upper.x, upper.y, side])

	_hazard = CablewayScript.new()
	_hazard.name = "Cableway"
	var route := Path3D.new()
	route.name = "Route"
	var rc := Curve3D.new()
	for p in [BOTTOM, MID, TOP]:
		rc.add_point(p)
	route.curve = rc
	_hazard.add_child(route)
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== TELECABINA: platforma mobila cu masina reala ===")
	print("  cablu %s -> %s: %.0f m orizontal, %+.0f m; period %.0f s, imbarcare %.0f s, traversare %.0f s"
		% [str(BOTTOM), str(TOP), Vector2(TOP.x - BOTTOM.x, TOP.z - BOTTOM.z).length(),
		TOP.y - BOTTOM.y, _hazard.period, _hazard.boarding_window, _hazard.travel_time])
	_print_terrain()
	await _run()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Intervalul de fractii al dreptei de sus (tot ce sta peste UPPER_MIN_Y).
func _upper_range() -> Vector2:
	var first := -1
	var last := -1
	for i in _track.baked.size():
		if _track.baked[i].y >= UPPER_MIN_Y:
			if first < 0:
				first = i
			last = i
	return Vector2(_track.frac_at(first), _track.frac_at(last))


## Semnul laturii drumului de sus care da spre statia de jos.
func _gulf_side() -> float:
	var i := _track.closest_index_global(TOP, 0)
	var sampler: TrackSideSampler = _track.get("_sampler")
	var sd: Vector3 = sampler.side_at(i)
	var p: Vector3 = _track.baked[i]
	return signf(Vector2(sd.x, sd.z).dot(Vector2(BOTTOM.x - p.x, BOTTOM.z - p.z)))


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


## Terenul sub cablu: cabina trebuie sa zboare PESTE el, nu prin el.
func _print_terrain() -> void:
	var sampler: TrackSideSampler = _track.get("_sampler")
	var worst := -INF
	for k in 11:
		var s := float(k) / 10.0
		var p := _hazard.station_bottom().lerp(_hazard.station_top(), s)
		var g := sampler.ground_y(p.x, p.z)
		worst = maxf(worst, g - p.y)
		if k % 2 == 0:
			print("    cablu s=%.1f cabina y=%.1f teren %.1f" % [s, p.y, g])
	print("  teren fata de podeaua cabinei, max %+.1f m (coarda dreapta; traseul real trece pe turn)" % worst)


func _spawn(at: Vector3) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3.ZERO
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	return car


func _wait_state(st: int, timeout: float = 30.0) -> bool:
	var frames := int(timeout * 60.0)
	for _f in frames:
		if _hazard.state() == st:
			return true
		await get_tree().physics_frame
	return false


func _run() -> void:
	# Ciclul incepe cu IMBARCAREA; A se aseaza pe podea in fereastra.
	await _wait_state(CablewayScript.State.BOARDING)
	var a := _spawn(BOTTOM + Vector3(0, 0.6, 0))
	var driver := ProbeDriver.new()
	a.set_controller(driver)
	for _f in 60:
		await get_tree().physics_frame
	var body := _hazard.body()
	var idx_lo := a.road_index
	print("--- imbarcare: A pe podea la t=%.2f, y=%.2f, roti pe sol %d, index %d (cota drum %.1f), stare %d"
		% [_hazard.cycle_time(), a.global_position.y, a.wheels_on_ground, idx_lo,
		_track.baked[idx_lo].y, _hazard.state()])
	_verdict(a.wheels_on_ground == 4 and absf(a.global_position.y - BOTTOM.y) < 0.3,
		"A sta pe podeaua cabinei inainte de plecare (y=%.2f, roti %d)" % [a.global_position.y, a.wheels_on_ground])

	# --- (i) + (iii): traversarea
	var ok_up := await _wait_state(CablewayScript.State.UP, 5.0)
	_verdict(ok_up, "cabina pleaca (stare UP)")
	var anchor := body.to_local(a.global_position)
	var max_drift := 0.0
	var max_dy := 0.0
	var min_dy := 0.0
	var max_vy := 0.0
	var frames_off_floor := 0
	var b: Car = null
	var b_spawned_t := -1.0
	var t0 := _hazard.cycle_time()
	var samples := 0
	var max_plat_speed := 0.0
	var max_gv_err := 0.0
	while _hazard.state() == CablewayScript.State.UP:
		await get_tree().physics_frame
		samples += 1
		var local := body.to_local(a.global_position)
		var d := Vector2(local.x - anchor.x, local.z - anchor.z).length()
		max_drift = maxf(max_drift, d)
		max_dy = maxf(max_dy, local.y - anchor.y)
		min_dy = minf(min_dy, local.y - anchor.y)
		max_vy = maxf(max_vy, absf(a.velocity.y))
		max_plat_speed = maxf(max_plat_speed, _hazard.velocity().length())
		if a.wheels_on_ground > 0 and absf(local.y - anchor.y) < 1.0:
			max_gv_err = maxf(max_gv_err, (a.ground_velocity() - _hazard.velocity()).length())
		if a.wheels_on_ground < 3:
			frames_off_floor += 1
		if samples % 60 == 0:
			print("    t=%5.2f cabina y=%5.1f v=%5.1f m/s | A local (%+.2f, %+.2f, %+.2f) roti %d vy %+.2f"
				% [_hazard.cycle_time(), body.global_position.y, _hazard.velocity().length(),
				local.x - anchor.x, local.y - anchor.y, local.z - anchor.z,
				a.wheels_on_ground, a.velocity.y])
		# (iv): B ajunge la peronul de jos la 1 s dupa plecare.
		if b == null and _hazard.cycle_time() - t0 > 1.0:
			b = _spawn(DOCK_BOTTOM + Vector3(0, 0.6, 0))
			b_spawned_t = _hazard.cycle_time()
	print("--- (i) traversare: %d cadre, viteza maxima a cabinei %.1f m/s" % [samples, max_plat_speed])
	print("    abatere orizontala max %.3f m, verticala [%+.2f, %+.2f] m, cadre cu <3 roti pe podea: %d"
		% [max_drift, min_dy, max_dy, frames_off_floor])
	print("    viteza solului citita de roti vs cabina: eroare max %.2f m/s" % max_gv_err)
	_verdict(max_drift < MAX_DRIFT, "A ramane pe locul ei pe podea (abatere %.3f < %.1f m)" % [max_drift, MAX_DRIFT])
	_verdict(min_dy > -0.3 and max_dy < 1.0, "A nu cade prin podea si nu sare (dy in [%+.2f, %+.2f])" % [min_dy, max_dy])
	_verdict(frames_off_floor <= 6, "rotile raman pe podea (%d cadre fara contact)" % frames_off_floor)
	_verdict(a.global_position.y > TOP.y - 1.0, "A a ajuns sus cu cabina (y=%.1f, statia %.1f)" % [a.global_position.y, TOP.y])
	print("--- (iii) plecare/sosire: |vy| max %.2f m/s" % max_vy)
	_verdict(max_vy < MAX_VY, "A nu e aruncata (|vy| max %.2f < %.0f m/s)" % [max_vy, MAX_VY])

	# --- (ii): la sosire, indexul si iesirea pe drum
	var t_arrive := _hazard.cycle_time()
	var t_index := -1.0
	var t_road := -1.0
	driver.throttle = 1.0
	var vy_exit := 0.0
	for _f in 300:
		await get_tree().physics_frame
		var el := _hazard.cycle_time() - t_arrive
		vy_exit = maxf(vy_exit, absf(a.velocity.y))
		if _f % 30 == 0:
			print("    +%.2f s stare %d | A %s v=%s roti %d fata %s sol_v %s"
				% [el, _hazard.state(), str(a.global_position.snapped(Vector3.ONE * 0.01)),
				str(a.velocity.snapped(Vector3.ONE * 0.01)), a.wheels_on_ground,
				str((-a.global_transform.basis.z).snapped(Vector3.ONE * 0.01)),
				str(a.ground_velocity().snapped(Vector3.ONE * 0.01))])
		if t_index < 0.0 and _track.baked[a.road_index].y > TOP.y - 3.0:
			t_index = el
		if t_road < 0.0 and _track.is_on_road(a.road_index, a.global_position, 0):
			t_road = el
			break
	print("--- (ii) sosire: index %d (cota drum %.1f) dupa %.2f s; pe sosea sus dupa %.2f s; pozitie %s; |vy| max la iesire %.2f"
		% [a.road_index, _track.baked[a.road_index].y, t_index, t_road, str(a.global_position.round()), vy_exit])
	_verdict(t_index >= 0.0 and t_index < 1.0, "indexul e pe etajul de sus in < 1 s (%.2f s)" % t_index)
	_verdict(t_road >= 0.0 and t_road < 4.0, "A iese pe drum sus (%.2f s)" % t_road)
	_verdict(vy_exit < MAX_VY, "iesirea nu o arunca (|vy| max %.2f)" % vy_exit)
	for _f in 60:
		await get_tree().physics_frame
	print("    dupa inca 1 s: index %d, checkpoint %d (cota %.1f), y=%.1f, viteza %.1f m/s"
		% [a.road_index, a.last_safe_index, _track.baked[a.last_safe_index].y,
		a.global_position.y, a.horizontal_speed()])
	_verdict(_track.baked[a.last_safe_index].y > TOP.y - 3.0, "checkpoint-ul s-a mutat pe etajul de sus")

	# --- (iv): B
	var b_aboard := _hazard.aboard().has(b)
	var b_d := Vector2(b.global_position.x - DOCK_BOTTOM.x, b.global_position.z - DOCK_BOTTOM.z).length()
	print("--- (iv) B ajunsa la t=%.2f (plecarea la %.2f): la bord=%s, y=%.2f, la %.2f m de peron, cabina la %.0f m"
		% [b_spawned_t, t0, str(b_aboard), b.global_position.y, b_d,
		b.global_position.distance_to(body.global_position)])
	_verdict(not b_aboard, "B nu e la bord")
	_verdict(b.global_position.y > DOCK_BOTTOM.y - 0.5 and b_d < 3.0, "B ramane pe peron (y=%.2f, %.2f m)" % [b.global_position.y, b_d])
