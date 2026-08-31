extends Node
## CE e solid in punctul in care se opresc masinile pe elice (frac ~0.80)?
## Plimba o cutie mica pe axa benzii intre 0.79 si 0.815, la mai multe inaltimi,
## si tipareste TOATE corpurile atinse, cu numele lor.


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 1.4, 4.2)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false
	print("frac    lat    h    corpuri")
	for i in n:
		var f := r.frac_at(i)
		if f < 0.788 or f > 0.818:
			continue
		var p: Vector3 = r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var half: float = track.width_at_index(i)
		for lat in [-half * 0.6, 0.0, half * 0.6]:
			for h in [0.8, 1.0, 1.6]:
				q.transform = Transform3D(Basis(side, Vector3.UP, -fwd),
					p + Vector3.UP * h + side * lat)
				var names: Array[String] = []
				for hit in space.intersect_shape(q, 12):
					var b := hit.get("collider") as Node
					if b != null:
						names.append(String(b.name))
				if not names.is_empty():
					print("%.4f  %+5.1f  %.1f   %s" % [f, lat, h,
						", ".join(names)])
	get_tree().quit(0)
