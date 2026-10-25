extends Node
## Reactia camerei si a timpului la izbituri (feel: hitstop-shake,
## player-big-ai-small): kick directional, hit-stop, regula atacatorului.
##
## Verifica:
##   1. arcul camerei: deplasarea in sensul normalei, se linisteste sub 5% in
##      0.5 s, ruliul are semnul potrivit;
##   2. izbitura REALA in perete: kick spre normala, hit-stop pornit cu durata
##      asteptata (in cadre de timp real), time_scale revine EXACT la 1.0;
##   3. hit-stop imposibil de blocat: masina stearsa in inghet, pauza, repunere,
##      aruncare, nod sters; fara inghet in numaratoare; cooldown intre inghetari;
##   4. cine a lovit pe cine: jucatorul care loveste (din spate) primeste kick
##      plin + hit-stop; AI-ul care loveste jucatorul — kick plafonat, fara
##      hit-stop; ciocnire frontala egala = jucatorul atacator.
##
## Duratele se masoara in cadre sub --fixed-fps (un cadru = 1/60 s real), deci
## sonda ruleaza DOAR asa:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeImpactCamera.tscn

const STEP: float = 1.0 / 60.0
const ImpactFeelScript := preload("res://scenes/race/impact_feel.gd")

var _failed: bool = false
var _player: Car
var _ai: Car
var _cam: ChaseCamera
var _feel: ImpactFeelScript
var _vig: Vignette
var _racing: bool = true
var _events: Array[Dictionary] = []


func _ready() -> void:
	# Cu arborele pe pauza, sonda trebuie sa-si continue cadrele.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_box(Vector3(600, 1, 600), Vector3(0, -0.5, 0)))
	# Perete lung pe axa X, la z = -20, fata spre +Z.
	add_child(_box(Vector3(200, 3, 1), Vector3(0, 1.5, -20.5)))
	await get_tree().physics_frame
	print("")
	print("=== Camera la izbituri: kick, hit-stop, atacator ===")
	await _test_spring()
	await _test_wall_hit()
	await _test_hitstop_safety()
	await _test_attacker()
	await _test_edge_flash()
	await _test_turbo_lag()
	Engine.time_scale = 1.0
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


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _car(pos: Vector3, yaw: float = 0.0) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	car.rotation.y = yaw
	car.race_active = true
	return car


## Lume noua: jucator (+ optional AI), camera, ImpactFeel. `_racing` il decide sonda.
func _rig(player_pos: Vector3, with_ai: bool, ai_pos: Vector3 = Vector3.ZERO,
		ai_yaw: float = 0.0) -> void:
	_player = _car(player_pos)
	_player.is_player = true
	_ai = null
	var cars: Array = [_player]
	if with_ai:
		_ai = _car(ai_pos, ai_yaw)
		cars.append(_ai)
	_cam = ChaseCamera.new()
	add_child(_cam)
	_cam.target = _player
	_cam.snap_behind()
	_feel = ImpactFeelScript.new()
	_feel.racing = func() -> bool: return _racing
	add_child(_feel)
	_vig = Vignette.new()
	add_child(_vig)
	_feel.setup(_player, cars, _cam, _vig)
	_events.clear()
	_player.impact.connect(func(_c: Car, kind: StringName, strength: float,
			normal: Vector3, _p: Vector3, _o: Node) -> void:
		_events.append({"kind": kind, "strength": strength, "normal": normal}))
	# Lasa masinile sa se aseze pe suspensie.
	await _frames(50)
	for c in [_player, _ai]:
		if c != null:
			(c as Car).linear_velocity = Vector3.ZERO


func _teardown() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	for n in [_feel, _cam, _vig, _player, _ai]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	await _frames(3)


# ------------------------------------------------------------------ 1. arcul

