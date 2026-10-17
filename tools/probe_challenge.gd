extends Node
## Garda pasului 4a al carierei: provocarea gimmick-ului.
##
## Ce garanteaza, cu cifre (nu "n-a crapat"):
##  1. DATE: cele 7 provocari se incarca, `validate()` e goala pe config-ul real,
##     iar un config sabotat in memorie (event necunoscut / pista inexistenta /
##     doua provocari pe aceeasi pista) iese cu CATE O problema pe sabotaj.
##  2. TRACKER: pentru fiecare event, un semnal al ALTEI masini lasa `events`
##     la 0 (o sonda care numara orice nu e garda), unul al jucatorului il
##     face 1 si `failed`; plus pragul `splash` si `traffic_bump` cu/fara
##     TrafficController. Sursele sunt instante REALE ale scripturilor de
##     hazard (`.new()`, fara scena si fara _ready), pasate prin
##     `setup(..., sources)`: tracker-ul nu are cum sa "reuseasca" pe un nod
##     inventat, iar scena pistei nu trebuie incarcata.
##  3. CAREER: modul CHALLENGE porneste ca RACE (ai_count neatins), bifa se pune
##     doar la reusita si nu se pierde la un esec ulterior.
##  4. FOAIA: butonul CHALLENGE e activ pe pistele cu provocare (subtitlu =
##     titlul), DONE cand e bifata, si ramane SOON pe o pista fara provocare.
##  5. PISTE REALE: pentru fiecare provocare pe semnal de hazard, pista se
##     incarca si contine cel putin o sursa a semnalului cerut (altfel
##     contractul ar fi o garda fara nimic de masurat).
##
## Ruleaza CA SCENA: godot --headless --path . res://tools/ProbeChallenge.tscn

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const TMP_PATH: String = "user://probe_challenge.cfg"
## Sub plafon un refactor care sare peste jumatate din verificari pica.
const MIN_CHECKS := 90
const EXPECTED := {
	&"kyoto": &"thrown", &"stromboli": &"fireball", &"serengeti": &"animal",
	&"okinawa": &"splash", &"monument_valley": &"crush",
	&"machu_picchu": &"shove", &"jodhpur": &"traffic_bump",
}

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
		"7 provocari in config, sunt %d" % cfg.challenges.size())
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
		_expect(c.rule == CareerChallenge.Rule.ZERO_EVENTS, "%s: regula ZERO_EVENTS" % track_id)
	_expect(Career.challenge_for(&"baikal") == null, "baikal n-are provocare in 4a")
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
	_expect(Career.validate(_clone()).is_empty(), "clona nesabotata e sanatoasa (contra-proba)")


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


# ---------------------------------------------------------------- 3. career

func _check_career() -> void:
	Career.load_progress()
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	GameState.ai_count = 3
	Career.start_track(&"kyoto", Career.Mode.CHALLENGE)
	_expect(Career.active and Career.active_mode == Career.Mode.CHALLENGE and Career.is_challenge(),
		"start_track(CHALLENGE) seteaza modul")
	_expect(started[0] == 1, "cursa de provocare porneste")
	_expect(GameState.ai_count == 3, "ai_count neatins (cursa cu AI), este %d" % GameState.ai_count)
	_expect(not Career.is_time_trial(), "provocarea nu e contratimp")
	var stamps0 := Career.stamps()
	_expect(not Career.finish_challenge(false), "finish_challenge(false) intoarce false")
	_expect(not bool(Career.track_state(&"kyoto").challenge) and Career.stamps() == stamps0,
		"un esec nu pune nimic")
	_expect(Career.finish_challenge(true), "finish_challenge(true) intoarce true")
	_expect(bool(Career.track_state(&"kyoto").challenge) and Career.stamps() == stamps0 + 1,
		"reusita pune bifa si +1 stampila")
	_expect(int(Career.track_state(&"kyoto").race_medal) == 0,
		"provocarea nu da medalie de cursa")
	Career.finish_challenge(false)
	_expect(bool(Career.track_state(&"kyoto").challenge), "reusita nu se pierde la un esec ulterior")
	Career.leave()
	_expect(not Career.is_challenge(), "dupa leave() nu mai e provocare")
	_expect(not Career.finish_challenge(true), "in afara unei provocari finish_challenge nu bifeaza")
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


func _check_sheet() -> void:
	Career.config = _real_config
	_remove_tmp()
	Career.load_progress()
	var panel := CareerPanel.new()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	for track_id in EXPECTED:
		panel._open_sheet(track_id)
		await get_tree().process_frame
		var b: Button = _sheet_buttons(panel).get("ChallengeButton")
		var c := Career.challenge_for(track_id)
		_expect(b != null and not b.disabled, "%s: CHALLENGE activ" % track_id)
		if b != null:
			_expect(c.title in b.text and c.hint in b.text and not ("SOON" in b.text),
				"%s: subtitlu = titlu + hint ('%s')" % [track_id, b.text])
	# apasarea porneste provocarea
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	panel._open_sheet(&"kyoto")
	await get_tree().process_frame
	(_sheet_buttons(panel)["ChallengeButton"] as Button).pressed.emit()
	_expect(started[0] == 1 and Career.is_challenge() and Career.active_track == &"kyoto",
		"apasarea CHALLENGE porneste provocarea pe Kyoto")
	Career.finish_challenge(true)
	Career.leave()
	panel._open_sheet(&"kyoto")
	await get_tree().process_frame
	var done_btn: Button = _sheet_buttons(panel)["ChallengeButton"]
	_expect("DONE" in done_btn.text and not done_btn.disabled,
		"Kyoto bifata: DONE ('%s')" % done_btn.text)
	panel.queue_free()
	await get_tree().process_frame

	# O pista FARA provocare (Kyoto scoasa din config in memorie): SOON + disabled.
	Career.config = _clone(&"kyoto")
	var panel2 := CareerPanel.new()
	add_child(panel2)
	await get_tree().process_frame
	panel2._open_sheet(&"kyoto")
	await get_tree().process_frame
	var soon: Button = _sheet_buttons(panel2)["ChallengeButton"]
	_expect(soon.disabled and "SOON" in soon.text,
		"fara provocare: CHALLENGE disabled + SOON ('%s')" % soon.text)
	panel2.queue_free()
	Career.config = _real_config
	Career.race_starter = Callable()
	await get_tree().process_frame


# ------------------------------------------------- 5. pistele reale au sursa

## Fara asta, un .tres pentru o pista al carei hazard lipseste ar fi o garda
## verde pe nimic (memoria garda-cu-numele-gimmickului).
func _check_real_tracks() -> void:
	var sig := {&"thrown": &"car_thrown", &"fireball": &"fireball_hit",
		&"animal": &"animal_hit", &"shove": &"shoved"}
	for track_id in EXPECTED:
		var event: StringName = EXPECTED[track_id]
		if not sig.has(event):
			continue
		var index := TrackInfo.index_of_id(track_id)
		var scene := load(GameState.TRACK_SCENES[index]) as PackedScene
		var root := scene.instantiate()
		var found: Array[Node] = []
		_collect_sources(root, sig[event], found)
		_expect(found.size() >= 1,
			"%s: pista contine >= 1 sursa pentru '%s' (%d)" % [track_id, event, found.size()])
		root.free()


func _collect_sources(node: Node, signal_name: StringName, out: Array[Node]) -> void:
	if ChallengeTracker._is_source(node, signal_name):
		out.append(node)
	for child in node.get_children():
		_collect_sources(child, signal_name, out)
