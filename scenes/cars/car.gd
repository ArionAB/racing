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
signal respawned(car: Car)
## Izbitura cu o alta masina, cu delta-v-ul incasat de NOI — cu cat mai mare,
## cu atat mai violent contactul (shake, sunet).
signal bumped(car: Car, other: Car, delta_v: float)
## Strivit de un hazard. `severity` in 0..1, pentru shake proportional.
signal crushed(car: Car, severity: float)

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
## Aderenta laterala intr-o balta de furtun: aproape zero, treci prin ea in
## sub o secunda.
const SLIP_GRIP_PUDDLE: float = 0.8
## Aderenta pe o suprafata uda pe care se CONDUCE, nu prin care se trece.
## Intre drift (2.0) si asfalt (7-10): simti ca aluneca, dar poti tine linia.
const SLIP_GRIP_WET: float = 3.6
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
## MASA, nu un "factor": intra ca 1/m in impulsul de coliziune (_resolve_bump).
@export var mass_factor: float = 1.0
@export var offroad_speed_factor: float = 0.45

@export_group("Imbranceli")
## Cat de "saltarea" e izbitura. 0 = perfect plastica (se lipesc), 1 = bile de
## biliard. Sub 1 = arcade: se simte lovitura, dar nu ricoseaza absurd.
@export var bump_restitution: float = 0.35
## Plafon pe IMPULS, nu pe delta-v-ul fiecarei masini. Diferenta conteaza: taiat
## pe masina, plafonul le egalizeaza (si autobuzul, si sportiva primesc fix
## maximul, adica exact identitatea pe care o vrem), taiat pe impuls, raportul de
## mase se pastreaza intact — doar violenta scade. Calibrat ca cea mai usoara
## masina din garaj (0.9) sa incaseze cel mult ~15 m/s.
@export var bump_max_impulse: float = 14.0
## Sub viteza asta de apropiere, contactul e frecare, nu izbitura: masinile care
## se ating mergand alaturi nu trebuie sa-si dea ghionturi.
@export var bump_min_closing: float = 2.5
## Cat nu mai poate genera un al doilea impuls ACEEASI pereche de masini.
## Fara asta, contactul sustinut aduna un impuls la fiecare cadru de fizica —
## de acolo veneau catapultarile de 50 m/s masurate cu tools/probe_race.gd.
@export var bump_pair_cooldown: float = 0.12
## Cat de tare se resping masinile intrepatrunse, per metru de patrundere.
## Fara asta o masina grea poate "inghiti" una usoara si o cara in ea.
@export var bump_separation: float = 8.0

# --- Stare de cursa (scrisa de Race) ---
var race_active: bool = false
var finished: bool = false
var race_position: int = 1
var is_player: bool = false
var speed_scale: float = 1.0 # variatia onesta a AI (0.88..0.97), 1.0 la player

var car_name: String = "?"
var pilot_name: String = "?" # numele "pilotului", stabil intre curse
var data: CarData
var controller: CarController
var track: Track
var road_index: int = 0
## Pe ce banda e masina: 0 = bucla principala, 1+ = scurtatura. Indexul de mai
## sus se refera MEREU la ruta asta, nu la traseul principal — vezi [TrackRoute].
var route: int = 0
## Ultimul punct de pe traseu unde masina era cu roatele pe asfalt — de aici
## repornim daca ratam o aterizare sau ajungem in nisip.
##
## Se retine si RUTA, nu doar indexul. Fara ea, o repunere de pe scurtatura
## te-ar fi asezat la indexul cu acelasi numar de pe bucla principala, adica
## intr-un punct fara nicio legatura cu locul unde ai gresit.
var last_safe_index: int = 0
var last_safe_route: int = 0

