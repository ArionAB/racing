class_name HerdHazard
extends Node3D
## RAUL DE GNU (Serengeti, docs/track_briefs/serengeti.md §3).
##
## Un culoar de migratie taie drumul perpendicular. Animalele curg pe el in
## PULSURI: `pulse_on` secunde de turma deasa, apoi `pulse_off` secunde de
## culoar liber, la nesfarsit. Pulsul e ce se invata; gaura e ce se prinde.
##
## DE CE NU E BOIDS SI NU E 150 DE RIGIDBODY-URI (decizia din brief):
##
## Turma e un CAMP DE CURGERE: fiecare animal are un loc fix in puls (rand,
## fisier, jitter) si e pus la `pozitia pulsului - locul lui`, cadru de cadru.
## E O(n), determinist, si pastreaza structura pulsului la infinit — cu
## viteze independente per animal, gaura s-ar fi umplut in doua tururi.
## Vizual: UN MultiMesh cu galopul facut in vertex shader (faza per instanta
## in custom data). Fizic: un BAZIN de `body_pool` corpuri AnimatableBody3D
## atasate animalelor cele mai apropiate de vreo masina; restul turmei n-are
## corp, ca nimeni nu o poate atinge oricum.
##
## CONTACTUL e regula de masa a jocului (principiul 1 din CLAUDE.md), scrisa
## explicit fiindca un corp cinematic n-are masa in solver: animalul lovit
## SE ROSTOGOLESTE mereu (corpul ii dispare 1,5 s, ca sa nu te tina prins),
## iar masina primeste un ghiont in sensul curgerii si pierde viteza inainte,
## amandoua scalate cu `animal_mass / masa masinii`. Sportul (90) e aruncat
## lateral, autobuzul (260) trece prin turma abia simtind-o. Intrarea
## frontala intr-un puls des = 5-6 lovituri = oprire (clasa „oprire" din
## sisteme.md, dar 2-3 s, nu 12 ca trenul).
##
## Nu sta pe Track: are nevoie doar de o directie de curgere, una a drumului
## si de un sol (implicit y=0; pe pista, `ground_y_at` primeste un Callable).

signal animal_hit(car: Car, mass_ratio: float)

enum State { RUN, TUMBLE }

## Masinile nu stau intr-un grup (verificat: niciun add_to_group in Car/Race),
## deci turma le gaseste ca toate hazardele: printr-o Area3D peste culoar.
const CATCH_MARGIN: float = 30.0
## Lungimea unui animal (de-a lungul curgerii) si latimea lui.
const ANIMAL_LEN: float = 1.7
const ANIMAL_WIDTH: float = 0.7
const ANIMAL_HEIGHT: float = 1.3
## Cat de repede recupereaza un animal rostogolit locul din puls (m/s peste
## viteza turmei). Fara asta ar reaparea in puls printr-un salt vizibil.
const CATCH_UP: float = 3.0
## Cat de departe de drum (pe axa curgerii) e "zona drumului" pentru
## intrebarea „e culoarul liber?": jumatate de latime de drum + un animal.
const ROAD_ZONE: float = 6.0
## Sub distanta asta de o masina un animal NU primeste corp: un corp cinematic
## care apare intr-o masina o azvarle cu sute de m/s (masurat: 282 m/s, -6 m
## sub sol). Contactul de aproape e GEOMETRIC (vezi _contacts), corpul e doar
## pentru izbitura de la distanta si pentru masinile oprite in culoar.
const NO_BODY_RADIUS: float = 3.2
## Gabaritul de contact, in spatiul masinii: jumatate de latime/lungime de
## masina + jumatate de animal.
const HIT_HALF_X: float = 1.5
const HIT_HALF_Z: float = 2.8
## Kitul de savana (PR #376). Amandoua STATICE, in poza de repaus, cu
## contractul shader-ului de galop: origine la sol, -Z inainte, ~30% din
## varfuri sub `leg_top` (0,55 m) — masurat in docs/asset_briefs/serengeti_inventory.md.
## Daca un fisier lipseste (sonda pe alt worktree, kit neimportat), turma cade
## pe placeholder-ul din cutii, ca sa nu pice sondele din cauza unui asset.
const WILDEBEEST_GLB := "res://assets/models/serengeti/animals/wildebeest.glb"
const ZEBRA_GLB := "res://assets/models/serengeti/animals/zebra.glb"

