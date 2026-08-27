extends Node
## Generator de decor MANUAL pentru Chongqing, POI A-D (Track12).
##
## Acelasi rost ca `gen_decor_chongqing.gd` (malul) si `gen_decor_baikal.gd`:
## NU verifica nimic, CALCULEAZA transformarile care se lipesc apoi in
## Track12.tscn sub `DecorManual`, in patru sectiuni. Fiecare grup de aici e o
## decizie de compozitie, dar cotele si lateralele vin din lumea reala
## (`sampler.ground_y`, buza falezei masurata), nu din ochi.
##
## Rulare (ca SCENA — pista cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorChongqingAD.tscn
##
## REGULA CARE DECIDE TOT (brief §2.0): camera vede ~5° peste orizontala si
## ~63° SUB ea, deci la distanta orizontala `d` vezi in sus cel mult
## `10 + 0.093*d` metri. Consecinta practica, respectata de fiecare grup de
## mai jos: langa carosabil nu se pune nimic mai inalt de 4 etaje (fatadele
## sunt pereti de coridor), iar tot ce e impresionant sta SUB drum.

const TRACK := "res://scenes/tracks/Track12.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track12.tscn. Primele
## cinci exista deja (le-a adus scenografia de mal); restul se adauga.
const RES := {
	"chongqing/props/lamp_lantern_a": "21_lamp",
	"chongqing/structures/hongya_dong": "23_hongya",
	"chongqing/buildings/kuixinglou_pavilion": "30_pavilion",
	"chongqing/props/cliff_railing": "31_railing",
	"chongqing/vehicles/bus": "32_bus",
	"chongqing/vehicles/mini_car_a": "33_cara",
	"chongqing/vehicles/mini_car_b": "34_carb",
	"chongqing/vehicles/mini_car_c": "35_carc",
	"chongqing/structures/stone_stairway": "36_stairs",
	"chongqing/buildings/shophouse_a": "37_shopa",
	"chongqing/buildings/shophouse_b": "38_shopb",
	"chongqing/buildings/shophouse_c": "39_shopc",
	"chongqing/props/laundry_line": "40_laundry",
	"chongqing/props/porter": "41_porter",
	"chongqing/buildings/restaurant_front": "42_restaurant",
	"chongqing/props/table_stools": "43_tables",
	"chongqing/props/steam_vent": "44_steam",
	"chongqing/props/scooter": "45_scooter",
	"chongqing/props/lamp_lantern_b": "46_lampb",
	"chongqing/props/lamp_lantern_c": "47_lampc",
	"chongqing/props/neon_sign_a": "48_neona",
	"chongqing/props/chevron_post": "49_chevron",
	"chongqing/props/bollard": "50_bollard",
}

## Latimea gabaritului de masina, ca sa nu se calculeze fanta din ochi:
## `tools/tmp/probe_fanta.gd` plimba exact cutia asta prin nodul de trafic.
const CAR_W := 2.4

## Cat de sus fata de buza cornisei incepe Hongya Dong (brief §8: adancimea se
## citeste prin PROXIMITATE — daca hero-ul incepe la cota drumului nu mai e
## „sub tine", si daca incepe prea jos intra in ceata).
const HONGYA_DROP := 5.0

var _track: Track
var _sampler: TrackSideSampler
var _path
var _out: Array[String] = []
var _n := 0
var _section := ""


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_path = TrackScenography._Path.new(_sampler)
	print("; total=%.1f  half_width=%.2f" % [_path.total, _sampler.half_width()])
	_emit_all()
	print("")
	for line in _out:
		print(line)
	get_tree().quit(0)


# ------------------------------------------------------------------ compozitia

func _emit_all() -> void:
	_poi_a_piata()
	_poi_b_shibati()
	_poi_c_alee()
	_poi_d_cornisa()
	print("; asezate %d piese" % _n)


