@tool
class_name TunnelSignalHazard
extends Node3D
## Semaforul tunelului Homer (Fiordland, brief §2 POI E, §3 „Semaforul
## tunelului"): un singur sens, autocarul vine din fata pe rosu. Prima
## „oprire" din joc CU IESIRE — poti trece pe rosu, in loc sa astepti.
##
## METRONOMUL (tiparul EruptionCycle, dar mai mic si fara grup de sincronizat:
## aici hazardul comanda direct DOI copii ai lui, nu un grup extern): un ceas
## `_clock` in [0, period) imparte ciclul in trei faze:
##   VERDE   [0, green)                              — lampa verde, tunel liber
##   GOLIRE  [green, green + clear_hold)              — lampa rosie, tunel INCA
##           liber (autocarul e ascuns), fereastra in care o masina intrata pe
##           verde in ultima clipa apuca sa iasa pe partea cealalta
##   TRANZIT [green + clear_hold, period)             — lampa rosie, autocarul
##           traverseaza tunelul dinspre portalul opus
## unde `green = period - red_hold` si `red_hold = clear_hold + CROSS`
## (`CROSS = tunnel_length / bus_speed`, timpul de traversare).
##
## DE CE FAZA DE GOLIRE (runda 2 de tuning, dupa sonda cu 43-72 contacte pe
## 150 s): fara ea, autocarul pornea din portalul opus CHIAR la inceputul
## rosului — dar un AI/jucator care intrase pe verde in ultima secunda mai are
## nevoie de `tunnel_length / viteza` (6-14 s la 25-11 m/s) ca sa strabata
## tunelul. Cu `clear_hold` prea mic (sau zero), cele doua se intalneau
## GARANTAT la fiecare ciclu, la mijlocul tunelului — de-aia sonda arata 5-9
## contacte pe minut, nu evenimente rare. `clear_hold` e timpul minim in care
## tunelul chiar se goleste inainte sa intre autocarul: cine trece pe rosu
## IMEDIAT si e rapid (150 m in <= clear_hold s) iese pe partea opusa inainte
## ca autocarul sa fi pornit macar. Trecerea pe rosu devine fereastra de
## timing (cate secunde ai, nu daca ai noroc), nu pariu.
##
## La intrarea in ROSU (inceputul golirii) se aprinde lampa rosie; autocarul
## ramane ASCUNS pana la inceputul tranzitului (`green + clear_hold`), cand
## porneste (un [BusHazard] pe traseul liniar al tunelului, in fata masinilor,
## deci cu curba desenata DINSPRE capatul de vest SPRE cel de est — vezi
## `_build_bus_curve`); la intrarea in verde, lampa verde si autocarul se
## ascunde (colizor stins, invizibil) pana la urmatorul ciclu.
##
## DE CE BusHazard, nu un PathMover nou: BusHazard aduce deja botul deflector
## oblic (`nose_angle_deg`, `nose_side`) care transforma un contact frontal in
## alunecare laterala CU MASA, fara nicio cifra de ghiont scrisa de mana — e
## exact „ghiont inapoi si in perete, nu distrugere" cerut de brief. Aduce si
## ciclul ascuns-la-capat (colizor stins + invizibil intre treceri), care
## rezolva singur memoria `corp-cinematic-aparut-in-masina`: un corp cinematic
## care apare LANGA o masina ii da o viteza uriasa la depenetrare: autocarul
## trebuie sa fie stins cand „sare" de la capatul de jos (est, unde iese din
## tunel) inapoi la capatul de sus (vest, de unde porneste urmatoarea trecere)
## — teleportarea se intampla STRICT cat e ascuns, la fel ca la serpentinele
## din Machu Picchu.
##
## `period` al lui BusHazard e ciclul LUI (o coborare + timpul ascuns), diferit
## de `period`-ul semaforului (ciclul verde+rosu): se sincronizeaza scriind
## direct `bus.period = period` si fazand coborarea lui sa inceapa exact cand
## incepe rosul (vezi `_sync_bus`), nu prin grupul `EruptionCycle` (acela
## presupune mai multe hazarde de acelasi fel; aici e un singur autocar legat
## de UN semafor, mai simplu sa-l tina direct).
##
## GEOMETRIA TUNELULUI (peretii, nisele, coliziunea) NU e aici — asta e doar
## metronomul + lampa + autocarul. Peretii ies din `TerrainPeak` + GLB-ul de
## portal/interior (brief §5.2), ca la Baikal.
##
## Declarare pe pista (.tscn), copil al radacinii, la portalul de est (frac
## ~0.50 din brief):
##   [node name="SemaforTunel" type="Node3D" parent="."]
##   script = ExtResource("res://scenes/hazards/tunnel_signal_hazard.gd")
##   transform = ...                # la linia de oprire, botul spre tunel (-Z)
##   period = 40.0
##   clear_hold = 6.0
##   tunnel_length = 150.0
##   bus_speed = 12.5
## AI-ul citeste `is_red()` prin [HazardMarker] `Kind.SIGNAL` pus pe waypoint,
## la linia de oprire (vezi `ai_controller.gd._signal_stop_ahead`).

