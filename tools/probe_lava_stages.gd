extends Node
## SONDA TEMPORARA — de ce nu avanseaza lava pe Stromboli.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLavaStages.tscn
##
## Instantiaza Track11, se uita la LavaFlowHazard: gaseste nodurile de stadiu?
## ce e vizibil la start? apoi simuleaza tururi (on_lap_completed) si tipareste
## vizibilitatea dupa fiecare — exact ce ar face race.gd la turul jucatorului.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track11.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var lava: LavaFlowHazard = null
	for child in track.get_children():
		if child is LavaFlowHazard:
			lava = child as LavaFlowHazard
	if lava == null:
		print("NU exista niciun LavaFlowHazard printre copiii pistei!")
		get_tree().quit()
		return

	print("")
	print("=== LavaFlowHazard '%s' ===" % lava.name)
	print("stage_nodes declarate: %s" % [lava.stage_nodes])
	for i in lava._meshes.size():
		var m: Node3D = lava._meshes[i]
		if m == null:
			print("  [%d] %-12s  NEGASIT in subarbore!" % [i, lava.stage_nodes[i]])
		else:
			print("  [%d] %-12s  gasit (%s)  visible=%s" % [
				i, lava.stage_nodes[i], m.get_path(), m.visible])

	print("")
	print("copiii instantei GLB (ce nume au venit din fisier):")
	var glb := lava.get_node_or_null("lava_flow")
	if glb != null:
		_dump(glb, 1)
	else:
		print("  (nu exista copil 'lava_flow' — copiii directi:)")
		_dump(lava, 1)

	print("")
	print("=== unde AJUNG stadiile in lume (AABB global) vs scurtatura ===")
	var branch := track.get_node_or_null("ScurtaturaLavei") as Path3D
	if branch != null and branch.curve != null:
		for k in branch.curve.point_count:
			var p := branch.to_global(branch.curve.get_point_position(k))
			print("  scurtatura P%d: (%.1f, %.1f, %.1f)  teren %.1f" % [
				k, p.x, p.y, p.z, track._sampler.ground_y(p.x, p.z)])
	for i in lava._meshes.size():
		var m := lava._meshes[i] as MeshInstance3D
		if m == null:
			continue
		var ab := m.global_transform * m.get_aabb()
		print("  %s: de la (%.1f, %.1f, %.1f) pana la (%.1f, %.1f, %.1f)" % [
			lava.stage_nodes[i],
			ab.position.x, ab.position.y, ab.position.z,
			ab.end.x, ab.end.y, ab.end.z])

	print("")
	print("=== drumul principal (ocolul) in zona campului de lava ===")
	var r := track.routes[0]
	var n := r.count()
	var step := maxi(n / 160, 1)
	for i in range(0, n, step):
		var f := r.frac_at(i)
		if f < 0.60 or f > 0.76:
			continue
		var p: Vector3 = r.baked[i]
		print("  frac %.3f  (%7.1f, %5.1f, %7.1f)" % [f, p.x, p.y, p.z])

	print("")
	print("=== distante mesh -> trasee (pe vertecsii REALI, in plan XZ) ===")
	var branch_pts: PackedVector2Array = _route_xz(track, 1)
	var main_pts: PackedVector2Array = _route_xz(track, 0)
	for i in lava._meshes.size():
		var m := lava._meshes[i] as MeshInstance3D
		if m == null:
			continue
		var verts := m.mesh.get_faces()
		var d_branch := INF
		var d_main := INF
		var float_max := -INF
		var gt := m.global_transform
		for k in range(0, verts.size(), 3):
			var w := gt * verts[k]
			d_branch = minf(d_branch, _dist_to_poly(Vector2(w.x, w.z), branch_pts))
			d_main = minf(d_main, _dist_to_poly(Vector2(w.x, w.z), main_pts))
			# doar talpa (y local ~0): cat pluteste peste teren
			if verts[k].y < 0.05:
				float_max = maxf(float_max,
					w.y - track._sampler.ground_y(w.x, w.z))
		print("  %s: min pana la scurtatura %.2f m, pana la ocol %.2f m, talpa max peste teren %.2f m" % [
			lava.stage_nodes[i], d_branch, d_main, float_max])
	print("  (scurtatura: stage1 vrem >= ~4; stage2 ~2 = buzele portii; stage3 ~0 = zid)")
	print("  (ocol: toate >= ~5; talpa: sub ~0.5 vizibil din drum e ok)")

	print("")
	print("=== banda coapta vs axa culoarului (axis_pos: 26..38 = poarta) ===")
	var tail := Vector2(-219.2, 452.6)
	var df := Vector2(0.902, 0.429)
	var nf := Vector2(-0.429, 0.902)
	if track.routes.size() >= 2:
		var last_a := -INF
		for p in track.routes[1].baked:
			var v := Vector2(p.x, p.z) - tail
			var a := v.dot(df)
			var o := v.dot(nf)
			if a >= 20.0 and a <= 42.0 and a - last_a >= 1.9:
				last_a = a
				print("  axa %5.1f m  offset %+.2f m" % [a, o])

	print("")
	print("=== gabaritul masinii pe scurtatura, per stadiu ===")
	for stage in 3:
		while lava.current_stage() < stage:
			lava.on_lap_completed()
		for k in 4:
			await get_tree().physics_frame
		print("stadiul %d (%s, shortcut_open=%s):" % [
			stage, _visible_list(lava), lava.shortcut_open()])
		for width: float in [2.4, 1.9]:
			var touches := _sweep_branch(track, width)
			if touches.is_empty():
				print("  gabarit %.1f m: trece liber" % width)
			else:
				for t: Array in touches:
					print("  gabarit %.1f m: ATINGE %s la frac %.2f din banda" % [
						width, t[0], t[1]])

	# Proba de ARDERE: masina reala, fara controller, lansata pe scurtatura.
	# In zidul stadiului 3 (stadiul curent dupa bucla de mai sus) trebuie sa
	# fie repusa DIN STAND (scorch); apoi, pe o pista proaspata adusa la
	# stadiul portii, o masina centrata trebuie sa treaca nearsa.
	print("")
	print("=== proba de ardere (Car real pe scurtatura) ===")
	await _scorch_case(track, "zidul (stadiul 2)", true)
	track.queue_free()
	await get_tree().process_frame
	track = scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	for child in track.get_children():
		if child is LavaFlowHazard:
			(child as LavaFlowHazard).on_lap_completed()
	for k in 4:
		await get_tree().physics_frame
	await _scorch_case(track, "poarta (stadiul 1)", false)
	get_tree().quit()


