class_name ChaseCamera
extends Node3D
## Chase cam in stilul Ignition: DE SUS, cu masina mica in cadru.
##
## Trei incercari pana aici. Prima a fost in directia gresita: camera coborata la
## 6.8 m / 2.55 m (7°), crezand ca "Ignition" inseamna mai aproape de asfalt —
## dar aia e vederea din Need for Speed Underground, cu masina umpland cadrul.
## A doua a urcat-o la 8.4 / 4.61 (19°) si tot NFS a ramas, doar mai politicos.
##
## A treia a fost prima facuta cu poze puse una langa alta, nu din amintire
## (`tools/ProbeCam.tscn`, aceeasi bucata de cursa fotografiata cu cinci camere).
## Verdictul s-a vazut cel mai clar in acul de par cu stanca in mijloc de pe
## Dunele: la 19° stanca ACOPERA iesirea din viraj, deci conduci pe ghicite; la
## 28.7° se vede tot virajul, linia si unde ajungi. Camera e acum la
## **12.5 m / 10.0 m, 28.7° in jos**, pe TOT garajul (vezi distance_for/height_for).
##
## Doua lucruri invatate acolo, care nu se deduc din cifre:
##
##   1. **FOV-ul stramt strica exact ce castiga inaltimea.** Varianta de 52° arata
##      lumea ca pe o macheta frumoasa si moarta — teleobiectivul aplatizeaza si
##      linisteste imaginea, adica taie senzatia de viteza. Ramanem la 68°: sus,
##      dar larg.
##   2. **Jumatate din caracter e in cat de LENESA e camera, nu unde sta.** O
##      camera care se aseaza instant in spatele masinii citeste ca simulator.
##      Cu urmarirea incetinita (follow 3.6, aim 5.0) ramane in urma in viraj si
##      vezi masina din trei sferturi — exact silueta din Ignition.
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
## Coeficientii sunt cei vechi INMULTITI cu raportul de ridicare (x1.487 pe
## distanta, x2.167 pe inaltime), nu rescrisi de la zero: asa autobuzul ramane
## incadrat fata de muscle car exact ca inainte, si se muta doar camera.
const DISTANCE_BASE: float = 8.636
const DISTANCE_PER_M: float = 0.92
const HEIGHT_BASE: float = 8.068
const HEIGHT_PER_M: float = 0.46

static func distance_for(body_length: float) -> float:
	return DISTANCE_BASE + body_length * DISTANCE_PER_M

static func height_for(body_length: float) -> float:
	return HEIGHT_BASE + body_length * HEIGHT_PER_M

## Valorile de referinta ale camerei, citite si de tools/snapshot.gd --gamecam
## ca sa poata reproduce vederea de joc fara sa le duplice.
##
## ATENTIE: nu confunda astea cu MEASURE_* din snapshot.gd. Alea sunt inghetate
## pentru masuratori; astea se schimba cand tunam feel-ul camerei.
const DEFAULT_DISTANCE: float = 12.5   # = distance_for(REFERENCE_LENGTH)
const DEFAULT_HEIGHT: float = 10.0     # = height_for(REFERENCE_LENGTH)
const BASE_FOV: float = 68.0
## Cat de departe in fata priveste camera, si la ce inaltime pe masina.
##
## Lead-ul e a doua parghie de unghi dupa inaltime, si lucreaza INVERS: cu cat
## privesti mai departe in fata, cu atat cadrul se aplatizeaza. Aici e urcat la
## 5.0 m tocmai fiindca inaltimea a crescut mai mult — altfel camera ar privi
## aproape vertical in capota. Tinta ramane la nivelul butucului (0.40, nu 1.0):
## o camera de sus priveste SOLUL, nu plafonul.
const LOOK_AHEAD: float = 5.00
const LOOK_HEIGHT: float = 0.40

@export var distance: float = DEFAULT_DISTANCE
@export var height: float = DEFAULT_HEIGHT
## Cat de repede ajunge rig-ul din urma masina. 3.6, nu 5.0: lenea e jumatate
## din caracterul camerei (vezi antetul), iar de la inaltimea asta o urmarire
## rapida arata ca un drone shot lipit de bara din spate.
@export var follow_speed: float = 3.6
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
##
## Coborata de la 0.60 la 0.40 odata cu ridicarea camerei, si nu din alt motiv
## decat ca de sus se VEDE deja iesirea din viraj. Cand cadrul era ingust,
## privitul spre vectorul de viteza era singurul mod de a nu conduce orb intr-un
## drift; acum e doar o rasucire in plus peste una pe care ochiul o are gratis.
const AIM_VEL_WEIGHT: float = 0.40
## Cat de mult se muta POZITIA rig-ului spre acelasi vector. Mic intentionat:
## ancorarea pe viteza leagana rig-ul in drift si pierzi botul din cadru. Cu
## bratul mai lung (12.5 m), acelasi unghi inseamna mai multi metri de leganare,
## deci coboara la 0.12.
const ANCHOR_VEL_WEIGHT: float = 0.12
## Netezirea directiei de privire. Rezolva si problema veche "rotatia nu era
## netezita deloc" — look_at se recalcula instant in fiecare cadru. 5.0, nu 9.0:
## aceeasi lene ca la `follow_speed`, altfel rig-ul ramane in urma dar privirea
## se rasuceste instant, si iese exact senzatia de camera care se smuceste.
const AIM_SMOOTH: float = 5.0
## Sub viteza asta directia de deplasare e zgomot, ramanem pe bot.
const AIM_MIN_SPEED: float = 2.0

