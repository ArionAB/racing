extends Node
## Raycast lateral la frac Stirling (0.2978), ca sa stabilesc conventia:
## fiordul (marea, gol) e stanga sau dreapta fata de sgn=route.side_at?
## Brief: "fiordul pe stanga, peretele/cascada pe dreapta" pe cornisa.
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
	for f in [0.29, 0.2978, 0.31]:
		var i := int(round(float(f) * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var side: Vector3 = route.side_at(i)
		print("\nfrac=%.4f road=(%.1f,%.2f,%.1f) side=(%.2f,_,%.2f)" % [f, bp.x, bp.y, bp.z, side.x, side.z])
		for lat in [10.0, 30.0, 60.0, 100.0]:
			for sgn in [1.0, -1.0]:
				var wp: Vector3 = bp + side * (lat * sgn)
				var from := wp + Vector3(0, 150, 0)
				var to := wp + Vector3(0, -150, 0)
				var q := PhysicsRayQueryParameters3D.create(from, to)
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					print("  off=%+6.1f (sgn=%+.0f)  NICIUN HIT (mare/gol)" % [lat * sgn, sgn])
				else:
					var hy: float = hit.position.y
					print("  off=%+6.1f (sgn=%+.0f)  hitY=%7.2f  dy_vs_road=%+7.2f"
						% [lat * sgn, sgn, hy, hy - bp.y])
	get_tree().quit(0)
