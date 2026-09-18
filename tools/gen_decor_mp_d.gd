extends Node
## Generator de decor MANUAL pentru POI D — CASCADA DE TERASE (Track15,
## Machu Picchu, frac 0.42-0.54). Nu e sonda: calculeaza transformarile care
## se lipesc in Track15.tscn sub `DecorManual/ZoneD_Terase`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpD.tscn -- \
##       --out=C:/cale/zoneD.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului masurat si nu genereaza nimic.
##
## CE SE VEDE IN BARA (bara_poi_D.png, deschisa inainte de asezare):
## terase in trepte — benzi de iarba deschisa separate de ZIDURI de piatra
## palida care arunca fiecare o DUNGA de umbra pe treapta de sub ea; o scara
## de piatra care coboara DREPT prin ele; canal de apa pe o parte; lame pe
## trepte; o casa cu acoperis sus. Dungile alb/umbra sunt identitatea.
##
## CIFRELE DE SURVEY (runda 1, D_r1_survey.txt) — compozitia se decide pe ele:
##
## 1. TERENUL E DEJA O CASCADA. Drumul coboara de la -2,9 m (frac 0.410) la
##    -20,0 m (0.540): 17 m pe 13% din traseu, in ZIGZAG cu patru picioare
##    (4 ace, brief §2 D). Pe fiecare picior o parte URCA si cealalta CADE:
##      L1 0.418-0.432 (27,8 m) deal pe DREAPTA  (+3,0 m la 15 m, -4,0 la -15)
##      L2 0.438-0.462 (47,7 m) deal pe STANGA   (+3,8 m la -15, -4,0 la +15)
##      L3 0.468-0.488 (39,7 m) deal pe DREAPTA  (+3,2 m la 15, -4,8 la -15)
##      L4 0.494-0.520 (51,6 m) deal pe STANGA   (+2,2 m la -15, -0,9 la +15)
##    Deci NU trebuie modelat relief: terasele exista, se IMBRACA.
##
## 2. PROFILUL LATERAL ARE DEJA BANCHETE. Masurat pe partea deal, cotele la
##    8/15/25/40 m dau: 0->8 m aproape plat (0-10 grade), 8->15 m RISER
##    (12-23 grade, +1,5..+3,0 m), 15->25 m SELF PLAT (0-1,7 grade), 25->40 m
##    al doilea riser (6-16 grade, +1,7..+4,4 m). Adica shelf-riser-shelf.
##    Zidurile de sprijin se pun la PICIORUL fiecarui riser — ~9 m si ~24 m
##    lateral — iar banda plata dintre ele e terasa de iarba. Asta da dungile
##    din bara fara sa atinga terenul.
##
## 3. SOARELE ACTUAL (-40, 45) DA DUNGILE — remasurat, nu presupus.
##    Lumina merge spre (-0,54, -0,64, -0,54), elevatie 40 deg, umbra pe XZ
##    -> (-0,707, -0,707). Incrucisat cu partea-deal de pe fiecare picior:
##    pe 19 din 23 de fractii esantionate zidul de pe deal isi arunca umbra
##    spre VALE, adica pe treapta de sub el = exact identitatea POI-ului.
##    Cele 4 exceptii (0.465, 0.490, 0.525, 0.530) sunt varfurile de ac, unde
##    drumul e oricum aproape orizontal. NU se cere schimbare de tema.
##
## 4. SCARA COBOARA PE PARTEA VALE, nu pe cea deal: la fiecare picior partea
##    care cade (-4..-6 m la 15 m) e singura pe care o scara de 2,5 m pe
##    treapta are unde sa coboare. In bara scara traverseaza terasele drept —
##    la noi traverseaza taluzul dintre doua picioare de zigzag, ceea ce e
##    aceeasi materie vazuta din masina (bara e LOOK, nu layout).
##
## 5. LAMELE hazard sunt cablate la 0.490-0.498. Decorul meu NU pune nimic in
##    banda acolo; fantanile si lamele decorative stau pe terase.
##
## 6. PE UN ZIGZAG, LATERALUL NU E SPATIU LIBER — e soseaua de dedesubt.
##    Runda 1 a picat ProbeLaneClear cu 63 de probe blocate fata de baza 20,
##    si vinovate erau tocmai zidurile de pe linia DEPARTATA (`zidTerasaSus`,
##    gap 18 m = 27 m de ax). Masurat, picioarele de zigzag sunt la doar
##    21,7-23,1 m unul de altul in cel mai stramt loc:
##      0.420 <-> 0.450: 21,7 m | 0.470 <-> 0.510: 23,1 m
##      0.480 <-> 0.450: 22,7 m | 0.440 <-> 0.480: 27,2 m
##    Deci un zid la 27 m lateral de un picior aterizeaza PE BANDA piciorului
##    de sub el — nu langa drum, ci pe drumul urmator. De aia si fractiile
##    blocate (0.380, 0.410) cadeau in afara intervalului meu.
##    Reparatia nu e „mai putin lateral" pe ghicite, ci o GARDA in generator:
##    `_lane_free` verifica distanta de la amprenta piesei la TOATE punctele
##    coapte ale traseului, nu doar la piciorul curent, si refuza piesa care
##    intra in banda oricarui picior. Cifra de refuz se raporteaza.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneD_Terase"

