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
## 7. UNDE SE UITA CAMERA (runda 3, masurat pe capturi). `--gamecam` pune
##    camera la 12,5 m IN SPATELE punctului de fractie, la 10 m inaltime.
##    Deci ce sta FIX la fractia de captura e la 12 m in fata, in marginea
##    de jos a cadrului; cadrul se umple cu ce e intre 20 si 80 m in fata,
##    adica intre frac+0.010 si frac+0.040 (1986 m / tur -> 19,86 m per
##    0.01 de fractie). Runda 2 pusese Trei Ferestre la frac 0.0005 si
##    Templul Soarelui la 0.0035, adica **langa masina**, si pe captura nu
##    se vede niciunul (memoria `masoara-inainte-nu-langa`). Piesele-erou
##    se muta la frac 0.012-0.030 pentru captura de la 0.00, si se dubleaza
##    intre 0.030-0.045 pentru captura de la 0.02.
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
	# LAMA: 1.657 m, NU 0.529. Tabelul din machu_picchu_masuratori.md §1 da
	# 0.529 fiindca masoara AABB-ul mesh-ului in spatiul LUI, inainte de
	# transformarea scheletului (LlamaMesh sta sub un Node3D sub un
	# Skeleton3D). Cifra reala, masurata in motor cu get_aabb() compus prin
	# global_transform, e (0.393 x 1.657 x 1.369). Runda 3 a crezut tabelul
	# si a cerut "1,66 m inaltime": a iesit scara 3.135 si o lama de 5,2 m,
	# vizibila pe A_r3_three_windows.png ca o girafa peste ziduri.
	# Memoria `sonda-masura-alt-obiect`: cifra din tabel masura alt obiect.
	# (Aceeasi scara 3.135 e pe cele patru lame-hazard din Track15.tscn,
	# cablate de fundatie — nu e zona mea, dar defectul e acelasi.)
	"llama": 1.657, "llama_b": 1.657, "llama_c": 1.657,
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
	"llama": 0.69, "llama_b": 0.69, "llama_c": 0.69,
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
var _holes := 0
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
##
## RUNDA 9: restul se CENTREAZA. Pe ziduri lungi (randurile de 26 m ale
## rundei 8) nu conta unde cade rostul. Pe laturi de CAMERA de 4-6 m conteaza
## tot: un rest de 1,4 m lasat la capat ar fi insemnat ca fiecare camera are
## un colt lipsa, adica exact defectul pe care blocul il repara. Restul
## `length - t_final` se imparte la doi si se pune jumatate la fiecare capat,
## deci coltul ramane inchis la ambele capete cu cel mult 0,7 m de rost —
## care citeste ca imbinare de piatra, nu ca zid rupt.
func _wall_run(start: Vector2, u: Vector2, length: float, yaw: float,
		h: float, tag: String, y_off: float) -> void:
	# Prima trecere, seaca: cat se umple efectiv din `length`.
	var used := 0.0
	var g0 := 0
	while length - used >= 1.95 and g0 < 200:
		g0 += 1
		var m0 := "inca_wall_c"
		if length - used >= 6.0:
			m0 = "inca_wall_b"
		elif length - used >= 4.0:
			m0 = "inca_wall_a"
		var rl0: float = float(LEN_X[m0]) * _scale_for(m0, h)
		if used + rl0 > length + 0.25:
			if m0 == "inca_wall_b":
				m0 = "inca_wall_a"
			elif m0 == "inca_wall_a":
				m0 = "inca_wall_c"
			else:
				break
			rl0 = float(LEN_X[m0]) * _scale_for(m0, h)
			if used + rl0 > length + 0.25:
				break
		used += rl0
	var pad := maxf(0.0, (length - used) * 0.5)
	var t := pad
	var guard := 0
	var stop := length - pad
	while stop - t >= 1.95 and guard < 200:
		guard += 1
		var mdl := "inca_wall_c"
		if stop - t >= 6.0:
			mdl = "inca_wall_b"
		elif stop - t >= 4.0:
			mdl = "inca_wall_a"
		var l: float = LEN_X[mdl]
		var scl := _scale_for(mdl, h)
		# Piesa se scaleaza UNIFORM (scara e una singura in `_raw`), deci
		# lungimea ei reala pe teren e l * scl — si de la runda 11 asta
		# CONTEAZA: zidurile de camp au 1,80-2,00 m, deci scl ~ 0,76, deci
		# `inca_wall_b` masoara 4,6 m pe teren, nu 6,0. O latura de camera de
		# 7,5 m se umple din b + c, doua bucati. Algoritmul e corect
		# fiindca masoara `real_l`, dar cifra din comentariul vechi
		# („scl ~ 1,005") era a rundei 2 si ar fi indus in eroare.
		var real_l := l * scl
		if t + real_l > stop + 0.25:
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
			if t + real_l > stop + 0.25:
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


