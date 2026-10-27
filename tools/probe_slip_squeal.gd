extends Node
## Scrasnetul care urmeaza alunecarea REALA (docs/feel_checklist.md, `slip-squeal`):
## volum si pitch dupa viteza laterala / unghiul de derapaj, nu dupa frana de
## mana. Pe sol afanat devine sisait de pietris. Citeste playerele `squeal` si
## `hiss` ale lui CarAudio.
##
## Contractele:
##   1. Mers drept la 25 m/s: niciun player de derapaj nu canta.
##   2. Alunecare la 8 / 20 / 40 de grade (viteza fixata): volumul urca strict cu
##      unghiul (soapta < -22 dB la 8 grade, > -14 dB la 40) si pitch-ul urca.
##   3. Frana de mana apasata dar fara alunecare (viteza aliniata cu botul): TACE.
##      Frana de mana nu e sursa, alunecarea e.
##   4. Franare tare de la 25 m/s: scrasneste (player pornit, > -30 dB).
##   5. Sol afanat (cusatura `override_loose`): la 40 de grade canta sisaitul
##      (`skid_gravel`) si scrasnetul de asfalt tace; pe asfalt invers.
##   6. Adversar: acelasi derapaj, cu >= 3 dB mai incet decat jucatorul.
## Sabotaj (trebuie sa PICE): `-- --off=flat` (volum constant, ca inainte),
## `-- --off=blend` (nu se mai separa sisaitul de scrasnet).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSlipSqueal.tscn

const U := preload("res://tools/probe_audio_util.gd")

var _failed: bool = false
var _off: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--off="):
			_off = a.substr(6)
	U.ground(self)
	await get_tree().physics_frame
	print("")
	print("=== Scrasnet dupa alunecare ===")
	if _off != "":
		print("  (SABOTAJ: %s)" % _off)
	await _test_straight_and_angles()
	await _test_handbrake_not_source()
	await _test_braking()
	await _test_loose()
	await _test_ai()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(player: bool = true) -> Car:
	var car := U.spawn(self, player)
	var au = U.audio(car)
	if _off == "flat":
		au.squeal_db = Vector2(-10.0, -10.0)
		au.hiss_db = Vector2(-10.0, -10.0)
	await U.settle(get_tree())
	return car


## Viteza fixata `speed`, rotita cu `angle_deg` fata de botul masinii.
func _slide(car: Car, speed: float, angle_deg: float, seconds: float) -> void:
	for _f in int(seconds / U.STEP):
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		var v := fwd.normalized().rotated(Vector3.UP, deg_to_rad(angle_deg)) * speed
		car.linear_velocity = Vector3(v.x, car.linear_velocity.y, v.z)
		await get_tree().physics_frame


func _loud(au: Node) -> float:
	var db := -99.0
	for p in [au.squeal, au.hiss]:
		if p != null and p.playing:
			db = maxf(db, p.volume_db)
	return db


