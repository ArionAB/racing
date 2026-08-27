@tool
class_name CraneHazard
extends Node3D
## Macaraua de pe nodul Huangjuewan (Chongqing, brief §2 POI F si §3): un braț
## rotitor care leagana un prefabricat peste rampa de sus. Contactul te
## INVARTE, nu te distruge.
##
## [b]E [CarouselHazard] mutat pe alt pivot[/b], si diferenta e toata in unde
## sta axa. Caruselul are butucul PE drum si vanele mature carosabilul: nu
## exista linie sigura, doar fereastra dintre doua vane. Macaraua are turnul
## LANGA drum si o sarcina la capatul unui braț de 13 m: sarcina traverseaza
## soseaua de doua ori pe rotatie (o data dus, o data intors), iar restul
## ciclului drumul e complet liber. Ritmul e deci de PANDA, nu de fereastra —
## exact ce cere un POI in care esti oricum ocupat sa urci in spirala.
##
## [b]Pedeapsa e rotatia, nu timpul[/b] (brief §3: „contact = invartit, nu
## distrus"). Sarcina e un corp solid care se misca incet (4 m/s la capatul
## brațului), deci impactul in sine e un bumping cinstit; peste el se adauga
## un ghiont pe TANGENTA (ca la carusel) si o rotire VIZUALA a caroseriei
## ([code]Car.spin_body[/code], imprumutata de la tromba). Nu exista `respawn`,
## nu exista `race_active = false`, iar strivirea e minima: pierzi linia si
## cateva zecimi, nu turul.
##
## [b]Si sarcina NU e un perete[/b]. Un bloc de beton de 4.6 m latime care
## atarna la 0.56 m de asfalt opreste orice masina — criticul a masurat 22.0
## -> 1.1 m/s la impact, adica exact „distrus", pe dos fata de contract.
## De aceea contactul deschide o exceptie de coliziune cu prefabricatul
## (`clear_seconds`, vezi [HazardThrow]) cu cateva cadre inainte, prin zona de
## ghiont care e mai grasa decat el: sarcina trece prin tine invartindu-te si
## maturandu-te de pe linie, in loc sa te zideasca.
##
## De ce spin VIZUAL si nu o rotatie reala: nota din `Car.spin_body` — o
## rotire a lui `basis` in aer te-ar face sa aterizezi cu botul in alta parte
## decat merge viteza, adica un tete-a-queue pe care nu l-ai putut evita.
##
## [b]Cotele ies din model[/b] (`tools/probe_cq_dims.gd` pe
## `tower_crane.glb`): turnul are 22.05 m, deci acolo sta pivotul brațului;
## brațul lung merge spre -Z pana la 18 m, cu carligul modelat la z ≈ -13 —
## de aia `hook_radius` implicit e 13, ca `prefab_slab.glb` sa atarne fix de
## unde atarna carligul desenat.

const WorldProp = preload("res://scenes/props/world_prop.gd")
const CRANE_MODEL: String = "res://assets/models/chongqing/structures/tower_crane.glb"
const SLAB_MODEL: String = "res://assets/models/chongqing/props/prefab_slab.glb"
const JIB_NODE := "Jib"
const MAST_NODE := "TowerCrane"
## Cota pivotului brațului = inaltimea turnului din GLB.
const JIB_HEIGHT: float = 22.05
## Gabaritul turnului din GLB, pentru colizor.
const MAST_SIDE: float = 3.6
## Gabaritul prefabricatului din GLB (originea lui e la CARLIG, geometria
## atarna sub ea: y de la -3.05 la -0.06).
const SLAB_SIZE := Vector3(4.6, 2.99, 2.2)
const SLAB_TOP_OFFSET: float = -0.06

@export_group("Ritm")
## O rotatie completa a brațului (s). Brief: 18-22, si NU divizor al turului.
@export_range(4.0, 120.0, 0.5) var period: float = 20.0
## Decalajul (0..1 din period). Doua macarale nu bat la unison.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Cu cat inainte de trecerea sarcinii peste axa drumului se aprinde lampa de
## avertizare (s). Brief §3, contractul comun al hazardelor ciclice: 3.
@export_range(0.0, 10.0, 0.1) var telegraph_lead: float = 3.0

