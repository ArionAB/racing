extends Node
## Taietura laterala tiparita ca profil, la fractiile cerute. Nu da verdict:
## e ochelarii cu care se citeste forma pamantului inainte si dupa o sapatura.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var track := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().physics_frame
	var s: TrackSideSampler = track.get("_sampler")
	var route := track.route_at(0)
	var n := route.count()
	var fracs: Array[float] = [0.045, 0.09, 0.13, 0.25, 0.30]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fracs="):
			fracs.clear()
			for t in arg.substr(8).split(","):
				fracs.append(float(t))
	for f in fracs:
		var idx := int(round(f * float(n))) % n
		var axis: Vector3 = route.baked[idx]
		var side := route.side_at(idx)
		print("--- frac %.3f  axa y=%.2f  (x=%.1f z=%.1f) ---"
			% [f, axis.y, axis.x, axis.z])
		var line := ""
		var ds: Array = []
		var fine := false
		for a in OS.get_cmdline_user_args():
			if a == "--fine":
				fine = true
		if fine:
			var q := -40.0
			while q <= 40.0:
				ds.append(q)
				q += 1.0
		else:
			ds = [-60.0, -40.0, -30.0, -20.0, -14.0, -10.0, -8.0, -6.0, 0.0,
				6.0, 8.0, 10.0, 14.0, 20.0, 30.0, 40.0, 60.0]
		for d in ds:
			var y := s.ground_y(axis.x + side.x * d, axis.z + side.z * d)
			line += "%+d:%+.1f " % [int(d), y - axis.y]
		print("   " + line)
	get_tree().quit(0)
