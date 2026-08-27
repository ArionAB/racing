extends Node
## Se potriveste modulul pasajului rotativ cu soseaua? Modulul e DREPT (local Z)
## si ORIZONTAL (cota nodului); soseaua se curbeaza si urca. Sonda masoara
## amandoua abaterile pe toata lungimea modulului, pentru mai multe fractii.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var L := r.length()
	var reach := 5.92 + 34.0 + 30.0
	print("modulul are +-%.0f m. Coloane: abaterea LATERALA max (m) / diferenta de COTA max (m)" % reach)
	print("frac   |  +-40 m        +-70 m")
	var ff := 0.44
	var cand: Array[float] = []
	while ff < 0.60:
		cand.append(ff)
		ff += 0.005
	for f: float in cand:
		var i := int(round(f * float(n))) % n
		var c := r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		fwd.y = 0.0
		fwd = fwd.normalized()
		var sidev := Vector3(fwd.z, 0.0, -fwd.x)
		var line := "%.3f |" % f
		for rr: float in [40.0, reach]:
			var dev := 0.0
			var dy := 0.0
			var d := -rr
			while d <= rr:
				var idx := ((i + int(round(d / L * float(n)))) % n + n) % n
				var p := r.baked[idx]
				dev = maxf(dev, absf((p - c).dot(sidev)))
				dy = maxf(dy, absf(p.y - c.y))
				d += 2.0
			line += "  lat %5.1f  dy %5.1f |" % [dev, dy]
		print(line)
	get_tree().quit()
