@tool
class_name RainCycle
extends Node
## METRONOMUL PLOII (Fiordland, docs/track_briefs/fiordland.md §3 „Faza de
## ploaie", §7 pasul 1(c)). La fiecare `period` secunde vine ploaia: cerul se
## inchide (`telegraph`), ploua (`rain_hold`), se zvanta (`dry_out`), apoi
## uscat pana la ciclul urmator.
##
## Acelasi tipar ca [EruptionCycle] (Stromboli): un nod mic, fara geometrie
## proprie, care bate ritmul intregii piste — tot ce e ciclic se aboneaza la
## el in loc sa-si tina propriul ceas. Aici insa efectul nu e un puls scurt
## de bombe, e o STARE continua (`rain_factor`) pe care alte sisteme o citesc
## in fiecare cadru: udul drumului, ceata/soarele, si (mai tarziu, cod care
## nu e in sonda asta) `WaterfallHazard` pentru greutatea cascadei Stirling.
##
## O SINGURA CALE DE UD (memoria `sonda-masura-alt-obiect` — cifra identica
## la bit intre ON/OFF ar insemna neconectat): nodul scrie `track.rain_wet`,
## acelasi camp citit de `Track.is_wet_at()`, care e deja calea prin care
## `Car._physics_process` intreaba „e ud aici?" pentru `custom_wet_ranges`.
## NU exista un `WetHazard` sau un flag separat pe masina — comentariul din
## car.gd langa `wet_here` e explicit ca banda uda se reinnoieste in fiecare
## cadru, deci un flag global e suficient.
##
## Efecte, in ordinea din brief:
## 1. `track.rain_wet` (fizica: singura cale, vezi mai sus);
## 2. lerp pe `fog_depth_end` al `Environment`-ului si pe `sun.light_energy`
##    al `DirectionalLight3D`-ului gasite in scena (tiparul `FogCorridorHazard`:
##    valorile de baza se iau O SINGURA DATA si se restaureaza la 0, ca alte
##    piste sa nu ramana ude daca sondele le instantiaza fara `RainCycle`);
## 3. `visible` + fade (prin `modulate`/`transparency`, cand nodul suporta) pe
##    tot ce e in grupul `rain_falls`;
## 4. grupul propriu `rain_cycle`, ca alte hazarde (viitorul `WaterfallHazard`)
##    sa gaseasca metronomul si sa-i citeasca `rain_factor` fara referinta directa;
## 5. TELEGRAPH-UL VIZIBIL (sep 2026, dupa „nu exista rain" la volan): cerul
##    (`ProceduralSkyMaterial` + `fog_sky_affect` + ambient) se inchide in prima
##    jumatate a telegraph-ului, apoi intra picaturile pe ecran ([RainScreen],
##    particule in fata camerei active), apoi cascadele de ploaie — vezi
##    `_apply_sky` si grupul de exporturi „Cer si ecran".
##
## Calibrare (brief §2.0 si §7): perioada ~95 s (5 s telegraph + 25 s ploaie +
## 5 s zvantare + restul uscat).

## Cat dureaza un ciclu complet, in secunde.
@export var period: float = 95.0:
	set(value):
		period = maxf(value, telegraph + rain_hold + dry_out + 1.0)

## Cat tine anuntul INAINTE sa inceapa ploaia propriu-zisa: `rain_factor` urca
## liniar 0 -> 1 in fereastra asta. Cerul se inchide, `sun_energy` scade,
## firele albe de pe peretele opus se aprind — dar drumul inca nu e ud (brief
## §2.0: „un jucator care se uita peste fiord stie cu un S inainte").
@export var telegraph: float = 5.0:
	set(value):
		telegraph = maxf(value, 0.1)

## Cat tine ploaia efectiva, cu `rain_factor` la 1 (drum ud, cascade de ploaie
## aprinse, ceata stransa).
@export var rain_hold: float = 25.0:
	set(value):
		rain_hold = maxf(value, 0.1)

