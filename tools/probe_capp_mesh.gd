extends Node
## Elicea vs. MESH-ul de teren construit — nu campul, ci triunghiurile.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappMesh.tscn -- --track=6
##
## `probe_capp_bury` intreaba `ground_y`, adica sursa. Asta intreaba rezultatul:
## grila de teren e la ~8 m, deci intre nodurile ei suprafata e un plan, si un
## plan poate trece peste asfalt chiar acolo unde campul nu trecea. Se cauta
## triunghiul de teren care acopera fiecare punct copt si se compara cotele.

const TOL: float = 0.15


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	# Raycast de sus in jos pe fiecare punct copt: exact ce fac rotile.
	var space := track.get_world_3d().direct_space_state
	var r := track.routes[0]
	var n := r.baked.size()
	var worst := -INF
	var worst_f := 0.0
	var over := 0
	var tested := 0
	for i in n:
		var p := r.baked[i]
		# Se porneste de SUB asfalt (0.4 m) ca sa nu se loveasca de carosabilul
		# insusi, si se trage in jos: ce se atinge acolo e teren.
		var q := PhysicsRayQueryParameters3D.create(
			p + Vector3(0.0, -0.4, 0.0), p + Vector3(0.0, -60.0, 0.0))
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		tested += 1
		var d := float(hit["position"].y) - (p.y - 0.4)
		if d > worst:
			worst = d
			worst_f = r.frac_at(i)
		if d > TOL:
			over += 1

	print("")
	print("=== %s — carosabil vs. MESH-ul de teren (raycast) ===" % track.track_name)
	print("  puncte cu teren dedesubt   %d / %d" % [tested, n])
	print("  puncte cu teren PESTE      %d" % over)
	print("  cea mai mare depasire      %+.2f m la frac %.3f" % [worst, worst_f])
	print("")
	var ok := over == 0
	print("VERDICT: %s" % ("OK" if ok else "PROBLEMA (mesh de teren peste asfalt)"))
	get_tree().quit(0 if ok else 1)
