@tool
class_name CablewayHazard
extends Node3D
## Telecabina (Chongqing, brief §2 E′ / §3 „riscul nr. 2"): o cabina-platforma
## care pleaca din statia de jos la interval fix, cara masina peste golf si o
## lasa la etajul de sus. Scurtatura pe TIMING vizibil: cabina se vede venind
## pe cablu; daca ajungi in fereastra de imbarcare o prinzi, daca nu, mergi pe
## pod.
##
## Traseul e curba unui Path3D copil numit „Route" (primul punct = statia de
## jos, ultimul = statia de sus; punctele din mijloc primesc cate un turn cu
## cablul trecut pe varf), desenat cu gizmo-ul standard, ca la PathMover si
## la traseul de rostogolire al HazardMarker. Ritmul e in exporturi.
##
## Ciclul (period): IMBARCARE la statia de jos (boarding_window) → URCARE
## (travel_time) → DEBARCARE sus (unload_time) → COBORARE (ce ramane din
## perioada). Cate o cabina per nod; doua noduri cu `phase` diferit fac un
## du-te-vino ca o telecabina adevarata.
##
## Fizica — cele trei capcane cunoscute si cum sunt inchise (ProbeCableway):
##  1. Corpul e AnimatableBody3D cu sync_to_physics si transformul se scrie O
##     DATA pe cadru (memoria `jolt-sync-transform-o-singura-scriere`).
##  2. Masina sta pe podea prin SUSPENSIA ei (raycast pe podeaua cabinei), nu
##     prin coliziune de corp — deci nu e „platforma" in sensul solverului.
##     Ca sa nu fie data jos de propriile ei forte de cauciuc, corpul cabinei
##     publica meta `platform_velocity`, iar Car isi socoteste drag-ul, grip-ul
##     lateral, amortizorul si plafonul de viteza fata de sol, nu fata de lume.
##  3. Longitudinal, cauciucul NU tine (rotile se invart liber): la plecare
##     masina ar aluneca pe usa din spate. Cabina o ANCOREAZA pe durata
##     traversarii — un arc+amortizor spre locul unde statea cand s-au inchis
##     usile (chocks sub roti), plafonat ca sa nu poata arunca. La sosire
##     usile se deschid, ancora dispare si masina pleaca pe roti.
##  4. Indexul de pista: fereastra locala (~72 m pe ruta) nu vede etajul de
##     sus, si nu exista „aterizare" (rotile n-au parasit podeaua). La sosire
##     cabina recauta indexul global pentru fiecare masina de la bord — ea e
##     cea care a teleportat-o, ea o si anunta.
##  5. IMBARCAREA la viteza (runda 2 a sondei): podeaua are 4.25 m, iar o
##     masina care soseste in fereastra cu 18 m/s si acceleratia tinuta trecea
##     prin capatul deschis din fata si cadea in golf (masurat: y=-31 m).
##     Doua masuri, amandoua vizibile: (a) BARE la capete — bara din fata e
##     coborata mereu, mai putin la debarcare; usa din spate se inchide la
##     plecare; (b) PRINDEREA: cat stau usile deschise jos, orice masina
##     intrata pe podea e trasa spre centrul ei de un arc+amortizor cu plafon
##     mai mare decat al ancorei de drum (catch_max_accel) — „lantul" care te
##     opreste pe un bac. Din 18 m/s cu gazul tinut se opreste in ~3.5 m.
##  6. USA DIN SPATE NU SE INCHIDE PESTE MASINA (runda 3): o masina care intra
##     pe podea in ultima zecime a ferestrei (26 m/s, gazul tinut) inca sta
##     peste pragul usii cand vine plecarea; colizerul barei activat sub ea o
##     lasa calare, fara roti pe podea, si cade de pe spatele cabinei in
##     timpul traversarii (masurat: y=-5 m, |vy| 17). Ca la orice usa cu
##     senzor: cat timp o masina e in prag, PLECAREA ASTEAPTA (cel mult
##     door_hold_max), prinderea o trage inauntru, apoi se inchide. Daca nici
##     asa nu s-a eliberat pragul, masina NU e la bord si usa ramane
##     deschisa (bara dezactivata) pana iese din suprapunere — nu e aruncata,
##     ramane pe peron.

