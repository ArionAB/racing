class_name Car
extends RigidBody3D
## Masina pe FIZICA INTREAGA (pivotul #261, integrata in joc la #258): un
## RigidBody3D sprijinit pe 4 raycasturi cu arc + amortizor, cate unul per
## roata. Ruliul, tangajul si legănarea peste denivelari ies din fizica, nu
## mai sunt efecte desenate. Comenzile vin de la un CarController (player sau
## AI), identitatea (statistici/culoare) dintr-un CarData — neschimbat.
##
## Ce ramane arcade, deliberat: directia scrie viteza unghiulara pe Y direct
## (un torque "realist" ar fi inca un etaj intre jucator si raspuns), grip-ul
## lateral e o forta de amortizare a vitezei laterale, plafonul de viteza e o
## contra-forta. Fortele de cauciuc se aplica LA SOL, nu in centrul de masa —
## de acolo vin ruliul in viraj, squat-ul la accelerare, dive-ul la frana.
##
## Compatibilitate: `velocity` si `is_on_floor()`/`get_floor_normal()` raman
## ca proprietate/metode-shim peste linear_velocity si suspensie, ca tot ce
## vorbeste cu masina (hazarde, sonde, AI) sa nu-si schimbe limbajul.
##
## Turbo model Ignition: o bara care se incarca in timp (mai repede in
## drift) si pe care o arzi CAND VREI TU tinand butonul de turbo — skill de
## decizie (pe ce dreapta, inaintea carei sarituri), nu de timing la viraj.
## Drift-ul e handbrake pur, iar pe fizica intreaga taie aderenta DOAR LA
## SPATE: fata tine, spatele aluneca — unghiul de derapaj e consecinta, nu
## simulare.

signal boost_started(car: Car)
signal wall_hit(car: Car, impact: float)
signal landed(car: Car, fall_speed: float)
signal respawned(car: Car)
## Izbitura cu o alta masina, cu delta-v-ul incasat de NOI — cu cat mai mare,
## cu atat mai violent contactul (shake, sunet).
signal bumped(car: Car, other: Car, delta_v: float)
## Strivit de un hazard. `severity` in 0..1, pentru shake proportional.
signal crushed(car: Car, severity: float)
## Lovit de o masa de apa (valul care spala digul). `strength` in 0..1.
##
## Semnal separat de `crushed` desi amandoua zguduie ecranul: `crushed` inseamna
## si turtire, si plafon de viteza taiat secunde intregi — un val nu te striveste,
## te uda si te impinge. Legate la acelasi semnal, ar fi trebuit tunate impreuna.
signal splashed(car: Car, strength: float)

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
## Pe fizica intreaga intra in PhysicsMaterial-ul corpului.
@export var bump_restitution: float = 0.35
## Plafon pe delta-v-ul incasat dintr-un contact cu alta masina (m/s).
## Solverul imparte impulsul dupa raportul maselor din constructie; peste
## plafon excedentul se taie PASTRAND directia — identitatea prin masa ramane,
## violenta scade. Inlocuieste bump_max_impulse de pe CharacterBody.
@export var bump_max_dv: float = 15.0
## Sub viteza asta de apropiere, contactul e frecare, nu izbitura: masinile care
## se ating mergand alaturi nu trebuie sa-si dea ghionturi.
@export var bump_min_closing: float = 2.5
## Cat nu mai emite ACEEASI pereche un al doilea semnal de bump. Doar pe
## semnal: impingerea fizica sustinuta o rezolva solverul, fara impulsuri
## repetate — catapultarile din vechiul cod nu mai au de unde sa apara.
@export var bump_pair_cooldown: float = 0.12
## Plafon pe rotatia primita dintr-o lovitura (rad/s). Necesar si pe fizica
## intreaga: directia scrie yaw-ul direct, deci rotatia data de solver ar fi
## STEARSA in cadrul urmator — o preluam in _impact_yaw (plafonat, se stinge
## singur) si o adunam peste comanda. Te sucesti, nu faci piruete.
@export var bump_yaw_max: float = 2.4
## Peste acest delta-v incasat, rotile pierd scurt aderenta laterala: lovitura
## se simte in directie, iar cel lovit isi prinde masina din alunecare.
@export var bump_slip_dv: float = 5.0

@export_group("Suspensie")
## Cursa arcului in repaus (m). Raza de cast = rest + wheel_radius.
@export var suspension_rest: float = 0.35
## Frecventa naturala a arcului (Hz). 2-3 = masina de strada arcade;
## rigiditatea se deriva din ea si din masa pe roata, deci tuning-ul nu
## depinde de cat cantareste corpul. Devine per masina in CarData la #260.
@export var spring_freq: float = 2.5
## Raportul de amortizare (1 = critic). 0.5-0.7 = revii asezat.
@export var damping_ratio: float = 0.6

# --- Stare de cursa (scrisa de Race) ---
var race_active: bool = false
## Pe grila, inainte de GO: corpul e INGHETAT (freeze), deci gravitatia nu
## curge si nimeni nu aluneca la vale in countdown — bug-ul din aug 2026,
## rezolvat pe rigid body din constructie.
##
## Flag SEPARAT de `race_active` desi amandoua sunt false in countdown, fiindca
## `race_active = false` are al doilea inteles: "scoasa din cursa de un hazard"
## (trenul si avalansa il folosesc pentru stun). Acolo fizica TREBUIE sa curga —
## trenul isi arunca victima cu corpul lui solid cat tine stun-ul. Un inghet
## legat de `race_active` ar fi stins tacut explozia trenului.
var on_start_grid: bool = false:
	set(value):
		on_start_grid = value
		freeze = value

