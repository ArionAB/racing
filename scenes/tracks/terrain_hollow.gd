@tool
class_name TerrainHollow
extends Marker3D
## Un volum SCOBIT din teren, editabil vizual: tragi nodul in viewport, bifezi
## Regenerate pe radacina pistei, si stanca ramane goala pe dinauntru.
##
## Perechea pe MINUS a lui [TerrainPeak], si nu din simetrie de dragul
## simetriei — fara ea o "stanca goala" e imposibila, exact cum fara
## [TerrainPeak] era imposibil un munte. Motivul e acelasi camp de inaltime:
## terenul URMEAZA soseaua (vezi [method TrackSideSampler.ground_y]), deci orice
## bucata de drum care trece pe deasupra unui gol umple golul cu piatra pana la
## cota ei.
##
## Cazul masurat pe Cappadocia, POI G: spirala urca pe interiorul stancii de la
## y=12 la y=47.5 pe un cilindru cu raza 28 m, iar drumul de IESIRE (platoul,
## y~48) traverseaza gura stancii pe deasupra. Fiind pe pamant, el trage lacatul
## local (GROUND_LOCK_LEN) si aseaza terenul la 48 m in mijlocul hornului —
## 196 din 984 de puncte coapte ingropate, cel mai adanc cu +38.40 m. Masina ar
## fi intrat intr-un perete de tuf plin exact acolo unde e gimmick-ul pistei.
##
## [b]De ce nu ajunge masca de pasaj.[/b] `custom_overpass_ranges` scoate
## punctele elicei din media terenului, si aia e corect (altfel cele doua ture
## s-ar media intre ele). Dar masca spune doar „ignora drumul asta"; nu spune
## nimic despre ce e SUB el, iar campul se umple linistit din ALT drum — chiar
## din cel de deasupra. Golul trebuie declarat ca gol.
##
## [b]Ce declara nodul.[/b] Un cilindru vertical: X/Z = axa, Y = PODEAUA
## (terenul nu urca peste ea inauntru), raza in Inspector. Peretele nu se
## subtiaza brusc: pe [member wall_m] metri dincolo de raza scobitura se stinge
## neted, deci exteriorul masivului ramane intreg — pe Cappadocia, la r=32 m
## terenul e la podea (11 m) si la r=48 m creasta e la 49 m.
##
## [b]E un PLAFON, nu o groapa.[/b] Sub podea nu se sapa nimic: acolo unde
## terenul era deja mai jos (valea de la intrare) ramane unde era. Asa
## scobitura nu poate crea o prapastie din greseala.
##
## Ca [TerrainPeak], nodul e o DECLARATIE, nu geometria: piatra pe care o vezi e
## terenul regenerat, cu coliziune, culoare de panta si decor asezat pe ground_y.

## Raza cilindrului scobit (metri), masurata de la nod in plan XZ.
##
## Se da cel putin cat raza spiralei PLUS jumatatea de latime a carosabilului —
## dar NU exact atat, fiindca marginea nominala nu e marginea reala.
##
## Cifra exacta (28 + 6 = 34 pe Cappadocia) a fost masurata gresita: la raza
## nominala scobitura e inca plina, si abia dupa ea incepe palnia de `wall_m`
## (vezi `_carve_hollows`: `mix = 1 - smoothstep(raza, raza+perete, d)`, deci
## mix=1 doar SUB raza). Cu 34 fix, punctele de INTRARE in elice — care vin din
## afara spre interior, la r intre 43 si 33 m, si sunt inca late de 7 m, nu 6 —
## cadeau in palnie. Acolo terenul nu mai era plafonat la podea, iar campul il
## ridica din drumul de deasupra: masurat +35 m de tuf peste asfalt, intrand
## pana la 1.7 m de AXA benzii. Masinile intrau cu jumatatea dreapta in stanca
## si se opreau — cursa nu se termina (ProbeRace: 0.80 tururi, 35 de repuneri).
##
## Regula, deci: raza acopera si APROPIEREA, cu latimea de acolo, plus o marja
## care sa tina intrarea in afara palniei. Pe Cappadocia 42 m — intrarea la
## r=33.9 ramane cu 8 m sub raza. Se verifica cu tools/ProbeLaneClear.tscn.
@export var radius_m: float = 30.0:
	set(value):
		radius_m = maxf(value, 1.0)
		gizmo_extents = radius_m + wall_m

## Pe cati metri dincolo de raza se stinge scobitura, ca peretele sa aiba
## grosime in loc sa fie o taietura de cutit.
##
## 12 m nu e o cifra de stil: grila de teren e la ~8 m, deci un racord mai scurt
## decat doua celule iese oricum in trepte, iar unul mai lung ar manca din
## masivul care trebuie sa citeasca plin din vale.
@export var wall_m: float = 12.0:
	set(value):
		wall_m = maxf(value, 0.0)
		gizmo_extents = radius_m + wall_m


func _ready() -> void:
	# Ca la [TerrainPeak]: setter-ul nu ruleaza pentru valoarea implicita la
	# instantiere, deci crucea ar ramane la cei 0.25 m ai lui Marker3D si
	# amprenta n-ar comunica nimic inainte de primul Regenerate.
	gizmo_extents = radius_m + wall_m
