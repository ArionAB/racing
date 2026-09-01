extends Node
## Linia unde malul din DREAPTA drumului iese din plat, pe portiunea 0.56-0.66.
## Grohotisul trebuie sa INGROAPE imbinarea aia — deci intai o masor, pe
## perpendiculara la traseu, in fata masinii, nu lateral pe harta.


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var curve := track.get_node("Path").curve as Curve3D
	var L := curve.get_baked_length()
	var space := track.get_world_3d().direct_space_state
	print("")
	print("frac | latura | dist_de_ax | cota_drum | cota_mal | panta")
	var f := 0.555
	while f <= 0.665:
		var p: Vector3 = curve.sample_baked(L * f)
		var ahead: Vector3 = curve.sample_baked(fmod(L * f + 8.0, L))
		var fwd := (ahead - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		for side_name in ["DR", "ST"]:
			var s: float = 1.0 if side_name == "DR" else -1.0
			var prev := p.y
			var toe := -1.0
			var toe_y := 0.0
			var d := 8.0
			while d <= 70.0:
				var q := p + right * (s * d)
				var y := _ground(space, q)
				if is_nan(y):
					d += 2.0
					continue
				if toe < 0.0 and (y - p.y) > 2.5:
					toe = d
					toe_y = y
				prev = y
				d += 2.0
			var slope := 0.0 if toe < 0.0 else (toe_y - p.y) / toe
			print("%.3f | %s | %5.1f | %6.2f | %6.2f | %.2f  punct(%.1f, %.1f)"
				% [f, side_name, toe, p.y, toe_y, slope,
				   p.x + right.x * s * toe, p.z + right.z * s * toe])
			prev = prev
		f += 0.01
	get_tree().quit()


func _ground(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 300.0, p.z), Vector3(p.x, -60.0, p.z))
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3).y if hit.has("position") else NAN
