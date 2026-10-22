extends Node
## Auto-upright (docs/feel_checklist.md, `auto-upright`): o masina pe acoperis
## sau pe o parte se intoarce pe roti pe loc, cu un salt mic, in loc sa
## astepte repunerea.
##
## Contractele:
##   1. pe acoperis, pe asfalt (cursa reala): in <= 1.5 s e pe roti
##      (up.y > 0.8, cel putin 3 roti pe sol), `respawned` si
##      `recovery_started` NU se emit, pozitia ramane la <= 3 m, directia la
##      <= 35 grade. Acelasi lucru pe o parte (rulata 90 grade).
##   2. fara pista (masina goala, autobuzul greu): tot pe roti in <= 1.5 s.
##   3. loc invalid (pe acoperis, la 30 m in afara soselei): NU se intoarce pe
##      loc; cade pe repunerea veche — `recovery_started` in <= 2.2 s.
##   4. `upright_enabled = false` readuce comportamentul vechi: pe acoperis,
##      repunerea (nu intoarcerea) — sabotajul care trebuie sa pice la 1.
## Sabotaj (trebuie sa PICE): `-- --off` pune upright_enabled = false.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeUpright.tscn -- [--track=0]

const STEP: float = 1.0 / 60.0
const RACE_SCENE := "res://scenes/race/Race.tscn"
const BUS: CarData = preload("res://scenes/cars/data/bus.tres")

var _failed: bool = false
var _off: bool = false
var _race: Race
## Contorizate de lambda-uri: MEMBRI, nu locale.
var _respawned: int = 0
var _recovery: int = 0
var _recovery_at: float = -1.0
var _clock: float = 0.0


class ScriptDriver:
	extends CarController
	func get_throttle() -> float:
		return 0.0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	var idx := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	_off = "--off" in OS.get_cmdline_user_args()
	print("")
	print("=== Auto-upright ===")
	if _off:
		print("  (SABOTAJ: upright_enabled = false)")
	await _bare_cars()
	await _race_cases(idx)
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


# ------------------------------------------------------------ fara pista

func _bare_cars() -> void:
	print("")
	print("-- 2. fara pista: masina goala si autobuzul --")
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(400, 1, 400)
	cs.shape = sh
	ground.add_child(cs)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	for variant in ["gol", "autobuz"]:
		for roll_deg in [180.0, 90.0, -90.0]:
			var car := Car.new()
			add_child(car)
			if variant == "autobuz":
				car.apply_data(BUS)
			car.upright_enabled = not _off
			car.set_controller(ScriptDriver.new())
			car.race_active = true
			car.global_position = Vector3(0, 0.7, 0)
			for _f in 50:
				await get_tree().physics_frame
			var t := car.global_transform
			var yaw0 := _yaw_deg(car)
			var p0 := car.global_position
			t.basis = t.basis.rotated(t.basis.z.normalized(), deg_to_rad(roll_deg))
			car.global_transform = Transform3D(t.basis, p0 + Vector3.UP * 1.0)
			car.linear_velocity = Vector3.ZERO
			car.angular_velocity = Vector3.ZERO
			var t_up := -1.0
			var tt := 0.0
			var pos_up := p0
			var yaw_up := yaw0
			for _f in 150:
				await get_tree().physics_frame
				tt += STEP
				if t_up < 0.0 and car.global_transform.basis.y.y > 0.8 \
						and car.wheels_on_ground >= 3:
					t_up = tt
					pos_up = car.global_position
					yaw_up = _yaw_deg(car)
			var moved := Vector2(pos_up.x - p0.x, pos_up.z - p0.z).length()
			print("  %s, rulat %4.0f: pe roti la %s, deplasare %.1f m, directie %.0f grade"
				% [variant, roll_deg, ("%.2f s" % t_up) if t_up >= 0.0 else "NICIODATA",
					moved, absf(angle_difference(deg_to_rad(yaw0), deg_to_rad(yaw_up))) * 57.2958])
			_check(t_up >= 0.0 and t_up <= 1.5, "%s/%.0f: pe roti in <= 1.5 s" % [variant, roll_deg])
			car.queue_free()
			await get_tree().physics_frame


func _yaw_deg(car: Car) -> float:
	var f := -car.global_transform.basis.z
	return rad_to_deg(atan2(-f.x, -f.z))


# ----------------------------------------------------------- cursa reala

func _race_cases(idx: int) -> void:
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(_race)
	var p := _race.player
	p.respawned.connect(func(_c: Car) -> void: _respawned += 1)
	p.recovery_started.connect(func(_c: Car, _s: float) -> void:
		_recovery += 1
		if _recovery_at < 0.0:
			_recovery_at = _clock)
	p.upright_enabled = not _off
	var guard := 0
	while _race.state != Race.State.RUNNING and guard < 1800:
		await get_tree().physics_frame
		guard += 1
	for _f in 150:
		await get_tree().physics_frame
	print("")
	print("-- 1. pe acoperis si pe o parte, pe asfalt (cursa reala) --")
	for roll_deg in [180.0, 90.0]:
		await _flip_on_road(p, roll_deg)
	print("")
	print("-- 3. loc invalid: pe acoperis, 30 m in afara soselei --")
	await _flip_off_road(p)


