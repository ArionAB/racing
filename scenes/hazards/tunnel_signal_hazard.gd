@tool
class_name TunnelSignalHazard
extends Node3D
## Semaforul tunelului Homer (Fiordland, brief §2 POI E, §3 „Semaforul
## tunelului"): un singur sens, autocarul vine din fata pe rosu.
##
## REPROIECTARE (22 sep 2026, decizia dezvoltatorului dupa 4 runde esuate de
## OPRIRE completa — vezi `docs/track_briefs/fiordland.md` §3, „optiunea 0"):
## oprirea completa a unei flote de 8 AI la o singura banda a cerut un sistem
## de coada adevarat (urmarire fara scurgere, tie-break, eliberare) — proiect
## de AI, nu de pista. In loc sa se construiasca aia, gimmick-ul devine
## **banda de autocar fara oprire**: tunelul are banda STANGA a autocarului si
## banda DREAPTA a masinilor, mereu. Lampa rosie nu mai inseamna „opreste" —
## inseamna „autocarul e in tunel sau intra in curand", iar decizia
## jucatorului e „depasesc pe stanga ACUM?", nu "astept sau risc". AI-ul
## onest tine strict banda dreapta cat e rosu si drumul intreg pe verde — nu
## se opreste, nu face coada, deci coada (sursa reala a celor 11 treceri pe
## rosu masurate pe ramura de coada) nu mai poate exista.
##
## `mode` alege intre cele doua contracte:
##   LANE (implicit, contractul nou) — AI-ul NU se opreste niciodata; tine
##     banda dreapta cat hazardul e "rosu" (vezi mai jos). Jucatorul e liber
##     sa depaseasca pe stanga oricand, cu riscul ghiontului.
##   STOP (contractul vechi, pastrat pentru compatibilitate cu sondele si cu
##     istoricul — cod „mort" dupa integrare, de curatat atunci): AI-ul
##     franeaza si asteapta la linie pe rosu (`ai_controller.gd`
##     `_signal_red_ahead`/`_signal_queue_gap`). Pastrat neschimbat.
##
## METRONOMUL (tiparul EruptionCycle, dar mai mic si fara grup de sincronizat:
## aici hazardul comanda direct DOI copii ai lui, nu un grup extern) NU s-a
## schimbat intre cele doua moduri — doar CE INSEAMNA "rosu" pentru pilot s-a
## schimbat. Un ceas `_clock` in [0, period) imparte ciclul in trei faze:
##   VERDE   [0, green)                              — lampa verde, tunel gol,
##           autocarul nu intra curand
##   GOLIRE  [green, green + clear_hold)              — lampa rosie (telegraph:
##           autocarul INTRA in <= clear_hold s), autocarul inca ascuns
##   TRANZIT [green + clear_hold, period)             — lampa rosie, autocarul
##           traverseaza tunelul dinspre portalul opus, PE BANDA LUI STANGA
## unde `green = period - red_hold` si `red_hold = clear_hold + CROSS`
## (`CROSS = tunnel_length / bus_speed`, timpul de traversare).
##
## DE CE FAZA DE GOLIRE RAMANE (chiar fara oprire): e telegraph-ul jucatorului
## — rosul se aprinde `clear_hold` secunde INAINTE ca autocarul sa intre in
## tunel, ca o mașina deja angajata pe banda stanga (a depasit chiar inainte
## de rosu) sa aiba timp sa se retraga pe dreapta inainte de intalnire. Fara
## ea, lampa ar anunta pericolul chiar in clipa in care apare — cu ea, brief-ul
## („lampa roșie = autocar în tunel sau intră în ≤ clear_hold s") e literal
## `is_red()`.
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
## CURBA AUTOCARULUI URMARESTE DRUMUL REAL, nu o linie dreapta (fix gasit la
## montarea benzii, 22 sep 2026): `_rebuild_bus_curve` esantioneaza acum
## centrul soselei parintelui [Track] intre linia de oprire si capatul opus
## al tunelului, offsetat lateral cu `bus_lane_offset` — nu doar cele 2 puncte
## de dinainte. MASURAT: pe Track16, o linie dreapta intre cele doua portaluri
## diverge de drumul real cu **pana la ~8 m la mijlocul tunelului** (drumul se
## curbeaza chiar daca lungimea totala aproape coincide cu coarda: 168.9 m
## real vs 167.8 m coarda) — pe un tunel de 8 m cu doua benzi de ~2 m, 8 m de
## deriva ar fi scos autocarul de pe sosea. Fara [Track] parinte (sonde
## izolate), se pastreaza fallback-ul vechi (2 puncte, linie dreapta).
##
## GEOMETRIA TUNELULUI (peretii, coliziunea) NU e aici — asta e doar
## metronomul + lampa + autocarul. Peretii ies din `TerrainPeak` + GLB-ul de
## portal/interior (brief §5.2), ca la Baikal.
##
## Declarare pe pista (.tscn), copil al `Hazarduri` (copil al radacinii de
## tip [Track]), la linia de oprire / portalul de est (frac ~0.61 pe Track16):
##   [node name="SemaforTunel" type="Node3D" parent="Hazarduri"]
##   script = ExtResource("res://scenes/hazards/tunnel_signal_hazard.gd")
##   transform = ...                # la linia de oprire, +Z local spre tunel
##   mode = 1                       # LANE (implicit)
##   period = 47.5
##   clear_hold = 8.0
##   tunnel_length = 169.0
##   bus_speed = 12.5
##   bus_lane_offset = -2.0         # banda STANGA sensului de mers al masinilor
## AI-ul citeste `is_red()` si `mode` direct de pe grupul `AI_GROUP` (vezi
## `ai_controller.gd._signal_red_ahead` / `_signal_keep_right`).

