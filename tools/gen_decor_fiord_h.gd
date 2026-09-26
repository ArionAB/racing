extends Node
## Generator de decor MANUAL pentru POI H — MALUL SI PISTA DE AVIOANE
## (Track16, Fiordland, frac 0.90-1.00, drum drept pe mal, semi 8).
##
## Ca gen_decor_mp_g.gd: nu e sonda, e unealta care CALCULEAZA transformarile
## ce se lipesc in Track16.tscn sub `DecorManual/ZoneH_Mal`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordH.tscn -- \
##       --out=C:/cale/zoneH.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_fiordland/bara_poi_H.png)
##
## Lodge lung cu acoperis in doua ape, containere, heliport cu H alb, pista de
## avioane PARALELA cu drumul, avionul mic aterizand cu umbra pe pista, fagi
## rari. Cheiul in stanga-jos (POI A, nu al nostru). Bara e LOOK, nu LAYOUT:
## se compara materia, silueta, lumina — nu unde cade fiecare obiect
## (docs/track_briefs/fiordland_poi_gauntlet.md, "Regula care se incalca cel
## mai des").
##
## ------------------------------------------------------------------------
## CONTRACT (fiordland_poi_gauntlet.md, sectiunea H):
## - drum drept pe mal (semi 8), satul pe DREAPTA (lodge, cafe_shed ca magazie,
##   heliport gol);
## - pista de avioane paralela la ~20 m pe DREAPTA, dincolo de sat: fasie plata
##   CONCRETE/SAND_SHADOW la cota drumului, marcaje FOAM_WHITE, fara prag > 0,3 m;
## - avionul: PathMover, stick_to_ground=false, origine CENTRU fuzelaj,
##   cast_shadow ON si in shadow_distance (umbra pe pista/drum e ce se vede),
##   punct de start departe de grila (corp-cinematic-aparut-in-masina), umbra
##   NU peste grila in countdown;
## - apa pe STANGA = repunere (RespawnZone, construita de cod din
##   custom_ravines 0.919-0.999 — se verifica, nu se construieste aici);
## - dreapta lunga = loc de turbo (nu se pune decor cu coliziune pe banda).
##
## ------------------------------------------------------------------------
## SURVEY (runda 1, v2r1_survey.txt) — cifrele care decid compozitia.
## Traseu 2159,2 m; felia 0,90-1,00 = ~216 m, ultimul segment al turului.

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneH_Mal"

const F_IN := 0.905
const F_OUT := 0.995

## id-urile ext_resource din Track16.tscn (fundatia).
const RES := {
	"lodge": "s_lodge",
	"cafe_shed": "s_cafe_shed",
	"luggage_container": "s_luggage_container",
	"heli_pad": "s_heli_pad",
	"bush_plane": "s_bush_plane",
	"snow_pole": "s_snow_pole",
	"road_sign_blank": "s_road_sign_blank",
	"kayak_a": "s_kayak_a",
	"kayak_b": "s_kayak_b",
	"penguin_tawaki": "s_penguin_tawaki",
	"driftwood": "s_driftwood",
	"beech_a": "s_beech_a",
	"beech_b": "s_beech_b",
	"beech_c": "s_beech_c",
	"beech_dead": "s_beech_dead",
	"tree_fern": "s_tree_fern",
	"guard_rock": "s_guard_rock",
	"tussock_clump": "s_tussock_clump",
	"fern_cluster": "s_fern_cluster",
}

## Inaltimea AABB masurata (docs/asset_briefs/fiordland_masuratori.md §1).
const HEIGHT := {
	"lodge": 6.185, "cafe_shed": 3.656, "luggage_container": 2.600,
	"heli_pad": 0.300, "bush_plane": 1.850, "snow_pole": 2.000,
	# 26 sep 2026: kayak_a/b inlocuite (fiordland_stare_poi.md decizia #2) —
	# inaltimea a crescut de la 0,361 la 0,585 m (lungimea 3,6 m neschimbata).
	"road_sign_blank": 2.450, "kayak_a": 0.585, "kayak_b": 0.585,
	"penguin_tawaki": 0.770, "driftwood": 0.384,
	"beech_a": 7.030, "beech_b": 10.189, "beech_c": 13.501, "beech_dead": 8.515,
	"tree_fern": 3.306,
	"guard_rock": 0.585, "tussock_clump": 0.804, "fern_cluster": 1.0,
}

## Raza de degajare la sol (m) la scara 1. Copacii (`trunk`): raza la baza
## masurata (masuratori §1). Restul (`hull`/`none`): jumatatea laturii mari
## a AABB-ului orizontal.
const BASE_R := {
	"lodge": 8.72, "cafe_shed": 3.33, "luggage_container": 3.27,
	"heli_pad": 6.00, "bush_plane": 3.73, "snow_pole": 0.03,
	"road_sign_blank": 0.80, "kayak_a": 1.80, "kayak_b": 1.80,
	"penguin_tawaki": 0.21, "driftwood": 2.02,
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03, "beech_dead": 0.68,
	"tree_fern": 0.30,
	"guard_rock": 0.59, "tussock_clump": 0.35, "fern_cluster": 0.4,
}

