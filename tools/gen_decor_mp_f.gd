extends Node
## Generator de decor MANUAL pentru POI F — MALUL RAULUI (Track15, Machu
## Picchu, frac 0.66-0.72, cel mai jos punct al turului). Nu e sonda:
## CALCULEAZA transformarile care se lipesc in Track15.tscn sub
## `DecorManual/ZoneF_MalulRaului`, pe teren real (raycast pe TerrainBody, nu
## `_terrain_mesh_y` — memoria `terrain-mesh-y-extrapoleaza`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpF.tscn -- \
##       --out=<fisier> [--survey]
##
## CE DECIDE COMPOZITIA (masurat cu --survey, runda 1, F_r1_survey.txt).
##
## 1. GEOMETRIA E UN AC IN JURUL UNUI BAZIN, nu o coborare dreapta pe mal.
##    Bratul de dus (0.655-0.685) merge spre vest pe z ~ -170..-157, bratul de
##    intors (0.695-0.730) vine spre est pe z = -134. Intre ele, la SUD de
##    amandoua, e un POLICIOR de teren plat masurat pe harta de 10 m:
##
##      z <= -190 -> cota -34.4 (x=-135), -35.4 (-155), -36.4 (-175),
##                   -34.0 (-195), -30.2 (-215)
##
##    Malul care coboara la el e intre z = -178 si z = -190 (de la -25 la -33 in
##    ~8 m orizontali, deci ~45 grade). Soseaua pe bratul de dus e la y = -25.7,
##    deci POLICIORUL E LA -8..-10 M SUB DRUM, la 30-55 m lateral. Acolo curge
##    raul: e singurul loc unde poate curge, si e chiar acolo unde ESTACADA
##    trenului il traverseaza (TrenPeruRail la (-160, -33, -205), sina pe X,
##    half_rail 65, deci x de la -225 la -95).
##
## 2. RAUL SE VEDE DOAR DE PE BRATUL DE DUS. Pe bratul de intors (z = -134)
##    profilul lateral masurat urca inainte sa coboare: la 0.710 solul e +1.3 m
##    la 40 m si abia apoi -6.0 la 50 m. Ochiul la 1.5 m peste o creasta la
##    +1.3 m de la 40 m vede, la 66 m (unde e albia), cota ~ -26.7; luciul e la
##    -34.2, adica 7,5 m SUB linia de vedere. Deci raul e ascuns de creasta aia.
##    Consecinta: la 0.70 POI-ul nu se poate baza pe apa — acolo lucreaza
##    tabara, vegetatia de mal si trenul pe orizont. Nu se muta traseul ca sa
##    vada apa (bara e LOOK, nu layout).
##
## 3. APA E GEOMETRIE PE SLOTURI, NU SHADER DE TEMA. `"water": false` e in
##    tema `machupicchu` (track.gd) si `_build_water` ar inunda TOATA pista la o
##    singura cota — un rau de munte la -34 m intr-o pista care are drumul intre
##    +35 si -30 nu incape in mecanismul ala. Raul e deci FlockProp cu
##    `disc_slot`, tiparul crustei de sare de la Serengeti POI E: placi plate de
##    12 laturi pe un slot de atlas existent, ZERO materiale in plus.
##    Luciul e slotul 18 SEA_DEEP (#2E5F6B), spuma slotul 22 FOAM_WHITE
##    (#E9F2F0) — exact perechea ceruta de brief §4. Singurul material pe care
##    il adauga POI-ul e clasa `granite` de pe pietrele din albie (vezi
##    `_river_rocks`), deci 17 -> 18 din 38.
##
## 4. SPUMA SE VEDE MULTA SI E PUTINA — masurat, nu impresie. Ochiul citeste
##    bara ca „repezisuri albe", si primele patru runde au construit exact asta:
##    in F_r5_0.66.png, 23,2 % din pixelii zonei de rau erau aproape-albi
##    (min(R,G,B) > 215). Pe BARA, aceeasi masuratoare da 0,8 % pe tot cadrul si
##    1,5 % pe banda de apa. Adica de cincisprezece ori mai putin.
##    Bara nu are apa alba: are apa CENUSIE-CALDA, rgb(124,114,98), H 38,
##    S 0,21, V 0,49, cu firicele albe pe ea. Ce da impresia de repezis e
##    CONTRASTUL local si desenul de pe pietre, nu suprafata alba.
##    Consecinta directa: spuma pastreaza mecanismele (dare in aval de piatra,
##    cascada pe prag), dar cantitatile scad de vreo sase ori, iar covorul peste
##    luciu dispare aproape complet. Cine o va urca la loc trebuie sa remasoare
##    procentul, nu sa se uite la miniatura.
##
## 5. LUCIUL NU E AUTORAT — il taie terenul. Nici jgheabul de sus, nici bazinul
##    de jos nu sunt albii: sunt tavi cu cote diferite (fundul e -33,1 la
##    x=-195 si -36,4 la x=-175, in bazin; -27,4..-28,3 in jgheab). Un
##    dreptunghi de apa la orice cota unica ar iesi ori peste mal ori sub
##    pamant pe jumatate din lungime. Solutia e cea a crustei de sare
##    (Serengeti E): se incearca placi in tot dreptunghiul si se PASTREAZA doar
##    cele cu sol REAL sub cota luciului, cu o cerinta de adancime care CRESTE
##    spre marginea casetei (0,15 m in mijloc, 1,2 m pe ultimii 12 m) — altfel
##    conturul se termina cu muchia casetei, si asta s-a si vazut in runda 2.
##
## 6. SOARELE (survey): rot (-40, 45, 0), lumina merge spre (-0.54, -0.64,
##    -0.54), elevatie 40 grade, umbra pe XZ -> (-0.707, -0.707). Pe bratul de
##    dus dot(side, umbra) = +0.87..+0.89, adica umbrele cad DINSPRE drum SPRE
##    rau: malul de nord (cel de sub sosea) isi arunca umbra pe apa, deci
##    bolovanii de pe buza se citesc pe luciu. De aia randul de bolovani de pe
##    buza e mai des decat cel de pe malul opus.
##
## 7. APA E REPUNERE, si ASTA E O GAURA DE GAMEPLAY EXISTENTA, nu o cerinta de
##    decor. ProbeRespawnZones pe starea de plecare gaseste doar `BridgeFall` si
##    `ViaductNet2` (x de la -106 la 94) — bazinul, x de la -276 la -108, N-ARE
##    plasa. Cine iese pe dreapta la 0.66-0.68 aluneca 10 m in jos si ramane
##    acolo, fiindca panta de intoarcere e de 45 de grade. Zona pune deci un
##    `RespawnZone`, cu plafonul MASURAT (nu ghicit): se baleiaza traseul, se ia
##    cota cea mai joasa a carosabilului din amprenta (marginea inclusa) si
##    plafonul sta cu 2,5 m sub ea. Iese -30,4, adica prinde bazinul adanc si NU
##    prinde jgheabul de sus — corect, fiindca jgheabul e la 1-2 m sub drum si
##    din el se iese conducand.
##
## 8. DEGAJAREA se masoara de la MUCHIA drumului la CORPUL piesei, iar pragul
##    de camera (coroana n-are voie sub 4.0 m de ax) e cel din
##    gen_decor_ser_d.gd — camera de joc zboara pe axa. In plus, dupa runda 3,
##    fiecare piesa asezata cu `_place` se verifica fata de TOT traseul copt, nu
##    doar fata de fractia ei: pe viraj drumul revine spre piesa cateva zeci de
##    metri mai incolo, si un bolovan „la 5 m de muchie" iesise fix pe carosabil.
##
## 9. DE CE DOUA REPRIZE DE APA. Runda 1 a pus raul in bazinul adanc, unde CHIAR
##    e cel mai jos punct — si in captura de la volan nu s-a vazut NIMIC.
##    `ProbeMpFSeen` (scrisa pentru asta) a masurat de ce, cu camera de joc
##    reala (12,5 m in spate, 10 m sus, fov 68 v / 100 h): la y = -34,2, din 125
##    de celule de grila aflate in frustum la 0.67, exact 34 erau neocluzate, si
##    toate 34 la x sub -260 — adica in cu totul alta vale. Bazinul insusi era
##    „in cadru dar ascuns de creasta".
##    Aceeasi sonda, plimbata pe cote, a gasit ce SE vede: o tava la -27,4..-28,3
##    pe x de la -260 la -205, z de la -200 la -168, neocluzata de la 0.660 pana
##    la 0.675 (70-83 de celule din ~120). Acolo s-a mutat apa pe care o vede
##    jucatorul. Bazinul adanc a ramas, cu luciul lui, fiindca acolo trece
##    estacada trenului si acolo se duce apa — dar e aval, nu decor de cadru.
##    Lectia, scrisa pentru urmatorul: „langa drum" nu inseamna „in cadru", iar
##    „in cadru" nu inseamna „vizibil". Sunt trei teste, si numai al treilea
##    conteaza.

## 10. `probe_manual` RAPORTEAZA FALS „INGROPAT" AICI, SI ARE DE CE.
##     Sonda compara cota piesei cu `_sampler.ground_y`, adica CAMPUL NETED
##     (media Shepard peste punctele coapte), pe cand generatorul aseaza pe
##     raycast in TerrainBody. Zece piese din tabara au iesit „INGROPAT" cu
##     2,5-3,7 m. Verificat punct cu punct pe o transversala de 6 m la
##     x = -203,4:
##
##       z       raycast   sampler
##       -115,0  -22,94    -20,70
##       -116,5  -24,24    -21,31
##       -117,7  -25,28    -21,98
##       -119,0  -26,41    -26,55
##       -121,0  -27,32    -27,74
##
##     Raycastul coboara LIN, cu ~0,73 m la fiecare metru; samplerul sare cu
##     4,6 m intre -117,7 si -119,0 si abia dupa aia prinde din urma. Deci
##     terenul REAL e o panta continua, iar campul neted e cel care se rupe —
##     exact memoria `terrain-mesh-y-extrapoleaza`, si exact motivul pentru care
##     `_sol_real` trage raza in loc sa intrebe samplerul.
##     Nu s-a mutat nimic si nu s-a adaugat niciun filtru: piesele stau corect
##     pe terenul pe care il ating masinile. Cine vrea garda verde trebuie sa
##     repare sonda (sa traga si ea raza), nu decorul.
##     Si: `probe_manual` ia NUMARUL DE SCENA (isi compune calea cu
##     `"Track%02d.tscn" % idx`), deci `--track=15`. Cu `--track=8` masoara
##     Okinawa si raporteaza `coral_rock` si `coconut_palm`.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneF_MalulRaului"
const F_IN := 0.655
const F_OUT := 0.730

## NOTA 11 (runda 2). Reprizele `UP_*` / `LOW_*` ale rundei 1 au DISPARUT,
## si merita spus de ce, fiindca erau rezultatul unei masuratori corecte
## interpretate gresit. Erau doua dreptunghiuri de apa, fiecare la un singur Y
## — si exact asta a numit criticul orb „o panza turcoaz plata la un singur Y".
## Masuratoarea care le-a produs (nota 9: ce se vede de la volan) ramane
## valabila si e chiar cea care a ghidat albia noua; ce a fost gresit e forma,
## nu locul. Vezi blocul de deasupra lui `CH_A` pentru ce le-a inlocuit.
## Calea ferata (TrenPeruRail): z = -205, x de la -225 la -95, sina la y = -33.
const RAIL_Z := -205.0

