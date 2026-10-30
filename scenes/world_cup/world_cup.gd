class_name WorldCup
extends Resource
## O cupa din modul WORLD CUP: un sir fix de piste, jucate in ordine, cu
## punctele cumulate de la o cursa la alta (GameState.CHAMP_POINTS). O cupa
## noua = un .tres nou in `scenes/world_cup/data/` + o intrare in
## `GameState.WORLD_CUPS`, zero alt cod.
##
## Gruparea e DATE, ca la lumile carierei (CareerWorld): pistele se numesc prin
## `TrackInfo.id`, nu prin index, ca un swap in TRACK_SCENES sa nu mute o cupa
## pe alta pista fara sa vrea nimeni.

@export var id: StringName = &""
@export var display_name: String = ""
## Culoarea benzii din cutia cupei, in meniu.
@export var accent: Color = Color(0.35, 0.45, 0.6)
## Id-uri de pista (`TrackInfo.id`), in ordinea curselor.
@export var tracks: Array[StringName] = []


## Indexul din GameState.TRACK_SCENES al cursei `race`, sau -1 (id stricat:
## ProbeWorldCup il prinde inainte de merge).
func track_index(race: int) -> int:
	if race < 0 or race >= tracks.size():
		return -1
	return TrackInfo.index_of_id(tracks[race])