const F_IN := 0.420
const F_OUT := 0.545

const RES := {
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"inca_stair_a": "s_inca_stair_a",
	"inca_stair_b": "s_inca_stair_b",
	"fountain_basin": "s_fountain_basin",
	"water_channel": "s_water_channel",
	"llama": "s_llama",
	"llama_b": "s_llama_b",
	"llama_c": "s_llama_c",
	"inca_house_b": "s_inca_house_b",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"trail_marker": "s_trail_marker",
	"bromeliad": "s_bromeliad",
	"tree_fern": "s_tree_fern",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
## Scara se cere in METRI si se imparte la cifra de aici.
const HEIGHT := {
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"inca_stair_a": 2.500, "inca_stair_b": 5.000,
	"fountain_basin": 0.600, "water_channel": 0.300,
	"llama": 0.529, "llama_b": 0.529, "llama_c": 0.529,
	"inca_house_b": 2.833,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798,
	"trail_marker": 1.200, "bromeliad": 0.377, "tree_fern": 3.306,
}
## Raza de degajare la baza (m) — masurata, coloana "raza baza".
const BASE_R := {
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"inca_stair_a": 3.16, "inca_stair_b": 6.08,
	"fountain_basin": 1.06, "water_channel": 2.01,
	"llama": 0.30, "llama_b": 0.30, "llama_c": 0.30,
	"inca_house_b": 3.64,
	"moss_boulder_a": 0.37, "moss_boulder_b": 0.94, "moss_boulder_c": 1.73,
	"polylepis_a": 0.61, "polylepis_b": 1.10,
	"trail_marker": 0.29, "bromeliad": 0.46, "tree_fern": 0.30,
}
## SEMI-GROSIMEA laterala (m), pentru testul de banda. `BASE_R` e raza pe
## DIAGONALA (buna la degajarea de la muchie, unde piesa poate fi rotita
## oricum); un zid intins TANGENT la drum ocupa insa doar grosimea lui.
## Din amprentele masurate (baza x X z): inca_wall_b e 6,00 x 0,86, deci
## lateral are 0,43 m, nu 3,02. Cu raza diagonala, un sir de ziduri lipit de
## terasa iesea „in banda" desi statea la 9 m de ax.
const SIDE_R := {
	"inca_wall_a": 0.42, "inca_wall_b": 0.43, "inca_wall_c": 0.43,
	"inca_stair_a": 1.30, "inca_stair_b": 1.30,
	"fountain_basin": 0.50, "water_channel": 0.20,
	"inca_house_b": 2.11,
}
const TRI := {
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"inca_stair_a": 422, "inca_stair_b": 798,
	"fountain_basin": 266, "water_channel": 36,
	"llama": 400, "llama_b": 400, "llama_c": 400,
	"inca_house_b": 496,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098,
	"trail_marker": 76, "bromeliad": 248, "tree_fern": 768,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _lane_reject := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0
var _shadow := Vector3.ZERO


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 140.0
	_rng.seed = 150413
	_survey()
	if not _survey_only:
		_build()
		_write()
	get_tree().quit(0)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


## Profilul real al terenului pe intervalul meu. Cifrele din antet vin de aici.
func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		_shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			_shadow.x, _shadow.z, rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac      ax(x,z)          y_drum  half  side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.01
	while f <= F_OUT + 0.011:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), s.dot(_shadow)])
		f += 0.005


func _step(meters: float) -> float:
	return meters / _total_len


## Picioarele de zigzag masurate la survey: [frac_in, frac_out, semn_deal].
## Semnul e partea pe care terenul URCA (unde merge zidul de sprijin).
const LEGS := [
	[0.418, 0.433, 1.0],
	[0.437, 0.463, -1.0],
	[0.467, 0.489, 1.0],
	[0.493, 0.522, -1.0],
]

