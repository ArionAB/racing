extends Node
## Fumul si urmele de drift urmeaza ALUNECAREA, nu butonul (feel_checklist:
## drift-snap, partea vizuala).
##
## Verifica, pe Car real:
##   1. functia pura `slide_amount_for`: 40 de grade > 15 de grade la aceeasi
##      viteza, viteza mare > viteza mica, sub 4 grade ~ 0;
##   2. la 15 vs 40 de grade (masina asezata cu botul rotit fata de viteza):
##      fractia de pufuri vizibile, opacitatea lor si marimea cresc, iar
##      urma de cauciuc e mai opaca;
##   3. un drift REAL cu handbrake: pe masura ce unghiul creste de la intrare,
##      densitatea fumului creste cu el (corelatie pozitiva);
##   4. fara handbrake: o alunecare mare aprinde fumul si lasa urme; mersul
##      drept nu; franarea tare cu masina in viteza lasa urma, rularea libera
##      nu;
##   5. plafonul de 160 de urme ramane.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDriftSmoke.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	var drift: bool = false
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return drift


func _ready() -> void:
	add_child(_box(Vector3(1200, 1, 1200), Vector3(0, -0.5, 0)))
	await get_tree().physics_frame
	print("")
	print("=== Fum si urme de drift dupa alunecare ===")
	_test_function()
	await _test_fixed_angles()
	await _test_real_drift()
	await _test_no_handbrake()
	await _test_cap()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	return b


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(pos: Vector3, parent: Node3D = null) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	car.race_active = true
	if parent != null:
		car.skid_parent = parent
	return car


func _settle(car: Car) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


func _test_function() -> void:
	print("")
	print("-- 1. functia pura --")
	var a15 := Car.slide_amount_for(15.0, 20.0)
	var a40 := Car.slide_amount_for(40.0, 20.0)
	var slow := Car.slide_amount_for(40.0, 5.0)
	print("  15 grade %.2f, 40 grade %.2f (la 20 m/s); 40 grade la 5 m/s %.2f; 2 grade %.2f"
		% [a15, a40, slow, Car.slide_amount_for(2.0, 20.0)])
	_check(a40 > a15 + 0.4, "40 de grade cu mult peste 15")
	_check(slow < a40 * 0.5, "viteza mica taie alunecarea")
	_check(Car.slide_amount_for(2.0, 20.0) < 0.02, "sub 4 grade e zgomot")


## Seteaza masina sa alunece la `deg` grade fata de viteza si citeste
## parametrii efectelor dupa un pas de efecte.
func _at_angle(deg: float, speed: float) -> Dictionary:
	var marks := Node3D.new()
	add_child(marks)
	var car := _spawn(Vector3(300, 0.7, 300), marks)
	await _settle(car)
	# Botul rotit cu `deg` fata de directia de mers (-Z).
	car.rotation.y = deg_to_rad(deg)
	car.linear_velocity = Vector3(0, 0, -speed)
	car.is_drifting = true
	for _i in 30: # netezirea lui slide_amount ajunge la tinta
		car._update_slide(STEP)
	car._update_drift_smoke()
	var d: Gradient = car._drift_density
	var out := {
		"slip": car.slip_angle_deg, "slide": car.slide_amount,
		"visible": d.get_offset(1), "alpha": d.get_color(0).a,
		"size": (car._drift_particles as CPUParticles3D).scale_amount_max,
		"mark": car._skid_mark_strength(STEP)}
	# Urma efectiva: transparenta instantei depuse.
	car._skid_accum = 99.0
	car._drop_skid_marks(STEP, out.mark)
	out["mark_transp"] = (marks.get_child(0) as MeshInstance3D).transparency \
		if marks.get_child_count() > 0 else 1.0
	car.queue_free()
	marks.queue_free()
	await get_tree().physics_frame
	return out


