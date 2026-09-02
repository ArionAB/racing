extends Node
## PROFILUL INBOARD (side = -1) pe portiunea cornisei.
##
## De ce: capturile arata drumul ASEZAT pe o duna — fara fata taiata in interior.
## Ca sa pot sapa o polita trebuie sa stiu daca terenul dinspre interior URCA
## (deci se poate taia in el) sau COBOARA (si atunci n-am in ce sapa).
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
	for f: float in [0.20, 0.24, 0.26, 0.28, 0.30, 0.34, 0.38]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var sd := s.side_at(i)
		var line := ""
		var rise := -999.0
		for d: float in [7, 10, 14, 20, 28, 40, 55, 75]:
			var q := p - sd * d
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 300.0, q.z), Vector3(q.x, p.y - 400.0, q.z))
			var hit := space.intersect_ray(pr)
			if hit.is_empty():
				line += "%d:- " % int(d)
				continue
			var y := (hit["position"] as Vector3).y
			line += "%d:%+.0f " % [int(d), y - p.y]
			rise = maxf(rise, y - p.y)
		print("frac %.2f sosea y=%.1f | inboard delta: %s | max +%.1f" % [f, p.y, line, rise])
	get_tree().quit()
