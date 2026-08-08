@tool
class_name Track
extends Node3D
## Generator de pista 3D din puncte de control. O pista noua = o subclasa
## care da alte puncte + fractiile pentru rampe/hazarde — atat.
## @tool: pista se construieste si IN EDITOR (preview la deschiderea
## scenei); nodurile generate nu se salveaza (nu primesc owner).
##
## Filosofia peretilor (stil Ignition): pe EXTERIORUL circuitului gard peste
## tot; pe INTERIOR doar unde soseaua e inaltata. La nivelul solului
## interiorul e deschis -> scurtaturi prin iarba lenta = risc/recompensa.

const WALL_HEIGHT: float = 1.3
## Cate repetitii de textura de suprafata intra intr-un metru de lume.
## 0.08 = o dala la 12.5m — destul de mare cat sa nu se vada tiparul repetandu-se,
## destul de mica cat granulatia sa fie vizibila la nivelul soselei.
## Cate repetitii de textura pe metru, pe teren.
##
## Era 0.08 = o repetitie la 12.5 m. La viteza, granulatia devenea sub-pixel si
## nisipul citea ca o pata uniforma — masurat, deviatia de luminanta era 1.48,
## adica sub un nivel. 0.32 = o repetitie la 3.1 m, unde granulatia se vede.
const SURFACE_TILING: float = 0.32
## A doua scara, mult mai lenta: rupe tiparul de repetitie al primei. Fara ea, o
## textura deasa arata ca o tapiterie pe suprafetele mari.
const SURFACE_TILING_MACRO: float = 0.022
## Soseaua e un "dig" solid: un mesh fara grosime lasa masina sa treaca
## prin el la viteza (depenetrarea o poate impinge pe partea gresita).
const ROAD_THICKNESS: float = 3.0

## Creasta de fly-off: urcare cu panta CRESCATOARE care se termina intr-o
## muchie (nu un cocoas lin — vezi FlyoffKicker pentru de ce).
const FLYOFF_RISE_LEN: float = 12.0
const FLYOFF_HEIGHT: float = 2.8
## Latura amprentei in care se cauta masini care au ratat aterizarea.
const FLYOFF_NET_EXTENT: float = 130.0
## Plafonul plasei, sub cea mai joasa sosea din amprenta.
const FLYOFF_NET_CEILING_DROP: float = 6.0
## Podeaua plasei, tot relativ la sosea.
const FLYOFF_NET_FLOOR_DROP: float = 45.0

## Personalitatea pistei — suprascrise de subclase.
var track_name: String = "Pista"
var half_width: float = 7.0 # ingust = tehnic, lat = vitezomanie

## Din ce e facut drumul: "asphalt" (implicit) sau "dirt" — nisip batatorit.
##
## NU e o intrare in tema, si asta e deliberat: Okinawa manual imparte tema
## "island" cu Okinawa v2 — si nu doar tema, ci LUMEA, pana la samanta (vezi
## world_seed_name). Pus in tema, drumul de nisip ar fi schimbat amandoua
## pistele; aici schimba exact pista care l-a cerut.
##
## Ce atarna de el, in ordinea in care se vede din masina:
##   - materialul soselei — nisip tintat in loc de asfalt, fara sheen
##     (_build_road);
##   - marcajele — un drum nepavat n-are nici linie de mijloc, nici borduri
##     rosu-alb (_build_center_line, _build_kerbs);
##   - urmele coapte in pista — DISPAR complet (_build_tire_marks): pe o
##     suprafata pe care masinile lasa urme reale in fiecare cadru, o urma
##     desenata dinainte nu se adauga la ele, le contrazice;
##   - masinile — ridica praf si lasa urme cat timp RULEAZA pe el, nu doar cand
##     derapeaza (Car._on_loose_ground).
var road_surface: String = "asphalt"

## Drumul e o suprafata AFANATA (pamant, nisip)?
##
## Intrebarea o pun masinile, in fiecare cadru, ca sa stie daca scot praf de sub
## roti si daca depun urme rulind. E o functie, nu o comparatie imprastiata prin
## cod: daca maine apare "gravel", se schimba un singur loc.
func road_is_loose() -> bool:
	return road_surface != "asphalt"

## Culoarea prafului ridicat DE PE SOSEA.
##
## Praful de pe teren isi ia culoarea din theme_ground_tint (vezi
## Car._update_dust), si asa trebuie sa ramana: norul e al suprafetei pe care
## calca roata, iar nisipul drumului nu e acelasi cu nisipul coraligen al plajei
## de langa el — e mai auriu si mai inchis (vezi DIRT_ROAD_COLOR).
func road_dust_color() -> Color:
	return DIRT_ROAD_COLOR if road_is_loose() else ROAD_COLOR

## Suprafata pe care masinile lasa brazde rulind (vezi SandTrail).
##
## O singura culoare pe pista, fiindca materialul urmelor e unul singur, partajat
## de toate masinile. Se alege suprafata pe care se lasa CELE MAI MULTE urme: pe
## o pista cu drum afanat aia e chiar drumul, pe una cu asfalt e terenul de
## langa el — pe asfalt nu se depune nimic.
func trail_surface_color() -> Color:
	return DIRT_ROAD_COLOR if road_is_loose() else theme_ground_tint

## Sursa semintei pentru tot ce e procedural-aleator in lume: faza dunelor,
## imprastierea decorului, falezele, siluetele de orizont, stalpii.
##
## Gol = numele pistei, deci o pista noua primeste automat alta lume — exact ce
## vrei in mod normal. Se completeaza cand doua piste trebuie sa aiba EXACT
## aceeasi lume si difera doar prin nume, adica in cazul unei VARIANTE: Okinawa
## manual e copia lui Okinawa v2 pe care se aseaza decor de mana, iar daca faza
## dunelor ar diferi, terenul de sub obiectele asezate pe una n-ar mai fi cel
## de pe cealalta.
var world_seed_name: String = ""


## Samanta lumii. Vezi [member world_seed_name].
func _world_seed() -> int:
	var src := world_seed_name if not world_seed_name.is_empty() else track_name
	return src.hash()

## Tema vizuala: fiecare pista isi defineste LUMEA (teren, cer, decor).
var theme_decor: String = "forest" # cheie in Track.themes()
var theme_ground_tint := Color(0.45, 0.72, 0.33)
var theme_sky_top := Color(0.30, 0.50, 0.80)
var theme_sky_horizon := Color(0.72, 0.84, 0.95)
var theme_fog := Color(0.75, 0.85, 0.95)
var theme_hill_color := Color(0.25, 0.45, 0.22)
var theme_sun_color := Color(1.0, 0.97, 0.9)
## Expunerea si taria soarelui.
##
## Se calibreaza IMPREUNA, masurand pixelii dintr-un snapshot fata de culoarea
## din style_bible — nu din ochi. Procedura, daca trebuie refacuta:
##   1. randezi `Snapshot.tscn -- --track=0 --frac=0.2 --size=40`
##   2. citesti media pe o zona de nisip departe de drum
##   3. o compari cu #D8A86A (sand_mid)
## Pe desert, combinatia de mai jos a coborat eroarea de la 198 la 10 (din 255).
var theme_exposure: float = 1.0
## Umbre dinamice de la soare. Vezi comentariul lung din _build_environment:
## e o abatere asumata de la CLAUDE.md, cu un singur loc de unde se stinge daca
## primul test pe device nu tine 60fps.
var theme_shadows: bool = true

## Bloom subtil (style_bible §8). Singurul efect fullscreen din joc — un lant de
## downsample pe cadru, deci cel mai scump item de fill rate pe care il rulam.
## Acelasi contract ca theme_shadows: daca device-ul nu tine 60fps, asta e a
## doua setare de stins (dupa umbre).
var theme_glow: bool = true

## Pana unde arunca soarele umbre. Peste, preia ceata (depth 90->250), deci
## lipsa lor nu se vede. O singura cascada pana aici = configuratia cea mai
## ieftina care da totusi contact real cu solul.
##
## 90 -> 110 (august 2026, upgrade-ul grafic): la 90, falezele dintre 90 si
## ~110 m — exact banda in care chase cam-ul le vede cel mai des — nu aruncau
## nimic si pareau lipite pe fundal, iar ceata abia incepe acolo (~20% la
## 110 m). Rezolutia pe metru scade cu ~18%; shadow_blur-ul de mai jos o
## acopera. NU se adauga a doua cascada: ar dubla draw call-urile de umbra
## ale intregii scene.
const SHADOW_DISTANCE: float = 110.0

## Rotatia soarelui (elevatie 42°, azimut 315° — style_bible §5). Constanta,
## nu inline: o citesc si lumina din _build_environment, si glint-ul apei din
## _water_material — scanteierea trebuie sa cada din acelasi soare.
const SUN_ROTATION_DEG: Vector3 = Vector3(-42, 135, 0)

## Layer-ul 8 = "geometrie care n-are voie sa stea intre camera si masina".
##
## Camera face raycast DOAR pe layer-ul asta. Pe layer-ul implicit (unde stau
## toate) ar lovi popice, mingea de plaja si celelalte masini, si fiecare
## depasire ar smuci cadrul cu cativa metri — mai rau decat clipping-ul pe care
## incearca sa-l evite. Se pune pe faleze si pe sol, atat.
const CAMERA_BLOCKER_LAYER: int = 1 << 7
var theme_sun_energy: float = 1.25

## Tema curenta ca DATE, nu ca sir de caractere. Vezi _THEMES.
var _theme: Dictionary = {}

## Toate temele, intr-un singur loc.
##
## Pana la Okinawa, tema era un `if theme == "desert" / else` in apply_theme si
## inca OPT intrebari `theme_decor == "desert"` imprastiate prin cod (ambient,
## ceata, siluete de orizont, pereti, hazard tematic, praf pe umeri, faleze,
## decor). A treia tema ar fi insemnat noua conditii triple, fiecare cu sansa
## ei de a fi uitata — si exact asa apar temele "aproape gata", care arata bine
## intr-un loc si ca desertul in altul.
##
## Acum tema e un dictionar de date, iar codul intreaba flag-uri. Ca sa adaugi
## o tema noua scrii o intrare aici si nimic altundeva; ca sa vezi ce face o
## tema, citesti o singura intrare in loc sa cauti noua `if`-uri.
##
## Nu e `const` fiindca valorile vin din Palette (apel de functie). E incarcat
## o data si partajat.
static var _themes_cache: Dictionary

static func themes() -> Dictionary:
	if not _themes_cache.is_empty():
		return _themes_cache
	_themes_cache = {
		"desert": {
			# sand_mid din paleta (style_bible §1). Era #EDC177, mai deschis decat
			# spec-ul; cu textura peste, valoarea aia impingea canalul rosu in
			# saturatie si stergea granulatia.
			"ground_tint": Palette.color(Palette.SAND_MID),
			"sky_top": Color(0.25, 0.52, 0.92), # albastru adanc, contrast cu nisipul
			"sky_horizon": Color(1.0, 0.86, 0.6),
			"fog": Color(0.98, 0.87, 0.68),
			"hill_color": Color(0.88, 0.62, 0.36),
			"sun_color": Color(1.0, 0.92, 0.78),
			# Calibrate prin masurare (vezi theme_exposure): la valorile vechi
			# (soare 1.25, expunere 1.0) nisipul iesea #FCDB99 in loc de #D8A86A —
			# supraexpus, si granulatia de suprafata disparea in saturatie.
			#
			# Recalibrat de TREI ori. Intai stratul de detaliu (se inmulteste peste
			# albedo, medie 0.89) si coborarea soarelui la 42° au dus nisipul la
			# #BD955E si au cerut 0.75 -> 1.42. Apoi paleta adanca (sand_mid
			# #D8A86A -> #D4994D) a cerut 1.42 -> 1.30: cu vechea expunere,
			# tonemapper-ul FILMIC impingea nisipul in zona de rolloff si ii SPALA
			# saturatia — cadrul masura 0.53 desi paleta primise +25%. Masurat la
			# 1.30: eroare -8/+5/+11 pe canale, sub pragul de 12.
			#
			# Daca schimbi detaliul, unghiul soarelui SAU paleta, REIA masuratoarea:
			#   godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.2 --size=40
			# si compara nisipul insorit (coltul liber al imaginii) cu
			# Palette.HEX[Palette.SAND_MID].
			"sun_energy": 0.8,
			"exposure": 1.30,
			# Ambient din CULOARE, nu din cer — vezi _build_environment.
			"ambient_color": Color.html("E2B77A"),
			"ambient_energy": 0.22,
			"fog_depth": true, # 90 -> 250 m, style_bible §6
			"horizon_model": "res://assets/models/rocks/butte.glb",
			"walls": false,   # rolul lor il preiau falezele de canion
			"cliffs": true,
			"decor": "bands",
			"props": "desert",
			"hazard_model": "res://assets/models/rocks/boulder_roller.glb",
			# Bolovanul e din aceeasi roca cu falezele — aceeasi clasa de
			# textura, doar proiectata in spatiul obiectului (vezi
			# SlidingHazard.model_tri_class).
			"hazard_class": "rock",
			"dust_color": Palette.color(Palette.SAND_SHADOW),
			"water": false,
		},
		"forest": {
			"ground_tint": Color(0.45, 0.72, 0.33), # verde viu, nu pastel
			"sky_top": Color(0.22, 0.48, 0.9),
			"sky_horizon": Color(0.72, 0.87, 1.0),
			"fog": Color(0.78, 0.88, 0.98),
			"hill_color": Color(0.3, 0.56, 0.27),
			"sun_color": Color(1.0, 0.97, 0.88),
			"sun_energy": 1.25,
			"exposure": 1.0,
			"ambient_color": null, # null = ambient din cer
			"fog_depth": false,
			"fog_density": 0.0035,
			"horizon_model": "", # "" = siluete de rezerva (sfere turtite)
			"walls": true,
			"cliffs": false,
			"decor": "scatter",
			"props": "forest",
			"hazard_model": "", # "" = excavator
			"dust_color": null, # null = derivat din ground_tint
			"water": false,
		},
		# --- Insula de recif (pista Okinawa) ---
		#
		# Culorile sunt sloturile insulare din paleta (17-23), ca sa nu existe
		# doua adevaruri despre "ce inseamna turcoaz".
		#
		# sun_energy e CALIBRAT prin masurare, ca la desert: la 1.10 nisipul iesea
		# #CDC3AF fata de tinta #E9DCC0 (rosu cu 28/255 sub), la 1.50 iese #DED5C1
		# — eroare maxima 11/255, sub pragul de 12 din style_bible §5.
		#
		# S-a folosit sun_energy, NU exposure, si asta conteaza: expunerea ar fi
		# ridicat si apa, care era deja pe tinta. Soarele atinge doar suprafetele
		# iluminate, iar apa e unshaded — deci e singura parghie care misca
		# nisipul fara sa strice marea.
		#
		# Daca se schimba ambientul sau unghiul soarelui, REIA masuratoarea:
		#   godot --path . res://tools/Snapshot.tscn -- --track=4 --size=300
		# si compara nisipul cu #E9DCC0.
		"island": {
			"ground_tint": Palette.color(Palette.CORAL_SAND),
			"sky_top": Color(0.20, 0.50, 0.88),
			"sky_horizon": Color(0.80, 0.92, 0.95), # palid marin, nu auriu ca desertul
			"fog": Color(0.82, 0.91, 0.93),
			"hill_color": Palette.color(Palette.TROPICAL_GREEN),
			"sun_color": Color(1.0, 0.97, 0.92),
			"sun_energy": 1.50,
			"exposure": 1.0,
			# Ambient din CULOARE, nu din cer — desi rationamentul initial spunea
			# invers.
			#
			# Prima versiune folosea ambient din cer, pe motiv ca pe o insula
			# lumina indirecta chiar vine din cer si din apa. Plauzibil, si gresit:
			# masurat pe prima randare, nisipul coraligen iesea #C0C8D9 in loc de
			# #E9DCC0 — albastru-cenusiu, cu rosul cu 41/255 sub tinta si albastrul
			# cu 25 peste. Exact esecul documentat la desert (vezi
			# _build_environment), doar ca acolo fusese prins din masuratoare, iar
			# aici l-am reintrodus din rationament.
			#
			# Culoarea e bounce-ul de pe nisip coraligen: mai deschis si mai putin
			# auriu decat cel de desert (#E2B77A), fiindca si nisipul e mai alb.
			"ambient_color": Color.html("EADFC8"),
			"ambient_energy": 0.30,
			# Ceata de adancime, ca la desert: marea se pierde in orizont la o
			# distanta cunoscuta, iar camera poate taia fix acolo.
			"fog_depth": true,
			# Insulele de fundal (#107). Trei siluete DELIBERAT diferite ca
			# forma, nu trei marimi ale aceleiasi movile: rolul lor e orientarea
			# (style_bible §7), deci "sunt langa insula cu doua varfuri" trebuie
			# sa fie o informatie reala. Inelul apropiat primeste insula joasa,
			# cel departat conul — silueta cea mai citibila sta cel mai departe.
			"horizon_model": "res://assets/models/effects/horizon_island.glb",
			"horizon_picks": [
				["Island_Low", "Island_Ridge"],
				["Island_Ridge", "Island_Peak"],
				["Island_Peak", "Island_Ridge"],
			],
			"horizon_class": "coral_rock",
			# Insula nu e o plaja pana in varf. Referinta (okinawa_v2.png) are
			# nisip doar pe fasia batuta de valuri; tot ce urca dincolo de ea e
			# verde — sat, terase, creasta. Fara asta, cadrul din masina arata o
			# campie de nisip cu cateva prop-uri pe ea, si nicio densitate de
			# palmieri n-o repara: pata de fundal e a TERENULUI, nu a decorului.
			#
			# Costa zero triunghiuri (e vertex color pe grila care exista deja) si
			# se aplica dupa INALTIMEA FATA DE MARE, nu dupa distanta pana la apa:
			# plaja e, prin definitie, fasia joasa. Digul de start ramane nisip
			# fiindca e la +1.6 m, creasta iese verde fiindca e la +29.
			"inland_tint": Palette.color(Palette.TROPICAL_GREEN),
			"inland_strength": 0.85,
			"walls": true,       # doar pe sectiunile inaltate — regula din sampler
			"cliffs": false,     # promontoriul e zid gusuku, nu faleza de canion
			"decor": "bands",    # densitatea din style_bible §7, ca pe desert
			"props": "island",   # ...dar palmieri si bazalt, nu cactusi
			"water": true,       # singura tema cu mare (vezi _build_water)
			# Cat de adanc cade terenul dincolo de coridorul pistei. Trebuie sa
			# duca adancimea DECIS peste SEA_NEAR_DEPTH, altfel grila fina de tarm
			# se emite pe toata marea. Vezi TrackSideSampler.ground_y.
			"seabed_drop": 26.0,
			# Hazardul de la frac 0.33: o sabani targita peste drum, in loc de
			# excavatorul de santier din desert (#107).
			#
			# `hazard_roll: false` NU e cosmetic. `SlidingHazard` roteste modelul
			# proportional cu deplasarea daca `roll_radius > 0` — corect pentru
			# bolovanul din canion, absurd pentru o barca. Fara steag, sabani
			# s-ar fi rostogolit ca un butoi.
			"hazard_model": "res://assets/models/vehicles/sabani_boat.glb",
			"hazard_roll": false,
			"hazard_scale": 1.0,
			"hazard_classes": {"Sabani_Hull": "wood"},
			# Banda uda de pe causeway vine din mare, nu dintr-o teava sparta.
			"hose_model": "",
			"dust_color": null,
		},
	}
	return _themes_cache


## Citeste un camp din tema curenta, cu valoare implicita daca lipseste.
##
## Initializarea e LENESA si intentionat NU trece prin apply_theme: o pista are
## voie sa nu apeleze apply_theme deloc si sa ramana pe valorile implicite ale
## variabilelor theme_*, care NU sunt identice cu ramura "forest" (cerul
## implicit e (0.30,0.50,0.80), cel din tema e (0.22,0.48,0.9)). Un
## apply_theme("forest") fortat aici i-ar schimba in tacere aspectul.
## Asa iau doar FLAG-urile de comportament, iar culorile raman ale ei.
func theme_flag(key: String, fallback: Variant = null) -> Variant:
	if _theme.is_empty():
		var all := themes()
		_theme = _with_overrides(all.get(theme_decor, all["forest"]))
	return _theme.get(key, fallback)


## Ce schimba PISTA ASTA din tema ei, cu aceleasi chei ca `themes()`.
##
## Exista fiindca o pista se putea abate pana acum doar prin metode (`_hose_fracs`,
## `_wave_fracs`, `_channel_specs`) — adica doar pe axele pentru care cineva
## apucase sa scrie un hook. Tot ce statea in tema (ce model are hazardul, cat de
## mare e, daca se rostogoleste) era comun pe toate pistele temei: schimbat acolo,
## se schimba si pe Okinawa si pe Okinawa v2, deci o incercare pe pista de lucru
## n-ar mai fi fost o incercare.
##
## Nu tine loc de tema noua. O tema descrie o LUME (cer, mare, decor, faleze); un
## override e o abatere declarata a unei piste de la lumea ei, si se scrie langa
## motivul ei, ca celelalte abateri ale lui Track08.
func _theme_overrides() -> Dictionary:
	return {}


## Tema + abaterile pistei. Duplicarea NU e defensiva: `themes()` intoarce un
## cache PARTAJAT de toate pistele, iar `merge` pe el ar muta hazardul de pe
## Okinawa manual si pe Okinawa v2, in tacere si doar in ordinea in care se
## incarca scenele.
func _with_overrides(base: Dictionary) -> Dictionary:
	var over := _theme_overrides()
	if over.is_empty():
		return base
	var merged := base.duplicate()
	merged.merge(over, true)
	return merged


## Paleta completa a unei teme, dintr-un singur apel.
## Stil: FLAT-COLOR saturat (stilul masinilor RgsDev, extins la lume) —
## fara texturi de zgomot; culoarea si lumina fac treaba.
func apply_theme(theme: String) -> void:
	var all := themes()
	if not all.has(theme):
		push_error("Track: tema necunoscuta '%s' (am %s)"
			% [theme, ", ".join(all.keys())])
		theme = "forest"
	theme_decor = theme
	_theme = _with_overrides(all[theme])
	theme_ground_tint = _theme["ground_tint"]
	theme_sky_top = _theme["sky_top"]
	theme_sky_horizon = _theme["sky_horizon"]
	theme_fog = _theme["fog"]
	theme_hill_color = _theme["hill_color"]
	theme_sun_color = _theme["sun_color"]
	theme_sun_energy = _theme["sun_energy"]
	theme_exposure = _theme["exposure"]

var curve: Curve3D
var baked: PackedVector3Array
var _dists: PackedFloat32Array # distanta cumulata pana la fiecare punct copt

## Toate benzile pe care se poate conduce. [code]routes[0][/code] e bucla
## principala si oglindeste exact [member baked] / [member _dists]; 1+ sunt
## scurtaturi. Vezi [TrackRoute] pentru de ce e nevoie de abstractia asta.
var routes: Array[TrackRoute] = []
## Sursa unica de sloturi pentru tot ce se aseaza langa drum (faleze, decor).
## Se reconstruieste la fiecare rebuild(), dupa ce curba e coapta.
var _sampler: TrackSideSampler

## Grila de inaltimi a terenului, coapta o data si citita si de umeri.
##
## Umarul soselei trebuie sa se termine EXACT pe suprafata pe care o vede si o
## atinge masina, iar aia nu e campul continuu din sampler: intre doua noduri de
## grila terenul e o coarda dreapta, care pe o creasta trece cu pana la un metru
## pe sub cota reala. Vezi _terrain_mesh_y().
var _terr_origin: Vector3 = Vector3.ZERO
var _terr_cells: int = 0
var _terr_step: float = 0.0
var _terr_heights: PackedFloat32Array = PackedFloat32Array()

## Materiale flat, refolosite pe culoare. Fara cache-ul asta fiecare mesh
## procedural isi facea propriul StandardMaterial3D — masurat cu
## tools/probe_decor.gd pe Dunele: 76 mesh-uri -> 72 materiale, adica tot atatea
## draw call-uri, exact ce nu ne permitem pe mobil (CLAUDE.md, constrangeri 3D).
## Se goleste la fiecare rebuild(), ca schimbarea de tema sa nu lase gunoi.
var _mat_cache: Dictionary = {}

# --- API pentru subclase ---

func _points() -> Array[Vector3]:
	push_error("Track: suprascrie _points() in subclasa")
	return []

## Fractii (0..1) din traseu unde apar rampe de saritura.
func _ramp_fracs() -> Array[float]:
	return []

## Fractii unde apar bariere mobile.
func _hazard_fracs() -> Array[float]:
	return []

## Fractii unde conducta sparta pulseaza apa peste drum.
##
## Prima din cele doua SURSE de apa, ambele pe acelasi hazard
## (`scenes/hazards/water_hazard.gd`): teava sta pe loc si uda o portiune fixa.
func _hose_fracs() -> Array[float]:
	return []

## Fractii unde marea trece peste sosea (Okinawa: digul, causeway-ul).
##
## A doua sursa de apa. Doua hook-uri si nu unul fiindca difera ce ALEGI cand le
## pui: teava e o portiune permanent alunecoasa (o taxa pe sector), valul e un
## ceas (o fereastra prin care treci sau nu). Mecanica din spate e literalmente
## aceeasi — vezi scenes/hazards/wave_surge.gd.
func _wave_fracs() -> Array[float]:
	return []

## Trombe de mini-typhoon care ratacesc peste sosea (Okinawa).
##
## A treia familie de hazard cu ceas, dupa val si pod, si singura care nu te
## opreste, nu te uda si nu te impinge: te RIDICA. Vezi antetul lui
## scenes/hazards/typhoon_hazard.gd pentru de ce merita o familie proprie.
func _typhoon_fracs() -> Array[float]:
	return []

## Excavatoare suplimentare, explicite (pe langa hazardul tematic).
func _excavator_fracs() -> Array[float]:
	return []

## Dinozauri-landmark: (fractie, parte) — plasati cu intentie, nu aleator.
func _dino_spots() -> Array[Vector2]:
	return []

## Arcade de stanca prin care trece soseaua (fractii 0..1).
func _arch_fracs() -> Array[float]:
	return []

## Defilee: intervale (frac_start, frac_end) in care falezele strang drumul de
## AMBELE parti, inalte si apropiate. Momentul-semnatura al unei piste (#28).
func _gorge_ranges() -> Array[Vector2]:
	return []

## Intrari de mina lipite de perete: (fractie, parte ±1).
func _mine_spots() -> Array[Vector2]:
	return []

## Unde TrackCliffs NU ridica pereti. Landmark-urile hero au avut mereu
## degajarea asta; situl cu schelet o cere la fel de tare, si din acelasi motiv:
## e asezat la 19 m de axa, adica FIX in spatele liniei de faleze, iar fara
## degajare silueta lui nu se vede deloc de pe sosea. Sondele nu prind asta —
## doar o captura din vederea de joc o prinde.
func _cliff_clearings() -> Array[Vector3]:
	var out: Array[Vector3] = _landmark_spots().duplicate()
	for spot in _dino_spots():
		out.append(Vector3(spot.x, spot.y, -1.0)) # id -1: nu e din _LANDMARKS
	for spot in _mine_spots():
		out.append(Vector3(spot.x, spot.y, -1.0))
	# Arcada straddleaza soseaua, deci cere degajare pe AMANDOUA laturile.
	for frac in _arch_fracs():
		out.append(Vector3(frac, 1.0, -1.0))
		out.append(Vector3(frac, -1.0, -1.0))
	# La fel calea ferata, si din acelasi motiv geometric: taie perpendicular pe
	# drum si iese 90 m in fiecare parte, deci intra direct in peretele de canion.
	# Se vedea de la prima captura cu trenul in cadru — locomotiva iesea din
	# stanca — dar nu se vedea in nicio sonda, fiindca nimic nu masoara
	# intersectia dintre doua sisteme care nu se cunosc intre ele.
	for frac in _train_fracs():
		out.append(Vector3(frac, 1.0, -1.0))
		out.append(Vector3(frac, -1.0, -1.0))
	return out

## Landmark-uri hero (turn de apa, benzinarie, moara, semn): fiecare
## (fractie, parte ±1, id-model din _LANDMARKS) — plasate cu intentie.
func _landmark_spots() -> Array[Vector3]:
	return []

## Carusele: moristi uriase cu vane care MATURA soseaua (gimmick de timing).
func _carousel_fracs() -> Array[float]:
	return []

## Deviatoare: bariere oblice care iti schimba traiectoria (gimmick de linie).
func _deflector_fracs() -> Array[float]:
	return []

## Creste de fly-off: te arunca in aer inaintea unui viraj; ratezi aterizarea
## si ajungi in nisipul de sub sosea, de unde te repune un RespawnZone.
func _flyoff_fracs() -> Array[float]:
	return []

## Rapele declarate: (frac_start, frac_end, adancime, latura ±1 sau 0 = ambele).
##
## Terenul urmareste soseaua peste tot — altfel plutea tot ce se aseza langa o
## portiune inaltata. Dar asta umple exact golul in care era gandita drama
## fly-off-ului: ai zbura de pe creasta si ai ateriza linistit pe nisip. Rapa
## declarata taie inapoi terenul acolo unde vrem sa existe chiar o prapastie.
func _ravines() -> Array[Vector4]:
	return []

## Laguna: conturul apei din INTERIORUL buclei, ca poligon in plan XZ.
##
## Regula implicita a temei cu apa e ca interiorul circuitului ramane USCAT
## (vezi TrackSideSampler.ground_y — un atol aparut din greseala nu se vede
## decat de sus). Hook-ul asta e exceptia declarata: o insula inelara in jurul
## unei lagune, unde golul din mijloc E subiectul pistei.
##
## Gol = fara laguna. Adancimea vine din [member lagoon_depth].
func _lagoon_points() -> Array[Vector2]:
	return []