## Cat tine zvantarea: `rain_factor` coboara liniar 1 -> 0. Simetric cu
## telegraph-ul ca sa nu existe salt la iesirea din ploaie.
@export var dry_out: float = 5.0:
	set(value):
		dry_out = maxf(value, 0.1)

## Punctul din ciclu (s) la care porneste ceasul la incarcare. Ciclul e
## telegraph -> ploaie -> zvantare -> USCAT, deci la 0 pista porneste DIRECT
## in telegraph: `rain_factor` > 0 din al doilea cadru, cascadele de ploaie
## aprinse si drumul ud in primele 35 s ale cursei (constatare 22 sep: cutiile
## de ploaie apareau „pe uscat" de la start — nu erau pe uscat, ploaia
## incepuse la t=0). `telegraph + rain_hold + dry_out` = inceputul ferestrei
## uscate: cursa porneste uscata si prima ploaie vine dupa `period` minus
## suma aceea (60 s pe Fiordland). Implicitul ramane 0 pentru sondele care
## verifica tranzitiile de la t=0 (`ProbeFiordPloaie`); pista il seteaza.
@export_range(0.0, 600.0, 0.5) var start_clock: float = 0.0

@export_group("Mediu")
## `fog_depth_end` pe uscat (m). Se citeste o singura data din Environment daca
## nu se suprascrie aici — vezi `_base_taken`.
@export var fog_end_dry: float = 320.0
## `fog_depth_end` in ploaie (m): ceata se strange, fiordul se inchide.
@export var fog_end_rain: float = 200.0
## Cat de mult se apropie culoarea cetii de alb in ploaie (0 = neschimbata,
## 1 = alb pur).
@export_range(0.0, 1.0, 0.01) var fog_whiten_rain: float = 0.55
## `sun.light_energy` pe uscat.
@export var sun_energy_dry: float = 1.1
## `sun.light_energy` in ploaie: soarele scade, dar nu dispare — e o rafala,
## nu o schimbare de tema (brief §4: raportul soare/ambient scade "natural").
@export var sun_energy_rain: float = 0.7

@export_group("Cer si ecran")
## TELEGRAPH-UL PE CER (brief §2.0: „cerul se inchide" e primul semn, cu 5 s
## inainte de prima picatura). Pe Fiordland `fog_sky_affect` e 0.20, deci
## cerul de pe ecran e in mare parte `ProceduralSkyMaterial`-ul temei, nu
## ceata — culorile lui se pot lerpui la runtime, fara material nou.
## Cerul e INCHIS COMPLET la `rain_factor` = `sky_lead` (implicit la
## jumatatea telegraph-ului), inaintea picaturilor: intai se inchide, apoi
## ploua. Pe zvantare se deschide ultimul, simetric.
@export_range(0.05, 1.0, 0.01) var sky_lead: float = 0.5
## `sky_top_color` in ploaie (gri de furtuna, in familia cetii — memoria
## `ceata-in-familia-solului`).
@export var sky_top_rain: Color = Color.html("3E4750")
## `sky_horizon_color` in ploaie.
@export var sky_horizon_rain: Color = Color.html("7E888E")
## Cat se intuneca norii (`sky_cover_modulate` e ADUNAT peste gradient, deci
## a-l lasa alb ar tine cerul luminos oricat de inchis ar fi gradientul).
@export_range(0.0, 1.0, 0.01) var sky_cover_dim_rain: float = 0.45
## Cat din cer preia ceata in ploaie (`fog_sky_affect`): orizontul se topeste
## in ceata, fiordul se inchide si pe verticala.
@export_range(0.0, 1.0, 0.01) var fog_sky_affect_rain: float = 0.55
## Ambientul in ploaie, ca fractie din cel de baza (cerul inchis lumineaza
## mai putin; nu sub 0.7 — brief §4 vrea drumul citibil in ploaie).
@export_range(0.5, 1.0, 0.01) var ambient_scale_rain: float = 0.85
## Ploaia PE ECRAN ([RainScreen], particule in fata camerei). Stins = zero
## noduri create; e primul strat de taiat pe device (brief §6).
@export var screen_rain: bool = true
## De la ce `rain_factor` apar primele picaturi (brief §2.0: cerul intai,
## apoi „prime picaturi", apoi cascadele). 0.25 = la 1,25 s din telegraph.
@export_range(0.0, 0.9, 0.01) var screen_lead: float = 0.25

