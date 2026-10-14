class_name Palette
extends RefCounted
## Paleta UNICA a lumii (directia "diorama stilizata").
##
## Toate prop-urile impart o singura textura — [b]assets/textures/palette_atlas.png[/b]
## (512x512: 32 de sloturi a cate 16px latime). Un obiect nu are textura proprie:
## UV-urile lui arata spre centrul slotului cu materialul dorit. Fiecare slot e
## un patch texturat (nisip granulat, roca stratificata, lemn cu fibra), nu un
## patrat de culoare uniforma — vezi [code]tools/generate_palette_atlas.gd[/code].
## Consecinte:
##   - un singur material pentru toata lumea -> foarte putine draw call-uri (mobil)
##   - coerenta de paleta garantata prin constructie
##   - umbrele proprii vin din ambient occlusion copt in VERTEX COLORS, nu din texturi
##
## Slotul e sursa de adevar comuna cu scripturile Blender: acolo se seteaza UV-ul
## pe [code]Palette.uv(slot)[/code], aici se citeste aceeasi valoare.

const ATLAS_PATH: String = "res://assets/textures/palette_atlas.png"
## Stratul de detaliu de suprafata, aplicat triplanar peste toata lumea.
const DETAIL_PATH: String = "res://assets/textures/detail_rock.png"
## Cat de tare bate detaliul pe fiecare slot (alfa per slot, 32x1).
const DETAIL_MASK_PATH: String = "res://assets/textures/detail_mask.png"
## Scara detaliului: 1 / 0.35 = o repetitie la 2.86 m.
const DETAIL_SCALE: float = 0.35
## Trim sheet-ul COLOR al clasei de roca (vezi rock_material()).
const TRIM_ROCK_PATH: String = "res://assets/textures/trim_rock.png"
## O repetitie la 5 m: cele 7 benzi din textura cad la ~0.71 m — intervalul de
## strat cerut de style_bible §3.
const TRIM_ROCK_SCALE: float = 0.2
const SLOTS: int = 32

# --- Mediu (0..13) ---
const SAND_LIGHT: int = 0     # nisip in soare, varfuri de faleza
const SAND_MID: int = 1       # majoritatea terenului
const SAND_SHADOW: int = 2    # nisip umbrit, tenta de AO
const ROCK_LIGHT: int = 3     # fete de stanca
const ROCK_DARK: int = 4      # interior de faleza, crapaturi
const ASPHALT: int = 5        # sosea — cea mai INCHISA suprafata continua
const ASPHALT_EDGE: int = 6   # margini tocite
const KERB_RED: int = 7       # borduri, marcaje de avertizare
const CONCRETE: int = 8       # pod, fundatii
const WOOD_WEATHERED: int = 9 # scanduri, garduri
const RUST_METAL: int = 10    # butoaie, moara, turn de apa
const PAINTED_METAL: int = 11 # containere, ornamente
const CACTUS_GREEN: int = 12  # cactusi, tufe
const DRY_VEGETATION: int = 13 # smocuri de iarba uscata

# --- Accente masini (14..16): NU se folosesc in decor, ca masinile sa "sara" ---
const CAR_RED: int = 14
const CAR_BLUE: int = 15
const CAR_YELLOW: int = 16

# --- Mediu insular (17..23), pentru pista Okinawa ---
#
# Sloturile 0..13 sunt acordate pe desert si nu acopera o insula de recif. Le
# lasam neatinse (orice GLB deja construit le foloseste) si ocupam din rezerva.
# Nu se lateste atlasul: 32 de sloturi erau deja alocate, doar 17 folosite.
#
# Ce NU a primit slot nou, ca sa nu risipim rezerva: calcarul Ryukyu foloseste
# CONCRETE (8), barcile sabani si stalpii de debarcader folosesc WOOD_WEATHERED
# (9), bordurile raman KERB_RED (7).
const REEF_SHALLOW: int = 17    # apa peste recif, turcoaz
const SEA_DEEP: int = 18        # larg
const CORAL_SAND: int = 19      # nisip coraligen alb-crem (SAND_LIGHT e prea galben)
const VOLCANIC_BLACK: int = 20  # bazalt (ROCK_DARK e maro, nu negru)
const TROPICAL_GREEN: int = 21  # vegetatie subtropicala (CACTUS_GREEN e oliv sters)
const FOAM_WHITE: int = 22      # creste de val, spuma la tarm
const TILE_TERRACOTTA: int = 23 # olane rosii

## --- Baikal (Track10): iarna pe lacul inghetat ------------------------------
##
## Sase sloturi din rezerva 24..31, nu opt cate propunea brief-ul pistei. Doua
## au picat la integrare, si motivul e acelasi in ambele cazuri: un slot e o
## CULOARE, nu o eticheta semantica.
##
##   - `snow_white`, propus la 27, e in cifre acelasi alb-albastrui ca
##     FOAM_WHITE (22, #E9F2F0). Un slot nou l-ar fi duplicat, cu costul unei
##     culori din rezerva si al unei a doua surse de adevar pentru zapada.
##     Brief-ul lasa el insusi portita ("sau reuse 22").
##   - `ribbon_accents`, propus la 31, cerea CINCI culori intr-un singur slot,
##     ceea ce atlasul nu poate reprezenta (un slot = o banda de o culoare).
##     Panglicile serge sunt insa accentele saturate ale pistei, deci nu se pot
##     sterge: iau sloturile de masina, singurele culori pure din paleta —
##     CAR_BLUE (15), FOAM_WHITE (22), CAR_YELLOW (16), CAR_RED (14) si
##     TROPICAL_GREEN (21). E o abatere CONSTIENTA de la style_bible §1
##     ("14..16 nu se folosesc in decor"): regula exista ca masinile sa ramana
##     cele mai saturate obiecte din cadru, iar panglicile sunt fasii de
##     60-90 cm pe 13 stalpi — sub un metru patrat in total, la marginea pistei,
##     si semnaleaza VANTUL, care aici e mecanica, nu ornament. Daca la primul
##     tur de mana concureaza vizual cu masinile, coboara pe variante desaturate.
const ICE_TURQUOISE: int = 24  # gheata in lumina, fata de sus
const ICE_DEEP: int = 25       # gheata in adancime, sub torosuri si in crapaturi
const ICE_CRACK: int = 26      # crapaturi, apa neagra dintre placi
const LARCH_RUST: int = 27     # larice iarna, ruginiu (era snow_white in brief)
const LOG_DARK: int = 28       # barne de casa siberiana, aproape negre
const MARBLE_GREY: int = 29    # marmura Stancii Samanului, faleza Olkhon

## --- Stromboli (Track11): insula vulcanica -----------------------------------
##
## UN singur slot din rezerva, decizia din brief (docs/track_briefs/stromboli.md
## §4, scrisa cu lectia Baikal in fata: un slot e o CULOARE, nu o eticheta).
## Lava, crapaturile bombelor si gurile craterului sunt SEMNALUL pistei —
## singura sursa de portocaliu saturat din decor, cu acelasi statut de exceptie
## ca panglicile serge. Emisivul nu vine din slot (atlasul e albedo): vine din
## materialul de clasa partajat al lavei, la integrarea hazardului. Restul
## paletei Stromboli reutilizeaza: VOLCANIC_BLACK 20, FOAM_WHITE 22 (var),
## REEF_SHALLOW/SEA_DEEP 17/18, TROPICAL_GREEN 21, MARBLE_GREY 29 (cenusa).
const LAVA_ORANGE: int = 30    # lava incandescenta; accent, nu suprafata mare

## Roz de flamingo, ultimul slot din rezerva (Serengeti, POI G).
##
## 31 a fost pana acum marcajul de eroare de UV: NEDEFINIT in HEX, deci
## generatorul de atlas ii dadea magenta pur, ca o greseala de UV sa sara in
## ochi. Kitul Serengeti l-a exportat totusi ca slot de penaj — comentariul din
## tools/blender/build_serengeti_plants.py:49 spunea ca "31 e NEON_PINK
## (Chongqing)", ceea ce e fals: Chongqing a declarat slotul consumat
## (track.gd:1295) dar a folosit pana la urma RUST_METAL pentru Yangtze si nu
## l-a repictat NICIODATA in atlas. Masurat pe atlasul comis: slotul 31 era
## (255, 0, 255).
##
## Consecinta in cadru: penajul magenta inmultit cu sun_color (1.0, 0.90, 0.72)
## da VERMILION, si asta a costat patru runde de critica. Solutia de ocolire
## din rundele 1-4 (penajul remapat pe CAR_RED 14) a mutat pasarile de la
## magenta la rosu-caramida — masurat pe captura hero: sat 0.66 la hue +16.3,
## fata de sat 0.51 la hue +3.9 in diorama de referinta. Un inel de flamingi
## nu se putea repara in remap fiindca atlasul chiar NU avea niciun slot in
## familia rozului (masurate toate 31: niciunul cu hue 300-30 sub sat 0.55).
##
## Valoarea e aleasa PRIN COMPENSARE INVERSA, nu la ochi: lumina calda a temei
## roteste nuanta cu ~+19 grade si urca saturatia HLS cu ~0.10, deci sursa e
## un roz RECE si palid (#D2A0BE, hue -28, sat 0.46) care ajunge pe ecran la
## hue +6 / sat 0.53 — banda referintei. Acelasi tipar ca la apa de noapte din
## Chongqing (memoria "apa stilizata de noapte").
##
## Nu strica nimic: 31 nu era desenat de nicio pista (verificat prin grep pe
## toate cele 8), deci schimbarea e pur aditiva. Ce dispare o data cu ea e
## marcajul de eroare de UV — de acum sloturile INEXISTENTE (>=32) nu mai au
## unde sa cada, iar UV-urile gresite ies roz, nu magenta. Costul e asumat:
## kitul e deja exportat si masurat.
const FLAMINGO_PINK: int = 31
##
## INTEGRARE: E si G au ajuns amandoua la concluzia ca 31 trebuie pictat, dar
## cu rozuri diferite — E #F0A0AE (mediana pixelilor rozi din referinta) si G
## #D2A0BE (aceeasi tinta, dar compensata invers pentru lumina calda a temei).
## Se pastreaza G: e singura care tine cont ca soarele temei roteste nuanta si
## urca saturatia INAINTE ca pixelul sa ajunga pe ecran, si e verificata pe
## captura fata de banda referintei (sat 0.51 / hue +3.4 fata de 0.55 / +7.9).

## Zapada NU are slot propriu — alias peste FOAM_WHITE, vezi nota de mai sus.
const SNOW_WHITE: int = FOAM_WHITE

## Culorile, in ordinea sloturilor (identice cu atlasul generat).
##
## Doua dintre culorile insulare au fost mutate fata de prima propunere, ca sa
## respecte regulile din style_bible §1:
##   - VOLCANIC_BLACK e #55535A (V 0.35), nu un negru real: asfaltul (#4B4B4D,
##     V 0.30) trebuie sa ramana cea mai inchisa suprafata din scena, altfel
##     linia de curs nu se mai citeste la viteza.
##   - TILE_TERRACOTTA e la saturatie 0.60, nu 0.69: acoperisurile sunt o
##     suprafata MARE, iar un rosu saturat ar concura cu CAR_RED. Asa ramane
##     distinct si de KERB_RED (nuanta 21° fata de 8°).
## Valorile de mediu (0..13) au fost recalibrate DUPA MASURATOARE, nu dupa ochi
## (august 2026). Cadrul de joc avea saturatie mediana 0.52 pe familia
## nisip/stanca; foile de referinta din assets/dunele_inspiration/ stau la
## 0.59-0.71. Plangerea "lumea e fada" era, in cifre, un deficit de ~25% de
## saturatie plus lipsa oricarui intuneric real (p5 de luminanta 0.20 la noi,
## 0.08-0.12 in referinte).
##
## Ce s-a schimbat: saturatie ×1.1..1.3 pe tot mediul; sand_shadow si rock_dark
## coborate si in valoare (×0.86 / ×0.82) ca AO-ul si crapaturile sa aiba unde
## sa se aseze. Asfaltul si betonul raman neutre INTENTIONAT — soseaua e cea mai
## inchisa suprafata continua si trebuie citita, nu colorata. Accentele de
## masini (14..16) si sloturile Okinawa (17+) neatinse.
##
## Multiplicatorii exacti per slot sunt in istoricul PR-ului; regula de reluat:
## masoara (tools de mai jos in style_bible §14), schimba HEX, regenereaza
## atlasul, recalibreaza theme_exposure. Nimic altceva nu se atinge.
const HEX: Array[String] = [
	"E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
	"BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
	"E54839", "2C82E8", "F2D03C",
	"54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
	"7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
	"E8622D", "D2A0BE",
]

## Culoarea unui slot.
static func color(slot: int) -> Color:
	return Color.html(HEX[slot])

## UV-ul care nimereste CENTRUL slotului (fara bleeding intre culori vecine).
static func uv(slot: int) -> Vector2:
	return Vector2((float(slot) + 0.5) / float(SLOTS), 0.5)

## O SINGURA instanta a materialului lumii, partajata (cheia pentru putine
## draw call-uri: toate prop-urile arata spre acelasi material).
static var _shared: StandardMaterial3D

## Calea stratului de detaliu ACTIV. Tema o poate schimba (`detail_texture`).
##
## Exista fiindca detail_rock.png are STRATE ORIZONTALE — corect pentru faleze
## sedimentare (Baikal, Stromboli, Chongqing), gresit pentru tuful din
## Cappadocia, care se erodeaza prin siroire: santurile coboara CU apa. Fiind
## aplicat triplanar peste TOATA lumea, defectul nu se putea repara in mesh:
## benzile ieseau identice si pe o cutie (buiandrugul arcadei), nu doar pe
## corpurile de revolutie. Doua runde de critica oarba s-au pierdut cautand
## vinovatul in `Builder.revolve`.
##
## NU adauga material: se schimba doar textura din `detail_albedo`, deci
## numaratoarea din tools/probe_decor.gd nu se misca.
static var _detail_path: String = DETAIL_PATH


## Schimba stratul de detaliu al lumii. Se apeleaza INAINTE de prima cerere de
## material (Track.apply_theme), fiindca `_shared` e construit lenes o data.
## Daca materialul exista deja, i se schimba textura pe loc — altfel o pista
## incarcata a doua oara in aceeasi sesiune ar ramane cu detaliul precedentei.
static func set_detail_texture(path: String) -> void:
	var want := path if path != "" else DETAIL_PATH
	if want == _detail_path and _shared != null:
		return
	_detail_path = want
	if _shared != null:
		_shared.detail_albedo = load(_detail_path)
	# Si varianta cu stingere pe distanta, din acelasi motiv: altfel o pista
	# incarcata dupa alta ar pastra detaliul precedentei pe prop-uri.
	if _faded_detail != null:
		_faded_detail.set_shader_parameter("detail_tex", load(_detail_path))


## Cuantizarea raspunsului de lumina pe prop-uri, ceruta de TEMA (runda 25).
##
## De ce e un setter si nu o valoare in `faded_detail_material`: shaderul e
## PARTAJAT de toate pistele care au prop-uri pe UV de tuf, iar cuantizarea o
## cere doar Cappadocia. Implicitul din shader e 0 (Lambert continuu), deci o
## pista care nu apeleaza functia asta ramane bit-identica cu inainte.
##
## Se apeleaza din Track.apply_theme, langa `set_detail_texture`, si din acelasi
## motiv: materialul e lenes, iar o pista incarcata dupa alta ar mosteni altfel
## reglajul precedentei. De-aia ramura `else` STINGE explicit, in loc sa nu faca
## nimic — fara ea, o cursa pe Cappadocia urmata de una pe Baikal ar fi fatetat
## si stancile de la Baikal.
##
## `sun_deg` sunt ACELEASI grade ca rotatia luminii scenei, nu un vector scris
## de mana. Motivul e o capcana deja platita o data in proiectul asta (vezi nota
## lunga din `_shade_facets` si memoria `azimutul-soarelui-fata-de-drum`): o
## directie de lumina scrisa literal si neremasurata dupa ce soarele s-a mutat
## ajunge sa picteze umbra exact pe fata pe care soarele o lumineaza, adica doua
## semnale care se scad. Derivata din grade, se misca odata cu soarele.
static func set_prop_light_steps(on: bool, sun_deg: Vector3 = Vector3.ZERO,
		split: float = 0.34, low: float = 0.30, ambient: float = 0.0) -> void:
	var mat := faded_detail_material()
	mat.set_shader_parameter("light_steps", 1.0 if on else 0.0)
	if not on:
		mat.set_shader_parameter("ambient_split", 0.0)
		return
	mat.set_shader_parameter("light_split", split)
	mat.set_shader_parameter("light_low", low)
	mat.set_shader_parameter("ambient_split", ambient)
	# Directia CATRE soare, in spatiul lumii. Un DirectionalLight3D lumineaza pe
	# -Z local, deci vectorul catre sursa e +Z rotit — exact ce compara `light()`
	# cu normala.
	var b := Basis.from_euler(Vector3(
			deg_to_rad(sun_deg.x), deg_to_rad(sun_deg.y), deg_to_rad(sun_deg.z)))
	mat.set_shader_parameter("ambient_sun_dir", b * Vector3(0.0, 0.0, 1.0))

## Materialul comun al lumii. Vertex color = AO copt, inmultit peste atlas.
##
## Filtrarea: LINEAR cu mipmap-uri, nu NEAREST. Cat timp sloturile erau patrate
## de culoare uniforma, NEAREST era alegerea corecta — garanta zero amestec intre
## culori vecine. De cand sloturile au textura reala, NEAREST ar face granulatia
## sa scanteieze urat la distanta (aliasing), fix efectul pe care texturile ar
## trebui sa-l elimine.
##
## Riscul filtrarii liniare e bleeding-ul intre sloturi vecine. Il tine in frau
## generatorul de atlas: fiecare slot are 2px de margine cu culoarea lui curata
## (vezi PAD in tools/generate_palette_atlas.gd), deci chiar daca filtrarea trage
## din vecin, trage dintr-o zona care arata corect.
static func world_material() -> StandardMaterial3D:
	if _shared == null:
		_shared = StandardMaterial3D.new()
		_shared.albedo_texture = load(ATLAS_PATH)
		_shared.texture_filter = \
			BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_shared.vertex_color_use_as_albedo = true # AO copt in vertex colors
		_shared.roughness = 0.9
		# Specular SLAB, nu zero. Cu SPECULAR_DISABLED (valoarea veche) absolut
		# nimic din scena nu avea vreun reflex — totul citea ca hartie mata, iar
		# fetele orientate spre soare si cele din umbra difereau doar prin
		# intensitatea difuza. 0.15 la roughness 0.9 e un "kiss of light" abia
		# vizibil pe fetele spre soare, care separa planurile fara plastic.
		# Daca nisipul incepe sa luceasca pe device, aici se intoarce la
		# SPECULAR_DISABLED si sheen-ul ramane doar pe asfalt si masini.
		_shared.metallic_specular = 0.15
		# --- Stratul de detaliu: aici se repara "totul arata plat" ---
		#
		# UV-urile prop-urilor sunt colapsate pe un punct (dio_lib.assign_uvs), ca
		# fiecare fata sa ia exact culoarea slotului ei. Efect secundar: derivata
		# UV e zero, deci fiecare fata citeste UN texel si tot detaliul din atlas
		# e invizibil. Masurat pe fata de faleza: deviatie de luminanta 0.76 fata
		# de ~40 in imaginile de referinta.
		#
		# uv2_triplanar calculeaza coordonatele din VERTEX si NORMAL in vertex
		# shader — ATRIBUTUL UV2 NU E CITIT NICIODATA. Deci toate prop-urile
		# capata detaliu de suprafata fara unwrap, fara re-export si, esential,
		# FARA MATERIAL NOU: garda de draw call-uri nu se misca.
		#
		# Masca (32x1 RGBA, alfa per slot) se esantioneaza pe UV1, adica pe
		# centrul slotului — asa slotul din paleta devine si canal de intensitate:
		# roca primeste tot, masinile nimic.
		_shared.detail_enabled = true
		_shared.detail_albedo = load(_detail_path)
		_shared.detail_mask = load(DETAIL_MASK_PATH)
		_shared.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		_shared.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		_shared.uv2_triplanar = true
		# 1 / 0.35 = o repetitie la 2.86 m. Cele 4 benzi de strat din textura cad
		# atunci la ~0.71 m, in intervalul cerut de style_bible §3.
		_shared.uv2_scale = Vector3(DETAIL_SCALE, DETAIL_SCALE, DETAIL_SCALE)
	return _shared

## Materialul FRUNZISULUI: acelasi atlas, aceleasi sloturi, doar fara backface
## culling.
##
## A doua abatere deliberata de la "un singur material pentru toata lumea", si
## din alt motiv decat rock_material: acolo era vorba de textura, aici de
## GEOMETRIE. Vegetatia din Stylized Nature MegaKit e construita din foi
## DESCHISE — masurat dupa sudura vertexilor, 32-80% muchii de contur. O frunza
## dintr-un singur strat de fete are spate, iar spatele e cules: treci pe langa
## tufa si jumatate din ea dispare.
##
## Alternativa era Solidify in Blender (grosime de 2 cm pe fiecare foaie).
## Costa DUBLU in triunghiuri, si exact pe piesele cele mai numeroase de pe
## pista — smocurile din banda lipita de drum se instantiaza de peste o suta de
## ori. Un material in plus pe toata lumea e mai ieftin decat 60.000 de
## triunghiuri, iar garda din tools/probe_decor.gd numara tocmai materialele
## fiindca ELE sunt constrangerea pe mobil.
##
## Nu se aplica pe orice are frunze: cactusii si copacii morti sunt corpuri
## inchise (3% contur) si raman pe materialul obisnuit al lumii.
static var _foliage: StandardMaterial3D

