extends Node
## Cotele reale pe DREAPTA, ca sa nu mai filtrez din ochi: generatorul a
## respins 90% din pozitii cu un prag de 9 m ales fara sa masor.


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
	print("frac | cota_drum | dY la 30/50/70/90/110 m dreapta")
	var f := 0.575
	while f <= 0.681:
		var p: Vector3 = curve.sample_baked(L * f)
		var ah: Vector3 = curve.sample_baked(fmod(L * f + 8.0, L))
		var right := (ah - p).normalized().cross(Vector3.UP).normalized()
		var line := "%.3f | %6.2f |" % [f, p.y]
		for off in [30.0, 50.0, 70.0, 90.0, 110.0]:
			var y := _g(space, p + right * off)
			line += ("  %+7.2f" % (y - p.y)) if not is_nan(y) else "    n/a "
		print(line)
		f += 0.012
	get_tree().quit()


func _g(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 300.0, p.z), Vector3(p.x, -80.0, p.z))
	var h := space.intersect_ray(q)
	return (h["position"] as Vector3).y if h.has("position") else NAN
