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
## Drift-ul (#256) e handbrake pur, ca pe CharacterBody, dar cu un castig al
## fizicii intregi: grip-ul se taie DOAR LA SPATE. Fata tine, spatele aluneca,
## deci unghiul de derapaj nu mai e simulat — e consecinta diferentei de
## aderenta intre axe, ca la o masina adevarata cu frana de mana trasa.
##
## Comenzile vin dintr-un "creier" cu interfata CarController (get_steer /
## get_throttle / is_drift_pressed / is_turbo_pressed) — pattern-ul separarii
## fizica/input NU se schimba. Aici e tinut duck-typed (Node, nu CarController)
## fiindca ala are `var car: Car` legat de CharacterBody3D; unificarea tipurilor
## e treaba integrarii (#258), nu a nucleului.

signal boost_started(car: RigidCar)
## Izbitura cu o alta masina, cu delta-v-ul incasat de NOI — proportional cu
## violenta contactului (shake, sunet — legate la #258).
signal bumped(car: RigidCar, other: RigidCar, delta_v: float)

## Gravitatia arcade a jocului (m/s²) — aceeasi cifra ca pe CharacterBody.
## Se traduce in gravity_scale fata de gravitatia proiectului in _ready.
const ARCADE_GRAVITY: float = 28.0
## Aderenta laterala intr-o balta: practic zero directie (contract apply_slip).
const SLIP_GRIP_PUDDLE: float = 0.8
## Aderenta pe suprafata uda pe care se CONDUCE: intre drift si asfalt.
const SLIP_GRIP_WET: float = 3.6

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

@export_group("Drift (handbrake)")
## Aderenta SPATELUI cat tine driftul; fata pastreaza `grip` intreg.
@export var drift_grip: float = 2.0
@export var drift_steer_bonus: float = 1.5
@export var drift_bias: float = 0.4
@export var drift_min_speed: float = 9.0

@export_group("Turbo (model Ignition)")
@export var turbo_fill_time: float = 10.0
@export var turbo_drift_multiplier: float = 2.5
@export var turbo_burn_time: float = 2.2
@export var turbo_min_to_fire: float = 0.15
@export var turbo_speed_bonus: float = 11.0
@export var turbo_accel_bonus: float = 10.0

@export_group("Imbranceli")
## MASA din identitate: mass = 100 * mass_factor. Motorul de fizica imparte
## impulsul dupa raportul maselor DIN CONSTRUCTIE — autobuzul (2.6) intrat in
## sport (0.9) o trimite de ~3x mai tare decat se opreste el, fara cod.
@export var mass_factor: float = 1.0
## Cat de "saltarea" e izbitura (PhysicsMaterial.bounce). Sub 1 = arcade.
@export var bump_restitution: float = 0.35
## Plafon pe delta-v-ul incasat dintr-un contact cu alta masina (m/s).
## Motorul poate genera varfuri; peste plafon, excedentul se taie PASTRAND
## directia — raportul de mase ramane, violenta scade. Acelasi rol ca
## bump_max_impulse de pe CharacterBody.
@export var bump_max_dv: float = 15.0
## Sub viteza asta de apropiere contactul e frecare, nu izbitura: fara semnal,
## fara shake — masinile care merg alaturi nu-si dau ghionturi.
@export var bump_min_closing: float = 2.5
## Cat nu mai emite ACEEASI pereche un al doilea semnal de bump. Fizica
## contactului sustinut o rezolva solverul (impingere, nu impulsuri repetate);
## cooldown-ul e doar pe semnal, ca shake-ul sa nu se acumuleze.
@export var bump_signal_cooldown: float = 0.12
## Peste acest delta-v incasat, rotile pierd scurt aderenta laterala.
@export var bump_slip_dv: float = 5.0
## Plafon pe rotatia primita dintr-o lovitura (rad/s): te sucesti, nu faci
## piruete. Necesar si pe fizica intreaga, fiindca directia scrie yaw-ul
## direct — rotatia din colizie ar fi STEARSA de scrierea urmatoare; o
## preluam in _impact_yaw (plafonat, se stinge singur) si o adunam peste
## comanda, exact ca pe CharacterBody.
@export var bump_yaw_max: float = 2.4

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