## Shim de compatibilitate: CharacterBody3D avea `velocity` si tot ce vorbeste
## cu masina (hazarde, sonde, AI, kickere) il foloseste. Pe rigid body e
## acelasi lucru cu linear_velocity — proprietatea pastreaza limbajul.
var velocity: Vector3:
	get:
		return linear_velocity
	set(value):
		linear_velocity = value
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
var slip_time: float = 0.0 # aquaplanare (setata de WaterHazard sau de o banda uda)
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
## Invartirea de caroserie data de tromba — vezi spin_body().
var _spin_rate: float = 0.0
var _spin_left: float = 0.0
var _spin_angle: float = 0.0
var _drift_particles: CPUParticles3D
var _boost_particles: CPUParticles3D
## Praf de sub roti cand esti pe nisip. Separat de fumul de drift: fumul iese
## din cauciuc si e gri, praful e ridicat din SOL si ia culoarea temei.
var _dust_particles: CPUParticles3D
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
## instance_id-ul celeilalte masini -> secunde pana la urmatorul semnal admis.
var _bump_pairs: Dictionary = {}
## Rotatia (rad/s) primita dintr-o lovitura excentrica; se stinge singura si
## se ADUNA peste comanda de directie (care altfel ar sterge-o).
var _impact_yaw: float = 0.0

# --- Suspensia pe raycast (fizica intreaga) ---
## Compresia curenta a fiecarui arc [0, suspension_rest], ordinea FL FR RL RR.
var wheel_compression: Array[float] = [0.0, 0.0, 0.0, 0.0]
## Cate roti au atins solul in tick-ul curent (0-4).
var wheels_on_ground: int = 0
## Factor extern pe plafonul de viteza (crush-ul are al lui; asta e pentru
## sonde si hazarde care vor sa taie viteza fara sa stie de crush).
var speed_limit_factor: float = 1.0
## Raza rotii fizice (cast = rest + raza); se deriva din model in apply_data.
var _susp_wheel_radius: float = 0.30
## Colturile rotilor in spatiul masinii; din dimensiunile CarData.
var _wheel_points: Array[Vector3] = []
## Media punctelor de contact cu solul (offset fata de origine): AICI se
## aplica fortele de cauciuc — la sol, nu in centrul de masa. De aici ruliul
## in viraj, squat-ul la accelerare, dive-ul la frana.
var _contact_offset: Vector3 = Vector3.ZERO
## Acelasi lucru per axa (0 = fata, 1 = spate): driftul taie doar spatele.
var _axle_offset: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _axle_grounded: Array[int] = [0, 0]
## Normala medie a solului de sub roti (shim pentru get_floor_normal).
var _ground_normal: Vector3 = Vector3.UP
## Yaw-ul scris de NOI la finalul tick-ului trecut; diferenta la intrarea in
## tick = rotatia data de solver (lovitura excentrica).
var _commanded_yaw: float = 0.0
## Compresia statica (de repaus) a arcului — reperul fata de care rotile
## vizuale se ridica/coboara. Setata de _rebuild_suspension_geometry.
var _susp_static_comp: float = 0.11
## Pozitia originala a fiecarui nod de roata din model si coltul de suspensie
## de care apartine (0-3, FL FR RL RR in spatiul masinii).
var _wheel_orig_pos: Array[Vector3] = []
var _wheel_corner: Array[int] = []
var _skid_accum: float = 0.0
var _respawn_cooldown: float = 0.0

# Resurse partajate intre toate urmele de cauciuc (ieftin la instantiere).
static var _skid_mesh: PlaneMesh
static var _skid_mat: StandardMaterial3D

var _collision_shape: CollisionShape3D

func _ready() -> void:
	mass = 100.0 * mass_factor
	# Gravitatia proiectului e cea implicita (9.8); jocul cade cu `gravity`.
	var project_g: float = ProjectSettings.get_setting(
		"physics/3d/default_gravity", 9.8)
	gravity_scale = gravity / project_g
	# Centrul de masa sub origine: parghia care tine masina pe roti in viraj.
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, -0.15, 0.0)
	# Nu doarme niciodata: un corp adormit pe grila n-ar mai primi fortele
	# suspensiei si s-ar aseza pe colizer cand il trezeste contactul.
	can_sleep = false
	# Amortizarile globale raman mici: franarea reala vine din drag si grip.
	linear_damp = 0.0
	angular_damp = 0.5
	# Imbranceli: contactele se raporteaza (semnal + plafon), restitutia
	# arcade vine din material.
	contact_monitor = true
	max_contacts_reported = 8
	var pmat := PhysicsMaterial.new()
	pmat.bounce = bump_restitution
	pmat.friction = 0.4
	physics_material_override = pmat
	_build_visual()
	_build_effects()
	# Colizerul caroseriei NU atinge solul in mers (garda la sol o da
	# suspensia); exista pentru imbranceli si aterizari dure. Talpa lui sta la
	# +0.25 fata de origine (care e la nivelul solului): bordurile si dalele
	# sub inaltimea aia sunt treaba ROTILOR (raycasturile trec peste ele), nu
	# a caroseriei. Cu talpa la +0.1, ca pe CharacterBody, o dala de 16 cm era
	# un zid frontal — masurat cu testul de denivelari: masina se oprea in
	# prima dala in loc sa o calce. move_and_slide pasea peste; solverul nu.
	_collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	_collision_shape.shape = box
	_collision_shape.position = Vector3(0, 0.75, 0)
	add_child(_collision_shape)
	_rebuild_suspension_geometry(0.85, 1.45)


