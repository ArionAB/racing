class_name GionMatsuriHazard
extends Node3D
## Car de festival Gion Matsuri (yamaboko, tip naginata-boko), Kyoto, Track18, POI F.
## Un turn de lemn lacuit pe patru roti de doi metri, cu tapiserii rosii/aurii/bleumarin
## si un catarg (shingi) de ~21 m cu lance aurie: o siluet verticala unica, care se
## citeste din viteza. Asteapta pe o margine a drumului, apoi (telegraf: tobe si
## clopotei „kon-chiki-chin", trasatorii se opintesc, turnul se leagana) TRAVERSEAZA
## drumul incet, ca un zid greu, si ramane pe cealalta margine pana la urmatorul ciclu,
## cand se intoarce. Nu conteaza ca in realitate carul nu e in gradina: e hazard.
##
## Inlocuieste `DarumaOtoshiHazard` pe pista (decizia dezvoltatorului, 3 oct 2026: o
## jucarie nu se potriveste jocului). Clasa veche, modelul si sunetele ei raman in repo.
##
## [b]O stare pura din ceas[/b], ca la daruma. `_clock` (s) merge peste ciclul mare: DOUA
## ETAPE (`rest_seconds` odihna + `telegraph_seconds` telegraful + `cross_seconds`
## traversarea), una de la `side` spre interior, una inapoi. Pozitia carului, rotile,
## trasatorii, balansul sunt functii PURE de `_clock` (`_apply_state`), deci `seek` /
## `force_clock` pun orice faza pentru sonde si capturi. Pozitia e continua prin
## constructie (smoothstep intre doua odihne): niciun salt, niciun corp care apare.
##
## [b]Geometria[/b]: radacina sta PE AXA soselei, cu fata pe sensul de mers (-Z), ca la
## daruma. Carul se misca pe X local (perpendicular pe sosea); `side` = +1 il pune intai
## pe dreapta (+X). Centrul lui in odihna: `road_half_width + rest_gap + cart_length / 2`.
## Cota urmeaza terenul (profil prin raycast pe `Track.CAMERA_BLOCKER_LAYER`, cu plafon).
##
## [b]Fara corp aparut in masina[/b] (memoria `corp-cinematic-aparut-in-masina`).
## Carul are un `AnimatableBody3D` (solid si in odihna: un zid pe marginea drumului),
## dar aruncarea NU o face solverul: o zona (`_zone`) merge cu `zone_lead` metri
## INAINTEA carului, pe sensul lui de mers, prinde masina si o arunca prin
## [HazardThrow] (orizontala se scrie, verticala prin `Car.launch`, exceptie de
## coliziune cat tine zborul). Zona e activa DOAR cat carul se misca pe drum.
##
## [b]Masa conteaza[/b]: `ratio = masa_de_referinta / masa_masinii` taie impinsul si
## inaltimea; masa grea PASTREAZA mai mult din viteza inainte (`keep_speed`). Pe
## intoarcere (spre exterior) impinsul e mai mic (`push_outward_factor`): in spatele
## carului nu e loc ca pe gazon. Fara oprire si fara distrugere.
##
## [b]Mereu o fereastra de trecere[/b]: carul acopera pe rand doar o parte din latime
## (`cart_length` = 6 m din 11), iar in odihna + telegraf (`rest_seconds +
## telegraph_seconds`) nu atinge drumul deloc. Scapi prin TIMING (inainte de el sau
## dupa el) sau prin spatele/fata lui.
##
## [b]AI onest[/b]: acelasi contract ca la daruma (`blocks_between`, `window_rel`,
## `ai_margin`, `ai_decision_point`); `AIController._daruma_cap` citeste ambele grupuri.
##
## [b]Contractul modelului[/b] (`gion_boko.glb`, scris inainte de Blender; daca difera,
## codul castiga). Originea = centrul carului LA SOL; axa lunga (`cart_length`) pe X
## local (deci pe lateralul soselei), +Y sus; simetric (ambele capete au echipa lor):
##   `Body`        corpul static (sasiu, caroserie, acoperisuri, catarg)
##   `Wheel_1..4`  rotile; originea = centrul osiei, axa pe Z; codul scrie `rotation.z`
##   `Puller_P1/P2`, `Puller_N1/N2`  trasatorii capatului +X / -X; originea = talpa;
##                 codul scrie `rotation.z` (inclinare) si `position.y` (pasul)
##   `Musicians`   muzicantii de pe platforma; codul le da un salt mic cat canta
## Fara el, un placeholder din primitive cu aceleasi nume de noduri.

