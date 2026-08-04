@tool
extends Track
## Pista 7 — "Okinawa v2": insula INELARA, cu laguna in mijlocul circuitului.
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
## Fata de Okinawa (pista 5), care e tot o insula: acolo interiorul buclei e
## ferm uscat si apa e doar pe exterior. Aici e exact invers, si de aia a fost
## nevoie de `_lagoon_points` in Track — regula "interiorul buclei ramane uscat"
## din TrackSideSampler exista tocmai ca sa nu apara atoli din greseala, deci
## unul FACUT ANUME trebuie cerut explicit.

func _init() -> void:
	track_name = "Okinawa v2"
	half_width = 7.0
	# Media cotelor soselei e +9.4 m (profilul urca la 30 si coboara la 0), deci
	# marea sta la -1.6. Adica 1.6 m sub dreapta de start — exact freeboard-ul
	# unui dig cu tetrapozi, si motivul pentru care cifra nu poate fi cea de pe
	# pista 5: acolo media e +7.6, aici +9.4, si aceeasi -7 ar fi lasat digul
	# sub apa.
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
	apply_theme("island")


## Traseul, sector cu sector. 1806 m, anvelopa 562 x 502 m.
##
## Masurat in motor (tools/probe_layout.gd): raza minima 14.6 m la frac 0.21,
## panta maxima 14.8% la 0.65, apropiere de sine 51.4 m. Toate cu marja fata de
## praguri (raza > 7, panta < 22%, separare > 14).
##
## Cotele sunt profilul din referinta, nu inventate: fiecare punct isi ia y-ul
## de la fractia lui de tur. Daca se muta un punct pe orizontala, cota lui NU
## mai corespunde profilului — se reciteste, nu se ajusteaza din ochi.
func _points() -> Array[Vector3]:
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
## castig (18% din portiunea ocolita, ~1.3 s). Mai putin decat crapatura din
## Stramtoarea (74 m), si asta e potrivit: acolo contragreutatea e latimea,
## aici e ca intri pe ea IMEDIAT dupa varf, cu 16 m de coborare in fata si
## banda uda sub roti.
##
## `wet` e contragreutatea, ca la bancul de nisip din Okinawa: pragul e spalat
## de valuri, deci grip lateral taiat exact pe portiunea in care cobori cel mai
## repede. Echilibrul dintre castig si cost se gaseste la playtest — aici se
## fixeaza doar geometria.
func _branch_specs() -> Array[Dictionary]:
	return [{
		"entry": 0.615,   # varful crestei
		"exit": 0.735,    # coborarea de est, la +11 m
		"half_width": 5.5,
		"wet": true,
		"label": "pragul de corali",
		"points": [
			Vector3(175, 23.6, -207),
			Vector3(179, 19.2, -163),
			Vector3(193, 14.8, -121),
		],
	}]


## Creasta de fly-off, pe coborarea de est.
##
## A stat intai pe urcarea catre varf (0.545), unde o pun si referinta si bunul
## simt — si acolo NU merge, din motive masurate: aterizezi tot pe urcare, deci
## nasul intra in panta, iar sonda de cursa gasea la fiecare tur cate un AI
## oprit pe la 0.59, la mijlocul drumului. Creasta cere o COBORARE dupa ea, ca
## pe Stramtoarea.
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


## Valul care spala digul, chiar inainte de linia de start: ultima portiune a
## turului e cea in care nu poti sa nu fii atent. Refoloseste furtunul, ca pe
## causeway-ul din Okinawa.
func _hose_fracs() -> Array[float]:
	return [0.975]


## Rampa pe iesirea din coasta de vest — a doua cea mai dreapta bucata a
## turului (raza minima 1900 m pe 40 m), pe teren aproape orizontal.
##
## Prima incercare a fost 0.265, in bucla de dupa capul de vest: raza 350 m
## parea destul, dar nu e — o rampa ocupa jumatate din latimea drumului, deci
## intr-un viraj masina care o ia pe partea gresita cade de pe muchia din spate
## si ramane acolo. Sonda gasea doi AI blocati la 0.258 in fiecare rulare.
func _ramp_fracs() -> Array[float]:
	return [0.383]


## Bariera mobila pe coasta de vest, inainte de rampa.
##
## A stat intai la 0.340 (bucla de dupa capul de vest) si apoi la 0.310, si de
## fiecare data sonda gasea acelasi AI intepenit intre bariera si perete, la
## mijlocul drumului. O bariera care mica pe un drum unde n-ai pe unde s-o
## ocolesti nu e obstacol, e usa. La 0.256 drumul e drept si larg.
func _hazard_fracs() -> Array[float]:
	return [0.256]


## Satul din port (id 6 = village_house, texturi de clasa: olane, tencuiala,
## piatra). Pozitiile vin din referinta: casele cu acoperis portocaliu stau pe
## malul de nord al soselei, intre dig si capul de vest. Alternate pe laturi, ca
## drumul sa treaca PRINTRE ele.
func _landmark_spots() -> Array[Vector3]:
	return [
		Vector3(0.115, 1.0, 6),
		Vector3(0.145, -1.0, 6),
		Vector3(0.175, 1.0, 6),
	]
