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
## Valoarea de referinta a urmaririi, peste care se aplica factorul din setari.
const DEFAULT_FOLLOW_SPEED: float = 3.6
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
@export var follow_speed: float = DEFAULT_FOLLOW_SPEED
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

## Grupul prin care panoul de setari si reglajul din cursa ajung la camera vie,
## fara sa tina o referinta la ea (panoul e folosit si din meniu, unde nu exista
## nicio cursa).
const GROUP := &"chase_camera"

var target: Car
var trauma: float = 0.0

var _cam: Camera3D
var _aim_dir: Vector3 = Vector3.FORWARD
## Lungimea vehiculului curent, retinuta ca `refresh_from_settings` sa poata
## recalcula incadrarea fara sa mai intrebe cine e la volan.
var _body_length: float = REFERENCE_LENGTH

## Presetul de zona (cavern) ca DATE, plus cat de mult e aplicat (0..1).
##
## Nu se scrie niciodata in `height`/`look_height`/`base_fov`: alea sunt
## rezultatul lui `apply_settings_for`, adica al setarilor jucatorului, si
## panoul le recalculeaza in timpul cursei. Presetul se aplica PESTE ele, in
## fiecare cadru, in `_physics_process`. Vezi [CameraZone].
var _zone_preset: Dictionary = {}
var _zone_amount: float = 0.0
var _zone_blend: float = 0.5
## Rezultatul lui `solve_preset` pentru cadrul curent (inaltime, FOV), tinut ca
## `eff_*` sa nu refaca cautarea binara de cateva ori pe cadru. Recalculat in
## `_physics_process` si oriunde se schimba o intrare (setari, preset nou).
var _solved_h: float = 0.0
var _solved_fov: float = 0.0
## Cine a cerut presetul. Doua zone suprapuse nu trebuie sa se stearga una pe
## alta la iesirea din prima: doar proprietarul curent poate anula.
var _zone_owner: int = 0


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
	add_to_group(GROUP)


## Incadrarea pentru un vehicul, cu factorii jucatorului aplicati peste.
##
## Aici se intalnesc cele doua lucruri care regleaza camera si care pana acum
## erau amestecate: FORMULA (autobuzul sta mai departe decat muscle car-ul) si
## PREFERINTA (jucatorul o vrea mai sus). Prima e cod, a doua e setare, si se
## inmultesc — deci nici tunarea camerei in cod nu calca peste reglajul lui,
## nici invers.
func apply_settings_for(body_length: float) -> void:
	_body_length = body_length
	distance = distance_for(body_length) * GameState.cam_distance_scale
	height = height_for(body_length) * GameState.cam_height_scale
	base_fov = BASE_FOV * GameState.cam_fov_scale
	follow_speed = DEFAULT_FOLLOW_SPEED * GameState.cam_follow_scale
	# Presetul de zona se recalculeaza ODATA CU setarile: `solve_preset` citeste
	# `distance` si `base_fov`, deci un slider miscat in timpul cursei (panoul
	# face exact asta) ar lasa altfel solutia veche pe o baza noua.
	_resolve_preset()


## Reia setarile pe vehiculul curent. Chemata prin grup, din panoul de setari si
## din reglajul de la taste, ca schimbarea sa se vada IN TIMP CE misti sliderul —
## o camera care se schimba abia la urmatoarea cursa nu se poate regla.
func refresh_from_settings() -> void:
	apply_settings_for(_body_length)


## Primeste (sau anuleaza) presetul unei [CameraZone]. Chemata prin grup.
##
## `preset` gol inseamna "iesi din zona". Anularea o poate cere doar zona care
## a pus presetul: cand doua zone se suprapun (gura cavernei si sala), iesirea
## din prima n-are voie sa stearga presetul celei in care tocmai ai intrat.
func set_zone_preset(preset: Dictionary, blend_time: float, owner_id: int) -> void:
	_zone_blend = maxf(blend_time, 0.01)
	if preset.is_empty():
		if owner_id == _zone_owner:
			_zone_owner = 0
		return
	_zone_preset = preset
	_zone_owner = owner_id
	_resolve_preset()


