class_name DarumaOtoshiHazard
extends Node3D
## Daruma-otoshi (Kyoto, Track18, POI F): jucaria japoneza cu ciocanel, la scara de
## jucarie. Un turn de 5 discuri colorate cu un cap de daruma deasupra, pe marginea
## EXTERIOARA a drumului; un ciocan de lemn mare, pe un brat cu pivot, in spatele
## turnului. Ciocanul se trage inapoi incet (telegraful, ~3 s), apoi loveste discul
## de JOS, care ALUNECA peste drum ca o puca, perpendicular pe sosea, si iese in
## iarba din interior. Turnul coboara un etaj, cu o mica saritura de jucarie.
##
## Inlocuieste `ShishiOdoshiHazard` (decizia dezvoltatorului, 3 oct 2026: tubul nu
## se citea, „arata ca o pompa"). Clasa veche ramane in repo, neatinsa.
##
## [b]Doua ceasuri, o stare pura[/b]. `_clock` e ceasul MARE, in secunde, peste
## tot ciclul: 5 perioade de lovitura (`strike_period`, ~13 s) + o reconstructie
## (`rebuild_seconds`). Tot ce se vede (unghiul ciocanului, ce disc zboara, cat de
## jos e turnul) e o functie PURA de `_clock` (`_apply_state`), deci `seek` /
## `force_clock` pun orice faza, la fel pentru sonde si pentru capturi. Inaltimea
## turnului spune si unde esti in ciclul mare: 5 discuri = abia a inceput, doar
## capul = urmeaza reconstructia.
##
## [b]Perioada de lovitura[/b] (s, in perioada): repaus -> ciocanul se trage inapoi
## (`windup_seconds`) -> ramane tensionat (`hold_seconds`) -> LOVITURA
## (`swing_seconds`, pana la `hit_at`) -> discul aluneca (`slide_seconds`) si se
## strange la nimic -> turnul coboara un etaj. Dupa al 5-lea disc, ramane doar capul, iar
## turnul creste la loc (`rebuild_seconds`), disc cu disc, de jos in sus.
##
## [b]Geometria[/b]: radacina sta PE AXA soselei, cu fata pe sensul de mers (-Z), ca
## `ShishiOdoshiHazard` si `WaterHazard`. `side` = +1 are turnul pe dreapta (+X),
## -1 pe stanga. Centrul turnului sta la `road_half_width + tower_gap + disc_r` de
## axa; discul loveste spre interior (-side), traverseaza toata latimea soselei si
## iese pe partea opusa. Nu exista banda libera: ca la un tren, scapi prin TIMING.
##
## [b]Fara corp aparut in masina[/b] (memoria `corp-cinematic-aparut-in-masina`).
## Discul in miscare are un `AnimatableBody3D`, dar aruncarea NU o face solverul: o
## zona (`_zone`) merge cu `zone_lead` metri INAINTEA discului, prinde masina si o
## arunca pe directia discului prin [HazardThrow] (orizontala se scrie, verticala
## prin `Car.launch`, exceptie de coliziune cat tine zborul). Discul porneste din
## turn, de pe marginea drumului, nu din interiorul unei masini.
##
## [b]Masa conteaza[/b]: `ratio = masa_de_referinta / masa_masinii` taie impinsul si
## inaltimea (Autobuzul e impins putin, Buggy-ul zboara), iar masa grea PASTREAZA
## mai mult din viteza inainte (`keep_speed`). Fara oprire si fara distrugere.
##
## [b]AI onest[/b]: AI-ul citeste ciclul (`blocks_between` pe fereastra lui de sosire
## [rapid, lent], `window_rel`) si NU franeaza pana la oprire: ridica piciorul (pana
## la o fractie din croaziera) ca sa treaca DUPA disc, sau trece inainte. Vezi
## `ai_controller.gd::_daruma_cap`.
##
## [b]Contractul modelului[/b] (`daruma_otoshi.glb`, scris inainte de Blender; daca
## difera, codul castiga). Originea radacinii = axa turnului, LA SOL (cota
## soselei); +X = spre EXTERIOR (departe de drum), +Z = FATA (spre masina care
## vine), +Y = sus:
##   `Base`      soclul/placa pe care sta turnul (static)
##   `Disc_1`..`Disc_5`  discurile, de jos in sus; originea fiecaruia = CENTRUL
##               BAZEI lui, pozitionat pe etajul lui (y = base_height +
##               (j-1) * disc_height); codul le coboara, le creste (scale.y) si
##               zboara `Disc_k` in lovitura
##   `Head`      capul de daruma (originea la baza, deasupra lui `Disc_5`; fata
##               pe +Z, ochii si gura pictate)
##   `Hammer`    ciocanul: ORIGINEA = axa pivotului (paralela cu Z), la
##               (hammer_u, pivot_y, 0); geometria atarna sub origine; codul
##               scrie `rotation.z` (+ = capul spre exterior, adica tras inapoi)
##   `Frame`     cadrul pivotului (doi stalpi + axa), static
## Fara el, un placeholder din primitive cu aceleasi nume de noduri.

