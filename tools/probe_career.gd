extends Node
## Garda carierei, pasul 1: config, persistenta, stampile si gating, versiune
## necunoscuta, regrupare, raftul din scena si lacatul cursei. Merge HEADLESS.
##
## Rulare:
##   Godot --headless --path . res://tools/ProbeCareer.tscn -- --check
##
## Memoria `garda-verde-pe-zero-masuratori` si `efecte-invizibile-nu-se-numara`:
## o garda care nu poate pica nu verifica nimic. De aceea (a) fiecare regula de
## validare are un SABOTAJ care trebuie sa produca exact problema ei, (b) se
## numara cate verificari au rulat si sub `MIN_CHECKS` verdictul pica, (c)
## raftul se numara pe noduri reale (carduri, etichete), nu pe apeluri.
##
## Nu atinge salvarea reala: `Career.save_path` merge pe un fisier temporar.

const TMP_PATH := "user://probe_career_tmp.cfg"
## Cate verificari trebuie sa fi rulat. Daca cineva scoate o sectiune sau o
## iesire timpurie sare peste ele, numarul scade si verdictul pica.
const MIN_CHECKS := 170

var _fails: Array[String] = []
var _checks: int = 0
var _real_config: CareerConfig
var _real_save_path: String
var _real_track: int


func _ready() -> void:
	var check := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--check":
			check = true
	if not check:
		print("probe_career: foloseste -- --check")
		get_tree().quit()
		return

	_real_config = Career.config
	_real_save_path = Career.save_path
	_real_track = GameState.selected_track
	Career.save_path = TMP_PATH
	_reset_save()

	_check_track_ids()
	_check_config()
	_check_persistence()
	_check_gating()
	_check_unknown_version()
	_check_regroup()
	await _check_panel()
	_check_race_lock()
	_check_time_trial()

	# Restaurare + curatenie.
	Career.config = _real_config
	Career.save_path = _real_save_path
	Career.race_starter = Callable()
	Career.leave()
	GameState.selected_track = _real_track
	_remove_tmp()
	_report()


# ------------------------------------------------------------------ utilitare

func _expect(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _remove_tmp() -> void:
	var abs_path := ProjectSettings.globalize_path(TMP_PATH)
	if FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)


## Fisier de salvare gol + stare goala in memorie.
func _reset_save() -> void:
	Career.config = _real_config
	_remove_tmp()
	Career.load_progress()


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f != null else "<lipsa>"


## Copie in memorie a config-ului real, ca sabotajul sa nu atinga resursa
## incarcata (care e partajata cu autoload-ul).
func _clone_config() -> CareerConfig:
	var out := CareerConfig.new()
	for src in _real_config.worlds:
		var w := CareerWorld.new()
		w.id = src.id
		w.display_name = src.display_name
		w.tracks = src.tracks.duplicate()
		w.free = src.free
		w.stamps_to_unlock = src.stamps_to_unlock
		w.rival = src.rival
		w.rival_track = src.rival_track
		out.worlds.append(w)
	return out


