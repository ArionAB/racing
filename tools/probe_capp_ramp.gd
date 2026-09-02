extends Node
## Masoara RAMPA hornului cazut asa cum o vede FIZICA, nu cum o descrie
## fisierul .py din Blender: exportul aplica bevel si recentrare, deci formula
## din generator nu mai e adevarata pe GLB.
##
## Metoda: se instantiaza doar GLB-ul, i se face un colizor trimesh, si se
## trage o raza in jos la fiecare 0.5 m pe lungimea lui. Ce raspunde raza E
## suprafata pe care va calca roata.

const MODEL := "res://assets/models/cappadocia/rocks/cracked_chimney_b.glb"


func _ready() -> void:
	await get_tree().process_frame
	var scene := load(MODEL) as PackedScene
	var model := scene.instantiate() as Node3D
	get_tree().root.add_child(model)

	var body := StaticBody3D.new()
	for entry in TrackDecor.visible_meshes(model, Transform3D.IDENTITY):
		var mi: MeshInstance3D = entry[0]
		var xf: Transform3D = entry[1]
		if mi.mesh == null:
			continue
		var faces := mi.mesh.create_trimesh_shape().get_faces()
		var moved := PackedVector3Array()
		moved.resize(faces.size())
		for i in faces.size():
			moved[i] = xf * faces[i]
		var cshape := ConcavePolygonShape3D.new()
		cshape.set_faces(moved)
		var cs := CollisionShape3D.new()
		cs.shape = cshape
		body.add_child(cs)
	get_tree().root.add_child(body)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space := get_tree().root.world_3d.direct_space_state
	print("x      | suprafata la z = -1.5 / 0.0 / +1.5 (raza in jos de la y=12)")
	var x := -11.0
	while x <= 11.01:
		var row := "%6.2f |" % x
		for z: float in [-1.5, 0.0, 1.5]:
			var q := PhysicsRayQueryParameters3D.create(
				Vector3(x, 12.0, z), Vector3(x, -3.0, z))
			var hit := space.intersect_ray(q)
			row += ("  %6.2f" % float(hit["position"].y)) if hit else "     --"
		print(row)
		x += 0.5
	get_tree().quit(0)
