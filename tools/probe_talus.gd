extends Node
## Ajung blocurile de grohotis in scena RANDATA, sau doar in .tscn?
##
## Sonda de numarat nu e suficienta (lectia „efectele nu se verifica numarand"):
## intreb daca nodul EXISTA, daca e vizibil in arbore, ce AABB are in lume si
## cati metri sunt de la el pana la axa benzii.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var dm := track.get_node_or_null("DecorManual")
	print("DecorManual: ", dm)
	if dm == null:
		get_tree().quit(); return
	for grp in dm.get_children():
		var tot := 0
		var vis := 0
		var meshes := 0
		var ymin := 1e9
		var ymax := -1e9
		for ch in grp.get_children():
			if not String(ch.name).begins_with("grohotis"):
				continue
			tot += 1
			if (ch as Node3D).is_visible_in_tree():
				vis += 1
			var ms: Array[Node] = []
			_collect(ch, ms)
			meshes += ms.size()
			for mnode in ms:
				var mi := mnode as MeshInstance3D
				if mi.is_visible_in_tree():
					var ab := mi.global_transform * mi.get_aabb()
					ymin = minf(ymin, ab.position.y)
					ymax = maxf(ymax, ab.end.y)
		print("  %-10s grohotis noduri=%3d vizibile=%3d mesh-uri=%3d  y_lume %.2f..%.2f"
			% [grp.name, tot, vis, meshes, ymin, ymax])
	get_tree().quit()

func _collect(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