## Cele doua linii de zid, la piciorul fiecarui riser masurat (nota 2 din
## antet): riserul de aproape incepe la ~8 m lateral, cel de departe la ~25 m.
## `gap` e de la MUCHIA drumului (semi-latimea 6,0 m), deci 3,0 -> 9,0 m de ax.
const WALL_NEAR_GAP := 3.2
const WALL_FAR_GAP := 18.0


func _build() -> void:
	_terrace_walls()
	_stairs()
	_water()
	_llamas()
	_house()
	_greens()


## ZIDURILE DE TERASA — identitatea POI-ului.
##
## Doua siruri continue pe partea care urca, la piciorul celor doua risere
## masurate. Piesele se INLANTUIE cap la cap (capetele masurate: wall_a ±2,0,
## wall_b ±3,0, wall_c ±1,0, rost 0,0000), deci pasul pe traseu e exact
## lungimea piesei — altfel raman rosturi si zidul citeste a lespezi razlete
## (memoria din POI G: piesele care traverseaza muchia rup zidul).
##
## Inaltimea: 2,5 m, adica treapta ceruta de brief. NU se scaleaza in jos —
## un zid de 1,2 m nu mai arunca dunga de umbra care e identitatea.
##
## Coliziune: implicit `hull` = solid. Asta e INTENTIONAT (brief §2 D:
## „pragul lateral > 0,3 m e zid — aici e intentionat zid, terasa de sub
## tine"). Dar zidul APROPIAT sta la 9,2 m de ax pe un drum cu semi-latimea
## 6,0, deci ramane 3,2 m de umar liber de fiecare parte: rampa intra in zid
## fara prag, iar ProbeLaneClear nu vede nimic in banda.
func _terrace_walls() -> void:
	for leg in LEGS:
		var f0: float = leg[0]
		var f1: float = leg[1]
		var sgn: float = leg[2]
		_wall_run(f0, f1, sgn, WALL_NEAR_GAP, 2.5, "zidTerasa")
		_wall_run(f0 + _step(6.0), f1 - _step(4.0), sgn, WALL_FAR_GAP, 2.5,
			"zidTerasaSus")


## Un sir continuu de zid intre doua fractii, la `gap` de muchie.
## Piesele alterneaza a (4,0 m) / b (6,0 m) / c (2,0 m) ca rostul sa nu cada
## pe acelasi ritm ca al terasei de deasupra.
func _wall_run(f0: float, f1: float, sgn: float, gap: float, h: float,
		base: String) -> void:
	var n := _track.baked.size()
	var f := f0
	var k := 0
	while f < f1:
		var mdl := "inca_wall_b"
		if k % 3 == 1:
			mdl = "inca_wall_a"
		elif k % 3 == 2:
			mdl = "inca_wall_c"
		var seg: float = {"inca_wall_a": 4.0, "inca_wall_b": 6.0,
			"inca_wall_c": 2.0}[mdl]
		var scl := _scale_for(mdl, h)
		# Yaw-ul: piesa are lungimea pe X, deci X-ul ei trebuie sa fie TANGENT
		# la traseu. Tangenta se ia din doua puncte coapte consecutive.
		var i := int(f * float(n)) % n
		var j := (i + 1) % n
		var tg: Vector3 = (_track.baked[j] - _track.baked[i])
		tg.y = 0.0
		tg = tg.normalized()
		var yaw := atan2(tg.x, tg.z) - PI * 0.5
		# Pe un zigzag lateralul ideal poate cadea pe banda piciorului de
		# dedesubt (nota 6). In loc sa pierd bucata, o TRAG SPRE INTERIOR
		# pana incape: sirul ramane continuu, doar ca serpuieste cu terasa —
		# ceea ce e si mai aproape de bara, unde zidurile urmeaza panta.
		var g2 := gap
		while g2 > 1.5:
			if _place_ok(mdl, f, sgn, g2, scl):
				break
			g2 -= 1.5
		_place(mdl, base, f, sgn, g2, yaw, scl)
		f += _step(seg * scl)
		k += 1


