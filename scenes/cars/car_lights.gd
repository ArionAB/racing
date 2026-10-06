class_name CarLights
extends Node3D
## Stopuri si faruri. O componenta a masinii, nu a pistei: [Car] o creeaza in
## `apply_data`, copil al `_visual`, deci se inclina si se strivesc odata cu
## caroseria. Citeste doua lucruri, fara sa scrie nimic inapoi:
##   - `Car.brake_lamp` (frana de serviciu sau handbrake/drift);
##   - nivelul farurilor al pistei (`Track.theme_headlights`): 0 pe zi, 1 pe
##     noapte (Chongqing), sau ceasul de apus (Jodhpur, `DuskCycle`).
##
## LAMPILE vin din GLB: nodurile `*_Lamp_Tail` / `*_Lamp_Head` (contractul din
## tools/blender/toy_driver_parts.py, ca rotile cu "wheel" in nume). Un model
## fara ele (placeholderul din cuburi) nu primeste nimic.
##
## Ce se deseneaza, in ordinea costului (decizia din octombrie 2026, A+B+C):
##   A+B lentilele: UN material pentru toate masinile (`car_lamp.gdshader`),
##       nivelul per instanta. +0 draw call-uri (nodurile existau oricum).
##   halourile: un MultiMesh de 2-4 patrate per masina cu `lamp_halo` —
##       fara bloom, asa „straluceste" o lampa in jocul asta.
##   C   doar cu farurile aprinse: conul aditiv (`car_beam.gdshader`) si balta
##       de lumina pe asfalt (Decal emisiv, ca felinarele din `StreetLights`).
##   D   TEST, doar jucatorul, doar cu `GameState.real_headlight`: un
##       SpotLight3D adevarat, fara umbre. Il inlocuieste pe decal (altfel
##       asfaltul ar primi lumina de doua ori). E prima setare de stins daca
##       device-ul nu tine 60 fps — acelasi statut ca `Track.theme_shadows`.

const LAMP_SHADER: Shader = preload("res://assets/shaders/car_lamp.gdshader")
const HALO_SHADER: Shader = preload("res://assets/shaders/lamp_halo.gdshader")
const BEAM_SHADER: Shader = preload("res://assets/shaders/car_beam.gdshader")

const TAIL_BASE := Color(0.42, 0.05, 0.04)
const TAIL_GLOW := Color(1.0, 0.1, 0.05)
const HEAD_BASE := Color(0.85, 0.84, 0.78)
const HEAD_GLOW := Color(1.0, 0.9, 0.7)

## Snapshot: stopurile aprinse ca la franare, cu masina inghetata pe grila
## (acolo `_physics_process` scrie `brake_lamp = false` la fiecare tick).
static var force_brake: bool = false

@export_group("Stopuri")
## Cat ard stopurile cu farurile aprinse (lumini de pozitie); 1 = franare.
@export var tail_running: float = 0.3
## Viteza de aprindere / stingere (1/s). Becul se aprinde aproape instant si
## se stinge putin mai moale — o atingere scurta de frana tot se vede.
@export var brake_attack: float = 25.0
@export var brake_release: float = 8.0

@export_group("Fascicul (C)")
@export var beam_length_m: float = 10.0
@export var beam_end_radius_m: float = 1.7
## Cat coboara fasciculul spre drum (grade sub orizontala masinii).
@export var beam_drop_deg: float = 6.0
@export var pool_size: Vector3 = Vector3(5.5, 4.0, 13.0)
@export var pool_energy: float = 1.3
@export var pool_fade_begin_m: float = 35.0
@export var pool_fade_len_m: float = 15.0

@export_group("Far real (D)")
@export var spot_range_m: float = 35.0
@export var spot_angle_deg: float = 32.0
## Mare fiindca lumina reala INMULTESTE albedo-ul si cade cu patratul
## distantei: pe asfaltul de Chongqing (sol intunecat cu 70%), masurat pe
## captura de joc, luminanta medie in fata masinii: 57 la 16, 94 la 80, fata
## de 71 cu balta falsa si 28 pe asfaltul de alaturi.
@export var spot_energy: float = 80.0
## Din far (~0,6 m) inclinat cu 7 grade, jumatate din con lumina aerul.
@export var spot_drop_deg: float = 14.0

