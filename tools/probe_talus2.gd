extends Node
## Unde ajung blocurile de grohotis fata de FATA peretelui: in fata ei (se vad)
## sau in spatele ei (ingropate in deal, invizibile)?
##
## Pe captura, poala a disparut de la piciorul peretelui exact cand a fost
## marita. Suspiciunea: garda de carosabil impinge blocul DINSPRE sosea, iar
## peretele e tot dinspre sosea, deci garda le impinge IN deal.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var base := track.get_node_or_null("DecorManual/D) Canionul rosu")
	var groh := base.get_node_or_null("Grohotis")
	var faleza := base.get_node_or_null("Faleza")
	var wall: PackedVector3Array = PackedVector3Array()
	for mi in faleza.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				wall.append(xf * v)
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var inside := 0
	var outside := 0
	for b in groh.get_children():
		var n3 := b as Node3D
		if n3 == null: continue
		var p := n3.global_transform.origin
		var ci: int = track.closest_index_global(p)
		var lat_b: float = absf(track.lateral_distance(ci, p))
		# fata peretelui la cota blocului, in vecinatatea lui
		var wall_lat := 1e9
		for wv in wall:
			if absf(wv.y - p.y) > 4.0:
				continue
			var dx: float = wv.x - p.x
			var dz: float = wv.z - p.z
			if dx * dx + dz * dz > 400.0:
				continue
			var cw: int = track.closest_index_global(wv)
			wall_lat = minf(wall_lat, absf(track.lateral_distance(cw, wv)))
		if wall_lat > 1e8:
			continue
		if lat_b > wall_lat + 0.5:
			inside += 1
		else:
			outside += 1
	print("blocuri: IN SPATELE fetei (ingropate)=%d  IN FATA (se vad)=%d"
		% [inside, outside])
	get_tree().quit(0)
