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

## Pana unde arunca soarele umbre. Peste, preia ceata (depth 90->250), deci
## lipsa lor nu se vede. O singura cascada pana aici = configuratia cea mai
## ieftina care da totusi contact real cu solul.
const SHADOW_DISTANCE: float = 90.0

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
			# Recalibrat de doua ori: stratul de detaliu se INMULTESTE peste albedo
			# (medie 0.89), iar soarele a coborat de la 48° la 42° si s-a mutat
			# lateral, deci nisipul primeste mai putina lumina directa. Cumulate, au
			# dus nisipul de la #D8A86A la #BD955E. 0.75 -> 1.42 il aduce inapoi.
			#
			# Daca schimbi detaliul SAU unghiul soarelui, REIA masuratoarea:
			#   godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.2 --size=40
			# si compara nisipul insorit (coltul liber al imaginii) cu #D8A86A.
			"sun_energy": 0.8,
			"exposure": 1.42,
			# Ambient din CULOARE, nu din cer — vezi _build_environment.
			"ambient_color": Color.html("E2B77A"),
			"ambient_energy": 0.22,
			"fog_depth": true, # 90 -> 250 m, style_bible §6
			"horizon_model": "res://assets/models/butte.glb",
			"walls": false,   # rolul lor il preiau falezele de canion
			"cliffs": true,
			"decor": "bands",
			"props": "desert",
			"hazard_model": "res://assets/models/boulder_roller.glb",
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
			"horizon_model": "", # deocamdata rezerva; insulele de fundal vin la etapa 5
			"walls": true,       # doar pe sectiunile inaltate — regula din sampler
			"cliffs": false,     # promontoriul e zid gusuku, nu faleza de canion
			"decor": "bands",    # densitatea din style_bible §7, ca pe desert
			"props": "island",   # ...dar palmieri si bazalt, nu cactusi
			"water": true,       # singura tema cu mare (vezi _build_water)
			# Cat de adanc cade terenul dincolo de coridorul pistei. Trebuie sa
			# duca adancimea DECIS peste SEA_NEAR_DEPTH, altfel grila fina de tarm
			# se emite pe toata marea. Vezi TrackSideSampler.ground_y.
			"seabed_drop": 26.0,
			"hazard_model": "",  # wave_surge se ataseaza separat, pe fractii
			"dust_color": null,
		},
	}
	return _themes_cache


## Citeste un camp din tema curenta, cu valoare implicita daca lipseste.
##
## Initializarea e LENESA si intentionat NU trece prin apply_theme. Track02 si
## Track03 nu apeleaza apply_theme niciodata: ele raman pe valorile implicite
## ale variabilelor theme_*, care NU sunt identice cu ramura "forest"
## (cerul implicit e (0.30,0.50,0.80), cel din tema e (0.22,0.48,0.9)).
## Un apply_theme("forest") fortat aici le-ar schimba in tacere aspectul.
## Asa iau doar FLAG-urile de comportament, iar culorile raman ale lor.
func theme_flag(key: String, fallback: Variant = null) -> Variant:
	if _theme.is_empty():
		var all := themes()
		_theme = all.get(theme_decor, all["forest"])
	return _theme.get(key, fallback)


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
	_theme = all[theme]
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

## Fractii unde furtunul de gradina pulseaza apa peste drum.
func _hose_fracs() -> Array[float]:
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

func _ready() -> void:
	rebuild()

## Reconstruieste toata pista (folosit si de editor, la Regenerate).
func rebuild() -> void:
	_mat_cache.clear() # altfel raman materialele temei precedente
	for child in get_children():
		if child is Path3D:
			continue # curba editabila a pistelor custom ramane
		child.free()
	_build_curve()
	# Dupa coacerea curbei (deci si a rutelor), inainte de orice generator care
	# aseaza ceva langa drum: toti citesc sloturi SI cota terenului de aici.
	_sampler = TrackSideSampler.new(baked, _dists, _points(), half_width,
		float(track_name.hash() % 1000) * 0.01, _ravines(),
		theme_flag("seabed_drop", 0.0), _branch_corridor_points())
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
	_build_markers()
	_build_start_gate()
	_build_start_line()
	_build_center_line()
	_build_shoulders()
	_build_kerbs()
	_build_world_decor()
	# Terenul DUPA faleze: le citeste pozitiile ca sa coaca umbra la baza lor.
	# Fara asta, stancile par lipite peste nisip, nu infipte in el.
	_build_terrain()
	# Apa DUPA teren: are nevoie de aceleasi cote ca sa stie unde e tarmul.
	_build_water()
	_build_world_bounds()

