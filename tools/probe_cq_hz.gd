extends Node
## Transformarile nodurilor de hazard pe Track12: pozitie + yaw la o fractie.
##   -- --fracs=0.497,0.750,0.845,0.885
func _ready() -> void:
	await get_tree().process_frame
	var fracs: Array[float] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fracs="):
			for s in arg.trim_prefix("--fracs=").split(","): fracs.append(float(s))
	var scene := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	for f in fracs:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p).normalized()
		# Hazardele isi construiesc geometria pe -Z local = sensul de mers.
		var yaw := atan2(-fwd.x, -fwd.z)
		var c := cos(yaw); var s := sin(yaw)
		var side := track._side_at(i)
		print("frac %.4f  hw %.1f  pos(%.3f, %.3f, %.3f) yaw %.2f deg  fwd(%.3f,%.3f)" % [
			f, track.width_at_index(i), p.x, p.y, p.z, rad_to_deg(yaw), fwd.x, fwd.z])
		print("  transform = Transform3D(%f, 0, %f, 0, 1, 0, %f, 0, %f, %f, %f, %f)" % [
			c, -s, s, c, p.x, p.y, p.z])
		print("  side(%.3f,%.3f)  panta %.1f%%" % [side.x, side.z, fwd.y / maxf(Vector2(fwd.x,fwd.z).length(),0.01) * 100.0])
	get_tree().quit()
