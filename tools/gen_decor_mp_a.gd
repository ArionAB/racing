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
## 3. MANA — MASURATA PE CAPTURA, nu dedusa. Runda 1 a dedus-o gresit din
##    `right = up.cross(forward)` si a pus campul dens pe partea cealalta.
##    Verdictul e A_r1_f000.png: campul asezat la `side = +1` a iesit in
##    **jumatatea DREAPTA a cadrului**. Deci **`side = +1` e DREAPTA
##    soferului**, `side = -1` e STANGA. Brief-ul cere Templul celor Trei
##    Ferestre pe STANGA -> side = **-1** (runda 1 il pusese pe +1).
##
## 4. SOARELE. rot (-40, 45, 0); lumina merge spre (-0.54, -0.64, -0.54),
##    elevatie 40 grade, umbra pe XZ -> (-0.707, -0.707). Pe drumul de la
##    frac 0.00 (dir = +X, side = +Z) dot(side, umbra) = **-0.71**: umbra
##    cade spre `-side`, adica (dupa nota 3) spre STANGA soferului.
##    Consecinta: zidurile de pe **dreapta** (side = +1) isi arunca umbra
##    peste piata si peste sosea. Acolo se pune campul cel mai dens, ca
##    dungile de umbra (identitatea pistei, brief §4) sa se vada din masina.
##    Un zid de 2,5 m la 40 de grade arunca umbra de 2,98 m.
##
## 5. CAT LOC E PE FIECARE PARTE (--survey runda 2, coloane la ±26/32/38/46 m):
##    - `+side` (DREAPTA): plat (±0,4 m) pe TOATA zona, pana la +60 m. Aici
##      incape campul de incinte pe trei randuri de adancime.
##    - `-side` (STANGA): la frac -0.010..0.000 cade la -3,5..-10 m de la
##      32 m incolo (buza defileului). De la frac +0.005 incolo e plat pana
##      la -46 m. Deci pe stanga: banda ingusta (pana la 26 m) la intrare,
##      camp plin abia de la +0.005.
##    Runda 1 a lasat stanga goala de la frac 0.02 incolo (A_r1_f002.png:
##    jumatate de cadru iarba goala) tocmai fiindca citise gresit mana si
##    crezuse ca acolo e prapastia. Nu e.
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
	_wall_side_y(a, b, h, gate_t, gate_w, tag, 0.0)


## Aceeasi latura, dar ridicata cu `y_off` metri peste sol: asa se face un
## ETAJ. Zidul unei incinte de pe o terasa nu se aseaza pe teren, se aseaza
## la cota coronamentului zidului de sprijin din fata ei — altfel terasa nu
## exista, e doar un desen pe iarba (runda 2, nota (a)).
func _wall_side_y(a: Vector2, b: Vector2, h: float, gate_t: float,
		gate_w: float, tag: String, y_off: float) -> void:
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
		_wall_run(a + u * seg.x, u, seg.y - seg.x, yaw, h, tag, y_off)


## Inlantuie piese pe directia `u` pornind din `start`, pe lungimea `length`.
## Alegerea e greedy pe piesa cea mai lunga care incape; restul sub 2,0 m se
## umple cu `inca_wall_c` scalat pe X? NU — scalarea neuniforma ar deforma
## piatra. Sub 2,0 m ramane gol: un rost de 1 m intr-un zid incas e o nisa,
## nu o greseala, iar deformarea s-ar vedea (memoria
## `accentul-de-slot-depinde-de-forma`).
func _wall_run(start: Vector2, u: Vector2, length: float, yaw: float,
		h: float, tag: String, y_off: float) -> void:
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
		_at(mdl, tag, c.x, c.y, yaw, scl, "", y_off - 0.12)
		t += real_l


## O incinta dreptunghiulara. `c` = centrul, `w` x `dpt` metri, rotita cu
## `rot` (radiani). `gates` = array de 4 fractii (una per latura, -1 = plin),
## in ordinea: +u (fata), +v (dreapta), -u (spate), -v (stanga).
func _enclosure(c: Vector2, w: float, dpt: float, rot: float, h: float,
		gates: Array, tag: String) -> void:
	_enclosure_y(c, w, dpt, rot, h, gates, tag, 0.0)


