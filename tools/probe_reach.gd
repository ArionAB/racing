extends Node
## CAT DE DEPARTE trebuie sa iasa faleza ca s-o vada camera de joc.
##
## Nu se ghiceste evazarea: se trage o raza din ochi spre un punct de proba
## aflat la rulajul `off` si adancimea `dy` sub cota soselei, si se intreaba
## daca ajunge. Coloana de raspunsuri spune exact de la ce rulaj incolo peretele
## iese de sub silueta tablierului.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
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
		var i := int(f * float(s.point_count())) % s.point_count()
		var p := s.baked_point(i)
		var sd := s.side_at(i)
		var hw := s.half_width_at(i)
		print("\n=== frac %.2f (hw=%.1f) — rulaj necesar ca punctul sa fie VAZUT ===" % [f, hw])
		print("      adancime sub sosea:      2m     6m    12m    20m    28m")
		var off := hw
		while off <= hw + 26.0:
			var line := "  lateral %5.1f m:" % off
			for dy: float in [2.0, 6.0, 12.0, 20.0, 28.0]:
				var w := p + sd * off + Vector3(0, -dy, 0)
				var q := PhysicsRayQueryParameters3D.create(eye, w)
				var hit := space.intersect_ray(q)
				var seen := true
				if not hit.is_empty():
					if eye.distance_to(hit["position"] as Vector3) < eye.distance_to(w) - 0.6:
						seen = false
				line += "   %s  " % ("DA " if seen else "nu ")
			print(line)
			off += 2.0
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
