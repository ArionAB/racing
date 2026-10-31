@tool # vizibil si in preview-ul din editor
class_name SlidingHazard
extends AnimatableBody3D
## Obstacol mobil care traverseaza soseaua dintr-o parte in alta.
## AnimatableBody3D = corp "static" pe care il misti tu din cod, iar fizica
## ii calculeaza corect viteza pentru corpurile care il ating.
##
## Poate folosi un model 3D (ex. mingea de plaja din Blender); fara model,
## cade pe cutia galbena placeholder. Cu roll_radius > 0 modelul se
## ROSTOGOLESTE fizic corect: unghi = distanta parcursa / raza.
##
## Ce il face CINSTIT e ca te dezechilibreaza, nu ca te scoate din cursa: la
## contact primesti un ghiont care te scoate din pensa (cooldown per masina).
## Fara el, un corp cinematic care impinge un CharacterBody3D il tine lipit de
## perete zeci de cadre — masurat cu tools/probe_race.gd: o masina cu 139 de
## cadre de contact intr-o singura cursa, adica blocata acolo, nu lovita.
##
## Ce am invatat masurand, si merita scris ca sa nu se reincerce: incetinirea
## maturarii "ca sa fie mai citibil" INRAUTATESTE lucrurile. Cu perioada dubla,
## obstacolul devine un blocaj semi-static pe drum si toata lumea intra in el
## (cadre de contact per masina: ~10 la perioada originala, ~110 la dublu).
## Un obstacol rapid traverseaza si elibereaza drumul; unul lent sta in el.

## Cum se misca obstacolul de-a lungul axei `travel`.
##
## PENDULARE e implicitul si tot ce a existat pana la #241: du-te-vino
## sinusoidal, la nesfarsit. Mecanic e corect, dar nu spune nicio poveste —
## nimic din lume nu se plimba perpetuu pe acelasi metru de drum. TRAVERSARE
## e tractorul din Ignition: vehiculul asteapta parcat pe acostament,
## traverseaza intr-un singur sens si parcheaza pe partea cealalta.
##
## Ritmul difera, si asta e tot rostul: la pendulare inveti o sinusoida, la
## traversare PANDESTI O FEREASTRA — ca la tren, dar fara infrastructura lui.
##
## USA e piatra de moara din orasul subteran (Cappadocia, brief §2 POI F:
## „inchis = zid"). E exact inversul TRAVERSARII pe un capat: un capat al
## cursei e nisa laterala (banda libera), celalalt e PE banda, unde piatra STA
## cateva secunde ca zid static, apoi se intoarce in nisa. Masurat inainte de
## a exista modul asta: cu TRAVERSARE, ambele capete de parcare cadeau in afara
## asfaltului, usa era deschisa ~87% din timp si „inchisa" doar o matura de
## 0.75 s — adica tot bilantul de decizie al briefului („piatra inchisa
## ≈ +2,5 s pe ocol") se sprijinea pe o stare care nu exista. Un zid care
## dureaza e ce face ocolul sa merite: cine vede usa inchizandu-se ia ocolul,
## cine o prinde deschisa castiga. Nu contrazice regula „un obstacol care STA
## in drum e mobilier": aia e pentru obstacole fara alternativa; usa are
## ocolul, deci starea inchisa e o decizie, nu un blocaj.
##
## Membrii noi se adauga LA COADA: valorile serializate in .tscn (HazardMarker
## `motion = 1`) sunt indici, iar scriptul asta e folosit de mai multe piste.
enum Motion {
	PENDULARE,  ## du-te-vino sinusoidal, fara oprire
	TRAVERSARE, ## asteapta, traverseaza intr-un sens, asteapta pe partea cealalta
	USA,        ## sta in nisa (liber), se rostogoleste PE banda, sta ca zid, se intoarce
}

## Cat de repede matura, la maximum (mijlocul cursei). Perioada se DEDUCE din
## viteza asta si din cursa reala, ca obstacolele de pe piste late sa nu iasa
## automat mai violente decat cele de pe piste inguste.
const MAX_SWEEP_SPEED_DEFAULT: float = 12.0

## TRAVERSARE — cat sta parcat pe acostament intre doua treceri.
##
## Lung dinadins. Un vehicul care traverseaza la fiecare 2 s redevine exact
## bariera pendulanta pe care o inlocuieste: daca e mereu pe drum, nu mai e un
## eveniment, e mobilier. Pauza e cea care face fereastra sa insemne ceva.
const CROSS_WAIT: float = 5.0
## Cat se urneste in loc inainte de a intra pe asfalt.
##
## Telegraful obstacolelor din proiect (bolovanul 1.4 s, avalansa 3.2 s):
## vehiculul se pune in miscare vizibil inainte sa ajunga pe carosabil, ca
## trecerea sa poata fi anticipata, nu doar incasata.
const CROSS_TELEGRAPH: float = 1.2
## USA — cat sta deschisa (parcata in nisa, banda libera) si cat sta INCHISA
## (pe banda, zid). Cu telegraful si cele doua rostogoliri (cursa de 4.5 m la
## DOOR_ROLL_SPEED = 2.5 s fiecare) ciclul iese ~23 s, cat cere brieful
## Cappadocia. Inchisa destul cat sa fie o stare, nu o clipa: la 6 s cine a
## prins-o inchizandu-se ar fi pierdut mai mult asteptand decat pe ocol
## (+1.85…+2.36 s masurat), deci ocolul chiar e alegerea corecta.
const DOOR_OPEN: float = 10.0
const DOOR_CLOSED: float = 3.0
## Viteza de rostogolire a usii (m/s). Lenta dinadins: o piatra de 3 m care
## traverseaza 4.5 m in 2.5 s se CITESTE ca usa care se inchide; la viteza
## maturarii (12 m/s) ar fi o clipire. Regula din antet („lent = mobilier")
## nu se aplica: usa nu blocheaza cat se misca, ci cat sta.
const DOOR_ROLL_SPEED: float = 1.8
## Grupul din care AI-ul citeste usile (acelasi tipar ca
## RotatingSpanHazard.AI_GROUP): pilotul intreaba `door_blocks_in()` si alege
## ocolul cand poarta va fi inchisa la sosire.
const DOOR_GROUP: StringName = &"door_hazards"
## Grupul din care AI-ul citeste traversarile cu sens care CER cedare de trecere
## (`ai_yields`): ursul de pe Transfagarasan (#603). Fara el, plutonul intra in
## animal la 40 m/s (masurat: 3 ejectari din 3 curse la ursul de la 0.199) — un
## AI care nu vede ce vede jucatorul nu e „AI onest".
const CROSSING_GROUP: StringName = &"crossing_hazards"
## Banda lasata libera langa perete. 0 = fara limitare (cursa exact cat cere
## pista). Exista pentru piste inguste, unde maturarea pana in perete ar lasa
## banda plina fara iesire.
const ESCAPE_LANE_DEFAULT: float = 0.0
## m/s dati masinii lovite, ca sa iasa din calea obstacolului.
const SWEEP_PUSH: float = 5.5

