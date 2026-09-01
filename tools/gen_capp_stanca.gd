extends Node
## Rescrie POI G (stanca goala) din Track13.tscn: coaja-erou, peretele
## interior, ferestrele-alcov si buza de la gura.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenCappStanca.tscn
##
## [b]De ce un generator si nu noduri scrise de mana.[/b] Ce se pune aici e
## derivat din geometria MASURATA a elicei (axa, raza 28 m, cotele coapte), nu
## ales din ochi: pozitia fiecarui alcov e o functie de azimutul si cota
## soselei in acel punct. Cifrele intra o data, in tabelul de mai jos, si ies
## ca [Transform3D]-uri in .tscn. Nodurile rezultate sunt EDITABILE — asta e
## regula (memoria `decor-manual-sursa-de-adevar`): generatorul e unealta de
## asezare initiala, .tscn-ul ramane sursa de adevar si se poate trage de
## noduri in editor dupa aceea.
##
## [b]Ce inlocuieste.[/b] Runda 1 pusese 94 de panouri `cliff_band_module` pe
## doua inele. Masurat cu ochii pe captura: din afara se citea gard de scanduri
## — panourile sunt placi de 20x12 m, deci intre ele ramanea cer, iar dinauntru
## soseaua avea aer liber pe AMANDOUA partile. Sonda nu prindea nimic fiindca
## ea intreaba TERENUL, iar terenul chiar urcase la 49 m — dar la r>=40 m, adica
## dincolo de sosea. Intre sosea si creasta nu era nimic, si exact acolo se uita
## camera.
##
## [b]Ce s-a incercat si s-a scos: o coroana de hornuri pe buza.[/b] Buza cojii
## e un cerc aproape perfect (masurat: y=83.0 pe 21 din 24 de azimuturi, raza
## 49.5-51.9), si de departe citeste tambur de masina, nu stanca. Incercarea a
## fost sa se infiga 14 hornuri de kit pe muchie, ca silueta sa iasa zimtata ca
## la Uchisar. Pe captura a iesit vizibil mai RAU: hornurile sunt conuri
## SUBTIRI si verticale (4-5 m grosime la 12-18 m inaltime), asezate la pas
## egal pe un cerc — adica o coroana de COSURI DE FABRICA, cu palariile de
## bazalt citind ca niste capace si benzile portocalii (slotul 20) tipand pe
## cremul cojii. Silueta zimtata a lui Uchisar vine din MASA cioplita, nu din
## tepi lipiti pe margine. De aceea nu s-a reglat, s-a scos.
##
## [b]De ce nu poate terenul sa faca peretele interior.[/b] `_lift_peaks` stinge
## orice masiv sub `PEAK_ROAD_CLEAR` (6 m) de asfalt si il aduce la putere plina
## abia la `PEAK_ROAD_FULL` (32 m). Elicea are raza 28 si semi-latime 6, deci
## carosabilul tine r=22..34: TOT peretele interior cade in masca. Terenul are
## voie sa urce abia de la r~40 — de aia crestele masurate sunt reale si totusi
## invizibile din masina. Inchiderea pe care o vede camera trebuie sa fie
## DECOR, nu teren. Terenul ramane cum e (sonda lui trece), decorul adauga ce
## ii lipseste.

const AXIS := Vector2(-302.02, 6.00)
const HELIX_R: float = 28.0
const FLOOR_Y: float = 11.0

