extends Node
## Sonda tehnica pentru traficul de tuk-tuk-uri (Jodhpur, brief §7 pasul 1,
## §4 „de verificat devreme" (1)(2)). Doua teste, ambele pe drum drept plat
## (ca la ProbeBumpRigid — bumpingul e o proprietate a solverului, nu a
## pistei):
##
##   (a) matrice de impact: fiecare CarData de cursa (scenes/cars/data/*.tres
##       in afara de tuktuk.tres) x 20 si 30 m/s x lovitura bot-in-spate si
##       laterala, in tuk-tuk-ul care merge la 14 m/s (CRUISE_SPEED). Masoara
##       pierderea de viteza a masinii de cursa (%), daca tuk-tuk-ul se
##       rastoarna, daca masina de cursa se rastoarna.
##   (b) redresarea: tuk-tuk rasturnat FORTAT -> in picioare si in mers in
##       <= 2,5 s + marja (TrafficController.UPSIDE_RECOVER_S).
##
## Tinte (brief): Sport/Politia pierd <= 25% la 30 m/s bot-in-spate, Autobuzul
## <= 10%, NICIO masina de cursa rasturnata. Cifrele TREBUIE sa difere intre
## masini — identice inseamna masa neconectata (memoria
## `reglajul-ieftin-se-testeaza-pe-cifra`).
##
## `tuktuk.tres.mass_factor`: brief-ul propunea 0,45; MASURAT nu ajunge la
## tinte (0,45 -> Politia 29,9%, Autobuzul 11,6%; 0,38 -> 26,7%/10,1%, tot
## peste). Retunat la 0,34, unde ambele tinte trec (Politia 24,6%, Autobuzul
## 9,2%, la 30 m/s bot-in-spate) — vezi principiul din brief §5: "un `nu merge
## la valoarea din brief, merge la alta, masurata` e livrare corecta".
##
## Ruleaza CA SCENA (autoload-uri necesare, ca la ProbeBumpRigid):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodTuk.tscn

const STEP: float = 1.0 / 60.0
const TUKTUK_DATA: String = "res://scenes/cars/data/tuktuk.tres"
## Toate CarData de cursa, in afara de tuktuk — brief §4(a).
const RACE_DATA: Array[String] = [
	"res://scenes/cars/data/buggy.tres",
	"res://scenes/cars/data/bus.tres",
	"res://scenes/cars/data/firetruck.tres",
	"res://scenes/cars/data/muscle.tres",
	"res://scenes/cars/data/police_sports.tres",
	"res://scenes/cars/data/taxi.tres",
]
const CRUISE_SPEED: float = 14.0 # TrafficController.CRUISE_SPEED, duplicat aici
# ca sonda sa ramana independenta de implementare (memoria `garda-circulara-
# propria-functie` — masoara cu o raza proprie, nu cu functia hazardului).
const ENTRY_SPEEDS: Array[float] = [20.0, 30.0]

var _failed: bool = false

func _ready() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(800, 1, 800)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame

	print("")
	print("=== Trafic tuk-tuk (Jodhpur, Track17) ===")
	await _test_impact_matrix()
	await _test_recovery()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


## Masina, cu CarData REALA (dimensiuni, masa, centru de masa) — folosim
## Car.apply_data ca in joc, nu doar mass_factor brut, fiindca aici conteaza
## si gabaritul (offset de contact) si centrul de masa (rasturnarea).
func _spawn(data_path: String, pos: Vector3, facing: Vector3) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	if facing.length_squared() > 0.001:
		car.global_transform = Transform3D(
			Basis.looking_at(facing.normalized(), Vector3.UP), pos)
	car.apply_data(load(data_path) as CarData)
	car.race_active = true
	return car


func _is_upside_down(car: Car) -> bool:
	return car.global_transform.basis.y.dot(Vector3.UP) < 0.35


func _settle(cars: Array[Car]) -> void:
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	for car in cars:
		car.linear_velocity = Vector3.ZERO
		car.angular_velocity = Vector3.ZERO


# ------------------------------------------------------------- (a) matrice

