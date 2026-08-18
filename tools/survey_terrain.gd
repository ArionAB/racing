extends SceneTree
## Topografia marginii drumului, fractie cu fractie: unde e malul si cat de
## jos e terenul la +6 si +14 m de umar. Cu cifrele astea se aleg offseturile
## si intervalele specurilor de scenografie — nu din ochi (vederile de sus
## mint despre relief, iar editorul nu are terenul generat la indemana).
##
## E tot ce a ramas din gen_decor_climb.gd dupa ce specurile lui au fost
## promovate in specs (#201, promovare intoarsa in aug 2026 — pana la delivery
## decorul manual sta ca noduri sub DecorManual): partea de MASURA era singura
## cu valoare de unealta; partea de emis .tscn pentru paste manual a murit
## odata cu nodurile pe care le emitea.
##
##   godot --headless --path . --script res://tools/survey_terrain.gd
##   ... -- --track=8 --from=0.48 --to=0.64 --step=0.005

var _track: Node = null
var _frames := 0
var _idx := 8
var _from := 0.0
var _to := 1.0
var _step := 0.01


func _process(_delta: float) -> bool:
	if _track == null:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				_idx = int(a.trim_prefix("--track="))
			elif a.begins_with("--from="):
				_from = float(a.trim_prefix("--from="))
			elif a.begins_with("--to="):
				_to = float(a.trim_prefix("--to="))
			elif a.begins_with("--step="):
				_step = maxf(0.001, float(a.trim_prefix("--step=")))
		var path := "res://scenes/tracks/Track%02d.tscn" % _idx
		if not ResourceLoader.exists(path):
			push_error("survey_terrain: nu exista %s" % path)
			quit(1)
			return true
		_track = (load(path) as PackedScene).instantiate()
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	_scan()
	quit(0)
	return true


func _scan() -> void:
	var sampler: TrackSideSampler = _track._sampler
	var hw := sampler.half_width()
	var sea_y := -1e9
	if "sea_level_offset" in _track:
		sea_y = sampler.mean_road_y() + _track.sea_level_offset
	var path := TrackScenography._Path.new(sampler)
	var f := _from
	while f <= _to:
		var st := path.at(path.total * f)
		var road: Vector3 = st["pos"]
		var line := "f=%.3f  road_y=%5.1f" % [f, road.y]
		for side: float in [-1.0, 1.0]:
			var out: Vector3 = st["right"] * side
			var shore := TrackScenography._shoreline(sampler, road, out,
				hw + 1.0, sea_y)
			var g6 := sampler.ground_y(road.x + out.x * (hw + 6.0),
				road.z + out.z * (hw + 6.0))
			var g14 := sampler.ground_y(road.x + out.x * (hw + 14.0),
				road.z + out.z * (hw + 14.0))
			line += "  | s%+d mal=%5.1f  g+6=%5.1f g+14=%5.1f" \
				% [int(side), shore, g6, g14]
		print(line)
		f += _step
