extends Node
## Generator de decor MANUAL pentru POI A — PIATA DIN GOREME (Track13,
## frac 0.965-0.045, linia de start la 0.00). Ca la POI B: nu e sonda, e
## unealta care CALCULEAZA transformarile ce se lipesc in Track13.tscn sub
## `DecorManual/ZoneA_PiataGoreme`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorCappA.tscn -- --track=6
##
## Ce decide compozitia, si de ce cifrele sunt astea:
##
## 1. PIATA E LATA, PADUREA E STRAMTA. Masurat (ProbeCappA): half_width e 9.0 m
##    pe tot 0.965-0.040, adica 18 m de drum — cel mai lat loc din pista, si
##    exact asta o face piata. Terenul e plat la 49.3-49.6 m pe +/-24 m, deci
##    piesele stau pe cota lor fara sa se ingroape. Degajarile se masoara de la
##    MUCHIA asfaltului (9 m de ax), nu de la ax.
##
## 2. PRIMUL HORN E LA 6 M DE BANDA, cerinta explicita a briefului §2 A: ca
##    sa-i vezi PALARIA. Verificare cu frustumul (10 + 0.093*d): la 6 m de
##    muchie centrul conului e la 9 + 6 + 2.19 = 17.2 m de ax, deci camera vede
##    pana la 11.6 m — un chimney_a de 11.41 m intra INTREG in cadru. Un
##    chimney_c de 17.45 m la aceeasi distanta si-ar pierde varful, deci
##    conurile inalte stau mai DEPARTE, unde plafonul creste.
##
## 3. UMBRELE. Masurat din lumina scenei (nu dedus din euler — lectia POI B):
##    umbra merge pe XZ catre (0.866, 0.500), iar dot(side, umbra) e POZITIV pe
##    toata piata, deci partea insorita e `-side`. Piesele inalte care trebuie
##    sa taie piata cu umbra stau pe -side.
##
## 3b. PIATA INCEPE LA 0.993, NU LA 0.965 — si asta a fost o masuratoare, nu o
##    preferinta. Prima runda a intins decorul de la 0.965; generatorul a
##    raportat „teren cu 37,88 m sub sosea" pe TOATE piesele de dinainte de
##    0.99. Cauza: pana acolo drumul e inca IESIREA din stanca goala (POI G),
##    care traverseaza pe DEASUPRA hornului scobit — `TerrainHollow` tine
##    podeaua la 11 m, iar soseaua e la 48-49 m. Terenul de sub ea nu e platou,
##    e GOL. O casa asezata pe `ground_y` acolo ar fi stat pe podeaua cavernei,
##    la 37 m sub drum: invizibila din masina si absurda de sus.
##    Masurat pe iesirea din gol: la 0.9900 terenul e inca la 32.5 m pe -side,
##    la 0.9950 e 49.2 m pe toata latimea. Deci piata incepe la 0.993.
##
## 4. CARUTA CU OALE, si de ce fanta e de 4 m. Brief §2 A: decor static cu
##    coliziune, o fanta de 4 m pe langa ea. Caruta masoara 4.96 x 2.26 m, deci
##    lunga pe X local. Se aseaza cu X local PE LATERALA benzii (yaw = atan2 pe
##    side), adica de-a curmezisul drumului, ca sa blocheze pe latime — altfel
##    ar sta paralel cu banda si n-ar bloca nimic.
##
##    Aritmetica fantei, pe drumul de 18 m: blocajul incepe pe muchia din
##    stanga (-9.0) si se opreste la `half - 4.0` = +5.0, deci golul liber e
##    +5.0 .. +9.0 = exact 4 m, pe partea dinspre exteriorul curbei care
##    urmeaza. Decizia pentru jucator e „strange-te pe dreapta".
##
## 5. CE NU TRAPEAZA O MASINA. Caruta si oalele au coliziune (`hull`), deci un
##    contact la viteza trebuie sa te RESPINGA, nu sa te agate. De aceea toate
##    piesele blocajului stau pe o SINGURA linie perpendiculara pe banda:
##    obstacolul e convex si continuu, iar masina care il atinge aluneca de-a
##    lungul lui spre fanta. Un U cu deschiderea spre drum ar fi fost un
##    buzunar din care nu iesi (lectia `coliziune-contact-si-platforma`).

