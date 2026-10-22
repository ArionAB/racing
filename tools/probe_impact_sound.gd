extends Node
## Impact in straturi (docs/feel_checklist.md: impact-layers, partea de sunet).
##
## Audio-ul headless merge pe un driver "dummy": nu se aude nimic, deci sonda
## masoara STAREA: planul pe care il alege AudioManager (`plan_impact`), jurnalul
## `sfx_log` si, ca sa nu masoare alt obiect, volumul si streamul de pe playerul
## real din pool dupa o redare.
##
## Verifica:
##   1. sub pragul feed-ului (2,5 m/s) planul e gol; la prag, nu;
##   2. stratul dominant urca tap -> crunch -> crash cu puterea;
##   3. puterea totala (suma 10^(dB/10)) NU scade niciodata cu puterea impactului
##      si niciun strat nu e sub -30 dB (nu se reda ceva inaudibil);
##   4. aceeasi varianta nu se repeta de doua ori la rand, in niciun strat, si
##      ambele variante se folosesc; pitch-ul variaza si scade cu puterea;
##   5. conducta reala: o izbitura frontala de perete a jucatorului reda straturi
##      noi + `wall_hit` o singura data (nu mai exista sunetul vechi fix), iar
##      volumul de pe playerul din pool e cel din jurnal;
##   6. o ciocnire intre masini scoate UN singur set de sunete (desi o emit ambele
##      masini), cu corpul `bump` si clinchetul `metal_hit`.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeImpactSound.tscn

