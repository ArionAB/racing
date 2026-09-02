extends Node
## Unde ajunge, de fapt, masa de pe malul opus.
##
## Sonda asta exista fiindca prima incercare de mal opus a IESIT in captura ca
## un perete tan lipit de buza — adica exact opusul cererii. Numarul care ar fi
## trecut („masa construita, N coloane") nu spune nimic: conteaza la ce RULAJ e
## talpa si coama, si daca terenul de acolo chiar urca peste fundul vaii.
##
## Se tipareste profilul in jurul rulajului cerut, ca sa se vada daca `far_offset_m`
## cade pe fund (masa n-are pe ce sta) sau pe mal (masa urca).
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
	for f: float in [0.20, 0.22, 0.25, 0.28, 0.31, 0.34]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var sd := s.side_at(i)
		print("\n=== frac %.2f — sosea y=%.1f ===" % [f, p.y])
		var best_off := 0.0
		var best_y := -999.0
		for d in range(20, 190, 10):
			var q := p + sd * float(d)
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 250.0, q.z), Vector3(q.x, p.y - 400.0, q.z))
			var hit := space.intersect_ray(pr)
			if hit.is_empty():
				continue
			var y := (hit["position"] as Vector3).y
			if y > best_y:
				best_y = y
				best_off = float(d)
		print("   creasta malului opus: y=%.1f la %d m rulaj (fund ~14, sosea %.1f)"
			% [best_y, int(best_off), p.y])
		print("   => %s" % ("mal REAL, masa are pe ce urca"
			if best_y > 20.0 else "nu exista mal aici"))
		# Si CE vede ochiul pe raza aia: daca creasta e sub linia privirii, masa
		# exista si tot nu apare in cadru (masurat: 0.00% la 0.22).
		var eye_y := p.y + ChaseCamera.DEFAULT_HEIGHT
		var ang := rad_to_deg(atan2(best_y - eye_y, maxf(best_off, 1.0)))
		print("   creasta e la %+.1f grade fata de ochi (negativ = sub linia privirii)"
			% ang)
	get_tree().quit()