## Scurtaturi: benzi care se desprind din traseu si revin mai tarziu.
##
## Fiecare intrare e un dictionar:
##   entry      fractia (0..1) de pe bucla principala unde se despica
##   exit       fractia unde revine
##   points     punctele intermediare, in coordonate de LUME. Capetele NU se dau
##              — se citesc de pe bucla principala, ca sa nu ramana in urma la
##              prima ajustare de traseu.
##   half_width jumatatea latimii benzii (implicit cat pista)
##   wet        banda uda: grip lateral taiat cat timp esti pe ea
##   label      nume pentru sonde
##
## Scurtatura da TIMP, nu progres: o masina de la jumatatea ei raporteaza
## aceeasi fractie de tur ca una de la jumatatea portiunii ocolite. Vezi
## [TrackRoute.frac_at] — acolo se decide ca nu se poate trisa un tur pe aici.
func _branch_specs() -> Array[Dictionary]:
	return []

## Bolovani care cad de pe faleza (fractii 0..1).
func _rockfall_fracs() -> Array[float]:
	return []

## Treceri de cale ferata cu tren (fractii 0..1).
func _train_fracs() -> Array[float]:
	return []

## Canale navigabile care TAIE soseaua, sarite pe un pod cu travee ridicatoare.
##
## Spre deosebire de rapa si de laguna, care sapa DE LANGA drum, canalul trece pe
## dedesubt: terenul dispare, soseaua ramane un gol, iar peste gol se ridica o
## travee la interval fix. Vezi [LiftBridgeHazard] pentru ciclu si
## [method TrackSideSampler._carve_channel] pentru taietura.
##
## Fiecare intrare e un dictionar:
##   frac        unde taie canalul soseaua (0..1)
##   gap         cati metri de sosea LIPSESC. Se rotunjeste la pasul curbei, iar
##               valoarea OBTINUTA e cea care conteaza pentru saritura — o
##               citeste tools/probe_bridge.gd, nu se presupune.
##   water_half  jumatatea latimii apei, masurata in lungul soselei
##   bank        pe cati metri urca malul de la apa la cota drumului
##   depth       cat sub cota soselei de acolo sta fundul dragat
##   reach       cat de departe merge canalul in fiecare parte
##   fade        pe ultimii metri din `reach` canalul se stinge in largul din jur
##   label       nume pentru sonde
func _channel_specs() -> Array[Dictionary]:
	return []

## Scenografia pistei: decorul asezat DUPA O REFERINTA, sector cu sector.
##
## Gol pe majoritatea pistelor — decorul lor vine din benzile statistice ale lui
## [TrackDecor]. O pista care are o referinta desenata (Okinawa v2) declara aici
## ce sta unde: digul cu tetrapozi, portul, satul, zidurile de cetate, lanul.
## Formatul fiecarei intrari e documentat in [TrackScenography].
func _scenography() -> Array[Dictionary]:
	return []

func _ready() -> void:
	rebuild()

## Reconstruieste toata pista (folosit si de editor, la Regenerate).
##
## Sterge doar ce a generat codul. Un nod pe care l-ai asezat DE MANA in editor
## si l-ai salvat in .tscn are `owner` setat (radacina scenei), pe cand tot ce
## adaugam noi cu add_child() are owner null — deci decorul asezat manual
## supravietuieste si la Regenerate, si la runtime. Vezi docs/decor_manual.md.
func rebuild() -> void:
	_mat_cache.clear() # altfel raman materialele temei precedente
	_terr_cells = 0 # grila de teren se recoace odata cu curba
	for child in get_children():
		if child is Path3D:
			continue # curba editabila a pistelor custom ramane
		if child.owner != null:
			continue # asezat de mana in editor, salvat in scena
		child.free()
	_build_curve()
	# Canalele INAINTEA samplerului: el sapa dupa ele, iar restul generatorilor
	# intreaba tot de aici unde e golul din sosea.
	_resolve_channels()
	# Dupa coacerea curbei (deci si a rutelor), inainte de orice generator care
	# aseaza ceva langa drum: toti citesc sloturi SI cota terenului de aici.
	_sampler = TrackSideSampler.new(baked, _dists, _points(), half_width,
		float(_world_seed() % 1000) * 0.01, _ravines(),
		theme_flag("seabed_drop", 0.0), _branch_corridor_points(),
		_lagoon_poly(), lagoon_depth, _channels)
	_build_environment()
	_build_road()
	_build_branch_surfaces()
	_build_walls()
	for frac in _ramp_fracs():
		_build_ramp(frac)
	for frac in _hazard_fracs():
		_build_hazard(frac)
	for frac in _excavator_fracs():
		_build_excavator(frac)
	for spot in _dino_spots():
		_build_dino(spot.x, spot.y)
	for frac in _arch_fracs():
		_build_arch(frac)
	for spot in _mine_spots():
		_build_mine(spot.x, spot.y)
	for spot in _landmark_spots():
		_build_landmark(spot.x, spot.y, int(spot.z))
	for frac in _hose_fracs():
		_build_hose(frac)
	for frac in _wave_fracs():
		_build_wave_surge(frac)
	for frac in _typhoon_fracs():
		_build_typhoon(frac)
	for frac in _flyoff_fracs():
		_build_flyoff(frac)
	for frac in _deflector_fracs():
		_build_deflector(frac)
	for frac in _carousel_fracs():
		_build_carousel(frac)
	for frac in _rockfall_fracs():
		_build_rockfall(frac)
	for frac in _train_fracs():
		_build_train(frac)
	for ch in _channels:
		_build_lift_bridge(ch)
	_build_markers()
	_build_start_gate()
	_build_start_line()
	_build_center_line()
	_build_shoulders()
	_build_kerbs()
	_build_tire_marks()
	_build_world_decor()
	# Chevron-urile DUPA decor, nu inaintea lui: canionul si stancile de margine
	# se aseaza exact pe exteriorul virajelor, adica fix unde stau si semnele.
	# Puse inainte, primul semn de pe Dunele a iesit INGROPAT intr-o faleza.
	# Acum semnul isi cauta singur un loc liber (vezi _place_chevron).
	_build_chevrons()
	# Gardul, tot dupa decor si din acelasi motiv: isi alege dreptele libere.
	_build_fences()
	# Terenul DUPA faleze: le citeste pozitiile ca sa coaca umbra la baza lor.
	# Fara asta, stancile par lipite peste nisip, nu infipte in el.
	_build_terrain()
	# Apa DUPA teren: are nevoie de aceleasi cote ca sa stie unde e tarmul.
	_build_water()
	_build_world_bounds()

## Linia discontinua de mijloc, din geometrie (fara texturi): placute albe
## la fiecare 6.5m de-a lungul curbei.
func _build_center_line() -> void:
	# Pe nisip nu se picteaza. Linia ar fi ramas singurul marcaj de pe o
	# suprafata care nu poarta marcaje, si prima care ar fi spus "asta e tot
	# asfalt, doar vopsit in nisipiu".
	if road_is_loose():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var total := _dists[n]
	var lift := Vector3.UP * 0.045
	var d := 4.0
	var idx := 0
	while d < total - 5.0:
		while idx + 1 < _dists.size() and _dists[idx + 1] < d:
			idx += 1
		var i := idx % n
		if _road_gap(i):
			d += 6.5
			continue
		var dir := (baked[(i + 1) % n] - baked[i]).normalized()
		var side := _side_at(i)
		var a := baked[i] + dir * (d - _dists[i]) + lift
		var b := a + dir * 2.8
		st.add_vertex(a - side * 0.18); st.add_vertex(a + side * 0.18)
		st.add_vertex(b - side * 0.18)
		st.add_vertex(a + side * 0.18); st.add_vertex(b + side * 0.18)
		st.add_vertex(b - side * 0.18)
		d += 6.5
	st.generate_normals()
	_add_visual_mesh(st.commit(), Color(0.92, 0.9, 0.78))

