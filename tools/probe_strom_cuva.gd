extends Node
## Cuva craterului (CraterFall) prinde masini care conduc normal? (#511)
## Compara TAVANUL zonei cu cota CAROSABILULUI pe portiunea care trece prin ea.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeStromCuva.tscn -- --track=4


func _ready() -> void:
	await get_tree().process_frame
	var idx := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	print("[cuva] pista: %s" % GameState.track_label(idx))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().physics_frame
	var zone := _find(track, "CraterFall") as Area3D
	if zone == null:
		print("VERDICT: PROBLEMA — nu gasesc CraterFall")
		get_tree().quit(1)
		return
	var cs := zone.get_node_or_null("Shape") as CollisionShape3D
	var box := cs.shape as BoxShape3D
	var c := zone.global_position + cs.position
	var top := c.y + box.size.y * 0.5
	var x0 := c.x - box.size.x * 0.5
	var x1 := c.x + box.size.x * 0.5
	var z0 := c.z - box.size.z * 0.5
	var z1 := c.z + box.size.z * 0.5
	print("[cuva] centru (%.1f, %.1f, %.1f)  cutie %.0f x %.0f x %.0f" % [
		c.x, c.y, c.z, box.size.x, box.size.y, box.size.z])
	print("[cuva] TAVAN y = %.2f   x %.1f..%.1f   z %.1f..%.1f" % [top, x0, x1, z0, z1])
	var r: TrackRoute = track.route_at(0)
	var n := r.baked.size()
	var inside := 0
	var under := 0
	var worst := -INF
	var worst_f := 0.0
	print("  frac     drum_y   tavan-drum   banda_lata_sub_tavan")
	for i in n:
		var p: Vector3 = r.baked[i]
		if p.x < x0 or p.x > x1 or p.z < z0 or p.z > z1:
			continue
		inside += 1
		# Masina are garda ~0 si centrul la ~0.6 m: daca tavanul e peste
		# carosabil, zona prinde o masina care merge normal.
		var margin := top - p.y
		if margin > -0.2:
			under += 1
			if margin > worst:
				worst = margin
				worst_f = track.frac_at(i)
		if margin > -2.0:
			print("  %.4f  %7.2f   %+8.2f" % [track.frac_at(i), p.y, margin])
	# Cat de adanc e de fapt golul: raza in jos din centrul zonei.
	var space := track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(c.x, top + 40.0, c.z), Vector3(c.x, top - 300.0, c.z))
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		print("[cuva] sub centrul zonei: NIMIC (gol deschis)")
	else:
		print("[cuva] fundul sub centrul zonei: y = %.2f (cu %.1f m sub tavan)"
			% [(hit.position as Vector3).y, top - (hit.position as Vector3).y])
	# Cea mai joasa bucata de carosabil din amprenta — plafonul admis al zonei.
	var lowest := INF
	for i in n:
		var pp: Vector3 = r.baked[i]
		if pp.x < x0 or pp.x > x1 or pp.z < z0 or pp.z > z1:
			continue
		lowest = minf(lowest, pp.y)
	print("[cuva] cel mai jos carosabil din amprenta: y = %.2f  -> marja tavan = %.2f m"
		% [lowest, lowest - top])
	# Cat din amprenta zonei e DEPARTE de orice drum? Acolo, zona nu mai e
	# "plasa sub saritura", ci o capcana pe tot platoul din jurul craterului.
	var far_cells := 0
	var near_cells := 0
	for gx in 26:
		for gz in 26:
			var px := x0 + (float(gx) + 0.5) * (x1 - x0) / 26.0
			var pz := z0 + (float(gz) + 0.5) * (z1 - z0) / 26.0
			var best := INF
			for i2 in n:
				var pp: Vector3 = r.baked[i2]
				best = minf(best, Vector2(pp.x - px, pp.z - pz).length())
			if best > 14.0:
				far_cells += 1
			else:
				near_cells += 1
	print("[cuva] amprenta: %d celule la <14 m de drum, %d celule DEPARTE (>14 m) = %.0f%%"
		% [near_cells, far_cells, 100.0 * float(far_cells) / float(far_cells + near_cells)])
	print("")
	print("[cuva] %d puncte de drum in amprenta zonei; %d au carosabilul SUB tavan" % [inside, under])
	if under > 0:
		print("[cuva] cel mai prost: frac %.4f, tavanul e cu %.2f m PESTE carosabil" % [worst_f, worst])
		print("VERDICT: PROBLEMA — plasa de siguranta prinde masini care conduc pe drum")
	else:
		print("VERDICT: OK — tavanul e sub carosabil peste tot")
	get_tree().quit(0)


func _find(node: Node, want: String) -> Node:
	for c in node.get_children():
		if c.name == want:
			return c
		var d := _find(c, want)
		if d != null:
			return d
	return null