## `follow_ground` — cat poate cobori / urca solul fata de linia asfaltului
## inainte ca obstacolul sa se OPREASCA acolo, in loc sa-l urmeze. Un animal
## coboara un taluz de un metru si jumatate; nu coboara peretele unei coame.
## Masurat pe coama Serengeti (E_Ankole1-5): la umar solul e la -1,1 m, iar
## dupa un metru cade la -5…-21 m. Fara oprire, vaca ar fi coborat peretele.
const GROUND_MAX_DROP: float = 1.5
const GROUND_MAX_RISE: float = 3.0
## Esantioane ale profilului de sol pe toata cursa (-1..+1).
const GROUND_SAMPLES: int = 41
## Cate cadre de fizica se reincearca profilul (terenul intra in spatiul fizic
## abia dupa primul pas, ca la `AvalancheHazard`).
const GROUND_ATTEMPTS: int = 30

## Modelele cu schelet (vaca) isi aleg animatia dupa VITEZA REALA a nodului,
## nu dupa faza de miscare: aceeasi regula acopera si pendularea (viteza
## sinusoidala — la capete vaca incetineste si se apuca de pascut) si
## traversarea (parcat = paste, telegraf + trecere = merge). Numele sunt
## conventia GLB-urilor noastre animate (build_cow_animated.py); un model
## fara AnimationPlayer sau fara "Walk" ramane teapan, ca pana acum.
const ANIM_REST := [&"Eating", &"Idle"] # prima gasita castiga
const ANIM_WALK := &"Walk"
const ANIM_RUN := &"Gallop"
## Clip OPTIONAL jucat pe durata telegrafului unei traversari (ursul se ridica
## in doua labe). Un model fara el ramane exact ca inainte.
const ANIM_STAND := &"Stand"
## Peste viteza asta pasul devine galop (vaca la trap real ~3 m/s).
const RUN_SPEED: float = 3.0
## Vitezele "naturale" ale ciclurilor, ca ritmul pasilor sa urmeze nodul:
## speed_scale = viteza reala / viteza ciclului. Gasite la ochi pe sonda.
const WALK_CYCLE_SPEED: float = 1.5
const RUN_CYCLE_SPEED: float = 8.0
## Viteza naturala a ciclului PE MODEL (m/s la `model_scale` 1 si ritm 1): cat de
## repede sta talpa inapoi in sprijin, masurat din clip cu
## `tools/probe_foot_slide.gd` (ritmul care da patinare minima, v / rate*). Un
## model absent din tabel foloseste constantele de mai sus. Se inmulteste cu
## `model_scale`: piciorul unui elefant de 1,1x parcurge cu 10% mai mult pe ciclu
## (masurat: S* 1,72 la 1,0x si 1,89 la 1,1x).
const WALK_CYCLE_SPEED_BY_MODEL := {
	&"horse_bay": 1.55, &"horse_pinto": 1.55, &"horse_black": 1.55,
	&"elephant": 1.72, &"cow": 0.94,
	# lama: 2,34 m/s masurat la model_scale 3,135 (Track15) -> 0,746 la 1,0
	&"llama": 0.746, &"llama_b": 0.746, &"llama_c": 0.746,
	# ursul brun (Transfagarasan, Track21): pasul greu; cheia e numele fisierului
	# (`model_scene.resource_path.get_file().get_basename()`), deci `brown_bear.glb`.
	&"brown_bear": 0.97,
}
## Galop: vaca din cireada Serengeti (12 m/s) are S* = 4,06 (patinare minima
## 3,3 m/s la ritm 2,87; cu constanta globala 8,0 ritmul ar fi 1,46).
const RUN_CYCLE_SPEED_BY_MODEL := {&"cow": 4.06}
const ANIM_BLEND: float = 0.4

var center: Vector3
var travel: Vector3 # amplitudinea (vector lateral, jumatate de cursa)
## Pendulare (implicit) sau traversare cu sens. Vezi [enum Motion].
var motion: Motion = Motion.PENDULARE
## Lasata pe 0 = dedusa din `max_sweep_speed` si din cursa reala. Pusa explicit,
## are prioritate (util daca vrei un obstacol anume mai lent).
var period: float = 0.0
var max_sweep_speed: float = MAX_SWEEP_SPEED_DEFAULT
## Semilatimea soselei, ca sa stim unde e marginea. 0 = necunoscuta, si atunci
## cursa ramane exact cea ceruta de pista.
var road_half_width: float = 0.0
var escape_lane: float = ESCAPE_LANE_DEFAULT
## Defazaj 0..1 dintr-o perioada. Doua obstacole pe aceeasi pista cu acelasi
## defazaj se misca la unison si arata ca un mecanism, nu ca doua obstacole.
var phase: float = 0.0
## TRAVERSARE cu model care are un „inainte": la drumul de intoarcere corpul
## se INTOARCE cu fata spre sensul de mers (o jumatate de tura in jurul
## verticalei), in loc sa mearga cu spatele. Pus de pista odata cu
## `face_travel`. Pendularea si usa nu-l folosesc.
var turn_around: bool = false
## Corpul calca pe SOL pe toata cursa, nu pe linia dreapta prin asfalt.
##
## Fara el, cota e cea a centrului (axa drumului) pana la capatul de parcare —
## corect pe campie, gresit oriunde acostamentul coboara: vacile de pe coama
## Serengeti (#503) pareau sa pluteasca la capatul din dreapta, cu versantul
## la 5-21 m sub copite. Cu el, cota vine dintr-un profil de sol masurat o
## singura data pe axa cursei (teren + sosea, fara decor, masini sau apa), iar
## capatul de pe o parte care cade in gol se scurteaza pana la buza (vezi
## GROUND_MAX_DROP).
##
## OPT-IN, nu implicit: un obstacol care traverseaza APA (jonca de pe Ha Long)
## ar fi coborat pe fundul marii.
var follow_ground: bool = false

