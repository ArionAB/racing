class_name RigidCar
extends RigidBody3D
## Masina pe FIZICA INTREAGA (pivotul din #261): un RigidBody3D sprijinit pe
## 4 raycasturi cu arc + amortizor, cate unul per roata. Ruliul, tangajul si
## legănarea peste denivelari IES din fizica — nu mai sunt efecte desenate
## peste un corp care aluneca pe un colizer-cutie, ca la CharacterBody3D.
##
## Ce ramane arcade (deliberat, nu din comoditate):
##   - directia scrie viteza unghiulara pe Y direct, proportional cu input si
##     viteza — un torque "realist" ar fi fost inca un etaj de tuning intre
##     jucator si raspuns, exact ce nu vrem intr-un joc unde virajul trebuie
##     sa asculte;
##   - grip-ul lateral e o forta de amortizare a vitezei laterale (acelasi
##     model exponential ca pe CharacterBody, doar ca exprimat in forte);
##   - plafonul de viteza e o contra-forta peste vmax, echivalentul lui
##     move_toward din vechea fizica.
##
## Ce e nou si chiar fizic: sprijinul. Fiecare colt isi masoara distanta pana
## la sol si impinge in sus cu F = k * compresie - c * viteza_compresie,
## aplicata LA COLT — de aici caroseria care se lasa pe exterior in viraj, isi
## inclina botul pe panta si se leagana pe denivelari, per roata, gratuit.
##
## Comenzile vin dintr-un "creier" cu interfata CarController (get_steer /
## get_throttle / is_drift_pressed / is_turbo_pressed) — pattern-ul separarii
## fizica/input NU se schimba. Aici e tinut duck-typed (Node, nu CarController)
## fiindca ala are `var car: Car` legat de CharacterBody3D; unificarea tipurilor
## e treaba integrarii (#258), nu a nucleului.

## Gravitatia arcade a jocului (m/s²) — aceeasi cifra ca pe CharacterBody.
## Se traduce in gravity_scale fata de gravitatia proiectului in _ready.
const ARCADE_GRAVITY: float = 28.0

# --- Motor (aceleasi cifre de feel ca in car.gd; sursa: CarData mai tarziu) ---
@export_group("Motor")
@export var max_speed: float = 34.0
@export var acceleration: float = 16.0    # m/s² la acceleratie plina
@export var brake_force: float = 30.0
@export var reverse_speed: float = 10.0
## Rezistenta la rulare, doar cu rotile pe sol (lectia din aug 2026: in aer nu
## exista nicio forta orizontala care s-o justifice).
@export var drag: float = 0.35
## Cat de agresiv e tras inapoi peste vmax (m/s²) — echivalentul lui
## move_toward(fwd_speed, vmax, 12*delta) din vechea fizica.
@export var overspeed_pull: float = 12.0

@export_group("Directie")
@export var steer_speed: float = 1.9      # rad/s la volan plin, viteza plina
@export var grip: float = 8.0             # amortizarea vitezei laterale (1/s)

@export_group("Suspensie")
## Cursa arcului in repaus (m). Raza de cast = rest + wheel_radius.
@export var suspension_rest: float = 0.35
## Frecventa naturala a arcului (Hz). 2-3 = masina de strada arcade;
## rigiditatea k se deriva din ea si din masa pe roata, deci tuning-ul nu
## depinde de cat cantareste corpul.
@export var spring_freq: float = 2.5
## Raportul de amortizare (1 = critic). 0.5-0.7 = revii asezat, fara tangaj
## care se stinge in trei balansari.
@export var damping_ratio: float = 0.6
@export var wheel_radius: float = 0.30
## Pozitia rotilor fata de origine (jumatati de ecartament si ampatament).
@export var wheel_x: float = 0.85
@export var wheel_z: float = 1.45

@export_group("Stabilitate")
## Centrul de masa sub origine: parghia care tine masina pe roti in viraj.
@export var com_height: float = -0.15

