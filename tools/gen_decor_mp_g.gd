extends Node
## Generator de decor MANUAL pentru POI G — SERPENTINELE HIRAM BINGHAM
## (Track15, Machu Picchu, frac 0.74-0.92, urcare 9,1 % pe 5 ace de par).
##
## Ca la Serengeti (gen_decor_ser_d.gd): nu e sonda, e unealta care CALCULEAZA
## transformarile ce se lipesc in Track15.tscn sub
## `DecorManual/ZoneG_Serpentine`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpG.tscn -- \
##       --out=C:/cale/zoneG.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui, curbura) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_machu/bara_poi_G.png)
##
## Detaliul care DECIDE POI-ul, citit din decupaj: fiecare ac are ZID DE
## SPRIJIN DE PIATRA pe marginea EXTERIOARA — o dunga continua de piatra care
## urmareste curba, sub nivelul drumului, cu drumul deasupra ei. Asta face
## drumul sa citeasca drept TAIAT IN VERSANT, nu drept poteca pe iarba. In
## bara zidul e vizibil pe FIECARE bucla, si e lucrul care da profunzime:
## vezi bucla de sub tine ca o lespede sprijinita, nu ca o linie pe deal.
## Plus: quenuali cu scoarta rosie (LARCH_RUST) intre ace, bolovani cu muschi
## pe versantul dinspre munte, autobuzul galben pe un ac.
##
## Bara e LOOK, nu LAYOUT (docs/track_briefs/machu_picchu_poi_gauntlet.md):
## diorama comprima 13 ace intr-un patrat. Traseul nostru a trecut ProbeLayout.
## Se compara MATERIA: piatra, iarba, scoarta rosie, silueta.
##
## ------------------------------------------------------------------------
## SURVEY (runda 1, --survey, G_r1_survey_near.txt) — cifrele care decid
## compozitia. Traseu 1986,4 m pe 1111 puncte; felia 0,740-0,920 = ~358 m.
## Soare: rot (-40, 45, 0), lumina merge spre (-0,54, -0,64, -0,54), elevatie
## 40 grade, umbra pe XZ -> (-0,707, -0,707).
##
## 1. CINCI ACE, citite din SEMNUL CURBURII si din rotatia vectorului lateral:
##      ac1 0,738-0,752 (+0,078)   dreapta 0,755-0,772 (side 0,-1)
##      ac2 0,774-0,790 (-0,066)   dreapta 0,793-0,817 (side 0,+1)
##      ac3 0,818-0,835 (+0,072)   dreapta 0,838-0,856 (side 0,-1)
##      ac4 0,858-0,876 (-0,078)   dreapta 0,878-0,902 (side 0,+1)
##      ac5 0,903-0,913 (+0,081)   iesire 0,915-0,920 (side -1,0)
##    Raza la apex: 1/0,078 = 12,8 m ... 1/0,063 = 15,9 m — peste pragul de
##    13 m din brief (masurat la nivelul punctelor bakuite).
##
## 2. DRUMUL STA PE O POLITA, NU PE O MUCHIE. La ±6,8 m (muchia, semi-latime
##    6,5) solul e la -0,2..-0,6 m PE AMBELE PARTI, pe TOT intervalul. Caderea
##    incepe abia la 9-11 m si se adanceste la 15-25 m. Deci exista un UMAR de
##    2-4 m inainte de gol.
##
##    Consecinta directa pentru zidul de sprijin: o piesa `inca_wall_*` de
##    2,487 m pusa in PICIOARE pe sol la muchie ar fi un PARAPET de 2,2 m
##    peste carosabil — adica un zid, periculos si fals (in bara zidul e SUB
##    drum, il vezi de pe bucla de deasupra). Asa ca zidul se ingroapa: baza
##    la `y_drum - 2,24`, varful la `y_drum + 0,25`. 25 cm e sub pragul de
##    0,3 m la care un prag lateral devine zid pentru fizica intreaga
##    (memoria suprafete-cu-goluri-si-praguri), deci ramane buza de piatra,
##    nu obstacol.
##
## 3. PARTEA CARE CADE ALTERNEAZA LA FIECARE AC, exact ca o serpentina reala:
##      0,750-0,775: cade +side (-0,9 la 11 m, -3,6 la 25), urca -side (+5,7 la 15)
##      0,780      : cade +side brutal (-11,0 la 11, -21,6 la 25) = apexul ac2
##      0,790-0,815: cade -side (-2,9 la 15, -7,9 la 25), urca +side
##      0,835-0,855: cade +side, urca -side (+8,5 la 15)
##      0,880-0,900: cade -side (-4,0 la 15, -6,6 la 25), urca +side (+18,2 la 15)
##    Deci NU se hardcodeaza „dreapta": `_downhill_side` o citeste din teren,
##    la 15 si 25 m lateral, la fiecare asezare.
##
## 4. UNDE E PIATRA FATA DE OCHI. Camera zboara pe axa la 10 m si vede in sus
##    10 + 0,093*d. Zidul de sprijin al buclei de DEASUPRA (urcarea urmatoare
##    e la +6..+8 m pe verticala si 40-60 m lateral) intra in cadru la
##    10 + 0,093*50 = 14,7 m — adica se vede, si e exact „lespedea sprijinita"
##    din bara. De aia zidul se pune si pe partea care URCA: privit de jos,
##    zidul buclei de sus e ce da profunzimea.
##
## ------------------------------------------------------------------------
## CAPCANA AUTOBUZULUI (machu_picchu_poi_gauntlet.md §G)
##
## `custom_lane_corridors (0.70, 0.909, +0.5)` tine AI-ul pe JUMATATEA +side
## fiindca AI-ul NU VEDE corpuri cinematice (memoria
## obstacol-pe-drum-poate-fi-gimmick). Autobuzul e 3,6 m lat pe drum de 6,5 m
## semi-latime si ia acul LARG, pe jumatatea EXTERIOARA. Orice decor pus pe
## jumatatea lui ii taie culoarul si blocheaza pista.
##
## Regula in cod: `_place` REFUZA orice piesa cu coliziune (hull/trunk/mesh) a
## carei margine ajunge la mai putin de `EDGE_KEEP` metri de MUCHIA drumului.
## Zidul de sprijin sta pe muchie DAR sub cota drumului (vezi `_retaining`):
## e taluz imbracat in piatra, nu parapet — nu urca peste carosabil.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneG_Serpentine"