## Model optional + configuratia lui.
var model_scene: PackedScene
## Ce PIESA din GLB se pastreaza (celelalte copii directe ai radacinii se
## arunca). Gol = tot fisierul, ca pana acum. Exista fiindca kitul Monument
## Valley tine ambele poze ale calului (`Pose_Stand`, `Pose_Walk`) in acelasi
## GLB: fara filtru s-ar randa suprapuse. Acelasi nume de camp ca la
## `RockfallHazard.model_node` / `DeflectorHazard.model_node`.
var model_node: String = ""
var model_scale: float = 1.0
var roll_radius: float = 0.0 # >0 = sfera care se rostogoleste
## Clasa de textura a modelului ("" = atlasul comun). Se aplica TRIPLANAR IN
## SPATIUL OBIECTULUI, nu al lumii: obstacolul se misca, iar proiectia de lume
## i-ar face textura sa "inoate" pe suprafata (style_bible §4).
var model_tri_class: String = ""
## Clase pe PIESE numite, pentru modelele care nu sunt dintr-un material unic.
## Bolovanul e integral roca si ii ajunge `model_tri_class`; barca sabani are
## coca de lemn si o dunga vopsita, deci ii trebuie maparea per nod — aceeasi
## impartire ca la landmark-uri ("tri_class" vs "classes").
var model_classes: Dictionary = {}
## Sunetul de contact (feel_checklist: hazards-speak): ghiontul bariere il reda
## pozitional, la masina lovita. Gol = hazard mut (o pista poate sa-l stinga).
var contact_sfx: StringName = &"hazard_barrier_hit"

## Doar TRAVERSARE: AI-ul franeaza si asteapta cat animalul e pe asfalt (sau va fi
## la sosire). Stins implicit: vacile si caii de pe celelalte piste raman ca pana
## acum (bit-identic).
var ai_yields: bool = false

var _time: float = 0.0
var _pivot: Node3D
## AnimationPlayer-ul modelului, daca GLB-ul are schelet. Vezi ANIM_* sus.
var _anim: AnimationPlayer
## Pasul legat de distanta (elefantul: picioarele nu patineaza, #613). Null la
## modelele fara oasele de picior numite (vaca, camila: pasul vine din clip).
var _stride: StrideDriver
var _anim_rest: StringName = &""
var _stand_started: bool = false
var _walk_cycle_speed: float = WALK_CYCLE_SPEED
var _run_cycle_speed: float = RUN_CYCLE_SPEED
var _last_pos: Vector3
var _area: Area3D
var _half_extent: float = 1.3
var _configured: bool = false
## Masina lovita -> secunde pana poate fi imbrancita din nou.
var _cooldown: Dictionary = {}
## Viteza reala a corpului la ultimul pas (m/s). USA nu imbranceste cat sta.
var _speed: float = 0.0
## `follow_ground`: abaterea solului fata de linia cursei, pe GROUND_SAMPLES
## puncte de la -1 la +1, si cat din cursa se parcurge pe fiecare parte.
var _ground_dy := PackedFloat32Array()
var _ground_attempts: int = GROUND_ATTEMPTS
var _reach_neg: float = 1.0
var _reach_pos: float = 1.0

func _ready() -> void:
	sync_to_physics = true
	if model_scene != null:
		_build_model()
	else:
		_build_placeholder_box()
	if not Engine.is_editor_hint():
		_build_sweep_area()

## Cursa si perioada se calculeaza la primul tick, nu in _ready: pista pune
## `travel` DUPA add_child (adica dupa _ready), asa ca aici amplitudinea ar fi
## inca zero si limitarea n-ar face nimic.
func _configure() -> void:
	_configured = true
	_clamp_travel()
	if period <= 0.0:
		period = _readable_period()
	if motion == Motion.USA and not is_in_group(DOOR_GROUP):
		add_to_group(DOOR_GROUP)
	if motion == Motion.TRAVERSARE and ai_yields and not is_in_group(CROSSING_GROUP):
		add_to_group(CROSSING_GROUP)
	# Pozitia de start a defazajului, nu centrul: altfel primul cadru "vede" o
	# deplasare de toata amplitudinea si roteste mingea brusc.
	_last_pos = _pos_at(_offset_now())

## Obstacolul nu iese niciodata din sosea: cursa se taie astfel incat MARGINEA
## lui sa se opreasca la marginea drumului (plus `escape_lane`, daca pista e
## ingusta si vrei sa ramana si o banda de trecere). Pista cere maturarea
## maxima, aici se decide cat e cinstit pe latimea asta de sosea.
##
## La TRAVERSARE regula se INVERSEAZA, si asta e diferenta de fond dintre cele
## doua moduri: capatul cursei e locul in care vehiculul PARCHEAZA, deci trebuie
## sa cada dincolo de asfalt. Taiat ca la pendulare, tractorul ar astepta oprit
## pe banda si ar fi un zid pe jumatate de drum — exact ce nu vrem, fiindca un
## obstacol care STA in drum e mobilier, nu eveniment (vezi masuratoarea din
## antetul clasei: obstacol lent = toata lumea intra in el).
##
## USA foloseste aceeasi regula pentru capatul din nisa (-1): piatra parcata
## trebuie sa elibereze complet banda. Capatul inchis e centrul cursei (0),
## adica axa soselei, si nu se taie — vezi `_door_offset`.
func _clamp_travel() -> void:
	if road_half_width <= 0.0:
		return
	if motion == Motion.TRAVERSARE or motion == Motion.USA:
		# Capatul curse: marginea drumului PLUS tot corpul, ca sa se elibereze
		# complet carosabilul, plus o palma de acostament.
		var park := road_half_width + _half_extent + 1.0
		travel = travel.normalized() * park if travel.length() > 0.001 \
			else travel
		return
	var max_amp := maxf(road_half_width - _half_extent - escape_lane, 0.0)
	if travel.length() > max_amp:
		travel = travel.normalized() * max_amp

