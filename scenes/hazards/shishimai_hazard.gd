class_name ShishimaiHazard
extends Node3D
## Shishimai — dansul leului japonez (Kyoto, Track18, POI H): un leu de festival, cap
## mare de lemn lacuit rosu si panza verde cu spirale albe (karakusa), purtat de doi
## dansatori, la scara de jucarie (~7,4 m lungime, ~4,8 m inaltime). Danseaza LATERAL
## peste soseaua dreptei finale (Yasaka-dori), cu capul care se leagana si falca care
## clampaneste, iar la fiecare 9 s face un ATAC: se ghemuieste si da capul inapoi
## (telegraful, 1,4 s, cu capul intors spre partea in care are sa sara), apoi se
## repede 3-4 m intr-o parte.
##
## Spre deosebire de daruma-otoshi (care traverseaza TOATA soseaua, deci se scapa prin
## timing), leul nu inchide niciodata drumul: ocupa o fasie de ~3 m dintr-o sosea de
## 14, deci pe tot ciclul ramane un culoar liber de cel putin 5 m pe cea mai larga
## parte. Jucatorul alege PARTEA pe care trece citind miscarea — nu e un hazard de
## timing, e unul de citire (principiul 2: turbo-ul se arde pe dreapta, iar dreapta
## asta cere sa te uiti).
##
## [b]O stare pura din ceas[/b]. `_clock` ruleaza peste un tipar de `PATTERN_CYCLES`
## cicluri (`pattern_seconds`); directia atacului depinde de ciclu (`LUNGE_DIRS`).
## Tot ce se vede si tot ce loveste (pozitia laterala, ghemuirea, unghiul capului,
## falca) e o functie PURA de `_clock` (`_apply_state`), deci `seek` / `force_clock`
## pun orice faza, la fel pentru sonde si capturi, iar AI-ul poate PREZICE unde va fi
## leul la sosire (`center_at`, `ai_choose_lane`).
##
## [b]Un ciclu[/b] (`cycle_seconds` = 9 s; s in ciclu): dans (amplitudine plina) ->
## telegraf [`lunge_at - telegraph_seconds`, `lunge_at`]: dansul se linisteste, leul
## se ghemuieste, capul se da inapoi cu botul in sus si se intoarce spre partea
## atacului, deplasare de pregatire de `wind_back` m in partea OPUSA -> ATAC
## (`lunge_seconds`): `lunge_reach` m spre `dir`, cu un salt -> pozitia ramane
## (`hold_seconds`) -> revenire (`recover_seconds`) la dans. Suma = `cycle_seconds`.
##
## [b]Contact[/b]. Fara corp solid (memoria `corp-cinematic-aparut-in-masina`): o zona
## (`_zone`, Area3D) acopera gabaritul leului si se misca cu el. Masina prinsa in
## zona e aruncata LATERAL, departe de centrul leului (sau pe sensul atacului), cu un
## mic salt, prin [HazardThrow] (orizontala se scrie, verticala prin `Car.launch`).
## Masa conteaza (`ratio = masa_de_referinta / masa_masinii`): Buggy-ul zboara,
## Autobuzul e clintit; masa grea PASTREAZA mai mult din viteza inainte. Fara oprire,
## fara distrugere. Distanta laterala e plafonata ca masina sa aterizeze cel mult
## `edge_slack` m dincolo de marginea soselei (la 35-40 m/s nu are voie sa fie
## ejectata absurd peste gard sau in rau).
##
## [b]AI onest[/b]: citeste ce vede si un om — ritmul dansului si, odata inceput
## telegraful, directia atacului — si isi alege banda libera pe fereastra lui de
## sosire [rapid, lent] (`ai_choose_lane`). NU franeaza. Vezi
## `ai_controller.gd::_shishimai_line`.
##
## [b]Contractul modelului[/b] (`shishimai.glb`, scris inainte de Blender; daca difera,
## codul castiga). Originea radacinii = centrul dansului, LA SOL (cota soselei); +X =
## dreapta, +Z = FATA (capul, spre masina care vine), +Y = sus:
##   `Head`     capul; PIVOT = gatul, la (0, 2,10, 1,45); fata pe +Z
##   `Jaw`      falca de jos; PIVOT = balamaua, la (0, 2,15, 1,70). Codul o face copil
##              al lui `Head` (reparent, global pastrat); `rotation.x` > 0 = deschis
##   `Body_1`..`Body_3`  panza, 3 segmente; PIVOT = marginea din fata, la sol; codul
##              scrie `rotation.y` (unduire)
##   `Leg_FL`, `Leg_FR`, `Leg_BL`, `Leg_BR`  picioare; PIVOT = soldul (y = 0,95);
##              codul scrie `rotation.x` (pasul) si `scale.y` (ghemuirea)
## Fara el, un placeholder din primitive cu aceleasi nume de noduri.