@export_group("Geometrie")
## Semilatimea soselei sub braț.
@export_range(2.0, 16.0, 0.1) var road_half_width: float = 3.4
## Cat de lateral sta turnul fata de axa drumului (m). Turnul NU are voie pe
## carosabil — doar sarcina trece peste el.
@export_range(3.0, 40.0, 0.5) var tower_offset: float = 7.0
## Pe ce parte sta turnul: +1 dreapta, -1 stanga sensului de mers.
@export_enum("Dreapta:1", "Stanga:-1") var tower_side: int = 1
## Raza la care atarna sarcina pe braț (m). Trebuie sa fie mai mare decat
## `tower_offset`, altfel sarcina nu ajunge niciodata deasupra drumului.
@export_range(4.0, 30.0, 0.5) var hook_radius: float = 13.0
## Cat spatiu ramane sub prefabricat cand trece peste asfalt (m).
##
## Sub 1.1 m (inaltimea colizorului masinii) sarcina chiar te prinde — asta e
## rostul. „Te prinde" inseamna aici ghiont + invartire, nu oprire: contactul
## solid e taiat de `clear_seconds` (vezi antetul).
@export_range(0.0, 4.0, 0.05) var load_clearance: float = 0.5
## Legănarea sarcinii, in grade, in planul de mers al brațului.
@export_range(0.0, 15.0, 0.5) var sway_deg: float = 3.0
## Cat dureaza o legănare completa (s).
@export_range(1.0, 20.0, 0.1) var sway_period: float = 4.5

@export_group("Lovitura")
## Ghiontul pe tangenta rotatiei (m/s), ADUNAT la viteza care ti-a mai ramas.
##
## Se aduna, spre deosebire de monorail (unde viteza de dupa lovitura se
## scrie): acolo te ia un tren, aici te sterge o sarcina care se plimba cu
## 4 m/s. Ce te scoate de pe linie e tangenta, nu masa.
@export_range(0.0, 20.0, 0.5) var sweep_push: float = 7.0
## Cat te ridica lovitura (m). Mic dinadins: sarcina te matura, nu te lanseaza
## — dar trebuie sa se si VADA, deci trece prin `Car.launch` ca la monorail
## (vezi [HazardThrow]). Cu vechiul „+= Vector3.UP * 1.2" urcarea masurata era
## sub 5 cm: un @export mort.
@export_range(0.0, 3.0, 0.05) var lift_rise: float = 0.45
## Cat timp dupa contact prefabricatul nu mai are voie sa atinga masina (s).
##
## [b]Asta e ce transforma sarcina din PERETE in matura.[/b] Criticul a
## masurat prima versiune: 22.0 -> 1.1 m/s la impact, adica un zid de beton de
## 4.6 m latime la 0.56 m de asfalt. „Contact = te INVARTE, nu te distruge"
## (brief §3) nu poate fi scris cu un corp solid care te opreste: zona de
## ghiont e mai GRASA decat sarcina, deci exceptia se pune cu cateva cadre
## inainte de contactul solid, iar prefabricatul trece prin tine invartindu-te.
@export_range(0.0, 4.0, 0.05) var clear_seconds: float = 1.0
## Rotirea VIZUALA a caroseriei dupa contact (rad/s) si cat tine (s).
@export_range(0.0, 20.0, 0.5) var spin_rate: float = 7.0
@export_range(0.0, 5.0, 0.1) var spin_seconds: float = 1.1
## Strivirea: cat tine plafonul redus (s), cat de mult il taie, si cat din
## viteza ramane. Deliberat blande — pedeapsa e linia pierduta, nu turul.
@export_range(0.0, 3.0, 0.05) var crush_seconds: float = 0.6
@export_range(0.3, 1.0, 0.01) var crush_factor: float = 0.85
## Cat din viteza ta ramane dupa contact. Se aplica O SINGURA DATA, in
## aruncare; `Car.crush` primeste 1.0 (altfel taietura ar cadea de doua ori).
@export_range(0.0, 1.0, 0.01) var keep_speed: float = 0.75
## Cat sta o masina imuna dupa o lovitura (s), ca sa nu primeasca ghiontul de
## 60 de ori pe secunda cat sta lipita de prefabricat.
@export_range(0.05, 3.0, 0.05) var hit_cooldown: float = 0.5

