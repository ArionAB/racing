extends Node
## Care parte e STANGA in imagine? Semnul se DEDUCE, nu se ghiceste: se compara
## normala cu directia camerei, exact cum o construieste Snapshot (--driver).

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	for fi in [44, 48, 52]:
		var f := float(fi) / 100.0
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 12) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		# Camera priveste pe `d`. In spatiul ei, +X e DREAPTA ecranului.
		# Godot: basis.x = -basis.z.cross(Vector3.UP) pentru o privire pe -Z.
		var cam_right := d.cross(Vector3.UP).normalized()
		var side_v := Vector3(d.z, 0.0, -d.x)
		var dotp := cam_right.dot(side_v)
		var gplus: float = track._sampler.ground_y(p.x + side_v.x * 20.0, p.z + side_v.z * 20.0)
		var gminus: float = track._sampler.ground_y(p.x - side_v.x * 20.0, p.z - side_v.z * 20.0)
		print("frac %.2f road_y %.1f | side_v e %s ecranului (dot %+.2f) | ground +20: %.1f  -20: %.1f" % [
			f, p.y, ("DREAPTA" if dotp > 0.0 else "STANGA"), dotp, gplus, gminus])
	get_tree().quit(0)