func _test_fixed_angles() -> void:
	print("")
	print("-- 2. 15 vs 40 de grade la 20 m/s --")
	var lo := await _at_angle(15.0, 20.0)
	var hi := await _at_angle(40.0, 20.0)
	for pair in [["15", lo], ["40", hi]]:
		var o: Dictionary = pair[1]
		print("  %s grade: unghi masurat %.1f, alunecare %.2f, pufuri vizibile %.0f%%, opacitate x%.2f, marime max %.2f, urma %.2f (transparenta %.2f)"
			% [pair[0], o.slip, o.slide, 100.0 * o.visible, o.alpha, o.size, o.mark, o.mark_transp])
	_check(absf(lo.slip - 15.0) < 2.0 and absf(hi.slip - 40.0) < 2.0, "unghiul masurat corespunde celui impus")
	_check(hi.visible > lo.visible + 0.25, "mai multe pufuri vizibile la 40 decat la 15")
	_check(hi.alpha > lo.alpha + 0.1, "pufurile sunt mai opace la 40")
	_check(hi.size > lo.size * 1.15, "pufurile sunt mai mari la 40")
	_check(hi.mark > lo.mark + 0.2 and hi.mark_transp < lo.mark_transp - 0.1, "urma e mai opaca la 40")


func _test_real_drift() -> void:
	print("")
	print("-- 3. drift real cu handbrake: densitatea urmareste unghiul --")
	var marks := Node3D.new()
	add_child(marks)
	var car := _spawn(Vector3(-300, 0.7, -300), marks)
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	await _settle(car)
	drv.throttle = 1.0
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
	drv.steer = 1.0
	drv.drift = true
	var xs: Array[float] = []
	var ys: Array[float] = []
	var max_slip := 0.0
	var emit_frames := 0
	var low_n := 0
	var low_sum := 0.0
	var high_n := 0
	var high_sum := 0.0
	for _f in int(4.0 / STEP):
		await get_tree().physics_frame
		if not car.is_drifting:
			continue
		if (car._drift_particles as CPUParticles3D).emitting:
			emit_frames += 1
		var vis: float = (car._drift_density as Gradient).get_offset(1)
		xs.append(car.slip_angle_deg)
		ys.append(vis)
		max_slip = maxf(max_slip, car.slip_angle_deg)
		if car.slip_angle_deg < 14.0:
			low_n += 1
			low_sum += vis
		elif car.slip_angle_deg > 22.0:
			high_n += 1
			high_sum += vis
	var corr := _correlation(xs, ys)
	print("  %d cadre de drift, unghi maxim %.1f grade, emite %d cadre; corelatie unghi/densitate %.2f"
		% [xs.size(), max_slip, emit_frames, corr])
	if low_n > 0 and high_n > 0:
		print("  pufuri vizibile: %.0f%% sub 14 grade (%d cadre), %.0f%% peste 22 (%d cadre)"
			% [100.0 * low_sum / low_n, low_n, 100.0 * high_sum / high_n, high_n])
	_check(xs.size() > 60 and emit_frames == xs.size(), "fumul emite tot timpul cat dureaza driftul")
	_check(corr > 0.5, "densitatea creste cu unghiul de derapaj (corelatie > 0.5)")
	_check(high_n > 5 and low_n > 5 and high_sum / maxf(high_n, 1) > low_sum / maxf(low_n, 1) + 0.15,
		"pufuri mai multe la unghi mare decat la unghi mic")
	# Opacitatea urmelor depuse variaza cu alunecarea (nu toate la fel).
	var tmin := 1.0
	var tmax := 0.0
	for m in marks.get_children():
		var t := (m as MeshInstance3D).transparency
		tmin = minf(tmin, t)
		tmax = maxf(tmax, t)
	print("  %d urme depuse, transparenta %.2f .. %.2f" % [marks.get_child_count(), tmin, tmax])
	_check(marks.get_child_count() >= 4 and tmax - tmin > 0.15, "urmele au opacitati diferite pe parcursul driftului")
	car.queue_free()
	marks.queue_free()
	await get_tree().physics_frame


func _correlation(xs: Array[float], ys: Array[float]) -> float:
	var n := xs.size()
	if n < 3:
		return 0.0
	var mx := 0.0
	var my := 0.0
	for i in n:
		mx += xs[i]
		my += ys[i]
	mx /= n
	my /= n
	var sxy := 0.0
	var sxx := 0.0
	var syy := 0.0
	for i in n:
		sxy += (xs[i] - mx) * (ys[i] - my)
		sxx += (xs[i] - mx) * (xs[i] - mx)
		syy += (ys[i] - my) * (ys[i] - my)
	return sxy / sqrt(maxf(sxx * syy, 1e-9))