## Ciclul complet (verde + rosu), secunde. Runda 2: 40 s = 22 verde + 18 rosu
## (6 golire + 12 tranzit), fata de 34 s = 22 + 12 dinainte de faza de golire.
@export_range(10.0, 120.0, 0.5) var period: float = 40.0:
	set(value):
		period = maxf(value, 4.0)
		_sync_bus()

## Cat tine faza de GOLIRE (lampa deja rosie, tunelul INCA liber, autocarul
## inca ascuns) inainte ca autocarul sa porneasca din portalul opus. Runda 2
## (a doua sonda, dupa 43-72 contacte/150s cu rosul = doar tranzitul): fara
## faza asta, o masina care intra pe verde in ultima clipa si autocarul care
## tocmai a pornit se intalneau GARANTAT la mijlocul tunelului, la fiecare
## ciclu. Cine trece pe rosu imediat si e rapid (150 m in <= clear_hold s =
## 25 m/s la 6 s) iese pe partea opusa inainte ca autocarul sa fi pornit
## macar; cine ezita il intalneste si are nisele. Vezi `cross_time()` si
## `red_hold` (calculat, nu mai e export propriu — vezi mai jos).
@export_range(0.0, 30.0, 0.5) var clear_hold: float = 6.0:
	set(value):
		clear_hold = maxf(value, 0.0)
		_sync_bus()

## Lungimea tunelului (m), de la linia de oprire (portalul de est, +45 m in
## brief) pana la iesirea de vest (+27 m). Autocarul parcurge distanta asta.
@export_range(20.0, 400.0, 1.0) var tunnel_length: float = 150.0:
	set(value):
		tunnel_length = maxf(value, 5.0)
		_rebuild_bus_curve()
		_sync_bus()

## Viteza autocarului prin tunel (m/s). Brief: 150 m in 12 s =~ 12.5 m/s.
## `red_hold` (mai jos) se calculeaza din asta + `clear_hold`, deci schimband
## viteza se schimba automat si durata rosului — decizia rundei 2: rosul
## trebuie sa acopere EXACT golirea + tranzitul, niciodata mai putin (altfel
## verdele revine cat autocarul inca traverseaza).
@export_range(1.0, 30.0, 0.1) var bus_speed: float = 12.5:
	set(value):
		bus_speed = maxf(value, 0.1)
		_sync_bus()

## Latimea autocarului (m). Brief: 3,6 m pe un tunel de 7 m (3,5 semilatime).
@export var bus_width: float = 3.6:
	set(value):
		bus_width = value
		_rebuild_bus_curve()
## Lungimea autocarului (m).
@export var bus_length: float = 8.5:
	set(value):
		bus_length = value
		_rebuild_bus_curve()

