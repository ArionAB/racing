extends Node
## SONDA SUNETULUI SAN FRANCISCO (Track25, brief san_francisco.md §5.6, pasul 8e). Ca sonda
## Angkorului, compara IDENTITATEA streamurilor (numele fisierului), nu doar ca a sunat ceva.
## Headless ruleaza pe driverul audio „dummy": se verifica STAREA playerelor (stream, bus,
## volume_db, playing) si cand pornesc, nu cum suna.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfSunet.tscn
##       [-- --fara-tur] [--tur-s=175] [--sabotaj=clopot|zumzet|ponton|golf]
##
## 1. CABLAJ (Track25.tscn instantiat): clopotul pe ambele tramvaie, cu streamuri diferite;
##    zumzetul (AmbienceBed cu `zone_line` pe strada tramvaiului 1); golful (AmbienceCalls: 6
##    locuri, leii de mare pe pluta lor); vocea scandurilor ceruta de pista; nivelurile in plaja.
##    Martori: Track15 / Track23 (celelalte BusHazard) fara clopot, Kyoto (Track18, puntea
##    Kiyomizu) fara voce de scandura.
## 2. CLOPOTUL, izolat (un BusHazard pe o dreapta, o „masina" mutata de sonda): suna o data la
##    apropierea din spate (si avansul pana la 12 m), o data cand vagonul vine spre tine, deloc
##    cand il urmezi la 30 m, deloc cat e ascuns si o data cand reapare langa tine, a doua oara
##    abia dupa ce te-ai departat; un BusHazard fara `bell_sfx` n-are player.
## 3. TURUL (Race.tscn cu Track25, masina jucatorului condusa de AIController, o cursa pe ocol si
##    una pe serpentine, `--tur-s` secunde fiecare): fiecare clopot cu distanta, viteza de
##    apropiere, linia de vedere si AVANSUL pana la 12 m de vagon; zumzetul plin pe strada si
##    oprit departe de ea; scandurile exact cand rotile sunt pe ponton; strigatele golfului rare
##    si doar in raza locului; aterizarile (cate, cat de tare) — in special cele 4 de pe lant;
##    cate playere adauga pista.
## Exit 1 la orice PICAT. Fiecare `--sabotaj` trebuie sa pice.

const TRACK := "res://scenes/tracks/Track25.tscn"
const KYOTO := "res://scenes/tracks/Track18.tscn"
const OTHER_BUS := ["res://scenes/tracks/Track15.tscn", "res://scenes/tracks/Track23.tscn"]
const RACE_SCENE := "res://scenes/race/Race.tscn"
const STEP: float = 1.0 / 60.0
## Pontonul pe harta (brief §2 F, gen_sf_route: x 40..120 pe cheiul de la z -454, 6 m semilatime).
const PONTON_X := Vector2(40.0, 120.0)
const QUAY_Z := -454.0

var _failed: bool = false
var _sab: String = ""
var _tour: bool = true
var _tour_s: float = 175.0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _stem(s: Resource) -> String:
	return "" if s == null else s.resource_path.get_file().get_basename()


func _all(root: Node, out: Array = []) -> Array:
	out.append(root)
	for c in root.get_children():
		_all(c, out)
	return out


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sabotaj="):
			_sab = a.trim_prefix("--sabotaj=")
		elif a == "--fara-tur":
			_tour = false
		elif a.begins_with("--tur-s="):
			_tour_s = float(a.trim_prefix("--tur-s="))
	print("")
	print("=== Sunetul San Francisco (Track25)%s ===" % ((" — SABOTAJ " + _sab) if _sab != "" else ""))
	_wiring()
	await _bell_unit()
	if _tour:
		await _race(false)
		await _race(true)
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


# ------------------------------------------------------------------ 1. cablaj

