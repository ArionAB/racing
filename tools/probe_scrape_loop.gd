extends Node
## Buclele de contact (docs/feel_checklist.md: scrape-sparks si side-rubbing,
## partea de sunet): razuirea pe perete si frecarea intre masini.
##
## Headless nu se aude nimic, deci sonda citeste playerul REAL al buclei
## (`AudioManager.loop_info`: playing, volume_db, pitch_scale, starts, stops) —
## nu o variabila a nodului de control.
##
## Verifica:
##   1. razuire reala pe un perete (15 grade, 16 si 8 m/s): bucla `scrape` canta cat
##      dureaza contactul, mai tare si mai ascutit la viteza mai mare;
##   2. dupa ce contactul se termina, bucla se opreste repede (sub 0,3 s);
##   3. contact care palpaie (3 tick-uri da, 2 nu, 1 s): o singura pornire, zero
##      opriri, volumul nu cade sub -6 dB fata de maxim;
##   4. un gol REAL (0,4 s) opreste bucla, iar urmatorul contact o reporneste;
##   5. frecare intre masini: bucla `rub` canta, `scrape` ramane tacuta, si invers;
##   6. doar jucatorul: o masina AI care razuie nu porneste nimic; cursa oprita
##      (`racing` fals) stinge ambele bucle.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeScrapeLoop.tscn

