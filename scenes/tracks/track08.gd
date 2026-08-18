@tool
extends Track
## Pista 8 — "Okinawa manual": insula INELARA, cu laguna in mijlocul
## circuitului, si banc de lucru pentru decor asezat DE MANA.
##
## Gimmick: LUMEA E O GOGOASA. Soseaua face inconjurul unei insule al carei
## centru nu e uscat, ci o laguna turcoaz de mic adanc. Peste tot pe tur ai apa
## in AMBELE parti — marea deschisa pe exterior, laguna pe interior — iar
## interiorul buclei, care pe orice alta pista din joc e o scurtatura prin iarba
## sau nisip, aici e pur si simplu inexistent: iesi pe stanga si esti in apa.
##
## Traseul, cotele si conturul apei NU sunt desenate din ochi. Sunt extrase din
## referinta `assets/okinawa_v2/okinawa_v2.png`:
##   - traseul, din harta de tur din coltul din dreapta sus (masca alba a
##     soselei -> profil radial -> puncte de control alese dupa curbura);
##   - cotele, din graficul "ELEVATION PROFILE" (0 m la start, +30 m la 1125 m,
##     inapoi la nivelul marii pana la 1800 m), esantionat pe LUNGIME DE ARC;
##   - conturul lagunei, din masca de apa dinauntrul buclei.
## Abaterea maxima a curbei rezultate fata de traseul trasat e 2.3 m (media
## 0.6 m) — sub jumatate de latime de banda.
##
## ISTORIC. Pista a fost pana in august 2026 o SUBCLASA a lui "Okinawa v2"
## (`track07.gd`), din care mostenea traseul, cotele, laguna si scurtatura,
## suprascriind doar abaterile. Cand celelalte piste au fost scoase din joc
## (raman Dunele, Okinawa manual si Alpii), clasa de baza a ramas fara pista
## proprie, asa ca a fost contopita aici. De aceea comentariile de mai jos
## compara pe alocuri cu "Okinawa v2": acelea sunt abaterile de atunci, pastrate
## fiindca explica DE CE arata pista asa, nu fiindca ar mai exista o a doua.
##
## `world_seed_name` e singurul lucru care NU se schimba odata cu numele, si
## conteaza: faza dunelor, imprastierea decorului si falezele se seamana din
## numele pistei (vezi Track._world_seed). Fara linia aia, decorul asezat cu
## mouse-ul ar fi plutit sau s-ar fi ingropat la prima redenumire — samanta
## ramane pe "Okinawa v2" tocmai ca terenul de sub piesele manuale sa nu se
## miste.
##
## CUM SE LUCREAZA PE EA: docs/decor_manual.md. Pe scurt — deschizi
## Track08.tscn (scriptul e @tool, deci pista se construieste in editor),
## adaugi sub radacina un Node3D `DecorManual` cu scenes/props/world_prop.gd,
## si tragi GLB-uri sub el. Tot ce e salvat in .tscn are `owner` setat, deci
## supravietuieste lui rebuild(); tot ce genereaza codul nu, si se sterge.
##
## DE STIUT: decorul procedural mostenit de la Okinawa v2 ramane pornit si NU
## te vede — se poate suprapune peste ce asezi. Daca vrei panza goala, cere
## un intrerupator de decor; nu l-am inventat aici ca sa nu difere de v2 in
## tacere.

func _init() -> void:
	half_width = 7.0
	# Media cotelor soselei e +9.4 m (profilul urca la 30 si coboara la 0), deci
	# marea sta la -1.6. Adica 1.6 m sub dreapta de start — exact freeboard-ul
	# unui dig cu tetrapozi.
	sea_level_offset = -11.0
	# Fundul lagunei la -5.6, adica 4 m de apa — sub Track.SEA_REEF_DEPTH (5),
	# deci culoarea coapta e turcoaz de recif pe TOATA suprafata ei, nu albastru
	# de larg ca marea dinafara (care sta la 15 m, peste SEA_NEAR_DEPTH).
	#
	# Prima incercare a fost 20 (9 m de apa) si iesea gresit din exact motivul
	# asta: la 9 m din 14, rampa de culoare a apei e deja pe jumatatea dinspre
	# larg, deci laguna citea bleumarin, iar ondulatia fundului o rupea in pete.
	# Referinta arata o laguna prin care se vede nisipul — asta inseamna metri,
	# nu zeci de metri.
	lagoon_depth = 15.0
	# Tema NU e optionala si tacerea ei a costat o masuratoare: fara ea pista
	# ramane pe valorile implicite ale lui Track — "forest" in loc de "island".
	# Geometria iese identica (aia vine din metode, nu din constructor) si
	# sondele de traseu dau aceleasi cifre, dar pista pierde marea, laguna si
	# decorul de banda: sonda de scena numara 232 de mesh-uri in loc de 741.
	apply_theme("island")
	track_name = "Okinawa manual"
	# Numele s-a schimbat, lumea nu.
	world_seed_name = "Okinawa v2"
	# DRUM DE NISIP, nu asfalt. A doua abatere a acestei piste de la Okinawa v2
	# (dupa Stramtoarea Kaiun) si prima care schimba SUPRAFATA pe care se conduce.
	#
	# Traseul, cotele si latimea raman neatinse — deci si scenografia, si tot ce
	# se aseaza de mana. Se schimba doar din ce e facut drumul, iar de acolo curg,
	# automat: nisip batatorit in loc de asfalt racoros, zero marcaje pictate,
	# zero urme desenate dinainte, si masini care scot praf si lasa brazde cat
	# timp ruleaza, nu doar cand derapeaza.
	#
	# De ce merita: pe o insula de nisip coraligen, panglica de asfalt era
	# singurul lucru din cadru care venea din alta lume. Vezi Track.road_surface
	# pentru ce anume atarna de linia asta.
	road_surface = "dirt"


## Traseul, sector cu sector. 1806 m, anvelopa 562 x 502 m.
##
## Masurat in motor (tools/probe_layout.gd): raza minima 14.6 m la frac 0.21,
## panta maxima 14.8% la 0.65, apropiere de sine 51.4 m. Toate cu marja fata de
## praguri (raza > 7, panta < 22%, separare > 14).
##
## Cotele sunt profilul din referinta, nu inventate: fiecare punct isi ia y-ul
## de la fractia lui de tur. Daca se muta un punct pe orizontala, cota lui NU
## mai corespunde profilului — se reciteste, nu se ajusteaza din ochi.
func _code_points() -> Array[Vector3]:
	return [
		# --- 1. Digul de start: dreapta la nivelul marii, tetrapozi pe exterior
		Vector3(30, 0.2, 217),    # LINIA DE START, mers spre -X
		Vector3(-2, 0.2, 201),
		Vector3(-43, 0.2, 205),
		Vector3(-84, 0.2, 191),
		# --- 2. Portul: soseaua urca de pe dig si intra printre case ----------
		Vector3(-131, 1.0, 150),
		Vector3(-171, 2.1, 128),
		Vector3(-233, 4.7, 119),
		Vector3(-297, 6.7, 102),
		# --- 3. Capul de vest: cel mai stramt viraj al pistei (raza 16 m) -----
		Vector3(-317, 7.1, 86),
		Vector3(-316, 7.8, 60),
		Vector3(-290, 8.6, 1),
		# --- 4. Coasta de vest: rapid, marea pe dreapta, laguna pe stanga -----
		Vector3(-277, 7.5, -45),
		Vector3(-277, 6.7, -90),
		Vector3(-256, 6.7, -124),
		Vector3(-204, 8.5, -158),
		# --- 5. Urcarea de coasta: de la +8 la +30, fara nicio dreapta lunga --
		Vector3(-130, 12.9, -196),
		Vector3(-89, 14.5, -211),
		Vector3(-60, 15.5, -197),
		Vector3(-28, 15.5, -176),
		Vector3(6, 16.6, -183),
		Vector3(59, 20.9, -217),
		Vector3(111, 26.2, -253),
		# --- 6. Creasta: punctul cel mai inalt, +30 m deasupra marii ----------
		Vector3(161, 27.7, -261),
		Vector3(212, 27.5, -256),
		Vector3(237, 25.4, -237),
		# --- 7. Coborarea de est: 24 m pierduti in 400 m, viraje deschise -----
		Vector3(243, 21.3, -207),
		Vector3(227, 15.5, -150),
		Vector3(212, 11.6, -93),
		Vector3(218, 7.1, -25),
		Vector3(226, 3.2, 60),
		# --- 8. Coltul de sud-est si intoarcerea pe dig -----------------------
		Vector3(232, 3.4, 112),
		Vector3(214, 3.6, 139),
		Vector3(181, 3.2, 184),
		Vector3(161, 2.1, 227),
		Vector3(134, 1.0, 240),
		Vector3(86, 0.0, 237),
	]


