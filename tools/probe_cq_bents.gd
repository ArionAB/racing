extends Node
## Pentru fiecare pila propusa sub pasaj: ce e DEDESUBT (alt tronson de pista?)
func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	print("frac   pos                    | cel mai apropiat alt tronson (dy>10): frac, dist plan, dy")
	var f := 0.700
	while f < 0.890:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var side := track._side_at(i)
		var w := track.width_at_index(i)
		var line := "%.3f (%7.1f,%5.1f,%7.1f) w%.1f |" % [f, p.x, p.y, p.z, w]
		var best := -1
		var bd := INF
		for j in n:
			if absf(r.baked[j].y - p.y) < 10.0: continue
			var d := Vector2(r.baked[j].x - p.x, r.baked[j].z - p.z).length()
			if d < bd: bd = d; best = j
		if best >= 0 and bd < 40.0:
			var q := r.baked[best]
			var lat := (q - p).dot(side)
			line += " frac %.3f  dist %5.1f  dy %5.1f  lat %6.1f  w_jos %.1f" % [
				r.frac_at(best), bd, p.y - q.y, lat, track.width_at_index(best)]
		else:
			line += " —"
		print(line)
		f += 26.0 / 2068.3
	get_tree().quit()
