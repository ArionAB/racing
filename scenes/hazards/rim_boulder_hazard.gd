@tool
class_name RimBoulderHazard
extends Node3D
## BOLOVANUL DE PE BUZA (Monument Valley, Track19, trecatoarea E): un bolovan
## care CADE de sus, de pe creasta peretelui, pe o banda a culoarului si te
## striveste. Spre deosebire de [RockfallHazard] (care se rostogoleste pe un
## traseu pe sol sau cade pe ciclul scurt de 5,5 s si ramane o clipa solid pe
## drum), aici caderea e libera, pe un ceas lung si propriu, iar dupa impact
## piatra se sparge: NU ramane niciun obstacol pe banda.
##
## [b]Strivirea inverseaza directia[/b]: `Car.crush(..., invert_steer = true)` —
## stanga <-> dreapta cat tine strivirea (`crush_seconds`). Inversarea e in Car,
## deci o simte si AI-ul. Restul hazardelor cu crush nu o activeaza.
##
## [b]Ceas determinist, fara zar[/b] (un hazard care se poate invata e o decizie,
## unul care surprinde e o taxa). Perioada (19 s) NU imparte durata turului (~70
## s), ca bolovanul sa nu cada mereu in acelasi loc al plutonului. Ciclul porneste
## in LINISTE (memoria `ceasul-porneste-in-prima-faza`): intai `idle`, abia apoi
## telegraful — la t=0 al cursei nu exista nicio piatra, nicio umbra, niciun praf.
##
##   idle -> telegraf (1.4 s) -> cadere (~1 s) -> impact (0.35 s activ) -> se sparge
##
## [b]Telegraful[/b]: pietricele si praf care curg de pe buza (CPUParticles3D) si
## umbra de pe asfalt care CRESTE pana la raza de impact — le vezi cu >1 s inainte.
##
## [b]Geometrie[/b]: nodul sta pe asfalt, in PUNCTUL DE IMPACT, cu +X local spre
## peretele de pe care cade piatra (`rim_offset` = cat de departe, lateral, e
## creasta; `rim_height` = cat de sus fata de asfalt). Piatra pleaca de pe creasta
## cu o viteza laterala spre drum, ca sa NU treaca prin fata peretelui.
##
## Nu are corp solid (doar [Area3D]): un corp cinematic aparut intr-o masina o
## azvarle (memoria `corp-cinematic-aparut-in-masina`); strivirea o da `crush`.

const DEFAULT_MODEL := "res://assets/models/rocks/boulder_roller.glb"
const DEFAULT_MODEL_SCALE: float = 0.5
const ROCK_RADIUS: float = 1.25
const IMPACT_MARGIN: float = 0.95
## Gravitatia caderii (m/s^2): mai mare decat cea reala, ca sa cada hotarat.
const FALL_GRAVITY: float = 22.0
## Cat mai e activa zona de impact dupa aterizare, apoi piatra se sparge.
const HOLD_AFTER_LAND: float = 0.35
const CRUMBLE_TIME: float = 0.3
const HIT_COOLDOWN: float = 1.0
## Cat de puternic e shake-ul la lovitura nu e aici (il da `crushed`, ca la restul).

const CRUSH_SECONDS: float = 1.75
const CRUSH_FACTOR: float = 0.70
const CRUSH_KEEP_SPEED: float = 0.55
const CRUSH_SQUASH := Vector3(1.55, 0.245, 1.45)

@export_group("Ciclu")
## Perioada (s). Nu divizor al turului de ~70 s.
@export_range(5.0, 120.0, 0.5) var period: float = 19.0
## Telegraful (s): praf + umbra care creste, inainte sa cada.
@export_range(0.4, 4.0, 0.1) var telegraph_time: float = 1.4
## Unde in ciclu (s) incepe ceasul. 0 = in `idle`, linistea de dinaintea telegrafului.
@export_range(0.0, 120.0, 0.1) var start_clock: float = 0.0
## >= 0: ceasul e FIX (snapshot/sonde); nu mai avanseaza.
var force_clock: float = -1.0

