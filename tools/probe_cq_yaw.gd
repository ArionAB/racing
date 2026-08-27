extends Node
## Transformul macaralei la frac 0.805: originea la COTA SOSELEI REALE
## (masurata cu raza, nu din curba - modulul rotativ ridica asfaltul cu 3 m
## in dreptul lui), si yaw derivat cu dot.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	for f: float in [0.800, 0.805, 0.810]:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 3) % n] - r.baked[(i - 3 + n) % n]).normalized()
		var flat := Vector3(fw.x, 0.0, fw.z).normalized()
		var yaw := atan2(flat.x, flat.z)
		var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 6.0, c + Vector3.DOWN * 10.0)
		var h := space.intersect_ray(q)
		var road_y: float = h.position.y if not h.is_empty() else c.y
		var b := Basis(Vector3.UP, yaw)
		print("frac %.3f  asfalt %.2f (curba %.2f) %s" % [f, road_y, c.y,
			str(h.collider.name) if not h.is_empty() else "(fara raza)"])
		print("   Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)" % [
			b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, c.x, road_y, c.z])
	get_tree().quit()
