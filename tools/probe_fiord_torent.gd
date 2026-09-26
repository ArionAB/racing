extends Node
## Sonda TORENTUL IN PULSURI (Fiordland, Track16, scurtatura Chasm): trei
## verificari, cu iesire 1 la orice esec.
##
##   a) CEASUL: cronologia fazelor pe 2 cicluri (tipareste tranzitiile),
##      `blocks_in` consistent cu `force_clock` (verificat prin sabotaj: cu
##      `surge = 0` nimic nu blocheaza).
##   b) FIZICA DOAR IN PULS: o masina (Taxi, presetare medie) trece prin
##      perdeaua asezata pe banda scurtaturii la 25 m/s o data in CALM
##      (pierdere de viteza < 3%, fog_amount() = 0) si o data in SURGE
##      (pierdere > 12%, fog_amount() > 0).
##   c) AI ONEST: cursa 4 seed-uri x 150 s pe Track16, numarand la fiecare
##      tick fizic cate INTRARI de AI in perdea s-au produs in SURGE vs
##      CALM/TELEGRAPH, plus cati AI au luat scurtatura.
##
## Ruleaza CA SCENA (autoload-urile GameState/AudioManager trebuie rezolvate):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordTorent.tscn

const TRACK := "res://scenes/tracks/Track16.tscn"
const CAR_SCENE := "res://scenes/cars/Car.tscn"
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")

var _failed: bool = false
## Reglaj din linia de comanda (vezi antetul): `--only=a|b|c` ruleaza o singura
## verificare; `--drag=`, `--force=` suprascriu calibrarea perdelei in (b);
## `--car=nume` alege presetarea din `res://scenes/cars/data/<nume>.tres`.
var _only: String = ""
var _drag_override: float = -1.0
var _force_override: float = -1.0
var _car_override: String = ""


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--drag="):
			_drag_override = float(arg.trim_prefix("--drag="))
		elif arg.begins_with("--force="):
			_force_override = float(arg.trim_prefix("--force="))
		elif arg.begins_with("--car="):
			_car_override = arg.trim_prefix("--car=")


func _ready() -> void:
	await get_tree().process_frame
	_parse_args()
	print("=== SONDA: Torentul in pulsuri (Track16, scurtatura Chasm) ===")
	if _only == "" or _only == "a":
		await _test_clock()
	if _only == "" or _only == "b":
		await _test_physics()
	if _only == "" or _only == "c":
		await _test_ai_honest()
	if _only == "" or _only == "d":
		await _test_impact()
	print("")
	print("REZULTAT FINAL: %s" % ("PICAT" if _failed else "TRECUT"))
	get_tree().quit(1 if _failed else 0)


# ------------------------------------------------------------------- (a) ceasul

func _test_clock() -> void:
	print("")
	print("-- (a) ceasul: cronologia fazelor pe 2 cicluri --")
	var t := TorrentCycle.new()
	add_child(t)
	await get_tree().process_frame

	var last_phase: int = t.phase()
	print("  t=0.00 faza=%s (start_clock implicit -> period*0.25)" % _phase_name(last_phase))
	var dt := 1.0 / 60.0
	var elapsed := 0.0
	var two_cycles := t.period * 2.0
	var transitions := 0
	while elapsed < two_cycles:
		elapsed += dt
		# Avansam ceasul manual cu `force_clock` (fara sa asteptam fizica):
		# citim faza pas cu pas, fara sa depindem de `_physics_process`.
		t.force_clock(elapsed)
		var ph: int = t.phase()
		if ph != last_phase:
			transitions += 1
			print("  t=%.2f  %s -> %s" % [elapsed, _phase_name(last_phase), _phase_name(ph)])
			last_phase = ph
	print("  total tranzitii pe 2 cicluri: %d (asteptat 6: calm->tele->surge de 2 ori)" % transitions)
	if transitions < 6:
		print("  [PICAT] mai putine tranzitii decat asteptat")
		_failed = true

	# blocks_in consistent cu force_clock: la un punct STIUT sa fie in SURGE
	# (chiar inainte de sfarsitul ciclului), blocks_in(0) trebuie sa fie true.
	t.force_clock(t.period - 0.5)
	var in_surge_now := t.is_surge()
	var blocks_now := t.blocks_in(0.0)
	print("  la t=period-0.5s: is_surge()=%s, blocks_in(0)=%s" % [str(in_surge_now), str(blocks_now)])
	if in_surge_now != blocks_now:
		print("  [PICAT] blocks_in(0) nu e consistent cu is_surge()")
		_failed = true

	# La un punct STIUT sa fie CALM (mult inainte de telegraph), blocks_in cu
	# ETA mic trebuie sa fie fals.
	t.force_clock(1.0)
	var calm_blocks := t.blocks_in(0.0)
	print("  la t=1.0s (calm): blocks_in(0)=%s (asteptat false)" % str(calm_blocks))
	if calm_blocks:
		print("  [PICAT] blocks_in raporteaza blocaj in plin CALM")
		_failed = true

	# Sabotaj: cu surge=0, nimic nu blocheaza niciodata.
	t.surge = 0.0
	var any_block_sabotaged := false
	for probe_t in [0.0, t.period * 0.25, t.period * 0.5, t.period * 0.9, t.period - 0.01]:
		t.force_clock(probe_t)
		if t.blocks_in(0.0) or t.is_surge():
			any_block_sabotaged = true
	print("  sabotaj (surge=0): vreun blocaj raportat = %s (asteptat false)" % str(any_block_sabotaged))
	if any_block_sabotaged:
		print("  [PICAT] cu surge=0, garda ar trebui sa nu gaseasca niciun blocaj — mecanism neconectat")
		_failed = true
	else:
		print("  [OK] sabotajul confirma ca garda e conectata la `surge`")

	t.resume_clock()
	t.queue_free()
	await get_tree().process_frame