static func foliage_material() -> StandardMaterial3D:
	if _foliage == null:
		# duplicate() fara subresurse: textura, masca si detaliul raman ACELEASI
		# obiecte, deci nu se dubleaza nimic in memoria GPU.
		_foliage = world_material().duplicate() as StandardMaterial3D
		_foliage.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _foliage

static func apply_foliage_material(root: Node) -> void:
	var mat := foliage_material()
	for node in _walk(root):
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = mat


## Varianta DUBLA-FATA a unei clase triplanare, pentru frunzisul din foi.
##
## Exista fiindca cele doua nevoi se bateau cap in cap: `apply_foliage_material`
## rezolva conturul (foile de 0 grosime dispar pe jumatate cu CULL_BACK), dar
## pune materialul ATLASULUI, deci sterge orice clasa; iar
## `triplanar_class_material` aduce textura, dar cu cull normal. Tufele care
## se legana (caper, ginestra, trestie) au nevoie de amandoua — pana in august
## 2026 primeau doar prima si de-aia ieseau blob-uri de o singura culoare,
## chiar dupa ce li s-a mapat o clasa.
##
## Se cheie pe clasa, si duplicatul e fara subresurse: textura ramane ACELASI
## obiect, deci nu se dubleaza nimic in memoria GPU. Costa un material per
## clasa de frunzis (azi unul singur, `macchia`) — acelasi schimb ca la
## `foliage_material`, si din acelasi motiv (garda numara materialele, si un
## material partajat e mai ieftin decat geometria care l-ar inlocui).
static var _foliage_class: Dictionary = {}

static func foliage_class_material(cls: String) -> StandardMaterial3D:
	if _foliage_class.has(cls):
		return _foliage_class[cls]
	var mat := triplanar_class_material(cls).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_foliage_class[cls] = mat
	return mat


## Varianta dubla-fata a unei clase, pusa pe TOT subarborele — pentru piesele
## cu un singur material dominant, unde clasa vine din alta parte decat maparea
## pe nume (vezi `class` din SCATTER_STROMBOLI).
static func apply_foliage_class_material(root: Node, cls: String) -> void:
	var mat := foliage_class_material(cls)
	for node in _walk(root):
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = mat


## Ca `apply_class_materials`, dar piesele mapate primesc varianta dubla-fata a
## clasei, iar cele nemapate materialul de frunzis (tot dubla-fata) in loc de
## cel al lumii. Pentru prop-urile cu `sway`, unde conturul conteaza pe TOT
## corpul — inclusiv pe partile fara clasa.
static func apply_foliage_class_materials(root: Node, mapping: Dictionary) -> void:
	var plain := foliage_material()
	for node in _walk(root):
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var cls := _class_for(String(mi.name), mapping)
		if cls.begins_with(TRI_PREFIX):
			mi.material_override = foliage_class_material(
				cls.trim_prefix(TRI_PREFIX))
		else:
			# Fara clasa (sau pe o clasa care nu e triplanara): conturul
			# ramane rezolvat, culoarea vine din atlas ca inainte.
			mi.material_override = plain


## ############################################################################
## OGLINDIREA NU CERE MATERIAL SEPARAT.
##
## Aici a stat pana in august 2026 o pereche de "materiale geamane" cu
## CULL_FRONT, pentru prop-urile puse cu scale.x = -1. Premisa era ca un
## determinant negativ inverseaza winding-ul si obiectul iese pe dos.
##
## Premisa e FALSA pe Godot 4: rasterizatorul intoarce singur sensul fetei dupa
## determinantul transformarii instantei. Masurat pe 4.7 (tools/MirrorTest.tscn):
## un quad CULL_BACK oglindit pe X ramane perfect vizibil. Materialul geaman era
## deci un AL DOILEA flip, care taia exact fetele dinspre camera — de aici
## bugul "stancile mari sunt goale pe dinauntru": jumatate din sectiunile de
## faleza de pe Dunele (`track_cliffs.gd` oglindeste 50% din ele) se randau ca
## niste coji prin care se vedea nisipul din spate.
##
## Daca vreodata pare din nou ca un prop oglindit e "pe dos", cauza e in mesh
## (normale inversate la export), nu in cull mode. Nu reintroduce geamanul.
##
## VALABIL DOAR PENTRU NODURI. Compensarea o face rasterizatorul dupa
## determinantul INSTANTEI, iar o instanta de MultiMesh n-are nod: transformarea
## ei sta in buffer si nu ajunge la logica aia. Dupa ce decorul a intrat in
## multimesh, exact acelasi bug s-a intors pe alt drum — vezi nota lunga si
## `_flipped_mesh` din `TrackDecorBatch`, plus etalonul tools/MultiMeshTest.tscn.
## Reparatia sta acolo, in coacere, si tot NU e materialul geaman.
## ############################################################################


## Materialul CLASEI de roca (faleze, butte, arcada, bolovani) — prima abatere
## deliberata de la "un singur material pentru toata lumea" (august 2026,
## upgrade grafic val 4b; regula actualizata in CLAUDE.md: materiale de CLASA,
## nu per asset).
##
## Albedo-ul e trim_rock.png — sedimentare cu pietre individuale, mortar si
## bevel fals PICTATE (diagnosticul BBR2: acolo statea diferenta, nu in
## poligoane). Se aplica TRIPLANAR IN SPATIUL LUMII, nu prin UV unwrap:
##   - contractul de UV-uri colapsate din dio_lib ramane intact (zero
##     re-exporturi de GLB);
##   - benzile curg CONTINUU peste sectiunile vecine de faleza — fara cusaturi
##     la fiecare 14 m;
##   - scalarea instantelor (±18%) nu mai intinde straturile.
## Vertex color = AO copt, ca peste tot. Fara stratul de detaliu pe UV2:
## masca lui se esantioneaza pe UV1, care sub triplanar nu mai inseamna slot —
## si trim-ul isi aduce oricum granulatia proprie.
## Din august 2026 (conversia Dunelor) albedo-ul rocii vine din
## assets/textures/classes/rock.png — sursa externa gradata prin
## process_class_textures — nu din trim-ul procedural. trim_rock.png ramane
## in repo ca fallback istoric si etalon al pipeline-ului procedural.
static func rock_material() -> StandardMaterial3D:
	return triplanar_class_material("rock")


## Roca aceleiasi clase, cu albedo mutat spre o alta piatra.
##
## Textura de clasa (`classes/rock.png`) e gradata spre gresia desertului, iar
## vertex colors coapte in GLB-uri o duc si mai mult intr-acolo. Pe alta lume —
## granitul rece al Alpilor — nuanta se muta AICI, nu prin modele noi si nu
## prin a strica materialul comun: fiecare culoare ceruta primeste o instanta
## cache-uita, deci o pista intreaga de stanci alpine costa UN material.
##
## Restul lumii ramane neatinsa: cine nu cere nuanta cheama `rock_material()`.
static var _rock_tints: Dictionary = {}

## ATENTIE la ce inseamna `tint`: e un FACTOR, nu culoarea finala. Peste el se
## inmultesc si textura de clasa (gradata spre gresie), si vertex colors coapte
## in GLB (tot gresie) — masurat pe prima incercare, un albedo b8bdc7 "gri
## granit" iesea tot portocaliu pe ecran, fiindca doi factori calzi bat un
## factor neutru. De aceea culorile de aici sunt SUPRACOMPENSATE spre rece: ele
## trebuie sa anuleze doua straturi calde, nu sa descrie piatra.
static func tinted_rock_material(tint: Color) -> StandardMaterial3D:
	var key := tint.to_html(false)
	if _rock_tints.has(key):
		return _rock_tints[key]
	var base := rock_material()
	var mat: StandardMaterial3D = base.duplicate()
	mat.albedo_color = tint
	_rock_tints[key] = mat
	return mat

## Pune materialul de roca pe un subarbore — aceeasi mecanica precum
## apply_world_material, alt material. Doar pentru assets-uri INTEGRAL din
## roca: un GLB cu parti de lemn/metal (mine_portal) ar primi piatra pe grinzi.
static func apply_rock_material(root: Node) -> void:
	var mat := rock_material()
	for node in _walk(root):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			mi.material_override = mat