static var _lamp_mat: ShaderMaterial
static var _halo_mat: ShaderMaterial
static var _beam_mat: ShaderMaterial
static var _pool_tex: ImageTexture
static var _halo_quad: QuadMesh

var _car: Car
var _tails: Array[MeshInstance3D] = []
var _heads: Array[MeshInstance3D] = []
## Centrele lampilor, cate unul pe fiecare parte, in spatiul `_visual`.
var _tail_pts := PackedVector3Array()
var _head_pts := PackedVector3Array()
## Cota celui mai din fata punct al farurilor (z minim: botul e spre -Z).
var _nose_z: float = 0.0
var _halos: MultiMeshInstance3D
var _beam: MeshInstance3D
var _pool: Decal
var _spot: SpotLight3D
var _brake: float = 0.0
var _last_tail: float = -1.0
var _last_head: float = -1.0
var _dusk: DuskCycle


func setup(car: Car, model_root: Node3D) -> void:
	_car = car
	for node in _walk(model_root):
		if not node is MeshInstance3D:
			continue
		var n := String(node.name).to_lower()
		if "lamp_tail" in n:
			_tails.append(node)
		elif "lamp_head" in n:
			_heads.append(node)
	for mi in _tails:
		_tail_pts.append_array(_side_centers(mi))
		_init_lens(mi, TAIL_BASE, TAIL_GLOW)
	for mi in _heads:
		var pts := _side_centers(mi)
		_head_pts.append_array(pts)
		for p in pts:
			_nose_z = minf(_nose_z, p.z)
		_init_lens(mi, HEAD_BASE, HEAD_GLOW)
	if not _tail_pts.is_empty() or not _head_pts.is_empty():
		_build_halos()


func _process(delta: float) -> void:
	if _car == null or (_tails.is_empty() and _heads.is_empty()):
		return
	var head := _headlight_level()
	var want := 1.0 if (_car.brake_lamp or force_brake) else 0.0
	var rate := brake_attack if want > _brake else brake_release
	_brake = move_toward(_brake, want, rate * delta)
	var tail := maxf(_brake, tail_running * head)
	if absf(tail - _last_tail) > 0.005 or absf(head - _last_head) > 0.005:
		_last_tail = tail
		_last_head = head
		for mi in _tails:
			mi.set_instance_shader_parameter(&"lamp_level", tail)
		for mi in _heads:
			mi.set_instance_shader_parameter(&"lamp_level", head)
		_update_halos(tail, head)
		_update_beam(head)
	_update_spot(head)


## 0..1. Nivelul farurilor cerut de pista: tema fixa, sau ceasul de apus.
func _headlight_level() -> float:
	var t := _car.track
	if t == null:
		return 0.0
	if t.theme_headlights >= 0.0:
		return t.theme_headlights
	# Negativ = urmeaza DuskCycle. Cautat lenes: snapshot-ul il adauga
	# dupa ce masina exista deja.
	if _dusk == null:
		_dusk = get_tree().get_first_node_in_group(&"dusk_cycle") as DuskCycle
		if _dusk == null:
			return 0.0
	# `lamps_value` merge 0.15 (apus) -> 0.6 -> 1.0 (noapte): farurile se
	# aprind pe la mijlocul cursei, odata cu felinarele, nu din grila.
	return smoothstep(0.35, 0.85, _dusk.lamps_value)


func _init_lens(mi: MeshInstance3D, base: Color, glow: Color) -> void:
	mi.material_override = _lamp_material()
	mi.set_instance_shader_parameter(&"base_color", base)
	mi.set_instance_shader_parameter(&"glow_color", glow)
	mi.set_instance_shader_parameter(&"lamp_level", 0.0)
	# Lentila e mica si luminoasa: o umbra aruncata de ea n-are ce adauga.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Centrul fiecarei lampi dintr-un nod care le poarta pe amandoua (stanga si