const F_IN := 0.740
const F_OUT := 0.920

## id-urile ext_resource din Track15.tscn (fundatia, PR de baza).
const RES := {
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"trail_marker": "s_trail_marker",
	"rope_rail": "s_rope_rail",
	"tree_fern": "s_tree_fern",
	"bromeliad": "s_bromeliad",
	"orchid_cluster": "s_orchid_cluster",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
## Scara se cere in METRI, se imparte la cifra de aici — nu din burta.
const HEIGHT := {
	"polylepis_a": 4.190, "polylepis_b": 6.798,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"trail_marker": 1.200, "rope_rail": 1.045,
	"tree_fern": 3.306, "bromeliad": 0.377, "orchid_cluster": 0.390,
}

## Raza de DEGAJARE la sol (m) la scara 1: raza corpului fizic.
## Copacii au coliziune `trunk` (cilindru in ax) — raza la baza masurata.
## Bolovanii si zidurile au `hull` — jumatatea laturii mari a AABB.
const BASE_R := {
	"polylepis_a": 0.61, "polylepis_b": 1.10,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"trail_marker": 0.29, "rope_rail": 2.07,
	"tree_fern": 0.54, "bromeliad": 0.46, "orchid_cluster": 0.17,
}

## Raza COROANEI (m) la scara 1 — pentru testul camerei (zboara pe axa la 10 m).
const CROWN_R := {
	"polylepis_a": 1.39, "polylepis_b": 2.27,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"trail_marker": 0.29, "rope_rail": 2.07,
	"tree_fern": 2.07, "bromeliad": 0.46, "orchid_cluster": 0.17,
}

const TRI := {
	"polylepis_a": 598, "polylepis_b": 1098,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"trail_marker": 76, "rope_rail": 92,
	"tree_fern": 768, "bromeliad": 248, "orchid_cluster": 410,
}

## Degajarea minima de la MUCHIA drumului la marginea corpului fizic, pentru
## orice piesa cu coliziune. 0,8 m: mai putin si o masina care atinge umarul
## in ac se opreste in decor. Zidul de sprijin face EXCEPTIE — el e sub cota
## drumului, si se verifica pe cota, nu pe distanta (vezi `_retaining`).
const EDGE_KEEP := 0.8
## Cat pot sa difere cota din raycast si cea din campul neted inainte sa refuz
## piesa (vezi nota din `_place`).
const SOL_TOL := 1.5

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
var _sun_to := Vector3(0.0, 1.0, 0.0)


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
	_rng.seed = 150815
	_survey()
	if not _survey_only:
		_retaining()
		_uphill_wall()
		_quenual_row()
		_understory()
		_markers()
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
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, sh_x(shadow), sh_z(shadow),
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        curb(1/m)  sol la -25 -15 -11 -9 -7.5 -6.8 | +6.8 +7.5 +9 +11 +15 +25   dot(side,umbra)")
	var f := F_IN - 0.01
	while f <= F_OUT + 0.01:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-25.0, -15.0, -11.0, -9.0, -7.5, -6.8, 6.8, 7.5, 9.0, 11.0, 15.0, 25.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %+8.4f  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, _curv(i), " ".join(cols),
			s.dot(shadow)])
		f += 0.005


func sh_x(v: Vector3) -> float: return v.x
func sh_z(v: Vector3) -> float: return v.z


## Curbura cu semn la indexul i (1/m): pozitiv = vireaza spre +side.
## Semnul se DERIVA cu dot, nu se ghiceste (memoria rotatii-in-builder-semnul).
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

## (1) ZIDUL DE SPRIJIN — DETALIUL CARE DECIDE POI-UL.
##
## O dunga CONTINUA de piatra pe marginea care CADE, urmarind curba, cu varful
## la `y_drum + LIP` si corpul ingropat in umar. Din masina se vede buza; de pe
## bucla de deasupra se vede fata de piatra a buclei de dedesubt — exact ce
## face drumul sa citeasca „taiat in versant", nu „poteca pe iarba" (bara).
##
## De ce CONTINUA si nu petice: in bara zidul e pe FIECARE bucla, fara
## intreruperi; ziduri razlete citesc a ruina, nu a terasament (aceeasi lectie
## ca la POI A cu incintele). Piesele se inlantuie cap la cap: `inca_wall_b` e
## 6,00 m pe X, `inca_wall_a` 4,00, `inca_wall_c` 2,00 — capetele sunt la
## ±3,00 / ±2,00 / ±1,00 exact, deci rostul e 0,000 daca pasul pe traseu e
## egal cu lungimea piesei.
##
## Pasul pe ARC, nu pe fractie: pe ac, fractia se strange, iar un pas constant
## in fractii ar suprapune piesele in ac si le-ar rari pe dreapta. Alegerea
## piesei se face dupa curbura: pe ac (raza 13-16 m) o piesa de 6 m subintinde
## 26 de grade si ar iesi din curba cu 0,35 m la mijloc — deci pe ac merge
## `inca_wall_c` (2 m, abatere 0,04 m), pe dreapta `inca_wall_b` (6 m).
const LIP := 0.25          # cat iese varful zidului peste cota drumului
## Plafonul absolut al varfului fata de sosea, cand zidul se ridica pe prispele
## plate ca sa mai aiba o fata. Peste 0,30 m un prag lateral devine ZID pentru
## fizica intreaga (memoria suprafete-cu-goluri-si-praguri) — dar zidul sta la
## 9-15 m de ax, nu pe umar, deci cifra e aici o limita de CITIRE (sa nu
## devina parapet vizual), nu una de siguranta.
const LIP_MAX := 0.55
const WALL_H := 2.487      # inaltimea piesei (masurata, inca_wall_a/b)
## Lungimea EXACTA pe X, din AABB (tools/probe_mp_g_aabb.gd): capetele sunt la
## ±3,000 / ±2,000 / ±1,000, deci rostul e 0,000 daca pasul = lungimea.
const WALL_LEN := {"inca_wall_a": 4.0, "inca_wall_b": 6.0, "inca_wall_c": 2.0}

