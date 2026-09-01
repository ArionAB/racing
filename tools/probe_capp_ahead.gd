extends Node
## E ceva IN FATA masinii pe elice, sau drumul e liber si totusi se opreste?
## Pentru fiecare punct din zona blocajului: exista sol sub axa (raza in jos)
## si e liber coridorul pe 6 m in fata, la inaltimea caroseriei?
## Vezi memoria `masoara-inainte-nu-langa`: sondele care masoara lateral rateaza
## exact ce vede soferul.


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	print("frac    sol_sub_axa   liber_6m_in_fata")
	for i in n:
		var f := r.frac_at(i)
		if f < 0.775 or f > 0.815:
			continue
		var p: Vector3 = r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p).normalized()
		# sol sub axa
		var down := PhysicsRayQueryParameters3D.create(
			p + Vector3.UP * 2.0, p - Vector3.UP * 3.0)
		var g := space.intersect_ray(down)
		var sol := "-"
		if not g.is_empty():
			sol = "%s la %+.2f" % [String((g["collider"] as Node).name),
				(g["position"] as Vector3).y - p.y]
		# coridor in fata, la 1 m peste asfalt
		var fwd_q := PhysicsRayQueryParameters3D.create(
			p + Vector3.UP * 1.0, p + Vector3.UP * 1.0 + fwd * 6.0)
		var h := space.intersect_ray(fwd_q)
		var lib := "liber"
		if not h.is_empty():
			lib = "BLOCAT de %s la %.2f m" % [
				String((h["collider"] as Node).name),
				(h["position"] as Vector3).distance_to(p + Vector3.UP)]
		print("%.4f  %-22s  %s" % [f, sol, lib])
	get_tree().quit(0)
