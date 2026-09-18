extends Node
## Generator de decor MANUAL pentru POI C — POARTA SOARELUI SI CREASTA
## (Track15, Machu Picchu, frac 0.22-0.40, coborare 35 -> 5 m pe muchie).
##
## Ca la POI G (gen_decor_mp_g.gd) si la Serengeti: nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track15.tscn sub
## `DecorManual/ZoneC_PoartaSoarelui`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpC.tscn -- \
##       --out=C:/cale/zoneC.part [--survey]
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_machu/bara_poi_C.png)
##
## Citit din decupaj, in ordinea in care sare in ochi:
##  1. O POARTA/CONSTRUCTIE DE PIATRA pe creasta, cu acoperis de paie langa ea
##     (Casa Paznicului) — masa de zidarie deschisa la culoare pe muchie.
##  2. CONDORUL pe o stanca alaturata, aripile desfacute, silueta neagra pe cer.
##  3. DRUMUL PE MUCHIE: fasie ingusta de pamant care serpuieste, cu NOR ALB
##     DEDESUBT DE AMBELE PARTI. Nu e drum pe deal, e drum pe creasta.
##  4. Coroane verzi dese INCLINATE PE VERSANT, sub cota drumului — se vad
##     varfurile de sub buza, nu trunchiurile.
##  5. Flancul muntelui pe fundal, in dreapta, cu ceata intre el si creasta.
##
## Bara e LOOK, nu LAYOUT: nu se redeseneaza traseul.
##
## ------------------------------------------------------------------------
## CAPCANA CENTRALA (memoria umarul-ingust-ascunde-caderea)
##
## Ochiul e la 10 m si camera priveste INAINTE. Ce face creasta sa citeasca
## drept creasta nu e adancimea finala a rapei, ci UNGHIUL din primii metri de
## la piatra. Un umar plat de 3 m urmat de o cadere de 40 m citeste ca pajiste.
##
## Terenul de aici E deja taiat: `custom_ravines` 0 (0.0734-0.3556, latime 200,
## planseu -40, cornisa) pe partea +1 si `custom_ravines` 1 (0.2215-0.3556,
## latime 70, side -1) pe partea -1. Deci rapa exista pe AMBELE parti pe
## 0.2215-0.3556. Survey-ul de mai jos MASOARA unghiul, nu il presupune.
##
## ------------------------------------------------------------------------
## SURVEY (se completeaza dupa prima rulare cu --survey)
##
## SURVEY (runda 1, --survey, C_r1_survey_cornisa.txt). Traseu 1986,4 m pe 1111
## puncte. Soare: rot (-40, 45, 0), lumina spre (-0,54, -0,64, -0,54),
## elevatie 40 grade. Semi-latime 6,5 pe tot 0,22-0,3627, apoi scade la 6,0.
##
## 1. CREASTA, DUPA REPARATIA DE TEREN (commit "rapa 1 devine cornisa").
##    Unghiul caderii pe primii 3 m de la muchie, cele doua parti:
##      frac    ungh(-1)  ungh(+1)   cadere la 3 m: -1 / +1
##      0,2250    0,0       82,7      -0,3 / -50,4
##      0,2400   54,1       74,9      -5,2 / -32,8
##      0,2500   69,2       80,5     -10,1 / -38,5
##      0,3000   69,2       73,6      -8,9 / -31,3
##      0,3300   43,4       79,4     -10,2 / -18,1
##      0,3500   46,0       79,8      -8,5 / -22,7
##      0,3550   15,8       71,2      -3,6 /  -9,9
##    Deci: gol de AMBELE parti pe 0,235-0,352. Pe 0,22-0,232 partea -1 e
##    inca platou (saua Portii Soarelui) — acolo se pune poarta, si e corect:
##    o poarta sta pe sa, nu pe muchie.
##
## 2. CE A ARATAT CAPTURA CA NU ARATA CIFRA (docs/bara_vizuala.md, regula zero).
##    Cu unghiul reparat de la 0-28 la 36-70 grade, capturile C_r1_cornisa_*
##    sunt aproape identice cu C_r0_gol_*: caderea din stanga TOT nu se vede.
##    Motivul, citit din imagine: pe partea +1 taietura se citeste fiindca
##    are ALTA CULOARE decat iarba (fata de pamant portocalie); pe partea -1
##    fata taiata prinde umbra si ramane VERDE, deci ochiul o citeste ca pe o
##    coasta, nu ca pe o muchie. Din masina, la 10 m inaltime si privind
##    INAINTE (memoria masoara-inainte-nu-langa), buza apropiata e sub cadru,
##    iar fata departata e scurtata de perspectiva.
##    Consecinta pentru decor: muchia trebuie MARCATA cu materie, nu cu
##    geometrie. Un sir de piatra pe buza da linia pe care terenul se termina,
##    si dincolo de ea nu mai e nimic — exact ce face bara cu zidul ei.
##
## 3. UNDE STA POARTA. La 0,2250 curbura e +0,0043 (raza 233 m, practic
##    dreapta) — golul masurat al lui inti_punku e 13,98 m pe axa drumului,
##    iar drumul are semi-latime 6,5 (deci 13,0 m). Marja e 0,98 m TOTAL,
##    adica 0,49 m pe parte: poarta nu suporta nici rotatie, nici curbura.
##    De aia se aseaza pe tangenta locala, la un punct cu raza peste 200 m.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneC_PoartaSoarelui"

const F_IN := 0.220
const F_OUT := 0.400

