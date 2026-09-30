@tool
class_name DuskCycle
extends Node
## CEASUL DE LUMINA (Jodhpur, docs/track_briefs/jodhpur.md §3 „Ceasul de
## lumina", §4 tabelul „Lumina — ceasul, nu o valoare"). Cursa tine cat un
## apus: `dusk` 0 la start (turul 1, auriu) -> 1 la ultima trecere (turul 3,
## noapte cu artificii). SPRE DEOSEBIRE de [RainCycle]/[EruptionCycle], NU e
## ciclic — e o rampa care merge o singura data, de la inceputul la sfarsitul
## cursei, si NU are ceas propriu: se citeste direct din progresul cursei.
##
## Acelasi tipar de METRONOM ca [RainCycle] (frate direct, citeste-l intai):
## un nod mic, fara geometrie proprie, care scrie starea globala de lumina pe
## Environment/DirectionalLight3D gasite in scena, plus UN SINGUR canal pentru
## emisia lampilor (vezi mai jos) pe care orice material emisiv viitor il
## poate citi fara referinta directa la acest nod.
##
## SURSA LUI `dusk`: PROGRESUL, nu timpul (brief §3, §4 nota de sub tabel).
## `dusk = clamp(progres_total_jucator / total_laps, 0, 1)`, citit din
## `Race.player_progress_fraction()` daca exista un `Race` in arbore. Asta
## face iluminarea IDENTICA pentru acelasi punct din cursa in race si in time
## trial — un tur lent nu trebuie sa fie mai intunecat decat unul rapid, altfel
## recordurile nu se compara (aceeasi lectie ca `ceasul-porneste-in-prima-faza`,
## dar pe axa inversa: acolo un ceas absolut strica primul tur, aici un ceas
## absolut ar strica insasi comparabilitatea recordurilor).
##
## OVERRIDE: `force_dusk` (export, vezi mai jos) — folosit de flagul
## `--dusk=x` din snapshot.gd/probe_race.gd/probe_masca.gd, si de orice sonda
## care instantiaza pista fara `Race` (nu exista progres de citit). Cand
## `force_dusk >= 0.0`, el CASTIGA necondiționat, indiferent daca exista sau
## nu o cursa — la fel ca `RainCycle.force_factor()`, care opreste ceasul
## automat cat timp e activa forțarea.
##
## O SINGURA CALE DE LUMINA DE LAMPI (memoria `sonda-masura-alt-obiect`—cifra
## identica la bit intre dusk=0 si dusk=1 ar insemna neconectat): nodul scrie
## parametrul GLOBAL de shader `dusk_lamps` (declarat in project.godot
## [shader_globals]), citit de ORICE material care vrea sa lumineze cu
## ceasul — candele, sfori de becuri, ferestre. Vezi
## `assets/shaders/dusk_lamp_probe.gdshader` pentru un material minimal care
## il citeste, si antetul lui pentru cum se conecteaza o lampa noua.
##
## Efecte, in ordinea din brief §4:
## 1. soarele: elevatie (doar `rotation_degrees.x`, AZIMUTUL NU SE ATINGE —
##    brief: „azimutul soarelui ramane cel din tema"), energie, culoare;
## 2. ambientul: energie + culoare (spre indigo);
## 3. ceata: culoare + `fog_depth_end` (300 -> 240);
## 4. `dusk_lamps` (parametrul global de shader, canalul unic de emisie).
##
## NU ATINGE FIZICA (brief §3): fara asta, `RainCycle` e modelul de „stare
## continua pe care alte sisteme o citesc in fiecare cadru" — aici insa
## efectul e STRICT vizual, deci nu exista un camp gen `track.rain_wet`.

