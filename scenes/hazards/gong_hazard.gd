class_name GongHazard
extends Node3D
## GONGUL DE TEMPLU (Angkor, Track24, nava templului): un disc mare de bronz atarnat in
## franghii de tavan, jos peste drum, intr-o banda. E un PENDUL FIZIC, nu un ceas: neatins
## sta nemiscat; masina care intra in el il trimite in leagan inainte-inapoi, iar cum iese
## din lovitura depinde de masa (principiul 1 din CLAUDE.md: masina grea impinge, cea usoara
## zboara). Un gong care se leagana e apoi obstacol mobil pentru plutonul din spate.
##
## [b]Fizica: corp rigid pe balama, plus trei forte proprii.[/b] Discul e un `RigidBody3D`
## legat cu un `HingeJoint3D` de o ancora statica (fara forma), cu axa balamalei DE-A
## CURMEZISUL drumului (X local): se misca doar inainte-inapoi si nu-si paraseste banda.
## Schimbul de impuls cu masina il face solverul (Jolt), deci raportul de mase iese singur.
## Ce adauga scriptul, in `_physics_process`, pe centrul de masa:
##   - amortizarea liniara `damping` (1/s): stinge leganatul mic in ~15 s;
##   - frana patratica `drag` (1/m, a = drag * v^2): o lovitura de autobuz ar trimite
##     discul peste pivot; frana taie varful de viteza fara sa atinga leganatul mic;
##   - opritorul moale: in ultimele `soft_zone_deg` grade inainte de `swing_limit_deg`,
##     iesind spre limita, o amortizare puternica (`soft_stop`, 1/s). Limita balamalei ramane
##     plasa de siguranta, dar in Jolt e MOALE: izbit fara opritor, discul o depaseste cu 2-7°
##     (masurat: 72° la 10 m/s, 77° la 20 m/s, cu limita 70°). Cu opritorul nu ajunge la ea.
## Valorile implicite sunt masurate cu `tools/ProbeGong.tscn` (tabelul e in antetul sondei):
## autobuzul pastreaza 95% din viteza la 1 s, buggy-ul 74%, tuk-tuk-ul 34%; o lovitura de
## buggy da 59° si se stinge sub 2° in 15 s (un tur are ~80 s); cel mai mare unghi masurat e
## 66°, autobuzul intrand in gongul care se intoarce.
##
## [b]De ce balama si nu pendul integrat de mana[/b]: am masurat intai varianta ceruta (corp
## rigid pe `HingeJoint3D`) si n-a avut nevoie de alternativa: fara NaN, fara masini prinse
## sub disc (blocaj max 0,2 s), fara prastie (nicio masina peste 1,00x referinta), disc
## prins la 3,5 cm in cea mai grea lovitura. Singura capcana a fost masca (mai jos).
##
## [b]Doar masinile il ating.[/b] Discul sta pe stratul decorului lovibil (`BumpProp.LAYER`,
## 9) cu masca 1. Masina il loveste (Car isi pune stratul 9 in masca), dar razele suspensiei,
## camera si cautarea de loc la repunere (masca 1) nu-l vad, iar alte gonguri (strat 9, masca
## 1) nu se vad intre ele. Masca 1 NU e optionala: in Jolt o coliziune vazuta dintr-o singura
## parte (masina vede discul, discul nu vede masina) se rezolva cu discul de masa INFINITA —
## masurat: Buggy-ul la 27 m/s ricosa inapoi cu 5,7 m/s, discul nu se clintea. Cu masca 1
## discul ar vedea si peretii si solul, dar pendulul nu-i atinge: se misca doar pe banda lui,
## iar cel mai jos punct al lui e chiar pozitia de repaus (buza la `center_height - radius`).
## Pe `BumpProp` (masca 1|9, deci il vede) discul isi pune exceptii de coliziune
## (`_except_bump_props`), dupa primul pas de fizica, cand piesele pistei exista deja.
## Masina trateaza orice `RigidBody3D` lovit ca pe o popica (`Car._process_contacts` ii da un
## ghiont scalat cu masa ei, in fiecare tick de contact) — gongul il primeste si el, si e in
## cifrele masurate.
##
## [b]Sunetul[/b]: o lovitura e un salt al vitezei unghiulare (`ring_min_dw`, rad/s intr-un
## tick) cu o masina in contact; gravitatia si fortele de mai sus dau sub 0,05 rad/s pe tick.
## Un singur `ring_sfx` per lovitura, cu pauza `ring_cooldown` (o masina sprijinita de disc nu
## mitraliaza), mai tare cu viteza de impact, in pozitia discului. `pitch` acordeaza gongurile
## unui rand pe note diferite. Masina jucatorului primeste si un tremur de camera.
##
## [b]AI-ul nu-l citeste[/b]: e un corp fizic onest, in care AI-ul intra sau pe langa care
## trece (`ai_controller.gd` nu stie de el).
##
## [b]Coordonate locale[/b]: nodul sta PE ASFALT, sub pozitia de repaus a discului; -Z local =
## directia de mers (ca `VineCurtain`), X local = de-a curmezisul (axa balamalei), Y = sus.
## Pivotul e la (0, `hang_height`, 0), centrul discului in repaus la (0, `center_height`, 0).
## Unghiul raportat (`swing_angle`) e pozitiv cand discul a plecat INAINTE (spre -Z).
##
## [b]Paleta[/b] (zero materiale noi, tot pe `Palette.world_material()`): bronzul discului
## (buza si inelul de pe fata) `LARCH_RUST` (#A8683A), fata si butonul din mijloc `SAND_LIGHT` (#E8C074,
## auriu), franghiile `DRY_VEGETATION` (#AF9F4E, canepa), grinda de sus `LOG_DARK` (#4A3526,
## aceeasi scoarta ca creanga perdelei de liane).

