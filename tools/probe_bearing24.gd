extends Node
## La 0.24 normala pleaca spre interiorul serpentinei. Pe ce AZIMUT e valea
## adevarata, si cat de departe trece drumul propriu pe fiecare directie?
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.22, 0.24, 0.26]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var fwd: Vector3 = (a - p).normalized()
		print("--- frac %.2f drum(%.0f,%.0f) y=%.1f" % [f, p.x, p.z, p.y])
		for az in [0, 30, 60, 90, 120, 150, 180, -30, -60, -90]:
			var d: Vector3 = fwd.rotated(Vector3.UP, deg_to_rad(-float(az)))
			# cota terenului la 60 m, si cat de aproape e alt tronson
			var q: Vector3 = p + d * 60.0
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 250.0, q.z), Vector3(q.x, p.y - 350.0, q.z))
			var hit := space.intersect_ray(ray)
			var dy := 999.0
			if hit: dy = float(hit["position"].y) - p.y
			var best := INF
			for j in n:
				var dj: int = absi(j - i); dj = mini(dj, n - dj)
				if dj < int(0.03 * n): continue
				var dd := Vector2(q.x - r.baked[j].x, q.z - r.baked[j].z).length()
				best = minf(best, dd)
			print("   az %+4d: teren %+7.1f la 60 m | drum propriu la %.0f m" % [az, dy, best])
	get_tree().quit(0)
