extends Node
## Sonda ad-hoc: de ce cade fiecare masina o data la frac ~0.794 pe Track16
## (coborarea F, dupa tunel), langa pos (38, 12, -231)? Dump baked road, latime,
## curbura si panta la rezolutie fina in jurul zonei, plus raycast fizic.
const TRACK := "res://scenes/tracks/Track16.tscn"
const TARGET := Vector3(38, 12, -231)
var _t: Track

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	print("baked road n=%d" % n)
	# gaseste indexul cel mai apropiat de TARGET
	var best_i := 0
	var best_d := INF
	for i in n:
		var d: float = _t.baked[i].distance_to(TARGET)
		if d < best_d:
			best_d = d
			best_i = i
	var best_f := _t.frac_at(best_i)
	print("cel mai apropiat punct de %s: idx=%d frac=%.4f baked=%s dist=%.2f"
		% [TARGET, best_i, best_f, _t.baked[best_i], best_d])

	print("\nfrac    idx   bakedY   width   dOFFROAD_L  dOFFROAD_R")
	var f0 := best_f - 0.02
	var f1 := best_f + 0.02
	var f := f0
	while f < f1:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var w := _t.width_at_index(i)
		print("%.4f  %4d  %7.3f  %5.2f  pos=(%.1f,%.2f,%.1f)" % [f, i, bp.y, w, bp.x, bp.y, bp.z])
		f += 0.002

	print("\n--- curbura si panta fina (pas 12 baked-index ~ ce foloseste ProbeLayout) ---")
	f = f0
	while f < f1:
		var i := int(round(f * float(n))) % n
		var a: Vector3 = _t.baked[route.wrap_index(i - 6)]
		var b: Vector3 = _t.baked[i]
		var c: Vector3 = _t.baked[route.wrap_index(i + 6)]
		var ab := Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
		var bc := Vector2(b.x, b.z).distance_to(Vector2(c.x, c.z))
		var ca := Vector2(c.x, c.z).distance_to(Vector2(a.x, a.z))
		var s := (ab + bc + ca) * 0.5
		var area2 := maxf(1e-6, s * (s - ab) * (s - bc) * (s - ca))
		var rad := ab * bc * ca / (4.0 * sqrt(area2))
		var d := b.distance_to(c)
		var slope := (c.y - b.y) / maxf(d, 0.001)
		print("%.4f  raza=%7.1f  panta=%+.1f%%" % [f, rad, slope * 100.0])
		f += 0.002

	print("\n--- raycast fizic din sus in jos, INCLUSIV lateral (+/- half_width) ---")
	var space := get_tree().root.get_world_3d().direct_space_state
	f = f0
	while f < f1:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var w := _t.width_at_index(i)
		var side := route.side_at(i)
		for off in [-w * 0.9, 0.0, w * 0.9]:
			var p := bp + side * off
			var from := p + Vector3(0, 60, 0)
			var to := p + Vector3(0, -60, 0)
			var q := PhysicsRayQueryParameters3D.create(from, to)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				print("  f=%.4f off=%+.1f  NICIUN HIT" % [f, off])
			else:
				var hy: float = hit.position.y
				var delta := hy - bp.y
				print("  f=%.4f off=%+.1f  hitY=%7.3f  bakedY=%7.3f  delta=%+.3f  collider=%s" % [
					f, off, hy, bp.y, delta, str(hit.get("collider"))])
		f += 0.004

	get_tree().quit(0)
