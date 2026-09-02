@tool
class_name BurnerHazard
extends Node3D
## SUFLUL ARZATORULUI (Cappadocia, brief §2 POI C / §3 „suflul arzatorului").
##
## Un balon ancorat langa exteriorul hairpinului de la capatul cornisei. Pe ciclu
## arzatorul porneste — flacara e telegraful, 1 s — si apoi sufla LATERAL, spre
## exteriorul curbei, adica spre gol. Nu te distruge: te muta cu cateva zeci de
## centimetri pe secunda pe linia gresita, exact cand ai nevoie de ea.
##
## [b]De ce nu e TyphoonHazard.[/b] Tromba e globala si te SCOATE din joc: te
## ridica de pe asfalt si te lasa jos peste o secunda si jumatate, fara volan.
## Aici pedeapsa e alta, si mai ieftina: ramai pe roti, ramai in control, dar
## esti impins spre buza. Decizia pe care o pune e „mai franez sau trec inainte
## sa porneasca?", nu „am ghinion sau nu" — de aia telegraful de 1 s e obligatoriu
## si de aia forta e o ACCELERATIE plafonata, nu un impuls.
##
## [b]De ce acceleratie si nu impuls.[/b] Un impuls aplicat o data e o loterie
## de cadru: acelasi hazard, la aceeasi viteza, da alt rezultat dupa cum a picat
## pasul de fizica. O acceleratie constanta pe `blow` secunde e ACEEASI pentru
## toata lumea si se citeste ca vant, nu ca lovitura. Se aplica prin
## `apply_central_force(a * masa)`, deci [b]masina grea nu e imuna si nici cea
## usoara nu zboara[/b]: acceleratia e egala, adica exact ce cere „AI onest".
##
## [b]Directia se DERIVA, nu se scrie.[/b] Nodul isi ia directia din propria
## orientare (-Z local, ca orice nod din Godot care „priveste" undeva). Asa se
## roteste in editor cu mouse-ul si sufla vizibil incolo, in loc sa aiba un
## vector in Inspector care nu se vede in viewport.

const WorldProp = preload("res://scenes/props/world_prop.gd")

## Flacara: un con emisiv scurt peste cos. `LAVA_ORANGE` prin `glow_material`,
## adica exact materialul lavei — nu unul nou (bugetul de materiale al pistei).
const FLAME_SLOT: int = 30
const FLAME_RADIUS: float = 0.55
const FLAME_HEIGHT: float = 1.8

@export_group("Ritm")
## Ciclul complet. Brief: ~17 s, si NU divizor al turului (lectia Stromboli) —
## faza se muta de la tur la tur, deci nu devine un metronom pe care il inveti
## pe de rost intr-un singur tur.
@export_range(4.0, 120.0, 0.5) var period: float = 17.0
## Telegraful: cat arde flacara INAINTE sa inceapa suflul. Sub o secunda hazardul
## devine nedrept (nu ai ce decide), peste doua devine decor.
@export_range(0.2, 5.0, 0.1) var telegraph: float = 1.0
## Cat dureaza suflul propriu-zis.
@export_range(0.1, 5.0, 0.1) var blow: float = 0.8
## Decalajul in ciclu (0..1), ca doua arzatoare sa nu porneasca odata.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

@export_group("Suflu")
## Acceleratia laterala (m/s2). Se compara cu gravitatia jocului (28): la 9
## inseamna aproape o treime din greutate impinsa lateral — se simte, dar nu
## rupe linia cui a franat din timp.
@export_range(0.0, 40.0, 0.5) var accel: float = 9.0
## Raza pe care se simte, de la nodul arzatorului.
@export_range(2.0, 40.0, 0.5) var radius: float = 11.0

@export_group("Constructie")
@export var basket_model: PackedScene = null
@export var envelope_model: PackedScene = null
@export_range(0.2, 4.0, 0.05) var model_scale: float = 1.0
## Scara PANZEI, separat de a cosului — vezi nota din `_build_models`.
@export_range(0.2, 4.0, 0.05) var envelope_scale: float = 1.0

var _area: Area3D
var _flame: MeshInstance3D
var _time: float = 0.0
var _started: bool = false
var _blowing: bool = false


func _ready() -> void:
	_build_models()
	_build_flame()
	_build_area()
	set_physics_process(not Engine.is_editor_hint())


## Cosul si panza, fiecare cu scara LUI. Cosul se umfla (piesa din kit are
## 2.16 m si trebuie sa arate cat un cos in care incape lume), panza nu: ea vine
## deja la cota din brief, 12 m. Acelasi factor pe amandoua da un balon de 26 m
## care umple cadrul — masurat pe captura de la frac 0.28.
func _build_models() -> void:
	for spec: Array in [[basket_model, 0.0, model_scale],
			[envelope_model, 2.0, envelope_scale]]:
		var scene: PackedScene = spec[0]
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		if inst == null:
			continue
		var sc := float(spec[2])
		inst.scale = Vector3.ONE * sc
		inst.position = Vector3(0.0, float(spec[1]), 0.0)
		Palette.apply_object_class_materials(inst, WorldProp.prop_classes(), sc)
		add_child(inst)


## Flacara: conul emisiv de deasupra cosului. `radial_segments`/`rings` SETATE
## (CLAUDE.md — o primitiva lasata la implicit aduce mii de triunghiuri dintr-un
## foc); aici ies 24 de fete.
func _build_flame() -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = FLAME_RADIUS
	cone.height = FLAME_HEIGHT
	cone.radial_segments = 8
	cone.rings = 1
	_flame = MeshInstance3D.new()
	_flame.name = "Flame"
	_flame.mesh = cone
	_flame.material_override = Palette.glow_material(FLAME_SLOT, 2.4)
	_flame.position = Vector3(0.0, 2.6, 0.0)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.visible = false
	add_child(_flame)


func _build_area() -> void:
	_area = Area3D.new()
	_area.name = "Blast"
	_area.monitoring = true
	_area.monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	_area.add_child(shape)
	add_child(_area)


func _physics_process(delta: float) -> void:
	if not _started:
		_started = true
		_time = phase * period
	_time += delta
	var t := fposmod(_time, period)
	var lit := t < telegraph + blow
	_blowing = t >= telegraph and t < telegraph + blow
	if _flame != null:
		_flame.visible = lit
		# Flacara pulsa: mai lunga cat sufla, ca telegraful si suflul sa nu
		# arate identic — altfel „a pornit" si „acum te impinge" sunt acelasi
		# cadru pentru ochi.
		var s := 1.0 + (0.6 if _blowing else 0.0)
		_flame.scale = Vector3(1.0, s, 1.0)
	if not _blowing:
		return
	# -Z local = incotro „priveste" nodul, deci incotro sufla. Vezi antetul:
	# directia se roteste in viewport, nu se scrie in Inspector.
	var dir := -global_transform.basis.z
	dir.y = 0.0
	dir = dir.normalized()
	for b in _area.get_overlapping_bodies():
		var car := b as Car
		if car == null:
			continue
		# ACCELERATIE, nu impuls: aceeasi pentru orice masa (vezi antetul).
		car.apply_central_force(dir * accel * car.mass)


# ---------------------------------------------------------------- pentru sonde

func is_blowing() -> bool:
	return _blowing


func cycle_time() -> float:
	return fposmod(_time, period)


## Directia suflului in lume, derivata din orientarea nodului.
func blow_dir() -> Vector3:
	var d := -global_transform.basis.z
	d.y = 0.0
	return d.normalized()
