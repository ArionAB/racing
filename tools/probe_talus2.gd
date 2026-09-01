extends Node
## Cat de sus urca grohotisul fata de podea, si cat de sus e MUCHIA pe care
## trebuie s-o ingroape (poala)? Daca blocul e mai jos decat muchia, linia
## ramane vizibila oricat de dese ar fi blocurile.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var dm := track.get_node("DecorManual")
	for grp in dm.get_children():
		var stats := {}
		for ch in grp.get_children():
			var nm := String(ch.name)
			var kind := ""
			for k in ["grohotis", "poala", "perete"]:
				if nm.begins_with(k):
					kind = k
			if kind == "":
				continue
			var ms: Array[Node] = []
			_collect(ch, ms)
			for mnode in ms:
				var mi := mnode as MeshInstance3D
				if not mi.is_visible_in_tree():
					continue
				var ab := mi.global_transform * mi.get_aabb()
				if not stats.has(kind):
					stats[kind] = [1e9, -1e9, 0.0, 0]
				var e: Array = stats[kind]
				e[0] = minf(e[0], ab.position.y)
				e[1] = maxf(e[1], ab.end.y)
				e[2] += ab.end.y - ab.position.y
				e[3] += 1
		var line := "  %-10s" % grp.name
		for k in ["poala", "grohotis", "perete"]:
			if stats.has(k):
				var e: Array = stats[k]
				line += "  %s y %.2f..%.2f (h_med %.2f, n=%d)" % [
					k, e[0], e[1], e[2] / float(e[3]), e[3]]
		print(line)
	get_tree().quit()

func _collect(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