# --- reactie la viteza ---
## Cat se retrage camera la viteza maxima (fractie din distanta). 0.10, nu 0.18:
## fractia se aplica pe 12.5 m acum, nu pe 8.4, deci vechea valoare ar fi tras
## camera cu 2.25 m in spate — se pierdea masina, nu se castiga viteza.
const SPEED_PULLBACK: float = 0.10
## Inclinarea maxima in viraje. Ignition avea aproape deloc; peste 3° citeste ca
## simulator de zbor. La 28.7° in jos si un rig lenes, chiar si 2.5° era prea
## mult: rotatia de urmarire aduce deja miscare in cadru.
const ROLL_MAX_DEG: float = 1.2
## Viteza laterala (m/s) la care se atinge inclinarea maxima.
const ROLL_FULL_LATERAL: float = 12.0

## Cat urca FOV-ul de la viteza (grade, la viteza maxima). Redus la 8: de la 68°
## de baza, un salt de 12 impinge marginile in distorsiune de fisheye.
const FOV_SPEED_KICK: float = 8.0

## Cat de aproape de perete are voie sa ajunga camera cand e impinsa afara.
const CLIP_MARGIN: float = 0.45

## Parghiile de STIL, ca variabile si nu constante.
##
## Constantele de mai sus raman valorile implicite SI documentatia deciziei;
## exportarile exista ca `tools/probe_cam.gd` sa poata fotografia aceeasi bucata
## de cursa cu mai multe camere in aceeasi rulare de tuning. Fara ele, orice
## comparatie inseamna editat cod intre poze — adica tunat din amintire, nu din
## imagini puse una langa alta.
@export var look_ahead: float = LOOK_AHEAD
@export var look_height: float = LOOK_HEIGHT
@export var aim_vel_weight: float = AIM_VEL_WEIGHT
@export var anchor_vel_weight: float = ANCHOR_VEL_WEIGHT
@export var aim_smooth: float = AIM_SMOOTH
@export var speed_pullback: float = SPEED_PULLBACK
@export var roll_max_deg: float = ROLL_MAX_DEG
@export var fov_speed_kick: float = FOV_SPEED_KICK

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


## Panta camerei in pozitia de repaus. Ridicarea la viteza o pastreaza (vezi
## `_physics_process`), deci asta e UNGHIUL camerei, nu doar o valoare de start.
func _pitch_tan() -> float:
	return (height - look_height) / (distance + look_ahead)


## Acelasi unghi, in grade — cifra cu care se compara doua camere intre ele.
func pitch_degrees() -> float:
	return rad_to_deg(atan(_pitch_tan()))


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

	var anchor := fwd.slerp(vel_dir, anchor_vel_weight).normalized()
	var aim := fwd.slerp(vel_dir, aim_vel_weight).normalized()
	_aim_dir = _aim_dir.slerp(aim, 1.0 - exp(-aim_smooth * delta)).normalized()

	var speed_frac := clampf(target.horizontal_speed() / target.max_speed,
		0.0, 1.0)
	var d := distance * (1.0 + speed_pullback * speed_frac)
	# Ridicarea NU e un numar liber: e exact cat trebuie ca UNGHIUL sa ramana
	# constant cand camera se retrage. Derivata din pozitia de repaus, nu ghicita
	# — de asta vechea pereche (0.18 / 0.10) aplatiza cadrul cu 0.6° la viteza
	# maxima, exact invers decat pretindea comentariul de langa ea. Asa nu mai
	# poate putrezi: schimbi SPEED_PULLBACK si unghiul ramane.
	var h := look_height + (d + look_ahead) * _pitch_tan()

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
	var fov_target := base_fov + fov_speed_kick * speed_frac + boost_kick
	# exp, nu delta simplu: altfel viteza de tranzitie depinde de framerate
	# (pozitia era deja corecta, FOV-ul nu era).
	_cam.fov = lerpf(_cam.fov, fov_target, 1.0 - exp(-3.0 * delta))

	# Inclinare in viraje, pe CAMERA copil — rig-ului ii rescrie look_at baza in
	# fiecare cadru, deci un roll pus acolo ar disparea instant.
	var lateral := target.global_transform.basis.x.dot(vel)
	var roll := clampf(-lateral / ROLL_FULL_LATERAL, -1.0, 1.0) \
		* deg_to_rad(roll_max_deg)
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
