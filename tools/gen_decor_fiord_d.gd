extends Node
## Generator de decor MANUAL pentru POI D — CHASM SI PADUREA DE MUSCHI
## (Track16, Fiordland, frac 0.323-0.46, `ZoneD_Chasm`).
## Ca la Serengeti POI D (gen_decor_ser_d.gd): nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track16.tscn sub
## `DecorManual/ZoneD_Chasm`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordD.tscn -- \
##       --out=C:/cale/zoneD.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului si nu genereaza nimic.
##
## BARA (bara_poi_D.png): padure de fag cu trunchiuri negre subtiri si
## coronament in etaje (cerul printre ele), bolovani inveliti in muschi,
## raul alb sapat in marmite, podetul de scanduri cu balustrada de lemn,
## doi kea pe un ciot. Bara e LOOK, nu layout.
##
## Contract (fiordland_poi_gauntlet.md §D):
## - drumul intra intr-o vale laterala (custom_ravines index 1: 0.341-0.444,
##   fund +7, latime 25 -> semi-latime rapa 12.5 fata de ax);
## - podetul 0.406-0.424 (custom_step_ranges) -- tablia e drumul, GLB-ul are
##   doar balustradele; podetul e PE CURBA (sagita 2,16 m / 38,4 m) -- fundatia
##   a scos `chasm_bridge_rail` (taia tablia la capete daca e drept pe 40 m).
##   Decizie RUNDA 1: doua jumatati de 20 m rotite pe TANGENTA locala (nu pe
##   coarda intregului pod), fiecare validata individual pe garzi -- scrisa in
##   raport, nu strecurata (vezi jos, `_bridge_rail`).
## - scurtatura `ScurtaturaChasm` 0.366-0.462, branch_half_width 3.2 m: decorul
##   ii da PERETI (trunchiuri, bolovani, muschi) ca sa citeasca "drum vechi",
##   dar AI-UL NU VEDE DECOR STATIC -- niciun trunchi/bolovan cu coliziune pe
##   cei 3.2 m de banda a scurtaturii (memoria obstacol-pe-drum-poate-fi-gimmick).
## - `torrent_chute` montat la fundatie, paralel cu banda, fata la 4.5 m de
##   axa benzii -- POI D nu il muta, doar verifica pe captura --torrent-at.
## - fagi 200+: sub 1000 de piese, deci noduri in DecorManual (nu MultiMesh
##   inca), per memoria decor-in-masa-cere-multimesh (prag ~1000).
## - stump + kea x2 pe mal, langa rau.
##
## Memorii aplicate: aranjamentul-bate-numarul (fara grila, jitter>=0.5*pas,
## yaw variat, densitate crescand spre rau), podeaua-vaii-e-banda-lipsa
## (albie cu bolovani, nu podea goala), particule-muchia-nu-numarul (ceata de
## rau -- nu adaugata aici, e din cod/RainCycle), terrain-mesh-y-extrapoleaza
## (cota din raycast pe TerrainBody real), tscn-transform-e-pe-randuri,
## verifica-cu-parametrii-lui (camera joc: 10m sus, 12.5m spate, fov 68).

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneD_Chasm"

## Limitele zonei (brief: frac 0.323-0.46; rapa reala 0.341-0.444).
const F_IN := 0.323
const F_OUT := 0.460
## Padurea deasa incepe/se termina putin inainte/dupa rapa, ca tranzitia sa
## fie linie continua (ca la Serengeti POI D).
const F_DENSE_IN := 0.335
const F_DENSE_OUT := 0.450

## Podetul (custom_step_ranges) -- tablia e drumul; balustradele merg deasupra.
const BRIDGE_IN := 0.406
const BRIDGE_OUT := 0.424
## `chasm_bridge_rail` masoara 40.48 m pe local Z (axa lunga, masurat cu
## tools/probe_rail_aabb.gd sters dupa folosire -- Rail_L/Rail_R la local Z
## +-20.24 m). O jumatate de pod are ~20.24 m -- scara 0.5 pe local Z aduce
## piesa la lungimea corecta a unei jumatati. FOST: RUNDA 1 pretindea
## "scurtata la jumatate" dar scria scara 1.0 (niciodata scurtata de fapt) --
## cele doua balustrade INTREGI de 40 m se suprapuneau/incrucisau vizibil
## langa mijlocul podului (vezi comentariul _bridge_rail).
const BRIDGE_HALF_LEN_SCALE := 0.5

## id-urile ext_resource deja inregistrate in Track16.tscn (fundatie + comune).
const RES := {
	"beech_a": "s_beech_a",
	"beech_b": "s_beech_b",
	"beech_c": "s_beech_c",
	"beech_dead": "s_beech_dead",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"chasm_rock": "s_chasm_rock",
	"chasm_bridge_rail": "s_chasm_bridge_rail",
	"stump": "s_stump",
	"kea": "s_kea",
	"tree_fern": "s_tree_fern",
	"fern_cluster": "s_fern_cluster",
	"driftwood": "s_driftwood",
	"guard_rock": "s_guard_rock",
	"tussock_clump": "s_tussock_clump",
}

## Inaltimea reala (m), din fiordland_masuratori.md / kit comun MP.
## NOTA: fagii sunt SUB cota ceruta in brief (6.1/8.8/11.2 fata de 8/11/14) --
## decizia de scara s-a luat o data la fundatie/vitrina, nu se repeta aici
## (memoria plafon-masurat-nu-presupus + contractul §"Piese comune").
const HEIGHT := {
	"beech_a": 7.030, "beech_b": 10.189, "beech_c": 13.501, "beech_dead": 8.515,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"chasm_rock": 2.500, "chasm_bridge_rail": 1.400,
	"stump": 0.828, "kea": 0.490, "tree_fern": 3.306,
	"driftwood": 0.384, "guard_rock": 0.585, "tussock_clump": 0.804,
}

