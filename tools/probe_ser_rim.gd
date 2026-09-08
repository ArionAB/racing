extends Node3D
## Cat de departe e drumul de un inel de puncte in jurul lagunei.
## Un varf de buza pus prea aproape de asfalt il ingroapa (memoria
## `carosabil-ingropat-garda`), deci raza si pozitia se aleg pe masuratoare.

const LAKE := Vector2(-55, -30)

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/tracks/Track14.tscn")
	var track: Track = scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	print("=== inel in jurul lagunei: cota terenului si distanta pana la drum ===")
	print("  azimut  raza   punct(x,z)      teren_y   dist_drum")
	for az: int in [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]:
		for r: float in [110.0, 140.0]:
			var a := deg_to_rad(float(az))
			var x := LAKE.x + cos(a) * r
			var z := LAKE.y + sin(a) * r
			var q := PhysicsRayQueryParameters3D.create(
				Vector3(x, 400.0, z), Vector3(x, -400.0, z))
			var hit := space.intersect_ray(q)
			var y := 0.0
			if not hit.is_empty():
				y = (hit["position"] as Vector3).y
			var best := 9999.0
			for p: Vector3 in track.baked:
				best = minf(best, Vector2(p.x - x, p.z - z).length())
			print("   %3d   %5.0f  (%5.0f,%5.0f)  %7.2f   %6.1f m" % [az, r, x, z, y, best])
	get_tree().quit()
