extends Node
## UNDE se termina taietura, si CUM.
##
## In captura peretele se opreste la mijlocul cadrului cu o muchie verticala in
## aer, in loc sa intre in teren. Cauza posibila: `rise` cade sub pragul de 2 m
## brusc (coloana se intoarce goala dintr-un pas in altul), deci panza se taie
## drept in loc sa coboare.
##
## Se tipareste `rise` pe fiecare pas al taieturii, ca sa se vada daca scade
## lin sau cade in gol.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var space := get_viewport().world_3d.direct_space_state
	var off := 8.2
	for k in 30:
		var f: float = 0.238 + (0.345 - 0.238) * float(k) / 29.0
		var i := int(round(f * float(n))) % n
		var p := s.baked_point(i)
		var sd := s.side_at(i) * -1.0
		var foot := p + sd * off
		var fy := _ground(space, foot, p.y)
		fy = minf(fy, p.y) - 1.2
		var crest := -1e9
		var probe := 4.0
		while probe <= 22.0:
			var q := foot + sd * probe
			crest = maxf(crest, _ground(space, q, p.y))
			probe += 6.0
		var rise: float = minf(crest - fy, 18.0)
		print("frac %.3f  talpa %6.1f  creasta %6.1f  rise %6.1f  %s" % [
			f, fy, crest, rise, "GOL" if rise < 2.0 else ""])
	get_tree().quit()


func _ground(space: PhysicsDirectSpaceState3D, q: Vector3, ry: float) -> float:
	var pr := PhysicsRayQueryParameters3D.create(
		Vector3(q.x, ry + 300.0, q.z), Vector3(q.x, ry - 400.0, q.z))
	var hit := space.intersect_ray(pr)
	return (hit["position"] as Vector3).y if not hit.is_empty() else ry
