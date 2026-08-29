extends Node
## Sunt blocurile in cadrul camerei de joc? Si ce se vede de fapt lateral?
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	var zone := track.find_child("1) Piata Kuixinglou", true, false)
	print("zona=", zone)
	for ch in zone.get_children():
		var nm := str(ch.name)
		if not nm.begins_with("bloc_sub_piata"): continue
		var n3 := ch as Node3D
		var aabb := _world_aabb(n3)
		print("%s: pos=%v  aabb pos=%v size=%v  top=%.1f" % [nm, n3.global_position, aabb.position, aabb.size, aabb.position.y + aabb.size.y])
		# lateral fata de axa
		var off := c.get_closest_offset(n3.global_position)
		var p := c.sample_baked(off)
		var p2 := c.sample_baked(minf(off + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var v: Vector3 = n3.global_position - p
		print("    frac=%.4f lateral(right)=%.2f  fata_de_sosea_y=%.1f" % [off / L, v.dot(right), p.y])
	# ce se vede la 90 grade dreapta din masina, la fractiile cerute
	get_tree().quit()

func _world_aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for ch in cur.get_children(): stack.append(ch)
		var mi := cur as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var a := mi.global_transform * mi.mesh.get_aabb()
		if first: out = a; first = false
		else: out = out.merge(a)
	return out
