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
## Tema e "alpine" (#221): cer de altitudine, ceata albastruie, zapada peste
## 78 m si poteca de pamant pe scurtatura. Modelele de hazard individuale
## (car cu fan, vaca, tractor) vin in #224 — pana atunci toate patru folosesc
## sania cu busteni din tema.

func _init() -> void:
	track_name = "Alpii"
	half_width = 7.0
	apply_theme("alpine")


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
func _code_points() -> Array[Vector3]:
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
		# --- CULMEA: drumul care se catara PE masiv ---
		#
		# Secventa e URCARE -> AC -> TRAVERSARE EXPUSA -> AC -> COBORARE, si
		# fiecare bucata are o treaba:
		#
		#   urcarea      poalele de sud, drum larg — aici mai poti depasi
		#   acul 1       te intoarce cu 180° si te pune cu fata la nord
		#   traversarea  flancul de VEST, cu prapastia pe dreapta (vezi
		#                _ravines si _rail_segments) — bucata care sperie
		#   acul 2       te intoarce inapoi spre est, pe umarul de nord
		#   umarul       punctul cel mai inalt (63 m), de unde VEZI traversarea
		#                pe care tocmai ai facut-o, cu 5 m mai jos si la 30 m
		#                lateral — asta e ce face muntele sa se citeasca
		#
		# Versiunea veche era un LOB cu doua diagonale paralele care treceau
		# peste un teren aproape plat: masivul declarat in _peak_specs statea
		# la 95-160 m de asfalt, adica prea departe ca sa fie flanc de munte.
		# Acum drumul trece la 26-40 m de varf si il inconjoara pe trei laturi.
		#
		# Ambele ace SI intoarcerea de pe umar sunt ESANTIONATE PE ARC (patru
		# puncte echidistante pe cercul dorit), regula platita pe serpentina
		# veche: la peste ~90°, punctele de control se pun PE arc, altfel
		# tangentele Catmull-Rom merg de-a lungul corzii si curba se strange.
		# Raza minima masurata pe sectorul asta: 10.2 m in estimator (vechiul
		# lob dadea 9.8 pe acelasi estimator), iar probe_layout ramane arbitrul.
		Vector3(114, 40, -382),  # poalele de sud, intrarea in urcare
		Vector3(80, 43, -388),
		Vector3(46, 45, -388),
		Vector3(16, 48, -380),   # ACUL 1 — arc r=~30, centru ~(20, -352)
		Vector3(-10, 51, -366),
		Vector3(-22, 54, -346),  # iesirea din ac, cu fata la nord
		Vector3(-18, 56, -326),  # TRAVERSAREA EXPUSA — buza de vest
		Vector3(-12, 58, -306),  # mijlocul cornisei: rapa de 26 m pe dreapta
		Vector3(-16, 60, -288),
		Vector3(-37, 61, -257),  # ACUL 2 — arc r=26, centru (-12, -262)
		Vector3(-23, 62, -239),
		Vector3(0, 63, -239),
		Vector3(14, 63, -257),   # iesirea din ac, spre est pe umarul de nord
		Vector3(40, 63, -276),   # umarul — intoarcerea, arc r=28, centru (30, -250)
		Vector3(56, 63, -261),   # statia de telecabina (M4+)
		Vector3(56, 62, -239),
		Vector3(40, 62, -224),
		Vector3(-2, 60, -208),   # platoul de nord — trecerea de cale ferata
		Vector3(-46, 59, -228),
		Vector3(-94, 58, -250),
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
		"entry": 0.754,   # masurat pe (-186, -238), punctul de dupa buza
		"exit": 0.886,    # masurat pe (-196, -46), inainte de pod
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
	return [0.694] # buza platoului, masurat pe (-96, -254)


## Rampa de pe coltul de nord-vest: airtime pe care il POTI evita (alegere de
## linie, nu de curaj) — si pe care scurtatura il sare cu totul.
func _ramp_fracs() -> Array[float]:
	return [0.862] # dreapta dintre coltul NV si revenirea scurtaturii