## SCARA care taie DREPT prin terase — silueta care face POI-ul.
##
## MASURAT, nu presupus (runda 3). Prima incercare punea scara pe partea
## VALE, ca in bara, si TOATE cele 12 tronsoane au fost refuzate de garda de
## banda. Cauza e geometria zigzagului, nu garda: pe un ac, „la vale de
## piciorul asta" ESTE piciorul urmator. Am masurat unde incape o scara de
## 3 tronsoane care coboara la >=9,5 m de orice ax, si raspunsul e UN SINGUR
## loc pe tot POI-ul:
##   0.440 dreapta  cade -5,5 m  cel mai stramt 18,0 m  INCAPE
##   0.445 dreapta  cade -5,9 m  cel mai stramt  5,5 m  blocat
##   0.470 stanga   cade -6,1 m  cel mai stramt  4,6 m  blocat
##   0.420 stanga   cade -4,0 m  cel mai stramt  1,9 m  blocat
##   (restul, intre 2,6 si 6,2 m — adica pe banda piciorului de sub el)
##
## Deci scara nu poate COBORI in gol: coboara in drumul de dedesubt. Ce se
## face in loc, si e si mai corect incaș: scara URCA riserul de pe partea
## DEAL, legand terasa de langa drum de shelf-ul de deasupra. Acolo nu e
## nicio banda de aparat (riserul urca), iar din masina silueta e aceeasi —
## o banda de trepte care taie perpendicular dungile de zid, exact ce se
## citeste in bara. `inca_stair_a` are 2,50 m, adica FIX inaltimea unei
## terase din brief, deci un tronson = o treapta de terasa.
##
## Cele doua locuri care incap pe vale (0.440 dreapta) pastreaza si scara
## care coboara, cu `inca_stair_b` (5,0 m = doua terase): acolo se vede
## cascada intreaga dintr-o privire.
func _stairs() -> void:
	for leg in LEGS:
		var f0: float = leg[0]
		var f1: float = leg[1]
		var deal: float = leg[2]
		# Scari care URCA riserul de pe deal: trei pe picior, ca sa taie
		# dungile de zid des, ca in bara.
		for t: float in [0.22, 0.50, 0.78]:
			_stair_up(lerpf(f0, f1, t), deal)
	# Singurul loc masurat in care o scara poate COBORI fara sa cada pe
	# banda piciorului de dedesubt (18,0 m liber).
	_stair_run(0.440, 1.0, 3)


## Scara care URCA riserul de pe partea deal: doua tronsoane de 2,5 m, adica
## doua terase, pornind din spatele zidului de langa drum.
func _stair_up(frac: float, sgn: float) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * sgn
	var half := _track.width_at_index(i)
	# Se uita SPRE drum (treptele coboara spre tine), deci yaw-ul e pe -s.
	var yaw := atan2(-s.x, -s.z)
	var lat := half + WALL_NEAR_GAP + 1.6
	var prev_y := -INF
	for k in 2:
		var q := p + s * lat
		var g := _sol_real(q.x, q.z)
		# Scara urca: daca terenul nu s-a ridicat, nu mai e riser de urcat.
		if k > 0 and g < prev_y + 0.8:
			return
		if not _lane_free(Vector3(q.x, g, q.z), 1.30, 2.5):
			_lane_reject += 1
			return
		_raw("inca_stair_a", "scaraUrcare", Vector3(q.x, g, q.z), yaw, 1.0, "")
		prev_y = g
		lat += 3.0


## Scara care COBOARA, cu `inca_stair_b` (5,0 m = doua terase pe tronson).
## Se foloseste doar acolo unde masuratoarea a aratat loc (0.440 dreapta).
func _stair_run(frac: float, sgn: float, flights: int) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * sgn
	var half := _track.width_at_index(i)
	var yaw := atan2(s.x, s.z)
	var lat := half + 2.0
	var prev_y := p.y
	for k in flights:
		var q := p + s * lat
		var g := _sol_real(q.x, q.z)
		# Scara se opreste cand terenul NU MAI COBOARA fata de tronsonul de
		# dinainte: o scara pe plat e un bloc de piatra in iarba.
		if k > 0 and g > prev_y - 1.5:
			return
		# Raza pentru testul de banda e SEMI-LATIMEA piesei (2,60 / 2 = 1,30),
		# nu `BASE_R` (6,08 = raza pe diagonala): o scara asezata cu latimea
		# spre drum ocupa 1,3 m lateral, nu 6.
		if not _lane_free(Vector3(q.x, g, q.z), 1.30, 5.0):
			_lane_reject += 1
			lat += 6.0
			continue
		_raw("inca_stair_b", "scara", Vector3(q.x, g, q.z), yaw, 1.0, "")
		prev_y = g
		lat += 6.0


