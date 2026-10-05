extends SceneTree
## Timpul de generare a pistei (instantiate + add_child, sincron), CU fereastra
## (citirile de pe GPU din _prop_foot_radius conteaza). Trei treceri: prima e
## "la rece", urmatoarele cu cache-ul de resurse cald.
##   godot --rendering-driver vulkan --path . --script res://tools/probe_load_time.gd -- --track=19
var _idx: int = 12
var _pass: int = 0
var _track: Node = null
var _times: Array[float] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_idx = int(arg.trim_prefix("--track="))

func _process(_d: float) -> bool:
	if _track != null:
		root.remove_child(_track)
		_track.free()
		_track = null
	if _pass >= 3:
		print("LOADTIME track=%d  s: %s" % [_idx, ", ".join(_times.map(func(t): return "%.2f" % t))])

		return true
	var path := "res://scenes/tracks/Track%02d.tscn" % _idx
	var t0 := Time.get_ticks_msec()
	_track = (load(path) as PackedScene).instantiate()
	root.add_child(_track)
	_times.append((Time.get_ticks_msec() - t0) / 1000.0)
	_pass += 1
	return false
