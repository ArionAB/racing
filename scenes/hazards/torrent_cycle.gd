class_name TorrentCycle
extends Node3D
## TORENTUL IN PULSURI (Fiordland, Track16, gimmick-ul scurtaturii
## `ScurtaturaChasm`). Drumul vechi din padure trece pe sub un jgheab de
## stanca din care un lac suspendat se goleste in valuri: cascada nu e
## constanta, e un CICLU (~14 s) cu trei faze:
##
##   CALM       [0, period-telegraph-surge)   fir subtire, teatru, fara forta
##   TELEGRAPH  [..., period-surge)           spray-ul creste, huruit — anunt
##   SURGE      [period-surge, period)        perdeaua PLINA, forta+franare+albire
##
## Decizia jucatorului se ia la furca scurtaturii (~80 m inainte de perdea,
## brief): citeste FAZA (vizibila — perdeaua e mai groasa/mai alba in
## telegraph, plina in surge), distanta si viteza proprie, si alege sa intre
## (arzand turbo ca sa treaca inaintea pulsului) sau sa ia podetul (bucla
## principala). AI-ul primeste EXACT acelasi calcul, niciun bit in plus —
## principiul 5 din CLAUDE.md, "AI onest".
##
## [b]De ce un nod separat, nu logica direct pe WaterfallHazard.[/b] Fizica
## perdelei (forta/franare/albire calibrate la Stirling, `force_accel=48`,
## `drag=0.25`) e deja corecta si testata — a se vedea antetul
## `WaterfallHazard`. Ce lipseste e METRONOMUL: pulsul on/off si pozitionarea
## pe banda scurtaturii. Acelasi tipar ca [EruptionCycle]/[RainCycle]: un nod
## mic care bate ritmul, construind intern hazardul de care are nevoie (ca
## [TunnelSignalHazard], care isi construieste singur `BusHazard`-ul).
##
## [b]De ce comutatorul `set_physics_enabled` pe WaterfallHazard, nu doar
## `modulate.a = 0` in CALM.[/b] `WaterfallHazard._physics_process` aplica
## `drag`-ul (franarea orizontala) de cate ori `modulate.a > 0.001` — un fir
## SUBTIRE de teatru (`calm_intensity` > 0) ar franea si ar albi masina in
## CALM, desi brief-ul cere fizica NUMAI in puls. De-asta hazardul primeste
## un comutator separat (vezi `waterfall_hazard.gd`): vizualul (`modulate`)
## si fizica (`set_physics_enabled`) se comanda independent — fir vizibil tot
## timpul, forta doar in SURGE.
##
## [b]De ce se pozitioneaza SINGUR, din ruta coapta.[/b] Alta echipa
## redeseneaza curba scurtaturii in paralel (brief: furca se misca intre
## 0.334 si 0.481 in timp ce se lucreaza la ea). Un `Vector3` scris de mana
## ar iesi de pe banda la urmatoarea redesenare. `branch_frac` e o FRACTIE
## din lungimea rutei 1 — pozitia reala se recalculeaza din
## `track.route_at(branch_index).baked` la construire, deci supravietuieste
## oricarei redesenari a curbei (pana la urmatorul `Regenerate`, care
## reconstruieste si pe noi — vezi `_ready`/`call_deferred`, acelasi tipar ca
## `RainCycle._collect`/`TunnelSignalHazard._build_bus`).
##
## [b]Ordinea de construictie a pistei.[/b] Rutele (`track.routes`) apar DUPA
## `rebuild()`-ul pistei, care ruleaza in `_ready`-ul EI — inaintea copiilor
## in ordinea Godot (parintele isi termina `_ready` dupa ce copiii au pornit
## `_ready`, dar `Track._ready` apeleaza `rebuild()` explicit, sincron,
## inainte de a reveni). Totusi, la fel ca `RainCycle`/`EruptionCycle`, nu
## presupunem ordinea exacta: `_ready` amana constructia cu
## `call_deferred`, si daca `route_at(branch_index)` e tot null (scena
## instantiata izolat, fara [Track] parinte — sonde), se reincearca la
## fiecare cadru pana apare, in loc sa pice silentios.
##
## [b]Ploaia strange fereastra, fara cod special.[/b] `rain_factor`-ul
## perdelei se seteaza in fiecare cadru din `RainCycle.rain_factor` (citit
## prin grupul `rain_cycle`, la fel ca `WaterfallHazard.rain_factor` e citit
## direct — hazardul nu stie CINE il comanda). Durata pulsului
## (`surge * lerp(1, rain_surge_factor, factor)`) creste odata cu ploaia:
## pulsul e mai lung, deci fereastra de CALM e mai scurta — asta e tot ce
## trebuie, ploaia nu adauga nicio ramura noua de decizie.
##
## [b]`start_clock`.[/b] Vezi exportul mai jos: valoarea aleasa evita sa puna
## SURGE exact la prima trecere a plutonului (aceeasi capcana descrisa in
## `TunnelSignalHazard.first_green_bonus_s` — un aliniament de faza intre
## ceasul hazardului si viteza tipica de start ar fi masurat gresit "AI-ul
## intra mereu in puls" cand de fapt e coincidenta primului ciclu).
##
## [b]API pentru AI si sonde[/b] — vezi sectiunea de la finalul fisierului:
## `phase()`, `is_surge()`, `seconds_to_surge()`, `blocks_in(seconds)`,
## `ai_decision_point()`, `curtain_position()`, `hazard()`,
## `force_clock(t)`/`resume_clock()`.

