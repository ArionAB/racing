extends Node
## Calculeaza asezarea blocurilor din geometria REALA: cadrul curbei baked,
## profilul terenului prin raycast si linia de vedere care rade buza.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	# 1) profilul fin pe partea rapei (right +), pe fractiile blocurilor
	for f: float in [0.004, 0.010, 0.016, 0.022]:
		var s: float = f * L
		var p := c.sample_baked(s)
		var p2 := c.sample_baked(minf(s + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		print("--- frac %.3f road=(%.1f,%.2f,%.1f) fwd=(%.3f,%.3f) right=(%.3f,%.3f)"
			% [f, p.x, p.y, p.z, fwd.x, fwd.z, right.x, right.z])
		var prof := ""
		var terr: Array[float] = []
		var ds: Array[float] = []
		for i in range(3, 31):
			var d: float = float(i)
			var o: Vector3 = p + right * d + Vector3.UP * 60.0
			var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 220.0)
			var h := space.intersect_ray(q)
			var y: float = h.position.y if not h.is_empty() else -99.0
			terr.append(y); ds.append(d)
			if i % 2 == 1: prof += " %d:%.0f" % [i, y]
		print("   teren:" + prof)
		# 2) linia de vedere: ochiul la 10 m peste sosea, pe axa; si la 4 m spre rapa
		for eye_lat: float in [0.0, 4.0]:
			var eye_y: float = p.y + 10.0
			var best_m := -1e9
			var best_d := 0.0
			for i in range(terr.size()):
				if ds[i] <= eye_lat: continue
				var m: float = (terr[i] - eye_y) / (ds[i] - eye_lat)
				if m > best_m: best_m = m; best_d = ds[i]
			var msg := "   ochi lat=%.0f: buza la d=%.0f, panta=%.2f ->" % [eye_lat, best_d, best_m]
			for d: float in [10.0, 12.0, 14.0, 16.0, 18.0, 20.0]:
				msg += " d%.0f<%.0f" % [d, eye_y + best_m * (d - eye_lat)]
			print(msg)
	get_tree().quit()