## Tabelul de clase de material, prin PRELOAD (vezi PathMover).
const WorldProp = preload("res://scenes/props/world_prop.gd")
const CABIN_MODEL: String = "res://assets/models/chongqing/vehicles/cableway_cabin.glb"
const TOWER_MODEL: String = "res://assets/models/chongqing/structures/cableway_tower.glb"
## Gabaritul cabinei (din GLB: 5.25 x 4.25 m, podeaua la y=0, talpa la -0.48).
const CABIN_SIZE := Vector3(5.25, 4.35, 4.25)
const FLOOR_THICKNESS: float = 0.48
const WALL_HEIGHT: float = 1.4
const WALL_THICKNESS: float = 0.12
## Barele de la capete: iesite cu putin peste marginea podelei, ca masina
## (colizer 3.8 m) sa aiba loc intre ele (2 x 2.27 m).
const END_BAR_OVERHANG: float = 0.2
const END_BAR_HEIGHT: float = 0.5
## Nota 6: cat loc se cere intre gabaritul masinii si usa ca sa se inchida.
const DOOR_MARGIN: float = 0.1
## Varful turnului din GLB (unde trece cablul).
const TOWER_TOP: float = 16.14
## Turnul sta LANGA linia cablului, nu pe ea: cabina trece pe langa el, iar
## coliziunea lui n-are voie sa intre in cabina (masurat: pe linie, colizerul
## turnului dadea masina jos din cabina la trecere).
const TOWER_SIDE_OFFSET: float = 5.5
const CABLE_RADIUS: float = 0.06
const CABLE_STEP: float = 6.0
const PLACEHOLDER_COLOR := Color(0.85, 0.75, 0.15)

enum State { BOARDING, UP, UNLOADING, DOWN }

@export_group("Ritm")
## Intervalul dintre doua plecari de jos (s). Brief: ~20, si NU divizor al
## turului — faza se muta de la tur la tur.
@export_range(6.0, 120.0, 0.5) var period: float = 20.0
## Cat sta cu usile deschise jos (s). Brief: ~3.
@export_range(0.5, 20.0, 0.1) var boarding_window: float = 3.0
## Durata traversarii (s). Brief: 8.
@export_range(1.0, 60.0, 0.1) var travel_time: float = 8.0
## Cat sta sus cu usile deschise (s), ca masina sa coboare.
@export_range(0.5, 20.0, 0.1) var unload_time: float = 2.0
## Decalajul ciclului (0..1 din period). Doua noduri in opozitie de faza =
## o cabina urca in timp ce cealalta coboara.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

@export_group("Ancora")
## Arcul care tine masina pe locul de imbarcare in timpul traversarii (1/s^2)
## si amortizarea lui (1/s). La 60/15, o acceleratie de varf de 14 m/s^2 a
## cabinei (150 m in 8 s, smoothstep) lasa masina cu ~0.25 m in urma.
@export_range(0.0, 200.0, 1.0) var hold_stiffness: float = 60.0
@export_range(0.0, 60.0, 0.5) var hold_damping: float = 15.0
## Plafonul acceleratiei ancorei (m/s^2): tine, dar nu poate arunca.
@export_range(1.0, 80.0, 1.0) var hold_max_accel: float = 30.0
## Prinderea la imbarcare (nota 5): plafonul (m/s^2) cu care cabina opreste
## o masina intrata pe podea cat usile sunt deschise jos. 60 cu gazul tinut
## (16 m/s^2) inseamna 44 net: 18 m/s se opresc in 3.7 m, sub podeaua de 4.25.
@export_range(1.0, 120.0, 1.0) var catch_max_accel: float = 60.0
## Nota 6: cat poate intarzia plecarea o masina prinsa in pragul usii (s).
@export_range(0.0, 3.0, 0.05) var door_hold_max: float = 1.0

