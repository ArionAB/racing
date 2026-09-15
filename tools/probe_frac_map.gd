extends Node
## Traducere fractie <-> pozitie pe axa unei piste, pentru cand se redeseneaza
## LOCAL o bucata din traseu: toate declaratiile in fractii (rape, sectoare de
## latime, intervale de suprafata) raman legate de POZITII din lume, deci dupa
## ce se schimba lungimea curbei trebuie recalculate. Doi pasi:
##
##   1. PE SCENA VECHE: fractiile -> pozitii
##      godot --headless --path . res://tools/ProbeFracMap.tscn -- --track=8 --fracs=0.04,0.2,0.912
##   2. PE SCENA NOUA: pozitiile -> fractii
##      godot --headless --path . res://tools/ProbeFracMap.tscn -- --track=8 --points=-105,150;-90,151
##
## Tipareste si lungimea rutei principale, ca sa se vada cu cat s-a schimbat.

func _ready() -> void:
	await get_tree().process_frame
	var idx := 8
	var fracs: PackedFloat32Array = PackedFloat32Array()
	var points: Array[Vector2] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--fracs="):
			for s in arg.trim_prefix("--fracs=").split(","):
				fracs.append(float(s))
		elif arg.begins_with("--points="):
			for s in arg.trim_prefix("--points=").split(";"):
				var xy := s.split(",")
				points.append(Vector2(float(xy[0]), float(xy[1])))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.count()
	print("")
	print("=== %s: ruta principala %.1f m, %d puncte coapte ===" % [track.track_name, r.length(), n])
	for f in fracs:
		var i := int(fposmod(f, 1.0) * float(n)) % n
		var p: Vector3 = r.baked[i]
		print("  frac %.4f -> (%.2f, %.2f, %.2f)" % [f, p.x, p.y, p.z])
	for q in points:
		var best := 0
		var best_d := INF
		for i in n:
			var p: Vector3 = r.baked[i]
			var d := Vector2(p.x, p.z).distance_squared_to(q)
			if d < best_d:
				best_d = d
				best = i
		var p: Vector3 = r.baked[best]
		var dd: PackedFloat32Array = track.get("_dists")
		print("  punct (%.2f, %.2f) -> frac index %.4f / lungime %.4f  (pe axa la %.2f m: %.2f, %.2f, %.2f)"
			% [q.x, q.y, r.frac_at(best), dd[best] / dd[n], sqrt(best_d), p.x, p.y, p.z])
	# --compare: fractia pe INDEX (TrackRoute.frac_at = i/n, folosita la
	# rulare prin frac_at(road_index)) fata de fractia pe LUNGIME
	# (_dists[i]/total, folosita de constructorii de pista). Coincid doar cand
	# punctele coapte sunt uniform distantate.
	if "--compare" in OS.get_cmdline_user_args():
		var dists: PackedFloat32Array = track.get("_dists")
		var total: float = dists[n]
		var worst := 0.0
		var worst_i := 0
		for i in range(0, n, 25):
			var fi := float(i) / float(n)
			var fd := dists[i] / total
			if absf(fi - fd) > worst:
				worst = absf(fi - fd)
				worst_i = i
			if i % 100 == 0:
				print("  i=%4d  index %.4f  lungime %.4f  diferenta %+.4f (%+.1f m)  pas mediu local %.2f m"
					% [i, fi, fd, fi - fd, (fi - fd) * total,
						(dists[mini(i + 25, n)] - dists[i]) / 25.0])
		print("  diferenta maxima index-lungime: %.4f (%.1f m) la i=%d" % [worst, worst * total, worst_i])
	track.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
