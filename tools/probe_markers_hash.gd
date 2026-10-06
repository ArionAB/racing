extends SceneTree
## Numara si hash-uieste stalpii de bordura (RoadMarker) si chevron-urile unei piste
## (regresie pentru `markers_skip_water`).
##   godot --headless --path . --script res://tools/probe_markers_hash.gd -- --track=1
var _t: Node
var _f := 0
func _process(_d: float) -> bool:
	if _t == null:
		var idx := 1
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				idx = int(a.trim_prefix("--track="))
		_t = (load("res://scenes/tracks/Track%02d.tscn" % idx) as PackedScene).instantiate()
		root.add_child(_t)
		return false
	_f += 1
	if _f < 3:
		return false
	var mk := PackedStringArray()
	var ch := PackedStringArray()
	var wet := 0
	for c in _t.get_children():
		if c is RoadMarker:
			var p := (c as Node3D).global_position
			mk.append("%.0f,%.0f" % [p.x, p.z])
		elif c.get_class() == "Node3D" and c.find_child("Chevron*", true, false) != null:
			var p := (c as Node3D).global_position
			ch.append("%.0f,%.0f" % [p.x, p.z])
	print("MARKERS %d hash %s | CHEVRONS %d hash %s" % [mk.size(), "|".join(mk).md5_text().substr(0, 10),
		ch.size(), "|".join(ch).md5_text().substr(0, 10)])
	quit(0)
	return true