## --- A: piata Kuixinglou (frac 0.00-0.04) ---------------------------------
##
## Referinta (bar/A_piata.png): pavilionul-pagoda pe buza platoului, un sir de
## stalpi cu lampioane de-a lungul unui parapet de piatra, si — la iesire —
## coada de trafic. Platoul e plat la 65 m pe 40 m in ambele parti (masurat),
## deci aici nu terenul face compozitia, ci obiectele.
func _poi_a_piata() -> void:
	_open_section("1) Piata Kuixinglou")

	# Pavilionul: 9.9 x 7.3 m. Sta pe stanga, la 15 m de ax — destul cat sa nu
	# fie perete de coridor, destul cat sa intre in cadru la plecare. Rotit cu
	# fata spre drum.
	var st := _at(0.012)
	_place("chongqing/buildings/kuixinglou_pavilion", "pavilion",
		_off(st, -1.0, 15.0), _yaw_to_road(st, -1.0), 1.0)

	# Parapetul de pe buza care da spre gol. Pe DREAPTA la iesirea din piata,
	# fiindca acolo platoul se termina — prima privire in jos a turului.
	# cliff_railing e o piesa de 4.38 m; se insiruie cu 4.3 m pas, ca sa se
	# atinga fara sa se intrepatrunda.
	var f := 0.004
	while f < 0.037:
		var s2 := _at(f)
		_place("chongqing/props/cliff_railing", "parapet",
			_off(s2, 1.0, 8.5), _yaw_across(s2), 1.0)
		f += 4.3 / _path.total

	# Stalpii cu lampioane: pe amandoua partile, alternand, la 22 m pas. In
	# referinta ei sunt ritmul pietei — sirul regulat de lumini calde care
	# spune cat de lunga e.
	var g := 0.003
	var side := 1.0
	while g < 0.040:
		var s3 := _at(g)
		_place("chongqing/props/lamp_lantern_a", "felinar_piata",
			_off(s3, side, 10.5), _yaw_to_road(s3, side), 1.0)
		side = -side
		g += 22.0 / _path.total

	_traffic_node()


## NODUL DE TRAFIC (brief §2 A si §3): bulevardul blocat de autobuze si
## masinute, cu O SINGURA fanta trecabila.
##
## Geometria e aleasa ca sa lase fanta pe o BANDA CONTINUA, nu ca sa arate bine
## de sus: latimea utila e 9 m (custom_width_segments da 9.0 pana la 0.053),
## deci +-9 m fata de ax cu tot cu acostament. Autobuzul are 2.68 m latime si
## 10.64 m lungime.
##
## Fanta o las intre autobuzul de pe banda stanga si cel de pe banda dreapta,
## centrata usor spre stanga (lat -0.6), ca sa nu fie exact pe linia de curs —
## trebuie sa ceara o corectie, nu doar sa fie nimerita din inertie.
## Latimea REALA se masoara cu tools/tmp/probe_fanta.gd, nu se socoteste aici.
func _traffic_node() -> void:
	var f := 0.0315
	var st := _at(f)

	# Cele doua autobuze care fac fanta.
	#
	# Offsetul NU se citeste pe latimea autobuzului (2.68 m). Un autobuz de
	# 10.64 m lungime, rotit cu unghiul `a`, mananca lateral
	# `(W*cos a + L*sin a) / 2`: la 7° aia e 1.98 m, adica se umfla cu 64 cm
	# peste jumatatea lui de caroserie. Prima incercare, cu centrele la 4.4 si
	# 4.6 m si 6-7° de oblic, a masurat 0.10 m de fanta — practic un zid.
	#
	# Deci: oblicul scade la 3° (tot se citeste „s-au oprit unde au apucat",
	# dar mananca doar 1.62 m) si centrele se duc la 4.2 m de o parte si de
	# alta a fantei. Ce ramane liber se MASOARA cu tools/tmp/probe_fanta.gd,
	# nu se socoteste aici: gabaritul are si 4 m lungime, deci trece prin
	# blocaj pe o banda, nu printr-un punct.
	_place("chongqing/vehicles/bus", "autobuz_stanga",
		_off(st, -1.0, 5.4), _yaw_drive(st) + deg_to_rad(3.0), 1.0)
	_place("chongqing/vehicles/bus", "autobuz_dreapta",
		_off(st, 1.0, 5.4), _yaw_drive(st) - deg_to_rad(3.0), 1.0)

	# Coada din spatele lor: masinute pe doua randuri, esalonate. Adancimea
	# blocajului conteaza — un singur rand se trece prin bumping, trei randuri
	# spun „pe aici nu se poate decat prin fanta".
	var rows := [
		Vector3(-6.4, 0.0072, 4.0), Vector3(6.6, 0.0072, -3.0),
		Vector3(-6.2, 0.0104, -5.0), Vector3(7.0, 0.0104, 6.0),
		Vector3(-6.8, 0.0136, 2.0), Vector3(6.4, 0.0136, -4.0),
	]
	var models := [
		"chongqing/vehicles/mini_car_a", "chongqing/vehicles/mini_car_b",
		"chongqing/vehicles/mini_car_c",
	]
	var i := 0
	for r: Vector3 in rows:
		var s2 := _at(r.y)
		var lat: float = r.x
		_place(models[i % 3], "masina_blocaj",
			_off(s2, signf(lat), absf(lat)),
			_yaw_drive(s2) + deg_to_rad(r.z), 1.0)
		i += 1

	# Bolarzi pe trotuar, ca blocajul sa aiba margine: fara ei masinutele par
	# aruncate pe un camp, nu oprite pe un bulevard.
	for lat: float in [-8.2, 8.2]:
		var j := 0
		while j < 3:
			var s3 := _at(f - 0.004 + float(j) * 0.003)
			_place("chongqing/props/bollard", "bolard",
				_off(s3, signf(lat), absf(lat)), 0.0, 1.0)
			j += 1