## Grupul pe care il citeste `AIController`.
const AI_GROUP: StringName = &"gion_matsuri"
const WHEEL_RADIUS: float = 1.0
const WHEEL_X: float = 1.9
## Inaltimea (m) la care sta centrul corpului solid fata de sol.
const BODY_CENTER_Y: float = 2.0
const BODY_HEIGHT: float = 4.0
const GROUND_STEP: float = 1.5
const GROUND_RANGE: float = 18.0

signal car_thrown(car: Car)

@export_group("Ciclul")
## Cat sta carul nemiscat la o margine, inainte de telegraf (s).
@export_range(1.0, 12.0, 0.5) var rest_seconds: float = 4.0
## Telegraful: tobe si clopotei, trasatorii se opintesc, turnul se leagana (s).
@export_range(1.0, 8.0, 0.1) var telegraph_seconds: float = 3.5
## Traversarea dintr-o margine in alta (s). ~20 m in 5,5 s = 3,7 m/s in medie.
@export_range(3.0, 12.0, 0.1) var cross_seconds: float = 5.5
## Ceasul de la care porneste (s) — decaleaza hazardele intre ele.
@export_range(0.0, 120.0, 0.1) var start_clock: float = 0.0

@export_group("Carul")
## +1 = intai pe dreapta sensului de mers (+X local), -1 = pe stanga.
@export_range(-1, 1, 2) var side: int = 1
## Semilatimea soselei in punctul carului (m). 0 = nu se atinge `road_width`.
@export var road_half_width: float = 0.0
## Lungimea caroseriei pe sensul de mers (m).
@export_range(3.0, 10.0, 0.1) var cart_length: float = 6.0
## Latimea pe sosea, roti inclusiv (m).
@export_range(2.0, 8.0, 0.1) var cart_width: float = 5.3
## Distanta (m) intre marginea soselei si capatul carului aflat in odihna.
@export_range(0.5, 8.0, 0.1) var rest_gap: float = 1.6
## Un model de la Blender; gol = placeholder.
@export var model: PackedScene
## Cat se leagana turnul (rad) in varful telegrafului.
@export_range(0.0, 0.05, 0.001) var sway_telegraph: float = 0.014

@export_group("Lovitura")
## Cat inaintea carului porneste zona de ghiont (m).
@export_range(0.5, 4.0, 0.1) var zone_lead: float = 1.2
## In plus fata de latimea carului, pe sensul soselei (m, de fiecare parte): acopera
## si trasatorii de pe flancuri.
@export_range(0.0, 3.0, 0.1) var hit_margin_along: float = 0.9
## Masa de referinta (Buggy = 100): raportul ei la masa masinii scaleaza efectul.
@export var reference_mass: float = 100.0
## Impinsul pe sensul de mers al carului, pentru masa de referinta (m/s).
@export_range(0.0, 30.0, 0.5) var push_speed: float = 9.0
## Factorul impinsului cand carul merge spre EXTERIOR (intoarcerea).
@export_range(0.0, 1.0, 0.05) var push_outward_factor: float = 0.6
## Inaltimea zborului pentru masa de referinta (m).
@export_range(0.0, 4.0, 0.1) var throw_rise: float = 1.1
## Din viteza inainte, cat ramane la masa de referinta; masa mai mare tine mai mult.
@export_range(0.0, 1.0, 0.05) var keep_speed: float = 0.15
@export_range(0.0, 1.0, 0.05) var keep_per_mass: float = 0.2
@export_range(0.0, 8.0, 0.1) var spin_rate: float = 3.5
@export_range(0.0, 2.0, 0.05) var spin_seconds: float = 0.6
@export_range(0.0, 2.0, 0.05) var crush_seconds: float = 0.4
@export_range(0.3, 1.0, 0.05) var crush_factor: float = 0.7
@export_range(0.2, 3.0, 0.1) var clear_seconds: float = 1.4
@export_range(0.1, 4.0, 0.1) var hit_cooldown: float = 1.5
## Marja pe fereastra de pericol pentru AI (s), de fiecare parte.
@export_range(0.0, 1.5, 0.05) var ai_margin: float = 0.35
## Cat de jos (fractie din croaziera) poate cobori plafonul de viteza al AI-ului ca sa
## treaca DUPA car. Mai jos decat la daruma (0,5): fereastra de pericol dureaza ~4 s,
## nu ~1,4 s. Niciodata oprire.
@export_range(0.2, 0.8, 0.05) var ai_floor: float = 0.35

