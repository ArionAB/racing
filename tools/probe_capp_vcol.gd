extends SceneTree

## Ajunge umbrirea pe fata pana in mesh-ul FINAL din scena?
##
## Ipoteza rundei 14 a fost ca `_shade_facets` cuantizeaza prea grosolan. Dar
## dupa ce s-a trecut la 12 trepte si contrast 0.46, captura aproape nu s-a
## miscat (muchii 7.0% -> 6.4%). Inainte de a mai schimba o cifra, se verifica
## ce e CHIAR in vertex color pe mesh-urile din scena, nu ce ar trebui sa fie:
## `world_prop` reconstruieste mesh-ul dupa `chimney_shape` (`_retint_tuff`,
## `_warm_tuff`), si oricare din pasii aia poate rescrie sau netezi culorile.

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var best: MeshInstance3D = null
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if String(n.name).to_lower().contains("chimney"):
			var f: int = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
			if best == null or f > best.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3:
				best = mi
	if best == null:
		print("niciun horn")
		quit()
		return
	print("horn: ", best.name, "  material_override=", best.material_override)
	print("suprafete: ", best.mesh.get_surface_count())
	for sf in best.mesh.get_surface_count():
		var sa: Array = best.mesh.surface_get_arrays(sf)
		var sv: PackedVector3Array = sa[Mesh.ARRAY_VERTEX]
		var sr: Variant = sa[Mesh.ARRAY_COLOR]
		if not (sr is PackedColorArray):
			print("  suprafata %d: %d fete, FARA culoare" % [sf, sv.size() / 3])
			continue
		var sc: PackedColorArray = sr
		var nf := 0
		for t in sv.size() / 3:
			var i := t * 3
			if absf(sc[i + 1].r - sc[i].r) > 0.002 or absf(sc[i + 2].r - sc[i].r) > 0.002:
				nf += 1
		print("  suprafata %d: %d fete, neplate %d" % [sf, sv.size() / 3, nf])
	var arr: Array = best.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var raw: Variant = arr[Mesh.ARRAY_COLOR]
	if not (raw is PackedColorArray):
		print("MESH-UL NU ARE VERTEX COLOR — umbrirea pe fata s-a pierdut")
		quit()
		return
	var cols: PackedColorArray = raw
	print("fete: ", verts.size() / 3, "  culori: ", cols.size())
	# Culoarea e constanta pe triunghi? (daca nu, cineva a interpolat peste ea)
	var nonflat := 0
	var vals := PackedFloat32Array()
	for t in verts.size() / 3:
		var i := t * 3
		var a := cols[i].r
		if absf(cols[i + 1].r - a) > 0.002 or absf(cols[i + 2].r - a) > 0.002:
			nonflat += 1
		vals.append(a)
	print("fete cu culoare NEPLATA pe triunghi: %d din %d" % [nonflat, vals.size()])
	var mn := 2.0
	var mx := -1.0
	for v in vals:
		mn = minf(mn, v)
		mx = maxf(mx, v)
	print("interval r pe fete: %.3f .. %.3f  (amplitudine %.3f)" % [mn, mx, mx - mn])
	var same := 0
	for i in maxi(vals.size() - 1, 0):
		if absf(vals[i] - vals[i + 1]) < 0.004:
			same += 1
	print("perechi vecine cu salt < 0.004: %.1f%%"
			% [float(same) / float(maxi(vals.size() - 1, 1)) * 100.0])
	quit()