## Perioada la care varful de viteza (mijlocul cursei) ramane sub plafon.
## Viteza maxima a unei oscilatii sinusoidale de amplitudine A: A * TAU / T.
##
## La TRAVERSARE viteza e CONSTANTA, nu sinusoidala, deci formula e alta:
## traversarea dureaza `period * 0.5` (vezi `_offset_now`) si acopera toata
## cursa 2A, adica viteza e 2A / (T/2) = 4A / T. Cu formula sinusoidala,
## acelasi numar ar fi dat o trecere cu ~27% mai iute decat plafonul cerut —
## adica exact genul de „obstacolul asta e mai violent decat celelalte" care
## nu se vede in cod, ci abia la playtest.
func _readable_period() -> float:
	var amp := travel.length()
	if amp < 0.01 or max_sweep_speed <= 0.0:
		return 3.2
	if motion == Motion.TRAVERSARE:
		return maxf(4.0 * amp / max_sweep_speed, 1.5)
	if motion == Motion.USA:
		# O rostogolire (nisa -> axa) acopera amplitudinea A si dureaza
		# `period * 0.5`, ca la traversare; viteza e cea a usii, nu plafonul
		# maturarii — vezi DOOR_ROLL_SPEED.
		return maxf(2.0 * amp / DOOR_ROLL_SPEED, 1.5)
	return maxf(TAU * amp / max_sweep_speed, 1.5)

func _build_model() -> void:
	var model := model_scene.instantiate() as Node3D
	if not model_node.is_empty():
		for child in model.get_children():
			# AnimationPlayer-ul GLB-ului (calul Monument Valley: armatura e
			# nodul `Pose_Walk`, playerul ii e frate) ramane: fara el, filtrul
			# ar arunca animatiile odata cu poza statica.
			if child.name != model_node and not child is AnimationPlayer:
				model.remove_child(child)
				child.queue_free()
	model.scale = Vector3.ONE * model_scale
	# `roll_radius` primit de la apelant e o INTENTIE ("obiectul asta se
	# rostogoleste"), nu o masuratoare. Raza efectiva se ia din model, ca un GLB
	# regenerat la alt diametru sa nu ramana cu o sfera de coliziune de alta
	# marime decat ce se vede. Apelantul o calcula de mana din diametrul de 5 m
	# al mingii — exact numarul care se schimba la inlocuirea cu un bolovan.
	if roll_radius > 0.0:
		var measured := Track.model_aabb(model)
		var d := maxf(measured.size.x, measured.size.z)
		if d > 0.02:
			roll_radius = d * 0.5
	# Pivotul sta la inaltimea centrului sferei; modelul (origine in centru)
	# se aseaza in pivot, iar rostogolirea roteste pivotul.
	_pivot = Node3D.new()
	_pivot.position = Vector3.UP * roll_radius
	add_child(_pivot)
	_pivot.add_child(model)
	# Atlasul comun. Modelele vechi (mingea de plaja) isi aduceau materialul lor
	# si mergeau fara asta; cele care respecta contractul de paleta au UV-uri
	# spre sloturi si un material fara imagine — fara apel, ies gresit.
	# Cu o clasa ceruta (bolovanul din desert = "rock"), textura de clasa ia
	# locul atlasului — dar in spatiul OBIECTULUI, ca sa se rostogoleasca odata
	# cu el. `model_scale` intra in socoteala ca pietrele pictate sa masoare in
	# lume cat cele de pe falezele din care s-a desprins.
	# REMAP-UL DE SLOTURI, inainte de material. Un hazard care isi incarca
	# singur GLB-ul nu trece prin WorldProp, deci nu primea corectiile din
	# `SLOT_REMAP_BY_MODEL` (handoff §5.9, aceeasi capcana ca la hipopotam):
	# elefantul din Serengeti sta pe sloturi gri NEUTRE, care sub soarele cald
	# al temei ies albe — masurat, hazardul era alb langa decorul gri corect,
	# adica acelasi animal in doua culori. Tabela ramane una singura, in
	# WorldProp; aici doar se aplica.
	_remap_model_slots(model)
	# Ruptura de accente (elefant: fildesii raman pe atlas), INAINTE de
	# materiale — acelasi ordin ca `WorldProp._split_shutters` si acelasi
	# motiv: nodul `_Accente` trebuie sa existe cand se aplica maparea, altfel
	# ramane pe materialul implicit.
	_split_model_accents(model)
	if not model_classes.is_empty():
		# CUANTIZAT la pas 0.5, ca in `avalanche_hazard.gd` (bolovanul de
		# zapada): `object_triplanar_class_material` cacheaza pe (clasa,
		# scale), deci scari distincte insemna materiale distincte pentru
		# aceeasi textura — exact regresia pe care o vaneaza
		# `tools/probe_decor.gd`. G_Elefant1 (1.0) si G_Elefant2 (1.1) ar fi
		# dat DOUA materiale `elephant_hide` (masurat: 29 -> 31 pe Track14,
		# buget +1) pentru un tipar de piele care la 10% diferenta de scara
		# nu se distinge de la volan. `model.scale` (linia de mai sus, deci
		# gabaritul de coliziune) NU se atinge — doar intrarea in cache-ul de
		# textura.
		var tex_scale := maxf(snappedf(model_scale, 0.5), 0.5)
		# OBIECT-spatiu, nu `apply_class_materials`: hazardul se MISCA
		# (traversare/pendulare), iar o clasa "tri:" proiectata in spatiul
		# lumii ar lasa textura pe loc in timp ce corpul aluneca pe sub ea —
		# acelasi defect ca la bolovanul de zapada din avalanche_hazard.gd.
		# Pentru clasele fara prefix "tri:" (ex. barca sabani, "wood") nu
		# schimba nimic: `class_material` foloseste UV-uri reale, nu
		# triplanar, deci world-space si object-space produc acelasi material.
		Palette.apply_object_class_materials(model, model_classes, tex_scale)
		# A DOUA trecere, doar pe accentele NUMITE EXACT in mapare.
		# `Palette._class_for` (folosit de apelul de mai sus) respinge ORICE
		# nod terminat in `_Accente`, indiferent ce spune maparea — pazitorul
		# corect impotriva prefixelor lacome (`House_A` nu trebuie sa se
		# reverse peste `House_A_Accente`). Dar elefantul chiar VREA clasa PE
		# accent (`Elephant_Mesh_Accente`): fildesii raman pe corp, pielea
		# pleaca in accent, exact ca `WorldProp.ACCENT_HOLDS_CLASS` +
		# `_apply_model_classes` pentru decorul static. Aici e varianta ei
		# pentru un hazard care nu trece prin WorldProp.
		_apply_named_accent_classes(model, tex_scale)
	elif model_tri_class.is_empty():
		Palette.apply_world_material(model)
	else:
		Palette.apply_object_triplanar_class(model, model_tri_class, model_scale)
	var shape := CollisionShape3D.new()
	if roll_radius > 0.0:
		# Un DISC (piatra de moara: 3 m diametru, 0.78 m grosime) primeste un
		# cilindru, nu o sfera. Sfera de raza 1.5 m centrata la 1.5 m ar avea la
		# inaltimea barei de protectie (0.5 m) doar 1.12 m raza — o usa cu
		# colturile rotunjite, prin care o masina se strecoara pe langa zid.
		# Cilindrul are axa pe normala discului (axa subtire a modelului) si NU
		# se invarte cu pivotul: rostogolirea e vizuala, forma e aceeasi in
		# orice faza. Vezi `Track._build_hazard` pentru orientarea usii.
		var measured := Track.model_aabb(model)
		var d := maxf(measured.size.x, measured.size.z)
		var thin := minf(measured.size.x, measured.size.z)
		if thin < d * 0.5:
			var cyl := CylinderShape3D.new()
			cyl.radius = roll_radius
			cyl.height = thin
			shape.shape = cyl
			if measured.size.z < measured.size.x:
				shape.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			else:
				shape.rotation = Vector3(0.0, 0.0, PI * 0.5)
		else:
			var sphere := SphereShape3D.new()
			sphere.radius = roll_radius
			shape.shape = sphere
		shape.position = Vector3.UP * roll_radius
		_half_extent = roll_radius
	else:
		# Cutia se MASOARA pe model cand exista unul, in loc sa ramana pe cotele
		# excavatorului. O sabani de 5 m intr-o cutie de 4.5 x 2.6 ar fi fost
		# lovita cu jumatate de metru inainte s-o atingi — si invers pe un model
		# mai mic, ai fi trecut prin ea.
		var box := BoxShape3D.new()
		# `model_aabb` porneste din transformul RADACINII, deci `model_scale` e
		# deja inauntru — inmultirea cu el ar dubla cutia. (Acelasi motiv pentru
		# care ramura cu `roll_radius` de mai sus foloseste masuratoarea direct.)
		var measured := Track.model_aabb(model)
		if measured.size.length() > 0.5:
			box.size = measured.size
			shape.position = Vector3.UP * (box.size.y * 0.5)
			_half_extent = maxf(box.size.x, box.size.z) * 0.5
		else:
			box.size = Vector3(4.5, 2.2, 2.6)
			shape.position = Vector3.UP * 1.1
			_half_extent = 2.25
		shape.shape = box
	add_child(shape)
	_hook_animation(model)