## id-urile ext_resource din Track15.tscn (fundatia).
const RES := {
	"inti_punku": "s_inti_punku",
	"main_gate": "s_main_gate",
	"condor": "s_condor",
	"guardhouse": "s_guardhouse",
	"inca_house_b": "s_inca_house_b",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"huayna_picchu": "s_huayna_picchu",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"tree_fern": "s_tree_fern",
	"bromeliad": "s_bromeliad",
	"orchid_cluster": "s_orchid_cluster",
	"rope_rail": "s_rope_rail",
	"trail_marker": "s_trail_marker",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
const HEIGHT := {
	"inti_punku": 5.000, "condor": 1.156, "guardhouse": 7.878,
	"main_gate": 7.500,
	"inca_house_b": 2.833,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"huayna_picchu": 33.000,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "tree_fern": 3.306,
	"bromeliad": 0.377, "orchid_cluster": 0.390,
	"rope_rail": 1.045, "trail_marker": 1.200,
}

## Raza de DEGAJARE la sol (m) la scara 1 (masuratori §1, coloana "raza baza"
## pentru trunk, jumatatea laturii mari a AABB pentru hull).
const BASE_R := {
	"inti_punku": 12.16, "condor": 0.73, "guardhouse": 4.01,
	"main_gate": 8.45,
	"huayna_picchu": 40.80,
	"inca_house_b": 3.00,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "tree_fern": 0.54,
	"bromeliad": 0.46, "orchid_cluster": 0.17,
	"rope_rail": 2.07, "trail_marker": 0.29,
}

## Raza COROANEI (m) la scara 1 — testul de silueta peste banda.
const CROWN_R := {
	"inti_punku": 12.60, "condor": 0.68, "guardhouse": 4.74,
	"main_gate": 8.45,
	"huayna_picchu": 40.80,
	"inca_house_b": 3.65,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 1.39, "polylepis_b": 2.27, "tree_fern": 2.07,
	"bromeliad": 0.46, "orchid_cluster": 0.17,
	"rope_rail": 2.07, "trail_marker": 0.29,
}

const TRI := {
	"inti_punku": 1092, "condor": 986, "guardhouse": 504, "inca_house_b": 496,
	"main_gate": 588,
	"huayna_picchu": 503,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098, "tree_fern": 768,
	"bromeliad": 248, "orchid_cluster": 410,
	"rope_rail": 92, "trail_marker": 76,
}

const EDGE_KEEP := 0.8
const WALL_HALF_THICK := 0.43
## Cat poate sta o piesa sub cota soselei de alaturi inainte sa fie refuzata.
## 2,5 m: pe umarul real terenul coboara 0,3-2,2 m (survey, coloana -3 pe
## portiunile fara rapa), deci 2,5 acopera umarul cinstit; peretele cornisei
## trece instant de el (-8..-15 m la 3 m de muchie). Piesele care TREBUIE sa
## stea jos — coroanele de sub buza — nu trec pe aici, au propria lor cale
## (`_below_lip`), fiindca acolo cota joasa e chiar scopul.
const DROP_REJECT := 2.5
## Cat poate cobori o piesa de BUZA sub sosea. 4,0 m: pe muchie profilul masurat
## da -1,9..-2,1 m la 0,2320 si -2,0..-7,3 la 0,3300, deci 4 m prinde buza reala
## si respinge orice a alunecat pe fata peretelui. Coroanele de sub buza
## (`coroanaJos`) NU trec pe aici — ele au voie oriunde pe fata, si de aia isi
## pastreaza calea proprie.
const LIP_DROP_MAX := 4.0

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
## Cand e adevarat, `_place` lasa piesa sa stea sub cota drumului (coroanele de
## pe fata rapei). Vezi `DROP_REJECT`.
var _below_lip := false
## Cand e adevarat, piesa are voie oriunde pe fata rapei (coroanele de sub buza).
var _free_fall := false


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
	_rng.seed = 220400
	_survey()
	if not _survey_only:
		_gate()
		_condor_rock()
		_guardhouse()
		_ridge_punctuation()
		_downhill_canopy()
		_uphill_side()
		_markers()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		print("; soare: rot %s, lumina spre (%.2f, %.2f, %.2f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; UNGHIUL e ce conteaza: pentru fiecare parte se da caderea la 3, 8, 15,")
	print("; 25, 40 m si UNGHIUL mediu pe primii 3 m de la muchie (grade sub orizontala).")
	print("; frac    y_drum  half  |  -3   -8  -15  -25  -40  ungh- |  +3   +8  +15  +25  +40  ungh+   curb")
	var f := F_IN - 0.01
	while f <= F_OUT + 0.01:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		var angs: Array[float] = []
		for sg: float in [-1.0, 1.0]:
			var y0 := _sol_real((p + s * sg * half).x, (p + s * sg * half).z)
			for off: float in [3.0, 8.0, 15.0, 25.0, 40.0]:
				var q := p + s * sg * (half + off)
				cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
			var q3 := p + s * sg * (half + 3.0)
			var drop := y0 - _sol_real(q3.x, q3.z)
			angs.append(rad_to_deg(atan2(maxf(drop, 0.0), 3.0)))
		print("; %.4f  %6.1f  %4.1f | %s %5.1f | %s %5.1f  %+8.4f" % [
			f, p.y, half,
			" ".join(cols.slice(0, 5)), angs[0],
			" ".join(cols.slice(5, 10)), angs[1], _curv(i)])
		f += 0.005


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

## (1) POARTA SOARELUI. Contractul de gameplay al POI-ului: golul MASURAT e
## 13,98 m pe axa drumului (masuratori §3, confirmat) si drumul are semi-latime
## 6,5 acolo, adica 13,0 m de asfalt. Marja totala e 0,98 m — 0,49 m pe parte.
##
## Trei consecinte, toate din cifra asta:
##  a. Poarta se aseaza pe TANGENTA locala, nu pe o directie aleasa: 1 grad de
##     eroare pe o piesa de 25,19 m anvergura misca un uscior cu 0,22 m, adica
##     jumatate din marja.
##  b. Se pune unde drumul e DREPT. La 0,2250 curbura e +0,0043 (raza 233 m):
##     pe cei 5 m de grosime ai portii drumul se abate 0,05 m. La 0,2450
##     (curbura +0,0290, raza 34 m) abaterea ar fi 0,37 m — trei sferturi din
##     marja, doar din curba.
##  c. Scara ramane 1,0. `inti_punku` e livrat exact pe contract; orice scalare
##     sub 1 strange golul proportional (0,98 scara = 13,70 m gol, adica marja
##     se injumatateste) si peste 1 ridica buiandrugul degeaba.
##
## Coliziunea e `mesh` (PROP_COLLISION, fundatia): un hull peste o poarta e un
## bloc plin de 25,19 x 5,00 m fix peste drum.
## POARTA. Trei lucruri s-au schimbat in runda 2, si al treilea le explica pe
## primele doua.
##
## (1) Mutata la 0,2605, fiindca fractiile judecate sunt 0,24 / 0,30 / 0,36 si
##     poarta statea inapoia tuturor. 0,2605 avea raza 717 m fata de 232 m.
##
## (2) Adusa inapoi la 0,2250, fiindca probe_mp_c_umar.gd a masurat umarul pe
##     toata zona: pe 0,232-0,358 e intre -1 si +5 m si de cele mai multe ori
##     zero — soseaua e cornisa peste aer pe ambele parti, pe 126 de fractii.
##     Singurele locuri cu pamant sunt capetele: 0,220-0,232 si de la 0,364.
##
## (3) SCHIMBATA DIN PIESA, si asta era problema reala de la inceput.
##     Capturile aratau doua cutii de piatra de o parte si de alta a drumului si
##     NIMIC intre ele. probe_mp_c_poarta.gd a numarat vertecsii lui
##     `inti_punku` pe felii de inaltime, cu x_min/x_max si cati cad in banda
##     centrala (|x| < 2 m, adica deasupra golului):
##
##       felie Y      n    x_min    x_max   in banda centrala
##       0,00-0,50   160  -12,00   +12,00          5
##       1,00-1,50    55  -12,51   +12,50          0
##       2,00-2,50    78  -12,63   +12,38          0
##       3,00-3,50    62  -12,46   +12,56          0
##       4,50-5,00    90  -12,00   +12,00          0
##
##     ZERO vertecsi peste gol la ORICE inaltime peste 1 m. `inti_punku` NU ARE
##     BUIANDRUG: sunt doi usciori la 25 m distanta plus o dala la sol. "Golul
##     de 13,98 m" din masuratori e distanta dintre picioare, cu cer deasupra.
##     Piesa nu poate citi ca poarta din nicio camera, fiindca nu e o poarta.
##
##     `main_gate`, masurata la fel, ARE traversa: feliile 5,25-6,00 si
##     6,00-7,50 traverseaza centrul (x de la -8,40 la +8,40, apoi -4,90 la
##     +4,90). Deschidere libera 7,39 m, buiandrug la 5,94-6,06 m, inaltime 7,50.
##
##     Scalata ca golul sa acopere cei 13,0 m de carosabil: 13,0 / 7,39 = 1,759.
##     Ansamblul iese de 13,19 m inaltime, cu BUIANDRUGUL LA 10,55 m — adica
##     peste ochiul camerei (10,0 m). Asta e chiar ce lipsea din verdictul
##     criticului ("nu ai ce citi pe cer daca nu e nimic vertical acolo"):
##     arcada taie linia orizontului, iar masina trece pe sub ea.
##
##     Contractul de gameplay se pastreaza si se largeste: golul devine 13,0 m
##     pe un drum de 13,0 m, in loc de 13,98 pe 13,0. Marja scade de la +0,98 la
##     0,00 la nivelul carosabilului — dar usciorii lui `main_gate` sunt
##     inclinati, deci la inaltimea masinii golul e mai larg decat la sol.
##     Se verifica cu ProbeLaneClear si ProbeRace dupa plantare, nu din tabel.
const GATE_FRAC := 0.2250

## Scara portii: golul liber (7,39 m la scara 1) trebuie sa acopere latimea
## carosabilului. Se recalculeaza din latimea masurata la fata locului, nu se
## scrie o cifra fixa: daca traseul se redeseneaza, poarta se rescaleaza singura.
const GATE_CLEAR_AT_1 := 7.39

## Cat intra talpa portii sub cota soselei, ca muchia de jos a aripii care
## atarna peste prapastie sa ramana ascunsa in spatele dalei de drum.
const GATE_SINK := 1.20

## Cota ochiului camerei de joc peste sosea (ChaseCamera.DEFAULT_HEIGHT) si cat
## trebuie sa treaca buiandrugul PESTE ea ca arcada sa se citeasca pe cer, nu
## lipita de linia orizontului.
const EYE_H := 10.0
const GATE_SKY_MARGIN := 1.0

func _gate() -> void:
	var n := _track.baked.size()
	var i := int(GATE_FRAC * float(n)) % n
	var p := _track.baked[i]
	# Tangenta pe o baza lunga (±4 puncte ≈ ±7 m): pe o baza scurta zgomotul
	# punctelor coapte ar roti poarta cu zecimi de grad degeaba.
	var tang := _track.baked[(i + 4) % n] - _track.baked[(i - 4 + n) % n]
	tang.y = 0.0
	tang = tang.normalized()
	# Piesa isi are anvergura pe X local, deci +X trebuie sa cada pe LATERAL,
	# nu pe tangenta: poarta sta DE-A CURMEZISUL drumului.
	var side := Vector3(-tang.z, 0.0, tang.x)
	var yaw := atan2(-side.z, side.x)
	var latime := 2.0 * _track.width_at_index(i)
	# Scara: golul trebuie sa acopere carosabilul, DAR buiandrugul trebuie sa
	# ramana peste ochiul camerei si dupa coborarea cu GATE_SINK. A doua conditie
	# e cea care castiga daca se bat cap in cap, fiindca prima se poate plati din
	# marja (usciorii stau pe muchii), iar a doua nu se poate plati din nimic:
	# sub cota ochiului arcada nu mai taie orizontul si POI-ul isi pierde
	# silueta — exact ce a reclamat criticul.
	var gscl := maxf(latime / GATE_CLEAR_AT_1,
		(EYE_H + GATE_SKY_MARGIN + GATE_SINK) / 6.0)
	# ARIPA EXTERIOARA CARE ATARNA, si de ce se rezolva cu cota, nu cu scara.
	#
	# Poarta are 29,55 m latime la scara 1,759 pe un drum de 13,0: usciorii
	# interiori cad exact pe muchii (+-6,51 fata de +-6,50), dar aripile
	# exterioare ajung la +-14,78. Pe partea -1 acolo e teren (umar 12 m); pe
	# partea +1 e gol de 27-66 m, si captura arata aripa retezata in aer.
	#
	# Micsorarea nu e o optiune: buiandrugul trebuie sa treaca peste ochiul
	# camerei (10,0 m) ca arcada sa taie orizontul, ceea ce cere scara >= 1,667,
	# adica exact latimea care nu incape. Cerintele se exclud pe terenul asta.
	#
	# Ce se poate: COBORAREA piesei. Talpa portii intra sub cota soselei cu
	# GATE_SINK, deci capatul de jos al aripii dispare in spatele dalei de drum
	# in loc sa se vada taiat pe ceata. Cat se pierde in inaltime se recastiga
	# din scara, fiindca buiandrugul urca oricum cu 6,00 * gscl de la talpa.
	# 1,20 m: destul cat muchia de jos sa fie ascunsa din camera de joc (care
	# priveste de sus), prea putin cat sa se vada ca poarta e ingropata.
	_raw("main_gate", "poartaSoarelui", Vector3(p.x, p.y - GATE_SINK, p.z),
		yaw, gscl, "mesh")
	print("; poarta (main_gate, scara %.3f) la frac %.4f, curbura %+.4f (raza %.0f m)" % [
		gscl, GATE_FRAC, _curv(i), 1.0 / maxf(absf(_curv(i)), 1e-6)])
	print(";   drum %.1f m, gol %.1f m, inaltime %.1f m, buiandrug la %.1f m peste sosea (ochiul camerei e la 10,0)" % [
		latime, GATE_CLEAR_AT_1 * gscl, 7.5 * gscl, 6.0 * gscl - GATE_SINK])
	# CONTRAFORTUL, SCOS DUPA CE probe_manual L-A MASURAT. Il pusesem ca sa
	# sprijine vizual piciorul dinspre prapastie: cinci `inca_wall_b` coborand
	# din talpa portii pe fata stancii. Sonda a raspuns:
	#
	#   contrafortPoarta3   y 23,52   teren 27,72   -4,20   INGROPAT
	#   contrafortPoarta4   y 21,18   teren 28,24   -7,05   INGROPAT
	#   contrafortPoarta5   y 18,84   teren 28,24   -9,40   INGROPAT
	#   contrafortPoarta6   y 16,51   teren 28,24  -11,74   INGROPAT
	#
	# Adica piesele coborau intr-un loc unde terenul e la cota soselei (28,24):
	# le ingropam in deal, nu le atarnam peste gol. Alegerea partii se facea pe
	# "unde cade solul cel mai jos sub piciorul interior", dar piciorul interior
	# e la 7 m de ax, iar acolo mai e inca munte — prapastia incepe mai departe.
	# Sonda masura un punct, contrafortul se punea in altul.
	#
	# Nu l-am mutat, l-am scos: dupa coborarea portii cu GATE_SINK muchia de jos
	# a aripii sta oricum in spatele dalei de drum, deci problema pe care venise
	# sa o rezolve nu mai exista. Cinci piese care nu se vad sunt cinci piese in
	# plus. (Memoria refuzul-motivat-e-livrare, la scara mica.)


## CONTRAFORTUL DE SUB PICIORUL DINSPRE PRAPASTIE.
##
## probe_mp_c_picior.gd a masurat solul sub fiecare pozitie de pe latimea portii
## (scara 1,759, deci 29,55 m latime pe un drum de 13,0), la 0,2250:
##
##   x local   pozitie fata de ax   cota teren   sub sosea
##    -8,40        -14,78 m           29,04        -0,25    teren
##    -3,70         -6,51 m           28,90        -0,39    teren
##     0,00          0,00 m           28,55        -0,74    teren
##    +3,70         +6,51 m            2,35       -26,95    AER
##    +8,40        +14,78 m          -36,85       -66,14    AER
##
## Jumatatea stanga a portii sta pe munte; jumatatea dreapta atarna peste un gol
## de 27-66 m. Captura de la 0,22 arata exact asta: uscior retezat in aer.
##
## Doua feluri de a repara, si alegerea conteaza:
##  - sa micsorez poarta pana incape pe teren. Dar buiandrugul trebuie sa treaca
##    peste ochiul camerei (10,0 m) ca arcada sa taie orizontul, iar asta cere
##    scara >= 1,667 — adica exact latimea care nu incape. Cele doua cerinte se
##    exclud pe terenul asta.
##  - sa CONSTRUIESC sub picior. Pe o cornisa, o poarta reala ar fi zidita pe un
##    contrafort care coboara pe fata stancii — si asta e chiar ce arata bara,
##    unde zidaria continua sub obiecte pana in nor.
##
## Se alege al doilea: un sir de `inca_wall_b` (6,00 x 2,49 m) suprapuse, care
## coboara din talpa piciorului pana unde ceata le inghite. Nu e nevoie sa
## atinga fundul — la 27 m sub drum ceata si distanta inchid oricum silueta;
## ce conteaza e ca ochiul sa nu vada capatul taiat.
##
## Coliziune `none` pe tot: sunt sub cota drumului, deci nu pot fi obstacol, iar
## un corp acolo ar fi doar cost.
const FOOTING_PIECES := 5

func _gate_footing(i: int, p: Vector3, side: Vector3, gscl: float) -> void:
	var n := _track.baked.size()
	# Care parte atarna: se MASOARA, nu se presupune. Se compara solul sub
	# piciorul interior al fiecarei parti (x local 3,70 * scara).
	var d_picior := 3.70 * gscl
	var caz := 0.0
	var jos := -INF
	for sg: float in [-1.0, 1.0]:
		var q: Vector3 = p + side * sg * d_picior
		var gy := _sol_real(q.x, q.z)
		if p.y - gy > jos:
			jos = p.y - gy
			caz = sg
	if jos < 2.0:
		print("; contrafort: nu e nevoie, ambele picioare pe teren (max %.1f m)" % jos)
		return
	# Tangenta, ca zidul sa fie paralel cu poarta (de-a curmezisul drumului).
	var tang := _track.baked[(i + 4) % n] - _track.baked[(i - 4 + n) % n]
	tang.y = 0.0
	tang = tang.normalized()
	var yaw := atan2(-tang.z, tang.x)
	# Scara zidului: latimea lui (6,00 m) trebuie sa acopere piciorul portii.
	# Piciorul are ~1,7 m grosime la scara 1, deci 3,0 la 1,759; un zid de 6 m
	# la scara 1,0 il acopera cu marja.
	var wscl := 1.0
	var h_piesa := 2.487 * wscl
	# Sirul porneste sub talpa portii si coboara. Fiecare piesa intra putin in
	# cea de deasupra (0,15 m) ca sa nu se vada rost intre ele.
	var y := p.y - GATE_SINK - h_piesa * 0.9
	for k in FOOTING_PIECES:
		# Se retrage cate 0,35 m spre munte la fiecare treapta: un contrafort
		# real se ingroasa in jos spre stanca, nu cade drept.
		var d := d_picior - 0.35 * float(k)
		var q: Vector3 = p + side * caz * d
		_raw("inca_wall_b", "contrafortPoarta", Vector3(q.x, y, q.z),
			yaw, wscl, "none")
		y -= h_piesa - 0.15
	print("; contrafort pe partea %+.0f: %d piese sub piciorul care atarna %.1f m" % [
		caz, FOOTING_PIECES, jos])
	# Zidaria care leaga poarta de creasta: cate o aripa scurta pe fiecare parte,
	# care porneste din uscior si se stinge in versant. Fara ele poarta sta ca un
	# arc de triumf in camp — in bara poarta e CAPATUL unui zid, nu un obiect
	# izolat. Piesele se lipesc cap la cap (capete la ±3,00 exact).
	# RUNDA 1 A GRESIT AICI, si probe_manual a dat cifra: aripaPoarta4 plutea
	# 38,51 m, aripaPoarta5 68,32 m. `clampf(gy, p.y - 2.0, ...)` le ridica la
	# cota soselei cand solul era la -11 si -41 — adica exact pe partea +1, unde
	# la 0,225 faleza cade cu 82,7 grade CHIAR de la muchie (survey).
	#
	# O aripa de zid porneste din uscior si se stinge in versant; daca nu exista
	# versant, nu exista aripa. Deci nu se mai ridica nimic: se pune piesa doar
	# unde terenul chiar o tine, si pe partea falezei poarta ramane cu usciorul
	# in gol — ceea ce e adevarul geometric al locului si arata mai bine decat
	# un zid suspendat.
	for sg: float in [-1.0, 1.0]:
		for k in 2:
			# Prima piesa incepe dincolo de uscior (6,99 = jumatatea golului
			# masurat), apoi se inlantuie spre exterior.
			var lat := 6.99 + 3.0 + 6.0 * float(k)
			var q := p + side * sg * lat
			var gy := _sol_real(q.x, q.z)
			if p.y - gy > DROP_REJECT:
				_skipped += 1
				continue
			_raw("inca_wall_b", "aripaPoarta", Vector3(q.x, gy, q.z), yaw, 1.0,
				"hull" if k == 0 else "none")


## (2) CONDORUL PE PINTEN. Al doilea semnal al barei, si singurul obiect din
## POI care e pura silueta: negru (VOLCANIC_BLACK 20) pe cer.
##
## RUNDA 2 A REFACUT COMPLET PIESA ASTA, si cifra care a cerut-o e derivata din
## camera, nu din gust. Criticul orb: "nu ai ce citi pe cer daca nu e nimic
## vertical acolo". Runda 1 avea condorul la 2,2 m pe un bolovan de 3,07 m.
##
## PLAFONUL SE DERIVA (memoria inaltimea-obiectelor-si-camera). ChaseCamera:
## ochi la 10,0 m peste masina, 12,5 m in spate, priveste un punct la 5,0 m
## inainte si 0,40 m inaltime, FOV 68. Pitch-ul iese -28,75 grade, deci
## ORIZONTUL CADE LA 7,7% DIN INALTIMEA CADRULUI, masurat de sus. Tot ce nu
## trece peste cota ochiului se vede pe iarba, prin definitie.
##
## Si creasta COBOARA: de la 29 m la 0,225 la 4 m la 0,36. Deci un obiect din
## fata camerei e deja sub ea. probe_mp_c_sky.gd, de la ochiul capturii 0,2400:
##   distanta   cota drumului fata de ochi   H necesar ca varful sa fie 3 grade
##                                           PESTE orizontala (adica pe cer)
##     22 m            -11,79 m                      12,8 m
##     39 m            -13,49 m                      15,4 m
##     56 m            -15,19 m                      18,0 m
##
## Adica: silueta ceruta de bara costa 13-16 m de inaltime, nu 5. Un condor de
## 2,2 m pe un bolovan de 3 m nu ajungea nici la o cincime din prag — de aia
## capturile aratau coama goala si de aia criticul n-a gasit nimic vertical.
##
## Solutia e cea din bara, citita inca o data: ACOLO CONDORUL STA PE UN PINTEN,
## nu pe o piatra. Stanca da inaltimea; pasarea da doar semnatura de sus. Deci
## `moss_boulder_c` (3,069 m) se stivuieste in trei bucati care se ingusteaza —
## o silueta de stanca, nu un bolovan umflat. Anvergura condorului urca de la
## 2,58 m la ~6 m ca sa ramana citibila de la 27 m: acolo pasarea acopera ~7%
## din latimea cadrului, deci se vede ca pasare, nu ca punct.
##
## UNDE, SI CELE PATRU INCERCARI CARE AU DUS ACOLO. Merita scrise toate,
## fiindca fiecare a picat pe alt motiv si impreuna dau regula.
##
## (a) 0,2448, partea +1, la 1 m dincolo de muchie, pe o "banca" de -1,92 m.
##     `_sol_real` a refuzat: "30,2 m sub drum". probe_mp_c_lip.gd a masurat
##     DOUA cote in acelasi punct — prima coliziune si terenul propriu-zis:
##
##       offset:        -3      -2      -1    -0,5     0,0    +0,5    +1,0
##       ORICE corp:  0,00    0,00    0,00    0,00    0,00   -0,96   -1,92
##       TEREN:      -4,85  -11,20  -17,55  -20,72  -23,90  -27,07  -30,25
##
##     Banca NU E TEREN: e umarul DALEI DE DRUM. (Memoria
##     terrain-mesh-y-extrapoleaza, pe dos: nu campul neted minte, ci raza care
##     se opreste in primul lucru pe care il atinge.)
##
## (b) Stiva de trei `moss_boulder_c` de 20 m la 0,2555. Cifra a iesit — varf la
##     42,0, peste ochiul de 37,7 — si captura a aratat de ce cifra nu era
##     intrebarea: un bolovan cu capac de muschi ramane bolovan la orice scara,
##     iar la 9 m capacul devine un DISC VERDE de 12 m. Trei clatite suprapuse.
##     (Memoria capcana-parametrului-care-doar-aduna.)
##
## (c) `huayna_picchu` scalat la 20 m. Silueta buna, dar piesa e munte de
##     fundal: la inaltimea ceruta baza iese de 48 m si ingroapa drumul, iar de
##     aproape benzile ei de albedo se citesc ca un tort.
##
##     Dupa (c) am masurat kitul in loc sa mai incerc piese. Zveltetea
##     (inaltime / latura mare a bazei): guardhouse 1,00 · moss_boulder_a 0,87 ·
##     inca_stair_b 0,83 · moss_boulder_b 0,79 · moss_boulder_c 0,73 · ... ·
##     inti_punku 0,20. CEA MAI ZVELTA PIESA DIN KIT E UN CUB. Orice piesa dusa
##     la 20 m inaltime capata 23-52 m de baza. Silueta inalta pe cer nu se
##     poate cumpara din kitul asta — e o proprietate a assetului, nu a asezarii.
##
## (d) Atunci am cumparat APROPIEREA in loc de inaltime: stanca de 8 m la 0,2436,
##     la 18,9 m de ochi. Captura a aratat condorul clar, pe banda de nor — dar
##     si stanca stand CALARE PE DRUM. Cauza, gasita la masuratoare: offsetul se
##     aplica CENTRULUI, iar cu raza de 4,52 m silueta ajungea cu 7,02 m peste
##     carosabil. ProbeLaneClear a trecut (18, sub linia de baza 20) fiindca
##     piesa are coliziune `none` — garda masoara corpuri, iar aici corp nu era.
##     Captura a aratat ce cifra n-avea cum sa arate.
##
##     Corectarea offsetului (pe silueta, nu pe centru) a mutat centrul la 10,2 m
##     de ax — si acolo terenul e la -11,8 m. Adica exact cornisa.
##
## CE A LAMURIT TOT: probe_mp_c_umar.gd, care a intrebat direct cat de departe
## dincolo de muchie mai e teren, pe toata zona C. Pe 0,232-0,358 umarul e intre
## -1 si +5 m si de cele mai multe ori zero — soseaua e cornisa peste aer pe
## ambele parti, pe 126 de fractii. Nu exista loc pentru niciun obiect de volum
## langa drum pe portiunea de creasta. Incercarile (a) si (d) n-au picat pe
## execuție, ci pe o premisa falsa: ca ar exista un umar acolo.
##
## Cele doua locuri cu pamant sunt capetele: 0,220-0,232 (umar 5-12 m pe partea
## -1) si de la 0,364 incolo (12 m pe ambele). Ansamblul se pune pe primul,
## la 0,2320: langa poarta (0,2250), pe umarul de 5 m, exact cum cere brief-ul
## ("condorul pe stanca alaturata" portii) si cum arata bara, unde poarta si
## condorul sunt UN grup, nu doua obiecte in locuri diferite.
##
## Costul, spus pe fata: ansamblul cade inaintea fractiei judecate 0,24, deci
## captura de la 0,24 tot nu-l contine. Se vede insa cand CONDUCI, pe 0,21-0,24,
## si se vede in captura de la 0,22. Alternativa ar fi fost sa-l mut la 0,358,
## unde ar fi prins captura 0,36 — dar acolo nu mai e creasta, e coborarea, si
## poarta ar fi ramas singura la celalalt capat. Un ansamblu rupt in doua ca sa
## nimereasca o fractie de judecata e exact genul de optimizare care arata bine
## in raport si prost in joc.
## MUTAT DE LA 0,2320 LA 0,2200 IN ACEEASI RUNDA, dupa captura. La 0,2320
## stanca era la 2,5 miimi DUPA poarta, deci camera care vedea poarta o avea
## exact in spatele piciorului drept, iar camera care ajungea langa ea trecea
## prea aproape ca sa mai incapa in cadru. Se vedea stanca, nu se vedea pasarea.
##
## 0,2200 e INAINTEA portii (0,2250), pe umarul de 12 m masurat de
## probe_mp_c_umar.gd — cel mai lat din tot POI-ul. Consecinte, toate in
## directia buna:
##  - intra in acelasi cadru cu poarta, din camerele de la 0,205-0,220, adica
##    poarta si condorul se citesc ca UN ansamblu. Asta cere si brief-ul
##    ("condorul pe stanca alaturata") si asta arata bara.
##  - 12 m de umar inseamna ca stanca poate creste fara sa se apropie de banda.
const CONDOR_FRAC := 0.2200

## Inaltimea ansamblului de stanca, in metri peste solul pe care se aseaza.
## 5,5: la scara 1,79 capacul de muschi al lui `moss_boulder_c` ramane capac
## (peste ~2,5 devine discul din incercarea (b)), iar raza siluetei ramane
## 3,10 m — incape pe umarul de 5,0 m masurat la 0,2320. Cu condorul deasupra
## ansamblul ajunge la ~10 m peste drum, adica la cota ochiului camerei.
## 7,5 in loc de 5,5: pe umarul de 12 m de la 0,2200 raza siluetei (1,73 *
## 2,44 = 4,23 m) incape cu marja, iar ansamblul cu condorul deasupra ajunge la
## ~12 m peste sosea. Peste ~2,5 scara capacul de muschi al lui
## `moss_boulder_c` incepe sa domine piesa, deci 2,44 e chiar sub prag.
const SPIRE_H := 7.5

## Distanta de la MUCHIA carosabilului la marginea siluetei stancii, spre
## exterior. Offsetul se aplica SILUETEI, nu centrului: centrul se aseaza la
## half + SPIRE_CLEAR + raza, deci marginea cade exact la SPIRE_CLEAR dincolo de
## muchie oricat de mare ar fi scara. Varianta care il aplica centrului isi
## schimba intelesul la fiecare scalare — asa a ajuns stanca pe drum la (d).
const SPIRE_CLEAR := 0.6

func _condor_rock() -> void:
	var n := _track.baked.size()
	var i := int(CONDOR_FRAC * float(n)) % n
	var p := _track.baked[i]
	var side := _track._side_at(i)
	var half := _track.width_at_index(i)
	# Partea se MASOARA la fiecare rulare, nu se scrie in cod: daca traseul se
	# redeseneaza, stanca trebuie sa ramana pe teren, nu pe fostul teren.
	# Se alege partea pe care solul de la SPIRE_OFF e mai sus.
	# Raza siluetei la scara ceruta: centrul se aseaza astfel incat MARGINEA sa
	# cada la SPIRE_CLEAR dincolo de muchie.
	var scl_mare := SPIRE_H / 3.069
	var r_silueta: float = 1.73 * scl_mare
	var d_centru := half + SPIRE_CLEAR + r_silueta
	var sg := 1.0
	var best := -INF
	for cand: float in [-1.0, 1.0]:
		var t := p + side * cand * d_centru
		var ty := _sol_real(t.x, t.z)
		if ty > best:
			best = ty
			sg = cand
	var q := p + side * sg * d_centru
	# Cota ca MEDIANA a trei raze de-a lungul drumului: o cusatura in panza de
	# teren strica un punct, nu o vecinatate. (Incercarea (a) a primit asa un
	# -23,9 izolat.) O masuratoare care se poate strica dintr-un singur esantion
	# nu e masuratoare.
	var probe: Array[float] = []
	for du: float in [-0.8, 0.0, 0.8]:
		var tg := _track.baked[(i + 1) % n] - _track.baked[(i - 1 + n) % n]
		tg.y = 0.0
		var r := q + tg.normalized() * du
		probe.append(_sol_real(r.x, r.z))
	probe.sort()
	var gy: float = probe[1]
	if p.y - gy > 3.0:
		print("; ATENTIE: soclul de la %.4f nu e teren (%.1f m sub drum, raze %s)" % [
			CONDOR_FRAC, p.y - gy, str(probe)])
		return
	# Stanca: doua `moss_boulder_c`, una mare si una care o sprijina lateral.
	# NU stivuite pe verticala (asta a dat clatitele la incercarea (b)): cea de
	# sus e mai MICA si decalata, deci silueta se ingusteaza spre varf si capacul
	# de muschi ramane un capac, nu un disc.
	#
	_raw("moss_boulder_c", "stancaCondor", Vector3(q.x, gy, q.z),
		_rng.randf_range(0.0, TAU), scl_mare, "none")
	# Contrafortul: 55% din cea mare, lipit de ea spre drum, cu talpa pe teren.
	var tg2 := _track.baked[(i + 1) % n] - _track.baked[(i - 1 + n) % n]
	tg2.y = 0.0
	var c2 := q + side * sg * 2.2 + tg2.normalized() * 1.4
	var gy2 := _sol_real(c2.x, c2.z)
	if p.y - gy2 <= 3.0:
		_raw("moss_boulder_c", "stancaCondor", Vector3(c2.x, gy2, c2.z),
			_rng.randf_range(0.0, TAU), scl_mare * 0.55, "none")
	# Condorul pe capacul celei mari. Capacul e sub cota AABB (forma e
	# rotunjita): 0,82 din inaltime, masurat pe silueta piesei.
	var top := gy + SPIRE_H * 0.82
	# Anvergura 6 m: la 18,9 m distanta acopera 16,7% din latimea cadrului,
	# adica se vede ca pasare cu aripi, nu ca punct. Piesa are 1,36 m la scara 1.
	var condor_scl := 6.0 / 1.36
	# PRIVIREA. Prima varianta o intorcea "spre drum" (perpendicular pe ax) si
	# captura a aratat pasarea DIN SPATE: spinare gri si mot rosu, fara profil.
	# Motivul, evident dupa ce l-am vazut: masina nu vine dinspre drum, vine
	# dinspre COADA pistei. Un condor care se uita spre ax ii arata spatele
	# soferului care se apropie.
	#
	# Se intoarce deci spre camera care vine, adica INAPOI pe tangenta, cu o
	# abatere spre drum ca sa nu fie perfect frontal (o silueta strict din fata
	# e mai plata decat una la trei sferturi).
	var inapoi := _track.baked[(i - 6 + n) % n] - _track.baked[i]
	inapoi.y = 0.0
	inapoi = inapoi.normalized()
	var spre_ax := (p - q)
	spre_ax.y = 0.0
	spre_ax = spre_ax.normalized()
	var privire := (inapoi * 0.75 + spre_ax * 0.25).normalized()
	var yaw := atan2(-privire.z, privire.x)
	_raw("condor", "condor", Vector3(q.x, top, q.z), yaw, condor_scl, "none")
	print("; stanca la frac %.4f parte %+.0f: soclu %.1f, capac %.1f (%.1f m peste drum)" % [
		CONDOR_FRAC, sg, gy, top, top - p.y])
	print(";   scara %.2f, raza silueta %.2f m, centru la %.2f m de ax, margine la %+.2f fata de muchie" % [
		scl_mare, r_silueta, d_centru, d_centru - r_silueta - half])
	print("; condor scara %.2f (anvergura %.1f m), varf aripi la %.1f (%.1f m peste drum)" % [
		condor_scl, 1.36 * condor_scl, top + 1.156 * condor_scl,
		top + 1.156 * condor_scl - p.y])


## (3) CASA PAZNICULUI la 0,33 — cadrul pozei clasice (brief §2, tabelul POI).
##
## De ce pe -1 si nu pe +1: la 0,33 partea -1 e cea care da spre terase si spre
## Huayna Picchu, adica exact directia in care priveste soferul cand casa e in
## cadru. O casa pe partea falezei ar sta cu spatele la priveliste.
##
## Scara 0,85: la 7,878 m casa ar fi cu 2 m mai inalta decat poarta de 5 m si ar
## domina creasta; brief-ul o descrie ca o casa mica cu acoperis de paie, iar in
## bara e vizibil mai mica decat poarta. 0,85 -> 6,70 m.
const GUARD_FRAC := 0.3300

func _guardhouse() -> void:
	# RUNDA 1 A ALES PARTEA DIN RATIONAMENT, si terenul a contrazis-o. Presupusesem
	# -1 fiindca "acolo e cetatea"; probe_manual a raspuns "casaPaznic8 PLUTESTE
	# 5,35 m", iar profilul fin (probe_mp_c_condor.gd, 0,3300) a aratat de ce:
	#
	#   offset fata de muchie:  -2,0   -1,0    0,0   +1,0   +2,0
	#   partea -1:             -4,83  -6,08  -7,33  -8,57  -9,75   <- cade DEJA
	#   partea +1:             -1,93  -1,98  -2,02  -6,31 -12,22   <- tine pana pe muchie
	#
	# Pe partea -1 terenul e cu 4,8 m sub sosea deja la DOI METRI INAINTE de
	# muchie — acolo nu se poate pune o casa, se poate pune cel mult un copac pe
	# fata rapei. Casa merge pe +1, unde exista prag.
	#
	# Partea nu se mai scrie in cod: se citeste din teren la fiecare rulare, ca
	# `_downhill_side` la POI G. Daca traseul se redeseneaza, casa se muta singura.
	# RUNDA 2: si casa a fost refuzata in tacere (0 noduri "casaPaznic" in .tscn).
	# La `gap = 0,9` centrul ei ajunge la 6,5 + 0,9 + 3,41 = 10,8 m de ax, adica
	# 4,3 m dincolo de muchie — pe cornisa, in gol. `gap` se masoara pana la
	# MARGINEA corpului, deci pentru o piesa lata conteaza raza, nu gap-ul.
	#
	# Casa se lipeste de umar: gap 0,15 m pune corpul la 6,65 m de ax, adica
	# fix langa banda, si centrul la 10,06 m. Pe partea aleasa de `_solid_side`
	# (masurata: +1 la 0,3300, unde solul pe muchie e la -2,02 fata de -7,33 pe
	# cealalta parte) acolo chiar e teren.
	# Casa e singura piesa din POI care TREBUIE sa aiba corp (e o cladire; daca
	# masina trece prin ea, cadrul pozei clasice devine o fantoma). Cum pe buza
	# nu e loc pentru un hull de 3,41 m raza, casa se muta INAPOI de la muchie:
	# se cauta fractia din jurul lui 0,33 la care exista cel mai mult umar, si
	# se pune acolo. Cadrul pozei ramane la 0,33 — ce conteaza e ca o VEZI din
	# masina la 0,33, nu ca talpa ei sa fie la 0,3300 exact.
	var gs := _solid_side(GUARD_FRAC)
	var gf := _best_shelf(GUARD_FRAC, gs)
	_place("guardhouse", "casaPaznic", gf, gs, 0.4,
		_yaw_to_road(gf, gs), 0.85, "hull")
	# O ruina mica alaturi, ca sa nu fie un singur obiect pe creasta: in bara
	# constructiile vin in grup, nu una singura.
	var ff := GUARD_FRAC + _step(14.0)
	var rs := _solid_side(ff)
	var rf := _best_shelf(ff, rs)
	_place("inca_house_b", "ruinaPaznic", rf, rs, 0.4,
		_yaw_to_road(rf, rs) + 0.4, 1.0, "hull")


## Fractia din vecinatatea lui `frac` (±35 m) la care partea `sg` are cel mai
## mult UMAR: cota solului la 5 m dincolo de muchie, cat mai aproape de sosea.
## Pe o cornisa umarul apare si dispare pe portiuni; nu se ghiceste unde e.
func _best_shelf(frac: float, sg: float) -> float:
	var n := _track.baked.size()
	var best := frac
	var best_y := -INF
	var d := -35.0
	while d <= 35.0:
		var f := frac + _step(d)
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i) * sg
		var half := _track.width_at_index(i)
		var q := p + s * (half + 5.0)
		var rel := _sol_real(q.x, q.z) - p.y
		if rel > best_y:
			best_y = rel
			best = f
		d += 2.5
	print("; umar pentru cladire: frac %.4f (sol la 5 m de muchie: %+.2f m)" % [
		best, best_y])
	return best


