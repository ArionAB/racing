@tool
extends Track
## Pista 9 — "Alpii": satul, padurea, culmea, valea.
##
## Gimmick: ALTITUDINEA CA ARC NARATIV. Un tur = o zi de munte: pleci din sat,
## urci prin padure pe flancul de est, iei serpentinele pe umarul masivului
## central (+63 m, punctul cel mai inalt din joc), treci calea ferata de culme
## si cobori in valea pasunilor, unde te asteapta scurtatura prin iarba.
## Niciuna dintre celelalte piste nu URCA: Dunele si Stramtoarea sunt
## orizontale cu accidente, Okinawa sta la nivelul marii. Aici cifra care
## defineste pista e +63 m diferenta de nivel, si o simti in ambele sensuri —
## motorul o duce greu la deal, frana o duce greu la vale.
##
## Masivul central NU e decor pe orizont: bucla il inconjoara, iar sectorul de
## culme chiar urca pe umarul lui. Interiorul buclei e muntele — de aceea
## serpentinele sunt un LOB spre centru, nu o bucla exterioara.
##
## Fractiile de mai jos NU sunt desenate din ochi (lectia Stramtorii): au fost
## masurate cu tools/probe_track09_fracs.gd pe curba coapta, dupa ce traseul a
## trecut de tools/probe_layout.gd. Daca se muta un punct de control, se
## remasoara toate — nu se ajusteaza.
##
## Tema ramane "forest" pana la tema "alpine" dedicata (paleta de granit +
## zapada pe varf) — verde de pajiste + cer albastru e deja 80% din citirea
## alpina. Modelele de hazard (car cu fan, vaca, tractor) vin odata cu
## asset-urile; pana atunci SlidingHazard foloseste modelul temei.

func _init() -> void:
	track_name = "Alpii"
	half_width = 7.0
	apply_theme("forest")


## Bucla: 1786 m, anvelopa ~535 x 400 m, urcare totala 63 m.
## Masurat in motor (probe_layout): raza minima 11.5 m, panta maxima 15.6%,
## apropiere de sine 38.8 m. Toate cu marja fata de praguri (raza > 7,
## panta < 22%, separare > 14) — dar raza minima e SUB cei ~14 m de la care
## AI-ul incepe sa se opinteasca (lectia V-ului Stramtorii); cele doua viraje
## in cauza sunt exact intoarcerile serpentinei, care ORICUM se iau incet,
## iar probe_race pe pista asta ramane arbitrul: daca AI-ul se blocheaza
## acolo, se largeste lobul, nu se cosmetizeaza cifra.
##
## Sectoarele, ca intentie de ritm:
##   SATUL     ulita dreapta cu sicana — aici se depaseste si se arde turbo
##   PADUREA   urcare sustinuta pe est, viraje medii — se castiga bara din drift
##   CULMEA    lob spre centrul masivului: doua serpentine stranse + platou
##   COBORAREA vest, in panta — franare, nu acceleratie
##   VALEA     pasunea cu scurtatura, podul, retur in sat
##
## Reguli de geometrie respectate prin constructie (probe_layout le verifica):
## raza > half_width (7 m), ramuri paralele la >= 14 m, panta < 22%.
## Diagonalele serpentinei stau la ~34 m una de alta si la 8-10 m diferenta de
## cota — destul cat samplerul sa nu sara de pe una pe alta (GROUND_LOCK_LEN 15).
func _points() -> Array[Vector3]:
	return [
		# --- SATUL: ulita mare, aproape plata ---
		Vector3(0, 0, 0),        # START/FINISH, mers spre +X
		Vector3(75, 0, 6),
		Vector3(150, 1, -2),     # aici matura drumul carul cu fan
		Vector3(215, 2, -24),    # iesirea din sat, viraj spre sud
		# --- PADUREA: flancul de est, urcare constanta (~8%) ---
		Vector3(258, 5, -76),
		Vector3(272, 10, -140),
		Vector3(258, 16, -204),  # sania cu busteni traverseaza
		Vector3(270, 22, -268),
		Vector3(240, 28, -330),
		Vector3(185, 33, -368),  # coltul de sud-est
		Vector3(115, 38, -385),  # marginea de sud, spre vest
		# --- CULMEA: lobul care urca pe umarul masivului central ---
		#
		# Doua diagonale aproape paralele legate de o intoarcere in U, apoi
		# platoul. Intoarcerea e un SEMICERC ESANTIONAT: patru puncte de
		# control asezate chiar pe arcul dorit (raza ~22 m, centru ~(-20,
		# -308)), ca fiecare tangenta Catmull-Rom sa cada de-a lungul lui.
		# S-a incercat intai cu unul si apoi cu doua puncte in varf, masurat
		# de fiecare data cu probe_layout: cu unul, tangenta — (urmatorul -
		# precedentul) * 0.22 — iese scurta si curba se strange la 9.3 m; cu
		# doua, tot virajul de 180° cade intr-un singur segment ale carui
		# tangente merg de-a lungul CORZII, si iese 8.7 m. Regula ramasa: la
		# un viraj de peste ~90°, punctele de control se pun PE arc, nu la
		# colturile lui.
		Vector3(48, 44, -362),   # intrarea in lob
		Vector3(20, 47, -345),   # diagonala de jos
		Vector3(-2, 50, -332),   # diagonala de jos, capatul dinspre arc
		Vector3(-20, 52, -330),  # SERPENTINA — intrarea in arc
		Vector3(-38, 53, -320),  # arcul, coltul de SV
		Vector3(-38, 55, -296),  # arcul, coltul de NV
		Vector3(-20, 56, -286),  # SERPENTINA — iesirea din arc
		Vector3(10, 57, -283),   # diagonala de sus, capatul dinspre arc
		Vector3(46, 58, -284),   # diagonala de sus — statia de telecabina (M4+)
		# Intoarcerea de sus, esantionata pe arc din acelasi motiv ca
		# serpentina: cu un singur punct in varf iesea 11.2 m.
		Vector3(64, 60, -272),   # intoarcerea de sus — intrarea in arc
		Vector3(74, 62, -250),   # varful arcului
		Vector3(48, 63, -236),   # iesirea din arc, spre platou
		Vector3(6, 63, -238),    # platoul culmii — punctul cel mai inalt
		Vector3(-64, 62, -240),  # dreapta trenului de culme
		# --- COBORAREA: flancul de vest, -52 m in ~300 m ---
		Vector3(-128, 56, -268), # buza platoului — creasta de fly-off
		Vector3(-186, 46, -238), # aici se desprinde scurtatura
		Vector3(-254, 33, -180), # vaca traverseaza spre pasune
		Vector3(-262, 21, -98),  # coltul de nord-vest
		Vector3(-196, 10, -46),  # aici revine scurtatura; rampa e chiar inainte
		# --- VALEA: retur aproape plat spre sat ---
		Vector3(-126, 4, -14),   # podul peste parau (decor, M4+)
		Vector3(-58, 1, -10),    # tractorul cu fan matura aici
		Vector3(-26, 0, 4),      # sicana satului
	]