@export_group("Constructie")
## Cabina si turnul: goale = modelele din kitul Chongqing.
@export var cabin_model: PackedScene = null
@export var tower_model: PackedScene = null
@export_range(0.2, 3.0, 0.05) var model_scale: float = 1.0
## Peronul static de la fiecare statie (m), in prelungirea podelei: jos in
## spatele cabinei (de unde intri), sus in fata ei (pe unde iesi). 0 = fara.
@export_range(0.0, 20.0, 0.5) var dock_length: float = 6.0
## Rampa de acces la capatul fiecarui peron (jos in spate, sus in fata): o
## pana care coboara `apron_drop` pe `apron_length`, ca marginea peronului sa
## nu fie prag. Masurat in ProbeCableway: soseaua e cu 0.6 m sub podea la
## marginea drumului, iar fata peronului (0.37 m peste talpa colizerului) era
## un zid — masina se oprea in ea cu botul (memoria `suprafete-cu-goluri-
## si-praguri`: pragurile > 0.3 m sunt ziduri, marginile se fac in panta).
## Capatul de jos al penei intra in pamant: nu e nevoie de cota din raycast.
@export_range(0.0, 10.0, 0.5) var apron_length: float = 3.0
@export_range(0.0, 2.0, 0.05) var apron_drop: float = 0.7
## Slotul de paleta al peroanelor si al cablului.
@export_range(0, 31) var dock_slot: int = 8
@export_range(0, 31) var cable_slot: int = 10

var _body: AnimatableBody3D
var _deck: Area3D
var _front_bar: CollisionShape3D
var _rear_bar: CollisionShape3D
var _front_bar_mesh: MeshInstance3D
var _rear_bar_mesh: MeshInstance3D
var _pivot: Node3D
var _route: Path3D
var _length: float = 0.0
var _yaw: float = 0.0
var _time: float = 0.0
var _started: bool = false
var _state: State = State.BOARDING
var _velocity: Vector3 = Vector3.ZERO
var _prev_pos: Vector3 = Vector3.ZERO
## Car -> ancora (pozitia locala pe podea) pentru masinile de la bord.
var _aboard: Dictionary = {}
## Nota 6: cat a asteptat plecarea in ciclul curent si daca usa din spate
## a ramas deschisa peste o masina neimbarcata.
var _door_hold: float = 0.0
var _rear_door_pending: bool = false


func _ready() -> void:
	_route = _find_route()
	if _route == null or _route.curve == null or _route.curve.point_count < 2:
		push_warning("CablewayHazard '%s': ii lipseste copilul Path3D 'Route' cu cel putin 2 puncte" % name)
		return
	_length = _route.curve.get_baked_length()
	var a := _station(0.0)
	var b := _station(1.0)
	var dir := b - a
	dir.y = 0.0
	_yaw = atan2(-dir.x, -dir.z) if dir.length_squared() > 0.001 else 0.0
	_build_body()
	_build_docks(a, b)
	_build_towers()
	_build_cable()
	_place(0.0)
	_prev_pos = _body.global_position
	_set_bars(_state)


func _find_route() -> Path3D:
	var named := get_node_or_null("Route") as Path3D
	if named != null:
		return named
	for c in get_children():
		if c is Path3D:
			return c as Path3D
	return null


## Pozitia globala pe traseu la fractia s (0 = jos, 1 = sus).
func _station(s: float) -> Vector3:
	return _route.to_global(_route.curve.sample_baked(clampf(s, 0.0, 1.0) * _length, true))


# ---------------------------------------------------------------- constructie

