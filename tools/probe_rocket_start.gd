extends Node
## Sunetul rocket start-ului (docs/feel_checklist.md: toy-sound-palette): clichetul
## cheii cat tii TURBO in numaratoare si arcul tras la GO, DOAR pe un start rocket.
##
## Audio-ul headless nu se aude, deci sonda masoara jurnalul `AudioManager.sfx_log`
## (ce sunete s-au cerut si pe ce cadru), pe un `Race.tscn` REAL cu
## `PlayerController` real (butonul "turbo" apasat prin `Input`), nu pe helperul
## izolat. Trei porniri:
##   A. rocket: TURBO apasat cu ~0.7 s inainte de GO -> clichete cu pitch urcator,
##      apoi EXACT un `rocket_spring`, pe cadrul lui `go_beep`, dupa clichete;
##   B. start obisnuit (fara TURBO): niciun clichet, niciun arc, dar `go_beep` a
##      sunat (altfel proba ar fi verde pe zero masuratori);
##   C. prea devreme (TURBO tinut de la inceputul numaratorii): clichetele se opreste
##      dupa fereastra, niciun arc la GO (mesajul „Too early..." are acum si semnal).
## Plus helperul: sub pragul de apasare nu sune nimic.
## Sabotaje verificate de mana (trebuie sa PICE): scoaterea apelului `on_go(true)` din
## `Race._go()`; apelul `on_go(true)` si pe start obisnuit; scoaterea `tick(...)`.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRocketStart.tscn

const RocketStartAudioScript := preload("res://scenes/race/rocket_start_audio.gd")
const RACE_SCENE := "res://scenes/race/Race.tscn"

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	print("")
	print("=== Rocket start: clichet si arc ===")
	_test_helper()
	await _scenario("A. rocket (TURBO cu ~0.7 s inainte de GO)", 0.7)
	await _scenario("B. start obisnuit (fara TURBO)", -1.0)
	await _scenario("C. prea devreme (TURBO de la inceput)", 99.0)
	Input.action_release("turbo")
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _test_helper() -> void:
	print("")
	print("-- helper izolat --")
	var h := RocketStartAudioScript.new()
	add_child(h)
	AudioManager.sfx_log.clear()
	for _i in 120:
		h.tick(1.0 / 60.0, 0.02) # sub pragul de apasare
	_check(h.ratchets == 0 and AudioManager.sfx_log.is_empty(), "sub 0.05 s de apasare: nimic")
	for _i in 120:
		h.tick(1.0 / 60.0, 1.3) # peste fereastra
	_check(h.ratchets == 0, "peste fereastra (1.05 s): nimic")
	h.on_go(false)
	_check(h.springs == 0 and AudioManager.sfx_log.is_empty(), "on_go(false): nu suna arcul")
	h.queue_free()


## `press_at`: apasa TURBO cand mai raman atatea secunde de numaratoare (< 0: nu
## apasa; 99: de la inceput).
func _scenario(title: String, press_at: float) -> void:
	print("")
	print("-- %s --" % title)
	Input.action_release("turbo")
	GameState.total_laps = 99
	GameState.champ_active = false
	var race := (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(race)
	var guard := 0
	while race.rocket_audio == null or race.state != Race.State.COUNTDOWN:
		await get_tree().physics_frame
		guard += 1
		if guard > 3000:
			break
	_check(race.state == Race.State.COUNTDOWN and race.rocket_audio != null,
		"cursa e in numaratoare si are RocketStartAudio")
	if race.state != Race.State.COUNTDOWN or race.rocket_audio == null:
		race.queue_free()
		await get_tree().physics_frame
		return
	AudioManager.sfx_log.clear()
	var pressed := false
	if press_at >= 90.0:
		Input.action_press("turbo")
		pressed = true
	var frames := 0
	while race.state == Race.State.COUNTDOWN and frames < 1200:
		if not pressed and press_at > 0.0 and race._countdown_left <= press_at:
			Input.action_press("turbo")
			pressed = true
		await get_tree().physics_frame
		frames += 1
	# Cateva cadre dupa GO, ca sa prindem tot ce porneste la GO.
	for _i in 6:
		await get_tree().physics_frame
	var log: Array[Dictionary] = AudioManager.sfx_log.duplicate()
	var ratchets := log.filter(func(e: Dictionary) -> bool: return e["name"] == &"rocket_ratchet")
	var springs := log.filter(func(e: Dictionary) -> bool: return e["name"] == &"rocket_spring")
	var gos := log.filter(func(e: Dictionary) -> bool: return e["name"] == &"go_beep")
	var pitches: Array = ratchets.map(func(e: Dictionary) -> float: return float(e["pitch"]))
	print("  clichete %d, arcuri %d, go_beep %d; pitch clichete: %s"
		% [ratchets.size(), springs.size(), gos.size(), pitches.map(func(p: float) -> String: return "%.2f" % p)])
	_check(gos.size() == 1, "go_beep a sunat o data (masuratoarea a vazut GO)")
	if press_at > 0.0 and press_at < 90.0:
		_check(ratchets.size() >= 2, "rocket: clichet cat tii apasat (%d)" % ratchets.size())
		var rising := pitches.size() >= 2
		for i in range(1, pitches.size()):
			# Zgomotul de pitch al redarii e +-4%; urcusul pe pas e mai mare.
			if float(pitches[i]) < float(pitches[i - 1]) - 0.001:
				rising = false
		_check(rising and pitches.size() >= 2, "pitch-ul clichetelor urca (arcul se incarca)")
		_check(springs.size() == 1, "rocket: exact un arc la GO (%d)" % springs.size())
		if springs.size() == 1 and gos.size() == 1:
			_check(int((springs[0] as Dictionary)["frame"]) >= int((gos[0] as Dictionary)["frame"]) - 1
				and int((springs[0] as Dictionary)["frame"]) <= int((gos[0] as Dictionary)["frame"]) + 2,
				"arcul sare la GO (cadru %d vs go_beep %d)"
				% [int((springs[0] as Dictionary)["frame"]), int((gos[0] as Dictionary)["frame"])])
			var last_ratchet := int((ratchets.back() as Dictionary)["frame"])
			_check(last_ratchet < int((springs[0] as Dictionary)["frame"]),
				"clichetele sunt inainte de arc")
		_check(race.player.is_boosting or race.player._forced_boost > 0.0,
			"startul a fost intr-adevar rocket (masina arde turbo gratuit)")
	elif press_at < 0.0:
		_check(ratchets.is_empty(), "start obisnuit: niciun clichet")
		_check(springs.is_empty(), "start obisnuit: niciun arc")
	else:
		# Ferestre de 1.05 s la un clichet pe 0.30 s: cel mult 4, apoi tacere.
		_check(ratchets.size() >= 1 and ratchets.size() <= 4,
			"prea devreme: clichetele se opresc dupa fereastra (%d, cel mult 4)" % ratchets.size())
		_check(springs.is_empty(), "prea devreme: niciun arc la GO")
	Input.action_release("turbo")
	race.queue_free()
	await get_tree().physics_frame
