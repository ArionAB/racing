extends Node3D
## Cota terenului la x/z-ul lui Fill003, masurata cu ACELASI raycast pe care il
## foloseste generatorul, ca sa vad daca sonda si generatorul vad lumi diferite.


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := get_world_3d().direct_space_state
	var n := track.find_child("Fill003", true, false) as Node3D
	var p := n.global_position
	print("")
	print("Fill003 global: %.2f %.2f %.2f" % [p.x, p.y, p.z])
	for h in [240.0, 100.0, 30.0, 5.0]:
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, p.y + h, p.z), Vector3(p.x, p.y - 240.0, p.z))
		var hit := space.intersect_ray(q)
		if hit.has("position"):
			var hp: Vector3 = hit["position"]
			print("  de la +%6.1f: teren %.2f  (colider %s)" % [h, hp.y, (hit["collider"] as Node).name])
		else:
			print("  de la +%6.1f: nimic" % h)
	get_tree().quit()
