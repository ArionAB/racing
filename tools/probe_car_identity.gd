extends Node
## Identitatea prin suspensie (#260): masinile trebuie sa se SIMTA diferit, si
## diferenta trebuie sa fie masurabila, nu doar declarata in .tres.
##
## Testul: fiecare masina din garaj face acelasi viraj sustinut, la ACEEASI
## viteza (plafonata prin speed_limit_factor, altfel sportiva ar vira mai
## repede si ruliul n-ar fi comparabil). Se masoara:
##   1. compresia statica proprie cade in 25-50% din cursa EI (arcul lucreaza
##      pe fiecare set de valori, nu doar pe cel implicit);
##   2. ruliul maxim in viraj, ORDONAT dupa moliciunea suspensiei:
##      autobuz > pompieri > taxi > muscle > politia — alegerea masinii =
##      alegerea stilului (principiul 4), acum si in caroserie;
##   3. autobuzul se leagana de cel putin 1.4x cat sportiva — diferenta care
##      se VEDE, nu una de zecimi de grad;
##   4. nimeni nu se rastoarna.
##
## Tot aici, costul de calcul: 6 masini simultan (cate incap pe grila),
## masurat cu ceasul de perete per tick de fizica — in headless cu
## --fixed-fps totul ruleaza cat de repede poate, deci timpul intre doua
## tick-uri e chiar costul de calcul al unui cadru, fara randare.
## (Performance.TIME_PHYSICS_PROCESS raporteaza 0 in headless — prima
## versiune a sondei "trecea" cu 0.00 ms, adica nu masura nimic.)
## Cifra e informativa + alarma generoasa; validarea reala e pe device (M4).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarIdentity.tscn

const STEP: float = 1.0 / 60.0
## Viteza comuna de viraj (m/s) — sub vmax-ul tuturor.
const CORNER_SPEED: float = 24.0
## Alarma pe costul de fizica per cadru, headless (ms). Generoasa: pragul
## real e 60fps pe device; asta prinde doar o regresie de ordin de marime.
const PHYSICS_MS_ALARM: float = 8.0

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
	box.size = Vector3(600, 1, 600)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame

	print("")
	print("=== Identitatea prin suspensie (acelasi viraj, %d m/s) ==="
		% int(CORNER_SPEED))
	print("%-14s %6s %8s %10s %10s"
		% ["masina", "f(Hz)", "comp_st", "ruliu_max", "rasturnat"])

	# Ordinea asteptata a ruliului: de la cea mai moale la cea mai teapana.
	var order := [3, 4, 2, 0, 1] # Autobuz, Pompierii, Taxi, Muscle, Politia
	var rolls: Array[float] = []
	var names: Array[String] = []
	for idx: int in order:
		var data := GameState.CAR_DATA[idx] as CarData
		var r := await _measure(data)
		rolls.append(float(r.roll))
		names.append(data.display_name)
		var comp_ok: bool = float(r.comp) >= 0.25 and float(r.comp) <= 0.50
		if not comp_ok or bool(r.flipped):
			_failed = true
		print("%-14s %6.1f %6.0f%% %9.1f° %10s%s"
			% [data.display_name, data.spring_freq, float(r.comp) * 100.0,
				float(r.roll), "DA" if r.flipped else "nu",
				"" if comp_ok else "   <-- compresie in afara 25-50%"])

	# Ordinea: fiecare treapta are voie o egalitate practica (5%), dar nu
	# inversare — altfel identitatea din .tres e doar decor.
	var ordered := true
	for i in rolls.size() - 1:
		if rolls[i] < rolls[i + 1] * 0.95:
			ordered = false
			print("  [PICAT] %s (%.1f°) se leagana mai putin decat %s (%.1f°)"
				% [names[i], rolls[i], names[i + 1], rolls[i + 1]])
	_check(ordered, "ruliul urmeaza moliciunea (autobuz > ... > politia)")
	_check(rolls[0] >= rolls[rolls.size() - 1] * 1.4,
		"autobuzul se leagana >= 1.4x cat sportiva (%.1f° vs %.1f°)"
			% [rolls[0], rolls[rolls.size() - 1]])

	await _bench_six_cars()

	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


## Costul unui cadru cu grila plina: 6 masini conducand simultan, ceas de
## perete intre tick-uri de fizica.
func _bench_six_cars() -> void:
	var lineup := [0, 1, 2, 3, 4, 3] # garajul + al doilea autobuz (ca in joc)
	var cars: Array[Car] = []
	for i in lineup.size():
		var car := Car.new()
		add_child(car)
		car.global_position = Vector3(-20.0 + 8.0 * float(i), 0.7, 100)
		car.apply_data(GameState.CAR_DATA[lineup[i]] as CarData)
		car.set_controller(ScriptDriver.new())
		car.race_active = true
		(car.controller as ScriptDriver).throttle = 1.0
		cars.append(car)
	for _f in int(1.0 / STEP): # asezare + pornire, in afara masuratorii
		await get_tree().physics_frame
	var sum_us := 0
	var max_us := 0
	var samples := 0
	var prev := Time.get_ticks_usec()
	for _f in int(5.0 / STEP):
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		var dt := int(now - prev)
		prev = now
		sum_us += dt
		max_us = maxi(max_us, dt)
		samples += 1
	for car in cars:
		car.queue_free()
	await get_tree().physics_frame
	var avg_ms := float(sum_us) / maxf(float(samples), 1.0) / 1000.0
	print("")
	print("cost per cadru cu 6 masini (headless, fara randare):")
	print("  mediu %.2f ms, varf %.2f ms (alarma la %.1f ms)"
		% [avg_ms, float(max_us) / 1000.0, PHYSICS_MS_ALARM])
	_check(avg_ms < PHYSICS_MS_ALARM, "costul de calcul sub pragul de alarma")


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _measure(data: CarData) -> Dictionary:
	var car := Car.new()
	add_child(car)
	car.global_position = Vector3(0, 0.7, 100)
	car.apply_data(data)
	car.set_controller(ScriptDriver.new())
	car.race_active = true
	# Viteza comuna: plafonul individual e adus la CORNER_SPEED.
	car.speed_limit_factor = CORNER_SPEED / data.max_speed

	# Asezare + compresia statica pe cursa PROPRIE.
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	var comp_frac := 0.0
	for compression in car.wheel_compression:
		comp_frac += float(compression)
	comp_frac /= 4.0 * car.suspension_rest

	# Prinde viteza, apoi viraj sustinut; ruliul se masoara dupa transient.
	(car.controller as ScriptDriver).throttle = 1.0
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
	(car.controller as ScriptDriver).steer = 1.0
	var max_roll := 0.0
	var flipped := false
	for f in int(4.0 / STEP):
		await get_tree().physics_frame
		if f < int(1.0 / STEP):
			continue # transientul intrarii in viraj nu e regim
		var up := car.global_transform.basis.y
		var tilt := rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
		max_roll = maxf(max_roll, tilt)
		if up.dot(Vector3.UP) < 0.5:
			flipped = true

	car.queue_free()
	await get_tree().physics_frame
	return {"comp": comp_frac, "roll": max_roll, "flipped": flipped}


