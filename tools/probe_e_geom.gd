extends Node
## Sectiune transversala pe buza craterului (POI E): cota terenului la
## distante laterale, ca sa stim daca "fundul craterului" e un bazin sau
## un plan de mare deschisa.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var space := track.get_world_3d().direct_space_state
	for f in [0.36, 0.40, 0.45, 0.482]:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var p2: Vector3 = r.baked[(i + 6) % n]
		var fwd := (p2 - p).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		print("--- frac=%.3f road=(%.1f,%.1f,%.1f) side=(%.2f,%.2f)" % [f, p.x, p.y, p.z, side.x, side.z])
		for lbl in ["R", "L"]:
			var sgn := 1.0 if lbl == "R" else -1.0
			var line := ""
			for d in [8, 15, 25, 40, 60, 90, 130, 180, 240]:
				var o: Vector3 = p + side * (sgn * float(d))
				var q := PhysicsRayQueryParameters3D.create(o + Vector3(0, 150, 0), o + Vector3(0, -200, 0))
				var hit := space.intersect_ray(q)
				line += " %d:%s" % [d, ("%.1f" % float(hit.position.y)) if not hit.is_empty() else "--"]
			print("   %s%s" % [lbl, line])
	var sea := track.find_child("Sea", true, false)
	if sea != null and sea is Node3D:
		print("SEA y=%.2f" % (sea as Node3D).global_position.y)
	for c in track.get_children():
		if c is DirectionalLight3D:
			print("SUN %s rot_deg=%s" % [c.name, str((c as Node3D).rotation_degrees)])
	get_tree().quit(0)
