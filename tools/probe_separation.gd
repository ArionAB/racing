extends Node
## Impulsul de separare intre masini (reteta SuperTuxKart, urmarea lui
## ProbeContactSteer): contactul sustinut nu are voie sa LIPEASCA masinile.
##
## Dupa ce directia a devenit imuna la contact (#299), doua masini pe aceeasi
## linie ramaneau lipite si macinau una in alta ("collision deadlock" in
## devlogul STK): yaw-ul e scris direct de directie, deci solverul n-are cum
## sa le roteasca una de pe linia celeilalte, iar alta forta de despartire nu
## exista. Impulsul de separare e forta aia: laterala, centrala (fara
## rotatie), scalata cu raportul maselor si cu cat de "alaturi" e contactul.
##
## Trei masuratori:
##   1. identitatea prin masa: autobuz si sport umar la umar -> sportul e
##      maturat vizibil, autobuzul abia se clinteste;
##   2. plutonul bara-n bara ramane pluton: separarea nu arunca lateral
##      coada de masini aliniate (impingerea din spate e mecanica legitima);
##   3. impinsul deliberat e rasplatit, nu pedepsit: te apleci pe un rival,
##      il muti vizibil de pe linie, si NU-ti pierzi viteza facand-o.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSeparation.tscn

const STEP: float = 1.0 / 60.0
## Sportul (0.9) impins de autobuz (2.6): raportul deplasarilor laterale.
## Tinta teoretica e raportul maselor (~2.9); cerem macar atat, cu marja.
const MIN_MASS_RATIO: float = 1.8
## Cat trebuie sa fie maturat sportul de autobuz ca impingerea sa se VADA (m).
const MIN_SWEPT_M: float = 1.5
## Cat are voie sa se strambe lateral coada bara-n bara (m).
const MAX_QUEUE_DRIFT_M: float = 0.8
## Cat trebuie sa muti rivalul cand te apleci deliberat pe el (m).
const MIN_SHOVE_M: float = 1.2
## Viteza minima pastrata de cel care impinge (m/s, din ~15 initial):
## in STK, sistemul vechi era "realist dar nedistractiv" fiindca initiatorul
## pierdea viteza — al nostru nu are voie sa repete greseala.
const MIN_PUSHER_SPEED: float = 11.0

var _failed: bool = false


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


func _ready() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(900, 1, 900)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame

	print("")
	print("=== Impulsul de separare intre masini ===")
	await _test_mass_identity()
	await _test_queue_stays_queue()
	await _test_deliberate_shove()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _spawn(pos: Vector3, factor: float) -> Car:
	var car := Car.new()
	car.mass_factor = factor
	add_child(car)
	car.global_position = pos
	car.race_active = true
	car.set_controller(ScriptDriver.new())
	return car


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _settle(cars: Array[Car]) -> void:
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	for car in cars:
		car.linear_velocity = Vector3.ZERO


# ------------------------------------------------------------------ testele

func _test_mass_identity() -> void:
	print("")
	print("-- 1. aplecare sustinuta: usoara e maturata, grea abia se clinteste --")
	# Aceeasi apasare, in ambele sensuri: cat muta autobuzul sportul, si cat
	# poate sportul sa mute autobuzul. Raportul e identitatea prin masa.
	var by_bus := await _lean_swept(2.6, 0.9)
	var by_sport := await _lean_swept(0.9, 2.6)
	var ratio := by_bus / maxf(by_sport, 0.001)
	print("  autobuzul muta sportul %.2f m; sportul muta autobuzul %.2f m -> raport %.1f"
		% [by_bus, by_sport, ratio])
	_check(by_bus >= MIN_SWEPT_M,
		"autobuzul chiar matura sportul (>= %.1f m)" % MIN_SWEPT_M)
	_check(ratio >= MIN_MASS_RATIO,
		"identitatea prin masa: greul muta usorul de >= %.1fx mai mult" % MIN_MASS_RATIO)