## Conturul lagunei, extras din masca de apa a referintei si simplificat la 16
## laturi (Douglas-Peucker, toleranta 5 px = 14 m).
##
## Se apropie pe alocuri pana la 9 m de axa soselei — la creasta, unde in
## referinta drumul chiar merge pe buza stancii deasupra apei. Nu e o problema
## de siguranta: saparea se aplica pe campul DEPARTAT, iar coridorul soselei
## (45 m plat + 70 m de racord) o tine departe de asfalt. Se vede ca faleza, nu
## ca groapa in drum.
func _lagoon_points() -> Array[Vector2]:
	return [
		Vector2(132, -251),
		Vector2(226, -200),
		Vector2(169, -114),
		Vector2(134, 95),
		Vector2(31, 178),
		Vector2(-83, 112),
		Vector2(-86, 92),
		Vector2(-92, 58),
		Vector2(-186, 15),
		Vector2(-163, -162),
		Vector2(-106, -188),
		Vector2(-54, -131),
		Vector2(43, -142),
		Vector2(57, -171),
		Vector2(91, -174),
		Vector2(94, -231),
	]


## Scurtatura: pragul de corali care taie coltul de nord-est al lagunei.
##
## E singurul loc de pe tur unde o coarda peste apa chiar are ce castiga. Asta
## nu e o alegere de stil, e o consecinta a formei: un inel e convex aproape
## peste tot, deci orice coarda intre doua puncte ale lui trece prin laguna, iar
## cele lungi taie 300+ m dintr-un tur de 1800 — 18%, adica n-ar mai exista
## cursa. Masurat pe toate perechile de fractii: singurele coarde cu castig sub
## 100 m si care chiar trec peste apa sunt in coltul asta.
##
## Masurat de sonda: 218 m de sosea inlocuiti cu 179 m de prag, deci 39 m
## castig (18% din portiunea ocolita, ~1.3 s). Contragreutatea e ca intri pe ea
## IMEDIAT dupa varf, cu 16 m de coborare in fata si banda uda sub roti.
##
## `wet` e contragreutatea propriu-zisa: pragul e spalat de valuri, deci grip
## lateral taiat exact pe portiunea in care cobori cel mai repede. Echilibrul
## dintre castig si cost se gaseste la playtest — aici se fixeaza doar
## geometria.
func _branch_specs() -> Array[Dictionary]:
	# Golit (aug 2026): scurtaturile se deseneaza DOAR de mana, ca noduri
	# [TrackBranch] (Path3D) in scena. Specificatia veche ramane mai jos, ca reper.
	# Era: entry 0.615 (varful crestei), exit 0.735 (coborarea de est, +11 m),
	# half_width 5.5, wet true, label "pragul de corali", puncte
	# (175, 23.6, -207), (179, 19.2, -163), (193, 14.8, -121).
	return []


## Creasta de fly-off, pe coborarea de est.
##
## A stat intai pe urcarea catre varf (0.545), unde o pun si referinta si bunul
## simt — si acolo NU merge, din motive masurate: aterizezi tot pe urcare, deci
## nasul intra in panta, iar sonda de cursa gasea la fiecare tur cate un AI
## oprit pe la 0.59, la mijlocul drumului. Creasta cere o COBORARE dupa ea.
##
## 0.805 e cea mai dreapta bucata din tot turul (raza minima pe o fereastra de
## 40 m: 6400 m) si coboara lin catre nivelul marii. Varful ramane varf — cu
## ruperea de panta de la +6.7% la -8.3% peste el, ridici oricum roțile daca
## intri tare; doar ca nu mai e locul in care ateriza toata lumea prost.
func _flyoff_fracs() -> Array[float]:
	return [0.805]


## Trei rapi, fiecare cu treaba ei.
##
## 1. Coama crestei, pe AMANDOUA laturile: acolo soseaua merge pe o muchie intre
##    mare (nord) si laguna (sud). E decor cu consecinte — de sus se vede ca
##    varful e o creasta ingusta, nu un platou.
## 2. Sub creasta de fly-off, pe coborarea de est. 12 m e peste pragul de 10 din
##    _build_flyoff_net, deci cine rateaza aterizarea chiar cade si e repus. La
##    +4 m cota drumului, fundul iese sub nivelul marii, deci se umple singura:
##    sari peste o limba de apa.
## 3. Digul de start: teren sapat pe ambele laturi ca marea sa vina pana la
##    asfalt. Fara ea, dreapta de start ar fi fost un drum pe o limba de nisip
##    lata de 90 m (terenul urmareste soseaua pe 45 m in fiecare parte), iar
##    tetrapozii din referinta n-ar fi avut ce sa apere. Fereastra trece peste
##    linia de start — _ring_window accepta f1 < f0.
func _ravines() -> Array[Vector4]:
	return [
		Vector4(0.510, 0.580, 16.0, 0.0), # coama crestei
		Vector4(0.770, 0.840, 12.0, 1.0), # sub fly-off, pe coasta de est
		Vector4(0.945, 0.030, 14.0, 0.0), # digul de start, ambele laturi
	]


## Rampa pe iesirea din coasta de vest — a doua cea mai dreapta bucata a
## turului (raza minima 1900 m pe 40 m), pe teren aproape orizontal.
##
## Prima incercare a fost 0.265, in bucla de dupa capul de vest: raza 350 m
## parea destul, dar nu e — o rampa ocupa jumatate din latimea drumului, deci
## intr-un viraj masina care o ia pe partea gresita cade de pe muchia din spate
## si ramane acolo. Sonda gasea doi AI blocati la 0.258 in fiecare rulare.
func _ramp_fracs() -> Array[float]:
	return [0.383]


## Mini-typhoon-ul pe coasta de est, pe intrarea catre dreapta de start.
##
## Fractia NU e aleasa din ochi, e scoasa din `tools/probe_typhoon.gd --scan`,
## care claseaza tot turul dupa cat de dreapta e soseaua, cat de departe e de
## celelalte hazarde, cata panta are si daca maturarea ajunge pe apa. Pista e
## plina — trei rapi, un pod, o rampa, o bariera, o creasta de fly-off, un val si
## un sat — si scanarea gaseste doar trei ferestre libere in tot turul:
## 0.03-0.20, 0.44-0.75 si 0.86-0.92.
##
## 0.877 e cel mai bun punct din ele, si cifrele spun de ce:
##   - raza 203 m, cea mai dreapta bucata din orice fereastra libera care nu e
##     pe o panta. (Cele de 216-219 m sunt fie in sat, fie pe urcarea de 8% la
##     creasta.) O tromba trebuie VAZUTA venind; pe un viraj de 22 m raza, cat
##     au majoritatea punctelor libere, decizia n-ar exista.
##   - panta 0.7%, practic orizontal: cotele aruncarii si ale aterizarii nu sunt
##     distorsionate de o inclinare a drumului.
##   - cota 4 m, adica jos, langa mare — palnia se citeste pe cer si pe apa, nu
##     pe un versant.
##   - 0.072 de creasta de fly-off (0.805) si 0.098 de val (0.975): ~130 m,
##     respectiv ~176 m de sosea. Doua hazarde cu ceas lipite nu produc doua
##     decizii, produc o loterie.
##
## Locul in ritmul turului: e ultima intrebare dinaintea dreptei de start, adica
## exact acolo unde cineva care conduce din memorie a inceput deja sa se
## gandeasca la turul urmator.
func _typhoon_fracs() -> Array[float]:
	# Golit (aug 2026): hazardele se pun DOAR de mana, ca noduri [HazardMarker]
	# in scena. Fractia veche ramane in comentariul de mai sus, ca reper.
	return [] # era [0.877]


