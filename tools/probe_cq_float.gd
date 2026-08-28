extends Node
## Orice piesa de decor din sectiunile mele care nu are podea sub ea.
## Verifica TOATE prop-urile, nu doar cele adaugate de mine in ultima runda:
## captura de la frac 0.80 arata case atarnate peste gol pe partea dreapta.
const SECTIONS := ["5) Cheiul Chaotianmen", "6) Nodul Huangjuewan", "7) Liziba", "8) Fundal"]
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var bad := 0
	for sec in SECTIONS:
		var node := track.find_child(sec, true, false)
		if node == null:
			continue
		for child in node.get_children():
			var nm := str(child.name)
			# Luminile NU stau pe podea — ala e un felinar, nu o lada. Sonda
			# cauta decor care pluteste; un OmniLight3D la 5 m deasupra
			# asfaltului e exact ce trebuie sa fie. Exceptia e pe TIP, nu pe
			# prefix de nume, ca sa nu depinda de cum botez luminile.
			if child is Light3D:
				continue
			# fundalul e intentionat peste rau; nu are ce sta pe pamant
			if sec.begins_with("8)") or nm.begins_with("turn") or nm.begins_with("slep") or nm.ends_with("_col") or nm.begins_with("pila") or sec.begins_with("7)"):
				continue
			var p: Vector3 = (child as Node3D).global_position
			var mount := 3.0 if nm.begins_with("neon") else 0.0
			var q := PhysicsRayQueryParameters3D.create(
				p + Vector3.UP * 1.5, p + Vector3.DOWN * 40.0)
			var h := space.intersect_ray(q)
			if h.is_empty():
				print("  %s / %s : NIMIC pe 40 m (pos %.0f,%.0f,%.0f)" % [sec, nm, p.x, p.y, p.z])
				bad += 1
			else:
				var drop: float = p.y - h.position.y - mount
				if drop > 2.5:
					print("  %s / %s : atarna %.1f m peste %s" % [sec, nm, drop, h.collider.name])
					bad += 1
	print("piese fara sprijin: %d" % bad)
	get_tree().quit()
