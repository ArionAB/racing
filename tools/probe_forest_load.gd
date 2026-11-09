extends SceneTree
## Timpul de incarcare al unei piste cu MeshForest, pe faze (padurea se construieste amanat,
## deci sonda asteapta semnalul `built`). Cere FEREASTRA (nu --headless).
##   godot --rendering-driver vulkan --path . --script res://tools/probe_forest_load.gd -- --track=24 [--passes=2] [--dump]
## --dump: scrie pe fiecare MultiMesh numarul de instante, mesh-ul si un checksum al transformarilor
## (dovada de identitate A/B intre doua versiuni de cod).
var _idx: int = 24
var _passes: int = 2
var _dump: bool = false
var _tag: String = ""
var _pass: int = 0
var _track: Node = null
var _t0: int = 0
var _forest: MeshForest = null
var _t_add: int = 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_idx = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--passes="):
			_passes = int(arg.trim_prefix("--passes="))
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg == "--dump":
			_dump = true

func _process(_d: float) -> bool:
	if _forest != null:
		if not _forest.done:
			return false
		var total := Time.get_ticks_msec() - _t0
		print("FORESTLOAD pass=%d add_child=%d ms, padure %s, total pana la gata=%d ms, MM=%d" % [
			_pass, _t_add, _forest.phase_ms, total, _forest.get_child_count()])
		if _dump:
			_dump_forest(_forest)
		root.remove_child(_track)
		_track.free()
		_track = null
		_forest = null
		_pass += 1
		return false
	if _pass >= _passes:
		return true
	_t0 = Time.get_ticks_msec()
	_track = (load("res://scenes/tracks/Track%02d.tscn" % _idx) as PackedScene).instantiate()
	root.add_child(_track)
	_t_add = Time.get_ticks_msec() - _t0
	for c in _track.find_children("*", "MeshForest", true, false):
		_forest = c
		break
	if _forest == null:
		print("FORESTLOAD: nicio MeshForest")
		return true
	return false

func _dump_forest(f: MeshForest) -> void:
	var lines: PackedStringArray = []
	var tot := 0
	for c in f.get_children():
		var m := c as MultiMeshInstance3D
		var mm := m.multimesh
		var h := 0
		var sx := 0.0
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			sx += t.origin.x + 2.0 * t.origin.y + 3.0 * t.origin.z + t.basis.x.x + 5.0 * t.basis.y.y + 7.0 * t.basis.z.x
		var mesh := mm.mesh as ArrayMesh
		lines.append("%s n=%d tris_surf=%d aabb=%s vb=%.2f..%.2f cs=%.4f" % [m.name, mm.instance_count,
			mesh.get_surface_count(), str(m.custom_aabb), m.visibility_range_begin, m.visibility_range_end, sx])
		tot += mm.instance_count
	lines.sort()
	var fa := FileAccess.open("user://forest_dump_%d_%s_%d.txt" % [_idx, _tag, OS.get_process_id()], FileAccess.WRITE)
	fa.store_string("\n".join(lines) + "\ntotal=%d\n" % tot)
	print("FORESTDUMP %s %d MM, %d inst" % [fa.get_path_absolute(), lines.size(), tot])