## STOP = contractul vechi (AI franeaza si asteapta la linie pe rosu, cu coada
## pe randuri) — pastrat pentru istoric/sonde, cod „mort" dupa integrare.
## LANE = contractul nou (brief, optiunea 0): AI-ul nu se opreste NICIODATA,
## tine banda dreapta cat e rosu (autocar in tunel sau intra in <= clear_hold
## s), toata latimea pe verde. Vezi antetul clasei.
enum Mode { STOP, LANE }

## Care contract e activ. Implicit LANE — STOP ramane disponibil doar pentru
## sonde de regresie/comparatie, nu pentru pistele noi.
@export var mode: Mode = Mode.LANE

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

## Viteza autocarului prin tunel (m/s). Runda 2 a benzii (dupa verdictul cu
## 18 m/s: nucleul trecea, dar contactele autocar-AI si masinile-cadre pe
## banda stanga pe rosu nu ieseau la zero): 12,5 m/s pe cei 169 m ai Track16 =
## ~13,5 s de traversare — mai lent inadins, ca viteza de INCHIDERE la contact
## sa fie mai mica ("ghiont", nu izbitura) si ca AI-ul sa aiba mai mult timp sa
## ajunga pe banda dreapta inainte sa-l prinda autocarul. Rosul creste automat
## (`red_hold` mai jos), ceea ce e GRATIS acum ca nimeni nu mai asteapta la
## linie — decizia rundei 2, coordonator: "acum avem o parghie noua: nimeni nu
## mai opreste, deci rosul lung e gratis".
## `red_hold` (mai jos) se calculeaza din asta + `clear_hold`, deci schimband
## viteza se schimba automat si durata rosului — rosul trebuie sa acopere
## EXACT golirea + tranzitul, niciodata mai putin (altfel verdele revine cat
## autocarul inca traverseaza).
@export_range(1.0, 30.0, 0.1) var bus_speed: float = 18.0:
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

## Runda 2 a benzii (coordonator): "ejectarile in tunel = veto real". Cand
## ghiontul lui BusHazard (`shove` + `side_accel`, implicit 3.0 / 8.0 — vezi
## bus_hazard.gd) arunca o masina prinsa intre autocar si peretele DREPT
## (peretele spre care nasul oblic o si deflecteaza), impulsul complet o
## ejecta din perete in loc s-o „impinga inapoi". Doar pentru `mode == LANE`:
## contractul de aici e „ghiont, nu distrugere" pe o banda ingusta (4 m),
## unde masina n-are loc de alunecare inainte sa atinga zidul — modul STOP
## (nefolosit azi) pastreaza implicitele lui BusHazard neatinse.
## Negativ = nu suprascrie (foloseste implicitul BusHazard).
@export_range(-1.0, 12.0, 0.5) var bus_shove: float = -1.0
## La fel ca `bus_shove`, pentru acceleratia laterala SUSTINUTA cat masina
## sta in zona de ghiont a autocarului.
@export_range(-1.0, 60.0, 1.0) var bus_side_accel: float = -1.0

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
	# BUG GASIT la montarea benzii (22 sep 2026): `BusHazard.apex_outer_m`
	# implicit 1.0 muta autonom corpul spre EXTERIORUL oricarei curburi
	# (gandit pentru serpentinele Machu Picchu, unde curba desenata de mana e
	# CHIAR banda, si offsetul compenseaza un ac stramt luat "larg"). Aici
	# curba e deja esantionata pe drumul real cu `bus_lane_offset` EXPLICIT
	# (vezi `_rebuild_bus_curve`) — un offset suplimentar de pana la 1 m pe
	# curbura tunelului (Track16 are un cot in prima jumatate) impingea
	# autocarul in afara benzii lui STANGA, spre banda masinilor: contactele
	# repetate pe rosu la frac ~0.62-0.68 (unde tunelul chiar curbeaza) nu
	# erau AI pe banda gresita, erau autocarul insusi deviind. 0 = urmeaza
	# curba esantionata exact.
	_bus.apex_outer_m = 0.0
	# Runda 2 a benzii: ghiont mai bland DOAR pe LANE (vezi doc la
	# bus_shove/bus_side_accel) — modul STOP nu se atinge.
	if mode == Mode.LANE:
		if bus_shove >= 0.0:
			_bus.shove = bus_shove
		if bus_side_accel >= 0.0:
			_bus.side_accel = bus_side_accel
	add_child(_bus)
	_rebuild_bus_curve()
	_sync_bus()
	_bus.shoved.connect(_on_bus_shoved)


