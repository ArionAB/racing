extends SceneTree
# Masoara, din OCHIUL CAMEREI DE JOC, cat de jos coboara raza spre lateral:
# adica UNGHIUL sub orizontala la care ochiul vede solul la diverse distante.
# Cifra din survey e pe verticala terenului; asta e ce vede efectiv camera.
func _init() -> void:
	var ts := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var tr = ts.instantiate()
	get_root().add_child(tr)
	await process_frame
	await process_frame
	var n: int = tr.baked.size()
	var space := (tr as Node3D).get_world_3d().direct_space_state
	print("frac | dist lat | unghi sub orizontala vazut din ochi (grade), -1 / +1")
	for f in [0.215, 0.24, 0.30, 0.33]:
		var i := int(f * float(n)) % n
		var p: Vector3 = tr.baked[i]
		var s: Vector3 = tr._side_at(i)
		var half: float = tr.width_at_index(i)
		var eye := p + Vector3(0, 10.0, 0)
		var row := "%.3f |" % f
		for off in [10.0, 20.0, 40.0, 80.0]:
			var vals := []
			for sg in [-1.0, 1.0]:
				var q: Vector3 = p + s * sg * (half + off)
				var pr := PhysicsRayQueryParameters3D.create(
					q + Vector3(0, 400, 0), q - Vector3(0, 400, 0))
				var hit := space.intersect_ray(pr)
				if hit.is_empty():
					vals.append("  --")
					continue
				var gy: float = (hit["position"] as Vector3).y
				var horiz: float = (half + off)
				var ang := rad_to_deg(atan2(eye.y - gy, horiz))
				vals.append("%5.1f" % ang)
			row += "  %2.0fm:%s/%s" % [off, vals[0], vals[1]]
		print(row)
	quit(0)
