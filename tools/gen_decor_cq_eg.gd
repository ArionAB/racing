extends Node
## Generator de decor MANUAL pentru Chongqing, sectiunile POI E / E' / F / G / S
## (cheiul Chaotianmen, telecabina, nodul Huangjuewan, Liziba, fundalul).
##
## Acelasi rost ca `gen_decor_chongqing.gd`, si aceeasi disciplina: fisierul NU
## aseaza nimic in joc, CALCULEAZA transformarile care se lipesc apoi de mana
## in `Track12.tscn` sub `DecorManual`, in noduri de zona. Cotele si pozitiile
## vin din ruta coapta si din `sampler.ground_y`, nu din ochi — un pilon pus
## „cam pe acolo" fie pluteste, fie intra in asfalt, si nici una nu se vede
## intr-o captura de sus.
##
## De ce un fisier separat de `gen_decor_chongqing.gd`: alea sunt zonele de MAL
## (deja lipite in scena, cu numere de nod fixe). Regenerarea lor ar renumerota
## tot. Aici se genereaza DOAR zonele noi.
##
## Rulare (ca SCENA — pista cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorCqEG.tscn
##   ... -- --zone=chei|nod|liziba|fundal
##
## Iesirea se lipeste in Track12.tscn dupa liniile [ext_resource] pe care le
## tipareste singura la inceput.

const TRACK := "res://scenes/tracks/Track12.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track12.tscn. Primele
## cinci exista deja in scena; restul se adauga.
const RES := {
	"chongqing/vehicles/cargo_ship": "20_ship",
	"chongqing/props/lamp_lantern_a": "21_lamp",
	"chongqing/props/container": "22_box",
	"chongqing/structures/hongya_dong": "23_hongya",
	"chongqing/buildings/tower_silhouette_a": "24_tower",
	"chongqing/props/bollard": "30_bollard",
	"chongqing/structures/pillar_round": "31_pillar",
	"chongqing/props/construction_barrier": "32_barrier",
	"chongqing/buildings/liziba_block": "33_liziba",
	"chongqing/structures/footbridge": "34_footbridge",
	"chongqing/props/mailbox_wall": "35_mailbox",
	"chongqing/props/bicycle": "36_bike",
	"chongqing/buildings/tower_silhouette_b": "37_towerb",
	"chongqing/buildings/tower_silhouette_c": "38_towerc",
	"chongqing/structures/bay_bridge": "39_baybridge",
	"chongqing/props/neon_sign_a": "40_neona",
	"chongqing/props/neon_sign_c": "41_neonc",
	"chongqing/props/lamp_lantern_c": "42_lampc",
	"chongqing/vehicles/mini_car_a": "43_minia",
	"chongqing/vehicles/mini_car_b": "44_minib",
	"chongqing/props/scooter": "45_scooter",
	"chongqing/props/laundry_line": "46_laundry",
	"chongqing/props/table_stools": "47_table",
	"chongqing/props/steam_vent": "48_steam",
	"chongqing/buildings/shophouse_a": "49_shopa",
	"chongqing/buildings/shophouse_b": "50_shopb",
	"chongqing/buildings/shophouse_c": "51_shopc",
	"chongqing/buildings/restaurant_front": "52_restaurant",
}

## Aceeasi valoare ca `Track.QUAY_FREEBOARD` — cat de sus sta dala cheiului
## peste apa. Daca se schimba acolo, se schimba si aici.
const QUAY_FREEBOARD: float = 3.2

var _track: Track
var _sampler: TrackSideSampler
var _sea: float
var _out: Array[String] = []
var _n := 100
var _zone := ""


func _ready() -> void:
	await get_tree().process_frame
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			only = arg.trim_prefix("--zone=")
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_sea = _sampler.mean_road_y() + _track.sea_level_offset
	print("; sea_y=%.2f  chei=%.2f" % [_sea, _sea + QUAY_FREEBOARD])
	if only == "" or only == "chei":
		_zone_chei()
	if only == "" or only == "nod":
		_zone_nod()
	if only == "" or only == "liziba":
		_zone_liziba()
	if only == "" or only == "fundal":
		_zone_fundal()
	print("")
	for line in _out:
		print(line)
	print("; %d piese" % (_n - 100))
	get_tree().quit(0)


