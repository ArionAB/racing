class_name Car
extends CharacterBody3D
## Masina arcade 3D — doar fizica; comenzile vin de la un CarController
## (player sau AI), identitatea (statistici/culoare) dintr-un CarData.
##
## Fizica: viteza descompusa in "inainte" + "lateral" fata de directia
## masinii; grip-ul amortizeaza lateralul, drift-ul il lasa sa alunece.
## Gravitatia si pantele raman in grija lui move_and_slide().
##
## Turbo model Ignition: o bara care se incarca in timp (mai repede in
## drift) si pe care o arzi CAND VREI TU tinand butonul de turbo — skill de
## decizie (pe ce dreapta, inaintea carei sarituri), nu de timing la viraj.
## Drift-ul e handbrake pur: unealta de viraj care hraneste bara mai repede.

signal boost_started(car: Car)
signal wall_hit(car: Car, impact: float)
signal landed(car: Car, fall_speed: float)

# --- Statistici (suprascrise de CarData la apply_data) ---
@export_group("Motor")
@export var max_speed: float = 34.0
@export var acceleration: float = 16.0
@export var brake_force: float = 30.0
@export var reverse_speed: float = 10.0
## Atentie la echilibru: viteza maxima reala = min(max_speed, acceleration/drag).
## Drag-ul trebuie tinut destul de mic incat plafonul max_speed sa conduca.
@export var drag: float = 0.35

@export_group("Directie")
@export var steer_speed: float = 1.9
@export var grip: float = 8.0

@export_group("Drift (handbrake)")
@export var drift_grip: float = 2.0
@export var drift_steer_bonus: float = 1.5
@export var drift_bias: float = 0.4
@export var drift_min_speed: float = 9.0

@export_group("Turbo (model Ignition)")
## Secunde pana la umplerea barii doar din mers.
@export var turbo_fill_time: float = 10.0
## In drift bara se umple de atatea ori mai repede — driftul ramane rasplatit.
@export var turbo_drift_multiplier: float = 2.5
## Secunde de ardere continua de la bara plina.
@export var turbo_burn_time: float = 2.2
## Sub pragul asta nu poti porni turbo (previne "sputter"-ul din taste scurte).
@export var turbo_min_to_fire: float = 0.15
@export var turbo_speed_bonus: float = 11.0 # m/s peste plafon cat arde
## Impins suplimentar cat arde turbo — fara el, drag-ul ar anula boost-ul.
@export var turbo_accel_bonus: float = 10.0

@export_group("Diverse")
@export var gravity: float = 28.0
@export var body_color: Color = Color(0.95, 0.45, 0.1)
@export var mass_factor: float = 1.0
@export var offroad_speed_factor: float = 0.45

# --- Stare de cursa (scrisa de Race) ---
var race_active: bool = false
var finished: bool = false
var race_position: int = 1
var is_player: bool = false
var speed_scale: float = 1.0 # variatia onesta a AI (0.88..0.97), 1.0 la player

var car_name: String = "?"
var pilot_name: String = "?" # numele "pilotului", stabil intre curse
var controller: CarController
var track: Track
var road_index: int = 0
var start_transform: Transform3D

# --- Drift/turbo ---
var is_drifting: bool = false
var drift_dir: float = 0.0
var turbo_charge: float = 0.0 # 0..1, bara din UI
var is_boosting: bool = false
var _forced_boost: float = 0.0 # rocket start: ardere gratuita, nu goleste bara

## Nodul (din Race) sub care se depun urmele de cauciuc.
var skid_parent: Node3D

var _visual: Node3D
var _drift_particles: CPUParticles3D
var _boost_particles: CPUParticles3D
var _engine_audio: AudioStreamPlayer3D
var _skid_audio: AudioStreamPlayer3D
var _turbo_full_latch: bool = false
var _was_on_floor: bool = true
var _prev_velocity: Vector3 = Vector3.ZERO
var _wall_cooldown: float = 0.0
var _bump_cooldown: float = 0.0
var _skid_accum: float = 0.0

# Resurse partajate intre toate urmele de cauciuc (ieftin la instantiere).
static var _skid_mesh: PlaneMesh
static var _skid_mat: StandardMaterial3D

func _ready() -> void:
	floor_snap_length = 2.0 # tine masina lipita de asfalt peste creste
	_build_visual()
	_build_effects()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	shape.shape = box
	shape.position = Vector3(0, 0.6, 0)
	add_child(shape)
	start_transform = global_transform

func set_controller(new_controller: CarController) -> void:
	controller = new_controller
	add_child(new_controller)
	new_controller.setup(self)

