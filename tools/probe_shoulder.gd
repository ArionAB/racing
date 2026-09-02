extends Node
## Cat de lat e umarul plat dintre marginea asfaltului si buza caderii, si de la
## ce rulaj incepe terenul sa cada cu adevarat. Umarul lat = fasia palida care
## ramane in cadru dupa ce valea a fost sapata.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.21, 0.24, 0.28, 0.32, 0.36]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		var s := "frac %.2f: " % f
		var d := 5.0
		var brink := -1.0
		while d <= 40.0:
			var q: Vector3 = p + side * d
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 200.0, q.z), Vector3(q.x, p.y - 300.0, q.z))
			var hit := space.intersect_ray(ray)
			var dy := -99.0
			if hit: dy = float(hit["position"].y) - p.y
			if brink < 0.0 and dy < -3.0: brink = d
			if int(d) % 5 == 0: s += "%.0fm:%.1f " % [d, dy]
			d += 1.0
		s += " | buza caderii la %.0f m" % brink
		print(s)
	get_tree().quit(0)
