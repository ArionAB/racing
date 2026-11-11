extends Node
## QUICK RACE: jucatorul vede exact pistele de lansare, nicio cale din UI nu-l
## duce pe bancurile de test (Dunele = Track01, Okinawa manual = Track08), iar
## registrul uneltelor (`GameState.TRACK_SCENES`) nu s-a mutat (issue #680).
##
## Contractele:
##   1. `QuickRaceTracks.indices()` are exact pistele din EXPECTED (15 la
##      10 nov 2026), fara dubluri de index si fara doua cartonase cu acelasi
##      nume afisat ("Okinawa" era pe Track08 SI pe Track20); ordinea: pistele
##      cupelor, cupa cu cupa, apoi restul in ordinea registrului;
##   2. `TrackSelectPanel` real: cartonasele din grila sunt exact lista de mai
##      sus, in aceeasi ordine; focusul la prima pornire (`selected_track` = 0,
##      adica Dunele) cade pe un cartonas jucabil, iar dupa o cursa pe pista
##      jucata;
##   3. cariera (lumi + provocari) si cupele numesc doar piste jucabile;
##   4. registrul e neatins: primele 17 intrari din TRACK_SCENES/TRACK_NAMES
##      sunt cele de dinainte (indicii uneltelor si cheile recordurilor stau
##      pe loc); o pista noua se poate doar ADAUGA la coada;
##   5. fiecare pista din lista se incarca si se instantiaza ca `Track`
##      (`--full`: o si construieste in arbore — lent, minute).
##
## Cand intra San Francisco (Track25) in TRACK_SCENES, se adauga "Track25" in
## EXPECTED — garda pica pana atunci, intentionat: lista de lansare e o decizie.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeQuickRace.tscn
##   ... -- --full   # construieste fiecare pista in arbore (5. complet)

const EXPECTED: Array[String] = [
	"Track10", "Track11", "Track12", "Track13", "Track14", "Track15",
	"Track16", "Track17", "Track18", "Track19", "Track20", "Track21",
	"Track22", "Track23", "Track24",
]
const TEST_BENCHES: Array[String] = ["Track01", "Track08"]
## Registrul de la 10 nov 2026, in ordine. Uneltele il indexeaza cu literal.
const REGISTRY: Array[String] = [
	"Track01", "Track08", "Track21", "Track10", "Track11", "Track12", "Track13",
	"Track14", "Track15", "Track16", "Track17", "Track18", "Track19", "Track20",
	"Track22", "Track23", "Track24",
]
const REGISTRY_NAMES: Array[String] = [
	"Dunele", "Okinawa manual", "Transfagarasan", "Baikal", "Stromboli",
	"Chongqing", "Cappadocia", "Serengeti", "Machu Picchu", "Fiordland",
	"Jodhpur", "Kyoto", "Monument Valley", "Okinawa", "Ha Long", "Carrara",
	"Angkor",
]

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	print("")
	print("=== Quick Race: piste de lansare ===")
	var list := QuickRaceTracks.indices()
	_check_list(list)
	await _check_panel(list)
	_check_modes()
	_check_registry()
	await _check_load(list, "--full" in OS.get_cmdline_user_args())
	print("")
	print("VERDICT: %s" % ("PROBLEMA" if _failed else "OK"))
	get_tree().quit(1 if _failed else 0)


# ------------------------------------------------------------------ 1. lista

func _check_list(list: Array[int]) -> void:
	print("-- lista vazuta de jucator")
	var keys: Array[String] = []
	for index in list:
		keys.append(TrackInfo.scene_key(index))
	print("    ", ", ".join(_labels(list)))
	_check(list.size() == EXPECTED.size(),
		"%d piste (asteptat %d)" % [list.size(), EXPECTED.size()])
	for key in EXPECTED:
		_check(keys.has(key), "%s e in lista" % key)
	for key in keys:
		_check(EXPECTED.has(key), "%s e pista de lansare" % key)
	for key in TEST_BENCHES:
		_check(not keys.has(key), "bancul de test %s lipseste" % key)
	var seen_index: Dictionary = {}
	var seen_name: Dictionary = {}
	for index in list:
		var shown := TrackInfo.for_track(index).display_name.strip_edges().to_lower()
		_check(not seen_index.has(index), "%s o singura data" % GameState.track_label(index))
		_check(not seen_name.has(shown), "nume afisat unic: '%s' (%s / %s)"
			% [shown, GameState.track_label(index), seen_name.get(shown, "-")])
		seen_index[index] = true
		seen_name[shown] = GameState.track_label(index)
	# Ordinea: cupele intai, cupa cu cupa; apoi restul in ordinea registrului.
	var expected_order: Array[int] = []
	for res in GameState.WORLD_CUPS:
		var cup := res as WorldCup
		for race in cup.tracks.size():
			expected_order.append(cup.track_index(race))
	var rest_ok := true
	for k in range(expected_order.size(), list.size() - 1):
		rest_ok = rest_ok and list[k] < list[k + 1]
	_check(list.slice(0, expected_order.size()) == expected_order,
		"primele %d sunt pistele cupelor, in ordinea curselor" % expected_order.size())
	_check(rest_ok, "restul urmeaza ordinea registrului")


