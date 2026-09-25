extends Node
## Continuare sv_fiord_bowen_wall.gd: scan mai larg pe lateral (pana la 120 m)
## pe AMBELE parti, la fracurile cheie 0.858 (kicker) si 0.87/0.885 (dupa
## kicker), ca sa gasesc PERETELE inalt (daca exista in terenul curent) din
## care ar cadea Bowen, nu doar taluzul imediat al rapei.
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	var space := get_tree().root.get_world_3d().direct_space_state
	var fracs := [0.858, 0.87, 0.885]
	for f in fracs:
		var i := int(round(float(f) * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var side: Vector3 = route.side_at(i)
		print("\nfrac=%.4f road=(%.1f,%.2f,%.1f)" % [f, bp.x, bp.y, bp.z])
		for lat in [60.0, 75.0, 90.0, 105.0, 120.0, 150.0]:
			for sgn in [1.0, -1.0]:
				var wp: Vector3 = bp + side * (lat * sgn)
				var from := wp + Vector3(0, 150, 0)
				var to := wp + Vector3(0, -150, 0)
				var q := PhysicsRayQueryParameters3D.create(from, to)
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					print("  off=%+6.1f (sgn=%+.0f) world=(%.1f,%.1f)  NICIUN HIT" % [lat * sgn, sgn, wp.x, wp.z])
				else:
					var hy: float = hit.position.y
					print("  off=%+6.1f (sgn=%+.0f) world=(%.1f,%.1f)  hitY=%7.2f  dy_vs_road=%+7.2f"
						% [lat * sgn, sgn, wp.x, wp.z, hy, hy - bp.y])
	get_tree().quit(0)
