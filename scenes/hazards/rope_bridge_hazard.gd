@tool
class_name RopeBridgeHazard
extends Node3D
## Podul de franghie (Machu Picchu, brief §2 POI E / §3 „Podul de franghie"):
## un tablier suspendat care SE AFUNDA sub masa masinilor de pe el si SE
## LEAGANA lateral cand intri descentrat. E hazardul-semnatura al pistei si
## prima suprafata din joc care face masa masinii vizibila fara contact intre
## masini: Autobuzul (mass_factor 2.6) lasa mijlocul cu ~1.5 m, sportul (0.9)
## cu ~0.6 m, iar masina usoara aflata pe pod cand intra una grea e RIDICATA
## de val. Fara pereti: cazi de pe el, RespawnZone-ul pistei te repune.
##
## [b]Cum se declara in Track15.tscn[/b] (acelasi tipar ca CablewayHazard —
## un nod cu scriptul asta, direct sub radacina pistei, NU prin HazardMarker):
##
##   [node name="PodFranghie" type="Node3D" parent="."]
##   script = ExtResource("rope_bridge")
##   near_end = Vector3(x0, y0, z0)   # buza de plecare, LOCAL fata de nod
##   far_end = Vector3(x1, y1, z1)    # buza de sosire (35 m mai departe)
##   deck_width = 5.5
##
## sau, editabil cu gizmo, un copil Path3D numit „Route" cu DOUA puncte
## (primul = buza de plecare, ultimul = buza de sosire); daca exista, el
## bate exporturile. Cele doua capete trebuie sa fie CHIAR pe cota soselei la
## buze (tablierul incepe la nivelul lor, fara prag), iar pista trebuie sa
## lase GOL carosabilul intre ele (custom_ravines) — podul e drumul acolo.
## Latimea e a tablierului; soseaua de la buze poate fi mai lata.
##
## [b]Modelul fizic[/b] (brief §3: NU lant de RigidBody3D cu joint-uri —
## 30 de corpuri pe mobil nu se pot; doua ecuatii de arc-amortizor pe pod):
##  1. SAGEATA globala `A`: arc+amortizor spre tinta
##       A_tinta = Σ a_i · P(u_i),  P(u) = 4u(1-u),  a_i = gain · m_i^exp
##     (gain/exp derivate din `sag_bus`/`sag_sport`, ca tuning-ul sa fie in
##     metri, nu in coeficienti). Forma modului: P(u) in jos MINUS valul
##     `wave_gain · sin²(2πu)`, care ridica sferturile cand mijlocul coboara —
##     o franghie de lungime fixa isi trage slabirea din parti. Peste el,
##     fiecare masina isi lasa o AFUNDARE LOCALA (gaussiana de `dip_sigma`
##     metri, `dip_ratio` din a_i) care merge cu ea: tablierul cedeaza sub
##     roti oriunde stai, nu doar la mijloc. Sageata de repaus `rest_sag` e
##     separata si permanenta (franghia nu e niciodata intinsa).
##  2. BALANSUL lateral `x` (deplasarea liniei mediane la mijloc, m): pendul
##     amortizat spre echilibrul dat de masa descentrata,
##       x_ech = sway_gain · Σ m_i · x_i · P(u_i) / (deck_mass + Σ m_i · P(u_i)),
##     unde x_i e lateralul masinii fata de COARDA (nu fata de tablier):
##     tablierul se muta SPRE partea grea si o duce cu el — de-aia intrarea
##     descentrata te apropie de margine. Coeficientul ramane < 1 pentru
##     autobuz (deck_mass), altfel bucla ar fugi. Un viraj pe tablier
##     schimba x_i, deci excita la fel. Ruliul e al unui scaun de leagan:
##     deplasat la dreapta, marginea dreapta URCA (`roll_arm`). Peste
##     `sway_max` arcul se intareste (limita moale, fara pocnet).
##  3. TABLIERUL FIZIC: `plate_count` placi AnimatableBody3D cu sync_to_physics,
##     PERMANENTE (memoria `corp-cinematic-aparut-in-masina`: nimic nu apare
##     langa masina), asezate O DATA pe tick pe coarda dintre doua puncte
##     consecutive ale curbei (global_transform INTREG — memoria
##     `jolt-sync-transform-o-singura-scriere`). Coarda, nu tangenta la
##     centru: placile vecine impart EXACT punctul de capat, deci niciun prag
##     (memoria `suprafete-cu-goluri-si-praguri`: > 0.3 m e zid); suprapunerea
##     `plate_overlap` acopera unghiul dintre ele. Pretul coardei: sub
##     autobuzul oprit la mijloc, mijlocul placii sta cu ~0.1 m peste curba
##     vizuala (sageata coardei de 4.4 m pe curbura maxima); rotile par sa
##     pluteasca putin doar in cazul asta static. Fiecare placa publica
##     `platform_velocity` (mecanismul telecabinei: Car isi socoteste
##     amortizorul, grip-ul si plafonul fata de sol) — asa valul ridica masina
##     usoara si balansul o impinge, fara cuplu si fara apply_torque_impulse
##     (yaw-ul masinii e rescris pe tick; memoria `yaw-ul-masinii-e-rescris`).
##  4. VIZUAL: un singur mesh (scanduri, 4 cabluri, legaturi) deformat in
##     assets/shaders/rope_bridge.gdshader din ACEIASI parametri (instance
##     uniforms); placile sunt invizibile. Turnurile de piatra stau pe
##     materialul lumii; balustradele de franghie la 1 m sunt DOAR vizuale,
##     ele dau referinta fata de care se citeste afundarea (brief §2.0).
##     Sloturi: WOOD_WEATHERED 9 scanduri, DRY_VEGETATION 13 franghie,
##     MARBLE_GREY 29 turnuri. Un material nou (shaderul), zero texturi noi.
##
## [b]Capcane inchise[/b] (tools/probe_machu_pod.gd):
##  - amplitudinile sunt CONTINUE (arc+amortizor + P(u) care pleaca din 0 la
##    capete): o placa nu sare niciodata sub masina;
##  - masina „pe tablier" = in zona Deck, cu roti pe sol si la < 1.5 m de
##    curba: una cazuta sub pod sau in zbor peste el nu incarca podul;
##  - `_drop` din GDScript si `deck_drop` din shader sunt aceeasi formula —
##    daca le desparti, masina merge pe o suprafata pe care n-o vezi.