## Scurtatura: taietura prin pasune, peste coltul de nord-vest.
##
## Ocoleste bucla pe coarda: ~252 m de sosea in panta inlocuiti cu ~215 m de
## poteca batatorita prin iarba. Castig brut masurat: ~37 m (~1.4 s), plus ce
## NU intalnesti pe ea: vaca (0.767) si rampa (0.856) raman pe soseaua
## principala. Cine taie pasunea renunta insa si la singurul airtime optional
## al pistei — castigul net e o decizie, nu un cadou.
##
## CONTRAGREUTATEA e latimea, ca la crapatura Stramtorii: 3.2 in loc de 7.0
## inseamna 6.4 m de poteca — singur incapi, in trafic nu. `wet` ramane false
## din acelasi motiv ca acolo: n-are de ce sa fie ud pe o pasune insorita, iar
## contragreutatile se aleg din lume, nu din tabel.
##
## Punctele intermediare tin poteca pe linia de cadere a pantei (44 -> 10 m),
## cu cotele intre cele doua drumuri ca terenul sa se aseze lin pe ea.
func _branch_specs() -> Array[Dictionary]:
	return [{
		"entry": 0.743,   # derivat din (-186, -238), punctul de dupa buza
		"exit": 0.881,    # derivat din (-196, -46), inainte de pod
		"half_width": 3.2,
		"wet": false,
		"label": "pasunea",
		"points": [
			Vector3(-215, 36, -180),
			Vector3(-206, 22, -108),
		],
	}]


## Creasta de fly-off, pe buza platoului: TOATA pista sare aici, alegerea e
## cat de tare intri. Sub ea, rapa declarata — vezi _ravines().
func _flyoff_fracs() -> Array[float]:
	return [0.683] # buza platoului, derivat din (-96, -254)


## Rampa de pe coltul de nord-vest: airtime pe care il POTI evita (alegere de
## linie, nu de curaj) — si pe care scurtatura il sare cu totul.
func _ramp_fracs() -> Array[float]:
	return [0.856] # dreapta dintre coltul NV si revenirea scurtaturii


## Trecerea de cale ferata, pe platoul culmii.
##
## Pusa pe singura bucata orizontala de la inaltime, deliberat: sina cere spatiu
## lateral, iar acolo unde platoul cade spre serpentina, estacada de lemn a
## trenului se vede de jos, din diagonale — avertizarea vizuala pe care o cere
## gimmick-ul de timing.
func _train_fracs() -> Array[float]:
	return [0.647] # mijlocul platoului, derivat din (-29, -239)


## Hazardele mobile, in ordinea turului: carul cu fan pe ulita satului, sania
## cu busteni pe urcarea prin padure, vaca pe coborare (spre pasune), tractorul
## pe returul din vale. Toate matura perpendicular, ca orice SlidingHazard.
func _hazard_fracs() -> Array[float]:
	return [
		0.060, # carul cu fan, pe ulita satului
		0.215, # sania cu busteni, pe urcarea prin padure
		0.767, # vaca, pe coborare — scurtatura o evita
		0.938, # tractorul, pe returul din vale
	]


## Rapa de sub creasta de fly-off, pe latura din afara buclei. Adancimea 16 e
## peste pragul din _build_flyoff_net (plafonul plasei coboara 6 m, garda cere
## > 10): cine rateaza aterizarea chiar cade si e repus, nu aterizeaza pe iarba.
func _ravines() -> Array[Vector4]:
	return [Vector4(0.668, 0.732, 16.0, 1.0)]