## O "aplecare" de 2 s: pusher-ul tine volanul usor spre victima (umar in
## umar, nu izbitura). Intoarce cat a fost maturata victima lateral (m).
func _lean_swept(pusher_factor: float, victim_factor: float) -> float:
	var pusher := _spawn(Vector3(0, 0.7, 0), pusher_factor)
	var victim := _spawn(Vector3(2.3, 0.7, 0), victim_factor)
	await _settle([pusher, victim])
	pusher.linear_velocity = Vector3(0, 0, -15)
	victim.linear_velocity = Vector3(0, 0, -15)
	(pusher.controller as ScriptDriver).throttle = 0.6
	(victim.controller as ScriptDriver).throttle = 0.6
	(pusher.controller as ScriptDriver).steer = -0.15
	for _f in int(2.0 / STEP):
		await get_tree().physics_frame
	var swept := victim.global_position.x - 2.3
	pusher.queue_free()
	victim.queue_free()
	await get_tree().physics_frame
	return swept


func _test_queue_stays_queue() -> void:
	print("")
	print("-- 2. bara-n bara: plutonul ramane pluton, nu e aruncat lateral --")
	var front := _spawn(Vector3(0, 0.7, 0), 1.0)
	var rear := _spawn(Vector3(0.1, 0.7, 4.2), 1.0)
	await _settle([front, rear])
	front.linear_velocity = Vector3(0, 0, -15)
	rear.linear_velocity = Vector3(0, 0, -15)
	(front.controller as ScriptDriver).throttle = 0.5
	(rear.controller as ScriptDriver).throttle = 1.0
	for _f in int(2.5 / STEP):
		await get_tree().physics_frame
	var drift := absf(rear.global_position.x - front.global_position.x - 0.1)
	var front_speed := front.horizontal_speed()
	var rear_speed := rear.horizontal_speed()
	print("  strambare laterala %.2f m; viteze: fata %.1f, spate %.1f m/s"
		% [drift, front_speed, rear_speed])
	_check(drift <= MAX_QUEUE_DRIFT_M,
		"coada aliniata nu e azvarlita lateral (<= %.1f m)" % MAX_QUEUE_DRIFT_M)
	_check(front_speed >= rear_speed - 2.0,
		"impingerea din spate impinge (fata tinuta la viteza cozii)")
	front.queue_free()
	rear.queue_free()
	await get_tree().physics_frame


func _test_deliberate_shove() -> void:
	print("")
	print("-- 3. te apleci pe rival: il muti de pe linie, fara sa fii pedepsit --")
	var pusher := _spawn(Vector3(0, 0.7, 0), 1.0)
	var victim := _spawn(Vector3(2.3, 0.7, 0), 1.0)
	await _settle([pusher, victim])
	pusher.linear_velocity = Vector3(0, 0, -15)
	victim.linear_velocity = Vector3(0, 0, -15)
	(pusher.controller as ScriptDriver).throttle = 0.6
	(victim.controller as ScriptDriver).throttle = 0.6
	# Volan tinut usor SPRE rival (steer negativ = spre +X), ca o depasire
	# cu umarul: nu izbitura, apasare sustinuta.
	(pusher.controller as ScriptDriver).steer = -0.15
	for _f in int(2.0 / STEP):
		await get_tree().physics_frame
	var shoved := victim.global_position.x - 2.3
	var pusher_speed := pusher.horizontal_speed()
	print("  rivalul mutat %.2f m; viteza impingatorului %.1f m/s (din ~15)"
		% [shoved, pusher_speed])
	_check(shoved >= MIN_SHOVE_M,
		"apasarea sustinuta chiar muta rivalul (>= %.1f m)" % MIN_SHOVE_M)
	_check(pusher_speed >= MIN_PUSHER_SPEED,
		"impingatorul nu e pedepsit cu viteza (>= %.0f m/s)" % MIN_PUSHER_SPEED)
	pusher.queue_free()
	victim.queue_free()
	await get_tree().physics_frame