func _test_spring() -> void:
	print("")
	print("-- 1. arcul camerei (izolat) --")
	_racing = true
	await _rig(Vector3(0, 0.7, 40), false)
	# Camera sta in spatele masinii, privind -Z: dreapta ecranului = +X.
	_cam.kick(Vector3(1, 0, 0), 1.0, 3.0)
	var peak := _cam.kick_offset().length()
	var roll0 := _cam.kick_roll_rad()
	print("  deplasare initiala %.2f m, ruliu %.2f grade, directie x=%.2f"
		% [peak, rad_to_deg(roll0), _cam.kick_offset().x])
	_check(_cam.kick_offset().x > 0.95 * peak, "kick spre +X (dreapta ecranului)")
	_check(roll0 < 0.0, "ruliu negativ cand camera e impinsa spre dreapta")
	var settled_at := -1.0
	var worst_after := 0.0
	var at_half := 0.0
	for i in 60:
		await get_tree().physics_frame
		var m := _cam.kick_offset().length()
		if i == 29:
			at_half = m
		if m < 0.05 * peak and settled_at < 0.0:
			settled_at = float(i + 1) * STEP
		if settled_at >= 0.0 and i * STEP > settled_at:
			worst_after = maxf(worst_after, m)
	print("  sub 5%% la %.2f s, la 0.5 s ramas %.1f%%, dupa asezare maxim %.1f%%"
		% [settled_at, at_half / peak * 100.0, worst_after / peak * 100.0])
	_check(settled_at > 0.0 and settled_at <= 0.5, "se linisteste sub 5% in 0.5 s")
	_check(at_half < 0.05 * peak, "la 0.5 s ramas sub 5%")
	_check(worst_after < 0.05 * peak, "dupa asezare nu mai iese peste 5% (fara balans)")
	_check(settled_at > 0.1, "nu e instant (arc, nu teleport): >0.1 s")
	# Doua lovituri se aduna, dar plafonul tine.
	_cam.kick(Vector3(0, 0, 1), 1.0)
	_cam.kick(Vector3(0, 0, 1), 1.0)
	_check(_cam.kick_offset().length() <= _cam.kick_limit + 0.001,
		"lovituri repetate raman sub plafonul de %.1f m" % _cam.kick_limit)
	await _teardown()


# ------------------------------------------------------- 2. izbitura in perete

func _test_wall_hit() -> void:
	print("")
	print("-- 2. izbitura in perete la 14 m/s --")
	_racing = true
	await _rig(Vector3(0, 0.7, -8), false)
	_player.linear_velocity = Vector3(0, 0, -14)
	var frozen_frames := 0
	var min_scale := 1.0
	var kick_dir := Vector3.ZERO
	var kick_len := 0.0
	var got := false
	for _f in 90:
		await get_tree().process_frame
		if Engine.time_scale < 0.999:
			frozen_frames += 1
			min_scale = minf(min_scale, Engine.time_scale)
		if not got and not _events.is_empty():
			got = true
			kick_len = _cam.kick_offset().length()
			kick_dir = _cam.kick_offset().normalized()
	var walls := _events.filter(func(e: Dictionary) -> bool: return e.kind == &"wall")
	_check(not walls.is_empty(), "impact &\"wall\" primit")
	if walls.is_empty():
		await _teardown()
		return
	var strength: float = walls[0].strength
	var n: Vector3 = walls[0].normal
	var expect_ms := lerpf(_feel.hitstop_min_ms, _feel.hitstop_max_ms,
		clampf((strength - _feel.hitstop_min_strength)
			/ (_feel.hitstop_full_strength - _feel.hitstop_min_strength), 0.0, 1.0))
	print("  forta %.1f, normala z=%.2f, kick %.2f m (dir z=%.2f), inghet %d cadre = %.0f ms (asteptat %.0f ms), time_scale minim %.2f"
		% [strength, n.z, kick_len, kick_dir.z, frozen_frames,
			frozen_frames * STEP * 1000.0, expect_ms, min_scale])
	_check(kick_len > 0.2, "camera primeste kick (>0.2 m)")
	_check(kick_dir.dot(Vector3(n.x, 0, n.z).normalized()) > 0.9,
		"kick in sensul normalei (dinspre perete spre masina)")
	_check(strength >= _feel.hitstop_min_strength, "izbitura trece de pragul de hit-stop")
	_check(min_scale <= 0.06, "time_scale coborat la ~0.05")
	_check(absf(frozen_frames * STEP * 1000.0 - expect_ms) <= 1.6 * STEP * 1000.0,
		"durata inghetului = cea scalata dupa forta (+-1.6 cadre)")
	_check(Engine.time_scale == 1.0, "time_scale readus EXACT la 1.0")
	await _teardown()


