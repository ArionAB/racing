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

const CAR_GROUP: StringName = &"cars"
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
## Sol plat implicit; pe pista se da un Callable(Vector3) -> float.
var ground_y_at: Callable = Callable()
## Masinile urmarite; gol = grupul "cars" din arbore.
var cars: Array[Car] = []

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
var _mmi: MultiMeshInstance3D
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
	_time = phase * period()


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
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _animal_mesh()
	mm.instance_count = _count
	for i in _count:
		mm.set_instance_custom_data(i, Color(_rng.randf(), 0.0,
			1.0 if _is_zebra[i] == 1 else 0.0, 0.0))
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Herd"
	_mmi.multimesh = mm
	_mmi.material_override = _herd_material()
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_mmi)


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


func _herd_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back;
// Galopul e in vertex shader: picioarele (y < leg_top) se leagana in
// antifaza fata/spate, corpul salta. Faza per instanta in INSTANCE_CUSTOM.r,
// rostogolit (fara animatie) in .g, zebra in .b.
uniform float gallop_hz = 2.4;
uniform float leg_top = 0.55;
uniform float swing = 0.32;
uniform float bob = 0.09;
varying float zebra_k;
varying float model_z;
void vertex() {
	zebra_k = INSTANCE_CUSTOM.b;
	model_z = VERTEX.z;
	float ph = INSTANCE_CUSTOM.r * 6.2831853;
	float still = INSTANCE_CUSTOM.g;
	float leg = clamp((leg_top - VERTEX.y) / leg_top, 0.0, 1.0);
	float s = sin(TIME * gallop_hz * 6.2831853 + ph) * (1.0 - still);
	float side = VERTEX.z < 0.0 ? 1.0 : -1.0;
	VERTEX.z += leg * s * swing * side;
	VERTEX.y += abs(s) * bob * (1.0 - leg);
}
void fragment() {
	vec3 base = COLOR.rgb;
	// zebra: deschisa, cu dungi pe corp dupa pozitia pe -Z
	float stripe = step(0.5, fract(model_z * 3.0));
	vec3 zebra = mix(vec3(0.85, 0.83, 0.78), vec3(0.12, 0.11, 0.1), stripe);
	ALBEDO = mix(base, zebra, zebra_k);
	ROUGHNESS = 0.9;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
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
				_mmi.multimesh.set_instance_custom_data(i,
					Color(_wobble_ph[i] / TAU, 0.0, float(_is_zebra[i]), 0.0))
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
	var mm := _mmi.multimesh
	for i in _count:
		mm.set_instance_transform(i, _animal_transform(i))


func _cars() -> Array:
	if not cars.is_empty():
		return cars
	return get_tree().get_nodes_in_group(CAR_GROUP)


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
	_mmi.multimesh.set_instance_custom_data(a,
		Color(_wobble_ph[a] / TAU, 1.0, float(_is_zebra[a]), 0.0))
	if _body_of.has(a):
		_release(int(_body_of[a]))
	hits += 1
	tumbles += 1
	animal_hit.emit(car, ratio)