@export_group("Geometrie")
## Directia in care alearga turma (taie drumul). Orizontala, normalizata.
@export var flow_dir: Vector3 = Vector3(1, 0, 0)
## Directia drumului in dreptul traversarii.
@export var road_dir: Vector3 = Vector3(0, 0, 1)
## Cat din drum (de-a lungul lui) acopera culoarul de migratie.
@export_range(6.0, 60.0, 0.5) var corridor_m: float = 24.0
## Benzi de animale de-a lungul drumului (culoarul se imparte egal).
@export_range(1, 5) var strips: int = 3
## Fisiere de animale intr-o banda.
@export_range(1, 4) var files_per_strip: int = 2
## Decalajul dintre benzi, in secunde: frontul pulsului e OBLIC peste drum,
## deci fereastra libera e diagonala. 0 = front drept.
@export_range(0.0, 3.0, 0.1) var strip_stagger: float = 0.6

@export_group("Ritm")
@export_range(1.0, 30.0, 0.5) var pulse_on: float = 8.0
@export_range(1.0, 30.0, 0.5) var pulse_off: float = 7.0
## Viteza turmei (m/s). Gnu-ul real galopeaza cu ~13; la scara de jucarie,
## 6-7 lasa pulsul lizibil.
@export_range(2.0, 14.0, 0.1) var speed: float = 6.5
## Distanta intre randuri, de-a lungul curgerii.
@export_range(1.5, 6.0, 0.1) var spacing: float = 2.5
@export_range(0.0, 1.0, 0.05) var phase: float = 0.0

@export_group("Contact")
## Masa efectiva a unui animal, in unitatile lui Car (100 * mass_factor).
@export_range(50.0, 1000.0, 10.0) var animal_mass: float = 200.0
## Ghiontul lateral (m/s) la raport de masa 1 (scaleaza cu patratul raportului:
## autobuzul abia il simte, sportul zboara).
@export_range(0.0, 15.0, 0.5) var kick_speed: float = 4.0
## Fractia din viteza inainte pierduta la o lovitura, la raport de masa 1.
@export_range(0.0, 1.0, 0.05) var forward_loss: float = 0.25
## Doua lovituri pe aceeasi masina nu vin mai des de atat (s).
@export_range(0.05, 1.0, 0.05) var hit_cooldown: float = 0.3
@export_range(0.5, 5.0, 0.1) var tumble_time: float = 1.5

@export_group("Bazin de corpuri")
@export_range(4, 40) var body_pool: int = 16
## Raza in jurul unei masini in care animalele primesc corp.
@export_range(4.0, 30.0, 0.5) var body_reach: float = 12.0

@export_group("Aspect")
@export_range(0.0, 1.0, 0.05) var zebra_ratio: float = 0.2

## Plafonul de valoare pe blana (vezi shader-ul): 1.0 = neatins, deci celelalte
## piste si hazardurile existente raman identice. Coboara numai capatul alb.
@export_range(0.4, 1.0, 0.01) var herd_white_cap: float = 1.0
## Cat din saturatia blanii se stinge spre gri (0 = atlasul brut).
@export_range(0.0, 1.0, 0.05) var herd_desat: float = 0.0
## Sol plat implicit; pe pista se da un Callable(Vector3) -> float.
var ground_y_at: Callable = Callable()
## Masinile urmarite (sondele le dau explicit); gol = cele din zona de prindere.
var cars: Array[Car] = []
var _catch: Area3D