## Valorile EFECTIVE ale camerei: setarile jucatorului, cu presetul de zona
## amestecat peste. Astea sunt cele pe care le foloseste `_physics_process` —
## `height`/`look_height`/`base_fov` raman curate, ale setarilor.
##
## Trei functii, nu un Dictionary: se cheama de cateva ori pe cadru, si un
## dictionar alocat de fiecare data ar fi gunoi pe bugetul de 60 fps.
func eff_height() -> float:
	if _zone_amount <= 0.0001 or _zone_preset.is_empty():
		return height
	return lerpf(height, _solved_h, _zone_amount)


func eff_look_height() -> float:
	return _blend(look_height, "look_height")


func eff_fov() -> float:
	if _zone_amount <= 0.0001 or _zone_preset.is_empty():
		return base_fov
	return lerpf(base_fov, _solved_fov, _zone_amount)


func _blend(base: float, key: String) -> float:
	if _zone_amount <= 0.0001 or _zone_preset.is_empty():
		return base
	return lerpf(base, float(_zone_preset.get(key, base)), _zone_amount)


## Recalculeaza tinta presetului (inaltime + FOV) din cerinta lui geometrica.
##
## Se cheama cand se schimba o INTRARE, nu in fiecare cadru degeaba: preset nou,
## setari noi. Rezultatul e capatul rampei — `_zone_amount` interpoleaza spre el,
## deci tranzitia ramane cea de 0.5 s, doar ca acum are un capat corect.
##
## Fara `ceiling`/`ceiling_dist` in preset, solverul nu face nimic si presetul
## se comporta ca inainte (aditiv): o zona care nu declara ce trebuie sa se vada
## n-are ce garanta.
func _resolve_preset() -> void:
	if _zone_preset.is_empty():
		return
	var want_h := float(_zone_preset.get("height", height))
	var want_lh := float(_zone_preset.get("look_height", look_height))
	var bonus := float(_zone_preset.get("fov_bonus", 0.0))
	var solved := solve_preset(want_h, want_lh, distance, look_ahead,
		base_fov + bonus,
		float(_zone_preset.get("ceiling", 0.0)),
		float(_zone_preset.get("ceiling_dist", 0.0)))
	_solved_h = float(solved[0])
	_solved_fov = float(solved[1])


## Marginea de sus a frustumului fata de orizontala (grade), pentru inaltimea
## si FOV-ul date. Pozitiv = camera vede deasupra orizontalei.
##
## `fov` din Godot e cel VERTICAL (`keep_aspect` implicit pastreaza inaltimea),
## deci jumatatea de cadru pe verticala e chiar fov/2 — nu se trece prin raport.
static func top_edge_deg(h: float, lh: float, d: float, la: float,
		fov: float) -> float:
	return -rad_to_deg(atan((h - lh) / (d + la))) + fov * 0.5


## Cat de jos are voie sa coboare camera de cavern cand geometria o cere.
##
## Nu e o valoare de gust, e o limita de coliziune: sub ~3 m bratul incepe sa
## intre in masina la orice denivelare, iar `_unclip` il scurteaza si mai mult.
## E prima parghie cheltuita (vezi `solve_preset`) fiindca e GRATUITA — coborarea
## camerei ridica marginea de sus SI scurteaza drumul pana la tavan, pe cand
## largirea FOV-ului costa distorsiune la margini (vezi antetul, punctul 1).
const CAVE_MIN_HEIGHT: float = 3.0

## FOV-ul minim care face un tavan de `ceiling` vizibil de la `dist`, cu camera
## la `h`. Inversa lui `ceiling_entry_distance`: acolo intrebi "de la ce
## distanta intra tavanul", aici "ce FOV imi trebuie ca sa intre de la X".
static func fov_for_ceiling(ceiling: float, dist: float, h: float, lh: float,
		d: float, la: float) -> float:
	var need_top := rad_to_deg(atan((ceiling - h) / dist))
	var pitch := rad_to_deg(atan((h - lh) / (d + la)))
	return 2.0 * (need_top + pitch)