## --- B: coborarea Shibati (frac 0.04-0.14) --------------------------------
##
## Referinta (bar/B_scari.png): scara de piatra taie panta pe langa drum, iar
## de-a lungul ei case vechi cu obloane, rufe intinse, oameni marunti.
##
## Terenul (masurat): pe latura -1 pamantul cade de la 25-40 m offset — 62.3 la
## 25 m, 61.7 la 40 m pe f=0.07, si tot mai mult mai jos. Aia e panta pe care
## sta scara. Piesele se aseaza pe `ground_y` real, nu pe cota drumului.
func _poi_b_shibati() -> void:
	_open_section("2) Coborarea Shibati")

	# SCARA. stone_stairway e 10.4 x 7.7 x 12.6 m: o bucata de scara, nu o
	# scara intreaga. Se insiruie in jos pe panta, fiecare pe cota terenului
	# ei, ca sa citeasca drept o singura fuga de trepte care coboara.
	var f := 0.058
	var lat := 17.0
	while f < 0.104:
		var st := _at(f)
		var p := _off_ground(st, -1.0, lat)
		_place("chongqing/structures/stone_stairway", "scara",
			p, _yaw_to_road(st, -1.0), 1.0)
		f += 10.5 / _path.total
		lat += 1.6

	# Casele de pe marginea scarii. Pe latura scarii, in doua siruri: unul
	# aproape de drum (peretele de coridor, 7.6 m inaltime = sub plafonul
	# camerei la 12 m distanta) si unul mai jos pe panta, care se vede PESTE
	# primul fiindca terenul coboara.
	var shops := [
		"chongqing/buildings/shophouse_a", "chongqing/buildings/shophouse_b",
		"chongqing/buildings/shophouse_c",
	]
	var g := 0.052
	var k := 0
	while g < 0.108:
		var st2 := _at(g)
		# sirul de langa drum
		_place(shops[k % 3], "pravalie",
			_off_ground(st2, -1.0, 11.5), _yaw_to_road(st2, -1.0), 1.0)
		# sirul de jos, decalat, mai departe
		if k % 2 == 0:
			_place(shops[(k + 1) % 3], "pravalie_jos",
				_off_ground(st2, -1.0, 27.0),
				_yaw_to_road(st2, -1.0) + 0.22, 1.0)
		g += 9.0 / _path.total
		k += 1

	# Rufele pe sarma: intre case, la inaltime de etaj. Sunt „mesh" la
	# coliziune, dar aici oricum stau la 11 m lateral, deci departe de linia
	# de curs. In referinta ele sunt ce spune „aici locuieste cineva".
	var h := 0.056
	while h < 0.104:
		var st3 := _at(h)
		var p3 := _off_ground(st3, -1.0, 14.0)
		p3.y += 3.4
		_place("chongqing/props/laundry_line", "rufe", p3,
			_yaw_across(st3), 1.0)
		h += 13.0 / _path.total

	# HAMALII. Figuranti SUB linia camerei — brief §2 B: „pietonii sunt
	# figuranti SUB linia camerei — exact unde vede". Stau pe scara si pe
	# palierele ei, nu pe carosabil.
	var porters := [
		Vector2(0.060, 19.0), Vector2(0.068, 22.5), Vector2(0.074, 20.0),
		Vector2(0.082, 25.0), Vector2(0.090, 23.0), Vector2(0.098, 27.0),
	]
	var m := 0
	for pp: Vector2 in porters:
		var st4 := _at(pp.x)
		_place("chongqing/props/porter", "hamal",
			_off_ground(st4, -1.0, pp.y),
			_yaw_across(st4) + deg_to_rad(float(m) * 47.0), 1.0)
		m += 1

	# Lampioanele scarii: sirul de lumini care face scara citibila noaptea.
	var q := 0.056
	while q < 0.106:
		var st5 := _at(q)
		_place("chongqing/props/lamp_lantern_c", "felinar_scara",
			_off_ground(st5, -1.0, 15.5), _yaw_to_road(st5, -1.0), 1.0)
		q += 11.0 / _path.total