## CANALUL DE APA pe o parte (bara: dunga de apa care coboara pe langa scara)
## plus cele 16 fantani in trepte cerute de brief.
##
## Canalul merge pe partea deal, lipit de piciorul zidului apropiat: acolo e
## jgheabul care aduna apa de pe terasa. water_channel e 4,0 m lung, 0,3 m
## inalt, coliziune `none` (masuratori §4) — nu poate prinde nicio masina.
func _water() -> void:
	for leg in LEGS:
		var f0: float = leg[0]
		var f1: float = leg[1]
		var sgn: float = leg[2]
		var n := _track.baked.size()
		var f := f0 + _step(2.0)
		while f < f1:
			var i := int(f * float(n)) % n
			var j := (i + 1) % n
			var tg: Vector3 = (_track.baked[j] - _track.baked[i])
			tg.y = 0.0
			tg = tg.normalized()
			var yaw := atan2(tg.x, tg.z) - PI * 0.5
			_place("water_channel", "canal", f, sgn, WALL_NEAR_GAP - 1.6,
				yaw, 1.0, "none", 0.05)
			f += _step(4.0)
	# 16 fantani in trepte, sirul de la 0.470 in jos pe partea deal a lui L3:
	# bara le arata ca o coloana de bazine unul sub altul, langa scara.
	var fb := 0.470
	for k in 16:
		var side: float = 1.0 if k < 8 else -1.0
		var f: float = fb + _step(3.0 * float(k % 8))
		if k >= 8:
			f = 0.498 + _step(3.0 * float(k % 8))
		_place("fountain_basin", "fantana", f, side,
			WALL_NEAR_GAP + 1.0 + 0.8 * float(k % 8), 0.0, 1.0, "none", 0.0)


## LAMELE de decor pe trepte (bara: patru lame albe stand pe terase).
## Coliziune `none` (masuratori §4: raza 0,30 m, ar fi pietroi invizibil).
## NU se pun pe banda si nu se pun la 0.490-0.498, unde trec lamele-hazard.
func _llamas() -> void:
	var mdl: Array[String] = ["llama", "llama_b", "llama_c"]
	var k := 0
	for leg in LEGS:
		var f0: float = leg[0]
		var f1: float = leg[1]
		var sgn: float = leg[2]
		for t: float in [0.22, 0.52, 0.80]:
			var f: float = lerpf(f0, f1, t)
			if f > 0.486 and f < 0.502:
				continue
			# Lama sta PE terasa: pe shelf-ul plat de la 15-25 m lateral.
			_place(mdl[k % 3], "lama", f, sgn,
				_rng.randf_range(8.0, 15.0), _rng.randf_range(0.0, TAU),
				2.6, "none")
			k += 1


## CASA SUS (bara: o casa cu acoperis in varful teraselor).
## inca_house_b, pe shelf-ul cel mai inalt al primului picior — se vede in
## fata cand intri in POI, ca in bara.
func _house() -> void:
	# Laturile sunt MASURATE, nu alese din ochi: la runda 3 ambele case au
	# fost refuzate fiindca stateau pe partea pe care trece piciorul de sub
	# ele. Cautarea „cel mai mare lateral care lasa >=11,6 m pana la orice
	# ax" da, pe partea deal a fiecarui picior:
	#   0.427 dreapta 24 m liber 24,0 | 0.505 dreapta 24 m liber 24,0
	# (0.505 STANGA, cum era, avea sub 11,6 — de aia pica).
	_house_at(0.427, 1.0, 24.0, 2.4, 1.6, "casaTerase")
	_house_at(0.505, 1.0, 24.0, -0.9, 1.4, "casaTeraseB")


## Casa se trage spre interior pana incape (nota 6), ca zidurile.
func _house_at(f: float, sgn: float, gap: float, yaw: float, scl: float,
		base: String) -> void:
	var g := gap
	while g > 8.0:
		if _place_ok("inca_house_b", f, sgn, g, scl):
			break
		g -= 2.0
	_place("inca_house_b", base, f, sgn, g, yaw, scl)


