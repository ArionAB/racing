extends Node
## Da coordonatele reale pentru POI E (via + balonul aterizat, 0.52-0.64):
## pozitie pe ax, tangenta, normala laterala si cota terenului la distante
## laterale. Fara ele, orice asezare de decor e ghicita — iar ghicitul a produs
## deja "moloz la scara 0.45-1.40" = coridor de coloane de 16 m.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePoiE.tscn


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var baked: PackedVector3Array = track.baked
	var n := baked.size()
	print("")
	print("=== POI E: geometria vaii ===")
	print("puncte baked: %d, half_width: %s" % [n, str(track.get("road_half_width"))])

	# cotele din MESH-ul de teren (raycast-ul cere lume fizica pornita)
	var tv := PackedVector3Array()
	for m in _terrain_meshes(track):
		var arrays := m.mesh.surface_get_arrays(0)
		var xf := m.global_transform
		for v in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			tv.append(xf * v)
	print("vertecsi de teren: %d" % tv.size())
	for m in _terrain_meshes(track):
		print("  mesh: %s (%d surf)" % [m.name, m.mesh.get_surface_count()])
	for f: float in [0.50, 0.52, 0.54, 0.56, 0.58, 0.60, 0.62, 0.64, 0.66]:
		var i := int(round(f * float(n))) % n
		var p: Vector3 = baked[i]
		var q: Vector3 = baked[(i + 3) % n]
		var fwd := (q - p)
		fwd.y = 0.0
		fwd = fwd.normalized()
		var rgt := Vector3(-fwd.z, 0.0, fwd.x)
		var line := "frac %.2f  pos(%.1f, %.1f, %.1f)  fwd(%.2f,%.2f)  " % [f, p.x, p.y, p.z, fwd.x, fwd.z]
		# cota terenului la stanga/dreapta
		for d: float in [-34.0, -26.0, -20.0, -14.0, -9.0, 9.0, 14.0, 20.0, 26.0]:
			var probe_pos: Vector3 = p + rgt * d
			var best := 36.0  # (6 m)^2 — altfel "cel mai apropiat" ia un varf de departe
			var gy := NAN
			for v in tv:
				var dd := Vector2(v.x - probe_pos.x, v.z - probe_pos.z).length_squared()
				if dd < best:
					best = dd
					gy = v.y
			line += "%+.0f:%.1f " % [d, gy]
		print(line)
	print("")
	get_tree().quit()


func _terrain_meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var nm := String(c.name).to_lower()
			if not (nm.contains("road") or nm.contains("asfalt") or nm.contains("sosea")):
				out.append(c)
		out.append_array(_terrain_meshes(c))
	return out
