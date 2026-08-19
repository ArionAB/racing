extends Node
## Directia sub CONTACT CONTINUU cu alta masina (bug de feel, aug 2026).
##
## Simptomul raportat la volan: daca o masina te ciocneste din spate sau
## lateral si ramane lipita de tine, abia mai poti vira stanga-dreapta.
##
## Mecanismul: directia scrie angular_velocity.y direct, iar _process_contacts
## preia diferenta "solver - comanda" in _impact_yaw, care se ADUNA peste
## comanda. Intr-un contact sustinut, solverul se opune in FIECARE tick
## rotatiei comandate (corpul celuilalt freaca de al tau), deci diferenta e
## mereu de semn opus comenzii si se acumuleaza pana la plafonul de ±2.4 —
## peste comanda maxima de 1.9. Rezultat: viraj anulat cat tine contactul.
##
## Sonda masoara cat se intoarce masina in 1.2 s de volan la maxim:
##   1. libera (reper);
##   2. impinsa bara-n bara de un autobuz cu acceleratia mai mare;
##   3. regresie: lovitura excentrica DE IZBITURA trebuie sa roteasca in
##      continuare victima (mecanismul _impact_yaw ramane pentru izbituri).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeContactSteer.tscn

const STEP: float = 1.0 / 60.0
## Cat de mult din virajul liber trebuie sa ramana sub impingere. Nu 100%:
## un corp lipit de al tau chiar rezista fizic putin, si e onest sa se simta.
const MIN_PUSHED_RATIO: float = 0.55
## Fractiunea de cadre cu contact in fereastra de impingere, ca scenariul
## sa nu fie gol (masini care nici nu se ating nu masoara nimic). Pragul e
## jos DELIBERAT: pe codul cu bug victima nu putea scapa si contactul tinea
## ~74% din cadre; cu directia functionala victima chiar scapa de urmaritor
## si contactul scade la ~33% — exact efectul dorit, nu un scenariu stricat.
const MIN_CONTACT_FRAC: float = 0.25

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
	print("=== Directia sub contact continuu ===")
	var free_heading := await _test_free_steer()
	await _test_pushed_steer(free_heading)
	await _test_corner_hit_still_rotates()
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


## Volan la maxim `seconds`; intoarce unghiul acumulat (rad, cu semn) si
## fractiunea de cadre in care `victim` atingea alta masina. Daca primeste un
## `chaser`, ii tine volanul indreptat spre victima, cadru de cadru.
func _steer_window(victim: Car, seconds: float, chaser: Car = null) -> Dictionary:
	(victim.controller as ScriptDriver).steer = 1.0
	var heading := 0.0
	var prev := victim.rotation.y
	var contact_frames := 0
	var frames := int(seconds / STEP)
	for _f in frames:
		if chaser != null:
			var to_victim := victim.global_position - chaser.global_position
			to_victim.y = 0.0
			var fwd := -chaser.global_transform.basis.z
			fwd.y = 0.0
			var ang := atan2(fwd.cross(to_victim).y,
				fwd.dot(to_victim))
			(chaser.controller as ScriptDriver).steer = clampf(ang * 2.5, -1.0, 1.0)
		await get_tree().physics_frame
		heading += wrapf(victim.rotation.y - prev, -PI, PI)
		prev = victim.rotation.y
		for body in victim.get_colliding_bodies():
			if body is Car:
				contact_frames += 1
				break
	(victim.controller as ScriptDriver).steer = 0.0
	return {"heading": heading, "contact_frac": contact_frames / float(frames)}


# ------------------------------------------------------------------ testele

func _test_free_steer() -> float:
	print("")
	print("-- 1. reper: viraj liber la 18 m/s --")
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	await _settle([sport])
	sport.linear_velocity = Vector3(0, 0, -18)
	(sport.controller as ScriptDriver).throttle = 0.45
	for _f in int(1.2 / STEP):
		await get_tree().physics_frame
	var r := await _steer_window(sport, 1.2)
	var heading := float(r.heading)
	print("  intoarcere libera: %.0f°" % rad_to_deg(heading))
	_check(heading > deg_to_rad(60.0), "reperul chiar vireaza (> 60°)")
	sport.queue_free()
	await get_tree().physics_frame
	return heading


func _test_pushed_steer(free_heading: float) -> void:
	print("")
	print("-- 2. acelasi viraj, impins bara-n bara de autobuz care urmareste --")
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(0, 0.7, 4.2), 2.6)
	await _settle([sport, bus])
	sport.linear_velocity = Vector3(0, 0, -18)
	bus.linear_velocity = Vector3(0, 0, -18)
	(sport.controller as ScriptDriver).throttle = 0.45
	(bus.controller as ScriptDriver).throttle = 1.0
	# Autobuzul accelereaza mai tare si se lipeste de bara din spate; in
	# fereastra de viraj isi tine volanul SPRE victima, ca in cursa — altfel
	# victima iese de pe linia lui dupa cateva cadre si contactul se rupe.
	for _f in int(1.2 / STEP):
		await get_tree().physics_frame
	var r := await _steer_window(sport, 1.2, bus)
	var heading := float(r.heading)
	var ratio := heading / maxf(free_heading, 0.001)
	print("  intoarcere sub impingere: %.0f° (%.0f%% din reper), contact %.0f%% din cadre, _impact_yaw ramas %.2f"
		% [rad_to_deg(heading), ratio * 100.0,
			float(r.contact_frac) * 100.0, sport._impact_yaw])
	_check(float(r.contact_frac) >= MIN_CONTACT_FRAC,
		"scenariul e valid: contact sustinut in fereastra de viraj")
	_check(ratio >= MIN_PUSHED_RATIO,
		"impins continuu, pastrezi cel putin %d%% din viraj"
			% int(MIN_PUSHED_RATIO * 100.0))
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame


## Regresie: mecanismul _impact_yaw exista ca loviturile excentrice sa te
## roteasca (altfel scrierea directa a yaw-ului le-ar sterge). Gate-ul pe
## dv nu are voie sa-l stinga si pentru izbituri reale.
func _test_corner_hit_still_rotates() -> void:
	print("")
	print("-- 3. regresie: izbitura in colt tot te roteste --")
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(1.3, 0.7, 8), 2.6)
	await _settle([sport, bus])
	var yaw_before := sport.rotation.y
	bus.linear_velocity = Vector3(0, 0, -13)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	var turned := absf(wrapf(sport.rotation.y - yaw_before, -PI, PI))
	print("  rotatie din izbitura: %.0f°" % rad_to_deg(turned))
	_check(turned > deg_to_rad(5.0), "izbitura excentrica chiar roteste (> 5°)")
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame
