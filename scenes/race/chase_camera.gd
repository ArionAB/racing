class_name ChaseCamera
extends Node3D
## Chase cam in stilul Ignition: DE SUS, cu masina mica in cadru.
##
## Doua incercari pana aici, si prima a fost in directia gresita. Camera
## originala statea la 8.5 m / 3.5 m, cu 11° in jos si complet static. Am
## coborat-o la 6.8 / 2.55 (7°) crezand ca "Ignition" inseamna mai aproape de
## asfalt — dar aia e vederea din Need for Speed Underground: masina creste la
## 13% din latimea ecranului si umple cadrul.
##
## Directia s-a schimbat dupa mai multe runde de joc: nu "Ignition cu pista
## deschizandu-se la orizont", ci DRONA — camera aproape de masina si privind
## abrupt in jos (~42°). Pasii de feedback: 19° "prea din spate si prea jos" →
## 24° → 28° "vad prea mult in fata, vreau de sus ca o drona" → 4.5 / 6.6 /
## lead 2.2. Acelasi unghi pe TOT garajul — vezi distance_for/height_for.
##
## Camera priveste spre unde MERGE masina, nu spre unde e intoarsa: intr-un drift
## vezi iesirea din viraj, nu peretele spre care esti cu botul.
##
## Netezire: pozitia are intarziere exponentiala (lag-ul face virajele sa "se
## simta"), directia privirii are propria netezire. FOV creste cu viteza si sare
## la boost. Screen shake pe modelul "trauma" (shake = trauma^2, se stinge
## singur — impacturile mici abia se simt, cele mari zguduie serios).

## Lungimea masinii de referinta. style_bible §2 cere 4 m; garajul e la 4.2 dupa
## rescalare, iar formula de mai jos e calibrata pe valoarea asta.
const REFERENCE_LENGTH: float = 4.20

## Formula de incadrare, MUTATA AICI din race.gd.
##
## Inainte, race.gd avea propriile literale si suprascria distance/height la
## runtime, deci editarea constantelor de mai jos NU SCHIMBA NIMIC IN JOC — capcana
## in care am cazut o data deja, tunand o camera care nu rula. Acum exista o
## singura sursa, plus un assert in _ready care prinde divergenta.
const DISTANCE_BASE: float = 3.24
const DISTANCE_PER_M: float = 0.30
const HEIGHT_BASE: float = 4.92
const HEIGHT_PER_M: float = 0.40

static func distance_for(body_length: float) -> float:
	return DISTANCE_BASE + body_length * DISTANCE_PER_M

static func height_for(body_length: float) -> float:
	return HEIGHT_BASE + body_length * HEIGHT_PER_M

## Valorile de referinta ale camerei, citite si de tools/snapshot.gd --gamecam
## ca sa poata reproduce vederea de joc fara sa le duplice.
##
## ATENTIE: nu confunda astea cu MEASURE_* din snapshot.gd. Alea sunt inghetate
## pentru masuratori; astea se schimba cand tunam feel-ul camerei.
const DEFAULT_DISTANCE: float = 4.50   # = distance_for(REFERENCE_LENGTH)
const DEFAULT_HEIGHT: float = 6.60     # = height_for(REFERENCE_LENGTH)
const BASE_FOV: float = 70.0
## Cat de departe in fata priveste camera, si la ce inaltime pe masina.
##
## Lead-ul e cea mai puternica parghie de UNGHI, nu inaltimea. La 5.5 m cadrul
## se aplatiza la 7° (vedere de NFS Underground); la 3.4 m dadea 28° si tot
## "vedeai prea mult in fata" pentru vederea de drona ceruta. Cu 2.2 m si tinta
## la nivelul butucului (0.55, nu 1.0 — o camera de sus priveste SOLUL, nu
## plafonul) unghiul urca la ~42°, si asta e tot pe garaj, nu doar pe muscle car.
const LOOK_AHEAD: float = 2.20
const LOOK_HEIGHT: float = 0.55

@export var distance: float = DEFAULT_DISTANCE
@export var height: float = DEFAULT_HEIGHT
@export var follow_speed: float = 5.0
@export var base_fov: float = BASE_FOV

const MAX_SHAKE: float = 0.35 # metri de offset la trauma maxima

