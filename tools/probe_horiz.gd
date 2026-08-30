extends Node
## Peste ce trece privirea spre dreapta: profilul terenului pe raza ochiului.
##
## Zoom-ul de sus arata faleza construita si colorata, dar la zeci de metri de
## drum, peste o platforma larga. Ipoteza: platforma aia isi face propriul
## orizont, iar peretele cade SUB el. Se verifica direct — se merge din ochi in
## lungul razei spre dreapta si se scrie unghiul de ridicare (elevatia) al
## fiecarui punct de teren. Daca un punct APROPIAT are elevatie mai mare decat
## peretele, el ascunde peretele, oricat de inalt ar fi acesta.
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
		print("\n=== frac %.2f — elevatia terenului pe raza spre dreapta (ochi y=%.1f) ===" % [f, eye.y])
		print("   rulaj   cota teren   elevatie fata de ochi   orizont curent")
		var best := -90.0
		var off := 6.0
		while off <= 90.0:
			var q := p + sd * off
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 150.0, q.z), Vector3(q.x, p.y - 300.0, q.z))
			var hit := space.intersect_ray(pr)
			if hit.is_empty():
				off += 4.0
				continue
			var w: Vector3 = hit["position"]
			var horiz := Vector2(w.x - eye.x, w.z - eye.z).length()
			var elev := rad_to_deg(atan2(w.y - eye.y, horiz))
			var mark := ""
			if elev > best:
				best = elev
				mark = "  <-- ridica orizontul (se vede)"
			print("   %5.1f   %10.2f   %18.2f gr   %8.2f gr%s" % [off, w.y, elev, best, mark])
			off += 4.0
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