## Trecerea de cale ferata, pe platoul de nord.
##
## Pusa pe singura bucata orizontala de la inaltime, deliberat: sina cere spatiu
## lateral, iar aici il are — dupa umar, drumul coboara lin spre coborare, fara
## nici un ac in apropiere. Ramane si citirea de dinainte: estacada se vede de
## pe umar, cu un sector inainte sa ajungi la ea, care e chiar avertizarea pe
## care o cere gimmick-ul de timing.
##
## NU se mai poate pune pe traversare, si asta e o consecinta buna a
## rescrierii: acolo drumul e o cornisa cu prapastie pe o latura si perete pe
## cealalta, adica exact locul in care o bariera de tren ar fi fost o capcana
## fara iesire, nu o decizie.
func _train_fracs() -> Array[float]:
	return [0.631] # platoul de nord, masurat pe (-2, -208)


## Hazardele mobile, in ordinea turului: carul cu fan pe ulita satului, sania
## cu busteni pe urcarea prin padure, vaca pe coborare (spre pasune), tractorul
## pe returul din vale. Toate matura perpendicular, ca orice SlidingHazard.
func _hazard_fracs() -> Array[float]:
	return [
		0.058, # carul cu fan, pe ulita satului
		0.206, # sania cu busteni, pe urcarea prin padure
		0.777, # vaca, pe coborare — scurtatura o evita
		0.941, # tractorul, pe returul din vale
	]


## Fiecare hazard cu modelul LUI (#224). Pana aici toate patru foloseau sania
## din tema, adica acelasi obiect de patru ori pe tur.
##
## SCARA E 1.0 PESTE TOT, si asta e o decizie, nu o omisiune: modelele din
## kitul alpin sunt construite la scara reala (masurate cu sonda de kit — carul
## 3.7 m lungime, sania 4.8, vaca 2.9, plugul 4.0), iar masina de referinta are
## 3.8 m. Implicitul de 0.52 vine de la bolovanul de canion, care era modelat
## la 5 m si trebuia micsorat; aici ar face din car o jucarie de 1.9 m.
##
## `roll: false` pe toate — niciunul nu e bolovan. Un car care se da peste cap
## traversand ulita ar fi exact greseala pe care o descrie barca sabani.
##
## `face_travel` doar pe VACA: un animal are un "inainte", deci trebuie sa se
## uite incotro merge (lectia testoasei din track08). Carul, sania si plugul
## sunt targite/impinse pe latime — ele chiar traverseaza cu flancul.
func _hazard_kinds() -> Dictionary:
	const M := "res://assets/models/"
	return {
		0.058: {"model": M + "vehicles/hay_cart.glb",
			"scale": 1.0, "roll": false},
		0.206: {"model": M + "vehicles/timber_sled.glb",
			"scale": 1.0, "roll": false},
		0.777: {"model": M + "props/cow.glb",
			"scale": 1.0, "roll": false, "face_travel": true},
		# Plugul de zapada tine loc de tractor: e utilajul de gospodarie pe care
		# il avem in kit, si pe un drum de munte are rostul lui chiar vara —
		# stationat in vale, nu la lucru. Un tractor propriu-zis ar fi un GLB
		# nou pentru aceeasi silueta si acelasi rol.
		0.941: {"model": M + "vehicles/snowplow.glb",
			"scale": 1.0, "roll": false},
	}


## Golurile declarate, amandoua pe latura din AFARA buclei (semnul +1 e masurat
## cu ProbeTrack09Fracs, nu presupus — depinde de sensul de parcurgere).
##
## 1. PRAPASTIA DE SUB TRAVERSARE (0.462 - 0.502) e miezul pistei, nu decor.
##    Traversarea merge pe cornisa flancului de vest, iar dedesubt terenul
##    trebuie sa CADA — altfel „drumul expus" e o sosea pe iarba, exact ce era
##    inainte. Fractiile acopera cu ~0.01 mai mult de fiecare parte decat
##    traversarea masurata (0.472 - 0.492), fiindca RAVINE_FADE_FRAC stinge
##    rapa gradual la capete: taiata fix pe capete, prapastia ar fi fost cea
##    mai adanca la mijloc si inexistenta exact unde intri in ea.
##
##    Adancimea 26 e derivata, nu aleasa: drumul e la 56-60 m pe portiunea
##    asta, iar poalele masivului stau pe la 30 m. O rapa mai adanca ar taia
##    prin fundul lumii, una de 16 (cat cea de la fly-off) ar lasa o taluz pe
##    care masina l-ar cobori rostogolindu-se, si ar disparea frica. La 26 m
##    caderea e terminala vizual si mecanic: cine e impins afara nu se mai
##    intoarce pe roti, il repune RespawnZone.
##
## 2. Rapa de sub creasta de fly-off (0.668 - 0.732 in vechea numerotare, acum
##    remasurata pe curba noua). Adancimea 16 e peste pragul din
##    _build_flyoff_net (plafonul plasei coboara 6 m, garda cere > 10): cine
##    rateaza aterizarea chiar cade si e repus, nu aterizeaza pe iarba.
func _ravines() -> Array[Vector4]:
	return [
		Vector4(0.462, 0.502, 26.0, 1.0), # prapastia traversarii
		Vector4(0.679, 0.743, 16.0, 1.0), # sub creasta de fly-off
	]


