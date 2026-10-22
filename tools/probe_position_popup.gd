extends Node
## Popup de schimbare de pozitie (feel: position-change, partea vizuala).
##
## Doua parti:
##   A. Logica de debounce (PositionWatch) pe un flux sintetic de pozitii, in timp
##      simulat: tinere, intoarcere, coalescare, cooldown, inactiv.
##   B. Cablajul REAL din Race.tscn: nimic in numaratoare, popup la o schimbare
##      reala de pozitie (sus/jos, culori), nimic la un schimb dus-intors rapid,
##      nimic dupa final.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePositionPopup.tscn

const WatchScript := preload("res://scenes/race/position_watch.gd")
const DT: float = 1.0 / 60.0

var _failed: bool = false
var _anns: Array[Vector2i] = []


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== Popup de pozitie ===")
	_part_a()
	await _part_b()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


# ------------------------------------------------------------------ A: logica

## Alimenteaza `watch` cu secventa [(pozitie, secunde)], activ.
func _feed(w: Node, seq: Array) -> void:
	for step in seq:
		for _i in int(round(float(step[1]) / DT)):
			w.observe(int(step[0]), DT, true)


func _new_watch() -> Node:
	var w: Node = WatchScript.new()
	add_child(w)
	_anns.clear()
	w.announced.connect(func(n: int, o: int) -> void: _anns.append(Vector2i(n, o)))
	return w


func _part_a() -> void:
	print("")
	print("-- A. debounce pe flux sintetic --")
	var w := _new_watch()
	_feed(w, [[4, 1.0]])
	_check(_anns.is_empty(), "pozitie stabila: niciun anunt")
	_feed(w, [[3, 0.3], [4, 0.3], [3, 0.3], [4, 0.3], [3, 0.3], [4, 1.0]])
	print("  schimb 3<->4 la 0.3 s, 5 cicluri: %d anunturi" % _anns.size())
	_check(_anns.is_empty(), "dus-intors sub 0.4 s nu anunta nimic")
	_feed(w, [[3, 0.6]])
	_check(_anns.size() == 1 and _anns[0] == Vector2i(3, 4), "3 tinut 0.6 s => un anunt 4->3")
	_anns.clear()
	# Coalescare: 3 -> 2 -> 1 la 0.2 s, apoi tinut.
	_feed(w, [[2, 0.2], [1, 0.8]])
	print("  3->2->1 rapid: %s" % [_anns])
	_check(_anns.size() == 1 and _anns[0] == Vector2i(1, 3), "coalescare: un singur anunt 3->1")
	w.queue_free()
	# Cooldown: dupa un anunt, un schimb real iese abia la 0.8 s de la el, desi hold-ul
	# (0.4 s) s-ar fi implinit mai devreme.
	w = _new_watch()
	_feed(w, [[4, 0.5], [3, 0.45]])
	_check(_anns.size() == 1, "primul anunt 4->3")
	_anns.clear()
	_feed(w, [[4, 0.6]])
	_check(_anns.is_empty(), "in cooldown (0.8 s) un schimb nou inca nu iese")
	_feed(w, [[4, 0.3]])
	_check(_anns.size() == 1 and _anns[0] == Vector2i(4, 3), "dupa cooldown iese 3->4")
	# Inactiv: resetare, fara anunt la reintrare.
	_anns.clear()
	for _i in 60:
		w.observe(6, DT, false)
	_feed(w, [[6, 1.0]])
	_check(_anns.is_empty(), "dupa inactiv (numaratoare/final) pozitia noua e referinta, fara anunt")
	w.queue_free()


# ------------------------------------------------------------------- B: Race

func _frames(seconds: float) -> void:
	for _i in int(round(seconds * 60.0)):
		await get_tree().physics_frame


func _set_rank(race: Node, to_top: bool) -> void:
	# Jucatorul e indexul 0 in `cars`/`_progress`. Un total extrem il pune primul/ultimul,
	# dar sub un tur intreg (altfel `car.finished` ar opri cursa jucatorului).
	race._progress[0].total = 0.9 if to_top else -0.9