const CROWN_R := {
	"lodge": 8.72, "cafe_shed": 3.33, "luggage_container": 3.27,
	"heli_pad": 6.00, "bush_plane": 4.00, "snow_pole": 0.03,
	"road_sign_blank": 0.80, "kayak_a": 1.80, "kayak_b": 1.80,
	"penguin_tawaki": 0.21, "driftwood": 2.02,
	"beech_a": 2.55, "beech_b": 3.18, "beech_c": 4.78, "beech_dead": 1.64,
	"tree_fern": 0.15,
	"guard_rock": 0.59, "tussock_clump": 0.35, "fern_cluster": 0.4,
}

const TRI := {
	"lodge": 636, "cafe_shed": 308, "luggage_container": 88, "heli_pad": 178,
	"bush_plane": 844, "snow_pole": 40, "road_sign_blank": 36,
	# 26 sep 2026: model nou, 94 -> 6775 tri (fara plafon, doar raportat).
	"kayak_a": 6775, "kayak_b": 6775, "penguin_tawaki": 282, "driftwood": 52,
	"beech_a": 228, "beech_b": 292, "beech_c": 292, "beech_dead": 136,
	"tree_fern": 768,
	"guard_rock": 72, "tussock_clump": 144, "fern_cluster": 60,
}

## Coliziunea per piesa (docs/asset_briefs/fiordland_masuratori.md §2, plus
## `world_prop.gd:PROP_COLLISION`). `_raw`/`_place` scriu metadata doar cand
## difera de implicitul "hull".
const MODE := {
	"beech_a": "trunk", "beech_b": "trunk", "beech_c": "trunk",
	"beech_dead": "trunk", "tree_fern": "trunk",
	"heli_pad": "none", "penguin_tawaki": "none", "kayak_a": "none",
	"kayak_b": "none", "bush_plane": "none", "fern_cluster": "none",
	"tussock_clump": "none",
}

## Degajarea minima de la MUCHIA drumului la marginea corpului fizic, pentru
## orice piesa cu coliziune (memoria aria-slotului-spune-cat-nu-ce nu se
## aplica aici, dar pragul e acelasi ca la POI G): dreapta lunga e loc de
## turbo, deci culoarul liber conteaza mai mult ca de obicei.
const EDGE_KEEP := 1.0

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
## Blocurile `[sub_resource ...]` (Curve3D-urile PathMover-ului), scrise
## INAINTEA blocurilor de noduri intr-un .tscn — separate ca sa poata fi
## splice-uite in locul corect (sectiunea de sub_resource a fisierului),
## nu amestecate printre nodurile din `_out`.
var _out_sub: Array[String] = []
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
	_rng.seed = 160901
	_survey()
	if not _survey_only:
		_village()
		_airstrip()
		_shore()
		_forest()
		_lodge_forest()
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
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.005
	while f <= F_OUT + 0.005:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
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

## (1) SATUL — lodge + magazie + heliport + containere, pe DREAPTA drumului
## (contract: "satul (lodge, magazii, heliport gol)"). Grupate compact ca in
## bara: lodge-ul cel mai aproape de drum, heliportul si containerele in
## spatele lui, spre pista de avioane.
func _village() -> void:
	# lodge: cladirea lunga, fatada spre drum. Yaw 90 ca fatada lunga (17 m pe
	# X in fisier) sa fie paralela cu drumul, nu perpendiculara.
	#
	# RUNDA 1: gap 6.0 respinsa de `_on_any_road`. RUNDA 2/3: mutat la frac
	# 0.910, gap 4.0 — geometric plasat corect, dar verdictul rundei 4 a
	# gasit cauza reala: `--gamecam` prива inainte doar LOOK_AHEAD=5 m (nu
	# spre un punct anume), deci la fractia de captura 0.91 camera se afla
	# la ~12,5 m in spatele lodge-ului si priveste aproape TANGENT la drum —
	# un obiect la +19 m lateral de axa cade la ~57° fata de directia
	# privirii, mult in afara jumatatii de FOV (34°). Calcul verificat
	# analitic (unghi camera->obiect, tangenta ~constanta pe 0.900-0.930):
	# la frac de captura 0.910, satul trebuie sa fie la 40-60 m INAINTE pe
	# drum (nu la 10-25 m) ca sa intre in con. Drumul ramane aproape drept
	# pana la 0.930 (deviatie tangentei < 10° fata de 0.910), deci mutarea nu
	# strica "paralel cu drumul". Sat + pista + avion mutate cu ~+0,010 in
	# frac (de la banda 0.908-0.917 la 0.918-0.927): la frac de captura 0.91,
	# lodge iese la unghi ~-28° (era -57°), heliport ~-20° (era -47°) —
	# ambele in con.
	_place("lodge", "lodge", 0.920, 1.0, 4.0, deg_to_rad(90.0), 1.0, "hull")
	# cafe_shed ca magazie, langa lodge, spre pista.
	_place("cafe_shed", "magazie", 0.923, 1.0, 10.0, deg_to_rad(-90.0), 1.0, "hull")
	# heliportul, disc gol, intre sat si pista de avioane.
	_place("heli_pad", "heliport", 0.926, 1.0, 14.0, 0.0, 1.0, "none")
	# containerele de bagaje, langa magazie.
	_place("luggage_container", "container", 0.921, 1.0, 16.0, deg_to_rad(20.0), 1.0, "hull")
	_place("luggage_container", "container", 0.924, 1.0, 16.5, deg_to_rad(-15.0), 1.0, "hull")
	# balize pe marginea drumului, lânga sat.
	_place("snow_pole", "baliza", 0.918, 1.0, 1.0, 0.0, 1.0, "none")
	_place("road_sign_blank", "semn", 0.927, 1.0, 2.0, deg_to_rad(-90.0), 1.0, "hull")
	# RUNDA 6: a doua instanta de lodge, LANGA heliport (verdict runda 5:
	# "langa heliportul cu H lipseste un lodge cu volum si silueta clara" —
	# primul lodge e la frac 0.920/gap 4.0, langa drum, dar captura de la
	# frac 0.98 (heliport + pista + avion in cadru) il priveste de peste
	# apa, la ~90 m, unde citeste ca pata alba, nu cladire. Piesa e deja in
	# kit (contract: "a doua instanta e ok"), deci nu se construieste nimic
	# nou: doar un al doilea `lodge` asezat chiar dupa heliport (gap 20.0,
	# fata de heliport la gap 14.0 + raza 6.0 -> centrul lui la ~2 m dincolo
	# de marginea heliportului, in acelasi cadru din care camera la 0.98
	# vede heliportul si pista). Yaw 90 ca fatada lunga sa ramana paralela
	# cu drumul/pista, la fel ca lodge1 — silueta de acoperis in doua ape
	# clar distincta de discul heliportului si de fasia pistei.
	_place("lodge", "lodgeHeli", 0.935, 1.0, 14.0, deg_to_rad(90.0), 1.0, "hull")
	print("; sat: lodge+magazie+heliport+containere asezate (2 lodge-uri)")