## Grupul pe care il citeste `AIController`.
const AI_GROUP: StringName = &"shishimai"
## Ciclul de atac se repeta cu directii in tiparul asta (+1 = dreapta, -1 = stanga).
const LUNGE_DIRS: Array[int] = [1, -1, -1, 1]

signal car_thrown(car: Car)

@export_group("Ciclul")
## Durata unui ciclu dans + atac (s). Impartit la `dance_period` da un numar intreg.
@export_range(4.0, 20.0, 0.5) var cycle_seconds: float = 9.0
## Telegraful: se ghemuieste si da capul inapoi inainte de atac.
@export_range(0.4, 3.0, 0.1) var telegraph_seconds: float = 1.4
## Momentul atacului in ciclu (s).
@export_range(2.0, 20.0, 0.05) var lunge_at: float = 6.8
@export_range(0.1, 1.0, 0.01) var lunge_seconds: float = 0.4
## Ramane in pozitia noua inainte sa se intoarca la dans.
@export_range(0.0, 2.0, 0.05) var hold_seconds: float = 0.3
## Dupa asta ciclul se inchide (suma tuturor = `cycle_seconds`).
@export_range(0.2, 4.0, 0.05) var recover_seconds: float = 1.5
## Ceasul de la care porneste (s) — decaleaza hazardele intre ele.
@export_range(0.0, 120.0, 0.1) var start_clock: float = 0.0

@export_group("Dansul")
## Semilatimea soselei in punctul dansului (m). 0 = nu se atinge `road_width`.
@export var road_half_width: float = 0.0
## Amplitudinea dansului lateral (m, de la axa).
@export_range(0.5, 6.0, 0.1) var dance_amplitude: float = 3.2
## Perioada dansului lateral (s). `cycle_seconds` / perioada = numar intreg.
@export_range(1.5, 9.0, 0.1) var dance_period: float = 4.5
## Cat din dans e o a doua armonica (Lissajous): ochiul vede ca nu e un balansoar.
@export_range(0.0, 0.6, 0.02) var dance_harmonic: float = 0.22
## Avans/retragere pe sensul de mers (m).
@export_range(0.0, 2.0, 0.1) var advance_amplitude: float = 0.7
## Cat se repede lateral la atac (m).
@export_range(1.0, 6.0, 0.1) var lunge_reach: float = 3.4
## Cat se trage inapoi in telegraf, in partea opusa atacului (m).
@export_range(0.0, 2.0, 0.1) var wind_back: float = 0.8
## Cat inainteaza la atac, spre masina care vine (m).
@export_range(0.0, 3.0, 0.1) var lunge_advance: float = 1.2
## Saltul vizual la atac (m).
@export_range(0.0, 2.0, 0.05) var lunge_hop: float = 0.9
## Cat coboara leul in ghemuire (m).
@export_range(0.0, 0.6, 0.02) var crouch_depth: float = 0.28
## Plafonul pozitiei centrului fata de axa (m).
@export_range(2.0, 6.5, 0.1) var max_center: float = 4.8
## Un model de la Blender; gol = placeholder.
@export var model: PackedScene
## Scara vizuala SI a gabaritului (1 = modelul asa cum e: ~7,4 m lungime).
@export_range(0.5, 2.0, 0.05) var model_scale: float = 1.0
## Cate clampaniri pe secunda face falca in timpul dansului.
@export_range(0.5, 4.0, 0.1) var clack_hz: float = 1.8