# ---------------------------------------------------------------- ajutoare

## Pozitia si cadrul soselei la o fractie de tur: [pozitie, side, inainte].
func _at(f: float) -> Array:
	var r := _track.routes[0]
	var n := r.count()
	var i := int(round(fposmod(f, 1.0) * float(n))) % n
	var p := r.baked[i]
	var side := _track._side_at(i)
	var fwd := (r.baked[(i + 1) % n] - p).normalized()
	return [p, side, fwd, _track.width_at_index(i)]


## Un punct la `off` metri lateral de axa la fractia `f` (pozitiv = dreapta).
func _off(f: float, off: float) -> Vector3:
	var st := _at(f)
	var p: Vector3 = st[0]
	var side: Vector3 = st[1]
	return p + side * off


## Unghiul de yaw care intoarce +Z al modelului spre directia de mers.
func _yaw_fwd(f: float) -> float:
	var fwd: Vector3 = _at(f)[2]
	return atan2(fwd.x, fwd.z)


## Unghiul care intoarce +Z al modelului spre exteriorul soselei (dreapta).
func _yaw_side(f: float) -> float:
	var side: Vector3 = _at(f)[1]
	return atan2(side.x, side.z)


# ----------------------------------------------------------- 5) cheiul (E)

## Cat de sus peste linia apei mai numara terenul drept „chei uscat". Sub
## atat, un obiect asezat acolo pluteste peste rau — exact ce a iesit in prima
## rundă cu bolarzii.
const DRY_MARGIN: float = 0.4

## Offsetul lateral la care se termina cheiul uscat, cautat DIN drum spre apa.
## Se cauta, nu se calculeaza din `width_at_index`: soseaua se ingusteaza de la
## 9 la 7 m intre 0.478 si 0.490, iar buza cheiului NU se ingusteaza odata cu
## ea — bolarzii pusi la „marginea asfaltului + 1.6" ajungeau in apa exact pe
## portiunea aia (vazut in captura de la 0.50).
func _quay_edge(f: float, dir: float) -> float:
	var o := _at(f)[3] as float
	var last := o
	while absf(o) < 60.0:
		var q := _off(f, o * dir)
		if _sampler.ground_y(q.x, q.z) < _sea + DRY_MARGIN:
			break
		last = o
		o += 0.5
	return last * dir


