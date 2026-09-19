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
## Unde se OPRESTE zidul de sprijin (restul decorului merge pana la F_OUT).
##
## RUNDA 4: captura `H_r4_f097.png` arata o lespede de piatra care umple
## jumatatea de jos a cadrului — pe `main`, la aceeasi fractie, nu e nimic
## acolo (`BAZA_main_f097.png`), deci e a mea. Masurat pe .tscn, vinovatele sunt
## piesele de la z = 118-136, asezate la 7,4-11,7 m lateral pe o portiune unde
## drumul are deja half 6,6-9,0 si COTESTE spre piata: camera de urmarire
## taie larg prin viraj si trece prin ele.
##
## Cauza de fond nu e distanta, e ca acolo nu mai exista cornisa. Dupa poarta
## traseul iese din rapa (survey: cota la +8 m urca de la -2,6 la -0,3 intre
## 0,968 si 0,976) si intra in piata — un „zid de sprijin" acolo nu sprijina
## nimic si nu are ce cauta. Deci se opreste la poarta, nu se impinge mai
## departe: memoria capcana-parametrului-care-doar-aduna — intrebarea nu e cu
## cat sa-l mut, ci de unde vine forma.
const F_WALL_OUT := 0.9655

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
	"huayna_picchu": "s_huayna_picchu",
	"gorge_far_wall": "s_gorge_far_wall",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
## Scara se cere in METRI si se imparte la cifra de aici.
const HEIGHT := {
	"main_gate": 7.500, "inca_bridge_ledge": 12.900, "rope_rail": 1.045,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "tree_fern": 3.306,
	"bromeliad": 0.377, "orchid_cluster": 0.390, "trail_marker": 1.200,
	"huayna_picchu": 33.000, "gorge_far_wall": 75.393,
}

## Raza de DEGAJARE la sol (m) la scara 1: raza corpului fizic.
const BASE_R := {
	"main_gate": 8.45, "inca_bridge_ledge": 15.28, "rope_rail": 2.07,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "tree_fern": 0.54,
	"bromeliad": 0.46, "orchid_cluster": 0.17, "trail_marker": 0.29,
	"huayna_picchu": 40.80, "gorge_far_wall": 97.42,
}

const CROWN_R := {
	"main_gate": 8.45, "inca_bridge_ledge": 15.28, "rope_rail": 2.07,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 1.39, "polylepis_b": 2.27, "tree_fern": 2.07,
	"bromeliad": 0.46, "orchid_cluster": 0.17, "trail_marker": 0.29,
	"huayna_picchu": 40.80, "gorge_far_wall": 97.42,
}