@export_group("Aruncarea")
## Semilatimea gabaritului care loveste (m, la scara 1): capul si panza.
@export_range(0.8, 2.5, 0.05) var hit_half_width: float = 1.4
## Gabaritul pe sensul de mers: cat in fata de origine (nasul) si in spate (coada).
@export_range(1.0, 6.0, 0.1) var hit_front: float = 3.5
@export_range(1.0, 6.0, 0.1) var hit_back: float = 3.7
## Masa de referinta (Buggy = 100): raportul ei la masa masinii scaleaza efectul.
@export var reference_mass: float = 100.0
## Impinsul lateral pentru masa de referinta (m/s).
@export_range(0.0, 30.0, 0.5) var push_speed: float = 8.5
## Cat din viteza laterala a leului se adauga la impins (la atac, el insusi se misca).
@export_range(0.0, 1.5, 0.05) var push_from_lunge: float = 0.3
## Inaltimea zborului pentru masa de referinta (m).
@export_range(0.0, 3.0, 0.1) var throw_rise: float = 1.0
## Din viteza inainte, cat ramane la masa de referinta; masa mai mare tine mai mult.
@export_range(0.0, 1.0, 0.05) var keep_speed: float = 0.55
@export_range(0.0, 1.0, 0.05) var keep_per_mass: float = 0.25
## Cat dincolo de marginea soselei are voie sa ajunga masina aruncata (m).
@export_range(0.0, 6.0, 0.1) var edge_slack: float = 1.5
@export_range(0.0, 8.0, 0.1) var spin_rate: float = 3.0
@export_range(0.0, 2.0, 0.05) var spin_seconds: float = 0.5
@export_range(0.0, 2.0, 0.05) var crush_seconds: float = 0.35
@export_range(0.3, 1.0, 0.05) var crush_factor: float = 0.8
@export_range(0.1, 4.0, 0.1) var hit_cooldown: float = 1.5

@export_group("AI")
## Spatiu liber (m) intre marginea gabaritului si marginea masinii pentru banda aleasa.
@export_range(0.0, 3.0, 0.1) var ai_lane_margin: float = 0.9
## Marja pe fereastra de sosire (s), de fiecare parte.
@export_range(0.0, 1.5, 0.05) var ai_time_margin: float = 0.25

@export_group("Sunet")
## Pana unde se aude muzica (m): flautul si tobele se aud de pe toata dreapta.
@export_range(20.0, 300.0, 5.0) var music_max_distance: float = 130.0
@export_range(1.0, 60.0, 1.0) var music_unit_size: float = 16.0
@export_range(-24.0, 6.0, 0.5) var music_db: float = -4.0
@export_range(-24.0, 6.0, 0.5) var clack_db: float = -1.0

## Latimea soselei (m) la tur; `road_half_width` o suprascrie.
var road_width: float = 14.0
## Contoare pentru sonde.
var throws: int = 0
var clacks: int = 0
var lunges: int = 0

var _clock: float = 0.0
var _rig: Node3D # radacina modelului (centrul leului, la sol)
var _head: Node3D
var _jaw: Node3D
var _bodies: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _head_rest: Vector3
var _jaw_rest: Vector3
var _body_rest: Array[Vector3] = []
var _leg_rest: Array[Vector3] = []
var _zone: Area3D
var _music: AudioStreamPlayer3D
var _clack_audio: AudioStreamPlayer3D
var _cooldown: Dictionary = {}
var _last_center: float = 0.0
var _last_clack_n: int = 0
var _last_lunge_cycle: int = -1


func _ready() -> void:
	if road_half_width > 0.0:
		road_width = road_half_width * 2.0
	_clock = fposmod(start_clock, pattern_seconds())
	add_to_group(AI_GROUP)
	_build_rig()
	_build_audio()
	_last_clack_n = _clack_index(_clock)
	_apply_state()
	_sync_music()


# ------------------------------------------------------------------ ciclul

## Durata tiparului intreg (s): `LUNGE_DIRS.size()` cicluri.
func pattern_seconds() -> float:
	return cycle_seconds * float(LUNGE_DIRS.size())


func clock() -> float:
	return _clock


func cycle_index(g: float) -> int:
	return int(floorf(fposmod(g, pattern_seconds()) / cycle_seconds)) % LUNGE_DIRS.size()


## Secunde de la inceputul ciclului.
func cycle_time(g: float) -> float:
	var p := fposmod(g, pattern_seconds())
	return p - floorf(p / cycle_seconds) * cycle_seconds


func telegraph_start() -> float:
	return lunge_at - telegraph_seconds


## Directia atacului in ciclul `k` (+1 dreapta, -1 stanga).
func lunge_dir(k: int) -> float:
	return float(LUNGE_DIRS[posmod(k, LUNGE_DIRS.size())])


## Factorul de amplitudine al dansului in ciclu: plin, se linisteste in telegraf,
## ramane jos in atac si revine in recuperare. Continuu la granita ciclului (1 -> 1).
func dance_factor(s: float) -> float:
	var ts := telegraph_start()
	if s < ts:
		return 1.0
	if s < lunge_at:
		return lerpf(1.0, 0.35, smoothstep(0.0, 1.0, (s - ts) / telegraph_seconds))
	var rs := lunge_at + lunge_seconds + hold_seconds
	if s < rs:
		return 0.35
	return lerpf(0.35, 1.0, smoothstep(0.0, 1.0, (s - rs) / recover_seconds))


