extends RefCounted
## Testul A al sondelor Machu Picchu (brief §7 pasul 1a): PODUL DE FRANGHIE
## (RopeBridgeHazard) pe sol plat, inaintea traseului. Contractul din brief §3:
##
##  1. SAGEATA: sportul (0.9) singur la mijloc coboara mijlocul cu 0.5-0.7 m
##     fata de repaus; Autobuzul (2.6) cu 1.3-1.7 m.
##  2. VALUL: sportul parcat la 1/4 din pod e RIDICAT cu > 0.15 m cand
##     Autobuzul ajunge la mijloc (masina usoara ridicata de cea grea).
##  3. BALANSUL: intrare descentrata cu 1.5 m la 15 m/s: deplasarea laterala
##     a mijlocului atinge 0.8-1.4 m si se stinge sub 0.1 m in < 4 s dupa ce
##     masina a parasit tablierul.
##  4. SIGURANTA: nicio masina sub tablier (< -0.5 m fata de scanduri) sau
##     la > 2 m peste el, nicio viteza > 40 m/s; sportul si Autobuzul trec
##     podul cap-coada la 15 si la 30 m/s fara sa se opreasca (> 5 m/s pe
##     tablier).
##  5. COSTUL: tick-ul podului sub 300 us in medie cu 4 masini pe el.
##  + CAPTURA (doar cu fereastra — randarea nu merge headless, vezi
##     tools/snapshot.gd): Autobuzul la mijloc, sportul la sfert, camera ca
##     de urmarire, in snapshots/machu_pod_val.png. Memoria
##     `efecte-invizibile-nu-se-numara`: cifra nu spune daca se VEDE.
##
## Lumea: doua placi de sol (plecare z in [0, 70], sosire z in [-35, -110])
## cu GOL intre ele; podul de la (0,0,0) la (0,0,-35), 5.5 m lat. Masinile
## merg spre -Z.

const Lib := preload("res://tools/probe_machu_lib.gd")
const BridgeScript := preload("res://scenes/hazards/rope_bridge_hazard.gd")

const NEAR := Vector3(0.0, 0.0, 0.0)
const FAR := Vector3(0.0, 0.0, -35.0)
const MID_Z: float = -17.5
const QUARTER_Z: float = -8.75
const STEP: float = 1.0 / 60.0
## Limitele de siguranta (m fata de scanduri, m/s).
const UNDER_DECK: float = -0.5
const OVER_DECK: float = 2.0
const MAX_SPEED: float = 40.0

var lib: Lib
var root: Node
var world: Node3D
var bridge: RopeBridgeHazard
## Cel mai rau caz de siguranta vazut in ORICE test (verdictul 4 se da pe tot).
var worst_under: float = INF
var worst_over: float = -INF
var worst_speed: float = 0.0
## `-- --only=sag|wave|sway|cross|cost|capture`: ruleaza un singur test (tuning).
var only: String = ""
## `-- --trace`: tipareste starea la fiecare 6 cadre in testele cu miscare.
var trace: bool = false


func run(lib_in: Lib) -> void:
	lib = lib_in
	root = lib.root
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a == "--trace":
			trace = true
	print("")
	print("-- A. podul de franghie --")
	_build_world()
	await root.get_tree().physics_frame
	await root.get_tree().physics_frame
	print("  tablier %.1f m x %.1f m, %d placi, sageata de repaus %.2f m"
		% [bridge.deck_length(), bridge.deck_width, bridge.plate_count, bridge.rest_sag])
	if _want("sag"):
		await _test_sag()
	if _want("wave"):
		await _test_wave()
	if _want("sway"):
		await _test_sway()
	if _want("cross"):
		await _test_crossings()
	if _want("cost"):
		await _test_cost()
	lib.check(worst_under > UNDER_DECK,
		"siguranta: nicio masina sub tablier (min %.2f m fata de scanduri)" % worst_under)
	lib.check(worst_over < OVER_DECK,
		"siguranta: nicio masina la > 2 m peste tablier (max %.2f m)" % worst_over)
	lib.check(worst_speed < MAX_SPEED,
		"siguranta: nicio viteza > 40 m/s (max %.1f m/s)" % worst_speed)
	await _capture()
	world.queue_free()
	await root.get_tree().physics_frame


