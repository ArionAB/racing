@tool
class_name BalloonHazard
extends Node3D
## COSUL CARE URCA DIN VALE (Cappadocia, brief §2 POI C / §3 „hazardul-semnatura").
##
## Un balon ancorat pe fundul Vaii Rosii urca pe ciclu pana la cota benzii, sta
## cateva secunde cu cosul IN banda, apoi coboara. Trei baloane defazate cu 1/3
## fac ritmul locului. Frustumul e motivul pentru care vine de JOS si nu de sus
## (brief §2.0): marginea de sus a cadrului e la ~+5°, deci un balon care coboara
## din cer n-ar exista pana in clipa impactului, pe cand un cos care se ridica
## de langa cornisa se vede 3-4 s inainte.
##
## Cosul e PLATFORMA: poti ateriza pe el la o saritura si te duce sus. Contractul
## e cel dovedit de telecabina (CablewayHazard, memoria
## `telecabina-platforma-mobila`), cu o singura deosebire care schimba tot:
## [b]miscarea e pur VERTICALA[/b], adica exact pe axa suspensiei.
##
## Cele cinci capcane, si cum sunt inchise (masurate in ProbeBalloon):
##
##  1. O SINGURA scriere de transform pe cadru, `global_transform` intreg
##     (AnimatableBody3D + sync_to_physics sub Jolt; memoria
##     `jolt-sync-transform-o-singura-scriere`).
##
##  2. `platform_velocity` in meta pe corp, diferentiata din pozitie. Rotile o
##     citesc din raycast si amortizorul masoara viteza RELATIVA la podea —
##     altfel o podea care urca cu 3 m/s citeste ca arc comprimat cu 3 m/s si
##     masina e batuta in sus la fiecare cadru.
##
##  3. [b]ACCELERATIA e ce arunca, nu viteza.[/b] Aici e diferenta fata de
##     telecabina. Podeaua care FRANEAZA sub o masina o lasa in aer (masina isi
##     tine inertia), iar podeaua care porneste in jos i-o ia de sub roti: la
##     capete, cursa verticala trebuie sa se stinga LIN. Profilul e un
##     smoothstep pe urcare si pe coborare, iar plafonul de acceleratie iese
##     din inaltime si durata: a_max = 6*H/T² pentru smoothstep. Cu H=30 m si
##     T=8 s ies 2.8 m/s², adica o zecime din gravitatia jocului (28) — deci
##     arcurile n-au ce sa decoleze, si nici masina n-are cum sa se desprinda
##     la varf. Un profil trapezoidal (viteza constanta cu capete drepte) ar da
##     o TREAPTA de acceleratie la fiecare capat: aia arunca. Cifra se masoara,
##     nu se presupune (ProbeBalloon (ii)).
##
##  4. Longitudinal si lateral cauciucul NU tine (rotile se invart liber, iar
##     cosul e o cutie de 2.4 m): pe urcare masina ar aluneca de pe el la prima
##     atingere. Cosul o ANCOREAZA cat sta la bord, arc+amortizor orizontal
##     spre locul unde a aterizat, plafonat — acelasi mecanism ca ancora
##     telecabinei, cu aceeasi lege. Vertical nu se atinge: acolo tine
##     suspensia.
##
##  5. Indexul de pista: cosul o urca `height` metri, fereastra locala de index
##     (~72 m pe ruta) nu vede etajul de sus si nu exista „aterizare" (rotile
##     n-au parasit podeaua). Cand cosul se opreste — sus sau jos — el recauta
##     indexul global pentru fiecare masina de la bord: el a teleportat-o, el o
##     anunta (nota 4 a telecabinei).
##
## Ce NU e: cosul nu prinde masina ca telecabina (n-are usi si n-are peron).
## Cine cade de pe el cade in vale — si asta e chiar pretul castigului.

const WorldProp = preload("res://scenes/props/world_prop.gd")

