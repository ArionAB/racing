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

## ALBIA, in coordonate de LUME. DOUA REPRIZE, si impartirea asta e chiar
## livrabilul masuratorii din nota 9.
##
## SUS (`UP_*`, luciu la -28.0): jgheabul larg si putin adanc din fata
## soferului, pe care il vede cap-coada la 0.660-0.675. Fundul lui masurat e
## -27.4..-28.3 pe x de la -260 la -205 si z de la -200 la -168 — o tava, nu un
## canal, deci apa il umple pana unde o opreste terenul.
## JOS (`LOW_*`, luciu la -34.2): bazinul adanc, unde trece estacada trenului.
## Nu se vede de la volan (nota 9), dar exista fiindca acolo CHIAR e cel mai
## jos punct, acolo e trenul, si fara el jgheabul de sus ar fi o balta fara
## aval.
const UP_Y := -28.0
const UP_X0 := -266.0
const UP_X1 := -202.0
const UP_Z0 := -204.0
const UP_Z1 := -166.0
const LOW_Y := -34.2
const LOW_X0 := -212.0
const LOW_X1 := -118.0
const LOW_Z0 := -222.0
const LOW_Z1 := -186.0
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
	_survey()
	if not _survey_only:
		_river()
		_gravel()
		_river_rocks()
		_foam()
		_banks()
		_bank_edge()
		_road_side()
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
var _wet_rocks: Array[Vector4] = []
## Placile de luciu deja asezate, ca spuma sa cada pe apa, nu pe pietris.
var _water_pts: Array[Vector2] = []


## LUCIUL: placi plate de 7 m pe slotul 18 (SEA_DEEP), la cota WATER_Y, numai
## acolo unde terenul REAL e sub ea (nota 5). Conturul iese din teren, nu din
## poligon autorat, deci bancurile de pietris apar singure intre brate.
##
## `snap_to_ground` ramane STINS: apa e un NIVEL, nu o depunere. Pus pe pornit
## ar tara luciul pe fundul albiei si ar disparea sub pietre.
func _river() -> void:
	_reach("Sus", UP_Y, UP_X0, UP_X1, UP_Z0, UP_Z1, 620, 6.0, 77001)
	_reach("Jos", LOW_Y, LOW_X0, LOW_X1, LOW_Z0, LOW_Z1, 480, 7.5, 77003)