## Cheile de interpolare (brief §4), la 0 / 0,5 / 1. Elevatia e GRADE
## (pozitive; se aplica NEGAT pe `rotation_degrees.x`, conventia din
## `Track._sun_rotation_deg` — vezi `_apply_sun`).
const KEY_T: PackedFloat32Array = [0.0, 0.5, 1.0]
const KEY_SUN_ELEV_DEG: PackedFloat32Array = [8.0, 3.0, 1.0]
const KEY_SUN_ENERGY: PackedFloat32Array = [0.85, 0.55, 0.30]
## Culorile NU pot fi `const Array[Color]` initializat cu `Color.html()`/
## `Color(...)` de call — GDScript cere o EXPRESIE CONSTANTA pentru `const`,
## iar un apel de functie (chiar si un constructor) nu calific ("Assigned
## value for constant... isn't a constant expression", verificat la
## compilare). De-aia sunt `Array[Color]` populate in `_static_init()`, in loc
## de literale `Color(r,g,b)` scrise de mana (mai usor de citit direct hexul
## din brief §4 decat trei zecimale rotunjite).
static var KEY_SUN_COLOR: Array[Color] = []
## TRECEREA DE LUMINA (tools/ProbeJodLumina.tscn, cifre pe masca de clasa in
## docs/track_briefs/img/jodhpur_lumina/): cheile din brief §4 faceau orasul
## bej la dusk 0 (soare+ambient+ceata portocalii) si TOATA scena albastra la
## dusk 1 (soare+ambient+ceata indigo: nisip H 232, asfalt H 238). Regula
## noua: ALBASTRUL VINE DIN ALBEDO (varul caselor), NU DIN LUMINA. Lumina
## ramane aproape neutra in spatiul liniar (B/R ~0,9-1,2), deci varul iese
## albastru si nisipul cald la orice faza; ce face noaptea e ENERGIA (luma
## cadrului scade ~40%), cerul si ceata inchisa, apoi flacarile (lampile).
## Soarele pastreaza caldura fazei (auriu -> roz -> luna gri-lila).
## Ambientul: neutru-cald -> lila stins -> gri-lila, energia 0,42 -> 0,45.
## A DOUA TRECERE („cald + albastru", jodhpur_masuratori.md §10): soarele
## portocaliu saturat (#FF9050 -> #FF7A50 la 0,5) dar mai slab (0,85/0,55),
## ambientul mai tare (0,50/0,48) — raportul cheie/umplere tine varul albastru
## sub un soare mai cald. Faza 1 (noaptea) neschimbata la soare/ambient/ceata.
const KEY_AMBIENT_ENERGY: PackedFloat32Array = [0.50, 0.48, 0.45]
static var KEY_AMBIENT_COLOR: Array[Color] = []
static var KEY_FOG_COLOR: Array[Color] = []
const KEY_FOG_END: PackedFloat32Array = [300.0, 270.0, 240.0]
## Imprastierea soarelui in ceata (`Environment.fog_sun_scatter`): ceata SPRE
## soare capata culoarea soarelui, ceata DINSPRE soare ramane culoarea ei.
## NEPIVOTATA pe baza (tema n-o declara): cheile se aplica exact.
const KEY_FOG_SUN_SCATTER: PackedFloat32Array = [1.0, 0.6, 0.0]
## CERUL (a doua trecere de lumina, „cald + albastru"): pana aici cerul nu era
## canal al ceasului, deci noaptea ramanea cu orizontul de apus. Acum
## `sky_top`/`sky_horizon` ale `ProceduralSkyMaterial` se interpoleaza ca
## restul (pivotate pe tema la dusk 0), iar `ground_horizon` urmeaza
## orizontul (tema le leaga la fel in `Track._build_environment`).
static var KEY_SKY_TOP: Array[Color] = []
static var KEY_SKY_HORIZON: Array[Color] = []
## Discul soarelui in ProceduralSky e un AMESTEC catre `culoare x energie` a
## luminii, nu un adaos: cand soarele scade la 0,30 (luna gri-lila) discul
## iese MAI INCHIS decat orizontul — pata intunecata de pe cer la dusk 1, de
## 30 de grade (`sun_angle_max` implicit). Raza haloului scade cu ceasul si
## dispare noaptea. NEPIVOTATA: tema nu declara unghiul.
const KEY_SUN_ANGLE_MAX: PackedFloat32Array = [30.0, 18.0, 0.0]


## Ceata: fum albastru-gri stins -> lila-gri -> gri-violet inchis (S <= 0,2
## la toate fazele; ceata indigo #3E4A7A albastrea tot ce e dincolo de 90 m).
static func _static_init() -> void:
	KEY_SUN_COLOR = [
		Color.html("FF9050"), Color.html("FF7A50"), Color.html("A4A0B4")]
	KEY_AMBIENT_COLOR = [
		Color.html("C8C4D0"), Color.html("BEB4C4"), Color.html("8A8690")]
	KEY_FOG_COLOR = [
		Color.html("8A94B8"), Color.html("8A8CA0"), Color.html("45424E")]
	KEY_SKY_TOP = [
		Color.html("8C4780"), Color.html("5A3A78"), Color.html("1A1834")]
	KEY_SKY_HORIZON = [
		Color.html("FF7A38"), Color.html("F06A3A"), Color.html("4A2E44")]
