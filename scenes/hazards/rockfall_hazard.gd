@tool
class_name RockfallHazard
extends Node3D
## Bolovan care se desprinde din faleza si cade pe sosea.
##
## Ruda cu [SlidingHazard], dar cu CICLU in loc de oscilatie: telegraf, cadere,
## asezare, retragere. Cronologia e DETERMINISTA, fara zar la runtime — la fel ca
## la sweeper, un hazard care se poate invata e o decizie, unul care surprinde e
## o taxa. Vezi si comentariul de acolo despre "citibil de departe".
##
## Ocupa O BANDA, nu tot drumul. Blocarea completa e treaba caruselului; aici
## trebuie sa ramana mereu o linie curata, ca sa fie alegere, nu franare.
##
## Pedeapsa e ~2 secunde, nu cursa: Car.crush() taie plafonul de viteza pentru
## putin timp. Nu exista stare de "distrus" in joc si nici nu ne trebuie.

## Cat tine fiecare faza, in secunde.
const TELEGRAPH: float = 1.4
const FALL: float = 0.55
const SETTLE: float = 1.1
## De la ce inaltime cade.
const DROP_HEIGHT: float = 9.0
## Raza formei de coliziune a bolovanului.
const ROCK_RADIUS: float = 1.15
## Raza zonei care detecteaza masina — putin mai mare decat piatra, ca lovitura
## sa se simta cand piatra te atinge, nu doar cand te patrunde.
const IMPACT_RADIUS: float = 2.1
## Cat de des cade. Nu se schimba per instanta; faza da defazarea.
const DEFAULT_PERIOD: float = 5.5
## Cat sta o masina imuna dupa ce a fost lovita.
const HIT_COOLDOWN: float = 0.6

## Efectul strivirii: durata, plafon de viteza, turtire, cat din viteza ramane.
const CRUSH_SECONDS: float = 1.6
const CRUSH_FACTOR: float = 0.55
const CRUSH_KEEP_SPEED: float = 0.30

@export var period: float = DEFAULT_PERIOD
## Defazare 0..1, ca doua bolovanuri sa nu cada la unison.
@export var phase: float = 0.0
## Culoarea umbrei de avertisment.
@export var telegraph_color: Color = Color(0.05, 0.03, 0.02, 0.55)

var _rock: AnimatableBody3D
var _rock_shape: CollisionShape3D
var _telegraph: MeshInstance3D
var _impact: Area3D
var _audio: AudioStreamPlayer3D
var _time: float = 0.0
## Faza precedenta, ca sunetele sa porneasca o singura data la trecere.
var _last_phase: int = -1
var _cooldown: Dictionary = {}

## Materiale STATICE, partajate intre toate instantele.
##
## Fiecare instanta isi facea materialul ei, deci costul crestea liniar cu
## numarul de hazarde — exact regresia pe care o vaneaza garda de draw call-uri.
static var _tele_mat: StandardMaterial3D
static var _rock_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	# Pornim din faza dorita, nu de la zero: altfel toate bolovanurile de pe pista
	# ar cadea simultan in primele secunde ale cursei.
	_time = fposmod(phase, 1.0) * period


func _build() -> void:
	_telegraph = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = IMPACT_RADIUS
	disc.bottom_radius = IMPACT_RADIUS
	disc.height = 0.04
	# Implicit are 64 de laturi. Pentru o pata de umbra e absurd — vezi nota din
	# CLAUDE.md despre primitive lasate la rezolutia implicita.
	disc.radial_segments = 14
	disc.rings = 1
	_telegraph.mesh = disc
	if _tele_mat == null:
		_tele_mat = StandardMaterial3D.new()
		_tele_mat.albedo_color = telegraph_color
		_tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Fara scriere in depth: umbra sta LIPITA de asfalt, nu taie geometria.
		_tele_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_telegraph.material_override = _tele_mat
	_telegraph.position = Vector3.UP * 0.05
	add_child(_telegraph)

	_rock = AnimatableBody3D.new()
	# Ca la celelalte hazarde mobile: fara asta, masina vede un salt de pozitie
	# in loc de o coliziune cu viteza.
	_rock.sync_to_physics = true
	add_child(_rock)
	_rock_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ROCK_RADIUS
	_rock_shape.shape = sphere
	_rock.add_child(_rock_shape)
	var model := _rock_model()
	if model != null:
		_rock.add_child(model)

	_impact = Area3D.new()
	var area_shape := CollisionShape3D.new()
	var area_sphere := SphereShape3D.new()
	area_sphere.radius = IMPACT_RADIUS
	area_shape.shape = area_sphere
	_impact.add_child(area_shape)
	_rock.add_child(_impact)

	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 80.0
	add_child(_audio)


