extends SceneTree
## SONDA (cu fereastra + lacatul GPU): cata granulatie a stratului de detaliu
## poarta fiecare caroserie, pe materialul lumii asa cum e livrat.
##
##   godot --path . --resolution 1600x700 --script res://tools/probe_car_grain.gd -- --out=<dir>
##
## Masinile stau in rand sub acelasi soare. Se randeaza de doua ori: cu
## `Palette.world_material()` (livrat) si cu `Palette.plain_material()` (acelasi
## material, stratul de detaliu oprit). Diferenta dintre cele doua cadre E
## granulatia — media |diferentei| de luminanta pe pixelii masinii, per masina.
## Iese <out>/cars_world.png, <out>/cars_plain.png si tabelul.

const CARS: Array[String] = ["muscle", "taxi", "hotrod", "ambulance", "police_sports", "bus"]
const STEP := 6.5

var _out := "user://"
var _frames := 0
var _cars: Array[Node3D] = []
var _cam: Camera3D
var _world_img: Image


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.9
	world.add_child(sun)
	sun.look_at_from_position(Vector3(4, 10, 6), Vector3.ZERO, Vector3.UP)
	for i in CARS.size():
		var data := load("res://scenes/cars/data/%s.tres" % CARS[i])
		var inst := (data.model as PackedScene).instantiate() as Node3D
		world.add_child(inst)
		inst.scale = Vector3.ONE * data.model_scale
		inst.rotation_degrees = Vector3(0, data.model_rotation_deg + 35.0, 0)
		inst.position = Vector3(i * STEP, 0, 0)
		Palette.apply_world_material(inst)
		_cars.append(inst)
	_cam = Camera3D.new()
	world.add_child(_cam)
	var cx := (CARS.size() - 1) * STEP * 0.5
	_cam.fov = 30.0
	_cam.look_at_from_position(Vector3(cx, 8, 36), Vector3(cx, 0.8, 0), Vector3.UP)
	_cam.current = true


func _set_mat(mat: Material) -> void:
	for car in _cars:
		var stack: Array[Node] = [car]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			stack.append_array(n.get_children())
			if n is MeshInstance3D:
				(n as MeshInstance3D).material_override = mat


func _lum(c: Color) -> float:
	return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0


func _process(_d: float) -> bool:
	_frames += 1
	if _frames == 10:
		_world_img = root.get_texture().get_image()
		_world_img.save_png(_out.path_join("cars_world.png"))
		_set_mat(Palette.plain_material())
		return false
	if _frames < 20:
		return false
	var plain := root.get_texture().get_image()
	plain.save_png(_out.path_join("cars_plain.png"))
	var w := plain.get_width()
	var bg := plain.get_pixel(1, 1)
	print("masina          granulatie (media |world - plain|, luminanta 0..255)   pixeli")
	for i in CARS.size():
		# Fasia ecranului care contine masina: intre mijloacele vecinilor.
		var cx := _cam.unproject_position(_cars[i].global_position).x * w / root.get_visible_rect().size.x
		var half := (_cam.unproject_position(Vector3(STEP, 0, 0)).x
				- _cam.unproject_position(Vector3.ZERO).x) * 0.5 * w / root.get_visible_rect().size.x
		var s := 0.0
		var n := 0
		for y in plain.get_height():
			for x in range(int(maxf(cx - half, 0)), int(minf(cx + half, w))):
				var p := plain.get_pixel(x, y)
				if absf(p.r - bg.r) + absf(p.g - bg.g) + absf(p.b - bg.b) < 0.02:
					continue
				s += absf(_lum(_world_img.get_pixel(x, y)) - _lum(p))
				n += 1
		print("%-15s %6.2f   %d" % [CARS[i], s / maxi(n, 1), n])
	return true