## Cheiul Chaotianmen, 0.455..0.515: bolarzi pe buza dinspre apa, stive de
## containere pe umarul dinspre uscat, un slep acostat la dana si felinare.
##
## Partea dinspre apa e DREAPTA (side pozitiv): `ground_y` cade sub cota apei
## de la ~+8 m incolo. Toate piesele isi iau cota din `ground_y`, nu din cota
## soselei: cheiul e cu 0.3 m mai jos decat asfaltul, si un container asezat la
## cota drumului sta pe jumatate ingropat, inclinat pe panta umarului.
func _zone_chei() -> void:
	_zone = "5) Cheiul Chaotianmen"
	# Bolarzi pe BUZA cheiului, cautata (vezi `_quay_edge`), retrasi cu 1.2 m.
	var f := 0.462
	while f < 0.512:
		var edge := _quay_edge(f, 1.0)
		var q := _off(f, edge - 1.2)
		_node("chongqing/props/bollard", "bolard",
			Vector3(q.x, _sampler.ground_y(q.x, q.z), q.z),
			_yaw_side(f), 1.0, "none")
		f += 14.0 / 2068.3
	# Stive de containere pe umarul dinspre USCAT (stanga), in trei grupuri.
	# Grupuri mici si rare — restul cheiului ramane gol, ca in referinta.
	# Cota fiecarei bucati e `ground_y` SUB EA, nu sub centrul grupului: pe un
	# umar in panta, doua containere alaturate nu stau la aceeasi cota.
	var stacks := [
		[0.4635, 0.0, 0.0], [0.4635, 0.0, 2.6], [0.4635, 6.4, 0.0],
		[0.4795, 0.0, 0.0], [0.4795, 6.4, 0.0], [0.4795, 6.4, 2.6],
		[0.4955, 0.0, 0.0], [0.4955, 0.0, 2.6], [0.4955, 6.4, 0.0],
	]
	for s: Array in stacks:
		var fr: float = s[0]
		var st := _at(fr)
		var fwd: Vector3 = st[2]
		var base := _off(fr, -(st[3] as float) - 6.5)
		var q := Vector3(base.x + fwd.x * s[1], 0.0, base.z + fwd.z * s[1])
		_node("chongqing/props/container", "cont",
			Vector3(q.x, _sampler.ground_y(q.x, q.z) + s[2], q.z),
			_yaw_fwd(fr), 1.0, "hull")
	# Felinare pe umarul dinspre uscat, la 30 m — continua sirul de pe malul
	# de vest, care se opreste inainte de cheiul asta.
	f = 0.458
	while f < 0.516:
		var q := _off(f, -(_at(f)[3] as float) - 2.4)
		_node("chongqing/props/lamp_lantern_a", "felinarE",
			Vector3(q.x, _sampler.ground_y(q.x, q.z), q.z),
			_yaw_side(f) + PI, 1.0, "none")
		f += 30.0 / 2068.3
	# Slepul acostat la dana, langa stiva din mijloc. Pescajul: carena sub apa.
	var dana := _off(0.4795, 26.0)
	_node("chongqing/vehicles/cargo_ship", "slep_chei",
		Vector3(dana.x, _sea - 1.7, dana.z), _yaw_fwd(0.4795), 0.85, "none")
	# Doua firme si un felinar chinezesc pe cheiul dinspre uscat: singurul
	# neon din sectiunea asta (brief §4: accent, sub 1% din pixeli).
	for spec: Array in [[0.4700, "neon_sign_a", "40_neona"],
			[0.5000, "neon_sign_c", "41_neonc"]]:
		var fr: float = spec[0]
		var st := _at(fr)
		var q := _off(fr, -(st[3] as float) - 3.0)
		_node("chongqing/props/" + spec[1], "firmaE",
			Vector3(q.x, _sampler.ground_y(q.x, q.z) + 2.4, q.z),
			_yaw_side(fr) + PI, 1.0, "none")


# --------------------------------------------------- 6) nodul Huangjuewan (F)

## Pilonii de sub tronsoanele in aer. Pasajul exista deja in teren
## (`custom_overpass_ranges` 0.676..0.901); aici vine ce se VEDE de dedesubt:
## doua siruri de piloni sub tablier.
##
## Cotele nu se ghicesc: baza fiecarui pilon e `ground_y` sub el, varful e
## cota soselei minus grosimea tablierului, iar scara pe Y iese din diferenta.
## Modelul are 8.84 m, deci un pilon de 30 m cere scara 3.4 — peste atat
## inelele de cofraj se intind atat de mult incat nu mai dau scara, si atunci
## se pun DOUA bucati suprapuse (pila in doua tronsoane, ca la nodurile reale).
const PILLAR_H: float = 8.84
const DECK_THICK: float = 1.6
const PILLAR_MAX_SCALE: float = 3.6

