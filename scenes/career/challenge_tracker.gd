class_name ChallengeTracker
extends Node
## Numara evenimentele care conteaza pentru provocarea gimmick-ului (brief
## §4.3, regula ZERO_EVENTS): primul eveniment al JUCATORULUI o pica.
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

var challenge: CareerChallenge
var player: Car
## Cate evenimente ale jucatorului au fost numarate.
var events: int = 0
var failed: bool = false


func setup(p_challenge: CareerChallenge, p_player: Car, track: Node,
		sources: Array[Node] = []) -> void:
	challenge = p_challenge
	player = p_player
	match challenge.event:
		&"thrown": _listen_hazards(track, sources, &"car_thrown", _on_car_first)
		&"fireball": _listen_hazards(track, sources, &"fireball_hit", _on_car_first)
		&"animal": _listen_hazards(track, sources, &"animal_hit", _on_car_first)
		&"shove": _listen_hazards(track, sources, &"shoved", _on_car_second)
		&"crush": player.crushed.connect(_on_crushed)
		&"splash": player.splashed.connect(_on_splashed)
		&"traffic_bump": player.bumped.connect(_on_bumped)
		_: push_warning("ChallengeTracker: eveniment necunoscut '%s'" % challenge.event)


## Reusita = niciun eveniment numarat. (Singura regula din 4a.)
func evaluate() -> bool:
	return not failed


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


func _count() -> void:
	events += 1
	if not failed:
		failed = true
		failed_changed.emit(true)
