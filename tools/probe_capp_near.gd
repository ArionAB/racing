extends Node
## Care sunt FETELE cele mai apropiate de punctul in care se opresc masinile
## (-278, 19.6, 20)? Se citesc toate corpurile cu trimesh si se raporteaza cea
## mai mica distanta de la punct la un vertex, plus cati vertecsi sunt in raza
## de 3 m. Asa se vede daca `Shoulders` chiar e acolo sau doar raspunde larg.
const TARGET := Vector3(-278.0, 19.6, 20.0)


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame

	print("corp                  min_dist  vertecsi_in_3m")
	for child in track.get_children():
		if not (child is StaticBody3D):
			continue
		for gc in child.get_children():
			var cs := gc as CollisionShape3D
			if cs == null or not (cs.shape is ConcavePolygonShape3D):
				continue
			var faces := (cs.shape as ConcavePolygonShape3D).get_faces()
			var xf := (child as Node3D).global_transform * cs.transform
			var best := 1e9
			var near := 0
			for p in faces:
				var d := (xf * p).distance_to(TARGET)
				best = minf(best, d)
				if d < 3.0:
					near += 1
			if best < 60.0:
				print("%-20s  %8.2f  %d" % [String(child.name), best, near])
	get_tree().quit(0)