## Stratul pe care sta discul: al decorului lovibil (vezi antetul).
const LAYER: int = 1 << 8
## Segmentele cercului discului (geometria e construita aici, nu din primitive).
const DISC_SEGMENTS: int = 28

@export_group("Forma")
## Raza discului (m).
@export_range(0.4, 3.0, 0.05) var radius: float = 1.3
## Grosimea discului (m). Coliziunea e cu `collision_pad` mai groasa, vezi mai jos.
@export_range(0.05, 0.6, 0.01) var thickness: float = 0.16
## Centrul discului in repaus, peste asfalt (m). 1,75 cu raza 1,3: buza de jos la ~0,45 m,
## adica sub capota oricarei masini (colizerul caroseriei e intre 0,25 si 1,25 m).
@export_range(0.5, 6.0, 0.05) var center_height: float = 1.75
## Pivotul (axa balamalei) peste asfalt (m).
@export_range(2.0, 12.0, 0.1) var hang_height: float = 7.5
## Tavanul (m peste asfalt): de grinda pivotului urca doua franghii pana aici. <= pivot = fara.
@export_range(0.0, 20.0, 0.1) var ceiling_height: float = 10.0

@export_group("Fizica")
## Masa discului (kg). Masinile au 34-260 kg; vezi tabelul din ProbeGong.
@export_range(5.0, 500.0, 1.0) var mass: float = 70.0
## Limita balamalei, de fiecare parte (grade). Plasa de siguranta; opritorul moale lucreaza
## inaintea ei.
@export_range(10.0, 85.0, 1.0) var swing_limit_deg: float = 70.0
## Amortizarea liniara a centrului de masa (1/s): cat de repede se stinge leganatul mic.
@export_range(0.0, 3.0, 0.01) var damping: float = 0.3
## Frana patratica (1/m): deceleratia e `drag * v^2`. Taie loviturile mari.
@export_range(0.0, 1.0, 0.005) var drag: float = 0.16
## Latimea zonei opritorului moale, inainte de limita (grade).
@export_range(0.0, 40.0, 1.0) var soft_zone_deg: float = 20.0
## Amortizarea din zona opritorului, doar spre limita (1/s).
@export_range(0.0, 40.0, 0.5) var soft_stop: float = 14.0
## Leganat propriu (grade). 0 = sta nemiscat pana il loveste cineva; > 0 = isi tine singur
## un leganat de amplitudinea asta, ca un jucator singur pe pista sa intalneasca si el un
## obstacol mobil. Dupa o lovitura, amortizarea il aduce inapoi la amplitudinea asta, nu la 0.
@export_range(0.0, 40.0, 0.5) var idle_swing_deg: float = 0.0
## Cu cat e mai gros colizerul decat discul desenat (m): la 25 m/s masina face 0,42 m pe tick.
@export_range(0.0, 0.4, 0.01) var collision_pad: float = 0.12