## Prapastia traversarii (indicele 0) e o CORNISA: buza ei incepe la o jumatate
## de metru de asfalt, nu la patru, si cade pe sase metri, nu pe saisprezece.
##
## Masurat pe forma implicita, taind profilul terenului perpendicular pe drum:
## primii 10 m de langa sosea coborau 1.1-1.4 m. Adica exact ce se vedea si in
## captura — o pajiste in panta pe care puteai iesi cu doua roti fara sa
## patesti nimic, sub un drum de pe care tocmai scosesem parapetul ca sa para
## periculos. Cu cornisa: -5 m pe buza, -17 m la cinci metri lateral.
##
## Rapa de fly-off (indicele 1) NU e cornisa, si ramane asa deliberat: acolo
## buza lina e o calitate — cine rateaza saritura aluneca in vale, nu se
## opreste intr-un perete.
func _cornice_ravines() -> Array[int]:
	return [0]


## Masivul central — muntele pe care pista chiar urca.
##
## VARFUL (30, -302) e subiectul pistei, nu decor pe orizont: drumul ii da
## ocol pe trei laturi la 26-40 m de axa, iar traversarea expusa ii taie
## flancul de vest. Raza 130 cu cota 160 nu sunt alese din ochi, sunt singura
## pereche care trece prin trei conditii deodata (masurate cu ProbeAlpineTerrain):
##   - de pe cornisa (cota 58) varful se ridica cu ~60 m peste tine, adica
##     umple cadrul chase cam-ului pe verticala si NU incape intr-o captura;
##   - la acul 2 (cota 62) conul a coborat deja sub cota drumului, deci nu
##     ingroapa asfaltul — un con mai LARG ar fi facut exact asta;
##   - trece de linia de zapada a temei (72 m, fade 18) cu suprafata reala,
##     nu cu varful singur: versiunea veche (104 m pe raza 210) tinea 0.23%
##     din teren peste 90 m, adica un petic alb cat o batista.
##
## Cifra care conteaza NU e cota declarata, ci cat ramane din ea dupa banda de
## protectie a asfaltului (PEAK_ROAD_CLEAR/FULL din TrackSideSampler) si dupa
## zgomotul de dune. De aceea se remasoara dupa orice mutare de traseu.
##
## Al doilea varf (10, -175) ramane: e umarul de sud care inchide interiorul
## buclei si il vezi din sat si din vale. Ridicat 99 -> 120 ca sa nu para o
## movila pe langa noul varf principal — doua cote apropiate citesc a creasta,
## una singura ar fi citit a con izolat.
func _peak_specs() -> Array[Vector4]:
	return [
		Vector4(30, -302, 130, 160),
		Vector4(10, -175, 210, 120),
	]


