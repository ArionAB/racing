extends Node
## Garda pentru #580 (tur fals dupa repunere langa linie) si #611 (locul final
## nu e locul real de sosire). Incarca Race.tscn REAL si conduce `_tick_race`
## de mana, cu progresul masinilor pus la milimetru — nu o copie a logicii.
##
##   #611: patru masini trec linia la ultimul tur, in ordinea AI1, AI2, jucator.
##         Depasirea din ultimul tick (cati cm dupa linie) e INVERS ordinii:
##         jucatorul, ultimul care trece, are cea mai mare depasire. Clasamentul
##         dupa `total` ingheta il punea pe 1; corect e locul 3, in
##         `race_finished`, in `player.race_position` si in `_final_order`.
##         Dupa sosire locul nu se mai misca (un AI care termina dupa tine nu te
##         coboara in tabelul punctelor).
##   #580: repunerea reala (`Car.respawn`) in spatele liniei, dupa ce tocmai a
##         fost trecuta, si traversarea din nou: `lap_completed` nu se emite a
##         doua oara. Contor "naiv" (floor(total) a crescut) il arat alaturi: el
##         e ce numara tabelul vechi din ProbeRace ca „tur de 0.85 s".
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFinishOrder.tscn

var _failed: bool = false
var _race: Race
var _laps_signal: Array[int] = []
var _finish_pos: int = -1
var _finish_emits: int = 0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== Tururi si ordine de sosire (#580, #611) ===")
	GameState.total_laps = 2
	_race = (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(_race)
	var guard := 0
	while _race.state != Race.State.RUNNING and guard < 2500:
		await get_tree().process_frame
		guard += 1
	_check(_race.state == Race.State.RUNNING, "cursa a pornit (%d cadre)" % guard)
	# Cursa o conduc eu: tick-urile proprii ale lui Race se opresc.
	_race.set_physics_process(false)
	_race.lap_completed.connect(func(laps: int, _ms: int) -> void: _laps_signal.append(laps))
	_race.race_finished.connect(func(pos: int, _ms: int) -> void:
		_finish_pos = pos
		_finish_emits += 1)
	await _probe_lap_respawn()
	await _probe_finish_order()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	Engine.time_scale = 1.0
	get_tree().quit(1 if _failed else 0)


## Pune masina `i` la `index` (pe ruta 0), cu progresul spus de apelant.
func _place(i: int, index: int) -> void:
	var car := _race.cars[i]
	car.global_transform = _race.track.recovery_transform(index, 0.0, 0)
	car.road_index = index
	car.route = 0


func _set_progress(i: int, total: float, laps: int) -> void:
	var st := _race._progress[i]
	st.total = total
	st.laps = laps
	st.frac = _race.track.frac_at(_race.cars[i].road_index, 0)


func _idx_at_frac(f: float) -> int:
	var r := _race.track.route_at(0)
	return int(round(f * float(r.baked.size()))) % r.baked.size()


func _probe_lap_respawn() -> void:
	print("-- #580: repunere langa linie --")
	var track := _race.track
	var player := _race.cars[0]
	var st := _race._progress[0]
	# Restul masinilor stau la distanta, ca sa nu se atinga nimic.
	for i in range(1, _race.cars.size()):
		_place(i, _idx_at_frac(0.5))
		_set_progress(i, 0.5, 0)
	var before := _idx_at_frac(0.99)
	var after := 2 # indecsi dupa linie: repunerea de 14 m o trece inapoi
	_place(0, before)
	_set_progress(0, track.frac_at(before, 0), 0)
	_laps_signal.clear()
	var naive := 0
	var prev_total := float(st.total)
	# 1) trece linia, pe drum.
	_place(0, after)
	_race._tick_race(1.0 / 60.0)
	naive += int(floor(float(st.total)) > floor(prev_total)); prev_total = float(st.total)
	_check(int(st.laps) == 1 and _laps_signal == [1],
		"trecerea reala se numara o data (laps=%d, semnal=%s)" % [st.laps, str(_laps_signal)])
	# 2) repunere reala la un punct sigur de dincolo de linie: aterizeaza 14 m in
	#    spate, adica peste linie inapoi.
	player.last_safe_index = after
	player.last_safe_route = 0
	player._respawn_cooldown = 0.0
	player.respawn()
	_race._tick_race(1.0 / 60.0)
	_check(float(st.total) < 1.0,
		"repusa in spatele liniei: progresul scade sub 1.0 (%.4f)" % float(st.total))
	naive += int(floor(float(st.total)) > floor(prev_total)); prev_total = float(st.total)
	# 3) traverseaza din nou.
	_place(0, after)
	_race._tick_race(1.0 / 60.0)
	naive += int(floor(float(st.total)) > floor(prev_total)); prev_total = float(st.total)
	_check(int(st.laps) == 1 and _laps_signal == [1],
		"a doua traversare NU e tur (laps=%d, semnal=%s)" % [st.laps, str(_laps_signal)])
	print("     info: contorul naiv floor(total) ar fi numarat %d (tabelul vechi ProbeRace)" % naive)
	# 4) invers: repusa DIN fata liniei (nu o trecuse), cu checkpoint chiar langa
	#    linie, nu poate fi mutata peste ea fara progres.
	_set_progress(0, track.frac_at(before, 0), 1)
	_place(0, before)
	st.total = 1.0 + track.frac_at(before, 0) - 1.0 # tur 2: inca nu a trecut linia
	st.total = 1.985
	_laps_signal.clear()
	player.last_safe_index = before
	player._respawn_cooldown = 0.0
	player.respawn()
	_race._tick_race(1.0 / 60.0)
	_check(float(st.total) < 2.0 and int(st.laps) == 1,
		"repusa inainte de linie: nu sare peste ea (total=%.4f, laps=%d)" % [st.total, st.laps])


func _probe_finish_order() -> void:
	print("-- #611: ordinea de sosire --")
	var cars := _race.cars
	_check(cars.size() >= 4, "sunt cel putin 4 masini (%d)" % cars.size())
	# Tabloul: jucatorul (0), AI1, AI2 trec in aceasta ordine; restul ramane in urma.
	var d := 0.002
	var over := {1: 0.0001, 2: 0.0010, 0: 0.0015}
	for i in cars.size():
		var idx := _idx_at_frac(0.3 + 0.05 * float(i))
		_place(i, idx)
		_set_progress(i, 1.0 + float(i) * 0.01, 1) # tur 2 din 2, departe de linie
	_race._progress[0].finish_t = -1.0
	# Cate un tick pentru fiecare, in ordinea AI1, AI2, jucator.
	for who: int in [1, 2, 0]:
		var idx := _idx_at_frac(0.0 + 0.0)
		_place(who, idx)
		var st := _race._progress[who]
		# `frac` din tick-ul trecut e cu `d` in spate; `total` a trecut linia cu over.
		st.frac = fposmod(_race.track.frac_at(cars[who].road_index, 0) - d, 1.0)
		st.total = 2.0 + float(over[who]) - d
		st.laps = 1
		_race._tick_race(1.0 / 60.0)
		_race._race_clock += 0.5 # intre sosiri trece timp
	_check(_finish_emits == 1, "race_finished emis o data (%d)" % _finish_emits)
	_check(_finish_pos == 3, "semnalul de final raporteaza locul 3 (a dat %d)" % _finish_pos)
	_check(cars[0].race_position == 3, "player.race_position = 3 (e %d)" % cars[0].race_position)
	_check(_race._final_order.find(0) == 2,
		"_final_order: jucatorul pe rangul 3 (gasit pe %d)" % (_race._final_order.find(0) + 1))
	_check(_race._final_order.slice(0, 3) == [1, 2, 0],
		"ordinea primilor trei = AI1, AI2, jucator (%s)" % str(_race._final_order.slice(0, 3)))
	# Cei care n-au terminat raman in spatele sositilor.
	var rest_ok := true
	for k in range(3, _race._final_order.size()):
		rest_ok = rest_ok and not cars[_race._final_order[k]].finished
	_check(rest_ok, "nesositii vin dupa cei sositi")
	# Dupa sosire, un AI care termina nu muta locul jucatorului.
	var late := 3
	var lst := _race._progress[late]
	_place(late, _idx_at_frac(0.0))
	lst.frac = fposmod(_race.track.frac_at(cars[late].road_index, 0) - d, 1.0)
	lst.total = 2.0 + 0.0005 - d
	lst.laps = 1
	_race._tick_race(1.0 / 60.0)
	_check(cars[0].race_position == 3,
		"un AI sosit dupa tine nu schimba locul jucatorului (%d)" % cars[0].race_position)
