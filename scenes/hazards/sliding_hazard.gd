@tool # vizibil si in preview-ul din editor
class_name SlidingHazard
extends AnimatableBody3D
## Obstacol mobil care traverseaza soseaua dintr-o parte in alta.
## AnimatableBody3D = corp "static" pe care il misti tu din cod, iar fizica
## ii calculeaza corect viteza pentru corpurile care il ating.
##
## Poate folosi un model 3D (ex. mingea de plaja din Blender); fara model,
## cade pe cutia galbena placeholder. Cu roll_radius > 0 modelul se
## ROSTOGOLESTE fizic corect: unghi = distanta parcursa / raza.
##
## Ce il face CINSTIT e ca te dezechilibreaza, nu ca te scoate din cursa: la
## contact primesti un ghiont care te scoate din pensa (cooldown per masina).
## Fara el, un corp cinematic care impinge un CharacterBody3D il tine lipit de
## perete zeci de cadre — masurat cu tools/probe_race.gd: o masina cu 139 de
## cadre de contact intr-o singura cursa, adica blocata acolo, nu lovita.
##
## Ce am invatat masurand, si merita scris ca sa nu se reincerce: incetinirea
## maturarii "ca sa fie mai citibil" INRAUTATESTE lucrurile. Cu perioada dubla,
## obstacolul devine un blocaj semi-static pe drum si toata lumea intra in el
## (cadre de contact per masina: ~10 la perioada originala, ~110 la dublu).
## Un obstacol rapid traverseaza si elibereaza drumul; unul lent sta in el.

## Cat de repede matura, la maximum (mijlocul cursei). Perioada se DEDUCE din
## viteza asta si din cursa reala, ca obstacolele de pe piste late sa nu iasa
## automat mai violente decat cele de pe piste inguste.
const MAX_SWEEP_SPEED_DEFAULT: float = 12.0
## Banda lasata libera langa perete. 0 = fara limitare (cursa exact cat cere
## pista). Exista pentru piste inguste, unde maturarea pana in perete ar lasa
## banda plina fara iesire.
const ESCAPE_LANE_DEFAULT: float = 0.0
## m/s dati masinii lovite, ca sa iasa din calea obstacolului.
const SWEEP_PUSH: float = 5.5

var center: Vector3
var travel: Vector3 # amplitudinea (vector lateral, jumatate de cursa)
## Lasata pe 0 = dedusa din `max_sweep_speed` si din cursa reala. Pusa explicit,
## are prioritate (util daca vrei un obstacol anume mai lent).
var period: float = 0.0
var max_sweep_speed: float = MAX_SWEEP_SPEED_DEFAULT
## Semilatimea soselei, ca sa stim unde e marginea. 0 = necunoscuta, si atunci
## cursa ramane exact cea ceruta de pista.
var road_half_width: float = 0.0
var escape_lane: float = ESCAPE_LANE_DEFAULT
## Defazaj 0..1 dintr-o perioada. Doua obstacole pe aceeasi pista cu acelasi
## defazaj se misca la unison si arata ca un mecanism, nu ca doua obstacole.
var phase: float = 0.0

## Model optional + configuratia lui.
var model_scene: PackedScene
var model_scale: float = 1.0
var roll_radius: float = 0.0 # >0 = sfera care se rostogoleste
## Clasa de textura a modelului ("" = atlasul comun). Se aplica TRIPLANAR IN
## SPATIUL OBIECTULUI, nu al lumii: obstacolul se misca, iar proiectia de lume
## i-ar face textura sa "inoate" pe suprafata (style_bible §4).
var model_tri_class: String = ""
## Clase pe PIESE numite, pentru modelele care nu sunt dintr-un material unic.
## Bolovanul e integral roca si ii ajunge `model_tri_class`; barca sabani are
## coca de lemn si o dunga vopsita, deci ii trebuie maparea per nod — aceeasi
## impartire ca la landmark-uri ("tri_class" vs "classes").
var model_classes: Dictionary = {}

