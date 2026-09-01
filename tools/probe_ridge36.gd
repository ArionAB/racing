extends Node
## Profil fin pe raza exterioara, ca sa vad unde e coama care rupe caderea.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.24, 0.36]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		print("--- frac %.2f drum y=%.1f" % [f, p.y])
		var d := 5.0
		while d <= 170.0:
			var q: Vector3 = p + side * d
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 250.0, q.z), Vector3(q.x, p.y - 350.0, q.z))
			var hit := space.intersect_ray(ray)
			var s := "   %5.0f m: " % d
			if hit:
				s += "%7.1f  %s" % [float(hit["position"].y) - p.y, str(hit["collider"].name)]
			else: s += "   gol"
			print(s)
			d += 10.0
	get_tree().quit(0)