## Cat de departe deseneaza camera.
##
## Implicitul Godot e 4000m — desenam de zece ori mai departe decat se vede.
## Ceata inghite totul la 250m (Track._build_environment), iar cele mai
## indepartate siluete de la orizont stau la ~350m. La 380m nu se pierde nimic
## vizibil, dar frustumul nu mai plimba geometrie prin pipeline degeaba.
const FAR_PLANE: float = 380.0

# --- privire spre vectorul de viteza ---
## Cat de mult se muta TINTA PRIVIRII spre directia reala de deplasare.
## Mare, ca in drift sa vezi unde ajungi.
const AIM_VEL_WEIGHT: float = 0.60
## Cat de mult se muta POZITIA rig-ului spre acelasi vector. Mic intentionat:
## ancorarea pe viteza leagana rig-ul in drift si pierzi botul din cadru.
const ANCHOR_VEL_WEIGHT: float = 0.25
## Netezirea directiei de privire. Rezolva si problema veche "rotatia nu era
## netezita deloc" — look_at se recalcula instant in fiecare cadru.
const AIM_SMOOTH: float = 9.0
## Sub viteza asta directia de deplasare e zgomot, ramanem pe bot.
const AIM_MIN_SPEED: float = 2.0

# --- reactie la viteza ---
## Cat se retrage camera la viteza maxima (fractie din distanta).
const SPEED_PULLBACK: float = 0.18
## Inclinarea maxima in viraje. Ignition avea aproape deloc; peste 3° citeste ca
## simulator de zbor.
const ROLL_MAX_DEG: float = 2.5
## Viteza laterala (m/s) la care se atinge inclinarea maxima.
const ROLL_FULL_LATERAL: float = 12.0

## Cat de aproape de perete are voie sa ajunga camera cand e impinsa afara.
const CLIP_MARGIN: float = 0.45

var target: Car
var trauma: float = 0.0

var _cam: Camera3D
var _aim_dir: Vector3 = Vector3.FORWARD


