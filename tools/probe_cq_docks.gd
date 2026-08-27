extends Node
## Unde stau peroanele telecabinei fata de sosea, si pe ce cota.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	var haz := track.get_node_or_null("PasajRotativ")
	var r := track.routes[0]
	var n := r.count()
	for child in haz.get_children():
		if not (child is Node3D): continue
		var p := (child as Node3D).global_position
		var best := INF; var bf := 0.0; var by := 0.0; var bw := 0.0
		for j in n:
			if absf(r.baked[j].y - p.y) > 10.0: continue
			var d := Vector2(r.baked[j].x - p.x, r.baked[j].z - p.z).length()
			if d < best: best = d; bf = r.frac_at(j); by = r.baked[j].y; bw = track.width_at_index(j)
		print("%-10s la (%.1f, %.1f, %.1f)  sosea la %5.1f m (frac %.3f, y %.1f, hw %.1f)  dy %+.1f" % [
			child.name, p.x, p.y, p.z, best, bf, by, bw, p.y - by])
	get_tree().quit()