var _time: float = 0.0
var _count: int = 0
var _loop_len: float = 0.0
# per animal
var _strip: PackedInt32Array
var _row_off: PackedFloat32Array     # metri in spatele capului pulsului
var _lateral: PackedFloat32Array     # pe axa drumului
var _wobble_amp: PackedFloat32Array
var _wobble_freq: PackedFloat32Array
var _wobble_ph: PackedFloat32Array
var _state: PackedInt32Array
var _lag: PackedFloat32Array         # metri ramasi in urma (dupa rostogolire)
var _tumble_left: PackedFloat32Array
var _tumble_roll: PackedFloat32Array
var _is_zebra: PackedByteArray
var _pos: PackedVector3Array         # pozitia calculata pe cadrul curent
# bazin
var _bodies: Array[AnimatableBody3D] = []
var _body_of: Dictionary = {}   # animal -> index corp
var _animal_of: PackedInt32Array # corp -> animal sau -1
var _pending: PackedInt32Array  # corp -> animal de plasat cadrul urmator
var _cooldown: Dictionary = {}  # car -> secunde
## DOUA MultiMesh-uri, un singur material: gnu-ul si zebra sunt mesh-uri
## diferite (un MultiMesh are UN mesh), deci fiecare specie isi are lotul ei,
## iar `_slot` spune ce instanta din lotul ei e animalul `i`. Ales in locul
## instantelor alternate fiindca nu cere niciun mesh combinat si costa exact
## un desen in plus (2 in loc de 1) la acelasi material.
var _mmi: MultiMeshInstance3D
var _mmi_zebra: MultiMeshInstance3D
var _slot: PackedInt32Array
var _rng := RandomNumberGenerator.new()
## Statistici pentru sonde.
var hits: int = 0
var tumbles: int = 0
var last_tick_usec: int = 0


func _ready() -> void:
	flow_dir.y = 0.0
	flow_dir = flow_dir.normalized()
	road_dir.y = 0.0
	road_dir = road_dir.normalized()
	_rng.seed = 1977
	_build_flow()
	_build_visual()
	_build_pool()
	_build_catch()
	_time = phase * period()


## Zona din care se citesc masinile: culoarul plus o margine, pe toata bucla.
func _build_catch() -> void:
	_catch = Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(_loop_len + CATCH_MARGIN, 12.0, corridor_m + CATCH_MARGIN * 2.0)
	shape.shape = box
	shape.position = Vector3.UP * 4.0
	_catch.add_child(shape)
	_catch.transform = Transform3D(Basis.looking_at(-flow_dir, Vector3.UP), Vector3.ZERO)
	add_child(_catch)


func period() -> float:
	return pulse_on + pulse_off


## Cate animale are turma (dedus din ritm si geometrie).
func count() -> int:
	return _count


func _build_flow() -> void:
	_loop_len = period() * speed
	var rows := int(floor(pulse_on * speed / spacing))
	_count = rows * files_per_strip * strips
	_strip.resize(_count)
	_row_off.resize(_count)
	_lateral.resize(_count)
	_wobble_amp.resize(_count)
	_wobble_freq.resize(_count)
	_wobble_ph.resize(_count)
	_state.resize(_count)
	_lag.resize(_count)
	_tumble_left.resize(_count)
	_tumble_roll.resize(_count)
	_is_zebra.resize(_count)
	_pos.resize(_count)
	var strip_w := corridor_m / float(strips)
	var file_w := strip_w / float(files_per_strip)
	var i := 0
	for s in strips:
		var strip_center := (float(s) - float(strips - 1) * 0.5) * strip_w
		for f in files_per_strip:
			var file_center := strip_center \
				+ (float(f) - float(files_per_strip - 1) * 0.5) * file_w
			for r in rows:
				_strip[i] = s
				# Randurile alterneaza intre fisiere (sah), ca sa nu para grila.
				var stagger := 0.5 * spacing if (f % 2 == 1) else 0.0
				_row_off[i] = float(r) * spacing + stagger \
					+ _rng.randf_range(-0.25, 0.25) * spacing
				_lateral[i] = file_center + _rng.randf_range(-0.3, 0.3) * file_w
				_wobble_amp[i] = _rng.randf_range(0.2, 0.6)
				_wobble_freq[i] = _rng.randf_range(0.4, 0.9)
				_wobble_ph[i] = _rng.randf_range(0.0, TAU)
				_state[i] = State.RUN
				_lag[i] = 0.0
				_is_zebra[i] = 1 if _rng.randf() < zebra_ratio else 0
				i += 1