func _wiring() -> void:
	print("-- 1. cablaj in Track25.tscn --")
	var scene := (load(TRACK) as PackedScene).instantiate()
	var t1 := scene.get_node_or_null(^"Tramvaie/Tramvai1") as BusHazard
	var t2 := scene.get_node_or_null(^"Tramvaie/Tramvai2") as BusHazard
	_check(t1 != null and t1.bell_sfx == &"cable_bell_climb", "Tramvai1.bell_sfx = cable_bell_climb")
	_check(t2 != null and t2.bell_sfx == &"cable_bell_mouth", "Tramvai2.bell_sfx = cable_bell_mouth")
	for nm: StringName in [&"cable_bell_climb", &"cable_bell_mouth"]:
		var s := AudioManager.stream(nm)
		_check(s != null and _stem(s) == String(nm), "AudioManager.%s -> %s.wav" % [nm, _stem(s)])
		var w := s as AudioStreamWAV
		_check(w != null and w.loop_mode == AudioStreamWAV.LOOP_DISABLED and w.get_length() < 2.0,
			"%s: o lovitura, nu bucla (%.2f s)" % [nm, w.get_length() if w else 0.0])
	for t: BusHazard in [t1, t2]:
		if t == null:
			continue
		_check(t.bell_db <= 0.0 and t.bell_db >= -12.0 and t.bell_max_distance >= t.bell_range_m + 20.0,
			"%s: bell_db %.1f, max_distance %.0f >= raza %.0f + 20 (se aude cand suna)"
			% [t.name, t.bell_db, t.bell_max_distance, t.bell_range_m])
	var bed := scene.get_node_or_null(^"Sunet/ZumzetCablu") as AmbienceBed
	_check(bed != null and _stem(bed.bed_stream) == "cable_hum", "ZumzetCablu: AmbienceBed cu cable_hum")
	if bed != null:
		_check(bed.zone_line.size() >= 2, "zumzet: zona pe o linie (%d puncte)" % bed.zone_line.size())
		_check(bed.bed_db <= -8.0 and bed.bed_db >= -24.0, "zumzet: nivel de fundal (%.1f dB)" % bed.bed_db)
		_check(bed.rain_stream == null, "zumzet: fara strat de ploaie")
		# linia sta pe axa tramvaiului 1 (fiecare punct al liniei la < 3 m de curba lui)
		var far := 0.0
		if t1 != null:
			for q in bed.zone_line:
				var best := INF
				for i in t1.curve.point_count:
					var c := t1.to_global(t1.curve.get_point_position(i)) if t1.is_inside_tree() \
						else t1.curve.get_point_position(i)
					best = minf(best, Vector2(c.x - q.x, c.z - q.z).length())
				far = maxf(far, best)
		_check(far < 40.0, "zumzet: capetele liniei langa curba tramvaiului 1 (max %.1f m)" % far)
	var wav_hum := AudioManager.stream(&"cable_hum") as AudioStreamWAV
	var wav_plank := AudioManager.stream(&"plank_rattle") as AudioStreamWAV
	_check(wav_hum != null and wav_hum.loop_mode == AudioStreamWAV.LOOP_FORWARD, "cable_hum e bucla")
	_check(wav_plank != null and wav_plank.loop_mode == AudioStreamWAV.LOOP_FORWARD, "plank_rattle e bucla")
	var calls := scene.get_node_or_null(^"Sunet/Golful") as AmbienceCalls
	_check(calls != null, "Golful: AmbienceCalls")
	if calls != null:
		var n := calls.spot_pos.size()
		_check(n == 6 and calls.spot_sfx.size() == n and calls.spot_radius.size() == n
			and calls.spot_gap.size() == n and calls.spot_db.size() == n, "golful: 6 locuri, tablouri egale")
		var kinds := {}
		var ok_lv := true
		for i in n:
			var nm: StringName = calls.spot_sfx[i] if i < calls.spot_sfx.size() else &""
			kinds[nm] = int(kinds.get(nm, 0)) + 1
			if AudioManager.stream(nm) == null or calls.spot_db[i] > -3.0 or calls.spot_db[i] < -20.0 \
					or calls.spot_gap[i].x < 3.0 or calls.spot_gap[i].y < calls.spot_gap[i].x \
					or calls.spot_radius[i] < 30.0 or calls.spot_radius[i] > 120.0:
				ok_lv = false
		_check(ok_lv, "golful: streamuri existente, -20..-3 dB, intervale >= 3 s, raze 30..120 m")
		_check(int(kinds.get(&"gull_call", 0)) == 3 and int(kinds.get(&"sea_lion_bark", 0)) == 1
			and int(kinds.get(&"parrot_squawk", 0)) == 2, "golful: 3 pescarusi, 1 lei de mare, 2 papagali")
		_check(calls.global_gap_s >= 1.0, "golful: pauza globala %.1f s" % calls.global_gap_s)
		var raft := scene.get_node_or_null(^"DecorManual/LeiDeMare/Pluta") as Node3D
		var li := calls.spot_sfx.find(&"sea_lion_bark")
		if raft != null and li >= 0:
			var dd := Vector2(raft.position.x - calls.spot_pos[li].x, raft.position.z - calls.spot_pos[li].z).length()
			_check(dd < 10.0, "leii de mare latra de pe pluta lor (%.1f m de nodul Pluta)" % dd)
		else:
			_check(false, "pluta leilor (DecorManual/LeiDeMare/Pluta) si locul lor")
	# Vocea scandurilor: pista o cere, pe intervalul pontonului; Kyoto nu.
	var tr := scene as Track
	_check(tr != null and bool(tr.get(&"custom_wood_deck_voice")), "Track25.custom_wood_deck_voice")
	if tr != null:
		tr.call(&"_apply_custom") # tema + abaterile pistei, ca in _ready (scena nu e in arbore)
		var ranges: Array = tr.get(&"custom_wood_deck_ranges")
		var mid := 0.5 * ((ranges[0] as Vector2).x + (ranges[0] as Vector2).y) if not ranges.is_empty() else 0.67
		_check(tr.is_wood_deck_voice_at(mid) and not tr.is_wood_deck_voice_at(0.5)
			and not tr.is_wood_deck_voice_at(0.1), "Track25: voce de scandura la %.3f (pontonul), nu la 0.5 / 0.1" % mid)
	scene.free()
	var ky := (load(KYOTO) as PackedScene).instantiate() as Track
	var ky_has := false
	var ky_voice := false
	if ky != null:
		ky.call(&"_apply_custom")
		for r in ky.theme_flag("wood_deck_ranges", []):
			var v := r as Vector2
			ky_has = true
			if ky.is_wood_deck_voice_at(0.5 * (v.x + v.y)):
				ky_voice = true
		ky.free()
	_check(ky_has and not ky_voice, "martor Kyoto: are punte de lemn, dar fara voce de scandura")
	for path: String in OTHER_BUS:
		var other := (load(path) as PackedScene).instantiate()
		var buses := _all(other).filter(func(x: Node) -> bool: return x is BusHazard)
		var mute := buses.all(func(b: BusHazard) -> bool: return b.bell_sfx == &"")
		_check(not buses.is_empty() and mute, "martor %s: %d BusHazard, toate fara clopot"
			% [path.get_file(), buses.size()])
		other.free()


