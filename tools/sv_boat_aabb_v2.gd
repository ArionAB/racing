extends SceneTree
## Sonda temporara: AABB instantiat al noilor cruise_boat.glb/kayak_a.glb/
## kayak_b.glb (dupa inlocuire, 26 sep 2026), ca sa verificam daca
## boat_half_len/boat_half_width/KAYAK_* din gen_decor_fiord_a.gd mai sunt
## corecte fata de geometria noua.

func _init() -> void:
	for path in [
		"res://assets/models/fiordland/vehicles/cruise_boat.glb",
		"res://assets/models/fiordland/props/kayak_a.glb",
		"res://assets/models/fiordland/props/kayak_b.glb",
	]:
		var glb: PackedScene = load(path)
		var inst := glb.instantiate()
		get_root().add_child(inst)
		await process_frame
		var aabb := _combined_aabb(inst)
		print("%s -> size %.3f X x %.3f Y x %.3f Z | half_len(Z)=%.3f half_w(X)=%.3f"
			% [path, aabb.size.x, aabb.size.y, aabb.size.z,
			   aabb.size.z * 0.5, aabb.size.x * 0.5])
		inst.queue_free()
	quit(0)


func _combined_aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for mi in _find_mesh_instances(node):
		var local_aabb: AABB = mi.get_aabb()
		var xform: Transform3D = mi.global_transform
		var world_aabb := xform * local_aabb
		if first:
			result = world_aabb
			first = false
		else:
			result = result.merge(world_aabb)
	return result


func _find_mesh_instances(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_find_mesh_instances(c))
	return out
