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
const HEX: Array[String] = [
	"E8C88B", "D8A86A", "A97A4A", "C79664", "7E5B3A", "4B4B4D", "696765",
	"B74A3A", "C8BEAC", "8A6947", "915535", "7E96A8", "617A43", "AFA25E",
	"E54839", "2C82E8", "F2D03C",
	"54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
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
		_shared.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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

## Geamanul OGLINDIT al materialului lumii.
##
## Un prop cu scale.x = -1 are winding inversat, deci rasterizatorul ii vede
## fetele din spate ca fete din fata si obiectul iese pe dos. CULL_FRONT taie
## exact ce trebuie. Normalele sunt deja corecte — Godot le transforma cu inversa
## transpusa, care se ocupa singura de oglindire.
##
## De ce un material geaman si nu CULL_DISABLED pe cel comun: dezactivarea
## culling-ului ar dubla triunghiurile rasterizate pe TOATA lumea, iar fill
## rate-ul e exact constrangerea pe care o tinem sub control. Asa costa un
## material in plus si zero pixeli.
static var _shared_mirrored: StandardMaterial3D

static func world_material_mirrored() -> StandardMaterial3D:
	if _shared_mirrored == null:
		_shared_mirrored = world_material().duplicate() as StandardMaterial3D
		_shared_mirrored.cull_mode = BaseMaterial3D.CULL_FRONT
	return _shared_mirrored


## Pune materialul comun pe toate mesh-urile dintr-un subarbore. Pentru GLB-uri
## importate din Blender: modelul aduce UV-urile catre sloturile atlasului si
## vertex color-ul de AO; noi ii inlocuim materialul cu cel partajat. Asa un
## prop facut in Blender se grupeaza cu restul lumii intr-un singur draw call.
##
## `mirrored` doar pentru subarbori cu scara negativa pe o axa.
static func apply_world_material(root: Node, mirrored: bool = false) -> void:
	var mat := world_material_mirrored() if mirrored else world_material()
	for node in _walk(root):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			mi.material_override = mat

static func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