## Grupul din care AI-ul si sondele gasesc torentele de pe pista (acelasi
## tipar ca TunnelSignalHazard.AI_GROUP / SlidingHazard.DOOR_GROUP).
const AI_GROUP: StringName = &"torrents"

@export_group("Ciclul")
## Durata unui ciclu complet (s). Brief: ~14 s = 7 calm + 3 anunt + 4 puls.
@export_range(4.0, 60.0, 0.5) var period: float = 14.0
## Cat tine ANUNTUL (spray-ul creste, perdeaua se ingroasa vizibil, huruit)
## imediat inainte de puls. Brief: 3 s.
@export_range(0.0, 20.0, 0.5) var telegraph: float = 3.0
## Cat tine PULSUL (perdea plina, forta+franare+albire active). Brief: 4 s.
@export_range(0.5, 20.0, 0.5) var surge: float = 4.0
## Punctul din ciclu (s) la care porneste ceasul. Vezi antetul clasei: se
## alege explicit ca SA NU puna un SURGE chiar la prima trecere a plutonului
## (aceeasi capcana ca `TunnelSignalHazard.first_green_bonus_s`, dar aici
## rezolvata dinainte, prin faza de start, nu printr-un timer de gratie
## separat — nu exista un "prim ciclu vizibil de la load" de protejat, ca la
## autocarul care trebuie sa apara ascuns: perdeaua e mereu vizibila, doar
## fizica ei comuta). Vezi `_ready` pentru valoarea calculata si motivatia
## numerica exacta.
@export_range(0.0, 60.0, 0.5) var start_clock: float = 0.0

@export_group("Pozitia pe banda")
## Ce ruta a pistei duce prin torent (`Track.route_at(branch_index)`).
## Implicit 1 = prima scurtatura (`ScurtaturaChasm` pe Track16).
@export var branch_index: int = 1
## Unde pe banda cade perdeaua, ca fractie din lungimea rutei `branch_index`
## (0 = capul de intrare, 1 = capul de iesire). 0.5 = la mijloc.
@export_range(0.0, 1.0, 0.01) var branch_frac: float = 0.5

@export_group("Perdeaua")
## Lungimea perdelei de-a lungul benzii (m) — vezi WaterfallHazard.length.
@export_range(4.0, 60.0, 0.5) var length: float = 20.0
## Latimea perdelei (m). -1 = latimea benzii (2x branch_half_width, ca in
## antetul TrackBranch) + 2 m de rezerva pe fiecare margine, calculata la
## constructie din `TrackRoute.half_width` a rutei — nu scrisa de mana, ca sa
## acopere banda oricat de late/inguste ar redesena-o cealalta echipa.
@export_range(-1.0, 40.0, 0.5) var thickness: float = -1.0
@export_range(2.0, 40.0, 0.5) var visual_height: float = 14.0

