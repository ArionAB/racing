extends Node
## Generator de decor MANUAL pentru POI H — CORNISA PODULUI INCAS
## (Track15, Machu Picchu, frac 0.94-1.00).
##
## Ca la Serengeti (gen_decor_ser_d.gd) si ca la POI G (gen_decor_mp_g.gd): nu e
## sonda, e unealta care CALCULEAZA transformarile ce se lipesc in Track15.tscn
## sub `DecorManual/ZoneH_Cornisa`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpH.tscn -- \
##       --out=C:/cale/zoneH.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui, curbura) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_machu/bara_poi_H.png)
##
## Citit din decupaj, in ordinea in care sare in ochi:
##  1. POARTA DE PIATRA peste drum — un portal trapezoidal prin care trece
##     soseaua, cu zidarie masiva de o parte si de alta a lui. E lucrul care
##     face cadrul: drumul INTRA undeva.
##  2. DRUMUL E TINUT DE ZIDARIE. Sub carosabil, pe partea golului, se vede
##     fata de piatra care il sprijina — aceeasi lectie ca la POI G, dar aici
##     mai importanta fiindca e o CORNISA: peretele e vertical si drumul e o
##     polita pe el.
##  3. PERETELE PE CEALALTA PARTE, cu vegetatie agatata: copaci verzi care ies
##     din stanca, tufe, bolovani cu muschi. Stanca e in umbra, verdele e aprins.
##  4. ZIDURI JOASE DE PIATRA pe marginea dinspre perete, ca punctuatie de
##     cetate (in bara sunt terase joase).
##  5. Cerul/golul pe o singura parte — jumatate de cadru e gol luminos.
##
## Bara e LOOK, nu LAYOUT (docs/track_briefs/machu_picchu_poi_gauntlet.md).
## Nu se redeseneaza traseul; se compara MATERIA: granit cald, verde de padure
## de nori, silueta de cornisa.
##
## ------------------------------------------------------------------------
## SURVEY R1 (--survey, H_r1_survey.txt) — cifrele care decid compozitia.
## Traseu 1986,4 m pe 1111 puncte. Soare rot (-40, 45, 0), lumina merge spre
## (-0,54, -0,64, -0,54), elevatie 40 grade, umbra pe XZ -> (-0,707, -0,707).
##
## 1. FELIA 0,928-0,965 E O DREAPTA PERFECTA: x = -140,0 constant, y_drum = 0,0
##    constant, merge pe +Z de la z=35,8 la z=106. `side` = (-1, 0) pe toata
##    portiunea, deci **-side = +X** si **+side = -X**. Curbura ~0.
##    Abia dupa 0,976 traseul coteste spre piata (side se roteste la (0, +1)).
##
## 2. CARE PARTE E GOLUL, MASURAT (cote fata de sosea):
##      lateral:      -40     -25     -15      -8  |   +8    +15    +25    +40
##      frac 0,9300  -11,5   -11,6   -10,3    -2,5 | -0,2   +1,8  +28,1  +68,5
##      frac 0,9400  -12,3   -12,3   -11,1    -2,5 | -0,3   +1,1  +19,9  +50,2
##      frac 0,9500  -12,2   -12,3   -11,1    -2,9 | -0,3   -0,0   +5,2  +14,4
##    Deci GOLUL e pe **-side (+X)**: -11..-12,3 m, si caderea incepe intre 8 si
##    15 m lateral. PERETELE e pe **+side (-X)**: urca la +28 m la 25 m lateral
##    si +68 m la 40 m — flancul lui Huayna Picchu din brief, real, nu fundal.
##    E rapa 4 (`custom_ravines` 0,912-0,9809, latime 40, partea -1), deci
##    prapastia EXISTA in teren pe toata felia; nu e de sapat.
##
## 3. GATUIREA E DEJA IN TRASEU si nu se atinge: `custom_width_segments`
##    (0,9631, 0,9703, 4) — semi-latimea scade 6,00 -> 4,00 intre 0,955 si
##    0,964, tine 4,00 pana la 0,9655, apoi sare la 6,02 si creste la 9,00
##    (piata). Masurat: half 5,11 la 0,955; 4,43 la 0,959; 4,00 la 0,964.
##    Deci poarta se pune ACOLO, nu se muta drumul si nu se largeste poarta.
##
## 4. CAT DE LUMINAT E CE. `dot(side, umbra)` = **+0,71 pe toata dreapta**,
##    adica umbra merge spre -side (+X, golul). Peretele de pe +side (-X) ia
##    soarele in plin, golul si fata zidului de sprijin stau in umbra — exact
##    contrastul din bara (stanca aprinsa sus, gol intunecat jos).
##    Nu se reaseaza soarele: azimutul e al pistei intregi.
##
## 5. BARNELE (`BarnePodIncas`, x=-140, z=63,86) cad la **frac 0,9435**, unde
##    survey-ul da sol -2,6 m la 8 m lateral si -11,1 m la 15 m. Deci sub gol
##    terenul chiar coboara — dar abia dupa umarul de 8 m.
##
## ------------------------------------------------------------------------
## CAPCANELE DECLARATE ALE POI-ULUI (gauntlet §H)
##
## 1. POARTA: REZOLVATA, si toate cele trei cifre din inventar erau corecte.
##
##    Gauntlet-ul spune ca `main_gate` are 7,39 m liber, nu 8,39, si ca brief-ul
##    cere 8 m la baza pentru imbranceala cu 4 masini — deci marja ar fi
##    negativa. Masurat cu `tools/ProbeMpHGate.tscn` (proiectia triunghiurilor
##    pe planul (lateral, y), grila de 1 cm — memoria
##    cota-de-contract-se-masoara-ca-gol: un contract care e GOL nu se citeste
##    din AABB):
##
##      fereastra y = 0,15..0,60  ->  **8,300 m**   (= "8,390 baza" din inventar)
##      fereastra y = 0,15..1,80  ->  **8,120 m**   (GABARITUL MASINII)
##      fereastra y = 0,15..5,80  ->  **7,420 m**   (= "7,410 sus" din inventar,
##                                                    si 7,39 din masuratori §3)
##
##    Usciorii sunt in TALUZ — poarta e trapezoidala, cum o descrie chiar
##    brief-ul — deci golul se stramteaza cu inaltimea, si cele trei cifre sunt
##    trei taieturi prin aceeasi piesa, nu o contradictie. masuratori.md §3 a
##    masurat pana sub buiandrug si a citit corect 7,39; dar masina nu trece pe
##    la 5,8 m inaltime. In fereastra pe care o ocupa caroseria golul e
##    **8,120 m pe un drum de 8,00 m**, deci brief-ul se CONFIRMA cu marja
##    +0,12 m, iar poarta chiar e gatuirea ceruta.
##
##    Poarta ramane la SCARA 1: "corectata" la 8,0 s-ar pierde marja, nu s-ar
##    castiga conformitate (gauntlet §H). Se verifica oricum cu ProbeRace si
##    ProbeLaneClear ca plutonul trece — cifra de geometrie nu conduce
##    (memoria proberace-la-inceput-nu-la-final).
##
## 2. Barnele (`BarnePodIncas`, frac 0,9435) aduc rampele podului mobil:
##    un damb de RAMP_RISE = 1,6 m pe 5,0 m la fiecare buza. Deci profilul nu
##    citeste "barne peste gol", ci "cocoasa-gaura-cocoasa"; si SUB gol
##    terenul ramane sus, deci nu e prapastie. Asta e o problema de TEREN
##    (sapatura locala), nu de decor manual — si terenul nu e treaba POI-ului
##    (traseul a trecut ProbeLayout). Ce poate face decorul: sa puna piatra
##    care CITESTE ca buza de prapastie in jurul golului, si sa raporteze ce
##    se vede pe captura cu --bridge-at=0.24.
##
## 3. `main_gate` si `inti_punku` au primit clasa `inca_stone` la integrarea
##    valului 1: portile sunt granit cu rosturi, nu atlas plat. Zidaria de
##    aici (inca_wall_*) foloseste ACEEASI clasa — zero materiale noi.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneH_Cornisa"