func _reset_counters() -> void:
	_respawned = 0
	_recovery = 0
	_recovery_at = -1.0
	_clock = 0.0


func _flip_on_road(p: Car, roll_deg: float) -> void:
	# Intai o repunere curata pe drum, ca punctul de plecare sa fie bun.
	p.respawn()
	for _f in 120:
		await get_tree().physics_frame
	# Opreste masina (jucatorul nu are comenzi) si intoarce-o.
	p.linear_velocity = Vector3.ZERO
	for _f in 30:
		await get_tree().physics_frame
	var p0 := p.global_position
	var yaw0 := _yaw_deg(p)
	var t := p.global_transform
	t.basis = t.basis.rotated(t.basis.z.normalized(), deg_to_rad(roll_deg))
	p.global_transform = Transform3D(t.basis, p0 + Vector3.UP * 1.0)
	p.linear_velocity = Vector3.ZERO
	p.angular_velocity = Vector3.ZERO
	_reset_counters()
	var t_up := -1.0
	var pos_up := p0
	var yaw_up := yaw0
	for _f in 210:
		await get_tree().physics_frame
		_clock += STEP
		if t_up < 0.0 and p.global_transform.basis.y.y > 0.8 and p.wheels_on_ground >= 3:
			t_up = _clock
			pos_up = p.global_position
			yaw_up = _yaw_deg(p)
	var moved := Vector2(pos_up.x - p0.x, pos_up.z - p0.z).length()
	var dyaw := absf(angle_difference(deg_to_rad(yaw0), deg_to_rad(yaw_up))) * 57.2958
	print("  rulat %.0f: pe roti la %s, respawned %d, recovery %d, deplasare %.1f m, directie %.0f grade"
		% [roll_deg, ("%.2f s" % t_up) if t_up >= 0.0 else "NICIODATA", _respawned,
			_recovery, moved, dyaw])
	_check(t_up >= 0.0 and t_up <= 1.5, "rulat %.0f: pe roti in <= 1.5 s" % roll_deg)
	_check(_respawned == 0 and _recovery == 0, "rulat %.0f: nicio repunere" % roll_deg)
	_check(moved <= 3.0, "rulat %.0f: pozitia ramane la <= 3 m" % roll_deg)
	_check(dyaw <= 35.0, "rulat %.0f: directia ramane (<= 35 grade)" % roll_deg)


func _flip_off_road(p: Car) -> void:
	p.respawn()
	for _f in 120:
		await get_tree().physics_frame
	var track := _race.track
	var rp := track.point_at(p.road_index, p.route)
	var ahead := track.point_at(mini(p.road_index + 4, track.curve.get_baked_length() as int), p.route)
	var dir := (ahead - rp)
	dir.y = 0.0
	dir = dir.normalized()
	var side := Vector3(-dir.z, 0.0, dir.x)
	# Gaseste teren la 30 m lateral (incearca ambele parti).
	var space := p.get_world_3d().direct_space_state
	var spot := Vector3.INF
	for sgn in [1.0, -1.0]:
		var from: Vector3 = rp + side * 30.0 * sgn + Vector3.UP * 60.0
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 120.0)
		q.collision_mask = 1
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and absf((hit.position as Vector3).y - rp.y) < 6.0:
			spot = hit.position
			break
	if spot == Vector3.INF:
		print("  (nu s-a gasit teren plat la 30 m lateral — scenariul sarit)")
		_check(false, "teren de test gasit la 30 m in afara soselei")
		return
	var t := p.global_transform
	t.basis = t.basis.rotated(t.basis.z.normalized(), PI)
	p.global_transform = Transform3D(t.basis, spot + Vector3.UP * 1.5)
	p.linear_velocity = Vector3.ZERO
	p.angular_velocity = Vector3.ZERO
	_reset_counters()
	var up_seen := false
	for _f in 240:
		await get_tree().physics_frame
		_clock += STEP
		if _recovery > 0:
			break
		if p.global_transform.basis.y.y > 0.8 and p.wheels_on_ground >= 3:
			up_seen = true
	print("  recovery_started la %s, intors pe roti inainte: %s"
		% [("%.2f s" % _recovery_at) if _recovery_at >= 0.0 else "NICIODATA", up_seen])
	_check(not up_seen, "nu se intoarce pe loc intr-un loc invalid")
	_check(_recovery_at >= 0.0 and _recovery_at <= 2.2, "cade pe repunere in <= 2.2 s")
