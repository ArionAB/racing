extends Node
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var sea := track._sampler.mean_road_y() + track.sea_level_offset
	print("apa la %.2f" % sea)
	var dm := track.get_node_or_null("DecorManual")
	for zone in dm.get_children():
		if not zone is Node3D: continue
		for c in zone.get_children():
			if not c is Node3D: continue
			var p := (c as Node3D).global_position
			var g := track._sampler.ground_y(p.x, p.z)
			if g < sea + 0.3 and p.y > sea - 2.0:
				print("  IN APA: %s/%s la (%.1f, %.1f, %.1f), teren %.2f" % [zone.name, c.name, p.x, p.y, p.z, g])
	get_tree().quit()