## Grupul pe care il citeste `AIController`.
const AI_GROUP: StringName = &"daruma_otoshi"
const LEVELS: int = 5

signal car_thrown(car: Car)

@export_group("Ciclul")
## Durata unei perioade de lovitura (s). 13 nu imparte turul de ~75 s.
@export_range(6.0, 30.0, 0.5) var strike_period: float = 13.0
## Ciocanul se trage inapoi: telegraful, vizibil de departe.
@export_range(0.5, 8.0, 0.1) var windup_seconds: float = 3.0
## Ramane tensionat (tremura) inainte de lovitura.
@export_range(0.0, 2.0, 0.05) var hold_seconds: float = 0.5
## Lovitura propriu-zisa, de la varf pana la contact.
@export_range(0.1, 1.0, 0.01) var swing_seconds: float = 0.25
## Momentul contactului in perioada (s). Dupa el mai raman `strike_period - hit_at`
## secunde pentru alunecare (se termina cu ~2 s inainte de urmatoarea ridicare).
@export_range(3.0, 30.0, 0.1) var hit_at: float = 11.0
## Turnul creste la loc dupa al 5-lea disc.
@export_range(2.0, 12.0, 0.5) var rebuild_seconds: float = 6.0
## Ceasul de la care porneste (s) — decaleaza hazardele intre ele.
@export_range(0.0, 120.0, 0.1) var start_clock: float = 0.0

@export_group("Turnul")
## +1 = turnul pe dreapta sensului de mers (+X local), -1 = stanga.
@export_range(-1, 1, 2) var side: int = 1
## Semilatimea soselei in punctul turnului (m). 0 = nu se atinge `road_width`.
@export var road_half_width: float = 0.0
## Distanta (m) intre marginea soselei si fata dinspre drum a turnului.
@export_range(0.2, 5.0, 0.1) var tower_gap: float = 1.7
@export_range(1.5, 3.5, 0.1) var disc_diameter: float = 4.0
@export_range(0.6, 2.0, 0.05) var disc_height: float = 1.3
## Grosimea placii pe care sta turnul (m).
@export_range(0.0, 0.6, 0.02) var base_height: float = 0.12
## Inaltimea capului de daruma (m), pentru colizorul turnului.
@export_range(1.0, 4.0, 0.1) var head_height: float = 2.4
## Un model de la Blender; gol = placeholder.
@export var model: PackedScene
## Intoarce turnul pe verticala (grade) ca sa priveasca spre mersul masinii care
## vine (curba nu e paralela cu +Z).
@export_range(-90.0, 90.0, 1.0) var face_yaw_deg: float = 0.0