@export_group("Geometrie")
## Distanta laterala (+X local) de la punctul de impact la creasta peretelui (m).
@export_range(2.0, 30.0, 0.1) var rim_offset: float = 7.2
## Inaltimea crestei fata de asfalt (m).
@export_range(3.0, 40.0, 0.1) var rim_height: float = 11.0
## Lungimea fronturii de praf pe creasta (m), de-a lungul drumului.
@export_range(0.5, 10.0, 0.1) var rim_spread: float = 2.4

@export_group("Efect")
@export_range(0.5, 4.0, 0.05) var crush_seconds: float = CRUSH_SECONDS
@export_range(0.3, 1.0, 0.01) var crush_factor: float = CRUSH_FACTOR
## Inverseaza directia pe durata strivirii. Stins doar pentru sonde (sabotaj).
@export var invert_steer: bool = true

var _rock: Node3D
var _pivot: Node3D
var _shadow: MeshInstance3D
var _impact: Area3D
var _rim_dust: CPUParticles3D
var _puff: CPUParticles3D
var _audio: AudioStreamPlayer3D
var _time: float = 0.0
var _radius: float = ROCK_RADIUS
var _last_phase: int = -1
var _cooldown: Dictionary = {}
var _spin_axis: Vector3 = Vector3(0.0, 0.0, 1.0)
## Cate impacturi (masini lovite) a facut, pentru sonde.
var hits: int = 0

static var _shadow_mat: StandardMaterial3D
static var _dust_mat: StandardMaterial3D

enum Phase { IDLE, TELEGRAPH, FALL, HOLD, CRUMBLE }


func _ready() -> void:
	_build()
	_time = fposmod(start_clock, period)
	if force_clock >= 0.0:
		_time = force_clock
	_apply(_time)


## Cat dureaza caderea libera, din inaltime si gravitatie.
func fall_time() -> float:
	return sqrt(2.0 * (rim_height + _radius * 0.8) / FALL_GRAVITY)


## Lungimea partii active a ciclului (telegraf + cadere + tinere + spargere).
func active_length() -> float:
	return telegraph_time + fall_time() + HOLD_AFTER_LAND + CRUMBLE_TIME


## Cand incepe telegraful in ciclu (restul de dinainte e linistea).
func telegraph_start() -> float:
	return maxf(period - active_length(), 0.0)


## Momentul (in ciclu) in care piatra atinge asfaltul.
func landing_time() -> float:
	return telegraph_start() + telegraph_time + fall_time()


func phase_at(t: float) -> int:
	var t0 := telegraph_start()
	if t < t0:
		return Phase.IDLE
	if t < t0 + telegraph_time:
		return Phase.TELEGRAPH
	if t < landing_time():
		return Phase.FALL
	if t < landing_time() + HOLD_AFTER_LAND:
		return Phase.HOLD
	return Phase.CRUMBLE


## Pozitia LOCALA a centrului pietrei la momentul `t` din ciclu (doar in cadere).
## Pe X: porneste de pe creasta si merge spre punctul de impact cu viteza laterala
## constanta; pe Y: cadere libera.
func rock_local_at(t: float) -> Vector3:
	var land := landing_time()
	var tf := fall_time()
	var k := clampf((t - (land - tf)) / tf, 0.0, 1.0)
	var x0 := rim_offset + _radius * 0.9
	var y0 := rim_height + _radius * 0.8 # centrul pietrei: o raza si ceva peste creasta
	var x := lerpf(x0, 0.0, k)
	# y: de la y0 (sus) la `_radius` (centrul pe asfalt); k*k = cadere accelerata.
	var y := lerpf(y0, _radius, k * k)
	return Vector3(x, y, 0.0)


