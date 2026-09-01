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
	print("=== CE VEDE CAMERA: teren pe fracii DIN FATA, nu de langa masina ===")
	print("de la frac | privind inainte la +0.01 .. +0.07 din tur (lateral 30 m in afara)")
	for f0 in [0.13, 0.24, 0.28]:
		var i0 := int(f0 * n)
		var row0 := "de la %.2f:" % f0
		for df in [0.01, 0.02, 0.04, 0.07]:
			var j := (i0 + int(df * n)) % n
			var pj: Vector3 = r.baked[j]
			var aj: Vector3 = r.baked[(j + 4) % n]
			var dj: Vector3 = (aj - pj).normalized()
			var sj: Vector3 = dj.cross(Vector3.UP).normalized()
			var qq: Vector3 = pj + sj * 30.0
			var ry := PhysicsRayQueryParameters3D.create(
				Vector3(qq.x, pj.y + 250.0, qq.z), Vector3(qq.x, pj.y - 300.0, qq.z))
			var hh := space.intersect_ray(ry)
			# relativ la cota de unde STA masina, ca asa il vede ochiul
			var base: float = (r.baked[i0] as Vector3).y
			if hh:
				row0 += "  +%.2f: %6.1f" % [df, float(hh["position"].y) - base]
			else:
				row0 += "  +%.2f:    gol" % df
		print(row0)
	print("")
	print("=== MUCHIA: primii 20 m in afara, din 2 in 2 (aici se ascund politele) ===")
	for f2 in [0.20, 0.28, 0.32]:
		var i2 := int(f2 * n)
		var p2: Vector3 = r.baked[i2]
		var a2: Vector3 = r.baked[(i2 + 4) % n]
		var d2: Vector3 = (a2 - p2).normalized()
		var s2: Vector3 = d2.cross(Vector3.UP).normalized()
		var row2 := "frac %.2f:" % f2
		for dd in [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 16.0, 20.0]:
			var q2: Vector3 = p2 + s2 * dd
			var ry2 := PhysicsRayQueryParameters3D.create(
				Vector3(q2.x, p2.y + 200.0, q2.z), Vector3(q2.x, p2.y - 300.0, q2.z))
			var h2 := space.intersect_ray(ry2)
			if h2:
				row2 += " %.0fm:%.1f" % [dd, float(h2["position"].y) - p2.y]
			else:
				row2 += " %.0fm:gol" % dd
		print(row2)
	print("")
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