# ------------------------------------------------------------------- 2. UI

func _check_panel(list: Array[int]) -> void:
	print("-- grila QUICK RACE (TrackSelectPanel real)")
	var saved := GameState.selected_track
	GameState.selected_track = 0 # prima pornire: valoarea implicita = Dunele
	var panel := TrackSelectPanel.new()
	add_child(panel)
	await get_tree().process_frame
	var shown: Array[int] = []
	for card in panel.cards():
		shown.append(card.track_index)
	_check(shown == list, "cartonasele = lista, in aceeasi ordine (%d cartonase)" % shown.size())
	for index in shown:
		if not QuickRaceTracks.is_playable(index):
			_check(false, "cartonas pe bancul de test %s" % GameState.track_label(index))
	var first := panel.focus_card().track_index
	_check(QuickRaceTracks.is_playable(first),
		"focus la prima pornire pe o pista jucabila: %s" % GameState.track_label(first))
	var fiord := TrackInfo.index_of_id(&"fiordland")
	GameState.selected_track = fiord
	_check(panel.focus_card().track_index == fiord,
		"dupa o cursa pe Fiordland, focusul e pe Fiordland")
	panel.queue_free()
	GameState.selected_track = saved
	await get_tree().process_frame


# --------------------------------------------------------- 3. cariera, cupe

func _check_modes() -> void:
	print("-- cariera si cupele numesc doar piste jucabile")
	var problems := Career.validate()
	_check(problems.is_empty(), "config cariera valid (%s)" % ", ".join(problems))
	var ids: Array[String] = []
	for world in Career.worlds():
		for track_id in world.tracks:
			ids.append("%s:%s" % [world.id, track_id])
	for challenge in Career.config.challenges:
		ids.append("provocare:%s" % challenge.track)
	for res in GameState.WORLD_CUPS:
		var cup := res as WorldCup
		for track_id in cup.tracks:
			ids.append("%s:%s" % [cup.id, track_id])
	var bad: Array[String] = []
	for entry in ids:
		var track_id := StringName(entry.get_slice(":", 1))
		if not QuickRaceTracks.is_playable(TrackInfo.index_of_id(track_id)):
			bad.append(entry)
	_check(bad.is_empty(), "%d intrari, niciuna pe banc de test sau inexistenta %s"
		% [ids.size(), bad])


# --------------------------------------------------------------- 4. registru

func _check_registry() -> void:
	print("-- registrul uneltelor (TRACK_SCENES) nu s-a mutat")
	var ok := GameState.TRACK_SCENES.size() >= REGISTRY.size() \
		and GameState.TRACK_NAMES.size() == GameState.TRACK_SCENES.size()
	for i in mini(REGISTRY.size(), GameState.TRACK_SCENES.size()):
		if TrackInfo.scene_key(i) != REGISTRY[i] or GameState.TRACK_NAMES[i] != REGISTRY_NAMES[i]:
			ok = false
			print("    indexul %d: %s, asteptat %s (%s)"
				% [i, GameState.track_label(i), REGISTRY_NAMES[i], REGISTRY[i]])
	_check(ok, "primii %d indici si numele (cheile recordurilor) pe loc" % REGISTRY.size())
	for key in TEST_BENCHES:
		var index := GameState.TRACK_SCENES.find("res://scenes/tracks/%s.tscn" % key)
		_check(index >= 0 and TrackInfo.for_track(index).test_bench,
			"%s ramane in registru, marcat test_bench" % key)


# -------------------------------------------------------------- 5. incarcare

func _check_load(list: Array[int], full: bool) -> void:
	print("-- fiecare pista din lista se incarca%s" % (" (construita in arbore)" if full else ""))
	for index in list:
		var t0 := Time.get_ticks_msec()
		var scene := load(GameState.TRACK_SCENES[index]) as PackedScene
		var track: Track = null
		if scene != null:
			track = scene.instantiate() as Track
		if track != null and full:
			add_child(track)
			await get_tree().process_frame
			await get_tree().process_frame
		var ok := track != null
		if ok and full:
			ok = track.routes.size() > 0
		_check(ok, "%s (%d ms)" % [GameState.track_label(index), Time.get_ticks_msec() - t0])
		if track != null:
			if track.is_inside_tree():
				track.queue_free()
				await get_tree().process_frame
			else:
				track.free()


func _labels(list: Array[int]) -> Array[String]:
	var out: Array[String] = []
	for index in list:
		out.append(TrackInfo.for_track(index).display_name)
	return out