## --- Materiale de clasa cu UV-uri REALE (pilotul de texturare, august 2026) ---
##
## Spre deosebire de rock_material (triplanar, pentru mesh-uri cu UV-uri
## colapsate), astea se aplica pe assets exportate cu UV-uri reale (proiectie
## cubica in dio_lib). Texturile vin din assets/textures/classes/ — surse
## externe (PolyHaven azi, ComfyUI maine) trecute OBLIGATORIU prin
## tools/process_class_textures.gd, care le gradeaza spre paleta. O textura
## nefiltrata pusa direct aici e exact reteta de "asset soup".
##
## Un material per CLASA de suprafata, cache-uit: oricate cladiri impart
## acoperisul de olane, toate costa UN singur material in garda.
const CLASS_TEXTURES := {
	"roof_tiles": "res://assets/textures/classes/roof_tiles.png",
	"plaster": "res://assets/textures/classes/plaster.png",
	"stone_wall": "res://assets/textures/classes/stone_wall.png",
	"rock": "res://assets/textures/classes/rock.png",
	# BAZALT. ACELASI PNG ca "rock" — nu se dubleaza in memorie, se schimba
	# doar multiplicatorul (vezi CLASS_TINT si nota de la ice_bloc). Dala
	# de "rock" e gresie de desert, medie (141, 97, 58): pe conul
	# Strombolilui iesea NISIP CALD pe toata buza craterului. Nu se putea
	# tenta clasa "rock" direct, fiindca ea e si `horizon_class` implicit
	# pentru TOATE temele (track.gd) si `rock_material()` comun — ar fi
	# revopsit siluetele de orizont pe celelalte piste.
	"volcanic_rock": "res://assets/textures/classes/rock.png",
	# VARUL SATULUI EOLIAN. ACELASI PNG ca "plaster" — nu se dubleaza in
	# memorie, se schimba doar multiplicatorul (vezi CLASS_TINT), aceeasi
	# mecanica ca la volcanic_rock/ice_bloc.
	#
	# Nu se putea folosi "plaster" direct: dala lui e gradata spre ancora
	# CONCRETE, iar varul din Stromboli sta pe slotul 22 (FOAM_WHITE, #E9F2F0).
	# Masurat: dala are luminanta 0.557, slotul 0.941 — raport 0.592. Pusa
	# netentata pe case, fatada se INTUNECA cu 44% (masurat si pe captura:
	# luminanta 95.3 -> 53.2 pe o fereastra strict pe perete). Gradarea
	# pastreaza luminanta sursei prin constructie, deci nu putea repara asta
	# singura — exact avertismentul din style_bible §4.
	"village_plaster": "res://assets/textures/classes/plaster.png",
	"rust_metal": "res://assets/textures/classes/rust_metal.png",
	"wood": "res://assets/textures/classes/wood.png",
	"wet_wood": "res://assets/textures/classes/wood.png",
	"concrete": "res://assets/textures/classes/concrete.png",
	# BETONUL ORASULUI (Chongqing). ACELASI PNG ca "concrete" — nu se dubleaza
	# in memorie, se schimba doar ridicarea si tenta (aceeasi mecanica pe care
	# o folosesc volcanic_rock, village_plaster si macchia_dry).
	#
	# Nu se putea folosi "concrete" direct: ancora lui e dana portului Okinawa,
	# ridicata cu `lift` 0.20 in process_class_textures.gd ca sa ramana mai
	# RECE si mai INCHISA decat varul de deasupra ei. Aici clasa cade pe
	# peretele de beton al fatadelor, care in atlas sta pe sloturile 8 si 29
	# (media (192,184,170), luminanta 0.726) — cu dala netentata (169,161,145,
	# luminanta 0.634) fatadele s-ar fi INTUNECAT cu ~13% fata de ce e azi pe
	# ecran. Tinta e deliberat culoarea de ACUM, nu una „de noapte": lumina
	# temei racește si coboara ea suprafata (masurat: slotul palid ajunge la
	# (83,84,92), R-B = -9, adica deja rece), deci o clasa care ar mai raci o
	# data ar face-o de doua ori.
	"city_concrete": "res://assets/textures/classes/concrete.png",
	# PIATRA VECHE a scarilor Shibati. ACELASI PNG ca "stone_wall" — doar alta
	# tenta, ca la city_concrete/volcanic_rock/village_plaster.
	#
	# Nu se putea folosi `stone_wall` direct fiindca dala lui e comuna cu
	# Okinawa si Alpii, iar o tenta pusa pe clasa ar fi revopsit si acolo.
	# Si nu se putea tinti slotul pe care stau treptele azi (3, ROCK_LIGHT,
	# #C18446): ala e gresie CALDA de desert — raportul catre el e
	# (1.26, 0.89, 0.51), adica ar fi cerut si o ridicare, si ar fi facut
	# scara Shibati portocalie in mijlocul unui oras de beton ud. Brief-ul
	# cere piatra veche uzata („treptele sunt geometrie, textura da uzura"),
	# deci tinta e piatra CENUSIE la luminanta dalei.
	"old_stone": "res://assets/textures/classes/stone_wall.png",
	# Kyoto POI F r3: bolovanii de gradina (garden_rock_a/b/c) pe ACEEASI dala de
	# zid, cu tenta mai inchisa si calda (vezi CLASS_TINT). Zero texturi noi.
	"garden_stone": "res://assets/textures/classes/stone_wall.png",
	# Insula (Okinawa): calcar coraligen si scoarta tropicala.
	"coral_rock": "res://assets/textures/classes/coral_rock.png",
	"bark": "res://assets/textures/classes/bark.png",
	# Muntele (Alpii): sisturi stratificate si zapada avalansei.
	"alpine_granite": "res://assets/textures/classes/alpine_granite.png",
	# TUFUL IN BENZI AL VAII ROSII (Cappadocia, POI D). ACEEASI dala ca
	# "alpine_granite" — nu se dubleaza in memorie, se schimba doar tenta
	# (aceeasi mecanica ca volcanic_rock / village_plaster / macchia_dry).
	#
	# De ce sisturile alpine si nu "rock": dala lor e STRATIFICATA, adica
	# are chiar desenul de sedimente orizontale pe care il cere faleza in
	# benzi. Dala de "rock" e gresie fara asezare, iar pe un perete de 20 m
	# ar fi iesit o pata uniforma — exact reprosul "banda pictata pe panta
	# neteda arata a panza".
	#
	# Nu se putea tenta "alpine_granite" direct: e clasa stancilor de pe
	# Alpi (Track09) si le-ar fi facut rosii.
	"red_valley_tuff": "res://assets/textures/classes/alpine_granite.png",
	# DALA gresiei: `olkhon_marble` (fisuri verticale, fete late), NU `alpine_granite` — aceea e un
	# zid de piatra uscata, cu blocuri mici si rosturi, si pe peretii de 14 m dadea zidarie de
	# caramida (numit de 4 ori independent). Masurat pe 6 cadre (docs/track_briefs/img/
	# monument_materiale): muchii orizontale dupa blur 1 px 0.449 -> 0.266, gy/gx 1.40 -> 0.92,
	# culoarea neschimbata (HSV median la +-1 grad). Zero VRAM nou pe pista: dala ridicata era deja
	# una singura pentru mv_sandstone. Tenta recalculata in spatiu liniar ca sa pastreze media.
	# GRESIA MONUMENT VALLEY (Track19, brief monument_valley.md §4): peretele
	# monoliturilor si al meselor, rosu-portocaliu #B8552E. ACEEASI dala ca
	# `red_valley_tuff` (stratificata, zero VRAM nou), alta ridicare si alta tenta:
	# tinta (0.722, 0.333, 0.180) are R PESTE media dalei (0.651), deci tenta
	# singura nu ajunge — vezi CLASS_LIFT. Clasa e NOUA: nicio alta pista n-o
	# foloseste, deci `rock` / `red_valley_tuff` raman neschimbate.
	"mv_sandstone": "res://assets/textures/classes/olkhon_marble.png",
	# SALVIA MONUMENT VALLEY (Track19, brief monument_valley.md §4: #8E977C, gri-verde
	# prafuit). ACEEASI dala ca `macchia`/`macchia_dry` — zero VRAM nou, doar alta
	# ridicare si alta tenta. Exista fiindca slotul `CACTUS_GREEN` (12, #5B7C34) e
	# oliv saturat, iar nicio culoare din atlas nu e gri-verde: nu se obtine din
	# slot si nici din `macchia` (verde sezonier). Vezi CLASS_TINT / CLASS_LIFT.
	# Se aplica DOAR pe nodul `Sagebrush_Foliage` (WorldProp.CLASSES_BY_THEME).
	"mv_sage": "res://assets/textures/classes/macchia.png",
	# CALOTA stancilor Monument Valley (#B9A08C, gri-roz palid, brief §4). Pe atlas
	# (SAND_LIGHT) iesea galben-oliv la umbra (galben x ambient rece). Acum dala
	# `olkhon_marble` a gresiei (imparte imaginea ridicata, CLASS_LIFT_SHARED): fara modelul de
	# zid de piatra al lui alpine_granite, care pe calota iesea mozaic gri-verzui. +1 material.
	"mv_cap": "res://assets/textures/classes/olkhon_marble.png",
	# CALCARUL RYUKYU (Track20, brief okinawa.md §4: gri-crem #CFC6B0). Dala
	# `coral_rock` (poroasa, cu cratere si pete albe — singura din biblioteca care
	# citeste ca roca de recif) RIDICATA, nu `olkhon_marble`: aceea are striuri
	# verticale de lemn/sist, iar zidurile gusuku de 8 m ar fi iesit cu scoarta pe
	# ele. Clasa e NOUA, `coral_rock` ramane neatinsa (stancile Track08).
	"ok_limestone": "res://assets/textures/classes/coral_rock.png",
	# OLANELE RYUKYU (#B8452E, rosu-caramiziu). Dala lui `roof_tiles` ridicata si
	# tentata: slotul 23 (TILE_TERRACOTTA) iese portocaliu-pal, iar `roof_tiles`
	# plin e brun-portocaliu (154,113,82), deci nici una nu da rosul din brief.
	# Clasa separata, ca `roof_tiles` (case Dunele, Fiordland) sa ramana neatinsa.
	"ok_roof": "res://assets/textures/classes/roof_tiles.png",
	# CLASELE TRANSFAGARASAN (Track21, brief transfagarasan.md §4). Toate sunt clase NOI
	# pe dale EXISTENTE (zero VRAM nou, nicio clasa partajata retentata — memoria
	# `tenta-pe-clasa-partajata`); se aplica doar prin `CLASSES_BY_THEME["transfagarasan"]`.
	# SISTUL: tinta #7E8478 (gri-verzui). Dala `alpine_granite` e crem-calda (#ADA38F),
	# dar toate canalele tintei stau SUB ea (0.50 / 0.63 / 0.68 liniar), deci tenta ajunge.
	"tf_schist": "res://assets/textures/classes/alpine_granite.png",
	# ZIDARIA (Poenari, cabane, case, ziduri de sprijin, parterul): `stone_wall` n-are
	# scara triplanara (azi doar prin UV-uri colapsate, adica un singur texel), deci clasa
	# proprie pe aceeasi dala, ridicata si tentata spre gri neutru (vezi CLASS_TINT).
	"tf_stone": "res://assets/textures/classes/stone_wall.png",
	# JNEAPANUL: tinta #34503A (verde inchis albastrui). `pine_needles` ramane #6C8946
	# (molizii Alpilor), prea luminoasa si prea galbena pentru tufa culcata.
	"tf_jneapan": "res://assets/textures/classes/pine_needles.png",
	# FAGUL european (#5E8A3A, verde cald): `beech_canopy` (Fiordland) iese #486335, mai
	# inchis si mai rece. Aceeasi dala `acacia_canopy`, ridicata si tentata altfel.
	"tf_beech": "res://assets/textures/classes/acacia_canopy.png",
	# TUFUL CREM al Cappadociei: hornurile, poarta geamana, gura de pestera si
	# fatada bisericii rupestre. ACEEASI dala ca `red_valley_tuff` — nu se
	# dubleaza in memorie, se schimba doar ridicarea si tenta (aceeasi mecanica
	# ca volcanic_rock / ice_bloc / macchia_dry).
	#
	# Clasa separata fiindca `red_valley_tuff` e tentat spre CARAMIZIU pentru
	# canionul rosu (POI D), si aterizeaza pe (0.523, 0.339, 0.249) — masurat.
	# Pus pe hornuri, ar fi facut rosu exact ce brief-ul §0.1 cere crem, adica
	# ar fi repetat defectul „cosuri de fabrica" pe care `TUFF_UV_REMAP` din
	# world_prop.gd tocmai l-a reparat mutand sloturile pe cremuri.
	#
	# De ce dala STRATIFICATA si aici: hornul de tuf E un corp sedimentar, cu
	# straturi orizontale de cenusa sudata — acelasi argument ca la faleza in
	# benzi, la alta culoare.
	"tuff_cream": "res://assets/textures/classes/alpine_granite.png",
	"snow": "res://assets/textures/classes/snow.png",
	# Coroana coniferelor (pictata, vezi tools/paint_pine_needles.py).
	"pine_needles": "res://assets/textures/classes/pine_needles.png",
	# Frunzisul mediteranean: tufele, coroanele si trestia de pe Stromboli.
	# A doua clasa pictata (tools/paint_macchia.py) — frunza lata in buchete,
	# nu ac in spic. Vezi nota din CLASS_TRIPLANAR_SCALE pentru scara.
	"macchia": "res://assets/textures/classes/macchia.png",
	# TUFARISUL USCAT. ACELASI PNG ca "macchia" — nu se dubleaza in memorie,
	# se schimba doar ridicarea si tenta (aceeasi mecanica ca volcanic_rock /
	# ice_bloc / village_plaster).
	#
	# Exista fiindca paleta face o distinctie pe care o singura dala ar sterge-o:
	# frunzisul verde sta pe slotul 21 (TROPICAL_GREEN, luminanta 0.382), iar
	# tufele USCATE de soare pe 13 (DRY_VEGETATION, #AF9F4E, 0.606) — caperul e
	# integral pe 13. Cu dala verde pusa pe tot, capirul devenea verde si insula
	# pierdea contrastul dintre tufa suculenta si cea uscata, adica exact ce
	# spune un flanc mediteranean despre cat de arsa e panta.
	#
	# Nu se putea obtine dintr-o tenta: raportul pe canale fata de verde e
	# (2.78, 1.30, 1.30), PESTE 1 pe toate trei, iar `albedo_color` doar
	# intuneca. Ridicarea sta in CLASS_LIFT, tenta doar corecteaza nuanta.
	"macchia_dry": "res://assets/textures/classes/macchia.png",
	# Gheata lacului (Baikal; pictata, vezi tools/paint_ice.py).
	"ice": "res://assets/textures/classes/ice.png",
	# Aceeasi dala, pentru PIESELE de gheata (torosuri, turturi, blocuri).
	# Clasa separata fiindca difera pe DOUA axe fata de lac: scara (un bloc
	# de 1.5 m nu prinde nimic dintr-o repetitie la 6.25 m) si culoarea —
	# lacul isi ia turcoazul din vertex colors (_ice_color, adancimea), pe
	# cand GLB-urile au in vertecsi doar AO, deci dala palida iesea piatra
	# sparta, nu gheata. Tenta e in CLASS_TINT.
	"ice_bloc": "res://assets/textures/classes/ice.png",
	# Marmura Olkhonului (Stanca Samanului, arcul grotei, faleza insulei si
	# peretii de stanca asezati de mana pe Track10). Dala PROPRIE, nu cea
	# alpina: sursa alpina e o fotografie de ZID de piatra uscata de 2 m, si
	# pe o fata de 18 m coltii Samanului ieseau cetate (masurat pe captura,
	# de doua ori — #313 si prima incercare din PR-ul asta). Sursa de aici
	# (marble_cliff_04, 12.7 m) e o faleza de marmura cu vine si strate, la
	# scara pieselor pe care cade. Vezi tools/process_class_textures.gd.
	"olkhon_marble": "res://assets/textures/classes/olkhon_marble.png",
	# Zidaria taiata a caii ferate Circum-Baikal: viaduct, portal si galeria
	# tunelului. Aici dala ALPINA e alegerea corecta, si din exact motivul
	# pentru care a picat pe coltii Samanului: sursa ei e o fotografie de ZID
	# de piatra uscata. Pe o stanca naturala iesea cetate; pe zidaria unui
	# viaduct de piatra e chiar subiectul. Sursa `stone_wall` (calcar ciupit,
	# ancora de insula) s-a incercat prima si citea beton turnat pe captura
	# din galerie — netedul ei nu are randuri.
	"cut_stone": "res://assets/textures/classes/alpine_granite.png",
	# FRESCELE bisericii rupestre din orasul subteran (Cappadocia, POI F).
	# A treia clasa PICTATA (tools/paint_fresco.py, dupa pine_needles si
	# macchia): motive bizantine ABSTRACTE — registre, medalioane, arcaturi
	# oarbe, cruci inscrise — pe var cojit. Nicio figura si niciun text, ca in
	# brief §5.2 si in prompt-ul de kit ("frescoes are abstract shapes").
	#
	# Dala PROPRIE, nu una refolosita cu alta tenta, si asta e diferenta fata
	# de volcanic_rock / village_plaster / macchia_dry: acelea reutilizeaza o
	# dala fiindca sunt tot SUPRAFETE (piatra, var, frunzis) si difera doar prin
	# culoare. O fresca nu e o suprafata cu alta culoare, e un DESEN — nicio
	# tenta pusa peste gresie sau peste tencuiala nu produce un medalion.
	"fresco": "res://assets/textures/classes/fresco.png",
	# GRANITUL kopje-urilor din Serengeti (Track14). ACEEASI dala ca
	# `olkhon_marble` — nu se dubleaza in memorie, se schimba doar tenta
	# (mecanica volcanic_rock / tuff_cream). Sursa (marble_cliff_04, 12,7 m)
	# e o faleza NATURALA la scara kopje-ului de 14 m; `alpine_granite` e un
	# zid de piatra de 2 m si pe stanca naturala a iesit cetate de doua ori
	# (memoria `clase-pe-piese-de-kit`), iar `rock` e gresie calda de canion
	# (141,97,58) — granitul de aici sta pe MARBLE_GREY / ROCK_LIGHT.
	# Masurat: dala olkhon are media (178,165,150), la 3-9% de tinta pe
	# canal, deci nu cere CLASS_LIFT. Clasa separata fiindca o tenta pe
	# `olkhon_marble` ar fi revopsit Stanca Samanului de pe Baikal.
	"granite": "res://assets/textures/classes/olkhon_marble.png",
	# LUTUL BATUT al termitierelor (Serengeti). ACEEASI dala ca "rock" — nu se
	# dubleaza in memorie, se schimba doar ridicarea si tenta (mecanica
	# volcanic_rock / tuff_cream / city_concrete).
	#
	# Masurat (tools/_tmp_probe_class_rgb.gd) fata de ancora ponderata a
	# termitierei (77-78% slot 23 #C4784F + 22-23% slot 27 #A8683A, ambele
	# caramizii — o singura familie de culoare, nu doua): dala `rock` are media
	# (140.7, 97.4, 58.2), tinta ponderata (189.7, 116.4, 74.3). Raportul pe
	# canale e (1.35, 1.19, 1.28) — PESTE 1 pe toate trei, deci nu se poate
	# obtine dintr-un `albedo_color` (doar intuneca): cere CLASS_LIFT, vezi mai
	# jos. Alte candidate incercate (plaster, concrete, stone_wall) au iesit
	# net mai rau: dupa aceeasi ridicare, spread-ul intre canale la tenta le-ar
	# fi cerut sa coboare verde/albastru cu 35-57%, adica sa stearga toata
	# granulatia sursei ca sa ajunga rosii — `rock` are nevoie de doar 5-11%.
	"termite_clay": "res://assets/textures/classes/rock.png",
	# Coroana savanei (Serengeti, lotul FRUNZISULUI): acaciile-umbrela,
	# fever_tree, fig_tree, euphorbia. A patra clasa PICTATA (dupa
	# pine_needles/macchia/fresco) — vezi tools/paint_acacia_canopy.py pentru
	# de ce nici macchia (frunza lata de tufa mediteraneana), nici
	# pine_needles (tusa liniara de ac) nu descriu o frunza compusa pinnata pe
	# un platou de 7-13 m. Dala PROPRIE, nu una refolosita cu alta tenta:
	# masurat (probe_slots.gd), coroanele nu au un slot cald de indepartat —
	# ele ADUNA deja pe 12/13/21, deci nu era nevoie de CLASS_TINT/CLASS_LIFT.
	"acacia_canopy": "res://assets/textures/classes/acacia_canopy.png",
	# SCOARTA GALBEN-VERZUIE a acaciei-febra (fever tree, Vachellia
	# xanthophloea). ACEEASI dala ca "bark" — nu se dubleaza in memorie, se
	# schimba doar ridicarea si tenta (mecanica volcanic_rock / tuff_cream /
	# termite_clay). Redeschide respingerea valului 1 (vezi CLASSES_BY_MODEL,
	# nota veche "fever_tree — RESPINS"): observatia era corecta (trunchiul
	# galben e semnul speciei), dar concluzia gresita — o dala nu poate fi
	# tentata direct spre o culoare MAI DESCHISA decat ea (albedo_color doar
	# intuneca), insa CLASS_LIFT poate, exact ca la tuff_cream/termite_clay.
	#
	# Nu se putea tenta "bark" direct: e clasa trunchiurilor de acacia
	# obisnuita/smochin/copac-uscat de pe Serengeti SI a palmierilor de pe
	# Okinawa/Stromboli — o tenta galbena ar fi revopsit toate astea.
	"bark_fever": "res://assets/textures/classes/bark.png",
	# --- Machu Picchu: ZIDARIA INCASA (Track15) ---------------------------
	#
	# ACEEASI dala ca `alpine_granite` / `cut_stone` — nu se dubleaza in
	# memorie, se schimba doar ridicarea si tenta (mecanica volcanic_rock /
	# tuff_cream / termite_clay).
	#
	# De ce o clasa si nu `cut_stone` direct, desi scara de zidarie (0.28) e
	# exact ce trebuie: `cut_stone` e clasa tunelului si a viaductului de pe
	# BAIKAL (track_decor.gd:654-659, Tunnel_Portal/Bore/Niche, Viaduct_Pier/
	# Arch/End), iar tenta lui e RECE — Color(0.88, 0.91, 0.97). Zidaria
	# incasa trebuie sa aterizeze CALD: tinta e media ponderata pe arie a
	# sloturilor pe care stau chiar piesele kitului (3 ROCK_LIGHT si 29
	# MARBLE_GREY domina, cu 4 ROCK_DARK pe nise si cornisa), pe cele sase
	# piese de zidarie. Cifrele sunt re-derivabile din atlas + dala: tinta e
	# 55% ROCK_LIGHT + 33% MARBLE_GREY + 13% ROCK_DARK (eroare 0.0008), iar
	# lift*tenta aterizeaza pe (0.7104, 0.5550, 0.3956). Verificat independent
	# la revizia adversariala. (Prima redactare cita o unealta
	# `probe_mp_tints.gd` care NU exista — cifrele erau bune, calea de
	# reverificare nu; memoria `justificarea-din-comentariu-se-verifica`.)
	#   tinta  (0.7104, 0.5549, 0.3927)  lum 0.5762
	#   dala   (0.6376, 0.5992, 0.5208)  lum 0.6017
	#   raport (1.1142, 0.9260, 0.7541)  -> un canal PESTE 1, deci cere lift
	# O tenta pe `cut_stone` ar fi facut tunelul Baikalului maro.
	"inca_stone": "res://assets/textures/classes/alpine_granite.png",
	# PIELEA elefantului (Serengeti, lotul ELEFANTULUI). ACEEASI dala ca
	# "concrete" — nu se dubleaza in memorie, se schimba doar tenta (mecanica
	# volcanic_rock / city_concrete / termite_clay).
	#
	# Elefantul a fost exclus in bloc din valul 1 cu argumentul corect pentru
	# zebra ("dungile SUNT sloturile de paleta") — dar pielea lui e o
	# suprafata monocroma incretita, exact ce descrie o clasa triplanara, nu o
	# paleta de accente. Masurat pe .glb (tools/_tmp_probe_elephant4.gd):
	# corpul (slot 29, 88.7% din arie) si capul/picioarele (slot 2, 2.8%) sunt
	# amandoua griuri NEUTRE — nimic de pastrat acolo. Fildesii (slot 22,
	# 8.5%, z=[-4.02,-2.66], fata modelului) raman pictati prin ACCENT_SPLIT/
	# ACCENT_HOLDS_CLASS (vezi world_prop.gd): un alb intentionat, sters de
	# orice clasa aplicata pe tot nodul.
	#
	# De ce "concrete" si nu "rock"/"stone_wall"/"alpine_granite"/
	# "olkhon_marble": masurat (tools/_tmp_probe_elephant, script temporar,
	# sters) directia dominanta a variatiei per candidat (raport std pe
	# randuri sau coloane fata de std total, pe dala redusa la 256x256):
	#   rock            0.581 pe randuri  -> STRATE orizontale (faleza
	#                   sedimentara, exact ce style_bible §4 numeste gresit
	#                   pentru o suprafata care nu e geologie)
	#   olkhon_marble   0.446 pe coloane  -> vine/strate verticale
	#   alpine_granite  0.265 pe randuri  -> sisturi, tot stratificat
	#   stone_wall      0.259 pe randuri  -> calcar ciupit in BLOCURI (bun
	#                   pentru zid, prea grosier pentru piele: variatie
	#                   fina 19.13 e cea mai mare, dar in pete de bloc, nu
	#                   in crapaturi fine)
	#   plaster         aproape plat (std local 8x8 = 0.57 — e tencuiala
	#                   neteda a satului eolian, zero relief de suprafata)
	#   concrete        0.156 / 0.220     -> IZOTROP (nicio axa dominanta),
	#                   variatie fina 18.12 pe bloc de 8x8, crapaturi si pete
	#                   NEREGULATE — exact "incretit", nu "stratificat"
	# `concrete` e singura fara directie dominanta si cu detaliu fin
	# comparabil cu `stone_wall`, deci imbraca elefantul in crapaturi
	# organice, nu in randuri de sediment.
	#
	# Zero PNG nou: refoloseste dala lui `concrete`. Scara triplanara ramane
	# NESCHIMBATA fata de `concrete` (vezi CLASS_TRIPLANAR_SCALE) — masurat cu
	# autocorelatie (diferenta medie absoluta intre pixeli la distanta d),
	# distanta de decorelare a detaliului fin e ~19px din 512, adica 3.71%
	# din dala. La scara existenta a lui `concrete` (o repetitie la 2 m),
	# 3.71% * 2 m = 7.4 cm — in banda 5-15 cm ceruta de brief pentru
	# increiturile pielii. Nicio derivare noua de scara nu era necesara.
	"elephant_hide": "res://assets/textures/classes/concrete.png",
	# PIELEA hipopotamului (Serengeti, lotul HIPOPOTAMULUI, redeschidere a
	# respingerii pur bugetare din lotul elefantului — vezi ACCENT_HOLDS_CLASS
	# / hippo_hazard.gd pentru cablare). ACEEASI dala ca "concrete"/
	# "elephant_hide" — nu se dubleaza in memorie, se schimba doar tenta si
	# scara (mecanica volcanic_rock / city_concrete / termite_clay).
	#
	# De ce ACEEASI dala si nu alta: masurat (tools/_tmp_probe_hippo_tex2.gd,
	# script temporar, sters), anizotropie pe dala redusa la 128x128 (aceeasi
	# metoda ca la elephant_hide, raport std pe randuri/coloane fata de std
	# total):
	#   rock            0.623 pe randuri  -> STRATE (respins, acelasi motiv ca
	#                   la elefant)
	#   stone_wall      0.309 pe randuri  -> aproape izotrop, dar grain FIN
	#                   (decorelare la 3.9% din dala, vezi mai jos) — bloc de
	#                   piatra ciupita, nu increitura de piele
	#   olkhon_marble   0.232/0.508       -> vine verticale (respins)
	#   plaster         0.119/0.114       -> izotrop, dar aproape PLAT (std pe
	#                   bloc de 8x8 = 0.31, fata de 17+ la concrete/stone_wall)
	#                   — zero relief, nu descrie "increturi mari si rare"
	#   concrete        0.218/0.311       -> IZOTROP (nicio axa dominanta,
	#                   acelasi rezultat calitativ ca la derivarea elefantului),
	#                   relief real (std bloc 8x8 = 17.3)
	# `concrete` ramane singura cu izotropie SI relief vizibil — exact
	# argumentul care a ales-o si pentru elefant, redescoperit independent.
	"hippo_hide": "res://assets/textures/classes/concrete.png",
	# Gneisul ud al Fiordland-ului (stirling_ledge Wall/Overhang, torrent_chute
	# Rock, nodurile FarWall_*/SnowRidge_* din fiordland_horizon) — brief §4:
	# "gneisul ud si verde-negru sunt deja in atlas", clasa refoloseste dala
	# `alpine_granite` (zero VRAM nou), ca `inca_stone`/`cut_stone` mai sus.
	"wet_gneiss": "res://assets/textures/classes/alpine_granite.png",
	# SCOARTA NEAGRA a fagului argintiu (Fiordland, lotul PADUREA DE FAGI).
	# ACEEASI dala ca "bark" — nu se dubleaza in memorie, se schimba doar
	# tenta (mecanica bark_fever/volcanic_rock/tuff_cream). Masurat
	# (tools/probe_slots.gd): Trunk/Trunk_001/Trunk_002 sunt 100% pe slotul 28
	# (LOG_DARK #4A3526) pe toate cele trei modele — deja monocrome SI deja pe
	# culoarea tinta, spre deosebire de fever_tree (trunchi galben, tinta
	# departe de dala). Aici tenta doar aduce dala de scoarta pe negrul-brun
	# al fagului, fara nicio ridicare (vezi CLASS_TINT: toate canalele sub 1).
	"bark_beech": "res://assets/textures/classes/bark.png",
	# FRUNZISUL fagului argintiu, coronament marunt verde-negru (brief §4:
	# "verde-negru de muschi si fag, cel mai inchis verde din joc"). ACEEASI
	# dala ca "acacia_canopy" — nu se dubleaza in memorie, se schimba doar
	# tenta. Masurat (probe_slots.gd): nodurile Crown/Crown_001/Crown_002 nu
	# separa trunchi/coroana pe INALTIME ca la Serengeti (sloturile 21 si 28
	# ocupa aproape acelasi interval de y in fiecare coroana) — coroana e UN
	# nod amestecat 56% TROPICAL_GREEN (21) + 44% LOG_DARK (28, umbra/ramurile
	# dese din interiorul coronamentului marunt). O clasa pe tot nodul Crown
	# sterge ambele sloturi deodata, deci tinta e media ponderata pe arie a
	# celor doua, nu un singur slot ales cu ochiul (aceeasi regula ca la
	# `tuff_cream`/`termite_clay`).
	#
	# `rata_tree.Rata` (28.2% slot 7 KERB_RED flori + 38.8% slot 21 + 33.0%
	# slot 28) refoloseste ACEEASI clasa pe corp, dupa ce accentul de flori
	# ramane pe atlas prin ACCENT_SPLIT (vezi world_prop.gd): renormalizat
	# doar pe sloturile 21/28 (54.0%/46.0%), tinta ponderata a Ratei cade la
	# (68.1, 90.3, 49.9) — la sub 2 unitati pe canal fata de tinta fagului
	# (67.8, 91.8, 50.4), aceeasi familie de culoare, deci nu justifica o a
	# doua clasa (buget +2, nu +3).
	"beech_canopy": "res://assets/textures/classes/acacia_canopy.png",
	# --- Jodhpur (Track17), brief §4/§5.1 -----------------------------------
	# Varul albastru al caselor: DOUA clase NOI pe dala lui `village_plaster`,
	# nu tenta lui (o tenta pe o clasa existenta recoloreaza Stromboli —
	# memoria `tenta-pe-clasa-partajata`). Alb x tenta = albastru.
	"blue_lime_light": "res://assets/textures/classes/plaster.png",
	"blue_lime_indigo": "res://assets/textures/classes/plaster.png",
	# Gresia fortului si a fantanii: blocuri cu rosturi fine (kitul, regula 5:
	# rosturile NU sunt geometrie, vin din textura clasei) -> dala de blocuri
	# `stone_wall`, ca `old_stone`. Doua tente, o singura imagine ridicata.
	"red_sandstone": "res://assets/textures/classes/stone_wall.png",
	"rose_sandstone": "res://assets/textures/classes/stone_wall.png",
	# Riolitul (stanca fortului, bolovanii parcului de desert): dala
	# stratificata `alpine_granite`, ca `red_valley_tuff` — zero VRAM nou.
	"rhyolite": "res://assets/textures/classes/alpine_granite.png",
	# --- Kyoto (Track18), brief §4 ----------------------------------------------
	# FRUNZISUL DE TOAMNA: o singura dala NEUTRA (gri, R=G=B), patru clase pe ea.
	# Tenta doar inmulteste, deci un rosu de artar (#BB3522) nu se poate scoate
	# din nicio dala verde existenta (acacia_canopy 89/108/56 ar cere R x2.1):
	# dala trebuie sa fie gri si cat mai deschisa. Generata de
	# tools/gen_autumn_foliage.py (frunze de artar lobate, 3 straturi, goluri
	# intunecate, infasurata). Patru materiale, O SINGURA imagine in memorie
	# (doar maple_orange/ginkgo_gold impart o a doua, ridicata — vezi CLASS_LIFT).
	"maple_crimson": "res://assets/textures/classes/autumn_foliage.png",
	"maple_orange": "res://assets/textures/classes/autumn_foliage.png",
	"ginkgo_gold": "res://assets/textures/classes/autumn_foliage.png",
	"leaf_litter": "res://assets/textures/classes/autumn_foliage.png",
	# Integrarea kitului (grupa int-a): arțarul RUGINIU are coroana pe aceeasi
	# tenta ca `leaf_litter`, dar la scara COROANEI (0.1), nu a covorului (0.25),
	# si bambusul are frunze lime — atlasul nu are slot lime (cel mai deschis verde,
	# CACTUS_GREEN, iese oliv). Doua materiale noi, ZERO imagini noi in memorie.
	"maple_rust": "res://assets/textures/classes/autumn_foliage.png",
	"bamboo_lime": "res://assets/textures/classes/autumn_foliage.png",
	# Lemnul de machiya si muschiul: clase NOI pe dalele lui `wood` si `macchia`,
	# NU tente pe ele (memoria `tenta-pe-clasa-partajata`: `wood` e folosit pe
	# Dunele/Okinawa, `macchia` pe Okinawa/Stromboli).
	"machiya_wood": "res://assets/textures/classes/wood.png",
	"moss": "res://assets/textures/classes/macchia.png",
	# Valul de materiale Kyoto (docs/track_briefs/kyoto_materiale.md): trei clase
	# NOI pe dale deja in VRAM, ZERO imagini noi. Clase separate, nu tente pe
	# `roof_tiles`/`bark`/`pine_needles`, din acelasi motiv ca machiya_wood.
	#   kawara        - acoperisurile (machiya, temple, pagode, clopotnita)
	#   bark_kyoto    - trunchiurile de arțar, ginkgo, pin niwaki
	#   cedar_needles - coroana cedrilor (padurea Inari) si a pinilor niwaki
	"kawara": "res://assets/textures/classes/roof_tiles.png",
	"bark_kyoto": "res://assets/textures/classes/bark.png",
	"cedar_needles": "res://assets/textures/classes/pine_needles.png",
	# Valul 2 (cererea dezvoltatorului dupa captura: „peste tot unde avem rosul,
	# bambusul, Kiyomizu"). Lacul vermilion, rosul trenului/podului si tulpinile
	# de bambus pe dala `wood` RIDICATA (rosul: o imagine rotita, impartita prin
	# CLASS_LIFT_SHARED; bambusul: una nerotita).
	# Prima incercare a fost `concrete` (pata fara fibra) si a dat MAI PUTIN
	# detaliu decat atlasul cu stratul de detaliu partajat (pe captura: pod
	# 4.85 -> 4.65, bambus 3.11 -> 2.74, diferenta de blur 1 px): pe o culoare
	# saturata ridicata, R se taie si variatia ramane doar pe G/B, mici. Masurat
	# pe rezultatul tentat: deviatia de luminanta 14.6 cu `concrete`, 27.5 cu
	# `wood` la ridicarea 0.65.
	"shu_vermilion": "res://assets/textures/classes/wood.png",
	"shu_red": "res://assets/textures/classes/wood.png",
	"bamboo_culm": "res://assets/textures/classes/wood.png",
}

