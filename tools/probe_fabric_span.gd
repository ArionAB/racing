extends Node
## Panza CHIAR traverseaza drumul? Constrangerea dura din referinta e "peste
## drum, nu pe acostament". O masor in lume: iau vertecsii panzei din scena
## construita si ii proiectez pe normala drumului la fractia ei. Nu ma uit la
## AABB-ul GLB-ului (aia e cutia LOCALA, minte despre rotatie).


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var fabric := track.find_child("BalloonFabric", true, false)
	if fabric == null:
		print("PANZA LIPSA")
		get_tree().quit()
		return

	var baked: PackedVector3Array = track.baked
	var n := baked.size()
	# fractia panzei = punctul de ax cel mai apropiat
	var fp: Vector3 = (fabric as Node3D).global_position
	var bi := 0
	var bd := INF
	for i in n:
		var d := Vector2(baked[i].x - fp.x, baked[i].z - fp.z).length_squared()
		if d < bd:
			bd = d
			bi = i
	var p: Vector3 = baked[bi]
	var q: Vector3 = baked[(bi + 3) % n]
	var fwd := Vector3(q.x - p.x, 0.0, q.z - p.z).normalized()
	var rgt := Vector3(-fwd.z, 0.0, fwd.x)

	var lat_min := INF
	var lat_max := -INF
	var y_max := -INF
	for m in _meshes(fabric):
		var mi := m as MeshInstance3D
		var xf := mi.global_transform
		for v in (mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			var w: Vector3 = xf * v
			var lat := (w - p).dot(rgt)
			lat_min = minf(lat_min, lat)
			lat_max = maxf(lat_max, lat)
			y_max = maxf(y_max, w.y - p.y)
	print("")
	print("=== Panza fata de drum (frac %.3f) ===" % (float(bi) / float(n)))
	print("half_width acolo: 8.0 m  ->  banda e [-8.0, +8.0]")
	print("panza acopera lateral: %.2f .. %.2f m (latime %.2f)" % [lat_min, lat_max, lat_max - lat_min])
	print("inaltime peste ax: %.2f m" % y_max)
	var covers := lat_min <= -8.0 and lat_max >= 8.0
	print("TRAVERSEAZA COMPLET: %s" % ("DA" if covers else "NU"))
	print("")
	get_tree().quit()


func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		out.append(root)
	for c in root.get_children():
		out.append_array(_meshes(c))
	return out
