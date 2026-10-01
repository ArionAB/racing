extends Node
## Amprenta terenului unei piste, ca sa se dovedeasca NEUTRALITATEA unei
## schimbari in codul comun (track.gd / track_side_sampler.gd): acelasi hash
## inainte si dupa = schimbarea nu atinge pista (memoria
## `fiordland-poi-gauntlet-sesiune`, lectia 2).
##
##   godot --headless --path . res://tools/SvGroundHash.tscn -- --scenes=09,11,16
##
## Hash-uri: campul `ground_y` pe o grila de 4 m peste toata panza, grila de
## teren randata (`_terr_heights`), si lista de noduri construite (nume + tip).

func _ready() -> void:
	var scenes := ["09", "11", "16"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenes="):
			scenes = Array(arg.trim_prefix("--scenes=").split(","))
	for s in scenes:
		var ps := load("res://scenes/tracks/Track%s.tscn" % s) as PackedScene
		var tr := ps.instantiate() as Track
		add_child(tr)
		for k in 3:
			await get_tree().process_frame
		var sampler: TrackSideSampler = tr.get("_sampler")
		var origin: Vector3 = tr.get("_terr_origin")
		var cells: int = tr.get("_terr_cells")
		var step: float = tr.get("_terr_step")
		var size := float(cells) * step
		var field := PackedFloat32Array()
		var x := 0.0
		while x <= size:
			var z := 0.0
			while z <= size:
				field.append(sampler.ground_y(origin.x + x, origin.z + z))
				z += 4.0
			x += 4.0
		var heights: PackedFloat32Array = tr.get("_terr_heights")
		var names := PackedStringArray()
		for c in tr.get_children():
			names.append("%s:%s" % [c.name, c.get_class()])
		print("Track%s  ground_y[%d] %s  terr_heights[%d] %s  noduri[%d] %s  water_at(0,0,0)=%s" % [
			s, field.size(), field.to_byte_array().hex_encode().sha256_text().left(16),
			heights.size(), heights.to_byte_array().hex_encode().sha256_text().left(16),
			names.size(), "|".join(names).sha256_text().left(16),
			str(tr.water_level_at(Vector3.ZERO))])
		tr.queue_free()
		await get_tree().process_frame
	get_tree().quit(0)