## Coaja-erou: `hollow_rock.glb`, masurat r_interior 14.32, r_exterior ~23.4,
## inaltime 46.4 m. Piesa a fost desenata pentru un interior de 28 m DIAMETRU;
## la noi elicea singura are raza 28, deci carosabilul se termina la r=34 si
## coaja trebuie INTINSA in plan (XZ) ca fata interioara sa treaca de sosea.
##
## `SHELL_SXZ` nu e aleasa din ochi: 14.32 * 2.5 = 35.8, adica 1.8 m de garda
## dincolo de marginea asfaltului (34 m). Mai putin ar musca din banda, mai mult
## ar departa peretele de sosea si s-ar pierde inchiderea din cadru.
##
## [b]De ce 0.95, dupa ce 1.6 a costat tot cerul (runda 2).[/b] Argumentul de
## mai jos era ca inaltimea "NU se plateste in cadru din masina", fiindca
## peretele depaseste plafonul frustumului la orice scara peste 1. Prima parte
## e adevarata, concluzia era gresita: daca peretele depaseste plafonul pe
## TOATE cele 24 de azimuturi, atunci in cadru nu mai intra niciodata cer, si
## exact asta a masurat `ProbeGSky` pe varianta cu 1.6 — buza la 83-94 m, ochiul
## vede pana la 47 m, **0 din 24 de azimuturi deschise**. Criticul orb a spus-o
## fara sa aiba cifra: "camera e sigilata intr-un butoi maro inchis, fara cer,
## fara directie de soare, fara silueta". 40 m de zid de prisos pe fiecare
## azimut, platiti ca sa arate bine o silueta pe care nicio captura din masina
## n-o vede.
##
## Cifra noua e derivata din ce trebuie sa se INTAMPLE, nu din raportul de
## forma. Brief-ul POI G cere ca "lumina de sus creste la fiecare tura". Camera
## vede in sus `y_masina + 10 + 0.093*d`, deci acelasi zid se deschide singur pe
## masura ce ochiul urca — cresterea de lumina nu se picteaza, e geometrie.
##
## Coaja NU mai duce insa silueta singura, si de-aia e la 0.78 (buza 47.2 m) si
## nu mai sus. Buza ei e un cerc aproape perfect: la orice cota ar sta, ea se
## deschide pe TOATE azimuturile deodata, adica lumina n-ar creste, ar
## COMUTA. Masurat exact asa dupa prima corectie (buza uniforma la 55 m):
## `ProbeGSky` a dat 0/24 la 36 m si 24/24 la 44 m — un intrerupator, nu o
## crestere. Coaja se aseaza deci la mijlocul intervalului si ZIMTII crestei
## sunt cei care se deschid pe rand (§3).
##
## 11 + 46.4 * 0.78 = 47.2 m. Raportul inaltime/latime scade la 0.38, adica
## piesa e iar un lighean vazuta de afara — dar de afara nu se uita nimeni din
## masina, iar POI G se judeca pe capturile de la 0.80/0.86/0.92, toate
## dinauntru. Daca vreodata se face o captura exterioara a stancii, silueta se
## rezolva acolo unde se vede: din `Creasta`, nu din scara cojii.
const SHELL_SXZ: float = 2.5
const SHELL_SY: float = 0.78
const SHELL_INNER_R: float = 14.32 * SHELL_SXZ  # 35.8 m

## Raza la care stau ORIGINILE panourilor de perete interior.
##
## Nu e raza zidului: panoul are fata inclinata la 3.82 m IN FATA originii lui
## (masurat pe piesa, nu presupus). Deci originea la 38.8 pune fata la 35.0,
## adica exact 1 m dincolo de marginea asfaltului (34.0).
##
## Prima incercare pusese originile la 36.5 „ca sa fie langa sosea" si fetele
## ajungeau la 32.7 — cu 1.3 m PESTE banda. Pe captura din masina zidul intra in
## carosabil si inghitea firidele; la volan ar fi fost o serie de stalpi in
## traiectorie.
const INNER_WALL_R: float = 38.8

## Scara firidelor. [b]0.7, coborata de la 1.6 in runda 2.[/b]
##
## `hall_alcove` are 3.2 x 3.0 x 1.5 m. La scara 1.6 deschiderea iese
## **5.1 x 4.8 m** — cat o poarta de garaj, pe un perete de 12 m. De-aia
## citeau panouri luminoase si nu ferestre: nu era doar culoarea interiorului,
## era MARIMEA. La 0.7 deschiderea e 2.2 x 2.1 m, adica o fereastra de casa
## sapata in tuf, si e chiar cheia de scara pe care criticul o cerea (ferestrele
## sunt singurul obiect din cadru a carui marime reala o stie privitorul).
##
## Efectul secundar rezolva si stralucirea: aria luminata scade de 5.3 ori
## (5.1*4.8 -> 2.2*2.1), deci acelasi material portocaliu ocupa a cincea parte
## din pixeli. Materialul nu se poate schimba din .tscn (vezi nota din `_ready`),
## dar suprafata pe care o acopera, da.
const ALCOVE_S: float = 0.7