## Lanseaza o masina reala pe scurtatura, drept inainte, si raporteaza daca a
## fost arsa (repusa) in `seconds`. `expect_scorch` da verdictul.
func _scorch_case(track: Track, label: String, expect_scorch: bool) -> void:
	var r = track.routes[1]
	var n: int = r.count()
	var i0 := int(n * 0.22)
	var start: Vector3 = r.baked[i0] + Vector3.UP * 0.6
	var dir: Vector3 = r.baked[mini(i0 + 6, n - 1)] - r.baked[i0]
	dir.y = 0.0
	dir = dir.normalized()
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene) \
		.instantiate() as Car
	get_tree().root.add_child(car)
	car.apply_data(GameState.CAR_DATA[0] as CarData)
	car.track = track
	car.route = 1
	car.road_index = i0
	car.last_safe_index = i0
	car.last_safe_route = 1
	car.global_position = start
	car.look_at(start + dir, Vector3.UP)
	car.race_active = true
	# LINIA CURATA la volan, nu AI-ul de cursa: AI-ul taie apexurile din
	# constructie (masurat: iesea ±1.3 m de pe axa si ardea legitim), dar in
	# joc AI-ul nici nu intra pe poarta (closed_from_stage). Poarta e testul
	# JUCATORULUI, deci intrebarea corecta e "trece o linie tinuta pe axa?" —
	# un pure-pursuit pe banda coapta, adica exact ce vinde brief-ul.
	car.set_controller(LineFollower.new())
	car.velocity = dir * 14.0
	var burned := [false]
	car.crushed.connect(func(c: Car, _s: float) -> void:
		if not burned[0]:
			var v := Vector2(c.global_position.x - (-219.2),
				c.global_position.z - 452.6)
			print("    ars la (%.1f, %.1f) — axa %.1f, offset %+.2f" % [
				c.global_position.x, c.global_position.z,
				v.dot(Vector2(0.902, 0.429)), v.dot(Vector2(-0.429, 0.902))])
	)
	car.respawned.connect(func(_c: Car) -> void: burned[0] = true)
	for k in 240:
		await get_tree().physics_frame
		if burned[0]:
			break
	var speed := car.horizontal_speed()
	var verdict := "OK" if burned[0] == expect_scorch else "GRESIT"
	print("  %s: arsa=%s (asteptat %s), viteza dupa=%.1f -> %s" % [
		label, burned[0], expect_scorch, speed, verdict])
	car.queue_free()
	await get_tree().process_frame