## Lumea pistei: cer, soare, teren si dealuri/dune de fundal — tematice.
func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = theme_sky_top
	sky_mat.sky_horizon_color = theme_sky_horizon
	sky_mat.ground_bottom_color = theme_fog.darkened(0.4)
	sky_mat.ground_horizon_color = theme_sky_horizon
	# Nori. Camera Ignition e mai plata (7° in loc de 11°), deci orizontul coboara
	# si cerul creste la ~48% din cadru — fara nimic in el, camera mai buna face
	# imaginea mai GOALA. sky_cover se inmulteste peste gradient, zero draw calls.
	#
	# sky_cover se ADUNA peste gradient, nu se inmulteste — cu modulate alb si
	# textura gri deschis, cerul iesea complet alb. Modulate-ul e deci foarte
	# scazut: norii trebuie doar sugerati, nu sa acopere albastrul.
	var clouds := _tex("res://assets/textures/sky_cover.png")
	if clouds != null:
		sky_mat.sky_cover = clouds
		sky_mat.sky_cover_modulate = Color(1.0, 0.97, 0.92, 0.35)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Ambientul: NU direct din cer pe tema de desert.
	#
	# Cerul e albastru intens (#4085EB) si, luat ca ambient, isi lasa nuanta pe
	# tot ce e deschis la culoare. Masurat pe nisip: canalul albastru urca de la
	# 0x6A la 0xCD, deci #D8A86A (cald) ajungea #EAD8CD (gri-roz). Nu era o
	# problema de luminozitate — rosul si verdele erau corecte — deci nici
	# expunerea, nici energia soarelui nu o puteau repara: alea scad toate cele
	# trei canale deodata.
	#
	# In realitate lumina indirecta de pe o intindere de nisip vine in cea mai
	# mare parte DE LA NISIP, nu de la cer. Folosim culoarea de bounce din
	# style_bible §5 (#E2B77A) ca sursa de ambient, si umbrele ies calde in loc
	# de albastre.
	var ambient: Variant = theme_flag("ambient_color")
	if ambient != null:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = ambient
		env.ambient_light_energy = theme_flag("ambient_energy", 0.22)
	else:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 1.0
	# Ceata doar IN JOC: camera editorului sta la kilometri deasupra scenei
	# in vederile ortogonale, iar ceata ar acoperi totul intr-o pata uniforma.
	env.fog_enabled = not Engine.is_editor_hint()
	env.fog_light_color = theme_fog
	if theme_flag("fog_depth", false):
		# FOG_MODE_DEPTH, cu inceput si sfarsit explicite (style_bible §6: 90 ->
		# 250m), in loc de exponential. Doua motive: se stie EXACT unde dispare
		# geometria, deci camera poate taia fix acolo (vezi ChaseCamera.far); si
		# prim-planul ramane complet limpede, in loc sa capete un val subtire de
		# ceata pe tot ce e la 20-50m.
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_depth_begin = 90.0
		env.fog_depth_end = 250.0
		env.fog_depth_curve = 1.4 # se ingroasa spre final, nu liniar
	else:
		env.fog_density = theme_flag("fog_density", 0.0035)
	# Culorile flat au nevoie de un pic de "pop": saturatie si contrast.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Expunerea: SINGURA parghie globala de luminozitate a scenei.
	#
	# Cerul de desert e albastru intens si foarte luminos; cu ambient din cer la
	# contributie plina, nisipul iesea #EAD8CD (gri-roz spalat) in loc de #D8A86A,
	# iar granulatia de suprafata disparea complet in saturatie.
	#
	# Se regleaza AICI, nu din energia soarelui sau din contributia cerului:
	# ambele schimba si raportul dintre lumina directa si umbra, deci "repara"
	# nisipul stricand altceva. Valoarea e calibrata masurand pixelii din
	# snapshot, nu din ochi — vezi comentariul de la theme_exposure.
	env.tonemap_exposure = theme_exposure
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.05
	# Bloom-ul din style_bible §8, pana acum doar specificat. Threshold-ul sta
	# PESTE alb (1.1): dupa FILMIC aproape nimic nu-l depaseste in mod normal,
	# deci efectul apare doar pe varfurile reale de lumina — soarele pe caroserii,
	# spuma, cerul la orizont — nu ca un val lăptos pe toata scena. Doar
	# nivelurile 2-3 (mip-uri mici) sunt active: halo strans, cost minim.
	#
	# ATENTIE la indici: `set_glow_level` numara de la 0 (sunt 7 niveluri,
	# 0..6), dar inspectorul le eticheteaza `glow_levels/1`..`glow_levels/7`.
	# Prima versiune a buclei mergea pe etichete (`range(1, 8)`) si arunca
	# la fiecare incarcare de pista "Index p_level = 7 is out of bounds".
	# Indicii 2 si 3 de mai jos sunt cei EFECTIV activi de atunci — adica
	# etichetele 3-4 din inspector, nu 2-3. Se pastreaza asa: ei sunt in
	# snapshot-urile pe care s-a calibrat restul tonemap-ului.
	if theme_glow:
		env.glow_enabled = true
		env.glow_intensity = 0.25
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 1.1
		for level in range(7):
			env.set_glow_level(level, 1.0 if level in [2, 3] else 0.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	# Elevatie 42°, azimut 315° (din stanga-sus) — style_bible §5. Constanta e
	# impartita cu _water_material(): glint-ul apei trebuie sa cada din acelasi
	# soare care lumineaza lumea.
	#
	# Vechiul (-48, -30) bătea aproape vertical si dinspre spatele camerei, deci
	# umbrele cadeau SUB si IN SPATELE stancilor, unde nu le vede nimeni. La 42°
	# umbra unei faleze de 10m se intinde ~11m pe nisip, transversal pe drum:
	# exact indiciul de volum care lipsea.
	sun.rotation_degrees = SUN_ROTATION_DEG
	sun.light_color = theme_sun_color
	sun.light_energy = theme_sun_energy
	# Umbrele contrazic litera CLAUDE.md ("umbre ieftine sau blob shadows").
	# Decizie asumata dupa comparatia cu Reckless Racing 3 / Beach Buggy Racing:
	# contactul cu solul e ce lipsea cel mai tare — fara el orice obiect pare
	# lipit peste fundal, nu asezat in el. Ramane O SINGURA lumina directionala,
	# doar ca acum arunca.
	#
	# Configuratia e cea mai ieftina care da contact real: o singura cascada, pe
	# 90m. Dincolo preia ceata (depth 90->250), deci nu se vede lipsa lor.
	#
	# COMUTATORUL E theme_shadows. Daca primul test pe device nu tine 60fps, se
	# stinge de acolo si AO-ul copt ramane singura sursa de volum.
	sun.shadow_enabled = theme_shadows
	if theme_shadows:
		sun.directional_shadow_mode = \
			DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = SHADOW_DISTANCE
		# Estompeaza muchia umbrei. Fara ea, o cascada singura pe 90m da o linie
		# taioasa de pixeli pe nisip.
		sun.shadow_blur = 1.4
		# Falezele sunt mari si inclinate; cu bias implicit apar dungi de shadow
		# acne pe fetele orientate spre soare.
		sun.shadow_bias = 0.06
		sun.shadow_normal_bias = 1.6
	add_child(sun)

	# _build_terrain() NU se cheama de aici: are nevoie de pozitiile falezelor ca
	# sa coaca AO la baza lor, iar alea exista abia dupa _build_world_decor().
	# Vezi ordinea din rebuild().
	var centroid := _centroid()
	var ground_body := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(2000, 1, 2000)
	ground_shape.shape = ground_box
	# ATENTIE: doar XZ din centroid — centroid.y include media dealurilor
	# si ar ridica podeaua de coliziune deasupra soselei (perete invizibil).
	#
	# Cutia asta NU mai e podeaua pe care se conduce: de cand terenul are
	# coliziune proprie (vezi _build_terrain), ea e doar ultima plasa, pentru
	# cazul in care cineva iese complet din harta. De aceea coboara SUB cel mai
	# jos punct posibil — altfel ar astupa fundul rapelor declarate.
	var lowest := INF
	for p in baked:
		lowest = minf(lowest, p.y)
	ground_shape.position = Vector3(centroid.x,
		lowest - _sampler.max_ravine_depth() - 10.0, centroid.z)
	# Solul blocheaza si el camera: fara asta, pe o coama camera trece prin nisip
	# si vezi lumea de dedesubt.
	ground_body.collision_layer |= CAMERA_BLOCKER_LAYER
	ground_body.add_child(ground_shape)
	add_child(ground_body)

	_build_horizon(centroid)

## Inelele de siluete de la orizont: (distanta_min, distanta_max, cate, variante).
##
## Cele apropiate sunt JOASE, cele departate INALTE. Invers decat pare intuitiv,
## dar asa apare perspectiva: o formatiune de 60m la 320m se inalta pe cer peste
## una de 25m la 170m, exact ca intr-un peisaj real de canion.
## `clear` = cat de departe de sosea trebuie sa stea silueta. E PER INEL, nu o
## singura cifra: inelul apropiat are siluete mici (scara 1.2) si cel mai putin
## loc, iar o degajare comuna de 160 m il facea practic imposibil de populat.
const HORIZON_RINGS := [
	{"near": 150.0, "far": 200.0, "count": 5, "scale": 1.2, "clear": 95.0,
		"picks": ["Butte_A", "Mesa_A"]},
	{"near": 200.0, "far": 255.0, "count": 6, "scale": 1.7, "clear": 130.0,
		"picks": ["Butte_B", "Mesa_A", "Mesa_B"]},
	{"near": 255.0, "far": 320.0, "count": 5, "scale": 2.4, "clear": 160.0,
		"picks": ["Butte_C", "Butte_B", "Mesa_B"]},
]
## Cat trebuie sa stea o silueta departe de sosea. Generos, pentru ca siluetele
## sunt scalate agresiv (vezi "scale" in inele) si o mesa de 78m devine, la
## scara 2.6, o formatiune de peste 200m latime.
const HORIZON_CLEARANCE: float = 120.0


## Siluetele de la orizont: butte-uri si mese reale, in inele concentrice.
##
## Inlocuiesc cele 12 sfere turtite de dinainte. Alea costau ~9000 de triunghiuri
## (chiar si dupa ce le-am coborat rezolutia) si aratau ca un sir de movile
## identice — nu-ti spuneau NIMIC despre unde esti pe pista.
##
## Astea sunt reperele de orientare (style_bible §7: landmark dominant la 4-6
## secunde). Fiecare inel are alta gama de siluete, deci "sunt langa turnul
## ingust" devine o informatie reala.
func _build_horizon(centroid: Vector3) -> void:
	var horizon_model: String = theme_flag("horizon_model", "")
	if horizon_model.is_empty() or not ResourceLoader.exists(horizon_model):
		_build_horizon_fallback(centroid)
		return
	var scene := load(horizon_model) as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed() + 1
	# Unghiuri ECHIDISTANTE cu jitter, nu complet aleatoare.
	#
	# Varianta veche trag ea la zar unghi SI raza, si renunta dupa 60 de
	# incercari. Masurat pe Dunele: plasa 6 din 16 siluete cerute, si nu spunea
	# nimic. Pe o pista care se auto-intersecteaza si ocupa ~380x220 m, cele mai
	# multe directii cad in banda de degajare, deci zarul le nimerea rar.
	#
	# Acum fiecare silueta primeste propriul SECTOR de cerc si cauta pe raza in
	# el. Unghiul e garantat, deci acoperirea orizontului ramane uniforma chiar
	# daca o directie e stramta — si un sector care chiar n-are loc se
	# RAPORTEAZA, nu dispare in tacere.
	var missed := 0
	var placed := 0
	for ring in HORIZON_RINGS:
		var count := int(ring["count"])
		var arc := TAU / float(count)
		var clear: float = float(ring["clear"])
		for slot in count:
			var angle := float(slot) * arc \
				+ rng.randf_range(-arc * 0.35, arc * 0.35)
			var pos := Vector3.ZERO
			var found := false
			# Distanta e REZULTAT, nu intrare. Raza se masoara din centroid, dar
			# degajarea din SOSEA — pe o pista de 380x220 m care se
			# auto-intersecteaza, cele doua nu se pot satisface simultan intr-un
			# interval fix, si de-aia inelul apropiat ramanea gol.
			#
			# Acum pornim de la marginea interioara a inelului si impingem spre
			# exterior pana intalnim degajarea. Inelul ramane sa dea SCARA si
			# ordinea de citire; distanta se aseaza singura.
			# Plafonul e legat de grila de teren (centroid ±380 m), nu de inel:
			# o silueta impinsa dincolo de ea ar sta peste cutia plata de rezerva,
			# nu peste nisipul vizibil.
			var limit: float = minf(float(ring["far"]) + 90.0, 355.0)
			var dist: float = float(ring["near"])
			while dist <= limit:
				var cand := centroid + Vector3(cos(angle), 0, sin(angle)) * dist
				if _road_distance_xz(cand) >= clear:
					pos = cand
					found = true
					break
				dist += 6.0
			if not found:
				missed += 1
				continue
			# Numele siluetelor sunt per TEMA, nu globale. `HORIZON_RINGS` le
			# tinea hardcodate (Butte_A, Mesa_B...), ceea ce mergea cat timp
			# exista un singur set de orizont; o insula numita `Butte_A` doar ca
			# sa treaca de o lista ar fi fost o minciuna in fisier. Cu steagul de
			# tema, fiecare tema isi aduce numele ei, iar cea fara steag pastreaza
			# lista din inel.
			var picks: Array = ring["picks"]
			var theme_picks: Array = theme_flag("horizon_picks", [])
			if not theme_picks.is_empty():
				picks = theme_picks[mini(HORIZON_RINGS.find(ring),
					theme_picks.size() - 1)]
			var model := _extract_glb_node(scene,
				picks[rng.randi_range(0, picks.size() - 1)])
			if model == null:
				continue
			add_child(model)
			# Ingropate 4m: taie muchia de la baza si le aseaza in peisaj.
			# Ingropate 4 m SUB nisipul de acolo, nu sub cota zero: la 150-320 m
			# terenul e deja dune in jurul mediei pistei, nu o podea plata.
			model.position = Vector3(pos.x,
				_sampler.ground_y(pos.x, pos.z) - 4.0, pos.z)
			model.rotation.y = rng.randf_range(0.0, TAU)
			# Scara creste cu inelul. La marimea nominala (25-60m) siluetele se
			# pierdeau sub linia cetii in loc sa se ridice pe cer — verificat in
			# vederea soferului. Sunt fundal pur, deci exagerarea nu costa nimic:
			# zero coliziune, sub 180 tris fiecare.
			var s: float = float(ring["scale"]) * rng.randf_range(0.85, 1.2)
			model.scale = Vector3.ONE * s
			# Clasa triplanara a temei: proiectia in spatiul lumii tine
			# straturile la scara reala si pe siluetele scalate 25-60x.
			# Era `apply_rock_material` fix, adica gresia rosiatica a canionului
			# si pe insulele de recif.
			Palette.apply_triplanar_class(model,
				String(theme_flag("horizon_class", "rock")))
			placed += 1
	print("%s: %d/%d siluete de orizont" % [track_name, placed,
		placed + missed])
	if missed > 0:
		# Fara linia asta, un orizont pe jumatate gol arata ca o alegere de
		# design. E exact bug-ul pe care l-a avut versiunea anterioara.
		push_warning("%s: %d siluete de orizont n-au incaput (degajare fata de sosea)"
			% [track_name, missed])


## Distanta pe orizontala pana la cel mai apropiat punct de sosea.
## Fata de SOSEA, nu fata de centroid: pista nu e rotunda, iar o mesa de 200 m
## latime aterizata pe drum ar fi o surpriza neplacuta.
func _road_distance_xz(pos: Vector3) -> float:
	var nearest := 1e12
	for i in range(0, baked.size(), 4):
		var dx := baked[i].x - pos.x
		var dz := baked[i].z - pos.z
		nearest = minf(nearest, dx * dx + dz * dz)
	return sqrt(nearest)


## Fara butte.glb (sau pe forest): dealurile rotunde de dinainte.
func _build_horizon_fallback(centroid: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed() + 1
	var placed := 0
	var attempts := 0
	while placed < 12 and attempts < 80:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(60.0, 140.0)
		var dist := rng.randf_range(240.0, 480.0)
		var pos := centroid + Vector3(cos(angle), 0, sin(angle)) * dist
		var nearest := 1e12
		for i in range(0, baked.size(), 4):
			var dx := baked[i].x - pos.x
			var dz := baked[i].z - pos.z
			nearest = minf(nearest, dx * dx + dz * dz)
		if sqrt(nearest) < radius + 60.0:
			continue
		placed += 1
		var hill := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 0.5
		# Implicit SphereMesh e 64x32 = 4224 triunghiuri. Pentru o movila vazuta
		# de la 240m+ e absurd. La distanta aia silueta e tot ce se vede.
		sphere.radial_segments = 12
		sphere.rings = 5
		hill.mesh = sphere
		hill.position = Vector3(pos.x, _sampler.ground_y(pos.x, pos.z) - 6.0, pos.z)
		# nuanta in 4 trepte, nu continua: dealurile de fundal impart 4 materiale
		var tint := float(rng.randi_range(0, 3)) / 3.0 * 0.15
		hill.material_override = _flat_material(theme_hill_color.lightened(tint))
		add_child(hill)


## Instantiaza un GLB si pastreaza un singur nod, anuland offsetul lui din fisier.
##
## `remove_child` INAINTE de `queue_free`, nu doar `queue_free`: eliberarea e
## amanata pana la sfarsitul cadrului, deci cine masoara containerul imediat
## (Track.model_aabb, _first_mesh) vede si variantele care tocmai au fost
## "sterse". Stalpii de marcaj au iesit toti cu aceeasi coliziune din cauza
## asta — inaltimea variantei drepte si latimea celei inclinate, amestecate.
func _extract_glb_node(scene: PackedScene, node_name: String) -> Node3D:
	var container := scene.instantiate() as Node3D
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == node_name:
			kept = child
		else:
			container.remove_child(child)
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


## Ca `_extract_glb_node`, dar pastreaza TOATE nodurile al caror nume incepe cu
## prefixul — un obiect spart pe clase de material (#130) e mai multe noduri
## care formeaza un ansamblu ("Portal_Rock", "Portal_Wood", "Portal_Trim").
##
## Spre deosebire de varianta pe un singur nod, containerul NU se recentreaza:
## piesele unui ansamblu isi impart originea, si mutarea ei dupa prima piesa
## gasita le-ar deplasa pe toate celelalte.
func _extract_glb_group(scene: PackedScene, prefix: String) -> Node3D:
	var container := scene.instantiate() as Node3D
	var kept := 0
	for child in container.get_children():
		if String(child.name).begins_with(prefix):
			kept += 1
		else:
			container.remove_child(child)
			child.queue_free()
	if kept == 0:
		container.queue_free()
		return null
	return container


## AABB-ul combinat al tuturor mesh-urilor dintr-un subarbore, in spatiul
## modelului. Baza pentru coliziunile de landmark si pentru scalarea portii de
## start: cotele se masoara, nu se scriu de mana.
##
## De ce nu ajunge primul mesh, cum face track_decor._first_mesh(): jumatate din
## GLB-urile din pipeline au mai multe noduri (moara are 2, arcada de stanca va
## avea 4), iar un singur nod da o cutie prea mica in tacere. Transformul local
## conteaza — palele morii au pivot propriu.
## `skip` taie un subarbore din masuratoare. Necesar fiindca ierarhia unui GLB
## nu e mereu plata: la toy_excavator, `arm` e COPIL al lui `body`, deci
## masurand `body` iese o cutie de 10 m care ar bloca soseaua permanent.
static func model_aabb(root: Node3D, skip: Node = null) -> AABB:
	var boxes: Array[AABB] = []
	_collect_aabbs(root, Transform3D.IDENTITY, boxes, skip)
	if boxes.is_empty():
		return AABB()
	var out: AABB = boxes[0]
	for i in range(1, boxes.size()):
		out = out.merge(boxes[i])
	return out


static func _collect_aabbs(node: Node, xform: Transform3D,
		out: Array[AABB], skip: Node = null) -> void:
	if node == skip:
		return
	var local := xform
	var spatial := node as Node3D
	if spatial != null:
		local = xform * spatial.transform
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		out.append(local * mi.mesh.get_aabb())
	for c in node.get_children():
		_collect_aabbs(c, local, out, skip)


func _centroid() -> Vector3:
	var sum := Vector3.ZERO
	for p in baked:
		sum += p
	return sum / float(baked.size())

## Terenul: NU un plan infinit de biliard, ci o panza cu valuri blande,
## APLATIZATA in coridorul pistei (fizica ramane plata acolo unde se
## conduce; relieful e scenografie). Variatie de culoare per varf — adanc
## = mai inchis — fara nicio textura.
## Cat de mare e panza de teren, in metri.
##
## Era 760 fix, ceea ce mergea cat timp cea mai lunga pista avea 1175 m si
## incapea comod. Okinawa are ~1800 m si o anvergura de peste 600 m: la 760,
## marginea grilei ar fi cazut in interiorul zonei de blend a terenului
## (GROUND_FLAT_RADIUS 45 + GROUND_BLEND_LEN 70 = 115 m dincolo de asfalt), deci
## pista s-ar fi terminat cu o faleza verticala in loc de tarm.
##
## Plafonul de jos e chiar 760: asa pistele existente primesc exact panza pe
## care o aveau, iar masuratorile lor raman comparabile. Cel de sus tine
## numarul de triunghiuri in frau — pasul de celula ramane constant, deci o
## panza de doua ori mai lata costa de patru ori mai mult.
const TERRAIN_MIN_SIZE: float = 760.0
const TERRAIN_MAX_SIZE: float = 1400.0
## Pasul grilei de teren, in metri. Constant indiferent de intindere.
## 48 -> 96 de celule (august 2026, upgrade-ul grafic): la ~7.9 m/celula,
## dunele mici din sampler (_detail_dunes, ~11 m lungime de unda) devin forme
## cu lumina proprie — la 15.8 m erau sub rezolutia grilei si dispareau.
## Costul: teren ~4.6k -> ~18.5k tris si trimesh de coliziune 4x, ambele
## acoperite (garda la 300k; Jolt duce trimesh static de ordinul asta lejer).
const TERRAIN_CELL: float = 760.0 / 96.0

func _world_extent() -> float:
	if baked.is_empty():
		return TERRAIN_MIN_SIZE
	var lo := baked[0]
	var hi := baked[0]
	for p in baked:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := maxf(hi.x - lo.x, hi.z - lo.z)
	var margin := 2.0 * (TrackSideSampler.GROUND_FLAT_RADIUS
		+ TrackSideSampler.GROUND_BLEND_LEN)
	return clampf(span + margin, TERRAIN_MIN_SIZE, TERRAIN_MAX_SIZE)


## Cat de sus fata de nivelul marii tine plaja, si pe cati metri se pierde in
## vegetatie. Vezi "inland_tint" din themes().
const BEACH_SAND_TOP: float = 1.4
const BEACH_FADE: float = 3.5


## Coace grila de inaltimi (o data per rebuild). O cer si umerii, care se
## construiesc INAINTEA terenului si trebuie sa se termine pe el.
func _terrain_grid() -> void:
	if _terr_cells > 0:
		return
	# 1500m si 56 de celule insemnau ~6200 de triunghiuri intinse pe o suprafata
	# din care jumatate nu se vede niciodata: ceata inghite totul la 250m, iar
	# siluetele de la orizont acopera fundalul. La 900m/36 raman ~2600, si nimeni
	# nu observa diferenta din masina.
	# Grila s-a indesit de la 36 la 48 de celule odata cu terenul care urmareste
	# soseaua: pasul de 25 m lasa o cusatura de pana la 3 m la marginea drumului
	# pe pantele de 12%. La 15.8 m cusatura scade sub 1 m, si asta se vede.
	var size := _world_extent()
	_terr_cells = int(round(size / TERRAIN_CELL))
	_terr_step = size / float(_terr_cells)
	_terr_origin = _centroid() - Vector3(size * 0.5, 0, size * 0.5)
	_terr_heights = PackedFloat32Array()
	_terr_heights.resize((_terr_cells + 1) * (_terr_cells + 1))
	for gz in _terr_cells + 1:
		for gx in _terr_cells + 1:
			# Toata matematica de inaltime traieste in sampler acum — aici doar
			# o citim. Asa terenul, falezele, decorul si landmark-urile nu pot
			# diverge: e literalmente aceeasi functie.
			_terr_heights[gz * (_terr_cells + 1) + gx] = _sampler.ground_y(
				_terr_origin.x + float(gx) * _terr_step,
				_terr_origin.z + float(gz) * _terr_step)


## Cota SUPRAFETEI de teren — nu a campului din sampler, ci a triunghiului care
## se randeaza si de care se lovesc rotile.
##
## Diferenta nu e o subtilitate: intre noduri, grila e o coarda dreapta. Pe o
## creasta, coarda taie pe dedesubt, iar campul spune "nisipul e la 30 cm sub
## asfalt" in timp ce triunghiul real e la 1.1 m dedesubt (masurat pe Dunele,
## fractia 0.31). Orice racord care se aliniaza la CAMP rateaza tocmai acolo
## unde treapta e cea mai mare.
##
## Interpolarea urmeaza exact taietura celulei din _build_terrain: diagonala
## merge de la (gx+1, gz) la (gx, gz+1), deci u + v = 1 separa cele doua
## triunghiuri.
func _terrain_mesh_y(x: float, z: float) -> float:
	_terrain_grid()
	var last := float(_terr_cells) - 0.0001
	var fx := clampf((x - _terr_origin.x) / _terr_step, 0.0, last)
	var fz := clampf((z - _terr_origin.z) / _terr_step, 0.0, last)
	var gx := int(fx)
	var gz := int(fz)
	var u := fx - float(gx)
	var v := fz - float(gz)
	var row := _terr_cells + 1
	var h00 := _terr_heights[gz * row + gx]
	var h10 := _terr_heights[gz * row + gx + 1]
	var h01 := _terr_heights[(gz + 1) * row + gx]
	var h11 := _terr_heights[(gz + 1) * row + gx + 1]
	if u + v <= 1.0:
		return h00 + u * (h10 - h00) + v * (h01 - h00)
	return h11 + (1.0 - u) * (h01 - h11) + (1.0 - v) * (h10 - h11)


func _build_terrain() -> void:
	_terrain_grid()
	var cells := _terr_cells
	var step := _terr_step
	var origin := _terr_origin
	var heights := _terr_heights
	# Pozitiile falezelor, pentru umbra coapta de la baza lor.
	var cliff_xz := _cliff_positions()
	# Vegetatia de uscat: vezi "inland_tint" in themes(). Null pe pistele fara
	# tema de insula, deci restul lumii nu se schimba cu un pixel.
	var inland: Variant = theme_flag("inland_tint", null)
	var inland_mix := float(theme_flag("inland_strength", 0.0))
	var sea_y := _sampler.mean_road_y() + sea_level_offset
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gz in cells:
		for gx in cells:
			var idx00 := gz * (cells + 1) + gx
			# ground_y include deja coborarea de 0.30 sub buza asfaltului.
			var corners := [
				Vector3(origin.x + float(gx) * step, heights[idx00],
					origin.z + float(gz) * step),
				Vector3(origin.x + float(gx + 1) * step, heights[idx00 + 1],
					origin.z + float(gz) * step),
				Vector3(origin.x + float(gx) * step,
					heights[idx00 + cells + 1],
					origin.z + float(gz + 1) * step),
				Vector3(origin.x + float(gx + 1) * step,
					heights[idx00 + cells + 2],
					origin.z + float(gz + 1) * step),
			]
			for tri in [[0, 1, 2], [1, 3, 2]]:
				for corner_idx: int in tri:
					var v: Vector3 = corners[corner_idx]
					# Nuanta dupa inaltimea RELATIVA la media pistei, nu absoluta.
					# Absoluta functiona doar cat timp terenul statea in jurul lui
					# zero; acum, cu terenul care urca la 19 m, ar fi spalat tot
					# varful pistei in alb.
					var rel := v.y - _sampler.mean_road_y()
					var shade := clampf(1.0 + rel * 0.012, 0.86, 1.10)
					shade *= _cliff_shadow(v, cliff_xz)
					var tint := theme_ground_tint
					if inland != null:
						# Banda de trecere e larga (3.5 m de cota) tocmai ca sa
						# nu se vada o linie de nivel: dunele o strambă singure,
						# iar marginea iese neregulata, ca o plaja.
						var t := clampf((v.y - sea_y - BEACH_SAND_TOP)
							/ BEACH_FADE, 0.0, 1.0)
						tint = tint.lerp(inland as Color, t * inland_mix)
					st.set_color(tint * shade)
					# UV din coordonate de LUME, nu din indexul celulei: asa
					# textura curge continuu peste toata suprafata, fara sa se
					# vada grila de 32x32 in tiparul ei.
					st.set_uv(Vector2(v.x, v.z) * SURFACE_TILING)
					# A doua scara, pentru stratul de detaliu: aceeasi textura,
					# de 15 ori mai lenta. Suprapuse, cele doua rup tiparul de
					# repetitie pe care ochiul il prinde imediat pe suprafete mari.
					st.set_uv2(Vector2(v.x, v.z) * SURFACE_TILING_MACRO)
					st.add_vertex(v)
	# Indexarea uneste colturile de celula partajate (pozitie+culoare+UV
	# identice), deci normalele se mediaza REAL intre celule vecine: dunele
	# prind lumina continuu, fara fatete aleatorii pe grila.
	st.index()
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	# Granulatie de nisip peste culoarea din vertex colors. Textura e gri si se
	# inmulteste, deci nu aduce culori noi — doar rupe pata uniforma care facea
	# terenul sa arate ca plastic turnat.
	var sand_tex := _tex("res://assets/textures/surface_sand.png")
	if sand_tex != null:
		mat.albedo_texture = sand_tex
		mat.uv1_scale = Vector3.ONE
		# albedo_color ramane ALB: culoarea vine din vertex colors, iar textura o
		# moduleaza. Orice ridicare aici impinge canalul rosu peste 1.0, se
		# satureaza, si granulatia dispare exact unde trebuia sa se vada.
		#
		# A doua trecere pe UV2 (scara macro): granulatia deasa da suprafata,
		# petele lente rup repetitia. Terenul are UV2 real (emis mai sus), deci
		# NU are nevoie de triplanar ca prop-urile.
		#
		# ALTA textura pe trecerea macro, nu aceeasi ca inainte. Fotografia
		# aeriana de 20 m arata pete si urme late — la 45 m/repetitie iese
		# aproape la scara ei reala, in timp ce pe UV1 (3.1 m) era stransa de sase
		# ori si se topea in mipmap. Granula fina o aduce acum sursa micro, care
		# chiar e o scanare de 2.5 m. Mediile amandurora raman 0.850, deci
		# produsul — si expunerea terenului — sunt neatinse.
		mat.detail_enabled = true
		mat.detail_albedo = _tex("res://assets/textures/surface_sand_macro.png")
		mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	mat.roughness = 0.95 # style_bible §4: nisip
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	inst.material_override = mat

	# COLIZIUNE PE TEREN — obligatorie de cand nisipul urmareste soseaua.
	#
	# Inainte, singura podea fizica in afara drumului era o cutie plata cu fata la
	# -0.3, care se NIMEREA sa coincida cu nisipul vizibil. In clipa in care
	# nisipul urca la 19 m pe creasta, o masina care iese de pe drum ar cadea prin
	# nisipul pe care il vede. Fara asta, tot task-ul ar fi fost o poza mai
	# frumoasa peste o lume stricata.
	#
	# Intra si pe layer-ul de blocare a camerei: camera noua, mai inalta, chiar
	# are nevoie de sol acolo, altfel intra sub nisip pe creste.
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	body.collision_layer |= CAMERA_BLOCKER_LAYER
	var shape := CollisionShape3D.new()
	var tri := inst.mesh.create_trimesh_shape() as ConcavePolygonShape3D
	# Ca la sosea: winding-ul nostru e arbitrar, iar trimesh-urile sunt implicit
	# unilaterale.
	tri.backface_collision = true
	shape.shape = tri
	body.add_child(shape)
	body.add_child(inst)
	add_child(body)


# ------------------------------------------------------------------- apa

## Cota marii, RELATIV la media cotelor soselei — nu la y = 0.
##
## Asta e capcana: terenul departat nu oscileaza in jurul originii lumii, ci in
## jurul lui TrackSideSampler.mean_road_y() (vezi ground_y). Pe Dunele media e
## pe la +6-7 m, pe Muntele si mai sus. Un plan de apa la y = 0 ar fi, pe unele
## piste, complet ingropat — si nimeni n-ar sti de ce, fiindca "nivelul marii e
## zero" e o presupunere pe care n-o pui la indoiala.
@export var sea_level_offset: float = -7.0

## Cat de adanc sapa laguna sub media soselei, cand [method _lagoon_points] da un
## contur. Se citeste IMPREUNA cu sea_level_offset: diferenta dintre ele e
## adancimea apei din laguna, iar ea trebuie sa ramana sub SEA_NEAR_DEPTH ca
## laguna sa fie turcoaz de mic adanc pe toata suprafata, nu albastru de larg.
@export var lagoon_depth: float = 20.0

## Cat de departe de tarm mai are rost geometrie fina. Dincolo, culoarea e
## oricum sea_deep uniform, deci preia cvadrilaterul de larg.
const SEA_NEAR_DEPTH: float = 14.0
## Sub atat de multa apa, un varf e "larg"; peste, e recif.
const SEA_REEF_DEPTH: float = 5.0
## Banda de spuma: cati metri de apa peste tarm mai citesc ca sparger de val.
const SEA_FOAM_DEPTH: float = 0.6
## Pasul grilei fine de langa tarm: 9.5 m, de doua ori mai des decat terenul
## (15.8 m), fiindca linia tarmului e ce se vede. Constant, ca si al terenului —
## o pista mai mare primeste mai multe celule, nu celule mai mari.
const SEA_CELL: float = 9.5
## Cat de mult depaseste cvadrilaterul de larg grila fina. Trebuie sa ajunga
## dincolo de ceata (250 m) ca marea sa nu aiba margine vizibila.
const SEA_FAR_EXTENT: float = 2400.0
## Amplitudinea valurilor de vertecsi din water.gdshader, in metri.
##
## Traieste AICI, nu ca valoare implicita in shader, si nu din cochetarie: e
## singurul numar din care se poate deriva corect SEA_FAR_DROP (vezi mai jos).
## Doua copii ale ei — una in shader, una aici — s-ar desincroniza la prima
## retusare a valurilor, si exact desincronizarea aia a produs bug-ul pe care
## il descrie SEA_FAR_DROP.
##
## Vertecsii se misca cu +/- amplitudinea asta: suma sinusoidelor din shader e
## 0.6 + 0.4 = 1.0 la varf, deci deplasarea maxima E chiar numarul de aici.
const SEA_WAVE_AMP: float = 0.12

## Cu cat sta mai jos cvadrilaterul de larg fata de grila fina.
##
## Sunt doua suprafete la aceeasi cota, deci ar face z-fighting pe toata zona de
## suprapunere. Cateva centimetri le separa fara sa se vada: la nivelul marii,
## din masina, treapta e sub un pixel.
##
## Cat de mult: STRICT mai mult decat coboara valurile grila fina, plus o marja.
## Valoarea a fost 4 cm fixi, scrisa cand marea era plata — si a devenit gresita
## in tacere cand grila fina a primit valuri de vertecsi de +/-12 cm (#122).
## Simptomul, vizibil in orice captura de sus a Okinawei: grila fina se scufunda
## sub larg pe portiunile in care sinusoida e in vale, iar prin gaura se vedea
## SeaFar — adica petele MARI, ALBASTRU INCHIS, cu margini poligonale (fatetele
## grilei de 9.5 m), care se PLIMBAU pe laguna fiindca sinusoidele au TIME in
## ele. Culoarea petelor masurata pe captura: #215965, adica exact sea_deep, la
## 4 m de apa unde laguna trebuia sa fie turcoaz.
##
## Marja de 8 cm peste amplitudine: la nivelul marii, din masina, 20 cm de
## treapta raman sub un pixel, iar in zona in care cele doua suprafete chiar se
## invecineaza (adancime > SEA_NEAR_DEPTH) anvelopa valului e oricum zero.
const SEA_FAR_DROP: float = SEA_WAVE_AMP + 0.08


## Marea: o grila fina langa tarm plus un cvadrilater urias pentru larg.
##
## De ce doua mesh-uri si nu unul singur: linia tarmului are nevoie de rezolutie
## (banda de spuma, tranzitia recif->larg), largul n-are nevoie de niciuna. O
## grila uniforma destul de deasa pentru tarm ar fi costat, pe toata suprafata,
## de trei ori bugetul de triunghiuri al intregii piste. Asa geometria sta acolo
## unde se uita jucatorul.
func _build_water() -> void:
	if not theme_flag("water", false):
		return
	if _sampler == null or baked.is_empty():
		return
	var sea_y := _sampler.mean_road_y() + sea_level_offset
	var root := Node3D.new()
	root.name = "Sea"
	add_child(root)
	_build_sea_far(root, sea_y)
	_build_sea_near(root, sea_y)
	_build_sea_respawn(sea_y)


## Largul: doua triunghiuri. Nu are nevoie de mai mult.
func _build_sea_far(root: Node3D, sea_y: float) -> void:
	var c := _centroid()
	var h := SEA_FAR_EXTENT * 0.5
	var y := sea_y - SEA_FAR_DROP
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var deep := water_tint(Palette.SEA_DEEP)
	# Alfa 1.0 = ADANCIMEA maxima (vezi _sea_color), nu opacitate. Placa asta e
	# largul, deci sta la capatul rampei de culoare.
	#
	# Aici a fost o capcana care merita scrisa. Cat timp alfa purta amplitudinea
	# valurilor, linia asta era `deep.a = 0.0`, cu motivul "largul are 4 varfuri
	# pe 2.4 km, deplasati ar legana toata placa marii". Corect atunci — dar sub
	# semantica noua, 0 inseamna ADANCIME ZERO, adica linia apei: toata marea
	# deschisa se randa cu culoarea de nisip ud si acoperita de spuma. Nimic
	# n-ar fi semnalat-o, fiindca linia se compileaza si merge.
	#
	# Cu anvelopa reconstituita din adancime, intentia veche se pastreaza
	# singura: la adancime 1.0 anvelopa e zero, deci largul tot nu se leagana.
	deep.a = 1.0
	var corners := [
		Vector3(c.x - h, y, c.z - h), Vector3(c.x + h, y, c.z - h),
		Vector3(c.x - h, y, c.z + h), Vector3(c.x + h, y, c.z + h),
	]
	for tri: Array in [[0, 1, 2], [1, 3, 2]]:
		for ci: int in tri:
			st.set_color(deep)
			st.set_normal(Vector3.UP)
			st.add_vertex(corners[ci])
	var inst := MeshInstance3D.new()
	inst.name = "SeaFar"
	inst.mesh = st.commit()
	inst.material_override = _water_material()
	root.add_child(inst)


## Zona de tarm: doar celulele care chiar au apa deasupra lor.
##
## Celulele complet uscate se SAR, din doua motive care conteaza amandoua:
## triunghiuri economisite, si — mai important — fara ele n-ar exista z-fighting
## intre apa si nisip pe toata suprafata insulei.
func _build_sea_near(root: Node3D, sea_y: float) -> void:
	var c := _centroid()
	# Aceeasi intindere ca terenul: dincolo preia cvadrilaterul de larg.
	var size := _world_extent()
	var cells := int(round(size / SEA_CELL))
	var step := size / float(cells)
	var origin := c - Vector3(size * 0.5, 0, size * 0.5)

	# Adancimea in fiecare nod al grilei, calculata O SINGURA DATA: ground_y e
	# o interpolare Shepard peste toate punctele coapte, adica departe de
	# gratuita. Cu 81x81 = 6561 de apeluri in loc de 4 per celula.
	var depth: Array[float] = []
	depth.resize((cells + 1) * (cells + 1))
	for gz in cells + 1:
		for gx in cells + 1:
			var wx := origin.x + float(gx) * step
			var wz := origin.z + float(gz) * step
			depth[gz * (cells + 1) + gx] = sea_y - _sampler.ground_y(wx, wz)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var emitted := 0
	for gz in cells:
		for gx in cells:
			var i00 := gz * (cells + 1) + gx
			var idx := [i00, i00 + 1, i00 + cells + 1, i00 + cells + 2]
			var d_max := -INF
			var d_min := INF
			for k: int in idx:
				d_max = maxf(d_max, depth[k])
				d_min = minf(d_min, depth[k])
			if d_max <= 0.0:
				continue # uscat pe tot patratul
			if d_min > SEA_NEAR_DEPTH:
				continue # larg curat — il acopera cvadrilaterul de dedesubt
			var pos := [
				Vector3(origin.x + float(gx) * step, sea_y,
					origin.z + float(gz) * step),
				Vector3(origin.x + float(gx + 1) * step, sea_y,
					origin.z + float(gz) * step),
				Vector3(origin.x + float(gx) * step, sea_y,
					origin.z + float(gz + 1) * step),
				Vector3(origin.x + float(gx + 1) * step, sea_y,
					origin.z + float(gz + 1) * step),
			]
			for tri: Array in [[0, 1, 2], [1, 3, 2]]:
				for k: int in tri:
					st.set_color(_sea_color(depth[idx[k]]))
					st.set_normal(Vector3.UP)
					st.add_vertex(pos[k])
			emitted += 1
	if emitted == 0:
		return
	var inst := MeshInstance3D.new()
	inst.name = "SeaNear"
	inst.mesh = st.commit()
	inst.material_override = _water_material()
	root.add_child(inst)


## Cat de saturata iese apa fata de cat a fost autorata.
##
## Environment.adjustment_saturation e 1.18 pe TOATA imaginea. Suprafetele
## aproape nesaturate abia se misca sub el — de-asta nisipul si asfaltul n-au
## avut niciodata problema asta. Apa e insa cea mai saturata suprafata mare din
## cadru, deci acolo se vede: masurat pe recif, #54BFB8 autorat iesea #4DD4CE,
## adica verdele si albastrul cu +21 si +22 peste tinta, in timp ce rosul era la
## -7. Nu e o eroare de luminozitate (aia s-ar fi vazut pe toate trei canalele),
## e chiar saturatia.
const WATER_SATURATION_FIX: float = 1.18

## Pasul de iluminare pe care shaderul unshaded il SARE.
##
## Orice alta suprafata din lume isi inmulteste albedo-ul cu lumina inainte de
## tonemap. Apa nu (vezi water.gdshader: unshaded, deliberat). Diferenta se
## masoara: dupa corectia de saturatie, reciful si largul ieseau amandoua cu
## ~+19/255 UNIFORM pe toate trei canalele — adica exact luminozitate in plus,
## nu nuanta gresita.
##
## Valoarea vine din masuratoare, nu din formula: 0.87 e raportul dintre tinta
## si masurat pe cele doua zone. Daca se schimba tonemap-ul, expunerea sau
## ripple_strength din shader, se REIA masuratoarea:
##   godot --path . res://tools/Snapshot.tscn -- --track=4 --size=300
## si se compara largul cu #2E5F6B, reciful cu #54BFB8.
const WATER_GAIN: float = 0.87


## Culoarea unei ape, pregatita pentru vertex colors.
##
## Doua corectii, amandoua din masuratoare:
##
## 1. DESATURARE cu WATER_SATURATION_FIX — compenseaza exact multiplicatorul
##    global din Environment, ca pixelul final sa cada pe culoarea din paleta.
##
## 2. srgb_to_linear — obligatorie fiindca shaderul apei e unshaded. Un vertex
##    color e citit ca LINIAR; restul lumii scapa fara conversie doar pentru ca
##    e ILUMINATA, iar inmultirea cu lumina readuce valorile in interval. Apa nu
##    are pasul ala. Masurat fara conversie: largul iesea #86C2CB in loc de
##    #2E5F6B, cu 95/255 peste tinta pe fiecare canal — turcoaz palid in loc de
##    mare adanca.
##
## S-a incercat si varianta "apa iluminata, fara conversie", ca sa fie o singura
## conventie in proiect. Nu merge: culorile INCHISE hranite ca liniare se umfla
## prea tare, iar lumina de aici (soare 1.5 + ambient) nu le mai coboara —
## marea iesea palida. Terenul nu are culori inchise, de-asta n-a semnalat
## nimeni pana acum.
## Desaturarea se face in jurul LUMINANTEI, nu in HSV.
##
## Prima incercare a fost `Color.from_hsv(h, s / 1.18, v)`. Nu e inversa
## operatiei: HSV pastreaza V, deci reducerea saturatiei urca doar canalele mici
## spre cel mare si INALBESTE culoarea. Masurat, eroarea reciful a crescut de la
## (-7, +21, +22) la (+21, +22, +24) — adica exact ce nu voiam.
## adjustment_saturation lucreaza in jurul luminantei, deci si compensarea
## trebuie sa faca la fel.
func water_tint(slot: int) -> Color:
	var c := Palette.color(slot)
	var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	var k := 1.0 / WATER_SATURATION_FIX
	return Color(
		(lum + (c.r - lum) * k) * WATER_GAIN,
		(lum + (c.g - lum) * k) * WATER_GAIN,
		(lum + (c.b - lum) * k) * WATER_GAIN).srgb_to_linear()


## Culoarea unui varf dupa cata apa are sub el.
##
## Spuma e GEOMETRIE, nu depth fade: banda de varfuri unde apa abia acopera
## tarmul primeste foam_white. Un depth fade ar fi cerut DEPTH_TEXTURE, adica
## un pas de citire a adancimii pe fiecare pixel de apa — pe mobil, exact
## genul de cost pe care nu-l vede nicio garda din proiect.
func _sea_color(d: float) -> Color:
	var reef := water_tint(Palette.REEF_SHALLOW)
	var deep := water_tint(Palette.SEA_DEEP)
	# Spuma NU e alb curat, ci alb spart cu recif.
	#
	# La FOAM_WHITE pur, banda de tarm citea ca zapada, nu ca sparger de val —
	# si o citea lat, fiindca varfurile USCATE ale celulelor de mal sunt tot
	# spuma si isi intind culoarea peste toata celula prin interpolare.
	var foam := water_tint(Palette.FOAM_WHITE).lerp(reef, 0.35)
	var c: Color
	if d <= 0.0:
		c = foam # varf uscat al unei celule de mal
	elif d < SEA_FOAM_DEPTH:
		c = foam.lerp(reef, d / SEA_FOAM_DEPTH)
	elif d < SEA_REEF_DEPTH:
		c = reef
	else:
		c = reef.lerp(deep, clampf(
			(d - SEA_REEF_DEPTH) / (SEA_NEAR_DEPTH - SEA_REEF_DEPTH), 0.0, 1.0))
	# Alfa = ADANCIMEA normalizata, NU transparenta: materialul e opac, iar
	# shaderul v2 citeste COLOR.a ca sa evalueze rampa de culoare PER PIXEL —
	# interpolata pe varfuri la 9.5 m, rampa iesea in benzi (issue #99).
	#
	# Aici s-au ciocnit doua implementari paralele, si merita spus de ce a
	# castigat asta. Valurile de vertecsi (#122) foloseau tot COLOR.a, dar
	# pentru AMPLITUDINEA lor: zero la tarm (un val acolo deschide o fisura cu
	# terenul), zero spre larg (granita cu planul fix SeaFar), varf pe recif.
	# Adancimea e insa strict mai informativa — anvelopa aia e ea insasi o
	# functie de adancime, deci se poate reconstitui in shader din alfa plus un
	# singur prag (`wave_reef` = SEA_REEF_DEPTH / SEA_NEAR_DEPTH), pe cand
	# drumul invers nu exista: din amplitudine nu poti afla adancimea, fiindca
	# anvelopa urca si coboara, deci doua adancimi diferite dau acelasi numar.
	c.a = clampf(d / SEA_NEAR_DEPTH, 0.0, 1.0)
	return c


## Materialul apei — UNUL SINGUR pentru ambele mesh-uri.
##
## Cache-ul nu e cosmetic: un ShaderMaterial per petec de apa ar strica
## raportul mesh-uri/materiale din tools/probe_decor.gd, adica exact garda de
## draw call-uri. Doua mesh-uri, un material, un draw call in plus fata de
## lumea de pe atlas.
var _water_mat: ShaderMaterial

func _water_material() -> ShaderMaterial:
	if _water_mat != null:
		return _water_mat
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = load("res://assets/shaders/water.gdshader") as Shader
	# Aceeasi textura pe care o foloseste deja stratul de detaliu al lumii —
	# zero VRAM in plus.
	_water_mat.set_shader_parameter("ripple_tex", load(Palette.DETAIL_PATH))
	# v2 (issue #99): rampa de adancime per pixel, spuma animata, glint.
	# Culorile trec toate prin water_tint() — calibrarea ramane pe CPU, intr-un
	# singur loc. Intensitatile sunt kill-switch-uri: 0 = comportamentul v1,
	# de stins pe rand la profilarea pe device (M4).
	var shallow := water_tint(Palette.REEF_SHALLOW)
	var deep := water_tint(Palette.SEA_DEEP)
	# Nisipul ud de la linia apei: nisipul de coral, intunecat putin — apa
	# uda nisipul inainte sa-l acopere.
	var shore := water_tint(Palette.CORAL_SAND).darkened(0.12)
	var foam := water_tint(Palette.FOAM_WHITE).lerp(shallow, 0.35)
	_water_mat.set_shader_parameter("ramp_strength", 1.0)
	_water_mat.set_shader_parameter("shore_col", Vector3(shore.r, shore.g, shore.b))
	_water_mat.set_shader_parameter("shallow_col",
		Vector3(shallow.r, shallow.g, shallow.b))
	_water_mat.set_shader_parameter("deep_col", Vector3(deep.r, deep.g, deep.b))
	_water_mat.set_shader_parameter("foam_strength", 0.75)
	_water_mat.set_shader_parameter("foam_col", Vector3(foam.r, foam.g, foam.b))
	_water_mat.set_shader_parameter("glint_strength", 0.55)
	# SPRE soare: inversul directiei in care bat razele. Din aceeasi rotatie
	# ca lumina reala (SUN_ROTATION_DEG), ca scanteierea sa cada corect.
	var to_sun := -(Basis.from_euler(Vector3(
		deg_to_rad(SUN_ROTATION_DEG.x), deg_to_rad(SUN_ROTATION_DEG.y),
		deg_to_rad(SUN_ROTATION_DEG.z))) * Vector3.FORWARD)
	_water_mat.set_shader_parameter("sun_dir", to_sun)
	# v3: creste de hula si trepte de adancime. Doua intrerupatoare, ambele in
	# lista de stins la profilarea pe device — crestele costa 2 sin + 2 pow,
	# treptele nu costa nimic (aceleasi esantioane).
	#
	# Directia hulei NU e aleatoare si nici legata de pista: bate dinspre soare,
	# adica dinspre partea din care si scanteierea vine. Doua directii diferite
	# ar fi dat o mare care sclipeste intr-o parte si curge in alta.
	_water_mat.set_shader_parameter("crest_strength", 0.85)
	_water_mat.set_shader_parameter("crest_dir",
		Vector2(to_sun.x, to_sun.z).normalized())
	_water_mat.set_shader_parameter("band_strength", 0.60)
	# Varful anvelopei de valuri, in adancime normalizata. Din constantele de
	# aici, nu scris de mana in shader: reciful e o cota de gameplay, iar doua
	# copii ale ei s-ar desincroniza tacut la prima retusare a lagunei.
	_water_mat.set_shader_parameter("wave_reef",
		SEA_REEF_DEPTH / SEA_NEAR_DEPTH)
	# Amplitudinea valurilor vine tot de pe CPU, din acelasi motiv ca wave_reef,
	# doar ca aici consecinta desincronizarii nu e cosmetica: SEA_FAR_DROP se
	# calculeaza din ea, iar daca shaderul ar avea alta valoare, grila fina s-ar
	# scufunda sub larg si ar reaparea petele de sea_deep pe laguna.
	_water_mat.set_shader_parameter("wave_amp", SEA_WAVE_AMP)
	return _water_mat


## Iesitul in mare = repunere pe traseu.
##
## Acelasi tipar ca plasa de sub creasta de fly-off (_build_flyoff_net): un
## Area3D care prinde ce a cazut si cheama RespawnZone. Volumul incepe SUB
## suprafata, ca stropul de la intrare sa apuce sa se vada.
func _build_sea_respawn(sea_y: float) -> void:
	var c := _centroid()
	var zone := RespawnZone.new()
	zone.name = "SeaRespawn"
	zone.backoff_m = 16.0
	add_child(zone)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var top := sea_y - 1.2
	var bottom := sea_y - 60.0
	box.size = Vector3(SEA_FAR_EXTENT, top - bottom, SEA_FAR_EXTENT)
	shape.shape = box
	zone.add_child(shape)
	zone.global_position = Vector3(c.x, (top + bottom) * 0.5, c.z)


## Cat de dens se testeaza terenul fata de faleze. Peste raza asta o faleza nu
## mai intuneca nimic.
const CLIFF_AO_RADIUS: float = 14.0
## Cat de intunecat e nisipul lipit de baza unei faleze.
##
## Coborat de la 0.45 cand au intrat umbrele dinamice: cele doua se ADUNA, iar
## la 0.45 baza falezelor iesea aproape neagra. AO-ul ramane pentru contactul
## fin si omniprezent, umbra dinamica face directia si forma.
const CLIFF_AO_STRENGTH: float = 0.22


## Pozitiile (doar XZ) ale falezelor deja construite.
##
## Se citesc din arbore, nu se recalculeaza: TrackCliffs are propriile filtre
## (ferestre libere, gol in jurul landmark-urilor, sloturi respinse), iar o a doua
## implementare a acelorasi reguli ar diverge la prima ajustare.
func _cliff_positions() -> PackedVector2Array:
	var out := PackedVector2Array()
	var cliffs := get_node_or_null("Cliffs")
	if cliffs == null:
		return out
	for child in cliffs.get_children():
		if child is StaticBody3D:
			continue # corpul de coliziune, nu un nod vizual
		var n := child as Node3D
		if n != null:
			out.append(Vector2(n.position.x, n.position.z))
	return out


## Umbra coapta la baza falezelor, ca factor multiplicativ (1.0 = neatins).
##
## Completeaza umbrele dinamice, nu le dubleaza: astea sunt OMNIPREZENTE (nu
## depind de unghiul soarelui si nu se opresc la SHADOW_DISTANCE), deci dau
## contactul fin de peste tot, inclusiv pe falezele departate unde cascada nu mai
## ajunge. Costa cateva inmultiri la generare si zero la runtime.
##
## Cand au intrat umbrele dinamice, CLIFF_AO_STRENGTH a coborat de la 0.45 la
## 0.22 — cele doua se aduna si baza iesea aproape neagra.
func _cliff_shadow(v: Vector3, cliff_xz: PackedVector2Array) -> float:
	if cliff_xz.is_empty():
		return 1.0
	var p := Vector2(v.x, v.z)
	var nearest_sq := INF
	for c in cliff_xz:
		nearest_sq = minf(nearest_sq, p.distance_squared_to(c))
	var d := sqrt(nearest_sq)
	if d >= CLIFF_AO_RADIUS:
		return 1.0
	# Cadere patratica: umbra e concentrata langa piatra, nu o pata larga.
	var t := d / CLIFF_AO_RADIUS
	return 1.0 - CLIFF_AO_STRENGTH * (1.0 - t) * (1.0 - t)


## Textura incarcata doar daca exista (inainte de prima generare lipsesc).
func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func start_point() -> Vector3:
	return baked[0]

func start_direction() -> Vector3:
	return (baked[1] - baked[0]).normalized()

# -------------------------------------------------------------- constructie

func _build_curve() -> void:
	curve = Curve3D.new()
	curve.bake_interval = 3.0
	var pts := _points()
	var n := pts.size()
	for i in n + 1:
		var p := pts[i % n]
		var prev := pts[(i - 1 + n) % n]
		var next := pts[(i + 1) % n]
		var tangent := (next - prev) * 0.22
		curve.add_point(p, -tangent, tangent)
	baked = curve.get_baked_points()
	if baked.size() > 1 and baked[0].distance_to(baked[baked.size() - 1]) < 0.5:
		baked.remove_at(baked.size() - 1)
	# Distante cumulate — pentru coordonate UV continue de-a lungul soselei.
	_dists = PackedFloat32Array()
	_dists.resize(baked.size() + 1)
	_dists[0] = 0.0
	for i in baked.size():
		var j := (i + 1) % baked.size()
		_dists[i + 1] = _dists[i] + baked[i].distance_to(baked[j])
	_build_routes()


## Ruta 0 = bucla principala; 1+ = scurtaturi.
##
## `baked` / `_dists` / `curve` raman EXACT ce erau — sunt ruta 0 privita direct.
## Asa tot codul care le citeste (teren, decor, faleze, hazarde, popici, sonde)
## functioneaza neschimbat, iar rutele sunt o adaugire, nu o rescriere.
func _build_routes() -> void:
	routes.clear()
	var main := TrackRoute.new()
	main.baked = baked
	main.dists = _dists
	main.half_width = half_width
	main.closed = true
	main.label = "principal"
	routes.append(main)
	for spec in _branch_specs():
		var branch := _make_branch(spec)
		if branch != null:
			routes.append(branch)


## Toate punctele coapte ale benzilor SECUNDARE, intr-o singura lista.
##
## Le primeste [TrackSideSampler] ca sa stie ca si acolo e drum: terenul le
## urmareste cota, iar decorul le ocoleste.
func _branch_corridor_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(1, routes.size()):
		out.append_array(routes[i].baked)
	return out


## Conturul lagunei in forma pe care o vrea samplerul.
func _lagoon_poly() -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in _lagoon_points():
		out.append(p)
	return out


## Suprafata benzilor secundare.
##
## NU refoloseste _build_road(): scurtatura din Okinawa e un banc de nisip
## submers, nu sosea. Fara borduri, fara linie de mijloc, fara umeri, fara
## pereti — si cu nisip coraligen in loc de asfalt. Asta e si diferenta pe care
## trebuie s-o citesti din mers ca sa stii ca intri pe alta banda.
func _build_branch_surfaces() -> void:
	for bi in range(1, routes.size()):
		var r := routes[bi]
		var n := r.count()
		if n < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tile := 3.5
		var u_half := r.half_width / tile
		# Banda submersa sta putin SUB cota capetelor: asa se vede de departe ca
		# intri in apa, si asa nu se bate cu asfaltul in punctele de racord.
		for i in n - 1:
			var j := i + 1
			var l0 := r.baked[i] - r.side_at(i) * r.half_width
			var r0 := r.baked[i] + r.side_at(i) * r.half_width
			var l1 := r.baked[j] - r.side_at(j) * r.half_width
			var r1 := r.baked[j] + r.side_at(j) * r.half_width
			var v0 := r.dists[i] / tile
			var v1 := r.dists[j] / tile
			st.set_uv(Vector2(-u_half, v0)); st.add_vertex(l0)
			st.set_uv(Vector2(u_half, v0)); st.add_vertex(r0)
			st.set_uv(Vector2(-u_half, v1)); st.add_vertex(l1)
			st.set_uv(Vector2(u_half, v0)); st.add_vertex(r0)
			st.set_uv(Vector2(u_half, v1)); st.add_vertex(r1)
			st.set_uv(Vector2(-u_half, v1)); st.add_vertex(l1)
		st.index()
		st.generate_normals()
		# Nisip umed: coral_sand intunecat. Nu e asfalt si nu trebuie sa para.
		_add_mesh_with_collision(st.commit(),
			Palette.color(Palette.CORAL_SAND).darkened(0.22),
			_tex("res://assets/textures/surface_sand.png"))


## Construieste o scurtatura dintr-o specificatie.
##
## Capetele NU se dau de mana: se citesc de pe bucla principala, la fractiile
## cerute. Asa scurtatura pleaca si revine garantat DE PE asfalt, oricat s-ar
## muta punctele de control ale pistei — un capat scris manual ar fi ramas in
## urma la prima ajustare de traseu si ar fi lasat o treapta in aer.
func _make_branch(spec: Dictionary) -> TrackRoute:
	var mid: Array[Vector3] = []
	mid.assign(spec.get("points", []))
	if mid.is_empty():
		push_error("Track: scurtatura fara puncte intermediare")
		return null
	var entry := fposmod(float(spec.get("entry", 0.0)), 1.0)
	var exit_f := fposmod(float(spec.get("exit", 0.0)), 1.0)
	var n := baked.size()
	var i_entry := int(entry * float(n)) % n
	var i_exit := int(exit_f * float(n)) % n
	var pts: Array[Vector3] = [baked[i_entry]]
	pts.append_array(mid)
	pts.append(baked[i_exit])
	var route := TrackRoute.from_points(pts, false, curve.bake_interval)
	route.half_width = float(spec.get("half_width", half_width))
	route.entry_frac = frac_at(i_entry)
	route.exit_frac = frac_at(i_exit)
	route.wet = bool(spec.get("wet", false))
	route.label = String(spec.get("label", "scurtatura"))
	return route

func _side_at(i: int) -> Vector3:
	var n := baked.size()
	var dir := (baked[(i + 1) % n] - baked[i]).normalized()
	return dir.cross(Vector3.UP).normalized()


## ############################################################################
## CANALE NAVIGABILE
##
## Un canal e singura structura din joc care taie soseaua in doua. Restul —
## rapa, laguna, fundul de mare — sapa doar PE LANGA drum, tocmai ca sa nu apara
## un gol sub roti. Aici golul E gimmick-ul.

## Descrierile rezolvate ale canalelor: acelasi dictionar ca `_channel_specs()`,
## plus tot ce se poate calcula O SINGURA DATA din curba coapta. Il citesc
## samplerul (ca sa sape), fiecare generator de suprafata (ca sa lase gaura) si
## hazardul (ca sa se aseze exact pe capetele gaurii).
var _channels: Array[Dictionary] = []


## Traduce fractiile declarate in indici, versori si cote.
##
## Golul din sosea NU poate avea lungimea ceruta la centimetru: soseaua se emite
## din segmente coapte, deci capetele lui cad pe puncte de pe curba. Se alege
## numarul de pasi care NIMERESTE CEL MAI BINE lungimea ceruta si se pastreaza
## lungimea OBTINUTA — de la ea depinde cata viteza iti trebuie ca sa treci, deci
## e o cifra care se masoara, nu una care se presupune.
##
## Pasul se cauta, nu se calculeaza dintr-o impartire, si asta a fost o
## reparatie: `bake_interval` e un MAXIM, iar Curve3D indeseste punctele in
## viraje. Pe Okinawa media iese ~2.0 m in timp ce pe dreapta unde sta podul
## segmentele sunt la 2.5. Impartirea la medie a cerut 3 pasi si a livrat un gol
## de 15.0 m in loc de 12 — cu 25% mai mult, adica pragul de viteza urcat de la
## 71% la 79% din viteza de varf, fara ca nimeni sa fi cerut asta.
func _resolve_channels() -> void:
	_channels.clear()
	var n := baked.size()
	if n < 8:
		return
	for spec in _channel_specs():
		var frac := fposmod(float(spec.get("frac", 0.0)), 1.0)
		var ci := int(frac * float(n)) % n
		var want := float(spec.get("gap", 12.0))
		var steps := 1
		var best := INF
		for k in range(1, 12):
			var a := baked[((ci - k) % n + n) % n]
			var b := baked[(ci + k) % n]
			var err := absf(a.distance_to(b) - want)
			if err < best:
				best = err
				steps = k
		var near_i := ((ci - steps) % n + n) % n
		var far_i := (ci + steps) % n
		# Sensul de mers si axa canalului, amandoua ORIZONTALE: taietura de teren
		# lucreaza in plan, iar o componenta pe y ar face malul sa se incline cu
		# panta soselei.
		var across := baked[far_i] - baked[near_i]
		across.y = 0.0
		across = across.normalized()
		var along := across.cross(Vector3.UP).normalized()
		var ch := spec.duplicate()
		ch["index"] = ci
		ch["near"] = near_i
		ch["far"] = far_i
		ch["steps"] = steps
		ch["origin"] = baked[ci]
		ch["near_point"] = baked[near_i]
		ch["far_point"] = baked[far_i]
		ch["along"] = along
		ch["across"] = across
		ch["along2"] = Vector2(along.x, along.z)
		ch["across2"] = Vector2(across.x, across.z)
		ch["gap_requested"] = want
		ch["gap"] = baked[near_i].distance_to(baked[far_i])
		ch["water_half"] = float(spec.get("water_half", 26.0))
		ch["bank"] = float(spec.get("bank", 20.0))
		ch["depth"] = float(spec.get("depth", 13.0))
		ch["reach"] = float(spec.get("reach", 200.0))
		ch["fade"] = float(spec.get("fade", 60.0))
		_channels.append(ch)


## Bucata de sosea dintre indicii `i` si `j` cade in golul unui canal?
##
## Se testeaza pe INDICI, nu pe distante: capetele golului sunt puncte coapte, si
## tot ele sunt punctele pe care se aseaza rampele si pilonii. O a doua definitie
## in metri ar diverge de prima la primul reglaj de traseu si ar lasa ori o buza
## de asfalt in aer, ori o rampa care incepe deasupra apei.
func _road_gap(i: int, j: int = -1) -> bool:
	if _channels.is_empty():
		return false
	var n := baked.size()
	for ch in _channels:
		var span: int = 2 * int(ch["steps"])
		var near_i: int = ch["near"]
		if ((i - near_i) % n + n) % n < span:
			return true
		if j >= 0 and ((j - near_i) % n + n) % n < span:
			return true
	return false


## Cat de mult e indexul „pe pod", in 0..1: 1 deasupra apei, 0 pe uscat.
##
## Umerii de pietris, bordurile si gardul se opresc dupa masura asta, nu dupa
## gol. Un umar de 4 m latime consolat peste senal ar fi fost o buza de nisip
## plutind la 8 m deasupra apei — `_shoulder_width` il calculeaza din panta
## terenului si nu are cum sa stie ca acolo terenul lipseste cu totul.
func _bridge_mix(i: int) -> float:
	if _channels.is_empty():
		return 0.0
	var best := 0.0
	var p := baked[i]
	for ch in _channels:
		var o: Vector3 = ch["origin"]
		var s := absf(Vector2(p.x - o.x, p.z - o.z).dot(ch["across2"] as Vector2))
		var edge: float = float(ch["water_half"]) + float(ch["bank"]) * 0.35
		best = maxf(best, 1.0 - smoothstep(edge - 8.0, edge, s))
	return best

## Inaltimea coroanei soselei (bombarea din centru spre margini).
##
## Plafonul e dat de marcaje: linia de mijloc sta la lift 0.045 si linia de
## start la 0.05 peste cota soselei — o coroana mai inalta de 0.03 le-ar
## strapunge. Daca vrei coroana mai mare, ridica intai lift-urile alea.
const ROAD_CROWN: float = 0.03

## Profilul transversal al soselei, in fractii din half_width.
## 5 pozitii = 4 fasii: destul ca coroana sa prinda lumina continuu si ca
## marginile sa poata purta un gradient de uzura, fara sa umfle geometria.
const ROAD_PROFILE: Array[float] = [-1.0, -0.55, 0.0, 0.55, 1.0]

## Culoarea asfaltului, INAINTE de compensarea trecerii macro. Racoroasa-inchisa
## ca masinile saturate sa "sara" din ecran (style_bible §1: asfaltul e cea mai
## inchisa suprafata continua).
const ROAD_COLOR: Color = Color(0.23, 0.24, 0.3)
## Media texturii macro de asfalt (process_class_textures.surfaces()). Culoarea
## se imparte la ea, ca a doua inmultire sa nu intunece soseaua.
const ASPHALT_MACRO_MEAN: float = 0.900

## Culoarea drumului afanat, INAINTE de compensarea trecerii macro.
##
## ############################################################################
## NISIP BATATORIT, nu laterita rosie — decizia dezvoltatorului dupa prima
## captura de joc, si a doua oara cand nuanta asta se schimba.
##
## Prima versiune a mers pe laterita ("kunigami maaji"), pe argumentul ca un drum
## nisipiu ar disparea in plaja pe care o traverseaza. Argumentul era corect
## pentru plaja si gresit pentru pista: drumul trece prin campul VERDE al insulei
## (inland_tint din tema island), nu prin fasia de nisip, iar rosul iesea maro
## inchis de pamant ud — nu semana cu nimic din lumea din jurul lui.
##
## Tinta e acum EXPLICITA si se poate re-masura: nisipul insorit de pe marginea
## soselei de pe Dunele, adica #D5A75E masurat pe captura de joc (track=0,
## frac=0.21, --gamecam). Nu se poate copia albedo-ul de acolo — Dunele are alta
## lumina (soare 0.8 / expunere 1.30, fata de 1.5 / 1.0 pe insula), deci aceeasi
## culoare de material ar da alt pixel. Se calibreaza pe ECRAN:
##   godot --path . res://tools/Snapshot.tscn -- --track=4 --frac=0.21 --gamecam
## si se compara petecul de drum cu #D5A75E. Masurat la valoarea de mai jos:
## #D8A55E, eroare 3/2/0 pe canale — sub pragul de 12 din style_bible §5.
##
## Ce se pierde, asumat: style_bible §1 cere ca soseaua sa fie cea mai INCHISA
## suprafata continua din cadru, ca linia de curs sa se citeasca la viteza. Un
## drum de nisip pe camp verde e mai LUMINOS decat terenul lui. Linia de curs
## ramane citibila pentru ca separarea nu mai vine din valoare, ci din TON: cald
## saturat pe drum, rece desaturat pe iarba — plus umerii si chevron-urile.
## ############################################################################
const DIRT_ROAD_COLOR: Color = Color(0.80, 0.66, 0.43)
## Media texturii macro de nisip (process_class_textures.surfaces()).
const SAND_MACRO_MEAN: float = 0.850

## Nuanta benzii de rulare pe un drum nepavat.
##
## Gradientul e INVERS fata de asfalt, si asta e chiar diferenta dintre cele
## doua materiale. Pe asfalt marginile sunt mai INCHISE (praf si uzura se aduna
## acolo unde nu calca nimeni); pe nisip, mijlocul e batatorit de roti — mai
## tare, mai umed, mai inchis — iar spre margini ramane praf afanat, deci mai
## deschis. Fara inversarea asta drumul ar fi doar asfalt vopsit in nisipiu.
const DIRT_CENTER_SHADE: Color = Color(0.82, 0.80, 0.78)

func _build_road() -> void:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Fusta soselei peste apa se emite SEPARAT, in beton.
	#
	# Fusta obisnuita e vopsita in `theme_hill_color` — corect cat timp sub drum
	# e mal, absurd pe pod: de pe tarm se vedea o panglica de gazon plutind la
	# 8 m deasupra marii. Un tint pe vertex n-ar fi ajuns (culoarea de material se
	# INMULTESTE, iar din verde nu iese beton), si o cutie construita in hazard
	# nici atat: podul e drept, soseaua nu, deci grinda ii fuge de sub picioare pe
	# 36 m. Aici geometria e deja pe curba — se schimba doar in ce mesh intra.
	var deck_sides := SurfaceTool.new()
	deck_sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Coliziunea NU vine din mesh-ul cambrat: fizica ramane pe fasia plata
	# veche (2 vertecsi transversal), ca feel-ul sa nu se miste deloc.
	# Coroana de 3 cm e vizuala; rotile ruleaza pe planul de dinainte.
	var col := SurfaceTool.new()
	col.begin(Mesh.PRIMITIVE_TRIANGLES)
	var down := Vector3.DOWN * ROAD_THICKNESS
	var n := baked.size()
	# UV-uri PATRATE: acelasi numar de metri pe ambele axe.
	#
	# Inainte U mergea 0..1 de-a latul soselei, adica o repetitie peste toata
	# latimea de 14 m, in timp ce V se repeta la 14 m — textura iesea intinsa
	# 14:1 lateral, deci granulatia aparea ca dungi longitudinale, nu ca pietris.
	var tile := 3.5
	var side_tile := 8.0
	var u_half := half_width / tile
	# Nuanta per pozitie de profil: alb pe banda de rulare, usor inchis spre
	# margini — uzura/praful se aduna la margine, si gradientul face soseaua
	# sa citeasca a suprafata cu latime, nu a panglica uniforma.
	#
	# Pe nisip gradientul se INTOARCE (vezi DIRT_CENTER_SHADE): banda din mijloc
	# e batatorita, deci inchisa, iar praful afanat ramane pe margini. Cele doua
	# nuante se aplica pe acelasi profil de 5 pozitii, deci trecerea dintre ele
	# se interpoleaza pe fasia t = 0.55..1.0 — o poteca cu margini difuze, nu o
	# banda decupata.
	var edge_shade := Color(0.84, 0.84, 0.86)
	var mid_shade := Color.WHITE
	if road_is_loose():
		edge_shade = Color.WHITE
		mid_shade = DIRT_CENTER_SHADE
	for i in n:
		var j := (i + 1) % n
		# Golul canalului: nici asfalt, nici coliziune, nici fusta laterala.
		# Aici se rupe pista in doua si incepe saritura.
		if _road_gap(i):
			continue
		var v0 := _dists[i] / tile
		var v1 := _dists[i + 1] / tile
		var s0v := _side_at(i)
		var s1v := _side_at(j)
		# Inelele profilului la capetele segmentului.
		var ring0: Array[Vector3] = []
		var ring1: Array[Vector3] = []
		for t in ROAD_PROFILE:
			var crown := Vector3.UP * (ROAD_CROWN * (1.0 - t * t))
			ring0.append(baked[i] + s0v * half_width * t + crown)
			ring1.append(baked[j] + s1v * half_width * t + crown)
		for k in ROAD_PROFILE.size() - 1:
			var ta: float = ROAD_PROFILE[k]
			var tb: float = ROAD_PROFILE[k + 1]
			var ca := edge_shade if absf(ta) > 0.99 else mid_shade
			var cb := edge_shade if absf(tb) > 0.99 else mid_shade
			var ua := ta * u_half
			var ub := tb * u_half
			# UV2 din coordonate de LUME, ca la teren: a doua trecere trebuie sa
			# fie CONTINUA cu nisipul de langa ea, nu sa urmareasca panglica.
			# Daca ar merge pe distanta parcursa, peticele s-ar aseza in dungi
			# transversale perfect regulate — exact tiparul pe care il repara.
			var w0 := ring0[k]
			var w1 := ring1[k]
			var w0b := ring0[k + 1]
			var w1b := ring1[k + 1]
			var m0 := Vector2(w0.x, w0.z) * SURFACE_TILING_MACRO
			var m1 := Vector2(w1.x, w1.z) * SURFACE_TILING_MACRO
			var m0b := Vector2(w0b.x, w0b.z) * SURFACE_TILING_MACRO
			var m1b := Vector2(w1b.x, w1b.z) * SURFACE_TILING_MACRO
			# Ordinea l0,l1,r0: fata triunghiului iese IN SUS (vezi istoricul
			# winding-ului — cu ordinea inversa normalele ieseau in jos).
			top.set_color(ca); top.set_uv(Vector2(ua, v0)); top.set_uv2(m0)
			top.add_vertex(w0)
			top.set_color(ca); top.set_uv(Vector2(ua, v1)); top.set_uv2(m1)
			top.add_vertex(w1)
			top.set_color(cb); top.set_uv(Vector2(ub, v0)); top.set_uv2(m0b)
			top.add_vertex(w0b)
			top.set_color(cb); top.set_uv(Vector2(ub, v0)); top.set_uv2(m0b)
			top.add_vertex(w0b)
			top.set_color(ca); top.set_uv(Vector2(ua, v1)); top.set_uv2(m1)
			top.add_vertex(w1)
			top.set_color(cb); top.set_uv(Vector2(ub, v1)); top.set_uv2(m1b)
			top.add_vertex(w1b)
		# Fasia plata de coliziune (geometria veche, 2 vertecsi transversal).
		var l0 := baked[i] - s0v * half_width
		var r0 := baked[i] + s0v * half_width
		var l1 := baked[j] - s1v * half_width
		var r1 := baked[j] + s1v * half_width
		col.add_vertex(l0); col.add_vertex(l1); col.add_vertex(r0)
		col.add_vertex(r0); col.add_vertex(l1); col.add_vertex(r1)
		var u0 := _dists[i] / side_tile
		var u1 := _dists[i + 1] / side_tile
		var skirt := deck_sides if _bridge_mix(i) > 0.5 else sides
		skirt.set_uv(Vector2(u0, 0)); skirt.add_vertex(l0)
		skirt.set_uv(Vector2(u1, 0)); skirt.add_vertex(l1)
		skirt.set_uv(Vector2(u0, 1)); skirt.add_vertex(l0 + down)
		skirt.set_uv(Vector2(u0, 1)); skirt.add_vertex(l0 + down)
		skirt.set_uv(Vector2(u1, 0)); skirt.add_vertex(l1)
		skirt.set_uv(Vector2(u1, 1)); skirt.add_vertex(l1 + down)
		skirt.set_uv(Vector2(u0, 0)); skirt.add_vertex(r0)
		skirt.set_uv(Vector2(u0, 1)); skirt.add_vertex(r0 + down)
		skirt.set_uv(Vector2(u1, 0)); skirt.add_vertex(r1)
		skirt.set_uv(Vector2(u0, 1)); skirt.add_vertex(r0 + down)
		skirt.set_uv(Vector2(u1, 1)); skirt.add_vertex(r1 + down)
		skirt.set_uv(Vector2(u1, 0)); skirt.add_vertex(r1)
		skirt.set_uv(Vector2(u0, 0)); skirt.add_vertex(l0 + down)
		skirt.set_uv(Vector2(u1, 0)); skirt.add_vertex(l1 + down)
		skirt.set_uv(Vector2(u0, 1)); skirt.add_vertex(r0 + down)
		skirt.set_uv(Vector2(u0, 1)); skirt.add_vertex(r0 + down)
		skirt.set_uv(Vector2(u1, 0)); skirt.add_vertex(l1 + down)
		skirt.set_uv(Vector2(u1, 1)); skirt.add_vertex(r1 + down)
	# index() inainte de generate_normals(): fara el, fiecare triunghi isi tine
	# vertecsii lui si normalele se mediaza doar in grupul implicit de netezire;
	# indexat, inelele vecine IMPART vertecsii si lumina curge continuu in lungul
	# soselei in loc sa se rupa in fasii la fiecare 3 m.
	top.index()
	top.generate_normals()
	sides.index()
	sides.generate_normals()
	deck_sides.index()
	deck_sides.generate_normals()
	# Asfaltul racoros-inchis face masinile saturate sa "sara" din ecran, iar
	# granulatia de pietris il scoate din senzatia de plastic turnat. Textura e
	# gri si se inmulteste peste culoare, deci nu schimba paleta.
	# UV-urile soselei sunt patrate (3.5 m pe ambele axe), asa ca pietrisul arata
	# a pietris si nu a dungi intinse.
	#
	# DOUA texturi, doua scari (vezi process_class_textures.surfaces()): agregatul
	# pe UV1 la 3.5 m, peticele si arcele de cauciuc pe UV2 la 45 m. Pana acum
	# soseaua avea o singura trecere, si aia cu o fotografie AERIANA de 30 m
	# stransa la 3.5 m — de aceea masura p25..p75 de 2.76..3.60, adica o panglica
	# aproape fara variatie.
	#
	# Culoarea e IMPARTITA la media trecerii macro (0.900), altfel a doua
	# inmultire ar intuneca soseaua cu 10%. Compensarea sta aici, si nu in media
	# texturii, pentru ca acolo n-ar fi incaput granulatia — vezi nota din
	# surfaces(). Randat, asfaltul iese identic cu inainte; se schimba doar cat
	# de uniform e.
	#
	# Roughness 0.82 + specular 0.3 (style_bible §4): singura suprafata din lume
	# cu un sheen vizibil — o banda discreta de lumina pe asfalt spre soare,
	# ca in Art of Rally. Restul lumii ramane mat (0.15 pe world_material).
	# CULL_BACK: fata soselei e garantat in sus (winding-ul e emis consistent
	# aici), deci nu platim fiecare pixel de doua ori.
	# Impartirea e pe canale, nu pe Color intreg: `Color / float` ar imparti si
	# alfa, si ar iesi 1.11 pe un material opac.
	#
	# DRUMUL NEPAVAT foloseste ACELEASI doua treceri, dar cu texturile de nisip si
	# fara sheen: nisipul batatorit n-are pelicula de bitum care sa prinda lumina,
	# iar specularul de 0.3 pastrat aici l-ar fi facut sa luceasca a asfalt vopsit.
	# Roughness 1.0 + specular 0 il scoate din familia "suprafata neteda".
	# Micro-ul e surface_sand (aceeasi granulatie ca terenul, la 3.5 m in loc de
	# 3.125 — deci si aceeasi lume), macro-ul e surface_sand_macro: petele lui de
	# 45 m sunt exact tiparul de nisip spalat de ploaie pe care il vrem.
	var base := DIRT_ROAD_COLOR if road_is_loose() else ROAD_COLOR
	var macro_mean := SAND_MACRO_MEAN if road_is_loose() else ASPHALT_MACRO_MEAN
	var road_color := Color(
		base.r / macro_mean,
		base.g / macro_mean,
		base.b / macro_mean)
	var micro := "res://assets/textures/surface_asphalt.png"
	var macro := "res://assets/textures/surface_asphalt_macro.png"
	var rough := 0.82
	var spec := 0.3
	if road_is_loose():
		micro = "res://assets/textures/surface_sand.png"
		macro = "res://assets/textures/surface_sand_macro.png"
		rough = 1.0
		spec = 0.0
	_add_mesh_with_collision(top.commit(), road_color,
		_tex(micro), rough, spec,
		BaseMaterial3D.CULL_BACK, col.commit(), _tex(macro))
	_add_mesh_with_collision(sides.commit(), theme_hill_color.darkened(0.2))
	if not _channels.is_empty():
		var deck_mesh := deck_sides.commit()
		if deck_mesh != null and deck_mesh.get_surface_count() > 0:
			_add_mesh_with_collision(deck_mesh, Palette.color(Palette.CONCRETE))

## Cati metri de sosea raman FARA perete de o parte si de alta a unei
## bifurcatii.
##
## Numarul asta a costat o cursa intreaga. Prima varianta n-avea degajare deloc,
## iar peretele de pe marginea soselei trecea drept peste gura scurtaturii: cele
## doua masini care alesesera s-o ia au ramas infipte in el la fractia 0.71, cu
## 29 de izbituri si 4.7 m/s medie pe felia aia, in timp ce masinile care NU o
## luau terminau 2.14 tururi curat. Sonda de cursa a aratat-o imediat; un
## playtest ar fi zis doar "se blocheaza acolo".
##
## 26 m acopera si intrarea, si iesirea, si lasa loc de o linie de apropiere.
const JUNCTION_CLEARANCE_M: float = 26.0

## Indicii de pe bucla principala unde se leaga scurtaturile (intrari + iesiri).
func _junction_indices() -> PackedInt32Array:
	var out := PackedInt32Array()
	var n := baked.size()
	if n == 0:
		return out
	for bi in range(1, routes.size()):
		out.append(int(routes[bi].entry_frac * float(n)) % n)
		out.append(int(routes[bi].exit_frac * float(n)) % n)
	return out


func _near_junction(i: int, junctions: PackedInt32Array, n: int) -> bool:
	if junctions.is_empty():
		return false
	var spacing := _dists[n] / float(n)
	var span := int(JUNCTION_CLEARANCE_M / maxf(spacing, 0.001))
	for j in junctions:
		var d := absi(i - j)
		d = mini(d, n - d) # bucla: si peste linia de start
		if d <= span:
			return true
	return false


## Gardul rosu de pe marginea soselei.
##
## Pe DESERT nu se mai emite deloc: peretii de canion din [TrackCliffs] preiau si
## rolul vizual, si coliziunea. Un gard rosu de 1.3m langa o faleza de 10m arata
## ca o bariera de santier lipita peste peisaj — exact senzatia de "margine
## artificiala" pe care canionul o inlocuieste.
##
## Regula de asezare (exterior mereu, interior doar unde e inaltat) NU dispare —
## s-a mutat in TrackSideSampler.wall_segments(), de unde o citesc si falezele, si
## popicele. O singura definitie, deci nu se pot contrazice.
func _build_walls() -> void:
	if not theme_flag("walls", true):
		return
	var loop_poly := PackedVector2Array()
	for p in _points():
		loop_poly.append(Vector2(p.x, p.z))
	var n := baked.size()
	var junctions := _junction_indices()
	for side_sign: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var emitted := false
		# Peste apa, acelasi perete devine PARAPET DE POD: aceeasi geometrie, alt
		# mesh, alta culoare. Podul isi cere balustrada, dar una construita in
		# hazard ar fi insirata pe axa lui LOCALA — o dreapta — in timp ce soseaua
		# se curbeaza: la 35 m de gol iesise deja de langa drum si plutea peste
		# mare. Aici geometria e a soselei prin constructie, si asta e tot ce
		# trebuia. Pe interiorul buclei peretele oricum nu se emite decat pe
		# portiunile inaltate, deci pe pod parapetul apare exact unde e apa.
		var deck := SurfaceTool.new()
		deck.begin(Mesh.PRIMITIVE_TRIANGLES)
		var deck_emitted := false
		for i in n:
			var j := (i + 1) % n
			if _near_junction(i, junctions, n):
				continue
			if _road_gap(i):
				continue # buza golului: dincolo de ea nu mai e pe ce sa stea
			var b0 := baked[i] + _side_at(i) * half_width * side_sign
			var b1 := baked[j] + _side_at(j) * half_width * side_sign
			var mid := (b0 + b1) * 0.5
			var on_deck := _bridge_mix(i) > 0.5
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(mid.x, mid.z), loop_poly)
			var elevated := mid.y > 1.0
			if not exterior and not elevated and not on_deck:
				continue
			var t0 := b0 + Vector3.UP * WALL_HEIGHT
			var t1 := b1 + Vector3.UP * WALL_HEIGHT
			var into := deck if on_deck else st
			into.add_vertex(b0); into.add_vertex(t0); into.add_vertex(b1)
			into.add_vertex(t0); into.add_vertex(t1); into.add_vertex(b1)
			if on_deck:
				deck_emitted = true
			else:
				emitted = true
		if emitted:
			st.generate_normals()
			# wall_visible = false pastreaza trimesh-ul dar stinge panglica:
			# bariera vizuala devine treaba scenografiei (gard, zid de piatra).
			# Parapetul de pod NU asculta de cheie — balustrada podului e parte
			# din citirea podului, nu o margine artificiala.
			_add_mesh_with_collision(st.commit(), Color(0.9, 0.25, 0.2),
				null, 1.0, 0.5, BaseMaterial3D.CULL_DISABLED, null, null,
				bool(theme_flag("wall_visible", true)))
		if deck_emitted:
			deck.generate_normals()
			_add_mesh_with_collision(deck.commit(),
				Palette.color(Palette.CONCRETE))

## Rampa pe jumatatea exterioara a soselei: alegi intre linia sigura si
## saritura (airtime).
func _build_ramp(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var c := baked[idx]
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var side := _side_at(idx)
	var half_l := 7.0
	var half_w := half_width * 0.5
	var height := 2.6
	var center := c + side * half_width * 0.5
	var fl := center - dir * half_l - side * half_w
	var fr := center - dir * half_l + side * half_w
	var bl := center + dir * half_l - side * half_w + Vector3.UP * height
	var br := center + dir * half_l + side * half_w + Vector3.UP * height
	var bl_low := bl - Vector3.UP * height
	var br_low := br - Vector3.UP * height
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(fl); st.add_vertex(fr); st.add_vertex(bl)
	st.add_vertex(fr); st.add_vertex(br); st.add_vertex(bl)
	st.add_vertex(bl); st.add_vertex(br); st.add_vertex(bl_low)
	st.add_vertex(br); st.add_vertex(br_low); st.add_vertex(bl_low)
	st.add_vertex(fl); st.add_vertex(bl); st.add_vertex(bl_low)
	st.add_vertex(fr); st.add_vertex(br_low); st.add_vertex(br)
	st.generate_normals()
	_add_mesh_with_collision(st.commit(), Color(0.95, 0.6, 0.1))

func _build_hazard(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	# Hazard tematic: in desert, un bolovan desprins din faleza se rostogoleste
	# peste sosea; in rest, excavatorul coboara bratul peste o banda.
	#
	# Pana acum era o MINGE DE PLAJA — ramasita din tema abandonata "jucarii in
	# lada de nisip", intr-un canion de desert.
	var hazard_model: String = theme_flag("hazard_model", "")
	if not hazard_model.is_empty() and ResourceLoader.exists(hazard_model):
		var ball := SlidingHazard.new()
		ball.model_scene = load(hazard_model)
		# 0.52 vine din bolovanul de 5 m diametru -> 2.6 m in joc. O barca de
		# 5 m lungime insa TREBUIE sa ramana de 5 m: la 0.52 ar fi fost o
		# jucarie de 2.6 m tarata peste sosea. De-aia e steag de tema.
		ball.model_scale = float(theme_flag("hazard_scale", 0.52))
		ball.model_tri_class = theme_flag("hazard_class", "")
		ball.model_classes = theme_flag("hazard_classes", {})
		# Doar intentia "se rostogoleste"; raza reala o ia din model. Cu
		# `hazard_roll: false` obiectul doar ALUNECA — o barca targita peste
		# causeway nu se da peste cap.
		ball.roll_radius = 1.0 if bool(theme_flag("hazard_roll", true)) else 0.0
		# Noi ii cerem maturarea maxima; el isi taie cursa cat sa nu iasa din
		# sosea pe latimea ASTA de drum (vezi SlidingHazard._clamp_travel).
		ball.road_half_width = half_width
		ball.phase = fposmod(frac * 3.7, 1.0) # doua obstacole nu bat la unison
		# Cu ce se uita obiectul spre directia in care matura. Fara steag ramane
		# pe axele LUMII, ceea ce e o nepasare acceptabila la o barca targ ita
		# (n-are un "inainte" al ei) si vizibil gresit la un animal: o testoasa
		# care traverseaza mergand cu umarul inainte nu traverseaza, pluteste.
		#
		# Rotatia se pune INAINTE de add_child. `SlidingHazard` e un
		# AnimatableBody3D cu sync_to_physics, deci dupa intrarea in arbore
		# transformul il tine serverul de fizica — iar pozitia se rescrie oricum
		# la fiecare pas, dar BAZA nu, deci o rotatie pusa dupa se pierde tacut.
		if bool(theme_flag("hazard_face_travel", false)):
			ball.rotation = Vector3(0.0, atan2(-side.x, -side.z), 0.0)
		add_child(ball)
		ball.center = p
		ball.travel = side * half_width * 0.9
		ball.global_position = p
	elif ResourceLoader.exists("res://assets/models/vehicles/rusted_digger.glb"):
		_build_excavator(frac)
	else:
		var box := SlidingHazard.new()
		box.road_half_width = half_width
		box.phase = fposmod(frac * 3.7, 1.0)
		add_child(box)
		box.center = p
		box.travel = side * half_width * 0.9
		box.global_position = p

## Caruselul: morisca plantata in mijlocul soselei, cu vane care matura toata
## latimea. Vanele stau sub half_width ca sa nu treaca prin pereti.
##
## ATENTIE la ordine: transformarea se pune INAINTE de add_child. Rotorul e un
## AnimatableBody3D cu sync_to_physics, deci transformarea lui o tine serverul
## de fizica — plasat dupa intrarea in arbore, ramane un pas fizic in origine,
## adica exact peste grila de start, si matura tot plutonul la countdown.
func _build_carousel(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var carousel := CarouselHazard.new()
	carousel.arm_reach = half_width - 0.2
	carousel.position = baked[idx]
	add_child(carousel)

## Bolovan care cade de pe faleza pe o banda a soselei.
##
## Ocupa jumatatea dinspre o margine, nu tot drumul: blocarea completa e treaba
## caruselului, iar aici trebuie sa ramana mereu o linie curata ca sa fie alegere.
## Latura alterneaza determinist cu fractia, ca doua bolovanuri consecutive sa nu
## cada pe aceeasi banda.
func _build_rockfall(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * signf(sin(frac * 17.0))
	var rock := RockfallHazard.new()
	# Defazare din fractie, ca la SlidingHazard: doua bolovanuri nu cad la unison.
	rock.phase = fposmod(frac * 3.7, 1.0)
	add_child(rock)
	# Y de pe SOSEA, nu de pe teren: piatra aterizeaza pe asfalt.
	rock.global_position = p + side * (half_width * 0.45)


## Trecere de cale ferata cu tren.
##
## Doua lucruri se corecteaza singure in loc sa fie scrise de mana in scena, ca
## sa nu se strice la prima modificare de traseu:
##   - trecerea se muta din apexul unui viraj (style_bible §7 cere sa nu pui
##     nimic care blocheaza citirea in apex);
##   - sina se opreste inainte de alta bucla a pistei, altfel un tren de 42 m
##     intra pe soseaua vecina pe o pista care se auto-intersecteaza;
##   - linia ramane ORIZONTALA, la cota drumului, si primeste estacada acolo unde
##     terenul fuge de sub ea (#152). Pana aici era plata prin presupunere, nu
##     prin decizie: mergea cat timp trecerile stateau pe camp, dar peste o rapa
##     de 17 m producea o panglica de traverse plutind in aer.
func _build_train(frac: float) -> void:
	var n := baked.size()
	var idx := _calm_index_near(int(frac * float(n)) % n, 40.0)
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var rail := dir.cross(Vector3.UP).normalized()
	var train := TrainHazard.new()
	train.road_half_width = half_width
	train.half_rail = _rail_reach(p, rail, 90.0, 25.0)
	train.ground_drop = _rail_ground_drop(p, rail, train.half_rail)
	# ATENTIE la ordine: transformarea INAINTE de add_child. Trenul e un
	# AnimatableBody3D cu sync_to_physics, deci transformarea o tine serverul de
	# fizica; pus dupa intrarea in arbore, ramane un pas fizic in origine — adica
	# exact peste grila de start, si matura tot plutonul la countdown.
	# Conventia de orientare din tot proiectul: looking_at(dir) da -Z pe directia
	# de mers si +X pe marginea din dreapta. Sina se construieste de-a lungul lui
	# X local, deci baza se face din DIRECTIA DRUMULUI, ca X sa iasa perpendicular
	# pe el.
	#
	# Prima versiune folosea looking_at(-rail) si punea X pe directia drumului —
	# adica sina mergea PARALEL cu soseaua. Nu se vedea imediat, pentru ca o
	# tangenta la o curba pare ca o traverseaza de doua ori.
	train.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), p)
	add_child(train)


## Podul cu travee ridicatoare peste un canal.
##
## Track calculeaza AICI tot ce tine de traseu si de teren, iar hazardul primeste
## numai numere in spatiul lui local. Aceeasi despartire ca la tren: o scena de
## hazard n-are (si n-ar trebui sa aiba) acces la samplerul pistei, altfel ar
## exista doua raspunsuri la "unde e fundul apei" si al doilea ar ramane in urma.
##
## Baza e facuta din DIRECTIA DRUMULUI, ca la trecerea de cale ferata: -Z local
## iese pe sensul de mers, deci +X local cade pe axa canalului. Golul se intinde
## in lungul lui Z, iar corabiile navigheaza pe X.
func _build_lift_bridge(ch: Dictionary) -> void:
	var origin: Vector3 = ch["origin"]
	var across: Vector3 = ch["across"]
	var bridge := LiftBridgeHazard.new()
	bridge.name = String(ch.get("label", "PodMobil"))
	bridge.road_half_width = half_width
	bridge.gap = float(ch["gap"])
	bridge.channel_reach = float(ch["reach"])
	# Transformarea INAINTE de add_child: traveea e un AnimatableBody3D cu
	# sync_to_physics, iar serverul de fizica ii tine transformarea. Adaugat mai
	# intai in arbore, ar ramane un pas fizic in origine — adica exact peste
	# grila de start (aceeasi capcana ca la carusel si la tren).
	bridge.transform = Transform3D(Basis.looking_at(across, Vector3.UP), origin)
	# Buzele in spatiul podului. NU se presupune ca soseaua e orizontala acolo:
	# pe Okinawa are ~1.7% panta, deci cele doua capete difera cu ~20 cm, si
	# rampa asezata pe o cota medie ar sta cu calcaiul in aer la un capat.
	var inv := bridge.transform.affine_inverse()
	bridge.near_lip = inv * (ch["near_point"] as Vector3)
	bridge.far_lip = inv * (ch["far_point"] as Vector3)
	# Baza e strict un yaw, deci verticala se pastreaza si cota apei se traduce
	# printr-o scadere. (Un `inv * punct` ar fi fost la fel de corect, dar ar fi
	# ascuns faptul ca aici ne bazam pe absenta oricarui tangaj.)
	bridge.water_y = _sampler.mean_road_y() + sea_level_offset - origin.y
	bridge.piers = _channel_piers(ch, bridge.transform.affine_inverse())
	add_child(bridge)


## Unde stau pilonii podului si cat de jos e fundul sub fiecare.
##
## Statiile se aleg PE SOSEA, mergand din punct copt in punct copt pana la
## PIER_STEP metri de precedenta, si abia apoi se trec in spatiul podului. Nu se
## insira pe axa locala a podului: aia e o dreapta, iar soseaua se curbeaza —
## pe Okinawa, la 35 m de gol, un pilon asezat pe axa ar fi iesit de sub drum.
##
## Cotele terenului vin din `ground_y` din acelasi motiv ca la `_rail_ground_drop`:
## e sursa unica pentru tot ce se aseaza pe sol, si sta in sampler.
func _channel_piers(ch: Dictionary, to_local_xf: Transform3D) -> Array[Vector4]:
	var out: Array[Vector4] = []
	var n := baked.size()
	var ci: int = ch["index"]
	var steps: int = ch["steps"]
	var reach := float(ch["water_half"]) + float(ch["bank"]) * 0.5
	var step := LiftBridgeHazard.PIER_STEP
	for dir: int in [-1, 1]:
		# Se pleaca de la BUZA, nu de la mijlocul podului: prima deschidere se
		# masoara de la marginea golului, ca la orice pod.
		var i := ci + dir * steps
		var last := baked[((i % n) + n) % n]
		var total := 0.0
		var since := 0.0
		while total < reach:
			i += dir
			var p := baked[((i % n) + n) % n]
			var seg := p.distance_to(last)
			total += seg
			since += seg
			last = p
			if since < step:
				continue
			since = 0.0
			var drop := p.y - _sampler.ground_y(p.x, p.z)
			var local := to_local_xf * p
			out.append(Vector4(local.x, local.y, local.z, drop))
	return out


## Cat de jos e terenul sub linia ferata, pala cu pala.
##
## Esantionat AICI, nu in hazard: `ground_y` e sursa unica pentru tot ce se
## aseaza pe sol si sta in sampler, iar TrainHazard e o scena de sine statatoare
## care n-are (si n-ar trebui sa aiba) acces la traseu. Aceeasi separare ca la
## `half_rail`, care se calculeaza tot aici.
##
## Pasul e cel al palelor, nu al traverselor: o pala la 7.2 m se sprijina oricum
## pe cota masurata sub ea, iar un profil de 100 de esantioane ar fi 100 de
## apeluri `ground_y` (fiecare o suma ponderata peste traseu) pentru o structura
## de 25 de palei.
func _rail_ground_drop(origin: Vector3, dir: Vector3,
		half_rail_m: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var step := TrainHazard.TRESTLE_BENT_STEP
	var d := -half_rail_m
	while d <= half_rail_m + 0.001:
		var q := origin + dir * d
		out.append(origin.y - _sampler.ground_y(q.x, q.z))
		d += step
	return out


## Cel mai apropiat index cu curbura mica, in raza data. Daca nu exista, il
## intoarce pe cel primit — mai bine o trecere intr-un viraj decat niciuna.
func _calm_index_near(idx: int, radius_m: float) -> int:
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	var steps := int(radius_m / spacing)
	for offset in range(0, steps):
		for sign_i: int in [1, -1]:
			var i := ((idx + offset * sign_i) % n + n) % n
			if _sampler.curvature_at(i) < TrackSideSampler.APEX_CURVATURE:
				return i
	return idx


## Cat de lunga poate fi sina inainte sa dea peste alta bucla a pistei.
##
## Doua praguri, nu unul. Prima versiune lua minimul peste AMBELE directii si
## iesea o sina de 25 m — pe interiorul unei curbe soseaua revine repede, iar
## restrictia de acolo taia si capatul dinspre desertul gol. Acum interiorul e
## limitat separat, iar exteriorul isi ia lungimea intreaga.
##
## MIN_RAIL nu e arbitrar: garnitura MASURATA are 42.3 m (locomotiva + tender +
## 3 vagoane, sonda de geometrie pe train.glb), deci sub atat trenul n-ar avea de
## unde sa intre in cadru. Daca se mai adauga un vagon, cifra asta se verifica din
## nou. Sina e doar geometrie, fara coliziune — daca trece pe langa alta bucla a
## pistei nu strica nimic, doar arata ciudat.
func _rail_reach(origin: Vector3, dir: Vector3, max_len: float,
		clearance: float) -> float:
	const MIN_RAIL := 46.0
	var reach := max_len
	var step := 6.0
	var d := clearance
	while d < max_len:
		for sign_f: float in [1.0, -1.0]:
			var probe := origin + dir * d * sign_f
			if _sampler.clearance_at(probe) < clearance:
				reach = minf(reach, d - step)
		d += step
	return maxf(reach, MIN_RAIL)


## Deviatorul: bariera oblica ancorata pe o margine, care taie drumul in
## diagonala si te trimite pe cealalta banda.
func _build_deflector(frac: float, side_sign: float = 1.0) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var deflector := DeflectorHazard.new()
	deflector.road_half_width = half_width
	deflector.side_sign = side_sign
	# looking_at: -Z pe sensul cursei, deci +X = marginea din dreapta.
	deflector.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), baked[idx])
	add_child(deflector)

## Zona de fly-off: o CREASTA peste toata latimea soselei, pusa inaintea unui
## viraj. Nu are linie sigura — aici sare toata pista, alegerea e cat de tare
## intri: prea incet si doar treci peste, prea tare si zbori pe langa viraj,
## in nisipul de dedesubt (de unde te repune plasa de siguranta).
func _build_flyoff(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var spacing := _dists[n] / float(n)
	var steps := maxi(2, int(FLYOFF_RISE_LEN / spacing))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in steps:
		var i := (idx + k) % n
		var j := (idx + k + 1) % n
		# exponent > 1 = panta creste spre buza (rampa de trambulina, nu cocoas)
		var h0 := FLYOFF_HEIGHT * pow(float(k) / float(steps), 1.35)
		var h1 := FLYOFF_HEIGHT * pow(float(k + 1) / float(steps), 1.35)
		var s0 := _side_at(i) * half_width
		var s1 := _side_at(j) * half_width
		var l0 := baked[i] - s0 + Vector3.UP * h0
		var r0 := baked[i] + s0 + Vector3.UP * h0
		var l1 := baked[j] - s1 + Vector3.UP * h1
		var r1 := baked[j] + s1 + Vector3.UP * h1
		# fata de rulare
		st.add_vertex(l0); st.add_vertex(r0); st.add_vertex(l1)
		st.add_vertex(r0); st.add_vertex(r1); st.add_vertex(l1)
		# flancurile, coborate pe asfalt — altfel creasta se vede pe dedesubt
		for pair: Array in [[l0, l1, -s0, -s1], [r0, r1, s0, s1]]:
			var b0: Vector3 = baked[i] + (pair[2] as Vector3)
			var b1: Vector3 = baked[j] + (pair[3] as Vector3)
			st.add_vertex(pair[0]); st.add_vertex(b0); st.add_vertex(pair[1])
			st.add_vertex(b0); st.add_vertex(b1); st.add_vertex(pair[1])
	# Buza: cadere VERTICALA pana la asfalt, ca la rampele pistei. Cu o
	# coborare lina masina ar ramane lipita de panta (floor snap) si creasta ar
	# fi doar o denivelare — desprinderea trebuie sa fie o muchie.
	var last := (idx + steps) % n
	var sl := _side_at(last) * half_width
	var lip_l := baked[last] - sl
	var lip_r := baked[last] + sl
	var top_l := lip_l + Vector3.UP * FLYOFF_HEIGHT
	var top_r := lip_r + Vector3.UP * FLYOFF_HEIGHT
	st.add_vertex(top_l); st.add_vertex(top_r); st.add_vertex(lip_l)
	st.add_vertex(top_r); st.add_vertex(lip_r); st.add_vertex(lip_l)
	st.generate_normals()
	# Portocaliul rampelor: jucatorul stie deja ca portocaliu = sari.
	_add_mesh_with_collision(st.commit(), Color(0.95, 0.6, 0.1))
	_build_flyoff_kicker(last)
	_build_flyoff_net(idx)

## Cutia de pe buza crestei care da viteza verticala (vezi FlyoffKicker: panta
## singura nu ridica un CharacterBody3D).
func _build_flyoff_kicker(idx: int) -> void:
	var n := baked.size()
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var kicker := FlyoffKicker.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_width * 2.0, 2.6, 3.0)
	shape.shape = box
	kicker.add_child(shape)
	kicker.transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		baked[idx] - dir * 1.2 + Vector3.UP * (FLYOFF_HEIGHT + 0.9))
	add_child(kicker)

## Plasa de siguranta a unei creste: un volum plat de nisip, mult SUB sosea,
## in jurul zonei de aterizare. Plafonul se calculeaza din cea mai joasa
## bucata de sosea aflata in amprenta, minus o marja — asa nu poate prinde pe
## cineva care conduce normal, indiferent de forma pistei.
func _build_flyoff_net(idx: int) -> void:
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	var center := baked[(idx + int(40.0 / spacing)) % n]
	var half_extent := FLYOFF_NET_EXTENT * 0.5
	var lowest_road := 1e9
	for i in n:
		if absf(baked[i].x - center.x) <= half_extent \
				and absf(baked[i].z - center.z) <= half_extent:
			lowest_road = minf(lowest_road, baked[i].y)
	# Relativ la sosea, nu absolut. Cu terenul care urmareste drumul, o podea la
	# -25 fix nu mai inseamna nimic: pe o portiune inaltata plasa ar ramane
	# ingropata sub nisip, iar pe una joasa ar inghiti masini care conduc normal.
	var top := lowest_road - FLYOFF_NET_CEILING_DROP
	var bottom := lowest_road - FLYOFF_NET_FLOOR_DROP
	# Garda de build: un fly-off fara rapa sub el arunca masina pe nisip, iar
	# plasa nu se declanseaza niciodata. Prinde orice pista unde cineva adauga
	# un fly-off si uita rapa.
	if _sampler.max_ravine_depth() <= FLYOFF_NET_CEILING_DROP + 4.0:
		push_warning(("Fly-off la indexul %d fara rapa suficienta: " +
			"plasa de respawn ramane ingropata. Vezi _ravines().") % idx)
	var zone := RespawnZone.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FLYOFF_NET_EXTENT, top - bottom, FLYOFF_NET_EXTENT)
	shape.shape = box
	zone.add_child(shape)
	zone.position = Vector3(center.x, (top + bottom) * 0.5, center.z)
	add_child(zone)