## (2) PISTA DE AVIOANE — fasie plata CONCRETE/SAND_SHADOW paralela cu drumul,
## la ~20 m pe dreapta (dincolo de sat), cu marcaje FOAM_WHITE. Nu exista GLB
## (contract): se construieste din PaletteBox-uri (fete plane, ca podetul de
## pe Chasm), la cota drumului local — nu la campul neted, ca sa nu apara
## praguri fata de teren (memoria suprafete-cu-goluri-si-praguri).
##
## Avionul: PathMover pe o curba scurta, in aer, coborand paralel cu drumul.
## `stick_to_ground=false` (contract), origine CENTRU (masurata), punct de
## start departe de grila (frac 0.905, la >200 m de start/finish care e la
## frac 0.0 — memoria corp-cinematic-aparut-in-masina), aterizare pe pista la
## frac ~0.97, cu umbra (cast_shadow ON, in shadow_distance).
##
## RUNDA 1, capcana gasita pe captura: brief-ul zice "drum drept pe mal"
## (§H), dar survey-ul arata contrariul — malul e o BUCLA aproape completa
## (0.900 la (35,1), 0.975 la (-70.8,40), inapoi la (-32.4,7.6) la 1.000;
## vectorul lateral se roteste ~180 grade). O pista la offset lateral
## CONSTANT fata de un drum care coteste asa iese ea insasi curbata — nu se
## vede ca pista dreapta, se vede ca o dunga arcuita fara sens. Singurul
## interval unde curbura e mica e chiar la intrare (0.900-0.930, unde side se
## roteste sub 10° fata de tangenta la 0.910) — acolo sta si satul.
##
## RUNDA 4: fasia mutata odata cu satul (vezi nota din `_village`), de la
## 0.900-0.917 la 0.912-0.930, ca la fractia de captura 0.91 sa fie in fata
## camerei (con de 34°), nu tangent la ea.
const STRIP_OFFSET := 22.0     # distanta laterala de la ax la mijlocul pistei
const STRIP_HALF_W := 6.0      # jumatate din latimea pistei de avioane
const STRIP_F_IN := 0.912
const STRIP_F_OUT := 0.930

## RUNDA 5, capcana gasita si reparata: `step` (mai jos) e o FRACTIE de traseu
## (`_step(3.0)` = 3 m convertiti in unitati de frac, ca sa avanseze `f`), dar
## codul vechi o refolosea DIRECT ca dimensiune in METRI a placii
## (`Vector3(step * 1.02, ...)`). Cu traseul la ~2162 m, `step` ~= 0.00139 —
## placa CONCRETE iesea lata de 1,4 MILIMETRI (confirmat in .tscn: `size =
## Vector3(0.001415, 0.06, 12.0)`), o linie invizibila. De-aici verdictul
## criticului: "avionul sta pe iarba, fara nicio dala de asfalt/beton sub el"
## — pista "exista" in .tscn, dar n-avea latime sa se vada. Fix: o constanta
## separata `SLAB_LEN_M` (lungimea placii de-a lungul drumului, in metri),
## `step` ramane doar pentru avansul pe frac.
const SLAB_LEN_M := 3.0