## Dansul lateral pur (m, fara atac): doua armonici, periodic in `cycle_seconds`.
func dance_lateral(g: float) -> float:
	var w := TAU / dance_period
	return dance_amplitude * (sin(w * g + 0.6)
		+ dance_harmonic * sin(2.0 * w * g + 1.9)) / (1.0 + dance_harmonic)


## Deplasarea de atac L (m, + = spre `dir`) la `s` secunde in ciclu, relativ la dans.
## `dir` e inclus: intoarce valoarea cu semn.
func lunge_offset(k: int, s: float) -> float:
	var d := lunge_dir(k)
	var ts := telegraph_start()
	if s < ts:
		return 0.0
	if s < lunge_at:
		var u := smoothstep(0.0, 1.0, (s - ts) / telegraph_seconds)
		return -d * wind_back * u
	var le := lunge_at + lunge_seconds
	if s < le:
		var v := (s - lunge_at) / lunge_seconds
		var e := 1.0 - (1.0 - v) * (1.0 - v)
		return d * lerpf(-wind_back, lunge_reach, e)
	var re := le + hold_seconds
	if s < re:
		return d * lunge_reach
	var w := clampf((s - re) / recover_seconds, 0.0, 1.0)
	return d * lunge_reach * (1.0 - smoothstep(0.0, 1.0, w))


## Centrul lateral al leului (m de la axa, + = dreapta) la ceasul `g`. `with_lunge`
## false = ce se vede inainte de telegraf (dans pur, amplitudine plina).
func center_at_clock(g: float, with_lunge: bool = true) -> float:
	var k := cycle_index(g)
	var s := cycle_time(g)
	var c: float
	if with_lunge:
		c = dance_factor(s) * dance_lateral(g) + lunge_offset(k, s)
	else:
		c = dance_lateral(g)
	return clampf(c, -max_center, max_center)


## Avansul pe sensul de mers (m, + = spre masina care vine) la ceasul `g`.
func advance_at_clock(g: float) -> float:
	var s := cycle_time(g)
	var a := advance_amplitude * sin(TAU / (dance_period * 0.667) * g + 1.0) * dance_factor(s)
	var le := lunge_at + lunge_seconds
	if s >= lunge_at and s < le:
		var va := (s - lunge_at) / lunge_seconds
		a += lunge_advance * (1.0 - (1.0 - va) * (1.0 - va))
	elif s >= le:
		var re := le + hold_seconds
		var w := 1.0 if s < re else 1.0 - smoothstep(0.0, 1.0, (s - re) / recover_seconds)
		a += lunge_advance * w
	return a


## Viteza laterala a centrului (m/s) la ceasul `g`.
func lateral_velocity_at_clock(g: float) -> float:
	return (center_at_clock(g + 0.02) - center_at_clock(g - 0.02)) / 0.04


## Faza atacului la ceasul `g`: 0 dans, (0..1] telegraf, 1 atac, ... vezi `phase_name`.
func phase_name(g: float) -> StringName:
	var s := cycle_time(g)
	if s < telegraph_start():
		return &"dans"
	if s < lunge_at:
		return &"telegraf"
	if s < lunge_at + lunge_seconds:
		return &"atac"
	if s < lunge_at + lunge_seconds + hold_seconds:
		return &"pauza"
	return &"revenire"


## Centrul leului (m) peste `t_rel` secunde, AȘA CUM POATE FI PREZIS din ce se vede
## acum: atacul intra in calcul doar daca telegraful ciclului respectiv a inceput deja
## (un sofer vede ghemuirea si capul intors; o lovitura ne-anuntata nu o ghiceste
## nimeni). Fara asta AI-ul ar sti viitorul pe care jucatorul nu-l are.
func center_seen_at(t_rel: float) -> float:
	var g := _clock + t_rel
	var n_now := floorf(_clock / cycle_seconds)
	var n_t := floorf(g / cycle_seconds)
	var announced := true # ciclul de dinainte s-a vazut deja
	if n_t == n_now:
		announced = cycle_time(_clock) >= telegraph_start()
	elif n_t > n_now:
		announced = false
	return center_at_clock(g, announced)