## Gabaritul cosului. Brief-ul §5 cerea `balloon_basket.glb` de [b]2 x 2 m[/b];
## cifra e GRESITA si sonda o corecteaza cu masuratoarea, nu cu o parere.
##
## Masina sta pe platforma prin SUSPENSIE, adica prin patru raycast-uri lansate
## din colturi: ca sa fie purtata, podeaua trebuie sa prinda toate patru
## punctele, deci sa fie mai lunga decat AMPATAMENTUL, nu decat „o masinuta".
## Ampatamentele masurate (ProbeBalloon, toate cele 5 masini): Taxi 2.94,
## Muscle/Politia 3.19, Pompierii 3.70, [b]Autobuzul 4.15[/b]. Un cos de 2 m
## nu prinde nici macar o axa a celei mai scurte — masina il calareste si cade
## pe langa el (masurat: cadea la -43.5 m, sub fundul vaii).
##
## 4.8 m lasa 0.32 m de marja de fiecare parte la autobuz. La scara de jucarie
## e un cos de nuiele cat doua masini — mare, dar exact cat trebuie ca sa fie
## platforma promisa in brief. Podeaua la y=0 local, ca la cabina.
const BASKET_SIZE := Vector3(4.8, 1.2, 4.8)
## Cel mai lung ampatament din garaj (autobuzul), pentru verificarea de mai sus.
const LONGEST_WHEELBASE: float = 4.15
const FLOOR_THICKNESS: float = 0.25
## Peretii de rachita: JOSI. Peste ~0.3 m devin prag-zid la aterizarea oblica
## (memoria `suprafete-cu-goluri-si-praguri`: pragurile > 0.3 m sunt ziduri).
const WALL_HEIGHT: float = 0.28
const WALL_THICKNESS: float = 0.1
## Pana la ce inaltime peste podea numara zona „la bord".
const DECK_HEIGHT: float = 2.5
## Panza (`balloon_envelope_*.glb`): 12 m inalta, 9 m lata, sta PESTE cos.
const ENVELOPE_HEIGHT: float = 12.0
const ENVELOPE_RADIUS: float = 4.5
## Cablul de ancorare: o linie de la tarus la cos.
const TETHER_RADIUS: float = 0.05

enum State { JOS, URCA, SUS, COBOARA }

@export_group("Ritm")
## Ciclul complet (s). Brief: ~28, si NU divizor al turului — faza se muta de
## la tur la tur (lectia Stromboli).
@export_range(4.0, 180.0, 0.5) var period: float = 28.0
## Cat sta jos, pe fundul vaii, cu panza umflandu-se.
@export_range(0.0, 60.0, 0.1) var ground_hold: float = 8.0
## Cat dureaza urcarea celor `height` metri (si coborarea).
@export_range(1.0, 40.0, 0.1) var rise_time: float = 8.0
## Cat sta SUS, cu cosul in banda. Brief: ~4 s.
@export_range(0.5, 30.0, 0.1) var hold: float = 4.0
## Decalajul ciclului (0..1 din period). Trei noduri la 0, 1/3, 2/3 fac ritmul
## cornisei — vezi verdictul (iv) al sondei pentru fereastra reala de blocare.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

@export_group("Cursa")
## Cat urca podeaua cosului fata de pozitia nodului. Brief: ~30 m, din vale
## pana la cota benzii. Nodul se pune PE FUNDUL VAII, la tarus.
@export_range(1.0, 80.0, 0.5) var height: float = 30.0

@export_group("Ancora")
## Arcul (1/s²) si amortizarea (1/s) care tin masina pe cos cat e la bord.
## Aceeasi lege ca ancora telecabinei.
@export_range(0.0, 200.0, 1.0) var hold_stiffness: float = 60.0
@export_range(0.0, 60.0, 0.5) var hold_damping: float = 15.0
## Plafonul acceleratiei ancorei (m/s²): tine, dar nu poate arunca.
@export_range(1.0, 80.0, 1.0) var hold_max_accel: float = 30.0

