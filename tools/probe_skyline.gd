extends Node
## Testul criticului: din ochiul soferului, umarul exterior trebuie sa fie ULTIMA
## bucata de teren apropiat. Daca in spatele lui se vede teren la aceeasi cota,
## nu exista cornisa — oricat ar spune datele de varfuri.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	print("frac | cota drum | teren la +15m in afara | +40m | +80m | +150m")
	for f in [0.20, 0.24, 0.28, 0.32, 0.36]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var dir: Vector3 = (a - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()  # dreapta = exterior
		var row := "%.2f | %8.1f |" % [f, p.y]
		for d in [15.0, 40.0, 80.0, 150.0]:
			var q: Vector3 = p + side * d
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 200.0, q.z), Vector3(q.x, p.y - 300.0, q.z))
			var hit := space.intersect_ray(ray)
			if hit:
				row += " %7.1f" % (float(hit["position"].y) - p.y)
			else:
				row += "    gol"
		print(row)
	print("(cifrele sunt DIFERENTA fata de cota drumului; negativ = mai jos = cadere)")
	get_tree().quit(0)