## Cutia de gabarit a masinii, plimbata pe banda scurtaturii — aceeasi
## intrebare ca in tools/probe_solid.gd, dar pe ruta secundara si per stadiu.
func _sweep_branch(track: Track, width: float) -> Array:
	var out := []
	if track.routes.size() < 2:
		return out
	var r = track.routes[1]
	var baked: PackedVector3Array = r.baked
	var n := baked.size()
	var space := get_tree().root.world_3d.direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(width, 1.4, 4.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var seen := {}
	var i := 0
	while i < n - 4:
		var here := baked[i]
		var dir := baked[i + 4] - here
		dir.y = 0.0
		if dir.length() < 0.01:
			i += 2
			continue
		query.transform = Transform3D(
			Basis.looking_at(dir.normalized(), Vector3.UP),
			here + Vector3.UP * 0.85)
		for hit in space.intersect_shape(query, 16):
			var col := hit["collider"] as Node
			if col == null:
				continue
			var nm := String(col.name)
			if not (nm.ends_with("_col") or nm == "stage_col"):
				continue
			var label := "%s/%s" % [col.get_parent().name, nm]
			if not seen.has(label):
				seen[label] = true
				out.append([label, float(i) / float(n)])
		i += 2
	return out


## Soferul de proba: tine linia benzii (pure pursuit pe curba coapta) la
## ~14 m/s — trecerea "curata" pe care o cere poarta.
class LineFollower extends CarController:
	func get_steer() -> float:
		if car == null or car.track == null:
			return 0.0
		var r = car.track.routes[car.route]
		var n: int = r.count()
		var target: Vector3 = r.baked[mini(car.road_index + 8, n - 1)]
		var to_t := target - car.global_position
		to_t.y = 0.0
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		if to_t.length_squared() < 0.01 or fwd.length_squared() < 0.01:
			return 0.0
		return clampf(fwd.signed_angle_to(to_t, Vector3.UP) * 2.0, -1.0, 1.0)

	func get_throttle() -> float:
		return 1.0 if car.horizontal_speed() < 14.0 else 0.0


func _route_xz(track: Track, idx: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if idx >= track.routes.size():
		return out
	for p in track.routes[idx].baked:
		out.append(Vector2(p.x, p.z))
	return out


func _dist_to_poly(p: Vector2, pts: PackedVector2Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		var a := pts[i]
		var ab := pts[i + 1] - a
		var l2 := ab.length_squared()
		var t := 0.0 if l2 <= 0.0 else clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _visible_list(lava: LavaFlowHazard) -> String:
	var names: Array[String] = []
	for i in lava._meshes.size():
		var m: Node3D = lava._meshes[i]
		if m != null and m.visible:
			names.append(String(lava.stage_nodes[i]))
	return ", ".join(names) if not names.is_empty() else "(niciunul)"


func _dump(node: Node, depth: int) -> void:
	for child in node.get_children():
		var vis := ""
		if child is Node3D:
			vis = "  visible=%s" % (child as Node3D).visible
		print("%s- %s (%s)%s" % ["  ".repeat(depth), child.name,
			child.get_class(), vis])
		if depth < 3:
			_dump(child, depth + 1)
