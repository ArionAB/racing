extends Node
## Ce vede CAMERA, nu raza pe normala: se trag raze prin grila cadrului din
## pozitia si orientarea reala a camerei de urmarire, si se raporteaza, pentru
## jumatatea DREAPTA a imaginii, cate lovesc teren si la ce cota fata de drum.
## Asta e testul de silueta al criticului in spatiul ecranului.
const W := 24
const H := 14
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.24, 0.28, 0.32]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 8) % n]
		var fwd: Vector3 = (a - p).normalized()
		# camera de urmarire: in spate si deasupra, privind usor in jos
		var eye: Vector3 = p - fwd * 7.0 + Vector3.UP * 3.2
		var tgt: Vector3 = p + fwd * 10.0 + Vector3.UP * 1.0
		var cf: Vector3 = (tgt - eye).normalized()
		var cr: Vector3 = cf.cross(Vector3.UP).normalized()
		var cu: Vector3 = cr.cross(cf).normalized()
		var fov := deg_to_rad(75.0)
		var tanv := tan(fov * 0.5)
		var tally := {}
		var dist_sum := {}
		var ground := 0
		var near := 0
		var sky := 0
		var above := 0
		for yy in H:
			for xx in W:
				var sx := (float(xx) + 0.5) / W * 2.0 - 1.0
				if sx > -0.15: continue   # jumatatea dinspre MAL (stanga)
				var sy := 1.0 - (float(yy) + 0.5) / H * 2.0
				var d: Vector3 = (cf + cr * (sx * tanv * 16.0/9.0) + cu * (sy * tanv)).normalized()
				var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 500.0)
				var hit := space.intersect_ray(q)
				if hit.is_empty(): sky += 1; continue
				var hp0: Vector3 = hit["position"]
				if eye.distance_to(hp0) < 4.0:
					near += 1
					continue
				ground += 1
				if true:
					above += 1
					var col = hit["collider"]
					var hp: Vector3 = hit["position"]
					var key := str(col.name)
					tally[key] = tally.get(key, 0) + 1
					var dd := eye.distance_to(hp)
					dist_sum[key] = dist_sum.get(key, 0.0) + dd
		var tot := ground + sky
		for k in tally:
			print("     %-28s %4d raze, distanta medie %.0f m" % [k, tally[k],
				float(dist_sum[k]) / float(tally[k])])
		print("frac %.2f | dincolo de 25 m: teren %3d%% cer %3d%% (aproape/drum %d raze) | din teren, la/peste cota drumului: %3d%%"
			% [f, 100 * ground / maxi(tot, 1), 100 * sky / maxi(tot, 1), near,
			   (100 * above / ground) if ground > 0 else 0])
	print("(teren la cota drumului in jumatatea dreapta = podea la nivelul ochiului)")
	get_tree().quit(0)