## RUNDA 1 A GRESIT AICI, si capturile au aratat-o (G_r1_f076/082/088.png):
## zidul pus la muchie (7,48 m de ax, varf la y_drum+0,25) iesea 0,55 m din
## pamant si citea drept BORDURA, nu drept zid de sprijin. Motivul e masurat
## in `tools/ProbeMpGUmar.tscn`, profilul fin al umarului:
##
##   la 6,5-9 m de ax solul e la -0,3..-0,5 m PE TOATA felia (exceptia:
##   apexul lui ac2, la 0,780, unde e -5,0 chiar la muchie);
##   caderea atinge -1,0 m abia la 10-12 m si -2..-3 m la 14-16 m.
##
## Adica drumul are un PRISPA de iarba de 3-5 m, apoi versantul. Un zid pus pe
## muchie nu sprijina nimic — n-are ce sa retina, si de aia nu se vede. Zidul
## trebuie sa stea pe CONTURUL unde terenul a cazut deja, cu varful la cota
## prispei: atunci profilul citit din masina si de pe bucla de deasupra e
## drum -> prispa -> FATA DE PIATRA -> gol, exact bara.
##
## Se cauta, la fiecare pas, distanta laterala la care caderea trece de
## `FALL_TARGET`; daca nu se atinge pana la `LAT_MAX`, se ia `LAT_MAX`.
## Varful zidului sta la cota solului de acolo + LIP, deci piesa NU e in aer si
## nu e o treapta peste care se calca — e imbracamintea taluzului.
## FALL_TARGET a coborat de la 1,6 la 1,1 dupa captura G_r2_f082: la 1,6 m
## conturul iesea la 15-17 m de ax pe picioarele plate, adica destul de departe
## incat zidul sa nu mai citeasca drept al DRUMULUI, ci un zid oarecare in
## camp. La 1,1 m conturul sta la 10-13 m — inca pe taluz, inca legat de sosea.
##
## RUNDA 2 (critica oarba) a mutat PREMISA, nu cifra. Cat timp felia nu avea
## rapa declarata, terenul statea la cota drumului pana la 9-11 m si orice
## „contur de cadere" era un artefact al campului, nu o buza — de aia zidul
## fugea la 10-15 m si citea ca bordura intr-o pajiste. Cu cele patru cornise
## (custom_ravines 5-8) buza e REALA si e la 0,5 m de asfalt
## (RAVINE_CORNICE_INNER), deci zidul se muta pe ea:
##   LAT_MIN 8,5 -> 7,3 m de ax = 0,8 m dincolo de muchia de 6,5.
##   LAT_MAX 15 -> 10,5: dincolo de racordul cornisei (6 m) peretele e deja in
##   cadere libera si o piesa pusa acolo atarna in aer.
## FALL_TARGET urca la 1,8: pe cornisa caderea trece de 1,8 m in primii metri,
## deci pragul alege buza, nu panta de racord.
const FALL_TARGET := 1.8
const LAT_MIN := 7.3       # 0,8 m dincolo de muchia drumului (semi-latime 6,5)
const LAT_MAX := 10.5      # dincolo de racordul cornisei piesa ar atarna in aer
## Cat poate sta zidul dincolo de MUCHIA locala. 1,4 m: piesa e groasa 0,83-0,86
## (masuratori §1), deci fata ei dinspre drum ramane la ~1 m de asfalt — destul
## cat sa nu fie obstacol pe umar, prea putin cat sa se vada iarba intre sosea
## si zid. Se masoara fata de `width_at_index`, nu fata de 6,5 fix: semi-latimea
## se schimba pe felie (custom_width_segments).
const EDGE_BAND := 1.4