const TRACK := "res://scenes/tracks/Track13.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track13.tscn.
const RES := {
	"buildings/cave_house_a": "18_house_a",
	"buildings/cave_house_b": "19_house_b",
	"buildings/cave_house_c": "30_house_c",
	"buildings/dovecote": "17_dovecote",
	"props/carpet_terrace": "31_carpet",
	"props/pottery_cart": "32_cart",
	"props/pot_stack": "33_pots",
	"plants/poplar_a": "34_poplar_a",
	"plants/poplar_b": "35_poplar_b",
	"plants/shrub_dry": "22_shrub",
	"plants/pigeon": "21_pigeon",
	"rocks/chimney_a": "10_ch_a",
	"rocks/chimney_b": "11_ch_b",
	"rocks/chimney_c": "12_ch_c",
	"rocks/chimney_d": "13_ch_d",
	"rocks/chimney_mushroom": "14_ch_mush",
}

## Raza la baza, din AABB-ul masurat de ProbeCappA (jumatate din latura mare).
const BASE_R := {
	"buildings/cave_house_a": 3.15, "buildings/cave_house_b": 3.96,
	"buildings/cave_house_c": 4.04, "buildings/dovecote": 2.34,
	"props/carpet_terrace": 3.00, "props/pottery_cart": 2.48,
	"props/pot_stack": 0.74, "plants/poplar_a": 1.00,
	"plants/poplar_b": 1.24, "plants/shrub_dry": 0.52, "plants/pigeon": 0.24,
	"rocks/chimney_a": 2.19, "rocks/chimney_b": 2.03, "rocks/chimney_c": 2.70,
	"rocks/chimney_d": 2.43, "rocks/chimney_mushroom": 2.04,
}

## Lungimea carutei pe X local (masurata, ProbeCappA).
const CART_LEN: float = 4.96
## Latimea unui teanc de oale pe X local (masurata).
const POT_W: float = 1.49

## Fractia unde sta caruta: dupa linia de start, la iesirea din piata, unde
## banda inca e lata (9.0 m) dar drumul deja s-a indreptat.
const CART_FRAC: float = 0.0300

## Cat gol trebuie sa ramana langa caruta, dupa brief §2 A.
const GAP_TARGET: float = 4.0

var _track: Track
var _sampler: TrackSideSampler
var _out: Array[String] = []
var _n := 0
var _rng := RandomNumberGenerator.new()
var _warn := 0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_rng.seed = 100301
	_houses()
	_terrace_and_life()
	_chimneys()
	_cart()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese, %d avertismente de degajare" % [_n, _warn])
	get_tree().quit(0)


# ------------------------------------------------------------------ compozitia