## "Creierul" — duck-typed pe interfata CarController (vezi antetul).
var controller: Node = null

## Compresia curenta a fiecarui arc, in metri [0, suspension_rest].
## Publica: vizualul rotilor (#258) si sondele citesc de aici.
var wheel_compression: Array[float] = [0.0, 0.0, 0.0, 0.0]
## Cate roti au atins solul in tick-ul curent (0-4).
var wheels_on_ground: int = 0

## Coltul fiecarei roti in spatiul masinii, in ordinea FL, FR, RL, RR.
var _wheel_points: Array[Vector3] = []
var _collision_shape: CollisionShape3D
## Media punctelor de contact ale rotilor cu solul, ca offset fata de origine.
## AICI se aplica fortele de cauciuc (motor/frana/grip/drag) — la sol, nu in
## centrul de masa. Diferenta nu e cosmetica: o forta laterala aplicata sub
## centrul de masa produce torque de RULIU, deci masina se lasa pe exterior in
## viraj; motorul aplicat la sol da squat la accelerare si dive la frana.
## Aplicate central (prima versiune), toate astea lipseau cu desavarsire —
## ruliu masurat de sonda: fix 0.0°.
var _contact_offset: Vector3 = Vector3.ZERO


func _ready() -> void:
	mass = 100.0
	# Gravitatia proiectului e cea implicita (9.8); jocul cade cu 28.
	var project_g: float = ProjectSettings.get_setting(
		"physics/3d/default_gravity", 9.8)
	gravity_scale = ARCADE_GRAVITY / project_g
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, com_height, 0.0)
	# Masina nu doarme niciodata: un corp adormit pe grila n-ar mai primi
	# fortele suspensiei si s-ar aseza pe colizer cand il trezeste contactul.
	can_sleep = false
	# Amortizarile globale raman mici: franarea reala vine din drag si grip,
	# nu dintr-un damping generic care ar atenua si suspensia.
	linear_damp = 0.0
	angular_damp = 0.5
	_wheel_points = [
		Vector3(-wheel_x, 0.0, -wheel_z), Vector3(wheel_x, 0.0, -wheel_z),
		Vector3(-wheel_x, 0.0, wheel_z), Vector3(wheel_x, 0.0, wheel_z),
	]
	# Colizerul caroseriei: NU atinge solul in mers (garda la sol o da
	# suspensia); exista pentru imbranceli (#257) si pentru aterizari dure,
	# cand arcul ajunge la fund.
	_collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(wheel_x * 2.0, 0.6, wheel_z * 2.0 + 0.6)
	_collision_shape.shape = box
	_collision_shape.position = Vector3(0.0, 0.35, 0.0)
	add_child(_collision_shape)


func set_controller(new_controller: Node) -> void:
	controller = new_controller
	add_child(new_controller)
	if new_controller.has_method("setup"):
		new_controller.setup(self)


func _physics_process(delta: float) -> void:
	var steer := 0.0
	var throttle := 0.0
	if controller != null:
		if controller.has_method("update"):
			controller.update(delta)
		steer = clampf(controller.get_steer(), -1.0, 1.0)
		throttle = clampf(controller.get_throttle(), -1.0, 1.0)

	_apply_suspension()
	_apply_driving(steer, throttle)


