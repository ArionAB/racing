extends Node
## Adevarul despre gabarit: amprenta ROTITA reala (4 colturi in planul XZ ai
## cutiei locale, transformati cu basis-ul piesei), nu AABB-ul aliniat pe axele
## lumii. La yaw ~37 grade un AABB de lume umfla o cutie 14.5x11.5 pana la ~21 m
## si raporteaza colturi care nu apartin cladirii.
## Compar ambele metode ca sa se vada diferenta.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	var root := track.get_node("DecorManual/1) Piata Kuixinglou")
	var worst := 1e9
	var worst_n := ""
	for ch in root.get_children():
		if not str(ch.name).begins_with("turn_piata"): continue
		var n := ch as Node3D
		var mi: MeshInstance3D = _f(n)
		if mi == null: continue
		var lab := mi.mesh.get_aabb()
		# cea mai apropiata fractie
		var bf := 0.0
		var bd := 1e9
		for k in 1200:
			var ss: float = float(k) / 1200.0 * 0.06 * L
			var dd := c.sample_baked(ss).distance_to(n.global_position)
			if dd < bd:
				bd = dd
				bf = ss
		var p := c.sample_baked(bf)
		var p2 := c.sample_baked(fmod(bf + 3.0, L))
		var right := (p2 - p).normalized().cross(Vector3.UP).normalized()
		# 4 colturi ROTITE ale bazei, in spatiul lumii
		var xf := mi.global_transform
		var rot_min := 1e9
		var aabb_min := 1e9
		for ix in 2:
			for iz in 2:
				var loc := Vector3(lab.position.x + lab.size.x * float(ix), 0.0,
					lab.position.z + lab.size.z * float(iz))
				rot_min = minf(rot_min, ((xf * loc) - p).dot(right))
		var wab: AABB = xf * lab
		for ix in 2:
			for iz in 2:
				var cor := Vector3(wab.position.x + wab.size.x * float(ix), 0.0,
					wab.position.z + wab.size.z * float(iz))
				aabb_min = minf(aabb_min, (cor - p).dot(right))
		if rot_min < worst:
			worst = rot_min
			worst_n = str(n.name)
		print("%s  amprenta_rotita=%.1f m   aabb_lume=%.1f m   (diferenta %.1f)"
			% [n.name, rot_min, aabb_min, rot_min - aabb_min])
	print("CEL MAI APROPIAT (amprenta reala): %s la %.1f m; half_width=5.0" % [worst_n, worst])
	print("VERDICT: %s" % ("OK, toate turnurile in afara carosabilului" if worst >= 6.0
		else "RESPINS, o piesa intra in carosabil"))
	get_tree().quit()
func _f(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for ch in n.get_children():
		var r := _f(ch)
		if r: return r
	return null
