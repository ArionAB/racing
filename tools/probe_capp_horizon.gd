extends Node
## De ce 3 din 6 siluete Erciyes nu incap: pentru fiecare slot al inelelor
## se cauta ca in `_build_horizon` si se raporteaza degajarea MAXIMA obtinuta
## pe raza disponibila. Fara asta, coborarea lui `clear` e o ghicitoare.
##   godot --headless --path . res://tools/ProbeCappHorizon.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(13)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var centroid := Vector3.ZERO
	for p in track.baked:
		centroid += p
	centroid /= float(track.baked.size())
	centroid.y = 0.0
	var rings: Array = track.theme_flag("horizon_rings", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x40D1
	print("")
	print("=== siluete de orizont: ce degajare se poate obtine ===")
	print("  centroid = (%.1f, %.1f)" % [centroid.x, centroid.z])
	for ri in rings.size():
		var ring: Dictionary = rings[ri]
		var count := int(ring["count"])
		var arc := TAU / float(count)
		var clear := float(ring["clear"])
		var limit: float = maxf(float(ring["far"]) + 90.0, 355.0)
		print("  inel %d: near=%.0f far=%.0f clear=%.0f limita=%.0f" % [
			ri, float(ring["near"]), float(ring["far"]), clear, limit])
		for slot in count:
			var angle := float(slot) * arc + rng.randf_range(-arc * 0.35, arc * 0.35)
			var best := -1.0
			var best_d := 0.0
			var hit := -1.0
			var d := float(ring["near"])
			while d <= limit:
				var cand := centroid + Vector3(cos(angle), 0, sin(angle)) * d
				var rd := track._road_distance_xz(cand)
				if rd > best:
					best = rd
					best_d = d
				if hit < 0.0 and rd >= clear:
					hit = d
				d += 6.0
			print("    slot %d unghi=%6.1f°  max_degajare=%6.1f m (la %.0f m)  %s" % [
				slot, rad_to_deg(angle), best, best_d,
				("OK la %.0f m" % hit) if hit > 0.0 else "NU INCAPE"])
	get_tree().quit(0)
