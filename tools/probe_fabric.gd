extends Node
## Ce e, de fapt, in balloon_landed.glb: cate mesh-uri, ce inaltime au varfurile
## si CE CULORI poarta. Panza apare in cadru ca o elipsa subtire — verific daca
## are volum si daca sloturile de paleta sunt cele de dungi.


func _ready() -> void:
	var ps := load("res://assets/models/cappadocia/props/balloon_landed.glb") as PackedScene
	var inst := ps.instantiate()
	add_child(inst)
	print("")
	print("=== balloon_landed.glb ===")
	for m in _meshes(inst):
		var mi := m as MeshInstance3D
		var mm := mi.mesh
		print("mesh %s: %d surfete" % [mi.name, mm.get_surface_count()])
		for si in mm.get_surface_count():
			var arr := mm.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var col: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var ymin := INF
			var ymax := -INF
			for p in v:
				ymin = minf(ymin, p.y)
				ymax = maxf(ymax, p.y)
			print("  surf %d: %d verts, y %.2f..%.2f, colors=%d, uv=%d" % [
				si, v.size(), ymin, ymax, col.size(), uv.size()])
			# profilul pe axa lunga: cat de "umflata" e panza pe X
			var bins := {}
			for i in v.size():
				var bx := int(floor((v[i].x + 10.5) / 2.0))
				bins[bx] = maxf(float(bins.get(bx, 0.0)), v[i].y)
			var ks := bins.keys()
			ks.sort()
			var prof := ""
			for k in ks:
				prof += "%.2f " % bins[k]
			print("    profil y pe X (felii de 2 m): %s" % prof)
			var seen := {}
			for i in mini(uv.size(), 4000):
				seen[Vector2(snappedf(uv[i].x, 0.02), snappedf(uv[i].y, 0.02))] = true
			var keys := seen.keys()
			keys.sort()
			print("    sloturi UV (max 12): %s" % [keys.slice(0, 12)])
	print("")
	get_tree().quit()


func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		out.append(root)
	for c in root.get_children():
		out.append_array(_meshes(c))
	return out
