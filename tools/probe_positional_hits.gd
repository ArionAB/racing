extends Node
## Impacturi pozitionale (docs/feel_checklist.md: who-hit-me si ai-ai-hits, partea
## de sunet).
##
## Masinile sunt STUB-uri (Car.new() fara arbore): `impact` se emite de mana, cu
## punct, normala si putere controlate, iar camera e un Camera3D real (urechea).
## Sonda citeste jurnalul `sfx_log` si playerele 3D REALE din pool
## (`AudioManager.pool3d()`): pozitie, stream, volum.
##
## Verifica:
##   1. lovitura peste jucator din dreapta / din stanga: straturile principale ies
##      din pool-ul 3D, cu sursa de PARTEA cealalta fata de camera (x relativ al
##      camerei de semn corect), aproape de punctul de contact; corpul (bump) ramane
##      2D; playerul 3D real poarta pozitia si volumul din jurnal;
##   2. AI-AI aproape (sub 35 m de camera): pozitional, fara corp, mai incet decat
##      aceeasi lovitura cu jucatorul; departe (peste 35 m) sau sub prag: tacut;
##   3. pauza globala AI-AI (0,12 s) si pe pereche (0,15 s) tin: 40 de lovituri intr-o
##      secunda simulata dau cel mult 9 sunete;
##   4. pool-ul ramane de 4 playere, nu apar alte AudioStreamPlayer3D in arbore,
##      iar cand toate 4 canta sunete de jucator, un sunet AI (prioritate mica) se
##      pierde in loc sa fure.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePositionalHits.tscn

