extends Node
## Ce ESTE, de fapt, "gaura" de la 0.24: teren lipsa, sau carosabilul bratului
## de sus al serpentinei? Compar cota terenului de pe linia laterala cu cota
## celui mai apropiat punct de drum.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	var i0 := int(0.24 * n)
	var p: Vector3 = r.baked[i0]
	var a: Vector3 = r.baked[(i0 + 4) % n]
	var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
	print("=== CE E LA 0.24 LATERAL: teren, sau bratul de sus al serpentinei? ===")
	print("drum la 0.24: y=%.1f" % p.y)
	print("lateral | teren | cel mai apropiat drum: frac, distanta, cota lui")
	for d in [10.0, 15.0, 20.0, 30.0, 40.0, 45.0, 60.0, 80.0, 110.0, 150.0]:
		var q: Vector3 = p + side * d
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(q.x, p.y + 250.0, q.z), Vector3(q.x, p.y - 350.0, q.z))
		var hit := space.intersect_ray(ray)
		var gy := 999.0
		if hit: gy = float(hit["position"].y)
		var best := INF
		var bi := 0
		var j := 0
		while j < n:
			var dd := Vector2(q.x - r.baked[j].x, q.z - r.baked[j].z).length_squared()
			if dd < best:
				best = dd
				bi = j
			j += 2
		print("%6.0f m | teren %+7.1f (dif %+6.1f) | drum frac %.3f la %5.1f m, y=%.1f"
			% [d, gy, gy - p.y, float(bi) / float(n), sqrt(best), r.baked[bi].y])
	get_tree().quit(0)
