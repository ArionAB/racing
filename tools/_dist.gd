extends Node
## Cat de aproape de axa soselei (pe orice etaj de aceeasi cota) ajunge fiecare
## prop din zonele mele. Prinde exact ce a pus generatorul prea aproape.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var dm := track.get_node_or_null("DecorManual")
	for zone in dm.get_children():
		if not zone is Node3D: continue
		if not str(zone.name).begins_with("5)") and not str(zone.name).begins_with("6)") \
				and not str(zone.name).begins_with("7)") and not str(zone.name).begins_with("8)"): continue
		for c in zone.get_children():
			if not c is Node3D: continue
			var p := (c as Node3D).global_position
			var best := INF; var bw := 0.0; var bf := 0.0
			for j in n:
				if absf(r.baked[j].y - p.y) > 8.0: continue
				var d := Vector2(r.baked[j].x - p.x, r.baked[j].z - p.z).length()
				if d < best: best = d; bw = track.width_at_index(j); bf = r.frac_at(j)
			if best < bw + 4.0:
				print("  APROAPE: %s/%s la %.1f m de axa (semilatime %.1f, frac %.3f)" % [
					zone.name, c.name, best, bw, bf])
	get_tree().quit()
