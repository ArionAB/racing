extends Node
## WaterfallVisual construieste sheet-urile de la local Y=-SINK_M (2m sub
## marker) pana la Y=visual_height (peste marker) - deci marker-ul trebuie
## asezat la COTA APEI/bazei caderii, nu pe versantul care urca. Bazinul (fund
## declarat -8 fata de drum in custom_ravine_floors index 2) e cel mai adanc
## intre off=-18 si off=-30 la frac 0.858 (dy ~ -7). Pun marker-ul acolo, langa
## malul indepartat (spre off=-34/-38 unde incepe urcarea), ca perdeaua sa cada
## DIN malul care urca, cu baza in bazin.
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
	var f := 0.856
	var i := int(round(f * float(n))) % n
	var i0 := route.wrap_index(i - 4)
	var i1 := route.wrap_index(i + 4)
	var bp: Vector3 = _t.baked[i]
	var fwd: Vector3 = (_t.baked[i1] - _t.baked[i0]).normalized()
	var side: Vector3 = route.side_at(i)
	print("frac=%.4f idx=%d road=%s fwd=%s side=%s" % [f, i, bp, fwd, side])

	var lateral_offset := -32.0
	var space := get_tree().root.get_world_3d().direct_space_state
	var wp_probe: Vector3 = bp + side * lateral_offset
	var from := wp_probe + Vector3(0, 150, 0)
	var to := wp_probe + Vector3(0, -150, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(q)
	var ground_y: float = hit.position.y if not hit.is_empty() else bp.y
	print("ground at offset %.1f: y=%.2f (dy_vs_road=%.2f)" % [lateral_offset, ground_y, ground_y - bp.y])

	var bz := -fwd
	var by := Vector3.UP
	var bx := by.cross(bz).normalized()
	by = bz.cross(bx).normalized()

	var pos := Vector3(wp_probe.x, ground_y, wp_probe.z)
	print("pos = %s" % [pos])
	print("\nTransform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)" % [
		bx.x, by.x, bz.x,
		bx.y, by.y, bz.y,
		bx.z, by.z, bz.z,
		pos.x, pos.y, pos.z])
	print("lateral fata de axa = %.1f m" % lateral_offset)
	get_tree().quit(0)