## Latimea soselei (m) la tur; `road_half_width` o suprascrie.
var road_width: float = 11.0

@export_group("Sunet")
## Pana unde se aude muzica (m).
@export_range(20.0, 300.0, 5.0) var music_max_distance: float = 150.0
@export_range(1.0, 60.0, 1.0) var music_unit_size: float = 18.0
@export_range(-24.0, 6.0, 0.5) var music_db: float = -2.0
@export_range(-24.0, 6.0, 0.5) var wheels_db: float = -4.0

## Contoare pentru sonde.
var throws: int = 0
## Cate telegrafe a pornit (pentru sonde).
var telegraphs: int = 0
## Cate traversari complete a facut (pentru sonde).
var crossings: int = 0

var _clock: float = 0.0
var _cart: Node3D # radacina modelului (centrul carului, la sol)
var _wheels: Array[Node3D] = []
var _pullers: Array[Node3D] = [] # P1, P2, N1, N2
var _puller_rest: Array[Vector3] = []
var _musicians: Node3D
var _musicians_rest_y: float = 0.0
var _body: AnimatableBody3D
var _body_shape: CollisionShape3D
var _zone: Area3D
var _zone_shape: CollisionShape3D
var _music_audio: AudioStreamPlayer3D
var _wheels_audio: AudioStreamPlayer3D
var _audio_phase: int = 0 # 0 oprit, 1 telegraf, 2 traversare
var _cooldown: Dictionary = {}
var _win_lo: float = 0.0 # fata de inceputul traversarii: de cand incepe pericolul (s)
var _win_hi: float = 0.0 # pana cand carul a eliberat soseaua (s)
var _ground: Dictionary = {} # x local (indice) -> cota locala
var _ground_ready: bool = false
var _ground_tries: int = 0


func _ready() -> void:
	if road_half_width > 0.0:
		road_width = road_half_width * 2.0
	_clock = fposmod(start_clock, total_seconds())
	add_to_group(AI_GROUP)
	_build_rig()
	_build_audio()
	recompute_windows()
	_apply_state()


# ------------------------------------------------------------------ ciclul

## Durata unei etape: odihna + telegraful + traversarea (s).
func leg_seconds() -> float:
	return rest_seconds + telegraph_seconds + cross_seconds


## Durata ciclului mare: doua etape (dus si intors).
func total_seconds() -> float:
	return leg_seconds() * 2.0


func clock() -> float:
	return _clock


## Etapa curenta: 0 = de la `side` spre interior, 1 = inapoi.
func leg_index(g: float) -> int:
	return mini(int(g / leg_seconds()), 1)


## Secunde de la inceputul etapei.
func leg_time(g: float) -> float:
	return g - float(leg_index(g)) * leg_seconds()


## Sensul de mers pe X local in etapa `l` (+1 sau -1).
func leg_dir(l: int) -> float:
	return -float(side) if l == 0 else float(side)


## Centrul carului in odihna (m, valoare absoluta pe X local).
func rest_x() -> float:
	return road_width * 0.5 + rest_gap + cart_length * 0.5


