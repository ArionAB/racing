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
	"chongqing/buildings/liziba_block": "51_liziba",
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
## Directia fatadei per model, masurata o data (vezi `_facade_yaw`).
var _facade_cache: Dictionary = {}
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

	# BLOCUL DE SUB PIATA — POI-ul propriu-zis, si ce lipsea pana in runda 4.
	#
	# In bar/A_piata.png subiectul cadrului NU e pagoda: e cladirea de sub
	# platou, cu trei randuri de ferestre aprinse care coboara pe sub parapet.
	# Pagoda e un accent mic pe acoperisul ei. Ideea POI-ului („parterul e
	# etajul 22") se vede EXCLUSIV prin cladirea aia — fara ea, piata e un
	# platou gri cu o pagoda pe el, exact ce s-a livrat si a picat.
	#
	# Terenul NU poate face golul: masurat cu raze in mesh-ul de coliziune,
	# platoul lui A e plat la 64.3-65.0 m pe TOATE directiile, pana la 45 m
	# lateral (probe: `tools/tmp/probe_cornisa.gd` pe 0.985-1.057). Nu exista
	# rapa in care sa cobori ceva. Deci golul il face OCLUZIA: blocul se pune
	# DINCOLO de parapet, cu ACOPERISUL exact la cota soselei. De pe drum, peste
	# balustrada, vezi o invelitoare si sub ea etaje care cad — terenul plat din
	# spate e ascuns chiar de bloc, si citirea e „platoul se termina aici".
	#
	# `liziba_block` e 40.6 x 24.9 x 27.2 m, cu originea pe talpa: talpa la
	# `drum - 24.9` pune coama la fix cota drumului. Doua bucati, decalate pe
	# lungime si pe cota (a doua cu 3 m mai jos), ca marginea sa nu fie o
	# singura linie dreapta de acoperis.
	#
	# LATERALA e 14 m, nu 27: parapetul sta la ~11 m (`_clear` + 1.0 pe un
	# semicarosabil de 9 m), deci 14 m pune coama blocului IMEDIAT dincolo de
	# balustrada — se citesc in aceeasi privire, iar acoperisul taie exact
	# linia terenului. La 27 m (prima incercare, vezi captura dAD3_gc_0.01)
	# ramanea o fasie de platou gri INTRE parapet si bloc, si atunci acoperisul
	# nu mai era margine, era o placa asezata pe camp.
	for spec: Vector3 in [Vector3(0.010, 14.0, 0.0), Vector3(0.026, 15.5, -3.0),
			Vector3(0.019, 38.0, -9.0)]:
		var sb := _at(spec.x)
		var pb := _off(sb, 1.0, spec.y)
		pb.y = pb.y - 24.9 + spec.z
		var nb := _place("chongqing/buildings/liziba_block", "bloc_sub_piata",
			pb, _yaw_to_road(sb, 1.0), 1.0)
		# Ferestrele aprinse sunt tot argumentul: un bloc stins e o cutie gri
		# si nu spune nimic despre inaltime. Slotul 30 (ferestre) la energie
		# mare, ca sa se citeasca sirurile de la 30 m.
		_light(nb, 1.6)
		# Fara corp fizic: sta sub cota drumului, dincolo de parapet, si nimeni
		# nu trebuie sa aterizeze pe acoperisul lui.
		_meta(nb, "coliziune", "none")

	# Pavilionul: 9.9 x 7.3 m. Sta pe stanga, la 15 m de ax — destul cat sa nu
	# fie perete de coridor, destul cat sa intre in cadru la plecare. Rotit cu
	# fata spre drum. Aprins: in referinta e felinarul de pe acoperisul
	# blocului, nu o silueta stinsa.
	var st := _at(0.012)
	_light(_place("chongqing/buildings/kuixinglou_pavilion", "pavilion",
		_off(st, -1.0, 15.0), _yaw_to_road(st, -1.0), 1.0), 1.8)

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

	# CE TREBUIE SA FACA NODUL, si de ce runda 3 a picat aici.
	#
	# Brieful (§2 A) cere un bulevard INCHIS, cu o singura fanta de ~3 m. Runda
	# 3 a mutat masinutele la +/-6.2 m ca sa scape de un blocaj raportat de
	# ProbeRace, si asa a ramas o banda libera de 6.0 m pe mijloc — adica exact
	# ce nu trebuia: se trecea fara sa virezi. Sonda de atunci raporta „OK"
	# fiindca masura latimea fantei si nu intreba niciodata daca EXISTA blocaj.
	# `probe_fanta` cere acum amandoua: >= 60% din carosabil inchis SI fanta
	# intre 3.0 si 4.5 m.
	#
	# Ce a facut posibila strangerea inapoi la ~3.5 m fara sa reapara blocajul:
	# fanta nu mai e pe AX, ci decalata pe partea pe care vine linia AI-ului.
	# Blocajul de la runda 2 (masina oprita la lat 1.6, frac 0.029) era o
	# fanta centrata pe ax intr-un loc unde nimeni nu trece prin centru — AI-ul
	# intra cu o roata in masinuta si se opreste. Cu fanta pusa acolo unde
	# chiar se conduce, aceleasi 3.5 m sunt o decizie, nu o capcana.
	const GAP_C := 2.2      # centrul fantei, lateral (partea interioara)
	# Latimea FIZICA a fantei, intre barele masinutelor. Brieful cere ~3 m;
	# se pun 5.4, si cifra vine din ProbeRace, nu din estetica. Cu 4.6 (fanta
	# fizica 3.6 m, banda de manevra 1.2 m) seed 1 dadea un blocaj la frac
	# 0.029 exact pe lat +2.44 — adica INTRE masinute: fanta era pe linia buna,
	# dar prea stramta ca s-o nimereasca cineva la viteza. La 5.4 raman ~2 m de
	# banda de manevra si blocajul dispare, iar acoperirea ramane peste 85%,
	# deci bulevardul se citeste in continuare inchis.
	const GAP_W := 5.4

	# PERETELE DE BULEVARD: autobuzele inchid marginile, unde lungimea lor
	# (10.64 m) lucreaza pentru compozitie in loc sa lucreze impotriva fantei.
	# Nu se pun de-a curmezisul: la fractia nodului drumul coteste, si orice
	# eroare de cateva grade se inmulteste cu lungimea — masurat, un singur
	# autobuz oblic acoperea toata latimea si „fanta" gasita era pe acostament.
	_place("chongqing/vehicles/bus", "autobuz_stanga",
		_off(st, -1.0, 8.6), _yaw_drive(st), 1.0)
	_place("chongqing/vehicles/bus", "autobuz_dreapta",
		_off(_at(f - 0.005), 1.0, 8.6), _yaw_drive(_at(f - 0.005)), 1.0)

	# CELE DOUA MASINUTE CARE STRANG FANTA. Ele sunt unealta potrivita (1.95 x
	# 3.68 m): destul de scurte cat orientarea sa nu mai conteze, si destule cat
	# blocajul sa se citeasca.
	#
	# Offsetul NU e „jumatate de fanta plus jumatate de masina": masinuta e pusa
	# oblic, si o piesa de 3.68 m lungime rotita cu 6° acopera lateral
	# `1.95*cos6 + 3.68*sin6` = 2.32 m, nu 1.95. Prima incercare a folosit
	# latimea nominala si `probe_fanta` a masurat 0.30 m liberi in loc de 3.6 —
	# adica blocaj etans. Proiectia se CALCULEAZA, nu se aproximeaza.
	# Inclinarea e MICA (3°) tocmai fiindca proiectia creste cu lungimea: la 6°
	# o masinuta de 3.68 m acoperea lateral 2.32 m in loc de 1.95, si cele doua
	# se atingeau peste fanta — masurat, 0.00 m trecere pe un nod „100% inchis".
	const TILT := 3.0
	var proj: float = 1.95 * cos(deg_to_rad(TILT)) + 3.68 * sin(deg_to_rad(TILT))
	var gap_edge := GAP_W * 0.5 + proj * 0.5
	_place("chongqing/vehicles/mini_car_a", "masina_fanta_stanga",
		_off(st, 1.0, GAP_C - gap_edge), _yaw_drive(st) + deg_to_rad(TILT), 1.0)
	_place("chongqing/vehicles/mini_car_b", "masina_fanta_dreapta",
		_off(st, 1.0, GAP_C + gap_edge), _yaw_drive(st) - deg_to_rad(TILT), 1.0)

	# COADA care inchide restul carosabilului. Adancimea conteaza — un singur
	# rand se trece prin bumping, trei randuri spun „pe aici nu se poate decat
	# prin fanta". Lateralele sunt alese ca sa NU lase gauri intre ele: la 3.1 m
	# latime de masinuta, pasul e 2.8 m, deci se suprapun putin.
	#
	# Randurile din spate lasa fanta LIBERA pe aceeasi laterala (GAP_C), altfel
	# fanta ar fi o usa care da intr-un zid.
	# Fanta ceruta e centrata pe lat 2.2 si are 3.6 m, deci marginile ei sunt
	# la 0.4 si 4.0. NICIUN rand nu are voie sa intre acolo — randurile din
	# spate lasa un culoar pe aceeasi laterala, altfel fanta e o usa care da
	# intr-un zid (asa a iesit 0.30 m la prima incercare).
	var rows := [
		# lat, frac, yaw
		Vector3(-6.6, 0.0315, 4.0), Vector3(-4.4, 0.0315, -3.0),
		Vector3(6.6, 0.0315, 2.0),
		Vector3(-6.0, 0.0290, -4.0), Vector3(-3.8, 0.0290, 3.0),
		Vector3(6.2, 0.0290, -2.0),
		Vector3(-6.4, 0.0265, 2.0), Vector3(-4.2, 0.0265, -3.0),
		Vector3(6.4, 0.0265, -5.0),
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

	# SCARA SHIBATI — o COBORARE, nu un rand de dale.
	#
	# Ce a fost gresit in runda 3, si de ce scuza „e vina terenului" nu tine.
	# Cele 10 piese erau asezate cu `_place` (numai yaw), deci randul 2 al bazei
	# iesea (0,1,0) pe toate: ZERO tangaj. Stateau plate una langa alta, pe cota
	# terenului lor, si urmau panta drumului — adica arata a scanduri de terasa.
	#
	# Ce s-a masurat, si ce arata: terenul de langa drum e PLAT LATERAL (raze
	# cu decorul exclus: la frac 0.05, 64.3 m la 4 m lateral si 63.8 m la 48 m).
	# Deci criticul si constructorul aveau fiecare o jumatate de dreptate — nu
	# exista panta laterala de taiat, DAR asta nu explica rotatia plata, care e
	# in noduri.
	#
	# Reparatia vine din piesa insasi: `stone_stairway` masoara 10.36 x 7.69 x
	# 12.61 m si COBOARA DEJA 7.69 m pe cei 12.61 m de adancime (~31°), de la
	# origine spre -Z. Nu e o dala, e o rampa de trepte. Deci nu trebuie
	# inclinata artificial, trebuie ORIENTATA: coborarea ei se pune pe directia
	# in care coboara lumea, si piesele se INLANTUIE — fiecare incepe unde s-a
	# terminat cea de dinainte, in jos si mai departe de drum.
	#
	# Asa se obtine o scara continua de la 64 m pana la ~40 m, adica exact
	# „cele 18 trepte" din brief: o coborare pe care o vezi in stanga cand
	# treci, nu un pavaj.
	#
	# CUM SE COMPUNE. Piesa coboara spre -Z local. Vrem ca -Z sa arate in jos
	# si in afara: yaw o intoarce cu spatele spre drum (`_yaw_to_road` + PI),
	# iar un mic tangaj suplimentar o aseaza pe panta compusa. Tangajul se
	# aplica INAINTEA yaw-ului (`Basis(UP,yaw) * Basis(X,pitch)`), altfel se
	# roteste in jurul axei lumii si piesa se rasuceste in loc sa se incline.
	var f := 0.048
	# UNDE INCEPE. Nu la `_clear` plus cativa metri: piesa se intinde de la
	# origine spre -Z local pe 12.42 m (AABB pos.z = -12.42), iar
	# `_yaw_to_road(-1) + PI` intoarce acel -Z INAPOI spre drum. Prima versiune
	# a pus originea la 13 m lateral si a trimis coada peste carosabil:
	# `probe_solid` a gasit toate cele 10 bucati „PESTE DRUM", si ProbeRace a
	# dat 61 de repuneri, toate la lat ~ 0 (adica pe mijlocul soselei).
	#
	# Deci originea se aseaza DINCOLO de coada: marginea benzii plus lungimea
	# piesei. Cifra se DERIVA din AABB-ul modelului, nu se alege din ochi.
	const STAIR_REACH := 12.42
	var s_i := 0
	while f < 0.112:
		var st := _at(f)
		# Fiecare bucata pleaca mai jos si mai in afara decat cea dinainte:
		# 7.0 m in jos si 7.5 m lateral per bucata (piesa coboara 7.69 pe 12.61,
		# deci pasii astia o inlantuie fara sa lase praguri in aer).
		var lat := _clear(st, 2.0) + STAIR_REACH + float(s_i) * 7.5
		var p := _off(st, -1.0, lat)
		p.y = (st["pos"] as Vector3).y - 2.0 - float(s_i) * 7.0
		# Tangaj mic in plus (12°), ca sa se citeasca panta si acolo unde
		# inlantuirea e mai lina decat cei 31° proprii ai piesei.
		var basis := Basis(Vector3.UP, _yaw_to_road(st, -1.0) + PI) \
			* Basis(Vector3.RIGHT, deg_to_rad(-12.0))
		_place_basis("chongqing/structures/stone_stairway", "scara", p,
			basis, 1.0)
		s_i += 1
		if s_i > 3:
			s_i = 0
		f += 7.0 / _path.total

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
				FACADE_SLOTS, 1.0, FACADE_TINT)
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
## De ce UNA si nu multe: referinta (bar/D_cornisa.png) e un MASIV cu silueta
## unica, nu un cartier. Trei runde au incercat varianta „mai multe, lipite" —
## 24 de exemplare pe doua randuri — si de fiecare data au produs acelasi
## rezultat: un sir de acoperisuri identice cu pas regulat, adica un gard.
## Hero-ul se defineste prin UNICITATE: din clipa in care vezi doi, niciunul
## nu mai e mare. Vezi comentariul din corpul functiei pentru masuratori.
func _poi_d_cornisa() -> void:
	_open_section("4) Cornisa Hongya Dong")

	# HERO-UL, asezat DE LA BUZA IN JOS. Runda 4 inverseaza runda 3.
	#
	# Ce a fost gresit, si de ce rationamentul „un masiv trebuie sa iasa din
	# cadru pe sus" e o contradictie in termeni: un lucru care ATARNA SUB tine
	# nu poate iesi din cadru pe sus. Runda 3 punea talpa pe terasa (5.7 m) si
	# scala 1.35, deci 64 m de casa care urcau pana la y=70 — cu soseaua la
	# 26 m, doua treimi din hero stateau DEASUPRA soferului. Brieful (§2 D,
	# §8) cere exact opusul: „sub tine, etajele de case pe piloni", incepand
	# la ~5 m sub buza.
	#
	# GEOMETRIA LOCULUI, masurata cu raze pe toata cornisa
	# (`tools/tmp/probe_cornisa.gd`, profil lateral la 2..50 m):
	#   * terenul tine cota drumului pana la ~6 m lateral (buza),
	#   * cade ABRUPT intre 6 si 16 m (la 12 m e deja cu 15-20 m mai jos),
	#   * de la ~18 m incolo e TERASA PLATA la 5.7 m.
	# La frac 0.30 soseaua e la 32.8 m, deci caderea pana la terasa e 27.1 m.
	#
	# CE VEDE CAMERA, si de ce nu se poate „umple caderea" cu piesa la scara
	# mica. Ochiul chase cam sta la ~cota drumului + 3 m si vede 63° in jos:
	# la distanta laterala `d` vede pana la `eye - 1.96*d`. Dar terasa nu
	# ascunde nimic pana jos — raza care atinge marginea terasei (16 m) trece
	# pe sub ea si mai departe, deci la d = 22 m se vede TOT pana la y ≈ -5.6.
	# Adica banda vizibila la 22 m lateral e y ∈ [-5.6, 27.8], unde 27.8 =
	# sosea - HONGYA_DROP. Sunt 33.4 m de fatada, si aia e masura piesei.
	#
	# De aici scara: 33.4 / 47.74 = 0.70, ceea ce da 29.4 m latime — nu 24 m
	# (varianta „incape intre terasa si buza", care facea hero-ul un obiect pe
	# langa care treci) si nu 57 m (varianta care iesea pe sus). Talpa se
	# aseaza la -5.6, adica SUB terasa: partea aia nu se vede si nu trebuie
	# sa se vada, e ce face piesa sa para ca iese din faleza, nu ca sta pe o
	# masa.
	#
	# UNDE. La 0.345, ales cu `tools/tmp/probe_frame.gd` fiindca de acolo
	# piesa e IN FATA la 0.30 (intra in cadru la ~90 m), umple dreapta la
	# 0.32-0.34 si abia dupa 0.37 trece in spate. Un hero trebuie sa se
	# APROPIE cateva secunde, nu sa apara si sa dispara.
	var hst := _at(0.345)
	var hroad: float = (hst["pos"] as Vector3).y
	# Coama la HONGYA_DROP sub buza, talpa la limita pana la care camera vede
	# peste marginea terasei. Ambele cifre vin din masuratori, nu din ochi.
	var htop := hroad - HONGYA_DROP
	var hbase := -5.6
	var hscale := (htop - hbase) / 47.74
	var hp := _off(hst, 1.0, 22.0)
	hp.y = hbase
	# Rotit cu ~35° fata de „cu fata la drum": frontal ar fi un panou, iar din
	# trei sferturi se vad DOUA fete — asa se citeste ca volum, si asa arata si
	# in bara.
	var hn := _place("chongqing/structures/hongya_dong", "hongya_hero",
		hp, _yaw_to_road(hst, 1.0) + deg_to_rad(35.0), hscale)
	# LUMINA: ard FERESTRELE (slotul 30), nu corpul — auriul care scapa dintre
	# lemne intunecate, exact limbajul referintei.
	_light(hn, 2.6)
	# Fara corp fizic: cine cade de pe cornisa trebuie sa CADA si sa fie repus,
	# nu sa aterizeze pe un acoperis la 40 m.
	_meta(hn, "coliziune", "none")

	# AL DOILEA REGISTRU, mai jos si mai departe: inca un exemplar, mai mic,
	# asezat astfel incat coama lui sa fie sub TALPA primului. Nu e repetitie
	# — e ce face bara sa aiba unsprezece etaje in loc de patru: masa continua
	# in jos, si ochiul citeste adancime din suprapunere, nu din dimensiune.
	# Coama lui sta la -4 (adica sub hero) si e la 34 m lateral, unde camera
	# vede pana la y ≈ -20.
	var h2st := _at(0.332)
	var h2top := -3.0
	var h2scale := 0.52
	var h2p := _off(h2st, 1.0, 34.0)
	h2p.y = h2top - 47.74 * h2scale
	var h2n := _place("chongqing/structures/hongya_dong", "hongya_registru2",
		h2p, _yaw_to_road(h2st, 1.0) + deg_to_rad(-22.0), h2scale)
	_light(h2n, 2.6)
	_meta(h2n, "coliziune", "none")

	# CONTRAFORTUL, si de ce e o piesa DIFERITA. Sub hero, mai in afara si mai
	# jos, un `liziba_block` (40.6 x 24.9 m, bloc de locuinte) care ii tine
	# talpa: masa piramidala din bara nu se termina in aer, are sub ea un soclu
	# construit. Piesa e alta ca sa nu repete silueta — repetarea aceleiasi
	# siluete era chiar defectul.
	var cst := _at(0.358)
	var cp := _off(cst, 1.0, 40.0)
	cp.y = 5.7
	var cn := _place("chongqing/buildings/liziba_block", "bloc_contrafort",
		cp, _yaw_to_road(cst, 1.0) + deg_to_rad(-18.0), 1.0)
	_light(cn, 1.6)
	_meta(cn, "coliziune", "none")

	# RESTUL CORNISEI se tine cu piese MARUNTE, nu cu hero-uri. Regula pe care
	# a incalcat-o runda trecuta: pe cornisa mai sunt inca 15 fractii de drum
	# dupa hero, si daca le umpli tot cu `hongya_dong` obtii gardul. Aici merg
	# `shophouse`-uri agatate sub buza — 7.6 m, adica a cincea parte din hero:
	# citesc ca „mai sunt case si dincolo", fara sa concureze cu el.
	#
	# Se opresc la 0.372: pana acolo mai exista faleza sub care sa atarne ceva
	# (sosea 32.5 m la 0.32, terasa 5.7 m). Dupa 0.375 drumul a coborat el insusi
	# la cota terasei (17 m la 0.375, 5.1 m la 0.425 — masurat), deci nu mai e
	# nimic „sub buza": acolo compozitia o face peretele din stanga, care
	# continua.
	var shopc := ["chongqing/buildings/shophouse_a",
		"chongqing/buildings/shophouse_b", "chongqing/buildings/shophouse_c"]
	var uf := 0.255
	var ui := 0
	while uf < 0.372:
		# Sarim fereastra hero-ului: intre 0.330 si 0.362 orice piesa in plus pe
		# dreapta ii ciobeste silueta, si silueta unica e tot ce castigam.
		if uf < 0.330 or uf > 0.362:
			var us := _at(uf)
			var up := _off(us, 1.0, 11.0 + float(ui % 3) * 4.0)
			# Agatate SUB buza, in trepte: coama la 3-9 m sub cota drumului.
			up.y = us["pos"].y - 3.0 - float(ui % 3) * 3.0 - 7.6
			var un := _place(shopc[ui % 3], "casa_sub_buza", up,
				_yaw_to_road(us, 1.0) + deg_to_rad(float((ui % 5) - 2) * 9.0), 1.0)
			_wash(un, FACADE_SLOTS, 1.0, FACADE_TINT)
			_meta(un, "coliziune", "none")
		ui += 1
		uf += 9.0 / _path.total

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
		# Randul din spate: mai departat si rotit, ca sa se vada acoperisuri
		# peste primul rand (adancime), nu o singura linie de fatade.
		if wi % 2 == 0:
			var nb := _place(shopd[(wi + 2) % 3], "casa_cornisa_spate",
				_off_ground(stw, -1.0, 20.5), _yaw_to_road(stw, -1.0)
				+ deg_to_rad(22.0), 1.0)
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
	# Perechea de la 0.432/0.437 a fost scoasa: acolo cornisa se stramteaza si
	# coteste orb, iar TOATE repunerile masurate (frac 0.427-0.436, `atinge: -`)
	# cadeau intre cei doi stalpi. Baza de pe main n-are nimic acolo si da
	# 0/0/0; cu perechea, orice marja incercata (0.3 / 0.8 / 1.4 m) lasa intre
	# 1 si 3 repuneri. Virajul ala se marcheaza cu ce e deja acolo, nu cu inca
	# doi stalpi pe muchie.
	var chevrons := [0.286, 0.291, 0.296, 0.336, 0.341, 0.346,
		0.376, 0.381, 0.394, 0.399, 0.416, 0.421]
	# Marja e 0.8 m, nu 0.3 si nici 1.4. Masurat A/B in acelasi worktree (memoria
	# `proberace-nedeterminism` — se compara distributii, nu o rulare): cu
	# 0.3, seed 1 dadea 2/0/2 repuneri pe trei rulari, iar baza de pe main
	# 0/0/0, toate la frac 0.427 cu `atinge: -`: nimeni nu LOVEA chevronul,
	# masina trecea pe langa el, iesea de pe sosea in virajul orb si ramanea
	# acolo. Dar 1.4 m a fost mai rau (2/2/3 repuneri si 10% in afara
	# soselei, fata de 2%): acolo stalpii ajung FIX pe linia pe care masinile
	# ies larg din viraj, deci nu mai marcheaza marginea, o mineaza.
	for cf: float in chevrons:
		var st2 := _at(cf)
		_place("chongqing/props/chevron_post", "chevron",
			_off_ground(st2, 1.0, _clear(st2, 0.8)), _yaw_to_road(st2, 1.0), 1.0)

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
##
## `side` e latura pe care STA piesa, deci se intoarce spre -right.
func _yaw_to_road(st: Dictionary, side: float) -> float:
	var r: Vector3 = st["right"] * side
	return atan2(-r.x, -r.z)


