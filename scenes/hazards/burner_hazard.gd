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
## Flacara se vede de pe drum, nu doar de langa cos: balonul sta la 13-19 m de
## axa, iar la 0.55 x 1.8 m era un chibrit intr-un colt de cadru — verdictul de
## la volan (4 sep 2026): „nu se intampla nimic vizual, se simte ca un zid
## invizibil". 1.4 x 4.5 m e o limba de foc cat cosul.
const FLAME_RADIUS: float = 1.4
const FLAME_HEIGHT: float = 4.5
## Suflul se VEDE: dare de aer cald care traverseaza toata zona de suflu pe
## directia lui, cat tine telegraful si suflul. Fara asta, o acceleratie
## laterala fara nicio imagine e exact „zidul invizibil" (verdictul de la
## volan, 4 sep 2026). Sunt MESH-uri miscate din cod, nu GPUParticles: prima
## varianta cu particule pe materialul lumii n-a randat nimic (ProbeMasca nu
## vede particule, captura n-a aratat nimic), iar un lucru pe care nici sonda
## nici poza nu-l vad nu exista. Culoarea e cea a flacarii (acelasi
## `glow_material`, deci ZERO materiale noi): aerul care iese din arzator e
## fierbinte, si asa se citeste si de unde vine suflul. Dungile umplu o cutie
## cat sfera de suflu, nu un jet din cos: jucatorul trebuie sa vada ZONA.
const GUST_COUNT: int = 28
const GUST_SPEED: float = 14.0
const GUST_LEN: float = 2.2

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
var _gust: Node3D
var _gust_t: Array[float] = []
var _time: float = 0.0
var _started: bool = false
var _blowing: bool = false


func _ready() -> void:
	_build_models()
	_build_flame()
	_build_gust()
	_build_area()
	set_physics_process(not Engine.is_editor_hint())


## Cosul si panza, fiecare cu scara LUI. Cosul se umfla (piesa din kit are
## 2.16 m si trebuie sa arate cat un cos in care incape lume), panza nu: ea vine
## deja la cota din brief, 12 m. Acelasi factor pe amandoua da un balon de 26 m
## care umple cadrul — masurat pe captura de la frac 0.28.
func _build_models() -> void:
	# Panza sta la 5 m peste cos (nu la 2, ca la cosurile care urca): intre
	# ele sta FLACARA, de 4.5 m, si trebuie sa se vada — la 2 m conul era
	# inauntrul panzei si arzatorul n-a avut niciodata telegraf vizibil
	# (verdictul de la volan, 4 sep 2026).
	for spec: Array in [[basket_model, 0.0, model_scale],
			[envelope_model, 5.6, envelope_scale]]:
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
	_flame.position = Vector3(0.0, 1.2 + FLAME_HEIGHT * 0.5, 0.0)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.visible = false
	add_child(_flame)


## Darele de aer cald. Fiecare e o placuta orizontala subtire, asezata pe -Z
## LOCAL (= `blow_dir()`), care aluneca pe -Z si se reia de la capatul din
## spate cand iese din zona. Pozitiile laterale (x local) si fazele sunt
## deterministe (fara RNG: doua rulari, aceeasi imagine — sondele compara).
func _build_gust() -> void:
	_gust = Node3D.new()
	_gust.name = "Gust"
	_gust.visible = false
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.6, GUST_LEN)
	mesh.orientation = PlaneMesh.FACE_Y
	var mat := Palette.glow_material(FLAME_SLOT, 2.4)
	for k in GUST_COUNT:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# x local: raspandite pe latimea zonei; y: la 0.5-1.6 m, cat sa treaca
		# prin dreptul masinii; faza: unde pe cursa porneste fiecare.
		var u := float(k) / float(GUST_COUNT)
		mi.position = Vector3(
			(fmod(u * 7.0, 1.0) * 2.0 - 1.0) * radius * 0.9,
			0.5 + fmod(u * 3.0, 1.0) * 1.1,
			0.0)
		_gust.add_child(mi)
		_gust_t.append(fmod(u * 5.0, 1.0))
	add_child(_gust)


## Muta darele pe -Z cat sufla; `z` de la +raza (spate) la -raza (capatul
## zonei), cu reluare — adica un curent continuu prin toata sfera de suflu.
func _animate_gust(delta: float) -> void:
	for k in _gust.get_child_count():
		_gust_t[k] = fmod(_gust_t[k] + delta * GUST_SPEED / (2.0 * radius), 1.0)
		var mi := _gust.get_child(k) as Node3D
		mi.position.z = radius - _gust_t[k] * 2.0 * radius


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
	if _gust != null:
		_gust.visible = lit
		if lit:
			_animate_gust(delta)
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