const ImpactSoundScript := preload("res://scenes/race/impact_sound.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _now: float = 1000.0
var _cam: Camera3D
var _snd: Node


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _clock() -> float:
	return _now


func _ready() -> void:
	print("")
	print("=== Impacturi pozitionale ===")
	AudioManager.clock = _clock
	# Camera de urmarire: 10 m sus, 13 m in spate, priveste spre -Z.
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.global_position = Vector3(0, 10, 13)
	_cam.current = true
	await get_tree().process_frame
	var seen := AudioManager.listener_position()
	_check(seen.is_finite() and seen.distance_to(Vector3(0, 10, 13)) < 0.01,
		"AudioManager vede camera activa (%s)" % str(seen))
	_snd = ImpactSoundScript.new()
	_snd.clock = _clock
	add_child(_snd)
	var player := Car.new()
	player.is_player = true
	_snd.setup(player, [player])
	var nodes_before := _count_players_3d()
	await _test_who_hit_me(player)
	await _test_ai_ai()
	await _test_rate_limit()
	await _test_pool_bounds(player, nodes_before)
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _count_players_3d() -> int:
	return get_tree().root.find_children("*", "AudioStreamPlayer3D", true, false).size()


## Cate tick-uri de fizica trec; ceasul simulat avanseaza odata cu ele.
func _advance(seconds: float) -> void:
	for _f in int(round(seconds / STEP)):
		_now += STEP
		await get_tree().physics_frame


## Cate IMPACTURI au sunat (o lovitura = mai multe straturi in acelasi cadru).
func _hits_in_log() -> int:
	var frames: Dictionary = {}
	for e in AudioManager.sfx_log:
		if String(e["name"]).begins_with("impact_"):
			frames[e["frame"]] = true
	return frames.size()


func _positional(log: Array) -> Array:
	return log.filter(func(e: Dictionary) -> bool: return e["positional"])


func _flat(log: Array) -> Array:
	return log.filter(func(e: Dictionary) -> bool: return not e["positional"])


## Emite lovitura ca `car` (impactul vazut din partea lui): `n` arata dinspre
## obstacol spre `car`, `other` e celalalt.
func _hit(car: Car, other: Car, strength: float, point: Vector3, normal: Vector3) -> void:
	car.impact.emit(car, &"car", strength, normal, point, other)
	other.impact.emit(other, &"car", strength * 0.8, -normal, point, car)


func _fresh_pair(player_in: bool) -> Array[Car]:
	var a := Car.new()
	var b := Car.new()
	a.is_player = player_in
	_snd.setup(a if player_in else b, [a, b])
	return [a, b]


func _test_who_hit_me(player: Car) -> void:
	print("")
	print("-- 1. cine m-a lovit: stanga / dreapta --")
	var contact := Vector3(0, 0, 0)
	var xs: Dictionary = {}
	for side: String in ["dreapta", "stanga"]:
		var other := Car.new()
		_snd.setup(player, [player, other])
		AudioManager.sfx_log.clear()
		# `other` e in dreapta (+X) sau in stanga (-X) jucatorului; normala (dinspre
		# obstacol spre jucator) arata invers.
		var sgn := 1.0 if side == "dreapta" else -1.0
		_hit(player, other, 11.0, contact, Vector3(-sgn, 0, 0))
		await _advance(0.1)
		var log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
		var pos := _positional(log)
		var flat := _flat(log)
		print("  %s: 3D %s, 2D %s" % [side,
			pos.map(func(e: Dictionary) -> String: return "%s@%s" % [e["name"], str(e["pos"])]),
			flat.map(func(e: Dictionary) -> StringName: return e["name"])])
		_check(not pos.is_empty(), "%s: stratul principal iese din pool-ul 3D" % side)
		_check(flat.any(func(e: Dictionary) -> bool: return e["name"] == &"bump"),
			"%s: corpul `bump` ramane 2D" % side)
		_check(pos.all(func(e: Dictionary) -> bool:
			return not String(e["name"]).begins_with("bump")), "%s: bump nu e pozitional" % side)
		if not pos.is_empty():
			var p: Vector3 = pos[0]["pos"]
			var rel := _cam.global_transform.affine_inverse() * p
			xs[side] = rel.x
			_check(rel.x * sgn > 0.5, "%s: sursa e de partea %s a camerei (x relativ %.1f)"
				% [side, side, rel.x])
			_check(p.distance_to(contact) < 5.0, "%s: aproape de punctul de contact (%.1f m)"
				% [side, p.distance_to(contact)])
			var found := false
			for pl in AudioManager.pool3d():
				if pl.stream == AudioManager.stream(pos[0]["name"]) \
						and pl.global_position.distance_to(p) < 0.01 \
						and absf(pl.volume_db - float(pos[0]["db"])) < 0.01:
					found = true
			_check(found, "%s: playerul 3D real poarta pozitia si volumul din jurnal" % side)
		await _advance(0.3)
	if xs.size() == 2:
		_check(float(xs["dreapta"]) > 0.0 and float(xs["stanga"]) < 0.0,
			"dreapta si stanga ies de parti opuse ale camerei")


func _test_ai_ai() -> void:
	print("")
	print("-- 2. AI-AI: aproape, departe, sub prag --")
	var pair := _fresh_pair(false)
	# Jucatorul de referinta: aceeasi lovitura, cu jucatorul implicat.
	var pp := _fresh_pair(true)
	AudioManager.sfx_log.clear()
	_hit(pp[0], pp[1], 9.0, Vector3(0, 0, -10), Vector3(-1, 0, 0))
	await _advance(0.5)
	var ref_log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
	var ref_main := _positional(ref_log)
	# AI-AI aproape (25 m de camera).
	_snd.setup(pair[1], [pair[0], pair[1]]) # niciun jucator real implicat
	AudioManager.sfx_log.clear()
	_hit(pair[0], pair[1], 9.0, Vector3(0, 0, -10), Vector3(-1, 0, 0))
	await _advance(0.5)
	var near_log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
	var near_pos := _positional(near_log)
	print("  jucator: %s; AI aproape: %s" % [
		ref_log.map(func(e: Dictionary) -> String: return "%s %.1f" % [e["name"], e["db"]]),
		near_log.map(func(e: Dictionary) -> String: return "%s %.1f" % [e["name"], e["db"]])])
	_check(not near_pos.is_empty(), "AI-AI aproape: pozitional")
	_check(_flat(near_log).is_empty(), "AI-AI: fara strat 2D (nici corp)")
	if not near_pos.is_empty() and not ref_main.is_empty():
		_check(float(ref_main[0]["db"]) - float(near_pos[0]["db"]) >= 6.0,
			"AI-AI mai incet cu cel putin 6 dB (%.1f vs %.1f)"
			% [float(near_pos[0]["db"]), float(ref_main[0]["db"])])
	# Departe de camera.
	AudioManager.sfx_log.clear()
	await _advance(0.5)
	_hit(pair[0], pair[1], 9.0, Vector3(0, 0, -80), Vector3(-1, 0, 0))
	await _advance(0.3)
	_check(AudioManager.sfx_log.is_empty(), "AI-AI la 90 m de camera: tacut")
	# Sub prag.
	await _advance(0.5)
	_hit(pair[0], pair[1], 3.0, Vector3(0, 0, -10), Vector3(-1, 0, 0))
	await _advance(0.3)
	_check(AudioManager.sfx_log.is_empty(), "AI-AI sub 3,5 m/s: tacut")
	# Chiar la marginea razei: 34 m da, 36 m nu.
	await _advance(0.5)
	var edge_near := Vector3(0, 10, 13) + Vector3(0, 0, -34)
	_hit(pair[0], pair[1], 9.0, edge_near, Vector3(-1, 0, 0))
	await _advance(0.3)
	var n34 := AudioManager.sfx_log.size()
	AudioManager.sfx_log.clear()
	await _advance(0.5)
	_hit(pair[0], pair[1], 9.0, Vector3(0, 10, 13) + Vector3(0, 0, -36), Vector3(-1, 0, 0))
	await _advance(0.3)
	_check(n34 > 0 and AudioManager.sfx_log.is_empty(), "raza de 35 m: 34 m suna, 36 m nu")


func _test_rate_limit() -> void:
	print("")
	print("-- 3. pauza globala si pe pereche --")
	var pairs: Array = []
	for i in 8:
		pairs.append(_fresh_pair(false))
	var all_cars: Array = []
	for p in pairs:
		all_cars.append_array(p)
	_snd.setup(all_cars[0], all_cars)
	await _advance(0.5)
	AudioManager.sfx_log.clear()
	var fired := 0
	# 40 de lovituri pe ~1,3 s simulate, pe 8 perechi diferite, aproape de camera.
	var t0 := _now
	for i in 40:
		var p: Array = pairs[i % 8]
		_hit(p[0], p[1], 9.0, Vector3(float(i % 8) - 4.0, 0, -12), Vector3(-1, 0, 0))
		fired += 1
		await _advance(1.0 / 40.0)
	var sounded := _hits_in_log()
	var elapsed := _now - t0
	var cap := int(floor(elapsed / _snd.ai_interval_s)) + 1
	print("  lovituri %d in %.2f s, au sunat %d (plafon %d la pauza de %.2f s)"
		% [fired, elapsed, sounded, cap, _snd.ai_interval_s])
	_check(sounded > 0, "ceva suna")
	_check(sounded <= cap, "cel mult o lovitura AI-AI la fiecare ai_interval_s (%d <= %d)" % [sounded, cap])
	_check(sounded >= 4, "dar pauza nu taie tot (%d)" % sounded)
	# Aceeasi pereche, doua lovituri la 0,05 s: una singura.
	await _advance(0.6)
	AudioManager.sfx_log.clear()
	var p0: Array = pairs[0]
	_hit(p0[0], p0[1], 9.0, Vector3(0, 0, -12), Vector3(-1, 0, 0))
	await _advance(0.05)
	_hit(p0[0], p0[1], 9.0, Vector3(0, 0, -12), Vector3(-1, 0, 0))
	await _advance(0.1)
	var same := _hits_in_log()
	_check(same == 1, "aceeasi pereche la 0,05 s: un singur sunet (%d)" % same)


func _test_pool_bounds(player: Car, nodes_before: int) -> void:
	print("")
	print("-- 4. pool-ul ramane de 4 --")
	await _advance(1.0)
	_check(AudioManager.pool3d().size() == 4, "pool-ul are 4 playere")
	# Patru sunete de jucator, in tick-uri diferite, ocupa tot pool-ul...
	var others: Array[Car] = []
	for i in 6:
		others.append(Car.new())
	_snd.setup(player, [player] + others)
	for i in 4:
		_hit(player, others[i], 12.0, Vector3(float(i), 0, -2), Vector3(-1, 0, 0))
		await _advance(0.03)
	var busy := AudioManager.pool3d_busy()
	print("  playere 3D ocupate dupa 4 lovituri ale jucatorului: %d" % busy)
	# ... iar un sunet AI (prioritate mica) nu are voie sa fure unul.
	var ai_a := Car.new()
	var ai_b := Car.new()
	var before := AudioManager.sfx_log.size()
	var pos_before: Array = []
	for p in AudioManager.pool3d():
		pos_before.append(p.global_position)
	_snd.setup(player, [player, ai_a, ai_b])
	_hit(ai_a, ai_b, 10.0, Vector3(5, 0, -6), Vector3(-1, 0, 0))
	await _advance(0.05)
	var stolen := false
	for i in AudioManager.pool3d().size():
		if AudioManager.pool3d()[i].global_position.distance_to(pos_before[i]) > 0.1:
			stolen = true
	_check(busy == 4, "pool-ul e plin inainte de proba de furt (%d)" % busy)
	_check(not stolen, "AI-AI nu fura un player ocupat de sunete ale jucatorului")
	_check(AudioManager.pool3d().size() == 4, "pool-ul are tot 4 playere")
	_check(_count_players_3d() == nodes_before,
		"niciun AudioStreamPlayer3D nou in arbore (%d = %d)" % [_count_players_3d(), nodes_before])
	_check(AudioManager.sfx_log.size() >= before, "jurnal ok")