## Punctele de prindere ale arcurilor, din dimensiunile vehiculului.
##
## Inaltimea lor e aleasa EXACT astfel incat, la echilibru static, originea
## masinii sa cada la nivelul solului — acelasi contract ca pe CharacterBody.
## Toata aritmetica de efecte construita pe el (talpa colizerului la +0.1,
## urmele, umbra, pozitiile particulelor) ramane valabila fara nicio ajustare.
## Compresia statica nu depinde de masa: comp = g / omega^2.
func _rebuild_suspension_geometry(wheel_x: float, wheel_z: float) -> void:
	var omega := TAU * spring_freq
	_susp_static_comp = gravity / (omega * omega)
	var attach_h := suspension_rest + _susp_wheel_radius - _susp_static_comp
	_wheel_points = [
		Vector3(-wheel_x, attach_h, -wheel_z),
		Vector3(wheel_x, attach_h, -wheel_z),
		Vector3(-wheel_x, attach_h, wheel_z),
		Vector3(wheel_x, attach_h, wheel_z),
	]

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
	mass = 100.0 * mass_factor # identitatea prin masa, direct in solver
	body_color = data.color if color_override.a == 0.0 else color_override
	if _visual != null:
		_visual.queue_free()
	_build_visual()
	# Colizerul, suspensia si efectele urmeaza dimensiunile vehiculului.
	if _collision_shape != null:
		var box := _collision_shape.shape as BoxShape3D
		box.size = Vector3(data.body_width * 0.9, 1.0, data.body_length * 0.85)
	# Suspensia e IDENTITATE (#260): rigiditatea, amortizarea si cursa vin din
	# CarData — sportiva teapana, autobuzul moale si leganat. Raza fizica a
	# rotii vine din model (via _build_visual); ecartamentul si ampatamentul
	# din corpul masinii — autobuzul calca mai lat si mai lung.
	spring_freq = data.spring_freq
	damping_ratio = data.damping_ratio
	suspension_rest = data.suspension_rest
	_susp_wheel_radius = clampf(_wheel_radius, 0.22, 0.42)
	_rebuild_suspension_geometry(
		data.body_width * 0.42, data.body_length * 0.38)
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
		# stai pe ea. Refoloseste acelasi slip_time ca WaterHazard — un al doilea
		# mecanism de aquaplanare ar fi insemnat doua feluri de a pierde grip-ul,
		# care s-ar fi tunat separat si ar fi divergat.
		if track.route_is_wet(route):
			apply_slip(SLIP_GRIP_WET)

	# Pe grila de start corpul e INGHETAT (freeze, prin on_start_grid), deci
	# gravitatia nu curge si nimeni nu aluneca la vale in countdown — bug-ul
	# masurat in aug 2026 (3.9-5.0 m pe Dunele), rezolvat aici din constructie.
	# Efectele vizuale de mai jos ruleaza oricum: masina nu pare obiect mort.

	# Bilantul solverului INTAI, cat _prev_velocity e inca "ieri": ce s-a
	# schimbat intre tick-uri e opera coliziunilor, nu a fortelor noastre.
	_process_contacts(delta)

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

	_apply_suspension()

	var forward := -global_transform.basis.z
	var fwd_h := Vector3(forward.x, 0.0, forward.z).normalized()
	var fwd_speed := Vector3(velocity.x, 0.0, velocity.z).dot(fwd_h)

	_update_drift(drift_pressed, steer, fwd_speed)
	_update_turbo(turbo_pressed, delta)

	_apply_driving(steer, throttle, fwd_h, fwd_speed)

	slip_time = maxf(slip_time - delta, 0.0)
	crush_time = maxf(crush_time - delta, 0.0)
	if crush_time <= 0.0:
		crush_factor = 1.0
	_detect_landing()
	_update_visual_tilt(delta, steer, fwd_speed)
	_update_wheels(delta, steer, fwd_speed)
	_update_shadow()
	_update_effects(delta)
	_wall_cooldown = maxf(_wall_cooldown - delta, 0.0)
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)
	_respawn_cooldown = maxf(_respawn_cooldown - delta, 0.0)
	# Checkpoint: aici, cu roatele pe asfalt, eram in siguranta.
	if track != null and is_on_floor() \
			and track.is_on_road(road_index, global_position, route):
		last_safe_index = road_index
		last_safe_route = route
	# Reperele pentru bilantul urmatorului tick.
	_prev_velocity = velocity
	_commanded_yaw = angular_velocity.y


## Shim de compatibilitate: "pe sol" inseamna cel putin o roata cu contact.
func is_on_floor() -> bool:
	return wheels_on_ground > 0


## Shim de compatibilitate: normala medie a solului de sub roti.
func get_floor_normal() -> Vector3:
	return _ground_normal


## Un raycast per colt; arcul impinge LA COLT, si exact asta produce ruliul si
## tangajul: rotile incarcate imping mai tare decat cele usurate.
func _apply_suspension() -> void:
	wheels_on_ground = 0
	var contact_sum := Vector3.ZERO
	var normal_sum := Vector3.ZERO
	var axle_sum: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
	_axle_grounded = [0, 0]
	var space := get_world_3d().direct_space_state
	var up := global_transform.basis.y
	var cast_len := suspension_rest + _susp_wheel_radius
	# Rigiditatea pe roata din frecventa si masa pe roata (k = m(2*pi*f)^2),
	# amortizarea din raport — tuning independent de cat cantareste masina.
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
		normal_sum += hit.normal as Vector3
		axle_sum[axle] += hit.position as Vector3
		_axle_grounded[axle] += 1
		var dist := attach.distance_to(hit.position as Vector3)
		var compression := clampf(cast_len - dist, 0.0, suspension_rest)
		wheel_compression[i] = compression
		var offset := attach - global_position
		var point_vel := linear_velocity + angular_velocity.cross(offset)
		var spring_vel := point_vel.dot(up)
		var force_mag := k * compression - c * spring_vel
		# Arcul doar IMPINGE — daca ar si trage, orice creasta ar smulge
		# masina in jos nefiresc.
		if force_mag > 0.0:
			apply_force(up * force_mag, offset)
	if wheels_on_ground > 0:
		_contact_offset = contact_sum / float(wheels_on_ground) - global_position
		_ground_normal = normal_sum.normalized()
	for axle in 2:
		if _axle_grounded[axle] > 0:
			_axle_offset[axle] = axle_sum[axle] / float(_axle_grounded[axle]) \
				- global_position