# ------------------------------------------------------------------ 2. clopotul izolat

## Un vagon pe o dreapta spre -Z (5 m/s, ciclu lung), fara teren (`stick_to_ground` stins).
func _make_bus(sfx: StringName) -> BusHazard:
	var hz := BusHazard.new()
	var c := Curve3D.new()
	c.add_point(Vector3(0, 1, 0))
	c.add_point(Vector3(0, 1, -600))
	hz.curve = c
	hz.speed = 5.0
	hz.period = 200.0
	hz.phase = 0.0
	hz.stick_to_ground = false
	hz.bell_sfx = sfx
	if _sab == "clopot":
		# sabotaj: clopotul suna oricand esti aproape, fara zavor si fara pauza
		hz.bell_closing_mps = -1000.0
		hz.bell_rearm_m = -1000.0
		hz.bell_min_gap_s = 0.0
	add_child(hz)
	return hz


## Muta „masina" dupa `motion(t) -> z`, la x = `lat`, timp de `seconds`; intoarce primul
## moment in care a ajuns la <= 12 m de corp (sau -1).
func _drive(hz: BusHazard, ear: Node3D, lat: float, seconds: float, motion: Callable) -> float:
	var t := 0.0
	var reach := -1.0
	while t < seconds:
		ear.global_position = Vector3(lat, 1.0, float(motion.call(t)))
		await get_tree().physics_frame
		t += STEP
		if reach < 0.0 and ear.global_position.distance_to(hz.body_position()) <= 12.0:
			reach = t
	return reach


