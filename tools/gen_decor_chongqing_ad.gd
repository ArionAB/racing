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
var _space: PhysicsDirectSpaceState3D
## Corpurile decorului DEJA existent in Track12.tscn. Generatorul reruleaza
## peste o pista care contine deja rezultatul rularii anterioare, deci fara
## excluderea asta fiecare piesa s-ar aseza pe acoperisul propriei versiuni
## precedente si cotele ar urca la fiecare rulare.
var _excluded: Array[RID] = []
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
	# CADRE DE FIZICA, nu doar de proces: `_ground` trage raze in `TerrainBody`,
	# iar corpul ala nu exista in spatiu inainte sa ruleze fizica.
	for i in 4:
		await get_tree().physics_frame
	_sampler = _track._sampler
	_path = TrackScenography._Path.new(_sampler)
	_space = _track.get_world_3d().direct_space_state
	_collect_excluded()
	print("; total=%.1f  half_width=%.2f" % [_path.total, _sampler.half_width()])
	_emit_all()
	print("")
	for line in _out:
		print(line)
	get_tree().quit(0)


## Aduna corpurile fizice ale DECORULUI (manual si procedural), lasand terenul.
func _collect_excluded() -> void:
	_excluded.clear()
	for root_name: String in ["DecorManual", "Decor"]:
		var root := _track.get_node_or_null(NodePath(root_name))
		if root == null:
			continue
		var stack: Array = [root]
		while not stack.is_empty():
			var x = stack.pop_back()
			for c in x.get_children():
				stack.append(c)
			var b := x as CollisionObject3D
			if b != null:
				_excluded.append(b.get_rid())
	print("; corpuri de decor excluse din raze: %d" % _excluded.size())


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
			_off_ground(s2, 1.0, _clear(s2, 1.0)), _yaw_across(s2), 1.0)
		f += 4.3 / _path.total

	# Stalpii cu lampioane: pe amandoua partile, alternand, la 22 m pas. In
	# referinta ei sunt ritmul pietei — sirul regulat de lumini calde care
	# spune cat de lunga e.
	var g := 0.003
	var side := 1.0
	while g < 0.040:
		var s3 := _at(g)
		_light(_place("chongqing/props/lamp_lantern_a", "felinar_piata",
			_off_ground(s3, side, _clear(s3, 2.5)), _yaw_to_road(s3, side), 1.0),
			1.6)
		side = -side
		g += 22.0 / _path.total

	_traffic_node()


## NODUL DE TRAFIC (brief §2 A si §3): bulevardul blocat de autobuze si
## masinute, cu O SINGURA fanta trecabila.
##
## Singurul grup din tot fisierul care sta INTENTIONAT pe carosabil, deci
## singurul pentru care `probe_manual` raporteaza „IN DRUM" fara ca asta sa fie
## o eroare: blocajul care nu e in drum nu blocheaza nimic. Ce trebuie sa fie
## adevarat aici nu e distanta fata de ax, ci latimea fantei — si aia se
## masoara separat, cu `tools/tmp/probe_fanta.gd`.
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

	# CE FACE FANTA. Autobuzul (10.64 m) s-a dovedit unealta gresita pentru
	# treaba asta: la fractia nodului drumul coteste, iar orice eroare de
	# cateva grade intre cadrul in care il asez si cel in care il masoara sonda
	# se inmulteste cu lungimea lui — masurat, o singura piesa acoperea toata
	# latimea bulevardului, si „fanta" gasita de sonda era pe acostament.
	# S-au incercat sase combinatii de offset si inclinare; niciuna n-a lasat o
	# banda libera INTRE autobuze.
	#
	# Deci fanta o fac masinutele (3.68 m): destul de scurte cat orientarea sa
	# nu mai conteze, si destule cat blocajul sa se citeasca. Autobuzele raman,
	# dar se muta pe MARGINI, unde lungimea lor lucreaza pentru compozitie (un
	# perete de bulevard blocat) in loc sa lucreze impotriva fantei.
	_place("chongqing/vehicles/bus", "autobuz_stanga",
		_off(st, -1.0, 8.6), _yaw_drive(st), 1.0)
	_place("chongqing/vehicles/bus", "autobuz_dreapta",
		_off(_at(f - 0.005), 1.0, 8.6), _yaw_drive(_at(f - 0.005)), 1.0)

	# Cele doua masinute care STRANG fanta, fata in fata pe cele doua benzi.
	#
	# Offsetul e 6.2 m, nu 4.8, si nu din estetica. La 4.8 `probe_fanta` masura
	# 3.20 m liberi, intre lat -1.5 si +1.7: trece gabaritul (2.4 m), dar
	# ProbeRace seed 2 raporta un blocaj la frac 0.029 cu masina oprita la
	# lat 1.6 — adica FIX pe buza fantei. AI-ul nu vine prin centrul soselei,
	# deci o fanta centrata pe ax nu e o decizie pentru el, e o capcana: intra
	# cu o roata in masinuta si se opreste. La 6.2 m raman 6.0 m liberi, intre
	# -2.9 si +3.1, iar linia AI-ului e inauntru cu margine de fiecare parte.
	# Bulevardul are 18 m, deci blocajul tot acopera doua treimi din el.
	_place("chongqing/vehicles/mini_car_a", "masina_fanta_stanga",
		_off(st, -1.0, 6.2), _yaw_drive(st) + deg_to_rad(6.0), 1.0)
	_place("chongqing/vehicles/mini_car_b", "masina_fanta_dreapta",
		_off(st, 1.0, 6.2), _yaw_drive(st) - deg_to_rad(6.0), 1.0)

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
				_off_ground(s3, signf(lat), _clear(s3, 0.6)), 0.0, 1.0)
			j += 1