# --- Drift/turbo ---
var is_drifting: bool = false
var drift_dir: float = 0.0
var turbo_charge: float = 0.0 # 0..1, bara din UI
var is_boosting: bool = false
var slip_time: float = 0.0 # aquaplanare (setata de WaterHose sau de o banda uda)
## Ce aderenta laterala are masina cat timp aluneca.
##
## Era o constanta de 0.8 in mijlocul fizicii — corect pentru o balta de furtun
## pe care o traversezi in jumatate de secunda, catastrofal pentru o suprafata
## uda de 200 m. Prima incercare de banc de nisip a folosit chiar 0.8 si a taiat
## AI-ul de la 2.5 la 1.6 tururi, cu 27% din timp in apa. Acum intensitatea vine
## de la cel care cere alunecarea.
var slip_grip: float = SLIP_GRIP_PUDDLE
## Strivit: cat mai tine penalizarea, si cat de tare taie din viteza.
##
## Oglindeste slip_time in loc sa inventeze un al doilea mecanism. NU exista
## stare de "distrus" si nici nu vrem una: pedeapsa in jocul asta e mereu TIMP
## PIERDUT, ca la repunere. Bolovanul te turteste si te incetineste; trenul face
## acelasi lucru dus la extrem, plus repunere.
var crush_time: float = 0.0
var crush_factor: float = 1.0
var _forced_boost: float = 0.0 # rocket start: ardere gratuita, nu goleste bara

## Nodul (din Race) sub care se depun urmele de cauciuc.
var skid_parent: Node3D

var _visual: Node3D
var _drift_particles: CPUParticles3D
var _boost_particles: CPUParticles3D
var _engine_audio: AudioStreamPlayer3D
var _skid_audio: AudioStreamPlayer3D
var _turbo_full_latch: bool = false

# Rotile modelului (noduri separate in FBX-urile RgsDev).
var _wheels_all: Array[Node3D] = []
var _wheels_front: Array[Node3D] = []
## Transformarea originala a fiecarei roti (FBX-urile au scala "coapta" in
## nod — daca o suprascriem cu o rotatie pura, rotile devin microscopice).
var _wheel_orig: Array[Basis] = []
var _wheel_radius: float = 0.35
var _wheel_spin: float = 0.0
var _wheel_steer: float = 0.0

# Umbra blob: ieftina, mereu pe sol — arata locul aterizarii la sarituri.
var _shadow: MeshInstance3D
var _shadow_mat: StandardMaterial3D
var _was_on_floor: bool = true
var _prev_velocity: Vector3 = Vector3.ZERO
var _wall_cooldown: float = 0.0
var _bump_cooldown: float = 0.0
## instance_id-ul celeilalte masini -> secunde pana la urmatorul impuls admis.
var _bump_pairs: Dictionary = {}
var _skid_accum: float = 0.0
var _respawn_cooldown: float = 0.0

# Resurse partajate intre toate urmele de cauciuc (ieftin la instantiere).
static var _skid_mesh: PlaneMesh
static var _skid_mat: StandardMaterial3D

var _collision_shape: CollisionShape3D

func _ready() -> void:
	floor_snap_length = 2.0 # tine masina lipita de asfalt peste creste
	_build_visual()
	_build_effects()
	_collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	_collision_shape.shape = box
	_collision_shape.position = Vector3(0, 0.6, 0)
	add_child(_collision_shape)

func set_controller(new_controller: CarController) -> void:
	controller = new_controller
	add_child(new_controller)
	new_controller.setup(self)

func apply_data(new_data: CarData, color_override: Color = Color(0, 0, 0, 0)) -> void:
	data = new_data
	car_name = data.display_name
	max_speed = data.max_speed
	acceleration = data.acceleration
	grip = data.grip
	mass_factor = data.mass_factor
	body_color = data.color if color_override.a == 0.0 else color_override
	if _visual != null:
		_visual.queue_free()
	_build_visual()
	# Colizerul si efectele urmeaza dimensiunile vehiculului.
	if _collision_shape != null:
		var box := _collision_shape.shape as BoxShape3D
		box.size = Vector3(data.body_width * 0.9, 1.0, data.body_length * 0.85)
	if _drift_particles != null:
		_drift_particles.position.z = data.body_length * 0.5
		_boost_particles.position.z = data.body_length * 0.5 + 0.1
	if _shadow != null:
		_shadow.scale = Vector3(data.body_width * 0.62, 1.0, data.body_length * 0.5)