## O repriza de luciu: placi plate pe slotul 18, numai unde terenul REAL e sub
## cota ceruta (nota 5). `snap_to_ground` ramane STINS — apa e un NIVEL, nu o
## depunere; pornit, ar tara luciul pe fundul albiei si ar disparea sub pietre.
func _reach(eticheta: String, wy: float, x0: float, x1: float, z0: float,
		z1: float, vrea: int, raza: float, sid: int) -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var pos_d: PackedVector3Array = []
	var yaw_d: PackedFloat32Array = []
	var tries := 0
	while pos.size() + pos_d.size() < vrea and tries < 40000:
		tries += 1
		var x := _rng.randf_range(x0, x1)
		var z := _rng.randf_range(z0, z1)
		# ADANCIMEA CERUTA CRESTE SPRE MARGINEA CASETEI. Fara asta conturul
		# apei e taiat DREPT acolo unde se termina dreptunghiul de cautare, si
		# in captura rundei 2 exact asta s-a vazut: o muchie de rigla in
		# coltul din dreapta-jos, la x = -266. Cu o cerinta care creste de la
		# 0,15 m in mijloc la 1,2 m pe ultimii 12 m de caseta, apa se
		# subtiaza singura si se termina acolo unde terenul chiar urca — deci
		# caseta nu se mai vede.
		var m: float = minf(minf(x - x0, x1 - x), minf(z - z0, z1 - z))
		var need: float = lerpf(1.2, 0.15, clampf(m / 12.0, 0.0, 1.0))
		var g := _sol_real(x, z)
		if g > wy - need:
			continue # mal sau banc de pietris
		# Apa nu curge pe sosea: aceeasi marja ca la restul loturilor.
		if _dist_to_road(x, z) < 3.0:
			continue
		# DOUA SLOTURI, si impartirea e MASURATA, nu de gust. Pe captura rundei
		# 4 apa noastra iesea rgb(63, 141, 146), S = 0.57 — turcoaz de recif.
		# Pe bara, aceleasi zone de apa dau rgb(115, 118, 116) si
		# rgb(140, 130, 110), adica S sub 0.12: un rau de munte plin de aluviuni
		# nu are culoare, are VALOARE. Slotul 6 (#696765, rgb 105/103/101,
		# S 0.04, numit `ASPHALT_EDGE` in paleta) nimereste tinta aproape la
		# bit; slotul 18 SEA_DEEP, cerut de
		# brief §4, ramane pentru gropile ADANCI, unde apa chiar se vede
		# albastra. Adancimea decide, si PRAGUL E MASURAT: la 1,2 m, doua
		# treimi din placi cadeau pe slotul 18 si apa ramanea turcoaz (209
		# gri fata de 411 albastre pe repriza de sus). La 2,2 m raportul se
		# rastoarna, iar albastrul ramane doar in gropi — ceea ce si vrea
		# bara: ochiuri intunecate intre bancuri de pietris palid.
		if wy - g > 2.2:
			pos_d.append(Vector3(x, wy, z))
			yaw_d.append(_rng.randf_range(0.0, TAU))
		else:
			pos.append(Vector3(x, wy, z))
			yaw.append(_rng.randf_range(0.0, TAU))
		_water_pts.append(Vector2(x, z))
	if pos.is_empty() and pos_d.is_empty():
		print("; ATENTIE: repriza %s e goala — luciul e sub tot terenul" % eticheta)
		return
	if not pos.is_empty():
		_disc_flock("F_Luciu%s" % eticheta, Palette.ASPHALT_EDGE, raza, 0.85,
			1.35, pos, yaw, sid)
	if not pos_d.is_empty():
		_disc_flock("F_LuciuAdanc%s" % eticheta, Palette.SEA_DEEP, raza * 0.8,
			0.8, 1.2, pos_d, yaw_d, sid + 1)
	print("; luciu %s (y=%.1f): %d placi mici-adancime + %d in ochiuri, din %d incercari"
		% [eticheta, wy, pos.size(), pos_d.size(), tries])