## --- B: coborarea Shibati (frac 0.04-0.14) --------------------------------
##
## Referinta (bar/B_scari.png): scara de piatra taie panta pe langa drum, iar
## de-a lungul ei case vechi cu obloane, rufe intinse, oameni marunti.
##
## CE S-A MASURAT, si de ce prima versiune n-a mers: pe latura -1 terenul e
## PLAT pana la 28 m (64.0 -> 63.9 la fractia 0.05). Nu exista panta laterala
## pe care sa curga o scara. Ce coboara aici e DRUMUL — 64 m la 0.05, 56 m la
## 0.11 — iar terenul coboara odata cu el.
##
## Deci scara nu taie panta perpendicular pe drum (n-are ce taia): merge PE
## LANGA drum, in jos, si fiecare bucata sta pe cota terenului ei. Ordinea
## laterala e cea din referinta — intai treptele, apoi casele in spatele lor:
## treptele sunt primul lucru sub tine cand te uiti in stanga.
##
## Distantele nu sunt alese pentru inaltime (7.6 m de pravalie incap in frustum
## la ORICE distanta) ci pentru LATIME: la 11 m lateral o singura pravalie de
## 7 m umple jumatate de cadru si in loc de un cartier se vede un perete. In
## referinta casele sunt marunte si multe tocmai fiindca sunt departe.
func _poi_b_shibati() -> void:
	_open_section("2) Coborarea Shibati")

	# SCARA, langa drum: `stone_stairway` e o BUCATA (10.4 x 12.6 m), deci
	# pasul e lungimea ei, si fiecare bucata sta pe cota terenului ei.
	var f := 0.052
	while f < 0.108:
		var st := _at(f)
		_place("chongqing/structures/stone_stairway", "scara",
			_off_ground(st, -1.0, _clear(st, 2.0)), _yaw_to_road(st, -1.0), 1.0)
		f += 12.0 / _path.total

	# Pravaliile, in doua siruri DINCOLO de scara.
	var shops := [
		"chongqing/buildings/shophouse_a", "chongqing/buildings/shophouse_b",
		"chongqing/buildings/shophouse_c",
	]
	var g := 0.050
	var k := 0
	while g < 0.110:
		var st2 := _at(g)
		_place(shops[k % 3], "pravalie",
			_off_ground(st2, -1.0, 21.0), _yaw_to_road(st2, -1.0), 1.0)
		if k % 2 == 0:
			_place(shops[(k + 1) % 3], "pravalie_jos",
				_off_ground(st2, -1.0, 31.0),
				_yaw_to_road(st2, -1.0) + 0.25, 1.0)
		g += 8.5 / _path.total
		k += 1

	# Rufele intre case, la inaltime de etaj: in referinta ele sunt ce spune
	# „aici locuieste cineva".
	var h := 0.054
	while h < 0.106:
		var st3 := _at(h)
		var p3 := _off_ground(st3, -1.0, 24.0)
		p3.y += 3.2
		_place("chongqing/props/laundry_line", "rufe", p3,
			_yaw_across(st3), 1.0)
		h += 13.0 / _path.total

	# HAMALII pe scara, sub linia camerei (brief §2 B). Nu pe carosabil: sunt
	# figuranti, iar un figurant care opreste o masina de cursa e un bug.
	var porters := [
		Vector2(0.058, 15.0), Vector2(0.066, 17.5), Vector2(0.072, 16.0),
		Vector2(0.080, 18.5), Vector2(0.088, 16.5), Vector2(0.096, 19.0),
	]
	var m := 0
	for pp: Vector2 in porters:
		var st4 := _at(pp.x)
		_place("chongqing/props/porter", "hamal",
			_off_ground(st4, -1.0, pp.y),
			_yaw_to_road(st4, -1.0) + deg_to_rad(float(m) * 41.0), 1.0)
		m += 1

	# Lampioanele scarii: sirul de lumini care o face citibila noaptea.
	var q := 0.054
	while q < 0.108:
		var st5 := _at(q)
		_light(_place("chongqing/props/lamp_lantern_c", "felinar_scara",
			_off_ground(st5, -1.0, _clear(st5, 0.8)),
			_yaw_to_road(st5, -1.0), 1.0), 1.6)
		q += 11.0 / _path.total


