extends SceneTree
## Scrie axa soselei pe un interval de fractie, pentru piese de Blender care
## trebuie sa urmeze drumul real (grota de pe Ha Long: tunelul e sapat de-a
## lungul axei, nu pe o dreapta presupusa).
##
##   godot --headless --path . --script res://tools/dump_road_span.gd -- \
##       --track=22 --from=0.27 --to=0.37 --out=tools/data/halong_grotto_axis.json
##
## JSON: {"points": [[x,y,z,half_width,side_x,side_z,frac], ...]} in coordonate
## de LUME Godot (Y sus). Latura e `_side_at(i)` (dreapta pe sensul de mers).

var _track: Node = null
var _frames: int = 0
var _from: float = 0.0
var _to: float = 1.0
var _out: String = ""


func _initialize() -> void:
	var n := 22
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			n = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--from="):
			_from = float(arg.trim_prefix("--from="))
		elif arg.begins_with("--to="):
			_to = float(arg.trim_prefix("--to="))
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_track = (load("res://scenes/tracks/Track%02d.tscn" % n) as PackedScene).instantiate()
	root.add_child(_track)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	var baked: PackedVector3Array = _track.get("baked")
	var pts: Array = []
	for i in baked.size():
		var f: float = _track.call("frac_at", i)
		if f < _from or f > _to:
			continue
		var side: Vector3 = _track.call("_side_at", i)
		var hw: float = _track.call("width_at_index", i)
		var p := baked[i]
		pts.append([p.x, p.y, p.z, hw, side.x, side.z, f])
	var txt := JSON.stringify({"points": pts})
	if _out != "":
		var fa := FileAccess.open(_out, FileAccess.WRITE)
		fa.store_string(txt)
		fa.close()
	print("dump_road_span: %d puncte, frac %.3f-%.3f" % [pts.size(), _from, _to])
	quit(0)
	return true