## PIETRISUL UD: placi plate pe slotul 4 ROCK_DARK (#67421F, rgb 103/66/31,
## H 29, S 0,70, V 0,40) pe BANCURILE dintre brate, adica acolo unde terenul e
## chiar peste cota luciului.
##
## Slotul s-a ales pe doua masuratori, nu din prima. Cu slotul 2 SAND_SHADOW
## (#915D27, V 0,57) zona de rau a iesit H 56 / S 0,39 / V 0,63 fata de
## H 40 / S 0,28 / V 0,50 pe bara: directia era buna (verdele disparuse, albul
## coborase de la 23,2 % la 4,9 %) dar bancul citea PORTOCALIU aprins. Orice
## suprafata orizontala pe soarele de 40 de grade plus expunerea 1,05 se ridica
## in valoare, deci slotul trebuie ales SUB tinta, nu pe ea. ROCK_DARK e cu
## 0,17 mai inchis in V si cu aceeasi nuanta calda.
## (Memoria `rock-dark-nu-pe-bazalt` spune ca slotul asta face rugina pe roca
## vulcanica — aici rugina e chiar ce vrem: pietris de rau ud.)
##
## De ce exista, masurat: zona de rau a rundei 5 avea H 86 (verde) si V 0,73,
## fata de H 40 / V 0,50 pe bara. Verdele nu venea din apa, venea din IARBA
## terenului care se vedea printre pietre — malul unui rau de munte nu e iarba,
## e pietris si nisip ud, si exact asta e culoarea calda din bara. Slotul 9 e
## cel mai apropiat din atlas de tinta rgb(124,114,98) tinand cont ca o
## suprafata orizontala sub soarele de 40 de grade se ridica in valoare. (Slotul
## 9 ar fi fost mai aproape numeric, dar e WOOD_WEATHERED — scanduri si garduri
## — si o mapare de clasa pe lemn l-ar fi luat cu ea.)
##
## Placile sunt LATE (4 m) si putine (390): e o suprafata, nu niste discuri, si
## se suprapun deliberat, ca la crusta de sare de la Serengeti.
func _gravel() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	for rc: Array in [["Sus", UP_Y, UP_X0, UP_X1, UP_Z0, UP_Z1, 240],
			["Jos", LOW_Y, LOW_X0, LOW_X1, LOW_Z0, LOW_Z1, 150]]:
		var wy: float = float(rc[1])
		var got := 0
		var tries := 0
		while got < int(rc[6]) and tries < 26000:
			tries += 1
			var x := _rng.randf_range(float(rc[2]) - 6.0, float(rc[3]) + 6.0)
			var z := _rng.randf_range(float(rc[4]) - 4.0, float(rc[5]) + 4.0)
			var g := _sol_real(x, z)
			# Banc: de la 0,3 m sub luciu (pietris care iese din apa) pana la
			# 2,0 m peste el (plaja dintre apa si vegetatie). Mai sus incepe
			# malul cu iarba, si acolo pietrisul ar fi minciuna.
			if g < wy - 0.3 or g > wy + 2.0:
				continue
			# NU langa drum. Runda 6: o placa de pietris de 4 m a iesit fix pe
			# carosabil, fiindca bancul se intinde pana sub sosea la capatul de
			# est al jgheabului. Pietrisul e decor de albie, deci se cere
			# 14 m liberi pana la marginea drumului (drum + acostament de 4 m).
			if _dist_to_road(x, z) < 14.0:
				continue
			# Ridicarea: placa e plata, malul e in panta. Se ia caderea REALA
			# pe raza placii, ca marginea sa nu intre in pamant (aceeasi
			# corectie ca la crusta de sare, unde 193 din 420 de placi erau
			# invizibile fara ea).
			var rr := 4.0
			var lo := g
			for da: float in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
				lo = minf(lo, _sol_real(x + cos(da) * rr, z + sin(da) * rr))
			var lift: float = clampf(g - lo, 0.0, 1.6) + 0.10
			pos.append(Vector3(x, g + lift, z))
			yaw.append(_rng.randf_range(0.0, TAU))
			sc3.append(Vector3(_rng.randf_range(0.7, 1.4), 1.0,
				_rng.randf_range(0.7, 1.4)))
			got += 1
	if pos.is_empty():
		print("; ATENTIE: pietris gol")
		return
	_disc_flock("F_Pietris", Palette.ROCK_DARK, 4.0, 1.0, 1.0, pos, yaw,
		77005, sc3)
	print("; pietris de banc: %d placi" % pos.size())


