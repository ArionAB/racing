extends Node
## Sonda ad-hoc, folosinta unica: masoara ground_y la +-6/10/15 m de axa, pe
## segmentul podetului Chasm (frac 0.406-0.424), ca sa confirme daca rapa D
## sapa sau e plafonata de garda benzii scurtaturii (_carve_ravines,
## branch_floor). Doar citire.
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _t.baked.size()
	var route := _t.routes[0]
	var fracs: Array[float] = [0.400, 0.406, 0.412, 0.415, 0.418, 0.424, 0.430]
	for frac in fracs:
		var idx := int(round(frac * float(n))) % n
		var p: Vector3 = _t.baked[idx]
		var dir: Vector3 = (_t.baked[route.wrap_index(idx + 1)] - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()
		var road_y := p.y
		var line := "frac=%.3f road_y=%.2f  " % [frac, road_y]
		for off in [6.0, 10.0, 15.0, 20.0, 25.0, -6.0, -10.0, -15.0, -20.0, -25.0]:
			var wp: Vector3 = p + side * off
			var gy: float = _t._sampler.ground_y(wp.x, wp.z)
			line += " off=%+.0f rel=%+.2f" % [off, gy - road_y]
		print(line)
		# Distanta de la fiecare punct deplasat (+off pe side) la scurtatura baked.
		var dline := "  dist_to_scurtatura:"
		for off in [6.0, 10.0, 15.0, 20.0, 25.0, -6.0, -10.0, -15.0, -20.0, -25.0]:
			var wp2: Vector3 = p + side * off
			var best2 := INF
			for q in _t.routes[1].baked:
				var d2: float = Vector2(q.x - wp2.x, q.z - wp2.z).length()
				if d2 < best2:
					best2 = d2
			dline += " off=%+.0f:%.1f" % [off, best2]
		print(dline)
	# Distanta minima de la bridge la scurtatura baked (routes[1]), pe cateva
	# puncte reprezentative ale podetului (0.406-0.424).
	var route1 := _t.routes[1]
	var bridge_fracs: Array[float] = [0.406, 0.412, 0.415, 0.418, 0.424]
	for bf in bridge_fracs:
		var bidx := int(round(bf * float(n))) % n
		var bp: Vector3 = _t.baked[bidx]
		var best := INF
		for q in route1.baked:
			var d: float = Vector2(q.x - bp.x, q.z - bp.z).length()
			if d < best:
				best = d
		print("bridge frac=%.3f dist_min_to_scurtatura_baked=%.2f m" % [bf, best])
	get_tree().quit(0)
