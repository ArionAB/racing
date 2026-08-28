extends Node
## Cat de dreapta si cat de urcatoare e soseaua pe o fereastra de N metri,
## pentru fiecare fractie — ca sa alegi unde intra un hazard cu geometrie proprie.
func _ready() -> void:
	await get_tree().process_frame
	var f0 := 0.60; var f1 := 0.90; var win := 70.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="): f0 = float(arg.trim_prefix("--from="))
		if arg.begins_with("--to="): f1 = float(arg.trim_prefix("--to="))
		if arg.begins_with("--win="): win = float(arg.trim_prefix("--win="))
	var scene := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var L := r.length()
	var half := int(win * 0.5 / L * float(n))
	print("fereastra %.0f m (+-%d puncte)" % [win, half])
	print("frac    y     | abatere max de la coarda (m) | panta % | cot total grade")
	var f := f0
	while f <= f1:
		var i := int(round(f * float(n))) % n
		var a := r.baked[(i - half + n) % n]
		var b := r.baked[(i + half) % n]
		var dev := 0.0
		for k in range(-half, half + 1):
			var p := r.baked[(i + k + n) % n]
			var t := (b - a)
			var u := clampf((p - a).dot(t) / t.length_squared(), 0.0, 1.0)
			dev = maxf(dev, Vector2(p.x - (a + t * u).x, p.z - (a + t * u).z).length())
		var slope := (b.y - a.y) / maxf(Vector2(b.x-a.x, b.z-a.z).length(), 0.01) * 100.0
		var h0 := r.baked[(i - half + 1 + n) % n] - a
		var h1 := b - r.baked[(i + half - 1 + n) % n]
		var turn := rad_to_deg(absf(Vector2(h0.x,h0.z).angle_to(Vector2(h1.x,h1.z))))
		print("%.3f %6.1f | %6.2f | %6.1f | %6.1f" % [f, r.baked[i].y, dev, slope, turn])
		f += 0.005
	get_tree().quit()