@export_group("Ciocanul")
## Distanta (m) de la axa turnului la axa pivotului, spre exterior.
@export_range(1.0, 6.0, 0.1) var hammer_u: float = 3.05
## De la axa pivotului la centrul capului de ciocan (m).
@export_range(2.0, 8.0, 0.1) var hammer_length: float = 5.02
@export_range(0.4, 1.6, 0.05) var hammer_head_radius: float = 0.95
## Cat de departe se trage inapoi (grade).
@export_range(20.0, 90.0, 1.0) var pull_back_deg: float = 72.0
## Cat trece de vertical dupa lovitura (grade).
@export_range(0.0, 25.0, 1.0) var overswing_deg: float = 10.0

@export_group("Discul")
## Cat de departe ajunge discul (m, de la centrul turnului), pe `slide_seconds`.
@export_range(14.0, 40.0, 0.5) var slide_distance: float = 22.0
@export_range(0.8, 4.0, 0.1) var slide_seconds: float = 2.0
@export_range(0.0, 12.0, 0.5) var spin_rate_disc: float = 7.0
## Cat inaintea discului porneste zona de ghiont (m).
@export_range(0.5, 4.0, 0.1) var zone_lead: float = 1.8
## In plus fata de diametrul discului, pe sensul de mers (m, de fiecare parte).
@export_range(0.0, 3.0, 0.1) var hit_margin_along: float = 0.9

@export_group("Aruncarea")
## Masa de referinta (Buggy = 100): raportul ei la masa masinii scaleaza efectul.
@export var reference_mass: float = 100.0
## Impinsul pe directia discului, pentru masa de referinta (m/s).
@export_range(0.0, 30.0, 0.5) var push_speed: float = 11.0
## Inaltimea zborului pentru masa de referinta (m).
@export_range(0.0, 4.0, 0.1) var throw_rise: float = 1.4
## Din viteza inainte, cat ramane la masa de referinta; masa mai mare tine mai mult.
@export_range(0.0, 1.0, 0.05) var keep_speed: float = 0.15
@export_range(0.0, 1.0, 0.05) var keep_per_mass: float = 0.2
@export_range(0.0, 8.0, 0.1) var spin_rate: float = 4.0
@export_range(0.0, 2.0, 0.05) var spin_seconds: float = 0.6
@export_range(0.0, 2.0, 0.05) var crush_seconds: float = 0.4
@export_range(0.3, 1.0, 0.05) var crush_factor: float = 0.7
@export_range(0.2, 3.0, 0.1) var clear_seconds: float = 1.4
@export_range(0.1, 4.0, 0.1) var hit_cooldown: float = 1.5
## Marja pe fereastra de pericol pentru AI (s), de fiecare parte.
@export_range(0.0, 1.5, 0.05) var ai_margin: float = 0.35

## Latimea soselei (m) la tur; `road_half_width` o suprascrie.
var road_width: float = 11.0

## Contoare pentru sonde.
var throws: int = 0

var _clock: float = 0.0
var _tower: Node3D # radacina modelului (centrul turnului, la sol)
var _discs: Array[Node3D] = []
var _disc_rest: Array[Vector3] = []
var _head: Node3D
var _head_rest_y: float = 0.0
var _hammer: Node3D
var _tower_body: StaticBody3D
var _tower_shape: CollisionShape3D
var _body: AnimatableBody3D
var _body_shape: CollisionShape3D
var _zone: Area3D
var _zone_shape: CollisionShape3D
var _splash: CPUParticles3D
var _splashed_period: int = -1
var _cooldown: Dictionary = {}
var _win_lo: float = 0.0 # fata de `hit_at`: de cand incepe pericolul (s, <= 0)
var _win_hi: float = 0.0 # pana cand discul a eliberat soseaua (s, > 0)


func _ready() -> void:
	if road_half_width > 0.0:
		road_width = road_half_width * 2.0
	_clock = fposmod(start_clock, total_seconds())
	add_to_group(AI_GROUP)
	_build_rig()
	recompute_windows()
	_apply_state()