# --- Stare drift/turbo (aceleasi reguli ca pe CharacterBody) ---
var is_drifting: bool = false
var drift_dir: float = 0.0
var turbo_charge: float = 0.0 # 0..1, bara din UI
var is_boosting: bool = false
var slip_time: float = 0.0
var slip_grip: float = SLIP_GRIP_PUDDLE
var _forced_boost: float = 0.0 # rocket start: ardere gratuita

## Factor extern pe plafonul de viteza (offroad 45%, crush). Il scrie logica
## de pista/hazard (#258); nucleul doar il respecta. Turbo-ul se ADUNA peste,
## ca pe CharacterBody: scurtatura cu turbo ramane o alegere valida.
var speed_limit_factor: float = 1.0

## Compresia curenta a fiecarui arc, in metri [0, suspension_rest].
## Publica: vizualul rotilor (#258) si sondele citesc de aici.
var wheel_compression: Array[float] = [0.0, 0.0, 0.0, 0.0]
## Cate roti au atins solul in tick-ul curent (0-4).
var wheels_on_ground: int = 0

## Coltul fiecarei roti in spatiul masinii, in ordinea FL, FR, RL, RR
## (fata = -Z, sensul de mers).
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
## Acelasi lucru, dar per axa (0 = fata, 1 = spate): grip-ul lateral se aplica
## separat pe axe, ca driftul sa poata taia doar spatele.
var _axle_offset: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _axle_grounded: Array[int] = [0, 0]

# --- Imbranceli: masurarea delta-v-ului dat de solver ---
## Viteza la FINALUL tick-ului trecut (dupa scrierile noastre directe). La
## intrarea in tick-ul curent, diferenta fata de ea e exact ce a facut
## solverul intre timp: coliziuni + fortele integrate. Fortele noastre
## contribuie sub ~0.5 m/s per cadru, mult sub orice prag de bump.
var _prev_velocity: Vector3 = Vector3.ZERO
## Yaw-ul pe care L-AM scris noi la finalul tick-ului trecut; diferenta la
## intrare = rotatia data de solver (lovitura excentrica).
var _commanded_yaw: float = 0.0
## Rotatia primita din lovituri, plafonata; se stinge singura si se ADUNA
## peste comanda de directie — altfel scrierea directa a yaw-ului ar sterge-o.
var _impact_yaw: float = 0.0
## instance_id-ul celeilalte masini -> secunde pana la urmatorul semnal admis.
var _bump_pairs: Dictionary = {}


func _ready() -> void:
	mass = 100.0 * mass_factor
	# Gravitatia proiectului e cea implicita (9.8); jocul cade cu 28.
	var project_g: float = ProjectSettings.get_setting(
		"physics/3d/default_gravity", 9.8)
	gravity_scale = ARCADE_GRAVITY / project_g
	# Imbranceli: contactele se raporteaza (pentru semnal + plafon), iar
	# restitutia arcade vine din material — se simte lovitura, nu ricoseaza.
	contact_monitor = true
	max_contacts_reported = 8
	var mat := PhysicsMaterial.new()
	mat.bounce = bump_restitution
	mat.friction = 0.4
	physics_material_override = mat
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
	# Intai bilantul solverului (izbituri), cat _prev_velocity mai e "ieri".
	_process_bumps(delta)

	var steer := 0.0
	var throttle := 0.0
	var drift_pressed := false
	var turbo_pressed := false
	if controller != null:
		if controller.has_method("update"):
			controller.update(delta)
		steer = clampf(controller.get_steer(), -1.0, 1.0)
		throttle = clampf(controller.get_throttle(), -1.0, 1.0)
		drift_pressed = controller.is_drift_pressed()
		turbo_pressed = controller.is_turbo_pressed()

	_apply_suspension()

	var fwd := -global_transform.basis.z
	var fwd_h := Vector3(fwd.x, 0.0, fwd.z).normalized()
	var fwd_speed := Vector3(linear_velocity.x, 0.0, linear_velocity.z) \
		.dot(fwd_h)

	_update_drift(drift_pressed, steer, fwd_speed)
	_update_turbo(turbo_pressed, delta)
	slip_time = maxf(slip_time - delta, 0.0)

	_apply_driving(steer, throttle, fwd_h, fwd_speed)

	# Reperele pentru bilantul de la urmatorul tick: tot ce e diferit de astea
	# la intrarea urmatoare e opera solverului (coliziuni), nu a noastra.
	_prev_velocity = linear_velocity
	_commanded_yaw = angular_velocity.y


