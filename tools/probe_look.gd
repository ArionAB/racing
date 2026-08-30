extends Node
## UNDE se uita, in metri de lume, camera din fiecare cadru judecat — si ce
## lovesc razele trimise prin cadru.
##
## Fara asta, „pune stanca la 105 m pe dreapta" e o presupunere: pe o serpentina
## privirea nu mai e perpendiculara pe rulaj, deci „dreapta soselei" si „dreapta
## cadrului" sunt doua locuri diferite. Aici se trag raze prin cadru si se
## tipareste unde cad, ca masa sa fie pusa acolo, nu unde pare din plan.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var space := get_viewport().world_3d.direct_space_state
	for f: float in [0.22, 0.28, 0.34]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var ahead := s.baked_point((i + 12) % n)
		var dir := (ahead - p).normalized()
		var eye := p - dir * ChaseCamera.DEFAULT_DISTANCE \
			+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var right := dir.cross(Vector3.UP).normalized() * -1.0
		print("\n=== frac %.2f — ochi (%.0f, %.0f, %.0f) ===" % [f, eye.x, eye.y, eye.z])
		# raze prin jumatatea DREAPTA a cadrului
		for yaw: float in [5.0, 15.0, 25.0, 35.0]:
			for pitch: float in [0.0, -8.0]:
				var d := (dir.rotated(Vector3.UP, deg_to_rad(-yaw))
					+ Vector3.UP * tan(deg_to_rad(pitch))).normalized()
				var pr := PhysicsRayQueryParameters3D.create(eye, eye + d * 400.0)
				var hit := space.intersect_ray(pr)
				if hit.is_empty():
					print("   yaw %+3.0f pitch %+3.0f  -> CER" % [yaw, pitch])
				else:
					var w: Vector3 = hit["position"]
					print("   yaw %+3.0f pitch %+3.0f  -> (%.0f, %.0f, %.0f) la %.0f m"
						% [yaw, pitch, w.x, w.y, w.z, eye.distance_to(w)])
	get_tree().quit()
