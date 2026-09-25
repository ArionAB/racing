extends Node
## Sonda ad-hoc: pe ce parte (sgn fata de route.side_at) sta StirlingFalls,
## ca referinta de conventie pentru Bowen (acelasi tipar: cascada reala,
## perete de stanca langa drum).
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
	var sf := _t.get_node("Hazarduri/StirlingFalls") as Node3D
	var idx := _t.closest_index_global(sf.global_position)
	var f := _t.frac_at(idx)
	var bp: Vector3 = _t.baked[idx]
	var side: Vector3 = route.side_at(idx)
	var rel := sf.global_position - bp
	var lat := Vector2(side.x, side.z).dot(Vector2(rel.x, rel.z))
	print("StirlingFalls global=%s frac=%.4f road=(%.1f,%.2f,%.1f) side=(%.2f,_,%.2f) lat_signed=%.2f"
		% [sf.global_position, f, bp.x, bp.y, bp.z, side.x, side.z, lat])

	var kb := _t.get_node("Hazarduri/KickerBowen") as Node3D
	var idx2 := _t.closest_index_global(kb.global_position)
	var f2 := _t.frac_at(idx2)
	var bp2: Vector3 = _t.baked[idx2]
	var side2: Vector3 = route.side_at(idx2)
	var rel2 := kb.global_position - bp2
	var lat2 := Vector2(side2.x, side2.z).dot(Vector2(rel2.x, rel2.z))
	print("KickerBowen global=%s frac=%.4f road=(%.1f,%.2f,%.1f) side=(%.2f,_,%.2f) lat_signed=%.2f"
		% [kb.global_position, f2, bp2.x, bp2.y, bp2.z, side2.x, side2.z, lat2])
	get_tree().quit(0)