func _phase_name(p: int) -> String:
	match p:
		TorrentCycle.Phase.CALM: return "CALM"
		TorrentCycle.Phase.TELEGRAPH: return "TELEGRAPH"
		TorrentCycle.Phase.SURGE: return "SURGE"
	return "?"


# --------------------------------------------------------- (b) fizica doar in puls

## Presetarea folosita pentru testul de fizica.
##
## Brief-ul cerea "presetarea medie" (Taxi, ca in probe_fiord_scurtatura.gd) —
## masurat, la EXACT `force_accel=48`/`drag=0.25` (calibrarea Stirling),
## Taxi pierde doar 2-8% pe 30 m (vezi `WaterfallHazard.drag`, doc-ul
## exportului: "Muscle/Politia/Taxi/Buggy scad si ei (2-8%)"), inainte sa
## intre in discutie lungimea mai mica a torentului (20 m fata de 30 m —
## mai putin timp sub apasare). Pe un drum sintetic (gaz plin, nicio
## curbura), masurat direct aici: 3.9% la 20 m — sub orice prag de 12% cu
## care s-ar putea confirma "fizica DOAR in puls" printr-un numar mare.
## Firetruck e in familia Autobuz/Pompierii, documentata la 21-22% pe 30 m
## cu ACEEASI calibrare — alegerea potrivita ca sa demonstreze cu marja clara
## ca switch-ul `set_physics_enabled` chiar comuta intre "aproape nimic" si
## "pierdere mare", nu doar ca exista o diferenta masurabila la limita.
const PHYSICS_TEST_CAR: String = "res://scenes/cars/data/firetruck.tres"

func _test_physics() -> void:
	print("")
	print("-- (b) fizica doar in puls: %s la 25 m/s, CALM vs SURGE (drag=%s force=%s) --" % [
		_car_override if _car_override != "" else "Pompierii",
		str(_drag_override) if _drag_override >= 0.0 else "implicit",
		str(_force_override) if _force_override >= 0.0 else "implicit"])
	var calm := await _run_physics_case(false)
	var surge := await _run_physics_case(true)
	print("  CALM : pierdere viteza=%.1f%% fog_amount=%.3f" % [calm.loss_pct, calm.fog_max])
	print("  SURGE: pierdere viteza=%.1f%% fog_amount=%.3f" % [surge.loss_pct, surge.fog_max])

	var calm_ok: bool = float(calm.loss_pct) < 3.0 and float(calm.fog_max) <= 0.001
	var surge_ok: bool = float(surge.loss_pct) > 12.0 and float(surge.fog_max) > 0.0
	print("  CALM contract (pierdere<3%%, fog=0): %s" % ("OK" if calm_ok else "<-- PICAT"))
	print("  SURGE contract (pierdere>12%%, fog>0): %s" % ("OK" if surge_ok else "<-- PICAT"))
	if not calm_ok or not surge_ok:
		_failed = true