const WOOD_SLOT: int = 9
const ROPE_SLOT: int = 13
const STONE_SLOT: int = 29
## Masele de referinta din calibrarea sagetii (CarData: sport 0.9, autobuz 2.6).
const MASS_SPORT: float = 0.9
const MASS_BUS: float = 2.6
const PLATE_THICKNESS: float = 0.3
const PLANK_WIDTH: float = 0.5
const PLANK_GAP: float = 0.06
const PLANK_THICKNESS: float = 0.16
const RAIL_HEIGHT: float = 1.0
const TIE_STEP: float = 1.75
const TOWER_SIZE := Vector3(1.2, 3.9, 1.2)
const TOWER_SINK: float = 1.5
const SHADER_PATH: String = "res://assets/shaders/rope_bridge.gdshader"

@export_group("Capete")
## Buzele podului, LOCAL fata de nod (un copil Path3D „Route" le bate).
@export var near_end: Vector3 = Vector3.ZERO
@export var far_end: Vector3 = Vector3(0.0, 0.0, -35.0)
## Latimea tablierului (m). Brief: 5.5.
@export_range(3.0, 10.0, 0.1) var deck_width: float = 5.5

@export_group("Afundare")
## Sageata de REPAUS la mijloc (m), fara nimeni pe pod.
@export_range(0.0, 2.0, 0.05) var rest_sag: float = 0.5
## Cat coboara mijlocul sub autobuz (2.6) si sub sport (0.9), fata de repaus.
## Din ele ies gain-ul si exponentul legii a(m).
@export_range(0.2, 4.0, 0.05) var sag_bus: float = 1.5
@export_range(0.1, 2.0, 0.05) var sag_sport: float = 0.6
## Cat din a_i e afundarea locala de sub masina (restul e modul global).
@export_range(0.0, 1.0, 0.05) var dip_ratio: float = 0.3
## Latimea afundarii locale (m, sigma gaussiana).
@export_range(1.0, 10.0, 0.1) var dip_sigma: float = 3.5
## Valul: cat din P(u) se scade ca sin²(2πu). La 1.1, autobuzul la mijloc
## ridica mediana sferturilor cu ~0.4 m; o masina parcata acolo urca mai
## putin (~0.17 m): rotile ei stau la ±1.45 m de creasta, pe placi-coarda
## care coboara spre cuva, iar ruliul din balansul spre banda autobuzului ii
## coboara partea. Sub 1.0 valul nu mai ridica masina deloc (masurat).
@export_range(0.0, 1.5, 0.05) var wave_gain: float = 1.1
## Frecventa (Hz) si amortizarea modului global.
@export_range(0.2, 4.0, 0.05) var sag_freq: float = 1.2
@export_range(0.05, 1.5, 0.05) var sag_damping: float = 0.5