## Materialul flat pentru o culoare (si optional o textura), refolosit intre
## apeluri. Doua mesh-uri de aceeasi culoare = acelasi material = un draw call
## in loc de doua. De aceea variatiile aleatoare de nuanta sunt CUANTIFICATE in
## cateva trepte peste tot: o nuanta continua per instanta ar face cache-ul inutil.
func _flat_material(color: Color, texture: Texture2D = null,
		roughness: float = 1.0, specular: float = 0.5,
		cull: BaseMaterial3D.CullMode = BaseMaterial3D.CULL_DISABLED,
		macro_texture: Texture2D = null) -> StandardMaterial3D:
	var key := "%s|%s|%.2f|%.2f|%d|%s" % [color.to_html(true),
		texture.resource_path if texture != null else "", roughness, specular,
		cull, macro_texture.resource_path if macro_texture != null else ""]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if texture != null:
		mat.albedo_texture = texture
	# A DOUA SCARA, pe UV2 — mecanica pe care terenul o avea de la inceput, iar
	# soseaua nu. O suprafata mare are nevoie de amandoua: granulatia (UV1, o
	# repetitie la ~3.5 m) da materialul sub roti, petele lente (UV2, ~45 m) rup
	# tiparul de repetitie pe care ochiul il prinde imediat pe sute de m².
	# Cele doua se INMULTESC, deci mediile lor se inmultesc si ele — vezi nota
	# despre pastrarea produsului din process_class_textures.surfaces().
	if macro_texture != null:
		mat.detail_enabled = true
		mat.detail_albedo = macro_texture
		mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	mat.roughness = roughness
	mat.metallic_specular = specular
	# Vertex color = AO/gradient copt de builder. Mesh-urile care nu emit COLOR
	# raman pe alb (1,1,1), deci inmultirea e identitate — zero regresie pe
	# apelantii care nu stiu de el.
	mat.vertex_color_use_as_albedo = true
	# CULL_DISABLED ramane default-ul (winding arbitrar pe multe mesh-uri
	# procedurale), dar suprafetele mari cu winding cunoscut (sosea, umeri)
	# cer CULL_BACK: fiecare pixel rasterizat o singura data, nu de doua ori —
	# fill rate-ul e constrangerea reala pe mobil.
	mat.cull_mode = cull
	_mat_cache[key] = mat
	return mat


