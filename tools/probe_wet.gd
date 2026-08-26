extends Node
## Sonda "interiorul buclei ramane uscat" (Chongqing, brief §2): pe o grila de
## 10 m, cate puncte din INTERIORUL poligonului pistei au terenul sub cota apei.
## Plus profilul transversal (ambele parti) pe fractiile date.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWet.tscn
##   ... -- [--scene=res://scenes/tracks/Track12.tscn] [--step=10]
##          [--fracs=0.50,0.52,0.54,0.56,0.59]

func _ready() -> void:
	var scene := "res://scenes/tracks/Track12.tscn"
	var step := 10.0
	var fracs: Array[float] = [0.48, 0.50, 0.52, 0.54, 0.56, 0.59, 0.62]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--step="):
			step = float(arg.trim_prefix("--step="))
		elif arg.begins_with("--fracs="):
			fracs.clear()
			for t in arg.trim_prefix("--fracs=").split(","):
				fracs.append(float(t))
	var track: Track = (load(scene) as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	var sampler: TrackSideSampler = track._sampler
	var sea_y: float = sampler.mean_road_y() + track.sea_level_offset
	print("=== ProbeWet %s  apa la %.2f m  grila %.0f m ===" % [scene, sea_y, step])
	var n := track.baked.size()
	var poly := PackedVector2Array()
	var bb_min := Vector2(INF, INF)
	var bb_max := Vector2(-INF, -INF)
	for p in track.baked:
		poly.append(Vector2(p.x, p.z))
		bb_min = bb_min.min(Vector2(p.x, p.z))
		bb_max = bb_max.max(Vector2(p.x, p.z))
	var wet := 0
	var total := 0
	var wet_fracs := {}
	var x := bb_min.x
	while x <= bb_max.x:
		var z := bb_min.y
		while z <= bb_max.y:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), poly):
				total += 1
				if sampler.ground_y(x, z) < sea_y:
					wet += 1
					var best := 0
					var best_d := INF
					for i in n:
						var d := Vector2(track.baked[i].x, track.baked[i].z).distance_squared_to(Vector2(x, z))
						if d < best_d:
							best_d = d
							best = i
					var f := snappedf(float(best) / float(n), 0.01)
					wet_fracs[f] = int(wet_fracs.get(f, 0)) + 1
			z += step
		x += step
	print("  interior: %d puncte, %d ude" % [total, wet])
	if wet > 0:
		print("  ude pe fractii: %s" % str(wet_fracs))
	var offsets := [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 40.0]
	var header := "  frac   drum |"
	for o in offsets:
		header += " L%-3d" % int(o)
	header += " |"
	for o in offsets:
		header += " R%-3d" % int(o)
	print(header)
	for f in fracs:
		var i := int(f * float(n)) % n
		var p: Vector3 = track.baked[i]
		var s: Vector3 = track._side_at(i)
		var line := "  %.2f  %5.1f |" % [f, p.y]
		for o in offsets:
			var y: float = sampler.ground_y(p.x - s.x * o, p.z - s.z * o)
			line += " %4.1f%s" % [y, "~" if y < sea_y else " "]
		line += " |"
		for o in offsets:
			var y: float = sampler.ground_y(p.x + s.x * o, p.z + s.z * o)
			line += " %4.1f%s" % [y, "~" if y < sea_y else " "]
		print(line + "   (~ = sub apa; L = stanga/interior)")
	print("VERDICT: %s (%d puncte ude in interior)" % ["OK" if wet == 0 else "PICAT", wet])
	get_tree().quit(1 if wet > 0 else 0)