## BOLOVANII UZI: piatra in albie si pe bancuri, pe AMANDOUA reprizele. Sunt
## structura repezisului — fara ei apa e o pata, cu ei e curent rupt. Trei
## marimi, cel mare mai rar, toate ca MultiMesh (un desen per lot).
##
## COLIZIUNEA: niciuna. MultiMesh nu produce corp fizic, si asta e corect aici —
## totul e sub plasa de repunere; un corp acolo ar fi doar ceva de care sa se
## agate masina care oricum va fi repusa.
##
## Repriza de SUS primeste de doua ori mai multa piatra la aceeasi suprafata:
## e cea pe care o vede soferul (nota 9), iar acolo trebuie sa se citeasca
## repezis, nu lac.
func _river_rocks() -> void:
	var reaches := [
		["Sus", UP_Y, UP_X0, UP_X1, UP_Z0, UP_Z1, 1.0],
		["Jos", LOW_Y, LOW_X0, LOW_X1, LOW_Z0, LOW_Z1, 0.55],
	]
	# RUNDA 2, MASURAT PE CAPTURA (F_r2_0.66.png / F_r2_0.67.png). Prima
	# incercare a scalat `moss_boulder_b` pana la 2,6 si i-a mai dat 1,0-1,35
	# pe lateral: 1,957 m x 2,6 x 1,35 = 6,9 m latime. La 30-40 m de camera un
	# bolovan de 7 m subintinde ~11 grade si acopera un sfert din inaltimea
	# cadrului — si fiindca `moss_boulder_*` are 12-39 % din vertecsi pe slotul
	# 12 (CACTUS_GREEN, masuratori §2), la marimea aia muschiul nu mai e un
	# accent, e toata piesa. Ce a iesit in captura: perne verzi de varza, nu
	# piatra uda.
	#
	# Marimile de acum vin din bara, citite ca raport fata de latimea albiei
	# (~30 m): cele mai mari pietre din repezis au 2-3 m, majoritatea sub 1,5 m,
	# si sunt CENUSII cu muschi pe capac. Scara maxima scade deci de la 2,6 la
	# 1,15 (b -> 2,25 m), de la 1,9 la 0,85 (c -> 2,61 m), de la 2,8 la 1,6
	# (a -> 1,19 m), iar intinderea laterala de la 1,35 la 1,15.
	# In schimb sunt MAI MULTE: la 2 m in loc de 6, aceeasi suprafata de piatra
	# cere de trei ori mai multe bucati, si abia asa se citeste albie cu pietre
	# in loc de cativa bolovani.
	var lots := [
		["moss_boulder_b", 420, 0.45, 1.15],
		["moss_boulder_c", 150, 0.35, 0.85],
		["moss_boulder_a", 620, 0.6, 1.6],
	]
	for rc: Array in reaches:
		var eticheta: String = String(rc[0])
		var wy: float = float(rc[1])
		var dens: float = float(rc[6])
		for lot: Array in lots:
			var mdl: String = String(lot[0])
			var pos: PackedVector3Array = []
			var yaw: PackedFloat32Array = []
			var sc3: Array[Vector3] = []
			var tries := 0
			var want := int(float(lot[1]) * dens)
			while pos.size() < want and tries < 26000:
				tries += 1
				var x := _rng.randf_range(float(rc[2]) - 4.0, float(rc[3]) + 4.0)
				var z := _rng.randf_range(float(rc[4]) - 3.0, float(rc[5]) + 3.0)
				var g := _sol_real(x, z)
				# Intre 2.2 m sub luciu si 1.2 m peste el: piatra din albie si
				# de pe banc. Mai jos nu se vede, mai sus e deja mal uscat.
				if g < wy - 2.2 or g > wy + 1.2:
					continue
				# Acelasi motiv ca la maluri: albia de sus ajunge pana sub
				# sosea, iar un bolovan pe carosabil e un obstacol invizibil
				# pentru AI (nu are corp — e MultiMesh) si o minciuna vizuala.
				if _dist_to_road(x, z) < 3.0:
					continue
				var sc: float = _rng.randf_range(float(lot[2]), float(lot[3]))
				# Bolovan de rau: turtit pe verticala de apa, nu bulgare.
				sc3.append(Vector3(sc * _rng.randf_range(1.0, 1.15), sc * 0.72,
					sc * _rng.randf_range(1.0, 1.15)))
				# Ingropat un sfert: o piatra din albie nu sta PE luciu, iese
				# din el.
				pos.append(Vector3(x, g - HEIGHT[mdl] * sc * 0.22, z))
				yaw.append(_rng.randf_range(0.0, TAU))
				if g < wy + 0.4:
					_wet_rocks.append(Vector4(x, g, z, wy))
			if pos.is_empty():
				continue
			_flock_seed += 1
			# CLASA DE PIATRA, nu atlasul. `moss_boulder_*` are 12-39 % din
			# vertecsi pe slotul 12 CACTUS_GREEN (masuratori §2), adica
			# muschi — si in captura rundei 2 exact muschiul a facut din albie
			# un camp de varza verde. Un material de clasa inlocuieste tot
			# nodul, deci scoate muschiul din ecuatie.
			#
			# CARE clasa: masurat pe captura, nu ales din lista. Prima
			# incercare a fost `inca_stone`, fiindca exista deja pe pista si
			# ar fi costat zero materiale — dar tenta ei e (1.0, 0.831,
			# 0.677), adica granit CALD, si in F_r3_0.67.png albia a iesit un
			# camp de pietricele bej: plaja, nu repezis. `granite` are tenta
			# (0.520, 0.578, 0.700), cenusiu-rece si mai inchis — exact piatra
			# uda din bara. Costa UN material (garda e la 17 din 38, deci
			# incape) si e deja folosita la Serengeti, deci nu e o dala noua.
			#
			# Muschiul nu dispare din POI: bolovanii de pe BUZA drumului
			# (`_bank_edge`) raman pe atlas, si acolo se vad de aproape.
			_model_flock("F_Pietre%s_%s" % [eticheta, mdl], RES[mdl], pos, yaw,
				sc3, 77200 + _flock_seed, "granite")
			print("; pietre %s %s: %d din %d incercari" % [eticheta, mdl, pos.size(), tries])
	print("; %d pietre UDE (ancore de spuma)" % _wet_rocks.size())


