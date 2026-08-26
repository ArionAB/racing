extends Node
## Sonda terasei de sub cornisa (Chongqing D): pe fractiile date, la 20-45 m
## in DREAPTA soselei, terenul trebuie sa fie USCAT (peste apa) si jos (chei).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTerrace.tscn
##   ... -- [--scene=res://scenes/tracks/Track12.tscn] [--f0=0.24] [--f1=0.35]
##          [--lo=4] [--hi=9] [--side=1]

var _fails: int = 0

func _ready() -> void:
	var scene := "res://scenes/tracks/Track12.tscn"
	var f0 := 0.24
	var f1 := 0.35
	var lo := 4.0
	var hi := 9.0
	var side := 1.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--f0="):
			f0 = float(arg.trim_prefix("--f0="))
		elif arg.begins_with("--f1="):
			f1 = float(arg.trim_prefix("--f1="))
		elif arg.begins_with("--lo="):
			lo = float(arg.trim_prefix("--lo="))
		elif arg.begins_with("--hi="):
			hi = float(arg.trim_prefix("--hi="))
		elif arg.begins_with("--side="):
			side = float(arg.trim_prefix("--side="))
	var track: Track = (load(scene) as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	var sampler: TrackSideSampler = track._sampler
	var sea_y: float = sampler.mean_road_y() + track.sea_level_offset
	print("=== ProbeTerrace %s  frac %.2f-%.2f  apa la %.2f m ===" % [
		scene, f0, f1, sea_y])
	var n := track.baked.size()
	var offsets := [14.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 55.0, 65.0, 80.0]
	var header := "  frac   drum"
	for o in offsets:
		header += "  %5dm" % int(o)
	print(header + "   apa de la")
	var f := f0
	while f <= f1 + 0.0001:
		var i := int(f * float(n)) % n
		var p: Vector3 = track.baked[i]
		var s: Vector3 = track._side_at(i) * side
		var line := "  %.3f  %5.1f" % [f, p.y]
		var water_at := -1.0
		var bad := false
		for o in offsets:
			var y: float = sampler.ground_y(p.x + s.x * o, p.z + s.z * o)
			line += "  %6.1f" % y
			if y < sea_y and water_at < 0.0:
				water_at = o
			if o >= 20.0 and o <= 45.0 and (y < lo or y > hi):
				bad = true
		line += "   %s" % ("%.0f m" % water_at if water_at > 0.0 else "-")
		if bad:
			line += "   <-- in afara [%.0f, %.0f]" % [lo, hi]
			_fails += 1
		print(line)
		f += 0.01
	print("VERDICT: %s (%d fractii in afara benzii)" % [
		"OK" if _fails == 0 else "PICAT", _fails])
	get_tree().quit(1 if _fails > 0 else 0)