## Pe ce parte e teren care TINE o cladire la fractia `frac`: cea la care solul
## de pe muchie e mai aproape de cota soselei. Se masoara PE MUCHIE, fiindca
## acolo ajunge talpa, nu la 3 m unde masurau garzile de felie.
func _solid_side(frac: float) -> float:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var best := -INF
	var sgn := 1.0
	for sg: float in [-1.0, 1.0]:
		var q := p + s * sg * half
		var y := _sol_real(q.x, q.z)
		if y > best:
			best = y
			sgn = sg
	return sgn


## Yaw-ul care intoarce fata piesei spre drum, de pe partea `sg`.
func _yaw_to_road(frac: float, sg: float) -> float:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var to_road := -_track._side_at(i) * sg
	return atan2(-to_road.z, to_road.x)


## (4) PUNCTUATIA DE MUCHIE — raspunsul la ce a aratat captura.
##
## Nota 2 din survey: unghiul e reparat, dar caderea din stanga tot nu se
## citeste, fiindca fata taiata ramane verde ca iarba de deasupra. Muchia se
## marcheaza deci cu MATERIE: pietre de creasta lipite de buza, care dau linia
## unde terenul se termina.
##
## Nu e un zid continuu (aia e semnatura lui G, si brief-ul cere aici
## PUNCTUATIE). Sunt bolovani si scurte reprize de zidarie, dese unde caderea e
## mare si absente unde nu e.
##
## Pragul: se pune ceva doar unde caderea la 3 m de muchie trece de
## `LIP_FALL_MIN`. Sub atat nu e muchie, e coasta, si o piatra acolo ar minti.
const LIP_FALL_MIN := 4.0
## Cat de des. 9 m: la 31 m/s (viteza masurata de ProbeRace pe felia 0.20-0.30)
## inseamna o piatra la fiecare 0,3 s — dens cat sa citeasca linie, rar cat sa
## nu fie gard.
const LIP_STEP := 9.0
## Distanta de la MUCHIE la marginea corpului. 0,9 m: peste EDGE_KEEP (0,8), deci
## nu e obstacol pe umar, si sub 1 m, deci nu ramane iarba intre asfalt si piatra
## (lectia rundelor 4-7 de la POI G).
## RUNDA 2: TOATE cele ~30 de piese de muchie au fost REFUZATE in tacere, si
## inventarul .tscn a aratat-o (0 noduri "muchie"), nu sonda.
##
## Cauza e aceeasi cu a plutitoarelor, doar ca de partea cealalta a garzii:
## `_place` masoara `gap` de la muchie SPRE AFARA, iar profilul fin
## (probe_mp_c_condor.gd) spune ca pe cornisa, la +0,5 m dincolo de muchie,
## solul e deja la -4,18 m. Deci `LIP_GAP = 0,9` punea fiecare piatra peste gol,
## si garda de plutire (corect) le arunca pe toate.
##
## O piatra de creasta nu sta DUPA muchie, sta PE ea: jumatate pe umar, jumatate
## deasupra golului — asta e ce o face sa citeasca drept buza. Deci gap-ul
## devine NEGATIV: centrul piesei intra spre drum cu raza corpului, iar silueta
## atarna peste margine.
##
## -0,35 m: cu raza medie a bolovanilor (0,4-1,2 m la scara folosita) corpul
## ramane la 0,6-0,9 m dincolo de banda, deci peste EDGE_KEEP (0,8) la piesele
## mari si la limita la cele mici — si toate sunt `hull` mic, nu ziduri.
## RUNDA 3: -0,35 a dus piesele IN BANDA (54 de avertismente "corpul la 6,15 m
## de ax, muchia la 6,50") si tot n-a asezat decat 5 din ~30.
##
## Aici se vede constrangerea reala a POI-ului, si merita scrisa ca atare:
## PE CORNISA NU EXISTA UMAR. Buza e la 0,5 m de asfalt si peretele cade imediat
## (profil masurat: -4,18 m la +0,5 m dincolo de muchie). Deci pentru o piesa cu
## CORP nu exista pozitie buna — ori intra pe banda, ori atarna in gol. Cele
## doua incercari (0,9 si -0,35) sunt exact cele doua capete ale aceleiasi
## fisii inexistente.
##
## Solutia nu e o a treia cifra, e sa cada cerinta de corp: punctuatia de muchie
## e DECOR, nu obstacol. Cu `coliziune = "none"` piesa poate sta calare pe buza
## — silueta peste gol, talpa pe umar — fara sa fie nici obstacol pe banda, nici
## corp suspendat. Masinile trec prin ea, dar masinile n-au ce cauta acolo:
## dincolo de buza e prapastia, si ProbeLaneClear ramane pe linia de baza.
##
## 0,1 m: centrul cade la ~0,5-1,5 m dincolo de muchie, adica exact calare.
const LIP_GAP := 0.1