var _time: float = 0.0
var _pivot: Node3D
var _last_pos: Vector3
var _area: Area3D
var _half_extent: float = 1.3
var _configured: bool = false
## Masina lovita -> secunde pana poate fi imbrancita din nou.
var _cooldown: Dictionary = {}

func _ready() -> void:
	sync_to_physics = true
	if model_scene != null:
		_build_model()
	else:
		_build_placeholder_box()
	if not Engine.is_editor_hint():
		_build_sweep_area()

## Cursa si perioada se calculeaza la primul tick, nu in _ready: pista pune
## `travel` DUPA add_child (adica dupa _ready), asa ca aici amplitudinea ar fi
## inca zero si limitarea n-ar face nimic.
func _configure() -> void:
	_configured = true
	_clamp_travel()
	if period <= 0.0:
		period = _readable_period()
	# Pozitia de start a defazajului, nu centrul: altfel primul cadru "vede" o
	# deplasare de toata amplitudinea si roteste mingea brusc.
	_last_pos = center + travel * sin(TAU * phase)

## Obstacolul nu iese niciodata din sosea: cursa se taie astfel incat MARGINEA
## lui sa se opreasca la marginea drumului (plus `escape_lane`, daca pista e
## ingusta si vrei sa ramana si o banda de trecere). Pista cere maturarea
## maxima, aici se decide cat e cinstit pe latimea asta de sosea.
func _clamp_travel() -> void:
	if road_half_width <= 0.0:
		return
	var max_amp := maxf(road_half_width - _half_extent - escape_lane, 0.0)
	if travel.length() > max_amp:
		travel = travel.normalized() * max_amp

## Perioada la care varful de viteza (mijlocul cursei) ramane sub plafon.
## Viteza maxima a unei oscilatii sinusoidale de amplitudine A: A * TAU / T.
func _readable_period() -> float:
	var amp := travel.length()
	if amp < 0.01 or max_sweep_speed <= 0.0:
		return 3.2
	return maxf(TAU * amp / max_sweep_speed, 1.5)

func _build_model() -> void:
	var model := model_scene.instantiate() as Node3D
	model.scale = Vector3.ONE * model_scale
	# `roll_radius` primit de la apelant e o INTENTIE ("obiectul asta se
	# rostogoleste"), nu o masuratoare. Raza efectiva se ia din model, ca un GLB
	# regenerat la alt diametru sa nu ramana cu o sfera de coliziune de alta
	# marime decat ce se vede. Apelantul o calcula de mana din diametrul de 5 m
	# al mingii — exact numarul care se schimba la inlocuirea cu un bolovan.
	if roll_radius > 0.0:
		var measured := Track.model_aabb(model)
		var d := maxf(measured.size.x, measured.size.z)
		if d > 0.02:
			roll_radius = d * 0.5
	# Pivotul sta la inaltimea centrului sferei; modelul (origine in centru)
	# se aseaza in pivot, iar rostogolirea roteste pivotul.
	_pivot = Node3D.new()
	_pivot.position = Vector3.UP * roll_radius
	add_child(_pivot)
	_pivot.add_child(model)
	# Atlasul comun. Modelele vechi (mingea de plaja) isi aduceau materialul lor
	# si mergeau fara asta; cele care respecta contractul de paleta au UV-uri
	# spre sloturi si un material fara imagine — fara apel, ies gresit.
	# Cu o clasa ceruta (bolovanul din desert = "rock"), textura de clasa ia
	# locul atlasului — dar in spatiul OBIECTULUI, ca sa se rostogoleasca odata
	# cu el. `model_scale` intra in socoteala ca pietrele pictate sa masoare in
	# lume cat cele de pe falezele din care s-a desprins.
	if not model_classes.is_empty():
		Palette.apply_class_materials(model, model_classes)
	elif model_tri_class.is_empty():
		Palette.apply_world_material(model)
	else:
		Palette.apply_object_triplanar_class(model, model_tri_class, model_scale)
	var shape := CollisionShape3D.new()
	if roll_radius > 0.0:
		var sphere := SphereShape3D.new()
		sphere.radius = roll_radius
		shape.shape = sphere
		shape.position = Vector3.UP * roll_radius
		_half_extent = roll_radius
	else:
		# Cutia se MASOARA pe model cand exista unul, in loc sa ramana pe cotele
		# excavatorului. O sabani de 5 m intr-o cutie de 4.5 x 2.6 ar fi fost
		# lovita cu jumatate de metru inainte s-o atingi — si invers pe un model
		# mai mic, ai fi trecut prin ea.
		var box := BoxShape3D.new()
		# `model_aabb` porneste din transformul RADACINII, deci `model_scale` e
		# deja inauntru — inmultirea cu el ar dubla cutia. (Acelasi motiv pentru
		# care ramura cu `roll_radius` de mai sus foloseste masuratoarea direct.)
		var measured := Track.model_aabb(model)
		if measured.size.length() > 0.5:
			box.size = measured.size
			shape.position = Vector3.UP * (box.size.y * 0.5)
			_half_extent = maxf(box.size.x, box.size.z) * 0.5
		else:
			box.size = Vector3(4.5, 2.2, 2.6)
			shape.position = Vector3.UP * 1.1
			_half_extent = 2.25
		shape.shape = box
	add_child(shape)

