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
		print("%-16s suprafete=%d triunghiuri=%5d materiale=%d  AABB y %.2f..%.2f  latime %.2f" % [
			cfg["nume"], sfc, tri, mats.size(),
			aabb.position.y, aabb.position.y + aabb.size.y, aabb.size.x])
		host.queue_free()
	get_tree().quit(0)

func _all(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D: out.append(n)
	for c in n.get_children(): out += _all(c)
	return out
