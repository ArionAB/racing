extends Node

func _ready() -> void:
	await get_tree().process_frame
	var glb := load("res://assets/models/serengeti/animals/elephant.glb") as PackedScene
	var inst := glb.instantiate() as Node3D
	get_tree().root.add_child(inst)
	await get_tree().process_frame

	# Camera looking from +X toward -X (side view), positioned to see the
	# whole elephant, with the model's own -Z axis (computed "forward")
	# pointing to the LEFT of frame if my dot-product reasoning is right.
	var cam := Camera3D.new()
	get_tree().root.add_child(cam)
	cam.position = Vector3(10, 3, 0)
	cam.look_at(Vector3(0, 2, 0), Vector3.UP)
	cam.current = true

	var sun := DirectionalLight3D.new()
	get_tree().root.add_child(sun)
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.2

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.6, 0.55, 0.5)
	env.environment = e
	get_tree().root.add_child(env)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var out := ProjectSettings.globalize_path("res://snapshots/elephant_side_check.png")
	img.save_png(out)
	print("saved: ", out)
	print("model -Z (computed forward): ", -inst.global_transform.basis.z)
	get_tree().quit()