## Emisia lampilor: 0,15 (abia perceptibil, ziua) -> 1,0 (sursa de lumina
## principala, noaptea) — brief §4 si §3 „emisia lampilor 0,15 -> 1,0".
const KEY_LAMPS: PackedFloat32Array = [0.15, 0.6, 1.0]

## -1.0 = neatins (dusk vine din progresul cursei, prin `Race`). >= 0.0 =
## FORTAT la valoarea asta, castiga necondiționat (sonde, snapshot, sau orice
## pista incarcata fara `Race`, unde n-ar exista alt progres de citit).
## Static, nu doar export: `--dusk=` din unelte trebuie sa poata forta orice
## `DuskCycle` gasit prin grup, fara sa tina o referinta la nod dinainte sa-l
## gaseasca (acelasi motiv ca `force_factor()` la RainCycle, dar aici pe cale
## statica fiindca unele unelte adauga nodul DUPA ce pista exista deja).
@export_range(-1.0, 1.0, 0.01) var force_dusk: float = -1.0

## Numele parametrului global de shader (`project.godot` [shader_globals]).
## UN SINGUR canal, ca orice material viitor sa-l citeasca fara referinta la
## acest nod — vezi antetul de mai sus si `dusk_lamp_probe.gdshader`.
const LAMPS_GLOBAL_PARAM: StringName = &"dusk_lamps"

## 0 = auriu/turul 1, 1 = noapte/turul 3. Public, ca sondele sa citeasca direct
## fara sa reconstruiasca interpolarea din `_race`/`force_dusk`.
var dusk: float = 0.0

var _race: Node = null # tipizat Variant intentionat, vezi `_find_race`
var _env: Environment = null
var _sun: DirectionalLight3D = null
var _base_taken: bool = false
var _base_sun_elev_deg: float = 0.0
var _base_sun_energy: float = 1.0
var _base_sun_color: Color = Color.WHITE
var _base_ambient_energy: float = 1.0
var _base_ambient_color: Color = Color.WHITE
var _base_fog_color: Color = Color.WHITE
var _base_fog_end: float = 300.0
var _sky_mat: ProceduralSkyMaterial = null
var _base_sky_top: Color = Color.WHITE
var _base_sky_horizon: Color = Color.WHITE
var _base_sun_angle_max: float = 0.0
var _last_sky_d: float = -1.0


func _ready() -> void:
	add_to_group(&"dusk_cycle")
	if Engine.is_editor_hint():
		set_process(false)
		return
	# AMANAT, acelasi motiv ca RainCycle._collect: `Race`/`Environment`/`sun`
	# sunt construite de scena parinte in jurul acestui `_ready`, iar o
	# cautare imediata ar gasi arborele inca nepopulat.
	_collect.call_deferred()


func _collect() -> void:
	if not is_inside_tree():
		return
	_race = _find_race()
	_env = _find_environment()
	_sun = _find_sun()
	_take_base()
	_apply(_current_dusk())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_apply(_current_dusk())


## `dusk` curent: override-ul castiga necondiționat; altfel, progresul cursei
## (nul daca sonda a instantiat pista fara `Race` — atunci ramane 0, adica
## exact starea neutra de la grila/countdown, brief §3).
func _current_dusk() -> float:
	if force_dusk >= 0.0:
		return clampf(force_dusk, 0.0, 1.0)
	if _race != null and _race.has_method("player_progress_fraction"):
		return clampf(float(_race.call("player_progress_fraction")), 0.0, 1.0)
	return 0.0


func _find_race() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_method("player_progress_fraction"):
			return n
		n = n.get_parent()
	return null


## Cauta pornind de la RADACINA ARBORELUI, ca RainCycle._search_root: o sonda
## care instantiaza pista ca sora a lui `current_scene` (nu fiica) tot trebuie
## gasita.
func _search_root() -> Node:
	if get_tree() != null:
		return get_tree().root
	return get_parent()


func _find_environment() -> Environment:
	var we := _first_of_type(_search_root(), "WorldEnvironment") as WorldEnvironment
	return we.environment if we != null else null


func _find_sun() -> DirectionalLight3D:
	return _first_of_type(_search_root(), "DirectionalLight3D") as Node3D as DirectionalLight3D


func _first_of_type(n: Node, class_name_str: String) -> Node:
	if n == null:
		return null
	if n.get_class() == class_name_str:
		return n
	for c in n.get_children():
		var found := _first_of_type(c, class_name_str)
		if found != null:
			return found
	return null