## Bariera mobila pe coasta de vest, inainte de rampa.
##
## A stat intai la 0.340 (bucla de dupa capul de vest) si apoi la 0.310, si de
## fiecare data sonda gasea acelasi AI intepenit intre bariera si perete, la
## mijlocul drumului. O bariera care mica pe un drum unde n-ai pe unde s-o
## ocolesti nu e obstacol, e usa. La 0.256 drumul e drept si larg.
func _hazard_fracs() -> Array[float]:
	# Golit (aug 2026): hazardele se pun DOAR de mana, ca noduri [HazardMarker]
	# in scena. Fractia veche ramane in comentariul de mai sus, ca reper.
	return [] # era [0.256]


## Satul din port (id 6 = village_house, texturi de clasa: olane, tencuiala,
## piatra). Pozitiile vin din referinta: casele cu acoperis portocaliu stau pe
## malul de nord al soselei, intre dig si capul de vest. Alternate pe laturi, ca
## drumul sa treaca PRINTRE ele.
##
## Restul satului, poarta shisa si farul sunt in `_scenography()`. Aici raman
## doar reperele care erau deja aici plus cele doua pe care le cer SONDELE:
## `snapshot.gd --landmark=` cere un id din tabelul din track.gd, deci un far
## asezat ca prop de scenografie n-ar mai fi putut fi fotografiat pe nume.
func _landmark_spots() -> Array[Vector3]:
	return [
		Vector3(0.115, 1.0, 6),
		Vector3(0.145, -1.0, 6),
		Vector3(0.175, 1.0, 6),
		# Poarta shisa de la intrarea in sat (referinta, panoul "SHISA GATE"):
		# torii peste drum si perechea de lei, gura deschisa in dreapta.
		Vector3(0.203, 1.0, 8),
		Vector3(0.203, 1.0, 9),
		Vector3(0.203, -1.0, 10),
		# Farul: pe platoul de la creasta, pe latura dinspre larg — singura
		# parte care ramane la cota drumului acolo (masurat cu probe_shore:
		# la frac 0.62, latura -1 sta la 27 m pe toti primii 50 m, iar +1
		# cade la 19 m si apoi in laguna).
		Vector3(0.620, -1.0, 7),
	]


## ############################################################################
## DIGUL DE START: apa de pe asfalt vine din mare, nu dintr-o teava.
##
## A treia abatere de la Okinawa v2, si prima care schimba un HAZARD. Traseul,
## cotele si fractia raman neatinse: se schimba doar ce anume uda drumul la
## 0.975.
##
## [b]De ce[/b]. Okinawa v2 pune acolo un `WaterHose` — o conducta sparta — si
## comentariul ei zice, cuvant cu cuvant, „valul care spala digul". Adica
## intentia era deja marea; furtunul era doar ce exista in cod atunci. Pe insula
## teava nici nu se vede (`hose_model: ""` in tema island), deci sectorul arata
## azi ca un jet de apa care tasneste din nimic peste un dig de tetrapozi.
##
## [b]Ce se schimba pentru cel care conduce[/b], si asta e adevaratul motiv:
## conducta uda mereu, deci digul era o TAXA — treci alunecand, indiferent ce
## faci. Valul uda doar cat trece, deci digul devine o DECIZIE: intri acum, sau
## ridici piciorul o secunda si intri pe uscat. Ultima portiune a turului, exact
## unde se decid depasirile, capata astfel o fereastra. E faza 2 din #106, luata
## aici pe pista de lucru — pe Okinawa v2 banda permanenta ramane, ca sa se poata
## simti diferenta una langa alta.
func _hose_fracs() -> Array[float]:
	return []


func _wave_fracs() -> Array[float]:
	# Golit (aug 2026): hazardele se pun DOAR de mana, ca noduri [HazardMarker]
	# in scena. Fractia veche ramane in comentariul de mai sus, ca reper.
	return [] # era [0.975], aceeasi fractie pe care o avea furtunul


## ############################################################################
## TESTOASA DE PE DRUM: bariera mobila de la 0.256 nu mai e o barca.
##
## A patra abatere de la Okinawa v2, si a doua care schimba un hazard. Fractia,
## amplitudinea maturarii si perioada raman ale lui `_hazard_fracs()` din
## track07.gd — se schimba doar CE anume traverseaza soseaua.
##
## [b]De ce[/b]. Sabani a ajuns `hazard_model` fiindca era barca pe care o aveam
## deja (#107), si a ramas ca „targ ita peste causeway" — o explicatie care merge
## doar cat timp hazardul chiar sta langa apa. La 0.256 e coasta de vest, adica
## exact bucata din tur pe care sonda de tarm o da drept punctul cel mai DEPARTE
## de apa (86-90 m pana la larg). O barca de 5 m care aluneca inainte si inapoi
## la 90 m de mal nu are nicio poveste in spate; o testoasa care traverseaza spre
## plaja are, si e a insulei.
##
## [b]Ce se schimba pentru cel care conduce: nimic[/b], si asta e intentia.
## Masurat cu o sonda pe ambele piste, nu presupus: barca e 5.01 x 1.02 m si
## matura +/-4.50 m; testoasa e 3.60 x 3.63 m si matura +/-5.19 m. In amandoua
## cazurile marginea obstacolului ajunge exact in marginea soselei (5.19 + 1.81 =
## 4.50 + 2.50 = 7.0 = `half_width`), fiindca `SlidingHazard._clamp_travel` cere
## chiar asta si isi taie singur cursa dupa cat de mare e modelul. Perioada iese
## putin mai lunga (2.72 s fata de 2.35 s) tot din asta — cursa e mai lunga la
## acelasi plafon de viteza de maturare, deci nu obstacolul a incetinit.
##
## Si o cota care merita retinuta: testoasa e cat o masina (3.60 x 0.99 m fata de
## 3.80 x 1.00 m cutia unei masini). Nu e un bolovan care te sterge, e un corp de
## marimea ta pe drum.
##
## `hazard_face_travel` NU e cosmetic, e acelasi soi de steag ca `hazard_roll:
## false` de la barca: un animal are un „inainte", deci trebuie sa se uite
## incotro merge. Vezi Track._build_hazard.
func _theme_overrides() -> Dictionary:
	return {
		# Panglica rosie de pe margini se stinge, coliziunea ei ramane (vezi
		# _build_walls): pe un drum de nisip de coasta, o bariera continua de
		# santier era singurul lucru din cadru care nu apartinea insulei.
		# Bariera VIZUALA e treaba scenografiei si a decorului manual: gard de
		# lemn pe buza lagunei, ziduri gusuku spre interior.
		"wall_visible": false,
		# Umerii isi trag implicit culoarea din nisipul de coral intunecat 25%
		# — pe langa drumul OCRU iesea o bordura gri de agregat, singura dunga
		# rece dintre doua suprafete calde. Pamant batut, putin mai inchis
		# decat marginea drumului, ca umarul sa citeasca drept continuarea
		# prafuita a drumului, nu alt material.
		"dust_color": Color(0.62, 0.50, 0.33),
		# Verdele campului, impins spre iarba grasa din referinta: tinta
		# vizuala e pajistea densa, iar pastelul mostenit citea a fanata.
		# Nuanta se calibreaza pe snapshot (--gamecam), nu pe hex-ul din
		# paleta — lumina insulei (soare 1.5 / expunere 1.0) schimba pixelul.
		"inland_tint": Color(0.30, 0.54, 0.19),
		"inland_strength": 0.95,
		# Lumina din referinta (#207): soare de dupa-amiaza tarzie, nu de
		# amiaza. Elevatia coboara 42° -> 33° (umbrele se lungesc ~1.4x, dealul
		# capata volum), culoarea se incalzeste spre auriu, iar contrastul urca
		# putin — pastelul spalat era jumatate din senzatia de "lume goala".
		# Saturatia NU se atinge (compensarea apei e masurata pe 1.18).
		"sun_rotation_deg": Vector3(-33, 135, 0),
		"sun_color": Color(1.0, 0.93, 0.8),
		"adjust_contrast": 1.12,
		"hazard_model": "res://assets/models/props/sea_turtle.glb",
		"hazard_face_travel": true,
		# Mostenite explicit de la tema, ca sa se citeasca tot contractul
		# hazardului dintr-un loc: nu se rostogoleste (i-ar zbura carapacea peste
		# cap), e la scara ei reala din Blender si sta pe atlasul de paleta —
		# fara `hazard_classes`, fiindca nicio clasa de material nu e o carapace.
		"hazard_roll": false,
		"hazard_scale": 1.0,
		"hazard_classes": {},
	}