## Raza de DEGAJARE la sol (m) la scara 1: fagii au coliziune `trunk`
## (cilindru pe trunchi -- masuratori: 0.318/0.242/0.216 * inaltime),
## restul `hull` (jumatatea laturii mari a AABB) sau `none` (contract).
const BASE_R := {
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03, "beech_dead": 0.68,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"chasm_rock": 3.02, "stump": 0.69,
	"guard_rock": 0.35, "tussock_clump": 0.05,
	"kea": 0.0, "tree_fern": 0.5, "fern_cluster": 0.4, "driftwood": 2.0,
}
## Raza de COLT (semi-diagonala AABB * scara, nu BASE_R -- BASE_R e doar
## jumatatea laturii MARI, corecta doar cand niciun colt al piesei nu iese mai
## departe pe axa laterala decat atat). La un yaw ARBITRAR un colt poate iesi
## mai departe: masurat direct din mesh (tools/dbg_aabb_d.gd, acelasi tipar ca
## CORNER_R din gen_decor_fiord_f.gd):
##   chasm_rock:     semi-laturi (2.999, 2.358) -> semi-diagonala 3.816
##   moss_boulder_a: semi-laturi (0.423, 0.369) -> semi-diagonala 0.562
##   moss_boulder_b: semi-laturi (1.241, 1.177) -> semi-diagonala 1.710
##   moss_boulder_c: semi-laturi (2.104, 1.688) -> semi-diagonala 2.697
##   tussock_clump:  semi-laturi (0.342, 0.344) -> semi-diagonala 0.485
##                   (BASE_R 0.05 masura alt gabarit, ~10x sub amprenta reala
##                   -- gasit cu garda podetului: 7 piese ramasesera la
##                   9.6-9.8 m, sub pragul de 10 m, dupa primul fix bazat pe
##                   BASE_R/guard_rock singur)
##   guard_rock:     semi-laturi (0.591, 0.351) -> semi-diagonala 0.688
## Folosita DOAR pentru garda podetului (_bridge_gap_floor), nu schimba
## plasarea existenta in restul POI-ului D.
const CORNER_R := {
	"chasm_rock": 3.816,
	"moss_boulder_a": 0.562,
	"moss_boulder_b": 1.710,
	"moss_boulder_c": 2.697,
	"tussock_clump": 0.485,
	"guard_rock": 0.688,
}

## Raza COROANEI (m), pentru testul camerei (coroana n-are voie sub 4 m de ax).
const CROWN_R := {
	"beech_a": 2.55, "beech_b": 3.18, "beech_c": 4.78, "beech_dead": 1.64,
}
const CROWN_Y := {
	"beech_a": 0.72, "beech_b": 0.74, "beech_c": 0.74, "beech_dead": 0.55,
}
## Modul de coliziune declarat in world_prop.gd (contract).
const MODE := {
	"beech_a": "trunk", "beech_b": "trunk", "beech_c": "trunk",
	"beech_dead": "trunk",
	"chasm_bridge_rail": "none", "tree_fern": "hull", "fern_cluster": "none",
	"kea": "none", "guard_rock": "hull", "tussock_clump": "hull",
	"driftwood": "hull", "stump": "hull",
	"moss_boulder_a": "hull", "moss_boulder_b": "hull", "moss_boulder_c": "hull",
	"chasm_rock": "hull",
}

const TRI := {
	"beech_a": 228, "beech_b": 292, "beech_c": 292, "beech_dead": 136,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"chasm_rock": 416, "chasm_bridge_rail": 336, "stump": 68, "kea": 682,
	"tree_fern": 768, "fern_cluster": 120, "driftwood": 52, "guard_rock": 72,
	"tussock_clump": 144,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _skipped_scurt := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _tri := 0
var _total_len := 2159.2
var _sun_to := Vector3(0.54, 0.6, 0.54)
## Puncte GLOBALE de pe curba REALA a ScurtaturaChasm (Path3D separat, care
## PLEACA TANGENT de traseul principal si merge zeci de metri pe langa el --
## nu e o banda paralela la distanta fixa de axa principala). RUNDA 1: prima
## incercare a exclus coliziunea dupa fractia PE TRASEUL PRINCIPAL (SCURT_IN/
## SCURT_OUT); ProbeLaneClear a aratat 445 probe blocate pe banda scurtaturii
## fiindca fractia principala nu corespunde geometric cu unde e de fapt
## scurtatura in spatiu -- piese "in afara" intervalului de fractie cadeau
## totusi pe traiectoria ei reala. Fix: se esantioneaza direct curba proprie
## (`ScurtaturaChasm.curve.get_baked_points()`, transformata global) si orice
## piesa cu coliziune reala se respinge daca ajunge la mai putin de
## `branch_half_width + raza ei` de cel mai apropiat punct de pe ACEASTA curba.
var _scurt_pts: PackedVector3Array = PackedVector3Array()
var _scurt_half := 3.2
## RUNDA 1, a doua trecere: ProbeLaneClear (masina la +/-half_local/3 pe
## RUTA PROPRIE a scurtaturii) tot lovea piese la 5.2-7.3 m de curba proprie
## esantionata -- peste marja initiala (_scurt_half+r+1.0 ~= 4-5 m). Cauza nu
## s-a putut confirma din acest worktree fara sa modific probe_lane_clear.gd
## (latimea foloseste `track.width_at_index` cu indexul RUTEI, nu al
## traseului principal -- posibil o latime mai mare pe segmentul de tranzitie
## decat cei 3,2 m declarati). Raspunsul sigur, fara sa ating sonda sau
## geometria pistei: marja de siguranta creste generos (8 m) pentru orice
## piesa cu coliziune reala, verificat empiric ca acopera cazul cel mai rau
## masurat (7,3 m). Vezi raportul rundei pentru nota catre coordonator.
const SCURT_SAFETY := 8.0


func _find_scurt_curve() -> void:
	var node := _track.get_node_or_null("ScurtaturaChasm")
	if node == null or not (node is Path3D):
		print("; ATENTIE: ScurtaturaChasm nu a fost gasit -- refuzul de coliziune pe scurtatura e DEZACTIVAT")
		return
	var path3d := node as Path3D
	if "branch_half_width" in path3d:
		_scurt_half = float(path3d.get("branch_half_width"))
	var curve := path3d.curve
	if curve == null:
		return
	var local_pts := curve.get_baked_points()
	var xf := path3d.global_transform
	_scurt_pts.resize(local_pts.size())
	for i in local_pts.size():
		_scurt_pts[i] = xf * local_pts[i]
	print("; scurtatura reala: %d puncte, half %.2f m (curba proprie, nu fractie pe traseul principal)"
		% [_scurt_pts.size(), _scurt_half])


## Distanta (XZ) de la `pos` la cel mai apropiat punct de pe curba REALA a
## scurtaturii. INF daca nu exista curba (refuzul se dezactiveaza sigur).
func _dist_to_scurt(pos: Vector3) -> float:
	if _scurt_pts.is_empty():
		return INF
	var best := INF
	for q in _scurt_pts:
		var d := Vector2(pos.x - q.x, pos.z - q.z).length()
		if d < best:
			best = d
	return best


func _ready() -> void:
	var _survey_bridge := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
		elif a == "--survey-bridge":
			_survey_only = true
			_survey_bridge = true
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
	_rng.seed = 160406
	_find_scurt_curve()
	_survey()
	if _survey_bridge:
		_survey_bridge_fn()
	if not _survey_only:
		_bridge_rail()
		_riverbed()
		_near_row()
		_second_row()
		_backdrop()
		_moss_boulders()
		_understory()
		_stump_and_kea()
		_edges()
		# RUNDA 2: adaugata LA COADA, dupa toate functiile care consuma _rng
		# pentru padure -- inserata mai devreme (intre _riverbed si _near_row)
		# a schimbat secventa aleatoare a TUTUROR copacilor plasati dupa ea,
		# rarind vizibil padurea la frac 0.40 si dezvaluind balustrada
		# indepartata a podului ca "X" pe carosabil din unghiul de camera de
		# acolo (regresie descoperita pe captura, nicio piesa noua nu era de
		# fapt gresit orientata -- copacii care o ascundeau anterior lipseau).
		_bridge_canyon_dressing()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var sun := _find_sun(_track)
	var shadow := Vector3.ZERO
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		_sun_to = -dir
		shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, shadow.x, shadow.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        curb(1/m)  sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.01
	while f <= F_OUT + 0.01:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %+8.4f  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, _curv(i), " ".join(cols),
			s.dot(shadow)])
		f += 0.005


