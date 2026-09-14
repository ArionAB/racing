extends RefCounted
## Uneltele comune ale sondelor tehnice Machu Picchu (tools/probe_machu.gd):
## masina condusa de script, asteptari pe cadre, verdicte. Sta intr-un fisier
## separat ca testele (A podul, B treptele, C terasele, D autobuzul) sa poata
## fi scrise de agenti diferiti fara sa se calce pe acelasi fisier.

const STEP: float = 1.0 / 60.0

var root: Node
var failed: bool = false
var checks: int = 0


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _init(owner: Node) -> void:
	root = owner


func check(ok: bool, what: String) -> void:
	checks += 1
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		failed = true


## Masina cu botul spre -Z, tinuta la `speed` de guvernator (throttle 1 +
## plafon), ca sa masuram efectul hazardului, nu al acceleratiei. speed 0 =
## parcata (throttle 0).
func spawn(pos: Vector3, factor: float, speed: float) -> Car:
	var car := Car.new()
	car.mass_factor = factor
	root.add_child(car)
	car.global_position = pos
	car.race_active = true
	var drv := ScriptDriver.new()
	drv.throttle = 1.0 if speed > 0.0 else 0.0
	car.set_controller(drv)
	car.speed_limit_factor = speed / car.max_speed
	car.linear_velocity = Vector3(0, 0, -speed)
	return car


func driver(car: Car) -> ScriptDriver:
	return car.controller as ScriptDriver


func wait(seconds: float) -> void:
	for _f in int(seconds / STEP):
		await root.get_tree().physics_frame


func free_cars(cars: Array) -> void:
	for c in cars:
		if c != null and is_instance_valid(c):
			(c as Node).queue_free()
	await root.get_tree().physics_frame


## O placa statica cu fata de sus la y = `top`.
func slab(size: Vector3, center_top: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = Palette.world_material()
	body.add_child(mi)
	root.add_child(body)
	body.global_position = center_top - Vector3(0.0, size.y * 0.5, 0.0)
	return body