const RES := {
	"tent_a": "s_tent_a", "tent_b": "s_tent_b",
	"backpack_pile": "s_backpack_pile", "bamboo_clump": "s_bamboo_clump",
	"moss_boulder_a": "s_moss_boulder_a", "moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c", "inca_house_b": "s_inca_house_b",
	"tree_fern": "s_tree_fern", "polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b", "bromeliad": "s_bromeliad",
	"trail_marker": "s_trail_marker",
}
## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
const HEIGHT := {
	"tent_a": 1.407, "tent_b": 1.407, "backpack_pile": 0.694,
	"bamboo_clump": 5.010, "moss_boulder_a": 0.741, "moss_boulder_b": 1.957,
	"moss_boulder_c": 3.069, "inca_house_b": 2.833, "tree_fern": 3.306,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "bromeliad": 0.377,
	"trail_marker": 1.200,
}
## Raza la baza masurata (aceeasi sursa): degajarea se ia de la ea.
const BASE_R := {
	"tent_a": 1.46, "tent_b": 1.46, "backpack_pile": 0.60,
	"bamboo_clump": 0.50, "moss_boulder_a": 0.37, "moss_boulder_b": 0.94,
	"moss_boulder_c": 1.73, "inca_house_b": 3.64, "tree_fern": 0.30,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "bromeliad": 0.46,
	"trail_marker": 0.29,
}
## Raza COROANEI (XZ, semi-latura AABB) — testul de camera.
const CROWN_R := {
	"tent_a": 1.14, "tent_b": 1.14, "backpack_pile": 0.58,
	"bamboo_clump": 1.24, "moss_boulder_a": 0.43, "moss_boulder_b": 1.24,
	"moss_boulder_c": 2.11, "inca_house_b": 3.00, "tree_fern": 2.07,
	"polylepis_a": 1.51, "polylepis_b": 2.36, "bromeliad": 0.46,
	"trail_marker": 0.26,
}
const TRI := {
	"tent_a": 256, "tent_b": 256, "backpack_pile": 288, "bamboo_clump": 958,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"inca_house_b": 496, "tree_fern": 768, "polylepis_a": 598,
	"polylepis_b": 1098, "bromeliad": 248, "trail_marker": 76,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
## Sub-resursele care trebuie sa ajunga in ANTETUL lui Track15.tscn, nu sub
## nodul zonei (forma plasei de repunere). Se scriu intr-un fisier separat.
var _subres: Array[String] = []
var _n := 0
var _warn := 0
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
	_rng.seed = 660721
	_chan_init()
	_survey()
	if not _survey_only:
		_river()
		#_gravel()
		_river_rocks()
		_foam()
		_canyon_wall()
		_banks()
		_bank_edge()
		_road_side()
		_flanc()
		_station()
		_camp()
		_respawn()
		_write()
	get_tree().quit(0)


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
	print("; frac      ax(x,z)             y_drum  half  side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.02
	while f <= F_OUT + 0.02:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+7.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%8.1f,%8.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), s.dot(shadow)])
		f += 0.005
	if not _survey_only:
		return
	# HARTA in plan a bazinului: cota terenului pe o grila de 10 m, in
	# dreptunghiul care contine ambele brate ale acului si estacada trenului.
	print("; HARTA (x de la -320 la -120 pas 10; z de la -240 la -120 pas 10)")
	var zz := -240.0
	while zz <= -120.0:
		var row: Array[String] = []
		var xx := -320.0
		while xx <= -120.0:
			row.append("%+6.1f" % _sol_real(xx, zz))
			xx += 10.0
		print("; z=%+7.1f %s" % [zz, " ".join(row)])
		zz += 10.0
	# ALBIA DE SUS: unde tine cota -27.9? grila fina de 4 m.
	print("; JGHEAB (x de la -290 la -195 pas 5; z de la -200 la -165 pas 5)")
	var jz := -200.0
	while jz <= -165.0:
		var jr: Array[String] = []
		var jx := -290.0
		while jx <= -195.0:
			jr.append("%+6.1f" % _sol_real(jx, jz))
			jx += 5.0
		print("; z=%+7.1f %s" % [jz, " ".join(jr)])
		jz += 5.0
	# ALBIA: profil N-S fin (pas 4 m) pe cateva coloane x, in bazin.
	for xk: float in [-215.0, -195.0, -175.0, -155.0, -135.0]:
		var line2: Array[String] = []
		var zk := -230.0
		while zk <= -150.0:
			line2.append("%.0f:%+.1f" % [zk, _sol_real(xk, zk)])
			zk += 4.0
		print("; ALBIE x=%.0f  %s" % [xk, " ".join(line2)])
	# Profil transversal fin pe cateva fractii cheie: unde e albia?
	for fk: float in [0.665, 0.680, 0.695, 0.710, 0.725]:
		var i := int(fk * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var line: Array[String] = []
		var off := -110.0
		while off <= 110.0:
			var q := p + s * off
			line.append("%.0f:%+.1f" % [off, _sol_real(q.x, q.z) - p.y])
			off += 10.0
		print("; PROFIL %.3f  y_drum=%.1f  %s" % [fk, p.y, " ".join(line)])


# ------------------------------------------------------------------ raul

## Bolovanii din apa si de pe bancuri, retinuti ca ancore de spuma: o
## repezisura se citeste dupa darele din SPATELE pietrelor. Al patrulea camp e
## cota LUCIULUI reprizei din care face parte piatra (sunt doua), fiindca dara
## trebuie sa stea pe apa ei, nu pe a celeilalte.
## ALBIA, RUNDA 2: UN CANAL CU BAZINE SI PRAGURI, nu doua dreptunghiuri.
##
## De ce s-a schimbat. Criticul orb a spus, despre captura rundei 1: „apa e o
## panza turcoaz plata la un singur Y, cu elipse albe plutind decorativ peste
## ea, fara nicio legatura cu vreun obstacol — toti bolovanii sunt pe mal".
## Verificat in cod, avea dreptate de doua ori, si din doua cauze diferite:
##
##   (a) BOLOVANII. `_river_rocks` cerea `g >= wy - 2.2` pentru fiecare piatra.
##       Masurat acum (grila fina de 5 m, x -330..-200, z -185..-115): fundul
##       raftului tine intre -27,3 si -29,0 pe TOATA intinderea lui, adica
##       adancimea sub luciul de -28,0 nu trece nicaieri de 0,7 m. Filtrul nu
##       taia deci nimic in albie — dar perechea lui, `g <= wy + 1.2`, lasa
##       inauntru toata aria uscata de banc, care e de cateva ori mai mare
##       decat luciul. Esantionarea uniforma pe dreptunghi a pus prin urmare
##       majoritatea pietrelor pe pietris, exact cum s-a vazut.
##   (b) SPUMA. Din ~1000 de pietre ude, `if _rng.randf() > 0.09: continue`
##       dadea dara la vreo 90. Restul albului era covorul (b), adica placi
##       imprastiate la intamplare pe luciu — spuma FARA cauza, literal.
##
## CE S-A MASURAT INAINTE DE REPARAT (sonda temporara, grila de 5 m + profile):
##
##   1. Raftul de ~-28 incepe la x = -195 si se termina spre SV pe o BUZA care
##      merge oblic: x = -227 la z = -120, pana la x = -285..-305 la z = -180.
##      Dincolo de buza terenul cade la -32 si apoi in podeaua hartii (-40).
##   2. `ProbeMpFSeen` la frac 0.660 / 0.670 / 0.680 da acelasi raspuns de
##      trei ori: ce se vede de la volan e banda x -320..-210, z -180..-120.
##      Reprizele rundei 1 (z -204..-166) cadeau pe jumatate in zona ocluzata.
##   3. Profil pe linia propusa, esantionat din 6 in 6 m cu +-16 m lateral:
##      albia tine -27,6..-29,3 cap-coada, iar buza raftului sta constant la
##      14-26 m spre SV.
##
## CONSECINTA DE PROIECTARE, si e cinstit sa fie scrisa: raftul are ~1,3 m de
## denivelare pe 98 m. Nu exista aici cascade de sase metri si nu se inventeaza:
## ce incape sunt TREI BAZINE cu DOUA PRAGURI scurte intre ele (0,45 si 0,40 m),
## adica exact ce face un rau de munte pe un raft — si la 40-70 m de ochi un
## prag de o jumatate de metru cu banda alba pe muchie CITESTE ca treapta de
## repezis. Criticul a cerut „2-3 cote cu caderi scurte"; astea sunt, si sunt
## masurate, nu decorative.
##
## Albia e parametrizata pe (t, o): `t` de-a lungul firului, `o` lateral. Tot
## ce urmeaza — luciu, pietre, spuma — se aseaza in coordonatele astea, deci
## spuma STIE unde sunt pietrele si unde sunt pragurile.
## FIRUL ALBIEI. A patra oara — si merita scrise toate patru, fiindca fiecare a
## picat pe alt test, si impreuna sunt chiar lista de teste care trebuie trecute
## SIMULTAN. Cine muta albia a cincea oara sa le treaca pe toate, nu pe ultimul.
##
##   R1: in bazinul adanc (z <= -190, y = -34). Cota buna, dar `ProbeMpFSeen`:
##       0 celule neocluzate la frac 0.67. NU SE VEDEA.
##   R2a: pe raftul de -28, linia (-193,-138) -> (-275,-191). Se vedea, dar
##       firul trecea PE SUB SOSEA: pe pragul de la t=4 sonda a dat
##       `drum = -0,1 / -2,1 / -4,1 / -6,1`, adica metri INTRE marginile
##       carosabilului. De aia iesisera 0 pietre de prag si 0 benzi — garda de
##       carosabil respingea, corect, tot. Lectia: „terenul e jos" nu inseamna
##       „e loc", fiindca drumul insusi coboara pe raft.
##   R2b: in troaca de la z = -178, x = -240..-300. Libera de drum (16-50 m) SI
##       81-90 % din puncte neocluzate... si in captura apa a iesit 0,05 % din
##       cadru, fata de 4,57 % pe bara. Adica: „neocluzat" nu inseamna „se vede".
##       Troaca e la 60-100 m, oblica fata de privire, si subintinde aproape
##       nimic. Testul care lipsea e ARIA PE ECRAN, nu vizibilitatea binara.
##
## R2c (asta): se cer TOATE PATRU, si fiecare e masurata.
##   (a) LIBER DE DRUM: 17-37 m de la marginea carosabilului pe toata lungimea.
##   (b) VIZIBIL: neocluzat de la volan.
##   (c) ARIE PE ECRAN: sonda a clasat toate celulele de 10x10 m din zona dupa
##       aria proiectata la frac 0.67. Primele sase sunt toate pe z = -180..-190,
##       x = -210..-240, la 20-45 m de camera; celula (-210,-180) singura face
##       7,9 % din ecran — mai mult decat TOATA apa din bara (4,57 %).
##   (d) PANTA REALA: pe z = -190 terenul coboara de la -27,9 (x=-252) la -31,4
##       (x=-204), adica 3,5 m pe 48 m. Raul curge spre EST, spre bazinul adanc
##       si spre Urubamba — exact sensul din brief.
##
## R3 (ASTA, RELUAREA). NU e o a cincea mutare pe acelasi teren: TERENUL S-A
## SCHIMBAT sub picioarele rundelor 1-26. Fundatia a primit intre timp o
## CORNISA pe 0.6611-0.7400 (`custom_ravines` indicele 9, latime 70, fund -42,
## partea +1). Toate rundele de mai sus au construit pe terenul dinainte, cand
## rapa 3 se termina exact la 0.6611 si malul era platou: de aia raul „n-avea
## unde sa stea" si de aia in F_r26 apa citeste ca pete gri pe iarba la nivelul
## soselei. Nu era o greseala de asezare, era o premisa disparuta.
##
## CE E ACUM, masurat (tools/sv3_mpf.gd, tools/sv5_mpf.gd, pas 1-2 m):
##
##   Pe bratul de INTORS (frac 0.695-0.730, soseaua pe z = -134) terenul cade
##   la +8..+13 m lateral intr-o GORJA CU FUND PLAT, si urca inapoi la +25 m:
##
##     TRANS 0.710  ax=(-190.5,-134) y=-27.8
##       +5:-27.8  +8:-29.7  +10:-33.9  +13:-37.5  +20:-37.7  +25:-20.5
##
##   Fundul e o panza continua pe z = -112..-120, x = -212..-155:
##
##     FIR z=-120  x=-212:-40.9  -200:-40.2  -190:-39.7  -180:-39.3
##                 -170:-38.9    -160:-38.4  -158:-38.3
##
##   adica 2,6 m de cadere pe 54 m, CURGAND SPRE VEST (spre x mic), catre
##   canionul adanc de la x <= -220 (acolo fundul trece de -45 si cade in
##   podeaua rapei la -49) — exact sensul Urubamba din brief.
##   Peretele DE DINCOLO sare la -20..-22 pe z = -110: gorja are, in sfarsit,
##   spate vertical, deci nu mai trebuie inventat un „perete de canion" din
##   bolovani (vezi `_canyon_wall`, pastrata dar mutata pe rama noua).
##
## DE CE ACOLO SI NU IN VECHIUL BAZIN: cele patru teste din R2c, toate pe
## terenul de azi.
##   (a) LIBER DE DRUM: 7,5-12 m de la marginea carosabilului. E mai putin
##       decat cei 17-37 m de pe raft, dar e pe VERTICALA 11-12 m mai jos, si
##       chiar asta e rostul POI-ului: „cel mai jos punct al turului".
##   (b) VIZIBIL: `ProbeMpFSeen --frac=0.705 --y=-36` da celulele neocluzate
##       fix pe z = -120, x = -200..-160. Nu e o zona larga — e o FANTA, si o
##       fanta e ce vezi cand treci pe buza unei gorje.
##   (c) ARIE PE ECRAN: e la 10-25 m de camera, nu la 60-100 ca troaca din R2b.
##       Un metru de apa la 15 m subintinde de patru ori cat la 60.
##   (d) PANTA REALA: 2,6 m pe 54 m, masurata mai sus.
##
## CE AM PASTRAT DIN RUNDA 9 (memoria `revenirea-e-o-mutare-valida`): runda 26
## e mai slaba decat runda 9 — in F_r9_0.67.png se vede apa turcoaz, un camp de
## bolovani si mal ocru; in F_r26 raman pete gri cu stropi albi. Deci punctul de
## plecare e MECANISMUL rundei 9 (luciu vizibil + bolovani in albie + spuma din
## pietre), nu reglajele de „mai putin alb" care au urmat.
const CH_A := Vector2(-155.0, -117.0)
const CH_B := Vector2(-212.0, -117.5)
const CH_OFF := 0.0
## Semi-latimea albiei. Fundul plat tine pe z = -112..-120 la x = -180
## (TRV x=-180: -120:-39.3 ... -112:-40.0, peretele sare la -20,9 pe z=-111),
## deci ~8 m de fund. Semi-latimea e 4,2 m, nu 12: gorja e o crapatura, nu un
## raft. Apa care ar trece de ea urca pe taluzul de 45 de grade si redevine
## „autocolant pe iarba", exact defectul reclamat.
const CH_HALF := 4.2
const CH_WET := 57.0

## BAZINELE: [t_start, t_end, y_luciu]. Fundul MASURAT pe fir (z ~ -188):
##   x     -250   -240   -234   -228   -222   -216   -210   -206
##   sol  -27,9  -27,8  -27,6  -27,5  -28,1  -29,0  -29,7  -30,6
## Deci panta e reala si se accelereaza spre est. Trei bazine cu doua caderi,
## fiecare cadere pusa acolo unde terenul CHIAR se rupe (intre x=-222 si -216,
## si intre x=-212 si -206):
##   bazin 1 (t 0..30, x -250..-220): luciu -27,75
##   bazin 2 (t 30..40, x -220..-210): luciu -28,85
##   bazin 3 (t 40..48, x -210..-202): luciu -30,10
## Caderile sunt de 1,10 si 1,25 m — de trei ori mai mari decat ce incapea pe
## raft, fiindca aici panta e reala, nu inventata.
## RUNDA 2, A DOUA MASURATOARE (si e cea care a scos „autocolantele"). Sonda de
## profil pe fir a aratat ca bazinul 1 la -27,75 statea in ±0,30 m de teren pe
## TOATA lungimea lui: nu e apa, e un FILM, si placile intrau si ieseau din
## pamant de la un metru la altul. Exact asa arata spuma „plutind fara cauza",
## fiindca sub ea nu era luciu continuu.
## Cotele coboara deci cu ~0,55 m fiecare, ca fiecare bazin sa aiba ADANCIME
## masurabila (0,4-0,9 m pe fir), si a treia ramane mai sus decat era ca sa nu
## inunde malul de la t=48 incolo (acolo terenul e deja cu 2,2 m sub ea).
## SI A TREIA MASURATOARE, care a corectat-o pe a doua. Coborate cu 0,55 m,
## bazinele au ajuns SUB terenul vizibil si raul a disparut aproape complet din
## cadru (F_r19_0.67.png: panza cenusie din r18 nu se mai vede deloc).
## Concluzia, si e o constrangere reala a locului, nu o preferinta: luciul
## traieste intr-o FEREASTRA de vreo jumatate de metru. Mai sus de -27,8 e film
## peste iarba; mai jos de -28,4 dispare sub mal. Cotele de mai jos sunt
## mijlocul ferestrei, verificat pe captura in ambele sensuri.
## R3: recalculate pe fundul gorjei. `t` creste de la CH_A (x=-155, amonte,
## est) spre CH_B (x=-212, aval, vest), deci x = -155 - t.
## Fundul MASURAT pe z = -120 (FIR, pas 2 m), convertit in `t`:
##   t     0     10    20    30    40    45    52    57
##   x  -155  -165  -175  -185  -195  -200  -207  -212
##   sol -38,2 -38,8 -39,2 -39,5 -39,9 -40,2 -40,7 -40,9
## Deci 2,7 m de cadere pe 57 m, aproape liniara, cu o accelerare pe ultimii
## 12 m. Trei bazine cu doua praguri, fiecare prag pus unde panta CHIAR se
## rupe (intre t=22 si t=26, si intre t=44 si t=48):
##   bazin 1 (t 0..24)  luciu -38,45   fund -38,2..-39,3  -> adancime 0,0..0,85
##   bazin 2 (t 24..46) luciu -39,35   fund -39,3..-40,0  -> adancime 0,0..0,65
##   bazin 3 (t 46..60) luciu -40,25   fund -40,0..-40,9  -> adancime 0,0..0,65
## Caderile sunt de 0,90 m fiecare. Lectia cotelor din runda 19 ramane in
## picioare si aici: luciul traieste intr-o fereastra ingusta, prea sus e film
## peste iarba, prea jos dispare sub fund. Cotele de mai sus stau cu 0,25-0,35 m
## SUB fundul de la capatul din amonte al fiecarui bazin, ca apa sa aiba
## adancime chiar de la prag, si cu 0,6-0,9 m PESTE fundul de la capatul din
## aval, ca sa nu se reverse peste pragul urmator.
const POOLS := [
	[-8.0, 24.0, -38.45],
	[24.0, 46.0, -39.35],
	[46.0, 62.0, -40.25],
]

var _chan_dir := Vector2.ZERO
var _chan_per := Vector2.ZERO
var _chan_len := 0.0

## Pietrele din ALBIE, retinute ca ancore de spuma: (x, z, raza_efectiva,
## y_luciu). Numai cele care chiar stau in apa — spuma vine din ele.
var _wet_rocks: Array[Vector4] = []
## Placile de luciu deja asezate, ca spuma sa cada pe apa, nu pe pietris.
var _water_pts: Array[Vector2] = []


func _chan_init() -> void:
	_chan_dir = (CH_B - CH_A).normalized()
	_chan_per = Vector2(-_chan_dir.y, _chan_dir.x)
	_chan_len = CH_A.distance_to(CH_B)


## Din (t, o) in lume.
## Inversa: din lume in `t` (proiectia pe firul albiei). Folosita de piesele
## care nu se aseaza in coordonate de albie (piciorul peretelui), ca sa afle
## cota luciului de langa ele.
func _chan_t_of(x: float, z: float) -> float:
	return (Vector2(x, z) - CH_A).dot(_chan_dir)


func _chan_pt(t: float, o: float) -> Vector2:
	return CH_A + _chan_dir * t + _chan_per * (o + CH_OFF)


## Cota luciului la `t`: constanta pe bazin, cu o cadere scurta intre bazine.
## Intre bazine interpoleaza pe 1,6 m de `t` — asta e „buza" pragului, si tot
## ea e locul unde se aseaza banda de spuma.
func _water_y(t: float) -> float:
	for k in POOLS.size():
		var p: Array = POOLS[k]
		var t0: float = float(p[0])
		var t1: float = float(p[1])
		if t < t1 or k == POOLS.size() - 1:
			if k + 1 < POOLS.size() and t > t1 - 1.6:
				var nxt: float = float((POOLS[k + 1] as Array)[2])
				var u: float = clampf((t - (t1 - 1.6)) / 1.6, 0.0, 1.0)
				return lerpf(float(p[2]), nxt, u)
			return float(p[2])
	return float((POOLS[POOLS.size() - 1] as Array)[2])


## Semi-latimea apei la `t`: albia se ingusteaza la praguri (apa se strange ca
## sa cada) si se largeste in bazine. Asta e ce da forma de clepsidra pe care
## ochiul o citeste ca „repezis", si nu o panglica de latime egala.
func _water_half(t: float) -> float:
	var w := CH_HALF
	for k in POOLS.size() - 1:
		var tk: float = float((POOLS[k] as Array)[1])
		var d: float = absf(t - tk)
		if d < 9.0:
			w = minf(w, lerpf(CH_HALF * 0.55, CH_HALF, d / 9.0))
	return w


## LUCIUL: placi plate pe sloturile de apa, asezate in coordonate de albie, la
## cota BAZINULUI, si numai unde terenul real e sub ea.
##
## `snap_to_ground` ramane STINS: apa e un NIVEL, nu o depunere. Pus pe pornit
## ar tara luciul pe fundul albiei si ar disparea sub pietre.
func _river() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var pos_d: PackedVector3Array = []
	var yaw_d: PackedFloat32Array = []
	var tries := 0
	while pos.size() + pos_d.size() < 1500 and tries < 90000:
		tries += 1
		var t := _rng.randf_range(-10.0, CH_WET)
		var half := _water_half(t)
		var o := _rng.randf_range(-half, half)
		var c := _chan_pt(t, o)
		var wy := _water_y(t)
		var g := _sol_real(c.x, c.y)
		# Malul taie apa: acolo unde terenul real urca peste luciu, apa se
		# opreste singura. Cerinta creste spre marginea albiei, ca sa nu se
		# vada muchia de caseta (lectia rundei 2 de anul trecut).
		# Cerinta de adancime creste spre MAL: in mijloc ajunge 0,05 m, pe
		# ultimii doi metri de albie cere 0,45 m. Fara asta conturul apei se
		# termina cu muchia casetei si placile ies pe iarba — si o placa de apa
		# pe iarba e chiar „autocolantul" reclamat.
		# RUNDA 2, masuratoare de CONTINUITATE. Componenta conexa cea mai mare
		# a apei era doar 36 % din pixelii de apa din banda: raul iesea in
		# cinci bucati separate de iarba, si cinci balti nu citesc ca un rau.
		# Cauza: cerinta de adancime respingea placile oriunde fundul se umfla
		# cu cativa centimetri. In mijlocul albiei se cere deci doar ca
		# terenul sa fie SUB luciu (0,02 m), si numai ultimii doi metri de mal
		# pastreaza pragul mare, ca apa sa nu urce pe iarba.
		var m: float = 1.0 - clampf(absf(o) / half, 0.0, 1.0)
		var need: float = lerpf(0.40, 0.02, clampf(m / 0.22, 0.0, 1.0))
		if g > wy - need:
			continue
		if _dist_to_road(c.x, c.y) < 3.0:
			continue
		# Apa nu trece de buza raftului: dincolo de ea terenul cade in gol.
		if g < wy - 4.0:
			continue
		var adanc := wy - g
		if adanc > 0.75:
			pos_d.append(Vector3(c.x, wy, c.y))
			yaw_d.append(_rng.randf_range(0.0, TAU))
		else:
			pos.append(Vector3(c.x, wy, c.y))
			yaw.append(_rng.randf_range(0.0, TAU))
		_water_pts.append(Vector2(c.x, c.y))
	if pos.is_empty() and pos_d.is_empty():
		print("; ATENTIE: albia e goala — luciul e sub tot terenul")
		return
	# R3, DOUA INCERCARI, SI A DOUA E CEA MASURATA.
	#
	# (i) Prima: apa mica de pe `ASPHALT_EDGE` (6) pe `REEF_SHALLOW` (17).
	#     Motivul parea solid — slotul 6 e „margini tocite" de SOSEA, adica un
	#     gri de asfalt, si in G2_r1_0.70.png mijlocul albiei chiar iesea banda
	#     cenusie (memoria `apa-iluminata-v12`: pata gri = panza opaca).
	# (ii) Dar 17/18 sunt perechea de RECIF de la Okinawa, si masurata pe
	#     captura da fix defectul opus (memoria `apa-stilizata-de-noapte`:
	#     conteaza SATURATIA, nu luminanta):
	#
	#       apa din BARA   rgb(125,116,110)  H  24  S 0,12  V 0,49
	#       apa NOASTRA    rgb( 46,142,140)  H 179  S 0,68  V 0,56
	#
	#     Saturatie de aproape SASE ori peste referinta: lagune tropicale intr-un
	#     rau andin. Valoarea era, de altfel, deja buna (0,56 fata de 0,49) —
	#     deci ce trebuia schimbat era exact saturatia.
	#
	# (iii) A TREIA masuratoare, si aici se opreste. Cu 8 CONCRETE pe apa mica
	#     saturatia a aterizat exact (0,14 fata de 0,12 pe bara) — dar VALOAREA
	#     a sarit in sus:
	#
	#       apa din BARA        rgb(125,116,110)  H 24  S 0,12  V 0,49
	#       apa NOASTRA (G4)    rgb(175,168,150)  H 43  S 0,14  V 0,68
	#
	#     adica cu 39 % mai deschisa, si in captura chiar asa citea: pietris
	#     palid, nu apa. E memoria `suprafata-palida-e-lumina` — slotul are
	#     V 0,54, dar o suprafata ORIZONTALA sub un soare de 40 de grade plus
	#     expunerea temei urca vizibil in valoare, deci slotul trebuie ales SUB
	#     tinta, nu pe ea (aceeasi lectie pe care generatorul o invatase deja o
	#     data, la pietrisul de mal).
	#
	# CE S-A ALES pana la urma, tot din sloturi existente (zero materiale):
	#     6  ASPHALT_EDGE  ( 79, 79, 85) H 240 S 0,07  V 0,33  <- apa mica
	#     5  ASPHALT       ( 59, 59, 64) H 240 S 0,08  V 0,25  <- ochiuri adanci
	# Amandoua au saturatia in jurul valorii din bara (0,07 si 0,08 fata de
	# 0,12), iar intre ele ramane o diferenta de valoare de 0,08 — apa DESCHISA
	# pe repezisuri si ochiuri INCHISE in bulboane, structura din referinta.
	# Culoarea nu vine din slot; contrastul vine din spuma alba si din pietre,
	# exact ca in bara.
	#
	# Si da, slotul 6 e cel de la care a plecat runda asta, cel numit „pata
	# gri". Diferenta e ca atunci era apa fara pietre si fara spuma pe un
	# platou; acum e fundul unei gorje, cu bolovani calzi in ea si cu alb pe
	# muchii. Un gri inconjurat de piatra si spuma citeste apa; acelasi gri
	# singur pe iarba citeste asfalt. Slotul n-a fost niciodata problema.
	if not pos.is_empty():
		_disc_flock("F_Luciu", Palette.ASPHALT_EDGE, 5.5, 0.85, 1.35, pos,
			yaw, 77001)
	if not pos_d.is_empty():
		_disc_flock("F_LuciuAdanc", Palette.ASPHALT, 4.5, 0.8, 1.2, pos_d,
			yaw_d, 77002)
	print("; luciu: %d placi mici-adancime + %d in ochiuri, din %d incercari"
		% [pos.size(), pos_d.size(), tries])


## PIETRISUL UD: placi plate pe slotul 4 ROCK_DARK (#67421F, rgb 103/66/31,
## H 29, S 0,70, V 0,40) pe MALURILE albiei, adica in banda dintre marginea
## apei si iarba.
##
## Slotul s-a ales pe doua masuratori, nu din prima. Cu slotul 2 SAND_SHADOW
## (V 0,57) zona de rau a iesit H 56 / S 0,39 / V 0,63 fata de H 40 / S 0,28 /
## V 0,50 pe bara: directia era buna (verdele disparuse, albul coborase de la
## 23,2 % la 4,9 %) dar bancul citea PORTOCALIU aprins. Orice suprafata
## orizontala pe soarele de 40 de grade plus expunerea 1,05 se ridica in
## valoare, deci slotul trebuie ales SUB tinta, nu pe ea.
## (Memoria `rock-dark-nu-pe-bazalt` spune ca slotul asta face rugina pe roca
## vulcanica — aici rugina e chiar ce vrem: pietris de rau ud.)
##
## RUNDA 2: pietrisul se aseaza tot in coordonate de albie, pe o banda de la
## marginea apei spre exterior. Inainte umplea un dreptunghi si iesea un CAMP
## ocru cat toata valea, in care albia se pierdea; criticul l-a si numit
## („campul de pietris ocru"). O prundisul de rau e o fasie pe langa apa.
func _gravel() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	var tries := 0
	var got := 0
	while got < 70 and tries < 40000:
		tries += 1
		var t := _rng.randf_range(-12.0, CH_WET + 8.0)
		var half := _water_half(t)
		var sgn: float = 1.0 if _rng.randf() < 0.5 else -1.0
		var o := sgn * _rng.randf_range(half * 0.95, half + 1.6)
		var c := _chan_pt(t, o)
		var wy := _water_y(t)
		var g := _sol_real(c.x, c.y)
		# Banda de prundis: de la putin sub linia apei pana la 1,8 m peste ea.
		if g < wy - 0.3 or g > wy + 1.0:
			continue
		if _dist_to_road(c.x, c.y) < 3.0:
			continue
		# Ridicata peste vecini, ca placa plata sa nu intre in panta.
		var rr := 4.0
		var lo := g
		for da: float in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
			lo = minf(lo, _sol_real(c.x + cos(da) * rr, c.y + sin(da) * rr))
		var lift: float = clampf(g - lo, 0.0, 1.6) + 0.10
		pos.append(Vector3(c.x, g + lift, c.y))
		yaw.append(_rng.randf_range(0.0, TAU))
		sc3.append(Vector3(_rng.randf_range(0.7, 1.4), 1.0,
			_rng.randf_range(0.7, 1.4)))
		got += 1
	if pos.is_empty():
		print("; ATENTIE: pietris gol")
		return
	# Placi de 2,4 m, nu de 4: la 20-40 m de camera o placa de 4 m e o dala
	# ocru cat un sfert de ecran. MASURAT pe captura rundei precedente:
	# pietrisul iesise 18,3 % din cadru, fata de 1,7 % pe bara — de zece ori.
	# Prundisul nu e peisajul, e chenarul apei.
	_disc_flock("F_Pietris", Palette.ROCK_DARK, 1.8, 1.0, 1.0, pos, yaw,
		77005, sc3)
	print("; pietris de mal: %d placi" % pos.size())


## BOLOVANII DIN ALBIE — reparatia principala a rundei 2.
##
## Criticul: „bolovani mari semi-scufundati in albie, calare pe linia de apa".
## Deci nu se mai esantioneaza un dreptunghi si nu se mai filtreaza dupa cota
## terenului: pietrele se aseaza PE FIRUL APEI, in coordonate de albie, si
## inaltimea lor se alege astfel incat sa iasa din luciu cu o fractiune
## MASURATA din corp. O piatra care iese 0,35-0,9 m din apa la 40-70 m de ochi
## e exact silueta din bara.
##
## TREI FAMILII, si impartirea e ce face repezisul sa aiba structura:
##   - `prag`: pietrele de pe buza fiecarui prag, dese si aliniate transversal.
##     Ele sunt cauza caderii; fara ele treapta pare o taietura in apa.
##   - `fir`: bolovani mari, raspanditi pe mijlocul curentului. Fiecare isi
##     capata dara lui in aval si dunga lui in amonte.
##   - `mal`: piatra marunta pe marginea apei, care leaga albia de prundis.
##
## COLIZIUNEA: niciuna. MultiMesh nu produce corp fizic, si asta e corect aici —
## totul e sub plasa de repunere; un corp acolo ar fi doar ceva de care sa se
## agate masina care oricum va fi repusa.
func _river_rocks() -> void:
	var lots := {
		"moss_boulder_b": {"pos": PackedVector3Array(), "yaw": PackedFloat32Array(), "sc": [] as Array[Vector3]},
		"moss_boulder_c": {"pos": PackedVector3Array(), "yaw": PackedFloat32Array(), "sc": [] as Array[Vector3]},
		"moss_boulder_a": {"pos": PackedVector3Array(), "yaw": PackedFloat32Array(), "sc": [] as Array[Vector3]},
	}

	# --- (1) PIETRELE DE PRAG: cauza fiecarei caderi.
	# Pe buza fiecarui prag, un sir transversal de bolovani mari, semi-scufundati
	# in apa DE SUS. Din ei iese banda alba de pe muchie.
	var praguri: Array[float] = []
	for k in POOLS.size() - 1:
		praguri.append(float((POOLS[k] as Array)[1]))
	for tk in praguri:
		var half := _water_half(tk)
		var o := -half
		while o <= half:
			var jitter := _rng.randf_range(-1.1, 1.1)
			var c := _chan_pt(tk + jitter, o + _rng.randf_range(-0.7, 0.7))
			var wy_sus := _water_y(tk - 2.0)
			var g := _sol_real(c.x, c.y)
			if g > wy_sus + 1.3 or g < wy_sus - 3.5 or _dist_to_road(c.x, c.y) < 3.0:
				o += _rng.randf_range(1.9, 3.1)
				continue
			var mdl := "moss_boulder_b" if _rng.randf() < 0.6 else "moss_boulder_a"
			# Iese din apa 0,45-0,95 m: o treapta trebuie sa aiba piatra
			# VIZIBILA pe ea, altfel muchia alba n-are de ce sa se sparga.
			var iesire := _rng.randf_range(0.45, 0.95)
			var sc: float = clampf((iesire + (wy_sus - g)) / HEIGHT[mdl], 0.30, 1.30)
			(lots[mdl]["pos"] as PackedVector3Array).append(Vector3(c.x, g, c.y))
			(lots[mdl]["yaw"] as PackedFloat32Array).append(_rng.randf_range(0.0, TAU))
			(lots[mdl]["sc"] as Array[Vector3]).append(Vector3(
				sc * _rng.randf_range(1.0, 1.25), sc * 0.78,
				sc * _rng.randf_range(1.0, 1.25)))
			_wet_rocks.append(Vector4(c.x, c.y,
				BASE_R.get(mdl, 0.6) * sc, wy_sus))
			o += _rng.randf_range(1.9, 3.1)

	var n_prag := _wet_rocks.size()

	# --- (2) BOLOVANII DE FIR: mari, in mijlocul curentului, calare pe luciu.
	var tries := 0
	var fir := 0
	while fir < 210 and tries < 40000:
		tries += 1
		var t := _rng.randf_range(-8.0, CH_WET)
		var half := _water_half(t)
		var o := _rng.randf_range(-half * 0.92, half * 0.92)
		var c := _chan_pt(t, o)
		var wy := _water_y(t)
		var g := _sol_real(c.x, c.y)
		# CALARE PE LINIA DE APA. Pragul rundei precedente (`g > wy + 0.05`)
		# a scos 90 % din candidati si a lasat 17 bolovani de fir din 150:
		# masurat, fundul albiei e la doar 0,1-0,7 m sub luciu, deci un test
		# care cere teren STRICT sub apa cade pe zgomotul terenului. Fereastra
		# corecta e „fundul e in albie", adica de la 3 m sub luciu pana la
		# 0,45 m peste el — o piatra pe un prag submers iese si ea din apa, si
		# aia e chiar silueta din bara.
		if g > wy + 0.35 or g < wy - 2.6:
			continue
		if _dist_to_road(c.x, c.y) < 3.0:
			continue
		# Prea aproape de alta piatra mare -> se face gramada, nu repezis.
		var prea := false
		for w in _wet_rocks:
			if Vector2(w.x - c.x, w.y - c.y).length() < 2.4:
				prea = true
				break
		if prea:
			continue
		var mdl := "moss_boulder_b"
		var rz := _rng.randf()
		if rz < 0.30:
			mdl = "moss_boulder_a"
		elif rz > 0.86:
			mdl = "moss_boulder_c"
		# Iese din apa 0,4-1,0 m — cele mai mari pietre din bara au 2-3 m
		# latime, majoritatea sub 1,5, si ies din apa cam o treime.
		var iesire := _rng.randf_range(0.40, 1.00)
		var sc: float = clampf((iesire + (wy - g)) / HEIGHT[mdl], 0.30, 1.35)
		(lots[mdl]["pos"] as PackedVector3Array).append(Vector3(c.x, g, c.y))
		(lots[mdl]["yaw"] as PackedFloat32Array).append(_rng.randf_range(0.0, TAU))
		(lots[mdl]["sc"] as Array[Vector3]).append(Vector3(
			sc * _rng.randf_range(1.0, 1.2), sc * 0.75,
			sc * _rng.randf_range(1.0, 1.2)))
		_wet_rocks.append(Vector4(c.x, c.y, BASE_R.get(mdl, 0.6) * sc, wy))
		fir += 1

	# --- (3) PIATRA DE MAL: marunta, pe muchia apei, ca albia sa nu se termine
	# intr-o linie dreapta intre luciu si prundis.
	var tries2 := 0
	var mal := 0
	while mal < 320 and tries2 < 30000:
		tries2 += 1
		var t := _rng.randf_range(-12.0, CH_WET + 8.0)
		var half := _water_half(t)
		var sgn: float = 1.0 if _rng.randf() < 0.5 else -1.0
		var o := sgn * _rng.randf_range(half * 0.8, half + 5.0)
		var c := _chan_pt(t, o)
		var wy := _water_y(t)
		var g := _sol_real(c.x, c.y)
		if g < wy - 1.2 or g > wy + 1.4:
			continue
		if _dist_to_road(c.x, c.y) < 3.0:
			continue
		var mdl := "moss_boulder_a" if _rng.randf() < 0.75 else "moss_boulder_c"
		var sc: float = _rng.randf_range(0.30, 0.75)
		(lots[mdl]["pos"] as PackedVector3Array).append(
			Vector3(c.x, g - HEIGHT[mdl] * sc * 0.20, c.y))
		(lots[mdl]["yaw"] as PackedFloat32Array).append(_rng.randf_range(0.0, TAU))
		(lots[mdl]["sc"] as Array[Vector3]).append(Vector3(
			sc * _rng.randf_range(1.0, 1.15), sc * 0.72,
			sc * _rng.randf_range(1.0, 1.15)))
		# Pietrele de mal care ating apa intra ca ancore, dar MARCATE: raza se
		# trece cu semn negativ. Ele primesc doar dunga din amonte, nu si siaj
		# — o piatra de 40 cm de pe mal nu lasa dara de sase metri, si in
		# F_r25 exact darele astea faceau albia sa para pieptanata cu linii
		# paralele care nu ies din nimic vizibil.
		if g < wy + 0.25:
			_wet_rocks.append(Vector4(c.x, c.y, -BASE_R.get(mdl, 0.6) * sc, wy))
		mal += 1

	for mdl: String in lots.keys():
		var d: Dictionary = lots[mdl]
		var pos: PackedVector3Array = d["pos"]
		if pos.is_empty():
			continue
		_flock_seed += 1
		# CLASA DE PIATRA, nu atlasul. `moss_boulder_*` are 12-39 % din
		# vertecsi pe slotul 12 CACTUS_GREEN (masuratori §2), adica muschi — si
		# in captura rundei 2 exact muschiul a facut din albie un camp de varza
		# verde. Un material de clasa inlocuieste tot nodul, deci scoate
		# muschiul din ecuatie.
		#
		# CARE clasa: masurat pe captura, nu ales din lista. `inca_stone` are
		# tenta (1.0, 0.831, 0.677), granit CALD, si albia iesea un camp de
		# pietricele bej: plaja, nu repezis. `granite` are (0.520, 0.578,
		# 0.700), cenusiu-rece si mai inchis — exact piatra uda din bara.
		#
		# R3, SI AICI JUSTIFICAREA DIN COMENTARIU S-A VERIFICAT (memoria
		# `justificarea-din-comentariu-se-verifica`). „Cenusiu-rece" nu descrie
		# tenta `granite`: (0.520, 0.578, 0.700) are B cu 0,18 peste R, adica
		# e ALBASTRA, nu neutra. Si se vede pe captura, masurat pe G2_r1_0.70:
		#
		#   piatra din BARA  rgb(121,113,109)  H 21   S 0,10  V 0,47  R-B = +11
		#   bolovanii NOSTRI rgb( 56, 64, 83)  H 221  S 0,33  V 0,32  R-B = -27
		#
		# Adica nuanta e de partea cealalta a rotii (21 fata de 221), saturatia
		# de trei ori mai mare, si valoarea cu o treime mai mica: bolovani de
		# plastic albastru intr-un rau de munte.
		#
		# De ce tenta aia e totusi corecta la ea acasa: e derivata pe Serengeti
		# ca INVERS al soarelui cald de acolo (1.0, 0.90, 0.72), deci e o
		# corectie de iluminare, nu o culoare de piatra. Machu Picchu are alt
		# soare si alt ambiental, deci corectia se aplica pe o lumina care nu
		# mai e acolo si ramane vizibila ca albastru. E chiar memoria
		# `slot-reutilizat-intre-piste`, in varianta ei de CLASA.
		#
		# Se trece pe `inca_stone` (1.0, 0.831, 0.677): calda, cum e si piatra
		# din bara (R-B = +11). Obiectia veche — „ies pietricele bej, plaja" —
		# era despre VALOARE, nu despre nuanta, si se repara unde trebuie: cu
		# pietre mai putine si mai mari, si cu apa inchisa intre ele. Zero
		# materiale in plus: `inca_stone` e deja in cele 20 (zidaria incasa).
		_model_flock("F_Pietre_%s" % mdl, RES[mdl], pos, d["yaw"], d["sc"],
			77200 + _flock_seed, "inca_stone")
		print("; pietre %s: %d" % [mdl, pos.size()])
	print("; %d pietre UDE (ancore de spuma), din care %d de prag si %d de fir"
		% [_wet_rocks.size(), n_prag, fir])


## SPUMA — a doua reparatie a rundei 2, si cea pe care criticul a numit-o
## „defectul de ordin zero".
##
## Verdictul, cuvant cu cuvant: „spuma nu are cauza si citeste ca autocolante pe
## plastic". Avea dreptate: 91 % din ancore erau aruncate (`randf() > 0.09`),
## iar cea mai mare parte a albului era un covor imprastiat uniform pe luciu.
##
## Acum FIECARE placa alba iese dintr-o interactie, si sunt trei, toate cerute
## explicit de critic:
##   (a) DUNGA DIN AMONTE: o banda scurta, transversala pe curent, lipita de
##       fata din amonte a fiecarei pietre. Acolo apa loveste piatra si se
##       ridica alba. Fara ea piatra pare pusa pe apa; cu ea, apa pare ca da
##       peste piatra.
##   (b) SIAJUL CONIC DIN AVAL: 3-7 placi care pleaca din spatele pietrei si se
##       largesc si se sting cu distanta. Asta e semnul de curgere.
##   (c) BANDA DE PE MUCHIA FIECARUI PRAG: continua, transversala, pe toata
##       latimea apei. E singurul alb care are voie sa fie compact.
##
## Nu mai exista covor pe luciu. Daca dupa runda asta albia pare prea intunecata
## intre pietre, raspunsul e MAI MULTE PIETRE, nu mai mult alb liber —
## repezisul din bara are apa inchisa intre benzile albe, si fara apa inchisa nu
## e repezis, e zapada.
##
## TOATE formele albe sunt orientate pe CURENT (yaw-ul albiei), cum a cerut
## criticul: „toate formele albe orientate in sensul curgerii".
##
## Cantitatea ramane sub control: pe bara, pixelii aproape-albi (min(R,G,B) >
## 215) sunt 0,8 % din cadru si 1,5 % pe banda de apa; runda 1 ajunsese la
## 23,2 % si apoi s-a taiat la ~5 %. Structura de acum e insa ALTA — albul sta
## strans langa pietre si pe muchii, deci se citeste mult mai tare la acelasi
## procent. Cine il urca inapoi trebuie sa remasoare, nu sa se uite la
## miniatura.
func _foam() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	# CURENTUL curge de la CH_A spre CH_B (spre SV, in aval). Yaw-ul unei placi
	# aliniate pe curent: directia albiei in plan XZ.
	var flow_yaw := atan2(_chan_dir.x, _chan_dir.y)
	var amonte := 0
	var siaj := 0

	for r in _wet_rocks:
		var rx := r.x
		var rz := r.y
		# Semnul razei spune de unde vine ancora: pozitiv = piatra din albie
		# (prag sau fir), negativ = piatra de mal. Numai cele din albie fac
		# siaj.
		var in_albie: bool = float(r.z) > 0.0
		var rad: float = maxf(absf(float(r.z)), 0.45)
		var wy: float = r.w
		# --- (a) dunga din AMONTE: transversala, lipita de piatra.
		var up := _chan_pt(0.0, 0.0)
		var ux := rx - _chan_dir.x * (rad + 0.35)
		var uz := rz - _chan_dir.y * (rad + 0.35)
		if _sol_real(ux, uz) < wy - 0.03 and _dist_to_road(ux, uz) >= 3.0:
			pos.append(Vector3(ux, wy + 0.13, uz))
			yaw.append(flow_yaw + _rng.randf_range(-0.12, 0.12))
			# Lata pe transversala (Z local), scurta pe curent (X local).
			sc3.append(Vector3(_rng.randf_range(0.30, 0.45), 1.0,
				rad * _rng.randf_range(1.5, 2.1)))
			amonte += 1
		# --- (b) SIAJUL conic din aval. Numai pietrele care chiar sparg apa:
		# o piatra de 40 cm nu lasa siaj de 8 m. Pragul e pe raza, si e ce
		# tine albul jos fara sa-i ia cauza — runda precedenta scosese 1045 de
		# placi (848 numai siaj) si albia iesea ZAPADA, defectul pe care
		# criticul l-a numit deja o data.
		if not in_albie or rad < 0.55:
			continue
		var cnt := _rng.randi_range(3, 6)
		for k in cnt:
			var t := 0.6 + float(k) * _rng.randf_range(0.75, 1.15)
			var lat := _rng.randf_range(-1.0, 1.0) * rad * (0.35 + t * 0.30)
			var px := rx + _chan_dir.x * (rad + t * 1.25) + _chan_per.x * lat
			var pz := rz + _chan_dir.y * (rad + t * 1.25) + _chan_per.y * lat
			if _sol_real(px, pz) > wy - 0.03 or _dist_to_road(px, pz) < 3.0:
				continue
			# Se stinge: placile de departe sunt mai mici si mai subtiri.
			var fade: float = clampf(1.0 - t * 0.16, 0.25, 1.0)
			pos.append(Vector3(px, wy + 0.11, pz))
			# Imprastiere mai mare pe yaw: siajul unei pietre se desface, nu
			# merge paralel cu al vecinei. Cu +-0,22 rad toate darele ieseau
			# pe aceeasi directie si albia citea „pieptanata".
			yaw.append(flow_yaw + _rng.randf_range(-0.55, 0.55))
			sc3.append(Vector3(_rng.randf_range(0.9, 1.5) * fade, 1.0,
				_rng.randf_range(0.28, 0.48) * fade))
			siaj += 1

	# --- (c) BANDA DE PE MUCHIA PRAGURILOR: continua, pe toata latimea.
	var casc := 0
	for k in POOLS.size() - 1:
		var tk: float = float((POOLS[k] as Array)[1])
		var half := _water_half(tk)
		var o := -half
		while o <= half:
			# Doua-trei randuri de placi pe muchie, ca banda sa fie SOLIDA:
			# criticul a cerut „banda alba solida pe muchie", si e singurul
			# alb compact din albie.
			for row: float in [-0.7, 0.0, 0.7, 1.5]:
				var c := _chan_pt(tk + row + _rng.randf_range(-0.25, 0.25),
					o + _rng.randf_range(-0.35, 0.35))
				var wy2 := _water_y(tk - 1.0)
				var g := _sol_real(c.x, c.y)
				# Aceeasi lectie ca la pietre: fundul e la o palma sub luciu,
				# deci un prag pe cota nu are voie sa fie strans. Se cere doar
				# sa nu fim deja pe mal uscat.
				if g > wy2 + 1.2 or _dist_to_road(c.x, c.y) < 3.0:
					continue
				pos.append(Vector3(c.x, minf(wy2, g + 0.9) + 0.16, c.y))
				yaw.append(flow_yaw + _rng.randf_range(-0.10, 0.10))
				sc3.append(Vector3(_rng.randf_range(0.34, 0.52), 1.0,
					_rng.randf_range(1.5, 2.3)))
				casc += 1
			o += _rng.randf_range(1.1, 1.8)

	if pos.is_empty():
		print("; ATENTIE: spuma goala")
		return
	# CAT ALB, SI CUM S-A MASURAT — fiindca prima masuratoare a fost gresita
	# si a trimis reglajul in directia opusa.
	#
	# Pe TOT cadrul, pixelii aproape-albi (min(R,G,B) > 215) dau 6,6 % la noi
	# si 0,82 % pe bara, si concluzia „de opt ori prea mult" pare evidenta.
	# E falsa: harta pe celule a albului arata ca la noi albul st in CENTRUL
	# si in JOSUL cadrului (41 % intr-o celula de mijloc), adica pe CAROSABILUL
	# nostru palid — nu in rau. Bara are in acelasi loc un drum ingust si
	# maro, deci compara doua lucruri diferite.
	#
	# Masurat unde trebuie, adica NUMAI in banda raului:
	#     noi  0,59 %      bara  1,69 % si 1,94 % (doua benzi de apa)
	# Adica avem MAI PUTINA spuma decat referinta, nu mai multa. De aia raza
	# ramane 0,85 m si numarul creste — invers decat sugera cifra pe cadru.
	# (Memoria `caseta-de-masura-exclude-defectul`, in varianta ei inversa:
	# caseta prea LARGA a inclus un obiect strain si a mintit la fel de bine.)
	_disc_flock("F_Spuma", Palette.FOAM_WHITE, 0.85, 0.45, 1.0, pos, yaw,
		77003, sc3)
	print("; spuma: %d placi (%d amonte + %d siaj + %d muchii de prag)"
		% [pos.size(), amonte, siaj, casc])


## PERETELE DE STANCA AL GORJULUI — nota secundara a criticului: „ne lipseste
## peretele de stanca al canionului, care in referinta da spate si scara
## verticala; la noi scena se termina intr-o panta verde plata topita in ceata".
##
## Nu se modeleaza un perete nou (n-avem piesa si n-ar incapea in materiale).
##
## R3: peretele NU MAI TREBUIE INVENTAT. Cornisa noua l-a adus: pe z = -110
## terenul sare de la -40 (fundul gorjei) la -20..-22, adica 18-20 m de perete
## vertical la 6-8 m de firul apei. Masurat, TRV x=-180:
##     z=-112:-40,0   z=-111:-20,9   z=-110:-21,2
##
## Deci functia isi schimba rostul: nu mai construieste un mal, ci IMBRACA
## PICIORUL peretelui real — banda de la baza lui, unde stanca intra in apa.
## Fara ea peretele se termina intr-o muchie geometrica curata si citeste a
## taietura de teren; cu bolovani la baza, citeste a stanca spalata de rau, si
## e chiar silueta din bara (repezisuri printre bolovani la baza unui perete).
##
## Cautarea merge pe fiecare coloana x dinspre albie spre z MAI MARE (spre
## nord, spre perete) si se opreste la primul punct care URCA peste -32, adica
## la piciorul peretelui.
##
## Costul: zero materiale (aceeasi clasa `granite` ca pietrele din albie).
func _canyon_wall() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	var x := -214.0
	while x <= -152.0:
		# R3, A TREIA masuratoare — si prima care a prins ce cauta.
		# Versiunea a doua lua `zr` = primul punct care URCA peste -32, adica
		# deja pe perete, si abia apoi cerea o cota apropiata de luciu: cele
		# doua conditii se bat cap in cap, si au iesit 2 bolovani din 24 de
		# coloane. Peretele nu are trepte (TRV x=-180: -40,0 la z=-112, -20,9
		# la z=-111), deci „piciorul" nu e o cota, e ULTIMUL punct de podea
		# dinainte de saritura. Se merge deci spre nord si se retine ultimul z
		# cu podea (sub -34), nu primul z cu perete.
		var z := -124.0
		var gasit := false
		var zr := 0.0
		while z < -105.0:
			z += 0.6
			if _sol_real(x, z) < -34.0:
				zr = z
				gasit = true
			elif gasit:
				break
		if not gasit:
			x += 2.6
			continue
		# Doua randuri la PICIORUL peretelui: unul pe muchie, unul cu un metru
		# inapoi in albie, ca poalele sa aiba grosime si sa nu fie un gard.
		# `dz` negativ = inapoi spre apa (z mai mic), fiindca peretele e la z
		# MAI MARE decat firul.
		# R3, a doua masuratoare: prima versiune cerea `-41,5 < g2 < -34` si a
		# dat 6 bolovani din ~24 de coloane. Motivul, masurat pe TRV x=-180:
		# peretele NU are banda de -34, sare direct de la -40,0 (z=-112) la
		# -20,9 (z=-111). Un filtru pe o cota intermediara respinge tot, fiindca
		# cota intermediara nu exista — memoria `scara-de-adancime-are-gol` in
		# varianta ei mica. Fereastra corecta se ia fata de LUCIU: bolovanii
		# stau de la 0,4 m sub apa pana la 2,6 m peste ea, adica exact poalele
		# spalate, si de-acolo in sus incepe stanca goala.
		for dz: float in [0.0, -1.8, -3.6]:
			var zz := zr + dz + _rng.randf_range(-0.6, 0.6)
			var xx := x + _rng.randf_range(-1.2, 1.2)
			var g2 := _sol_real(xx, zz)
			# Podeaua gorjei, fereastra larga: intre -43 si -35. Peretele insusi
			# (peste -34) si podeaua rapei deschise (sub -43) raman afara.
			if g2 < -43.0 or g2 > -35.0 or _dist_to_road(xx, zz) < 3.0:
				continue
			# R3: 1,6-3,4 m, nu 2,5-5,5. Piciorul peretelui e la 12-25 m de
			# ochi (nu la 50-80 ca vechea rama), deci bolovanii de 5 m ar fi
			# blocuri cat masina si ar inchide fanta prin care se vede apa.
			var meters := _rng.randf_range(1.6, 3.4)
			var sc: float = meters / HEIGHT["moss_boulder_b"]
			pos.append(Vector3(xx, g2 - HEIGHT["moss_boulder_b"] * sc * 0.16, zz))
			yaw.append(_rng.randf_range(0.0, TAU))
			sc3.append(Vector3(sc * _rng.randf_range(1.0, 1.4), sc,
				sc * _rng.randf_range(1.0, 1.4)))
		x += 2.6
	if pos.is_empty():
		print("; ATENTIE: piciorul peretelui e gol")
		return
	# R4: piciorul peretelui e UD, deci e cea mai INCHISA piatra din cadru —
	# `cut_stone`, nu `inca_stone`. In bara, contrastul cel mai puternic e
	# exact perechea spuma alba / roca uda inchisa, iar cu bolovanii calzi
	# (rgb 181,141,100) poalele peretelui citeau nisip, nu stanca spalata.
	# Aceeasi dala `alpine_granite.png`, deci zero textura noua.
	_flock_seed += 1
	_model_flock("F_PereteCanion", RES["moss_boulder_b"], pos, yaw, sc3,
		77400 + _flock_seed, "cut_stone")
	print("; picior de perete: %d bolovani la baza peretelui de gorja" % pos.size())


func _banks() -> void:
	# RUNDA 2: malurile urmaresc ALBIA, nu doua dreptunghiuri. Cautarea merge
	# de-a lungul firului (`t`) si iese PERPENDICULAR (`o`) pana gaseste cota
	# ceruta peste luciu — asta urmareste conturul real al malului, oricat de
	# oblic ar fi, si e singurul mod de a imbraca un canal diagonal.
	#
	# Se pastreaza ideea care a mers in runda 1: nu un inel de cota, ci TREI
	# ferestre suprapuse pe fiecare mal (tufa la apa, feriga peste ea, copac in
	# spate). Cu o singura fereastra, un mal lin satisface conditia pe zeci de
	# metri si toate piesele cad pe acelasi inel subtire.
	for spec: Array in [
			# [spre_dreapta?, model, h_min, h_max, pas, prob, y_min, y_max]
			# MALUL DINSPRE CAMERA E RAR — si asta e o decizie de compozitie,
			# masurata pe captura. La densitatea malului opus (prob 0,8-0,9,
			# pas 3-4 m), ferigile si bambusul de pe malul apropiat au ajuns
			# un PARAVAN verde intre ochi si apa: in F_r22_0.67.png raul se
			# mai vedea doar pe sfertul de sus al benzii lui. Apa e subiectul
			# POI-ului F; vegetatia care o acopera lucreaza impotriva lui.
			# Raman tufe joase si rare, ca malul sa nu fie chel, dar fara
			# coroane care sa taie linia apei.
			[true, "bamboo_clump", 2.6, 3.6, 8.0, 0.30, 0.0, 0.8],
			[true, "tree_fern", 1.8, 2.6, 11.0, 0.25, 0.4, 1.6],
			[false, "bamboo_clump", 3.5, 5.8, 3.2, 0.88, 0.0, 0.8],
			[false, "bamboo_clump", 3.2, 5.2, 3.8, 0.82, 1.0, 2.2],
			[false, "tree_fern", 2.4, 3.8, 4.5, 0.75, 0.4, 1.6],
			[false, "tree_fern", 2.2, 3.4, 5.5, 0.65, 2.0, 3.6],
			[false, "polylepis_a", 3.4, 5.2, 6.5, 0.70, 2.5, 5.0],
			[false, "polylepis_b", 5.5, 8.0, 9.0, 0.65, 3.5, 8.0],
		]:
		var spre_dr: bool = bool(spec[0])
		var mdl: String = String(spec[1])
		var pos: PackedVector3Array = []
		var yaw: PackedFloat32Array = []
		var sc3: Array[Vector3] = []
		var t := -12.0
		while t < _chan_len + 16.0:
			t += float(spec[4]) + _rng.randf_range(-1.2, 1.2)
			if _rng.randf() > float(spec[5]):
				continue
			var half := _water_half(t)
			var wy := _water_y(t)
			var dir_o: float = 1.0 if spre_dr else -1.0
			var want := _rng.randf_range(float(spec[6]), float(spec[7]))
			var o := half * 0.7
			var hit := false
			for _i in 90:
				o += 0.8
				if o > half + 42.0:
					break
				var c := _chan_pt(t, dir_o * o)
				var gg := _sol_real(c.x, c.y)
				# Buza raftului cade in gol: dincolo de ea nu creste nimic.
				if gg < wy - 4.0:
					break
				if gg - wy >= want:
					hit = true
					break
			if not hit:
				continue
			# Jitter lateral, ca sirul sa nu fie o linie trasa cu rigla.
			o += _rng.randf_range(-1.6, 2.4)
			var c2 := _chan_pt(t, dir_o * o)
			var g := _sol_real(c2.x, c2.y)
			if g < wy - 0.2:
				continue
			# NU IN DRUM. Loturile de MultiMesh nu trec prin `_place`, deci
			# n-aveau niciun test de carosabil — si cautarea pe cota, care
			# merge dinspre albie SPRE mal, urca fix pe umarul soselei cand
			# malul e chiar sub ea. In F_r8_0.67.png asta s-a vazut ca o
			# feriga si un bambus in mijlocul benzii palide. Marja e 3 m de la
			# marginea acostamentului REAL.
			if _dist_to_road(c2.x, c2.y) < 3.0:
				continue
			var h := _rng.randf_range(float(spec[2]), float(spec[3]))
			var sc := _scale_for(mdl, h)
			pos.append(Vector3(c2.x, g, c2.y))
			yaw.append(_rng.randf_range(0.0, TAU))
			sc3.append(Vector3(sc, sc, sc))
		if pos.is_empty():
			continue
		_flock_seed += 1
		# Numele poarta si indicele inelului: doua specificatii impart acelasi
		# model si acelasi mal, iar doua noduri cu acelasi nume sub acelasi
		# parinte sunt o eroare de .tscn.
		_model_flock("F_Mal_%s_%s%d" % [mdl, "D" if spre_dr else "S",
			_flock_seed], RES[mdl], pos, yaw, sc3, 77300 + _flock_seed)
		print("; mal %s (%s): %d piese" % [mdl,
			"dreapta" if spre_dr else "stanga", pos.size()])


## BUZA MALULUI DE SUB SOSEA: bolovani pe taluzul de 45 de grade, intre drum si
## apa. Rostul lor e legatura vizuala — fara ei carosabilul se termina in iarba
## si apa apare din nimic la 30 m mai jos, adica doua lumi lipite.
##
## Astia sunt NODURI, nu MultiMesh, si au hull: cad in banda de 8-16 m de
## muchie, adica exact unde ajunge o masina scapata — sunt primul lucru care o
## opreste inainte de plasa de repunere. De aia sunt si putini (16) si
## masurati cu `_place`, care striga daca intra in banda.
##
## R3: mutat de pe bratul de dus (0.6555-0.6880) pe bratul de INTORS
## (0.6960-0.7290), fiindca acolo s-a mutat apa. Partea ramane +1: si pe dus si
## pe intors, gorja e pe partea `side` pozitiva (cornisa `custom_ravines[9]` e
## declarata cu partea +1).
##
## GOLUL: 1,5-4,5 m, nu 5,5-13. Masurat pe G2_r1_0.70.png si verificat in .tscn
## (`FBuza1` la y = -43,19): cu golul vechi piesele cadeau in FUNDUL gorjei, nu
## pe buza ei — la 8-13 m lateral terenul e deja -37..-40 (TRANS 0.710). Acolo
## nu mai sunt „buza malului": sunt bolovani razleti in albie, si pe deasupra
## sunt singurii din zona FARA clasa de piatra, fiindca `_place` emite instante
## de GLB, nu MultiMesh. In captura s-au si vazut asa: pietre PORTOCALII
## (slotul de rugina al GLB-ului) intre bolovanii clasati.
## Albia are acum bolovanii ei, clasati, din `_river_rocks`. Astia se intorc
## deci la meseria lor: sa stea pe MUCHIE, in primii metri de taluz (la 1,5-4,5
## m lateral terenul e -27,8..-29,7, adica inca sus), ca ochiul sa aiba o
## treapta intre carosabil si gol.
## FLANCUL: masa care inchide cadrul lateral, ca MultiMesh.
##
## DE CE EXISTA (masurat pe captura, nu pe impresie — runda 1 a valului 4).
## Criticul valului 3 a spus „raul lipseste cu totul din zona numita malul
## raului". Verificat inainte de a construi: raul NU lipseste. `F_Luciu` are 602
## instante, `F_LuciuAdanc` 898, `F_Spuma` 242 — apa e acolo, cu pozitii reale,
## si la 0.71 se si vede ca fir alb in gorja. Ce lipseste e ALTCEVA, si se
## citeste cand clasifici pixelii pe familii de culoare (r0_*.png fata de
## `bara_poi_F.png`):
##
##   sursa         iarba   piatra   drum
##   BARA           0,7 %   24,0 %  30,6 %
##   noi la 0.67   39,0 %   18,6 %  30,7 %
##   noi la 0.69   10,4 %   17,2 %  42,1 %
##   noi la 0.71   23,9 %   12,6 %  30,0 %
##
## In bara nu exista IZLAZ: tot ce nu e drum e piatra sau vegetatie deasa. La
## noi, 39 % din cadrul de la 0.67 e gazon gol. Impartita pe o grila de 4x4,
## iarba nu e imprastiata, e in BLOCURI: la 0.67 coloana din dreapta da
## 91 / 99,5 / 81 % (exact partea dinspre rau), la 0.71 coloana din stanga da
## 52 / 85 / 85 %. Deci „raul nu se vede" e simptomul; cauza e ca jumatate din
## cadru e o pajiste pe care ochiul n-are ce citi, iar un fir de apa la 30 m
## intr-un izlaz gol nu devine subiect.
##
## `_road_side` punea DOUA randuri pe pas de 4,5 si 8 m, adica ~25 de piese pe
## 300 m de traseu: copaci razleti, nu mal. `_banks` cauta doar pana la
## `half + 42 m` PE PERPENDICULARA ALBIEI, deci nu ajunge niciodata in campul
## din dreapta de la 0.67. Flancul acopera fix golul dintre ele.
##
## CUM (acelasi tipar ca podeaua vaii, `gen_podea_vale.gd`):
## - MultiMesh, nu noduri de scena: la densitatea ceruta ies ~2000 de piese, iar
##   2000 de noduri individuale ar umfla Track15.tscn cu ~8000 de linii
##   (podeaua a ajuns la 25 de minute de incarcare cu 5633).
## - feliat pe fractie in 4 bucati, ca AABB-ul unui MultiMesh sa nu fie cat
##   zona si culling-ul sa ramana util.
## - cota din `_sol_real` (raycast filtrat pe TerrainBody), nu din campul neted.
## - fiecare piesa trece prin `_dist_to_road`, aceeasi poarta ca malurile —
##   loturile de MultiMesh nu trec prin `_place`, deci poarta se pune explicit.
## - compozitia dupa `aranjamentul-bate-numarul`: pilcuri cu goluri intre ele,
##   nu pas egal; piatra jos si deasa, copaci peste ea.
## ZERO materiale noi: bolovanii poarta `inca_stone` (clasa deja pe pista),
## copacii stau pe materialul de lume.
func _flanc() -> void:
	_fl_gol = 0
	_fl_panta = 0
	_fl_drum = 0
	_fl_gap = 0
	_fl_prob = 0
	_fl_try = 0
	# [model, h_min, h_max, gap_min, gap_max, pas, prob, clasa]
	# Golul pleaca de la 7 m (peste acostamentul de 4 m plus marja) si se
	# intinde pana la 58 m — acolo unde grila de iarba arata blocurile pline.
	for spec: Array in [
			# `gap_min` coboara la 2,5-4 m: PRIMUL PLAN era gaura ramasa dupa
			# runda 1 (celula din stanga-jos la 0.71 nu se miscase deloc,
			# 85,4 -> 85,0 %), fiindca un `gap_min` de 7 m lasa gol fix
			# culoarul cel mai apropiat de ochi, care ocupa cei mai multi
			# pixeli. Nu slabeste nicio garda: `_dist_to_road` scade
			# acostamentul REAL si cere 3 m de la el, deci carosabilul e aparat
			# de poarta aia, nu de `gap_min`.
			# RUNDA 2 A VALULUI 4 — RAPORTUL PIATRA/VEGETATIE, nu numarul.
			# Masurat pe banda, clasificand pixelii pe familii de nuanta
			# (treimi verticale din `bara_poi_F.png`):
			#   banda     brun/tan   gri (piatra)   verde
			#   MIJLOC      38 %        24 %         ~0 %
			#   JOS         52 %         9 %         ~0 %
			# Bara e o vale de PIATRA cu vegetatie ca accent. La noi, dupa
			# runda 1, flancul avea 373 de polylepis si 88 de tree_fern fata de
			# 258 de bolovani — adica exact invers. Si nu e o chestiune de
			# densitate: runda 1 a masurat deja ca a INGROSA vegetatia urca
			# iarba (30,4 -> 34,6 %), fiindca coroana lui polylepis e un verde
			# DESCHIS (V > 0,42) care inlocuieste gazon cu pixeli din aceeasi
			# familie. Ce schimba MATERIA e piatra.
			# Deci: bolovanii se indesesc si se maresc (pasul scade, h_max
			# creste), iar copacii se raresc (pasul creste, prob scade).
			# Piesele nu cresc mult la numar — se schimba din ce sunt facute.
			["moss_boulder_b", 1.6, 3.4, 3.0, 34.0, 1.6, 0.92, "inca_stone"],
			["moss_boulder_c", 2.6, 5.2, 4.0, 44.0, 2.2, 0.90, "inca_stone"],
			["moss_boulder_a", 0.6, 1.4, 2.5, 30.0, 1.3, 0.90, "inca_stone"],
			["polylepis_a", 3.6, 5.4, 4.0, 56.0, 4.2, 0.62, ""],
			["polylepis_b", 5.4, 8.2, 6.0, 70.0, 5.4, 0.58, ""],
			# INELUL DE FUNDAL (70-150 m) A FOST INCERCAT SI RESPINS, si merita
			# scris ca sa nu-l reincerce altcineva. Grila 8x6 la 0.67 arata
			# dupa runda 2 banda de orizont (randul 2) cu 37-67 % iarba pe toata
			# latimea, deci ipoteza „mai lipseste doar departarea" parea solida.
			# Masurat dupa: iarba a URCAT 30,4 -> 34,6 % la 0.67, si s-a inrautatit
			# pe toate cele trei fractii. Cauza, citita pe captura: coroana lui
			# `polylepis` e un verde DESCHIS (V > 0,42), deci la departare
			# inlocuieste pixeli de gazon cu pixeli de aceeasi familie —
			# silueta se schimba, materia nu. Ce lipseste in banda aia nu e
			# vegetatie, e RELIEF care sa rupa linia; si asta e teren, nu decor
			# (aceeasi granita ca la D si H). Starea pastrata e cea de dupa
			# runda 2 (memoria `revenirea-e-o-mutare-valida`).
			["tree_fern", 2.2, 3.4, 3.0, 36.0, 4.4, 0.58, ""],
			["bamboo_clump", 3.2, 5.4, 4.0, 46.0, 4.8, 0.56, ""],
		]:
		var mdl: String = String(spec[0])
		var cls: String = String(spec[7])
		# Patru felii de fractie, fiecare cu lotul ei de MultiMesh, ca AABB-ul
		# sa nu fie cat zona si culling-ul sa ramana util.
		for felie in 4:
			var f0: float = F_IN + (F_OUT - F_IN) * (float(felie) / 4.0)
			var f1: float = F_IN + (F_OUT - F_IN) * (float(felie + 1) / 4.0)
			var pos: PackedVector3Array = []
			var yaw: PackedFloat32Array = []
			var sc3: Array[Vector3] = []
			for sgn: float in [-1.0, 1.0]:
				var f := f0
				while f < f1:
					f += _step(float(spec[5]) + _rng.randf_range(-1.0, 1.0))
					# UN CAMP, NU UN SIR. Prima versiune punea o singura piesa
					# la fiecare pas longitudinal, deci iesea un RAND paralel cu
					# drumul oricat de mare era `gap_max`: 307 de incercari pe
					# toata zona si 90 de piese asezate, adica exact izlazul pe
					# care trebuia sa-l acopere. Un camp lat de 50 m cere
					# esantionare si pe LATIME — cu o banda la fiecare ~7 m de
					# departare, fiindca aria creste cu departarea.
					var benzi := int(maxf(1.0,
						(float(spec[4]) - float(spec[3])) / 7.0))
					for b in benzi:
						if _rng.randf() > float(spec[6]):
							_fl_prob += 1
							continue
						# PILCURI, NU SIR: goluri intentionate pe amandoua axele,
						# altfel campul citeste ca gazon tuns
						# (memoria aranjamentul-bate-numarul).
						if sin(f * 190.0 + float(b) * 2.1) > 0.62:
							_fl_gap += 1
							continue
						_fl_try += 1
						# Banda `b` isi ia golul din felia ei, cu suprapunere
						# de jitter intre benzi vecine.
						var lo: float = lerpf(float(spec[3]), float(spec[4]),
							float(b) / float(benzi))
						var hi: float = lerpf(float(spec[3]), float(spec[4]),
							float(b + 1) / float(benzi))
						var gap := _rng.randf_range(lo, hi)
						var n := _track.baked.size()
						var i := int(f * float(n)) % n
						var p := _track.baked[i]
						var s := _track._side_at(i) * sgn
						var half := _track.width_at_index(i)
						var q := p + s * (half + gap)
						var g := _sol_real(q.x, q.z)
						# NU peste buza care cade in gorja: dincolo de 9 m sub
						# drum incepe peretele, iar acolo lucreaza
						# `_canyon_wall`, nu flancul. Fara pragul asta copacii
						# ies pe fatada verticala.
						if g < p.y - 9.0:
							_fl_gol += 1
							continue
						# Nici pe stanca prea abrupta: panta pe patru directii,
						# maximul nu media (un perete paralel cu o raza nu se
						# vede altfel).
						var panta := 0.0
						for ang: float in [0.0, TAU * 0.25, TAU * 0.5, TAU * 0.75]:
							var gg := _sol_real(q.x + cos(ang) * 2.5,
								q.z + sin(ang) * 2.5)
							panta = maxf(panta, absf(gg - g) / 2.5)
						if panta > 0.78:
							_fl_panta += 1
							continue
						# Aceeasi poarta de carosabil ca la maluri: un lot de
						# MultiMesh nu trece prin `_place`, deci poarta se pune
						# explicit, fata de TOT traseul (pe viraj drumul revine
						# spre piesa cateva zeci de metri mai incolo).
						# ACEST REFUZ E CORECT SI POARTA INFORMATIE, nu e o
						# pierdere de randament: masurat, toate respingerile
						# sunt pe `sgn=-1` la frac 0.665-0.690 cu `dist=0.00`,
						# adica INTERIORUL acului, unde bratul de dus si cel de
						# intors sunt la ~25 m. O piesa „la 25 m in stanga"
						# bratului de dus cade pe bratul de intors. De aia
						# campul interior ramane ingust, si de aia latimea mare
						# se plateste pe exterior.
						if _dist_to_road(q.x, q.z) < 3.0:
							_fl_drum += 1
							continue
						var h := _rng.randf_range(float(spec[1]), float(spec[2]))
						var sc := _scale_for(mdl, h)
						pos.append(Vector3(q.x, g, q.z))
						yaw.append(_rng.randf_range(0.0, TAU))
						sc3.append(Vector3(sc, sc, sc))
			if pos.is_empty():
				continue
			# RUNDA 3 A VALULUI 4 — CULOAREA PIETREI, nu cantitatea ei.
			# Rundele 1 si 2 au mutat RAPORTUL piatra/vegetatie (0,56 -> 1,71)
			# si au scazut iarba de la 39 % la 21-30 %. Dar masurata pe BENZI
			# ORIZONTALE, nu pe cadru intreg, imaginea spune altceva:
			#
			#   banda (sus->jos)   BARA verde   noi verde   BARA gri   noi gri
			#   1 (mijloc sus)         3,3 %      51,8 %      29,1 %     3,1 %
			#   2                      3,6 %      46,6 %      28,2 %     0,8 %
			#   3                      1,1 %      43,4 %      16,7 %     2,4 %
			#
			# Bara are 28-29 % PIATRA CENUSIE fix in benzile de mijloc; noi
			# aveam sub 3 %. Cauza nu e numarul de bolovani (sunt 403), ci
			# CLASA lor: `inca_stone` are tenta (1.0, 0.8311, 0.6768) si lift
			# 0.6704, adica iese rgb(181,141,100), S=0,447 — se clasifica
			# „tan", si asa si arata. Piatra cenusie a barei e rgb(87,86,87),
			# S=0,066, V=0,351 (masurat pe 13 306 pixeli din benzile 1-2).
			#
			# `cut_stone` foloseste ACEEASI dala (`alpine_granite.png`) cu lift
			# 0.28 si tenta rece (0.88, 0.91, 0.97). Aceeasi textura in VRAM,
			# doar alta instanta de material. Masurat pe captura, nu calculat
			# (memoria `procent-de-culoare-nu-e-dovada`: aritmetica prezisese
			# rgb(67,65,60), pe ecran a iesit piatra deschisa):
			#
			#   banda   verde inca -> cut   gri inca -> cut
			#     1        51,8 -> 40,1       3,1 ->  3,7
			#     2        46,6 -> 26,2       0,8 ->  8,5
			#     3        43,4 -> 19,2       2,4 -> 11,4
			#
			# NU se pune pe tot: cu toti bolovanii cenusii, p90 al valorii sare
			# la 1,000 (bara: 0,620), adica tot flancul citeste ca un camp de
			# piatra alba si intra in concurenta cu lespedea drumului, care e
			# deja cel mai luminos lucru din cadru. Se imparte deci lotul:
			# doua treimi `cut_stone` (masa cenusie a benzilor de mijloc), o
			# treime `inca_stone` (accentele calde pe care bara le are si ea —
			# 38-52 % brun/tan in benzile de jos). Impartirea e DETERMINISTA
			# pe indice, nu pe alt apel de RNG, ca regenerarea sa dea acelasi
			# rezultat.
			var split_cls: bool = cls == "inca_stone" and mdl.begins_with("moss_boulder")
			if split_cls:
				var pg: PackedVector3Array = []
				var yg: PackedFloat32Array = []
				var sg: Array[Vector3] = []
				var pw: PackedVector3Array = []
				var yw: PackedFloat32Array = []
				var sw: Array[Vector3] = []
				for k in pos.size():
					if k % 3 == 2:
						pw.append(pos[k])
						yw.append(yaw[k])
						sw.append(sc3[k])
					else:
						pg.append(pos[k])
						yg.append(yaw[k])
						sg.append(sc3[k])
				if not pg.is_empty():
					_flock_seed += 1
					_model_flock("F_Flanc_%s_f%d_gri" % [mdl, felie], RES[mdl],
						pg, yg, sg, 77500 + _flock_seed, "cut_stone")
				if not pw.is_empty():
					_flock_seed += 1
					_model_flock("F_Flanc_%s_f%d" % [mdl, felie], RES[mdl],
						pw, yw, sw, 77500 + _flock_seed, cls)
				_tri += int(TRI.get(mdl, 0)) * pos.size()
				print("; flanc %s felie %d: %d piese (%d gri + %d cald)" % [
					mdl, felie, pos.size(), pg.size(), pw.size()])
				continue
			_flock_seed += 1
			_model_flock("F_Flanc_%s_f%d" % [mdl, felie], RES[mdl], pos, yaw,
				sc3, 77500 + _flock_seed, cls)
			_tri += int(TRI.get(mdl, 0)) * pos.size()
			print("; flanc %s felie %d: %d piese" % [mdl, felie, pos.size()])
	print("; FLANC filtre: incercari %d, respinse gol %d, panta %d, drum %d, pilc %d, prob %d" % [
		_fl_try, _fl_gol, _fl_panta, _fl_drum, _fl_gap, _fl_prob])



func _bank_edge() -> void:
	var f := 0.6960
	var k := 0
	while f < 0.7290:
		var mdl: String = ["moss_boulder_c", "moss_boulder_b", "moss_boulder_b",
			"moss_boulder_a"][k % 4]
		# RUNDA 2: primele marimi (2,6-4,2 m la `moss_boulder_c`) au iesit in
		# captura la 0.67 ca doua perne verzi lipite de marginea drumului,
		# ocupand jumatate de cadru. Un bolovan pe buza are rostul de a lega
		# carosabilul de mal, nu de a-l inlocui: acum 1,4-2,4 m la cel mare si
		# 0,5-1,0 m la cel mic, iar golul minim urca de la 2,5 la 4,0 m ca
		# silueta sa nu mai atinga muchia soselei.
		var h := _rng.randf_range(1.4, 2.4) if mdl == "moss_boulder_c" else (
			_rng.randf_range(0.9, 1.5) if mdl == "moss_boulder_b"
			else _rng.randf_range(0.5, 1.0))
		_place(mdl, "FBuza", f, 1.0, _rng.randf_range(1.5, 4.5),
			_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "hull")
		f += 0.0022 + _rng.randf_range(-0.0004, 0.0004)
		k += 1


## VEGETATIA DE LANGA SOSEA, pe ambele brate. Fara ea cadrul de la 0.70 (unde
## raul nu se vede, nota 2) ramane campul gol din captura de plecare.
##
## Partea dinspre rau (dreapta la dus, stanga la intors) primeste piese MICI si
## rare — acolo trebuie sa se vada in jos, spre albie. Partea dinspre versant
## primeste masa: bambus si queñual.
func _road_side() -> void:
	# --- versantul (partea opusa raului), DOUA RANDURI ---
	#
	# RUNDA 9, masurat pe captura la 0.70: cu un singur rand la pas 7,5 m si
	# probabilitate 0,78 iese o piesa la ~9,6 m de drum, adica exact ce s-a
	# vazut — cativa copaci razleti pe un izlaz gol, nu un mal. Randul apropiat
	# coboara la pas 4,5 m si probabilitate 0,88 (o piesa la ~5 m), iar peste el
	# se adauga un rand de fund la 16-30 m, mai inalt: masa verde care inchide
	# cadrul, in loc de orizont de iarba.
	for leg: Array in [[0.6560, 0.6870, -1.0], [0.6930, 0.7300, 1.0]]:
		var fb := float(leg[0])
		var kb := 0
		while fb < float(leg[1]):
			if _rng.randf() < 0.75:
				var mdlb: String = ["polylepis_b", "bamboo_clump",
					"polylepis_a", "polylepis_b"][kb % 4]
				var hb := {
					"polylepis_b": _rng.randf_range(6.0, 8.5),
					"bamboo_clump": _rng.randf_range(4.5, 6.5),
					"polylepis_a": _rng.randf_range(3.8, 5.0),
				}[mdlb] as float
				_place(mdlb, "FVersFund", fb, float(leg[2]),
					_rng.randf_range(16.0, 30.0), _rng.randf_range(0.0, TAU),
					_scale_for(mdlb, hb), "trunk")
			fb += _step(8.0 + _rng.randf_range(-1.5, 1.5))
			kb += 1
	for leg: Array in [[0.6560, 0.6870, -1.0], [0.6930, 0.7300, 1.0]]:
		var f := float(leg[0])
		var k := 0
		while f < float(leg[1]):
			var sgn := float(leg[2])
			if _rng.randf() < 0.88:
				var mdl: String = ["bamboo_clump", "polylepis_a", "bamboo_clump",
					"tree_fern", "polylepis_b"][k % 5]
				var h := {
					"bamboo_clump": _rng.randf_range(3.6, 5.6),
					"polylepis_a": _rng.randf_range(3.2, 4.6),
					"tree_fern": _rng.randf_range(2.4, 3.6),
					"polylepis_b": _rng.randf_range(5.0, 7.2),
				}[mdl] as float
				# Coroana n-are voie sub 4 m de ax (prag de camera): la
				# semi-latimea de 6.5-8 m, un gol de 2 m e deja sigur.
				# Golul pleaca de la 5,5 m, nu de la 2: acostamentul are pana la
				# 4 m si o piesa pusa „la 2 m de muchie" statea in el (runda 4).
				_place(mdl, "FVers", f, sgn, _rng.randf_range(5.5, 13.0),
					_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
			f += _step(4.5 + _rng.randf_range(-1.0, 1.0))
			k += 1
	# --- partea dinspre rau ---
	#
	# R3, SI REGULA VECHE SE APLICA ACUM DOAR PE JUMATATE. Piesele erau tinute
	# joase (bromelie 0,35 m, bolovan 0,6 m) „ca sa nu astupe albia" — corect
	# cat timp albia era pe bratul de DUS. Acum apa e in gorja de pe bratul de
	# INTORS, deci pe bratul de dus nu mai e nimic de aparat, si consecinta se
	# vede in captura: G5_r4_0.67.png e jumatate de cadru de iarba goala care se
	# topeste in ceata. Piese de 0,35-0,6 m la 40 m de camera subintind sub un
	# grad; nu se vad, deci nu exista.
	#
	# Deci: bratul de INTORS (-1, dinspre gorja) pastreaza regula joasa, fiindca
	# acolo apa CHIAR e dedesubt si o coroana ar taia-o.
	# Bratul de DUS (+1, dinspre vale) primeste vegetatie de mal adevarata —
	# ferigi si bambus de 2,4-5 m, cu queñual in randul al doilea. Materia din
	# bara pentru zona asta e „copaci pe mal", si asta e partea de cadru care ii
	# poate primi.
	for leg2: Array in [[0.6930, 0.7300, -1.0]]:
		var f2 := float(leg2[0])
		var k2 := 0
		while f2 < float(leg2[1]):
			if _rng.randf() < 0.55:
				var mdl2: String = ["bromeliad", "moss_boulder_a", "bromeliad",
					"tree_fern"][k2 % 4]
				var h2 := {
					"bromeliad": _rng.randf_range(0.35, 0.6),
					"moss_boulder_a": _rng.randf_range(0.6, 1.1),
					"tree_fern": _rng.randf_range(2.2, 3.0),
				}[mdl2] as float
				var mode := "none" if mdl2 == "bromeliad" else (
					"trunk" if mdl2 == "tree_fern" else "hull")
				_place(mdl2, "FMalDrum", f2, float(leg2[2]),
					_rng.randf_range(5.0, 11.0), _rng.randf_range(0.0, TAU),
					_scale_for(mdl2, h2), mode)
			f2 += _step(6.0 + _rng.randf_range(-1.2, 1.2))
			k2 += 1
	# MALUL DINSPRE VALE PE BRATUL DE DUS (0.656-0.687, partea +1): doua randuri,
	# unul aproape si unul de fund, ca marginea sa nu se mai termine in orizont.
	var f3 := 0.6555
	var k3 := 0
	while f3 < 0.6880:
		if _rng.randf() < 0.82:
			var mdl3: String = ["tree_fern", "bamboo_clump", "tree_fern",
				"polylepis_a", "bamboo_clump"][k3 % 5]
			var h3 := {
				"tree_fern": _rng.randf_range(2.4, 3.6),
				"bamboo_clump": _rng.randf_range(3.4, 5.2),
				"polylepis_a": _rng.randf_range(3.4, 4.8),
			}[mdl3] as float
			_place(mdl3, "FMalVale", f3, 1.0, _rng.randf_range(5.5, 12.0),
				_rng.randf_range(0.0, TAU), _scale_for(mdl3, h3), "trunk")
		if _rng.randf() < 0.60:
			var mdl4: String = ["polylepis_b", "bamboo_clump", "polylepis_a"][k3 % 3]
			var h4 := {
				"polylepis_b": _rng.randf_range(5.5, 7.8),
				"bamboo_clump": _rng.randf_range(4.2, 6.0),
				"polylepis_a": _rng.randf_range(3.8, 5.0),
			}[mdl4] as float
			_place(mdl4, "FMalValeFund", f3 + 0.0009, 1.0,
				_rng.randf_range(15.0, 28.0), _rng.randf_range(0.0, TAU),
				_scale_for(mdl4, h4), "trunk")
		f3 += _step(5.5 + _rng.randf_range(-1.2, 1.2))
		k3 += 1
	# BUZA DINSPRE VALE pe bratul de INTORS. Raul nu se vede de acolo (nota 9),
	# dar CADEREA trebuie sa se vada: fara ea, la 0.70 marginea din stanga e
	# iarba care se pierde in orizont, si POI-ul „cel mai jos punct al turului"
	# nu are nicio buza. Bolovani mici, rari, pe umarul dinspre vale — acelasi
	# rol ca `_bank_edge` pe bratul de dus.
	var fv := 0.6950
	var kv := 0
	while fv < 0.7290:
		var mv: String = ["moss_boulder_b", "moss_boulder_a", "moss_boulder_a",
			"moss_boulder_c"][kv % 4]
		var hv := _rng.randf_range(1.4, 2.2) if mv == "moss_boulder_c" else (
			_rng.randf_range(0.9, 1.5) if mv == "moss_boulder_b"
			else _rng.randf_range(0.5, 1.0))
		_place(mv, "FBuzaVale", fv, -1.0, _rng.randf_range(5.5, 14.0),
			_rng.randf_range(0.0, TAU), _scale_for(mv, hv), "hull")
		fv += 0.0026 + _rng.randf_range(-0.0005, 0.0005)
		kv += 1
	# Repere de traseu pe acul de la 0.685-0.695, unde drumul se intoarce 180 de
	# grade peste o creasta: singurul semn de „aici se intoarce" din tot POI-ul.
	for fm: float in [0.6835, 0.6870, 0.6905, 0.6940]:
		# 1,7 m in loc de 1,2: la 1,2 m un reper de traseu e un cilindru palid
		# de doi pixeli si citea ca gunoi in captura rundei 10.
		_place("trail_marker", "FSemn", fm, -1.0, 5.2,
			_rng.randf_range(0.0, TAU), _scale_for("trail_marker", 1.7), "none")


## GARA MICA (`inca_house_b`, 2,83 m inalt, 6,00 x 4,21 m in plan).
##
## UNDE, si de ce NU langa sina. Bara o arata lipita de calea ferata, si prima
## versiune a pus-o acolo (x = -176, z = -211). Apoi ProbeMpFSeen a masurat ce
## se vede de la volan la cota trenului (y = -31): la 0.660 si 0.670 celulele
## NEOCLUZATE sunt toate la x <= -250 sau z >= -170, adica sina de la z = -205
## nu e in cadru DELOC — nici ea, nici ce sta langa ea. O halta acolo e o casa
## construita pentru nimeni.
##
## Deci gara sta pe malul de sud al reprizei de SUS, la x ~ -232, z ~ -186: in
## plina zona masurata ca vizibila la 0.660-0.675, peste apa fata de sofer.
## Citeste tot ca „cladire mica la marginea apei" — materia din bara — fara sa
## pretinda un peron pe care nu-l vede nimeni.
##
## Cota vine din raycast si piesa se ridica 0,15 m: `inca_house_b` are talpa
## plata, iar pe un mal in panta un colt ar intra in pamant.
##
## R3, DOUA MUTARI, si a doua a fost ceruta de o GARDA, nu de o captura.
##
## (i) Din vechiul bazin (x=-232, z=-186, acum in afara cadrului si sub cornisa
##     noua) pe RAMA DE DINCOLO a gorjei, la x ~ -178, z ~ -103, unde terenul e
##     un platou la -20,7. Aratau bine in captura...
## (ii) ...si ProbeLaneClear a picat, cu numele pieselor pe ea:
##
##       0.755 lat=-2.2 | FCortGara68_col
##       0.760 lat=+0.0 | FGara63_col
##       0.760 lat=-2.2 | FGara63_col
##       0.760 lat=+2.2 | FGara63_col
##
##     27 de probe blocate fata de linia de baza 20, adica EXACT cele 7 puse de
##     gara. Cauza: „rama de dincolo" e rama pe care URCA DRUMUL inapoi, la
##     frac 0.748-0.771 si z = -104. Halta statea pe carosabil.
##     Masurat apoi pe toata rama (tools/sv7_mpf.gd): la z = -100..-96 golul
##     fata de marginea drumului e NEGATIV pe toate cele cinci coloane testate,
##     si abia la z = -88 ajunge la 3,5 m. Nu e loc de gara acolo, punct.
##
## Deci gara coboara in GORJA, pe malul de dincolo al apei (x ~ -186, z ~ -118).
## Acolo: terenul e podea la -36..-40, e in plin cadru la 0.70 (fanta masurata
## de `ProbeMpFSeen` e chiar z = -120, x = -200..-160), si e la 12-15 m SUB
## carosabil, deci nu poate intra in nicio banda. O halta pe malul raului, sub
## drum, e chiar materia din bara: „cladire mica de gara" langa apa.
##
## COLIZIUNEA: `none` pe tot grupul. E sub plafonul plasei de repunere (-27,5),
## deci orice masina ajunsa acolo e deja repusa; un corp fizic n-ar face decat
## sa dea de ce sa se agate in cele doua secunde de pana la repunere
## (memoria `coliziune-none-e-fantoma-nu-stearsa`: mesh-ul ramane, corpul nu).
func _station() -> void:
	var sx := -186.0
	var sz := -118.0
	var g := _sol_real(sx, sz)
	# SCARA: 2,833 m livrat, 4,2 m aici. Gara sta la ~50 m de sofer, peste apa;
	# la inaltimea din GLB ar subintinde 3 grade si s-ar pierde intre bolovanii
	# de 2 m. La 4,2 m ramane „cladire mica" fata de un drum de 16 m latime, dar
	# se citeste ca acoperis si ziduri.
	_place_world("inca_house_b", "FGara", Vector3(sx, g + 0.15, sz), 0.42,
		_scale_for("inca_house_b", 4.2), "none")
	# Peronul: rucsaci si doua corturi — gara are oameni, altfel e o ruina.
	for off: float in [-5.2, -2.0, 3.4]:
		var px := sx + off
		var pz := sz + _rng.randf_range(2.0, 3.6)
		_place_world("backpack_pile", "FRucsacGara",
			Vector3(px, _sol_real(px, pz), pz), _rng.randf_range(0.0, TAU),
			_scale_for("backpack_pile", 1.3), "none")
	for i in 2:
		var tx := sx + (-8.5 if i == 0 else 7.6)
		var tz := sz + _rng.randf_range(-1.0, 2.4)
		_place_world("tent_a" if i == 0 else "tent_b", "FCortGara",
			Vector3(tx, _sol_real(tx, tz), tz), _rng.randf_range(0.0, TAU),
			_scale_for("tent_a", 2.4), "none")


## TABARA DE PE DRUM (brief §2 F: „gara mica, corturi, rucsacuri"). Sta pe
## bratul de INTORS, pe partea dinspre versant, fiindca acolo raul nu se vede
## (nota 9) si cadrul are nevoie de ceva ce nu e iarba.
##
## RUNDA 9, masurat pe captura: la 0.70 cadrul era drum peste izlaz, cu patru
## corturi razlete de 1,4 m la 6-12 m de muchie — la 40 m de camera subintind
## doua grade, deci nu se citesc ca tabara, se citesc ca gunoi. Tabara din
## bara e un GRUP: corturi unul langa altul, rucsaci intre ele, pe o poiana.
## Deci corturile se aduna in DOUA pilcuri (4 + 3), in aceeasi fereastra de
## fractie, la 7-11 m de muchie, cu rucsaci si repere intre ele.
##
## Corturile au `hull`: un cort de 2,1 m latime atins la 20 m/s e o oprire,
## deci nu intra in banda — verificarea e cea din `_place`, fata de marginea
## acostamentului real.
func _camp() -> void:
	# Doua pilcuri, fiecare cu centrul lui, ca sa se citeasca „doua grupuri de
	# oameni", nu „un sir de corturi la distante egale".
	for pilc: Array in [[0.7045, 4], [0.7105, 3]]:
		var f0: float = float(pilc[0])
		for i in int(pilc[1]):
			var mdl := "tent_a" if i % 2 == 0 else "tent_b"
			# SCARA CORTULUI: GLB-ul e livrat la 1,407 m inaltime si 2,09 m
			# amprenta. Runda 10, masurat pe captura la 0.70: la 30-40 m de
			# camera un cort de 1,4 m subintinde sub doua grade si citea ca o
			# pata inchisa pe iarba — nu ca un cort. La 2,4 m (scara 1,71)
			# subintinde 3,5-4,5 grade, adica se vede acoperisul si intrarea,
			# si ramane sub inaltimea unei masini, deci nu e un zid.
			# STRANS, nu imprastiat: un pilc de corturi la 3 m unul de altul si
			# la 7-9 m de muchie citeste „tabara"; aceleasi corturi la 5 m si
			# 11 m citesc „ceva aruncat pe camp" (runda 11).
			_place(mdl, "FCort", f0 + _step(float(i) * 3.0 - 4.0), 1.0,
				7.0 + float(i % 2) * 2.0, _rng.randf_range(0.0, TAU),
				_scale_for(mdl, 2.4), "hull")
		for j in 3:
			# Rucsacii tot asa: 0,694 m e invizibil la 35 m. La 1,3 m sunt
			# gramezi de bagaje langa corturi, si raman sub capota.
			_place("backpack_pile", "FRucsac",
				f0 + _step(float(j) * 2.6 - 3.0), 1.0,
				_rng.randf_range(6.2, 8.5), _rng.randf_range(0.0, TAU),
				_scale_for("backpack_pile", 1.3), "none")


## PLASA DE REPUNERE peste albie (nota 7). Bazinul asta n-avea niciuna:
## ProbeRespawnZones raporta doar `BridgeFall` si `ViaductNet2` (x de la -106 la
## 94), iar apa e la x de la -266 la -118.
##
## PLAFONUL NU E GHICIT, E MASURAT. O cutie pusa „sub cota apei plus un metru"
## e gresita cand soseaua trece pe deasupra: bratul de dus coboara de la -24,4
## (0,655) la -27,7 (0,680), adica intra in intervalul de cote al apei de sus
## (-28,0). De aceea `_respawn` baleiaza traseul, ia cota CEA MAI JOASA a
## carosabilului care cade in amprenta cutiei (inclusiv semi-latimea, deci
## marginea, nu axa) si pune plafonul cu 2,5 m sub ea. Daca nu ramane loc
## deasupra apei, cutia nu se emite deloc si sonda o spune — mai bine fara
## plasa decat cu o plasa care repune pe cine conduce normal.
##
## `backoff_m` 70 e cifra canalelor (Track.CHANNEL_FALL_BACKOFF): de la 14 m
## masina nu apuca sa ia viteza, recade, si bucla aia o tine in apa toata cursa.
func _respawn() -> void:
	# UNDE E GAURA, MASURAT. `ProbeRespawnZones` pe starea de plecare gaseste
	# doar `BridgeFall` si `ViaductNet2` (x de la -106 la 94). Gorjul de sub
	# POI-ul F — x de la -310 la -230, z de la -186 la -150 — n-are plasa:
	# terenul acolo cade la -32..-40, panta de intoarcere e de peste 45 de
	# grade, si o masina ajunsa in el nu mai iese conducand.
	#
	# AMPRENTA NU E CASETA ALBIEI, si asta e reparatia rundei 2. Caseta
	# albiei largita cu maluri ajungea pana sub sosea (drumul coboara la -28,1
	# chiar acolo), deci nu mai ramanea plafon: `top` iesea -30,6, adica SUB
	# apa, si plasa nu se mai emitea deloc. Corect e sa se acopere GORJUL, care
	# e sub rama, nu albia, care e la nivelul drumului.
	#
	# R3: amprenta mutata pe gorja noua. Ea e STRANSA INTRE DOUA SOSELE — bratul
	# de intors pe z = -134 (y -25..-29) si revenirea pe z = -104 (y -20,6) —
	# deci caseta se opreste la z = -126 si z = -107, ca sa nu prinda niciun
	# carosabil in plan; plafonul masurat mai jos o verifica si pe verticala.
	# Pe x se opreste la -232: dincolo incepe podeaua rapei 9 (-49 la x=-240),
	# care e canionul deschis, nu gorja raului.
	# Masurat (tools/sv6_mpf.gd): cu x1 = -148 amprenta prinde 75 de puncte de
	# carosabil — acul de la 0.731-0.745, care urca spre nord pe x ~ -150 la
	# y = -23..-25. Plafonul de -27,5 il ocoleste corect pe verticala, dar
	# marginea de est se retrage oricum la -156: albia incepe la x = -155, deci
	# nimic din rau nu iese din plasa, si caseta nu mai atinge acul deloc.
	var x0 := -232.0
	var x1 := -156.0
	var z0 := -126.0
	var z1 := -107.0
	# Cea mai joasa sosea din amprenta, marginea inclusa.
	var n := _track.baked.size()
	var road_lo := INF
	for i in n:
		var p := _track.baked[i]
		var sd := _track._side_at(i)
		var half := _track.width_at_index(i)
		for lat: float in [-half, 0.0, half]:
			var q := p + sd * lat
			if q.x >= x0 and q.x <= x1 and q.z >= z0 and q.z <= z1:
				road_lo = minf(road_lo, p.y)
	# PLAFONUL, R3 — si aici regula veche se INVERSEAZA, cu motiv.
	#
	# Pana acum plafonul statea si sub cea mai joasa sosea, si SUB ALBIE
	# (`apa_jos - 1,6`), ca sa nu fie repus cine cade in apa si poate iesi
	# conducand. Pe raftul vechi era corect: albia era la 1-2 m sub drum.
	# Pe gorja noua da o plasa INUTILA, si se vede din cifre: apa cea mai de jos
	# e la -40,25, deci `apa_jos - 1,6` = -41,85, iar FUNDUL gorjei e la -38..-41.
	# Plasa ar fi stat sub podeaua pe care aterizeaza masina — adica n-ar fi
	# prins pe nimeni, niciodata.
	#
	# Aici apa NU e o baltoaca pe care o traversezi: e fundul unei crapaturi de
	# 11-12 m cu pereti de peste 45 de grade pe ambele parti (TRANS 0.710:
	# +8 m -> -29,7, +13 m -> -37,5, +25 m -> -20,5). Cine ajunge acolo nu iese
	# conducand, si brief-ul o spune pe fata: „Apa = repunere (RespawnZone)".
	# Deci plafonul se leaga de CAROSABIL, nu de apa: 2,5 m sub cea mai joasa
	# sosea din amprenta. Iese -27,5, adica prinde toata gorja (fund -38..-45)
	# si nu atinge niciun drum.
	var apa_jos: float = float((POOLS[POOLS.size() - 1] as Array)[2])
	var top := -20.0
	if road_lo < INF:
		top = road_lo - 2.5
		print("; plasa: cea mai joasa sosea in amprenta e %.1f -> plafon %.1f (apa cea mai de jos %.1f, fund gorja ~-40)"
			% [road_lo, top, apa_jos])
	else:
		print("; plasa: NICIUN carosabil in amprenta -> plafon %.1f" % top)
	var bottom := -62.0
	_out.append('[node name="F_RaulRepunere" type="Area3D" parent="%s"]' % ZONE)
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)"
		% [(x0 + x1) * 0.5, (top + bottom) * 0.5, (z0 + z1) * 0.5])
	_out.append('script = ExtResource("respawn")')
	_out.append("backoff_m = 70.0")
	_out.append("")
	_out.append('[node name="Forma" type="CollisionShape3D" parent="%s/F_RaulRepunere"]' % ZONE)
	_out.append('shape = SubResource("BoxShape3D_F_rau")')
	_out.append("")
	_subres.append('[sub_resource type="BoxShape3D" id="BoxShape3D_F_rau"]')
	_subres.append("size = Vector3(%f, %f, %f)" % [x1 - x0, top - bottom, z1 - z0])
	_subres.append("")
	print("; plasa de repunere: x [%.0f, %.0f] z [%.0f, %.0f] y [%.1f, %.1f]"
		% [x0, x1, z0, z1, bottom, top])


