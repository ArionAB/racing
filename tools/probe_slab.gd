extends Node
## CE e masa rosie din dreapta-sus a cadrului de la fractia 0.22?
##
## De ce sonda: la 0.22 se vad lespezi rosii care plutesc, taiate in dinti de
## fierastrau, infipte pe jumatate intr-un con crem. Doua presupuneri (pintenul
## `far_wall`, apoi inceputul panzei de buza) au fost stinse pe rand si captura
## NU s-a schimbat cu un pixel — semn ca geometria e a altui nod. Deci n-o mai
## ghicesc: trag raze din ochiul soferului spre coltul in care apar si intreb
## corpul lovit cum il cheama.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var i := int(0.22 * float(n)) % n
	var p := s.baked_point(i)
	var i2 := (i + 3) % n
	var fwd := (s.baked_point(i2) - p).normalized()
	var right := Vector3(-fwd.z, 0.0, fwd.x).normalized()
	var eye := p + Vector3.UP * 6.0 - fwd * 8.0
	print("ochi %s  inainte %s" % [eye, fwd])
	# Coltul dreapta-sus: spre dreapta si putin in sus.
	for yaw in [20.0, 30.0, 40.0, 50.0]:
		for pitch in [-2.0, 4.0, 10.0, 16.0]:
			var dir := fwd.rotated(Vector3.UP, deg_to_rad(-yaw))
			dir = dir.rotated(right.rotated(Vector3.UP, deg_to_rad(-yaw)), deg_to_rad(pitch))
			var pr := PhysicsRayQueryParameters3D.create(eye, eye + dir * 400.0)
			var hit := get_viewport().world_3d.direct_space_state.intersect_ray(pr)
			if hit.is_empty():
				print("  yaw %4.0f pitch %4.0f  -> cer" % [yaw, pitch])
			else:
				var c: Node = hit["collider"]
				var pos: Vector3 = hit["position"]
				print("  yaw %4.0f pitch %4.0f  -> %-28s la %6.1f m, y %6.2f (drum %6.2f)"
					% [yaw, pitch, c.name, eye.distance_to(pos), pos.y, p.y])
	# Si ce noduri VIZUALE exista in zona, cu numele parintelui.
	print("\n=== noduri de geometrie in raza de 120 m de punctul 0.22 ===")
	_walk(t, p, 120.0, 0)
	get_tree().quit()

func _walk(node: Node, ref: Vector3, r: float, depth: int) -> void:
	if node is VisualInstance3D:
		var gi := node as VisualInstance3D
		var ab := gi.get_aabb()
		var centre: Vector3 = gi.global_transform * ab.get_center()
		if centre.distance_to(ref) < r:
			var parent_name: String = node.get_parent().name if node.get_parent() != null else "-"
			print("   %-30s parinte %-24s centru %s  marime %s"
				% [node.name, parent_name, centre.round(), ab.size.round()])
	for c in node.get_children():
		_walk(c, ref, r, depth + 1)