## dreapta in acelasi mesh): varfurile se impart dupa semnul lui x, iar o
## lampa unica pe centru (farul tuk-tuk-ului) ramane un singur punct.
func _side_centers(mi: MeshInstance3D) -> PackedVector3Array:
	var xf := _to_visual(mi)
	var faces := mi.mesh.get_faces()
	var out := PackedVector3Array()
	if faces.is_empty():
		return out
	var lo := [Vector3.INF, Vector3.INF]
	var hi := [-Vector3.INF, -Vector3.INF]
	var spread := 0.0
	for v in faces:
		spread = maxf(spread, absf((xf * v).x))
	for v in faces:
		var p: Vector3 = xf * v
		var k := 0 if (spread < 0.2 or p.x < 0.0) else 1
		lo[k] = (lo[k] as Vector3).min(p)
		hi[k] = (hi[k] as Vector3).max(p)
	for k in 2:
		if (lo[k] as Vector3).x != INF:
			out.append(((lo[k] as Vector3) + (hi[k] as Vector3)) * 0.5)
	return out


## Transformarea nodului fata de parintele acestei componente (`_visual`),
## compusa de mana: `apply_data` poate rula inainte ca masina sa fie in arbore.
func _to_visual(node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	var stop := get_parent()
	while n != null and n != stop:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf


func _build_halos() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _quad()
	# Stopurile INTAI: pe zi se deseneaza doar ele (visible_instance_count).
	var pts := _tail_pts + _head_pts
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pts[i]))
		var is_tail := i < _tail_pts.size()
		# miez, halou, alungire, palpaire — vezi antetul lamp_halo.gdshader
		mm.set_instance_custom_data(i, Color(0.07, 0.55, 1.0, 0.0) if is_tail
			else Color(0.09, 0.85, 1.0, 0.0))
		mm.set_instance_color(i, Color(TAIL_GLOW, 0.0) if is_tail
			else Color(HEAD_GLOW, 0.0))
	mm.visible_instance_count = 0
	_halos = MultiMeshInstance3D.new()
	_halos.name = "Halouri"
	_halos.multimesh = mm
	_halos.material_override = _halo_material()
	_halos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halos)


func _update_halos(tail: float, head: float) -> void:
	if _halos == null:
		return
	var mm := _halos.multimesh
	var nt := _tail_pts.size()
	for i in mm.instance_count:
		var c := mm.get_instance_color(i)
		c.a = tail if i < nt else head
		mm.set_instance_color(i, c)
	if head > 0.01:
		mm.visible_instance_count = mm.instance_count
	elif tail > 0.01:
		mm.visible_instance_count = nt
	else:
		mm.visible_instance_count = 0


func _update_beam(head: float) -> void:
	var on := head > 0.01 and not _head_pts.is_empty()
	if on and _beam == null:
		_build_beam()
	if _beam != null:
		_beam.visible = on
		_beam.set_instance_shader_parameter(&"beam_level", head)
		_pool.emission_energy = pool_energy * head
		_pool.visible = on and not _spot_active()


func _build_beam() -> void:
	var drop := deg_to_rad(beam_drop_deg)
	var dir := Vector3(0.0, -sin(drop), -cos(drop))
	var side := Vector3.RIGHT
	var up := dir.cross(side).normalized() * -1.0
	var seg := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in _head_pts:
		var tip := p + dir * beam_length_m
		for s in seg:
			var a0 := TAU * float(s) / float(seg)
			var a1 := TAU * float(s + 1) / float(seg)
			var r0 := side * cos(a0) + up * sin(a0)
			var r1 := side * cos(a1) + up * sin(a1)
			var near0 := p + r0 * 0.12
			var near1 := p + r1 * 0.12
			var far0 := tip + r0 * beam_end_radius_m
			var far1 := tip + r1 * beam_end_radius_m
			for v in [[near0, r0, 0.0], [far0, r0, 1.0], [far1, r1, 1.0],
					[near0, r0, 0.0], [far1, r1, 1.0], [near1, r1, 0.0]]:
				st.set_normal(v[1])
				st.set_uv(Vector2(0.0, v[2]))
				st.add_vertex(v[0])
	_beam = MeshInstance3D.new()
	_beam.name = "Fascicul"
	_beam.mesh = st.commit()
	_beam.material_override = _beam_material()
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	# Balta de lumina: incepe chiar in fata botului (altfel decalul ar aprinde
	# si capota masinii proprii) si se proiecteaza in jos (-Y local).
	_pool = Decal.new()
	_pool.name = "BaltaDeLumina"
	_pool.size = pool_size
	_pool.position = Vector3(0.0, 0.3, _nose_z - 0.3 - pool_size.z * 0.5)
	_pool.texture_emission = _pool_texture()
	_pool.modulate = HEAD_GLOW
	_pool.normal_fade = 0.3
	_pool.upper_fade = 0.2
	_pool.lower_fade = 0.2
	# Decalurile au limita per mesh pe randarea mobila; doar masinile din jurul
	# camerei isi pastreaza balta.
	_pool.distance_fade_enabled = true
	_pool.distance_fade_begin = pool_fade_begin_m
	_pool.distance_fade_length = pool_fade_len_m
	add_child(_pool)


