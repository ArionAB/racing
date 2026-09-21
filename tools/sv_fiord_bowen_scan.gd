extends Node
## Sonda ad-hoc: scaneaza curbura (unghi intre directii succesive) pe portiunea
## Bowen (0.840-0.900) ca sa gasesc cel mai DREPT punct pentru kicker.
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	var f := 0.838
	while f <= 0.902:
		var idx := int(round(f * float(n))) % n
		var p: Vector3 = _t.baked[idx]
		var i0 := route.wrap_index(idx - 5)
		var i1 := route.wrap_index(idx + 5)
		var d0 := (_t.baked[idx] - _t.baked[i0]).normalized()
		var d1 := (_t.baked[i1] - _t.baked[idx]).normalized()
		var ang := rad_to_deg(d0.angle_to(d1))
		print("frac=%.4f idx=%d pos=(%.1f,%.1f,%.1f) hw=%.2f curv10pt=%.2fdeg"
			% [f, idx, p.x, p.y, p.z, _t.width_at_index(idx), ang])
		f += 0.004
	get_tree().quit(0)