const F_IN := 0.9280
const F_OUT := 0.9990

## id-urile ext_resource din Track15.tscn (fundatia).
const RES := {
	"main_gate": "s_main_gate",
	"inca_bridge_ledge": "s_inca_bridge_ledge",
	"rope_rail": "s_rope_rail",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"tree_fern": "s_tree_fern",
	"bromeliad": "s_bromeliad",
	"orchid_cluster": "s_orchid_cluster",
	"trail_marker": "s_trail_marker",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
## Scara se cere in METRI si se imparte la cifra de aici.
const HEIGHT := {
	"main_gate": 7.500, "inca_bridge_ledge": 12.900, "rope_rail": 1.045,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "tree_fern": 3.306,
	"bromeliad": 0.377, "orchid_cluster": 0.390, "trail_marker": 1.200,
}

## Raza de DEGAJARE la sol (m) la scara 1: raza corpului fizic.
const BASE_R := {
	"main_gate": 8.45, "inca_bridge_ledge": 15.28, "rope_rail": 2.07,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "tree_fern": 0.54,
	"bromeliad": 0.46, "orchid_cluster": 0.17, "trail_marker": 0.29,
}

const CROWN_R := {
	"main_gate": 8.45, "inca_bridge_ledge": 15.28, "rope_rail": 2.07,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 1.39, "polylepis_b": 2.27, "tree_fern": 2.07,
	"bromeliad": 0.46, "orchid_cluster": 0.17, "trail_marker": 0.29,
}

const TRI := {
	"main_gate": 588, "inca_bridge_ledge": 914, "rope_rail": 92,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098, "tree_fern": 768,
	"bromeliad": 248, "orchid_cluster": 410, "trail_marker": 76,
}

const EDGE_KEEP := 0.8

# ------------------------------------------------------------------ constante

## Partea pe care cade golul, citita din survey (nota 2) si RE-verificata la
## fiecare asezare cu `_gap_side`: -side, adica +X pe dreapta. Nu se hardcodeaza
## un "stanga/dreapta" — se citeste terenul, ca la POI G.

## POARTA. Fractia unde semi-latimea e deja la minimul ei (4,00 m) din
## `custom_width_segments`. Masurat cu ProbeMpHGate: golul portii in gabaritul
## masinii (y 0,15-1,80) e 8,120 m pe un drum de 8,00 m, deci trece plutonul cu
## marja +0,12 m. Poarta ramane la SCARA 1: "corectata" la 8,0 s-ar pierde marja
## (gauntlet §H).
const GATE_FRAC := 0.9640

## ZIDUL DE SPRIJIN pe buza golului. Lectiile rundelor 1-9 de la POI G, luate
## de-a gata (gen_decor_mp_g.gd): zidul se lipeste de ASFALT (fata interioara pe
## muchie), varful iese cu LIP peste sosea, corpul se ingroapa in taluz, si
## piesele se SUPRAPUN ca sa nu se vada crestatura dintre ele.
const LIP := 0.25              # cat iese coama peste cota drumului
const WALL_H := 2.487
const WALL_HALF_THICK := 0.43  # jumatatea grosimii masurate (0,83-0,86 m)
const WALL_LEN := {"inca_wall_a": 4.0, "inca_wall_b": 6.0, "inca_wall_c": 2.0}
const WALL_OVERLAP := 0.75     # pasul = L * asta, deci fetele se incaleca 25 %
const WALL_MAX_SAGITTA := 0.12
const WALL_POLY_STEP := 0.5
## Cate cursuri se stivuiesc. Aici caderea masurata e 11-12 m, dar din masina se
## vad primele doua (ochiul la ~1,5 m, zidul la 4-6 m lateral: sub 35 de grade
## nu mai intra in cadru). Al treilea curs se vede doar de departe, la intrarea
## pe cornisa, si acolo chiar conteaza — de aia 3, nu 2 ca la POI G.
const WALL_COURSES := 3

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _skipped := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0


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
	_rng.seed = 940971
	_survey()
	if not _survey_only:
		_gate()
		_retaining()
		_gap_lip()
		_cliff_face()
		_understory()
		_citadel_walls()
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
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        curb(1/m)  sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.012
	while f <= F_OUT + 0.004:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+7.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.4f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %+8.4f  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, _curv(i), " ".join(cols),
			s.dot(shadow)])
		f += 0.002