## Incinta ridicata pe o terasa, cu `y_off` metri peste sol.
func _enclosure_y(c: Vector2, w: float, dpt: float, rot: float, h: float,
		gates: Array, tag: String, y_off: float) -> void:
	var u := Vector2(cos(rot), sin(rot))
	var v := Vector2(-sin(rot), cos(rot))
	var hw := w * 0.5
	var hd := dpt * 0.5
	var p0 := c - u * hw - v * hd
	var p1 := c + u * hw - v * hd
	var p2 := c + u * hw + v * hd
	var p3 := c - u * hw + v * hd
	_wall_side_y(p0, p1, h, float(gates[0]), 2.6, tag, y_off)
	_wall_side_y(p1, p2, h, float(gates[1]), 2.6, tag, y_off)
	_wall_side_y(p2, p3, h, float(gates[2]), 2.6, tag, y_off)
	_wall_side_y(p3, p0, h, float(gates[3]), 2.6, tag, y_off)


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
	_terase_dreapta()
	_camp_dreapta()
	_camp_stanga()
	_temple()
	_movila_intihuatana()
	_case()
	_apa()
	_lame()
	_verde()


## ------------------------------------------------------------------
## RUNDA 2 — ce a aratat captura rundei 1 (A_r1_f000.png, A_r1_f002.png)
## si ce se schimba din cauza ei.
##
## (a) INCINTELE ERAU PREA MICI SI TOATE LA ACEEASI INALTIME. Sapte
## dreptunghiuri de 13-21 m puse pe un plan orizontal, cu ziduri de 2,4-2,9 m,
## se citesc din masina ca un GARD DE SIPCI: de la 1,5 m inaltime a ochiului
## vezi numai capetele zidurilor, niciodata interiorul unei incinte. In bara,
## fiecare incinta are INTERIOR vizibil — iarba deschisa incadrata de zid —
## si asta se vede fiindca incintele stau pe TERASE la cote diferite: ce e
## mai departe e si mai SUS, deci se uita peste zidul din fata.
##
## Terenul e plat (masuratoare 1), deci etajele nu pot veni din relief. Vin
## din ZID DE SPRIJIN: fiecare rand de incinte sta pe o platforma ridicata
## cu `y_off` fata de sol, incadrata in fata de un zid de sprijin lung.
## Ridicarea e 1,6 m pe randul II si 3,2 m pe randul III — masurate din
## cadru: la 36 m de ax, plafonul de camera e 10 + 0.093*36 = 13,3 m, deci
## un zid de 2,5 m pe o platforma de 3,2 m ajunge la 5,7 m si intra intreg;
## iar interiorul lui (iarba de la +3,2 m) e cu 3,2 m peste coronamentul
## randului I (2,5 m), deci se VEDE peste el. Asta e ce lipsea.
##
## (b) INCINTELE ERAU PREA MULTE SI PREA MARUNTE. Runda 2 pastreaza acelasi
## numar de ziduri dar le pune in incinte MARI (22-30 m latura): din masina,
## o incinta mare citeste ca o curte, patru mici citesc ca un labirint.
##
## (c) STANGA ERA GOALA de la frac 0.02 incolo. Masuratoarea de runda 2 arata
## ca platoul din stanga tine pana la -46 m de la frac +0.005 — deci se umple.

## ZIDURILE DE SPRIJIN care fac etajele. Un zid lung, continuu, paralel cu
## drumul, la `lat` metri de ax, de la `f0` la `f1`, inalt `h`. E fata
## vizibila a platformei pe care sta randul de incinte de dincolo de el.
func _terasa(f0: float, f1: float, lat: float, h: float, y_off: float,
		tag: String) -> void:
	var a := _pt(f0, lat)
	var b := _pt(f1, lat)
	_wall_side_y(a, b, h, -1.0, 0.0, tag, y_off)


## TERASELE de pe partea DREAPTA (side = +1), unde platoul tine pana la
## +60 m si unde cade umbra peste drum. Trei etaje:
##   etaj 0 (piata):    sol,      incinte la 14-30 m de ax
##   etaj 1 (+1.6 m):   zid la 32 m, incinte la 34-50 m
##   etaj 2 (+3.2 m):   zid la 52 m, incinte la 54-62 m
func _terase_dreapta() -> void:
	_terasa(-0.0090, 0.0270, 32.0, 2.7, 0.0, "sprijin1")
	_terasa(-0.0060, 0.0270, 52.0, 2.9, 1.6, "sprijin2")