## Parapetii de pe munte: RITM, nu o singura decizie.
##
## Regula implicita a jocului e gard rosu continuu pe tot exteriorul. Pe
## traversare spune exact pe dos decat vrea pista — un drum de cornisa cu
## balustrada peste tot e o pista de curse, nu un drum de munte. Absenta
## gardului e ce comunica „nu te lasa impins afara".
##
## Dar nici prapastie continua nu merge: 200 m de expunere neintrerupta devin
## fundal, iar frica se toceste. Ritmul e alternanta, si e citit din
## fractiile MASURATE ale sectorului (ProbeTrack09Fracs):
##
##   0.462 - 0.472  stalpi     intrarea pe cornisa — avertizarea
##   0.472 - 0.484  NIMIC      prima bucata expusa: aici e cel mai rau
##   0.484 - 0.490  stalpi     o rasuflare scurta, cat sa observi diferenta
##   0.490 - 0.502  NIMIC      a doua bucata expusa, pana la iesire
##
## Restul turului ramane pe gardul implicit — inclusiv acul 2 si umarul, unde
## caderea ar fi pe teren, nu in gol, deci gardul chiar isi face treaba.
##
## Proportia iese ~35% fara nimic si ~16% pe stalpi DIN SECTORUL DE CULME, nu
## din tur: pe tot turul, portiunea fara parapet e sub 4%. Cifra care conteaza
## pentru senzatie e prima; cea care conteaza pentru „nu pierzi masina din
## greseala" e a doua.
##
## Toate pe latura +1 (exteriorul, masurat), adica exact peste rapa declarata
## in _ravines — asta e conditia pe care o cere Track._rail_segments: fara
## panglica dispare si coliziunea, deci se scoate numai unde caderea e gandita.
func _rail_segments() -> Array[Vector4]:
	return [
		Vector4(0.462, 0.472, RAIL_POSTS, 1.0),
		Vector4(0.472, 0.484, RAIL_NONE, 1.0),
		Vector4(0.484, 0.490, RAIL_POSTS, 1.0),
		Vector4(0.490, 0.502, RAIL_NONE, 1.0),
	]


## Landmark-urile hero (#223): (fractie, latura ±1, id din Track._LANDMARKS).
##   13 biserica · 14/15 chalet mare/mic · 16 statie telecabina
##   17 pilon · 18 pod peste parau · 19 indicator
##
## GRUPAREA E INTENTIA, nu insiruirea (regula din track08): satul e un PILC
## dens intre 0.95 si 0.10 — chalet-uri pe ambele laturi plus biserica — dupa
## care lumea se goleste deliberat pana la telecabina de pe culme. Alternanta
## plin/gol e ce face satul sa citeasca a asezare, nu a decor presarat.
##
## Fractiile sunt cele MASURATE (tools/ProbeTrack09Fracs), nu alese: sicana
## satului cade la 0.972, podul peste parau la 0.925, statia de telecabina pe
## umarul de nord la 0.585. Daca se muta un punct de control, se remasoara.
func _landmark_spots() -> Array[Vector3]:
	return [
		# --- SATUL (0.92-0.10): pilcul dens, de-o parte si de alta a ulitei ---
		Vector3(0.925, -1.0, 18.0), # podul peste parau, la intrarea in sat
		Vector3(0.941, 1.0, 15.0),  # chalet mic, pe dreapta
		Vector3(0.958, -1.0, 14.0), # chalet MARE, pe stanga
		# Biserica la 0.972: turla de 14 m in axul sicanei, deci o vezi cum se
		# apropie pe toata ulita si stii unde se strange drumul. Exact rolul de
		# "reper de franare" din style_bible §7.
		Vector3(0.972, 1.0, 13.0),
		Vector3(0.988, -1.0, 15.0), # chalet mic, inchide pilcul
		Vector3(0.030, 1.0, 15.0),  # ultimul chalet, deja la iesirea din sat
		# --- IESIREA SPRE PADURE: un singur indicator, apoi gol ---
		Vector3(0.132, -1.0, 19.0),
		# --- CULMEA: telecabina, singurul pilc de la inaltime ---
		#
		# Statia pe umarul de nord (0.585), pilonul pe INTERIORUL acului 2
		# (0.526): cablul dintre ele trece pe deasupra acului, deci il vezi o
		# data de dedesubt cand intri in ac si o data de alaturi de pe umar.
		#
		# Pilonul e pe latura -1 (spre munte) DIN OBLIGATIE, nu din gust: pe +1
		# e prapastia traversarii, iar un pilon plantat in gol ar fi exact
		# genul de obiect care pluteste. Statia la fel — pe umar, exteriorul
		# cade spre acul 2.
		Vector3(0.526, -1.0, 17.0),
		Vector3(0.585, -1.0, 16.0),
		# --- COBORAREA: indicator inainte de creasta de fly-off ---
		Vector3(0.672, 1.0, 19.0),
	]
