extends Node
## Dimensiunile REALE ale GLB-urilor de care am nevoie la POI E. Scalarea se
## face in METRI derivati din AABB-ul real, niciodata dintr-un factor ghicit
## (lectia "moloz la 0.45-1.40" = coloane de 16,84 m).


func _ready() -> void:
	var files := [
		"res://assets/models/cappadocia/plants/vine_row.glb",
		"res://assets/models/cappadocia/plants/poplar_a.glb",
		"res://assets/models/cappadocia/plants/poplar_b.glb",
		"res://assets/models/cappadocia/plants/shrub_dry.glb",
		"res://assets/models/cappadocia/buildings/farmhouse.glb",
		"res://assets/models/cappadocia/props/balloon_landed.glb",
		"res://assets/models/cappadocia/props/balloon_basket.glb",
		"res://assets/models/cappadocia/props/balloon_envelope_a.glb",
		"res://assets/models/cappadocia/rocks/balloon_far.glb",
	]
	print("")
	print("=== AABB real per GLB (metri) ===")
	for f: String in files:
		var ps := load(f) as PackedScene
		if ps == null:
			print("%s -> LIPSA" % f)
			continue
		var inst := ps.instantiate()
		add_child(inst)
		var aabb := AABB()
		var first := true
		for m in _meshes(inst):
			var a := (m as MeshInstance3D).mesh.get_aabb()
			a = (m as MeshInstance3D).global_transform * a
			if first:
				aabb = a
				first = false
			else:
				aabb = aabb.merge(a)
		var tris := 0
		for m in _meshes(inst):
			var mm := (m as MeshInstance3D).mesh
			for si in mm.get_surface_count():
				tris += mm.surface_get_arrays(si)[Mesh.ARRAY_INDEX].size() / 3
		print("%-26s  size(%.2f x %.2f x %.2f)  min.y=%.2f  tris=%d" % [
			f.get_file(), aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y, tris])
		inst.queue_free()
	print("")
	get_tree().quit()


func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		out.append(root)
	for c in root.get_children():
		out.append_array(_meshes(c))
	return out
