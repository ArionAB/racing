extends Node
## Yaw-ul macaralei se deriva din tangenta REALA a rutei in punctul ei
## (r.baked), nu din curba de control reconstruita: la frac 0.805 cele doua
## difera cu ~55 grade, si de aceea turnul cadea in lungul drumului in loc de
## lateral. Se verifica cu dot (memoria `rotatii-in-builder-semnul`).
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
	for f: float in [0.795, 0.805, 0.815]:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 3) % n] - r.baked[(i - 3 + n) % n]).normalized()
		var flat := Vector3(fw.x, 0.0, fw.z).normalized()
		var yaw := atan2(flat.x, flat.z)
		var b := Basis(Vector3.UP, yaw)
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 6.0, c + Vector3.DOWN * 10.0)
		var h := space.intersect_ray(q)
		var road_y: float = h.position.y if not h.is_empty() else c.y
		print("frac %.3f: +Z dot tangenta %+.4f | +X dot normala %+.4f | asfalt %.2f" % [
			f, b.z.dot(flat), b.x.dot(side), road_y])
		print("   Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)" % [
			b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, c.x, road_y, c.z])
	get_tree().quit()