## ############################################################################
## PAJISTEA SI PIETRELE: densitatea din imaginea de referinta, declarata, nu
## asezata cu mouse-ul.
##
## Referinta drumului de coasta arata doua lucruri pe care Okinawa v2 nu le
## are: iarba VIE (smocuri, flori, tufe pana in buza drumului) si pietre din
## belsug, in ciorchini, pe fasia dintre drum si garduri. Ambele sunt tipare
## STATISTICE, nu compozitii — exact felul de lucru pentru grove/edge, nu
## pentru decor manual: se reface la fiecare rebuild, se coace in MultiMesh,
## si isi gaseste singur pamantul cu ground_y.
##
## `above_sea` la 1.6 e ce tine pajistea PE CAMP: sub BEACH_SAND_TOP (1.4 m)
## terenul e plaja, si un smoc de iarba grasa pe nisipul spalat de valuri ar
## fi la fel de nelalocul lui ca panglica rosie pe care tocmai am stins-o.
## Plaja isi pastreaza imprastierea ei (island_scatter din benzile mostenite).
func _scenography() -> Array[Dictionary]:
	const M := "res://assets/models/"
	var specs := _scenography_island()
	# Decorul asezat cu mouse-ul (dig de tetrapozi, port, urcarea de coasta,
	# creasta, intoarcerea de sud-est) sta ca NODURI sub DecorManual in
	# Track08.tscn, editabile in editor. A fost o vreme promovat aici ca specs
	# "spot"/"world" (#201, track08_manual_specs.gd), dar decizia din aug 2026
	# e: sketchpad-ul ramane sursa de adevar pe toata dezvoltarea, iar
	# promovarea in cod (y re-derivat din ground_y, bake in MultiMesh) se face
	# O DATA, la delivery. Pretul pana atunci: ~550 de desene in plus.
	# Speciile pajistii, declarate O DATA: covorul e taiat in trei lanuri cu
	# goluri intre ele (#209, ritmul plin/gol din style_bible §7) si toate
	# trei trag din aceeasi lista. Speciile ieftine duc greul (smocuri,
	# ~100-250 tri); florile si hibiscusul sunt accentele, nu umplutura.
	var pajiste_species: Array = [
		{"path": M + "rocks/island_scatter.glb",
			"picks": ["Beach_Grass"], "weight": 3.0,
			"scale": [0.9, 1.5], "sink": 0.08},
		{"path": M + "plants/megakit_plants.glb",
			"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
			"weight": 4.0, "scale": [0.8, 1.4], "sink": 0.1},
		{"path": M + "plants/grass_tuft_small.glb", "weight": 2.0,
			"scale": [0.8, 1.3], "sink": 0.08},
		{"path": M + "plants/grass_tuft_large.glb", "weight": 1.2,
			"scale": [0.8, 1.2], "sink": 0.1},
		{"path": M + "flowers/flowers_orange.glb", "weight": 1.2,
			"scale": [0.9, 1.3], "sink": 0.06},
		{"path": M + "flowers/flowers_white.glb", "weight": 0.8,
			"scale": [0.9, 1.3], "sink": 0.06},
		{"path": M + "plants/hibiscus_bush.glb", "weight": 0.8,
			"scale": [0.7, 1.1], "sink": 0.12},
		# Runda 2 (veg_set2): siluetele care lipseau rotatiei — arcul de
		# feriga, tufa plina cu frunze late, a treia culoare de floare
		# (CORAL_SAND, floare decolorata de soare). Ponderile vechi au
		# scazut ca sa faca loc: piesele noi sunt la fel de scumpe ca
		# florile (~750-800 tri), deci amestecul ramane aproape la acelasi
		# cost mediu, doar mai variat la citire.
		{"path": M + "plants/fern_cluster.glb", "weight": 1.0,
			"scale": [0.8, 1.3], "sink": 0.08},
		{"path": M + "plants/broadleaf_shrub.glb", "weight": 0.6,
			"scale": [0.7, 1.1], "sink": 0.1},
		{"path": M + "flowers/flowers_coral.glb", "weight": 0.6,
			"scale": [0.85, 1.2], "sink": 0.06},
	]
	specs.append_array([
		# --- PAJISTEA: trei lanuri cu goluri intre ele. Golurile cad pe
		# strambatoarea cu pod (0.27-0.315) si pe creasta cu ziduri
		# (0.60-0.655) — acolo scenografia mostenita e deja densa, iar un
		# covor continuu pe tot turul citeste a mocheta, nu a camp.
		{"kind": "grove", "label": "Pajiste", "side": 1.0, "both_sides": true,
			"from": 0.03, "to": 0.27, "off": [1.5, 12.0], "spacing": 3.5,
			"above_sea": 1.6, "clear": 2.0, "species": pajiste_species},
		{"kind": "grove", "label": "Pajiste", "side": 1.0, "both_sides": true,
			"from": 0.315, "to": 0.60, "off": [1.5, 12.0], "spacing": 3.5,
			"above_sea": 1.6, "clear": 2.0, "species": pajiste_species},
		{"kind": "grove", "label": "Pajiste", "side": 1.0, "both_sides": true,
			"from": 0.655, "to": 0.93, "off": [1.5, 12.0], "spacing": 3.5,
			"above_sea": 1.6, "clear": 2.0, "species": pajiste_species},
		# --- PATURILE: flori si iarba LIPITE de gardul de pe buza lagunei si
		# de zidul dinspre mare, pe urcarea de coasta — compozitia-semnatura a
		# referintei: nimic nu creste in mijlocul gazonului, totul se aduna la
		# picioarele a ceva. Offseturile stau cu ~0.5 m inauntrul liniei
		# gardului (manual, la ~2.5-3.5 m), deci paturile rasar la baza lui.
		{"kind": "edge", "label": "Paturi_gard", "side": 1.0,
			"from": 0.495, "to": 0.585, "off": 2.0, "spacing": 4.0,
			"jitter": 0.5, "min_ground": 0.8,
			"path": M + "flowers/flowers_orange.glb",
			"scale": [0.9, 1.25], "face": "random", "sink": 0.06,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_A", "Tuft_B"], "count": [1, 2],
				"radius": 1.1, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Paturi_gard", "side": 1.0,
			"from": 0.505, "to": 0.578, "off": 2.6, "spacing": 9.0,
			"jitter": 0.6, "min_ground": 0.8,
			"path": M + "flowers/flowers_white.glb",
			"scale": [0.85, 1.15], "face": "random", "sink": 0.06},
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.452, "to": 0.60, "off": 1.8, "spacing": 4.0,
			"jitter": 0.5, "min_ground": 0.8,
			"path": M + "plants/megakit_plants.glb",
			"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
			"scale": [0.9, 1.4], "face": "random", "sink": 0.1},
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.46, "to": 0.595, "off": 2.7, "spacing": 8.0,
			"jitter": 0.8, "min_ground": 0.8,
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.6, 0.9], "face": "random", "sink": 0.12},
		# Florile lipseau CU TOTUL pe latura zidului (-1): referinta are
		# accente portocalii pe ambele parti ale urcarii, nu doar la gard.
		# Portocaliul conduce (pas 5 vs 10), albul doar puncteaza.
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.462, "to": 0.592, "off": 2.2, "spacing": 5.0,
			"jitter": 0.5, "min_ground": 0.8,
			"path": M + "flowers/flowers_orange.glb",
			"scale": [0.85, 1.2], "face": "random", "sink": 0.06,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_B", "Tuft_D"], "count": [1, 2],
				"radius": 1.1, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.47, "to": 0.585, "off": 3.1, "spacing": 10.0,
			"jitter": 0.6, "min_ground": 0.8,
			"path": M + "flowers/flowers_white.glb",
			"scale": [0.8, 1.1], "face": "random", "sink": 0.06},
		# --- PIETRELE DE MARGINE: semnatura referintei pe urcarea de coasta
		# si pe creasta. Doua siruri decalate pe fiecare latura (off si pas
		# diferite), ca sa citeasca a ciorchini cazuti, nu a margele insirate.
		# Fara coliziune: la 2.8-5 m de margine esti in zona de iertare, nu
		# intr-un slalom nedeclarat (regula benzii `hug` din TrackDecor).
		{"kind": "edge", "label": "Pietre_margine", "side": 1.0,
			"from": 0.44, "to": 0.72, "off": 2.8, "spacing": 6.5,
			"jitter": 1.6, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_01", "Coral_Rock_03", "Coral_Rock_05",
				"Coral_Rock_07"],
			"scale": [0.25, 0.55], "face": "random", "sink": 0.15,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_A", "Tuft_C"], "count": [1, 2],
				"radius": 1.0, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Pietre_margine", "side": 1.0,
			"from": 0.45, "to": 0.71, "off": 4.8, "spacing": 12.0,
			"jitter": 1.8, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_02", "Coral_Rock_04", "Coral_Rock_06",
				"Coral_Rock_08"],
			"scale": [0.4, 0.75], "face": "random", "sink": 0.2},
		{"kind": "edge", "label": "Pietre_margine", "side": -1.0,
			"from": 0.44, "to": 0.72, "off": 3.2, "spacing": 7.0,
			"jitter": 1.6, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_02", "Coral_Rock_05", "Coral_Rock_08"],
			"scale": [0.25, 0.6], "face": "random", "sink": 0.15,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_B", "Tuft_D"], "count": [1, 2],
				"radius": 1.0, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Pietre_margine", "side": -1.0,
			"from": 0.46, "to": 0.70, "off": 5.2, "spacing": 13.0,
			"jitter": 2.0, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_01", "Coral_Rock_04", "Coral_Rock_06"],
			"scale": [0.45, 0.8], "face": "random", "sink": 0.2},
		# --- CIORCHINII: grupuri gata sculptate (rock_cluster), rare, pe tot
		# campul — punctele grele care ancoreaza covorul marunt al pajistii.
		# Cu fusta de smocuri: piatra care sta pe gazon fara iarba la baza e
		# exact citirea de "obiect pus cu mana" pe care o reparam.
		{"kind": "grove", "label": "Ciorchini_pietre", "side": 1.0,
			"both_sides": true, "from": 0.03, "to": 0.93,
			"off": [4.0, 14.0], "spacing": 34.0, "above_sea": 1.6,
			"clear": 3.5, "skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
				"count": [1, 3], "radius": 1.7, "scale": [0.8, 1.3],
				"sink": 0.1},
			"species": [
				{"path": M + "rocks/rock_cluster.glb",
					"picks": ["Cluster_S1", "Cluster_S2", "Cluster_M1"],
					"weight": 3.0, "scale": [0.5, 0.9], "sink": 0.2},
				{"path": M + "rocks/coral_rock.glb",
					"picks": ["Coral_Rock_03", "Coral_Rock_06"],
					"weight": 2.0, "scale": [0.5, 0.9], "sink": 0.25},
			]},
		# --- SUBARBORETUL: sub perdelele de palmieri ale urcarii (M05,
		# 0.44-0.72) v2 are gazon gol; referinta are tufaris marunt sub
		# fiecare coroana. Acelasi amestec ca pajistea, dar pas mai strans
		# si mai aproape de drum — si FARA gol pe 0.60-0.655: acolo pajistea
		# tace ca sa respire zidurile, dar sub copaci golul citeste a chelie.
		# Fara fusta: subarboretul E el insusi covorul, fusta pe vegetatie
		# ar fi geometrie dubla fara castig de citire.
		{"kind": "grove", "label": "Sub_Palmieri", "side": 1.0,
			"both_sides": true, "from": 0.44, "to": 0.72,
			"off": [2.0, 9.0], "spacing": 3.0, "above_sea": 1.6,
			"clear": 2.0, "species": pajiste_species},
		# --- PATURILE DE LA ZIDURI: accente la CAPETELE si la rostul
		# zidului gusuku si ale celor doua tronsoane de gard. Bazele
		# dinspre drum au deja paturi (Paturi_gard, oglindite); ce
		# ramanea gol si se vede din masina sunt exact incheieturile:
		# capetele de zid care se termina brusc in gazon si trecerea
		# dintre cele doua bucati de zid (x 40.8 -> 70.8). Pozitiile
		# sunt DERIVATE din coordonatele zidurilor (Zone05_CoastalClimb din DecorManual,
		# perpendiculara din yaw-ul segmentului, spre drum) — nu asezate
		# cu mouse-ul, de aia stau aici si nu in fisierul regenerabil.
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(0.46, -191.33), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.85, 0.85], "sink": 0.12},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(2.1, -190.9), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [1.0, 1.0], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(41.45, -215.30), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [1.0, 1.0], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(42.55, -214.62), "face": "world",
			"path": M + "flowers/flowers_coral.glb",
			"scale": [0.9, 0.9], "sink": 0.06},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(71.50, -239.21), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [1.0, 1.0], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(72.9, -238.3), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.75, 0.75], "sink": 0.12},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(106.26, -262.16), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.85, 0.85], "sink": 0.12},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(107.3, -261.5), "face": "world",
			"path": M + "flowers/flowers_coral.glb",
			"scale": [0.9, 0.9], "sink": 0.06},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(13.64, -176.71), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.7, 0.7], "sink": 0.1},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(49.19, -199.34), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [0.95, 0.95], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(79.57, -220.66), "face": "world",
			"path": M + "flowers/flowers_coral.glb",
			"scale": [0.9, 0.9], "sink": 0.06},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(104.46, -239.44), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.8, 0.8], "sink": 0.1},
	])
	# --- VERGE-UL: peretele verde de la umarul drumului. Pajistea incepe la
	# 1.5 m si se rarefiaza spre camp; referinta are un tiv CONTINUU in primul
	# metru, pe AMBELE laturi — el face drumul sa citeasca a taiat prin
	# vegetatie, nu asezat peste ea. Trei straturi pe interval (smocuri des,
	# iarba de plaja mediu, flori portocalii rar) — edge cu picks, ca la
	# Paturi: amestecul se face din spec-uri single-source suprapuse, nu din
	# `species` (edge nu stie de ponderi). Aceleasi trei lanuri si aceleasi
	# goluri ca pajistea (#209): tivul tace si el pe pod si pe creasta.
	# `min_ground` 1.6 = regula plajei de la pajiste (sub BEACH_SAND_TOP nu
	# creste iarba grasa).
	var verge_lanuri: Array[Vector2] = [Vector2(0.03, 0.27),
		Vector2(0.315, 0.60), Vector2(0.655, 0.93)]
	for lan: Vector2 in verge_lanuri:
		for latura: float in [1.0, -1.0]:
			specs.append_array([
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.0, "spacing": 3.2,
					"jitter": 0.3, "min_ground": 1.6,
					"path": M + "plants/megakit_plants.glb",
					"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
					"scale": [0.7, 1.1], "face": "random", "sink": 0.1},
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.2, "spacing": 4.2,
					"jitter": 0.4, "min_ground": 1.6,
					"path": M + "rocks/island_scatter.glb",
					"picks": ["Beach_Grass"],
					"scale": [0.8, 1.3], "face": "random", "sink": 0.08},
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.3, "spacing": 18.0,
					"jitter": 0.4, "min_ground": 1.6,
					"path": M + "flowers/flowers_orange.glb",
					"scale": [0.8, 1.1], "face": "random", "sink": 0.06},
				# veg_set2: tufa lata e silueta de gard viu a tivului —
				# rara, dar ea face "peretele"; coralul e accentul pal
				# dintre portocaliuri. Pasii mari nu sunt zgarcenie: linia
				# tivului are ~2.6 km pe ambele laturi, si la 750-800 tri
				# bucata fiecare metru de pas taiat costa zeci de mii.
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.4, "spacing": 40.0,
					"jitter": 0.5, "min_ground": 1.6,
					"path": M + "plants/broadleaf_shrub.glb",
					"scale": [0.8, 1.15], "face": "random", "sink": 0.1},
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.3, "spacing": 55.0,
					"jitter": 0.5, "min_ground": 1.6,
					"path": M + "flowers/flowers_coral.glb",
					"scale": [0.85, 1.15], "face": "random", "sink": 0.06},
			])
	return specs