func _curv(i: int) -> float:
	var n := _track.baked.size()
	var a: Vector3 = _track.baked[(i - 3 + n) % n]
	var b: Vector3 = _track.baked[i]
	var c: Vector3 = _track.baked[(i + 3) % n]
	var t0 := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var t1 := Vector3(c.x - b.x, 0.0, c.z - b.z)
	var l := t0.length() + t1.length()
	if l < 0.01:
		return 0.0
	var s := _track._side_at(i)
	var dth := t1.normalized().angle_to(t0.normalized())
	var sgn := signf(t1.normalized().dot(s))
	return sgn * absf(dth) / (l * 0.5)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ compozitia

## (1) POARTA PRINCIPALA — lucrul care face cadrul.
##
## In bara, portalul de piatra e ce transforma un drum pe stanca intr-o INTRARE.
## Se pune exact pe gatuirea deja taiata in traseu (survey, nota 3: semi-latimea
## 4,00 m la 0,9631-0,9703), cu axa ei pe axa drumului si perpendiculara pe el.
##
## Coliziunea e `mesh` (PROP_COLLISION, masuratori §4): un `hull` peste o poarta
## e un bloc plin de 16,80 x 7,50 m fix peste sosea. Golul masurat E contractul.
##
## Yaw: piesa are anvergura pe X-ul ei local (AABB 16,80 pe x, 2,70 pe z), deci
## X-ul local trebuie sa cada pe VECTORUL LATERAL al drumului, nu pe tangenta.
func _gate() -> void:
	var n := _track.baked.size()
	var i := int(GATE_FRAC * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	# X-ul local pe `side`: Basis.from_euler(0, yaw, 0) are coloana X =
	# (cos yaw, 0, -sin yaw). O egalez cu `side`.
	var yaw := atan2(-s.z, s.x)
	# Cota: talpa pe SOSEA, nu pe teren. Poarta sta pe carosabil, si carosabilul
	# e la p.y; terenul de sub el poate fi mai jos (cornisa).
	_raw("main_gate", "poarta", Vector3(p.x, p.y, p.z), yaw, 1.0, "mesh")
	print("; poarta la frac %.4f, (%.1f, %.1f, %.1f), yaw %.1f deg, semi-latime %.2f m (drum %.2f), gol masurat 8,120 m" % [
		GATE_FRAC, p.x, p.y, p.z, rad_to_deg(yaw), half, 2.0 * half])


## Partea pe care CADE golul la indexul i, citita din teren la 15 si 25 m
## lateral (ca la POI G). Nu se hardcodeaza: survey-ul spune -side pe dreapta,
## dar la capetele feliei traseul coteste si relatia se schimba.
func _gap_side(i: int) -> float:
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var dl := 0.0
	var dr := 0.0
	for off: float in [15.0, 25.0]:
		var l := p + s * -off
		var r := p + s * off
		dl += _sol_real(l.x, l.z) - p.y
		dr += _sol_real(r.x, r.z) - p.y
	return -1.0 if dl < dr else 1.0


class WallPt:
	var pos: Vector3
	var road_y: float
	var sgn: float
	var frac: float
	var idx: int


## (2) ZIDUL DE SPRIJIN pe buza golului — a doua obligatie a barei.
##
## Aici e mai important decat la POI G: o CORNISA e prin definitie o polita pe
## un perete, si ce o face sa citeasca asa e sa vezi ca drumul e TINUT de ceva.
## Fara zid, cornisa e o panglica de asfalt care pluteste peste o rapa.
##
## Tot mecanismul vine de-a gata din gen_decor_mp_g.gd, unde a fost gasit in
## noua runde de captura; ce se schimba aici sunt doar doua cifre, si amandoua
## din survey:
##  - 3 cursuri in loc de 2: caderea masurata e 11-12 m si dreapta lunga lasa
##    zidul sa se vada de departe la intrarea pe cornisa, nu doar de alaturi.
##  - fara cautare de "contur de cadere": felia e o dreapta cu rapa declarata,
##    deci zidul se lipeste de asfalt prin constructie.
func _retaining() -> void:
	var n := _track.baked.size()
	var line: Array[WallPt] = []
	var f := F_IN
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := _gap_side(i)
		var half := _track.width_at_index(i)
		var lat := half + WALL_HALF_THICK
		var p := _track.baked[i]
		var q := p + _track._side_at(i) * sgn * lat
		var w := WallPt.new()
		w.pos = Vector3(q.x, p.y, q.z)
		w.road_y = p.y
		w.sgn = sgn
		w.frac = f
		w.idx = i
		line.append(w)
		f += _step(WALL_POLY_STEP)
	var k := 0
	var head := Vector3.INF
	var head_w: WallPt = null
	var placed := 0
	while k < line.size() - 1:
		var a: WallPt = line[k]
		var b: WallPt = line[k + 1]
		var jump := Vector3(b.pos.x - a.pos.x, 0.0, b.pos.z - a.pos.z).length()
		if a.sgn != b.sgn or jump > 5.0:
			head = Vector3.INF
			head_w = null
			k += 1
			continue
		if head == Vector3.INF:
			head = a.pos
			head_w = a
		# Cea mai LUNGA piesa care mai urmeaza curba (sageata sub prag). Pe
		# dreapta trec toate, deci iese cea de 6 m si proportia e buna de la
		# sine (lectia rundei 9b de la POI G: un zid citeste ca zid fiindca e
		# mai LAT decat INALT).
		var mdl := "inca_wall_c"
		for cand: String in ["inca_wall_b", "inca_wall_a", "inca_wall_c"]:
			if _line_sagitta(line, k, WALL_LEN[cand]) <= WALL_MAX_SAGITTA:
				mdl = cand
				break
		var seg: float = WALL_LEN[mdl] * WALL_OVERLAP
		var j := k + 1
		var broke := false
		while j < line.size():
			var pj: WallPt = line[j]
			var pv: WallPt = line[j - 1]
			if pj.sgn != pv.sgn or Vector3(pj.pos.x - pv.pos.x, 0.0,
					pj.pos.z - pv.pos.z).length() > 5.0:
				broke = true
				break
			if Vector3(pj.pos.x - head.x, 0.0, pj.pos.z - head.z).length() >= seg:
				break
			j += 1
		if broke or j >= line.size():
			head = Vector3.INF
			head_w = null
			k = j
			continue
		var tip := _chord_point(head, line[j - 1].pos, line[j].pos, seg)
		if _place_wall(mdl, head, tip, head_w, line[j]):
			placed += 1
		head = tip
		head_w = line[j]
		k = j - 1
	print("; zid de sprijin: %d imbinari asezate" % placed)


func _line_sagitta(line: Array[WallPt], k: int, span: float) -> float:
	var p0: Vector3 = line[k].pos
	var j := k + 1
	while j < line.size():
		var pj: WallPt = line[j]
		var pv: WallPt = line[j - 1]
		if pj.sgn != pv.sgn or Vector3(pj.pos.x - pv.pos.x, 0.0,
				pj.pos.z - pv.pos.z).length() > 5.0:
			return 999.0
		if Vector3(pj.pos.x - p0.x, 0.0, pj.pos.z - p0.z).length() >= span:
			break
		j += 1
	if j >= line.size():
		return 999.0
	var p1 := _chord_point(p0, line[j - 1].pos, line[j].pos, span)
	var d := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	var l := d.length()
	if l < 0.01:
		return 999.0
	var dir := d / l
	var worst := 0.0
	for t in range(k, j + 1):
		var q: Vector3 = line[t].pos
		var v := Vector3(q.x - p0.x, 0.0, q.z - p0.z)
		var along: float = v.dot(dir)
		if along < 0.0 or along > l:
			continue
		worst = maxf(worst, (v - dir * along).length())
	return worst


func _chord_point(c: Vector3, p0: Vector3, p1: Vector3, r: float) -> Vector3:
	var d := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	var m := Vector3(p0.x - c.x, 0.0, p0.z - c.z)
	var aa := d.dot(d)
	if aa < 1e-9:
		return p1
	var bb := 2.0 * m.dot(d)
	var cc := m.dot(m) - r * r
	var disc := bb * bb - 4.0 * aa * cc
	if disc < 0.0:
		return p1
	return p0.lerp(p1, clampf((-bb + sqrt(disc)) / (2.0 * aa), 0.0, 1.0))


func _place_wall(mdl: String, p0: Vector3, p1: Vector3, w0: WallPt,
		w1: WallPt) -> bool:
	var d := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	if d.length() < 0.01:
		return false
	var tang := d.normalized()
	var mid := (p0 + p1) * 0.5
	# Coama urmeaza cota SOSELEI: pe cornisa zidul TINE drumul, deci cota lui e
	# a drumului, nu a terenului de alaturi — dincolo de el nu mai e teren.
	var top := (w0.road_y + w1.road_y) * 0.5 + LIP
	var side := _track._side_at(w0.idx) * w0.sgn
	var probe := mid + side * 0.6
	var foot: float = minf(_sol_real(probe.x, probe.z),
		_sampler.ground_y(probe.x, probe.z))
	# Daca dincolo de muchie nu e cadere, zidul n-are ce sprijini si ar citi ca
	# bordura ornamentala (lectia rundelor 2-7 de la POI G).
	if top - foot < 0.8:
		_skipped += 1
		return false
	var yaw := atan2(-tang.z, tang.x)
	var foot_out: float = _sol_real(probe.x, probe.z)
	var courses := int(ceil((top - foot_out) / WALL_H))
	courses = clampi(courses, 1, WALL_COURSES)
	for c in courses:
		var y := top - WALL_H * float(c + 1)
		# Doar cursul de sus poarta coliziune: e singurul care atinge cota
		# soselei. Cele de dedesubt sunt fata de piatra, in gol — un hull acolo
		# ar fi o polita invizibila peste prapastie.
		_raw(mdl, "zidSprijin", Vector3(mid.x, y, mid.z), yaw, 1.0,
			"hull" if c == 0 else "none")
	return true


## (3) BUZA GOLULUI: parapetul de franghie pe marginea care cade, plus bornele.
##
## Amandoua sunt fantome (masuratori §4: `rope_rail` e o placa de 0,15 m
## grosime, `trail_marker` 76 tri la 1,2 m), deci pot sta chiar pe muchie fara
## sa devina obstacol pe umar. Rolul lor e SEMNALUL de margine: in bara marginea
## exterioara e mereu marcata, si fara ea ochiul nu stie unde se termina drumul.
##
## Parapetul se INTRERUPE pe golul cu barne (frac 0,9435 +- traveea): acolo chiar
## nu mai e drum, si un parapet continuu ar minti despre gol. Se intrerupe si sub
## poarta, unde uscioarele sunt chiar marginea.
const BEAM_FRAC := 0.9435
const BEAM_HALF_SPAN := 0.0035   # ~7 m de traseu, cat traveea plus buzele

func _gap_lip() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := _gap_side(i)
		var p := _track.baked[i]
		var half := _track.width_at_index(i)
		var side := _track._side_at(i) * sgn
		var tang := (_track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n])
		tang.y = 0.0
		if tang.length() < 0.01:
			f += _step(4.14)
			continue
		tang = tang.normalized()
		var la_poarta: bool = absf(f - GATE_FRAC) < 0.0045
		var la_barne: bool = absf(f - BEAM_FRAC) < BEAM_HALF_SPAN
		if not la_poarta and not la_barne:
			var q := p + side * (half + 0.45)
			# Cota: pe buza, dar niciodata sub sol (lectia POI G runda 2 — un
			# panou ingropat dispare, unul usor suspendat citeste a parapet).
			var gy := maxf(_sol_real(q.x, q.z), _sampler.ground_y(q.x, q.z))
			_raw("rope_rail", "parapet",
				Vector3(q.x, minf(p.y + LIP, gy + 0.10), q.z),
				atan2(-tang.z, tang.x), 1.0, "none")
			if k % 5 == 0:
				var qb := p + side * (half + WALL_HALF_THICK)
				_raw("trail_marker", "borna",
					Vector3(qb.x, p.y + LIP, qb.z), 0.0,
					_scale_for("trail_marker", 1.2), "none")
		f += _step(4.14)
		k += 1
	# Pietrele de pe buza golului cu barne: nu inchid nimic (traveea trece
	# printre ele), dar dau CAPETE de piatra prapastiei — fara ele profilul e
	# doar cele doua rampe ale hazardului, adica "cocoasa-gaura-cocoasa"
	# (capcana 2 din antet). Se pun in afara carosabilului, pe ambele parti.
	for dz: float in [-1.0, 1.0]:
		var ff := BEAM_FRAC + _step(5.2 * dz)
		var i := int(ff * float(n)) % n
		var sgn := _gap_side(i)
		for sd: float in [sgn, -sgn]:
			# >= EDGE_KEEP de muchie: pietrele sunt `hull`, deci sub 0,8 m
			# ar fi obstacol pe umar chiar in zona unde masina aterizeaza
			# dupa sarit.
			_place("moss_boulder_c", "buzaGol", ff, sd,
				_rng.randf_range(0.9, 1.8), _rng.randf_range(0.0, TAU),
				_scale_for("moss_boulder_c", _rng.randf_range(2.2, 3.0)),
				"hull", -0.6)