func _ridge_punctuation() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var half := _track.width_at_index(i)
		for sg: float in [-1.0, 1.0]:
			var s := _track._side_at(i) * sg
			var edge := p + s * half
			var y_edge := _sol_real(edge.x, edge.z)
			var q3 := p + s * (half + 3.0)
			var fall := y_edge - _sol_real(q3.x, q3.z)
			if fall < LIP_FALL_MIN:
				continue
			# Alternanta: bolovan / piatra de zid / bolovan mic. Un sir de
			# obiecte identice citeste a balustrada, nu a creasta.
			var mdl: String = ["moss_boulder_b", "inca_wall_c", "moss_boulder_a",
				"moss_boulder_b"][k % 4]
			var h := 1.0
			if mdl == "moss_boulder_b":
				h = _rng.randf_range(1.5, 2.1)
			elif mdl == "inca_wall_c":
				h = _rng.randf_range(1.0, 1.4)
			else:
				h = _rng.randf_range(0.6, 0.9)
			var scl := _scale_for(mdl, h)
			var yaw := _rng.randf_range(0.0, TAU)
			if mdl == "inca_wall_c":
				# Piesa de zid urmeaza muchia, nu se roteste aiurea.
				var tang := _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
				tang.y = 0.0
				tang = tang.normalized()
				yaw = atan2(-tang.z, tang.x)
			# Coboara putin sub buza: o piatra asezata exact pe cota arata
			# lipita, una infipta 15 cm arata crescuta din creasta.
			# `_below_lip` pornit: pe muchie solul E cu 1-2 m sub sosea
			# (profilul fin: -1,86 m la 0,2320), iar garda generala de 2,5 m ar
			# taia tocmai piesele de pe buza — cele pentru care cota joasa e
			# rostul lor. Marginea reala se apara prin `gap`, nu prin cota.
			# `none`: vezi nota de la LIP_GAP — piesa e semn de margine, nu
			# obstacol. `_below_lip` ii permite cota de buza (pana la -4 m).
			_below_lip = true
			_place(mdl, "muchie", f, sg, LIP_GAP, yaw, scl, "none", -0.15)
			_below_lip = false
			k += 1
		f += _step(LIP_STEP)


