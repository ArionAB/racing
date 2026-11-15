extends Node
## Calibrarea masinilor parcate din San Francisco (Track25, brief san_francisco.md §3, §7 pasul 6):
## cat costa o masina parcata lovita (tinta ~ +0,3 s) si cum raspunde la masa masinii care o
## loveste (Autobuzul o arunca, Politia ricoseaza).
##
## Pe un teren plat, fara pista: o masina de joc pleaca cu `--speed` m/s pe linia z = 0 (pilot
## care tine gazul la fund si linia, si o reia dupa lovitura), iar la x = 60 sta o masina parcata
## PERPENDICULAR pe drum, cu botul intrat `--overlaps` metri in latimea masinii (0 = o atinge cu
## oglinda). Masoara, fata de aceeasi trecere fara masina parcata:
##   - pierderea de timp pana la x = 160 (s);
##   - viteza imediat dupa lovitura (raport), unghiul de ricoseu (yaw) si ejectarea;
##   - cat a fost aruncata masina parcata (m) si cu ce viteza maxima.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfParked.tscn -- \
##       --masses=80,140,200 --overlaps=0.4,1.0,1.8 --cars=0,1,2 --speed=30
## `--cars` = indici GameState.CAR_DATA (implicit: toate). Exit 1 daca nicio lovitura n-a trezit
## masina parcata (sonda care nu loveste nimic e goala, nu verde).

const ParkedCar := preload("res://scenes/props/sf_parked_car.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const STEP: float = 1.0 / 60.0
const X_PARK: float = 60.0
const X_END: float = 160.0


class LineController extends CarController:
	func get_steer() -> float:
		var p := car.global_position
		var f := -car.global_transform.basis.z
		f.y = 0.0
		if f.length() < 0.01:
			return 0.0
		var t := Vector3(p.x + 14.0, p.y, 0.0) - p
		t.y = 0.0
		var ang := atan2(f.normalized().cross(t.normalized()).y, f.normalized().dot(t.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0


var _masses: Array[float] = [80.0, 140.0, 200.0]
var _overlaps: Array[float] = [0.4, 1.0, 1.8]
var _cars: Array[int] = []
var _speed: float = 30.0
var _woken: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--masses="):
			_masses.clear()
			for s in arg.trim_prefix("--masses=").split(","):
				_masses.append(float(s))
		elif arg.begins_with("--overlaps="):
			_overlaps.clear()
			for s in arg.trim_prefix("--overlaps=").split(","):
				_overlaps.append(float(s))
		elif arg.begins_with("--cars="):
			for s in arg.trim_prefix("--cars=").split(","):
				_cars.append(int(s))
		elif arg.begins_with("--speed="):
			_speed = float(arg.trim_prefix("--speed="))
	if _cars.is_empty():
		for i in GameState.CAR_DATA.size():
			_cars.append(i)
	add_child(_ground())
	await get_tree().physics_frame
	print("")
	print("=== MASINI PARCATE — lovitura la %.0f m/s, masina parcata perpendiculara, botul intrat in banda ===" % _speed)
	print("  masina        masa_m | masa_p  intrat | pierdere_s  v_dupa/v0  yaw_dupa  ejectat | aruncata_m  v_max_p")
	var all_loss: Dictionary = {}
	for ci in _cars:
		var data: CarData = GameState.CAR_DATA[ci]
		var base: Dictionary = await _run(ci, -1.0, 0.0)
		for m in _masses:
			for ov in _overlaps:
				var r: Dictionary = await _run(ci, m, ov)
				var loss := float(r["t"]) - float(base["t"])
				var key := "%.0f" % m
				if not all_loss.has(key):
					all_loss[key] = []
				(all_loss[key] as Array).append(loss)
				print("  %-12s  %4.0f   | %4.0f   %4.1f   |   %+5.2f      %4.2f     %+5.0f     %s   |   %5.1f     %5.1f" % [
					data.display_name.left(12), data.mass_factor * 100.0, m, ov, loss,
					float(r["v_after"]) / maxf(_speed, 0.1), float(r["yaw"]), "DA " if bool(r["eject"]) else "nu ",
					float(r["thrown"]), float(r["pv_max"])])
	print("")
	print("  pierderea pe masa masinii parcate (toate masinile si intrarile): mediana / max")
	for key: String in all_loss:
		var a: Array = all_loss[key]
		a.sort()
		print("    %4s kg: %+5.2f s / %+5.2f s  (%d lovituri)" % [key, float(a[a.size() / 2]), float(a[a.size() - 1]), a.size()])
	print("  masini parcate trezite: %d" % _woken)
	get_tree().quit(0 if _woken > 0 else 1)


func _ground() -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2400, 1, 2400)
	cs.shape = sh
	b.add_child(cs)
	b.position = Vector3(0, -0.5, 0)
	return b


## O trecere. `mass` < 0 = fara masina parcata (linia de baza).
func _run(ci: int, mass: float, overlap: float) -> Dictionary:
	var data: CarData = GameState.CAR_DATA[ci]
	var holder := Node3D.new()
	add_child(holder)
	var parked = null
	var body: RigidBody3D = null
	if mass > 0.0:
		parked = ParkedCar.new()
		parked.mass_kg = mass
		parked.go_home = false
		parked.snap_to_ground = false
		var half_w := data.body_width * 0.5
		# perpendiculara pe drum: lunga pe Z; botul (capatul spre z mic) la half_w - overlap
		var z_c := half_w - overlap + ParkedCar.LENGTH * 0.5
		parked.transform = Transform3D(Basis.IDENTITY, Vector3(X_PARK, 0.0, z_c))
		holder.add_child(parked)
		for _f in 3:
			await get_tree().physics_frame
		for c in parked.get_children():
			if c is RigidBody3D:
				body = c
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	holder.add_child(car)
	car.apply_data(data)
	car.global_transform = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), Vector3(0, 0.6, 0))
	car.set_controller(LineController.new())
	car.race_active = true
	car.velocity = Vector3(_speed, 0, 0)
	car.linear_velocity = Vector3(_speed, 0, 0)
	var ev := {"eject": false}
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: ev["eject"] = true)
	var t := 0.0
	var v_after := -1.0
	var yaw := 0.0
	var pv_max := 0.0
	var home := body.global_position if body != null else Vector3.ZERO
	var hit_t := -1.0
	while t < 20.0:
		await get_tree().physics_frame
		t += STEP
		var p := car.global_position
		if body != null:
			pv_max = maxf(pv_max, body.linear_velocity.length())
			if hit_t < 0.0 and not body.sleeping and body.linear_velocity.length() > 0.5:
				hit_t = t
				_woken += 1
			if hit_t > 0.0 and v_after < 0.0 and t - hit_t > 0.25:
				v_after = Vector2(car.linear_velocity.x, car.linear_velocity.z).length()
				var f := -car.global_transform.basis.z
				yaw = rad_to_deg(atan2(-f.z, f.x))
		if p.x >= X_END:
			break
	var thrown := body.global_position.distance_to(home) if body != null else 0.0
	holder.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	return {"t": t, "v_after": v_after if v_after >= 0.0 else _speed, "yaw": yaw, "eject": ev["eject"],
		"thrown": thrown, "pv_max": pv_max}