## Incinta la cota terenului. `y_off` a EXISTAT si a fost SCOS — vezi de ce.
##
## RUNDA 6, si e o revenire, nu o rafinare (memoria
## `revenirea-e-o-mutare-valida`). Runda 2 inventase etaje: incinte ridicate
## cu 1,6 si 3,2 m peste sol, cu un zid de sprijin lung drept fatada. Din
## masina arata bine si a facut campul sa aiba adancime. Doua masuratori au
## aratat ca era o fatada, nu o terasa:
##
##  (a) `probe_manual --track=15` — garda, RULATA, nu presupusa — a numarat
##      **38 de piese PLUTIND**, exact zidurile etajelor: sub ele era aer.
##      Din drum nu se vedea fiindca zidul de sprijin acoperea golul.
##      (`probe_manual` ia NUMARUL DE SCENA, ca `probe_decor`; cu --track=8
##      masoara Okinawa si raporteaza `stone_gate_torii` — nu e zona asta.)
##  (b) Am incercat intai reparatia „corecta": un inel PLIN de zid de la sol
##      pana la y_off sub fiecare incinta ridicata (128 de piese in plus).
##      Captura din lateral (A_r6_terase.png) arata de ce nu tine: peretii se
##      umplusera, dar INTERIORUL incintei ramanea la cota terenului. Adica
##      nu o terasa, ci o groapa incadrata de zid — te uiti IN ea, nu PE ea.
##      O terasa adevarata cere PAMANT ridicat, iar pamantul vine din teren
##      (`custom_ravines` / TerrainStep), nu din decor manual. Nu e la
##      indemana POI-ului asta si nu inventez un al treilea etaj fals ca sa
##      ascund al doilea.
##
## Deci campul ramane pe UN plan, si adancimea vine de unde vine si in bara:
## din inaltimi DIFERITE de zid (1,2 / 1,8 / 2,5 / 3,2 m) si din randuri tot
## mai departate, nu din cote.
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
## (b) RUNDA 9 O INTOARCE, CU MOTIV MASURAT. Runda 2 scrisese aici ca
## "o incinta mare citeste ca o curte, patru mici citesc ca un labirint",
## si a marit incintele la 22-30 m latura. Capturile A_r8_f000/f002.png
## arata ca a fost exact invers, si se vede de ce din geometrie, nu din gust:
##
##   Ochiul sta la ~10 m inaltime, la 12,5 m in spatele masinii, si priveste
##   PE LUNGUL drumului. O incinta de 26 x 15 m aliniata cu drumul isi arata
##   camerei numai latura LUNGA (26 m, aproape paralela cu privirea, deci
##   intinsa pe toata latimea cadrului) — laturile transversale au 15 m si
##   sunt vazute aproape din capat, deci ocupa cateva zeci de pixeli. Iar
##   incinta urmatoare, la 13 m mai departe pe aceeasi linie laterala, isi
##   aliniaza latura lunga cu a celei dinainte: din masina, cele cinci curti
##   ale etajului 0 se citesc ca UN SINGUR zid continuu de 130 m. Exact ce
##   a numit criticul rundei 8: "siruri lungi paralele cu drumul".
##
##   In bara, dreptunghiurile de iarba au 4-8 m pe latura. La marimea aia,
##   ORICE unghi de privire arata doua laturi si un colt, fiindca latura
##   transversala e la fel de lunga cu cea longitudinala. Coltul e ce
##   citeste; lungimea e ce sterge coltul.
##
## Deci campul nu se mai compune din incinte independente, ci din BLOCURI
## impartite in CAMERE: `_block` deseneaza grila completa a unui dreptunghi
## (toate liniile pe u si toate pe v), cu celula de 5-7 m. Fiecare zid iese
## atunci cu doua colturi PRIN CONSTRUCTIE, si camerele vecine impart zidul
## dintre ele — exact ce cere criticul si exact ce e in bara.
##
## Si consecinta secundara pe care criticul a legat-o corect de aceeasi
## cauza: dunga verde. Slotul 12 (CACTUS_GREEN) de pe `inca_wall_*` e iarba
## de CORONAMENT, la y 2,31-2,49 (masuratori §2), adica pe muchia de sus a
## zidului. Pe un sir drept de 130 m, coronamentele tuturor pieselor stau pe
## aceeasi linie si iese o dunga de vopsea de-a latul cadrului. Rupta in
## camere de 6 m, cu inaltimi care variaza +/- 0,45 m de la camera la camera
## (`_h_of`), aceeasi iarba de coronament devine ce e in bara: petice verzi
## pe capetele de zid, la cote diferite. Nu schimb nicio textura si nicio
## clasa — schimb geometria care le insira.
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