## Linia discontinua de mijloc, din geometrie (fara texturi): placute albe
## la fiecare 6.5m de-a lungul curbei.
func _build_center_line() -> void:
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
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	# Elevatie 42°, azimut 315° (din stanga-sus) — style_bible §5.
	#
	# Vechiul (-48, -30) bătea aproape vertical si dinspre spatele camerei, deci
	# umbrele cadeau SUB si IN SPATELE stancilor, unde nu le vede nimeni. La 42°
	# umbra unei faleze de 10m se intinde ~11m pe nisip, transversal pe drum:
	# exact indiciul de volum care lipsea.
	sun.rotation_degrees = Vector3(-42, 135, 0)
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
	rng.seed = track_name.hash() + 1
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
			var picks: Array = ring["picks"]
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
			Palette.apply_world_material(model)
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
	rng.seed = track_name.hash() + 1
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
const TERRAIN_CELL: float = 760.0 / 48.0

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


func _build_terrain() -> void:
	var centroid := _centroid()
	# 1500m si 56 de celule insemnau ~6200 de triunghiuri intinse pe o suprafata
	# din care jumatate nu se vede niciodata: ceata inghite totul la 250m, iar
	# siluetele de la orizont acopera fundalul. La 900m/36 raman ~2600, si nimeni
	# nu observa diferenta din masina.
	# Grila s-a indesit de la 36 la 48 de celule odata cu terenul care urmareste
	# soseaua: pasul de 25 m lasa o cusatura de pana la 3 m la marginea drumului
	# pe pantele de 12%. La 15.8 m cusatura scade sub 1 m, si asta se vede.
	var size := _world_extent()
	var cells := int(round(size / TERRAIN_CELL))
	var step := size / float(cells)
	var origin := centroid - Vector3(size * 0.5, 0, size * 0.5)
	var heights: Array[float] = []
	heights.resize((cells + 1) * (cells + 1))
	for gz in cells + 1:
		for gx in cells + 1:
			# Toata matematica de inaltime traieste in sampler acum — aici doar
			# o citim. Asa terenul, falezele, decorul si landmark-urile nu pot
			# diverge: e literalmente aceeasi functie.
			heights[gz * (cells + 1) + gx] = _sampler.ground_y(
				origin.x + float(gx) * step, origin.z + float(gz) * step)
	# Pozitiile falezelor, pentru umbra coapta de la baza lor.
	var cliff_xz := _cliff_positions()
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
					st.set_color(theme_ground_tint * shade)
					# UV din coordonate de LUME, nu din indexul celulei: asa
					# textura curge continuu peste toata suprafata, fara sa se
					# vada grila de 32x32 in tiparul ei.
					st.set_uv(Vector2(v.x, v.z) * SURFACE_TILING)
					# A doua scara, pentru stratul de detaliu: aceeasi textura,
					# de 15 ori mai lenta. Suprapuse, cele doua rup tiparul de
					# repetitie pe care ochiul il prinde imediat pe suprafete mari.
					st.set_uv2(Vector2(v.x, v.z) * SURFACE_TILING_MACRO)
					st.add_vertex(v)
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
		# A doua trecere cu ACEEASI textura, pe UV2 (scara macro): granulatia
		# deasa da suprafata, petele lente rup repetitia. Terenul are UV2 real
		# (emis mai sus), deci NU are nevoie de triplanar ca prop-urile.
		mat.detail_enabled = true
		mat.detail_albedo = sand_tex
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
## Cu cat sta mai jos cvadrilaterul de larg fata de grila fina.
##
## Sunt doua suprafete la aceeasi cota, deci ar face z-fighting pe toata zona de
## suprapunere. 4 cm le separa fara sa se vada: la nivelul marii, din masina,
## treapta e sub un pixel.
const SEA_FAR_DROP: float = 0.04


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
	if d <= 0.0:
		return foam # varf uscat al unei celule de mal
	if d < SEA_FOAM_DEPTH:
		return foam.lerp(reef, d / SEA_FOAM_DEPTH)
	if d < SEA_REEF_DEPTH:
		return reef
	return reef.lerp(deep, clampf(
		(d - SEA_REEF_DEPTH) / (SEA_NEAR_DEPTH - SEA_REEF_DEPTH), 0.0, 1.0))


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