# ----------------------------------------------------- 3. hit-stop fara blocaj

## Porneste un inghet direct (ocolind cooldown-ul) si intoarce daca a pornit.
func _freeze() -> bool:
	_feel.hit_stop._cool = 0.0
	return _feel.hit_stop.trigger(0.09)


func _big_wall_hit() -> void:
	_player.impact.emit(_player, &"wall", 16.0, Vector3.BACK, Vector3.ZERO, null)


func _test_hitstop_safety() -> void:
	print("")
	print("-- 3. hit-stop imposibil de blocat --")
	_racing = true
	await _rig(Vector3(0, 0.7, 40), false)

	# 3a. mers normal
	_check(_freeze() and Engine.time_scale < 0.1, "inghet pornit")
	await _frames(12)
	_check(Engine.time_scale == 1.0, "revine singur la 1.0 (90 ms)")

	# 3b. pauza
	_check(_freeze(), "inghet pornit (pauza)")
	get_tree().paused = true
	await _frames(3)
	_check(Engine.time_scale == 1.0, "pauza => time_scale 1.0")
	get_tree().paused = false
	await _frames(3)

	# 3c. repunere
	_check(_freeze(), "inghet pornit (repunere)")
	_player.respawned.emit(_player)
	_check(Engine.time_scale == 1.0, "repunere => 1.0")

	# 3d. aruncare
	_check(_freeze(), "inghet pornit (aruncare)")
	_player.ejected.emit(_player, null)
	_check(Engine.time_scale == 1.0, "aruncare => 1.0")

	# 3e. final de cursa
	_check(_freeze(), "inghet pornit (final)")
	_feel.cancel_hit_stop()
	_check(Engine.time_scale == 1.0, "final de cursa => 1.0")

	# 3f. masina stearsa in inghet
	_check(_freeze(), "inghet pornit (masina stearsa)")
	_player.queue_free()
	await _frames(2)
	_check(Engine.time_scale == 1.0, "masina stearsa in inghet => 1.0")
	await _teardown()

	# 3g. nodul iese din arbore in inghet
	await _rig(Vector3(0, 0.7, 40), false)
	_check(_freeze(), "inghet pornit (iesire din arbore)")
	var feel := _feel
	remove_child(feel)
	_check(Engine.time_scale == 1.0, "iesire din arbore => 1.0")
	feel.free()
	_feel = null
	await _teardown()

	# 3h. numaratoare: fara hit-stop; cooldown intre inghetari; prag
	await _rig(Vector3(0, 0.7, 40), false)
	_racing = false
	_big_wall_hit()
	_check(Engine.time_scale == 1.0, "fara hit-stop in numaratoare")
	_check(_cam.kick_offset().length() > 0.1, "dar kick-ul exista si in numaratoare")
	_racing = true
	_big_wall_hit()
	_check(Engine.time_scale < 0.1, "dupa GO, aceeasi izbitura ingheata")
	await _frames(12)
	_check(Engine.time_scale == 1.0, "inghetul s-a incheiat")
	_big_wall_hit()
	_check(Engine.time_scale == 1.0,
		"a doua izbitura la ~0.2 s: fara al doilea inghet (cooldown)")
	await _frames(40)
	_big_wall_hit()
	_check(Engine.time_scale < 0.1, "dupa >0.6 s inghetul e din nou posibil")
	await _frames(12)
	await _frames(40)
	_player.impact.emit(_player, &"wall", 6.0, Vector3.BACK, Vector3.ZERO, null)
	_check(Engine.time_scale == 1.0, "izbitura de 6 m/s nu ingheata")
	await _teardown()