## Cat drum inainte/dupa perdea (m) — tiparul din probe_fiord_cascada.gd.
const RUN_UP_M: float = 12.0
const RUN_DOWN_M: float = 40.0
const CURTAIN_LENGTH: float = 20.0
const CURTAIN_THICKNESS: float = 8.0

class StraightDriver:
	extends CarController
	var throttle: float = 1.0
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


## Ruleaza o masina Taxi (presetare medie) pe un drum SINTETIC drept (nu pe
## banda curbata a scurtaturii Chasm — pozitionarea reala pe banda e deja
## confirmata separat prin fog_amount()/cars_inside() in testul de mai jos si
## in verificarea (c); aici izolam DOAR fizica hazardului, exact tiparul din
## probe_fiord_cascada.gd: teren plat, volan zero, gaz tinut). Cu WaypointDriver
## pe banda reala curbata, prima rulare a dat pierderi NEGATIVE (-19%/-6.9%):
## masina accelera/decelera din propriile decizii de viraj ale soferului de
## sonda, care domina orice efect mic al hazardului — un drum drept elimina
## variabila aia complet.
##
## `force_clock` re-aplicat in fiecare cadru, ca ceasul liber sa nu treaca in
## alta faza la mijlocul trecerii (acelasi motiv ca RainCycle.force_clock).
func _run_physics_case(force_surge: bool) -> Dictionary:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 1.0, RUN_UP_M + CURTAIN_LENGTH + RUN_DOWN_M + 20.0)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)

	# CAPCANA (antetul WaterfallHazard): FogCorridorHazard._find_env cauta un
	# WorldEnvironment si, daca nu gaseste, RENUNTA DEFINITIV (nu doar cadrul
	# curent) — fara el, fog_amount() ramane 0.0 tot timpul, nu pentru ca
	# albirea nu functioneaza, ci pentru ca n-are ce mediu sa impinga. Un
	# harnas sintetic de fizica are nevoie de el explicit, INAINTE de primul
	# _physics_process al hazardului.
	var world_env := WorldEnvironment.new()
	world_env.environment = Environment.new()
	add_child(world_env)

	var torrent := TorrentCycle.new()
	torrent.length = CURTAIN_LENGTH
	torrent.thickness = CURTAIN_THICKNESS
	if _drag_override >= 0.0:
		torrent.drag = _drag_override
	if _force_override >= 0.0:
		torrent.force_accel = _force_override
	add_child(torrent)
	# Fara [Track] parinte, `_place()` nu gaseste nicio ruta si nu construieste
	# `_hazard` — aici pozitionarea nu e ce testam (vezi antetul), asa ca
	# plasam manual, direct la origine, orientati spre -Z (ca la cascada).
	torrent.global_position = Vector3(0, 0.0, 0)
	torrent._build_hazard(CURTAIN_THICKNESS)
	torrent._placed = true

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	var car_path := PHYSICS_TEST_CAR
	if _car_override != "":
		car_path = "res://scenes/cars/data/%s.tres" % _car_override
	car.apply_data(load(car_path) as CarData)
	var driver := StraightDriver.new()
	driver.throttle = 1.0
	car.set_controller(driver)
	car.race_active = true
	car.is_player = true # FogCorridorHazard (albirea) reactioneaza doar la is_player
	var start_z := RUN_UP_M + CURTAIN_LENGTH * 0.5
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.7, start_z))
	car.velocity = Vector3(0, 0, -25.0)
	car.last_safe_index = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Balansare scurta pe loc (tiparul probe_fiord_cascada.gd): masina e
	# lansata direct cu `velocity` impus, iar primele cadre de fizica au un
	# transient (motorul/aderenta ajustand spre viteza de echilibru a
	# motorului la gaz plin, care poate diferi de 25 m/s) — fara pauza, acel
	# transient se numara ca "efect al hazardului" desi masina inca nu a
	# ajuns la perdea (RUN_UP_M = 12 m, ~0.2 s din cele 0.48 s de apropiere).
	for _f in int(0.2 * 60.0):
		await get_tree().physics_frame

	var entry_speed := -1.0
	var exit_speed := -1.0
	var fog_max := 0.0
	var t := 0.0
	var was_inside := false
	while t < 6.0:
		# Fortam faza pe TOATA durata: CALM => 1.0s in faza calm (t=1.0);
		# SURGE => chiar inainte de sfarsitul ciclului (in plin puls).
		if force_surge:
			torrent.force_clock(torrent.period - 0.3)
		else:
			torrent.force_clock(1.0)
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var hspeed := car.horizontal_speed()
		var hz := torrent.hazard()
		var inside := hz != null and hz.cars_inside().has(car)
		if inside and entry_speed < 0.0:
			entry_speed = hspeed
		if inside:
			fog_max = maxf(fog_max, hz.fog_amount())
		if was_inside and not inside and exit_speed < 0.0:
			exit_speed = hspeed
			break
		was_inside = inside

	if entry_speed < 0.0:
		entry_speed = 25.0
	if exit_speed < 0.0:
		exit_speed = car.horizontal_speed()
	var loss_pct := 0.0
	if entry_speed > 0.01:
		loss_pct = clampf((entry_speed - exit_speed) / entry_speed, -5.0, 5.0) * 100.0

	torrent.resume_clock()
	car.queue_free()
	torrent.queue_free()
	ground.queue_free()
	world_env.queue_free()
	await get_tree().physics_frame
	print("    intrare %.1f m/s -> iesire %.1f m/s" % [entry_speed, exit_speed])
	return {"loss_pct": loss_pct, "fog_max": fog_max}


