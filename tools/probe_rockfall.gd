extends Node
## Sonda bolovanului rostogolit de pe versant (#242).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRockfall.tscn
##
## Ca SCENA, nu cu --script: hazardele au nevoie de autoload-uri ca sa compileze.
##
## Trei verdicte, cate unul pentru fiecare parte a issue-ului:
##
##   1. VINE DE PE VERSANT. Piatra porneste lateral, nu de pe axa drumului, si
##      ajunge in punctul de impact. Un bolovan care cade vertical n-are sursa
##      vizibila si se citeste ca scripted.
##   2. SE ROSTOGOLESTE. Modelul se roteste in timpul coborarii. Fara asta,
##      piatra ar aluneca peste sosea ca o cutie pe gheata.
##   3. STRIVIREA E PE SPEC. Masina merge cu ~30% mai incet, ramane turtita cu
##      ~30% mai mult decat inainte, si isi revine dupa 3 s. Turtirea se
##      masoara PE MASINA, nu in constante — un `hold_squash` care nu ajunge la
##      `_visual` ar trece orice verificare facuta pe cifre din cod.
##
## Plus non-regresia: fara versant declarat, piatra cade vertical ca inainte.

const PERIOD: float = 5.5


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("=== Sonda bolovan de pe versant ===")
	var failed := false

	# --- 1 + 2: traiectoria si rostogolirea
	var slope := _trace(1.0)
	var flat := _trace(0.0)

	var lateral: float = slope["start_lateral"]
	var lateral_ok := lateral > 3.0
	if not lateral_ok:
		failed = true
	print("\ntraiectorie (cu versant):")
	print("  pornire laterala   -> %.2f m  %s"
			% [lateral, "OK" if lateral_ok else "PROBLEMA (porneste de pe axa)"])
	var landed: float = slope["impact_lateral"]
	var landed_ok := landed < 0.5
	if not landed_ok:
		failed = true
	print("  la impact, lateral -> %.2f m  %s"
			% [landed, "OK" if landed_ok else "PROBLEMA (nu ajunge pe drum)"])
	var spin: float = slope["spin"]
	var spin_ok := spin > 1.0
	if not spin_ok:
		failed = true
	print("  rotatie in coborare-> %.2f rad  %s"
			% [spin, "OK" if spin_ok else "PROBLEMA (aluneca, nu se rostogoleste)"])

	print("\nnon-regresie (fara versant):")
	var flat_lat: float = flat["start_lateral"]
	var flat_ok := flat_lat < 0.01
	if not flat_ok:
		failed = true
	print("  pornire laterala   -> %.2f m  %s"
			% [flat_lat, "OK (cade vertical)" if flat_ok else "PROBLEMA"])

	# --- 2b: modul cu TRASEU — porneste de unde i s-a spus, ajunge la capat,
	# se rostogoleste tot drumul, iar raza vine din model, nu din constanta.
	var routed := _trace_route()
	print("
traseu desenat (Path3D):")
	var r_start: float = routed["start_err"]
	var r_start_ok := r_start < 0.05
	if not r_start_ok:
		failed = true
	print("  porneste din primul punct  -> abatere %.2f m  %s"
			% [r_start, "OK" if r_start_ok else "PROBLEMA"])
	var r_end: float = routed["end_err"]
	# Ultimul cadru masurat e cu un pas inainte de capat: 9 m/s / 60 = 0.15 m.
	var r_end_ok := r_end < 0.2
	if not r_end_ok:
		failed = true
	print("  ajunge la ultimul punct    -> abatere %.2f m  %s"
			% [r_end, "OK" if r_end_ok else "PROBLEMA"])
	var r_spin: float = routed["spin_total"]
	var r_len: float = routed["length"]
	var r_radius: float = routed["radius"]
	# Rostogolire fara alunecare: unghiul total = lungime / raza (+-15%, curba
	# e esantionata).
	var expect := r_len / r_radius
	var r_spin_ok := absf(r_spin - expect) < expect * 0.15
	if not r_spin_ok:
		failed = true
	print("  rotatie totala             -> %.1f rad (asteptat %.1f = %.1f m / %.2f m)  %s"
			% [r_spin, expect, r_len, r_radius, "OK" if r_spin_ok else "PROBLEMA"])
	var r_still: int = routed["frames_still"]
	var r_still_ok := r_still == 0
	if not r_still_ok:
		failed = true
	print("  cadre in care sta pe loc   -> %d  %s"
			% [r_still, "OK (se rostogoleste continuu)" if r_still_ok else "PROBLEMA"])
	var r_model: String = routed["model"]
	var r_model_ok := r_model == "boulder_roller"
	if not r_model_ok:
		failed = true
	print("  model                      -> %s  %s"
			% [r_model, "OK" if r_model_ok else "PROBLEMA (nu e bolovanul rotund)"])
	var r_rad_ok := absf(r_radius - 1.25) < 0.05
	if not r_rad_ok:
		failed = true
	print("  raza masurata din model    -> %.2f m (asteptat 1.25)  %s"
			% [r_radius, "OK" if r_rad_ok else "PROBLEMA"])

	# --- 3: strivirea, masurata pe masina
	var crush := await _crush_test()
	print("\nstrivirea, masurata pe masina:")
	var factor: float = crush["factor"]
	var factor_ok := absf(factor - 0.70) < 0.01
	if not factor_ok:
		failed = true
	print("  plafon de viteza   -> %.0f%% (cerut 70%%)  %s"
			% [factor * 100.0, "OK" if factor_ok else "PROBLEMA"])
	var flat_y: float = crush["squash_y"]
	# Cerinta: cu ~30% mai aplatizata decat inainte (0.35 -> 0.245).
	var flat_ok2 := flat_y <= 0.25 + 0.005
	if not flat_ok2:
		failed = true
	print("  turtire pe Y       -> %.3f (inainte 0.35)  %s"
			% [flat_y, "OK" if flat_ok2 else "PROBLEMA"])
	var held: float = crush["squash_at_2s"]
	var held_ok := held <= 0.30
	if not held_ok:
		failed = true
	print("  turtita si la 2.0s -> %.3f  %s"
			% [held, "OK (tine)" if held_ok else "PROBLEMA (a revenit prea repede)"])
	var back: float = crush["squash_at_end"]
	var back_ok := back > 0.9
	if not back_ok:
		failed = true
	print("  revenita la 3.4s   -> %.3f  %s"
			% [back, "OK" if back_ok else "PROBLEMA (ramane turtita)"])
	var slow: float = crush["crush_time_at_2s"]
	var slow_ok := slow > 0.5
	if not slow_ok:
		failed = true
	print("  inca incetinita 2s -> %.2f s ramase  %s"
			% [slow, "OK" if slow_ok else "PROBLEMA"])

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Urmareste un ciclu de bolovan si intoarce ce a facut.
##
## Traiectoria se ia din `_start_pos()` si din fazele rulate, NU citind
## `_rock.position`: bolovanul e un `AnimatableBody3D` cu `sync_to_physics`,
## deci pozitia scrisa de faze nu se vede inapoi pe nod intr-o sonda fara pasi
## de fizica reali (aceeasi capcana ca la probe_crossing.gd, unde masuratoarea
## pe pozitie raporta 0.00 pentru un obstacol perfect functional).
##
## Rostogolirea insa se poate citi direct: pivotul e un Node3D obisnuit.
func _trace(slope_side: float) -> Dictionary:
	var hz := RockfallHazard.new()
	hz.period = PERIOD
	hz.slope_side = slope_side
	add_child(hz)

	var step := 1.0 / 60.0
	# De unde porneste: direct din geometria declarata de hazard.
	var start_lateral: float = absf(hz._start_pos().x)
	var impact_lateral := 999.0
	var spin_start: Basis
	var spin_end: Basis
	var seen_start := false
	# Un ciclu intreg, ca sa prindem si telegraful si coborarea si asezarea.
	for i in int(PERIOD / step):
		hz._physics_process(step)
		var t := hz._time
		if t < RockfallHazard.TELEGRAPH and not seen_start:
			if hz._pivot != null:
				spin_start = hz._pivot.transform.basis
			seen_start = true
		# La finalul coborarii: unde a ajuns fata de banda de impact. Se ia din
		# ultima pozitie CERUTA de faze (`_last_pos`, scrisa de `_roll`), care e
		# un camp obisnuit, nu transformul corpului.
		var fall_end := RockfallHazard.TELEGRAPH + RockfallHazard.FALL
		if t >= fall_end and t < fall_end + 0.1:
			impact_lateral = minf(impact_lateral, absf(hz._last_pos.x))
			if hz._pivot != null:
				spin_end = hz._pivot.transform.basis

	var spin := 0.0
	if hz._pivot != null and seen_start:
		# Cat s-a rotit, ca unghi intre orientarea de start si cea de la impact.
		spin = spin_start.get_rotation_quaternion().angle_to(
			spin_end.get_rotation_quaternion()) * 2.0
	var out := {
		"start_lateral": start_lateral,
		"impact_lateral": impact_lateral,
		"spin": spin,
	}
	hz.queue_free()
	return out


## Un bolovan cu traseu: curba de la (12, 8, -3) prin (4, 3, 0) peste origine
## pana la (-10, 0, 4). Urmareste o trecere intreaga si masoara ce a facut.
func _trace_route() -> Dictionary:
	var curve := Curve3D.new()
	curve.add_point(Vector3(12.0, 8.0, -3.0))
	curve.add_point(Vector3(4.0, 3.0, 0.0))
	curve.add_point(Vector3(0.0, 0.0, 0.0))
	curve.add_point(Vector3(-10.0, 0.0, 4.0))
	var hz := RockfallHazard.new()
	hz.route = curve
	hz.route_pause = 1.0
	add_child(hz)

	var step := 1.0 / 60.0
	var radius: float = hz._radius
	var first := curve.get_point_position(0) + Vector3.UP * radius
	var last := curve.get_point_position(3) + Vector3.UP * radius
	var start_err := INF
	var end_err := INF
	var spin_total := 0.0
	var frames_still := 0
	var prev_basis: Basis = hz._pivot.transform.basis
	var frames := int(hz._route_travel / step)
	for i in frames:
		hz._physics_process(step)
		var pos: Vector3 = hz._last_pos
		if i == 0:
			start_err = pos.distance_to(first)
		end_err = pos.distance_to(last)
		var b: Basis = hz._pivot.transform.basis
		var da := prev_basis.get_rotation_quaternion().angle_to(
			b.get_rotation_quaternion())
		prev_basis = b
		if i > 0 and da < 0.0005:
			frames_still += 1
		spin_total += da
	var model_name := ""
	if hz._pivot.get_child_count() > 0:
		model_name = String(hz._pivot.get_child(0).name)
	var out := {
		"start_err": start_err,
		"end_err": end_err,
		"spin_total": spin_total,
		"length": hz._route_len,
		"radius": radius,
		"frames_still": frames_still,
		"model": model_name,
	}
	hz.queue_free()
	return out


## Aplica strivirea pe o masina adevarata si masoara ce se vede pe ea.
func _crush_test() -> Dictionary:
	var car_scene: PackedScene = load("res://scenes/cars/Car.tscn")
	var car: Car = car_scene.instantiate()
	add_child(car)
	await get_tree().process_frame

	car.crush(RockfallHazard.CRUSH_SECONDS, RockfallHazard.CRUSH_FACTOR,
		RockfallHazard.CRUSH_SQUASH, RockfallHazard.CRUSH_KEEP_SPEED, true)

	var visual: Node3D = car.get_node_or_null("Visual")
	if visual == null:
		for c in car.get_children():
			if c is Node3D and c.name != "Camera":
				visual = c
				break

	# Turtirea intra in 0.08 s; masuram dupa ce s-a asezat.
	await _wait(0.2)
	var squash_y: float = visual.scale.y if visual != null else -1.0
	await _wait(1.8) # 2.0 s de la lovitura
	var at_2s: float = visual.scale.y if visual != null else -1.0
	var left_at_2s: float = car.crush_time
	await _wait(1.4) # 3.4 s: dupa revenire
	var at_end: float = visual.scale.y if visual != null else -1.0

	var out := {
		"factor": RockfallHazard.CRUSH_FACTOR,
		"squash_y": squash_y,
		"squash_at_2s": at_2s,
		"squash_at_end": at_end,
		"crush_time_at_2s": left_at_2s,
	}
	car.queue_free()
	return out


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
