extends Node
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	print("n=", n, "  half_width=", t.road_half_width if "road_half_width" in t else "?")
	# toate punctele care cad in fereastra care ma intereseaza
	print("--- puncte de drum in zona x 60..300, z 40..200 ---")
	for i in range(n):
		var p: Vector3 = r.baked[i]
		if p.x > 60.0 and p.x < 300.0 and p.z > 20.0 and p.z < 200.0:
			print("  i=%4d frac=%.3f  (%.1f, %.1f, %.1f)" % [i, float(i)/n, p.x, p.y, p.z])
	get_tree().quit(0)