const TRI := {
	"main_gate": 588, "inca_bridge_ledge": 914, "rope_rail": 92,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098, "tree_fern": 768,
	"bromeliad": 248, "orchid_cluster": 410, "trail_marker": 76,
	"huayna_picchu": 503, "gorge_far_wall": 1706,
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
## Cate cursuri de zidarie se pun sub coama, pe buza golului.
##
## Cifra a fost 3 (r1), 5 (r2, cu retragere pe panta), 5 (r3, cu contact cautat
## per curs) si a ajuns inapoi la 2 — vezi nota lunga din `_place_wall`, care
## spune de ce: pe o DREAPTA, zidul paralel cu soseaua nu intra in cadrul unei
## camere care priveste inainte, deci cursurile de sub primele doua sunt
## geometrie pe care nu o vede nimeni din masina, iar incercarile de a le face
## vizibile (retragere, contact) le-au transformat in panouri inclinate.
##
## Doua cursuri = 4,97 m de fata sub coama: destul cat marginea sa citeasca a
## zidarie si nu a bordura, si atat cat se vede de pe drum.
const WALL_COURSES := 2

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
var _lat_only := false
var _terr_test := false
var _total_len := 1.0
var _lvl_ok: Array[int] = []
var _lvl_no: Array[int] = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
		elif a == "--lat":
			_lat_only = true
		elif a == "--terr-test":
			_terr_test = true
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
	if _lat_only:
		_survey_lateral()
		get_tree().quit(0)
		return
	_survey()
	if not _survey_only:
		_gate()
		_retaining()
		_terraces()
		_gap_lip()
		_cliff_face()
		_understory()
		_citadel_walls()
		_cliff_mass()
		_gap_rock_lip()
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


## Profil lateral FIN pe partea golului: unde exact incepe caderea si cat de
## abrupta e. Survey-ul general masoara la -40/-25/-15/-8; runda 7 are nevoie de
## pasul de 1 m intre 5 si 30 m, fiindca criticul spune ca nu se citeste nicio
## cadere, iar cifra de la 8 -> 15 m (-2,5 -> -11,1) e o PANTA de 8,6 m pe 7 m,
## adica 51 de grade: real, dar neted si acoperit de iarba.
func _survey_lateral() -> void:
	var n := _track.baked.size()
	print("; PROFIL LATERAL pe partea golului (pas 1 m, cote fata de sosea)")
	for f: float in [0.9300, 0.9350, 0.9400, 0.9450, 0.9500, 0.9550, 0.9600, 0.9640]:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var sgn := _gap_side(i)
		var s := _track._side_at(i) * sgn
		var half := _track.width_at_index(i)
		var row: Array[String] = []
		var off := 4.0
		while off <= 30.0:
			var q := p + s * off
			row.append("%.1f" % (_sol_real(q.x, q.z) - p.y))
			off += 1.0
		print("; GOL  frac %.4f half %.2f | %s" % [f, half, " ".join(row)])
		var row2: Array[String] = []
		var off2 := 4.0
		while off2 <= 30.0:
			var q2 := p + s * -off2
			row2.append("%.1f" % (_sol_real(q2.x, q2.z) - p.y))
			off2 += 1.0
		print("; PER  frac %.4f half %.2f | %s" % [f, half, " ".join(row2)])
	print("; (coloane: lateral 4,5,6,...,30 m)")


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
	# COTA. Prima versiune punea talpa pe SOSEA (`p.y`), fiindca poarta sta pe
	# carosabil. Captura `H_test_f0966.png` a aratat ce scapa rationamentul:
	# poarta are 16,80 m ANVERGURA pe un drum de 8,00 m, deci usciorii ei
	# exterioari cad la 4-8 m dincolo de muchie — pe teren, care acolo e la
	# -0,30 m. Rezultatul: blocurile laterale ATARNA IN AER cu 30 cm.
	#
	# Se ia deci cea mai JOASA dintre cota soselei si cotele terenului sub cele
	# doua capete ale piesei. Poarta se afunda cu diferenta (aici ~0,30 m), ceea
	# ce nu schimba nimic pentru masina — golul masurat e 8,120 m in fereastra
	# 0,15-1,80 m peste TALPA, iar buiandrugul ramane la 5,94 m, mult peste
	# gabarit — dar sterge aerul de sub uscioarele exterioare.
	# Prima incercare a luat `min` peste cele doua capete ale anvergurii si a
	# iesit -5,04 m: capatul dinspre gol atarna peste rapa, deci minimul lui e
	# fundul rapei, si poarta s-ar fi ingropat cu 5 m cu tot cu deschidere.
	# Memoria origin-base-ridica-tot-obiectul, in oglinda — o cota luata dintr-un
	# punct nereprezentativ misca TOT obiectul.
	#
	# Ce trebuie de fapt: poarta sa nu atarne pe UMERII drumului, adica pe fasia
	# imediat de langa carosabil, unde chiar e pamant. Se ia cota terenului la
	# +-5 m de ax (inca pe umar la half 4,0) si se afunda cel mult 0,6 m — atat
	# cat sa dispara aerul de sub usciori, fara sa scada gabaritul.
	var um_a := p + s * 5.0
	var um_b := p - s * 5.0
	var y_um: float = minf(_sol_real(um_a.x, um_a.z), _sol_real(um_b.x, um_b.z))
	var y_gate: float = maxf(minf(p.y, y_um), p.y - 0.6)
	_raw("main_gate", "poarta", Vector3(p.x, y_gate, p.z), yaw, 1.0, "mesh")
	print("; poarta: talpa la %.2f (sosea %.2f, umeri %.2f / %.2f), afundare %.2f m" % [
		y_gate, p.y, _sol_real(um_a.x, um_a.z), _sol_real(um_b.x, um_b.z),
		p.y - y_gate])
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
	while f < F_WALL_OUT:
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
	# ------------------------------------------------------------------
	# RUNDA 2: CURSURILE SE RETRAG PE PANTA, NU SE STIVUIESC PE VERTICALA.
	#
	# Runda 1 punea toate cursurile la acelasi `mid`, adica unul sub altul. Pe
	# POI G asta era corect: acolo zidul imbraca o taietura verticala (`scarp`).
	# Aici NU e vertical, si `tools/ProbeMpHCornisa.tscn` a masurat exact cat:
	#
	#   frac    panta 0-3m   0-6m   0-12m    cota la +3 / +6 / +12 m
	#   0.9400    27.2       41.2   40.3      -3.7  -7.4  -12.3
	#   0.9480    28.4       41.2   39.8      -3.9  -7.6  -12.3
	#   0.9560    33.8       39.8   37.8      -5.0  -8.0  -12.3
	#
	# Adica un TALUZ de ~40 de grade adanc de 12,3 m, care incepe la 0,3 m dupa
	# muchie. Un curs pus 2,487 m mai jos la acelasi `mid` intra in deal cu
	# 2,487 / tan(40) = 2,96 m — de aia `probe_manual` le-a raportat INGROPATE
	# cu -3,67 m, si de aia captura H_r1_f0935 arata doar buza de piatra pe o
	# panta verde de 12 m.
	#
	# Cifra nu era un fals pozitiv, cum am presupus cand am citit-o prima data:
	# era chiar defectul, scris pe nume (memoria garda-existenta-nerulata, in
	# varianta ei mai neplacuta — garda rulata si RASTALMACITA).
	#
	# Deci fiecare curs se muta in afara cu cat cere panta LOCALA masurata
	# acolo, si se opreste cand talpa lui a ajuns la teren. Asa fata de piatra
	# urmeaza taluzul in trepte, ca o terasa incasa adevarata, in loc sa se
	# ingroape.
	var foot_out: float = _sol_real(probe.x, probe.z)
	# Panta locala a taluzului, masurata pe primii 6 m dupa muchie: e intervalul
	# pe care cad cursurile 1-3, si singurul care se vede din masina.
	var e6 := mid + side * 6.0
	var drop6: float = maxf(0.0, top - _sol_real(e6.x, e6.z))
	var slope := atan2(drop6, 6.0)
	# Retragerea pe orizontala per curs. Sub 25 de grade panta e destul de lina
	# cat un zid drept sa mai citeasca; peste 60 e practic vertical si retragerea
	# ar rupe lantul, deci se plafoneaza.
	var step_out: float = 0.0
	if slope > deg_to_rad(25.0):
		step_out = WALL_H / tan(clampf(slope, deg_to_rad(25.0), deg_to_rad(60.0)))
	# RUNDA 4: SE REVINE LA STIVA SIMPLA, si motivul e o lectie, nu o retragere.
	#
	# Rundele 2 si 3 au incercat sa faca fata de piatra sa imbrace taluzul: mai
	# intai cu un offset calculat din panta (r2), apoi cu un contact cautat per
	# curs (r3). Amandoua au inrautatit captura:
	#   r2 (H_r2_f0955) — blocuri razlete imprastiate pe panta, 1,3-2,6 m de
	#     plutire masurata cu probe_manual;
	#   r3 (H_r3_f0955) — si mai rau: cursurile isi pastreaza yaw-ul soselei dar
	#     stau la departari si cote diferite, deci lantul citeste ca un sir de
	#     PANOURI CAZUTE, inclinate unul fata de altul.
	#
	# Diagnosticul, dupa a treia captura cu acelasi verdict (memoria
	# criticul-cere-ce-zona-nu-poate-da: acelasi verdict de doua ori inseamna ca
	# la cauza nu se ajunge din zona in care sap):
	#
	#   Felia mea e o DREAPTA (survey nota 1: x = -140 constant pe 70 m). Un zid
	#   paralel cu un drum drept nu se vede dintr-o camera care priveste INAINTE
	#   (memoria perete-paralel-nu-se-vede: doar serpentina spre interior
	#   infasoara peretele). La POI G fata de piatra era eroul fiindca acolo
	#   bucla de deasupra priveste in jos pe bucla de dedesubt; aici nu exista
	#   nicio bucla care sa se uite inapoi la ea.
	#
	# Deci nicio cantitate de cursuri nu poate face din zid eroul POI-ului asta,
	# si fiecare incercare l-a facut doar mai zgomotos pe marginea cadrului. Ce
	# poate face zidul pe o dreapta e sa fie o LINIE CURATA de piatra care
	# margineste drumul — si aia o face stiva simpla, cu 2 cursuri, cel mai bine.
	#
	# Ce lipseste cu adevarat (silueta de stanca a taluzului) e o proprietate a
	# TERENULUI, nu a decorului manual: taluzul e verde fiindca asa il coloreaza
	# tema, si culoarea lui nu e a POI-ului. Se raporteaza, nu se bricoleaza.
	for c in WALL_COURSES:
		var y := top - WALL_H * float(c + 1)
		# Doar cursul de sus poarta coliziune: e singurul care atinge cota
		# soselei. Cel de sub el e fata de piatra deasupra caderii — un hull
		# acolo ar fi o polita invizibila peste prapastie.
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

## ------------------------------------------------------------------ RUNDA 7
## (2b) TERASELE ANDENE PE TALUZ — ce a cerut criticul orb, cuvant cu cuvant.
##
## Verdictul rundei 6: «Lipseste GOLUL. [...] zidul e o singura panglica
## subtire de ~1.5m, iar de cealalta parte terenul e o pajiste verde perfect
## neteda care urca continuu spre orizont: nicio cadere, niciun etaj, niciun
## gol.»
##
## Am masurat premisa inainte sa construiesc (`--lat`, pas de 1 m, cote fata de
## sosea pe partea golului):
##
##   frac 0.9400  half 6.00
##     lateral:  4     5     6     7     8  |  9    10    11    12    13    14
##     cota:   -1.7  -1.9  -2.1  -2.3  -2.5 | -3.7 -4.9  -6.1  -7.4  -8.6  -9.8
##     lateral: 15    16   17..30
##     cota:  -11.1 -12.3  -12.3 (podea plata)
##
## Deci CADEREA EXISTA IN TEREN si e mare: **12,3 m**, pe banda 9-16 m lateral,
## adica 8,6 m de cadere pe 7 m de orizontala = **51 de grade**. Criticul nu se
## inseala insa: 51 de grade de IARBA NETEDA, fara nimic pe ea care sa dea
## scara sau muchie, se citeste ca o pajiste. Nu are nici macar o umbra proprie
## — de aia „umbra lunga din stanga nu are niciun caster".
##
## Asta e reparabil strict in decor, si exact asa cum a spus el: terasele sunt
## decor lateral. Trei etaje de zidarie pe taluz, fiecare cu fata pe verticala
## si cu banda de iarba deasupra ei, transforma panta neteda in trepte care
## arunca umbre si dau scara. Sub ele, pe podeaua de la -12,3 m, bolovani: de
## acolo in jos e piatra, nu pajiste.
##
## DE CE MERGE AICI SI NU A MERS LA ZIDUL DE SPRIJIN (runda 4, nota din
## `_place_wall`). Zidul de sprijin e pe MUCHIE si paralel cu o sosea dreapta,
## deci camera il vede din cutit (memoria perete-paralel-nu-se-vede). Terasele
## nu: ele stau la 9-16 m lateral, **sub** nivelul ochiului, deci camera le vede
## IN PLAN, desfasurate, exact zona care ocupa jumatatea stanga a cadrului in
## `H_r6_f094.png`. Aceeasi piesa, alt loc, alta vizibilitate — nu contrazice
## runda 4, o completeaza.
##
## Geometria unui etaj: fata de piatra e VERTICALA (cursuri stivuite la acelasi
## `mid`, ca la POI G), inalta cat `TERR_RISE`; urmatorul etaj se retrage spre
## exterior cu `TERR_RUN`, deci profilul e scara, nu panta. Retragerea se alege
## din panta reala (51 grade => rise/run = 1,23), ca terasele sa urmeze taluzul
## in loc sa iasa din el sau sa se ingroape.
## ------------------------------------------------------------------ RUNDA 7
## (2b) TERASELE ANDENE PE TALUZ — ce a cerut criticul orb, cuvant cu cuvant.
##
## Verdictul rundei 6: «Lipseste GOLUL. [...] zidul e o singura panglica subtire
## de ~1.5m, iar de cealalta parte terenul e o pajiste verde perfect neteda care
## urca continuu spre orizont: nicio cadere, niciun etaj, niciun gol.»
##
## CADEREA EXISTA IN TEREN, masurata cu `--lat` (pas de 1 m, cote fata de sosea,
## partea golului, frac 0,9400):
##
##   lateral:  4     5     6     7     8  |  9    10    11    12    13    14
##   cota:   -1,7  -1,9  -2,1  -2,3  -2,5 | -3,7 -4,9  -6,1  -7,4  -8,6  -9,8
##   lateral: 15    16   17..30
##   cota:  -11,1 -12,3  -12,3 (podea plata)
##
## 12,3 m de cadere pe banda 9-16 m, adica **51 de grade**. Criticul nu se
## insala totusi: 51 de grade de IARBA NETEDA, fara nimic pe ea care sa dea
## scara sau muchie, se citesc ca pajiste.
##
## DOUA INCERCARI GRESITE, si de ce — amandoua masurate, nu ghicite.
##
## 7a: 51 de fete pe banda 9,5-14,3 m, cu coama la `teren + 0,55`. Captura
##     `H_r7_f0935.png`: niciuna vizibila. Cauza, calculata pe .tscn: coama la
##     -3,02 peste un teren de -3,70 inseamna ca din piesa de 2,487 m ies
##     **0,68 m, adica 27 %**. O dunga de piatra pe 12 m de verde nu e o terasa.
##     Nu erau ratate — erau prea putin expuse ca sa existe.
##
## 7b: terasele mutate pe MUCHIE, in fereastra 0-4,5 m, fiindca un prim calcul
##     al ocluziei (unghiul catre fiecare punct, de pe ax) parea sa spuna ca
##     umarul de la 4 m ascunde tot ce e dincolo. Captura `H_r7b_f0935.png`:
##     tot nimic, si 35 de fete din 61 refuzate ca ingropate.
##     Calculul era gresit, si merita scris de ce ca sa nu-l refac: comparasem
##     unghiul catre un punct lateral cu unghiul catre umar masurat **lateral**,
##     nu **pe aceeasi raza azimutala**. Refacut corect (raza care pleaca din
##     camera catre punct intalneste linia umarului la distanta 4/sin(azimut)),
##     banda 9-16 m e **vizibila la orice distanta inainte**: la 20 m in fata,
##     punctul de la lat 12 e la 23,2 grade sub orizontala iar umarul pe aceeasi
##     raza la 28,9 — deci raza trece pe deasupra. Umarul nu ascunde nimic.
##     (Memoria umarul-ingust-ascunde-caderea cere sa verifici UNGHIUL; cere si
##     sa-l verifici pe directia corecta.)
##
## DECI 7c: terasele se intorc pe taluz, unde 7a le pusese, dar cu cifra care
## le face sa se vada. Expunerea unei fete = cat coboara terenul intre lateralul
## ei si piciorul ei, adica `teren(L) - teren(L + run)`. Masurat pe profil:
##
##   run = 1,5 m -> expunere 1,80-1,90 m
##   run = 2,0 m -> expunere **2,40-2,50 m**  (= toata piesa de 2,487)
##   run = 2,5 m -> expunere 3,00-3,10 m (mai mult decat piesa: ar ramane gol)
##
## `run = 2,0` e singurul care expune fata INTREAGA fara sa lase gol sub ea.
## Coama fiecarui etaj se ia din terenul de la lateralul lui (raycast pe
## TerrainBody, memoria terrain-mesh-y-extrapoleaza), talpa la coama - 2,487,
## si piciorul cade exact pe terenul de la L + 2,0. Rezultat: o scara de piatra
## de 5 etaje care coboara din umarul drumului pana pe podeaua rapei — etaje cu
## fasie de iarba intre ele, exact cum arata bara.
const TERR_LEVELS := 4
const TERR_RISE := 2.487
## Retragerea per etaj. 1,6 m (runda 8) lipea etajele intre ele si impreuna cu
## zidul de sprijin citeau ca o singura masa bej — in bara treptele sunt
## SEPARATE, cu o fasie de iarba pe fiecare. La 2,6 m retragere si 1,2 m cadere
## treapta are 1,4 m de banda orizontala descoperita intre coama unui etaj si
## fata urmatorului: destul cat sa se vada iarba dintre ele.
const TERR_RUN := 2.6            # retragerea per etaj
## Caderea coamei per etaj si cat de jos fata de sosea mai e vizibil un etaj.
const TERR_DROP := 1.2
const TERR_VIS_DEPTH := 3.9
const TERR_LAT0 := 7.8           # primul etaj, imediat dupa zidul de sprijin
const TERR_STEP := 4.6
const TERR_F_IN := 0.9285
const TERR_F_OUT := 0.9620

func _terraces() -> void:
	var n := _track.baked.size()
	var placed := 0
	var refuzate := 0
	var expuneri: Array[float] = []
	_lvl_ok.resize(TERR_LEVELS)
	_lvl_no.resize(TERR_LEVELS)
	_lvl_ok.fill(0)
	_lvl_no.fill(0)
	for lvl in TERR_LEVELS:
		var lat: float = TERR_LAT0 + float(lvl) * TERR_RUN
		var f := TERR_F_IN
		while f < TERR_F_OUT:
			var i := int(f * float(n)) % n
			var sgn := _gap_side(i)
			var p := _track.baked[i]
			var side := _track._side_at(i) * sgn
			var q := p + side * lat
			var g := _sol_real(q.x, q.z)
			var qf := p + side * (lat + TERR_RUN)
			var foot: float = _sol_real(qf.x, qf.z)
			var expunere: float = g - foot
			# Garzile: (a) sub etaj trebuie sa fie cadere reala, altfel e o
			# bordura pe camp; (b) coama sub cota soselei, altfel e damb pe umar.
			if expunere < 0.35:
				refuzate += 1
				_lvl_no[lvl] += 1
				if _lvl_no[lvl] == 1:
					print("; etaj %d refuz la frac %.4f: lat %.1f, g %.2f, foot %.2f, expunere %.2f, sosea %.2f" % [
						lvl, f, lat, g, foot, expunere, p.y])
				f += _step(TERR_STEP)
				continue
			var tang := (_track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n])
			tang.y = 0.0
			if tang.length() < 0.01:
				f += _step(TERR_STEP)
				continue
			tang = tang.normalized()
			var yaw := atan2(-tang.z, tang.x)
			# COAMA — aici a fost bug-ul rundei 7c, si merita numit.
			#
			# Calculasem corect `expunere` = cat coboara terenul intre lateralul
			# fetei si piciorul ei (2,07 m in medie), dar apoi asezasem coama la
			# `g + 0,30`, adica la 30 cm peste terenul de sub ea. Din piesa de
			# 2,487 m ieseau deci 30 cm, restul stand ingropat in taluz — a
			# treia oara la rand cand asez terase care exista in .tscn si nu se
			# vad in captura (`H_r7c_f0950.png`: panta e verde curat).
			# Cifra buna o aveam masurata si nu o foloseam.
			#
			# Corect: coama se ridica fata de terenul de la PICIORUL fetei, nu de
			# la capul ei. Talpa cade pe `foot`, coama la `foot + RISE`, deci
			# fata sta INTREAGA peste taluz si se vede de sus pana jos. Cand
			# expunerea e mai mica decat piesa, diferenta se ingroapa in spate —
			# unde nu o vede nimeni — nu in fata.
			# COAMA — cifra care a decis toata runda, gasita prin experiment.
			#
			# Trei versiuni au asezat terase corecte pe hartie si invizibile in
			# captura (7a coama la teren+0,55; 7c la teren+0,30; 7d la
			# picior+RISE). De fiecare data cele 76 de fete erau in .tscn, peste
			# sol, cu expunere calculata de 2,07 m — si panta ramanea verde.
			#
			# Experimentul care a taiat nodul (`--terr-test`, captura
			# `H_test2_f0945.png`): aceleasi piese, acelasi lateral, acelasi
			# numar, doar cu coama fortata la cota SOSELEI minus un pas mic. Au
			# aparut toate patru etajele, instantaneu. Deci nu era nici cull,
			# nici origine, nici ingropare: era ocluzie.
			#
			# Plimbarea razei pe teren o spune exact: din camera de joc (2,6 m
			# peste sosea), umarul propriu al drumului ridica linia de vedere,
			# si tot ce are coama sub ~1 m fata de cota soselei cade in spatele
			# lui. Caderea de 12,3 m EXISTA in teren, dar soferul nu poate privi
			# in ea — memoria umarul-ingust-ascunde-caderea, in forma ei tare:
			# nu conteaza cat de adanca e prapastia, ci sub ce unghi o vezi.
			#
			# Deci scara nu coboara in rapa, ci pe fereastra care se vede: patru
			# etaje intre cota soselei si -3,6 m, cu treapta de 1,2 m. Fiecare
			# etaj are coama peste umar, deci fata lui se vede intreaga, si
			# impreuna citesc drept terase andene care coboara catre gol — ceea
			# ce a cerut criticul — in loc sa fie zidarie ascunsa in iarba.
			# Sub ultimul etaj terenul isi continua caderea reala de 12,3 m:
			# terasele nu inlocuiesc prapastia, ii dau muchia de sus vizibila.
			var top: float = p.y - 0.25 - float(lvl) * TERR_DROP
			# Garda de ocluzie: daca un etaj ar cadea prea jos fata de sosea, nu
			# se vede si nu se aseaza (mai bine trei etaje vizibile decat cinci
			# din care doua sunt geometrie moarta).
			if p.y - top > TERR_VIS_DEPTH:
				refuzate += 1
				_lvl_no[lvl] += 1
				f += _step(TERR_STEP)
				continue
			expuneri.append(expunere)
			_raw("inca_wall_b", "terasa", Vector3(q.x, top - TERR_RISE, q.z),
				yaw, 1.0, "none")
			placed += 1
			_lvl_ok[lvl] += 1
			f += _step(TERR_STEP * WALL_OVERLAP)
	for lvl in TERR_LEVELS:
		print("; etaj %d la lat %.1f m: %d asezate, %d refuzate" % [
			lvl, TERR_LAT0 + float(lvl) * TERR_RUN, _lvl_ok[lvl], _lvl_no[lvl]])
	var med := 0.0
	for e in expuneri:
		med += e
	if expuneri.size() > 0:
		med /= float(expuneri.size())
	print("; terase andene: %d fete asezate, %d refuzate, expunere medie %.2f m (piesa 2,49)" % [
		placed, refuzate, med])
	# Grohotisul pe podeaua rapei, sub ultimul etaj: de acolo in jos e piatra,
	# nu pajiste. `moss_boulder` are muschi doar pe fata de sus, deci vazut de
	# sus citeste verde — de aia se pun INCLINATI (pitch), ca sa arate flancul
	# de piatra catre camera.
	var fb := TERR_F_IN
	while fb < TERR_F_OUT:
		var i := int(fb * float(n)) % n
		var sgn := _gap_side(i)
		var half := _track.width_at_index(i)
		for j in 3:
			var lat: float = _rng.randf_range(18.0, 24.0)
			var mdl := "moss_boulder_c" if j == 0 else "moss_boulder_b"
			var h := _rng.randf_range(2.8, 4.0) if j == 0 				else _rng.randf_range(1.6, 2.4)
			_place(mdl, "grohotis", fb + _step(_rng.randf_range(-3.5, 3.5)),
				sgn, maxf(1.0, lat - half), _rng.randf_range(0.0, TAU),
				_scale_for(mdl, h), "none", -0.4,
				_rng.randf_range(-0.5, -0.2))
		fb += _step(10.0)


