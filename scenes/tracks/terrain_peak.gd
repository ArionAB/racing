@tool
class_name TerrainPeak
extends Marker3D
## Un masiv declarat, editabil VIZUAL: tragi nodul in viewport, bifezi
## Regenerate pe radacina pistei, si muntele rasare acolo.
##
## Pozitia nodului spune totul despre varf: X/Z = unde sta masivul in lume,
## Y = cota varfului (tragi in sus = munte mai inalt). Raza se da in Inspector.
##
## Nodul e o DECLARATIE, nu muntele insusi: TrackFromPath aduna nodurile astea
## si le da mai departe ca acelasi Vector4(x, z, raza, cota) pe care il declara
## si pistele scrise in cod (vezi Track09._peak_specs). Profilul de dom,
## zgomotul de flanc si banda de protectie a asfaltului
## (TrackSideSampler._lift_peaks) raman EXACT aceleasi — o singura
## implementare, doua feluri de a o hrani.
##
## De aceea si Marker3D, nu MeshInstance3D: muntele adevarat e terenul
## regenerat, care poarta coliziune, culoare de panta si tot decorul asezat pe
## ground_y. Crucea gizmo-ului se intinde pana la raza declarata, ca sa vezi
## amprenta inca dinainte de primul Regenerate.
##
## Limita de care sa stii: panza de teren e un patrat de minim 760 m centrat
## pe pista (Track._world_extent). Un varf pus mult dincolo de ea s-ar reteza
## la margine — dar "un munte in mijlocul hartii" e mereu inauntru.

## Raza la care profilul de dom moare complet (metri).
@export var radius_m: float = 80.0:
	set(value):
		radius_m = maxf(value, 1.0)
		gizmo_extents = radius_m
## INSULA: masivul se ridica DUPA saparea rapelor, din terenul deja sapat
## (fundul marii), nu inaintea lor. Implicit fals = comportamentul vechi,
## in care rapele taie si prin masive (TrackSideSampler.ground_y: masivele
## sunt inainte de benzi si de taieturi, deliberat — o scurtatura isi
## re-aseaza terenul peste flanc). Masurat pe Fiordland (21 sep 2026): Mitre
## Peak declarat la 60 m iesea 51,7 m fiindca centrul statea pe muchia
## sapaturii rapei 0, iar orice varf pus IN golf era retezat la podeaua de
## -30 m. Cu flagul, domul porneste de la fundul apei si urca la cota
## declarata: singurul fel de a avea un varf care iese din mare. Vezi
## TrackSideSampler._lift_island_peaks pentru profil (blend din terenul
## existent, nu smax — altfel marginea domului ar face o clatita la cota 0).
@export var island: bool = false


func _ready() -> void:
	# Setter-ul nu ruleaza pentru valoarea implicita la instantiere — crucea
	# ar ramane la cei 0.25 m ai lui Marker3D si amprenta n-ar comunica nimic.
	gizmo_extents = radius_m