## Tente de albedo per clasa, inmultite peste textura. Pentru clasele care
## REFOLOSESC dala alteia dar trebuie sa aterizeze pe alta culoare medie:
## ice_bloc readuce dala palida a lacului la culoarea slotului ICE_TURQUOISE
## (media dalei e ~(0.75, 0.87, 0.885), slotul e (0.49, 0.757, 0.776) —
## raportul da tenta). Textura NU se dubleaza in memorie: acelasi PNG,
## alt multiplicator pe material.
const CLASS_TINT := {
	"ice_bloc": Color(0.65, 0.87, 0.88),
	# Tuful crem: tenta aproape neutra, fiindca RIDICAREA face aproape toata
	# treaba (vezi CLASS_LIFT). Calculata, nu aleasa — dupa ridicarea la
	# k = 1.3140 dala sta pe (0.838, 0.787, 0.684), iar tinta ponderata pe arie
	# e (0.790, 0.754, 0.684), deci raportul pe canale da exact valorile de mai
	# jos. Albastrul ramane 1.0: pe el ridicarea a nimerit din prima, si orice
	# valoare peste 1 ar fi fost oricum imposibila (`albedo_color` doar coboara).
	"tuff_cream": Color(0.943, 0.958, 1.000),
	# `olkhon_marble` NU are tenta: dala lui e gradata direct spre slotul
	# MARBLE_GREY in pipeline, deci aterizeaza singura pe culoarea corecta.
	# Zidaria caii ferate e gradata spre CORAL_SAND (crem de insula, slotul
	# calcarului de Okinawa); pe Baikal trebuie sa ramana piatra cenusie sub
	# soare rece, de unde tenta rece de aici.
	"cut_stone": Color(0.88, 0.91, 0.97),
	# Zidaria incasa: dupa ridicarea la 0.6704 (CLASS_LIFT, k = 1.1142 = max
	# raport pe canale) dala ajunge la (0.7104, 0.6676, 0.5803); tenta o aduce
	# pe tinta masurata (0.7104, 0.5549, 0.3927). Calculata, nu aleasa —
	# tinta_c / (dala_c * k), ca la macchia_dry / tuff_cream / termite_clay.
	# Canalul R nimereste exact (1.0000), deci nu mai ramane nimic de urcat.
	"inca_stone": Color(1.0, 0.8311, 0.6768),
	# Bazalt: gresia calda a dalei impinsa spre cenusiu-rece si coborata mult.
	# Nu e o alegere de gust — pe un vulcan tanar roca de langa crater e cea
	# mai INCHISA suprafata din cadru, iar cu dala netentata buza citea ca o
	# duna de nisip. Multiplicativ pe (141, 97, 58) da ~(48, 40, 37).
	"volcanic_rock": Color(0.34, 0.41, 0.63),
	# Varul: dala (151.7, 140.7, 125.7) trebuie sa aterizeze pe slotul 22
	# (233, 242, 240). Raportul pe canale e (1.536, 1.720, 1.909) — PESTE 1,
	# deci nu se poate obtine dintr-un multiplicator: `albedo_color` doar
	# intuneca. Urcarea se face pe TEXTURA, in CLASS_LIFT; aici ramane doar
	# corectia de nuanta (dala e calda, varul e rece).
	"village_plaster": Color(0.97, 1.0, 1.0),
	# Tufarisul uscat: dala verde, ridicata in CLASS_LIFT la luminanta 0.82,
	# adusa pe culoarea slotului 13 (DRY_VEGETATION, 0.686/0.624/0.306).
	# Ridicarea e aleasa cat sa NU trebuiasca sa urce nimic din tenta —
	# multiplicatorul poate doar sa coboare, deci verdele si albastrul se
	# taie de aici, iar rosul ramane aproape neatins. Asa iese galben-oliv
	# dintr-o dala verde, fara un al doilea PNG.
	"macchia_dry": Color(1.0, 0.66, 0.54),
	# Betonul orasului: dupa ridicarea de mai sus dala e (198,189,170), iar
	# tinta (192,184,170). Tenta doar corecteaza restul, si e aproape 1.0 pe
	# toate canalele — asta E rezultatul dorit: clasa schimba TEXTURA, nu
	# culoarea. Fatada ramane exact griul care e azi pe ecran, dar capata
	# granulatie de beton in loc de suprafata plata.
	"city_concrete": Color(0.969, 0.975, 1.0),
	# Piatra veche: dala (153,149,137) coborata pe (137,139,137) — cenusiu
	# neutru. Ancorata pe canalul ALBASTRU, singurul mod in care tenta ramane
	# <= 1 pe toate canalele si nu mai e nevoie de nicio ridicare. Sub lumina
	# temei iese (59,63,74), R-B = -15: piatra rece de oras noaptea.
	"old_stone": Color(0.895, 0.933, 1.0),
	# garden_stone: masurat pe captura de joc (r3, cadrul-erou F). Atlas/old_stone:
	# fata luminata a bolovanilor ~(195, 170, 140); diorama ~(139, 119, 108), gri
	# mediu-cald. Prima tenta (0,64; 0,65; 0,77) dadea fata luminata (165, 144, 125)
	# dar umbrele VIOLET (68, 67, 81) sub ambientul rece; (0,54; 0,54; 0,56) le
	# facea carbune (58, 56, 57), (0,62; 0,60; 0,58) maro-inchis (96, 84, 68).
	# Albastrul tinut sub rosu (B/R ~0,95), luminozitatea spre tinta:
	"garden_stone": Color(0.84, 0.81, 0.80),
	# Valea Rosie: dala alpine_granite (166, 156, 137) impinsa pe rosul
	# caramiziu al referintei. Multiplicatorul NU e ales din ochi — e
	# masurat din docs/track_briefs/img/v3_crops/D_canyon.png (media zonei
	# de faleza: 136, 89, 65) impartit la media dalei. Toate cele trei
	# canale ies SUB 1, deci nu cere CLASS_LIFT.
	"red_valley_tuff": Color(0.822, 0.568, 0.479),
	# Gresia Monument Valley (#B8552E). CALIBRATA IN JOC, pe captura de joc (memoria
	# monocromia-se-masoara-dupa-remap), nu din socoteli pe dala. Prima tenta
	# (0.990, 0.486, 0.299, ridicare 0.672) era calculata in sRGB si multiplicarea
	# `albedo_color` x textura se face in spatiu LINIAR: pe captura iesea
	# (171, 48, 9) pe fata luminata, saturatie 0.95, B aproape zero — rosu de
	# cuptor, nu gresie, iar umbrele (111, 28, 4) erau negru-ruginiu.
	# Valorile de acum, masurate pe captura `--eye=210,60,230 --look=300,14,300`
	# (mediana pe patch-uri de perete, HSV): fata luminata (195, 88, 42) = #C3582A
	# (18 grade, 0.78, 0.76), jumatate de umbra (150, 65, 34) = #964122 (16 grade),
	# umbra (134, 52, 25). Tinta #B8552E = (184, 85, 46), 16 grade, 0.75, 0.72.
	# R ramane la 1.0: ridicarea (0.82) e cea care urca canalul, nu tenta.
	"mv_sandstone": Color(0.964, 0.592, 0.444),
	# Salvia (#8E977C = 142, 151, 124). Calculata in spatiu LINIAR (multiplicarea
	# `albedo_color` x textura e liniara; prima varianta, in sRGB, dadea albedo
	# (150, 140, 130) si pe captura frunzisul iesea albastru-cenusiu): dala
	# `macchia` ridicata la 0.72 are media liniara (0.31, 0.53, 0.21), tinta liniara
	# (0.27, 0.31, 0.20) => multiplicator liniar (0.87, 0.58, 0.95) = in sRGB
	# (0.93, 0.78, 0.97). Verificat apoi pe captura de joc.
	"mv_sage": Color(1.130, 0.920, 0.880),
	# Calota: tinta liniara (0.49, 0.35, 0.26) / dala ridicata la 0.70 => (0.955, 0.872, 0.861).
	"mv_cap": Color(0.900, 0.830, 0.800),
	# Calcarul Ryukyu (#CFC6B0 = 207,198,176). Dala `coral_rock` ridicata la 0.85
	# (CLASS_LIFT) are media liniara (0.676, 0.651, 0.670); tinta liniara e
	# (0.624, 0.565, 0.434) => multiplicator liniar (0.92, 0.87, 0.65) = in sRGB
	# (0.965, 0.94, 0.825). INCEPUT DE CALIBRARE, de masurat pe captura de joc.
	"ok_limestone": Color(0.988, 0.988, 0.945),
	# Olanele (#B8452E = 184,69,46). Dala `roof_tiles` ridicata la 0.60 are media
	# liniara (0.599, 0.303, 0.153); tinta liniara (0.479, 0.060, 0.027) =>
	# multiplicator liniar (0.80, 0.20, 0.18) = in sRGB (0.906, 0.48, 0.46).
	# TOATE canalele sub 1. INCEPUT DE CALIBRARE.
	"ok_roof": Color(0.630, 0.370, 0.480),
	# Transfagarasan: tentele se calculeaza ca (tinta liniara / media liniara a dalei), pe
	# canal, apoi in sRGB (`tools` de calibrare din commit-ul clasei). TOATE canalele sub 1.
	# Sist #7E8478 IN JOC (nu pe dala): soarele temei (#FFD9A8) taie albastrul. Masurat pe
	# vitrina, cu tenta (0.737, 0.817, 0.843) pe dala neridicata, sistul iesea (127,117,84)
	# = olive-cald, ratia fata de albedo (1.02, 0.77, 0.47) liniar. Albedoul cerut e deci
	# tinta / ratia = #7D95AA, iar B (0.40 liniar) e peste media dalei (0.276): dala ridicata
	# la 0.80 (CLASS_LIFT), apoi tenta (0.31, 0.50, 0.84) liniar. A doua trecere: (123,132,129)
	# pe captura, deci B -15% si R +5% liniar: (0.32, 0.50, 0.71).
	"tf_schist": Color(0.6030, 0.7327, 0.8597),
	# Jneapan #34503A: dala (0.150, 0.251, 0.061) -> (0.229, 0.320, 0.691).
	# Zidaria: tinta in joc #8E8C82 (gri neutru; cu dala neatinsa piatra iesea (150,127,91),
	# bej-maro sub soarele temei). Albedo #8D9EB7, dala ridicata la 0.80, tenta (0.41, 0.55, 0.91).
	"tf_stone": Color(0.6703, 0.7683, 0.9603),
	"tf_jneapan": Color(0.5160, 0.6011, 0.8495),
	# Fag #5E8A3A: dala ridicata la 0.50 (mai jos). Prima tenta (0.773, 0.923, 0.788) a dat in
	# joc (104,139,53) pe coroana, deci R prea mare si B prea mic: corectie liniara
	# (0.81, 0.98, 1.19) peste (0.559, 0.833, 0.584).
	"tf_beech": Color(0.7030, 0.9165, 0.8510),
	# Granitul Serengeti — valoare de INTEGRARE, nu a unui singur POI.
	# Sase bucati au masurat aceeasi clasa independent, pe capturi diferite:
	# A (0.50,0.56,0.68), B (0.56,0.60,0.68), C (0.520,0.578,0.723),
	# E (0.50,0.51,0.58), F (0.42,0.38,0.38), H (0.766,0.810,1.0).
	# Cinci din sase spun acelasi lucru: tenta veche (0.95,0.97,1.0) era o
	# corectie de NUANTA pe o dala deja deschisa, iar problema era VALOAREA —
	# bolovanii ieseau creta (S0.39 V0.83 masurat de C) fata de stanca din
	# referinta (S0.18 V0.53).
	# Mecanica, derivata de C si confirmata de restul: o tenta multiplicativa
	# nu desatureaza singura, doar scaleaza canalele. Ce le departeaza e
	# soarele cald (1.0, 0.90, 0.72), deci tenta corecta e INVERSUL lui,
	# normalizat ca sa nu urce valoarea: (1, 1/0.90, 1/0.72) scalat cu ~0.52.
	# Asta explica de ce A, B, C si E au aterizat toate pe acelasi vector
	# (albastrul canalul cel mai mare) pornind din capturi diferite.
	# F (cald si mai inchis) si H (deschis) raman notate ca dezacord de
	# masuratoare — se re-masoara pe capturile de integrare, pe POI-ul lor.
	"granite": Color(0.520, 0.578, 0.700),
	# Termitiere: dupa CLASS_LIFT (k=1.3483, mai jos) dala ajunge la
	# (189.7, 131.3, 78.5), tinta e (189.7, 116.4, 74.3). Tenta doar corecteaza
	# G si B in jos, ca la city_concrete — R ramane 1.0, canalul pe care
	# ridicarea a nimerit exact.
	"termite_clay": Color(1.0, 0.886, 0.947),
	# Scoarta acaciei-febra: dupa CLASS_LIFT (k=1.3642, mai jos) dala ajunge la
	# (234.3, 192.0, 146.9), tinta e slotul 0 SAND_LIGHT (232, 192, 116) —
	# chiar galbenul scoartei (masurat de lotul respins in valul 1). Raportul
	# target/dala pe canale, INAINTE de ridicare, e (1.351, 1.365, 1.077) —
	# PESTE 1 pe toate trei, deci nu se poate obtine dintr-un `albedo_color`
	# (doar intuneca): cere CLASS_LIFT, ca la tuff_cream/termite_clay. Tenta
	# doar corecteaza R si B in jos dupa ridicare; G ramane 1.0, canalul pe
	# care ridicarea (k = max al raportului) a nimerit exact.
	"bark_fever": Color(0.990, 1.0, 0.789),
	# Pielea elefantului: dala `concrete` (168.8, 160.7, 145.0) trasa spre
	# VOLCANIC_BLACK (85, 83, 90) — slotul CORPULUI (29), 88.7% din arie
	# masurata, deci tenta se calculeaza pe el, nu pe o medie ponderata cu
	# capul/picioarele (slot 2, doar 2.8%). Toate trei canale ies SUB 1
	# (0.503, 0.517, 0.621), deci nu cere CLASS_LIFT.
	#
	# Consecinta masurata pe capul/picioarele ramase pe slotul 2 (ASPHALT,
	# 75,75,77): aceeasi tenta unica le duce la (85,83,90) — diferenta fata de
	# tinta lor proprie e 18.25 in distanta euclidiana pe 0..255 (4.1% din
	# maximul posibil), adica tot un gri rece inchis, in aceeasi familie ca
	# ASPHALT, nu o pata straina. Acceptat: elefantul e UN nod, deci UN
	# material, iar 2.8% din arie (capul, urechile, picioarele) nu justifica
	# o a doua ruptura de accent pentru o diferenta sub prag de vizibilitate.
	"elephant_hide": Color(0.5034, 0.5165, 0.6206),
	# Pielea hipopotamului: dala `concrete` (168.84, 160.68, 145.01, medie
	# precisa cu PIL/numpy) trasa spre ROCK_DARK (#67421F, 103, 66, 31) —
	# slotul CORPULUI (4), 100% din arie masurata (tools/_tmp_probe_hippo1.gd,
	# script temporar, sters; hippo_back.glb e cel mai monocrom animal din kit,
	# fara accent de pastrat). Raport pe canale (0.6101, 0.4107, 0.2138) —
	# TOATE SUB 1, deci nu cere CLASS_LIFT. Verificare inversa (mean * tint):
	# (168.84*0.6101, 160.68*0.4107, 145.01*0.2138) = (103.00, 66.00, 31.00) —
	# cade EXACT pe tinta (103, 66, 31), sub 0.01 unitate pe fiecare canal.
	"hippo_hide": Color(0.6101, 0.4107, 0.2138),
	# Gneisul ud (Fiordland). Valoarea veche (0.8560, 0.8907, 1.0) fusese
	# calculata din sloturile de atlas VOLCANIC_BLACK/MARBLE_GREY MASURATE PE
	# .GLB (fiordland_masuratori.md), nu din randare — si a iesit GRI-ALBASTRUI
	# DESCHIS pe ecran (captura, nu presupunere: stirling_ledge.Wall citea
	# ~(95,106,116) pe fata spre soare), cu textura de scoarta a dalei
	# `alpine_granite` vizibila peste tot. Bara (bara_poi_C/B.png) cere gneis
	# INCHIS, aceeasi materie ca `scarp_tint` de pe pantele terenului (mai sus
	# in acest fisier era gresit sa duca la acelasi rezultat: scarp_tint e
	# vertex-color pe texturile de teren, "wet_gneiss" e CLASS_TINT peste o
	# dala complet diferita — cele doua mecanisme nu impart aceeasi curba de
	# lumina, deci un factor derivat matematic din scarp_tint (~0.29-0.36) a
	# iesit prea INCHIS la masurare (Wall mediu (29,33,34) pe fata din umbra,
	# fata de tinta (62,63,63)).
	#
	# A/B fortat (albedo_color -> (3.0, 0.05, 3.0), magenta absurd): a aratat
	# ca stirling_ledge.Wall SI torrent_chute.Rock ies amandoua magenta in
	# aceeasi captura, deci tinta chiar ajunge pe ambii consumatori.
	#
	# Valoarea finala (0.40, 0.40, 0.42) a fost gasita prin masurare directa pe
	# captura (--track=9 --frac=0.28 --gamecam), nu derivata: aproape neutra
	# (canalul B usor peste, ca sa pastreze raceala gneisului ud), suficient de
	# inchisa cat sa citeasca "stanca uda in umbra" (H191 S0.08, aproape de
	# masuratoarea din bara H199 S0.02), fara sa stinga complet dungile
	# verticale ale texturii `alpine_granite`.
	"wet_gneiss": Color(0.40, 0.40, 0.42),
	# Scoarta neagra a fagului: dala `bark` (171.7, 140.7, 107.7, medie exacta
	# PIL/numpy pe bark.png) trasa spre LOG_DARK (74, 53, 38) — trunchiul e
	# 100% pe slotul asta pe toate cele trei modele (beech_a/b/c), deci tinta
	# se calculeaza direct pe el, fara ponderare. Raport pe canale (0.4311,
	# 0.3767, 0.3529) — TOATE SUB 1, deci nu cere CLASS_LIFT. Verificare
	# inversa: (171.7*0.4311, 140.7*0.3767, 107.7*0.3529) = (74.0, 53.0, 38.0),
	# exact pe tinta.
	"bark_beech": Color(0.4311, 0.3767, 0.3529),
	# Coroana fagului: dala `acacia_canopy` (88.8, 108.2, 56.1) trasa spre
	# media ponderata pe arie a coroanei (Crown/Crown_001/Crown_002, masurat
	# probe_slots.gd): 56.3% TROPICAL_GREEN (63,122,60) + 43.7% LOG_DARK
	# (74,53,38) = (67.8, 91.8, 50.4). Raport pe canale (0.7639, 0.8490,
	# 0.8975) — TOATE SUB 1, nu cere CLASS_LIFT. Verificare inversa:
	# (88.8*0.7639, 108.2*0.8490, 56.1*0.8975) = (67.8, 91.8, 50.4), exact pe
	# tinta.
	"beech_canopy": Color(0.7639, 0.8490, 0.8975),
	# Lemnul ud (Fiordland, brief §4: "podetul, balustradele, pontonul —
	# WOOD_WEATHERED 9, ud = mai inchis"). Dala `wood.png` exista deja in
	# CLASS_TEXTURES (0.7 in CLASS_TRIPLANAR_SCALE) din pipeline-ul general,
	# dar pana acum n-avea niciun consumator in world_prop.gd — infrastructura
	# pregatita, niciodata cablata.
	#
	# Masurat (script temporar, sters): dala are media (124.14, 98.99, 71.72),
	# luminanta 0.401 (rec709). Slotul WOOD_WEATHERED (9, #835C34) e
	# (131, 92, 52), luminanta 0.382 — aproape identic cu dala, deci un simplu
	# multiplicator de potrivire ar fi cerut R usor PESTE 1 (raport 1.055),
	# adica CLASS_LIFT pentru un canal aproape neschimbat. Fiindca brief-ul
	# cere explicit mai INCHIS decat slotul uscat (nu potrivire cu el), tinta
	# s-a ales direct la 65% din valoarea slotului uscat — (85.15, 59.80, 33.80),
	# luminanta 0.248, o scadere de 35% fata de WOOD_WEATHERED uscat, in aceeasi
	# ordine de marime ca alte clase "ud"/umbrite ale pistei (`volcanic_rock`,
	# `wet_gneiss` fata de dala lor). Raportul tinta/dala pe toate trei canale
	# (0.686, 0.604, 0.471) e SUB 1, deci se obtine integral din CLASS_TINT,
	# fara CLASS_LIFT.
	# Clasa SEPARATA, nu tenta pe `wood`: `wood` e folosita deja pe Dunele/
	# Okinawa (moara, lazi, barca sabani, portalul minei — track.gd), iar o
	# tenta globala le-ar fi intunecat pe toate cu 35%. Aceeasi dala, cache
	# pe clasa: +1 material doar pe Track16.
	"wet_wood": Color(0.686, 0.604, 0.471),
	# --- Jodhpur (Track17): tente calculate pe dala EFECTIVA (dupa ridicare),
	# masurata cu tools/ProbeJodDale.tscn — tinta_c / dala_c pe canale, ca la
	# inca_stone / wet_gneiss. Tintele sunt culorile brief-ului §1/§4.
	# Varul albastru deschis #8FB0DC si indigo #4F6FB8, pe dala `plaster`
	# ridicata la 0.98 (masurat efectiv (1.000, 0.970, 0.866) — R retezat):
	"blue_lime_light": Color(0.561, 0.711, 0.997),
	"blue_lime_indigo": Color(0.310, 0.448, 0.834),
	# Gresia roz a fantanii #D4957A, pe dala `stone_wall` ridicata la 0.81
	# (masurat efectiv (0.824, 0.804, 0.742); R ramane cu 0.8% sub tinta, tenta
	# nu poate urca peste 1).
	# Gresia fortului: #B87466 efectiv (roz-teracota), NU #A5553A din brief.
	# Criticul orb a numit tenta de TREI ori pe POI E (portocaliu-rosu saturat,
	# uniform; tinta e roz-teracota cu buze mai deschise). Masurat pe masca
	# gresiei (scratchpad val1/e/hsv.py, frac 0.505 si 0.530, dusk 0): S
	# mediana 0,86-0,88 cu #A5553A (lumina calda de apus o satureaza), 0,64-0,67
	# cu #B87466, fata de 0,66 in bara E; V p90 0,72 -> 0,78 (bara 0,83).
	# Variantele A #B06A55 si C #A0604E ramaneau la 0,73-0,75. Aleasa de
	# coordonator (30 sep 2026). Muta si A (turnul, market_gate) si F
	# (bastionul, fatadele): clasa e folosita doar pe Jodhpur.
	"red_sandstone": Color(0.876, 0.566, 0.539),
	"rose_sandstone": Color(1.0, 0.726, 0.645),
	# Riolitul roz-brun #9A6A5A pe dala `alpine_granite` NERIDICATA
	# (0.650, 0.611, 0.534): toate trei rapoartele sub 1, deci fara
	# CLASS_LIFT si fara imagine noua in memorie.
	"rhyolite": Color(0.929, 0.681, 0.661),
	# --- Kyoto (Track18): tente CALCULATE, nu alese (tools in sesiunea 2 oct
	# 2026: scratchpad tints.py, reprodus in tools/probe_kyoto_frunzis.gd).
	# Metoda: Godot inmulteste in spatiu LINIAR (textura sRGB->liniar, albedo_color
	# la fel, rezultatul inapoi in sRGB), deci raportul simplu tinta/medie de pe
	# celelalte clase e usor gresit (~1-3%). Aici, pentru fiecare canal, tenta e
	# gasita prin bisectie pe pixelii reali ai dalei astfel incat media
	# imaginii randate (sRGB, cum o citeste un instrument de culoare) sa fie
	# EXACT tinta. Tintele sunt hex-urile sloturilor din brief §4.
	#
	# Dala neutra neridicata are media 195.2/255. Peste 195 un canal nu se poate
	# atinge doar din tenta: maple_crimson (R 187) si leaf_litter (R 168) se
	# incadreaza, maple_orange (R 229) si ginkgo_gold (R 242) NU — vezi
	# CLASS_LIFT. Chiar si ridicate (media 220.6 dupa taiere), R ramane cu
	# 3.7% sub tinta la portocaliu si 8.9% la auriu: ridicarea mai mare taie
	# luminile dalei (la 1.25x, 53% din pixeli sunt albi si frunzele dispar).
	# R=1.0 la ele inseamna "tenta nu mai poate", nu "aleasa".
	"maple_crimson": Color(0.9584, 0.2826, 0.1863),   # #BB3522
	"maple_orange": Color(1.0, 0.3318, 0.2642),       # #E54839 (R: 220.6 din 229)
	"ginkgo_gold": Color(1.0, 0.9434, 0.2777),        # #F2D03C (R: 220.6 din 242)
	"leaf_litter": Color(0.8626, 0.5400, 0.3079),     # #A8683A (LARCH_RUST 27)
	# Aceeasi tenta ca leaf_litter, alta scara (CLASS_TRIPLANAR_SCALE): coroana de
	# arțar ruginiu `momiji_c` (LARCH_RUST 27 in GLB).
	"maple_rust": Color(0.8626, 0.5400, 0.3079),      # #A8683A
	# Lime-ul frunzelor de bambus: media pixelilor verzi-galbeni (S>0.35, H 0.15-
	# 0.30) din decuparea `bamboo_crown.png` = (117, 145, 62) = #75913E. Aceeasi
	# bisectie in spatiu liniar ca mai sus, pe aceeasi dala neutra (verificata:
	# reproduce exact tenta lui maple_crimson). Nicio ridicare: toate canalele
	# sub media dalei (195).
	"bamboo_lime": Color(0.6055, 0.7467, 0.3281),     # #75913E
	# Lemn de machiya (74, 53, 38) pe dala `wood` (124.1, 99.0, 71.7), NERIDICATA:
	# toate canalele sub 1, nu cere CLASS_LIFT.
	"machiya_wood": Color(0.6171, 0.5707, 0.5841),
	# Muschi (63, 122, 60) pe dala `macchia` (86.7, 122.6, 73.3), NERIDICATA.
	"moss": Color(0.7520, 0.9954, 0.8392),
	# Valul de materiale Kyoto: aceeasi bisectie in spatiu liniar (verificata:
	# reproduce exact machiya_wood de mai sus). Tintele sunt sloturile GLB-urilor.
	# Kawara: VOLCANIC_BLACK 20 (85, 83, 90) pe dala `roof_tiles` (154.4, 113.4,
	# 82.1). B atinge plafonul (82.1 din 90): rezultatul e gri neutru, nu
	# albastrui. Prima versiune tintea media pe arie cu cei 15% de LOG_DARK 28
	# (83.4, 78.5, 82.2) si iesea MOV pe captura (R > G); slotul 28 nu e umbrire,
	# e coama si streasina (vezi CLASSES_BY_MODEL), deci nu intra in medie.
	"kawara": Color(0.5653, 0.7481, 1.0),
	# Trunchiuri: WOOD_WEATHERED 9 (131, 92, 52) pe dala `bark` (171.7, 140.7, 107.7).
	"bark_kyoto": Color(0.7690, 0.6680, 0.5173),
	# Cedri/pini: TROPICAL_GREEN 21 (63, 122, 60) pe dala `pine_needles`
	# (103.1, 131.4, 67.9).
	"cedar_needles": Color(0.6386, 0.9317, 0.8979),
	# Valul 2. Dala `wood` ridicata la luminanta 0.65 (CLASS_LIFT), apoi bisectia
	# obisnuita. R atinge plafonul la 200 din 232 (86%): lac invechit, cu 7.6%
	# din pixeli taiati. La 0.75 R ar ajunge 224, dar se taie 31.8% si fibra
	# dispare in luminile dalei — acelasi compromis ca la maple_orange.
	# LAVA_ORANGE 30 (232, 98, 45): torii, porti, pagode, altare.
	"shu_vermilion": Color(1.0, 0.6231, 0.4227),
	# CAR_RED 14 (229, 72, 57): trenul Sagano, podul de fier, umbrelele ceainariei,
	# ricsa, bavetele vulpilor. Aceeasi imagine ridicata (CLASS_LIFT_SHARED).
	"shu_red": Color(1.0, 0.4657, 0.5204),
	# CACTUS_GREEN 12 (91, 124, 52), aceeasi ridicare (imagine proprie, NErotita:
	# rosturile orizontale sunt nodurile tulpinii): atinsa exact.
	"bamboo_culm": Color(0.4630, 0.7804, 0.4797),
}