## Pozitia capului pulsului unei benzi de-a lungul curgerii, in [-L/2, L/2).
func _head_along(strip: int, at_time: float) -> float:
	var t := at_time - float(strip) * strip_stagger
	return wrapf(t * speed, -_loop_len * 0.5, _loop_len * 0.5)


func _along_of(i: int, at_time: float) -> float:
	var a := _head_along(_strip[i], at_time) - _row_off[i] - _lag[i]
	return wrapf(a, -_loop_len * 0.5, _loop_len * 0.5)


## Zona drumului (|along| < ROAD_ZONE) e libera pe banda `strip` la `at_time`?
func strip_free_at(strip: int, at_time: float) -> bool:
	var head := _head_along(strip, at_time)
	var block := pulse_on * speed + ANIMAL_LEN
	# Blocul ocupa [head - block, head] pe cerc; testam cele doua capete ale
	# zonei drumului fata de el.
	for a: float in [-ROAD_ZONE, ROAD_ZONE, 0.0]:
		var behind := wrapf(head - a, 0.0, _loop_len)
		if behind <= block:
			return false
	return true


## Tot culoarul e liber acum (fereastra pe care o pandeste jucatorul)?
func window_open_now() -> bool:
	for s in strips:
		if not strip_free_at(s, _time):
			return false
	return true


## Cate secunde pana se deschide urmatoarea fereastra (0 = e deschisa).
func seconds_to_window() -> float:
	var step := 0.1
	var t := 0.0
	while t < period() + 1.0:
		var all_free := true
		for s in strips:
			if not strip_free_at(s, _time + t):
				all_free = false
				break
		if all_free:
			return t
		t += step
	return period()


## Cate secunde pana ce culoarul e plin pe toate benzile (pentru sonde).
func seconds_to_dense() -> float:
	var t := 0.0
	while t < period() + 1.0:
		var all_busy := true
		for s in strips:
			if strip_free_at(s, _time + t):
				all_busy = false
				break
		if all_busy:
			return t
		t += 0.1
	return period()


func _ground(p: Vector3) -> float:
	if ground_y_at.is_valid():
		return float(ground_y_at.call(p))
	return global_position.y


func _build_visual() -> void:
	var gnu_mesh := _animal_mesh_from(WILDEBEEST_GLB)
	var zebra_mesh := _animal_mesh_from(ZEBRA_GLB)
	var from_kit := gnu_mesh != null
	if gnu_mesh == null:
		push_warning("HerdHazard: %s nu se incarca; turma ramane pe cutii" % WILDEBEEST_GLB)
		gnu_mesh = _animal_mesh()
	if zebra_mesh == null:
		zebra_mesh = gnu_mesh
	var mat := _herd_material(from_kit)
	_slot.resize(_count)
	var n_zebra := 0
	for i in _count:
		if _is_zebra[i] == 1:
			_slot[i] = n_zebra
			n_zebra += 1
	var n_gnu := 0
	for i in _count:
		if _is_zebra[i] == 0:
			_slot[i] = n_gnu
			n_gnu += 1
	_mmi = _make_lot("Herd", gnu_mesh, n_gnu, mat)
	_mmi_zebra = _make_lot("HerdZebra", zebra_mesh, n_zebra, mat)
	for i in _count:
		_set_custom(i, Color(_rng.randf(), 0.0, float(_is_zebra[i]), 0.0))


