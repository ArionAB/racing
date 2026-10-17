class_name ChallengeTracker
extends Node
## Numara evenimentele care conteaza pentru provocarea gimmick-ului (brief
## §4.3): ZERO_EVENTS (primul eveniment al JUCATORULUI o pica), AT_LEAST,
## EVERY_LAP, CLEAN_LAP — vezi `CareerChallenge.Rule`. Turele vin de la `Race`
## prin `notify_lap`.
##
## Nu schimba nimic in joc: doar asculta semnale care existau deja pe hazarduri
## si pe `Car`. Reusita se decide la `race_finished` (`evaluate`); tracker-ul e
## copil al lui `Race`, deci moare cu cursa si abonarile cu el.
##
## DE CE conteaza doar `player`: AI-ul si traficul sunt aruncati, striviti si
## loviti la fel; provocarea e despre cum conduci TU printre hazarduri.
##
## Sursele de semnal se gasesc dupa CLASA in arborele pistei (hazardele sunt
## copii sau nepoti ai ei). `sources` explicit (sonda) le ocoleste: un nod cu
## semnalul potrivit e suficient, tracker-ul se aboneaza dupa NUME de semnal.

signal failed_changed(failed: bool)
## Textul de progres pentru HUD s-a schimbat (`progress_text`).
signal progress_changed(text: String)

var challenge: CareerChallenge
var player: Car
## Cate evenimente ale jucatorului au fost numarate.
var events: int = 0
var failed: bool = false
## Evenimente per tur INCHEIAT (in ordinea turelor) si ale turului curent.
var closed_laps: Array[int] = []
var lap_events: int = 0
var _zone_node: Node


func setup(p_challenge: CareerChallenge, p_player: Car, track: Node,
		sources: Array[Node] = []) -> void:
	challenge = p_challenge
	player = p_player
	if challenge.fail_event != &"":
		match challenge.fail_event:
			&"bus_hit": _listen_hazards(track, sources, &"bus_hit", _on_fail_car)
			_: push_warning("ChallengeTracker: fail_event necunoscut '%s'" % challenge.fail_event)
	match challenge.event:
		&"thrown": _listen_hazards(track, sources, &"car_thrown", _on_car_first)
		&"fireball": _listen_hazards(track, sources, &"fireball_hit", _on_car_first)
		&"animal": _listen_hazards(track, sources, &"animal_hit", _on_car_first)
		&"shove": _listen_hazards(track, sources, &"shoved", _on_car_second)
		&"crush": player.crushed.connect(_on_crushed)
		&"splash": player.splashed.connect(_on_splashed)
		&"traffic_bump": player.bumped.connect(_on_bumped)
		&"red_run": _listen_hazards(track, sources, &"passed_on_red", _on_car_first)
		&"boarded": _listen_hazards(track, sources, &"boarded", _on_car_first)
		&"plate_broken": _listen_hazards(track, sources, &"plate_broken", _on_plate_broken)
		&"wall_hit":
			_resolve_zone(track)
			player.wall_hit.connect(_on_wall_hit)
		# Scurtatura: o masina pe ea are `route != 0` — se sondeaza, nu are semnal.
		&"branch": set_physics_process(true)
		_: push_warning("ChallengeTracker: eveniment necunoscut '%s'" % challenge.event)


func _ready() -> void:
	# Sondajul de ruta ruleaza doar pentru `branch`.
	set_physics_process(false)


## `branch`: primul tick cu jucatorul pe o ruta secundara marcheaza turul
## curent (o singura data per tur; restul turului nu mai numara).
func _physics_process(_delta: float) -> void:
	if challenge != null and challenge.event == &"branch" \
			and player != null and player.route != 0 and lap_events == 0:
		_count()


## Race anunta un tur incheiat (`laps` = turele terminate pana acum). EVERY_LAP
## pica pe loc la un tur fara eveniment; CLEAN_LAP doar il noteaza.
func notify_lap(_laps: int) -> void:
	closed_laps.append(lap_events)
	var empty := lap_events == 0
	lap_events = 0
	if empty and challenge.rule == CareerChallenge.Rule.EVERY_LAP:
		_fail()
	progress_changed.emit(progress_text())


## Reusita dupa regula (vezi `CareerChallenge.Rule`). Pe EVERY_LAP, turele
## incheiate sunt deja evaluate in `notify_lap`; aici doar `failed`.
func evaluate() -> bool:
	match challenge.rule:
		CareerChallenge.Rule.AT_LEAST:
			return not failed and events >= challenge.count
		CareerChallenge.Rule.CLEAN_LAP:
			return closed_laps.has(0)
		_:
			return not failed