func _physics_process(delta: float) -> void:
	if track != null:
		# Intai PE CE banda suntem, abia apoi unde pe ea. Ordinea conteaza:
		# cautarea de index e locala (fereastra de ~72 m), deci pe ruta gresita
		# ar ramane agatata in urma si fractia de tur ar ingheta.
		var resolved := track.resolve_route(route, road_index, global_position)
		if resolved.x != route:
			route = resolved.x
			road_index = resolved.y
		else:
			road_index = track.closest_index(road_index, global_position, route)
		# Banda uda: se reinnoieste in fiecare cadru, deci efectul tine exact cat
		# stai pe ea. Refoloseste acelasi slip_time ca WaterHose — un al doilea
		# mecanism de aquaplanare ar fi insemnat doua feluri de a pierde grip-ul,
		# care s-ar fi tunat separat si ar fi divergat.
		if track.route_is_wet(route):
			apply_slip(SLIP_GRIP_WET)

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
	var grip_now := drift_grip if is_drifting else grip
	if slip_time > 0.0:
		grip_now = slip_grip
	lateral *= exp(-grip_now * delta)
	if fwd_speed > vmax:
		fwd_speed = move_toward(fwd_speed, vmax, 12.0 * delta)
	hvel = fwd_h * fwd_speed + lateral

	slip_time = maxf(slip_time - delta, 0.0)
	crush_time = maxf(crush_time - delta, 0.0)
	if crush_time <= 0.0:
		crush_factor = 1.0
	velocity.x = hvel.x
	velocity.z = hvel.z
	_prev_velocity = velocity
	move_and_slide()
	_handle_bumping()
	_detect_landing()
	_update_visual_tilt(delta, steer, fwd_speed)
	_update_wheels(delta, steer, fwd_speed)
	_update_shadow()
	_update_effects(delta)
	_wall_cooldown = maxf(_wall_cooldown - delta, 0.0)
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)
	_respawn_cooldown = maxf(_respawn_cooldown - delta, 0.0)
	for key: int in _bump_pairs.keys():
		var left := float(_bump_pairs[key]) - delta
		if left <= 0.0:
			_bump_pairs.erase(key)
		else:
			_bump_pairs[key] = left
	# Checkpoint: aici, cu roatele pe asfalt, eram in siguranta. Dupa
	# move_and_slide, ca is_on_floor() sa fie al cadrului curent.
	if track != null and is_on_floor() \
			and track.is_on_road(road_index, global_position, route):
		last_safe_index = road_index
		last_safe_route = route

## Plafonul de viteza al momentului: taiat de iarba, ridicat de turbo.
## Turbo-ul merge SI pe iarba — scurtatura cu turbo e o alegere valida.
func _current_max_speed() -> float:
	var vmax := max_speed * speed_scale
	if track != null and not track.is_on_road(road_index, global_position, route):
		vmax *= offroad_speed_factor
	if is_boosting:
		vmax += turbo_speed_bonus
	# Strivirea taie plafonul, nu viteza curenta: pierzi timp reaccelerand, exact
	# ca la offroad. Se aplica DUPA turbo, ca sa nu poti sterge pedeapsa cu boost.
	return vmax * crush_factor

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

## Refresh-uit de WaterHose cat timp esti in banda uda activa.
## Cere alunecare pentru urmatoarea fractiune de secunda.
##
## `grip_value` e aderenta laterala cat timp tine: SLIP_GRIP_PUDDLE pentru o
## balta (practic zero directie), SLIP_GRIP_WET pentru o suprafata uda pe care
## se poate totusi conduce. Reper: asfalt 7-10, drift 2.0.
func apply_slip(grip_value: float = SLIP_GRIP_PUDDLE) -> void:
	slip_time = 0.25
	slip_grip = grip_value

