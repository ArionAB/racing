extends Node
## Generator de decor MANUAL pentru POI A — PIATA SACRA (Track15, Machu Picchu,
## frac 0.96-0.06 cu trecere prin 0 — grila e la frac 0.00).
## Nu e sonda: e unealta care CALCULEAZA transformarile ce se lipesc in
## Track15.tscn sub `DecorManual/ZoneA_PiataSacra`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpA.tscn -- \
##       --out=C:/cale/zoneA.part [--survey]
##
## MASURATOAREA (--survey, runda 1, A_r1_survey.txt). Cifrele de mai jos
## decid compozitia; nu sunt copiate din brief.
##
## 1. PIATA E UN PLATOU, NU O PANTA. Pe frac -0.010 .. +0.050 (adica ~119 m
##    de traseu) solul sta intre -0.3 si +1.0 m fata de sosea pana la ±55 m
##    lateral, pe AMBELE parti. Deci incintele NU trebuie sapate sau urcate
##    pe taluz: se aseaza pe teren, iar zidul de 2,5 m e zid pe toata
##    lungimea lui. (Prin contrast, la frac -0.020..-0.040 solul cade la
##    -11 m pe partea `side` negativa: acolo e deja cornisa lui H, nu piata.)
##
## 2. SEMI-LATIMEA E 9,0 m de la frac -0.020 la +0.050 (`custom_width_segments`
##    (0.9802, 0.0513, 9)). E cel mai lat punct al pistei si e RESPIRO: gardul
##    de decor pleaca de la 3,0 m de MUCHIE (12 m de ax) in sus, ca banda sa
##    ramana libera si `ProbeLaneClear` sa nu urce peste baza de 20.
##
## 3. MANA. `_side_at` = dir.cross(UP); la frac 0.00 dir = +X, deci
##    side = +Z. In Godot `right = up.cross(forward) = -Z`. Adica
##    **`side` pozitiv e STANGA soferului**, `side` negativ e DREAPTA.
##    Brief-ul cere Templul celor Trei Ferestre pe STANGA -> side = +1.
##
## 4. SOARELE. rot (-40, 45, 0); lumina merge spre (-0.54, -0.64, -0.54),
##    elevatie 40 grade, umbra pe XZ -> (-0.707, -0.707). Pe drumul de la
##    frac 0.00 (dir = +X, side = +Z) dot(side, umbra) = **-0.71**: umbra
##    cade spre `-side`, adica spre DREAPTA soferului. Consecinta de
##    compozitie: zidurile de pe **stanga** (side = +1) isi arunca umbra
##    PESTE piata si peste sosea — acolo se pune incinta cea mai densa, ca
##    dungile de umbra (identitatea pistei, brief §4) sa se vada din masina.
##    Un zid de 2,5 m la 40 de grade arunca umbra de 2,98 m.
##
## 5. LATURA DINSPRE GOL. La frac -0.005..+0.005 solul de pe `-side` cade la
##    -12 m de la 40 m incolo (marginea defileului). Deci incinta din dreapta
##    se opreste la 30 m de ax, iar mai departe nu se pune nimic care sa
##    pluteasca. Pe `+side` platoul tine pana la +70 m: al doilea etaj de
##    incinte si casele merg acolo.
##
## 6. FRACTIA DE INTRARE. Zona incepe la -0.010 (unde platoul incepe si
##    latimea e deja 9 m) si tine pana la +0.050, unde soseaua urca la
##    +7,6 m si intra deja in POI B (`custom_step_ranges` incepe la 0.0405).
##    Ultimele piese (0.040-0.050) se rarefiaza: e poarta de iesire din
##    cetate, nu inca piata.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneA_PiataSacra"

## Intervalul zonei, in fractii. Trece prin 0.0 (start/finish), deci se
## lucreaza cu fractii NEGATIVE si se normalizeaza in `_place`.
const F_IN := -0.040
const F_OUT := 0.050

## id-urile ext_resource din Track15.tscn (fundatia, §1).
const RES := {
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"three_windows": "s_three_windows",
	"sun_temple": "s_sun_temple",
	"intihuatana": "s_intihuatana",
	"inca_house_a": "s_inca_house_a",
	"inca_house_b": "s_inca_house_b",
	"guardhouse": "s_guardhouse",
	"fountain_basin": "s_fountain_basin",
	"water_channel": "s_water_channel",
	"llama": "s_llama",
	"llama_b": "s_llama_b",
	"llama_c": "s_llama_c",
	"trail_marker": "s_trail_marker",
	"inca_stair_a": "s_inca_stair_a",
	"inca_stair_b": "s_inca_stair_b",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"tree_fern": "s_tree_fern",
	"bromeliad": "s_bromeliad",
	"orchid_cluster": "s_orchid_cluster",
}

## Inaltimea REALA a piesei (m), din docs/asset_briefs/machu_picchu_masuratori.md
## §1. Scara se cere in METRI si se imparte la cifra de aici, nu din burta.
const HEIGHT := {
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"three_windows": 4.000, "sun_temple": 5.586, "intihuatana": 2.720,
	"inca_house_a": 4.825, "inca_house_b": 2.833, "guardhouse": 7.878,
	"fountain_basin": 0.600, "water_channel": 0.300,
	"llama": 0.529, "llama_b": 0.529, "llama_c": 0.529,
	"trail_marker": 1.200,
	"inca_stair_a": 2.500, "inca_stair_b": 5.000,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "tree_fern": 3.306,
	"bromeliad": 0.377, "orchid_cluster": 0.390,
}
## Lungimea piesei pe axa X la scara 1 (m) — pentru INLANTUIRE. Capetele
## zidurilor sunt la ±L/2 cu rost 0.0000 (contractul kitului): doua ziduri
## puse la distanta L (a lor, mediata) se ating exact.
const LEN_X := {
	"inca_wall_a": 4.00, "inca_wall_b": 6.00, "inca_wall_c": 2.00,
}
## Raza de DEGAJARE la sol (m) la scara 1: jumatatea laturii mici pentru
## ziduri (grosimea), raza de baza masurata pentru restul.
const BASE_R := {
	"inca_wall_a": 0.42, "inca_wall_b": 0.43, "inca_wall_c": 0.43,
	"three_windows": 0.58, "sun_temple": 3.80, "intihuatana": 3.00,
	"inca_house_a": 3.58, "inca_house_b": 3.64, "guardhouse": 4.01,
	"fountain_basin": 1.06, "water_channel": 0.20,
	"llama": 0.30, "llama_b": 0.30, "llama_c": 0.30,
	"trail_marker": 0.29,
	"inca_stair_a": 1.50, "inca_stair_b": 3.00,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "tree_fern": 0.30,
	"bromeliad": 0.46, "orchid_cluster": 0.17,
}
## Triunghiuri per piesa (masuratori §1) — pentru raportul de buget.
const TRI := {
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"three_windows": 540, "sun_temple": 1108, "intihuatana": 492,
	"inca_house_a": 548, "inca_house_b": 496, "guardhouse": 504,
	"fountain_basin": 266, "water_channel": 36,
	"llama": 400, "llama_b": 400, "llama_c": 400,
	"trail_marker": 76,
	"inca_stair_a": 422, "inca_stair_b": 798,
	"moss_boulder_a": 200, "moss_boulder_b": 242,
	"polylepis_a": 598, "polylepis_b": 1098, "tree_fern": 768,
	"bromeliad": 248, "orchid_cluster": 410,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1985.6


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
	_sus_y = hi + 150.0
	_rng.seed = 150901
	_survey()
	if not _survey_only:
		_build()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var sun := _find_sun(_track)
	var shadow := Vector3.ZERO
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, shadow.x, shadow.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac      ax(x,z)          y_drum  half  side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN
	while f <= F_OUT + 0.0001:
		var i := _idx(f)
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-90.0, -70.0, -55.0, -40.0, 40.0, 55.0, 70.0, 90.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %+.3f  (%7.1f,%7.1f)  %5.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), s.dot(shadow)])
		f += 0.005


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ compozitia