func _zone_nod() -> void:
	_zone = "6) Nodul Huangjuewan"
	# Sirul de pile de sub pasaj. Pasul de 26 m e cel din referinta (bar/F_nod:
	# pile dese, nu rare) si e si limita peste care un tablier de 14 m pare ca
	# pluteste.
	var f := 0.700
	while f < 0.888:
		_bent(f)
		f += 26.0 / 2068.3
	# ORASUL DE SUB NOD. Brief §2.0: „tot ce e impresionant sta SUB jucator".
	# Fara el, flancul spiralei e o panta gri goala — masurat la volan, capturile
	# de la 0.65/0.75/0.80 nu aveau nimic intre asfalt si linia cerului.
	# Casele stau pe TEREN, la 22..34 m de axa, deci sub linia camerei (5° in
	# sus la 25 m inseamna 12 m — o casa de 7.6 m intra intreaga).
	_orasul_de_jos()
	# Bariere de santier pe umarul interior, in dreptul pasajului rotativ:
	# anunta santierul cu doua curbe inainte, ca in referinta.
	for spec: Array in [[0.762, -1.0], [0.766, -1.0], [0.770, 1.0]]:
		var fr: float = spec[0]
		var st := _at(fr)
		var q := _off(fr, (st[3] as float + 1.2) * spec[1])
		_node("chongqing/props/construction_barrier", "santier",
			Vector3(q.x, (st[0] as Vector3).y, q.z), _yaw_fwd(fr), 1.0, "none")
	# Masinute oprite pe umarul din afara curbei, la etajul de jos: dau scara
	# tablierului de deasupra si spun „e un nod rutier, nu o rampa".
	# Fractiile sunt de pe etajul de JOS al spiralei, unde umarul e chiar teren.
	# Cea de la 0.842 a fost scoasa: acolo drumul e pe pasaj, iar `ground_y` a
	# pus masinuta pe carosabilul etajului 1, la 25 m sub ea — `probe_cq_hall`
	# a prins-o ca obstacol pe banda extrema a etajului de jos.
	for spec: Array in [[0.632, "mini_car_a", 1.0], [0.646, "mini_car_b", 1.0],
			[0.660, "mini_car_a", 1.0]]:
		var fr: float = spec[0]
		var st := _at(fr)
		# 3 m de la buza asfaltului nu ajung: masina parcata are 1.84 m de la
		# origine pana la bot, iar `probe_cq_hall.gd` a prins-o pe cea de la
		# 0.842 in banda extrema. 6 m de la buza, deci coada ei la 4 m de asfalt.
		var q := _off(fr, (st[3] as float + 6.0) * spec[2])
		_node("chongqing/vehicles/" + spec[1], "masinuta",
			Vector3(q.x, _sampler.ground_y(q.x, q.z), q.z),
			_yaw_fwd(fr) + PI, 1.0, "hull")


## O PILA sub pasaj.
##
## [b]Coloanele NU pot sta simetric fata de axa[/b], si asta e masuratoarea care
## a decis toata zona (`tools/probe_cq_bents.gd`): pe spirala, tablierul de sus
## trece EXACT peste cel de jos — decalajul lateral e 1.4..6.2 m intre doua
## benzi de cate 14 m. O pila la 4 m de axa ar cadea fix in carosabilul de
## dedesubt, adica un stalp de beton pe linia de curs a etajului 1.
##
## Deci fiecare pila e o coloana SINGURA, pe partea unde nu e etajul de jos, cu
## capul de pila (grinda in consola) subinteles de tablierul insusi: se cauta
## primul offset lateral care lasa `CLEAR` metri intre coloana si marginea
## benzii de dedesubt, si care ramane sub `MAX_ARM` de axa ca sa se citeasca
## drept pila, nu drept stalp orfan.
const CLEAR: float = 2.5
const MAX_ARM: float = 13.0

## Casele de sub nodul rutier si de pe flancurile spiralei.
##
## [b]Nu sunt umplutura.[/b] Regula frustumului (brief §2.0) spune ca orasul se
## vede DOAR in jos, deci un flanc gol nu e „sobru", e chiar lucrul pe care
## camera il priveste tot POI-ul. Se aseaza numai unde terenul e cu cel putin
## `SUB_MIN` metri sub sosea (altfel casa ar creste in fata masinii, nu sub ea)
## si cu cel mult `SUB_MAX` (mai jos de atat se pierde in ceata).
##
## Coliziunea e „none" fiindca sunt sub cota drumului: un corp solid acolo n-ar
## opri niciodata o masina care merge, dar ar prinde una care cade — iar
## caderea trebuie sa ajunga la `RespawnZone`, nu sa se agate de un acoperis
## (memoria `coliziune-contact-si-platforma`).
const SUB_MIN: float = 5.0
const SUB_MAX: float = 34.0