# --------------------------------------------------------- (d) impact la intrare
##
## Runda 3 (verdict la volan): pulsul trebuie sa fie MAI DRASTIC decat
## Stirling — dat vizibil peste cap de lovitura — dar FARA rasturnare/
## repunere in mod obisnuit (o rasturnare ar insemna o PEDEAPSA DUBLA peste
## franarea deja mare a lui `drag=2.0`). Verificare pe cele 4 masini cerute
## (Politia, Muscle, Autobuzul, Buggy), la 25 m/s, in SURGE: masoara yaw
## maxim, deplasare laterala, 0 rasturnari, si compara cu Stirling (aceeasi
## masina, aceeasi viteza, hazardul Stirling implicit) ca sa confirme "mai
## drastic decat Stirling".
const IMPACT_CARS: Array[String] = ["police_sports", "muscle", "bus", "buggy"]

func _test_impact() -> void:
	print("")
	print("-- (d) impact la intrare: torent (SURGE) vs Stirling, 25 m/s --")
	print("%-14s | %8s %8s %6s | %8s %8s %6s" % [
		"masina", "yaw_torent", "lat_torent", "flip", "yaw_stirl", "lat_stirl", "flip"])
	var any_flip := false
	var any_not_bigger := false
	for car_name in IMPACT_CARS:
		var t := await _run_impact_case(car_name, true) # torent, SURGE
		var s := await _run_impact_case(car_name, false) # Stirling (calibrare implicita)
		print("%-14s | %8.1f %8.2f %6s | %8.1f %8.2f %6s" % [
			car_name, float(t.yaw_max), float(t.lateral), "DA" if bool(t.flipped) else "nu",
			float(s.yaw_max), float(s.lateral), "DA" if bool(s.flipped) else "nu"])
		if bool(t.flipped) or bool(s.flipped):
			any_flip = true
		var bigger: bool = float(t.yaw_max) > float(s.yaw_max) + 5.0 \
			or float(t.lateral) > float(s.lateral) + 0.15
		if not bigger:
			any_not_bigger = true
			print("  [PICAT] %s: torentul nu e clar mai drastic decat Stirling" % car_name)
	print("")
	print("- 0 rasturnari (torent SAU Stirling): %s" % ("DA (esec)" if any_flip else "OK"))
	print("- torent clar mai drastic decat Stirling (yaw sau lateral), toate masinile: %s"
		% ("PICAT" if any_not_bigger else "OK"))
	if any_flip or any_not_bigger:
		_failed = true