@export_group("Forta (SURGE, calibrat la Stirling)")
## Acceleratia in jos in puls — vezi WaterfallHazard.force_accel. Brief:
## exact fizica lui Stirling, 48.
@export_range(0.0, 60.0, 0.5) var force_accel: float = 48.0
## Franarea orizontala in puls — vezi WaterfallHazard.drag.
##
## NU 0.25 ca la Stirling. Acolo drag-ul mic a fost ales fiindca masinile
## grele stateau SECUNDE sub o perdea de 30 m cu forta constanta (bucla
## pozitiva descrisa in WaterfallHazard). Aici perdeaua e un PULS de 20 m pe
## care il traversezi in sub o secunda, iar rostul lui e RISCUL scurtaturii:
## pulsul trebuie sa coste MAI MULT decat castiga coarda, altfel nu e o
## decizie. Doua masuratori, in ordine:
##
## 1. drum drept, 25 m/s (`ProbeFiordTorent --only=b --car=X --drag=D`):
##      drag 0.25: Taxi -4%, Politia -2%, Autobuz -19%   (nu se simte)
##      drag 0.6 : Taxi -26%, Politia -23%, Autobuz -42%
##      drag 1.0 : Taxi -46%, Politia -44%, Autobuz -62%
##      drag 1.5 : Taxi -64%, Politia -62%, Autobuz -75%
## 2. pe pista, sonda risc/recompensa (`ProbeFiordScurtatura --torrent=surge`,
##    fata de bucla, uscat; in liniste toate castiga +0,9..+1,4 s):
##      drag 1.0 : Politia +0,05  Autobuz -0,75  Muscle +0,28  Taxi +0,07
##      drag 1.5 : Politia -0,57  Autobuz -1,70  Muscle -0,37  Taxi -0,55
##      drag 2.0 : Politia -1,17  Autobuz -2,63  Muscle -1,08  Taxi -1,20  <- ales
## La 1.0 pulsul doar ANULEAZA castigul (net ~0): riscul nu exista. La 2.0
## pulsul prins gresit te lasa cu 1-2,6 s in urma fata de podet, iar pulsul
## evitat iti da +1..+1,4 s — o balansoare de 2-4 s, asta e decizia. Forta
## in jos ramane cea de la Stirling (apasarea pe suspensie e identitate per
## masina). Reglaj de volan: daca la joc pulsul pare zid, 1.5 e treapta de
## dedesubt (tabelul de mai sus), nu 1.0.
@export_range(0.0, 3.0, 0.05) var drag: float = 2.0
## In ploaie, pulsul e cu atat mai GREU (brief: rain_factor al perdelei
## 1.3) — trecut direct catre WaterfallHazard.rain_factor in fiecare cadru.
@export_range(1.0, 2.0, 0.01) var rain_surge_factor_force: float = 1.3
## In ploaie, pulsul e cu atat mai LUNG (brief: ×1.5) — multiplica `surge`
## cat timp `RainCycle.rain_factor` > 0, interpolat liniar cu el.
@export_range(1.0, 3.0, 0.05) var rain_surge_factor: float = 1.5

@export_group("Vizual")
## Intensitatea vizuala (`WaterfallVisual.set_intensity`, prin
## `WaterfallHazard.modulate.a`) in CALM — fir subtire, teatru, brief: „fir
## subtire" pe 7 s. Nu 0: cascada nu dispare intre pulsuri, doar se ingusteaza.
@export_range(0.0, 1.0, 0.01) var calm_intensity: float = 0.12
## Intensitatea in TELEGRAPH — spray-ul creste, perdeaua se ingroasa vizibil.
@export_range(0.0, 1.0, 0.01) var telegraph_intensity: float = 0.45
## Intensitatea in SURGE — perdea plina.
const SURGE_INTENSITY: float = 1.0

## Fazele ciclului. Public, ca AI-ul si sondele sa citeasca exact ce vede si
## un om — nicio informatie suplimentara.
enum Phase { CALM, TELEGRAPH, SURGE }

var _hazard: WaterfallHazard = null
var _track: Track = null
var _track_searched: bool = false
var _rain_cycle: Node = null
var _rain_searched: bool = false
var _clock: float = 0.0
var _placed: bool = false
## TODO(sunet): scripts/autoload/audio_manager.gd are `avalanche_rumble` (un
## huruit continuu de tip "roca in miscare") si `wave_wash`/`splash" pentru
## apa — niciunul e un one-shot "cascada isi ADUNA forta" (anuntul de aici
## e o CRESTERE, nu un impact). Cel mai apropiat e `avalanche_rumble`, dar
## e deja folosit ca loop de alt hazard (avalansa Alpilor) si a-l porni aici
## in plus ar dubla sursele sonore fara sa fie clar ca acelasi sfx inseamna
## doua lucruri diferite pe piste diferite. Nu s-a adaugat un asset nou
## (interzis fara cerere explicita) — cand exista un sfx dedicat de tip
## "spray crescand", se porneste in `_enter_telegraph()` prin
## `AudioManager.play_sfx(&"nume", pitch)`, acelasi tipar ca EruptionCycle.