## Ferestrele: pe partea dinspre vale, la cote care cresc odata cu elicea.
## Fiecare e un ALCOV, nu o gaura — vezi blocul 4.
##
## [b]Runda 2: nu se mai aleg azimuturile, se aleg PANOURILE.[/b] Lista veche
## dadea azimuturi rotunde (107 / 77 / 47 / 17), alese ca sa cada "pe sfertul
## dinspre vale". Dar peretele nu e continuu la orice azimut: sunt 14 panouri pe
## etaj, cu centrele la `k * 360/14 + etaj * 8`, adica pe etajul 0 la 0, 26, 51,
## 77, 103... Trei din cele zece ferestre cadeau INTRE panouri, iar `ProbeGFlush`
## a masurat exact asta: raza zidului la azimutul lor era infinit, adica **nu
## exista zid in spatele lor**. Se vedea si pe captura la 1:1 — o cutie cu
## obrajii luminati plutind, fiindca nu avea in ce sa fie sapata.
##
## Acum fereastra se declara ca INDICE DE PANOU (etaj, k) si azimutul iese din
## el. Nu se mai poate cere o firida acolo unde nu e perete.
##
## [b]Si nu se aleg nici "pe sfertul dinspre vale".[/b] A doua incercare a pus
## cate trei-patru panouri consecutive pe sfertul 67-145 grade, cu argumentul ca
## "acolo se uita camera cand urca". Fals, si masurabil fals: `ProbeGAim` a
## calculat pe ce azimut al inelului cade privirea la fiecare fractie judecata —
## 43, -121, 158, 70, -97, 56 grade, adica IMPRASTIATE pe tot inelul, fiindca
## elicea se roteste sub tine. Din cele zece firide, sase nu erau vizibile in
## niciunul dintre cadre. Pe captura la 0.80 nu se vedea NICIUNA.
##
## Aceeasi lectie ca in memoria `masoara-inainte-nu-langa`, mutata pe inel:
## "dinspre vale" descrie unde e valea, nu unde se uita omul. Fiecare fereastra
## de mai jos e ancorata de o fractie din captura.
const WINDOWS: Array = [
	# {etaj, k} — indicele panoului in care se sapa firida. Alese din
	# `ProbeGAim`: panoul pe care CADE PRIVIREA la fiecare fractie judecata.
	# frac 0.80 (y 14.9, privire az  43) -> etaj 0, k 2
	{"etaj": 0, "k": 2},
	# frac 0.84 (y 23.1, privire az -121) -> etaj 1, k 9
	{"etaj": 1, "k": 9},
	# frac 0.86 (y 27.3, privire az  158) -> etaj 1, k 6
	{"etaj": 1, "k": 6},
	# frac 0.88 (y 31.4, privire az   71) -> etaj 1, k 2
	{"etaj": 1, "k": 2},
	# frac 0.92 (y 39.6, privire az  -97) -> etaj 2, k 10
	{"etaj": 2, "k": 10},
	# frac 0.96 (y 47.6, privire az   56) -> etaj 2, k 2
	{"etaj": 2, "k": 2},
	# Inca patru, vecine cu cele de mai sus: o singura fereastra pe cadru e un
	# accident, doua-trei sunt o lume locuita. Nu mai multe — runda 17 pe POI B
	# a dublat densitatea deschiderilor si a fost REVERTITA (rame care traversau
	# silueta in cer gol). Densitatea se verifica pe captura la 1:1, nu se creste
	# din principiu.
	{"etaj": 0, "k": 3}, {"etaj": 1, "k": 10},
	{"etaj": 2, "k": 3}, {"etaj": 2, "k": 9},
]


func _fmt(v: float) -> String:
	return "%.3f" % v


