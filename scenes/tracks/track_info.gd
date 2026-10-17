class_name TrackInfo
extends Resource
## Ce arata meniul despre o pista: numele de afis, regiunea si culoarea
## cartonasului. Un fisier per pista in `scenes/tracks/info/`, cu ACELASI nume
## ca scena (Track09.tscn -> Track09.tres), gasit dupa conventie — o pista noua
## in meniu = un .tres nou, zero cod.
##
## Imaginea NU sta aici: se cauta tot dupa conventie, in THUMB_DIR, ca sa poata
## fi adaugata doar punand un PNG in folder, fara sa editezi resursa.

const INFO_DIR := "res://scenes/tracks/info/"
const THUMB_DIR := "res://assets/ui/track_thumbs/"

static var _id_cache: Dictionary = {}

## Cheia STABILA a pistei: cariera, abtibildurile si `career.cfg` se leaga de
## ea, nu de `display_name`, care e text de afis si poate fi redenumit
## (recordurile vechi raman pe nume). Goala => se deduce din numele scenei.
@export var id: StringName = &""
@export var display_name: String = ""
## Tara / regiunea, afisata sub nume ("JAPONIA", "EUROPA").
@export var region: String = ""
## Culoarea placeholder-ului cat timp lipseste imaginea, si a bulinei de regiune.
@export var accent: Color = Color(0.35, 0.45, 0.6)

@export_group("Contratimp")
## Timpi pe TOATA cursa (3 tururi) cu rezervor sigilat, PUSI DE DEZVOLTATOR LA
## VOLAN (aur = timpul lui curat; argint ~ aur x 1.06, bronz ~ aur x 1.15 ca
## punct de pornire). Nu se calculeaza din AI: AI-ul nu conduce cu rezervor
## sigilat. 0 = fara tinta inca: nu da medalie, dar timpul se salveaza.
@export var tt_gold_ms: int = 0
@export var tt_silver_ms: int = 0
@export var tt_bronze_ms: int = 0


## Numele de baza al scenei ("Track09") pentru o pozitie din TRACK_SCENES.
static func scene_key(track_index: int) -> String:
	return String(GameState.TRACK_SCENES[track_index]).get_file().get_basename()


## Resursa pistei, sau una implicita din TRACK_NAMES daca .tres-ul lipseste —
## o pista noua apare in meniu si inainte sa-i scrie cineva fisierul.
static func for_track(track_index: int) -> TrackInfo:
	var path := INFO_DIR + scene_key(track_index) + ".tres"
	if ResourceLoader.exists(path):
		var info := load(path) as TrackInfo
		if info != null:
			if info.id == &"":
				info.id = StringName(scene_key(track_index).to_lower())
			return info
	var fallback := TrackInfo.new()
	fallback.id = StringName(scene_key(track_index).to_lower())
	fallback.display_name = GameState.TRACK_NAMES[track_index]
	return fallback


## True daca pista are cel putin o tinta de contratimp completata.
static func has_time_trial_targets(track_index: int) -> bool:
	return for_track(track_index).has_targets()


func has_targets() -> bool:
	return tt_gold_ms > 0 or tt_silver_ms > 0 or tt_bronze_ms > 0


## Indexul din GameState.TRACK_SCENES al pistei cu acest `id`, sau -1.
## Cariera vorbeste in id-uri; cursa, in indici.
static func index_of_id(track_id: StringName) -> int:
	if _id_cache.is_empty():
		for i in GameState.TRACK_SCENES.size():
			_id_cache[for_track(i).id] = i
	return int(_id_cache.get(track_id, -1))


## Calea asteptata a imaginii ("res://assets/ui/track_thumbs/Track09.png").
static func thumb_path(track_index: int) -> String:
	return THUMB_DIR + scene_key(track_index) + ".png"


## Imaginea pistei, sau null (=> placeholder). Accepta si .jpg/.webp.
static func thumbnail(track_index: int) -> Texture2D:
	var base := THUMB_DIR + scene_key(track_index)
	for ext in [".png", ".jpg", ".webp"]:
		if ResourceLoader.exists(base + ext):
			return load(base + ext) as Texture2D
	return null