# ------------------------------------------------------------------ ciclul

## Durata ciclului mare (s): 5 perioade de lovitura + reconstructia.
func total_seconds() -> float:
	return strike_period * float(LEVELS) + rebuild_seconds


func clock() -> float:
	return _clock


## Perioada curenta: 0..4 = perioade de lovitura, 5 = reconstructia.
func period_index(g: float) -> int:
	return mini(int(g / strike_period), LEVELS)


## Secunde de la inceputul perioadei.
func period_time(g: float) -> float:
	return g - float(period_index(g)) * strike_period


## Cate discuri a pierdut turnul la ceasul `g`, ca numar real (0..5). In
## perioada k creste de la k la k+1 pe saritura de dupa lovitura.
func drop_level(g: float) -> float:
	var k := period_index(g)
	if k >= LEVELS:
		return float(LEVELS)
	var s := period_time(g)
	var u := clampf((s - (hit_at + 0.25)) / 0.5, 0.0, 1.0)
	return float(k) + _hop(u)


## Saritura de jucarie: cade, loveste pe jos si sare putin inapoi.
func _hop(u: float) -> float:
	if u <= 0.0:
		return 0.0
	if u >= 1.0:
		return 1.0
	if u < 0.6:
		var f := u / 0.6
		return f * f
	return 1.0 - 0.12 * sin(PI * (u - 0.6) / 0.4)


## Cat de mult a crescut turnul (0..5) in reconstructie, ca numar real.
func rebuild_level(s: float) -> float:
	var step := (rebuild_seconds - 0.9) / float(LEVELS)
	var n := 0.0
	for i in LEVELS:
		var t0 := 0.4 + float(i) * step
		var u := clampf((s - t0) / 0.5, 0.0, 1.0)
		# iese cu un mic depasire, ca un resort
		n += _ease_out_back(u)
	return n


func _ease_out_back(u: float) -> float:
	if u <= 0.0:
		return 0.0
	if u >= 1.0:
		return 1.0
	var c1 := 1.4
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(u - 1.0, 3.0) + c1 * pow(u - 1.0, 2.0)


## Unghiul ciocanului (rad, + = capul spre exterior) in perioada de lovitura,
## la `s` secunde de la inceputul ei.
func hammer_angle(s: float) -> float:
	var pull := deg_to_rad(pull_back_deg)
	var s_swing := hit_at - swing_seconds
	var s_hold := s_swing - hold_seconds
	var s_back := s_hold - windup_seconds
	if s < s_back:
		return 0.0
	if s < s_hold:
		var u := (s - s_back) / windup_seconds
		var e := u * u * (3.0 - 2.0 * u)
		# scartaie si tremura pe ultimul sfert: telegraful final
		var shake := 0.0
		if u > 0.7:
			shake = deg_to_rad(1.6) * sin(s * 38.0) * (u - 0.7) / 0.3
		return pull * e + shake
	if s < s_swing:
		return pull + deg_to_rad(1.6) * sin(s * 38.0)
	if s < hit_at:
		var u := (s - s_swing) / swing_seconds
		return pull * (1.0 - u * u)
	var v := s - hit_at
	return -deg_to_rad(overswing_deg) * exp(-4.5 * v) * sin(9.0 * v) * 1.5


## Cat a parcurs discul (m, de la centrul turnului) la `tau` secunde de la lovitura.
func disc_distance(tau: float) -> float:
	if tau <= 0.0:
		return 0.0
	if tau >= slide_seconds:
		return slide_distance
	var x := 1.0 - tau / slide_seconds
	return slide_distance * (1.0 - x * x)


func tower_center_x() -> float:
	return float(side) * (road_width * 0.5 + tower_gap + disc_diameter * 0.5)


