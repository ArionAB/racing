extends Node
## Piesa bump-abila INALTA (`BumpProp.wrap` cu `max_height`), brief san_francisco.md §7 pasul 6:
## duba parcata din foaia de assets (mai inalta de 1,8 m) trebuie sa poata fi `BumpProp`, nu zid.
##
## Pe teren plat, fara pista: o cutie de 1,9 x 2,4 x 4,2 m (duba) sta PERPENDICULAR pe drum, cu
## botul intrat `overlap` m in latimea masinii (sau LATERAL, cu flancul spre drum), iar o masina de
## joc o loveste la 30 m/s si tine linia. Verifica, pe fiecare lovitura:
##   1. 0 ejectari ale soferului;
##   2. piesa lovita se misca: alunecata (>= 0,5 m) sau rasturnata (axa ei verticala trece de 45 de
##      grade), ori e doar razuita (masina nu pierde nici 20 % din viteza);
##   3. nu e zid: masina ajunge la x = 160 in < 12 s si nu ramane sub 3 m/s mai mult de 1 s;
##   4. masina nu ramane BLOCATA sub piesa (sub talpa ei ridicata si sub 3 m/s). O duba rasturnata
##      care zboara peste masina nu e blocaj.
## Plus SABOTAJUL, care trebuie sa ramana adevarat: fara `max_height` in `opts`, aceeasi cutie e
## REFUZATA (`wrap` intoarce null) — plafonul de 1,8 m e neschimbat pentru celelalte piste.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBumpTall.tscn [-- --masses=70,140]

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const STEP: float = 1.0 / 60.0
const SIZE := Vector3(1.9, 2.4, 4.2)
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


var _fail: int = 0


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
	if not ok:
		_fail += 1


func _ready() -> void:
	var masses: Array[float] = [70.0, 140.0]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--masses="):
			masses.clear()
			for s in arg.trim_prefix("--masses=").split(","):
				masses.append(float(s))
	add_child(_ground())
	await get_tree().physics_frame
	print("")
	print("=== PIESA BUMP-ABILA INALTA (%.1f x %.1f x %.1f m), lovita la 30 m/s ===" % [SIZE.x, SIZE.y, SIZE.z])
	# SABOTAJUL: fara `max_height`, aceeasi cutie e refuzata
	var h := Node3D.new()
	add_child(h)
	var m0 := _van(h, Vector3(X_PARK, 0, 20.0), 0.0)
	var refused := BumpProp.wrap(m0, {"mass": 70.0, "max_footprint": 4.5}) == null
	h.queue_free()
	_check(refused, "fara `max_height`, piesa de %.1f m e refuzata (plafonul de 1,8 m neschimbat)" % SIZE.y)
	print("  masina        masa_p  pozitie   intrat | ejectat  alunecata  rasturnata  timp_x160  oprit>1s  sub_piesa")
	var n := 0
	var ej := 0
	var moved := 0
	var hit := 0
	var walls := 0
	var under := 0
	for ci in [1, 2, 3, 5, 9]:
		for mass in masses:
			for pose in ["perpendicular", "lateral"]:
				for ov in [0.6, 1.2, 2.0]:
					var r: Dictionary = await _run(ci, mass, pose, ov)
					n += 1
					var data: CarData = GameState.CAR_DATA[ci]
					if bool(r["eject"]):
						ej += 1
					if bool(r["woke"]):
						hit += 1
						if float(r["slid"]) >= 0.5 or float(r["tilt"]) >= 45.0 or float(r["v_min"]) >= 24.0:
							moved += 1
					if float(r["t"]) >= 12.0 or float(r["stuck"]) > 1.0:
						walls += 1
					if bool(r["under"]):
						under += 1
					print("  %-12s  %4.0f   %-13s %4.1f  |  %s     %5.1f m    %5.0f gr     %5.2f s    %4.1f s    %s" % [
						data.display_name.left(12), mass, pose, ov, "DA" if bool(r["eject"]) else "nu",
						float(r["slid"]), float(r["tilt"]), float(r["t"]), float(r["stuck"]),
						"DA" if bool(r["under"]) else "nu"])
	print("")
	_check(ej == 0, "ejectari: %d din %d lovituri" % [ej, n])
	_check(hit > 0 and moved == hit, "piesa lovita: urnita (alunecata >= 0,5 m / rasturnata >= 45 gr) sau doar razuita (masina sub 20%% pierdere de viteza): %d din %d lovituri (%d treceri doar razand-o, fara s-o trezeasca)" % [moved, hit, n - hit])
	_check(walls == 0, "piesa ca zid (masina la x 160 dupa > 12 s sau oprita > 1 s): %d din %d" % [walls, n])
	_check(under == 0, "masina blocata sub piesa: %d din %d" % [under, n])
	print("VERDICT: %s" % ("OK" if _fail == 0 else "PICAT (%d)" % _fail))
	get_tree().quit(0 if _fail == 0 else 1)


