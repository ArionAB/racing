extends Node
## Verifica ca poala si usile chiar produc geometrie, si CAT: suprafete,
## triunghiuri, materiale. Numaratul singur nu dovedeste ca se vede (vezi
## efecte-invizibile-nu-se-numara), dar dovedeste ca nu e zero.
func _ready() -> void:
	await get_tree().process_frame
	var scn := load("res://assets/models/cappadocia/rocks/chimney_a.glb") as PackedScene
	for cfg in [
		{"nume": "gol", "talus": 0.0, "usi": 0},
		{"nume": "doar poala", "talus": 0.55, "usi": 0},
		{"nume": "poala + 3 usi", "talus": 0.55, "usi": 3},
	]:
		var host := Node3D.new()
		get_tree().root.add_child(host)
		var inst := scn.instantiate()
		var cs := ChimneyShape.new()
		cs.talus_spread = cfg["talus"]
		cs.door_count = cfg["usi"]
		cs.door_height_m = 2.0
		cs.shape_seed = 5
		cs.add_child(inst)
		host.add_child(cs)
		await get_tree().process_frame
		var tri := 0
		var sfc := 0
		var mats := {}
		var aabb := AABB()
		var first := true
		for mi in _all(cs):
			var m: Mesh = mi.mesh
			if m == null: continue
			sfc += m.get_surface_count()
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ni: int = 0
				if arr[Mesh.ARRAY_INDEX] != null:
					ni = (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
				tri += (ni / 3) if ni > 0 else (vv.size() / 3)
				var mm := m.surface_get_material(s)
				if mm != null: mats[mm.get_instance_id()] = true
			if first:
				aabb = m.get_aabb(); first = false
			else:
				aabb = aabb.merge(m.get_aabb())
		for mi in _all(cs):
			var mm: Mesh = mi.mesh
			if mm == null: continue
			for s2 in mm.get_surface_count():
				var ar := mm.surface_get_arrays(s2)
				var uv_s := "FARA UV"
				if ar[Mesh.ARRAY_TEX_UV] != null:
					var uvs: PackedVector2Array = ar[Mesh.ARRAY_TEX_UV]
					if uvs.size() > 0:
						var mn := uvs[0]; var mx := uvs[0]
						for u in uvs:
							mn = Vector2(minf(mn.x,u.x), minf(mn.y,u.y))
							mx = Vector2(maxf(mx.x,u.x), maxf(mx.y,u.y))
						uv_s = "u %.3f..%.3f  v %.3f..%.3f" % [mn.x, mx.x, mn.y, mx.y]
				print("      sfc %d: %s" % [s2, uv_s])
		print("%-16s suprafete=%d triunghiuri=%5d materiale=%d  AABB y %.2f..%.2f  latime %.2f" % [
			cfg["nume"], sfc, tri, mats.size(),
			aabb.position.y, aabb.position.y + aabb.size.y, aabb.size.x])
		host.queue_free()
	# Geometria unei usi: cat de adanca iese DUPA clamp, si ce proportie are.
	var scn2 := load("res://assets/models/cappadocia/rocks/chimney_a.glb") as PackedScene
	var host2 := Node3D.new()
	get_tree().root.add_child(host2)
	var i2 := scn2.instantiate()
	var c2 := ChimneyShape.new()
	c2.talus_spread = 0.55
	c2.door_count = 1
	c2.door_height_m = 2.0
	c2.door_depth_m = 0.8
	c2.shape_seed = 5
	c2.add_child(i2)
	host2.add_child(c2)
	await get_tree().process_frame
	for mi in _all(c2):
		var mm: Mesh = mi.mesh
		if mm == null or mm.get_surface_count() < 3: continue
		var ar := mm.surface_get_arrays(2)
		var vv: PackedVector3Array = ar[Mesh.ARRAY_VERTEX]
		var mn := vv[0]; var mx := vv[0]
		for v in vv:
			mn = Vector3(minf(mn.x,v.x), minf(mn.y,v.y), minf(mn.z,v.z))
			mx = Vector3(maxf(mx.x,v.x), maxf(mx.y,v.y), maxf(mx.z,v.z))
		print("USA: latime %.2f  inaltime %.2f  adancime-bbox %.2f  prag y=%.2f" % [
			maxf(mx.x-mn.x, mx.z-mn.z), mx.y-mn.y, minf(mx.x-mn.x, mx.z-mn.z), mn.y])
	get_tree().quit(0)

func _all(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D: out.append(n)
	for c in n.get_children(): out += _all(c)
	return out