@export_group("Constructie")
@export var crane_model: PackedScene = null
@export var slab_model: PackedScene = null
@export_range(0.2, 3.0, 0.05) var model_scale: float = 1.0
## Slotul de paleta al cablului.
@export_range(0, 31) var cable_slot: int = Palette.RUST_METAL

var _jib_pivot: Node3D
var _hook: Node3D
var _load: AnimatableBody3D
var _area: Area3D
var _lamp: HazardLamp
var _time: float = 0.0
var _started: bool = false
var _prev_load: Vector3 = Vector3.ZERO
var _load_velocity: Vector3 = Vector3.ZERO
var _cooldown: Dictionary = {}


func _ready() -> void:
	add_to_group("hazards")
	_build_tower()
	_build_load()
	_build_lamp()
	_apply_cycle(1.0 / 60.0)
	_prev_load = _load.global_position


# ------------------------------------------------------------ constructie

func _tower_x() -> float:
	return signf(float(tower_side)) * tower_offset


## Turnul (fix, cu colizor) si pivotul brațului.
func _build_tower() -> void:
	var scene := crane_model if crane_model != null else load(CRANE_MODEL) as PackedScene
	var root: Node3D = scene.instantiate() as Node3D if scene != null else null
	var body := StaticBody3D.new()
	body.name = "Mast"
	add_child(body)
	body.position = Vector3(_tower_x(), 0.0, 0.0)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(MAST_SIDE, JIB_HEIGHT, MAST_SIDE) * model_scale
	col.shape = box
	col.position = Vector3(0.0, JIB_HEIGHT * 0.5 * model_scale, 0.0)
	body.add_child(col)

	_jib_pivot = Node3D.new()
	_jib_pivot.name = "JibPivot"
	add_child(_jib_pivot)
	_jib_pivot.position = Vector3(_tower_x(), JIB_HEIGHT * model_scale, 0.0)

	if root == null:
		# Rezerva pe cutii: pista nu ramane fara gimmick din cauza unui fisier.
		body.add_child(PaletteBox.instance(
			Vector3(MAST_SIDE, JIB_HEIGHT, MAST_SIDE) * model_scale,
			Palette.PAINTED_METAL,
			Vector3(0.0, JIB_HEIGHT * 0.5 * model_scale, 0.0)))
		_jib_pivot.add_child(PaletteBox.instance(
			Vector3(0.5, 0.5, hook_radius * 2.0), Palette.PAINTED_METAL,
			Vector3(0.0, 0.0, -hook_radius * 0.5 + hook_radius * 0.5)))
		return
	# Brațul se desprinde din GLB si trece pe pivot; turnul ramane pe corp.
	# `remove_child` INAINTE de `queue_free` (lectia din `TrainHazard._extract`):
	# eliberarea e amanata pana la finalul cadrului, iar pana atunci nodul ar
	# fi ramas in arbore, randat si numarat.
	var jib := root.find_child(JIB_NODE, true, false) as Node3D
	if jib != null:
		jib.get_parent().remove_child(jib)
		jib.scale = Vector3.ONE * model_scale
		_jib_pivot.add_child(jib)
		Palette.apply_object_class_materials(jib, WorldProp.prop_classes(), model_scale)
	root.scale = Vector3.ONE * model_scale
	body.add_child(root)
	Palette.apply_object_class_materials(root, WorldProp.prop_classes(), model_scale)


