extends Node
## Dovada de neutralitate pentru `shoulder_zones_are_road` (Jodhpur POI H):
## compara `Track.is_on_road` cu formula DE DINAINTE (copiata aici) pe o grila
## de puncte in jurul traseului, pe ruta 0.
##
##   godot --headless --path . res://tools/SvOnRoadDiff.tscn -- --scene=16
##
## Pe orice pista fara cheia de tema: 0 diferente (asta e dovada). Pe Jodhpur:
## diferentele sunt doar in fasia pavata (raporteaza intervalul lateral si
## fractiile).

func _ready() -> void:
	var scene := 17
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = int(a.trim_prefix("--scene="))
	var tr := (load("res://scenes/tracks/Track%02d.tscn" % scene) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	var r := tr.route_at(0)
	var n := r.count()
	var tested := 0
	var diff := 0
	var lat_min := INF
	var lat_max := -INF
	var fr_min := INF
	var fr_max := -INF
	var hist := {}
	for i in range(0, n, 2):
		var p: Vector3 = r.baked[i]
		var side := r.side_at(i)
		var lat := -16.0
		while lat <= 16.0:
			var q := p + side * lat + Vector3.UP * 0.5
			var old := _old(tr, i, q)
			var neu := tr.is_on_road(i, q, 0)
			tested += 1
			if old != neu:
				diff += 1
				lat_min = minf(lat_min, absf(lat))
				lat_max = maxf(lat_max, absf(lat))
				fr_min = minf(fr_min, float(i) / n)
				fr_max = maxf(fr_max, float(i) / n)
				var b := int(float(i) / n * 20.0)
				hist[b] = int(hist.get(b, 0)) + 1
			lat += 0.25
	print("Track%02d: %d puncte, %d diferente" % [scene, tested, diff])
	if diff > 0:
		print("  |lat| %.2f .. %.2f m, frac %.3f .. %.3f" % [lat_min, lat_max, fr_min, fr_max])
		var keys := hist.keys()
		keys.sort()
		for b in keys:
			print("  felia %.2f-%.2f: %d" % [b / 20.0, (b + 1) / 20.0, hist[b]])
	get_tree().quit(0)


func _old(tr: Track, index: int, pos: Vector3) -> bool:
	var r := tr.route_at(0)
	if tr._width_profile().is_empty():
		return r.is_on_road(index, pos)
	if r.lateral_distance(index, pos) > tr.width_at_index(index) + 0.5:
		return false
	return not r.is_other_level(index, pos)
