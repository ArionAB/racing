@tool
class_name PathMover
extends Path3D
## Figurant mobil cu traiectorie desenata DE MANA: tractorul care se plimba pe
## langa drum, barca de pe lac, animalul care paste intre doua puncte.
##
## Traiectoria e chiar curba acestui nod: instantiezi scena (sau adaugi un nod
## PathMover) in scena pistei, desenezi curba cu gizmo-ul standard de Path3D —
## click pe sosea, tragi puncte, exact ca la TrackFromPath — si alegi modelul
## si viteza in Inspector. Zero cod per figurant, conform arhitecturii: conteaza
## ca traseul sa ramana editabil vizual, nu scris in fractii de mana.
##
## Corpul e AnimatableBody3D cu `sync_to_physics`, acelasi tipar ca trenul si
## SlidingHazard: fizica ii cunoaste viteza, deci masina care intra in el se
## CIOCNESTE cinstit — un corp cinematic fara sync ar fi un decor prin care
## treci sau, mai rau, un zid care nu impinge inapoi. Nu exista ghiont
## suplimentar (apply_sweep) ca la obstacolele de pe carosabil: figurantii
## stau pe margine, iar cine iese de pe sosea ca sa-i loveasca isi asuma
## ciocnirea, ca la orice perete.
##
## Y-ul curbei conteaza doar cu `stick_to_ground` stins (barca pe linia apei).
## Aprins, cota se ia din teren cu un raycast — desenezi curba din vederea de
## sus fara sa-ti pese de relief, si figurantul urca dealul singur.

## Cum se parcurge curba.
##
## BUCLA e pentru trasee inchise (tractorul da ture): la capat continua de la
## inceput, deci curba trebuie sa se termine unde a inceput, altfel se vede
## teleportarea. DUS_INTORS e pentru trasee deschise (animalul intre doua
## tufe): la capat intoarce pe loc si merge inapoi — intoarcerea e lina,
## fiindca yaw-ul urmareste directia cu viteza limitata (TURN_RATE).
enum TravelMode {
	BUCLA,      ## curba inchisa, parcursa la nesfarsit in acelasi sens
	DUS_INTORS, ## curba deschisa, parcursa alternativ in ambele sensuri
}

## Cat de repede se intoarce spre directia de mers (rad/s). Mic dinadins:
## intoarcerea de la capatul unui dus-intors trebuie sa se VADA ca manevra,
## nu ca un snap — un tractor care se rasuceste instant citeste ca teleportare.
const TURN_RATE: float = 2.2
## De cat de sus porneste si cat de adanc cauta raycast-ul de teren.
const GROUND_PROBE_UP: float = 4.0
const GROUND_PROBE_DOWN: float = 40.0
## Cutia placeholder (fara model): gabarit de tractor, galbena ca la
## SlidingHazard — se vede din prima ca e un substituent, nu arta.
const PLACEHOLDER_SIZE := Vector3(1.9, 1.7, 3.4)

## Modelul carat pe traiectorie. Gol = cutia galbena placeholder.
@export var model: PackedScene = null:
	set(v):
		model = v
		# Lista de sugestii pentru `animation` vine din modelul ales — la
		# schimbarea lui, Inspectorul trebuie sa reciteasca proprietatile.
		notify_property_list_changed()
## Ce PIESA din GLB se pastreaza (kiturile tin mai multe obiecte intr-un
## fisier). Gol = tot fisierul. Acelasi contract ca la HazardMarker.
@export var model_node: String = ""
@export_range(0.05, 4.0, 0.01) var model_scale: float = 1.0
## Corectie de orientare, in grade. Conventia Godot e "inainte = -Z", dar nu
## toate GLB-urile o respecta; daca figurantul merge cu spatele sau cu umarul
## inainte, de aici se indreapta — pe instanta, nu regenerand modelul.
@export_range(-180.0, 180.0, 1.0) var model_yaw: float = 0.0
## Clasa de material triplanar (ex. "rock"). Gol = atlasul comun de paleta.
## O CLASA, nu texturi proprii — garda din tools/probe_decor.gd numara
## materialele per pista (CLAUDE.md §texturi).
@export var tri_class: String = ""
## Ce clip din GLB se reda in bucla, daca modelul are AnimationPlayer. Gol =
## automat: "Walk" (indiferent de majuscule) cand se misca, o animatie de
## repaus ("Idle"/"Eating") cand `speed` e 0, altfel primul clip din fisier.
## In Inspector apare ca dropdown cu clipurile din GLB (se poate si tasta —
## sau lasa gol pentru automat); un nume care nu exista se anunta la consola
## si cade pe automat, nu lasa modelul teapan in tacere.
@export var animation: String = ""
## Viteza de redare a clipului (1 = cum a fost exportat). Un ciclu de mers
## exportat pentru 1.5 m/s arata a patinaj la 4 m/s — de aici se potriveste.
@export_range(0.1, 4.0, 0.05) var animation_speed: float = 1.0

