extends Node
## E peretele opus INGROPAT in teren? Pentru fiecare coloana a lui se compara
## cota coamei cu cota SUPRAFETEI terenului in acelasi loc. Daca terenul e mai
## sus, peretele e sub el si nu poate desena nimic — ceea ce ar explica de ce
## panza exista, are AABB corect, si cadrul nu se schimba.
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
	print("=== peretele opus fata de teren (rulaj 26 m) ===")
	print("  frac    cota drum   fund vale   coama perete   teren la 26m   verdict")
	var f := 0.20
	while f <= 0.375:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var sd := s.side_at(i)
		var base := p + sd * 26.0
		var pr := PhysicsRayQueryParameters3D.create(
			Vector3(base.x, p.y + 120.0, base.z), Vector3(base.x, p.y - 250.0, base.z))
		var hit := space.intersect_ray(pr)
		var ty := -999.0
		if not hit.is_empty():
			ty = (hit["position"] as Vector3).y
		var top := minf(ty + 22.0, p.y + 5.0)
		var verdict := "vizibil"
		if ty > top - 0.5:
			verdict = "INGROPAT (terenul e peste coama)"
		print("  %.3f   %8.2f   %9.2f   %12.2f   %12.2f   %s"
			% [f, p.y, ty, top, ty, verdict])
		f += 0.0125
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
