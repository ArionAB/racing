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
## Placile de PODEA ale teraselor (vezi `_platforma`), adunate ca sa iasa un
## singur `FlockProp` — un desen pentru toate, zero materiale noi.
var _podea_pos: Array[Vector3] = []
var _podea_scl: Array[Vector3] = []
var _n_terase := 0
## Amprentele teraselor, ca piesele de deasupra (case, soclu) sa poata cere
## COTA PODELEI in loc de cota terenului. Fiecare: {c, u, v, hw, hd, top}.
var _terase: Array[Dictionary] = []


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
	if length < 1.2:
		return
	var scl_c := _scale_for("inca_wall_c", h)
	var scl_a := _scale_for("inca_wall_a", h)
	var scl_b := _scale_for("inca_wall_b", h)
	var lc: float = float(LEN_X["inca_wall_c"]) * scl_c
	var la: float = float(LEN_X["inca_wall_a"]) * scl_a
	var lb: float = float(LEN_X["inca_wall_b"]) * scl_b
	# ANCORA DE COLT. Prima si ultima piesa incep EXACT la capatul laturii.
	# Daca latura e mai scurta decat doua piese-colt, o singura piesa
	# centrata tine ambele capete si latura ramane inchisa.
	if length < lc * 2.0 - 0.10:
		var cc := start + u * (length * 0.5)
		_at("inca_wall_c", tag, cc.x, cc.y, yaw, scl_c * minf(1.0,
			length / lc), "", y_off - 0.12)
		return
	var p_a := start + u * (lc * 0.5)
	var p_b := start + u * (length - lc * 0.5)
	_at("inca_wall_c", tag, p_a.x, p_a.y, yaw, scl_c, "", y_off - 0.12)
	_at("inca_wall_c", tag, p_b.x, p_b.y, yaw, scl_c, "", y_off - 0.12)
	# MIJLOCUL. Ce ramane intre cele doua pietre de colt se umple de la
	# stanga la dreapta cu piesa cea mai lunga care incape; restul, daca
	# mai ramane, cade in MIJLOC, unde citeste ca nisa, nu ca un colt rupt.
	var t := lc
	var stop := length - lc
	var guard := 0
	while stop - t >= 1.85 and guard < 200:
		guard += 1
		var rest := stop - t
		var mdl := "inca_wall_c"
		var real_l := lc
		var scl := scl_c
		if rest >= lb - 0.10:
			mdl = "inca_wall_b"
			real_l = lb
			scl = scl_b
		elif rest >= la - 0.10:
			mdl = "inca_wall_a"
			real_l = la
			scl = scl_a
		if real_l > rest + 0.10:
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
	# RUNDA 13. Bugetul de goluri scade de la 25% la 10%, si golul nu mai e
	# o latura INTREAGA lipsa: e o POARTA de 1,5 m taiata in mijlocul ei
	# (`gates`, mai jos). Masuratoarea care cere schimbarea: din 778 de
	# capete de zid ale rundei 12, **376 (48%) nu aveau vecin la sub 0,8 m**,
	# iar mediana golului intre capete era 0,75 m. Adica jumatate din ziduri
	# se terminau in aer — exact ce a vazut criticul („niciuna intalnindu-se
	# cu alta la un colt"). Doua cauze, amandoua reparate aici:
	#   (a) `_wall_run` centra restul si lasa pana la 0,7 m de gol la FIECARE
	#       capat, deci un colt aduna doua goluri: pana la 1,4 m lipsa pe o
	#       latura de 7,5 m. Acum prima si ultima piesa sunt ANCORATE pe
	#       capat si restul cade in mijloc.
	#   (b) aici: 25% din laturile interioare lipseau cu totul. `_min_laturi`
	#       garanta ca nicio CAMERA nu scade sub 3 laturi, dar din masina nu
	#       se vad camere, se vad LATURI — iar o latura lipsa e un colt
	#       deschis pentru toate camerele care o imparteau.
	var budget := int(floor(float(interior.size()) * 0.10))
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
	# Desenarea. O treime din laturile PASTRATE primesc o poarta de 1,5 m in
	# mijloc: incinta ramane inchisa la colturi (ce cere criticul) dar are
	# intrare, iar rostul de poarta e in mijlocul laturii, unde se citeste ca
	# usa, nu ca zid rupt.
	for j2 in range(nv + 1):
		for i2 in range(nu):
			if not bool(keep["U|%d|%d" % [i2, j2]]):
				continue
			var a := o + u * (float(i2) * cw) + v * (float(j2) * cd)
			var gt := 0.5 if rng.randf() < 0.33 else -1.0
			_wall_side_y(a, a + u * cw, _h_of(h, h_var, rng), gt, 1.5,
				tag, 0.0)
	for i3 in range(nu + 1):
		for j3 in range(nv):
			if not bool(keep["V|%d|%d" % [i3, j3]]):
				continue
			var a2 := o + u * (float(i3) * cw) + v * (float(j3) * cd)
			var gt2 := 0.5 if rng.randf() < 0.33 else -1.0
			_wall_side_y(a2, a2 + v * cd, _h_of(h, h_var, rng), gt2, 1.5,
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


## ------------------------------------------------------------------
## RUNDA 14 — PLATFORMA. Ce a cerut criticul, cuvant cu cuvant, a treia oara
## la rand si de fiecare data mai precis:
##
##   «Zidurile noastre nu INCHID nimic, si mai ales nu inchid un PLAN
##    ORIZONTAL. In referinta fiecare traseu de zid coteste si se inchide, iar
##    ce inchide are PODEA: o platforma de iarba plata, mai deschisa la
##    culoare, asezata la ALTA COTA decat vecina ei, cu fata de sprijin
##    vizibila si o scara intre niveluri.»
##
## Sunt patru lucruri in propozitia aia, si rundele 2-13 au livrat zero din
## ele, fiindca s-au certat toate pe ZID. Le iau pe rand:
##
##   (1) PODEA. Nu exista in kit nicio piesa de pavaj sau de gazon — 39 de
##       GLB-uri, verificate in `machu_picchu_masuratori.md` §1, niciunul o
##       suprafata orizontala. Deci podeaua trebuie sa fie geometrie facuta
##       aici. Tema o si astepta: `track.gd:967` scrie negru pe alb ca la
##       `machupicchu` clasele `inca_stone`, `inca_steps` si **`terrace_grass`**
##       „vin cu POI-urile". `inca_stone` a venit. `terrace_grass` n-a venit
##       niciodata — si nici nu poate veni ca CLASA: ar fi un material nou, iar
##       probe_decor masoara ACUM 20 din 20 (comanda de mai jos, pe scena
##       integrata de azi). Bugetul cerut de dezvoltator e plin.
##
##       Deci podeaua se face pe un SLOT care exista deja, prin `FlockProp` cu
##       `disc_slot` — mecanismul crustei de sare de pe Serengeti POI E, scris
##       exact pentru cazul asta („o textura noua ar fi un material in plus, de
##       aceea crusta e geometrie pe un slot care exista deja", flock.gd:50-60).
##       Materialul e `Palette.world_material()`, cel comun; toate placile din
##       POI intra intr-un singur `MultiMesh`, deci **un desen si zero
##       materiale noi**. Verificat pe garda, nu presupus: 20 -> 20.
##
##   (2) „MAI DESCHISA LA CULOARE" e o cifra, nu un adjectiv, si decide slotul.
##       `ground_tint` al temei e #5F6B3E, luminanta Rec.709 **101,2**. Sloturile
##       din familia verde: 12 CACTUS_GREEN #5B7C34 -> **111,8**; 21
##       TROPICAL_GREEN #3F7A3C -> 105,0. Deci **slotul 12**: cu +10,6 luminanta
##       peste sol e singurul verde din atlas care iese mai deschis, si e chiar
##       familia in care e pictata iarba de coronament a zidurilor (masuratori
##       §2), deci podeaua si zidul care o incadreaza sunt din acelasi verde.
##       21 ar fi fost +3,8 — sub pragul la care ochiul separa doua suprafete
##       mari la 40 m, deci ar fi citit ca aceeasi iarba.
##       Si vertex color NU putea repara diferenta pe alt slot: `set_color` doar
##       INTUNECA (memoria `surfacetool-clamp-vertex-color`), deci un slot mai
##       inchis decat solul ramane pe veci mai inchis.
##
##   (3) „ALTA COTA DECAT VECINA EI". Terenul e plat pe toata piata (--survey:
##       intre -0,4 si +1,1 m la ±8..25 m lateral, pe toata zona), deci cotele
##       NU pot veni din relief si nu am voie sa ating traseul. Vin din
##       platforma: fiecare terasa isi ridica podeaua cu `lift` peste solul ei.
##       Ridicarile se aleg DIFERITE intre terase vecine (1,4 / 2,0 / 2,6 / 3,2),
##       fiindca cerinta nu e „sus", e „alta cota decat vecina".
##
##   (4) DE CE NU E GROAPA — capcana in care a cazut runda 6, si singurul motiv
##       pentru care „platforma" a fost respinsa atunci. Runda 6 a ridicat
##       ZIDURILE cu `y_off` si a umplut sub ele un inel plin de zidarie, dar
##       **interiorul a ramas la cota terenului**: captura din lateral
##       (A_r6_terase.png) arata ca te uiti IN incinta, nu PE ea. Nota de la
##       `_enclosure_y` conchidea, corect pentru ce incercase, ca „o terasa
##       adevarata cere PAMANT ridicat". Aici pamantul chiar se ridica: placa
##       de podea e o suprafata orizontala continua la cota `lift`, deci ce e
##       inauntru E sus. Diferenta fata de runda 6 e exact placa.
##       (Memoria `revenirea-e-o-mutare-valida`: reglajul respins atunci se
##       reincearca acum, cu cauza reala reparata.)
##
## Ce construieste `_platforma`, in ordinea in care se vede din masina:
##
##   a. ZIDUL DE SPRIJIN pe tot conturul, cu coronamentul la `lift`. E „fata de
##      sprijin vizibila" din verdict. Inaltimea ceruta piesei e chiar `lift`,
##      deci talpa lui sta pe sol si capul lui la nivelul podelei.
##   b. PODEAUA la `lift` (minus 6 cm, ca placa sa nu palpaie cu coronamentul).
##   c. SCARA `inca_stair_a`, scalata la EXACT `lift`, lipita de fata dinspre
##      drum, cu treptele spre sosea. E „scara intre niveluri".
##   d. ZIDURILE INCINTEI **pe podea** (`y_off = lift`): camerele stau PE
##      terasa, nu langa ea. Astea sunt scunde (1,2-1,6 m), fiindca peste
##      ridicare ar depasi plafonul de cadru.
##
## COLIZIUNEA. Placa de podea e `FlockProp` = MultiMesh, deci fantoma prin
## constructie (n-are corp). Asta e si bine si necesar: o podea solida la
## +2 m, la 20 m de ax, ar fi o rampa pe care ar urca AI-ul. Zidul de sprijin
## are `hull` (e piesa de kit) si el e ce opreste masina — adica exact
## contractul brief-ului: „zidurile pietei sunt pereti CU MASA".
##
## UNDE NU SE PUN. Nicio platforma sub 16 m de ax: semi-latimea e 9 m si
## `ProbeLaneClear` are marja 2 fata de baza 20. Cea mai apropiata fata de
## sprijin a rundei asteia e la 16,0 m — 7 m dincolo de muchie.

## O TERASA COMPLETA: dreptunghi `w` x `dpt` centrat in `c`, rotit `rot`,
## cu podeaua ridicata `lift` metri peste solul masurat sub centrul ei.
## `rooms_u` x `rooms_v` camere desenate PE ea. `stair_side`: +1 scara pe
## latura dinspre drum, -1 pe cea opusa, 0 fara scara.
func _platforma(c: Vector2, w: float, dpt: float, rot: float, lift: float,
		rooms_u: int, rooms_v: int, room_h: float, stair_side: float,
		tag: String) -> void:
	_n_terase += 1
	var u := Vector2(cos(rot), sin(rot))
	var v := Vector2(-sin(rot), cos(rot))
	var hw := w * 0.5
	var hd := dpt * 0.5
	# Cota de referinta a terasei: MEDIANA solului sub cele patru colturi plus
	# centru. Un singur raycast ar putea nimeri o muchie a panzei si ar aseza
	# toata terasa cu metri mai jos (memoria din `_sol_med`, aici extinsa la
	# scara terasei: o terasa e mai mare decat cercul de 0,9 m al lui _sol_med).
	var probe: Array[float] = [_sol_med(c.x, c.y)]
	for sgn: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1),
			Vector2(-1, -1)]:
		var q := c + u * (hw * sgn.x) + v * (hd * sgn.y)
		probe.append(_sol_med(q.x, q.y))
	probe.sort()
	var base_y: float = probe[2]
	# CADEREA sub terasa. Soseaua urca 7,6 m pe zona (--survey: y_drum de la
	# 0,0 la +0,050 merge 0 -> 7,6), deci o terasa de 25 m lungime vede pana
	# la 3,2 m diferenta intre colturi — masurat, nu presupus: cifrele ies din
	# rularea generatorului, cea mai rea `terasaStgB` cu 3,16 m.
	#
	# Daca zidul de sprijin ar sta la mediana, coltul de jos ar avea 1,6 m de
	# AER sub talpa si s-ar vedea podeaua pe dedesubt — adica fix „platforma
	# e o fatada" pentru care a picat runda 6, doar pe alta axa. Deci zidul se
	# lungeste in jos pana sub cel mai de jos colt (`drop`), iar coronamentul
	# ramane la `base_y + lift`, unde e podeaua. Piesa e mai inalta, talpa ei
	# intra in pamant la colturile inalte — corect: un zid de sprijin incas se
	# si ingroapa, si `probe_manual` masoara fata de teren pe CENTRU.
	var drop: float = maxf(0.0, base_y - probe[0])
	if absf(probe[4] - probe[0]) > 1.2:
		print("; terasa %s: cadere %.2f m intre colturi, zidul de sprijin se lungeste la %.2f m" % [
			tag, probe[4] - probe[0], lift + drop])

	# (a) ZIDUL DE SPRIJIN pe tot conturul. Cota lui e ABSOLUTA (base_y), nu
	# raycast per piesa: altfel piesele ar urma micile valuri ale panzei si
	# coronamentul — care e linia podelei — ar serpui.
	var p0 := c - u * hw - v * hd
	var p1 := c + u * hw - v * hd
	var p2 := c + u * hw + v * hd
	var p3 := c - u * hw + v * hd
	# Inaltimea ceruta piesei e `lift + drop` si talpa ei coboara la
	# `base_y - drop`, deci coronamentul ramane exact la `base_y + lift` —
	# linia podelei — oricat de mult ar cadea terenul sub ea.
	var h_spr := lift + drop
	for e: Array in [[p0, p1], [p1, p2], [p2, p3], [p3, p0]]:
		_wall_abs_inalt(e[0] as Vector2, e[1] as Vector2, h_spr,
			base_y - drop, tag + "Spr")

	# (b) PODEAUA. Placi de 12 laturi, raza `r`, asezate pe o grila cu pasul
	# `r` — deci se SUPRAPUN mult si iese o suprafata continua, nu niste
	# discuri (exact ce scrie flock.gd despre crusta de sare).
	#
	# RAZA SE SCADE DIN INSET, si asta e un bug reparat pe CAPTURA, nu pe
	# cifra (docs/bara_vizuala.md, regula zero). Prima versiune retragea
	# CENTRUL placii cu 0,35 m de la contur si scria in comentariu ca asa
	# „placa nu iese din spatele zidului". Fals: placa are raza 3,2 x 1,12 =
	# 3,58 m, deci iesea 3,23 m PESTE zid. Pe A_r14_f002.png se vede limpede
	# in dreapta — o limba de iarba atarnand peste fata de piatra, ca o fata
	# de masa. Marginea trebuie sa fie `r_efectiv`, nu o constanta.
	#
	# Placa e o suprafata, nu un stol: scara ramane 1.0 pe toate. Variatia ar
	# lasa goluri intre placi prin care s-ar vedea solul de sub terasa.
	var r := 3.2
	var y := base_y + lift - 0.06
	# Zidul are ~0,6 m grosime la inaltimile astea; placa se opreste cu raza
	# ei inauntrul fetei INTERIOARE, deci nu se vede de afara deloc.
	var inset := r + 0.30
	var span_u := maxf(0.0, w - 2.0 * inset)
	var span_v := maxf(0.0, dpt - 2.0 * inset)
	var nu := maxi(1, int(ceil(span_u / r)) + 1)
	var nv := maxi(1, int(ceil(span_v / r)) + 1)
	for i in range(nu):
		for j in range(nv):
			var fu: float = 0.5 if nu == 1 else float(i) / float(nu - 1)
			var fv: float = 0.5 if nv == 1 else float(j) / float(nv - 1)
			var su := -span_u * 0.5 + fu * span_u
			var sv := -span_v * 0.5 + fv * span_v
			var q := c + u * su + v * sv
			_podea_pos.append(Vector3(q.x, y, q.y))
			_podea_scl.append(Vector3(1.0, 1.0, 1.0))

	# (c) SCARA intre niveluri — „o scara intre niveluri" din verdict, si
	# singura piesa care spune ca podeaua de sus e CALCABILA, nu un capac.
	#
	# Inaltimea ceruta nu e `lift`, e diferenta reala intre coronament si
	# solul DE SUB SCARA: scara sta in afara terasei, unde terenul poate fi cu
	# pana la `drop` mai jos decat mediana. Ceruta la `lift` fix, o scara
	# asezata pe un sol mai jos s-ar opri sub podea si ar citi ca o treapta
	# rupta (memoria `o-tinta-pe-axa-se-atinge-pe-axa-aia`: tinta e „capul
	# scarii la cota podelei", deci se masoara chiar acolo).
	if absf(stair_side) > 0.01:
		var n_out := v * stair_side
		var sc := c + n_out * (hd + 1.35)
		var s_yaw := atan2(n_out.y, n_out.x)
		var s_sol := _sol_med(sc.x, sc.y)
		var s_h := maxf(0.8, (base_y + lift) - s_sol)
		_at("inca_stair_a", tag + "Scara", sc.x, sc.y, s_yaw,
			_scale_for("inca_stair_a", s_h), "", -0.05)

	# Amprenta, pentru `_cota_terasa`: ce se aseaza deasupra (o casa, un soclu)
	# trebuie sa stea pe PODEA, nu pe solul de sub terasa.
	_terase.append({
		"c": c, "u": u, "v": v, "hw": hw - 1.2, "hd": hd - 1.2,
		"top": base_y + lift,
	})

	# (d) CAMERELE, desenate PE podea (y_off = lift fata de solul lor).
	if rooms_u > 0 and rooms_v > 0:
		var cw := (w - 3.0) / float(rooms_u)
		var cd := (dpt - 3.0) / float(rooms_v)
		_block_abs(c, rooms_u, rooms_v, cw, cd, rot, room_h, 0.22,
			tag + "Cam", base_y + lift, _n_terase * 137)