func _add_mesh_with_collision(mesh: ArrayMesh, color: Color,
		texture: Texture2D = null, roughness: float = 1.0,
		specular: float = 0.5,
		cull: BaseMaterial3D.CullMode = BaseMaterial3D.CULL_DISABLED,
		collision_mesh: ArrayMesh = null,
		macro_texture: Texture2D = null,
		visible_mesh: bool = true) -> void:
	# visible_mesh = false: doar fizica, fara desen. Zidul exterior pe pistele
	# care nu vor panglica vizibila ramane totusi zid — altfel se deschide
	# marginea buclei (pe Okinawa, direct in mare).
	if visible_mesh:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = _flat_material(color, texture, roughness,
			specular, cull, macro_texture)
		add_child(inst)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	# collision_mesh separat cand vizualul nu trebuie sa fie si fizica: soseaua
	# cambrata ruleaza pe fasia plata veche, ca feel-ul sa ramana identic.
	var col_source := collision_mesh if collision_mesh != null else mesh
	var tri := col_source.create_trimesh_shape() as ConcavePolygonShape3D
	# Trimesh-urile sunt implicit UNILATERALE; fara asta masina cade prin
	# asfalt ca printr-o plasa (winding-ul nostru e arbitrar).
	tri.backface_collision = true
	shape.shape = tri
	body.add_child(shape)
	add_child(body)

## Linia de start in sah: doua randuri de patrate alb/negru peste asfalt.
func _build_start_line() -> void:
	var white := SurfaceTool.new()
	white.begin(Mesh.PRIMITIVE_TRIANGLES)
	var black := SurfaceTool.new()
	black.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dir := start_direction()
	var side := _side_at(0)
	var cols := 8
	var cell_w := half_width * 2.0 / float(cols)
	var cell_l := 1.6
	var lift := Vector3.UP * 0.05 # putin peste asfalt, contra z-fighting
	for row in 2:
		for col in cols:
			var origin := baked[0] + lift \
				+ dir * (float(row) * cell_l) \
				+ side * (-half_width + float(col) * cell_w)
			var st := white if (row + col) % 2 == 0 else black
			var a := origin
			var b := origin + side * cell_w
			var c := origin + dir * cell_l
			var d := origin + side * cell_w + dir * cell_l
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
			st.add_vertex(b); st.add_vertex(d); st.add_vertex(c)
	white.generate_normals()
	black.generate_normals()
	_add_visual_mesh(white.commit(), Color(0.95, 0.95, 0.95))
	_add_visual_mesh(black.commit(), Color(0.08, 0.08, 0.08))

## Borduri rosu-alb pe marginile virajelor stranse — citesti pista de departe.
## Latimea MINIMA a benzii de praf dintre asfalt si nisip.
const SHOULDER_WIDTH: float = 1.3

## Panta maxima a umarului, in grade. Peste ea banda se LATESTE pana coboara
## destul de lin.
##
## 25° si nu 45° (unghiul de la care Godot declara un plan "perete"): la limita
## teoretica masina se catara doar cu botul si viteza potrivite, iar o
## reintrare pe drum nu are voie sa fie o manevra de indemanare. Vezi de ce
## exista panta asta in _build_shoulders.
const SHOULDER_MAX_SLOPE_DEG: float = 25.0
## Cat de lat poate ajunge umarul cand nisipul e mult sub asfalt. 4 m acopera si
## treapta cea mai mare masurata pe Dunele (1.1 m pe creasta); dincolo de atat
## nu mai e umar de drum, e rambleu, si atunci e o decizie de pista, nu un racord.
const SHOULDER_MAX_WIDTH: float = 4.0
## Cat de mult trece marginea exterioara a umarului PE SUB teren.
##
## Fara ea, banda si nisipul se termina cap la cap si orice nepotrivire de
## cativa centimetri (coarda umarului e la ~3 m, a terenului la ~8 m) redevine
## un prag. Ingropata, cele doua suprafete se INTERSECTEAZA: masina merge pe cea
## de deasupra, care se schimba continuu, deci nu exista treapta nicaieri.
const SHOULDER_SINK: float = 0.10