## Cauta AnimationPlayer-ul din GLB si pune ciclurile pe bucla. Buclele se
## seteaza AICI, nu in setarile de import: importul implicit lasa animatiile
## one-shot, iar o vaca ce face un singur pas si ingheata e mai rea decat una
## teapana. Fara player sau fara "Walk", _anim ramane null si nimic nu se
## schimba fata de modelele rigide.
func _hook_animation(model: Node3D) -> void:
	if Engine.is_editor_hint():
		return # in preview-ul de editor modelul sta in poza de repaus
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	if not player.has_animation(ANIM_WALK):
		return
	_anim = player
	var stem := StringName(model_scene.resource_path.get_file().get_basename())
	_walk_cycle_speed = float(WALK_CYCLE_SPEED_BY_MODEL.get(stem, WALK_CYCLE_SPEED)) * model_scale
	_run_cycle_speed = float(RUN_CYCLE_SPEED_BY_MODEL.get(stem, RUN_CYCLE_SPEED)) * model_scale
	for rest: StringName in ANIM_REST:
		if _anim.has_animation(rest):
			_anim_rest = rest
			break
	for anim_name: StringName in [ANIM_WALK, ANIM_RUN, _anim_rest]:
		if anim_name != &"" and _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	var driver := StrideDriver.new()
	if driver.attach(model, _anim.get_animation(ANIM_WALK)):
		_stride = driver
		add_child(driver)
	else:
		driver.free()

## Pasul urmeaza nodul: ce animatie si in ce ritm, din viteza reala (m/s).
func _animate(speed: float) -> void:
	if motion == Motion.TRAVERSARE and _anim.has_animation(ANIM_STAND):
		if _in_telegraph(_time):
			if not _stand_started:
				_stand_started = true
				_anim.speed_scale = 1.0
				_anim.play(ANIM_STAND, ANIM_BLEND)
			return
		_stand_started = false
	var target := _anim_rest
	var rate := 1.0
	if speed > RUN_SPEED and _anim.has_animation(ANIM_RUN):
		target = ANIM_RUN
		rate = clampf(speed / _run_cycle_speed, 0.7, 3.0)
	elif speed > 0.15:
		target = ANIM_WALK
		rate = clampf(speed / _walk_cycle_speed, 0.75, 2.2)
	if target == &"":
		# Fara animatie de repaus (elefantul are doar Walk/Trumpet): parcat pe
		# acostament STA, nu merge pe loc. Se reia de unde a ramas la urnire.
		if _anim.is_playing():
			_anim.pause()
		return
	_anim.speed_scale = rate
	if _anim.current_animation != String(target) or not _anim.is_playing():
		_anim.play(target, ANIM_BLEND)

func _build_placeholder_box() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4.5, 2.2, 2.6)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.15)
	mesh.material_override = mat
	mesh.position = Vector3.UP * 1.1
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(4.5, 2.2, 2.6)
	shape.shape = col_box
	shape.position = Vector3.UP * 1.1
	add_child(shape)
	_half_extent = 2.25