## Rezolva presetul de cavern ca sa TINA CERINTA GEOMETRICA, oricare ar fi
## sliderele jucatorului. Intoarce [height, fov] efective.
##
## [b]De ce exista.[/b] Presetul, asa cum a fost construit prima data, era
## ADITIV: `base_fov * cam_fov_scale + 6`. Dar cerinta din brief (§2.0) nu e
## "cu 6° mai larg", e GEOMETRICA — "tavanul de 15 m se vede de la 25 m". Cele
## doua coincid doar la sliderele pe 1.0. Masurat pe grila legala a sliderelor
## (0.5–2.0 pe distanta x 0.7–1.3 pe FOV), varianta aditiva pica pe aproape
## JUMATATE din spatiu: la `cam_fov_scale` 0.7 tavanul intra abia de la 45.6 m
## in loc de 22.4, iar la distanta scurtata la 0.5 nici macar FOV-ul implicit
## nu ajunge (38 m). Adica pentru o buna parte din reglajele legale subteranul —
## POI-ul pistei — era un tavan negru pe care jucatorul nu-l vedea niciodata.
##
## [b]Ordinea parghiilor, si de ce asta.[/b] Intai coboara INALTIMEA pana la
## `CAVE_MIN_HEIGHT`, si abia daca nici acolo nu ajunge urca FOV-ul. Inaltimea
## e gratuita si lucreaza de doua ori (ridica marginea de sus si scurteaza
## `ceiling - h`); FOV-ul larg aplatizeaza si distorsioneaza marginile — exact
## ce spune antetul ca strica senzatia de viteza. Cu ordinea asta, FOV-ul cerut
## in coltul cel mai greu (distanta 0.5, FOV 0.7) scade de la 86.3° la 67.5°.
##
## [b]Cine pierde, si unde.[/b] Preferinta de FOV a jucatorului e respectata
## PESTE podea, niciodata sub: FOV-ul iese `max(preferinta + bonus, podea)`.
## Podeaua se ridica peste preferinta doar in coltul "FOV stramt + camera
## aproape" — la `cam_fov_scale` 0.7 peste tot (+3.8° la distanta 2.0, pana la
## +13.9° la 0.5), la 0.8 doar sub distanta 1.2, si deloc de la 0.9 in sus.
## Restul spatiului legal isi pastreaza reglajul neatins. Pierderea e asumata
## si are un motiv care nu se poate negocia: sub un FOV vertical de ~57° un
## tavan de 15 m NU INCAPE in cadru de la 25 m la NICIO inaltime si NICIO
## distanta — 13.6 m de urcare la 25 m cer o jumatate de unghi de 28.5°, iar
## 47.6° (adica 0.7) ofera 23.8°. Nu e o alegere de design, e trigonometrie:
## ori se largeste FOV-ul acolo, ori POI-ul nu exista pentru acei jucatori.
##
## `cam_height_scale` nu apare nicaieri fiindca presetul da inaltimea ABSOLUT
## (o inghite complet), iar `cam_distance_scale` intra prin `d`, care e chiar
## parametrul.
static func solve_preset(want_h: float, lh: float, d: float, la: float,
		player_fov: float, ceiling: float, dist: float) -> Array:
	if ceiling <= 0.0 or dist <= 0.0:
		return [want_h, player_fov]
	# Parghia 1: inaltimea. Cat de sus poate sta camera si cerinta sa tina inca?
	var h := want_h
	if ceiling_entry_distance(ceiling, h,
			top_edge_deg(h, lh, d, la, player_fov)) > dist:
		var lo := CAVE_MIN_HEIGHT
		var hi := want_h
		if ceiling_entry_distance(ceiling, lo,
				top_edge_deg(lo, lh, d, la, player_fov)) <= dist:
			# Cerinta se rezolva DOAR din inaltime: cauta cea mai INALTA cota
			# care o tine, ca sa cobori camera cat mai putin.
			for _i in 40:
				var mid := (lo + hi) * 0.5
				if ceiling_entry_distance(ceiling, mid,
						top_edge_deg(mid, lh, d, la, player_fov)) <= dist:
					lo = mid
				else:
					hi = mid
			h = lo
		else:
			# Nici jos de tot nu ajunge: coboara complet si plateste in FOV.
			h = CAVE_MIN_HEIGHT
	# Parghia 2: FOV-ul, doar cat lipseste. `max` = preferinta jucatorului e
	# respectata peste podea.
	return [h, maxf(player_fov, fov_for_ceiling(ceiling, dist, h, lh, d, la))]


