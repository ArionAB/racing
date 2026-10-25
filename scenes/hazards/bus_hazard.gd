@tool
class_name BusHazard
extends "res://scenes/props/path_mover.gd"
## Autobuzul care coboara serpentinele (Machu Picchu, brief §2 POI G, §3
## „Autobuzul"): un vehicul greu pe traseu fix, care NU te opreste (trenul e la
## Baikal), ci te IMPINGE spre exterior daca esti pe partea lui.
##
## Cea mai mica reutilizare: [PathMover] da deja corpul [AnimatableBody3D] cu
## `sync_to_physics` pe un [Path3D] desenat de mana, cu o singura scriere de
## transform pe tick (memoria `jolt-sync-transform-o-singura-scriere`), modelul
## sau cutia placeholder si lipirea de teren. Peste el, trei lucruri:
##
##   1. CICLUL: coboara curba o data la `speed`, apoi „urca gol pe cealalta
##      parte, invizibil" (brief §2): sta ASCUNS la capatul de sus al curbei
##      pana se implineste `period`, si porneste iar. Ascuns = colizor stins
##      (`collision_layer = 0`) + invizibil + zona de ghiont oprita.
##      Teleportarea de la capatul de jos la cel de sus se face NUMAI cat e
##      stins — memoria `corp-cinematic-aparut-in-masina`: un corp cinematic
##      care apare langa masina ii da o viteza uriasa. Cand reapare, sta deja
##      pe loc de cateva secunde, deci viteza lui e zero. Primul punct al curbei
##      se pune in afara drumului (in spatele unui perete) ca nimeni sa nu
##      parcheze exact acolo.
##   2. BOTUL DEFLECTOR: „contactul e DeflectorHazard care merge" (brief §3).
##      Un corp cinematic are masa infinita in solver, deci o fata plata
##      frontala ar fi un zid care merge: masina lovita bot in bot pleaca
##      inapoi cu viteza autobuzului. Fata din fata e OBLICA (`nose_angle_deg`,
##      spre `nose_side`): normala contactului are componenta laterala, deci
##      solverul insusi transforma lovitura in alunecare spre exterior — cu
##      masa, fara nicio cifra de ghiont. Un flanc subtire inchide triunghiul
##      de sub fata oblica, ca o roata sa nu intre in gol.
##   3. GHIONTUL: zona putin mai grasa decat corpul, `apply_sweep` lateral
##      (dinspre axa autobuzului spre partea pe care e masina) + un pic inainte
##      pe directia masinii, cu cooldown per masina — reteta din
##      [SlidingHazard]._shove_cars (elefantul din Serengeti). Nu se roteste
##      masina (`apply_yaw_kick` e pentru sabotaj de control, nu pentru asta).
##
## „Masa efectiva ~2000" din brief e, in practica, masa infinita a corpului
## cinematic: masina nu-l clinteste, indiferent de presetare. Diferenta intre
## sport si Autobuzul din garaj se vede in cat de departe zboara la ghiont
## (acelasi delta-v, alta inertie in restul contactului), nu in cat il misca.
##
## Se masoara in tools/probe_machu_teren.gd (testul D): impins lateral, nu
## oprit, zero contact pe interiorul acului, cost sub 100 us pe tick.
##
## ACUL LUAT LARG (`apex_outer_m`): autorul deseneaza curba pe BANDA
## autobuzului de pe drepte (jumatatea dinspre gol, dreapta lui la coborare)
## si NU deseneaza arcul de mana. Corpul se muta singur spre exteriorul
## virajului proportional cu curbura curbei (saturata la `apex_radius_m`):
## pe un ac de raza 10 sta cu `apex_outer_m` mai in afara decat curba, pe
## drepte exact pe ea. Asa interiorul acului ramane liber (decizia POI G:
## „astepti in interior sau treci pe langa el"), iar autobuzele reale chiar
## asa iau serpentinele. Masurat in tools/probe_machu_teren.gd (testul D,
## 14 sep 2026): pe ac de raza 13 interiorul trece cu zero contact la 7 si
## 9 m/s; pe raza 10 nu — dar fiindca sportul nu poate vira sub 9.5 m
## (max_speed / (2 * steer_speed)), nu din cauza autobuzului. Acele
## serpentinelor: raza >= 13 m pe axa, sau 8.2 m latime la apex.
##
## DECLARARE PE PISTA (.tscn) — nodul INSUSI e Path3D-ul (tiparul PathMover;
## nu are nevoie de un copil „Route"), copil direct al pistei:
##   [node name="Autobuz" type="Path3D" parent="."]
##   script = ExtResource("res://scenes/hazards/bus_hazard.gd")
##   curve = SubResource("Curve3D_...")   # desenata cu gizmo-ul, DE SUS IN JOS
##   speed = 7.0                          # m/s la coborare
##   period = 35.0                        # ciclu; ascuns sus in rest
##   nose_side = 1                        # +1: deflecteaza spre DREAPTA lui
##   apex_outer_m = 1.0                   # cat iese spre exterior la apex
##   apex_radius_m = 15.0                 # sub raza asta ofsetul e intreg
##   body_size = Vector3(3.6, 3.0, 6.0)   # placeholder; cu model, din AABB
##   model = ExtResource("consettur_bus.glb")   # optional
## SENSUL: curba se deseneaza in sensul coborarii: primul punct SUS, in
## afara drumului (in spatele unui perete) — acolo sta ascuns intre doua
## coborari si acolo reapare; ultimul punct jos, tot in afara drumului.
## Curba merge pe jumatatea drumului dinspre gol (dreapta autobuzului la
## coborare); masinile care urca il vad venind din fata, pe jumatatea
## dinspre gol, iar interiorul acului (dinspre perete) ramane liber.
## `nose_side = 1` = impinge spre dreapta LUI = spre gol. `stick_to_ground`
## ramane pornit: cota o ia din teren cu raycast, curba se deseneaza de sus
## fara sa-ti pese de panta. AI-ul nu-l vede (obstacol dinamic):
## HazardMarker „asteapta in interiorul acului" pe waypoint ramane de pus de
## agentul pistei (brief §3).

