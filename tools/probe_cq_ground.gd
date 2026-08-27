extends Node
## Cota terenului la offset-uri laterale in dreptul unei fractii.
##   -- --fracs=0.47,0.50 --offs=-30,-20,-12,-8,8,12,20,30,50
func _ready() -> void:
	await get_tree().process_frame
	var fracs: Array[float] = []
	var offs: Array[float] = [-30.0,-20.0,-12.0,-9.0,9.0,12.0,20.0,30.0,50.0]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fracs="):
			for s in arg.trim_prefix("--fracs=").split(","): fracs.append(float(s))
		if arg.begins_with("--offs="):
			offs = []
			for s in arg.trim_prefix("--offs=").split(","): offs.append(float(s))
	var scene := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var hdr := "frac    road_y |"
	for o in offs: hdr += " %7.0f" % o
	print(hdr)
	for f in fracs:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var side := track._side_at(i)
		var line := "%.3f %6.2f |" % [f, p.y]
		for o in offs:
			line += " %7.2f" % track._sampler.ground_y(p.x + side.x * o, p.z + side.z * o)
		print(line + "   pos(%.1f,%.1f,%.1f) side(%.3f,%.3f)" % [p.x,p.y,p.z,side.x,side.z])
	get_tree().quit()
