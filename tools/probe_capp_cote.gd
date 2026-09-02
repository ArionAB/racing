extends Node
## Distributia COTELOR bazei pentru tot kitul de tuf de pe Track13.
## Raspunde la: poate o banda de strat sa stea pe o cota FIXA de lume, sau
## trebuie legata de baza fiecarei piese?
func _ready() -> void:
	await get_tree().process_frame
	var ps := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var t := ps.instantiate()
	get_tree().root.add_child(t)
	for i in 5:
		await get_tree().process_frame
	var dm: Node = t.get_node_or_null("DecorManual")
	var per_grup := {}
	var toate := PackedFloat32Array()
	_walk(dm, per_grup, toate)
	var s := Array(toate)
	s.sort()
	print("=== baze de tuf: %d piese ===" % s.size())
	if s.size() > 0:
		for q in [0, 5, 25, 50, 75, 95, 100]:
			var i: int = clampi(int(float(q) / 100.0 * float(s.size() - 1)), 0, s.size() - 1)
			print("   p%-3d  Y = %.2f" % [q, s[i]])
	var keys: Array = per_grup.keys()
	keys.sort()
	for g in keys:
		var arr: Array = per_grup[g]
		arr.sort()
		print("%-28s n=%3d  Y %.1f .. %.1f  (median %.1f)" % [
			g, arr.size(), arr[0], arr[-1], arr[arr.size() / 2]])
	get_tree().quit()


func _walk(node: Node, per_grup: Dictionary, toate: PackedFloat32Array) -> void:
	const TUF := ["chimney_a", "chimney_b", "chimney_c", "chimney_d",
		"chimney_mushroom", "chimney_triple", "twin_chimney_gate",
		"cracked_chimney_a", "cracked_chimney_b", "cracked_chimney_c",
		"cave_house_a", "cave_house_b", "cave_house_c", "dovecote",
		"rock_church_facade"]
	for c in node.get_children():
		var sp := c as Node3D
		if sp == null:
			continue
		if sp.scene_file_path.is_empty():
			_walk(sp, per_grup, toate)
			continue
		if not TUF.has(sp.scene_file_path.get_file().get_basename()):
			continue
		var y := sp.global_position.y
		toate.append(y)
		var g := String(sp.get_parent().name)
		if not per_grup.has(g):
			per_grup[g] = []
		per_grup[g].append(y)