## UNDE E FATADA unei piese, in spatiul ei local (unghi pe Y).
##
## Nu se deduce dintr-o conventie. Kit-ul Chongqing pune vitrina, copertina,
## balconul si ferestrele pe O SINGURA fata, iar fata aia difera de la piesa
## la piesa: doua deduceri din semne (+Z, apoi -Z) au iesit amandoua pe dos,
## si 139 din 211 de cladiri isi aratau spatele soselei — adica POI-urile
## erau coridoare de pereti gri, exact reprosul „drum gri intre acoperisuri".
##
## Se MASOARA deci: centroidul ariei triunghiurilor din slotul 30 (ferestrele
## aprinse) da directia in care se uita fatada. Cifra se calculeaza o data per
## MODEL si se tine in cache — piesele aceluiasi .glb au aceeasi geometrie.
func _facade_yaw(model: String) -> float:
	if _facade_cache.has(model):
		return _facade_cache[model]
	# Zero inseamna „nu corecta nimic". E raspunsul corect pentru piesele care
	# au ferestre pe DOUA fete: la ele centroidul cade langa origine si unghiul
	# lui e zgomot, nu directie. Se cere deci si o DEPARTARE minima de origine
	# (masurat: shophouse_a/b/c au |xz| ~ 2.1 m, restaurant_front 0.03 m —
	# adica primele au fatada, ultima e simetrica si nu trebuie intoarsa).
	const MIN_OFFSET := 0.5
	var ang := 0.0
	var scn := load("res://assets/models/%s.glb" % model) as PackedScene
	if scn != null:
		var root := scn.instantiate() as Node3D
		var centroid := Vector3.ZERO
		var area := 0.0
		var stack: Array[Node] = [root]
		while not stack.is_empty():
			var x: Node = stack.pop_back()
			for ch in x.get_children():
				stack.append(ch)
			var mi := x as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			for si in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				if uv.is_empty() or ix.is_empty():
					continue
				for k in range(0, ix.size(), 3):
					if int(floor(uv[ix[k]].x * 32.0)) != 30:
						continue
					var ar: float = (v[ix[k + 1]] - v[ix[k]]).cross(
						v[ix[k + 2]] - v[ix[k]]).length() * 0.5
					centroid += (v[ix[k]] + v[ix[k + 1]] + v[ix[k + 2]]) / 3.0 * ar
					area += ar
		root.queue_free()
		if area > 0.0:
			centroid /= area
			centroid.y = 0.0
			if centroid.length() > MIN_OFFSET:
				# `_yaw_to_road` intoarce deja -Z-ul piesei spre drum, deci
				# corectia e fata de -Z (180°), nu fata de +Z. Masurat:
				# shophouse_a/b/c au fatada la 172-180°, adica sunt DEJA bine
				# orientate si corectia lor trebuie sa fie ~0 — cu referinta
				# gresita ar fi fost intoarse cu spatele, si asa am si masurat
				# 115 din 224 „intoarse de la drum" la prima incercare.
				ang = atan2(centroid.x, centroid.z) - PI
				ang = wrapf(ang, -PI, PI)
	_facade_cache[model] = ang
	return ang


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
	# FARA +90°. Aici a stat, doua runde, cauza „nodul nu blocheaza nimic".
	#
	# O runda anterioara a masurat amprenta autobuzului si a gasit-o de 6.5 m
	# pe latimea soselei; a tras concluzia ca piesa sta de-a curmezisul si a
	# adaugat +90° ca s-o intoarca. Amprenta era intr-adevar gresita, dar din
	# alta cauza (yaw-ul se lua din `_Path`, care esantioneaza la ~1.8 m de
	# punctul copt, intr-un loc unde drumul coteste) — cauza reparata separat,
	# mai sus, prin luarea tangentei din punctele COAPTE. Cu ea reparata, +90°
	# a ramas si a intors vehiculele CU ADEVARAT de-a curmezisul: masurat pe
	# corpurile fizice, autobuzul acoperea 10.6 m lateral (adica lungimea lui,
	# nu latimea de 2.68) si masinutele 4.0 m in loc de 1.95. De-aia
	# bulevardul iesea „100% inchis" fara nicio fanta, oricat mutam offseturile.
	#
	# Verificat cu dot, nu dedus (memoria `rotatii-in-builder-semnul`,
	# `tools/tmp/probe_yaw.gd`): `Basis(UP, atan2(fw.x, fw.z)).z` are dot 1.000
	# cu directia de mers, iar cu +90° are dot 0.000.
	return atan2(fw.x, fw.z)


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
## SPALAREA DE FATADA E DEZACTIVATA, si de-aia nu se scrie nimic aici.
##
## Ideea era buna si masurata: peretii kitului sunt 30% slot 11 (`#7692A8`,
## gri-albastru) si 19% slot 29 (gri, luminanta 180), adica exact dominanta
## rece pe care o reclama comparatia cu bara, iar in referinta peretii sunt
## spalati de lumina care iese din pravalii.
##
## Ce lipseste ca sa functioneze e in `palette.gd`, nu aici: cu operatorul
## MULTIPLY emisia finala e `emission * textura`, iar `emission` e NEGRU
## (corect pentru ADD, unde tocmai negrul opreste aprinderea intregii piese),
## deci produsul e zero pe toate sloturile. Verificat: materialul se
## construieste, se aplica pe 132 de fatade si nu schimba NICIUN pixel.
##
## Reparatia (`emission = Color.WHITE` cand `multiply`) a fost incercata si
## data inapoi: `palette.gd` e infrastructura comuna tuturor pistelor, iar
## schimbarea semanticii lui MULTIPLY atinge si lava Stromboli, si orice alt
## material care o foloseste — nu e o decizie care se ia din perimetrul unui
## POI. Pana se ia, nu punem pe 132 de noduri o metadata despre care STIM ca
## nu face nimic: ar arata a lucru facut si ar minti urmatorul care citeste.
func _wash(_node_name: String, _slots: String, _energy: float,
		_tint: String = WARM) -> void:
	pass