## VERDELE: queñual (polylepis) pe marginea teraselor si cativa bolovani cu
## muschi la piciorul riserelor — in bara marginea din dreapta e o coama de
## copaci, iar terasele au pietre la capete. Se refolosesc clasele existente
## (macchia pe verde, inca_stone pe piatra): NICIUN material nou.
func _greens() -> void:
	for leg in LEGS:
		var f0: float = leg[0]
		var f1: float = leg[1]
		var sgn: float = leg[2]
		var f := f0
		var k := 0
		while f < f1:
			# Copacii pe partea VALE, departe: coama de pe marginea cadrului.
			if _rng.randf() < 0.55:
				var mdl := "polylepis_b" if k % 3 == 0 else "polylepis_a"
				_place(mdl, "quenual", f, -sgn,
					_rng.randf_range(14.0, 30.0), _rng.randf_range(0.0, TAU),
					_scale_for(mdl, _rng.randf_range(4.5, 7.5)), "trunk")
			# Bolovani la piciorul riserului, pe deal.
			if _rng.randf() < 0.35:
				var b: String = ["moss_boulder_a", "moss_boulder_b",
					"moss_boulder_c"][k % 3]
				_place(b, "bolovan", f + _step(3.0), sgn,
					_rng.randf_range(10.0, 22.0), _rng.randf_range(0.0, TAU),
					1.0)
			f += _step(9.0)
			k += 1


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Marja peste semi-latime in care ProbeLaneClear inca vede piesa: sonda
## plimba cutia masinii (2,2 x 1,4 x 4,2) la lat = 0 si ±half/3, deci la
## half/3 + 1,1 = 3,1 m de ax pe un drum cu half 6,0 — plus 6,0 m de
## anticipare pe directia de mers. 2,2 m peste muchie acopera si cutia si
## jocul de esantionare fara sa impinga zidul in fundal.
const LANE_MARGIN := 2.2


## Ar incapea piesa la `gap` de muchie, fara sa intre in banda niciunui
## picior? Acelasi calcul ca `_place`, dar fara sa scrie nimic — se
## foloseste ca sa cauti lateralul care incape.
func _place_ok(model: String, frac: float, side_sign: float, gap: float,
		scl: float) -> bool:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var q := p + s * (half + gap + r)
	var g := _sol_real(q.x, q.z)
	var lr: float = float(SIDE_R.get(model, BASE_R.get(model, 0.6))) * scl
	return _lane_free(Vector3(q.x, g, q.z), lr,
		float(HEIGHT.get(model, 1.0)) * scl)


## E LIBERA BANDA pentru o piesa cu amprenta `r` la `pos`?
##
## Testul e fata de TOATE punctele coapte ale traseului, nu doar fata de
## piciorul pe care se aseaza piesa (nota 6 din antet): pe un zigzag cu
## picioarele la 21,7 m unul de altul, un lateral de 27 m cade pe banda de
## sub tine. Verticala conteaza: un zid care sta cu 6 m mai jos decat o
## sosea nu e in banda ei, e sub ea — altfel niciun zid de terasa n-ar mai
## incapea nicaieri.
func _lane_free(pos: Vector3, r: float, h: float) -> bool:
	var n := _track.baked.size()
	for i in n:
		var p: Vector3 = _track.baked[i]
		var dy := pos.y - p.y
		# Singura scapare cinstita pe verticala: piesa e in INTREGIME sub
		# cota soselei, adica pe terasa de dedesubt. Atunci cutia masinii
		# (0..1,4 m peste banda) trece pe deasupra ei si n-o atinge.
		# „Piesa e mult DEASUPRA drumului" NU e o scapare — un zid la +3 m
		# peste sosea tot blocheaza banda; sonda plimba cutia pe carosabil,
		# nu pe cota piesei.
		if dy + h < 0.0:
			continue
		var dx := pos.x - p.x
		var dz := pos.z - p.z
		var need: float = _track.width_at_index(i) + LANE_MARGIN + r
		if dx * dx + dz * dz < need * need:
			return false
	return true


## Aseaza la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA drumului
## pana la marginea piesei. Cota din raycast pe terenul real.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "",
		dy: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if d - r < half + 0.3:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	# Garda de banda pe TOT traseul (nota 6): piesele fantoma nu conteaza,
	# n-au corp care sa opreasca masina.
	if mode != "none":
		var hh: float = HEIGHT.get(model, 1.0) * scl
		var lr: float = float(SIDE_R.get(model, BASE_R.get(model, 0.6))) * scl
		if not _lane_free(Vector3(q.x, g + dy, q.z), lr, hh):
			_lane_reject += 1
			return
	_raw(model, base, Vector3(q.x, g + dy, q.z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, s, scl, -s, c, pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate de garda de banda, %d avertismente, ~%d triunghiuri" % [_n, _lane_reject, _warn, _tri])
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala (TerrainBody), nu din campul neted
## (memoria terrain-mesh-y-extrapoleaza).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
