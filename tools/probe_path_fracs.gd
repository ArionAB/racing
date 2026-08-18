extends Node
## Fractia de tur a FIECARUI punct de control din nodul "Path" al unei piste.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePathFracs.tscn -- --track=N
##
## Pentru pistele desenate in editor (TrackFromPath): tragi punctele, apoi vrei
## sa scrii intervale (`custom_ice_ranges`, `custom_wet_ranges`, `custom_ravines`)
## sau fractii — si fractia unui punct de control nu se citeste din desen.
## Sonda o tipareste pe fiecare, cu cota si distanta parcursa, plus media
## cotelor drumului (de care depinde `custom_sea_level_offset`).

func _ready() -> void:
	await get_tree().process_frame
	var idx := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r := track.routes[0]
	var n := r.count()
	var mean_y := 0.0
	var y_min := INF
	var y_max := -INF
	for p in r.baked:
		mean_y += p.y
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
	mean_y /= maxf(float(n), 1.0)
	print("")
	print("=== %s — %s ===" % [scene.resource_path.get_file(), track.track_name])
	print("lungime bucla: %.1f m (%d puncte coapte)" % [r.length(), n])
	print("cota drum: min %.1f, medie %.2f, max %.1f" % [y_min, mean_y, y_max])
	print("mean_road_y (sampler): %.2f  -> sea_y = %.2f" % [
		track._sampler.mean_road_y(),
		track._sampler.mean_road_y() + track.sea_level_offset])
	var path := track.get_node_or_null("Path") as Path3D
	if path == null or path.curve == null:
		print("(fara nod Path)")
		return
	print("")
	for k in path.curve.point_count:
		var p := path.curve.get_point_position(k)
		var best := 0
		var best_d := INF
		for i in n:
			var d := Vector2(r.baked[i].x - p.x, r.baked[i].z - p.z).length_squared()
			if d < best_d:
				best_d = d
				best = i
		# Cota terenului la 20 m stanga/dreapta de axa: spune dintr-o privire
		# daca rapa/laguna/muntele declarat chiar au ajuns acolo.
		var side := track._side_at(best)
		var tr := ""
		for m: float in [20.0, 50.0, 90.0]:
			var gl := track._sampler.ground_y(
				r.baked[best].x - side.x * m, r.baked[best].z - side.z * m)
			var gr := track._sampler.ground_y(
				r.baked[best].x + side.x * m, r.baked[best].z + side.z * m)
			tr += "  @%dm L %5.1f R %5.1f" % [int(m), gl, gr]
		print("P%02d (%6.1f, %5.1f, %7.1f)  frac %.3f  dist %7.1f m%s" % [
			k, p.x, p.y, p.z, r.frac_at(best), r.frac_at(best) * r.length(), tr])
	get_tree().quit()
