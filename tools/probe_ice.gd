extends Node
## Sonda DRUMULUI DE GHEATA (Baikal, docs/track_briefs/baikal.md).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeIce.tscn [-- --track=3]
##
## Ce verifica, pe pista reala:
##
##   1. INTERVALUL RASPUNDE: `is_ice_at` e adevarat pe gheata si fals pe mal.
##   2. SE CONSTRUIESTE ALTFEL: exista mesh-ul "IceRoad", betele cu stegulete si
##      corpul de coliziune al placii ("IceSheet") — deci gheata nu e doar o
##      cifra de grip, e o suprafata pe care o vezi si pe care calci.
##   3. GRIP-UL SCADE PE MASINA: pe gheata masina primeste alunecare cu grip-ul
##      temei; pe mal, nimic.
##   4. VANTUL SUFLA DOAR PE GHEATA: `wind_at` nenul pe gheata, zero pe mal.
##   5. SE SIMTE: aceeasi masina, acelasi viraj (volan la maxim, 1.2 s, de la
##      30 m/s) — pe gheata unghiul dintre bot si viteza (unghiul de derapaj)
##      trebuie sa fie CLAR mai mare decat pe asfalt. Asta e chiar promisiunea:
##      pe gheata aluneci, nu doar „ai mai putin grip" intr-un tabel.

func _ready() -> void:
	await get_tree().process_frame
	var idx := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var failed := false
	print("\n=== ProbeIce — %s ===" % track.track_name)

	var ranges := track._ice_ranges()
	if ranges.is_empty():
		print("pista n-are intervale de gheata — nimic de verificat")
		get_tree().quit(1)
		return
	var seg: Vector2 = ranges[0]
	var f_ice := fposmod(seg.x + 0.4 * (seg.y - seg.x), 1.0)
	var f_land := fposmod(seg.y + 0.15, 1.0)
	if track.is_ice_at(f_land):
		f_land = fposmod(seg.x - 0.10, 1.0)

	# 1
	var ok1 := track.is_ice_at(f_ice) and not track.is_ice_at(f_land)
	failed = failed or not ok1
	print("1. interval: gheata la %.2f -> %s, mal la %.2f -> %s  %s" % [
		f_ice, track.is_ice_at(f_ice), f_land, track.is_ice_at(f_land),
		"OK" if ok1 else "PROBLEMA"])

	# 2
	var has_road := track.get_node_or_null("IceRoad") != null
	var has_flags := track.get_node_or_null("IceFlags") != null
	var has_sheet := track.get_node_or_null("Sea/IceSheet") != null
	var ok2 := has_road and has_flags and has_sheet
	failed = failed or not ok2
	print("2. constructie: IceRoad %s, IceFlags %s, Sea/IceSheet %s  %s" % [
		has_road, has_flags, has_sheet, "OK" if ok2 else "PROBLEMA"])

	# 3 + 4
	var car_scene: PackedScene = load("res://scenes/cars/Car.tscn")
	var car: Car = car_scene.instantiate()
	track.add_child(car)
	car.track = track
	await get_tree().process_frame
	var n: int = track.baked.size()
	var res := {}
	for pair in [[f_ice, "gheata"], [f_land, "mal"]]:
		var f: float = pair[0]
		var i: int = int(f * float(n)) % n
		car.global_position = track.baked[i] + Vector3.UP * 0.5
		car.velocity = Vector3.ZERO
		car.route = 0
		car.road_index = i
		car.slip_time = 0.0
		for k in 8:
			await get_tree().physics_frame
		res[pair[1]] = {"slip": car.slip_time > 0.0, "grip": car.slip_grip,
			"wind": track.wind_at(f, 1.0)}
	var ice_slip: bool = res["gheata"]["slip"]
	var land_slip: bool = res["mal"]["slip"]
	var ice_grip: float = res["gheata"]["grip"]
	var want_grip := track.ice_grip() if track.ice_grip() > 0.0 else Car.SLIP_GRIP_ICE
	var ok3 := ice_slip and not land_slip and is_equal_approx(ice_grip, want_grip)
	failed = failed or not ok3
	print("3. grip: pe gheata alunecare=%s grip=%.2f (vrut %.2f); pe mal alunecare=%s  %s" % [
		ice_slip, ice_grip, want_grip, land_slip, "OK" if ok3 else "PROBLEMA"])
	var w_ice: Vector3 = res["gheata"]["wind"]
	var w_land: Vector3 = res["mal"]["wind"]
	var ok4 := w_ice.length() > 0.1 and w_land.length() < 0.001
	failed = failed or not ok4
	print("4. vant: pe gheata %.2f m/s^2, pe mal %.2f  %s" % [
		w_ice.length(), w_land.length(), "OK" if ok4 else "PROBLEMA"])

	# 5. unghiul de derapaj intr-un viraj identic
	var slip_ice := await _corner_slip(track, car, f_ice)
	var slip_land := await _corner_slip(track, car, f_land)
	var ok5 := slip_ice > slip_land + 6.0
	failed = failed or not ok5
	print("5. derapaj (volan la maxim 1.2 s de la 30 m/s): gheata %.1f°, asfalt %.1f°  %s" % [
		slip_ice, slip_land, "OK" if ok5 else "PROBLEMA (nu se simte diferenta)"])

	# 6. suflul hovercraftului (PathMover.push_radius): un figurant parcat pe
	# gheata impinge masina de langa el dinspre el; unul fara suflu, nu.
	var i6: int = int(f_ice * float(n)) % n
	var origin: Vector3 = track.baked[i6]
	var side6: Vector3 = track._side_at(i6)
	var pushed := await _push_test(track, car, origin, side6, 9.0)
	var still := await _push_test(track, car, origin, side6, 0.0)
	var ok6 := pushed > 1.0 and still < 0.3
	failed = failed or not ok6
	print("6. suflu (PathMover.push_radius): cu suflu masina pleaca %.2f m/s, fara %.2f  %s" % [
		pushed, still, "OK" if ok6 else "PROBLEMA"])

	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Un PathMover parcat la `origin` cu raza de suflu data; masina la 4 m lateral,