## Cat din traversare a trecut (0..1), neted la capete.
func cross_u(s: float) -> float:
	return clampf((s - rest_seconds - telegraph_seconds) / cross_seconds, 0.0, 1.0)


## Cat din telegraf a trecut (0..1).
func telegraph_u(s: float) -> float:
	return clampf((s - rest_seconds) / telegraph_seconds, 0.0, 1.0)


## Pozitia pe X local a centrului carului la ceasul `g`.
func cart_x_at(g: float) -> float:
	var l := leg_index(g)
	var s := leg_time(g)
	var d := leg_dir(l)
	var x0 := -d * rest_x()
	return x0 + d * 2.0 * rest_x() * smoothstep(0.0, 1.0, cross_u(s))


## Viteza (m/s, cu semn pe X local) la ceasul `g`.
func cart_speed_at(g: float) -> float:
	var l := leg_index(g)
	var s := leg_time(g)
	var u := (s - rest_seconds - telegraph_seconds) / cross_seconds
	if u <= 0.0 or u >= 1.0:
		return 0.0
	return leg_dir(l) * 2.0 * rest_x() * 6.0 * u * (1.0 - u) / cross_seconds


## Viteza maxima (m/s), la mijlocul traversarii.
func peak_speed() -> float:
	return 2.0 * rest_x() * 1.5 / cross_seconds


func cart_x() -> float:
	return cart_x_at(_clock)


## Carul se misca acum (traversarea e in curs)?
func moving(g: float) -> bool:
	var u := (leg_time(g) - rest_seconds - telegraph_seconds) / cross_seconds
	return u > 0.0 and u < 1.0


## Faza sunetului: 0 oprit (odihna), 1 telegraf, 2 traversare.
func audio_phase(g: float) -> int:
	var s := leg_time(g)
	if s < rest_seconds:
		return 0
	if s < rest_seconds + telegraph_seconds:
		return 1
	if s < rest_seconds + telegraph_seconds + cross_seconds:
		return 2
	return 0


## Semi-lungimea zonei de pericol pe sensul de mers (m): caroseria + zona din fata.
func reach_half() -> float:
	return cart_length * 0.5 + zone_lead


## Cand (fata de inceputul traversarii) e periculos: de la intrarea zonei in sosea,
## pana caroseria a eliberat-o. Se masoara pe profilul real, nu se presupune.
func recompute_windows() -> void:
	var lo := INF
	var hi := -INF
	var step := 1.0 / 240.0
	var t := 0.0
	while t <= cross_seconds:
		var u := t / cross_seconds
		# simetric: masoara mersul spre +X (spre -X da aceeasi fereastra, oglindita)
		var x := -rest_x() + 2.0 * rest_x() * smoothstep(0.0, 1.0, u)
		if _edge_over_road(x, 1.0):
			lo = minf(lo, t)
			hi = maxf(hi, t)
		t += step
	_win_lo = lo
	_win_hi = hi


## Zona din fata sau caroseria acopera o parte din sosea cu centrul carului la `x`,
## mergand pe sensul `d` (+1 / -1 pe X local)?
func _edge_over_road(x: float, d: float) -> bool:
	var hw := road_width * 0.5
	var lead_edge := x + d * reach_half()
	var tail_edge := x - d * cart_length * 0.5
	return maxf(lead_edge, tail_edge) > -hw and minf(lead_edge, tail_edge) < hw


## Fereastra de pericol, relativa la inceputul traversarii (s).
func danger_window() -> Vector2:
	return Vector2(_win_lo, _win_hi)


## Prima fereastra de pericol care se termina dupa `t_from` secunde de acum:
## (inceput, sfarsit) in secunde RELATIVE la acum. Dupa ultima etapa a ciclului cade
## pe prima din ciclul urmator.
func window_rel(t_from: float) -> Vector2:
	var g := _clock + t_from
	var total := total_seconds()
	var base := floorf(g / total) * total
	var gl := g - base
	var move0 := rest_seconds + telegraph_seconds
	for l in 2:
		var a := base + float(l) * leg_seconds() + move0 + _win_lo
		var b := base + float(l) * leg_seconds() + move0 + _win_hi
		if gl <= b - base:
			return Vector2(a - _clock, b - _clock)
	var a2 := base + total + move0 + _win_lo
	var b2 := base + total + move0 + _win_hi
	return Vector2(a2 - _clock, b2 - _clock)