## Bilantul izbiturilor cu alte masini: solverul a impartit deja impulsul
## dupa raportul maselor (identitatea din principiul 1, gratis); aici se
## aplica REGULILE arcade de deasupra: plafonul de violenta, rotatia
## plafonata, slip-ul la lovitura mare si semnalul cu prag + cooldown.
func _process_bumps(delta: float) -> void:
	var others: Array[RigidCar] = []
	for body in get_colliding_bodies():
		if body is RigidCar:
			others.append(body as RigidCar)

	if not others.is_empty():
		var dv_vec := linear_velocity - _prev_velocity
		var dv := dv_vec.length()
		# Plafonul: excedentul se taie pastrand DIRECTIA — raportul de mase
		# ramane in picioare, doar violenta scade.
		if dv > bump_max_dv:
			linear_velocity = _prev_velocity + dv_vec * (bump_max_dv / dv)
			dv = bump_max_dv
		# Rotatia din lovitura excentrica: preluata cu plafon in _impact_yaw,
		# care se aduna peste comanda de directie si se stinge singur. Fara
		# asta, scrierea directa a yaw-ului ar sterge-o in cadrul urmator.
		var solver_yaw := angular_velocity.y - _commanded_yaw
		if absf(solver_yaw) > 0.1:
			_impact_yaw = clampf(_impact_yaw + solver_yaw,
				-bump_yaw_max, bump_yaw_max)
		# Lovitura mare pe lateral taie scurt aderenta: cel lovit isi prinde
		# masina din alunecare, ca pe CharacterBody.
		var fwd := -global_transform.basis.z
		var fwd_h := Vector3(fwd.x, 0.0, fwd.z).normalized()
		var lat_dv := (dv_vec - fwd_h * dv_vec.dot(fwd_h)).length()
		if lat_dv >= bump_slip_dv:
			slip_time = maxf(slip_time, clampf(0.15 + lat_dv * 0.02, 0.0, 0.55))
			slip_grip = SLIP_GRIP_WET
		# Semnalul: doar peste pragul de frecare si nu mai des decat
		# cooldown-ul per pereche (fizica impingerii merge oricum inainte).
		if dv >= bump_min_closing:
			for other in others:
				var key := other.get_instance_id()
				if _bump_pairs.has(key):
					continue
				_bump_pairs[key] = bump_signal_cooldown
				bumped.emit(self, other, dv)

	for key: int in _bump_pairs.keys():
		var left := float(_bump_pairs[key]) - delta
		if left <= 0.0:
			_bump_pairs.erase(key)
		else:
			_bump_pairs[key] = left
	_impact_yaw *= exp(-4.0 * delta)
	if absf(_impact_yaw) < 0.05:
		_impact_yaw = 0.0


## Un raycast per colt; arcul impinge LA COLT, si exact asta produce ruliul si
## tangajul: rotile incarcate imping mai tare decat cele usurate.
func _apply_suspension() -> void:
	wheels_on_ground = 0
	var contact_sum := Vector3.ZERO
	var axle_sum: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	_axle_grounded = [0, 0]
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
		var axle := 0 if i < 2 else 1
		contact_sum += hit.position as Vector3
		axle_sum[axle] += hit.position as Vector3
		_axle_grounded[axle] += 1
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
	for axle in 2:
		if _axle_grounded[axle] > 0:
			_axle_offset[axle] = axle_sum[axle] / float(_axle_grounded[axle]) \
				- global_position


## Handbrake pur: alunecare controlata pentru viraje, fara boost la iesire.
func _update_drift(drift_pressed: bool, steer: float, fwd_speed: float) -> void:
	if not is_drifting:
		if drift_pressed and fwd_speed > drift_min_speed and absf(steer) > 0.25:
			is_drifting = true
			drift_dir = signf(steer)
	elif not drift_pressed or fwd_speed < drift_min_speed * 0.55:
		is_drifting = false


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
	# Lovitura de plecare: acelasi +4 m/s ca pe CharacterBody. Sunetul si
	# squash-ul vizual vin la integrare (#258), pe semnalul boost_started.
	var fwd := -global_transform.basis.z
	linear_velocity += Vector3(fwd.x, 0.0, fwd.z).normalized() * 4.0
	boost_started.emit(self)