@export_group("Miscare")
## m/s. 0 = parcat pe traiectorie (util cat asezi curba).
@export_range(0.0, 30.0, 0.1) var speed: float = 4.0
@export var travel_mode: TravelMode = TravelMode.BUCLA
## De unde porneste pe curba, ca fractie 0..1. Doi figuranti pe aceeasi bucla
## cu faze diferite nu merg lipiti unul de altul.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Lipit de teren (tractor, animal) sau pe cota curbei (barca pe linia apei).
@export var stick_to_ground: bool = true

@export_group("Suflu")
## Raza (m) in care figurantul IMPINGE masinile din jur — hovercraftul de pe
## Baikal (docs/track_briefs/baikal.md §3): jetul elicei si perna de aer
## arunca zapada si masinile deoparte. 0 = figurant obisnuit, nu impinge.
##
## Nu e o coliziune (aia exista oricum, pe corp): e o zona in jurul corpului
## in care masinile primesc o acceleratie DINSPRE figurant, care scade liniar
## cu distanta. Pe gheata, cu grip 1.5, iti muta linia; pe asfalt abia se
## simte — asa trebuie: hazardul e al lacului, nu al pistei.
@export_range(0.0, 20.0, 0.5) var push_radius: float = 0.0
## Acceleratia la contact (m/s^2), scade la zero la marginea razei.
@export_range(0.0, 40.0, 0.5) var push_accel: float = 12.0
## Jetul de zapada din spate (particule), aprins cat timp se misca.
@export var plume: bool = false

@export_group("Leganare")
## Miscarea CORPULUI pe traiectorie e rigida; astea doua dau viata modelului:
## saltare pe verticala (barca pe valuri) si ruliu in jurul axei de mers
## (tractor pe drum de tara). Amandoua pe pivotul vizual, NU pe corpul de
## coliziune — cutia de lovire nu are voie sa respire.
@export_range(0.0, 0.5, 0.01) var bob_amplitude: float = 0.0
@export_range(0.0, 0.2, 0.005) var rock_amplitude: float = 0.0
@export_range(0.1, 4.0, 0.05) var sway_frequency: float = 0.9

var _body: AnimatableBody3D
var _pivot: Node3D
var _push_area: Area3D
var _plume: CPUParticles3D
var _pivot_rest_y: float = 0.0
var _dist: float = 0.0
var _dir: float = 1.0
var _yaw: float = 0.0
var _time: float = 0.0
var _started: bool = false


## Dropdown-ul de la `animation`: sugestii citite din modelul ales (o
## instantiere scurta, doar in editor). ENUM_SUGGESTION, nu ENUM: campul
## ramane text liber, deci gol = automat si un GLB fara animatii nu-l strica.
func _validate_property(property: Dictionary) -> void:
	if property.name != "animation" or not Engine.is_editor_hint():
		return
	var names := _model_animation_names()
	if names.is_empty():
		return
	property.hint = PROPERTY_HINT_ENUM_SUGGESTION
	property.hint_string = ",".join(names)


func _model_animation_names() -> PackedStringArray:
	var out := PackedStringArray()
	if model == null:
		return out
	var inst := model.instantiate() as Node3D
	if inst == null:
		return out
	for ap in inst.find_children("*", "AnimationPlayer", true, false):
		out.append_array((ap as AnimationPlayer).get_animation_list())
	inst.free()
	return out


func _ready() -> void:
	_build_body()


## Corpul si infatisarea, o singura data. Copiii nu primesc owner, deci in
## editor nu se salveaza in .tscn — scena pastreaza doar declaratia (curba +
## exporturi), iar corpul se reconstruieste la fiecare deschidere.
func _build_body() -> void:
	_body = AnimatableBody3D.new()
	_body.sync_to_physics = true
	add_child(_body)
	_pivot = Node3D.new()
	_body.add_child(_pivot)
	if model != null:
		_build_model()
	else:
		_build_placeholder()
	if push_radius > 0.0:
		_build_push()