## RUNDA 2, nota (2) a coordonatorului: cota albiei fata de drum la +/-6/10/15 m
## EXACT (nu +/-8/15/25/40 ca in _survey()), pe segmentul podetului (0.400-0.424),
## ca sa se decida cu dovada daca valea sub pod e vizibila sau ingropata.
func _survey_bridge_fn() -> void:
	var n := _track.baked.size()
	print("; --- survey pod (partea +, side=1 conform custom_ravines index1) ---")
	print("; frac    y_drum  sol la +6     +10    +15   | -6     -10    -15")
	var f := 0.398
	while f <= 0.426:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var cols: Array[String] = []
		for off: float in [6.0, 10.0, 15.0, -6.0, -10.0, -15.0]:
			var q := p + s * off
			cols.append("%+6.2f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  %6.2f  %s" % [f, p.y, "  ".join(cols)])
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


func _step(meters: float) -> float:
	return meters / _total_len


## Cat de "in padure/rapa" e fractia: 0 la margini, 1 in interior.
func _density(f: float) -> float:
	if f < F_IN or f > F_OUT:
		return 0.0
	var a := clampf((f - F_IN) / (F_DENSE_IN - F_IN), 0.0, 1.0)
	var b := clampf((F_OUT - f) / (F_OUT - F_DENSE_OUT), 0.0, 1.0)
	return minf(a, b)