## Un raycast per colt; arcul impinge LA COLT, si exact asta produce ruliul si
## tangajul: rotile incarcate imping mai tare decat cele usurate.
func _apply_suspension() -> void:
	wheels_on_ground = 0
	var contact_sum := Vector3.ZERO
	var space := get_world_3d().direct_space_state
	var up := global_transform.basis.y
	var cast_len := suspension_rest + wheel_radius
	# Rigiditatea pe roata, derivata din frecventa si masa pe roata:
	# k = m_roata * (2*pi*f)^2; amortizarea din raport: c = 2*zeta*sqrt(k*m).
	var wheel_mass := mass * 0.25
	var omega := TAU * spring_freq
	var k := wheel_mass * omega * omega
	var c := 2.0 * damping_ratio * sqrt(k * wheel_mass)
	for i in _wheel_points.size():
		var attach := to_global(_wheel_points[i])
		var query := PhysicsRayQueryParameters3D.create(
			attach, attach - up * cast_len)
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			wheel_compression[i] = 0.0
			continue
		wheels_on_ground += 1
		contact_sum += hit.position as Vector3
		var dist := attach.distance_to(hit.position as Vector3)
		var compression := clampf(cast_len - dist, 0.0, suspension_rest)
		wheel_compression[i] = compression
		# Viteza punctului de prindere pe axa arcului: pozitiva cand coltul
		# urca (arcul se destinde), negativa cand se comprima.
		var offset := attach - global_position
		var point_vel := linear_velocity + angular_velocity.cross(offset)
		var spring_vel := point_vel.dot(up)
		var force_mag := k * compression - c * spring_vel
		# Arcul doar IMPINGE. Daca ar si trage, masina ar fi lipita de sol ca
		# de un magnet si orice creasta ar smulge-o in jos nefiresc.
		if force_mag > 0.0:
			apply_force(up * force_mag, offset)
	if wheels_on_ground > 0:
		_contact_offset = contact_sum / float(wheels_on_ground) - global_position


## Motor, frana, plafon, drag, grip lateral si directie — toate ca forte,
## cu aceleasi reguli de feel ca vechea fizica pe CharacterBody.
func _apply_driving(steer: float, throttle: float) -> void:
	# Tractiunea cere contact: cu rotile in aer nu se accelereaza si nu se
	# vireaza (aceeasi regula ca is_on_floor() in vechea fizica).
	var ground_frac := float(wheels_on_ground) / 4.0
	if ground_frac == 0.0:
		return

	var fwd := -global_transform.basis.z
	var fwd_h := Vector3(fwd.x, 0.0, fwd.z).normalized()
	var hvel := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var fwd_speed := hvel.dot(fwd_h)

	# Fortele de CAUCIUC se aplica la sol (media punctelor de contact), nu in
	# centrul de masa — de acolo vin ruliul in viraj, squat-ul la accelerare si
	# dive-ul la frana. Vezi nota de la _contact_offset.
	# --- Motor / frana (fortele scaleaza cu cate roti au contact) ---
	if throttle > 0.0 and fwd_speed < max_speed:
		apply_force(fwd_h * acceleration * throttle * mass * ground_frac,
			_contact_offset)
	elif throttle < 0.0:
		if fwd_speed > 2.0:
			apply_force(fwd_h * brake_force * throttle * mass * ground_frac,
				_contact_offset)
		elif fwd_speed > -reverse_speed:
			apply_force(
				fwd_h * acceleration * 0.6 * throttle * mass * ground_frac,
				_contact_offset)
	# Plafonul: peste vmax nu se taie viteza, se trage inapoi — echivalentul
	# lui move_toward de pe CharacterBody. Central, nu la sol: e un guvernator
	# de joc, nu o forta fizica — n-are voie sa adauge tangaj.
	if fwd_speed > max_speed:
		apply_central_force(-fwd_h * overspeed_pull * mass)

	# --- Rezistenta la rulare, doar pe sol ---
	apply_force(-hvel * drag * mass * ground_frac, _contact_offset)

	# --- Grip lateral: forta care amorteste viteza laterala ---
	var lateral := hvel - fwd_h * fwd_speed
	apply_force(-lateral * grip * mass * ground_frac, _contact_offset)

	# --- Directia: viteza unghiulara pe Y, scrisa direct (arcade asumat) ---
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	var yaw_rate := steer * steer_speed * speed_frac * reverse_sign
	angular_velocity = Vector3(
		angular_velocity.x, yaw_rate, angular_velocity.z)


func horizontal_speed() -> float:
	return Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()
