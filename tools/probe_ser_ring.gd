extends Node3D
## Inelul de buza in jurul lagunei: cota terenului pe azimut, ca sa se vada
## EXACT pe ce sector lipseste peretele craterului (criticul de ansamblu:
## est/nord-est la +1.7 m fata de +28..+45 m pe vest).

const LAKE := Vector2(-55, -30)

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/tracks/Track14.tscn")
	var track: Node3D = scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	for r: float in [70.0, 100.0, 130.0]:
		print("=== inel r=%.0f m ===" % r)
		for a: int in range(0, 360, 15):
			var rad := deg_to_rad(float(a))
			var p := Vector3(LAKE.x + r * cos(rad), 0.0, LAKE.y + r * sin(rad))
			var q := PhysicsRayQueryParameters3D.create(
				p + Vector3.UP * 500.0, p + Vector3.DOWN * 500.0)
			var hit := space.intersect_ray(q)
			var y := -999.0
			var what := "(nimic)"
			if not hit.is_empty():
				y = (hit["position"] as Vector3).y
				what = str((hit["collider"] as Node).name)
			print("  az=%3d  (%7.1f, %7.1f)  y=%7.2f  %s" % [a, p.x, p.z, y, what])
	get_tree().quit()