@export_group("Sunet")
@export var ring_sfx: StringName = &"gong_hit"
## Inaltimea notei (1 = fisierul). Un rand de gonguri, pe note diferite.
@export_range(0.3, 3.0, 0.01) var pitch: float = 1.0
## Pauza minima intre doua sunete ale aceluiasi gong (s).
@export_range(0.1, 3.0, 0.05) var ring_cooldown: float = 0.7
## Saltul minim de viteza unghiulara intr-un tick, cu o masina in contact, care conteaza ca
## lovitura (rad/s). Gravitatia si fortele proprii raman sub 0,05.
@export_range(0.05, 3.0, 0.01) var ring_min_dw: float = 0.25
## Volumul la lovitura slaba si la cea plina (dB); plina = `ring_full_speed` m/s la contact.
@export var ring_db_soft: float = -16.0
@export var ring_db_full: float = -2.0
@export var ring_full_speed: float = 22.0

## Pentru sonde: de cate ori a sunat si ultima viteza de impact estimata (m/s).
var rings: int = 0
var last_ring_speed: float = 0.0

var _disc: RigidBody3D
var _anchor: StaticBody3D
var _joint: HingeJoint3D
var _prev_w: float = 0.0
var _ring_left: float = 0.0


func _ready() -> void:
	_build_static()
	_build_disc()
	if Engine.is_editor_hint():
		return
	_build_joint()
	get_tree().physics_frame.connect(_except_bump_props, CONNECT_ONE_SHOT)


## Corpul discului (sondele: pozitie, viteza, contacte).
func disc() -> RigidBody3D:
	return _disc


## Pivotul in coordonate globale.
func pivot_global() -> Vector3:
	return global_transform * Vector3(0.0, hang_height, 0.0)


## Lungimea pendulului: pivot -> centrul discului (m).
func arm_length() -> float:
	return hang_height - center_height


## Unghiul de leganat (rad), pozitiv cu discul plecat INAINTE (-Z local).
func swing_angle() -> float:
	if _disc == null:
		return 0.0
	var rel := global_transform.affine_inverse() * _disc.global_position \
		- Vector3(0.0, hang_height, 0.0)
	return atan2(-rel.z, -rel.y)


## Viteza unghiulara de leganat (rad/s), acelasi semn ca `swing_angle`.
func swing_rate() -> float:
	if _disc == null:
		return 0.0
	# Rotatia in jurul +X local duce discul spre -Z: semnul e chiar proiectia pe +X.
	return _disc.angular_velocity.dot(global_transform.basis.x.normalized())


# ------------------------------------------------------------------ fizica