func _ready() -> void:
	set_process(false)
	set_physics_process(not Engine.is_editor_hint())
	# `start_clock` implicit (0.0 exportat, dar calculat aici pentru pistele
	# care nu-l suprascriu explicit din .tscn): pornim la jumatatea fazei
	# CALM. La un ciclu de 14 s (7 calm + 3 anunt + 4 puls), pluton-ul
	# tipic (rocket start, croaziera ~20-25 m/s) ajunge la furca scurtaturii
	# in primele ~15-25 s de cursa — suficient de aproape de UN ciclu
	# complet ca un start la faza gresita (ceas=0, chiar la marginea
	# CALM/urmatorul ciclu) sa fi aliniat SURGE cu prima trecere la fel de
	# usor cum ar fi evitat-o. Pornind la jumatatea CALM (period*0.25 —
	# in mijlocul ferestrei de 7 s, nu la marginea ei), prima trecere are
	# maxim de fereastra CALM inaintea ei indiferent de viteza exacta de
	# start, iar ciclurile URMATOARE (plutonul deja imprastiat pe pista)
	# nu mai depind de asta — exact argumentul din
	# TunnelSignalHazard.first_green_bonus_s, aplicat static (fara timer de
	# gratie: aici nu exista un "autocar ascuns" de sincronizat, doar un
	# ceas liniar).
	if start_clock <= 0.0:
		_clock = period * 0.25
	else:
		_clock = fposmod(start_clock, period)
	add_to_group(AI_GROUP)
	_place.call_deferred()


func _place() -> void:
	if not is_inside_tree():
		return
	var track := _find_track()
	if track == null or track.routes.size() <= branch_index:
		# Fara [Track] parinte, sau ruta inca nu exista (Regenerate in curs):
		# reincercam la cadrul urmator, in loc sa picam silentios — acelasi
		# motiv ca RainCycle._collect/TunnelSignalHazard._build_bus, dar cu
		# retry explicit fiindca aici nu avem garantia unui singur
		# call_deferred (rutele pot inca sa nu existe la primul).
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_place, CONNECT_ONE_SHOT)
		return
	var route := track.route_at(branch_index)
	if route == null or route.baked.is_empty():
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_place, CONNECT_ONE_SHOT)
		return
	var n := route.baked.size()
	var idx := clampi(int(round(branch_frac * float(n - 1))), 0, n - 1)
	var idx_next := mini(idx + 1, n - 1)
	if idx_next == idx:
		idx_next = maxi(idx - 1, 0)
	var pos := route.baked[idx]
	var dir := (route.baked[idx_next] - route.baked[mini(idx, idx_next)])
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	if idx_next < idx:
		dir = -dir
	global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos)
	var eff_thickness := thickness
	if eff_thickness < 0.0:
		eff_thickness = route.half_width * 2.0 + 2.0
	_build_hazard(eff_thickness)
	_placed = true