func _airstrip() -> void:
	var n := _track.baked.size()
	var f := STRIP_F_IN
	var step := _step(SLAB_LEN_M)
	var slabs := 0
	while f < STRIP_F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var mid := p + s * STRIP_OFFSET
		var y := _sol_real(mid.x, mid.z)
		# fasia: o placa PaletteBox plata, orientata pe tangenta locala.
		var tang := (_track.baked[(i + 3) % n] - _track.baked[(i - 3 + n) % n])
		tang.y = 0.0
		if tang.length() < 0.01:
			f += step
			continue
		tang = tang.normalized()
		var yaw := atan2(-tang.z, tang.x) + PI * 0.5
		_raw_box(mid + Vector3.UP * 0.02, yaw,
			Vector3(SLAB_LEN_M * 1.02, 0.06, STRIP_HALF_W * 2.0), "CONCRETE")
		slabs += 1
		# marcaj central FOAM_WHITE, mai ingust si mai scurt, la fiecare al
		# doilea pas (linie intrerupta, ca pe pista reala) — TRANSVERSAL pe
		# pista (lat pe directia drumului, ingust pe latimea pistei), ca in
		# bara ("marcaje albe transversale"): dimensiunea mare pe Z local
		# (STRIP_HALF_W-ul e pe Z), deci marcajul trebuie lat pe X, ingust pe Z.
		if slabs % 2 == 0:
			_raw_box(mid + Vector3.UP * 0.04, yaw,
				Vector3(SLAB_LEN_M * 0.5, 0.02, 1.2), "FOAM_WHITE")
		f += step
	print("; pista de avioane: %d placi la %.0f m de ax" % [slabs, STRIP_OFFSET])
	_plane()


## Avionul: PathMover e chiar un `Path3D` cu scriptul `path_mover.gd`
## (`class_name PathMover extends Path3D`). Formatul real (verificat pe
## Track01.tscn, nodul `PathMover` existent): `curve` e un `SubResource`
## declarat INAINTE de blocul `[node ...]`, cu punctele in coordonate LOCALE
## fata de `transform`-ul nodului — nu globale. Se pune deci originea
## transformului pe primul punct al curbei si restul punctelor relativ la ea.
func _plane() -> void:
	# Curba avionului: 4 puncte, DE-A LUNGUL FELIEI DREPTE (0.912-0.930, acolo
	# unde sta acum si pista si satul — RUNDA 4, vezi nota de la STRIP_F_IN/
	# OUT) — nu pe toata zona H, care se curbeaza aproape 180 grade. Start
	# departe de grila (frac 0.910, la >1900 m de start/finish, memoria
	# corp-cinematic-aparut-in-masina), aterizare pe pista langa heliport.
	# Coboara de la +25 m fata de sol la +0,3 (atinge pista), paralel cu
	# drumul, deplasat spre STRIP_OFFSET.
	var n := _track.baked.size()
	var pts: Array[Vector3] = []
	var heights: Array[float] = [25.0, 14.0, 3.0, 0.3]
	var offs: Array[float] = [STRIP_OFFSET - 4.0, STRIP_OFFSET, STRIP_OFFSET, STRIP_OFFSET]
	var fracs: Array[float] = [0.910, 0.917, 0.923, 0.927]
	for k in fracs.size():
		var i := int(fracs[k] * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var q: Vector3 = p + s * offs[k]
		var ground := _sol_real(q.x, q.z)
		pts.append(Vector3(q.x, ground + heights[k], q.z))
	var origin := pts[0]
	_n += 1
	var sid := "Curve3D_avionMal%d" % _n
	var pv: Array[String] = []
	for pt in pts:
		var loc := pt - origin
		# ORDINEA REALA (verificata empiric pe Curve3D_f51a1/Track01.tscn, un
		# PathMover STIUT bun): (in, out, POZITIE) - pozitia e a TREIA
		# tripleta, nu a doua. Scris gresit ca (in, pozitie, out) prima oara:
		# toate cele 4 puncte ieseau cu pozitia reala la (0,0,0) (tangenta
		# "out" citita ca pozitie), deci get_baked_length() intorcea 0.000 si
		# avionul nu se misca deloc - prins cu `--train-at diag` in
		# tools/snapshot.gd. In/out zero: segmente drepte intre puncte.
		pv.append("0, 0, 0, 0, 0, 0, %f, %f, %f" % [loc.x, loc.y, loc.z])
	_out_sub.append('[sub_resource type="Curve3D" id="%s"]' % sid)
	_out_sub.append('_data = {')
	_out_sub.append('"points": PackedVector3Array(%s),' % ", ".join(pv))
	var tilt_parts: Array[String] = []
	for _t in pts.size():
		tilt_parts.append("0")
	_out_sub.append('"tilts": PackedFloat32Array(%s)' % ", ".join(tilt_parts))
	_out_sub.append('}')
	_out_sub.append('point_count = %d' % pts.size())
	# `up_vector_enabled` e proprietate a RESURSEI Curve3D, nu a nodului
	# Path3D — pusa pe node n-are efect. Cu ea ON (implicit), bake-ul curbei
	# calculeaza intern un vector "sus" pe traiectorie cu Basis.looking_at pe
	# tangenta fiecarui punct; un prim segment scurt/aproape vertical (avionul
	# coboara abrupt din start) a dat "ERROR: The target vector can't be
	# zero." la incarcare. PathMover nu foloseste vectorul sus (yaw-ul vine
	# din `_travel_yaw`, manual) — se stinge la sursa.
	_out_sub.append('up_vector_enabled = false')
	_out_sub.append("")
	var nm := "avionMal%d" % _n
	_out.append('[node name="%s" type="Path3D" parent="%s"]' % [nm, ZONE])
	_out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)'
		% [origin.x, origin.y, origin.z])
	_out.append('curve = SubResource("%s")' % sid)
	_out.append('script = ExtResource("s_path_mover_script")')
	_out.append('model = ExtResource("s_bush_plane")')
	_out.append('model_scale = 1.0')
	_out.append('speed = 9.0')
	_out.append('travel_mode = 1')  # DUS_INTORS: aterizeaza, se intoarce, decoleaza
	_out.append('phase = 0.0')
	_out.append('stick_to_ground = false')
	_out.append("")
	_tri += int(TRI.get("bush_plane", 0))
	print("; avion: PathMover pe %d puncte, de la frac 0.910 la 0.927" % pts.size())


