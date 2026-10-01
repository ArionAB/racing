@tool
class_name TerrainBluff
extends Marker3D
## ABRUPTUL: o latura de masiv care cade scurt, cu un taluz si terase la picior.
## Editabil vizual, ca [TerrainPeak] / [TerrainHollow]: tragi nodul, rotesti,
## bifezi Regenerate pe radacina pistei.
##
## De ce exista (Jodhpur, Track17, POI F — „orasul sub tine", decizia
## dezvoltatorului din 30 sep 2026). Stanca fortului e un [TerrainPeak], iar
## profilul lui de dom e un smoothstep pe 100 m: de pe varful bastionului
## (+40) terenul spre oras cobora cu 8 m pe primii 60 m, deci camera vedea o
## CUPOLA de pamant (buza convexa ascundea tot ce era sub ea), nu o cadere.
## Criticul orb, de doua ori: „sub bastion nu e cadere". Un dom mai ingust ar
## fi strans stanca pe TOATE laturile, inclusiv pe cea cu zigzagul portilor (E),
## care nu se atinge. Trebuia o reparatie pe O singura latura.
##
## [b]Ce declara.[/b] Pozitia nodului = mijlocul BUZEI (X/Z) si cota ei (Y).
## Axa +Z locala a nodului = directia in care cade terenul. De la buza, pe
## [member run_m] metri, plafonul coboara LINIAR cu [member drop_m] (o fata
## plana: memoria `suprafete-din-placi-plane`), apoi [member terrace_count]
## terase late de [member terrace_tread_m], fiecare cu [member terrace_rise_m]
## mai jos decat precedenta. Ultima tine pana la [member length_m], apoi
## plafonul se stinge pe [member end_fade_m]. Lateral: plin pe
## [member half_width_m], stins pe [member side_fade_m].
##
## [b]E un PLAFON, ca [TerrainHollow].[/b] Nu ridica nimic: unde terenul era
## deja mai jos, ramane unde era. Deci nu poate face un zid din greseala, doar
## o groapa — si groapa se tine departe de asfalt prin [member road_clear_m]
## (masurat de la MARGINEA soselei celei mai apropiate, ca banda de protectie
## a masivelor). Pe o pista fara noduri de felul asta `ground_y` nu se schimba
## cu nimic (lista samplerului e goala).
##
## [b]Taluz, nu zid.[/b] Grila de teren are 7,92 m (Track.TERRAIN_CELL): o
## cadere de 25 m pe 22 m iese pe ~3 celule, adica ~50° pe mesh — citeste ca
## stanca (tema coloreaza panta > 30° ca stanca), fara sa ceara geometrie de
## faleza ([CliffFace] e legat de buza unei rape de pe traseu, nu de un masiv).
## Treptele teraselor sunt si ele coarde de grila: o treapta de 3 m pe o rampa
## de 4 m iese ~3 m pe o celula, deci umplutura de oras (CityFill, prag 2,5 m)
## lasa goale randurile de pe trepte si terasele se citesc prin case.

## Jumatatea de latime a buzei (m), pe care abruptul e plin.
@export var half_width_m: float = 30.0
## Pe cati metri lateral se stinge abruptul dincolo de [member half_width_m].
@export var side_fade_m: float = 16.0
## Lungimea orizontala a taluzului (m).
@export var run_m: float = 22.0
## Cat coboara taluzul de la buza la prima terasa (m).
@export var drop_m: float = 25.0
## Cate terase (niveluri) la piciorul taluzului; 1 = o singura podea.
@export var terrace_count: int = 3
## Latimea unei terase, masurata pe directia de cadere (m).
@export var terrace_tread_m: float = 22.0
## Cat coboara fiecare terasa fata de precedenta (m).
@export var terrace_rise_m: float = 3.0
## Pana unde (de la buza, pe directia de cadere) tine plafonul plin (m).
@export var length_m: float = 150.0
## Pe cati metri se stinge plafonul dupa [member length_m].
@export var end_fade_m: float = 40.0
## Distanta de la MARGINEA asfaltului sub care abruptul e stins complet (m);
## plin la `road_clear_m + 8`.
@export var road_clear_m: float = 6.0


## Declaratia in forma pe care o citeste samplerul (vezi
## [method TrackSideSampler._carve_bluffs]): 15 numere, in coordonatele
## pistei `track` (ca la [TerrainPeak] — conteaza daca nodul e grupat sub un
## parinte cu transformare proprie).
func spec(track: Node3D) -> PackedFloat32Array:
	var p := track.to_local(global_position)
	var fwd := track.global_transform.basis.inverse() * global_transform.basis.z
	var d := Vector2(fwd.x, fwd.z)
	d = d.normalized() if d.length() > 1e-4 else Vector2(0, 1)
	return PackedFloat32Array([p.x, p.z, d.x, d.y, p.y,
		half_width_m, side_fade_m, run_m, drop_m,
		terrace_tread_m, terrace_rise_m, float(maxi(terrace_count, 1)),
		length_m, end_fade_m, road_clear_m])