## --- C: aleea hot-pot (frac 0.16-0.24) ------------------------------------
##
## Brief §2 C: coridor strans de 6 m intre restaurante. Carosabilul se
## stramteaza singur (custom_width_segments: 6.0 intre 0.18 si 0.209), deci
## treaba decorului e sa faca PERETII.
##
## RUNDA 3 — de ce aleea „exista ca geometrie, dar e stinsa si nu e coridor".
## `restaurant_front` are 4.68 m inaltime, adica UN nivel. Pus la 8.2 m
## lateral, capatul lui de sus ramane sub linia de vedere si de pe sosea nu se
## vad decat ACOPERISURILE — masurat pe captura rundei 2: un sir de soproane
## privite de sus, nu un tunel. Frustumul (§2.0) spune cat poti sa pui, nu cat
## TREBUIE: la 7 m lateral incap 10.6 m de perete, iar noi foloseam 4.7.
##
## Deci peretele il fac `shophouse_a/b/c` (7.6 m, doua niveluri), asezate mai
## aproape (7.2 m), iar restaurantele raman la parter, in fata lor, ca
## tejghelele luminate de unde vine aburul. Doua randuri, nu unul: asa
## coridorul are si inaltime si adancime.
func _poi_c_alee() -> void:
	_open_section("3) Aleea hot-pot")

	# PERETELE: pravalii de doua niveluri pe amandoua partile, alternand
	# piesa ca sa nu iasa un gard repetat. La 7.2 m lateral cei 7.6 m de
	# fatada intra in cadru pana sus (la 7 m lateral camera vede 10.6 m).
	# Distanta e 10.5 m, nu 7.2. La 7.2 m pravaliile de 7.6 m ies din cadru pe
	# sus si raman in imagine cu ACOPERISUL — masurat pe captura: un zid de
	# invelitori cenusii care inghesuie aleea si ascunde chiar tejghelele
	# luminate pentru care exista coridorul. Camera priveste in JOS, deci o
	# fatada se vede doar de la distanta la care unghiul ei de sus intra sub
	# linia de vedere: la 10.5 m, cei 7.6 m de pravalie se citesc ca PERETE.
	var shop := ["chongqing/buildings/shophouse_a",
		"chongqing/buildings/shophouse_b", "chongqing/buildings/shophouse_c"]
	var f := 0.168
	var k := 0
	while f < 0.240:
		var st := _at(f)
		for sd: float in [-1.0, 1.0]:
			# Peretii pravaliei stau IN lumina calda a aleii (MULTIPLY pe
			# sloturile de zidarie), nu sunt ei sursa. Slotul 30 (firma) NU
			# intra in spalare: MULTIPLY l-ar INCHIDE, si tocmai el trebuie
			# sa arda. O piesa are un singur material_override, deci alegerea
			# e „ori firma arde, ori peretele se incalzeste" — pe pravalii
			# conteaza peretele (30% slot 11 gri-albastru + 19% slot 29 gri,
			# adica dominanta rece masurata), firmele le dau restaurantele si
			# lampioanele de langa ele.
			# Distanta se CITESTE din sampler (`_clear`), nu se scrie de mana.
			# Cu 10.5 m fix, in aleea care se stramteaza la 6 m latime utila
			# pravaliile intrau peste linia de curs: ProbeRace seed 1 a dat 41
			# atingeri de pereti pe feliile 0.15-0.25 si viteza cazuta la
			# 12-18 m/s (fata de 26-32 pe restul turului). `_clear` da
			# jumatatea LOCALA plus marja sondei, deci urmareste stramtarea.
			_wash(_place(shop[k % 3], "pravalie",
				_off_ground(st, sd, _clear(st, 3.6)), _yaw_to_road(st, sd), 1.0),
				"3,8,11,20,28,29", 1.0, "#FFB877")
			k += 1
		f += 7.0 / _path.total

	# RESTAURANTELE, la parter in fata pravaliilor: tejgheaua luminata de unde
	# ies aburii. Decalate fata de pravalii, ca sa nu se suprapuna fatadele.
	var f2 := 0.172
	var side := 1.0
	while f2 < 0.236:
		var st := _at(f2)
		# La 6.4 m fix, `restaurant151_col` a fost blocantul numit de ProbeRace
		# (2 repuneri, seed 1). Piesa are 9.2 m latime, deci centrul ei trebuie
		# sa stea la jumatatea aia distanta de marginea benzii, nu pe ea.
		_light(_place("chongqing/buildings/restaurant_front", "restaurant",
			_off_ground(st, side, _clear(st, 1.2)), _yaw_to_road(st, side),
			1.0), 1.6)
		side = -side
		f2 += 7.4 / _path.total

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
		_light(_place("chongqing/props/lamp_lantern_b", "felinar_alee",
			_off_ground(st4, qs, _clear(st4, 0.6)), _yaw_to_road(st4, qs), 1.0),
			1.6)
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
	_light(_place("chongqing/props/neon_sign_a", "neon_roz",
		_off_ground(st6, 1.0, 6.0), _yaw_to_road(st6, 1.0), 1.0), 2.2, "#FF3FA4")


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

	# Piesa are originea pe TALPA (masurat: aabb pos.y = 0, size.y = 47.74),
	# deci `p.y` e cota talpii, nu a coamei. Prima incercare a scazut toata
	# inaltimea din cota drumului si a ingropat hero-ul la y = -19 .. -27,
	# adica sub podeaua lumii — verificat cu tools/tmp/check_glow2.gd, care
	# scrie si pozitia, nu doar materialul.
	#
	# Asezarea corecta se citeste de la TALPA in sus: talpa sta pe terasa
	# (masurat 5.7 m pe toata cornisa), iar de acolo cele 47.7 m de casa urca
	# pana la ~53 m — adica exact sub buza, care e la 32-34 m. Ca sa incapa
	# sub buza cu cei 5 m de HONGYA_DROP ceruti de brief, piesa se scaleaza
	# pana cand coama ajunge la `buza - HONGYA_DROP`.
	# A doua greseala, prinsa tot pe captura: scalasem piesa pana cand coama ei
	# incapea SUB buza. Cu 47.7 m de casa si o faleza de 27, iesea un factor de
	# 0.4 — hero-ul ajungea o cladire de 17 m, la 25 m lateral, adica un obiect
	# pe langa care treci. In referinta (bar/D_cornisa.png) casele umplu doua
	# treimi din cadru si URCA pe langa drum: nu te uiti la ele de sus, esti
	# INTRE ele.
	#
	# Deci scara ramane 1.0 si piesa se lipeste de buza (8.5 m masurat): coama
	# trece de cota soselei, iar `HONGYA_DROP` isi schimba rolul — nu mai
	# coboara coama, ci coboara TALPA sub buza, ca etajele sa se vada
	# coborand in gol.
	var terrace_y := 5.7
	# CE VEDE CAMERA, si de ce runda 2 a picat cu „hero-ul e mic si lateral".
	#
	# Trei cauze, toate masurate, si doar una era de compozitie:
	#
	#  1. AO-ul copt in `hongya_dong.glb` era STRICAT: mediana vertex color
	#     0.098 — FIX podeaua lui `floor=0.10` — pe peste jumatate din mesh.
	#     `AO_HERO` folosea `dist=9.0` pe o cladire de 47.7 m cu geometrie
	#     densa: razele loveau ceva in toate directiile, ocluzia satura, tot
	#     corpul cadea pe podea. Props-urile aceluiasi kit folosesc 2.0-2.6,
	#     iar `buildings/village_house` de pe o pista livrata are mediana
	#     0.475. Cu jumatate din mesh la 0.098, NIMIC nu putea arata a
	#     cladire: ADD dadea placa portocalie, MULTIPLY placa crem — ambele
	#     „plate" fiindca dedesubt nu mai era relief, doar o constanta.
	#     Reparat IN ASSET (vertex colors recompuse, mediana 0.675).
	#  2. Masca emisiva avea 31 px in loc de 32 (`HEX.size()` vs `SLOTS`):
	#     slotul 30 cadea intre texeli si ardea pe jumatate. De aici venea
	#     masuratoarea „slotul 30 singur da o silueta neagra" — concluzie
	#     corecta pe o masca gresita. Reparat in `palette.gd`.
	#  3. Ferestrele erau de 0.62 x 0.78 m, adica 0.29 x 0.37 m la scara
	#     hero-ului: sub-pixel de la 40 m. Dovada ca nu era o problema de
	#     energie: la 6, 12 si 20 warm% masura acelasi 0.66 — emisia satura pe
	#     o arie prea mica. Largite in asset la 1.15 x 1.13 m (traveea e
	#     2.1 m, deci ramane ~1 m de perete intre ele) si retragerea de 12 cm
	#     NU s-a atins, ca golul sa ramana gol, nu autocolant.
	#
	# GEOMETRIA LOCULUI, masurata cu ground_y pe toata cornisa: soseaua e la
	# 32-34 m, fata falezei cade SCURT si abrupt (8 m -> 31 m, 13 m -> 5.7 m),
	# iar dincolo de 13 m e terasa PLATA la 5.7 m. Deci nu exista perete pe
	# care sa „atarne" casele: ele stau pe terasa si trebuie sa fie destul de
	# INALTE cat sa urce inapoi pana sub buza.
	#
	# Si mai important, ce vede camera: la 63° in jos, de la o distanta
	# laterala `d` vezi cel mult `d * tan(63) = 1.96 * d` metri sub ochi. La
	# 12 m lateral vezi pana la cota 9 — deci dintr-o casa cu talpa pe terasa
	# se vede DOAR ce trece de cota aia. De-aia stivele se pun aproape (12 m,
	# pe muchia de sus a falezei) si inalte (coama la 5 m sub buza, brief §8):
	# tot ce e mai jos sau mai departe nu ajunge niciodata pe ecran.
	# CE VEDE CAMERA DIN HERO, si de ce runda 3 a picat cu „fragmente
	# imprastiate, cu spatiu pe sub ele".
	#
	# Camera vede ~63° SUB orizontala: de la distanta laterala `d` vezi cel
	# mult `1.96 * d` metri sub cota ochiului. Stivele stateau la 12 m cu
	# TALPA pe terasa (5.7 m) si drumul la 32-34 m — deci din 47 m de casa,
	# primii 26 cadeau sub linia de vedere si NU AJUNGEAU NICIODATA pe ecran.
	# Ce ramanea vizibil era o fasie de 5-8 m din varf: exact „fragmentele
	# portocalii mici" din verdict. Masa exista in lume si lipsea din cadru.
	#
	# Deci talpa NU mai sta pe terasa. Fiecare stiva se aseaza astfel incat
	# coama ei sa fie la `HONGYA_DROP` sub buza (brief §8 — hero-ul incepe la
	# ~5 m sub buza, nu la 27), iar corpul sa coboare de acolo in gol. Piesa
	# pastreaza scara 1.0: la 47.74 m coama e la buza-5 si talpa la buza-53,
	# adica bine sub terasa — dar terasa e ORIZONT, nu podea, iar ce e sub ea
	# oricum nu se vede. Ce se castiga: cei 20 m de fatada de sub buza, care
	# sunt chiar fasia pe care camera o vede.
	#
	# STIVELE se ating intre ele (pas ≈14 m pe o piesa de 42 m latime, deci
	# suprapunere reala): in referinta nu sunt case separate pe o terasa, e un
	# ZID continuu de balcoane care coboara.
	var spots := [
		Vector2(0.250, 0.0), Vector2(0.257, -1.5), Vector2(0.264, 0.0),
		Vector2(0.271, -1.5), Vector2(0.278, 0.0), Vector2(0.285, -1.5),
		Vector2(0.292, 0.0), Vector2(0.299, -1.5), Vector2(0.306, 0.0),
		Vector2(0.313, -1.5), Vector2(0.320, 0.0), Vector2(0.327, -1.5),
		Vector2(0.334, 0.0), Vector2(0.341, -1.5), Vector2(0.348, 0.0),
		Vector2(0.355, -1.5), Vector2(0.362, 0.0), Vector2(0.369, -1.5),
		Vector2(0.376, 0.0), Vector2(0.383, -1.5), Vector2(0.390, 0.0),
		Vector2(0.397, -1.5), Vector2(0.404, 0.0), Vector2(0.411, -1.5),
	]
	for sp: Vector2 in spots:
		var st := _at(sp.x)
		var brink: float = st["pos"].y
		# COAMA la `buza - HONGYA_DROP`, talpa unde cade. Scara ramane 1.0:
		# piesa e proiectata pentru masa asta, iar micsorarea ei a fost chiar
		# greseala rundelor trecute.
		# CAT DE JOS, exact. Cu coama la buza-5 si piesa lipita la 11 m, de pe
		# sosea vezi ACOPERISUL, nu fatada: la 63° in jos linia de vedere
		# trece pe deasupra coamei si tot ce ajunge pe ecran e un camp de
		# placi cenusii (masurat pe captura — dreapta cadrului iesea gri, cu
		# zero ferestre). In referinta se vad FATADELE cu ferestre, fiindca
		# ele coboara PE LANGA drum, nu sub el.
		#
		# Deci coama coboara sub buza cat sa intre fatada in cadru, si piesa
		# se departeaza cat sa nu fie privita vertical: la 16 m lateral si
		# coama la buza-13, linia de la 63° taie fatada pe la mijloc.
		var ridge := brink + sp.y - HONGYA_DROP
		var p := _off(st, 1.0, 13.0)
		p.y = ridge - 47.74
		var node_name := _place("chongqing/structures/hongya_dong", "hongya_hero",
			p, _yaw_to_road(st, 1.0), 1.0)
		# LUMINA: ard FERESTRELE (slotul 30), nu corpul — lumina calda care
		# scapa dintre lemne intunecate, exact limbajul referintei.
		_light(node_name, 2.0)
		# Fara corp fizic: cine cade de pe cornisa trebuie sa CADA in terasa
		# si sa fie repus, nu sa aterizeze pe un acoperis la 30 m.
		_meta(node_name, "coliziune", "none")

		# AL DOILEA RAND, mai in afara si cu coama mai jos: da adancime
		# (acoperisuri care coboara in trepte spre apa) fara sa acopere
		# randul intai.
		var p2 := _off(st, 1.0, 13.0 + 20.0)
		p2.y = ridge - 47.74 - 7.0
		var n2 := _place("chongqing/structures/hongya_dong", "hongya_jos",
			p2, _yaw_to_road(st, 1.0) + deg_to_rad(14.0), 1.0)
		_light(n2, 2.0)
		_meta(n2, "coliziune", "none")

		# RANDUL DE BUZA — ce repara „dreapta e un camp de placi cenusii".
		#
		# Masurat cu `tools/tmp/probe_view.gd`: stivele de mai sus cad la
		# -14° .. -60° sub orizontala, adica bine INAUNTRUL frustumului. Nu
		# erau invizibile, erau privite DE SUS — iar de sus dintr-o casa vezi
		# acoperisul, si acoperisul lui hongya_dong e o placa mare fara
		# ferestre. In referinta cadrul e umplut de FATADE cu balcoane
		# aprinse, fiindca ele urca pana aproape de cota drumului.
		#
		# Deci un rand lipit de buza (9 m) cu coama la 2 m sub sosea: de acolo
		# unghiul spre perete e mic si pe ecran ajunge fatada cu ferestre, nu
		# invelitoarea. Randurile dinainte raman si dau adancimea.
		# COTA se alege dupa CE E LA COTA AIA IN MESH, nu dupa cat de sus e
		# piesa. Masurat cu `tools/tmp/hd_shape.gd` (aria pe benzi de 5 m,
		# separata in orizontala/verticala): piesa alterneaza benzi de FATADA
		# (y 10-15 si 20-25 m: 83% si 72% suprafata verticala) cu TERASE de
		# acoperis (y 5-10, 15-20, 25-30: doar 10-12% vertical, cate ~1400 m²
		# de placa orizontala). Varful (y 40-50) e tot acoperis.
		#
		# De-aia dreapta cadrului iesea „camp de placi cenusii" oricat mutam
		# piesa pe verticala: nimereau mereu terasele. Aici banda de fatada
		# 20-25 m se aduce la nivelul ochiului, adica la cota drumului: talpa
		# = sosea - 22.5.
		# Talpa la `sosea - 27.5` pune banda de fatada 20-25 m intre cotele
		# -7.5 si -2.5 fata de drum: fatada e SUB buza (regula §2.0 tine —
		# coama piesei ramane la -22.5 fata de nimic ce depaseste soseaua),
		# dar destul de aproape de cota ochiului cat sa fie privita aproape
		# frontal, nu de deasupra. La -22.5 (incercat, masurat pe captura)
		# corpul urca 25 m PESTE drum si ocupa jumatate de ecran.
		var p3 := _off(st, 1.0, 9.0)
		p3.y = brink + sp.y - 27.5
		var n3 := _place("chongqing/structures/hongya_dong", "hongya_buza",
			p3, _yaw_to_road(st, 1.0) + deg_to_rad(-7.0), 1.0)
		_light(n3, 2.4)
		_meta(n3, "coliziune", "none")

	# PERETELE DIN STANGA — jumatatea goala din verdict.
	#
	# Masurat cu raze in mesh-ul de coliziune: pe toata cornisa (0.26-0.44)
	# terenul din stanga e PLAT si la cota drumului (-0.5 .. +1.1 m la 11-40 m
	# lateral), si `is_on_road` spune „liber" peste tot acolo. Adica exista un
	# platou intreg pe care nu statea nimic — de-aia stanga cadrului iesea
	# camp gri, si de-aia soseaua se citea ca o banda izolata.
	#
	# In referinta drumul TRECE PRIN oras: are case pe amandoua partile, iar
	# intunericul e fundal, nu vecin. Deci stanga primeste un perete de
	# coridor din `shophouse_a/b/c` (7.6 m inaltime = doua niveluri, exact ce
	# permite frustumul la 10-12 m lateral: `10 + 0.093*11` ≈ 11 m).
	# Se aseaza pe TEREN (`_off_ground`, deci raycast), in doua siruri:
	# primul lipit de drum, al doilea in spate si mai departat, ca peretele sa
	# aiba adancime in loc sa fie un panou.
	var shopd := ["chongqing/buildings/shophouse_a",
		"chongqing/buildings/shophouse_b", "chongqing/buildings/shophouse_c"]
	var wf := 0.252
	var wi := 0
	while wf < 0.436:
		var stw := _at(wf)
		# Randul din fata: la 11.5 m de ax, cu fata spre drum.
		var nw := _place(shopd[wi % 3], "casa_cornisa",
			_off_ground(stw, -1.0, 11.5), _yaw_to_road(stw, -1.0), 1.0)
		# ACEEASI RETETA ca pravaliile aleii C, care sunt aceleasi mesh-uri:
		# sloturile de fatada la energie 1.0 cu operatorul MULTIPLY (`*`).
		# Slotul 30 la 1.7 — ce incercasem intai — aprindea geamul ca pe un
		# panou alb (se vede in captura: ferestre arse, fara cadru), fiindca
		# ADD peste un albedo deja deschis satureaza. MULTIPLY pastreaza
		# relieful si lasa ramele sa se citeasca.
		_meta(nw, "lumina", "3,8,11,20,28,29|1.00|#FFB877*")
		# Randul din spate: mai departat si rotit, ca sa se vada acoperisuri
		# peste primul rand (adancime), nu o singura linie de fatade.
		if wi % 2 == 0:
			var nb := _place(shopd[(wi + 2) % 3], "casa_cornisa_spate",
				_off_ground(stw, -1.0, 20.5), _yaw_to_road(stw, -1.0)
				+ deg_to_rad(22.0), 1.0)
			_meta(nb, "lumina", "3,8,11,20,28,29|1.00|#FFB877*")
		wi += 1
		wf += 8.6 / _path.total

	# RUFELE intre casele din stanga: semnatura cartierului, si singurul lucru
	# care umple aerul dintre fatade. Sunt INTINSE intre cladiri, deci stau
	# legitim deasupra terenului (cota drumului + 3 m).
	var rf := 0.258
	while rf < 0.430:
		var str2 := _at(rf)
		var pr := _off(str2, -1.0, 15.5)
		pr.y += 3.0
		_place("chongqing/props/laundry_line", "rufe_cornisa",
			pr, _yaw_to_road(str2, -1.0), 1.0)
		rf += 17.0 / _path.total

	# CHEVROANELE pe curbele oarbe. Cornisa e un S larg fara parapet pe
	# dreapta: chevronul e singurul lucru care spune unde se duce drumul cand
	# faleza inghite orizontul.
	# Acoperirea merge pana la 0.44, nu se opreste la 0.40: verdictul rundei 3
	# a gasit „la 0.36 si 0.42 nu e practic nimic acolo".
	var chevrons := [0.286, 0.291, 0.296, 0.336, 0.341, 0.346,
		0.376, 0.381, 0.394, 0.399, 0.416, 0.421, 0.432, 0.437]
	for cf: float in chevrons:
		var st2 := _at(cf)
		_place("chongqing/props/chevron_post", "chevron",
			_off_ground(st2, 1.0, _clear(st2, 0.3)), _yaw_to_road(st2, 1.0), 1.0)

	# PARAPETUL: pe exteriorul unui SINGUR viraj, ca punctuatie (brief §2 D).
	# Un parapet continuu ar anula frica de cadere, care e subiectul POI-ului.
	var pf := 0.352
	while pf < 0.366:
		var st3 := _at(pf)
		_place("chongqing/props/cliff_railing", "parapet_cornisa",
			_off_ground(st3, 1.0, _clear(st3, 0.3)), _yaw_across(st3), 1.0)
		pf += 4.3 / _path.total

	# Felinarele cornisei, pe latura DINSPRE MUNTE (-1): pe dreapta e golul,
	# iar un stalp acolo ar fi si obstacol si contradictie cu „fara parapet".
	var lf := 0.258
	while lf < 0.444:
		var st4 := _at(lf)
		_light(_place("chongqing/props/lamp_lantern_a", "felinar_cornisa",
			_off_ground(st4, -1.0, _clear(st4, 0.8)), _yaw_to_road(st4, -1.0), 1.0),
			1.6)
		lf += 19.0 / _path.total