## Motor, frana, plafon, drag si directie — ca FORTE, cu aceleasi reguli de
## feel. Fortele de cauciuc se aplica la punctele de contact (vezi nota de la
## _contact_offset); grip-ul lateral e per axa, ca driftul sa taie doar
## spatele.
func _apply_driving(steer: float, throttle: float,
		fwd_h: Vector3, fwd_speed: float) -> void:
	# Tractiunea cere contact: cu rotile in aer nu se accelereaza si nu se
	# vireaza. Drag-ul lipseste si el — lectia sariturii din aug 2026 (in aer
	# nu exista nicio rezistenta modelata) e pastrata de constructie.
	var ground_frac := float(wheels_on_ground) / 4.0
	if ground_frac == 0.0:
		return

	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	var vmax := _current_max_speed()

	# --- Motor / frana ---
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
	# lui move_toward(12.0) de pe CharacterBody. Central, nu la sol: e un
	# guvernator de joc, nu o forta fizica, n-are voie sa adauge tangaj.
	if fwd_speed > vmax:
		apply_central_force(-fwd_h * 12.0 * mass)

	# --- Rezistenta la rulare, doar pe sol ---
	apply_force(-hvel * drag * mass * ground_frac, _contact_offset)

	# --- Grip lateral, per axa: fata tine, spatele aluneca in drift ---
	for axle in 2:
		if _axle_grounded[axle] == 0:
			continue
		var grip_axle := grip
		if axle == 1 and is_drifting:
			grip_axle = drift_grip
		if slip_time > 0.0:
			grip_axle = slip_grip
		# Viteza laterala A AXEI (cu componenta din rotatie): spatele care se
		# roteste in jurul fetei chiar simte ca aluneca, si e amortizat acolo.
		var offset: Vector3 = _axle_offset[axle]
		var point_vel := linear_velocity + angular_velocity.cross(offset)
		var lat := Vector3(point_vel.x, 0.0, point_vel.z)
		lat -= fwd_h * lat.dot(fwd_h)
		var axle_frac: float = float(_axle_grounded[axle]) / 2.0
		apply_force(-lat * grip_axle * mass * 0.5 * axle_frac, offset)

	# --- Directia (amplificata si "impinsa" in directia drift-ului) ---
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var effective_steer := steer
	if is_drifting:
		effective_steer = clampf(
			steer * drift_steer_bonus + drift_dir * drift_bias, -1.6, 1.6)
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	var yaw_rate := effective_steer * steer_speed * speed_frac * reverse_sign
	# Comanda + rotatia ramasa din lovituri (se stinge singura, plafonata).
	angular_velocity = Vector3(
		angular_velocity.x, yaw_rate + _impact_yaw, angular_velocity.z)


## Bilantul contactelor raportate de solver: izbituri cu alte masini (plafon,
## rotatie, slip, semnal), pereti (wall_hit) si popice (imprastiate).
func _process_contacts(delta: float) -> void:
	var cars_hit: Array[Car] = []
	var static_hit := false
	for body in get_colliding_bodies():
		if body is Car:
			cars_hit.append(body as Car)
		elif body is RigidBody3D:
			# Popice & co: imprastiate cu un impuls scalat cu masa noastra —
			# autobuzul le trimite mai departe decat un sport.
			var dir := (body as Node3D).global_position - global_position
			dir.y = 0.0
			if dir.length_squared() < 0.01:
				dir = -global_transform.basis.z
			(body as RigidBody3D).apply_central_impulse(
				dir.normalized() * clampf(
					horizontal_speed() * 0.5 * mass_factor, 1.0, 16.0)
				+ Vector3.UP * 1.5)
		elif body is StaticBody3D:
			static_hit = true

	var dv_vec := velocity - _prev_velocity
	if not cars_hit.is_empty():
		var dv := dv_vec.length()
		# Plafonul de violenta: excedentul se taie pastrand DIRECTIA, deci
		# raportul de mase (identitatea) supravietuieste taierii.
		if dv > bump_max_dv:
			velocity = _prev_velocity + dv_vec * (bump_max_dv / dv)
			dv = bump_max_dv
		# Rotatia data de solver din lovitura excentrica, preluata cu plafon.
		var solver_yaw := angular_velocity.y - _commanded_yaw
		if absf(solver_yaw) > 0.1:
			_impact_yaw = clampf(_impact_yaw + solver_yaw,
				-bump_yaw_max, bump_yaw_max)
		# Lovitura mare pe lateral taie scurt aderenta (mecanismul de
		# aquaplanare, refolosit): un T-bone te face sa derapezi.
		var fwd := -global_transform.basis.z
		var fwd_hn := Vector3(fwd.x, 0.0, fwd.z).normalized()
		var lat_dv := (dv_vec - fwd_hn * dv_vec.dot(fwd_hn)).length()
		if lat_dv >= bump_slip_dv:
			slip_time = maxf(slip_time, clampf(0.15 + lat_dv * 0.02, 0.0, 0.55))
			slip_grip = SLIP_GRIP_WET
		# Semnalul, cu prag (frecarea nu e ghiont) si cooldown per pereche.
		if dv >= bump_min_closing:
			for other in cars_hit:
				var key := other.get_instance_id()
				if _bump_pairs.has(key):
					continue
				_bump_pairs[key] = bump_pair_cooldown
				bumped.emit(self, other, dv)
				if _bump_cooldown <= 0.0 and (is_player or other.is_player):
					_bump_cooldown = 0.25
					AudioManager.play_sfx(&"bump")
	elif static_hit:
		# Perete/bariera: impact = schimbarea ORIZONTALA de viteza (aterizarea
		# dura pe sol are dv vertical si nu e izbitura de perete).
		var dv_h := Vector3(dv_vec.x, 0.0, dv_vec.z).length()
		if dv_h > 8.0 and _wall_cooldown <= 0.0:
			_wall_cooldown = 0.35
			wall_hit.emit(self, dv_h)
			if is_player:
				AudioManager.play_sfx(&"wall_hit")

	for key: int in _bump_pairs.keys():
		var left := float(_bump_pairs[key]) - delta
		if left <= 0.0:
			_bump_pairs.erase(key)
		else:
			_bump_pairs[key] = left
	_impact_yaw *= exp(-4.0 * delta)
	if absf(_impact_yaw) < 0.05:
		_impact_yaw = 0.0