## ------------------------------------------------------------------ BLOCUL
## Un bloc de cetate: dreptunghi de `nu` x `nv` camere, fiecare de `cw` x `cd`
## metri, centrat in `c`, rotit cu `rot`. Se deseneaza GRILA COMPLETA — cele
## `nv+1` linii pe directia u si cele `nu+1` linii pe directia v — deci:
##
##   * fiecare camera e INCHISA (patru laturi), fiindca liniile se
##     intersecteaza in colturi;
##   * camerele vecine IMPART zidul dintre ele (o linie interioara e latura
##     din dreapta a unei camere si latura din stanga a celeilalte), deci
##     zidaria nu se dubleaza;
##   * niciun zid nu are capat liber: orice segment porneste dintr-un colt
##     si se opreste in altul.
##
## GOLURILE — si de ce runda 9 le-a facut gresit din prima incercare.
##
## Prima versiune sarea fiecare segment cu p = 0,16 (bord) / 0,22 (interior),
## independent. Captura A_r9_f000.png arata rezultatul: pe stanga, in loc de
## camere, un camp de LESPEZI IZOLATE la unghiuri diferite — adica exact
## defectul rundei 8, doar cu alta forma. Cauza e combinatorica, nu estetica:
## o camera are 4 laturi, deci sansa sa ramana INTREAGA e (1-p)^4. La p = 0,22
## aia e 0,37. Doua treimi din camere pierdeau macar o latura, si o camera cu
## doua laturi lipsa nu mai e camera, e un colt razlet. Pe un bloc de 2x2
## (12 segmente) se vedea cel mai tare, fiindca n-avea destule camere ca
## macar una sa iasa intreaga.
##
## Regula noua, care pastreaza si intentia (o cetate nu e plasa de sarma) si
## contractul (fiecare zid cu doua colturi):
##
##   * bordul blocului NU se sare niciodata — conturul exterior e ce spune
##     „asta e un corp construit", si e si ce inchide camerele de margine;
##   * dintre segmentele INTERIOARE se scoate cel mult unul din patru, si
##     numai daca scoaterea lui nu lasa vreo camera cu mai putin de trei
##     laturi. Verificarea se face pe o harta de laturi per camera, nu pe o
##     aruncare de zar: un gol care scoate a doua latura a unei camere se
##     REFUZA, nu se spera sa nu apara.
##
## Un gol asa plasat e o USA intre doua camere vecine — ce e si in bara.
##
## `h` variaza pe SEGMENT (`h` +/- `h_var`) — vezi nota (b): asta e si ce
## rupe dunga de coronament.
func _block(c: Vector2, nu: int, nv: int, cw: float, cd: float, rot: float,
		h: float, h_var: float, tag: String, seed_off: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 900000 + seed_off
	var u := Vector2(cos(rot), sin(rot))
	var v := Vector2(-sin(rot), cos(rot))
	var o := c - u * (float(nu) * cw * 0.5) - v * (float(nv) * cd * 0.5)
	# Inventarul segmentelor. Cheia "U|i|j" = segmentul de pe linia u de
	# indice j, intre coloanele i si i+1; "V|i|j" = cel de pe linia v de
	# indice i, intre randurile j si j+1.
	var keep := {}
	var interior: Array[String] = []
	for j in range(nv + 1):
		for i in range(nu):
			var k := "U|%d|%d" % [i, j]
			keep[k] = true
			if j > 0 and j < nv:
				interior.append(k)
	for i in range(nu + 1):
		for j in range(nv):
			var k2 := "V|%d|%d" % [i, j]
			keep[k2] = true
			if i > 0 and i < nu:
				interior.append(k2)
	# Cate laturi mai are fiecare camera daca se scoate un segment dat.
	var budget := int(floor(float(interior.size()) * 0.25))
	interior.shuffle()  # foloseste RNG-ul global; ordinea nu e critica
	var dropped := 0
	for k3 in interior:
		if dropped >= budget:
			break
		keep[k3] = false
		if _min_laturi(keep, nu, nv) < 3:
			keep[k3] = true  # refuzat: ar fi rupt o camera
		else:
			dropped += 1
	# Desenarea.
	for j2 in range(nv + 1):
		for i2 in range(nu):
			if not bool(keep["U|%d|%d" % [i2, j2]]):
				continue
			var a := o + u * (float(i2) * cw) + v * (float(j2) * cd)
			_wall_side_y(a, a + u * cw, _h_of(h, h_var, rng), -1.0, 0.0,
				tag, 0.0)
	for i3 in range(nu + 1):
		for j3 in range(nv):
			if not bool(keep["V|%d|%d" % [i3, j3]]):
				continue
			var a2 := o + u * (float(i3) * cw) + v * (float(j3) * cd)
			_wall_side_y(a2, a2 + v * cd, _h_of(h, h_var, rng), -1.0, 0.0,
				tag, 0.0)


## Cate laturi are camera cea mai saraca din bloc, cu harta de segmente data.
## Camera (i, j) e marginita de U|i|j (in fata), U|i|j+1 (in spate),
## V|i|j (la stanga) si V|i+1|j (la dreapta).
func _min_laturi(keep: Dictionary, nu: int, nv: int) -> int:
	var worst := 4
	for i in range(nu):
		for j in range(nv):
			var n := 0
			if bool(keep["U|%d|%d" % [i, j]]):
				n += 1
			if bool(keep["U|%d|%d" % [i, j + 1]]):
				n += 1
			if bool(keep["V|%d|%d" % [i, j]]):
				n += 1
			if bool(keep["V|%d|%d" % [i + 1, j]]):
				n += 1
			worst = mini(worst, n)
	return worst


func _h_of(h: float, h_var: float, rng: RandomNumberGenerator) -> float:
	return maxf(1.15, h + rng.randf_range(-h_var, h_var))


## TERASELE de pe partea DREAPTA (side = +1), unde platoul tine pana la
## +60 m si unde cade umbra peste drum.
func _terase_dreapta() -> void:
	# Zidul lung de sprijin RAMANE (separa randul din fata de cel din fund),
	# dar se muta la 38 m si se rupe in doua tronsoane cu gol la mijloc. Cu
	# blocurile de camere in fata lui nu mai e el linia care se citeste; daca
	# ar fi ramas continuu pe 100 m, ar fi refacut singur defectul rundei 8.
	_terasa(-0.0090, 0.0150, 39.0, 2.2, 0.0, "sprijin1")
	_terasa(0.0215, 0.0440, 39.0, 2.2, 0.0, "sprijin1")


## RUNDA 11 — RAPORTUL INALTIME/CAMERA, masurat pe decupaje puse fata in fata
## (`cmp_r10.png`: bara sus, captura noastra jos, aceeasi marime pe ecran).
##
## Camerele rundei 10 se inchid corect — coltul e acolo, criticul rundei 8 ar
## fi multumit pe punctul lui principal. Dar decupajul arata ca nu se vede
## NICIUNA pe dinauntru: din masina se citesc numai FETELE si CAPETELE de zid,
## niciodata podeaua de iarba a vreunei curti. In bara e invers — fiecare
## incinta isi arata interiorul, si iarba dinauntru e cea mai mare suprafata
## din cadru dupa piatra.
##
## Cauza e un raport, si e usor de citit pe bara: acolo zidul are cam a
## CINCEA pana la a OPTA parte din latura camerei. La noi era 2,5 m pe camera
## de 6,0 m — adica 1/2,4. Ochiul sta la 10 m si priveste aproape razant;
## la raportul ala, zidul din fata acopera complet podeaua camerei din spatele
## lui.
##
## RUNDA 12 a gasit si capatul CELALALT al reglajului, tot pe decupaj
## (`cmp_r11.png`). La 1/7 — camere de 10 m cu ziduri de 1,4 m — podeaua se
## vede, dar camera nu se mai citeste: piesele se scaleaza UNIFORM, deci un
## zid de 1,4 m e si SUBTIRE (0,47 m in loc de 0,83), iar patru lame subtiri
## asezate pe un patrat de 10 m nu se mai grupeaza in „inel". Fiecare citea
## iar ca lespede separata — adica defectul rundei 9 intors pe alt drum.
##
## Deci raportul nu e singurul parametru; mai e unul, si e lungimea ABSOLUTA
## a laturii fata de grosimea zidului. Reglajul de oprire, masurat intre cele
## doua capete pe care le-am vazut amandoua pe captura:
##
##   runda 10:  camera 6,0 m · zid 2,5 m (1/2,4) → curti invizibile
##   runda 11:  camera 10,0 m · zid 1,4 m (1/7)  → curti vizibile, inel rupt
##   runda 12:  camera 7,5 m · zid 1,9 m (1/4)   → si, si
##
## La 1,9 m scara e 0,764, deci zidul are 0,63 m grosime si `inca_wall_b`
## masoara 4,58 m pe teren: o latura de 7,5 m se face din b + c, doua bucati,
## deci inelul ramane citibil ca inel. Iar linia de vedere de la 10 m
## inaltime trece peste un coronament de 1,9 m si cade pe podea incepand de
## la ~7 m in spatele lui — adica fix inauntrul camerei urmatoare.
##
## Si asta rezolva si obiectia SECUNDARA a criticului, cea pe care a legat-o
## (corect) de aceeasi cauza: „iarba dinauntrul incintelor nu e mai aprinsa
## decat panta din jur, deci petecele nu se delimiteaza cand zidul e scund;
## iar bordura verde de la baza zidurilor citeste ca dunga de vopsea".
##
## Verdele ala nu e la baza, e la CORONAMENT: slotul 12 (CACTUS_GREEN) de pe
## `inca_wall_*` sta la y 2,31-2,49 din 2,49 (masuratori §2), adica iarba
## crescuta pe muchia de sus. Criticul l-a vazut la baza fiindca zidurile din
## planul doi isi arata coronamentul exact acolo unde zidul din planul intai
## isi are talpa. Cu ziduri de 1,4 m si camere de 10 m, numarul de coronamente
## vizibile scade de vreo trei ori, si fiecare e un petec scurt pe o camera,
## nu un fir continuu — iar intre ele se vede podeaua.
##
## Nu ating nicio textura si nicio clasa. Iarba nu se poate face mai aprinsa
## din decor oricum (memoria `surfacetool-clamp-vertex-color`: vertex color
## doar INTUNECA), iar culoarea terenului se decide in `track.gd`, care e cod
## de tema, comun celorlalte doua POI-uri care lucreaza in paralel. Ce tine
## de mine e cat din ea se VEDE.
##
## CAMPUL DIN DREAPTA: blocuri de camere, doua randuri de adancime.
## Fiecare bloc e rotit usor fata de drum (+/- 0,08..0,15 rad): in bara,
## incintele nu sunt toate pe aceeasi axa, si micile diferente de unghi sunt
## ce face ca laturile lungi sa NU se mai alinieze intr-o dunga unica.
func _camp_dreapta() -> void:
	# Randul din fata, centre la 23-24 m de ax. Bloc de 3x3 camere de
	# 6,2 x 5,6 m = 18,6 x 16,8 m: marginea dinspre drum ajunge la
	# 23 - 8,4 = 14,6 m de ax, deci la 5,6 m de muchia benzii de 9 m.
	for sp: Array in [
			[-0.0050, 25.0, 2, 3, 7.6, 7.2, 0.09, 1.90, 0.22],
			[0.0070, 26.0, 3, 2, 7.4, 7.6, -0.11, 1.80, 0.20],
			[0.0190, 25.0, 2, 3, 7.8, 7.0, 0.13, 2.00, 0.22],
			[0.0305, 26.0, 3, 2, 7.5, 7.4, -0.08, 1.85, 0.20],
			[0.0420, 25.0, 2, 2, 7.6, 7.2, 0.10, 1.95, 0.22]]:
		_blk(sp, "cameraDr")
	# Randul din fund, dincolo de zidul de sprijin, la 51-52 m: camere putin
	# mai mari si ziduri mai inalte (3,1-3,3 m), ca sa se vada peste randul
	# din fata fara sa fie ridicate pe cota (terenul e plat, nota 1).
	for sp: Array in [
			[-0.0030, 52.0, 3, 2, 8.2, 7.8, -0.14, 2.45, 0.25],
			[0.0115, 53.0, 2, 2, 8.0, 8.2, 0.12, 2.55, 0.25],
			[0.0260, 52.0, 3, 2, 8.4, 7.6, -0.10, 2.40, 0.25],
			[0.0395, 53.0, 2, 2, 8.0, 8.0, 0.15, 2.55, 0.25]]:
		_blk(sp, "cameraDrB")


## CAMPUL DIN STANGA (side = -1).
##
## RUNDA 9, MASURAT DIN NOU si altfel decat la runda 2. `probe_manual` a
## picat pe `cameraStg161` (ingropat 2,71 m fata de campul neted), si sonda
## `probe_mp_a_dip.gd` a aratat ca nu e o gaura de coliziune si nici o minciuna
## a campului: acolo terenul chiar coboara de la -0,2 la -5,3 pe vreo 12 m,
## iar campul neted ramane in urma pe rampa cu pana la 2,4 m. Piesa statea
## corect pe sol — dar pe o RAMPA, ceea ce pentru un bloc de camere e mai rau
## decat sa pluteasca: camerele ies la cote diferite si blocul se rupe.
##
## Buza defileului din stanga NU e paralela cu drumul, e o DIAGONALA. Din
## tabelul sondei (cota fata de sosea, raycast pe TerrainBody):
##
##   frac      -52    -44    -35    -28    -22    -16
##   -0.0120  -11.3   -9.4   -7.1   -5.3   -3.5   -0.8
##   -0.0040  -11.4   -9.4   -7.0   -3.6   -1.9   -0.3
##   +0.0000  -11.5   -9.5   -0.4   -0.2   -0.2   -0.3
##   +0.0040   -9.2   -3.0   -0.1   -0.1   -0.1   -0.2
##   +0.0080   -0.6    0.0    0.1    0.1   -0.0   -0.2
##   +0.0120    0.0    0.1    0.2    0.1    0.1   -0.1
##
## Adica: la -22 m e platou de la frac -0.002 in sus; la -44 m abia de la
## +0.006; la -52 m abia de la +0.008. Runda 2 „stia" din `--survey` ca de
## la +0.005 e plat pana la -46 — dar `--survey` masura coloane la ±40/55/70/90,
## deci nu se uitase NICIODATA la cotele pe care le foloseste compozitia
## (memoria `caseta-de-masura-exclude-defectul`).
##
## Deci: randul din fata incepe la +0.004 (platou la -22 de la -0.002, cu
## marja pentru adancimea blocului); randul din fund abia de la +0.012.
func _camp_stanga() -> void:
	# La INTRARE (frac sub 0.000) stanga e deja rapa: nu se pune bloc, se
	# pune numai zidul de margine care opreste ochiul inainte de gol.
	_terasa(-0.0095, 0.0010, -16.0, 1.6, 0.0, "margineGol")
	# Randul din fata, de la +0.004 (unde -22 m e sigur platou).
	for sp: Array in [
			[0.0065, -24.0, 3, 2, 7.5, 7.4, -0.12, 1.85, 0.20],
			[0.0185, -24.0, 2, 3, 7.8, 7.0, 0.10, 1.95, 0.22],
			[0.0300, -23.0, 3, 2, 7.4, 7.6, -0.09, 1.80, 0.20],
			[0.0415, -24.0, 2, 2, 7.6, 7.2, 0.13, 1.90, 0.22]]:
		_blk(sp, "cameraStg")
	_terasa(0.0090, 0.0450, -36.0, 2.2, 0.0, "sprijinStg")
	# Randul din fund, de la +0.014: la -44 m platoul incepe la +0.006, iar
	# blocul are 12-14 m adancime, deci centrul lui nu poate cobori sub +0.012.
	for sp: Array in [
			[0.0155, -45.0, 2, 2, 8.2, 8.0, 0.14, 2.45, 0.25],
			[0.0275, -45.0, 3, 2, 8.0, 7.8, -0.11, 2.55, 0.25],
			[0.0400, -44.0, 2, 2, 8.4, 7.6, 0.09, 2.40, 0.25]]:
		_blk(sp, "cameraStgB")


## Dezambalarea unei specificatii de BLOC:
## [frac, lat, nu, nv, cw, cd, rot_rel, h, h_var]
func _blk(sp: Array, tag: String) -> void:
	var fr: float = sp[0]
	var c := _pt(fr, float(sp[1]))
	_block(c, int(sp[2]), int(sp[3]), float(sp[4]), float(sp[5]),
		_yaw_at(fr) + float(sp[6]), float(sp[7]), float(sp[8]), tag,
		int(absf(fr) * 100000.0) + int(absf(float(sp[1]))))


## TEMPLELE. Brief: Trei Ferestre pe STANGA (deci side = **-1**, dupa
## masuratoarea de mana din nota 3 — runda 1 il pusese pe dreapta), Templul
## Principal pe dreapta, grila intre ele.
func _temple() -> void:
	# Trei Ferestre: fatada de 10 m x 4,0 m. La 15 m de ax pe STANGA, cu
	# fata spre drum: cele trei nise trapezoidale sunt semnalul de
	# recunoastere si trebuie sa se vada din masina la trecerea prin grila.
	# Piesa e o FATADA (10,00 x 4,00 x 1,15 m masurat in motor), nu o
	# cladire: are o singura fata buna, cea cu nisele. Runda 3 o pusese la
	# -15 m de ax, adica IN SPATELE zidului incintei din stanga (care e la
	# 21 m centru, deci latura lui dinspre drum e la ~13,5 m): pe captura se
	# vedea doar buiandrugul peste coronament (A_r3_three_windows.png).
	# Acum sta la -12,5 m, in FATA oricarui zid, cu nisele spre sosea.
	var f := 0.0155
	var c := _pt(f, -12.5)
	_at("three_windows", "treiFerestre", c.x, c.y, _yaw_at(f) + PI, 1.0, "", -0.10)
	# Templul Principal (sun_temple, zid curb, 5,59 m) pe DREAPTA, la 16 m de
	# ax, in poarta curtii mari — e cea mai inalta piesa de piatra din piata
	# si trebuie sa stea in fata incintei, nu in spatele ei.
	# Templul Principal: 8,79 x 5,59 x 7,59 m — o cladire, nu o fatada, deci
	# are nevoie de teren liber in jur. Runda 3 il pusese la 16 m de ax, fix
	# peste latura dinspre drum a curtii de pe dreapta: zidul ii taia baza
	# si iesea o lespede curba de piatra (A_r3_sun_temple.png). Acum sta la
	# 13,5 m, in fata zidului, pe teren gol.
	var f2 := 0.0215
	var c2 := _pt(f2, 13.5)
	_at("sun_temple", "templulSoarelui", c2.x, c2.y, _yaw_at(f2) - PI * 0.5,
		1.0, "", -0.12)
	# A doua fatada de nise, pentru cadrul de la frac 0.02: la 0.038 pe
	# dreapta. Piesa `three_windows` e o fatada, nu o cladire — doua exemplare
	# la 45 m distanta citesc ca doua incaperi ale aceluiasi templu, nu ca
	# duplicat (in bara, sirul de nise se repeta pe toata terasa de sus).
	var f3 := 0.0380
	var c3 := _pt(f3, 17.0)
	_at("three_windows", "treiFerestreB", c3.x, c3.y, _yaw_at(f3) + PI,
		0.95, "", -0.10)


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
	var f := 0.0265
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
	# Casa din curtea de pe dreapta, la frac 0.018: pentru cadrul de la 0.00
	# e la ~36 m in fata, adica in treimea din mijloc a ecranului.
	var f := 0.0180
	var c := _pt(f, 23.0)
	_at("inca_house_a", "casaPaie", c.x, c.y, _yaw_at(f) - PI * 0.5, 1.0, "", -0.10)
	# A doua, pe etajul 1 (ridicata 1,6 m), la frac 0.038: silueta de sus a
	# cetatii pentru cadrul de la frac 0.02.
	# A doua casa sta pe etajul 1, la +1,55 m. Acum etajul e SOLID (soclul
	# plin de sub incinta ei, runda 6), deci casa are pe ce sta: `probe_manual`
	# o masoara fata de teren si o vede ridicata, dar sub ea e zidarie, nu aer.
	# Ca sa nu ramana totusi in lista de „plutesc", coboara la +1,5 m si
	# primeste soclul ei propriu, un inel scund chiar sub amprenta casei.
	var f2 := 0.0380
	var c2 := _pt(f2, 42.0)
	_at("inca_house_a", "casaPaieB", c2.x, c2.y, _yaw_at(f2) - PI * 0.35,
		1.12, "", -0.10)
	# RUINELE FARA ACOPERIS — diferenta „casa intreaga / casa cazuta" din
	# bara. Runda 4 le facuse din `inca_house_b`, si captura a aratat de ce
	# nu merge: piesa aia e SINGURA bucata de zidarie din kit care nu poate
	# primi clasa `inca_stone` (inventarul o respinge cu motiv masurat —
	# muschiul e 22,8% si intervalele de y se SUPRAPUN, deci o ruptura pe
	# inaltime ar taia gresit). Ramasa pe atlasul brut, in cadru citea la
	# **H 186 grade, S 0.09** — cyan — la doi metri de ziduri la H 39-44,
	# S 0.45-0.50. Doua familii de piatra in acelasi cadru, pe obiecte
	# despre care brief-ul spune ca sunt acelasi granit
	# (A_r4_ruina.png; memoria `tenta-de-clasa-se-decide-la-integrare`).
	#
	# Nu „corectez" respingerea inventarului: scot piesa din POI-ul asta.
	# Casa cazuta se face din ce citeste corect — un inel JOS de zid (1,2 m)
	# in interiorul unei curti, cu o latura lipsa. E chiar ce arata bara:
	# in piata, ruinele sunt conturul de temelie al unei incaperi, nu un
	# corp de casa.
	var f3 := 0.0085
	var c3 := _pt(f3, -22.0)
	_enclosure(c3, 7.0, 6.0, _yaw_at(f3) + 0.2, 1.2,
		[-1.0, -1.0, 0.5, -1.0], "temelie")
	var f4 := 0.0195
	var c4 := _pt(f4, 26.0)
	_enclosure(c4, 8.0, 6.0, _yaw_at(f4) - 0.25, 1.2,
		[0.5, -1.0, -1.0, -1.0], "temelie")
	var f5 := 0.0330
	var c5 := _pt(f5, -24.0)
	_enclosure(c5, 7.0, 6.0, _yaw_at(f5) + 0.3, 1.3,
		[-1.0, 0.5, -1.0, -1.0], "temelie")


## APA. Canalul incas spune „oras, nu ruina": jgheab de 4 m (`water_channel`,
## 0,30 m, coliziune `none` — un prag de 30 cm pe linia de curs ar fi zid).
## Bucati cap la cap, paralel cu banda, pe STANGA la 11,5 m de ax (partea
## opusa campului dens, ca sa nu se piarda in el), plus trei fantani.
func _apa() -> void:
	var f := 0.0010
	while f < 0.0250:
		# 12,2 m de ax, nu 10,6: `probe_manual` numara drept „IN DRUM" orice
		# sta sub semi-latime + 2,0 m marja, adica sub 11,0 m aici. Jgheabul
		# e `none` (n-ar opri nicio masina), dar garda are dreptate ca
		# obiectul sta pe umar, iar umarul de 9 m e chiar respiro-ul POI-ului.
		var c := _pt(f, -12.2)
		_at("water_channel", "canal", c.x, c.y, _yaw_at(f), 1.0, "none", -0.08)
		f += _step(3.98)
	for fr: float in [0.0040, 0.0125, 0.0210]:
		var cb := _pt(fr, -14.0)
		_at("fountain_basin", "fantana", cb.x, cb.y, _yaw_at(fr) - PI * 0.5,
			1.0, "", -0.05)


## LAMELE care pasc. Nu sunt hazard aici (cele patru de pe terase sunt deja
## cablate pe `SlidingHazard` la POI D): decor static, `none` (0,53 m, sub
## linia capotei). In bara ele sunt in PIATA, aproape, la scara umana —
## sunt reperul de marime al intregului cadru. Deci se pun la 12-16 m de ax,
## nu prin curti unde s-ar pierde.
func _lame() -> void:
	# Scara iese ~1.00 acum (1,66 / 1,657), adica piesa la marimea ei
	# naturala: kitul e deja livrat la scara de lume, nu la scara de mesh.
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
	# RUNDA 3. In bara, cetatea e INCONJURATA de o coroana de copaci inchisi
	# la culoare: ei sunt ce o face sa fie un ostrov de piatra intr-un munte
	# verde, si ei inchid cadrul sus. Runda 2 ii pusese la 62-72 m de ax,
	# adica dincolo de tot campul de incinte — pe captura nu se vede niciunul.
	# Acum inelul e la 46-64 m (imediat dupa ultimul etaj) si e DES: 12 piese
	# pe dreapta si 7 pe stanga, nu 7 in total. Inaltimea 6,5-8,5 m: la 55 m
	# plafonul de cadru e 10 + 0.093*55 = 15,1 m, deci intra intregi si stau
	# peste coronamentul etajului 2 (3,2 + 2,7 = 5,9 m) — adica se vad ca
	# masa verde in spatele pietrei, exact cum sunt in bara.
	for sp: Array in [[-0.0090, 58.0, "polylepis_b", 8.2],
			[-0.0020, 64.0, "polylepis_b", 7.6],
			[0.0050, 60.0, "polylepis_b", 8.4],
			[0.0110, 64.0, "polylepis_a", 5.2],
			[0.0175, 58.0, "polylepis_b", 7.8],
			[0.0235, 63.0, "polylepis_b", 7.2],
			[0.0295, 57.0, "polylepis_a", 5.0],
			[0.0350, 62.0, "polylepis_b", 8.0],
			[0.0410, 56.0, "polylepis_b", 7.4],
			[0.0460, 60.0, "polylepis_a", 4.8],
			[0.0200, 46.0, "polylepis_a", 4.6],
			[0.0420, 46.0, "polylepis_a", 4.4],
			[0.0120, -48.0, "polylepis_b", 7.6],
			[0.0200, -52.0, "polylepis_b", 8.2],
			[0.0280, -47.0, "polylepis_a", 5.0],
			[0.0360, -51.0, "polylepis_b", 7.4],
			[0.0440, -47.0, "polylepis_b", 7.8],
			[0.0490, -44.0, "polylepis_a", 4.6],
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
		var c := _pt(fr, -12.0)
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
	var g := _sol_med(q.x, q.z)
	if d - r < half + 0.35:
		_warn += 1
		print("; ATENTIE %s la frac %+.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	return _raw(model, base, Vector3(q.x, g + y_off, q.z), yaw, scl, mode)


## Aseaza la o pozitie absoluta in lume (pentru incinte: coltul se calculeaza
## o data, restul zidurilor se insira din el).
## RUNDA 9: cota nu mai vine dintr-un SINGUR raycast. `probe_manual` a gasit
## `cameraStg161` la -2,97 m cu terenul la -0,26 — un zid ingropat 2,71 m.
## Cauza nu e extrapolarea campului neted (aia e alta memorie): raycast-ul pe
## TerrainBody a nimerit o muchie a panzei de coliziune si a cazut prin ea.
## Un singur esantion nu are cum sa stie ca a cazut; MEDIANA a cinci
## esantioane pe un mic cerc (centru + 4 la 0,9 m) stie, fiindca patru dintre
## ele stau pe fata buna. Pragul de alerta: daca centrul difera de mediana cu
## peste 0,8 m, cota luata e a MEDIANEI si se raporteaza.
func _sol_med(x: float, z: float) -> float:
	var vals: Array[float] = [_sol_real(x, z)]
	for d: Vector2 in [Vector2(0.9, 0.0), Vector2(-0.9, 0.0),
			Vector2(0.0, 0.9), Vector2(0.0, -0.9)]:
		vals.append(_sol_real(x + d.x, z + d.y))
	vals.sort()
	var med: float = vals[2]
	if absf(vals[0] - med) > 0.8 or absf(vals[4] - med) > 0.8:
		_holes += 1
	return med


func _at(model: String, base: String, x: float, z: float, yaw: float,
		scl: float, mode: String = "", y_off: float = 0.0) -> Vector3:
	var g := _sol_med(x, z)
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
	print("; asezate %d piese, %d avertismente, %d cote netezite (gauri de coliziune), ~%d triunghiuri" % [_n, _warn, _holes, _tri])
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
