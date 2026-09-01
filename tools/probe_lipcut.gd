extends Node
## De ce nu se vede faleza: PROFILUL TERENULUI langa buza.
##
## Sonda de proiectie spune ca 994 din 1070 de vertecsi ai panzei sunt in
## frustum si doar 29 NEascunsi. Deci faleza nu lipseste si nu e intoarsa: e
## ACOPERITA. Aici se masoara de cine — se plimba un esantion pe lateral, de la
## marginea asfaltului spre vale, si se scrie cota SUPRAFETEI (mesh, prin raza)
## fata de cota BUZEI. Daca terenul sta peste linia buzei dupa marginea benzii,
## el e paravanul.
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
		print("\n=== frac %.2f  ax y=%.2f  semilatime=%.2f ===" % [f, p.y, hw])
		var lip_y := p.y - Track.ROAD_THICKNESS * 0.72
		print("  cota buzei falezei: %.2f" % lip_y)
		var off := hw - 1.0
		while off < hw + 40.0:
			var q := p + sd * off
			# raza de sus in jos: cota SUPRAFETEI randate, nu a campului
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 60.0, q.z), Vector3(q.x, p.y - 200.0, q.z))
			var hit := space.intersect_ray(pr)
			var sy := -999.0
			if not hit.is_empty():
				sy = (hit["position"] as Vector3).y
			var flag := ""
			if sy > lip_y + 0.3 and off > hw + 0.5:
				flag = "  <<< PARAVAN (peste buza)"
			print("   lateral %6.1f m   suprafata y=%8.2f   fata de buza %+7.2f%s"
				% [off, sy, sy - lip_y, flag])
			off += 2.0
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