## RUNDA 3 A GRESIT PASUL, si captura a aratat-o inainte de orice cifra
## (G_r3_f076/082/088.png): zidul citea ca un SIR DE STALPI cu iarba pe cap, nu
## ca o linie de zidarie. Masurat pe .tscn-ul rezultat (capetele piesei pe axa
## ei locala +X, lungimi 6,00/4,00/2,00 din AABB): rost median 1,42 m, 65 din
## 92 de imbinari peste 1 m, 30 peste 2 m. Piesele trebuie sa se ATINGA (rost
## 0,000 — capetele sunt la ±3,00/±2,00/±1,00 exact), deci lantul era rupt la
## doua treimi din imbinari.
##
## Prima incercare de reparatie a cautat, binar, fractia la care capul piesei
## urmatoare cade pe coada celei precedente. A injumatatit rostul (median 1,26)
## si atat, iar descompunerea imbinarii pe axe a aratat de ce: abaterea e PE
## TANGENTA si ALTERNEAZA semnul (+1,96 / -1,08 / -0,47 / +2,75 / -1,73), adica
## piesele cad alternativ prea departe si suprapuse. Cauza e ca predicatul de
## cautare foloseste tangenta si `lat` de la fractia `mid`, iar piesa care chiar
## se aseaza acolo isi recalculeaza `lat` si modelul — deci testul si asezarea
## nu vorbesc despre acelasi capat. Nicio cautare pe fractie nu poate inchide
## asta, fiindca marimea cautata (pozitia capatului) nu e monotona in fractie.
##
## Asa ca zidul nu se mai aseaza pe fractii: se construieste intai LINIA lui, ca
## polilinie deasa, si abia apoi se calca pe ea la intervale exacte. Un zid e o
## curba cu piese pe ea, nu un sir de piese care incearca sa nimereasca o curba.
## Pasul pe polilinie e chiar lungimea piesei, deci rostul e 0 prin constructie:
## capatul piesei k e, la milimetru, inceputul piesei k+1.
const WALL_POLY_STEP := 0.5   # cat de des se esantioneaza linia zidului (m de axa)
## Cat poate coti linia pe lungimea UNEI piese, in grade. Peste atat, imbinarea
## dintre doua piese drepte lasa o crestatura vizibila si sirul citeste a stalpi
## (masurat pe G_r4_f082: salt de yaw median 8,7 grade, maxim 43).
## 6 grade pe o piesa de 2 m inseamna o sageata de 2,6 cm — sub ce se vede.
const WALL_MAX_TURN_DEG := 6.0

## Un punct de pe linia zidului, cu tot ce trebuie ca sa se aseze o piesa acolo.
class WallPt:
	var pos: Vector3       # pozitia pe linia zidului (x, z reale; y = cota drumului)
	var road_y: float      # cota soselei la fractia asta (varful zidului o urmeaza)
	var sgn: float         # pe ce latura cade
	var frac: float
	var idx: int


func _retaining() -> void:
	# (a) linia zidului, esantionata des pe fractie.
	var n := _track.baked.size()
	var line: Array[WallPt] = []
	var f := F_IN
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := _downhill_side(i)
		var lat := _smooth_lateral(i, sgn)
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
	# (b) se calca pe ea. Latura se inverseaza la fiecare ac; acolo linia SARE
	# de pe un mal pe celalalt (masurat: 17-19 m intr-un pas), si acolo lantul
	# TREBUIE sa se rupa — sunt doua ziduri diferite, pe doi versanti diferiti.
	#
	# A DOUA INCERCARE A GRESIT AICI, si masuratoarea a aratat exact cat: se
	# consuma `WALL_LEN` metri de ARC (suma pasilor de polilinie) si apoi piesa
	# se aseza pe COARDA dintre capete. Coarda unei curbe e mai scurta decat
	# arcul ei, deci o piesa de 6,00 m ajungea centrata pe o coarda de ~5 m, iar
	# urmatoarea pornea de la capatul ARCULUI — cu un metru mai departe decat
	# capatul piesei. Rostul median masurat: 1,35 m, adica exact diferenta.
	#
	# Piesa e DREAPTA si are lungime fixa, deci ce trebuie sa se potriveasca e
	# coarda, nu arcul: se cauta pe polilinie punctul aflat la fix `WALL_LEN`
	# metri IN LINIE DREAPTA de capatul precedent, si piesa se intinde intre
	# cele doua. Asa capatul piesei k e, la milimetru, inceputul piesei k+1.
	var s_arc := 0.0
	var k := 0
	var head := Vector3.INF     # capatul piesei precedente (inceputul celei noi)
	var head_w: WallPt = null
	while k < line.size() - 1:
		var a: WallPt = line[k]
		var b: WallPt = line[k + 1]
		var jump := Vector3(b.pos.x - a.pos.x, 0.0, b.pos.z - a.pos.z).length()
		if a.sgn != b.sgn or jump > 5.0:
			head = Vector3.INF      # salt de mal: lantul se rupe aici
			head_w = null
			k += 1
			continue
		if head == Vector3.INF:
			head = a.pos
			head_w = a
		# Modelul se alege dupa CAT COTESTE LINIA pe lungimea piesei, nu dupa o
		# raza efectiva ghicita.
		#
		# Ce a aratat captura G_r4_f082: rostul era deja mic (median 0,23 m), dar
		# zidul tot citea ca un sir de lespezi razlete. Masurat pe .tscn, cauza
		# nu era rostul, era UNGHIUL: salt de yaw median 8,7 grade intre piese
		# vecine, 26 din 76 peste 10 grade, maximul 43. Doua piese drepte care se
		# intalnesc la 15 grade lasa o crestatura in V la imbinare, si un sir de
		# crestaturi e exact silueta de „stalpi", oricat de lipite ar fi.
		#
		# Deci lungimea piesei se alege ca ea sa subintinda cel mult
		# `WALL_MAX_TURN_DEG`: se masoara direct cat se roteste linia zidului pe
		# 6 m, pe 4 m si pe 2 m in fata, si se ia cea mai lunga piesa care incape
		# sub prag. Pe dreapta iese tot cea de 6 m (unghi ~0), pe ac cea de 2 m.
		var mdl := "inca_wall_c"
		for cand: String in ["inca_wall_b", "inca_wall_a"]:
			if _line_turn_deg(line, k, WALL_LEN[cand]) <= WALL_MAX_TURN_DEG:
				mdl = cand
				break
		var seg: float = WALL_LEN[mdl]
		# Cauta primul punct de polilinie aflat la >= `seg` IN LINIE DREAPTA de
		# `head`, apoi interpoleaza pe ultimul segment ca sa cada la fix `seg`.
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
			s_arc += seg
		head = tip
		head_w = line[j]
		k = j - 1
	print("; zid de sprijin: %d piese pe ~%.0f m de linie" % [_n, s_arc])


