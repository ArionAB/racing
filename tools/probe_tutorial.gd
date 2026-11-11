extends Node
## ProbeTutorial — garda turului ghidat (#678).
##
## Rulare (ca SCENA, autoload-urile nu se rezolva cu --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTutorial.tscn
##   ... -- --bench     # cursa pe Track01 (banc usor) in loc de pista turului
##
## Contractele, fiecare cu sabotajul care il pica (vezi raportul PR-ului):
##   A. LAYOUT, la 1280x720, telefon 2532x1170 (1558x720 dupa stretch) si 4:3:
##      cartonasul si butoanele lui stau in viewport, nu acopera zonele de
##      atingere ale butoanelor touch si nici panourile HUD-ului; inelele din
##      jurul butoanelor nu intra in discul altui buton; rama barii de turbo
##      sta in viewport si departe de butoane. Si invitatia din meniu.
##   B. INVITATIA: apare o data pe sesiune, doar cat turul n-a fost facut;
##      TEST DRIVE porneste turul, SKIP il marcheaza facut si salveaza.
##   C. SETTINGS: REPLAY TUTORIAL porneste turul (si din pauza).
##   D. CURSA REALA (Race.tscn, PlayerController + Car reale, comenzi
##      sintetice pe puntea touch din GameState): fara adversari; fiecare
##      indiciu avanseaza DOAR la gestul lui, citit din starea masinii (DRIFT
##      fara viraj nu e drift, TURBO cu bara goala si arderea gratuita nu sunt
##      turbo, asteptarea nu avanseaza nimic); pe touch butonul vizat pulseaza
##      dupa `nudge_after_s`, pe tastatura textul numeste tasta; la final
##      starea se salveaza si se reincarca; SKIP incheie, salveaza si iese.
##
## Nu atinge setarile reale: `GameState.settings_path` merge in
## user://probe_tmp/ (sters la final). Dovada: cat ruleaza, sonda tine in
## memorie un `cam_follow_scale` marcator (LEAK_MARK); orice salvare scapata
## spre user://settings.cfg l-ar duce acolo, iar sonda pica daca il gaseste.
## (Nu MD5 pe fisierul real: user:// e comun tuturor worktree-urilor, iar alte
## sonde, de ex. ProbeHaptics, il rescriu si il restaureaza in paralel.)

## Subdosar PROPRIU: user://probe_tmp/ e folosit si de alte sonde.
const TMP_DIR := "user://probe_tmp/tutorial/"
const TMP_SETTINGS := TMP_DIR + "tutorial_settings.cfg"
const RACE_SCENE := "res://scenes/race/Race.tscn"
const BENCH := "res://scenes/tracks/Track01.tscn"
## Valoare pe care sliderul (pas 0.05) n-o produce: marcatorul de scurgere.
const LEAK_MARK := 1.2345

var _fail: int = 0
var _checks: int = 0
var _launches: int = 0
var _exits: int = 0
var _saved_sensitivity: float = 1.0
var _saved_follow: float = 1.0
var _bench: bool = false
var _cfg: TutorialConfig = TutorialDirector.DEFAULT_CONFIG


