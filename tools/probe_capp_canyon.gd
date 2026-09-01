extends Node
## POI D: masoara axa drumului si profilul transversal pe toata portiunea de
## canion (frac 0.40-0.56), ca peretii sa fie asezati pe cote reale, nu ghicite.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	print("baked points: ", n)
	for i in range(40, 57, 1):
		var f := float(i) / 100.0
		var idx := int(round(f * float(n))) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 12) % n]
		var dir := (ahead - p)
		dir.y = 0.0
		dir = dir.normalized()
		var side := Vector3(dir.z, 0.0, -dir.x)
		var hw := track.width_at(f)
		var line := "frac %.2f pos(%7.1f,%6.1f,%7.1f) dir(%+.2f,%+.2f) hw %.1f | lat:" % [
			f, p.x, p.y, p.z, dir.x, dir.z, hw]
		for lat in [-40.0, -28.0, -18.0, -10.0, 10.0, 18.0, 28.0, 40.0]:
			var q: Vector3 = p + side * float(lat)
			line += " %+.0f:%.1f" % [lat, track._sampler.ground_y(q.x, q.z)]
		print(line)
	get_tree().quit(0)