@export_group("Balans")
## Cuplajul masei descentrate in echilibrul balansului.
@export_range(0.0, 3.0, 0.05) var sway_gain: float = 1.1
## Masa efectiva a tablierului, in unitati de mass_factor (tine coeficientul
## sub 1 pentru autobuz: sway_gain·2.6/(deck_mass+2.6) < 1).
@export_range(0.5, 10.0, 0.1) var deck_mass: float = 1.5
## Frecventa (Hz) si amortizarea pendulului. Brief: se stinge in ~3 s.
@export_range(0.1, 2.0, 0.01) var sway_freq: float = 0.45
@export_range(0.05, 1.5, 0.01) var sway_damping: float = 0.35
## Limita moale a deplasarii laterale la mijloc (m). Brief: ±1.2.
@export_range(0.2, 3.0, 0.05) var sway_max: float = 1.2
## Bratul ruliului (m): roll = atan(x / roll_arm). La 20, balansul maxim
## inclina tablierul cu ~3.4°: semnalul vizual al balansului e deplasarea
## laterala (±1.2 m fata de capatul opus), nu inclinarea. Un brat mai scurt
## (8 m, ~8.5°) anula valul pentru masina de pe banda opusa autobuzului
## (partea ei coboara cu ruliul cat urca cu valul) si facea o masina PARCATA
## sa alunece spre centru cu ~0.15 m/s (cauciucul n-are aderenta statica la
## viteza zero — ramane asa si la 20, doar mai incet).
@export_range(2.0, 40.0, 0.5) var roll_arm: float = 20.0

@export_group("Constructie")
@export_range(4, 16) var plate_count: int = 8
@export_range(0.0, 0.5, 0.05) var plate_overlap: float = 0.2

var _frame: Transform3D = Transform3D.IDENTITY
var _length: float = 35.0
var _plates: Array[AnimatableBody3D] = []
var _plate_prev: Array[Vector3] = []
var _deck_area: Area3D
var _visual: MeshInstance3D
## Starea celor doua ecuatii.
var _sag: float = 0.0
var _sag_vel: float = 0.0
var _sway: float = 0.0
var _sway_vel: float = 0.0
## Afundarile locale ale tick-ului curent: [u, amplitudine] per masina.
var _dips: Array[Vector2] = []
var _sag_gain: float = 0.0
var _sag_exp: float = 1.0
## Masinile de pe tablier in tick-ul curent (Car), pentru sonde.
var _on_deck: Array[Car] = []
var last_tick_usec: int = 0
static var _deck_material: ShaderMaterial


func _ready() -> void:
	_resolve_ends()
	_calibrate()
	_build_plates()
	_build_deck_area()
	_build_visual()
	_build_towers()
	_place_plates(0.0)
	_push_shader_params()


## Capetele: copilul „Route" (primul si ultimul punct) sau exporturile.
func _resolve_ends() -> void:
	var route := get_node_or_null("Route") as Path3D
	if route == null:
		for c in get_children():
			if c is Path3D:
				route = c as Path3D
				break
	var a := near_end
	var b := far_end
	if route != null and route.curve != null and route.curve.point_count >= 2:
		a = to_local(route.to_global(route.curve.get_point_position(0)))
		b = to_local(route.to_global(route.curve.get_point_position(route.curve.point_count - 1)))
	var chord := b - a
	_length = maxf(chord.length(), 1.0)
	var fwd := chord / _length
	var right := fwd.cross(Vector3.UP)
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(fwd).normalized()
	# Cadrul coardei: -Z de-a lungul podului, +X dreapta, +Y sus.
	_frame = Transform3D(Basis(right, up, -fwd), a)


## a(m) = gain · m^exp prin cele doua puncte de calibrare, cu afundarea locala
## (dip_ratio) inclusa: o masina la mijloc coboara mijlocul cu a·(1+dip_ratio).
func _calibrate() -> void:
	_sag_exp = log(sag_bus / sag_sport) / log(MASS_BUS / MASS_SPORT)
	_sag_gain = sag_bus / pow(MASS_BUS, _sag_exp) / (1.0 + dip_ratio)