## Semilatimea ocupata de leu (m), cu scara.
func half_extent() -> float:
	return hit_half_width * model_scale


## Intervalul lateral (lo, hi) ocupat de leu pe fereastra [t0, t1] secunde de acum,
## cu marja de timp. Centrul e continuu, deci reuniunea e un singur interval.
func occupied_interval(t0: float, t1: float) -> Vector2:
	var a := minf(t0, t1) - ai_time_margin
	var b := maxf(t0, t1) + ai_time_margin
	var lo := INF
	var hi := -INF
	var n := maxi(int(ceilf((b - a) / 0.1)), 1)
	for i in n + 1:
		var c := center_seen_at(a + (b - a) * float(i) / float(n))
		lo = minf(lo, c)
		hi = maxf(hi, c)
	return Vector2(lo - half_extent(), hi + half_extent())


## Spatiul liber (m) intre masina (centrata la `lat`, semilatime `car_half`) si
## intervalul ocupat; negativ = se suprapun.
func clearance(lat: float, car_half: float, occ: Vector2) -> float:
	return maxf(lat - car_half - occ.y, occ.x - (lat + car_half))


## Banda (m de la axa, + = dreapta) pe care sa treaca o masina sosind in [t0, t1]:
## cea mai apropiata de `current` care are cel putin `ai_lane_margin` liber; daca
## nu exista niciuna, cea cu spatiul liber cel mai mare. `lane_max` = cat de
## departe de axa are voie sa mearga.
func ai_choose_lane(current: float, car_half: float, t0: float, t1: float,
		lane_max: float) -> float:
	var occ := occupied_interval(t0, t1)
	var best := clampf(current, -lane_max, lane_max)
	var best_free := clearance(best, car_half, occ)
	if best_free >= ai_lane_margin:
		return best
	var fallback := best
	var fallback_free := best_free
	var found := false
	var found_lane := best
	var step := 0.4
	var n := int(ceilf(2.0 * lane_max / step))
	for i in n + 1:
		var lane := -lane_max + step * float(i)
		var free := clearance(lane, car_half, occ)
		if free > fallback_free:
			fallback_free = free
			fallback = lane
		if free >= ai_lane_margin and (not found or absf(lane - current) < absf(found_lane - current)):
			found = true
			found_lane = lane
	return found_lane if found else fallback


## Punctul de pe axa soselei unde sta leul (pentru indexul de pista al AI-ului).
func ai_decision_point() -> Vector3:
	return global_position


## Pentru sonde: fixeaza ceasul fara sa opreasca ciclul.
func seek(t: float) -> void:
	_clock = fposmod(t, pattern_seconds())
	_last_clack_n = _clack_index(_clock)
	_apply_state()
	_sync_music()


## Pentru sonde si capturi: fixeaza ceasul si OPRESTE avansul.
func force_clock(t: float) -> void:
	set_physics_process(false)
	seek(t)


func resume_clock() -> void:
	set_physics_process(true)


func hit_zone() -> Area3D:
	return _zone


func rig() -> Node3D:
	return _rig


func head_node() -> Node3D:
	return _head


func jaw_node() -> Node3D:
	return _jaw


## Centrul real al leului acum (m de la axa, din nodul vazut), pentru sonde.
func current_center() -> float:
	return _rig.position.x if _rig != null else 0.0


# ------------------------------------------------------------ constructia

func _build_rig() -> void:
	_rig = Node3D.new()
	_rig.name = "Lion"
	add_child(_rig)
	_rig.scale = Vector3.ONE * model_scale
	var root: Node3D = null
	if model != null:
		root = model.instantiate() as Node3D
	if root == null or root.find_child("Head", true, false) == null \
			or root.find_child("Jaw", true, false) == null:
		root = _placeholder()
	_rig.add_child(root)
	# Materialul lumii (atlasul de paleta + AO din vertex color): zero materiale in plus.
	Palette.apply_world_material(root)
	_head = root.find_child("Head", true, false) as Node3D
	_jaw = root.find_child("Jaw", true, false) as Node3D
	_jaw.reparent(_head, true) # falca urmeaza capul, pastrand transformul global
	_head_rest = _head.position
	_jaw_rest = _jaw.position
	_bodies.clear()
	_body_rest.clear()
	for i in 3:
		var b := root.find_child("Body_%d" % (i + 1), true, false) as Node3D
		_bodies.append(b)
		_body_rest.append(b.position)
	_legs.clear()
	_leg_rest.clear()
	for nm in ["Leg_FL", "Leg_FR", "Leg_BL", "Leg_BR"]:
		var l := root.find_child(nm, true, false) as Node3D
		_legs.append(l)
		_leg_rest.append(l.position)

	# Zona de ghiont: gabaritul leului, copil al lui `_rig` (se misca cu el). Fara corp
	# solid -- contactul de aproape e geometric.
	_zone = Area3D.new()
	_zone.name = "HitZone"
	_zone.monitorable = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var length := hit_front + hit_back
	box.size = Vector3(hit_half_width * 2.0, 6.0, length)
	shape.shape = box
	shape.position = Vector3(0.0, 2.5, (hit_front - hit_back) * 0.5)
	_zone.add_child(shape)
	_rig.add_child(_zone)


