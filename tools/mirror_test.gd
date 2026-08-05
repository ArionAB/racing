extends Node
## Sonda temporara: Godot 4.7 inverseaza singur winding-ul pentru instantele cu
## determinant negativ (scale.x = -1)?
##
##   godot --path . res://tools/MirrorTest.tscn
##
## Doua quad-uri cu material CULL_BACK: unul normal, unul oglindit pe X.
## Daca cel oglindit ramane vizibil -> Godot flip-uieste singur, iar materialul
## geaman CULL_FRONT din Palette e un al doilea flip (deci greseala).

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

	var normal := MeshInstance3D.new()
	normal.mesh = quad
	normal.material_override = mat
	normal.position = Vector3(-1.0, 0.0, 0.0)
	add_child(normal)

	var mirrored := MeshInstance3D.new()
	mirrored.mesh = quad
	mirrored.material_override = mat
	mirrored.position = Vector3(1.0, 0.0, 0.0)
	mirrored.scale = Vector3(-1.0, 1.0, 1.0)
	add_child(mirrored)

	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.0, 0.0, 3.0)
	cam.current = true

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var w := img.get_width()
	var h := img.get_height()
	# Centrele celor doua quad-uri, proiectate: stanga si dreapta de centru.
	var left := img.get_pixel(int(w * 0.5) - int(w * 0.5 * 0.30), int(h * 0.5))
	var right := img.get_pixel(int(w * 0.5) + int(w * 0.5 * 0.30), int(h * 0.5))
	print("NORMAL(CULL_BACK)   = ", left)
	print("MIRRORED(CULL_BACK) = ", right)
	print("CONCLUZIE: Godot flip-uieste singur winding-ul = ", right.r > 0.5)
	get_tree().quit()