## Grupul de noduri „cascade de ploaie" (teatru, cost zero): vizibile DOAR in
## ploaie, cu fade pe intrare/iesire ca sa nu apara cu un pocnet.
@export var rain_falls_group: StringName = &"rain_falls"

## Emis de fiecare data cand se schimba starea binara ud/uscat (nu la fiecare
## cadru — doar la tranzitie), ca HUD-ul sau sunetul sa se agate de un
## eveniment, nu sa citeasca `rain_factor` in `_process`.
signal rain_changed(raining: bool)

## 0 = uscat, 1 = in ploaie plina. Continuu, ramps liniare pe telegraph/zvantare
## — fara salturi peste rata de `1/telegraph` sau `1/dry_out` pe cadru.
var rain_factor: float = 0.0

## Fazele ciclului, in ordinea in care se succed. Public ca sondele sa poata
## citi in ce faza suntem fara sa reconstruiasca pragurile din `_clock`.
enum Phase { DRY, TELEGRAPH, RAIN, DRY_OUT }
var phase: Phase = Phase.DRY

var _clock: float = 0.0
var _was_raining: bool = false
var _track: Track = null
var _env: Environment = null
var _sun: DirectionalLight3D = null
var _base_taken: bool = false
var _base_fog_end: float = 0.0
var _base_fog_color: Color = Color.WHITE
var _base_sun_energy: float = 1.0
var _sky: ProceduralSkyMaterial = null
var _base_sky_top: Color = Color.WHITE
var _base_sky_horizon: Color = Color.WHITE
var _base_sky_cover: Color = Color.WHITE
var _base_fog_sky_affect: float = 1.0
var _base_ambient_energy: float = 1.0
## Scriptul se ia prin preload, nu prin `class_name`: cache-ul de clase globale
## se reface doar la `--import`/editor, iar o sonda pornita intre timp ar pica
## la parsare pe un tip necunoscut (platit: 4 seed-uri de ProbeRace fara ploaie).
const RAIN_SCREEN_SCRIPT: GDScript = preload("res://scenes/hazards/rain_screen.gd")
var _screen: GPUParticles3D = null
var _fall_nodes: Array[Node] = []
## Modulate/transparency de baza al fiecarui nod din `rain_falls`, ca fade-ul
## sa poata reveni exact la ce era, nu la un implicit ghicit.
var _fall_base_alpha: Array[float] = []


func _ready() -> void:
	add_to_group(&"rain_cycle")
	if Engine.is_editor_hint():
		set_process(false)
		return
	_clock = fposmod(start_clock, period)
	# AMANAT: `track` si nodurile din `rain_falls` sunt construite de pista in
	# `rebuild()`/`_ready()`-ul ei, care ruleaza inaintea copiilor dar dupa
	# `_init`; cautarea in sus/jos pe arbore trebuie sa gaseasca o scena deja
	# populata. Acelasi motiv ca `_resync.call_deferred()` in EruptionCycle.
	_collect.call_deferred()