## Va fi periculos in vreun moment din [t0, t1] secunde (sosirea masinii e o
## fereastra, nu un moment)? `ai_margin` acopera trecerea prin amprenta.
func blocks_between(t0: float, t1: float) -> bool:
	var lo := minf(t0, t1) - ai_margin
	var hi := maxf(t0, t1) + ai_margin
	var w := window_rel(lo)
	return w.x <= hi


func blocks_in(seconds: float) -> bool:
	return blocks_between(seconds, seconds)


## Secunde pana la INCEPUTUL urmatoarei ferestre de pericol (0 daca e in ea).
func seconds_to_danger() -> float:
	return maxf(window_rel(0.0).x, 0.0)


## Punctul de pe axa soselei unde e carul (pentru indexul de pista al AI-ului).
func ai_decision_point() -> Vector3:
	return global_position


## Directia „spre exterior" in lume (orizontala, spre partea `side`).
func outward() -> Vector3:
	var o := global_transform.basis.x * float(side)
	o.y = 0.0
	return o.normalized()


## Semi-lungimea zonei de pericol pe sensul soselei (m).
func footprint_half() -> float:
	return cart_width * 0.5 + hit_margin_along


## Pentru sonde: fixeaza ceasul fara sa opreasca ciclul.
func seek(t: float) -> void:
	_clock = fposmod(t, total_seconds())
	_apply_state()


## Pentru sonde si capturi: fixeaza ceasul si OPRESTE avansul.
func force_clock(t: float) -> void:
	set_physics_process(false)
	seek(t)


func resume_clock() -> void:
	set_physics_process(true)


func body() -> AnimatableBody3D:
	return _body


func hit_zone() -> Area3D:
	return _zone


func cart_node() -> Node3D:
	return _cart


func wheel_node(i: int) -> Node3D:
	return _wheels[i]


func puller_node(i: int) -> Node3D:
	return _pullers[i]


## Profilul solului e construit (raycast reusit sau buget epuizat)?
func ground_ready() -> bool:
	return _ground_ready


## Cota solului (m, fata de radacina) la pozitia `x` pe X local, din profilul raycast.
func ground_at(x: float) -> float:
	if _ground.is_empty():
		return 0.0
	var f := (x + GROUND_RANGE) / GROUND_STEP
	var i0 := clampi(int(floorf(f)), 0, int(2.0 * GROUND_RANGE / GROUND_STEP))
	var i1 := mini(i0 + 1, int(2.0 * GROUND_RANGE / GROUND_STEP))
	var y0: float = _ground.get(i0, 0.0)
	var y1: float = _ground.get(i1, y0)
	return lerpf(y0, y1, clampf(f - float(i0), 0.0, 1.0))


# ------------------------------------------------------------ constructia

func _build_rig() -> void:
	_cart = Node3D.new()
	_cart.name = "Cart"
	add_child(_cart)
	var root: Node3D = null
	if model != null:
		root = model.instantiate() as Node3D
	if root == null or root.find_child("Wheel_1", true, false) == null:
		root = _placeholder()
	_cart.add_child(root)
	# Materialul lumii (atlasul de paleta + AO din vertex color): zero materiale in plus.
	Palette.apply_world_material(root)
	_wheels.clear()
	for i in 4:
		_wheels.append(root.find_child("Wheel_%d" % (i + 1), true, false) as Node3D)
	_pullers.clear()
	_puller_rest.clear()
	for nm in ["Puller_P1", "Puller_P2", "Puller_N1", "Puller_N2"]:
		var p := root.find_child(nm, true, false) as Node3D
		_pullers.append(p)
		_puller_rest.append(p.position if p != null else Vector3.ZERO)
	_musicians = root.find_child("Musicians", true, false) as Node3D
	if _musicians != null:
		_musicians_rest_y = _musicians.position.y

	# Corp solid (frate cu modelul, nu copil: o SINGURA scriere de transform pe cadru).
	_body = AnimatableBody3D.new()
	_body.name = "CartBody"
	_body.sync_to_physics = true
	add_child(_body)
	_body_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(cart_length - 0.2, BODY_HEIGHT, cart_width - 0.3)
	_body_shape.shape = box
	_body.add_child(_body_shape)
	_zone = Area3D.new()
	_zone.name = "HitZone"
	_zone.monitorable = true
	_zone_shape = CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(cart_length + zone_lead, BODY_HEIGHT + 0.6,
		cart_width + hit_margin_along * 2.0)
	_zone_shape.shape = zbox
	_zone_shape.disabled = true
	_zone.add_child(_zone_shape)
	_body.add_child(_zone)