## Cati metri de sosea acopera o repetitie a texturii de umar.
##
## 5 m, si numarul asta e o LECTIE DE MIPMAP, nu o preferinta. Prima varianta a
## pus 1.8 m — cat scanarea reala a sursei, deci pietrele la marimea lor
## adevarata. Randat, banda a iesit perfect PLATA, desi sonda de materiale
## confirma si UV-uri corecte (u 0..0.72, v pana la 653) si textura legata.
##
## Cauza: umarul are 1.3 m latime si ocupa ~25 px pe ecran chiar in prim-plan.
## La o repetitie de 1.8 m ii revin ~15 texeli pe pixel, iar GPU-ul alege atunci
## un nivel de mipmap de 32x32 — adica media texturii, adica o culoare plata.
## Soseaua, cu aceleasi UV-uri patrate, se vede pentru ca e de zece ori mai
## lata pe ecran, deci ii revin ~2 texeli pe pixel.
##
## Regula generala de retinut: pe o suprafata INGUSTA, granulatia fina nu ajunge
## niciodata pe ecran, oricat de corecta ar fi textura. Ce supravietuieste e
## variatia de frecventa JOASA — de aia banda primeste si pete pe vertex color
## (SHOULDER_PATCH_*), care nu trec prin mipmap deloc.
const SHOULDER_TILE: float = 5.0

## Cate trepte de nuanta au petele de praf si cat de tare bat.
## Cuantificate, ca sa nu inmulteasca materialele si ca sa citeasca a pete, nu a
## zgomot: doua bucati vecine cad des in aceeasi treapta si formeaza o pata lata.
const SHOULDER_PATCH_STEPS: int = 4
const SHOULDER_PATCH_DEPTH: float = 0.22
## Cati metri tine o pata. 7 m: destul cat sa se citeasca din mers ca petic de
## praf, prea putin cat sa devina o dunga lunga pe toata pista.
const SHOULDER_PATCH_LENGTH: float = 7.0

## Umarul soselei: o banda de praf de o parte si de alta a asfaltului.
##
## In imaginile de referinta asfaltul nu atinge NICIODATA nisipul direct — exista
## mereu o fasie de praf batatorit intre ele. Fara ea, marginea drumului e o
## taietura brusca intre doua culori, si citeste ca decupaj de hartie, nu ca drum
## construit de cineva prin desert.
##
## Banda e si RACORDUL FIZIC dintre asfalt si nisip, nu doar o culoare.
##
## Pana acum statea orizontala, la cota drumului, peste un teren care e cu 30 cm
## mai jos (TrackSideSampler.GROUND_DROP) — deci o clapa care plutea, iar sub ea
## soseaua ramanea un platou cu marginile verticale (fusta de 3 m din
## _build_road, cu coliziune). Un CharacterBody3D cu cutie n-are step-up in
## Godot: orice prag peste ~10 cm e perete. Masurat pe Dunele inainte de
## reparatie, 13 din 16 incercari de reintrare pe sosea esuau — iesisei de pe
## drum si ramaneai afara pana la repunere.
##
## Acum banda coboara de la buza asfaltului pana SUB suprafata reala a terenului
## si se lateste unde e nevoie ca panta sa ramana sub SHOULDER_MAX_SLOPE_DEG.
## Are coliziune proprie, deci e chiar rampa pe care urci inapoi.
func _build_shoulders() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var tile := SHOULDER_TILE
	# Latimea per (punct, latura), coapta INAINTE de emitere: doua segmente
	# vecine trebuie sa foloseasca exact aceeasi valoare in punctul comun, altfel
	# banda se rupe si fisura devine o capcana de coliziune.
	var w_left := PackedFloat32Array()
	var w_right := PackedFloat32Array()
	w_left.resize(n)
	w_right.resize(n)
	for i in n:
		w_left[i] = _shoulder_width(i, -1.0)
		w_right[i] = _shoulder_width(i, 1.0)
	for i in n:
		var j := (i + 1) % n
		# Pe pod nu exista umar de pietris: sub el nu e nisip, e apa. Latimea se
		# stinge treptat pe malul canalului in loc sa se taie brusc, altfel banda
		# s-ar termina cu o buza vizibila exact unde incepe structura.
		if _road_gap(i, j):
			continue
		var bridge := maxf(_bridge_mix(i), _bridge_mix(j))
		var s0 := _side_at(i)
		var s1 := _side_at(j)
		var v0 := _dists[i] / tile
		var v1 := _dists[i + 1] / tile
		for side_sign: float in [-1.0, 1.0]:
			var band := w_left if side_sign < 0.0 else w_right
			var w0 := band[i] * (1.0 - bridge)
			var w1 := band[j] * (1.0 - bridge)
			if w0 < 0.05 and w1 < 0.05:
				continue
			# Buza interioara EXACT la cota asfaltului. Vechii 2 cm de garda
			# contra z-fighting erau inofensivi cat timp banda nu avea coliziune;
			# acum ar fi chiar ei pragul pe care masina nu-l urca. Nu e nevoie de
			# ei: coroana soselei e zero la t = ±1, deci cele doua suprafete se
			# ating pe o muchie comuna, nu se suprapun.
			var inner0 := baked[i] + s0 * half_width * side_sign
			var inner1 := baked[j] + s1 * half_width * side_sign
			var outer0 := inner0 + s0 * w0 * side_sign
			var outer1 := inner1 + s1 * w1 * side_sign
			outer0.y = _terrain_mesh_y(outer0.x, outer0.z) - SHOULDER_SINK
			outer1.y = _terrain_mesh_y(outer1.x, outer1.z) - SHOULDER_SINK
			# U-ul urmeaza latimea REALA, altfel textura se intinde exact acolo
			# unde banda se lateste.
			var u_shoulder := maxf(w0, w1) / tile
			# Gradient de vertex color: mai INCHIS la contactul cu asfaltul
			# (praful batatorit de lansat rotile), plin spre nisip. Face umarul
			# sa citeasca a tranzitie de material, nu a banda decupata.
			const INNER_SHADE := Color(0.82, 0.82, 0.84)
			# Peste gradient, petele de praf: singura variatie a umarului care
			# ajunge sigur pe ecran, fiindca nu trece prin mipmap (vezi nota de
			# la SHOULDER_TILE). Se calculeaza din distanta parcursa, deci
			# capatul unui segment si inceputul urmatorului dau aceeasi valoare
			# si banda nu se rupe.
			var p0 := _shoulder_patch(i, side_sign)
			var p1 := _shoulder_patch(j, side_sign)
			var in_c0 := INNER_SHADE * p0
			var in_c1 := INNER_SHADE * p1
			var out_c0 := Color(p0, p0, p0)
			var out_c1 := Color(p1, p1, p1)
			# Winding-ul se inverseaza cu latura, altfel una din benzi iese cu
			# fata in jos si dispare la cull.
			var uo := u_shoulder
			if side_sign < 0.0:
				st.set_color(in_c0)
				st.set_uv(Vector2(0, v0)); st.add_vertex(inner0)
				st.set_color(out_c0)
				st.set_uv(Vector2(uo, v0)); st.add_vertex(outer0)
				st.set_color(in_c1)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
				st.set_color(out_c0)
				st.set_uv(Vector2(uo, v0)); st.add_vertex(outer0)
				st.set_color(out_c1)
				st.set_uv(Vector2(uo, v1)); st.add_vertex(outer1)
				st.set_color(in_c1)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
			else:
				st.set_color(in_c0)
				st.set_uv(Vector2(0, v0)); st.add_vertex(inner0)
				st.set_color(in_c1)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
				st.set_color(out_c0)
				st.set_uv(Vector2(uo, v0)); st.add_vertex(outer0)
				st.set_color(out_c0)
				st.set_uv(Vector2(uo, v0)); st.add_vertex(outer0)
				st.set_color(in_c1)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
				st.set_color(out_c1)
				st.set_uv(Vector2(uo, v1)); st.add_vertex(outer1)
	st.index()
	st.generate_normals()
	# Praf: intre asfalt si nisip ca valoare, ca sa faca tranzitia, nu un al
	# treilea ton care sa sara in ochi.
	var dust_override: Variant = theme_flag("dust_color")
	var dust: Color = dust_override if dust_override != null \
		else theme_ground_tint.darkened(0.25)
	# Winding-ul e tinut corect pe ambele laturi (vezi mai sus), deci umerii
	# suporta CULL_BACK — banda care margineste toata pista nu se mai
	# rasterizeaza pe ambele fete.
	# PIETRIS, nu nisip. Umarul are alt material decat terenul de langa el —
	# praf batatorit cu pietre iesite din el, cum se vede in orice fotografie de
	# drum de desert. Cat timp imprumuta textura nisipului, singura lui
	# diferenta fata de teren era culoarea, si banda citea ca vopsea.
	#
	# CU COLIZIUNE: banda e rampa de reintrare pe sosea, nu doar o culoare.
	_add_mesh_with_collision(st.commit(), dust,
		_tex("res://assets/textures/surface_gravel.png"), 1.0, 0.5,
		BaseMaterial3D.CULL_BACK)


## Cat de lat trebuie sa fie umarul intr-un punct ca panta lui sa ramana sub
## SHOULDER_MAX_SLOPE_DEG.
##
## Se masoara intai cu latimea minima, apoi se corecteaza — o singura iteratie,
## nu o cautare: terenul se schimba lent pe cativa metri, deci a doua estimare a
## caderii e deja buna, iar diferenta ramasa o inghite marja dintre 25° si cele
## 45° de la care panta ar deveni perete.
##
## Pe o RAPA declarata banda nu se lateste deloc. Acolo prapastia e chiar
## subiectul: rapa exista tocmai ca terenul care urmareste soseaua sa NU umple
## golul in care e gandita drama fly-off-ului (vezi _ravines()). Un rambleu de
## 4 m pe buza ei ar da inapoi exact ce sapa ea — asa ca acolo ramane muchie, si
## din rapa iesi cum ai iesit mereu: cu repunerea.
func _shoulder_width(i: int, side_sign: float) -> float:
	var frac := _dists[i] / _dists[baked.size()] if _dists[baked.size()] > 0.0 else 0.0
	if _sampler.ravine_at(frac, side_sign):
		return SHOULDER_WIDTH
	var base: Vector3 = baked[i]
	var lat := _side_at(i) * side_sign
	var max_tan := tan(deg_to_rad(SHOULDER_MAX_SLOPE_DEG))
	var w := SHOULDER_WIDTH
	for _pass in 2:
		var p := base + lat * (half_width + w)
		var drop := base.y - _terrain_mesh_y(p.x, p.z) + SHOULDER_SINK
		w = clampf(drop / max_tan, SHOULDER_WIDTH, SHOULDER_MAX_WIDTH)
	return w


## Nuanta petei de praf la un indice de pe traseu, ca factor in jurul lui 1.0.
##
## CENTRATA pe 1.0 (de aici `- 0.5`), nu doar intunecatoare: o pata care numai
## scade ar cobori luminozitatea medie a benzii cu jumatate din amplitudine si
## ar strica expunerea umarului fara ca nimeni sa observe de ce.
##
## Numarul de pete se calculeaza din lungimea REALA a pistei si se foloseste
## modulo, ca pata de la kilometrul zero sa fie aceeasi cu cea de dinaintea
## liniei de start. Fara asta, bucla ar avea o cusatura vizibila intr-un singur
## loc — genul de artefact care se vede o data la trei tururi si nu se explica.
func _shoulder_patch(idx: int, side_sign: float) -> float:
	var total: float = _dists[_dists.size() - 1]
	var buckets := maxi(1, int(round(total / SHOULDER_PATCH_LENGTH)))
	var t := _dists[idx] / total * float(buckets)
	var b := floori(t)
	var f := smoothstep(0.0, 1.0, t - float(b))
	var a := _patch_step(b % buckets, side_sign)
	var c := _patch_step((b + 1) % buckets, side_sign)
	return 1.0 + SHOULDER_PATCH_DEPTH * (lerpf(a, c, f) - 0.5)


## Treapta de nuanta a unei pete — hash determinist din indice, nu rng.
## Un artefact nu are voie sa se schimbe fiindca altul de langa el a consumat
## extrageri (aceeasi regula ca in generate_palette_atlas).
func _patch_step(bucket: int, side_sign: float) -> float:
	var h := (bucket * 374761393) ^ (int(side_sign + 2.0) * 668265263)
	h = (h ^ (h >> 13)) * 1274126177
	var v := float((h ^ (h >> 16)) & 0xFFFF) / 65535.0
	return floorf(v * float(SHOULDER_PATCH_STEPS)) \
		/ float(SHOULDER_PATCH_STEPS - 1)


## Urme de cauciucuri pe linia de curse — decal-uri de geometrie (val 4c).
##
## Trucul de sol al BBR2: urmele pictate pe traseu spun "pe aici se merge" si
## rup uniformitatea asfaltului exact unde se uita jucatorul. Fasiile stau la
## +0.025 m peste asfalt (sub linia de mijloc, 0.045) si folosesc SINGURA
## textura cu alpha real din lume (decal_tracks.png) — suprafata acoperita e
## deliberat mica: doua fasii de 0.34 m pe zonele de viraj + franare, nu covor.
##
## Urmele se aseaza pe INTERIORUL virajului (linia de apex), decalate spre
## inainte ca sa acopere si franarea. Alpha-ul creste/scade la capetele
## fiecarei serii prin vertex color — urmele apar si dispar gradual, nu taiat.
##
## ############################################################################
## PE DRUM AFANAT (road_is_loose) NU SE COACE NIMIC. Nici o urma, nici o poteca.
##
## Versiunea de dinainte facea invers: pe drumul nepavat intindea o poteca pe
## TOT turul, ca semn ca pe acolo circula lume. Ca imagine statica era corect; in
## joc, prima reactie a fost "urmele astea nu-s ale nimanui". Si chiar nu erau:
## pista se nastea cu doua dare desenate pe ea, identice tur de tur, indiferent
## pe unde treceai tu sau AI-ul. Pe o suprafata pe care masinile lasa urme REALE
## in fiecare cadru (SandTrail, depusa cat timp rulezi), o urma coapta nu se
## adauga la ele — le contrazice: cea coapta nu se schimba niciodata, deci o
## recunosti ca decor imediat ce ai vazut-o de doua ori.
##
## Pe asfalt urmele coapte raman, si nu e o inconsecventa: acolo masinile lasa
## urme doar cand DERAPEAZA (Car._drop_skid_marks), si alea se sting. Fara stratul
## copt, virajele ar fi curate ca in ziua turnarii asfaltului. Regula, pe scurt:
## coci ce masinile nu pot produce, si lasa in seama lor ce pot.
## ############################################################################
## Jumatatea de latime a unei fasii de urma si ecartamentul lor, in metri:
## latimea anvelopei si distanta dintre roti.
const TIRE_HALF_W: float = 0.17
const TIRE_GAUGE: float = 0.85
## Cati metri de drum acopera o repetitie a texturii de urma, pe lungime.
const TIRE_TILE: float = 1.4

func _build_tire_marks() -> void:
	# Vezi antetul: pe suprafata afanata urmele sunt treaba masinilor.
	if road_is_loose():
		return
	var n := baked.size()
	if n < 20:
		return
	# 1. Ce indecsi primesc urme: virajele reale + 10 pasi de franare inainte.
	var strength: Array[float] = []
	strength.resize(n)
	var offset_sign: Array[float] = []
	offset_sign.resize(n)
	for i in n:
		var before := (baked[i] - baked[(i - 3 + n) % n]).normalized()
		var after := (baked[(i + 3) % n] - baked[i]).normalized()
		if before.angle_to(after) < 0.10:
			continue
		var turn := signf(before.cross(after).y)
		for k in range(-10, 5):
			var idx := (i + k + n) % n
			strength[idx] = 1.0
			offset_sign[idx] = turn
	# 2. Rampa de alpha la capete: 4 pasi de aparitie/disparitie.
	var alpha: Array[float] = []
	alpha.resize(n)
	for i in n:
		if strength[i] <= 0.0:
			continue
		var run_in := 0
		while run_in < 4 and strength[(i - run_in - 1 + n) % n] > 0.0:
			run_in += 1
		var run_out := 0
		while run_out < 4 and strength[(i + run_out + 1) % n] > 0.0:
			run_out += 1
		alpha[i] = minf(float(mini(run_in, run_out) + 1) / 4.0, 1.0)
	# 3. Geometria: doua fasii (ecartamentul rotilor) pe linia de apex.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Peste COROANA, nu peste cota axei. Cei 0.025 m de dinainte erau masurati
	# fata de curba soselei, iar bombarea o ridica pe sub ei cu pana la 0.03 —
	# adica exact pe banda de rulare, unde stau urmele, asfaltul trecea PESTE
	# decal si le ingropa. Fasiile erau in scena, in numaratoarea de triunghiuri,
	# si invizibile de cand exista coroana. Ramane loc sub linia de mijloc (0.045).
	var lift := Vector3.UP * (ROAD_CROWN + 0.008)
	var emitted := false
	for i in n:
		var j := (i + 1) % n
		if alpha[i] <= 0.0 and alpha[j] <= 0.0:
			continue
		if _road_gap(i, j):
			continue
		# Linia de apex: spre interiorul virajului, nu pe axa drumului.
		var lane0 := -offset_sign[i] * half_width * 0.35
		var lane1 := -offset_sign[j] * half_width * 0.35
		var v0 := _dists[i] / TIRE_TILE
		var v1 := _dists[i + 1] / TIRE_TILE
		for wheel: float in [-TIRE_GAUGE, TIRE_GAUGE]:
			var c0 := baked[i] + _side_at(i) * (lane0 + wheel) + lift
			var c1 := baked[j] + _side_at(j) * (lane1 + wheel) + lift
			# Forma urmei — clopotul care o stinge spre margini — vine din ALFA
			# TEXTURII; vertex color-ul poarta doar rampa de la capetele seriei.
			var half := _side_at(i) * TIRE_HALF_W
			var col0 := Color(1, 1, 1, alpha[i])
			var col1 := Color(1, 1, 1, alpha[j])
			st.set_color(col0)
			st.set_uv(Vector2(0.0, v0)); st.add_vertex(c0 - half)
			st.set_color(col1)
			st.set_uv(Vector2(0.0, v1)); st.add_vertex(c1 - half)
			st.set_color(col0)
			st.set_uv(Vector2(1.0, v0)); st.add_vertex(c0 + half)
			st.set_color(col0)
			st.set_uv(Vector2(1.0, v0)); st.add_vertex(c0 + half)
			st.set_color(col1)
			st.set_uv(Vector2(0.0, v1)); st.add_vertex(c1 - half)
			st.set_color(col1)
			st.set_uv(Vector2(1.0, v1)); st.add_vertex(c1 + half)
			emitted = true
	if not emitted:
		return
	# Fara normale, materialul (care e luminat per pixel) primea vectorul nul si
	# fasiile se colorau doar din ambianta — inca un motiv pentru care nu se
	# vedeau. Sunt plane orizontale, deci normalele ies toate in sus si costa un
	# singur pas de generare la construirea pistei.
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.name = "TireMarks"
	inst.mesh = st.commit()
	inst.material_override = _decal_material()
	add_child(inst)


## Materialul decal-urilor — UNUL singur, cache-uit. Transparenta alpha e
## costul pe care garda nu-l masoara (vezi water.gdshader), deci sta izolata
## aici, pe o suprafata totala de cativa zeci de m².
var _decal_mat: StandardMaterial3D

func _decal_material() -> StandardMaterial3D:
	if _decal_mat != null:
		return _decal_mat
	_decal_mat = StandardMaterial3D.new()
	_decal_mat.albedo_texture = _tex("res://assets/textures/decal_tracks.png")
	_decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_decal_mat.vertex_color_use_as_albedo = true # rampa de alpha la capete
	_decal_mat.roughness = 1.0
	_decal_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_decal_mat.cull_mode = BaseMaterial3D.CULL_BACK
	return _decal_mat


## Latimea benzii de bordura, in metri.
const KERB_WIDTH: float = 0.9
## O repetitie de textura la 3.5 m. Nu 1.2 (scara reala a petelor din beton):
## bordura e o banda de 0.9 m, deci si mai ingusta pe ecran decat umarul, si
## cade in aceeasi capcana de mipmap — vezi nota de la SHOULDER_TILE. La 3.5 m
## pata de beton e mai mare decat adevarul, dar se VEDE, si asta e tot rostul ei.
const KERB_TILE: float = 3.5

## Cat de tare variaza uzura de la o bucata de bordura la alta (factor in jurul
## lui 1.0). Bordurile sunt turnate si vopsite bucata cu bucata, deci decolorarea
## e per bucata, nu continua — variatia asta e geometrica, deci supravietuieste
## mipmap-ului acolo unde textura nu.
const KERB_WEAR_DEPTH: float = 0.14

## AO discret pe muchia dinspre exterior: bordura citeste a beton turnat cu
## grosime, nu a banda de plastic lipita pe asfalt.
const KERB_EDGE_SHADE: Color = Color(0.86, 0.86, 0.86)

## Culorile bordurii, IMPARTITE la media texturii de uzura (0.940, vezi
## process_class_textures.surfaces()). Textura se inmulteste peste ele, deci fara
## corectia asta benzile ar iesi cu 6% mai inchise si si-ar pierde din rolul de
## "citesti virajul de departe". Asa se schimba doar uniformitatea lor.
const KERB_RED: Color = Color(0.904, 0.160, 0.106)
const KERB_WHITE: Color = Color(0.979, 0.979, 0.979)

## Bordurile rosu-alb de pe marginile virajelor stranse.
##
## UN SINGUR mesh pentru amandoua culorile, nu doua: culoarea vine acum din
## vertex color, iar materialul e comun. Inainte erau doua materiale (rosu plat
## si alb plat) fara nicio textura pe ele — singurele suprafete mari din cadru
## ramase pe culoare pura, si se vedea. Acum sunt un material texturat, deci si
## garda de draw call-uri scade cu unu.
##
## Amplasarea NU s-a schimbat: bordurile stau tot doar pe virajele reale
## (curbura peste 0.08 rad). Nu sunt decor, sunt SEMNAL — daca ar margini toata
## pista, n-ar mai spune nimic despre unde se franeaza.
func _build_kerbs() -> void:
	# Un drum de nisip n-are borduri turnate. Semnalul lor — "aici se franeaza",
	# citit de departe — NU se pierde: pe virajele aceleiasi piste raman
	# chevron-urile (_build_chevrons), umarul de pietris (_build_shoulders) si,
	# de acum, poteca batatorita care se muta spre interiorul virajului
	# (_build_tire_marks). Trei semnale geometrice in loc de unul pictat.
	if road_is_loose():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var lift := Vector3.UP * 0.04
	var u_in := KERB_WIDTH / KERB_TILE
	var emitted := false
	for i in range(0, n, 2):
		# curbura locala: unghiul dintre directia dinainte si cea de dupa
		var before := (baked[i] - baked[(i - 3 + n) % n]).normalized()
		var after := (baked[(i + 3) % n] - baked[i]).normalized()
		if before.angle_to(after) < 0.08:
			continue
		var j := (i + 2) % n
		if _road_gap(i, j):
			continue
		var v0 := _dists[i] / KERB_TILE
		var v1 := _dists[mini(i + 2, n)] / KERB_TILE
		var block := i / 2
		var wear := 1.0 + KERB_WEAR_DEPTH * (_patch_step(block, 1.0) - 0.5)
		var tint := (KERB_RED if block % 2 == 0 else KERB_WHITE) * wear
		var edge := tint * KERB_EDGE_SHADE
		for side_sign: float in [-1.0, 1.0]:
			var e0 := baked[i] + _side_at(i) * half_width * side_sign + lift
			var e1 := baked[j] + _side_at(j) * half_width * side_sign + lift
			var in0 := e0 - _side_at(i) * KERB_WIDTH * side_sign
			var in1 := e1 - _side_at(j) * KERB_WIDTH * side_sign
			st.set_color(edge)
			st.set_uv(Vector2(0.0, v0)); st.add_vertex(e0)
			st.set_uv(Vector2(0.0, v1)); st.add_vertex(e1)
			st.set_color(tint)
			st.set_uv(Vector2(u_in, v0)); st.add_vertex(in0)
			st.set_uv(Vector2(u_in, v0)); st.add_vertex(in0)
			st.set_color(edge)
			st.set_uv(Vector2(0.0, v1)); st.add_vertex(e1)
			st.set_color(tint)
			st.set_uv(Vector2(u_in, v1)); st.add_vertex(in1)
			emitted = true
	if not emitted:
		return
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.name = "Kerbs"
	inst.mesh = st.commit()
	# albedo ALB: culoarea vine din vertex color, textura o moduleaza. Aceeasi
	# mecanica ca la teren si din acelasi motiv — orice culoare pusa aici s-ar
	# inmulti peste rosu si l-ar impinge in saturatie, unde uzura dispare.
	inst.material_override = _flat_material(Color.WHITE,
		_tex("res://assets/textures/surface_kerb.png"), 0.9, 0.3)
	add_child(inst)

## Lumea din jurul soselei: peretii de canion si decorul imprastiat.
##
## Amandoua traiesc in fisiere separate ([TrackCliffs], [TrackDecor]) si cer
## sloturi de la [member _sampler]. Motivul e la fel de mult organizatoric cat
## tehnic: track.gd e fisierul pe care il atinge toata lumea, iar decorul e
## partea care se itereaza cel mai des.
## Radacinile decorului generat (faleze + scatter), tinute minte ca chevron-urile
## sa poata intreba "e ceva mare aici?" fara sa scaneze toata scena.
var _decor_roots: Array[Node3D] = []


func _build_world_decor() -> void:
	_decor_roots.clear()
	var cliffs := TrackCliffs.build(_sampler, theme_flag("cliffs", false),
		_world_seed(), _cliff_clearings(), _gorge_ranges())
	add_child(cliffs)
	_decor_roots.append(cliffs)
	# Decorul primeste amprentele falezelor deja asezate. De asta ordinea celor
	# doua apeluri nu mai e doar o conventie: falezele TREBUIE construite intai.
	var decor := TrackDecor.build(_sampler, theme_flag("decor", "scatter"),
		_world_seed(), Callable(self, "_flat_material"),
		theme_flag("props", "desert"),
		cliffs.get_meta(TrackCliffs.FOOTPRINT_META, []) as Array)
	add_child(decor)
	_decor_roots.append(decor)
	# Scenografia DUPA benzile statistice, si tot in `_decor_roots`: semnele
	# chevron si gardurile isi cauta loc liber printre obstacolele de acolo, iar
	# un tetrapod sau un zid de cetate e cel putin la fel de solid ca o stanca.
	var scen := TrackScenography.build(_sampler, _scenography(), _world_seed(),
		_sampler.mean_road_y() + sea_level_offset)
	add_child(scen)
	_decor_roots.append(scen)
	_bake_decor(cliffs, decor, scen)


## Coace vizualul falezelor si al decorului in MultiMesh-uri.
##
## Aici, si nu in cei doi constructori, fiindca decizia e una de POLITICA a
## pistei, nu de continut: amandoi produc noduri, iar daca maine mai apare un
## generator de decor va trebui copt la fel, din acelasi loc. Tot de aici vine
## si portita `--no-batch`, care exista ca sondele sa poata masura A/B pe
## aceeasi build (tools/ProbeFrame.tscn).
##
## Scenografia intra si ea, desi prima intentie a fost s-o las pe dinafara —
## "piese putine si mari, castig mic". Masuratoarea a contrazis intentia: pe
## Okinawa manual sunt 524 de piese si ele sunt costul dominant al pistei, nu
## decorul. O piesa cu parti pe clase de material diferite nu e o problema
## pentru coacere: fiecare parte isi are grupul ei, fiindca cheia contine si
## materialul.
##
## ORDINEA CONTEAZA: chevron-urile si gardul se aseaza dupa `_build_world_decor`
## si isi cauta loc liber cu `_collect_obstacles`. Daca coacerea s-ar face dupa
## ei, ar cauta printre noduri care intre timp au disparut in buffere.
func _bake_decor(cliffs: Node3D, decor: Node3D, scen: Node3D) -> void:
	if OS.get_cmdline_user_args().has("--no-batch"):
		return
	TrackDecorBatch.bake(cliffs)
	TrackDecorBatch.bake(decor, decor.get_node_or_null(^"Sway") as SwayDriver)
	TrackDecorBatch.bake(scen)

func _build_excavator(frac: float) -> void:
	const PATH := "res://assets/models/vehicles/rusted_digger.glb"
	if not ResourceLoader.exists(PATH):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var excavator := ExcavatorHazard.new()
	# Era un excavator de PLASTIC din tema "lada de nisip". Cel nou e construit
	# la scara lumii — corpul lui de 3.73 m e practic cat cel vechi inmultit cu
	# 0.75, deci scara devine 1.0 si colizoarele se recalibreaza in hazard.
	excavator.model_scene = load(PATH)
	excavator.model_scale = 1.0
	add_child(excavator)
	# Corpul sta PE marginea soselei (blocheaza banda exterioara),
	# bratul coboara spre centru — lasa o strecuratoare pe interior.
	var park := p + side * (half_width * 0.8)
	excavator.look_at_from_position(park, p, Vector3.UP) # bratul spre drum

## Dinozaurul de plastic: landmark care "priveste" cursa de pe margine.
func _build_dino(frac: float, side_sign: float) -> void:
	const PATH := "res://assets/models/props/dino_bones.glb"
	if not ResourceLoader.exists(PATH):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * side_sign
	var dino := StaticBody3D.new()
	dino.add_to_group("dinos")
	# Era un dinozaur de PLASTIC din tema "lada de nisip". Acum e un schelet
	# fosilizat partial dezgropat — acelasi rol de reper, dar unul dintre cele
	# mai puternice clisee vizuale ale desertului american.
	var scene := load(PATH) as PackedScene
	var model := _extract_glb_node(scene, "Dino_Skeleton")
	if model == null:
		return
	var aabb := model_aabb(model)
	dino.add_child(model)
	Palette.apply_world_material(model)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	# Inaltimea masurata; raza din amprenta pe X, NU din diagonala — silueta are
	# coada lunga (9 m pe Z la modelul actual), iar un cilindru care s-o acopere
	# ar fi un gard invizibil de 4.5 m raza langa sosea.
	cyl.radius = maxf(aabb.size.x * 0.5, 0.5)
	cyl.height = maxf(aabb.size.y, 0.5)
	shape.shape = cyl
	shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
	dino.add_child(shape)
	add_child(dino)
	# 12 m de la marginea asfaltului, nu 6: la 6 statea in banda in care
	# TrackCliffs ridica peretii (OFFSET_OUTER 1.2 .. CORNER 5.0) si silueta
	# s-ar fi pierdut in stanca. Un sit de sapaturi nu sta oricum pe acostament.
	var stand := p + side * (half_width + 12.0)
	# Chiar la nivelul solului, nu la cota drumului. Comentariul de aici spunea
	# deja "la nivelul solului", dar terenul nu-l onora: statea la o cota fixa in
	# lume, deci pe portiunile inaltate landmark-ul ramanea suspendat in aer.
	stand.y = _sampler.ground_y(stand.x, stand.z)
	dino.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)
	_scatter_bones(scene, stand, frac)