## --- C: aleea hot-pot (frac 0.16-0.24) ------------------------------------
##
## Brief §2 C: coridor strans de 6 m intre restaurante. Carosabilul se
## stramteaza singur (custom_width_segments: 6.0 intre 0.18 si 0.209), deci
## treaba decorului e sa faca PERETII. restaurant_front e 9.2 x 4.7 m — jos si
## lat, exact ce cere frustumul: la 9 m lateral vezi 10.8 m inaltime, iar
## piesa are 4.7.
func _poi_c_alee() -> void:
	_open_section("3) Aleea hot-pot")

	# Peretii de restaurante, de o parte si de alta, decalati intre ei ca sa
	# nu iasa un tunel simetric.
	var f := 0.170
	var side := 1.0
	while f < 0.238:
		var st := _at(f)
		_place("chongqing/buildings/restaurant_front", "restaurant",
			_off_ground(st, side, 8.2), _yaw_to_road(st, side), 1.0)
		side = -side
		f += 5.6 / _path.total

	# Mesele cu scaunele pe trotuar. „none" la coliziune: in aleea de 6 m ele
	# stau la o roata de linia de curs, iar o masa care opreste o masina de
	# cursa e un bug, nu un decor.
	var g := 0.172
	var gs := -1.0
	while g < 0.236:
		var st2 := _at(g)
		_place("chongqing/props/table_stools", "mese",
			_off_ground(st2, gs, 5.6), _yaw_to_road(st2, gs) + 0.3, 1.0)
		gs = -gs
		g += 7.4 / _path.total

	# Aburii din bucatarii. steam_vent e piesa care ii emite; particulele sunt
	# treaba hazardului, aici e doar gura de ventilatie de pe perete.
	var h := 0.176
	var hs := 1.0
	while h < 0.234:
		var st3 := _at(h)
		_place("chongqing/props/steam_vent", "gura_abur",
			_off_ground(st3, hs, 5.2), _yaw_to_road(st3, hs), 1.0)
		hs = -hs
		h += 12.0 / _path.total

	# Lampioanele aleii: sirul de rosu de deasupra, semnatura locului.
	var q := 0.171
	var qs := 1.0
	while q < 0.237:
		var st4 := _at(q)
		_place("chongqing/props/lamp_lantern_b", "felinar_alee",
			_off_ground(st4, qs, 6.4), _yaw_to_road(st4, qs), 1.0)
		qs = -qs
		q += 6.2 / _path.total

	# Scuterul parcat (brief §2 C il cere pe nume) si UN neon roz.
	var st5 := _at(0.196)
	_place("chongqing/props/scooter", "scuter",
		_off_ground(st5, -1.0, 5.4), _yaw_drive(st5) + deg_to_rad(80.0), 1.0)

	# NEONUL. Unul singur, pe toata pista: slotul 31 e ultimul liber si briefingul
	# §4 il vrea „accent, sub 1% din pixeli". Unul se vede; zece devin identitate,
	# si identitatea pistei nu e cyberpunk (§0.1).
	var st6 := _at(0.204)
	_place("chongqing/props/neon_sign_a", "neon_roz",
		_off_ground(st6, 1.0, 6.0), _yaw_to_road(st6, 1.0), 1.0)