func _physics_process(delta: float) -> void:
	if _rock == null:
		return
	if force_clock >= 0.0:
		_time = force_clock
	else:
		_time = fposmod(_time + delta, period)
	_apply(_time)
	if Engine.is_editor_hint():
		return
	for key in _cooldown.keys():
		if not is_instance_valid(key):
			_cooldown.erase(key)
			continue
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0:
			_cooldown.erase(key)
		else:
			_cooldown[key] = left
	var t := _time
	var land := landing_time()
	# Activ: ultima clipa a caderii + cat sta pe asfalt.
	if t >= land - 0.15 and t < land + HOLD_AFTER_LAND:
		_hit_cars()


func _apply(t: float) -> void:
	var ph := phase_at(t)
	var t0 := telegraph_start()
	_rock.visible = ph == Phase.FALL or ph == Phase.HOLD or ph == Phase.CRUMBLE
	_shadow.visible = ph == Phase.TELEGRAPH or ph == Phase.FALL or ph == Phase.HOLD
	_rim_dust.emitting = ph == Phase.TELEGRAPH or (ph == Phase.FALL and t < t0 + telegraph_time + 0.35)
	match ph:
		Phase.TELEGRAPH:
			var k := clampf((t - t0) / telegraph_time, 0.0, 1.0)
			_shadow.scale = Vector3.ONE * lerpf(0.15, 1.0, k)
		Phase.FALL:
			_shadow.scale = Vector3.ONE
			_rock.position = rock_local_at(t)
			_rock.scale = Vector3.ONE
			var tf := fall_time()
			var k2 := clampf((t - (landing_time() - tf)) / tf, 0.0, 1.0)
			_pivot.rotation = _spin_axis * (k2 * 7.0)
		Phase.HOLD:
			_rock.position = Vector3(0.0, _radius, 0.0)
			_rock.scale = Vector3.ONE
		Phase.CRUMBLE:
			var kc := clampf((t - landing_time() - HOLD_AFTER_LAND) / CRUMBLE_TIME, 0.0, 1.0)
			_rock.position = Vector3(0.0, _radius * (1.0 - 0.5 * kc), 0.0)
			_rock.scale = Vector3.ONE * (1.0 - kc)
			_rock.visible = kc < 0.98
	_impact.position = Vector3(0.0, _radius, 0.0) if ph == Phase.HOLD \
		else (rock_local_at(t) if ph == Phase.FALL else Vector3(0.0, -50.0, 0.0))
	if ph != _last_phase:
		_on_phase_enter(ph)
		_last_phase = ph


func _on_phase_enter(ph: int) -> void:
	if Engine.is_editor_hint():
		return
	match ph:
		Phase.TELEGRAPH:
			_play(&"rock_warn")
		Phase.HOLD:
			_play(&"rock_impact")
			_puff.restart()
			_puff.emitting = true


func _play(sfx: StringName) -> void:
	var stream := AudioManager.stream(sfx)
	if stream == null or _audio == null:
		return
	_audio.stream = stream
	_audio.play()


func _hit_cars() -> void:
	for body in _impact.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = HIT_COOLDOWN
		hits += 1
		car.crush(crush_seconds, crush_factor, CRUSH_SQUASH, CRUSH_KEEP_SPEED,
			true, invert_steer)
		# Impinsa in jos: turtirea trebuie sa se si SIMTA, nu doar sa se vada.
		car.velocity.y = -6.0