func _physics_process(delta: float) -> void:
	if _disc == null or Engine.is_editor_hint():
		return
	_ring_left = maxf(_ring_left - delta, 0.0)
	var w := swing_rate()
	var dw := absf(w - _prev_w)
	_prev_w = w
	if dw >= ring_min_dw and _ring_left <= 0.0:
		var car := _touching_car()
		if car != null:
			_ring(car, dw)
	var v := _disc.linear_velocity
	var speed := v.length()
	var accel := Vector3.ZERO
	# Amortizarea liniara si frana patratica, pe centrul de masa (viteza lui = ω x brat).
	accel -= v * (damping + drag * speed)
	# Opritorul moale: spre limita, in ultima zona, franeaza tare.
	var th := swing_angle()
	var lim := deg_to_rad(swing_limit_deg)
	var zone := deg_to_rad(soft_zone_deg)
	if zone > 0.0 and absf(th) > lim - zone and signf(w) == signf(th):
		var k := clampf((absf(th) - (lim - zone)) / zone, 0.0, 1.0)
		accel -= v * soft_stop * k
	if idle_swing_deg > 0.0:
		accel += _idle_pump(v, th)
	_disc.apply_central_force(accel * _disc.mass)


## Pompa de leganat propriu: tine energia pendulului la cea a amplitudinii `idle_swing_deg`.
## Impinge pe directia vitezei (sau inainte, din repaus) cat energia e sub tinta; peste ea nu
## face nimic, deci dupa o lovitura amortizarea coboara leganatul pana la amplitudinea idle.
func _idle_pump(v: Vector3, th: float) -> Vector3:
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var arm := arm_length()
	var e_now := 0.5 * v.length_squared() + g * arm * (1.0 - cos(th))
	var e_want := g * arm * (1.0 - cos(deg_to_rad(idle_swing_deg)))
	if e_now >= e_want:
		return Vector3.ZERO
	var dir := v.normalized() if v.length() > 0.05 else -global_transform.basis.z.normalized()
	# Plus ce mananca amortizarea: fara asta pompa s-ar opri sub tinta.
	return dir * (0.6 + damping * v.length())


func _touching_car() -> Car:
	for body in _disc.get_colliding_bodies():
		if body is Car:
			return body as Car
	return null


func _ring(car: Car, dw: float) -> void:
	_ring_left = ring_cooldown
	rings += 1
	# Viteza punctului lovit, cam la jumatatea caroseriei (0,85 m peste asfalt).
	var hit_speed := dw * maxf(hang_height - 0.85, 0.5)
	last_ring_speed = hit_speed
	var k := clampf(hit_speed / maxf(ring_full_speed, 0.1), 0.0, 1.0)
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager != null:
		manager.call(&"play_sfx_at", ring_sfx, _disc.global_position, pitch,
			lerpf(ring_db_soft, ring_db_full, k), 3, 0.01)
	if car.is_player:
		for node in get_tree().get_nodes_in_group(ChaseCamera.GROUP):
			var cam := node as ChaseCamera
			if cam != null and cam.target == car:
				cam.add_trauma(lerpf(0.15, 0.45, k))


## Dupa primul pas de fizica: exceptii de coliziune cu decorul lovibil (singurul alt corp care
## vede stratul 9) si adormirea discului neatins. Adormirea ceruta inainte ca discul sa existe
## in Jolt nu tine (lectia din `BumpProp._setup`); cu leagan propriu nu adoarme deloc.
func _except_bump_props() -> void:
	if _disc == null or not is_inside_tree():
		return
	if _disc.can_sleep:
		_disc.sleeping = true
		# Adormit nu costa nici scriptul: contactul unei masini il trezeste, iar `_prev_w`
		# (0 in repaus) prinde saltul chiar in primul cadru de dupa trezire.
		_disc.sleeping_state_changed.connect(func() -> void:
			_prev_w = 0.0 if _disc.sleeping else _prev_w
			set_physics_process(not _disc.sleeping))
		set_physics_process(false)
	for node in get_tree().get_nodes_in_group(&"bump_props"):
		var b := node as PhysicsBody3D
		if b != null:
			_disc.add_collision_exception_with(b)


# ------------------------------------------------------------------ constructie