## --- D: cornisa Hongya Dong (frac 0.26-0.44) ------------------------------
##
## VARFUL EMOTIONAL AL TURULUI, si singurul POI unde decorul e un HERO, nu un
## kit. Masurat pe teren: buza falezei e la 8.0-8.5 m de ax pe latura +1, iar
## terasa de dedesubt e la 5.7 m — o cadere de ~27 m.
##
## hongya_dong.glb e 42 x 47.7 x 17.7 m, cu originea pe talpa si centrata in
## X/Z. Ca sa se citeasca „agatat de faleza SUB cornisa", coama lui trebuie sa
## ajunga la ~5 m sub buza (HONGYA_DROP): asta pune talpa la
## `buza - 5 - inaltime`, iar corpul lipit de peretele de stanca.
##
## De ce trei bucati si nu una: referinta (bar/D_cornisa.png) nu e o cladire,
## e un MASIV care umple cadrul cat tine virajul. O singura instanta ar fi un
## obiect pe langa care treci; trei, lipite si decalate pe verticala, sunt un
## cartier pe care il ai sub tine tot lungul cornisei.
func _poi_d_cornisa() -> void:
	_open_section("4) Cornisa Hongya Dong")

	var hongya_h := 47.74
	var spots := [
		Vector2(0.272, 0.0), Vector2(0.296, -3.5), Vector2(0.320, -7.0),
	]
	for sp: Vector2 in spots:
		var st := _at(sp.x)
		# Lipit de peretele falezei: centrul piesei la jumatate din latimea ei
		# dincolo de buza, ca fatada dinspre rau sa fie in gol si spatele in
		# stanca (piesa n-are detaliu pe spate — brief §5.2).
		var p := _off(st, 1.0, 8.0 + 17.0)
		p.y = st["pos"].y + sp.y - HONGYA_DROP - hongya_h
		var node_name := _place("chongqing/structures/hongya_dong", "hongya_hero",
			p, _yaw_to_road(st, 1.0), 1.0)
		# LUMINA: aici e tot rostul POI-ului. Sloturile 28 (lemnul, 61% din
		# arie) + 30 (aurul ferestrelor, 0.8%) — masurat cu slot_area.gd.
		# Doar 30 ar lasa o silueta neagra pe o faleza neagra.
		_meta(node_name, "lumina", "28,30|1.35")

	# CHEVROANELE pe curbele oarbe. Cornisa e un S larg fara parapet pe
	# dreapta: chevronul e singurul lucru care spune unde se duce drumul cand
	# faleza inghite orizontul.
	var chevrons := [0.286, 0.291, 0.296, 0.336, 0.341, 0.346, 0.394, 0.399]
	for cf: float in chevrons:
		var st2 := _at(cf)
		_place("chongqing/props/chevron_post", "chevron",
			_off_ground(st2, 1.0, 7.6), _yaw_to_road(st2, 1.0), 1.0)

	# PARAPETUL: pe exteriorul unui SINGUR viraj, ca punctuatie (brief §2 D).
	# Un parapet continuu ar anula frica de cadere, care e subiectul POI-ului.
	var pf := 0.352
	while pf < 0.366:
		var st3 := _at(pf)
		_place("chongqing/props/cliff_railing", "parapet_cornisa",
			_off_ground(st3, 1.0, 7.8), _yaw_across(st3), 1.0)
		pf += 4.3 / _path.total

	# Felinarele cornisei, pe latura DINSPRE MUNTE (-1): pe dreapta e golul,
	# iar un stalp acolo ar fi si obstacol si contradictie cu „fara parapet".
	var lf := 0.268
	while lf < 0.424:
		var st4 := _at(lf)
		_place("chongqing/props/lamp_lantern_a", "felinar_cornisa",
			_off_ground(st4, -1.0, 8.4), _yaw_to_road(st4, -1.0), 1.0)
		lf += 26.0 / _path.total


