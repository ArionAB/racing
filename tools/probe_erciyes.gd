extends Node
## Profilul conului Erciyes apropiat: raza reala pe fiecare cota, ca sa se
## poata aseza cornise PE suprafata (nu plutind, nu ingropate). Masurat pe
## triunghiurile mesh-ului, la scara si pozitia din lume.

func _ready() -> void:
	var ti := GameState.resolve_track_index(13)
	var track := (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate() as Track
	add_child(track)
	for i in range(6):
		await get_tree().process_frame

	var mi := _find(track)
	if mi == null:
		print("nu am gasit Erciyes-ul apropiat")
		get_tree().quit(1)
		return
	var xf := mi.global_transform
	print("nod: %s" % mi.get_path())
	print("origine lume: %.1f, %.1f, %.1f  scale %.3f" % [
		xf.origin.x, xf.origin.y, xf.origin.z, xf.basis.get_scale().y])
	var vs := PackedVector3Array()
	for s in range((mi.mesh as Mesh).get_surface_count()):
		var arr := (mi.mesh as Mesh).surface_get_arrays(s)
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			vs.append(xf * v)
	var ymin := 1e9
	var ymax := -1e9
	for v in vs:
		ymin = minf(ymin, v.y); ymax = maxf(ymax, v.y)
	print("y: %.1f .. %.1f  (inaltime %.1f m)" % [ymin, ymax, ymax - ymin])
	# axa = centroidul in XZ
	var cx := 0.0; var cz := 0.0
	for v in vs:
		cx += v.x; cz += v.z
	cx /= float(vs.size()); cz /= float(vs.size())
	print("axa xz: %.1f, %.1f" % [cx, cz])
	print("%8s %10s %10s %8s" % ["cota", "raza min", "raza max", "n"])
	var step := (ymax - ymin) / 14.0
	for k in range(14):
		var y0 := ymin + float(k) * step
		var y1 := y0 + step
		var rmin := 1e9; var rmax := 0.0; var cnt := 0
		for v in vs:
			if v.y >= y0 and v.y < y1:
				var r := Vector2(v.x - cx, v.z - cz).length()
				rmin = minf(rmin, r); rmax = maxf(rmax, r); cnt += 1
		if cnt > 0:
			print("%8.0f %10.1f %10.1f %8d" % [(y0 + y1) * 0.5, rmin, rmax, cnt])
	get_tree().quit()

func _find(node: Node) -> MeshInstance3D:
	for c in node.get_children():
		if c is MeshInstance3D and "Erciyes" in str(c.get_path()) \
				and "@128" in str(c.get_path()):
			return c as MeshInstance3D
		var r := _find(c)
		if r != null:
			return r
	return null
