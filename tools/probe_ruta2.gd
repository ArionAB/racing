extends Node
## Masuratori pentru A DOUA RUTA prin gatul cu piatra (Cappadocia, POI F).
## Tipareste: lungimea buclei, pozitii/latimi pe frac 0.68-0.74, hazardul
## pietrei (centru, cursa, raza), si profilul terenului la est de drum.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRuta2.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var total: float = r.dists[n]
	print("RUTE: %d" % track.routes.size())
	for bi in track.routes.size():
		var b := track.routes[bi]
		print("  ruta %d '%s' puncte=%d lung=%.1f hw=%.2f entry=%.4f exit=%.4f" % [
			bi, b.label, b.count(), b.dists[b.count() - (0 if b.closed else 1)],
			b.half_width, b.entry_frac, b.exit_frac])
	print("BUCLA: n=%d total=%.1f m  (30 m = %.5f frac)" % [n, total, 30.0 / total])
	for k in range(int(0.680 / 0.002), int(0.742 / 0.002)):
		var f := k * 0.002
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw: Vector3 = (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		print("f=%.3f  pos=(%.1f, %.2f, %.1f)  fw=(%.2f, %.2f)  hw=%.2f" % [
			f, c.x, c.y, c.z, fw.x, fw.z, track.width_at(f)])
	# Piatra de moara
	for hz in track.get_children():
		if hz is SlidingHazard:
			var s := hz as SlidingHazard
			if s.center.distance_to(Vector3(-319.5, 12.8, -103.6)) < 25.0:
				print("PIATRA: center=(%.2f, %.2f, %.2f) travel=(%.2f, %.2f, %.2f) |t|=%.2f raza=%.2f perioada=%.2f" % [
					s.center.x, s.center.y, s.center.z,
					s.travel.x, s.travel.y, s.travel.z, s.travel.length(),
					s.roll_radius, s.period])
	# Teren la est (interior): raycast in jos, fan lateral
	var space := get_tree().root.world_3d.direct_space_state
	for k in range(int(0.700 / 0.004), int(0.752 / 0.004) + 1):
		var f := k * 0.004
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw: Vector3 = (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var row := "TEREN f=%.3f: " % f
		for lat: float in [-30.0, -24.0, -18.0, -12.0, 12.0, 16.0, 20.0, 24.0, 28.0, 34.0, 40.0]:
			var p := c + side * lat
			var q := PhysicsRayQueryParameters3D.create(
				p + Vector3.UP * 60.0, p + Vector3.DOWN * 60.0)
			q.collision_mask = 0xFFFFFFFF
			var hit := space.intersect_ray(q)
			row += "%5.1f@%2.0f " % [(hit["position"].y - c.y) if hit else -99.0, lat]
		print(row)
	# Ruta 1 (ocolul): puncte coapte + teren pe axul ei
	if track.routes.size() > 1:
		var b := track.routes[1]
		var bn := b.count()
		print("OCOL: puncte=%d lung=%.1f" % [bn, b.dists[bn - 1]])
		for i in range(0, bn, 4):
			var c2: Vector3 = b.baked[i]
			var q2 := PhysicsRayQueryParameters3D.create(
				c2 + Vector3.UP * 50.0, c2 + Vector3.DOWN * 50.0)
			q2.collision_mask = 0xFFFFFFFF
			var h2 := space.intersect_ray(q2)
			print("  ocol i=%3d frac=%.4f pos=(%.1f, %.2f, %.1f) sol=%.2f" % [
				i, b.frac_at(i), c2.x, c2.y, c2.z,
				(h2["position"].y - c2.y) if h2 else -99.0])
	get_tree().quit()