## (3) MALUL — apa pe stanga = repunere (verificata, nu construita aici):
## driftwood, caiace, pinguini pe malul stang, aproape de apa. `guard_rock`
## pe marginea dinspre mare (contract, comun tuturor zonelor).
func _shore() -> void:
	var fracs_drift := [0.910, 0.945, 0.960, 0.978]
	for f in fracs_drift:
		_place("driftwood", "malDriftwood", f, -1.0, 1.5,
			_rng.randf_range(0.0, TAU), 1.0, "none")
	# 26 sep 2026: kayak_a/b inlocuite cu un model nou (canoe CC-BY-4.0, vezi
	# fiordland_stare_poi.md) — latimea AABB a crescut de la 0,58 la 1,61 m
	# (tools/sv_boat_aabb_v2.gd; lungimea 3,6 m a ramas neschimbata prin
	# constructie). Gap-ul lateral dintre cele doua caiace era 0,6 m (3,0 vs
	# 3,6), suficient pentru latimea veche (2x0,29 m) dar nu si pentru cea
	# noua (2x0,805 m) — marit la 2,0 m ca sa nu se suprapuna vizual.
	_place("kayak_a", "malKayak", 0.922, -1.0, 3.0, deg_to_rad(8.0), 1.0, "none")
	_place("kayak_b", "malKayak", 0.923, -1.0, 5.0, deg_to_rad(-6.0), 1.0, "none")
	for i in 3:
		var f: float = 0.950 + 0.006 * float(i)
		_place("penguin_tawaki", "malPinguin", f, -1.0,
			_rng.randf_range(0.5, 2.0), _rng.randf_range(0.0, TAU), 1.0, "none")
	for f in [0.912, 0.950, 0.988]:
		_place("guard_rock", "malGuard", f, -1.0,
			_rng.randf_range(4.0, 9.0), _rng.randf_range(0.0, TAU), 1.0, "hull")
	print("; mal: driftwood/caiace/pinguini/guard_rock asezate")


## (4) FAGII RARI — brief: "fagi rari" pe H, nu padure densa ca la D. Cateva
## exemplare pe stanga (spre mal, ferindu-se de RespawnZone-ul apei) si pe
## dreapta, dincolo de pista de avioane, ca sa incadreze scena fara sa
## aglomereze. ARANJAMENT, nu grila (memoria aranjamentul-bate-numarul):
## jitter pe fractie si pe gap, yaw variat, mix de specii/varste.
func _forest() -> void:
	var species := ["beech_a", "beech_b", "beech_a", "beech_c", "beech_dead", "beech_b"]
	# RUNDA 4: verdictul criticului identifica exact acest sir (side_sign
	# -1, spre apa) ca sursa golului din stanga/mijlocul cadrului — la
	# distanta de 14 pasi de fractie (~30 m) intre 0.913 si 0.927, cu gap
	# 6-16 m, un singur copac cade in conul camerei la 0.91 si urmatorul e
	# prea departe ca sa citeasca "sir". Adaugate 3 exemplare intre ele
	# (0.907/0.910/0.917, gap mai mic 3-9 m ca sa fie mai aproape de drum si
	# deci mai mari in cadru), pastrand jitter-ul si fara sa devina grila
	# (spatiere neregulata, nu echidistanta).
	var side_left := [0.907, 0.910, 0.913, 0.917, 0.920, 0.927, 0.944, 0.957, 0.970, 0.983]
	for k in side_left.size():
		var f: float = side_left[k] + _rng.randf_range(-0.002, 0.002)
		var gap: float = _rng.randf_range(3.0, 9.0) if f < 0.922 else _rng.randf_range(6.0, 16.0)
		_place(species[k % species.size()], "fagMalA", f, -1.0, gap,
			_rng.randf_range(0.0, TAU), 1.0, MODE.get(species[k % species.size()], "trunk"))
	# dreapta, dincolo de pista (>= STRIP_OFFSET + STRIP_HALF_W + 3): rar, ca
	# sa nu inchida cadrul spre orizont. Pista s-a mutat (STRIP_F_IN 0.912),
	# prima entitate urmeaza (0.919 -> 0.929).
	var side_right := [0.929, 0.938, 0.966, 0.990]
	for k in side_right.size():
		var f: float = side_right[k] + _rng.randf_range(-0.002, 0.002)
		var gap: float = STRIP_OFFSET + STRIP_HALF_W - 8.0 + _rng.randf_range(6.0, 14.0)
		var sp: String = species[(k + 3) % species.size()]
		_place(sp, "fagMalB", f, 1.0, gap, _rng.randf_range(0.0, TAU), 1.0,
			MODE.get(sp, "trunk"))
	# ferigi/tufe razlete la baza fagilor, ca sub-etaj (nu grila: densitate
	# usor crescanda spre mal, unde bara arata mai mult verde jos).
	for i in 10:
		var f: float = F_IN + _rng.randf_range(0.0, F_OUT - F_IN)
		var side: float = -1.0 if _rng.randf() < 0.6 else 1.0
		var gap: float = _rng.randf_range(2.0, 10.0)
		_place("fern_cluster", "fagFeriga", f, side, gap,
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.3), "none")
	for i in 6:
		var f: float = F_IN + _rng.randf_range(0.0, F_OUT - F_IN)
		var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
		var gap: float = _rng.randf_range(3.0, 12.0)
		_place("tussock_clump", "fagTussock", f, side, gap,
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.2), "none")
	print("; fagi rari + subetaj asezate")