## Sloturile spalate pe fatadele kitului chinezesc, intr-un singur loc.
##
## Include si INVELITOAREA (20, 29), cu o culoare inchisa: slotul 29
## (`#B8B4AC`) e cel mai deschis din toata paleta (luminanta 180) si e chiar
## acoperisul, iar camera priveste in jos — deci pe ecran ajunge o mare de
## placi palide exact acolo unde referinta are acoperisuri intunecate si
## fatade luminate. Masurat pe cadrul cornisei: 63.7% din pixeli erau
## gri-albastru, 3.1% calzi.
const FACADE_SLOTS := "3,11,20,28,29"
## Calda SI subunitara: inmulteste zidaria spre chihlimbar si in acelasi timp
## coboara invelitoarea palida (slot 29, luminanta 180) sub jumatate.
const FACADE_TINT := "#B08050"


## Piesele carora li se corecteaza fatada, DUPA NUME, nu dupa „are slot 30".
##
## Filtrul pe slot pare mai general si e o capcana masurata: prinde si scarile,
## si autobuzele nodului de trafic, si pavilionul — toate au ferestre — iar
## rotite intra in carosabil (57 de repuneri si cursa moarta la 0.09 tururi).
## Se corecteaza deci doar peretii de strada, unde „fatada spre drum" chiar e
## intentia.
const FACADE_NAMES := ["pravalie", "casa_cornisa", "casa_sub_buza",
	"restaurant", "bloc_sub_piata", "bloc_contrafort"]