## Centrul discului, in spatiul radacinii, la `tau` de la lovitura (pe sol).
func disc_center(tau: float) -> Vector3:
	return Vector3(tower_center_x() - float(side) * disc_distance(tau),
		_disc_bottom_y(tau) + disc_height * 0.5, 0.0)


func _disc_bottom_y(tau: float) -> float:
	var d := disc_distance(tau)
	var t := smoothstep(0.0, 2.5, d)
	var y := lerpf(base_height, 0.03, t)
	return y


## Discul e in miscare (a plecat din turn si nu s-a strans inca)?
func disc_flying(g: float) -> bool:
	var k := period_index(g)
	if k >= LEVELS:
		return false
	var tau := period_time(g) - hit_at
	return tau >= 0.0 and tau < slide_seconds + 0.8


## `tau` de la lovitura pana cand discul a eliberat soseaua (s), dupa distanta.
func crossing_clear_tau() -> float:
	# marginea de IESIRE a discului trece de marginea opusa: tx + hw + r, adica
	# 2*hw + gap + 2*r
	var need := road_width + tower_gap + disc_diameter
	var lo := 0.0
	var hi := slide_seconds
	for _i in 30:
		var mid := (lo + hi) * 0.5
		if disc_distance(mid) < need:
			lo = mid
		else:
			hi = mid
	return hi


## Cand (in raport cu `hit_at`) e periculos: zona pornita, pana discul a iesit.
func recompute_windows() -> void:
	_win_lo = -0.3
	_win_hi = crossing_clear_tau() + 0.1


## Fereastra de pericol, relativa la `hit_at` (s).
func danger_window() -> Vector2:
	return Vector2(_win_lo, _win_hi)


## Prima fereastra de pericol care se termina dupa `t_from` secunde de acum:
## (inceput, sfarsit) in secunde RELATIVE la acum. Dupa ultima perioada de
## lovitura cade pe prima din ciclul urmator.
func window_rel(t_from: float) -> Vector2:
	var g := _clock + t_from
	var total := total_seconds()
	var base := floorf(g / total) * total
	var gl := g - base
	for k in LEVELS:
		var a := base + float(k) * strike_period + hit_at + _win_lo
		var b := base + float(k) * strike_period + hit_at + _win_hi
		if gl <= b - base:
			return Vector2(a - _clock, b - _clock)
	var a2 := base + total + hit_at + _win_lo
	var b2 := base + total + hit_at + _win_hi
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


## Punctul de pe axa soselei unde e turnul (pentru indexul de pista al AI-ului).
func ai_decision_point() -> Vector3:
	return global_position


## Directia „spre exterior" in lume (orizontala, spre partea turnului).
func outward() -> Vector3:
	var o := global_transform.basis.x * float(side)
	o.y = 0.0
	return o.normalized()


## Semi-lungimea zonei de pericol pe sensul de mers (m).
func footprint_half() -> float:
	return disc_diameter * 0.5 + hit_margin_along


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


func hammer_node() -> Node3D:
	return _hammer


func tower_node() -> Node3D:
	return _tower


func disc_node(i: int) -> Node3D:
	return _discs[i]


## Cate discuri are turnul acum in picioare (pentru sonde).
func visible_discs() -> int:
	var n := 0
	for d in _discs:
		if d.visible:
			n += 1
	return n


# ------------------------------------------------------------ constructia