# Primitive pe atlas, cu aceleasi nume de noduri ca modelul.
func _placeholder() -> Node3D:
	var root := Node3D.new()
	root.name = "ShishimaiPlaceholder"
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 2.1, 1.45)
	head.add_child(PaletteBox.instance(Vector3(2.5, 1.7, 1.7), Palette.KERB_RED,
		Vector3(0.0, 0.95, 0.85)))
	root.add_child(head)
	var jaw := Node3D.new()
	jaw.name = "Jaw"
	jaw.position = Vector3(0.0, 2.15, 1.7)
	jaw.add_child(PaletteBox.instance(Vector3(2.2, 0.5, 1.6), Palette.KERB_RED,
		Vector3(0.0, -0.35, 0.8)))
	root.add_child(jaw)
	var z0 := [1.55, -0.4, -2.35]
	for i in 3:
		var b := Node3D.new()
		b.name = "Body_%d" % (i + 1)
		b.position = Vector3(0.0, 0.0, z0[i])
		b.add_child(PaletteBox.instance(Vector3(2.4, 1.3, 2.0), Palette.TROPICAL_GREEN,
			Vector3(0.0, 1.55, -1.0)))
		root.add_child(b)
	for nm_x_z in [["Leg_FL", -0.55, 0.85], ["Leg_FR", 0.55, 0.85],
			["Leg_BL", -0.55, -2.25], ["Leg_BR", 0.55, -2.25]]:
		var l := Node3D.new()
		l.name = nm_x_z[0]
		l.position = Vector3(nm_x_z[1], 0.95, nm_x_z[2])
		l.add_child(PaletteBox.instance(Vector3(0.45, 0.85, 0.5), Palette.FOAM_WHITE,
			Vector3(0.0, -0.45, 0.0)))
		root.add_child(l)
	return root


# ------------------------------------------------------------------ starea

func _physics_process(delta: float) -> void:
	var prev := _clock
	_clock = fposmod(_clock + delta, pattern_seconds())
	_apply_state()
	_tick_audio(prev)
	_tick_cooldown(delta)
	_hit_cars()


func _clack_index(g: float) -> int:
	return int(floorf(g * clack_hz - 0.6))