## Cele TREI case-con din brief §2 A: conuri locuite cu usi, ferestre si un
## balcon. Sunt piesa principala a piatei, deci stau APROAPE (4-6 m de muchie)
## si cu fatada spre drum — usile si ferestrele sapate sunt tot ce desparte
## „sat sapat in tuf" de „camp de conuri".
##
## Doua pe partea insorita (-side), ca soarele razant sa le sape fatada in
## relief, si una pe partea opusa ca piata sa aiba doua maluri, nu un decor
## pe o singura parte.
##
## Verificare de frustum: casa_b are 13.45 m si sta la 4.5 m de muchie, adica
## centrul la ~17.5 m de ax -> plafonul e 10 + 0.093*17.5 = 11.6 m. Deci varful
## casei iese din cadru cand esti langa ea — corect si dorit: la o casa de
## langa drum vezi USA si BALCONUL, nu acoperisul. Ce trebuie sa incapa intreg
## e HORNUL de la 6 m (nota 2 din antet), si ala e chimney_a.
func _houses() -> void:
	# DEGAJAREA E O FEREASTRA, NU UN MINIM. Doua runde au ratat-o pe rand:
	#   - la 4.5 m de muchie casele stau la 17.5 m de AX (piata are 18 m
	#     latime!) si captura de la 0.02 iesea fara sat, doar geologie;
	#   - la 1.5 m, captura de la 0.00 iesea cu o fatada maro peste jumatate
	#     de cadru: camera de urmarire zboara la 12.5 m IN SPATELE masinii, deci
	#     o casa langa frac 0.999 e exact acolo unde sta camera la pornire.
	# Fereastra care tine amandoua: 3-4 m de muchie (12-13 m de ax pentru o
	# casa de 4 m raza), si NIMIC sub 3 m pe ultimele doua sutimi dinaintea
	# liniei, unde e camera.
	_place("buildings/cave_house_b", "casaCon", 0.9945, -1.0, 3.5,
		0.0, 1.0, "hull", "toward")
	_place("buildings/cave_house_a", "casaCon", 0.0090, -1.0, 3.0,
		0.0, 1.0, "hull", "toward")
	# A treia pe malul opus, dupa linie, ca sa inchida piata fara sa intre in
	# cadrul de pornire.
	_place("buildings/cave_house_c", "casaCon", 0.0055, 1.0, 3.2,
		0.0, 1.0, "hull", "toward")
	# Un al doilea rand, mai departe si mai rar: satul trebuie sa aiba
	# ADANCIME. In referinta v3 casele urca in trepte in spatele piatei; un
	# singur rand ar citi ca fatada de teatru.
	_place("buildings/cave_house_a", "casaSpate", 0.0250, -1.0, 12.0,
		0.5, 1.05, "hull", "toward")
	_place("buildings/cave_house_c", "casaSpate", 0.0180, -1.0, 14.0,
		-0.4, 0.95, "hull", "toward")
	_place("buildings/cave_house_b", "casaSpate", 0.0115, 1.0, 13.0,
		0.3, 0.95, "hull", "toward")
	# Inca doua case spre iesire, ca satul sa continue pana la caruta in loc
	# sa se termine la jumatatea piatei.
	_place("buildings/cave_house_a", "casaCon", 0.0210, 1.0, 3.4,
		0.0, 0.95, "hull", "toward")
	_place("buildings/cave_house_c", "casaCon", 0.0150, -1.0, 3.6,
		0.0, 0.9, "hull", "toward")


## Terasa cu covoare, porumbarul, plopul si viata marunta.
##
## Terasa e PLATA (0.99 m inalta): daca sta departe nu se vede deloc de la
## nivelul soferului, deci sta la 2.5 m de muchie, chiar langa banda, pe
## partea umbrita — covoarele sunt singura pata SATURATA din piata (KERB_RED)
## si trebuie sa cada in cadru, nu in fundal.
func _terrace_and_life() -> void:
	_place("props/carpet_terrace", "terasaCovoare", 0.0030, 1.0, 1.5,
		0.0, 1.0, "hull", "toward")
	# Porumbarul VOPSIT IN ALB, cu gauri de porumbei (brief §2 A). Sta pe
	# partea umbrita, langa terasa, ca varul sa citeasca pe fundalul de tuf.
	_place("buildings/dovecote", "porumbar", 0.0125, 1.0, 2.5,
		0.0, 1.0, "hull", "toward")
	# Porumbei in evantai deasupra porumbarului: decor fantoma, zero gameplay.
	for j in 6:
		_place("plants/pigeon", "porumbel", 0.0125 + 0.0012 * float(j),
			1.0, 2.0 + 1.6 * float(j % 3), float(j) * 1.1 + 0.3, 1.0,
			"none", "", 7.4 + 1.2 * float(j % 4))
	# UN plop (brief §2 A: „one poplar tree"). Cel inalt, pe partea umbrita,
	# langa terasa: verticala lui subtire e singurul accent care rupe conurile,
	# si verdele e a doua pata de culoare din piata.
	_place("plants/poplar_b", "plop", 0.0072, 1.0, 1.5, 0.0, 1.0, "trunk")
	# Inca doi plopi in spate, ca sa nu para plantat singur (in referinta
	# plopii vin in palcuri langa case).
	_place("plants/poplar_a", "plopSpate", 0.0098, 1.0, 6.0, 0.0, 0.95, "trunk")
	_place("plants/poplar_a", "plopSpate", 0.0165, 1.0, 7.0, 0.0, 1.05, "trunk")
	# Tufe uscate la piciorul pieselor: rup linia de contact dintre piatra si
	# pamant, care altfel e o taietura curata si citeste ca decupaj (lectia POI B).
	for j in 18:
		var f := 0.9940 + 0.0028 * float(j)
		if f > 1.0:
			f -= 1.0
		var sgn := -1.0 if j % 2 == 0 else 1.0
		_place("plants/shrub_dry", "tufa", f, sgn,
			_rng.randf_range(0.8, 4.5), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.9, 1.5), "none")


