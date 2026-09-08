extends Node
## Cota reala a terenului pe inelul de crusta, ca discurile sa nu fie ingropate.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var track := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var cx := 0.0
	var cz := -68.0
	var out := PackedStringArray()
	for ri in range(0, 12):
		var r := 44.0 + float(ri) * 5.0
		var line := "r=%.0f:" % r
		for ai in range(0, 8):
			var a := TAU * float(ai) / 8.0
			var x := cx + cos(a) * r
			var z := cz + sin(a) * r
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, 90, z), Vector3(x, -40, z))
			var hit := space.intersect_ray(q)
			line += " %s" % (("%.1f" % float(hit.position.y)) if not hit.is_empty() else "--")
		print(line)
	get_tree().quit(0)
