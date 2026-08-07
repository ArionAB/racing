@tool
class_name TyphoonHazard
extends Node3D
## Mini-typhoon-ul care rataceste peste sosea: te ridica in aer si te lasa
## inapoi pe asfalt cateva zeci de metri mai incolo.
##
## ############################################################################
## CE FEL DE HAZARD E ASTA, si de ce nu seamana cu niciunul de pana acum
##
## Pe pista mai sunt trei familii, si tromba nu intra in niciuna:
##   - podul si trenul te OPRESC daca gresesti (gol in asfalt, bariera);
##   - valul si furtunul iti TAIE GRIP-UL (banda uda);
##   - bariera mobila si deflectorul te IMPING lateral.
## Tromba nu face nimic din astea: te SCOATE DIN JOC PENTRU O SECUNDA SI JUMATATE.
## Nu pierzi controlul, pierzi contactul — si odata cu el franele, virajul si
## incarcarea barei de turbo. Pedeapsa e in TIMP si in linie, nu in viteza.
##
## De aia si aterizarea e garantata pe sosea (vezi `_steer_lofted`). Un hazard
## care te ridica 15 m si te lasa unde nimereste ar fi o rulare de zaruri: din
## aer nu poti corecta nimic, deci ce urmeaza nu mai e conducere. Asa, tromba
## iti ia secunda si atat — cine pierde cursa din cauza ei a pierdut-o fiindca
## n-a citit ceasul, nu fiindca a avut ghinion la aterizare.
##
## Decizia pe care o pune: tromba traverseaza soseaua inainte si inapoi, cu
## viteza constanta. O vezi de la 200 m (are 18 m inaltime — vezi mai jos de ce
## exact atat). Intrebarea e daca fortezi trecerea inaintea ei sau ridici
## piciorul o clipa si o lasi sa treaca. Turbo-ul e exact parghia: cu bara plina
## treci, fara ea calculezi.
## ############################################################################

const MODEL_PATH := "res://assets/models/effects/typhoon.glb"
const FUNNEL_NODE := "Typhoon"
const DEBRIS_NODE := "Typhoon_Debris"

## Inaltimea palniei, IDENTICA cu HEIGHT din tools/blender/build_typhoon.py.
##
## NU e o cifra de stil, e derivata din camera si e verificata de
## tools/probe_typhoon.gd. `ChaseCamera` priveste in jos cu 28.75°, iar cu FOV-ul
## vertical de 68° raza de sus a frustumului urca doar 5.25° peste orizontala —
## o camera inclinata in jos are foarte putin cer in cadru. La 18 m, tromba
## INTREAGA incape in ecran de la ~37 m in fata la viteza de varf si de la ~75 m
## in cea mai stramta stare a camerei; abia in ultima secunda incepe sa-i iasa
## varful din cadru, si atunci trebuie sa se simta ca te inghite. Detaliile si
## tabelul complet: antetul lui build_typhoon.py.
const FUNNEL_HEIGHT: float = 18.0

# ------------------------------------------------------------------- ciclul
## Cat dureaza o traversare completa, dus-intors.
##
## 11 s, nu 5-6: la o perioada scurta tromba devine un metronom pe care il
## astepti, si sectorul se transforma in slalom. Asa, un tur normal prinde una
## sau doua treceri — deci fiecare e o intrebare, nu o taxa.
const PERIOD: float = 11.0
## Cat de tare se apleaca palnia in directia de mers (radiani).
##
## Fara ea, o tromba care se translateaza perfect vertical arata ca un burghiu pe
## sine. Inclinarea se pune pe SUPORTUL modelului, nu pe radacina: radacina tine
## si zona de prindere, iar o zona de prindere inclinata ar insemna ca te prinde
## de la o distanta pe o parte si de la alta pe cealalta, fara ca nimic din ce
## vezi sa explice de ce.
const LEAN: float = 0.11
## Rotatia palniei si a gulerului de moloz (rad/s).
##
## Diferite intentionat, si molozul mai incet: doua corpuri de revolutie rotite
## la unison citesc ca un singur obiect rigid. La viteze diferite, ochiul vede
## turbulenta. Acelasi motiv pentru care sunt doua noduri in GLB.
const SPIN_FUNNEL: float = 8.8
const SPIN_DEBRIS: float = 3.4