## Sarcina: cablul (sub braț) plus prefabricatul, pe un corp animat.
##
## Corpul NU e copil al pivotului: e frate, si i se scrie transformul intreg o
## data pe cadru din cel al carligului (memoria
## `jolt-sync-transform-o-singura-scriere`). Copil al unui nod rotit, un
## `AnimatableBody3D` cu `sync_to_physics` si-ar fi luat transformul de la
## serverul de fizica si de la parinte in acelasi timp.
func _build_load() -> void:
	_hook = Node3D.new()
	_hook.name = "Hook"
	_jib_pivot.add_child(_hook)
	_hook.position = Vector3(0.0, 0.0, -hook_radius * model_scale)

	_load = AnimatableBody3D.new()
	_load.name = "Load"
	_load.sync_to_physics = true
	add_child(_load)

	# Originea prefabricatului e la carlig si geometria atarna sub ea, deci
	# „cat de sus e carligul" se deriva din garda ceruta sub sarcina.
	var hook_y := load_clearance + SLAB_SIZE.y * model_scale
	var drop := hook_y - JIB_HEIGHT * model_scale # negativ: sub braț
	var cable_len := -drop
	if cable_len > 0.1:
		_load.add_child(PaletteBox.instance(Vector3(0.16, cable_len, 0.16),
			cable_slot, Vector3(0.0, drop + cable_len * 0.5, 0.0)))
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SLAB_SIZE * model_scale
	col.shape = box
	col.position = Vector3(0.0, drop - (SLAB_SIZE.y * 0.5 + SLAB_TOP_OFFSET) * model_scale, 0.0)
	_load.add_child(col)

	var scene := slab_model if slab_model != null else load(SLAB_MODEL) as PackedScene
	var slab: Node3D = scene.instantiate() as Node3D if scene != null else null
	if slab != null:
		slab.scale = Vector3.ONE * model_scale
		slab.position = Vector3(0.0, drop, 0.0)
		_load.add_child(slab)
		Palette.apply_object_class_materials(slab, WorldProp.prop_classes(), model_scale)
	else:
		_load.add_child(PaletteBox.instance(SLAB_SIZE * model_scale,
			Palette.CONCRETE, col.position))

	# Zona de ghiont: mult mai grasa decat sarcina pe orizontala, si asta e
	# functional, nu generos. Ghiontul si exceptia de coliziune trebuie sa
	# apuce sa se aplice INAINTE ca solverul sa rezolve contactul cu betonul:
	# la 22 m/s masina inainteaza 0.37 m pe cadru de fizica, deci marginea de
	# 1.2 m de fiecare parte e o fereastra de trei cadre. Cu vechii 0.6 m
	# aveam un singur cadru si sonda criticului a masurat ce inseamna asta —
	# viteza cazuta de la 22.0 la 1.1 m/s, adica un perete.
	_area = Area3D.new()
	_area.name = "SweepZone"
	_area.monitorable = false
	var azone := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = (SLAB_SIZE + Vector3(2.4, 0.6, 2.4)) * model_scale
	azone.shape = abox
	azone.position = col.position
	_area.add_child(azone)
	_load.add_child(_area)


## Lampa de avertizare, pe marginea dinspre turn, la intrarea sub braț.
func _build_lamp() -> void:
	var side := signf(float(tower_side))
	var at := Vector3(side * (road_half_width + 1.0), 0.0, hook_radius * 0.6)
	var post := PaletteBox.instance(Vector3(0.2, 2.6, 0.2), Palette.PAINTED_METAL,
		at + Vector3.UP * 1.3)
	post.name = "WarnPost"
	add_child(post)
	_lamp = HazardLamp.new()
	_lamp.name = "WarnLamp"
	_lamp.slots = [Palette.CAR_YELLOW]
	_lamp.vertical = false
	add_child(_lamp)
	_lamp.position = at + Vector3.UP * 2.7


# ------------------------------------------------------------------- ciclu

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _started:
		_started = true
		_time = phase * period
	_time += delta
	_apply_cycle(delta)
	_hit_cars(delta)


func _apply_cycle(delta: float) -> void:
	if _jib_pivot == null or _load == null:
		return
	_jib_pivot.rotation.y = jib_angle()
	_hook.rotation.z = deg_to_rad(sway_deg) * sin(TAU * _time / sway_period)
	# O SINGURA scriere de transform pe cadru.
	_load.global_transform = _hook.global_transform
	_load_velocity = (_load.global_position - _prev_load) / maxf(delta, 0.0001)
	_prev_load = _load.global_position
	if _lamp != null:
		var lead := seconds_to_crossing()
		_lamp.blink(0, lead <= telegraph_lead and fmod(_time, 0.4) < 0.2)


## Unghiul brațului acum (rad). 0 = brațul spre -Z (in lungul soselei).
func jib_angle() -> float:
	return fposmod(TAU * (_time / period + phase), TAU)


