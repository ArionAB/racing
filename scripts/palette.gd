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
## 30..31 raman rezerva (magenta in atlas, ca greselile de UV sa sara in ochi).

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
		_shared.detail_albedo = load(DETAIL_PATH)
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
	"rust_metal": "res://assets/textures/classes/rust_metal.png",
	"wood": "res://assets/textures/classes/wood.png",
	"concrete": "res://assets/textures/classes/concrete.png",
	# Insula (Okinawa): calcar coraligen si scoarta tropicala.
	"coral_rock": "res://assets/textures/classes/coral_rock.png",
	"bark": "res://assets/textures/classes/bark.png",
	# Muntele (Alpii): sisturi stratificate si zapada avalansei.
	"alpine_granite": "res://assets/textures/classes/alpine_granite.png",
	"snow": "res://assets/textures/classes/snow.png",
	# Coroana coniferelor (pictata, vezi tools/paint_pine_needles.py).
	"pine_needles": "res://assets/textures/classes/pine_needles.png",
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
}

## Tente de albedo per clasa, inmultite peste textura. Pentru clasele care
## REFOLOSESC dala alteia dar trebuie sa aterizeze pe alta culoare medie:
## ice_bloc readuce dala palida a lacului la culoarea slotului ICE_TURQUOISE
## (media dalei e ~(0.75, 0.87, 0.885), slotul e (0.49, 0.757, 0.776) —
## raportul da tenta). Textura NU se dubleaza in memorie: acelasi PNG,
## alt multiplicator pe material.
const CLASS_TINT := {
	"ice_bloc": Color(0.65, 0.87, 0.88),
	# `olkhon_marble` NU are tenta: dala lui e gradata direct spre slotul
	# MARBLE_GREY in pipeline, deci aterizeaza singura pe culoarea corecta.
	# Zidaria caii ferate e gradata spre CORAL_SAND (crem de insula, slotul
	# calcarului de Okinawa); pe Baikal trebuie sa ramana piatra cenusie sub
	# soare rece, de unde tenta rece de aici.
	"cut_stone": Color(0.88, 0.91, 0.97),
}

## Clasele care se aplica TRIPLANAR in spatiul lumii, pe assets cu UV-uri
## colapsate — zero re-export (mecanica validata de rock_material). Scara e
## per clasa: rugina se repeta mai des decat straturile de roca.
const CLASS_TRIPLANAR_SCALE := {
	# 0.2 -> 0.14 la trecerea pe fotografie: striatiile lui cliff_side sunt
	# mai fine decat benzile trim-ului pictat, iar la 5 m/repetitie se topeau
	# in mipmap. La ~7 m, un strat citeste cat un strat.
	"rock": 0.14,
	"rust_metal": 0.45, # o repetitie la ~2.2 m — panouri, nu strate
	# Sursa e o scanare de 1.1 m; la 1.18 m/repetitie scobiturile de calcar cad
	# aproape la scara reala, iar o stanca de recif de 1.6-4 m prinde 1.5-3.5
	# repetitii — destul cat tiparul sa nu se citeasca ca tapet.
	"coral_rock": 0.85,
	# Sursa e o dala de 2 m de sisturi. La 0.16 (o repetitie la 6.25 m) un
	# strat de piatra citeste cat un strat pe o stanca de 2-4 m, exact ca la
	# `rock` — aceeasi familie de geologie, alta piatra.
	"alpine_granite": 0.16,
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
	# Zidaria taiata: 0.5 = o repetitie la 2 m, adica SCARA REALA a sursei.
	# Blocurile din fotografie ies atunci la 20-40 cm, randurile din geometrie
	# sunt la 0.9 m: doua scari de zidarie care se sprijina una pe alta, exact
	# ca la o pila reala. La scara alpina (0.16, 6.25 m) blocurile ar fi de
	# 1-1.2 m — zidarie ciclopica, alt fel de constructie.
	"cut_stone": 0.28,
}

static var _tri_mats: Dictionary = {}

static func triplanar_class_material(cls: String) -> StandardMaterial3D:
	if _tri_mats.has(cls):
		return _tri_mats[cls]
	assert(CLASS_TRIPLANAR_SCALE.has(cls),
		"clasa triplanara necunoscuta: " + cls)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(CLASS_TEXTURES[cls])
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mat.metallic_specular = 0.15
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	var s: float = CLASS_TRIPLANAR_SCALE[cls]
	mat.uv1_scale = Vector3(s, s, s)
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
	mat.albedo_texture = load(CLASS_TEXTURES[cls])
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

## Finisajele disponibile: nume -> [roughness, metallic_specular].
const FINISHES := {
	# Tabla vopsita a vehiculelor de decor (trenul, hovercraftul). Nu e
	# cromare: 0.55 sta la jumatatea drumului dintre lumea mata (0.9) si
	# gheata lacului (0.35), care ramane cea mai lucioasa suprafata din scena.
	"vehicle": [0.55, 0.40],
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
	_finish_mats[name] = mat
	return mat

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

static func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