## ############################################################################
## STRAMTOAREA KAIUN: canalul cu pod mobil de pe coasta de vest.
##
## Singura abatere a acestei piste de la Okinawa v2, si prima care schimba
## LUMEA, nu doar decorul asezat de mana. Traseul ramane neatins — nici un punct
## de control mutat, nici o cota schimbata — deci scenografia mostenita si toate
## fractiile ei raman valabile. Ce se schimba e insula: primeste o taietura.
##
## [b]De ce aici[/b]. Cerinta a fost „pe partea opusa fata de unde avem apa
## acum", iar apa de acum e digul de start: fractiile 0.93..0.05, la SUD, cu
## soseaua la 1.6 m peste valuri. Sonda de tarm (probe_shore --track=8) spune
## unde se poate raspunde la asta:
##   - nordul geografic e creasta, la +27 m — acolo un canal ar fi o prapastie
##     cu apa pe fund, nu o stramtoare;
##   - coasta de vest, 0.28..0.34, e punctul cel mai DEPARTE de apa din tot
##     turul (86-90 m pana la larg, 103-116 m pana la laguna), e dreapta pe
##     100 m si sta la ~7 m, adica 8.5 m peste nivelul marii.
## Deci: locul in care insula nu are apa deloc, si in care soseaua sta exact
## cu „putin mai multa elevatie" decat pe dig. Apa nu se cauta, se sapa — un
## senal taie istmul de la larg pana in laguna, si drumul il sare pe pod.
##
## [b]De ce nu e scurtatura, ci soseaua principala[/b]. Insula e un INEL, deci
## convexa aproape peste tot: orice coarda intre doua fractii trece pe uscat,
## prin interior, iar cele care chiar trec peste apa taie 300+ m dintr-un tur de
## 1800 (masurat in track07.gd, la asezarea pragului de corali). Adica nu exista
## loc pentru o a doua sosea peste apa care sa fie si atractiva, si cinstita. Si
## e mai bine asa: cerinta spunea „trebuie sa intrerupem track-ul", iar un pod
## pe care il ia toata lumea, in fiecare tur, chiar il intrerupe.
##
## Cifrele: gol de 12 m intre buze, rampe de 1.6 m pe 5 m (17.7°), deci pragul
## de trecere iese pe la 24 m/s — 71% din viteza de varf de baza. Cine merge
## tare nici nu simte podul; cine a ridicat piciorul sau a fost imbrancit
## inainte de el inoata. Verificate in motor cu tools/probe_bridge.gd, nu
## calculate pe hartie: acolo se citeste golul OBTINUT (capetele lui cad pe
## puncte coapte, deci nu poate fi exact 12) si degajarea reala sub travee.
func _channel_specs() -> Array[Dictionary]:
	return [{
		"frac": 0.310,
		"label": "Stramtoarea Kaiun",
		"gap": 12.0,
		# 52 m de apa: sub ~40 m nu mai citeste a senal navigabil, ci a sant, iar
		# corabia de 15 m ar parea prinsa intre maluri.
		"water_half": 26.0,
		"bank": 20.0,
		# Fundul la 13 m sub sosea, adica ~4.5 m de apa peste el. Peste pragul de
		# plutire al corabiei si mult sub Track.SEA_REEF_DEPTH, deci senalul iese
		# turcoaz ca laguna, nu bleumarin ca largul.
		"depth": 13.0,
		# Pana la larg sunt 90 m si pana la laguna 116: cu 200 m in fiecare parte
		# taietura ajunge in amandoua si stramtoarea chiar leaga doua ape.
		"reach": 200.0,
		"fade": 55.0,
	}]