func _ready() -> void:
	_bench = "--bench" in OS.get_cmdline_user_args()
	await get_tree().process_frame
	await get_tree().physics_frame
	_isolate()

	print("== A. layout")
	await _check_layout(Vector2i(1280, 720), "1280x720")
	await _check_layout(Vector2i(1558, 720), "telefon 2532x1170 -> 1558x720")
	await _check_layout(Vector2i(960, 720), "4:3 (iPad) 960x720")
	print("== B. invitatia de la prima pornire")
	await _check_invite()
	print("== C. REPLAY TUTORIAL din SETTINGS")
	await _check_settings_replay()
	print("== D. cursa reala")
	await _check_flow()

	_restore()
	print("")
	print("VERDICT: %s (%d verificari, %d esecuri)" % [
		"OK" if _fail == 0 else "PICA", _checks, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("  %s %s" % ["OK  " if ok else "PICA", what])


# ----------------------------------------------------------------- izolare

func _isolate() -> void:
	DirAccess.make_dir_recursive_absolute(TMP_DIR)
	GameState.settings_path = TMP_SETTINGS
	_saved_sensitivity = GameState.steer_sensitivity
	GameState.steer_sensitivity = 1.0
	_saved_follow = GameState.cam_follow_scale
	GameState.cam_follow_scale = LEAK_MARK
	TutorialDirector.launch_override = func() -> void: _launches += 1
	TutorialDirector.exit_override = func() -> void: _exits += 1


func _restore() -> void:
	TutorialDirector.launch_override = Callable()
	TutorialDirector.exit_override = Callable()
	GameState.tutorial_run = false
	GameState.track_scene_override = ""
	GameState.steer_sensitivity = _saved_sensitivity
	GameState.reset_touch()
	get_tree().paused = false
	GameState.cam_follow_scale = _saved_follow
	# Salvarile sondei au ajuns in fisierul ei (cu marcatorul), nu in cel real.
	var tmp := ConfigFile.new()
	var tmp_ok := tmp.load(TMP_SETTINGS) == OK \
		and is_equal_approx(float(tmp.get_value("camera", "follow_scale", 0.0)), LEAK_MARK)
	_check(tmp_ok, "salvarile sondei au mers in %s" % TMP_SETTINGS)
	var real := ConfigFile.new()
	var leaked := real.load(GameState.SETTINGS_PATH) == OK \
		and is_equal_approx(float(real.get_value("camera", "follow_scale", 0.0)), LEAK_MARK)
	_check(not leaked, "user://settings.cfg real neatins (fara marcatorul sondei)")
	if FileAccess.file_exists(TMP_SETTINGS):
		DirAccess.remove_absolute(TMP_SETTINGS)
	DirAccess.remove_absolute(TMP_DIR)
	GameState.settings_path = GameState.SETTINGS_PATH


## Starea salvata e cea din fisier: o stergem din memorie si o recitim.
func _reloaded_done() -> bool:
	GameState.tutorial_done = false
	GameState.load_settings()
	return GameState.tutorial_done


# ------------------------------------------------------------------ layout

## Zona de ATINGERE a fiecarui buton (ca `TouchControls._zone_at`): cartonasul
## nu are voie sa intre in ea — acolo degetul trebuie sa ajunga la buton.
func _touch_zones(tc: TouchControls) -> Dictionary:
	var pad := {
		"left": TouchControls.STEER_TOUCH_PAD, "right": TouchControls.STEER_TOUCH_PAD,
		"gas": 14.0, "brake": 14.0, "turbo": 14.0, "drift": 6.0,
	}
	var out := {}
	for z: String in pad:
		var disc := tc.button_disc(z)
		out[z] = [tc.global_position + disc.get_center(), disc.size.x * 0.5 + float(pad[z])]
	return out


static func _circle_hits_rect(c: Vector2, r: float, rect: Rect2) -> bool:
	var q := Vector2(clampf(c.x, rect.position.x, rect.end.x),
		clampf(c.y, rect.position.y, rect.end.y))
	return q.distance_to(c) < r


func _check_layout(px: Vector2i, label: String) -> void:
	var vp := SubViewport.new()
	vp.size = px
	vp.disable_3d = true
	add_child(vp)
	var hud := RaceHUD.new()
	vp.add_child(hud)
	var ov := TutorialOverlay.new()
	ov.config = _cfg
	hud.add_tutorial_overlay(ov)
	ov.bind(hud.touch_controls(), hud.turbo_bar_rect)
	await _frames(3)
	var view := Rect2(Vector2.ZERO, Vector2(px))
	var tc := hud.touch_controls()
	var zones := _touch_zones(tc)
	var hud_rects := {}
	for n in ["_info_panel", "_pause_button", "_minimap", "_respawn_button"]:
		hud_rects[n] = (hud.get(n) as Control).get_global_rect()
	var bad: Array[String] = []
	var notes := {}
	var steps: Array[StringName] = [TutorialDirector.STEP_INTRO]
	steps.append_array(_cfg.steps)
	steps.append(TutorialDirector.STEP_DONE)
	for mode in [true, false]:
		ov.touch_mode = mode
		for step in steps:
			if step == TutorialDirector.STEP_DONE:
				ov.show_done()
			else:
				# Cel mai lung sub-text posibil, ca rama sa fie cea mai inalta.
				var sub := _cfg.drift_sub_speed if step == &"drift" \
					else (_cfg.turbo_sub_empty if step == &"turbo" else "")
				ov.show_step(step, 1, _cfg.steps.size(), 0.5, sub, true)
			await _frames(2)
			var tag := "%s/%s" % [String(step), "touch" if mode else "keys"]
			var card := ov.card_rect()
			if not view.encloses(card):
				bad.append("%s: cartonas %s iese din %s" % [tag, card, view])
			var btn := ov.continue_button() if step == TutorialDirector.STEP_DONE \
				else ov.skip_button()
			var br := btn.get_global_rect()
			if not view.encloses(br) or not card.encloses(br):
				bad.append("%s: butonul %s in afara cartonasului" % [tag, btn.text])
			for z: String in zones:
				var zc: Array = zones[z]
				if _circle_hits_rect(zc[0], zc[1], card):
					bad.append("%s: cartonasul acopera zona de atingere %s" % [tag, z])
			for n: String in hud_rects:
				if (hud_rects[n] as Rect2).intersects(card):
					bad.append("%s: cartonasul acopera %s" % [tag, n])
			# Inelele: la maximul pulsului, in viewport si in afara discului
			# DESENAT al oricarui alt buton.
			for z in ov.highlighted_zones():
				var disc := tc.button_disc(z)
				var c := tc.global_position + disc.get_center()
				var ro := TutorialOverlay.ring_outer_radius(disc.size.x * 0.5)
				if not view.encloses(Rect2(c - Vector2(ro, ro), Vector2(ro, ro) * 2.0)):
					bad.append("%s: inelul %s iese din ecran" % [tag, z])
				for other in ["left", "right", "gas", "brake", "turbo", "drift"]:
					if other == z:
						continue
					var od := tc.button_disc(other)
					var oc := tc.global_position + od.get_center()
					if oc.distance_to(c) < ro + od.size.x * 0.5:
						bad.append("%s: inelul %s intra in butonul %s" % [tag, z, other])
			if ov.bar_highlighted():
				var bar0 := hud.turbo_bar_rect()
				var bar := bar0.grow(10.0)
				if not view.encloses(bar):
					bad.append("%s: rama barii iese din ecran" % tag)
				for z: String in zones:
					var zc: Array = zones[z]
					# Daca bara HUD-ului INSASI intra deja in zona (4:3), nu e
					# vina ramei: se raporteaza ca nota, nu ca esec al turului.
					if _circle_hits_rect(zc[0], zc[1], bar0):
						notes[z] = true
					elif _circle_hits_rect(zc[0], zc[1], bar):
						bad.append("%s: rama barii atinge zona %s" % [tag, z])
	_check(bad.is_empty(), "%s: cartonas, butoane, inele si rama barii la locul lor%s"
		% [label, "" if bad.is_empty() else "\n      " + "\n      ".join(bad.slice(0, 8))])
	print("      cartonas (drift/keys): %s" % ov.card_rect())
	if not notes.is_empty():
		print("      NOTA (preexistent, HUD): bara de turbo insasi intra in zona de atingere %s"
			% ", ".join(notes.keys()))

	# Invitatia din meniu, in acelasi viewport.
	TutorialInvite.offered = false
	GameState.tutorial_done = false
	var menu := Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	vp.add_child(layer)
	layer.add_child(menu)
	var inv := TutorialInvite.offer_if_needed(menu)
	await _frames(3)
	if inv != null:
		var ok := view.encloses(inv.play_button().get_global_rect()) \
			and view.encloses(inv.skip_button().get_global_rect())
		_check(ok, "%s: butoanele invitatiei in ecran (%s, %s)" % [label,
			inv.play_button().get_global_rect(), inv.skip_button().get_global_rect()])
	else:
		_check(false, "%s: invitatia n-a aparut" % label)
	vp.queue_free()
	await _frames(1)


# --------------------------------------------------------------- invitatia

func _check_invite() -> void:
	var menu := Control.new()
	add_child(menu)
	TutorialInvite.offered = false
	GameState.tutorial_done = false
	GameState.tutorial_run = false
	GameState.selected_track = 0
	var inv := TutorialInvite.offer_if_needed(menu)
	_check(inv != null, "prima pornire, tur nefacut: invitatia apare")
	_check(TutorialInvite.offer_if_needed(menu) == null,
		"a doua intrare in meniu in aceeasi sesiune: nu mai apare")
	if inv != null:
		_launches = 0
		inv.play_button().pressed.emit()
		_check(_launches == 1 and GameState.tutorial_run
			and GameState.selected_track == TutorialDirector.track_index(),
			"TEST DRIVE porneste turul pe %s (lansari %d)"
				% [GameState.track_label(TutorialDirector.track_index()), _launches])
	GameState.tutorial_run = false
	TutorialInvite.offered = false
	var inv2 := TutorialInvite.offer_if_needed(menu)
	if inv2 != null:
		inv2.skip_button().pressed.emit()
	_check(inv2 != null and GameState.tutorial_done and _reloaded_done(),
		"SKIP din invitatie: tur marcat facut, salvat si recitit din fisier")
	TutorialInvite.offered = false
	_check(TutorialInvite.offer_if_needed(menu) == null,
		"sesiune noua cu turul facut: invitatia nu mai apare")
	menu.queue_free()
	await _frames(1)


# ---------------------------------------------------------------- settings

func _check_settings_replay() -> void:
	var sp := SettingsPanel.new()
	add_child(sp)
	await _frames(1)
	var btn: Button = null
	for n in sp.find_children("*", "Button", true, false):
		if (n as Button).text == TutorialDirector.REPLAY_LABEL:
			btn = n as Button
	_check(btn != null, "SETTINGS are butonul %s" % TutorialDirector.REPLAY_LABEL)
	if btn != null:
		GameState.tutorial_run = false
		GameState.selected_track = 0
		_launches = 0
		# Din pauza (SETTINGS din cursa): arborele trebuie dezghetat.
		get_tree().paused = true
		btn.pressed.emit()
		var unpaused := not get_tree().paused
		get_tree().paused = false
		_check(_launches == 1 and GameState.tutorial_run
			and GameState.selected_track == TutorialDirector.track_index() and unpaused,
			"REPLAY TUTORIAL porneste turul (lansari %d, tutorial_run %s, dezghetat %s)"
				% [_launches, GameState.tutorial_run, unpaused])
	sp.queue_free()
	await _frames(1)


# ------------------------------------------------------------- cursa reala

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
	await get_tree().process_frame


## Tine comenzile `cmd` pe puntea touch (exact ce scrie TouchControls) timp de
## `seconds`, sau pana `until` devine adevarat. `alt` > 0 alterneaza virajul
## stanga/dreapta la fiecare `alt` secunde.
func _hold(cmd: Dictionary, seconds: float, until: Callable = Callable(),
		alt: float = 0.0) -> bool:
	var frames := int(seconds * 60.0)
	for i in frames:
		GameState.reset_touch()
		GameState.touch_gas = bool(cmd.get("gas", false))
		GameState.touch_brake = bool(cmd.get("brake", false))
		GameState.touch_drift = bool(cmd.get("drift", false))
		GameState.touch_turbo = bool(cmd.get("turbo", false))
		var steer := float(cmd.get("steer", 0.0))
		if alt > 0.0:
			steer = 1.0 if int(float(i) / (alt * 60.0)) % 2 == 0 else -1.0
		GameState.touch_steer = steer
		await get_tree().physics_frame
		if until.is_valid() and bool(until.call()):
			GameState.reset_touch()
			return true
	GameState.reset_touch()
	await get_tree().physics_frame
	return false


func _check_flow() -> void:
	var idx := TutorialDirector.track_index()
	GameState.tutorial_done = false
	GameState.save_settings()
	GameState.champ_active = false
	GameState.tutorial_run = true
	GameState.selected_track = idx
	GameState.total_laps = 99
	if _bench:
		GameState.track_scene_override = BENCH
	print("  pista: %s" % (BENCH if _bench else GameState.track_label(idx)))
	var t0 := Time.get_ticks_msec()
	var race := (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(race)
	print("  incarcata in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	_check(race.cars.size() == 1, "turul e singur pe pista (%d masini)" % race.cars.size())
	var d := race.tutorial
	_check(d != null, "Race a atasat TutorialDirector")
	if d == null:
		race.queue_free()
		return
	var car := race.player
	var ov := d.overlay
	ov.touch_mode = true
	_check(d.step == TutorialDirector.STEP_INTRO and ov.highlighted_zones().is_empty(),
		"in numaratoare: cartonasul de intro, fara evidentieri")

	var guard := 0
	while race.state != Race.State.RUNNING and guard < 600:
		await get_tree().physics_frame
		guard += 1
	await _frames(2)
	_check(d.step == &"steer", "dupa GO: primul indiciu e VIRAJUL (%s)" % d.step)
	_check(car.turbo_charge < 0.05,
		"bara pleaca de la start_bar=%.2f, nu cu ce a strans in numaratoare (%.3f)" % [_cfg.start_bar, car.turbo_charge])

	# --- VIRAJ
	_check(ov.pulsing_zones().is_empty(), "viraj: la inceput butoanele nu pulseaza inca")
	await _hold({}, _cfg.nudge_after_s + 0.5)
	_check(d.step == &"steer", "viraj: %.1f s fara gest, indiciul ramane" % (_cfg.nudge_after_s + 0.5))
	var pulsing := ov.pulsing_zones()
	_check("left" in pulsing and "right" in pulsing,
		"viraj: pe touch sagetile pulseaza dupa %.1f s (%s)" % [_cfg.nudge_after_s, pulsing])
	ov.touch_mode = false
	d.call("_refresh_overlay")
	var keys_text := ov.body_text()
	var want_key := TutorialOverlay.key_name(&"steer_left")
	_check(keys_text.contains(want_key) and ov.pulsing_zones().is_empty(),
		"viraj pe tastatura: textul numeste tasta '%s' si nu pulseaza nimic (\"%s\")"
			% [want_key, keys_text.replace("\n", " ")])
	ov.touch_mode = true
	d.call("_refresh_overlay")
	_check(not ov.body_text().contains("{"), "viraj pe touch: textul numeste butonul (\"%s\")"
		% ov.body_text().replace("\n", " "))
	await _hold({"gas": true}, 0.6)
	_check(d.step == &"steer", "viraj: gazul nu bifeaza virajul")
	await _hold({"brake": true}, 4.0, func() -> bool: return car.horizontal_speed() < 1.5)
	await _hold({"steer": -1.0}, 0.6)
	if _cfg.steer_both_sides:
		_check(d.step == &"steer" and d.progress > 0.4 and d.progress < 0.6,
			"viraj: doar stanga = jumatate (%.2f)" % d.progress)
	await _hold({"steer": 1.0}, 2.0, func() -> bool: return d.step != &"steer")
	_check(d.step == &"gas", "viraj facut in ambele sensuri -> GAZ (%s)" % d.step)

	# --- GAZ
	var want_gas: Array[String] = ["gas"]
	_check(ov.highlighted_zones() == want_gas,
		"gaz: evidentiat butonul de gaz (%s)" % ov.highlighted_zones())
	await _hold({"steer": -1.0}, 1.0)
	_check(d.step == &"gas", "gaz: virajul nu bifeaza gazul")
	await _hold({"gas": true, "brake": true}, 0.6)
	_check(d.step == &"gas" and d.progress < 0.05,
		"gaz: GAZ + FRANA tinute (frana bate gazul) nu e mers (%.2f)" % d.progress)
	await _hold({"gas": true}, 8.0, func() -> bool: return d.step != &"gas")
	_check(d.step == &"drift" and car.horizontal_speed() * 3.6 >= _cfg.gas_speed_kmh - 1.0,
		"gaz pana la %.0f km/h -> DRIFT (%s, %.0f km/h)"
			% [_cfg.gas_speed_kmh, d.step, car.horizontal_speed() * 3.6])

	# --- DRIFT
	_check(absf(car.turbo_charge - maxf(_cfg.drift_bar_reset, 0.0)) < 0.02,
		"drift: bara pornita de la %.2f, ca umplerea sa se vada (%.3f)"
			% [_cfg.drift_bar_reset, car.turbo_charge])
	_check(ov.bar_highlighted() and "drift" in ov.highlighted_zones(),
		"drift: evidentiate butonul DRIFT si bara de turbo")
	# Lambdas capteaza prin valoare: textul vazut se strange intr-un Array.
	var sub_seen := [""]
	await _hold({"drift": true}, 0.6, func() -> bool:
		if ov.sub_text() != "":
			sub_seen[0] = ov.sub_text()
		return false)
	_check(d.step == &"drift" and d.progress == 0.0,
		"drift: DRIFT apasat fara viraj nu e drift (progres %.2f)" % d.progress)
	_check(sub_seen[0] == _cfg.drift_sub_turn or sub_seen[0] == _cfg.drift_sub_speed,
		"drift: indiciul spune de ce nu merge (\"%s\")" % sub_seen[0])
	var bar0 := car.turbo_charge
	var drifted := [false]
	await _hold({"drift": true}, 14.0, func() -> bool:
		if car.is_drifting:
			drifted[0] = true
		return d.step != &"drift", 0.7)
	_check(d.step == &"turbo" and bool(drifted[0]),
		"drift adevarat (Car.is_drifting) %.1f s -> TURBO (%s)" % [_cfg.drift_required_s, d.step])
	_check(car.turbo_charge > bar0 + 0.2,
		"drift: bara s-a umplut vizibil (%.2f -> %.2f)" % [bar0, car.turbo_charge])

	# --- TURBO
	_check(ov.bar_highlighted() and "turbo" in ov.highlighted_zones(),
		"turbo: evidentiate butonul TURBO si bara")
	var earned := car.turbo_charge
	car.turbo_charge = 0.0
	sub_seen[0] = ""
	await _hold({"turbo": true}, 0.5, func() -> bool:
		if ov.sub_text() != "":
			sub_seen[0] = ov.sub_text()
		return false)
	_check(d.step == &"turbo" and d.progress == 0.0 and sub_seen[0] == _cfg.turbo_sub_empty,
		"turbo: TURBO cu bara goala nu arde nimic (progres %.2f, \"%s\")" % [d.progress, sub_seen[0]])
	car.force_boost(0.6)
	await _hold({"gas": true}, 0.7)
	_check(d.step == &"turbo" and d.progress == 0.0,
		"turbo: arderea GRATUITA (rocket start / force_boost) nu conteaza (%.2f)" % d.progress)
	car.turbo_charge = earned
	await _hold({"turbo": true}, 4.0, func() -> bool: return d.is_finished())
	_check(d.step == TutorialDirector.STEP_DONE,
		"turbo: %.2f din bara arsa -> GATA (%s)" % [_cfg.turbo_burn_required, d.step])

	# --- FINAL: salvat, recitit, CONTINUE iese
	_check(GameState.tutorial_done and _reloaded_done(),
		"gata: tutorial_done salvat in %s si recitit" % TMP_SETTINGS)
	_check(ov.continue_button().visible and not ov.skip_button().visible,
		"gata: cartonasul final are CONTINUE, nu SKIP")
	_exits = 0
	ov.continue_button().pressed.emit()
	_check(_exits == 1, "CONTINUE iese din tur")

	# --- SKIP: oricand, incheie, salveaza, iese
	GameState.tutorial_done = false
	GameState.save_settings()
	d.restart()
	await _frames(2)
	_check(d.step == &"steer", "restart: turul reia de la primul indiciu (%s)" % d.step)
	_exits = 0
	ov.skip_button().pressed.emit()
	_check(d.step == TutorialDirector.STEP_SKIPPED and not ov.visible,
		"SKIP: turul se incheie si cartonasul dispare")
	_check(_exits == 1, "SKIP iese din tur")
	_check(GameState.tutorial_done and _reloaded_done(),
		"SKIP: tur marcat facut, salvat si recitit")
	await _hold({"steer": 1.0}, 0.5)
	_check(d.step == TutorialDirector.STEP_SKIPPED, "dupa SKIP gesturile nu mai repornesc nimic")
	race.queue_free()
	await _frames(2)