func _build_road() -> void:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
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
	for i in n:
		var j := (i + 1) % n
		var l0 := baked[i] - _side_at(i) * half_width
		var r0 := baked[i] + _side_at(i) * half_width
		var l1 := baked[j] - _side_at(j) * half_width
		var r1 := baked[j] + _side_at(j) * half_width
		var v0 := _dists[i] / tile
		var v1 := _dists[i + 1] / tile
		top.set_uv(Vector2(-u_half, v0)); top.add_vertex(l0)
		top.set_uv(Vector2(u_half, v0)); top.add_vertex(r0)
		top.set_uv(Vector2(-u_half, v1)); top.add_vertex(l1)
		top.set_uv(Vector2(u_half, v0)); top.add_vertex(r0)
		top.set_uv(Vector2(u_half, v1)); top.add_vertex(r1)
		top.set_uv(Vector2(-u_half, v1)); top.add_vertex(l1)
		var u0 := _dists[i] / side_tile
		var u1 := _dists[i + 1] / side_tile
		sides.set_uv(Vector2(u0, 0)); sides.add_vertex(l0)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(l0 + down)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(l0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1)
		sides.set_uv(Vector2(u1, 1)); sides.add_vertex(l1 + down)
		sides.set_uv(Vector2(u0, 0)); sides.add_vertex(r0)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(r1)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u1, 1)); sides.add_vertex(r1 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(r1)
		sides.set_uv(Vector2(u0, 0)); sides.add_vertex(l0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1 + down)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1 + down)
		sides.set_uv(Vector2(u1, 1)); sides.add_vertex(r1 + down)
	top.generate_normals()
	sides.generate_normals()
	# Asfaltul racoros-inchis face masinile saturate sa "sara" din ecran, iar
	# granulatia de pietris il scoate din senzatia de plastic turnat. Textura e
	# gri si se inmulteste peste culoare, deci nu schimba paleta.
	# UV-urile soselei sunt patrate (3.5 m pe ambele axe), asa ca pietrisul arata
	# a pietris si nu a dungi intinse.
	_add_mesh_with_collision(top.commit(), Color(0.23, 0.24, 0.3),
		_tex("res://assets/textures/surface_asphalt.png"))
	_add_mesh_with_collision(sides.commit(), theme_hill_color.darkened(0.2))

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
		for i in n:
			var j := (i + 1) % n
			if _near_junction(i, junctions, n):
				continue
			var b0 := baked[i] + _side_at(i) * half_width * side_sign
			var b1 := baked[j] + _side_at(j) * half_width * side_sign
			var mid := (b0 + b1) * 0.5
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(mid.x, mid.z), loop_poly)
			var elevated := mid.y > 1.0
			if not exterior and not elevated:
				continue
			var t0 := b0 + Vector3.UP * WALL_HEIGHT
			var t1 := b1 + Vector3.UP * WALL_HEIGHT
			st.add_vertex(b0); st.add_vertex(t0); st.add_vertex(b1)
			st.add_vertex(t0); st.add_vertex(t1); st.add_vertex(b1)
			emitted = true
		if emitted:
			st.generate_normals()
			_add_mesh_with_collision(st.commit(), Color(0.9, 0.25, 0.2))

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
		ball.model_scale = 0.52 # diametru 5m in model -> 2.6m in joc
		# Doar intentia "se rostogoleste"; raza reala o ia din model.
		ball.roll_radius = 1.0
		# Noi ii cerem maturarea maxima; el isi taie cursa cat sa nu iasa din
		# sosea pe latimea ASTA de drum (vezi SlidingHazard._clamp_travel).
		ball.road_half_width = half_width
		ball.phase = fposmod(frac * 3.7, 1.0) # doua obstacole nu bat la unison
		add_child(ball)
		ball.center = p
		ball.travel = side * half_width * 0.9
		ball.global_position = p
	elif ResourceLoader.exists("res://assets/models/rusted_digger.glb"):
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
##   - sina se opreste inainte de alta bucla a pistei, altfel un tren de ~33 m
##     intra pe soseaua vecina pe o pista care se auto-intersecteaza.
func _build_train(frac: float) -> void:
	var n := baked.size()
	var idx := _calm_index_near(int(frac * float(n)) % n, 40.0)
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var rail := dir.cross(Vector3.UP).normalized()
	var train := TrainHazard.new()
	train.road_half_width = half_width
	train.half_rail = _rail_reach(p, rail, 90.0, 25.0)
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
## MIN_RAIL nu e arbitrar: garnitura are ~33 m, deci sub atat trenul n-ar avea de
## unde sa intre in cadru. Sina e doar geometrie, fara coliziune — daca trece pe
## langa alta bucla a pistei nu strica nimic, doar arata ciudat.
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
	# plasa nu se declanseaza niciodata. Prinde Track04 si orice pista viitoare
	# unde cineva adauga un fly-off si uita rapa.
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
func _flat_material(color: Color, texture: Texture2D = null) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(true),
		texture.resource_path if texture != null else ""]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if texture != null:
		mat.albedo_texture = texture
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache[key] = mat
	return mat