func _build_body() -> void:
	_body = AnimatableBody3D.new()
	_body.name = "Cabin"
	_body.sync_to_physics = true
	add_child(_body)
	_body.set_meta(&"platform_velocity", Vector3.ZERO)
	# Podeaua: cutie cu fata de sus la y=0 — masina STA pe ea prin raycast.
	_add_shape(_body, Vector3(CABIN_SIZE.x, FLOOR_THICKNESS, CABIN_SIZE.z),
		Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0))
	# Peretii laterali (stanga/dreapta fata de sensul de mers); capetele raman
	# deschise: intri pe spate, iesi pe fata.
	for sx in [-1.0, 1.0]:
		_add_shape(_body, Vector3(WALL_THICKNESS, WALL_HEIGHT, CABIN_SIZE.z),
			Vector3(sx * (CABIN_SIZE.x - WALL_THICKNESS) * 0.5, WALL_HEIGHT * 0.5, 0.0))
	# Barele de la capete (nota 5): fata (-Z local) si spate (+Z local),
	# comutate pe stari — colizer + o bara vizibila pe slotul peronului.
	var bar_size := Vector3(CABIN_SIZE.x, END_BAR_HEIGHT, WALL_THICKNESS)
	var bar_z := CABIN_SIZE.z * 0.5 + END_BAR_OVERHANG
	_front_bar = _add_shape(_body, bar_size, Vector3(0.0, END_BAR_HEIGHT * 0.5, -bar_z))
	_rear_bar = _add_shape(_body, bar_size, Vector3(0.0, END_BAR_HEIGHT * 0.5, bar_z))
	_front_bar_mesh = _bar_mesh(bar_size, _front_bar.position)
	_rear_bar_mesh = _bar_mesh(bar_size, _rear_bar.position)
	_pivot = Node3D.new()
	_body.add_child(_pivot)
	var scene := cabin_model if cabin_model != null else load(CABIN_MODEL) as PackedScene
	var inst: Node3D = scene.instantiate() as Node3D if scene != null else null
	if inst != null:
		inst.scale = Vector3.ONE * model_scale
		Palette.apply_object_class_materials(inst, WorldProp.prop_classes(), model_scale)
		_pivot.add_child(inst)
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = _box_mesh(Vector3(CABIN_SIZE.x, 0.3, CABIN_SIZE.z), dock_slot)
		mi.position = Vector3(0.0, -0.15, 0.0)
		_pivot.add_child(mi)
	# Zona podelei: cine e in ea cand se inchid usile e la bord.
	_deck = Area3D.new()
	_deck.name = "Deck"
	_deck.monitoring = true
	_deck.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(CABIN_SIZE.x, 2.5, CABIN_SIZE.z)
	shape.shape = box
	shape.position = Vector3(0.0, 1.25, 0.0)
	_deck.add_child(shape)
	_body.add_child(_deck)


func _add_shape(body: PhysicsBody3D, size: Vector3, at: Vector3) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	return shape


