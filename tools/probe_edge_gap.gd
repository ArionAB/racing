extends Node
## Marginea drumului: e perete lipit, sol continuu sau GOL in care poti cadea?
## Pe fiecare punct copt din intervalul de fractii, pe ambele parti:
##   perete — raza orizontala de la muchie spre afara, la 1 m inaltime;
##   gol    — raze in jos la 0,5 / 1,5 m dincolo de muchie: daca solul e la
##            peste `--drop` m sub asfalt (sau lipseste), acolo cazi.
## Raporteaza intervalele continue cu gol, pe parte (stanga/dreapta in sensul
## de mers), cu latimea golului pana la perete.
##   godot --headless --path . res://tools/ProbeEdgeGap.tscn -- --track=6 --frac=0.76,0.99 [--drop=2]

var _f0 := 0.0
var _f1 := 1.0
var _drop := 2.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			var p := arg.trim_prefix("--frac=").split(",")
			_f0 = float(p[0])
			_f1 = float(p[1])
		elif arg.begins_with("--drop="):
			_drop = float(arg.trim_prefix("--drop="))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().physics_frame
	var r: TrackRoute = track.route_at(0)
	var space := track.get_world_3d().direct_space_state
	var total := 0
	for side_sign: float in [1.0, -1.0]:
		var label := "dreapta" if side_sign > 0.0 else "stanga"
		var run_start := -1.0
		var run_last := -1.0
		var run_wall := 0.0
		var run_n := 0
		var runs: PackedStringArray = []
		for i in r.baked.size():
			var f := track.frac_at(i)
			if f < _f0 or f > _f1:
				continue
			total += 1
			var p := r.baked[i]
			var side := r.side_at(i) * side_sign
			var hw := track.width_at_index(i)
			var edge := p + side * hw
			# Perete: raza orizontala de la muchie spre afara.
			var wq := PhysicsRayQueryParameters3D.create(edge + Vector3.UP * 1.0,
				edge + Vector3.UP * 1.0 + side * 8.0)
			var wh := space.intersect_ray(wq)
			var wall := INF if wh.is_empty() else edge.distance_to(
				Vector3((wh.position as Vector3).x, edge.y, (wh.position as Vector3).z))
			var hole := false
			for off: float in [0.5, 1.5]:
				if off >= wall:
					continue
				var top := edge + side * off + Vector3.UP * 2.0
				var dq := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * (2.0 + _drop))
				if space.intersect_ray(dq).is_empty():
					hole = true
			if hole:
				if run_start < 0.0:
					run_start = f
					run_wall = 0.0
					run_n = 0
				run_last = f
				run_n += 1
				run_wall += wall if wall < INF else 8.0
			elif run_start >= 0.0:
				runs.append("frac %.3f..%.3f (%d puncte, perete la ~%.1f m de muchie)" % [
					run_start, run_last, run_n, run_wall / float(run_n)])
				run_start = -1.0
		if run_start >= 0.0:
			runs.append("frac %.3f..%.3f (%d puncte, perete la ~%.1f m de muchie)" % [
				run_start, run_last, run_n, run_wall / float(run_n)])
		print("[margine] %s: %d intervale cu gol (cadere > %.1f m)" % [label, runs.size(), _drop])
		for s in runs:
			print("    " + s)
	print("[margine] %d puncte verificate pe parte" % (total / 2))
	get_tree().quit(0)
