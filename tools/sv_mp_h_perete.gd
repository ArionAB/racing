extends Node
## Profilul lateral pe partea PERETELUI (+side, -X) in jurul portii:
## mai exista faleza dupa poarta, sau drumul a iesit in platou?
func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var t := ps.instantiate()
	add_child(t)
	await get_tree().process_frame
	var tr := t as Track
	var n := tr.baked.size()
	var space := get_viewport().world_3d.direct_space_state
	print("frac | sosea |  +8m   +15m   +25m   +40m   (partea PERETELUI, -X)")
	for ff in [0.9280, 0.9400, 0.9500, 0.9577, 0.9640, 0.9703, 0.9800, 0.9900]:
		var i := int(ff * float(n)) % n
		var p: Vector3 = tr.baked[i]
		var side: Vector3 = tr._side_at(i)
		# partea peretelui: cea pe care solul URCA
		var line := "%.4f | %5.1f |" % [ff, p.y]
		for lat in [8.0, 15.0, 25.0, 40.0]:
			var q: Vector3 = p + side * lat
			var par := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 400.0, q.z), Vector3(q.x, p.y - 400.0, q.z))
			var hit := space.intersect_ray(par)
			var y := NAN
			if hit and hit.has("collider") and String(hit.collider.name).contains("Terrain"):
				y = hit.position.y - p.y
			line += " %6.1f" % y
		print(line)
	get_tree().quit()
