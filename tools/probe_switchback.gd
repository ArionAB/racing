extends Node
## Ce are soferul IN STANGA pe bucla de JOS a serpentinei, si cat de jos e ea.
##
## Doua intrebari, amandoua platite deja o data cu o captura pierduta:
##
##  1. La ce rulaj lateral urca terenul peste cota drumului, si cu cat. Fara
##     cifra asta `far_offset_m` al taieturii e ghicit — iar o panza asezata
##     DINCOLO de creasta ramane ascunsa in spatele ei. Exact asta s-a intamplat
##     la prima incercare (offset 26 m): duna crem acoperea toata fata rosie.
##  2. Cat de mult e bucla de sus DEASUPRA celei de jos, masurat in lume, nu in
##     tabelul de puncte — adica exista sau nu cei doua etaje pe care se sprijina
##     toata compozitia referintei.
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
	print("\n=== DREAPTA (vale): teren fata de cota drumului ===")
	for f: float in [0.175, 0.185, 0.195, 0.205, 0.215, 0.225, 0.235]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		# side_at da DREAPTA; stanga e semnul opus.
		var sd := s.side_at(i)
		var line := "frac %.2f  drum_y %6.2f | " % [f, p.y]
		for off: float in [7.0, 10.0, 14.0, 18.0, 24.0, 32.0, 44.0]:
			var q := p + sd * off
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 300.0, q.z), Vector3(q.x, p.y - 300.0, q.z))
			var hit := space.intersect_ray(pr)
			if hit.is_empty():
				line += "%.0fm:  --   " % off
			else:
				line += "%.0fm:%+6.1f " % [off, (hit["position"] as Vector3).y - p.y]
		print(line)
	print("\n=== ETAJELE: cat e bucla de sus peste cea de jos ===")
	for f: float in [0.26, 0.28, 0.30, 0.32]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var best := 1e9
		var best_f := -1.0
		var best_dy := 0.0
		for j in range(int(0.19 * float(n)), int(0.245 * float(n))):
			var q := s.baked_point(j % n)
			var d := Vector2(p.x - q.x, p.z - q.z).length()
			if d < best:
				best = d
				best_f = float(j) / float(n)
				best_dy = q.y - p.y
		print("  jos frac %.2f (y %6.2f) <-> sus frac %.3f la %5.1f m in plan, cu %+5.1f m mai SUS"
			% [f, p.y, best_f, best, best_dy])
	get_tree().quit()