## Cota PODELEI terasei care contine punctul, sau NAN daca punctul e pe teren.
##
## De ce exista: o casa asezata la 23 m de ax cade acum INAUNTRUL unei terase
## ridicate cu 1,8 m. Cu `_at` (raycast pe teren) ar fi stat la cota solului,
## adica 1,8 m SUB podeaua din jurul ei — ingropata pana la ferestre, cu iarba
## terasei taindu-i peretii. Defectul e exact perechea pe minus a celui pentru
## care a picat runda 6 (acolo zidul plutea peste gol, aici casa se ingroapa
## sub podea), si se vede la fel de prost.
func _cota_terasa(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := NAN
	for t in _terase:
		var d: Vector2 = p - (t["c"] as Vector2)
		if absf(d.dot(t["u"] as Vector2)) <= float(t["hw"]) \
				and absf(d.dot(t["v"] as Vector2)) <= float(t["hd"]):
			# Daca doua terase se suprapun, castiga cea de SUS: o piesa nu
			# poate sta sub podeaua pe care o strapunge.
			if is_nan(best) or float(t["top"]) > best:
				best = float(t["top"])
	return best


## Ca `_at`, dar daca punctul cade pe o terasa, cota vine de la PODEAUA ei.
func _at_terasa(model: String, base: String, x: float, z: float, yaw: float,
		scl: float, mode: String = "", y_off: float = 0.0) -> void:
	var t := _cota_terasa(x, z)
	if is_nan(t):
		_at(model, base, x, z, yaw, scl, mode, y_off)
		return
	_raw(model, base, Vector3(x, t + y_off, z), yaw, scl, mode)


## Zid de sprijin INALT, facut din ASIZE suprapuse in loc de o piesa intinsa.
##
## De ce, masurat pe captura A_r14b_f002.png si pe scara reala din .tscn:
## piesele de zid se scaleaza UNIFORM, deci un zid cerut la 4,90 m iese la
## scara 1,97 — si atunci nu e doar inalt, e si **1,64 m GROS** (0,83 x 1,97)
## si are blocurile de piatra de doua ori mai mari. Pe cadru iesea un panou
## brun-inchis, fara textura de zidarie citibila, exact acolo unde terenul
## cade mai mult sub terasa. Masurat in scena: `terasaStgBSpr` mergea pana la
## scara **2,012**, `terasaDrBSpr` pana la 1,971.
##
## Un zid incas inalt nu e un bloc mai mare, e mai multe ASIZE. Deci peste
## `H_ASIZA` se pun mai multe randuri suprapuse, fiecare aproape de scara 1,
## si grosimea ramane cea a piesei. Randul de sus e cel care da coronamentul,
## deci el se aseaza ultimul si fix sub cota podelei.
##
## Consecinta secundara, dorita: rostul orizontal dintre asize e chiar linia
## pe care o are si zidul de terasa din bara — o dunga de umbra la fiecare
## 2,4 m pe inaltime, care e ce face piatra sa se citeasca drept piatra.
const H_ASIZA := 2.45

func _wall_abs_inalt(a: Vector2, b: Vector2, h: float, y_abs: float,
		tag: String) -> void:
	if h <= H_ASIZA * 1.12:
		_wall_abs(a, b, h, y_abs, tag)
		return
	var n := int(ceil(h / H_ASIZA))
	var hh := h / float(n)
	for k in range(n):
		_wall_abs(a, b, hh, y_abs + float(k) * hh, tag)


## `_wall_side` cu cota ABSOLUTA: piesele nu mai citesc solul, stau toate la
## `y_abs`. Pentru zidul de sprijin al unei terase, unde coronamentul TREBUIE
## sa fie o linie dreapta (e linia podelei).
func _wall_abs(a: Vector2, b: Vector2, h: float, y_abs: float,
		tag: String) -> void:
	var d := b - a
	var total := d.length()
	if total < 1.0:
		return
	var u := d / total
	var yaw := atan2(u.y, u.x)
	var scl_b := _scale_for("inca_wall_b", h)
	var lb: float = float(LEN_X["inca_wall_b"]) * scl_b
	var scl_a := _scale_for("inca_wall_a", h)
	var la: float = float(LEN_X["inca_wall_a"]) * scl_a
	var scl_c := _scale_for("inca_wall_c", h)
	var lc: float = float(LEN_X["inca_wall_c"]) * scl_c
	var t := 0.0
	var guard := 0
	while total - t >= 0.9 and guard < 300:
		guard += 1
		var rest := total - t
		var mdl := "inca_wall_c"
		var real_l := lc
		var s := scl_c
		if rest >= lb - 0.10:
			mdl = "inca_wall_b"
			real_l = lb
			s = scl_b
		elif rest >= la - 0.10:
			mdl = "inca_wall_a"
			real_l = la
			s = scl_a
		if real_l > rest + 0.35:
			# Ultima bucata: se pune oricum, putin suprapusa, ca fata de
			# sprijin sa nu aiba gauri prin care se vede solul de sub terasa.
			real_l = rest
			mdl = "inca_wall_c"
			s = scl_c
			var cq := a + u * (total - lc * 0.5)
			_raw(mdl, tag, Vector3(cq.x, y_abs, cq.y), yaw, s, "")
			break
		var cp := a + u * (t + real_l * 0.5)
		_raw(mdl, tag, Vector3(cp.x, y_abs, cp.y), yaw, s, "")
		t += real_l


## `_block`, dar toate zidurile la cota ABSOLUTA `y_abs` (camerele de pe o
## terasa stau pe podeaua ei, nu pe solul de dedesubt).
func _block_abs(c: Vector2, nu: int, nv: int, cw: float, cd: float,
		rot: float, h: float, h_var: float, tag: String, y_abs: float,
		seed_off: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 770000 + seed_off
	var u := Vector2(cos(rot), sin(rot))
	var v := Vector2(-sin(rot), cos(rot))
	var o := c - u * (float(nu) * cw * 0.5) - v * (float(nv) * cd * 0.5)
	for j in range(nv + 1):
		for i in range(nu):
			var a := o + u * (float(i) * cw) + v * (float(j) * cd)
			var gt := 0.5 if rng.randf() < 0.30 else -1.0
			_wall_abs_gate(a, a + u * cw, _h_of(h, h_var, rng), y_abs, gt, tag)
	for i2 in range(nu + 1):
		for j2 in range(nv):
			var a2 := o + u * (float(i2) * cw) + v * (float(j2) * cd)
			var gt2 := 0.5 if rng.randf() < 0.30 else -1.0
			_wall_abs_gate(a2, a2 + v * cd, _h_of(h, h_var, rng), y_abs, gt2,
				tag)


## Latura de camera la cota absoluta, cu poarta optionala de 1,5 m in mijloc.
func _wall_abs_gate(a: Vector2, b: Vector2, h: float, y_abs: float,
		gate_t: float, tag: String) -> void:
	var d := b - a
	var total := d.length()
	if total < 1.0:
		return
	var u := d / total
	if gate_t <= 0.0:
		_wall_abs(a, b, h, y_abs, tag)
		return
	var gc := gate_t * total
	var g0 := maxf(0.0, gc - 0.75)
	var g1 := minf(total, gc + 0.75)
	if g0 > 0.9:
		_wall_abs(a, a + u * g0, h, y_abs, tag)
	if total - g1 > 0.9:
		_wall_abs(a + u * g1, b, h, y_abs, tag)


## TERASELE de pe partea DREAPTA (side = +1), unde platoul tine pana la
## +60 m si unde cade umbra peste drum.
func _terase_dreapta() -> void:
	# RUNDA 14: cele doua tronsoane de zid drept de 60 m de la 39 m de ax au
	# fost SCOASE. Erau ultima bucata din decorul rundelor 8-13 care facea
	# exact ce a numit criticul — „bare lungi paralele asezate una sub alta" —
	# si existau ca sa separe randul din fata de cel din fund. Separarea o face
	# acum caderea de cota intre terase (1,5-2,9 m in fata, 3,4-4,2 m in fund),
	# care e si ce cere verdictul. Un zid drept lasat in fata lor le-ar fi
	# ascuns tocmai fetele de sprijin.
	pass


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
## RUNDA 13, partea a doua — CURTEA, nu camera.
##
## Dupa ce colturile s-au inchis si coronamentul verde a disparut, decupajul
## din masina (crop_r13_dr.png / crop_r13_st.png) inca nu citea incinte pe
## partea dreapta: se vedeau siruri de fete lungi de zid. Comparatia cu
## decupajul barii (bara_crop.png, aceeasi marime pe ecran) arata de ce, si
## nu e nici coltul, nici culoarea — e RAPORTUL PIATRA/IARBA la sol.
##
## In bara, cetatea sta pe o terasa in mare parte DESCHISA: zidurile sunt
## linii rare care delimiteaza curti mari, iar iarba curtii e cea mai mare
## suprafata dupa piatra. La noi erau trei randuri de blocuri de 2x3 camere
## de 7,5 m, adica ziduri la fiecare 7,5 m pe 40 m de adancime: din ochiul
## de la 10 m fiecare zid era acoperit de urmatorul si nu ramanea nicio
## podea vizibila. Masurat pe decupaj: **piatra 61-65% din cadru, iarba
## 27-29%**, iar in bara raportul e invers pe zona de cetate.
##
## Deci camerele nu se mai inmultesc, se MARESC: 12-13,5 m in loc de 7,5 m,
## si 1-2 pe latura in loc de 2-3. Cu zidul tot la 1,8-2,0 m, raportul
## inaltime/latura trece de la 1/4 la 1/7 — capatul pe care runda 11 il
## respinsese fiindca la 10 m latura inelul se rupea. Aici nu se rupe,
## fiindca intre timp `_wall_run` ancoreaza colturile: ce rupea inelul la
## runda 11 nu era latura lunga, erau capetele lasate in aer pe ea.
## (Memoria `revenirea-e-o-mutare-valida`: reglajul respins atunci se
## reincearca acum, cu cauza reala reparata.)
##
## Randul din fund scade de la 4 blocuri la 3 (dreapta) si de la 3 la 2
## (stanga): adancimea vine din doua planuri, nu din trei.

## CAMPUL DIN DREAPTA: blocuri de camere, doua randuri de adancime.
## Fiecare bloc e rotit usor fata de drum (+/- 0,08..0,15 rad): in bara,
## incintele nu sunt toate pe aceeasi axa, si micile diferente de unghi sunt
## ce face ca laturile lungi sa NU se mai alinieze intr-o dunga unica.
## RUNDA 14: campul din dreapta nu mai e un camp, e o SCARA DE TERASE.
##
## Cotele sunt alese ca vecinele sa difere, nu ca sa urce monoton (verdictul
## cere „ALTA cota decat vecina ei", nu „mai sus"). Randul din fata, la 24-27 m
## de ax, alterneaza 1,5 / 2,4 / 1,8 / 2,9 / 1,6; randul din fund, la 50-54 m,
## sta la 3,4-4,2 m, deci podelele lui se vad PESTE coronamentul randului din
## fata — care e chiar linia podelei din fata. Asta e ce n-a putut da nicio
## runda de pana acum din inaltimi de zid: doua plane orizontale la cote
## diferite, unul peste altul, amandoua vizibile din masina.
##
## Fata de sprijin cea mai apropiata e la 24 - 8 = 16,0 m de ax. Semi-latimea
## e 9,0 m, deci 7,0 m de la muchie — peste cei 3,0 m de respiro ai notei 2,
## si `ProbeLaneClear` (marja 2 fata de baza 20) nu are ce sa vada.
func _camp_dreapta() -> void:
	# [frac, lat, w, dpt, rot_rel, lift, camere_u, camere_v, h_camera, scara]
	#
	# CAMERELE SUNT PUTINE ANUME. Prima rulare a rundei 14 pusese 2x1 / 1x2 pe
	# fiecare terasa, si captura A_r14_f000.png arata ca refacea singura
	# defectul rundei 13: zidurile de camera stau PE podea, deci se aduna cu
	# zidul de sprijin si acopera exact suprafata pe care terasa tocmai o
	# castigase. Podeaua e ce cere criticul; camera pe ea e punctuatie, nu
	# umplutura. Doua terase din cinci raman COMPLET goale — o curte de iarba
	# incadrata de zidul ei de sprijin e deja o incinta inchisa cu podea.
	for sp: Array in [
			[-0.0050, 26.0, 24.0, 17.0, 0.09, 1.50, 1, 1, 1.30, -1.0],
			[0.0080, 27.0, 25.0, 18.0, -0.11, 2.40, 0, 0, 0.0, -1.0],
			[0.0210, 26.0, 24.0, 17.0, 0.13, 1.80, 1, 1, 1.35, -1.0],
			[0.0345, 27.0, 25.0, 18.0, -0.08, 2.90, 0, 0, 0.0, -1.0],
			[0.0465, 26.0, 22.0, 16.0, 0.10, 1.60, 1, 1, 1.30, -1.0]]:
		_plt(sp, "terasaDr")
	# Randul din fund. Ridicarile de 3,4-4,2 m sunt ce face ca podeaua LUI sa
	# se vada peste terasa din fata: podeaua din fata e la 1,5-2,9 m, deci
	# diferenta e 0,5-2,7 m — destul cat privirea de la 10 m sa prinda si a
	# doua suprafata de iarba, nu doar capul zidului.
	for sp: Array in [
			[-0.0030, 52.0, 26.0, 18.0, -0.14, 3.60, 1, 1, 1.40, 0.0],
			[0.0150, 53.0, 27.0, 19.0, 0.12, 4.20, 0, 0, 0.0, 0.0],
			[0.0335, 52.0, 26.0, 18.0, -0.10, 3.40, 1, 1, 1.45, 0.0]]:
		_plt(sp, "terasaDrB")


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
	# Randul din fata, de la +0.004 (unde -22 m e sigur platou). Cotele
	# alterneaza ca pe dreapta, dar DEFAZAT: unde dreapta e sus, stanga e jos.
	# Din masina cele doua parti se vad in acelasi cadru, si daca ar urca la
	# fel ar citi ca o singura terasa taiata de sosea, nu ca doua niveluri.
	for sp: Array in [
			[0.0070, -25.0, 24.0, 17.0, -0.12, 2.60, 1, 1, 1.30, 1.0],
			[0.0210, -25.0, 25.0, 18.0, 0.10, 1.50, 0, 0, 0.0, 1.0],
			[0.0345, -24.0, 23.0, 16.0, -0.09, 2.20, 1, 1, 1.35, 1.0],
			[0.0470, -25.0, 22.0, 16.0, 0.13, 1.70, 0, 0, 0.0, 1.0]]:
		_plt(sp, "terasaStg")
	# Randul din fund, de la +0.014: la -44 m platoul incepe la +0.006, iar
	# terasa are 18 m adancime, deci centrul ei nu poate cobori sub +0.012.
	for sp: Array in [
			[0.0175, -46.0, 26.0, 18.0, 0.14, 3.80, 1, 1, 1.40, 0.0],
			[0.0355, -46.0, 25.0, 18.0, -0.11, 3.30, 0, 0, 0.0, 0.0]]:
		_plt(sp, "terasaStgB")


## Dezambalarea unei specificatii de TERASA:
## [frac, lat, w, dpt, rot_rel, lift, camere_u, camere_v, h_camera, scara]
func _plt(sp: Array, tag: String) -> void:
	var fr: float = sp[0]
	var c := _pt(fr, float(sp[1]))
	_platforma(c, float(sp[2]), float(sp[3]), _yaw_at(fr) + float(sp[4]),
		float(sp[5]), int(sp[6]), int(sp[7]), float(sp[8]), float(sp[9]),
		tag)


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
	_at_terasa("three_windows", "treiFerestre", c.x, c.y, _yaw_at(f) + PI, 1.0, "", -0.10)
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
	_at_terasa("sun_temple", "templulSoarelui", c2.x, c2.y, _yaw_at(f2) - PI * 0.5,
		1.0, "", -0.12)
	# A doua fatada de nise, pentru cadrul de la frac 0.02: la 0.038 pe
	# dreapta. Piesa `three_windows` e o fatada, nu o cladire — doua exemplare
	# la 45 m distanta citesc ca doua incaperi ale aceluiasi templu, nu ca
	# duplicat (in bara, sirul de nise se repeta pe toata terasa de sus).
	var f3 := 0.0380
	var c3 := _pt(f3, 17.0)
	_at_terasa("three_windows", "treiFerestreB", c3.x, c3.y, _yaw_at(f3) + PI,
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
	_at_terasa("inca_house_a", "casaPaie", c.x, c.y, _yaw_at(f) - PI * 0.5, 1.0, "", -0.10)
	# A doua, pe etajul 1 (ridicata 1,6 m), la frac 0.038: silueta de sus a
	# cetatii pentru cadrul de la frac 0.02.
	# A doua casa sta pe etajul 1, la +1,55 m. Acum etajul e SOLID (soclul
	# plin de sub incinta ei, runda 6), deci casa are pe ce sta: `probe_manual`
	# o masoara fata de teren si o vede ridicata, dar sub ea e zidarie, nu aer.
	# Ca sa nu ramana totusi in lista de „plutesc", coboara la +1,5 m si
	# primeste soclul ei propriu, un inel scund chiar sub amprenta casei.
	var f2 := 0.0380
	var c2 := _pt(f2, 42.0)
	_at_terasa("inca_house_a", "casaPaieB", c2.x, c2.y, _yaw_at(f2) - PI * 0.35,
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
		_at_terasa(String(p[0]), "lama", c.x, c.y, _yaw_at(fr) + float(p[3]), s,
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
	# ZIDURILE NU PRIMESC DISC DE CONTACT. Vezi nota lunga din
	# `track.gd::_prop_contact_discs` — pe scurt: discul are raza din amprenta
	# BAZEI, iar la un zid amprenta bazei e toata lungimea piesei; zidurile
	# fiind INLANTUITE cap la cap, discurile se suprapun garantat, iar
	# materialul lor e BLEND_MODE_MUL, deci umbrele se INMULTESC.
	#
	# Masurat pe cele 802 ziduri ale zonei: maxim 10 discuri peste acelasi
	# punct, 0,74^10 = 0,049 — de aceea 38,2% din `PropContact` se randa la
	# luminanta ZERO, in timp ce terenul nu cobora sub 122. Negrul din cadru
	# era discul, nu umbra si nu o gaura in geometrie.
	if model.begins_with("inca_wall"):
		_out.append('metadata/contact = "none"')
	_out.append("")
	return pos


## PODEAUA teraselor, ca UN SINGUR nod `FlockProp`. Vezi nota mare de la
## `_platforma` (1) si (2): mecanismul crustei de sare, slotul 12, materialul
## comun de lume. Un desen pentru toate placile din POI.
func _emit_podea() -> void:
	if _podea_pos.is_empty():
		return
	var pos: Array[String] = []
	var scl: Array[String] = []
	for i in _podea_pos.size():
		var p := _podea_pos[i]
		var s := _podea_scl[i]
		pos.append("%f, %f, %f" % [p.x, p.y, p.z])
		scl.append("Vector3(%f, %f, %f)" % [s.x, s.y, s.z])
	_out.append('[node name="A_PodeaTerase" type="MultiMeshInstance3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("flock")')
	# 12 = CACTUS_GREEN: singurul verde din atlas mai DESCHIS decat
	# `ground_tint` (111,8 fata de 101,2 luminanta Rec.709) — nota (2).
	_out.append("disc_slot = 12")
	_out.append("disc_radius = 3.20")
	# FUSTA — reparatia rundei 15, decisa pe CAPTURA (A_r0_f0035.png,
	# crop_right_002.png), nu pe cifra.
	#
	# Ce se vedea: podeaua unei terase e o placa PLATA cu o singura fata, deci
	# de la camera de joc (10 m inaltime, privire in jos-inainte) se vede fata
	# ei de sus SI pe sub muchia ei libera — iar sub muchie nu e nimic. Pe
	# captura, fiecare curte iese o TAVA verde care pluteste, cu negru
	# dedesubt si cu zidul de sprijin in spatele ei, nu sub ea. Exact ce a
	# numit criticul valului 3 „fara interior": ce se inchide nu e pamant, e
	# o foaie suspendata.
	#
	# `disc_skirt` exista in flock.gd de la POI D si face fix asta — placa
	# devine PRISMA, si prismele suprapuse dau un BLOC de pamant retinut de
	# zid. Comentariul de langa `@export` spune chiar ca implicitul 0 s-a
	# pastrat ca sa nu atinga „terasele lui POI A, care sunt deja acceptate
	# asa". Nu sunt: criticul le-a respins de trei ori. Mecanismul era scris
	# si nerulat (memoria `garda-existenta-nerulata`).
	#
	# CIFRA: 1,50 m = cea mai MICA ridicare din tot POI-ul (`_camp_dreapta`
	# si `_camp_stanga`: lift merge 1,50 .. 4,20). Fusta e o proprietate a
	# MESH-ului, deci una singura pentru toate placile; aleasa la minimul
	# ridicarilor, nicio fusta nu coboara sub talpa zidului ei de sprijin,
	# deci nu apare masa bruna sub piatra. Pe terasele mai inalte masa se
	# opreste mai sus decat solul — corect si suficient: zidul de sprijin
	# urca pana la coronament (`lift + drop`), deci acopera tot ce e sub el.
	_out.append("disc_skirt = 1.50")
	# 4 = ROCK_DARK (#67421F), pamantul brun. NU slotul 12: fusta cu iarba
	# iese cutie verde si citeste a gard viu, nu a pamant taiat (masurat pe
	# D_r14_frac0.44.png, nota de la `disc_skirt_slot`). Slot existent in
	# atlas -> ZERO materiale noi.
	_out.append("disc_skirt_slot = 4")
	# Fara variatie de scara: podeaua e o SUPRAFATA, nu un stol. Variatia ar
	# lasa goluri intre placi prin care s-ar vedea solul de sub terasa.
	_out.append("scale_min = 1.0")
	_out.append("scale_max = 1.0")
	_out.append("seed_value = 140901")
	# NU se reaseaza pe teren: cota lor E cota terasei, tot rostul lor.
	# `snap_to_ground` le-ar tari la pamant si ar sterge exact platforma.
	_out.append("snap_to_ground = false")
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(pos))
	_out.append("scale3_list = [%s]" % ", ".join(scl))
	_out.append("")
	print("; podea: %d placi pe %d terase, slot 12, un singur MultiMesh" % [
		_podea_pos.size(), _n_terase])


func _write() -> void:
	_emit_podea()
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
