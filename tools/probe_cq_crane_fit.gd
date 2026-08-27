extends Node
## Pentru fiecare fractie candidata si fiecare offset lateral: cat de aproape
## ajunge turnul macaralei de axa soselei (pe orice tronson de la aceeasi cota).
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	print("frac   latura off | distanta minima turn-axa (m)   [nevoie: > 7 + 1.8 + 0.5 = 9.3]")
	for f: float in [0.795, 0.805, 0.815, 0.825, 0.845, 0.855, 0.865, 0.875]:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var side := track._side_at(i)
		for sgn: float in [-1.0, 1.0]:
			var line := "%.3f %s " % [f, "dr" if sgn > 0 else "st"]
			for off: float in [11.0, 14.0, 18.0, 22.0]:
				var q := p + side * (off * sgn)
				var best := INF
				for j in n:
					if absf(r.baked[j].y - p.y) > 12.0: continue
					best = minf(best, Vector2(r.baked[j].x - q.x, r.baked[j].z - q.z).length())
				line += " %2.0f->%5.1f" % [off, best]
			print(line)
	get_tree().quit()