## (5) COROANELE DE SUB BUZA — semnalul 4 al barei: varfuri verzi care se vad
## peste margine, sub cota drumului, nu trunchiuri langa sosea.
##
## Departarea: 12-26 m de muchie. Cu cornisa (racord 6 m) peretele de sub buza
## cade in primii metri, deci la 12 m esti deja pe fata, si `_sol_real` coboara
## cu ea — copacul iese cu varful pe la nivelul buzei sau sub el, exact ce
## trebuie. Sub 12 m ar sta CHIAR pe muchie si ar astupa golul pe care POI-ul il
## vinde.
func _downhill_canopy() -> void:
	var n := _track.baked.size()
	var f := F_IN + _step(6.0)
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		for sg: float in [-1.0, 1.0]:
			var s := _track._side_at(i) * sg
			var half := _track.width_at_index(i)
			var q3 := p + s * (half + 3.0)
			var edge := p + s * half
			if _sol_real(edge.x, edge.z) - _sol_real(q3.x, q3.z) < LIP_FALL_MIN:
				continue
			var mdl := "polylepis_b" if k % 3 != 1 else "polylepis_a"
			var h := _rng.randf_range(5.5, 7.5) if mdl == "polylepis_b" \
				else _rng.randf_range(3.6, 4.6)
			# `_below_lip` = acelasi `_place`, dar FARA garda de plutire: aici
			# cota joasa e scopul, nu defectul. Coroanele stau pe fata rapei si
			# se vad peste buza — cu garda pornita s-ar refuza toate.
			_free_fall = true
			_place(mdl, "coroanaJos", f + _step(_rng.randf_range(-3.0, 3.0)), sg,
				_rng.randf_range(12.0, 26.0), _rng.randf_range(0.0, TAU),
				_scale_for(mdl, h), "trunk")
			_free_fall = false
			k += 1
		f += _step(12.0 + _rng.randf_range(-2.5, 2.5))