## Hornurile care inconjoara piata — SATUL, nu trei conuri pe un camp.
##
## Prima runda a pus 12 conuri la 7-30 m de muchie si captura de la 0.02 a
## iesit un drum de desert cu trei cosuri de fabrica pe orizont. Referinta v3
## (`img/v3_crops/A_village.png`) are conurile LIPITE: umplu cadrul de la
## marginea benzii pana in ceata, in trei-patru straturi care se suprapun, si
## nu se vede pamant gol intre ele. Diferenta nu e de stil, e de NUMAR.
##
## Compozitia de acum, pe straturi, cu pasul injumatatit (0.0021 ~ 4.3 m):
##   - inelul 1 (2-6 m de muchie): conuri MICI si medii, pe ambele parti, la
##     fiecare pas. Astea sunt cele care trec pe langa geam.
##   - inelul 2 (8-18 m): conuri medii si inalte, la doi pasi.
##   - inelul 3 (20-45 m): conurile inalte, care inchid fundalul si dau
##     silueta satului. Acolo plafonul frustumului e 10 + 0.093*50 = 14.7 m,
##     deci un chimney_c de 17.45 m isi pierde doar varful — corect pentru
##     fundal, unde silueta conteaza mai mult decat palaria.
##
## PRIMUL HORN ramane cerinta explicita a briefului §2 A: la 6 m de banda,
## chimney_a (11.41 m), fiindca la distanta aia plafonul e 11.6 m si palaria
## se vede INTREAGA — care e tot rostul cerintei.
func _chimneys() -> void:
	_place("rocks/chimney_a", "hornulDeSase", 0.0060, -1.0, 6.0,
		0.6, 1.0, "hull")
	var small: Array[String] = [
		"rocks/chimney_a", "rocks/chimney_mushroom", "rocks/chimney_d",
		"rocks/chimney_mushroom", "rocks/chimney_a",
	]
	var mid: Array[String] = [
		"rocks/chimney_d", "rocks/chimney_b", "rocks/chimney_a",
		"rocks/chimney_mushroom",
	]
	var tall: Array[String] = [
		"rocks/chimney_c", "rocks/chimney_b", "rocks/chimney_c", "rocks/chimney_d",
	]
	var k := 0
	var f := 0.9915
	while f < 1.0465:
		var fw := f if f < 1.0 else f - 1.0
		var near_cart := absf(fw - CART_FRAC) < 0.0055
		# Culoarul camerei: ea zboara 12.5 m IN SPATELE masinii, deci la
		# pornire sta pe frac ~0.994. Inelul 1 (2-6 m de muchie) se opreste
		# acolo, altfel prima imagine a cursei e o piatra peste jumatate de
		# cadru — masurat, exact asta s-a intamplat cu o casa la 1.8 m.
		var on_line := fw > 0.9900 or fw < 0.0030
		f += 0.0021
		k += 1
		# Pe linia de start si langa caruta ramane liber INELUL 1: acolo trebuie
		# sa se vada grila si blocajul, nu piatra. Inelele 2 si 3 continua —
		# altfel satul se rupe in doua exact in cadrul de pornire.
		if not (near_cart or on_line):
			var sgn := -1.0 if k % 2 == 0 else 1.0
			_place(small[k % small.size()], "hornAproape", fw, sgn,
				2.0 + _rng.randf_range(0.0, 4.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.88, 1.08), "hull")
		if k % 2 == 0:
			_place(mid[(k / 2) % mid.size()], "hornMijloc", fw,
				1.0 if k % 4 == 0 else -1.0,
				8.0 + _rng.randf_range(0.0, 10.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.92, 1.12), "hull")
		# Fundalul primeste doua conuri pe pas, pe ambele parti: silueta satului
		# trebuie sa fie CONTINUA pe orizont, nu punctata.
		_place(tall[k % tall.size()], "hornFund", fw, -1.0,
			20.0 + _rng.randf_range(0.0, 25.0), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.95, 1.20), "hull")
		if k % 2 == 1:
			_place(tall[(k + 2) % tall.size()], "hornFund", fw, 1.0,
				20.0 + _rng.randf_range(0.0, 25.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.95, 1.20), "hull")