## Plafonul de viteza al momentului: taiat de iarba, ridicat de turbo.
## Turbo-ul merge SI pe iarba — scurtatura cu turbo e o alegere valida.
func _current_max_speed() -> float:
	var vmax := max_speed * speed_scale * speed_limit_factor
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

## Refresh-uit de WaterHazard cat timp esti in apa (conducta sau val).
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


## Am intrat intr-o masa de apa: doar semnalul (shake + orice mai asculta).
## Efectele pe fizica le aplica hazardul, ca sa ramana toate intr-un loc.
func splash(strength: float) -> void:
	splashed.emit(self, strength)

## Invarte caroseria in jurul verticalei, `duration` secunde. DOAR VIZUAL.
##
## Colizorul si directia de mers raman ale masinii, si asta e deliberat: o
## rotatie reala a lui `basis` in aer ar insemna ca aterizezi cu botul in alta
## parte decat merge viteza, adica un tete-a-queue pe care jucatorul nu l-a cerut
## si nu l-a putut evita. Tromba (`TyphoonHazard`) trebuie sa te SPERIE cat esti
## in aer, nu sa-ti schimbe traiectoria pe ascuns.
##
## Se stinge singura: cine o porneste n-are nimic de curatat, deci nici o
## repunere sau un abandon la mijlocul zborului nu lasa masina invartindu-se.
func spin_body(rate_rad_s: float, duration: float) -> void:
	_spin_rate = rate_rad_s
	_spin_left = duration


## Aruncat in aer de o creasta de fly-off. SETAM velocity.y, nu adunam: pe sol
## el e mereu readus la ~0 de move_and_slide, deci o adunare s-ar pierde.
func launch(up_speed: float) -> void:
	if velocity.y >= up_speed:
		return
	velocity.y = up_speed
	_punch_scale(Vector3(0.9, 1.18, 0.92)) # intinsa pe verticala la desprindere

# Imbrancelile, peretii si popicele: vezi _process_contacts — solverul imparte
# impulsul dupa masa, regulile arcade (plafon, rotatie, slip, semnal) se aplica
# peste bilantul lui.

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
	# Teleportare de corp rigid: si rotatia, si reperele bilantului de bump se
	# reseteaza — altfel saltul de pozitie ar citi ca "izbitura" (dv urias) si
	# ar declansa plafonari si semnale fantoma in primul tick de dupa.
	angular_velocity = Vector3.ZERO
	_prev_velocity = velocity
	_commanded_yaw = 0.0
	is_drifting = false
	is_boosting = false
	_spin_left = 0.0 # repusa pe sosea, nu mai e in tromba
	_forced_boost = 0.0
	slip_time = 0.0
	crush_time = 0.0
	crush_factor = 1.0
	_bump_pairs.clear() # am fost teleportati; vechile contacte nu mai exista
	_impact_yaw = 0.0 # nici rotatia din ultima izbitura nu ne urmareste
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
	# Suprafata de sub roti, aflata O DATA pe cadru: raspunsul il cer si urmele
	# de drift, si praful, si dara de rulare.
	var on_road := track != null \
		and track.is_on_road(road_index, global_position)
	var loose := _on_loose_ground(on_road)
	if is_drifting:
		_drift_particles.emitting = true
		# Cauciuc ars doar pe suprafata TARE. Pe pamant derapajul se vede in dara
		# de rulare si in norul de praf; o pata neagra lucioasa acolo ar fi
		# asfaltul care se vede prin drum.
		if not loose:
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
	_update_dust(on_road, loose)
	_drop_trail(delta, loose)
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
		# 0.4 alpha pe asfaltul nostru inchis abia se vedea (ProbeFx). 0.6 se
		# citeste clar si de la camera de joc, si dupa ce iesi din viraj.
		_skid_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.6)
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
		# Urma traieste destul cat sa o REVEZI: la un tur de ~55 s, 8 s inseamna
		# ca inca vezi urmele virajului cand privesti in urma, dar turul urmator
		# gaseste asfalt curat.
		tw.tween_interval(6.5)
		tw.tween_property(mark, "transparency", 1.0, 2.0)
		tw.tween_callback(mark.queue_free)
	# Limita de "juice": stergem urmele cele mai vechi.
	while skid_parent.get_child_count() > 160:
		skid_parent.get_child(0).free()

## Praful se ridica doar cand chiar zgarii solul: roti pe teren afanat si cu
## viteza. Fara pragul de viteza, o masina oprita pe nisip ar fumega la
## nesfarsit — si aia e fix imaginea care strica iluzia in loc s-o construiasca.
const DUST_MIN_SPEED: float = 6.0

## Solul de sub roti e AFANAT — nisip, pamant? De asta atarna si praful, si
## urmele lasate rulind.
##
## Pe majoritatea pistelor raspunsul e "doar in afara soselei": asfaltul e tare,
## marginea nu. Pe o pista cu drum de pamant (Track.road_surface) raspunsul e
## "peste tot", si asta e chiar rostul ei — nu mai exista panglica tare pe care
## sa te odihnesti, tot turul scoate praf.
func _on_loose_ground(on_road: bool) -> bool:
	if track == null or not is_on_floor():
		return false
	return track.road_is_loose() or not on_road