## Transform3D in forma pe care o scrie Godot in .tscn.
##
## [b]Atentie la ordine — aici s-a rupt runda trecuta.[/b] In .tscn cele noua
## numere sunt AXELE bazei (X, apoi Y, apoi Z) date pe componente in spatiul
## lumii. In GDScript `b.x` ESTE chiar axa X, dar `b.x.z` nu e componenta pe
## care o astepta fisierul: indexarea `b[rand][coloana]` si accesul pe axe se
## transpun una pe alta. Versiunea veche scria randurile bazei acolo unde Godot
## citeste coloanele, adica TRANSPUSA — pentru o rotatie in jurul lui Y asta e
## exact rotatia INVERSA (yaw -> -yaw).
##
## Nu era o greseala vizibila din arbore: nodurile aveau originile corecte, la
## r=38.8, si sonda de layout trecea. Dar panourile de zid erau intoarse pe dos,
## si fata lor de 20 m matura spre AXA in loc sa priveasca spre ea: masurat,
## geometria ajungea la r=28.5, adica 5.5 m PESTE marginea asfaltului (34.0), pe
## banda pe care urca masina. Se vedea si pe captura din joc (frac 0.90) ca un
## perete lipit de parbriz.
##
## Se scrie explicit pe componente, ca sa nu mai depinda de care convenție isi
## aminteste cititorul. Memoria `rotatii-in-builder-semnul` spune acelasi lucru:
## semnul se DERIVA, nu se ghiceste.
func _xf(basis: Basis, o: Vector3) -> String:
	var b := basis
	return "Transform3D(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % [
		_fmt(b.x.x), _fmt(b.y.x), _fmt(b.z.x),
		_fmt(b.x.y), _fmt(b.y.y), _fmt(b.z.y),
		_fmt(b.x.z), _fmt(b.y.z), _fmt(b.z.z),
		_fmt(o.x), _fmt(o.y), _fmt(o.z)]


## Un nod instanta de GLB, cu rotatie in jurul lui Y si scara pe axe.
func _node(name: String, parent: String, res: String, o: Vector3,
		yaw: float, scale: Vector3, meta: String, mesh_child: String = "",
		mat_sub: String = "") -> String:
	var b := Basis(Vector3.UP, yaw).scaled(scale)
	var s := "[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%s\")]\n" % [
		name, parent, res]
	s += "transform = %s\n" % _xf(b, o)
	if meta != "":
		s += "metadata/coliziune = \"%s\"\n" % meta
	s += "
"
	# Materialul se pune pe COPILUL de mesh al instantei, ca override de
	# suprafata. Un [node] cu `parent=` care coboara in instanta e felul in care
	# Godot scrie in .tscn o proprietate schimbata pe un nod mostenit.
	if mesh_child != "" and mat_sub != "":
		s += "[node name=\"%s\" parent=\"%s/%s\" index=\"0\"]
" % [
			mesh_child, parent, name]
		s += "surface_material_override/0 = SubResource(\"%s\")

" % mat_sub
	return s