## Zona de ghiont: un pic mai grasa decat corpul solid, ca sa prinda contactul
## inainte ca masina sa apuce sa ramana captiva intre obstacol si perete.
func _build_sweep_area() -> void:
	_area = Area3D.new()
	add_child(_area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * (_half_extent * 2.0 + 1.0)
	shape.shape = box
	shape.position = Vector3.UP * maxf(_half_extent, 1.1)
	_area.add_child(shape)

func _physics_process(delta: float) -> void:
	if not _configured:
		_configure()
	_time += delta
	if follow_ground and _ground_dy.is_empty() and _ground_attempts > 0 \
			and not Engine.is_editor_hint():
		_measure_ground()
	var next_pos := _pos_at(_offset_now())
	var moved := next_pos - _last_pos
	# Intoarcerea la capat de cursa: O SINGURA scriere de transform (baza +
	# pozitie) — cu sync_to_physics, pozitia si rotatia scrise separat in
	# acelasi pas ingheata corpul tacut (memoria jolt-sync-transform).
	var flat_move := Vector3(moved.x, 0.0, moved.z)
	if turn_around and flat_move.length() > 0.01 			and (-global_transform.basis.z).dot(flat_move) < 0.0:
		global_transform = Transform3D(
			global_transform.basis.rotated(Vector3.UP, PI), next_pos)
	else:
		global_position = next_pos
	_speed = moved.length() / delta if delta > 0.0 else 0.0
	if _pivot != null and roll_radius > 0.0:
		# Rostogolire: rotatie in jurul axei perpendiculare pe miscare.
		var flat := moved
		flat.y = 0.0
		if flat.length() > 0.0001:
			var axis := Vector3.UP.cross(flat.normalized()).normalized()
			_pivot.global_rotate(axis, -flat.length() / roll_radius)
	if _anim != null and delta > 0.0:
		_animate(moved.length() / delta)
	if _stride != null:
		_stride.advance(moved.length(), delta)
	# `next_pos`, NU `global_position`: cu sync_to_physics getterul intoarce
	# transformul de acum UN PAS (scrierea de mai sus ajunge in nod abia la
	# sincronizarea fizicii), deci `moved` de la pasul urmator ar fi acoperit
	# DOUA pasi si `_speed` ar fi iesit dublu fata de viteza reala (masurat pe
	# caii din Track19: 3,88 m/s la 1,94 m/s adevarat). Ritmul pasilor
	# (`_animate`) se calculeaza din ea.
	_last_pos = next_pos
	if not Engine.is_editor_hint():
		_shove_cars(delta)

## Suntem in fereastra de telegraf a unei traversari? Oglindeste calendarul din
## [method _offset_at] (aceleasi constante), fara sa-l modifice.
func _in_telegraph(time: float) -> bool:
	var cross := period * 0.5
	var leg := CROSS_WAIT + CROSS_TELEGRAPH + cross
	var t := fposmod(time + phase * leg * 2.0, leg * 2.0)
	if t >= leg:
		t -= leg
	return t >= CROSS_WAIT and t < CROSS_WAIT + CROSS_TELEGRAPH

## Unde se afla obstacolul pe axa `travel`, ca fractie -1..+1 (−1 si +1 fiind
## cele doua margini ale cursei).
##
## Amandoua modurile se misca pe ACEEASI axa si sunt taiate de acelasi
## `_clamp_travel()`. Ce difera e doar legea de miscare, si de-aia sta intr-o
## singura functie: un al doilea camp de pozitie ar fi insemnat doua feluri de
## a sti unde e obstacolul, care ar fi divergat la prima corectie de mecanica.
func _offset_now() -> float:
	return _offset_at(_time)

## Pozitia in lume pentru o fractie de cursa -1..+1. Fara `follow_ground` e
## linia dreapta prin centru, ca pana acum; cu el, fractia se scurteaza pe
## partea care cade in gol si cota urmeaza profilul de sol.
func _pos_at(offset: float) -> Vector3:
	if _ground_dy.is_empty():
		return center + travel * offset
	var k := offset * (_reach_pos if offset > 0.0 else _reach_neg)
	var f := (k + 1.0) * 0.5 * float(GROUND_SAMPLES - 1)
	var i := clampi(int(floor(f)), 0, GROUND_SAMPLES - 2)
	var dy := lerpf(_ground_dy[i], _ground_dy[i + 1], clampf(f - float(i), 0.0, 1.0))
	return center + travel * k + Vector3.UP * dy

## Profilul solului pe axa cursei, o singura data (terenul si soseaua nu se
## misca). Se reincearca pana raspunde spatiul fizic; daca nu raspunde deloc,
## obstacolul ramane pe linia dreapta, ca fara steag.
func _measure_ground() -> void:
	_ground_attempts -= 1
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var dys := PackedFloat32Array()
	dys.resize(GROUND_SAMPLES)
	var found := 0
	for s in GROUND_SAMPLES:
		var k := -1.0 + 2.0 * float(s) / float(GROUND_SAMPLES - 1)
		var p := center + travel * k
		var gy := _ground_y(space, p)
		dys[s] = NAN if is_nan(gy) else gy - p.y
		if not is_nan(gy):
			found += 1
	if found == 0:
		return
	# Gauri (fara sol sub raza): iau vecinul cel mai apropiat cu sol.
	for s in GROUND_SAMPLES:
		if not is_nan(dys[s]):
			continue
		for d in range(1, GROUND_SAMPLES):
			if s - d >= 0 and not is_nan(dys[s - d]):
				dys[s] = dys[s - d]
				break
			if s + d < GROUND_SAMPLES and not is_nan(dys[s + d]):
				dys[s] = dys[s + d]
				break
	# Cat se merge pe fiecare parte: pana la ultimul esantion inainte de
	# primul care iese din fereastra [-GROUND_MAX_DROP, +GROUND_MAX_RISE].
	var mid := (GROUND_SAMPLES - 1) / 2
	_reach_pos = _side_reach(dys, mid, 1)
	_reach_neg = _side_reach(dys, mid, -1)
	_ground_dy = dys

func _side_reach(dys: PackedFloat32Array, mid: int, dir: int) -> float:
	var last_ok := mid
	var s := mid + dir
	while s >= 0 and s < GROUND_SAMPLES:
		if dys[s] < -GROUND_MAX_DROP or dys[s] > GROUND_MAX_RISE:
			break
		last_ok = s
		s += dir
	return float(absi(last_ok - mid)) / float(mid)

## Cota SOLULUI sub un punct: terenul si soseaua, adica corpurile statice pe
## care pista le pune direct sub ea (TerrainBody, RoadTop, fusta). Decorul
## (copaci, stanci), masinile si alte obstacole se sar — o vaca nu urca pe un
## trunchi de acacia doar fiindca raza l-a atins primul.
func _ground_y(space: PhysicsDirectSpaceState3D, at: Vector3) -> float:
	var from := at + Vector3.UP * (GROUND_MAX_RISE + 3.0)
	var exclude: Array[RID] = [get_rid()]
	for attempt in 8:
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 80.0)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var body := hit.collider as Node
		if body is StaticBody3D and body.get_parent() is Track:
			return (hit.position as Vector3).y
		exclude.append(hit.rid as RID)
	return NAN

