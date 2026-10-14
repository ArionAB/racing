class_name WaterfallDecor
extends Node3D
## Cascada ca DECOR, fara hazard (Transfagarasan G, N7).
##
## [WaterfallVisual] e vizualul partajat al perdelelor de apa din Fiordland, dar
## il construieste doar `WaterfallHazard` (care are si zona de coliziune si ciclul
## de ploaie). Pe o pista fara hazard de apa (Track21), cascada de pe perete e
## doar o vedere: acest nod o pune in scena si atat — fara corp, fara zona de
## repunere, fara ceas.
##
## Reperul e cel al vizualului: X = grosime, Y = inaltime, Z = latimea perdelei
## (de-a lungul peretelui). Baza (Y = 0) sta la piciorul peretelui, deci nodul se
## aseaza cu originea pe teren si se roteste cu Z paralel cu peretele.
##
## Costa un material de shader si unul de spray, UNICE pe pista (statice in
## WaterfallVisual) — oricate astfel de noduri ar fi.

## Grosimea (X), inaltimea (Y) si latimea (Z) perdelei, in metri.
@export var curtain_size: Vector3 = Vector3(3.0, 28.0, 6.0)
## Particulele de spray de la baza (bugetul real e overdraw-ul: 16 ca la ploaie).
@export var spray_count: int = 16

var visual: WaterfallVisual


func _ready() -> void:
	visual = WaterfallVisual.new()
	visual.name = "Perdea"
	add_child(visual)
	visual.build(curtain_size, spray_count)
