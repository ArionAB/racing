extends Node
## CINE acopera faleza. Sonda de proiectie spune ca 97% din panza e ascunsa;
## profilul de teren spune ca terenul NU sta peste buza. Deci paravanul e
## altceva — aici i se cere NUMELE: pentru fiecare vertex ascuns, se trage raza
## ochi->vertex si se scrie ce nod o opreste.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var mis: Array[Node] = []
	_walk(t, mis)
	for f: float in [0.22, 0.28, 0.34]:
		_shoot(t, f, mis)
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _shoot(t: Track, frac: float, mis: Array[Node]) -> void:
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	var target := focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
	var fwd := (target - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var half_v := tan(deg_to_rad(ChaseCamera.BASE_FOV) * 0.5)
	var half_h := half_v * (16.0 / 9.0)
	var space := get_viewport().world_3d.direct_space_state
	var blockers: Dictionary = {}
	var inside := 0
	var vis := 0
	for m in mis:
		var mi := m as MeshInstance3D
		var arr := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var step := maxi(int(verts.size() / 900), 1)
		var k := 0
		while k < verts.size():
			var w: Vector3 = mi.global_transform * verts[k]
			k += step
			var rel := w - eye
			var z := rel.dot(fwd)
			if z <= 0.5:
				continue
			if absf(rel.dot(right) / (z * half_h)) > 1.0:
				continue
			if absf(rel.dot(up) / (z * half_v)) > 1.0:
				continue
			inside += 1
			var q := PhysicsRayQueryParameters3D.create(eye, w)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				vis += 1
				continue
			var hp: Vector3 = hit["position"]
			if eye.distance_to(hp) >= eye.distance_to(w) - 1.0:
				vis += 1
				continue
			var nm := String((hit["collider"] as Node).name)
			blockers[nm] = int(blockers.get(nm, 0)) + 1
	print("\n=== frac %.2f: in frustum %d, vizibili %d ===" % [frac, inside, vis])
	var keys := blockers.keys()
	keys.sort_custom(func(a, b): return int(blockers[a]) > int(blockers[b]))
	for kk in keys:
		print("   paravan: %-34s %d vertecsi" % [kk, blockers[kk]])

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Faleza"):
			out.append(c)
		_walk(c, out)