func _orasul_de_jos() -> void:
	var kinds := ["buildings/shophouse_a", "buildings/shophouse_b",
		"buildings/shophouse_c", "buildings/restaurant_front"]
	var k := 0
	var f := 0.600
	while f < 0.900:
		for spec: Array in [[-1.0, 22.0], [-1.0, 33.0], [1.0, 24.0], [1.0, 35.0]]:
			var off: float = spec[1] * spec[0]
			var q := _off(f, off)
			var g := _sampler.ground_y(q.x, q.z)
			var drop := (_at(f)[0] as Vector3).y - g
			if drop < SUB_MIN or drop > SUB_MAX:
				continue
			if g < _sea + 0.5:
				continue
			# Fatada se uita spre drum; casele nu stau la unison.
			_node("chongqing/" + kinds[k % kinds.size()], "casaF",
				Vector3(q.x, g, q.z),
				_yaw_side(f) + (PI if spec[0] > 0.0 else 0.0) + float(k % 3) * 0.22,
				[1.0, 1.25, 0.85][k % 3], "none")
			k += 1
		f += 17.0 / 2068.3


func _bent(f: float) -> void:
	var st := _at(f)
	var road: Vector3 = st[0]
	var side: Vector3 = st[1]
	var w: float = st[3]
	for off: float in _bent_offsets(f, road, side, w):
		var q := road + side * off
		var g := _sampler.ground_y(q.x, q.z)
		# Sub apa pila pleaca de pe un radier la cota apei, nu de pe fundul
		# lagunei: altfel are 48 m si scara ii intinde inelele in dungi.
		var base := maxf(g, _sea - 1.0)
		var top := road.y - DECK_THICK
		var h := top - base
		if h < 3.0:
			continue
		var segs := maxi(1, int(ceil(h / (PILLAR_H * PILLAR_MAX_SCALE))))
		var seg_h := h / float(segs)
		for k in segs:
			_node("chongqing/structures/pillar_round", "pila",
				Vector3(q.x, base + seg_h * float(k), q.z),
				_yaw_fwd(f), 1.0, "hull", Vector3(1.3, seg_h / PILLAR_H, 1.3))


## Offset-urile laterale libere pentru pilele de la fractia `f`. Una sau doua,
## dupa cat loc lasa etajul de dedesubt.
##
## Nu se compune o singura „banda ocupata" din toate tronsoanele de dedesubt:
## la 0.775 spirala are DOUA tronsoane in raza de 30 m, iar reuniunea lor
## ([-17.7, 13.6]) nu mai lasa nimic sub `MAX_ARM`, desi intre ele exista loc.
## Se pleaca de la offsetul dorit si se cauta in AFARA, din 0.5 in 0.5 m, primul
## punct liber fata de FIECARE tronson in parte.
func _bent_offsets(f: float, road: Vector3, side: Vector3, w: float) -> Array[float]:
	var out: Array[float] = []
	for s: float in [-1.0, 1.0]:
		var o := w * 0.55 * s
		while absf(o) <= MAX_ARM:
			if _lateral_free(road, side, o):
				out.append(o)
				break
			o += 0.5 * s
	return out


## E liber offsetul `o` fata de orice tronson de sub tablier?
func _lateral_free(road: Vector3, side: Vector3, o: float) -> bool:
	var q := road + side * o
	var r := _track.routes[0]
	for j in r.count():
		var b := r.baked[j]
		if absf(b.y - road.y) < 10.0:
			continue
		if Vector2(b.x - q.x, b.z - q.z).length() < _track.width_at_index(j) + CLEAR:
			return false
	return true


# ------------------------------------------------------------ 7) Liziba (G)