func _add_mesh_with_collision(mesh: ArrayMesh, color: Color,
		texture: Texture2D = null) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _flat_material(color, texture)
	add_child(inst)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var tri := mesh.create_trimesh_shape() as ConcavePolygonShape3D
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
## Latimea benzii de praf dintre asfalt si nisip.
const SHOULDER_WIDTH: float = 1.3


## Umarul soselei: o banda de praf de o parte si de alta a asfaltului.
##
## In imaginile de referinta asfaltul nu atinge NICIODATA nisipul direct — exista
## mereu o fasie de praf batatorit intre ele. Fara ea, marginea drumului e o
## taietura brusca intre doua culori, si citeste ca decupaj de hartie, nu ca drum
## construit de cineva prin desert.
##
## Doua mesh-uri (unul per latura ar fi fost inutil — culoarea e aceeasi), asezate
## sub nivelul asfaltului cu 2cm ca sa nu produca z-fighting.
func _build_shoulders() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var drop := Vector3.UP * -0.02
	var tile := 3.5
	for i in n:
		var j := (i + 1) % n
		var s0 := _side_at(i)
		var s1 := _side_at(j)
		var v0 := _dists[i] / tile
		var v1 := _dists[i + 1] / tile
		for side_sign: float in [-1.0, 1.0]:
			var inner0 := baked[i] + s0 * half_width * side_sign + drop
			var inner1 := baked[j] + s1 * half_width * side_sign + drop
			var outer0 := inner0 + s0 * SHOULDER_WIDTH * side_sign
			var outer1 := inner1 + s1 * SHOULDER_WIDTH * side_sign
			# Winding-ul se inverseaza cu latura, altfel una din benzi iese cu
			# fata in jos si dispare la cull.
			if side_sign < 0.0:
				st.set_uv(Vector2(0, v0)); st.add_vertex(inner0)
				st.set_uv(Vector2(1, v0)); st.add_vertex(outer0)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
				st.set_uv(Vector2(1, v0)); st.add_vertex(outer0)
				st.set_uv(Vector2(1, v1)); st.add_vertex(outer1)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
			else:
				st.set_uv(Vector2(0, v0)); st.add_vertex(inner0)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
				st.set_uv(Vector2(1, v0)); st.add_vertex(outer0)
				st.set_uv(Vector2(1, v0)); st.add_vertex(outer0)
				st.set_uv(Vector2(0, v1)); st.add_vertex(inner1)
				st.set_uv(Vector2(1, v1)); st.add_vertex(outer1)
	st.generate_normals()
	# Praf: intre asfalt si nisip ca valoare, ca sa faca tranzitia, nu un al
	# treilea ton care sa sara in ochi.
	var dust_override: Variant = theme_flag("dust_color")
	var dust: Color = dust_override if dust_override != null \
		else theme_ground_tint.darkened(0.25)
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	inst.material_override = _flat_material(dust,
		_tex("res://assets/textures/surface_sand.png"))
	add_child(inst)