## Incotro deflecteaza botul autocarului la contact frontal: +1 = dreapta LUI
## (care e stanga masinii care vine din fata pe banda ei) — brief: „ghiont
## inapoi si in perete", nu o parte anume; -1 disponibil daca geometria
## niselor (toate pe dreapta soselei, brief §2E) cere alta parte.
@export_enum("Dreapta:1", "Stanga:-1") var nose_side: int = 1

## Cat de devreme se aprind farurile pe pereti (billboard-uri emisive, brief:
## „3 s inainte sa apara"), fata de PORNIREA autocarului. Doar semnal —
## geometria farurilor o pune pista (brief §2E); aici doar semnalul
## `headlights_on` ca sa se poata agata orice vizual.
@export_range(0.0, 10.0, 0.1) var headlight_lead_s: float = 3.0

## Semaforul insusi. Daca ramane null, se construieste unul implicit
## (vertical, rosu sus) la `_ready` — vezi antetul lui HazardLamp: „ROSUL SUS
## ca orice semafor".
@export var lamp: HazardLamp

## Cat de mult inainte de sfarsitul rosului se emite `signal_changed(false)`
## (verde) — 0 = exact la tranzitie. Exista pentru sonde/reglaj fin, dar
## brief-ul nu cere avans: implicit 0.
const GREEN_SLOT: int = 0
const RED_SLOT: int = 2 # Palette.KERB_RED, ca in HazardLamp.slots implicit

## Grupul din care AI-ul citeste semafoarele (acelasi tipar ca
## SlidingHazard.DOOR_GROUP / RotatingSpanHazard.AI_GROUP): pilotul intreaba
## `blocks_in()` cu timpul lui de sosire si opreste la linie daca va fi rosu.
const AI_GROUP: StringName = &"tunnel_signals"
## Cat de departe (m) incepe raza de decizie a AI-ului fata de linia de
## oprire — trebuie sa fie mai mult decat `red_hold`-ul cel mai lung ori de
## viteza cea mai mica de croaziera a AI-ului, ca decizia sa nu se rasuceasca
## intre "vine verde" si "vine rosu" chiar inainte de sosire. 130 m la ~11
## m/s (viteza minima realista intr-o urcare de 12%) = ~12 s, mai mult decat
## orice `red_hold` rezonabil (18 s implicit: 6 golire + 12 tranzit).
const AI_REACH_M: float = 130.0
## Unde se opreste botul masinii fata de linia de oprire (originea nodului),
## masurat pe axa -Z (spre tunel) — inaintea axei, ca sa nu intre in cadrul
## lampii/portalului.
const AI_STOP_BACK_M: float = 3.0

## Se emite la fiecare tranzitie (verde -> rosu sau rosu -> verde).
signal signal_changed(red: bool)
## Farurile autocarului ar trebui aprinse pe peretii tunelului (billboard,
## geometrie de pista): emis `headlight_lead_s` inainte sa porneasca.
signal headlights_on()
## O masina a fost lovita frontal de autocar (ghiontul BusHazard.shoved,
## retransmis cu semnatura simpla pentru sonde/HUD).
signal bus_hit(car: Car)

var _bus: BusHazard
var _clock: float = 0.0
var _was_red: bool = false
var _headlight_fired: bool = false


func _ready() -> void:
	add_to_group(AI_GROUP)
	if lamp == null:
		lamp = HazardLamp.new()
		lamp.name = "Lampa"
		lamp.vertical = true
		add_child(lamp)
	if _bus == null:
		_build_bus.call_deferred()
	# Pornim in verde (fractia initiala a ciclului = 0), lampa verde aprinsa.
	lamp.set_lit(GREEN_SLOT)