## Ghiont de la un obstacol care iti schimba traiectoria: caruselul te matura
## pe tangenta, deviatorul te trimite pe cealalta banda. Impactul in sine
## (shake + sunet) vine din coliziunea solida, prin _handle_bumping.
## Strivit de un hazard: turtit, incetinit, si scos din boost.
##
## `factor` inmulteste plafonul de viteza (0.55 = 55%), `keep_speed` cat din
## viteza orizontala ramane pe loc, iar `squash` e forma de turtire.
func crush(seconds: float, factor: float, squash: Vector3,
		keep_speed: float) -> void:
	crush_time = maxf(crush_time, seconds)
	crush_factor = minf(crush_factor, factor)
	velocity.x *= keep_speed
	velocity.z *= keep_speed
	is_boosting = false
	_forced_boost = 0.0
	_punch_scale(squash)
	crushed.emit(self, 1.0 - factor)


func apply_sweep(push: Vector3) -> void:
	velocity += push

## Aruncat in aer de o creasta de fly-off. SETAM velocity.y, nu adunam: pe sol
## el e mereu readus la ~0 de move_and_slide, deci o adunare s-ar pierde.
func launch(up_speed: float) -> void:
	if velocity.y >= up_speed:
		return
	velocity.y = up_speed
	_punch_scale(Vector3(0.9, 1.18, 0.92)) # intinsa pe verticala la desprindere

func _handle_bumping() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider() as Car
		var n := col.get_normal() # dinspre obstacol spre noi
		var rigid := col.get_collider() as RigidBody3D
		if rigid != null:
			# Popice & co: le imprastiem cu un impuls — juice fizic ieftin.
			# Scalat cu masa: autobuzul le trimite mai departe decat un sport.
			rigid.apply_central_impulse(-n * clampf(
				horizontal_speed() * 0.5 * mass_factor, 1.0, 16.0) + Vector3.UP * 1.5)
			continue
		if other != null:
			_resolve_bump(other, col)
		elif absf(n.y) < 0.5:
			# Obstacol vertical (perete/bariera): impact = viteza "in" perete.
			var impact := maxf(0.0, Vector3(
				_prev_velocity.x, 0.0, _prev_velocity.z).dot(-n))
			if impact > 8.0 and _wall_cooldown <= 0.0:
				_wall_cooldown = 0.35
				wall_hit.emit(self, impact)
				if is_player:
					AudioManager.play_sfx(&"wall_hit")

## Izbitura dintre doua masini, cu MASA in ecuatie — principiul de design nr. 1
## ("grea impinge, usoara zboara") nu ca un caz special, ci ca fizica: acelasi
## impuls pentru amandoua, impartit la masa fiecareia. Autobuzul (2.6) intrat in
## Politie (0.9) o trimite de ~3 ori mai tare decat se opreste el.
##
## Trei lucruri il fac sa NU fie pinball:
##  1. impulsul creste cu viteza de APROPIERE, nu e o constanta — frecarea
##     alaturi de cineva nu mai da ghionturi;
##  2. o pereche de masini nu poate genera un al doilea impuls mai devreme de
##     `bump_pair_cooldown` (contactul dura zeci de cadre si aduna la infinit);
##  3. impulsul e plafonat, deci nimeni nu e catapultat de pe pista — si fiind
##     plafonat pe IMPULS, nu pe masina, raportul de mase supravietuieste taierii.
func _resolve_bump(other: Car, col: KinematicCollision3D) -> void:
	var key := other.get_instance_id()
	if float(_bump_pairs.get(key, 0.0)) > 0.0:
		return
	var n := col.get_normal() # dinspre cealalta masina spre noi
	n.y = 0.0 # imbrancelile sunt orizontale; saltul il face suspensia, nu contactul
	if n.length_squared() < 0.01:
		# Normala aproape verticala = o masina s-a URCAT pe cealalta. Se intampla
		# cu vehiculele lungi (autobuzul calca sportiva si o cara in el 20m, cu
		# zero imbranceala — masurat inainte de fix). Atunci directia de respingere
		# o luam din pozitiile relative, ca sa se desprinda oricum.
		n = global_position - other.global_position
		n.y = 0.0
		if n.length_squared() < 0.01:
			return
	n = n.normalized()
	# Cat de repede ne apropiem, masurat pe normala contactului — din vitezele
	# DINAINTEA lui move_and_slide. Cele de acum au deja componenta spre coliziune
	# stearsa de alunecare (de-aia se simtea ca un zid: te opreai sec si primeai
	# in schimb un ghiont fix, fara legatura cu forta izbiturii).
	var closing := (_prev_velocity - other._prev_velocity).dot(-n)
	# Depenetrare: cat de mult ne-am intrepatruns deja. Fara ea, o masina grea
	# poate ingloba una usoara si o cara in ea zeci de metri.
	var separation := col.get_depth() * bump_separation
	if closing < bump_min_closing and separation < 0.5:
		return
	_bump_pairs[key] = bump_pair_cooldown
	other._bump_pairs[get_instance_id()] = bump_pair_cooldown
	var inv_self := 1.0 / maxf(mass_factor, 0.05)
	var inv_other := 1.0 / maxf(other.mass_factor, 0.05)
	var reduced_mass := 1.0 / (inv_self + inv_other)
	# Un singur impuls pentru pereche (izbitura + desprindere), impartit apoi la
	# masa fiecareia. Asa "cine pe cine arunca" iese din raportul de mase, nu
	# dintr-un caz special scris de mana.
	var impulse := (1.0 + bump_restitution) * maxf(closing, 0.0) * reduced_mass
	impulse += separation * reduced_mass
	impulse = minf(impulse, bump_max_impulse)
	var dv_self := impulse * inv_self
	var dv_other := impulse * inv_other
	velocity += n * dv_self
	other.velocity += -n * dv_other
	bumped.emit(self, other, dv_self)
	other.bumped.emit(other, self, dv_other)
	if _bump_cooldown <= 0.0 and (is_player or other.is_player):
		_bump_cooldown = 0.25
		other._bump_cooldown = 0.25
		AudioManager.play_sfx(&"bump")