## Blocul traversat si scenografia din jurul lui.
##
## [b]GEOMETRIA MODELULUI DECIDE ASEZAREA, nu invers[/b], si trei masuratori au
## fost necesare (`tools/probe_liziba*.gd`, sectiuni prin mesh, nu AABB-uri —
## AABB-ul unui bloc pe piloni spune ca totul e plin):
##
##  1. [b]Parterul e deschis, dar nu pe unde crezi.[/b] 40.6 x 27.2 m in plan,
##     inaltime 24.9. Capetele scurte (x = ±20.3) sunt colonade de 13 stalpi la
##     2.2 m — nu se trece pe acolo. Se trece pe ADANCIME (Z), printr-o gura de
##     11 m in fatada (x -5.5..+5.5).
##  2. [b]Inauntru sunt patru perechi de nuclee de scara[/b] la x = ±2.97..4.00
##     (z ≈ -10, -3.5, +3, +9.5), care string culoarul liber la 5.94 m. Soseaua
##     are 14 m, deci blocul se scaleaza pe X pana cand nucleele ies din
##     gabaritul masinii de pe banda extrema: la 2.7 sunt la ±8.0, cu un metru
##     de joc peste buza asfaltului.
##  3. [b]Gura are un PRAG.[/b] La y = 0 fatada are un sill continuu peste toata
##     deschiderea (~0.25 m). Cu talpa blocului la cota soselei din CENTRU,
##     pragul ajungea la +0.35 m fata de asfalt la intrare — un zid de 60 cm pe
##     toata latimea drumului, prins de `probe_cq_hall.gd` pe toate benzile.
##     De aceea talpa se pune sub cota soselei de la INTRARE, nu de la centru:
##     holul urca 8.7% pe 35 m, iar podeaua modelului e orizontala.
##
## Scara pe X e si motivul pentru care blocul e `mesh`, nu `hull`: hull-ul unei
## piese prin care se TRECE e un bloc plin, adica un zid peste sosea.
const LIZIBA_SCALE_X: float = 2.7
const LIZIBA_SCALE_Y: float = 1.15
const LIZIBA_SCALE_Z: float = 1.3
const LIZIBA_FRAC: float = 0.8855
## Semiadancimea modelului (m). Cu scara pe Z da jumatatea holului.
const LIZIBA_HALF_DEPTH: float = 13.62
## Cat de jos sub asfaltul de la intrare sta talpa blocului (m) — vezi nota 3.
const LIZIBA_SILL_CLEAR: float = 0.35