## Culorile prafului, coapte o data cand masina afla pe ce pista e: una a
## terenului, una a soselei. Cat timp soseaua era asfalt exista o singura
## suprafata pe care se ridica praf, deci si o singura culoare.
var _dust_ground_color: Color = Color.BLACK
var _dust_road_color: Color = Color.BLACK
var _dust_colors_ready: bool = false
## Ce culoare e pusa ACUM pe particule: -1 niciuna, 0 teren, 1 sosea.
var _dust_source: int = -1

func _update_dust(on_road: bool, loose: bool) -> void:
	if _dust_particles == null or track == null:
		return
	if not _dust_colors_ready:
		_dust_colors_ready = true
		# Praful de pe TEREN: mai INCHIS decat solul, nu mai deschis. Prima
		# versiune folosea lightened(0.22) si ProbeFx a aratat rezultatul: alb pal
		# pe nisip luminat = invizibil. Contrastul care se citeste ca praf e cel
		# al unei umbre usoare.
		_dust_ground_color = track.theme_ground_tint.darkened(0.12)
		# Praful de pe SOSEA merge exact invers, din acelasi motiv: contrastul,
		# nu luminozitatea. Drumul de pamant e cea mai inchisa suprafata de sub
		# roti, deci un nor si mai inchis peste el ar fi invizibil la fel de sigur
		# cum era cel alb pe nisip.
		_dust_road_color = track.road_dust_color().lightened(0.18)
	var live := loose and horizontal_speed() > DUST_MIN_SPEED
	_dust_particles.emitting = live
	if not live:
		return
	var src := 1 if on_road else 0
	if src != _dust_source:
		_dust_source = src
		var tint := _dust_road_color if src == 1 else _dust_ground_color
		_dust_particles.color = tint
		# Si fumul de drift: pe pamant nu arde cauciucul, se ridica solul. Gri de
		# anvelopa peste o dara rosie ar fi singurul lucru din cadru care spune
		# ca dedesubt e tot asfalt.
		_drift_particles.color = tint if track.road_is_loose() \
			else DRIFT_SMOKE_COLOR
	# Norul creste cu viteza: la 6 m/s e o adiere, la plafon e o dara adevarata.
	var k := clampf(horizontal_speed() / maxf(max_speed, 1.0), 0.0, 1.0)
	_dust_particles.initial_velocity_max = lerpf(2.5, 7.0, k)
	_dust_particles.lifetime = lerpf(0.75, 1.35, k)


## Cat de des se depune o urma de rulare, in metri parcursi. 2.2 m cu placute de
## 2.4 m (SandTrail.MARK_SIZE) inseamna suprapunere, deci dara e continua.
const TRAIL_SPACING: float = 2.2
## Sub viteza asta nu se depune nimic: o masina care abia se misca prin nisip tot
## lasa urme, una oprita nu — si mai ales nu vrem sa tapetam gridul de start.
const TRAIL_MIN_SPEED: float = 3.0
## Cat de sus peste SOL sta placuta — nu peste originea masinii.
##
## ############################################################################
## Distinctia asta a costat o vanatoare intreaga: urmele se depuneau, cu pozitii
## corecte, si nu se vedea niciuna.
##
## Originea unui Car NU e la nivelul solului. Colizorul e o cutie de 1 m inalta,
## asezata la +0.6 (vezi _ready), deci talpa ei — punctul care atinge drumul —
## sta la +0.1 fata de origine. O placuta ridicata cu 0.05 "peste masina" ajungea
## astfel cu 5 cm SUB asfalt.
##
## Peste asta se aduna coroana soselei: suprafata VIZIBILA a drumului e bombata
## cu pana la Track.ROAD_CROWN (0.03) peste cea de COLIZIUNE, pe care calca
## roata. Adica exact pe banda de rulare, unde stau urmele, drumul desenat trece
## peste drumul pipait — aceeasi capcana care ingropase si urmele coapte in
## pista (vezi Track._build_tire_marks).
##
## De-aia inaltimea se calculeaza din talpa colizorului (_hull_bottom), iar
## constanta de mai jos e doar MARJA peste sol: coroana plus ce trebuie ca
## placuta sa nu clipeasca in ea pe denivelari.
## ############################################################################
const TRAIL_LIFT: float = 0.08

## Cat de sus fata de originea masinii e SOLUL. Pe fizica intreaga originea
## sta chiar la nivelul solului prin constructia suspensiei (vezi
## _rebuild_suspension_geometry), deci nu se mai deriva din talpa colizerului
## — aia s-a ridicat la +0.25 ca bordurile sa fie treaba rotilor, si ar fi
## tras urmele de rulare in aer.
func _hull_bottom() -> float:
	return 0.02


## Dara de urme lasata rulind pe teren afanat. Creata la prima nevoie: pe o pista
## cu asfalt care nu iese niciodata de pe drum nu se aloca nimic.
var _trail: SandTrail
var _trail_accum: float = 0.0

