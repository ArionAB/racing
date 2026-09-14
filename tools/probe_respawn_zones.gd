extends Node
## Inventarul plaselor de repunere (RespawnZone) ale unei piste: nume, cutie
## (pozitie + marime in lume) si plafon. Pentru cand ProbeRace raporteaza
## repuneri pe sosea, cu masina la cota drumului — adica o plasa care
## prinde pe cineva care conduce normal.
##   godot --headless --path . res://tools/ProbeRespawnZones.tscn -- --track=8

func _ready() -> void:
	await get_tree().process_frame
	var idx := 8
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	print("")
	print("=== %s: plase de repunere ===" % track.track_name)
	for node in track.find_children("*", "RespawnZone", true, false):
		var zone := node as Node3D
		for c in zone.get_children():
			var cs := c as CollisionShape3D
			if cs == null or not (cs.shape is BoxShape3D):
				continue
			var size: Vector3 = (cs.shape as BoxShape3D).size
			var center: Vector3 = cs.global_position
			print("  %-24s parinte %-20s centru (%.1f, %.1f, %.1f) marime (%.0f x %.1f x %.0f) -> x [%.0f, %.0f] y [%.1f, %.1f] z [%.0f, %.0f]"
				% [zone.name, zone.get_parent().name, center.x, center.y, center.z,
					size.x, size.y, size.z, center.x - size.x * 0.5, center.x + size.x * 0.5,
					center.y - size.y * 0.5, center.y + size.y * 0.5,
					center.z - size.z * 0.5, center.z + size.z * 0.5])
	track.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