const ImpactSoundScript := preload("res://scenes/race/impact_sound.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	print("")
	print("=== Bucle de contact: razuire si frecare ===")
	await _test_real_wall()
	await _test_flicker()
	await _test_rub_and_rules()
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


func _spawn(parent: Node, pos: Vector3, yaw: float, player: bool) -> Car:
	var car := Car.new()
	parent.add_child(car)
	car.global_position = pos
	car.rotation.y = yaw
	car.race_active = true
	car.is_player = player
	return car


func _wait(seconds: float) -> void:
	for _f in int(round(seconds / STEP)):
		await get_tree().physics_frame


## O razuire pe peretele de la z = -20, la 15 grade, cu viteza data. Intoarce
## {db, pitch, playing_frames, contact_frames} masurate pe playerul buclei.
func _scrape_run(speed: float) -> Dictionary:
	var world := Node3D.new()
	add_child(world)
	world.add_child(_box(Vector3(600, 1, 600), Vector3(0, -0.5, 0)))
	world.add_child(_box(Vector3(400, 3, 1), Vector3(0, 1.5, -20.5)))
	await get_tree().physics_frame
	var car := _spawn(world, Vector3(-speed * 0.45 - 5.0, 0.7, -17.6), -PI * 0.5, true)
	var snd := ImpactSoundScript.new()
	world.add_child(snd)
	snd.setup(car, [car])
	await _wait(0.8)
	car.linear_velocity = Vector3.ZERO
	var dir := Vector3(cos(deg_to_rad(15.0)), 0, -sin(deg_to_rad(15.0)))
	car.rotation.y = atan2(-dir.x, -dir.z)
	var contact := 0
	var covered := 0
	var db_sum := 0.0
	var pitch_sum := 0.0
	var n := 0
	var last_contact_f := -1
	var playing_at: Array[bool] = []
	var touched := false
	for f in 200:
		# Pana la prima atingere ii tinem viteza (frecarea de rulare ar sufoca
		# apropierea lenta); dupa aceea masina face ce vrea fizica.
		if not touched:
			car.linear_velocity = dir * speed
		await get_tree().physics_frame
		var info := AudioManager.loop_info(&"scrape")
		playing_at.append(bool(info["playing"]))
		if car.wall_contact:
			touched = true
		if car.wall_contact and car.wall_scrape_speed > snd.scrape_min_speed:
			contact += 1
			last_contact_f = f
			if info["playing"]:
				covered += 1
			if f > 25 and info["playing"]:
				db_sum += float(info["db"])
				pitch_sum += float(info["pitch"])
				n += 1
	# Cat dupa ULTIMUL cadru de contact mai canta bucla.
	var silent := -1
	for f in range(last_contact_f + 1, playing_at.size()):
		if not playing_at[f]:
			silent = f - last_contact_f
			break
	var out := {"contact": contact, "playing": covered,
		"db": db_sum / maxf(n, 1), "pitch": pitch_sum / maxf(n, 1),
		"silence_frames": silent}
	snd.queue_free()
	world.queue_free()
	await get_tree().physics_frame
	return out


func _test_real_wall() -> void:
	print("")
	print("-- 1/2. razuire reala, la doua viteze --")
	var fast := await _scrape_run(16.0)
	var slow := await _scrape_run(8.0)
	print("  16 m/s: contact %d cadre, canta %d, %.1f dB, pitch %.2f, tace dupa %d cadre"
		% [fast["contact"], fast["playing"], fast["db"], fast["pitch"], fast["silence_frames"]])
	print("   8 m/s: contact %d cadre, canta %d, %.1f dB, pitch %.2f, tace dupa %d cadre"
		% [slow["contact"], slow["playing"], slow["db"], slow["pitch"], slow["silence_frames"]])
	_check(int(fast["contact"]) >= 20, "contact real (%d cadre)" % int(fast["contact"]))
	_check(int(fast["playing"]) >= int(fast["contact"]) * 0.6 - 40,
		"bucla canta cat tine contactul (%d / %d)" % [int(fast["playing"]), int(fast["contact"])])
	_check(float(fast["db"]) > float(slow["db"]) + 1.5,
		"mai tare la viteza mare (%.1f > %.1f dB)" % [float(fast["db"]), float(slow["db"])])
	_check(float(fast["pitch"]) > float(slow["pitch"]) + 0.08,
		"mai ascutit la viteza mare (%.2f > %.2f)" % [float(fast["pitch"]), float(slow["pitch"])])
	var fs := int(fast["silence_frames"])
	_check(fs > 0 and fs <= 18, "dupa contact tace in %d cadre (%.2f s, limita 0.30 s)"
		% [fs, float(fs) * STEP])


## Masina de proba fara fizica: nu e in arbore, deci starea de contact o scriu eu.
func _stub_car(player: bool) -> Car:
	var car := Car.new()
	car.is_player = player
	return car


func _test_flicker() -> void:
	print("")
	print("-- 3/4. contact care palpaie, gol real --")
	var player := _stub_car(true)
	var snd := ImpactSoundScript.new()
	add_child(snd)
	snd.setup(player, [player])
	await get_tree().physics_frame
	var base := AudioManager.loop_info(&"scrape")
	var starts0 := int(base["starts"])
	var stops0 := int(base["stops"])
	player.wall_scrape_speed = 12.0
	var max_db := -INF
	var min_db := INF
	for f in 60:
		# 3 tick-uri da, 2 tick-uri nu.
		player.wall_contact = (f % 5) < 3
		await get_tree().physics_frame
		if f >= 12:
			var info := AudioManager.loop_info(&"scrape")
			max_db = maxf(max_db, float(info["db"]))
			min_db = minf(min_db, float(info["db"]))
	var info := AudioManager.loop_info(&"scrape")
	print("  palpaire: porniri %d, opriri %d, volum %.1f .. %.1f dB"
		% [int(info["starts"]) - starts0, int(info["stops"]) - stops0, min_db, max_db])
	_check(int(info["starts"]) - starts0 == 1, "o singura pornire in 1 s de palpaire")
	_check(int(info["stops"]) - stops0 == 0, "zero opriri in timpul palpairii")
	_check(max_db - min_db < 6.0, "volumul nu cade cu mai mult de 6 dB (%.1f)" % (max_db - min_db))
	# Gol real: 0,4 s fara contact.
	player.wall_contact = false
	await _wait(0.4)
	var gap := AudioManager.loop_info(&"scrape")
	_check(not gap["playing"] and int(gap["stops"]) - stops0 == 1, "un gol de 0,4 s opreste bucla")
	player.wall_contact = true
	await _wait(0.2)
	var back := AudioManager.loop_info(&"scrape")
	_check(back["playing"] and int(back["starts"]) - starts0 == 2, "urmatorul contact o reporneste")
	player.wall_contact = false
	await _wait(0.4)
	snd.queue_free()
	await get_tree().physics_frame


func _test_rub_and_rules() -> void:
	print("")
	print("-- 5/6. frecare, doar jucatorul, cursa oprita --")
	var player := _stub_car(true)
	var rival := _stub_car(false)
	var snd := ImpactSoundScript.new()
	add_child(snd)
	snd.setup(player, [player, rival])
	player.rub_car = rival
	player.rub_speed = 6.0
	await _wait(0.3)
	var rub := AudioManager.loop_info(&"rub")
	var scr := AudioManager.loop_info(&"scrape")
	_check(rub["playing"], "bucla de frecare canta")
	_check(not scr["playing"], "razuirea de perete ramane tacuta")
	var rub_db_a := float(rub["db"])
	player.rub_speed = 9.5
	await _wait(0.3)
	_check(float(AudioManager.loop_info(&"rub")["db"]) > rub_db_a + 1.0,
		"frecarea mai rapida e mai tare (%.1f -> %.1f dB)"
		% [rub_db_a, float(AudioManager.loop_info(&"rub")["db"])])
	# Cursa oprita stinge totul.
	snd.racing = func() -> bool: return false
	player.wall_contact = true
	player.wall_scrape_speed = 12.0
	await _wait(0.4)
	_check(not AudioManager.loop_info(&"rub")["playing"]
		and not AudioManager.loop_info(&"scrape")["playing"], "racing = fals stinge ambele bucle")
	snd.racing = func() -> bool: return true
	# Doar jucatorul: un AI care razuie nu porneste nimic.
	player.wall_contact = false
	player.rub_car = null
	player.rub_speed = 0.0
	rival.wall_contact = true
	rival.wall_scrape_speed = 14.0
	rival.rub_car = player
	rival.rub_speed = 8.0
	await _wait(0.4)
	_check(not AudioManager.loop_info(&"scrape")["playing"]
		and not AudioManager.loop_info(&"rub")["playing"],
		"o masina AI care razuie sau se frecheaza nu porneste buclele")
	snd.queue_free()
	await get_tree().physics_frame