func _build_kerbs() -> void:
	var red := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := SurfaceTool.new()
	white.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var lift := Vector3.UP * 0.04
	var emitted_red := false
	var emitted_white := false
	for i in range(0, n, 2):
		# curbura locala: unghiul dintre directia dinainte si cea de dupa
		var before := (baked[i] - baked[(i - 3 + n) % n]).normalized()
		var after := (baked[(i + 3) % n] - baked[i]).normalized()
		if before.angle_to(after) < 0.08:
			continue
		for side_sign: float in [-1.0, 1.0]:
			var e0 := baked[i] + _side_at(i) * half_width * side_sign + lift
			var e1 := baked[(i + 2) % n] + _side_at((i + 2) % n) * half_width * side_sign + lift
			var in0 := e0 - _side_at(i) * 0.9 * side_sign
			var in1 := e1 - _side_at((i + 2) % n) * 0.9 * side_sign
			var st := red if (i / 2) % 2 == 0 else white
			st.add_vertex(e0); st.add_vertex(e1); st.add_vertex(in0)
			st.add_vertex(in0); st.add_vertex(e1); st.add_vertex(in1)
			if (i / 2) % 2 == 0:
				emitted_red = true
			else:
				emitted_white = true
	if emitted_red:
		red.generate_normals()
		_add_visual_mesh(red.commit(), Color(0.85, 0.15, 0.1))
	if emitted_white:
		white.generate_normals()
		_add_visual_mesh(white.commit(), Color(0.92, 0.92, 0.92))

## Lumea din jurul soselei: peretii de canion si decorul imprastiat.
##
## Amandoua traiesc in fisiere separate ([TrackCliffs], [TrackDecor]) si cer
## sloturi de la [member _sampler]. Motivul e la fel de mult organizatoric cat
## tehnic: track.gd e fisierul pe care il atinge toata lumea, iar decorul e
## partea care se itereaza cel mai des.
func _build_world_decor() -> void:
	add_child(TrackCliffs.build(_sampler, theme_flag("cliffs", false),
		track_name.hash(), _cliff_clearings()))
	add_child(TrackDecor.build(_sampler, theme_flag("decor", "scatter"),
		track_name.hash(), Callable(self, "_flat_material"),
		theme_flag("props", "desert")))

func _build_excavator(frac: float) -> void:
	const PATH := "res://assets/models/rusted_digger.glb"
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
	const PATH := "res://assets/models/dino_bones.glb"
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
	rng.seed = track_name.hash() + int(frac * 1000.0)
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
	const PATH := "res://assets/models/rock_arch.glb"
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
	Palette.apply_world_material(model)
	var stand := p
	stand.y = _sampler.ground_y(p.x, p.z)
	body.global_position = stand
	# Deschiderea arcadei e pe X-ul modelului, deci privirea se aliniaza cu
	# directia de mers: soseaua trece prin gol, nu pe langa un picior.
	body.global_basis = Basis.looking_at(dir, Vector3.UP)