func apply_data(data: CarData, color_override: Color = Color(0, 0, 0, 0)) -> void:
	car_name = data.display_name
	max_speed = data.max_speed
	acceleration = data.acceleration
	grip = data.grip
	mass_factor = data.mass_factor
	body_color = data.color if color_override.a == 0.0 else color_override
	if _visual != null:
		_visual.queue_free()
	_build_visual()

func _physics_process(delta: float) -> void:
	if track != null:
		road_index = track.closest_index(road_index, global_position)

	var steer := 0.0
	var throttle := 0.0
	var drift_pressed := false
	var turbo_pressed := false
	if controller != null and race_active and not finished:
		controller.update(delta)
		steer = clampf(controller.get_steer(), -1.0, 1.0)
		throttle = clampf(controller.get_throttle(), -1.0, 1.0)
		drift_pressed = controller.is_drift_pressed()
		turbo_pressed = controller.is_turbo_pressed()

	velocity.y -= gravity * delta

	var forward := -global_transform.basis.z
	var fwd_h := Vector3(forward.x, 0.0, forward.z).normalized()
	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	var fwd_speed := hvel.dot(fwd_h)

	_update_drift(drift_pressed, steer, fwd_speed)
	_update_turbo(turbo_pressed, delta)

	# --- Motor / frana ---
	var vmax := _current_max_speed()
	if throttle > 0.0 and fwd_speed < vmax:
		var accel := acceleration
		if is_boosting:
			accel += turbo_accel_bonus
		hvel += fwd_h * accel * throttle * delta
	elif throttle < 0.0:
		if fwd_speed > 2.0:
			hvel += fwd_h * brake_force * throttle * delta
		elif fwd_speed > -reverse_speed:
			hvel += fwd_h * acceleration * 0.6 * throttle * delta
	hvel -= hvel * drag * delta

	# --- Directie (amplificata si "impinsa" in directia drift-ului) ---
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var effective_steer := steer
	if is_drifting:
		effective_steer = clampf(
			steer * drift_steer_bonus + drift_dir * drift_bias, -1.6, 1.6)
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	rotate_y(effective_steer * steer_speed * speed_frac * reverse_sign * delta)

	# --- Grip lateral pe noua directie ---
	forward = -global_transform.basis.z
	fwd_h = Vector3(forward.x, 0.0, forward.z).normalized()
	fwd_speed = hvel.dot(fwd_h)
	var lateral := hvel - fwd_h * fwd_speed
	lateral *= exp(-(drift_grip if is_drifting else grip) * delta)
	if fwd_speed > vmax:
		fwd_speed = move_toward(fwd_speed, vmax, 12.0 * delta)
	hvel = fwd_h * fwd_speed + lateral

	velocity.x = hvel.x
	velocity.z = hvel.z
	_prev_velocity = velocity
	move_and_slide()
	_handle_bumping()
	_detect_landing()
	_update_visual_tilt(delta, steer, fwd_speed)
	_update_effects(delta)
	_wall_cooldown = maxf(_wall_cooldown - delta, 0.0)
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)

## Plafonul de viteza al momentului: taiat de iarba, ridicat de turbo.
## Turbo-ul merge SI pe iarba — scurtatura cu turbo e o alegere valida.
func _current_max_speed() -> float:
	var vmax := max_speed * speed_scale
	if track != null and not track.is_on_road(road_index, global_position):
		vmax *= offroad_speed_factor
	if is_boosting:
		vmax += turbo_speed_bonus
	return vmax

# ------------------------------------------------------------------- drift

## Handbrake pur: alunecare controlata pentru viraje, fara boost la iesire.
func _update_drift(drift_pressed: bool, steer: float, fwd_speed: float) -> void:
	if not is_drifting:
		if drift_pressed and fwd_speed > drift_min_speed and absf(steer) > 0.25:
			is_drifting = true
			drift_dir = signf(steer)
			if is_player:
				AudioManager.play_sfx(&"drift_start")
	elif not drift_pressed or fwd_speed < drift_min_speed * 0.55:
		is_drifting = false

# ------------------------------------------------------------------- turbo

func _update_turbo(turbo_pressed: bool, delta: float) -> void:
	_forced_boost = maxf(_forced_boost - delta, 0.0)
	# Poti PORNI turbo doar cu bara peste prag; odata pornit, arzi pana la 0.
	var can_fire := turbo_charge > (0.02 if is_boosting else turbo_min_to_fire)
	if turbo_pressed and can_fire:
		if not is_boosting:
			_start_boost()
		turbo_charge = maxf(turbo_charge - delta / turbo_burn_time, 0.0)
		is_boosting = true
	else:
		is_boosting = _forced_boost > 0.0
		# Bara se umple din mers; drift-ul o hraneste mult mai repede.
		var fill := delta / turbo_fill_time
		if is_drifting:
			fill *= turbo_drift_multiplier
		turbo_charge = minf(turbo_charge + fill, 1.0)