## SPUMA: doua mecanisme, fiindca „repezisuri albe" nu inseamna pete albe.
##
## (a) DARELE din aval de fiecare piatra uda: 3-6 placi mici insirate pe
## directia curentului (spre EST, +x — raul coboara spre Urubamba), imprastiate
## tot mai lat pe masura ce se departeaza de piatra. Asta e ce face curentul sa
## se citeasca drept curent, si nu un covor de confetti.
## (b) Un covor rarefiat pe restul luciului, ca albia sa nu fie neagra intre
## pietre. Pe repriza de SUS, de doua ori mai des: acolo se uita soferul.
## (c) CASCADA dintre reprize: pragul de la x ~ -205, unde terenul cade de la
## -28 la -34 in 10 m, primeste o banda compacta de spuma. E singura legatura
## vizibila dintre jgheabul din fata si bazinul de jos; fara ea apa de sus e o
## balta fara aval.
##
## Placile sunt MICI (1.6 m fata de cei 6-7.5 m ai luciului): la 40-70 m de
## sofer o placa alba de 7 m ar fi o dala, una de 1.6 m e o creasta de val.
func _foam() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	# CURENTUL curge spre EST (+x): raul coboara spre Urubamba, si toate cotele
	# masurate scad in sensul asta (-27,4 la x=-205, -36,4 la x=-175). Deci
	# crestele de spuma sunt lungi pe X si inguste pe Z, cu abateri mici de
	# yaw — nu discuri rotite aiurea.
	# (a) dare in aval de pietre
	for r in _wet_rocks:
		if _rng.randf() > 0.09:
			continue
		var wy: float = r.w
		var cnt := _rng.randi_range(1, 3)
		for k in cnt:
			var t := float(k) + _rng.randf()
			var px := r.x + t * _rng.randf_range(1.4, 2.4)
			var pz := r.z + _rng.randf_range(-0.9, 0.9) * (1.0 + t * 0.5)
			if _sol_real(px, pz) > wy - 0.05 or _dist_to_road(px, pz) < 3.0:
				continue
			pos.append(Vector3(px, wy + 0.10, pz))
			yaw.append(_rng.randf_range(-0.35, 0.35))
			# Dara se subtiaza si se lungeste pe masura ce se departeaza.
			# RUNDA 4: cu 1,6-2,8 (plus t) pe X si raza de 1,15 m, o dara iesea
			# de 4-7 m lungime si citea ca o zgarietura alba trasa cu rigla.
			# O creasta de repezis are ~2 m; scara pe X coboara deci la
			# 0,9-1,7 si cresterea cu distanta la 0,18.
			sc3.append(Vector3(_rng.randf_range(0.9, 1.7) + t * 0.18, 1.0,
				_rng.randf_range(0.35, 0.60)))
	var wake := pos.size()
	# (b) covor pe fiecare luciu
	# RUNDA 2, MASURAT PE CAPTURA. Covorul de 620 + 300 de placi de 1,6 m peste
	# ~1.500 m2 de luciu se SUPRAPUNEA: 920 x pi x 1,6^2 = 7.400 m2, adica
	# cinci straturi peste fiecare punct de apa. In captura albia iesea o
	# PANZA alba continua, nu repezisuri — acelasi defect ca podeaua de ceata
	# de la Serengeti POI D (`mist-patch e o podea opaca`). Repezisul din bara
	# are apa INCHISA intre benzile albe; fara apa inchisa nu e repezis, e
	# zapada. Covorul coboara deci la 150 + 90, adica ~1,3 straturi, iar
	# structura o dau darele si cascada, care stau unde apa CHIAR sparge.
	for rc: Array in [["Sus", UP_Y, UP_X0, UP_X1, UP_Z0, UP_Z1, 22],
			["Jos", LOW_Y, LOW_X0, LOW_X1, LOW_Z0, LOW_Z1, 14]]:
		var wy2: float = float(rc[1])
		var tries := 0
		var got := 0
		while got < int(rc[6]) and tries < 26000:
			tries += 1
			var x := _rng.randf_range(float(rc[2]), float(rc[3]))
			var z := _rng.randf_range(float(rc[4]), float(rc[5]))
			if _sol_real(x, z) > wy2 - 0.4 or _dist_to_road(x, z) < 3.0:
				continue
			pos.append(Vector3(x, wy2 + 0.08, z))
			yaw.append(_rng.randf_range(-0.5, 0.5))
			sc3.append(Vector3(_rng.randf_range(0.8, 1.5), 1.0,
				_rng.randf_range(0.30, 0.55)))
			got += 1
	var carpet := pos.size() - wake
	# (c) cascada de prag intre reprize: aici apa cade, deci crestele sunt
	# TRANSVERSALE pe curent (late pe Z, scurte pe X) — o treapta de cascada,
	# nu o dara.
	var casc := 0
	var cz := UP_Z0
	while cz <= UP_Z1:
		var cx := -212.0
		while cx <= -196.0:
			var g := _sol_real(cx, cz)
			if g < UP_Y + 0.2 and g > LOW_Y - 0.5 and _rng.randf() < 0.14 					and _dist_to_road(cx, cz) >= 3.0:
				pos.append(Vector3(cx + _rng.randf_range(-1.2, 1.2),
					g + 0.25, cz + _rng.randf_range(-1.4, 1.4)))
				yaw.append(_rng.randf_range(-0.25, 0.25))
				sc3.append(Vector3(_rng.randf_range(0.5, 0.9), 1.0,
					_rng.randf_range(1.5, 2.6)))
				casc += 1
			cx += 1.6
		cz += 1.6
	if pos.is_empty():
		print("; ATENTIE: spuma goala")
		return
	_disc_flock("F_Spuma", Palette.FOAM_WHITE, 0.85, 0.45, 1.0, pos, yaw,
		77002, sc3)
	print("; spuma: %d placi (%d dare + %d covor + %d cascada)"
		% [pos.size(), wake, carpet, casc])