func _bell_unit() -> void:
	print("-- 2. clopotul, izolat (vagon pe dreapta, 5 m/s) --")
	var ear := Node3D.new()
	add_child(ear)
	# A: din spate, la 30 m/s, de la 200 m: o data, la <= raza, cu avans pana la 12 m
	var a := _make_bus(&"cable_bell_climb")
	a.bell_listener = ear
	var ra := await _drive(a, ear, 1.5, 14.0, func(t: float) -> float: return 200.0 - 30.0 * t)
	var la := a.bell_log
	var lead := (ra - float(la[0]["t"])) if (la.size() > 0 and ra > 0.0) else -1.0
	_check(a.bells_rung == 1, "din spate la 30 m/s: %d clopot(e)" % a.bells_rung)
	if la.size() > 0:
		print("    la %.1f m, apropiere %.1f m/s; avans pana la 12 m: %.2f s" % [la[0]["dist"], la[0]["closing"], lead])
		_check(float(la[0]["dist"]) <= a.bell_range_m and float(la[0]["dist"]) > a.bell_range_m - 5.0,
			"suna cand intra in raza (%.1f m)" % la[0]["dist"])
	_check(lead >= 2.5, "avans >= 2,5 s la 25 m/s de apropiere (%.2f s)" % lead)
	var bp := a.bell_player
	_check(bp != null and _stem(bp.stream) == "cable_bell_climb" and bp.bus == &"SFX",
		"playerul 3D al clopotului: cable_bell_climb pe SFX")
	_check(bp != null and bp.get_parent() == a.get(&"_body"), "playerul merge cu vagonul (copil al corpului)")
	a.queue_free()
	# B: il urmezi la 30 m, cu viteza lui, 30 s: nimic
	var b := _make_bus(&"cable_bell_climb")
	b.bell_listener = ear
	await _drive(b, ear, 1.5, 30.0, func(t: float) -> float: return 30.0 - 5.0 * t)
	_check(b.bells_rung == 0, "il urmezi la 30 m, 30 s: %d clopot(e) (trebuie 0)" % b.bells_rung)
	b.queue_free()
	# C: stai pe loc la 60 m in fata lui, pe langa sine; vine spre tine si trece: o data
	var c := _make_bus(&"cable_bell_mouth")
	c.bell_listener = ear
	await _drive(c, ear, 4.0, 30.0, func(_t: float) -> float: return -60.0)
	_check(c.bells_rung == 1, "vagonul vine spre tine si trece: %d clopot(e)" % c.bells_rung)
	_check(c.bell_player != null and _stem(c.bell_player.stream) == "cable_bell_mouth", "gura: cable_bell_mouth")
	c.queue_free()
	# D: ascuns, te apropii: nimic; reapare cand esti la ~40 m si inca vii: o data
	var d := _make_bus(&"cable_bell_climb")
	d.bell_listener = ear
	await get_tree().physics_frame
	d.call(&"_hide", 100.0)
	await _drive(d, ear, 1.5, 5.0, func(t: float) -> float: return 200.0 - 30.0 * t)
	var hidden_rings := d.bells_rung
	d.call(&"_show")
	await _drive(d, ear, 1.5, 1.5, func(t: float) -> float: return 50.0 - 10.0 * t)
	_check(hidden_rings == 0 and d.bells_rung == 1,
		"ascuns: %d clopot(e); dupa ce reapare langa tine: %d (trebuie 0 si 1)" % [hidden_rings, d.bells_rung])
	d.queue_free()
	# E: apropiere, retragere peste raza + rearmare, a doua apropiere: de doua ori
	var e := _make_bus(&"cable_bell_climb")
	e.bell_listener = ear
	# distanta in spatele vagonului (care e la z = -5t): 200 m -> 40 m la 27 m/s, inapoi la 215 m
	# la 25 m/s (peste raza + rearmare), apoi iar spre el la 30 m/s
	await _drive(e, ear, 1.5, 24.0, func(t: float) -> float:
		var rel := 200.0 - 27.0 * t
		if t >= 5.93 and t < 12.93:
			rel = 40.0 + 25.0 * (t - 5.93)
		elif t >= 12.93:
			rel = 215.0 - 30.0 * (t - 12.93)
		return -5.0 * t + rel)
	_check(e.bells_rung == 2, "apropiere, retragere peste raza, a doua apropiere: %d clopot(e) (trebuie 2)"
		% e.bells_rung)
	e.queue_free()
	# F: fara bell_sfx (Carrara, Machu Picchu): niciun player
	var f := _make_bus(&"")
	await get_tree().physics_frame
	var players := _all(f).filter(func(x: Node) -> bool: return x is AudioStreamPlayer3D)
	_check(f.bell_player == null and players.is_empty(), "BusHazard fara bell_sfx: niciun player audio")
	f.queue_free()
	ear.queue_free()
	await get_tree().physics_frame