func _build_rig() -> void:
	_tower = Node3D.new()
	_tower.name = "Tower"
	add_child(_tower)
	_tower.position = Vector3(tower_center_x(), 0.0, 0.0)
	# Modelul are +X = exterior; pe stanga se intoarce cu 180 de grade.
	var yaw := 0.0 if side > 0 else PI
	_tower.rotation.y = yaw + deg_to_rad(face_yaw_deg) * float(side)

	var root: Node3D = null
	if model != null:
		root = model.instantiate() as Node3D
	if root == null or root.find_child("Hammer", true, false) == null:
		root = _placeholder()
	_tower.add_child(root)
	# Materialul lumii (atlasul de paleta + AO din vertex color): zero materiale
	# in plus fata de placeholder.
	Palette.apply_world_material(root)
	_discs.clear()
	_disc_rest.clear()
	for i in LEVELS:
		var d := root.find_child("Disc_%d" % (i + 1), true, false) as Node3D
		_discs.append(d)
		_disc_rest.append(d.position)
	_head = root.find_child("Head", true, false) as Node3D
	_head_rest_y = _head.position.y
	_hammer = root.find_child("Hammer", true, false) as Node3D
	if side < 0:
		# Fata capului ramane spre masina care vine, nu se roteste cu turnul.
		_head.rotation.y += PI

	# Turnul si stalpii ciocanului sunt solizi (static): coliziune cu masinile care
	# ies de pe drum. Inaltimea turnului urmeaza numarul de etaje.
	_tower_body = StaticBody3D.new()
	_tower_body.name = "TowerBody"
	_tower.add_child(_tower_body)
	_tower_shape = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = disc_diameter * 0.5
	cyl.height = 6.0
	_tower_shape.shape = cyl
	_tower_body.add_child(_tower_shape)
	for sz in [-1.0, 1.0]:
		var post := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.9, hammer_length + 1.6, 0.9)
		post.shape = box
		post.position = Vector3(hammer_u, (hammer_length + 1.6) * 0.5, sz * 1.9)
		_tower_body.add_child(post)

	# Discul in miscare: corp cinematic + zona de ghiont care il precede. Frate cu
	# turnul (nu copil): o SINGURA scriere de transform pe cadru.
	_body = AnimatableBody3D.new()
	_body.name = "DiscBody"
	_body.sync_to_physics = true
	add_child(_body)
	_body_shape = CollisionShape3D.new()
	var dcyl := CylinderShape3D.new()
	dcyl.radius = disc_diameter * 0.5
	dcyl.height = disc_height
	_body_shape.shape = dcyl
	_body_shape.disabled = true
	_body.add_child(_body_shape)
	_zone = Area3D.new()
	_zone.name = "HitZone"
	_zone.monitorable = true
	_zone_shape = CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(disc_diameter + zone_lead,
		disc_height + 0.8, disc_diameter + hit_margin_along * 2.0)
	_zone_shape.shape = zbox
	_zone_shape.position = Vector3(-float(side) * zone_lead * 0.5, 0.0, 0.0)
	_zone_shape.disabled = true
	_zone.add_child(_zone_shape)
	_body.add_child(_zone)

	_splash = CPUParticles3D.new()
	_splash.name = "Splash"
	_splash.one_shot = true
	_splash.emitting = false
	_splash.amount = 28
	_splash.lifetime = 0.9
	_splash.explosiveness = 1.0
	_splash.mesh = PaletteBox.mesh(Vector3(0.3, 0.3, 0.3), Palette.SAND_MID)
	_splash.direction = Vector3.UP
	_splash.spread = 38.0
	_splash.initial_velocity_min = 3.0
	_splash.initial_velocity_max = 6.5
	_splash.gravity = Vector3(0.0, -12.0, 0.0)
	_splash.scale_amount_min = 0.7
	_splash.scale_amount_max = 1.5
	add_child(_splash)
	_splash.position = Vector3(tower_center_x() - float(side) * slide_distance,
		0.2, 0.0)
	_place_body(0.0, false)