func _gap_lip() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	# Parapetul marcheaza buza CORNISEI, deci se termina unde se termina si ea
	# (la poarta), din acelasi motiv ca zidul.
	while f < F_WALL_OUT:
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
## singuratic in pustiu.
##
## RUNDA 1 A GRESIT AICI DE DOUA ORI, si captura le-a aratat pe amandoua:
##
## 1. `H_r1_f097.png` — o piesa asezata dupa poarta umple JUMATATEA DE JOS A
##    CADRULUI, ca o lespede pusa de-a curmezisul in fata masinii. Cauza:
##    sirul de dupa poarta pornea la 9 m si drumul coteste acolo (survey: side
##    se roteste de la (-1, 0) la (0, +1) dupa 0,976), deci o piesa pusa
##    „lateral" fata de fractia ei ajunge IN FATA la fractia urmatoare.
##    Memoria masoara-inainte-nu-langa, exact: camera priveste inainte.
##
## 2. `H_r1_f0955.png` — piesele de pe dreapta stau in aer si la unghiuri
##    razlete, ca niste scanduri aruncate pe iarba. Cauza: `_raw` direct, cu
##    cota din `_sol_real` plus un `dy` fix, ocoleste toate garzile din
##    `_place` (scufundare, degajare, carosabilul altui tronson).
##
## Deci sirurile se muta TOATE inaintea portii, pe portiunea dreapta unde
## `side` e constant, si trec prin `_place` ca orice alta piesa.
func _citadel_walls() -> void:
	var n := _track.baked.size()
	# Doar pe dreapta dinaintea portii (frac < GATE_FRAC), unde survey-ul da
	# side = (-1, 0) constant. Dupa poarta traseul coteste spre piata si orice
	# piesa „laterala" ajunge in fata camerei.
	var runs: Array = [
		# frac_start, cate piese, gap de la muchie
		[GATE_FRAC - _step(52.0), 5, 1.8],
		[GATE_FRAC - _step(34.0), 4, 6.0],
		[GATE_FRAC - _step(20.0), 3, 11.0],
	]
	for r: Array in runs:
		var f0: float = r[0]
		var cnt: int = r[1]
		var gap: float = r[2]
		for j in cnt:
			var ff: float = f0 + _step(6.2 * float(j))
			var i := int(ff * float(n)) % n
			var up := -_gap_side(i)
			var tang := (_track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n])
			tang.y = 0.0
			if tang.length() < 0.01:
				continue
			tang = tang.normalized()
			# Piesa e lunga pe X-ul ei local si trebuie sa stea PARALEL cu
			# drumul, deci X local pe tangenta. `_place` primeste yaw-ul gata
			# calculat si pune cota, garzile si refuzurile.
			_place("inca_wall_b", "zidCetate", ff, up, gap,
				atan2(-tang.z, tang.x), 1.0, "hull", -0.10)


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