## MALURILE raului: bambus si ferigi arborescente pe malurile fiecarei reprize,
## plus queñual (polylepis) mai sus pe taluz. In bara copacii sunt INGHESUITI pe
## mal — masa verde inchisa care margineste albia pe toata lungimea, nu
## exemplare razlete.
##
## RUNDA 1, a doua masuratoare: prima versiune cauta pe BENZI de z fixe si a
## iesit cu 18 piese pe tot malul, fiindca taluzul urca de la -34 la -25 in 8 m
## orizontali — banda „0..3,4 m peste luciu" e lata de doi metri si cade unde
## nimereste. Cautarea se face acum pe COTA, nu pe z: se pleaca de la mijlocul
## albiei, se baleiaza spre mal si se opreste la prima cota din fereastra
## ceruta. Asta urmareste conturul real, oricat de strans ar fi taluzul.
##
## Coliziunea e `trunk` (raport raza/semi-latime 0,40 la bambus si 0,15 la
## feriga, masuratori §4), dar totul e sub plasa de repunere.
func _banks() -> void:
	for rc: Array in [["Sus", UP_Y, UP_X0, UP_X1, UP_Z0, UP_Z1],
			["Jos", LOW_Y, LOW_X0, LOW_X1, LOW_Z0, LOW_Z1]]:
		var eticheta: String = String(rc[0])
		var wy: float = float(rc[1])
		var zc: float = (float(rc[4]) + float(rc[5])) * 0.5
		# RUNDA 2: pe repriza de SUS prima versiune a scos 19 piese pe tot
		# malul, fata de 58 pe cea de jos. Cauza masurata: tava de sus e larga
		# si lina, deci fereastra de cota (de exemplu „0..2,5 m peste luciu")
		# se satisface pe o banda de zeci de metri, iar cautarea se opreste la
		# PRIMA potrivire — adica toate piesele cad pe acelasi inel subtire, si
		# pasul de 4 m pe x le rareste. Reparatia nu e „mai multa
		# probabilitate", e mai multe FERESTRE: fiecare mal primeste trei
		# inele de cota in loc de unul, cu pas mai mic. Asta imbraca malul in
		# adancime (tufa la apa, feriga peste ea, copac in spate), adica exact
		# masa verde inghesuita din bara.
		for spec: Array in [
				# [spre_nord?, model, h_min, h_max, pas, prob, y_min, y_max]
				[true, "bamboo_clump", 3.8, 6.2, 3.0, 0.90, 0.0, 0.8],
				[true, "bamboo_clump", 3.4, 5.6, 3.5, 0.85, 1.0, 2.2],
				[true, "tree_fern", 2.6, 4.2, 4.0, 0.80, 0.4, 1.6],
				[true, "tree_fern", 2.4, 3.8, 5.0, 0.70, 2.0, 3.6],
				[true, "polylepis_a", 3.2, 4.8, 6.0, 0.70, 2.5, 5.0],
				[true, "polylepis_b", 5.5, 8.0, 9.0, 0.65, 3.5, 8.0],
				[false, "bamboo_clump", 3.5, 5.8, 3.2, 0.88, 0.0, 0.8],
				[false, "bamboo_clump", 3.2, 5.2, 3.8, 0.82, 1.0, 2.2],
				[false, "tree_fern", 2.4, 3.8, 4.5, 0.75, 0.4, 1.6],
				[false, "tree_fern", 2.2, 3.4, 5.5, 0.65, 2.0, 3.6],
				[false, "polylepis_a", 3.4, 5.2, 6.5, 0.70, 2.5, 5.0],
				[false, "polylepis_b", 5.5, 8.0, 9.0, 0.65, 3.5, 8.0],
			]:
			var spre_nord: bool = bool(spec[0])
			var mdl: String = String(spec[1])
			var pos: PackedVector3Array = []
			var yaw: PackedFloat32Array = []
			var sc3: Array[Vector3] = []
			var x := float(rc[2]) - 8.0
			while x < float(rc[3]) + 8.0:
				x += float(spec[4]) + _rng.randf_range(-1.2, 1.2)
				if _rng.randf() > float(spec[5]):
					continue
				var dz: float = 1.0 if spre_nord else -1.0
				var z := zc
				var hit := false
				var want := _rng.randf_range(float(spec[6]), float(spec[7]))
				for _i in 110:
					z += dz * 0.8
					if z > float(rc[5]) + 16.0 or z < float(rc[4]) - 16.0:
						break
					if _sol_real(x, z) - wy >= want:
						hit = true
						break
				if not hit:
					continue
				# Jitter lateral, ca sirul sa nu fie o linie trasa cu rigla.
				z += dz * _rng.randf_range(-1.6, 2.4)
				var g := _sol_real(x, z)
				if g < wy - 0.2:
					continue
				# NU IN DRUM. Loturile de MultiMesh nu trec prin `_place`, deci
				# n-aveau niciun test de carosabil — si cautarea pe cota, care
				# merge dinspre albie SPRE mal, urca fix pe umarul soselei
				# cand malul de nord al jgheabului e chiar sub ea. In
				# F_r8_0.67.png asta s-a vazut ca o feriga si un bambus in
				# mijlocul benzii palide (`F_MalSus_*_N`, z pana la -160,8,
				# cu soseaua la z = -166,9). Marja e 3 m de la marginea
				# acostamentului REAL.
				if _dist_to_road(x, z) < 3.0:
					continue
				var h := _rng.randf_range(float(spec[2]), float(spec[3]))
				var sc := _scale_for(mdl, h)
				pos.append(Vector3(x, g, z))
				yaw.append(_rng.randf_range(0.0, TAU))
				sc3.append(Vector3(sc, sc, sc))
			if pos.is_empty():
				continue
			_flock_seed += 1
			# Numele poarta si indicele inelului: doua specificatii impart
			# acelasi model si acelasi mal, iar doua noduri cu acelasi nume
			# sub acelasi parinte sunt o eroare de .tscn.
			_model_flock("F_Mal%s_%s_%s%d" % [eticheta, mdl,
				"N" if spre_nord else "S", _flock_seed], RES[mdl], pos, yaw,
				sc3, 77300 + _flock_seed)
			print("; mal %s %s (%s): %d piese" % [eticheta, mdl,
				"nord" if spre_nord else "sud", pos.size()])


