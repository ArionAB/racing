extends Node
## Rapa 3 (0.955-0.048, adancime 42, podea 22) chiar e activa pe fractiile
## pietei? Compar cota terenului la 6/8/10 m cu ce ar trebui sa dea rapa.
## `ravine_at` spune daca sectorul e declarat; terenul spune daca s-a si sapat.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var s = track._sampler
	for f in [0.960, 0.980, 0.000, 0.005, 0.012, 0.020, 0.030, 0.040, 0.047, 0.055]:
		print("frac=%.3f rapa_dreapta=%s rapa_stanga=%s"
			% [f, str(s.ravine_at(f, 1.0)), str(s.ravine_at(f, -1.0))])
	print("adancime_max=%.1f" % s.max_ravine_depth())
	get_tree().quit()
