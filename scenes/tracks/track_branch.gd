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

## Plafonul de viteza PE BANDA, ca fractie din viteza maxima a masinii.
##
## A treia contragreutate, langa `wet` si latime — si cea mai naturala pentru
## un drum de tara: pamantul batatorit nu tine viteza asfaltului. 1.0 = neatins
## (banda merge cat soseaua). 0.85 taie 15% din plafon, cat sa castigi din
## scurtatura doar daca o iei curat. Se aplica DUPA offroad, deci pe iarba de
## langa banda ramane pedeapsa obisnuita, nu una dubla.
@export_range(0.5, 1.0, 0.01) var speed_factor: float = 1.0

## De unde PLEACA banda de pe bucla principala, ca fractie de tur. Negativ =
## se deduce din primul punct desenat (implicit, vezi antetul clasei).
##
## Exista pentru un caz pe care deducerea nu-l poate servi: capatul dedus e
## mereu piciorul PERPENDICULAREI pe sosea din primul punct, deci banda pleaca
## mereu LATERAL, in unghi drept. Pentru o panglica la sol asta e doar un
## racord scurt; pentru o banda `elevated` peste apa e chiar accidentul —
## AI-ul e atras spre banda (Track.branch_lure) de la 70 m si tinteste un
## punct la 20 m pe ea, iar daca banda a ajuns deja la 25 m in lateral,
## masina iese de pe sosea in apa inainte sa apuce sa urce pe tablier.
## Masurat pe Chongqing: 12-18 repuneri pe cursa, toate intre fractiile
## 0.42 si 0.44.
##
## Cu fractia declarata, capatul se muta INAINTEA punctelor desenate si banda
## se desprinde in unghi mic, pe langa marginea soselei, peste teren uscat —
## adica exact cum arata o banda de desprindere reala. Se declara cand banda
## trebuie sa plece TANGENT; altfel se lasa negativ.
@export_range(-0.01, 1.0, 0.001) var entry_at: float = -1.0

## Unde REVINE banda pe bucla, ca fractie de tur. Negativ = se deduce din
## ultimul punct desenat. Aceleasi motive ca [member entry_at].
@export_range(-0.01, 1.0, 0.001) var exit_at: float = -1.0

## Banda sta IN AER: telecabina de pe Chongqing, o pasarela. Terenul NU o
## urmareste — fara flag, samplerul ridica pamantul pana la cota benzii
## (_lift_branches) si o banda peste un golf ar iesi un dig de pamant, nu un
## cablu. Banda ramane in fizica si in AI exact ca oricare alta.
@export var elevated: bool = false

@export_group("Suprafata")

## Din ce e facuta banda. THEME = ce spune tema pistei (`branch_surface`:
## nisip pe insula, drum de tara pe munte); restul suprascriu tema DOAR pe
## banda asta.
##
##   SAND       banda plata de nisip (bancul submers din Okinawa) — reteta
##              veche, neschimbata cu un pixel
##   DIRT_ROAD  drum de tara: doua fagase batatorite, brazda de iarba intre
##              ele, margini zdrentuite care se topesc in pajiste, smocuri de
##              iarba pe margini si pe brazda
##   GRAVEL     pietris batatorit: aceleasi margini zdrentuite, fara fagase
##              si fara iarba pe mijloc
enum Surface { THEME, SAND, DIRT_ROAD, GRAVEL }
@export var surface: Surface = Surface.THEME

## Culoarea pamantului benzii. Alfa 0 = culoarea din tema (`branch_tint`).
## Se INMULTESTE cu granulatia texturii, deci alege-o cu ~15% mai deschisa
## decat vrei s-o vezi pe ecran.
@export var tint: Color = Color(0.0, 0.0, 0.0, 0.0)

## Adancimea fagaselor (m), doar la DIRT_ROAD. 3-5 cm se citesc din umbra;
## peste 8 cm banda arata sapata, nu calcata. 0 = fara fagase.
@export_range(0.0, 0.12, 0.005, "suffix:m") var rut_depth: float = 0.04

## Cat de inierbata e brazda dintre fagase, doar la DIRT_ROAD: 0 = pamant
## peste tot (drum umblat des), 1 = iarba plina pe mijloc (poteca rara).
## Iarba vine si ca smocuri, nu doar ca nuanta.
@export_range(0.0, 1.0, 0.05) var grass_center: float = 0.6

## Cat de neregulate sunt marginile (m). 0 = taiate cu rigla (banda pare
## lipita peste teren). ~0.8 e destul cat marginea sa para calcata, nu trasa.
@export_range(0.0, 2.0, 0.1, "suffix:m") var edge_noise: float = 0.8

## Denivelari de rulare (m amplitudine): gropi si valuri de 1-3 m lungime.
## Peste 0 intra SI in coliziune — suspensia le simte, caroseria se leagana.
## 0.03 e „drum de tara"; 0.06 e „drum forestier". 0 = neted (implicit,
## ca banda sa nu schimbe feel-ul pana nu ceri).
@export_range(0.0, 0.10, 0.005, "suffix:m") var bumpiness: float = 0.0

## Iarba densa (smocuri) pe margini si pe brazda, doar la DIRT_ROAD.
## Se stinge daca vrei banda curata sau daca numeri triunghiuri.
@export var tufts: bool = true


## Numele retetei, cum il citeste [Track] (cheia `surface` din spec).
## THEME intoarce "" — pista completeaza din tema.
func surface_name() -> String:
	match surface:
		Surface.SAND: return "sand"
		Surface.DIRT_ROAD: return "dirt_road"
		Surface.GRAVEL: return "gravel"
	return ""


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