## Unghiurile la care sarcina trece peste AXA soselei (x = 0).
##
## Sarcina sta la (-R·sin a) fata de turn pe X, deci trece axa cand
## sin a = tower_x / R. Doua solutii pe rotatie: dus si intors.
func _crossing_angles() -> Array[float]:
	var r := hook_radius * model_scale
	if r < 0.01:
		return []
	var s := _tower_x() / r
	if absf(s) > 1.0:
		return [] # brațul nu ajunge niciodata peste axa
	var a := asin(s)
	return [fposmod(a, TAU), fposmod(PI - a, TAU)]


## Cate secunde mai sunt pana sarcina trece iar peste axa soselei.
func seconds_to_crossing() -> float:
	var angles := _crossing_angles()
	if angles.is_empty():
		return INF
	var now := jib_angle()
	var best := INF
	for a in angles:
		best = minf(best, fposmod(a - now, TAU))
	return best * period / TAU


## Cat de departe de axa soselei e sarcina acum (m, pe lateral).
func load_offset() -> float:
	return _load.global_position.x - global_position.x if _load != null else INF


## Unde (in coordonatele nodului) trece sarcina peste axa drumului, si la ce
## unghi de braț. Nu e la z = 0: sarcina descrie un cerc in jurul turnului, iar
## turnul e LANGA drum, deci cele doua treceri cad simetric fata de el, la
## z = -/+R*cos(a). Cu implicitele (turn la 7 m, braț de 13) asta inseamna doua
## ferestre la ~22 m una de alta — de aia hazardul se citeste ca o panda cu
## doua batai, nu ca o singura poarta.
##
## Sonda are nevoie de punctele astea ca sa poata TRIMITE masina in sarcina;
## fara ele ar trebui sa ghiceasca unde sa astepte impactul.
func crossings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var r := hook_radius * model_scale
	for a in _crossing_angles():
		out.append({
			"angle": a,
			"z": -r * cos(a),
			"seconds": fposmod(a - jib_angle(), TAU) * period / TAU,
		})
	return out


func _hit_cars(delta: float) -> void:
	for key in _cooldown.keys():
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0 or not is_instance_valid(key):
			_cooldown.erase(key)
		else:
			_cooldown[key] = left
	for b in _area.get_overlapping_bodies():
		var car := b as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = hit_cooldown
		# Tangenta: chiar directia in care se misca sarcina. Nu se deduce din
		# unghi — legănarea o schimba, si ce conteaza e incotro TE-A LOVIT.
		var tangent := _load_velocity
		tangent.y = 0.0
		if tangent.length_squared() < 0.01:
			tangent = Vector3.RIGHT * signf(float(tower_side))
		else:
			tangent = tangent.normalized()
		var mine := Vector3(car.velocity.x, 0.0, car.velocity.z) * keep_speed
		HazardThrow.throw(car, _load, mine + tangent * sweep_push,
			lift_rise, clear_seconds)
		# Sensul rotirii urmeaza sensul maturarii, ca invartirea sa se citeasca
		# drept „m-a impins prefabricatul", nu ca un bug de fizica.
		var sign := signf(tangent.cross(Vector3.UP).dot(
			-car.global_transform.basis.z))
		car.spin_body(spin_rate * (sign if absf(sign) > 0.01 else 1.0),
			spin_seconds)
		car.crush(crush_seconds, crush_factor, Vector3(1.2, 0.62, 1.2), 1.0)


# ---------------------------------------------------------- pentru sonde

func load_body() -> AnimatableBody3D:
	return _load


func load_velocity() -> Vector3:
	return _load_velocity


## Cota celui mai de jos punct al prefabricatului (m, global).
##
## Se citeste din COLIZOR, nu din formula cu care a fost asezat: legănarea il
## plimba, iar diferenta dintre "cat am cerut" si "cat e" e chiar lucrul pe
## care sonda trebuie sa-l poata contrazice.
func load_bottom() -> float:
	if _load == null:
		return INF
	for c in _load.get_children():
		var shape := c as CollisionShape3D
		if shape == null:
			continue
		var box := shape.shape as BoxShape3D
		if box == null:
			continue
		return shape.global_position.y - box.size.y * 0.5
	return INF


## Lampa de avertizare aprinsa acum?
func warning() -> bool:
	return _lamp != null and _lamp.lit() == 0


func cycle_time() -> float:
	return fposmod(_time, period)
