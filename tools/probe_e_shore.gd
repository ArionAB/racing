extends Node
## Linia apei pe malul DINSPRE DRUM al lacului de soda (POI E), in coordonate
## de lume: pe raze care pleaca de la centrul lagunei catre camera hero, unde
## trece terenul prin cota apei.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var sea := track.find_child("Sea", true, false) as Node3D
	var wy := sea.global_position.y if sea != null else 0.0
	print("APA y=%.2f" % wy)
	# Centrul lagunei din Track14: poligonul e centrat pe (0,-68)
	var c := Vector2(0.0, -68.0)
	for adeg in range(200, 340, 5):
		var a := deg_to_rad(float(adeg))
		var dirv := Vector2(cos(a), sin(a))
		var prev_below := true
		var line := "az=%d" % adeg
		for step in range(10, 120):
			var d := float(step)
			var o := c + dirv * d
			var q := PhysicsRayQueryParameters3D.create(Vector3(o.x, 120, o.y), Vector3(o.x, -60, o.y))
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var y := float(hit.position.y)
			var below := y < wy
			if prev_below and not below:
				line += "  LINIA_APEI d=%.0f (%.1f,%.1f) y=%.2f" % [d, o.x, o.y, y]
				# si cota la +10 / +25 m dincolo de mal
				for extra in [6, 12, 20, 30, 45]:
					var o2 := c + dirv * (d + float(extra))
					var q2 := PhysicsRayQueryParameters3D.create(Vector3(o2.x, 120, o2.y), Vector3(o2.x, -60, o2.y))
					var h2 := space.intersect_ray(q2)
					line += " +%d:%s" % [extra, ("%.1f" % float(h2.position.y)) if not h2.is_empty() else "--"]
				break
			prev_below = below
		print(line)
	get_tree().quit(0)
