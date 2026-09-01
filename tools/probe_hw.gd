extends Node
## Cat e LATIMEA reala a benzii pe POI F, si unde cade fiecare rand de piese
## fata de ea. Fara cifra asta, "grohotisul e prea in afara" ramane o parere.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	print("frac   hw     poala   perete  grohotis(gros..fin)")
	for f in [0.66, 0.68, 0.70, 0.72, 0.74]:
		var hw: float = track.width_at(f)
		print("%.2f   %5.2f  %6.2f  %6.2f   %.2f .. %.2f" % [
			f, hw, hw + 0.55, hw + 2.6 + 3.4,
			hw - 0.35 + 2.3, hw - 0.35 + 0.1])
	get_tree().quit()