func _ground() -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2400, 1, 2400)
	cs.shape = sh
	b.add_child(cs)
	b.position = Vector3(0, -0.5, 0)
	return b


## Duba: o cutie (originea la talpa) sub `parent`, rotita `yaw` in jurul verticalei.
func _van(parent: Node3D, at: Vector3, yaw: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = SIZE
	mi.mesh = bm
	parent.add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	# BoxMesh e centrat: ridicat cu jumatate din inaltime, talpa la cota solului
	mi.mesh = _lifted(bm)
	return mi


static func _lifted(bm: BoxMesh) -> ArrayMesh:
	var arrays := bm.get_mesh_arrays()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i].y += SIZE.y * 0.5
	arrays[Mesh.ARRAY_VERTEX] = v
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


func _run(ci: int, mass: float, pose: String, overlap: float) -> Dictionary:
	var data: CarData = GameState.CAR_DATA[ci]
	var holder := Node3D.new()
	add_child(holder)
	var half_w := data.body_width * 0.5
	# perpendicular: lunga pe Z, botul (capatul spre z mic) intrat `overlap` in latimea masinii;
	# lateral: lunga pe X (paralela cu drumul), flancul intrat `overlap`
	var depth := SIZE.z if pose == "perpendicular" else SIZE.x
	var z_c := half_w - overlap + depth * 0.5
	var mi := _van(holder, Vector3(X_PARK, 0.0, z_c), 0.0 if pose == "perpendicular" else PI * 0.5)
	var body := BumpProp.wrap(mi, {"mass": mass, "max_footprint": 4.5, "max_height": 2.6})
	for _f in 3:
		await get_tree().physics_frame
	var home := body.global_position if body != null else Vector3.ZERO
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	holder.add_child(car)
	car.apply_data(data)
	car.global_transform = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), Vector3(0, 0.6, 0))
	car.set_controller(LineController.new())
	car.race_active = true
	car.velocity = Vector3(30, 0, 0)
	car.linear_velocity = Vector3(30, 0, 0)
	var ev := {"eject": false}
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: ev["eject"] = true)
	var t := 0.0
	var stuck := 0.0
	var stuck_max := 0.0
	var tilt := 0.0
	var under := false
	var woke := false
	var v_min := INF
	while t < 14.0:
		await get_tree().physics_frame
		t += STEP
		var p := car.global_position
		if body != null:
			if not body.sleeping and body.linear_velocity.length() > 0.3:
				woke = true
			tilt = maxf(tilt, rad_to_deg(acos(clampf(body.global_transform.basis.y.dot(Vector3.UP), -1.0, 1.0))))
			var bp := body.global_position
			# sub piesa: centrul masinii in amprenta ei si talpa piesei ridicata peste caroserie
		var v := Vector2(car.linear_velocity.x, car.linear_velocity.z).length()
		if t > 0.5:
			v_min = minf(v_min, v)
		if body != null and t > 0.5 and v < 3.0 				and Vector2(p.x - body.global_position.x, p.z - body.global_position.z).length() < 1.5 				and body.global_position.y > p.y + 0.8:
			under = true
		if t > 0.5 and v < 3.0:
			stuck += STEP
			stuck_max = maxf(stuck_max, stuck)
		else:
			stuck = 0.0
		if p.x >= X_END:
			break
	var slid := Vector2(body.global_position.x - home.x, body.global_position.z - home.z).length() \
		if body != null else 0.0
	holder.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	return {"t": t, "eject": ev["eject"], "slid": slid, "tilt": tilt, "stuck": stuck_max, "under": under,
		"wrapped": body != null, "woke": woke, "v_min": v_min}