## (5) PADUREA DIN SPATELE SATULUI — runda 2 a adaugat 3 clustere, dar pe
## RANDURI la fractii aproape echidistante (grila deghizata): aceeasi specie
## ciclata `sp_i % 6` in ordine fixa, scala doar +-10% (aproape identica),
## fara inclinare, fara specie la margine — verdict runda 3 (critic orb):
## "fagii din jurul pistei/heliportului sunt instante clonate identic —
## aceeasi coroana, aceeasi inaltime, aceeasi orientare, plantate in aceeasi
## linie". Nota coordonator: scara jitter +-15% NESISTEMATICA (nu doar mica
## variatie, ci si outlieri ocazionali), yaw complet aleator (era deja),
## inclinare usoara +-4 grade, amestec beech_a/b/c + beech_dead + tree_fern
## LA MARGINE, grupuri neregulate de 2-5 cu GOLURI intre ele, NU in linie.
##
## Geometrie neschimbata fata de runda 2 (lodge la frac 0,910 gap 4,0 ->
## centru la ~19,2 m de ax; heliport 0,916 gap 14,0 -> ~26,7 m; containere
## 0,911/0,914 gap 16-16,5; pista incepe la 16 m de ax): aceleasi trei benzi
## de fractie (inainte de lodge, intre lodge si heliport, dupa heliport),
## dar populate cu CLUSTERE de 2-5 copaci in loc de randuri, centrele
## clusterelor plasate cu jitter mare pe fractie SI pe gap, cu goluri reale
## intre clustere (nu acoperire continua).
func _lodge_forest() -> void:
	# specie: distribuita per-CLUSTER (nu ciclata copac cu copac), ca fiecare
	# grup sa aiba silueta de contur diferita de vecinul lui; tree_fern doar
	# la marginea clusterelor ("amestec ... + tree_fern la margine").
	var trunk_species := ["beech_a", "beech_b", "beech_c", "beech_dead"]
	# RUNDA 4: satul mutat cu +0,010 in frac (lodge 0.910->0.920, vezi
	# `_village`), benzile se muta odata cu el. Banda A ("inainte de lodge")
	# marita si densificata: verdictul rundei 4 arata exact acest interval —
	# la fractia de captura 0.91 camera priveste spre 0.905-0.925, adica
	# spre banda A si inceputul lodge-ului. Un "gol mare de iarba" acolo
	# citeste "camp cu un copac"; contractul cere "lizera continua in cadru"
	# (fagi rari CA EXEMPLARE, dar sirul neintrerupt), deci n_clusters creste
	# 3->5 si banda se lateste ca sa acopere tot intervalul vizibil inainte
	# de lodge, nu doar coada lui.
	# gap_min 3.0 (nu 1.5): jitter-ul de cluster (+-1.6 pe gap_center, +-1.6
	# per membru) putea impinge centrul unui fag sub `hw_here + ROAD_MARGIN`
	# (probe_manual, prag 2.0 de la muchie) desi `_place` insusi il accepta
	# (EDGE_KEEP 1.0 e doar warning) — prins de probe_manual ca "IN DRUM"
	# (fagLodgeA_5 la 8.9 m, runda 4).
	var bands := [
		# [f0, f1, gap_min, gap_max, n_clusters] — cele trei benzi.
		[0.902, 0.918, 3.0, 9.5, 5],   # inainte de lodge (lizera din cadru)
		[0.9195, 0.9255, 3.0, 6.5, 2], # intre lodge si heliport
		[0.9265, 0.939, 3.0, 6.5, 3],  # dupa heliport/containere, spre pista
	]
	var band_names := ["fagLodgeA", "fagLodgeB", "fagLodgeC"]
	var cluster_id := 0
	for bi in bands.size():
		var band: Array = bands[bi]
		var f0: float = band[0]
		var f1: float = band[1]
		var gap_min: float = band[2]
		var gap_max: float = band[3]
		var n_clusters: int = band[4]
		# centrele clusterelor: NU echidistante — jitter pe segment plus un
		# gol garantat intre clustere consecutive, ca sa nu citeasca linie.
		var edges: Array[float] = []
		for c in n_clusters:
			edges.append(f0 + (f1 - f0) * (float(c) + 0.5) / float(n_clusters))
		for ci in n_clusters:
			cluster_id += 1
			var f_center: float = edges[ci] + _rng.randf_range(-0.35, 0.35) * (f1 - f0) / float(n_clusters)
			var gap_center: float = _rng.randf_range(gap_min, gap_max)
			var group_n := _rng.randi_range(2, 5)
			# specia dominanta a clusterului (silueta de grup diferita intre
			# clustere), cu o sansa mica de tree_fern la primul/ultimul
			# membru al grupului ("la margine").
			var dom_a: String = trunk_species[_rng.randi() % trunk_species.size()]
			var dom_b: String = trunk_species[_rng.randi() % trunk_species.size()]
			for m in group_n:
				var is_edge_member := (m == 0 or m == group_n - 1)
				var sp: String = dom_a if _rng.randf() < 0.6 else dom_b
				if is_edge_member and _rng.randf() < 0.35:
					sp = "tree_fern"
				# jitter individual in jurul centrului clusterului — pozitia
				# fiecarui membru variaza pe fractie SI pe gap, ca grupul sa
				# aiba contur neregulat, nu un cerc perfect.
				var f: float = f_center + _rng.randf_range(-0.55, 0.55) * (f1 - f0) / float(n_clusters * 2)
				# podea de 2.2 pe gap: cu raza fagului (~0.7-1.0) tine centrul
				# piesei clar peste hw_here+ROAD_MARGIN (probe_manual, 2.0),
				# altfel jitter-ul de -1.6 pe un gap_center minim (3.0) poate
				# cobori sub prag ("IN DRUM", prins runda 4 pe fagLodgeA_5).
				var gap: float = maxf(gap_center + _rng.randf_range(-1.6, 1.6), 2.2)
				var yaw := _rng.randf_range(0.0, TAU)
				# scara: jitter +-15% NESISTEMATIC — in loc de o banda mica
				# si uniforma, trage din doua regimuri (majoritatea aproape
				# de 1.0, o parte rar mai marcanta) ca sa nu se vada "toate
				# putin mai mici/mai mari la fel".
				var scl: float
				if _rng.randf() < 0.75:
					scl = 1.0 + _rng.randf_range(-0.06, 0.06)
				else:
					scl = 1.0 + _rng.randf_range(-0.15, 0.15)
				# inclinare usoara, axa aleatorie (facuta in _raw).
				var tilt := deg_to_rad(_rng.randf_range(-4.0, 4.0))
				_place(sp, "%s_%d" % [band_names[bi], cluster_id], f, 1.0, gap,
					yaw, scl, MODE.get(sp, "trunk"), tilt)
	print("; padurea din spatele satului: %d clustere neregulate (runda 3, mix + inclinare)" % cluster_id)