# ------------------------------------------------------------------ podetul
## RUNDA 1: decizia de asset scrisa in raport, nu strecurata.
##
## Contract: `chasm_bridge_rail` masoara 12.24 x 40.48 m (grup Rail_L/Rail_R),
## dreapta -- podetul e PE CURBA (sagita 2.16 m pe 38.4 m). O piesa dreapta de
## 40 m pe o coarda cu sageata de 2.16 m taie tablia (semi 5.5) la capete: la
## mijlocul piesei capatul e la ~2.16 m in lateral fata de axa curbei, adica
## in interiorul benzii de 5.5 m semi-latime -- balustrada ar aparea "in aer"
## deasupra asfaltului la capete sau "ingropata" in versant, nu pe margine.
##
## Optiuni (contract): (a) doua jumatati de 20 m rotite fiecare pe TANGENTA
## locala; (b) refacerea GLB-ului pe arc.
## Aleg (a): doua jumatati de cate 20 m (Rail_L+Rail_R impreuna, deci fiecare
## instanta ramane balustrada COMPLETA stanga+dreapta pe segmentul ei, doar
## scurtata la jumatate din lungime -- world_prop scaleaza uniform, deci
## scara pe X ramane 1.0 (piesa nu se scaleaza pe lungime, doar se ROTESTE si
## se translateaza), iar cele doua jumatati se ating cap la cap la mijlocul
## podului. Motivul: (b) cere un nou export GLB (brief-ul cere asset nou,
## codul nu-l are), deci nu se poate face in acest worktree fara Blender; (a)
## foloseste piesa deja inregistrata si trece garzile fara resursa noua.
## Sagita pe fiecare jumatate de 19.2 m e ~0.54 m (sagita scade cu patratul
## lungimii: 2.16 * (19.2/38.4)^2 = 0.54), sub pragul de 0.3 m... e putin
## PESTE (0.54 > 0.3), dar balustrada e `none` (fantoma, nu opreste masina) --
## abaterea vizuala ramane (piesa dreapta pe coarda cu sageata 0.54 m), insa
## nu creeaza prag de coliziune. Se noteaza in raport ca abatere vizuala mica,
## nu ca defect de gameplay.
func _bridge_rail() -> void:
	var n := _track.baked.size()
	var f_mid := (BRIDGE_IN + BRIDGE_OUT) * 0.5
	for half_i in 2:
		# jumatatea 0: BRIDGE_IN..f_mid; jumatatea 1: f_mid..BRIDGE_OUT
		var fa: float = BRIDGE_IN if half_i == 0 else f_mid
		var fb: float = f_mid if half_i == 0 else BRIDGE_OUT
		var fm := (fa + fb) * 0.5
		var ia := int(fa * float(n)) % n
		var ib := int(fb * float(n)) % n
		var im := int(fm * float(n)) % n
		var pa: Vector3 = _track.baked[ia]
		var pb: Vector3 = _track.baked[ib]
		var pm: Vector3 = _track.baked[im]
		var tang := Vector3(pb.x - pa.x, 0.0, pb.z - pa.z).normalized()
		# RUNDA 1, a treia trecere: prima captura (v1r1_0415_uscat.png) a aratat
		# balustradele ca doua bare DIAGONALE, care taie drumul ca niste
		# bariere -- nu ca un parapet paralel cu marginea. AABB grup masurat e
		# 12,24 x 40,48 (masuratori.md); modelul are axa LUNGA (40,48 m,
		# Rail_L+Rail_R) pe local Z, latimea (12,24 m) pe local X (verificat
		# direct din mesh, tools/probe_rail_aabb.gd sters dupa folosire).
		#
		# REPARATIE INTEGRARE (fiord/poi-fix), trecerea FINALA -- trei bug-uri
		# separate, toate confirmate numeric (tools/probe_bridge_yaw.gd,
		# tools/probe_rail_live.gd, sterse dupa folosire) inainte de a rescrie:
		#
		# 1) Yaw-ul vechi (`atan2(-tang.z, tang.x) + PI*0.5`) era o supracorectie
		#    in directia gresita -- capetele ajungeau la 15.7-20.2 m LATERAL de
		#    ax (banda are 5.5-6.5 m semi-latime aici).
		# 2) RUNDA 1 PRETINDEA ca fiecare instanta e "scurtata la jumatate din
		#    lungime", dar scria scara 1.0 pe toate axele -- niciodata scurtata
		#    de fapt. Doua bare INTREGI de 40 m, fiecare rotita pe tangenta
		#    LOCALA a jumatatii ei (yaw-uri diferite), centrate langa mijlocul
		#    podului, se suprapuneau/incrucisau vizibil pe toata lungimea lor.
		# 3) CEA MAI ADANCA: memoria tscn-transform-e-pe-randuri -- Transform3D
		#    scris in text in .tscn ia 9 numere ca RANDURILE bazei
		#    (row0=(x.x,y.x,z.x), row1=(x.y,y.y,z.y), row2=(x.z,y.z,z.z)), NU
		#    coloanele. Codul (si increderea "aliniaza local +X pe tangenta" din
		#    comentariul original) scria coloanele direct ca argumente -- iesea
		#    o baza TRANSPUSA (oglindita), verificat cu probe_rail_live.gd:
		#    global_transform.basis.x avea componenta Z gresita fata de ce
		#    trebuia sa fie coloana X. Acelasi bug a lovit deja Track13
		#    (baloane/arzator) si Track16 (perdelele de ploaie) -- a treia oara
		#    pe acest cod, de-asta se construieste Basis-ul in obiect (nu direct
		#    in text) si se scriu RANDURILE lui explicit mai jos.
		#
		# Fix: yaw = atan2(-tang.x, tang.z) face local Z (coloana z a bazei)
		# paralel cu tang; scara 0.5 pe coloana z scurteaza piesa la ~20.24 m
		# (o jumatate de pod); bazei i se scriu RANDURILE (nu coloanele) in
		# .tscn, verificat cu sonda dupa scriere (nu presupus).
		var yaw := atan2(-tang.x, tang.z)
		var col_x := Vector3(cos(yaw), 0.0, sin(yaw))
		var col_y := Vector3(0.0, 1.0, 0.0)
		var col_z := Vector3(-sin(yaw), 0.0, cos(yaw)) * BRIDGE_HALF_LEN_SCALE
		var basis := Basis(col_x, col_y, col_z)
		_n += 1
		_tri += int(TRI.get("chasm_bridge_rail", 0))
		_out.append('[node name="chasmBridgeRail%d" parent="%s" instance=ExtResource("%s")]'
			% [_n, ZONE, RES["chasm_bridge_rail"]])
		# RANDURILE bazei (nu coloanele) -- vezi comentariul de mai sus.
		var r0 := Vector3(basis.x.x, basis.y.x, basis.z.x)
		var r1 := Vector3(basis.x.y, basis.y.y, basis.z.y)
		var r2 := Vector3(basis.x.z, basis.y.z, basis.z.z)
		_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
			% [r0.x, r0.y, r0.z, r1.x, r1.y, r1.z, r2.x, r2.y, r2.z, pm.x, pm.y, pm.z])
		_out.append('metadata/coliziune = "none"')
		_out.append("")
	print("; podet: 2 jumatati de balustrada (decizie RUNDA 1: doua jumatati rotite pe tangenta, scurtate real pe local Z, randuri corecte -- vezi comentariul _bridge_rail)")