## Ciclul complet (s): o coborare + timpul ascuns. Daca e mai scurt decat
## coborarea, autobuzul reapare imediat ce a ajuns jos.
@export_range(5.0, 120.0, 0.5) var period: float = 35.0
## Gabaritul cutiei placeholder (latime, inaltime, lungime) cand nu e model.
## 4.2 m latime = 2/3 din drumul de 6.5 m al serpentinelor (brief §2 POI G).
@export var body_size: Vector3 = Vector3(3.6, 3.0, 6.0)
## Incotro deflecteaza botul: +1 = spre dreapta autobuzului (exteriorul
## serpentinei cand coboara pe partea lui), -1 = spre stanga.
@export_enum("Dreapta:1", "Stanga:-1") var nose_side: int = 1
## Unghiul fetei oblice fata de axa transversala (grade). 0 = fata plata (zid
## care merge — nu). Mai mare = deflectare mai blanda, dar bot mai lung.
@export_range(0.0, 45.0, 1.0) var nose_angle_deg: float = 20.0
## Cat iese corpul spre EXTERIORUL virajului la apex, fata de curba (m).
## 0 = urmeaza curba exact. Vezi antetul, „acul luat larg".
@export_range(0.0, 4.0, 0.1) var apex_outer_m: float = 1.0
## Raza de viraj sub care ofsetul e intreg; peste ea scade liniar cu
## curbura (la raza dubla e jumatate). Serpentinele au ~10 m.
@export_range(3.0, 60.0, 0.5) var apex_radius_m: float = 15.0
## m/s adaugati lateral masinii care intra in zona de ghiont (o data, cu
## cooldown — dezechilibrarea).
@export_range(0.0, 12.0, 0.5) var shove: float = 3.0
## Acceleratia laterala SUSTINUTA (m/s^2) cat masina sta in zona de ghiont.
## Ghiontul singur nu deplaseaza: grip-ul lateral al masinii (~10/s) stinge
## un delta-v de 5.5 m/s in ~0.1 s, adica ~0.5 m. Impingerea „cu masa" din
## brief e o forta care tine cat tine contactul — deriva laterala de regim e
## side_accel / grip, deci ~3 m/s la 30. (PathMover are deja `push_accel`, campul radial al hovercraftului — asta e alta forta, laterala.)
@export_range(0.0, 60.0, 1.0) var side_accel: float = 8.0
## Sunetul de contact (feel_checklist: hazards-speak): la ghiont, pozitional la
## masina lovita. Gol = autobuz mut.
@export var contact_sfx: StringName = &"hazard_bus_hit"