func _make_lot(lot_name: String, mesh: Mesh, n: int, mat: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.name = lot_name
	mmi.multimesh = mm
	# Transformurile instantelor sunt in spatiul LUMII (`_animal_transform`
	# pleaca din `_pos`, care e global, ca si corpurile din bazin). Un
	# MultiMesh le interpreteaza fata de nodul lui, deci fara `top_level`
	# turma se desena deplasata cu pozitia nodului: pe Track14 (nodul la
	# (70, 0, 165)) animalele vizibile stateau la 130 m in campie, in timp ce
	# corpurile loveau pe drum. Invizibil pe ProbeSerengeti (nodul la origine)
	# si in snapshot (care nu arata turma fara --herd-at).
	mmi.top_level = true
	mmi.transform = Transform3D.IDENTITY
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)
	return mmi


func _lot_of(i: int) -> MultiMesh:
	return (_mmi_zebra if _is_zebra[i] == 1 else _mmi).multimesh


func _set_custom(i: int, c: Color) -> void:
	_lot_of(i).set_instance_custom_data(_slot[i], c)


## Mesh-ul unui animal din GLB, cu transformul nodului COPT in varfuri: un
## MultiMesh nu stie de transformul nodului din care a venit mesh-ul, deci un
## GLB cu rotatie pe nod ar fi iesit culcat. Intoarce null daca fisierul
## lipseste sau nu are niciun MeshInstance3D.
static func _animal_mesh_from(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var root := ps.instantiate()
	var found: MeshInstance3D = null
	var stack: Array[Node] = [root]
	while not stack.is_empty() and found == null:
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			found = n as MeshInstance3D
	var mesh: Mesh = null
	if found != null and found.mesh != null:
		var xf := Transform3D.IDENTITY
		var cur: Node = found
		while cur != null and cur != root:
			if cur is Node3D:
				xf = (cur as Node3D).transform * xf
			cur = cur.get_parent()
		if xf.is_equal_approx(Transform3D.IDENTITY):
			mesh = found.mesh
		else:
			var out: ArrayMesh = null
			for sidx in found.mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.append_from(found.mesh, sidx, xf)
				out = st.commit(out)
			mesh = out
	root.free()
	return mesh


## Placeholder de gnu din cutii, cu fata spre -Z (inainte in Godot). Kitul
## real (wildebeest.glb) trebuie sa respecte aceleasi conventii: picioarele
## sub y = 0.55 (shader-ul le leagana), origine la sol, -Z inainte.
func _animal_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color(0.22, 0.18, 0.15)
	var mane := Color(0.12, 0.10, 0.09)
	# corp
	_add_box(st, Vector3(0.0, 0.95, 0.0), Vector3(ANIMAL_WIDTH, 0.6, 1.5), dark)
	# gat + cap, aplecat
	_add_box(st, Vector3(0.0, 0.95, -0.95), Vector3(0.4, 0.45, 0.5), dark)
	_add_box(st, Vector3(0.0, 0.75, -1.25), Vector3(0.32, 0.4, 0.35), mane)
	# coarne
	_add_box(st, Vector3(0.28, 1.05, -1.2), Vector3(0.12, 0.25, 0.1), mane)
	_add_box(st, Vector3(-0.28, 1.05, -1.2), Vector3(0.12, 0.25, 0.1), mane)
	# picioare (sub 0.55 -> leganate de shader)
	for x: float in [-0.22, 0.22]:
		for z: float in [-0.55, 0.55]:
			_add_box(st, Vector3(x, 0.33, z), Vector3(0.16, 0.66, 0.18), dark)
	st.generate_normals()
	return st.commit()


func _add_box(st: SurfaceTool, c: Vector3, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
		[Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1)],
		[Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1)],
		[Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(-1, 1, -1)],
		[Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1)],
	]
	for f: Array in faces:
		var p: Array[Vector3] = []
		for v: Vector3 in f:
			p.append(c + v * h)
		st.set_color(col)
		st.add_vertex(p[0]); st.add_vertex(p[1]); st.add_vertex(p[2])
		st.add_vertex(p[0]); st.add_vertex(p[2]); st.add_vertex(p[3])


