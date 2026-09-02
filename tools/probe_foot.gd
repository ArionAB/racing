extends Node
## TALPA panzei fata de TEREN, pe toata cornisa. Diferenta pozitiva = lespede
## care pluteste, cu cer pe sub ea. Criticul: "meets the floor at a flat butt
## joint like set dressing stood on a table" — asta o masoara.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var worst := -1e9
	var worst_f := 0.0
	# cel mai jos vertex al panzei, pe felii de fractie
	var faces := PackedVector3Array()
	var stack: Array = [t]
	while not stack.is_empty():
		var nd = stack.pop_back()
		for c in nd.get_children(): stack.append(c)
		if nd is MeshInstance3D and str(nd.name).begins_with("Faleza"):
			var mf: PackedVector3Array = nd.mesh.get_faces()
			var xf: Transform3D = nd.global_transform
			for v in mf: faces.append(xf * v)
			print("panza %s: %d vertecsi (parinte %s)" % [nd.name, mf.size(), nd.get_parent().name])
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.21, 0.24, 0.28, 0.32, 0.36, 0.39]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		# cel mai jos punct al panzei in felia asta
		var lo := 1e9
		var lo_at := Vector3.ZERO
		for v in faces:
			if absf(Vector2(v.x - p.x, v.z - p.z).length()) > 120.0: continue
			var along := (Vector2(v.x - p.x, v.z - p.z)).dot(Vector2(side.x, side.z))
			if along < 2.0: continue
			if v.y < lo: lo = v.y; lo_at = v
		if lo > 1e8: print("  frac %.2f: nimic" % f); continue
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(lo_at.x, lo_at.y + 300.0, lo_at.z),
			Vector3(lo_at.x, lo_at.y - 300.0, lo_at.z))
		ray.exclude = []
		var gy := -999.0
		var excl: Array[RID] = []
		for k in 10:
			ray.exclude = excl
			var hit := space.intersect_ray(ray)
			if hit.is_empty(): break
			if str(hit["collider"].name) == "TerrainBody":
				gy = float(hit["position"].y); break
			excl.append(hit["rid"])
		var gap := lo - gy
		print("  frac %.2f: talpa y=%.1f  teren y=%.1f  GOL=%.1f m" % [f, lo, gy, gap])
		if gap > worst: worst = gap; worst_f = f
	print("CEL MAI RAU: %.1f m la frac %.2f" % [worst, worst_f])
	get_tree().quit(0)