func grant_turbo(amount: float) -> void:
	turbo_charge = clampf(turbo_charge + amount, 0.0, 1.0)


## Ardere gratuita (rocket start): boost fara sa goleasca bara.
func force_boost(seconds: float) -> void:
	_forced_boost = seconds
	is_boosting = true
	_start_boost()


## Contractul cu apa (WaterHazard / banda uda): alunecare pentru urmatoarea
## fractiune de secunda, cu intensitatea ceruta de hazard.
func apply_slip(grip_value: float = SLIP_GRIP_PUDDLE) -> void:
	slip_time = 0.25
	slip_grip = grip_value


## Plafonul de viteza al momentului: taiat de factorul extern (offroad/crush),
## ridicat de turbo. Turbo-ul se aduna DUPA taiere — scurtatura cu turbo
## ramane o alegere valida, exact ca pe CharacterBody.
func _current_max_speed() -> float:
	var vmax := max_speed * speed_limit_factor
	if is_boosting:
		vmax += turbo_speed_bonus
	return vmax


## Motor, frana, plafon, drag si directie — toate ca forte, cu aceleasi reguli
## de feel ca vechea fizica. Grip-ul lateral e PER AXA: fata tine mereu cu
## `grip` intreg, spatele trece pe `drift_grip` cat tine driftul — de aici
## unghiul de derapaj, fizic, nu simulat.
func _apply_driving(steer: float, throttle: float,
		fwd_h: Vector3, fwd_speed: float) -> void:
	# Tractiunea cere contact: cu rotile in aer nu se accelereaza si nu se
	# vireaza (aceeasi regula ca is_on_floor() in vechea fizica).
	var ground_frac := float(wheels_on_ground) / 4.0
	if ground_frac == 0.0:
		return

	var hvel := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var vmax := _current_max_speed()

	# Fortele de CAUCIUC se aplica la sol (media punctelor de contact), nu in
	# centrul de masa — de acolo vin ruliul in viraj, squat-ul la accelerare si
	# dive-ul la frana. Vezi nota de la _contact_offset.
	# --- Motor / frana (fortele scaleaza cu cate roti au contact) ---
	if throttle > 0.0 and fwd_speed < vmax:
		var accel := acceleration
		if is_boosting:
			accel += turbo_accel_bonus
		apply_force(fwd_h * accel * throttle * mass * ground_frac,
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
	if fwd_speed > vmax:
		apply_central_force(-fwd_h * overspeed_pull * mass)

	# --- Rezistenta la rulare, doar pe sol ---
	apply_force(-hvel * drag * mass * ground_frac, _contact_offset)

	# --- Grip lateral, per axa (fata / spate) ---
	for axle in 2:
		if _axle_grounded[axle] == 0:
			continue
		var grip_axle := grip
		if axle == 1 and is_drifting:
			grip_axle = drift_grip
		if slip_time > 0.0:
			grip_axle = slip_grip
		# Viteza laterala A AXEI (nu a centrului): include componenta din
		# rotatie, deci spatele care se roteste in jurul fetei chiar "simte"
		# ca aluneca si e amortizat acolo unde aluneca.
		var offset: Vector3 = _axle_offset[axle]
		var point_vel := linear_velocity + angular_velocity.cross(offset)
		var lat := Vector3(point_vel.x, 0.0, point_vel.z)
		lat -= fwd_h * lat.dot(fwd_h)
		var axle_frac: float = float(_axle_grounded[axle]) / 2.0
		apply_force(-lat * grip_axle * mass * 0.5 * axle_frac, offset)

	# --- Directia: viteza unghiulara pe Y, scrisa direct (arcade asumat) ---
	var effective_steer := steer
	if is_drifting:
		effective_steer = clampf(
			steer * drift_steer_bonus + drift_dir * drift_bias, -1.6, 1.6)
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	var yaw_rate := effective_steer * steer_speed * speed_frac * reverse_sign
	# Comanda + rotatia ramasa din lovituri (se stinge singura).
	angular_velocity = Vector3(
		angular_velocity.x, yaw_rate + _impact_yaw, angular_velocity.z)


func horizontal_speed() -> float:
	return Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()
