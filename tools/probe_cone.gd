extends Node
## Ce vede camera, nu ce e langa masina: conul de vizibilitate de la fracii
## fotografiati. Trage raze pe directia privirii (inainte), la mai multe
## deschideri laterale, si scrie si coordonatele lumii ca sa pot pune
## scobituri exact acolo.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	var args := OS.get_cmdline_user_args()
	var fracs: Array = [0.10, 0.13, 0.16]
	for a in args:
		if a.begins_with("--fracs="):
			fracs = []
			for s in a.substr(8).split(","):
				fracs.append(float(s))
	print("baked points: ", n)
	for f0 in fracs:
		var i0 := int(f0 * n)
		var p0: Vector3 = r.baked[i0]
		var a0: Vector3 = r.baked[(i0 + 4) % n]
		var fwd: Vector3 = (a0 - p0).normalized()
		var sid: Vector3 = fwd.cross(Vector3.UP).normalized()
		print("")
		print("=== frac %.3f  idx %d  drum la (%.1f, %.1f, %.1f)  fwd=(%.2f,%.2f)  side=(%.2f,%.2f)" % [
			f0, i0, p0.x, p0.y, p0.z, fwd.x, fwd.z, sid.x, sid.z])
		# conul: distanta in fata x unghi lateral (dreapta pozitiv = valea)
		print("  dist |  -20deg   -0deg   +15deg   +30deg   +45deg   +60deg   +75deg   +90deg")
		for dist in [40.0, 70.0, 110.0, 160.0, 220.0]:
			var row := "  %4.0f |" % dist
			for ang in [-20.0, 0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0]:
				var d2: Vector3 = fwd.rotated(Vector3.UP, -deg_to_rad(ang))
				var q: Vector3 = p0 + d2 * dist
				var ry := PhysicsRayQueryParameters3D.create(
					Vector3(q.x, p0.y + 320.0, q.z), Vector3(q.x, p0.y - 400.0, q.z))
				var hh := space.intersect_ray(ry)
				if hh:
					row += " %7.1f" % (float(hh["position"].y) - p0.y)
				else:
					row += "     gol"
			print(row)
		# coordonatele XZ ale conului, ca sa stiu unde sa sap
		print("  XZ ale conului (dist @ +45 / +60 / +75):")
		for dist in [70.0, 110.0, 160.0, 220.0]:
			var s := "   %4.0f m:" % dist
			for ang in [45.0, 60.0, 75.0]:
				var d2: Vector3 = fwd.rotated(Vector3.UP, -deg_to_rad(ang))
				var q: Vector3 = p0 + d2 * dist
				s += "  (%.0f, %.0f)" % [q.x, q.z]
			print(s)
	get_tree().quit(0)
