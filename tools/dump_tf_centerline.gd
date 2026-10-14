extends SceneTree
## Scrie axa soselei Transfagarasan (x, z, semilatime) in CSV, pentru
## `tools/rarire_tf.py` (rarirea stolurilor de padure dupa distanta de drum).
##   godot --headless --path . --script res://tools/dump_tf_centerline.gd
var _t: Node = null

func _process(_d: float) -> bool:
	if _t == null:
		_t = (load("res://scenes/tracks/Track21.tscn") as PackedScene).instantiate()
		root.add_child(_t)
		return false
	var t := _t
	var s: Object = t.get("_sampler")
	var f := FileAccess.open("res://tools/data/tf_rarire/centerline.csv", FileAccess.WRITE)
	f.store_line("x,z,half_width")
	for i in s.point_count():
		var p: Vector3 = s.baked_point(i)
		f.store_line("%.3f,%.3f,%.3f" % [p.x, p.z, s.half_width_at(i)])
	f.close()
	print("CENTERLINE ", s.point_count())
	return true