## Cel mai apropiat offset lateral PERMIS pentru un obiect solid, la fractia
## data: latimea LOCALA a benzii plus marja cu care lucreaza `probe_manual`
## (`ROAD_MARGIN` = 2.0 m). Sub cifra asta, sonda raporteaza „IN DRUM" — si are
## dreptate, fiindca acolo chiar trece masina.
##
## Se citeste din sampler, nu se scrie de mana: pista are profil de latime
## (`custom_width_segments`), deci piata are 9 m si aleea 6, iar un singur
## numar ar fi gresit intr-una din ele.
func _clear(st: Dictionary, extra: float = 0.0) -> float:
	# `half_width_at` vrea un INDEX din punctele coapte, iar `_Path.at` da o
	# fractie: conversia trece prin numarul de puncte.
	var n := _track.baked.size()
	var idx := int(float(st["frac"]) * float(n)) % n
	return _sampler.half_width_at(idx) + 2.0 + extra


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
	p.y = _ground(p.x, p.z, p.y)
	return p


## COTA TERENULUI, CITITA DIN MESH-UL DE COLIZIUNE, nu din `ground_y`.
##
## `ground_y` e un camp NETED (medie ponderata a cotelor drumului plus dune) —
## sursa buna pentru cat de sus e lumea in general, sursa GRESITA pentru unde
## se aseaza o piesa. Terenul randat e sculptat pe deasupra (cornisa, rapa,
## terasa per POI), deci cele doua diverg exact acolo unde panta e mare:
## masurat pe cornisa, `ground_y` da 25.77 acolo unde `TerrainBody` e la 17.06
## — 8.7 m de aer sub piesa. Pe aleea C diferenta ajunge la 11.7 m.
##
## De aici veneau piesele plutitoare gasite de critic: nu erau asezate „la cota
## drumului din greseala", erau asezate pe un teren care nu exista.
##
## Raza porneste de SUS (cota data + 80 m) ca sa nu inceapa deja sub deal, si
## exclude decorul deja pus — altfel a doua piesa se aseaza pe acoperisul
## primeia. Daca nu loveste nimic (gol real), intoarce cota data, iar apelantul
## decide; nicio piesa din fisierul asta nu se pune deliberat peste gol.
func _ground(wx: float, wz: float, hint: float) -> float:
	if _space == null:
		return _sampler.ground_y(wx, wz)
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(wx, hint + 80.0, wz), Vector3(wx, hint - 400.0, wz))
	q.exclude = _excluded
	var hit := _space.intersect_ray(q)
	if hit.is_empty():
		return _sampler.ground_y(wx, wz)
	return (hit["position"] as Vector3).y


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
	# Tangenta se ia din punctele COAPTE, nu din `_Path`. Cele doua nu sunt
	# acelasi lucru: la fractia nodului de trafic esantionul lui `_Path` cade
	# la ~1.8 m de punctul copt, iar acolo drumul coteste — masurat, autobuzele
	# ieseau la 23.6° si 29.6° fata de tangenta pe care o foloseste
	# `probe_fanta`, in loc de cei 3° ceruti. Un autobuz de 10.64 m la 26°
	# mananca lateral ~7 m, adica exact latimea bulevardului: de-aia „fanta"
	# gasita de sonda era pe acostament, nu intre autobuze.
	#
	# Vehiculele se orienteaza deci dupa ACEEASI directie pe care o masoara
	# sonda, altfel cele doua unelte vorbesc despre doua drumuri diferite.
	var n := _track.baked.size()
	# indexul se ia dupa POZITIE, nu dupa fractie: fractia lui `_Path` si
	# fractia pe punctele coapte nu sunt aceeasi parametrizare.
	var road: Vector3 = st["pos"]
	var idx := 0
	var best := 1e30
	for i in n:
		var d: float = (_track.baked[i] - road).length_squared()
		if d < best:
			best = d
			idx = i
	var nx: Vector3 = _track.baked[(idx + 1) % n]
	var pv: Vector3 = _track.baked[(idx - 1 + n) % n]
	var fw := nx - pv
	fw.y = 0.0
	fw = fw.normalized()
	# +90°: gasit prin masurare, nu prin deducere. Cu `atan2(fw.x, fw.z)` gol,
	# amprenta de coliziune a autobuzului iesea 6.5 m lata pe latimea soselei
	# (tools/tmp/probe_fanta2.gd) desi colizorul e o cutie curata de 2.68 m
	# (tools/tmp/bus_local.gd) — adica piesa statea de-a curmezisul. Diferenta
	# se citeste direct in amprenta, si aia e proba care conteaza aici.
	return atan2(fw.x, fw.z) + PI * 0.5


