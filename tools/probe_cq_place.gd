extends Node
## Sonda de lucru pentru asezarea decorului POI E-G pe Chongqing.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCqPlace.tscn -- --from=0.44 --to=1.0 --step=0.005

func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(12)
	var f0 := 0.44
	var f1 := 1.0
	var st := 0.01
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="): f0 = float(arg.trim_prefix("--from="))
		if arg.begins_with("--to="): f1 = float(arg.trim_prefix("--to="))
		if arg.begins_with("--step="): st = float(arg.trim_prefix("--step="))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	print("lungime %.1f m, %d puncte" % [r.length(), n])
	print("frac    i     x       y       z      hdg    hw   |  gL20  gR20  gL60  gR60")
	var f := f0
	while f <= f1 + 1e-6:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var side := track._side_at(i)
		var fwd := r.baked[(i + 1) % n] - p
		var hdg := rad_to_deg(atan2(fwd.x, fwd.z))
		var hw := track.width_at_index(i)
		var g := ""
		for m: float in [20.0, 60.0]:
			var gl := track._sampler.ground_y(p.x - side.x * m, p.z - side.z * m)
			var gr := track._sampler.ground_y(p.x + side.x * m, p.z + side.z * m)
			g += "  %6.1f %6.1f" % [gl, gr]
		print("%.3f %4d %8.2f %7.2f %8.2f %7.1f %5.1f |%s   side(%.3f,%.3f)" % [
			r.frac_at(i), i, p.x, p.y, p.z, hdg, hw, g, side.x, side.z])
		f += st
	get_tree().quit()