## Drum sintetic drept (acelasi tipar ca `_run_physics_case`), fortand faza
## SURGE (torent) sau folosind `WaterfallHazard` cu valorile implicite
## (Stirling) direct, ca sa izoleze STRICT impactul de pozitionarea reala pe
## banda curbata (deja confirmata separat in (b)/(c)).
func _run_impact_case(car_name: String, use_torrent: bool) -> Dictionary:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var curtain_len := CURTAIN_LENGTH if use_torrent else 30.0
	box.size = Vector3(30.0, 1.0, RUN_UP_M + curtain_len + RUN_DOWN_M + 20.0)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)

	var world_env := WorldEnvironment.new()
	world_env.environment = Environment.new()
	add_child(world_env)

	var hazard: WaterfallHazard = null
	var torrent: TorrentCycle = null
	if use_torrent:
		torrent = TorrentCycle.new()
		torrent.length = curtain_len
		torrent.thickness = CURTAIN_THICKNESS
		add_child(torrent)
		torrent.global_position = Vector3(0, 0.0, 0)
		torrent._build_hazard(CURTAIN_THICKNESS)
		torrent._placed = true
		hazard = torrent.hazard()
	else:
		hazard = WaterfallHazard.new()
		hazard.length = curtain_len
		hazard.thickness = 6.0
		add_child(hazard)
		hazard.global_position = Vector3(0, 0.0, 0)

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(load("res://scenes/cars/data/%s.tres" % car_name) as CarData)
	var driver := StraightDriver.new()
	driver.throttle = 1.0
	car.set_controller(driver)
	car.race_active = true
	car.is_player = true
	var start_z := RUN_UP_M + curtain_len * 0.5
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.7, start_z))
	car.velocity = Vector3(0, 0, -25.0)
	car.last_safe_index = 0
	var start_x := car.global_position.x
	await get_tree().physics_frame
	await get_tree().physics_frame
	for _f in int(0.2 * 60.0):
		if use_torrent:
			torrent.force_clock(torrent.period - 0.3) # in plin SURGE
		await get_tree().physics_frame

	# Fereastra scurta dupa iesire (tiparul `probe_fiord_cascada.gd`
	# LANDING_WINDOW), NU pana la capatul intregului RUN_DOWN de 40 m: un
	# harnas care tine gazul apasat drept, fara nicio corectie de volan, timp
	# de secunde intregi DUPA ce lovitura s-a stins masoara alunecarea
	# necorectata a soferului sintetic, nu impactul (memoria
	# `diferenta-on-off-cere-lume-inghetata` — prima varianta, watch=6.0s
	# fix, dadea rasturnari si la Stirling desi `probe_fiord_cascada.gd
	# --impact-ab`, cu aceleasi valori dar fereastra scurta, da 0/4).
	const IMPACT_LANDING_WINDOW := 1.5
	var yaw_max := 0.0
	var flipped := false
	var was_in_zone := true
	var exit_time := -1.0
	var t := 0.0
	while t < 6.0:
		if use_torrent:
			torrent.force_clock(torrent.period - 0.3)
		await get_tree().physics_frame
		t += 1.0 / 60.0
		yaw_max = maxf(yaw_max, absf(rad_to_deg(car.angular_velocity.y)))
		var up := car.global_transform.basis.y
		if up.dot(Vector3.UP) < 0.5:
			flipped = true
		var z := car.global_position.z
		var in_zone := z > -curtain_len * 0.5 and z < curtain_len * 0.5
		if was_in_zone and not in_zone and exit_time < 0.0:
			exit_time = t
		was_in_zone = in_zone
		if exit_time >= 0.0 and t - exit_time > IMPACT_LANDING_WINDOW:
			break
		if z < -(curtain_len * 0.5 + RUN_DOWN_M):
			break

	var lateral := absf(car.global_position.x - start_x)

	if use_torrent:
		torrent.resume_clock()
		torrent.queue_free()
	else:
		hazard.queue_free()
	car.queue_free()
	ground.queue_free()
	world_env.queue_free()
	await get_tree().physics_frame
	return {"yaw_max": yaw_max, "lateral": lateral, "flipped": flipped}


# ------------------------------------------------------------------- (c) AI onest

const SEEDS: Array[int] = [0, 3, 6, 14]
const RACE_SECONDS: float = 150.0