# --------------------------------------------------- RUNDA 10: peretele si buza
##
## VERDICTUL ORB AL RUNDEI 9: "in a noastra drumul trece peste o pajiste
## continua, cu ambele margini la aceeasi cota cu terenul din spate. Nu exista
## buza taiata / cadere pe partea golului (stanga e iarba care urca bland pana
## in orizont), iar zidul de pe dreapta e o bordura joasa peste care camera
## trece. [...] poarta pare gratuita - sta singura in mijlocul campului,
## ocolibila pe iarba, in loc sa fie taiata prin masa de piatra."
##
## L-am verificat cu `--lat`, care acum masoara AMANDOUA partile (pas 1 m, cote
## fata de sosea). Criticul are dreptate pe amandoua, si cifrele spun de ce:
##
##  PARTEA GOLULUI (muchia la half 6,00):
##    lateral   4     5     6     7     8     9    10    11    12 ...  16
##    frac .94 -1.7  -1.9  -2.1  -2.3  -2.5  -3.7  -4.9  -6.1  -7.4 ... -12.3
##  Primii ~4 m de dupa muchie coboara 0,8 m in total: un UMAR DE IARBA. Rapa de
##  12,3 m e reala, dar incepe la 9 m lateral, adica dincolo de umar - iar din
##  camera de joc (2,6 m) umarul propriu ridica linia de vedere si ascunde exact
##  muchia (memoria umarul-ingust-ascunde-caderea). De aia se citeste "pajiste".
##
##  PARTEA PERETELUI:
##    lateral   4     8    12    15    20    25    30
##    frac .94 -0.7  -0.3  +0.9  +1.8  +8.7  +22.5 +34.8
##    frac .96 -0.7  -0.3  -0.3  -0.3  -0.3  -0.3  -0.3
##  La 0,94 "peretele" e o coasta care abia se ridica 1,8 m in primii 15 m, si
##  urca serios abia dupa 20 m. La poarta (0,955-0,964) e PLAT la -0,30 m pe tot
##  intervalul de 30 m. Deci la poarta nu exista niciun perete: poarta chiar sta
##  in camp si chiar e ocolibila pe iarba. Nu e o chestiune de a inalta zidaria
##  cu inca un curs - nu exista masa de piatra in care sa fie taiata.
##
## CE FAC, exact cele doua lucruri cerute, nimic altceva:
##
## (A) BUZA TAIATA pe partea golului, in primii 3-5 m. Nu pot sapa terenul (nu e
##     treaba POI-ului si traseul a trecut ProbeLayout), dar pot pune PIATRA
##     acolo unde acum e iarba: un sir continuu de bolovani INCLINATI cu coama
##     chiar sub cota soselei, lipit de muchie, care inlocuieste umarul verde cu
##     o muchie de stanca - si sub el un al doilea sir, mai jos, in fereastra
##     vizibila. Efectul cerut: primii 3-5 m sa fie flanc de stanca, nu iarba.
##
## (B) MASA DE PIATRA pe partea opusa, prin care trece poarta. `huayna_picchu`
##     (33,00 m inaltime, 79,47 x 73,47 m amprenta, 503 triunghiuri, coliziune
##     `none` prin PROP_COLLISION) e exact piesa pentru asta si e deja
##     inregistrata in Track15.tscn ca `s_huayna_picchu` - NEFOLOSITA de niciun
##     POI. Sloturile ei (2,3,12,21,28,29) sunt aceleasi ca ale bolovanilor, deci
##     ZERO materiale noi: nu cer buget, refolosesc.
##
##     Se aseaza cu flancul lipit de umarul drumului si INGROPATA adanc, ca sa
##     iasa din ea doar felia dinspre drum: un perete care urca dincolo de cadru.
##     Sirul merge de la intrarea pe cornisa pana DUPA poarta, ca poarta sa fie
##     taiata prin masa, nu pusa langa ea.
##
## Ce NU fac: nu ating traseul, nu largesc poarta, nu mut terasele (criticul nu
## le-a cerut si ele raman muchia de sus a caderii), nu adaug material nou.


