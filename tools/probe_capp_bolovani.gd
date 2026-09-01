extends Node
## Bolovanii de pe poala EXISTA in geometrie? Si cat de mari sunt in metri?
##
## Sonda numara triunghiurile adaugate de ChimneyShape peste mesh-ul original si
## masoara gabaritul celor mai mari fragmente. Exista fiindca in captura poala
## arata mai departe ca o duna neteda, iar "am adaugat bolovani" e o afirmatie
## despre COD pana cand cineva masoara geometria.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappBolovani.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 4:
		await get_tree().process_frame

	var seen := 0
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if not (nd is Node3D):
			continue
		var sh := nd as ChimneyShape
		if sh == null:
			continue
		if sh.talus_rocks <= 0:
			continue
		if seen >= 3:
			continue
		seen += 1
		var scale_y := sh.global_basis.get_scale().y
		print("")
		print("=== %s  (talus_rocks=%d, rock_max=%.3f, spread=%.2f) ===" % [
			sh.name, sh.talus_rocks, sh.talus_rock_max, sh.talus_spread])
		print("  scara instantei: %.2f" % scale_y)
		var s2: Array[Node] = [sh]
		while not s2.is_empty():
			var q: Node = s2.pop_back()
			for c in q.get_children():
				s2.append(c)
			var mi := q as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			print("  mesh %s: %d suprafete" % [mi.name, mi.mesh.get_surface_count()])
			for si in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var aabb := AABB(v[0], Vector3.ZERO)
				for p in v:
					aabb = aabb.expand(p)
				print("    supr %d: %d vertecsi, gabarit local (%.2f x %.2f x %.2f) => in metri (%.2f x %.2f x %.2f)" % [
					si, v.size(), aabb.size.x, aabb.size.y, aabb.size.z,
					aabb.size.x * scale_y, aabb.size.y * scale_y, aabb.size.z * scale_y])
	print("")
	get_tree().quit(0)