# ------------------------------------------------------------ 4. atacatorul

## O ciocnire cu masini reale pe axa Z. Intoarce kick, cadre inghetate, atacator.
func _collide(label: String, player_z: float, player_v: Vector3, ai_z: float,
		ai_v: Vector3, ai_yaw: float = 0.0) -> Dictionary:
	await _rig(Vector3(0, 0.7, player_z), true, Vector3(0, 0.7, ai_z), ai_yaw)
	_racing = true
	_player.linear_velocity = player_v
	_ai.linear_velocity = ai_v
	var frozen := 0
	var strength := 0.0
	var kick := 0.0
	var got := false
	for _f in 50:
		await get_tree().process_frame
		if Engine.time_scale < 0.999:
			frozen += 1
		if not got and not _events.is_empty():
			got = true
			strength = float(_events[0].strength)
			kick = _feel.last_kick
	var r := {"kick": kick, "frozen": frozen, "got": got,
		"attacker": _feel.last_player_attacker, "strength": strength}
	print("  %s: forta %.1f, atacator=%s, kick %.2f m, inghet %d cadre"
		% [label, strength, str(r.attacker), kick, frozen])
	await _teardown()
	return r


func _test_attacker() -> void:
	print("")
	print("-- 4. cine a lovit pe cine --")
	# Ambii cu botul spre -Z. Jucatorul vine din spate peste un AI stationar.
	var a: Dictionary = await _collide("jucatorul loveste AI-ul",
		60.0, Vector3(0, 0, -28), 50.0, Vector3.ZERO)
	# Acum AI-ul vine din spate peste jucatorul stationar.
	var b: Dictionary = await _collide("AI-ul loveste jucatorul",
		50.0, Vector3.ZERO, 60.0, Vector3(0, 0, -28))
	# Frontal, viteze egale (AI-ul intors spre +Z).
	var c: Dictionary = await _collide("frontal egal",
		60.0, Vector3(0, 0, -14), 48.0, Vector3(0, 0, 14), PI)
	_check(a.got and b.got and c.got, "toate ciocnirile au emis impact")
	_check(a.strength >= 9.0 and b.strength >= 9.0,
		"cele doua lovituri din spate depasesc pragul de hit-stop (%.1f / %.1f)"
		% [a.strength, b.strength])
	_check(a.attacker and a.frozen > 0, "jucatorul atacator: hit-stop pornit")
	_check(a.kick > 0.3, "jucatorul atacator: kick plin")
	_check(not b.attacker, "AI-ul atacator: jucatorul NU e atacator")
	_check(b.frozen == 0, "AI-ul atacator: fara hit-stop")
	_check(b.kick > 0.0 and b.kick <= 0.4 + 0.001, "AI-ul atacator: kick plafonat (<=0.4 m)")
	_check(b.kick < a.kick * 0.9, "AI-ul atacator: kick mai mic decat al jucatorului")
	_check(c.attacker, "frontal egal: jucatorul ramane atacatorul")


# ------------------------------------------------------ 5. flash de margine

func _edges() -> Array[float]:
	return [_vig.edge_alpha(Vignette.Edge.LEFT), _vig.edge_alpha(Vignette.Edge.RIGHT),
		_vig.edge_alpha(Vignette.Edge.TOP), _vig.edge_alpha(Vignette.Edge.BOTTOM)]


