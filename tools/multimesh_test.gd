extends Node
## Godot compenseaza determinantul negativ si pentru instantele dintr-un
## MultiMesh, sau doar pentru MeshInstance3D?
##
## Trei quad-uri CULL_BACK: unul MeshInstance3D oglindit (etalonul din
## MirrorTest) si doua intr-un MultiMesh — normal si oglindit.

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 1.0
	env.environment = e
	add_child(env)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)

	var single := MeshInstance3D.new()
	single.mesh = quad
	single.material_override = mat
	single.position = Vector3(-2.0, 0.0, 0.0)
	single.scale = Vector3(-1.0, 1.0, 1.0)
	add_child(single)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = 2
	mm.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0, 0, 0)))
	mm.set_instance_transform(1, Transform3D(
		Basis.IDENTITY.scaled(Vector3(-1.0, 1.0, 1.0)), Vector3(2, 0, 0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)

	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.0, 0.0, 5.0)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var w := img.get_width()
	var h := img.get_height()
	var y := int(h * 0.5)
	var px := func(world_x: float) -> Color:
		var p := cam.unproject_position(Vector3(world_x, 0.0, 0.0))
		return img.get_pixel(clampi(int(p.x), 0, w - 1), y)
	print("MeshInstance oglindit = ", px.call(-2.0))
	print("MultiMesh normal      = ", px.call(0.0))
	print("MultiMesh oglindit    = ", px.call(2.0))
	get_tree().quit()