@export_group("Constructie")
@export var basket_model: PackedScene = null
@export var envelope_model: PackedScene = null
@export_range(0.2, 3.0, 0.05) var model_scale: float = 1.0
## Sloturile de paleta pentru inlocuitoarele desenate in cod (fara model).
@export_range(0, 31) var basket_slot: int = 9    # WOOD_WEATHERED (rachita)
@export_range(0, 31) var envelope_slot: int = 14 # CAR_RED (balon saturat)
@export_range(0, 31) var tether_slot: int = 10   # RUST_METAL (cablu)

var _body: AnimatableBody3D
var _deck: Area3D
var _envelope: Node3D
var _tether: MeshInstance3D
var _base_y: float = 0.0
var _time: float = 0.0
var _started: bool = false
var _state: State = State.JOS
var _velocity: Vector3 = Vector3.ZERO
var _prev_pos: Vector3 = Vector3.ZERO
## Car -> ancora (pozitia locala pe podea) pentru masinile de la bord.
var _aboard: Dictionary = {}


func _ready() -> void:
	# Invariantul care face din cos o PLATFORMA si nu un obstacol: podeaua
	# trebuie sa prinda toate patru razele de suspensie ale celei mai lungi
	# masini. Daca cineva micsoreaza cosul „ca sa arate mai bine", afla aici,
	# nu dintr-o masina care cade in vale (vezi ProbeBalloon (vii)).
	if BASKET_SIZE.z <= LONGEST_WHEELBASE:
		push_warning("BalloonHazard '%s': podeaua (%.2f m) e mai scurta decat cel mai lung ampatament din garaj (%.2f m) — masina o va calari, nu va sta pe ea"
			% [name, BASKET_SIZE.z, LONGEST_WHEELBASE])
	_base_y = global_position.y
	_build_body()
	_build_envelope()
	_build_tether()
	_place(0.0)
	_prev_pos = _body.global_position


# ---------------------------------------------------------------- constructie

func _build_body() -> void:
	_body = AnimatableBody3D.new()
	_body.name = "Basket"
	_body.sync_to_physics = true
	add_child(_body)
	_body.set_meta(&"platform_velocity", Vector3.ZERO)
	# Podeaua: fata de sus la y=0 local. Masina sta pe ea prin raycast.
	_add_shape(_body, Vector3(BASKET_SIZE.x, FLOOR_THICKNESS, BASKET_SIZE.z),
		Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0))
	# Peretii de rachita pe toate patru laturile, JOSI (vezi WALL_HEIGHT).
	for sx in [-1.0, 1.0]:
		_add_shape(_body, Vector3(WALL_THICKNESS, WALL_HEIGHT, BASKET_SIZE.z),
			Vector3(sx * (BASKET_SIZE.x - WALL_THICKNESS) * 0.5,
				WALL_HEIGHT * 0.5, 0.0))
	for sz in [-1.0, 1.0]:
		_add_shape(_body, Vector3(BASKET_SIZE.x, WALL_HEIGHT, WALL_THICKNESS),
			Vector3(0.0, WALL_HEIGHT * 0.5,
				sz * (BASKET_SIZE.z - WALL_THICKNESS) * 0.5))
	var scene := basket_model
	if scene != null:
		var inst := scene.instantiate() as Node3D
		if inst != null:
			inst.scale = Vector3.ONE * model_scale
			Palette.apply_object_class_materials(inst,
				WorldProp.prop_classes(), model_scale)
			_body.add_child(inst)
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = _box_mesh(BASKET_SIZE, basket_slot)
		mi.position = Vector3(0.0,
			-BASKET_SIZE.y * 0.5 + FLOOR_THICKNESS * 0.5, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_body.add_child(mi)
	# Zona podelei: cine e in ea e la bord (ancorat).
	_deck = Area3D.new()
	_deck.name = "Deck"
	_deck.monitoring = true
	_deck.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BASKET_SIZE.x, DECK_HEIGHT, BASKET_SIZE.z)
	shape.shape = box
	shape.position = Vector3(0.0, DECK_HEIGHT * 0.5, 0.0)
	_deck.add_child(shape)
	_body.add_child(_deck)