## Clasele a caror DALA trebuie luminata inainte de folosire, cu luminanta
## tinta (0..1). Exista fiindca `CLASS_TINT` e un multiplicator: poate doar sa
## intunece, iar unele clase reutilizeaza o dala mai INCHISA decat slotul pe
## care trebuie sa aterizeze.
##
## `village_plaster` e cazul: dala (gradata spre CONCRETE) are luminanta 0.557,
## iar varul satului sta pe FOAM_WHITE (0.941). Fara ridicare, casele se
## intunecau cu 44% — masurat pe captura, nu presupus.
##
## Se ridica MULTIPLICATIV si se retine contrastul relativ: nu e o spalare spre
## alb, e o schimbare de expunere. Ce depaseste 1.0 se retează, deci tinta se
## alege sub alb pur.
const CLASS_LIFT := {
	# Gresia Monument Valley: vezi CLASS_TINT (R tinta > media dalei).
	"mv_sandstone": 0.820,
	# Salvia: vezi CLASS_TINT (R tinta 142 > media dalei 86.7, deci ridicare).
	"mv_sage": 0.950,
	# Calcarul Ryukyu: dala `coral_rock` are luminanta 0.35 si trebuie sa ajunga
	# pe un crem deschis (#CFC6B0, 0.78). Vezi CLASS_TINT.
	"ok_limestone": 0.850,
	# Olanele Ryukyu: R tinta (0.479 liniar) e peste media dalei `roof_tiles`
	# (0.357), deci tenta singura nu ajunge. Vezi CLASS_TINT.
	"ok_roof": 0.600,
	# Sistul Transfagarasan: vezi CLASS_TINT.
	"tf_schist": 0.800,
	"tf_stone": 0.800,
	# Fagul Transfagarasan: G tinta (0.254 liniar) e peste media dalei (0.182), deci ridicare.
	"tf_beech": 0.500,
	"village_plaster": 0.88,
	# Tufarisul uscat: dala lui `macchia` are luminanta 0.417 si trebuie sa
	# ajunga pe slotul 13 (0.606). Ridicarea e insa la 0.82, nu la 0.606:
	# tinta se atinge DUPA tenta de mai sus, care coboara doua canale din trei.
	# Calculata, nu aleasa — k = max(slot_c / dala_c) pe canale.
	"macchia_dry": 0.82,
	# Betonul orasului: dala lui `concrete` are luminanta 0.634 si trebuie sa
	# ajunga pe media sloturilor 8/29 (0.726). Ridicarea e k = max(tinta_c /
	# dala_c) pe canale = 1.1724, adica exact cat sa NU mai trebuiasca sa urce
	# nimic din tenta — calculata, nu aleasa, ca la macchia_dry.
	"city_concrete": 0.743,
	# Tuful crem: dala alpina are luminanta 0.600 si trebuie sa ajunga pe media
	# PONDERATA PE ARIE a sloturilor pe care stau hornurile DUPA `TUFF_UV_REMAP`
	# — 52.5% CORAL_SAND (19), 31.2% MARBLE_GREY (29), 9.5% slot 20 si 6.8%
	# CONCRETE (8), adica (0.790, 0.754, 0.684), luminanta 0.757.
	#
	# Ridicarea e la 0.791, nu la 0.757, si din acelasi motiv ca la macchia_dry:
	# tinta se atinge DUPA tenta, care coboara doua canale din trei. Calculata
	# ca k = max(tinta_c / dala_c) pe canale = 1.3140.
	#
	# Ponderea pe ARIE si nu un slot ales cu ochiul: hornurile nu sunt „crem",
	# sunt crem SI gri-cald in benzi de valoare, iar o clasa care aterizeaza pe
	# slotul 19 curat le-ar fi facut cu 15% mai palide decat sunt azi.
	"tuff_cream": 0.791,
	# Termitiere: dala `rock` are luminanta 0.407 si trebuie sa ajunga pe media
	# ponderata a sloturilor 23/27 (0.506). Ridicarea e la 0.549, nu la 0.506,
	# din acelasi motiv ca la macchia_dry/tuff_cream: tinta se atinge DUPA
	# tenta, care coboara doua canale din trei. k = max(tinta_c / dala_c) pe
	# canale = 1.3483 (canalul R e cel care nimereste exact).
	"termite_clay": 0.549,
	# Zidaria incasa: dala `alpine_granite` are luminanta 0.6017 si trebuie sa
	# ajunga pe media ponderata pe arie a sloturilor de zidarie (0.5762).
	# Ridicarea e la 0.6704, nu la 0.5762, din acelasi motiv ca la
	# macchia_dry / tuff_cream / termite_clay: tinta se atinge DUPA tenta,
	# care coboara doua canale din trei. k = max(tinta_c / dala_c) = 1.1142.
	"inca_stone": 0.6704,
	# Gneisul ud (Fiordland): dala `alpine_granite` luminanta 0.6147 (rec709
	# pe 166,156,137), tinta masurata 0.5554. Raportul pe canale are un
	# singur canal peste 1 (B, 1.0155), deci ridicarea e mica — k = 1.0155,
	# nu media directa a luminantelor (acelasi motiv ca la inca_stone/
	# termite_clay: tinta se atinge DUPA tenta CLASS_TINT).
	"wet_gneiss": 1.0155,
	# Scoarta acaciei-febra: dala `bark` are luminanta 0.568 (rec709) si
	# trebuie sa ajunga pe slotul 0 SAND_LIGHT (232, 192, 116), luminanta
	# 0.749. Ridicarea e la 0.775, nu la 0.749, din acelasi motiv ca la
	# macchia_dry/tuff_cream/termite_clay: tinta se atinge DUPA tenta, care
	# coboara doua canale din trei. k = max(tinta_c / dala_c) pe canale =
	# 1.3642 (canalul G e cel care nimereste exact — masurat cu
	# tools/_tmp_probe_bark_fever.gd, esantionare 128x128 din bark.png:
	# media (171.72, 140.74, 107.71), la 0.03-0.07% de valorile citate in
	# nota de respingere a valului 1).
	"bark_fever": 0.775,
	# --- Jodhpur (Track17), masurat cu tools/ProbeJodDale.tscn -------------
	# Varul albastru: dala `plaster` (0.593, 0.552, 0.492) e CALDA, iar tinta
	# #8FB0DC are albastrul la 0.863. Chiar ridicata ca `village_plaster`
	# (0.88 -> B 0.776) raportul pe B ramane 1.11 > 1, deci tenta n-ar ajunge
	# niciodata pe albastru. La 0.98 canalul B ajunge la ~0.87 si tenta il
	# poate cobori exact pe tinta; R se reteaza la 1.0 (detaliul varului ramane
	# in G/B, exact canalele care conteaza pe o casa albastra). Indigo
	# imparte ACEEASI imagine ridicata (CLASS_LIFT_SHARED): o singura dala in
	# memorie pentru amandoua tentele.
	"blue_lime_light": 0.98,
	# Gresia: dala `stone_wall` (0.598, 0.582, 0.535). Tinta cea mai deschisa
	# e gresia roz a fantanii #D4957A: raport R 1.39 -> ridicare la
	# 0.582 x 1.39 = 0.81. Gresia rosie a fortului (#A5553A) imparte aceeasi
	# imagine si coboara din tenta.
	"rose_sandstone": 0.81,
	# Kyoto: frunzisul portocaliu si cel auriu cer R 229/242, iar dala neutra are
	# media 0.7656 (lum). Ridicare 1.15x (L = 1.15 * 0.7656 = 0.8805): media dupa
	# taiere 220.6, 28% din pixeli taiati. Mai mult nu: la 1.25x jumatate din
	# dala e alba. Auriul ramane cu R sub tinta (vezi CLASS_TINT). `ginkgo_gold`
	# imparte imaginea (CLASS_LIFT_SHARED); maple_crimson/leaf_litter NU se
	# ridica — folosesc dala originala.
	"maple_orange": 0.8805,
	"shu_vermilion": 0.65,
	"bamboo_culm": 0.65,
}

## Clasele a caror dala ridicata se ROTESTE cu 90 de grade. Triplanarul pune dala
## `wood` cu scandurile ORIZONTALE pe fetele verticale: pe tulpina de bambus
## rosturile se citesc noduri (corect), dar pe stalpul unei porti torii il fac
## sa para din discuri stivuite (captura f0.50 pe tunel). Rotita, fibra urca pe
## stalp. Doar pe clase cu CLASS_LIFT: rotirea se face pe imaginea deja copiata.
const CLASS_LIFT_ROTATE := {
	"shu_vermilion": true,
}