## Cat coteste linia zidului (grade) pe `span` metri in linie dreapta inainte de
## punctul `k`. Se compara directia primei coarde cu a ultimei.
func _line_turn_deg(line: Array[WallPt], k: int, span: float) -> float:
	var p0: Vector3 = line[k].pos
	var j := k + 1
	while j < line.size():
		var pj: WallPt = line[j]
		var pv: WallPt = line[j - 1]
		if pj.sgn != pv.sgn or Vector3(pj.pos.x - pv.pos.x, 0.0,
				pj.pos.z - pv.pos.z).length() > 5.0:
			return 999.0        # rupere de mal: nu incape nicio piesa lunga
		if Vector3(pj.pos.x - p0.x, 0.0, pj.pos.z - p0.z).length() >= span:
			break
		j += 1
	if j >= line.size():
		return 999.0
	var d0 := Vector3(line[k + 1].pos.x - p0.x, 0.0, line[k + 1].pos.z - p0.z)
	var d1 := Vector3(line[j].pos.x - line[j - 1].pos.x, 0.0,
		line[j].pos.z - line[j - 1].pos.z)
	if d0.length() < 0.01 or d1.length() < 0.01:
		return 999.0
	return rad_to_deg(absf(d0.normalized().angle_to(d1.normalized())))


## Punctul de pe segmentul p0->p1 aflat la fix `r` in linie dreapta de `c`.
## (intersectia cercului de raza r centrat in c cu segmentul; r e intre |c-p0|
## si |c-p1| prin constructia apelantului, deci solutia exista)
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
	var t := (-bb + sqrt(disc)) / (2.0 * aa)
	t = clampf(t, 0.0, 1.0)
	return p0.lerp(p1, t)


## Aseaza o piesa de zid pe coarda p0->p1. Intoarce false daca s-a sarit.
func _place_wall(mdl: String, p0: Vector3, p1: Vector3, w0: WallPt,
		w1: WallPt) -> bool:
	var d := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	if d.length() < 0.01:
		return false
	var tang := d.normalized()
	var mid := (p0 + p1) * 0.5
	# Varful zidului urmeaza cota SOSELEI (media capetelor) plus buza — pe
	# cornisa zidul TINE DRUMUL, deci cota lui e a drumului, nu a terenului de
	# alaturi, fiindca dincolo de el nu mai e teren, e gol.
	var top := (w0.road_y + w1.road_y) * 0.5 + LIP
	# Cat de adanca e caderea sub fata zidului. Singura decizie pe care o ia:
	# daca buza NU a fost taiata (racordul cornisei se stinge spre capetele
	# feliei), piesa ar sta pe iarba plata si ar citi iar ca bordura — exact
	# bordura ornamentala care a pierdut runda 2. Sub 0,8 m se sare.
	var side := _track._side_at(w0.idx) * w0.sgn
	var probe := mid + side * 0.6
	var foot: float = minf(_sol_real(probe.x, probe.z),
		_sampler.ground_y(probe.x, probe.z))
	if top - foot < 0.8:
		_skipped += 1
		return false
	# INALTIMEA RAMANE INTREAGA, talpa se ingroapa (sau atarna pe fata).
	# Runda 3 a strans piesele pe verticala la fata disponibila (v_scl); in
	# captura (G_r4_f076.png) au iesit blocuri indesate care citeau a lazi, nu
	# a zidarie — proportia pietrelor din textura se strica odata cu piesa.
	# Un zid pe jumatate ingropat e tot un zid; unul turtit nu mai e.
	var y := top - WALL_H
	# Yaw astfel incat local +X sa mearga pe coarda. Baza X a lui
	# Basis.from_euler(0, yaw, 0) e (cos, 0, -sin); o egalez cu coarda.
	var yaw := atan2(-tang.z, tang.x)
	_raw(mdl, "zidSprijin", Vector3(mid.x, y, mid.z), yaw, 1.0, "hull")
	return true


## RUNDA 4 A GRESIT AICI. Versiunea dinainte (`_fall_lateral`) cauta, la
## FIECARE piesa, distanta la care terenul cazuse cu FALL_TARGET. Suna corect
## si e gresit: conturul de cadere serpuieste, deci piesele consecutive cadeau
## la distante laterale si la cote diferite, lantul se rupea, si in captura
## (G_r4_f076.png) zidul citea ca un sir de LAZI razlete pe panta, cu goluri
## intre ele si talpile in aer. Un zid de sprijin e o LINIE, nu un contur de
## nivel; ce urmareste el e drumul, nu terenul.
##
## Deci: distanta laterala e o functie NETEDA de fractie — media conturului de
## cadere pe o fereastra de +-12 m de traseu, clampata. Se pastreaza adaptarea
## (pe unde e rapa, zidul se apropie; pe unde e prispa lunga, se departeaza)
## fara zimtii care rup lantul.
func _smooth_lateral(i: int, sgn: float) -> float:
	var n := _track.baked.size()
	var acc := 0.0
	var cnt := 0
	for k in range(-4, 5):
		var j := (i + k * 3 + n) % n
		acc += _fall_lateral_raw(j, sgn)
		cnt += 1
	# ...si apoi se leaga de MUCHIE, nu doar de cele doua plafoane absolute.
	# Pe cornisa, zidul TINE ASFALTUL: buza taieturii e la 0,5 m de el
	# (RAVINE_CORNICE_INNER), deci un zid la 10,5 m de ax cand muchia e la 6,5
	# lasa patru metri de iarba intre sosea si zid — si atunci piesele nu mai
	# citesc ca terasamentul drumului, ci ca un gard pe camp, splayate pe panta.
	# Exact asta se vede in prim-planul lui G_r6_f082.png.
	# Deci limita de sus e RELATIVA la muchia locala: cel mult `EDGE_BAND` metri
	# dincolo de ea. Cautarea conturului de cadere ramane, dar doar ca sa apropie
	# zidul acolo unde rapa incepe mai devreme decat buza nominala.
	var half := _track.width_at_index(i)
	return clampf(acc / float(cnt), maxf(LAT_MIN, half + 0.5),
		minf(LAT_MAX, half + EDGE_BAND))