func _offset_at(time: float) -> float:
	if motion == Motion.PENDULARE:
		return sin(TAU * (time / period + phase))
	if motion == Motion.USA:
		return _door_offset(time)
	# TRAVERSARE. Ciclul, in ordinea in care il vede jucatorul:
	#   [parcat] -> [telegraf: se urneste] -> [traverseaza] -> [parcat pe partea
	#   cealalta] -> ... si inapoi, cu sensul intors.
	#
	# Un ciclu complet duce vehiculul dus-intors, ca sa nu se teleporteze inapoi:
	# la a doua trecere pleaca de unde a ramas.
	var cross := period * 0.5 # cat dureaza o traversare propriu-zisa
	var leg := CROSS_WAIT + CROSS_TELEGRAPH + cross # o trecere, cu asteptarea ei
	var t := fposmod(time + phase * leg * 2.0, leg * 2.0)
	# A doua jumatate a ciclului e aceeasi trecere, in sens invers.
	var back := t >= leg
	if back:
		t -= leg
	var from := -1.0
	var to := 1.0
	if back:
		from = 1.0
		to = -1.0
	if t < CROSS_WAIT:
		return from # parcat pe acostament
	var moving := t - CROSS_WAIT
	if moving < CROSS_TELEGRAPH:
		# Telegraful: se urneste in loc, fara sa intre inca pe asfalt. Deplasare
		# mica si lina, cat sa se VADA ca a pornit.
		var warn := moving / CROSS_TELEGRAPH
		return from * (1.0 - 0.06 * warn * warn)
	# Traversarea: viteza constanta, ca la val si la tren — o trecere care
	# accelereaza nu se poate anticipa, si atunci fereastra devine ghicitoare.
	var k := clampf((moving - CROSS_TELEGRAPH) / maxf(cross, 0.001), 0.0, 1.0)
	return lerpf(from * 0.94, to, k)

## USA. Ciclul, in ordinea in care il vede jucatorul:
##   [deschisa: parcata in nisa, -1] -> [telegraf] -> [se rostogoleste pe axa]
##   -> [INCHISA: sta pe axa, 0, zid] -> [telegraf] -> [inapoi in nisa] -> ...
## Cursa e doar jumatate din axa `travel` (-1..0): capatul +1 nu exista, usa
## nu trece niciodata pe partea cealalta a soselei.
func _door_offset(time: float) -> float:
	var roll := period * 0.5
	var cycle := door_cycle()
	var u := fposmod(time + phase * cycle, cycle)
	if u < DOOR_OPEN:
		return -1.0
	u -= DOOR_OPEN
	if u < CROSS_TELEGRAPH:
		var warn := u / CROSS_TELEGRAPH
		return -1.0 + 0.06 * warn * warn
	u -= CROSS_TELEGRAPH
	if u < roll:
		return lerpf(-0.94, 0.0, u / maxf(roll, 0.001))
	u -= roll
	if u < DOOR_CLOSED:
		return 0.0
	u -= DOOR_CLOSED
	if u < CROSS_TELEGRAPH:
		var warn := u / CROSS_TELEGRAPH
		return -0.06 * warn * warn
	u -= CROSS_TELEGRAPH
	return lerpf(-0.06, -1.0, clampf(u / maxf(roll, 0.001), 0.0, 1.0))

## Lungimea unui ciclu complet al usii (s). Doar USA; cere `period` deja
## dedusa, deci `_configure()` sa fi rulat.
func door_cycle() -> float:
	var roll := period * 0.5
	return DOOR_OPEN + CROSS_TELEGRAPH + roll + DOOR_CLOSED + CROSS_TELEGRAPH + roll

## Peste `seconds` secunde, piatra va fi (macar partial) PE banda? Pentru AI:
## pilotul isi estimeaza sosirea si alege ocolul cand raspunsul e da.
## „Pe banda" = marginea pietrei dinspre drum a trecut de marginea asfaltului;
## o usa pe jumatate inchisa e tot o usa inchisa pentru cine vine cu 25 m/s.
func door_blocks_in(seconds: float) -> bool:
	if motion != Motion.USA:
		return false
	if not _configured:
		_configure()
	var amp := travel.length()
	var edge := _door_offset(_time + seconds) * amp + _half_extent
	var hw := road_half_width if road_half_width > 0.0 else amp * 0.5
	return edge > -hw

## Peste `seconds` secunde, animalul care traverseaza va fi (macar cu o parte din
## corp) PE asfalt? Pentru AI, ca `door_blocks_in`: pilotul isi estimeaza sosirea
## din ce vede si un om (animalul se misca vizibil, cu telegraf) si franeaza daca
## raspunsul e da. Parcat pe acostament = nu blocheaza. Doar TRAVERSARE.
func crossing_blocks_in(seconds: float) -> bool:
	if motion != Motion.TRAVERSARE:
		return false
	if not _configured:
		_configure()
	var amp := travel.length()
	var hw := road_half_width if road_half_width > 0.0 else amp * 0.5
	return absf(_offset_at(_time + seconds)) * amp - _half_extent < hw + 0.5

## Usa e pe banda ACUM (pentru sonde si pentru snapshot).
func door_closed_now() -> bool:
	return door_blocks_in(0.0)