## CAMIONUL VINE DIN FATA (Carrara, brief §3): doua flaguri, AMBELE implicit
## stinse, deci Machu Picchu (autobuzul care coboara) ramane bit-identic.
##
## `ai_reads_lane`: AI-ul vede corpul VIZIBIL al camionului (pozitia lui pe
## sosea, ca jucatorul — niciodata faza ascunsa) si trece pe banda opusa lui
## pana il depaseste. Vezi `AIController._bus_line`.
@export var ai_reads_lane: bool = false
## `soft_contact`: lovitura frontala NU mai ejecteaza soferul (un camion e un
## corp greu, nu un zid de beton la 36 m/s): ghiont + strivire de
## `soft_crush_s` secunde. Vezi `Car._process_contacts` (meta `soft_hit_crush`).
@export var soft_contact: bool = false
@export_range(0.2, 3.0, 0.1) var soft_crush_s: float = 1.2

## Grupul pe care il citeste AI-ul (doar daca `ai_reads_lane`).
const AI_GROUP: StringName = &"ai_bus_lane"

## Reapare sus si porneste la vale (carlig pentru claxon/telegraf).
signal descent_started(bus: BusHazard)
## A ajuns jos si s-a ascuns.
signal descent_ended(bus: BusHazard)
## O masina a primit ghiontul.
signal shoved(bus: BusHazard, car: Car)

## Costul ultimului tick (us), pentru sonde.
var last_tick_usec: int = 0

const SHOVE_COOLDOWN: float = 0.35
## Cat de grasa e zona de ghiont fata de corp: lateral putin (o masina care
## trece cu rotile pe margine NU trebuie impinsa), in fata mai mult (ghiontul
## sa vina inainte de contactul dur).
const SHOVE_MARGIN_SIDE: float = 0.15
const SHOVE_MARGIN_FRONT: float = 4.0
const NOSE_THICKNESS: float = 0.35
## Pe cati metri de curba (inainte si inapoi) se citeste curbura. Destul
## de mult ca o curba desenata din segmente drepte (fara manere) sa nu dea
## curbura zero intre doua varfuri si un salt la varf.
const APEX_SAMPLE_M: float = 6.0
## Cat de repede urmareste ofsetul curbura (1/s): netezeste saltul dintre
## segmentele unei curbe poligonale.
const APEX_FOLLOW: float = 4.0

var _hidden: bool = false
var _hide_left: float = 0.0
var _shove_area: Area3D
var _cooldown: Dictionary = {}
var _box_size: Vector3 = Vector3.ZERO
var _apex: Vector3 = Vector3.ZERO
var _prev_pos: Vector3 = Vector3.ZERO
var _has_prev: bool = false
var _box_center: Vector3 = Vector3.ZERO


## Cutia autobuzului, nu tractorul din PathMover.
func _build_placeholder() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = body_size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.2)
	mesh.material_override = mat
	mesh.position = Vector3.UP * (body_size.y * 0.5)
	_pivot.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = body_size
	shape.shape = col
	shape.position = Vector3.UP * (body_size.y * 0.5)
	_body.add_child(shape)


func _build_body() -> void:
	super()
	# Fata fara frecare: masina ALUNECA pe botul oblic in loc sa fie tarata
	# de el. Cu frecarea implicita, contactul frontal o tinea lipita (masurat
	# in ProbeMachuTeren: 86 de cadre de contact, 2.5 s sub 5 m/s).
	var pmat := PhysicsMaterial.new()
	pmat.friction = 0.0
	pmat.bounce = 0.0
	_body.physics_material_override = pmat
	# Cutia solida a corpului (din model sau placeholder), ca sa croim botul si
	# zona de ghiont pe ea — masurate, nu scrise de mana.
	for c in _body.get_children():
		var cs := c as CollisionShape3D
		if cs != null and cs.shape is BoxShape3D:
			_box_size = (cs.shape as BoxShape3D).size
			_box_center = cs.position
			break
	if _box_size == Vector3.ZERO:
		_box_size = body_size
		_box_center = Vector3.UP * (body_size.y * 0.5)
	_build_nose()
	_build_shove_area()
	if soft_contact:
		_body.set_meta(&"soft_hit_crush", soft_crush_s)
	if ai_reads_lane:
		add_to_group(AI_GROUP)


