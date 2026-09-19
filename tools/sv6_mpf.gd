extends Node
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var x0 := -232.0; var x1 := -148.0; var z0 := -126.0; var z1 := -107.0
	var n := _track.baked.size()
	print("CAROSABIL IN AMPRENTA x[%.0f,%.0f] z[%.0f,%.0f]:" % [x0,x1,z0,z1])
	var lo := INF
	var cnt := 0
	for i in n:
		var p := _track.baked[i]
		var sd := _track._side_at(i)
		var half := _track.width_at_index(i)
		for lat: float in [-half, -half*0.5, 0.0, half*0.5, half]:
			var q := p + sd * lat
			if q.x >= x0 and q.x <= x1 and q.z >= z0 and q.z <= z1:
				if cnt < 20:
					print("  frac=%.4f lat=%+.1f pos=(%.1f,%.1f,%.1f)" % [float(i)/float(n), lat, q.x, p.y, q.z])
				lo = minf(lo, p.y)
				cnt += 1
	print("TOTAL %d puncte de carosabil in amprenta, cea mai joasa y=%.2f" % [cnt, lo])
	get_tree().quit(0)