func _place(model: String, base: String, pos: Vector3, yaw: float,
		scl: float) -> String:
	# FATADA SPRE DRUM. `yaw` spune incotro trebuie sa se uite piesa, dar piesa
	# nu isi tine fatada pe -Z: se scade unghiul MASURAT al fatadei ei
	# (`_facade_yaw`), altfel jumatate din kit arata soselei spatele de beton.
	for tag: String in FACADE_NAMES:
		if base.begins_with(tag):
			yaw -= _facade_yaw(model)
			break
	# Baza se ia de la Godot, nu se scrie de mana. Versiunea scrisa de mana
	# folosea (c, 0, -s / s, 0, c), adica TRANSPUSA lui `Basis(UP, yaw)` — deci
	# fiecare piesa iesea rotita in sensul invers fata de unghiul verificat cu
	# `tools/tmp/yaw_check.gd`. Pe stalpi si pe parapete nu se vedea (sunt
	# simetrice), dar autobuzele nodului de trafic stateau de-a curmezisul
	# bulevardului si sonda gasea fanta pe acostament, nu intre ele.
	#
	# Cu `Basis` real, unghiul verificat si unghiul scris in .tscn sunt acelasi
	# lucru prin constructie.
	return _place_basis(model, base, pos, Basis(Vector3.UP, yaw), scl)


## Ca `_place`, dar cu o BAZA data — pentru piesele care nu stau orizontal.
##
## Scara Shibati are nevoie de asta: `stone_stairway` coboara deja 7.69 m pe
## 12.61 m de adancime (masurat), dar terenul de langa drum e PLAT lateral
## (masurat cu raze, 64.3 -> 63.8 pe 48 m), deci o piesa asezata numai cu yaw
## sta orizontal si arata a scandura de terasa. Ca sa coboare, primeste si
## TANGAJ, iar tangajul se compune INAINTEA yaw-ului: `Basis(UP,yaw) * pitch`.
func _place_basis(model: String, base: String, pos: Vector3, basis: Basis,
		scl: float) -> String:
	_n += 1
	var node_name := "%s%d" % [base, _n]
	var b := basis.scaled(Vector3(scl, scl, scl))
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
