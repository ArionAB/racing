extends Node
func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	for k in track.routes.size():
		var r := track.routes[k]
		print("ruta %d  %s  %d puncte  %.1f m" % [k, r.label if "label" in r else "?", r.count(), r.length()])
		var n := r.count()
		for m in range(0, n, maxi(1, n / 16)):
			print("   f %.3f  (%8.2f, %6.2f, %8.2f)" % [r.frac_at(m), r.baked[m].x, r.baked[m].y, r.baked[m].z])
		print("   ultimul (%8.2f, %6.2f, %8.2f)" % [r.baked[n-1].x, r.baked[n-1].y, r.baked[n-1].z])
	get_tree().quit()
