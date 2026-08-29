extends Node
## Verifica: (1) piesele din piata nu intra in carosabil, (2) baza fata de teren,
## (3) unghiul de depresie spre varf de la camera.
## Examineaza TOATE nodurile POI-ului, nu un prefix de nume: filtrul pe nume a
## lasat sonda oarba dupa o redenumire (raport "0 semnalari" pe 0 noduri).
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	var root := track.get_node("DecorManual/1) Piata Kuixinglou")
	var n_seen := 0
	var n_bad := 0
	for ch in root.get_children():
		if ch is not Node3D: continue
		# Doar piesele INALTE de decor pot face zid pe carosabil; parapetii,
		# felinarele si masinile stau la buza prin design. Filtrez pe rol,
		# nu pe nume: inaltime > 8 m fata de sosea deasupra sau sub ea.
		if not _is_cladire(ch as Node3D): continue
		n_seen += 1
		var n := ch as Node3D
		var ab := _aabb(n)
		var gp := n.global_position
		# fractia cea mai apropiata pe curba
		var best_f := 0.0
		var best_d := 1e9
		for k in 400:
			var f: float = float(k) / 400.0 * 0.06
			var pp := c.sample_baked(f * L)
			var dd := Vector2(pp.x - gp.x, pp.z - gp.z).length()
			if dd < best_d:
				best_d = dd; best_f = f
		var p := c.sample_baked(best_f * L)
		var p2 := c.sample_baked(minf(best_f * L + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		# distanta laterala minima a AABB fata de axa
		var dmin := 1e9
		var dmax := -1e9
		for ix in 2: for iy in 2: for iz in 2:
			var cor := ab.position + Vector3(ab.size.x*ix, ab.size.y*iy, ab.size.z*iz)
			var lat := (cor - p).dot(right)
			dmin = minf(dmin, lat); dmax = maxf(dmax, lat)
		# teren sub centrul piesei
		var o := Vector3(gp.x, 90.0, gp.z)
		var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 300.0)
		q.collide_with_areas = false
		var h := space.intersect_ray(q)
		var g: float = h.position.y if not h.is_empty() else -999.0
		var top := ab.position.y + ab.size.y
		var depr := rad_to_deg(atan2(p.y + 10.0 - top, maxf(dmin, 1.0)))
		print("%s frac=%.4f lat=[%.1f..%.1f] baza=%.1f teren=%.1f varf=%.1f sosea=%.1f depresie_varf=%.1f %s"
			% [n.name, best_f, dmin, dmax, ab.position.y, g, top, p.y, depr,
				("!!CAROSABIL" if dmin < 5.6 else "ok")])
		if dmin < 5.6: n_bad += 1
	if n_seen == 0:
		print("VERDICT SONDA INVALIDA: 0 noduri examinate (nume de nod gresit?)")
	elif n_bad > 0:
		print("VERDICT RESPINS: %d din %d blocuri in carosabil" % [n_bad, n_seen])
	else:
		print("VERDICT OK: %d blocuri examinate, 0 in carosabil" % n_seen)
	get_tree().quit()
func _is_cladire(n: Node3D) -> bool:
	var ab := _aabb(n)
	return ab.size.y >= 8.0

func _aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in _all(n):
		var a: AABB = m.global_transform * m.get_aabb()
		if first: out = a; first = false
		else: out = out.merge(a)
	return out
func _all(n: Node) -> Array:
	var r := []
	if n is VisualInstance3D: r.append(n)
	for ch in n.get_children(): r.append_array(_all(ch))
	return r