func _build_disc() -> void:
	_disc = RigidBody3D.new()
	_disc.name = "GongDisc"   # numele apare in rapoartele ProbeLaneClear
	_disc.position = Vector3(0.0, center_height, 0.0)
	_disc.mass = mass
	_disc.collision_layer = LAYER
	# Masca 1, nu 0: vezi antetul (coliziunea vazuta dintr-o parte = disc de masa infinita).
	_disc.collision_mask = 1
	_disc.continuous_cd = true
	_disc.can_sleep = idle_swing_deg <= 0.0
	# Amortizarea o da scriptul (pe centrul de masa); cea din proiect nu se adauga peste.
	_disc.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	_disc.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	_disc.linear_damp = 0.0
	_disc.angular_damp = 0.0
	_disc.contact_monitor = true
	_disc.max_contacts_reported = 4
	var pm := PhysicsMaterial.new()
	# Frecare mica: o caroserie care trece pe sub buza nu se agata de bronz.
	pm.friction = 0.2
	pm.bounce = 0.0
	_disc.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = thickness + collision_pad
	cs.shape = cyl
	# Cilindrul Godot sta pe Y; discul are axa pe Z (fata spre masina).
	cs.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_disc.add_child(cs)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_disc_mesh(st)
	_hanging_ropes(st)
	var mi := PaletteBox.emit(st, "Gong")
	if mi != null:
		_disc.add_child(mi)
	add_child(_disc)


func _build_joint() -> void:
	_anchor = StaticBody3D.new()
	_anchor.name = "Ancora"
	_anchor.collision_layer = 0
	_anchor.collision_mask = 0
	_anchor.position = Vector3(0.0, hang_height, 0.0)
	add_child(_anchor)
	_joint = HingeJoint3D.new()
	_joint.name = "Balama"
	# Axa balamalei e Z-ul jointului; rotit 90° in jurul lui Y, Z-ul lui cade pe X local.
	_joint.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, hang_height, 0.0))
	add_child(_joint)
	_joint.node_a = _joint.get_path_to(_anchor)
	_joint.node_b = _joint.get_path_to(_disc)
	var lim := deg_to_rad(swing_limit_deg)
	_joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	_joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -lim)
	_joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, lim)


## Grinda pivotului si franghiile pana in tavan: statice, nu se leagana.
func _build_static() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var beam_w := radius * 2.0 + 0.8
	PaletteBox.add(st, Transform3D(Basis.IDENTITY, Vector3(0.0, hang_height, 0.0)),
		Vector3(beam_w, 0.26, 0.26), Palette.LOG_DARK)
	if ceiling_height > hang_height + 0.3:
		for sx: float in [-1.0, 1.0]:
			var x := sx * (beam_w * 0.5 - 0.2)
			_rope(st, Vector3(x, hang_height + 0.13, 0.0), Vector3(x, ceiling_height, 0.0), 0.07)
	var mi := PaletteBox.emit(st, "Grinda")
	if mi != null:
		add_child(mi)


## Discul in spatiul lui (centrul in origine, fata pe +-Z): bronz cu buza ingrosata, un inel
## auriu pe fiecare fata si butonul din mijloc. Umbrirea e in vertex colors (buza mai
## intunecata, butonul luminos).
func _disc_mesh(st: SurfaceTool) -> void:
	var t := thickness * 0.5
	_cyl(st, radius, -t - 0.02, t + 0.02, Palette.LARCH_RUST, 0.62)        # buza
	_cyl(st, radius * 0.92, -t, t, Palette.SAND_LIGHT, 0.95)               # fata (aurie: bronzul inchis se pierdea in nava intunecata)
	for sz: float in [-1.0, 1.0]:
		_ring_band(st, radius * 0.55, radius * 0.62, sz * (t + 0.005), Palette.LARCH_RUST, 0.8)
		var z0 := sz * t
		var z1 := sz * (t + 0.09)
		_cyl(st, radius * 0.24, minf(z0, z1), maxf(z0, z1), Palette.SAND_LIGHT, 1.0)


