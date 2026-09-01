extends Node
## Gabaritul real (AABB) al GLB-urilor pe care le folosesc la marginea benzii.
## Scara din .tscn nu spune nimic fara marimea sursei.
func _ready() -> void:
	for p in ["rocks/cracked_chimney_a", "rocks/cracked_chimney_b",
			"rocks/cracked_chimney_c", "plants/shrub_dry", "plants/poplar_a",
			"rocks/chimney_a", "rocks/chimney_d"]:
		var sc := load("res://assets/models/cappadocia/%s.glb" % p) as PackedScene
		if sc == null:
			print("%-28s LIPSA" % p); continue
		var n := sc.instantiate()
		add_child(n)
		var ab := AABB()
		var first := true
		var tri := 0
		for m in _meshes(n):
			var a: AABB = (m as MeshInstance3D).get_aabb()
			a = (m as MeshInstance3D).global_transform * a
			if first: ab = a; first = false
			else: ab = ab.merge(a)
			var ms := (m as MeshInstance3D).mesh
			if ms != null:
				for s in ms.get_surface_count():
					var arr := ms.surface_get_arrays(s)
					if arr.size() > Mesh.ARRAY_INDEX and arr[Mesh.ARRAY_INDEX] != null:
						tri += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
					elif arr.size() > 0 and arr[Mesh.ARRAY_VERTEX] != null:
						tri += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		print("%-28s dim %5.2f x %5.2f x %5.2f  (y de la %.2f)  %d tri" % [
			p, ab.size.x, ab.size.y, ab.size.z, ab.position.y, tri])
		n.queue_free()
	get_tree().quit(0)

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D: out.append(n)
	for c in n.get_children(): out += _meshes(c)
	return out