## CAMPUL DIN DREAPTA: incinte mari, trei randuri, fiecare pe etajul lui.
func _camp_dreapta() -> void:
	# Etajul 0 — doua curti mari lipite de piata, la 14-30 m de ax.
	# Poarta fiecareia da spre drum: din masina se vede PRIN ea in curte.
	for sp: Array in [
			[-0.0055, 22.0, 26.0, 15.0, 2.5, 0.0, [-1.0, -1.0, -1.0, 0.5]],
			[0.0075, 22.0, 28.0, 15.0, 2.5, 0.0, [-1.0, -1.0, -1.0, 0.45]],
			[0.0205, 22.0, 24.0, 15.0, 2.4, 0.0, [-1.0, -1.0, -1.0, 0.5]]]:
		_inc(sp, "curteDr")
	# Etajul 1 — peste zidul de sprijin de la 32 m, ridicat cu 1,6 m.
	for sp: Array in [
			[-0.0045, 42.0, 28.0, 16.0, 2.6, 1.6, [-1.0, -1.0, -1.0, 0.5]],
			[0.0100, 42.0, 30.0, 16.0, 2.6, 1.6, [-1.0, -1.0, -1.0, 0.5]],
			[0.0240, 41.0, 22.0, 15.0, 2.5, 1.6, [-1.0, -1.0, 0.5, -1.0]]]:
		_inc(sp, "curteDrB")
	# Etajul 2 — peste zidul de la 52 m, ridicat cu 3,2 m. Astea sunt
	# siluetele de sus din bara: se vad peste tot restul.
	for sp: Array in [
			[-0.0020, 59.0, 24.0, 12.0, 2.7, 3.2, [-1.0, -1.0, -1.0, -1.0]],
			[0.0140, 59.0, 26.0, 12.0, 2.7, 3.2, [-1.0, -1.0, -1.0, -1.0]]]:
		_inc(sp, "curteDrC")


## CAMPUL DIN STANGA (side = -1). La intrare (frac -0.010..+0.003) platoul
## tine doar pana la -26 m: acolo o singura incinta ingusta, lipita de
## buza defileului. De la +0.005 incolo terenul e plat pana la -46 m si
## campul se deschide pe doua etaje, ca in dreapta.
func _camp_stanga() -> void:
	# Buza defileului: incinta ingusta la intrare, cu latura dinspre gol
	# lipsa (in bara, zidul de margine se termina la prapastie).
	for sp: Array in [
			[-0.0045, -19.0, 22.0, 12.0, 2.5, 0.0, [-1.0, 0.5, -1.0, -1.0]]]:
		_inc(sp, "curteStg")
	# Zidul de margine dinspre gol: linia care opreste ochiul inainte de
	# prapastie si da cetatii contur pe partea aia.
	_terasa(-0.0095, 0.0010, -27.0, 2.2, 0.0, "margineGol")
	# De la +0.005: campul plin, doua etaje.
	for sp: Array in [
			[0.0085, -21.0, 26.0, 15.0, 2.5, 0.0, [-1.0, 0.5, -1.0, -1.0]],
			[0.0215, -21.0, 24.0, 15.0, 2.4, 0.0, [-1.0, 0.5, -1.0, -1.0]]]:
		_inc(sp, "curteStg")
	_terasa(0.0035, 0.0300, -31.0, 2.7, 0.0, "sprijinStg")
	for sp: Array in [
			[0.0110, -41.0, 26.0, 16.0, 2.6, 1.6, [-1.0, -1.0, -1.0, 0.5]],
			[0.0250, -40.0, 22.0, 15.0, 2.6, 1.6, [-1.0, -1.0, -1.0, 0.5]]]:
		_inc(sp, "curteStgB")


## Dezambalarea unei specificatii de incinta.
func _inc(sp: Array, tag: String) -> void:
	var fr: float = sp[0]
	var c := _pt(fr, float(sp[1]))
	_enclosure_y(c, float(sp[2]), float(sp[3]), _yaw_at(fr), float(sp[4]),
		sp[6] as Array, tag, float(sp[5]))