## Latimea REALA a acostamentului la indicele dat, cea mai lata dintre cele doua
## parti, luata chiar de la pista (`_shoulder_width`, privat dar accesibil prin
## `call`). Nu se presupune plafonul de 4 m: pe malul raului caderea e mare si
## acostamentul chiar ajunge la plafon, dar in alte locuri e 1,3 m, si o marja
## presupusa peste tot ar refuza degeaba jumatate din decor.
func _shoulder(i: int) -> float:
	if _sh_cache.has(i):
		return float(_sh_cache[i])
	var w: float = maxf(
		float(_track.call("_shoulder_width", i, -1.0)),
		float(_track.call("_shoulder_width", i, 1.0)))
	_sh_cache[i] = w
	return w


## Distanta de la un punct la MARGINEA carosabilului (drum + acostament),
## masurata pe tot traseul copt. Negativa inseamna „pe drum".
## R3: DEGAJAREA ERA OARBA PE VERTICALA, si pe gorja asta e chiar defectul care
## golea malurile. Functia masura numai in plan XZ, deci un punct de pe fundul
## gorjei, la y = -39, era declarat „la 2 m de drum" fata de o sosea care trece
## la y = -27, adica DOUAZECI SI PATRU de metri mai sus in linie dreapta.
## E memoria `is-on-road-vertical-cu-profil`, aceeasi capcana, alt semn: acolo
## un punct la +17 m raspundea „pe drum", aici unul la -12 m raspunde „langa
## drum" si refuza decorul.
##
## Masurat pe generarea dinainte de fix: 32 de piese refuzate langa carosabil si
## maluri de 1-2 piese pe fiecare inel. Acum distanta e cea REALA in spatiu:
## se compune orizontala (fata de marginea acostamentului) cu diferenta de cota
## fata de sosea. Un punct chiar sub drum, dar la 12 m mai jos, ramane la 12 m —
## ceea ce si este, si ce conteaza si pentru fizica (nu poate fi atins de o
## masina care trece pe deasupra).
##
## Cota punctului vine din teren real. Cache-ul ramane pe grila de 2 m.
func _dist_to_road(x: float, z: float) -> float:
	# Cache pe grila de 2 m: apelul e O(numarul de puncte coapte) = 1111
	# iteratii, iar `_gravel` il cheama de zeci de mii de ori. 2 m e cu mult sub
	# marja de 14 m pe care o pazeste, deci cache-ul nu schimba nicio decizie.
	var key := Vector2i(int(round(x * 0.5)), int(round(z * 0.5)))
	if _road_cache.has(key):
		return float(_road_cache[key])
	var px := float(key.x) * 2.0
	var pz := float(key.y) * 2.0
	var py := _sol_real(px, pz)
	var lo := INF
	for j in _track.baked.size():
		var bp := _track.baked[j]
		# Orizontala: de la marginea acostamentului, ca pana acum. Sub zero
		# inseamna „pe carosabil in plan", si atunci ramane doar verticala.
		var oriz: float = maxf(0.0, Vector2(bp.x - px, bp.z - pz).length()
			- _track.width_at_index(j) - _shoulder(j))
		# Verticala: cat de departe pe y. Numai cand punctul e SUB sosea —
		# un prop mai INALT decat drumul ramane judecat in plan, fiindca acolo
		# silueta chiar intra in cadrul soferului.
		var vert: float = maxf(0.0, bp.y - py)
		lo = minf(lo, sqrt(oriz * oriz + vert * vert))
	_road_cache[key] = lo
	return lo