# Primitive pe atlas, cu aceleasi nume de noduri ca modelul.
func _placeholder() -> Node3D:
	var root := Node3D.new()
	root.name = "DarumaPlaceholder"
	var r := disc_diameter * 0.5
	var base := Node3D.new()
	base.name = "Base"
	root.add_child(base)
	base.add_child(_cyl_instance(r + 0.5, base_height, Palette.ROCK_LIGHT,
		Vector3.ZERO))
	var slots := [Palette.LAVA_ORANGE, Palette.REEF_SHALLOW, Palette.SAND_LIGHT,
		Palette.TROPICAL_GREEN, Palette.FLAMINGO_PINK]
	for i in LEVELS:
		var d := Node3D.new()
		d.name = "Disc_%d" % (i + 1)
		d.position = Vector3(0.0, base_height + float(i) * disc_height, 0.0)
		d.add_child(_cyl_instance(r, disc_height, slots[i], Vector3.ZERO))
		root.add_child(d)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, base_height + float(LEVELS) * disc_height, 0.0)
	head.add_child(_cyl_instance(r * 0.78, head_height, Palette.KERB_RED, Vector3.ZERO))
	# fata: o placa alba cu doi ochi, pe +Z
	head.add_child(PaletteBox.instance(Vector3(r * 1.0, head_height * 0.5, 0.1),
		Palette.FOAM_WHITE, Vector3(0.0, head_height * 0.55, r * 0.74)))
	for ex in [-0.4, 0.4]:
		head.add_child(PaletteBox.instance(Vector3(0.28, 0.28, 0.12),
			Palette.LOG_DARK, Vector3(ex, head_height * 0.62, r * 0.78)))
	root.add_child(head)
	var frame := Node3D.new()
	frame.name = "Frame"
	root.add_child(frame)
	for sz in [-1.0, 1.0]:
		frame.add_child(PaletteBox.instance(
			Vector3(0.7, hammer_length + 1.6, 0.7), Palette.WOOD_WEATHERED,
			Vector3(hammer_u, (hammer_length + 1.6) * 0.5, sz * 1.9)))
	var pivot_y := 0.95 + hammer_length # centrul maciucii in repaus: 0,95 m (talpa la sol)
	var hammer := Node3D.new()
	hammer.name = "Hammer"
	hammer.position = Vector3(hammer_u, pivot_y, 0.0)
	hammer.add_child(PaletteBox.instance(
		Vector3(0.35, hammer_length, 0.35), Palette.WOOD_WEATHERED,
		Vector3(0.0, -hammer_length * 0.5, 0.0)))
	var hh := _cyl_instance(hammer_head_radius, 2.2, Palette.LOG_DARK,
		Vector3(0.0, -hammer_length, 0.0))
	hh.rotation.x = PI * 0.5
	hammer.add_child(hh)
	root.add_child(hammer)
	return root


func _cyl_instance(radius: float, height: float, slot: int, at: Vector3) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	var seg := 14 # 14 laturi: 56 triunghiuri pe cilindru
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var p0 := Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		var up := Vector3(0.0, height, 0.0)
		var n := Vector3(cos((a0 + a1) * 0.5), 0.0, sin((a0 + a1) * 0.5))
		for tri in [[p0, p0 + up, p1 + up], [p0, p1 + up, p1]]:
			for v: Vector3 in tri:
				st.set_normal(n)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(v)
		for cap in [[Vector3.ZERO + up, p0 + up, p1 + up, Vector3.UP],
				[Vector3.ZERO, p1, p0, Vector3.DOWN]]:
			for k in 3:
				st.set_normal(cap[3])
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(cap[k])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = at
	return mi


# ------------------------------------------------------------------ starea

func _physics_process(delta: float) -> void:
	_clock = fposmod(_clock + delta, total_seconds())
	_apply_state()
	_tick_cooldown(delta)
	if _zone_shape != null and not _zone_shape.disabled:
		_hit_cars()