## Zona de suflu + jetul de zapada. Vezi `push_radius`.
func _build_push() -> void:
	_push_area = Area3D.new()
	_push_area.name = "Push"
	_push_area.monitoring = true
	_push_area.monitorable = false
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = push_radius
	shape.shape = sph
	shape.position = Vector3.UP * 1.0
	_push_area.add_child(shape)
	_body.add_child(_push_area)
	if not plume:
		return
	# Jetul: fulgi de zapada aruncati in spate (+Z local = spatele, modelul
	# merge cu -Z inainte), putin in sus, cu gravitatie mica. Cutii mici
	# nemodulate de lumina, ca stropii furtunului — acelasi tipar ieftin.
	_plume = CPUParticles3D.new()
	_plume.name = "Plume"
	_plume.position = Vector3(0.0, 1.2, 2.5)
	_plume.direction = Vector3(0, 0.35, 1)
	_plume.spread = 22.0
	_plume.initial_velocity_min = 9.0
	_plume.initial_velocity_max = 14.0
	_plume.gravity = Vector3(0, -3.0, 0)
	_plume.amount = 60
	_plume.lifetime = 1.3
	_plume.emitting = false
	var flake := BoxMesh.new()
	flake.size = Vector3(0.28, 0.28, 0.28)
	var flake_mat := StandardMaterial3D.new()
	flake_mat.vertex_color_use_as_albedo = true
	flake_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake.material = flake_mat
	_plume.mesh = flake
	_plume.color = Color(0.94, 0.97, 1.0)
	_pivot.add_child(_plume)


func _build_model() -> void:
	var inst := _extract_node(model, model_node)
	if inst == null:
		_build_placeholder()
		return
	inst.scale = Vector3.ONE * model_scale
	inst.rotation.y = deg_to_rad(model_yaw)
	_pivot.add_child(inst)
	if tri_class.is_empty():
		Palette.apply_world_material(inst)
	else:
		Palette.apply_object_triplanar_class(inst, tri_class, model_scale)
	_autoplay_animation(inst)
	# Cutia de coliziune se MASOARA pe model (tiparul din sliding_hazard):
	# scrisa de mana, ar ramane in urma la primul model schimbat din Inspector.
	var box := Track.model_aabb(inst)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	if box.size.length() > 0.3:
		col.size = box.size
		shape.position = box.position + box.size * 0.5
	else:
		col.size = PLACEHOLDER_SIZE
		shape.position = Vector3.UP * (PLACEHOLDER_SIZE.y * 0.5)
	shape.shape = col
	_body.add_child(shape)


func _build_placeholder() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = PLACEHOLDER_SIZE
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.15)
	mesh.material_override = mat
	mesh.position = Vector3.UP * (PLACEHOLDER_SIZE.y * 0.5)
	_pivot.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = PLACEHOLDER_SIZE
	shape.shape = col
	shape.position = Vector3.UP * (PLACEHOLDER_SIZE.y * 0.5)
	_body.add_child(shape)


## Instantiaza GLB-ul si pastreaza o singura piesa, anuland offsetul ei din
## fisier — acelasi tipar ca TrainHazard._extract / HazardMarker.model_node.
## `remove_child` inainte de `queue_free`, ca piesele aruncate sa nu mai intre
## in masuratoarea AABB de imediat dupa.
func _extract_node(scene: PackedScene, node_name: String) -> Node3D:
	var container := scene.instantiate() as Node3D
	if container == null:
		return null
	if node_name.is_empty():
		return container
	var kept: Node3D = null
	for child in container.get_children():
		if String(child.name) == node_name:
			kept = child as Node3D
		else:
			container.remove_child(child)
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


## Daca modelul vine cu schelet si animatii (ciclu de mers exportat din
## Blender), porneste-l in bucla: un animal care aluneca cu picioarele
## teapene nu e ambient, e defect vizibil. Clipul il alege `animation`; gol =
## automat, dupa viteza. Potrivirea e fara majuscule/minuscule: primul GLB
## animat (vaca Quaternius) are "Walk", iar cautarea dupa "walk" cadea pe
## primul clip alfabetic — "Eating" — si vaca traversa drumul pascand.
const AUTO_WALK := ["walk", "run", "gallop", "swim", "fly", "move"]
const AUTO_REST := ["idle", "eating", "rest", "stand"]

func _autoplay_animation(root: Node3D) -> void:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var ap := players[0] as AnimationPlayer
	var names := ap.get_animation_list()
	if names.is_empty():
		return
	var pick := ""
	if not animation.is_empty():
		if ap.has_animation(animation):
			pick = animation
		else:
			push_warning("PathMover '%s': animatia '%s' nu exista in model (are: %s); cad pe automat"
				% [name, animation, ", ".join(names)])
	if pick.is_empty():
		pick = _pick_by_name(names, AUTO_WALK if speed > 0.0 else AUTO_REST)
	if pick.is_empty():
		pick = String(names[0])
	var anim := ap.get_animation(pick)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	ap.speed_scale = animation_speed
	ap.play(pick)


## Primul clip al carui nume contine (fara majuscule) unul din cuvintele date,
## in ordinea cuvintelor. Gol daca niciunul.
func _pick_by_name(names: PackedStringArray, words: Array) -> String:
	for w: String in words:
		for n in names:
			if String(n).to_lower().contains(w):
				return String(n)
	return ""