## Clasele care se aplica TRIPLANAR in spatiul lumii, pe assets cu UV-uri
## colapsate — zero re-export (mecanica validata de rock_material). Scara e
## per clasa: rugina se repeta mai des decat straturile de roca.
const CLASS_TRIPLANAR_SCALE := {
	# 0.2 -> 0.14 la trecerea pe fotografie: striatiile lui cliff_side sunt
	# mai fine decat benzile trim-ului pictat, iar la 5 m/repetitie se topeau
	# in mipmap. La ~7 m, un strat citeste cat un strat.
	"rock": 0.14,
	# Aceeasi scara ca "rock": e aceeasi dala, doar alta tenta.
	"volcanic_rock": 0.14,
	"rust_metal": 0.45, # o repetitie la ~2.2 m — panouri, nu strate
	# Frescele: o repetitie la ~3.2 m. Dala tine DOUA registre pe inaltime
	# (tools/paint_fresco.py §2), deci un registru masoara 1.6 m — inaltimea
	# unui panou pictat real, si aproape exact inaltimea benzii de pe pilastrul
	# arcadei (0.55 m x scara 2.3 = 1.27 m in lume la `arcadas2_*`). La o scara
	# mai mare motivele ar fi cazut sub un pixel de la 12 m, distanta camerei de
	# joc; la una mai mica un singur medalion ar fi acoperit tot pilastrul si
	# textura ar fi citit ca o pata, nu ca o pictura.
	"fresco": 0.31,
	# Sursa e o scanare de 1.1 m; la 1.18 m/repetitie scobiturile de calcar cad
	# aproape la scara reala, iar o stanca de recif de 1.6-4 m prinde 1.5-3.5
	# repetitii — destul cat tiparul sa nu se citeasca ca tapet.
	"coral_rock": 0.85,
	# Sursa e o dala de 2 m de sisturi. La 0.16 (o repetitie la 6.25 m) un
	# strat de piatra citeste cat un strat pe o stanca de 2-4 m, exact ca la
	# `rock` — aceeasi familie de geologie, alta piatra.
	"alpine_granite": 0.16,
	# Gneisul ud (Fiordland): ACEEASI dala si ACEEASI scara ca alpine_granite
	# — familie de geologie identica (sisturi/gneis stratificat), doar tenta
	# diferita. stirling_ledge.Wall (26.57 m inaltime) e mai mare decat
	# faleza alpina de referinta, dar la 0.16 (o repetitie la 6.25 m) tot
	# citeste ca strat de piatra la distanta de care trece masina (3-5 m),
	# nu ca tapet intins pe un perete de 26 m.
	"wet_gneiss": 0.16,
	# Valea Rosie: dala se intinde de DOUA ori mai mult decat pe Alpi
	# (0.08 fata de 0.16). Modulul are 12.4 m inaltime: la scara alpina ar
	# fi incaput ~2 randuri de sedimente pe toata faleza, adica desen prea
	# mare ca sa citeasca a straturi. La 0.08 intra de doua ori mai multe
	# benzi, deci fiecare treapta de 12 m arata ca un teanc de straturi,
	# nu ca doua dungi.
	"red_valley_tuff": 0.08,
	# Gresia Monument Valley: aceeasi scara ca faleza rosie (aceeasi dala).
	"mv_sandstone": 0.065,
	# Salvia: ca `macchia` (aceeasi dala, tufe de ~1 m).
	"mv_sage": 1.4,
	# Calota: aceeasi scara ca gresia (aceeasi dala).
	"mv_cap": 0.065,
	# Calcarul Ryukyu: dala de 1.1 m ca `coral_rock` (0.85), dar zidurile gusuku au
	# 8 m: la 0.85 o fata prinde 7 repetitii pe inaltime si se citeste tapet.
	# Mai rar (o repetitie la 1.7 m) cratere mai late, tot la scara de bolovan.
	"ok_limestone": 0.6,
	# Olanele: ~26 coloane de tigla pe repetitie. La 0.2 (5 m) coloana are ~0.19 m,
	# aproape de nervurile de 0.2 m modelate in geometrie (`Gate_Roof`).
	"ok_roof": 0.2,
	# Transfagarasan. Sistul: ca `alpine_granite`/`wet_gneiss` (o repetitie la ~6 m).
	"tf_schist": 0.16,
	# Zidaria: o repetitie la ~2.5 m — pietre cat o piatra de zid, nu cat un bloc.
	"tf_stone": 0.4,
	"tf_jneapan": 0.6,
	# Ca `beech_canopy` (aceeasi dala pictata, lobi la ~20 m/repetitie).
	"tf_beech": 0.05,
	# ACEEASI scara ca faleza rosie, si nu din lene: hornurile masoara 11-18 m
	# pe verticala (masurat pe cele 12 .glb-uri — chimney_a 11.3, chimney_c 17.3,
	# triple 18.5, twin_gate 21.6), adica exact plaja modulului de faleza de
	# 12.4 m pentru care s-a reglat 0.08. Un horn si peretele de langa el sunt
	# acelasi corp sedimentar; daca stratele ar avea alta densitate pe fiecare,
	# s-ar citi ca doua geologii lipite — chiar defectul pe care proiectia de
	# LUME il evita facand benzile sa curga continuu dintr-o piesa in vecina.
	"tuff_cream": 0.08,
	# Masa avalansei. Sursa e o scanare de teren de ~2 m; la 0.3 (o repetitie
	# la 3.3 m) un corp de 7 m prinde ~2 repetitii — destul cat crustele si
	# urmele sa se citeasca la rostogolire, prea putin cat sa devina tapet.
	#
	# Se aplica IN SPATIUL OBIECTULUI (`apply_object_triplanar_class`), nu al
	# lumii: masa se rostogoleste, iar proiectia de lume i-ar face textura sa
	# stea pe loc in timp ce corpul se invarte pe sub ea — adica exact
	# contrariul lucrului pentru care am pus textura.
	"snow": 0.3,
	# Acele coniferelor. Sursa e pictata la ~1 m/dala (ramurele de 5-10 cm,
	# ace de 1-2 cm), dar la 1.0 (scara reala) coroana iesea GRANULATA pe
	# captura de sofer — la 10-15 m un ac e sub un texel si ramane zgomot.
	# La 0.6 (o repetitie la 1.67 m) ramurelele au 8-16 cm si smocurile
	# 25-40 cm: se citesc ca ramuri de la distanta de joc, iar un etaj de
	# 2.6 m prinde ~1.5 repetitii, destul cat tiparul sa nu se vada. Proiectie
	# in spatiul LUMII (brazii nu se misca): un singur material pentru toata
	# padurea, oricate scari ar avea instantele.
	"pine_needles": 0.6,
	# Frunzisul mediteranean. Sursa e pictata la ~1 m/dala (buchete de 20-30 cm,
	# frunze de 1-3 cm), dar piesele pe care cade sunt MULT mai mici decat un
	# molid: o tufa de caper are 0.6 m, una de ginestra ~1.2 m, coroana unui
	# maslin ~2.5 m. La scara acelor (0.6, adica o repetitie la 1.67 m) o tufa
	# intreaga ar fi prins jumatate de dala si ar fi iesit o pata de frunze
	# uriase — exact greseala inversa fata de cea din #222.
	#
	# La 1.4 (o repetitie la 0.71 m) buchetele au 14-21 cm si frunzele 1-2 cm:
	# o tufa de ginestra prinde ~1.7 repetitii, un maslin ~3.5. Adica fiecare
	# piesa vede tiparul intreg de macar o data, iar de la distanta de joc
	# (10-25 m) frunzele se topesc in mipmap si ramane variatia de valoare —
	# tocmai ce lipsea. Proiectie in spatiul LUMII (plantele nu se misca):
	# un singur material pentru tot frunzisul pistei.
	"macchia": 1.4,
	# Aceeasi scara ca frunzisul verde: e aceeasi dala, doar alta tenta.
	"macchia_dry": 1.4,
	# Gheata Baikalului. Dala pictata reprezinta ~6 m (celule de crapaturi de
	# ~1 m, bule de 5-15 cm): la 0.16 (o repetitie la 6.25 m) crapaturile mari
	# citesc ca fisuri de un metru din chase cam, iar tiparul nu se vede ca
	# tapet pe placa de 200 m — variatia mare o dau culorile de vertex
	# (adancimea, vezi Track._ice_color). Spatiul LUMII: placa nu se misca.
	"ice": 0.16,
	# Piesele de gheata: la scara lacului un toros de 1.5 m cadea intre
	# crapaturi si iesea o dala goala. La 0.55 (o repetitie la 1.8 m) un
	# bloc prinde o celula de crapaturi si cateva bule — se citeste ca
	# gheata sparta de la distanta de joc.
	"ice_bloc": 0.55,
	# Marmura Olkhonului: 0.09 = o repetitie la ~11 m, adica SCARA REALA a
	# sursei (12.7 m) cu 12% mai mica. Regula 1 din pipeline (scara sursei
	# fata de repetitia din joc) e singura care conteaza aici: piesele au
	# 12-22 m, deci fata dinspre drum a unui colt prinde aproape exact o
	# repetitie — vinele si stratele fotografiei se citesc ca geologie, nu ca
	# tipar care se repeta.
	"olkhon_marble": 0.09,
	# Granitul Serengeti: aceeasi dala ca olkhon_marble, aceeasi scara —
	# world triplanar, ca stratele sa curga din bolovan in kopje.
	"granite": 0.09,
	# Zidaria taiata: 0.5 = o repetitie la 2 m, adica SCARA REALA a sursei.
	# Blocurile din fotografie ies atunci la 20-40 cm, randurile din geometrie
	# sunt la 0.9 m: doua scari de zidarie care se sprijina una pe alta, exact
	# ca la o pila reala. La scara alpina (0.16, 6.25 m) blocurile ar fi de
	# 1-1.2 m — zidarie ciclopica, alt fel de constructie.
	"cut_stone": 0.28,
	# Zidaria incasa: ACEEASI scara ca `cut_stone`, si nu din lene — 0.28
	# inseamna o repetitie la ~3.6 m, iar blocurile kitului masoara 4.00 m
	# (inca_wall_a) si 6.00 m (inca_wall_b) pe lungime, cu 2.49 m inaltime:
	# un zid prinde ~1.1-1.7 repetitii, adica rosturile se citesc ca blocuri
	# potrivite, nu ca tapet. E chiar scara de zidarie reala pentru care a
	# fost reglat `cut_stone` pe viaductul Baikalului, la alta culoare.
	"inca_stone": 0.28,
	# --- Clasele insulei vulcanice (Stromboli) ----------------------------
	#
	# Toate patru exista deja ca dale, dar pana acum DOAR pe UV-uri reale
	# (`class_material`). Pe kitul Stromboli asta nu se putea folosi: masurat
	# pe toate cele 36 de GLB-uri, UV-urile sunt colapsate pe un punct
	# (u_min == u_max, iar v e 0.5000 peste tot), deci un material pe UV ar
	# citi UN texel si fata ar ramane exact la fel de plata ca pe atlas. De
	# aceea intrarile de aici sunt scari TRIPLANARE, nu clase noi: acelasi
	# PNG, aceeasi textura in VRAM, alta proiectie.
	#
	# Tencuiala satului eolian. Sursa e o dala de perete de ~2 m; la 0.55 (o
	# repetitie la 1.8 m) un zid de 3 m prinde ~1.7 repetitii si o casa de 7 m
	# vreo patru — destul cat varul sa aiba pete si rosturi, prea putin cat
	# tiparul sa se citeasca ca tapet pe fatade care stau una langa alta.
	# Mai fin ar fi gresit in mod specific aici: satul e MASA ALBA a pistei,
	# iar o textura care se repeta des pe zeci de fatade citeste imediat ca
	# tipar, nu ca var.
	"plaster": 0.55,
	# Varul satului: aceeasi scara ca `plaster` (aceeasi dala), doar ridicata
	# si racita. Vezi CLASS_LIFT / CLASS_TINT.
	"village_plaster": 0.55,
	# Betonul danei din Ginostra si al parapetilor. Aceeasi scara ca
	# tencuiala, si din acelasi motiv — sursa e tot o suprafata de ~2 m — dar
	# clasa ramane separata fiindca ancora ei e ridicata cu `lift` 0.20
	# (vezi process_class_textures.gd): dana trebuie sa ramana mai rece si mai
	# inchisa decat varul de deasupra ei, altfel portul devine o singura pata.
	"concrete": 0.5,
	# Betonul orasului: aceeasi scara ca `concrete` — e aceeasi dala, si cade
	# pe acelasi fel de suprafata. La 2 m/repetitie un perete de fatada de
	# 5.8 m prinde ~2.9 repetitii: destul cat granulatia sa se citeasca la
	# viteza, prea putin cat sa devina tapet (style_bible §4).
	"city_concrete": 0.5,
	# Pielea elefantului: ACEEASI scara ca `concrete`/`city_concrete`, NEDERIVATA
	# din marimea elefantului (4.66 m inaltimea corpului, masurat pe .glb cu
	# tools/_tmp_probe_elephant2.gd) ci din distanta de DECORELARE a detaliului
	# fin al dalei — masurata cu diferenta medie absoluta intre pixeli la
	# distanta d (tools/_tmp_probe pentru autocorelatie, script temporar,
	# sters): curba urca abrupt si se aplatizeaza la d~=19px din 512, adica
	# 3.71% din dala. La scara EXISTENTA a lui `concrete` (o repetitie la 2 m,
	# nota de mai sus), 3.71% * 2 m = 7.4 cm — in banda 5-15 cm pe care
	# style_bible/brief o cere pentru increiturile pielii de elefant.
	# Rescalarea ar fi rezolvat o problema care nu exista: pastrarea scarii
	# lui `concrete` nimereste deja tinta, fara nicio derivare suplimentara.
	"elephant_hide": 0.5,
	# Pielea hipopotamului: ACEEASI dala ca `elephant_hide` (`concrete`), dar
	# scara NU e copiata orbeste — brief-ul cere increturi mai MARI si mai
	# RARE decat la elefant. Derivat din decorelarea texturii, ca la
	# `elephant_hide`, dar cu o tinta de granulatie explicit mai mare:
	# autocorelatie (diferenta medie absoluta intre pixeli la distanta d,
	# tools/_tmp_probe_hippo_auto.gd, script temporar, sters) pe dala nativa
	# 512x512 da platoul (90%) la d~=40px, adica 7.81% din dala — fata de
	# 3.71% masurat pentru elefant (metode comparabile dar nu identice, deci
	# cifrele nu se cumuleaza direct; foloseste-le doar comparativ, in ACELASI
	# fel de masuratoare).
	# Tinta explicita pentru hipopotam: banda 15-25 cm (fata de 5-15 cm la
	# elefant — de 2-3x mai mare, cum cere brief-ul), mijloc 20 cm. Scara:
	# 0.0781 / 0.20 = 0.391, rotunjit la 0.4 (1 repetitie la 2.5 m, fata de
	# 1 repetitie la 2 m pe elefant — grain mai rar SI mai mare pe animalul
	# mai mic, exact directia ceruta).
	"hippo_hide": 0.4,
	# Zidaria scarilor Shibati. `stone_wall` avea textura si ancora, dar NU si
	# o scara triplanara — se folosea doar pe UV-uri reale. Kitul Chongqing are
	# UV-urile colapsate (ca Stromboli), deci ii trebuie una.
	# 0.35 = o repetitie la 2.86 m: pe scara de 10x12 m intra ~4 randuri de
	# zidarie pe latime, adica se citeste ca zidarie si nu ca tapet.
	"old_stone": 0.35,
	"garden_stone": 0.35,
	# Lemnaria: bena tricicletei Ape, busteni de rulare, bordaj. Sursa e o
	# scanare de scanduri; la 0.7 (o repetitie la 1.43 m) fibra cade aproape
	# la scara reala pe piese de 1-3 m. Prim consumator REAL (Fiordland,
	# `driftwood` 4,03 m si tabliera `WoodDeckStrip` a podetului Chasm,
	# scanduri de ~1,5-2 m): scara ramane neschimbata, era deja gandita pentru
	# exact plaja asta.
	"wood": 0.7,
	"wet_wood": 0.7,
	# Trunchiuri de maslin si de smochin. Sursa `bark` e o scanare de 1.3 m de
	# trunchi, deci 0.77 (o repetitie la 1.3 m) e SCARA REALA — cicatricile
	# cad exact cat sunt. Regula 1 din pipeline (scara sursei fata de
	# repetitia din joc, style_bible §4).
	"bark": 0.77,
	# Scoarta acaciei-febra: ACEEASI scara ca `bark` (0.77), verificata pe
	# piesa, nu copiata orbeste. Masurat pe geometria fever_tree.glb
	# (tools/_tmp_probe_bark_fever.gd, vertecsii pe slot 0 cu y <= 0.15/0.5/
	# 1.0 m — stabil pe toate trei benzile): trunchiul are 0.648 m diametru
	# la baza. Acaciile-umbrela (deja pe `bark` la 0.77, nicio plangere de
	# scara) masoara 0.570-0.686 m la baza (tools/_tmp_probe_trunks.gd) —
	# fever_tree cade CHIAR IN mijlocul acelui interval, deci scara sursei de
	# 1.3 m/repetitie ramane la fel de potrivita ca pe acaciile-umbrela. Nu
	# exista o masuratoare care sa ceara alta cifra.
	"bark_fever": 0.77,
	# Scoarta neagra a fagului (Fiordland): ACEEASI scara ca `bark` (0.77,
	# repetitie la 1.3 m REALA — scara SURSEI, nu a piesei, regula #2 din
	# `clase-pe-piese-de-kit`). Trunchiurile de fag masoara 1.54-2.06 m
	# diametru la baza (raza 0.77-1.03 m, probe_slots.gd) — mai groase decat
	# acaciile-umbrela/fever_tree (0.57-0.69 m), dar aceeasi fotografie de
	# scoarta ramane aceeasi fotografie de scoarta oriunde e proiectata: la
	# 0.77 un trunchi de 2 m prinde ~1.5 repetitii, destul cat cicatricile sa
	# se citeasca fara sa devina tapet. Nicio masuratoare de aici nu cere alta
	# cifra.
	"bark_beech": 0.77,
	# Coroana fagului (Fiordland): ACEEASI scara ca `acacia_canopy` (0.05,
	# repetitie la 20 m) — clasa e derivata din aceeasi dala PICTATA, cu
	# aceeasi logica de "bulgare de frunzis" (lobii mastii de densitate sunt o
	# PROPORTIE a dalei, nu o marime fizica masurata). Coroanele de fag
	# (5.1-9.55 m diametru, probe_slots.gd) si Rata (4.29 m) sunt in acelasi
	# ordin de marime ca acaciile-umbrela/fig_tree (7-13 m) pentru care scara a
	# fost aleasa — un lob la 20 m/repetitie cade tot in banda 1.2-2.6 m,
	# "bulgare" vizibil, nu o pata cat toata coroana si nu tapet.
	"beech_canopy": 0.05,
	# Termitiere (Serengeti): scara DERIVATA din piesa, nu copiata de la `rock`
	# (0.14, calibrata pe faleze de 6-12 m). Cele doua modele masoara 1.5 m
	# (termite_mound_a) si 3.0 m (termite_mound_b) pe verticala
	# (tools/probe_slots.gd). La 0.14 movila mare ar fi prins ~0.4 repetitii —
	# sub o singura banda, adica exact defectul "zid de 2 m pe stanca de 18 m"
	# din memoria `clase-pe-piese-de-kit`, doar inversat (dala prea RARA pe o
	# piesa mica). Tinta: ~2 repetitii pe movila de 3 m (ca 1 pe cea de 1.5 m),
	# adica o repetitie la 1.5 m -> scara 0.65 (rotunjit de la 0.667).
	"termite_clay": 0.65,
	# Coroana savanei (Serengeti): acaciile-umbrela, fever_tree, fig_tree,
	# euphorbia. Sursa e PICTATA, nu fotografiata (ca ace/macchia), deci n-are
	# o scara "reala" de masurat — lobii ei de densitate (`_clump_mask` in
	# tools/paint_acacia_canopy.py, raza 60-130 din 1024) sunt o PROPORTIE a
	# dalei, nu un desen la o dimensiune fizica.
	#
	# 0.05 = o repetitie la 20 m. Aleasa din marimea coroanei, nu din ochi:
	# acaciile-umbrela au 7-10 m (brief §14), fig_tree/fever_tree ajung la
	# 12-13 m pe verticala (probe_slots.gd: fig_tree y 7.04..13.00). Un lob de
	# masca (6-13% din dala, la 20 m/repetitie) cade atunci la 1.2-2.6 m —
	# marimea unui "bulgare" vizibil de frunzis din referinta
	# (docs/asset_briefs/img/serengeti_plants.png), nu o pata cat toata
	# coroana si nu un tipar sub-metru care s-ar citi ca zgomot. Proiectie in
	# spatiul LUMII: copacii nu se misca, si benzile de valoare curg continuu
	# intre coroanele vecine dintr-o padure deasa (POI D), exact ca la
	# `pine_needles` pe un rand de brazi.
	"acacia_canopy": 0.05,
	# --- Jodhpur (Track17) ---------------------------------------------
	# Varul albastru: ACEEASI scara ca `village_plaster` (aceeasi dala de
	# tencuiala, ~1.8 m pe repetitie) — o casa de 7 m prinde ~4 repetitii,
	# destul pentru pete si scurgeri, prea putin ca tiparul sa citeasca tapet.
	"blue_lime_light": 0.55,
	"blue_lime_indigo": 0.55,
	# Gresia fortului si a fantanii: ACEEASI scara ca `old_stone` (aceeasi
	# dala de blocuri `stone_wall`) — blocurile au marimea unor asize de zid
	# (~2.9 m pe repetitie), nu de pietre de caldaram.
	"red_sandstone": 0.35,
	"rose_sandstone": 0.35,
	# Riolitul: dala stratificata `alpine_granite` la scara ei (0.16), ca la
	# `red_valley_tuff` / `wet_gneiss` — aceeasi familie de stanca.
	"rhyolite": 0.16,
	# --- Kyoto (Track18) ---
	# Frunzisul: o repetitie la 10 m (0.1). O frunza din dala (~25 px din 512)
	# e ~0.5 m, un palc ~1.5-2 m, un golf intunecat ~3 m: o coroana de arțar de
	# 8-10 m prinde ~1 repetitie. De la 12 m (camera) frunza are ~35 px.
	"maple_crimson": 0.1,
	"maple_orange": 0.1,
	"ginkgo_gold": 0.1,
	# Covorul de frunze: acelasi PNG la scara de 2.5x mai deasa (o repetitie la
	# 4 m, frunza ~20 cm — frunze cazute pe sol, nu coroana).
	"leaf_litter": 0.25,
	"maple_rust": 0.1,
	# Frunza de bambus e ingusta si deasa: scara covorului (frunza ~20 cm), nu a
	# coroanei de arțar.
	"bamboo_lime": 0.25,
	# Aceeasi scara ca dala-sursa (`wood` 0.7, `macchia` 1.4).
	"machiya_wood": 0.7,
	# Kawara: dala are ~26 de coloane de tigla pe latime. La 0.15 o repetitie
	# acopera 6.7 m, deci coloana ~0.26 m: tigla de jucarie, citita la 10-30 m.
	"kawara": 0.15,
	# Aceeasi scara ca dalele-sursa (`bark` 0.77, `pine_needles` 0.6).
	"bark_kyoto": 0.77,
	"cedar_needles": 0.3,
	# Scara dalei-sursa (`wood` 0.7).
	"shu_vermilion": 0.7,
	"shu_red": 0.7,
	# Bambus: la 0.5 rosturile dalei (6 scanduri pe repetitie) cad la ~0.33 m,
	# cat distanta dintre nodurile unei tulpini moso — se citesc ca noduri.
	"bamboo_culm": 0.5,
	"moss": 1.4,
}

## Ascutimea amestecului triplanar, pe clasele unde implicitul (1.0) strica
## tiparul. La 1.0 o fata la 45 de grade ia 50/50 din doua proiectii, deci doua
## seturi de frunze suprapuse decalat: conturul lobat se dubleaza si se topeste
## in pata (masurat din camera de joc pe coroanele de arțar, oct 2026). Coroana
## e o icosfera zimtata, cu fete in toate directiile, deci cazul e peste tot.
## La 8 fiecare fata ia practic o singura proiectie; cusatura dintre proiectii
## cade pe muchia dintre fete, unde umbrirea plata o ascunde oricum.
const CLASS_TRIPLANAR_SHARPNESS := {
	"maple_crimson": 8.0,
	"maple_orange": 8.0,
	"maple_rust": 8.0,
	"ginkgo_gold": 8.0,
}

## Umbrire NETEDA pe coroanele de frunzis (aceleasi clase ca mai sus). Coroana e
## din icosfere zimtate cu umbrire plata: fiecare fata e o placa de lumina, deci
## ciorchinele se citeste „piatra sparta", nu frunzis. Normalele mediate pe pozitie
## fac lumina sa curga peste ciorchine, iar detaliul il duce textura. Zero
## triunghiuri in plus; trunchiurile raman cu fatete. Comutator pentru A/B la volan.
const SMOOTH_FOLIAGE := true

static var _smoothed_meshes: Dictionary = {}

static func is_smooth_foliage(cls: String) -> bool:
	return SMOOTH_FOLIAGE and CLASS_TRIPLANAR_SHARPNESS.has(cls.trim_prefix(TRI_PREFIX))

## Suprafetele unui mesh care poarta un material de coroana (gol daca
## SMOOTH_FOLIAGE e stins).
static func foliage_surfaces(mesh: Mesh) -> Dictionary:
	var out := {}
	if not SMOOTH_FOLIAGE or mesh == null:
		return out
	for si in mesh.get_surface_count():
		for cls in CLASS_TRIPLANAR_SHARPNESS:
			if mesh.surface_get_material(si) == triplanar_class_material(cls):
				out[si] = true
	return out

## Copie a mesh-ului cu normale mediate pe pozitie (cuantizata la 5 mm), pe
## suprafetele din `only` (gol = toate). Cache pe mesh: instantele aceluiasi
## GLB impart rezultatul.
static func smoothed_mesh(mesh: Mesh, only: Dictionary = {}) -> Mesh:
	if mesh == null:
		return null
	if _smoothed_meshes.has(mesh):
		return _smoothed_meshes[mesh]
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(si)
		if not only.is_empty() and not only.has(si):
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			out.surface_set_material(si, mesh.surface_get_material(si))
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] != null:
			idx = arrays[Mesh.ARRAY_INDEX]
		var acc := {}
		var tri_count := idx.size() / 3 if idx.size() > 0 else verts.size() / 3
		for t in tri_count:
			var i0: int = idx[t * 3] if idx.size() > 0 else t * 3
			var i1: int = idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1
			var i2: int = idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2
			var fn := (verts[i1] - verts[i0]).cross(verts[i2] - verts[i0])
			for i in [i0, i1, i2]:
				var key := (verts[i] * 200.0).round()
				acc[key] = acc.get(key, Vector3.ZERO) + fn
		var old_n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var normals := PackedVector3Array()
		normals.resize(verts.size())
		for i in verts.size():
			normals[i] = (acc.get((verts[i] * 200.0).round(), old_n[i]) as Vector3).normalized()
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = null
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(si, mesh.surface_get_material(si))
	_smoothed_meshes[mesh] = out
	return out