func _ready() -> void:
	# Prinde exact divergenta de care am suferit: cine schimba coeficientii fara
	# sa actualizeze si constantele DEFAULT_* tuneaza o camera pe care jocul n-o
	# foloseste, iar snapshot-ul --gamecam ar minti.
	assert(is_equal_approx(DEFAULT_DISTANCE, distance_for(REFERENCE_LENGTH)),
		"DEFAULT_DISTANCE nu mai e distance_for(REFERENCE_LENGTH)")
	assert(is_equal_approx(DEFAULT_HEIGHT, height_for(REFERENCE_LENGTH)),
		"DEFAULT_HEIGHT nu mai e height_for(REFERENCE_LENGTH)")
	_cam = Camera3D.new()
	_cam.far = FAR_PLANE
	add_child(_cam)
	_cam.current = true


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var fwd := -target.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var vel := Vector3(target.velocity.x, 0.0, target.velocity.z)
	var vel_dir := fwd
	# Garda obligatorie: slerp intre vectori aproape OPUSI e instabil, iar AI-ul
	# da marsarier exact asa cand iese dintr-un blocaj. Atunci ramanem pe bot.
	if vel.length() > AIM_MIN_SPEED and fwd.dot(vel.normalized()) > -0.2:
		vel_dir = vel.normalized()

	var anchor := fwd.slerp(vel_dir, ANCHOR_VEL_WEIGHT).normalized()
	var aim := fwd.slerp(vel_dir, AIM_VEL_WEIGHT).normalized()
	_aim_dir = _aim_dir.slerp(aim, 1.0 - exp(-AIM_SMOOTH * delta)).normalized()

	var speed_frac := clampf(target.horizontal_speed() / target.max_speed,
		0.0, 1.0)
	var d := distance * (1.0 + SPEED_PULLBACK * speed_frac)
	# Ridicarea NU e un numar liber: e exact cat trebuie ca UNGHIUL sa ramana
	# constant cand camera se retrage. Derivata din pozitia de repaus, nu ghicita
	# — de asta vechea pereche (0.18 / 0.10) aplatiza cadrul cu 0.6° la viteza
	# maxima, exact invers decat pretindea comentariul de langa ea. Asa nu mai
	# poate putrezi: schimbi SPEED_PULLBACK si unghiul ramane.
	var pitch_tan := (height - LOOK_HEIGHT) / (distance + LOOK_AHEAD)
	var h := LOOK_HEIGHT + (d + LOOK_AHEAD) * pitch_tan

	var desired := target.global_position - anchor * d + Vector3.UP * h
	var t := 1.0 - exp(-follow_speed * delta) # urmarire independenta de fps
	global_position = global_position.lerp(desired, t)
	# Anti-clipping DUPA lerp, nu inainte: camera n-are voie sa fie niciodata in
	# perete, iar `desired` o impinge afara oricum, deci iesirea e lina de la sine.
	global_position = _unclip(target.global_position + Vector3.UP * LOOK_HEIGHT,
		global_position)
	_look_at_point(_aim_point(_aim_dir))

	# FOV: viteza + kick suplimentar cat tine boost-ul.
	var boost_kick := 6.0 if target.is_boosting else 0.0
	var fov_target := base_fov + 12.0 * speed_frac + boost_kick
	# exp, nu delta simplu: altfel viteza de tranzitie depinde de framerate
	# (pozitia era deja corecta, FOV-ul nu era).
	_cam.fov = lerpf(_cam.fov, fov_target, 1.0 - exp(-3.0 * delta))

	# Inclinare in viraje, pe CAMERA copil — rig-ului ii rescrie look_at baza in
	# fiecare cadru, deci un roll pus acolo ar disparea instant.
	var lateral := target.global_transform.basis.x.dot(vel)
	var roll := clampf(-lateral / ROLL_FULL_LATERAL, -1.0, 1.0) \
		* deg_to_rad(ROLL_MAX_DEG)
	_cam.rotation.z = lerpf(_cam.rotation.z, roll, 1.0 - exp(-6.0 * delta))

	# Shake in spatiul ecranului (h/v offset pe camera, nu pe rig).
	trauma = maxf(trauma - 1.8 * delta, 0.0)
	var shake := trauma * trauma
	_cam.h_offset = randf_range(-1.0, 1.0) * MAX_SHAKE * shake
	_cam.v_offset = randf_range(-1.0, 1.0) * MAX_SHAKE * shake


func snap_behind() -> void:
	if target == null:
		return
	var fwd := -target.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	global_position = target.global_position - fwd * distance \
		+ Vector3.UP * height
	# Aceeasi tinta ca in mers (prin _aim_point), altfel apare un salt de unghi
	# de un cadru dupa fiecare repunere — versiunea veche omitea lead-ul.
	_aim_dir = fwd
	_look_at_point(_aim_point(fwd))


## Punctul spre care priveste camera, pentru o directie data.
## Exista ca functie ca cele doua cai (mers si snap) sa nu poata diverge.
func _aim_point(dir: Vector3) -> Vector3:
	return target.global_position + Vector3.UP * LOOK_HEIGHT + dir * LOOK_AHEAD


## look_at cu garda: Godot da eroare daca tinta coincide cu pozitia camerei, iar
## asta chiar se poate intampla — o repunere poate ateriza masina in camera.
func _look_at_point(point: Vector3) -> void:
	if global_position.distance_squared_to(point) < 0.0025:
		return
	look_at(point, Vector3.UP)


## Trage camera in fata peretelui daca a ajuns in spatele lui.
##
## Falezele stau la 1.2m de asfalt, deci un brat de 6.8m intr-un ac de par e
## fizic IN piatra. Raycast-ul merge doar pe layer-ul de blocare (Track.
## CAMERA_BLOCKER_LAYER): pe layer-ul implicit ar lovi popice, mingea si
## celelalte masini, si fiecare depasire ar smuci cadrul cu metri.
##
## Deliberat NU SpringArm3D: ar cere restructurarea rig-ului (pozitie absoluta +
## netezirea deja tunata) intr-un lant parinte/brat/camera.
func _unclip(from: Vector3, to: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if space == null:
		return to
	var q := PhysicsRayQueryParameters3D.create(from, to,
		Track.CAMERA_BLOCKER_LAYER)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return to
	return (hit["position"] as Vector3).move_toward(from, CLIP_MARGIN)