## Galopul in vertex shader + culoarea din ATLASUL de paleta (nu material alb
## si nu vertex color pur): mesh-urile din kit au UV-urile colapsate pe centrul
## slotului si AO-ul in vertex colors, exact contractul `Palette.world_material`.
## Stratul de detaliu triplanar lipseste deliberat: pe un animal de 2 m, la 15+
## m, mip-ul ales e oricum sub un texel — si masca de detaliu e ~0 pe sloturile
## de blana. Un singur material pentru ambele loturi (gnu + zebra).
## `from_kit` = false pastreaza placeholder-ul din cutii (fara UV-uri: ar citi
## slotul 0 din atlas) pe culoarea de vertex.
func _herd_material(from_kit: bool) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back;
// Galopul e in vertex shader: picioarele (y < leg_top) se leagana in
// antifaza fata/spate, corpul salta. Faza per instanta in INSTANCE_CUSTOM.r,
// rostogolit (fara animatie) in .g, zebra in .b (nefolosit de shader de cand
// zebra e propriul ei mesh; ramane pentru sonde).
uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap;
uniform float use_atlas = 1.0;
uniform float gallop_hz = 2.4;
uniform float leg_top = 0.55;
uniform float swing = 0.32;
uniform float bob = 0.09;
// Desaturarea blanii spre luminanta. Slotul de atlas al gnu-ului e un brun
// portocaliu (S 0.78 masurat pe cadrul de joc), in timp ce gnu-ul referintei
// e gri-brun (S 0.49) — diferenta e de SATURATIE, nu de nuanta (H 24 fata de
// 29) si nici de valoare (V 0.38 fata de 0.34). 0 = neatins.
uniform float desat = 0.0;
// PLAFONUL DE ALB, si e o axa diferita de `desat`. Zebra din kit e alb pur:
// masurat pe cadrul de joc (--frac=0.06 --gamecam --herd-at=4), pixelii
// aproape-albi (V > 0.80, S < 0.22) sunt 2.66 % din caseta turmei si au media
// (254,250,229) — taiati in alb. In referinta aceiasi pixeli sunt 0.37 % si au
// media (231,212,199), adica un alb-crem cald. `desat` nu putea repara asta
// niciodata: desaturarea albului da tot alb, ea lucreaza pe saturatie iar aici
// diferenta e de VALOARE. Plafonul coboara doar capatul de sus si lasa
// registrul brun al gnu-ului (deja la paritate) neatins. 1.0 = neatins.
uniform float white_cap = 1.0;
uniform vec3 white_tint = vec3(1.0, 0.94, 0.88);
void vertex() {
	float ph = INSTANCE_CUSTOM.r * 6.2831853;
	float still = INSTANCE_CUSTOM.g;
	float leg = clamp((leg_top - VERTEX.y) / leg_top, 0.0, 1.0);
	float s = sin(TIME * gallop_hz * 6.2831853 + ph) * (1.0 - still);
	float side = VERTEX.z < 0.0 ? 1.0 : -1.0;
	VERTEX.z += leg * s * swing * side;
	VERTEX.y += abs(s) * bob * (1.0 - leg);
}
void fragment() {
	vec3 atlas = texture(albedo_atlas, UV).rgb;
	vec3 base = mix(COLOR.rgb, atlas * COLOR.rgb, use_atlas);
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(base, vec3(lum), desat);
	// Coborare DURA a capatului de sus, nu o interpolare: prima incercare a
	// amestecat proportional cu cat se depaseste plafonul, si formula se lupta
	// singura (cu cat plafonul e mai jos, cu atat numitorul 1 - white_cap creste
	// si factorul de amestec scade) — masurat, 0.72 -> 0.45 a taiat numarul de
	// pixeli albi la jumatate, dar pixelii ramasi erau tot (255,250,213), adica
	// tot taiati in alb. Aici tot ce depaseste plafonul e readus FIX la el si
	// primit tenta calda; tonurile medii, sub plafon, nu se ating deloc.
	float over = max(max(col.r, col.g), col.b);
	if (over > white_cap) {
		col = col * (white_cap / over) * white_tint;
	}
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("albedo_atlas", load(Palette.ATLAS_PATH))
	mat.set_shader_parameter("use_atlas", 1.0 if from_kit else 0.0)
	mat.set_shader_parameter("desat", herd_desat)
	mat.set_shader_parameter("white_cap", herd_white_cap)
	return mat


func _build_pool() -> void:
	_animal_of.resize(body_pool)
	_pending.resize(body_pool)
	for b in body_pool:
		var body := AnimatableBody3D.new()
		body.name = "HerdBody%d" % b
		body.sync_to_physics = true
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(ANIMAL_WIDTH, ANIMAL_HEIGHT * 0.8, ANIMAL_LEN)
		shape.shape = box
		shape.position = Vector3(0.0, 0.3 + ANIMAL_HEIGHT * 0.4, 0.0)
		body.add_child(shape)
		add_child(body)
		body.global_position = _parking()
		_bodies.append(body)
		_animal_of[b] = -1
		_pending[b] = -1


func _parking() -> Vector3:
	return global_position + Vector3(0.0, -60.0, 0.0)


func _physics_process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_time += delta
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	_advance_animals(delta)
	_place_visuals()
	_assign_bodies()
	_place_bodies()
	_contacts()
	last_tick_usec = Time.get_ticks_usec() - t0


func _advance_animals(delta: float) -> void:
	for i in _count:
		if _state[i] == State.TUMBLE:
			_tumble_left[i] -= delta
			_lag[i] += speed * delta # pulsul merge mai departe fara el
			if _tumble_left[i] <= 0.0:
				_state[i] = State.RUN
				_set_custom(i, Color(_wobble_ph[i] / TAU, 0.0, float(_is_zebra[i]), 0.0))
		elif _lag[i] > 0.0:
			_lag[i] = maxf(_lag[i] - CATCH_UP * delta, 0.0)
		var along := _along_of(i, _time)
		var wob := sin(_time * _wobble_freq[i] * TAU + _wobble_ph[i]) * _wobble_amp[i]
		var p := global_position + flow_dir * along + road_dir * (_lateral[i] + wob)
		p.y = _ground(p)
		_pos[i] = p


func _animal_transform(i: int) -> Transform3D:
	# -Z al modelului spre directia curgerii.
	var basis := Basis.looking_at(flow_dir, Vector3.UP)
	if _state[i] == State.TUMBLE:
		basis = basis * Basis(Vector3.FORWARD, _tumble_roll[i])
		return Transform3D(basis, _pos[i] + Vector3.UP * 0.35)
	return Transform3D(basis, _pos[i])


func _place_visuals() -> void:
	for i in _count:
		_lot_of(i).set_instance_transform(_slot[i], _animal_transform(i))


func _cars() -> Array:
	if not cars.is_empty():
		return cars
	if _catch == null:
		return []
	var found: Array = []
	for body in _catch.get_overlapping_bodies():
		if body is Car:
			found.append(body)
	return found


## Corpurile merg la animalele care ALEARGA cel mai aproape de vreo masina.
## Lipicios: un animal isi tine corpul cat ramane in raza (x1.3), ca sa nu
## sara corpurile intre animale la fiecare cadru.
func _assign_bodies() -> void:
	var list := _cars()
	if list.is_empty():
		return
	var want: Array = [] # [dist, animal]
	for i in _count:
		if _state[i] != State.RUN:
			continue
		var best := INF
		for c: Variant in list:
			var car := c as Node3D
			if car == null:
				continue
			var d := car.global_position.distance_to(_pos[i])
			if d < best:
				best = d
		if best < body_reach and best > NO_BODY_RADIUS:
			want.append([best, i])
	want.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var keep: Dictionary = {}
	for b in body_pool:
		var a := _animal_of[b]
		if a < 0:
			continue
		var still := _state[a] == State.RUN
		if still:
			var best := INF
			for c: Variant in list:
				var car := c as Node3D
				if car != null:
					best = minf(best, car.global_position.distance_to(_pos[a]))
			still = best < body_reach * 1.3 and best > NO_BODY_RADIUS
		if still:
			keep[a] = b
		else:
			_release(b)
	for entry: Array in want:
		var i: int = entry[1]
		if keep.has(i):
			continue
		var free := _free_body()
		if free < 0:
			break
		_pending[free] = i
		keep[i] = free
		_body_of[i] = free


func _free_body() -> int:
	for b in body_pool:
		if _animal_of[b] < 0 and _pending[b] < 0:
			return b
	return -1


func _release(b: int) -> void:
	var a := _animal_of[b]
	if a >= 0:
		_body_of.erase(a)
	_animal_of[b] = -1
	_pending[b] = -1
	_bodies[b].global_transform = Transform3D(Basis.IDENTITY, _parking())


## Un corp proaspat atribuit sta un cadru in parcare (unde a fost mutat la
## eliberare), abia apoi apare la animal: altfel sync_to_physics i-ar da
## viteza teleportarii si ar matura masina de langa el.
func _place_bodies() -> void:
	for b in body_pool:
		if _pending[b] >= 0:
			_animal_of[b] = _pending[b]
			_pending[b] = -1
			continue
		var a := _animal_of[b]
		if a < 0:
			continue
		_bodies[b].global_transform = _animal_transform(a)


## Contactul e geometric, in spatiul masinii: orice animal care alearga si
## intra in gabaritul (HIT_HALF_X x HIT_HALF_Z) al unei masini o loveste.
## Nu depinde de corpuri — de aceea corpurile pot lipsi tocmai langa masina.
func _contacts() -> void:
	for c: Variant in _cars():
		var car := c as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		var inv := car.global_transform.affine_inverse()
		for i in _count:
			if _state[i] != State.RUN:
				continue
			if car.global_position.distance_squared_to(_pos[i]) > 16.0:
				continue
			var local := inv * _pos[i]
			if absf(local.x) < HIT_HALF_X and absf(local.z) < HIT_HALF_Z \
					and absf(local.y) < 1.5:
				_cooldown[car] = hit_cooldown
				_hit(i, car)
				break


func _hit(a: int, car: Car) -> void:
	var ratio := clampf(animal_mass / maxf(car.mass, 1.0), 0.4, 1.6)
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var fwd_speed := car.velocity.dot(fwd)
	var loss := fwd * fwd_speed * forward_loss * minf(ratio, 1.0)
	var push := flow_dir * kick_speed * ratio * ratio + Vector3.UP * 0.3
	car.apply_sweep(push - loss)
	# Animalul cade si isi pierde corpul: nu te tine prins intre el si vecin.
	_state[a] = State.TUMBLE
	_tumble_left[a] = tumble_time
	_tumble_roll[a] = PI * 0.5 * (1.0 if _rng.randf() < 0.5 else -1.0)
	_set_custom(a, Color(_wobble_ph[a] / TAU, 1.0, float(_is_zebra[a]), 0.0))
	if _body_of.has(a):
		_release(int(_body_of[a]))
	hits += 1
	tumbles += 1
	animal_hit.emit(car, ratio)