# ----------------------------------------------------------------- prinderea
## Dincolo de raza asta nu se intampla nimic.
const CATCH_RADIUS: float = 7.0
## Sub raza asta esti in ochi: ridicare maxima.
const CORE_RADIUS: float = 2.6
## Cat de sus deasupra soselei se poate intinde mana tromba. Peste atat treci pe
## deasupra — adica o saritura bine plasata chiar te scapa, si asta e un lucru pe
## care merita sa-l descopere cineva singur.
const CATCH_TOP: float = 6.0
## Cat de sus te ridica: la marginea razei si in ochi.
##
## Din ele iese viteza verticala prin `sqrt(2*g*h)`, nu invers. Cu g = 28: 5 m
## inseamna 16.7 m/s si 1.2 s in aer, 15 m inseamna 29.0 m/s si 2.1 s. Doua
## secunde fara contact e enorm pentru jocul asta (creasta de fly-off plafoneaza
## la ~12 m/s, adica 2.6 m) — de-aia maximul se ia doar in ochi.
const LIFT_MIN: float = 5.0
const LIFT_MAX: float = 15.0
## Cat pastrezi din viteza orizontala cand esti smuls.
##
## Nu 1.0 si nu 0.0. Cu 1.0, doua secunde de zbor la 34 m/s inseamna 68 m de
## sosea parcursi fara sa conduci — pe un viraj, tromba ar deveni scurtatura. Cu
## 0.0 aterizezi mort si pierzi patru secunde, adica cursa. 0.62 lasa pedeapsa in
## timp si-i pastreaza spectacolul.
const SPEED_KEEP: float = 0.62
## Cat de repede te invarte tromba in aer (rad/s), doar vizual.
const SPIN_CAR: float = 7.5

# ------------------------------------------------------ curentul de aterizare
## Cat de departe in fata pe axa soselei tinteste curentul care te tine deasupra
## asfaltului.
const STEER_AHEAD: float = 22.0
## Cat de repede corecteaza (fractie pe secunda din diferenta).
const STEER_RATE: float = 2.6
## Peste atatea secunde tromba te lasa in pace chiar daca inca esti in aer.
## Plasa de siguranta: fara ea, o masina care ateriza pe un acoperis ar fi ramas
## sub curent pe restul cursei.
const LOFT_MAX_TIME: float = 2.8
## Cat se asteapta pana se crede ca `is_on_floor()` inseamna aterizare. In cadrul
## in care te-a smuls, masina inca e pe sol.
const LOFT_GRACE: float = 0.30
## Cat nu te mai poate prinde dupa ce te-a lasat jos. Fara el, o tromba care se
## intoarce peste tine in aceeasi trecere te-ar tine in aer la nesfarsit.
const CATCH_COOLDOWN: float = 3.5

# ------------------------------------------------------------------ particule
const SAND_COUNT: int = 40
const LEAF_COUNT: int = 20
const SPRAY_COUNT: int = 28