func _fall_lateral_raw(i: int, sgn: float) -> float:
	var p := _track.baked[i]
	var s := _track._side_at(i) * sgn
	var d := LAT_MIN
	while d <= LAT_MAX:
		var q := p + s * d
		if p.y - _sol_real(q.x, q.z) >= FALL_TARGET:
			return d
		d += 0.5
	return LAT_MAX


## (2) VERSANTUL DINSPRE MUNTE: peretele verde din bara. Bolovani cu muschi
## insirati pe partea care URCA, la 1,5-5 m de muchie, cu marimi in gradient
## (cel mare in spate, cei mici spre drum — patru-defecte-de-diorama, 3).
## Nu un sir uniform: grupuri de 2-4, ca un talus de versant, nu ca un gard.
func _uphill_wall() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var g := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := -_downhill_side(i)
		var cnt := 2 + (g % 3)
		for j in cnt:
			var mdl := "moss_boulder_c" if j == 0 else (
				"moss_boulder_b" if j % 2 == 1 else "moss_boulder_a")
			var h := _rng.randf_range(2.6, 3.6) if j == 0 else (
				_rng.randf_range(1.4, 2.1) if j % 2 == 1
				else _rng.randf_range(0.6, 1.0))
			# Minim 2,1 m de muchie si pe bolovanii mici: la 1,0 m un
			# moss_boulder_b de 2 m sta cu hull-ul la 7,7 m de ax, adica pe
			# umarul de 2-4 m pe care o masina larga in ac chiar calca.
			var gap := _rng.randf_range(3.5, 7.0) if j == 0 \
				else _rng.randf_range(2.1, 5.0)
			_place(mdl, "bolovan", f + _step(_rng.randf_range(-4.0, 4.0)),
				sgn, gap, _rng.randf_range(0.0, TAU), _scale_for(mdl, h),
				"hull", -0.15)
		# RUNDA 3: pasul a coborat de la 18 la 10 m. Capturile G_r3_f082/f088
		# arata versantul dinspre munte ca IARBA GOALA cu cativa copaci
		# razleti — in bara e un perete verde compact de vegetatie si piatra,
		# lipit de drum. La 18 m pas si 2-4 bucati pe grup ieseau ~20 de
		# bolovani pe 358 m, adica unul la 18 m: prea rar ca sa citeasca drept
		# versant.
		f += _step(10.0 + _rng.randf_range(-2.5, 2.5))
		g += 1