## Oase razlete in jurul scheletului. Fara ele, un schelet singur pe nisip
## citeste ca o statuie; cu ele, locul citeste ca un SIT — si asta e diferenta
## dintre un obiect si un moment de pe tur. Costa 24-36 de triunghiuri bucata.
func _scatter_bones(scene: PackedScene, center: Vector3, frac: float) -> void:
	const PICKS := ["Bone_A", "Bone_B", "Bone_C"]
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed() + int(frac * 1000.0)
	for i in range(7):
		var bone := _extract_glb_node(scene, PICKS[rng.randi_range(0, 2)])
		if bone == null:
			continue
		# Inel in jurul scheletului, nu peste el: sub 6 m ar intra in coaste.
		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(6.0, 16.0)
		var spot := center + Vector3(cos(ang), 0.0, sin(ang)) * dist
		spot.y = _sampler.ground_y(spot.x, spot.z) - 0.08 # putin ingropate
		add_child(bone)
		Palette.apply_world_material(bone)
		bone.global_position = spot
		bone.rotation = Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(0.0,
			TAU), rng.randf_range(-0.25, 0.25))

## Arcada de stanca peste sosea — singurul landmark prin care TRECI, nu pe
## langa care treci.
##
## Nu poate merge prin _LANDMARKS din doua motive: alea se aseaza lateral, la
## `half_width + gap`, iar asta straddleaza drumul; si coliziunea nu poate veni
## din AABB, fiindca AABB-ul unei arcade include golul si ar zidi soseaua.
## Proxy-urile `Arch_L_col` / `Arch_R_col` din GLB sunt raspunsul — aceeasi
## conventie ca la cliff_wall. Traversa NU primeste coliziune: nicio masina
## n-ar trebui s-o atinga, iar o forma concava acolo e o capcana.
func _build_arch(frac: float) -> void:
	const PATH := "res://assets/models/rocks/rock_arch.glb"
	if not ResourceLoader.exists(PATH):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var body := StaticBody3D.new()
	body.add_to_group("arches")
	var model := (load(PATH) as PackedScene).instantiate() as Node3D
	# Proxy-urile de coliziune ies din arborele vizual si devin cutii.
	for child in model.get_children():
		var nm := String(child.name)
		if not nm.ends_with("_col"):
			continue
		var mi := child as MeshInstance3D
		model.remove_child(child)
		if mi != null and mi.mesh != null:
			var aabb := mi.mesh.get_aabb()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = aabb.size
			shape.shape = box
			shape.position = mi.position + aabb.position + aabb.size * 0.5
			body.add_child(shape)
		child.queue_free()
	body.add_child(model)
	add_child(body)
	# Arcada e integral roca — primeste trim sheet-ul de clasa.
	Palette.apply_rock_material(model)
	var stand := p
	stand.y = _sampler.ground_y(p.x, p.z)
	body.global_position = stand
	# Deschiderea arcadei e pe X-ul modelului, deci privirea se aliniaza cu
	# directia de mers: soseaua trece prin gol, nu pe langa un picior.
	body.global_basis = Basis.looking_at(dir, Vector3.UP)


## Clasele de suprafata ale portalului de mina (#130). Prefixele sunt numele
## pieselor din GLB; "tri:" = proiectie triplanara in spatiul lumii, ca movila
## sa-si continue straturile in faleza de care se sprijina.
## Ce nu apare aici (Portal_Trim, MineCart_Trim) cade pe atlas: gura minei
## traieste din intuneric plat, iar minereul din culoarea de material desfacut.
## Id-uri de sonda pentru prop-urile hero care NU sunt in `_LANDMARKS`. Stau
## peste intervalul tabelului ca sa nu se ciocneasca de el.
const SHOT_MINE: int = 20

## Clasele de suprafata ale lui props_junk.glb (butoaie, lazi, cauciucuri).
##
## Constanta exista INAINTE de consumatorul ei, si intentionat: din #131
## butoaiele si lazile au UV-uri REALE (se misca — sunt bump-abile — deci
## triplanarul de lume le-ar face textura sa inoate). Cine le pune pe pista
## (issue #7) TREBUIE sa treaca prin `Palette.apply_class_materials` cu maparea
## asta. Cu `apply_world_material`, atlasul citit pe UV-uri reale ar matura
## toata paleta si un butoi ar iesi in dungi, inclusiv prin sloturile magenta.
## Cauciucurile lipsesc din tabel deliberat: negrul curat E cauciucul.
const PROPS_JUNK_CLASSES := {
	"Barrel_": "rust_metal",
	"Crate_": "wood",
}

const _MINE_CLASSES := {
	"Portal_Rock": "tri:rock",
	"Portal_Wood": "wood",
	"MineRail_Wood": "wood", "MineRail_Metal": "rust_metal",
	"MineCart_Wood": "wood", "MineCart_Metal": "rust_metal",
}

## Intrare de mina lipita de peretele de faleza, cu sina si vagonet asezate
## separat — de aia sunt trei GRUPURI in GLB si nu unul. Din #130 fiecare grup
## e la randul lui spart pe clase de material, deci se extrag dupa PREFIX.
func _build_mine(frac: float, side_sign: float) -> void:
	const PATH := "res://assets/models/buildings/mine_portal.glb"
	if not ResourceLoader.exists(PATH):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * side_sign
	var scene := load(PATH) as PackedScene
	var portal := _extract_glb_group(scene, "Portal")
	if portal == null:
		return
	var body := StaticBody3D.new()
	body.add_to_group("mines")
	# Portalul nu e un `_LANDMARKS`, dar e tot un prop hero care merita verificat
	# in cadru. Id de sonda peste intervalul tabelului (vezi `shot_id`).
	body.set_meta("shot_id", SHOT_MINE)
	var aabb := model_aabb(portal)
	body.add_child(portal)
	# Cutie pe amprenta portalului: e o masa compacta, deci AABB-ul e corect
	# aici (spre deosebire de bratul excavatorului, vezi ONBOARDING).
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	shape.shape = box
	shape.position = aabb.position + aabb.size * 0.5
	body.add_child(shape)
	add_child(body)
	Palette.apply_class_materials(portal, _MINE_CLASSES)
	var stand := p + side * (half_width + 16.0)
	stand.y = _sampler.ground_y(stand.x, stand.z)
	body.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)
	# Sina iese din gura minei spre drum; vagonetul rasturnat langa ea.
	for pair: Array in [["MineRail", 7.0, 0.0], ["MineCart", 5.0, 3.2]]:
		var piece := _extract_glb_group(scene, String(pair[0]))
		if piece == null:
			continue
		var spot := stand - side * float(pair[1]) \
			+ side.cross(Vector3.UP).normalized() * float(pair[2])
		spot.y = _sampler.ground_y(spot.x, spot.z)
		add_child(piece)
		Palette.apply_class_materials(piece, _MINE_CLASSES)
		piece.look_at_from_position(spot, Vector3(p.x, spot.y, p.z), Vector3.UP)
	_build_mine_camp(stand, side)


## Gramada de unelte din jurul gurii de mina: butoaie, lazi, cauciucuri.
##
## Pozitiile sunt SCRISE, nu trase la sorti — asta e toata diferenta dintre un
## set si scatter. Decorul procedural imprastie deja obiecte pe toata pista;
## ce nu avea pista era un loc unde obiectele stau IMPREUNA si spun ceva
## ("aici s-a descarcat vagonetul"). Un cluster citit corect valoreaza cat
## douazeci de butoaie presarate, si costa de douazeci de ori mai putin.
##
## Sistemul de coordonate e cel al sinei de deasupra: `toward` = metri spre
## sosea fata de gura minei, `along` = metri lateral (pozitiv in aceeasi parte
## ca vagonetul, ca gramada sa se stranga in jurul lui). `yaw` e rotatia in
## grade fata de directia „cu fata la drum" — la un butoi conteaza doar ca
## piesele vecine sa nu iasa aliniate ca la raft.
## Cele doua ACCENTE de culoare (#149) stau amandoua aici, si asta e regula, nu
## intamplarea: style_bible §1 lasa masinilor monopolul suprafetelor saturate,
## deci o pata de rosu sau de albastru in decor e o resursa care se cheltuie pe
## un set, ca sa-i tragi ochiul acolo. Imprastiate pe margine ar concura chiar
## lucrul pe care trebuie sa-l urmaresti — masina din fata.
##
## Containerul e lipit de peretele minei dinadins: `painted_metal` se citeste
## RECE pe nisip, deci are nevoie de o structura langa el. Singur pe dune ar
## arata a greseala de paleta.
const _MINE_CAMP := [
	# Punctul de descarcare, langa vagonet: doua butoaie si o lada.
	{"node": "Barrel_A", "toward": 4.3, "along": 4.5, "yaw": 15.0},
	{"node": "Barrel_B", "toward": 3.5, "along": 5.4, "yaw": -40.0},
	{"node": "Crate_A", "toward": 5.4, "along": 5.1, "yaw": 24.0},
	{"node": "Tarp_A", "toward": 4.9, "along": 6.3, "yaw": -8.0},
	# Depozitul, lipit de peretele minei, pe partea cealalta a sinei.
	{"node": "TyreStack", "toward": 7.6, "along": -3.4, "yaw": 0.0},
	{"node": "Crate_B", "toward": 9.2, "along": -2.6, "yaw": -18.0},
	{"node": "Tyre", "toward": 6.0, "along": -4.5, "yaw": 0.0},
	{"node": "Container_A", "toward": 8.4, "along": -4.6, "yaw": 8.0},
]


func _build_mine_camp(stand: Vector3, side: Vector3) -> void:
	const PATH := "res://assets/models/props/props_junk.glb"
	if not ResourceLoader.exists(PATH):
		return
	var scene := load(PATH) as PackedScene
	var along := side.cross(Vector3.UP).normalized()
	# Cu fata la drum, adica invers decat `side` (care arata dinspre sosea spre
	# mina). Butoaiele n-au fata, dar lazile au muchii, si un rand de cutii
	# paralele cu drumul citeste altfel decat unul pieziș.
	var base_yaw := atan2(-side.x, -side.z)
	for item: Dictionary in _MINE_CAMP:
		var piece := _extract_glb_node(scene, String(item["node"]))
		if piece == null:
			continue
		# Clasele, NU atlasul: butoaiele si lazile au UV-uri reale din #131, iar
		# `apply_world_material` ar citi atlasul pe ele si le-ar face dungi prin
		# toata paleta. Cauciucurile nu sunt in tabel si cad pe atlas — negrul
		# curat E cauciucul (vezi PROPS_JUNK_CLASSES).
		Palette.apply_class_materials(piece, PROPS_JUNK_CLASSES)
		add_child(piece)
		var spot := stand - side * float(item["toward"]) \
			+ along * float(item["along"])
		spot.y = _sampler.ground_y(spot.x, spot.z)
		piece.global_position = spot
		piece.rotation.y = base_yaw + deg_to_rad(float(item["yaw"]))

## Tabel de landmark-uri hero. id -> model GLB + cum se aseaza:
##   gap    = cat de departe de marginea soselei sta (m)
##   col    = forma de coliziune ("cyl" / "box" / "none")
##   radius = raza cilindrului, DOAR pentru "cyl" (vezi mai jos de ce ramane)
##   spin   = primeste scriptul windmill.gd (roata "Blades" care se invarte)
##
## Ce NU mai sta aici: inaltimea si latimea. Se citesc din AABB-ul modelului, ca
## la clustere si cactusi (vezi comentariul din track_decor._add_cluster) —
## regenerezi GLB-ul cu alte cote si coliziunea le urmeaza singura.
##
## Tabelul avea cotele scrise de mana si DOUA din ele erau deja gresite:
## benzinaria era declarata 6.0 pe Z cand modelul are 6.58 (0.58 m de cladire
## prin care treceai), iar moara 9.0 cand turnul are 10.10. Nimic nu le verifica,
## fiindca nimic nu compara un numar dintr-un dictionar cu geometria.
##
## Raza ramane in tabel pentru ca NU e o masuratoare, e o decizie: un turn pe
## patru picioare are amprenta de ~4.6 m, dar vrem sa lovesti picioarele, nu un
## cilindru gras care inghite spatiul dintre ele.
const _LANDMARKS := {
	# "tri_class": tot subarborele primeste clasa triplanara respectiva —
	# doar pentru assets dintr-un singur material dominant (turnul e integral
	# metal ruginit). Cele cu mai multe materiale trec prin "classes" + parti
	# numite, ca village_house.
	0: {"path": "res://assets/models/buildings/water_tower.glb",
		"gap": 10.0, "col": "cyl", "radius": 2.4, "spin": false,
		"tri_class": "rust_metal"},
	# Benzinaria: patru clase de suprafata. Ce ramane pe atlas (Gas_Trim) ramane
	# din motive — geamurile isi iau adancimea falsa din slotul cel mai inchis,
	# iar panoul, fascia rosie si steaua sunt accente de culoare pe care o
	# textura le-ar sterge.
	1: {"path": "res://assets/models/buildings/gas_station.glb",
		"gap": 9.0, "col": "box", "spin": false,
		"classes": {"Gas_Wood": "wood", "Gas_Rust": "rust_metal",
			"Gas_Concrete": "concrete"}},
	# Moara: lemn SI metal, deci nu poate lua o clasa "pe tot subarborele" ca
	# turnul. Piesele Mill_Wood/Mill_Metal/Blades au UV-uri reale (proiectie
	# cubica); Mill_Trim ramane pe atlas — vana albastra e singurul accent de
	# culoare al morii, iar apa din jgheab e un slot, nu o textura.
	# ATENTIE: `Blades` se roteste, deci UV-uri reale, NU triplanar de lume.
	2: {"path": "res://assets/models/buildings/windmill.glb",
		"gap": 11.0, "col": "cyl", "radius": 1.6, "spin": true,
		"classes": {"Mill_Wood": "wood", "Mill_Metal": "rust_metal",
			"Blades": "rust_metal"}},
	3: {"path": "res://assets/models/signs/route66_sign.glb",
		"gap": 3.5, "col": "none", "spin": false},
	# Ecran de drive-in: 20.6 m lat si 10.8 m inalt, cel mai lat lucru construit
	# de pe pista. Sta departe de sosea nu ca sa nu-l lovesti, ci ca sa incapa in
	# cadru — de la 9 m ai doar tabla in fata.
	# Doar scheletul primeste textura. Fata ecranului RAMANE pe atlas: e cea mai
	# deschisa si cea mai curata suprafata din cadru, si asta e tot rostul
	# obiectului — o textura de metal peste ea ar face-o inca un perete ruginit.
	4: {"path": "res://assets/models/buildings/drive_in_screen.glb",
		"gap": 15.0, "col": "box", "spin": false,
		"classes": {"DriveIn_Metal": "rust_metal"}},
	# Stalpul GAS: 13.7 m, cel mai INALT. Raza mica intentionat — vrem sa lovesti
	# stalpul, nu un cilindru de 1.9 m in jurul unui obiect subtire.
	5: {"path": "res://assets/models/signs/gas_pole_sign.glb",
		"gap": 5.0, "col": "cyl", "radius": 0.55, "spin": false},
	# Casa de sat (Okinawa) — PILOTUL texturilor de clasa: partile House_Roof/
	# House_Plaster/House_Stone au UV-uri reale si primesc texturile din
	# assets/textures/classes/ prin cheia "classes"; lemnaria si nisipul raman
	# pe atlas. Raza de coliziune acopera cladirea, nu limba de nisip — poti
	# rula peste marginea curtii, dar nu prin casa.
	6: {"path": "res://assets/models/buildings/village_house.glb",
		"gap": 10.0, "col": "cyl", "radius": 2.6, "spin": false,
		"classes": {"House_Roof": "roof_tiles", "House_Plaster": "plaster",
			"House_Stone": "stone_wall"}},
	# --- Okinawa (#102 / #103) ------------------------------------------------
	#
	# Farul: 9.1 m, cel mai inalt reper al insulei. Raza 1.1 acopera TURNUL, nu
	# soclul de piatra de 1.6 — poti calca treapta soclului, dar nu treci prin
	# turn. Sta departe (12 m) fiindca rolul lui e sa se vada de pe jumatate de
	# tur; de la 5 m nu mai vezi decat benzi rosii.
	7: {"path": "res://assets/models/buildings/lighthouse.glb",
		"gap": 12.0, "col": "cyl", "radius": 1.1, "spin": false,
		"classes": {"Lighthouse_Stone": "stone_wall",
			"Lighthouse_White": "plaster"}},
	# Poarta de piatra: singurul landmark peste care se TRECE, deci "none".
	# O cutie de coliziune pusa pe deschiderea ei ar fi zidit drumul, iar
	# stalpii stau oricum dincolo de marginea asfaltului prin `gap`.
	8: {"path": "res://assets/models/structures/stone_gate_torii.glb",
		"gap": 1.2, "col": "none", "spin": false,
		"classes": {"Torii_Stone": "stone_wall", "Torii_Roof": "roof_tiles"}},
	# Perechea de shisa: DOUA id-uri, nu unul cu doua modele. `_build_landmark`
	# aseaza tot ce e intr-un GLB la o singura pozitie, deci perechea se face
	# din doua intrari puse pe laturi opuse la aceeasi fractie (vezi
	# `Track05._landmark_spots`). Traditia: gura deschisa in dreapta.
	9: {"path": "res://assets/models/props/shisa_statue.glb",
		"gap": 2.2, "col": "box", "spin": false,
		"classes": {"Shisa_Base": "stone_wall", "Shisa_Stone": "concrete"}},
	10: {"path": "res://assets/models/props/shisa_statue_closed.glb",
		"gap": 2.2, "col": "box", "spin": false,
		"classes": {"Shisa_Base": "stone_wall", "Shisa_Stone": "concrete"}},
	# Zidul gusuku: cutie de coliziune, nu cilindru — un zid de 8 m e lung, iar
	# un cilindru in jurul lui ar fi inghitit jumatate de sosea.
	11: {"path": "res://assets/models/structures/gusuku_wall.glb",
		"gap": 4.5, "col": "box", "spin": false,
		"classes": {"Gusuku_Wall": "stone_wall"}},
	# --- Desert -----------------------------------------------------------
	#
	# Baraca minerului. Casa de sat (id 6) e tot o cladire mica, dar e Okinawa —
	# tigla, tencuiala, piatra de gusuku — deci nu se refoloseste pe desert.
	# `Shack_Trim` (usa, geamul, pragul) NU e mapat si cade pe atlas, dinadins:
	# usa si geamul sunt cele mai inchise suprafete din obiect, iar contrastul
	# lor cu lemnul spalat de soare e ce face silueta sa se citeasca de la 60 m.
	# O textura de lemn peste ele le-ar aduce la valoarea peretelui.
	#
	# Id 12, nu 7: baraca s-a nascut pe id 7 (#150) in acelasi timp in care
	# farul insulei si-l lua tot pe 7 (#103), pe alta ramura. Insula a pastrat
	# 7-11 fiindca `Track05._landmark_spots` le referea deja din COD; baraca era
	# referita doar din datele lui Track01, deci ea s-a mutat. Cand adaugi un
	# landmark nou, ia urmatorul id LIBER si verifica intai ramurile deschise.
	12: {"path": "res://assets/models/buildings/miner_shack.glb",
		"gap": 12.0, "col": "box", "spin": false,
		"classes": {"Shack_Wood": "wood", "Shack_Roof": "rust_metal"}},
}

## Prop "hero" asezat cu intentie pe marginea pistei, ca reper vizual
## (style_bible §7: landmark dominant la cateva secunde; NICIODATA inalt in
## apexul virajului). Turnul de apa/moara stau retrase, cu coliziune; semnul
## e doar vizual. Moara primeste windmill.gd ca sa i se invarta roata.
func _build_landmark(frac: float, side_sign: float, id: int) -> void:
	if not _LANDMARKS.has(id):
		return
	var info: Dictionary = _LANDMARKS[id]
	var path: String = info["path"]
	if not ResourceLoader.exists(path):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * side_sign
	var model := (load(path) as PackedScene).instantiate() as Node3D
	# Masurat INAINTE de set_script si de orice scalare — pe urma nodul "Blades"
	# al morii ajunge sa fie rotit de windmill.gd si AABB-ul n-ar mai fi al
	# pozitiei de repaus.
	var aabb := model_aabb(model)
	if info["spin"]:
		model.set_script(load("res://scenes/props/windmill.gd"))
	var root: Node3D
	if info["col"] == "none":
		root = Node3D.new()
	else:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		if info["col"] == "box":
			var box := BoxShape3D.new()
			box.size = aabb.size
			shape.shape = box
			# Centrat pe AABB-ul real, nu presupus simetric fata de origine:
			# benzinaria e decalata pe Z fata de pivotul ei.
			shape.position = aabb.position + aabb.size * 0.5
		else: # "cyl"
			var cyl := CylinderShape3D.new()
			cyl.radius = info["radius"]
			cyl.height = aabb.size.y
			shape.shape = cyl
			shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
		body.add_child(shape)
		root = body
	root.add_to_group("landmarks")
	# Eticheta pentru sonde: ca `snapshot.gd --landmark=` sa poata cere un prop
	# anume in loc sa ghiceasca fractia la care il prinde in cadru. Nu are
	# niciun rol de gameplay.
	root.set_meta("shot_id", id)
	root.add_child(model)
	add_child(root)
	# Atlasul comun pe tot subarborele (fara el, GLB-ul iese alb). Moara si-l
	# aplica singura in _ready, dar celelalte prop-uri il primesc aici.
	# Landmark-urile cu "classes" isi mapeaza partile pe texturile de clasa;
	# "tri_class" imbraca tot subarborele intr-o clasa triplanara (assets
	# dintr-un singur material); nodurile nemapate cad pe atlas.
	if info.has("classes"):
		Palette.apply_class_materials(root, info["classes"])
	elif info.has("tri_class"):
		Palette.apply_triplanar_class(root, info["tri_class"])
	else:
		Palette.apply_world_material(root)
	var stand := p + side * (half_width + float(info["gap"]))
	# Chiar la nivelul solului, nu la cota drumului. Comentariul de aici spunea
	# deja "la nivelul solului", dar terenul nu-l onora: statea la o cota fixa in
	# lume, deci pe portiunile inaltate landmark-ul ramanea suspendat in aer.
	stand.y = _sampler.ground_y(stand.x, stand.z)
	root.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)

func _build_hose(frac: float) -> void:
	# Modelul sursei e TEMATIC, si poate lipsi cu totul. Pe Okinawa banda uda
	# vine din mare, deci o conducta de santier langa ea ar fi fost o piesa
	# importata din alta pista — `WaterHose` accepta `model == null` si ramane
	# doar cu balta si zona de grip taiat.
	var path: String = theme_flag("hose_model",
		"res://assets/models/props/pipe_leak.glb")
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var hose := WaterHose.new()
	# Era un FURTUN DE GRADINA care traversa soseaua intr-un canion de desert.
	# Conducta sparta face acelasi lucru mecanic — banda uda, grip aproape zero —
	# dar apartine peisajului.
	if not path.is_empty() and ResourceLoader.exists(path):
		hose.model = _extract_glb_node(load(path) as PackedScene, "Pipe_Broken")
	hose.road_width = half_width * 2.0
	add_child(hose)
	hose.global_position = baked[idx]
	hose.global_basis = Basis.looking_at(dir, Vector3.UP) # +X = marginea din dreapta


