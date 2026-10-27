extends Node
## Garda pasurilor 4a+4b ale carierei: provocarea gimmick-ului.
##
## Ce garanteaza, cu cifre (nu "n-a crapat"):
##  1. DATE: cele 12 provocari se incarca, `validate()` e goala pe config-ul real,
##     iar un config sabotat in memorie (event necunoscut / pista inexistenta /
##     doua provocari pe aceeasi pista) iese cu CATE O problema pe sabotaj.
##  2. TRACKER: pentru fiecare event, un semnal al ALTEI masini lasa `events`
##     la 0 (o sonda care numara orice nu e garda), unul al jucatorului il
##     face 1 si `failed`; plus pragul `splash` si `traffic_bump` cu/fara
##     TrafficController. Sursele sunt instante REALE ale scripturilor de
##     hazard (`.new()`, fara scena si fara _ready), pasate prin
##     `setup(..., sources)`: tracker-ul nu are cum sa "reuseasca" pe un nod
##     inventat, iar scena pistei nu trebuie incarcata.
##  3. CAREER: provocarea e BONUS (+1) in cursa normala de cariera (25 oct 2026):
##     RACE o poarta (`challenge_to_track`), contratimpul nu; `finish_active`
##     da punctele locului + bonusul, bifa nu cere podium si nu se pierde la
##     un esec ulterior; pe o pista fara provocare bonusul nu exista.
##  4. FOAIA: fara buton CHALLENGE; eticheta BONUS (titlu + hint) pe pistele
##     cu provocare, DONE cand e bifata, si NIMIC pe o pista fara provocare.
##  5. PISTE REALE: pentru fiecare provocare pe semnal de hazard, pista se
##     incarca si contine cel putin o sursa a semnalului cerut (altfel
##     contractul ar fi o garda fara nimic de masurat).
##
## Ruleaza CA SCENA: godot --headless --path . res://tools/ProbeChallenge.tscn

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const TMP_PATH: String = "user://probe_challenge.cfg"
## Sub plafon un refactor care sare peste jumatate din verificari pica.
const MIN_CHECKS := 170
const EXPECTED := {
	&"kyoto": &"thrown", &"stromboli": &"fireball", &"serengeti": &"animal",
	&"okinawa": &"splash", &"monument_valley": &"crush",
	&"machu_picchu": &"shove", &"jodhpur": &"traffic_bump",
	&"transfagarasan": &"red_run", &"cappadocia": &"wall_hit",
	&"chongqing": &"boarded", &"baikal": &"plate_broken",
	&"fiordland": &"branch",
}
## Regula fiecarei provocari (4a: toate ZERO_EVENTS).
const RULES := {
	&"transfagarasan": CareerChallenge.Rule.AT_LEAST,
	&"cappadocia": CareerChallenge.Rule.ZERO_EVENTS,
	&"chongqing": CareerChallenge.Rule.EVERY_LAP,
	&"baikal": CareerChallenge.Rule.CLEAN_LAP,
	&"fiordland": CareerChallenge.Rule.EVERY_LAP,
}
## Pista fara provocare (pentru contra-probe).
const NO_CHALLENGE_TRACK: StringName = &"halong"

var _fails: Array[String] = []
var _checks: int = 0
var _real_save_path: String
var _real_config: CareerConfig


func _ready() -> void:
	_real_save_path = Career.save_path
	_real_config = Career.config
	Career.save_path = TMP_PATH
	_remove_tmp()
	Career.load_progress()

	_check_data()
	await _check_tracker()
	await _check_rules()
	_check_new_signals()
	_check_career()
	await _check_sheet()
	_check_real_tracks()

	Career.config = _real_config
	Career.save_path = _real_save_path
	Career.race_starter = Callable()
	Career.leave()
	_remove_tmp()
	if _checks < MIN_CHECKS:
		_fails.append("doar %d verificari (< %d): sonda a sarit peste ceva" % [_checks, MIN_CHECKS])
	for f in _fails:
		print("  PICAT: ", f)
	print("verificari: %d" % _checks)
	print("VERDICT: ", "OK" if _fails.is_empty() else "PROBLEMA (%d)" % _fails.size())
	get_tree().quit(1 if not _fails.is_empty() else 0)


func _expect(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _remove_tmp() -> void:
	var abs_path := ProjectSettings.globalize_path(TMP_PATH)
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)