# ------------------------------------------------------------------ iesirea

## Aprinde o piesa asezata: scrie metadata `lumina` citita de `world_prop.gd`.
##
## De ce e o functie si nu doua linii la fiecare apel: lumina calda e SUBIECTUL
## pistei (brief §4, „auriu de Hongya Dong, rosu de lampioane"), iar runda 2 a
## picat fiindca lipsea peste tot, nu doar pe hero. Masurat pe cadrul cornisei:
## bara are R-B = +24.7 si 20% pixeli calzi, noi aveam R-B = -18 si 0.6% — semn
## INVERS, adica o scena albastru-cenusie cu cateva pete portocalii. Cauza nu
## era o nuanta gresita, ci ca nimic in afara de hero nu ardea: cei 13 felinari
## ai cornisei, lampioanele pietei, neonul aleii si ferestrele pravaliilor
## stateau toate STINSE, desi fiecare are 33-68% din arie in slotul 30.
const WARM := "#FFC98A"

func _light(node_name: String, energy: float, tint: String = WARM) -> void:
	_meta(node_name, "lumina", "30|%.1f|%s" % [energy, tint])


## Aceeasi lumina, dar peste MAI MULTE sloturi si cu operatorul MULTIPLY:
## „peretii astia stau intr-o lumina calda", nu „peretii astia sunt surse".
##
## De ce MULTIPLY si de ce si peretii: pe hero MULTIPLY a esuat (a iesit placa
## crem) fiindca AO-ul assetului era stricat si inmultea totul cu ~0.2. Pe
## fatadele kitului, cu AO teafar, inmultirea face exact ce trebuie: pastreaza
## si albedo-ul si umbra si doar le muta temperatura. Iar fara ea aleea ramane
## reala dar RECE — masurat pe cadrul aleii, peretii sunt 30% slot 11
## (`#7692A8`, gri-albastru) si 19% slot 29 (gri), adica fix dominanta rece pe
## care o reclama comparatia cu bara (R-B -14.5 la noi, +15.7 la ea). In
## referinta peretii nu sunt cenusii: sunt spalati de lumina care iese din
## pravalii.
func _wash(node_name: String, slots: String, energy: float,
		tint: String = WARM) -> void:
	_meta(node_name, "lumina", "%s|%.2f|%s*" % [slots, energy, tint])


