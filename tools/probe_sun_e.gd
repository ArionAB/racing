extends Node
## Azimutul soarelui fata de directia drumului, pe intervalul POI E.
## godot --headless --fixed-fps 60 --path . res://tools/ProbeSunE.tscn -- --track=7

func _ready() -> void:
	await get_tree().process_frame
	var only := 7
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sun: DirectionalLight3D = null
	for c in track.get_children():
		if c is DirectionalLight3D:
			sun = c
			break
	if sun == null:
		for c in track.find_children("*", "DirectionalLight3D", true, false):
			sun = c
			break
	var sun_dir := Vector3(0, -1, 0)
	if sun != null:
		sun_dir = -sun.global_transform.basis.z
		print("sun rot_deg=", sun.rotation_degrees, " energy=", sun.light_energy, " shadow=", sun.shadow_enabled)
	print("sun_dir(lumina bate spre)=", sun_dir)

	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	for f in [0.362, 0.39, 0.408, 0.431, 0.454, 0.482]:
		var i := int(f * float(n)) % n
		var j := (i + maxi(1, int(0.004 * float(n)))) % n
		var p: Vector3 = r.baked[i]
		var q: Vector3 = r.baked[j]
		var fwd := q - p
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var sd := Vector3(sun_dir.x, 0.0, sun_dir.z).normalized()
		# unghiul in care CADE umbra, relativ la directia de mers (0 = in fata, +90 = dreapta)
		var umbra := rad_to_deg(atan2(sd.dot(right), sd.dot(fwd)))
		var soare_din := rad_to_deg(atan2(-sd.dot(right), -sd.dot(fwd)))
		print("frac=%.3f pos=(%.1f,%.1f,%.1f) umbra_cade_la=%.0f deg  soarele_vine_din=%.0f deg" % [f, p.x, p.y, p.z, umbra, soare_din])
	get_tree().quit(0)