## (6) PARTEA CARE URCA. Pe 0,22-0,235 partea -1 e inca platou (saua portii) si
## pe 0,355-0,40 amandoua se aseaza: acolo creasta se termina si incepe
## coborarea spre terase. Pe portiunile alea decorul e cel de versant — bolovani
## cu muschi, ferigi, bromelii — ca sa nu ramana iarba goala intre poarta si
## muchie.
func _uphill_side() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var half := _track.width_at_index(i)
		for sg: float in [-1.0, 1.0]:
			var s := _track._side_at(i) * sg
			var edge := p + s * half
			var q3 := p + s * (half + 3.0)
			# DOAR unde NU e gol: aici e umplutura de versant, complementul
			# punctuatiei de muchie.
			if _sol_real(edge.x, edge.z) - _sol_real(q3.x, q3.z) >= LIP_FALL_MIN:
				continue
			var cnt := 1 + (k % 3)
			for j in cnt:
				var mdl := "moss_boulder_c" if j == 0 else (
					"moss_boulder_b" if j % 2 == 1 else "moss_boulder_a")
				var h := _rng.randf_range(2.4, 3.2) if j == 0 else (
					_rng.randf_range(1.3, 1.9) if j % 2 == 1
					else _rng.randf_range(0.6, 1.0))
				# 2,2-6,5 m a produs 8 bolovani plutitori (probe_manual r1):
				# dincolo de ~4 m incepe racordul cornisei. Garda de plutire ii
				# refuza oricum, dar cautand mai aproape se pastreaza piesele.
				_place(mdl, "bolovan", f + _step(_rng.randf_range(-3.0, 3.0)), sg,
					_rng.randf_range(1.6, 4.2), _rng.randf_range(0.0, TAU),
					_scale_for(mdl, h), "hull", -0.15)
			if k % 2 == 0:
				_place("tree_fern", "feriga", f + _step(4.0), sg,
					_rng.randf_range(2.0, 4.0), _rng.randf_range(0.0, TAU),
					_scale_for("tree_fern", _rng.randf_range(2.4, 3.2)), "trunk")
			if _rng.randf() < 0.7:
				_place("bromeliad", "bromelie", f + _step(2.0), sg,
					_rng.randf_range(1.5, 3.4), _rng.randf_range(0.0, TAU),
					_scale_for("bromeliad", _rng.randf_range(0.5, 0.9)), "none")
			if _rng.randf() < 0.12:
				_place("orchid_cluster", "orhidee", f + _step(6.0), sg,
					_rng.randf_range(1.6, 3.2), _rng.randf_range(0.0, TAU),
					_scale_for("orchid_cluster", _rng.randf_range(0.45, 0.7)),
					"none")
			k += 1
		f += _step(11.0 + _rng.randf_range(-2.0, 2.0))


