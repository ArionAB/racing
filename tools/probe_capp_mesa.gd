extends Node
## UNDE se pun mesele rosii ca sa astupe golul SI sa dea a doua adancime.
## Pentru azimuturile cu gol, se cauta punctul de la 150-260 m unde terenul e
## destul de jos ca o masa sa se vada peste buza vaii, si se tipareste
## transformul gata de lipit in .tscn.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var i := int(0.05 * n)
	var p: Vector3 = r.baked[i]
	var a: Vector3 = r.baked[(i + 6) % n]
	var dir: Vector3 = (a - p).normalized()
	var eye: Vector3 = p - dir * 12.5 + Vector3.UP * 10.0
	var right := dir.cross(Vector3.UP).normalized()
	var space := get_tree().root.world_3d.direct_space_state
	print("eye ", eye)
	for yaw_deg in [-30.0, -22.0, -14.0, -6.0, -2.0, 6.0, 14.0, 22.0, 30.0, 34.0]:
		for dist in [170.0, 210.0, 250.0]:
			var yaw := deg_to_rad(yaw_deg)
			var d := (dir * cos(yaw) + right * sin(yaw)).normalized()
			var xz: Vector3 = eye + d * dist
			# cota terenului acolo: raza de sus in jos
			var q := PhysicsRayQueryParameters3D.create(
				Vector3(xz.x, eye.y + 200.0, xz.z), Vector3(xz.x, eye.y - 300.0, xz.z))
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				print("yaw %5.0f d %3.0f : NIMIC sub" % [yaw_deg, dist])
				continue
			var gy: float = hit["position"].y
			# cat de sus trebuie sa urce ca sa fie vizibila din ochi peste 1 grad
			var need: float = eye.y - dist * tan(deg_to_rad(1.0)) - gy
			print("yaw %5.0f d %3.0f : teren y=%6.1f (eye-%5.1f)  masa ar trebui inalta de %5.1f m   pos=Vector3(%.1f, %.1f, %.1f)" % [
				yaw_deg, dist, gy, eye.y - gy, need, xz.x, gy, xz.z])
	get_tree().quit(0)