## Starea vizuala si fizica ca functie PURA de `_clock`.
func _apply_state() -> void:
	if _rig == null:
		return
	var g := _clock
	var k := cycle_index(g)
	var s := cycle_time(g)
	var d := lunge_dir(k)
	var ts := telegraph_start()
	var c := center_at_clock(g)
	_rig.position = Vector3(c, 0.0, advance_at_clock(g))
	_last_center = c
	var vel := lateral_velocity_at_clock(g)
	var a := dance_factor(s)
	var w := TAU / dance_period

	# ghemuire (0..1) in telegraf si pauza; saltul (m) la atac
	var crouch := 0.0
	var hop := 0.0
	var le := lunge_at + lunge_seconds
	if s >= ts and s < lunge_at:
		crouch = smoothstep(0.0, 1.0, (s - ts) / telegraph_seconds)
	elif s >= lunge_at and s < le:
		var v := (s - lunge_at) / lunge_seconds
		crouch = 1.0 - smoothstep(0.0, 0.35, v)
		hop = lunge_hop * sin(PI * v)
	var drop := crouch * crouch_depth

	# capul: se leagana, in telegraf se da inapoi si se intoarce spre partea atacului
	var look := 0.0
	var pitch := 0.10 * sin(2.0 * w * g)
	if s >= ts and s < lunge_at:
		var u := smoothstep(0.0, 1.0, (s - ts) / telegraph_seconds)
		look = d * 0.62 * u
		pitch = lerpf(pitch, -0.42, u) + 0.03 * sin(s * 40.0) * u
	elif s >= lunge_at and s < le + hold_seconds:
		var v2 := clampf((s - lunge_at) / lunge_seconds, 0.0, 1.0)
		look = d * lerpf(0.62, 0.30, v2)
		pitch = lerpf(-0.42, 0.34, 1.0 - pow(1.0 - v2, 2.0))
	elif s >= le + hold_seconds:
		var r := smoothstep(0.0, 1.0, (s - le - hold_seconds) / recover_seconds)
		look = d * 0.30 * (1.0 - r)
		pitch = lerpf(0.34, 0.10 * sin(2.0 * w * g), r)
	look += 0.30 * a * sin(w * g + 0.9)
	_head.rotation = Vector3(pitch, look, 0.07 * a * sin(w * g + 0.3))
	_head.position = _head_rest + Vector3(0.0, hop - drop, 0.0)

	# falca: clampaneste la dans, se deschide larg in telegraf, se inchide la atac
	var jaw_open: float
	var p := fposmod(g * clack_hz, 1.0)
	jaw_open = 0.42 * smoothstep(0.0, 0.15, p) * (1.0 - smoothstep(0.58, 0.64, p))
	if s >= ts and s < lunge_at:
		var u2 := smoothstep(0.0, 1.0, (s - ts) / telegraph_seconds)
		jaw_open = lerpf(jaw_open, 0.62 + 0.05 * sin(s * 36.0), u2)
	elif s >= lunge_at and s < le:
		jaw_open = lerpf(0.62, 0.0, smoothstep(0.55, 1.0, (s - lunge_at) / lunge_seconds))
	elif s >= le and s < le + hold_seconds:
		jaw_open = 0.0
	elif s >= le + hold_seconds:
		var r2 := smoothstep(0.0, 1.0, (s - le - hold_seconds) / recover_seconds)
		jaw_open = lerpf(0.0, jaw_open, r2)
	_jaw.rotation = Vector3(jaw_open, 0.0, 0.0)
	_jaw.position = _jaw_rest # copil al capului: pozitia locala ramane

	# panza: unduire in lant, inclinata spre miscarea laterala
	for i in 3:
		var b := _bodies[i]
		b.rotation = Vector3(0.0, 0.14 * a * sin(w * g - 0.9 * float(i)) - vel * 0.025 * float(i + 1) * 0.35, 0.0)
		b.position = _body_rest[i] + Vector3(0.0, hop * (1.0 - 0.15 * float(i)) - drop, 0.0)

	# picioarele: pas diagonal; ghemuit = coapsa mai joasa, talpa ramane pe sol
	var step := TAU * clack_hz * g
	for i in 4:
		var l := _legs[i]
		var phase := step + (PI if i == 1 or i == 2 else 0.0)
		var hip_y := _leg_rest[i].y
		l.rotation = Vector3(0.45 * a * sin(phase), 0.0, 0.0)
		l.position = _leg_rest[i] + Vector3(0.0, -drop + hop, 0.0)
		l.scale = Vector3(1.0, maxf((hip_y - drop) / hip_y, 0.2), 1.0)
		if hop > 0.001:
			l.scale = Vector3.ONE
			l.rotation = Vector3(-0.5 * sin(PI * clampf((s - lunge_at) / lunge_seconds, 0.0, 1.0)), 0.0, 0.0)


# ------------------------------------------------------------------ sunet

## Doua playere pozitionale (bus SFX): muzica (flaut fue + taiko, bucla de exact un
## ciclu, deci toba mare cade pe atac si ruladele cresc in telegraf) si clampanitul
## falcii (lemn). Evenimentele se prind PE MARGINE in `_physics_process`, nu in
## `_apply_state` (pura, o cheama si `seek`), deci un `seek` nu canta nimic.
## Stream-ul se cere prin ARBORE (`/root/AudioManager`), nu prin identificatorul
## autoload: in modul `--script` identificatorul nu se rezolva (vezi
## `daruma_otoshi_hazard.gd::_sfx`).
func _build_audio() -> void:
	_music = AudioStreamPlayer3D.new()
	_music.bus = &"SFX"
	_music.max_distance = music_max_distance
	_music.unit_size = music_unit_size
	_music.volume_db = music_db
	_rig.add_child(_music)
	_music.position = Vector3(0.0, 2.5, 0.0)
	_clack_audio = AudioStreamPlayer3D.new()
	_clack_audio.bus = &"SFX"
	_clack_audio.max_distance = music_max_distance * 0.6
	_clack_audio.unit_size = music_unit_size * 0.6
	_clack_audio.volume_db = clack_db
	_rig.add_child(_clack_audio)
	_clack_audio.position = Vector3(0.0, 2.6, 1.9)


