@tool
class_name TrainHazard
extends Node3D
## Tren de marfa care taie soseaua la interval fix. Contactul te scoate din cursa
## pentru cateva secunde.
##
## Gimmick-ul e de TIMING, nu de reflexe: linia, barierele si clopotul spun de
## departe daca prinzi trecerea sau nu. Perioada e lunga (26 s la un tur de ~50)
## tocmai ca decizia "fortez sau ridic piciorul" sa apara o data sau de doua ori
## pe tur, nu la fiecare viraj.
##
## Ce inseamna "explodezi", mecanic: nu exista stare de distrus in joc. Trenul
## te turteste complet, iti taie comenzile cat te arunca fizic, apoi te repune.
## Corpul solid face aruncarea — aia E explozia vizuala — iar repunerea
## temporizata garanteaza ca nimeni nu ramane blocat sub tren.

## Cat dureaza un ciclu complet.
const DEFAULT_PERIOD: float = 26.0
## Avertizarea, inainte sa intre trenul in cadru.
const WARN: float = 4.5
## Cat dureaza traversarea.
const CROSS: float = 6.9
## Viteza trenului.
const SPEED: float = 26.0
## Cat de des bate clopotul in timpul avertizarii.
const BELL_INTERVAL: float = 0.6
## Cand suna cornul, masurat de la inceputul ciclului.
const HORN_AT: float = 0.4

## Un vagon: lungime, latime, inaltime.
const WAGON_LEN: float = 7.0
const WAGON_WIDTH: float = 3.0
const WAGON_HEIGHT: float = 3.4
## Cate vagoane trage locomotiva.
const WAGON_COUNT: int = 3
## Spatiul dintre vagoane.
const WAGON_GAP: float = 1.2

## Cat sta o masina imuna dupa ce a fost lovita — mai lung decat la bolovan,
## fiindca urmeaza o repunere si n-are rost sa fie lovita de doua ori.
const HIT_COOLDOWN: float = 2.0
## Cat tine masina fara comenzi, cat o arunca trenul.
const STUN_SECONDS: float = 0.9
## Cat de departe in spate te repune. Mai mult decat implicitul de 14 m: trenul
## inca trece, iar o repunere prea aproape te-ar pune inapoi sub el.
const RESPAWN_BACKOFF: float = 20.0

@export var period: float = DEFAULT_PERIOD
## Lungimea sinei de fiecare parte a soselei. Se scurteaza automat daca ar da
## peste alta bucla a pistei — vezi Track._build_train.
@export var half_rail: float = 90.0
## Latimea soselei in punctul de trecere, pentru bariere.
@export var road_half_width: float = 7.0

var _train: AnimatableBody3D
var _hit: Area3D
var _audio: AudioStreamPlayer3D
var _gate_lights: Array[MeshInstance3D] = []
var _time: float = 0.0
var _last_bell: int = -1
var _horn_done: bool = false
var _cooldown: Dictionary = {}
## Lungimea totala a garniturii, pentru pozitionare.
var _train_len: float = 0.0

## Materiale STATICE, partajate. Terasamentul si stalpii folosesc acelasi
## material de structura: sunt amandoua "beton si lemn vechi" si nimeni nu vede
## diferenta la 60 km/h, dar garda de draw call-uri o vede.
static var _struct_mat: StandardMaterial3D
static var _body_mat: StandardMaterial3D
static var _light_mat: StandardMaterial3D


func _ready() -> void:
	_train_len = float(WAGON_COUNT + 1) * (WAGON_LEN + WAGON_GAP)
	_build()


func _build() -> void:
	_build_bed()
	_build_gates()
	_build_train()
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 140.0
	add_child(_audio)


## Terasamentul: doua sine si traverse. Local, X e de-a lungul sinei si Z de-a
## lungul soselei — nodul e rotit de Track la asezare.
func _build_bed() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sleepers := int(half_rail * 2.0 / 2.4)
	for i in sleepers:
		var x := -half_rail + float(i) * 2.4
		_box(st, Vector3(x, 0.06, 0.0), Vector3(1.0, 0.12, 2.9))
	for side: float in [-1.0, 1.0]:
		_box(st, Vector3(0.0, 0.20, side * 0.75),
			Vector3(half_rail * 2.0, 0.16, 0.16))
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	# Refolosim sloturi din paleta, nu culori noi: hazardele procedurale intra in
	# raportul mesh-uri/material din garda, iar Dunele e cazul strans.
	inst.material_override = _structure_material()
	add_child(inst)


## Barierele de trecere la nivel, de o parte si de alta a soselei. Lumina lor
## clipeste in timpul avertizarii — singurul semnal pe care il vezi din masina
## inainte sa apara trenul.
func _build_gates() -> void:
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 3.2, 0.22)
		post.mesh = mesh
		post.position = Vector3(side * 3.4, 1.6, (road_half_width + 2.2) * side)
		post.material_override = _structure_material()
		add_child(post)

		var light := MeshInstance3D.new()
		var bulb := SphereMesh.new()
		bulb.radius = 0.34
		bulb.height = 0.68
		bulb.radial_segments = 8
		bulb.rings = 4
		light.mesh = bulb
		light.position = post.position + Vector3.UP * 1.8
		if _light_mat == null:
			_light_mat = StandardMaterial3D.new()
			_light_mat.albedo_color = Color(0.85, 0.15, 0.1)
			# UNSHADED: un bec trebuie sa se vada aprins si cand e in umbra.
			_light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		light.material_override = _light_mat
		add_child(light)
		_gate_lights.append(light)