# ------------------------------------------------------------------ albia raului
## Raul Cleddau la -8 m (rapa index 1: fund +7 fata de -1 offset -> vezi
## brief), cu marmite (`chasm_rock`) IN albie, nu pe podea goala (memoria
## podeaua-vaii-e-banda-lipsa: benzile de vegetatie se opresc lateral, rapa
## trebuie sa aiba fund populat). Rapa e pe 0.341-0.444, fund la +7 (cota
## absoluta fata de teren local), latime 25 (semi 12.5).
## RUNDA 1, gardata: probe_manual a semnalat marmitele de mal ca "IN DRUM"
## (6-10 m de ax cu half local 5.5-6.5 + ROAD_MARGIN 2.0 = prag 7.5-8.5 m).
## Albia raman vizibil langa drum (podul o traverseaza), dar orice bolovan cu
## coliziune `hull` se muta dincolo de prag: marmitele centrale (in mijlocul
## sosetei vizuale a raului, sub pod) raman la +/-3 m DE POD, nu de ax -- se
## calculeaza fata de half local + 3.5 m; cele de mal urca la 9-13 m.
func _riverbed() -> void:
	var f := 0.341 + _step(4.0)
	var k := 0
	while f < 0.444:
		var n := _track.baked.size()
		var i := int(f * float(n)) % n
		var half := _track.width_at_index(i)
		# bolovani mari, chiar sub linia drumului (vizibil prin/langa pod),
		# dar impinsi peste half+ROAD_MARGIN pe fiecare parte (nu chiar pe ax).
		#
		# REPARATIE INTEGRARE (fiord/poi-fix), a doua trecere: gap-ul fix 3.5 m
		# (lat = half+3.5, mereu ~10.0 m la half~6.5) e OK departe de traseul
		# principal in general, dar la frac 0.352-0.40 (furca scurtaturii, 0.366)
		# un `marmita` (nu doar `marmitaMal`) a ramas exact pe linia unde AI-ul
		# taie coltul la viteza mare -- masurat: [ejectare] "perete" 48.4 m/s la
		# frac 0.365, pos (-538,24,-495), la 5.4 m de `marmita19` (lat -10.00,
		# hull) -- identic pe seed 8 inainte SI dupa fix-ul de la `marmitaMal18`
		# (deci un obstacol diferit, nu acelasi). Acelasi tratament: gap
		# suplimentar in fereastra fork-ului.
		var near_fork_c := f >= 0.352 and f <= 0.40
		var gap_c := 6.5 if near_fork_c else 3.5
		var lat := (half + gap_c) * (1.0 if k % 2 == 0 else -1.0)
		var mdl := "chasm_rock"
		_place_river(mdl, "marmita", f, lat, _rng.randf_range(0.75, 1.4), "hull")
		# bolovani mai mici pe margini, spre malurile albiei.
		#
		# REPARATIE INTEGRARE (fiord/poi-fix): gap-ul 4.0-8.0 (lat 9.5-13.5 la
		# half~5.5-6.5) e sigur DEPARTE de traseul principal in general, dar la
		# frac 0.355-0.40 (chiar inainte si la intrarea in furca scurtaturii,
		# 0.366) traficul AI congestioneaza cand masinile decid ramura -- una
		# a lovit REPETAT marmitaMal18 (frac 0.3636, lat 8.5, half 6.5 acolo)
		# la fiecare din cele 8 seed-uri uscate si a ramas blocata (fara
		# repunere ulterioara pana la finalul cursei, tur minim cazut la 1.42).
		# Marja marita la 7.0-11.0 in fereastra fork-ului, ca sa acopere si
		# deviatia laterala mai mare din trafic aglomerat, nu doar linia
		# curata a unei singure masini.
		var near_fork := f >= 0.352 and f <= 0.40
		var gap_lo := 7.0 if near_fork else 4.0
		var gap_hi := 11.0 if near_fork else 8.0
		for sgn: float in [-1.0, 1.0]:
			if _rng.randf() < 0.6:
				_place_river("chasm_rock", "marmitaMal", f + _step(_rng.randf_range(-3.0, 3.0)),
					sgn * (half + _rng.randf_range(gap_lo, gap_hi)), _rng.randf_range(0.4, 0.75), "hull")
		f += _step(7.0 + _rng.randf_range(-1.5, 1.5))
		k += 1
	print("; albie: piese de rau asezate (marmite chasm_rock)")


## Aseaza o piesa IN albie, la `lat` metri fata de axa (nu fata de muchia
## drumului -- albia e mai lata decat carosabilul aici). Cota din raycast.
## Refuzul de scurtatura foloseste curba REALA (vezi _dist_to_scurt).
func _place_river(model: String, base: String, frac: float, lat: float,
		scl: float, mode: String) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	# REPARATIE INTEGRARE (fiord/poi-fix): vezi comentariul BRIDGE_MIN_LAT de
	# la _place()/_bridge_gap_floor -- aceeasi garda, dar `lat` aici e deja
	# distanta ABSOLUTA (semnata) de la ax pana la CENTRUL piesei, nu un gap
	# fata de muchie. Impune |lat| - corner >= BRIDGE_MIN_LAT pastrand semnul.
	var f_wrapped := fposmod(frac, 1.0)
	if mode != "none" and f_wrapped >= BRIDGE_LO and f_wrapped <= BRIDGE_HI:
		var corner_r0: float = CORNER_R[model] if CORNER_R.has(model) else BASE_R.get(model, 0.6)
		var corner: float = corner_r0 * scl
		var min_abs := BRIDGE_MIN_LAT + corner
		if absf(lat) < min_abs:
			lat = min_abs * (signf(lat) if lat != 0.0 else 1.0)
	var q := p + s * lat
	if mode != "none":
		var g0 := _sol_real(q.x, q.z)
		var r0: float = BASE_R.get(model, 0.6) * scl
		if _dist_to_scurt(Vector3(q.x, g0, q.z)) < _scurt_half + r0 + SCURT_SAFETY:
			_skipped_scurt += 1
			return
	var g := _sol_real(q.x, q.z)
	_raw(model, base, Vector3(q.x, g, q.z), _rng.randf_range(0.0, TAU), scl, mode)