# ------------------------------------------------------------------ parametri
## Latimea soselei acolo (jumatate). Din ea ies raza de maturat si tinta
## curentului de aterizare.
@export var road_half_width: float = 7.0
## Cat de departe se duce tromba de o parte si de alta a axei soselei.
@export var sweep: float = 22.0
## Defazaj 0..1, ca doua trombe de pe aceeasi pista sa nu bata la unison.
@export var phase: float = 0.0
## Directia in care matura (versor orizontal, perpendicular pe sosea).
@export var travel_dir: Vector3 = Vector3.RIGHT
## Cota apei, in spatiul PARINTELUI (adica al pistei) — nu al trombei.
##
## Podul mobil isi primeste cota apei relativ la el insusi, fiindca acolo tot ce
## se construieste sunt copii ai podului. Aici e invers: singurul lucru care se
## compara cu apa e `position`, care e in spatiul parintelui. O cota relativa
## ar fi trebuit convertita inapoi la fiecare comparatie, si prima conversie
## uitata ar fi asezat talpa cu zeci de metri gresit — tacut, fiindca ambele
## numere arata la fel intr-un print.
##
## Sub ea nu coboara talpa palniei: peste mare tromba devine trâmbă de apa si sta
## pe luciu, nu pe fund.
@export var water_y: float = 0.0

var _model: Node3D
var _funnel: Node3D
var _debris: Node3D
var _eye: Area3D
var _sand: CPUParticles3D
var _leaves: CPUParticles3D
var _spray: CPUParticles3D
var _audio: AudioStreamPlayer3D
var _time: float = 0.0
## Punctul pe care a fost asezata tromba, in spatiul PARINTELUI. Traversarea se
## socoteste fata de el.
##
## Nu e un detaliu, si valul a facut deja greseala: `wave_surge.gd` scria in
## fiecare cadru `position = travel_dir * offset + ...`, adica ARUNCA pozitia pe
## care i-o daduse pista la constructie si matura in jurul originii pistei, nu in
## jurul sectorului. Pe Track05 nu s-a vazut fiindca sectorul cu val e aproape de
## origine. Tromba nu-si permite: e pe Okinawa, la jumatate de tur de origine, si
## are 18 m. Valul si-a luat intre timp ancora proprie, dupa modelul asta.
var _anchor: Vector3 = Vector3.ZERO
## Ultima cota buna a talpii. Punctul de plecare e cota la care a fost asezata
## tromba — adica soseaua — deci pana la prima raza reusita sta pe drum, care e
## si locul in care o pune pista. Vezi `_ground_y`.
var _foot_y: float = 0.0
## Masinile aflate sub curent, si de cat timp. Cheia e masina, ca la pod.
var _lofted: Dictionary = {}
var _cooldown: Dictionary = {}
## Materialul comun al tuturor particulelor. Static: garda numara materialele per
## pista (vezi CLAUDE.md), iar trei sisteme de particule cu trei materiale ar fi
## insemnat trei intrari pentru un singur efect.
static var _dust_mat: StandardMaterial3D


func _ready() -> void:
	_anchor = position
	_foot_y = position.y
	_build_model()
	_build_eye()
	_build_particles()
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	# Raza mare intentionat: vuietul e jumatate din telegrafiere. Il auzi
	# crescand inainte sa te uiti dupa el.
	_audio.max_distance = 220.0
	_audio.unit_size = 24.0
	add_child(_audio)
	if not Engine.is_editor_hint():
		_start_roar()
	# Aici NU se cheama `_apply_cycle`, desi podul mobil chiar isi aseaza starea
	# initiala in `_ready`. Diferenta e ca ciclul trombei incepe cu o raza in jos,
	# iar in `_ready` spatiul de fizica inca n-a facut niciun pas: raza n-ar gasi
	# nimic si talpa ar sari pe linia apei pentru un cadru. Ancora e deja pozitia
	# corecta pentru cadrul zero, deci nu e nimic de asezat.


# -------------------------------------------------------------------- modelul