# Primitive pe atlas, cu aceleasi nume de noduri ca modelul.
func _placeholder() -> Node3D:
	var root := Node3D.new()
	root.name = "GionPlaceholder"
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	body.add_child(PaletteBox.instance(Vector3(cart_length, 2.4, cart_width - 1.2),
		Palette.KERB_RED, Vector3(0.0, 2.2, 0.0)))
	body.add_child(PaletteBox.instance(Vector3(cart_length - 1.0, 2.2, cart_width - 1.8),
		Palette.LOG_DARK, Vector3(0.0, 4.5, 0.0)))
	body.add_child(PaletteBox.instance(Vector3(0.6, 11.0, 0.6),
		Palette.WOOD_WEATHERED, Vector3(0.0, 11.0, 0.0)))
	var k := 1
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			var w := Node3D.new()
			w.name = "Wheel_%d" % k
			k += 1
			w.position = Vector3(sx * WHEEL_X, WHEEL_RADIUS, sz * (cart_width * 0.5 - 0.3))
			w.add_child(PaletteBox.instance(Vector3(2.0, 2.0, 0.5), Palette.WOOD_WEATHERED))
			root.add_child(w)
	for nm in ["Puller_P1", "Puller_P2", "Puller_N1", "Puller_N2"]:
		var p := Node3D.new()
		p.name = nm
		var sx := 1.0 if nm.contains("_P") else -1.0
		var sz := 1.0 if nm.ends_with("1") else -1.0
		p.position = Vector3(sx * 1.9, 0.0, sz * 3.35)
		p.add_child(PaletteBox.instance(Vector3(0.5, 1.8, 0.5), Palette.KERB_RED,
			Vector3(0.0, 0.9, 0.0)))
		root.add_child(p)
	var m := Node3D.new()
	m.name = "Musicians"
	root.add_child(m)
	return root


## Profilul solului sub carul in miscare, prin raycast pe stratul terenului. Terenul se
## construieste dupa `_ready` (decorul/terenul sunt amanate), deci se reincearca cateva
## cadre fizice; la epuizarea bugetului ramane profilul plat (cota soselei).
func _build_ground_profile() -> void:
	if _ground_ready:
		return
	_ground_tries += 1
	var space := get_world_3d().direct_space_state
	var n := int(2.0 * GROUND_RANGE / GROUND_STEP)
	var any_hit := false
	var prof: Dictionary = {}
	for i in n + 1:
		var x := -GROUND_RANGE + float(i) * GROUND_STEP
		var g := to_global(Vector3(x, 0.0, 0.0))
		var q := PhysicsRayQueryParameters3D.create(g + Vector3.UP * 14.0, g + Vector3.DOWN * 14.0)
		q.collision_mask = Track.CAMERA_BLOCKER_LAYER
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		any_hit = true
		prof[i] = clampf((to_local(hit.position as Vector3) as Vector3).y, -2.0, 1.8)
	if not any_hit and _ground_tries < 20:
		return # mai incercam la urmatorul cadru fizic
	_ground_ready = true
	_ground = prof
	_apply_state()


# ------------------------------------------------------------------ starea