## Starea vizuala si fizica ca functie PURA de `_clock`.
func _apply_state() -> void:
	if _tower == null:
		return
	var g := _clock
	var k := period_index(g)
	var s := period_time(g)
	var h := disc_height

	# --- discurile si capul ---
	if k >= LEVELS:
		var n := rebuild_level(s)
		for i in LEVELS:
			var p := clampf(n - float(i), 0.0, 1.0)
			var d := _discs[i]
			d.visible = p > 0.02
			d.position = _disc_rest[i]
			d.scale = Vector3(1.0, maxf(p, 0.001), 1.0)
			d.rotation = Vector3.ZERO
		_head.position.y = _head_rest_y - (float(LEVELS) - n) * h
		_hammer.rotation.z = 0.0
		_set_tower_height(n)
		_flying_off()
		return
	var dl := drop_level(g)
	for i in LEVELS:
		var d := _discs[i]
		d.scale = Vector3.ONE
		if i < k:
			d.visible = false
			continue
		if i == k:
			# discul lovit: sta pe loc pana la lovitura, apoi zboara
			var tau := s - hit_at
			if tau < 0.0:
				d.visible = true
				d.position = _disc_rest[i] - Vector3(0.0, dl * h, 0.0)
				d.rotation = Vector3.ZERO
			else:
				var fly := tau < slide_seconds + 0.8
				d.visible = fly
				var c := disc_center(tau)
				d.position = Vector3(-disc_distance(tau), _disc_bottom_y(tau), 0.0)
				var tt := minf(tau, slide_seconds)
				d.rotation.y = spin_rate_disc * (tt - tt * tt / (2.0 * slide_seconds))
				# oprit, mai sta o clipa, apoi se strange la nimic cu un nor de praf
				var vanish := clampf((tau - slide_seconds - 0.3) / 0.4, 0.0, 1.0)
				d.scale = Vector3.ONE * (1.0 - vanish)
				_place_body(tau, tau < slide_seconds and _on_road_window(c))
			continue
		d.visible = true
		d.rotation = Vector3.ZERO
		d.position = _disc_rest[i] - Vector3(0.0, dl * h, 0.0)
	_head.position.y = _head_rest_y - dl * h
	_hammer.rotation.z = hammer_angle(s)
	_set_tower_height(float(LEVELS) - dl)
	if s < hit_at:
		_flying_off()
		_splashed_period = -1
	# norul de praf, o singura data pe perioada, cand discul se strange
	elif s - hit_at >= slide_seconds + 0.3 and _splashed_period != k:
		_splashed_period = k
		_splash.restart()
		_splash.emitting = true


func _flying_off() -> void:
	if _body_shape != null:
		_body_shape.disabled = true
		_zone_shape.disabled = true


func _on_road_window(c: Vector3) -> bool:
	var reach := road_width * 0.5 + disc_diameter * 0.5 + zone_lead + 0.6
	return absf(c.x) < reach


func _place_body(tau: float, active: bool) -> void:
	if _body == null:
		return
	_body.position = disc_center(maxf(tau, 0.0))
	_body_shape.disabled = not active
	_zone_shape.disabled = not active


func _set_tower_height(levels: float) -> void:
	if _tower_shape == null:
		return
	var h := base_height + maxf(levels, 0.0) * disc_height + head_height
	(_tower_shape.shape as CylinderShape3D).height = h
	_tower_shape.position.y = h * 0.5


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
	var dir := -outward() # directia discului: spre interior
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	# DOAR componenta pe sensul de mers: lateralul din cadrul loviturii e al
	# solverului, nu al soferului, si nu trebuie sa se adune la impinsul hotarat de
	# hazard.
	var along := car.velocity.dot(fwd)
	var horizontal := fwd * along * keep + dir * push_speed * ratio
	HazardThrow.throw(car, _body, horizontal, throw_rise * ratio, clear_seconds)
	var sgn := signf(dir.cross(Vector3.UP).dot(-car.global_transform.basis.z))
	car.spin_body(spin_rate * ratio * (sgn if absf(sgn) > 0.01 else 1.0),
		spin_seconds)
	car.crush(crush_seconds, crush_factor, Vector3(1.2, 0.62, 1.2), 1.0)
	throws += 1
	car_thrown.emit(car)