## Franghiile discului: din doua puncte de pe buza (la 40° de varf) pana la capetele grinzii.
## In spatiul discului: pivotul e la (0, arm_length(), 0).
func _hanging_ropes(st: SurfaceTool) -> void:
	var arm := arm_length()
	var top_x := radius * 2.0 * 0.5 + 0.4 - 0.25
	for sx: float in [-1.0, 1.0]:
		var a := Vector3(sx * radius * sin(deg_to_rad(40.0)), radius * cos(deg_to_rad(40.0)), 0.0)
		_rope(st, a, Vector3(sx * top_x, arm, 0.0), 0.06)


## O franghie: o prisma patrata de grosime `w` de la `a` la `b`.
func _rope(st: SurfaceTool, a: Vector3, b: Vector3, w: float) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.01:
		return
	var y := d / length
	var x := y.cross(Vector3.FORWARD)
	if x.length_squared() < 1e-4:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	PaletteBox.add(st, Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(w, length, w),
		Palette.DRY_VEGETATION)


## Cilindru inchis pe axa Z, de la `z0` la `z1`, cu `DISC_SEGMENTS` laturi.
func _cyl(st: SurfaceTool, r: float, z0: float, z1: float, slot: int, shade: float) -> void:
	var uv := Palette.uv(slot)
	var c := Color(shade, shade, shade)
	for i in DISC_SEGMENTS:
		var a0 := TAU * float(i) / float(DISC_SEGMENTS)
		var a1 := TAU * float(i + 1) / float(DISC_SEGMENTS)
		var p0 := Vector2(cos(a0), sin(a0)) * r
		var p1 := Vector2(cos(a1), sin(a1)) * r
		# Manta.
		var n := Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0.0)
		var side: Array[Vector3] = [Vector3(p0.x, p0.y, z0), Vector3(p1.x, p1.y, z0),
			Vector3(p1.x, p1.y, z1), Vector3(p0.x, p0.y, z1)]
		_quad(st, side, n, uv, Color(shade * 0.85, shade * 0.85, shade * 0.85))
		# Capacele.
		_tri(st, [Vector3(0, 0, z1), Vector3(p0.x, p0.y, z1), Vector3(p1.x, p1.y, z1)],
			Vector3.BACK, uv, c)
		_tri(st, [Vector3(0, 0, z0), Vector3(p1.x, p1.y, z0), Vector3(p0.x, p0.y, z0)],
			Vector3.FORWARD, uv, c)


## Un inel plat (intre `r0` si `r1`) la cota `z`, cu fata spre semnul lui `z`.
func _ring_band(st: SurfaceTool, r0: float, r1: float, z: float, slot: int, shade: float) -> void:
	var uv := Palette.uv(slot)
	var c := Color(shade, shade, shade)
	var n := Vector3.BACK if z >= 0.0 else Vector3.FORWARD
	for i in DISC_SEGMENTS:
		var a0 := TAU * float(i) / float(DISC_SEGMENTS)
		var a1 := TAU * float(i + 1) / float(DISC_SEGMENTS)
		var q: Array[Vector3] = [Vector3(cos(a0) * r0, sin(a0) * r0, z), Vector3(cos(a1) * r0, sin(a1) * r0, z),
			Vector3(cos(a1) * r1, sin(a1) * r1, z), Vector3(cos(a0) * r1, sin(a0) * r1, z)]
		if z < 0.0:
			q.reverse()
		_quad(st, q, n, uv, c)


func _quad(st: SurfaceTool, q: Array, n: Vector3, uv: Vector2, c: Color) -> void:
	_tri(st, [q[0], q[1], q[2]], n, uv, c)
	_tri(st, [q[0], q[2], q[3]], n, uv, c)


func _tri(st: SurfaceTool, p: Array, n: Vector3, uv: Vector2, c: Color) -> void:
	# Ordinea varfurilor dupa normala ceruta, ca in `PaletteBox.add`: (b-a)x(d-a) pe normala.
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var d: Vector3 = p[2]
	if (b - a).cross(d - a).dot(n) < 0.0:
		var tmp := b
		b = d
		d = tmp
	for v: Vector3 in [a, b, d]:
		st.set_normal(n)
		st.set_uv(uv)
		st.set_color(c)
		st.add_vertex(v)