func _physics_process(delta: float) -> void:
	if not _ground_ready:
		_build_ground_profile()
	var prev := _clock
	_clock = fposmod(_clock + delta, total_seconds())
	_apply_state()
	_tick_audio(prev)
	_tick_cooldown(delta)
	if _zone_shape != null and not _zone_shape.disabled:
		_hit_cars()


## Starea vizuala si fizica ca functie PURA de `_clock` (si de profilul solului).
func _apply_state() -> void:
	if _cart == null:
		return
	var g := _clock
	var l := leg_index(g)
	var s := leg_time(g)
	var d := leg_dir(l)
	var x := cart_x_at(g)
	var v := cart_speed_at(g)
	var vfrac := clampf(absf(v) / maxf(peak_speed(), 0.01), 0.0, 1.0)
	var tu := telegraph_u(s)
	var cu := cross_u(s)

	# --- pozitia, cota si inclinarea dupa teren ---
	var y0 := ground_at(x - WHEEL_X)
	var y1 := ground_at(x + WHEEL_X)
	var pitch := clampf(atan2(y1 - y0, 2.0 * WHEEL_X), -0.25, 0.25)
	var gy := (y0 + y1) * 0.5
	# balans: telegraful il leagana tot mai tare, traversarea doar usor
	var rock := 0.0
	if cu <= 0.0:
		rock = sway_telegraph * tu * sin(g * TAU * 1.3)
	else:
		rock = sway_telegraph * 0.45 * vfrac * sin(g * TAU * 0.9)
	_cart.position = Vector3(x, gy, 0.0)
	_cart.rotation.z = pitch + rock

	# --- roti: unghiul urmeaza pozitia (rostogolire fara alunecare) ---
	var roll := -x / WHEEL_RADIUS
	for w in _wheels:
		if w != null:
			w.rotation.z = roll

	# --- trasatori: se opintesc in telegraf (spre spate), trag in traversare ---
	var front_p := d > 0.0 # echipa +X trage cand mergem spre +X
	var strain_back := 0.28 * tu * (1.0 - clampf(cu * 8.0, 0.0, 1.0))
	var lean_pull := 0.20 * clampf(cu * 6.0, 0.0, 1.0) * (1.0 - clampf((cu - 0.9) * 10.0, 0.0, 1.0))
	var bob := 0.07 * absf(sin(x * TAU / 1.15)) * (1.0 if absf(v) > 0.05 else 0.0)
	for i in _pullers.size():
		var p := _pullers[i]
		if p == null:
			continue
		var is_p := i < 2
		var is_front := (is_p == front_p)
		var toward := d # sensul de mers pe X local
		# rotatia pe Z cu semn: spre +X inseamna unghi negativ
		var a := 0.0
		if is_front:
			a = -toward * (lean_pull - strain_back)
		else:
			a = toward * (0.10 * clampf(cu * 6.0, 0.0, 1.0) + 0.5 * strain_back)
		p.rotation.z = a
		p.position = _puller_rest[i] + Vector3(0.0, bob, 0.0)

	# --- muzicantii: salt mic cat canta ---
	if _musicians != null:
		var music := 1.0 if audio_phase(g) > 0 else 0.0
		_musicians.position.y = _musicians_rest_y + music * 0.05 * absf(sin(g * TAU * 2.0))

	# --- corpul solid si zona de ghiont ---
	# O SINGURA scriere de transform pe cadru (memoria jolt-sync-transform-o-singura-scriere):
	# pozitia si rotatia separat se anuleaza reciproc pe un AnimatableBody3D sincronizat.
	_body.transform = Transform3D(Basis(Vector3.BACK, pitch),
		Vector3(x, gy + BODY_CENTER_Y, 0.0))
	var active := moving(g) and _edge_over_road(x, d)
	_zone_shape.disabled = not active
	_zone_shape.position = Vector3(d * zone_lead * 0.5, 0.2, 0.0)


# ------------------------------------------------------------------ sunet