## libera. Intoarce viteza masinii dinspre figurant dupa 1 s.
func _push_test(track: Track, car: Car, origin: Vector3, side: Vector3,
		radius: float) -> float:
	var mover := PathMover.new()
	mover.push_radius = radius
	mover.push_accel = 14.0
	mover.speed = 0.0
	mover.stick_to_ground = false
	var c := Curve3D.new()
	c.add_point(Vector3.ZERO)
	c.add_point(Vector3(0, 0, 5))
	mover.curve = c
	mover.position = origin + Vector3.UP * 0.1
	track.add_child(mover)
	car.freeze = false
	car.global_transform = Transform3D(Basis.IDENTITY, origin + side * 4.0 + Vector3.UP * 0.5)
	car.velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
	car.controller = null
	car.race_active = false
	for k in 60:
		await get_tree().physics_frame
	var v := car.velocity
	v.y = 0.0
	var out := v.dot(side)
	mover.queue_free()
	await get_tree().process_frame
	return out


## Aseaza masina pe axa la fractia data, cu 30 m/s inainte, si tine volanul la
## maxim 1.2 s (controller sintetic). Intoarce unghiul, in grade, dintre bot si
## directia vitezei la sfarsit — mare = aluneca, mic = tine linia.
func _corner_slip(track: Track, car: Car, f: float) -> float:
	var n: int = track.baked.size()
	var i: int = int(f * float(n)) % n
	var dir: Vector3 = (track.baked[(i + 1) % n] - track.baked[i]).normalized()
	car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		track.baked[i] + Vector3.UP * 0.5)
	car.velocity = dir * 30.0
	car.angular_velocity = Vector3.ZERO
	car.route = 0
	car.road_index = i
	car.slip_time = 0.0
	car.race_active = true
	var ctl := _SteerController.new()
	car.controller = ctl
	for k in int(1.2 * 60.0):
		await get_tree().physics_frame
	car.controller = null
	car.race_active = false
	var fwd: Vector3 = -car.global_transform.basis.z
	var v: Vector3 = car.velocity
	fwd.y = 0.0; v.y = 0.0
	if v.length() < 0.5:
		return 0.0
	return rad_to_deg(fwd.normalized().angle_to(v.normalized()))


class _SteerController extends CarController:
	func get_steer() -> float:
		return 1.0
	func get_throttle() -> float:
		return 1.0
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false