## TEMPLELE. Brief: Trei Ferestre pe STANGA (deci side = **-1**, dupa
## masuratoarea de mana din nota 3 — runda 1 il pusese pe dreapta), Templul
## Principal pe dreapta, grila intre ele.
func _temple() -> void:
	# Trei Ferestre: fatada de 10 m x 4,0 m. La 15 m de ax pe STANGA, cu
	# fata spre drum: cele trei nise trapezoidale sunt semnalul de
	# recunoastere si trebuie sa se vada din masina la trecerea prin grila.
	var f := 0.0005
	var c := _pt(f, -15.0)
	_at("three_windows", "treiFerestre", c.x, c.y, _yaw_at(f), 1.0, "", -0.10)
	# Templul Principal (sun_temple, zid curb, 5,59 m) pe DREAPTA, la 16 m de
	# ax, in poarta curtii mari — e cea mai inalta piesa de piatra din piata
	# si trebuie sa stea in fata incintei, nu in spatele ei.
	var f2 := 0.0035
	var c2 := _pt(f2, 16.0)
	_at("sun_temple", "templulSoarelui", c2.x, c2.y, _yaw_at(f2) - PI * 0.5,
		1.0, "", -0.12)


## INTIHUATANA pe movila. Runda 1 a facut soclul din doua inele concentrice
## de zid scund (1,3 si 1,0 m) — pe captura a iesit un TORT, nu o movila:
## doua discuri de piatra suprapuse. Cauza e ca inelul interior, la 1,0 m,
## era mai SCUND decat cel exterior la 1,3, deci nu urca, coboara.
##
## Runda 2: UN singur soclu patrat, zid de 1,8 m, cu platforma la +1,7 m
## inauntru, si scara de urcare dinspre drum. Piatra-ceas sta PE platforma.
## Capcana declarata (treptele au varfuri partajate, pragurile > 0,3 m sunt
## ziduri) se rezolva prin distanta, nu prin forma: soclul e la 19 m de ax,
## deci marginea lui (raza 3,0 m la scara 1 + jumatate de latura) e la
## ~11 m de ax, adica 2 m dincolo de muchia benzii de 9 m. Masinile nu ajung.
func _movila_intihuatana() -> void:
	var f := 0.0175
	var c := _pt(f, 19.0)
	_enclosure_y(c, 14.0, 13.0, _yaw_at(f), 1.8, [-1.0, -1.0, -1.0, 0.5],
		"soclu", 0.0)
	_at("intihuatana", "intihuatana", c.x, c.y, _yaw_at(f) + 0.35, 1.0, "", 1.70)
	# Scara dinspre drum pe coronamentul soclului: `inca_stair_a` (2,50 m)
	# scalata la 1,80 m ca sa ajunga exact sus.
	var st := _pt(f - 0.0026, 12.6)
	_at("inca_stair_a", "trepteSoclu", st.x, st.y, _yaw_at(f) - PI * 0.5,
		_scale_for("inca_stair_a", 1.80), "", -0.05)


## CASELE cu acoperis de paie. Bara are DOUA, si paiele aurii sunt singura
## culoare calda din camp: pozitia lor decide unde se uita ochiul. Una in
## curtea mare din dreapta (etajul 0, se vede prin poarta), una pe etajul 1
## din dreapta, ridicata cu 1,6 m — acolo e silueta de sus a cetatii.
## `guardhouse` (7,88 m) NU intra: e piesa de la Casa Paznicului (POI C); in
## piata ar fi inghitit silueta templului.
func _case() -> void:
	var f := 0.0075
	var c := _pt(f, 24.0)
	_at("inca_house_a", "casaPaie", c.x, c.y, _yaw_at(f) - PI * 0.5, 1.0, "", -0.10)
	var f2 := 0.0100
	var c2 := _pt(f2, 44.0)
	_at("inca_house_a", "casaPaieB", c2.x, c2.y, _yaw_at(f2) - PI * 0.35,
		1.06, "", 1.55)
	# Ruine fara acoperis (inca_house_b, 2,83 m): diferenta „casa intreaga /
	# casa cazuta" din bara. Una in curtea din stanga, una pe etajul 2.
	var f3 := 0.0085
	var c3 := _pt(f3, -22.0)
	_at("inca_house_b", "ruina", c3.x, c3.y, _yaw_at(f3) + 0.2, 1.0, "", -0.12)
	var f4 := 0.0140
	var c4 := _pt(f4, 59.0)
	_at("inca_house_b", "ruinaB", c4.x, c4.y, _yaw_at(f4) - 0.3, 1.0, "", 3.15)


