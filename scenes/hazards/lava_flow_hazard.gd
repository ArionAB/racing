@tool
class_name LavaFlowHazard
extends Node3D
## LIMBA DE LAVA CARE INCHIDE RUTA SCURTA (Stromboli, brief §3, POI F).
##
## Gimmick-ul pistei. Trei stadii, unul pe tur:
##
##   turul 1  `Lava_Stage1`  40 m, un brat   — ruta scurta e LIBERA
##   turul 2  `Lava_Stage2`  60 m, doua brate — poarta de 4.0 m intre ele
##   turul 3  `Lava_Stage3`  80 m, front lat  — ZID, ruta scurta e inchisa
##
## CONTRACTUL CU ASSET-UL (docs/asset_briefs/lava_set.md):
##
## Cele trei stadii sunt noduri in ACELASI `lava_flow.glb` si impart coada la
## origine — masurat, toate pleaca de la y=0 si cresc la 40/60/80 m. De aceea
## hazardul instantiaza scena O SINGURA DATA si comuta doar `visible`: nodul
## NU se muta niciodata. Daca l-ai muta la fiecare stadiu, limba ar SARI in loc
## sa avanseze, si tocmai avansul e ce trebuie sa se citeasca de sus, in timpul
## coborarii pe Sciara.
##
## COLIZIUNEA nu e aici: limba primeste corp fizic din `world_prop` la
## integrare (memoria `decor-manual-coliziune`). Hazardul se ocupa doar de
## STADIU si de semnalul catre AI.
##
## AI-UL RE-ALEGE. `prefers_shortcut` se trage o data pe cursa in
## AIController, deci fara nimic aici un AI care a decis "o iau pe scurta" ar
## intra in zid la turul 3. Hazardul expune `shortcut_open()`, iar AI-ul il
## intreaba la fiecare tur.

## Cate tururi tine fiecare stadiu. Implicit 1: stadiul creste la fiecare tur.
@export var laps_per_stage: int = 1:
	set(value):
		laps_per_stage = maxi(value, 1)

## Numele nodurilor de stadiu din GLB, in ordinea avansului. Sunt CONTRACT cu
## asset-ul — un nume gresit cade tacut pe "niciun mesh vizibil", nu pe eroare
## (avertismentul din okinawa_kit.md).
@export var stage_nodes: PackedStringArray = PackedStringArray([
	"Lava_Stage1", "Lava_Stage2", "Lava_Stage3",
])

## De la ce stadiu ruta scurta e considerata INCHISA pentru AI. Implicit 2
## (indexat de la 0), adica stadiul 3 din brief: zidul.
##
## Stadiul 2 (poarta de 4 m) ramane DESCHIS: masurat pe mesh, culoarul e de
## 4.00 m liberi, iar masina are 1.8 m — trece, dar cere linie curata. Aia e
## decizia pe care o vindem, deci n-o luam noi de la jucator.
@export var closed_from_stage: int = 2

## Indexul benzii secundare pe care o inchide (in ordinea din Track.routes).
@export var branch_index: int = 1

signal stage_changed(stage: int)

var _stage: int = 0
var _laps: int = 0
var _meshes: Array[Node3D] = []


func _ready() -> void:
	_collect()
	_apply()


## Se apeleaza din Race la fiecare tur incheiat de LIDER (nu de jucator: lava
## e o proprietate a lumii, nu a cursei tale).
func on_lap_completed() -> void:
	_laps += 1
	var want := mini(_laps / laps_per_stage, stage_nodes.size() - 1)
	if want != _stage:
		_stage = want
		_apply()
		stage_changed.emit(_stage)


## Poate AI-ul sa mai ia scurtatura? Intrebat la fiecare tur, nu o data pe cursa.
func shortcut_open() -> bool:
	return _stage < closed_from_stage


func current_stage() -> int:
	return _stage


## Strange nodurile de stadiu din subarbore, dupa NUME.
##
## Cauta recursiv fiindca importul GLB baga mesh-urile sub un nod-radacina cu
## numele fisierului; daca schimbi structura scenei, numele raman ancora.
func _collect() -> void:
	_meshes.clear()
	for n in stage_nodes:
		var found := _find_by_name(self, String(n))
		if found == null:
			push_warning("LavaFlowHazard: lipseste nodul '%s' — verifica "
				% n + "numele din lava_flow.glb (sunt contract)")
		_meshes.append(found)


func _find_by_name(node: Node, want: String) -> Node3D:
	for child in node.get_children():
		if child.name == want and child is Node3D:
			return child as Node3D
		var deep := _find_by_name(child, want)
		if deep != null:
			return deep
	return null


## Un singur stadiu vizibil. Variantele stinse NU intra in numaratoarea garzii
## (`probe_decor` numara doar ce se randeaza) — de-asta stau toate trei in
## scena, in loc sa se instantieze la schimbare.
func _apply() -> void:
	for i in _meshes.size():
		var m := _meshes[i]
		if m != null:
			m.visible = (i == _stage)