func _start_boost() -> void:
	var forward := -global_transform.basis.z
	velocity += Vector3(forward.x, 0.0, forward.z).normalized() * 4.0
	_punch_scale(Vector3(0.85, 0.9, 1.2))
	boost_started.emit(self)
	if is_player:
		AudioManager.play_sfx(&"boost")

func grant_turbo(amount: float) -> void:
	turbo_charge = clampf(turbo_charge + amount, 0.0, 1.0)

## Ardere gratuita (rocket start): boost fara sa goleasca bara.
func force_boost(seconds: float) -> void:
	_forced_boost = seconds
	is_boosting = true
	_start_boost()

# ------------------------------------------------------------- imbranceli

func _handle_bumping() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider() as Car
		var n := col.get_normal() # dinspre obstacol spre noi
		if other != null:
			n.y = 0.0
			other.velocity += -n * 4.5 * (mass_factor / other.mass_factor)
			velocity += n * 4.5 * (other.mass_factor / mass_factor)
			if _bump_cooldown <= 0.0 and is_player:
				_bump_cooldown = 0.25
				AudioManager.play_sfx(&"bump")
		elif absf(n.y) < 0.5:
			# Obstacol vertical (perete/bariera): impact = viteza "in" perete.
			var impact := maxf(0.0, Vector3(
				_prev_velocity.x, 0.0, _prev_velocity.z).dot(-n))
			if impact > 8.0 and _wall_cooldown <= 0.0:
				_wall_cooldown = 0.35
				wall_hit.emit(self, impact)
				if is_player:
					AudioManager.play_sfx(&"wall_hit")

func _detect_landing() -> void:
	if is_on_floor() and not _was_on_floor and _prev_velocity.y < -6.0:
		landed.emit(self, -_prev_velocity.y)
		_punch_scale(Vector3(1.15, 0.8, 1.15))
		if is_player:
			AudioManager.play_sfx(&"land")
	_was_on_floor = is_on_floor()

# ------------------------------------------------------------------ restul

func reset() -> void:
	global_transform = start_transform
	velocity = Vector3.ZERO
	is_drifting = false
	is_boosting = false
	_forced_boost = 0.0
	if track != null:
		road_index = track.closest_index_global(global_position)

func horizontal_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()

## Squash & stretch: deformare scurta a caroseriei care "vinde" evenimentul.
func _punch_scale(target: Vector3) -> void:
	if _visual == null:
		return
	_visual.scale = target
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_effects(delta: float) -> void:
	if is_drifting:
		_drift_particles.emitting = true
		_drop_skid_marks(delta)
		if not _skid_audio.playing:
			_skid_audio.play()
	else:
		_drift_particles.emitting = false
		if _skid_audio.playing:
			_skid_audio.stop()
	# Ding cand bara de turbo ajunge plina — stii fara sa te uiti in jos.
	if turbo_charge >= 1.0 and not _turbo_full_latch and is_player:
		_turbo_full_latch = true
		AudioManager.play_sfx(&"drift_level", 1.3)
	elif turbo_charge < 0.95:
		_turbo_full_latch = false
	_boost_particles.emitting = is_boosting
	# Pitch de motor variabil: turatia urca cu viteza + salt la turbo.
	var speed_frac := clampf(horizontal_speed() / max_speed, 0.0, 1.2)
	_engine_audio.pitch_scale = lerpf(0.7, 1.9, speed_frac) \
		+ (0.25 if is_boosting else 0.0)

## Urme de cauciuc: placute plate depuse sub rotile din spate in drift.
func _drop_skid_marks(delta: float) -> void:
	if skid_parent == null or not is_on_floor():
		return
	_skid_accum += horizontal_speed() * delta
	if _skid_accum < 1.1:
		return
	_skid_accum = 0.0
	if _skid_mesh == null:
		_skid_mesh = PlaneMesh.new()
		_skid_mesh.size = Vector2(0.4, 1.0)
		_skid_mat = StandardMaterial3D.new()
		_skid_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.4)
		_skid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_skid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_skid_mesh.material = _skid_mat
	for side in [-0.85, 0.85]:
		var mark := MeshInstance3D.new()
		mark.mesh = _skid_mesh
		skid_parent.add_child(mark)
		mark.global_position = global_position \
			+ global_transform.basis.x * side \
			+ global_transform.basis.z * 1.3 + Vector3.UP * 0.06
		mark.rotation.y = rotation.y
		var tw := mark.create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(mark, "transparency", 1.0, 1.5)
		tw.tween_callback(mark.queue_free)
	# Limita de "juice": stergem urmele cele mai vechi.
	while skid_parent.get_child_count() > 160:
		skid_parent.get_child(0).free()