## Urme de rulare — DIFERITE de urmele de drift, si asta e tot rostul lor.
##
## Urma de drift e cauciuc ars pe asfalt: apare doar cu handbrake-ul tras, e
## neagra si dispare in 8 secunde. Urma de rulare e sant in pamant moale: apare
## din simplul fapt ca ai trecut pe acolo si ramane pana o rescrie inelul. Cele
## doua nu apar niciodata pe aceeasi suprafata (vezi _update_effects).
func _drop_trail(delta: float, loose: bool) -> void:
	if not loose:
		return
	var speed := horizontal_speed()
	if speed < TRAIL_MIN_SPEED:
		return
	_trail_accum += speed * delta
	if _trail_accum < TRAIL_SPACING:
		return
	_trail_accum = 0.0
	# Baza urmei sta pe PANTA, nu pe orizontala: y-ul placutei urmeaza normala
	# solului, iar directia de mers se proiecteaza pe planul ei.
	var up := get_floor_normal()
	if up.length_squared() < 0.5:
		up = Vector3.UP
	var fwd := -global_transform.basis.z
	fwd -= up * fwd.dot(up)
	if fwd.length_squared() < 0.001:
		return # masina exact perpendiculara pe panta: nu exista "inainte" pe ea
	fwd = fwd.normalized()
	var right := fwd.cross(up).normalized()
	if _trail == null:
		_trail = SandTrail.new()
		# Nuanta brazdei tine de suprafata, nu de masina: materialul e partajat,
		# deci o singura culoare pe pista (vezi SandTrail.set_surface_color).
		SandTrail.set_surface_color(track.trail_surface_color())
		add_child(_trail)
	var half_track_w := data.body_width * 0.38 if data != null else 0.85
	var rear_z := data.body_length * 0.34 if data != null else 1.3
	# Rotile din SPATE: pe o linie dreapta ele calca peste urma celor din fata,
	# deci doua fasii, nu patru.
	var base := global_position - fwd * rear_z \
		+ up * (_hull_bottom() + TRAIL_LIFT)
	var orientation := Basis(right, up, -fwd)
	for side: float in [-1.0, 1.0]:
		_trail.stamp(base + right * half_track_w * side, orientation)

## Fum de cauciuc ars. Pe drum de pamant se inlocuieste cu praful solului —
## vezi _update_dust.
const DRIFT_SMOKE_COLOR: Color = Color(0.78, 0.78, 0.8)

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
	_drift_particles.color = DRIFT_SMOKE_COLOR
	# Sfera cu putine laturi, nu cub: particulele-cuburi erau una din cele trei
	# cauze ale lui "parca am facut racing in Minecraft" (feedback direct).
	# 24 de triunghiuri bucata, cu segmentele setate — vezi regula din CLAUDE.md.
	var smoke := SphereMesh.new()
	smoke.radius = 0.14
	smoke.height = 0.28
	smoke.radial_segments = 6
	smoke.rings = 3
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.vertex_color_use_as_albedo = true # ia culoarea din particula
	smoke_mat.vertex_color_is_srgb = true # altfel gri 0.78 citit liniar = alb
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.material = smoke_mat
	_drift_particles.mesh = smoke
	add_child(_drift_particles)

	# Praf ridicat de sub roti pe off-road. Emite din SPATELE masinii, la nivelul
	# solului — sursa e contactul rotii cu nisipul, nu evacuarea.
	#
	# Buget: 26 de particule per masina, 130 pe o cursa de 5. Prima versiune avea
	# 18 mici si palide si sonda vizuala (ProbeFx) a aratat de ce nu le vedea
	# nimeni: o dara punctata de cuburi, nu un nor.
	_dust_particles = CPUParticles3D.new()
	# Nume propriu ca sondele sa-l poata gasi: ProbeFx verifica praful si dara
	# impreuna, iar pana acum singurul mod de a-l deosebi de fumul de drift era
	# sa te iei dupa `amount`.
	_dust_particles.name = "Dust"
	_dust_particles.position = Vector3(0, 0.12, 1.7)
	_dust_particles.emitting = false
	_dust_particles.amount = 26
	_dust_particles.lifetime = 1.15
	_dust_particles.direction = Vector3(0, 1, 0.6)
	_dust_particles.spread = 45.0
	_dust_particles.initial_velocity_min = 1.5
	_dust_particles.initial_velocity_max = 4.0
	# Gravitatie usor negativa: praful se ridica si se lasa, nu tasneste ca fumul.
	_dust_particles.gravity = Vector3(0, -1.2, 0)
	_dust_particles.damping_min = 1.5
	_dust_particles.damping_max = 3.0
	_dust_particles.scale_amount_min = 1.2
	_dust_particles.scale_amount_max = 3.0
	# Se stinge in transparenta pe durata vietii; fara asta, norul dispare brusc.
	# CPUParticles3D vrea un Gradient direct, nu un GradientTexture1D — ala e
	# pentru varianta GPU.
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.72))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	_dust_particles.color_ramp = fade
	# Culoare provizorie; cea reala vine din tema, in _update_dust, de indata ce
	# masina stie pe ce pista e. Praf nisipiu pe iarba ar fi exact genul de
	# detaliu care se observa fara sa stii de ce te deranjeaza.
	_dust_particles.color = Palette.color(Palette.SAND_MID).darkened(0.12)
	var puff := SphereMesh.new()
	puff.radius = 0.26
	puff.height = 0.52
	puff.radial_segments = 6
	puff.rings = 3
	var puff_mat := StandardMaterial3D.new()
	puff_mat.vertex_color_use_as_albedo = true
	# Culorile noastre sunt autorate ca sRGB (Color.html, Palette). Fara steagul
	# asta, Godot le citeste ca LINIARE si le scoate cu ~1.5 trepte mai deschise:
	# #BB8744 randa (241,218,177) — crem pal, masurat cu ProbeFx. De-aia praful
	# parea alb oricat il inchideam la sursa.
	puff_mat.vertex_color_is_srgb = true
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Fara scriere in depth: norii se suprapun fara sa se taie unul pe altul.
	puff_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	puff.material = puff_mat
	_dust_particles.mesh = puff
	add_child(_dust_particles)

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
	var flame := SphereMesh.new()
	flame.radius = 0.11
	flame.height = 0.22
	flame.radial_segments = 6
	flame.rings = 3
	var flame_mat := StandardMaterial3D.new()
	flame_mat.vertex_color_use_as_albedo = true
	flame_mat.vertex_color_is_srgb = true
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