func _zone_liziba() -> void:
	_zone = "7) Liziba"
	var st := _at(LIZIBA_FRAC)
	var road: Vector3 = st[0]
	# Cota de asezare: cea mai JOASA cota a soselei din hol, minus garda de
	# prag. Se citeste din ruta, la capatul de intrare al blocului.
	var half := LIZIBA_HALF_DEPTH * LIZIBA_SCALE_Z
	var f_in := LIZIBA_FRAC - half / 2068.3
	var f_out := LIZIBA_FRAC + half / 2068.3
	var y_lo: float = minf((_at(f_in)[0] as Vector3).y, (_at(f_out)[0] as Vector3).y)
	_node("chongqing/buildings/liziba_block", "bloc_liziba",
		Vector3(road.x, y_lo - LIZIBA_SILL_CLEAR, road.z), _yaw_fwd(LIZIBA_FRAC),
		1.0, "mesh",
		Vector3(LIZIBA_SCALE_X, LIZIBA_SCALE_Y, LIZIBA_SCALE_Z))
	# Cutii postale si biciclete in hol, LANGA stalpi (la 9 m de axa, adica in
	# afara asfaltului de 7 m dar sub bloc) — decorul care spune „aici locuiesc
	# oameni", fara sa intre pe linia de curs.
	for spec: Array in [[-0.010, 9.4, "mailbox_wall", "35_mailbox", 0.0],
			[0.004, -9.4, "mailbox_wall", "35_mailbox", PI],
			[-0.004, 9.8, "bicycle", "36_bike", 0.0],
			[-0.002, 9.8, "bicycle", "36_bike", 0.4],
			[0.006, -9.8, "bicycle", "36_bike", PI]]:
		var fr: float = LIZIBA_FRAC + spec[0]
		var q := _off(fr, spec[1])
		var d: String = "props/" + spec[2]
		_node("chongqing/" + d, "hol",
			Vector3(q.x, (_at(fr)[0] as Vector3).y, q.z),
			_yaw_side(fr) + spec[4], 1.0, "none")
	# Pasarela de iesire spre piata (brief §2 G: „iesirea pe o pasarela").
	#
	# [b]Nu peste sosea.[/b] Prima versiune o punea perpendicular pe drum, ca sa
	# dea „tavanul scurt" de 2 secunde; `probe_cq_hall.gd` a masurat ce iese:
	# picioarele ei sunt la ±6.7 m de axa (cadre in V, `build_footbridge`), deci
	# o pasarela care traverseaza o sosea de 14 m isi pune stalpii FIX pe benzile
	# extreme — 56 de atingeri, pe ±1.00. Ar fi cerut scara 2.2, adica 53 m de
	# pasarela pentru un drum de 14.
	#
	# Sta deci PARALEL cu drumul, pe umarul dinspre rapa, ca legatura dintre
	# bloc si terasa de dincolo: se vede tot, nu incurca linia de curs, si
	# ramane exact ce spune briefingul — iesirea pietonala din bloc.
	var fp := LIZIBA_FRAC + 0.022
	var pq := _off(fp, 19.0)
	_node("chongqing/structures/footbridge", "pasarela",
		Vector3(pq.x, (_at(fp)[0] as Vector3).y + 1.2, pq.z), _yaw_fwd(fp), 1.0,
		"none")
	# Firma de neon si felinare la gura de intrare — semnalizarea ceruta de
	# brief §8 („intrarea in bloc primeste chevroane/semafoare").
	for spec: Array in [[LIZIBA_FRAC - 0.016, 10.6, "lamp_lantern_c", "42_lampc"],
			[LIZIBA_FRAC + 0.016, -10.6, "lamp_lantern_c", "42_lampc"],
			[LIZIBA_FRAC - 0.018, -10.2, "neon_sign_a", "40_neona"]]:
		var fr: float = spec[0]
		var q := _off(fr, spec[1])
		_node("chongqing/props/" + spec[2], "gura",
			Vector3(q.x, (_at(fr)[0] as Vector3).y, q.z), _yaw_side(fr) + PI,
			1.0, "none")


# ----------------------------------------------------------- 8) fundal (S)

## Siluetele de peste rau. Brief §2.0: turnurile exista DOAR peste rau, la
## 150-250 m, sub `fog_end` 250 — deci se pun pe un arc in jurul golfului,
## masurat de la soseaua de pe chei, nu pe conturul lagunei (aia e treaba lui
## `gen_decor_chongqing._far_towers`, deja lipita).
##
## Al doilea pod (brief §2 S) e `bay_bridge.glb` intins ca silueta peste golf,
## la 190 m de chei: un tronson de 40 m nu ajunge peste un golf, deci se pun
## cinci bucati cap la cap pe aceeasi linie.
## Cat de mult in spatele liniei de mal se infig siluetele.
const SHORE_BACK: float = 22.0