func _build_model() -> void:
	# Suportul exista ca sa poarte INCLINAREA fara s-o dea si zonei de prindere.
	_model = Node3D.new()
	_model.name = "Funnel"
	add_child(_model)
	if not ResourceLoader.exists(MODEL_PATH):
		# Fara GLB, un con turcoaz de aceeasi inaltime. Mecanica trebuie sa poata
		# fi jucata si reglata inainte sa existe modelul — acelasi contract ca la
		# val (`wave_surge.gd`).
		var mi := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 6.3
		cone.bottom_radius = 1.4
		cone.height = FUNNEL_HEIGHT
		# Rezolutia implicita a primitivelor Godot e o capcana documentata in
		# CLAUDE.md: un cilindru lasat asa aduce cateva mii de triunghiuri.
		cone.radial_segments = 12
		cone.rings = 1
		mi.mesh = cone
		mi.position = Vector3.UP * (FUNNEL_HEIGHT * 0.5)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Palette.color(Palette.CONCRETE)
		mi.material_override = mat
		_funnel = mi
		_model.add_child(mi)
		return
	var glb := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	_model.add_child(glb)
	Palette.apply_world_material(glb)
	# Nodurile se cauta dupa NUME, ca `Blades` la moara si `Wave_Foam` la val.
	# Daca lipsesc, tromba se invarte intreaga in loc sa crape.
	for child in glb.get_children():
		if child.name == FUNNEL_NODE:
			_funnel = child as Node3D
		elif child.name == DEBRIS_NODE:
			_debris = child as Node3D


# ---------------------------------------------------------------- zona de ochi

## Cilindrul care prinde masinile.
##
## NU e un corp solid, si asta e toata diferenta fata de bariera mobila: o tromba
## solida ar fi un stalp de 18 m care se plimba pe sosea si te opreste — adica un
## zid care se misca, cel mai frustrant obiect posibil intr-un joc de curse.
## Treci prin ea; ce se schimba e ca nu mai atingi pamantul.
func _build_eye() -> void:
	_eye = Area3D.new()
	_eye.name = "Eye"
	_eye.monitoring = true
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = CATCH_RADIUS
	cyl.height = CATCH_TOP
	shape.shape = cyl
	shape.position = Vector3.UP * (CATCH_TOP * 0.5)
	_eye.add_child(shape)
	add_child(_eye)


# ------------------------------------------------------------------ particule

## Materialul comun: culoarea vine din particula, nu din material.
static func _dust_material() -> StandardMaterial3D:
	if _dust_mat == null:
		_dust_mat = StandardMaterial3D.new()
		_dust_mat.vertex_color_use_as_albedo = true
		# Culorile proiectului sunt autorate ca sRGB (Palette, Color.html). Fara
		# steagul asta Godot le citeste ca LINIARE si le scoate cu ~1.5 trepte mai
		# deschise — lectia deja platita o data pe praful de sub roti, care iesea
		# crem pal oricat il inchideam la sursa.
		_dust_mat.vertex_color_is_srgb = true
		_dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Fara scriere in depth: bucatile se suprapun fara sa se taie una pe alta.
		_dust_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return _dust_mat