## (3) QUENUALII — scoarta rosie (slot LARCH_RUST), al doilea semnal al barei.
## In bara sunt copaci rosii-portocalii INTRE ace, pe versant, nu in ac: in ac
## ar sta chiar pe culoarul autobuzului sau ar ascunde acul urmator (si acul e
## informatia de care are nevoie soferul).
##
## Se pun pe AMBELE parti, dar cu roluri diferite, ca sa nu iasa alee:
##  - pe partea care URCA, aproape (2,5-6 m de muchie), inalti (5-8 m):
##    coroana trece peste umar si intra in cadru ca masa rosie langa geam;
##  - pe partea care CADE, DEDESUBT (8-16 m de muchie, sub cota drumului):
##    se vad varfurile de sub buza zidului, adica exact ce se vede in bara
##    cand privesti peste marginea exterioara spre bucla de jos.
func _quenual_row() -> void:
	var n := _track.baked.size()
	# (a) randul dinspre munte
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := -_downhill_side(i)
		# Filtrul de curbura din runda 1 (nimic pe ac) s-a scos: pe ac, partea
		# dinspre munte e chiar peretele in care e taiat acul, si ea trebuie sa
		# fie cea mai plina. Ce ramane e degajarea, care e treaba lui `_place`.
		var mdl := "polylepis_b" if k % 3 != 1 else "polylepis_a"
		var h := _rng.randf_range(6.0, 8.0) if mdl == "polylepis_b" \
			else _rng.randf_range(3.8, 4.8)
		_place(mdl, "quenual", f, sgn, _rng.randf_range(2.5, 6.0),
			_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
		# RUNDA 3: 13 -> 8 m. Cu pasul de 13 m si filtrul de curbura (nimic pe
		# ac), randul dinspre munte avea goluri de 25-30 m fix pe ace, adica
		# exact unde camera priveste cel mai mult spre versant.
		f += _step(8.0 + _rng.randf_range(-2.0, 2.0))
		k += 1
	# (b) randul de SUB buza, pe partea care cade — coroanele care se vad peste
	# creasta zidului.
	#
	# RUNDA 2: departarea a urcat de la 4-11 m la 16-30 m. Cat timp felia era
	# plata, 4-11 m insemna „pe umar, putin mai jos"; cu cornisele taiate, un
	# copac la 4-11 m sta CHIAR PE FATA peretelui, adica exact in dreptul golului
	# pe care criticul cere sa-l vezi („peste zid vezi coroane si stanca
	# dedesubt, plus tierul urmator de drum"). La 16-30 m sunt dincolo de racord
	# (6 m) si in interiorul latimii declarate (55 m), deci stau pe fundul si pe
	# malul rapei: din masina, varfurile lor apar SUB linia zidului, si golul
	# dintre zid si ele e chiar adancimea.
	#
	# `_place` ia cota din `_sol_real`, adica din panza de coliziune reala, deci
	# coboara singur cu peretele (memoria terrain-mesh-y-extrapoleaza).
	f = F_IN + _step(7.0)
	k = 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := _downhill_side(i)
		var mdl := "polylepis_b" if k % 2 == 0 else "polylepis_a"
		var h := _rng.randf_range(5.5, 7.5) if mdl == "polylepis_b" \
			else _rng.randf_range(3.6, 4.6)
		_place(mdl, "quenualJos", f, sgn, _rng.randf_range(16.0, 30.0),
			_rng.randf_range(0.0, TAU), _scale_for(mdl, h), "trunk")
		f += _step(11.0 + _rng.randf_range(-2.5, 2.5))
		k += 1


## (4) SUBARBORETUL: ferigi arborescente si bromelii pe versantul umed dinspre
## munte, orhidee ca accent rar. Toate `none` sau `trunk` mici — stratul de la
## inaltimea farului, fara care intre iarba si coroane nu e nimic.
##
## ATENTIE la `tree_fern`: coliziunea `trunk` ii da un cilindru de 0,537 m raza
## (masuratori §3), de 1,8 ori stipa reala. De aia sta la >= 2,5 m de muchie.
func _understory() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var up := -_downhill_side(i)
		if k % 2 == 0:
			_place("tree_fern", "feriga", f, up, _rng.randf_range(2.5, 6.0),
				_rng.randf_range(0.0, TAU),
				_scale_for("tree_fern", _rng.randf_range(2.4, 3.4)), "trunk")
		# Departarea minima e 2,1 m de muchie, nu 0,4: la 0,4 m centrul cade la
		# 7,4 m de ax, iar `probe_manual` marcheaza „IN DRUM" tot ce e sub
		# `half + 2,0` (r1: 16 bromelii si 4 orhidee asa). Nu e periculos
		# (sunt fantome), dar pe umarul de 2-4 m masurat in survey ele sunt
		# CHIAR pe carosabilul vizual — accentul roz langa banda citeste a
		# gunoi pe drum, nu a padure de nori.
		if _rng.randf() < 0.75:
			_place("bromeliad", "bromelie", f + _step(3.0), up,
				_rng.randf_range(2.1, 5.0), _rng.randf_range(0.0, TAU),
				_scale_for("bromeliad", _rng.randf_range(0.5, 0.9)), "none")
		# Accent roz, RAR (brief §0.1: orhideea e 'accent rar').
		if _rng.randf() < 0.14:
			_place("orchid_cluster", "orhidee", f + _step(5.0), up,
				_rng.randf_range(2.2, 4.5), _rng.randf_range(0.0, TAU),
				_scale_for("orchid_cluster", _rng.randf_range(0.45, 0.7)),
				"none")
		f += _step(9.0 + _rng.randf_range(-2.0, 2.0))
		k += 1


## (5) SEMNELE DE DRUM: bornele `trail_marker` pe muchia care cade, la fiecare
## ~22 m, plus `rope_rail` in APEXUL fiecarui ac — parapetul de franghie din
## bara, pus doar acolo unde acul e stramt, ca punctuatie.
##
## Amandoua sunt `none` (masuratori: rope_rail e fantoma, trail_marker 76 tri
## la 1,2 m): pot sta pe buza fara sa devina obstacol. Bornele stau IN AFARA
## zidului (dincolo de fata de piatra), ca sa nu fie un stalp pe umar.
func _markers() -> void:
	var n := _track.baked.size()
	var f := F_IN
	while f < F_OUT:
		var i := int(f * float(n)) % n
		var sgn := _downhill_side(i)
		_place("trail_marker", "borna", f, sgn, 1.35, 0.0,
			_scale_for("trail_marker", 1.2), "none", LIP - 0.1)
		f += _step(22.0)
	# Parapetul de franghie in apexul acelor: se cauta maximul local de curbura.
	for rg: Vector2 in [Vector2(0.738, 0.752), Vector2(0.774, 0.790),
			Vector2(0.818, 0.835), Vector2(0.858, 0.876), Vector2(0.903, 0.913)]:
		var best := rg.x
		var bk := 0.0
		var t := rg.x
		while t < rg.y:
			var kk := absf(_curv(int(t * float(n)) % n))
			if kk > bk:
				bk = kk
				best = t
			t += _step(2.0)
		# Sase panouri inlantuite (4,14 m fiecare) centrate pe apex.
		for j in range(-2, 4):
			var ff := best + _step(4.14 * float(j))
			var i := int(ff * float(n)) % n
			var p := _track.baked[i]
			var side := _track._side_at(i) * _downhill_side(i)
			var tang := (_track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n])
			tang.y = 0.0
			if tang.length() < 0.01:
				continue
			tang = tang.normalized()
			var half := _track.width_at_index(i)
			var q := p + side * (half + 0.45)
			# Parapetul urmeaza SOLUL, nu cota drumului. In apexul lui ac2
			# terenul cade abrupt chiar dupa muchie (survey: -5,3 m la 6,8 m
			# lateral la frac 0,780) — un panou pus la `y_drum + LIP` plutea
			# acolo 4,04 m (probe_manual r1, parapet311). Se ia minimul dintre
			# buza si solul real + 0,1 m: pe umarul plat ramane pe buza, pe
			# rapa coboara cu terenul.
			# Cele doua cote de teren nu sunt de acord in apexul lui ac2: panza
			# de coliziune are o cuta cu 2,35 m sub campul neted (r2,
			# parapet292). Se ia cea mai INALTA dintre ele: un panou usor
			# suspendat peste cuta se citeste ca parapet, unul ingropat in ea
			# dispare. Si tot nu urca peste buza.
			var gy := maxf(_sol_real(q.x, q.z), _sampler.ground_y(q.x, q.z))
			_raw("rope_rail", "parapet",
				Vector3(q.x, minf(p.y + LIP, gy + 0.10), q.z),
				atan2(-tang.z, tang.x), 1.0, "none")