## (4) PERETELE: flancul care urca pe partea opusa golului.
##
## Survey nota 2: pe +side terenul urca la +28 m la 25 m lateral si +68 m la
## 40 m. Deci exista PERETE adevarat; ce lipseste e ce sta PE el. In bara,
## peretele nu e stanca goala — e stanca cu vegetatie agatata: bolovani cu
## muschi la baza, copaci verzi care ies din ea, si verdele e lucrul cel mai
## aprins din cadru.
##
## Marimile in gradient (patru-defecte-de-diorama, 3): cei mari in spate, cei
## mici spre drum, ca sa nu iasa un gard de obiecte egale.
func _cliff_face() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var g := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var up := -_gap_side(i)
		var cnt := 2 + (g % 3)
		for j in cnt:
			var mdl := "moss_boulder_c" if j == 0 else (
				"moss_boulder_b" if j % 2 == 1 else "moss_boulder_a")
			var h := _rng.randf_range(2.6, 3.6) if j == 0 else (
				_rng.randf_range(1.4, 2.1) if j % 2 == 1
				else _rng.randf_range(0.6, 1.0))
			var gap := _rng.randf_range(3.2, 8.0) if j == 0 \
				else _rng.randf_range(1.6, 5.5)
			_place(mdl, "bolovan", f + _step(_rng.randf_range(-3.5, 3.5)),
				up, gap, _rng.randf_range(0.0, TAU), _scale_for(mdl, h),
				"hull", -0.15)
		f += _step(8.5 + _rng.randf_range(-2.0, 2.0))
		g += 1
	# copacii agatati de perete, in doua randuri: aproape (coroana intra in
	# cadru pe langa geam) si departe-sus (silueta pe stanca luminata).
	f = F_IN + _step(4.0)
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var up := -_gap_side(i)
		var mdl := "polylepis_b" if k % 3 != 1 else "polylepis_a"
		var h := _rng.randf_range(6.0, 8.2) if mdl == "polylepis_b" \
			else _rng.randf_range(3.8, 4.8)
		_place(mdl, "copac", f, up, _rng.randf_range(2.4, 6.5),
			_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
		# randul de sus, pe fata peretelui: 14-26 m lateral, unde survey-ul da
		# +5..+28 m cota. De acolo se vad ca siluete pe stanca.
		if k % 2 == 0:
			var m2 := "polylepis_a" if k % 4 == 0 else "polylepis_b"
			_place(m2, "copacSus", f + _step(3.0), up,
				_rng.randf_range(14.0, 26.0), _rng.randf_range(0.0, TAU),
				_scale_for(m2, _rng.randf_range(4.2, 7.0)), "trunk")
		f += _step(7.5 + _rng.randf_range(-1.8, 1.8))
		k += 1


## (5) SUBARBORETUL pe perete: ferigi, bromelii, orhidee ca accent rar.
## Stratul de la inaltimea farului, fara care intre iarba si coroane nu e nimic.
## `tree_fern` sta la >= 2,5 m de muchie: coliziunea `trunk` ii da un cilindru
## de 0,537 m raza, de 1,8 ori stipa reala (masuratori §3).
func _understory() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var up := -_gap_side(i)
		if k % 2 == 0:
			_place("tree_fern", "feriga", f, up, _rng.randf_range(2.5, 6.0),
				_rng.randf_range(0.0, TAU),
				_scale_for("tree_fern", _rng.randf_range(2.4, 3.4)), "trunk")
		if _rng.randf() < 0.75:
			_place("bromeliad", "bromelie", f + _step(2.5), up,
				_rng.randf_range(2.1, 5.0), _rng.randf_range(0.0, TAU),
				_scale_for("bromeliad", _rng.randf_range(0.5, 0.9)), "none")
		if _rng.randf() < 0.14:
			_place("orchid_cluster", "orhidee", f + _step(4.5), up,
				_rng.randf_range(2.2, 4.5), _rng.randf_range(0.0, TAU),
				_scale_for("orchid_cluster", _rng.randf_range(0.45, 0.7)),
				"none")
		f += _step(8.0 + _rng.randf_range(-1.8, 1.8))
		k += 1


## (6) ZIDURILE JOASE DE CETATE pe partea peretelui, langa poarta.
##
## In bara, in jurul portalului nu e doar stanca: sunt terase si ziduri joase de
## aceeasi zidarie, care spun ca poarta e intrarea intr-o CETATE, nu un arc
## singuratic in pustiu. Se pun doar in ultimii ~45 m dinaintea portii si imediat
## dupa ea, in siruri scurte paralele cu drumul, esalonate pe doua trepte.
##
## Sunt `hull` si stau pe partea peretelui, la >= 1,6 m de muchie.
func _citadel_walls() -> void:
	var n := _track.baked.size()
	var runs: Array = [
		# frac_start, cate piese, gap de la muchie, treapta (dy)
		[GATE_FRAC - _step(44.0), 5, 1.6, 0.0],
		[GATE_FRAC - _step(26.0), 4, 5.2, 1.1],
		[GATE_FRAC + _step(9.0), 4, 2.0, 0.0],
	]
	for r: Array in runs:
		var f0: float = r[0]
		var cnt: int = r[1]
		var gap: float = r[2]
		var dy: float = r[3]
		for j in cnt:
			var ff: float = f0 + _step(6.0 * float(j))
			var i := int(ff * float(n)) % n
			var up := -_gap_side(i)
			var p := _track.baked[i]
			var s := _track._side_at(i) * up
			var half := _track.width_at_index(i)
			var tang := (_track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n])
			tang.y = 0.0
			if tang.length() < 0.01:
				continue
			tang = tang.normalized()
			# Piesa e lunga pe X-ul ei local si trebuie sa stea PARALEL cu
			# drumul, deci X local pe tangenta.
			var yaw := atan2(-tang.z, tang.x)
			var d := half + gap + 0.43
			var q := p + s * d
			var gy := _sol_real(q.x, q.z)
			# Treapta a doua sta mai sus: e o terasa in spatele primeia.
			_raw("inca_wall_b", "zidCetate",
				Vector3(q.x, gy + dy, q.z), yaw, 1.0, "hull")