## Gap-ul (fata de muchie) la care ajunge FLANCUL masei de piatra la cota
## soselei. Mic dinadins: criticul cere ca peretele sa ocupe cadrul, iar
## coliziunea piesei e `none`, deci nu poate impinge masina - dar garda de banda
## de mai jos ramane, ca silueta sa nu intre peste carosabil.
## RUNDA 10b: 1,6 -> 0,2. Pe `H_r10_f0940.png` intre muchia drumului si piciorul
## masei ramanea o pana de IARBA de cativa metri, deci peretele plutea peste
## pajiste in loc ca drumul sa fie taiat in el - exact jumatatea de verdict
## ramasa nerezolvata ("in loc sa fie taiata prin masa de piatra"). Coliziunea
## piesei e `none`, deci apropierea nu poate atinge masina; garda de banda de mai
## jos ramane, pe silueta.
## 1,6 era prea departe (pana de iarba intre drum si perete), 0,2 prea aproape:
## garda de banda l-a refuzat pe toate patru, si pe buna dreptate - silueta ar fi
## atarnat peste umarul pe care se aterizeaza dupa barne. Se ia exact
## `EDGE_KEEP` (0,8 m), adica cel mai aproape pe care garda il accepta: piciorul
## peretelui sta pe umar, fara pana de pajiste, dar nu peste banda.
const CLIFF_GAP := 0.85
## Cat din piesa se ingroapa. Piesa e un CON de 33 m cu baza de ~81 m; intreaga,
## baza ei ar acoperi jumatate de pista. Ingropata cu `CLIFF_SINK`, ce ramane
## afara e o felie de flanc - perete, nu munte.
const CLIFF_H := 33.0
## Cat urca varful masei PESTE COTA SOSELEI. Criticul cere ca peretele sa ocupe
## ~1/3 din cadru pe verticala si sa urce dincolo de el. Camera de joc sta la
## ~2,6 m peste sosea si priveste aproape orizontal, cu FOV vertical ~70 deg,
## deci jumatatea de sus a cadrului acopera ~35 deg. Un perete al carui picior e
## la ~8 m lateral si al carui varf e la 14 m peste ochi subintinde
## atan(14/8) = 60 deg, adica trece DINCOLO de marginea de sus: exact ce s-a
## cerut. 14 m e si cifra care tine piesa in cascada de umbre (shadow_distance),
## ca sa TAIE lumina - a doua jumatate a verdictului.
const CLIFF_TOP_OVER_ROAD := 14.0

