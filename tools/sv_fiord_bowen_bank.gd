extends Node
## Rafinare: gaseste EXACT unde se termina bazinul (fund apa) si incepe malul
## exterior care urca, pe partea sgn=-1 (stanga, bazinul), la fracurile G
## (0.84-0.858), pas fin intre -20 si -70 m.
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
	for f in [0.840, 0.845, 0.850, 0.8581, 0.862]:
		var i := int(round(float(f) * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var side: Vector3 = route.side_at(i)
		print("\nfrac=%.4f road=(%.1f,%.2f,%.1f)" % [f, bp.x, bp.y, bp.z])
		var lat := -18.0
		while lat >= -70.0:
			var wp: Vector3 = bp + side * lat
			var from := wp + Vector3(0, 150, 0)
			var to := wp + Vector3(0, -150, 0)
			var q := PhysicsRayQueryParameters3D.create(from, to)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				print("  off=%+6.1f  NICIUN HIT" % [lat])
			else:
				var hy: float = hit.position.y
				print("  off=%+6.1f  world=(%.1f,%.1f)  hitY=%7.2f  dy_vs_road=%+7.2f"
					% [lat, wp.x, wp.z, hy, hy - bp.y])
			lat -= 4.0
	get_tree().quit(0)