func _take_base() -> void:
	if _base_taken:
		return
	if _sun != null:
		# Conventia din Track._sun_rotation_deg: elevatia se scrie NEGATA pe
		# `.x`. Se ia `absf` ca sa lucram in grade pozitive de-a lungul
		# interpolarii si se re-negheaza la aplicare (`_apply_sun`).
		_base_sun_elev_deg = absf(_sun.rotation_degrees.x)
		_base_sun_energy = _sun.light_energy
		_base_sun_color = _sun.light_color
	else:
		_base_sun_elev_deg = KEY_SUN_ELEV_DEG[0]
		_base_sun_energy = KEY_SUN_ENERGY[0]
		_base_sun_color = KEY_SUN_COLOR[0]
	if _env != null:
		_base_ambient_energy = _env.ambient_light_energy
		_base_ambient_color = _env.ambient_light_color
		_base_fog_color = _env.fog_light_color
		_base_fog_end = _env.fog_depth_end
		if _env.sky != null:
			_sky_mat = _env.sky.sky_material as ProceduralSkyMaterial
		if _sky_mat != null:
			_base_sky_top = _sky_mat.sky_top_color
			_base_sky_horizon = _sky_mat.sky_horizon_color
			_base_sun_angle_max = _sky_mat.sun_angle_max
	_base_taken = true


func _apply(d: float) -> void:
	dusk = d
	_apply_sun(d)
	_apply_ambient_and_fog(d)
	_apply_sky(d)
	_apply_lamps(d)


## Elevatia soarelui scade odata cu `dusk` (8 -> 3 -> 1 grade); AZIMUTUL
## (`.y`/`.z`) NU SE ATINGE — brief §4: „Azimutul soarelui ramane cel din
## tema". La `dusk = 0` valorile revin exact la cele citite in `_take_base`
## (nu la cheia 0 a tabelului), ca o tema care nu foloseste 8°/1,0/#FFB27A ca
## bază sa nu sara la incarcare.
func _apply_sun(d: float) -> void:
	if _sun == null:
		return
	var elev := _lerp_key(KEY_SUN_ELEV_DEG, d, _base_sun_elev_deg)
	var rot := _sun.rotation_degrees
	rot.x = -elev
	_sun.rotation_degrees = rot
	_sun.light_energy = _lerp_key(KEY_SUN_ENERGY, d, _base_sun_energy)
	_sun.light_color = _lerp_color_key(KEY_SUN_COLOR, d, _base_sun_color)


func _apply_ambient_and_fog(d: float) -> void:
	if _env == null:
		return
	_env.ambient_light_energy = _lerp_key(KEY_AMBIENT_ENERGY, d, _base_ambient_energy)
	_env.ambient_light_color = _lerp_color_key(KEY_AMBIENT_COLOR, d, _base_ambient_color)
	_env.fog_light_color = _lerp_color_key(KEY_FOG_COLOR, d, _base_fog_color)
	_env.fog_depth_end = _lerp_key(KEY_FOG_END, d, _base_fog_end)
	_env.fog_sun_scatter = _lerp_key(KEY_FOG_SUN_SCATTER, d, KEY_FOG_SUN_SCATTER[0])


## Cerul: vezi `KEY_SKY_TOP`/`KEY_SKY_HORIZON`/`KEY_SUN_ANGLE_MAX`.
##
## Scris in TREPTE de 0,01 din `dusk`, nu la fiecare cadru: o schimbare de
## parametru pe materialul cerului face motorul sa refaca harta de radianta a
## cerului (cubemap), cost care pe mobil nu se plateste de 60 de ori pe
## secunda. 100 de trepte pe o cursa de 2-3 minute = o scriere la ~1,5 s,
## sub pragul la care se vede un salt de culoare.
func _apply_sky(d: float) -> void:
	if _sky_mat == null:
		return
	if _last_sky_d >= 0.0 and absf(d - _last_sky_d) < 0.01 and d != 0.0 and d != 1.0:
		return
	if d == _last_sky_d:
		return
	_last_sky_d = d
	_sky_mat.sky_top_color = _lerp_color_key(KEY_SKY_TOP, d, _base_sky_top)
	var hz := _lerp_color_key(KEY_SKY_HORIZON, d, _base_sky_horizon)
	_sky_mat.sky_horizon_color = hz
	_sky_mat.ground_horizon_color = hz
	# Sub orizont cerul e `ground_bottom` = ceata intunecata cu 40% (aceeasi
	# legatura ca in `Track._build_environment`). Fixa pe tema, ramanea
	# albastru-gri deschis noaptea: de pe bastion (F, dusk 1) se vedea o banda
	# palida sub cerul de noapte, acolo unde terenul se termina inainte de
	# linia orizontului. Urmeaza acum ceata ceasului.
	if _env != null:
		_sky_mat.ground_bottom_color = _env.fog_light_color.darkened(0.4)
	# Tema care a stins discul (`sky_sun_disc` false => 0) ramane stinsa.
	if _base_sun_angle_max > 0.0:
		_sky_mat.sun_angle_max = maxf(_lerp_key(KEY_SUN_ANGLE_MAX, d, _base_sun_angle_max), 0.0)