func _test_straight_and_angles() -> void:
	print("")
	print("-- 1-2. drept si unghiuri de derapaj --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	await _slide(car, 25.0, 0.0, 0.6)
	var playing: bool = (au.squeal != null and au.squeal.playing) or (au.hiss != null and au.hiss.playing)
	_check(not playing, "mers drept la 25 m/s: tace (slip %.3f)" % au.slip_amount)
	var vols: Array[float] = []
	var pitches: Array[float] = []
	for ang in [8.0, 20.0, 40.0]:
		await _slide(car, 25.0, ang, 0.6)
		vols.append(_loud(au))
		pitches.append(au.squeal.pitch_scale if au.squeal != null else 0.0)
		print("  %.0f grade: volum %.1f dB, pitch %.2f, slip %.2f" % [ang, vols[-1], pitches[-1], au.slip_amount])
		await _slide(car, 25.0, 0.0, 0.6)
	_check(vols[1] - vols[0] >= 3.0 and vols[2] - vols[1] >= 1.0, "volumul urca cu unghiul (>= 3 dB, apoi >= 1 dB)")
	_check(vols[0] < -22.0, "la 8 grade doar soapta (< -22 dB)")
	_check(vols[2] > -14.0, "la 40 de grade scrasneste plin (> -14 dB)")
	_check(pitches[0] < pitches[1] and pitches[1] < pitches[2], "pitch-ul urca cu alunecarea")
	car.queue_free()
	await get_tree().physics_frame


func _test_handbrake_not_source() -> void:
	print("")
	print("-- 3. frana de mana fara alunecare --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	U.drv(car).drift = true
	await _slide(car, 22.0, 0.0, 0.7)
	var playing: bool = (au.squeal != null and au.squeal.playing) or (au.hiss != null and au.hiss.playing)
	print("  is_drifting=%s, slip %.3f" % [car.is_drifting, au.slip_amount])
	_check(not playing, "cu frana de mana trasa dar fara alunecare nu scrasneste")
	car.queue_free()
	await get_tree().physics_frame


func _test_braking() -> void:
	print("")
	print("-- 4. franare tare --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	for _f in 30:
		U.pin_speed(car, 25.0)
		await get_tree().physics_frame
	U.drv(car).throttle = -1.0
	var best := -99.0
	for _f in 40:
		await get_tree().physics_frame
		best = maxf(best, _loud(au))
	print("  cel mai tare scrasnet la franare: %.1f dB (viteza acum %.1f m/s)" % [best, car.horizontal_speed()])
	_check(best > -30.0, "franarea tare scrasneste (> -30 dB)")
	car.queue_free()
	await get_tree().physics_frame


func _test_loose() -> void:
	print("")
	print("-- 5. sol afanat: sisait, nu scrasnet --")
	var car := await _spawn()
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	await _slide(car, 25.0, 40.0, 0.5)
	var asphalt_squeal: bool = au.squeal != null and au.squeal.playing
	if _off != "blend":
		au.override_loose = 1
	await _slide(car, 25.0, 40.0, 0.8)
	var hiss_ok: bool = au.hiss != null and au.hiss.playing \
		and au.hiss.stream == AudioManager.stream(&"skid_gravel")
	var squeal_off: bool = au.squeal == null or not au.squeal.playing
	print("  pe pietris: sisait %s (%.1f dB), scrasnet oprit %s"
		% [hiss_ok, au.hiss.volume_db if au.hiss != null else -99.0, squeal_off])
	_check(asphalt_squeal, "pe asfalt scrasneste")
	_check(hiss_ok, "pe sol afanat canta `skid_gravel`")
	_check(squeal_off, "pe sol afanat scrasnetul de asfalt tace")
	au.override_loose = 0
	await _slide(car, 25.0, 40.0, 0.8)
	_check(au.squeal != null and au.squeal.playing and (au.hiss == null or not au.hiss.playing),
		"inapoi pe asfalt: scrasnet, fara sisait")
	car.queue_free()
	await get_tree().physics_frame


func _test_ai() -> void:
	print("")
	print("-- 6. adversarul scrasneste mai incet --")
	var a := await _spawn(true)
	var b := await _spawn(false)
	b.global_position = Vector3(30, 0.7, 0)
	a.global_position = Vector3(-30, 0.7, 0)
	await U.settle(get_tree(), 0.4)
	U.drv(a).throttle = 1.0
	U.drv(b).throttle = 1.0
	for _f in 36:
		for c in [a, b]:
			var fwd := -(c as Car).global_transform.basis.z
			fwd.y = 0.0
			var v := fwd.normalized().rotated(Vector3.UP, deg_to_rad(30.0)) * 25.0
			(c as Car).linear_velocity = Vector3(v.x, (c as Car).linear_velocity.y, v.z)
		await get_tree().physics_frame
	var pl := _loud(U.audio(a))
	var ai := _loud(U.audio(b))
	print("  jucator %.1f dB, adversar %.1f dB" % [pl, ai])
	_check(ai > -90.0 and pl - ai >= 3.0, "adversarul e cu >= 3 dB mai incet")
	a.queue_free()
	b.queue_free()
	await get_tree().physics_frame