func _test_impact_matrix() -> void:
	print("")
	print("-- (a) matricea de impact: masina de cursa -> tuk-tuk (14 m/s) --")
	print("%-14s %6s %10s %10s %12s %10s" % [
		"masina", "v(m/s)", "unghi", "pierdere%", "tuk-rast?", "masina-rast?"])
	var any_race_flip := false
	var loss_by_car: Dictionary = {}
	for data_path in RACE_DATA:
		var data := load(data_path) as CarData
		var name: String = data.display_name
		for entry_speed in ENTRY_SPEEDS:
			for angle_label in ["bot-spate", "laterala"]:
				var r := await _run_impact(data_path, entry_speed, angle_label == "laterala")
				print("%-14s %6.0f %10s %9.1f%% %12s %10s" % [
					name, entry_speed, angle_label, r.loss_pct,
					"DA" if r.tuk_flip else "nu",
					"DA" if r.attacker_flip else "nu"])
				if r.attacker_flip:
					any_race_flip = true
				var key := "%s|%s" % [name, angle_label]
				if entry_speed == 30.0:
					loss_by_car[key] = r.loss_pct
	_check(not any_race_flip, "nicio masina de cursa nu se rastoarna la impact")
	# Tintele explicite ale brief-ului, la 30 m/s bot-in-spate.
	var sport_loss: float = float(loss_by_car.get("Politia|bot-spate", -1.0))
	var bus_loss: float = float(loss_by_car.get("Autobuzul|bot-spate", -1.0))
	if sport_loss >= 0.0:
		_check(sport_loss <= 25.0,
			"Politia pierde <= 25%% la 30 m/s bot-in-spate (masurat %.1f%%)" % sport_loss)
	if bus_loss >= 0.0:
		_check(bus_loss <= 10.0,
			"Autobuzul pierde <= 10%% la 30 m/s bot-in-spate (masurat %.1f%%)" % bus_loss)
	# Cifrele TREBUIE sa difere intre masini — identice = masa neconectata.
	var distinct := {}
	for v in loss_by_car.values():
		distinct[snappedf(float(v), 0.01)] = true
	_check(distinct.size() > 1,
		"pierderile difera intre masini (%d valori distincte din %d) — masa e conectata"
			% [distinct.size(), loss_by_car.size()])


## Controller de laborator: gaz fix, ca ScriptDriver din probe_bump_rigid.gd —
## fara el, o masina fara "creier" are throttle=0 (vezi Car._physics_process,
## `controller != null` e conditia gazului) si DECELEREAZA din drag chiar in
## fereastra in care se masoara impactul, amestecand franarea normala cu
## pierderea din ciocnire. Cu gaz tinut, viteza dinainte de impact e stabila —
## exact ce ar simti un sofer care nu ridica piciorul.
class ScriptDriver:
	extends CarController
	var throttle: float = 1.0
	func get_throttle() -> float:
		return throttle
	func get_steer() -> float:
		return 0.0

## O singura rulare a matricei: masina de cursa vine cu `entry_speed` din spate
## (sau lateral) intr-un tuk-tuk care circula la CRUISE_SPEED (14 m/s, ca in
## joc — nu un obstacol static). Pierderea se masoara ca DELTA-V DE PE UN
## SINGUR CADRU (tiparul din probe_bump_rigid._watch_impact): impulsul de
## coliziune se aplica intr-un singur pas de solver, deci "lovitura" e varful
## de acolo — o fereastra lunga (2s) ar amesteca impactul cu franarea/dragul
## normal de dupa el, care NU e parte din "cat pierzi la impact" (masurat in
## prima versiune: ~60% identic la toate masinile, semn de mecanism gresit,
## nu de masa neconectata — vezi memoria `reglajul-ieftin-se-testeaza-pe-cifra`).
func _run_impact(attacker_data: String, entry_speed: float, lateral: bool) -> Dictionary:
	var tuk := _spawn(TUKTUK_DATA, Vector3(0, 0.7, 0), Vector3.FORWARD)
	var tuk_driver := ScriptDriver.new()
	tuk.set_controller(tuk_driver)
	var gap := 12.0
	var attacker_pos: Vector3
	var attacker_dir: Vector3
	if lateral:
		# Atac perpendicular pe axa tuk-tuk-ului, in flancul lui. Tuk-tuk-ul
		# insusi se misca (spre -Z, CRUISE_SPEED) cat atacatorul traverseaza
		# golul — fara compensare, atacatorul ar ajunge la x=0 mult DUPA ce
		# tuk-tuk-ul a trecut deja de acolo (masurat: 0% "impact", niciun
		# contact deloc). Se tinteste unde va fi, nu unde e acum: offset pe Z
		# cu cat inainteaza tuk-tuk-ul in timpul de traversare (gap/entry_speed).
		var lead_s := gap / entry_speed
		attacker_pos = Vector3(-gap, 0.7, -CRUISE_SPEED * lead_s)
		attacker_dir = Vector3.RIGHT
	else:
		# Bot-in-spate: atacatorul vine din spatele tuk-tuk-ului (+Z), mergand
		# in ACEEASI directie (-Z, ca Vector3.FORWARD — tuk-tuk-ul "priveste"
		# spre -Z si merge inainte), doar mai repede — il ajunge din urma.
		attacker_pos = Vector3(0, 0.7, gap)
		attacker_dir = Vector3.FORWARD
	var attacker := _spawn(attacker_data, attacker_pos, attacker_dir)
	var attacker_driver := ScriptDriver.new()
	attacker.set_controller(attacker_driver)
	await _settle([tuk, attacker])
	tuk.linear_velocity = -tuk.global_transform.basis.z * CRUISE_SPEED
	attacker.linear_velocity = attacker_dir.normalized() * entry_speed

	# Bilantul ca la probe_bump_rigid: cel mai mare delta-v pe UN cadru, pe
	# fereastra in care cele doua corpuri chiar se ating (get_colliding_bodies
	# nu e gol) — dupa separare, orice schimbare de viteza e franare/drag
	# normal, nu impactul.
	var attacker_speed0 := attacker.horizontal_speed()
	var tuk_flip := false
	var attacker_flip := false
	var attacker_prev := attacker.linear_velocity
	var attacker_peak_dv := 0.0
	var contact_seen := false
	for _f in int(2.5 / STEP):
		await get_tree().physics_frame
		var touching := false
		for body in attacker.get_colliding_bodies():
			if body == tuk:
				touching = true
				break
		if touching:
			contact_seen = true
			var dv := (attacker.linear_velocity - attacker_prev).length()
			attacker_peak_dv = maxf(attacker_peak_dv, dv)
		attacker_prev = attacker.linear_velocity
		if _is_upside_down(tuk):
			tuk_flip = true
		if _is_upside_down(attacker):
			attacker_flip = true
	# Pierderea = cat din viteza de abordare s-a dus in impuls, nu viteza
	# absoluta ramasa (care ar amesteca "cat a pierdut" cu "cat mai franeaza
	# in continuare din drag normal").
	var loss_pct := (attacker_peak_dv / maxf(attacker_speed0, 0.001)) * 100.0
	if not contact_seen:
		push_warning("probe_jod_tuk: %s @ %.0f m/s (%s) — NICIUN contact detectat"
			% [attacker_data.get_file(), entry_speed, "laterala" if lateral else "bot-spate"])
	tuk.queue_free()
	attacker.queue_free()
	await get_tree().physics_frame
	return {
		"loss_pct": clampf(loss_pct, 0.0, 100.0),
		"tuk_flip": tuk_flip,
		"attacker_flip": attacker_flip,
	}


