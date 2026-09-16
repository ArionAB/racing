extends Node
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _track.baked.size()
	for q: Vector2 in [Vector2(-190,-112), Vector2(-190,-118), Vector2(-210,-118), Vector2(-170,-118), Vector2(-230,-120), Vector2(-160,-118)]:
		var best := 1e9
		var bi := -1
		for i in n:
			var p := _track.baked[i]
			var d := Vector2(p.x - q.x, p.z - q.y).length()
			if d < best: best = d; bi = i
		var pb := _track.baked[bi]
		print("q=(%.0f,%.0f) cel mai aproape frac=%.4f ax=(%.1f,%.1f,y=%.1f) half=%.1f dist_ax=%.1f dist_margine=%.1f" % [q.x, q.y, float(bi)/float(n), pb.x, pb.y, pb.z, _track.width_at_index(bi), best, best - _track.width_at_index(bi)])
	get_tree().quit(0)
