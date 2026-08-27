extends Node
## Care dintre piesele noi de pe rampa de sus au PAMANT sub ele? Cele care
## plutesc (drumul e pe viaduct, malul lipseste pe partea deschisa) trebuie
## scoase sau coborate. Raportam numele si cat de mult atarna in gol.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var dm := track.find_child("6) Nodul Huangjuewan", true, false)
	var floating: Array[String] = []
	var ok := 0
	for child in dm.get_children():
		var nm := str(child.name)
		if not nm.begins_with("casaFmal") and not nm.begins_with("neonF") and not nm.begins_with("felinarF"):
			continue
		var p: Vector3 = (child as Node3D).global_position
		# ignoram propriile corpuri: tragem raza de sub piesa in jos
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 8.0)
		var h := space.intersect_ray(q)
		if h.is_empty():
			floating.append("%s (nimic sub ea 60 m)" % nm)
		else:
			var mount: float = 3.0 if nm.begins_with("neonF") else 0.0
			var drop: float = p.y - h.position.y - mount
			if drop > 2.5:
				floating.append("%s atarna %.1f m peste %s" % [nm, drop, h.collider.name])
			else:
				ok += 1
	print("piese cu sprijin: %d" % ok)
	print("piese care plutesc: %d" % floating.size())
	for f in floating:
		print("   %s" % f)
	get_tree().quit()