## (7) PARAPETUL PUNCTUAT si bornele.
##
## Brief: `rope_rail` doar la CELE DOUA ACE ("punctuatie"), nu pe toata creasta:
## pe dreapta defileul TREBUIE sa se vada, si un parapet continuu il ascunde
## exact cand e cel mai spectaculos.
##
## Acele se citesc din curbura, la fel ca la POI G: maximele locale ale lui
## |curbura| pe felie, despartite de cel putin 30 m.
func _markers() -> void:
	var n := _track.baked.size()
	# PRIMA RULARE A ALES ACELE GRESIT, si print-ul a aratat unde: 0,3821 (raza
	# 9,2 m) si 0,3650 (raza 18,1 m). Amandoua sunt DUPA ce se termina creasta —
	# la 0,365 rapele 0 si 1 s-au stins (survey: cadere -0,3 m pe ambele parti)
	# si drumul intra in cascada de terase, adica POI-ul D. Un parapet de creasta
	# pus acolo e parapetul altcuiva.
	#
	# Maximul global pe felie nu e criteriul, fiindca felia mea include si
	# racordul spre D. Acele CRESTEI sunt cele doua S-uri din brief, si se
	# recunosc prin faptul ca au GOL de ambele parti: se cauta doar acolo unde
	# muchia chiar cade (acelasi prag ca la punctuatie).
	var peaks: Array[Vector2] = []
	var f := F_IN
	while f < F_OUT:
		var i := int(f * float(n)) % n
		if _both_sides_fall(i):
			peaks.append(Vector2(f, absf(_curv(i))))
		f += _step(2.0)
	peaks.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y > b.y)
	var chosen: Array[float] = []
	for pk: Vector2 in peaks:
		if chosen.size() >= 2:
			break
		var ok := true
		for c: float in chosen:
			if absf(c - pk.x) < _step(30.0):
				ok = false
		if ok:
			chosen.append(pk.x)
	for c: float in chosen:
		var ci := int(c * float(n)) % n
		print("; ac la frac %.4f, curbura %.4f (raza %.1f m)" % [
			c, absf(_curv(ci)), 1.0 / maxf(absf(_curv(ci)), 1e-6)])
		var sg := _worse_fall_side(ci)
		for j in range(-2, 4):
			var ff := c + _step(4.14 * float(j))
			var i := int(ff * float(n)) % n
			var p := _track.baked[i]
			var side := _track._side_at(i) * sg
			var tang := _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
			tang.y = 0.0
			if tang.length() < 0.01:
				continue
			tang = tang.normalized()
			var half := _track.width_at_index(i)
			var q := p + side * (half + 0.45)
			# Parapetul nu urca peste buza si nu se ingroapa: minimul dintre cota
			# drumului si solul real + 10 cm (lectia parapet311 de la POI G).
			var gy: float = maxf(_sol_real(q.x, q.z), _sampler.ground_y(q.x, q.z))
			_raw("rope_rail", "parapet",
				Vector3(q.x, minf(p.y + 0.25, gy + 0.10), q.z),
				atan2(-tang.z, tang.x), 1.0, "none")
	# Bornele pe muchia care cade mai tare, la fiecare 26 m.
	f = F_IN + _step(13.0)
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var sg := _worse_fall_side(i)
		var half := _track.width_at_index(i)
		var q := p + _track._side_at(i) * sg * (half + WALL_HALF_THICK)
		_raw("trail_marker", "borna", Vector3(q.x, p.y + 0.25, q.z), 0.0,
			_scale_for("trail_marker", 1.2), "none")
		f += _step(26.0)