# ------------------------------------------------------------------ asezarea

func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Cat de mult poate cobori terenul sub cota drumului local inainte ca o
## piesa de mal (stanga = spre mare) sa fie refuzata. Survey (v2r1_survey.txt):
## de la frac ~0.920 solul de pe stanga cade la -8..-30 m incepand chiar de
## la 8 m lateral — piesele trebuie sa ramana pe PLATOUL de langa drum, nu pe
## taluzul falezei (RespawnZone e a apei, nu a decorului nostru).
const MAX_DROP_FROM_ROAD := 2.5

## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la MARGINEA corpului fizic. Cota din raycast pe TerrainBody.
## `tilt_rad` (implicit 0): inclinare mica a trunchiului fata de verticala,
## in jurul unei axe orizontale aleatorii — organic, nu geometrie perfecta
## (verdict runda 3: fagii citeau "clonati", vezi _lodge_forest).
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String,
		tilt_rad: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	# Refuza panta falezei: piesa ar cadea in gol vizual (sau chiar in mare
	# pe geometrie), oricat de "reala" ar fi cota raycast-ului.
	if p.y - g > MAX_DROP_FROM_ROAD:
		_skipped += 1
		return
	# ALT PICIOR DE DRUM. Malul (frac 0.90-1.00) coteste puternic (survey:
	# vectorul lateral se roteste aproape complet intre 0.905 si 0.995) —
	# exact tiparul documentat in gen_decor_mp_g.gd ("ALT PICIOR DE
	# SERPENTINA"): un punct asezat relativ la frac-ul LOCAL poate cadea
	# geometric langa un alt segment de drum, mai aproape decat orice
	# semi-latime locala sugereaza. probe_manual masoara distanta fata de
	# CEL MAI APROPIAT punct baked, nu fata de frac-ul de asezare, deci o
	# piesa "la 26 m de axul ei" poate iesi "la 3,7 m de axul altui picior".
	if mode != "none" and _on_any_road(q, i, r):
		_skipped += 1
		return
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < half - 1.0:
		_warn += 1
		print("; ATENTIE silueta %s la frac %.4f ajunge la %.2f m de ax (banda %.2f)" % [
			model, frac, d - cr, half])
	var smooth := _sampler.ground_y(q.x, q.z)
	var sink := smooth - g
	var piece_h: float = float(HEIGHT.get(model, 1.0)) * scl
	var zvelt: bool = model.begins_with("beech")
	var max_sink: float = 0.8 if zvelt else maxf(0.5 * piece_h, 1.0)
	if sink > max_sink:
		_skipped += 1
		return
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode, tilt_rad)