## ------------------------------------------------------------------
## INCINTELE. Ce face cetatea sa citeasca drept cetate (contractul POI-ului)
## sunt dreptunghiurile INCHISE, nu segmentele razlete. De aceea zidurile nu
## se aseaza bucata cu bucata: se cere o incinta prin (colt, latura, latime,
## adancime, rotatie) si `_enclosure` o inlantuie singura din `inca_wall_a`
## (4,00 m), `_b` (6,00 m) si `_c` (2,00 m).
##
## Inlantuirea e exacta: capetele piesei sunt la ±L/2 cu rost 0,0000
## (masuratori §1), deci doua piese cu centrele la distanta (L1+L2)/2 se
## ating fara suprapunere si fara gol. `_wall_run` alege piesele dintr-o
## lungime data astfel incat suma sa fie EXACT lungimea ceruta cand se poate,
## si sa nu depaseasca niciodata (un zid mai lung ar iesi din incinta si ar
## rupe dreptunghiul).
##
## GOLURILE sunt intentionate: o incinta incasa are o usa. Fiecare latura
## primeste cel mult o poarta de 2,0-3,0 m, niciodata pe latura dinspre drum
## la incintele lipite de banda (acolo golul ar arata ca un zid rupt, nu ca
## o intrare).

## O latura de incinta: de la `a` la `b` (ambele in XZ, y din teren), cu
## inaltimea `h` (m). `gate_t` in (0,1) = centrul portii pe latura, sau -1
## pentru latura plina.
func _wall_side(a: Vector2, b: Vector2, h: float, gate_t: float,
		gate_w: float, tag: String) -> void:
	var d := b - a
	var total := d.length()
	if total < 1.0:
		return
	var u := d / total
	var yaw := atan2(u.y, u.x)
	# Segmentele de umplut: unul singur, sau doua daca e poarta.
	var segs: Array[Vector2] = []  # [t0, t1] in metri de la `a`
	if gate_t <= 0.0 or gate_w <= 0.0:
		segs.append(Vector2(0.0, total))
	else:
		var gc := gate_t * total
		var g0 := maxf(0.0, gc - gate_w * 0.5)
		var g1 := minf(total, gc + gate_w * 0.5)
		if g0 > 0.6:
			segs.append(Vector2(0.0, g0))
		if total - g1 > 0.6:
			segs.append(Vector2(g1, total))
	for seg in segs:
		_wall_run(a + u * seg.x, u, seg.y - seg.x, yaw, h, tag)


## Inlantuie piese pe directia `u` pornind din `start`, pe lungimea `length`.
## Alegerea e greedy pe piesa cea mai lunga care incape; restul sub 2,0 m se
## umple cu `inca_wall_c` scalat pe X? NU — scalarea neuniforma ar deforma
## piatra. Sub 2,0 m ramane gol: un rost de 1 m intr-un zid incas e o nisa,
## nu o greseala, iar deformarea s-ar vedea (memoria
## `accentul-de-slot-depinde-de-forma`).
func _wall_run(start: Vector2, u: Vector2, length: float, yaw: float,
		h: float, tag: String) -> void:
	var t := 0.0
	var guard := 0
	while length - t >= 1.95 and guard < 200:
		guard += 1
		var mdl := "inca_wall_c"
		if length - t >= 6.0:
			mdl = "inca_wall_b"
		elif length - t >= 4.0:
			mdl = "inca_wall_a"
		var l: float = LEN_X[mdl]
		var scl := _scale_for(mdl, h)
		# Piesa se scaleaza UNIFORM (scara e una singura in `_raw`), deci
		# lungimea ei reala pe teren e l * scl. Cu h = 2,5 m si inaltimea
		# nominala 2,487 m, scl ~ 1,005: lungimile raman practic nominale.
		var real_l := l * scl
		if t + real_l > length + 0.25:
			# Nu incape la scara asta: incearca piesa urmatoare mai mica.
			if mdl == "inca_wall_b":
				mdl = "inca_wall_a"
			elif mdl == "inca_wall_a":
				mdl = "inca_wall_c"
			else:
				break
			l = LEN_X[mdl]
			scl = _scale_for(mdl, h)
			real_l = l * scl
			if t + real_l > length + 0.25:
				break
		var c := start + u * (t + real_l * 0.5)
		_at(mdl, tag, c.x, c.y, yaw, scl, "", -0.12)
		t += real_l