static var _tri_mats: Dictionary = {}

## Textura unei clase, cu ridicarea din CLASS_LIFT aplicata daca e ceruta.
## Cache pe clasa: dala ridicata se construieste O DATA, deci doua materiale pe
## aceeasi clasa nu platesc doua imagini.
static var _lifted: Dictionary = {}

## Clase care IMPART imaginea ridicata a altei clase (aceeasi dala, aceeasi
## ridicare, alta tenta). Fara asta, `_lifted` e cheiat pe numele clasei si
## doua tente pe aceeasi dala ridicata ar plati doua imagini in memorie.
## Introdus pentru Jodhpur (varul in doua tente, gresia in doua tente); nu
## atinge nicio clasa existenta.
const CLASS_LIFT_SHARED := {
	"blue_lime_indigo": "blue_lime_light",
	"red_sandstone": "rose_sandstone",
	"ginkgo_gold": "maple_orange",
	"shu_red": "shu_vermilion",
	# Calota imparte dala ridicata a gresiei (aceeasi imagine, alta tenta): zero VRAM.
	"mv_cap": "mv_sandstone",
}

static func _class_texture(cls: String) -> Texture2D:
	if CLASS_LIFT_SHARED.has(cls):
		return _class_texture(CLASS_LIFT_SHARED[cls])
	var src: Texture2D = load(CLASS_TEXTURES[cls])
	if not CLASS_LIFT.has(cls):
		return src
	if _lifted.has(cls):
		return _lifted[cls]
	var img: Image = src.get_image()
	if img == null:
		return src # checkout fara textura importata: mai bine dala originala
	img = img.duplicate()
	img.decompress() # dalele sunt importate comprimat (ETC2/S3TC)
	img.convert(Image.FORMAT_RGB8)
	# Luminanta medie actuala, esantionata din 4 in 4 pixeli (destul pentru o
	# medie, de 16 ori mai ieftin decat tot).
	var sum: float = 0.0
	var n: int = 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			sum += img.get_pixel(x, y).get_luminance()
			n += 1
	var cur: float = sum / maxf(float(n), 1.0)
	if cur <= 0.001:
		return src
	var gain: float = float(CLASS_LIFT[cls]) / cur
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(minf(c.r * gain, 1.0),
				minf(c.g * gain, 1.0), minf(c.b * gain, 1.0)))
	if CLASS_LIFT_ROTATE.has(cls):
		img.rotate_90(CLOCKWISE)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_lifted[cls] = tex
	return tex


static func triplanar_class_material(cls: String) -> StandardMaterial3D:
	if _tri_mats.has(cls):
		return _tri_mats[cls]
	assert(CLASS_TRIPLANAR_SCALE.has(cls),
		"clasa triplanara necunoscuta: " + cls)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _class_texture(cls)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mat.metallic_specular = 0.15
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	var s: float = CLASS_TRIPLANAR_SCALE[cls]
	mat.uv1_scale = Vector3(s, s, s)
	mat.uv1_triplanar_sharpness = CLASS_TRIPLANAR_SHARPNESS.get(cls, 1.0)
	if CLASS_TINT.has(cls):
		mat.albedo_color = CLASS_TINT[cls]
	_tri_mats[cls] = mat
	return mat

## Aplica o clasa triplanara pe TOT subarborele — doar pentru assets-uri
## dintr-un singur material dominant (turnul de apa e integral ruginit).
## ATENTIE: triplanar in spatiul LUMII = textura "inoata" pe obiecte care se
## MISCA. Pentru alea exista varianta din spatiul OBIECTULUI, mai jos.
static func apply_triplanar_class(root: Node, cls: String) -> void:
	var mat := triplanar_class_material(cls)
	for node in _walk(root):
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = mat


## --- Varianta din spatiul OBIECTULUI, pentru ce se misca ---
##
## Triplanarul de LUME isi ia coordonatele din pozitia vertexului in scena. Pe
## un obiect fix e exact ce vrem (benzile curg continuu peste sectiuni vecine,
## fara cusaturi). Pe unul care se MISCA e o eroare vizibila: lumea sta pe loc,
## obiectul aluneca prin ea, deci textura "inoata" pe suprafata. La bolovanul
## rostogolitor e cel mai rau caz cu putinta — se si roteste, deci pietrele
## pictate ar curge peste el ca apa, si tocmai rostogolirea e ce trebuie citita.
##
## `uv1_world_triplanar = false` muta proiectia in spatiul MODELULUI: textura se
## roteste odata cu mesh-ul si sta lipita de piatra.
##
## `world_scale` compenseaza scalarea nodului. Proiectia citeste coordonatele
## vertexului DINAINTE de transformare, deci un model desenat la 5 m si pus in
## joc la 0.52 ar arata straturile de 2x mai mari decat pe falezele de langa el.
## Inmultind scara cu factorul de scalare, un strat de roca masoara la fel in
## lume indiferent pe ce obiect cade — asta tine clasa sa arate ca o clasa.
static var _tri_obj_mats: Dictionary = {}

static func object_triplanar_class_material(cls: String,
		world_scale: float = 1.0) -> StandardMaterial3D:
	var key := "%s@%.3f" % [cls, world_scale]
	if _tri_obj_mats.has(key):
		return _tri_obj_mats[key]
	var mat := triplanar_class_material(cls).duplicate() as StandardMaterial3D
	mat.uv1_world_triplanar = false
	var s: float = CLASS_TRIPLANAR_SCALE[cls] * world_scale
	mat.uv1_scale = Vector3(s, s, s)
	_tri_obj_mats[key] = mat
	return mat

static func apply_object_triplanar_class(root: Node, cls: String,
		world_scale: float = 1.0) -> void:
	var mat := object_triplanar_class_material(cls, world_scale)
	for node in _walk(root):
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = mat

static var _class_mats: Dictionary = {}

static func class_material(cls: String) -> StandardMaterial3D:
	if _class_mats.has(cls):
		return _class_mats[cls]
	assert(CLASS_TEXTURES.has(cls), "clasa de material necunoscuta: " + cls)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _class_texture(cls)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true # AO copt, ca peste tot
	mat.roughness = 0.9
	mat.metallic_specular = 0.15
	if CLASS_TINT.has(cls):
		mat.albedo_color = CLASS_TINT[cls]
	_class_mats[cls] = mat
	return mat


## Aplica materiale pe un GLB cu parti numite: cheia din `mapping` e un
## prefix de nume de nod, valoarea e clasa. Nodurile nemapate raman pe
## materialul lumii (atlas + AO) — lemnaria si nisipul unui asset mixt.
##
## Valoarea poate fi prefixata cu "tri:" pentru clasele proiectate TRIPLANAR in
## spatiul lumii, in loc de UV-uri reale. Nu e un detaliu de implementare, e o
## alegere de aspect: pe roca, proiectia de lume face straturile sa curga
## CONTINUU dintr-o piesa in vecina ei, deci movila portalului de mina se leaga
## de faleza de care se sprijina in loc sa aiba propriul ei tipar. Merge doar pe
## piese care stau pe loc (style_bible §4).
const TRI_PREFIX := "tri:"

## Al doilea prefix acceptat in mapari: "finish:<nume>". NU schimba textura, ci
## FINISAJUL — acelasi atlas, alt raspuns la lumina.
##
## Exista pentru piesele care nu pot primi o clasa fara sa piarda tot: trenul
## are verdele, dunga galbena si geamurile in sloturi, deci orice albedo de
## clasa le-ar sterge. Ce lipsea insa nu era tiparul de suprafata, ci faptul ca
## tabla vopsita raspundea la soarele jos exact ca zapada din jur — roughness
## 0.9, specular 0.15, adica hartie. Un singur material in plus (cache-uit,
## textura si masca sunt ACELEASI obiecte) da locomotivei o lucire pe fetele
## dinspre soare, si atat.
const FINISH_PREFIX := "finish:"

## Al treilea prefix acceptat: "shader:<nume>". Pentru partile a caror aparenta
## nu se poate obtine dintr-un StandardMaterial3D, oricat i-ai regla
## parametrii — azi doar lava, care trebuie sa CURGA si sa pulseze.
##
## Nu e o portita pentru „materiale speciale": un shader e un material in plus
## la garda si o compilare in plus pe GPU. Se adauga doar cand miscarea E
## continutul, ca aici (o limba de lava statica e o dunga portocalie, adica
## verdictul dezvoltatorului pe captura din august 2026).
const SHADER_PREFIX := "shader:"

## Al patrulea prefix acceptat: "glow:<slot>|<energie>". NU schimba nici
## textura, nici finisajul: aprinde UN slot din atlas pe o piesa care ramane
## altfel neatinsa.
##
## Exista fiindca pe o pista de NOAPTE (Chongqing) diferenta fata de referinta
## nu era poligonajul si nici tiparul de suprafata, ci faptul ca nimic nu
## EMITE. Masurat pe cadrul nodului rutier: deviatie de luminanta 14.4 fata de
## 28.1 pe bara — jumatate din variatia de valoare, si toata lipsa era
## contrastul de ferestre calde pe beton rece. Cladirile aveau deja ferestrele,
## firmele si felinarele pictate pe slotul 30 (`GLOW` in build_chongqing_*.py);
## le lipsea doar lumina.
##
## Se sprijina pe `glow_material`, deci masca de emisie e slotul: betonul
## ramane beton, ard doar fetele din slotul cerut. Si, esential pentru garda,
## materialul e cache-uit per (slot, energie) — un cartier intreg de ferestre
## aprinse costa UN material, nu unul per cladire.
const GLOW_PREFIX := "glow:"

## Al cincilea prefix acceptat: "atlas". Nu aduce nicio textura noua — forteaza
## `world_material()` pe o parte anume a unui model, ca sa anuleze o coliziune
## de nume cu maparea GLOBALA din `prop_classes()` (memoria
## `nume-noduri-nu-sunt-unice`). Fara sentinela, `CLASSES_BY_MODEL` nu putea
## SCOATE o clasa deja aplicata global — doar adauga una noua — fiindca un
## string gol insemna "nicio intrare" si sarea nodul, lasand materialul gresit
## pe loc. Vezi `cafe_shed`/`lodge` mai jos: `House_Roof` al lor coincide cu
## `House_Roof` din `village_house.glb` (landmark Okinawa, `roof_tiles`).
const ATLAS_PREFIX := "atlas"

## Al saselea prefix acceptat: "plain". La fel ca ATLAS_PREFIX, nu aduce nicio
## textura noua — dar, spre deosebire de el, OPRESTE stratul triplanar de
## detaliu (`detail_enabled`), nu doar reface `world_material()` (care il
## are pornit din constructie).
##
## DE CE exista, separat de ATLAS_PREFIX: `world_material()` e gandit pentru
## teren/roca/lemn — stratul triplanar (fibra, crapaturi) e exact ce cere
## style_bible §4 pe suprafetele acelea. O caroserie de VOPSEA PLATA nu are
## acel tipar de suprafata: masurat pe `cruise_boat` (POI A, runda 3), corpul
## alb al vaporasului primea `world_material()` prin fallback-ul implicit al
## lui `apply_class_materials` (nodul `Boat` nu are nicio intrare in
## CLASSES_BY_MODEL), deci stratul triplanar de detaliu (gandit pentru
## piatra/lemn de teren) se vedea PESTE gelcoat-ul alb ca un model de fibra
## de lemn/scoarta — verdictul criticului orb: "carena alba are un model de
## fibra de lemn/scoarta". Confirmat direct pe scena incarcata (sonda
## tools/sv_boat_slots.gd), nu presupus: materialul pe `Boat` ERA chiar
## `PaletteAtlas`-ul din GLB brut, deci nu e o coliziune de nume cu alt kit
## (nume-noduri-nu-sunt-unice) — e fallback-ul universal, corect pentru
## roca/lemn de decor, gresit pentru vopsea neteda.
##
## Cache-uit ca finish_material: ZERO materiale noi la garda (acelasi atlas,
## aceeasi masca, doar `detail_enabled=false` pe o copie).
const PLAIN_PREFIX := "plain"

static var _plain_mat: StandardMaterial3D = null

static func plain_material() -> StandardMaterial3D:
	if _plain_mat == null:
		_plain_mat = world_material().duplicate() as StandardMaterial3D
		_plain_mat.detail_enabled = false
	return _plain_mat


## Al saptelea prefix acceptat: "atint:<nume>". ATLASUL modelului, cu o TENTA pe
## material: culoarea slotului ramane (nicio textura noua, nicio clasa
## triplanara), dar se inmulteste cu `ATLAS_TINTS[nume]`.
##
## Exista fiindca un slot nu se poate muta pe alta culoare fara sa fie stricate
## toate piesele care il folosesc, iar o clasa triplanara ar STERGE culoarea
## slotului (textura inlocuieste atlasul). Cazul Okinawa (Track20): floarea de
## bougainvillea sta pe FLAMINGO_PINK 31 (#D2A0BE, roz pal), iar tinta e magenta
## #C2378F; frunzisul fukugi sta pe TROPICAL_GREEN 21 (#3F7A3C), iar tinta e
## #2E5A2C. Tenta doar INTUNECA, deci tinta se alege sub slot pe fiecare canal.
##
## Un material per nume, partajat de toate piesele care il cer (garda numara
## materiale, nu instante). Pastreaza stratul de detaliu al atlasului, ca
## `world_material()`: copie cu `duplicate()`, texturile raman aceleasi obiecte.
const ATINT_PREFIX := "atint:"

const ATLAS_TINTS := {
	# Magenta #C2378F pe slotul 31 (#D2A0BE): (0.92, 0.34, 0.75), valoarea din
	# inventarul kitului (okinawa_inventory.md, bougainvillea). CALIBRATA in joc.
	"ok_bloom": Color(0.890, 0.420, 0.830),
	# Frunzisul fukugi/pin: #3F7A3C -> #2E5A2C, liniar (0.55, 0.52, 0.56) = in
	# sRGB (0.76, 0.745, 0.77). INCEPUT DE CALIBRARE, de masurat in joc.
	"ok_leaves": Color(0.760, 0.720, 1.000),
	# Lacul (#B3261E = 179,38,30) pe slotul KERB_RED 7. Pe captura de joc, fata
	# luminata a peretelui palatului iesea (222, 48, 19) = #DE3013: portocaliu-aprins,
	# mult peste tinta (nu „plastic" prin luciu, ci prin valoare si saturatie).
	# Tenta liniara R 0.62, G 0.66; B nu poate creste (19 vs 30), ramane 1.0 => in
	# sRGB (0.81, 0.84, 1.0). Doar pe `*_Lacquer`; aurul si mortarul raman pe atlas.
	"ok_lacquer": Color(0.810, 0.840, 1.000),
	# Transfagarasan. Bujorul de munte: FLAMINGO_PINK 31 (#D2A0BE) -> #B63A7A, liniar
	# (0.727, 0.119, 0.379) = in sRGB (0.868, 0.382, 0.648) a dat in joc (202,33,94), rosu-aprins;
	# tinta (182,58,122) cere R mai jos, G si B mai sus. Corectie liniara (0.79, 3.5, 1.78),
	# aplicata pe jumatate (floarea are ~300 px, masuratoarea e zgomotoasa): (0.824, 0.510, 0.739).
	"tf_bloom": Color(0.824, 0.510, 0.739),
}

static var _atint_mats: Dictionary = {}

static func atlas_tint_material(name: String) -> StandardMaterial3D:
	if _atint_mats.has(name):
		return _atint_mats[name]
	assert(ATLAS_TINTS.has(name), "tenta de atlas necunoscuta: " + name)
	var mat := world_material().duplicate() as StandardMaterial3D
	mat.albedo_color = ATLAS_TINTS[name]
	_atint_mats[name] = mat
	return mat


## Materialul cerut de un "glow:<slot>|<energie>". Energia e optionala
## (implicit 1.2, ca la `glow_material`).
static func _glow_from_spec(spec: String) -> StandardMaterial3D:
	var parts := spec.split("|")
	var slot := int(parts[0])
	var energy := 1.2 if parts.size() < 2 else float(parts[1])
	return glow_material(slot, energy)

## Finisajele disponibile: nume -> [roughness, metallic_specular] sau, pentru
## finisajele care ARD, [roughness, metallic_specular, energie, slot].
const FINISHES := {
	# Tabla vopsita a vehiculelor de decor (trenul, hovercraftul). Nu e
	# cromare: 0.55 sta la jumatatea drumului dintre lumea mata (0.9) si
	# gheata lacului (0.35), care ramane cea mai lucioasa suprafata din scena.
	"vehicle": [0.55, 0.40],
	# Lava (Stromboli): crapaturile, buzele gurilor si bombele poarta slotul 30
	# in albedo si trebuie sa ARDA — e semnalul pistei, iar la soarele jos al
	# temei albedo-ul singur citea ca vopsea. Emisia NU vine din atlas (ar
	# lumina si crusta): vine dintr-o masca 32x1 generata la rulare, neagra
	# peste tot in afara slotului declarat aici. UN material pentru lava,
	# guri si bombe — garda numara materialele, deci unul, nu trei.
	# Energia 2.6 e aleasa pe captura: peste ea tonemap-ul nu mai schimba
	# nimic (portocaliul saturat e deja la plafonul lui de luminanta, iar
	# bloom nu exista — constrangerile mobile interzic post-procesarea).
	# Castigul real al emisiei e ca semnalul ramane aprins si in umbra cuvei.
	"lava": [0.9, 0.15, 2.6, LAVA_ORANGE],
}

static var _finish_mats: Dictionary = {}

static func finish_material(name: String) -> StandardMaterial3D:
	if _finish_mats.has(name):
		return _finish_mats[name]
	assert(FINISHES.has(name), "finisaj necunoscut: " + name)
	# duplicate() fara subresurse, ca la foliage_material: atlasul, masca si
	# stratul de detaliu raman aceleasi obiecte in memoria GPU.
	var mat := world_material().duplicate() as StandardMaterial3D
	var f: Array = FINISHES[name]
	mat.roughness = f[0]
	mat.metallic_specular = f[1]
	if f.size() >= 4:
		mat.emission_enabled = true
		# NEGRU, nu alb: operatorul implicit e ADD, deci culoarea de emisie se
		# ADUNA cu textura — cu alb aici, toata crusta ardea orbitor si masca
		# de slot nu mai conta (masurat pe prima captura). Textura e semnalul.
		mat.emission = Color.BLACK
		mat.emission_energy_multiplier = f[2]
		mat.emission_texture = _slot_glow_texture(int(f[3]))
	_finish_mats[name] = mat
	return mat


## Un material care ARDE pe UN slot din atlas, cached per slot.
##
## Generalizarea ramurii emisive din `finish_material` ("lava"), scoasa de sub
## tabelul de finisaje fiindca al doilea client al ei nu e un finisaj, ci o
## CLASA de piese: reperele din culoarul de ceata (Chongqing, brief §3 POI E —
## „marcajele si stopurile raman vizibile, emisive slabe"). Fara ea, „raman
## vizibile" se rezolva prin distanta (reperele la 12 m, ceata inghite la 46),
## adica prin noroc, nu prin lumina — exact obiectia criticului.
##
## UN material per slot, partajat de toate piesele care il cer: garda numara
## materialele per pista, deci un culoar cu 12 repere aduce +1, nu +12.
## Energia e mica dinadins (`energy`): un reper care ARDE in ceata devine un
## far si sterge tot ce voia sa marcheze.
static var _glow_mats: Dictionary = {}

static func glow_material(slot: int, energy: float = 1.2) -> StandardMaterial3D:
	return glow_material_slots([slot], energy)


## Varianta pe MAI MULTE sloturi, cu aceeasi energie.
##
## Exista fiindca „cladirea luminata din interior" nu e un slot, ci doi-trei:
## pe `hongya_dong.glb`, masurat cu tools/tmp/slot_area, aurul (slot 30) e
## 0.8% din arie, iar corpul de lemn (slot 28, `#4A3526`) e 61%. Aprins doar
## slotul 30, hero-ul vizual al Chongqing-ului ramanea o silueta neagra pe o
## faleza neagra — masurat pe captura: luminanta medie 31 si o dominanta RECE
## (R-B = -10), fata de 55 si +58 in dioramă de referinta.
##
## Un material per (combinatie de sloturi, energie), ca si pana acum: un
## cartier intreg de case aurii aduce +1 la garda, nu +40.
static func glow_material_slots(slots: Array, energy: float = 1.2,
		tint: Color = Color.BLACK, multiply: bool = false) -> StandardMaterial3D:
	var sorted_slots: Array = slots.duplicate()
	sorted_slots.sort()
	var key := "%s|%.2f|%s|%s" % [
		str(sorted_slots), energy, tint.to_html(false), str(multiply)]
	if _glow_mats.has(key):
		return _glow_mats[key]
	var mat := world_material().duplicate() as StandardMaterial3D
	# NEGRU + textura de masca, ca la lava: cu operatorul ADD o culoare de
	# emisie alba ar aprinde toata piesa, nu sloturile.
	mat.emission_enabled = true
	mat.emission = Color.BLACK
	mat.emission_energy_multiplier = energy
	mat.emission_texture = _slots_glow_texture(sorted_slots, tint)
	# ADD vs MULTIPLY: ADD ADAUGA lumina peste pixel, deci pe o suprafata mare
	# stinge relieful — pe `hongya_dong.glb` (95% din arie in sloturile
	# aprinse) peretii ieseau placi portocalii uniforme la ORICE energie
	# incercata, fiindca emisia acoperea AO-ul din vertex colors care da
	# textura lemnului. Masurat pe captura: deviatia de luminanta 15-19, fata
	# de 30.8 in diorama de referinta.
	#
	# MULTIPLY inmulteste, deci pastreaza si albedo-ul si AO-ul si doar le
	# incalzeste: cladirea ramane o cladire, dar arde.
	if multiply:
		mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	_glow_mats[key] = mat
	return mat


