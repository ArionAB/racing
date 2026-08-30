extends Node
## CE E obiectul rosu din coltul din dreapta-jos al cadrului.
##
## Criticul orb l-a numit „un decal rosu placeholder, neancorat, taiat de
## marginea de jos". Nu se ghiceste ce e: se trag raze exact prin coltul acela
## din camera REALA (--gamecam, adica ChaseCamera) si se cere numele nodului.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var space := get_viewport().world_3d.direct_space_state
	for f: float in [0.22, 0.28, 0.34]:
		var idx := int(f * float(n)) % n
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
		print("\n=== frac %.2f — coltul dreapta-jos (sh 0.55..0.95, sv 0.55..0.95) ===" % f)
		var seen := {}
		for a in 6:
			var sv := 0.55 + 0.08 * float(a)
			for b in 6:
				var sh := 0.55 + 0.08 * float(b)
				var rd := (fwd + right * (sh * half_h) - up * (sv * half_v)).normalized()
				var q := PhysicsRayQueryParameters3D.create(eye, eye + rd * 300.0)
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					continue
				var nd := hit["collider"] as Node
				var chain := String(nd.name)
				var cur := nd.get_parent()
				var depth := 0
				while cur != null and depth < 3:
					chain = String(cur.name) + "/" + chain
					cur = cur.get_parent()
					depth += 1
				var d := eye.distance_to(hit["position"] as Vector3)
				if not seen.has(chain):
					seen[chain] = d
		for k in seen.keys():
			print("   %-56s la %.1f m" % [k, seen[k]])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
