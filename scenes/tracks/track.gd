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

## Poarta de start folosita cand nici pista, nici tema nu cer alta.
## Vezi [member gate_model] pentru cum se suprascrie.
const DEFAULT_GATE_MODEL: String = "res://assets/models/structures/start_gate.glb"

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
## Jumatatea latimii soselei, in metri. Ingust = tehnic, lat = vitezomanie.
##
## NU se citeste direct din generatoare: acolo se cheama [method width_at] sau
## [method width_at_index]. Deocamdata amandoua intorc exact valoarea asta,
## deci comportamentul e neschimbat — dar toate cele ~44 de locuri care
## dimensionau ceva dupa latime trec printr-un singur punct, iar profilul de
## latime pe sectoare (#236 pasul 2) devine o schimbare intr-o functie in loc
## de una in patruzeci. Vezi [method width_at].
var half_width: float = 7.0

## Din ce e facut drumul: "asphalt" (implicit), "dirt" — nisip batatorit —
## sau "snow" — zapada batatorita (malul Baikalului).
##
## NU e o intrare in tema, si asta e deliberat: Okinawa manual imparte tema
## "island" cu Okinawa v2 — si nu doar tema, ci LUMEA, pana la samanta (vezi
## world_seed_name). Pus in tema, drumul de nisip ar fi schimbat amandoua
## pistele; aici schimba exact pista care l-a cerut.
##
## Ce atarna de el, in ordinea in care se vede din masina:
##   - materialul soselei — nisip/zapada in loc de asfalt, fara sheen
##     (_build_road);
##   - marcajele — un drum nepavat n-are linie de mijloc (_build_center_line);
##     bordurile dispar pe nisip dar RAMAN pe zapada (vezi _build_kerbs);
##   - urmele coapte in pista — DISPAR complet (_build_tire_marks): pe o
##     suprafata pe care masinile lasa urme reale in fiecare cadru, o urma
##     desenata dinainte nu se adauga la ele, le contrazice;
##   - masinile — ridica praf si lasa urme cat timp RULEAZA pe el, nu doar cand
##     derapeaza (Car._on_loose_ground); pe zapada praful e alb-albastrui si
##     brazda e zapada presata (vezi trail_mark_color).
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
	if road_surface == "snow":
		return SNOW_ROAD_COLOR
	return dirt_road_color() if road_is_loose() else ROAD_COLOR

## Suprafata pe care masinile lasa brazde rulind (vezi SandTrail).
##
## O singura culoare pe pista, fiindca materialul urmelor e unul singur, partajat
## de toate masinile. Se alege suprafata pe care se lasa CELE MAI MULTE urme: pe
## o pista cu drum afanat aia e chiar drumul, pe una cu asfalt e terenul de
## langa el — pe asfalt nu se depune nimic.
func trail_surface_color() -> Color:
	if road_surface == "snow":
		return SNOW_ROAD_COLOR
	return dirt_road_color() if road_is_loose() else theme_ground_tint

## Cat de INCHISA e brazda fata de suprafata pe care e lasata, pe drumurile de
## pamant/nisip. Tinta e o brazda, nu vopsea: nisipul rascolit isi pierde din
## lumina fiindca boabele stau altfel si pentru ca sub crusta uscata e material
## mai umed. 0.42 e cat s-a masurat pe drumul de nisip (#D3A855 curat ->
## #9E7A45 pe brazda) — se citeste din masina, dar nu face din urma o dara de
## pacura. (Constanta a stat in SandTrail cat timp exista o singura suprafata
## afanata; culoarea brazdei e insa a PISTEI, ca si cea a prafului.)
const TRAIL_MARK_DARKEN: float = 0.42

## Culoarea FINALA a brazdei de rulare (SandTrail o pune direct pe material).
##
## Pe nisip e suprafata intunecata cu TRAIL_MARK_DARKEN. Pe zapada, aceeasi
## reteta ar da o dara gri-noroi: zapada presata nu doar ca e mai intunecata,
## e mai ALBASTRA — fagasul compact devine semi-transparent si tine umbra
## cerului, in timp ce spulberul din jur ramane alb. Coeficientii per canal
## coboara rosul mai tare decat albastrul exact ca sa pastreze racoarea.
func trail_mark_color() -> Color:
	if road_surface == "snow":
		var s := SNOW_ROAD_COLOR
		return Color(s.r * 0.68, s.g * 0.74, s.b * 0.86)
	return trail_surface_color().darkened(TRAIL_MARK_DARKEN)

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

## Modelul portii de start AL PISTEI. Gol = ce cere tema (cheia `gate_model`);
## daca nici tema nu cere nimic, [constant DEFAULT_GATE_MODEL].
##
## Poarta e primul lucru pe care il vezi la countdown, deci tine de identitatea
## pistei, nu de mobilierul comun: o pista de iarna vrea alta silueta decat una
## de plaja. Doua nivele, fiindca sunt doua intrebari diferite — "toate pistele
## din tema asta au poarta de lemn" se scrie pe TEMA, "pista asta anume are
## poarta ei" se scrie PE PISTA, din Inspector (vezi
## TrackFromPath.custom_gate_model).
##
## "none" = fara poarta deloc, nici macar stalpii procedurali de fallback.
var gate_model: String = ""

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


## Unghiul soarelui, cu abaterea pistei daca exista (theme "sun_rotation_deg").
## Citit si de lumina, si de scanteierea apei — o singura sursa de adevar.
func _sun_rotation_deg() -> Vector3:
	var v: Variant = theme_flag("sun_rotation_deg", SUN_ROTATION_DEG)
	return v if v is Vector3 else SUN_ROTATION_DEG

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
##
## Cheia `gate_model` (optionala) da poarta de start a temei — calea unui GLB,
## sau "none" pentru nicio poarta. Lipsa ei = [constant DEFAULT_GATE_MODEL].
## O pista anume o suprascrie cu [member gate_model].
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
			# Bolovanul care se rostogoleste de pe faleza e din aceeasi roca cu
			# ea (#242). Steag separat de `hazard_class` fiindca sunt doua
			# obiecte diferite: bariera mobila poate fi orice (o barca, o
			# testoasa), bolovanul e mereu piatra locului.
			#
			# Declarat explicit aici fiindca desertul n-are `rock_class` — pe
			# temele care au (alpinul, cu sisturile lui), acela e implicitul si
			# steagul asta nu mai trebuie scris.
			"rockfall_class": "rock",
			# Deflectorul: bolovani desprinsi din faleza, cazuti de-a curmezisul
			# drumului (#244) — in locul lamei albe cu dungi, care pe o pista de
			# canion se citea ca mobilier de santier.
			"deflector_model": "res://assets/models/rocks/rock_large.glb",
			"deflector_node": "Rock_Large",
			"deflector_scale": 1.15,
			# Morisca devine MOARA DE VANT (#245): pe un drum de desert cu ferma
			# si moara la orizont, o morisca de balci nu avea ce cauta. Turnul e
			# cladirea reala din kit, langa drum; peste sosea trec aripile.
			"carousel_model": "res://assets/models/buildings/windmill.glb",
			"carousel_scale": 1.0,
			# Aceleasi clase ca moara decorativa din `_LANDMARKS` (id 2): moara
			# are lemn SI metal, deci nu poate lua o clasa pe tot subarborele.
			# `Mill_Trim` ramane pe atlas — vana albastra e singurul accent de
			# culoare al morii.
			"carousel_classes": {"Mill_Wood": "wood", "Mill_Metal": "rust_metal",
				"Blades": "rust_metal"},
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
		# --- Muntele de vara (pista Alpii) ---
		#
		# Nu e "forest cu alt cer". Diferentele care conteaza, toate din lumea
		# reala si toate verificabile pe un snapshot:
		#
		# 1. AERUL E SUBTIRE. La altitudine cerul e mai adanc si mai rece la
		#    zenit, iar ceata e albastruie (imprastiere Rayleigh pe distanta),
		#    nu alb-laptoasa ca la nivelul marii. De aceea fog e mai albastru
		#    decat cerul de la orizont, invers decat la desert.
		# 2. UMBRELE SUNT RECI. Ambientul vine din CULOARE, nu din cer, exact
		#    din motivul masurat pe insula: cerul singur trage tot verdele spre
		#    cenusiu. Culoarea aleasa e bounce-ul de pe pajiste — verde palid
		#    cald, nu gri.
		# 3. VERDELE E DE PAJISTE ALPINA, nu de padure tropicala: mai galben si
		#    mai putin saturat decat "forest" (#73B854 fata de un verde crud),
		#    fiindca iarba de munte in august e uscata la varf.
		#
		# sun_energy 1.15 si nu 1.25 ca la forest: aici soarele bate pe un
		# teren care URCA, deci flancurile orientate spre lumina primesc
		# incidenta mai buna si se supraexpun la aceeasi energie. Diferenta
		# e vizibila pe umarul masivului, unde panta e de 35-40%.
		"alpine": {
			# Pajiste de munte in august, NU gazon: verdele lui "forest"
			# (0.45, 0.72, 0.33) iesea fluorescent pe prima randare — e acordat
			# pentru o padure in umbra, iar aici cade pe pante intregi luminate
			# direct. Coborat in saturatie si impins spre galben-oliv, adica
			# spre iarba uscata la varf. Verificabil pe captura de sus: masa
			# verde trebuie sa citeasca a fan tanar, nu a masa de biliard.
			"ground_tint": Color(0.44, 0.60, 0.31),
			# Cer de altitudine: zenit adanc, orizont palid si RECE.
			"sky_top": Color(0.16, 0.42, 0.86),
			"sky_horizon": Color(0.74, 0.86, 0.97),
			# Ceata albastruie — vezi punctul 1 de mai sus.
			"fog": Color(0.72, 0.83, 0.94),
			"hill_color": Color(0.36, 0.56, 0.38),
			"sun_color": Color(1.0, 0.97, 0.90),
			"sun_energy": 1.15,
			"exposure": 1.0,
			"ambient_color": Color.html("C8D8B8"),
			"ambient_energy": 0.26,
			# Ceata de ADANCIME, ca la desert si insula: de pe platou vezi pana
			# in vale, iar crestele de fundal trebuie sa se piarda progresiv,
			# nu sa fie taiate de un plan de ceata uniform.
			"fog_depth": true,
			# Crestele de fundal (#225): un singur model, folosit la scari si
			# rotatii diferite de inelele de orizont. Are deja benzile pictate
			# in sloturi — padure la poale, granit la mijloc, zapada peste
			# 38 m — deci silueta ADUCE cu ea povestea de altitudine, fara
			# niciun cost de material.
			"horizon_model": "res://assets/models/rocks/mountain_peak.glb",
			# Un singur nod in GLB, deci acelasi nume pe toate inelele. Varietatea
			# vine din scara si din rotatie, nu din forme diferite — la 300 m si
			# prin ceata, doua siluete rotite 90° citesc ca doi munti.
			"horizon_picks": [["MountainPeak"], ["MountainPeak"],
				["MountainPeak"]],
			# DOUA clase pe prefix de nod, nu una pe tot modelul si nu atlasul.
			#
			# Istoric: `horizon_class: "rock"` (implicitul) intindea gresia
			# canionului peste tot varful si crestele ieseau portocalii; apoi
			# `horizon_class: ""` lasa atlasul, cu benzile pictate in sloturi —
			# padure/granit/zapada — dar benzile erau culori UNIFORME cu granita
			# dura pe fete, si muntii citeau a carton langa stancile de drum
			# deja texturate cu `alpine_granite`. Din august 2026 GLB-ul e spart
			# pe doua noduri (vezi build_alpine_nature.py): corpul primeste
			# granitul stancilor de langa sosea, calota primeste zapada masei de
			# avalansa. Aceeasi piatra in fundal si in prim-plan. Padurea de la
			# poale ramane tenta de vertex color, deci nu are nevoie de nod.
			"horizon_classes": {"MountainPeak": "tri:alpine_granite",
				"PeakSnow": "tri:snow"},
			# Inele PROPRII: varful e de trei ori cat un butte de desert, deci
			# vrea distanta mai mare si numar mai mic. Degajarea de 150-210 m e
			# masurata contra esecului: cu cea implicita (95 m pe inelul
			# apropiat) niciuna din cele 10 siluete n-a incaput pe o pista de
			# 535x400 m. Scarile RAMAN mici (0.8-1.4): la 92 m nominal, un varf
			# la scara 2.4 ar fi un zid de 220 m care inghite tot cerul.
			# Cotele astea sunt LEGATE INTRE ELE — se schimba impreuna sau
			# deloc:
			#   ChaseCamera.FAR_PLANE = 380 m  <- plafonul absolut; orice
			#     silueta dincolo e taiata din frustum.
			#   fog_end = 370 m                <- ce nu inghite ceata.
			#   inelele: 190 -> 355 m          <- incap sub amandoua.
			# Prima incercare le pusese la 300-500 m: 13 siluete asezate
			# corect si ZERO vizibile, taiate de ceata la 250 si de camera
			# la 380.
			# Degajarea a mai coborat o data, tot din masuratoare: la 120/145/165
			# treceau 8 din 13 (pista are 535x400 m, deci sectoarele dinspre
			# lungimea ei n-aveau unde sa puna un varf). La 95/115/140 intra
			# toate 13. Nu e o slabire a regulii — un varf de fundal la 95 m de
			# sosea e tot dincolo de orice banda de decor (far se opreste la
			# 58 m), deci nu se poate ciocni cu nimic.
			"horizon_rings": [
				{"near": 190.0, "far": 240.0, "count": 4, "scale": 0.80,
					"clear": 95.0, "picks": ["MountainPeak"]},
				{"near": 240.0, "far": 300.0, "count": 5, "scale": 1.05,
					"clear": 115.0, "picks": ["MountainPeak"]},
				{"near": 300.0, "far": 355.0, "count": 4, "scale": 1.30,
					"clear": 140.0, "picks": ["MountainPeak"]},
			],
			# Ceata merge pana aproape de planul camerei: intr-un peisaj alpin
			# distanta mare E subiectul, iar la 250 m crestele nu existau
			# pentru ochi. Vezi _build_environment.
			"fog_begin": 130.0,
			"fog_end": 370.0,
			# DRUM DE MUNTE DESCHIS, nu pista de curse.
			#
			# Restul lumii primeste gard rosu continuu pe exterior; aici NU. Un
			# drum alpin care traverseaza pasuni si platouri n-are parapet pe
			# toata lungimea lui, iar panglica rosie taia exact senzatia pe care
			# o cere pista: esti sus, in gol, si nimic nu te tine.
			#
			# `walls: false` scoate SI coliziunea, deliberat — asta e chiar
			# cererea: masina poate iesi pe pasune, poate lua o linie larga, poate
			# rata un viraj si continua pe iarba (lenta, 45%) in loc sa se
			# lipeasca de un zid invizibil. Regimul de risc ramane declarat in
			# teren, nu in bariere: unde caderea chiar conteaza — cornisa
			# traversarii, rapa de sub fly-off — o face `_ravines()`, iar
			# RespawnZone repune masina care cade in gol.
			#
			# Consecinta pe _rail_segments(): stalpii de RAIL_POSTS de pe cornisa
			# se adunau in _build_walls(), care acum nu mai ruleaza, deci dispar
			# odata cu gardul. Nu e o pierdere — rolul lor era sa marcheze
			# EXCEPTIA intr-un tur cu gard peste tot; fara gard, exceptia e
			# regula si marcajul n-ar mai spune nimic.
			"walls": false,
			# Bordurile rosu-alb pleaca odata cu gardul, si e aceeasi decizie:
			# amandoua spun „circuit", iar pista asta vrea sa spuna „drum".
			# Vezi _build_kerbs.
			"kerbs": false,
			"cliffs": false,     # flancurile masivului sunt teren, nu faleze de canion
			"decor": "bands",
			"props": "alpine",
			# ZAPADA PE CREASTA: mecanismul "inland_tint" al insulei, intors.
			#
			# Acolo verdele venea PESTE o cota (plaja jos, vegetatie sus); aici
			# albul vine peste o cota mult mai sus. E acelasi cod si aceeasi
			# cheie — vezi _build_terrain — fiindca intrebarea e identica: "de
			# la ce inaltime terenul isi schimba materialul?".
			#
			# 72 m NU e ales din ochi, e MASURAT cu tools/ProbeAlpineTerrain:
			# platoul drumului sta la 63.2 m, terenul urca la 104.2 m, dar
			# distributia de cote e ascutita — doar 0.67% din suprafata trece
			# de 70 m, si 0.48% de 78 m. Prima incercare la 78 punea zapada pe
			# 0.48% din lume, adica doua pete cat o moneda pe o captura de sus.
			#
			# 72 pastreaza garda de 9 m peste cel mai inalt asfalt (zapada nu
			# atinge pista, ceea ce ar fi absurd in august) si dubleaza flancul
			# alb. Peste asta, `snow_fade` mai lat (18 m) face ca trecerea sa
			# ocupe ea insasi o bucata de munte: la altitudine limita zapezii nu
			# e o linie, e o zona in care petice albe coboara pe vaiugi.
			"snow_line": 72.0,
			"snow_fade": 18.0,
			"snow_tint": Palette.color(Palette.FOAM_WHITE),
			# ZAPADA PE ASFALT: petice, nu un strat.
			#
			# Terenul isi ia albul de la o COTA (snow_line, 72 m) — asa se
			# comporta o limita de zapada pe munte. Soseaua nu poate folosi
			# aceeasi regula: cel mai inalt asfalt sta la 63 m, adica sub linie,
			# deci pe cota drumul ar ramane negru pe tot turul. Si e corect ca
			# regula: un drum e DESZAPEZIT si CALCAT de roti, deci pastreaza
			# petice acolo unde plugul si traficul n-au ajuns, nu un strat
			# continuu care urmeaza cota.
			#
			# De aceea peticele de aici sunt un tipar de ZGOMOT modulat de
			# altitudine: exista peste tot, dar se indesesc cu inaltimea. Jos in
			# sat (0 m) asfaltul e curat, pe culme (63 m) e patat serios — adica
			# exact povestea pistei, "un tur = o urcare", spusa si de suprafata
			# pe care conduci.
			#
			# ZAPADA DE PE DRUM INCEPE UNDE INCEPE CEA DE PE TEREN, si asta e o
			# corectie facuta pe captura, nu pe tabel.
			#
			# Primele doua versiuni derivasera cotele din profilul SOSELEI (sonda
			# de cote: min -0.4 · mediana 38.2 · max 107.8 m) si porneau albul de
			# la 20 m. Cifrele erau masurate corect si rezultatul era gresit: la
			# fractia 0.30 drumul iesea deja cenusiu prin PASUNE VERDE, fara un
			# fulg de zapada in tot cadrul. Zapada pe asfalt intr-o lume fara
			# zapada nu se citeste ca zapada, se citeste ca beton decolorat.
			#
			# Cotele sunt acum LEGATE de linia zapezii terenului (`snow_line` 72,
			# `snow_fade` 18 — deci terenul se albeste intre 72 si 90 m):
			#   80 m  primele petice pe asfalt, cand pe margini deja e alb
			#   105 m densitate maxima, pe cel mai inalt asfalt masurat
			# Drumul ramane cu o intarziere fata de teren, si asta e chiar
			# adevarul fizic: un drum e batatorit si deszapezit, deci se albeste
			# mai tarziu si mai putin decat pajistea de langa el.
			#
			# Daca se muta `snow_line`, se muta si astea — sunt aceeasi poveste
			# spusa pe doua suprafete.
			"road_snow_low": 80.0,
			"road_snow_high": 105.0,
			# Cat de ALB iese un petic la cota maxima (nu cat de des apare — de
			# desime se ocupa pragul din _road_snow_weight). 0.85 face peticul
			# sa fie zapada adevarata acolo unde e; ce tine linia de curs
			# citibila nu e paloarea lui, ci faptul ca sta pe margini si ca
			# banda de rulare ramane curata (style_bible §1).
			"road_snow_amount": 0.85,
			"road_snow_tint": Palette.color(Palette.FOAM_WHITE),
			# BANDA DE STANCA dintre pajiste si zapada.
			#
			# Un munte adevarat are trei etaje, si lipsea cel din mijloc: pana
			# la #229 terenul trecea direct din verde in alb, deci masivul
			# citea ca un deal cu glazura. Cu masivul central urcat la 154 m
			# (de la 104), etajul lipsa a devenit vizibil de pe drum, nu doar
			# dintr-o captura de sus — de la 60 m in sus, pe cornisa, ai un
			# perete de iarba unde ar trebui sa fie piatra.
			#
			# 46 m e cota de la care iarba se rareste. NU e aleasa rotund: pe
			# traversare soseaua urca de la 54 la 63 m, deci o linie mai sus ar
			# fi lasat exact bucata pe care o conduci tot verde, iar una mai
			# jos ar fi impietrit si pasunea din vale (care sta sub 40 m).
			# Trecerea larga (20 m) e din acelasi motiv ca la zapada: la munte
			# limita padurii e o zona, nu o linie.
			#
			# Culoarea NU e Palette.ROCK_LIGHT, si asta e o abatere declarata:
			# slotul ala e #C18446, gresie calda de canion („maro", scrie chiar
			# in palette.gd), iar prima incercare a facut din masivul alpin o
			# duna portocalie — se vede in captura de sus. Granitul din foaia
			# de referinta a kitului e #8A8980, gri-verzui rece.
			#
			# Se pune ca nuanta de TEMA, nu ca slot nou in atlas: e o culoare
			# de vertex peste terenul care are deja textura de clasa, deci nu
			# adauga niciun material — exact conditia din CLAUDE.md. Un slot
			# nou ar fi insemnat regenerarea atlasului si recalibrarea
			# expunerii pentru toate pistele.
			"rock_line": 46.0,
			"rock_fade": 20.0,
			"rock_band_tint": Color.html("8A8980"),
			# IARBA DENSA pe marginea drumului (prototip TrackGrass): pajistea
			# alpina e pista pe care firele vizibile vand cel mai mult lumea.
			# Plafonul e sub rock_line (46): iarba se rareste si dispare INAINTE
			# ca terenul sa devina piatra, nu exact pe linia lui.
			"dense_grass": true,
			"dense_grass_max_y": 42.0,
			# Granit ADEVARAT, nu o nuanta peste gresie.
			#
			# Pana la texturile PolyHaven, muntele imprumuta roca de canion si o
			# racea cu `rock_tint` — o compensare peste doua straturi calde
			# (textura de gresie + vertex colors coapte), calibrata in doi pasi
			# pe captura ca sa nu iasa portocalie. Functiona, dar era un filtru
			# de culoare peste piatra gresita.
			#
			# `rock_class` inlocuieste mecanismul cu unul mai simplu: sisturi
			# stratificate reale, gradate spre paleta. Nuanta ramane in cod
			# (`rock_tint`) pentru orice lume care vrea gresie colorata altfel,
			# dar aici nu mai e nevoie de ea — piatra e deja piatra de munte.
			"rock_class": "alpine_granite",
			"hazard_model": "res://assets/models/vehicles/timber_sled.glb",
			"hazard_roll": false, # o sanie nu se rostogoleste (vezi barca sabani)
			"dust_color": Color(0.62, 0.58, 0.44), # pamant de pajiste, nu nisip
			# Nu exista MARE pe pista asta, dar exista un canal cu apa (paraul
			# din vale, vezi Track09._channel_specs): steagul de mai jos ramane
			# false, iar apa de canal se construieste separat.
			"water": false,
			# Apa de munte, nu laguna. Fara sloturile astea, `_sea_color` ar
			# folosi recif+larg (turcoaz tropical) si paraul iesea o lagunca
			# intre brazi — asa arata prima randare in snapshots/alpii.png.
			#
			# Nu se aloca sloturi noi in atlas. Prima incercare a fost
			# CONCRETE + ROCK_DARK si a iesit un ghetar: CONCRETE e #C8BDA9,
			# adica un bej CALD (r > g > b) — de aproape nu se mai citea ca
			# apa, ci ca prundis. PAINTED_METAL (#7692A8) e singurul
			# albastru-cenusiu rece din paleta si e exact culoarea unei ape de
			# munte; adancul ramane SEA_DEEP (#2E5F6B), care nu e tropical prin
			# el insusi — turcoazul venea din REEF_SHALLOW.
			#
			# CAR_BLUE ar fi fost mai saturat, dar sloturile 14..16 sunt
			# rezervate masinilor tocmai ca ele sa "sara" din decor.
			"water_shallow_slot": Palette.PAINTED_METAL,
			"water_deep_slot": Palette.SEA_DEEP,
			# Poteca scurtaturii: pamant batatorit, nu nisip coraligen umed.
			# Pietrisul e textura care exista si care se potriveste — o poteca
			# de pasune calcata de vaci si de roti E pamant cu pietre, iar
			# granulatia ei se citeste ca "nu mai esti pe asfalt" din mers.
			"branch_tint": Color(0.52, 0.44, 0.30),
			"branch_texture": "res://assets/textures/surface_gravel.png",
			# ...si reteta „drum de tara" (fagase, brazda de iarba, margini
			# zdrentuite, smocuri): pana aici banda era o panglica plata in
			# nuanta de mai sus, si de la 20 m se citea ca un dreptunghi maro
			# lipit peste pajiste. Un nod TrackBranch poate suprascrie reteta
			# (`surface`), tema da doar implicitul lumii.
			"branch_surface": "dirt_road",
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
		#   godot --path . res://tools/Snapshot.tscn -- --track=1 --size=300
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
			# Deflectorul: busteni de driftwood aruncati de mare de-a curmezisul
			# drumului (#244). Pe o insula, lemnul adus de valuri e cel mai
			# firesc lucru cazut peste sosea — si e deja in kitul de plaja.
			"deflector_model": "res://assets/models/scatter/beach_clutter.glb",
			"deflector_node": "Driftwood_Log",
			"deflector_scale": 1.0,
			"deflector_class": "wood",
			"water": true,       # apa mare deschisa (vezi _build_water)
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
		# --- Lacul inghetat (pista Baikal, docs/track_briefs/baikal.md) ---
		#
		# Iarna pe Olkhon: jumatate de tur PE gheata, jumatate pe mal. Cheile
		# care conteaza si de ce:
		#
		# 1. `water` + `frozen`: marea e o PLACA — se randeaza ca gheata si are
		#    coliziune (vezi _build_water). Soseaua de pe lac sta la cativa cm
		#    peste ea, in `_ice_ranges`, iar restul terenului de langa drum e
		#    sub placa, deci gheata citeste continua pana la banda.
		# 2. Zapada e PESTE TOT pe uscat: `snow_line` la 0.5 m (linia ghetii e
		#    la 0), cu iarba uscata galbena care iese pe langa mal — aceeasi
		#    mecanica de cota ca pe Alpi, doar ca linia e jos.
		# 3. Soare JOS (~15°), lumina calda, umbre lungi si albastre din
		#    ambient — dupa-amiaza de februarie, nu amiaza. Cer alb-laptos spre
		#    roz la orizont, ceata alba.
		# 4. `wind`: vantul de pe lac (dinspre larg, adica din SE, spre NV), cu
		#    rafale — sufla doar pe portiunile de gheata (vezi wind_at). Pe
		#    gheata cu grip 1.5 iti muta linia; steguletele il arata.
		#
		# Decorul (`props: baikal`, varianta de iarna a celui alpin — fara
		# flori, fan, garduri) e PROVIZORIU pana vine kitul de larici/mesteceni. Fara pereti si borduri pe gheata
		# (le taie `_road_ice`), cu borduri pe mal.
		"baikal": {
			"ground_tint": Palette.color(Palette.DRY_VEGETATION),
			"sky_top": Color(0.52, 0.66, 0.84),
			"sky_horizon": Color(0.95, 0.88, 0.86),
			"fog": Color(0.90, 0.90, 0.92),
			"hill_color": Color(0.84, 0.87, 0.90),
			"sun_color": Color(1.0, 0.90, 0.78),
			"sun_energy": 1.0,
			"sun_rotation_deg": Vector3(-24, 135, 0),
			"exposure": 1.0,
			"ambient_color": Color.html("C4D2E6"),
			"ambient_energy": 0.32,
			"fog_depth": true,
			"fog_begin": 120.0,
			"fog_end": 330.0,
			"horizon_model": "res://assets/models/rocks/mountain_peak.glb",
			"horizon_picks": [["MountainPeak"], ["MountainPeak"],
				["MountainPeak"]],
			"horizon_classes": {"MountainPeak": "tri:snow",
				"PeakSnow": "tri:snow"},
			"horizon_rings": [
				{"near": 190.0, "far": 240.0, "count": 4, "scale": 0.70,
					"clear": 95.0, "picks": ["MountainPeak"]},
				{"near": 240.0, "far": 300.0, "count": 5, "scale": 0.90,
					"clear": 115.0, "picks": ["MountainPeak"]},
			],
			"walls": false,
			"kerbs": true,
			"cliffs": false,
			"decor": "bands",
			"props": "baikal",
			"snow_line": -0.2,
			"snow_fade": 1.5,
			"snow_tint": Palette.color(Palette.FOAM_WHITE),
			"road_snow_low": 2.0,
			"road_snow_high": 14.0,
			"road_snow_amount": 0.7,
			"road_snow_tint": Palette.color(Palette.FOAM_WHITE),
			"rock_class": "alpine_granite",
			"rock_tint": Color(0.86, 0.88, 0.92),
			"hazard_model": "res://assets/models/vehicles/timber_sled.glb",
			"hazard_roll": false,
			"dust_color": Color(0.90, 0.94, 0.97),
			"water": true,
			"frozen": true,
			"seabed_drop": 12.0,
			"ice_grip": 1.5,
			"ice_road_tint": Color(0.74, 0.90, 0.95),
			"wind": Vector3(-2.2, 0.0, -2.2),
			"wind_gust": 0.5,
			"branch_tint": Color(0.86, 0.90, 0.94),
			"branch_surface": "gravel",
		},
		# --- Insula vulcanica (pista Stromboli, docs/track_briefs/stromboli.md) --
		#
		# Sfarsit de dupa-amiaza pe un vulcan activ in Mediterana. Cheile care
		# conteaza si de ce:
		#
		# 1. Trei etaje de culoare pe ACELASI mecanism ca insula + Alpii:
		#    `ground_tint` negru vulcanic la nivelul marii (plaja neagra),
		#    `inland_tint` verde prafuit peste fasia de plaja (tufaris),
		#    `snow_line` la 48 m cu "zapada" GRI (MARBLE_GREY) = capul de cenusa
		#    al conului. Niciun cod nou — doar valori.
		# 2. Soare JOS (~20°), cald, dinspre mare — ora la care emisivul lavei
		#    (PR-ul hazardului) incepe sa se citeasca fara sa fie noapte.
		# 3. `fog_end` 300, peste ce cer alte teme calde: de pe buza craterului
		#    (70 m) diagonala pana la sat e ~280 m, iar dezvaluirea din brief
		#    (§2.0) exista doar daca satul ramane sub ceata. Cotele raman legate:
		#    inele orizont < fog_end < FAR_PLANE 380.
		# 4. `walls: false`, ca pe Alpi, si din acelasi motiv: e drum de munte
		#    deschis, nu circuit. Riscul e declarat in teren (buza craterului,
		#    marginea spre mare) prin `custom_ravines` + RespawnZone.
		#
		# Decorul e pe kitul mediteranean propriu (`props: "stromboli"`) de la
		# integrarea celor 12 piese de flanc; a stat provizoriu pe props insulare
		# — palmieri si coral — exact cum Baikal a stat pe props alpine.
		"stromboli": {
			"ground_tint": Palette.color(Palette.VOLCANIC_BLACK),
			"sky_top": Color(0.28, 0.50, 0.82),
			"sky_horizon": Color(0.86, 0.89, 0.88),
			"fog": Color(0.80, 0.85, 0.88),
			"hill_color": Color(0.40, 0.44, 0.42),
			# LUMINA E CE FACEA VULCANUL SA ARATE A PLAJA.
			#
			# Terenul de pe buza avea deja culoarea corecta — masurat direct in
			# mesh, COLOR = (0.235, 0.231, 0.251), adica bazalt inchis, iar cele
			# patru texturi de suprafata sunt gri neutru (media 215). Si totusi
			# la volan iesea nisip cald, (132, 111, 89).
			#
			# Cauza era aici: soare chihlimbariu (1.0, 0.88, 0.72) la energie
			# 1.30, plus ambiental D8C4A8 (bej) si ceata calda de la 110 m.
			# Socoteala da (139, 131, 124) pe un albedo neutru inchis — exact ce
			# se vedea. Atmosfera era copiata din desert, unde apusul auriu e
			# tocmai ideea; pe o insula eoliana la amiaza lumina e ALBA si dura,
			# iar cenusa trebuie sa ramana cea mai inchisa suprafata din cadru.
			#
			# Am pierdut trei incercari retusand albedo-uri (snow_tint,
			# rock_class) fiindca am presupus ca o suprafata palida are o culoare
			# palida. Verificarea care a rupt bucla n-a fost o captura, ci
			# citirea culorilor de vertex din mesh plus inmultirea cu lumina.
			"sun_color": Color(1.0, 0.98, 0.95),
			"sun_energy": 0.95,
			"sun_rotation_deg": Vector3(-46, 210, 0),
			"exposure": 1.0,
			"ambient_color": Color.html("9FB0BF"),
			# AMBIENTALUL E CE UMPLE RAPELE, si pista asta e facuta din rape.
			#
			# La 0.18 (cel mai mic din joc — restul temelor sunt la 0.22-0.32)
			# fetele intoarse de la soare primeau aproape nimic: masurat pe un
			# cadru de pe buza craterului, peretii erau la (9,13,17)-(14,18,22)
			# si 54.6% din cadrul util cadea sub luminanta 40. Prapastia exista
			# in geometrie, dar pe ecran era o pata neagra plata — nu se citea
			# nici adancimea, nici ca e roca.
			#
			# Umbra o face ocluzia si contrastul cu soarele, nu lipsa luminii.
			"ambient_energy": 0.34,
			"fog_depth": true,
			"fog_begin": 150.0,
			"fog_end": 300.0,
			# Panarea si Salina: doua siluete joase, albastrui, pe orizont.
			# Refolosesc modelul insulelor Okinawa — la 200+ m prin ceata calda
			# citesc ca insule vecine, nu ca recif tropical.
			"horizon_model": "res://assets/models/effects/horizon_island.glb",
			"horizon_picks": [
				["Island_Ridge", "Island_Low"],
				["Island_Peak"],
			],
			"horizon_class": "coral_rock",
			"horizon_rings": [
				{"near": 200.0, "far": 250.0, "count": 2, "scale": 0.85,
					"clear": 110.0, "picks": ["Island_Ridge", "Island_Low"]},
				{"near": 250.0, "far": 295.0, "count": 2, "scale": 1.10,
					"clear": 130.0, "picks": ["Island_Peak"]},
			],
			# TREI ETAJE DE CULOARE PE CON (brief §5.5), nu verde peste tot.
			#
			# Prima versiune a copiat `inland_tint` de la Okinawa: verde
			# tropical la 0.75 peste tot interiorul insulei. Captura de sus a
			# iesit o insula VERDE cu drum galben — adica Okinawa cu alt
			# traseu, nu un vulcan. Pe Stromboli verdele are voie doar la
			# POALE; de la ~18 m in sus incepe scoria, iar de la ~48 m cenusa.
			#
			# Etajele se fac cu mecanismele care exista deja, nu cu cod nou:
			#   - `inland_tint`  = etajul verde, slabit la 0.40 si oprit de
			#                      banda de roca de deasupra lui
			#   - `rock_band_tint` (mecanismul alpin) = scoria, de la 18 m
			#   - `snow_tint`    = capul de cenusa, de la 48 m
			# Toate trei sunt culori de VERTEX peste terenul existent: zero
			# materiale noi, zero sloturi noi (conditia din CLAUDE.md).
			"inland_tint": Palette.color(Palette.TROPICAL_GREEN),
			"inland_strength": 0.40,
			# Etajul de scorie: incepe jos (18 m) fiindca vegetatia de pe
			# Stromboli se opreste repede — insula e conul, nu are platou.
			# `rock_fade` mare (16) ca trecerea sa fie o zona, nu o linie.
			"rock_line": 18.0,
			"rock_fade": 16.0,
			"rock_band_tint": Palette.color(Palette.VOLCANIC_BLACK).darkened(0.42),
			# Capul de cenusa: mecanismul zapezii, cu gri in loc de alb.
			"snow_line": 48.0,
			"snow_fade": 9.0,
			# CENUSA PROASPATA, nu zapada. Mecanismul se numeste "snow" fiindca
			# s-a nascut pe Alpi, unde etajul de sus e cel mai DESCHIS. Pe un
			# vulcan e exact invers: verdele se opreste jos, iar spre crater
			# roca devine tot mai neagra, fiindca acolo cade cenusa proaspata.
			#
			# Prima versiune a pus MARBLE_GREY (182,178,170) ca sa citeasca a
			# "cap de cenusa". De pe buza, la volan, iesea NISIP: un varf palid
			# si cald langa asfaltul inchis — plaja Dunelor pusa pe vulcan.
			# Toata buza sta peste 48 m (54-60 m masurati), deci nu era o dunga
			# de sus, era toata scena.
			"snow_tint": Palette.color(Palette.VOLCANIC_BLACK).darkened(0.62),
			"walls": false,
			"kerbs": false,
			"cliffs": false,
			"decor": "bands",
			# Kitul mediteranean (docs/asset_briefs/stromboli_slope_kit.md).
			# Pana la el pista a imprumutat props-urile insulare — palmieri si
			# coral — exact cum Baikal a stat pe props alpine pana la kitul lui.
			"props": "stromboli",
			# BAZALT, nu gresie. Clasa "rock" e dala de desert (medie
			# (141, 97, 58)) si NU trece prin `_tint_rock` — compensarea aia se
			# aplica doar cand `rock_class` e gol (track_decor.gd:1654). Deci pe
			# buza craterului ieseau bolovani de nisip cald, masurati la volan
			# ca (132, 111, 89): plaja Dunelor pusa pe vulcan.
			#
			# Clasa nu se putea tenta pe loc: "rock" e si `horizon_class`
			# implicit pentru toate temele, si `rock_material()` comun.
			# `volcanic_rock` foloseste ACELASI PNG cu alt multiplicativ — zero
			# textura in plus, zero atingere pe celelalte piste.
			"rock_class": "volcanic_rock",
			"water": true,
			"seabed_drop": 26.0,
			# Nisip negru vulcanic pe drum si pe plaja, nu nisipul auriu
			# implicit (vezi dirt_road_color). Nu e VOLCANIC_BLACK curat:
			# nisipul batatorit de roti e putin mai deschis si mai cald decat
			# bazaltul de langa el, altfel drumul dispare in teren.
			# Cenusa si nisipul negru adanc: 0.85x fata de asfalt (brief §3),
			# adica 6.8 pe scara grip-ului. Intre asfalt (8) si ud (3.6) —
			# aluneci, dar nu patinezi.
			# TARM ABRUPT, nu recif: conul vulcanic intra direct in apa.
			# Singur, reglajul asta NU apropie apa de plaja (masurat: banda
			# se masoara fata de poligonul buclei, iar plaja e la ~80 m
			# INAUNTRUL lui) — de asta traseul a fost si impins spre coasta.
			# Ramane fiindca face tarmul sa citeasca vulcanic pe tot turul.
			"shore_band_in": 14.0,
			"shore_band_out": 30.0,
			"loose_grip": 6.8,
			# MARE VULCANICA, nu lagună. Sloturile implicite (recif turcoaz +
			# larg) descriu un atol cu fund de nisip alb la doi metri. Stromboli
			# cade abrupt: conul intra direct in apa, fundul e bazalt negru, iar
			# adancimea incepe de la mal. Cu turcoazul de recif, plaja de la POI
			# B citea ca Okinawa cu alt drum — aceeasi capcana ca paraul din
			# Alpi, unde recif+larg dadeau o lagunca intre brazi.
			#
			# Fara slot nou: SEA_DEEP tine acum apa de langa mal, iar ICE_CRACK
			# (albastru aproape negru) tine largul. Atlasul e comun tuturor
			# pistelor, deci un slot in plus s-ar plati pe toate.
			"water_shallow_slot": Palette.SEA_DEEP,
			"water_deep_slot": Palette.ICE_CRACK,
			"dirt_road_tint": Color(0.34, 0.32, 0.33),
			"dust_color": Color(0.28, 0.26, 0.27),
			"branch_tint": Color(0.30, 0.28, 0.30),
			"branch_surface": "gravel",
		},
		"chongqing": {
			# NOAPTE CU BURNITA, ORAS CONSTRUIT PESTE EL INSUSI (brief §0.1, §4).
			# Prima tema de noapte: lumina nu vine de la soare, ci de la oras —
			# ambientul gri-violaceu e "cerul luminat de jos", iar "soarele" e o
			# luna rece, aproape verticala, doar cat sa dea volum. Fara umbre:
			# n-are ce arunca o luna la 0.35, iar pe mobil e si setarea cea mai
			# scumpa (CLAUDE.md). Ceata 150 -> 250, gri-violacee: turnurile de
			# peste rau se sting in ea firesc (§2.0).
			"ground_tint": Palette.color(Palette.CONCRETE).darkened(0.70),
			# Cer de oras innorat: gradient albastru-gri INCHIS, nu violet
			# saturat (runda 1 iesea mov de afis). Orizontul e putin mai
			# deschis decat zenitul — orasul lumineaza norii de jos (§4) — iar
			# ceata e in aceeasi familie, cu o idee de violet, nu mai mult.
			"sky_top": Color(0.045, 0.05, 0.075),
			"sky_horizon": Color(0.17, 0.18, 0.24),
			"fog": Color(0.25, 0.25, 0.31),
			"hill_color": Color(0.12, 0.13, 0.17),
			# Fara disc de soare (luna e in ceata, nu se vede) si norii aproape
			# stinsi: la 0.35 stratul de nori ADUNAT peste gradientul intunecat
			# facea o pata alburie la zenit.
			"sky_sun_disc": false,
			# FARA oras pictat in cer, si merita spus de ce ca sa nu se
			# reincerce: s-a construit (PR #365), arata bine din vederile
			# libere, si NU SE VEDE DE LA VOLAN. Cifra o spunea de la inceput —
			# `ChaseCamera` vede ~5 grade deasupra orizontalei (brief §2.0),
			# adica 14 px din cei 256 ai semisferei, iar banda aia e exact
			# acolo unde stau terenul, cladirile si parapetul. Turnurile
			# pictate incepeau de la 1.2 grade, deci partea lor vizibila era
			# integral ACOPERITA de geometrie.
			#
			# Adancimea la orizont, daca se mai vrea, trebuie sa vina din ceva
			# ce intra in frustum: siluete 3D APROAPE (sub 5 grade, deci sub
			# ~20 m la 250 m distanta) sau nimic. Un strat de cer nu poate.
			"sky_cover_alpha": 0.08,
			"sun_color": Color(0.78, 0.84, 1.0),
			"sun_energy": 0.35,
			"sun_rotation_deg": Vector3(-78, 200, 0),
			"exposure": 1.0,
			"ambient_color": Color.html("66667A"),
			"ambient_energy": 0.40,
			"shadows": false,
			"fog_depth": true,
			"fog_begin": 150.0,
			"fog_end": 250.0,
			# Fara insule pe orizont: siluetele de turnuri vin din DecorManual.
			"horizon_rings": [],
			"walls": false,
			"deck_rails": true,
			"kerbs": false,
			"cliffs": false,
			# Fara decor procedural: orasul se aseaza de mana (DecorManual), nu
			# din benzi de vegetatie.
			"decor": "none",
			# INERT cat timp "decor" e "none": `props` ajunge in
			# TrackDecor.build, care cu "none" nu aseaza nimic. Ramane
			# "stromboli" fiindca ala e ce s-a masurat, nu fiindca orasul ar
			# imprumuta ceva de pe vulcan — kitul Chongqing isi ia clasele din
			# `TrackDecor.CHONGQING_CLASSES`, pe nume de nod, nu prin cheia
			# asta. Daca pista capata vreodata benzi procedurale, aici se pune
			# un set propriu.
			"props": "stromboli",
			"rock_class": "volcanic_rock",
			# Doua rauri de culori diferite (Jialing verde, Yangtze brun) — dar
			# apa are doar doua sloturi, dupa ADANCIME, nu dupa loc. Noaptea
			# amandoua trebuie sa fie INCHISE: TROPICAL_GREEN la mal iesea o
			# pata verde luminoasa in captura de sus, deci malul ia SEA_DEEP si
			# largul ICE_CRACK (aproape negru), ca pe Stromboli. Jialing verde /
			# Yangtze brun (SAND_SHADOW) raman pentru un shader pe plan de apa,
			# cand vine (brief §5 "plan de apa in doua culori"). Fara slot nou.
			# APA DE NOAPTE (runda 2). Shaderul apei e unshaded, deci sloturile
			# "inchise" iesisera tot o laguna de amiaza: turcoaz, spuma alba,
			# glint de soare. Acum sloturile chiar sunt cele doua rauri (verde
			# Jialing la mal, brun Yangtze in larg — dupa adancime, nu dupa
			# loc) si trec printr-o "lumina" de 0.30; spuma si scanteierea sunt
			# stinse, hula si treptele abia sugerate. Malul: pamant inchis.
			# RUNDA 3: verde/brun la 0.42 citeau ca PAJISTE (mata, fara nimic
			# care sa se miste, si mai deschisa decat cheiul); SEA_DEEP la
			# 0.55 + glint citea ca apa, dar TURCOAZ SATURAT (masurat pe
			# captura: saturatie mediana 0.65) — laguna de amiaza, nu rau de
			# noapte. RUNDA 4: inapoi la sloturile brief-ului (TROPICAL_GREEN
			# = Jialing verde tulbure la mal, SAND_SHADOW = Yangtze brun in
			# larg), dar trecute prin "water_desat" (trase spre gri in jurul
			# luminantei) si o tenta de oras gri-verde ("water_mul") — asta
			# le fereste si de pajistea rundei 2 (sunt INTUNECATE si tinute
			# in familie de glint) si de turcoazul rundei 3. Gate-ul rundei:
			# saturatie HSV mediana < 0.35, luminanta < 60, sclipiri pastrate.
			# RUNDA 5. Masurat pe capturile rundei 4: apa iesea la luminanta
			# 39-41 langa un uscat de 44-51 (raport 0.85-0.93 — practic aceeasi
			# valoare) si la nuanta 60-78 HSV, adica GALBEN-VERDE. Pe diorama,
			# aceleasi doua marimi masurate in bar/E_chei.png si overview.png
			# dau rau verde la nuanta 148-160, rau brun la 16-27, si apa mereu
			# SEPARATA in valoare de mal. Runda 4 nu masurase separarea, doar
			# "desaturat si inchis", si a trecut cu apa care citea miriste.
			#
			# De unde venea olivul, cauza reala: rampa apei e dupa ADANCIME, iar
			# runda 4 pusese verde la mal si BRUN in larg. Fiecare pixel de
			# adancime medie cadea intre verde si maro — media lor E oliv. Deci
			# aici raul nu se mai alege dupa adancime (`water_split`, o dreapta
			# in plan XZ), iar adancimea doar INTUNECA aceeasi culoare
			# (`water_deep_gain` / `water_shore_gain`). Fiecare rau ramane in
			# familia lui pe toata suprafata.
			# RUNDA 7. Ce a ramas dupa ce culoarea a fost calibrata pe diorama
			# (runda 6) si tot a picat cu "apa nu citeste ca apa": SUPRAFATA era
			# reglata, CONTEXTUL lipsea. Masurat pe bar/E_chei.png, semnalul de
			# lichid nu e pe apa — e zidul de chei de deasupra ei, slepul care
			# sta IN ea, felinarele ale caror reflexii sunt chiar sclipirile, si
			# malul de dincolo care o TERMINA. Un plan care se intinde pana la
			# orizont se citeste camp, oricat de bine i-ai nimeri nuanta. De
			# aici "quay_wall" si "far_shore" mai jos, plus scenografia din
			# DecorManual (tools/gen_decor_chongqing.gd).
			#
			# Culoarea s-a mai mutat o data, cu masuratoarea alaturi. Nuanta
			# ceruta era 130-155; runda 6 iesea 166 PE ECRAN desi tema calcula
			# 142 — diferenta o face ceata (fog 0.25,0.25,0.31, adica
			# albastru-violet) peste o apa care se vede la 60-200 m. Se
			# calibreaza deci pe captura, nu pe culoarea autorata. Acum:
			#   verde D (frac 0.30): mean 55.5  hue 147.2  sat 0.152
			#   diorama (E_chei):    mean 52.2  hue 141.6  sat 0.180
			#   brun pod (frac 0.52): mean 63.9  hue 30.0
			#   diorama (bratul auriu): mean 80.3  hue 28.1
			"water": true,
			# Jialing — verde tulbure. Un singur slot pe toata rampa.
			"water_shallow_slot": Palette.TROPICAL_GREEN,
			"water_deep_slot": Palette.TROPICAL_GREEN,
			"water_shore_slot": Palette.TROPICAL_GREEN,
			# Yangtze — brun noroios. RUST_METAL e cel mai jos ca nuanta din
			# paleta (21 grade); SAND_SHADOW, incercat intai, iesea la 44 dupa
			# tenta de oras, adica inca in galben. Un slot e o CULOARE, nu o
			# eticheta (nota din palette.gd) — nu se aloca unul nou, si oricum
			# slotul 31 era ultimul liber pe pista asta.
			"water_b_shallow_slot": Palette.RUST_METAL,
			"water_b_deep_slot": Palette.RUST_METAL,
			"water_b_shore_slot": Palette.RUST_METAL,
			# Adancimea = valoare, nu nuanta. Malul e cel mai inchis (umbra
			# cheiului) — de aici iese linia de mal neta pe care runda 4 o avea
			# pastoasa, fiindca trecea din maro-inchis in verde pe 8 m.
			"water_deep_gain": 0.72,
			"water_shore_gain": 0.62,
			# RUNDA 9: la 0.84 verdele iesea pe ecran la saturatie 0.13, sub
			# banda 0.18-0.28 masurata in diorama (verde 0.217). 0.76 il aduce
			# la ~0.19 fara sa-l scoata din familia de gri-verde.
			"water_desat": 0.79,
			# Tenta de oras trasa spre rece: cu (0.85,0.89,0.87) verdele iesea
			# la nuanta 123 (sub tinta 130-155). Cu asta: verde 142, brun 26.
			# RUNDA 9: cu (0.835, 0.915, 0.925) verdele masura 120 pe ecran, iar
			# in diorama e 148-152 — prea albastru, adica apa de piscina, nu de
			# rau. Albastrul coboara si rosul urca putin: nuanta se muta spre
			# verde-galbui fara sa ridice saturatia.
			"water_mul": Color(0.795, 0.900, 0.925),
			# Tenta raului brun. Vezi water_tint: cu tenta verde de mai sus
			# (albastru urcat, rosu coborat) Yangtze-ul iesea la saturatie 0.10 —
			# ocru-gri, adica nisip ud vazut de pe pod, nu apa. Cu asta: 0.35 la
			# nuanta 24, langa 0.37/29 masurate pe bratul auriu al dioramei.
			# RUNDA 9: cu (1.00, 0.98, 0.93) brunul iesea la saturatie 0.21 in
			# albedo, dar pe ECRAN, sub aurul reflexiilor, se masura 0.26-0.55
			# — culoare de pamant arat. Tenta se raceste pana aproape de
			# neutru: raul e NAMOL, iar namolul e gri-maroniu, nu ocru. Ce ii
			# tine nuanta calda e tot slotul (RUST_METAL), doar mai putin.
			"water_b_mul": Color(0.95, 0.93, 0.91),
			# Vezi water_tint: desaturarea verdelui (0.84) transforma brunul in
			# noroi. Diorama masurata: verde sat 0.18, brun sat 0.42.
			# RUNDA 9: tinta masurata pe corpul apei e saturatie 0.18-0.28.
			# 0.86 lasa albedo-ul la 0.21, dar peste el se aduna aurul, care
			# urca mediana. Se coboara la 0.90 ca SUMA sa cada in banda.
			"water_b_desat": 0.91,
			# RUNDA 8. Cifra care a picat runda 7: brunul era cea mai DESCHISA
			# suprafata mare dintr-un cadru de noapte — luminanta 45-63 langa o
			# stanca de 47.7 (raport 0.97-1.08), la saturatie 0.52. Ocru viu,
			# uniform, mai deschis decat piatra: pamant, nu apa. In diorama
			# raportul apa/uscat pe bratul auriu e 1.21 fata de TERASA
			# LUMINATA, dar bratul ala e luminos din REFLEXII (2% din pixeli
			# peste 150), nu din vopsea. Deci albedo-ul coboara aici, iar
			# lumina se intoarce prin "water_b_glint" de mai jos.
			# RUNDA 9: 1.05 lasa brunul la aceeasi luminanta cu verdele (48 vs
			# 48, masurat). In diorama bratul auriu e mai DESCHIS decat cel
			# verde (76 fata de 52), dar din reflexii, nu din vopsea — deci
			# albedo-ul coboara si diferenta o face `water_b_glint`.
			"water_b_gain": 0.82,
			# CAT de aprins e Yangtze fata de Jialing. Vezi nota v6 din shader:
			# in diorama bratul auriu are de cinci ori mai multi pixeli aprinsi
			# decat cel verde (11.8% fata de 2.4% peste luminanta 90). La noi
			# era pe dos: brunul avea p99 = 92-96 si maximul 143, adica nicio
			# scanteie, pe cand verdele urca la 128.
			# RUNDA 9. Masurat pe captura rundei 8, apa din stanga podului:
			# 25% din pixeli peste luminanta 90 si ecart p10-p90 = 107, adica
			# de patru ori cat are diorama (11.4% si 28). Nu e "prea multa
			# lumina", e prea multa SUPRAFATA aprinsa deodata — vezi
			# `facet_gate` in shader. Castigul coboara putin fiindca poarta
			# lasa acum mai putine placi, dar cele care trec raman aprinse.
			"water_b_glint": 1.9,
			"water_b_glint_cut": 0.66,
			# Cat de INCHISA e apa fata de mal. Nu "inchisa" in absolut: pragul
			# e un RAPORT, apa <= 0.65 x uscatul din ACELASI cadru, fiindca de
			# aia citea runda 4 miriste — 42 langa 41, adica aceeasi valoare, si
			# nimic nu mai spunea ca e alta materie. Masurat pe cornisa D:
			# faleza 51, terasa/cheiul 38. La 0.50 apa iesea 29.6, deci 0.58
			# fata de faleza dar 0.77 fata de chei; la 0.40 iese 24-25, adica
			# sub prag fata de amandoua.
			# RUNDA 9. Regula "apa <= 0.65 x uscatul" pe care era calibrata
			# valoarea asta a fost RETRASA: masurat in diorama, apa NU e mai
			# inchisa decat malul (verde 52 si auriu 76, fata de 39-45 pe
			# betonul cheiului — apa e mai DESCHISA). Apa nu se deosebeste de
			# uscat prin faptul ca e inchisa, ci prin saturatie mica si prin
			# suprafata fatetata. 0.62 tragea corpul apei la 36-40, adica sub
			# tot ce e in jur; 0.78 il aduce in banda 45-55 a dioramei fara sa
			# atinga saturatia, care e reglata separat (`water_desat`).
			"water_dim": 0.78,
			"water_foam": 0.0,
			# Unde se despart cele doua rauri: o dreapta prin (60, 215) — malul
			# de sud al peninsulei, la mijloc — spre SSE. La vest de ea curge
			# Jialing (bratul care coboara pe langa cornisa D), la est Yangtze
			# (golful de sub pod). Granita trece prin fata cheiului, deci linia
			# de confluenta se vede din vederea de cursa la fractia 0.46.
			"water_split": 1.0,
			"water_split_dir": Vector2(0.94, -0.35),
			# RUNDA 9. Linia era la -18.85, adica trecea la ~100 m in SPATELE
			# camerei de pe pod: din vederea de cursa la fractia 0.52 se vedea
			# numai Yangtze, pe amandoua malurile, si masuratoarea a spus-o
			# fara ocolisuri — "ambele rauri ale noastre sunt la nuanta 30, nu
			# exista rau verde". Un rau verde care nu se vede din cadrele de
			# joc nu exista, oricat de corect ar fi autorat.
			#
			# La 90, dreapta trece CHIAR PE SUB TABLIER: apa din stanga soselei
			# e Jialing (distanta cu semn de la -15 la -36 pe primii 45 m, deci
			# verde pana la mal) si cea din dreapta e Yangtze (+3 la +27).
			# Adica exact geografia din brief — soseaua traverseaza confluenta,
			# si o vezi ca pe doua ape diferite de o parte si de alta a masinii,
			# nu ca pe o nota din documentatie. Cornisa D ramane la -363 (verde
			# curat) si cheiul E la -128 (tot verde), deci cele doua cadre in
			# care Jialing-ul se vedea deja bine nu se schimba.
			"water_split_offset": 70.0,
			# RUNDA 8: 35 m de amestec plus 55 m de serpuire faceau din
			# confluenta o ZONA de peste 100 m, pastoasa, cu pete reticulate —
			# muschi pe noroi, nu doua ape care se intalnesc. In natura linia e
			# de ordinul metrilor si serpuieste pe zeci, nu invers.
			"water_split_soft": 12.0,
			"water_split_meander": 24.0,
			# Pe ce distanta se abate granita cu cei 24 m de mai sus. Vezi nota
			# din shader: pana in runda 9 serpuirea se lua din zgomotul de
			# suprafata, deci granita se zimtea pe metru si cele doua ape
			# ieseau marmorate. 260 m = o cotitura pe toata largimea golfului.
			"water_split_wave": 260.0,
			"water_seam": 0.55,
			# Glint/crest URCATE in runda 4: cu verdele/brunul desaturat, apa
			# de la distanta (vederea de pe cornisa D) iesea camp mat — ce o
			# face sa citeasca APA noaptea sunt sclipirile orasului pe hula
			# (referinta: diorama, pete aurii pe verde inchis). Sclipirile
			# sunt pete mici: mediana de saturatie/luminanta ramane sub gate.
			# SEMNALUL DE LICHID. Scanteierea nu mai vine de la soare: soarele
			# temei sta la -78 grade, aproape in zenit, deci reflexia lui pleaca
			# in sus si camera razanta de cursa nu prindea decat cateva pete in
			# prim-plan — pete izolate pe o suprafata mata, adica exact cum
			# arata un camp. `water_glint_horizon` pune in loc o lumina JOASA
			# dincolo de apa (felinarele de pe malul opus), mereu in
			# continuarea privirii, deci drumul de sclipiri vine spre camera.
			# `water_glint_streak` il si lungeste pe axa privirii — pe ecran,
			# vertical.
			# RUNDA 12: 0.24 -> 0.62. Vezi `facet_lid`: partea luminoasa a
			# histogramei a fost eliberata de placi ca sa fie a reflexiilor, si
			# atunci reflexiile chiar trebuie sa o ocupe. Masurat pe pixelii
			# peste mediana+25: fractia AURIE urca de la 0.2-1% la 2.3-5.1%
			# (diorama 2.9%), fara ca acoperirea totala sa creasca.
			"water_glint": 0.62,
			"water_glint_horizon": 0.30,
			"water_glint_sharp": 16.0,
			# CAT de mult din apa e reflexie. Masurat in diorama
			# (bar/E_chei.png, cu pragul de luminanta 90): 2.4% pe bratul verde,
			# 11.8% pe cel brun. Sub 0.58 pragul lasa peste 15% si apa devine o
			# foaie de aur; peste 0.70 scade sub 6% si redevine mata. 0.64 da
			# 9-11% pe cornisa D.
			# RUNDA 12: 0.64 -> 0.66, impreuna cu `water_b_glint_cut`
			# (0.56 -> 0.66) si `facet_gate` (0.42 -> 0.60). Glint-ul e mai
			# puternic acum, deci pragul urca cat sa tina acoperirea acolo unde
			# o are diorama (4.7%): masurat, 3.1-4.9% pe vederile de cursa.
			# RUNDA 13: 0.66 -> 0.58, ca sa compenseze petele pierdute prin
			# latirea rampei (`water_glint_soft`). Pragul deschide aria, rampa
			# o tine moale — cele doua se regleaza impreuna.
			"water_glint_cut": 0.58,
			# Cat de lungite. 3.2 (incercat intai) trage petele in fasii de zeci
			# de metri; la 1.4 ies limbi de flacara pe cheiul E. 0.9 le lasa
			# pete cu coada — alungite pe verticala, dar tot pete.
			# RUNDA 12: 0.28 -> 0.55. Petele masurate de critic ieseau ROTUNDE
			# (alungire 1.33 fata de 2.24-2.43 in diorama), nu alungite cum
			# raportase runda 11. Reflexia unei lumini pe apa e o dara pe axa
			# privitorului, si asta e butonul ei: alungirea urca la 1.6-2.9.
			"water_glint_streak": 0.55,
			# Marimea unei reflexii. Vezi nota din shader: la 1.0 (scara
			# ondulatiei) petele ies de cativa pixeli si in randuri regulate —
			# masurat pe captura rundei 5, o grila de ferestre aprinse peste
			# rau. Masurat in diorama (bar/E_chei.png): reflexiile aurii au
			# 20-60 px pe o apa vazuta de la aceeasi distanta, adica pete de
			# metri, rare, cu marimi diferite.
			"water_glint_grain": 0.36,
			# Suprafata NETEDA sub reflexii (implicitul 0.35 e de laguna
			# vazuta de aproape; de la 60 m in sus iese pasla).
			# RUNDA 8: 0.10 lasa suprafata prea neteda pentru apa de APROAPE.
			# Masurat pe capturile rundei 7, energia de detaliu la raza 2 px:
			# diorama 9.84, brunul nostru 2.75 — iar ASFALTUL din acelasi cadru
			# 4.89. Cand soseaua are mai multa viata pe suprafata decat raul,
			# raul citeste material solid.
			"water_ripple": 0.21,
			# RUNDA 9: dupa ce petele-amiba au disparut, ecartul p10-p90 a cazut
			# la 18-20 fata de 28-39 in diorama — suprafata devenise linoleum.
			# Placa e acum singura care mai da variatie de valoare, deci ea
			# trebuie sa o dea toata.
			# RUNDA 10. Cifra care decide daca tesela se VEDE, si a fost tot
			# timpul prea mica. Masurat pe saltul de luminanta intre pixeli
			# vecini (adica exact ce e o muchie de fateta): in diorama p90 e
			# 5.7 pe bratul verde si 10.8 pe cel auriu, la noi era 1.9-2.0 in
			# prim-plan — placile difereau intre ele cu mai putin de un nivel,
			# deci ochiul nu avea ce muchie sa vada oricat de corect ar fi fost
			# desenata tesela. 0.52 impartit la 7 trepte inseamna ~7% intre
			# doua placi vecine, iar 7% dintr-o apa la luminanta 55 e sub 4
			# niveluri, din care jumatate se pierd in ondulatie.
			#
			# Se urca amplitudinea SI se rareste treapta: cu 4 trepte in loc de
			# 7, doua placi vecine cad mai des in cutii diferite, si diferenta
			# lor e mai mare. Nu se poate urca la nesfarsit — peste ~1.0 apar
			# placi negre langa placi albe, adica sah, nu apa.
			# RUNDA 12: amplitudinea URCA (0.7 -> 0.95) desi defectul era
			# „prea multa variatie”. Nu e o contradictie: `facet_calm` de mai
			# jos schimba DISTRIBUTIA, nu marimea, si strange corpul spre
			# mijloc. Coborand in schimb amplitudinea s-ar fi sters si coada,
			# deci si muchia, si suprafata redevenea degradeul neted al
			# rundelor 8-9. Aici corpul se linisteste si coada isi pastreaza
			# muscatura: edge% ramane 9.5-12 (diorama 10.3) cu calm4 42-46%.
			#
			# Si treptele se INDESESC (4 -> 9): cu 4 trepte, corpul strans de
			# `facet_calm` tot cadea pe cateva rungi departate una de alta, deci
			# „linistea” iesea tot tabla de sah, doar cu mai putine culori.
			# Cu 9, majoritatea placilor cad pe rungi vecine langa mijloc.
			"water_facet": 0.95,
			"water_facet_count": 9,
			# RUNDA 8. 0.17 rad/m inseamna fatete de ~37 m, iar banda de apa
			# vizibila de pe pod are 60-150 m: doua-patru fatete pe toata
			# suprafata, adica nici una. In diorama o fateta subintinde cam a
			# zecea parte din latimea benzii de apa. 0.46 => 13.7 / 9.8 / 6.9 m
			# pe cele trei sinusoide, deci 6-14 m pe ecran.
			"water_facet_scale": 0.46,
			# RUNDA 9: 0.10 lasa muchia placii dreapta pe zeci de metri, deci
			# placile ies un caroiaj regulat. In diorama fiecare triunghi are
			# alta marime si alta orientare.
			#
			# RUNDA 11: regularitatea NU se repara de aici, si asta s-a masurat.
			# La 0.30 muchiile se curbeaza inapoi in lobii de camuflaj scosi in
			# runda 9 (edge% urca la 9.8, dar pe captura tesela dispare), iar la
			# 0.45 si mai rau. Periodicitatea venea din diagonala aleasa pe
			# paritatea celulei — o tabla de sah cu perioada 2x2 — si se repara
			# acolo (vezi `flip` in shader). 0.18 rupe muchia cat sa nu fie de
			# rigla, si atat.
			"water_facet_wobble": 0.18,
			# Cat se indoaie grila. Vezi nota din shader: la 0.22 (valoarea
			# scrisa in cod pana in runda 9) laturile triunghiului se curbeaza
			# pana ies lobi inchisi unul in altul — camuflaj. 0.07 le lasa
			# drepte, iar neregularitatea vine din tesela in sine.
			"water_facet_warp": 0.02,
			# Distanta la care fateta are chiar marimea autorata; mai aproape
			# se micsoreaza. Sub tablier apa incepe la 10 m, unde o fateta de
			# 14 m umplea un sfert de cadru — pete late cat un camion.
			"water_facet_ref": 95.0,
			# CAT de mult se poate micsora celula langa camera. 2.5 (scris in
			# cod pana la runda 9) e calibrat pe cornisa, unde apa cea mai
			# apropiata e la 40 m. Tablierul golfului trece la 3.3 m peste apa
			# si apa incepe la 5 m de ochi: acolo raportul cerut e 19x, iar
			# plafonul de 2.5 lasa celula la 5.5 m, adica JUMATATE DE ECRAN pe
			# o placa. 5.5 o duce la ~2.5 m langa camera, deci placile de sub
			# pod se vad ca placi, nu ca judete.
			# RUNDA 10: 5.5 lasa celula la 3.42 m in tot prim-planul, iar de pe
			# tablier 3.42 m la 5-15 m de ochi inseamna 98-320 px pe ecran —
			# adica sub zece placi pe toata apa din cadru. O tesela din care
			# vezi cinci placi nu se citeste tesela, se citeste pata: masurat
			# pe banda de aproape, densitate de muchii 2.9% fata de 13.6% pe
			# banda departata (unde anizotropia lucreaza) si 19.8% in diorama.
			# 16 duce celula la ~0.85 m langa camera, deci 25-80 px — marimea
			# pe care o au placile in bar/E_chei.png.
			# RUNDA 11: cele doua chei de mai jos (`water_facet_ref` /
			# `water_facet_near`) NU MAI SUNT ACTIVE pe tema asta — `facet_px`
			# de mai jos le ia locul in shader. Raman scrise pentru ca alte teme
			# (Okinawa, Baikal, Alpii) tot pe ele merg, si ca sa se vada de ce
			# s-a renuntat: 16.0 e la aproape 3x pragul de esec documentat chiar
			# deasupra uniformei `facet_near_max` (~6x, peste care celula scade
			# sub 2.5 m si reflexia o trage in fire). Ridicat de trei ori
			# (2.5 -> 5.5 -> 16) fara sa nimereasca, fiindca o DISTANTA de
			# calibrare nu poate fi corecta si de pe cornisa (27 m peste apa) si
			# de pe tablier (3.3 m). Marimea ceruta in pixeli nu are problema.
			"water_facet_near": 16.0,
			# RUNDA 11. Inlocuieste `water_facet_ref`/`water_facet_near` cu
			# marimea CERUTA DIRECT IN PIXELI. Cele doua de deasupra raman
			# scrise fiindca alte teme le folosesc; pe Chongqing `facet_px` le
			# ia locul (vezi shader: cand e > 0, ramura veche nu mai ruleaza).
			#
			# Marimea e citita din bar/E_chei.png, nu aleasa: acolo lungimea
			# medie de segment intre doua muchii de luminanta >= 8 e 17.7 px pe
			# orizontala in prim-plan si 71 px pe banda departata. Cu
			# mecanismul vechi (facet_ref 95 / near 16) placile ieseau 89-171 px
			# late in prim-plan — sub zece placi pe toata apa din cadru, adica
			# pete.
			#
			# RUNDA 12: corectat comentariul, care spunea „24 px” in timp ce
			# valoarea scrisa era 16 — inconsecventa semnalata de critic. 16 e
			# cea masurata: aria medie a fatetei iese 6.0-6.5 px in capturi
			# fata de 4.9-8.5 px in diorama, deci scara e nimerita si nu ea era
			# problema rundei 11 (era amplitudinea, reparata prin `facet_calm`).
			"water_facet_px": 16,
			# Plafonul micsorarii fata de placa autorata (13.7 m). 32 il lasa
			# sa coboare la 0.43 m langa camera, adica tot placa, nu granulatie.
			"water_facet_px_max": 32.0,
			# RARITATEA reflexiilor. Vezi `facet_gate` in shader: fateta spune
			# CARE placi prind lumina, fisura deseneaza pata inauntru. La 0.62
			# trec cam 38% din placi, si in ele fisura mai taie o data — de
			# aici acoperirea de 3-10% pe care o are diorama, in loc de 25%.
			"water_facet_gate": 0.60,
			# RUNDA 10. Butonul care repara defectul care a picat runda 9.
			# Vezi nota lunga din shader (`facet_aniso`): de pe tablier camera
			# sta la 3.3 m peste apa, deci proiectia intinde axa radiala de r/h
			# ori — 12x la 40 m, 45x la 150 m. Celula patrata in lume iesea
			# aschie de sub 10 px pe ecran de la 40 m in sus, si o tesela de
			# aschii se amesteca intr-un degrade: 8.2% densitate de muchii pe
			# pod fata de 20.9% in golf (de sus, unde raportul e 1) si 19-31%
			# in diorama. 12 e derivat, nu ales: la 150 m lasa celula la ~1.1 m
			# pe axa radiala, adica tot ~10 px pe ecran — cat sa se vada muchia,
			# prea putin cat sa se citeasca fir.
			# RUNDA 12: STINS, si nu fiindca ar fi reglat prost — fiindca
			# premisa lui e gresita, iar rundele 10 si 11 au discutat doar
			# semnul ei. Amandoua au cerut ca fateta sa iasa PATRATA PE ECRAN.
			# Dar bar/E_chei.png e o suprafata 3D fotografiata: fatetele ei
			# sunt cam echilaterale IN LUME, iar perspectiva le turteste pe
			# ecran — si tocmai turtirea aia e semnalul „planul asta e
			# orizontal si se departeaza”. Corectand-o, o placa patrata pe
			# ecran devine o PANGLICA in lume, si o panglica orientata radial
			# se citeste ca pensulatie. Se vede direct pe captura, la orice
			# semn: prim-planul de sub tablier iesea in dungi verticale (r10 le
			# facea aschii transversale, r11 dungi radiale — aceeasi eroare, in
			# oglinda), iar zona de mai departe, unde raportul cerut e mic si
			# corectia aproape nu lucra, era chiar singura care arata a apa.
			# Cu 1.0 placa ramane echilaterala in lume peste tot si se
			# scurteaza pe ecran cat cere distanta, ca in diorama.
			"water_facet_aniso": 1.0,
			# Vezi `facet_aa` in shader. La 0.5 tesela se stinge cand celula
			# ajunge la doi pixeli — masurat, aia e granita intre "placi" si
			# "pietris" pe banda departata a Yangtze-ului.
			"water_facet_aa": 0.5,
			# Perechea pentru masca de reflexii. Vezi `glint_aa` in shader:
			# fara ea banda departata a Yangtze-ului se rupea in sclipici de
			# sub un pixel — 24-33% densitate de muchii fata de 19.8% in
			# diorama, si pe captura pietris in loc de apa.
			"water_glint_aa": 0.18,
			# Yangtze-ul porneste de la ~64% din luminanta lui Jialing
			# (water_b_gain 0.82 peste water_dim 0.78), deci aceeasi
			# amplitudine relativa ii da cu o treime mai putine NIVELURI de
			# luminanta intre doua placi vecine — masurat, 6.7% densitate de
			# muchii fata de 10.6% pe verde. 1.55 = chiar inversul raportului.
			# RUNDA 12 (lead): 1.20 -> 0.80. Cheia a fost pusa ca sa compenseze
			# o apa mai INCHISA (aceeasi amplitudine relativa da mai putine
			# niveluri de luminanta, iar muchia se vede in niveluri) — dar pe
			# Chongqing raul B, Yangtze, e cel mai DESCHIS dintre cele doua
			# (lum 56 fata de 52 la Jialing, masurat pe r12_gamecam_pod).
			# Amplificarea lucra deci in sensul invers motivului ei si scotea
			# tocmai malul de sub ochiul soferului ca mozaic de piatra, in timp
			# ce verdele de dincolo de drum se linistise deja corect.
			"water_facet_b_gain": 0.80,
			# RUNDA 12, si asta e reparatia principala. Vezi `facet_calm` in
			# shader: treptele de placa erau echiprobabile, deci FIECARE placa
			# purta tonul ei si nu ramanea suprafata neteda intre ele. Masurat
			# pe corpul apei, procentul din suprafata la +-4 niveluri de
			# mediana: 18.9% la noi fata de 36.5% in bar/E_chei.png, iar golul
			# se tinea la orice prag. Pe plansa oarba panelul nostru citea
			# PIATRA acoperita cu licheni; culoarea era corecta, materialul nu
			# era lichid. 2.2 aduce cifra la 42-46% pe prim-plan cu edge% 9.5-12
			# (diorama 10.3), adica placi care se vad pe o apa care se
			# odihneste. Peste ~3 suprafata redevine degrade neted.
			"water_facet_calm": 2.2,
			# Coada de SUS a placilor, taiata la 58%. Motivul e o masuratoare
			# care desparte doua suprafete cu aceeasi statistica de luminanta:
			# in diorama 61% din pixelii peste mediana+25 sunt AURII (reflexii
			# de felinar), la noi erau 1-2% — restul, placi verzi palide. O apa
			# de noapte primeste lumina in PETE, nu pe placi, deci placa are
			# voie sa se inchida cat vrea (umbra dintre valuri e a apei) dar nu
			# sa se deschida: partea luminoasa a histogramei ramane a
			# glint-ului. Masurat dupa: 45-70% din pete sunt aurii, cu
			# acoperire 3.1-4.9% (diorama 4.7%).
			"water_facet_lid": 0.58,
			# A doua jumatate a aceluiasi defect: lobul speculat. Razant,
			# dot(reflect, view) sta lipit de 1 pe toata apa, deci lobul e un
			# camp neted fara varf si diferenta de panta dintre doua fatete
			# vecine nu mai produce diferenta de stralucire — de aia malul brun
			# avea 2 pete de reflexie fata de 59 in diorama. Exponentul se
			# imparte la 6 la incidenta zero si ramane intreg cand privesti de
			# sus, deci golful (care masura deja ancora) nu se schimba.
			"water_glint_graze": 6.0,
			# RUNDA 12. `glint_graze` de mai sus lateste lobul razant ca sa
			# existe reflexii si de pe tablier — corect ca forma, dar din
			# scaunul soferului (1.2 m peste sosea) TOATA apa e razanta, deci
			# lobul latit se aprindea peste tot deodata si banda de apa iesea
			# crema plina: 15.4% acoperire in vederea D. Ce se lateste ca forma
			# se stinge ca intensitate, si cele doua se compenseaza — acoperirea
			# ramane a temei, nu a unghiului. Vederea D scade la 7.3%.
			"water_glint_graze_cap": 0.30,
			# RUNDA 8: 0.68 / 1.32 erau calibrate pe cornisa D, unde camera e
			# la 27 m deasupra apei. Tablierul de peste golf trece la 3.3 m,
			# deci de acolo apa se vede razant pe toata suprafata si aceeasi
			# regula o inchidea uniform — pamant. Panta se domoleste, iar ce se
			# intampla razant il preia "water_fresnel".
			"water_view_lo": 0.86,
			"water_view_hi": 1.14,
			"water_view_ref": 0.20,
			"water_crest_shade": 0.22,
			# OGLINDA RAZANTA. Vezi nota v7 din shader: singurul semnal de
			# lichid care functioneaza cand te uiti PESTE apa, nu IN ea — si de
			# pe tablier, la 3.3 m peste golf, asa se vede toata. Culoarea vine
			# din ceata temei (mediul reflectat), nu dintr-un slot.
			"water_fresnel": 0.55,
			"water_fresnel_sharp": 14.0,
			"water_fresnel_gain": 1.0,
			# CE se oglindeste. Implicitul e ceata, si pentru o tema de zi e
			# corect — dar aici ceata e gri-violacee, iar amestecata razant
			# peste un rau brun il ducea la saturatie 0.08, adica gri neutru:
			# cerinta "brun intre 20 si 40 grade" pica nu fiindca nuanta se
			# muta, ci fiindca nu mai ramane nuanta deloc. Ce se vede razant
			# peste apa unui oras noaptea nu e cerul, e MALUL OPUS: felinare de
			# sodiu si ferestre, adica o lumina CALDA si joasa. Si e chiar
			# explicatia bratului auriu din diorama — nu are alt albedo decat
			# cel verde, are drumul de lumina al malului de dincolo.
			"water_fresnel_color": Color(0.33, 0.24, 0.145),
			# RUNDA 12. Amandoua faceau reflexia MOALE, si critic a masurat
			# exact asta: raportul rampa/miez 16.6 in prim-plan fata de 1.5-4.5
			# in diorama — fum auriu difuz, nu cioburi taioase. `glint_soft`
			# 0.22 e o tranzitie lata cat un sfert din masca, iar `glint_body`
			# 0.75 face intensitatea sa creasca cu adancimea fisurii, adica tot
			# halou. Cioburile din diorama au margine scurta si miez aproape
			# plat. Aria medie a petei scade de la 411 px la 16-22 (diorama 21).
			# RUNDA 13 (verdict pe captura din JOC, nu de sus): petele „par ca
			# plutesc". Masurat pe vederea de la volan, de pe cornisa:
			#
			#   raport pata/apa ........ 2.43x   (tinta din diorama: 1.8-2.8x) OK
			#   gradient la margine .... p90 = 50, max = 131 pe UN pixel     NU
			#   deviatie in interior ... 15.1 (deci miezul NU e plat)        OK
			#
			# Deci nu luminozitatea e problema si nici interiorul — e MARGINEA:
			# un salt de 130 intr-un pixel citeste ca hartie taiata, adica exact
			# „obiect lipit pe suprafata" din nota de la `glint_soft` in shader.
			#
			# 0.09 venise din calibrarea pe diorama VAZUTA DE SUS, unde petele
			# trebuiau sa fie cioburi mici si distincte. De la volan, aceeasi
			# taietura e ce face pata sa nu apartina apei. Se lateste tranzitia
			# si se lasa intensitatea sa CREASCA cu adancimea fisurii, in loc sa
			# sara la maxim imediat dupa prag — aria petei ramane data de
			# `glint_cut`/`facet_gate`, care nu se ating.
			# Latirea tranzitiei subtiaza si petele — aria galbena scade
			# 4.4% -> 1.7%, fiindca o pata slaba nu mai apuca sa ajunga la
			# valoare plina inainte sa se stinga rampa. (Verificat ca NU e de
			# la `glint_body`: la 0.70 si la 0.50 aria e aceeasi, 1.5 vs 1.7%.)
			# Compensarea se face din prag, nu din intensitate: `glint_cut`
			# 0.66 -> 0.58 lasa mai multe fisuri sa treaca, iar rampa lata le
			# tine tot moi.
			"water_glint_soft": 0.28,
			"water_glint_body": 0.50,
			"water_cell": 4.0,
			# Aurul lampilor de sodiu, INTREG. La 0.75 (tras spre alb, ca sa nu
			# iasa neon) reflexiile ieseau crem — pe o apa verde-inchisa asta e
			# culoare de miriste uscata, adica exact tema pe care o rezolv.
			# Reflexia unei lampi de sodiu chiar E galben-portocalie: in diorama
			# petele masoara nuanta 30-40 la saturatie 0.45-0.55, iar SAND_LIGHT
			# (E8C074) sta la 37/0.50.
			"water_glint_slot": Palette.SAND_LIGHT,
			# RUNDA 8: la 1.0 (aurul intreg) petele ieseau portocaliu saturat
			# pe brun inchis — foita de aur, nu lumina. In diorama reflexiile
			# sunt CREM palid: masurate pe pete individuale, saturatie 0.22-0.30
			# la nuanta 40-46, nu 0.50.
			"water_glint_tint": 0.95,
			# FORMA reflexiei: poligon de fateta, nu fisura de roca. Vezi nota
			# din shader — pe apa de la 20-40 m fisurile ies zigzaguri
			# ramificate, iar in diorama petele au muchii drepte si interior
			# plat, taiate pe aceeasi tesela ca fatetele de culoare.
			# Doar pe Yangtze, si doar de aproape: Jialing se vede de pe
			# cornisa la 60-250 m, unde fisura texturii are chiar marimea unei
			# pete si celula de fateta ar cadea sub un pixel. Masurat cand
			# fatetele erau pornite si pe Jialing: nuanta verdelui sarea de la
			# 147 la 69 (galben) si 8.9% din pixeli treceau de 150 — adica
			# fix miristea rundei 4, inapoi.
			# RUNDA 12: PORNIT si pe Jialing (verde). Era 0, deci reflexiile
			# raului verde nu treceau prin nicio poarta de fateta — ieseau
			# direct din fisura texturii, adica pete rotunde si difuze lipite
			# peste suprafata (masurat de critic: arie medie 411 px, alungire
			# 1.33, rampa/miez 16.6, fata de 43-83 px / 2.24-2.43 / 1.5-4.5 in
			# diorama). Comentariul de la `water_b_glint_facet` explica de ce
			# fusese stins: cu fatetele de dinainte, nuanta verdelui sarea la
			# galben. Aia era o consecinta a amplitudinii, si amplitudinea s-a
			# reparat mai sus — cu `facet_calm` si `facet_lid` nuanta ramane la
			# 155-157 si petele devin cioburi cu muchii drepte (arie 16-22 px).
			"water_glint_facet": 0.80,
			"water_b_glint_facet": 0.85,
			"water_glint_facet_far": 110.0,
			# Hula da si umbra suprafetei, si panta din care se naste lobul
			# speculat — nu poate merge la 0. La 0.45 dungile ei se vedeau ca
			# brazde pe o suprafata deja fara ondulatie fina; 0.35 le lasa doar
			# cat sa arate ca apa curge.
			"water_crest": 0.35,
			# Trepte, nu degrade: linia de mal trebuie sa fie o MUCHIE (brief
			# §2 E, style_bible §1). 0.25 lasa o trecere pastoasa pe 8 m.
			"water_band": 0.55,
			# UNDE e apa: NU "tot ce e in afara buclei" (seabed_drop) — asta
			# ar fi facut o insula, iar Chongqing e o peninsula: golful si cele
			# doua rauri stau pe sud si pe est (custom_lagoon, in Track12.tscn),
			# spre nord si vest orasul continua pe dealuri. seabed_drop ramane
			# 0 ca sa nu se sape si acolo.
			"seabed_drop": 0.0,
			# CHEIUL si MALUL OPUS (runda 7). Vezi _build_quay_wall si
			# _build_far_shore pentru de ce culoarea apei nu putea rezolva
			# singura "apa nu citeste ca apa": lipsea muchia de sus si malul
			# de dincolo.
			"quay_wall": true,
			# Doua maluri care se ATING intr-un varf, la (95, 335): de pe chei
			# se vede o pana de uscat cu varful spre tine, cu Jialing la
			# stanga ei si Yangtze la dreapta. Varful sta CHIAR pe dreapta de
			# despartire a culorilor (water_split trece prin (60,215) spre
			# SSE), deci linia de confluenta pleaca din varful penei catre
			# privitor. Departari: 130 m de chei, 150 m de cornisa D — sub
			# fog_end (250) si peste fog_begin (150), adica exact "turnurile
			# de peste rau se sting in ceata" din brief §2.0.
			"far_shore": [
				{"line": [Vector2(-395, -140), Vector2(-400, 40),
					Vector2(-372, 170), Vector2(-300, 258),
					Vector2(-170, 308), Vector2(-30, 330),
					Vector2(95, 335)], "h": 12.0, "depth": 45.0},
				{"line": [Vector2(95, 335), Vector2(245, 316),
					Vector2(385, 266), Vector2(505, 190)],
					"h": 12.0, "depth": 45.0},
			],
			# Mal de CHEI, nu plaja: apa incepe la cativa metri de contur.
			"lagoon_band_in": 10.0,
			"lagoon_band_out": 6.0,
			# Sapatura lagunei incepe imediat dincolo de buza tablierului
			# (1.5 m) si coboara scurt (8 m): apa golfului sta SUB pod, nu
			# la 15 m de el (implicitul 8+30 e plaja de atol).
			"lagoon_inner": 1.5,
			"lagoon_rim": 8.0,
			"dust_color": Color(0.30, 0.30, 0.34),
			# SCURTATURA E UN TABLIER DE VIADUCT, nu un banc de nisip si nici
			# un drum de tara. Implicitul "sand" (reteta Okinawei) e prin
			# proiect fara marcaje si fara borduri, iar "gravel", incercat
			# inainte, doar a schimbat VALOAREA suprafetei (inchis -> deschis),
			# nu si CITIREA ei: variatia lui fina de fagas si marginile care se
			# topesc in teren nu exista noaptea, la 10 m in spatele masinii. De
			# la volan a ramas exact reprosul dezvoltatorului — "un drum prin
			# care nu vezi nimic". Reteta "deck" e cea care aduce lucrurile din
			# care ochiul citeste un drum: asfalt (aceleasi doua treceri ca
			# soseaua), ax discontinuu si benzi albe pe umeri.
			"branch_surface": "deck",
			# Asfalt de noapte, dar mai DESCHIS decat bucla principala
			# (ROAD_COLOR 0.23/0.24/0.30): tablierul e beton nou, si diferenta
			# de valoare e ce spune de pe cornisa ca acolo e o alegere, nu
			# continuarea soselei. Marcajele si bordurile spun ca e drum;
			# nuanta spune ca e ALT drum.
			"branch_tint": Color(0.33, 0.34, 0.40),
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
	# Umbrele raman comutatorul de performanta (vezi _build_environment), dar o
	# tema de NOAPTE nu are ce umbri: soarele e o luna palida aproape verticala,
	# iar o umbra dura ar contrazice lumina. "shadows": false le stinge pe tema.
	theme_shadows = bool(_theme.get("shadows", true))

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

## ############################################################################
## LATIMEA SOSELEI, INTR-UN SINGUR LOC
##
## Toate generatoarele intreaba de aici cat de lat e drumul, in loc sa citeasca
## `half_width` direct. Deocamdata raspunsul e mereu acelasi — pasul asta NU
## schimba niciun pixel, si chiar asta e testul lui.
##
## De ce merita un pas separat (#236): latimea era citita in ~44 de locuri, si
## nu doar pentru asfalt — hazardele isi dimensioneaza cursa dupa ea
## (`travel`, `arm_reach`, `sweep`), grila de start isi imparte celulele,
## chevron-urile si gardurile isi calculeaza degajarea. Fiecare presupunea
## tacit ca latimea e CONSTANTA. Un profil de latime bagat direct peste ele
## le-ar fi rupt pe rand, si nu zgomotos: o vana de carusel dimensionata pe
## latimea de la fractia 0 ar fi trecut prin perete la fractia 0.5, tacut.
##
## Cu intrebarea centralizata, pasul 2 (profil pe sectoare) e o schimbare
## intr-o functie, iar locurile care au nevoie de latimea LOCALA se vad deja:
## sunt cele care cheama `width_at_index`.

## Sectoarele cu latime proprie: fiecare e (frac_start, frac_end, half_width).
##
## Gol (implicit) = latime constanta pe toata pista, adica exact
## comportamentul dinainte de #236. Un drum care nu declara nimic nu se schimba
## cu un pixel.
##
## Fractiile se dau ca oriunde in pista: 0..1 pe tur, 0 = linia de start. Un
## sector poate trece peste linia de start ([code]end < start[/code]) — e tratat
## prin desfasurare, ca la scurtaturi.
##
## Intre sectoare latimea NU sare: [method width_at] interpoleaza neted pe
## [constant WIDTH_RAMP_M] metri de fiecare parte. Vezi acolo de ce lungimea
## tranzitiei nu e o preferinta de gust.
##
## Sectoarele care se suprapun sunt o eroare de declaratie, nu o compunere:
## castiga primul care contine fractia. Le semnaleaza `_validate_width_segments`.
func _width_segments() -> Array[Vector3]:
	return []

## Pe cati metri se face trecerea de la o latime la alta, de fiecare parte a
## marginii unui sector.
##
## NU e o preferinta de gust. Marginea asfaltului e si marginea fasiei de
## coliziune: daca latimea sare cu 3.5 m intre doua inele de drum aflate la
## ~3 m unul de altul, apare un PRAG LATERAL de 3.5 m. Masina e un
## CharacterBody3D fara step-up, deci un prag lateral nu e o denivelare, e un
## PERETE — te opresti in el mergand drept, in mijlocul soselei.
##
## Masurat pe o strangere 7.0 -> 3.5 cu inele la 1.91 m: 15.7 inele de
## tranzitie, deci 0.22 m pe inel in medie si 0.33 m in varf (smoothstep-ul
## e mai abrupt la mijloc decat la capete). O treime de metru pe pas, adica
## margine oblica, nu zid.
const WIDTH_RAMP_M: float = 30.0

## Jumatatea latimii soselei la o fractie de tur (0..1).
##
## Fara sectoare declarate intoarce `half_width` — acelasi raspuns pentru
## toata pista, deci pistele care nu cer nimic raman neatinse.
##
## Cu sectoare, latimea CURGE: fiecare margine de sector e o rampa de
## [constant WIDTH_RAMP_M] metri, neteda la capete (smoothstep), nu o treapta.
## Vezi constanta pentru ce se intampla fara ea.
func width_at(frac: float) -> float:
	var segs := _width_profile()
	if segs.is_empty():
		return half_width
	var f := fposmod(frac, 1.0)
	var out := half_width
	for seg in segs:
		# `seg` e (start, end, half_width) cu start/end deja desfasurate, deci
		# un sector peste linia de start are end > 1.0 si se testeaza si la
		# f + 1.0. Vezi `_width_profile`.
		var w := _width_blend(f, seg)
		if w < 0.0:
			w = _width_blend(f + 1.0, seg)
		if w >= 0.0:
			out = w
			break
	return out


## Cat de lata e soseaua la fractia `f` din perspectiva unui SINGUR sector, sau
## -1.0 daca fractia e in afara lui cu totul (rampe incluse).
##
## Rampele stau IN AFARA sectorului declarat, nu inauntru: cine scrie
## „de la 0.30 la 0.40 drumul are 3.5" vrea 3.5 pe tot intervalul ala, nu 3.5
## doar la mijloc, cu capetele inca pe jumatate largi.
func _width_blend(f: float, seg: Vector3) -> float:
	var ramp := _width_ramp_frac()
	var a := seg.x
	var b := seg.y
	if f >= a and f <= b:
		return seg.z
	if f < a:
		if f < a - ramp:
			return -1.0
		return lerpf(half_width, seg.z, smoothstep(0.0, 1.0, (f - (a - ramp)) / ramp))
	if f > b + ramp:
		return -1.0
	return lerpf(seg.z, half_width, smoothstep(0.0, 1.0, (f - b) / ramp))


## Lungimea rampei exprimata in fractii de tur, ca sa fie comparabila cu
## fractiile sectoarelor. Pe o pista de 2271 m, 30 m inseamna 0.0132.
##
## Daca lungimea inca nu se stie (chemat inainte de coacerea curbei), intoarce
## o rampa lata in loc sa imparta la zero. Nu se intampla in fluxul normal —
## `rebuild()` coace curba inaintea oricarui generator — dar functia e publica
## prin `width_at`, deci nu se bazeaza pe ordinea apelurilor.
func _width_ramp_frac() -> float:
	var total := _dists[baked.size()] if _dists.size() > baked.size() else 0.0
	if total <= 0.0:
		return 0.05
	return WIDTH_RAMP_M / total


## Sectoarele cu fractiile desfasurate si validate, calculate O SINGURA DATA pe
## rebuild. `width_at` e chemata de zeci de mii de ori pe constructie (o data pe
## inel de drum, plus hazarde, decor, chevron-uri) — refacerea listei la fiecare
## apel ar fi transformat o cautare liniara intr-una patratica.
var _width_segs: Array[Vector3] = []
var _width_segs_ready: bool = false

func _width_profile() -> Array[Vector3]:
	if not _width_segs_ready:
		_width_segs = _validate_width_segments(_width_segments())
		_width_segs_ready = true
	return _width_segs


## Curata declaratiile: latimi imposibile, sectoare goale, suprapuneri.
##
## Toate cele trei se plang in Output si CONTINUA cu ce se poate, in loc sa
## opreasca pista: o pista pe jumatate construita e mai greu de depanat decat
## una care spune ce n-a inteles.
func _validate_width_segments(raw: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for seg in raw:
		var a := fposmod(seg.x, 1.0)
		var b := fposmod(seg.y, 1.0)
		var w: float = seg.z
		if w <= 0.0:
			push_warning("Track: sector de latime cu half_width %.2f — se ignora" % w)
			continue
		# Sub o latime de masina drumul nu mai e drum. Masina are ~1.8 m, deci
		# 2.0 m jumatate de latime lasa 4 m de asfalt: se trece, dar nu se
		# depaseste — exact ce vrea o strangere.
		if w < 2.0:
			push_warning(("Track: sector de latime cu half_width %.2f m — sub 2 m "
				+ "nu mai incape o masina cu spatiu de manevra") % w)
		if is_equal_approx(a, b):
			push_warning("Track: sector de latime gol la fractia %.3f — se ignora" % a)
			continue
		# Sectorul care trece peste linia de start se desfasoara peste 1.0, ca
		# `width_at` sa-l poata testa si la f + 1.0.
		if b < a:
			b += 1.0
		out.append(Vector3(a, b, w))
	for i in out.size():
		for j in range(i + 1, out.size()):
			if _width_segs_overlap(out[i], out[j]):
				push_warning(("Track: sectoarele de latime %.3f-%.3f si %.3f-%.3f "
					+ "se suprapun — castiga primul") % [
					out[i].x, out[i].y, out[j].x, out[j].y])
	return out


## Doua sectoare se ating? Comparatia se face si cu al doilea mutat cu un tur,
## fiindca unul dintre ele poate fi desfasurat peste 1.0.
func _width_segs_overlap(p: Vector3, q: Vector3) -> bool:
	for shift: float in [-1.0, 0.0, 1.0]:
		if p.x < q.y + shift and q.x + shift < p.y:
			return true
	return false


## Latimea la fiecare punct copt, pentru [TrackSideSampler].
##
## Lista GOALA cand pista n-are profil declarat, si asta nu e o optimizare de
## dragul ei: samplerul trateaza lista goala ca „latime constanta" si raspunde
## bit-identic ca inainte. Pistele existente nu platesc nici memorie, nici
## risc, pentru o functie pe care n-o folosesc.
func _baked_widths() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if _width_profile().is_empty():
		return out
	var n := baked.size()
	out.resize(n)
	for i in n:
		out[i] = width_at(float(i) / float(n))
	return out


## Acelasi lucru, dar intrebat cu un index din [member baked].
##
## Exista separat fiindca majoritatea generatoarelor itereaza pe indici si NU au
## fractia la indemana; convertind aici, nu se imprastie prin cod aceeasi
## impartire la `baked.size()`. Un index inseamna o fractie doar pe bucla
## principala — pe scurtaturi latimea vine din [member TrackRoute.half_width].
func width_at_index(i: int) -> float:
	var n := baked.size()
	if n == 0:
		return half_width
	return width_at(float(((i % n) + n) % n) / float(n))


## Punctele de control ale traseului. INTAI curba din nodul copil "Path"
## (editabila vizual, cu gizmo-uri), apoi cele scrise in cod. Asa ORICE pista
## — inclusiv una definita in cod, ca Alpii — devine editabila din editor in
## clipa in care primeste un nod Path; pana atunci nimic nu se schimba.
func _points() -> Array[Vector3]:
	var path := get_node_or_null("Path") as Path3D
	if path != null and path.curve != null and path.curve.point_count >= 3:
		var pts: Array[Vector3] = []
		for i in path.curve.point_count:
			pts.append(path.curve.get_point_position(i))
		return pts
	return _code_points()

## Punctele scrise in cod — hook-ul pe care il suprascriu pistele definite in
## .gd. Pierde in fata nodului "Path" de indata ce acesta exista.
func _code_points() -> Array[Vector3]:
	push_error("Track: suprascrie _code_points() in subclasa sau adauga un nod Path")
	return []

## Bifeaza in Inspector ca sa reconstruiesti pista (doar in editor).
## Pe o pista definita in cod, PRIMA bifare creeaza si nodul "Path" cu
## punctele reale ale traseului — de atunci curba e a ta, trage de ea.
@export var regenerate: bool = false:
	set(_value):
		regenerate = false
		if Engine.is_editor_hint() and is_inside_tree():
			_editor_regenerate()

## Ce se intampla la Regenerate — suprascris de TrackFromPath, care isi
## aplica intai exporturile custom_*.
func _editor_regenerate() -> void:
	_ensure_path_from_code()
	rebuild()

## Materializeaza curba editabila dintr-o pista definita in cod: un nod
## "Path" cu EXACT punctele din _code_points(), salvat in scena (owner pe
## radacina). Geometria nu se schimba cu nimic — aceleasi puncte, acelasi
## Catmull-Rom — doar sursa lor devine trasabila cu mouse-ul.
func _ensure_path_from_code() -> void:
	if get_node_or_null("Path") != null:
		return
	var pts := _code_points()
	if pts.size() < 3:
		return
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in pts:
		curve.add_point(p)
	path.curve = curve
	add_child(path)
	if Engine.is_editor_hint():
		path.owner = get_tree().edited_scene_root

## Fractii (0..1) din traseu unde apar rampe de saritura.
func _ramp_fracs() -> Array[float]:
	return []

## Fractii unde apar bariere mobile.
func _hazard_fracs() -> Array[float]:
	return []

## Fractii unde coboara o avalansa peste sosea.
##
## Gol implicit, si nu doar fiindca asa e sablonul: avalansa e singurul hazard
## care te scoate din cursa ACOPERIND TOT DRUMUL, deci nu are ce cauta pe o
## pista care n-a cerut-o explicit. Se declara aici sau se planteaza vizual cu
## un [HazardMarker] de tip AVALANCHE.
func _avalanche_fracs() -> Array[float]:
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

## Care dintre rapele de mai sus sunt CORNISE: buza lipita de asfalt, in loc de
## valea lina de sub o creasta de fly-off. Indici in lista intoarsa de
## [method _ravines].
##
## Doua forme, nu una singura reglabila, fiindca descriu doua lucruri diferite:
## o vale de aterizare vrea buza lina (aluneci in ea), un drum de munte vrea
## muchie (cazi de pe el). Vezi TrackSideSampler.RAVINE_CORNICE_INNER.
func _cornice_ravines() -> Array[int]:
	return []

## Care dintre rape sunt VIADUCTE (indici in [method _ravines]): golul e si
## SUB sosea, tablierul ramane in aer pe fusta lui, iar dedesubt se aseaza
## pilele si arcadele din kit (DecorManual). O cornisa pe ambele parti fara
## asta e o creasta de stanca cu drumul pe muchie, nu un pod. Vezi
## TrackSideSampler.RAVINE_VIADUCT_OVERHANG.
func _viaduct_ravines() -> Array[int]:
	return []

## PODELE de rapa: (indice in [method _ravines], cota ABSOLUTA y). Sapatura
## nu coboara sub cota, deci o cornisa cu podea e o faleza cu un chei USCAT la
## picior, iar apa incepe dincolo de el (laguna / rapa urmatoare). Fara podea,
## adancimea se masoara de la drum, si un drum care coboara 30 m isi duce
## rapa sub apa la capatul de jos. Vezi TrackSideSampler._floors.
func _ravine_floors() -> Array[Vector2]:
	return []

## PASAJE PE PILONI: intervale de tur (fractii, x..y, cu wrap peste 1.0) in care
## soseaua trece IN AER peste un alt tronson al aceleiasi piste — nodul rutier
## din Chongqing, sau orice „pista peste pista".
##
## Nu e un viaduct si nu e un pod peste canal, si diferenta e de teren: alea
## sapa un gol SUB drum, iar aici sub drum e un alt drum, care trebuie sa
## ramana pe pamant. Punctele din interval nu mai trag terenul (vezi
## TrackSideSampler.ground_y); tablierul primeste fusta de beton si parapet pe
## ambele parti, iar umerii de pietris se sting. Pilonii vin din kit, ca la
## viaduct. Separarea VERTICALA intre etaje e regula de desen, nu de cod:
## peste TrackRoute.ROAD_ABOVE_TOLERANCE (12 m), altfel testul „pe sosea" nu
## poate deosebi etajele. Vezi docs/track_briefs/chongqing.md §7.1.
func _overpass_ranges() -> Array[Vector2]:
	return []

## Cat de mult e indexul „pe pasaj", 0..1 — masca sampler-ului, ca sa existe o
## singura definitie a intervalului (aceeasi pe care o vede si terenul).
func _overpass_mix(i: int) -> float:
	if _sampler == null:
		return 0.0
	return 1.0 if _sampler.on_overpass(i) else 0.0

## Cat de mult e indexul „pe viaduct", 0..1, cu aceeasi rampa de capat ca
## sapatura (TrackSideSampler.RAVINE_FADE_FRAC). Umerii de pietris se sting
## dupa masura asta, ca pe pod — sub tablier nu e pamant, e gol.
func _viaduct_mix(i: int) -> float:
	var ids := _viaduct_ravines()
	if ids.is_empty() or baked.is_empty():
		return 0.0
	var n := baked.size()
	var total: float = _dists[n] if _dists.size() > n else 0.0
	if total <= 0.0:
		return 0.0
	var f := _dists[i] / total
	var rav := _ravines()
	var best := 0.0
	for ri in ids:
		if ri < 0 or ri >= rav.size():
			continue
		var r: Vector4 = rav[ri]
		var fade := TrackSideSampler.RAVINE_FADE_FRAC
		var a := smoothstep(r.x - fade, r.x, f)
		var b := 1.0 - smoothstep(r.y, r.y + fade, f)
		best = maxf(best, minf(a, b))
	return best

## Ce fel de obstacol mobil sta la fiecare fractie: frac -> dictionar cu
## `model`, si optional `scale`, `roll`, `face_travel`.
##
## Suprascrie steagurile de tema DOAR pentru fractiile listate; restul raman pe
## `hazard_model` al temei. Exista fiindca o pista poate avea mai multe feluri
## de obstacol — vezi Track09, unde fiecare din cele patru vine din alta parte
## a lumii ei. Cheia se rotunjeste la 3 zecimale, ca sa se potriveasca cu
## fractiile scrise in `_hazard_fracs`.
func _hazard_kinds() -> Dictionary:
	return {}

## Masivele declarate: (x, z, raza, cota varfului in lume).
##
## Perechea pe PLUS a rapelor, din acelasi motiv: terenul urmareste soseaua,
## deci interiorul unei bucle care URCA ramane o campie — muntele pe care
## pista pretinde ca se catara nu apare de la sine. Vezi
## TrackSideSampler._lift_peaks pentru profil si pentru banda de protectie a
## asfaltului.
func _peak_specs() -> Array[Vector4]:
	return []

## Nodul e (sau contine) o declaratie de intrare, deci `rebuild` nu are voie
## sa-l stearga: [TerrainPeak], [TrackChannel], [HazardMarker].
##
## Recursiv, fiindca toate trei se pot grupa sub un Node3D oarecare — vezi
## comentariul din `rebuild`. Un grup gol NU e protejat: daca l-ai golit de
## declaratii, e un nod generat ca oricare altul.
func _holds_declarations(node: Node) -> bool:
	if node is TerrainPeak or node is TrackChannel or node is HazardMarker:
		return true
	for child in node.get_children():
		if _holds_declarations(child):
			return true
	return false


## Masivele plasate ca noduri [TerrainPeak] in scena — se ADUNA la cele
## declarate in cod, deci pe o pista ca Alpii poti pune un deal NOU tragand
## un nod, fara sa atingi declaratiile existente. Cautarea e recursiva (poti
## grupa varfurile sub un Node3D "Peaks") si manuala, nu find_children pe
## nume de clasa — sa nu depinda de inregistrarea claselor de script la
## rularea headless.
func _node_peaks() -> Array[Vector4]:
	var out: Array[Vector4] = []
	_collect_peaks(self, out)
	return out

func _collect_peaks(node: Node, out: Array[Vector4]) -> void:
	for child in node.get_children():
		if child is TerrainPeak:
			var pk := child as TerrainPeak
			# In coordonatele PISTEI, ca baked si ca tot ce citeste samplerul —
			# conteaza daca varful e grupat sub un nod cu transformare proprie.
			var p := to_local(pk.global_position)
			out.append(Vector4(p.x, p.z, pk.radius_m, p.y))
		_collect_peaks(child, out)


## Scurtaturile desenate ca noduri [TrackBranch] — se ADUNA la cele declarate in
## cod, exact ca varfurile de mai sus. O pista scrisa in cod (Alpii) poate primi
## o scurtatura NOUA tragand un nod, fara sa atinga `_branch_specs()`.
##
## Intoarce acelasi dictionar pe care il returneaza `_branch_specs()`, deci
## `_make_branch()` nu stie si nu-i pasa de unde vine banda.
##
## `entry` / `exit` NU sunt in dictionar, si asta e chiar decizia din #234:
## se DERIVA din capetele curbei desenate (vezi `_branch_ends`), nu se declara.
## Un capat scris de mana ramane in urma la prima ajustare a traseului si lasa
## o treapta in aer.
func _node_branches() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_collect_branches(self, out)
	return out


func _collect_branches(node: Node, out: Array[Dictionary]) -> void:
	for child in node.get_children():
		# Nodul "Path" al traseului principal e tot un Path3D, dar NU e o
		# scurtatura — de aceea verificarea e pe TrackBranch, nu pe Path3D.
		if child is TrackBranch:
			var br := child as TrackBranch
			var mid := br.mid_points(self)
			if mid.size() < 1:
				push_warning("Track: %s n-are puncte — se ignora" % br.name)
				continue
			var spec := {
				"points": mid,
				"wet": br.wet,
				"label": br.label if br.label != "" else br.name,
				# Suprafata si contragreutatea de viteza, cu aceleasi chei pe
				# care le poate scrie si o pista din cod in `_branch_specs()`.
				# `surface` lipseste cand nodul zice THEME — atunci
				# `_make_branch` completeaza din tema, ca la culoare.
				"speed_factor": br.speed_factor,
				"rut_depth": br.rut_depth,
				"grass_center": br.grass_center,
				"edge_noise": br.edge_noise,
				"bumpiness": br.bumpiness,
				"tufts": br.tufts,
				"elevated": br.elevated,
			}
			if br.entry_at >= 0.0:
				spec["entry"] = br.entry_at
			if br.exit_at >= 0.0:
				spec["exit"] = br.exit_at
			if br.branch_half_width > 0.0:
				spec["half_width"] = br.branch_half_width
			if br.surface_name() != "":
				spec["surface"] = br.surface_name()
			if br.tint.a > 0.0:
				spec["tint"] = br.tint
			out.append(spec)
		_collect_branches(child, out)

## Canalele asezate ca noduri [TrackChannel] — se ADUNA la cele declarate in
## cod, exact ca varfurile si scurtaturile de mai sus. O pista scrisa in cod
## poate primi o rapa NOUA tragand un nod, fara sa atinga `_channel_specs()`.
##
## Intoarce acelasi dictionar ca `_channel_specs()`, cu o singura diferenta:
## in loc de `frac` pune `at` (pozitia nodului). `_resolve_channels()` cauta
## singur indicele — vezi acolo de ce fractia nu se scrie de mana.
func _node_channels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_collect_channels(self, out)
	return out


func _collect_channels(node: Node, out: Array[Dictionary]) -> void:
	for child in node.get_children():
		if child is TrackChannel:
			var ch := child as TrackChannel
			var spec := ch.to_spec(self)
			spec["at"] = ch.local_position(self)
			out.append(spec)
		_collect_channels(child, out)


## Gimmickurile plasate ca noduri [HazardMarker] — se ADUNA la cele declarate in
## cod, exact ca varfurile si scurtaturile de mai sus. O pista scrisa in cod
## poate primi un obstacol NOU tragand un nod, fara sa atinga `_hazard_fracs()`
## si celelalte hook-uri.
##
## Intoarce { kind: HazardMarker.Kind, frac: float, side: int } — adica traduce
## POZITIA nodului in FRACTIA pe care o cer toate `_build_*`. Traducerea se face
## aici si nu in nod fiindca are nevoie de `baked`, care exista abia dupa ce
## traseul e generat.
##
## Cautarea e recursiva (poti grupa obstacolele sub un Node3D "Hazards") si
## manuala, nu `find_children` pe nume de clasa — aceeasi regula ca la varfuri:
## sa nu depinda de inregistrarea claselor de script la rularea headless.
func _node_hazards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if baked.is_empty():
		return out # fara traseu nu exista fractie in care sa traducem pozitia
	_collect_hazards(self, out)
	return out


func _collect_hazards(node: Node, out: Array[Dictionary]) -> void:
	for child in node.get_children():
		if child is HazardMarker:
			var hz := child as HazardMarker
			# In coordonatele PISTEI, ca la varfuri: conteaza daca nodul e grupat
			# sub un Node3D cu transformare proprie.
			var p := to_local(hz.global_position)
			# Proiectia e 2D (vezi `_closest_baked_index`): un nod tras pe un drum
			# care urca sta oricum la alta cota decat punctul baked cel mai
			# apropiat, si cu distanta 3D obstacolul ar aluneca de-a lungul
			# soselei pe bucata care se INTAMPLA sa fie la aceeasi inaltime.
			var spec := hz.model_spec()
			# Grupurile puse pe marker in editor trec pe hazardul CONSTRUIT:
			# markerul e o declaratie, dar cine se aboneaza la grup (metronomul
			# eruptiei, de pilda) are nevoie de nodul viu, nu de declaratie.
			# Grupurile interne ale editorului (prefixate cu _) nu se cara.
			var carried: Array[StringName] = []
			for g in hz.get_groups():
				if not String(g).begins_with("_"):
					carried.append(g)
			if not carried.is_empty():
				spec["groups"] = carried
			# Bolovanul isi poate aduce TRASEUL, desenat ca Path3D sub nod. Se
			# aduce in coordonatele pistei aici, unde stim si transformul
			# grupului in care sta nodul; hazardul il duce apoi in spatiul lui.
			# Fumarola sta LANGA drum, nu pe axa lui: gura e un obiect de decor
			# asezat pe marginea faleze. Fractia singura ar aduce-o pe mijlocul
			# soselei, deci se cara si punctul ei, exact ca la rockfall.
			if hz.kind == HazardMarker.Kind.FUMAROLE:
				spec["at"] = p
			if hz.kind == HazardMarker.Kind.ROCKFALL:
				var curve := hz.route_curve_in(self)
				if curve != null:
					spec["route"] = curve
					# Punctul de impact e al TRASEULUI, nu al nodului: nodul da
					# fractia (unde pe sosea), curba spune exact pe unde trece.
					spec["at"] = p
			out.append({
				"kind": hz.kind,
				"frac": frac_at(_closest_baked_index(p)),
				"side": hz.deflector_side,
				# Infatisarea declarata pe nod, in acelasi vocabular ca o intrare
				# din `_hazard_kinds()` — vezi HazardMarker.model_spec(). Gol cand
				# nodul n-a cerut nimic, si atunci decide tema, ca pana acum.
				"spec": spec,
			})
		_collect_hazards(child, out)


## Portiunile pe care peretele exterior NU e panglica rosie continua:
## (frac_start, frac_end, regim, latura ±1 sau 0 = ambele).
##
## Regimul e una din valorile RAIL_*:
##   RAIL_NONE   nimic. Marginea drumului e marginea drumului.
##   RAIL_POSTS  stalpi rari de lemn, fara panglica intre ei — se vede ca
##               cineva a incercat sa marcheze buza, nu ca te opreste ceva.
##
## De ce exista, si de ce ca EXCEPTIE declarata si nu ca setare de tema:
## regula implicita (gard peste tot pe exterior) e buna si ramane implicita —
## pe majoritatea pistelor peretele e singurul lucru care tine masina in lume.
## Dar pe un drum de munte gardul continuu spune exact pe dos decat vrea pista:
## „esti in siguranta, e o pista". Absenta lui e ce comunica „nu te lasa
## impins". Iar asta e o afirmatie despre O BUCATA de drum, nu despre o lume
## intreaga — de aceea intervale, nu un flag.
##
## COLIZIUNEA DISPARE ODATA CU PANGLICA, si asta e chiar scopul. Pe RAIL_NONE
## chiar poti cadea. Se declara deci numai acolo unde caderea e prevazuta:
## peste o rapa (vezi _ravines) sau pe teren care coboara. Pe o portiune plata
## ar insemna doar ca masina pleaca in campie si asteapta repunerea.
func _rail_segments() -> Array[Vector4]:
	return []

## Regimurile de parapet pentru [method _rail_segments].
enum { RAIL_NONE = 0, RAIL_POSTS = 1 }

## Stalpii de pe RAIL_POSTS: la cati metri unul.
const RAIL_POST_SPACING: float = 9.0
const RAIL_POST_HEIGHT: float = 0.95
const RAIL_POST_RADIUS: float = 0.11


## Ce regim de parapet e declarat la fractia si latura date.
## -1 = niciunul, deci peretele implicit al pistei.
func _rail_mode_at(frac: float, side_sign: float) -> int:
	for seg in _rail_segments():
		if not is_zero_approx(seg.w) and signf(seg.w) != signf(side_sign):
			continue
		# Interval pe un INEL: 0.95 -> 0.05 trece prin start/finish.
		var inside := (frac >= seg.x and frac <= seg.y) if seg.x <= seg.y \
			else (frac >= seg.x or frac <= seg.y)
		if inside:
			return int(seg.z)
	return -1

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
	# Foaia de uzura e copil fara owner, deci bucla de mai jos o elibereaza;
	# referinta trebuie sa moara odata cu ea, altfel stamp_wear ar scrie
	# intr-un viewport eliberat.
	_road_wear = null
	# Profilul de latime se recalculeaza: la Regenerate in editor, declaratiile
	# se pot fi schimbat de sub noi, iar lungimea pistei (deci si lungimea
	# rampelor, in fractii) se schimba la orice retus de traseu.
	_width_segs_ready = false
	_terr_cells = 0 # grila de teren se recoace odata cu curba
	for child in get_children():
		if child is Path3D:
			continue # curba editabila a pistelor custom ramane
		if _holds_declarations(child):
			# Declaratie de INTRARE, ca si curba — nu e output generat.
			# Nodul declara varful / rapa / gimmickul, nu e lucrul insusi.
			#
			# Testul e RECURSIV, si asta a fost un bug real: pana aici se
			# verifica doar copilul direct, desi documentatia lui `_node_peaks`
			# invita explicit la grupare („poti grupa varfurile sub un Node3D").
			# Un grup e un Node3D oarecare, fara owner in cod — deci pica la
			# `child.free()` si ducea cu el toate declaratiile dinauntru.
			# Se vedea ca „nodurile dispar la primul Regenerate", fara nimic in
			# consola.
			continue
		if child.owner != null:
			continue # asezat de mana in editor, salvat in scena
		child.free()
	_build_curve()
	# Se aduna din nou la fiecare regenerare, altfel Regenerate in editor ar
	# lasa steguletele sa ocoleasca si campuri care nu mai exista.
	_built_ice_fields.clear()
	# Canalele INAINTEA samplerului: el sapa dupa ele, iar restul generatorilor
	# intreaba tot de aici unde e golul din sosea.
	_resolve_channels()
	# Gaurile cerute de pasajele rotitoare, din acelasi motiv si in acelasi loc:
	# tot ce emite carosabil intreaba mai jos `_road_gap`.
	_resolve_span_holes()
	# Dupa coacerea curbei (deci si a rutelor), inainte de orice generator care
	# aseaza ceva langa drum: toti citesc sloturi SI cota terenului de aici.
	#
	# Samplerul primeste SI latimea de referinta, SI profilul pe puncte coapte.
	# Prima ramane pentru raspunsurile care nu au un loc anume in vedere
	# (praguri, bugete); a doua e pentru tot ce stie UNDE se afla — banda de
	# protectie a asfaltului, buza rapelor, malul lagunei, sloturile de decor.
	# Pe o pista fara profil declarat lista e goala, deci samplerul raspunde
	# exact ca inainte.
	_sampler = TrackSideSampler.new(baked, _dists, _points(), half_width,
		float(_world_seed() % 1000) * 0.01, _ravines(),
		theme_flag("seabed_drop", 0.0), _branch_corridor_points(),
		_lagoon_poly(), lagoon_depth, _channels, _peak_specs() + _node_peaks(),
		_cornice_ravines(), _baked_widths(), _branch_carve_points(),
		_viaduct_ravines(), _overpass_ranges(), _ravine_floors())
	# Tarmul: implicit lenes (atol), dar temele vulcanice il pot strange.
	# Vezi TrackSideSampler.shore_in / shore_out.
	_sampler.shore_in = float(theme_flag("shore_band_in",
		TrackSideSampler.SHORE_BAND_IN))
	_sampler.shore_out = float(theme_flag("shore_band_out",
		TrackSideSampler.SHORE_BAND_OUT))
	_sampler.lagoon_in = float(theme_flag("lagoon_band_in",
		TrackSideSampler.LAGOON_BAND_IN))
	_sampler.lagoon_out = float(theme_flag("lagoon_band_out",
		TrackSideSampler.LAGOON_BAND_OUT))
	_sampler.lagoon_inner = float(theme_flag("lagoon_inner",
		TrackSideSampler.LAGOON_INNER))
	_sampler.lagoon_rim = float(theme_flag("lagoon_rim",
		TrackSideSampler.LAGOON_RIM))
	_build_environment()
	_build_road()
	_build_branch_surfaces()
	_build_walls()
	_build_viaduct_nets()
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
	_lane_bias.clear()
	for frac in _train_along_fracs():
		_build_train_along(frac)
	for frac in _avalanche_fracs():
		_build_avalanche(frac)
	for rg in _ice_field_ranges():
		_build_ice_field(rg)
	for frac in _hummock_fracs():
		_build_hummock(frac)
	# Gimmickurile plantate ca noduri, DUPA cele din cod: intra prin exact
	# aceleasi `_build_*`, deci un obstacol tras in viewport e identic cu unul
	# declarat intr-o fractie. Vezi `_node_hazards`.
	for hz in _node_hazards():
		_build_node_hazard(hz)
	for ch in _channels:
		# Un canal se trece ori pe pod, ori din saritura — nu amandoua. Cu
		# `jump: true` golul ramane gol si primeste in schimb o trambulina pe
		# toata latimea (vezi _build_channel_kicker).
		if bool(ch.get("jump", false)):
			_build_channel_kicker(ch)
		else:
			_build_lift_bridge(ch)
	_build_markers()
	_build_ice_flags()
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
		if _road_gap(i) or _road_ice(i):
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
		# Alfa din tema: noaptea norii nu sunt luminati de nimic, iar la 0.35
		# stratul ADUNAT peste un gradient intunecat iesea o pata alburie.
		sky_mat.sky_cover_modulate = Color(1.0, 0.97, 0.92,
			float(theme_flag("sky_cover_alpha", 0.35)))
	# Discul soarelui + haloul lui (sun_angle_max, 30 grade implicit) se
	# deseneaza din DirectionalLight. Pe o tema de noapte cu "luna" aproape
	# verticala iesea o pata luminoasa la zenit, in cadru la fiecare urcare.
	if not bool(theme_flag("sky_sun_disc", true)):
		sky_mat.sun_angle_max = 0.0
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
		env.fog_depth_begin = float(theme_flag("fog_begin", 90.0))
		# Capatul e steag de tema, nu constanta, si diferenta se vede pe munte:
		# la 250 m crestele de fundal (inele la 300-500 m) erau COMPLET
		# inghitite — 13 siluete asezate corect, zero vizibile. Intr-un peisaj
		# alpin distanta mare e chiar subiectul; intr-un canion, ceata care
		# taie la 250 m e ce ascunde marginea lumii.
		env.fog_depth_end = float(theme_flag("fog_end", 250.0))
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
	# Salturatia NU e cheie de tema cu buna stiinta: compensarea de saturatie
	# a apei (vezi nota de la _water_material) e masurata pe 1.18, si o pista
	# care ar schimba-o si-ar strica marea in tacere. Contrastul e — abaterea
	# lui misca mult mai putin apa si e prima parghie de "adancime" din
	# referinta (#207).
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = float(theme_flag("adjust_contrast", 1.05))
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
	#
	# De la #207 unghiul e cheie de tema ("sun_rotation_deg", default constanta
	# de mai sus): referinta de coasta are soare de dupa-amiaza tarzie, iar o
	# pista care vrea umbre mai lungi nu trebuie sa le ia pentru tot jocul.
	# Apa isi ia scanteierea din ACEEASI valoare (vezi _water_material).
	sun.rotation_degrees = _sun_rotation_deg()
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
	# Inelele pot veni din TEMA, ca si numele siluetelor.
	#
	# Cele implicite sunt calibrate pe butte-uri de desert (25-60 m, degajare
	# 95-160 m). Un varf alpin de 92 m la scara 1.2 e o formatiune de peste
	# 110 m latime, iar pe o pista de 535x400 m nu exista NICIUN punct la
	# 150-200 m de centroid care sa aiba si 95 m degajare fata de sosea:
	# masurat, 0 din 10 siluete incapeau si toata garda tipa. Muntele isi cere
	# propriile inele — mai departe si mai putine, fiindca fiecare piesa e de
	# trei ori cat un butte.
	var rings: Array = theme_flag("horizon_rings", HORIZON_RINGS)
	for ring in rings:
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
			# Plafonul era fix (355 m), legat de grila de teren a Dunelor. Pe o
			# lume mai mare el taia inelele inainte sa apuce sa caute: inelul
			# alpin de la 430 m pornea deja peste limita, deci bucla nu rula
			# niciodata. Acum plafonul urmeaza inelul CERUT, cu marja de
			# cautare — cine declara un inel departat primeste unde sa-l puna.
			var limit: float = maxf(float(ring["far"]) + 90.0, 355.0)
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
				picks = theme_picks[mini(rings.find(ring),
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
			#
			# Clasa GOALA = pastreaza atlasul modelului. Nu e un caz special
			# inventat: un varf alpin isi are benzile (padure/granit/zapada)
			# pictate in sloturi, iar o textura de roca intinsa peste ele le
			# sterge — pe captura, crestele ieseau portocalii ca dunele.
			var horizon_class := String(theme_flag("horizon_class", "rock"))
			# `horizon_classes` (dictionar prefix -> clasa) are prioritate:
			# un model spart pe noduri (corp de granit + calota de zapada) isi
			# ia fiecare parte clasa ei, ca ansamblurile din decorul manual.
			var horizon_classes: Dictionary = theme_flag("horizon_classes", {})
			if not horizon_classes.is_empty():
				Palette.apply_class_materials(model, horizon_classes)
			elif horizon_class.is_empty():
				Palette.apply_world_material(model)
			else:
				Palette.apply_triplanar_class(model, horizon_class)
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
## Culoarea peticelor de pamant din camp (#206): pamant batut, cald, intre
## verdele campului si ocrul drumului — acelasi sol, alta uzura. Se aplica
## prin lerp in vertex color, doar unde greutatea de iarba e mare.
const TERRAIN_DIRT_COLOR: Color = Color(0.56, 0.47, 0.32)


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
	# Zapada de creasta: null pe orice tema fara munte, deci restul pistelor
	# nu se schimba cu un pixel. Vezi "snow_line" in themes().
	var snow_tint: Variant = theme_flag("snow_tint", null)
	var snow_line := float(theme_flag("snow_line", 0.0))
	var snow_fade := maxf(float(theme_flag("snow_fade", 1.0)), 0.001)
	# Etajul de stanca, sub zapada. Vezi "rock_line" in themes().
	var rock_tint: Variant = theme_flag("rock_band_tint", null)
	var rock_line := float(theme_flag("rock_line", 0.0))
	var rock_fade := maxf(float(theme_flag("rock_fade", 1.0)), 0.001)
	var sea_y := _sampler.mean_road_y() + sea_level_offset
	# Peticele de pamant din camp (#206): zgomot world-space, doar unde e
	# iarba. Referinta nu are un covor verde uniform — are pete de pamant
	# batut si iarba rarita, si tocmai lipsa lor facea campul nostru sa arate
	# a masa de biliard. Functia e de pozitie pura, deci weld-ul de la
	# st.index() ramane intact (acelasi colt => aceeasi culoare).
	var dirt_noise := FastNoiseLite.new()
	dirt_noise.seed = _world_seed() ^ 0xD127
	dirt_noise.frequency = 0.035 # perioada ~28 m: pete de 8-15 m, ca in referinta
	dirt_noise.fractal_octaves = 2
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
					# Greutatea de iarba (0 = plaja/nisip, 1 = camp), plecata
					# spre shader prin COLOR.a: acolo alege intre perechea de
					# texturi de nisip si cea de iarba (#206).
					var grass_w := 0.0
					if inland != null:
						# Banda de trecere e larga (3.5 m de cota) tocmai ca sa
						# nu se vada o linie de nivel: dunele o strambă singure,
						# iar marginea iese neregulata, ca o plaja.
						var t := clampf((v.y - sea_y - BEACH_SAND_TOP)
							/ BEACH_FADE, 0.0, 1.0)
						grass_w = t * inland_mix
						tint = tint.lerp(inland as Color, grass_w)
						# Peticele de pamant, doar pe iarba: tenta coboara spre
						# pamant batut si greutatea spre nisip, ca in petic sa
						# se vada granulatia de sol, nu firele de iarba.
						var patch := smoothstep(0.55, 0.75,
							dirt_noise.get_noise_2d(v.x, v.z) * 0.5 + 0.5) \
							* grass_w
						if patch > 0.0:
							tint = tint.lerp(TERRAIN_DIRT_COLOR, patch * 0.65)
							grass_w *= 1.0 - patch * 0.75
					# ZAPADA DE CREASTA, oglinda plajei de mai sus: acolo
					# materialul se schimba SUB o cota, aici PESTE ea. Cota e
					# absoluta (nu relativa la media pistei) fiindca linia
					# zapezii e o proprietate a MUNTELUI, nu a traseului: daca
					# maine soseaua urca cu 10 m, zapada nu trebuie sa urce cu
					# ea. Vezi "snow_line" din themes().
					#
					# Greutatea de iarba se stinge odata cu albul: pe piatra
					# inghetata nu creste iarba, iar fara asta shader-ul ar
					# amesteca textura de pajiste peste zapada.
					# ETAJUL DE STANCA, intre pajiste si zapada. Aceeasi forma
					# ca zapada de mai jos (cota absoluta, margine zdrentuita
					# cu acelasi zgomot) fiindca e acelasi fel de lucru: o
					# limita de vegetatie pe munte, nu o proprietate a pistei.
					# Se aplica INAINTE de zapada, ca albul sa ramana ultimul
					# strat — pe creasta e zapada peste piatra, nu invers.
					if rock_tint != null:
						var rock_w := clampf(
							(v.y - rock_line) / rock_fade, 0.0, 1.0)
						rock_w = clampf(rock_w + dirt_noise.get_noise_2d(
							v.x * 0.5, v.z * 0.5) * 0.25, 0.0, 1.0)
						rock_w = smoothstep(0.0, 1.0, rock_w)
						if rock_w > 0.0:
							tint = tint.lerp(rock_tint as Color, rock_w)
							# Pe piatra nu creste iarba: greutatea coboara spre
							# textura de nisip/roca, exact ca sub zapada.
							grass_w *= 1.0 - rock_w
					if snow_tint != null:
						var snow_w := clampf(
							(v.y - snow_line) / snow_fade, 0.0, 1.0)
						# Marginea se zdrentuieste cu ACELASI zgomot ca peticele
						# de pamant: o linie de nivel perfecta se citeste ca
						# desen tehnic. Amplitudinea e in METRI de cota, deci
						# raportata la latimea benzii de trecere.
						snow_w = clampf(snow_w + dirt_noise.get_noise_2d(
							v.x * 0.6, v.z * 0.6) * 0.22, 0.0, 1.0)
						snow_w = smoothstep(0.0, 1.0, snow_w)
						if snow_w > 0.0:
							tint = tint.lerp(snow_tint as Color, snow_w)
							grass_w *= 1.0 - snow_w
					var col := tint * shade
					st.set_color(Color(col.r, col.g, col.b, grass_w))
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
	# Doua perechi de texturi gri (nisip pe plaja, iarba pe camp), amestecate
	# per-vertex prin COLOR.a in shader-ul de teren — vezi antetul lui
	# terrain_splat.gdshader pentru de ce nu StandardMaterial3D si de ce nu
	# doua suprafete. Culoarea vine tot din vertex colors; texturile doar o
	# moduleaza (gri, medie 0.850 toate patru, deci expunerea nu se misca).
	# Pe pistele fara inland_tint greutatea e 0 peste tot si randarea iese
	# identica cu vechea pereche de nisip, pixel cu pixel.
	var sand_tex := _tex("res://assets/textures/surface_sand.png")
	var grass_tex := _tex("res://assets/textures/surface_grass.png")
	if sand_tex != null and grass_tex != null:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/terrain_splat.gdshader")
		mat.set_shader_parameter("sand_micro", sand_tex)
		mat.set_shader_parameter("sand_macro",
			_tex("res://assets/textures/surface_sand_macro.png"))
		mat.set_shader_parameter("grass_micro", grass_tex)
		mat.set_shader_parameter("grass_macro",
			_tex("res://assets/textures/surface_grass_macro.png"))
		inst.material_override = mat
	else:
		# Checkout fara texturi: macar culoarea din vertex colors.
		var flat := StandardMaterial3D.new()
		flat.vertex_color_use_as_albedo = true
		flat.albedo_color = Color.WHITE
		flat.roughness = 0.95
		flat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		inst.material_override = flat

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
##
## Pragul asta NU e parghia cand marea citeste palid — am incercat, si n-a
## schimbat un pixel. Culoarea de larg se atinge la SEA_NEAR_DEPTH (14 m), deci
## ce conteaza e cata APA e acolo, nu unde pui pragul: pe Stromboli fundul era
## la 3 m pe 180 m de la mal, adica ~10% din rampa, si ar fi ramas palid cu
## orice sloturi. Reparatia a fost sa se SAPE (rapa de cornisa, adancime 16),
## nu sa se retuseze rampa.
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
	if _sampler == null or baked.is_empty():
		return
	# Canalele isi au apa lor, la cota LOR — un parau de munte curge la 4 m, nu
	# la nivelul marii. De aceea rularea nu mai e conditionata de steagul de
	# tema: o pista fara mare (Alpii) poate avea totusi un canal cu apa.
	_build_channel_water()
	if not theme_flag("water", false):
		return
	var sea_y := _sampler.mean_road_y() + sea_level_offset
	var root := Node3D.new()
	root.name = "Sea"
	add_child(root)
	_build_sea_far(root, sea_y)
	_build_sea_near(root, sea_y)
	if is_frozen():
		# LAC INGHETAT (Baikal): aceeasi geometrie de mare, dar e o PLACA — se
		# calca pe ea. Materialul e opac si iluminat (nu shaderul de apa cu
		# valuri), colorat din adancime prin `_ice_color`, iar dedesubt sta un
		# corp de coliziune cat toata placa: cine iese din culoarul marcat ruleaza
		# mai departe pe gheata (offroad, deci lent), nu cade in apa. De aceea nu
		# exista nici zona de repunere — nu e unde sa cazi.
		for child in root.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = _ice_sheet_material()
		var body := StaticBody3D.new()
		body.name = "IceSheet"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(SEA_FAR_EXTENT, 2.0, SEA_FAR_EXTENT)
		shape.shape = box
		body.add_child(shape)
		root.add_child(body)
		var c := _centroid()
		body.global_position = Vector3(c.x, sea_y - 1.0, c.z)
		return
	_build_quay_wall(sea_y)
	_build_far_shore(sea_y)
	_build_sea_respawn(sea_y)



## Cat de des se esantioneaza conturul lagunei cand se ridica cheiul.
const QUAY_STEP: float = 5.0
## Cat de departe de linia apei se citeste daca CHIAR e uscat in spate.
const QUAY_INLAND: float = 20.0
## Cat de lata e dala de deasupra zidului.
##
## [b]3 m, si latimea asta e chiar reclamatia dezvoltatorului.[/b] La 9 m dala
## iesea „o banda gri lata cat drumul, lipita de marginea dreapta a soselei pe
## tot cheiul" — masurat pe scanline la frac 0.48, luminanta 0.31-0.52 langa
## asfalt la 0.09, adica de patru ori mai deschisa, pe o fasie tot atat de lata
## cat carosabilul. Din masina nu se citea nici drum, nici mal: o placa.
##
## Dala NU e ce face treaba aici — treaba o face fata VERTICALA de sub ea
## (muchia dintre apa si uscat, si acoperirea treptelor grilei de tarm, vezi
## antetul lui `_build_quay_wall`). Dala doar acopera panta de mal de imediat
## in spatele muchiei, si pentru asta 3 m ajung: la 9 m acoperea si tot ce era
## intre chei si sosea, adica exact suprafata care nu trebuia sa existe.
##
## Verificat prin A/B in acelasi worktree, cu `quay_wall` stins: banda dispare
## complet si cheiul se citeste corect. Deci cauza era dala, nu latimea
## carosabilului, nu `QUAY_INLAND` (aia spune doar UNDE se considera ca e mal)
## si nu telecabina — toate incercate si eliminate inainte.
const QUAY_DECK: float = 3.0
## Cat de sus sta muchia cheiului peste apa.
##
## FIXA, nu citita din teren, si asta e chiar lectia primei incercari: cu
## inaltimea luata din `ground_y` la cativa metri in spate, muchia urma panta
## malului — adica exact suprafata pe care terenul o coboara sub apa — si
## zidul iesea o dantela de petice de 0.3-0.6 m, vizibila ca zgomot alb pe
## captura. Un chei real are gabarit constant fata de apa; unde malul e mai
## inalt, zidul intra in pamant si nu se vede, ceea ce e raspunsul corect.
const QUAY_FREEBOARD: float = 3.2


## ZIDUL DE CHEI: muchia dintre apa si uscat, construita, nu interpolata.
##
## De ce exista. Pe Chongqing apa nu se citea ca apa nici dupa ce culoarea,
## valoarea si sclipirile au fost calibrate pe diorama pixel cu pixel. Masurand
## referinta (`docs/track_briefs/img` -> bar/E_chei.png) a iesit ca semnalul
## cel mai tare nu e pe apa deloc: e ZIDUL de deasupra ei. Apa unei diorame
## incepe la o muchie verticala de beton, cu bolarzi si baloane de acostare;
## un camp nu are asa ceva, si de-aia o suprafata verde care se termina intr-o
## panta de pietris se citeste camp indiferent ce nuanta are.
##
## A doua problema pe care o rezolva: linia apei. Grila de tarm
## ([method _build_sea_near]) are celula de `water_cell` metri, deci conturul
## malului iesea o SCARA de trepte in unghi drept — masurat pe capturile rundei
## 6, zimti de zeci de pixeli, exact ce nu are un chei. Zidul e desenat pe
## conturul AUTORAT al lagunei, deci muchia lui e o polilinie neteda care
## acopera treptele grilei.
##
## Geometria: pentru fiecare esantion de pe contur, o fata verticala de la
## `sea_y - 2.5` pana la cota uscatului de la [constant QUAY_INLAND] metri in
## spate, plus o dala orizontala pana acolo. Culoarea de varf vine din vertex
## color, deci intra pe acelasi material ca parapetii — zero materiale in plus.
## Fara coliziune, deliberat: cheiul sta DINCOLO de marginea carosabilului, iar
## un corp fizic acolo ar prinde masinile care oricum cad in rau (gate-ul de
## repuneri e platit in alta parte, la racordul benzii).
func _build_quay_wall(sea_y: float) -> void:
	if not bool(theme_flag("quay_wall", false)):
		return
	var poly := _lagoon_poly()
	if poly.size() < 3:
		return
	var half := _world_extent() * 0.5
	var c := _centroid()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev: Dictionary = {}
	var emitted := 0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var seg := a.distance_to(b)
		var steps := maxi(int(seg / QUAY_STEP), 1)
		for k in steps + 1:
			if k == steps and i < poly.size() - 1:
				continue # nodul urmator il emite latura urmatoare
			var p := a.lerp(b, float(k) / float(steps))
			var cur := _quay_sample(p, b - a, poly, sea_y, c, half)
			if not prev.is_empty() and not cur.is_empty():
				_quay_quad(st, prev, cur)
				emitted += 1
			prev = cur
	if emitted == 0:
		return
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.name = "QuayWall"
	inst.mesh = st.commit()
	inst.material_override = _flat_material(
		Palette.color(Palette.CONCRETE), null, 1.0, 0.5,
		BaseMaterial3D.CULL_DISABLED)
	add_child(inst)


## Un esantion de chei, sau {} daca acolo nu e chei (uscatul e deja sub apa,
## sau punctul a iesit din panza de teren).
func _quay_sample(p: Vector2, along: Vector2, poly: PackedVector2Array,
		sea_y: float, c: Vector3, half: float) -> Dictionary:
	if absf(p.x - c.x) > half - QUAY_INLAND 			or absf(p.y - c.z) > half - QUAY_INLAND:
		return {}
	var n := Vector2(-along.y, along.x).normalized()
	# Normala catre APA: interiorul conturului de laguna.
	if not Geometry2D.is_point_in_polygon(p + n * 2.0, poly):
		n = -n
	var inland := p - n * QUAY_INLAND
	if _sampler.ground_y(inland.x, inland.y) < sea_y + 1.0:
		return {} # nu e mal, e larg — nimic de zidit
	return {"p": p, "n": n, "top": sea_y + QUAY_FREEBOARD, "base": sea_y - 2.5}


## Fasia de zid + dala dintre doua esantioane de chei.
func _quay_quad(st: SurfaceTool, a: Dictionary, b: Dictionary) -> void:
	# Betonul ud de la linia apei e INCHIS, cel de sus e curat: muchia dintre
	# ele e chiar ce spune ochiului unde se termina apa.
	var wet := Color(0.13, 0.14, 0.17)
	# Betonul de sus sta in aceeasi familie de VALOARE cu asfaltul de langa el
	# (memoria `rock-dark-nu-pe-bazalt`: variatia de valoare in familie, nu o
	# culoare noua). La 0.27 dala era cu un ton peste tot ce o inconjoara si
	# sarea in ochi de la 40 m; muchia dintre ea si apa o da contrastul cu
	# `wet`, care ramane neschimbat, nu luminozitatea dalei.
	var dry := Color(0.19, 0.20, 0.23)
	var pa: Vector2 = a["p"]
	var pb: Vector2 = b["p"]
	var fa0 := Vector3(pa.x, a["base"], pa.y)
	var fa1 := Vector3(pa.x, a["top"], pa.y)
	var fb0 := Vector3(pb.x, b["base"], pb.y)
	var fb1 := Vector3(pb.x, b["top"], pb.y)
	for tri: Array in [[fa0, fa1, fb0], [fa1, fb1, fb0]]:
		for v: Vector3 in tri:
			st.set_color(wet if v.y < a["top"] - 0.01 and v.y < b["top"] - 0.01 				else dry)
			st.add_vertex(v)
	# Dala orizontala pana la uscat: acopera panta de sub ea, deci malul se
	# termina in muchie, nu in trecere pastoasa.
	var ia: Vector2 = pa - (a["n"] as Vector2) * QUAY_DECK
	var ib: Vector2 = pb - (b["n"] as Vector2) * QUAY_DECK
	var ca := Vector3(ia.x, a["top"], ia.y)
	var cb := Vector3(ib.x, b["top"], ib.y)
	for tri2: Array in [[fa1, ca, fb1], [ca, cb, fb1]]:
		for v2: Vector3 in tri2:
			st.set_color(dry)
			st.add_vertex(v2)


## MALUL OPUS. Fara el, apa se intinde pana la orizont si un plan care nu se
## termina nicaieri se citeste CAMP, nu rau — asta a fost verdictul rundei 6.
##
## Nu e teren: panza de teren se intinde doar cat bucla plus o margine
## ([method _world_extent]), iar malul opus trebuie sa stea la 100-160 m
## DINCOLO de tarm, adica in afara ei. E o prisma joasa asezata pe planul apei,
## opaca si intunecata, exact cat sa inchida apa si sa primeasca siluetele de
## turnuri. Ceata temei o preia oricum de la 150 m in sus.
##
## Cheia de tema e o lista de maluri, fiecare cu polilinia lui in plan XZ,
## inaltimea peste apa si adancimea spre spate. Doua maluri care se ating
## intr-un varf fac exact confluenta: o pana de uscat cu apa pe amandoua
## partile, cu varful spre jucator.
func _build_far_shore(sea_y: float) -> void:
	var banks: Array = theme_flag("far_shore", [])
	if banks.is_empty():
		return
	var c := _centroid()
	var runs := _far_shore_runs(banks, sea_y)
	if runs.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for bank: Dictionary in runs:
		_far_shore_run(st, bank, sea_y, c)
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.name = "FarShore"
	inst.mesh = st.commit()
	inst.material_override = _flat_material(
		Palette.color(Palette.CONCRETE), null, 1.0, 0.5,
		BaseMaterial3D.CULL_DISABLED)
	add_child(inst)


## Poliliniile de mal TAIATE acolo unde nu mai au apa in fata, si lipite acolo
## unde se continua una pe alta.
##
## Amandoua taieturile sunt din masuratoare, nu din precautie. Malurile autorate
## fac un inel in jurul intregii periferii, iar terenul pistei nu se termina
## unde se termina bucla: din 9 segmente, 3 cadeau PESTE uscat — vertecsii lor
## masurati la cota 16.3, 35.5 si 41.1 m, cu prisma intre 1 si 15 m. Unde
## dealul e mai inalt decat prisma, ea dispare in el (inofensiv); unde coasta
## URCA prin ea, iese exact ce a vazut criticul: o pata bleumarin cu muchie
## dreapta asezata peste terenul gri, adica o pata de ulei pe un platou.
##
## A doua: doua maluri care se termina in acelasi punct erau doua rulari
## independente de SurfaceTool, fiecare cu normala segmentului ei, deci in
## nodul comun spatele lor pleca in doua directii — o crestatura in "V" la
## (95, 335), acolo unde de fapt cele doua polilinii sunt aproape coliniare
## (directiile lor difera cu 7 grade). Lipite intr-o singura polilinie,
## normalele se mediaza si crestatura dispare fara sa se piarda nimic.
func _far_shore_runs(banks: Array, sea_y: float) -> Array:
	var runs: Array = []
	for bank: Dictionary in banks:
		var line: Array = bank.get("line", [])
		var run: Array[Vector2] = []
		for i in maxi(line.size() - 1, 0):
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			# Segmentul are voie sa existe doar daca apa e in fata lui pe toata
			# lungimea: capete SI mijloc sub linia apei.
			var wet := _far_shore_wet(a, sea_y) and _far_shore_wet(b, sea_y) 				and _far_shore_wet(a.lerp(b, 0.5), sea_y)
			if not wet:
				if run.size() > 1:
					runs.append({"line": run, "h": bank.get("h", 9.0),
						"depth": bank.get("depth", 80.0)})
				run = []
				continue
			if run.is_empty():
				run.append(a)
			run.append(b)
		if run.size() > 1:
			runs.append({"line": run, "h": bank.get("h", 9.0),
				"depth": bank.get("depth", 80.0)})
	# Lipirea: doua rulari care se ating in acelasi punct sunt un singur mal.
	var merged: Array = []
	for run: Dictionary in runs:
		var line: Array = run["line"]
		if not merged.is_empty():
			var prev: Dictionary = merged[-1]
			var pline: Array = prev["line"]
			if (pline[-1] as Vector2).distance_to(line[0]) < 0.5 					and is_equal_approx(float(prev["h"]), float(run["h"])):
				for i in range(1, line.size()):
					pline.append(line[i])
				continue
		merged.append(run)
	return merged


## E apa in fata malului in punctul asta? Panza de teren se intinde doar cat
## bucla plus o margine, deci in afara ei nu exista uscat de care sa te lovesti
## si raspunsul e „da" fara sa mai intrebi sampler-ul.
func _far_shore_wet(p: Vector2, sea_y: float) -> bool:
	var c := _centroid()
	var half := _world_extent() * 0.5
	if absf(p.x - c.x) > half or absf(p.y - c.z) > half:
		return true
	return _sampler.ground_y(p.x, p.y) < sea_y - 1.0


## Un mal intreg: fata verticala + coama, cu normalele MEDIATE pe noduri.
##
## Normala per NOD, nu per segment: cu una per segment fiecare patrulater isi
## trimitea spatele in alta directie, deci intre doua segmente ramanea o pana
## deschisa pe coama (la coturi convexe) sau o suprapunere (la cele concave).
## Mediata, coama e o banda continua.
##
## Inaltimea nu mai e constanta: 800 m de creasta la exact 12 m citeau ZID, nu
## mal. Doua sinusoide necomensurabile pe distanta parcursa o plimba cu ±22%,
## adica destul cat silueta sa aiba profil, prea putin cat sa se vada tiparul.
func _far_shore_run(st: SurfaceTool, bank: Dictionary, sea_y: float,
		c: Vector3) -> void:
	var line: Array = bank["line"]
	var h := float(bank.get("h", 9.0))
	var depth := float(bank.get("depth", 80.0))
	# Culoarea de la linia apei e mai INCHISA decat coama: un mal care se
	# termina brusc in apa pluteste, unul care se intuneca la baza se aseaza in
	# ea. Aceleasi trei valori pentru toate temele care au far_shore.
	var foot := Color(0.05, 0.05, 0.07)
	var face := Color(0.09, 0.09, 0.12)
	var crown := Color(0.13, 0.13, 0.17)
	var normals: Array[Vector2] = []
	var dist: Array[float] = []
	var run := 0.0
	for i in line.size():
		var a: Vector2 = line[maxi(i - 1, 0)]
		var b: Vector2 = line[mini(i + 1, line.size() - 1)]
		var t := (b - a)
		if t.length() < 0.001:
			t = Vector2(1.0, 0.0)
		var n := Vector2(-t.y, t.x).normalized()
		if n.dot((line[i] as Vector2) - Vector2(c.x, c.z)) < 0.0:
			n = -n
		normals.append(n)
		if i > 0:
			run += (line[i] as Vector2).distance_to(line[i - 1])
		dist.append(run)
	for i in line.size() - 1:
		var pa: Vector2 = line[i]
		var pb: Vector2 = line[i + 1]
		var ha := h * _far_shore_height(dist[i])
		var hb := h * _far_shore_height(dist[i + 1])
		var na: Vector2 = normals[i]
		var nb: Vector2 = normals[i + 1]
		var a0 := Vector3(pa.x, sea_y - 2.0, pa.y)
		var a1 := Vector3(pa.x, sea_y + ha, pa.y)
		var b0 := Vector3(pb.x, sea_y - 2.0, pb.y)
		var b1 := Vector3(pb.x, sea_y + hb, pb.y)
		var a2 := Vector3(pa.x + na.x * depth, sea_y + ha * 0.8,
			pa.y + na.y * depth)
		var b2 := Vector3(pb.x + nb.x * depth, sea_y + hb * 0.8,
			pb.y + nb.y * depth)
		for tri: Array in [[a0, a1, b0], [a1, b1, b0]]:
			for v: Vector3 in tri:
				if v.y <= sea_y - 1.99:
					st.set_color(foot)
				elif v.y < sea_y + minf(ha, hb) - 0.01:
					st.set_color(face)
				else:
					st.set_color(crown)
				st.add_vertex(v)
		for tri2: Array in [[a1, a2, b1], [a2, b2, b1]]:
			for v2: Vector3 in tri2:
				st.set_color(crown)
				st.add_vertex(v2)


## Cat de inalt e malul la `d` metri de la capatul lui, ca fractie din `h`.
func _far_shore_height(d: float) -> float:
	return 1.0 + 0.14 * sin(d * 0.0163) + 0.08 * sin(d * 0.0071 + 1.7)


## Marea e INGHETATA pe tema asta (`frozen`): placa se randeaza ca gheata si
## are coliziune. Vezi `_build_water`.
func is_frozen() -> bool:
	return bool(theme_flag("frozen", false))


## Apa dintr-un canal care NU e la nivelul marii.
##
## Pe Okinawa stramtoarea e sapata sub `sea_y`, deci grila de tarm a lui
## [method _build_sea_near] o umple din mers si aici nu e nimic de facut. Un
## parau de munte insa are cota lui, cu 60 m peste media soselei, si nici o
## suprafata globala nu il poate acoperi — de aceea fiecare canal cu
## `water_y_drop` declarat isi primeste banda proprie.
##
## Geometria e o BANDA in lungul canalului, nu o grila peste toata lumea:
## canalul e un culoar ingust (water_half + bank lateral, reach in lungime),
## iar o grila de talia celei de mare ar fi emis zeci de mii de celule uscate
## ca sa gaseasca cateva ude. Adancimea intra tot in alfa culorii de vertex,
## exact ca la mare (vezi _sea_color): shaderul de apa citeste COLOR.a ca
## adancime, nu ca opacitate.
func _build_channel_water() -> void:
	if _channels.is_empty():
		return
	var mat := _water_material()
	for ch in _channels:
		var drop := float(ch.get("water_y_drop", -1.0))
		if drop < 0.0:
			continue # canal la nivelul marii — il acopera grila de tarm
		var o: Vector3 = ch["origin"]
		var along: Vector3 = ch["along"]
		var across: Vector3 = ch["across"]
		var water_y := o.y - drop
		var half: float = float(ch["water_half"]) + float(ch["bank"]) * 0.5
		var reach: float = ch["reach"]
		# Pasul lateral e mai fin decat cel longitudinal: pe latime se vede
		# rampa de adancime (mal -> senal -> mal), pe lungime apa e uniforma.
		var nu := maxi(2, int(round(half * 2.0 / 3.0)))
		var nv := maxi(2, int(round(reach * 2.0 / 12.0)))
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		const CORNERS: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0),
			Vector2(0, 1), Vector2(1, 1)]
		const ORDER: Array[int] = [0, 1, 2, 1, 3, 2]
		for iv in nv:
			for iu in nu:
				var quad: Array[Vector3] = []
				for corner: Vector2 in CORNERS:
					var u := (float(iu) + corner.x) / float(nu) * 2.0 - 1.0
					var v := (float(iv) + corner.y) / float(nv) * 2.0 - 1.0
					var p := o + across * (u * half) + along * (v * reach)
					p.y = water_y
					quad.append(p)
				# Adancimea reala sub fiecare colt: terenul e deja sapat de
				# _carve_channel, deci o citim, nu o presupunem.
				var d: Array[float] = []
				var wet := false
				for p: Vector3 in quad:
					var dd := water_y - _sampler.ground_y(p.x, p.z)
					d.append(dd)
					if dd > 0.0:
						wet = true
				if not wet:
					continue # patrat uscat pe tot — malul, nu apa
				for k: int in ORDER:
					# Adancimea se normalizeaza pe ADANCIMEA REALA A APEI din
					# canalul asta, nu pe cea a marii.
					#
					# Prima versiune trimitea `t * SEA_NEAR_DEPTH` cu `t`
					# raportat la `depth` (18 m, adica adancimea SAPATURII).
					# Apa masurata in albie are insa 3 m, deci intra in
					# _sea_color ca ~2.3 dintr-o scara de 14 — adica exact in
					# banda de mal, intre spuma (0.6) si recif (5). Rezultatul
					# se vede in prima randare: un parau aproape alb, care
					# citea ca ghetar. Cu scara refacuta pe adancimea proprie,
					# aceiasi 3 m acopera tot gradientul, de la spuma la mal
					# pana la culoarea plina la mijloc.
					var t := clampf(d[k] / _channel_water_depth(ch), 0.0, 1.0)
					st.set_color(_sea_color(t * SEA_NEAR_DEPTH))
					st.add_vertex(quad[k] - global_position)

		st.generate_normals()
		var mesh := st.commit()
		if mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "ChannelWater_%s" % String(ch.get("label", "canal"))
		mi.mesh = mesh
		# material_override, ca la SeaNear: acelasi obiect de material pentru
		# toate suprafetele de apa din pista, deci un singur material in
		# numaratoarea garzii (tools/probe_decor.gd).
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_build_channel_respawn(ch, water_y)


## Cata APA are efectiv un canal, in metri.
##
## NU e `depth`: aia e cat de adanc s-a SAPAT sub cota soselei. Apa sta la
## `water_y_drop` sub aceeasi cota, deci grosimea stratului e diferenta lor.
## Un parau sapat 18 m cu apa la 15 m are 3 m de apa — si dupa cei 3 m se
## normalizeaza culoarea, altfel gradientul de adancime nu se vede deloc.
func _channel_water_depth(ch: Dictionary) -> float:
	return maxf(float(ch["depth"]) - float(ch.get("water_y_drop", 0.0)), 0.5)


## Cati metri INAINTE de buza e repus cine cade in canal.
##
## Nu cei 14 m impliciti ai lui RespawnZone: golul se trece cu ~24 m/s, iar
## repunerea porneste de la 9. De la 14 m de trambulina nu ajungi la viteza,
## cazi din nou, si bucla aia tine masina in apa toata cursa (vazut pe Alpii,
## la paraul vaii). Aceeasi cifra si acelasi motiv ca LiftBridgeHazard.FALL_BACKOFF.
##
## Nu mai mult: la 150 m ProbeRace pe Alpii dadea MAI multe repuneri (17-18
## fata de 8-10 pe aceleasi seed-uri) — repus inainte de virajul dinaintea
## dreptei, AI-ul il ia cu frana si ajunge la trambulina mai incet decat cel
## repus la 70 m, care sta pe dreapta finala cu pedala la fund.
const CHANNEL_FALL_BACKOFF: float = 70.0

## Cine rateaza saritura peste canal cade in apa si e repus pe traseu.
##
## Acelasi tipar ca plasa de sub creasta de fly-off si ca volumul de mare:
## un [RespawnZone] sub suprafata, destul de jos cat stropul de la intrare sa
## apuce sa se vada, si destul de lat cat sa prinda si pe cine cade oblic.
## Cu spatiu de ELAN in fata (CHANNEL_FALL_BACKOFF), nu doar repus pe buza.
func _build_channel_respawn(ch: Dictionary, water_y: float) -> void:
	var o: Vector3 = ch["origin"]
	var along: Vector3 = ch["along"]
	var top := water_y - 0.6
	var bottom := water_y - float(ch["depth"]) - 6.0
	var zone := RespawnZone.new()
	zone.name = "ChannelFall_%s" % String(ch.get("label", "canal"))
	zone.backoff_m = CHANNEL_FALL_BACKOFF
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var width: float = (float(ch["water_half"]) + float(ch["bank"]) * 0.5) * 2.0
	box.size = Vector3(width, top - bottom, float(ch["reach"]) * 2.0)
	shape.shape = box
	zone.add_child(shape)
	zone.transform = Transform3D(
		Basis.looking_at(along, Vector3.UP),
		Vector3(o.x, (top + bottom) * 0.5, o.z) - global_position)
	add_child(zone)


## Largul: doua triunghiuri. Nu are nevoie de mai mult.
func _build_sea_far(root: Node3D, sea_y: float) -> void:
	var c := _centroid()
	var h := SEA_FAR_EXTENT * 0.5
	var y := sea_y - SEA_FAR_DROP
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var deep := water_tint(Palette.SEA_DEEP)
	if is_frozen():
		deep = _ice_color(SEA_NEAR_DEPTH)
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
	# Cat de fin e conturul malului. SEA_CELL (9.5 m) e calibrat pe o laguna cu
	# plaja: acolo apa se termina pe nisip in panta, deci muchia grilei nu se
	# vede. Pe un chei apa se termina in ZID, iar celula de 9.5 m devine chiar
	# forma malului: masurat pe captura rundei 5, linia apei era o SCARA de
	# trepte in unghi drept de ~30x18 px, nu o muchie. In diorama malul e o
	# dreapta neta de-a lungul cheiului. Se plateste in triunghiuri (patratic),
	# de aceea e cheie de tema si nu o constanta coborata pentru toata lumea.
	var cell := maxf(float(theme_flag("water_cell", SEA_CELL)), 1.0)
	var cells := int(round(size / cell))
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
##   godot --path . res://tools/Snapshot.tscn -- --track=1 --size=300
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
##
## `mul_key` alege TENTA. Exista fiindca Chongqing are doua rauri de nuante
## opuse pe acelasi luciu: o singura tenta globala nu poate servi si verdele
## (care are nevoie de albastru urcat) si brunul (pe care exact aia il face
## gri). Masurat cu tenta verde pe amandoua: Jialing saturatie 0.25, Yangtze
## 0.10 — adica nisip ud, nu apa noroioasa. Cheia lipsa se intoarce la
## "water_mul", deci temele cu un singur rau nu se schimba.
func water_tint(slot: int, gain: float = 1.0,
		mul_key: String = "water_mul",
		desat_key: String = "water_desat") -> Color:
	var c := Palette.color(slot)
	var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	# Doua chei de tema aplicate O DATA, aici, pe toate culorile apei (rampa,
	# spuma, glint — toate trec prin functia asta, deci raman in familie):
	#  - "water_desat" (0..1) trage culoarea spre luminanta EI, in jurul
	#    luminantei, exact invers fata de WATER_SATURATION_FIX. Chongqing:
	#    raurile de noapte sunt verde tulbure/maro noroios cu saturatie mica
	#    (brief §4), nu teal de recif.
	#  - "water_mul" — tenta multiplicativa (lumina de oras gri-verde), fara
	#    slot nou de paleta.
	# `desat_key` exista pentru acelasi motiv ca `mul_key`: cele doua rauri ale
	# Chongqing-ului nu suporta aceeasi desaturare. Masurat pe RUST_METAL
	# (91461E, saturatie 0.79): trecut prin water_desat 0.84 iese la 0.19 —
	# gri-maroniu, adica NOROI, exact verdictul criticului. Verdele are nevoie
	# de desaturarea mare (diorama: 0.18), brunul de una mica (diorama: 0.42).
	var desat := clampf(float(theme_flag(desat_key,
		theme_flag("water_desat", 0.0))), 0.0, 1.0)
	var mul: Color = theme_flag(mul_key, theme_flag("water_mul", Color.WHITE))
	var k := (1.0 - desat) / WATER_SATURATION_FIX
	# `gain` se aplica in sRGB, INAINTE de conversie: e „cata lumina cade pe
	# apa" pe o tema de noapte (water_dim), si trebuie sa citeasca perceptual.
	# Un darkened() dupa conversie (in liniar) la 0.3 iesea 58% luminozitate
	# pe ecran — apa de amiaza cu putin fum, nu rau de noapte (masurat r2).
	return Color(
		(lum + (c.r - lum) * k) * WATER_GAIN * gain * mul.r,
		(lum + (c.g - lum) * k) * WATER_GAIN * gain * mul.g,
		(lum + (c.b - lum) * k) * WATER_GAIN * gain * mul.b).srgb_to_linear()


## Culoarea unui varf dupa cata apa are sub el.
##
## Spuma e GEOMETRIE, nu depth fade: banda de varfuri unde apa abia acopera
## tarmul primeste foam_white. Un depth fade ar fi cerut DEPTH_TEXTURE, adica
## un pas de citire a adancimii pe fiecare pixel de apa — pe mobil, exact
## genul de cost pe care nu-l vede nicio garda din proiect.
func _sea_color(d: float) -> Color:
	if is_frozen():
		return _ice_color(d)
	# Sloturile vin din TEMA, nu fix din paleta recifului. Pana la paraul din
	# Alpii singura apa din joc era laguna Okinawei, deci recif+larg era o
	# alegere buna; pe un parau de munte, insa, aceleasi doua culori dadeau o
	# lagunca turcoaz intre brazi — se vede in snapshots/alpii.png de la prima
	# randare. Apa rece nu e apa calda cu alt cer deasupra.
	# Aceeasi "lumina" de tema ca in _water_material (water_dim).
	var dim := clampf(float(theme_flag("water_dim", 1.0)), 0.0, 1.0)
	var reef := water_tint(theme_flag("water_shallow_slot",
		Palette.REEF_SHALLOW), dim)
	# Aceleasi trepte de lumina ca in _water_material — promisiunea "doua surse
	# de adevar pentru culoarea apei s-ar desincroniza la prima tema noua" se
	# aplica si aici.
	var deep := water_tint(theme_flag("water_deep_slot",
		Palette.SEA_DEEP), dim * float(theme_flag("water_deep_gain", 1.0)))
	# Spuma NU e alb curat, ci alb spart cu recif.
	#
	# La FOAM_WHITE pur, banda de tarm citea ca zapada, nu ca sparger de val —
	# si o citea lat, fiindca varfurile USCATE ale celulelor de mal sunt tot
	# spuma si isi intind culoarea peste toata celula prin interpolare.
	var foam := water_tint(Palette.FOAM_WHITE, dim).lerp(reef, 0.35)
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


## Culoarea PLACII DE GHEATA dupa cata apa are sub ea (tema `frozen`).
##
## Aceeasi intrebare ca la `_sea_color`, alt raspuns: langa mal gheata e
## subtire si prinsa cu zapada (alb-albastrui), la larg e groasa si se vede
## adancul prin ea (turcoaz spre albastru inchis). Culorile sunt LITERALE, nu
## trecute prin `water_tint`: materialul e iluminat, nu unshaded, deci nu are
## nevoie nici de srgb_to_linear, nici de compensarea de saturatie.
func _ice_color(d: float) -> Color:
	# Terenul de langa drumul de gheata sta la ~15 cm sub placa (GROUND_DROP),
	# deci aproape toata gheata pe care o vezi din masina are "adancime" mica —
	# rampa trebuie sa ajunga la turcoaz repede, altfel lacul iese alb.
	# Se INMULTESC cu textura de clasa (turcoaz mediu, cu crapaturi si bule),
	# deci "alb" aici inseamna textura neatinsa, iar "adanc" o intuneca.
	var shore := Color(1.0, 1.0, 1.0)
	var thin := Color(0.92, 0.97, 0.98)
	var deep := Color(0.62, 0.80, 0.84)
	var c: Color
	if d < 0.12:
		c = shore.lerp(thin, clampf(d / 0.12, 0.0, 1.0))
	else:
		c = thin.lerp(deep, clampf((d - 0.12) / (SEA_REEF_DEPTH - 0.12), 0.0, 1.0))
	c.a = 1.0
	return c


var _ice_sheet_mat: StandardMaterial3D

## Materialul placii de gheata: opac, iluminat, culoare din vertex (adancime),
## granulatia stratului de detaliu al lumii peste, luciu mai mare decat orice
## sol. Unul singur pentru ambele mesh-uri, ca la apa.
func _ice_sheet_material() -> StandardMaterial3D:
	if _ice_sheet_mat != null:
		return _ice_sheet_mat
	# Luciu MIC: cu 0.28/0.75 soarele jos punea o pata alba cat jumatate de
	# ecran pe placa (masurat pe snapshot la frac 0.30, si tot acolo cu
	# 0.55/0.35). Gheata cu zapada suflata pe ea nu e oglinda.
	_ice_sheet_mat = _ice_class_material(Color.WHITE, 0.75, 0.2)
	_ice_sheet_mat.cull_mode = BaseMaterial3D.CULL_BACK
	return _ice_sheet_mat


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
	# Aceleasi sloturi ca in _sea_color, din acelasi motiv: doua surse de
	# adevar pentru culoarea apei s-ar desincroniza la prima tema noua.
	# Shaderul e UNSHADED (contractul #2): apa nu vede nici soarele, nici
	# ambientul, deci pe o tema de noapte ramane apa de amiaza daca nu i se
	# spune. `water_dim` e lumina pe care ar fi primit-o — se aplica pe toate
	# culorile, o data, aici si in _sea_color.
	var dim := clampf(float(theme_flag("water_dim", 1.0)), 0.0, 1.0)
	# "Cata lumina primeste" fiecare treapta a rampei, ca FACTOR peste dim.
	# Pana aici singurul mod de a face apa mai adanca sa arate mai adanca era
	# sa-i dai alt SLOT — adica alta nuanta. Pe o laguna de recif e corect
	# (turcoaz -> albastru), pe un rau tulbure nu: Yangtze-ul e aceeasi apa
	# maro si la mal si in mijloc, doar mai intunecata. Fara treptele astea,
	# "adanc" trebuia autorat cu o a doua culoare, iar amestecul dintre doua
	# familii de culoare pe acelasi luciu de apa iese OLIV (vezi runda 4).
	# Implicit 1.0 => exact comportamentul de dinainte pe toate pistele vechi.
	var deep_k := float(theme_flag("water_deep_gain", 1.0))
	var shore_k := float(theme_flag("water_shore_gain", 1.0))
	var shallow := water_tint(theme_flag("water_shallow_slot",
		Palette.REEF_SHALLOW), dim)
	var deep := water_tint(theme_flag("water_deep_slot",
		Palette.SEA_DEEP), dim * deep_k)
	# Nisipul ud de la linia apei: nisipul de coral, intunecat putin — apa
	# uda nisipul inainte sa-l acopere. Slot de tema: un rau de noapte n-are
	# plaja crem la mal.
	var shore := water_tint(theme_flag("water_shore_slot",
		Palette.CORAL_SAND), dim * shore_k).darkened(0.12)
	var foam := water_tint(Palette.FOAM_WHITE, dim).lerp(shallow, 0.35)
	_water_mat.set_shader_parameter("ramp_strength", 1.0)
	_water_mat.set_shader_parameter("shore_col", Vector3(shore.r, shore.g, shore.b))
	_water_mat.set_shader_parameter("shallow_col",
		Vector3(shallow.r, shallow.g, shallow.b))
	_water_mat.set_shader_parameter("deep_col", Vector3(deep.r, deep.g, deep.b))
	# Spuma, scanteierea si hula sunt chei de tema (implicitele = Okinawa):
	# un rau noroios sub burnita n-are nici spuma alba, nici soare de reflectat.
	_water_mat.set_shader_parameter("foam_strength",
		float(theme_flag("water_foam", 0.75)))
	_water_mat.set_shader_parameter("foam_col", Vector3(foam.r, foam.g, foam.b))
	_water_mat.set_shader_parameter("glint_strength",
		float(theme_flag("water_glint", 0.55)))
	# SPRE soare: inversul directiei in care bat razele. Din aceeasi rotatie
	# ca lumina reala (theme "sun_rotation_deg"), ca scanteierea sa cada corect
	# si pe pistele care isi coboara soarele.
	var sun_rot := _sun_rotation_deg()
	var to_sun := -(Basis.from_euler(Vector3(
		deg_to_rad(sun_rot.x), deg_to_rad(sun_rot.y),
		deg_to_rad(sun_rot.z))) * Vector3.FORWARD)
	_water_mat.set_shader_parameter("sun_dir", to_sun)
	# v3: creste de hula si trepte de adancime. Doua intrerupatoare, ambele in
	# lista de stins la profilarea pe device — crestele costa 2 sin + 2 pow,
	# treptele nu costa nimic (aceleasi esantioane).
	#
	# Directia hulei NU e aleatoare si nici legata de pista: bate dinspre soare,
	# adica dinspre partea din care si scanteierea vine. Doua directii diferite
	# ar fi dat o mare care sclipeste intr-o parte si curge in alta.
	_water_mat.set_shader_parameter("crest_strength",
		float(theme_flag("water_crest", 0.85)))
	_water_mat.set_shader_parameter("crest_dir",
		Vector2(to_sun.x, to_sun.z).normalized())
	_water_mat.set_shader_parameter("band_strength",
		float(theme_flag("water_band", 0.60)))
	# --- v5 (runda 6). Trei chei de SUPRAFATA, nu de culoare. Motivul e masurat
	# si sta scris pe larg in water.gdshader: apa noastra avea 90% din pixeli
	# intre luminanta 22 si 26 si exact aceeasi valoare de la orizont pana in
	# prim-plan, in timp ce diorama are ecart intercuartilic de ~12 puncte si
	# isi dubleaza valoarea pe adancimea cadrului. Fara variatie de valoare pe
	# suprafata, orice reglaj de nuanta iese linoleum luminat.
	# Toate trei au implicitul = comportamentul de dinainte, deci Okinawa,
	# Baikal, Alpii si Stromboli nu se misca.
	_water_mat.set_shader_parameter("facet_strength",
		float(theme_flag("water_facet", 0.0)))
	_water_mat.set_shader_parameter("facet_count",
		float(theme_flag("water_facet_count", 5.0)))
	_water_mat.set_shader_parameter("facet_scale",
		float(theme_flag("water_facet_scale", 0.10)))
	_water_mat.set_shader_parameter("facet_wobble",
		float(theme_flag("water_facet_wobble", 0.35)))
	_water_mat.set_shader_parameter("facet_warp",
		float(theme_flag("water_facet_warp", 0.22)))
	_water_mat.set_shader_parameter("facet_ref",
		float(theme_flag("water_facet_ref", 0.0)))
	_water_mat.set_shader_parameter("facet_near_max",
		float(theme_flag("water_facet_near", 2.5)))
	# RUNDA 11: marimea placii ceruta in PIXELI, nu printr-o distanta de
	# referinta. Vezi `facet_px` in shader — o distanta de calibrare nu poate fi
	# corecta si de pe cornisa (27 m peste apa) si de pe tablier (3.3 m).
	_water_mat.set_shader_parameter("facet_px",
		float(theme_flag("water_facet_px", 0.0)))
	_water_mat.set_shader_parameter("facet_px_max",
		float(theme_flag("water_facet_px_max", 32.0)))
	_water_mat.set_shader_parameter("facet_gate",
		float(theme_flag("water_facet_gate", 0.0)))
	_water_mat.set_shader_parameter("facet_aniso",
		float(theme_flag("water_facet_aniso", 1.0)))
	_water_mat.set_shader_parameter("facet_aa",
		float(theme_flag("water_facet_aa", 0.5)))
	_water_mat.set_shader_parameter("glint_aa",
		float(theme_flag("water_glint_aa", 0.0)))
	_water_mat.set_shader_parameter("facet_b_gain",
		float(theme_flag("water_facet_b_gain", 1.0)))
	_water_mat.set_shader_parameter("facet_calm",
		float(theme_flag("water_facet_calm", 1.0)))
	_water_mat.set_shader_parameter("facet_lid",
		float(theme_flag("water_facet_lid", 1.0)))
	_water_mat.set_shader_parameter("glint_graze_cap",
		float(theme_flag("water_glint_graze_cap", 1.0)))
	# Gradientul de perspectiva: cat de mult se deschide apa cand privirea cade
	# mai de sus pe ea. Implicit 1.0/1.0 = plat, ca pana acum.
	_water_mat.set_shader_parameter("view_lo",
		float(theme_flag("water_view_lo", 1.0)))
	_water_mat.set_shader_parameter("view_hi",
		float(theme_flag("water_view_hi", 1.0)))
	_water_mat.set_shader_parameter("view_ref",
		float(theme_flag("water_view_ref", 0.22)))
	_water_mat.set_shader_parameter("crest_shade",
		float(theme_flag("water_crest_shade", 0.12)))
	# LUCIUL RAZANT. Culoarea nu e un slot de paleta ci MEDIUL REFLECTAT: pe o
	# tema de noapte, ceata. Se ia de acolo tocmai ca sa nu se poata
	# desincroniza — daca cerul se schimba, si ce se oglindeste in apa se
	# schimba odata cu el.
	var fres := float(theme_flag("water_fresnel", 0.0))
	_water_mat.set_shader_parameter("fresnel_strength", fres)
	if fres > 0.0:
		var fc: Color = theme_flag("water_fresnel_color",
			theme_flag("fog", Color(0.5, 0.5, 0.5)))
		fc = fc.srgb_to_linear()
		# NU se normalizeaza: aici e RADIANTA a ceea ce se oglindeste, adica
		# exact culoarea cetii, in liniar. `water_fresnel` e cat de mult din ea
		# se vede la incidenta razanta (0..1), nu cat de tare straluceste.
		var fg := float(theme_flag("water_fresnel_gain", 1.0))
		_water_mat.set_shader_parameter("fresnel_col",
			Vector3(fc.r * fg, fc.g * fg, fc.b * fg))
	_water_mat.set_shader_parameter("fresnel_sharp",
		float(theme_flag("water_fresnel_sharp", 4.0)))
	# --- AL DOILEA RAU (v4). Vezi nota lunga din water.gdshader: apa se imparte
	# dupa LOC, nu dupa adancime, fiindca doua familii de culoare amestecate pe
	# axa adancimii dau oliv — culoarea unei mirisiti, nu a unui rau.
	# Implicit sloturile lui = ale primului rau, deci o tema care nu cere
	# despartirea (`water_split` 0) se randeaza exact ca inainte.
	# `water_b_gain` = cata lumina primeste raul B fata de A (Yangtze-ul e apa
	# mai noroioasa decat Jialing-ul), `water_b_mul` = tenta lui. Implicit
	# amandoua = ale raului A, deci o tema cu un singur rau nu se misca.
	var b_k := float(theme_flag("water_b_gain", 1.0))
	var b_shallow := water_tint(theme_flag("water_b_shallow_slot",
		theme_flag("water_shallow_slot", Palette.REEF_SHALLOW)),
		dim * b_k, "water_b_mul", "water_b_desat")
	var b_deep := water_tint(theme_flag("water_b_deep_slot",
		theme_flag("water_deep_slot", Palette.SEA_DEEP)),
		dim * b_k * deep_k, "water_b_mul", "water_b_desat")
	var b_shore := water_tint(theme_flag("water_b_shore_slot",
		theme_flag("water_shore_slot", Palette.CORAL_SAND)),
		dim * b_k * shore_k, "water_b_mul", "water_b_desat").darkened(0.12)
	_water_mat.set_shader_parameter("shore_col_b",
		Vector3(b_shore.r, b_shore.g, b_shore.b))
	_water_mat.set_shader_parameter("shallow_col_b",
		Vector3(b_shallow.r, b_shallow.g, b_shallow.b))
	_water_mat.set_shader_parameter("deep_col_b",
		Vector3(b_deep.r, b_deep.g, b_deep.b))
	_water_mat.set_shader_parameter("split_strength",
		float(theme_flag("water_split", 0.0)))
	var split_dir: Vector2 = theme_flag("water_split_dir", Vector2(1.0, 0.0))
	_water_mat.set_shader_parameter("split_dir", split_dir.normalized())
	_water_mat.set_shader_parameter("split_offset",
		float(theme_flag("water_split_offset", 0.0)))
	_water_mat.set_shader_parameter("split_soft",
		float(theme_flag("water_split_soft", 24.0)))
	_water_mat.set_shader_parameter("split_meander",
		float(theme_flag("water_split_meander", 40.0)))
	_water_mat.set_shader_parameter("split_wave",
		float(theme_flag("water_split_wave", 260.0)))
	_water_mat.set_shader_parameter("seam_strength",
		float(theme_flag("water_seam", 0.0)))
	# Lumina care sclipeste si forma sclipirii. Pe temele vechi raman 0 =
	# soarele si pete izotrope, adica v3 neatins.
	_water_mat.set_shader_parameter("glint_horizon",
		float(theme_flag("water_glint_horizon", 0.0)))
	_water_mat.set_shader_parameter("glint_streak",
		float(theme_flag("water_glint_streak", 0.0)))
	_water_mat.set_shader_parameter("glint_sharp",
		float(theme_flag("water_glint_sharp", 48.0)))
	_water_mat.set_shader_parameter("glint_graze",
		float(theme_flag("water_glint_graze", 1.0)))
	_water_mat.set_shader_parameter("glint_graze_ref",
		float(theme_flag("water_glint_graze_ref", 0.5)))
	_water_mat.set_shader_parameter("glint_cut",
		float(theme_flag("water_glint_cut", 0.0)))
	_water_mat.set_shader_parameter("glint_grain",
		float(theme_flag("water_glint_grain", 1.0)))
	# CAT de aprins e raul B fata de A. Vezi nota v6 din shader: in diorama
	# bratul auriu nu are alt albedo, are alt DRUM DE LUMINA — 2.0% din pixeli
	# peste 150 si varf 201, fata de 0.4% si 160 pe cel verde. La noi era exact
	# invers: brunul avea vopseaua cea mai deschisa si sclipirile cele mai
	# putine. 1.0 / 0.0 = o singura apa, ca pe temele vechi.
	_water_mat.set_shader_parameter("glint_b_gain",
		float(theme_flag("water_b_glint", 1.0)))
	_water_mat.set_shader_parameter("glint_b_cut",
		float(theme_flag("water_b_glint_cut", 0.0)))
	# Din ce se face FORMA unei reflexii: fisurile texturii (0, temele vechi)
	# sau fateta apei (1). Vezi nota din shader — pe apa de la 20-40 m fisurile
	# de roca ies zigzaguri late de zeci de pixeli, adica flacari.
	_water_mat.set_shader_parameter("glint_facet",
		float(theme_flag("water_glint_facet", 0.0)))
	_water_mat.set_shader_parameter("glint_b_facet",
		float(theme_flag("water_b_glint_facet", 0.0)))
	_water_mat.set_shader_parameter("glint_facet_far",
		float(theme_flag("water_glint_facet_far", 130.0)))
	# Marginea si interiorul unei reflexii. Masurat: petele dioramei stau la
	# 1.8-2.8x fata de apa de sub ele, ale noastre la 6-7.4x, cu contur taiat cu
	# cutitul si interior de o singura culoare — de aia se citeau frunze lipite
	# pe suprafata, nu lumina in unda. Implicit: taietura de pana acum.
	_water_mat.set_shader_parameter("glint_soft",
		float(theme_flag("water_glint_soft", 0.17)))
	_water_mat.set_shader_parameter("glint_body",
		float(theme_flag("water_glint_body", 0.0)))
	# Cat de MOTLATA e suprafata sub reflexii. Implicitul shaderului (0.35) e
	# calibrat pe o laguna vazuta de aproape; pe un rau vazut de la 60 m in sus
	# aceeasi valoare iese pasla — captura rundei 5 avea apa cu granulatie de
	# muschi, adica jumatate din motivul pentru care citea camp. In diorama
	# suprafata e NETEDA, cu fatete mari; detaliul il dau reflexiile.
	_water_mat.set_shader_parameter("ripple_strength",
		float(theme_flag("water_ripple", 0.35)))
	# Culoarea sclipirii se ADUNA in LINIAR, deci trece prin srgb_to_linear ca
	# orice culoare a apei, dar NORMALIZATA la 1 pe canalul cel mai mare:
	# intensitatea o da `glint_strength`, aici e doar nuanta. Fara normalizare,
	# un slot inchis ar fi stins scanteierea in loc s-o coloreze.
	var glint_slot: int = int(theme_flag("water_glint_slot", Palette.FOAM_WHITE))
	var gc := Palette.color(glint_slot).srgb_to_linear()
	var gmax := maxf(gc.r, maxf(gc.g, gc.b))
	if gmax > 0.0:
		gc = Color(gc.r / gmax, gc.g / gmax, gc.b / gmax)
	# Spre alb cu `water_glint_white`: felinarele de sodiu sunt aurii, dar un
	# reflex pur saturat pe apa neagra iese lampa de neon, nu lumina pe unda.
	gc = Color.WHITE.lerp(gc, clampf(
		float(theme_flag("water_glint_tint", 1.0)), 0.0, 1.0))
	_water_mat.set_shader_parameter("glint_col", Vector3(gc.r, gc.g, gc.b))
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
## Materialul benzii de gheata de pe sosea (`_ice_ranges`).
##
## Culoarea vine din tema (`ice_road_tint`, implicit un turcoaz palid) peste
## granulatia de asfalt — aceeasi textura de clasa, alt albedo si luciu: gheata
## batatorita de roti e mai lucioasa si mai deschisa decat placa de langa ea.
## Textura proprie de gheata (crapaturi, bule) e un pas urmator; aici e doar
## suprafata pe care se testeaza feelingul, si asta se vede din masina.
var _ice_road_mat: StandardMaterial3D

func _ice_road_material() -> StandardMaterial3D:
	if _ice_road_mat != null:
		return _ice_road_mat
	var tint: Variant = theme_flag("ice_road_tint", null)
	var c: Color = tint as Color if tint != null else Color(0.62, 0.84, 0.86)
	# ACEEASI textura de clasa ca placa (`ice`, triplanar in spatiul lumii,
	# aceeasi scara): crapaturile trec continuu de pe placa pe banda, deci
	# banda se citeste ca o fasie CURATATA din aceeasi gheata, nu ca alt
	# material lipit peste. Diferenta o face nuanta (mai deschisa) si luciul.
	# Luciu moderat (0.5/0.4): la 0.3/0.7 soarele jos punea o pata alba pe
	# banda la fiecare viraj catre el (snapshot la frac 0.37).
	_ice_road_mat = _ice_class_material(c, 0.5, 0.4)
	_ice_road_mat.cull_mode = BaseMaterial3D.CULL_BACK
	return _ice_road_mat


## Material pe textura de clasa `ice` (tools/paint_ice.py), proiectata
## triplanar in spatiul lumii la scara clasei, cu culoarea de vertex ca
## multiplicator (placa isi ia albul de mal / turcoazul de larg din
## `_ice_color`; banda e alba, deci ia doar tenta de aici).
func _ice_class_material(tint: Color, roughness: float,
		specular: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = load(Palette.CLASS_TEXTURES["ice"])
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	var sc: float = Palette.CLASS_TRIPLANAR_SCALE["ice"]
	mat.uv1_scale = Vector3(sc, sc, sc)
	mat.roughness = roughness
	mat.metallic_specular = specular
	return mat


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
	# Cele din cod INTAI, cele desenate dupa: ordinea rutelor e stabila pentru
	# sonde si mesaje, iar un nod adaugat in editor nu renumeroteaza benzile
	# declarate in cod.
	for spec in _branch_specs() + _node_branches():
		var branch := _make_branch(spec)
		if branch != null:
			routes.append(branch)
	# Ocolurile hazardelor, DUPA benzile declarate: ordinea rutelor ramane
	# stabila pentru sonde, iar un pasaj rotativ adaugat in scena nu
	# renumeroteaza scurtaturile de dinaintea lui.
	#
	# Vin de la nod, nu din `_node_branches()`, fiindca punctele lor nu sunt
	# desenate: se CALCULEAZA din geometria hazardului, care se muleaza la
	# randul ei pe ruta 0 — deci trebuie cerute dupa ce ruta 0 e in lista.
	# Vezi `RotatingSpanHazard.detour_route_spec`.
	for spec in _span_detours():
		var detour := _make_branch(spec)
		if detour != null:
			routes.append(detour)


## Ocolurile cerute de pasajele rotitoare, ca specificatii de banda.
func _span_detours() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var nodes: Array[Node] = []
	_collect_span_holes(self, nodes)
	for node in nodes:
		if not node.has_method("detour_route_spec"):
			continue
		var spec: Dictionary = node.call("detour_route_spec", self)
		if not spec.is_empty():
			out.append(spec)
	return out


## Toate punctele coapte ale benzilor SECUNDARE, intr-o singura lista.
##
## Le primeste [TrackSideSampler] ca sa stie ca si acolo e drum: terenul le
## urmareste cota, iar decorul le ocoleste.
func _branch_corridor_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(1, routes.size()):
		# O banda in aer (TrackBranch.elevated) nu e coridor: terenul n-o vede.
		if routes[i].elevated:
			continue
		out.append_array(routes[i].baked)
	return out


## Punctele coapte ale benzilor DE PE USCAT (drum de tara, pietris): pentru
## ele samplerul si sapa terenul pana la cota benzii, nu doar il ridica.
## Bancul de nisip ("sand") ramane pe lista de ridicare doar. Vezi
## TrackSideSampler._carve_branches.
func _branch_carve_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(1, routes.size()):
		if routes[i].surface != "sand" and not routes[i].elevated:
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
##
## Fiecare banda isi alege RETETA dupa `TrackRoute.surface` (vezi acolo):
## "sand" e panglica plata de pana acum, neschimbata cu un pixel; "dirt_road"
## si "gravel" trec prin `_build_branch_dirt`.
func _build_branch_surfaces() -> void:
	for bi in range(1, routes.size()):
		var r := routes[bi]
		var n := r.count()
		if n < 2:
			continue
		# Banda care isi aduce carosabilul (rampa de serviciu a pasajului
		# rotativ) nu primeste nici foaie, nici parapeti — le are deja de la
		# nodul care a construit-o. Vezi `TrackRoute.no_surface`.
		if r.no_surface:
			continue
		match r.surface:
			"dirt_road":
				_build_branch_dirt(r, true)
			"gravel":
				_build_branch_dirt(r, false)
			"deck":
				_build_branch_deck(r)
			_:
				_build_branch_sand(r)
		if r.elevated:
			_build_branch_rails(r)


## Cat de aproape de capetele unei benzi in aer NU se pune parapet.
##
## Capatul benzii `elevated` e lipit de MARGINEA soselei (vezi _branch_end),
## deci pe primii metri masina inca trece dintr-o suprafata in cealalta: un
## parapet acolo ar fi un zid pus fix in dreptul racordului. 5 m e o lungime de
## masina si jumatate — cat sa treaca, prea putin cat sa apuce sa alunece.
const BRANCH_RAIL_SKIP: float = 5.0

## Cat spatiu se lasa intre parapetul benzii si marginea soselei.
##
## Vezi `_branch_rail_clear`: sub atat, parapetul ar sta PE carosabil.
const BRANCH_RAIL_CLEAR: float = 1.5


## Parapetul unei benzi IN AER.
##
## De ce exista: banda telecabinei e o panglica de 8 m suspendata peste apa, si
## pana aici n-avea nimic pe margini. Masurat cu ProbeRace pe seed 2 (2 rulari
## din 3, si aceleasi coordonate raportate independent de doua sesiuni):
## Autobuzul intra pe ea, aluneca lateral la 7-50 m de la capat si cade in
## volumul de repunere al marii — apoi e repus, o ia iar pe scurtatura si cade
## iar, la fiecare ciclu, 15 repuneri intr-o cursa. Nu era nedeterminism Jolt:
## era o panglica ingusta fara buza, luata la 25 m/s de masina cea mai grea.
##
## Acelasi argument (si acelasi mesh) ca parapetul de tablier din _build_walls:
## "fara ea, bumping-ul pe tablierul cu apa pe ambele parti arunca masinile in
## golf". O banda in aer E un tablier.
##
## Nu se emite decat pentru benzile `elevated` — adica, azi, doar Chongqing.
func _build_branch_rails(r: TrackRoute) -> void:
	var n := r.count()
	if n < 3:
		return
	var total: float = r.dists[n - 1]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var emitted := false
	for side_sign: float in [-1.0, 1.0]:
		for i in n - 1:
			var j := i + 1
			# Capetele raman deschise: acolo se face racordul cu asfaltul.
			if r.dists[i] < BRANCH_RAIL_SKIP:
				continue
			if total - r.dists[j] < BRANCH_RAIL_SKIP:
				continue
			var b0 := r.baked[i] + r.side_at(i) * r.half_width * side_sign
			var b1 := r.baked[j] + r.side_at(j) * r.half_width * side_sign
			# ... si nici acolo unde parapetul ar cadea PE sosea.
			if not _branch_rail_clear(b0) or not _branch_rail_clear(b1):
				continue
			var t0 := b0 + Vector3.UP * WALL_HEIGHT
			var t1 := b1 + Vector3.UP * WALL_HEIGHT
			st.add_vertex(b0); st.add_vertex(t0); st.add_vertex(b1)
			st.add_vertex(t0); st.add_vertex(t1); st.add_vertex(b1)
			emitted = true
	if not emitted:
		return
	st.generate_normals()
	_add_mesh_with_collision(st.commit(), Palette.color(Palette.CONCRETE),
		null, 1.0, 0.5, BaseMaterial3D.CULL_DISABLED)


## Are voie sa stea un parapet de banda in punctul asta?
##
## Nu si daca punctul e pe carosabilul buclei principale. `BRANCH_RAIL_SKIP`
## masoara pe LUNGIMEA benzii si ajunge cat timp banda se desprinde in unghi
## drept: dupa cativa metri e deja in lateral, departe de asfalt. O banda care
## pleaca TANGENT (TrackBranch.entry_at) merge insa zeci de metri pe langa
## marginea soselei, iar parapetul ei dinspre drum ar fi un zid ridicat pe banda
## din dreapta a soselei. Masurat pe Chongqing inainte de verificarea asta:
## Politia lovea parapetul de 25 de ori intr-o cursa si pierdea 27% din tur in
## afara soselei — un singur pilot, mereu acelasi, mereu la fractia 0.42.
func _branch_rail_clear(p: Vector3) -> bool:
	var i := routes[0].closest_index_global(p)
	var lat := routes[0].lateral_distance(i, p)
	return lat > width_at_index(i) + BRANCH_RAIL_CLEAR


## Reteta "sand": banda plata, doi vertecsi transversal, culoarea + granulatia
## din tema. E codul original al bancului de nisip din Okinawa si NU se atinge:
## orice retus vizual se face intr-o reteta noua, ca pistele existente sa nu se
## miste.
func _build_branch_sand(r: TrackRoute) -> void:
	var n := r.count()
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
	# Materialul benzii vine din TEMA, nu din cod: pe insula e nisip
	# coraligen umed, pe munte e pamant batatorit de pasune. Implicit
	# raman valorile Okinawei, ca pistele existente sa nu se schimbe cu
	# un pixel — aceeasi regula ca la orice steag de tema adaugat tarziu.
	var tint: Color = _branch_dirt_color(r)
	_add_mesh_with_collision(st.commit(), tint,
		_tex(String(theme_flag("branch_texture",
			"res://assets/textures/surface_sand.png"))))


## Reteta "deck": banda ASFALTATA — un tablier de viaduct, nu o panglica.
##
## De ce exista, cand aveam deja "sand", "dirt_road" si "gravel": toate trei
## sunt suprafete NEPAVATE, si prin proiect n-au marcaje (un banc de nisip nu
## poarta linie de mijloc — vezi si _build_center_line, care iese pe
## `road_is_loose`). Pe Chongqing scurtatura nu e insa o poteca, e o rampa de
## beton peste golf, iar la volan, noaptea, "gravel" a iesit exact reprosul
## dezvoltatorului: o panglica de o singura culoare, "un drum prin care nu vezi
## nimic". Trecerea de la gri inchis la gri deschis n-a rezolvat nimic —
## VALOAREA se schimbase, CITIREA nu: variatia fina de fagas si marginile care
## se topesc in teren se sting complet la lumina de noapte si de la 10 m in
## spatele masinii.
##
## Un drum se citeste din trei lucruri, si toate trei sunt AICI, nu in nuanta:
##   1. SUPRAFATA e asfalt — aceleasi doua treceri de textura ca soseaua
##      principala (micro 3.5 m + macro 45 m) si aceeasi familie de culoare.
##      Materialul e cel din cache-ul soselei cand culorile coincid, deci
##      costul in materiale e ZERO pe soseaua care are deja asfalt.
##   2. MARCAJ DE AX: linie discontinua, acelasi pas si aceeasi latime ca pe
##      bucla principala (2.8 m linie / 6.5 m pas / 0.36 m latime), ca ochiul
##      s-o recunoasca drept acelasi obiect.
##   3. BORDURI: doua benzi albe continue pe umeri, plus buza de beton care
##      exista deja din parapet. Astea dau LATIMEA — pe un tablier fara ele nu
##      stii unde se termina banda pana nu cazi de pe ea.
##
## Coliziunea e planul benzii (marcajele stau la 4.5 cm deasupra, ca pe sosea,
## si sunt pur vizuale).
func _build_branch_deck(r: TrackRoute) -> void:
	var n := r.count()
	var hw := r.half_width
	var tile := 3.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var u_half := hw / tile
	for i in n - 1:
		var j := i + 1
		var l0 := r.baked[i] - r.side_at(i) * hw
		var r0 := r.baked[i] + r.side_at(i) * hw
		var l1 := r.baked[j] - r.side_at(j) * hw
		var r1 := r.baked[j] + r.side_at(j) * hw
		var v0 := r.dists[i] / tile
		var v1 := r.dists[j] / tile
		st.set_uv(Vector2(-u_half, v0)); st.set_uv2(Vector2(-u_half, v0) * 0.078)
		st.add_vertex(l0)
		st.set_uv(Vector2(u_half, v0)); st.set_uv2(Vector2(u_half, v0) * 0.078)
		st.add_vertex(r0)
		st.set_uv(Vector2(-u_half, v1)); st.set_uv2(Vector2(-u_half, v1) * 0.078)
		st.add_vertex(l1)
		st.set_uv(Vector2(u_half, v0)); st.set_uv2(Vector2(u_half, v0) * 0.078)
		st.add_vertex(r0)
		st.set_uv(Vector2(u_half, v1)); st.set_uv2(Vector2(u_half, v1) * 0.078)
		st.add_vertex(r1)
		st.set_uv(Vector2(-u_half, v1)); st.set_uv2(Vector2(-u_half, v1) * 0.078)
		st.add_vertex(l1)
	st.index()
	st.generate_normals()
	# Aceeasi impartire la media macro-ului ca pe sosea (_build_road): fara ea
	# a doua trecere ar intuneca banda cu ~10%.
	var base: Color = _branch_dirt_color(r)
	var deck_color := Color(
		base.r / ASPHALT_MACRO_MEAN,
		base.g / ASPHALT_MACRO_MEAN,
		base.b / ASPHALT_MACRO_MEAN)
	# CULL_DISABLED, nu CULL_BACK ca pe sosea: windingul benzii vine din ordinea
	# punctelor desenate in .tscn si nu e garantat in sus (masurat — cu
	# CULL_BACK tablierul dispare complet si raman doar marcajele plutind).
	_add_mesh_with_collision(st.commit(), deck_color,
		_tex("res://assets/textures/surface_asphalt.png"), 0.82, 0.3,
		BaseMaterial3D.CULL_DISABLED, null,
		_tex("res://assets/textures/surface_asphalt_macro.png"))
	_build_branch_markings(r)


## Latimea unei linii discontinue de ax pe banda (jumatate, in metri).
const BRANCH_DASH_HALF_W: float = 0.18
## Lungimea unei linii si pasul intre inceputurile a doua linii.
const BRANCH_DASH_LEN: float = 2.8
const BRANCH_DASH_STEP: float = 6.5
## Latimea benzii albe continue de pe umar.
const BRANCH_EDGE_W: float = 0.30
## Cat de departe de marginea benzii sta banda alba de umar.
const BRANCH_EDGE_INSET: float = 0.45
## Inaltimea marcajelor peste planul benzii — aceeasi ca pe sosea.
const BRANCH_MARK_LIFT: float = 0.045


## Marcajele benzii asfaltate: ax discontinuu + doua benzi albe pe umeri.
##
## Un singur mesh si o singura culoare (aceeasi vopsea ca `_build_center_line`),
## deci un singur material — si acela deja in cache daca pista are linie de ax.
func _build_branch_markings(r: TrackRoute) -> void:
	var n := r.count()
	if n < 3:
		return
	var total: float = r.dists[n - 1]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lift := Vector3.UP * BRANCH_MARK_LIFT
	var emitted := false
	# 1. AXUL, discontinuu. Se sare peste primii si ultimii metri: acolo banda
	# se racordeaza la asfaltul buclei, si o linie acolo s-ar bate cu marcajul
	# soselei.
	var d := 6.0
	var idx := 0
	while d < total - 8.0:
		while idx + 1 < n and r.dists[idx + 1] < d:
			idx += 1
		var i := mini(idx, n - 2)
		var dir := (r.baked[i + 1] - r.baked[i]).normalized()
		var side := r.side_at(i)
		var a := r.baked[i] + dir * (d - r.dists[i]) + lift
		var b := a + dir * BRANCH_DASH_LEN
		st.add_vertex(a - side * BRANCH_DASH_HALF_W)
		st.add_vertex(a + side * BRANCH_DASH_HALF_W)
		st.add_vertex(b - side * BRANCH_DASH_HALF_W)
		st.add_vertex(a + side * BRANCH_DASH_HALF_W)
		st.add_vertex(b + side * BRANCH_DASH_HALF_W)
		st.add_vertex(b - side * BRANCH_DASH_HALF_W)
		d += BRANCH_DASH_STEP
		emitted = true
	# 2. BENZILE DE UMAR, continue pe ambele parti. Ele dau latimea benzii —
	# fara ele, la 10 m in spate si noaptea, tablierul se termina in nimic.
	var inner := r.half_width - BRANCH_EDGE_INSET - BRANCH_EDGE_W
	var outer := r.half_width - BRANCH_EDGE_INSET
	if inner > BRANCH_DASH_HALF_W + 0.3:
		for side_sign: float in [-1.0, 1.0]:
			for i in n - 1:
				var j := i + 1
				if r.dists[i] < 4.0 or total - r.dists[j] < 4.0:
					continue
				var s0 := r.side_at(i) * side_sign
				var s1 := r.side_at(j) * side_sign
				var a0 := r.baked[i] + s0 * inner + lift
				var a1 := r.baked[i] + s0 * outer + lift
				var b0 := r.baked[j] + s1 * inner + lift
				var b1 := r.baked[j] + s1 * outer + lift
				st.add_vertex(a0); st.add_vertex(a1); st.add_vertex(b0)
				st.add_vertex(a1); st.add_vertex(b1); st.add_vertex(b0)
				emitted = true
	if not emitted:
		return
	st.generate_normals()
	_add_visual_mesh(st.commit(), Color(0.92, 0.9, 0.78))


## Culoarea pamantului unei benzi: a nodului daca a cerut una, altfel a temei,
## altfel nisipul coraligen al Okinawei (implicitul istoric).
func _branch_dirt_color(r: TrackRoute) -> Color:
	if r.tint.a > 0.0:
		return Color(r.tint.r, r.tint.g, r.tint.b, 1.0)
	var branch_tint: Variant = theme_flag("branch_tint", null)
	return branch_tint if branch_tint != null \
		else Palette.color(Palette.CORAL_SAND).darkened(0.22)


## Ecartamentul fagaselor (m intre axele celor doua urme) si jumatatea latimii
## unei urme. Masinile de jucarie au ~1.6-1.9 m intre roti; ecartamentul e al
## drumului, nu al masinii — pe un drum umblat toate rotile cad in aceleasi
## urme, si de aceea exista fagase.
const RUT_GAUGE: float = 1.7
const RUT_HALF_W: float = 0.32
## Cat de departe de marginea urmei se mai vede pamant curat inainte ca
## iarba sa inceapa sa castige spre margine.
const RUT_SHOULDER: float = 0.6
## Ridicarea vizuala a benzii peste planul de coliziune — acelasi rol ca
## ROAD_CROWN pe sosea: fizica ramane pe planul benzii, ochiul vede fagasele.
const BRANCH_LIFT: float = 0.02
## Cat coboara MARGINEA benzii sub planul ei, ca sa se ingroape in teren.
## Terenul sta la TrackSideSampler.BRANCH_DROP (0.25) sub banda; marginea
## coboara mai jos de atat, deci linia vizibila a drumului e unde suprafata
## benzii intra in pajiste — o linie pe care o deseneaza doua suprafete si
## zgomotul terenului, nu o muchie de mesh. Asta, plus `edge_noise`, e ce
## face marginea sa para calcata, nu trasa. Intra si in coliziune (o panta de
## ~20% pe ultimul metru si ceva), ca rotile de la margine sa stea pe ce vad.
const BRANCH_EDGE_SINK: float = 0.35
## Media texturii macro folosite pe banda (surface_sand_macro), la care se
## imparte culoarea ca a doua trecere sa n-o intunece. Vezi SAND_MACRO_MEAN.
const BRANCH_MACRO_MEAN: float = SAND_MACRO_MEAN


## Reteta "dirt_road" (cu fagase si iarba) / "gravel" (fara).
##
## De ce arata a drum de tara si nu a dreptunghi maro — cele patru lucruri pe
## care banda veche nu le avea:
##   1. SECTIUNE: 11 vertecsi transversal, nu 2. Doua fagase adancite cu
##      `rut_depth` la ecartament fix (RUT_GAUGE), brazda dintre ele, umeri,
##      margini. Adancitura se citeste din umbra chiar la 4 cm — normalele
##      generate o vand.
##   2. CULOARE PE VERTEX: urmele sunt pamant deschis, batatorit; brazda e
##      iarba (cat cere `grass_center`, in pete, nu uniform); marginile ajung
##      la CULOAREA TERENULUI, deci banda se dizolva in pajiste in loc sa se
##      termine cu o linie. Materialul e maximul pe canale dintre pamant si
##      iarba, iar vertecsii coboara din el (culorile de vertex doar
##      INTUNECA — vezi _road_shade).
##   3. MARGINI ZDRENTUITE: vertexul exterior iese/intra cu `edge_noise` metri,
##      dupa un zgomot in coordonate de LUME (nu de distanta parcursa, altfel
##      ies valuri regulate).
##   4. A DOUA TRECERE DE TEXTURA (macro, UV2), ca soseaua si terenul: fara ea
##      granulatia de 3.5 m se repeta identic pe 200 m si ochiul o prinde.
## Plus smocurile de iarba (TrackGrass) pe margini si pe brazda, care sunt
## singurul lucru „3D" din tot pachetul si cel care vinde restul.
##
## COLIZIUNEA e planul benzii (fara fagase — alea sunt vizuale, ca ROAD_CROWN),
## cu marginile ingropate (BRANCH_EDGE_SINK) si, doar daca `bumpiness` > 0, cu
## denivelarile — atunci suspensia le simte.
func _build_branch_dirt(r: TrackRoute, with_ruts: bool) -> void:
	var n := r.count()
	var hw := r.half_width
	var tile := 3.5
	# Culorile-tinta, in „unitati de material" (inainte de textura):
	#   dirt  = pamantul benzii (tema / nod), ce se vedea si pana acum
	#   dust  = urmele batatorite, putin mai deschise si mai calde (praf)
	#   grass = terenul de langa, ca marginile sa se topeasca in el
	var dirt := _branch_dirt_color(r)
	var dust := dirt.lightened(0.16)
	var grass_v: Variant = theme_flag("inland_tint", null)
	var grass: Color = grass_v if grass_v != null else theme_ground_tint
	# Materialul poarta maximul pe canale, IMPARTIT la media trecerii macro
	# (ca la sosea), iar fiecare vertex coboara la tinta lui.
	var mat_col := Color(
		maxf(dust.r / BRANCH_MACRO_MEAN, grass.r),
		maxf(dust.g / BRANCH_MACRO_MEAN, grass.g),
		maxf(dust.b / BRANCH_MACRO_MEAN, grass.b))
	var v_dirt := _color_ratio(Color(dirt.r / BRANCH_MACRO_MEAN,
		dirt.g / BRANCH_MACRO_MEAN, dirt.b / BRANCH_MACRO_MEAN), mat_col)
	var v_dust := _color_ratio(Color(dust.r / BRANCH_MACRO_MEAN,
		dust.g / BRANCH_MACRO_MEAN, dust.b / BRANCH_MACRO_MEAN), mat_col)
	var v_grass := _color_ratio(grass, mat_col)
	# Geometria fagaselor, stransa daca banda e prea ingusta pentru ecartament.
	var rc := RUT_GAUGE * 0.5
	var rw := RUT_HALF_W
	var sh := RUT_SHOULDER
	var need := rc + rw + sh + 0.4
	if hw < need:
		var k := hw / need
		rc *= k
		rw *= k
		sh *= k
	var depth := r.rut_depth if with_ruts else 0.0
	var grass_c := r.grass_center if with_ruts else 0.0
	# Offsetele laterale ale profilului (m), de la stanga la dreapta.
	var offs: Array[float] = [-hw, -(rc + rw + sh), -(rc + rw), -rc, -(rc - rw),
		0.0, rc - rw, rc, rc + rw, rc + rw + sh, hw]
	# Adancimea la fiecare pozitie de profil (0 = planul benzii): fagasele
	# doar vizual, marginile (ingropate in teren) si in coliziune.
	var dips: Array[float] = [-BRANCH_EDGE_SINK, 0.0, 0.0, -depth, 0.0, 0.0,
		0.0, -depth, 0.0, 0.0, -BRANCH_EDGE_SINK]
	var col_dips: Array[float] = [-BRANCH_EDGE_SINK, 0.0, 0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0, -BRANCH_EDGE_SINK]
	# Zgomotele, toate in coordonate de LUME (vezi punctul 3 din antet).
	var edge_noise := FastNoiseLite.new()
	edge_noise.seed = _world_seed() ^ 0xB0A7
	edge_noise.frequency = 0.18 # perioada ~5.5 m: dantelura, nu valuri
	var patch_noise := FastNoiseLite.new()
	patch_noise.seed = _world_seed() ^ 0x6A55
	patch_noise.frequency = 0.11 # pete de iarba de 4-9 m pe brazda
	patch_noise.fractal_octaves = 2
	var bump_noise := FastNoiseLite.new()
	bump_noise.seed = _world_seed() ^ 0xB0B0
	bump_noise.frequency = 0.45 # gropi/valuri de 1-3 m
	bump_noise.fractal_octaves = 2
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := SurfaceTool.new()
	col.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m := offs.size()
	# Inelul precedent, ca fiecare segment sa refoloseasca vertecsii de sus.
	var prev_ring: Array[Vector3] = []
	var prev_col_ring: Array[Vector3] = []
	var prev_cols: Array[Color] = []
	for i in n:
		var side := r.side_at(i)
		var c := r.baked[i]
		var ring: Array[Vector3] = []
		var col_ring: Array[Vector3] = []
		var cols: Array[Color] = []
		for k in m:
			var x := offs[k]
			# Doar vertexul exterior se zdrentuieste; restul profilului
			# ramane fix, ca fagasele sa nu serpuiasca.
			if k == 0 or k == m - 1:
				var e := edge_noise.get_noise_2d(c.x + x, c.z) * r.edge_noise
				x += e * signf(x)
			var p := c + side * x + Vector3.UP * (BRANCH_LIFT + dips[k])
			var pc := c + side * x + Vector3.UP * col_dips[k]
			if r.bumpiness > 0.0:
				var bump := bump_noise.get_noise_2d(p.x, p.z) * r.bumpiness
				p.y += bump
				pc.y += bump
			ring.append(p)
			col_ring.append(pc)
			cols.append(_branch_vertex_color(absf(offs[k]), rc, rw, sh,
				grass_c, patch_noise.get_noise_2d(p.x, p.z) * 0.5 + 0.5,
				v_dirt, v_dust, v_grass))
		if i > 0:
			var v0 := r.dists[i - 1] / tile
			var v1 := r.dists[i] / tile
			for k in m - 1:
				var a0 := prev_ring[k]
				var b0 := prev_ring[k + 1]
				var a1 := ring[k]
				var b1 := ring[k + 1]
				var ua := offs[k] / tile
				var ub := offs[k + 1] / tile
				# Ordinea a0, a1, b0: fata in sus (ca la sosea).
				_branch_vert(st, a0, prev_cols[k], Vector2(ua, v0))
				_branch_vert(st, a1, cols[k], Vector2(ua, v1))
				_branch_vert(st, b0, prev_cols[k + 1], Vector2(ub, v0))
				_branch_vert(st, b0, prev_cols[k + 1], Vector2(ub, v0))
				_branch_vert(st, a1, cols[k], Vector2(ua, v1))
				_branch_vert(st, b1, cols[k + 1], Vector2(ub, v1))
			# Coliziunea: acelasi profil, fara fagase (planul benzii, cu
			# marginile ingropate si, daca sunt cerute, cu denivelarile).
			for k in m - 1:
				col.add_vertex(prev_col_ring[k])
				col.add_vertex(col_ring[k])
				col.add_vertex(prev_col_ring[k + 1])
				col.add_vertex(prev_col_ring[k + 1])
				col.add_vertex(col_ring[k])
				col.add_vertex(col_ring[k + 1])
		prev_ring = ring
		prev_col_ring = col_ring
		prev_cols = cols
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	col.index()
	var col_mesh := col.commit()
	# Granulatia din tema (pietris pe munte), macro-ul de nisip: petele lui de
	# 45 m sunt exact tiparul de pamant spalat de ploaie. Roughness 1, specular
	# 0 — pamantul e mat, ca drumul de nisip din _build_road.
	_add_mesh_with_collision(mesh, mat_col,
		_tex(String(theme_flag("branch_texture",
			"res://assets/textures/surface_gravel.png"))),
		1.0, 0.0, BaseMaterial3D.CULL_DISABLED, col_mesh,
		_tex("res://assets/textures/surface_sand_macro.png"))
	if with_ruts and r.tufts:
		_build_branch_tufts(r, rc - rw, grass_c)


func _branch_vert(st: SurfaceTool, p: Vector3, c: Color, uv: Vector2) -> void:
	st.set_color(c)
	st.set_uv(uv)
	st.set_uv2(Vector2(p.x, p.z) * SURFACE_TILING_MACRO)
	st.add_vertex(p)


## Raportul pe canale intre o culoare-tinta si culoarea materialului — adica
## culoarea de vertex care, inmultita cu materialul, da tinta. Prin
## constructie <= 1 pe fiecare canal (materialul e maximul tintelor).
static func _color_ratio(target: Color, mat: Color) -> Color:
	return Color(target.r / maxf(mat.r, 0.001), target.g / maxf(mat.g, 0.001),
		target.b / maxf(mat.b, 0.001), 1.0)


## Culoarea de vertex la o pozitie de profil, dupa |x| (m de la axa).
##
## Zonele, dinspre axa spre margine: brazda (iarba in pete, cat cere
## `grass_c`), urma (praf batatorit, fundul putin umbrit), umarul (pamant
## curat care incepe sa prinda iarba), marginea (culoarea terenului, cu un pic
## de pamant razlet ca sa nu fie o linie).
func _branch_vertex_color(ax: float, rc: float, rw: float,
		sh: float, grass_c: float, patch: float, v_dirt: Color, v_dust: Color,
		v_grass: Color) -> Color:
	if ax < rc - rw + 0.001:
		# Brazda: iarba in pete, mai plina pe axa, stinsa spre urma.
		var g := grass_c * (0.45 + 0.55 * smoothstep(0.35, 0.75, patch))
		g *= 1.0 - 0.6 * (ax / maxf(rc - rw, 0.001))
		return v_dirt.lerp(v_grass, g)
	if ax < rc + rw + 0.001:
		# Urma: praf, cu fundul umbrit.
		var bottom := 1.0 - absf(ax - rc) / rw
		return v_dust.darkened(0.16 * bottom)
	if ax < rc + rw + sh + 0.001:
		# Umarul: pamant care se raspandeste dincolo de urma.
		return v_dirt.lerp(v_grass, 0.30 * (0.5 + 0.5 * patch))
	# Marginea: teren, cu pamant razlet unde zgomotul o cere.
	return v_grass.lerp(v_dirt, 0.15 * patch)


## Smocurile drumului de tara: pe MARGINI (in afara benzii, unde iarba densa a
## soselei nu ajunge — TrackGrass o taie la CORRIDOR_CLEAR de orice banda
## secundara, tocmai ca sa nu creasca prin ea) si RAR pe brazda dintre fagase.
##
## `center_hw` = jumatatea latimii brazdei; `grass_c` scaleaza desimea de pe
## brazda: la 0 nu creste nimic acolo, la 1 e o poteca prin fan.
func _build_branch_tufts(r: TrackRoute, center_hw: float,
		grass_c: float) -> void:
	var main := routes[0]
	var keep_out := func(p: Vector3) -> bool:
		# Nu pe soseaua principala si nici pe umerii ei — la racorduri banda
		# intra sub asfalt.
		var i := main.closest_index_global(p)
		return main.lateral_distance(i, p) < width_at_index(i) + 1.5
	var ground := func(x: float, z: float) -> float:
		return _sampler.ground_y(x, z)
	var tufts := TrackGrass.build_strip(r, _world_seed(), theme_ground_tint,
		grass_c * 1.6, center_hw, 4.5, -0.6, 3.0, keep_out, ground)
	tufts.name = "BranchGrass_%s" % r.label
	add_child(tufts)


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
	var n := baked.size()
	# Fiecare capat se rezolva pe cont propriu: o banda desenata poate declara
	# DOAR intrarea (Chongqing: desprinderea trebuie sa fie tangenta, vezi
	# TrackBranch.entry_at) si sa lase revenirea dedusa ca pana acum.
	var i_entry := -1
	var i_exit := -1
	if spec.has("entry"):
		i_entry = int(fposmod(float(spec["entry"]), 1.0) * float(n)) % n
	if spec.has("exit"):
		i_exit = int(fposmod(float(spec["exit"]), 1.0) * float(n)) % n
	if i_entry < 0 or i_exit < 0:
		# Scurtatura DESENATA: capetele se citesc de pe bucla principala, ca
		# punctele ei cele mai apropiate de primul si ultimul punct desenat.
		# Vezi antetul lui TrackBranch pentru de ce nu se deseneaza capetele.
		var lbl := String(spec.get("label", "?"))
		if i_entry < 0:
			i_entry = _closest_baked_index(mid[0])
		if i_exit < 0:
			i_exit = _closest_baked_index(mid[mid.size() - 1])
		if i_entry == i_exit:
			push_warning(("Track: scurtatura '%s' pleaca si revine in acelasi "
				+ "punct de pe bucla — se ignora") % lbl)
			return null
		# CAPETELE DESENATE TREBUIE SA FIE LANGA SOSEA, si asta e o conditie
		# reala, nu o pedanterie. "Cel mai apropiat punct de pe bucla" e o
		# intrebare bine pusa doar cat timp punctul chiar e langa bucla; pentru
		# unul aruncat in mijlocul hartii raspunsul e arbitrar si se schimba din
		# nimic la prima ajustare de traseu.
		#
		# Masurat pe scurtatura din COD a Alpilor, ale carei puncte sunt
		# waypoint-uri de mijloc, nu capete: primul sta la 33.8 m de sosea, si
		# de acolo cel mai apropiat punct de bucla iese la fractia 0.825, pe
		# cand fractia masurata de mana e 0.754. Nici una nu e gresita — e
		# intrebarea care e prost pusa la distanta aia.
		#
		# De aceea pragul e generos (BRANCH_END_NEAR_M): nu respinge, doar
		# avertizeaza, ca sa vezi in Output DE CE banda ta pleaca de unde pleaca.
		var checks := []
		if not spec.has("entry"):
			checks.append([mid[0], i_entry, "pleaca"])
		if not spec.has("exit"):
			checks.append([mid[mid.size() - 1], i_exit, "revine"])
		for pair in checks:
			var p: Vector3 = pair[0]
			var b: Vector3 = baked[int(pair[1])]
			var d := Vector2(p.x - b.x, p.z - b.z).length()
			if d > BRANCH_END_NEAR_M:
				push_warning(("Track: scurtatura '%s' %s de la %.0f m de sosea "
					+ "(prag %.0f) — deseneaza capatul LANGA drum, altfel "
					+ "punctul de racord e ales arbitrar")
					% [lbl, String(pair[2]), d, BRANCH_END_NEAR_M])
	var elevated := bool(spec.get("elevated", false))
	# [b]`own_ends`: banda isi pune singura capetele.[/b] `_branch_end` alege
	# capatul unei benzi `elevated` pe MARGINEA soselei, pe partea din care vine
	# banda — ce trebuie pentru o pasarela care se lipeste de bordura. Ocolul
	# pasajului rotativ pleaca insa de pe AXA, in unghi mic, si masurat cu
	# capatul mutat pe margine iesea o cotitura: banda facea 7 m in lateral, se
	# intorcea, si ultimele patru puncte mergeau INAPOI, in aer, pe langa drum
	# (masurat: coada de la z 199.6 la 204.5 in sens invers). Pe ea, pilotul
	# intorcea volanul si ProbeRace numara 28 de repuneri, cu 20 s de mers in
	# marsarier pe masina.
	var pts: Array[Vector3] = []
	if bool(spec.get("own_ends", false)):
		pts.assign(mid)
	else:
		pts.append(_branch_end(i_entry, mid[0], elevated))
		pts.append_array(mid)
		pts.append(_branch_end(i_exit, mid[mid.size() - 1], elevated))
	var route := TrackRoute.from_points(pts, false, curve.bake_interval)
	route.half_width = float(spec.get("half_width", half_width))
	route.entry_frac = frac_at(i_entry)
	route.exit_frac = frac_at(i_exit)
	route.wet = bool(spec.get("wet", false))
	route.label = String(spec.get("label", "scurtatura"))
	# Suprafata: ce zice spec-ul, altfel ce zice tema, altfel nisipul de pana
	# acum — deci o pista care n-a auzit de retete ramane cum era.
	route.surface = String(spec.get("surface",
		theme_flag("branch_surface", "sand")))
	route.rut_depth = float(spec.get("rut_depth", route.rut_depth))
	route.grass_center = float(spec.get("grass_center", route.grass_center))
	route.edge_noise = float(spec.get("edge_noise", route.edge_noise))
	route.bumpiness = float(spec.get("bumpiness", route.bumpiness))
	route.speed_factor = clampf(float(spec.get("speed_factor", 1.0)), 0.3, 1.0)
	route.tufts = bool(spec.get("tufts", true))
	route.elevated = elevated
	route.no_surface = bool(spec.get("no_surface", false))
	route.detour = bool(spec.get("detour", false))
	route.own_ends = bool(spec.get("own_ends", false))
	if spec.has("tint"):
		route.tint = spec["tint"] as Color
	return route

## Capatul unei benzi pe bucla principala: AXA soselei, sau — pentru o banda
## `elevated` — MARGINEA ei, pe partea din care vine banda.
##
## O banda de la sol se termina in axa si nu deranjeaza: e o panglica plata,
## la cota terenului, iar peste asfalt sta sub el. O banda in aer (platforma
## telecabinei) isi tine insa cota proprie, deci bucata dintre margine si axa
## iese PESTE asfalt: un prag de 0.3-0.5 m pe carosabil, adica un zid pentru
## roata (masurat pe Chongqing: 4 repuneri intr-o cursa, toate la intrare) si
## un triunghi de banda vizibil peste tablier la sosire. Racordata la
## margine, banda nu mai calca deloc pe asfalt.
func _branch_end(i: int, toward: Vector3, elevated: bool) -> Vector3:
	var b := baked[i]
	if not elevated:
		return b
	var side := _side_at(i)
	var sgn := signf(Vector2(side.x, side.z).dot(
		Vector2(toward.x - b.x, toward.z - b.z)))
	if sgn == 0.0:
		return b
	return b + side * (sgn * width_at_index(i))

## Cat de departe de sosea poate sta un capat DESENAT de scurtatura inainte sa
## primeasca avertisment.
##
## 25 m e cam trei latimi de drum: destul cat sa desenezi relaxat primul punct
## putin pe langa asfalt, prea putin cat sa ajungi langa ALT sector al buclei.
## Nu e un prag de respingere — o scurtatura peste el se construieste oricum,
## doar ca stii de ce s-a agatat unde s-a agatat.
const BRANCH_END_NEAR_M: float = 25.0

## Indexul de pe bucla principala cel mai apropiat de un punct, in plan (XZ).
##
## Distanta e 2D deliberat: o scurtatura de munte pleaca de pe un drum care urca,
## iar capatul desenat sta aproape sigur la alta cota decat asfaltul. Cu distanta
## 3D, o diferenta de cota de cativa metri ar fi mutat punctul de desprindere cu
## zeci de metri de-a lungul soselei — capatul s-ar fi lipit de bucata de drum
## care se INTAMPLA sa fie la aceeasi inaltime, nu de cea de deasupra lui.
func _closest_baked_index(p: Vector3) -> int:
	var best := 0
	var best_d := INF
	for i in baked.size():
		var d := Vector2(p.x - baked[i].x, p.z - baked[i].z).length_squared()
		if d < best_d:
			best_d = d
			best = i
	return best


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


## Gaurile din carosabil cerute de pasajele rotitoare, ca perechi
## (primul index scos, cate indici) pe curba coapta.
##
## [b]De ce exista, si de ce nu se putea altfel.[/b] `RotatingSpanHazard` isi
## construieste singur tot ce are nevoie — tablier, ocol, poarta — dar
## contractul lui din brief (§2 randul F: „inchis -> te trimite pe rampa de
## serviciu") cere ca sub tronsonul rotitor sa fie GOL. Nodul nu poate scoate
## asfaltul pistei: el se aseaza PESTE el. Cat timp soseaua a trecut mai
## departe pe dedesubt, hazardul a fost pe jumatate — deschis mergea, inchis
## era doar o incetinire, fiindca masina cobora un lat de palma pe carosabilul
## pistei si continua drept.
##
## Masurat pe pista reala, in stare inchisa fortata: masina se strecura prin
## linia de bariere cu 3.2-4.5 m/s, se abatea cu 5.4 m de la axa (ocolul e la
## 24) si revenea — +1.7/+2.6/+2.8 s, adica pretul frecarii, nu al unui ocol.
## Sonda `ProbeRotatingSpan` nu putea sa vada asta: ea ruleaza pe o sosea-test
## peste care modulul e RIDICAT (`deck_rise`), deci acolo golul e gol prin
## constructie.
##
## Gaura o declara nodul insusi (`RotatingSpanHazard.road_hole_span()`) si se
## rezolva ca la canale — pe INDICI, nu pe metri, ca sa cada pe aceleasi puncte
## coapte pe care se aseaza si buzele tablierului.
var _span_holes: Array[Vector2i] = []

## Cati indici de o parte si de alta a fiecarei gauri raman FARA peretele
## pistei, ca sa se poata intra pe rampa de serviciu a pasajului.
##
## [b]Aceeasi problema ca la gura unei scurtaturi, si aceeasi reparatie.[/b]
## Peretele soselei trece drept peste locul in care rampa de serviciu se
## desprinde din banda; masurat pe Track12, masinile care incercau devierea se
## opreau la 5.7-6.0 m lateral cu peretele pistei in fata lor (ProbeRace:
## `atinge: @StaticBody3D@617`), adica exact ce s-a intamplat prima data si la
## bifurcatii — vezi `JUNCTION_CLEARANCE_M`, o cifra despre care comentariul ei
## spune ca „a costat o cursa intreaga".
##
## Nu e o degajare aleasa: e lungimea DEVIERII, ceruta de nodul insusi prin
## `RotatingSpanHazard.wall_clear_span()`.
var _span_wall_free: Array[Vector2i] = []


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
## Traduce pasajele rotitoare din scena in gauri de carosabil.
##
## Indexul se cauta in 3D (`distance_squared_to`), nu in plan: nodul
## Huangjuewan e o SPIRALA care trece de patru ori peste aceeasi amprenta xz,
## iar `_closest_baked_index` — care compara doar x si z — ar putea sa taie
## gaura pe alt etaj (memoria `pista-peste-pista`). Cota separa etajele.
func _resolve_span_holes() -> void:
	_span_holes.clear()
	_span_wall_free.clear()
	var n := baked.size()
	if n < 8:
		return
	var nodes: Array[Node] = []
	_collect_span_holes(self, nodes)
	for node in nodes:
		var want: float = float(node.call("road_hole_span"))
		if want <= 0.1:
			continue
		var p := to_local(node.global_position)
		var ci := 0
		var best := INF
		for i in n:
			var d := p.distance_squared_to(baked[i])
			if d < best:
				best = d
				ci = i
		# Cati pasi de o parte si de alta acopera lungimea ceruta. Se cauta, ca
		# la canale: `bake_interval` e un MAXIM, iar punctele coapte se indesesc
		# in viraje — o impartire ar da alta lungime decat cea reala.
		var steps := 1
		var err := INF
		for k in range(1, 16):
			var a := baked[((ci - k) % n + n) % n]
			var b := baked[(ci + k) % n]
			var e := absf(a.distance_to(b) - want)
			if e < err:
				err = e
				steps = k
		_span_holes.append(Vector2i(((ci - steps) % n + n) % n, 2 * steps))
		# Degajarea de perete, pe aceeasi metoda: cati pasi acopera lungimea
		# devierii de o parte si de alta.
		var free: float = float(node.call("wall_clear_span"))
		if free <= 0.1:
			continue
		var fsteps := 1
		var ferr := INF
		for k in range(1, 80):
			var a := baked[((ci - k) % n + n) % n]
			var b := baked[(ci + k) % n]
			var e := absf(a.distance_to(b) - free)
			if e < ferr:
				ferr = e
				fsteps = k
		_span_wall_free.append(Vector2i(((ci - fsteps) % n + n) % n, 2 * fsteps))


func _collect_span_holes(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		if child.has_method("road_hole_span"):
			out.append(child)
		_collect_span_holes(child, out)


func _resolve_channels() -> void:
	_channels.clear()
	var n := baked.size()
	if n < 8:
		return
	for spec in _channel_specs() + _node_channels():
		# Doua feluri de a spune UNDE taie canalul, si doar unul se scrie de
		# mana. Un nod [TrackChannel] pune in dictionar `at` (pozitia lui in
		# coordonatele pistei) si NU pune `frac`: indicele se cauta pe curba
		# coapta, deci tragi nodul in viewport si taietura il urmeaza. O pista
		# scrisa in cod declara mai departe `frac`, ca pana acum.
		var ci: int
		if spec.has("at"):
			# Acelasi cautator ca la capetele scurtaturilor desenate, si din
			# acelasi motiv: distanta e in plan (XZ). Un canal asezat langa un
			# drum care urca sta oricum la alta cota decat asfaltul, iar cu
			# distanta 3D taietura ar fugi zeci de metri, pe bucata de sosea
			# care se INTAMPLA sa fie la aceeasi inaltime.
			ci = _closest_baked_index(spec["at"] as Vector3)
		else:
			var frac := fposmod(float(spec.get("frac", 0.0)), 1.0)
			ci = int(frac * float(n)) % n
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
## Segmentul i (si j) e pe o portiune de GHEATA (vezi `_ice_ranges`).
## Folosit de generatorii de „mobilier" de sosea ca sa nu puna linie de mijloc,
## borduri, umeri, urme sau semne pe banda de gheata.
func _road_ice(i: int, j: int = -1) -> bool:
	if _ice_ranges().is_empty():
		return false
	if is_ice_at(frac_at(i)):
		return true
	return j >= 0 and is_ice_at(frac_at(j))


func _road_gap(i: int, j: int = -1) -> bool:
	var n := baked.size()
	for h in _span_holes:
		if ((i - h.x) % n + n) % n < h.y:
			return true
		if j >= 0 and ((j - h.x) % n + n) % n < h.y:
			return true
	if _channels.is_empty():
		return false
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
## 7 pozitii = 6 fasii: coroana prinde lumina continuu, iar gradientul de
## uzura are un inel intermediar (0.85) pe care sa se aseze — cu 5 pozitii
## trecerea mid->edge se intampla intr-o singura fasie si iese o dunga, nu
## un degrade. Costul: un inel de vertecsi in plus pe toata bucla, masurat
## sub 1% din pista.
const ROAD_PROFILE: Array[float] = [-1.0, -0.85, -0.5, 0.0, 0.5, 0.85, 1.0]

## Culoarea asfaltului, INAINTE de compensarea trecerii macro. Racoroasa-inchisa
## ca masinile saturate sa "sara" din ecran (style_bible §1: asfaltul e cea mai
## inchisa suprafata continua).
const ROAD_COLOR: Color = Color(0.23, 0.24, 0.3)
## Media texturii macro de asfalt (process_class_textures.surfaces()). Culoarea
## se imparte la ea, ca a doua inmultire sa nu intunece soseaua.
const ASPHALT_MACRO_MEAN: float = 0.900

## Cat de aproape de zapada ajunge peticul CEL MAI ALB de pe sosea (0 = asfalt
## curat, 1 = zapada plina). E plafonul pe care il poate atinge culoarea de
## VERTEX, si de aceea exista ca prag explicit: culorile de vertex se taie la
## 1.0, deci albul trebuie sa fie deja in materialul soselei, iar restul pistei
## sa coboare de acolo inapoi la asfalt. Vezi _road_snow_weight.
const ROAD_SNOW_CEIL: float = 0.42

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
##   godot --path . res://tools/Snapshot.tscn -- --track=1 --frac=0.21 --gamecam
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

## Culoarea drumului afanat, cu voie de suprascriere din TEMA.
##
## `DIRT_ROAD_COLOR` e nisipul auriu al desertului, potrivit pe Dunele si
## Okinawa. Pe Stromboli plaja si drumul sunt NISIP NEGRU vulcanic: cu galbenul
## implicit, captura de sus arata o insula vulcanica traversata de o panglica
## de plaja tropicala.
##
## Se rezolva cu o cheie de tema, nu cu o constanta noua si un `if` per pista:
## la fel ca `ice_road_tint` pe Baikal. Temele care n-o declara raman exact pe
## valoarea veche.
func dirt_road_color() -> Color:
	var tint: Variant = theme_flag("dirt_road_tint", null)
	return tint as Color if tint != null else DIRT_ROAD_COLOR
## Media texturii macro de nisip (process_class_textures.surfaces()).
const SAND_MACRO_MEAN: float = 0.850

## Cat de mult se intuneca asfaltul UD, ca factor pe vertex color (#246).
##
## 0.62 e ales cat sa se vada DE LA DISTANTA DE FRANARE, nu doar de aproape:
## portiunea trebuie citita din mers, ca sa poti ridica piciorul inainte de ea.
## Mai jos de atat, drumul incepe sa arate ars, nu ud.
const WET_DARKEN: float = 0.62
## Pe cate fractii de tur se sting marginile petei ude.
##
## ~1.5% dintr-un tur — la o pista de 1.5 km inseamna ~20 m de tranzitie, adica
## o jumatate de secunda de mers. Destul cat marginea sa nu fie o dunga trasa cu
## rigla, prea putin cat sa nu inmoaie semnalul.
const WET_FADE: float = 0.015

## Nuanta MARGINILOR pe un drum nepavat.
##
## Prima versiune intorsese gradientul fata de asfalt (mijloc batatorit =
## inchis, margini prafuite = deschise), pe un rationament de material corect
## si o citire gresita a referintei. In imaginea de referinta a drumului de
## coasta e exact invers: banda calcata de roti e PALIDA — praful fin s-a dus,
## a ramas nisipul tare si uscat — iar spre margini drumul se INCHIDE si se
## SATUREAZA (praf nebatut, umezeala de la iarba). Multiplicatorul de aici
## lasa deci mijlocul alb si trage marginile spre ocru: inchide albastrul mai
## mult decat rosul, ca marginea sa iasa calda, nu murdara.
const DIRT_EDGE_SHADE: Color = Color(0.87, 0.78, 0.66)

## Culoarea drumului de ZAPADA BATATORITA (road_surface == "snow"), inainte de
## compensarea trecerii macro. Sub albul zapezii proaspete din paleta
## (snow #E9F2F0) si trasa spre albastru: pe drumul pe care se circula zapada
## e tasata si sta in umbra cerului. Alaturi de ea, terenul alb al iernii
## ramane treapta LUMINOASA — deci si aici linia de curs se citeste din
## valoare, doar ca pe dos fata de asfalt: drumul e cu o idee mai INCHIS si
## mai rece decat campul.
const SNOW_ROAD_COLOR: Color = Color(0.87, 0.91, 0.95)
## Media texturii macro de zapada (process_class_textures.surfaces()).
const SNOW_MACRO_MEAN: float = 0.850

## Nuanta BENZII DE RULARE pe drumul de zapada, ca multiplicator de vertex.
##
## Pe zapada gradientul lateral e INVERSUL nisipului, si citirea de referinta
## e alta: pe un drum de iarna banda calcata e mai INCHISA si mai albastra
## (zapada presata, aproape gheata), iar spre margini sta zapada proaspata,
## alba. Cum culorile de vertex doar INTUNECA (SurfaceTool taie la [0,1]),
## albul marginilor trebuie sa fie chiar materialul, iar mijlocul coboara de
## acolo: multiplicatorul inchide rosul mai tare decat albastrul, ca banda sa
## iasa rece, nu murdara.
const SNOW_MID_SHADE: Color = Color(0.84, 0.88, 0.95)

## Foaia de uzura a drumului de zapada (doar pe road_surface == "snow").
## Traieste cat pista; masinile scriu in ea prin stamp_wear.
var _road_wear: RoadWear = null


## Materialul soselei de zapada: acelasi continut ca materialul standard
## (culoare compensata x micro x macro x vertex color, mat), plus masca de
## uzura din RoadWear. Tot aici se NASTE foaia de uzura — material si foaie
## sunt un singur mecanism, nu au sens separat, iar dimensiunile benzii
## (lungime, latime acoperita) trebuie sa fie ACELEASI in amandoua.
func _snow_road_material(road_color: Color, micro: String, macro: String,
		tile: float) -> ShaderMaterial:
	var n := baked.size()
	var total: float = _dists[n]
	var span := 0.0
	for i in n:
		span = maxf(span, width_at_index(i))
	# Toata latimea, ambele parti, plus un metru de marja pe fiecare: o roata
	# cu doua tale afara inca lasa urma pe buza drumului.
	span = span * 2.0 + 2.0
	_road_wear = RoadWear.new()
	_road_wear.name = "RoadWear"
	_road_wear.setup(total, span)
	add_child(_road_wear)
	# Fagasele "de-o iarna": drumul de sat nu incepe alb ca foaia.
	_road_wear.preseed()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/road_snow.gdshader") as Shader
	mat.set_shader_parameter("base_color", road_color)
	mat.set_shader_parameter("micro_tex", _tex(micro))
	mat.set_shader_parameter("macro_tex", _tex(macro))
	mat.set_shader_parameter("wear_tex", _road_wear.get_texture())
	mat.set_shader_parameter("lane_len", total)
	mat.set_shader_parameter("lane_span", span)
	mat.set_shader_parameter("road_tile", tile)
	return mat


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
	# Banda de GHEATA (vezi `_ice_ranges`): aceeasi geometrie, alt mesh si alt
	# material — nu e asfalt ud, e alta suprafata. Fusta ei intra tot aici, ca
	# marginea sa fie tot gheata, nu un tiv de pajiste sub un drum de gheata.
	var ice_top := SurfaceTool.new()
	ice_top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_ice := not _ice_ranges().is_empty()
	var down := Vector3.DOWN * ROAD_THICKNESS
	var n := baked.size()
	# UV-uri PATRATE: acelasi numar de metri pe ambele axe.
	#
	# Inainte U mergea 0..1 de-a latul soselei, adica o repetitie peste toata
	# latimea de 14 m, in timp ce V se repeta la 14 m — textura iesea intinsa
	# 14:1 lateral, deci granulatia aparea ca dungi longitudinale, nu ca pietris.
	var tile := 3.5
	var side_tile := 8.0
	# Nuanta per pozitie de profil: alb pe banda de rulare, gradat spre margini
	# — uzura/praful se aduna la margine, si gradientul face soseaua sa
	# citeasca a suprafata cu latime, nu a panglica uniforma.
	#
	# Pe nisip aceeasi directie, alta paleta (vezi DIRT_EDGE_SHADE): mijloc
	# palid batatorit, margini ocru. Nuanta nu se mai alege binar pe inelul
	# exterior, ci curge cu smoothstep pe |t| = 0.45..1.0 — inelul de la 0.85
	# primeste valoarea intermediara si trecerea iese degrade, nu dunga.
	var edge_shade := Color(0.84, 0.84, 0.86)
	var mid_shade := Color.WHITE
	if road_surface == "snow":
		# Gradient INVERSAT (vezi SNOW_MID_SHADE): alb la margini, banda de
		# rulare tasata si albastruie la mijloc.
		edge_shade = Color.WHITE
		mid_shade = SNOW_MID_SHADE
	elif road_is_loose():
		edge_shade = DIRT_EDGE_SHADE
	# Peticele de zapada de pe asfalt (vezi "road_snow_low" in themes()). Null pe
	# orice tema fara munte, deci restul pistelor nu se schimba cu un pixel.
	var snow_tint: Variant = theme_flag("road_snow_tint", null)
	var snow_low := float(theme_flag("road_snow_low", 0.0))
	var snow_high := maxf(float(theme_flag("road_snow_high", 1.0)),
		snow_low + 0.001)
	var snow_amount := float(theme_flag("road_snow_amount", 0.0))
	# Pe un drum DIN zapada, peticele de zapada de pe asfalt n-au obiect:
	# suprafata e deja alba toata, iar mecanismul lor (materialul ridicat spre
	# alb + vertecsii intorsi spre asfalt) ar dilua chiar culoarea drumului.
	if road_surface == "snow":
		snow_amount = 0.0
	# Zgomotul peticelor, in coordonate de LUME — din acelasi motiv ca UV2-ul de
	# mai jos: peticele trebuie sa stea pe loc pe teren, nu sa curga cu panglica.
	# Daca ar fi functie de distanta parcursa, ar iesi dungi transversale
	# perfect regulate, adica exact tiparul de „desen tehnic" pe care il repara.
	#
	# Frecventa 0.09 da pete de 4-8 m: la 3.5 m latime de banda, o pata are
	# marimea unei masini — destul cat s-o vezi venind si sa alegi daca o
	# ocolesti, dar nu atat cat sa acopere toata soseaua deodata.
	var snow_noise := FastNoiseLite.new()
	snow_noise.seed = _world_seed() ^ 0x5A0D
	snow_noise.frequency = 0.09
	snow_noise.fractal_octaves = 2
	# Pe o tema cu zapada, materialul e ridicat spre alb cu ROAD_SNOW_CEIL, iar
	# vertecsii FARA zapada se intorc la asfalt cu factorul asta. Raportul e sub
	# 1.0 prin constructie (numaratorul e asfaltul, numitorul e asfaltul ridicat
	# spre alb), deci nu-l taie clamp-ul de vertex color.
	#
	# Pe restul pistelor `road_dark` ramane alb, deci `_road_shade` intoarce
	# nuanta neatinsa — celelalte lumi nu se schimba cu un pixel.
	var road_dark := Color.WHITE
	if snow_tint != null and snow_amount > 0.0:
		var lifted := (dirt_road_color() if road_is_loose() else ROAD_COLOR) \
			.lerp(snow_tint as Color, ROAD_SNOW_CEIL)
		var plain := dirt_road_color() if road_is_loose() else ROAD_COLOR
		road_dark = Color(
			plain.r / maxf(lifted.r, 0.001),
			plain.g / maxf(lifted.g, 0.001),
			plain.b / maxf(lifted.b, 0.001))
	for i in n:
		var j := (i + 1) % n
		# Golul canalului: nici asfalt, nici coliziune, nici fusta laterala.
		# Aici se rupe pista in doua si incepe saritura.
		if _road_gap(i):
			continue
		var on_ice := has_ice and _road_ice(i, j)
		var dst := ice_top if on_ice else top
		var v0 := _dists[i] / tile
		var v1 := _dists[i + 1] / tile
		var s0v := _side_at(i)
		var s1v := _side_at(j)
		# Asfaltul UD e mai inchis la culoare (#246). E semnalul, nu decorul: o
		# portiune care iti taie grip-ul fara sa se vada ar fi necinstita — toate
		# celelalte hazarde se anunta (telegraf, lumini, bariere).
		#
		# Vertex color INTUNECA, nu lumineaza: valorile sunt taiate la [0,1],
		# deci se poate doar cobora din culoarea materialului. Aici asta e chiar
		# ce ne trebuie.
		var wet0 := _wet_shade(frac_at(i))
		var wet1 := _wet_shade(frac_at(j))
		# Latimea la CELE DOUA capete ale segmentului, nu una singura: asa
		# panglica se ingusteaza continuu cand va exista profilul, in loc sa
		# sara in trepte de cate un segment. Acum sunt egale.
		var hw0 := width_at_index(i)
		var hw1 := width_at_index(j)
		# Inelele profilului la capetele segmentului.
		var ring0: Array[Vector3] = []
		var ring1: Array[Vector3] = []
		for t in ROAD_PROFILE:
			var crown := Vector3.UP * (ROAD_CROWN * (1.0 - t * t))
			ring0.append(baked[i] + s0v * hw0 * t + crown)
			ring1.append(baked[j] + s1v * hw1 * t + crown)
		for k in ROAD_PROFILE.size() - 1:
			var ta: float = ROAD_PROFILE[k]
			var tb: float = ROAD_PROFILE[k + 1]
			var ca := mid_shade.lerp(edge_shade, smoothstep(0.45, 1.0, absf(ta)))
			var cb := mid_shade.lerp(edge_shade, smoothstep(0.45, 1.0, absf(tb)))
			# UV-ul urmareste latimea LOCALA, ca dala sa ramana patrata si acolo
			# unde drumul se ingusteaza — altfel textura s-ar intinde in strangere.
			var ua := ta * (hw0 / tile)
			var ub := tb * (hw0 / tile)
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
			# Zapada se aplica PER VERTEX, nu per pozitie de profil ca `ca`/`cb`:
			# tiparul e o functie de pozitie in lume, deci cele doua capete ale
			# aceluiasi segment (w0 si w1, la 3 m distanta) trebuie sa poata cadea
			# unul in petic si celalalt pe asfalt curat. Cu o culoare per profil,
			# peticele s-ar fi intins pe toata lungimea segmentului si ar fi iesit
			# tot dungi transversale.
			#
			# `road_shade` INTUNECA de la culoarea materialului (care e zapada, pe
			# temele cu zapada) inapoi spre asfalt — vezi _road_snow_weight pentru
			# de ce sensul e inversat.
			var c0 := _road_shade(ca, road_dark, _road_snow_weight(
				w0, snow_low, snow_high, snow_amount, snow_noise, ta)) * wet0
			var c1 := _road_shade(ca, road_dark, _road_snow_weight(
				w1, snow_low, snow_high, snow_amount, snow_noise, ta)) * wet1
			var c0b := _road_shade(cb, road_dark, _road_snow_weight(
				w0b, snow_low, snow_high, snow_amount, snow_noise, tb)) * wet0
			var c1b := _road_shade(cb, road_dark, _road_snow_weight(
				w1b, snow_low, snow_high, snow_amount, snow_noise, tb)) * wet1
			if on_ice:
				# Gheata n-are uzura de margine si nici petice: culoarea vine
				# toata din material (vezi `_ice_road_material`).
				c0 = Color.WHITE; c1 = Color.WHITE
				c0b = Color.WHITE; c1b = Color.WHITE
			# Ordinea l0,l1,r0: fata triunghiului iese IN SUS (vezi istoricul
			# winding-ului — cu ordinea inversa normalele ieseau in jos).
			dst.set_color(c0); dst.set_uv(Vector2(ua, v0)); dst.set_uv2(m0)
			dst.add_vertex(w0)
			dst.set_color(c1); dst.set_uv(Vector2(ua, v1)); dst.set_uv2(m1)
			dst.add_vertex(w1)
			dst.set_color(c0b); dst.set_uv(Vector2(ub, v0)); dst.set_uv2(m0b)
			dst.add_vertex(w0b)
			dst.set_color(c0b); dst.set_uv(Vector2(ub, v0)); dst.set_uv2(m0b)
			dst.add_vertex(w0b)
			dst.set_color(c1); dst.set_uv(Vector2(ua, v1)); dst.set_uv2(m1)
			dst.add_vertex(w1)
			dst.set_color(c1b); dst.set_uv(Vector2(ub, v1)); dst.set_uv2(m1b)
			dst.add_vertex(w1b)
		# Fasia plata de coliziune (geometria veche, 2 vertecsi transversal).
		var l0 := baked[i] - s0v * hw0
		var r0 := baked[i] + s0v * hw0
		var l1 := baked[j] - s1v * hw1
		var r1 := baked[j] + s1v * hw1
		col.add_vertex(l0); col.add_vertex(l1); col.add_vertex(r0)
		col.add_vertex(r0); col.add_vertex(l1); col.add_vertex(r1)
		var u0 := _dists[i] / side_tile
		var u1 := _dists[i + 1] / side_tile
		var skirt := deck_sides \
			if _bridge_mix(i) > 0.5 or _overpass_mix(i) > 0.5 else sides
		if on_ice:
			skirt = ice_top
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
	var base := ROAD_COLOR
	var macro_mean := ASPHALT_MACRO_MEAN
	if road_surface == "snow":
		base = SNOW_ROAD_COLOR
		macro_mean = SNOW_MACRO_MEAN
	elif road_is_loose():
		base = dirt_road_color()
		macro_mean = SAND_MACRO_MEAN
	# Pe temele cu zapada pe drum, materialul poarta o culoare INTRE asfalt si
	# zapada, iar vertecsii o duc in ambele sensuri: in jos spre asfalt (peste
	# tot), in sus... nicaieri, ca nu se poate. Vezi _road_snow_weight pentru de
	# ce culorile de vertex nu pot depasi 1.0.
	#
	# De ce nu direct culoarea zapezii, cum era intr-o versiune intermediara:
	# TEXTURA SE INMULTESTE PESTE ALBEDO. Cu albedo alb, granulatia de asfalt
	# (o textura gri, medie ~0.5) cadea peste alb si iesea gri deschis — adica
	# soseaua se albea pe TOATA pista, si in pasunea verde de la 33 m, unde
	# cifrele spuneau limpede ca zapada e 0%. Se vedea doar in A/B cu ramura de
	# baza: acelasi cadru, drum albastru-inchis inainte, gri palid dupa.
	#
	# `ROAD_SNOW_CEIL` e cat de alb poate ajunge peticul cel mai alb. Materialul
	# se ridica exact atat, iar restul soselei se intoarce la asfalt prin vertex
	# color. Peste ~0.45 reapare spalarea de mai sus; sub ~0.25 peticul nu se mai
	# vede ca zapada.
	if road_dark != Color.WHITE:
		base = base.lerp(snow_tint as Color, ROAD_SNOW_CEIL)
	var road_color := Color(
		base.r / macro_mean,
		base.g / macro_mean,
		base.b / macro_mean)
	var micro := "res://assets/textures/surface_asphalt.png"
	var macro := "res://assets/textures/surface_asphalt_macro.png"
	var rough := 0.82
	var spec := 0.3
	if road_surface == "snow":
		# Zapada tasata, in ACEEASI schema de doua treceri: micro = snow_01
		# (zapada calcata, urmele raman variatie de luminanta), macro =
		# snow_field_aerial (pete de zapada suflata de vant, la 45 m).
		# MATA, ca placa de gheata (_ice_sheet_material a invatat lectia):
		# cu soarele jos al Baikalului, orice luciu pe o suprafata aproape
		# alba pune o pata alba cat jumatate de ecran.
		micro = "res://assets/textures/surface_snow.png"
		macro = "res://assets/textures/surface_snow_macro.png"
		rough = 1.0
		spec = 0.0
	elif road_is_loose():
		micro = "res://assets/textures/surface_sand.png"
		macro = "res://assets/textures/surface_sand_macro.png"
		rough = 1.0
		spec = 0.0
	# Pe zapada, materialul standard e inlocuit cu shaderul care citeste masca
	# de uzura — ACELASI continut vizual si zero materiale in plus: il
	# inlocuieste pe cel pe care soseaua l-ar fi avut oricum.
	var road_override: Material = null
	if road_surface == "snow":
		road_override = _snow_road_material(road_color, micro, macro, tile)
	_add_mesh_with_collision(top.commit(), road_color,
		_tex(micro), rough, spec,
		BaseMaterial3D.CULL_BACK, col.commit(), _tex(macro), true,
		road_override)
	_add_mesh_with_collision(sides.commit(), theme_hill_color.darkened(0.2))
	if has_ice:
		ice_top.index()
		ice_top.generate_normals()
		var ice_mesh := ice_top.commit()
		if ice_mesh != null and ice_mesh.get_surface_count() > 0:
			var inst := MeshInstance3D.new()
			inst.name = "IceRoad"
			inst.mesh = ice_mesh
			inst.material_override = _ice_road_material()
			add_child(inst)
	if not _channels.is_empty():
		var deck_mesh := deck_sides.commit()
		if deck_mesh != null and deck_mesh.get_surface_count() > 0:
			_add_mesh_with_collision(deck_mesh, Palette.color(Palette.CONCRETE))


## Cat de alba e zapada de pe asfalt, ca greutate 0..1 pentru un vertex.
##
## Intoarce DOAR greutatea, nu culoarea, si asta e consecinta directa a bugului
## care a costat versiunea precedenta:
##
##   SURFACETOOL TAIE CULORILE DE VERTEX LA [0,1].
##
## Prima varianta a mers pe „culoarea de vertex se inmulteste cu albedo-ul, deci
## ca sa iasa alb peste asfaltul inchis (#3B3D4D) pun un factor de ~3.9x".
## Rationamentul e corect pe hartie si IMPOSIBIL de executat: `set_color(2.4)`
## ajunge 1.0 in mesh. Masurat pe pista construita — max.r = 1.000 pe toate cele
## 7490 de varfuri, 0.0% suprafata patata, adica efect ZERO — desi aceeasi
## functie, chemata direct, dadea 53.8% acoperire si factori pana la 2.4.
## Sonda de coacere spunea „e acolo", ecranul spunea „nu e nimic; vezi si nota
## din CLAUDE.md despre efecte care se numara in loc sa se vada.
##
## Solutia inverseaza sensul: ALBEDO-UL MATERIALULUI DEVINE ZAPADA, iar culoarea
## de vertex INTUNECA inapoi spre asfalt peste tot unde nu e zapada. Inmultirea
## merge acum in jos (0.24 / 0.91 = 0.26, cuminte sub 1.0), deci nu se taie
## nimic. E aceeasi mecanica pe care o foloseau deja bordurile — albedo alb,
## culoarea din vertex — doar ca aici motivul e o limita a formatului, nu gustul.
##
## Costul: ZERO materiale in plus si nicio trecere de transparenta. Varianta
## „naturala" (un al doilea mesh alb cu alfa peste sosea) ar fi adus si un
## material, si overdraw pe toata banda de rulare — exact constrangerea pe care
## CLAUDE.md o numeste cea reala pe mobil.
## Nuanta finala a unui vertex de sosea: gradientul de uzura, intunecat de la
## zapada inapoi la asfalt acolo unde nu e zapada (`w` = 0 -> asfalt curat,
## `w` = 1 -> zapada plina). Pe pistele fara zapada `dark` e alb si functia
## intoarce exact `shade`, deci nu schimba nimic.
func _road_shade(shade: Color, dark: Color, w: float) -> Color:
	if dark == Color.WHITE:
		return shade
	var mix := Color(
		lerpf(dark.r, 1.0, w),
		lerpf(dark.g, 1.0, w),
		lerpf(dark.b, 1.0, w))
	return Color(shade.r * mix.r, shade.g * mix.g, shade.b * mix.b)


func _road_snow_weight(v: Vector3, low: float, high: float, amount: float,
		noise: FastNoiseLite, t: float) -> float:
	# Densitatea creste cu altitudinea: curat in sat, patat pe culme.
	var alt := smoothstep(0.0, 1.0, clampf((v.y - low) / (high - low), 0.0, 1.0))
	if alt <= 0.0:
		return 0.0
	# PRAGUL SE MISCA CU ALTITUDINEA, INTENSITATEA CU POZITIA PE LATIME — si cele
	# doua NU se inmultesc intre ele. O versiune intermediara le combina intr-un
	# singur prag (`1 - amount * alt * edge_bias`), si atunci pe axul soselei
	# pragul ramanea la 0.81..1.00, unde zgomotul (masurat: 3.8% din valori trec
	# de 0.75) nu ajunge aproape niciodata.
	#
	# Asa, pragul depinde DOAR de cota: la varf coboara la 0.45, unde trece ~60%
	# din zgomot. Cat de alb iese peticul se decide dupa aceea.
	# TRECEREA E INGUSTA (0.07), si asta e a doua corectie facuta pe captura, nu
	# pe rationament. Cu o banda larga (0.18) aproape fiecare vertex primea o
	# greutate mica dar nenula, iar rezultatul nu era „asfalt cu petice de
	# zapada", ci o sosea uniform CENUSIE — beton ud pe toata culmea. Se vedea
	# imediat in captura, desi cifrele de acoperire aratau bine: exact capcana
	# „efectele nu se verifica numarand".
	#
	# Ingusta, marginea peticului e o margine: ai zapada SAU asfalt, cu doar
	# cativa metri de trecere. Aia e si diferenta dintre „petic" si „ceata".
	var noise_v := noise.get_noise_3d(v.x, v.y, v.z) * 0.5 + 0.5
	var thresh := lerpf(0.92, 0.52, alt)
	var w := smoothstep(thresh, thresh + 0.07, noise_v)
	if w <= 0.0:
		return 0.0
	# Banda de rulare ramane curata: rotile o matura, zapada rezista pe margini
	# si pe axul dintre urme. 0.12 la mijloc, 1.0 pe buza — pe ax peticul e doar
	# o umbra de alb, cat sa nu iasa doua dungi negre perfect paralele, dar
	# destul de putin cat linia de curs sa ramana citibila pe asfalt inchis
	# (style_bible §1). Cu 0.45, cat era inainte, mijlocul se albea si el si
	# soseaua isi pierdea rolul de suprafata cea mai inchisa din cadru.
	return w * lerpf(0.12, 1.0, smoothstep(0.15, 0.95, absf(t))) * amount

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
	# Gura devierii unui pasaj rotativ e o bifurcatie ca oricare alta: peretele
	# soselei nu are voie sa treaca peste ea. Vezi `_span_wall_free`.
	for w in _span_wall_free:
		if ((i - w.x) % n + n) % n < w.y:
			return true
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
	var walls_on := bool(theme_flag("walls", true))
	# Parapetul de TABLIER traieste separat de peretii pistei: pe Chongqing
	# ("walls": false — e oras, nu circuit cu mantinela) podul peste golf si
	# rampele suspendate tot au balustrada de beton, fiindca balustrada e
	# parte din citirea podului (si, masurat cu ProbeRace: fara ea, bumping-ul
	# pe tablierul cu apa pe ambele parti arunca masinile in golf).
	var deck_rails := bool(theme_flag("deck_rails", walls_on))
	if not walls_on and not deck_rails:
		return
	var loop_poly := PackedVector2Array()
	for p in _points():
		loop_poly.append(Vector2(p.x, p.z))
	var n := baked.size()
	var junctions := _junction_indices()
	var total_len: float = _dists[n] if _dists.size() > n else 0.0
	# Buza pe care se planteaza stalpii de RAIL_POSTS, adunata cat se cladeste
	# peretele: acolo se stie deja si latura, si ca segmentul chiar ar fi primit
	# perete (nu e in dreptul unei jonctiuni sau al unui gol de canal).
	var post_spots: Array[Vector3] = []
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
			if _road_gap(i) or _road_ice(i):
				continue # buza golului: dincolo de ea nu mai e pe ce sa stea
			var b0 := baked[i] + _side_at(i) * width_at_index(i) * side_sign
			var b1 := baked[j] + _side_at(j) * width_at_index(j) * side_sign
			var mid := (b0 + b1) * 0.5
			# Pe pasaj, parapet de beton pe AMBELE parti: e un tablier in aer,
			# si golul de sub el e un alt drum — cazi pe el, nu in apa.
			# Viaductul e tot un tablier (gol si sub asfalt), doar ca golul
			# lui e sapat in teren, nu un canal — parapetul i se cuvine la fel.
			var on_deck := _bridge_mix(i) > 0.5 or _overpass_mix(i) > 0.5 				or _viaduct_mix(i) > 0.5
			# Parapetul DECLARAT se citeste inaintea oricarei alte reguli.
			# Pana aici era citit dupa `if not walls_on: continue`, deci pe o
			# pista fara gard (Chongqing) stalpii declarati nu se emiteau
			# niciodata — iar exact acolo sunt singurul lucru care spune
			# soferului ca la marginea asfaltului incepe caderea: din scaunul
			# masinii buza cornisei e sub linia orizontului, deci nu se vede
			# nimic din rapa, doar apa lipita de asfalt (masurat, r4 si r6).
			# Un stalp de 0.95 m e peste linia aia. Nu aduce coliziune (vezi
			# _build_rail_posts) — nu inchide drumul, doar il marcheaza.
			var mode := -1
			if not on_deck:
				var frac := _dists[i] / total_len if total_len > 0.0 else 0.0
				mode = _rail_mode_at(frac, side_sign)
				if mode == RAIL_POSTS:
					post_spots.append(b0)
			if not walls_on and not on_deck:
				continue
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(mid.x, mid.z), loop_poly)
			var elevated := mid.y > 1.0
			if not exterior and not elevated and not on_deck:
				continue
			# Parapetul declarat al pistei bate regula implicita. Pe pod NU:
			# balustrada podului e parte din citirea podului (vezi mai sus).
			if not on_deck and mode != -1:
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
	_build_rail_posts(post_spots)


## Stalpii rari de pe portiunile RAIL_POSTS.
##
## FARA COLIZIUNE, deliberat: un stalp de 11 cm care opreste o masina de tona
## ar fi mai mincinos decat gardul pe care tocmai l-am scos, iar unul care o
## deviaza imprevizibil pe buza prapastiei ar fi frustrare, nu tensiune. Rolul
## lor e sa spuna „aici e marginea" cu o secunda inainte, atat.
##
## Un singur mesh pentru toti (nu un nod per stalp): pe traversare ies cateva
## zeci, iar fiecare cu materialul lui ar fi cateva zeci de draw call-uri
## pentru niste betisoare — exact clasa de risipa pe care o numara
## tools/probe_decor.gd.
func _build_rail_posts(spots: Array[Vector3]) -> void:
	if spots.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last := Vector3.INF
	var placed := 0
	for p in spots:
		if last != Vector3.INF and p.distance_to(last) < RAIL_POST_SPACING:
			continue
		last = p
		placed += 1
		# Prisma hexagonala: 12 triunghiuri pe stalp. Un CylinderMesh la
		# rezolutia implicita ar fi adus 64 de segmente pentru un obiect de
		# 11 cm — lectia primitivelor din CLAUDE.md.
		var base := p - Vector3.UP * 0.15 # infipt, nu asezat
		var top := base + Vector3.UP * RAIL_POST_HEIGHT
		for k in 6:
			var a0 := TAU * float(k) / 6.0
			var a1 := TAU * float(k + 1) / 6.0
			var o0 := Vector3(cos(a0), 0.0, sin(a0)) * RAIL_POST_RADIUS
			var o1 := Vector3(cos(a1), 0.0, sin(a1)) * RAIL_POST_RADIUS
			st.add_vertex(base + o0); st.add_vertex(top + o0)
			st.add_vertex(base + o1)
			st.add_vertex(top + o0); st.add_vertex(top + o1)
			st.add_vertex(base + o1)
	if placed == 0:
		return
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = _flat_material(
		Palette.color(Palette.WOOD_WEATHERED), null, 1.0, 0.35)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh)


## Rampa pe jumatatea exterioara a soselei: alegi intre linia sigura si
## saritura (airtime).
func _build_ramp(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var c := baked[idx]
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var side := _side_at(idx)
	var half_l := 7.0
	var hw := width_at(frac)
	var half_w := hw * 0.5
	var height := 2.6
	var center := c + side * hw * 0.5
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

## TOROS (Baikal): creasta de gheata impinsa de vant peste culoar — un
## kicker natural, mic. Prisma asimetrica pe TOATA latimea benzii (+1 m de
## fiecare parte): urcare lina pe HUMMOCK_RUN metri pana la HUMMOCK_RISE, apoi
## cadere scurta. La 30 m/s decolezi ~0.8 s; la 20 abia saltezi — deci
## rasplateste viteza fara sa opreasca pe nimeni. Textura de clasa `snow`
## (zapada suflata pe creasta), ca sa se citeasca de departe pe turcoaz.
## 0.75 pe 5.5 m (~8 grade), NU 0.9 pe 4.5 (~11): cu panta mai abrupta,
## masurat cu ProbeRace, autobuzul si pompierii (grele, inalte) faceau 2
## repuneri fiecare si 20% din timp in afara culoarului — decolau, aterizau
## strimb pe gheata si se invarteau. La 8 grade: 0 repuneri, 0% offroad.
const HUMMOCK_RUN: float = 5.5
const HUMMOCK_RISE: float = 0.75
const HUMMOCK_DROP: float = 1.6

func _build_hummock(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var c := baked[idx]
	var dir := _smooth_dir(idx, 6.0)
	var side := dir.cross(Vector3.UP).normalized()
	var hw := width_at(frac) + 1.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := c - dir * HUMMOCK_RUN
	var crest := c + Vector3.UP * HUMMOCK_RISE
	var back := c + dir * HUMMOCK_DROP
	var l := -side * hw
	var r := side * hw
	# panta de urcare
	st.add_vertex(foot + l); st.add_vertex(foot + r); st.add_vertex(crest + l)
	st.add_vertex(foot + r); st.add_vertex(crest + r); st.add_vertex(crest + l)
	# caderea
	st.add_vertex(crest + l); st.add_vertex(crest + r); st.add_vertex(back + l)
	st.add_vertex(crest + r); st.add_vertex(back + r); st.add_vertex(back + l)
	# capetele (triunghiuri laterale), ca sa nu se vada prin creasta
	st.add_vertex(foot + l); st.add_vertex(crest + l); st.add_vertex(back + l)
	st.add_vertex(foot + r); st.add_vertex(back + r); st.add_vertex(crest + r)
	st.generate_normals()
	var mesh := st.commit()
	var inst := MeshInstance3D.new()
	inst.name = "Hummock"
	inst.mesh = mesh
	# Clasa SNOW, nu ice: creasta e din placi sparte cu zapada suflata peste
	# ele, si mai ales trebuie sa se citeasca de departe pe turcoaz — cu aceeasi
	# textura ca banda se pierdea (masurat pe snapshot la 0.238).
	inst.material_override = Palette.triplanar_class_material("snow")
	add_child(inst)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var tri := mesh.create_trimesh_shape() as ConcavePolygonShape3D
	tri.backface_collision = true
	shape.shape = tri
	body.add_child(shape)
	add_child(body)


func _hummock_fracs() -> Array[float]:
	return []


## `spec` suprascrie ce s-ar fi ales pentru fractia asta: e infatisarea ceruta
## de un [HazardMarker] tras in viewport (vezi HazardMarker.model_spec()).
## Gol — cazul pistelor scrise in cod — inseamna "cauta in `_hazard_kinds()`",
## adica exact comportamentul de dinainte.
func _build_hazard(frac: float, spec: Dictionary = {}) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var hw := width_at(frac)
	# Hazard tematic: in desert, un bolovan desprins din faleza se rostogoleste
	# peste sosea; in rest, excavatorul coboara bratul peste o banda.
	#
	# Pana acum era o MINGE DE PLAJA — ramasita din tema abandonata "jucarii in
	# lada de nisip", intr-un canion de desert.
	# Suprascrierea PER FRACTIE bate steagul de tema.
	#
	# Cat timp o pista avea un singur fel de obstacol mobil, un model pe toata
	# tema era destul. Alpii au patru, si fiecare vine din alta parte a lumii:
	# car cu fan pe ulita satului, sanie cu busteni pe urcarea prin padure,
	# vaca spre pasune, tractor pe returul din vale. Cu un singur steag ar fi
	# fost aceeasi sanie de patru ori, ceea ce ar fi contrazis chiar regula pe
	# care o aplica testoasa din track08: hazardul apartine LOCULUI in care
	# sta, nu tabelului de teme.
	#
	# Potrivirea se face pe DISTANTA, nu pe egalitate de chei.
	#
	# Prima versiune folosea `_hazard_kinds().get(snappedf(frac, 0.001))` si
	# pierdea tacut ultimul hazard: `snappedf(0.938, 0.001)` NU e bit-identic
	# cu literalul `0.938` scris in dictionar, iar Dictionary compara float-uri
	# exact. Trei din patru se potriveau din noroc, al patrulea cadea pe
	# modelul temei — adica bug-ul arata ca "am uitat sa declar unul".
	# O toleranta face intentia explicita si scoate norocul din ecuatie.
	#
	# Un nod care si-a declarat modelul sare peste cautare: el A SPUS deja ce
	# vrea, iar fractia lui e derivata din pozitie, deci n-ar avea cum sa se
	# potriveasca cu o cheie scrisa de mana in dictionar.
	var kind := {}
	if not spec.is_empty():
		kind = spec
	else:
		for key in _hazard_kinds():
			if absf(float(key) - frac) < 0.0005:
				kind = _hazard_kinds()[key]
				break
	var hazard_model: String = String(kind.get("model",
		theme_flag("hazard_model", "")))
	if not hazard_model.is_empty() and ResourceLoader.exists(hazard_model):
		var ball := SlidingHazard.new()
		ball.model_scene = load(hazard_model)
		# 0.52 vine din bolovanul de 5 m diametru -> 2.6 m in joc. O barca de
		# 5 m lungime insa TREBUIE sa ramana de 5 m: la 0.52 ar fi fost o
		# jucarie de 2.6 m tarata peste sosea. De-aia e steag de tema.
		ball.model_scale = float(kind.get("scale",
			theme_flag("hazard_scale", 0.52)))
		ball.model_tri_class = String(kind.get("tri_class",
			theme_flag("hazard_class", "")))
		ball.model_classes = theme_flag("hazard_classes", {})
		# Doar intentia "se rostogoleste"; raza reala o ia din model. Cu
		# `hazard_roll: false` obiectul doar ALUNECA — o barca targita peste
		# causeway nu se da peste cap.
		var rolls := bool(kind.get("roll", theme_flag("hazard_roll", true)))
		ball.roll_radius = 1.0 if rolls else 0.0
		# Noi ii cerem maturarea maxima; el isi taie cursa cat sa nu iasa din
		# sosea pe latimea ASTA de drum (vezi SlidingHazard._clamp_travel).
		# Latimea e cea de la fractia LUI: un hazard dimensionat pe latimea
		# medie ar iesi prin perete exact pe portiunile stramte.
		ball.road_half_width = hw
		ball.phase = fposmod(frac * 3.7, 1.0) # doua obstacole nu bat la unison
		# Pendulare (implicit) sau traversare cu sens — vezi SlidingHazard.Motion.
		# Se pune INAINTE de `travel`: la traversare, capatul cursei e locul de
		# PARCARE si trebuie sa cada dincolo de asfalt, deci `_clamp_travel` are
		# nevoie sa stie modul ca sa nu taie cursa la marginea drumului.
		ball.motion = int(kind.get("motion",
			theme_flag("hazard_motion", 0))) as SlidingHazard.Motion
		# Cu ce se uita obiectul spre directia in care matura. Fara steag ramane
		# pe axele LUMII, ceea ce e o nepasare acceptabila la o barca targ ita
		# (n-are un "inainte" al ei) si vizibil gresit la un animal: o testoasa
		# care traverseaza mergand cu umarul inainte nu traverseaza, pluteste.
		#
		# Rotatia se pune INAINTE de add_child. `SlidingHazard` e un
		# AnimatableBody3D cu sync_to_physics, deci dupa intrarea in arbore
		# transformul il tine serverul de fizica — iar pozitia se rescrie oricum
		# la fiecare pas, dar BAZA nu, deci o rotatie pusa dupa se pierde tacut.
		#
		# La TRAVERSARE e implicit pornit: un vehicul care asteapta pe
		# acostament si intra pe drum are prin definitie un sens de mers, iar
		# unul care ar traversa cu flancul inainte n-ar arata ca traverseaza.
		# La pendulare ramane stins, ca pana acum — o barca targita dus-intors
		# chiar n-are un "inainte".
		var crossing := ball.motion == SlidingHazard.Motion.TRAVERSARE
		if bool(kind.get("face_travel",
				theme_flag("hazard_face_travel", crossing))):
			ball.rotation = Vector3(0.0, atan2(-side.x, -side.z), 0.0)
		add_child(ball)
		ball.center = p
		ball.travel = side * hw * 0.9
		ball.global_position = p
	elif ResourceLoader.exists("res://assets/models/vehicles/rusted_digger.glb"):
		_build_excavator(frac)
	else:
		var box := SlidingHazard.new()
		box.road_half_width = hw
		box.phase = fposmod(frac * 3.7, 1.0)
		add_child(box)
		box.center = p
		box.travel = side * hw * 0.9
		box.global_position = p

## Trimite un gimmick plantat ca nod ([HazardMarker]) la constructorul lui.
##
## Nu construieste NIMIC singur, si asta e tot rostul: fiecare tip trece prin
## exact acelasi `_build_*` pe care il apeleaza si pistele scrise in cod, deci
## un obstacol tras in viewport se comporta identic cu unul declarat intr-o
## fractie. Daca aparea aici o a doua cale de constructie, cele doua ar fi
## divergat la prima corectie de mecanica — exact ce evita [TerrainPeak] prin
## faptul ca hraneste `_peak_specs` in loc sa-si construiasca propriul munte.
##
## Infatisarea declarata pe nod (`spec`) ajunge la bariera mobila (model
## complet), la bolovan (model + clasa de material + TRASEUL desenat ca Path3D
## sub nod, #242 si urmatoarele), la morisca (turnul morii de
## vant, #245) si la deflector (model + piesa + scara + clasa, #244). Restul
## tipurilor isi construiesc vizualul din cod si ignora spec-ul.
func _build_node_hazard(hz: Dictionary) -> void:
	var frac := float(hz.get("frac", 0.0))
	var spec: Dictionary = hz.get("spec", {})
	match int(hz.get("kind", 0)):
		HazardMarker.Kind.SLIDING:
			_build_hazard(frac, spec)
		HazardMarker.Kind.ROCKFALL:
			_build_rockfall(frac, spec)
		HazardMarker.Kind.CAROUSEL:
			_build_carousel(frac, spec)
		HazardMarker.Kind.TRAIN:
			_build_train(frac)
		HazardMarker.Kind.TYPHOON:
			_build_typhoon(frac)
		HazardMarker.Kind.DEFLECTOR:
			_build_deflector(frac, signf(float(hz.get("side", 1))), spec)
		HazardMarker.Kind.FLYOFF:
			_build_flyoff(frac)
		HazardMarker.Kind.EXCAVATOR:
			_build_excavator(frac)
		HazardMarker.Kind.AVALANCHE:
			_build_avalanche(frac)
		HazardMarker.Kind.WAVE:
			# Se sare singur, cu avertisment, daca tema n-are mare.
			_build_wave_surge(frac)
		HazardMarker.Kind.ICE_SLAB:
			_build_ice_field_at(frac)
		HazardMarker.Kind.TRAIN_ALONG:
			_build_train_along(frac)
		HazardMarker.Kind.FUMAROLE:
			_build_fumarole(frac, spec)


## Caruselul: morisca plantata in mijlocul soselei, cu vane care matura toata
## latimea. Vanele stau sub half_width ca sa nu treaca prin pereti.
##
## ATENTIE la ordine: transformarea se pune INAINTE de add_child. Rotorul e un
## AnimatableBody3D cu sync_to_physics, deci transformarea lui o tine serverul
## de fizica — plasat dupa intrarea in arbore, ramane un pas fizic in origine,
## adica exact peste grila de start, si matura tot plutonul la countdown.
func _build_carousel(frac: float, spec: Dictionary = {}) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var carousel := CarouselHazard.new()
	carousel.arm_reach = width_at(frac) - 0.2
	# Cu turn declarat, morisca devine MOARA DE VANT (#245): butucul procedural
	# e inlocuit de cladire, iar bratele se citesc ca aripi. Mecanica ramane
	# aceeasi — rotatie continua, fereastra intre brate, ghiont pe tangenta.
	var tower_path := String(spec.get("model", theme_flag("carousel_model", "")))
	if not tower_path.is_empty() and ResourceLoader.exists(tower_path):
		carousel.tower_scene = load(tower_path)
		carousel.tower_node = String(spec.get("model_node",
			theme_flag("carousel_node", "")))
		carousel.tower_scale = float(spec.get("scale",
			theme_flag("carousel_scale", 1.0)))
		carousel.tower_class = String(spec.get("tri_class",
			theme_flag("carousel_class", "")))
		carousel.tower_classes = theme_flag("carousel_classes", {})
		carousel.mill_blades = true
		# CALARE peste sosea: picioarele de o parte si de alta, tu treci pe
		# dedesubt, aripile matura carosabilul de sus in jos. Varianta cu turnul
		# lateral a picat la prima privire din masina — moara statea in nisip,
		# iar aripile se roteau in jurul axei drumului, deci cele doua nu se
		# legau vizual deloc.
		carousel.straddle = true
		carousel.road_half = width_at(frac)
		# Latura alterneaza determinist cu fractia, ca la bolovan: doua mori pe
		# aceeasi pista n-ar matura amandoua aceeasi banda.
		carousel.straddle_side = signf(sin(frac * 23.0))
		# Turnul sta pe MARGINEA drumului, dincolo de bataia aripilor: pe axa ar
		# fi fost o cladire in mijlocul soselei. Bratele raman centrate pe axa,
		# deci fereastra de trecere nu se schimba.
		#
		# `tower_offset` e pe X LOCAL, deci nodul trebuie orientat. Fara
		# orientare, turnul ar cadea pe axa X a LUMII — adica oriunde, in
		# functie de cum se intampla sa fie intors drumul acolo.
		#
		# Rotatie DOAR pe verticala (yaw), nu `Basis.looking_at(dir)`: aia
		# aliniaza -Z pe directia drumului CU TOT CU PANTA, deci pe o portiune
		# inclinata inclina si axa verticala a nodului — iar moara, care e
		# lipita de ea, se culca pe nisip. Exact ce s-a intamplat la prima
		# incercare, pe Dunele la 0.945 (vezi snapshots/dunele_joc.png): turnul
		# zacea pe o parte, cu paletele in pamant.
		#
		# Aripile se rotesc oricum in jurul lui Y local, deci nu au nevoie de
		# panta; iar o moara sta vertical si pe un deal.
		var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
		var yaw := atan2(dir.x, dir.z)
		carousel.transform = Transform3D(
			Basis(Vector3.UP, yaw), baked[idx])
		# Picioarele stau chiar pe marginile soselei, cat sa nu intre in
		# carosabil: `half_width` plus jumatatea latimii turnului (~1.4 m).
		# Deschiderea dintre ele e atunci toata latimea drumului — treci pe sub
		# moara fara sa atingi nimic, exact ideea gimmickului.
		carousel.tower_offset = width_at(frac) + 1.4
		add_child(carousel)
		return
	carousel.position = baked[idx]
	add_child(carousel)

## Bolovan care cade de pe faleza pe o banda a soselei.
##
## Ocupa jumatatea dinspre o margine, nu tot drumul: blocarea completa e treaba
## caruselului, iar aici trebuie sa ramana mereu o linie curata ca sa fie alegere.
## Latura alterneaza determinist cu fractia, ca doua bolovanuri consecutive sa nu
## cada pe aceeasi banda.
func _build_rockfall(frac: float, spec: Dictionary = {}) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * signf(sin(frac * 17.0))
	var rock := RockfallHazard.new()
	# Defazare din fractie, ca la SlidingHazard: doua bolovanuri nu cad la unison.
	rock.phase = fposmod(frac * 3.7, 1.0)
	# Clasa de material: ce cere nodul, altfel steagul dedicat al temei, altfel
	# ROCA LUMII (`rock_class` — sisturile alpine, gresia canionului). Ultima
	# treapta e cea care conteaza: bolovanul care se desprinde dintr-o faleza e
	# din aceeasi piatra cu ea, si asta ar trebui sa fie adevarat implicit, nu
	# doar pe temele care si-au adus aminte sa declare.
	#
	# DOAR pentru bolovanul implicit, insa: un model adus de nod (bomba
	# vulcanica) vine cu propriile sloturi din atlas, iar clasa temei le-ar
	# sterge pe toate — bombele Stromboli ieseau portocalii pe tot corpul, cu
	# semnalul crapaturilor pierdut. Modelul custom isi ia clasele pe PARTI,
	# din maparea comuna (vezi RockfallHazard._extract).
	var model_path := String(spec.get("model", ""))
	rock.tri_class = String(spec.get("tri_class", ""))
	if rock.tri_class.is_empty() and model_path.is_empty():
		rock.tri_class = theme_flag("rockfall_class", theme_flag("rock_class", ""))
	# Modelul: ce cere nodul (grupul „Model" de pe HazardMarker), altfel
	# bolovanul implicit al hazardului (`boulder_roller.glb`). Scara 0 =
	# „implicitul modelului ales" — un GLB din kit e la scara reala, bolovanul
	# de 5 m se micsoreaza singur.
	if not model_path.is_empty() and ResourceLoader.exists(model_path):
		rock.model_scene = load(model_path)
		rock.model_scale = float(spec.get("scale", 1.0))
		rock.model_node = String(spec.get("model_node", ""))
	rock.route_speed = float(spec.get("rock_speed",
		RockfallHazard.DEFAULT_ROUTE_SPEED))
	rock.route_pause = float(spec.get("rock_pause",
		RockfallHazard.DEFAULT_ROUTE_PAUSE))
	rock.stick_to_ground = bool(spec.get("rock_stick_to_ground", true))
	for g in spec.get("groups", []):
		rock.add_to_group(g)
	# Cu TRASEU desenat in editor: bolovanul urmeaza curba de la primul punct
	# la ultimul, iar hazardul se planteaza pe sosea sub locul in care curba
	# trece cel mai aproape de nod. Nu mai e nimic de dedus despre versant —
	# a spus dezvoltatorul, cu mana, de unde vine si pe unde merge.
	var route: Curve3D = spec.get("route", null)
	if route != null:
		var at: Vector3 = spec.get("at", p)
		var near := _route_point_near(route, at)
		rock.route = route
		rock.position = Vector3(near.x, p.y, near.z)
		add_child(rock)
		return
	# Punctul de impact: o banda, nu axa drumului (blocarea completa e treaba
	# caruselului). Y de pe SOSEA, nu de pe teren: piatra aterizeaza pe asfalt.
	var hit := p + side * (width_at(frac) * 0.45)
	# Din ce parte VINE. Se alege latura pe care chiar exista deal, masurand
	# terenul de-o parte si de alta — un bolovan care se rostogoleste dintr-un
	# camp neted ar fi la fel de neexplicat ca unul care cadea din cer.
	rock.slope_side = _rockfall_slope_side(p, side, frac)
	# Nodul se orienteaza cu +X spre versant, ca `_start_pos()` sa fie doar „pe X
	# local" — aceeasi conventie ca la avalansa, unde masa coboara tot pe X.
	# Transformarea INAINTE de add_child, ca la restul hazardelor cu corp
	# cinematic: dupa intrarea in arbore o tine serverul de fizica.
	if rock.slope_side != 0.0:
		# Directia spre versant, in lume. `Basis.looking_at(f)` pune -Z pe `f` si
		# +X la dreapta lui; ca +X sa cada FIX pe versant, privirea trebuie sa fie
		# perpendiculara pe el — adica de-a lungul drumului, intr-un sens sau
		# altul, ales tocmai ca +X sa iasa spre deal.
		var toward := (side * rock.slope_side).normalized()
		var look := Vector3(toward.z, 0.0, -toward.x) # rotit -90° in plan
		rock.transform = Transform3D(Basis.looking_at(look, Vector3.UP), hit)
	else:
		rock.position = hit
	add_child(rock)


## Punctul de pe curba cel mai apropiat (in plan) de `at`.
func _route_point_near(route: Curve3D, at: Vector3) -> Vector3:
	var best := route.get_point_position(0)
	var best_d := INF
	var total := route.get_baked_length()
	var d := 0.0
	while d <= total:
		var s := route.sample_baked(d, true)
		var dist := Vector2(s.x - at.x, s.z - at.z).length()
		if dist < best_d:
			best_d = dist
			best = s
		d += 0.25
	return best


## Pe ce latura a punctului de impact e versantul din care se desprinde piatra:
## +1 spre `side`, -1 spre partea opusa, 0 = teren plat pe amandoua (cade
## vertical, ca inainte de #242).
##
## Se MASOARA terenul, nu se presupune. Pe o pista de munte dealul e cand la
## stanga, cand la dreapta, iar o latura aleasa din fractie (ca banda de impact)
## ar fi nimerit versantul pe jumatate din cazuri — adica exact jumatate din
## bolovani ar fi venit dintr-o vale.
func _rockfall_slope_side(p: Vector3, side: Vector3, frac: float) -> float:
	if _sampler == null:
		return 0.0
	# Distanta la care se intreaba NU e aleasa din ochi: langa asfalt terenul e
	# aplatizat deliberat, iar masivele sunt stinse complet sub
	# `TrackSideSampler.PEAK_ROAD_CLEAR` (6 m de la marginea drumului) si ajung
	# la putere plina abia la `PEAK_ROAD_FULL` (32 m). Intrebat mai aproape,
	# orice munte pare camp — prima varianta masura la 14 m, adica in plina
	# zona de stingere, si raporta „teren plat" langa masivul central al
	# Alpilor.
	var reach := width_at(frac) + TrackSideSampler.PEAK_ROAD_FULL
	var a := p + side * reach
	var b := p - side * reach
	var ya := _sampler.ground_y(a.x, a.z) - p.y
	var yb := _sampler.ground_y(b.x, b.z) - p.y
	# Pragul: sub 3 m diferenta nu e „versant", e denivelare. O piatra care se
	# rostogoleste de pe un damb de doi metri nu explica nimic.
	const MIN_RISE := 3.0
	if maxf(ya, yb) >= MIN_RISE:
		return 1.0 if ya >= yb else -1.0
	# Fara deal in teren, mai exista o sursa cinstita: FALEZELE de canion. Ele
	# sunt geometrie separata, construita ABIA DUPA hazarde (`_build_world_decor`
	# ruleaza la sfarsitul lui `rebuild`), deci nodul lor nici nu exista cand
	# intrebam. Pe Dunele, unde bolovanii stau exact la poalele canionului,
	# masuratoarea de teren raporta camp neted si piatra ar fi continuat sa cada
	# din cer fix acolo unde peretele de stanca era la cativa metri.
	#
	# Se intreaba SURSA, nu rezultatul: `wall_segments` e chiar lista pe care o
	# citeste si TrackCliffs ca sa decida unde ridica pereti, deci cele doua nu
	# se pot contrazice.
	# `+1` = latura pe care sta banda de impact (nodul e deja orientat cu +X
	# spre ea), deci bolovanul vine de deasupra locului in care aterizeaza.
	return _cliff_slope_side(frac, 1.0)


## Latura pe care [TrackCliffs] ridica perete la fractia asta (+1 dreapta, -1
## stanga, 0 daca niciuna).
##
## Pe o pista de canion peretii sunt de obicei pe AMANDOUA laturile (masurat:
## in toate punctele de rockfall de pe Dunele si Alpii). O prima versiune
## intorcea 0 in cazul asta — „nu exista partea cu dealul" — si efectul practic
## era ca detectia de faleze nu se aplica NICIODATA, adica exact pistele pentru
## care fusese scrisa ramaneau cu bolovani cazand din cer.
##
## Cu perete de ambele parti, alegerea ramane oricum cinstita: piatra vine de pe
## faleza dinspre EXTERIORUL virajului, cea inalta si continua, nu de pe umarul
## dinspre interior. Pe portiunile drepte cele doua sunt echivalente, deci
## alegerea nu poate fi „gresita" — poate fi doar arbitrara, si atunci o facem
## determinista (latura de impact), nu aleatoare.
func _cliff_slope_side(frac: float, impact_side: float) -> float:
	if _sampler == null or not theme_flag("cliffs", false):
		return 0.0
	var here := frac * _sampler.total_length()
	var right := _within_wall(_sampler.wall_segments(1.0), here)
	var left := _within_wall(_sampler.wall_segments(-1.0), here)
	if not right and not left:
		return 0.0
	if right != left:
		return 1.0 if right else -1.0
	# Ambele: bolovanul vine dinspre banda pe care oricum aterizeaza, ca sa nu
	# traverseze tot drumul si sa nu blocheze si linia curata de trecere.
	return impact_side


func _within_wall(segments: Array[Vector2], at_m: float) -> bool:
	for s in segments:
		if at_m >= s.x and at_m <= s.y:
			return true
	return false


## Avalansa: masa de zapada care coboara de pe versant si traverseaza soseaua.
##
## Fractii, ca la restul gimmickurilor — dar spre deosebire de bolovan, care
## ocupa o banda, avalansa ACOPERA TOT DRUMUL. E o alegere de ritm, nu de linie:
## nu exista traiectorie sigura, exista doar „ai trecut inainte" sau „nu ai".
## De aceea telegraful e de 3.2 s (vezi AvalancheHazard.TELEGRAPH) si de aceea
## nu se pune niciodata in apex — style_bible §7 cere sa nu blochezi citirea
## virajului, iar aici blocajul e total.
## Avalansa: masa de zapada care coboara de pe versant si traverseaza soseaua.
##
## Fractii, ca la restul gimmickurilor — dar spre deosebire de bolovan, care
## ocupa o banda, avalansa ACOPERA TOT DRUMUL. E o alegere de ritm, nu de linie:
## nu exista traiectorie sigura, exista doar „ai trecut inainte" sau „nu ai".
## De aceea telegraful e de 3.2 s (vezi AvalancheHazard.TELEGRAPH) si de aceea
## nu se pune niciodata in apex — style_bible §7 cere sa nu blochezi citirea
## virajului, iar aici blocajul e total.
func _build_avalanche(frac: float) -> void:
	var n := baked.size()
	if n == 0:
		return
	# Mutata din apexul unui viraj, ca trecerea de cale ferata: pe o portiune
	# calma jucatorul VEDE masa venind si poate decide, ceea ce e tot rostul
	# telegrafului lung.
	var idx := _calm_index_near(int(frac * float(n)) % n, 30.0)
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var av := AvalancheHazard.new()
	av.road_half_width = width_at(frac_at(idx))
	av.phase = fposmod(frac * 3.7, 1.0) # doua avalanse nu pornesc la unison
	# ATENTIE la ordine: transformarea INAINTE de add_child. Masa e un
	# AnimatableBody3D cu sync_to_physics, deci transformarea o tine serverul de
	# fizica; pusa dupa intrarea in arbore, ramane un pas fizic in origine —
	# adica exact peste grila de start, si matura tot plutonul la countdown.
	#
	# `looking_at(dir)` da -Z pe sensul cursei si +X pe marginea din dreapta,
	# conventia din tot proiectul. Avalansa coboara pe X local (vezi
	# `_start_point` / `_end_point`), deci traverseaza perpendicular pe drum.
	av.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), p)
	add_child(av)


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


## TREN PE SENS (Baikal): sina in lungul soselei, trenul vine din fata.
##
## Baza e looking_at(rail): -Z pe perpendiculara, deci X local cade pe
## directia drumului, INVERSATA (X = -dir) — trenul inainteaza spre +X in
## spatiul lui, adica spre masinile care vin. E chiar prima versiune de la
## trecerea perpendiculara, folosita acum cu intentie.
##
## Lungimea sinei nu vine din degajarea fata de sosea (aici e zero — sina E pe
## sosea), ci din cat de DREAPTA e soseaua in jurul fractiei: se merge inainte
## si inapoi cat timp axa nu se abate mai mult de 1.5 m de la dreapta prin
## origine, cu plafon 110 m. Un tren drept pe un drum curb ar iesi de pe asfalt.
##
## Sectorul intra in `_lane_bias` (cu 40 m inainte de capatul dinspre masini),
## de unde AI-ul afla ca aici se sta pe margine, nu pe axa — altfel jumatate
## din pluton ar muri la fiecare tur, si asta nu e AI onest, e AI orb.
## Fumarola: gura de abur de pe marginea drumului, cu ceas propriu.
##
## Nu construieste model — gura in sine e decor asezat de mana in .tscn
## (`fumarole_vent.glb` sub DecorManual). Ce adauga aici e MECANICA: coloana
## de particule si zona care albeste ecranul. Asa ramane hazardul deasupra
## decorului fara sa duplice assetul, si fara sa consume un material.
##
## Pozitia vine din `spec["at"]` (unde a fost tras nodul), nu din fractie:
## gurile stau pe faleza, la cativa metri lateral. Doar COTA se ia de la drum,
## dupa regula lui HazardMarker (Y-ul nodului e ignorat) — o gura tarata cu 3 m
## prea sus ar sufla din aer.
func _build_fumarole(frac: float, spec: Dictionary = {}) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p: Vector3 = baked[idx]
	var f := FumaroleHazard.new()
	f.road_width = width_at(frac) * 2.0
	for key in ["period", "on_time", "phase", "reach", "blind_seconds"]:
		if spec.has(key):
			f.set(key, spec[key])
	var at: Vector3 = spec.get("at", p)
	# Cota de la sosea, restul de la nod: vezi nota din antet.
	add_child(f)
	f.position = Vector3(at.x, p.y, at.z)


func _build_train_along(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	# Directia din puncte la +/-20 m, nu din segmentul local: pe o curba coapta
	# Catmull-Rom tangenta locala tremura cu ~1 grad, si la 100 m de sina 1
	# grad inseamna aproape 2 m de abatere. Aceeasi directie intra si in
	# masuratoarea de dreptime.
	var dir := _smooth_dir(idx, 20.0)
	var rail := dir.cross(Vector3.UP).normalized()
	var half := _straight_reach(idx, 110.0, 1.5)
	var train := TrainHazard.new()
	train.along_road = true
	train.road_half_width = width_at(frac)
	train.half_rail = half
	train.ground_drop = _rail_ground_drop(p, dir, half)
	train.transform = Transform3D(Basis.looking_at(rail, Vector3.UP), p)
	add_child(train)
	var total := _dists[n]
	var f0 := fposmod((_dists[idx] - half - 40.0) / total, 1.0)
	var f1 := fposmod((_dists[idx] + half) / total, 1.0)
	_lane_bias.append(Vector3(f0, f1, 0.62))


## Cat de departe (m) ramane soseaua DREAPTA in jurul indexului: se avanseaza
## in ambele sensuri cat timp abaterea laterala fata de tangenta din origine
## sta sub `tol`. Intoarce minimul celor doua parti, plafonat.
func _straight_reach(idx: int, max_len: float, tol: float) -> float:
	var n := baked.size()
	var p := baked[idx]
	var dir := _smooth_dir(idx, 20.0)
	var reach := max_len
	for sgn: int in [1, -1]:
		var d := 0.0
		var k := 1
		while d < max_len:
			var q := baked[((idx + sgn * k) % n + n) % n]
			var v := q - p
			var along := v.dot(dir)
			var lat := (v - dir * along).length()
			d = absf(along)
			if lat > tol:
				break
			k += 1
		reach = minf(reach, d)
	return maxf(reach, 30.0)


## Directia soselei la index, netezita pe +/- `span_m`: coarda dintre punctul
## din spate si cel din fata, nu segmentul local.
func _smooth_dir(idx: int, span_m: float) -> Vector3:
	var n := baked.size()
	var steps := maxi(1, int(span_m / maxf(_dists[n] / float(n), 0.001)))
	var a := baked[((idx - steps) % n + n) % n]
	var b := baked[(idx + steps) % n]
	var d := b - a
	d.y = 0.0
	if d.length() < 0.01:
		return (baked[(idx + 1) % n] - baked[idx]).normalized()
	return d.normalized()


## Sectoare in care AI-ul se tine de MARGINE, nu de axa: (frac_start,
## frac_end, |linie| minima 0..1). Umplut de hazardele care ocupa axa (trenul
## pe sens). Vezi AIController.
var _lane_bias: Array[Vector3] = []

func lane_bias_at(index: int) -> float:
	if _lane_bias.is_empty():
		return 0.0
	var f := frac_at(index)
	var out := 0.0
	for seg in _lane_bias:
		var inside: bool
		if seg.x <= seg.y:
			inside = f >= seg.x and f <= seg.y
		else:
			inside = f >= seg.x or f <= seg.y
		if inside:
			out = maxf(out, seg.z)
	return out


func _train_along_fracs() -> Array[float]:
	return []


## Campul de placi crapate (Baikal, brief §2 POI C): pe intervalul dat,
## suprafata de gheata se sparge in placi poligonale Voronoi ridicate peste
## placa lacului, cu fisuri de apa neagra intre ele si 3-4 placi „vii" care
## se inclina sub masini si se rup sub incarcare mare. Vezi [IceFieldHazard]
## — pista calculeaza aici traseul (probe de centru, laterale, semilatimi),
## hazardul primeste doar numere, ca la tren si la pod.
##
## A inlocuit placa singulara IceSlabHazard: trei dreptunghiuri identice pe
## banda nu citeau ca un camp si nu lasau nimic de ales; skill-ul cerut de
## brief e citirea campului si alegerea liniei.
func _build_ice_field(rg: Vector2) -> void:
	var n := baked.size()
	var i0 := int(fposmod(rg.x, 1.0) * float(n))
	var count := int(fposmod(rg.y - rg.x, 1.0) * float(n))
	if count < 4:
		return
	var pts := PackedVector3Array()
	var sides := PackedVector3Array()
	var hws := PackedFloat32Array()
	for k in count + 1:
		var i := (i0 + k) % n
		pts.append(baked[i])
		sides.append(_side_at(i))
		hws.append(width_at_index(i))
	var field := IceFieldHazard.new()
	field.name = "IceField"
	# ACEEASI instanta de material ca banda de gheata: placile sunt, la
	# propriu, din gheata drumului, si numaratoarea de materiale nu urca.
	field.setup(pts, sides, hws, _world_seed(), _ice_road_material())
	add_child(field)
	_built_ice_fields.append(rg)


## Un HazardMarker ICE_SLAB tras in viewport devine un camp centrat pe nod,
## cu lungimea implicita — acelasi generator, hranit in doua feluri.
const ICE_FIELD_DEFAULT_LEN: float = 120.0

func _build_ice_field_at(frac: float) -> void:
	var total := _dists[baked.size()]
	var half := ICE_FIELD_DEFAULT_LEN * 0.5 / total
	_build_ice_field(Vector2(fposmod(frac - half, 1.0),
		fposmod(frac + half, 1.0)))


func _ice_field_ranges() -> Array[Vector2]:
	return []


## Intervalele campurilor CONSTRUITE (din cod sau din markere) — betele cu
## stegulete le ocolesc, altfel ar ramane ingropate in campul ridicat.
var _built_ice_fields: Array[Vector2] = []

func _in_ice_field(frac: float) -> bool:
	var f := fposmod(frac, 1.0)
	for rg in _built_ice_fields:
		if rg.x <= rg.y:
			if f >= rg.x and f <= rg.y:
				return true
		elif f >= rg.x or f <= rg.y:
			return true
	return false


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


## Inaltimea trambulinei de peste canal, si cat de mult arunca.
##
## 1.4 m e jumatate din creasta de fly-off (2.6): acolo buza e pe marginea unei
## rapi si panta ajuta, aici trambulina sta pe teren plat si TOATA inaltimea se
## simte in suspensie la aterizare. Factorul 0.34 e peste cel al crestei (0.25)
## din motivul opus: creasta arunca pe cine vrea sa zboare, trambulina asta
## trebuie sa treaca pe toata lumea peste un gol de 26 m, altfel golul devine
## o capcana, nu o decizie.
## Plafonul NU e ce limiteaza distanta aici, desi asa pare la prima vedere.
## Ce limiteaza e `Car.drag`, care se aplica si in aer (car.gd, "hvel -= hvel *
## drag * delta", in afara oricarui `is_on_floor()`): la 0.35 si ~2.4 s de
## zbor, masina pierde peste jumatate din viteza orizontala cat e in aer —
## masurat cu tools/probe_jump.gd, 36.9 m/s la desprindere si 17.9 la
## aterizare. De aceea saritura se plafoneaza in jur de 40 m indiferent cu ce
## viteza intri, si de aceea golul de aici e dimensionat pe cifra MASURATA, nu
## pe cea balistica (care ar da ~87 m).
const CHANNEL_JUMP_HEIGHT: float = 1.4
const CHANNEL_JUMP_FACTOR: float = 0.34
const CHANNEL_JUMP_MAX: float = 13.0

## Trambulina de peste un canal declarat cu `jump: true`.
##
## Spre deosebire de [method _build_ramp], care aseaza o rampa pe JUMATATE de
## sosea (alegere de linie, o poti ocoli), asta tine toata latimea: golul e pe
## toata soseaua, deci si lansarea trebuie sa fie. Cine intra incet tot cade —
## si tocmai asta e decizia de turbo pe care o cere principiul 2.
func _build_channel_kicker(ch: Dictionary) -> void:
	var n := baked.size()
	var near_i: int = ch["near"]
	# Trambulina se sprijina pe ULTIMELE puncte de asfalt dinaintea golului.
	# Indicele, nu metrii: capetele golului sunt puncte coapte (vezi _road_gap),
	# iar o a doua definitie in metri ar diverge la primul retus de traseu.
	var lip := baked[near_i]
	var prev := baked[((near_i - 3) % n + n) % n]
	var dir := (lip - prev).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var hw := width_at_index(near_i)
	var run := 9.0
	var base := lip - dir * run
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bl := base - side * hw
	var br := base + side * hw
	var tl := lip - side * hw + Vector3.UP * CHANNEL_JUMP_HEIGHT
	var tr := lip + side * hw + Vector3.UP * CHANNEL_JUMP_HEIGHT
	# Panta de urcare.
	st.add_vertex(bl); st.add_vertex(br); st.add_vertex(tl)
	st.add_vertex(br); st.add_vertex(tr); st.add_vertex(tl)
	# Peretele de la buza, ca trambulina sa nu fie o pana transparenta lateral.
	st.add_vertex(tl); st.add_vertex(tr); st.add_vertex(lip - side * hw)
	st.add_vertex(tr); st.add_vertex(lip + side * hw)
	st.add_vertex(lip - side * hw)
	# Laturile.
	st.add_vertex(bl); st.add_vertex(tl); st.add_vertex(lip - side * hw)
	st.add_vertex(br); st.add_vertex(lip + side * hw); st.add_vertex(tr)
	st.generate_normals()
	# Acelasi portocaliu ca rampele si creasta: jucatorul stie ca portocaliu
	# inseamna "sari", si e singurul cod de culoare cu care e antrenat.
	_add_mesh_with_collision(st.commit(), Color(0.95, 0.6, 0.1))

	var kicker := FlyoffKicker.new()
	kicker.name = "Trambulina_%s" % String(ch.get("label", "canal"))
	kicker.launch_factor = CHANNEL_JUMP_FACTOR
	kicker.launch_max = CHANNEL_JUMP_MAX
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(hw * 2.0, 2.6, 3.0)
	shape.shape = box
	kicker.add_child(shape)
	# Transformarea INAINTE de add_child, ca la pod si la tren.
	kicker.transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		lip - dir * 1.2 + Vector3.UP * (CHANNEL_JUMP_HEIGHT + 0.9)
			- global_position)
	add_child(kicker)


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
func _build_deflector(frac: float, side_sign: float = 1.0,
		spec: Dictionary = {}) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var deflector := DeflectorHazard.new()
	deflector.road_half_width = half_width
	deflector.side_sign = side_sign
	# Din ce e facuta bariera: ce cere nodul, altfel obiectul temei, altfel
	# lama alba cu dungi de dinainte (#244). Fiecare lume are alt lucru cazut
	# peste drum — un trunchi pe insula, un bolovan in canion.
	var model_path := String(spec.get("model",
		theme_flag("deflector_model", "")))
	if not model_path.is_empty() and ResourceLoader.exists(model_path):
		deflector.model_scene = load(model_path)
		deflector.model_node = String(spec.get("model_node",
			theme_flag("deflector_node", "")))
		deflector.model_scale = float(spec.get("scale",
			theme_flag("deflector_scale", 1.0)))
		deflector.tri_class = String(spec.get("tri_class",
			theme_flag("deflector_class", theme_flag("rock_class", ""))))
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
		var s0 := _side_at(i) * width_at_index(i)
		var s1 := _side_at(j) * width_at_index(j)
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
	var sl := _side_at(last) * width_at_index(last)
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
	box.size = Vector3(width_at_index(idx) * 2.0, 2.6, 3.0)
	shape.shape = box
	kicker.add_child(shape)
	kicker.transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		baked[idx] - dir * 1.2 + Vector3.UP * (FLYOFF_HEIGHT + 0.9))
	add_child(kicker)

## Plasa de repunere a viaductului: o cutie sub fiecare tablier declarat in
## [method _viaduct_ravines]. SeaRespawn incepe abia la 1.2 m sub apa, dar o
## cadere de pe tablier se poate opri pe bancul de mal de langa fusta
## (teren la 0.9-2 m; masurat cu ProbeRace pe Chongqing: masini intepenite
## 25 s la frac 0.547, y intre -4 si 0, deasupra plasei marii si fara drum
## inapoi pe tablier). Aceeasi idee ca _build_flyoff_net: plafonul se ia din
## cel mai jos punct de tablier al ferestrei, minus o marja — cine conduce pe
## pod nu il atinge, cine a cazut sub buza lui e prins oriunde ar ateriza.
func _build_viaduct_nets() -> void:
	var n := baked.size()
	if n == 0:
		return
	var total: float = _dists[n] if _dists.size() > n else 0.0
	if total <= 0.0:
		return
	var rav := _ravines()
	for ri in _viaduct_ravines():
		if ri < 0 or ri >= rav.size():
			continue
		var r: Vector4 = rav[ri]
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		var deck_min := INF
		for i in n:
			var f := _dists[i] / total
			var inside := (f >= r.x and f <= r.y) if r.x <= r.y 				else (f >= r.x or f <= r.y)
			if not inside:
				continue
			var p := baked[i]
			lo = lo.min(Vector2(p.x, p.z))
			hi = hi.max(Vector2(p.x, p.z))
			deck_min = minf(deck_min, p.y)
		if deck_min == INF:
			continue
		var top := deck_min - 1.6
		var bottom := top - 25.0
		var zone := RespawnZone.new()
		zone.name = "ViaductNet%d" % ri
		zone.backoff_m = 16.0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(hi.x - lo.x + VIADUCT_NET_MARGIN * 2.0,
			top - bottom, hi.y - lo.y + VIADUCT_NET_MARGIN * 2.0)
		shape.shape = box
		zone.add_child(shape)
		zone.position = Vector3((lo.x + hi.x) * 0.5, (top + bottom) * 0.5,
			(lo.y + hi.y) * 0.5)
		add_child(zone)

## Cat dincolo de amprenta XZ a tablierului se intinde plasa viaductului.
const VIADUCT_NET_MARGIN: float = 45.0

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
## Materialul CAROSABILULUI, pentru suprafetele de condus construite de
## hazarde (pasajul rotativ isi face singur tablierul si ocolul).
##
## [b]De ce exista.[/b] Un hazard care emite prin `PaletteBox` primea
## `Palette.world_material()` — materialul triplanar al LUMII, adica piatra.
## Pe Chongqing asta se vedea exact asa cum a raportat dezvoltatorul: tablierul
## pasajului iesea negru si ondulat langa o sosea neteda albastru-gri, deci se
## citea ca o gaura in carosabil, nu ca drum. Nicio schimbare de SLOT nu putea
## sa repare asta: slotul da culoarea, dar tiparul de suprafata venea din alta
## textura.
##
## [b]Nu costa un material in plus[/b] — si asta e conditia ca sa fie voie.
## `_flat_material` e cache-uit pe (culoare, texturi, finisaj), iar cererea de
## aici trece exact aceleasi valori ca soseaua: se intoarce ACELASI obiect.
## Garda numara materiale, si numarul nu se misca.
func road_material() -> Material:
	var base := ROAD_COLOR
	var macro_mean := ASPHALT_MACRO_MEAN
	if road_surface == "snow":
		base = SNOW_ROAD_COLOR
		macro_mean = SNOW_MACRO_MEAN
	elif road_is_loose():
		base = dirt_road_color()
		macro_mean = SAND_MACRO_MEAN
	var color := Color(base.r / macro_mean, base.g / macro_mean,
		base.b / macro_mean)
	var micro := "res://assets/textures/surface_asphalt.png"
	var macro := "res://assets/textures/surface_asphalt_macro.png"
	var rough := 0.82
	var spec := 0.3
	if road_surface == "snow":
		micro = "res://assets/textures/surface_snow.png"
		macro = "res://assets/textures/surface_snow_macro.png"
		rough = 1.0
		spec = 0.0
	elif road_is_loose():
		micro = "res://assets/textures/surface_sand.png"
		macro = "res://assets/textures/surface_sand_macro.png"
		rough = 1.0
		spec = 0.0
	return _flat_material(color, _tex(micro), rough, spec,
		BaseMaterial3D.CULL_BACK, _tex(macro))


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
		visible_mesh: bool = true,
		override_material: Material = null) -> void:
	# visible_mesh = false: doar fizica, fara desen. Zidul exterior pe pistele
	# care nu vor panglica vizibila ramane totusi zid — altfel se deschide
	# marginea buclei (pe Okinawa, direct in mare).
	if visible_mesh:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		# override_material: pentru suprafetele care au nevoie de shader
		# propriu (soseaua de zapada cu masca de uzura), in locul materialului
		# standard din cache.
		inst.material_override = override_material if override_material != null \
			else _flat_material(color, texture, roughness,
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
	var cell_w := width_at_index(0) * 2.0 / float(cols)
	var cell_l := 1.6
	var lift := Vector3.UP * 0.05 # putin peste asfalt, contra z-fighting
	for row in 2:
		for col in cols:
			var origin := baked[0] + lift \
				+ dir * (float(row) * cell_l) \
				+ side * (-width_at_index(0) + float(col) * cell_w)
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
		if _road_gap(i, j) or _road_ice(i, j):
			continue
		# Pe VIADUCT la fel: umarul cobora de la buza asfaltului pana la fundul
		# rapei — un zid de 13 m cu textura de pietris, care ascundea pilele
		# si arcadele din kit (vazut din lateral cu Snapshot --eye).
		var bridge := maxf(maxf(_bridge_mix(i), _bridge_mix(j)),
			maxf(_viaduct_mix(i), _overpass_mix(i)))
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
			var inner0 := baked[i] + s0 * width_at_index(i) * side_sign
			var inner1 := baked[j] + s1 * width_at_index(j) * side_sign
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
		var p := base + lat * (width_at_index(i) + w)
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
		if _road_gap(i, j) or _road_ice(i, j):
			continue
		# Linia de apex: spre interiorul virajului, nu pe axa drumului.
		var lane0 := -offset_sign[i] * width_at_index(i) * 0.35
		var lane1 := -offset_sign[j] * width_at_index(j) * 0.35
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
	#
	# DOAR pe nisip, nu pe orice suprafata afanata: pe drumul de ZAPADA
	# bordurile raman — sunt mobilier turnat care iese de sub stratul alb, nu
	# vopsea pe el, iar pe o suprafata altfel uniform alba sunt singurul semnal
	# saturat de franare (brief-ul Baikal le cere explicit pe virajele malului).
	if road_surface == "dirt":
		return
	# Nici un drum public de munte n-are, si din acelasi motiv: bordura rosu-alb
	# e mobilier de CIRCUIT. Pe Alpii ea era chiar „marginea rosie" cea mai
	# vizibila din vederea soferului — mai vizibila decat gardul, fiindca sta pe
	# asfalt, in ax, pe toata durata virajului. Un drum care traverseaza pasuni
	# si serpentine de cornisa se termina in pietris si iarba, nu intr-o dunga
	# vopsita. Semnalul de franare ramane pe chevron-uri si pe umar, ca la
	# drumul de nisip. Vezi "kerbs" in themes().
	if not theme_flag("kerbs", true):
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
		if _road_gap(i, j) or _road_ice(i, j):
			continue
		var v0 := _dists[i] / KERB_TILE
		var v1 := _dists[mini(i + 2, n)] / KERB_TILE
		var block := i / 2
		var wear := 1.0 + KERB_WEAR_DEPTH * (_patch_step(block, 1.0) - 0.5)
		var tint := (KERB_RED if block % 2 == 0 else KERB_WHITE) * wear
		var edge := tint * KERB_EDGE_SHADE
		for side_sign: float in [-1.0, 1.0]:
			var e0 := baked[i] + _side_at(i) * width_at_index(i) * side_sign + lift
			var e1 := baked[j] + _side_at(j) * width_at_index(j) * side_sign + lift
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
	# Nuanta de roca a lumii, INAINTE de build: se aplica pe fiecare stanca la
	# asezare. Alb = neatinsa, deci pistele fara steag raman identice.
	var rock_tint: Variant = theme_flag("rock_tint", null)
	TrackDecor.set_rock_tint(rock_tint as Color if rock_tint != null
		else Color.WHITE)
	TrackDecor.set_rock_class(String(theme_flag("rock_class", "")))
	# Pe gheata nu se pune decor de margine (vezi TrackDecor.set_frac_veto);
	# Callable gol pe pistele fara gheata, deci nimic nu se schimba acolo.
	TrackDecor.set_frac_veto(Callable(self, "is_ice_at")
		if not _ice_ranges().is_empty() else Callable())
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
	# Iarba densa de margine (prototip): fire-geometrie pe banda de langa
	# asfalt, cu vant in shader si topire cu distanta. NU intra in
	# _decor_roots (n-are volum, nimic nu trebuie s-o ocoleasca) si nici in
	# coacere (e deja MultiMesh pe celule). Vezi TrackGrass.
	if bool(theme_flag("dense_grass", false)):
		var grass := TrackGrass.build(_sampler, _world_seed(), theme_ground_tint,
			float(theme_flag("dense_grass_max_y", 1e9)))
		add_child(grass)


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
	var park := p + side * (width_at(frac) * 0.8)
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
	var stand := p + side * (width_at(frac) + 12.0)
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
	# Arcada e integral roca — primeste trim sheet-ul de clasa. Piatra
	# LOCULUI: pe temele cu `rock_class` declarat (granitul alpin, pe Baikal)
	# ia clasa aia, altfel gresia canionului — o arcada de gresie portocalie
	# peste un lac inghetat se vedea din prima captura.
	var arch_cls := String(theme_flag("rock_class", ""))
	if arch_cls.is_empty():
		Palette.apply_rock_material(model)
	else:
		Palette.apply_triplanar_class(model, arch_cls)
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
	var stand := p + side * (width_at(frac) + 16.0)
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
	# --- Alpii (#223) ---------------------------------------------------------
	#
	# Kitul alpin (#226) e INTEGRAL pe atlasul de paleta — vezi antetul lui
	# build_alpine_buildings.py. Deci NICIUNA dintre intrarile de mai jos n-are
	# "classes": culoarea vine din sloturi, iar a le da texturi de clasa ar
	# insemna sa re-exportam GLB-uri care sunt deja corecte, ca sa castigam un
	# detaliu pe care ceata il inghite oricum la 90 m.
	#
	# Biserica: 14 m cu tot cu turla, cel mai inalt lucru construit din sat si
	# reperul lui de franare. Sta la 11 m — de la 5 m turla iese din cadru si
	# reperul devine un zid alb (aceeasi lectie ca la ecranul de drive-in).
	13: {"path": "res://assets/models/buildings/alpine_church.glb",
		"gap": 11.0, "col": "cyl", "radius": 2.2, "spin": false},
	# Chalet-urile: cutie, nu cilindru. Sunt dreptunghiulare si LATE (14.1 x
	# 11.1 m cel mare), iar un cilindru in jurul lor ar inghiti curtea.
	14: {"path": "res://assets/models/buildings/mountain_chalet_large.glb",
		"gap": 9.0, "col": "box", "spin": false},
	15: {"path": "res://assets/models/buildings/mountain_chalet_small.glb",
		"gap": 7.5, "col": "box", "spin": false},
	# Statia de telecabina: 14 m lata, se aseaza pe culme. `gap` mic (6 m)
	# fiindca acolo drumul trece pe un umar ingust — la 12 m ar pluti pe panta
	# de dincolo de creasta.
	16: {"path": "res://assets/models/buildings/cable_car_station.glb",
		"gap": 6.0, "col": "box", "spin": false},
	# Pilonul: 18.2 m, cel mai INALT obiect din joc. Raza 0.9 acopera stalpul,
	# nu bratele de sus — vrem sa lovesti piciorul, ca la stalpul GAS.
	17: {"path": "res://assets/models/structures/cable_car_pylon.glb",
		"gap": 8.0, "col": "cyl", "radius": 0.9, "spin": false},
	# Podul peste parau: se TRECE pe langa el, deci fara coliziune proprie —
	# parapetii lui sunt geometrie decorativa langa drum, iar un colizor acolo
	# ar strange soseaua exact unde pista are nevoie de latime.
	18: {"path": "res://assets/models/structures/stream_bridge.glb",
		"gap": 2.0, "col": "none", "spin": false},
	# Indicatorul de drum alpin: reper mic, fara coliziune, ca semnul Route 66.
	19: {"path": "res://assets/models/signs/alpine_signpost.glb",
		"gap": 3.0, "col": "none", "spin": false},
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
	var stand := p + side * (width_at(frac) + float(info["gap"]))
	# Impins lateral daca ar cadea in canal, nu sters: un landmark e asezat DE
	# MANA la o fractie anume (vezi _landmark_spots), deci disparitia lui tacuta
	# ar fi mai rea decat mutarea. Se cauta primul loc pe raza lui care nu mai e
	# apa; daca nici la dublul distantei nu e uscat, atunci chiar se renunta.
	#
	# Fara pasul asta, o cabana declarata la 0.941 pe Alpii ajungea sa pluteasca
	# peste albia paraului de la 0.937 — cota ei venea din ground_y, adica de pe
	# fundul rapei, iar cladirea ramanea in aer deasupra apei.
	if _sampler.channel_mix(stand.x, stand.z) > 0.3:
		var pushed := false
		for step in range(1, 7):
			var probe := p + side * (width_at(frac) + float(info["gap"])
				+ float(step) * 8.0)
			if _sampler.channel_mix(probe.x, probe.z) <= 0.3:
				stand = probe
				pushed = true
				break
		if not pushed:
			root.queue_free()
			return
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
	hose.road_width = width_at(frac) * 2.0
	add_child(hose)
	hose.global_position = baked[idx]
	hose.global_basis = Basis.looking_at(dir, Vector3.UP) # +X = marginea din dreapta


## Valul care spala soseaua (#106). E acelasi hazard de apa ca furtunul — banda
## uda si taierea de grip vin amandoua din `WaterHazard` — doar ca sursa se misca
## si uda doar cat trece.
func _build_wave_surge(frac: float) -> void:
	var n := baked.size()
	if n == 0:
		return
	# Fara mare in tema, valul nu se construieste DELOC — si spune de ce.
	#
	# Pana la #247 asta nu se putea intampla: valul se declara numai din cod, iar
	# singura pista care il cerea era o insula. De cand se poate pune din editor
	# (`custom_wave_fracs`), un val cerut pe Dunele ar fi iesit o creasta de apa
	# plutind peste desert, la o cota luata din senin — vizibil absurd, dar tacut
	# in cod. Refuzul cu mesaj e conventia pistelor: scurtaturile prost desenate
	# se plang tot in Output, in loc sa se construiasca gresit.
	if not theme_flag("water", false):
		push_warning(("%s: val cerut la fractia %.3f, dar tema '%s' n-are mare "
			+ "— valul se sare (are nevoie de o linie a apei)")
			% [track_name, frac, theme_decor])
		return
	var idx := int(frac * float(n)) % n
	var wave := WaveSurge.new()
	# Directia de mers: perpendicular pe sosea, dinspre larg spre uscat. Nu se
	# alege la zar — pe un dig marea vine de pe o parte anume, iar un val care
	# porneste din interiorul insulei ar fi absurd.
	wave.travel_dir = _side_at(idx)
	wave.sweep = width_at(frac) * 3.2
	wave.road_width = width_at(frac) * 2.0
	# Creasta cat DOUA latimi de drum. Nu e o cifra de gust: la o latime de drum
	# valul citea din masina ca un obiect care pluteste pe asfalt (captura din
	# #106), fiindca ochiul il compara cu marginile soselei. Peste ele, devine ce
	# trebuie sa fie — o portiune de drum acoperita de mare.
	wave.crest_length = width_at(frac) * 4.0
	# Linia apei, ca la tromba: fara ea valul traverseaza orizontal la cota
	# soselei si pluteste in aer cat e in larg. Aceeasi despartire ca peste tot —
	# cotele terenului le stie pista, nu hazardul.
	# Tema are mare (verificat la intrare), deci linia apei exista.
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
	typhoon.sweep = width_at(frac) * 3.2
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


## Betele cu stegulete ale DRUMULUI DE GHEATA (`_ice_ranges`).
##
## Pe gheata nu exista asfalt, borduri sau gard: culoarul e marcat cu bete de
## lemn infipte in gheata la ~20 m, cu un stegulet rosu in varf — asa arata
## un drum de iarna pe Baikal, si asa citeste jucatorul unde e „soseaua" pe o
## placa turcoaz fara margini. Steguletele flutura toate in ACEEASI directie —
## cea a vantului din tema — deci sunt si o informatie de gameplay: vezi de
## unde bate inainte sa te loveasca.
##
## Doua mesh-uri (lemn + rosu), fara coliziune: un bat de 6 cm nu e un
## obstacol, e un reper. Nimic pe pistele fara gheata.
const ICE_FLAG_SPACING_M: float = 20.0

func _build_ice_flags() -> void:
	if _ice_ranges().is_empty() or baked.is_empty():
		return
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cloth := SurfaceTool.new()
	cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wind_v: Variant = theme_flag("wind", null)
	var flutter := Vector3(1, 0, 0)
	if wind_v != null and (wind_v as Vector3).length() > 0.01:
		flutter = (wind_v as Vector3)
		flutter.y = 0.0
		flutter = flutter.normalized()
	var n := baked.size()
	var total := _dists[n]
	var d := 0.0
	var idx := 0
	var count := 0
	while d < total:
		while idx + 1 < _dists.size() and _dists[idx + 1] < d:
			idx += 1
		var i := idx % n
		if not is_ice_at(frac_at(i)) or _road_gap(i) \
				or _in_ice_field(frac_at(i)):
			d += ICE_FLAG_SPACING_M
			continue
		var dir := (baked[(i + 1) % n] - baked[i]).normalized()
		var side := _side_at(i)
		var on_axis := baked[i] + dir * (d - _dists[i])
		for sgn: float in [-1.0, 1.0]:
			var base := on_axis + side * (width_at_index(i) + 1.3) * sgn
			base.y -= 0.12 # infipt in placa, nu plutind la cota drumului
			_emit_ice_flag(wood, cloth, base, side, flutter)
			count += 1
		d += ICE_FLAG_SPACING_M
	if count == 0:
		return
	wood.generate_normals()
	cloth.generate_normals()
	var w := MeshInstance3D.new()
	w.name = "IceFlagSticks"
	w.mesh = wood.commit()
	w.material_override = _flat_material(Palette.color(Palette.WOOD_WEATHERED))
	add_child(w)
	var c := MeshInstance3D.new()
	c.name = "IceFlags"
	c.mesh = cloth.commit()
	c.material_override = _flat_material(Palette.color(Palette.KERB_RED))
	add_child(c)


func _emit_ice_flag(wood: SurfaceTool, cloth: SurfaceTool, base: Vector3,
		side: Vector3, flutter: Vector3) -> void:
	const H := 1.45
	const R := 0.035
	# Batul: prisma cu 4 fete (fara capace — nu se vad).
	var ax := side * R
	var az := side.cross(Vector3.UP).normalized() * R
	var top := base + Vector3.UP * H
	var corners := [base + ax + az, base - ax + az, base - ax - az, base + ax - az]
	for k in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		var au := a + Vector3.UP * H
		var bu := b + Vector3.UP * H
		wood.add_vertex(a); wood.add_vertex(b); wood.add_vertex(au)
		wood.add_vertex(au); wood.add_vertex(b); wood.add_vertex(bu)
	# Steguletul: triunghi care pleaca din varf pe directia vantului.
	var tip := top + flutter * 0.42
	var low := top - Vector3.UP * 0.26
	cloth.add_vertex(top); cloth.add_vertex(tip); cloth.add_vertex(low)
	cloth.add_vertex(top); cloth.add_vertex(low); cloth.add_vertex(tip)


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
			var edge := baked[i] + _side_at(i) * width_at_index(i) * side_sign
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(edge.x, edge.z), loop_poly)
			if exterior or edge.y > 1.0:
				continue # acolo sunt pereti; stalpii marcheaza doar golurile
			if _road_gap(i) or _road_ice(i) or _bridge_mix(i) > 0.05:
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
				* (width_at_index(i) + CHEVRON_GAP) * out_sign * side_mult
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
		var spot := baked[idx] + _side_at(idx) * (width_at_index(idx) + FENCE_GAP) * side_sign
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

## Calea GLB-ului de poarta pentru pista asta, dupa toate suprascrierile:
## intai ce cere pista, apoi ce cere tema, apoi poarta implicita.
func _gate_model_path() -> String:
	if not gate_model.is_empty():
		return _resolve_uid(gate_model)
	return _resolve_uid(String(theme_flag("gate_model", DEFAULT_GATE_MODEL)))


## Traduce un "uid://..." in calea "res://..." pe care o are in spate.
##
## Butonul de fisier din Inspector scrie UID, nu cale (asa a iesit Baikal cu
## `uid://blx1lq0lx0dml` in loc de calea GLB-ului). Ambele incarca la fel, dar
## restul codului COMPARA si verifica existenta pe cale — cu un UID, verificarea
## de mai jos ar fi picat pe modelul implicit desi assetul era acolo. Se
## normalizeaza o data, in punctul in care intra in sistem.
static func _resolve_uid(path: String) -> String:
	if not path.begins_with("uid://"):
		return path
	var id := ResourceUID.text_to_id(path)
	if id == ResourceUID.INVALID_ID or not ResourceUID.has_id(id):
		return path
	return ResourceUID.get_id_path(id)


func _build_start_gate() -> void:
	# Poarta de start din Blender, scalata pe latimea pistei; picioarele
	# au coliziune. Fallback pe stalpii procedurali daca lipseste modelul.
	#
	# Era o arcada de jucarie din tema abandonata "lada de nisip", pe TOATE
	# pistele, si primul lucru pe care il vezi la countdown.
	var gate_path := _gate_model_path()
	if gate_path == "none":
		return
	if not gate_path.is_empty() and not ResourceLoader.exists(gate_path):
		# Un GLB scris gresit in Inspector nu are voie sa lase pista fara poarta
		# in tacere: se vede in Output si se cade pe cea implicita.
		push_warning("Poarta de start lipseste: %s — se foloseste cea implicita."
			% gate_path)
		gate_path = DEFAULT_GATE_MODEL
	if ResourceLoader.exists(gate_path):
		var target_width := (width_at_index(0) + 1.2) * 2.0
		var gate := StaticBody3D.new()
		gate.add_to_group("start_gate")
		var model := (load(gate_path) as PackedScene).instantiate() as Node3D
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
		# MINUS start_direction: poarta se uita INAPOI, spre masinile care vin.
		#
		# looking_at intoarce -Z spre directia ceruta, iar contractul assetului e
		# "fata spre +Y in Blender" = tot -Z in Godot. Cu directia de mers, cele
		# doua se compun si fata pleaca IN JOSUL pistei: la countdown vedeai
		# spatele panoului si zabrelele stalpilor inclinate invers.
		gate.global_basis = Basis.looking_at(-start_direction(), Vector3.UP)
		return
	var side := _side_at(0)
	for s in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 6.0, 0.8)
		pillar.mesh = box
		pillar.position = baked[0] + side * (width_at_index(0) + 0.8) * s + Vector3.UP * 3.0
		pillar.material_override = _flat_material(Color(0.9, 0.9, 0.95))
		add_child(pillar)
	var bar := MeshInstance3D.new()
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3((width_at_index(0) + 1.2) * 2.0, 0.7, 0.9)
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


## Plafonul de viteza al benzii, ca fractie (1 = neatins). Ruta 0 = 1.
func route_speed_factor(route: int) -> float:
	var r := route_at(route)
	return 1.0 if r == null or route == 0 else r.speed_factor


## Culoarea prafului ridicat de pe o banda SECUNDARA: pamantul ei, nu solul.
func route_dust_color(route: int) -> Color:
	var r := route_at(route)
	if r == null or route == 0:
		return road_dust_color()
	return _branch_dirt_color(r)


## Portiunile UDE de pe traseul principal: (frac_start, frac_end).
##
## Pana la #246, „ud" exista doar ca proprietate a unei SCURTATURI
## (`TrackBranch.wet`) — adica se putea uda un ocol intreg, dar nu 80 de metri
## de drum principal. Asta lasa pe dinafara chiar cazul interesant: o portiune
## umeda pe linia pe care oricum mergi, care iti schimba traiectoria si decizia
## de turbo fara sa-ti ofere o ruta alternativa.
##
## Intervale, nu fractii punctuale, si acelasi tipar ca `_gorge_ranges()`: udul
## e o STARE a drumului pe o distanta, nu un obiect asezat undeva. De aceea nu
## intra nici in [HazardMarker] — vezi nota din antetul lui despre ce se
## declara ca nod si ce nu.
##
## Un interval poate trece peste linia de start (ex. 0.95 -> 0.05): se trateaza
## ca doua bucati, ca la sectoarele de latime.
func _wet_ranges() -> Array[Vector2]:
	return []


## Cat de alunecos e udul pe pista asta. Vezi `Car.SLIP_GRIP_WET`.
##
## In tema, nu constanta in cod, fiindca „ud" inseamna altceva pe o sosea de
## munte decat pe un dig batut de valuri. 0 = implicitul masinii.
func wet_grip() -> float:
	return float(theme_flag("wet_grip", 0.0))


## Cat de mult se intuneca asfaltul la fractia asta, ca factor multiplicativ
## (1.0 = neatins). Vezi `_build_road`.
##
## Marginile se sting NETED, pe `WET_FADE`, dintr-un motiv practic: o trecere
## brusca ar desena o dunga transversala perfect dreapta peste sosea — exact
## tiparul de „prag poligonal" pe care restul generatorului il evita peste tot
## (vezi trecerea uscat -> fund de mare din sampler).
func _wet_shade(frac: float) -> Color:
	var segs := _wet_ranges()
	if segs.is_empty():
		return Color.WHITE
	var f := fposmod(frac, 1.0)
	var best := 0.0
	for seg in segs:
		best = maxf(best, _wet_weight(f, seg))
	if best <= 0.0:
		return Color.WHITE
	# Asfaltul ud e mai inchis SI mai rece (apa trage spre albastru-cenusiu).
	var dark := lerpf(1.0, WET_DARKEN, best)
	return Color(dark, dark, lerpf(1.0, WET_DARKEN + 0.06, best))


## Cat de „in interval" e fractia, cu marginile estompate. 0..1.
func _wet_weight(f: float, seg: Vector2) -> float:
	var d := _wet_distance_inside(f, seg)
	if d <= 0.0:
		return 0.0
	return clampf(d / WET_FADE, 0.0, 1.0)


## Cat de departe de cel mai apropiat capat al intervalului se afla fractia,
## masurat pe interior, in fractii de tur. Negativ (0) daca e in afara.
func _wet_distance_inside(f: float, seg: Vector2) -> float:
	var inside := false
	if seg.x <= seg.y:
		inside = f >= seg.x and f <= seg.y
	else:
		inside = f >= seg.x or f <= seg.y # trece peste linia de start
	if not inside:
		return 0.0
	var to_start := fposmod(f - seg.x, 1.0)
	var to_end := fposmod(seg.y - f, 1.0)
	return minf(to_start, to_end)


## E uda soseaua principala la fractia asta?
##
## Se intreaba pe FRACTIE, nu pe indice de punct copt: intervalele se declara in
## fractii ca sa supravietuiasca unei modificari de traseu, exact ca restul
## reperelor.
func is_wet_at(frac: float) -> bool:
	var f := fposmod(frac, 1.0)
	for seg in _wet_ranges():
		if seg.x <= seg.y:
			if f >= seg.x and f <= seg.y:
				return true
		# Interval care trece peste linia de start.
		elif f >= seg.x or f <= seg.y:
			return true
	return false


## Portiunile de GHEATA de pe traseul principal: (frac_start, frac_end).
##
## Sora udului (`_wet_ranges`), cu doua diferente care conteaza amandoua:
##
## 1. Grip-ul e MULT mai jos (vezi `ice_grip`, ~1.5 fata de 3.6 la ud): pe ud
##    aluneci dar tii linia; pe gheata drift-ul devine modul principal de
##    condus, nu unealta de viraj. Asta e chiar promisiunea pistei Baikal
##    (docs/track_briefs/baikal.md §0).
## 2. Nu e o STARE a asfaltului, e ALTA SUPRAFATA: pe interval soseaua se
##    construieste ca banda de gheata (material propriu, fara linie de mijloc,
##    borduri, umeri sau urme de cauciuc — vezi `_road_ice`), iar culoarul
##    e marcat cu bete cu stegulete, ca un drum de gheata adevarat.
##
## Un interval poate trece peste linia de start, ca la ud.
func _ice_ranges() -> Array[Vector2]:
	return []


## Intervalele de suprafata AFANATA de pe traseul principal (cenusa, nisip
## negru adanc). Acelasi tipar ca `_ice_ranges`, si dinadins: e acelasi fel de
## lucru — o portiune pe care grip-ul e altul — deci merita acelasi mecanism,
## nu inca unul care s-ar tuna separat.
##
## Diferenta fata de gheata e doar de intensitate: gheata e sub apa ca grip
## (SLIP_GRIP_ICE), afanatul sta intre asfalt si ud.
func _loose_ranges() -> Array[Vector2]:
	return []


## Cat de alunecoasa e gheata pe pista asta. Reper: asfalt 8, ud 3.6, drift 2.
## In tema, ca si `wet_grip`; 0 = implicitul din Car.SLIP_GRIP_ICE.
func ice_grip() -> float:
	return float(theme_flag("ice_grip", 0.0))


func is_ice_at(frac: float) -> bool:
	return _frac_in_ranges(frac, _ice_ranges())


## Cat de putin tine cenusa / nisipul adanc. Reper: asfalt 8, ud 3.6, drift 2.
## Brief-ul Stromboli cere 0.85x pe cenusa, adica ~6.8 pe scara asta.
## 0 = nu se schimba nimic (implicitul masinii).
func loose_grip() -> float:
	return float(theme_flag("loose_grip", 0.0))


func is_loose_at(frac: float) -> bool:
	return _frac_in_ranges(frac, _loose_ranges())


## Mai e practicabila banda secundara cu indexul dat?
##
## Implicit DA — pistele care n-au nimic care sa inchida o banda nu simt
## nimic. Pe Stromboli raspunde `LavaFlowHazard`: limba creste tur de tur si
## de la stadiul 3 ruta scurta e zid.
##
## Intrebarea o pune AIController la fiecare cadru, nu o data pe cursa: o
## banda se poate inchide IN TIMPUL cursei, si un AI care a decis la turul 1
## ca merge pe scurta ar intra in lava la turul 3.
func branch_is_open(index: int) -> bool:
	for child in get_children():
		if child is LavaFlowHazard:
			var lf := child as LavaFlowHazard
			if lf.branch_index == index:
				return lf.shortcut_open()
	return true


## Fractia cade intr-unul din intervale? Intervalele au voie sa treaca peste
## linia de start (seg.x > seg.y), de-asta nu e o simpla comparatie.
##
## Scos in comun fiindca gheata si afanatul faceau exact aceeasi bucla; a
## treia suprafata pe interval ar fi copiat-o a treia oara.
func _frac_in_ranges(frac: float, ranges: Array[Vector2]) -> bool:
	var f := fposmod(frac, 1.0)
	for seg in ranges:
		if seg.x <= seg.y:
			if f >= seg.x and f <= seg.y:
				return true
		elif f >= seg.x or f <= seg.y:
			return true
	return false


## VANTUL: acceleratie (m/s^2) aplicata masinii la fractia data.
##
## Vine din tema (`wind`, un Vector3 in coordonate de lume) si sufla doar pe
## portiunile de gheata — pe mal il opresc casele, padurea, faleza. Rafalele
## sunt un zgomot lent peste valoarea de baza (`wind_gust`, fractie 0..1), cu
## FAZA din pozitia pe tur, ca doua masini din acelasi loc sa simta aceeasi
## rafala. Zero pe orice pista fara vant declarat, deci nimic nu se schimba.
func wind_at(frac: float, time_s: float) -> Vector3:
	var base: Variant = theme_flag("wind", null)
	if base == null or not is_ice_at(frac):
		return Vector3.ZERO
	var w: Vector3 = base
	var gust := float(theme_flag("wind_gust", 0.0))
	if gust > 0.0:
		var g := sin(time_s * 0.7 + frac * 40.0) * 0.6 			+ sin(time_s * 1.9 + frac * 13.0) * 0.4
		w *= 1.0 + gust * g
	return w


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

## Pozitia unui punct in SPATIUL BENZII buclei principale: (metri de-a lungul
## soselei, metri lateral de ax, cu semn — pozitiv spre dreapta sensului).
## Proiectie pe segmentul de la indexul dat, deci ieftina si fara cautare:
## apelantul aduce indexul pe care oricum il intretine (Car.road_index).
## E exact spatiul in care sunt intinse UV-urile soselei (_build_road), deci
## si cel in care scrie masca de uzura.
func road_coords(index: int, pos: Vector3) -> Vector2:
	var n := baked.size()
	if n < 2:
		return Vector2.ZERO
	var i := ((index % n) + n) % n
	var j := (i + 1) % n
	var a := baked[i]
	var seg := baked[j] - a
	var seg_len := seg.length()
	var t := 0.0
	if seg_len > 0.001:
		t = clampf((pos - a).dot(seg) / (seg_len * seg_len), 0.0, 1.0)
	return Vector2(_dists[i] + seg_len * t, (pos - a).dot(_side_at(i)))

## Depune uzura in masca drumului de zapada, la pozitia rotii date in lume.
## Pe pistele fara foaie de uzura si in afara soselei nu face nimic — masca
## acopera doar carosabilul, iar o roata pe camp isi lasa urma prin SandTrail.
func stamp_wear(index: int, pos: Vector3, strength: float = 1.0) -> void:
	if _road_wear == null:
		return
	var rc := road_coords(index, pos)
	if absf(rc.y) > width_at_index(index) + 0.5:
		return
	_road_wear.stamp(rc.x, rc.y, strength)

## Esti pe asfalt, sau pe iarba lenta?
##
## Cea mai importanta intrebare de latime din joc: de ea atarna penalizarea de
## offroad (45% viteza), repunerea si anti-blocajul AI-ului. Pe o pista cu
## profil, marginea trebuie sa fie cea LOCALA — altfel o portiune largita ar
## penaliza masina care merge pe asfaltul ei propriu, iar una stramta ar lasa-o
## sa taie prin iarba la viteza plina.
func is_on_road(index: int, pos: Vector3, route: int = 0) -> bool:
	var r := route_at(route)
	if r == null:
		return false
	if route != 0 or _width_profile().is_empty():
		return r.is_on_road(index, pos)
	return r.lateral_distance(index, pos) <= width_at_index(index) + 0.5

func lookahead_point(index: int, ahead_m: float, lateral_frac: float,
		route: int = 0) -> Vector3:
	var r := route_at(route)
	if r == null:
		return Vector3.ZERO
	# Latimea de la indexul TINTA, nu de la cel curent — si doar pe bucla
	# principala, fiindca profilul e declarat in fractii de tur. O scurtatura
	# isi pastreaza latimea ei (vezi TrackRoute.half_width).
	var hw := -1.0
	if route == 0 and not _width_profile().is_empty():
		var steps := int(ahead_m / maxf(curve.bake_interval, 0.001))
		hw = width_at_index(index + steps)
	return r.lookahead_point(index, ahead_m, lateral_frac, curve.bake_interval, hw)


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
		# Un ocol de pedeapsa nu se momeste niciodata: se ia doar cand banda
		# directa e inchisa, si atunci decide ceasul hazardului prin
		# `AiController._span_line`. Vezi `TrackRoute.detour`.
		if b.detour:
			continue
		if pos.distance_to(b.baked[0]) > BRANCH_LURE_RANGE:
			continue
		var bidx := b.closest_index_global(pos)
		# Acelasi test de etaj ca la `resolve_route`, si din acelasi motiv:
		# raza de momeala e 3D, dar 70 m acopera doua etaje de spirala.
		if b.is_other_level(bidx, pos):
			continue
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
			# [b]Si la ACELASI ETAJ.[/b] `lateral_distance` e 2D prin proiect
			# (o banda urca, deci cota difera de la un capat la altul), iar
			# raza de comutare e 3D — dar 45 m de raza acopera doua etaje ale
			# unei spirale. Rampa de serviciu a pasajului rotativ sta la y 39
			# fix peste cheiul de la y 7, si masurat pe ProbeRace masinile de
			# pe chei comutau pe ea: 2-3 repuneri pe cursa la frac 0.50, cu
			# masina „pe o banda" aflata la 32 m deasupra ei. Memoria
			# `pista-peste-pista` — de fiecare data cand pista trece peste ea
			# insasi, testul care lipseste e cel vertical.
			if b.is_other_level(bidx, pos):
				continue
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
		var side := (-1.0 if i % 2 == 0 else 1.0) * width_at_index(idx) * 0.4
		var pos := baked[idx] + _side_at(idx) * side + Vector3.UP * 0.5
		var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
		result.append(Transform3D(Basis.looking_at(dir, Vector3.UP), pos))
	return result