## Panza: STA PESTE cos si urca odata cu el, dar NU are coliziune — un balon
## de 9 m latime cu colizer ar fi un zid mobil de 9 m, adica alt hazard.
## Numai cosul e solid; panza e ce vezi de departe.
func _build_envelope() -> void:
	_envelope = Node3D.new()
	_envelope.name = "Envelope"
	_body.add_child(_envelope)
	if envelope_model != null:
		var inst := envelope_model.instantiate() as Node3D
		if inst != null:
			inst.scale = Vector3.ONE * model_scale
			Palette.apply_object_class_materials(inst,
				WorldProp.prop_classes(), model_scale)
			_envelope.add_child(inst)
			return
	# Inlocuitor: o sfera turtita, desenata in SurfaceTool ca sa aiba toate
	# UV-urile pe slotul de paleta (o `SphereMesh` are UV-urile ei si ar
	# esantiona tot atlasul). Segmentele sunt SETATE explicit (CLAUDE.md — o
	# primitiva lasata la implicit aduce 4.224 de triunghiuri; aici ies 168).
	var mi := MeshInstance3D.new()
	mi.mesh = _ellipsoid_mesh(ENVELOPE_RADIUS, ENVELOPE_HEIGHT * 0.5,
		12, 7, envelope_slot)
	# Baza panzei la ~2 m peste cos (franghiile), varful la ENVELOPE_HEIGHT.
	mi.position = Vector3(0.0, 2.0 + ENVELOPE_HEIGHT * 0.5, 0.0)
	mi.material_override = Palette.world_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_envelope.add_child(mi)


## Elipsoid pe un singur slot de paleta. `segments` x `rings` sunt DATE, nu
## implicite — vezi nota din `_build_envelope`.
func _ellipsoid_mesh(rx: float, ry: float, segments: int, rings: int,
		slot: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	for i in rings:
		var v0 := float(i) / float(rings)
		var v1 := float(i + 1) / float(rings)
		for j in segments:
			var u0 := float(j) / float(segments)
			var u1 := float(j + 1) / float(segments)
			var quad := [
				_ellipsoid_point(u0, v0, rx, ry), _ellipsoid_point(u1, v0, rx, ry),
				_ellipsoid_point(u1, v1, rx, ry), _ellipsoid_point(u0, v1, rx, ry),
			]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					var p: Vector3 = quad[k]
					st.set_normal(p.normalized())
					st.set_uv(uv)
					st.set_color(Color.WHITE)
					st.add_vertex(p)
	var mesh := st.commit()
	mesh.surface_set_material(0, Palette.world_material())
	return mesh


func _ellipsoid_point(u: float, v: float, rx: float, ry: float) -> Vector3:
	var phi := v * PI
	var theta := u * TAU
	return Vector3(sin(phi) * cos(theta) * rx, cos(phi) * ry,
		sin(phi) * sin(theta) * rx)


## Cablul de ancorare: o linie de la tarusul de la sol la cos. NU se rescala pe
## cadru (ar fi al doilea transform pe cadru) — e un tub static pe cursa
## intreaga, ca la cablul telecabinei.
func _build_tether() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Transform3D(Basis.IDENTITY, Vector3(0.0, height * 0.5, 0.0)),
		Vector3(TETHER_RADIUS * 2.0, height, TETHER_RADIUS * 2.0), tether_slot)
	_tether = MeshInstance3D.new()
	_tether.name = "Tether"
	_tether.mesh = st.commit()
	_tether.material_override = Palette.world_material()
	_tether.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_tether)


func _add_shape(body: PhysicsBody3D, size: Vector3, at: Vector3) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	return shape


func _box_mesh(size: Vector3, slot: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Transform3D.IDENTITY, size, slot)
	var mesh := st.commit()
	mesh.surface_set_material(0, Palette.world_material())
	return mesh