func amplitude_for(mass_factor: float) -> float:
	return _sag_gain * pow(maxf(mass_factor, 0.01), _sag_exp)


# ---------------------------------------------------------------- curba

static func _p(u: float) -> float:
	return 4.0 * u * (1.0 - u)


## Cat coboara linia mediana la fractia u (pozitiv = in jos). Oglinda lui
## deck_drop din rope_bridge.gdshader.
func _drop(u: float) -> float:
	var p := _p(u)
	var s2 := sin(TAU * u)
	var d := rest_sag * p + _sag * (p - wave_gain * s2 * s2)
	var e := smoothstep(0.0, 0.1, minf(u, 1.0 - u))
	for dip in _dips:
		var dz := (u - dip.x) * _length / dip_sigma
		d += dip.y * exp(-dz * dz) * e
	return d


## Punctul de pe linia mediana, in cadrul coardei.
func _point(u: float) -> Vector3:
	return Vector3(_sway * sin(PI * u), -_drop(u), -u * _length)


## Baza unei placi: inainte de-a lungul coardei placii, ruliul de leagan
## (deplasat la dreapta, dreapta urca) — acelasi semn ca in shader.
func _plate_basis(fwd: Vector3, u_mid: float) -> Basis:
	var right0 := fwd.cross(Vector3.UP).normalized()
	var up0 := right0.cross(fwd).normalized()
	var phi := atan(_sway * sin(PI * u_mid) / roll_arm)
	var right := right0 * cos(phi) + up0 * sin(phi)
	var up := -right0 * sin(phi) + up0 * cos(phi)
	return Basis(right, up, -fwd)


# ---------------------------------------------------------------- constructie

func _build_plates() -> void:
	_plates.clear()
	_plate_prev.clear()
	for k in plate_count:
		var body := AnimatableBody3D.new()
		body.name = "Plate%d" % k
		body.sync_to_physics = true
		body.set_meta(&"platform_velocity", Vector3.ZERO)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(deck_width, PLATE_THICKNESS, _length / float(plate_count) + plate_overlap)
		shape.shape = box
		body.add_child(shape)
		add_child(body)
		_plates.append(body)
		_plate_prev.append(Vector3.ZERO)


## Zona in care cautam masinile: un paralelipiped pe coarda, destul de larg
## si de inalt ca sa cuprinda tablierul in orice stare (±sway_max, ~2 m jos).
func _build_deck_area() -> void:
	_deck_area = Area3D.new()
	_deck_area.name = "Deck"
	_deck_area.monitoring = true
	_deck_area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(deck_width + 2.0 * sway_max + 2.0, 8.0, _length)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, -_length * 0.5)
	_deck_area.add_child(shape)
	add_child(_deck_area)
	_deck_area.transform = _frame


static func deck_material() -> ShaderMaterial:
	if _deck_material == null:
		_deck_material = ShaderMaterial.new()
		_deck_material.shader = load(SHADER_PATH)
		# ACEEASI textura ca materialul lumii: niciun asset nou.
		_deck_material.set_shader_parameter(&"atlas", Palette.world_material().albedo_texture)
	return _deck_material