func _physics_process(delta: float) -> void:
	if _body == null or curve == null:
		return
	var length := curve.get_baked_length()
	if length < 0.5:
		return
	# Faza se aplica la primul tick, nu in _ready: cand nodul e construit din
	# cod, exporturile se seteaza DUPA add_child (lectia din SlidingHazard).
	if not _started:
		_started = true
		_dist = phase * length
	_time += delta
	_advance(delta, length)

	var pos := to_global(curve.sample_baked(_dist, true))
	var target_yaw := _travel_yaw(length, pos)
	_yaw = lerp_angle(_yaw, target_yaw, minf(TURN_RATE * delta, 1.0))
	if stick_to_ground:
		pos.y = _ground_y(pos)
	# O SINGURA scriere de transform, nu pozitie + rotatie separat: cu
	# sync_to_physics sub Jolt, a doua scriere recompune transformul dintr-o
	# citire sincronizata de fizica (inca veche) si o sterge pe prima — corpul
	# ramane teapan la origine. Masurat cu un experiment izolat (aug 2026):
	# pozitia singura sau transformul intreg merg, perechea de scrieri nu.
	_body.global_transform = Transform3D(Basis(Vector3.UP, _yaw), pos)
	_apply_sway()
	_apply_push()


## Impinge masinile din raza de suflu, dinspre corp spre ele. Doar cu rotile
## pe sol e treaba masinii sa decida (apply_central_force nu are efect vizibil
## in aer oricum, si un hovercraft nu zboara masini).
func _apply_push() -> void:
	if _push_area == null or Engine.is_editor_hint():
		return
	if _plume != null:
		_plume.emitting = speed > 0.5
	var origin := _body.global_position
	for b in _push_area.get_overlapping_bodies():
		var car := b as Car
		if car == null:
			continue
		var away := car.global_position - origin
		away.y = 0.0
		var d := away.length()
		if d < 0.3 or d > push_radius:
			continue
		var k := 1.0 - d / push_radius
		car.apply_central_force(away / d * push_accel * k * car.mass)


func _advance(delta: float, length: float) -> void:
	_dist += speed * delta * _dir
	if travel_mode == TravelMode.BUCLA:
		_dist = fposmod(_dist, length)
		return
	if _dist >= length:
		_dist = length
		_dir = -1.0
	elif _dist <= 0.0:
		_dist = 0.0
		_dir = 1.0


## Incotro merge, ca yaw global. Directia se ia dintr-un esantion PUTIN mai in
## fata pe sensul de mers — derivata analitica a curbei nu tine cont de sens,
## si un dus-intors ar merge jumatate de drum cu spatele.
func _travel_yaw(length: float, pos: Vector3) -> float:
	var ahead_dist := _dist + 0.6 * _dir
	if travel_mode == TravelMode.BUCLA:
		ahead_dist = fposmod(ahead_dist, length)
	else:
		ahead_dist = clampf(ahead_dist, 0.0, length)
	var ahead := to_global(curve.sample_baked(ahead_dist, true))
	var t := ahead - pos
	t.y = 0.0
	if t.length_squared() < 0.0001:
		return _yaw # parcat sau fix in capatul cursei: pastreaza orientarea
	return atan2(-t.x, -t.z)


## Cota terenului sub punctul de pe curba. Fara teren sub raza (curba trasa
## peste o rapa, decor inca negenerat in editor), ramane cota curbei — mai
## bine un figurant plutind vizibil decat unul teleportat la -40.
func _ground_y(pos: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return pos.y
	var query := PhysicsRayQueryParameters3D.create(
		pos + Vector3.UP * GROUND_PROBE_UP,
		pos - Vector3.UP * GROUND_PROBE_DOWN,
		0xFFFFFFFF, [_body.get_rid()])
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return pos.y
	return (hit["position"] as Vector3).y


func _apply_sway() -> void:
	if bob_amplitude <= 0.0 and rock_amplitude <= 0.0:
		return
	var w := _time * TAU * sway_frequency
	_pivot.position.y = _pivot_rest_y + sin(w) * bob_amplitude
	# Doua frecvente decalate, ca la SwayDriver: o singura sinusoida pe o
	# singura axa citeste ca metronom, nu ca leganare.
	_pivot.rotation.z = sin(w * 0.83) * rock_amplitude
	_pivot.rotation.x = cos(w * 0.61) * rock_amplitude * 0.5


## Corpul fizic, pentru sonde (tools/probe_path_mover.gd) — expus printr-o
## functie, ca la SwayDriver.tracked_instances: interiorul e detaliu de
## implementare.
func body() -> AnimatableBody3D:
	return _body