func _build_effects() -> void:
	# Fum de drift, colorat dupa nivelul de boost incarcat.
	_drift_particles = CPUParticles3D.new()
	_drift_particles.position = Vector3(0, 0.4, 1.9) # spatele masinii (+Z)
	_drift_particles.emitting = false
	_drift_particles.amount = 24
	_drift_particles.lifetime = 0.5
	_drift_particles.direction = Vector3(0, 0.4, 1)
	_drift_particles.spread = 30.0
	_drift_particles.initial_velocity_min = 3.0
	_drift_particles.initial_velocity_max = 6.0
	_drift_particles.gravity = Vector3(0, 1.5, 0)
	_drift_particles.scale_amount_min = 0.6
	_drift_particles.scale_amount_max = 1.4
	_drift_particles.color = Color(0.78, 0.78, 0.8) # fum de cauciuc
	var smoke := BoxMesh.new()
	smoke.size = Vector3(0.22, 0.22, 0.22)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.vertex_color_use_as_albedo = true # ia culoarea din particula
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.material = smoke_mat
	_drift_particles.mesh = smoke
	add_child(_drift_particles)

	# Flacara de boost.
	_boost_particles = CPUParticles3D.new()
	_boost_particles.position = Vector3(0, 0.6, 2.0)
	_boost_particles.emitting = false
	_boost_particles.amount = 30
	_boost_particles.lifetime = 0.25
	_boost_particles.direction = Vector3(0, 0, 1)
	_boost_particles.spread = 10.0
	_boost_particles.initial_velocity_min = 10.0
	_boost_particles.initial_velocity_max = 16.0
	_boost_particles.scale_amount_min = 0.4
	_boost_particles.scale_amount_max = 0.9
	_boost_particles.color = Color(1.0, 0.55, 0.1)
	var flame := BoxMesh.new()
	flame.size = Vector3(0.18, 0.18, 0.18)
	var flame_mat := StandardMaterial3D.new()
	flame_mat.vertex_color_use_as_albedo = true
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.material = flame_mat
	_boost_particles.mesh = flame
	add_child(_boost_particles)

	# Motor pozitional: al tau se aude mereu, adversarii cand sunt aproape.
	_engine_audio = AudioStreamPlayer3D.new()
	_engine_audio.stream = AudioManager.ENGINE_LOOP
	_engine_audio.bus = &"Engine"
	_engine_audio.volume_db = -14.0
	_engine_audio.max_distance = 60.0
	add_child(_engine_audio)
	_engine_audio.play()

	# Scrasnet de cauciuc cat tine drift-ul.
	_skid_audio = AudioStreamPlayer3D.new()
	_skid_audio.stream = AudioManager.SKID_LOOP
	_skid_audio.bus = &"SFX"
	_skid_audio.volume_db = -10.0
	_skid_audio.max_distance = 45.0
	add_child(_skid_audio)

func _update_visual_tilt(delta: float, steer: float, fwd_speed: float) -> void:
	var speed_frac := clampf(fwd_speed / max_speed, 0.0, 1.0)
	var target_roll := -steer * 0.09 * speed_frac * (1.6 if is_drifting else 1.0)
	var target_pitch := clampf(-velocity.y * 0.02, -0.15, 0.15) * speed_frac
	_visual.rotation.z = lerpf(_visual.rotation.z, target_roll, 8.0 * delta)
	_visual.rotation.x = lerpf(_visual.rotation.x, target_pitch, 5.0 * delta)

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_add_box(Vector3(2.2, 0.7, 3.6), Vector3(0, 0.55, 0), body_color)
	_add_box(Vector3(1.6, 0.55, 1.7), Vector3(0, 1.1, 0.2), body_color.darkened(0.5))
	_add_box(Vector3(2.3, 0.18, 0.7), Vector3(0, 0.9, 1.85), body_color.darkened(0.25))
	for corner in [Vector3(-1.05, 0.45, -1.2), Vector3(1.05, 0.45, -1.2),
			Vector3(-1.05, 0.45, 1.25), Vector3(1.05, 0.45, 1.25)]:
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.48
		cyl.bottom_radius = 0.48
		cyl.height = 0.42
		wheel.mesh = cyl
		wheel.rotation.z = PI / 2.0
		wheel.position = corner
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1)
		wheel.material_override = mat
		_visual.add_child(wheel)

func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	inst.material_override = mat
	_visual.add_child(inst)
