extends Node
## Testul de silueta, dar pe RAZE DIN OCHIUL SOFERULUI, nu verticale: cat de jos
## sub orizont e prima lovitura de teren dincolo de buza, si urmeaza cer?
## O cornisa adevarata: dupa umar, urmatoarea lovitura e DEPARTE si JOS, sau cer.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	print("frac | unghi sub orizont la care ochiul vede teren (grade), pe azimut spre vale")
	for f in [0.20, 0.24, 0.28, 0.32, 0.36]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var fwd: Vector3 = (a - p).normalized()
		var side: Vector3 = fwd.cross(Vector3.UP).normalized()
		var eye: Vector3 = p + Vector3.UP * 1.5
		var row := "%.2f |" % f
		# azimut: 30/60/90 grade spre dreapta fata de directia de mers
		for az in [30.0, 60.0, 90.0]:
			var dirh: Vector3 = (fwd * cos(deg_to_rad(az)) + side * sin(deg_to_rad(az))).normalized()
			# coboara raza pana gaseste teren; raporteaza unghiul
			var found := 999.0
			for k in 60:
				var ang := -float(k) * 0.5   # 0 = orizont, negativ = in jos
				var d: Vector3 = (dirh + Vector3.UP * tan(deg_to_rad(ang))).normalized()
				var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 400.0)
				var hit := space.intersect_ray(q)
				if hit:
					found = ang
					var col = hit["collider"]
					var hp: Vector3 = hit["position"]
					var path := str(col.name)
					var par = col.get_parent()
					var depth := 0
					while par != null and depth < 4:
						path = str(par.name) + "/" + path
						par = par.get_parent(); depth += 1
					row += " [%s @%.0fm dy=%.1f]" % [path,
						eye.distance_to(hp), hp.y - p.y]
					break
			row += "  az%2d: %6.1f" % [int(az), found]
		print(row)
	print("(0 = teren chiar la orizont = podea la nivelul ochiului; foarte negativ = gol)")
	get_tree().quit(0)
