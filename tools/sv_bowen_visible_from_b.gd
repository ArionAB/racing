extends Node
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track
func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _t.baked.size()
	var bowen_pos := Vector3(84.197, 2.550, -94.718)
	for f in [0.15, 0.18, 0.20, 0.22, 0.25]:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var d := bp.distance_to(bowen_pos)
		print("frac=%.2f road=%s dist_to_bowen=%.1f" % [f, bp, d])
	get_tree().quit(0)
