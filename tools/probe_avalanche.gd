extends Node
## Garda avalansei: dovada ca masina prinsa chiar e INGHITITA, CARATA la vale si
## REPUSA in spate.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAvalanche.tscn
##
## Ruleaza CA SCENA, nu cu --script: masina, hazardul si pista au nevoie de
## autoload-uri (AudioManager). Cu `--script`, `car.gd` nici nu compileaza.
##
## ############################################################################
## CE VERIFICA, si de ce fiecare cifra conteaza
##
## 1. CICLUL. Ca fazele se succed in ordine si masa chiar traverseaza soseaua:
##    porneste de pe versant (lateral, sus) si ajunge dincolo de drum. O sonda
##    care doar numara noduri ar trece si daca masa ramane parcata sub harta.
##
## 2. INGHITIREA. Masina intra in traiectorie si sonda urmareste ce pateste:
##    a fost scoasa din cursa (`race_active`), a fost turtita (semnalul
##    `crushed`), si a primit invartirea de caroserie.
##
## 3. CARATUL — singura proba care desparte avalansa de tren, si singurul motiv
##    pentru care hazardul asta exista separat. Se masoara cati metri s-a
##    deplasat masina CAT era inghitita si in ce directie. Daca numarul e ~0,
##    avalansa e „inca un tren cu alt model" si mecanica nu si-a facut treaba.
##
## 4. REPUNEREA. Ca masina revine in cursa dupa stun si ca ajunge IN SPATE fata
##    de unde a fost inghitita — nu in fata, ceea ce ar fi un cadou.
## ############################################################################

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Cati metri inaintea avalansei porneste masina.
const RUN_UP: float = 70.0
## Cat urmarim in total, in secunde de simulare.
const WATCH: float = 12.0
## Cat trebuie sa fie carata masina ca sa spunem ca „te ia cu ea", in metri.
## Sub atat, efectul nu se distinge de o simpla oprire pe loc.
const MIN_DRAG: float = 6.0

## Cate secunde de la inceputul traversarii pana cand masa e PE AXA drumului.
##
## Se DERIVA din constantele hazardului, nu se scrie: X-ul interpoleaza liniar
## de la `START_SIDE` la `-END_SIDE`, deci trece prin zero la fractia
## START_SIDE / (START_SIDE + END_SIDE) din cursa. Scris de mana, s-ar
## desincroniza tacut la prima ajustare a geometriei si sonda ar raporta
## „neprinsa" pentru un hazard perfect functional.
static func _sweep_mid() -> float:
	var a := AvalancheHazard.START_SIDE
	var b := AvalancheHazard.END_SIDE
	return AvalancheHazard.SWEEP * (a / (a + b))

var _track: Track
var _car: Car
var _av: AvalancheHazard
var _time: float = 0.0

## Ce am observat pe parcurs.
var _was_crushed := false
var _left_race := false
var _swallow_pos := Vector3.ZERO
var _swallow_idx := -1
var _drag := 0.0
var _last_pos := Vector3.ZERO
var _carried_prev := false
var _returned := false
var _respawn_idx := -1
var _phase_seen := {}
var _mass_span := AABB()
var _mass_samples := 0
## Diagnostic: cea mai mica distanta masina-masa, si contextul ei.
var _closest := 1e9
var _closest_t := 0.0
var _closest_phase := -1
## Urmarire cadru cu cadru, pentru diagnostic: --dbg
var _dbg := false