# ------------------------------------------------------------------ asezarea

func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull",
		dy: float = 0.0, pitch: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z) + dy
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < half - 1.0:
		_warn += 1
		print("; ATENTIE silueta %s la frac %.4f ajunge la %.2f m de ax (banda %.2f)" % [
			model, frac, d - cr, half])
	if mode != "none" and _on_any_road(q, i, r):
		_skipped += 1
		return
	var smooth := _sampler.ground_y(q.x, q.z)
	var sink := smooth - (g - dy)
	var piece_h: float = float(HEIGHT.get(model, 1.0)) * scl
	var zvelt: bool = model.begins_with("polylepis") or model == "tree_fern"
	var max_sink: float = 0.8 if zvelt else maxf(0.5 * piece_h, 1.0)
	if sink > max_sink:
		_skipped += 1
		return
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode, pitch)


const NEAR_WINDOW_FRAC := 0.012
const OTHER_ROAD_KEEP := 1.2

func _on_any_road(p: Vector3, home_i: int, body_r: float) -> bool:
	var n := _track.baked.size()
	var skip := int(round(float(n) * NEAR_WINDOW_FRAC))
	for i in n:
		var di := absi(i - home_i)
		di = mini(di, n - di)
		if di <= skip:
			continue
		var b: Vector3 = _track.baked[i]
		var dx := b.x - p.x
		var dz := b.z - p.z
		var clear: float = _track.width_at_index(i) + OTHER_ROAD_KEEP + body_r
		if dx * dx + dz * dz < clear * clear:
			return true
	return false


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, pitch: float = 0.0) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri).
	var b := Basis.from_euler(Vector3(pitch, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate, %d avertismente, ~%d triunghiuri" % [
		_n, _skipped, _warn, _tri])
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
## campul neted (memoria terrain-mesh-y-extrapoleaza).
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