## O incinta dreptunghiulara. `c` = centrul, `w` x `dpt` metri, rotita cu
## `rot` (radiani). `gates` = array de 4 fractii (una per latura, -1 = plin),
## in ordinea: +u (fata), +v (dreapta), -u (spate), -v (stanga).
func _enclosure(c: Vector2, w: float, dpt: float, rot: float, h: float,
		gates: Array, tag: String) -> void:
	var u := Vector2(cos(rot), sin(rot))
	var v := Vector2(-sin(rot), cos(rot))
	var hw := w * 0.5
	var hd := dpt * 0.5
	var p0 := c - u * hw - v * hd
	var p1 := c + u * hw - v * hd
	var p2 := c + u * hw + v * hd
	var p3 := c - u * hw + v * hd
	_wall_side(p0, p1, h, float(gates[0]), 2.6, tag)
	_wall_side(p1, p2, h, float(gates[1]), 2.6, tag)
	_wall_side(p2, p3, h, float(gates[2]), 2.6, tag)
	_wall_side(p3, p0, h, float(gates[3]), 2.6, tag)


## Punctul din lume la (frac, lateral de la AX), in XZ. Toata compozitia se
## exprima asa: fractie + parte + gol fata de muchie, niciodata XYZ absolut.
func _pt(frac: float, lat: float) -> Vector2:
	var a := _axis(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = a["s"]
	var q := p + s * lat
	return Vector2(q.x, q.z)


## Unghiul (in lume) al directiei de mers la fractia data — incintele se
## aliniaza cu drumul, ca sa citeasca drept cartier, nu drept moloz.
func _yaw_at(frac: float) -> float:
	var a := _axis(frac)
	var f: Vector3 = a["fwd"]
	return atan2(f.z, f.x)


func _build() -> void:
	_incinte_stanga()
	_incinte_dreapta()
	_temple()
	_movila_intihuatana()
	_case()
	_apa()
	_lame()
	_verde()


## STANGA (side = +1) e latura cu UMBRA peste piata (masuratoare 4) si cu
## platoul cel mai lat (+70 m). Aici sta cartierul dens: patru incinte
## lipite intr-o grila, ca terasele de sus din bara — nu patru dreptunghiuri
## risipite, ci un CAMP de incinte cu ziduri comune la 1,5-2,5 m.
func _incinte_stanga() -> void:
	# Randul I, lipit de piata: incinte mici (14 x 11 m), la 14 m de ax
	# (5 m de muchie). Umbra lor de 2,98 m cade spre drum.
	var f0 := 0.000
	var specs := [
		# [frac_centru, lat_centru, w, dpt, inaltime, porti]
		[-0.0045, 20.0, 15.0, 12.0, 2.5, [-1.0, 0.5, -1.0, -1.0]],
		[0.0025, 20.0, 13.0, 12.0, 2.5, [-1.0, -1.0, 0.45, -1.0]],
		[0.0095, 20.5, 14.0, 12.0, 2.4, [-1.0, 0.55, -1.0, -1.0]],
		[0.0165, 21.0, 13.0, 12.0, 2.5, [0.5, -1.0, -1.0, -1.0]],
	]
	for sp: Array in specs:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_enclosure(c, float(sp[2]), float(sp[3]), _yaw_at(fr), float(sp[4]),
			sp[5] as Array, "zidStg")
	# Randul II, in spate, la 36-38 m de ax: incinte mai MARI (20 x 16 m).
	# Sunt al doilea etaj de citit din masina — peste coronamentul randului I
	# (2,5 m) se vede zidul lor de 2,9 m de la 36 m, deci campul are adancime.
	var specs2 := [
		[-0.0035, 37.0, 21.0, 16.0, 2.9, [-1.0, 0.5, -1.0, -1.0]],
		[0.0065, 37.5, 20.0, 16.0, 2.9, [-1.0, -1.0, 0.5, -1.0]],
		[0.0165, 38.0, 20.0, 16.0, 2.8, [0.5, -1.0, -1.0, -1.0]],
	]
	for sp: Array in specs2:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_enclosure(c, float(sp[2]), float(sp[3]), _yaw_at(fr), float(sp[4]),
			sp[5] as Array, "zidStgB")
	# Terasa de sprijin: un zid LUNG, continuu, care taie campul de incinte
	# pe lungime la 29 m de ax. In bara, ce leaga incintele intre ele e exact
	# o linie lunga de zid orizontal — fara ea, incintele plutesc.
	var a := _pt(-0.0085, 29.0)
	var b := _pt(0.0225, 29.0)
	_wall_side(a, b, 2.6, -1.0, 0.0, "terasaStg")


## DREAPTA (side = -1) e latura dinspre GOL: platoul tine doar pana la ~30 m
## de ax la frac 0.00 (masuratoare 5), apoi cade la -12 m. Deci aici NU e loc
## pentru un al doilea rand: doua incinte lipite de banda si un zid de
## margine care le leaga, si dincolo de el prapastia se vede.
func _incinte_dreapta() -> void:
	var specs := [
		[-0.0030, -19.0, 15.0, 11.0, 2.5, [-1.0, -1.0, -1.0, 0.5]],
		[0.0055, -19.5, 14.0, 11.0, 2.4, [-1.0, -1.0, 0.5, -1.0]],
		[0.0140, -19.0, 13.0, 11.0, 2.5, [-1.0, -1.0, -1.0, 0.5]],
	]
	for sp: Array in specs:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_enclosure(c, float(sp[2]), float(sp[3]), _yaw_at(fr), float(sp[4]),
			sp[5] as Array, "zidDr")
	# Zidul de margine dinspre defileu: linia care opreste ochiul inainte de
	# gol si da cetatii un contur. La 28 m de ax, pe toata zona.
	var a := _pt(-0.0075, -28.0)
	var b := _pt(0.0205, -28.0)
	_wall_side(a, b, 2.2, 0.62, 3.0, "terasaDr")


## TEMPLELE. Brief: Trei Ferestre pe STANGA, Templul Principal (sun_temple)
## pe dreapta, grila intre ele. Amandoua se aseaza cu FATA spre drum: piesele
## sunt orientate pe axa X (lungimea AABB: three_windows 10,00 x 1,15,
## sun_temple 8,79 x 7,59), deci yaw-ul lor e yaw-ul drumului.
func _temple() -> void:
	# Trei Ferestre: 4,0 m inalt, 10 m lung — o fatada. La 5,5 m de muchie
	# (14,5 m de ax) e destul de aproape ca cele trei nise trapezoidale sa
	# se citeasca din masina, si destul de departe de banda de 9 m.
	var f := -0.0005
	var c := _pt(f, 15.5)
	_at("three_windows", "treiFerestre", c.x, c.y, _yaw_at(f), 1.0, "", -0.10)
	# Templul Principal (sun_temple, zid curb, 5,59 m): pe dreapta, la 17 m
	# de ax. E cea mai inalta piesa de piatra din piata dupa paznic, deci sta
	# in fata incintei din dreapta ca sa nu fie ascuns de ea.
	var f2 := 0.0020
	var c2 := _pt(f2, -16.5)
	_at("sun_temple", "templulSoarelui", c2.x, c2.y, _yaw_at(f2) + PI * 0.5,
		1.0, "", -0.12)


## INTIHUATANA pe movila. Capcana declarata: e langa grila si masinile o pot
## atinge, iar treptele au varfuri partajate (pragurile > 0,3 m sunt ZIDURI
## pentru fizica intreaga). Deci nu se pune pe banda si nici pe umar: sta la
## 13,5 m de ax (4,5 m de MUCHIE, raza ei de baza 3,0 m -> marginea la 10,5 m
## de ax, adica 1,5 m dincolo de muchie), pe partea STANGA, in fata-sus.
## Movila e platforma ei: doua incinte concentrice mici de zid scund, exact
## soclul din bara. `intihuatana` ramane `hull` (2 sloturi, ambele piatra).
func _movila_intihuatana() -> void:
	var f := 0.0215
	var c := _pt(f, 17.0)
	# Soclul: doua inele patrate de zid scund (1,2 si 0,9 m), concentrice.
	_enclosure(c, 16.0, 14.0, _yaw_at(f), 1.3, [-1.0, 0.5, -1.0, -1.0], "soclu")
	_enclosure(c, 9.0, 8.0, _yaw_at(f), 1.0, [0.5, -1.0, -1.0, -1.0], "socluB")
	# Piatra-ceas in mijloc, ridicata cu 1,0 m ca sa stea PE soclu, nu langa.
	_at("intihuatana", "intihuatana", c.x, c.y, _yaw_at(f) + 0.35, 1.0, "", 0.95)
	# Trepte de urcare pe soclu, dinspre drum: `inca_stair_a` 2,50 m inalt,
	# scalata la 1,05 m ca sa ajunga exact pe coronamentul inelului mare.
	var st := _pt(f - 0.0022, 14.5)
	_at("inca_stair_a", "trepteSoclu", st.x, st.y, _yaw_at(f) + PI * 0.5,
		_scale_for("inca_stair_a", 1.05), "", -0.05)


## CASELE cu acoperis de paie. Bara are DOUA. Paiele aurii sunt singura
## culoare calda din camp, deci pozitia lor decide unde se uita ochiul:
## una in campul de incinte din stanga (in a doua incinta, ca sa se vada
## peste zidul de 2,5 m — casa are 4,83 m), una pe movila din dreapta-fata.
## `guardhouse` (7,88 m) e prea inalt pentru piata — el e la POI C, pe
## creasta; aici ar fi mancat silueta templului.
func _case() -> void:
	var f := 0.0025
	var c := _pt(f, 20.0)
	_at("inca_house_a", "casaPaie", c.x, c.y, _yaw_at(f) + PI * 0.5, 1.0, "", -0.10)
	var f2 := 0.0140
	var c2 := _pt(f2, -19.0)
	_at("inca_house_a", "casaPaieB", c2.x, c2.y, _yaw_at(f2) - PI * 0.25,
		0.92, "", -0.10)
	# Doua ruine fara acoperis (inca_house_b, 2,83 m) in randul II din stanga:
	# dau scara si diferenta „casa intreaga / casa cazuta" din bara.
	var f3 := -0.0035
	var c3 := _pt(f3, 37.0)
	_at("inca_house_b", "ruina", c3.x, c3.y, _yaw_at(f3) + 0.2, 1.0, "", -0.12)
	var f4 := 0.0175
	var c4 := _pt(f4, 38.0)
	_at("inca_house_b", "ruinaB", c4.x, c4.y, _yaw_at(f4) - 0.3, 1.0, "", -0.12)


## APA. Canalul incas e piesa care spune „asta e un oras, nu o ruina": un
## jgheab de 4 m (`water_channel`, 0,30 m inalt, coliziune `none` — un prag
## de 30 cm pe linia de curs ar fi zid). Se pun bucati cap la cap, paralel
## cu banda, la 11,5 m de ax pe dreapta, plus trei fantani in trepte.
func _apa() -> void:
	var f := -0.0060
	var k := 0
	while f < 0.0180:
		var c := _pt(f, -11.5)
		_at("water_channel", "canal", c.x, c.y, _yaw_at(f), 1.0, "none", -0.02)
		f += _step(3.98)
		k += 1
	for fr: float in [-0.0040, 0.0040, 0.0120]:
		var cb := _pt(fr, -13.2)
		_at("fountain_basin", "fantana", cb.x, cb.y, _yaw_at(fr) + PI * 0.5,
			1.0, "", -0.05)


## LAMELE care pasc. Nu sunt hazard aici (cele patru de pe terase sunt deja
## cablate pe `SlidingHazard` la POI D): astea sunt decor static, coliziune
## `none` (0,53 m, sub linia capotei). Scara: 3,135, aceeasi ca la hazard,
## adica ~1,66 m inaltime — o lama adevarata.
func _lame() -> void:
	var s := _scale_for("llama", 1.66)
	var poz := [
		["llama", 0.0075, 13.5, 0.8],
		["llama_b", 0.0100, 15.5, 2.1],
		["llama_c", -0.0015, -13.0, 3.4],
		["llama", 0.0185, 24.0, 5.0],
		["llama_b", -0.0055, 25.0, 1.2],
	]
	for p: Array in poz:
		var fr: float = p[1]
		var c := _pt(fr, float(p[2]))
		_at(String(p[0]), "lama", c.x, c.y, _yaw_at(fr) + float(p[3]), s,
			"none", 0.0)


## VERDELE. Piata din bara e IARBA cu piatra peste, nu piatra cu iarba: deci
## vegetatia e rara si scunda in incinte, si se ingroasa abia la marginea
## platoului, unde incepe padurea de nori. Doi queñuali (polylepis) marcheaza
## intrarea in cetate dinspre H, cativa bolovani cu muschi si bromelii dau
## pestrit la baza zidurilor, si orhideea e accentul roz, rar, la 3 m de
## banda (brief: accent, nu covor).
func _verde() -> void:
	# Queñuali pe marginea platoului din stanga, unde incepe verdele.
	for sp: Array in [[-0.0085, 52.0, "polylepis_b", 7.2],
			[0.0040, 55.0, "polylepis_b", 6.6],
			[0.0150, 50.0, "polylepis_a", 4.4],
			[0.0230, 46.0, "polylepis_a", 4.6]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at(String(sp[2]), "quenual", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for(String(sp[2]), float(sp[3])), "", -0.15)
	# Bolovani cu muschi la baza zidurilor: rup linia dreapta a zidariei.
	for sp: Array in [[-0.0065, 26.0, "moss_boulder_b", 2.0],
			[0.0090, 27.5, "moss_boulder_a", 0.8],
			[0.0200, -24.0, "moss_boulder_b", 2.2],
			[-0.0020, -25.5, "moss_boulder_a", 0.75]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at(String(sp[2]), "bolovan", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for(String(sp[2]), float(sp[3])), "", -0.12)
	# Bromelii si orhidee: accente sub linia capotei, coliziune `none`.
	for sp: Array in [[-0.0070, 12.5, "bromeliad", 0.45],
			[0.0060, -12.0, "bromeliad", 0.42],
			[0.0170, 12.8, "bromeliad", 0.44],
			[0.0035, 12.2, "orchid_cluster", 0.45],
			[0.0205, -12.5, "orchid_cluster", 0.42]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at(String(sp[2]), "accent", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for(String(sp[2]), float(sp[3])), "none", -0.02)
	# Bornele de traseu (trail_marker, 1,20 m, `none`): punctuatie pe umar,
	# la 2,5 m de muchie — semnalul „drumul trece pe aici", ca in bara.
	for fr: float in [-0.0070, 0.0030, 0.0130, 0.0230]:
		var c := _pt(fr, 11.5)
		_at("trail_marker", "borna", c.x, c.y, _yaw_at(fr), 1.0, "none", -0.05)


# ------------------------------------------------------------------ asezarea

func _idx(frac: float) -> int:
	var n := _track.baked.size()
	var i := int(round(frac * float(n)))
	return ((i % n) + n) % n


func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Punctul de pe axa + vectorul lateral + semi-latimea, la fractia data.
func _axis(frac: float) -> Dictionary:
	var i := _idx(frac)
	var n := _track.baked.size()
	var fwd: Vector3 = (_track.baked[(i + 1) % n] - _track.baked[i]).normalized()
	return {
		"p": _track.baked[i],
		"s": _track._side_at(i),
		"half": _track.width_at_index(i),
		"fwd": fwd,
	}


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la marginea piesei. Cota din raycast pe TerrainBody.
## `yaw` e ABSOLUT (radiani, in lume) daca `absolute_yaw`, altfel relativ la
## directia laterala a drumului.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "",
		y_off: float = 0.0) -> Vector3:
	var a := _axis(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = (a["s"] as Vector3) * side_sign
	var half: float = a["half"]
	var r: float = float(BASE_R.get(model, 0.6)) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if d - r < half + 0.35:
		_warn += 1
		print("; ATENTIE %s la frac %+.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	return _raw(model, base, Vector3(q.x, g + y_off, q.z), yaw, scl, mode)


## Aseaza la o pozitie absoluta in lume (pentru incinte: coltul se calculeaza
## o data, restul zidurilor se insira din el).
func _at(model: String, base: String, x: float, z: float, yaw: float,
		scl: float, mode: String = "", y_off: float = 0.0) -> Vector3:
	var g := _sol_real(x, z)
	return _raw(model, base, Vector3(x, g + y_off, z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> Vector3:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri): yaw pur =
	# Transform3D(cos*s, 0, sin*s, 0, s, 0, -sin*s, 0, cos*s, x, y, z).
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, s, scl, -s, c, pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")
	return pos


func _write() -> void:
	print("; asezate %d piese, %d avertismente, ~%d triunghiuri" % [_n, _warn, _tri])
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


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody), nu din
## campul neted si nu din _terrain_mesh_y (memoria terrain-mesh-y-extrapoleaza).
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
