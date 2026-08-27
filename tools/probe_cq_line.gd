extends Node
## Cota terenului de-a lungul unei linii in plan: pentru cablul telecabinei.
##   -- --a=38,220.5 --b=248,94 --steps=14
func _ready() -> void:
	await get_tree().process_frame
	var a := Vector2(38, 220.5); var b := Vector2(248, 94); var steps := 14
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--a="):
			var s := arg.trim_prefix("--a=").split(","); a = Vector2(float(s[0]), float(s[1]))
		if arg.begins_with("--b="):
			var s := arg.trim_prefix("--b=").split(","); b = Vector2(float(s[0]), float(s[1]))
		if arg.begins_with("--steps="): steps = int(arg.trim_prefix("--steps="))
	var scene := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	print("lungime plan %.1f m" % a.distance_to(b))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		var g := track._sampler.ground_y(p.x, p.y)
		# cel mai apropiat punct de sosea, ca sa stim daca turnul ar fi pe drum
		var bd := INF; var by := 0.0
		for j in r.count():
			var d := Vector2(r.baked[j].x - p.x, r.baked[j].z - p.y).length()
			if d < bd: bd = d; by = r.baked[j].y
		print("t %.2f (%7.1f, %7.1f)  teren %6.2f  sosea la %5.1f m (y %5.1f)" % [
			float(i)/float(steps), p.x, p.y, g, bd, by])
	get_tree().quit()