## Fata oblica din fata (-Z local) + flancul care inchide triunghiul.
##
## Fata merge din coltul din fata de pe partea OPUSA deflectarii (cel mai
## avansat punct, la -depth in fata cutiei) pana in coltul din fata de pe
## partea deflectarii (la fata cutiei). Normala ei arata inainte si spre
## `nose_side`, deci orice contact frontal e impins intr-acolo.
func _build_nose() -> void:
	if nose_angle_deg <= 0.0:
		return
	var w := _box_size.x
	var h := _box_size.y
	var front_z := _box_center.z - _box_size.z * 0.5
	var depth := w * tan(deg_to_rad(nose_angle_deg))
	var s := float(nose_side)
	var a := Vector3(-s * w * 0.5, _box_center.y, front_z - depth) # varful
	var b := Vector3(s * w * 0.5, _box_center.y, front_z)          # coltul
	var along := b - a
	var length := along.length()
	var basis := Basis.looking_at(along.normalized(), Vector3.UP)
	# Fata: cutie subtire cu axa Z locala pe segmentul a->b.
	_add_box(Vector3(NOSE_THICKNESS, h, length + NOSE_THICKNESS),
		Transform3D(basis, (a + b) * 0.5))
	# Flancul: pe partea opusa deflectarii, de la varf pana la fata cutiei.
	_add_box(Vector3(NOSE_THICKNESS, h, depth + NOSE_THICKNESS),
		Transform3D(Basis.IDENTITY,
			Vector3(-s * (w * 0.5 - NOSE_THICKNESS * 0.5), _box_center.y,
				front_z - depth * 0.5)))


func _add_box(size: Vector3, xform: Transform3D) -> void:
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	shape.transform = xform
	_body.add_child(shape)
	if model == null:
		# Pe placeholder se si vede botul; pe model e bara invizibila.
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.transform = xform
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.3, 0.15)
		mi.material_override = mat
		_pivot.add_child(mi)


func _build_shove_area() -> void:
	_shove_area = Area3D.new()
	_shove_area.name = "Shove"
	_shove_area.monitoring = true
	_shove_area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var depth := _box_size.x * tan(deg_to_rad(maxf(nose_angle_deg, 0.0)))
	box.size = Vector3(_box_size.x + SHOVE_MARGIN_SIDE * 2.0,
		_box_size.y + 0.4,
		_box_size.z + depth + SHOVE_MARGIN_FRONT * 2.0)
	shape.shape = box
	shape.position = _box_center + Vector3(0.0, 0.0, -depth * 0.5)
	_shove_area.add_child(shape)
	_body.add_child(_shove_area)


## Tick-ul lui PathMover, rescris cu un singur adaos: ofsetul spre exterior
## la apex. (Nu se poate injecta intre esantionarea curbei si scrierea
## transformului fara sa se copieze restul, si restul e mic.)
func _physics_process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	if _body == null or curve == null:
		return
	var length := curve.get_baked_length()
	if length < 0.5:
		return
	if not _started:
		_started = true
		_dist = phase * length
	_time += delta
	_advance(delta, length)
	var pos := to_global(curve.sample_baked(_dist, true))
	var target_yaw := _travel_yaw(length, pos)
	_apex = _apex.lerp(_apex_offset(length), minf(APEX_FOLLOW * delta, 1.0))
	pos += _apex
	# Botul arata INCOTRO SE MISCA corpul (cu tot cu iesirea spre exterior la
	# apex), nu pe tangenta curbei: altfel pe ac corpul „crabeaza" cu varful
	# botului rotit spre interior si masina din fata il ia in flanc, nu pe
	# fata oblica.
	if _has_prev and not _hidden:
		var moved := pos - _prev_pos
		moved.y = 0.0
		if moved.length() > 0.02:
			target_yaw = atan2(-moved.x, -moved.z)
	_prev_pos = pos
	_has_prev = true
	_yaw = lerp_angle(_yaw, target_yaw, minf(TURN_RATE * delta, 1.0))
	if stick_to_ground:
		pos.y = _ground_y(pos)
	# O SINGURA scriere de transform (memoria jolt-sync-transform).
	_body.global_transform = Transform3D(Basis(Vector3.UP, _yaw), pos)
	_apply_sway()
	if not Engine.is_editor_hint():
		_shove_cars(delta)
	last_tick_usec = int(Time.get_ticks_usec() - t0)