func _spot_active() -> bool:
	return _spot != null and _spot.visible


func _update_spot(head: float) -> void:
	var want := _car.is_player and GameState.real_headlight and head > 0.01 \
		and not _head_pts.is_empty()
	if want and _spot == null:
		_spot = SpotLight3D.new()
		_spot.name = "FarReal"
		var c := Vector3.ZERO
		for p in _head_pts:
			c += p
		_spot.position = c / float(_head_pts.size())
		_spot.rotation.x = -deg_to_rad(spot_drop_deg)
		_spot.spot_range = spot_range_m
		_spot.spot_angle = spot_angle_deg
		_spot.spot_attenuation = 1.2
		_spot.light_color = HEAD_GLOW
		_spot.light_specular = 0.2
		_spot.shadow_enabled = false
		add_child(_spot)
	if _spot == null:
		return
	_spot.visible = want
	# Balta falsa si farul real nu ard deodata: asfaltul ar primi lumina de
	# doua ori. Scris pe fiecare cadru (doua atribuiri), nu doar la comutare —
	# `_update_beam` ruleaza inainte si aprinde balta cat farul nu exista.
	if _pool != null:
		_pool.visible = head > 0.01 and not want
	_spot.light_energy = spot_energy * head


static func _lamp_material() -> ShaderMaterial:
	if _lamp_mat == null:
		_lamp_mat = ShaderMaterial.new()
		_lamp_mat.shader = LAMP_SHADER
	return _lamp_mat


static func _halo_material() -> ShaderMaterial:
	if _halo_mat == null:
		_halo_mat = ShaderMaterial.new()
		_halo_mat.shader = HALO_SHADER
		# Pe zi si pe noapte la fel: aici intensitatea o da franarea, nu ceasul.
		_halo_mat.set_shader_parameter(&"halo_gain_day", 0.8)
		_halo_mat.set_shader_parameter(&"halo_gain_night", 0.8)
		_halo_mat.set_shader_parameter(&"fade_begin", 80.0)
		_halo_mat.set_shader_parameter(&"fade_end", 160.0)
	return _halo_mat


static func _beam_material() -> ShaderMaterial:
	if _beam_mat == null:
		_beam_mat = ShaderMaterial.new()
		_beam_mat.shader = BEAM_SHADER
	return _beam_mat


## Balta in forma de pana de far: ingusta si intensa langa bot, larga si
## stinsa spre capat, cu cadere CONTINUA pe toate marginile (un gradient radial
## simplu, privit din camera de urmarire, se turtea intr-un disc cu centrul
## la 9 m de bot — masurat pe prima captura). In UV-ul decalului v = 1 e
## capatul dinspre masina (+Z local).
static func _pool_texture() -> ImageTexture:
	if _pool_tex == null:
		var w := 32
		var h := 64
		var img := Image.create(w, h, false, Image.FORMAT_RGB8)
		for y in h:
			var d := 1.0 - (float(y) + 0.5) / float(h) # 0 la bot, 1 la capat
			var along := smoothstep(0.0, 0.15, d) * pow(1.0 - d, 1.4)
			var half := 0.3 + 0.7 * d
			for x in w:
				var u := absf((float(x) + 0.5) / float(w) * 2.0 - 1.0)
				var lat := pow(clampf(1.0 - u / half, 0.0, 1.0), 1.5)
				var v := along * lat
				img.set_pixel(x, y, Color(v, v, v))
		_pool_tex = ImageTexture.create_from_image(img)
	return _pool_tex


static func _quad() -> QuadMesh:
	if _halo_quad == null:
		_halo_quad = QuadMesh.new()
		_halo_quad.size = Vector2(2.0, 2.0)
	return _halo_quad


static func _walk(root: Node) -> Array[Node]:
	var out: Array[Node] = [root]
	var i := 0
	while i < out.size():
		out.append_array(out[i].get_children())
		i += 1
	return out