## CARUTA CU OALE la iesirea din piata, cu fanta de 4 m.
##
## Blocajul se construieste ca o linie CONTINUA perpendiculara pe banda, de la
## muchia din stanga (-half) pana la `half - GAP_TARGET`: caruta intai, apoi
## teancuri de oale cap la cap pana se umple lungimea. Golul ramas e exact
## GAP_TARGET, pe partea dreapta.
func _cart() -> void:
	var n := _track.baked.size()
	var i := int(CART_FRAC * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var g := _sampler.ground_y(p.x, p.z)
	# Caruta e lunga pe X local, deci X local trebuie sa fie LATERALA benzii.
	var yaw := atan2(s.x, s.z)
	var left := -half
	var right := half - GAP_TARGET
	print("; caruta la frac %.4f: ax=(%.2f, %.2f) sosea_y=%.2f teren_y=%.2f half_w=%.2f" % [
		CART_FRAC, p.x, p.z, p.y, g, half])
	print(";   blocaj de la %+.2f la %+.2f m fata de ax, fanta %.2f m in dreapta" % [
		left, right, half - right])
	_at(i, left + 0.5 * CART_LEN, "props/pottery_cart", "carutaCuOale", yaw, 1.0, 0.0)
	# Teancurile de oale continua linia pana la `right`, fara sa lase gauri.
	var x := left + CART_LEN
	var j := 0
	while x < right - 0.2:
		var c := x + 0.5 * POT_W
		# Se decaleaza pe LUNGUL benzii alternativ, ca sa nu fie un sir de
		# robot. Decalajul e mic (0.5 m) si de ambele parti, deci blocajul
		# ramane convex — nu se formeaza niciun buzunar.
		var along := 0.5 if j % 2 == 0 else -0.4
		_at(i, c, "props/pot_stack", "teancOale", yaw + 0.35 * float(j % 3), 1.0, along)
		x += POT_W
		j += 1
	print(";   %d teancuri de oale langa caruta, blocaj continuu pe %.2f m" % [
		j, right - left])


# ------------------------------------------------------------------ asezarea

## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## asfaltului (nu de ax — muchia e ce vede jucatorul). Cota vine din teren.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull",
		face: String = "", lift: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6)
	var d := half + gap + r
	var q := p + s * d
	var g := _sampler.ground_y(q.x, q.z)
	# Garda: piatra n-are voie sa intre in carosabil. Se masoara distanta de la
	# ax pana la MARGINEA piesei, nu pana la centru — capcana din
	# `decor-manual-coliziune`.
	if d - r < half + 0.5:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	if lift == 0.0 and p.y - g > 1.2:
		print("; nota %s la frac %.4f: teren cu %.2f m sub sosea" % [model, frac, p.y - g])
	var a := yaw
	if face == "toward":
		a = atan2(-s.x, -s.z)
	_raw(model, base, Vector3(q.x, g + lift, q.z), a, scl, mode, false)


## Aseaza o piesa la un OFFSET LATERAL dat fata de ax (pentru blocajul carutei,
## unde pozitia se calculeaza pe latimea benzii, nu ca degajare fata de muchie).
func _at(idx: int, lateral: float, model: String, base: String, yaw: float,
		scl: float, along: float) -> void:
	var n := _track.baked.size()
	var p := _track.baked[idx]
	var s := _track._side_at(idx)
	var dir := (_track.baked[(idx + 1) % n] - p).normalized()
	var q := p + s * lateral + dir * along
	var g := _sampler.ground_y(q.x, q.z)
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, "hull", false)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, blocker: bool) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="DecorManual/ZoneA_PiataGoreme" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	if blocker:
		_out.append("metadata/camera_blocker = true")
	_out.append("")