# ------------------------------------------------------------------ emitere

## Un lot de placi plate pe un slot de atlas (tiparul crustei de sare).
func _disc_flock(nume: String, slot: int, radius: float, smin: float,
		smax: float, pos: PackedVector3Array, yaw: PackedFloat32Array,
		sid: int, sc3: Array[Vector3] = []) -> void:
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [nume, ZONE])
	_out.append('script = ExtResource("flock")')
	_out.append("disc_slot = %d" % slot)
	_out.append("disc_radius = %.2f" % radius)
	_out.append("scale_min = %.2f" % smin)
	_out.append("scale_max = %.2f" % smax)
	_out.append("seed_value = %d" % sid)
	_out.append("positions = %s" % var_to_str(pos).replace("\n", ""))
	_out.append("yaws = %s" % var_to_str(yaw).replace("\n", ""))
	# Scalare NEUNIFORMA, optionala: spuma cere placi INTINSE pe firul apei, nu
	# discuri. Cu scara uniforma, in F_r3_0.66.png spuma citea ca un covor de
	# nuferi — o multime de ovale albe egale. O creasta de repezis e lunga si
	# ingusta, si aia se obtine numai din (x, y, z) diferiti pe instanta.
	if sc3.size() == pos.size() and not sc3.is_empty():
		_out.append("scale3_list = %s" % var_to_str(sc3).replace("\n", ""))
	_out.append("")