## Unde sta poarta, in lume (axa soselei). Pentru AI, ca la RotatingSpanHazard.
func ai_decision_point() -> Vector3:
	return center

## Contactul te DEZECHILIBREAZA, nu te captureaza. Ghiontul e RADIAL (dinspre
## obstacol spre masina) plus un pic inainte, nu in sensul maturarii: impins pe
## sensul maturarii, exact masina prinsa intre obstacol si perete — singura care
## chiar are nevoie de ajutor — ar fi impinsa si mai tare in perete. Radial +
## inainte are mereu unde sa te scoata, fiindca soseaua continua.
##
## USA nu imbranceste cat STA: ghiontul e pentru corpuri in miscare, care
## altfel te tin lipit de perete. O piatra parcata pe axa e zid — te opresti
## in ea si dai inapoi, ca la orice zid; un zid care te azvarle ar fi alt
## gimmick. Cat se rostogoleste, ghiontul ramane (contactul cu piatra in
## miscare a fost masurat corect: impins cu masa, 0 repuneri).
func _shove_cars(delta: float) -> void:
	if _area == null:
		return
	if motion == Motion.USA and _speed < 0.2:
		return
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	for body in _area.get_overlapping_bodies():
		var car := body as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = 0.35
		var away := car.global_position - global_position
		away.y = 0.0
		if away.length() < 0.05:
			continue
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		car.apply_sweep(away.normalized() * SWEEP_PUSH
			+ fwd.normalized() * SWEEP_PUSH * 0.5 + Vector3.UP * 0.8)
		_speak(car)


## Sunetul ghiontului, pozitional la masina. Prin arbore, nu prin identificatorul
## autoload-ului: hazardul trebuie sa se compileze si in modul `--script`.
func _speak(car: Car) -> void:
	if contact_sfx == &"":
		return
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio != null:
		audio.hazard_contact(contact_sfx, car.global_position + Vector3.UP * 0.5,
			car.is_player)


## Muta sloturile modelului dupa `WorldProp.SLOT_REMAP_BY_MODEL`, daca stem-ul
## GLB-ului are o intrare acolo. Fara intrare nu se atinge nimic, deci niciun
## hazard de pe alta pista nu se schimba.
func _remap_model_slots(model: Node3D) -> void:
	if model.scene_file_path.is_empty():
		return
	var stem := model.scene_file_path.get_file().get_basename()
	var remap: Variant = WorldProp.SLOT_REMAP_BY_MODEL.get(stem, null)
	if remap == null or not (remap is Dictionary) or (remap as Dictionary).is_empty():
		return
	for node in Palette._walk(model):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		mi.mesh = WorldProp._mesh_with_slots_moved(mi.mesh, remap as Dictionary)


## Rupe accentele pictate (`WorldProp.ACCENT_SPLIT`) de pe modelul acestui
## hazard, daca stem-ul GLB-ului e in `WorldProp.SPLIT_MODELS` — ACEEASI
## mecanica pe care o foloseste decorul static (`WorldProp._split_shutters`),
## doar ca aici hazardul isi incarca singur GLB-ul si nu trece prin WorldProp.
##
## Fara asta, o clasa ceruta prin `model_classes` pe un model cu accent (ex.
## elefantul: fildesii pe slotul FOAM_WHITE) ar imbraca TOT nodul, fiindca
## `Elephant_Mesh_Accente` n-ar exista inca. Trebuie sa ruleze INAINTE de
## aplicarea materialelor.
##
## `where` poate fi o LISTA de grupuri de decor manual (vezi nota de la
## `church_arch` in SPLIT_MODELS) — restrictie care nu are sens pentru un
## hazard (n-are grup de decor), deci o lista inseamna "nu se aplica aici".
func _split_model_accents(model: Node3D) -> void:
	if model.scene_file_path.is_empty():
		return
	var stem := model.scene_file_path.get_file().get_basename()
	if not WorldProp.SPLIT_MODELS.has(stem):
		return
	var where: Variant = WorldProp.SPLIT_MODELS[stem]
	if where is Array:
		return
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for c in node.get_children():
			stack.append(c)
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		for prefix: String in WorldProp.ACCENT_SPLIT:
			if String(mi.name).begins_with(prefix):
				Palette.split_accents(mi, WorldProp.ACCENT_SPLIT[prefix])
				break


## Aplica pe `model_classes` clasa ceruta pentru un nod care se termina in
## `Palette.ACCENT_SUFFIX`, dar NUMAI cand cheia din mapare e numele lui EXACT
## (nu un prefix). `Palette.apply_object_class_materials` nu poate face asta —
## `Palette._class_for` respinge orice `_Accente` inainte sa se uite la
## mapare. Contractul e cel din `WorldProp._apply_model_classes`, portat aici
## in spatiul OBIECTULUI (triplanar proiectat pe model, nu pe lume), ca
## pielea elefantului sa nu alunece pe sub textura in timp ce traverseaza.
##
## `tex_scale` e CUANTIZAT (vezi apelantul), nu `model_scale` brut — acelasi
## motiv ca la `apply_object_class_materials`: doua instante la scari vecine
## nu trebuie sa coste doua materiale pentru acelasi tipar de piele.
func _apply_named_accent_classes(model: Node3D, tex_scale: float) -> void:
	for node in Palette._walk(model):
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var nm := String(mi.name)
		if not nm.ends_with(Palette.ACCENT_SUFFIX):
			continue
		if not model_classes.has(nm):
			continue
		var cls := String(model_classes[nm])
		if cls.begins_with(Palette.GLOW_PREFIX):
			mi.material_override = Palette._glow_from_spec(
				cls.trim_prefix(Palette.GLOW_PREFIX))
		elif cls.begins_with(Palette.FINISH_PREFIX):
			mi.material_override = Palette.finish_material(
				cls.trim_prefix(Palette.FINISH_PREFIX))
		elif cls.begins_with(Palette.SHADER_PREFIX):
			mi.material_override = Palette.shader_material(
				cls.trim_prefix(Palette.SHADER_PREFIX))
		elif cls.begins_with(Palette.TRI_PREFIX):
			mi.material_override = Palette.object_triplanar_class_material(
				cls.trim_prefix(Palette.TRI_PREFIX), tex_scale)
		else:
			mi.material_override = Palette.class_material(cls)