## Ultima valoare SCRISA pe `dusk_lamps` (vezi `_apply_lamps`). Exista DOAR
## fiindca `RenderingServer.global_shader_parameter_get()` NU se poate citi
## la runtime in afara editorului — Godot 4.7 arunca explicit "This function
## should never be used outside the editor, it can severely damage
## performance" si intoarce `null` necondiționat (verificat direct: si
## imediat dupa un `global_shader_parameter_set()` pe ACEEASI cheie, `get()`
## tot null). `set()` insa functioneaza normal la runtime — asta e calea
## SUPORTATA prin care shaderele citesc valoarea (`global uniform float
## dusk_lamps;`), doar unealta de INTROSPECTIE dinspre GDScript lipseste in
## afara editorului. `lamps_value` e oglinda locala prin care o sonda poate
## verifica "ce s-a scris", fara sa pretinda ca citeste inapoi din motor —
## canalul real ramane tot `RenderingServer`/`global uniform`, neschimbat.
var lamps_value: float = KEY_LAMPS[0]

## Scrie parametrul GLOBAL de shader (canalul unic de emisie a lampilor).
## `RenderingServer.global_shader_parameter_set` functioneaza indiferent daca
## parametrul e declarat in `project.godot` [shader_globals] sau nu (Godot il
## creeaza „soft" la runtime), dar fara declaratie niciun shader nou nu-l vede
## la compilare — de-aia proiectul TREBUIE sa aiba cheia (vezi project.godot).
func _apply_lamps(d: float) -> void:
	lamps_value = _lerp_key(KEY_LAMPS, d, KEY_LAMPS[0])
	RenderingServer.global_shader_parameter_set(LAMPS_GLOBAL_PARAM, lamps_value)


## Interpolare liniara pe cheile `KEY_T` (0 / 0,5 / 1), PIVOTATA pe valoarea
## de baza citita din scena: la `d = 0` rezultatul e `base`, nu `keys[0]` —
## altfel o tema care nu incepe exact la 8°/1,0/#FFB27A ar sari vizibil la
## primul cadru. Cheile de la 0,5 si 1 sunt cele din brief, NEATINSE de baza
## (comportamentul RainCycle: baza conteaza doar la capatul uscat/dusk=0).
func _lerp_key(keys: PackedFloat32Array, d: float, base: float) -> float:
	var t := clampf(d, 0.0, 1.0)
	if t <= KEY_T[1]:
		var k := t / KEY_T[1]
		return lerpf(base, keys[1], k)
	var k2 := (t - KEY_T[1]) / (KEY_T[2] - KEY_T[1])
	return lerpf(keys[1], keys[2], k2)


func _lerp_color_key(keys: Array[Color], d: float, base: Color) -> Color:
	var t := clampf(d, 0.0, 1.0)
	if t <= KEY_T[1]:
		var k := t / KEY_T[1]
		return base.lerp(keys[1], k)
	var k2 := (t - KEY_T[1]) / (KEY_T[2] - KEY_T[1])
	return keys[1].lerp(keys[2], k2)


# ---------------------------------------------------------- pentru sonde

## Forteaza `dusk` direct, ocolind `Race`/progresul — pentru sonde si capturi.
## Vezi nota de la `force_dusk`: valoarea ramane pana la urmatorul apel, chiar
## daca exista un `Race` in arbore (override-ul castiga necondiționat).
func force_value(v: float) -> void:
	force_dusk = clampf(v, 0.0, 1.0)
	_apply(force_dusk)


## Reporneste citirea din progresul cursei dupa un `force_value`.
func resume_progress() -> void:
	force_dusk = -1.0


func environment() -> Environment:
	return _env


func sun() -> DirectionalLight3D:
	return _sun


func race_ref() -> Node:
	return _race
