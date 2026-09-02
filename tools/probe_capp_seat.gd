extends Node
## Cotele terenului la pozitiile unde vrem hornuri noi (zona frac 0.15-0.17):
## originile se aseaza pe ground_y, nu din ochi — altfel plutesc sau se ingroapa.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var space := t.get_world_3d().direct_space_state
	var pts := [Vector2(52, 22), Vector2(66, 20), Vector2(80, 26), Vector2(96, 24),
		Vector2(58, 74), Vector2(72, 80), Vector2(88, 76), Vector2(104, 70),
		Vector2(44, 30), Vector2(112, 34)]
	for p in pts:
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, 200.0, p.y), Vector3(p.x, -200.0, p.y))
		var excl: Array[RID] = []
		var y := 999.0
		for _k in 12:
			ray.exclude = excl
			var hit := space.intersect_ray(ray)
			if hit.is_empty():
				break
			var col = hit["collider"]
			if col is StaticBody3D and not str(col.name).ends_with("_col"):
				y = float(hit["position"].y)
				break
			excl.append(hit["rid"])
		print("%.0f %.0f %.3f" % [p.x, p.y, y])
	get_tree().quit(0)