## Un singur mesh in cadrul coardei: scanduri, doua cabluri portante sub
## margini, doua balustrade la 1 m, legaturi verticale intre ele.
func _build_visual() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := deck_width * 0.5
	var pitch := PLANK_WIDTH + PLANK_GAP
	var n_planks := int(floor(_length / pitch))
	var start := (_length - n_planks * pitch) * 0.5
	for k in n_planks:
		var z := -(start + (float(k) + 0.5) * pitch)
		# Variatie de valoare intre scanduri (doar intuneca: vertex color).
		var shade := 0.82 + 0.18 * fmod(float(k) * 0.618, 1.0)
		_box(st, Vector3(0.0, -PLANK_THICKNESS * 0.5, z),
			Vector3(deck_width, PLANK_THICKNESS, PLANK_WIDTH), WOOD_SLOT, shade)
	var seg := 1.25
	var n_seg := int(ceil(_length / seg))
	seg = _length / float(n_seg)
	for side: float in [-1.0, 1.0]:
		for k in n_seg:
			var z := -(float(k) + 0.5) * seg
			# cablul portant, sub marginea scandurilor
			_box(st, Vector3(side * (hw - 0.2), -PLANK_THICKNESS - 0.1, z),
				Vector3(0.2, 0.2, seg + 0.02), ROPE_SLOT, 0.9)
			# balustrada
			_box(st, Vector3(side * (hw + 0.05), RAIL_HEIGHT, z),
				Vector3(0.12, 0.12, seg + 0.02), ROPE_SLOT, 1.0)
		var n_ties := int(floor(_length / TIE_STEP))
		for k in range(1, n_ties):
			var z := -float(k) * TIE_STEP
			_box(st, Vector3(side * (hw + 0.02), RAIL_HEIGHT * 0.5, z),
				Vector3(0.05, RAIL_HEIGHT, 0.05), ROPE_SLOT, 0.95)
		# ciotul care duce balustrada in turn, la fiecare capat (u = 0 si 1:
		# deformare zero, deci sta lipit de piatra)
		for z in [0.0, -_length]:
			_box(st, Vector3(side * (hw + 0.6), RAIL_HEIGHT, z),
				Vector3(1.1, 0.12, 0.12), ROPE_SLOT, 1.0)
	_visual = MeshInstance3D.new()
	_visual.name = "DeckVisual"
	_visual.mesh = st.commit()
	_visual.material_override = deck_material()
	# Deformarea muta vertecsii cu pana la ~2.5 m: AABB-ul static ar culla podul
	# cand doar mijlocul lui e in cadru.
	var aabb: AABB = _visual.mesh.get_aabb()
	_visual.custom_aabb = aabb.grow(3.0)
	add_child(_visual)
	_visual.transform = _frame
	_visual.set_instance_shader_parameter(&"deck_length", _length)
	_visual.set_instance_shader_parameter(&"rest_sag", rest_sag)
	_visual.set_instance_shader_parameter(&"wave_gain", wave_gain)
	_visual.set_instance_shader_parameter(&"roll_arm", roll_arm)
	_visual.set_instance_shader_parameter(&"dip_sigma", dip_sigma)


## Doua turnuri de piatra la fiecare capat, langa tablier (nu pe el): corp
## static fiecare, materialul lumii.
func _build_towers() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := deck_width * 0.5
	var towers := Node3D.new()
	towers.name = "Towers"
	add_child(towers)
	towers.transform = _frame
	for z in [TOWER_SIZE.z * 0.5, -_length - TOWER_SIZE.z * 0.5]:
		for side: float in [-1.0, 1.0]:
			var at := Vector3(side * (hw + 0.6 + TOWER_SIZE.x * 0.5),
				TOWER_SIZE.y * 0.5 - TOWER_SINK, z)
			_box(st, at, TOWER_SIZE, STONE_SLOT, 1.0)
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = TOWER_SIZE
			shape.shape = box
			body.add_child(shape)
			towers.add_child(body)
			body.position = at
	var mi := MeshInstance3D.new()
	mi.name = "TowerMesh"
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	towers.add_child(mi)


## Cutie axata, 12 triunghiuri, UV pe centrul slotului, vertex color = AO.
static func _box(st: SurfaceTool, center: Vector3, size: Vector3, slot: int,
		shade: float) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var col := Color(shade, shade, shade)
	var faces := [
		[Vector3.UP, Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(-1, 1, -1)],
		[Vector3.DOWN, Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1)],
		[Vector3.RIGHT, Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1)],
		[Vector3.LEFT, Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1)],
		[Vector3.BACK, Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3.FORWARD, Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
	]
	for f: Array in faces:
		var normal: Vector3 = f[0]
		var pts: Array[Vector3] = []
		for k in range(1, 5):
			pts.append(center + (f[k] as Vector3) * h)
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.set_normal(normal)
				st.set_uv(uv)
				st.set_color(col)
				st.add_vertex(pts[k])


# ---------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _plates.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	_gather_loads()
	_integrate(delta)
	_place_plates(delta)
	_push_shader_params()
	last_tick_usec = Time.get_ticks_usec() - t0


## Masinile de pe tablier si incarcarile lor: tinta sagetii, tinta balansului,
## afundarile locale.
var _sag_target: float = 0.0
var _sway_target: float = 0.0

