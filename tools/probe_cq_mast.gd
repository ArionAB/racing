extends Node
## Cat de departe de axa soselei sta turnul macaralei, pe toata vecinatatea.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	var mast := track.get_node_or_null("Macara/Mast") as Node3D
	var haz := track.get_node_or_null("Macara") as Node3D
	print("Macara la %s (yaw din baza)" % haz.global_position)
	if mast: print("Mast la %s" % mast.global_position)
	var r := track.routes[0]
	var n := r.count()
	var best := INF; var bf := 0.0
	for j in n:
		var d := Vector2(r.baked[j].x - haz.global_position.x, r.baked[j].z - haz.global_position.z).length()
		if absf(r.baked[j].y - haz.global_position.y) > 12.0: continue
		if d < best: best = d; bf = r.frac_at(j)
	print("cel mai apropiat punct de sosea de NODUL macaralei: %.1f m (frac %.4f)" % [best, bf])
	if mast:
		best = INF
		for j in n:
			if absf(r.baked[j].y - mast.global_position.y) > 12.0: continue
			var d := Vector2(r.baked[j].x - mast.global_position.x, r.baked[j].z - mast.global_position.z).length()
			if d < best: best = d; bf = r.frac_at(j)
		print("cel mai apropiat punct de sosea de TURN: %.1f m (frac %.4f), semilatime %.1f" % [
			best, bf, track.width_at_index(int(bf * n) % n)])
	get_tree().quit()