# ------------------------------------------------------------------ ansamblul de canion la pod
## RUNDA 2, verdict critic: "lipseste silueta compusa a cascadei-canion ...
## niciun podet cu balustrada peste vreun curs de apa vizibil -- doar copaci
## si bolovani". Nota coordonatorului (2): masurat cu --survey-bridge, terenul
## la +/-6/10/15 m fata de drum pe TOT segmentul podetului (0.398-0.424) e
## intre -1.06 si +0.39 m -- NU cei -8 m de vale promisi de brief
## (custom_ravines index 1, floor +7). Asta e relief, nu decor (contractul:
## "NU atinge tema, terenul, relieful"). Ce RAMANE de facut in decor, fara sa
## musc din regula aia: aglomerarea vizibila de stanci chiar la baza podului
## (chasm_rock in "trepte" de inaltime descrescanda + moss_boulder la baza),
## ca marmitele sa se vada IMEDIAT langa tablie, nu la 50+ m mai devreme pe
## traseu (unde erau deja plasate de _riverbed). Cascada: RainFallChasm (cod,
## `--rain=1`) verificata pe captura la frac 0.406 -- se vede lateral-dreapta
## SI balustrada in acelasi cadru; in stare uscata nu exista geometrie de apa
## alba (niciun asset din kit are FOAM_WHITE pe Chasm), deci in uscat ramane
## doar ansamblul de stanci ca reper vizual -- nu se inventeaza cascada.
func _bridge_canyon_dressing() -> void:
	var n := _track.baked.size()
	# Grup pe partea dreapta (side=+1, conform custom_ravines index1 "side": 1),
	# chiar sub tablia podului si putin inainte de ea, ca sa fie in cadru din
	# chase-cam la 0.404-0.418 (verificat pe captura).
	var fracs := [0.401, 0.405, 0.408, 0.411, 0.414, 0.417, 0.420]
	var k := 0
	for f in fracs:
		var i := int(float(f) * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		# Bolovanul mare, cel mai aproape de asfalt permis de garda (half+2.5),
		# scara mare -> citeste ca prag/treapta de canion.
		var lat_big := half + 2.5
		var mdl_big := "chasm_rock"
		var scl_big := _rng.randf_range(1.1, 1.5)
		_place(mdl_big, "canionTreapta", f, 1.0, 2.5, _rng.randf_range(0.0, TAU),
			scl_big, "hull")
		# Al doilea, mai mic, putin mai departe si mai jos vizual (scara mica),
		# sugereaza coborarea in trepte spre "albie".
		if k % 2 == 0:
			_place("chasm_rock", "canionTreaptaMica", f + _step(1.5), 1.0,
				_rng.randf_range(4.5, 6.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.6, 0.9), "hull")
		# Moss la baza, intre stanci -- "bolovani inveliti in muschi" din bara,
		# aproape de tablie.
		var mdl_moss: String = ["moss_boulder_a", "moss_boulder_b"][k % 2]
		var h_moss: float = {"moss_boulder_a": 0.7, "moss_boulder_b": 1.6}[mdl_moss]
		_place(mdl_moss, "canionMuschi", f - _step(1.0), -1.0,
			_rng.randf_range(2.8, 4.0), _rng.randf_range(0.0, TAU),
			_scale_for(mdl_moss, h_moss), "hull")
		k += 1
	print("; ansamblu canion la pod: %d fractii, stanci+muschi langa tablie (vezi comentariul _bridge_canyon_dressing)" % fracs.size())


# ------------------------------------------------------------------ padurea de fag
## RANDUL APROPIAT: fagi (beech_a/b) la 2.5-5.5 m de MUCHIE, continuu pe ambele
## parti, cu exceptia benzii scurtaturii unde se opreste (AI-ul nu vede decor
## static -- niciun trunchi pe cei 3.2 m). In afara scurtaturii, decorul chiar
## se apropie de ea (pereti de trunchiuri langa banda veche, cere contractul).
##
## RUNDA 3, verdict critic: coronamentul din STANGA cadrului citea "zid verde
## continuu" -- inaltimi aproape identice, plasate prea des, fara goluri de
## cer. Nota coordonatorului (2): amestec beech_a/b/c (7.0/10.2/13.5) +
## beech_dead pe stanga, jitter +/-10% pe inaltime, MAI PUTINE piese pe randul
## apropiat stang (sa apara goluri de cer printre coroane din camera de joc).
## Dreapta ramane neschimbata (criticul a numit STANGA, memoria
## tinta-pe-o-axa-se-atinge-pe-axa-aia).
func _near_row() -> void:
	for sgn: float in [-1.0, 1.0]:
		var left := sgn < 0.0
		var f := F_IN + (0.0 if left else _step(4.0))
		var k := 0
		while f < F_OUT:
			var dens := _density(f)
			# Stanga: prag mai mare (mai rar) ca sa lase goluri de cer intre coroane.
			var thresh := (0.22 + 0.45 * dens) if left else (0.4 + 0.6 * dens)
			if _rng.randf() < thresh:
				var mdl: String
				var h: float
				if left:
					# amestec pe 4 clase, cu beech_dead ca a patra treapta de verde/lumina.
					var pick := k % 4
					mdl = ["beech_a", "beech_b", "beech_c", "beech_dead"][pick]
					var base_h: float = {"beech_a": 6.6, "beech_b": 9.9,
						"beech_c": 13.0, "beech_dead": 8.0}[mdl]
					h = base_h * _rng.randf_range(0.9, 1.1)
				else:
					mdl = "beech_a" if k % 3 != 2 else "beech_b"
					h = _rng.randf_range(6.0, 7.2) if mdl == "beech_a" \
						else _rng.randf_range(9.5, 10.4)
				var lat := _rng.randf_range(2.5, 5.5)
				_place(mdl, "fagApropiat", f, sgn, lat,
					_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
			# Stanga: pas mai mare (rand mai rar) -- acelasi motiv, goluri de cer.
			f += _step((7.0 if left else 5.5) + _rng.randf_range(-1.0, 1.0))
			k += 1


## AL DOILEA RAND: fagi mai mari (beech_b/c) la 8-15 m de muchie -- al doilea
## etaj de coronament (bara: "coronament in etaje, cerul se vede printre ele").
## RUNDA 3: stanga primeste acelasi amestec pe 4 clase + jitter +/-10% (vezi
## _near_row) si pas usor mai mare, ca etajele 1-2 sa nu se suprapuna in zid.
func _second_row() -> void:
	for sgn: float in [-1.0, 1.0]:
		var left := sgn < 0.0
		var f := F_IN + _step(2.5 if left else 6.0)
		var k := 0
		while f < F_OUT:
			var dens := _density(f)
			var thresh := (0.12 + 0.55 * dens) if left else (0.2 + 0.8 * dens)
			if _rng.randf() < thresh:
				var mdl: String
				var h: float
				if left:
					var pick := k % 4
					mdl = ["beech_b", "beech_c", "beech_a", "beech_dead"][pick]
					var base_h: float = {"beech_a": 6.6, "beech_b": 9.9,
						"beech_c": 13.0, "beech_dead": 8.0}[mdl]
					h = base_h * _rng.randf_range(0.9, 1.1)
				else:
					mdl = "beech_b" if k % 3 != 1 else "beech_c"
					h = _rng.randf_range(9.5, 10.4) if mdl == "beech_b" \
						else _rng.randf_range(12.5, 13.5)
				_place(mdl, "fagEtaj2", f, sgn, _rng.randf_range(8.0, 15.0),
					_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
			f += _step((8.5 if left else 7.0) + _rng.randf_range(-1.2, 1.2))
			k += 1


## FUNDALUL: fagii cei mai inalti (beech_c) la 18-32 m de muchie, sa inchida
## cerul in etajul al treilea, mai rar spre margini. Fundalul ramane neschimbat
## pe ambele parti -- criticul a incadrat defectul in "primele 2/3 din
## inaltime" (etajele 1-2), fundalul e deja cel mai inalt/mai rar etaj.
func _backdrop() -> void:
	for sgn: float in [-1.0, 1.0]:
		var f := F_IN + _step(4.0 if sgn < 0.0 else 9.0)
		var k := 0
		while f < F_OUT + _step(10.0):
			var dens := _density(clampf(f, F_IN, F_OUT - 0.001))
			if _rng.randf() < 0.25 + 0.75 * dens:
				var mdl := "beech_c" if k % 3 != 2 else "beech_dead"
				var h := _rng.randf_range(12.5, 13.5) if mdl == "beech_c" \
					else _rng.randf_range(7.5, 8.5)
				_place(mdl, "fagFund", f, sgn, _rng.randf_range(19.0, 30.0),
					_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
			f += _step(8.5 + _rng.randf_range(-1.5, 1.5))
			k += 1


## BOLOVANI INVELITI IN MUSCHI -- pe versanti, intre trunchiuri (bara).
func _moss_boulders() -> void:
	var f := F_IN + _step(6.0)
	var g := 0
	while f < F_OUT - _step(6.0):
		var dens := _density(f)
		if dens > 0.3:
			for sgn: float in [-1.0, 1.0]:
				if _rng.randf() < 0.5:
					var mdl: String = ["moss_boulder_a", "moss_boulder_b", "moss_boulder_c"][g % 3]
					var h: float = {"moss_boulder_a": 0.7, "moss_boulder_b": 1.6,
						"moss_boulder_c": 2.4}[mdl]
					var lat := _rng.randf_range(3.5, 9.0)
					_place(mdl, "muschiBolovan", f + _step(_rng.randf_range(-3.0, 3.0)),
						sgn, lat, _rng.randf_range(0.0, TAU), _scale_for(mdl, h), "hull")
		f += _step(9.0 + _rng.randf_range(-1.5, 1.5))
		g += 1


## SUBARBORETUL: ferigi (tree_fern, fern_cluster), guard_rock si tussock pe
## umar, densitate crescand spre rau (contract: densitate care creste spre
## subiect -- memoria aranjamentul-bate-numarul).
##
## RUNDA 1, gardata: probe_manual (`hw_here + ROAD_MARGIN`, adica half-latimea
## LOCALA + 2.0 m) a aratat 59 piese "IN DRUM" la 6-8 m de ax, cand half aici
## e 5.5-6.5 -- adica pragul e 7.5-8.5 m de ax. Gap-urile initiale (0.5-2.0 m
## de MUCHIE) puneau exact acolo. Piesele cu coliziune se muta la gap >= 2.7 m
## de muchie (>= ~9.2-9.7 m de ax, limpede peste prag); doar `fern_cluster`
## (coliziune `none`, fantoma) ramane aproape de asfalt.
func _understory() -> void:
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var dens := _density(f)
		var sgn := -1.0 if k % 2 == 0 else 1.0
		if _rng.randf() < 0.25 + 0.55 * dens:
			_place("tree_fern", "feriga", f, sgn, _rng.randf_range(2.8, 5.0),
				_rng.randf_range(0.0, TAU), _scale_for("tree_fern",
					_rng.randf_range(2.6, 3.5)), "hull")
		if _rng.randf() < 0.3:
			# `none` (fantoma) -- probe_manual nu stie de mod, deci gap-ul tot
			# trebuie sa treaca peste half+ROAD_MARGIN ca sa nu iasa "IN DRUM".
			_place("fern_cluster", "ferigaMica", f + _step(2.0), -sgn,
				_rng.randf_range(2.7, 4.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.4), "none")
		if _rng.randf() < 0.2:
			_place("guard_rock", "reperMargine", f + _step(1.0), sgn,
				_rng.randf_range(2.7, 4.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.3), "hull")
		if _rng.randf() < 0.25:
			_place("tussock_clump", "tufaIarba", f - _step(1.5), -sgn,
				_rng.randf_range(2.7, 4.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.7, 1.2), "hull")
		f += _step(4.5)
		k += 1


## STUMP + 2 KEA -- static cu Idle (contract: "PathMover sau static cu Idle";
## alegem static, pe ciot, langa albie -- e vizual, nu gimmick de gameplay).
func _stump_and_kea() -> void:
	var f := 0.395
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	# probe_manual: half local + ROAD_MARGIN(2.0) = prag; +2.0 peste el.
	var lat := half + 4.0
	var q := p + s * lat
	var g := _sol_real(q.x, q.z)
	_n += 1
	_tri += int(TRI.get("stump", 0))
	_out.append('[node name="stumpKea" parent="%s" instance=ExtResource("%s")]'
		% [ZONE, RES["stump"]])
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)"
		% [q.x, g, q.z])
	_out.append("")
	for j in 2:
		_n += 1
		_tri += int(TRI.get("kea", 0))
		var kx := q.x + (0.25 if j == 0 else -0.25)
		var kz := q.z + (0.1 if j == 0 else -0.15)
		var ky := g + HEIGHT["stump"]
		_out.append('[node name="kea%d" parent="%s" instance=ExtResource("%s")]'
			% [_n, ZONE, RES["kea"]])
		var yaw := _rng.randf_range(0.0, TAU)
		var c := cos(yaw)
		var sn := sin(yaw)
		_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
			% [c, sn, 1.0, -sn, c, kx, ky, kz])
		_out.append('metadata/coliziune = "none"')
		_out.append("")
	print("; ciot + 2 kea la frac %.3f, lat %.1f" % [f, lat])


## MARGINILE: cateva piese in afara intervalului ca padurea sa se lege de
## restul decorului (nu incepe brusc la o fractie).
func _edges() -> void:
	for j in 2:
		var f_in := F_IN - _step(8.0 + 12.0 * float(j))
		_place("beech_a", "fagIntrare", f_in, -1.0 if j % 2 == 0 else 1.0,
			_rng.randf_range(3.0, 7.0), _rng.randf_range(0.0, TAU),
			_scale_for("beech_a", _rng.randf_range(6.2, 7.0)), "trunk")
		var f_out := F_OUT + _step(6.0 + 12.0 * float(j))
		_place("beech_a", "fagIesire", f_out, 1.0 if j % 2 == 0 else -1.0,
			_rng.randf_range(3.0, 7.0), _rng.randf_range(0.0, TAU),
			_scale_for("beech_a", _rng.randf_range(6.2, 7.0)), "trunk")


# ------------------------------------------------------------------ asezarea

func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la corp (raza de degajare). REFUZA orice piesa cu coliziune
## (trunk/hull/mesh) care ar cadea pe banda REALA a scurtaturii (curba proprie
## a `ScurtaturaChasm`, nu un interval de fractie pe traseul principal --
## memoria obstacol-pe-drum-poate-fi-gimmick + fix RUNDA 1 dupa ProbeLaneClear).
## REPARATIE INTEGRARE (fiord/poi-fix): fereastra de APROPIERE DE FURCA
## (0.360-0.372, chiar inainte si la intrarea in ScurtaturaChasm la 0.366) --
## acolo traficul AI (6 masini, una grea/lenta) congestioneaza la decizia de
## ramura, si deviatiile laterale ale unei masini in dificultate depasesc ce
## vede vreodata o singura masina pe linie curata. ProbeRace pe integrare a
## prins Autobuzul blocat repetat la exact frac 0.364, lat 8.5-9.0 (fix
## anterior in _riverbed a scos marmitaMal18 din calea directa, dar padurea
## deasa de langa drum -- fagApropiat/feriga/reperMargine, toate cu coliziune
## reala -- ramane la 9.5-11 m, in aceeasi banda unde autobuzul incearca sa
## manevreze). Gap suplimentar mic (1.5 m) DOAR pentru piesele cu coliziune
## reala in aceasta fereastra ingusta -- nu schimba densitatea vizuala a
## padurii pe restul POI-ului D (critic aprobat), doar da putin mai mult loc
## de manevra exact la punctul de decizie.
const FORK_APPROACH_LO := 0.360
const FORK_APPROACH_HI := 0.372
const FORK_APPROACH_EXTRA_GAP := 1.5

## REPARATIE INTEGRARE (fiord/poi-fix), a treia trecere: garda finala pe
## integrare (race_dry_2.log) a prins [blocaj] repetat pe Kai la frac 0.405,
## lat 7.0/8.1, atingand Shoulders/RoadSides/RoadTop + marmita38_col si
## canionTreapta324_col -- intrarea/iesirea podetului (custom_step_ranges
## 0.406-0.424), unde semi-latimea scade la 5.5 m si masinile se inghesuie.
## Fereastra de siguranta e mai LARGA decat podetul insusi (0.395-0.435) ca sa
## acopere si manevra de aliniere inainte/dupa tablie.
##
## Fix structural (acelasi tipar ca HULL_SAFETY_MULT din gen_decor_fiord_g.gd):
## in loc sa se tot creasca un gap fix (istoricul de mai sus a facut asta de
## doua ori si tot a ramas o piesa sub prag), pragul se impune direct pe
## AMPRENTA REALA -- `_bridge_lat_floor` calculeaza gap-ul minim necesar ca
## distanta de la ax pana la cel mai apropiat COLT al piesei (CORNER_R * scara,
## nu BASE_R) sa fie >= BRIDGE_MIN_LAT, si-l foloseste ca podea (`maxf`), nu ca
## adaos -- corect indiferent de scara instantei.
const BRIDGE_LO := 0.395
const BRIDGE_HI := 0.435
## +0.3 m peste pragul cerut (10.0): marja pentru eroarea de curbura (memoria
## runda-3c/CURVE_MARGIN din gen_decor_fiord_f.gd) -- `half`/pozitia se
## calculeaza la indexul central al pasului generatorului, dar sonda de
## verificare masoara fata de indexul REAL cel mai apropiat de pozitia
## offsetata a piesei; pe curbe diferenta a lasat o piesa (tufaIarba296) la
## 9.98 m, sub cei 10.0 m ceruti la limita.
const BRIDGE_MIN_LAT := 10.3

## Gap-ul minim (fata de MUCHIA drumului) ca sa garanteze `BRIDGE_MIN_LAT` de
## la AX pana la cel mai apropiat colt al piesei, folosind raza de colt REALA
## (CORNER_R) in loc de BASE_R. `r` e raza nominala deja folosita de apelant in
## calculul lui `d = half + gap + r` -- floor-ul se exprima in aceiasi termeni
## (gap), ca sa se compuna cu `maxf` peste gap-ul cerut de apelant.
func _bridge_gap_floor(model: String, scl: float, half: float, r: float) -> float:
	# Implicit: fara CORNER_R masurat (piese `trunk`, cilindru izotrop -- fara
	# colt care sa iasa mai departe decat raza nominala), amprenta reala e `r`
	# insusi, deci floor-ul tot se aplica (distanta absoluta fata de ax conteaza,
	# nu doar corectia de colt).
	var corner: float = CORNER_R[model] * scl if CORNER_R.has(model) else r
	return BRIDGE_MIN_LAT - half + corner - r


func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull") -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var f_wrapped := fposmod(frac, 1.0)
	if mode != "none" and f_wrapped >= FORK_APPROACH_LO and f_wrapped <= FORK_APPROACH_HI:
		gap += FORK_APPROACH_EXTRA_GAP
	if mode != "none" and f_wrapped >= BRIDGE_LO and f_wrapped <= BRIDGE_HI:
		gap = maxf(gap, _bridge_gap_floor(model, scl, half, r))
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	# Refuzul de scurtatura: distanta reala (XZ) fata de curba proprie a
	# ScurtaturaChasm, esantionata in spatiul global (nu fractia pe traseul
	# principal, care nu corespunde geometric cu banda ei).
	if mode != "none":
		var ds := _dist_to_scurt(Vector3(q.x, g, q.z))
		if ds < _scurt_half + r + SCURT_SAFETY:
			_skipped_scurt += 1
			return
	if d - r < half + 0.5:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.0) * scl
	if cr > 0.0 and d - cr < 4.0:
		_warn += 1
		print("; ATENTIE coroana %s la frac %.4f ajunge la %.2f m de ax" % [
			model, frac, d - cr])
	if g - p.y > 8.0 or p.y - g > 14.0:
		print("; nota %s la frac %.4f: teren la %+.2f m fata de sosea (lateral %.1f)" % [
			model, frac, g - p.y, d])
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode)


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
	var m: String = MODE.get(model, mode)
	if m != "hull":
		_out.append('metadata/coliziune = "%s"' % m)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate de scurtatura, %d avertismente, ~%d triunghiuri" % [_n, _skipped_scurt, _warn, _tri])
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
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
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
