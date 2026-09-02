extends SceneTree

## Cat de neted e AO-ul COPT in .glb, inainte sa-l atinga cineva?
##
## `_shade_facets` INMULTESTE cu un k plat per fata. Daca culorile care intra
## variaza deja de la vertex la vertex (AO copt in Blender), inmultirea pastreaza
## variatia — deci fata ramane neteda oricat de bine ar fi cuantizat k. Sonda
## citeste mesh-ul direct din .glb, fara scena, ca sa vada ce e la INTRARE.

func _initialize() -> void:
	for path in ["res://assets/models/cappadocia/rocks/chimney_triple.glb",
			"res://assets/models/cappadocia/rocks/chimney_a.glb"]:
		if not ResourceLoader.exists(path):
			print("lipseste: ", path)
			continue
		var packed: PackedScene = load(path)
		var scene: Node = packed.instantiate()
		var stack: Array[Node] = [scene]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			var mi := n as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var arr: Array = mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var raw: Variant = arr[Mesh.ARRAY_COLOR]
			if not (raw is PackedColorArray):
				print("%s / %s: %d fete, FARA vertex color"
						% [path.get_file(), n.name, verts.size() / 3])
				continue
			var cols: PackedColorArray = raw
			var mn := 2.0
			var mx := -1.0
			for c in cols:
				mn = minf(mn, c.r)
				mx = maxf(mx, c.r)
			print("%s / %s: %d fete, AO r %.3f..%.3f (amplitudine %.3f)"
					% [path.get_file(), n.name, verts.size() / 3, mn, mx, mx - mn])
	quit()