## Bolovanul: cel mai mare cluster din biblioteca, ca sa fie citibil de departe.
## Fara GLB, o sfera cu putine laturi — hazardul trebuie sa functioneze si daca
## lipseste un asset.
func _rock_model() -> Node3D:
	const PATH := "res://assets/models/rocks/rock_cluster.glb"
	if ResourceLoader.exists(PATH):
		var container := (load(PATH) as PackedScene).instantiate() as Node3D
		var kept: Node3D = null
		for child in container.get_children():
			if child.name == "Cluster_L1":
				kept = child
			else:
				child.queue_free()
		if kept != null:
			container.position = -kept.position
			Palette.apply_world_material(container)
			return container
		container.queue_free()
	var fallback := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = ROCK_RADIUS
	mesh.height = ROCK_RADIUS * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	fallback.mesh = mesh
	if _rock_mat == null:
		_rock_mat = StandardMaterial3D.new()
		_rock_mat.albedo_color = Palette.color(Palette.ROCK_DARK)
	fallback.material_override = _rock_mat
	return fallback


func _physics_process(delta: float) -> void:
	if _rock == null:
		return
	_time = fposmod(_time + delta, period)
	var t := _time
	var idx := 0
	if t < TELEGRAPH:
		_phase_telegraph(t)
	elif t < TELEGRAPH + FALL:
		idx = 1
		_phase_fall(t - TELEGRAPH)
	elif t < TELEGRAPH + FALL + SETTLE:
		idx = 2
		_phase_settle()
	else:
		idx = 3
		_phase_retract(t - (TELEGRAPH + FALL + SETTLE))
	if idx != _last_phase:
		_on_phase_enter(idx)
		_last_phase = idx
	if Engine.is_editor_hint():
		return
	# Doar in ultima clipa a caderii si la inceputul asezarii: intre timp piatra e
	# sus sau se retrage, si o lovitura acolo n-ar avea sens vizual.
	var live := (idx == 1 and t - TELEGRAPH > FALL - 0.12) \
		or (idx == 2 and t - TELEGRAPH - FALL < 0.15)
	_tick_cooldowns(delta)
	if live:
		_hit_cars()


func _on_phase_enter(idx: int) -> void:
	if Engine.is_editor_hint():
		return
	match idx:
		0:
			_play(&"rock_warn")
		2:
			_play(&"rock_impact")


func _play(sfx: StringName) -> void:
	var stream := AudioManager.stream(sfx)
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


## Umbra creste pe asfalt: singurul avertisment, si trebuie sa fie lizibil de la
## distanta de franare.
func _phase_telegraph(t: float) -> void:
	var k := clampf(t / TELEGRAPH, 0.0, 1.0)
	_telegraph.visible = true
	_telegraph.scale = Vector3.ONE * lerpf(0.2, 1.0, k)
	_rock.position.y = DROP_HEIGHT
	_rock_shape.disabled = true
	_rock.visible = false


func _phase_fall(t: float) -> void:
	var k := clampf(t / FALL, 0.0, 1.0)
	_rock.visible = true
	_rock_shape.disabled = false
	# Cadere accelerata, nu liniara: k^2 arata a gravitatie.
	_rock.position.y = lerpf(DROP_HEIGHT, ROCK_RADIUS, k * k)
	_telegraph.scale = Vector3.ONE * lerpf(1.0, 0.85, k)


## Piatra sta pe drum ca obstacol SOLID: trebuie ocolita, nu doar evitata la
## momentul caderii. Aici se transforma dintr-un eveniment intr-o alegere de linie.
func _phase_settle() -> void:
	_rock.position.y = ROCK_RADIUS
	_rock_shape.disabled = false
	_telegraph.visible = false


func _phase_retract(t: float) -> void:
	var span := maxf(period - (TELEGRAPH + FALL + SETTLE), 0.001)
	var k := clampf(t / span, 0.0, 1.0)
	_rock.position.y = lerpf(ROCK_RADIUS, DROP_HEIGHT, k)
	_rock_shape.disabled = true
	_rock.visible = k < 0.9
	_telegraph.visible = false


func _tick_cooldowns(delta: float) -> void:
	# Netipat: `for car: Car in` ar ATRIBUI si cheile-masini deja eliberate
	# in variabila tipata, si chiar atribuirea da "previously freed instance"
	# (vezi nota din TyphoonHazard._steer_lofted).
	for key in _cooldown.keys():
		if not is_instance_valid(key):
			_cooldown.erase(key)
			continue
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0:
			_cooldown.erase(key)
		else:
			_cooldown[key] = left


func _hit_cars() -> void:
	for body in _impact.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = HIT_COOLDOWN
		car.crush(CRUSH_SECONDS, CRUSH_FACTOR,
			Vector3(1.35, 0.35, 1.25), CRUSH_KEEP_SPEED)
		# Impinsa in jos: turtirea trebuie sa se si SIMTA, nu doar sa se vada.
		car.velocity.y = -6.0
