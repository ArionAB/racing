extends Node
## Randeaza o pista si salveaza PNG in snapshots/. Ruleaza CU FEREASTRA
## (randarea nu merge headless); fereastra apare ~o secunda si se inchide singura.
##
##   --track=0                 ansamblu, de sus (ortografic)
##   --track=0 --frac=0.2      prim-plan inclinat la o fractie din traseu
##   --track=0 --frac=0.2 --driver
##                             VEDEREA SOFERULUI: perspectiva, la inaltimea
##                             camerei de urmarire
##
## Pentru decizii de COMPOZITIE foloseste --driver. Vederile ortografice de sus
## turtesc tot ce e vertical, deci mint despre densitatea decorului de pe
## margine: ceva ce arata presarat de sus poate strange cadrul perfect din
## masina, si invers.

func _ready() -> void:
	var track_index := 0
	var zoom_frac := -1.0 # >= 0: prim-plan la fractia respectiva din traseu
	var zoom_size := 60.0
	var driver_view := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--frac="):
			zoom_frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--size="):
			zoom_size = float(arg.trim_prefix("--size="))
		elif arg == "--driver":
			driver_view = true
	if driver_view and zoom_frac < 0.0:
		zoom_frac = 0.0
	track_index = clampi(track_index, 0, GameState.TRACK_SCENES.size() - 1)

	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	# Fara ceata: camera e sus si ceata ar spala imaginea.
	for child in track.get_children():
		if child is WorldEnvironment:
			(child as WorldEnvironment).environment.fog_enabled = false

	# Incadram pista (nu terenul urias): bounds din punctele coapte.
	var bmin := track.baked[0]
	var bmax := track.baked[0]
	for p in track.baked:
		bmin = bmin.min(p)
		bmax = bmax.max(p)
	var center := (bmin + bmax) * 0.5
	var extent_x := bmax.x - bmin.x + 90.0
	var extent_z := bmax.z - bmin.z + 90.0
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y
	var cam := Camera3D.new()
	add_child(cam)
	if driver_view:
		# Vederea SOFERULUI: perspectiva, la inaltimea camerei de urmarire.
		# Singura care raspunde la "cum arata cand joci" — vederile ortografice
		# de sus mint despre densitatea decorului de pe margine, pentru ca
		# turtesc tot ce e vertical.
		var n := track.baked.size()
		var idx := int(zoom_frac * float(n)) % n
		var focus: Vector3 = track.baked[idx]
		var ahead: Vector3 = track.baked[(idx + 12) % n]
		var dir := (ahead - focus).normalized()
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = 68.0 # acelasi cu ChaseCamera.base_fov
		cam.far = 400.0
		cam.position = focus - dir * 7.5 + Vector3.UP * 3.2
		cam.look_at(focus + dir * 14.0 + Vector3.UP * 1.2, Vector3.UP)
		cam.current = true
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var dimg := get_viewport().get_texture().get_image()
		var ddir := ProjectSettings.globalize_path("res://snapshots")
		DirAccess.make_dir_recursive_absolute(ddir)
		var dout := "%s/%s_sofer.png" % [ddir,
			GameState.TRACK_NAMES[track_index].to_lower()]
		dimg.save_png(dout)
		print("SNAPSHOT: ", dout)
		get_tree().quit()
		return
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	if zoom_frac >= 0.0:
		# Prim-plan inclinat la un punct de pe traseu (vezi si inaltimile).
		var idx := int(zoom_frac * float(track.baked.size())) % track.baked.size()
		var focus: Vector3 = track.baked[idx]
		cam.size = zoom_size
		cam.position = focus + Vector3(0, zoom_size * 0.9, zoom_size * 0.6)
		cam.look_at(focus, Vector3.UP)
	else:
		# `size` e extinderea VERTICALA; orizontala = size * aspect.
		# Cu --size fortezi cadrul (ex. 950 ca sa vezi si zidul lumii).
		cam.size = zoom_size if zoom_size > 100.0 else maxf(extent_z, extent_x / aspect)
		cam.position = center + Vector3.UP * 400.0
		cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.far = 1000.0
	cam.current = true

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/%s.png" % [dir, GameState.TRACK_NAMES[track_index].to_lower()]
	img.save_png(out)
	print("SNAPSHOT: ", out)
	get_tree().quit()
