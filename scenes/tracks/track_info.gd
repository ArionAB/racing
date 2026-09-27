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

@export var display_name: String = ""
## Tara / regiunea, afisata sub nume ("JAPONIA", "EUROPA").
@export var region: String = ""
## Culoarea placeholder-ului cat timp lipseste imaginea, si a bulinei de regiune.
@export var accent: Color = Color(0.35, 0.45, 0.6)


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
			return info
	var fallback := TrackInfo.new()
	fallback.display_name = GameState.TRACK_NAMES[track_index]
	return fallback


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
