extends Node
func _ready() -> void:
	await get_tree().process_frame
	var ps := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := ps.instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	for nm in ["PasajRotativ","Macara","CuloarCeata","Monorail","Telecabina3D"]:
		var h = track.find_child(nm, false, false)
		if h == null:
			print("LIPSA ", nm); continue
		var idx := track.closest_index_global(h.global_position)
		var f := float(idx)/float(n)
		var d: float = r.baked[idx].distance_to(h.global_position)
		print("%s: frac %.3f  dist_axa %.2f  hw %.2f  pos %.1f,%.1f,%.1f" % [nm, f, d, track.width_at_index(idx), h.global_position.x, h.global_position.y, h.global_position.z])
	print("--- profil pista 0.60-0.72 ---")
	var i := int(0.60*n)
	while i < int(0.72*n):
		var p: Vector3 = r.baked[i]
		print("  frac %.3f  y %.1f  hw %.1f  pos %.0f,%.0f,%.0f" % [float(i)/float(n), p.y, track.width_at_index(i), p.x, p.y, p.z])
		i += max(1, int(0.01*n))
	get_tree().quit()
