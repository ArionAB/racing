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
## SCENOGRAFIA: referinta, sector cu sector.
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
func _scenography() -> Array[Dictionary]:
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
			"max_shore": 26.0, "path": M + "tetrapod.glb",
			"picks": ["Tetrapod_01", "Tetrapod_04", "Tetrapod_04",
				"Tetrapod_01", "Tetrapod_Stack_01", "Tetrapod_04"],
			"scale": [0.7, 1.0], "face": "random", "tilt": 0.13,
			"sink": 0.35},
		# Parapetul dinspre laguna: pe partea protejata a digului marea nu bate,
		# deci acolo referinta are un zid jos cu stalpi, nu tetrapozi.
		{"kind": "edge", "label": "Dig_parapet", "side": 1.0,
			"from": 0.930, "to": 0.048, "off": 3.6, "spacing": 3.7,
			"jitter": 0.0, "min_ground": -0.4,
			"path": M + "sea_wall_segment.glb",
			"picks": ["Sea_Wall_A", "Sea_Wall_B", "Sea_Wall_C"],
			"scale": [1.0, 1.0], "face": "along", "sink": 0.1},
		# Bolovanii din spuma, pe ambele laturi. In referinta digul nu iese din
		# apa curata: intre tetrapozi si sub parapet sunt stanci negre.
		{"kind": "revetment", "label": "Dig_stanci", "side": -1.0,
			"from": 0.920, "to": 0.060, "rows": 2, "spacing": 9.0,
			"row_gap": 5.0, "first_row": 2.5, "jitter": 2.2,
			"max_shore": 30.0, "path": M + "coral_rock.glb",
			"picks": ["Coral_Rock_03", "Coral_Rock_04", "Coral_Rock_05",
				"Coral_Rock_06"],
			"scale": [0.8, 1.5], "face": "random", "sink": 0.5},
		{"kind": "revetment", "label": "Dig_stanci", "side": 1.0,
			"from": 0.930, "to": 0.050, "rows": 1, "spacing": 11.0,
			"first_row": 3.0, "jitter": 2.5, "max_shore": 30.0,
			"path": M + "coral_rock.glb",
			"picks": ["Coral_Rock_02", "Coral_Rock_03", "Coral_Rock_04"],
			"scale": [0.7, 1.3], "face": "random", "sink": 0.45},

		# --- 2. PORTUL DE PESCARI ----------------------------------------
		#
		# Cheiul se aseaza pe LINIA APEI, nu la o distanta fixa: laguna intra
		# pana la ~45 m de axa in golful asta si la 62 m imediat dupa.
		{"kind": "edge", "label": "Port_chei", "side": 1.0,
			"from": 0.060, "to": 0.106, "off": 36.0, "spacing": 6.9,
			"jitter": 0.0, "min_ground": -1.0,
			"path": M + "gusuku_wall.glb",
			"picks": ["Gusuku_Wall_A", "Gusuku_Wall_B"],
			"scale": [0.85, 0.85], "face": "along", "sink": 0.6},
		# Barcile sabani, acostate paralel cu cheiul. `on_water` le pune la
		# nivelul marii, nu pe fundul lagunei.
		{"kind": "spot", "label": "Port_barci", "frac": 0.070, "side": 1.0,
			"off": 44.0, "on_water": true, "path": M + "sabani_boat.glb",
			"face": "along", "yaw": 8.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.078, "side": 1.0,
			"off": 47.0, "on_water": true, "path": M + "sabani_boat.glb",
			"face": "along", "yaw": -6.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.084, "side": 1.0,
			"off": 43.0, "on_water": true, "path": M + "sabani_boat.glb",
			"face": "along", "yaw": 14.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.092, "side": 1.0,
			"off": 48.0, "on_water": true, "path": M + "sabani_boat.glb",
			"face": "along", "yaw": -11.0, "sink": 0.15},
		{"kind": "spot", "label": "Port_barci", "frac": 0.099, "side": 1.0,
			"off": 45.0, "on_water": true, "path": M + "sabani_boat.glb",
			"face": "along", "yaw": 5.0, "sink": 0.15},
		# Viata de pe chei: lazi, plute, oale de awamori.
		{"kind": "grove", "label": "Port_marfa", "side": 1.0,
			"from": 0.064, "to": 0.104, "spacing": 7.0, "off": [26.0, 36.0],
			"species": [
				{"path": M + "beach_clutter.glb", "weight": 1.0,
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
				{"path": M + "beach_palm_bent.glb", "weight": 0.34,
					"scale": [0.9, 1.25], "face": "random"},
				{"path": M + "coral_rock.glb", "weight": 0.30,
					"picks": ["Coral_Rock_04", "Coral_Rock_05",
						"Coral_Rock_06"],
					"scale": [0.8, 1.4], "face": "random"},
				{"path": M + "pandanus.glb", "weight": 0.22,
					"scale": [0.9, 1.3], "face": "random"},
				{"path": M + "island_scatter.glb", "weight": 0.14,
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
			"path": M + "village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-115, 85),
			"path": M + "village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-149, 70),
			"path": M + "village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-165, 66),
			"path": M + "village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-199, 60),
			"path": M + "village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		{"kind": "spot", "label": "Sat_curti", "world": Vector2(-215, 58),
			"path": M + "village_house.glb", "face": "road", "yaw_jitter": 12.0,
			"scale": [0.95, 1.1], "collide": 2.6},
		# Randul de la drum, intercalat cu cele trei landmark-uri de mai sus
		# (0.115 / 0.145 / 0.175), ca soseaua sa treaca PRINTRE case.
		{"kind": "spot", "label": "Sat_case", "frac": 0.105, "side": 1.0,
			"off": 11.0, "path": M + "village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.128, "side": -1.0,
			"off": 12.0, "path": M + "village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.158, "side": 1.0,
			"off": 11.0, "path": M + "village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.166, "side": -1.0,
			"off": 13.0, "path": M + "village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		{"kind": "spot", "label": "Sat_case", "frac": 0.190, "side": 1.0,
			"off": 12.0, "path": M + "village_house.glb", "face": "road",
			"scale": [0.95, 1.05], "collide": 2.6},
		# Zidurile de curte: doua bucati scurte de gusuku, la scara de gard.
		# Nu pe tot satul — un panou de zid costa 2 300 de triunghiuri, deci se
		# pun acolo unde chiar marginesc o curte, nu ca sa umple metri.
		{"kind": "edge", "label": "Sat_ziduri", "side": 1.0, "from": 0.100,
			"to": 0.114, "off": 7.0, "spacing": 4.8,
			"path": M + "gusuku_wall.glb", "picks": ["Gusuku_Wall_A"],
			"scale": [0.60, 0.60], "face": "along", "sink": 0.15,
			"min_ground": 0.5},
		{"kind": "edge", "label": "Sat_ziduri", "side": -1.0, "from": 0.162,
			"to": 0.176, "off": 7.0, "spacing": 4.8,
			"path": M + "gusuku_wall.glb", "picks": ["Gusuku_Wall_A"],
			"scale": [0.60, 0.60], "face": "along", "sink": 0.15,
			"min_ground": 0.5},
		# Gradinile: hibiscus si palmieri mici intre case, ca in poza.
		{"kind": "grove", "label": "Sat_gradini", "side": 1.0, "both_sides":
			true, "from": 0.100, "to": 0.200, "spacing": 9.0,
			"off": [9.0, 26.0], "species": [
				{"path": M + "hibiscus_bush.glb", "weight": 0.40,
					"scale": [1.0, 1.8], "face": "random"},
				{"path": M + "coconut_palm.glb", "weight": 0.34,
					"scale": [0.8, 1.05], "face": "random", "collide": 0.45},
				{"path": M + "banyan.glb", "weight": 0.16,
					"scale": [0.8, 1.0], "face": "random", "collide": 1.1},
				{"path": M + "island_scatter.glb", "weight": 0.10,
					"picks": ["Beach_Grass", "Hibiscus"], "scale": [1.2, 2.0],
					"face": "random"},
			]},

		# --- 4. CAPUL DE VEST ---------------------------------------------
		#
		# Panoul "HAIRPIN" din referinta: palmieri pe exteriorul virajului,
		# stanca joasa pe interior, nimic inalt in apex (style_bible §7).
		{"kind": "grove", "label": "Cap_vest", "side": -1.0, "from": 0.205,
			"to": 0.268, "spacing": 8.0, "off": [10.0, 30.0], "species": [
				{"path": M + "coconut_palm.glb", "weight": 0.46,
					"scale": [0.9, 1.2], "face": "random", "collide": 0.45},
				{"path": M + "beach_palm_bent.glb", "weight": 0.28,
					"scale": [0.9, 1.25], "face": "random", "collide": 0.4},
				{"path": M + "pandanus.glb", "weight": 0.26,
					"scale": [0.9, 1.3], "face": "random"},
			]},
		{"kind": "grove", "label": "Cap_vest_roci", "side": 1.0, "from": 0.212,
			"to": 0.262, "spacing": 11.0, "off": [9.0, 20.0], "species": [
				{"path": M + "rock_cluster.glb", "weight": 0.6,
					"picks": ["Cluster_M1", "Cluster_M2", "Cluster_S1"],
					"scale": [0.9, 1.4], "face": "random"},
				{"path": M + "coral_rock.glb", "weight": 0.4,
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
			"path": M + "gusuku_wall.glb",
			"picks": ["Gusuku_Wall_B", "Gusuku_Wall_C"],
			"scale": [1.0, 1.0], "face": "along", "sink": 0.3,
			"min_ground": 1.0},
		{"kind": "grove", "label": "Urcare_vegetatie", "side": 1.0,
			"both_sides": true, "from": 0.400, "to": 0.500, "spacing": 12.0,
			"off": [9.0, 24.0], "species": [
				{"path": M + "pandanus.glb", "weight": 0.40,
					"scale": [0.9, 1.3], "face": "random"},
				{"path": M + "coconut_palm.glb", "weight": 0.36,
					"scale": [0.9, 1.15], "face": "random", "collide": 0.45},
				{"path": M + "hibiscus_bush.glb", "weight": 0.24,
					"scale": [1.2, 2.0], "face": "random"},
			]},

		# --- 7. CREASTA: cetatea ------------------------------------------
		#
		# Platoul e pe latura dinspre larg (masurat, vezi antetul). Zidul merge
		# cap la cap pe buza lui, iar farul (landmark id 7) sta in spatele lui.
		{"kind": "edge", "label": "Cetate_creasta", "side": -1.0, "from": 0.588,
			"to": 0.652, "off": 7.0, "spacing": 9.5,
			"path": M + "gusuku_wall.glb",
			"picks": ["Gusuku_Wall_C", "Gusuku_Wall_B", "Gusuku_Wall_C"],
			"scale": [1.2, 1.2], "face": "along", "sink": 0.3,
			"min_ground": 1.0},
		{"kind": "grove", "label": "Creasta_palmieri", "side": -1.0,
			"from": 0.585, "to": 0.660, "spacing": 13.0, "off": [22.0, 40.0],
			"species": [
				{"path": M + "coconut_palm.glb", "weight": 0.55,
					"scale": [0.95, 1.2], "face": "random"},
				{"path": M + "banyan.glb", "weight": 0.25,
					"scale": [0.9, 1.15], "face": "random"},
				{"path": M + "pandanus.glb", "weight": 0.20,
					"scale": [0.9, 1.2], "face": "random"},
			]},
		# Stalpii de pe pragul de corali (panoul "TIDAL SANDBAR SHORTCUT"):
		# doua siruri care marcheaza banda uda peste laguna. Pozitiile sunt
		# calculate pe polilinia scurtaturii din `_branch_specs`, la 6.5 m de
		# axa ei — adica exact pe margine, unde se vad din masina.
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(164, -247),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(177, -248),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(167, -217),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(180, -218),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(170, -187),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(183, -188),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(174, -156),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(187, -160),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(179, -142),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},
		{"kind": "spot", "label": "Prag_stalpi", "world": Vector2(192, -146),
			"path": M + "marker_post.glb", "picks": ["Marker_A"],
			"face": "road", "scale": [1.4, 1.4]},

		# --- 8. COBORAREA DE EST: lanul si palmierii ----------------------
		#
		# In referinta interiorul sweeper-ului e un lan de trestie, marginit de
		# cocotieri, cu stanci mari pe malul dinspre laguna. Benzile statistice
		# pun deja trestie pe 0.68-0.88 (TrackDecor.CANE_FRAC_MIN); aici se
		# adauga PATA densa din poza, nu inca un strat pe tot sectorul.
		{"kind": "grove", "label": "Lan_trestie", "side": 1.0, "from": 0.690,
			"to": 0.766, "spacing": 3.6, "off": [4.0, 17.0], "species": [
				{"path": M + "sugar_cane_clump.glb", "weight": 1.0,
					"picks": ["Cane_Clump_A", "Cane_Clump_B", "Cane_Clump_C"],
					"scale": [0.9, 1.25], "face": "random", "sink": 0.2},
			]},
		{"kind": "grove", "label": "Est_palmieri", "side": 1.0,
			"both_sides": true, "from": 0.672, "to": 0.800, "spacing": 8.0,
			"off": [9.0, 28.0], "species": [
				{"path": M + "coconut_palm.glb", "weight": 0.50,
					"scale": [0.9, 1.25], "face": "random", "collide": 0.45},
				{"path": M + "beach_palm_bent.glb", "weight": 0.22,
					"scale": [0.9, 1.2], "face": "random", "collide": 0.4},
				{"path": M + "pandanus.glb", "weight": 0.18,
					"scale": [0.9, 1.3], "face": "random"},
				{"path": M + "banyan.glb", "weight": 0.10,
					"scale": [0.9, 1.2], "face": "random", "collide": 1.1},
			]},
		# Malul lagunei, acolo unde apa vine la 18-27 m de sosea (0.79-0.83):
		# bolovani mari in apa, ca in coltul din dreapta jos al posterului.
		{"kind": "revetment", "label": "Est_bolovani", "side": 1.0,
			"from": 0.782, "to": 0.840, "rows": 2, "spacing": 8.0,
			"row_gap": 5.5, "first_row": 1.0, "jitter": 2.0,
			"max_shore": 34.0, "path": M + "coral_rock.glb",
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
				{"path": M + "coconut_palm.glb", "weight": 0.44,
					"scale": [0.85, 1.1], "face": "random"},
				{"path": M + "pandanus.glb", "weight": 0.34,
					"scale": [0.9, 1.25], "face": "random"},
				{"path": M + "hibiscus_bush.glb", "weight": 0.22,
					"scale": [1.3, 2.0], "face": "random"},
			]},
		{"kind": "grove", "label": "Perdea_cap_vest", "side": -1.0,
			"from": 0.206, "to": 0.266, "spacing": 12.0, "off": [2.5, 6.5],
			"clear": 2.0, "species": [
				{"path": M + "beach_palm_bent.glb", "weight": 0.46,
					"scale": [0.85, 1.15], "face": "random"},
				{"path": M + "pandanus.glb", "weight": 0.34,
					"scale": [0.9, 1.25], "face": "random"},
				{"path": M + "hibiscus_bush.glb", "weight": 0.20,
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
				{"path": M + "beach_palm_bent.glb", "weight": 0.44,
					"scale": [0.9, 1.25], "face": "random", "collide": 0.4},
				{"path": M + "coconut_palm.glb", "weight": 0.30,
					"scale": [0.9, 1.15], "face": "random", "collide": 0.45},
				{"path": M + "island_scatter.glb", "weight": 0.26,
					"picks": ["Driftwood", "Beach_Grass", "Coral_Pebbles"],
					"scale": [1.3, 2.2], "face": "random"},
			]},
	]
