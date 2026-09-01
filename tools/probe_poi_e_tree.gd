extends Node
## Cine EXISTA de fapt sub DecorManual dupa rebuild. Sonda de buget a raportat
## doar vine_row din sapte clase asezate — deci ori nodurile nu se instantiaza,
## ori le sterge ceva. Numar noduri, nu ma incred in tabel.


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var dm := track.get_node_or_null("DecorManual")
	print("")
	print("=== DecorManual dupa rebuild ===")
	if dm == null:
		print("LIPSESTE cu totul")
		get_tree().quit()
		return
	for zone in dm.get_children():
		print("zona %s: %d copii" % [zone.name, zone.get_child_count()])
		var kinds := {}
		for c in zone.get_children():
			var vis := 0
			for m in _meshes(c):
				if (m as MeshInstance3D).is_visible_in_tree():
					vis += 1
			var key := String(c.name).rstrip("0123456789")
			if not kinds.has(key):
				kinds[key] = [0, 0]
			kinds[key][0] += 1
			kinds[key][1] += vis
		for k in kinds:
			print("   %-18s x%d, mesh-uri vizibile: %d" % [k, kinds[k][0], kinds[k][1]])
	print("")
	get_tree().quit()


func _meshes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		out.append(root)
	for c in root.get_children():
		out.append_array(_meshes(c))
	return out