func _ready() -> void:
	_dbg = "--dbg" in OS.get_cmdline_user_args()
	await get_tree().process_frame
	_track = TrackFromPath.new()
	_track.custom_name = "SondaAvalansa"
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame

	# Avalansa se planteaza ca nod, adica pe drumul pe care va fi folosita in
	# practica — asa sonda acopera SI lantul HazardMarker -> _build_avalanche,
	# nu doar clasa hazardului.
	var marker := HazardMarker.new()
	marker.kind = HazardMarker.Kind.AVALANCHE
	var baked: Array = _track.baked
	marker.position = Vector3(baked[int(baked.size() * 0.45)])
	_track.add_child(marker)
	_track.rebuild()
	await get_tree().process_frame

	_av = _find_avalanche(_track)
	if _av == null:
		print("PICAT: nodul AVALANCHE nu a produs un AvalancheHazard")
		get_tree().quit(1)
		return

	_spawn_car()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _av == null or _car == null:
		return
	_time += delta
	_observe()
	if _dbg and int(_time * 60.0) % 30 == 0:
		print("t=%.2f faza=%d masa=%s masina=%s dist=%.1f v=%.1f" % [
			_time, _av._last_phase, str(_av._mass.position),
			str(_track.to_local(_car.global_position)),
			_car.global_position.distance_to(_av._mass.global_position),
			_car.velocity.length()])
	if _time >= WATCH:
		set_physics_process(false)
		_report()


func _observe() -> void:
	# Amplitudinea reala a masei, ca sa stim ca traverseaza si nu sta pe loc.
	if _av._mass != null and _av._mass.visible:
		var p := _av._mass.global_position
		if _mass_samples == 0:
			_mass_span = AABB(p, Vector3.ZERO)
		else:
			_mass_span = _mass_span.expand(p)
		_mass_samples += 1
	_phase_seen[_av._last_phase] = true

	# Diagnostic: cat de aproape a trecut masina de masa, si cand.
	if _av._mass != null and _av._mass.visible:
		var d := _car.global_position.distance_to(_av._mass.global_position)
		if d < _closest:
			_closest = d
			_closest_t = _time
			_closest_phase = _av._last_phase

	var carried: bool = _av._carried.has(_car)
	if carried and not _carried_prev:
		# Momentul inghitirii.
		_swallow_pos = _car.global_position
		_swallow_idx = _track.closest_index_global(_swallow_pos)
		_last_pos = _swallow_pos
		_left_race = not _car.race_active
	if carried:
		_drag += _car.global_position.distance_to(_last_pos)
		_last_pos = _car.global_position
	if _carried_prev and not carried:
		# A fost eliberata: repunerea se face pe timer, deci o citim putin dupa.
		_returned = _car.race_active
	_carried_prev = carried
	if _swallow_idx >= 0 and _returned and _respawn_idx < 0:
		_respawn_idx = _track.closest_index_global(_car.global_position)


func _report() -> void:
	print("")
	print("=== Sonda AvalancheHazard ===")

	var failed := false

	# 1. ciclul
	var phases: Array = _phase_seen.keys()
	phases.sort()
	var span := _mass_span.size.length()
	print("faze parcurse: %s | deplasarea masei: %.1f m (%d esantioane)"
			% [str(phases), span, _mass_samples])
	if phases.size() < 2:
		print("  PROBLEMA: avalansa nu a parcurs mai multe faze")
		failed = true
	if span < _av.road_half_width:
		print("  PROBLEMA: masa nu traverseaza soseaua (semilatime %.1f m)"
				% _av.road_half_width)
		failed = true

	# 2. inghitirea
	print("cea mai mica distanta masina-masa: %.1f m (la t=%.2f s, faza %d)"
			% [_closest, _closest_t, _closest_phase])
	print("inghitita: %s | scoasa din cursa: %s | turtita: %s"
			% [_swallow_idx >= 0, _left_race, _was_crushed])
	if _swallow_idx < 0:
		print("  PROBLEMA: masina nu a fost prinsa niciodata")
		failed = true
	else:
		if not _left_race:
			print("  PROBLEMA: masina a ramas in cursa cat era inghitita")
			failed = true
		if not _was_crushed:
			print("  PROBLEMA: semnalul `crushed` nu a venit")
			failed = true

	# 3. caratul — proba care desparte avalansa de tren
	print("carata: %.1f m (prag %.1f)" % [_drag, MIN_DRAG])
	if _swallow_idx >= 0 and _drag < MIN_DRAG:
		print("  PROBLEMA: masina nu a fost dusa la vale — e un tren, nu o avalansa")
		failed = true

	# 4. repunerea
	if _swallow_idx >= 0:
		var n := _track.baked.size()
		var back := posmod(_swallow_idx - _respawn_idx, n)
		var fwd := posmod(_respawn_idx - _swallow_idx, n)
		var behind := back < fwd
		print("repusa: %s | index %d -> %d (%s cu %d pasi)"
				% [_returned, _swallow_idx, _respawn_idx,
				"in spate" if behind else "in fata", mini(back, fwd)])
		if not _returned:
			print("  PROBLEMA: masina nu a revenit in cursa dupa stun")
			failed = true
		elif not behind:
			print("  PROBLEMA: repunerea a mutat masina INAINTE — ar fi un cadou")
			failed = true

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


