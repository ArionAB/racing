extends Node
## Latimea reala a benzii pe zona POI D, si lateralul lui Bloc_115.
## Garda din generator foloseste `width_at(f)`; daca banda e mai lata acolo
## decat cei 6 m presupusi in ProbeClearD, o piesa „curata" la 9 m poate fi
## totusi pe carosabil.
func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var f := 0.428
	while f < 0.535:
		print("frac %.3f  half_width %.2f" % [f, track.width_at(f)])
		f += 0.012
	var groh := track.get_node_or_null("DecorManual/D) Canionul rosu/Grohotis")
	var n := track.route_at(0).baked.size()
	for nm in ["Bloc_115", "Bloc_130", "Bloc_164", "Bloc_171"]:
		var b := groh.get_node_or_null(nm) as Node3D
		if b == null:
			continue
		var worst := 1e9
		for mi in b.find_children("*", "MeshInstance3D", true, false):
			var mm := (mi as MeshInstance3D).mesh
			if mm == null: continue
			var xf := (mi as MeshInstance3D).global_transform
			var ab := mm.get_aabb()
			for i in 8:
				var wp: Vector3 = xf * ab.get_endpoint(i)
				var ci: int = track.closest_index_global(wp)
				for w in range(-40, 41, 4):
					var iw: int = ((ci + w) % n + n) % n
					worst = minf(worst, absf(track.lateral_distance(iw, wp)))
		print("%s lateral MIN %.2f  poz=%s" % [nm, worst, str(b.global_transform.origin)])
	get_tree().quit(0)