func _build_bus() -> void:
	_bus = BusHazard.new()
	_bus.name = "Autocar"
	# Fara model: cutia galbena a BusHazard e inlocuita mai tarziu de
	# `coach_fiordland` (brief §5.2, reuse mesh Autobuz din garaj) — se
	# seteaza din pista, prin `bus.model`, dupa Regenerate.
	_bus.body_size = Vector3(bus_width, 3.0, bus_length)
	_bus.nose_side = nose_side
	_bus.nose_angle_deg = 20.0
	add_child(_bus)
	_rebuild_bus_curve()
	_sync_bus()
	_bus.shoved.connect(_on_bus_shoved)


## Curba pe care coboara autocarul: DINSPRE portalul de vest (capatul jos in
## vocabularul BusHazard, unde sta ascuns intre doua treceri) SPRE linia de
## oprire de la est (unde „ajunge jos" — aici, spre jucatori). Local, -Z e
## sensul soselei (spre tunel); autocarul vine din fata, deci pe +Z local al
## nodului semaforului (care sta la linia de oprire, cu fata spre tunel).
##
## Primul punct (start ascuns) e pus DINCOLO de iesirea de vest, in afara
## drumului vizibil (memoria bus_hazard.gd: „in spatele unui perete" — aici,
## dincolo de portal, unde tunelul oricum il ascunde de camera).
func _rebuild_bus_curve() -> void:
	if _bus == null:
		return
	var curve := Curve3D.new()
	# +Z = spre tunel (vezi antet); 4 m rezerva dincolo de portalul de vest,
	# ca autocarul sa dispara complet inainte sa se ascunda.
	curve.add_point(Vector3(0.0, 0.0, tunnel_length + 4.0))
	curve.add_point(Vector3(0.0, 0.0, 0.0))
	_bus.curve = curve


## Timpul de traversare a tunelului la `bus_speed` (s). Runda 2: rosul
## trebuie sa acopere EXACT `clear_hold + cross_time()`, nicio secunda mai
## putin — vezi `red_hold`.
func cross_time() -> float:
	return tunnel_length / maxf(bus_speed, 0.1)


## Cat tine rosul (s), CALCULAT, nu mai e export propriu (runda 2): golirea
## plus tranzitul. Un `red_hold` scris de mana putea sa nu incapa deasupra
## celor doua faze (rosul se termina inainte ca autocarul sa fi iesit) —
## calculat, contractul „rosul acopera tot ciclul autocarului" nu se poate
## rupe din Inspector.
func red_hold() -> float:
	return clear_hold + cross_time()


## Cat tine verdele (s), CALCULAT: tot ce ramane din `period` dupa rosu.
func green_hold() -> float:
	return maxf(period - red_hold(), 1.0)


## Sincronizeaza ceasul lui BusHazard cu al nostru: `period` al lui = al
## nostru (asa `_advance` din BusHazard calculeaza corect cat sta ascuns).
##
## `phase` NU rezolva "porneste ascuns": in BusHazard, `phase` e doar punctul
## de START pe curba DE COBORARE (`_dist = phase * length` la primul tick,
## cu `_hidden` implicit fals) — folosit pentru figuranti care trebuie sa
## arate "deja in tranzit" la incarcarea scenei, nu pentru un ciclu care
## trebuie sa inceapa ASCUNS. Masurat: cu `phase = (period-red_hold)/period`
## autocarul aparea VIZIBIL si pe jumatate de tunel de la primul cadru,
## inainte de primul rosu (t=1-4s in sonda) — exact contactele "aparut langa
## masina" pe care brief-ul le interzice explicit.
##
## Fix: pornim explicit ASCUNS (acelasi apel pe care BusHazard si-l face
## singur la finalul fiecarei coborari — vezi `_hide()`), cu exact timpul
## ramas pana la INCEPUTUL TRANZITULUI (`green_hold() + clear_hold`), nu pana
## la inceputul rosului — runda 2: autocarul nu porneste la primul rosu, ci
## dupa faza de golire. Ciclul se auto-intretine corect dupa aceea:
## `_hide(seconds)` seteaza `_hide_left`, iar `_advance` il numara la fiecare
## tick si cheama `_show()` cand ajunge la 0.
func _sync_bus() -> void:
	if _bus == null:
		return
	_bus.period = period
	_bus.speed = bus_speed
	_bus.phase = 0.0
	_force_hidden_until_transit()