## Partea care CADE la indexul i: solul la 15 si 25 m lateral, stanga fata de
## dreapta. Se CITESTE din teren la fiecare asezare — partea alterneaza la
## fiecare ac (survey, nota 3), deci un „dreapta" hardcodat ar pune zidul pe
## versant jumatate din felie.
func _downhill_side(i: int) -> float:
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


# ------------------------------------------------------------------ asezarea

func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la MARGINEA corpului fizic. Cota din raycast pe TerrainBody.
## `dy` ridica/coboara fata de sol (zidul de sprijin coboara).
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
	# Degajarea fata de carosabil: orice corp fizic sub EDGE_KEEP de muchie e
	# un obstacol pe umar. Culoarul autobuzului trece pe jumatatea exterioara.
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < half - 1.0:
		_warn += 1
		print("; ATENTIE silueta %s la frac %.4f ajunge la %.2f m de ax (banda %.2f)" % [
			model, frac, d - cr, half])
	# ALT PICIOR DE SERPENTINA. Degajarea de mai sus se uita doar la muchia
	# LOCALA, si pe o serpentina asta nu ajunge: drumul se intoarce, deci 16-30 m
	# lateral de pe un picior cad pe ASFALTUL piciorului urmator. Masurat cand
	# randul `quenualJos` a fost mutat in rapa (runda 2): ProbeLaneClear a sarit
	# de la 18 la 34 de probe blocate, toate pe `quenualJos*_col`, la fractii
	# 0,700-0,850 — copaci plantati in banda de dedesubt.
	# Acelasi test ca `CliffFace._on_any_road`: distanta pe INEL intre indici,
	# ca sa nu se compare piesa cu propria ei curba.
	if mode != "none" and _on_any_road(q, i, r):
		_skipped += 1
		return
	# TERENUL REAL vs CAMPUL NETED. `_sol_real` e adevarul pentru fizica, dar
	# acolo unde panza de coliziune are o cuta sub campul neted piesa ajunge
	# sub linia pe care o vede ochiul (si pe care o masoara `probe_manual`):
	# in runda 1, `quenualJos192` sedea la -25,37 pe un teren citit -23,05,
	# adica 2,3 m ingropata.
	#
	# RUNDA 3: prima versiune refuza orice piesa la care cele doua cote difera
	# peste 1,5 m — si asta a taiat 84 de piese, aproape toate BOLOVANII DE PE
	# VERSANT, fiindca exact acolo panza e cutata. Adica garda contra unui
	# copac ingropat golea flancul dinspre munte, care e al doilea semnal al
	# barei. Se pastreaza cota REALA (fizica nu minte) si se refuza doar cand
	# piesa ar fi ingropata mai mult de jumatate din inaltimea ei — atunci nu
	# se mai vede oricum.
	var smooth := _sampler.ground_y(q.x, q.z)
	var sink := smooth - (g - dy)
	var piece_h: float = float(HEIGHT.get(model, 1.0)) * scl
	if sink > maxf(0.5 * piece_h, 1.0):
		_skipped += 1
		return
	# Cand campul neted e mai SUS decat panza, piesa se ridica la el: altfel
	# sta intr-o groapa invizibila (asta era defectul lui quenualJos192).
	if sink > 0.0:
		g = smooth + dy
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode, pitch)


## Cade punctul `p` pe carosabilul ALTUI tronson (nu pe cel local)?
##
## `home_i` e indexul de care apartine piesa; tot ce e la mai putin de
## NEAR_WINDOW de el pe inel se sare, altfel orice piesa s-ar respinge singura
## fata de propria ei curba. `body_r` e raza corpului fizic, ca sa se pastreze
## degajarea si la piese groase.
const NEAR_WINDOW_FRAC := 0.012   # ~24 m in fata si in spate pe 1986 m de tur
const OTHER_ROAD_KEEP := 1.2      # peste muchia celuilalt picior

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


## Ca `_raw`, dar cu scara verticala separata: zidul de sprijin isi pastreaza
## lungimea (ca sa se inlantuie cap la cap) si se strange doar pe inaltime, la
## fata de taluz disponibila.
func _raw_yz(model: String, base: String, pos: Vector3, yaw: float,
		h_scl: float, v_scl: float, mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0))
	b = b.scaled(Vector3(h_scl, v_scl, h_scl))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


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
	print("; asezate %d piese, %d refuzate (cota in dezacord), %d avertismente, ~%d triunghiuri" % [_n, _skipped, _warn, _tri])
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
