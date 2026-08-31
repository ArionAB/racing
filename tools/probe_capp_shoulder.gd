extends Node
## Cat de lat si cat de adanc e UMARUL pe elice? Daca masca de pasaj il stinge,
## latimea trebuie sa fie 0 pe tot intervalul declarat.


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	print("frac    on_over  w_left  w_right  y_drum")
	for i in n:
		var f := r.frac_at(i)
		if f < 0.745 or f > 0.82:
			continue
		var over := track._overpass_mix(i) > 0.5
		print("%.4f  %s  %6.2f  %6.2f  %6.2f" % [f, "DA " if over else "nu ",
			track._shoulder_width(i, -1.0), track._shoulder_width(i, 1.0),
			(r.baked[i] as Vector3).y])
	get_tree().quit(0)