func _collect() -> void:
	if not is_inside_tree():
		return
	_track = _find_track()
	_env = _find_environment()
	_sun = _find_sun()
	if _env != null and _env.sky != null:
		_sky = _env.sky.sky_material as ProceduralSkyMaterial
	_take_base()
	if screen_rain and _screen == null and not Engine.is_editor_hint():
		# Copil al metronomului (Node fara transform): RainScreen isi ia
		# pozitia din camera activa, nu din parinte, deci ierarhia nu conteaza.
		_screen = RAIN_SCREEN_SCRIPT.new() as GPUParticles3D
		add_child(_screen)
	_fall_nodes = get_tree().get_nodes_in_group(rain_falls_group)
	_fall_base_alpha.clear()
	for n in _fall_nodes:
		_fall_base_alpha.append(_node_alpha(n))
	# Stare initiala uscata, aplicata explicit: o pista incarcata la mijlocul
	# unui ciclu anterior (sonda, editor) nu trebuie sa mosteneasca vizual
	# starea ramasa de la o rulare precedenta.
	_apply(0.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock = fposmod(_clock + delta, period)
	var f := _factor_at(_clock)
	rain_factor = f
	phase = _phase_at(_clock)
	_apply(f)
	var raining := f > 0.0001
	if raining != _was_raining:
		_was_raining = raining
		rain_changed.emit(raining)


## `rain_factor` la un anumit punct din ciclu — functie pura, ca sondele sa
## poata verifica tranzitiile fara sa astepte `period` secunde de `_process`.
func _factor_at(t: float) -> float:
	if t < telegraph:
		return t / telegraph # 0 -> 1
	t -= telegraph
	if t < rain_hold:
		return 1.0
	t -= rain_hold
	if t < dry_out:
		return 1.0 - t / dry_out # 1 -> 0
	return 0.0


func _phase_at(t: float) -> Phase:
	if t < telegraph:
		return Phase.TELEGRAPH
	t -= telegraph
	if t < rain_hold:
		return Phase.RAIN
	t -= rain_hold
	if t < dry_out:
		return Phase.DRY_OUT
	return Phase.DRY


func _find_track() -> Track:
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			return n as Track
		n = n.get_parent()
	return null


## Cauta pornind de la RADACINA ARBORELUI (`get_tree().root`), nu de la
## `current_scene`: o sonda care instantiaza pista direct cu
## `get_tree().root.add_child(track)` (tiparul din probe_theme.gd/probe_wet.gd)
## o aseaza ca SORA a lui `current_scene`, nu ca fiica — o cautare pornita de
## la `current_scene` n-ar gasi niciodata `WorldEnvironment`-ul pistei. In
## jocul real `track` e oricum sub `current_scene`, care e sub `root`, deci
## acelasi punct de start functioneaza in ambele cazuri.
func _search_root() -> Node:
	if _track != null and _track.is_inside_tree():
		return _track.get_tree().root
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
	if _env != null:
		_base_fog_end = _env.fog_depth_end
		_base_fog_color = _env.fog_light_color
		_base_fog_sky_affect = _env.fog_sky_affect
		_base_ambient_energy = _env.ambient_light_energy
	else:
		_base_fog_end = fog_end_dry
	if _sky != null:
		_base_sky_top = _sky.sky_top_color
		_base_sky_horizon = _sky.sky_horizon_color
		_base_sky_cover = _sky.sky_cover_modulate
	if _sun != null:
		_base_sun_energy = _sun.light_energy
	else:
		_base_sun_energy = sun_energy_dry
	_base_taken = true


## Aplica `amount` (0..1) pe fizica si pe mediu. Fizica e binara (peste orice
## `amount` > 0 drumul e ud — brief-ul nu cere un grip intermediar in
## telegraph), mediul e continuu (lerp).
func _apply(amount: float) -> void:
	if _track != null:
		_track.rain_wet = amount > 0.0
	if _env != null and _base_taken:
		_env.fog_depth_end = lerpf(_base_fog_end, fog_end_rain, amount)
		_env.fog_light_color = _base_fog_color.lerp(Color.WHITE, amount * fog_whiten_rain)
	if _sun != null and _base_taken:
		_sun.light_energy = lerpf(_base_sun_energy, sun_energy_rain, amount)
	_apply_sky(amount)
	if _screen != null:
		# Picaturile intra DUPA ce cerul a inceput sa se inchida (screen_lead)
		# si ajung la plin odata cu ploaia; pe zvantare dispar primele.
		var k := clampf((amount - screen_lead) / maxf(1.0 - screen_lead, 0.01),
			0.0, 1.0)
		_screen.call("set_intensity", k)
	_apply_rain_falls(amount)


## Cerul se inchide PRIMUL: la `amount` = `sky_lead` e deja complet gri. Tot ce
## e aici e lerp pe proprietati existente (ProceduralSkyMaterial + Environment),
## zero materiale noi; la 0 revine exact la valorile de baza citite o singura
## data in `_take_base`.
func _apply_sky(amount: float) -> void:
	if not _base_taken:
		return
	var k := clampf(amount / maxf(sky_lead, 0.01), 0.0, 1.0)
	if _sky != null:
		_sky.sky_top_color = _base_sky_top.lerp(sky_top_rain, k)
		_sky.sky_horizon_color = _base_sky_horizon.lerp(sky_horizon_rain, k)
		var cover := _base_sky_cover
		var dim := lerpf(1.0, 1.0 - sky_cover_dim_rain, k)
		_sky.sky_cover_modulate = Color(cover.r * dim, cover.g * dim, cover.b * dim, cover.a)
	if _env != null:
		_env.fog_sky_affect = lerpf(_base_fog_sky_affect, fog_sky_affect_rain, k)
		_env.ambient_light_energy = lerpf(_base_ambient_energy,
			_base_ambient_energy * ambient_scale_rain, k)


## Grupul `rain_falls`: vizibil doar cand `amount` > 0, cu fade liniar pe
## modulate/transparency ca sa nu aprinda/stinga cu un pocnet.
func _apply_rain_falls(amount: float) -> void:
	for i in _fall_nodes.size():
		var n := _fall_nodes[i]
		if not is_instance_valid(n):
			continue
		var visible_prop: bool = amount > 0.0001
		if "visible" in n:
			n.set("visible", visible_prop)
		_set_node_alpha(n, _fall_base_alpha[i] * amount)


func _node_alpha(n: Node) -> float:
	if n is CanvasItem:
		return (n as CanvasItem).modulate.a
	if n is GeometryInstance3D or n is Node3D:
		if "modulate" in n:
			return n.get("modulate").a
	return 1.0


func _set_node_alpha(n: Node, a: float) -> void:
	if n is CanvasItem:
		var ci := n as CanvasItem
		var m := ci.modulate
		m.a = a
		ci.modulate = m
	elif "modulate" in n:
		var m2: Color = n.get("modulate")
		m2.a = a
		n.set("modulate", m2)


# ---------------------------------------------------------- pentru sonde

## Forteaza direct un punct din ciclu (secunde de la inceputul lui), pentru
## sondele care vor sa verifice o faza anume fara sa astepte `_process`.
##
## OPRESTE ceasul automat (`set_process(false)`): altfel `_process` ar avansa
## `_clock` chiar in cadrul URMATOR si ar suprascrie valoarea fortata — exact
## bug-ul gasit la constructia sondei (ProbeFiordPloaie): un `force_factor(0.0)`
## parea sa "revina" la ud pe cadrul imediat urmator, fiindca ceasul liber
## pornea de la 0 si `_factor_at(delta)` e deja > 0 dupa un singur cadru.
## `resume_clock()` reporneste ciclul automat, pentru cine vrea sa foloseasca
## acelasi nod si ca metronom normal dupa un test fortat.
func force_clock(t: float) -> void:
	set_process(false)
	_clock = fposmod(t, period)
	rain_factor = _factor_at(_clock)
	phase = _phase_at(_clock)
	_apply(rain_factor)


## Forteaza `rain_factor` la o valoare arbitrara, ocolind ceasul — folosit de
## sonda pentru testul A/B (ploaie ON fortat, fara sa astepte telegraph-ul).
## Vezi nota de la `force_clock` despre de ce opreste `_process`.
func force_factor(f: float) -> void:
	set_process(false)
	rain_factor = clampf(f, 0.0, 1.0)
	phase = Phase.RAIN if rain_factor > 0.0 else Phase.DRY
	_apply(rain_factor)


## Reporneste ceasul automat dupa un `force_factor`/`force_clock`.
func resume_clock() -> void:
	set_process(true)


func environment() -> Environment:
	return _env


func sun() -> DirectionalLight3D:
	return _sun


func track_ref() -> Track:
	return _track


## Ploaia de pe ecran (null cand `screen_rain` e stins sau in editor).
func screen() -> GPUParticles3D:
	return _screen