## ############################################################################
## SCENOGRAFIA INSULEI: referinta, sector cu sector.
##
## Baza mostenita de la fosta pista "Okinawa v2", pastrata ca metoda separata:
## `_scenography()` o cheama intai si adauga peste ea decorul propriu al acestei
## piste (pajistea, paturile de flori, pietrele de margine si piesele promovate
## din decorul manual). Separarea nu e cosmetica — tine cele doua straturi
## lizibile unul fata de altul, exact cum le tinea mostenirea inainte de
## contopire.
##
## Sursa e `assets/okinawa_v2/okinawa_v2.png` — acelasi poster din care au iesit
## traseul, cotele si laguna. Ce se putea MASURA din el s-a masurat (pozitiile
## caselor de sat vin din masca de acoperisuri portocalii a hartii de tur,
## trecuta prin transformarea harta->lume, 2.83 m/px); ce tine de densitate si
## de specie s-a citit din randarea izometrica, unde se vede piesa cu piesa.
##
## Distantele fata de sosea NU sunt cele din desen, si asta e important: terenul
## din motor are propria linie a apei (laguna sapata, rapa digului, banda de
## tarm). Toate cifrele de mai jos sunt verificate cu `tools/probe_shore.gd`,
## care tipareste unde e malul la fiecare fractie. Doua exemple din prima
## rulare: pe dig apa vine pana la 14 m de axa in AMBELE parti (deci tetrapozii
## chiar stau langa asfalt, ca in poza), iar pe creasta interiorul buclei cade la
## 19 m — platoul cu cetatea e pe latura dinspre larg, nu invers cum arata
## unghiul izometric al posterului.
##
## Ce NU e aici, desi e in poza: podul cu arcade de sub creasta (n-avem asset de
## viaduct) si templul cu streasina intoarsa (casa de sat scalata ar fi fost o
## minciuna, nu un stand-in). Se adauga cand apar modelele.
func _scenography_island() -> Array[Dictionary]:
	const M := "res://assets/models/"
	return [
		# --- 1. DIGUL DE START -------------------------------------------
		#
		# Imaginea care defineste pista: un sir dublu de tetrapozi pe toata
		# dreapta de start, spalati de valuri. Nu sunt presarati — e o lucrare
		# de aparare, deci merg cap la cap, cu randul doi in golurile primului.
		# `max_shore` opreste sirul acolo unde tarmul se desprinde de sosea:
		# dincolo de capetele digului, coasta primeste pietre, nu beton.
		{"kind": "revetment", "label": "Dig_tetrapozi", "side": -1.0,
			"from": 0.926, "to": 0.052, "rows": 2, "spacing": 4.5,
			"row_gap": 4.2, "first_row": -1.0, "jitter": 0.9,
			"max_shore": 26.0, "path": M + "structures/tetrapod.glb",
			"picks": ["Tetrapod_01", "Tetrapod_04", "Tetrapod_04",
				"Tetrapod_01", "Tetrapod_Stack_01", "Tetrapod_04"],
			"scale": [0.7, 1.0], "face": "random", "tilt": 0.13,
			"sink": 0.35},
		# Parapetul dinspre laguna: pe partea protejata a digului marea nu bate,
		# deci acolo referinta are un zid jos cu stalpi, nu tetrapozi.
		{"kind": "edge", "label": "Dig_parapet", "side": 1.0,
			"from": 0.930, "to": 0.048, "off": 3.6, "spacing": 3.7,
			"jitter": 0.0, "min_ground": -0.4,
			"path": M + "structures/sea_wall_segment.glb",
			"picks": ["Sea_Wall_A", "Sea_Wall_B", "Sea_Wall_C"],
			"scale": [1.0, 1.0], "face": "along", "sink": 0.1},
		# Bolovanii din spuma, pe ambele laturi. In referinta digul nu iese din
		# apa curata: intre tetrapozi si sub parapet sunt stanci negre.
		{"kind": "revetment", "label": "Dig_stanci", "side": -1.0,
			"from": 0.920, "to": 0.060, "rows": 2, "spacing": 9.0,
			"row_gap": 5.0, "first_row": 2.5, "jitter": 2.2,
			"max_shore": 30.0, "path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_03", "Coral_Rock_04", "Coral_Rock_05",
				"Coral_Rock_06"],
			"scale": [0.8, 1.5], "face": "random", "sink": 0.5},
		{"kind": "revetment", "label": "Dig_stanci", "side": 1.0,
			"from": 0.930, "to": 0.050, "rows": 1, "spacing": 11.0,
			"first_row": 3.0, "jitter": 2.5, "max_shore": 30.0,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_02", "Coral_Rock_03", "Coral_Rock_04"],
			"scale": [0.7, 1.3], "face": "random", "sink": 0.45},

		# --- 2. PORTUL DE PESCARI ----------------------------------------
		#
		# Cheiul se aseaza pe LINIA APEI, nu la o distanta fixa: laguna intra
		# pana la ~45 m de axa in golful asta si la 62 m imediat dupa.
		{"kind": "edge", "label": "Port_chei", "side": 1.0,
			"from": 0.060, "to": 0.106, "off": 36.0, "spacing": 6.9,
			"jitter": 0.0, "min_ground": -1.0,
			"path": M + "structures/gusuku_wall.glb",
			"picks": ["Gusuku_Wall_A", "Gusuku_Wall_B"],
			"scale": [0.85, 0.85], "face": "along", "sink": 0.6},
		# Barcile sabani, acostate paralel cu cheiul. `on_water` le pune la
		# nivelul marii, nu pe fundul lagunei.
		{"kind": "spot", "label": "Port_barci", "frac": 0.070, "side": 1.0,
			"off": 44.0, "on_water": true, "path": M + "vehicles/sabani_boat.glb",
			"face": "along", "yaw": 8.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.078, "side": 1.0,
			"off": 47.0, "on_water": true, "path": M + "vehicles/sabani_boat.glb",
			"face": "along", "yaw": -6.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.084, "side": 1.0,
			"off": 43.0, "on_water": true, "path": M + "vehicles/sabani_boat.glb",
			"face": "along", "yaw": 14.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.092, "side": 1.0,
			"off": 48.0, "on_water": true, "path": M + "vehicles/sabani_boat.glb",
			"face": "along", "yaw": -11.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.099, "side": 1.0,
			"off": 45.0, "on_water": true, "path": M + "vehicles/sabani_boat.glb",
			"face": "along", "yaw": 5.0, "sink": 0.15},
		# Viata de pe chei: lazi, plute, oale de awamori.
		{"kind": "grove", "label": "Port_marfa", "side": 1.0,
			"from": 0.064, "to": 0.104, "spacing": 7.0, "off": [26.0, 36.0],
			"species": [
				{"path": M + "scatter/beach_clutter.glb", "weight": 1.0,
					"picks": ["Fishing_Crate", "Net_Floats", "Awamori_Pot",
						"Bamboo_Rack"], "scale": [1.0, 1.6],
					"face": "random"},
			]},

		# Coasta dinspre larg, in dreptul portului si al satului. Fara ea,
		# jumatatea din stanga a cadrului e nisip gol pe 60 m: tarmul e departe
		# acolo (masurat 65-76 m), deci nici digul, nici benzile statistice
		# (care se opresc la 26 m) nu ajung pana la el.
		{"kind": "grove", "label": "Coasta_vest", "side": -1.0, "from": 0.030,
			"to": 0.150, "spacing": 10.0, "off": [16.0, 46.0], "species": [
				{"path": M + "trees/beach_palm_bent.glb", "weight": 0.34,
					"scale": [0.9, 1.25], "face": "random"},
				{"path": M + "rocks/coral_rock.glb", "weight": 0.30,
					"picks": ["Coral_Rock_04", "Coral_Rock_05",
						"Coral_Rock_06"],
					"scale": [0.8, 1.4], "face": "random"},
				{"path": M + "trees/pandanus.glb", "weight": 0.22,
					"scale": [0.9, 1.3], "face": "random"},
				{"path": M + "scatter/island_scatter.glb", "weight": 0.14,
					"picks": ["Beach_Grass", "Driftwood"], "scale": [1.4, 2.4],
					"face": "random"},
			]},

		# --- 3. SATUL ----------------------------------------------------
		#
		# Randul din spate: cele trei curti masurate in harta de tur. Fiecare
		# pata de acoperis portocaliu are 500-750 m2, adica un grup de case, nu
		# una — de aia sunt cate doua pe pozitie, decalate pe directia drumului.
		# Coordonatele raman cele MASURATE; daca pica in laguna (conturul ei e
		# simplificat la 16 laturi), casa se trage singura pe uscat.
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-103, 95),
			"path": M + "buildings/village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-115, 85),
			"path": M + "buildings/village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-149, 70),
			"path": M + "buildings/village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-165, 66),
			"path": M + "buildings/village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-199, 60),
			"path": M + "buildings/village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-215, 58),
			"path": M + "buildings/village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		# Randul de la drum, intercalat cu cele trei landmark-uri de mai sus
		# (0.115 / 0.145 / 0.175), ca soseaua sa treaca PRINTRE case.
		{"kind": "spot", "label": "Sat_case", "frac": 0.105, "side": 1.0,
			"off": 11.0, "path": M + "buildings/village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.128, "side": -1.0,
			"off": 12.0, "path": M + "buildings/village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.158, "side": 1.0,
			"off": 11.0, "path": M + "buildings/village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.166, "side": -1.0,
			"off": 13.0, "path": M + "buildings/village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.190, "side": 1.0,
			"off": 12.0, "path": M + "buildings/village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		# Zidurile de curte: doua bucati scurte de gusuku, la scara de gard.
		# Nu pe tot satul — un panou de zid costa 2 300 de triunghiuri, deci se
		# pun acolo unde chiar marginesc o curte, nu ca sa umple metri.
		{"kind": "edge", "label": "Sat_ziduri", "side": 1.0, "from": 0.100,
			"to": 0.114, "off": 7.0, "spacing": 4.8,
			"path": M + "structures/gusuku_wall.glb", "picks": ["Gusuku_Wall_A"],
			"scale": [0.60, 0.60], "face": "along", "sink": 0.15,
			"min_ground": 0.5},
		{"kind": "edge", "label": "Sat_ziduri", "side": -1.0, "from": 0.162,
			"to": 0.176, "off": 7.0, "spacing": 4.8,
			"path": M + "structures/gusuku_wall.glb", "picks": ["Gusuku_Wall_A"],
			"scale": [0.60, 0.60], "face": "along", "sink": 0.15,
			"min_ground": 0.5},
		# Gradinile: hibiscus si palmieri mici intre case, ca in poza.
		{"kind": "grove", "label": "Sat_gradini", "side": 1.0, "both_sides":
			true, "from": 0.100, "to": 0.200, "spacing": 9.0,
			"off": [9.0, 26.0], "species": [
				{"path": M + "plants/hibiscus_bush.glb", "weight": 0.40,
					"scale": [1.0, 1.8], "face": "random"},
				{"path": M + "trees/coconut_palm.glb", "weight": 0.34,
					"scale": [0.8, 1.05], "face": "random", "collide": 0.45},
				{"path": M + "trees/banyan.glb", "weight": 0.16,
					"scale": [0.8, 1.0], "face": "random", "collide": 1.1},
				{"path": M + "scatter/island_scatter.glb", "weight": 0.10,
					"picks": ["Beach_Grass", "Hibiscus"], "scale": [1.2, 2.0],
					"face": "random"},
			]},

		# --- 4. CAPUL DE VEST ---------------------------------------------
		#
		# Panoul "HAIRPIN" din referinta: palmieri pe exteriorul virajului,
		# stanca joasa pe interior, nimic inalt in apex (style_bible §7).
		{"kind": "grove", "label": "Cap_vest", "side": -1.0, "from": 0.205,
			"to": 0.268, "spacing": 8.0, "off": [10.0, 30.0], "species": [
				{"path": M + "trees/coconut_palm.glb", "weight": 0.46,
					"scale": [0.9, 1.2], "face": "random", "collide": 0.45},
				{"path": M + "trees/beach_palm_bent.glb", "weight": 0.28,
					"scale": [0.9, 1.25], "face": "random", "collide": 0.4},
				{"path": M + "trees/pandanus.glb", "weight": 0.26,
					"scale": [0.9, 1.3], "face": "random"},
			]},
		{"kind": "grove", "label": "Cap_vest_roci", "side": 1.0, "from": 0.212,
			"to": 0.262, "spacing": 11.0, "off": [9.0, 20.0], "species": [
				{"path": M + "rocks/rock_cluster.glb", "weight": 0.6,
					"picks": ["Cluster_M1", "Cluster_M2", "Cluster_S1"],
					"scale": [0.9, 1.4], "face": "random"},
				{"path": M + "rocks/coral_rock.glb", "weight": 0.4,
					"picks": ["Coral_Rock_04", "Coral_Rock_05"],
					"scale": [0.8, 1.2], "face": "random"},
			]},

		# --- 6. URCAREA DE COASTA: terasele de gusuku ---------------------
		#
		# Zidul de cetate incepe pe urcare, pe latura dinspre uscat (-1), si
		# insoteste drumul pana sub creasta. In referinta e piesa care da scara
		# intregului sector: 6 m de piatra langa un drum de 14.
		{"kind": "edge", "label": "Cetate_terase", "side": -1.0, "from": 0.452,
			"to": 0.498, "off": 6.0, "spacing": 7.9,
			"path": M + "structures/gusuku_wall.glb",
			"picks": ["Gusuku_Wall_B", "Gusuku_Wall_C"],
			"scale": [1.0, 1.0], "face": "along", "sink": 0.3,
			"min_ground": 1.0},
		{"kind": "grove", "label": "Urcare_vegetatie", "side": 1.0,
			"both_sides": true, "from": 0.400, "to": 0.500, "spacing": 12.0,
			"off": [9.0, 24.0], "species": [
				{"path": M + "trees/pandanus.glb", "weight": 0.40,
					"scale": [0.9, 1.3], "face": "random"},
				{"path": M + "trees/coconut_palm.glb", "weight": 0.36,
					"scale": [0.9, 1.15], "face": "random", "collide": 0.45},
				{"path": M + "plants/hibiscus_bush.glb", "weight": 0.24,
					"scale": [1.2, 2.0], "face": "random"},
			]},

		# --- 7. CREASTA: cetatea ------------------------------------------
		#
		# Platoul e pe latura dinspre larg (masurat, vezi antetul). Zidul merge
		# cap la cap pe buza lui, iar farul (landmark id 7) sta in spatele lui.
		{"kind": "edge", "label": "Cetate_creasta", "side": -1.0, "from": 0.588,
			"to": 0.652, "off": 7.0, "spacing": 9.5,
			"path": M + "structures/gusuku_wall.glb",
			"picks": ["Gusuku_Wall_C", "Gusuku_Wall_B", "Gusuku_Wall_C"],
			"scale": [1.2, 1.2], "face": "along", "sink": 0.3,
			"min_ground": 1.0},
		{"kind": "grove", "label": "Creasta_palmieri", "side": -1.0,
			"from": 0.585, "to": 0.660, "spacing": 13.0, "off": [22.0, 40.0],
			"species": [
				{"path": M + "trees/coconut_palm.glb", "weight": 0.55,
					"scale": [0.95, 1.2], "face": "random"},
				{"path": M + "trees/banyan.glb", "weight": 0.25,
					"scale": [0.9, 1.15], "face": "random"},
				{"path": M + "trees/pandanus.glb", "weight": 0.20,
					"scale": [0.9, 1.2], "face": "random"},
			]},
		# Stalpii de pe pragul de corali (panoul "TIDAL SANDBAR SHORTCUT"):
		# doua siruri care marcheaza banda uda peste laguna. Pozitiile sunt
		# calculate pe polilinia scurtaturii din `_branch_specs`, la 6.5 m de
		# axa ei — adica exact pe margine, unde se vad din masina.
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(164, -247),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(177, -248),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(167, -217),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(180, -218),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(170, -187),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(183, -188),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(174, -156),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(187, -160),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(179, -142),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(192, -146),
			"path": M + "signs/marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},

		# --- 8. COBORAREA DE EST: lanul si palmierii ----------------------
		#
		# In referinta interiorul sweeper-ului e un lan de trestie, marginit de
		# cocotieri, cu stanci mari pe malul dinspre laguna. Benzile statistice
		# pun deja trestie pe 0.68-0.88 (TrackDecor.CANE_FRAC_MIN); aici se
		# adauga PATA densa din poza, nu inca un strat pe tot sectorul.
		{"kind": "grove", "label": "Lan_trestie", "side": 1.0, "from": 0.690,
			"to": 0.766, "spacing": 3.6, "off": [4.0, 17.0], "species": [
				{"path": M + "plants/sugar_cane_clump.glb", "weight": 1.0,
					"picks": ["Cane_Clump_A", "Cane_Clump_B", "Cane_Clump_C"],
					"scale": [0.9, 1.25], "face": "random", "sink": 0.2},
			]},
		{"kind": "grove", "label": "Est_palmieri", "side": 1.0,
			"both_sides": true, "from": 0.672, "to": 0.800, "spacing": 8.0,
			"off": [9.0, 28.0], "species": [
				{"path": M + "trees/coconut_palm.glb", "weight": 0.50,
					"scale": [0.9, 1.25], "face": "random", "collide": 0.45},
				{"path": M + "trees/beach_palm_bent.glb", "weight": 0.22,
					"scale": [0.9, 1.2], "face": "random", "collide": 0.4},
				{"path": M + "trees/pandanus.glb", "weight": 0.18,
					"scale": [0.9, 1.3], "face": "random"},
				{"path": M + "trees/banyan.glb", "weight": 0.10,
					"scale": [0.9, 1.2], "face": "random", "collide": 1.1},
			]},
		# Malul lagunei, acolo unde apa vine la 18-27 m de sosea (0.79-0.83):
		# bolovani mari in apa, ca in coltul din dreapta jos al posterului.
		{"kind": "revetment", "label": "Est_bolovani", "side": 1.0,
			"from": 0.782, "to": 0.840, "rows": 2, "spacing": 8.0,
			"row_gap": 5.5, "first_row": 1.0, "jitter": 2.0,
			"max_shore": 34.0, "path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_05", "Coral_Rock_06", "Coral_Rock_07",
				"Coral_Rock_08"],
			"scale": [0.9, 1.5], "face": "random", "sink": 0.4},

		# Perdeaua de la marginea drumului. In referinta palmierii nu incep la
		# 16 m, cresc pana in bordura — asta e ce face sectorul de est sa citeasca
		# a jungla si nu a camp cu copaci. FARA coliziune, ca banda "hug" din
		# TrackDecor: la 3-6 m de asfalt un colizor nu e decor, e pedeapsa.
		{"kind": "grove", "label": "Perdea_est", "side": 1.0,
			"both_sides": true, "from": 0.676, "to": 0.800, "spacing": 13.0,
			"off": [2.5, 6.5], "clear": 2.0, "species": [
				{"path": M + "trees/coconut_palm.glb", "weight": 0.44,
					"scale": [0.85, 1.1], "face": "random"},
				{"path": M + "trees/pandanus.glb", "weight": 0.34,
					"scale": [0.9, 1.25], "face": "random"},
				{"path": M + "plants/hibiscus_bush.glb", "weight": 0.22,
					"scale": [1.3, 2.0], "face": "random"},
			]},
		{"kind": "grove", "label": "Perdea_cap_vest", "side": -1.0,
			"from": 0.206, "to": 0.266, "spacing": 12.0, "off": [2.5, 6.5],
			"clear": 2.0, "species": [
				{"path": M + "trees/beach_palm_bent.glb", "weight": 0.46,
					"scale": [0.85, 1.15], "face": "random"},
				{"path": M + "trees/pandanus.glb", "weight": 0.34,
					"scale": [0.9, 1.25], "face": "random"},
				{"path": M + "plants/hibiscus_bush.glb", "weight": 0.20,
					"scale": [1.3, 2.0], "face": "random"},
			]},

		# --- 9. RETURUL DE SUD-EST ----------------------------------------
		#
		# Plaja dinaintea digului: palmieri aplecati spre apa, lemn adus de
		# valuri, pietre marunte. E ultima respiratie inainte de dreapta de
		# start, deci ramane rara — nimic care sa ascunda linia de cursa.
		{"kind": "grove", "label": "Plaja_sud", "side": 1.0, "both_sides": true,
			"from": 0.845, "to": 0.925, "spacing": 12.0, "off": [10.0, 30.0],
			"species": [
				{"path": M + "trees/beach_palm_bent.glb", "weight": 0.44,
					"scale": [0.9, 1.25], "face": "random", "collide": 0.4},
				{"path": M + "trees/coconut_palm.glb", "weight": 0.30,
					"scale": [0.9, 1.15], "face": "random", "collide": 0.45},
				{"path": M + "scatter/island_scatter.glb", "weight": 0.26,
					"picks": ["Driftwood", "Beach_Grass", "Coral_Pebbles"],
					"scale": [1.3, 2.2], "face": "random"},
			]},
	]