func _zone_fundal() -> void:
	_zone = "8) Fundal"
	# TURNURILE stau pe malul OPUS, si pozitia lor se citeste din tema, nu se
	# tasteaza ca offset fata de sosea.
	#
	# Prima versiune le punea la 140..250 m in dreapta cheiului si le lua cota
	# cu `max(ground_y, apa + 1)`. Opt din opt au iesit peste apa (verificat cu
	# o sonda care compara cota terenului cu linia apei sub fiecare prop): malul
	# de peste golf, declarat in `far_shore`, se opreste la z ~335, iar
	# offsetul de 140-250 m ii ducea pana la z 445. Un obiect care sta pe o
	# geometrie declarata in ALTA PARTE trebuie sa-si ia si pozitia de acolo —
	# aceeasi lectie ca la `gen_decor_chongqing._far_towers`.
	var models := ["buildings/tower_silhouette_b", "buildings/tower_silhouette_c",
		"buildings/tower_silhouette_a"]
	var k := 0
	# Numai malul dinspre golf (a doua linie din `far_shore`) si coada primei:
	# restul e in fata cornisei D, unde siluetele exista deja.
	var banks: Array = _track.theme_flag("far_shore", [])
	for bi in banks.size():
		var bank: Dictionary = banks[bi]
		var line: Array = bank.get("line", [])
		var h := float(bank.get("h", 12.0))
		var depth := float(bank.get("depth", 45.0))
		# Coroana coboara liniar de la `h` la 0.8*h pe `depth`; la SHORE_BACK
		# metri in spate iese cota de mai jos, minus un metru ca sa fie infipta.
		var y := _sea + h - 0.2 * h * (SHORE_BACK / depth) - 1.0
		var c := _track._centroid()
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			# Numai bucata dinspre golf: siluetele de pe Jialing sunt deja puse.
			if maxf(a.x, b.x) < -50.0:
				continue
			var seg := a.distance_to(b)
			var steps := maxi(int(seg / 75.0), 1)
			for m in steps:
				var p := a.lerp(b, (float(m) + 0.5) / float(steps))
				var nrm := Vector2(-(b.y - a.y), b.x - a.x).normalized()
				if nrm.dot(a - Vector2(c.x, c.z)) < 0.0:
					nrm = -nrm
				var q := p + nrm * SHORE_BACK
				_node("chongqing/" + models[k % 3], "siluetaS",
					Vector3(q.x, y, q.y), float(k) * 0.8 + 0.3,
					[1.05, 0.8, 1.2][k % 3], "none")
				k += 1
	# AL DOILEA POD (brief §2 S): silueta unui pod care traverseaza golful, de
	# la coltul cheiului spre malul opus. Un tronson are 40 m, deci se pun cap
	# la cap pana la mal — cota e cea a unui tablier peste apa, nu cea a lui
	# `_sea + 7` din prima versiune, care il lasa in aer peste apa deschisa
	# fiindca nici capetele nu atingeau uscatul.
	var a0 := _off(0.507, 30.0)
	var b0 := Vector3(230.0, _sea, 316.0)
	var dir := (b0 - a0)
	dir.y = 0.0
	var total := dir.length()
	dir = dir.normalized()
	var pieces := int(ceil(total / 40.0))
	for m in pieces:
		var q := a0 + dir * (40.0 * (float(m) + 0.5))
		_node("chongqing/structures/bay_bridge", "podS",
			Vector3(q.x, _sea + 6.0, q.z), atan2(dir.x, dir.z), 1.0, "none")


# ------------------------------------------------------------------ iesirea

func _node(model: String, base: String, pos: Vector3, yaw: float,
		scl: float, coll: String, scl3: Vector3 = Vector3.ZERO) -> void:
	_n += 1
	var s3 := scl3 if scl3 != Vector3.ZERO else Vector3(scl, scl, scl)
	var c := cos(yaw)
	var s := sin(yaw)
	_out.append('[node name="%s%d" parent="DecorManual/%s" instance=ExtResource("%s")]'
		% [base, _n, _zone, RES[model]])
	# [b]Cele noua numere din .tscn sunt baza pe LINII, nu pe coloane.[/b]
	# Masurat, nu presupus (o scena de o linie cu Transform3D(1..9)):
	# `Transform3D(a,b,c, d,e,f, g,h,i)` da X=(a,d,g), Y=(b,e,h), Z=(c,f,i).
	#
	# Cu scara uniforma diferenta e doar semnul rotatiei si nu se vede pe un
	# felinar. Cu scara NEUNIFORMA e o greseala care nu iarta: prima versiune
	# a compus X din (c*sx, .., s*sz) — coloane amestecate — si blocul Liziba a
	# iesit rotit cu ~26° fata de sosea, cu axa drumului trecand fix prin
	# nucleul de scara de la x = -3.8 (masurat de `probe_cq_hall.gd`).
	#
	# Coloanele corecte: X = (cos, 0, -sin) * sx, Y = (0, 1, 0) * sy,
	# Z = (sin, 0, cos) * sz. Scrise pe linii, in ordinea de mai jos.
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c * s3.x, s * s3.z, s3.y, -s * s3.x, c * s3.z, pos.x, pos.y, pos.z])
	_out.append('metadata/coliziune = "%s"' % coll)
	_out.append("")