## Pe ce banda a tunelului merge autocarul, fata de AXA drumului (m, semn
## local X — acelasi semn ca `TrackRoute.side_at` / `lateral_distance`:
## POZITIV = dreapta SENSULUI de mers al masinilor, NEGATIV = stanga).
##
## Reproiectare (banda de autocar, brief optiunea 0): tunelul de 8 m are banda
## STANGA a autocarului (dinspre masini, adica local X NEGATIV — masurat cu o
## sonda dedicata pe Track16: `_side_at(idx).dot(bus_pos - baked[idx])` a iesit
## pozitiv pentru orice offset > 0, deci "dreapta soselei" e local +X, si
## "banda stanga" cere `bus_lane_offset < 0`) si banda DREAPTA a masinilor
## (`AIController` tinteste local X POZITIV cat e rosu — vezi
## `_signal_keep_right` in ai_controller.gd). -2.0 m centreaza autocarul (3.6 m
## lat) pe jumatatea stanga a unui tunel de 8 m (semilatime 4.0): de la axa,
## banda stanga ocupa [-4.0, 0.0], centrul ei e la -2.0.
##
## Semnul vechi (+1.5, mod STOP) venea din geometria niselor (toate pe dreapta
## soselei) si nu mai are sens in LANE: nisele s-au scos, iar acum contează
## doar sa nu fie pe axa in banda masinilor.
@export_range(-4.0, 4.0, 0.1) var bus_lane_offset: float = -2.0:
	set(value):
		bus_lane_offset = value
		_rebuild_bus_curve()

## Cati metri de drum real intre doua puncte esantionate din centrul soselei
## (vezi `_rebuild_bus_curve`). Mai mic decat `bake_interval`-ul tipic (3.0)
## al pistei, ca autocarul sa nu taie coltul pe curbura tunelului.
const BUS_SAMPLE_STEP_M: float = 2.0

## [Track]-ul ancestor, cautat o data si tinut minte (nu se schimba in timpul
## rularii). Null in afara unei piste (sonde izolate) — `_rebuild_bus_curve`
## cade pe fallback-ul de linie dreapta.
var _track: Track = null
var _track_searched: bool = false

func _find_track() -> Track:
	if _track_searched:
		return _track
	_track_searched = true
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			_track = n as Track
			break
		n = n.get_parent()
	return _track

