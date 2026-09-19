extends Node
## Sampler-ul si `Track.baked` sunt aceeasi curba? `_cut_column` aseaza talpa la
## `sampler.baked_point(i) + side_at(i) * cut_offset_m`, adica 7,6 m de la AX,
## dar vertecsii masurati stau la 19,5-24 m de ax. Diferenta de ~12 m trebuie sa
## fie intr-unul din cei trei termeni, si singurul nemasurat inca e SAMPLER-UL.
##
## Compara, punct cu punct, `sampler.baked_point(i)` cu `_track.baked[i]`,
## `sampler.half_width_at(i)` cu `_track.width_at_index(i)`, si `side_at` intre
## cele doua. Memoria `sonda-masura-alt-obiect`: cifre care nu se potrivesc
## inseamna ca cele doua unelte nu privesc acelasi lucru.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sm = _track.get("_sampler")
	if sm == null:
		print("_sampler e null"); get_tree().quit(0); return
	var n := _track.baked.size()
	print("Track.baked: ", n, "   sampler.point_count: ", sm.point_count())
	for f in [0.070, 0.126, 0.180]:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = _track.baked[i]
		var sp: Vector3 = sm.baked_point(i)
		print("frac %.3f idx %d" % [f, i])
		print("   Track.baked   = (%.2f, %.2f, %.2f)" % [bp.x, bp.y, bp.z])
		print("   sampler point = (%.2f, %.2f, %.2f)   distanta %.2f m" % [sp.x, sp.y, sp.z, bp.distance_to(sp)])
		print("   half_width sampler %.2f   Track.width_at_index %.2f" % [sm.half_width_at(i), _track.width_at_index(i)])
		var sa: Vector3 = sm.side_at(i)
		var ta: Vector3 = (_track.baked[(i + 1) % n] - bp).normalized().cross(Vector3.UP).normalized()
		print("   side_at sampler (%.3f,%.3f)  vs Track (%.3f,%.3f)  unghi %.1f grade" % [sa.x, sa.z, ta.x, ta.z, rad_to_deg(sa.angle_to(ta))])
		# Reface EXACT ce face `_cut_column`: talpa la offset pe `sd`.
		var cf := _track.get_node("Faleze").get_child(0) as CliffFace
		var sd: Vector3 = sm.side_at(i) * -signf(cf.side)
		var foot: Vector3 = sm.baked_point(i) + sd * cf.cut_offset_m
		var latd: float = (foot - bp).dot(ta)
		print("   TALPA reconstruita: (%.2f,%.2f)  lateral fata de ax %+.2f m  (+ = dreapta)" % [foot.x, foot.z, latd])
	get_tree().quit(0)