## Un sistem de particule de vartej.
##
## `radial_accel` NEGATIV plus `tangential_accel` pozitiv sunt tot ce trebuie ca
## sa iasa un vartej: primul trage bucatile spre axa, al doilea le da imbrancitura
## perpendiculara. Fara ele, oricate particule ai emite, iese o fantana — praf
## care urca drept si cade drept, adica un gheizer, nu o tromba.
func _spin_emitter(count: int, tint: Color, life: float, size: float,
		rise: float, from_y: float, radius: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = count
	p.lifetime = life
	p.position = Vector3.UP * from_y
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 22.0
	p.initial_velocity_min = rise * 0.5
	p.initial_velocity_max = rise
	p.radial_accel_min = -9.0
	p.radial_accel_max = -4.0
	p.tangential_accel_min = 7.0
	p.tangential_accel_max = 15.0
	# Gravitatie slaba: ce ridica tromba nu recade ca o piatra, se tine sus si se
	# stinge. Cu -28 (gravitatia jocului) toate bucatile cadeau in primul metru.
	p.gravity = Vector3(0.0, -3.0, 0.0)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var fade := Gradient.new()
	fade.set_color(0, Color(tint.r, tint.g, tint.b, 0.0))
	fade.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	# Trei opriri: intra din transparent, tine, iese. O particula care apare la
	# opacitate plina POCNESTE in cadru — se vede mai ales la marginea razei de
	# emisie, unde nu e nimic care s-o ascunda.
	fade.add_point(0.15, Color(tint.r, tint.g, tint.b, 0.85))
	fade.add_point(0.70, Color(tint.r, tint.g, tint.b, 0.6))
	p.color_ramp = fade
	var bit := SphereMesh.new()
	bit.radius = 0.30
	bit.height = 0.60
	# Rezolutia implicita a unei sfere Godot e 64x32 = 4224 de triunghiuri. Cu 40
	# de particule ar fi insemnat 169.000 de triunghiuri de praf, adica jumatate
	# de pista Okinawa intr-un nor. Vezi CLAUDE.md.
	bit.radial_segments = 5
	bit.rings = 3
	bit.material = _dust_material()
	p.mesh = bit
	add_child(p)
	return p


func _build_particles() -> void:
	# Nisipul: mult, mic, rapid — corpul norului de la baza.
	_sand = _spin_emitter(SAND_COUNT, Palette.color(Palette.SAND_MID),
		1.5, 1.5, 13.0, 0.4, 3.2)
	# Frunzele: putine, mari, lenese. Ele sunt cele care se vad individual si
	# spun ca tromba ridica LUCRURI, nu doar praf. Traiesc mai mult tocmai ca sa
	# apuce sa urce pe langa palnie.
	_leaves = _spin_emitter(LEAF_COUNT, Palette.color(Palette.TROPICAL_GREEN),
		2.6, 2.4, 9.0, 0.8, 4.0)
	# Apa: burniţa pe care o cara tromba, pornita MEREU, nu doar peste mare.
	#
	# Prima versiune o aprindea doar cand talpa era pe apa, ca sa nu minta vizual.
	# Sonda a aratat de ce era gresit: pe asezarea de pe Okinawa malul e la peste
	# 60 m de axa in ambele parti, deci palnia nu ajunge niciodata pe apa si
	# stropii n-ar fi aparut nicio data intr-o cursa intreaga. Iar regula pe care
	# o aparam era gresita si ea: un typhoon nu e un vartej de praf, e o furtuna
	# — apa e in el de cand a traversat marea, nu de cand atinge luciul. Ce chiar
	# depinde de suprafata e NISIPUL, si ala ramane conditionat.
	_spray = _spin_emitter(SPRAY_COUNT, Palette.color(Palette.FOAM_WHITE),
		1.2, 1.8, 15.0, 0.2, 2.6)


# --------------------------------------------------------------------- ciclul

func _physics_process(delta: float) -> void:
	_time += delta
	_apply_cycle(delta)
	if Engine.is_editor_hint():
		return
	_tick_cooldowns(delta)
	_catch_cars()
	_steer_lofted(delta)


## Unde e tromba pe traversare, in metri fata de axa soselei.
##
## Sinusoida, nu du-te-vino liniar: la capete incetineste si intoarce lin, deci
## nu exista niciun cadru in care sa-si schimbe directia brusc. Peste sosea trece
## in schimb prin partea rapida a sinusoidei — adica fereastra de pericol e
## scurta si CITIBILA, iar restul ciclului o vezi departandu-se si stii ca ai
## timp. Un du-te-vino liniar ar fi avut aceeasi viteza peste tot si o
## intoarcere in unghi drept, care de la 150 m arata ca un salt.
func _offset() -> float:
	return sweep * sin(TAU * (_time / PERIOD + phase))


func _apply_cycle(delta: float) -> void:
	var moved := _anchor + travel_dir * _offset()
	# Talpa sta pe teren, nu pe cota la care a fost asezat nodul. Fara asta, o
	# tromba care iese de pe asfalt pluteste peste rapa digului sau se ingroapa
	# in duna — si tocmai marginile sunt locul in care se vede cel mai bine, avand
	# 18 m si nimic in jur.
	moved.y = _ground_y(moved)
	position = moved
	if _model != null:
		# Se apleaca INCOTRO merge. Derivata sinusoidei da si semnul, si
		# intensitatea: la capete, unde incetineste, se indreapta singura.
		var lean_amount := LEAN * cos(TAU * (_time / PERIOD + phase))
		var axis := travel_dir.cross(Vector3.UP).normalized()
		_model.transform.basis = Basis(axis, -lean_amount)
	if _funnel != null:
		_funnel.rotate_y(SPIN_FUNNEL * delta)
	if _debris != null:
		_debris.rotate_y(SPIN_DEBRIS * delta)
	if Engine.is_editor_hint():
		return
	_update_particles()


## Cota la care sta talpa palniei, in spatiul PARINTELUI, deasupra punctului `at`
## (tot local).
##
## O raza in jos, in fiecare cadru: terenul de sub tromba se schimba tot timpul,
## fiindca tromba se plimba. Peste mare talpa se opreste la `water_y` — acolo e
## trâmbă de apa si sta pe luciu, nu pe fundul marii.
##
## Masca e cea a camerei (`CAMERA_BLOCKER_LAYER`), nu layer-ul implicit, si din
## acelasi motiv pentru care o foloseste camera: pe layer-ul implicit stau si
## masinile, si popicele. O raza care nimereste o masina care trece pe sub tromba
## ar ridica talpa cu un metru pentru un cadru — un tremur din senin, imposibil de
## legat de cauza.
##
## ############################################################################
## O RAZA RATATA PASTREAZA COTA VECHE. NU inseamna „suntem deasupra apei".
##
## Prima versiune intorcea `water_y` cand raza nu gasea nimic, pe presupunerea ca
## un ratat inseamna mare. Presupunerea e falsa, si stiam de ce inca de la
## `--scan`: terenul pistei CONTINUA sub mare (fundul e sapat, nu lipseste), deci
## raza gaseste mereu ceva, iar apa se recunoaste comparand cota, nu prin absenta
## unui contact. Un ratat e prin urmare o anomalie — spatiul de fizica n-a facut
## inca niciun pas, scena se construieste, interogarile sunt blocate — si raspunsul
## corect la o anomalie e sa nu MISTI nimic.
##
## Ce facea varianta veche: la prima interogare fara raspuns, o tromba de 18 m
## sarea pe cota marii. Pe Okinawa, unde soseaua e la +4 si apa la −1.4, asta o
## ingroapa cu peste cinci metri — deci in editor, unde spatiul de fizica nu
## raspunde de fiecare data unui script `@tool`, palnia apare infipta in asfalt in
## loc sa stea pe el. In joc ar fi fost un singur cadru de pocnitura la start.
## ############################################################################
func _ground_y(at: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return _foot_y
	var parent := get_parent_node_3d()
	var to_world := parent.global_transform if parent != null else Transform3D.IDENTITY
	var from := to_world * Vector3(at.x, water_y + 70.0, at.z)
	var query := PhysicsRayQueryParameters3D.create(from,
		from + to_world.basis.y.normalized() * -140.0)
	query.collision_mask = Track.CAMERA_BLOCKER_LAYER
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return _foot_y
	var local: Vector3 = to_world.affine_inverse() * (hit.position as Vector3)
	_foot_y = maxf(local.y, water_y)
	return _foot_y


## Nisipul se opreste peste apa. Restul merg tot timpul.
##
## Frunzele raman pornite si peste mare: tromba tocmai a traversat plaja, deci
## cara inca ce a smuls de acolo. Fara ele, trecerea peste apa ar deveni brusc
## curata si s-ar vedea comutatorul — exact felul de detaliu care transforma un
## efect intr-un mecanism.
func _update_particles() -> void:
	if _sand != null:
		_sand.emitting = position.y > water_y + 0.35


# ------------------------------------------------------------------- prinderea

func _catch_cars() -> void:
	if _eye == null:
		return
	for body in _eye.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car) or _lofted.has(car):
			continue
		_catch(car)


## Viteza cu care se deplaseaza tromba, orizontal. Derivata lui `_offset`.
func _travel_velocity() -> Vector3:
	var w := TAU / PERIOD
	return travel_dir * (sweep * w * cos(TAU * (_time / PERIOD + phase)))


## Cat de central va fi contactul, in 0..1. 1 = prin ochi.
##
## ############################################################################
## SE PREZICE, NU SE MASOARA IN CLIPA CONTACTULUI, si asta a fost un defect real.
##
## Prima versiune lua distanta pana la axa chiar in cadrul in care masina intra
## in zona. Numai ca momentul ala e prin definitie MARGINEA cilindrului: acolo
## incepe suprapunerea. Deci distanta masurata era mereu ~CATCH_RADIUS, `core`
## iesea mereu 0, si toata lumea primea exact ridicarea minima. Gradientul
## „margine 5 m / ochi 15 m" era scris in cod si nu se intampla niciodata —
## masurat de tools/probe_typhoon.gd, care raporta apex 4.6 m si pentru o
## trecere pe mijloc.
##
## Corect e sa te uiti INAINTE: din pozitia si viteza RELATIVE (masina fata de
## tromba, care se misca si ea) iese momentul apropierii maxime si distanta la
## care va fi atunci. Aia e cat de central e contactul, si se stie deja in cadrul
## in care intri — deci ridicarea porneste imediat, fara sa astepte nimic.
## ############################################################################
func _hit_depth(car: Car) -> float:
	var p := Vector2(car.global_position.x - global_position.x,
		car.global_position.z - global_position.z)
	var rel := car.velocity - _travel_velocity()
	var v := Vector2(rel.x, rel.z)
	var closest := p.length()
	if v.length_squared() > 0.01:
		# Doar inainte: un `t` negativ ar insemna ca apropierea maxima a fost in
		# trecut, iar atunci distanta de acum chiar e cea buna.
		var t := maxf(-p.dot(v) / v.length_squared(), 0.0)
		closest = (p + v * t).length()
	var edge := maxf(CATCH_RADIUS - CORE_RADIUS, 0.01)
	return 1.0 - clampf((closest - CORE_RADIUS) / edge, 0.0, 1.0)


func _catch(car: Car) -> void:
	# Cat de sus te ridica scade cu cat de departe de axa treci. E singura parghie
	# de skill din interiorul contactului: cine atinge tromba pe margine pierde o
	# secunda, cine intra in ochi pierde doua si jumatate.
	var core := _hit_depth(car)
	var lift := lerpf(LIFT_MIN, LIFT_MAX, core)
	# Inaltimea ceruta se traduce in viteza verticala, nu invers: `launch` ia m/s,
	# dar cifra pe care o reglezi si o vezi pe ecran e inaltimea.
	car.launch(sqrt(2.0 * car.gravity * lift))
	car.velocity.x *= SPEED_KEEP
	car.velocity.z *= SPEED_KEEP
	car.spin_body(SPIN_CAR * (1.0 if core > 0.5 else 0.6), LOFT_MAX_TIME)
	_lofted[car] = 0.0


## Curentul care tine masina ridicata deasupra asfaltului.
##
## ############################################################################
## ASTA E PIESA CARE FACE CERINTA „TOT PE SOSEA" ADEVARATA.
##
## O masina ridicata 15 m sta in aer 2.1 s. La 34 m/s inseamna ~45 m de sosea
## parcursi fara nicio corectie — iar soseaua de pe Okinawa se curbeaza in tot
## intervalul asta, cu marea de o parte si laguna de cealalta. Aruncata pe o
## dreapta balistica, masina ar ateriza in apa de fiecare data cand tromba prinde
## pe cineva inaintea unui viraj. Adica hazardul ar fi fost, in practica, o
## repunere deghizata.
##
## Corectia se aplica prin `apply_sweep` — adica ADITIV pe viteza, nu prin
## scrierea ei. Nu e o preferinta de stil: `Car._physics_process` isi rescrie
## singur viteza in fiecare cadru, iar ordinea in care ruleaza cele doua noduri
## nu e garantata. O atribuire ar fi mers sau nu dupa cine e mai sus in arbore —
## adica ar fi fost un bug care apare la mutarea unui nod. Un adaos supravietuieste
## oricarei ordini.
##
## Tinta e `lookahead_point(..., lateral_frac = 0)`, adica AXA soselei la 22 m in
## fata — aceeasi unealta cu care isi aleg AI-urile linia. Asa corectia urmeaza
## curba prin constructie si nu trebuie sa stie nimic despre geometria pistei.
## ############################################################################
func _steer_lofted(delta: float) -> void:
	for car: Car in _lofted.keys():
		# Vezi nota de la `_tick_cooldowns`: cheia poate fi o masina deja
		# eliberata, si atunci nu e nimic de purtat prin aer.
		if not is_instance_valid(car):
			_lofted.erase(car)
			continue
		var t: float = float(_lofted[car]) + delta
		_lofted[car] = t
		var landed := t > LOFT_GRACE and car.is_on_floor()
		if landed or t > LOFT_MAX_TIME or car.track == null:
			_lofted.erase(car)
			_cooldown[car] = CATCH_COOLDOWN
			continue
		var idx := car.track.closest_index_global(car.global_position, car.route)
		var target := car.track.lookahead_point(idx, STEER_AHEAD, 0.0, car.route)
		var to_target := target - car.global_position
		to_target.y = 0.0
		if to_target.length_squared() < 0.01:
			continue
		var flat := Vector3(car.velocity.x, 0.0, car.velocity.z)
		# Directia se schimba, viteza NU: curentul te duce deasupra drumului, nu
		# te accelereaza. Altfel tromba ar fi devenit un boost gratuit pentru
		# cine o incaseaza.
		var wanted := to_target.normalized() * flat.length()
		car.apply_sweep((wanted - flat) * clampf(STEER_RATE * delta, 0.0, 1.0))


## ############################################################################
## `is_instance_valid` NU E PARANOIA AICI.
##
## Cele doua dictionare au drept CHEIE o masina. O masina insa poate sa dispara
## din lume oricand — la sfarsitul cursei, la schimbarea scenei, sau pur si simplu
## cand o sonda o elibereaza intre doua treceri. Cheia ramane in dictionar, dar
## nu mai arata spre nimic, iar `_cooldown[car] = left` pe ea da
## „Trying to assign invalid previously freed instance" IN FIECARE CADRU, la
## nesfarsit. Gasit de tools/probe_typhoon.gd, care elibereaza masina de proba
## intre treceri; in joc ar fi aparut abia la a doua cursa dintr-un campionat,
## adica exact unde nu te uiti.
## ############################################################################
func _tick_cooldowns(delta: float) -> void:
	for car: Car in _cooldown.keys():
		if not is_instance_valid(car):
			_cooldown.erase(car)
			continue
		var left: float = float(_cooldown[car]) - delta
		if left <= 0.0:
			_cooldown.erase(car)
		else:
			_cooldown[car] = left


# ---------------------------------------------------------------------- sunet

## Vuietul, cerut prin ARBORE si nu prin identificatorul de autoload.
##
## `AudioManager.stream(...)` ar fi mai scurt, dar in modul `--script`
## autoload-urile nu exista, deci identificatorul nu se rezolva si SCRIPTUL NU
## COMPILEAZA — iar clasa necompilata inseamna ca `TyphoonHazard.new()` intoarce
## eroare si pista se construieste fara tromba, in tacere. Lectia e a podului
## mobil (`lift_bridge_hazard.gd`), platita acolo pe trei sonde deodata.
func _start_roar() -> void:
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null:
		return
	var stream: AudioStream = manager.call("stream", &"typhoon_roar")
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()