## BUZA MALULUI DE SUB SOSEA: bolovani pe taluzul de 45 de grade, intre drum si
## apa. Rostul lor e legatura vizuala — fara ei carosabilul se termina in iarba
## si apa apare din nimic la 30 m mai jos, adica doua lumi lipite.
##
## Astia sunt NODURI, nu MultiMesh, si au hull: cad in banda de 8-16 m de
## muchie, adica exact unde ajunge o masina scapata — sunt primul lucru care o
## opreste inainte de plasa de repunere. De aia sunt si putini (16) si
## masurati cu `_place`, care striga daca intra in banda.
func _bank_edge() -> void:
	var f := 0.6555
	var k := 0
	while f < 0.6880:
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
		_place(mdl, "FBuza", f, 1.0, _rng.randf_range(5.5, 13.0),
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
	# --- partea dinspre rau: doar piese joase, ca sa nu astupe albia ---
	for leg2: Array in [[0.6560, 0.6870, 1.0], [0.6930, 0.7300, -1.0]]:
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
func _station() -> void:
	var sx := -232.0
	var sz := -186.0
	var g := _sol_real(sx, sz)
	# SCARA: 2,833 m livrat, 4,2 m aici. Gara sta la ~50 m de sofer, peste apa;
	# la inaltimea din GLB ar subintinde 3 grade si s-ar pierde intre bolovanii
	# de 2 m. La 4,2 m ramane „cladire mica" fata de un drum de 16 m latime, dar
	# se citeste ca acoperis si ziduri.
	_place_world("inca_house_b", "FGara", Vector3(sx, g + 0.15, sz), 0.42,
		_scale_for("inca_house_b", 4.2), "hull")
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
			_scale_for("tent_a", 2.4), "hull")


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
	var x0: float = minf(UP_X0, LOW_X0) - 10.0
	var x1: float = maxf(UP_X1, LOW_X1) + 10.0
	var z0: float = minf(UP_Z0, LOW_Z0) - 10.0
	var z1: float = maxf(UP_Z1, LOW_Z1) + 6.0
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
	var top: float = UP_Y + 1.4
	if road_lo < INF:
		top = minf(top, road_lo - 2.5)
		print("; plasa: cea mai joasa sosea in amprenta e %.1f -> plafon %.1f" % [road_lo, top])
	if top <= LOW_Y + 0.5:
		print("; ATENTIE: nu ramane plafon peste apa (%.1f <= %.1f); NU emit plasa"
			% [top, LOW_Y + 0.5])
		return
	var bottom := LOW_Y - 14.0
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
func _dist_to_road(x: float, z: float) -> float:
	# Cache pe grila de 2 m: apelul e O(numarul de puncte coapte) = 1111
	# iteratii, iar `_gravel` il cheama de zeci de mii de ori. 2 m e cu mult sub
	# marja de 14 m pe care o pazeste, deci cache-ul nu schimba nicio decizie.
	var key := Vector2i(int(round(x * 0.5)), int(round(z * 0.5)))
	if _road_cache.has(key):
		return float(_road_cache[key])
	var px := float(key.x) * 2.0
	var pz := float(key.y) * 2.0
	var lo := INF
	for j in _track.baked.size():
		var bp := _track.baked[j]
		lo = minf(lo, Vector2(bp.x - px, bp.z - pz).length()
			- _track.width_at_index(j) - _shoulder(j))
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
	var g := _sol_real(q.x, q.z)
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