func _want(test: String) -> bool:
	return only == "" or only == test


func _trace(t: float, cars: Array) -> void:
	if not trace:
		return
	var parts: Array[String] = []
	for c in cars:
		var car := c as Car
		var dc := bridge.deck_coords(car.global_position)
		parts.append("[%s u=%.2f x=%+.2f y=%+.2f v=(%.1f %.1f %.1f) sol=%d]" % [
			"bus" if car.mass_factor > 2.0 else "spt", dc.z, dc.x, dc.y,
			car.linear_velocity.x, car.linear_velocity.y, car.linear_velocity.z,
			car.wheels_on_ground])
	print("    t=%.2f sag=%.2f sway=%+.2f %s" % [t, bridge.sag_amplitude(), bridge.sway(), " ".join(parts)])


func _build_world() -> void:
	world = Node3D.new()
	world.name = "LumePod"
	root.add_child(world)
	var saved_root: Node = lib.root
	lib.root = world
	lib.slab(Vector3(40.0, 1.0, 70.0), Vector3(0.0, 0.0, 35.0))
	lib.slab(Vector3(40.0, 1.0, 75.0), Vector3(0.0, 0.0, -72.5))
	lib.root = saved_root
	bridge = BridgeScript.new()
	bridge.name = "PodFranghie"
	bridge.near_end = NEAR
	bridge.far_end = FAR
	bridge.deck_width = 5.5
	world.add_child(bridge)


