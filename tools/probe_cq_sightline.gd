extends Node
## Ce vede efectiv soferul spre dreapta: trag raze din OCHIUL CAMEREI (10 m
## peste masina, 12.5 m in spate) spre puncte tot mai jos in rapa si raportez
## ce lovesc PRIMA data. Daca prima lovitura e terenul de la buza, atunci un
## val de pamant ascunde caderea si orice cladire pusa dincolo de el e inutila.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	for f in [0.005, 0.012, 0.020, 0.030]:
		var p := c.sample_baked(f * L)
		var p2 := c.sample_baked(fmod(f * L + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var eye: Vector3 = p - fwd * 12.5 + Vector3.UP * 10.0
		print("--- frac=%.3f ochi=(%.0f,%.0f,%.0f) sosea_y=%.1f" % [f, eye.x, eye.y, eye.z, p.y])
		# tinte: in rapa, la distante laterale crescande si cote coborate
		for d in [10, 15, 20, 30, 45]:
			var tgt: Vector3 = p + right * float(d) + Vector3.UP * (23.0 - p.y)
			var q := PhysicsRayQueryParameters3D.create(eye, tgt)
			q.collide_with_areas = false
			var h := space.intersect_ray(q)
			if h.is_empty():
				print("   spre %2dm in rapa: LIBER (se vede pana jos)" % d)
			else:
				var col: Node = h.collider
				var frac_hit: float = (h.position - eye).length() / maxf((tgt - eye).length(), 0.001)
				# cine e, de fapt: numele parintilor si distanta laterala a lovirii
				var chain := str(col.name)
				var par := col.get_parent()
				var depth := 0
				while par != null and depth < 3:
					chain = str(par.name) + "/" + chain
					par = par.get_parent()
					depth += 1
				print("   spre %2dm in rapa: lovit %s la y=%.1f lat=%.1f (%.0f%% din drum)" % [
					d, chain, h.position.y,
					(h.position - p).dot(right), frac_hit * 100.0])
	get_tree().quit()