func _test_edge_flash() -> void:
	print("")
	print("-- 5. flash de margine dinspre lovitura --")
	_racing = false # fara hit-stop, doar flash-ul
	await _rig(Vector3(0, 0.7, 40), false)
	# Camera priveste -Z; dreapta ecranului = +X. Normala arata dinspre obstacol
	# spre masina, deci un obstacol la STANGA are normala +X.
	_player.impact.emit(_player, &"wall", 12.0, Vector3(1, 0, 0), Vector3.ZERO, null)
	var e := _edges()
	print("  obstacol la stanga: L=%.2f R=%.2f sus=%.2f jos=%.2f" % [e[0], e[1], e[2], e[3]])
	_check(e[0] > 0.2 and e[1] == 0.0 and e[2] == 0.0 and e[3] == 0.0,
		"obstacol la stanga => doar marginea stanga")
	_check(_vig.get_child(1).visible, "fasia stanga e vizibila")
	await _frames(40)
	e = _edges()
	_check(e[0] == 0.0 and not _vig.is_processing(),
		"flash-ul se stinge singur si nodul nu mai ruleaza (cost zero)")
	_check(not _vig.get_child(1).visible, "fasia revine ascunsa")
	_player.impact.emit(_player, &"wall", 12.0, Vector3(-1, 0, 0), Vector3.ZERO, null)
	e = _edges()
	_check(e[1] > 0.2 and e[0] == 0.0, "obstacol la dreapta => marginea dreapta")
	await _frames(40)
	_player.impact.emit(_player, &"wall", 12.0, Vector3(0, 0, 1), Vector3.ZERO, null)
	e = _edges()
	_check(e[2] > 0.2 and e[3] == 0.0, "obstacol in fata => marginea de sus")
	await _frames(40)
	_player.impact.emit(_player, &"wall", 12.0, Vector3(0, 0, -1), Vector3.ZERO, null)
	e = _edges()
	_check(e[3] > 0.2 and e[2] == 0.0, "lovit din spate => marginea de jos")
	await _frames(40)
	_player.impact.emit(_player, &"wall", 4.0, Vector3(1, 0, 0), Vector3.ZERO, null)
	var small := _vig.edge_alpha(Vignette.Edge.LEFT)
	await _frames(40)
	_player.impact.emit(_player, &"wall", 18.0, Vector3(1, 0, 0), Vector3.ZERO, null)
	var big := _vig.edge_alpha(Vignette.Edge.LEFT)
	print("  alfa: izbitura 4 m/s %.2f, 18 m/s %.2f" % [small, big])
	_check(big > small * 2.0 and big <= _feel.flash_max + 0.001,
		"flash-ul creste cu forta si e plafonat")
	await _teardown()


## Turbo-event: la aprinderea turbo-ului camera e trasa INAPOI (spre +Z local al
## masinii) cu `turbo_lag_m`, apoi arcul o aduce la loc.
func _test_turbo_lag() -> void:
	print("")
	print("-- turbo: camera ramane o clipa in urma --")
	await _rig(Vector3(0, 0.7, 40), false)
	var back := _player.global_transform.basis.z
	back.y = 0.0
	back = back.normalized()
	_player.force_boost(0.5)
	var along := _cam.kick_offset().dot(back)
	var side := absf(_cam.kick_offset().dot(_player.global_transform.basis.x))
	print("  kick dupa aprindere: %.2f m inapoi, %.2f m lateral (tinta %.2f)"
		% [along, side, _feel.turbo_lag_m])
	_check(along > 0.7 * _feel.turbo_lag_m, "camera e trasa inapoi la aprinderea turbo-ului")
	_check(side < 0.1, "fara deviere laterala")
	await _frames(40)
	print("  dupa 0.67 s: %.3f m" % _cam.kick_offset().length())
	_check(_cam.kick_offset().length() < 0.05 * _feel.turbo_lag_m, "arcul o aduce inapoi")
	_teardown()
	await _frames(2)