func _gather_loads() -> void:
	_on_deck.clear()
	_dips.clear()
	_sag_target = 0.0
	var moment := 0.0
	var load := 0.0
	var inv := _frame.affine_inverse()
	for b in _deck_area.get_overlapping_bodies():
		var car := b as Car
		if car == null or not car.is_on_floor():
			continue
		var local := inv * to_local(car.global_position)
		var u := -local.z / _length
		if u < 0.0 or u > 1.0 or absf(local.x) > deck_width * 0.5 + 1.0:
			continue
		if absf(local.y + _drop(u)) > 1.5:
			continue
		_on_deck.append(car)
		var a := amplitude_for(car.mass_factor)
		var p := _p(u)
		_sag_target += a * p
		moment += car.mass_factor * local.x * p
		load += car.mass_factor * p
		_dips.append(Vector2(u, a * dip_ratio))
	_sway_target = sway_gain * moment / (deck_mass + load)
	if _dips.size() > 4:
		_dips.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y > b.y)
		_dips.resize(4)


func _integrate(delta: float) -> void:
	var ws := TAU * sag_freq
	var acc := ws * ws * (_sag_target - _sag) - 2.0 * sag_damping * ws * _sag_vel
	_sag_vel += acc * delta
	_sag += _sag_vel * delta
	var wl := TAU * sway_freq
	var acc_l := wl * wl * (_sway_target - _sway) - 2.0 * sway_damping * wl * _sway_vel
	var excess := absf(_sway) - sway_max
	if excess > 0.0:
		acc_l -= wl * wl * 8.0 * excess * signf(_sway)
	_sway_vel += acc_l * delta
	_sway += _sway_vel * delta


## O SINGURA scriere de transform per placa pe tick; viteza placii din
## deplasarea centrului ei (delta 0 = asezarea initiala, viteza zero).
func _place_plates(delta: float) -> void:
	var n := plate_count
	var half_t := Vector3.UP * (PLATE_THICKNESS * 0.5)
	for k in n:
		var u0 := float(k) / float(n)
		var u1 := float(k + 1) / float(n)
		var p0 := _point(u0)
		var p1 := _point(u1)
		var fwd := (p1 - p0).normalized()
		var basis := _plate_basis(fwd, (u0 + u1) * 0.5)
		var center := (p0 + p1) * 0.5 - basis * half_t
		var xf := global_transform * _frame * Transform3D(basis, center)
		var body := _plates[k]
		var vel := Vector3.ZERO
		if delta > 0.0:
			vel = (xf.origin - _plate_prev[k]) / delta
		_plate_prev[k] = xf.origin
		body.global_transform = xf
		body.set_meta(&"platform_velocity", vel)


func _push_shader_params() -> void:
	if _visual == null:
		return
	_visual.set_instance_shader_parameter(&"sag", _sag)
	_visual.set_instance_shader_parameter(&"sway", _sway)
	var du := Vector4(-1.0, -1.0, -1.0, -1.0)
	var da := Vector4.ZERO
	for i in mini(_dips.size(), 4):
		du[i] = _dips[i].x
		da[i] = _dips[i].y
	_visual.set_instance_shader_parameter(&"dip_u", du)
	_visual.set_instance_shader_parameter(&"dip_a", da)


# ---------------------------------------------------------------- pentru sonde

## Amplitudinea modului global (m) si deplasarea laterala la mijloc (m).
func sag_amplitude() -> float:
	return _sag


func sway() -> float:
	return _sway


## Cat e coborata linia mediana la fractia u FATA DE REPAUS (m).
func sag_at(u: float) -> float:
	return _drop(u) - rest_sag * _p(u)


## Coborarea totala (cu repaus) la fractia u.
func drop_at(u: float) -> float:
	return _drop(u)


func deck_length() -> float:
	return _length


func cars_on_deck() -> Array[Car]:
	return _on_deck


## Pozitia globala -> (x lateral fata de coarda, y fata de LINIA MEDIANA a
## tablierului in starea curenta, u fractia). y ≈ 0 = pe scanduri.
func deck_coords(global_pos: Vector3) -> Vector3:
	var local := _frame.affine_inverse() * to_local(global_pos)
	var u := clampf(-local.z / _length, 0.0, 1.0)
	return Vector3(local.x - _sway * sin(PI * u), local.y + _drop(u), u)


## Punctul global de pe linia mediana la fractia u (starea curenta).
func deck_point_global(u: float) -> Vector3:
	return global_transform * (_frame * _point(u))


func plates() -> Array[AnimatableBody3D]:
	return _plates
