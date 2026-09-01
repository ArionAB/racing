extends Node
## Ajutor de RUNDA 29 (temporar): cota solului REAL sub o lista de puncte XZ,
## citita din stdin-ul liniei de comanda. Foloseste aceeasi regula ca
## `_sol_real` din gen_decor_capp_b.gd — raza doar in TerrainBody — ca sa poata
## fi asezate si piesele puse de mana, care nu trec prin generator.

func _ready() -> void:
	call_deferred("_go")

func _go() -> void:
	var pts: Array[Vector2] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pts="):
			for pair in a.trim_prefix("--pts=").split(";"):
				if pair.is_empty():
					continue
				var xy := pair.split(",")
				pts.append(Vector2(float(xy[0]), float(xy[1])))
	var t := (load(GameState.TRACK_SCENES[6]) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 12:
		await get_tree().process_frame
	var rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			rid = (c as StaticBody3D).get_rid()
	var hi := -INF
	for bp in t.baked:
		hi = maxf(hi, bp.y)
	var sus_y: float = hi + 120.0
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	for p in pts:
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, sus_y, p.y), Vector3(p.x, sus_y - 900.0, p.y))
		q.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if hit.is_empty() or hit["rid"] != rid:
			print("SOL %.2f %.2f NONE" % [p.x, p.y])
		else:
			print("SOL %.2f %.2f %.4f" % [p.x, p.y, float(hit["position"].y)])
	get_tree().quit(0)