func _build_hazard(eff_thickness: float) -> void:
	if _hazard != null and is_instance_valid(_hazard):
		_hazard.queue_free()
	_hazard = WaterfallHazard.new()
	_hazard.name = "Perdea"
	_hazard.length = length
	_hazard.thickness = eff_thickness
	_hazard.visual_height = visual_height
	_hazard.force_accel = force_accel
	_hazard.drag = drag
	_hazard.rain_extra_thickness = 0.0 # torentul isi tine singur latimea din banda
	add_child(_hazard)
	# Perdeaua NU e in "rain_falls" (RainCycle ar stinge-o pe uscat — vezi
	# antetul WaterfallHazard §"Fade-ul de ploaie") — torentul e vizibil in
	# orice vreme, doar mai greu in ploaie. `modulate` se comanda de aici.
	_hazard.modulate = Color(1.0, 1.0, 1.0, calm_intensity)
	_hazard.call("set_physics_enabled", false)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not _placed:
		return
	var rain_factor := _rain_factor()
	var surge_now := surge * lerpf(1.0, rain_surge_factor, rain_factor)
	var cycle_len := period # perioada ramane fixa; doar durata SURGE se intinde
	# in ploaie NU e ceruta de brief pe perioada — brief cere fereastra mai
	# grea/mai lunga, nu un ciclu diferit. Cu `surge_now` > `surge` implicit,
	# CALM se ingusteaza automat (acelasi `period`), exact "ploaia strange
	# fereastra" din brief, fara ramura de cod noua.
	var was_phase := phase()
	_clock = fposmod(_clock + delta, cycle_len)
	var telegraph_start := maxf(cycle_len - telegraph - surge_now, 0.0)
	var surge_start := maxf(cycle_len - surge_now, 0.0)
	var ph := Phase.CALM
	if _clock >= surge_start:
		ph = Phase.SURGE
	elif _clock >= telegraph_start:
		ph = Phase.TELEGRAPH
	if _hazard != null and is_instance_valid(_hazard):
		_hazard.rain_factor = lerpf(1.0, rain_surge_factor_force, rain_factor)
		match ph:
			Phase.CALM:
				_hazard.modulate = Color(1.0, 1.0, 1.0, calm_intensity)
			Phase.TELEGRAPH:
				_hazard.modulate = Color(1.0, 1.0, 1.0, telegraph_intensity)
			Phase.SURGE:
				_hazard.modulate = Color(1.0, 1.0, 1.0, SURGE_INTENSITY)
		_hazard.call("set_physics_enabled", ph == Phase.SURGE)
	if ph != was_phase and ph == Phase.TELEGRAPH:
		# TODO(sunet): vezi comentariul de la _ready — niciun sfx dedicat
		# existent, nu se adauga asset nou fara cerere explicita.
		pass


func _rain_factor() -> float:
	var rc := _find_rain_cycle()
	if rc == null:
		return 0.0
	return clampf(float(rc.get("rain_factor")), 0.0, 1.0)


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


## Grupul `rain_cycle` (vezi RainCycle._ready): citim `rain_factor` de acolo,
## fara referinta directa — acelasi tipar prin care WaterfallHazard.rain_factor
## e citit de altcineva, aici e RainCycle care produce, TorrentCycle consuma.
func _find_rain_cycle() -> Node:
	if _rain_searched and (_rain_cycle == null or is_instance_valid(_rain_cycle)):
		return _rain_cycle
	_rain_searched = true
	if not is_inside_tree():
		return null
	var nodes := get_tree().get_nodes_in_group(&"rain_cycle")
	_rain_cycle = nodes[0] if not nodes.is_empty() else null
	return _rain_cycle


# ---------------------------------------------------------------- pentru AI/sonde

## Faza curenta — acelasi bit pe care il vede jucatorul (perdeaua mai groasa/
## mai alba in TELEGRAPH, plina in SURGE).
func phase() -> Phase:
	var rain_factor := _rain_factor()
	var surge_now := surge * lerpf(1.0, rain_surge_factor, rain_factor)
	var telegraph_start := maxf(period - telegraph - surge_now, 0.0)
	var surge_start := maxf(period - surge_now, 0.0)
	if _clock >= surge_start:
		return Phase.SURGE
	elif _clock >= telegraph_start:
		return Phase.TELEGRAPH
	return Phase.CALM


func is_surge() -> bool:
	return phase() == Phase.SURGE


## Secunde pana la INCEPUTUL urmatorului SURGE (0 daca deja in puls).
func seconds_to_surge() -> float:
	var rain_factor := _rain_factor()
	var surge_now := surge * lerpf(1.0, rain_surge_factor, rain_factor)
	var surge_start := maxf(period - surge_now, 0.0)
	if _clock >= surge_start:
		return 0.0
	return surge_start - _clock


## Cat de mult (s) e traversarea perdelei la o viteza plauzibila — acelasi
## rol ca `TunnelSignalHazard.cross_time()`, dar cu o viteza fixa de
## referinta (nu configurabila): banda e scurtatura, nu tunelul, si brief-ul
## cere doar "timpul de traversare la o viteza plauzibila", nu o calibrare
## per masina — AI-ul isi calculeaza ETA cu PROPRIA viteza (vezi
## `ai_controller.gd._torrent_blocks_branch`), asta e doar durata perdelei
## insasi pentru marja de traversare din `blocks_in`.
const CROSS_REF_SPEED: float = 20.0

