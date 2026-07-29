class_name Palette
extends RefCounted
## Paleta UNICA a lumii (directia "diorama stilizata").
##
## Toate prop-urile impart o singura textura — [b]assets/textures/palette_atlas.png[/b]
## (32 sloturi x 16px). Un obiect nu are textura proprie: UV-urile lui arata spre
## centrul slotului cu culoarea dorita. Consecinte:
##   - un singur material pentru toata lumea -> foarte putine draw call-uri (mobil)
##   - coerenta de paleta garantata prin constructie
##   - umbrele proprii vin din ambient occlusion copt in VERTEX COLORS, nu din texturi
##
## Slotul e sursa de adevar comuna cu scripturile Blender: acolo se seteaza UV-ul
## pe [code]Palette.uv(slot)[/code], aici se citeste aceeasi valoare.

const ATLAS_PATH: String = "res://assets/textures/palette_atlas.png"
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

## Culorile, in ordinea sloturilor (identice cu atlasul generat).
const HEX: Array[String] = [
	"E8C88B", "D8A86A", "A97A4A", "C79664", "7E5B3A", "4B4B4D", "696765",
	"B74A3A", "C8BEAC", "8A6947", "915535", "7E96A8", "617A43", "AFA25E",
	"E54839", "2C82E8", "F2D03C",
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

## Materialul comun al lumii. Filtru NEAREST + fara mipmap-uri = culori curate,
## fara amestec intre sloturi. Vertex color = AO copt, inmultit peste atlas.
static func world_material() -> StandardMaterial3D:
	if _shared == null:
		_shared = StandardMaterial3D.new()
		_shared.albedo_texture = load(ATLAS_PATH)
		_shared.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_shared.vertex_color_use_as_albedo = true # AO copt in vertex colors
		_shared.roughness = 0.9
		_shared.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return _shared

## Pune materialul comun pe toate mesh-urile dintr-un subarbore. Pentru GLB-uri
## importate din Blender: modelul aduce UV-urile catre sloturile atlasului si
## vertex color-ul de AO; noi ii inlocuim materialul cu cel partajat. Asa un
## prop facut in Blender se grupeaza cu restul lumii intr-un singur draw call.
static func apply_world_material(root: Node) -> void:
	for node in _walk(root):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			mi.material_override = world_material()

static func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