func _bar_mesh(size: Vector3, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _box_mesh(size, dock_slot)
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(mi)
	return mi


## Bara din fata e coborata mereu, mai putin la debarcare (iesi pe fata);
## usa din spate e deschisa doar la imbarcare (intri pe spate).
func _set_bars(st: State) -> void:
	var front_open := st == State.UNLOADING
	var rear_open := st == State.BOARDING or _rear_door_pending
	_front_bar.disabled = front_open
	_rear_bar.disabled = rear_open
	_front_bar_mesh.visible = not front_open
	_rear_bar_mesh.visible = not rear_open


## Peroanele: jos in spatele cabinei (+Z local), sus in fata ei (-Z local).
func _build_docks(a: Vector3, b: Vector3) -> void:
	if dock_length <= 0.0:
		return
	var basis := Basis(Vector3.UP, _yaw)
	var size := Vector3(CABIN_SIZE.x, FLOOR_THICKNESS, dock_length)
	var half := (CABIN_SIZE.z + dock_length) * 0.5
	for entry: Array in [[a, half], [b, -half]]:
		var at: Vector3 = entry[0]
		var dz: float = entry[1]
		var dock := StaticBody3D.new()
		dock.name = "Dock"
		add_child(dock)
		dock.global_transform = Transform3D(basis,
			at + basis * Vector3(0.0, -FLOOR_THICKNESS * 0.5, dz))
		_add_shape(dock, size, Vector3.ZERO)
		var mi := MeshInstance3D.new()
		mi.mesh = _box_mesh(size, dock_slot)
		dock.add_child(mi)
		if apron_length <= 0.0:
			continue
		# Pana de acces, in continuarea peronului, cu suprafata de sus
		# plecand din cota podelei si coborand spre capatul dinspre drum.
		var sign := signf(dz)
		var pitch := sign * atan2(apron_drop, apron_length)
		var apron_basis := basis * Basis(Vector3.RIGHT, pitch)
		var apron_len := sqrt(apron_length * apron_length + apron_drop * apron_drop)
		var apron_size := Vector3(CABIN_SIZE.x, FLOOR_THICKNESS, apron_len)
		var apron := StaticBody3D.new()
		apron.name = "Apron"
		add_child(apron)
		var top_edge := at + basis * Vector3(0.0, 0.0, dz + sign * dock_length * 0.5)
		apron.global_transform = Transform3D(apron_basis,
			top_edge + apron_basis * Vector3(0.0, -FLOOR_THICKNESS * 0.5, sign * apron_len * 0.5))
		_add_shape(apron, apron_size, Vector3.ZERO)
		var ami := MeshInstance3D.new()
		ami.mesh = _box_mesh(apron_size, dock_slot)
		apron.add_child(ami)


## Un turn la fiecare punct de control intermediar, cu varful la cablu,
## asezat lateral fata de linie (TOWER_SIDE_OFFSET).
func _build_towers() -> void:
	var scene := tower_model if tower_model != null else load(TOWER_MODEL) as PackedScene
	if scene == null:
		return
	var curve := _route.curve
	for i in range(1, curve.point_count - 1):
		var p := _route.to_global(curve.get_point_position(i))
		var inst := scene.instantiate() as Node3D
		if inst == null:
			continue
		inst.name = "Tower%d" % i
		inst.scale = Vector3.ONE * model_scale
		Palette.apply_object_class_materials(inst, WorldProp.prop_classes(), model_scale)
		add_child(inst)
		var basis := Basis(Vector3.UP, _yaw)
		inst.global_transform = Transform3D(basis,
			p + Vector3.UP * (CABIN_SIZE.y - TOWER_TOP * model_scale)
			+ basis * Vector3(TOWER_SIDE_OFFSET, 0.0, 0.0))
		var body := StaticBody3D.new()
		inst.add_child(body)
		_add_shape(body, Vector3(5.3, TOWER_TOP, 5.4), Vector3(0.0, TOWER_TOP * 0.5, 0.0))


## Cablul: tub subtire pe traseu, la inaltimea carligului cabinei. Un singur
## mesh, materialul lumii (fara material nou).
func _build_cable() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(int(ceil(_length / CABLE_STEP)), 1)
	var lift := Vector3.UP * (CABIN_SIZE.y * model_scale)
	for i in n:
		var p0 := _station(float(i) / float(n)) + lift
		var p1 := _station(float(i + 1) / float(n)) + lift
		var seg := p1 - p0
		var len := seg.length()
		if len < 0.01:
			continue
		var basis := Basis.looking_at(seg.normalized(), Vector3.UP)
		_add_box(st, Transform3D(basis, (p0 + p1) * 0.5),
			Vector3(CABLE_RADIUS * 2.0, CABLE_RADIUS * 2.0, len), cable_slot)
	var mi := MeshInstance3D.new()
	mi.name = "Cable"
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


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
	# Nota 6: usa cu senzor — plecarea asteapta cat o masina sta in prag.
	if _state == State.BOARDING and fposmod(_time, period) >= boarding_window 			and _door_hold < door_hold_max and not _doorway_cars().is_empty():
		_time -= delta
		_door_hold += delta
	var t := fposmod(_time, period)
	var prev_state := _state
	var s := _progress(t)
	_place(s)
	_velocity = (_body.global_position - _prev_pos) / maxf(delta, 0.0001)
	_prev_pos = _body.global_position
	_body.set_meta(&"platform_velocity", _velocity)
	if _state != prev_state:
		_on_state_changed(prev_state, _state)
		_set_bars(_state)
	if _rear_door_pending and _doorway_cars().is_empty():
		_rear_door_pending = false
		_set_bars(_state)
	if _state == State.BOARDING:
		_catch_boarding()
	elif _state == State.UP or _state == State.DOWN:
		_hold_aboard()


## Fractia pe traseu la momentul t din ciclu; seteaza si starea.
func _progress(t: float) -> float:
	var t_up := boarding_window
	var t_top := t_up + travel_time
	var t_down := t_top + unload_time
	var down_time := maxf(period - t_down, 1.0)
	if t < t_up:
		_state = State.BOARDING
		return 0.0
	if t < t_top:
		_state = State.UP
		return smoothstep(0.0, 1.0, (t - t_up) / travel_time)
	if t < t_down:
		_state = State.UNLOADING
		return 1.0
	_state = State.DOWN
	return 1.0 - smoothstep(0.0, 1.0, clampf((t - t_down) / down_time, 0.0, 1.0))


## O SINGURA scriere de transform pe cadru (Jolt + sync_to_physics).
func _place(s: float) -> void:
	_body.global_transform = Transform3D(Basis(Vector3.UP, _yaw), _station(s))


func _on_state_changed(from: State, to: State) -> void:
	if to == State.BOARDING:
		_door_hold = 0.0
	if to == State.UP or to == State.DOWN:
		# Usile se inchid: cine e pe podea e la bord, ancorat unde sta — mai
		# putin cine a ramas in pragul usii din spate (nota 6): usa ramane
		# deschisa peste el si el ramane pe peron.
		_aboard.clear()
		var doorway := _doorway_cars()
		_rear_door_pending = to == State.UP and not doorway.is_empty()
		for b in _deck.get_overlapping_bodies():
			var car := b as Car
			if car == null or doorway.has(car):
				continue
			_aboard[car] = _body.to_local(car.global_position)
	elif from == State.UP or from == State.DOWN:
		# Usile se deschid: masina isi afla etajul si pleaca pe roti.
		for key in _aboard.keys():
			var car := key as Car
			if car == null or not is_instance_valid(car) or car.track == null:
				continue
			car.road_index = car.track.closest_index_global(car.global_position, car.route)
		_aboard.clear()


## Masinile de pe podea al caror gabarit (colizerul, in lungul cabinei)
## se suprapune cu bara din spate — usa nu se poate inchide peste ele.
func _doorway_cars() -> Array:
	var out: Array = []
	var bar_near := _rear_bar.position.z - WALL_THICKNESS * 0.5 - DOOR_MARGIN
	for b in _deck.get_overlapping_bodies():
		var car := b as Car
		if car == null:
			continue
		var half_len := car.collider_half_length()
		var local := _body.to_local(car.global_position)
		# Directia masinii poate fi oblica: proiecteaza jumatatea de lungime pe
		# axa cabinei si ia maximul dintre lungime si latime.
		var fwd := _body.global_transform.basis.inverse() * (-car.global_transform.basis.z)
		var reach := maxf(absf(fwd.z) * half_len, car.collider_half_width())
		if local.z + reach > bar_near:
			out.append(car)
	return out


## Prinderea la imbarcare (nota 5): cat usile sunt deschise jos, orice masina
## de pe podea e trasa spre centrul ei — asa se opreste o masina care intra
## la viteza, inainte sa ajunga in bara din fata. Aceeasi lege ca ancora
## (arc+amortizor fata de cabina), cu plafon mai mare.
func _catch_boarding() -> void:
	for b in _deck.get_overlapping_bodies():
		var car := b as Car
		if car == null:
			continue
		_pull_to(car, Vector3.ZERO, catch_max_accel)


## Arc+amortizor orizontal spre punctul local `anchor` al cabinei.
func _pull_to(car: Car, anchor_local: Vector3, max_accel: float) -> void:
	var d := _body.to_global(anchor_local) - car.global_position
	d.y = 0.0
	var dv := _velocity - car.linear_velocity
	dv.y = 0.0
	var acc := (d * hold_stiffness + dv * hold_damping).limit_length(max_accel)
	car.apply_central_force(acc * car.mass)


## Ancora din timpul traversarii (vezi nota 3 din antet). Orizontal doar:
## vertical o tine suspensia ei pe podea. Cine a parasit podeaua (sarit,
## impins) e lasat in plata golfului.
func _hold_aboard() -> void:
	if _aboard.is_empty():
		return
	var overlapping := _deck.get_overlapping_bodies()
	for key in _aboard.keys():
		var car := key as Car
		if car == null or not is_instance_valid(car):
			_aboard.erase(key)
			continue
		if not overlapping.has(car):
			_aboard.erase(key)
			continue
		_pull_to(car, _aboard[key] as Vector3, hold_max_accel)


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


func door_hold() -> float:
	return _door_hold


func rear_door_pending() -> bool:
	return _rear_door_pending


func doorway_cars() -> Array:
	return _doorway_cars()


## Masinile de pe podea in clipa asta (indiferent de usi).
func on_deck() -> Array:
	var out: Array = []
	for b in _deck.get_overlapping_bodies():
		if b is Car:
			out.append(b)
	return out


func station_bottom() -> Vector3:
	return _station(0.0)


func station_top() -> Vector3:
	return _station(1.0)


func travel_yaw() -> float:
	return _yaw