## Doua bucle pozitionale (bus SFX, deci volumul din setari le tine): muzica
## (taiko + kane) de la inceputul telegrafului pana carul ajunge, si scartaitul
## rotilor cat se misca. Evenimentele se prind PE MARGINE in `_physics_process`
## (nu in `_apply_state`, care e pura si o apeleaza si `seek`), deci un `seek` nu
## cheama niciun sunet. Stream-ul se cere prin ARBORE, nu prin identificatorul
## autoload (vezi `daruma_otoshi_hazard.gd::_sfx`).
func _build_audio() -> void:
	_music_audio = AudioStreamPlayer3D.new()
	_music_audio.bus = &"SFX"
	_music_audio.max_distance = music_max_distance
	_music_audio.unit_size = music_unit_size
	_music_audio.volume_db = music_db
	_cart.add_child(_music_audio)
	_music_audio.position = Vector3(0.0, 5.0, 0.0)
	_wheels_audio = AudioStreamPlayer3D.new()
	_wheels_audio.bus = &"SFX"
	_wheels_audio.max_distance = music_max_distance * 0.6
	_wheels_audio.unit_size = music_unit_size * 0.5
	_wheels_audio.volume_db = wheels_db
	_cart.add_child(_wheels_audio)
	_wheels_audio.position = Vector3(0.0, 1.0, 0.0)


func _sfx(sfx_name: StringName) -> AudioStream:
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null:
		return null
	return manager.call("stream", sfx_name)


func _tick_audio(_prev_clock: float) -> void:
	if _music_audio == null:
		return
	var ph := audio_phase(_clock)
	if ph != _audio_phase:
		if ph == 1:
			telegraphs += 1
		if _audio_phase == 2 and ph == 0:
			crossings += 1
		_audio_phase = ph
		if ph >= 1:
			var music := _sfx(&"gion_bayashi")
			if music != null and not _music_audio.playing:
				_music_audio.stream = music
				_music_audio.play()
		else:
			_music_audio.stop()
		if ph == 2:
			var wheels := _sfx(&"gion_wheels")
			if wheels != null:
				_wheels_audio.stream = wheels
				_wheels_audio.play()
		else:
			_wheels_audio.stop()
	if ph == 2:
		var vf := clampf(absf(cart_speed_at(_clock)) / maxf(peak_speed(), 0.01), 0.05, 1.0)
		_wheels_audio.volume_db = wheels_db + linear_to_db(vf)
		_wheels_audio.pitch_scale = lerpf(0.8, 1.1, vf)


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
	for b in _zone.get_overlapping_bodies():
		var car := b as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = hit_cooldown
		_throw_car(car)


func _throw_car(car: Car) -> void:
	var ratio := clampf(reference_mass / maxf(car.mass, 1.0), 0.4, 1.4)
	var keep := clampf(keep_speed + keep_per_mass * (car.mass / reference_mass - 1.0),
		0.1, 0.95)
	var d := leg_dir(leg_index(_clock))
	# Directia carului in lume (orizontala): pe X local, cu semnul mersului.
	var dir := global_transform.basis.x * d
	dir.y = 0.0
	dir = dir.normalized()
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	# Spre exterior (`side`) impinsul e mai mic: acolo nu e loc ca pe gazon.
	var out_f := push_outward_factor if signf(d) == float(side) else 1.0
	# DOAR componenta pe sensul de mers: lateralul din cadrul loviturii e al solverului,
	# nu al soferului, si nu trebuie sa se adune la impinsul hotarat de hazard.
	var along := car.velocity.dot(fwd)
	var horizontal := fwd * along * keep + dir * push_speed * ratio * out_f
	HazardThrow.throw(car, _body, horizontal, throw_rise * ratio, clear_seconds)
	var sgn := signf(dir.cross(Vector3.UP).dot(-car.global_transform.basis.z))
	car.spin_body(spin_rate * ratio * (sgn if absf(sgn) > 0.01 else 1.0), spin_seconds)
	car.crush(crush_seconds, crush_factor, Vector3(1.2, 0.62, 1.2), 1.0)
	throws += 1
	car_thrown.emit(car)
