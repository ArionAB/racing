extends Node
## Ce ridica terenul dincolo de buza: pentru fiecare raza a testului de silueta,
## spune ce masive o acopera si cat de departe e buza rapei.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var peaks: Array = []
	for nd in t.get_node("Peaks").get_children():
		peaks.append([nd.name, nd.global_position, float(nd.get("radius_m"))])
	for f in [0.20, 0.24, 0.28, 0.32, 0.36]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		print("--- frac %.2f  drum y=%.1f  pos=(%.0f, %.0f)" % [f, p.y, p.x, p.z])
		for d in [15.0, 40.0, 80.0, 150.0]:
			var q: Vector3 = p + side * d
			var hits := ""
			for pk in peaks:
				var c: Vector3 = pk[1]
				var dd := Vector2(q.x - c.x, q.z - c.z).length()
				if dd < pk[2]:
					hits += " %s(d=%.0f/r=%.0f y=%.0f)" % [pk[0], dd, pk[2], c.y]
			print("   +%3dm (%.0f,%.0f):%s" % [int(d), q.x, q.z, hits if hits != "" else " —"])
	get_tree().quit(0)