func _place(model: String, base: String, pos: Vector3, yaw: float,
		scl: float) -> String:
	_n += 1
	var node_name := "%s%d" % [base, _n]
	# Baza se ia de la Godot, nu se scrie de mana. Versiunea scrisa de mana
	# folosea (c, 0, -s / s, 0, c), adica TRANSPUSA lui `Basis(UP, yaw)` — deci
	# fiecare piesa iesea rotita in sensul invers fata de unghiul verificat cu
	# `tools/tmp/yaw_check.gd`. Pe stalpi si pe parapete nu se vedea (sunt
	# simetrice), dar autobuzele nodului de trafic stateau de-a curmezisul
	# bulevardului si sonda gasea fanta pe acostament, nu intre ele.
	#
	# Cu `Basis` real, unghiul verificat si unghiul scris in .tscn sunt acelasi
	# lucru prin constructie.
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(scl, scl, scl))
	_out.append('[node name="%s" parent="DecorManual/%s" instance=ExtResource("%s")]'
		% [node_name, _section, RES[model]])
	# ATENTIE la ordinea componentelor. `Basis.x/.y/.z` sunt COLOANELE bazei,
	# dar constructorul `Transform3D(...)` isi ia primele noua argumente pe
	# LINII. Scrise ca mai jos in ordinea coloanelor, matricea iesea
	# TRANSPUSA — adica o rotatie cu -yaw.
	#
	# Pe piesele simetrice (stalpi, parapete) nu se vedea. Pe autobuzele
	# nodului de trafic se vedea tare: masurat cu tools/tmp/yaw3.gd, stateau la
	# 23° si 29° fata de tangenta in loc de cei 3° ceruti, adica aproape
	# de-a curmezisul bulevardului, si sonda gasea „fanta" pe acostament.
	#
	# `b[0]` / `b[1]` / `b[2]` sunt liniile, deci exact ce vrea constructorul.
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b[0].x, b[0].y, b[0].z, b[1].x, b[1].y, b[1].z,
			b[2].x, b[2].y, b[2].z, pos.x, pos.y, pos.z])
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
