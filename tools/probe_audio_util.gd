extends RefCounted
## Unelte comune ale sondelor de sunet al masinii (ProbeEngineVoice, ProbeLiftPops,
## ProbeSlipSqueal, ProbeSurfaceVoice, ProbeTurboSound, ProbeWind). Headless
## foloseste driverul de sunet „dummy": sondele afirma pe STAREA playerelor
## (playing, pitch_scale, volume_db, stream), nu pe ce se aude.

const STEP: float = 1.0 / 60.0


## Comenzi scriptate, in locul touch-ului/AI-ului.
class ScriptCtl:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	var drift: bool = false
	var turbo: bool = false
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return drift
	func is_turbo_pressed() -> bool:
		return turbo


static func ground(parent: Node) -> void:
	var g := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(4000, 1, 4000)
	cs.shape = sh
	g.add_child(cs)
	parent.add_child(g)
	g.global_position = Vector3(0, -0.5, 0)


static func spawn(parent: Node, player: bool, pos: Vector3 = Vector3(0, 0.7, 0)) -> Car:
	var car := Car.new()
	car.is_player = player
	parent.add_child(car)
	car.global_position = pos
	var drv := ScriptCtl.new()
	car.set_controller(drv)
	car.race_active = true
	return car


## Cade pe sol: cateva zeci de cadre dupa spawn, ca rotile sa atinga asfaltul.
static func settle(tree: SceneTree, seconds: float = 0.6) -> void:
	for _f in int(seconds / STEP):
		await tree.physics_frame


static func audio(car: Car) -> Node:
	return car._audio


static func drv(car: Car) -> ScriptCtl:
	return car.controller as ScriptCtl


## Vitezele se pun fata de botul masinii, doar pe orizontala.
static func pin_speed(car: Car, speed: float) -> void:
	var fwd := -car.global_transform.basis.z
	var v := Vector3(fwd.x, 0.0, fwd.z).normalized() * speed
	# Verticala ramane a fizicii: fara ea masina atarna in aer cat o fixam.
	car.linear_velocity = Vector3(v.x, car.linear_velocity.y, v.z)
