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
	print("frac | cota drum | DREAPTA 30/45/60/75/90/110/140/180 m")
	for f in [0.10, 0.115, 0.13, 0.145, 0.16]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var dir: Vector3 = (a - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()  # dreapta = exterior
		var row := "%.2f | pos(%.0f,%.0f) side(%.2f,%.2f) | %6.1f |" % [f, p.x, p.z, side.x, side.z, p.y]
		for d in [30.0, 45.0, 60.0, 75.0, 90.0, 110.0, 140.0, 180.0]:
			var q: Vector3 = p + side * d
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 200.0, q.z), Vector3(q.x, p.y - 300.0, q.z))
			# Decorul NU e teren: un balon ancorat sau o lespede de kit prinsa de
			# raza raporta o cota falsa. Se trage prin ce nu e pamant.
			var excl: Array[RID] = []
			var dy := 999.0
			for _k in 12:
				ray.exclude = excl
				var hit := space.intersect_ray(ray)
				if hit.is_empty():
					break
				var col = hit["collider"]
				if col is StaticBody3D and not str(col.name).ends_with("_col"):
					dy = float(hit["position"].y) - p.y
					break
				excl.append(hit["rid"])
			if dy < 900.0:
				row += " %7.1f" % dy
			else:
				row += "    gol"
		print(row)
	print("(cifrele sunt DIFERENTA fata de cota drumului; negativ = mai jos = cadere)")
	get_tree().quit(0)