const ImpactSoundScript := preload("res://scenes/race/impact_sound.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _sim_clock() -> float:
	return float(Engine.get_physics_frames()) * STEP


func _ready() -> void:
	print("")
	print("=== Impact in straturi ===")
	AudioManager.clock = _sim_clock
	_test_floor()
	_test_layers_and_monotonic()
	_test_variants_and_pitch()
	await _test_wall_pipeline()
	await _test_car_pipeline()
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
	AudioManager.sfx_log.clear()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _power(plan: Array[Dictionary], only_main: bool = false) -> float:
	var p := 0.0
	for e in plan:
		if only_main and e["role"] != &"main":
			continue
		p += pow(10.0, float(e["db"]) / 10.0)
	return p


func _dominant(plan: Array[Dictionary]) -> StringName:
	var best := -INF
	var layer: StringName = &""
	for e in plan:
		if e["role"] == &"main" and float(e["db"]) > best:
			best = float(e["db"])
			layer = e["layer"]
	return layer


func _has(plan: Array, sfx: StringName) -> bool:
	for e in plan:
		if e["name"] == sfx:
			return true
	return false


func _test_floor() -> void:
	print("")
	print("-- 1. pragul --")
	for kind: StringName in [&"wall", &"car"]:
		_check(AudioManager.plan_impact(kind, 2.49).is_empty(), "%s: 2.49 m/s nu suna" % kind)
		_check(AudioManager.plan_impact(kind, 0.0).is_empty(), "%s: 0 m/s nu suna" % kind)
		_check(not AudioManager.plan_impact(kind, 2.5).is_empty(), "%s: 2.5 m/s suna" % kind)


func _test_layers_and_monotonic() -> void:
	print("")
	print("-- 2/3. straturi dupa putere, putere totala monotona --")
	for kind: StringName in [&"wall", &"car"]:
		var d3 := _dominant(AudioManager.plan_impact(kind, 3.0))
		var d9 := _dominant(AudioManager.plan_impact(kind, 9.0))
		var d20 := _dominant(AudioManager.plan_impact(kind, 20.0))
		print("  %s: 3 m/s -> %s, 9 m/s -> %s, 20 m/s -> %s" % [kind, d3, d9, d20])
		_check(d3 == &"tap", "%s: usor = tap" % kind)
		_check(d9 == &"crunch", "%s: mediu = crunch" % kind)
		_check(d20 == &"crash", "%s: tare = crash" % kind)
		var prev := -1.0
		var prev_main := -1.0
		var mono := true
		var audible := true
		var first_bad := 0.0
		var s := 2.5
		while s <= 30.0:
			var plan := AudioManager.plan_impact(kind, s)
			var p := _power(plan)
			var pm := _power(plan, true)
			if p < prev - 1.0e-9 or pm < prev_main - 1.0e-9:
				if mono:
					first_bad = s
				mono = false
			prev = p
			prev_main = pm
			for e in plan:
				if float(e["db"]) < -30.0:
					audible = false
					first_bad = s
			s += 0.1
		_check(mono, "%s: puterea totala (si cea a straturilor principale) nu scade cu puterea impactului, 2.5 .. 30 m/s (abatere la %.1f)" % [kind, first_bad])
		_check(audible, "%s: niciun strat sub -30 dB" % kind)
		var p_lo := _power(AudioManager.plan_impact(kind, 2.5))
		var p_hi := _power(AudioManager.plan_impact(kind, 22.0))
		_check(10.0 * log(p_hi / p_lo) / log(10.0) > 10.0,
			"%s: de la prag la plafon volumul creste cu peste 10 dB" % kind)
	var car_plan := AudioManager.plan_impact(&"car", 14.0)
	var wall_plan := AudioManager.plan_impact(&"wall", 14.0)
	_check(_has(car_plan, &"bump") and _has(car_plan, &"metal_hit"),
		"masina: corpul bump + clinchetul metal_hit raman in plan")
	_check(_has(wall_plan, &"wall_hit") and not _has(wall_plan, &"metal_hit"),
		"perete: wall_hit ca si corp, fara metal_hit")


func _test_variants_and_pitch() -> void:
	print("")
	print("-- 4. variante fara repetitie, pitch --")
	var last: Dictionary = {}
	var seen: Dictionary = {}
	var repeat := false
	for i in 400:
		# Alterneaza puterile ca sa treaca prin toate cele trei straturi.
		var s: float = [3.0, 9.0, 20.0][i % 3]
		for e in AudioManager.plan_impact(&"car", s):
			if e["role"] != &"main":
				continue
			var layer: StringName = e["layer"]
			if last.get(layer, &"") == e["name"]:
				repeat = true
			last[layer] = e["name"]
			seen[e["name"]] = true
	_check(not repeat, "aceeasi varianta nu se repeta de doua ori la rand (400 apeluri, 3 straturi)")
	_check(seen.size() == 6, "toate cele 6 variante se folosesc (%d)" % seen.size())
	var lo := INF
	var hi := -INF
	var sum_soft := 0.0
	var sum_hard := 0.0
	for i in 200:
		for e in AudioManager.plan_impact(&"car", 8.0):
			if e["role"] == &"main":
				lo = minf(lo, float(e["pitch"]))
				hi = maxf(hi, float(e["pitch"]))
		sum_soft += float((AudioManager.plan_impact(&"car", 3.5)[0] as Dictionary)["pitch"])
		sum_hard += float((AudioManager.plan_impact(&"car", 20.0)[0] as Dictionary)["pitch"])
	print("  pitch la 8 m/s: %.3f .. %.3f; medie usor %.3f, tare %.3f"
		% [lo, hi, sum_soft / 200.0, sum_hard / 200.0])
	_check(hi - lo > 0.04, "pitch-ul variaza intre apeluri identice")
	_check(lo > 0.7 and hi < 1.5, "pitch-ul ramane in 0.7 .. 1.5")
	_check(sum_hard < sum_soft, "impactul tare e mai grav decat cel usor")


# ------------------------------------------------------------ conducta reala

func _box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	return b


func _spawn(parent: Node, pos: Vector3, yaw: float = 0.0, player: bool = false) -> Car:
	var car := Car.new()
	parent.add_child(car)
	car.global_position = pos
	car.rotation.y = yaw
	car.race_active = true
	car.is_player = player
	return car


func _settle(cars: Array) -> void:
	for _f in 48:
		await get_tree().physics_frame
	for c in cars:
		(c as Car).linear_velocity = Vector3.ZERO


func _test_wall_pipeline() -> void:
	print("")
	print("-- 5. izbitura frontala de perete, conducta reala --")
	var world := Node3D.new()
	add_child(world)
	world.add_child(_box(Vector3(600, 1, 600), Vector3(0, -0.5, 0)))
	world.add_child(_box(Vector3(200, 3, 1), Vector3(0, 1.5, -20.5)))
	await get_tree().physics_frame
	var car := _spawn(world, Vector3(0, 0.7, -8), 0.0, true)
	var snd := ImpactSoundScript.new()
	snd.clock = _sim_clock
	world.add_child(snd)
	snd.setup(car, [car])
	await _settle([car])
	AudioManager.sfx_log.clear()
	car.linear_velocity = Vector3(0, 0, -14)
	for _f in 90:
		await get_tree().physics_frame
	var log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
	var names: Array = log.map(func(e: Dictionary) -> StringName: return e["name"])
	print("  sunete: ", names)
	var mains := log.filter(func(e: Dictionary) -> bool:
		return String(e["name"]).begins_with("impact_"))
	_check(not mains.is_empty(), "un strat nou (impact_*) a sunat")
	_check(names.count(&"wall_hit") == 1,
		"wall_hit o singura data (corpul stratului), nu sunetul vechi fix")
	_check(mains.all(func(e: Dictionary) -> bool: return not e["positional"]),
		"peretele ramane 2D")
	_check(names.count(&"bump") == 0 and names.count(&"metal_hit") == 0,
		"fara bump / metal_hit la perete")
	var hit: Dictionary = {}
	for e in log:
		if e["name"] == &"wall_hit":
			hit = e
	if not hit.is_empty():
		# Playerul REAL din pool: acelasi stream si acelasi volum ca in jurnal.
		var found := false
		for p in AudioManager._pool:
			if p.stream == AudioManager.stream(&"wall_hit") \
					and absf(p.volume_db - float(hit["db"])) < 0.01:
				found = true
		_check(found, "playerul din pool poarta wall_hit la volumul din jurnal (%.1f dB)"
			% float(hit["db"]))
	snd.queue_free()
	world.queue_free()
	await get_tree().physics_frame


func _test_car_pipeline() -> void:
	print("")
	print("-- 6. T-bone intre masini: un singur set de sunete --")
	var world := Node3D.new()
	add_child(world)
	world.add_child(_box(Vector3(600, 1, 600), Vector3(0, -0.5, 0)))
	await get_tree().physics_frame
	var a := _spawn(world, Vector3(30, 0.7, 10), -PI * 0.5, true)
	var b := _spawn(world, Vector3(37, 0.7, 10))
	var emits := [0]
	var count := func(_c: Car, k: StringName, _s: float, _n: Vector3, _p: Vector3,
			_o: Node) -> void:
		if k == &"car":
			emits[0] += 1
	a.impact.connect(count)
	b.impact.connect(count)
	var snd := ImpactSoundScript.new()
	snd.clock = _sim_clock
	world.add_child(snd)
	snd.setup(a, [a, b])
	await _settle([a, b])
	AudioManager.sfx_log.clear()
	a.linear_velocity = Vector3(10, 0, 0)
	for _f in 72:
		await get_tree().physics_frame
	var log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
	var names: Array = log.map(func(e: Dictionary) -> StringName: return e["name"])
	print("  impact emis de masini: %d, sunete: %s" % [emits[0], names])
	_check(emits[0] >= 2, "ambele masini au emis `impact` (%d)" % emits[0])
	_check(names.count(&"bump") == 1, "bump o singura data pe perechea de masini")
	_check(names.count(&"metal_hit") == 1, "metal_hit o singura data")
	_check(log.any(func(e: Dictionary) -> bool: return String(e["name"]).begins_with("impact_")),
		"un strat principal a sunat")
	snd.queue_free()
	world.queue_free()
	await get_tree().physics_frame