## Un tick de urmarire a masinilor: actualizeaza cel mai rau caz de siguranta
## si intoarce coordonatele de tablier ale fiecareia (x, y, u).
func _watch(cars: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for c in cars:
		var car := c as Car
		var dc := bridge.deck_coords(car.global_position)
		var local_z := car.global_position.z
		var on_span := local_z < NEAR.z - 0.5 and local_z > FAR.z + 0.5
		if on_span:
			worst_under = minf(worst_under, dc.y)
			worst_over = maxf(worst_over, dc.y)
		worst_speed = maxf(worst_speed, car.linear_velocity.length())
		out.append(dc)
	return out


func _settle_bridge() -> void:
	# fara nimeni pe pod, modul global si balansul se sting singure
	var frames := 0
	while frames < int(6.0 / STEP):
		await root.get_tree().physics_frame
		frames += 1
		if absf(bridge.sag_amplitude()) < 0.01 and absf(bridge.sway()) < 0.02 \
				and frames > 30:
			break


# ------------------------------------------------------------------ 1. sageata

func _test_sag() -> void:
	for entry: Array in [["sportul", 0.9, 0.5, 0.7], ["Autobuzul", 2.6, 1.3, 1.7]]:
		var car := lib.spawn(Vector3(0.0, 0.7, MID_Z), entry[1], 0.0)
		var frames := int(4.0 / STEP)
		for _f in frames:
			await root.get_tree().physics_frame
			_watch([car])
		var sag := bridge.sag_at(0.5)
		var dc := bridge.deck_coords(car.global_position)
		print("  %s la mijloc (u=%.2f): sageata %.2f m (mod global %.2f), masina la %+.2f m de scanduri, pe sol %s"
			% [entry[0], dc.z, sag, bridge.sag_amplitude(), dc.y, str(car.is_on_floor())])
		lib.check(sag >= entry[2] and sag <= entry[3],
			"%s singur la mijloc: sageata %.2f in [%.1f, %.1f]" % [entry[0], sag, entry[2], entry[3]])
		await lib.free_cars([car])
		await _settle_bridge()


# ------------------------------------------------------------------ 2. valul

func _test_wave() -> void:
	var sport := lib.spawn(Vector3(1.5, 0.7, QUARTER_Z), 0.9, 0.0)
	for _f in int(4.0 / STEP):
		await root.get_tree().physics_frame
		_watch([sport])
	var y0 := sport.global_position.y
	var drop0 := bridge.drop_at(0.25)
	# Autobuzul intra pe partea cealalta, la 12 m/s, si trece pe langa sport.
	var bus := lib.spawn(Vector3(-1.3, 0.7, 40.0), 2.6, 12.0)
	var rise_car := -INF
	var rise_deck := -INF
	var u_bus_at_peak := 0.0
	var frames := 0
	while frames < int(7.0 / STEP):
		await root.get_tree().physics_frame
		frames += 1
		_watch([sport, bus])
		if frames % 6 == 0:
			_trace(frames * STEP, [sport, bus])
		var r := sport.global_position.y - y0
		if r > rise_car:
			rise_car = r
			u_bus_at_peak = bridge.deck_coords(bus.global_position).z
		rise_deck = maxf(rise_deck, drop0 - bridge.drop_at(0.25))
	var dc := bridge.deck_coords(sport.global_position)
	print("  valul: sportul la u=0.25 urcat cu %.2f m (tablierul acolo cu %.2f m); autobuzul era la u=%.2f la varf; sportul ramas pe scanduri la %+.2f m, x=%.2f"
		% [rise_car, rise_deck, u_bus_at_peak, dc.y, dc.x])
	lib.check(rise_car > 0.15, "valul ridica sportul de la sfert cu > 0.15 m (%.2f)" % rise_car)
	lib.check(dc.y > UNDER_DECK and absf(dc.x) < 2.75, "sportul ramane pe tablier dupa val")
	await lib.free_cars([sport, bus])
	await _settle_bridge()


# ------------------------------------------------------------------ 3. balansul

func _test_sway() -> void:
	var sport := lib.spawn(Vector3(1.5, 0.7, 40.0), 0.9, 15.0)
	var peak := 0.0
	var car_x_max := 0.0
	var t := 0.0
	var t_leave := -1.0
	var t_last_loud := -1.0
	var fell := false
	while t < 10.0:
		await root.get_tree().physics_frame
		t += STEP
		_watch([sport])
		var s := bridge.sway()
		peak = maxf(peak, absf(s))
		var dc := bridge.deck_coords(sport.global_position)
		if sport.global_position.z < FAR.z - 1.0 and t_leave < 0.0:
			t_leave = t
		if t_leave < 0.0 and sport.global_position.z < NEAR.z:
			car_x_max = maxf(car_x_max, absf(dc.x))
			if dc.y < UNDER_DECK:
				fell = true
		if absf(s) >= 0.1:
			t_last_loud = t
		if t_leave > 0.0 and t - t_leave > 5.0:
			break
	var settle := t_last_loud - t_leave if t_leave > 0.0 else INF
	print("  balans: varf %.2f m, masina la cel mult %.2f m de axa tablierului, iesita la t=%.2f, sub 0.1 m la +%.2f s, cazuta %s"
		% [peak, car_x_max, t_leave, settle, str(fell)])
	lib.check(peak >= 0.8 and peak <= 1.4, "balans lateral cu varf in [0.8, 1.4] m (%.2f)" % peak)
	lib.check(t_leave > 0.0 and settle < 4.0, "balansul se stinge sub 0.1 m in < 4 s (%.2f s)" % settle)
	lib.check(not fell, "masina descentrata nu cade de pe pod")
	await lib.free_cars([sport])
	await _settle_bridge()


# ------------------------------------------------------------------ 4. traversari

func _test_crossings() -> void:
	for entry: Array in [["sportul", 0.9, 15.0], ["sportul", 0.9, 30.0],
			["Autobuzul", 2.6, 15.0], ["Autobuzul", 2.6, 30.0]]:
		var speed: float = entry[2]
		var car := lib.spawn(Vector3(0.0, 0.7, 30.0), entry[1], speed)
		var v_min := INF
		var y_min := INF
		var y_max := -INF
		var air := 0
		var t := 0.0
		var reached := false
		var sag_max := 0.0
		while t < 8.0:
			await root.get_tree().physics_frame
			t += STEP
			var dc := _watch([car])[0]
			var z := car.global_position.z
			if z < NEAR.z and z > FAR.z:
				v_min = minf(v_min, car.horizontal_speed())
				y_min = minf(y_min, dc.y)
				y_max = maxf(y_max, dc.y)
				if not car.is_on_floor():
					air += 1
				sag_max = maxf(sag_max, bridge.sag_amplitude())
			if z < FAR.z - 10.0:
				reached = true
				break
		print("  %s la %.0f m/s: traversat %s in %.2f s, viteza minima pe pod %.1f, fata de scanduri [%+.2f, %+.2f], in aer %d cadre, sageata max %.2f"
			% [entry[0], speed, str(reached), t, v_min, y_min, y_max, air, sag_max])
		lib.check(reached and v_min > 5.0,
			"%s trece podul cap-coada la %.0f m/s fara sa se opreasca" % [entry[0], speed])
		await lib.free_cars([car])
		await _settle_bridge()


# ------------------------------------------------------------------ 5. costul

func _test_cost() -> void:
	var cars: Array = []
	var k := 0
	for u: float in [0.2, 0.4, 0.6, 0.8]:
		var x := 0.8 if k % 2 == 0 else -0.8
		cars.append(lib.spawn(Vector3(x, 0.7, -u * 35.0), 0.9 if k % 2 == 0 else 2.6, 0.0))
		k += 1
	await lib.wait(1.5)
	var total := 0
	var worst := 0
	var n := int(3.0 / STEP)
	for _f in n:
		await root.get_tree().physics_frame
		_watch(cars)
		total += bridge.last_tick_usec
		worst = maxi(worst, bridge.last_tick_usec)
	print("  tick pod: mediu %d us, varf %d us (%d masini pe tablier, sageata %.2f m)"
		% [total / n, worst, bridge.cars_on_deck().size(), bridge.sag_at(0.5)])
	lib.check(bridge.cars_on_deck().size() == 4, "toate cele 4 masini sunt numarate pe tablier")
	lib.check(total / n < 300, "tick-ul podului sub 300 us in medie cu 4 masini")
	await lib.free_cars(cars)
	await _settle_bridge()


# ------------------------------------------------------------------ captura

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		print("  captura: sarita (headless; ruleaza fara --headless pentru snapshots/machu_pod_val.png)")
		return
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.74, 0.86)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.75, 0.8)
	e.ambient_light_energy = 0.7
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	world.add_child(sun)
	# apa la -20 m sub pod, ca sa se vada golul
	var saved_root: Node = lib.root
	lib.root = world
	lib.slab(Vector3(120.0, 1.0, 40.0), Vector3(0.0, -20.0, -17.5))
	lib.root = saved_root
	var sport := lib.spawn(Vector3(1.5, 0.7, QUARTER_Z), 0.9, 0.0)
	var bus := lib.spawn(Vector3(-1.2, 0.7, MID_Z), 2.6, 0.0)
	await lib.wait(3.0)
	var cam := Camera3D.new()
	cam.fov = 68.0
	world.add_child(cam)
	cam.global_position = Vector3(1.5, 9.5, QUARTER_Z + 13.0)
	cam.look_at(Vector3(0.0, -0.5, MID_Z - 4.0), Vector3.UP)
	cam.current = true
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/machu_pod_val.png" % dir
	img.save_png(out)
	print("  SNAPSHOT: %s (sageata %.2f m, balans %.2f m, sport la %+.2f m)"
		% [out, bridge.sag_at(0.5), bridge.sway(),
			bridge.deck_coords(sport.global_position).y])
	await lib.free_cars([sport, bus])
