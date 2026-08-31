extends Node
## Unde se pun usile/ferestrele ca sa fie CHEIE DE SCARA: pe fata falezei, la
## cotele pe care camera le vede la 0.26-0.30, si cu gabaritul assetului
## masurat, nu presupus.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	print("=== GABARITELE ASSETURILOR DE SCARA ===")
	for path in ["res://assets/models/cappadocia/structures/cave_entrance.glb",
			"res://assets/models/cappadocia/rocks/rock_church_facade.glb",
			"res://assets/models/cappadocia/buildings/cave_house_a.glb",
			"res://assets/models/cappadocia/buildings/cave_house_b.glb",
			"res://assets/models/cappadocia/buildings/dovecote.glb"]:
		var ps := load(path) as PackedScene
		if ps == null:
			print("  %s: LIPSA" % path)
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		await get_tree().process_frame
		var aabb := AABB()
		var first := true
		for m in _meshes(inst):
			var a: AABB = (m as MeshInstance3D).get_aabb()
			a = (m as MeshInstance3D).global_transform * a
			if first:
				aabb = a
				first = false
			else:
				aabb = aabb.merge(a)
		print("  %s: %.2f x %.2f x %.2f m (jos la y=%.2f)"
			% [path.get_file(), aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y])
		inst.queue_free()
	print("")
	print("=== FATA FALEZEI: unde e peretele, pe fracii vizibili ===")
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.255, 0.27, 0.285, 0.30, 0.315]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var sd: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		# buza e la half_width + 0.2; fata coboara cu evazare
		print("frac %.3f: drum (%.1f, %.1f, %.1f)  side (%.3f, %.3f)"
			% [f, p.x, p.y, p.z, sd.x, sd.z])
		for d in [7.0, 10.0, 14.0]:
			var q: Vector3 = p + sd * d
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 60.0, q.z), Vector3(q.x, p.y - 200.0, q.z))
			var h := space.intersect_ray(ray)
			var gy := -999.0
			if h: gy = float(h["position"].y)
			print("    la %4.1f m lateral: teren y=%.1f (dif %.1f), punct (%.1f, %.1f)"
				% [d, gy, gy - p.y, q.x, q.z])
	get_tree().quit(0)

func _meshes(nd: Node) -> Array:
	var out: Array = []
	if nd is MeshInstance3D:
		out.append(nd)
	for c in nd.get_children():
		out.append_array(_meshes(c))
	return out
