extends Node
## Cat de groasa e cu adevarat pila, in colizor? (raza ghicita a fost 1.4)
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var decor := track.find_child("DecorManual", true, false)
	for nm: String in ["pila135", "pila139", "pila141", "pila143"]:
		var node := decor.find_child(nm, true, false) as Node3D
		if node == null:
			continue
		var body := node.find_child("*_col", true, false)
		if body == null:
			for ch in node.get_children():
				if ch is StaticBody3D:
					body = ch
		var aabb := AABB()
		var first := true
		for ch in node.find_children("*", "MeshInstance3D", true, false):
			var mi := ch as MeshInstance3D
			var a: AABB = (mi.global_transform * mi.get_aabb()) if false else mi.global_transform * mi.get_aabb()
			if first:
				aabb = a
				first = false
			else:
				aabb = aabb.merge(a)
		print("%s: AABB size=(%.2f, %.2f, %.2f) centru=(%.2f,%.2f,%.2f) poz=(%.2f,%.2f,%.2f)" % [
			nm, aabb.size.x, aabb.size.y, aabb.size.z,
			aabb.get_center().x, aabb.get_center().y, aabb.get_center().z,
			node.global_position.x, node.global_position.y, node.global_position.z])
	get_tree().quit()
