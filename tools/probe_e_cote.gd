extends Node
## Cota soselei pe TOATA pista (POI E, runda 4): un tint pe cota (strata_tint)
## atinge tot ce e sub linie, deci trebuie stiut daca linia trece pe sub drum
## peste tot sau doar in zona craterului.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var lo := 1e9
	var hi := -1e9
	var line := ""
	for k in 20:
		var f := float(k) / 20.0
		var p: Vector3 = r.baked[int(f * float(n)) % n]
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
		line += " %.2f:%.0f" % [f, p.y]
	print("COTA DRUM%s" % line)
	print("min=%.1f max=%.1f" % [lo, hi])
	get_tree().quit(0)