## Cade punctul `p` pe carosabilul ALTUI tronson (nu pe cel local)? Portul
## din gen_decor_mp_g.gd (memoria din brief-ul Machu Picchu POI G): `home_i`
## e indexul de care apartine piesa; tot ce e la mai putin de NEAR_WINDOW de
## el pe inel se sare, altfel orice piesa s-ar respinge singura fata de
## propria ei curba.
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
		mode: String, tilt_rad: float = 0.0) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri). Ordinea Euler
	# conteaza pentru cum se "citeste" inclinarea: yaw intai (in jurul Y,
	# fiindca modelul e simetric pe azimut), apoi o mica inclinare pe X/Z ca
	# axa de inclinare sa nu fie mereu aceeasi fata de drum (altfel toti
	# trunchiurile s-ar apleca "in aceeasi directie", tot un pattern).
	var tilt_axis := deg_to_rad(360.0) * _rng.randf()
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0))
	if tilt_rad != 0.0:
		b = Basis(Vector3(cos(tilt_axis), 0.0, sin(tilt_axis)), tilt_rad) * b
	b = b.scaled(Vector3(scl, scl, scl))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## Placa plana pentru pista de avioane: PaletteBox-like, un MeshInstance3D
## direct in .tscn (nu exista GLB, contract explicit).
##
## RUNDA 5, doua bug-uri gasite si reparate in aceasta functie:
##
## (1) `[sub_resource]` era scris in `_out` (blocul de NODURI), DUPA nodul
## care il refera prin `SubResource("BoxMesh_...")`. Godot cere id-ul
## declarat INAINTE de orice referinta in fisier — cu sub_resource dupa,
## incarcarea Track16.tscn pica cu "Parse Error: Invalid parameter" chiar la
## acel nod (confirmat: `probe_decor` nu rula deloc, proces Godot ramas la
## 5 MB / 0 CPU time, aparent "blocat", de fapt mort pe eroare de parsare).
## Fix: sub_resource-ul merge in `_out_sub`, care `_write()` il varsa
## INAINTEA blocului de noduri.
##
## (2) Placile ieseau cu dungi curcubeu (atlasul de paleta intins pe UV-ul
## implicit al BoxMesh-ului), nu beton. Cauza NU era lipsa unui
## `material_override` in .tscn — orice valoare pusa acolo manual e
## SUPRASCRISA necondiționat la incarcare: `DecorManual` are scriptul
## `world_prop.gd` (scenes/tracks/Track16.tscn, nodul chiar), al carui
## `_ready()` ruleaza `Palette.apply_class_materials(self, prop_classes())`
## pe TOT subarborele — orice `MeshInstance3D` al carui nume nu se
## potriveste cu un prefix din maparea globala primeste necondiționat
## `world_material()` (scripts/palette.gd:1739). Descoperit abia in
## captura, nu la incarcare (fara eroare de parsare, deci `probe_decor`/
## `probe_manual` treceau "verde" in timp ce placile erau curcubeu).
## Fix real: inregistrat prefixul "pistaAvioane*" in
## `TrackDecor.FIORDLAND_AIRSTRIP_CLASSES` (scenes/tracks/track_decor.gd),
## adaugat in `world_prop.prop_classes()` — acelasi mecanism ca orice alt
## GLB de pe alta clasa triplanara ("concrete" pt dala, "village_plaster"
## pt marcaje, ambele clase EXISTENTE, zero material nou). Generatorul nu
## mai scrie niciun material in .tscn: doar `metadata/tri_class`, folosit
## de `probe_decor.gd` pentru raportare.
func _raw_box(pos: Vector3, yaw: float, size: Vector3, cls: String) -> void:
	_n += 1
	var nm := "pistaAvioane%s%d" % [cls.to_lower(), _n]
	_out_sub.append('[sub_resource type="BoxMesh" id="BoxMesh_%s"]' % nm)
	_out_sub.append("size = Vector3(%f, %f, %f)" % [size.x, size.y, size.z])
	_out_sub.append("")
	_out.append('[node name="%s" type="MeshInstance3D" parent="%s"]' % [nm, ZONE])
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	_out.append('mesh = SubResource("BoxMesh_%s")' % nm)
	_out.append('metadata/tri_class = "%s"' % cls)
	_out.append('metadata/coliziune = "none"')
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate (cota in dezacord), %d avertismente, ~%d triunghiuri" % [_n, _skipped, _warn, _tri])
	if not _out_sub.is_empty():
		print("; %d bloc(uri) sub_resource (Curve3D avion) — de lipit in sectiunea [sub_resource] a Track16.tscn, NU sub ZoneH_Mal" % (_out_sub.size()))
	if _out_path.is_empty():
		for line in _out_sub:
			print(line)
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out_sub:
		fa.store_line(line)
	fa.store_line("; --- SPLIT AICI: de sus merge la [sub_resource], de jos sub ZoneH_Mal ---")
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
