extends Node
## Garda carierei: config, persistenta, puncte si gating, versiune necunoscuta,
## regrupare, raftul din scena si lacatul cursei. Merge HEADLESS.
##
## Punctele (25 oct 2026): locul 1/2/3 = 3/2/1, provocarea reusita in cursa = +1,
## contratimpul 0 (fara tinte). Lacatele: lumea 2 la 8, lumea 3 la 18.
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
		w.points_to_unlock = src.points_to_unlock
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
	_expect(Career.points() == 0, "de la zero punctele sunt 0, sunt %d" % Career.points())
	_expect(Career.is_world_unlocked(w[0]), "lumea free trebuie sa fie deschisa")
	_expect(not Career.is_world_unlocked(w[1]) and not Career.is_world_unlocked(w[2]),
		"de la zero lumile 2 si 3 sunt sigilate")
	_expect(Career.points_missing(w[1]) == 8 and Career.points_missing(w[2]) == 18,
		"lipsesc 8 si 18, sunt %d si %d" % [Career.points_missing(w[1]), Career.points_missing(w[2])])
	var rivals := 0
	for world in w:
		if world.rival != &"":
			rivals += 1
	var expected_max := Career.MAX_TRACK_POINTS * 12 + Career.RIVAL_POINTS * rivals
	_expect(Career.max_points() == 48 and expected_max == 48,
		"max_points trebuie 48 (12 piste x 4, 0 rivali), e %d" % Career.max_points())

	# Lumea 1: locul 3 pe toate cele 4 piste = 4 puncte; lacatul lumii 2 e la 8.
	var placed := 0
	for id in w[0].tracks:
		Career.set_race_medal(id, Career.MEDAL_BRONZE)
		placed += 1
		_expect(Career.points() == placed, "puncte %d != puse %d" % [Career.points(), placed])
	_expect(not Career.is_world_unlocked(w[1]) and Career.points_missing(w[1]) == 4,
		"4 locuri 3 = 4 puncte, lumea 2 sigilata, lipsesc 4")
	# Contratimpul NU da puncte (fara tinte): medaliile lui nu misca lacatul.
	Career.set_time_trial(w[0].tracks[0], Career.MEDAL_GOLD, 70000)
	Career.set_time_trial(w[0].tracks[1], Career.MEDAL_SILVER, 70001)
	_expect(Career.points() == 4, "contratimpul nu da puncte, sunt %d" % Career.points())
	# Provocarea = +1 pe pista, independent de loc.
	for i in 2:
		Career.set_challenge(w[0].tracks[i])
		placed += 1
	_expect(Career.points() == 6 and placed == 6, "2 provocari => 6 puncte, sunt %d" % Career.points())
	_expect(not Career.is_world_unlocked(w[1]) and Career.points_missing(w[1]) == 2,
		"la 6 lumea 2 inca sigilata, lipsesc 2")
	# Locul mai bun PLATESTE: bronz -> aur pe aceeasi pista = +2 (asta e
	# diferenta fata de stampile, decizia din 25 oct 2026).
	Career.set_race_medal(w[0].tracks[0], Career.MEDAL_GOLD)
	_expect(Career.points() == 8, "bronz -> aur pe aceeasi pista = +2, sunt %d" % Career.points())
	_expect(Career.is_world_unlocked(w[1]), "la 8 puncte lumea 2 se deschide")
	_expect(not Career.is_world_unlocked(w[2]) and Career.points_missing(w[2]) == 10,
		"la 8 lumea 3 inca sigilata, lipsesc 10")
	# Aceeasi medalie pusa a doua oara nu aduce nimic; una mai slaba nici atat.
	Career.set_race_medal(w[0].tracks[0], Career.MEDAL_GOLD)
	Career.set_race_medal(w[0].tracks[0], Career.MEDAL_BRONZE)
	Career.set_challenge(w[0].tracks[0])
	_expect(Career.points() == 8, "repetarea nu da puncte in plus (%d)" % Career.points())
	_expect(Career.track_points(w[0].tracks[0]) == Career.MAX_TRACK_POINTS,
		"pista plina: 3 + 1 = %d" % Career.MAX_TRACK_POINTS)
	# Lumea 2: locul 2 pe toate cele 4 piste = +8 => 16; lacatul lumii 3 e la 18.
	for id in w[1].tracks:
		Career.set_race_medal(id, Career.MEDAL_SILVER)
	_expect(Career.points() == 16, "ar trebui 16 puncte, sunt %d" % Career.points())
	_expect(not Career.is_world_unlocked(w[2]), "la 16 lumea 3 inca sigilata")
	Career.set_challenge(w[1].tracks[0])
	_expect(not Career.is_world_unlocked(w[2]), "la 17 lumea 3 inca sigilata")
	Career.set_challenge(w[1].tracks[1])
	_expect(Career.points() == 18 and Career.is_world_unlocked(w[2]),
		"la 18 puncte lumea 3 se deschide (sunt %d)" % Career.points())
	_expect(is_equal_approx(Career.progress_fraction(), 18.0 / 48.0), "progress_fraction gresit")
	# O pista din afara lumilor nu conteaza (Ha Long e doar cursa rapida).
	Career.set_race_medal(&"halong", Career.MEDAL_GOLD)
	Career.set_challenge(&"halong")
	_expect(Career.points() == 18, "pista din afara lumilor nu aduce puncte (%d)" % Career.points())
	var counts := Career.medal_counts()
	# cursa: 1 aur + 3 bronz (lumea 1) + 4 argint (lumea 2); tt: 1 aur + 1
	# argint. Aurul de pe Ha Long nu intra (doar pistele din lumi).
	_expect(int(counts[3]) == 1 + 1 and int(counts[2]) == 4 + 1 and int(counts[1]) == 3,
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
	_expect(int(Career.track_state(&"kyoto").race_medal) == 0 and Career.points() == 0,
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
	var points_before := Career.points()
	# Kyoto: locul 2 (2) + provocare (1), contratimpul 0; Cappadocia: locul 1 (3).
	_expect(points_before == 6, "kyoto 3 + cappadocia 3 = 6, sunt %d" % points_before)

	# Kyoto trece din lumea 1 in lumea 2.
	cfg.worlds[0].tracks.erase(&"kyoto")
	cfg.worlds[1].tracks.append(&"kyoto")
	_expect(Career.validate(cfg).is_empty(), "config regrupat trebuie sa ramana valid")
	_expect(Career.track_state(&"kyoto") == state_before, "regruparea a schimbat starea pistei")
	_expect(Career.points() == points_before, "regruparea a schimbat totalul de puncte")
	_expect(Career.max_points() == 48, "max_points nu depinde de lume")

	# Deblocarea se recalculeaza din noile praguri.
	cfg.worlds[1].points_to_unlock = points_before + 1
	_expect(not Career.is_world_unlocked(cfg.worlds[1]), "prag mai sus => sigilata")
	cfg.worlds[1].points_to_unlock = points_before
	_expect(Career.is_world_unlocked(cfg.worlds[1]), "prag la nivelul curent => deschisa")

	# Rivalul: +RIVAL_POINTS la maxim si la puncte cand e batut, cheie pe rival.
	cfg.worlds[0].rival = &"rival_test"
	_expect(Career.max_points() == 48 + Career.RIVAL_POINTS, "un rival adauga RIVAL_POINTS la maxim")
	Career.set_rival_beaten(&"rival_test")
	_expect(Career.points() == points_before + Career.RIVAL_POINTS, "rivalul batut aduce RIVAL_POINTS")
	cfg.worlds[0].rival = &""
	cfg.worlds[2].rival = &"rival_test" # rivalul se muta in alta lume
	_expect(Career.points() == points_before + Career.RIVAL_POINTS, "rivalul batut ramane batut dupa mutare")
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
	_expect(panel._points_label.text == "POINTS  0 / 48",
		"pasaport initial: '%s'" % panel._points_label.text)
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
	_expect(panel._points_label.text == "POINTS  3 / 48",
		"dupa o medalie: '%s'" % panel._points_label.text)
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

	# Cu 8 puncte se deschide lumea 2: 8 carduri, 1 eticheta SEALED. Kyoto are
	# deja locul 1 (3); inca un loc 1 si doua locuri 3 = 8. Contratimpul NU
	# conteaza (fara tinte): medaliile lui nu misca lacatul.
	Career.set_race_medal(Career.worlds()[0].tracks[0], Career.MEDAL_GOLD)
	Career.set_race_medal(Career.worlds()[0].tracks[2], Career.MEDAL_BRONZE)
	Career.set_time_trial(Career.worlds()[0].tracks[0], Career.MEDAL_GOLD, 1000)
	_expect(not Career.is_world_unlocked(Career.worlds()[1]),
		"la 7 puncte (contratimpul nu conteaza) lumea 2 e inca sigilata")
	Career.set_race_medal(Career.worlds()[0].tracks[3], Career.MEDAL_BRONZE)
	_expect(Career.points() == 8, "setup: 8 puncte, sunt %d" % Career.points())
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
		_expect(buttons.size() == 3, "foaia are 3 butoane (RACE, TIME TRIAL, BACK): %d" % buttons.size())
		for key in ["RaceButton", "TimeTrialButton", "BackButton"]:
			_expect(buttons.has(key), "foaia: lipseste " + key)
			if buttons.has(key):
				_expect((buttons[key] as Button).custom_minimum_size.y >= 64.0,
					key + " sub 64 px")
		# Provocarea nu mai e proba separata (25 oct 2026): niciun buton CHALLENGE;
		# bonusul e o eticheta sub RACE (continutul ei il verifica ProbeChallenge).
		_expect(not buttons.has("ChallengeButton"), "foaia nu mai are buton CHALLENGE")
		var has_bonus := false
		for n in sheet_nodes:
			if n is Label and n.name == "BonusLabel":
				has_bonus = true
		_expect(has_bonus, "foaia pistei cu provocare are eticheta BONUS")
		if buttons.has("RaceButton"):
			var race_text := (buttons["RaceButton"] as Button).text
			_expect(("/ %d PTS" % Career.MAX_TRACK_POINTS) in race_text,
				"RACE arata punctele pistei din %d ('%s')" % [Career.MAX_TRACK_POINTS, race_text])
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

	var earned := Career.finish_active(1)
	_expect(earned == Career.MEDAL_GOLD and int(Career.track_state(&"kyoto").race_medal) == 3,
		"locul 1 => 3 puncte, aur salvat")
	_expect(Career.finish_active(5) == 0
		and int(Career.track_state(&"kyoto").race_medal) == 3,
		"locul 5 => 0 puncte si nu strica aurul")
	_expect(Career.finish_active(2, true) == Career.MEDAL_SILVER + Career.CHALLENGE_POINTS
		and int(Career.track_state(&"kyoto").race_medal) == 3
		and bool(Career.track_state(&"kyoto").challenge),
		"locul 2 + provocare => 2 + 1 acum; pe raft aurul ramane si bifa se pune")
	_expect(Career.track_points(&"kyoto") == Career.MAX_TRACK_POINTS,
		"pista: 3 (aur) + 1 (bonus) = %d" % Career.MAX_TRACK_POINTS)
	_expect(Career.active, "active ramane true pana la leave()")
	Career.leave()
	_expect(not Career.active, "leave() trebuie sa opreasca modul de cariera")
	_expect(Career.finish_active(1, true) == 0, "in afara carierei finish_active nu da puncte")
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
