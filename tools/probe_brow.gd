extends Node
## E MUCHIE sau e ROTUNJIRE? Panta terenului chiar la marginea benzii.
##
## Criticul: „marginea exterioara a benzii se rostogoleste intr-un fileu convex
## neted". Aici se masoara direct: se ia panta pe fiecare metru de la marginea
## asfaltului spre vale, si se cauta locul in care sare de la aproape-plat la
## abrupt. Cu cat saltul se face pe mai multi metri, cu atat e mai „fileu" si
## mai putin „buza".
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
		var sd := s.side_at(i)
		var hw := s.half_width_at(i)
		print("\n=== frac %.2f (marginea asfaltului la %.1f m) ===" % [f, hw])
		var prev_y := p.y
		var off := hw
		var first_steep := -1.0
		while off <= hw + 18.0:
			var q := p + sd * off
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 80.0, q.z), Vector3(q.x, p.y - 250.0, q.z))
			var hit := space.intersect_ray(pr)
			if hit.is_empty():
				off += 1.0
				continue
			var y := (hit["position"] as Vector3).y
			var slope := rad_to_deg(atan2(prev_y - y, 1.0))
			var mark := ""
			if slope > 45.0 and first_steep < 0.0:
				first_steep = off
				mark = "  <<< aici incepe caderea"
			print("   %5.1f m   y=%7.2f   panta pe ultimul metru %5.1f gr%s"
				% [off, y, slope, mark])
			prev_y = y
			off += 1.0
		if first_steep < 0.0:
			print("   >>> NICIO cadere abrupta in 18 m: e FILEU, nu buza")
		else:
			print("   >>> caderea incepe la %.1f m de ax, adica %.1f m dupa asfalt"
				% [first_steep, first_steep - hw])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