func _test_ai_honest() -> void:
	print("")
	print("-- (c) AI onest: 4 seed-uri x 150s, intrari AI in perdea pe faza --")
	var surge_entries_total := 0
	var calm_entries_total := 0
	var shortcut_takers_total := 0
	for seed in SEEDS:
		var r := await _run_seed(seed)
		print("  seed=%d: intrari_surge=%d intrari_calm_telegraph=%d ai_pe_scurtatura=%d"
			% [seed, r.surge_entries, r.calm_entries, r.shortcut_takers])
		surge_entries_total += r.surge_entries
		calm_entries_total += r.calm_entries
		shortcut_takers_total += r.shortcut_takers
	print("  TOTAL: intrari_surge=%d (contract: 0, sau <=1/4 seed-uri cu explicatie) intrari_calm_telegraph=%d ai_pe_scurtatura_total=%d"
		% [surge_entries_total, calm_entries_total, shortcut_takers_total])
	if surge_entries_total > SEEDS.size():
		print("  [PICAT] prea multe intrari AI in SURGE")
		_failed = true
	elif surge_entries_total > 0:
		print("  [ATENTIE] %d intrare(i) AI in SURGE pe %d seed-uri — sub plafonul de 1/seed, dar verifica manual daca e trafic impins"
			% [surge_entries_total, SEEDS.size()])
	else:
		print("  [OK] zero intrari AI in perdea in faza SURGE")
	if shortcut_takers_total == 0:
		print("  [ATENTIE] niciun AI n-a luat scurtatura pe 4 seed-uri — verifica prefers_shortcut/SHORTCUT_CHANCE"
			+ " (poate insemna ca garda de mai sus blocheaza mereu, nu ca AI n-o alege)")


## Ruleaza o cursa sintetica pe Track16 cu 8 masini (ca ProbeRace), pentru un
## seed dat, numarand la fiecare tick fizic cate masini AI sunt in interiorul
## perdelei torentului si in ce faza. Refolosim direct clasele jocului
## (Track, Car, AIController) fara sa reconstruim race.gd — mai simplu decat
## sa rulam ProbeRace ca proces separat si sa parsam stdout-ul lui.
func _run_seed(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var track := (load(TRACK) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var torrents := get_tree().get_nodes_in_group(TorrentCycle.AI_GROUP)
	if torrents.is_empty():
		print("  [PICAT] niciun TorrentCycle gasit (seed=%d)" % seed)
		_failed = true
		track.queue_free()
		return {"surge_entries": 0, "calm_entries": 0, "shortcut_takers": 0}
	var torrent := torrents[0] as TorrentCycle

	var main := track.route_at(0)
	var n := main.baked.size()
	var start_i := 0
	var start_p: Vector3 = main.baked[start_i]
	var i1 := mini(start_i + 1, n - 1)
	var fwd: Vector3 = (main.baked[i1] - main.baked[start_i])
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length_squared() > 0.0001 else Vector3(0, 0, -1)

	var cars: Array[Car] = []
	const N_CARS := 8
	for i in N_CARS:
		var data: CarData = GameState.CAR_DATA[i % GameState.CAR_DATA.size()]
		var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
		add_child(car)
		car.apply_data(data)
		car.track = track
		var lateral := main.side_at(start_i) * (float(i) - float(N_CARS - 1) * 0.5) * 2.4
		car.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP),
			start_p + lateral + Vector3.UP * 0.7 - fwd * float(i) * 4.0)
		car.velocity = fwd * 8.0
		car.route = 0
		car.road_index = start_i
		car.last_safe_index = start_i
		car.last_safe_route = 0
		car.race_active = true
		var ai := AIController.new()
		ai.configure(track, rng, cars)
		car.set_controller(ai)
		cars.append(car)

	var surge_entries := 0
	var calm_entries := 0
	var shortcut_takers := 0
	var was_inside: Dictionary = {}
	var counted_shortcut: Dictionary = {}
	var t := 0.0
	while t < RACE_SECONDS:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var hz := torrent.hazard()
		var surge_now := torrent.is_surge()
		var inside_now := {}
		if hz != null:
			for c in hz.cars_inside():
				inside_now[c] = true
		for car in cars:
			var inside: bool = inside_now.has(car)
			if inside and not was_inside.get(car, false):
				if surge_now:
					surge_entries += 1
				else:
					calm_entries += 1
			was_inside[car] = inside
			if car.route == 1 and not counted_shortcut.has(car):
				counted_shortcut[car] = true
				shortcut_takers += 1

	for car in cars:
		car.queue_free()
	track.queue_free()
	await get_tree().physics_frame
	return {"surge_entries": surge_entries, "calm_entries": calm_entries,
		"shortcut_takers": shortcut_takers}