func _detect_landing() -> void:
	if is_on_floor() and not _was_on_floor and _prev_velocity.y < -6.0:
		landed.emit(self, -_prev_velocity.y)
		_punch_scale(Vector3(1.15, 0.8, 1.15))
		if is_player:
			AudioManager.play_sfx(&"land")
	_was_on_floor = is_on_floor()

# ------------------------------------------------------------------ restul

## Repunere pe pista dupa o aterizare ratata (sau orice iesire din lume): pe
## ultimul checkpoint valid, retrasa cu `backoff_m` metri ca sa aiba spatiu de
## elan. Nu pe grila de start — repornirea cursei de la zero ar fi o pedeapsa
## absurda pentru o saritura ratata.
## Are rost sa apesi butonul de repunere acum?
##
## respawn() iese in tacere cand nu poate (fara pista, in cooldown, dupa
## terminare). Butonul trebuie sa arate asta, nu sa para stricat.
func can_respawn() -> bool:
	return track != null and _respawn_cooldown <= 0.0 and not finished


func respawn(backoff_m: float = 14.0) -> void:
	if track == null or _respawn_cooldown > 0.0:
		return
	_respawn_cooldown = 1.5
	global_transform = track.recovery_transform(last_safe_index, backoff_m,
		last_safe_route)
	# Un pic de viteza, nu oprire pe loc: pornirea din zero in mijlocul unei
	# curse e mai frustranta decat saritura ratata.
	velocity = -global_transform.basis.z * 9.0
	is_drifting = false
	is_boosting = false
	_forced_boost = 0.0
	slip_time = 0.0
	crush_time = 0.0
	crush_factor = 1.0
	_bump_pairs.clear() # am fost teleportati; vechile contacte nu mai exista
	_was_on_floor = true # fara "aterizare" falsa (shake + bufnet) la repunere
	route = last_safe_route
	road_index = track.closest_index_global(global_position, route)
	last_safe_index = road_index
	respawned.emit(self)

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
		# Scalat cu masinile (factor 0.84): urma trebuie sa aiba latimea anvelopei.
		_skid_mesh.size = Vector2(0.34, 0.85)
		_skid_mat = StandardMaterial3D.new()
		_skid_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.4)
		_skid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_skid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_skid_mesh.material = _skid_mat
	var half_track_w := data.body_width * 0.38 if data != null else 0.85
	var rear_z := data.body_length * 0.34 if data != null else 1.3
	for side in [-1.0, 1.0]:
		var mark := MeshInstance3D.new()
		mark.mesh = _skid_mesh
		skid_parent.add_child(mark)
		mark.global_position = global_position \
			+ global_transform.basis.x * half_track_w * side \
			+ global_transform.basis.z * rear_z + Vector3.UP * 0.06
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

	# Umbra blob: disc intunecat, pozitionat pe sol la fiecare tick.
	# top_level = nu mosteneste transformarea masinii (o setam noi global).
	_shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	_shadow.mesh = disc
	_shadow_mat = StandardMaterial3D.new()
	_shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.38)
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = _shadow_mat
	_shadow.scale = Vector3(1.3, 1.0, 2.0)
	add_child(_shadow)
	_shadow.top_level = true

