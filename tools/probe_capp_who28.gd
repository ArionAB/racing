extends Node
## Ce nod construieste peretele din STANGA cadrului la 0.28? Trag raze din
## ochiul soferului spre stanga si numar ce mesh lovesc, ca sa nu mai reglez
## nodul gresit.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	for f in [0.28, 0.30]:
		var i0 := int(f * n)
		var p: Vector3 = r.baked[i0]
		var a: Vector3 = r.baked[(i0 + 4) % n]
		var fwd: Vector3 = (a - p).normalized()
		var eye: Vector3 = p + Vector3.UP * 1.6
		print("--- frac %.2f, din ochi la %.1f" % [f, eye.y])
		var tally := {}
		# evantai spre STANGA si in fata, ca in cadru
		for az in [-70, -55, -40, -25, -10]:
			for pitch in [-14, -6, 2, 10]:
				var d: Vector3 = fwd.rotated(Vector3.UP, deg_to_rad(-float(az)))
				d = d.rotated(d.cross(Vector3.UP).normalized(), deg_to_rad(float(pitch)))
				var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 220.0)
				var h := space.intersect_ray(q)
				if h:
					var col = h["collider"]
					var nm: String = str(col.name) if col != null else "?"
					var pnt = col
					var path := nm
					if col != null and col.get_parent() != null:
						path = str(col.get_parent().name) + "/" + nm
					tally[path] = int(tally.get(path, 0)) + 1
				else:
					tally["CER"] = int(tally.get("CER", 0)) + 1
		for k in tally:
			print("   %4d raze -> %s" % [tally[k], k])
	get_tree().quit(0)