## Cade terenul de AMBELE parti la indexul i? Asta e definitia operationala a
## "creastei" in POI-ul asta, si separa felia mea (0,235-0,352) de racordul
## spre terase (0,355+), unde rapele s-au stins.
func _both_sides_fall(i: int) -> bool:
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	for sg: float in [-1.0, 1.0]:
		var edge := p + s * sg * half
		var q3 := p + s * sg * (half + 3.0)
		if _sol_real(edge.x, edge.z) - _sol_real(q3.x, q3.z) < LIP_FALL_MIN:
			return false
	return true


## Pe ce parte cade mai tare la indexul i. Se CITESTE din teren la fiecare
## folosire — pe creasta amandoua cad, dar nu la fel.
func _worse_fall_side(i: int) -> float:
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var best := 0.0
	var sgn := 1.0
	for sg: float in [-1.0, 1.0]:
		var q := p + s * sg * (half + 8.0)
		var drop := p.y - _sol_real(q.x, q.z)
		if drop > best:
			best = drop
			sgn = sg
	return sgn


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
	# GARDA DE PLUTIRE, adaugata dupa `probe_manual --track=15` (runda 1): 15 din
	# 146 de piese pluteau intre 3,2 si 68,3 m. Cauza, una singura pentru toate:
	# pe o CORNISA buza e la 0,5 m de asfalt si racordul e 6 m, deci orice piesa
	# asezata la mai mult de ~1 m dincolo de muchie cade pe PERETE, nu pe umar.
	# Testele mele de "aici nu e gol" masurau la 3 m de muchie, dar piesele
	# plecau pana la 6,5 m — adica se decidea intr-un punct si se punea in altul
	# (exact capcana din runda 3 a lui POI G).
	#
	# Aici nu se mai deduce nimic: se compara cota pe care AR PRIMI-O piesa cu
	# cota drumului de alaturi. Daca e mai jos cu peste `DROP_REJECT`, piesa e
	# pe fata peretelui si se refuza — nu se ridica, fiindca ridicarea e chiar
	# mecanismul care a produs plutirea la condor si la aripile portii.
	# `_below_lip` nu e "orice cota merge": piesele de buza au voie sa stea sub
	# sosea, dar nu pe podeaua rapei (la -22 m). Plafonul lor e `LIP_DROP_MAX`.
	var limita: float = LIP_DROP_MAX if _below_lip else DROP_REJECT
	if not _free_fall and p.y - g > limita:
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
	return _sampler.ground_y(x, z)
