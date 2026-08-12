@tool
class_name HazardMarker
extends Marker3D
## Un gimmick declarat, editabil VIZUAL: tragi nodul pe sosea, alegi tipul in
## Inspector, bifezi Regenerate pe radacina pistei, si obstacolul apare acolo.
##
## Nodul e o DECLARATIE, nu obstacolul insusi — exact tiparul lui [TerrainPeak],
## [TrackBranch] si [TrackChannel]. [Track] aduna nodurile astea si le trece
## prin ACELEASI `_build_*` pe care le folosesc si pistele scrise in cod, deci
## exista o singura implementare per gimmick, hranita in doua feluri.
##
## Ce se declara si ce se DERIVA — impartirea e tot ce conteaza aici:
##   - declari: tipul si POZITIA (tragi nodul in viewport)
##   - se deriva: fractia pe traseu, semilatimea soselei acolo, lateralul si
##     directia drumului
##
## Motivul e lectia din #234, scrisa in `Track._node_branches`: un capat de
## banda scris de mana ramane in urma la prima ajustare a traseului si lasa o
## treapta in aer. Aici e la fel — o fractie scrisa de mana (`0.62`) nu spune
## nimic cand muti doua puncte de control, in timp ce un nod tras pe asfalt
## ramane pe asfalt fiindca fractia se recalculeaza la fiecare Regenerate.
##
## De aceea si Marker3D, nu MeshInstance3D: obstacolul adevarat e cel construit
## la Regenerate, cu coliziunea si mecanica lui. Nodul e doar unde-ul.
##
## Y-ul nodului e IGNORAT deliberat. Fiecare gimmick isi asaza singur cota:
## bolovanul cade pe asfalt, trenul sta la cota drumului cu estacada sub el,
## caruselul se planteaza in mijlocul soselei. Un Y luat de la nod ar insemna ca
## un nod tras cu 3 m prea sus lasa un carusel plutind — si nimeni nu s-ar uita
## la Y-ul nodului cand ar cauta de ce.

## Tipurile care se pot planta manual.
##
## Sunt exact gimmickurile care se plaseaza azi PE O FRACTIE din traseu, adica
## alea pentru care nodul e o traducere directa. Lipsesc deliberat:
##   - LiftBridge: se leaga de un canal ([TrackChannel]), nu de o fractie — se
##     declara acolo, cu `jump: false`;
##   - WaveSurge / WaterHose: portiuni de sosea, nu obiecte punctuale.
enum Kind {
	SLIDING,    ## bariera/bolovan care matura soseaua dintr-o parte in alta
	ROCKFALL,   ## bolovan care cade de pe faleza pe o banda
	CAROUSEL,   ## morisca plantata in mijlocul drumului
	TRAIN,      ## trecere de cale ferata cu tren
	TYPHOON,    ## tromba care te ridica si te invarte
	DEFLECTOR,  ## panta care te arunca pe cealalta banda
	FLYOFF,     ## creasta care arunca toata pista in aer
	EXCAVATOR,  ## excavatorul ruginit care matura cu bratul
	AVALANCHE,  ## masa de zapada care se rostogoleste peste sosea
}

@export var kind: Kind = Kind.SLIDING

## Pentru DEFLECTOR: pe ce parte a soselei sta panta. Ignorat de restul.
##
## Nu se deduce din pozitia nodului fiindca deflectorul se planteaza pe AXA
## drumului si isi ia latura din semn — un nod tras cu 20 cm peste mijloc ar
## intoarce panta fara ca nimeni sa fi cerut asta.
@export_enum("Dreapta:1", "Stanga:-1") var deflector_side: int = 1


func _ready() -> void:
	# Crucea gizmo-ului cat un obstacol tipic, ca sa vezi amprenta inainte de
	# primul Regenerate. Marker3D vine cu 0.25 m — invizibil pe o sosea de 20 m.
	gizmo_extents = 3.0
