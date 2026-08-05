extends Node
## Sonda de CADRU: cate triunghiuri si cate draw call-uri ajung efectiv la GPU
## dintr-o pozitie de joc, nu cate exista pe pista.
##
##   godot --path . res://tools/ProbeFrame.tscn -- --track=3
##
## Ruleaza CU FEREASTRA: RenderingServer nu contorizeaza nimic in --headless.
## Camera e cea reala (constantele lui ChaseCamera), inclusiv far-ul ei.

const SAMPLES: int = 20

func _ready() -> void:
	var track_index := 0
	var no_shadows := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg == "--no-shadows":
			no_shadows = true
	track_index = clampi(track_index, 0, GameState.TRACK_SCENES.size() - 1)
	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	if no_shadows:
		track.theme_shadows = false
		track.rebuild()
	await get_tree().process_frame
	await get_tree().process_frame

	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = ChaseCamera.FAR_PLANE
	cam.current = true

	var n := track.baked.size()
	var rows: Array[Dictionary] = []
	for s in SAMPLES:
		var frac := float(s) / float(SAMPLES)
		var idx := int(frac * float(n)) % n
		var focus: Vector3 = track.baked[idx]
		var ahead: Vector3 = track.baked[(idx + 12) % n]
		var dir := (ahead - focus).normalized()
		cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE \
			+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD
			+ Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
		# Doua cadre ca sa se aseze culling-ul, apoi citim al treilea.
		for k in 3:
			await RenderingServer.frame_post_draw
		rows.append({
			"frac": frac,
			"prim": RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			"draw": RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		})

	print("")
	print("=== CADRU: %s (camera de joc, far %.0f m, umbre %s) ==="
		% [track.track_name, ChaseCamera.FAR_PLANE,
			"NU" if no_shadows else "da"])
	print("  frac   triunghiuri/cadru   draw calls")
	var max_p := 0
	var sum_p := 0
	var max_d := 0
	for r in rows:
		print("  %.2f   %14d   %10d" % [r["frac"], r["prim"], r["draw"]])
		max_p = maxi(max_p, int(r["prim"]))
		max_d = maxi(max_d, int(r["draw"]))
		sum_p += int(r["prim"])
	print("  --- varf %d triunghiuri/cadru, medie %d, varf %d draw calls"
		% [max_p, sum_p / rows.size(), max_d])
	get_tree().quit()