# ---------------------------------------------------------------- (b) redresare

func _test_recovery() -> void:
	print("")
	print("-- (b) redresarea: tuk-tuk rasturnat -> in picioare si in mers --")
	var tuk := _spawn(TUKTUK_DATA, Vector3(0, 1.2, 0), Vector3.FORWARD)
	# Rasturnare FORTATA: orientare cu susul in jos, direct — nu simulam
	# cauza (o lovitura reala), doar consecinta, ca la ProbeBumpRigid unde
	# se testeaza reactia la o stare data, nu drumul pana la ea.
	tuk.global_transform = Transform3D(
		Basis(Vector3.RIGHT, PI), Vector3(0, 1.2, 0))
	tuk.linear_velocity = Vector3.ZERO
	tuk.angular_velocity = Vector3.ZERO
	var traffic := TrafficController.new()
	tuk.set_controller(traffic)
	var track_stub := _make_straight_route()
	traffic.configure(track_stub, [])
	await get_tree().physics_frame
	_check(tuk.global_transform.basis.y.dot(Vector3.UP) < 0.35,
		"rasturnarea fortata a reusit (precondiție)")

	var recovered_at := -1.0
	var moving_at := -1.0
	var t := 0.0
	var limit := TrafficController.UPSIDE_RECOVER_S + 1.5 # marja ceruta de brief
	while t < limit:
		await get_tree().physics_frame
		t += STEP
		if recovered_at < 0.0 and tuk.global_transform.basis.y.dot(Vector3.UP) > 0.85:
			recovered_at = t
		if recovered_at >= 0.0 and moving_at < 0.0 and tuk.horizontal_speed() > 2.0:
			moving_at = t
	print("  redresat la t=%.2fs, in miscare la t=%s (limita %.1fs)" % [
		recovered_at, ("%.2fs" % moving_at) if moving_at >= 0.0 else "NICIODATA", limit])
	_check(recovered_at >= 0.0 and recovered_at <= limit,
		"tuk-tuk-ul se redreseaza in <= %.1fs" % limit)
	_check(moving_at >= 0.0 and moving_at <= limit,
		"tuk-tuk-ul e din nou in mers in <= %.1fs" % limit)
	tuk.queue_free()
	await get_tree().physics_frame


## `TrafficController.update()` cere un `Track` pentru `route_at`/`width_at_index`/
## `lookahead_point`/`curve.bake_interval`. `Track` de baza n-are puncte proprii
## (`_code_points()` din clasa de baza da eroare si lista goala — e menita sa
## fie suprascrisa de o subclasa de pista reala), deci nu se poate instantia
## direct: refolosim Dunele (Track01, cea mai simpla pista existenta) ca sursa
## de geometrie — testul de redresare nu depinde de FORMA pistei, doar de un
## `Track` functional pentru cele patru apeluri de mai sus.
func _make_straight_route() -> Track:
	var scene := load("res://scenes/tracks/Track01.tscn") as PackedScene
	var track := scene.instantiate() as Track
	add_child(track)
	return track