## Cutie orientata, 12 triunghiuri, toate UV-urile pe slotul de paleta.
func _add_box(st: SurfaceTool, xf: Transform3D, size: Vector3, slot: int) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var faces := [
		[Vector3.UP, Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(-1, 1, -1)],
		[Vector3.DOWN, Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1)],
		[Vector3.RIGHT, Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1)],
		[Vector3.LEFT, Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1)],
		[Vector3.BACK, Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3.FORWARD, Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
	]
	for f: Array in faces:
		var normal: Vector3 = xf.basis * (f[0] as Vector3)
		var pts: Array[Vector3] = []
		for k in range(1, 5):
			pts.append(xf * ((f[k] as Vector3) * h))
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.set_normal(normal)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(pts[k])


# ---------------------------------------------------------------- miscare

func _physics_process(delta: float) -> void:
	if _body == null or Engine.is_editor_hint():
		return
	if not _started:
		_started = true
		_time = phase * period
	_time += delta
	var prev_state := _state
	var s := _progress(fposmod(_time, period))
	_place(s)
	_velocity = (_body.global_position - _prev_pos) / maxf(delta, 0.0001)
	_prev_pos = _body.global_position
	_body.set_meta(&"platform_velocity", _velocity)
	if _state != prev_state:
		_on_state_changed(prev_state, _state)
	_hold_aboard()


## Fractia de cursa (0 = jos, 1 = sus) la momentul t din ciclu; seteaza starea.
##
## Capetele sunt smoothstep pe TOATA cursa, deliberat: acceleratia porneste si
## se stinge de la zero, deci nu exista treapta care sa desprinda masina de
## podea (nota 3 din antet). Varful de acceleratie e 6*H/T².
func _progress(t: float) -> float:
	var t_rise := ground_hold
	var t_top := t_rise + rise_time
	var t_fall := t_top + hold
	var fall_time := maxf(period - t_fall, 0.5)
	if t < t_rise:
		_state = State.JOS
		return 0.0
	if t < t_top:
		_state = State.URCA
		return smoothstep(0.0, 1.0, (t - t_rise) / rise_time)
	if t < t_fall:
		_state = State.SUS
		return 1.0
	_state = State.COBOARA
	return 1.0 - smoothstep(0.0, 1.0, clampf((t - t_fall) / fall_time, 0.0, 1.0))


## O SINGURA scriere de transform pe cadru (Jolt + sync_to_physics).
func _place(s: float) -> void:
	var p := global_position
	_body.global_transform = Transform3D(Basis.IDENTITY,
		Vector3(p.x, _base_y + height * s, p.z))


func _on_state_changed(_from: State, to: State) -> void:
	if to != State.SUS and to != State.JOS:
		return
	# Cosul s-a oprit dupa o cursa de `height` metri: fereastra locala de index
	# nu vede noul etaj si nu exista aterizare de raportat (rotile n-au parasit
	# podeaua). El a mutat-o, el o anunta (nota 5 din antet).
	for key in _aboard.keys():
		# `is_instance_valid` PRIMUL, si pe cheia bruta: `key as Car` pe un obiect
		# deja eliberat arunca el insusi („Trying to cast a freed object"), deci o
		# garda de dupa cast n-apuca sa apere nimic. Vezi nota din `_hold_aboard`.
		if not is_instance_valid(key):
			_aboard.erase(key)
			continue
		var car := key as Car
		if car == null or car.track == null:
			continue
		car.road_index = car.track.closest_index_global(
			car.global_position, car.route)