func cross_s() -> float:
	return length / CROSS_REF_SPEED


## Va fi SURGE in vreun moment din intervalul [seconds, seconds + cross_s()]?
## Aceeasi forma ca SlidingHazard.door_blocks_in/TunnelSignalHazard.blocks_in,
## ca AIController sa trateze torentul cu tiparul "daca ajung acolo peste X
## secunde, mai gasesc drumul liber pana ies din perdea?".
func blocks_in(seconds: float) -> bool:
	return blocks_between(seconds, seconds)


## Va fi SURGE in vreun moment din [t0, t1 + cross_s()]? Generalizarea lui
## `blocks_in` pentru un sofer care NU stie exact cand ajunge: AI-ul isi
## estimeaza sosirea intre „cu viteza de acum" (t0) si „incetinit in virajele
## benzii" (t1) — vezi `ai_controller.gd._torrent_blocks_branch`. Masurat pe
## scena unita cu un singur moment (`blocks_in(eta)` + 1 s): 5 intrari de AI
## in puls din 30, fiindca banda are viraje de 19 m raza la furca si masina
## ajunge la perdea cu 2-3 s mai tarziu decat socotise la 25 m/s.
func blocks_between(t0: float, t1: float) -> bool:
	var rain_factor := _rain_factor()
	var surge_now := surge * lerpf(1.0, rain_surge_factor, rain_factor)
	var surge_start := maxf(period - surge_now, 0.0)
	var cross := cross_s()
	var t := minf(t0, t1)
	var span := absf(t1 - t0) + cross
	# Verificam pe pasi mici in loc de o formula inchisa (perioada ramane
	# fixa dar surge_now variaza cu ploaia doar la evaluare, nu in timp —
	# in practica un `fposmod` simplu e suficient, fiindca in intervalul
	# [seconds, seconds+cross] ploaia nu-si schimba faza suficient de des
	# ca sa conteze pentru un puls de cateva secunde).
	var steps := maxi(int(ceil(span / 0.1)), 1)
	for i in steps + 1:
		var tt := t + span * float(i) / float(steps)
		if fposmod(_clock + tt, period) >= surge_start:
			return true
	return false


## Punctul de pe BUCLA PRINCIPALA unde se desprinde banda (ruta 0), pentru
## AI — acelasi rol ca `ai_decision_point()` la celelalte hazarde, dar
## aici returnam explicit punctul de pe ruta 0 (nu perdeaua insasi), fiindca
## decizia AI-ului ("iau scurtatura sau nu") se ia la FURCA, nu la perdea.
func ai_decision_point() -> Vector3:
	var track := _find_track()
	if track == null:
		return global_transform.origin
	var route := track.route_at(branch_index)
	if route == null:
		return global_transform.origin
	var entry_i := int(route.entry_frac * float(track.route_at(0).count())) \
		% maxi(track.route_at(0).count(), 1)
	return track.route_at(0).baked[entry_i]


## Pozitia perdelei (pentru sonde: distanta de traversare, camera etc).
func curtain_position() -> Vector3:
	return global_transform.origin


## Hazardul construit (pentru sonde: fizica, fog_amount, cars_inside).
func hazard() -> WaterfallHazard:
	return _hazard


# ---------------------------------------------------------------- pentru sonde

## Forteaza ceasul la un punct din ciclu (s), pentru sonde care vor sa
## verifice o faza anume fara sa astepte `period` secunde de `_physics_process`.
## OPRESTE avansul automat — acelasi tipar/aceeasi capcana ca
## `RainCycle.force_clock`: fara asta, cadrul URMATOR ar avansa `_clock` si
## ar suprascrie valoarea fortata.
func force_clock(t: float) -> void:
	set_physics_process(false)
	_clock = fposmod(t, period)
	if _hazard != null and is_instance_valid(_hazard):
		var ph := phase()
		match ph:
			Phase.CALM:
				_hazard.modulate = Color(1.0, 1.0, 1.0, calm_intensity)
			Phase.TELEGRAPH:
				_hazard.modulate = Color(1.0, 1.0, 1.0, telegraph_intensity)
			Phase.SURGE:
				_hazard.modulate = Color(1.0, 1.0, 1.0, SURGE_INTENSITY)
		_hazard.call("set_physics_enabled", ph == Phase.SURGE)


func resume_clock() -> void:
	set_physics_process(not Engine.is_editor_hint())