func _ready() -> void:
	var out := ""

	# [b]Ce s-a incercat si NU merge: sa stingi firida din .tscn.[/b] Interiorul
	# alcovului iese `255,184,71` masurat pe captura (canalul rosu taiat), langa
	# un zid insorit la `107,72,41` — de 2.4 ori mai luminos decat cea mai
	# luminoasa piatra din cadru, deci citeste reclama, nu camera sapata. Piesa
	# e de ORAS SUBTERAN: UV-ul ei cade pe slotul de torta, unde exact asta e
	# corect.
	#
	# Corectia evidenta — un `StandardMaterial3D` cu albedo 0.34 pus ca
	# `surface_material_override/0` pe copilul de mesh — a fost scrisa, a intrat
	# in .tscn, sonda a confirmat "albedo (0.34, ...)" pe suprafata... si captura
	# a iesit IDENTICA, pixel cu pixel. Cauza: decorul cheama
	# `Palette.apply_world_material()`, care pune `material_override` PE NOD, iar
	# in Godot overrideul de nod bate overrideul de suprafata. Deci orice
	# material scris in .tscn pentru piesele de decor e mort la runtime.
	#
	# De retinut, fiindca sonda a spus "da" si cadrul a spus "nu": verificarea
	# care conteaza a fost sa sting nodul `Ferestre` si sa vad ca patratele
	# portocalii dispar — abia aia a dovedit ce sunt.
	# --- 1. Coaja: masivul propriu-zis, o singura piesa -------------------
	# Asezata pe podeaua hornului (11 m). Un singur mesh, un singur material
	# (PaletteAtlas) — deci inchiderea completa costa ZERO materiale in plus
	# fata de cele 94 de panouri pe care le scoate.
	#
	# [b]Fara coliziune, si nu din comoditate.[/b] Piesa are POALE evazate:
	# masurat pe azimutul drumului de apropiere (235 grade), un sort subtire de
	# la y=11 la y=14 care se intinde pana la r=69, in timp ce peretele adevarat
	# sta la r=36 si r=51-58. Drumul care vine din orasul subteran trece pe
	# acolo la y=12.4 — deci cu colizor, sortul ala devine un zid invizibil fix
	# peste soseaua de intrare. `probe_solid` l-a si prins: „Coaja_col atinge
	# masina la frac 0.736", exact acolo. Nicio captura n-ar fi aratat-o.
	#
	# Si nu e nevoie de el: ce opreste masina pe partea de afara e TERENUL, care
	# urca 30-49 m pe fiecare azimut (verificat de `ProbeCappRock`), iar pe
	# partea de sus soseaua isi are marginile ei. Coaja e piele vizuala asezata
	# in afara carosabilului, nu peretele de care te lovesti.
	out += _node("Coaja", "DecorManual/G) Stanca goala",
		"43_hollow", Vector3(AXIS.x, FLOOR_Y, AXIS.y), 0.0,
		Vector3(SHELL_SXZ, SHELL_SY, SHELL_SXZ), "none")

	# --- 2. Peretele INTERIOR, inel inchis (fata zidului la r=35) ---------
	#
	# De ce mai e nevoie de el peste coaja. Coaja are RAMPA EI in interior, si
	# fata ei interioara urmeaza rampa aia: masurat pe azimut si cota, peretele
	# apropiat (r~36) exista doar acolo unde trece spirala proprie a piesei, iar
	# in rest golul se deschide pana la r~51. Elicea NOASTRA e alta (raza 28,
	# alt pas), deci cele doua spirale se suprapun doar pe bucati: din 25 de
	# puncte ale elicei, 13 aveau perete langa ele si 12 dadeau in gol. Aia se
	# si vedea din masina — inchis pe o bucata, deschis pe urmatoarea.
	#
	# Inelul asta nu depinde de geometria interna a cojii: e continuu pe toate
	# cele 360 de grade si pe toata inaltimea urcarii (12 -> 48 m).
	#
	# 14 panouri pe etaj, nu 12: coarda unui panou de 20.3 m la raza 38.8 e
	# 17.3 m, deci raman 3.0 m de SUPRAPUNERE intre vecini. Runda 1 pusese
	# panourile cap la cap si intre ele ramaneau fante prin care se vedea cerul
	# — „gard de scanduri". Suprapunerea e ce face zidul sa fie zid.
	out += "[node name=\"PereteInterior\" type=\"Node3D\" parent=\"DecorManual/G) Stanca goala\"]\n\n"
	var rings := 0
	for etaj in 3:
		# Panoul are 12.4 m; etajele se calca 0.4 m ca sa nu ramana rost orizontal.
		var y := FLOOR_Y + 1.0 + float(etaj) * 12.0
		for k in 14:
			var az := float(k) * (360.0 / 14.0) + float(etaj) * 8.0
			var a := deg_to_rad(az)
			var p := Vector3(AXIS.x + INNER_WALL_R * cos(a), y,
				AXIS.y + INNER_WALL_R * sin(a))
			# Fata inclinata a modulului e -Z; ca ea sa priveasca spre AXA
			# (adica spre sosea), -Z local trebuie sa arate spre centru. Acelasi
			# calcul ca la alcovuri, verificat cu dot in loc de ghicit
			# (memoria `rotatii-in-builder-semnul`).
			var yaw := PI * 0.5 - a
			out += _node("Zid%d_%02d" % [etaj, k],
				"DecorManual/G) Stanca goala/PereteInterior",
				"40_cliff", p, yaw, Vector3(1.0, 1.05, 1.0), "none")
			rings += 1

	# --- 3. Creasta: acelasi panou, dar peste buza si la inaltimi diferite -
	#
	# Buza cojii e un cerc aproape perfect (masurat: y=83.0 pe 21 din 24 de
	# azimuturi, raza 49.5-51.9), si de departe cercul ala citeste TAMBUR, nu
	# stanca. Referinta (Uchisar) are marginea de sus RUPTA, cu bucati de masiv
	# de inaltimi diferite.
	#
	# Ruptura se face cu acelasi `cliff_band_module` — placa de faleza, adica
	# MASA cioplita — nu cu hornuri (incercat si scos, vezi nota de sus:
	# conurile subtiri au iesit cosuri de fabrica). Panourile stau pe un inel
	# mai larg (r=44, deci in afara zidului interior si in dreptul flancului
	# cojii) si li se schimba doar INALTIMEA, dupa un tipar fix de trei trepte.
	# Asa silueta iese zimtata din aceeasi piatra, nu din obiecte lipite.
	#
	# Sunt in afara culoarului camerei: carosabilul se termina la r=34, fetele
	# astea ajung la 44 - 3.82 = 40.2, adica 6 m mai incolo si zeci de metri mai
	# sus decat orice vede masina din interior.
	# [b]Cotele coborate in runda 2, si de ce zimtii conteaza acum.[/b] Creasta
	# statea la 62-71 m, adica PESTE buza cojii (55.1 m) — deci ea inchidea
	# cerul chiar dupa ce coaja a fost coborata. Masurat cu `ProbeGSky` dupa
	# coborarea cojii: inca 0/24 azimuturi deschise, fiindca panourile cresc IN
	# SUS de la cota la care sunt puse (varf = baza + 12.4*sy, verificat pe
	# cifrele sondei: 78.0 si 79.9), deci scara verticala de 1.6-2.1 era
	# adevaratul capac.
	#
	# Acum baza e 34 m si variatia s-a mutat din Y in SCARA, cu 12 valori
	# distincte: varfurile se intind de la 40.2 la 61.9 m.
	#
	# Asezarea asta face doua lucruri deodata. Bucatile joase trec sub plafonul
	# cadrului devreme in urcare, deci intre ele apare cer — "lumina care creste
	# tura cu tura" din brief. Bucatile inalte raman peste si taie cerul ala in
	# bucati: silueta zimtata, care lipsea cu totul. Un inel de aceeasi cota ar
	# fi dat ori butoi inchis (sus), ori un inel de cer perfect uniform (jos) —
	# la fel de mort, si masurat ca atare.
	#
	# 12 bucati, nu mai multe: lectia POI D (47 -> 69 module au facut masa MAI
	# uniforma, nu mai bogata). Variatia sta in cote, nu in numar.
	var ridge := 0
	out += "[node name=\"Creasta\" type=\"Node3D\" parent=\"DecorManual/G) Stanca goala\"]\n\n"
	# Douasprezece inaltimi DIFERITE, nu trei repetate. Varfurile ies intre 40.2
	# si 61.9 m, iar plafonul cadrului urca de la 37 m (masina la 20) la 61 m
	# (masina la 44): deci zimtii trec sub plafon UNUL CATE UNUL pe masura ce
	# urci. Asta e "lumina creste tura cu tura" masurabil, si tot asta rupe
	# conturul pe cer.
	#
	# Ordinea e amestecata deliberat (nu 0.5, 0.6, 0.7...): un inel care creste
	# monoton in jurul axei ar citi rampa elicoidala a doua, adica exact
	# regularitatea pe care o reproseaza criticii ("dinti egali", "rafturi
	# stantate"). Alternanta inalt/jos da colturi de masiv.
	var tops: Array = [0.50, 1.35, 0.75, 2.05, 0.95, 1.60,
		0.60, 2.25, 1.10, 0.85, 1.85, 0.70]
	for k in 12:
		var az := float(k) * 30.0 + 14.0
		var a := deg_to_rad(az)
		var p := Vector3(AXIS.x + 44.0 * cos(a), 34.0,
			AXIS.y + 44.0 * sin(a))
		var yaw := PI * 0.5 - a
		# Scara pe verticala urmeaza treapta: bucata mai inalta e si mai masiva,
		# altfel ar iesi o placa intinsa, nu un colt de stanca.
		var sy := float(tops[k % tops.size()])
		out += _node("Colt%02d" % k, "DecorManual/G) Stanca goala/Creasta",
			"40_cliff", p, yaw, Vector3(1.15, sy, 1.15), "none")
		ridge += 1

	# --- 4. Ferestrele, ca ALCOVURI ---------------------------------------
	# Criticul orb a numit exact asta: o fereastra care e o ABSENTA arata cer,
	# nu camera. In referinta, fiecare deschidere are un interior in spate si
	# lumina cade pe el. Deci fiecare fereastra de aici e o nisa (`hall_alcove`,
	# 3.2x3x1.5 m) ingropata in grosimea peretelui, cu fata spre sosea.
	out += "[node name=\"Ferestre\" type=\"Node3D\" parent=\"DecorManual/G) Stanca goala\"]\n\n"
	var wi := 0
	for w: Dictionary in WINDOWS:
		# Azimutul si cota IES din indicele panoului — aceeasi formula ca la
		# constructia peretelui (blocul 2), ca firida sa cada mereu pe piatra.
		var etaj := int(w["etaj"])
		var k := int(w["k"])
		var az := float(k) * (360.0 / 14.0) + float(etaj) * 8.0
		var a := deg_to_rad(az)
		# Cota: la mijlocul inaltimii panoului, ca firida sa aiba piatra si
		# deasupra, si dedesubt. Panoul incepe la FLOOR_Y + 1 + etaj*12 si are
		# 12.4 m scalati cu 1.05.
		var y := FLOOR_Y + 1.0 + float(etaj) * 12.0 + 6.0
		# [b]Cat de adanc.[/b] Varianta veche punea gura firidei la o raza FIXA
		# (35.02), calculata din "fata panoului e cu 3.82 m inaintea originii".
		# Cifra aia e o MEDIE: panoul de faleza e cioplit, deci fata lui variaza
		# cu azimutul si cu inaltimea. `ProbeGFlush` a masurat fata reala intre
		# 35.04 si 36.03 — adica firida iesea din perete cu pana la 1 m exact
		# acolo unde panoul e mai retras, si aia se vedea ca o cutie lipita.
		#
		# Se ingroapa cu 0.3 m mai adanc decat media, adica gura ajunge la 35.28
		# cand fata cea mai apropiata a zidului e la 35.04: firida e RETRASA cu
		# un sfert de metru, deci are prag si un obraz umbrit, dar ramane
		# deschisa vederii.
		#
		# [b]0.3 si nu 1.2, dupa o incercare esuata.[/b] Prima corectie a impins
		# firidele cu 1.2 m, ca sa treaca sigur dincolo de cel mai retras punct
		# al panoului cioplit. Pe captura la 0.80 rezultatul a fost ca ferestrele
		# au DISPARUT cu totul — nici gaura, nici lumina portocalie, nici cheie
		# de scara. Adica defectul (cutie proeminenta) fusese scos scotand
		# functia, ceea ce e mai rau: criticul spusese explicit ca ferestrele
		# sunt SINGURA cheie de scara din cadru. Marja se pune cat trebuie ca sa
		# nu iasa, nu cat sa nu se vada.
		# Corpul firidei se intinde +- (1.5 * ALCOVE_S) / 2 fata de origine, deci
		# originea se pune cu atat mai in spate ca gura sa cada in planul
		# zidului, plus 0.3 m ca sa fie RETRASA (prag + obraz umbrit).
		var r := INNER_WALL_R - 3.82 + (1.5 * ALCOVE_S) * 0.5 + 0.3
		var p := Vector3(AXIS.x + r * cos(a), y, AXIS.y + r * sin(a))
		# Fata alcovului (+Z local) priveste spre AXA, deci spre sosea.
		var yaw := -a + PI * 0.5
		# [b]Scara UNICA, si de ce conteaza mai mult aici decat oriunde.[/b]
		# Criticul orb: ferestrele sunt "de marimi inconsecvente — si sunt
		# SINGURA cheie de scara din cadru, deci inconsecventa lor strica activ
		# citirea". Intr-o sala fara copaci, fara masini parcate si fara oameni,
		# ochiul citeste marimea lumii din singurul obiect pe care crede ca il
		# cunoaste. Doua ferestre de marimi diferite pe acelasi perete spun ca
		# peretele are doua marimi.
		#
		# Deci toate au aceeasi scara. Variatia vizuala vine din LUMINA (cat de
		# adanc bate soarele in fiecare, dupa azimut) si din inaltime, nu din
		# dimensiune.
		out += _node("Alcov%02d" % wi, "DecorManual/G) Stanca goala/Ferestre",
			"44_alcove", p, yaw, Vector3(ALCOVE_S, ALCOVE_S, ALCOVE_S), "none")
		wi += 1

	print(out)
	var f := FileAccess.open("res://tools/_stanca_noduri.txt", FileAccess.WRITE)
	f.store_string(out)
	f.close()
	print("scris: 1 coaja + %d panouri de zid + %d colturi de creasta + %d firide"
		% [rings, ridge, wi])
	get_tree().quit()
