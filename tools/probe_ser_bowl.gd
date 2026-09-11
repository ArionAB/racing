extends Node3D
## Profilul craterului: e vas sau farfurie?
##
## Criticul de ansamblu: "craterul nu se citeste ca un vas — buza inalta,
## perete interior in umbra, fund luminos". Se masoara ca RELIEF (cote pe o
## transversala prin centrul lagunei) plus contrastul buza/fund pe captura —
## nu ca procent de culoare (memoria `procent-de-culoare-nu-e-dovada`).

const LAKE := Vector2(-55, -30)

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/tracks/Track14.tscn")
	var track: Node3D = scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state

	print("=== profil prin centrul lagunei (%.0f, %.0f) ===" % [LAKE.x, LAKE.y])
	for axis: String in ["X", "Z"]:
		print("  --- transversala pe %s ---" % axis)
		var lo := 999.0
		var hi := -999.0
		for d: float in [-220.0, -180.0, -150.0, -120.0, -100.0, -80.0, -60.0,
				-40.0, -20.0, 0.0, 20.0, 40.0, 60.0, 80.0, 100.0, 120.0,
				150.0, 180.0, 220.0]:
			var p := Vector3(LAKE.x, 0, LAKE.y)
			if axis == "X":
				p.x += d
			else:
				p.z += d
			var q := PhysicsRayQueryParameters3D.create(
				p + Vector3.UP * 400.0, p + Vector3.DOWN * 400.0)
			var hit := space.intersect_ray(q)
			var y := 0.0
			var what := "(nimic)"
			if not hit.is_empty():
				y = (hit["position"] as Vector3).y
				what = str((hit["collider"] as Node).name)
				lo = minf(lo, y)
				hi = maxf(hi, y)
			print("    d=%+5.0f m   y=%7.2f   %s" % [d, y, what])
		print("    -> amplitudine %.1f m (min %.1f, max %.1f)" % [hi - lo, lo, hi])
	get_tree().quit()