## Ofsetul spre exteriorul virajului in punctul curent: curbura din unghiul
## dintre tangentele la -APEX_SAMPLE_M si +APEX_SAMPLE_M, saturata la
## 1/apex_radius_m; exteriorul unui viraj la stanga e dreapta.
func _apex_offset(length: float) -> Vector3:
	if apex_outer_m <= 0.0:
		return Vector3.ZERO
	var h := APEX_SAMPLE_M
	var a := to_global(curve.sample_baked(clampf(_dist - h, 0.0, length), true))
	var b := to_global(curve.sample_baked(_dist, true))
	var c := to_global(curve.sample_baked(clampf(_dist + h, 0.0, length), true))
	var t1 := b - a
	var t2 := c - b
	t1.y = 0.0
	t2.y = 0.0
	if t1.length_squared() < 0.01 or t2.length_squared() < 0.01:
		return Vector3.ZERO
	var dtheta := t1.normalized().signed_angle_to(t2.normalized(), Vector3.UP)
	var kappa := dtheta / h
	var frac := clampf(absf(kappa) * apex_radius_m, 0.0, 1.0)
	var tangent := c - a
	tangent.y = 0.0
	var right := tangent.normalized().cross(Vector3.UP)
	return right * signf(kappa) * apex_outer_m * frac


## Ciclul: coboara o data, se ascunde sus, asteapta restul perioadei.
func _advance(delta: float, length: float) -> void:
	if Engine.is_editor_hint():
		return
	if _hidden:
		_hide_left -= delta
		if _hide_left <= 0.0:
			_show()
		return
	_dist += speed * delta
	if _dist >= length:
		# Teleportarea sus se face DOAR stins (vezi antet).
		_dist = 0.0
		_hide(maxf(period - length / maxf(speed, 0.01), 0.5))


func _hide(seconds: float) -> void:
	_hidden = true
	_hide_left = seconds
	_body.collision_layer = 0
	_body.visible = false
	if _shove_area != null:
		_shove_area.monitoring = false
	_cooldown.clear()
	descent_ended.emit(self)


func _show() -> void:
	_hidden = false
	_body.collision_layer = 1
	_body.visible = true
	if _shove_area != null:
		_shove_area.monitoring = true
	descent_started.emit(self)


## Pozitia corpului VIZIBIL (lume) si semilatimea lui — ce vede si un om.
func body_position() -> Vector3:
	return _body.global_position if _body != null else global_position


func body_forward() -> Vector3:
	return -_body.global_transform.basis.z if _body != null else Vector3.FORWARD


func body_half_width() -> float:
	return _box_size.x * 0.5 if _box_size.x > 0.0 else body_size.x * 0.5


func body_half_length() -> float:
	return _box_size.z * 0.5 if _box_size.z > 0.0 else body_size.z * 0.5


## Ascuns acum? (pentru sonde)
func is_hidden() -> bool:
	return _hidden


## Distanta parcursa pe curba in coborarea curenta (m), pentru sonde.
func distance() -> float:
	return _dist


func _shove_cars(delta: float) -> void:
	if _hidden or _shove_area == null:
		return
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	var right := _body.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var ahead := -_body.global_transform.basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	var front := _box_center.z - _box_size.z * 0.5
	for b in _shove_area.get_overlapping_bodies():
		var car := b as Car
		if car == null:
			continue
		var rel := car.global_position - _body.global_position
		# IN FATA botului (si in banda lui): spre partea botului, aceeasi
		# directie in care deflecteaza fata oblica — altfel ghiontul si botul
		# se anuleaza si masina ramane infipta (masurat pe ac: 3.7 s sub
		# 5 m/s). ALATURI: de langa axa, ca la SlidingHazard.
		# „In banda lui" = centrul masinii la mai putin de (jumatate de latime
		# - 0.6 m) de axa: o masina care CALARESTE muchia opusa botului atinge
		# flancul si varful, care o imping de langa axa; ghiontul trebuie sa
		# mearga in aceeasi parte, altfel se anuleaza (masurat pe ac, r = 13:
		# 40 de cadre de contact, 2.9 s sub 5 m/s).
		var side := signf(rel.dot(right))
		if rel.dot(ahead) > -front - 0.5 				and absf(rel.dot(right)) < _box_size.x * 0.5 - 0.6:
			side = float(nose_side)
		elif side == 0.0:
			side = float(nose_side)
		# Forta sustinuta, doar cu rotile pe sol (in aer ar fi mecanism de zbor).
		if car.wheels_on_ground > 0 and side_accel > 0.0:
			car.apply_central_force(right * side * side_accel * car.mass)
		if float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = SHOVE_COOLDOWN
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		car.apply_sweep(right * side * shove
			+ fwd.normalized() * shove * 0.3 + Vector3.UP * 0.3)
		shoved.emit(self, car)
		if contact_sfx != &"":
			var audio := get_node_or_null(^"/root/AudioManager")
			if audio != null:
				audio.hazard_contact(contact_sfx,
					car.global_position + Vector3.UP * 0.5, car.is_player)