func _collect(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		out.append(child)
		_collect(child, out)


# -------------------------------------------------------------- 0. id-uri

## Cariera, abtibildurile si career.cfg se leaga de `TrackInfo.id`. Un id gol,
## duplicat sau care nu duce inapoi la pozitia lui face o pista inaccesibila
## sau, mai rau, doua piste care isi impart progresul.
func _check_track_ids() -> void:
	var seen: Dictionary = {}
	for i in GameState.TRACK_SCENES.size():
		var id := TrackInfo.for_track(i).id
		_expect(id != &"", "pista %d nu are id" % i)
		_expect(not seen.has(id), "id duplicat: %s" % id)
		seen[id] = i
		_expect(TrackInfo.index_of_id(id) == i,
			"index_of_id(%s) != %d" % [id, i])
	_expect(TrackInfo.index_of_id(&"nu_exista_deloc") == -1,
		"un id necunoscut trebuie sa dea -1")
	# Ha Long e in joc dar in nicio lume: starea normala, nu o eroare.
	_expect(TrackInfo.index_of_id(&"halong") >= 0, "halong lipseste din TRACK_SCENES")


# -------------------------------------------------------------- 1. config

func _check_config() -> void:
	# Config-ul real trebuie sa fie sanatos. Un `validate()` mereu gol ar trece
	# aici, de aceea urmeaza sabotajele.
	var real := Career.validate()
	_expect(real.is_empty(), "config real are probleme: %s" % ", ".join(real))
	_expect(Career.worlds().size() == 3, "se asteapta 3 lumi, sunt %d" % Career.worlds().size())
	var clean := Career.validate(_clone_config())
	_expect(clean.is_empty(), "clona nesabotata ar trebui sa fie curata")

	# Sabotaj a: doua lumi free -> exact problema "o lume free".
	var cfg := _clone_config()
	cfg.worlds[1].free = true
	var p := Career.validate(cfg)
	_expect(p.size() == 1 and "free" in p[0], "doua lumi free: %s" % ", ".join(p))

	# Sabotaj b: o pista in doua lumi.
	cfg = _clone_config()
	cfg.worlds[1].tracks.append(&"kyoto")
	p = Career.validate(cfg)
	_expect(p.size() == 1 and "kyoto" in p[0] and "doua lumi" in p[0],
		"pista in doua lumi: %s" % ", ".join(p))

	# Sabotaj c: id inexistent.
	cfg = _clone_config()
	cfg.worlds[2].tracks.append(&"pista_fantoma")
	p = Career.validate(cfg)
	_expect(p.size() == 1 and "pista_fantoma" in p[0],
		"id inexistent: %s" % ", ".join(p))

	# Sabotaj d: rival_track in alta lume decat a rivalului.
	cfg = _clone_config()
	cfg.worlds[0].rival = &"rival_test"
	cfg.worlds[0].rival_track = &"baikal" # baikal e in lumea 3
	p = Career.validate(cfg)
	_expect(p.size() == 1 and "rival_track" in p[0],
		"rival_track in alta lume: %s" % ", ".join(p))
	# Contra-proba: rival_track in propria lume e valid.
	cfg.worlds[0].rival_track = &"kyoto"
	_expect(Career.validate(cfg).is_empty(), "rival_track in lumea lui trebuie sa treaca")

	# Nicio lume free.
	cfg = _clone_config()
	cfg.worlds[0].free = false
	p = Career.validate(cfg)
	_expect(p.size() == 1 and "free" in p[0], "zero lumi free: %s" % ", ".join(p))


# --------------------------------------------------------- 2. persistenta

func _check_persistence() -> void:
	_reset_save()
	var k := &"kyoto"
	Career.set_race_medal(k, Career.MEDAL_GOLD)
	Career.set_race_medal(k, Career.MEDAL_BRONZE) # nu are voie sa scada
	_expect(int(Career.track_state(k).race_medal) == 3,
		"aur apoi bronz trebuie sa ramana aur")
	Career.set_time_trial(k, Career.MEDAL_SILVER, 90000)
	Career.set_time_trial(k, Career.MEDAL_BRONZE, 80000)
	var st := Career.track_state(k)
	_expect(int(st.tt_medal) == 2, "tt: argint apoi bronz => argint, e %d" % int(st.tt_medal))
	_expect(int(st.tt_best_ms) == 80000, "tt_best_ms trebuie sa ia minimul, e %d" % int(st.tt_best_ms))
	Career.set_time_trial(k, Career.MEDAL_BRONZE, 95000) # timp mai prost
	_expect(int(Career.track_state(k).tt_best_ms) == 80000, "un timp mai prost nu inlocuieste recordul")
	Career.set_challenge(k)
	Career.set_race_medal(&"serengeti", Career.MEDAL_BRONZE)
	Career.set_rival_beaten(&"rival_test")
	Career.set_cup_won(&"world_1")

	var before_k := Career.track_state(k)
	var before_s := Career.track_state(&"serengeti")
	var before_untouched := Career.track_state(&"cappadocia")
	var text := _read_text(TMP_PATH)
	_expect("[track:kyoto]" in text and "version=1" in text,
		"fisierul nu are schema asteptata")

	Career.load_progress() # sterge memoria si reciteste de pe disc
	for key in ["race_medal", "tt_medal", "tt_best_ms", "challenge"]:
		_expect(Career.track_state(k)[key] == before_k[key],
			"kyoto.%s difera dupa reload" % key)
		_expect(Career.track_state(&"serengeti")[key] == before_s[key],
			"serengeti.%s difera dupa reload" % key)
	_expect(Career.track_state(&"cappadocia") == before_untouched,
		"o pista neatinsa trebuie sa ramana la zero")
	_expect(Career.is_cup_won(&"world_1") and not Career.is_cup_won(&"world_2"),
		"cupa lumii 1 trebuie sa persiste (si numai ea)")
	_expect("[rival:rival_test]" in _read_text(TMP_PATH), "rivalul batut nu e in fisier")


# ------------------------------------------------------------- 3. gating

func _check_gating() -> void:
	_reset_save()
	var w := Career.worlds()
	_expect(Career.stamps() == 0, "de la zero stampilele sunt 0, sunt %d" % Career.stamps())
	_expect(Career.is_world_unlocked(w[0]), "lumea free trebuie sa fie deschisa")
	_expect(not Career.is_world_unlocked(w[1]) and not Career.is_world_unlocked(w[2]),
		"de la zero lumile 2 si 3 sunt sigilate")
	_expect(Career.stamps_missing(w[1]) == 6 and Career.stamps_missing(w[2]) == 14,
		"lipsesc 6 si 14, sunt %d si %d" % [Career.stamps_missing(w[1]), Career.stamps_missing(w[2])])
	var rivals := 0
	for world in w:
		if world.rival != &"":
			rivals += 1
	var expected_max := 3 * 12 + rivals
	_expect(Career.max_stamps() == 36 and expected_max == 36,
		"max_stamps trebuie 36 (12 piste x 3, 0 rivali), e %d" % Career.max_stamps())

	var placed := 0
	# Lumea 1: 4 medalii de cursa + 2 de contratimp = 6.
	for id in w[0].tracks:
		Career.set_race_medal(id, Career.MEDAL_BRONZE)
		placed += 1
		_expect(Career.stamps() == placed, "stampile %d != puse %d" % [Career.stamps(), placed])
		if placed == 5:
			_expect(not Career.is_world_unlocked(w[1]) and Career.stamps_missing(w[1]) == 1,
				"la 5 stampile lumea 2 inca sigilata, lipseste 1")
	for i in 2:
		Career.set_time_trial(w[0].tracks[i], Career.MEDAL_SILVER, 70000 + i)
		placed += 1
	_expect(Career.stamps() == 6 and placed == 6, "ar trebui 6 stampile, sunt %d" % Career.stamps())
	_expect(Career.is_world_unlocked(w[1]), "la 6 stampile lumea 2 se deschide")
	_expect(not Career.is_world_unlocked(w[2]) and Career.stamps_missing(w[2]) == 8,
		"la 6 lumea 3 inca sigilata, lipsesc 8")
	# Aceeasi medalie pusa a doua oara nu aduce o a doua stampila.
	Career.set_race_medal(w[0].tracks[0], Career.MEDAL_GOLD)
	_expect(Career.stamps() == 6, "o medalie mai buna pe aceeasi pista nu da stampila in plus")
	# Provocari pe lumea 1 (+2), apoi lumea 2: 4 cursa (+4) = 12, +2 tt = 14.
	for i in 2:
		Career.set_challenge(w[0].tracks[i])
		placed += 1
	for id in w[1].tracks:
		Career.set_race_medal(id, Career.MEDAL_SILVER)
		placed += 1
	_expect(Career.stamps() == 12 and placed == 12, "ar trebui 12 stampile, sunt %d" % Career.stamps())
	_expect(not Career.is_world_unlocked(w[2]), "la 12 lumea 3 inca sigilata")
	Career.set_time_trial(w[1].tracks[0], Career.MEDAL_BRONZE, 99000)
	_expect(not Career.is_world_unlocked(w[2]), "la 13 lumea 3 inca sigilata")
	Career.set_time_trial(w[1].tracks[1], Career.MEDAL_BRONZE, 99000)
	_expect(Career.stamps() == 14 and Career.is_world_unlocked(w[2]),
		"la 14 stampile lumea 3 se deschide (sunt %d)" % Career.stamps())
	_expect(is_equal_approx(Career.progress_fraction(), 14.0 / 36.0), "progress_fraction gresit")
	var counts := Career.medal_counts()
	# 4 bronz + 2 argint (tt) lumea 1, aur pe prima (inlocuieste un bronz) =>
	# cursa: 1 aur, 3 bronz, 4 argint(lumea 2); tt: 2 argint + 2 bronz.
	_expect(int(counts[3]) == 1 and int(counts[2]) == 4 + 2 and int(counts[1]) == 3 + 2,
		"medal_counts gresit: %s" % str(counts))
	_expect(Career.medal_for_position(1) == 3 and Career.medal_for_position(2) == 2
		and Career.medal_for_position(3) == 1 and Career.medal_for_position(4) == 0
		and Career.medal_for_position(6) == 0, "medal_for_position")


# ------------------------------------------------- 4. versiune necunoscuta

func _check_unknown_version() -> void:
	_reset_save()
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	f.store_string("[meta]\nversion=99\n\n[track:kyoto]\nrace_medal=3\nfutur=\"necunoscut\"\n")
	f.close()
	var before := _read_text(TMP_PATH)
	Career.load_progress() # trebuie sa dea push_warning, vezi _read_only
	_expect(Career._read_only, "versiunea 99 trebuie sa puna _read_only")
	_expect(int(Career.track_state(&"kyoto").race_medal) == 0 and Career.stamps() == 0,
		"un fisier mai nou nu se incarca")
	Career.set_race_medal(&"serengeti", Career.MEDAL_GOLD)
	_expect(_read_text(TMP_PATH) == before, "un fisier mai nou nu are voie sa fie rescris")
	# Contra-proba: aceeasi operatie pe un fisier de versiunea 1 SCRIE.
	_reset_save()
	Career.set_race_medal(&"serengeti", Career.MEDAL_GOLD)
	_expect("[track:serengeti]" in _read_text(TMP_PATH), "pe versiunea 1 salvarea trebuie sa scrie")


# ------------------------------------------------------------ 5. regrupare

func _check_regroup() -> void:
	_reset_save()
	var cfg := _clone_config()
	Career.config = cfg
	Career.set_race_medal(&"kyoto", Career.MEDAL_SILVER)
	Career.set_time_trial(&"kyoto", Career.MEDAL_BRONZE, 88000)
	Career.set_challenge(&"kyoto")
	Career.set_race_medal(&"cappadocia", Career.MEDAL_GOLD)
	var state_before := Career.track_state(&"kyoto")
	var stamps_before := Career.stamps()
	_expect(stamps_before == 4, "kyoto 3 + cappadocia 1 = 4, sunt %d" % stamps_before)

	# Kyoto trece din lumea 1 in lumea 2.
	cfg.worlds[0].tracks.erase(&"kyoto")
	cfg.worlds[1].tracks.append(&"kyoto")
	_expect(Career.validate(cfg).is_empty(), "config regrupat trebuie sa ramana valid")
	_expect(Career.track_state(&"kyoto") == state_before, "regruparea a schimbat starea pistei")
	_expect(Career.stamps() == stamps_before, "regruparea a schimbat totalul de stampile")
	_expect(Career.max_stamps() == 36, "max_stamps nu depinde de lume")

	# Deblocarea se recalculeaza din noile praguri.
	cfg.worlds[1].stamps_to_unlock = stamps_before + 1
	_expect(not Career.is_world_unlocked(cfg.worlds[1]), "prag mai sus => sigilata")
	cfg.worlds[1].stamps_to_unlock = stamps_before
	_expect(Career.is_world_unlocked(cfg.worlds[1]), "prag la nivelul curent => deschisa")

	# Rivalul: +1 la maxim si +1 la stampile cand e batut, cheie pe rival.
	cfg.worlds[0].rival = &"rival_test"
	_expect(Career.max_stamps() == 37, "un rival adauga 1 la maxim")
	Career.set_rival_beaten(&"rival_test")
	_expect(Career.stamps() == stamps_before + 1, "rivalul batut aduce o stampila")
	cfg.worlds[0].rival = &""
	cfg.worlds[2].rival = &"rival_test" # rivalul se muta in alta lume
	_expect(Career.stamps() == stamps_before + 1, "rivalul batut ramane batut dupa mutare")
	Career.config = _real_config


# -------------------------------------------------------------- 6. panoul

func _check_panel() -> void:
	_reset_save()
	var panel := CareerPanel.new()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame

	var all: Array[Node] = []
	_collect(panel, all)
	var boxes := 0
	var cards: Array[TrackCard] = []
	var sealed := 0
	for n in all:
		if n is PanelContainer and String(n.name).begins_with("World_"):
			boxes += 1
		elif n is TrackCard:
			cards.append(n)
		elif n is Label and (n as Label).text.begins_with("SEALED"):
			sealed += 1
	_expect(boxes == 3, "o cutie per lume: asteptat 3, sunt %d" % boxes)
	_expect(cards.size() == 4, "doar lumea 1 e deschisa => 4 carduri, sunt %d" % cards.size())
	_expect(sealed == 2, "2 lumi sigilate => 2 etichete SEALED, sunt %d" % sealed)
	_expect(panel._stamps_label.text == "STAMPS  0 / 36",
		"pasaport initial: '%s'" % panel._stamps_label.text)
	for card in cards:
		_expect(card._medals != null, "cardul din cariera trebuie sa aiba medaliile")

	# Un card de cursa rapida nu are medalii: arata ca inainte.
	var plain := TrackCard.new().setup(0)
	add_child(plain)
	await get_tree().process_frame
	_expect(plain._medals == null, "cardul de cursa rapida nu are voie sa primeasca medalii")
	plain.queue_free()

	# progress_changed reimprospateaza pasaportul si cardul.
	Career.set_race_medal(&"kyoto", Career.MEDAL_GOLD)
	_expect(panel._stamps_label.text == "STAMPS  1 / 36",
		"dupa o medalie: '%s'" % panel._stamps_label.text)
	all.clear()
	_collect(panel, all)
	var kyoto_medal := -1
	cards.clear()
	for n in all:
		if n is TrackCard:
			cards.append(n)
			if (n as TrackCard).track_index == TrackInfo.index_of_id(&"kyoto"):
				kyoto_medal = (n as TrackCard)._medals.race
	_expect(kyoto_medal == 3, "cardul Kyoto trebuie sa arate aurul, are %d" % kyoto_medal)
	_expect(cards.size() == 4, "reimprospatarea nu are voie sa dubleze cardurile (%d)" % cards.size())

	# Cu 6 stampile se deschide lumea 2: 8 carduri, 1 eticheta SEALED.
	for i in 5:
		Career.set_race_medal(Career.worlds()[0].tracks[(i + 1) % 4], Career.MEDAL_BRONZE)
	Career.set_time_trial(Career.worlds()[0].tracks[0], Career.MEDAL_BRONZE, 1000)
	Career.set_time_trial(Career.worlds()[0].tracks[1], Career.MEDAL_BRONZE, 1000)
	Career.set_time_trial(Career.worlds()[0].tracks[2], Career.MEDAL_BRONZE, 1000)
	_expect(Career.stamps() >= 6, "setup: stampile insuficiente (%d)" % Career.stamps())
	all.clear()
	_collect(panel, all)
	var cards_after := 0
	var sealed_after := 0
	for n in all:
		if n is TrackCard:
			cards_after += 1
		elif n is Label and (n as Label).text.begins_with("SEALED"):
			sealed_after += 1
	_expect(cards_after == 8 and sealed_after == 1,
		"dupa deblocare: 8 carduri / 1 sigilata, sunt %d / %d" % [cards_after, sealed_after])
	# Foaia pistei: tap pe card deschide butoanele, nu porneste cursa.
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	all.clear()
	_collect(panel, all)
	var first: TrackCard = null
	for n in all:
		if n is TrackCard:
			first = n
			break
	_expect(first != null, "exista un card pentru foaie")
	first.pressed.emit()
	await get_tree().process_frame
	_expect(panel._sheet != null, "tap pe card deschide foaia pistei")
	_expect(started[0] == 0 and not Career.active, "tap pe card nu porneste cursa direct")
	if panel._sheet != null:
		var sheet_nodes: Array[Node] = []
		_collect(panel._sheet, sheet_nodes)
		var buttons := {}
		for n in sheet_nodes:
			if n is Button:
				buttons[n.name] = n
		_expect(buttons.size() == 4, "foaia are 4 butoane (RACE, TIME TRIAL, CHALLENGE, BACK): %d" % buttons.size())
		for key in ["RaceButton", "TimeTrialButton", "ChallengeButton", "BackButton"]:
			_expect(buttons.has(key), "foaia: lipseste " + key)
			if buttons.has(key):
				_expect((buttons[key] as Button).custom_minimum_size.y >= 64.0,
					key + " sub 64 px")
		if buttons.has("ChallengeButton"):
			# Din pasul 4a, pistele cu provocare (primul card, Monument Valley, are
			# una) au butonul activ; SOON ramane pentru cele fara (ProbeChallenge).
			_expect(not (buttons["ChallengeButton"] as Button).disabled, "CHALLENGE activ pe pista cu provocare")
			_expect(not (buttons["ChallengeButton"] as Button).text.contains("SOON"), "CHALLENGE nu mai zice SOON")
		if buttons.has("TimeTrialButton"):
			_expect(not (buttons["TimeTrialButton"] as Button).disabled, "TIME TRIAL activ")
			var ai_before := GameState.ai_count
			(buttons["TimeTrialButton"] as Button).pressed.emit()
			_expect(started[0] == 1 and Career.is_time_trial(), "TIME TRIAL porneste contratimpul")
			Career.leave()
			_expect(GameState.ai_count == ai_before, "leave() readuce ai_count dupa foaie")
	# ui_cancel inchide foaia, nu panoul.
	var closed := [0]
	panel.back_pressed.connect(func() -> void: closed[0] += 1)
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	panel._unhandled_input(cancel)
	await get_tree().process_frame
	_expect(panel._sheet == null, "ui_cancel inchide foaia")
	_expect(closed[0] == 0, "primul ui_cancel nu inchide panoul")
	panel._unhandled_input(cancel)
	_expect(closed[0] == 1, "al doilea ui_cancel inchide panoul")
	Career.race_starter = Callable()
	panel.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------- 7. lacatul cursei

func _check_race_lock() -> void:
	_reset_save()
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	GameState.champ_active = true # trebuie sa fie oprit de start_track
	Career.start_track(&"kyoto")
	var kyoto_index := GameState.TRACK_SCENES.find("res://scenes/tracks/Track18.tscn")
	_expect(kyoto_index >= 0, "Track18 lipseste din TRACK_SCENES")
	_expect(Career.active and Career.active_track == &"kyoto", "start_track nu a setat starea")
	_expect(GameState.selected_track == kyoto_index,
		"selected_track %d != indexul Kyoto %d" % [GameState.selected_track, kyoto_index])
	_expect(not GameState.champ_active, "cursa de cariera opreste campionatul")
	_expect(started[0] == 1, "cursa trebuia pornita exact o data, de %d ori" % started[0])

	var medal := Career.finish_active(1)
	_expect(medal == Career.MEDAL_GOLD and int(Career.track_state(&"kyoto").race_medal) == 3,
		"locul 1 => aur salvat")
	_expect(Career.finish_active(5) == Career.MEDAL_NONE
		and int(Career.track_state(&"kyoto").race_medal) == 3,
		"locul 5 nu strica aurul")
	_expect(Career.active, "active ramane true pana la leave()")
	Career.leave()
	_expect(not Career.active, "leave() trebuie sa opreasca modul de cariera")
	_expect(Career.finish_active(1) == Career.MEDAL_NONE, "in afara carierei finish_active nu da medalii")
	GameState.champ_active = false


# --------------------------------------------------- 8. contratimpul

func _check_time_trial() -> void:
	_reset_save()
	# (a) medalia din tinte, pe un TrackInfo sintetic 100/110/120 s.
	var info := TrackInfo.new()
	info.tt_gold_ms = 100000
	info.tt_silver_ms = 110000
	info.tt_bronze_ms = 120000
	for pair in [[99000, 3], [100000, 3], [105000, 2], [110000, 2], [115000, 1],
			[120000, 1], [121000, 0]]:
		_expect(Career.medal_for_time(info, pair[0]) == pair[1],
			"medalie pentru %d ms: %d != %d" % [pair[0], Career.medal_for_time(info, pair[0]), pair[1]])
	var none := TrackInfo.new()
	_expect(not none.has_targets(), "tinte 0 => has_targets false")
	_expect(info.has_targets(), "tinte setate => has_targets true")
	for ms in [1, 100000, 999999999]:
		_expect(Career.medal_for_time(none, ms) == 0, "tinte 0 nu dau medalie (%d)" % ms)
	_expect(Career.time_trial_medal(&"nu_exista", 1) == 0, "pista necunoscuta => 0")

	# (b) ai_count: 0 in contratimp, readus de leave(); RACE nu-l atinge.
	var started := [0]
	Career.race_starter = func() -> void: started[0] += 1
	var saved_ai := GameState.ai_count
	GameState.ai_count = 5
	Career.start_track(&"kyoto", Career.Mode.TIME_TRIAL)
	_expect(GameState.ai_count == 0, "contratimp: ai_count 0, este %d" % GameState.ai_count)
	_expect(Career.is_time_trial() and Career.active_mode == Career.Mode.TIME_TRIAL,
		"modul contratimp setat")
	Career.leave()
	_expect(GameState.ai_count == 5, "leave() readuce ai_count: %d" % GameState.ai_count)
	_expect(not Career.is_time_trial(), "dupa leave nu mai e contratimp")
	# Doua start-uri la rand nu pierd valoarea originala.
	Career.start_track(&"kyoto", Career.Mode.TIME_TRIAL)
	Career.start_track(&"kyoto", Career.Mode.TIME_TRIAL)
	Career.leave()
	_expect(GameState.ai_count == 5, "start dublu: ai_count tot 5, este %d" % GameState.ai_count)
	Career.start_track(&"kyoto", Career.Mode.RACE)
	_expect(GameState.ai_count == 5, "RACE nu atinge ai_count")
	_expect(not Career.is_time_trial() and Career.active, "RACE: activ, nu contratimp")
	# finish_time_trial in RACE nu salveaza nimic.
	_expect(Career.finish_time_trial(90000) == 0
		and int(Career.track_state(&"kyoto").tt_best_ms) == 0,
		"finish_time_trial in RACE nu salveaza nimic")
	Career.leave()
	_expect(GameState.ai_count == 5, "leave dupa RACE lasa ai_count 5")
	_expect(started[0] == 4, "4 porniri, sunt %d" % started[0])
	GameState.ai_count = saved_ai

	# (c) finish_time_trial: timp minim, medalie maxima. Tintele pistei reale
	# sunt 0 (neintroduse), deci le punem temporar pe resursa si le readucem.
	var kyoto_info := TrackInfo.for_track(TrackInfo.index_of_id(&"kyoto"))
	var old_targets := [kyoto_info.tt_gold_ms, kyoto_info.tt_silver_ms, kyoto_info.tt_bronze_ms]
	kyoto_info.tt_gold_ms = 100000
	kyoto_info.tt_silver_ms = 110000
	kyoto_info.tt_bronze_ms = 120000
	Career.start_track(&"kyoto", Career.Mode.TIME_TRIAL)
	var m1 := Career.finish_time_trial(130000)
	var m2 := Career.finish_time_trial(105000)
	var st := Career.track_state(&"kyoto")
	_expect(m1 == 0 and m2 == 2, "medalii intoarse: %d, %d" % [m1, m2])
	_expect(int(st.tt_best_ms) == 105000 and int(st.tt_medal) == 2,
		"best 105000 / medalie 2: %d / %d" % [int(st.tt_best_ms), int(st.tt_medal)])
	Career.finish_time_trial(118000)
	st = Career.track_state(&"kyoto")
	_expect(int(st.tt_best_ms) == 105000 and int(st.tt_medal) == 2,
		"un timp mai slab nu strica best-ul / medalia")
	Career.leave()
	kyoto_info.tt_gold_ms = old_targets[0]
	kyoto_info.tt_silver_ms = old_targets[1]
	kyoto_info.tt_bronze_ms = old_targets[2]
	# Tinte 0: timpul se salveaza, medalia nu.
	Career.start_track(&"serengeti", Career.Mode.TIME_TRIAL)
	var m3 := Career.finish_time_trial(200000)
	_expect(m3 == 0 and int(Career.track_state(&"serengeti").tt_best_ms) == 200000,
		"fara tinta: timp salvat, fara medalie")
	Career.leave()
	Career.race_starter = Callable()

	# (d) semnalele cursei exista (fara sa instantiem o cursa intreaga).
	var race_script := load("res://scenes/race/race.gd") as GDScript
	var race: Node = race_script.new()
	_expect(race.has_signal("lap_completed"), "Race.lap_completed lipseste")
	_expect(race.has_signal("race_finished"), "Race.race_finished lipseste")
	race.free()

	# (e) rezervorul: steagul exista pe Car, implicit true.
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	_expect(car.turbo_recharge, "Car.turbo_recharge implicit true")
	car.free()


func _report() -> void:
	if _checks < MIN_CHECKS:
		_fails.append("doar %d verificari au rulat (minim %d) — garda e oarba" % [
			_checks, MIN_CHECKS])
	for f in _fails:
		printerr("probe_career: ", f)
	print("probe_career: %d verificari" % _checks)
	if _fails.is_empty():
		print("VERDICT: OK")
		get_tree().quit()
		return
	print("VERDICT: PROBLEMA (%d)" % _fails.size())
	get_tree().quit(1)