## Un lot de piese de kit ca MultiMesh (un desen, zero corpuri fizice).
func _model_flock(nume: String, res_id: String, pos: PackedVector3Array,
		yaw: PackedFloat32Array, sc3: Array[Vector3], sid: int,
		tri_class: String = "") -> void:
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [nume, ZONE])
	_out.append('script = ExtResource("flock")')
	_out.append('model = ExtResource("%s")' % res_id)
	if tri_class != "":
		_out.append('tri_class = "%s"' % tri_class)
	_out.append("seed_value = %d" % sid)
	_out.append("positions = %s" % var_to_str(pos).replace("\n", ""))
	_out.append("yaws = %s" % var_to_str(yaw).replace("\n", ""))
	_out.append("scale3_list = %s" % var_to_str(sc3).replace("\n", ""))
	_out.append("")


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la corpul piesei. Cota din teren real.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull",
		y_off: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	# COTA SE IA PE AMPRENTA, NU INTR-UN PUNCT. `probe_manual` a gasit patru
	# corturi din tabara ingropate cu 2,3 m — si de data asta NU era falsul
	# pozitiv al campului neted: verificate cu raycast, chiar erau sub teren.
	# Cauza: tabara sta pe taluzul malului, unde solul coboara cu ~1 m pe
	# metru, iar un cort de 2,09 m amprenta asezat dupa cota din CENTRU are
	# marginea din amonte infipta si pe cea din aval in aer. Se ia deci cota
	# cea mai MARE de pe amprenta (colturile plus centrul): piesa sta pe
	# varful denivelarii, si nimic nu intra in pamant.
	# Raza de esantionare: cel putin 1,2 m, chiar daca piesa are trunchi
	# subtire. `FVers28` (o feriga) a ramas ingropata cu 2,9 m dupa prima
	# versiune a acestui fix, fiindca `BASE_R` pentru feriga e raza
	# TRUNCHIULUI (~0,3 m) si esantionarea nu ajungea pe taluz. Ce conteaza
	# aici nu e cat de gros e trunchiul, ci cat de repede coboara terenul sub
	# el — deci raza minima e a pantei, nu a piesei.
	# RAZA DE ESANTIONARE SE PLAFONEAZA, si asta repara „plutirile" de pe taluz.
	# Regula de mai sus (cota cea mai MARE de pe amprenta) e corecta ca intentie
	# — piesa sa nu intre in deal — dar raza folosita era `maxf(r, 1.2)`, adica
	# raza de COLIZIUNE scalata. Un cort dus la 2,4 m inaltime are scara 1,71,
	# deci r = 1,46 * 1,71 = 2,50 m: esantioneaza la doi metri si jumatate, si
	# pe un taluz de 45 de grade asta inseamna ca ia cota de la 2,5 m mai sus pe
	# panta. Masurat pe FCort74: amprenta reala -39,72..-36,63, dar piesa
	# asezata la -34,95, adica 1,7 m peste MAXIMUL propriei amprente.
	# Se plafoneaza deci la 1,2 m (raza pantei, nu a piesei) si se ia percentila
	# 75 in loc de maxim: percentila ignora un singur colt nimerit pe un pinten,
	# care e exact cazul de aici (memoria
	# `impartirea-pe-jumatati-ascunde-umbrirea`, in varianta pe cote).
	var rs: float = clampf(r, 0.6, 1.2)
	var esant: Array[float] = [_sol_real(q.x, q.z)]
	for ang: float in [0.0, TAU * 0.125, TAU * 0.25, TAU * 0.375, TAU * 0.5,
			TAU * 0.625, TAU * 0.75, TAU * 0.875]:
		esant.append(_sol_real(q.x + cos(ang) * rs, q.z + sin(ang) * rs))
	esant.sort()
	var g: float = esant[int(float(esant.size() - 1) * 0.75)]
	if d - r < half + 0.5:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < 4.0:
		_warn += 1
		print("; ATENTIE coroana %s la frac %.4f ajunge la %.2f m de ax" % [
			model, frac, d - cr])
	# DEGAJAREA FATA DE TOT TRASEUL, SI FATA DE ACOSTAMENT.
	#
	# Runda 3, masurat pe captura: `gap` e socotit din latimea la fractia `frac`
	# si pe DIRECTIA laterala de acolo — pe un viraj drumul revine spre piesa
	# cateva zeci de metri mai incolo, si un bolovan „la 5 m de muchie" a iesit
	# fix pe carosabil (F_r3_0.67.png). Deci se cauta punctul copt cel mai
	# apropiat, nu cel de la fractia data.
	#
	# Runda 4, a doua captura: bambusul iesea IN BANDA PALIDA desi trecea de
	# testul de mai sus. Cauza, citita din track.gd: banda palida nu e
	# `width_at_index`, e drumul PLUS acostamentul, iar `_shoulder_width` il
	# deriva din caderea terenului de langa banda si il lasa sa creasca pana la
	# `SHOULDER_MAX_WIDTH` = 4,0 m. Pe malul raului caderea e chiar maxima, deci
	# acostamentul e la plafon. De aia degajarea se masoara acum de la
	# `width_at_index + 4.0`, adica de la marginea a ceea ce se VEDE ca drum.
	var lo := INF
	for j in n:
		var bp := _track.baked[j]
		var dd: float = Vector2(bp.x - q.x, bp.z - q.z).length()
		dd -= _track.width_at_index(j) + _shoulder(j)
		lo = minf(lo, dd)
	# 2,5 m de la marginea acostamentului, nu 1,0: in F_r7_0.67.png bambusul
	# tot iesea pe banda palida. Cauza e ca punctele coapte sunt la ~1,8 m
	# distanta pe traseu, deci intre doua puncte marginea reala se mai umfla
	# putin pe viraj; marja acopera diferenta.
	if lo < r + 2.5:
		_refuzate += 1
		return
	_raw(model, base, Vector3(q.x, g + y_off, q.z), yaw, scl, mode)