## APA. Canalul incas spune „oras, nu ruina": jgheab de 4 m (`water_channel`,
## 0,30 m, coliziune `none` — un prag de 30 cm pe linia de curs ar fi zid).
## Bucati cap la cap, paralel cu banda, pe STANGA la 11,5 m de ax (partea
## opusa campului dens, ca sa nu se piarda in el), plus trei fantani.
func _apa() -> void:
	var f := 0.0010
	while f < 0.0250:
		var c := _pt(f, -11.5)
		_at("water_channel", "canal", c.x, c.y, _yaw_at(f), 1.0, "none", -0.02)
		f += _step(3.98)
	for fr: float in [0.0040, 0.0125, 0.0210]:
		var cb := _pt(fr, -13.2)
		_at("fountain_basin", "fantana", cb.x, cb.y, _yaw_at(fr) - PI * 0.5,
			1.0, "", -0.05)


## LAMELE care pasc. Nu sunt hazard aici (cele patru de pe terase sunt deja
## cablate pe `SlidingHazard` la POI D): decor static, `none` (0,53 m, sub
## linia capotei). In bara ele sunt in PIATA, aproape, la scara umana —
## sunt reperul de marime al intregului cadru. Deci se pun la 12-16 m de ax,
## nu prin curti unde s-ar pierde.
func _lame() -> void:
	var s := _scale_for("llama", 1.66)
	var poz := [
		["llama", 0.0025, 13.0, 0.8],
		["llama_b", 0.0045, 15.5, 2.1],
		["llama_c", 0.0135, -13.5, 3.4],
		["llama", 0.0155, -16.0, 4.2],
		["llama_b", 0.0235, 14.0, 1.2],
	]
	for p: Array in poz:
		var fr: float = p[1]
		var c := _pt(fr, float(p[2]))
		_at(String(p[0]), "lama", c.x, c.y, _yaw_at(fr) + float(p[3]), s,
			"none", 0.0)


## VERDELE. Piata din bara e IARBA cu piatra peste, si verdele adevarat
## (copacii) incepe abia DINCOLO de cetate, pe versant. Deci quenualii se pun
## la marginea platoului, dupa ultimul etaj de incinte — acolo inchid cadrul
## si dau adancime; in piata raman doar accente sub linia capotei.
func _verde() -> void:
	for sp: Array in [[-0.0080, 70.0, "polylepis_b", 7.4],
			[0.0050, 72.0, "polylepis_b", 6.8],
			[0.0180, 68.0, "polylepis_a", 4.6],
			[0.0280, 62.0, "polylepis_a", 4.4],
			[0.0120, -52.0, "polylepis_b", 6.6],
			[0.0260, -50.0, "polylepis_a", 4.5],
			[-0.0110, -32.0, "polylepis_a", 4.2]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at(String(sp[2]), "quenual", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for(String(sp[2]), float(sp[3])), "", -0.15)
	# Ferigi arborescente pe buza defileului din stanga, la intrare: acolo
	# terenul cade si vegetatia de padure de nori urca din gol (brief §0.1).
	for sp: Array in [[-0.0075, -29.0, 3.2], [-0.0030, -30.0, 2.8]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at("tree_fern", "feriga", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for("tree_fern", float(sp[2])), "", -0.10)
	# Bolovani cu muschi la baza zidurilor de sprijin: rup linia dreapta.
	for sp: Array in [[-0.0035, 34.5, "moss_boulder_b", 2.1],
			[0.0125, 34.0, "moss_boulder_a", 0.8],
			[0.0230, 33.5, "moss_boulder_b", 2.2],
			[0.0165, -33.0, "moss_boulder_a", 0.75],
			[0.0060, -29.0, "moss_boulder_b", 1.9]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at(String(sp[2]), "bolovan", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for(String(sp[2]), float(sp[3])), "", -0.12)
	# Bromelii si orhidee: accente sub linia capotei, `none`.
	for sp: Array in [[-0.0070, 12.5, "bromeliad", 0.45],
			[0.0060, -12.0, "bromeliad", 0.42],
			[0.0190, 12.8, "bromeliad", 0.44],
			[0.0035, 12.2, "orchid_cluster", 0.45],
			[0.0225, -12.5, "orchid_cluster", 0.42]]:
		var fr: float = sp[0]
		var c := _pt(fr, float(sp[1]))
		_at(String(sp[2]), "accent", c.x, c.y, _rng.randf_range(0.0, TAU),
			_scale_for(String(sp[2]), float(sp[3])), "none", -0.02)
	# Bornele de traseu (`trail_marker`, 1,20 m, `none`): punctuatie pe umar.
	for fr: float in [-0.0070, 0.0030, 0.0130, 0.0230]:
		var c := _pt(fr, -11.0)
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
