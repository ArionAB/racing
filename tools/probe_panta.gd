extends Node
## Cat de ABRUPT e malul sapaturii. O prapastie citita ca prapastie are nevoie
## de o fata, nu de o panta lina: sonda masoara panta maxima pe transecte care
## traverseaza malul, in conul privirii.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var space := t.get_world_3d().direct_space_state
	# transecte peste malul canionului din fata (de la drum spre nord)
	print("transect | panta maxima (grade) | cadere totala | pe ce distanta")
	for tr in [
		{"n": "0.13 -> nord", "x0": 60.0, "z0": 60.0, "dx": 0.55, "dz": 0.83},
		{"n": "0.16 -> nord", "x0": 120.0, "z0": 55.0, "dx": 0.45, "dz": 0.89},
		{"n": "0.16 -> est ", "x0": 150.0, "z0": 90.0, "dx": 0.90, "dz": 0.44},
	]:
		var prev := 0.0
		var first := true
		var mx := 0.0
		var hi := -1e9
		var lo := 1e9
		var step := 4.0
		for k in 40:
			var d := float(k) * step
			var qx: float = float(tr["x0"]) + float(tr["dx"]) * d
			var qz: float = float(tr["z0"]) + float(tr["dz"]) * d
			var ry := PhysicsRayQueryParameters3D.create(
				Vector3(qx, 300.0, qz), Vector3(qx, -300.0, qz))
			var hh := space.intersect_ray(ry)
			if not hh:
				continue
			var y: float = hh["position"].y
			hi = maxf(hi, y)
			lo = minf(lo, y)
			if not first:
				var slope := rad_to_deg(atan2(absf(y - prev), step))
				mx = maxf(mx, slope)
			prev = y
			first = false
		print("%-12s |  %5.1f grade  |  %5.1f m  |  pas de %.0f m" % [tr["n"], mx, hi - lo, step])
	get_tree().quit(0)
