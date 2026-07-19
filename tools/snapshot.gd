extends Node
## Unealta de overview: randeaza o pista de sus (ortografic) si salveaza
## PNG in snapshots/. Ruleaza cu fereastra (randarea nu merge headless):
##   godot --path . res://tools/Snapshot.tscn -- --track=0
## Fereastra apare ~o secunda si se inchide singura.

func _ready() -> void:
	var track_index := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
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
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	# `size` e extinderea VERTICALA; orizontala = size * aspect.
	cam.size = maxf(extent_z, extent_x / aspect)
	cam.position = center + Vector3.UP * 250.0
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
