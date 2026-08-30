extends Node
## Masuratoare de teren pentru POI F (subteranul), inainte sa se aseze ceva.
##
## Nu construieste nimic: intreaba geometria REALA a motorului (routes[0].baked
## plus raze de fizica) ce cote, ce latimi si ce pereti exista pe frac
## 0.63-0.79, ca sălile sa fie sapate pe drumul care exista, nu pe cel din brief.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	print("puncte %d, lungime %.1f m" % [n, r.length()])

	var ground := func(p: Vector3, up: float, dn: float) -> float:
		var q := PhysicsRayQueryParameters3D.create(
			p + Vector3.UP * up, p + Vector3.DOWN * dn)
		var h := space.intersect_ray(q)
		return NAN if h.is_empty() else float(h.position.y)

	print("")
	print("frac    x        z        y      hw    | teren la +8/+14/+22 st | dr")
	var f := 0.62
	while f < 0.80:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var row := "%.3f %8.2f %8.2f %7.2f %5.2f |" % [
			f, c.x, c.z, c.y, track.width_at(f)]
		for d: float in [8.0, 14.0, 22.0, -8.0, -14.0, -22.0]:
			var g: float = ground.call(c + side * d, 60.0, 60.0)
			row += ("%+7.1f" % (g - c.y)) if not is_nan(g) else "   ----"
		print(row)
		f += 0.005
	get_tree().quit()
