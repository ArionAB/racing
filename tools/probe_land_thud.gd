extends Node
## Bufnitura de aterizare dupa viteza de cadere (docs/feel_checklist.md:
## jump-skill, partea de sunet).
##
## Verifica:
##   1. planul (`AudioManager.plan_land`): gol sub 6 m/s; volumul creste si
##      pitch-ul scade cu viteza de cadere; stratul greu (`land_heavy`) lipseste
##      la o cadere mica si intra la una mare; puterea totala nu scade;
##   2. conducta reala: un Car lasat sa cada de la doua inaltimi scoate `land`
##      (volum/pitch dupa viteza masurata din `landed`), cu `land_heavy` doar la
##      cea mare; sunetul vechi fix a disparut (un singur `land` pe aterizare),
##      iar playerul real din pool poarta volumul din jurnal;
##   3. o masina AI care aterizeaza nu scoate nimic.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLandThud.tscn

const ImpactSoundScript := preload("res://scenes/race/impact_sound.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	print("")
	print("=== Aterizare: bufnitura dupa viteza de cadere ===")
	_test_plan()
	await _test_real_drop()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _entry(plan: Array[Dictionary], sfx: StringName) -> Dictionary:
	for e in plan:
		if e["name"] == sfx:
			return e
	return {}


func _power(plan: Array[Dictionary]) -> float:
	var p := 0.0
	for e in plan:
		p += pow(10.0, float(e["db"]) / 10.0)
	return p


func _test_plan() -> void:
	print("")
	print("-- 1. plan --")
	_check(AudioManager.plan_land(5.99).is_empty(), "sub 6 m/s nu suna")
	_check(not AudioManager.plan_land(6.0).is_empty(), "6 m/s suna")
	var small := AudioManager.plan_land(7.0)
	var mid := AudioManager.plan_land(12.0)
	var big := AudioManager.plan_land(22.0)
	_check(_entry(small, &"land_heavy").is_empty(), "cadere mica: fara strat greu")
	_check(not _entry(big, &"land_heavy").is_empty(), "cadere mare: cu strat greu")
	var d_small := float(_entry(small, &"land")["db"])
	var d_mid := float(_entry(mid, &"land")["db"])
	var d_big := float(_entry(big, &"land")["db"])
	var p_small := float(_entry(small, &"land")["pitch"])
	var p_big := float(_entry(big, &"land")["pitch"])
	print("  land: 7 m/s %.1f dB, 12 m/s %.1f dB, 22 m/s %.1f dB; pitch %.2f -> %.2f"
		% [d_small, d_mid, d_big, p_small, p_big])
	_check(d_small < d_mid and d_mid < d_big, "volumul creste cu viteza de cadere")
	_check(d_big - d_small > 8.0, "peste 8 dB intre cadere mica si mare")
	_check(p_big < p_small - 0.2, "pitch-ul scade cu viteza de cadere")
	var prev := 0.0
	var mono := true
	var f := 6.0
	while f <= 30.0:
		var p := _power(AudioManager.plan_land(f))
		if p < prev - 1.0e-9:
			mono = false
		prev = p
		f += 0.1
	_check(mono, "puterea totala nu scade niciodata (6 .. 30 m/s)")


func _box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	return b


## Lasa o masina sa cada de la `height` m. Intoarce {fall, log} unde log sunt
## sunetele aparute de la prima cadere.
func _drop(world: Node3D, x: float, height: float, player: bool) -> Dictionary:
	var car := Car.new()
	world.add_child(car)
	car.global_position = Vector3(x, height, 0)
	car.race_active = true
	car.is_player = player
	var snd := ImpactSoundScript.new()
	world.add_child(snd)
	# Masina AI cade in alta parte decat jucatorul (un stub, fara fizica).
	var watcher: Car = car if player else Car.new()
	watcher.is_player = true
	snd.setup(watcher, [car])
	var falls: Array[float] = []
	car.landed.connect(func(_c: Car, v: float) -> void: falls.append(v))
	AudioManager.sfx_log.clear()
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
	var log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
	var out := {"fall": falls[0] if not falls.is_empty() else 0.0, "falls": falls.size(),
		"log": log}
	snd.queue_free()
	car.queue_free()
	if watcher != car:
		watcher.free()
	await get_tree().physics_frame
	return out


func _count(log: Array, sfx: StringName) -> int:
	var n := 0
	for e in log:
		if e["name"] == sfx:
			n += 1
	return n


func _first(log: Array, sfx: StringName) -> Dictionary:
	for e in log:
		if e["name"] == sfx:
			return e
	return {}


func _test_real_drop() -> void:
	print("")
	print("-- 2/3. cadere reala --")
	var world := Node3D.new()
	add_child(world)
	world.add_child(_box(Vector3(2000, 1, 400), Vector3(0, -0.5, 0)))
	await get_tree().physics_frame
	var low := await _drop(world, 0.0, 1.3, true)
	var high := await _drop(world, 100.0, 14.0, true)
	var ai := await _drop(world, 200.0, 14.0, false)
	print("  mica: cadere %.1f m/s, sunete %s" % [float(low["fall"]),
		(low["log"] as Array).map(func(e: Dictionary) -> StringName: return e["name"])])
	print("  mare: cadere %.1f m/s, sunete %s" % [float(high["fall"]),
		(high["log"] as Array).map(func(e: Dictionary) -> StringName: return e["name"])])
	_check(int(low["falls"]) >= 1 and int(high["falls"]) >= 1, "ambele cazaturi au emis `landed`")
	_check(float(high["fall"]) > float(low["fall"]) + 4.0, "a doua cadere e mai rapida")
	var ll: Array = low["log"]
	var hl: Array = high["log"]
	_check(_count(ll, &"land") == 1 and _count(hl, &"land") == 1,
		"un singur `land` pe aterizare (fara sunetul vechi fix)")
	_check(_count(ll, &"land_heavy") == 0, "cadere mica: fara land_heavy")
	_check(_count(hl, &"land_heavy") == 1, "cadere mare: cu land_heavy")
	var l_low := _first(ll, &"land")
	var l_high := _first(hl, &"land")
	if not l_low.is_empty() and not l_high.is_empty():
		_check(float(l_high["db"]) > float(l_low["db"]) + 3.0,
			"mai tare la cadere mare (%.1f > %.1f dB)" % [float(l_high["db"]), float(l_low["db"])])
		_check(float(l_high["pitch"]) < float(l_low["pitch"]),
			"mai grav la cadere mare (%.2f < %.2f)" % [float(l_high["pitch"]), float(l_low["pitch"])])
		var found := false
		for p in AudioManager._pool:
			if p.stream == AudioManager.stream(&"land") \
					and absf(p.volume_db - float(l_high["db"])) < 0.01:
				found = true
		_check(found, "playerul din pool poarta `land` la volumul din jurnal")
	_check((ai["log"] as Array).is_empty() and int(ai["falls"]) >= 1,
		"masina AI aterizeaza (%d) si nu scoate nimic" % int(ai["falls"]))
	world.queue_free()