func _test_no_handbrake() -> void:
	print("")
	print("-- 4. fara handbrake: alunecare mare si franare tare --")
	# Alunecare mare, fara handbrake: fum + urma.
	var marks := Node3D.new()
	add_child(marks)
	var car := _spawn(Vector3(300, 0.7, -300), marks)
	await _settle(car)
	car.rotation.y = deg_to_rad(35.0)
	car.linear_velocity = Vector3(0, 0, -22)
	for _i in 30:
		car._update_slide(STEP)
	var big_strength := car._skid_mark_strength(STEP)
	print("  35 grade fara handbrake: alunecare %.2f, urma %.2f" % [car.slide_amount, big_strength])
	_check(not car.is_drifting and car.slide_amount >= Car.SMOKE_FREE_SLIDE and big_strength > 0.3,
		"alunecarea mare fara handbrake lasa urma")
	# Alunecare mica: nimic.
	car.rotation.y = deg_to_rad(5.0)
	for _i in 40:
		car._update_slide(STEP)
	var small_strength := car._skid_mark_strength(STEP)
	print("  5 grade: alunecare %.2f, urma %.2f" % [car.slide_amount, small_strength])
	_check(small_strength == 0.0, "alunecare mica fara handbrake: nicio urma")
	car.queue_free()
	await get_tree().physics_frame

	# Franare tare REALA vs rulare libera.
	var brake_marks := 0
	var coast_marks := 0
	for mode in ["brake", "coast"]:
		var mk := Node3D.new()
		add_child(mk)
		var c := _spawn(Vector3(-300, 0.7, 300), mk)
		var drv := ScriptDriver.new()
		c.set_controller(drv)
		await _settle(c)
		c.rotation.y = 0.0
		c.linear_velocity = Vector3(0, 0, -26)
		drv.throttle = -1.0 if mode == "brake" else 0.0
		for _f in int(1.2 / STEP):
			await get_tree().physics_frame
		var n := mk.get_child_count()
		print("  %s de la 26 m/s: viteza finala %.1f m/s, %d urme" % [mode, c.horizontal_speed(), n])
		if mode == "brake":
			brake_marks = n
		else:
			coast_marks = n
		c.queue_free()
		mk.queue_free()
		await get_tree().physics_frame
	_check(brake_marks >= 2, "franarea tare in viteza lasa urme")
	_check(coast_marks == 0, "rularea libera nu lasa urme")
	# Mers drept cu acceleratie: nimic.
	var mk2 := Node3D.new()
	add_child(mk2)
	var c2 := _spawn(Vector3(0, 0.7, 500), mk2)
	var drv2 := ScriptDriver.new()
	c2.set_controller(drv2)
	await _settle(c2)
	drv2.throttle = 1.0
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
	print("  acceleratie dreapta 3 s: %d urme, fum emite=%s" % [mk2.get_child_count(),
		(c2._drift_particles as CPUParticles3D).emitting])
	_check(mk2.get_child_count() == 0 and not (c2._drift_particles as CPUParticles3D).emitting,
		"mersul drept nu lasa urme si nu face fum")
	c2.queue_free()
	mk2.queue_free()
	await get_tree().physics_frame


func _test_cap() -> void:
	print("")
	print("-- 5. plafonul de 160 de urme --")
	var marks := Node3D.new()
	add_child(marks)
	var car := _spawn(Vector3(600, 0.7, 0), marks)
	await _settle(car)
	car.linear_velocity = Vector3(0, 0, -10)
	for _i in 200:
		car._skid_accum = 99.0
		car._drop_skid_marks(STEP, 0.7)
	print("  dupa 200 de depuneri: %d urme" % marks.get_child_count())
	_check(marks.get_child_count() <= 160, "plafon 160 pastrat")
	car.queue_free()
	marks.queue_free()
	await get_tree().physics_frame