## Progresul pentru HUD; gol la ZERO_EVENTS (e pica-pe-loc, nu are ce numara).
func progress_text() -> String:
	match challenge.rule:
		CareerChallenge.Rule.AT_LEAST:
			return "%d / %d" % [mini(events, challenge.count), challenge.count]
		CareerChallenge.Rule.EVERY_LAP:
			var lap := mini(closed_laps.size() + 1, GameState.total_laps)
			return "LAP %d%s" % [lap, " \u2713" if lap_events > 0 else ""]
		CareerChallenge.Rule.CLEAN_LAP:
			var lap := mini(closed_laps.size() + 1, GameState.total_laps)
			return "LAP %d: %d PLATES" % [lap, lap_events]
	return ""


## Clasele de hazard care emit semnalul fiecarui eveniment (pentru gasirea lor
## in pista). Shishi-odoshi si Daruma emit tot `car_thrown`.
static func _is_source(node: Node, signal_name: StringName) -> bool:
	match signal_name:
		&"car_thrown":
			return node is GionMatsuriHazard or node is ShishimaiHazard \
				or node is ShishiOdoshiHazard or node is DarumaOtoshiHazard
		&"fireball_hit": return node is FireballGeyser
		&"animal_hit": return node is HerdHazard
		&"shoved": return node is BusHazard
		&"passed_on_red", &"bus_hit": return node is TunnelSignalHazard
		&"boarded": return node is CablewayHazard
		&"plate_broken": return node is IceFieldHazard
	return false


func _listen_hazards(track: Node, sources: Array[Node], signal_name: StringName,
		handler: Callable) -> void:
	var found: Array[Node] = sources.duplicate()
	if found.is_empty() and track != null:
		_collect(track, signal_name, found)
	if found.is_empty():
		# Un contract scris pentru un gimmick care lipseste nu are ce masura:
		# provocarea ar fi mereu „reusita". Se vede in log, nu in tacere.
		push_warning("ChallengeTracker: pista '%s' nu are niciun hazard cu semnalul '%s'"
			% [challenge.track, signal_name])
		return
	for source in found:
		source.connect(signal_name, handler)


func _collect(node: Node, signal_name: StringName, out: Array[Node]) -> void:
	if _is_source(node, signal_name):
		out.append(node)
	for child in node.get_children():
		_collect(child, signal_name, out)


# car_thrown(car[, on_strike]), fireball_hit(car), animal_hit(car, ratio)
func _on_car_first(car: Car, _extra: Variant = null) -> void:
	if car == player:
		_count()


# shoved(bus, car)
func _on_car_second(_bus: Node, car: Car) -> void:
	if car == player:
		_count()


func _on_crushed(_car: Car, _severity: float) -> void:
	_count()


func _on_splashed(_car: Car, strength: float) -> void:
	if strength >= challenge.threshold:
		_count()


func _on_bumped(_car: Car, other: Car, _delta_v: float) -> void:
	if other != null and other.controller is TrafficController:
		_count()


# plate_broken(cars): conteaza doar daca jucatorul era pe placa.
func _on_plate_broken(cars: Array) -> void:
	if player in cars:
		_count()


# bus_hit(car): autocarul a lovit pe cineva; doar jucatorul pica provocarea.
func _on_fail_car(car: Car) -> void:
	if car == player:
		_fail()


## Zona se cauta dupa nume in pista. Lipsa ei NU e eroare de joc, dar ar face
## provocarea „mereu reusita" (evenimentul n-ar numara niciodata): se vede in
## log, iar sonda verifica ca zona exista pe pista reala.
func _resolve_zone(track: Node) -> void:
	if challenge.zone == &"":
		return
	if track != null:
		_zone_node = track.find_child(String(challenge.zone), true, false)
	if _zone_node == null:
		push_warning("ChallengeTracker: pista '%s' nu are zona '%s'"
			% [challenge.track, challenge.zone])


func _in_zone() -> bool:
	if challenge.zone == &"":
		return true
	if _zone_node == null:
		return false
	# CameraZone are intindere pe fractie (Cappadocia: StancaSpirala) SAU cutie;
	# `_player_inside` le stie pe amandoua, deci nu dublam logica.
	if _zone_node is CameraZone:
		return (_zone_node as CameraZone)._player_inside()
	if _zone_node is Area3D:
		return (_zone_node as Area3D).overlaps_body(player)
	return false


func _on_wall_hit(_car: Car, impact: float) -> void:
	if impact >= challenge.threshold and _in_zone():
		_count()


func _fail() -> void:
	if not failed:
		failed = true
		failed_changed.emit(true)


func _count() -> void:
	events += 1
	lap_events += 1
	# Doar ZERO_EVENTS pica la primul eveniment; celelalte reguli numara.
	if challenge.rule == CareerChallenge.Rule.ZERO_EVENTS:
		_fail()
	progress_changed.emit(progress_text())
