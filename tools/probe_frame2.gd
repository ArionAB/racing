extends Node
## Faleza pe ECRAN, prin PROIECTIE, nu prin raze.
##
## Prima versiune a sondei trage raze si a dat 0.0% — dar panza falezei n-are
## corp fizic (deliberat: peste buza se cade in gol), deci razele treceau prin
## ea. Verdictul era corect din intamplare, nu din masura. Aici se proiecteaza
## VERTECSII mesh-ului cu camera reala si se numara cati cad in cadru si nu
## sunt ascunsi de teren — asta e chiar intrebarea „se vede peretele?".
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var mis: Array[Node] = []
	_walk(t, mis)
	for f: float in [0.20, 0.28, 0.36]:
		_shoot(t, f, mis)
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _shoot(t: Track, frac: float, mis: Array[Node]) -> void:
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	var target := focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
	var fwd := (target - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var half_v := tan(deg_to_rad(ChaseCamera.BASE_FOV) * 0.5)
	var half_h := half_v * (16.0 / 9.0)
	var space := get_viewport().world_3d.direct_space_state

	var inside := 0
	var visible_pts := 0
	var total := 0
	var sx_min := INF
	var sx_max := -INF
	var sy_min := INF
	var sy_max := -INF
	for m in mis:
		var mi := m as MeshInstance3D
		var arr := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var step := maxi(int(verts.size() / 900), 1)
		var k := 0
		while k < verts.size():
			var w: Vector3 = mi.global_transform * verts[k]
			k += step
			total += 1
			var rel := w - eye
			var z := rel.dot(fwd)
			if z <= 0.5:
				continue
			var sh := rel.dot(right) / (z * half_h)
			var sv := rel.dot(up) / (z * half_v)
			if absf(sh) > 1.0 or absf(sv) > 1.0:
				continue
			inside += 1
			# ascuns de teren? raza spre punct, oprita de orice corp solid
			var q := PhysicsRayQueryParameters3D.create(eye, w)
			var hit := space.intersect_ray(q)
			var occluded := false
			if not hit.is_empty():
				var hp: Vector3 = hit["position"]
				if eye.distance_to(hp) < eye.distance_to(w) - 1.0:
					occluded = true
			if not occluded:
				visible_pts += 1
				sx_min = minf(sx_min, sh)
				sx_max = maxf(sx_max, sh)
				sy_min = minf(sy_min, sv)
				sy_max = maxf(sy_max, sv)
	print("\n=== frac %.2f — FALEZA prin proiectie ===" % frac)
	print("  vertecsi esantionati: %d, in frustum: %d, NEascunsi de teren: %d" % [total, inside, visible_pts])
	if visible_pts > 0:
		# ecran normalizat -1..1; sv pozitiv = sus
		print("  intinderea pe ecran: x %.2f..%.2f (din -1..1), y %.2f..%.2f" % [sx_min, sx_max, sy_min, sy_max])
		var wpct := (sx_max - sx_min) * 50.0
		var hpct := (sy_max - sy_min) * 50.0
		print("  adica ~%.0f%% din latimea cadrului si ~%.0f%% din inaltime" % [wpct, hpct])
	else:
		print("  >>> NIMIC pe ecran  [PICAT]")

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Faleza"):
			out.append(c)
		_walk(c, out)