# ------------------------------------------------------------------ geometria

func _at(frac: float) -> Dictionary:
	return _path.at(_path.total * frac)


## Punct la `dist` metri lateral de ax, la COTA DRUMULUI.
func _off(st: Dictionary, side: float, dist: float) -> Vector3:
	var road: Vector3 = st["pos"]
	var r: Vector3 = st["right"] * side
	return Vector3(road.x + r.x * dist, road.y, road.z + r.z * dist)


## Punct la `dist` metri lateral, asezat pe TERENUL de acolo. Pentru tot ce sta
## pe pamant: pe o panta, cota drumului ar lasa piesele in aer sau ingropate.
func _off_ground(st: Dictionary, side: float, dist: float) -> Vector3:
	var p := _off(st, side, dist)
	p.y = _sampler.ground_y(p.x, p.z)
	return p


## Yaw-ul care intoarce piesa CU FATA spre ax (pentru fatade si felinare).
func _yaw_to_road(st: Dictionary, side: float) -> float:
	var r: Vector3 = st["right"] * side
	return atan2(-r.x, -r.z)


## Yaw-ul care pune Z-ul LOCAL al piesei pe vectorul `right` — adica piesa sta
## DE-A CURMEZISUL drumului. Bun pentru panourile de parapet (cliff_railing e
## lat pe X local: 4.38 x 0.52 m, deci asezat asa panoul se insiruie de-a
## lungul soselei).
##
## Verificat cu dot, nu ghicit (memoria `rotatii-in-builder-semnul`):
## Basis(UP, atan2(r.x, r.z)) duce Z local exact pe `right` (dot = 1.000).
func _yaw_across(st: Dictionary) -> float:
	var r: Vector3 = st["right"]
	return atan2(r.x, r.z)


## Yaw-ul care pune Z-ul LOCAL al piesei pe directia de MERS. Pentru vehicule:
## autobuzul e 2.68 x 10.64 m pe (X, Z) local, deci cu yaw-ul celalalt ar sta
## de-a latul bulevardului.
##
## Confuzia asta a costat o runda: cele doua autobuze ale nodului de trafic,
## asezate cu `_yaw_across`, stateau BROADSIDE peste sosea si isi atingeau
## capetele la mijloc — `probe_fanta` a masurat 0.10 m de fanta, adica un zid.
## De-aia sunt doua functii cu nume care spun ce fac, nu una „de-a lungul".
func _yaw_drive(st: Dictionary) -> float:
	var r: Vector3 = st["right"]
	return atan2(-r.z, r.x)


# ------------------------------------------------------------------ iesirea

func _place(model: String, base: String, pos: Vector3, yaw: float,
		scl: float) -> String:
	_n += 1
	var node_name := "%s%d" % [base, _n]
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s" parent="DecorManual/%s" instance=ExtResource("%s")]'
		% [node_name, _section, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	_out.append("")
	return node_name


## Adauga o metadata pe ultimul nod emis. Linia goala de dupa transform s-a
## scris deja, deci se ridica: metadata trebuie sa stea in blocul nodului.
func _meta(_node_name: String, key: String, value: String) -> void:
	_out[_out.size() - 1] = 'metadata/%s = "%s"' % [key, value]
	_out.append("")


## Capul de sectiune: un Node3D la transformarea IDENTITATE (docs/decor_manual.md
## — „nodurile de zona raman la identitate", altfel fiecare cifra de dedesubt
## devine relativa si un diff in .tscn nu mai spune unde e obiectul).
func _open_section(title: String) -> void:
	_section = title
	_out.append('[node name="%s" type="Node3D" parent="DecorManual"]' % title)
	_out.append("")