## Ancora: arc+amortizor ORIZONTAL spre locul unde masina a aterizat pe cos.
## Vertical nu se atinge — acolo tine suspensia ei. Cine a parasit podeaua e
## lasat in plata vaii.
func _hold_aboard() -> void:
	var overlapping := _deck.get_overlapping_bodies()
	# Cine e nou pe podea isi inregistreaza ancora acolo unde a aterizat.
	#
	# Conditia nu e „se suprapune cu zona", ci [b]sta pe podea[/b]: cosul n-are
	# usi ca telecabina, deci fara ea o masina care doar RAZUIESTE cosul in
	# trecere (sau il atinge cu botul in banda) ar fi ancorata pe loc si oprita
	# din plin — adica exact teleportarea pe care hazardul n-are voie s-o faca.
	# Doua conditii, amandoua ieftine: roti pe sol, si cota apropiata de podea.
	for b in overlapping:
		var car := b as Car
		if car == null or _aboard.has(car):
			continue
		if car.wheels_on_ground < 3:
			continue
		if absf(_body.to_local(car.global_position).y) > 1.0:
			continue
		_aboard[car] = _body.to_local(car.global_position)
	for key in _aboard.keys():
		# ORDINEA CONTEAZA, si a fost gresita: in GDScript `key as Car` pe un
		# obiect eliberat arunca „Trying to cast a freed object" — eroarea vine
		# DIN cast, deci un `is_instance_valid` de dupa el nu mai are ce salva.
		# Cum bucla asta ruleaza in `_physics_process`, o masina eliberata cat e
		# la bord (respawn, sfarsit de cursa, `queue_free` din sonde) o repeta la
		# 60 Hz: masurat, 3007 erori si ~1 MB de stderr intr-o singura rulare de
		# sonda. Cheia bruta se verifica INTAI, si abia pe urma se caste.
		if not is_instance_valid(key):
			_aboard.erase(key)
			continue
		var car := key as Car
		if car == null or not overlapping.has(car):
			_aboard.erase(key)
			continue
		_pull_to(car, _aboard[key] as Vector3, hold_max_accel)


func _pull_to(car: Car, anchor_local: Vector3, max_accel: float) -> void:
	var d := _body.to_global(anchor_local) - car.global_position
	d.y = 0.0
	var dv := _velocity - car.linear_velocity
	dv.y = 0.0
	var acc := (d * hold_stiffness + dv * hold_damping).limit_length(max_accel)
	car.apply_central_force(acc * car.mass)


# ---------------------------------------------------------------- pentru sonde

func body() -> AnimatableBody3D:
	return _body


func state() -> State:
	return _state


func cycle_time() -> float:
	return fposmod(_time, period)


func velocity() -> Vector3:
	return _velocity


func aboard() -> Array:
	return _aboard.keys()


func on_deck() -> Array:
	var out: Array = []
	for b in _deck.get_overlapping_bodies():
		if b is Car:
			out.append(b)
	return out


## Cota podelei acum.
func floor_y() -> float:
	return _body.global_position.y


## Cota podelei la varful cursei.
func top_y() -> float:
	return _base_y + height


func base_y() -> float:
	return _base_y


## Fereastra din ciclu (secunde, [intrare, iesire]) in care podeaua cosului e
## peste `lane_y - tol`, adica „cosul e in banda". Pentru verdictul de defazare.
## Intoarce (-1, -1) daca nu ajunge niciodata acolo.
func lane_window(lane_y: float, tol: float = 1.0) -> Vector2:
	var target := lane_y - tol - _base_y
	if target <= 0.0:
		return Vector2(0.0, period)
	if target > height:
		return Vector2(-1.0, -1.0)
	# smoothstep e monotona pe [0,1]: se inverseaza prin injumatatire.
	var want := target / height
	var lo := 0.0
	var hi := 1.0
	for _i in 40:
		var mid := (lo + hi) * 0.5
		if smoothstep(0.0, 1.0, mid) < want:
			lo = mid
		else:
			hi = mid
	var frac := (lo + hi) * 0.5
	var t_in := ground_hold + frac * rise_time
	var fall_time := maxf(period - (ground_hold + rise_time + hold), 0.5)
	var t_out := ground_hold + rise_time + hold + (1.0 - frac) * fall_time
	return Vector2(t_in, t_out)


## Varful de acceleratie verticala al profilului (m/s²), analitic: pentru
## smoothstep pe H metri in T secunde e 6*H/T². Sonda il compara cu masuratoarea.
func peak_accel() -> float:
	return 6.0 * height / (rise_time * rise_time)