## --- Lava incandescenta (Stromboli) -----------------------------------------

## Materialul lavei: crusta neagra cu crapaturi care CURG si pulseaza.
## Vezi assets/shaders/lava.gdshader pentru ce face si cat costa.
##
## INLOCUIESTE `finish_material("lava")` pe piesele de lava, si nu e o
## rafinare cosmetica — finisajul avea un BUG pe geometria generata in cod.
## Finisajul pastreaza textura ATLASULUI, iar contractul atlasului cere UV-uri
## colapsate pe centrul slotului. GLB-urile respecta contractul; primitivele lui
## Godot NU: un CylinderMesh are UV-uri 0..1, deci matura tot atlasul. Masurat:
## cilindrul atinge 21 de sloturi si sfera 13, amandoua trecand prin rezerva
## MAGENTA (24..31). De-aia coloanele gheizerelor ieseau in dungi de acadea.
##
## Shaderul nu citeste niciun UV — isi calculeaza culoarea din pozitia in
## spatiul obiectului — deci merge la fel pe GLB-uri si pe primitive, si nu
## exista drum pe care sa culeaga slotul gresit.
##
## Un SINGUR material pentru toate piesele care nu se defazeaza (limba, gurile,
## bombele, placile): garda numara materialele. Gheizerele cer defazaj per
## instanta, deci isi iau o duplicare — vezi `lava_material_phased`.
static var _lava_mat: ShaderMaterial

static func lava_material() -> ShaderMaterial:
	if _lava_mat != null:
		return _lava_mat
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/lava.gdshader")
	# Culorile vin din PALETA, nu din shader: lava trebuie sa ramana in aceeasi
	# familie cu bazaltul de langa ea. Crusta e slotul 20 (VOLCANIC_BLACK)
	# coborat, jarul e slotul 30 (LAVA_ORANGE).
	var crust := color(VOLCANIC_BLACK)
	mat.set_shader_parameter("crust_color",
		Color(crust.r * 0.45, crust.g * 0.45, crust.b * 0.45))
	mat.set_shader_parameter("glow_color", color(LAVA_ORANGE))
	_lava_mat = mat
	return mat


## Varianta defazata, pentru piesele care trebuie sa NU pulseze la unison —
## gheizerele. `duplicate()` pastreaza acelasi Shader (o singura compilare pe
## GPU); ce difera e un uniform.
##
## Costa cate un material per gheizer in numaratoarea garzii. E acceptat
## deliberat: alternativa (toate gheizerele pulsand la aceeasi bataie) ar fi
## anulat exact citirea pe care se bazeaza hazardul — opozitia de faza trebuie
## sa se VADA, nu doar sa existe in fizica.
## Materialul din spatele prefixului "shader:<nume>" dintr-o mapare de clase.
## Un singur nume azi; e o functie ca sa existe UN loc unde se adauga al doilea,
## nu un `if` strecurat in dispatcher.
static func shader_material(name: String) -> ShaderMaterial:
	if name == "faded_detail":
		return faded_detail_material()
	if name == "jod_window":
		return window_lamp_material()
	assert(name == "lava", "shader necunoscut: " + name)
	return lava_material()


## Materialul lumii, dar cu stratul de pete care SE STINGE CU DISTANTA.
##
## Runda 6 a stins pestritul pe carosabil si pe teren; prop-urile au ramas pe
## `world_material`, care e StandardMaterial3D. Runda 7, amandoi criticii,
## despre hornuri: aceeasi marime si acelasi contrast al petelor de la 3 m la
## 90 m. Nu e o impresie — se vede pe captura, conul din marginea cadrului si
## cel de la 90 m poarta caneluri identice.
##
## De ce nu se putea repara pe materialul existent: `distance_fade` din
## StandardMaterial3D stinge OBIECTUL (alfa), nu un strat, iar mipmap-urile
## netezesc tiparul fara sa-i scada contrastul — la incidenta razanta
## selectorul de mip ramane pe nivelele ascutite (nota lunga din
## terrain_splat.gdshader).
##
## Shaderul reproduce exact ce facea materialul comun (atlas pe UV1, vertex
## color ca AO, detaliu triplanar prin masca de slot) si adauga stingerea spre
## 1.0 — identitatea inmultirii — intre `detail_near_m` si `detail_far_m`.
##
## UN material pentru toate piesele care il cer, ca la `lava_material`: garda
## numara materialele, deci o padure intreaga de hornuri aduce +1, nu +41.
static var _faded_detail: ShaderMaterial

## Ferestrele si nisele care se aprind cu ceasul (`dusk_lamps`, DuskCycle).
## Azi doar pe Jodhpur (`shader:jod_window` in maparile de clase); vezi
## assets/shaders/jod_window.gdshader pentru praguri. UN material pentru
## toate ferestrele pistei: +1 la garda, nu +1 per cladire.
static var _window_lamp: ShaderMaterial

static func window_lamp_material() -> ShaderMaterial:
	if _window_lamp != null:
		return _window_lamp
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/jod_window.gdshader")
	mat.set_shader_parameter("albedo_atlas", load(ATLAS_PATH))
	_window_lamp = mat
	return mat

static func faded_detail_material() -> ShaderMaterial:
	if _faded_detail != null:
		return _faded_detail
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/prop_detail_fade.gdshader")
	# Aceleasi obiecte de textura ca `world_material`: nimic nu se dubleaza in
	# memoria GPU.
	mat.set_shader_parameter("albedo_atlas", load(ATLAS_PATH))
	mat.set_shader_parameter("detail_tex", load(_detail_path))
	mat.set_shader_parameter("detail_mask_tex", load(DETAIL_MASK_PATH))
	mat.set_shader_parameter("detail_scale", DETAIL_SCALE)
	# Fereastra de stingere e MAI SCURTA decat pe teren (26->130 m). Nu din
	# gust: terenul se vede razant si se intinde pana in ceata, deci are nevoie
	# de o tranzitie lunga ca sa nu apara un inel. Un horn e un obiect cu
	# silueta, pe care il vezi intre 3 si 90 m, si tocmai intervalul ala trebuie
	# sa arate diferenta. Masurat pe captura de la frac 0.045, deviatia de
	# luminanta in corpul unui con, departe/aproape:
	#   world_material (fara stingere)  1.01  — identic la 8 m si la 70 m
	#   26 -> 130 m                     0.94
	#   14 ->  70 m                     vezi commit
	mat.set_shader_parameter("detail_near_m", 14.0)
	mat.set_shader_parameter("detail_far_m", 70.0)
	_faded_detail = mat
	return mat


static func lava_material_phased(phase: float, flow: float = -1.0) -> ShaderMaterial:
	var mat := lava_material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("phase_offset", phase)
	if flow >= 0.0:
		mat.set_shader_parameter("flow_speed", flow)
	return mat


## Masca de emisie pe UN slot: 32x1, negru peste tot, culoarea slotului pe
## texelul lui. UV-urile colapsate pe centrul slotului (contractul atlasului)
## cad exact pe centrul texelului, deci filtrarea liniara nu trage din vecini.
## Fara mipmap-uri: la distanta ar amesteca tot randul si ar stinge semnalul.
static func _slot_glow_texture(slot: int) -> ImageTexture:
	return _slots_glow_texture([slot])


## Masca emisiva pentru mai multe sloturi deodata (vezi `glow_material_slots`).
## `tint` NEGRU inseamna „aprinde fiecare slot cu propria lui culoare" — bun
## pentru jar, unde culoarea slotului CHIAR e culoarea luminii.
##
## Pentru lumina de INTERIOR nu merge, si asta s-a masurat: pe `hongya_dong.glb`
## corpul e slotul 28 (`#4A3526`, lemn aproape negru) pe 61% din arie. Adunat
## peste el insusi, lemnul ramane lemn — captura de pe cornisa a dat luminanta
## 13.7 cu dominanta RECE (R-B = -4), fata de 60.0 si +49 in diorama de
## referinta. Ce lumineaza in referinta nu e lemnul, sunt ferestrele DIN
## SPATELE lui: o lumina calda, aceeasi pentru tot corpul.
##
## Deci un `tint` ne-negru inlocuieste culoarea slotului cu culoarea LUMINII,
## pastrand masca — adica „partile astea ale piesei ard, in nuanta asta".
static func _slots_glow_texture(slots: Array,
		tint: Color = Color.BLACK) -> ImageTexture:
	# LATIMEA E `SLOTS`, NU `HEX.size()`. Sunt 32 de sloturi alocate si doar 31
	# de culori scrise, iar UV-ul unui slot e `(slot + 0.5) / 32` (vezi `uv()`).
	# Cu o masca de 31 px, slotul 30 cadea la x = 0.953 * 31 = 29.5 — adica FIX
	# intre texelul aprins si vecinul lui negru, deci filtrarea liniara statea
	# la jumatate de emisie si mai si murdarea slotul 29. De aici venea
	# masuratoarea „slotul 30 singur da o silueta neagra": masca nu-l nimerea.
	var img := Image.create(SLOTS, 1, false, Image.FORMAT_RGB8)
	img.fill(Color.BLACK)
	for s: int in slots:
		img.set_pixel(s, 0, color(s) if tint == Color.BLACK else tint)
	return ImageTexture.create_from_image(img)

static func apply_class_materials(root: Node, mapping: Dictionary) -> void:
	for node in _walk(root):
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		var cls := _class_for(String(mi.name), mapping)
		if cls.is_empty():
			mi.material_override = world_material()
		elif cls.begins_with(FINISH_PREFIX):
			mi.material_override = finish_material(
				cls.trim_prefix(FINISH_PREFIX))
		elif cls.begins_with(SHADER_PREFIX):
			mi.material_override = shader_material(
				cls.trim_prefix(SHADER_PREFIX))
		elif cls.begins_with(GLOW_PREFIX):
			mi.material_override = _glow_from_spec(
				cls.trim_prefix(GLOW_PREFIX))
		elif cls.begins_with(ATINT_PREFIX):
			mi.material_override = atlas_tint_material(
				cls.trim_prefix(ATINT_PREFIX))
		elif cls.begins_with(TRI_PREFIX):
			mi.material_override = triplanar_class_material(
				cls.trim_prefix(TRI_PREFIX))
		else:
			mi.material_override = class_material(cls)


## Ca `apply_class_materials`, dar cu clasele triplanare proiectate in spatiul
## OBIECTULUI — pentru modelele care SE MISCA (trenul, hovercraftul, figuranti
## pe PathMover).
##
## Nu e un detaliu: proiectia de lume isi ia coordonatele din pozitia vertexului
## in scena, deci pe un tren care traverseaza 200 m textura ii curge pe sub
## tabla — rugina „sta pe loc" si trenul aluneca prin ea. Aceeasi capcana e
## descrisa pe larg la `apply_object_triplanar_class`; aici e varianta ei pe
## PARTI, ca un model mixt (caroserie pe atlas, sasiu ruginit, gheata pe
## acoperis) sa poata avea si clase, si culorile din sloturi.
static func apply_object_class_materials(root: Node, mapping: Dictionary,
		world_scale: float = 1.0) -> void:
	for node in _walk(root):
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		var cls := _class_for(String(mi.name), mapping)
		if cls.is_empty():
			mi.material_override = world_material()
		elif cls.begins_with(FINISH_PREFIX):
			mi.material_override = finish_material(
				cls.trim_prefix(FINISH_PREFIX))
		elif cls.begins_with(SHADER_PREFIX):
			mi.material_override = shader_material(
				cls.trim_prefix(SHADER_PREFIX))
		elif cls.begins_with(GLOW_PREFIX):
			mi.material_override = _glow_from_spec(
				cls.trim_prefix(GLOW_PREFIX))
		elif cls.begins_with(ATINT_PREFIX):
			mi.material_override = atlas_tint_material(
				cls.trim_prefix(ATINT_PREFIX))
		elif cls.begins_with(TRI_PREFIX):
			mi.material_override = object_triplanar_class_material(
				cls.trim_prefix(TRI_PREFIX), world_scale)
		else:
			mi.material_override = class_material(cls)


## Clasa unei parti, dupa prefixul CEL MAI LUNG care se potriveste. Gol = pe
## materialul lumii.
##
## Lungimea, nu ordinea din dictionar: de cand piesele mixte se sparg la export
## in bucati cu acelasi radacina de nume ("Tunnel_Bore" + "Tunnel_Bore_Ice",
## "RailTrack" + "RailTrack_Rails"), prima potrivire ar fi depins de ordinea in
## care sunt scrise cheile — adica o mapare corecta ar fi devenit gresita la o
## reordonare inocenta. Cu prefixul cel mai lung, partea cea mai specifica
## castiga intotdeauna.
static func _class_for(name: String, mapping: Dictionary) -> String:
	# Nodurile de accente rupte de `split_accents` raman pe materialul lumii,
	# ORICE ar spune maparea. Fara linia asta, `House_A_Accente` s-ar potrivi
	# tot pe prefixul "House_" si ar primi tencuiala — adica exact obloanele pe
	# care ruptura le salva. Prinsa pe scena incarcata, nu prin numaratoare.
	if name.ends_with(ACCENT_SUFFIX):
		return ""
	var best := ""
	var best_len := -1
	for prefix: String in mapping:
		if not name.begins_with(prefix):
			continue
		if prefix.length() > best_len:
			best_len = prefix.length()
			best = mapping[prefix]
	return best


## Pune materialul comun pe toate mesh-urile dintr-un subarbore. Pentru GLB-uri
## importate din Blender: modelul aduce UV-urile catre sloturile atlasului si
## vertex color-ul de AO; noi ii inlocuim materialul cu cel partajat. Asa un
## prop facut in Blender se grupeaza cu restul lumii intr-un singur draw call.
##
## Merge la fel pe subarborii oglinditi (scale negativa pe o axa) — vezi nota
## despre oglindire de mai sus.
static func apply_world_material(root: Node) -> void:
	var mat := world_material()
	for node in _walk(root):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			mi.material_override = mat


## --- Lumina RECE de umplere, pe sloturile de piatra ------------------------

## [b]De ce nu merge niciun drum multiplicativ.[/b] Sub pamant, piesele salii
## (`hall_alcove`, `hall_column`, `hall_ceiling_module`, `hall_arch`) stau DOAR
## pe sloturile 2 (#955f28) si 4 (#774c23) — masurat cu
## `tools/ProbeCappSlots.tscn`, nu presupus. Amandoua sunt brunuri calde si
## saturate (0.73 / 0.71), deci toata sala are o singura croma si cele 16 torte
## se citesc ca un singur jar: n-au nimic RECE langa care sa fie calde.
## Referinta (`v3_crops/F_underground.png`) are piatra gri-bej rece, cu caldura
## numai din flacara.
##
## Aritmetica, facuta inainte de a scrie codul, spune ca trei din patru lucruri
## la indemana NU pot ajunge acolo, fiindca toate INMULTESC brunul:
##   - `albedo_color` (tenta pe material): ca sa ajunga neutru trebuie sa aduca
##     R si G la nivelul lui B, adica (119,76,35) -> (35,35,35). Saturatie 0,
##     dar luminanta 82 -> 35: piatra devine gri DEVENIND aproape neagra, exact
##     ce a respins criticul rundei trecute („piatra CITIBILA peste tot").
##   - `ambient_light_color`: si el multiplicativ. De-aia corectia rundei
##     trecute (cave_ambient dus pe gri neutru 0.72/0.70/0.72) NU s-a vazut —
##     masurat pe hartie, saturatia ramane 0.71 indiferent ce culoare are
##     ambientul, fiindca inmultirea scaleaza toate canalele proportional.
##   - `EMISSION_OP_MULTIPLY`: emisia e proportionala cu albedo-ul, deci scaleaza
##     acelasi brun (sat 0.71 -> 0.58 in cel mai bun caz incercat).
##
## Ce ramane, si ce chiar functioneaza, e lumina ADITIVA: un termen ABSOLUT,
## independent de albedo, care ridica PODEAUA canalelor mici. Masurat pe aceleasi
## doua sloturi, `#39445C` la energie 0.55 da (73,64,62) — saturatie 0.71 -> 0.15
## si luminanta 82 -> 66, adica se raceste CRESCAND in citibilitate, nu scazand.
##
## Fizic e si corect: intr-o caverna, umplerea rece vine din putul de ventilatie
## (cer), iar caldura din torte. Aici se declara chiar acea umplere.
##
## Costa UN material per (sloturi, energie, nuanta), partajat prin cache-ul din
## `glow_material_slots` — garda numara materiale, si un cartier intreg de piese
## racite aduce +1, nu +N.
static func cool_fill_material(slots: Array, tint: Color,
		energy: float) -> StandardMaterial3D:
	return glow_material_slots(slots, energy, tint, false)


## Pune umplerea rece pe tot subarborele.
## `skip_suffix`, daca e dat, lasa neatinse nodurile al caror nume se termina
## asa. Exista pentru piesele rupte de accente la care CLASA sta pe accent
## (`WorldProp.ACCENT_HOLDS_CLASS`): fara el racirea trecea peste tot subarborele
## si stergea clasa doua apeluri dupa ce fusese pusa.
static func apply_cool_fill(root: Node, slots: Array, tint: Color,
		energy: float, skip_suffix: String = "") -> void:
	var mat := cool_fill_material(slots, tint, energy)
	for node in _walk(root):
		if node is MeshInstance3D:
			if skip_suffix != "" and String(node.name).ends_with(skip_suffix):
				continue
			(node as MeshInstance3D).material_override = mat

## --- Ruperea accentelor de pe o parte care primeste clasa ------------------

## Numele nodului-copil in care ajung triunghiurile pastrate pe atlas.
const ACCENT_SUFFIX: String = "_Accente"

## Rupe dintr-un MeshInstance triunghiurile care NU stau pe `keep_slot` si le
## muta intr-un copil propriu, ramas pe materialul lumii.
##
## De ce exista: regula „o clasa triplanara sterge sloturile" a tinut casele
## Stromboli pe atlas, plate, ca sa nu piardem obloanele albastre. Masurat pe
## arie, varul e 90-98% din fatada si obloanele 1-9% — deci alegerea era intre
## „90% plat" si „5% pierdut", si amandoua sunt proaste cand se poate si una si
## alta. Aici corpul ia clasa si accentul ramane pictat.
##
## Nu cere re-export din Blender: se face la incarcare, pe arrays. Costa un
## draw call in plus per piesa care CHIAR are accente (mesh-urile fara ele nu
## se ating) si ZERO materiale — copilul foloseste `world_material()`, care era
## deja numarat.
##
## `keep_slot` poate fi un slot sau un Array de sloturi. Varianta cu mai multe
## exista pentru fatadele Chongqing, unde peretele de beton e pictat pe DOUA
## sloturi din motive de compozitie, nu de material: masurat pe cele trei
## shophouse-uri, slotul 29 tine parterul (y 0..3.1) si slotul 8 etajele
## (y 2.9..5.8) — acelasi perete, taiat pe orizontala. Cu un singur slot pastrat,
## jumatate din fatada ramanea plata langa cealalta jumatate texturata, adica
## exact cusatura pe care ruptura de accente ar trebui s-o evite.
##
## Intoarce `true` daca a rupt ceva.
static func split_accents(mi: MeshInstance3D, keep_slot) -> bool:
	if mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return false
	if mi.has_node(NodePath(String(mi.name) + ACCENT_SUFFIX)):
		return false # deja rupt (scena reincarcata in editor)
	var arr: Array = MeshCpu.surface_arrays(mi.mesh, 0)
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	if uvs.is_empty() or idx.is_empty():
		return false
	var keep_slots: Dictionary = {}
	if keep_slot is Array:
		for s: int in keep_slot:
			keep_slots[s] = true
	else:
		keep_slots[int(keep_slot)] = true
	var keep: PackedInt32Array = PackedInt32Array()
	var move: PackedInt32Array = PackedInt32Array()
	var i: int = 0
	while i + 2 < idx.size():
		# Slotul triunghiului dupa PRIMUL vertex: UV-urile sunt colapsate pe
		# centrul slotului, deci toate trei cad in acelasi loc prin constructie.
		var slot: int = clampi(int(uvs[idx[i]].x * float(SLOTS)), 0, SLOTS - 1)
		var tri := PackedInt32Array([idx[i], idx[i + 1], idx[i + 2]])
		if keep_slots.has(slot):
			keep.append_array(tri)
		else:
			move.append_array(tri)
		i += 3
	if move.is_empty() or keep.is_empty():
		return false # totul intr-o parte: nu e nimic de rupt
	var accents := MeshInstance3D.new()
	accents.name = String(mi.name) + ACCENT_SUFFIX
	accents.mesh = _mesh_with_indices(arr, move)
	accents.material_override = world_material()
	mi.mesh = _mesh_with_indices(arr, keep)
	mi.add_child(accents)
	return true


## Un ArrayMesh cu ACELEASI arrays de vertecsi, dar alt set de indici. Vertecsii
## nefolositi raman in buffer — irosesc cativa kb dar pastreaza indicii valizi
## fara remapare, si mesh-urile astea au sute de vertecsi, nu sute de mii.
static func _mesh_with_indices(src: Array, indices: PackedInt32Array) -> ArrayMesh:
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	for k: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT,
			Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
		out[k] = src[k]
	out[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	MeshCpu.add_surface(mesh, out)
	return mesh


static func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
