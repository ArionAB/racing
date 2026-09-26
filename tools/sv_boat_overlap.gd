extends SceneTree
## Sonda temporara: verifica overlap REAL intre corpurile fizice ale
## cruiseBoatDock4/5 si kayakDock6/7 (si wooden_pier), folosind
## PhysicsServer3D pe scena INCARCATA (nu OBB recalculat manual — fragil la
## curbura drumului, cum a demonstrat runda asta).

func _init() -> void:
	var track_scene: PackedScene = load("res://scenes/tracks/Track16.tscn")
	var track := track_scene.instantiate()
	get_root().add_child(track)
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var zone := track.get_node_or_null("DecorManual/ZoneA_Chei")
	var bodies := {}
	for child in zone.get_children():
		var nm := str(child.name)
		if nm.begins_with("cruiseBoatDock") or nm.begins_with("kayakDock") \
				or nm.begins_with("woodenPier"):
			if child is StaticBody3D:
				bodies[nm] = child

	print("corpuri gasite: ", bodies.keys())
	var space: PhysicsDirectSpaceState3D = track.get_world_3d().direct_space_state
	var names := bodies.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: StaticBody3D = bodies[names[i]]
			var b: StaticBody3D = bodies[names[j]]
			var overlap := _bodies_overlap(space, a, b)
			print("%s vs %s: %s" % [names[i], names[j], "OVERLAP" if overlap else "ok"])
	quit(0)


func _bodies_overlap(space: PhysicsDirectSpaceState3D, a: StaticBody3D, b: StaticBody3D) -> bool:
	# Foloseste shape-ul de coliziune al lui A ca query impotriva lumii,
	# filtrat sa raporteze doar rezultate de pe rid-ul lui B.
	var shape_node: CollisionShape3D = null
	for c in a.get_children():
		if c is CollisionShape3D:
			shape_node = c
			break
	if shape_node == null or shape_node.shape == null:
		return false
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape_node.shape
	params.transform = shape_node.global_transform
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var results: Array = space.intersect_shape(params, 8)
	for r: Dictionary in results:
		if r.get("collider") == b:
			return true
	return false