## Rotile se invart cu viteza reala (unghi = viteza / raza) si cele din
## fata se intorc vizual spre directia de viraj.
func _update_wheels(delta: float, steer: float, fwd_speed: float) -> void:
	if _wheels_all.is_empty():
		return
	_wheel_spin = fposmod(_wheel_spin + fwd_speed / _wheel_radius * delta, TAU)
	_wheel_steer = lerpf(_wheel_steer, steer * 0.42, 10.0 * delta)
	var spin_basis := Basis(Vector3.RIGHT, _wheel_spin)
	for idx in _wheels_all.size():
		var wheel := _wheels_all[idx]
		var anim := spin_basis
		if wheel in _wheels_front:
			anim = Basis(Vector3.UP, _wheel_steer) * spin_basis
		# Compunem PESTE transformarea originala, nu in locul ei.
		wheel.basis = anim * _wheel_orig[idx]

## Umbra blob: raycast in jos, discul sta pe sol indiferent unde e masina.
## Cu cat sari mai sus, cu atat umbra palste — dar iti arata aterizarea.
func _update_shadow() -> void:
	if _shadow == null:
		return
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.6, global_position + Vector3.DOWN * 30.0)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		_shadow.visible = false
		return
	_shadow.visible = true
	_shadow.global_position = (hit.position as Vector3) + Vector3.UP * 0.06
	_shadow.rotation = Vector3(0.0, rotation.y, 0.0)
	var height := global_position.y - (hit.position as Vector3).y
	_shadow_mat.albedo_color.a = clampf(0.38 - height * 0.03, 0.08, 0.38)

func _update_visual_tilt(delta: float, steer: float, fwd_speed: float) -> void:
	var speed_frac := clampf(fwd_speed / max_speed, 0.0, 1.0)
	var target_roll := -steer * 0.09 * speed_frac * (1.6 if is_drifting else 1.0)
	var target_pitch := clampf(-velocity.y * 0.02, -0.15, 0.15) * speed_frac
	_visual.rotation.z = lerpf(_visual.rotation.z, target_roll, 8.0 * delta)
	_visual.rotation.x = lerpf(_visual.rotation.x, target_pitch, 5.0 * delta)

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Model 3D real daca exista in CarData; altfel placeholder din cuburi.
	if data != null and data.model != null:
		var model := data.model.instantiate() as Node3D
		model.scale = Vector3.ONE * data.model_scale
		model.rotation.y = deg_to_rad(data.model_rotation_deg)
		_visual.add_child(model)
		# Gasim rotile dupa nume, ca sa le animam (spin + viraj vizual).
		_wheels_all.clear()
		_wheels_front.clear()
		_wheel_orig.clear()
		for child in model.get_children():
			var child_name := String(child.name).to_lower()
			if child is Node3D and "wheel" in child_name:
				_wheels_all.append(child)
				_wheel_orig.append((child as Node3D).basis)
				if "front" in child_name:
					_wheels_front.append(child)
		if not _wheels_all.is_empty():
			# Raza reala = inaltimea centrului rotii (sta pe sol) x scala.
			_wheel_radius = maxf(0.15,
				_wheels_all[0].position.y * data.model_scale)
		return
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
