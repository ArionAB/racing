extends Node
## Cat de mare e treapta dintre tablierul PLAN al pasajului rotativ si soseaua
## care urca sub el, pe toata lungimea modulului, pentru fiecare fractie.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var L := r.length()
	print("frac   deck_run | treapta max (m) intre plan si sosea, pe +-(5.92+deck_run)")
	for f: float in [0.475, 0.480, 0.485, 0.490]:
		var i := int(round(f * float(n))) % n
		var c := r.baked[i]
		for dr: float in [34.0, 46.0, 52.0, 64.0, 70.0]:
			var reach := dr
			var step := 0.0
			var d := -reach
			while d <= reach:
				var idx := ((i + int(round(d / L * float(n)))) % n + n) % n
				step = maxf(step, absf(r.baked[idx].y - c.y))
				d += 1.0
			print("%.3f  %5.1f     | %.2f" % [f, dr, step])
	get_tree().quit()