## De la ce distanta intra in cadru un tavan aflat la `ceiling` metri, cu
## camera la `cam_h`. INF daca marginea de sus nu urca peste orizontala:
## atunci tavanul nu intra niciodata, oricat de departe ar fi.
static func ceiling_entry_distance(ceiling: float, cam_h: float,
		top_deg: float) -> float:
	if top_deg <= 0.01 or ceiling <= cam_h:
		return INF
	return (ceiling - cam_h) / tan(deg_to_rad(top_deg))


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


## Panta camerei in pozitia de repaus. Ridicarea la viteza o pastreaza (vezi
## `_physics_process`), deci asta e UNGHIUL camerei, nu doar o valoare de start.
func _pitch_tan() -> float:
	return (eff_height() - eff_look_height()) / (distance + look_ahead)


## Acelasi unghi, in grade — cifra cu care se compara doua camere intre ele.
func pitch_degrees() -> float:
	return rad_to_deg(atan(_pitch_tan()))


func _physics_process(delta: float) -> void:
	if target == null:
		return
	# Presetul de zona urca/coboara liniar, ca `blend_time` sa insemne chiar
	# durata ceruta. Restul netezirilor camerei sunt exponentiale fiindca
	# urmaresc o tinta care se misca; asta e o rampa cu capete, si un exp ar
	# lasa-o mereu "aproape" de preset, niciodata pe el.
	var zone_target := 1.0 if _zone_owner != 0 else 0.0
	_zone_amount = move_toward(_zone_amount, zone_target, delta / _zone_blend)
	if _zone_amount <= 0.0 and _zone_owner == 0:
		_zone_preset = {}
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
	var h := eff_look_height() + (d + look_ahead) * _pitch_tan()

	var desired := target.global_position - anchor * d + Vector3.UP * h
	var t := 1.0 - exp(-follow_speed * delta) # urmarire independenta de fps
	global_position = global_position.lerp(desired, t)
	# Anti-clipping DUPA lerp, nu inainte: camera n-are voie sa fie niciodata in
	# perete, iar `desired` o impinge afara oricum, deci iesirea e lina de la sine.
	global_position = _unclip(
		target.global_position + Vector3.UP * eff_look_height(),
		global_position)
	_look_at_point(_aim_point(_aim_dir))

	# FOV: viteza + kick suplimentar cat tine boost-ul.
	var boost_kick := 6.0 if target.is_boosting else 0.0
	var fov_target := eff_fov() + fov_speed_kick * speed_frac + boost_kick
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
##
## Foloseste `look_height`/`look_ahead` EXPORTATE, nu constantele. Inainte erau
## constantele, si asta facea `look_height` o parghie pe jumatate moarta: muta
## pozitia rig-ului (prin `_pitch_tan`), dar nu si TINTA, deci camera cobora
## fara sa-si ridice privirea. Pentru presetul de cavern ([CameraZone]) exact
## ridicarea privirii e tot rostul — cu tinta lasata la butuc, panta ar fi iesit
## 19.22° in loc de 16.25°, marginea de sus +17.78° in loc de +20.75°, iar
## tavanul de 15 m ar fi intrat in cadru abia de la 26.5 m in loc de 22.4:
## adica exact peste pragul de 25 m cerut de brief, deci presetul ar fi ratat
## tinta cu tot cu cifrele lui corecte.
##
## Pe camera implicita nu schimba nimic: exporturile pornesc chiar de la
## constante (`look_height = LOOK_HEIGHT`, `look_ahead = LOOK_AHEAD`), si
## singurul care le mai misca e `tools/probe_cam.gd`, unde diferenta e chiar
## scopul.
func _aim_point(dir: Vector3) -> Vector3:
	return target.global_position + Vector3.UP * eff_look_height() \
		+ dir * look_ahead


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