func _build() -> void:
	_shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.height = 0.04
	disc.radial_segments = 14
	disc.rings = 1
	_shadow.mesh = disc
	if _shadow_mat == null:
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.albedo_color = Color(0.05, 0.03, 0.02, 0.55)
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_shadow.material_override = _shadow_mat
	_shadow.position = Vector3.UP * 0.07
	_shadow.visible = false
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)

	_rock = Node3D.new()
	add_child(_rock)
	_pivot = Node3D.new()
	_rock.add_child(_pivot)
	var model := _rock_model()
	if model != null:
		_pivot.add_child(model)
		var box := Track.model_aabb(model)
		if box.size.length() > 0.02:
			model.position -= box.get_center()
			_radius = maxf(box.size.x, box.size.z) * 0.5
	_rock.visible = false

	disc.top_radius = _radius + IMPACT_MARGIN
	disc.bottom_radius = disc.top_radius

	_impact = Area3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = _radius + IMPACT_MARGIN
	shape.shape = sphere
	_impact.add_child(shape)
	_impact.position = Vector3(0.0, -50.0, 0.0)
	add_child(_impact)

	if _dust_mat == null:
		_dust_mat = StandardMaterial3D.new()
		_dust_mat.albedo_color = Color(0.78, 0.55, 0.38)
		_dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var bit := BoxMesh.new()
	bit.size = Vector3(0.16, 0.16, 0.16)

	# Pietricele si praf care curg de pe creasta: avertismentul vizibil de la distanta.
	_rim_dust = CPUParticles3D.new()
	_rim_dust.mesh = bit
	_rim_dust.material_override = _dust_mat
	_rim_dust.amount = 28
	_rim_dust.lifetime = 1.1
	_rim_dust.local_coords = false
	_rim_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rim_dust.emission_box_extents = Vector3(0.5, 0.1, rim_spread * 0.5)
	_rim_dust.direction = Vector3(-0.35, -1.0, 0.0)
	_rim_dust.spread = 18.0
	_rim_dust.initial_velocity_min = 0.6
	_rim_dust.initial_velocity_max = 2.2
	_rim_dust.gravity = Vector3(0.0, -9.0, 0.0)
	_rim_dust.scale_amount_min = 0.5
	_rim_dust.scale_amount_max = 1.6
	_rim_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rim_dust.position = Vector3(rim_offset + 0.3, rim_height - 0.7, 0.0)
	_rim_dust.emitting = false
	add_child(_rim_dust)

	# Norul de la impact: o singura explozie.
	_puff = CPUParticles3D.new()
	_puff.mesh = bit
	_puff.material_override = _dust_mat
	_puff.amount = 20
	_puff.lifetime = 0.8
	_puff.one_shot = true
	_puff.explosiveness = 1.0
	_puff.local_coords = false
	_puff.direction = Vector3.UP
	_puff.spread = 70.0
	_puff.initial_velocity_min = 3.0
	_puff.initial_velocity_max = 7.0
	_puff.gravity = Vector3(0.0, -9.0, 0.0)
	_puff.scale_amount_min = 0.8
	_puff.scale_amount_max = 2.2
	_puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_puff.position = Vector3(0.0, 0.4, 0.0)
	_puff.emitting = false
	add_child(_puff)

	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 80.0
	add_child(_audio)


func _rock_model() -> Node3D:
	if not ResourceLoader.exists(DEFAULT_MODEL):
		var fallback := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = ROCK_RADIUS
		mesh.height = ROCK_RADIUS * 2.0
		mesh.radial_segments = 10
		mesh.rings = 5
		fallback.mesh = mesh
		return fallback
	var container := (load(DEFAULT_MODEL) as PackedScene).instantiate() as Node3D
	container.scale = Vector3.ONE * DEFAULT_MODEL_SCALE
	# Roca lumii (gresia canionului), in spatiul OBIECTULUI: piatra se invarte.
	var tri := _world_rock_class()
	if tri.is_empty():
		Palette.apply_object_class_materials(container, WorldProp.prop_classes(),
			DEFAULT_MODEL_SCALE)
	else:
		Palette.apply_object_triplanar_class(container, tri, DEFAULT_MODEL_SCALE)
	return container


func _world_rock_class() -> String:
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			return String((n as Track).theme_flag("rockfall_class",
				(n as Track).theme_flag("rock_class", "")))
		n = n.get_parent()
	return ""
