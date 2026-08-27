extends Node
## Unde e soseaua PLANA si DREAPTA pe +-R metri? Pentru module de hazard care
## isi aduc propriul tablier orizontal si drept (pasajul rotativ).
func _ready() -> void:
	await get_tree().process_frame
	var R := 70.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--reach="): R = float(a.trim_prefix("--reach="))
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var L := r.length()
	print("reach +-%.0f m — se cauta: dy_total < 0.6 si lat < 1.5" % R)
	var f := 0.0
	while f < 1.0:
		var i := int(round(f * float(n))) % n
		var c := r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		fwd.y = 0.0
		fwd = fwd.normalized()
		var sidev := Vector3(fwd.z, 0.0, -fwd.x)
		var lat := 0.0
		var ylo := INF
		var yhi := -INF
		var d := -R
		while d <= R:
			var idx := ((i + int(round(d / L * float(n)))) % n + n) % n
			var p := r.baked[idx]
			lat = maxf(lat, absf((p - c).dot(sidev)))
			ylo = minf(ylo, p.y)
			yhi = maxf(yhi, p.y)
			d += 2.0
		if yhi - ylo < 0.85 and lat < 2.5:
			print("  frac %.3f  y %.2f  dy_total %.2f  lat %.2f" % [f, c.y, yhi - ylo, lat])
		f += 0.002
	get_tree().quit()