## Aceeasi asezare, dar la coordonate de lume date direct (mal, albie).
func _place_world(model: String, base: String, pos: Vector3, yaw: float,
		scl: float, mode: String = "hull") -> void:
	_raw(model, base, pos, yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, s, scl, -s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate langa carosabil, %d avertismente, ~%d triunghiuri"
		% [_n, _refuzate, _warn, _tri])
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
	if not _subres.is_empty():
		var sp := _out_path.get_basename() + ".subres"
		var fs := FileAccess.open(sp, FileAccess.WRITE)
		if fs != null:
			for line in _subres:
				fs.store_line(line)
			fs.close()
			print("; scris %s (se lipeste in ANTETUL Track15.tscn)" % sp)


## Cache pe grila de 0.5 m. Compozitia face ~100.000 de interogari de cota (se
## incearca placi in tot dreptunghiul si se pastreaza doar cele cu sol sub
## luciu), iar fiecare raycast prin `intersect_ray` costa. Terenul are celula de
## ~8 m, deci 0.5 m e cu un ordin de marime sub rezolutia lui: cache-ul nu
## schimba nicio cifra, doar o obtine o data.
var _sol_cache := {}
## Seed distinct per lot de MultiMesh: doua loturi cu acelasi seed ar avea
## aceeasi serie de scari, deci acelasi desen repetat.
var _flock_seed := 0
var _fl_gol := 0
var _fl_panta := 0
var _fl_drum := 0
var _fl_gap := 0
var _fl_prob := 0
var _fl_try := 0
## Piese refuzate fiindca marginea lor ar fi intrat sub 1,5 m de carosabil, pe
## ORICE bucata a traseului (nu doar la fractia lor).
var _refuzate := 0
## Cache pentru `_dist_to_road`, pe grila de 2 m.
var _road_cache := {}
## Cache pentru latimea acostamentului, per indice de punct copt.
var _sh_cache := {}


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	var key := Vector2i(int(round(x * 2.0)), int(round(z * 2.0)))
	if _sol_cache.has(key):
		return float(_sol_cache[key])
	var v := _sol_raw(float(key.x) * 0.5, float(key.y) * 0.5)
	_sol_cache[key] = v
	return v


func _sol_raw(x: float, z: float) -> float:
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