# ------------------------------------------------------------------ 3. turul

func _line_dist(line: PackedVector3Array, p: Vector3) -> float:
	var q := Vector2(p.x, p.z)
	var best := INF
	for i in line.size() - 1:
		var a := Vector2(line[i].x, line[i].z)
		var b := Vector2(line[i + 1].x, line[i + 1].z)
		var ab := b - a
		var k := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * k))
	return best


func _race(shortcut: bool) -> void:
	var label := "serpentine" if shortcut else "ocol"
	print("-- 3. turul (%s), %.0f s, masina jucatorului cu AIController --" % [label, _tour_s])
	GameState.track_scene_override = TRACK
	GameState.selected_track = GameState.resolve_track_arg("Track25")
	GameState.selected_car = 0
	GameState.ai_count = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	var race: Node = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(race)
	var track: Track = race.track
	var car: Car = race.player
	var old: CarController = car.controller
	car.remove_child(old)
	old.free()
	var ai := AIController.new()
	car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8011 if shortcut else 8010
	var vis: Array[Car] = []
	vis.append_array(race.cars)
	ai.configure(track, rng, vis)
	ai.prefers_shortcut = shortcut
	var trams: Array[BusHazard] = [track.get_node(^"Tramvaie/Tramvai1") as BusHazard,
		track.get_node(^"Tramvaie/Tramvai2") as BusHazard]
	# gura scurtaturii: ultimul punct al ramurii (unde serpentinele se varsa in strada de jos)
	var serp := track.get_node(^"Serpentine") as Path3D
	var mouth := serp.to_global(serp.curve.get_point_position(serp.curve.point_count - 1))
	var bed := track.get_node(^"Sunet/ZumzetCablu") as AmbienceBed
	var calls := track.get_node(^"Sunet/Golful") as AmbienceCalls
	calls.rng.seed = 77 + int(shortcut)
	var hum_line := bed.zone_line.duplicate()
	if _sab == "clopot":
		for t in trams:
			t.bell_closing_mps = -1000.0
			t.bell_rearm_m = -1000.0
			t.bell_min_gap_s = 0.0
	elif _sab == "zumzet":
		var moved := PackedVector3Array()
		for q in bed.zone_line:
			moved.append(q + Vector3(300.0, 0.0, 0.0))
		bed.zone_line = moved
	elif _sab == "ponton":
		track.set(&"_wood_voice_ready", true)
		var wrong: Array[Vector2] = [Vector2(0.55, 0.59)]
		track.set(&"_wood_voice_ranges", wrong)
	elif _sab == "golf":
		calls.global_gap_s = 0.0
		var gaps := PackedVector2Array()
		var radii := PackedFloat32Array()
		for i in calls.spot_gap.size():
			gaps.append(Vector2(0.1, 0.2))
			radii.append(10000.0)
		calls.spot_gap = gaps
		calls.spot_radius = radii
	# Cate playere audio adauga pista (sub nodul pistei): clopotele + zumzetul.
	var track_players := _all(track).filter(func(x: Node) -> bool:
		return x is AudioStreamPlayer or x is AudioStreamPlayer3D)
	var guard := 0
	while int(race.state) != 1 and guard < 2000:
		await get_tree().physics_frame
		guard += 1
	var lands: Array[Dictionary] = []
	car.landed.connect(func(_c: Car, fs: float) -> void:
		lands.append({"t": 0.0, "fs": fs, "pos": car.global_position, "plan": AudioManager.plan_land(fs)}))
	var space := track.get_world_3d().direct_space_state
	var cam: Camera3D = get_viewport().get_camera_3d()
	var t := 0.0
	var seen_rings := [0, 0]
	var rings: Array[Dictionary] = []
	var prev_d := [-1.0, -1.0]
	var hum_on_frames := 0
	var hum_on_bad := 0
	var hum_off_bad := 0
	var hum_play_s := 0.0
	var hum_db_max := -80.0
	var near_t := 0.0
	var far_t := 0.0
	var wood_s := 0.0
	var wood_out_bad := 0
	var wood_in_bad := 0
	var wood_in_frames := 0
	var plank_bad := 0
	var plank_db := Vector2(INF, -INF)
	var wood_passes := 0
	var was_wood := false
	var wood_left_t := 0.0
	var wood_on_t := 0.0
	var calls_seen := 0
	var call_far := 0
	var call_rows: Array[Dictionary] = []
	var max_busy := 0
	var land_seen := 0
	while t < _tour_s:
		await get_tree().physics_frame
		t += STEP
		if cam == null or not is_instance_valid(cam):
			cam = get_viewport().get_camera_3d()
		var ear := cam.global_position if cam != null else car.global_position
		while land_seen < lands.size():
			lands[land_seen]["t"] = t
			land_seen += 1
		# --- clopotele
		for k in 2:
			var tr_ := trams[k]
			var dd := car.global_position.distance_to(tr_.body_position())
			for r in rings:
				if int(r["k"]) == k and float(r["reach"]) < 0.0 and t - float(r["t"]) <= 20.0:
					r["dmin"] = minf(float(r["dmin"]), dd)
					if dd <= 12.0:
						r["reach"] = t - float(r["t"])
				if int(r["k"]) == k and float(r["mouth_t"]) < 0.0 and t - float(r["t"]) <= 20.0 \
						and car.global_position.distance_to(mouth) <= 12.0:
					r["mouth_t"] = t - float(r["t"])
					r["mouth_tram"] = tr_.body_position().distance_to(mouth)
					r["mouth_hidden"] = tr_.is_hidden()
			while seen_rings[k] < tr_.bells_rung:
				seen_rings[k] += 1
				var e: Dictionary = tr_.bell_log[tr_.bell_log.size() - (tr_.bells_rung - seen_rings[k]) - 1]
				var top := tr_.body_position() + Vector3.UP * 2.6
				var q := PhysicsRayQueryParameters3D.create(ear, top)
				var excl: Array[RID] = [car.get_rid()]
				var body := tr_.get(&"_body") as CollisionObject3D
				if body != null:
					excl.append(body.get_rid())
				q.exclude = excl
				var hit := space.intersect_ray(q)
				var own_d := (float(prev_d[k]) - dd) / STEP if float(prev_d[k]) >= 0.0 else 0.0
				rings.append({"k": k, "t": t, "dist": float(e["dist"]), "closing": float(e["closing"]),
					"own_closing": own_d, "v": car.linear_velocity.length(), "hidden": tr_.is_hidden(),
					"los": hit.is_empty(), "blocker": "" if hit.is_empty() else String((hit["collider"] as Node).name),
					"pos": car.global_position, "reach": -1.0, "dmin": dd, "mouth_t": -1.0,
					"mouth_tram": -1.0, "mouth_hidden": false,
					"playing": tr_.bell_player != null and tr_.bell_player.playing})
			prev_d[k] = dd
		# --- zumzetul
		var hd := _line_dist(hum_line, ear)
		var bp := bed.bed_player
		if bp.playing:
			hum_play_s += STEP
			hum_db_max = maxf(hum_db_max, bp.volume_db)
		near_t = near_t + STEP if hd <= 10.0 else 0.0
		far_t = far_t + STEP if hd >= 50.0 else 0.0
		if near_t > bed.fade_seconds + 0.2:
			hum_on_frames += 1
			if not bp.playing or bp.volume_db < bed.bed_db - 1.0:
				hum_on_bad += 1
		if far_t > bed.fade_seconds + 0.2 and bp.playing:
			hum_off_bad += 1
		# --- scandurile
		var au: Node = car.get(&"_audio")
		var surf := int(au.get(&"surface"))
		var is_wood := surf == 4 # CarAudio.Surface.WOOD
		var p := car.global_position
		var in_core := p.x > PONTON_X.x + 5.0 and p.x < PONTON_X.y - 5.0 and absf(p.z - QUAY_Z) < 5.0 \
			and car.wheels_on_ground > 0 and car.route == 0
		var outside := p.x < PONTON_X.x - 5.0 or p.x > PONTON_X.y + 15.0 or absf(p.z - QUAY_Z) > 8.0
		if in_core:
			wood_in_frames += 1
			if not is_wood:
				wood_in_bad += 1
		if is_wood and outside:
			wood_out_bad += 1
		if is_wood:
			wood_s += STEP
			wood_on_t += STEP
			if not was_wood:
				wood_passes += 1
			wood_left_t = 0.0
		else:
			wood_on_t = 0.0
			wood_left_t += STEP
		was_wood = is_wood
		var roll: Dictionary = au.get(&"roll")
		var plank: AudioStreamPlayer3D = roll.get(4)
		var spd := car.linear_velocity.length()
		if is_wood and wood_on_t > 0.4 and spd > 3.0:
			if plank == null or not plank.playing or _stem(plank.stream) != "plank_rattle":
				plank_bad += 1
			else:
				plank_db.x = minf(plank_db.x, plank.volume_db)
				plank_db.y = maxf(plank_db.y, plank.volume_db)
		if not is_wood and wood_left_t > 0.8 and plank != null and plank.playing:
			plank_bad += 1
		# --- golful
		while calls_seen < calls.call_log.size():
			var cl: Dictionary = calls.call_log[calls_seen]
			calls_seen += 1
			var i := int(cl["spot"])
			var dsp := ear.distance_to(calls.spot_pos[i])
			if dsp > calls.spot_radius[i] + 1.0:
				call_far += 1
			call_rows.append({"t": t, "sfx": cl["sfx"], "spot": i, "d": dsp, "played": cl["played"]})
		max_busy = maxi(max_busy, AudioManager.pool3d_busy())
	# ---------------------------------------------------------------- raport
	var lap_s := 82.9
	print("  playere audio sub pista: %d (%s)" % [track_players.size(),
		", ".join(track_players.map(func(x: Node) -> String: return String(x.name)))])
	_check(track_players.size() == 3, "pista adauga 3 playere (2 clopote + zumzetul); scandurile: 1 in CarAudio")
	var au_end: Node = car.get(&"_audio")
	var roll_end: Dictionary = au_end.get(&"roll")
	print("  CarAudio: playere de rulare create: %d (%s)" % [roll_end.size(), str(roll_end.keys())])
	print("  pool 3D comun: cel mult %d / %d ocupate" % [max_busy, AudioManager.POOL3D_SIZE])
	# clopote
	print("  clopote: %d (urcarea %d, gura %d)" % [rings.size(), trams[0].bells_rung, trams[1].bells_rung])
	var bad_ring := 0
	for r in rings:
		var nm := "urcare" if int(r["k"]) == 0 else "gura"
		var p: Vector3 = r["pos"]
		print("    t %6.1f  %-6s  la %5.1f m, apropiere %5.1f m/s (masurat %5.1f), v %4.1f m/s, la (%.0f, %.0f), "
			% [r["t"], nm, r["dist"], r["closing"], r["own_closing"], r["v"], p.x, p.z]
			+ "vagonul %s, avans pana la 12 m: %s (cel mai aproape %.1f m)"
			% ["VIZIBIL" if r["los"] else "ascuns de " + String(r["blocker"]),
				("%.2f s" % r["reach"]) if float(r["reach"]) >= 0.0 else "nu ajunge", r["dmin"]])
		if float(r["mouth_t"]) >= 0.0:
			print("      -> masina ajunge in gura scurtaturii dupa %.2f s; vagonul atunci la %.1f m de gura%s"
				% [r["mouth_t"], r["mouth_tram"], " (ascuns)" if r["mouth_hidden"] else ""])
		if bool(r["hidden"]) or float(r["dist"]) > trams[int(r["k"])].bell_range_m + 0.5 \
				or float(r["own_closing"]) < 0.5 or not bool(r["playing"]):
			bad_ring += 1
	_check(bad_ring == 0, "fiecare clopot: vagon vizibil, in raza, la apropiere reala, player pornit (%d abateri)"
		% bad_ring)
	for k in 2:
		var ts: Array = rings.filter(func(r: Dictionary) -> bool: return int(r["k"]) == k).map(
			func(r: Dictionary) -> float: return float(r["t"]))
		var min_gap := INF
		for i in range(1, ts.size()):
			min_gap = minf(min_gap, float(ts[i]) - float(ts[i - 1]))
		_check(ts.size() <= int(ceil(_tour_s / lap_s)) * 2 + 1,
			"%s: %d clopote in %.0f s (cel mult 2 pe tur)" % [trams[k].name, ts.size(), _tour_s])
		if ts.size() > 1:
			_check(min_gap >= trams[k].bell_min_gap_s - 0.05, "%s: cel putin %.0f s intre doua clopote (%.1f)"
				% [trams[k].name, trams[k].bell_min_gap_s, min_gap])
	# zumzet
	print("  zumzet: %.1f s pornit din %.0f s, varf %.1f dB; %d cadre pe strada (dupa intrare)"
		% [hum_play_s, _tour_s, hum_db_max, hum_on_frames])
	_check(hum_on_frames > 60 and hum_on_bad == 0, "zumzet plin pe strada tramvaiului (%d abateri din %d cadre)"
		% [hum_on_bad, hum_on_frames])
	_check(hum_off_bad == 0, "zumzet oprit la >= 50 m de strada (%d abateri)" % hum_off_bad)
	_check(hum_play_s < _tour_s * 0.5, "zumzetul nu e peste tot (%.0f%% din timp)" % (100.0 * hum_play_s / _tour_s))
	# scanduri
	print("  scanduri: %d treceri, %.1f s pe lemn, %d cadre in miezul pontonului, nivel %.1f..%.1f dB"
		% [wood_passes, wood_s, wood_in_frames, plank_db.x, plank_db.y])
	_check(wood_in_frames > 30 and wood_in_bad == 0, "pe miezul pontonului, cu rotile jos: suprafata WOOD (%d abateri din %d)"
		% [wood_in_bad, wood_in_frames])
	_check(wood_out_bad == 0, "WOOD niciodata in afara pontonului (%d cadre)" % wood_out_bad)
	_check(plank_bad == 0, "bucla plank_rattle porneste pe lemn si se opreste dupa (%d abateri)" % plank_bad)
	# golful
	var per := {}
	var min_dt := INF
	for i in call_rows.size():
		var key := String(call_rows[i]["sfx"])
		per[key] = int(per.get(key, 0)) + 1
		if i > 0:
			min_dt = minf(min_dt, float(call_rows[i]["t"]) - float(call_rows[i - 1]["t"]))
	var played := call_rows.filter(func(r: Dictionary) -> bool: return bool(r["played"])).size()
	print("  golful: %d strigate (%s), %d redate; cel mai scurt interval %.2f s; %.1f / minut"
		% [call_rows.size(), str(per), played, min_dt, call_rows.size() * 60.0 / _tour_s])
	for r in call_rows:
		print("    t %6.1f  %-14s loc %d, urechea la %.0f m" % [r["t"], r["sfx"], r["spot"], r["d"]])
	_check(call_far == 0, "fiecare strigat cu urechea in raza locului (%d in afara)" % call_far)
	_check(call_rows.size() == 0 or min_dt >= calls.global_gap_s - 0.05,
		"strigatele la cel putin %.1f s unul de altul" % calls.global_gap_s)
	_check(call_rows.size() * 60.0 / _tour_s <= 15.0, "golful presarat: <= 15 strigate pe minut")
	_check(call_rows.size() >= 2, "golful chiar striga (%d)" % call_rows.size())
	# aterizari
	var chain := lands.filter(func(l: Dictionary) -> bool:
		var q: Vector3 = l["pos"]
		return absf(q.x) < 20.0 and q.z > -320.0 and q.z < 110.0)
	print("  aterizari: %d in %.0f s (%.1f pe tur), din care pe lant %d" % [lands.size(), _tour_s,
		lands.size() * lap_s / _tour_s, chain.size()])
	for l in lands:
		var q: Vector3 = l["pos"]
		var names := ", ".join((l["plan"] as Array).map(func(e: Dictionary) -> String:
			return "%s %.1f dB p%.2f" % [e["name"], e["db"], e["pitch"]]))
		print("    t %6.1f  cadere %5.1f m/s  la (%.0f, %.0f)  %s  -> %s" % [l["t"], l["fs"], q.x, q.z,
			"LANT" if chain.has(l) else "", names])
	race.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
