extends Node3D
## Hornurile din infill PLUTESC? Pe captura la 0.64 se vad goluri sub cateva
## piese. Compar cota bazei fiecarei piese cu terenul EXACT sub ea.


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := get_world_3d().direct_space_state
	var bad := 0
	var tot := 0
	print("")
	print("=== piese Fill: baza fata de teren ===")
	for node in _all(track):
		var n3 := node as Node3D
		if n3 == null or not String(n3.name).begins_with("Fill") or String(n3.name).ends_with("_col"):
			continue
		tot += 1
		var p := n3.global_position
		# De la +2 m, NU de sus: world_prop da fiecarui prop un corp fizic, iar
		# o raza pornita de la +200 m loveste HULL-UL PIESEI si raporteaza
		# varful hornului drept "teren". Prima versiune a sondei a raportat
		# asa 47 de piese "ingropate 13-24 m" care de fapt stateau corect —
		# masurat pe Fill003: de la +240 m "teren"=44.27 (propriul colider),
		# de la +5 m teren=24.74 fata de baza 24.59, adica exact offsetul cerut.
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, p.y + 2.0, p.z), Vector3(p.x, p.y - 200.0, p.z))
		q.exclude = _bodies_of(n3)
		var hit := space.intersect_ray(q)
		if not hit.has("position"):
			print("  %-8s FARA TEREN sub ea" % n3.name)
			bad += 1
			continue
		var gy: float = (hit["position"] as Vector3).y
		var dy := p.y - gy
		if absf(dy) > 0.6:
			bad += 1
			print("  %-8s baza %.2f, teren %.2f, decalaj %+.2f m" % [n3.name, p.y, gy, dy])
	print("  total %d, gresite %d" % [tot, bad])
	get_tree().quit()


## RID-urile corpurilor proprii ale piesei (si ale fratelui `<nume>_col`), ca
## raza sa nu se opreasca in ea insasi.
func _bodies_of(n3: Node3D) -> Array[RID]:
	var out: Array[RID] = []
	var parent := n3.get_parent()
	if parent != null:
		var col := parent.get_node_or_null("%s_col" % n3.name)
		if col is CollisionObject3D:
			out.append((col as CollisionObject3D).get_rid())
	for c in _all(n3):
		if c is CollisionObject3D:
			out.append((c as CollisionObject3D).get_rid())
	return out


func _all(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var st: Array[Node] = [root]
	while not st.is_empty():
		var c: Node = st.pop_back()
		out.append(c)
		for k in c.get_children():
			st.push_back(k)
	return out
