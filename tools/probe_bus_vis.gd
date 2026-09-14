extends Node
## Diagnostic: e autobuzul de pe Track15 construit si vizibil?
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[8]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	for _i in 5:
		await get_tree().physics_frame
	for node in track.find_children("*", "BusHazard", true, false):
		var bus := node as BusHazard
		var body: Node3D = bus.body()
		print("bus %s: body=%s visible=%s in_tree_visible=%s pos=%s hidden=%s dist=%.1f layer=%d" % [bus.name, str(body),
			str(body.visible), str(body.is_visible_in_tree()), str(body.global_position), str(bus.is_hidden()),
			bus.distance(), body.collision_layer])
		for c in body.find_children("*", "", true, false):
			var mi := c as MeshInstance3D
			var cs := c as CollisionShape3D
			if mi != null:
				print("   mesh %s visible=%s aabb=%s" % [mi.name, str(mi.is_visible_in_tree()), str(mi.get_aabb())])
			elif cs != null:
				print("   shape %s %s" % [cs.name, str((cs.shape as BoxShape3D).size if cs.shape is BoxShape3D else cs.shape)])
	track.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