## Valul care spala soseaua (#106). E acelasi hazard de apa ca furtunul — banda
## uda si taierea de grip vin amandoua din `WaterHazard` — doar ca sursa se misca
## si uda doar cat trece.
func _build_wave_surge(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var wave := WaveSurge.new()
	# Directia de mers: perpendicular pe sosea, dinspre larg spre uscat. Nu se
	# alege la zar — pe un dig marea vine de pe o parte anume, iar un val care
	# porneste din interiorul insulei ar fi absurd.
	wave.travel_dir = _side_at(idx)
	wave.sweep = half_width * 3.2
	wave.road_width = half_width * 2.0
	# Creasta cat DOUA latimi de drum. Nu e o cifra de gust: la o latime de drum
	# valul citea din masina ca un obiect care pluteste pe asfalt (captura din
	# #106), fiindca ochiul il compara cu marginile soselei. Peste ele, devine ce
	# trebuie sa fie — o portiune de drum acoperita de mare.
	wave.crest_length = half_width * 4.0
	# Linia apei, ca la tromba: fara ea valul traverseaza orizontal la cota
	# soselei si pluteste in aer cat e in larg. Aceeasi despartire ca peste tot —
	# cotele terenului le stie pista, nu hazardul.
	if theme_flag("water", false):
		wave.water_y = _sampler.mean_road_y() + sea_level_offset
		# Apa de pe drum e chiar MAREA: acelasi material, deci acelasi turcoaz,
		# aceeasi spuma animata si zero materiale in plus la numaratoarea garzii.
		# La adancime ~0 shaderul da nisip ud cu spuma peste el — exact ce ramane
		# in urma unui val care a trecut peste dig.
		wave.film_material = _water_material()
	# Defazaj derivat din fractie, ca doua valuri pe aceeasi pista sa nu bata la
	# unison — acelasi truc ca la SlidingHazard.
	wave.phase = fposmod(frac * 2.3, 1.0)
	# Pozitia INAINTE de add_child: `add_child` declanseaza `_ready`, iar acolo
	# valul isi retine ancora. Asezat dupa, ancora ar fi ramas la originea pistei
	# si valul ar fi maturat acolo — vezi nota de pe `WaveSurge._anchor`.
	wave.position = baked[idx]
	add_child(wave)

## Tromba de mini-typhoon care matura soseaua.
##
## Ce ii da pista si ce isi calculeaza singura: aici se hotaraste DOAR unde sta,
## incotro matura si unde e apa. Cat de sus arunca, cat tine masina in aer si pe
## unde o aduce inapoi sunt in hazard, fiindca sunt reglaje de feel; cotele
## terenului sunt aici, fiindca hazardul n-are acces la sampler — aceeasi
## despartire ca la `TrainHazard.ground_drop` si la pilonii podului.
func _build_typhoon(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var typhoon := TyphoonHazard.new()
	typhoon.name = "Typhoon%03d" % idx
	typhoon.road_half_width = half_width
	# Directia de maturat: perpendicular pe sosea. Ca la val, nu se alege la zar —
	# o tromba vine dinspre larg, nu din mijlocul insulei.
	typhoon.travel_dir = _side_at(idx)
	# Maturarea trece de ambele margini ale asfaltului cu o marja buna: tromba
	# trebuie sa se DEPARTEZE vizibil, nu doar sa iasa de pe banda. Cu 3.2 x
	# jumatatea de latime, capetele cad la ~22 m de axa, adica pe apa de o parte
	# si pe plaja de cealalta — acolo unde o vezi cum ridica altceva.
	typhoon.sweep = half_width * 3.2
	typhoon.phase = fposmod(frac * 2.3, 1.0)
	# Linia apei, in spatiul PISTEI si nu al trombei — vezi nota de pe
	# TyphoonHazard.water_y pentru de ce e altfel decat la podul mobil.
	typhoon.water_y = _sampler.mean_road_y() + sea_level_offset
	# Pozitia INAINTE de add_child, nu dupa. `add_child` declanseaza `_ready`, iar
	# `_ready` isi retine punctul de ancorare — asezat dupa, ancora ar fi ramas la
	# originea pistei si tromba ar fi maturat acolo. Exact capcana in care cazuse
	# `_build_wave_surge`, care scria pozitia dupa si apoi si-o suprascria in
	# fiecare cadru — reparata odata cu ancora valului.
	typhoon.position = baked[idx]
	add_child(typhoon)


## Popice pe marginile DESCHISE ale pistei (interior la nivelul solului,
## unde nu sunt pereti): delimitatoare fizice — stau cuminti pana le lovesti.
## Cele trei siluete din marker_post.glb si cat de des apare fiecare.
## Cel rupt e rar intentionat: daca fiecare al treilea stalp e frant, marginea
## drumului nu mai citeste ca marcaj, ci ca ruina.
const _MARKER_PICKS := [
	{"node": "Marker_A", "weight": 0.55}, # drept
	{"node": "Marker_B", "weight": 0.32}, # inclinat, lovit de o masina
	{"node": "Marker_C", "weight": 0.13}, # rupt la jumatate
]


func _build_markers() -> void:
	if not ResourceLoader.exists("res://assets/models/signs/marker_post.glb"):
		return
	var scene := load("res://assets/models/signs/marker_post.glb") as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed() + 7 # alt sir decat decorul si orizontul
	var loop_poly := PackedVector2Array()
	for p in _points():
		loop_poly.append(Vector2(p.x, p.z))
	var n := baked.size()
	var placed := 0
	for i in range(0, n, 4): # un stalp la ~12m de margine deschisa
		if placed >= 110:
			break
		for side_sign: float in [-1.0, 1.0]:
			var edge := baked[i] + _side_at(i) * half_width * side_sign
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(edge.x, edge.z), loop_poly)
			if exterior or edge.y > 1.0:
				continue # acolo sunt pereti; stalpii marcheaza doar golurile
			if _road_gap(i) or _bridge_mix(i) > 0.05:
				continue # pe pod: parapetul tine locul popicilor
			var model := _extract_glb_node(scene, _marker_variant(rng))
			if model == null:
				continue
			# Materialul comun PE MODEL, nu pe pista. `apply_world_material` pune
			# material_override pe tot subarborele primit — dat pe `self`, ar
			# rescrie asfaltul, bordurile si liniile cu UV-uri de atlas pe care
			# ele nu le au. Tiparul e cel din track_decor: cate un apel per
			# instanta, materialul fiind oricum partajat.
			Palette.apply_world_material(model)
			var marker := RoadMarker.new()
			marker.model = model
			add_child(marker)
			# Rotire pe verticala: banda reflectorizanta se intoarce spre drum.
			# Fara asta, jumatate din stalpi si-ar arata spatele.
			marker.rotation.y = atan2(-_side_at(i).x * side_sign,
				-_side_at(i).z * side_sign)
			var spot := edge + _side_at(i) * side_sign * 1.7
			# Stalpii scapasera de bug-ul plutirii doar din NOROC: linia de mai
			# sus sare peste sloturile inaltate, care erau exact cele afectate.
			# Acum stau pe sol prin constructie, nu prin coincidenta.
			spot.y = _sampler.ground_y(spot.x, spot.z) + 0.2
			marker.global_position = spot
			placed += 1


func _marker_variant(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var acc := 0.0
	for pick: Dictionary in _MARKER_PICKS:
		acc += float(pick["weight"])
		if roll < acc:
			return String(pick["node"])
	return String(_MARKER_PICKS[0]["node"])


## Semne chevron inaintea virajelor stranse: comunicare de gameplay, nu decor.
## De la 60-80 m, din chase cam, directia virajului trebuie citita inainte sa
## se vada virajul (brieful din docs/asset_briefs/chevron_sign.md).
const CHEVRON_PATH := "res://assets/models/signs/chevron_sign.glb"
## Sub pragul asta de rotatie cumulata pe fereastra de ~30 m nu e "viraj
## strans", e curgere — un semn acolo ar fi zgomot (style_bible §3).
const CHEVRON_TURN_MIN: float = 0.8    # rad (~46°)
## De aici in sus virajul primeste panoul triplu, nu pe cel simplu.
## 1.0, nu 1.3: la 1.3 niciun viraj de pe Dunele nu lua panoul mare, iar din
## chase cam, la 27 m, panoul simplu abia se anunta. Virajele de ~60° pe
## fereastra de 30 m sunt exact cele in care intri prea repede.
const CHEVRON_TURN_TRIPLE: float = 1.0 # rad (~57°)
## Semnul sta INAINTEA intrarii in viraj: la ~30 m/s, o secunda de reactie.
const CHEVRON_LEAD: float = 28.0
const CHEVRON_GAP: float = 2.6         # m de la marginea asfaltului
const CHEVRON_MAX: int = 12
## Cat poate aluneca semnul de-a lungul drumului ca sa iasa dintre stanci.
## Rulat DUPA decor tocmai ca sa poata face asta: prima versiune se construia
## inaintea decorului si primul semn de pe Dunele a iesit ingropat in faleza.
const CHEVRON_SLIDE: Array[float] = [0.0, -3.0, 3.0, -6.0, 6.0, -9.0, -12.0,
	-15.0] # metri fata de avansul nominal; negativ = si mai devreme
## Cat de departe de marginea oricarei piese de decor trebuie sa stea STALPUL
## semnului. Doar anti-suprapunere — vizibilitatea o dau liniile de vedere.
const CHEVRON_CLEAR: float = 0.6
## Punctele de pe traseu (metri in urma semnului) din care semnul trebuie sa
## se vada neacoperit. 15 = "il citesti cand ridici piciorul de pe acceleratie",
## 30 = "il vezi din zona de franare".
const CHEVRON_EYES: Array[float] = [15.0, 30.0]


## Cotitura SEMNATA a fiecarui pas de pe traseu, in radiani: + stanga, - dreapta.
##
## Insumata pe o fereastra da „cat de tare intoarce drumul aici", si din ea ies
## amandoua deciziile de amplasare care se uita la forma soselei: semnele de
## chevron cauta maximele (viraje), gardul cauta minimele (drepte).
func _turn_angles() -> PackedFloat32Array:
	var n := baked.size()
	var ang := PackedFloat32Array()
	ang.resize(n)
	for i in n:
		var d0 := baked[i] - baked[(i - 1 + n) % n]
		var d1 := baked[(i + 1) % n] - baked[i]
		d0.y = 0.0
		d1.y = 0.0
		if d0.length_squared() < 1e-8 or d1.length_squared() < 1e-8:
			ang[i] = 0.0
			continue
		ang[i] = asin(clampf(d0.normalized().cross(d1.normalized()).y, -1.0, 1.0))
	return ang


func _build_chevrons() -> void:
	if not ResourceLoader.exists(CHEVRON_PATH):
		return
	var scene := load(CHEVRON_PATH) as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed() + 11 # alt sir decat stalpii si decorul
	var n := baked.size()
	if n < 8 or _dists.size() <= n:
		return
	# Piesele de decor destul de mari cat sa ascunda un semn de 1.6 m, ca
	# amprente convexe in XZ. Se strang O DATA, nu per candidat.
	var obstacles: Array[PackedVector2Array] = []
	for decor_root in _decor_roots:
		_collect_obstacles(decor_root, obstacles)
	var spacing := _dists[n] / float(n)
	var ang := _turn_angles()
	var look := maxi(1, int(30.0 / spacing))
	var lead := maxi(1, int(CHEVRON_LEAD / spacing))
	var placed := 0
	var i := lead # nu incepe inainte de linia de start: semnul ar intra in poarta
	while i < n and placed < CHEVRON_MAX:
		var total := 0.0
		for k in look:
			total += ang[(i + k) % n]
		if absf(total) < CHEVRON_TURN_MIN:
			i += 1
			continue
		if _place_chevron(scene, rng, (i - lead + n) % n, total, obstacles):
			placed += 1
		# Sari peste viraj plus un respiro — altfel un S lung ar insira
		# cate un semn la fiecare 3 m si semnalul ar redeveni zgomot.
		i += look + int(40.0 / spacing)


## Aduna piesele de decor ca amprente convexe in plan XZ: colturile AABB-ului
## LOCAL trecute prin transformarea globala, apoi convex hull. Amprenta
## ORIENTATA, nu AABB global: sectiunile de faleza stau diagonal in viraje —
## exact unde stau si semnele — iar cutia lor axata se umfla peste tot
## coridorul drumului si "suprapune" semne care stau de fapt la metri de
## fata zidului (asa au murit toate candidatele la a doua incercare; prima
## murise de cercuri). Doar piesele care pot acoperi PANOUL (0.8-1.6 m):
## scatterul marunt ascunde cel mult stalpii.
func _collect_obstacles(node: Node, out: Array[PackedVector2Array]) -> void:
	for c in node.get_children():
		if c.is_queued_for_deletion():
			continue # variante de GLB "sterse" in cadrul curent, inca in arbore
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			_add_obstacle(mi.get_aabb(), mi.global_transform, out)
		elif c is MultiMeshInstance3D:
			# Decorul copt (TrackDecorBatch) nu mai are cate un nod per prop:
			# amprentele se citesc din buffer, instanta cu instanta. Fara
			# ramura asta sonda ar gasi ZERO obstacole in decor si semnele s-ar
			# aseza iar in falezele din spatele lor — bug-ul pentru care exista
			# functia in primul rand.
			var mmi := c as MultiMeshInstance3D
			var mm := mmi.multimesh
			if mm != null and mm.mesh != null:
				var local := mm.mesh.get_aabb()
				for i in mm.instance_count:
					_add_obstacle(local,
						mmi.global_transform * mm.get_instance_transform(i),
						out)
		_collect_obstacles(c, out)


## Amprenta ORIENTATA a unei cutii, proiectata in plan. Extrasa din
## `_collect_obstacles` cand decorul a capatat a doua reprezentare (noduri si
## buffere): aceeasi matematica, doua surse.
func _add_obstacle(aabb: AABB, xf: Transform3D,
		out: Array[PackedVector2Array]) -> void:
	if (xf * aabb).size.y < 1.2:
		return
	var pts := PackedVector2Array()
	for cx in 2:
		for cy in 2:
			for cz in 2:
				var corner := aabb.position + Vector3(
					aabb.size.x * cx, aabb.size.y * cy, aabb.size.z * cz)
				var g := xf * corner
				pts.append(Vector2(g.x, g.z))
	out.append(Geometry2D.convex_hull(pts))


## Un semn pentru virajul care incepe la `at0 + lead`. `turn` semnat: + stanga,
## - dreapta. Semnul prefera pozitia nominala, dar decorul nu stie de el
## (generatorul e orb la ce vine dupa el — docs/decor_manual.md), asa ca
## CANDIDEAZA de-a lungul drumului si, daca tot exteriorul e zidit, trece pe
## interiorul virajului — un semn pe interior tot comunica directia; unul
## ingropat in stanca nu comunica nimic.
## Modelul e desenat spre STANGA (varful pe +X, adica stanga soferului care ii
## vede fata); virajele la dreapta il oglindesc cu scale.x = -1 — Godot
## intoarce backface culling dupa determinantul transformarii, deci oglindirea
## e legala pentru geometrie statica.
func _place_chevron(scene: PackedScene, rng: RandomNumberGenerator,
		at0: int, turn: float, obstacles: Array[PackedVector2Array]) -> bool:
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	var out_sign := 1.0 if turn > 0.0 else -1.0
	for side_mult: float in [1.0, -1.0]: # intai exteriorul, apoi interiorul
		for slide in CHEVRON_SLIDE:
			var i := (at0 + int(slide / spacing) + n) % n
			var stand := baked[i] + _side_at(i) \
				* (half_width + CHEVRON_GAP) * out_sign * side_mult
			var ground := _sampler.ground_y(stand.x, stand.z)
			if absf(ground - baked[i].y) > 2.0:
				continue # sectiune inaltata: ar pluti sau ar cadea sub drum
			if not _chevron_spot_clear(stand, i, obstacles):
				continue
			var variant := "Chevron_A"
			if absf(turn) < CHEVRON_TURN_TRIPLE:
				# Acelasi motiv ca la stalpi: unul din vreo sase e lovit, ca
				# marginea sa citeasca a loc trait, nu a ruina.
				variant = "Chevron_C" if rng.randf() < 0.18 else "Chevron_B"
			var model := _extract_glb_node(scene, variant)
			if model == null:
				return false
			Palette.apply_world_material(model)
			if turn < 0.0:
				model.scale.x = -1.0
			var root := Node3D.new()
			root.add_child(model)
			add_child(root)
			stand.y = ground
			# -Z al semnului (fata cu chevronele) se intoarce IMPOTRIVA sensului
			# de mers: semnul vorbeste cu cine vine spre el, nu cu cine a trecut.
			var dir := (baked[(i + 1) % n] - baked[i]).normalized()
			root.look_at_from_position(stand, stand - dir, Vector3.UP)
			return true
	return false


## Gard de ranch pe portiunile DREPTE: textura de margine, nu reper.
##
## Oglinda semnelor de chevron — aceeasi fereastra de curbura din
## `_turn_angles`, dar cautand minimele in loc de maxime. Gardul are nevoie de
## o dreapta ca sa citeasca drept: pe un viraj, module rigide de 4 m ar taia
## coarda si ar iesi un poligon, nu o curba.
const FENCE_PATH := "res://assets/models/structures/fence_ranch.glb"
## Peste atata cotitura cumulata pe fereastra nu mai e dreapta.
## 0.22 -> 0.40: Dunele n-are aproape nicio dreapta adevarata, e un circuit din
## curbe inlantuite. La pragul strict incapeau 7 randuri pe tot turul, adica
## gardul se citea ca un accident, nu ca un element al lumii. Un gard pe o
## curba lunga si lina se descurca: modulele de 4 m taie coarda cu centimetri.
const FENCE_STRAIGHT_MAX: float = 0.40   # rad (~23°)
## Cat de lunga trebuie sa fie dreapta ca sa incapa un rand care se citeste.
const FENCE_RUN_MIN: float = 18.0
const FENCE_GAP: float = 5.2             # m de la marginea asfaltului
const FENCE_PITCH: float = 3.94          # lungimea modulului (masurata din GLB)
const FENCE_ROWS_MAX: int = 16
const FENCE_MODULES_MIN: int = 3
const FENCE_MODULES_MAX: int = 6
## Cat trebuie sa stea un modul departe de orice piesa de decor.
const FENCE_CLEAR: float = 1.0
## Cat de mult poate urca/cobori terenul sub un modul fata de cota soselei
## inainte sa renuntam: un gard care intra in deal arata mai rau decat lipsa lui.
const FENCE_STEP_MAX: float = 1.6
## Variantele si cat de des apar. Cel rupt e rar din acelasi motiv ca la stalpii
## de marcaj: daca fiecare al treilea modul e frant, nu mai citesti un gard, ci
## o ruina.
const _FENCE_PICKS := [
	{"node": "Fence_A", "weight": 0.58},
	{"node": "Fence_B", "weight": 0.30},
	{"node": "Fence_C", "weight": 0.12},
]


func _build_fences() -> void:
	# Gard de RANCH, deci doar pe temele de desert. Fara poarta asta ajungea si
	# pe Okinawa — lemn de ferma texana pe o insula tropicala, chiar langa un
	# torii de piatra. Legat de setul de prop-uri, nu de numele pistei, ca la
	# banda `far` din track_decor.
	if theme_flag("props", "desert") != "desert":
		return
	if not ResourceLoader.exists(FENCE_PATH):
		return
	var scene := load(FENCE_PATH) as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = _world_seed() + 23 # alt sir decat stalpii, decorul si semnele
	var n := baked.size()
	if n < 8 or _dists.size() <= n:
		return
	var obstacles: Array[PackedVector2Array] = []
	for decor_root in _decor_roots:
		_collect_obstacles(decor_root, obstacles)
	var spacing := _dists[n] / float(n)
	var ang := _turn_angles()
	var need := maxi(2, int(FENCE_RUN_MIN / spacing))
	var rows := 0
	var i := 0
	# Se merge din pas in pas si se pune un rand ORIUNDE incape, nu unul per
	# portiune dreapta.
	#
	# Varianta initiala cauta portiuni drepte si aseza un singur rand in
	# mijlocul fiecareia, apoi sarea peste toata portiunea. Consecinta perversa:
	# cand pragul de „drept" s-a relaxat ca sa incapa mai mult gard, portiunile
	# au devenit mai LUNGI si mai PUTINE, deci gardul a scazut de la 31 de
	# module la 3. Un criteriu mai permisiv trebuie sa dea mai mult, nu mai
	# putin — daca da mai putin, bucla masoara altceva decat crezi.
	while i < n and rows < FENCE_ROWS_MAX:
		var count := rng.randi_range(FENCE_MODULES_MIN, FENCE_MODULES_MAX)
		var span := maxi(need, int(float(count) * FENCE_PITCH / spacing))
		# E destul de drept pe toata lungimea randului?
		var total := 0.0
		for k in span:
			total += ang[(i + k) % n]
		if absf(total) > FENCE_STRAIGHT_MAX:
			i += 1
			continue
		# Alternam latura intre randuri: un gard mereu pe aceeasi parte citeste
		# ca o imprejmuire de pista, nu ca peisaj locuit.
		var first := 1.0 if rows % 2 == 0 else -1.0
		if _place_fence_row(scene, rng, i, count, first, obstacles) \
				or _place_fence_row(scene, rng, i, count, -first, obstacles):
			rows += 1
			# Respiro dupa un rand asezat: garduri cap la cap pe tot turul ar
			# citi ca imprejmuire, nu ca ferma.
			i += span + int(22.0 / spacing)
		else:
			i += 1
	if rows == 0 and n > 0:
		# Tacerea ar fi arata ca o alegere de design (lectia din _build_horizon).
		print("%s: niciun rand de gard (fara drepte destul de lungi sau libere)"
			% track_name)


## Un rand de module. Intoarce false daca nu incape — apelantul incearca cealalta
## latura. Randul e totul sau nimic: un gard din care lipsesc bucati la mijloc
## citeste ca eroare, nu ca uzura (pentru uzura exista `Fence_C`).
func _place_fence_row(scene: PackedScene, rng: RandomNumberGenerator,
		start: int, count: int, side_sign: float,
		obstacles: Array[PackedVector2Array]) -> bool:
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	var step := maxi(1, int(FENCE_PITCH / spacing))
	var spots: Array[Vector3] = []
	var yaws: Array[float] = []
	for m in count:
		var idx := (start + m * step) % n
		var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
		var spot := baked[idx] + _side_at(idx) * (half_width + FENCE_GAP) * side_sign
		var ground := _sampler.ground_y(spot.x, spot.z)
		if absf(ground - baked[idx].y) > FENCE_STEP_MAX:
			return false
		if not _spot_free(Vector2(spot.x, spot.z), obstacles, FENCE_CLEAR):
			return false
		spot.y = ground
		spots.append(spot)
		# Modulul se intinde pe X-ul lui local, deci X-ul trebuie sa cada pe
		# directia drumului. Pentru rotation.y = t, basis.x = (cos t, 0, -sin t).
		yaws.append(atan2(-dir.z, dir.x))
	for m in count:
		var model := _extract_glb_node(scene, _fence_variant(rng))
		if model == null:
			return false
		Palette.apply_world_material(model)
		var root := Node3D.new()
		root.add_child(model)
		add_child(root)
		root.global_position = spots[m]
		root.rotation.y = yaws[m]
	return true


func _fence_variant(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var acc := 0.0
	for pick: Dictionary in _FENCE_PICKS:
		acc += float(pick["weight"])
		if roll < acc:
			return String(pick["node"])
	return String(_FENCE_PICKS[0]["node"])


## Punctul e destul de departe de toate amprentele de decor?
static func _spot_free(p: Vector2, obstacles: Array[PackedVector2Array],
		clearance: float) -> bool:
	for hull in obstacles:
		if Geometry2D.is_point_in_polygon(p, hull):
			return false
		for e in hull.size():
			var closest := Geometry2D.get_closest_point_to_segment(
				p, hull[e], hull[(e + 1) % hull.size()])
			if closest.distance_to(p) < clearance:
				return false
	return true


## Locul e bun daca semnul (1) nu se suprapune cu nicio piesa de decor si
## (2) SE VEDE din pozitiile de apropiere — liniile de vedere de la sofer la
## semn nu taie nicio amprenta de decor. O stanca LANGA sau IN SPATELE
## semnului e in regula (e chiar fundal bun); doar una intre sofer si semn
## il face inutil. Asta e diferenta fata de testul radial initial, care pe
## Dunele respingea aproape tot: banda "hug" captuseste drumul cu stanci.
func _chevron_spot_clear(stand: Vector3, at: int,
		obstacles: Array[PackedVector2Array]) -> bool:
	var p := Vector2(stand.x, stand.z)
	if not _spot_free(p, obstacles, CHEVRON_CLEAR):
		return false
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	for back_m: float in CHEVRON_EYES:
		var k := (at - int(back_m / spacing) + n) % n
		var line := PackedVector2Array([Vector2(baked[k].x, baked[k].z), p])
		for hull in obstacles:
			if not Geometry2D.intersect_polyline_with_polygon(line, hull).is_empty():
				return false
	return true

## Marginea LUMII: patru pereti INVIZIBILI care opresc masina sa iasa din
## harta. Inainte era rama de scanduri a unei lazi de nisip (tema "jucarii in
## sandbox"); tema desert a devenit canion, iar o rama de placaj la 380m
## contrazicea direct citirea. Coliziunea ramane — doar decorul dispare.
## Bariera sta DINCOLO de silueta de la orizont, ca sa nu se loveasca de ea
## nimeni in mod normal: e plasa de siguranta, nu element de pista.
func _build_world_bounds() -> void:
	var centroid := _centroid()
	var half_extent := 420.0
	for side_idx in 4:
		var outward := [Vector3(0, 0, -1), Vector3(1, 0, 0),
			Vector3(0, 0, 1), Vector3(-1, 0, 0)][side_idx] as Vector3
		var wall := StaticBody3D.new()
		wall.add_to_group("world_bounds")
		add_child(wall)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var span := half_extent * 2.0 + 40.0
		box.size = Vector3(span, 30.0, 2.0) if absf(outward.z) > 0.5 \
			else Vector3(2.0, 30.0, span)
		shape.shape = box
		shape.position = Vector3(centroid.x, 14.0, centroid.z) \
			+ outward * half_extent
		wall.add_child(shape)

## Mesh doar vizual (fara coliziune) — pentru linii de start, borduri etc.
func _add_visual_mesh(mesh: ArrayMesh, color: Color) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _flat_material(color)
	add_child(inst)

func _build_start_gate() -> void:
	# Poarta de start din Blender, scalata pe latimea pistei; picioarele
	# au coliziune. Fallback pe stalpii procedurali daca lipseste modelul.
	#
	# Era o arcada de jucarie din tema abandonata "lada de nisip", pe TOATE
	# pistele, si primul lucru pe care il vezi la countdown.
	if ResourceLoader.exists("res://assets/models/structures/start_gate.glb"):
		var target_width := (half_width + 1.2) * 2.0
		var gate := StaticBody3D.new()
		gate.add_to_group("start_gate")
		var model := (load("res://assets/models/structures/start_gate.glb") as PackedScene) \
			.instantiate() as Node3D
		# Latimea si inaltimea se MASOARA. Aici erau trei literale (22.8 si 8.7
		# de doua ori) copiate din bbox-ul modelului de atunci; un GLB de alta
		# marime se scala gresit si ramanea cu coliziunea in aer, fara eroare.
		var aabb := model_aabb(model)
		var model_w := maxf(aabb.size.x, 0.001)
		var s := target_width / model_w
		var gate_h := aabb.size.y * s
		model.scale = Vector3.ONE * s
		gate.add_child(model)
		# Atlasul comun. Arcada veche isi aducea materialul ei, deci mergea fara
		# apelul asta; poarta noua are UV-uri spre sloturi si iese gresit fara el.
		Palette.apply_world_material(model)
		for sx: float in [-1.0, 1.0]:
			var pillar := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(1.4, gate_h, 1.6)
			pillar.shape = box
			# 0.9 = jumatate din grosimea cutiei (0.7) plus 0.2 marja, ca stalpul
			# de coliziune sa stea in interiorul siluetei, nu peste ea.
			pillar.position = Vector3(sx * (target_width * 0.5 - 0.9),
				gate_h * 0.5, 0)
			gate.add_child(pillar)
		add_child(gate)
		gate.global_position = baked[0]
		gate.global_basis = Basis.looking_at(start_direction(), Vector3.UP)
		return
	var side := _side_at(0)
	for s in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 6.0, 0.8)
		pillar.mesh = box
		pillar.position = baked[0] + side * (half_width + 0.8) * s + Vector3.UP * 3.0
		pillar.material_override = _flat_material(Color(0.9, 0.9, 0.95))
		add_child(pillar)
	var bar := MeshInstance3D.new()
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3((half_width + 1.2) * 2.0, 0.7, 0.9)
	bar.mesh = bar_box
	bar.position = baked[0] + Vector3.UP * 6.0
	bar.basis = Basis.looking_at(start_direction(), Vector3.UP)
	bar.material_override = _flat_material(Color(0.95, 0.55, 0.1))
	add_child(bar)

# ---------------------------------------------- interogari (AI + progres)

# Toate interogarile primesc `route` ca ULTIM parametru, cu 0 implicit.
#
# Nu e o preferinta de stil: asa fiecare apel existent din joc — car.gd,
# race.gd, ai_controller.gd, hazardele, sondele — continua sa insemne exact ce
# insemna, iar rutele devin o adaugire in loc de o rescriere. Un parametru pus
# primul ar fi cerut atins fiecare apel, adica exact felul in care se strecoara
# regresiile intr-un sistem de progres.

## Ruta cu indexul dat, sau bucla principala daca indexul e in afara.
func route_at(route: int) -> TrackRoute:
	if route >= 0 and route < routes.size():
		return routes[route]
	return routes[0] if not routes.is_empty() else null

## Banda asta e uda? Cat timp masina e pe ea, grip-ul lateral scade.
func route_is_wet(route: int) -> bool:
	var r := route_at(route)
	return r != null and r.wet


## Punctul de pe axa benzii. Inlocuieste accesul direct la `baked[i]` din codul
## de cursa — pe o scurtatura, indexul inseamna alt vector.
func point_at(index: int, route: int = 0) -> Vector3:
	var r := route_at(route)
	if r == null or r.count() == 0:
		return Vector3.ZERO
	return r.baked[r.wrap_index(index)]

func closest_index(from_index: int, pos: Vector3, route: int = 0) -> int:
	var r := route_at(route)
	return r.closest_index(from_index, pos) if r != null else 0

func closest_index_global(pos: Vector3, route: int = 0) -> int:
	var r := route_at(route)
	return r.closest_index_global(pos) if r != null else 0

func frac_at(index: int, route: int = 0) -> float:
	var r := route_at(route)
	return r.frac_at(index) if r != null else 0.0

## Punctul de repunere pe pista: centrul soselei cu `backoff_m` metri INAINTE
## de checkpoint-ul dat, orientat in sensul cursei. Retragerea da spatiu de
## elan — repus exact pe buza crestei, ai cadea din nou, iar bucla aia ar
## bloca cursa (exact ce nu vrem).
func recovery_transform(index: int, backoff_m: float,
		route: int = 0) -> Transform3D:
	var r := route_at(route)
	return r.recovery_transform(index, backoff_m) if r != null \
		else Transform3D.IDENTITY

func lateral_distance(index: int, pos: Vector3, route: int = 0) -> float:
	var r := route_at(route)
	return r.lateral_distance(index, pos) if r != null else 1e9

func is_on_road(index: int, pos: Vector3, route: int = 0) -> bool:
	var r := route_at(route)
	return r.is_on_road(index, pos) if r != null else false

func lookahead_point(index: int, ahead_m: float, lateral_frac: float,
		route: int = 0) -> Vector3:
	var r := route_at(route)
	if r == null:
		return Vector3.ZERO
	return r.lookahead_point(index, ahead_m, lateral_frac, curve.bake_interval)


## Cat de aproape de capetele unei scurtaturi se mai poate comuta pe ea.
##
## La intrare, scurtatura si soseaua principala pornesc din ACELASI punct si se
## departeaza treptat, deci nu exista o linie peste care sa treci. Fereastra e
## zona in care intrebarea "pe care dintre ele esti?" are sens.
const BRANCH_SNAP_RANGE: float = 45.0
## Cat de clar trebuie sa fii mai aproape de cealalta banda ca sa comuti.
## Fara histereza, o masina exact la mijloc ar oscila intre rute la 60 Hz.
const BRANCH_HYSTERESIS: float = 1.5


## De la ce distanta incepe un AI hotarat sa tinteasca spre scurtatura.
##
## Mai mare decat BRANCH_SNAP_RANGE cu intentie: comutarea de ruta se face pe
## proximitate laterala, deci masina trebuie sa apuce sa se MUTE pe banda
## cealalta inainte ca despicatura sa se termine. Cu o raza egala, AI-ul ar
## incepe sa vireze exact cand ar fi trebuit sa fie deja acolo.
const BRANCH_LURE_RANGE: float = 70.0

## Punct-tinta care duce spre intrarea unei scurtaturi.
##
## Intoarce [code]Vector3.INF[/code] daca nu e nicio bifurcatie in fata — asa
## apelantul stie sa-si pastreze tinta obisnuita, fara sa mai intrebe nimic.
func branch_lure(pos: Vector3, ahead_m: float) -> Vector3:
	for bi in range(1, routes.size()):
		var b := routes[bi]
		if pos.distance_to(b.baked[0]) > BRANCH_LURE_RANGE:
			continue
		var bidx := b.closest_index_global(pos)
		return b.lookahead_point(bidx, ahead_m, 0.0, curve.bake_interval)
	return Vector3.INF


## Pe ce ruta si la ce index e masina acum. Intoarce (ruta, index).
##
## Se cheama in fiecare cadru din [code]Car[/code], deci calea obisnuita —
## nicio scurtatura in apropiere — trebuie sa fie ieftina: o iesire imediata.
##
## Comutarea recalculeaza indexul cu o scanare completa pe ruta noua, si asta e
## si motivul pentru care scurtatura poate taia ORICAT. Cautarea locala
## obisnuita are o fereastra de ~72 m in lungul traseului; o revenire care sare
## mai mult de-atat ar lasa indexul agatat in urma, iar fractia de tur ar
## ingheta. Scanarea se face o singura data per comutare, nu per cadru.
func resolve_route(route: int, index: int, pos: Vector3) -> Vector2i:
	if routes.size() < 2:
		return Vector2i(route, index)
	if route == 0:
		for bi in range(1, routes.size()):
			var b := routes[bi]
			if pos.distance_to(b.baked[0]) > BRANCH_SNAP_RANGE:
				continue
			var bidx := b.closest_index_global(pos)
			if bidx == 0:
				continue # inca inainte de despicare
			if b.lateral_distance(bidx, pos) + BRANCH_HYSTERESIS \
					< routes[0].lateral_distance(index, pos):
				return Vector2i(bi, bidx)
		return Vector2i(0, index)
	var cur := route_at(route)
	if cur == null:
		return Vector2i(0, index)
	var last := cur.count() - 1
	var near_end := index >= last - 1 \
		or pos.distance_to(cur.baked[last]) < BRANCH_SNAP_RANGE * 0.5
	if near_end:
		return Vector2i(0, routes[0].closest_index_global(pos))
	# Iesire de siguranta: ai parasit banda si esti clar mai aproape de sosea.
	# Fara ea, o masina impinsa de pe banc ar ramane legata de o ruta pe care
	# nu mai e, cu tot ce inseamna asta pentru checkpoint si pozitie.
	if cur.lateral_distance(index, pos) > cur.half_width * 2.5:
		var mi := routes[0].closest_index_global(pos)
		if routes[0].lateral_distance(mi, pos) < cur.lateral_distance(index, pos):
			return Vector2i(0, mi)
	return Vector2i(route, index)

func spawn_transforms(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var n := baked.size()
	for i in count:
		var back_m := 8.0 + float(i / 2) * 8.0
		var idx := ((n - int(back_m / curve.bake_interval)) % n + n) % n
		var side := (-1.0 if i % 2 == 0 else 1.0) * half_width * 0.4
		var pos := baked[idx] + _side_at(idx) * side + Vector3.UP * 0.5
		var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
		result.append(Transform3D(Basis.looking_at(dir, Vector3.UP), pos))
	return result