func _sfx(sfx_name: StringName) -> AudioStream:
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null:
		return null
	return manager.call("stream", sfx_name)


## (Re)porneste muzica la pozitia ciclului. Se cheama la `_ready` si la `seek`.
func _sync_music() -> void:
	if _music == null or not is_inside_tree():
		return
	if _music.stream == null:
		_music.stream = _sfx(&"shishimai_music")
	if _music.stream != null:
		_music.play(cycle_time(_clock))


func _tick_audio(prev_clock: float) -> void:
	if _clack_audio == null:
		return
	var n := _clack_index(_clock)
	if n != _last_clack_n:
		_last_clack_n = n
		# in telegraf si atac falca nu clampaneste in ritmul dansului
		var s := cycle_time(_clock)
		if s < telegraph_start() or s >= lunge_at + lunge_seconds + hold_seconds:
			_play_clack(1.0)
	var s_prev := cycle_time(prev_clock)
	var s_now := cycle_time(_clock)
	# atacul: clampanitul mare, la inchiderea falcii
	var close_at := lunge_at + lunge_seconds * 0.8
	if s_prev < close_at and s_now >= close_at and cycle_index(prev_clock) == cycle_index(_clock):
		lunges += 1
		_play_clack(0.8)


func _play_clack(pitch: float) -> void:
	clacks += 1
	var st := _sfx(&"shishimai_clack")
	if st == null:
		return
	_clack_audio.stream = st
	_clack_audio.pitch_scale = pitch * randf_range(0.95, 1.05)
	_clack_audio.play()


# ------------------------------------------------------------------ lovitura

func _tick_cooldown(delta: float) -> void:
	for key in _cooldown.keys():
		if not is_instance_valid(key):
			_cooldown.erase(key)
			continue
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0:
			_cooldown.erase(key)
		else:
			_cooldown[key] = left


func _hit_cars() -> void:
	if _zone == null:
		return
	for b in _zone.get_overlapping_bodies():
		var car := b as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = hit_cooldown
		_throw_car(car)


## Directia laterala a aruncarii (+1 = dreapta fata de sensul de mers): departe de
## centrul leului; daca masina e fix in axa lui, pe sensul in care se misca el.
func throw_side(car_x: float, lion_x: float, lion_vx: float) -> float:
	var dx := car_x - lion_x
	if absf(dx) > 0.3:
		return signf(dx)
	if absf(lion_vx) > 0.5:
		return signf(lion_vx)
	return -signf(lion_x) if absf(lion_x) > 0.05 else 1.0


func _throw_car(car: Car) -> void:
	var ratio := clampf(reference_mass / maxf(car.mass, 1.0), 0.4, 1.4)
	var keep := clampf(keep_speed + keep_per_mass * (car.mass / reference_mass - 1.0),
		0.1, 0.95)
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var lp := to_local(car.global_position)
	var vx := lateral_velocity_at_clock(_clock)
	var sgn := throw_side(lp.x, _rig.position.x, vx)
	var v_lat := push_speed * ratio
	# leul insusi se misca la atac: cine e in calea lui primeste si din viteza lui
	if signf(vx) == sgn:
		v_lat += absf(vx) * push_from_lunge
	# plafon: aterizeaza cel mult `edge_slack` dincolo de marginea soselei
	var t_air := 2.0 * sqrt(2.0 * maxf(throw_rise * ratio, 0.01) / maxf(car.gravity, 1.0))
	var room := road_width * 0.5 + edge_slack - sgn * lp.x
	v_lat = minf(v_lat, maxf(room / maxf(t_air, 0.1), 2.0))
	# DOAR componenta pe sensul de mers: lateralul din cadrul loviturii e al solverului,
	# nu al soferului, si nu trebuie sa se adune la impinsul hotarat de hazard.
	var along := car.velocity.dot(fwd)
	var horizontal := fwd * along * keep + right * sgn * v_lat
	HazardThrow.throw(car, null, horizontal, throw_rise * ratio, 0.0)
	var spin_sgn := -sgn
	car.spin_body(spin_rate * ratio * spin_sgn, spin_seconds)
	car.crush(crush_seconds, crush_factor, Vector3(1.15, 0.7, 1.15), 1.0)
	throws += 1
	car_thrown.emit(car)
