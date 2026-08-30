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
## [b]De ce si pe verticala, si de ce 1.6.[/b] Intinsa doar in plan, piesa iese
## 46 m inalta si 117 m lata — un LIGHEAN, masurat 0.40 raport inaltime/latime,
## exact ce s-a si vazut pe captura. Brief-ul cere 45 m la 70 m baza, adica 0.64.
## Latimea nu se poate reduce (o impune soseaua), deci se ridica inaltimea:
## 46.4 * 1.6 = 74 m da raportul 0.63.
##
## Inaltimea asta NU se plateste in cadru din masina. Frustumul camerei de
## urmarire vede in sus `10 + 0.093*d` (brief §2.0): de la 36 m — distanta pana
## la perete — inseamna 13.3 m. Peretele depaseste plafonul cadrului la ORICE
## scara peste 1, deci verticala conteaza doar pentru silueta de AFARA, care era
## chiar reprosul: masiv fara silueta pe cer.
const SHELL_SXZ: float = 2.5
const SHELL_SY: float = 1.6
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

## Ferestrele: pe partea dinspre vale (est/nord-est), la cote care cresc odata
## cu elicea. Fiecare e un ALCOV, nu o gaura — vezi `_alcove()`.
##
## Azimuturile sunt alese pe sfertul dinspre vale (0-140 grade), acolo unde
## camera chiar se uita cand masina urca, si esalonate pe cele doua ture ca
## lumina sa creasca tura cu tura (brief POI G).
const WINDOWS: Array = [
	# {azimut, cota}, cotele urmaresc elicea la acel azimut
	{"az": 107.0, "y": 17.0}, {"az": 77.0, "y": 18.4},
	{"az": 47.0, "y": 19.9}, {"az": 17.0, "y": 21.4},
	{"az": 107.0, "y": 34.7}, {"az": 77.0, "y": 36.2},
	{"az": 47.0, "y": 37.7}, {"az": 17.0, "y": 39.1},
	{"az": 137.0, "y": 33.2}, {"az": 137.0, "y": 15.5},
]


func _fmt(v: float) -> String:
	return "%.3f" % v


## Transform3D in forma pe care o scrie Godot in .tscn: basis pe coloane, apoi
## originea.
func _xf(basis: Basis, o: Vector3) -> String:
	var b := basis
	return "Transform3D(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % [
		_fmt(b.x.x), _fmt(b.x.y), _fmt(b.x.z),
		_fmt(b.y.x), _fmt(b.y.y), _fmt(b.y.z),
		_fmt(b.z.x), _fmt(b.z.y), _fmt(b.z.z),
		_fmt(o.x), _fmt(o.y), _fmt(o.z)]


## Un nod instanta de GLB, cu rotatie in jurul lui Y si scara pe axe.
func _node(name: String, parent: String, res: String, o: Vector3,
		yaw: float, scale: Vector3, meta: String) -> String:
	var b := Basis(Vector3.UP, yaw).scaled(scale)
	var s := "[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%s\")]\n" % [
		name, parent, res]
	s += "transform = %s\n" % _xf(b, o)
	if meta != "":
		s += "metadata/coliziune = \"%s\"\n" % meta
	return s + "\n"


func _ready() -> void:
	var out := ""

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
	var ridge := 0
	out += "[node name=\"Creasta\" type=\"Node3D\" parent=\"DecorManual/G) Stanca goala\"]\n\n"
	# Trei trepte de inaltime, repetate: colturi de masiv, nu dinti egali.
	var steps: Array = [0.0, 9.0, 4.0]
	for k in 12:
		var az := float(k) * 30.0 + 14.0
		var a := deg_to_rad(az)
		var p := Vector3(AXIS.x + 44.0 * cos(a), 62.0 + float(steps[k % 3]),
			AXIS.y + 44.0 * sin(a))
		var yaw := PI * 0.5 - a
		# Scara pe verticala urmeaza treapta: bucata mai inalta e si mai masiva,
		# altfel ar iesi o placa intinsa, nu un colt de stanca.
		var sy := 1.6 + 0.25 * float(k % 3)
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
		var az := float(w["az"])
		var a := deg_to_rad(az)
		# Nisa sta INGROPATA in grosimea peretelui, cu gura la fata lui.
		#
		# Cifra e derivata, nu aleasa: alcovul are 1.5 m adancime, scalat 1.6 =
		# 2.4 m, si originea lui e la MIJLOC, deci corpul se intinde +-1.2 m.
		# Firida se ingroapa in FATA zidului, iar fata zidului NU e
		# `INNER_WALL_R` — aia e originea panoului, care isi poarta fata cu
		# 3.82 m inaintea ei. Zidul se vede deci la 38.8 - 3.82 = 35.0.
		# Alcovul are 1.5 m adancime scalata 1.6 = 2.4 m, cu originea la MIJLOC,
		# deci corpul se intinde +-1.2 m: originea la 35.0 + 1.2 = 36.2 pune gura
		# fix in planul zidului si restul in piatra.
		#
		# Prima varianta o asezase fata de coaja (35.8 + 0.6) si corpul iesea de
		# la 35.2 — adica prin perete, in drum. Pe captura se vedea exact asta:
		# o cutie maro plutind pe zid, nu o firida sapata.
		var r := INNER_WALL_R - 3.82 + 1.2
		var p := Vector3(AXIS.x + r * cos(a), float(w["y"]), AXIS.y + r * sin(a))
		# Fata alcovului (+Z local) priveste spre AXA, deci spre sosea.
		var yaw := -a + PI * 0.5
		out += _node("Alcov%02d" % wi, "DecorManual/G) Stanca goala/Ferestre",
			"44_alcove", p, yaw, Vector3(1.6, 1.6, 1.6), "none")
		wi += 1

	print(out)
	var f := FileAccess.open("res://tools/_stanca_noduri.txt", FileAccess.WRITE)
	f.store_string(out)
	f.close()
	print("scris: 1 coaja + %d panouri de zid + %d colturi de creasta + %d firide"
		% [rings, ridge, wi])
	get_tree().quit()