## Pragul care decide DACA se pune o masa de piatra intr-un punct: cat trebuie
## sa urce solul pe partea peretelui, la `CLIFF_RISE_LAT` metri lateral, ca
## piesa sa fie "felia de jos a unei falezei" si nu un con pe pajiste.
##
## Cifrele masurate (vezi nota din `_cliff_mass`): pe faleza reala terenul e la
## +19,9 .. +27,6 m la 25 m lateral; pe platoul pietei e la -0,3 m peste tot.
## Distanta dintre cele doua regimuri e de doua ordine de marime, deci pragul nu
## e delicat: 6 m taie curat, iar ultimul punct acceptat (0,9500, +5,2 la 25 m /
## +14,4 la 40 m) cade chiar sub el. Se masoara la 25 m fiindca la 8 m terenul e
## la -0,2 m si pe faleza (umarul drumului e plat pe ambele regimuri) — memoria
## masoara-inainte-nu-langa, in varianta laterala: intrebi terenul acolo unde
## cele doua regimuri chiar difera.
const CLIFF_RISE_LAT := 25.0
const CLIFF_MIN_RISE := 6.0

## Pasul intre mase, in metri de traseu. Piesa are 79,5 m amprenta dar iese din
## ea doar felia de sus (restul e ingropat cu CLIFF_SINK), iar felia vizibila la
## cota soselei are ~2 * r * (1 - t) = ~49 m. Pasul de 34 m le lasa sa se
## incalece cu ~15 m, deci silueta e continua si nu se vede cusatura dintre ele.
## Cele patru pozitii vechi (offset-uri fata de poarta) dadeau un pas neuniform
## de 34/28/26 m plus o gaura, si gaura cadea fix peste poarta.
const CLIFF_SPACING := 34.0

## Cat trebuie sa urce solul sub CENTRUL masei, peste cota soselei, ca piesa sa
## fie de prisos. Peste pragul asta terenul e el insusi faleza si conul n-ar
## face decat sa-si scoata calota prin creasta (vezi nota din `_cliff_mass`).
## Pragul e la jumatatea inaltimii vizibile cerute (CLIFF_TOP_OVER_ROAD = 14):
## sub 7 m terenul nu poate tine singur silueta, peste 7 m o tine.
## Masurat: pe platou solul e la -0,3 m (deci 0 peste sosea), pe faleza la
## +6,9 si +24,5 — cele doua regimuri sunt separate de un ordin de marime, deci
## pragul nu e delicat.
const CLIFF_TERRAIN_ENOUGH := 7.0


