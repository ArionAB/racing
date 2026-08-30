extends Node
## Cote de teren la coordonate cerute: --at=x,z;x,z;...
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
func _ready() -> void:
	var track := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().physics_frame
	var s: TrackSideSampler = track.get("_sampler")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			for pair in arg.substr(5).split(";"):
				var c := pair.split(",")
				var x := float(c[0])
				var z := float(c[1])
				print("  (%.1f, %.1f)  y=%.2f" % [x, z, s.ground_y(x, z)])
	get_tree().quit(0)
