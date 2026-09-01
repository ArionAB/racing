extends Node
## Unde e IMBINAREA reala perete-teren, ca sa nu asez grohotisul din ochi.
##
## Criticul: "talpa peretelui e o curba desenata cu rigla". Ca sa o ingrop,
## am nevoie de linia unde panta masivului se domoleste — nu de centrul
## Marker3D-ului. Merg pe raze din centrul masivului si raportez, pe fiecare,
## raza la care panta terenului scade sub prag (piciorul pantei).

const CENTER := Vector3(-160.0, 0.0, -70.0)


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var space := track.get_world_3d().direct_space_state
	print("")
	print("=== piciorul pantei MasivulDeTuf (centru %.0f,%.0f) ===" % [CENTER.x, CENTER.z])
	for deg in [90, 105, 120, 135, 150, 165, 180]:
		var a := deg_to_rad(float(deg))
		var dir := Vector3(cos(a), 0.0, sin(a))
		var prev_y := NAN
		var foot_r := -1.0
		var foot_y := 0.0
		for i in range(20, 210, 2):
			var r := float(i)
			var p := CENTER + dir * r
			var y := _ground(space, p)
			if is_nan(y):
				continue
			if not is_nan(prev_y):
				var slope: float = (prev_y - y) / 2.0
				if slope < 0.06 and foot_r < 0.0 and r > 40.0:
					foot_r = r
					foot_y = y
			prev_y = y
		print("  azimut %3d: picior la raza %6.1f m, cota %6.2f  -> punct (%.1f, %.1f)"
			% [deg, foot_r, foot_y, CENTER.x + dir.x * foot_r, CENTER.z + dir.z * foot_r])
	get_tree().quit()


func _ground(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 300.0, p.z), Vector3(p.x, -60.0, p.z))
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3).y if hit.has("position") else NAN