func _part_b() -> void:
	print("")
	print("-- B. cablaj in Race.tscn --")
	GameState.total_laps = 3
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(race)
	var guard := 0
	while (race.get("position_watch") == null) and guard < 1500:
		await get_tree().process_frame
		guard += 1
	_check(race.get("position_watch") != null, "Race.position_watch construit")
	if race.get("position_watch") == null:
		_failed = true
		return
	var hud = race.hud
	var pop = hud.position_popup
	_check(pop != null and not pop.visible, "popup exista si e ascuns la start")
	# Numaratoare: pozitia schimbata fortat nu scoate popup.
	_check(race.state == race.State.COUNTDOWN, "cursa e in numaratoare")
	_set_rank(race, true)
	race.call("_update_positions")
	await _frames(1.0)
	_set_rank(race, false)
	race.call("_update_positions")
	await _frames(1.0)
	print("  pozitie fortata in numaratoare: %d" % race.player.race_position)
	print("  numaratoare: popup afisat de %d ori" % pop.shown_count)
	_check(pop.shown_count == 0, "nicio aparitie in numaratoare")
	guard = 0
	while race.state != race.State.RUNNING and guard < 1500:
		await get_tree().physics_frame
		guard += 1
	_check(race.state == race.State.RUNNING, "cursa a pornit")
	# Linia de start amesteca pozitiile (totaluri aproape egale + rocket start AI):
	# lasam clasamentul sa se aseze, apoi masuram DIN starea asta.
	_set_rank(race, true)
	await _frames(1.5)
	_set_rank(race, false)
	await _frames(3.5)
	var start_pos: int = race.player.race_position
	var base: int = pop.shown_count
	print("  pozitia asezata: %d din %d, popup-uri de asezare: %d" % [
		start_pos, race.cars.size(), base])
	# Depasit: coboara pe ultimul loc (daca nu e deja acolo, atunci urca intai).
	var total: int = race.cars.size()
	var go_top: bool = start_pos > 1
	_set_rank(race, go_top)
	await _frames(0.2)

	_check(pop.shown_count == base, "la 0.2 s dupa schimbare: inca nimic (hold 0.4 s)")
	await _frames(0.7)
	var first_dir: int = pop.last_dir
	print("  dupa schimbare reala: shown=%d text=%s dir=%d vizibil=%s" % [
		pop.shown_count, pop.last_text, pop.last_dir, str(pop.visible)])
	_check(pop.shown_count == base + 1 and pop.visible, "schimbare reala tinuta => popup")
	_check(first_dir == (1 if go_top else -1), "directia corespunde (urcat = verde, coborat = rosu)")
	_check(pop.last_text == ("P1" if go_top else "P%d" % total), "textul e pozitia noua")
	var col1: Color = pop.last_color
	await _frames(2.2)
	_check(not pop.visible, "popup se stinge singur")
	# Inversul, ca sa vedem ambele culori.
	_set_rank(race, not go_top)
	await _frames(1.1)
	print("  schimbare inversa: shown=%d dir=%d" % [pop.shown_count, pop.last_dir])
	_check(pop.shown_count == base + 2 and pop.last_dir == -first_dir, "schimbarea inversa => al doilea popup, directie opusa")
	_check(pop.last_color != col1, "culoare diferita pe directie opusa")
	await _frames(2.5)
	# Dus-intors rapid: 10 schimburi la 0.25 s.
	var before: int = pop.shown_count
	var flip := true
	for _i in 12:
		_set_rank(race, flip)
		flip = not flip
		await _frames(0.25)
	_set_rank(race, not flip) # revine la pozitia de dinainte de balansoar? nu conteaza: tinut mai jos
	print("  dus-intors 12 x 0.25 s: %d popup-uri noi" % (pop.shown_count - before))
	_check(pop.shown_count == before, "schimb dus-intors rapid nu declanseaza popup")
	# Dupa final: nimic.
	await _frames(1.2)
	race.call("_finish_race")
	var after_finish: int = pop.shown_count
	_check(not pop.visible, "final: popup ascuns")
	_set_rank(race, true)
	await _frames(1.5)
	_set_rank(race, false)
	await _frames(1.5)
	print("  dupa final: %d popup-uri noi" % (pop.shown_count - after_finish))
	_check(pop.shown_count == after_finish, "nicio aparitie dupa final")
	Engine.time_scale = 1.0