## Curba pe care circula autocarul: DINSPRE linia de oprire (est, unde sta
## nodul, cu +Z local spre tunel) PANA la capatul opus al tunelului
## (`tunnel_length` mai departe), cu +4 m rezerva dincolo de portalul de vest
## (ascuns acolo intre doua treceri — vezi `bus_hazard.gd`: „in spatele unui
## perete"). BusHazard parcurge curba DINSPRE primul punct SPRE ultimul, deci
## primul punct e capatul de VEST (+ rezerva), ultimul e linia de oprire
## (origine, `Vector3.ZERO`) — autocarul vine din fata catre masini, exact ca
## in modul vechi.
##
## FIX (22 sep 2026, montarea benzii): cu [Track] parinte gasit, esantioneaza
## centrul soselei REALE la `BUS_SAMPLE_STEP_M` interval, offsetat lateral cu
## `bus_lane_offset` prin `TrackRoute.side_at` — nu doar 2 puncte pe o linie
## dreapta intre portaluri. MASURAT pe Track16: o linie dreapta diverge de
## drum cu pana la ~8 m la mijlocul tunelului (curbura reala, desi lungimea
## totala aproape coincide cu coarda) — pe doar 4 m de semilatime de banda,
## 8 m de deriva scotea autocarul de pe sosea cu totul. Fara [Track] (sonde
## izolate), fallback pe cele 2 puncte de dinainte.
func _rebuild_bus_curve() -> void:
	if _bus == null:
		return
	var curve := Curve3D.new()
	var track := _find_track()
	if track == null:
		var x := bus_lane_offset
		curve.add_point(Vector3(x, 0.0, tunnel_length + 4.0))
		curve.add_point(Vector3(x, 0.0, 0.0))
		_bus.curve = curve
		return
	var r := track.route_at(0)
	if r == null or r.baked.is_empty():
		var x2 := bus_lane_offset
		curve.add_point(Vector3(x2, 0.0, tunnel_length + 4.0))
		curve.add_point(Vector3(x2, 0.0, 0.0))
		_bus.curve = curve
		return
	var line_idx: int = track.closest_index_global(global_transform.origin, 0)
	# `bake_interval` e un MAXIM (memoria proiectului: Curve3D indeseste
	# punctele in curbe) — spatierea REALA intre indici poate fi mult sub 3.0 m
	# (masurat pe tunelul Track16: ~2.03 m/index, nu 3.0). Mergem pe DISTANTA
	# ACUMULATA intre baked[i] consecutivi, nu pe un numar de indici presupus
	# din bake_interval — altfel un `steps` calculat cu spatierea gresita
	# se opreste la jumatatea tunelului (masurat: 58 indici la "3 m" acopereau
	# doar 118 m dintr-un tunel de 169 m).
	var n := r.baked.size()
	var idx_west := line_idx
	var acc := 0.0
	while acc < tunnel_length and idx_west - line_idx < n:
		var nxt: int = r.wrap_index(idx_west + 1)
		acc += r.baked[r.wrap_index(idx_west)].distance_to(r.baked[nxt])
		idx_west = idx_west + 1
	var steps: int = idx_west - line_idx
	if OS.get_environment("TUNNEL_SIGNAL_TRACE") == "1":
		print("[tunnel-signal-curve] line_idx=%d steps=%d acc=%.1f n=%d" %
			[line_idx, steps, acc, n])
	# Esantioane DINSPRE vest (mai departe) SPRE est (linia de oprire, capat),
	# ca ordinea punctelor curbei sa ramana "primul = ascuns sus, ultimul =
	# jos la linie" (tiparul PathMover/BusHazard). Un punct din drum la fiecare
	# index (spatierea reala, ~2-3 m) — destul de des ca sa nu taie coltul pe
	# curbura tunelului; `BUS_SAMPLE_STEP_M` nu se mai foloseste ca pas de
	# INDEX (spatierea reala nu e uniforma), ci doar ca prag minim ca sa nu se
	# adauge puncte inutil de dese pe portiuni aproape drepte.
	var samples: Array[Vector3] = []
	var last_added: Vector3 = Vector3.INF
	var i := steps
	while i >= 0:
		var idx: int = r.wrap_index(line_idx + i)
		var center: Vector3 = r.baked[idx]
		var side: Vector3 = r.side_at(idx)
		var world_pt: Vector3 = center + side * bus_lane_offset
		if last_added == Vector3.INF or world_pt.distance_to(last_added) >= BUS_SAMPLE_STEP_M * 0.5 or i == 0:
			samples.append(to_local(world_pt))
			last_added = world_pt
		i -= 1
	# Punctul din urma (capatul de vest + rezerva ascunsa) explicit dincolo de
	# ultimul esantion real, pe aceeasi directie, ca autocarul sa dispara
	# complet inainte de a se ascunde.
	if samples.size() >= 2:
		var last := samples[0]
		var prev := samples[1]
		var dir := (last - prev)
		if dir.length_squared() > 0.0001:
			samples.insert(0, last + dir.normalized() * 4.0)
	for p in samples:
		curve.add_point(p)
	if curve.point_count < 2:
		var x3 := bus_lane_offset
		curve.add_point(Vector3(x3, 0.0, tunnel_length + 4.0))
		curve.add_point(Vector3(x3, 0.0, 0.0))
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
	if OS.get_environment("SIGNAL_LANE_TRACE") == "1":
		print("[bus-shove-debug] bus_dist=%.1f bus_pos=%s car_pos=%s" %
			[_bus_ref.distance(), _bus_ref.body().global_transform.origin,
				car.global_position])
	bus_hit.emit(car)


## Autocarul construit (pentru sonde: pozitie, ascuns/vizibil, coliziune).
func bus() -> BusHazard:
	return _bus
