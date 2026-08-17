extends Node
## Sonda benzilor secundare: pentru fiecare scurtatura, cota benzii fata de
## terenul de sub ea, punct cu punct — o banda INGROPATA (teren peste ea) nu
## se vede si nu se poate conduce.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBranch.tscn -- --track=2

func _ready() -> void:
	var track_index := 2
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var sampler: TrackSideSampler = track.get("_sampler")
	for bi in range(1, track.routes.size()):
		var r: TrackRoute = track.routes[bi]
		print("ruta %d '%s': %d puncte, %.0f m, hw %.1f, suprafata %s, speed %.2f"
			% [bi, r.label, r.count(), r.length(), r.half_width, r.surface,
			r.speed_factor])
		var buried := 0
		var worst := 0.0
		for i in r.count():
			var p := r.baked[i]
			var g := sampler.ground_y(p.x, p.z)
			var d := g - p.y
			if d > 0.15:
				buried += 1
			worst = maxf(worst, d)
			if i % 8 == 0:
				print("  [%3d] (%.0f, %.1f, %.0f) teren %.1f  diff %+.2f" % [i, p.x, p.y, p.z, g, d])
		print("  ingropate: %d/%d, cel mai adanc %.2f m" % [buried, r.count(), worst])
	get_tree().quit()