func _collect(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		out.append(child)
		_collect(child, out)


## Copie in memorie a config-ului real (sabotajul nu atinge resursa partajata).
func _clone(drop_track: StringName = &"") -> CareerConfig:
	var out := CareerConfig.new()
	out.worlds = _real_config.worlds.duplicate()
	for c in _real_config.challenges:
		if c.track == drop_track:
			continue
		out.challenges.append(c.duplicate() as CareerChallenge)
	return out


# ------------------------------------------------------------------ 1. date

func _check_data() -> void:
	var cfg := _real_config
	_expect(cfg.challenges.size() == EXPECTED.size(),
		"12 provocari in config, sunt %d" % cfg.challenges.size())
	_expect(Career.validate().is_empty(),
		"validate() goala pe config-ul real: %s" % [Career.validate()])
	for track_id in EXPECTED:
		var c := Career.challenge_for(track_id)
		_expect(c != null, "challenge_for(%s) exista" % track_id)
		if c == null:
			continue
		_expect(c.event == EXPECTED[track_id],
			"%s asculta '%s', nu '%s'" % [track_id, EXPECTED[track_id], c.event])
		_expect(c.title != "" and c.hint != "", "%s are titlu si hint" % track_id)
		var want_rule: int = RULES.get(track_id, CareerChallenge.Rule.ZERO_EVENTS)
		_expect(c.rule == want_rule, "%s: regula %d, nu %d" % [track_id, want_rule, c.rule])
	_expect(Career.challenge_for(NO_CHALLENGE_TRACK) == null, "halong n-are provocare")
	# 4b: contractele noi, cu cifra (DE CE: o schimbare tacuta a lor schimba proba).
	var rr := Career.challenge_for(&"transfagarasan")
	_expect(rr.count == 3 and rr.fail_event == &"bus_hit",
		"transfagarasan: 3 treceri pe rosu, pica la bus_hit (%d, %s)" % [rr.count, rr.fail_event])
	var cap := Career.challenge_for(&"cappadocia")
	_expect(cap.zone == &"StancaSpirala", "cappadocia: zona StancaSpirala")
	# 8 = pragul de la care Car emite wall_hit (frecare); 26 = eject_wall_dv.
	_expect(cap.threshold > 8.0 and cap.threshold < 26.0,
		"cappadocia: prag intre frecare (8) si ejectie (26): %s" % cap.threshold)
	_expect(Career.challenge_for(&"nu_exista") == null, "pista necunoscuta => null")
	var okinawa := Career.challenge_for(&"okinawa")
	_expect(okinawa != null and okinawa.threshold > 0.22 and okinawa.threshold < 0.75,
		"prag Okinawa intre stropire (0.22) si val (0.75)")

	# Sabotaje: fiecare produce problema ei.
	var bad_event := _clone()
	bad_event.challenges[0].event = &"inventat"
	_expect(_count_problems(bad_event, "nu e cunoscut") == 1, "sabotaj: event necunoscut")
	var bad_track := _clone()
	bad_track.challenges[0].track = &"pista_fantoma"
	_expect(_count_problems(bad_track, "pista nu exista") == 1, "sabotaj: pista inexistenta")
	var dup := _clone()
	dup.challenges[1].track = dup.challenges[0].track
	_expect(_count_problems(dup, "doua provocari") == 1, "sabotaj: doua provocari pe aceeasi pista")
	# 4b: AT_LEAST fara count, fail_event inventat, wall_hit fara zona.
	var no_count := _clone()
	_mutate(no_count, &"transfagarasan", func(c: CareerChallenge) -> void: c.count = 0)
	_expect(_count_problems(no_count, "count >= 1") == 1, "sabotaj: AT_LEAST cu count = 0")
	var bad_fail := _clone()
	_mutate(bad_fail, &"transfagarasan", func(c: CareerChallenge) -> void: c.fail_event = &"inventat")
	_expect(_count_problems(bad_fail, "fail_event") == 1, "sabotaj: fail_event necunoscut")
	var no_zone := _clone()
	_mutate(no_zone, &"cappadocia", func(c: CareerChallenge) -> void: c.zone = &"")
	_expect(_count_problems(no_zone, "cere o zona") == 1, "sabotaj: wall_hit fara zona")
	_expect(Career.validate(_clone()).is_empty(), "clona nesabotata e sanatoasa (contra-proba)")


func _mutate(cfg: CareerConfig, track_id: StringName, change: Callable) -> void:
	for c in cfg.challenges:
		if c.track == track_id:
			change.call(c)


func _count_problems(cfg: CareerConfig, needle: String) -> int:
	var n := 0
	for p in Career.validate(cfg):
		if needle in p:
			n += 1
	return n


# --------------------------------------------------------------- 2. tracker

func _make_car(player: bool) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.is_player = player
	return car


func _track_of(event: StringName) -> StringName:
	for k in EXPECTED:
		if EXPECTED[k] == event:
			return k
	return &""


func _tracker_for(event: StringName, player: Car, sources: Array[Node]) -> ChallengeTracker:
	var c := Career.challenge_for(_track_of(event)).duplicate() as CareerChallenge
	var t := ChallengeTracker.new()
	add_child(t)
	t.setup(c, player, null, sources)
	return t


func _check_tracker() -> void:
	var player := _make_car(true)
	var other := _make_car(false)
	await get_tree().process_frame

	var hazard_cases := [
		[&"thrown", "res://scenes/hazards/gion_matsuri_hazard.gd", "car_thrown"],
		[&"thrown", "res://scenes/hazards/shishimai_hazard.gd", "car_thrown"],
		[&"thrown", "res://scenes/hazards/shishi_odoshi_hazard.gd", "car_thrown"],
		[&"thrown", "res://scenes/hazards/daruma_otoshi_hazard.gd", "car_thrown"],
		[&"fireball", "res://scenes/hazards/fireball_geyser.gd", "fireball_hit"],
		[&"animal", "res://scenes/hazards/herd_hazard.gd", "animal_hit"],
		[&"shove", "res://scenes/hazards/bus_hazard.gd", "shoved"],
	]
	for hc in hazard_cases:
		var event: StringName = hc[0]
		var hazard := (load(hc[1] as String) as GDScript).new() as Node
		var src: Array[Node] = [hazard]
		var t := _tracker_for(event, player, src)
		var label := "%s/%s" % [event, (hc[1] as String).get_file()]
		_emit_hazard(hazard, hc[2], other)
		_expect(t.events == 0 and not t.failed and t.evaluate(),
			"%s: semnalul ALTEI masini nu se numara (events=%d)" % [label, t.events])
		_emit_hazard(hazard, hc[2], player)
		_expect(t.events == 1 and t.failed and not t.evaluate(),
			"%s: semnalul jucatorului da 1 si failed (events=%d)" % [label, t.events])
		_emit_hazard(hazard, hc[2], player)
		_expect(t.events == 2, "%s: numara fiecare eveniment (events=%d)" % [label, t.events])
		t.queue_free()
		hazard.free()

	# crush
	var tc := _tracker_for(&"crush", player, [] as Array[Node])
	other.crushed.emit(other, 1.0)
	_expect(tc.events == 0, "crush: strivirea altei masini nu se numara")
	player.crushed.emit(player, 0.5)
	_expect(tc.events == 1 and tc.failed, "crush: strivirea jucatorului pica provocarea")
	tc.queue_free()

	# splash cu prag
	var ts := _tracker_for(&"splash", player, [] as Array[Node])
	var thr := ts.challenge.threshold
	player.splashed.emit(player, 0.22)
	_expect(ts.events == 0 and not ts.failed, "splash: stropirea (0.22) sub prag nu se numara")
	player.splashed.emit(player, thr - 0.01)
	_expect(ts.events == 0, "splash: chiar sub prag nu se numara")
	player.splashed.emit(player, 0.75)
	_expect(ts.events == 1 and ts.failed, "splash: valul (0.75) peste prag se numara")
	ts.queue_free()

	# traffic_bump
	var tb := _tracker_for(&"traffic_bump", player, [] as Array[Node])
	var ai_car := _make_car(false)
	ai_car.set_controller(AIController.new())
	var tuk := _make_car(false)
	tuk.set_controller(TrafficController.new())
	await get_tree().process_frame
	player.bumped.emit(player, ai_car, 5.0)
	_expect(tb.events == 0, "traffic_bump: ciocnirea cu un AI nu se numara")
	player.bumped.emit(player, tuk, 5.0)
	_expect(tb.events == 1 and tb.failed, "traffic_bump: tuk-tuk-ul (TrafficController) se numara")
	tb.queue_free()

	# failed_changed o singura data
	var tf := _tracker_for(&"crush", player, [] as Array[Node])
	var fired := [0]
	tf.failed_changed.connect(func(_f: bool) -> void: fired[0] += 1)
	player.crushed.emit(player, 0.5)
	player.crushed.emit(player, 0.5)
	_expect(fired[0] == 1, "failed_changed se emite o singura data (%d)" % fired[0])
	tf.queue_free()
	for car in [player, other, ai_car, tuk]:
		(car as Node).queue_free()


func _emit_hazard(hazard: Node, signal_name: String, car: Car) -> void:
	match signal_name:
		"car_thrown":
			# shishi-odoshi are un al doilea argument (on_strike)
			var two_args := false
			for s in hazard.get_signal_list():
				if s.name == "car_thrown" and (s.args as Array).size() == 2:
					two_args = true
			if two_args:
				hazard.emit_signal("car_thrown", car, false)
			else:
				hazard.emit_signal("car_thrown", car)
		"animal_hit": hazard.emit_signal("animal_hit", car, 1.0)
		"shoved": hazard.emit_signal("shoved", hazard, car)
		_: hazard.emit_signal(signal_name, car)


# ------------------------------------------------- 2b. reguli noi (4b)

func _tracker_c(c: CareerChallenge, player: Car, track: Node, sources: Array[Node]) -> ChallengeTracker:
	var t := ChallengeTracker.new()
	add_child(t)
	t.setup(c.duplicate() as CareerChallenge, player, track, sources)
	return t


func _hz(path: String) -> Node:
	return (load(path) as GDScript).new() as Node


func _check_rules() -> void:
	var player := _make_car(true)
	var other := _make_car(false)
	await get_tree().process_frame

	# --- AT_LEAST + fail_event (Transfagarasan). O singura instanta de semafor
	# da ambele semnale (passed_on_red si bus_hit).
	var sem := _hz("res://scenes/hazards/tunnel_signal_hazard.gd")
	var src: Array[Node] = [sem]
	var base := Career.challenge_for(&"transfagarasan")
	var t := _tracker_c(base, player, null, src)
	sem.emit_signal("passed_on_red", other)
	_expect(t.events == 0, "red_run: trecerea ALTEI masini nu se numara")
	sem.emit_signal("passed_on_red", player)
	sem.emit_signal("passed_on_red", player)
	_expect(t.events == 2 and not t.failed and not t.evaluate(),
		"AT_LEAST 3: 2 evenimente => nereusit, dar nu picat (events=%d)" % t.events)
	_expect(t.progress_text() == "2 / 3", "progres AT_LEAST '2 / 3' ('%s')" % t.progress_text())
	sem.emit_signal("passed_on_red", player)
	_expect(t.evaluate(), "AT_LEAST 3: 3 evenimente => reusit")
	sem.emit_signal("bus_hit", other)
	_expect(t.evaluate() and not t.failed, "bus_hit al ALTEI masini nu pica provocarea")
	var fired := [0]
	t.failed_changed.connect(func(_f: bool) -> void: fired[0] += 1)
	sem.emit_signal("bus_hit", player)
	sem.emit_signal("bus_hit", player)
	_expect(t.failed and not t.evaluate() and t.events == 3,
		"3 evenimente + bus_hit al jucatorului => picat (events=%d)" % t.events)
	_expect(fired[0] == 1, "failed_changed o singura data la bus_hit (%d)" % fired[0])
	t.queue_free()
	sem.free()

	# --- EVERY_LAP (Chongqing, boarded)
	var cab := _hz("res://scenes/hazards/cableway_hazard.gd")
	var csrc: Array[Node] = [cab]
	var ch := Career.challenge_for(&"chongqing")
	var te := _tracker_c(ch, player, null, csrc)
	cab.emit_signal("boarded", other)
	_expect(te.events == 0, "boarded: imbarcarea ALTEI masini nu se numara")
	_expect(te.progress_text() == "LAP 1", "EVERY_LAP progres fara eveniment 'LAP 1' ('%s')" % te.progress_text())
	cab.emit_signal("boarded", player)
	_expect(te.progress_text() == "LAP 1 \u2713", "EVERY_LAP progres cu eveniment ('%s')" % te.progress_text())
	te.notify_lap(1)
	cab.emit_signal("boarded", player)
	te.notify_lap(2)
	_expect(not te.failed, "EVERY_LAP: 2 ture cu eveniment nu pica")
	cab.emit_signal("boarded", player)
	te.notify_lap(3)
	_expect(te.evaluate() and str(te.closed_laps) == "[1, 1, 1]",
		"EVERY_LAP: 3 ture cu >= 1 => reusit (%s)" % [te.closed_laps])
	te.queue_free()
	var tf := _tracker_c(ch, player, null, csrc)
	var fl := [0]
	tf.failed_changed.connect(func(_f: bool) -> void: fl[0] += 1)
	cab.emit_signal("boarded", player)
	tf.notify_lap(1)
	_expect(not tf.failed, "EVERY_LAP: turul 1 cu eveniment, inca viu")
	tf.notify_lap(2)
	_expect(tf.failed and not tf.evaluate() and fl[0] == 1,
		"EVERY_LAP: turul 2 incheiat cu 0 pica PE LOC, o singura data (%d)" % fl[0])
	tf.notify_lap(3)
	_expect(fl[0] == 1, "EVERY_LAP: nu re-emite failed_changed")
	tf.queue_free()
	cab.free()

	# --- CLEAN_LAP (Baikal, plate_broken)
	var ice := _hz("res://scenes/hazards/ice_field_hazard.gd")
	var isrc: Array[Node] = [ice]
	var bk := Career.challenge_for(&"baikal")
	var with_player: Array[Car] = [player]
	var without_player: Array[Car] = [other]
	var tcl := _tracker_c(bk, player, null, isrc)
	ice.emit_signal("plate_broken", without_player)
	_expect(tcl.events == 0, "plate_broken fara jucator in `cars` nu se numara")
	ice.emit_signal("plate_broken", with_player)
	ice.emit_signal("plate_broken", with_player)
	_expect(tcl.events == 2, "plate_broken cu jucator se numara (%d)" % tcl.events)
	_expect(tcl.progress_text() == "LAP 1: 2 PLATES", "progres CLEAN_LAP ('%s')" % tcl.progress_text())
	tcl.notify_lap(1)
	_expect(not tcl.failed, "CLEAN_LAP: tur cu placi nu pica pe loc")
	tcl.notify_lap(2) # tur cu 0
	ice.emit_signal("plate_broken", with_player)
	tcl.notify_lap(3)
	_expect(tcl.evaluate() and str(tcl.closed_laps) == "[2, 0, 1]",
		"CLEAN_LAP: ture 2,0,1 => reusit (%s)" % [tcl.closed_laps])
	tcl.queue_free()
	var tcn := _tracker_c(bk, player, null, isrc)
	for n in [2, 1, 3]:
		for i in n:
			ice.emit_signal("plate_broken", with_player)
		tcn.notify_lap(0)
	_expect(not tcn.evaluate() and str(tcn.closed_laps) == "[2, 1, 3]",
		"CLEAN_LAP: ture 2,1,3 => nereusit (%s)" % [tcn.closed_laps])
	tcn.queue_free()
	ice.free()

	# --- wall_hit: prag + zona (CameraZone in mod cutie, ca in productie)
	var track := Node3D.new()
	add_child(track)
	var zone := CameraZone.new()
	zone.name = "StancaSpirala"
	zone.size = Vector3(20, 20, 20)
	zone.collision_mask = 0xFFFFF
	track.add_child(zone)
	zone.global_position = Vector3(500, 0, 0)
	var ws := Career.challenge_for(&"cappadocia")
	var tw := _tracker_c(ws, player, track, [] as Array[Node])
	_expect(tw._zone_node == zone, "wall_hit: zona gasita dupa nume in pista")
	player.gravity_scale = 0.0
	player.freeze = true
	player.global_position = Vector3(500, 1, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(zone.overlaps_body(player), "premisa: masina e in zona sintetica")
	player.wall_hit.emit(player, ws.threshold - 0.5)
	_expect(tw.events == 0, "wall_hit sub prag in zona nu se numara")
	player.wall_hit.emit(player, ws.threshold + 0.5)
	_expect(tw.events == 1 and tw.failed, "wall_hit peste prag in zona pica (ZERO_EVENTS)")
	tw.queue_free()
	var tw2 := _tracker_c(ws, player, track, [] as Array[Node])
	player.global_position = Vector3(0, 1, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(not zone.overlaps_body(player), "premisa: masina e in afara zonei")
	player.wall_hit.emit(player, ws.threshold + 10.0)
	_expect(tw2.events == 0 and not tw2.failed,
		"wall_hit peste prag in AFARA zonei nu se numara")
	tw2.queue_free()
	# zona lipsa: nu numara niciodata (si avertizeaza)
	var empty_track := Node3D.new()
	var tw3 := _tracker_c(ws, player, empty_track, [] as Array[Node])
	player.global_position = Vector3(500, 1, 0)
	await get_tree().physics_frame
	player.wall_hit.emit(player, 99.0)
	_expect(tw3.events == 0, "zona lipsa: evenimentul nu numara (de aceea pista reala e verificata)")
	tw3.queue_free()
	empty_track.free()
	track.queue_free()

	# --- branch: sondat din player.route
	var fo := Career.challenge_for(&"fiordland")
	var tb := _tracker_c(fo, player, null, [] as Array[Node])
	player.route = 0
	await get_tree().physics_frame
	_expect(tb.lap_events == 0, "branch: pe ruta 0 nu se marcheaza")
	player.route = 1
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(tb.lap_events == 1 and tb.events == 1,
		"branch: primul tick pe ruta !=0 marcheaza turul, o data (%d)" % tb.lap_events)
	tb.notify_lap(1)
	_expect(not tb.failed, "branch: tur 1 cu scurtatura nu pica")
	player.route = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(tb.lap_events == 0, "branch: tur nou pe ruta 0 ramane nemarcat")
	tb.notify_lap(2)
	_expect(tb.failed and not tb.evaluate(), "branch: tur fara scurtatura pica provocarea")
	tb.queue_free()
	player.route = 0

	# --- detectia de trecere pe rosu a semaforului REAL (o adaugam noi: nu avea)
	var sg := TunnelSignalHazard.new()
	add_child(sg)
	sg.global_position = Vector3(0, 0, 2000)
	var passes: Array[Car] = []
	sg.passed_on_red.connect(func(c: Car) -> void: passes.append(c))
	player.gravity_scale = 0.0
	player.freeze = true
	# verde: trecerea liniei nu conteaza
	sg._clock = 1.0
	_expect(not sg.is_red(), "premisa: semaforul e verde la t=1")
	player.global_position = Vector3(0, 1, 1999)
	await get_tree().physics_frame
	player.global_position = Vector3(0, 1, 2001)
	await get_tree().physics_frame
	_expect(passes.is_empty(), "trecere pe VERDE nu emite passed_on_red (%d)" % passes.size())
	# rosu: o trecere = un semnal
	sg._clock = sg.green_hold() + 1.0
	_expect(sg.is_red(), "premisa: semaforul e rosu")
	player.global_position = Vector3(0, 1, 1999)
	await get_tree().physics_frame
	player.global_position = Vector3(0, 1, 2001)
	await get_tree().physics_frame
	_expect(passes.size() == 1 and passes[0] == player,
		"trecere pe ROSU emite o data cu masina (%d)" % passes.size())
	await get_tree().physics_frame
	_expect(passes.size() == 1, "cat stai in tunel nu re-emite (%d)" % passes.size())
	# inapoi si iar peste linie in acelasi rosu: tot o trecere
	player.global_position = Vector3(0, 1, 1999)
	await get_tree().physics_frame
	player.global_position = Vector3(0, 1, 2001)
	await get_tree().physics_frame
	_expect(passes.size() == 1, "aceeasi masina, acelasi rosu: o singura trecere (%d)" % passes.size())
	# alt drum in paralel (lateral > podul liniei): nu conteaza
	sg._clock = sg.green_hold() + 1.0
	sg._red_counted.clear()
	player.global_position = Vector3(40, 1, 1999)
	await get_tree().physics_frame
	player.global_position = Vector3(40, 1, 2001)
	await get_tree().physics_frame
	_expect(passes.size() == 1, "trecere la 40 m lateral nu conteaza (%d)" % passes.size())
	sg.queue_free()
	player.queue_free()
	other.queue_free()
	await get_tree().process_frame


# --------------------------------------------- 2c. semnalele noi exista

func _check_new_signals() -> void:
	var cases := [
		["res://scenes/hazards/tunnel_signal_hazard.gd", "passed_on_red"],
		["res://scenes/hazards/tunnel_signal_hazard.gd", "bus_hit"],
		["res://scenes/hazards/cableway_hazard.gd", "boarded"],
		["res://scenes/hazards/ice_field_hazard.gd", "plate_broken"],
	]
	for c in cases:
		var h := _hz(c[0] as String)
		_expect(h.has_signal(c[1] as String),
			"%s are semnalul '%s'" % [(c[0] as String).get_file(), c[1]])
		h.free()


# ---------------------------------------------------------------- 3. career

func _check_career() -> void:
	_remove_tmp()
	Career.load_progress()
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	GameState.ai_count = 3
	Career.start_track(&"kyoto", Career.Mode.RACE)
	_expect(Career.active and Career.active_mode == Career.Mode.RACE, "start_track(RACE) seteaza modul")
	_expect(started[0] == 1, "cursa porneste")
	_expect(GameState.ai_count == 3, "ai_count neatins (cursa cu AI), este %d" % GameState.ai_count)
	_expect(Career.challenge_to_track() != null
		and Career.challenge_to_track() == Career.challenge_for(&"kyoto"),
		"cursa normala de cariera poarta provocarea pistei")
	var points0 := Career.points()
	_expect(Career.finish_active(5, false) == 0, "locul 5 fara provocare = 0 puncte")
	_expect(not bool(Career.track_state(&"kyoto").challenge) and Career.points() == points0,
		"un esec nu pune nimic")
	_expect(Career.finish_active(5, true) == Career.CHALLENGE_POINTS,
		"locul 5 cu provocarea reusita = +1 (bonusul nu cere podium)")
	_expect(bool(Career.track_state(&"kyoto").challenge) and Career.points() == points0 + 1,
		"reusita pune bifa si +1 punct")
	_expect(int(Career.track_state(&"kyoto").race_medal) == 0, "sub podium nu da medalie de cursa")
	_expect(Career.finish_active(1, true) == Career.MAX_TRACK_POINTS,
		"locul 1 + provocare = 4 puncte intr-o cursa")
	_expect(Career.points() == points0 + Career.MAX_TRACK_POINTS,
		"pe raft: 3 + 1 = 4 (bifa nu se numara de doua ori)")
	Career.finish_active(5, false)
	_expect(bool(Career.track_state(&"kyoto").challenge)
		and int(Career.track_state(&"kyoto").race_medal) == Career.MEDAL_GOLD,
		"reusita si locul nu se pierd la o cursa mai slaba")
	Career.leave()
	_expect(Career.challenge_to_track() == null, "dupa leave() nu mai e provocare de urmarit")
	_expect(Career.finish_active(1, true) == 0, "in afara carierei finish_active nu da puncte")
	# Contratimpul nu poarta provocarea (singur pe pista, fara trafic).
	Career.start_track(&"kyoto", Career.Mode.TIME_TRIAL)
	_expect(Career.is_time_trial() and Career.challenge_to_track() == null,
		"contratimpul nu are provocare")
	Career.leave()
	# Pista fara provocare: bonusul nu exista, chiar daca cineva il raporteaza.
	Career.start_track(NO_CHALLENGE_TRACK, Career.Mode.RACE)
	_expect(Career.challenge_to_track() == null, "%s: fara provocare de urmarit" % NO_CHALLENGE_TRACK)
	_expect(Career.finish_active(1, true) == Career.MEDAL_GOLD,
		"fara provocare pe pista, bonusul nu se da (doar locul)")
	_expect(not bool(Career.track_state(NO_CHALLENGE_TRACK).challenge),
		"fara provocare pe pista, bifa nu se pune")
	Career.leave()
	Career.race_starter = Callable()


# ----------------------------------------------------------------- 4. foaia

func _sheet_buttons(panel: CareerPanel) -> Dictionary:
	var nodes: Array[Node] = []
	_collect(panel._sheet, nodes)
	var out := {}
	for n in nodes:
		if n is Button:
			out[n.name] = n
	return out


func _sheet_labels(panel: CareerPanel) -> Dictionary:
	var nodes: Array[Node] = []
	_collect(panel._sheet, nodes)
	var out := {}
	for n in nodes:
		if n is Label:
			out[n.name] = n
	return out


func _check_sheet() -> void:
	Career.config = _real_config
	_remove_tmp()
	Career.load_progress()
	var panel := CareerPanel.new()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	var zero_pts := "%d / %d PTS" % [0, Career.MAX_TRACK_POINTS]
	for track_id in EXPECTED:
		panel._open_sheet(track_id)
		await get_tree().process_frame
		var buttons := _sheet_buttons(panel)
		var bonus: Label = _sheet_labels(panel).get("BonusLabel")
		var c := Career.challenge_for(track_id)
		_expect(not buttons.has("ChallengeButton"), "%s: fara buton CHALLENGE" % track_id)
		_expect(bonus != null, "%s: eticheta BONUS exista" % track_id)
		if bonus != null:
			_expect(c.title in bonus.text and c.hint in bonus.text and not ("SOON" in bonus.text)
				and ("+%d" % Career.CHALLENGE_POINTS) in bonus.text and not ("DONE" in bonus.text),
				"%s: BONUS = +1, titlu + hint, nebifata ('%s')" % [track_id, bonus.text])
		var race: Button = buttons.get("RaceButton")
		_expect(race != null and "NO PODIUM YET" in race.text and zero_pts in race.text,
			"%s: RACE arata 'NO PODIUM YET · %s' ('%s')" % [track_id, zero_pts,
				race.text if race != null else ""])
	# RACE porneste cursa normala, care poarta provocarea.
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	panel._open_sheet(&"kyoto")
	await get_tree().process_frame
	(_sheet_buttons(panel)["RaceButton"] as Button).pressed.emit()
	_expect(started[0] == 1 and Career.active and Career.active_track == &"kyoto"
		and Career.challenge_to_track() == Career.challenge_for(&"kyoto"),
		"apasarea RACE porneste cursa pe Kyoto cu provocarea ei")
	Career.finish_active(3, true)
	Career.leave()
	panel._open_sheet(&"kyoto")
	await get_tree().process_frame
	var done: Label = _sheet_labels(panel)["BonusLabel"]
	_expect("DONE" in done.text, "Kyoto bifata: BONUS ... DONE ('%s')" % done.text)
	var race_after: Button = _sheet_buttons(panel)["RaceButton"]
	var two_pts := "%d / %d PTS" % [Career.MEDAL_BRONZE + Career.CHALLENGE_POINTS,
		Career.MAX_TRACK_POINTS]
	_expect("3RD PLACE" in race_after.text and two_pts in race_after.text,
		"Kyoto dupa locul 3 + bonus: '3RD PLACE · %s' ('%s')" % [two_pts, race_after.text])
	panel.queue_free()
	await get_tree().process_frame

	# O pista FARA provocare (Kyoto scoasa din config in memorie): nicio
	# eticheta BONUS, niciun buton CHALLENGE, 3 butoane.
	Career.config = _clone(&"kyoto")
	var panel2 := CareerPanel.new()
	add_child(panel2)
	await get_tree().process_frame
	panel2._open_sheet(&"kyoto")
	await get_tree().process_frame
	var buttons2 := _sheet_buttons(panel2)
	_expect(not _sheet_labels(panel2).has("BonusLabel") and not buttons2.has("ChallengeButton")
		and buttons2.size() == 3,
		"fara provocare: fara BONUS, fara CHALLENGE, 3 butoane (%d)" % buttons2.size())
	panel2.queue_free()
	Career.config = _real_config
	Career.race_starter = Callable()
	await get_tree().process_frame


# ------------------------------------------------- 5. pistele reale au sursa

## Fara asta, un .tres pentru o pista al carei hazard lipseste ar fi o garda
## verde pe nimic (memoria garda-cu-numele-gimmickului).
func _check_real_tracks() -> void:
	var sig := {&"thrown": &"car_thrown", &"fireball": &"fireball_hit",
		&"animal": &"animal_hit", &"shove": &"shoved", &"red_run": &"passed_on_red",
		&"boarded": &"boarded", &"plate_broken": &"plate_broken"}
	for track_id in EXPECTED:
		var event: StringName = EXPECTED[track_id]
		var index := TrackInfo.index_of_id(track_id)
		var scene := load(GameState.TRACK_SCENES[index]) as PackedScene
		var root := scene.instantiate()
		if sig.has(event):
			var found: Array[Node] = []
			_collect_sources(root, sig[event], found)
			if event == &"plate_broken":
				# Campul de gheata se construieste in `Track._ready` dintr-un
				# HazardMarker ICE_SLAB sau din `custom_ice_ranges`, deci in scena
				# neinstantiata in arbore nu exista inca nodul: numaram sursele lui.
				_collect_ice_sources(root, found)
			_expect(found.size() >= 1,
				"%s: pista contine >= 1 sursa pentru '%s' (%d)" % [track_id, event, found.size()])
		# fail_event: aceeasi pista trebuie sa aiba si sursa lui.
		var c := Career.challenge_for(track_id)
		if c.fail_event != &"":
			var fails: Array[Node] = []
			_collect_sources(root, c.fail_event, fails)
			_expect(fails.size() >= 1,
				"%s: pista contine sursa pentru fail_event '%s'" % [track_id, c.fail_event])
		if c.zone != &"":
			# Fara zona, provocarea ar fi MEREU reusita (vezi tracker).
			var z := root.find_child(String(c.zone), true, false)
			_expect(z != null and z is CameraZone,
				"%s: zona '%s' exista pe pista reala si e CameraZone" % [track_id, c.zone])
			if z is CameraZone:
				_expect((z as CameraZone).frac_to > (z as CameraZone).frac_from,
					"%s: zona e pe fractie (frac_from < frac_to) — o verifica `_player_inside` prin camera" % track_id)
		if event == &"branch":
			var branches: Array[Node] = []
			_collect_class(root, "TrackBranch", branches)
			_expect(branches.size() >= 1,
				"%s: pista contine un TrackBranch (scurtatura) (%d)" % [track_id, branches.size()])
		root.free()


func _collect_ice_sources(node: Node, out: Array[Node]) -> void:
	if node is HazardMarker and (node as HazardMarker).kind == HazardMarker.Kind.ICE_SLAB:
		out.append(node)
	if "custom_ice_ranges" in node and not (node.get("custom_ice_ranges") as Array).is_empty():
		out.append(node)
	for child in node.get_children():
		_collect_ice_sources(child, out)


func _collect_class(node: Node, cls: String, out: Array[Node]) -> void:
	if node.get_script() != null and (node.get_script() as Script).get_global_name() == cls:
		out.append(node)
	for child in node.get_children():
		_collect_class(child, cls, out)


func _collect_sources(node: Node, signal_name: StringName, out: Array[Node]) -> void:
	if ChallengeTracker._is_source(node, signal_name):
		out.append(node)
	for child in node.get_children():
		_collect_sources(child, signal_name, out)
