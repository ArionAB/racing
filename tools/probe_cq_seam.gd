extends Node
## Imbinarea dintre capatul deck-ului si soseaua reala, pe toata latimea.
## Repunerile cad la z local +34..+47, adica DINCOLO de deck (care se termina
## la 31.9): acolo trebuie sa fie o treapta sau o buza.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var span := track.find_child("PasajRotativ", false, false)
	print("z_local |  x=-6    x=-3     x=0     x=+3    x=+6   | ce e pe axa")
	var z := 50.0
	while z >= 24.0:
		var row := "%+7.1f |" % z
		var who := ""
		for x: float in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			var wp: Vector3 = span.global_transform * Vector3(x, 0.0, z)
			var q := PhysicsRayQueryParameters3D.create(wp + Vector3.UP * 4.0, wp + Vector3.DOWN * 8.0)
			var h := space.intersect_ray(q)
			if h.is_empty():
				row += "   ----"
			else:
				row += " %+6.2f" % (h.position.y - wp.y)
				if x == 0.0:
					who = str(h.collider.name)
		print("%s | %s" % [row, who])
		z -= 1.0
	get_tree().quit()