## Cat urca solul peste sosea, pe partea peretelui, la `CLIFF_RISE_LAT` lateral.
## Raycast filtrat pe `TerrainBody` (via `_sol_real`), nu campul neted: memoria
## terrain-mesh-y-extrapoleaza. Returneaza -1000 daca nu e sol (gol lateral).
func _wall_rise(ff: float) -> float:
	var n := _track.baked.size()
	var i := int(ff * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var side: Vector3 = _track._side_at(i) * (-_gap_side(i))
	var q: Vector3 = p + side * CLIFF_RISE_LAT
	return _sol_real(q.x, q.z) - p.y


## (A) BUZA TAIATA pe marginea dinspre gol.
##
## RUNDA 13, dupa doua incercari gresite cu `moss_boulder_c` - ambele pastrate
## in istoric fiindca spun de ce piesa nu era buna:
##   r11: bolovani drepti, coama sub sosea -> 42/47 vizibili geometric, dar la
##        -12,0 grade mediana, adica sub botul masinii. Existau, nu se vedeau.
##   r12/r13: coama ridicata peste sosea si inclinata 35-50 grade ca sa arate
##        flancul - `H_r13_f0950.png` arata un sir de DISCURI cu capac verde si
##        burta maro. `moss_boulder_*` are muschi pe fata de sus si o baza plata:
##        inclinat, isi arata talpa. E o piatra de camp, nu o muchie taiata.
##
## Piesa buna o aveam deja in cadru: `inca_wall_b`, din care sunt facute cele 76
## de fete de terasa care se citesc curat pe taluz in aceeasi captura. O cornisa
## incasa CHIAR e zidita pe muchie - buza nu e un sir de bolovani, e cursul de
## sus al sprijinului, iesit putin peste carosabil. Deci buza devine un curs de
## zidarie continuu pe muchia dinspre gol, cu coama peste cota soselei, adica
## exact "buza + flanc de stanca in primii 3-5 m, nu iarba" din verdict - si in
## materia care e deja peste tot in zona (`inca_stone`), nu una noua.
##
## Zidul de sprijin (`_retaining`) sta pe ACEEASI muchie, dar sub cota soselei:
## el e fata care tine drumul. Buza e cursul de deasupra lui, singurul care rupe
## linia orizontului. Impreuna dau profilul "drumul se termina intr-o muchie de
## piatra, apoi cade".
const LIP_RISE := 0.62           # cat iese coama peste sosea
const LIP_STEP := 4.5            # pasul, sub lungimea piesei (6,0 m) => se incaleca


func _gap_rock_lip() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var puse := 0
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
			f += _step(LIP_STEP)
			continue
		tang = tang.normalized()
		# La poarta si la barne se lasa loc: poarta are usciori pe umeri, iar
		# traveea podului trebuie sa ramana libera.
		var la_poarta: bool = absf(f - GATE_FRAC) < 0.006
		var la_barne: bool = absf(f - BEAM_FRAC) < BEAM_HALF_SPAN + 0.0015
		if not la_poarta and not la_barne:
			# Fata interioara pe muchia asfaltului, ca la zidul de sprijin:
			# centrul piesei la half + jumatatea grosimii.
			var q := p + side * (half + WALL_HALF_THICK)
			_raw("inca_wall_b", "buzaTaiata",
				Vector3(q.x, p.y + LIP_RISE - WALL_H, q.z),
				atan2(-tang.z, tang.x), 1.0, "none")
			puse += 1
			# Bolovani RARI la piciorul buzei, ca accent de stanca sub zidarie -
			# nu ca buza in sine. Drepti (fara pitch): asa arata capacul cu
			# muschi, care aici e corect, e vegetatie agatata de perete.
			if k % 3 == 0:
				var h2 := _rng.randf_range(1.4, 2.2)
				_place("moss_boulder_b", "pietreBuza", f, sgn,
					_rng.randf_range(2.6, 4.2), _rng.randf_range(0.0, TAU),
					_scale_for("moss_boulder_b", h2), "none", -0.35)
		f += _step(LIP_STEP)
		k += 1
	print("; buza taiata pe partea golului: %d asize de inca_wall_b, coama la +%.2f m peste sosea" % [
		puse, LIP_RISE])


## (B) MASA DE PIATRA pe partea peretelui, prin care e taiata poarta.
func _cliff_mass() -> void:
	var n := _track.baked.size()
	# De la intrarea pe cornisa pana DUPA poarta. Capatul de dupa poarta e ce
	# face poarta sa fie "taiata prin masa": daca masa s-ar opri la poarta,
	# poarta ar fi tot capatul unui zid, nu o trecere.
	#
	# RUNDA 14 — poarta a fost reperul GRESIT, si captura a spus-o.
	#
	# `H_r0_f097.png` (captura de pornire a rundei) arata o LESPEDE de piatra
	# care umple jumatatea de jos a cadrului la frac 0,97. Vinovata e a patra
	# masa, asezata la `GATE_FRAC + _step(14.0)` = frac 0,9703, la 31,4 m de ax,
	# cu varful la 14 m peste sosea.
	#
	# Cauza nu e distanta si nu e scara: e ca ACOLO NU MAI EXISTA PERETE.
	# `tools/SvMpHPerete.tscn` masoara solul pe partea peretelui (-X), prin
	# raycast filtrat pe `TerrainBody`, cota relativa la sosea:
	#
	#     frac    +8 m   +15 m   +25 m   +40 m
	#     0,9280  -0,2    +1,7   +27,6   +66,7   <- faleza reala
	#     0,9400  -0,3    +1,1   +19,9   +50,2   <- faleza reala
	#     0,9500  -0,3     nan    +5,2   +14,4   <- se stinge
	#     0,9577   nan    -0,3    -0,2    +0,2   <- PLAT
	#     0,9640   nan    -0,3    -0,3    -0,3   <- PLAT (poarta)
	#     0,9703  -0,3    -0,3    -0,3    -0,3   <- PLAT (lespedea)
	#
	# Dupa 0,955 drumul iese din rapa si intra in platoul pietei. Un con de
	# 33 m pus pe pajiste plata nu e "masa prin care e taiat drumul", e un
	# bolovan cat un bloc lasat pe camp — exact tiparul "un perete de piese
	# peste teren plat citeste a gard, nu a prapastie".
	#
	# Aceeasi forma ca decizia rundei 4 pentru zidul de sprijin (`F_WALL_OUT`):
	# intrebarea nu e cu cat sa mut piesa, ci DE UNDE VINE FORMA
	# (memoria capcana-parametrului-care-doar-aduna). Forma vine din faleza.
	# Deci reperul nu mai e poarta, ci terenul: se asaza o masa doar acolo unde
	# solul chiar urca. Pragul se masoara, nu se presupune.
	# Prima incercare a rundei a fost sa se taie masele care nu stau pe faleza
	# (pragul `CLIFF_MIN_RISE` pe `_wall_rise`). Masuratoarea era corecta —
	# terenul de pe partea peretelui chiar se stinge dupa 0,952 — dar
	# CONCLUZIA a fost gresita, si captura a spus-o: `r1_f0p95.png` are partea
	# dreapta mai PROASTA decat `r0_f0p95.png`. Fara con, pe dreapta ramane un
	# zid scund de zidarie pe pajiste, cu pana de iarba vizibila in spate;
	# conul, chiar stand pe plat, inchidea marginea cadrului cu masa continua
	# de piatra — adica exact ce cere brief-ul: "flancul lui Huayna Picchu in
	# dreapta, la 40 m, umpland marginea cadrului".
	#
	# Deci masele NU sunt "faleza prin care e taiat drumul" (aia e teren si nu
	# e a POI-ului); sunt SILUETA DE FUNDAL care inchide cadrul pe partea
	# opusa golului. Pentru rolul ala terenul de sub ele nu conteaza — piesa e
	# `coliziune = none`, nu o atinge nimeni — conteaza sa fie continue, ca sa
	# nu ramana pana de pajiste intre doua.
	# Memoria revenirea-e-o-mutare-valida: ma intorc la starea cea mai bine
	# judecata (cele 4 pozitii), si pastrez masuratoarea ca sa stiu CE sunt.
	#
	# Ce se schimba fata de r0: pasul devine uniform si continuu pe toata
	# cornisa, in loc de patru offset-uri ad-hoc fata de poarta. Cele patru
	# vechi lasau o gaura de 34 m intre a treia si a patra (0,9577 -> 0,9703),
	# exact peste poarta — de aia poarta citea ca un toc liber pe gazon.
	var runs: Array = []
	var ff_scan := F_IN + _step(6.0)
	while ff_scan < F_OUT - _step(20.0):
		runs.append(ff_scan)
		ff_scan += _step(CLIFF_SPACING)
	var pe_faleza := 0
	for ff_r: float in runs:
		if _wall_rise(ff_r) >= CLIFF_MIN_RISE:
			pe_faleza += 1
	print("; masa de piatra: %d pozitii la pas de %.0f m (din care %d pe faleza reala, restul silueta de fundal)" % [
		runs.size(), CLIFF_SPACING, pe_faleza])
	var puse := 0
	for ff: float in runs:
		var i := int(ff * float(n)) % n
		var up := -_gap_side(i)
		var p := _track.baked[i]
		var half := _track.width_at_index(i)
		var side := _track._side_at(i) * up
		var scl := 1.0
		var r: float = BASE_R["huayna_picchu"] * scl
		# Cota se ia de la SOL sub centrul piesei, nu de la sosea, ca sa nu
		# pluteasca pe portiunea unde terenul lateral urca.
		# Distanta centrului se ALEGE ca flancul la cota soselei sa cada la
		# `CLIFF_GAP` de muchie: la inaltimea `p.y` conul are raza
		# `r * (1 - (p.y - y) / CLIFF_H)`, deci d = half + CLIFF_GAP + raza_aia.
		# Se rezolva in doi pasi, fiindca `y` depinde de `d` prin sol.
		# Cota TALPII se leaga de SOSEA, nu de solul de sub centrul piesei.
		# Prima versiune lua `_sol_real` sub centru si scadea CLIFF_SINK; dar
		# centrul cade la 48 m lateral, unde terenul e deja la +34..+60 m, deci
		# varful iesea la 48-74 m peste drum: un munte, nu o cornisa. Aceeasi
		# capcana ca la poarta (nota din `_gate`): o cota luata dintr-un punct
		# nereprezentativ misca TOT obiectul.
		#
		# Se cere in schimb INALTIMEA PESTE DRUM, care e marimea din verdict
		# ("sa ocupe ~1/3 din cadru pe verticala"), si talpa iese din ea.
		var y: float = p.y + CLIFF_TOP_OVER_ROAD - CLIFF_H
		var d: float = half + CLIFF_GAP + r * 0.4
		var q := p + side * d
		for _it in 3:
			var t0: float = clampf((p.y - y) / CLIFF_H, 0.0, 1.0)
			d = half + CLIFF_GAP + r * (1.0 - t0)
			q = p + side * d
		# RUNDA 15: talpa se leaga de SOLUL DE SUB PIESA cand solul e mai SUS
		# decat soseaua, nu doar de sosea.
		#
		# Legarea exclusiv de sosea (`p.y - 19`) e corecta doar cat timp
		# terenul lateral e la cota drumului. Masurat cu tools/SvMpHMase.tscn
		# (raycast filtrat pe TerrainBody, sub centrul fiecarei piese):
		#
		#   piesa           talpa    sol_real   delta
		#   masaPiatra267  -19,00     +24,52   -43,52
		#   masaPiatra268  -19,00      +6,94   -25,94
		#   masaPiatra269  -19,00      -0,30   -18,70
		#   masaPiatra270  -19,00      -0,30   -18,70
		#
		# Adica toate patru au talpa cu 18,7-43,5 m SUB sol. Piesa e ingropata
		# mult mai adanc decat cei 19 m proiectati, si din ea nu mai iese felia
		# de flanc fatetat, ci doar CALOTA de varf — partea cea mai lata, cea
		# mai uniform luminata si cea mai plata a conului. De aici venea
		# verdictul criticului ("duna de nisip neteda, o singura nuanta"):
		# fatetele nu lipseau, erau sub pamant.
		#
		# Reperul corect e maximul dintre cele doua: pe platou solul e la cota
		# drumului si nu schimba nimic (269/270), pe faleza ridica piesa cu
		# solul ei (267/268) si felia vizibila ramane aceeasi peste tot.
		# Nu se scade nimic in plus: `CLIFF_TOP_OVER_ROAD` e definit ca
		# inaltime PESTE OCHI, si ochiul e pe sosea.
		# RUNDA 15: unde terenul face DEJA masa, nu se mai pune con.
		#
		# Masurat cu tools/SvMpHMase.tscn (raycast filtrat pe TerrainBody, sub
		# centrul fiecarei piese), pe pozitiile rundei 14:
		#
		#   piesa           talpa    sol_real   delta
		#   masaPiatra267  -19,00     +24,52   -43,52
		#   masaPiatra268  -19,00      +6,94   -25,94
		#   masaPiatra269  -19,00      -0,30   -18,70
		#   masaPiatra270  -19,00      -0,30   -18,70
		#
		# Toate patru aveau talpa cu 18,7-43,5 m SUB sol — mult mai adanc decat
		# cei 19 m proiectati. Din piesa nu mai iesea felia de flanc fatetat, ci
		# CALOTA de varf: partea cea mai lata, cea mai uniform luminata si cea
		# mai plata a conului. De aici venea verdictul criticului ("duna de
		# nisip neteda, dintr-o singura nuanta"): fatetele nu lipseau, erau sub
		# pamant.
		#
		# Prima reparatie incercata — legarea talpii de solul de sub piesa — se
		# alearga pe ea insasi: talpa urcata impinge centrul mai in lateral (raza
		# la cota soselei scade), acolo faleza e si mai sus, deci piesa iese si
		# mai ingropata. Masurat dupa acea incercare: 267 ajunsese la -58,7.
		# Memoria capcana-parametrului-care-doar-aduna: intrebarea nu e cu cat
		# sa ridic piesa, ci DE UNDE VINE FORMA.
		#
		# Forma, pe felia 0,93-0,94, vine din TEREN: survey-ul (nota 2 din antet)
		# da solul la +28,1 / +68,5 m la 25 / 40 m lateral pe 0,9300, si +19,9 /
		# +50,2 pe 0,9400. Faleza e reala si e uriasa. Un con ingropat acolo nu
		# adauga silueta, doar o calota palida peste o creasta care exista deja
		# — exact aceeasi lectie ca la zidul de sprijin in runda 4 (`F_WALL_OUT`):
		# unde nu mai e cornisa, un zid nu sprijina nimic.
		#
		# Deci masa se pune DOAR unde terenul NU face deja treaba: acolo unde
		# solul lateral ramane la cota drumului (platoul, 269/270). Pe faleza
		# reala se lasa terenul sa fie muntele.
		var sol_masa: float = _sol_real(q.x, q.z)
		if sol_masa > -900.0 and sol_masa - p.y > CLIFF_TERRAIN_ENOUGH:
			print("; masa de piatra frac %.4f: SARITA, terenul face deja masa (sol %+.1f fata de sosea, prag %.1f)" % [
				ff, sol_masa - p.y, CLIFF_TERRAIN_ENOUGH])
			continue
		# GARDA DE BANDA, de mana (memoria plafonul-buclei-orbe-pe-banda):
		# flancul conului la cota soselei nu are voie sa intre in carosabil.
		#
		# RUNDA 15: cazul "talpa PESTE sosea" se trateaza separat, nu prin
		# clamp. Pe faleza (sol +24,5) talpa urca la +5,5, deci la cota soselei
		# conul NU EXISTA — e in intregime deasupra. Formula veche calcula
		# t = (p.y - y) / CLIFF_H = -0,167, il tundea la 0, si obtinea
		# "raza la sosea = 40,8 m", adica raza BAZEI: garda citea o intrare in
		# banda de -16,6 m si refuza o piesa care de fapt nici nu ajunge acolo.
		# Doua din cele patru mase erau respinse asa.
		var raza_la_drum: float = 0.0
		if y <= p.y:
			var t: float = clampf((p.y - y) / CLIFF_H, 0.0, 1.0)
			raza_la_drum = r * (1.0 - t)
		var pana_la_ax: float = d - raza_la_drum
		if pana_la_ax < half + EDGE_KEEP:
			_warn += 1
			print("; ATENTIE masa de piatra la frac %.4f intra in banda: flanc la %.2f m de ax, muchia la %.2f" % [
				ff, pana_la_ax, half])
			continue
		_raw("huayna_picchu", "masaPiatra", Vector3(q.x, y, q.z),
			_rng.randf_range(0.0, TAU), scl, "none")
		puse += 1
		print("; masa de piatra frac %.4f: centru la %.1f m de ax, talpa %.1f (sosea %.1f, sol %.1f), ies %.1f m, flanc la %.2f m de ax (muchia %.2f)" % [
			ff, d, y, p.y, sol_masa, (y + CLIFF_H) - p.y, pana_la_ax, half])
	print("; masa de piatra: %d bucati huayna_picchu (coliziune none, sloturi de roca - zero materiale noi)" % puse)