## Rotile se invart cu viteza reala (unghi = viteza / raza), cele din fata se
## intorc spre directia de viraj, si TOATE urmaresc compresia reala a arcului
## lor: pe denivelari fiecare roata urca singura, in aer atarna la
## destinderea completa. Vizualul citeste fizica, nu o mimeaza.
func _update_wheels(delta: float, steer: float, fwd_speed: float) -> void:
	if _wheels_all.is_empty():
		return
	_wheel_spin = fposmod(_wheel_spin + fwd_speed / _wheel_radius * delta, TAU)
	_wheel_steer = lerpf(_wheel_steer, steer * 0.42, 10.0 * delta)
	var spin_basis := Basis(Vector3.RIGHT, _wheel_spin)
	var inv_scale := 1.0 / maxf(data.model_scale if data != null else 1.0, 0.001)
	for idx in _wheels_all.size():
		var wheel := _wheels_all[idx]
		var anim := spin_basis
		if wheel in _wheels_front:
			anim = Basis(Vector3.UP, _wheel_steer) * spin_basis
		# Compunem PESTE transformarea originala, nu in locul ei.
		wheel.basis = anim * _wheel_orig[idx]
		# Mai multa compresie = roata mai sus fata de caroserie (distanta de la
		# prindere la centrul rotii e rest - compresie). Offsetul e in spatiul
		# modelului, deci impartit la scala.
		if idx < _wheel_corner.size():
			var corner: int = _wheel_corner[idx]
			var lift := (wheel_compression[corner] - _susp_static_comp) \
				* inv_scale
			wheel.position.y = _wheel_orig_pos[idx].y + lift

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
	# Pe fizica intreaga, CORPUL insusi se inclina: panta, ruliul, squat-ul si
	# dive-ul vin din suspensie, nu mai e nimic de desenat. Toata istoria
	# fake-pitch-ului (botul in sus la coborare, pivotul pe axul rotilor — vezi
	# git blame pe blocul asta) a murit odata cu CharacterBody3D.
	#
	# Ce ramane pe _visual: un STROP de ruliu suplimentar in drift — juice-ul
	# care vinde alunecarea, calibrat mic ca sa nu se bata cu ruliul fizic —
	# si invartirea de tromba (_update_spin), care e doar vizuala prin design.
	var speed_frac := clampf(fwd_speed / max_speed, 0.0, 1.0)
	var target_roll := -steer * 0.05 * speed_frac * (1.6 if is_drifting else 0.0)
	_visual.rotation.z = lerpf(_visual.rotation.z, target_roll, 8.0 * delta)
	_update_spin(delta)


## Invartirea de caroserie, cat tine si pe urma inapoi la zero.
##
## Axa Y e singura libera: `_update_visual_tilt` scrie in fiecare cadru pe Z
## (inclinarea in viraj) si pe X (botul in aer), deci orice ar pune altcineva
## acolo ar fi sters in cadrul urmator. Pe Y nu scrie nimeni.
func _update_spin(delta: float) -> void:
	if _spin_left > 0.0:
		_spin_left -= delta
		_spin_angle = wrapf(_spin_angle + _spin_rate * delta, -PI, PI)
	elif not is_zero_approx(_spin_angle):
		# Botul se intoarce in fata la aterizare. O masina lasata strambă dupa ce
		# atinge solul citeste ca bug de rotatie, nu ca urmare a trombei.
		_spin_angle = lerp_angle(_spin_angle, 0.0, minf(7.0 * delta, 1.0))
		if absf(_spin_angle) < 0.01:
			_spin_angle = 0.0
	_visual.rotation.y = _spin_angle

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Model 3D real daca exista in CarData; altfel placeholder din cuburi.
	if data != null and data.model != null:
		var model := data.model.instantiate() as Node3D
		model.scale = Vector3.ONE * data.model_scale
		model.rotation.y = deg_to_rad(data.model_rotation_deg)
		_visual.add_child(model)
		# Gasim rotile dupa nume, ca sa le animam (spin + viraj + compresie).
		_wheels_all.clear()
		_wheels_front.clear()
		_wheel_orig.clear()
		_wheel_orig_pos.clear()
		_wheel_corner.clear()
		for child in model.get_children():
			var child_name := String(child.name).to_lower()
			if child is Node3D and "wheel" in child_name:
				var wheel_node := child as Node3D
				_wheels_all.append(wheel_node)
				_wheel_orig.append(wheel_node.basis)
				_wheel_orig_pos.append(wheel_node.position)
				var is_front := "front" in child_name
				if is_front:
					_wheels_front.append(wheel_node)
				# Coltul de suspensie al rotii vizuale. Modelul e rotit 180°
				# (privea spre +Z), deci stanga masinii = +x in spatiul
				# modelului — de-aia conditia pare inversata.
				var car_left := wheel_node.position.x > 0.0
				var axle := 0 if is_front else 1
				_wheel_corner.append(axle * 2 + (0 if car_left else 1))
		if not _wheels_all.is_empty():
			# Raza reala = inaltimea centrului rotii (sta pe sol) x scala.
			_wheel_radius = maxf(0.15,
				_wheels_all[0].position.y * data.model_scale)
		# Pe fizica intreaga pivotul vizual nu mai conteaza: corpul intreg se
		# inclina fizic in jurul propriului centru de masa, iar modelul sta
		# simplu la origine. Hack-ul "pivot pe axul rotilor" de pe
		# CharacterBody a murit odata cu fake-pitch-ul.
		return
	# Placeholder din cuburi, cand masina n-are model in CarData.
	_wheel_radius = 0.48
	_add_box(Vector3(2.2, 0.7, 3.6), Vector3(0, 0.55, 0), body_color)
	_add_box(Vector3(1.6, 0.55, 1.7), Vector3(0, 1.1, 0.2),
		body_color.darkened(0.5))
	_add_box(Vector3(2.3, 0.18, 0.7), Vector3(0, 0.9, 1.85),
		body_color.darkened(0.25))
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
