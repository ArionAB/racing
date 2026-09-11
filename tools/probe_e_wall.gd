extends Node
## Geometria bolului craterului (POI E): centrul buclei, raza drumului pe
## intervalul E, si cota terenului pe o raza dinspre centru spre camera —
## ca sa stim unde se poate ridica malul opus fara sa fie sapat de rapa.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var space := track.get_world_3d().direct_space_state
	var cx := 0.0
	var cz := 0.0
	for i in n:
		cx += r.baked[i].x
		cz += r.baked[i].z
	cx /= float(n)
	cz /= float(n)
	print("CENTRU (%.1f, %.1f)" % [cx, cz])
	for f in [0.36, 0.40, 0.44, 0.48]:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var d := Vector2(p.x - cx, p.z - cz).length()
		print("f=%.2f road=(%.0f,%.0f,%.0f) raza=%.0f" % [f, p.x, p.y, p.z, d])
	# Profilul pe raza centru -> punctul de la f=0.40
	var i40 := int(0.40 * float(n)) % n
	var p40: Vector3 = r.baked[i40]
	var dirv := Vector2(p40.x - cx, p40.z - cz).normalized()
	var line := "PROFIL centru->f0.40:"
	for d in [0, 20, 40, 60, 80, 100, 120, 140, 160, 180]:
		var o := Vector2(cx, cz) + dirv * float(d)
		var q := PhysicsRayQueryParameters3D.create(Vector3(o.x, 200, o.y), Vector3(o.x, -200, o.y))
		var hit := space.intersect_ray(q)
		line += " %d:%s" % [d, ("%.1f" % float(hit.position.y)) if not hit.is_empty() else "--"]
	print(line)
	var te := track.find_child("Terrain", true, false)
	if te is MeshInstance3D:
		var ab: AABB = (te as MeshInstance3D).get_aabb()
		print("TEREN aabb pos=%s size=%s" % [str(ab.position), str(ab.size)])
	get_tree().quit(0)