func _build_placeholder_box() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4.5, 2.2, 2.6)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.15)
	mesh.material_override = mat
	mesh.position = Vector3.UP * 1.1
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(4.5, 2.2, 2.6)
	shape.shape = col_box
	shape.position = Vector3.UP * 1.1
	add_child(shape)
	_half_extent = 2.25

## Zona de ghiont: un pic mai grasa decat corpul solid, ca sa prinda contactul
## inainte ca masina sa apuce sa ramana captiva intre obstacol si perete.
func _build_sweep_area() -> void:
	_area = Area3D.new()
	add_child(_area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * (_half_extent * 2.0 + 1.0)
	shape.shape = box
	shape.position = Vector3.UP * maxf(_half_extent, 1.1)
	_area.add_child(shape)

func _physics_process(delta: float) -> void:
	if not _configured:
		_configure()
	_time += delta
	global_position = center + travel * sin(TAU * (_time / period + phase))
	var moved := global_position - _last_pos
	if _pivot != null and roll_radius > 0.0:
		# Rostogolire: rotatie in jurul axei perpendiculare pe miscare.
		var flat := moved
		flat.y = 0.0
		if flat.length() > 0.0001:
			var axis := Vector3.UP.cross(flat.normalized()).normalized()
			_pivot.global_rotate(axis, -flat.length() / roll_radius)
	_last_pos = global_position
	if not Engine.is_editor_hint():
		_shove_cars(delta)

## Contactul te DEZECHILIBREAZA, nu te captureaza. Ghiontul e RADIAL (dinspre
## obstacol spre masina) plus un pic inainte, nu in sensul maturarii: impins pe
## sensul maturarii, exact masina prinsa intre obstacol si perete — singura care
## chiar are nevoie de ajutor — ar fi impinsa si mai tare in perete. Radial +
## inainte are mereu unde sa te scoata, fiindca soseaua continua.
func _shove_cars(delta: float) -> void:
	if _area == null:
		return
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	for body in _area.get_overlapping_bodies():
		var car := body as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = 0.35
		var away := car.global_position - global_position
		away.y = 0.0
		if away.length() < 0.05:
			continue
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		car.apply_sweep(away.normalized() * SWEEP_PUSH
			+ fwd.normalized() * SWEEP_PUSH * 0.5 + Vector3.UP * 0.8)
