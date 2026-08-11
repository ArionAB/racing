@tool
class_name TrackBranch
extends Path3D
## O scurtatura desenata VIZUAL: adaugi nodul, tragi de punctele curbei in
## viewport, bifezi Regenerate pe radacina pistei, si banda apare.
##
## Nodul e o DECLARATIE, ca [TerrainPeak]: [Track] aduna nodurile astea si le
## trece prin acelasi [code]_make_branch()[/code] pe care il folosesc si pistele
## scrise in cod (vezi Track09._branch_specs). Coacerea curbei, materialul de
## tema, coridorul din sampler si [TrackRoute.frac_at] raman EXACT aceleasi —
## o singura implementare, doua feluri de a o hrani.
##
## [b]CAPETELE NU SE DESENEAZA.[/b] Tragi doar punctele din MIJLOCUL scurtaturii;
## unde se desprinde si unde revine se citeste de pe bucla principala, la
## fractiile cele mai apropiate de primul si ultimul punct al curbei tale.
##
## Motivul e acelasi pentru care `_branch_specs()` cere de la inceput doar
## punctele intermediare: un capat desenat de mana ramane in urma la prima
## ajustare a traseului principal si lasa o treapta in aer. Asa, muti traseul
## si scurtatura se reataseaza singura.
##
## [b]CONTRAGREUTATEA E OBLIGATORIE, nu optionala.[/b] O scurtatura fara pret e
## un cadou: o iei mereu, deci nu mai e o decizie. Ai doua parghii, si se aleg
## din LUME, nu dintr-un tabel:
##   [member wet]        banda uda, grip lateral taiat (bancul de nisip din Okinawa)
##   [member half_width] mai ingusta decat pista: singur incapi, in trafic nu
##                       (poteca de pasune de pe Alpii, 3.2 fata de 7.0)
##
## [b]Limitele de geometrie sunt cele ale oricarei curbe de pista[/b] si NU se
## relaxeaza aici: raza virajului > [member half_width], iar banda trebuie sa
## stea la >= 2x latime de bucla principala pe portiunile paralele. Sub ele
## asfaltul se pliaza peste el insusi si blocheaza masinile. Dupa ce desenezi,
## ProbeLayout si ProbeRace raman arbitrii — ProbeRace e cel care spune daca
## AI-ul chiar trece pe aici.

## Jumatatea latimii benzii, in metri. 0 sau mai mic = cat pista.
##
## Mai INGUSTA decat pista e contragreutatea implicita si cea mai citibila din
## mers: vezi antetul clasei.
@export var branch_half_width: float = 0.0

## Banda e permanent uda: cine merge pe ea are grip lateral taiat.
##
## Cealalta contragreutate. Se alege din lume — un banc de nisip spalat de mare
## E ud, o pasune insorita de munte nu.
@export var wet: bool = false

## Numele afisat in sonde si in mesaje de eroare.
@export var label: String = ""


## Punctele din mijlocul scurtaturii, in coordonatele PISTEI.
##
## Conteaza daca nodul e grupat sub ceva cu transformare proprie (sau daca a
## fost tras el insusi in viewport): curba e in spatiul LUI, iar `baked` si tot
## ce citeste samplerul sunt in spatiul pistei. Fara conversia asta, o
## scurtatura desenata corect ar aparea deplasata dupa prima mutare a nodului.
func mid_points(track: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if curve == null:
		return out
	for i in curve.point_count:
		out.append(track.to_local(
			to_global(curve.get_point_position(i))))
	return out