## Forteaza autocarul in starea ASCUNS, cu timpul ramas pana la urmatorul
## inceput de TRANZIT (nu de rosu — vezi antetul `_sync_bus`) — apelat o data
## la construire (inainte ca `_clock` sa fi avansat) si e sigur de rechemat
## oricand (ex. dupa o schimbare de `clear_hold`/`bus_speed` din Inspector).
func _force_hidden_until_transit() -> void:
	if _bus == null:
		return
	var until_transit := green_hold() + clear_hold - _clock
	if until_transit < 0.0:
		until_transit = fposmod(until_transit, period)
	_bus.call("_hide", maxf(until_transit, 0.05))


## Rosu acum (lampa)? Citit de AI (HazardMarker.Kind.SIGNAL) si de sonde.
## ADEVARAT pe toata durata rosului — golire SI tranzit — fiindca lampa nu
## deosebeste cele doua faze (jucatorul nu vede „cat mai am pana pleaca
## autocarul", vede doar rosu/verde, ca la orice semafor real).
func is_red() -> bool:
	return _clock >= green_hold()


## Tranzitul chiar in curs (autocarul traverseaza)? Pentru sonde/diagnostic —
## AI-ul NU foloseste asta (ar fi un bit in plus fata de ce vede un om).
func is_transit() -> bool:
	return _clock >= green_hold() + clear_hold


## Secunde ramase pana la verde (0 daca deja verde). Pentru AI: cat sa astepte.
func red_seconds_left() -> float:
	if not is_red():
		return 0.0
	return period - _clock


## Secunde ramase pana la ROSU (0 daca deja rosu). Runda 2, punctul 2: un AI
## care e la linie PE VERDE nu intreaba doar „e liber ACUM", ci „am timp sa
## si IES pe partea cealalta inainte sa vina rosul" — vezi
## `ai_controller.gd._signal_red_ahead`, care compara asta cu timpul de
## traversare la viteza proprie.
func green_seconds_left() -> float:
	if is_red():
		return 0.0
	return green_hold() - _clock


## Va fi ROSU peste `seconds`? Aceeasi forma ca SlidingHazard.door_blocks_in,
## ca AIController sa poata trata semaforul cu exact acelasi tipar de
## intrebare ("daca ajung acolo peste X secunde, gasesc drumul liber?").
func blocks_in(seconds: float) -> bool:
	return fposmod(_clock + seconds, period) >= green_hold()


## Unde se opreste un AI care asteapta (linia de oprire, cu marja inapoi).
## Pentru AI, ca la SlidingHazard.ai_decision_point / RotatingSpanHazard.
func ai_decision_point() -> Vector3:
	return to_global(Vector3(0.0, 0.0, -AI_STOP_BACK_M))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock = fposmod(_clock + delta, period)
	var red := is_red()
	if red != _was_red:
		_was_red = red
		lamp.set_lit(RED_SLOT if red else GREEN_SLOT)
		signal_changed.emit(red)
		if not red:
			_headlight_fired = false
	if red and not _headlight_fired:
		# Farurile se aprind cu `headlight_lead_s` inainte ca autocarul sa
		# PORNEASCA — asta e inceputul TRANZITULUI (`green_hold() + clear_hold`),
		# nu inceputul rosului (runda 2: autocarul asteapta `clear_hold` dupa
		# ce lampa a trecut pe rosu, inainte sa porneasca).
		var transit_start := green_hold() + clear_hold
		if _clock >= transit_start - headlight_lead_s:
			_headlight_fired = true
			headlights_on.emit()


func _on_bus_shoved(_bus_ref: BusHazard, car: Car) -> void:
	bus_hit.emit(car)


## Autocarul construit (pentru sonde: pozitie, ascuns/vizibil, coliziune).
func bus() -> BusHazard:
	return _bus