## Intrare de mina lipita de peretele de faleza, cu sina si vagonet asezate
## separat — de aia sunt trei noduri in GLB si nu unul.
func _build_mine(frac: float, side_sign: float) -> void:
	const PATH := "res://assets/models/mine_portal.glb"
	if not ResourceLoader.exists(PATH):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * side_sign
	var scene := load(PATH) as PackedScene
	var portal := _extract_glb_node(scene, "Portal")
	if portal == null:
		return
	var body := StaticBody3D.new()
	body.add_to_group("mines")
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
	Palette.apply_world_material(portal)
	var stand := p + side * (half_width + 16.0)
	stand.y = _sampler.ground_y(stand.x, stand.z)
	body.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)
	# Sina iese din gura minei spre drum; vagonetul rasturnat langa ea.
	for pair: Array in [["MineRail", 7.0, 0.0], ["MineCart", 5.0, 3.2]]:
		var piece := _extract_glb_node(scene, String(pair[0]))
		if piece == null:
			continue
		var spot := stand - side * float(pair[1]) \
			+ side.cross(Vector3.UP).normalized() * float(pair[2])
		spot.y = _sampler.ground_y(spot.x, spot.z)
		add_child(piece)
		Palette.apply_world_material(piece)
		piece.look_at_from_position(spot, Vector3(p.x, spot.y, p.z), Vector3.UP)

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
	0: {"path": "res://assets/models/water_tower.glb",
		"gap": 10.0, "col": "cyl", "radius": 2.4, "spin": false},
	1: {"path": "res://assets/models/gas_station.glb",
		"gap": 9.0, "col": "box", "spin": false},
	2: {"path": "res://assets/models/windmill.glb",
		"gap": 11.0, "col": "cyl", "radius": 1.6, "spin": true},
	3: {"path": "res://assets/models/route66_sign.glb",
		"gap": 3.5, "col": "none", "spin": false},
	# Ecran de drive-in: 20.6 m lat si 10.8 m inalt, cel mai lat lucru construit
	# de pe pista. Sta departe de sosea nu ca sa nu-l lovesti, ci ca sa incapa in
	# cadru — de la 9 m ai doar tabla in fata.
	4: {"path": "res://assets/models/drive_in_screen.glb",
		"gap": 15.0, "col": "box", "spin": false},
	# Stalpul GAS: 13.7 m, cel mai INALT. Raza mica intentionat — vrem sa lovesti
	# stalpul, nu un cilindru de 1.9 m in jurul unui obiect subtire.
	5: {"path": "res://assets/models/gas_pole_sign.glb",
		"gap": 5.0, "col": "cyl", "radius": 0.55, "spin": false},
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
	root.add_child(model)
	add_child(root)
	# Atlasul comun pe tot subarborele (fara el, GLB-ul iese alb). Moara si-l
	# aplica singura in _ready, dar celelalte prop-uri il primesc aici.
	Palette.apply_world_material(root)
	var stand := p + side * (half_width + float(info["gap"]))
	# Chiar la nivelul solului, nu la cota drumului. Comentariul de aici spunea
	# deja "la nivelul solului", dar terenul nu-l onora: statea la o cota fixa in
	# lume, deci pe portiunile inaltate landmark-ul ramanea suspendat in aer.
	stand.y = _sampler.ground_y(stand.x, stand.z)
	root.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)

func _build_hose(frac: float) -> void:
	const PATH := "res://assets/models/pipe_leak.glb"
	if not ResourceLoader.exists(PATH):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var hose := WaterHose.new()
	# Era un FURTUN DE GRADINA care traversa soseaua intr-un canion de desert.
	# Conducta sparta face acelasi lucru mecanic — banda uda, grip aproape zero —
	# dar apartine peisajului.
	hose.model = _extract_glb_node(load(PATH) as PackedScene, "Pipe_Broken")
	hose.road_width = half_width * 2.0
	add_child(hose)
	hose.global_position = baked[idx]
	hose.global_basis = Basis.looking_at(dir, Vector3.UP) # +X = marginea din dreapta

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
	if not ResourceLoader.exists("res://assets/models/marker_post.glb"):
		return
	var scene := load("res://assets/models/marker_post.glb") as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = track_name.hash() + 7 # alt sir decat decorul si orizontul
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
	if ResourceLoader.exists("res://assets/models/start_gate.glb"):
		var target_width := (half_width + 1.2) * 2.0
		var gate := StaticBody3D.new()
		gate.add_to_group("start_gate")
		var model := (load("res://assets/models/start_gate.glb") as PackedScene) \
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