func _spawn_car() -> void:
	var n := _track.baked.size()
	var idx := _track.closest_index_global(_av.global_position)
	# Se merge inapoi pe DISTANTA REALA dintre puncte, nu pe `bake_interval`.
	# Prima versiune impartea RUN_UP la `bake_interval` si presupunea ca un pas
	# baked masoara atat — nu masoara, iar masina pornea DUPA hazard si se
	# departa de el (urmarit cadru cu cadru: 23 m la t=1.0, apoi tot mai mult).
	var back := idx
	var walked := 0.0
	while walked < RUN_UP:
		var prev := posmod(back - 1, n)
		walked += _track.baked[prev].distance_to(_track.baked[back])
		back = prev
		if back == idx:
			break # tur complet: pista e mai scurta decat RUN_UP
	var dir := (_track.baked[posmod(back + 1, n)] - _track.baked[back]).normalized()
	var start: Vector3 = _track.baked[back] + Vector3.UP * 0.6

	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.track = _track
	_car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), start)
	_car.velocity = dir * 30.0
	_car.road_index = _track.closest_index_global(start)
	_car.last_safe_index = _car.road_index
	_car.race_active = true
	_car.crushed.connect(func(_c: Car, _s: float) -> void: _was_crushed = true)

	# Creier de AI, nu volan blocat: fara controller masina nu accelereaza si
	# nici nu ajunge la hazard (lectia din probe_typhoon.gd).
	var ai := AIController.new()
	_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260812
	ai.configure(_track, rng)
	ai.line_offset = 0.0

	# CEASUL AVALANSEI SE POTRIVESTE CU MASINA, nu invers.
	#
	# Fara asta sonda e o loterie: ciclul are 8 secunde, masina face cei 70 m in
	# ~2.3 s, si daca fazele nu se aliniaza masa trece cat masina inca accelereaza
	# — prima rulare a raportat „NEPRINSA" cu 25 m distanta minima la t=0.57 s,
	# adica avalansa isi terminase trecerea inainte ca masina sa ajunga.
	#
	# Se calculeaza cand ajunge masina pe axa hazardului si se da ceasul inapoi
	# astfel incat MASA SA FIE PE SOSEA exact atunci. Nu e o ajustare a
	# mecanicii, e sonda care alege momentul pe care in cursa reala il alege
	# jucatorul.
	#
	# Momentul cheie e MIJLOCUL traversarii (masa e la x = 0), nu inceputul ei:
	# aliniat pe inceput, masa ajungea pe drum cu ~1.5 s dupa ce masina trecuse
	# — urmarit cadru cu cadru, ratare la 23 m.
	#
	# Viteza medie e masurata, nu presupusa: masina porneste la 30 m/s si
	# accelereaza spre ~37, deci un ETA calculat pe viteza de start ar fi cu
	# ~20% prea lung.
	var eta := RUN_UP / 35.0
	_av._time = fposmod(_av.TELEGRAPH + _sweep_mid() - eta, _av.period)


func _find_avalanche(node: Node) -> AvalancheHazard:
	for child in node.get_children():
		if child is AvalancheHazard:
			return child as AvalancheHazard
		var found := _find_avalanche(child)
		if found != null:
			return found
	return null
