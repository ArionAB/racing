extends Node
## Cat de ingropat e carosabilul Cappadociei sub campul de teren.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappBury.tscn -- --track=6
##
## Nu masoara mesh-ul de teren (grila e la ~8 m si rateaza exact punctele
## stramte), ci CAMPUL: `ground_y` la coordonatele fiecarui punct copt. Aia e
## sursa din care se naste si mesh-ul, si coliziunea, si asezarea decorului.
##
## Verdictul e simplu: nicaieri terenul nu are voie sa fie peste asfalt. Marja
## de 0.15 m e cea din probe_branch/probe_overpass (grosimea de racord).

const TOL: float = 0.15


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	if idx < 0:
		push_error("ProbeCappBury: index de pista invalid")
		get_tree().quit(1)
		return
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var s: TrackSideSampler = track.get("_sampler")
	var r := track.routes[0]
	var n := r.baked.size()
	var buried := 0
	var worst := -INF
	var worst_f := 0.0
	var hist: Dictionary = {}
	for i in n:
		var p := r.baked[i]
		var g := s.ground_y(p.x, p.z)
		var d := g - p.y
		if d > worst:
			worst = d
			worst_f = r.frac_at(i)
		if d > 1.0:
			buried += 1
			var b := int(r.frac_at(i) * 20.0)
			hist[b] = int(hist.get(b, 0)) + 1

	print("")
	print("=== %s — carosabil vs. camp de teren ===" % track.track_name)
	print("  puncte coapte           %d" % n)
	print("  ingropate peste 1 m     %d" % buried)
	print("  cel mai adanc           %+.2f m la frac %.3f" % [worst, worst_f])
	if not hist.is_empty():
		var keys := hist.keys()
		keys.sort()
		for k: int in keys:
			print("    frac %.2f-%.2f : %d puncte"
				% [k * 0.05, (k + 1) * 0.05, hist[k]])
	print("")
	var ok := worst <= TOL
	print("VERDICT: %s" % ("OK" if ok else "PROBLEMA (teren peste asfalt)"))
	get_tree().quit(0 if ok else 1)