## Terasament si stalpi: acelasi material.
static func _structure_material() -> StandardMaterial3D:
	if _struct_mat == null:
		_struct_mat = StandardMaterial3D.new()
		_struct_mat.albedo_color = Palette.color(Palette.WOOD_WEATHERED)
		_struct_mat.roughness = 0.9
	return _struct_mat


func _build_train() -> void:
	_train = AnimatableBody3D.new()
	_train.sync_to_physics = true
	add_child(_train)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in WAGON_COUNT + 1:
		var x := float(i) * (WAGON_LEN + WAGON_GAP)
		var h := WAGON_HEIGHT if i > 0 else WAGON_HEIGHT + 0.7 # locomotiva
		_box(st, Vector3(x, h * 0.5 + 0.5, 0.0),
			Vector3(WAGON_LEN, h, WAGON_WIDTH))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(WAGON_LEN, h, WAGON_WIDTH)
		shape.shape = box
		shape.position = Vector3(x, h * 0.5 + 0.5, 0.0)
		_train.add_child(shape)
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	if _body_mat == null:
		_body_mat = StandardMaterial3D.new()
		_body_mat.albedo_color = Palette.color(Palette.RUST_METAL)
		_body_mat.roughness = 0.8
	inst.material_override = _body_mat
	_train.add_child(inst)

	_hit = Area3D.new()
	var hit_shape := CollisionShape3D.new()
	var hit_box := BoxShape3D.new()
	# Cu un metru mai gras decat vagoanele: lovitura se simte cand trenul te
	# atinge, nu cand a intrat deja jumatate in tine.
	hit_box.size = Vector3(_train_len, WAGON_HEIGHT + 1.0, WAGON_WIDTH + 1.0)
	hit_shape.shape = hit_box
	hit_shape.position = Vector3(_train_len * 0.5 - WAGON_LEN * 0.5,
		WAGON_HEIGHT * 0.5 + 0.5, 0.0)
	_hit.add_child(hit_shape)
	_train.add_child(_hit)


## O cutie in SurfaceTool. Doua triunghiuri per fata, fara indexare.
func _box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var c := [
		center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z), center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z), center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z),
	]
	const FACES := [
		[4, 5, 6, 7], [1, 0, 3, 2], [0, 1, 5, 4],
		[2, 3, 7, 6], [3, 0, 4, 7], [1, 2, 6, 5],
	]
	for f: Array in FACES:
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[1]]); st.add_vertex(c[f[2]])
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[2]]); st.add_vertex(c[f[3]])


func _physics_process(delta: float) -> void:
	if _train == null:
		return
	_time = fposmod(_time + delta, period)
	var warning := _time < WARN
	var crossing := _time >= WARN and _time < WARN + CROSS

	# Luminile clipesc doar in avertizare; in rest sunt stinse, ca sa nu obisnuiesti
	# ochiul cu ele si sa nu le mai vezi cand conteaza.
	var blink := warning and fmod(_time, 0.5) < 0.25
	for light in _gate_lights:
		var m := light.material_override as StandardMaterial3D
		m.albedo_color = Color(1.0, 0.25, 0.15) if blink \
			else Color(0.28, 0.06, 0.05)

	if crossing:
		var k := (_time - WARN) / CROSS
		# Traverseaza de la un capat la altul al sinei, cu garnitura cu tot.
		var span := half_rail * 2.0 + _train_len
		_train.position.x = -half_rail - _train_len + span * k
		_train.visible = true
	else:
		# Parcat departe, cu coliziunea inactiva prin distanta. Mai simplu si mai
		# sigur decat sa comutam disabled pe cinci forme in fiecare cadru.
		_train.position.x = -half_rail - _train_len * 3.0
		_train.visible = false

	if Engine.is_editor_hint():
		return
	_tick_audio()
	_tick_cooldowns(delta)
	if crossing:
		_hit_cars()


func _tick_audio() -> void:
	if _time < WARN:
		if not _horn_done and _time >= HORN_AT:
			_horn_done = true
			_play(&"train_horn")
		var bell := int(_time / BELL_INTERVAL)
		if bell != _last_bell:
			_last_bell = bell
			_play(&"crossing_bell")
	else:
		_horn_done = _time < WARN + CROSS
		_last_bell = -1


func _play(sfx: StringName) -> void:
	var stream := AudioManager.stream(sfx)
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


func _tick_cooldowns(delta: float) -> void:
	for car: Car in _cooldown.keys():
		var left: float = float(_cooldown[car]) - delta
		if left <= 0.0:
			_cooldown.erase(car)
		else:
			_cooldown[car] = left


func _hit_cars() -> void:
	for body in _hit.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car):
			continue
		# Doar la TRECEREA propriu-zisa. Sina e dreapta, soseaua e curba, deci pe
		# o pista care se intoarce in ea insasi linia poate trece a doua oara pe
		# langa asfalt — fara bariere, fara clopot, fara nicio avertizare. Acolo
		# trenul n-are voie sa loveasca: ar fi o moarte din senin.
		if absf(to_local(car.global_position).x) > road_half_width + 10.0:
			continue
		_cooldown[car] = HIT_COOLDOWN
		# Turtit complet si oprit. Corpul solid al trenului o arunca in
		# continuare cat tine stun-ul — aia e "explozia".
		car.crush(0.0, 1.0, Vector3(1.6, 0.25, 1.4), 0.0)
		car.race_active = false
		var hit_car := car
		get_tree().create_timer(STUN_SECONDS, false).timeout.connect(
			func() -> void:
				if not is_instance_valid(hit_car):
					return
				hit_car.race_active = true
				hit_car.respawn(RESPAWN_BACKOFF))
