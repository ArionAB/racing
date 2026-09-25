extends Node
## Generator de decor MANUAL pentru POI C — CASCADA STIRLING (Track16,
## Fiordland, frac 0.273-0.323, segment perdea 0.273-0.323 cu miezul la
## 0.297, semi-latime 6).
##
## Ca la Machu Picchu G (gen_decor_mp_g.gd): nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track16.tscn sub
## `DecorManual/ZoneC_Stirling`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorFiordC.tscn -- \
##       --out=C:/cale/zoneC.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_fiordland/bara_poi_C.png)
##
## Perdea alba lata care cade de pe buza de roca DIRECT peste drum, bazin alb
## cu spray la baza, peretele din spatele ei intunecat si ud, muschi pe buza.
## Mai vizibil in bara: doi papagali (kea) pe stanca din dreapta, coronament
## des deasupra peretelui, bolovani cu muschi la baza, un pic de vegetatie
## agatatoare pe fata stancii.
##
## Bara e LOOK, nu LAYOUT: perdeaua, spray-ul si bazinul sunt COD
## (`WaterfallHazard`/`WaterfallVisual`, deja montat la fundatie ca
## `StirlingFalls`, `visual_height=14.0`, `length=30.0`, `thickness=6.0`).
## POI-ul C NU construieste apa. NU muta `stirlingLedge`
## (Wall/Overhang/Shelf, `--origin=assembly`, deja plasat la fundatie).
## Construieste DOAR ce e in jurul ei: muschiul pe buza/nisa, bolovanii uzi
## la baza peretelui, fagii pe platoul de deasupra, un rata_tree, un
## guard_rock spre mare.
##
## ------------------------------------------------------------------------
## GEOMETRIA CUNOSCUTA (fundatie, inventory + masuratori):
##   Wall: fata peretelui la ~8,0 m de axa (semi 6 + sagita 1,8 + prag).
##   Overhang (buza): x in [-9.97, 3.50] LOCAL, y in [14.00, 21.40] LOCAL,
##     GLOBAL prin transform stirlingLedge (rotatie ~50 deg pe Y, pos
##     (-446.267, 31.900, -386.642)).
##   Shelf (pragul uscat): local pos (0, 0.38, -15.00), size (3.00, 0.02, 30.00).
##   Perdeaua (cod): 6 m latime CENTRATA PE AXA drumului, 30 m lungime de-a
##     lungul drumului, cade de la +14,0 peste jumatatea dinspre perete.
##
## Peretele e pe DREAPTA drumului (side pozitiv, ca la Wall x in [-1.90,11.58]
## local, deci spre +x local = spre exteriorul curbei). Nu presupun semnul:
## il masor din survey (`_wall_side`), ca la G (memoria rotatii-in-builder-semnul).
##
## ------------------------------------------------------------------------
## AMPLASARE (masurata in --survey, vezi antetul umplut dupa rulare):
##
## SURVEY (rulat 25 sep 2026, out=C_survey.txt):
##   la fractia 0.297 (mijlocul perdelei): axa (-451.6, 31.9, -380.6),
##   half=6.0, side=(0.768,-0.008,-0.641) [aprox, din transform stirlingLedge]
##   panta drum ~ usor urcatoare spre interior (cornisa mare pe stanga,
##   perete pe dreapta).
##   Peretele (Wall) e pe side POZITIV (dreapta drumului in sensul de mers),
##   la ~8 m; nisa/Overhang iese peste drum pana la ~3.5 m fata de perete deci
##   ~4.5 m de axa pe partea de perete.
##   Marea (rapa cornisa) e pe side NEGATIV, fund -30, deci guard_rock spre
##   mare se pune pe side negativ la marginea drumului (~half+1.5).
##
## ------------------------------------------------------------------------
## ARANJAMENT (aranjamentul-bate-numarul): fara grila, jitter >= 0.5*pas, yaw
## variat, densitate crescatoare spre subiect (peretele/nisa), ocluzie
## (bolovani mari in fata, fagi mici in spate se ascund partial).
##
## AI-UL NU VEDE DECOR STATIC: nimic cu coliziune pe carosabil (|lat| < half)
## sau pe banda (in Fiordland nu exista banda secundara la Stirling — un
## singur drum). EDGE_KEEP tine orice piesa cu coliziune la >= 0.8 m dincolo
## de muchie.

const TRACK := "res://scenes/tracks/Track16.tscn"
const ZONE := "DecorManual/ZoneC_Stirling"

const F_CENTER := 0.297
const F_IN := 0.273
const F_OUT := 0.323
## Felie putin mai larga decat segmentul perdelei, ca sa incapa fagii de pe
## platou si guard_rock spre iesirea din zona.
const F_SURVEY_IN := 0.255
const F_SURVEY_OUT := 0.345

## id-urile ext_resource din Track16.tscn (deja inregistrate).
const RES := {
	"beech_a": "s_beech_a", "beech_b": "s_beech_b", "beech_c": "s_beech_c",
	"beech_dead": "s_beech_dead",
	"moss_boulder_a": "s_moss_boulder_a", "moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"fern_cluster": "s_fern_cluster", "tree_fern": "s_tree_fern",
	"guard_rock": "s_guard_rock", "tussock_clump": "s_tussock_clump",
	"rata_tree": "s_rata_tree",
}

## Inaltimea AABB masurata (fiordland_masuratori.md / fiordland_inventory.md;
## moss_boulder si tree_fern din machu_picchu_masuratori.md, reuse).
const HEIGHT := {
	"beech_a": 6.10, "beech_b": 8.80, "beech_c": 11.17, "beech_dead": 8.51,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"fern_cluster": 0.90, "tree_fern": 3.306,
	"guard_rock": 0.585, "tussock_clump": 0.80,
	"rata_tree": 3.67,
}

## Raza de degajare la sol (m) la scara 1.
const BASE_R := {
	"beech_a": 0.318 * 6.10, "beech_b": 0.242 * 8.80, "beech_c": 0.216 * 11.17,
	"beech_dead": 0.30 * 8.51,
	"moss_boulder_a": 0.85 * 0.5, "moss_boulder_b": 2.48 * 0.5,
	"moss_boulder_c": 4.21 * 0.5,
	"fern_cluster": 0.45, "tree_fern": 0.15,
	"guard_rock": 0.59, "tussock_clump": 0.40,
	"rata_tree": 0.930 * 3.67,
}

const TRI := {
	"beech_a": 228, "beech_b": 292, "beech_c": 292, "beech_dead": 136,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"fern_cluster": 120, "tree_fern": 768,
	"guard_rock": 72, "tussock_clump": 144,
	"rata_tree": 354,
}

const COLLISION := {
	"beech_a": "trunk", "beech_b": "trunk", "beech_c": "trunk",
	"beech_dead": "trunk",
	"moss_boulder_a": "hull", "moss_boulder_b": "hull", "moss_boulder_c": "hull",
	"fern_cluster": "hull", "tree_fern": "trunk",
	"guard_rock": "hull", "tussock_clump": "hull",
	"rata_tree": "hull",
}

## Degajarea minima de la muchia drumului (m), pentru orice piesa cu
## coliziune. Fara banda secundara la Stirling, deci o singura muchie pe
## fiecare parte.
##
## RUNDA 1: probe_manual a raportat 12 "IN DRUM" la EDGE_KEEP=0.8. Cauza:
## garda nu masoara fata de `half_width` + EDGE_KEEP, masoara fata de
## `half_width` + ROAD_MARGIN (2.0, `tools/probe_manual.gd`), pe distanta 3D
## catre cel mai apropiat punct copt, nu doar lateral. `stirlingLedge` insusi
## trece la limita (8.3 m, half 6.0 -> marja 2.3). Deci orice piesa NOUA cu
## coliziune trebuie sa treaca de half+2.0 cu rezerva, nu de half+0.8.
const EDGE_KEEP := 2.4

var _track: Track
var _sampler: TrackSideSampler
var _wall_side := 1.0   # +1 daca peretele e pe side pozitiv, -1 altfel
var _n := 0
var _tri := 0
var _skipped := 0
var _out: Array[String] = []
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
	_rng.seed = 160297
	_survey()
	if not _survey_only:
		_wall_side = _detect_wall_side()
		print("; wall_side = %.0f" % _wall_side)
		_moss_and_nook()
		_wet_boulders()
		_plateau_beeches()
		_rata_and_guard()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        sol la -15 -11 -9 -7 -5 -3 | +3 +5 +7 +9 +11 +15")
	var f := F_SURVEY_IN
	while f <= F_SURVEY_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-15.0, -11.0, -9.0, -7.0, -5.0, -3.0, 3.0, 5.0, 7.0, 9.0, 11.0, 15.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sampler.ground_y(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols)])
		f += 0.003
	# transformul stirlingLedge, ca sa deriv fata peretelui in coordonate
	# locale drumului la f=0.297.
	var i0 := int(F_CENTER * float(n)) % n
	var p0 := _track.baked[i0]
	var s0 := _track._side_at(i0)
	print("; la centrul perdelei f=%.3f: axa=(%.2f,%.2f,%.2f) side=(%.3f,%.3f,%.3f) y_drum=%.2f" % [
		F_CENTER, p0.x, p0.y, p0.z, s0.x, s0.y, s0.z, p0.y])


## Detecteaza pe ce parte a drumului e peretele Stirling.
##
## NU se poate citi din `ground_y` (terenul): survey-ul (25 sep, out=
## poi_c_survey.txt) arata solul practic PLAT (-0.3..-0.4 m) pe AMBELE parti
## la f=0.279-0.345 — peretele Stirling e geometrie GLB (`stirling_ledge`),
## nu relief al terenului, deci sonda de teren nu-l vede (nu e cazul lui
## `umarul-ingust-ascunde-caderea`, unde cade terenul real; aici cade doar
## afara zonei, la f<0.279, cornisa marii pe side NEGATIV).
##
## Se calculeaza direct din nodul `stirlingLedge` deja plasat (fundatie):
## Wall x local in [-1.90, 11.58] proiectat pe transform-ul lui in coordonate
## laterale fata de axa drumului la f=0.297 da lat in [+6.1, +8.6] — deci
## peretele e pe side POZITIV. Verificat independent (nu ghicit — memoria
## rotatii-in-builder-semnul): Overhang da acelasi semn ([+7.4, +9.9]).
func _detect_wall_side() -> float:
	var ledge := _track.get_node_or_null("%s/stirlingLedge" % ZONE)
	if ledge == null:
		push_warning("stirlingLedge nu a fost gasit; presupun wall_side=+1 (masurat 25 sep)")
		return 1.0
	var t: Transform3D = (ledge as Node3D).global_transform
	var wall_mid_local := Vector3(4.84, 0.0, 0.0)   # mijlocul Wall pe x local
	var wall_world: Vector3 = t * wall_mid_local
	var n := _track.baked.size()
	var i := int(F_CENTER * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var s: Vector3 = _track._side_at(i)
	var lat: float = (wall_world - p).dot(s)
	print("; Wall (mijloc) la lat=%.2f fata de axa" % lat)
	return 1.0 if lat > 0.0 else -1.0


# ------------------------------------------------------------------ compozitia

## (1) MUSCHIUL PE BUZA/NISA — bara cere explicit muschi pe buza surplombului.
## Nu avem un asset "moss patch" separat in kitul de fundatie (§1.8: doar
## moss_boulder_*, care e bolovan cu muschi, nu o pata pe stanca). Solutia:
## moss_boulder mici agatate pe traseul buzei, ca sa citeasca drept muschi
## crescut pe piatra, nu bolovani cazuti — varianta cea mai apropiata din kit,
## ca la Machu Picchu unde moss_boulder acopera acelasi rol de "piatra
## verde umeda" langa apa.
##
## RUNDA 1: prima varianta ancora la `y_drum + 14 + jitter`, o cota GHICITA.
## `probe_manual` a raportat corect PLUTESTE (14 m peste terenul de dedesubt) —
## terenul e real, cota mea nu era legata de nimic. Piesele stau pe stanca
## `stirling_ledge` (Wall/Overhang), nu pe teren, deci ancora corecta e o
## RAZA fizica in jos din deasupra buzei pana cand atinge coliziunea REALA a
## stancii (mesh, per masuratori — nisa concava, `probe_manual`-ul altor
## piese "pe apa"/"pe structura" foloseste acelasi principiu: ancora e
## suprafata pe care piesa chiar sta, nu terenul de dedesubt).
##
## RUNDA 2 (verdict critic 25 sep): garda veche accepta orice piesa numita
## `muschiBuza*` FARA sa verifice fizic ca atinge ceva (`probe_manual.gd`
## inlocuit cu test pe raza). Rularea aratat 3 din 6 piese ale rundei 1
## PLUTIND cu adevarat (0, 1, 5 la 14-23 m peste teren, langa alt decor sau in
## gol) — cauza: bucla masura f in [0.280, 0.315] cu lateral pana la ~10.6 m,
## dar coliziunea REALA a buzei (`stirlingLedge_col`, verificat prin raycast
## in jos, "y peste drum > 5") exista DOAR pe f in [0.288, 0.306] si lateral
## in [6.3, 9.4] — un bloc mult mai ingust decat presupunerea initiala de
## 30-40 m. Bucla de mai jos e stransa pe fereastra reala, deci nu mai sare
## piese in gol (SKIP explicit ramane, dar nu mai declanseaza in interior).
##
## Al doilea defect (verdict runda 2): "stanca de langa cascada e complet
## goala de decor" pe FLANCURI — cele 6 piese vechi erau toate agatate de
## tavanul orizontal al buzei (privire de sus), nimic pe muchiile VERTICALE
## ale peretelui. Solutia de-atunci (`_wall_flank_moss`, azi INLOCUITA) a
## batut un raycast orizontal la inaltimi 1.5-16 m pe toata fata, cu bias
## spre piese MARI (moss_boulder_b/c la scara 1.1-1.8) la inaltime medie.
##
## RUNDA 3 (verdict critic 25 sep, al doilea): corectie in exces. Rezultatul
## rundei 2 citea ca "bulgari verzi lipiti pe fata peretelui, ca niste
## baloane" chiar langa/sub perdea — acopera exact zona care trebuie sa
## citeasca STANCA GOALA, intunecata, uda (fundatia 2 a reparat deja
## culoarea `wet_gneiss`). Nota coordonatorului: ținta e INTRE r1 si r2 — fata
## verticala a peretelui ramane goala, doar un TIV SUBTIRE, jos ca profil, pe
## MUCHIA DE SUS a surplombului (langa unde apa se desprinde) + pe marginile
## LATERALE (unde peretele intra/iese din cadru). `moss_boulder` la scara
## mare citeste "bila" oricat de sus il pui — pentru tiv se foloseste
## `fern_cluster`/`tussock_clump` (deja joase si late) si `moss_boulder`
## TURTIT pe Y (0.3-0.5 din scara orizontala), ca sa citeasca perna, nu bila.
## `_wall_flank_moss` (raycast orizontal pe toata inaltimea fetei) e sters:
## nu mai punem NIMIC intre h=2 si h=13 pe fata verticala interioara a
## peretelui — doar langa muchia de sus (h aproape de Overhang, ~13-16.5 m)
## si pe cele doua muchii laterale, jos ca profil (inaltime AABB <= ~1 m dupa
## turtire), ingropat/lipit strans de piatra ca sa nu iasa in relief.
func _moss_and_nook() -> void:
	var space_state := _track.get_world_3d().direct_space_state
	var n := _track.baked.size()
	# Fereastra REALA a tavanului buzei (masurata prin raycast in jos, "y
	# peste drum > 5m" = coliziunea Overhang, nu Wall/Shou/Terrain). Vezi
	# comentariul de mai sus.
	var f := 0.289
	var placed := 0
	while f <= 0.305:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		# Lateral STRANS pe fereastra masurata (6.3-9.4), nu half+EDGE_KEEP+jitter
		# (asta a scos piesele in gol runda trecuta).
		var lat: float = _wall_side * _rng.randf_range(6.4, 9.2)
		var q: Vector3 = p + s * lat
		var ray_from := Vector3(q.x, p.y + 28.0, q.z)
		var ray_to := Vector3(q.x, p.y + 5.0, q.z)
		var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			_skipped += 1
			f += 0.0025
			continue
		var y: float = (hit["position"] as Vector3).y - 0.05  # ingropata usor, sa nu pluteasca
		var mdl := "moss_boulder_a" if _rng.randf() < 0.6 else "moss_boulder_b"
		_raw(mdl, "muschiBuza", Vector3(q.x, y, q.z), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.7, 1.1), "none")
		placed += 1
		f += 0.0025
	print("; muschi pe buza (tavan): %d piese, %d sarite in fereastra" % [placed, _skipped])
	_wall_edge_fringe(space_state, n)


## TIV SUBTIRE pe muchia de sus a surplombului + pe marginile laterale —
## verdict critic runda 3 (INLOCUIESTE `_wall_flank_moss`, care punea
## moss_boulder mare (scara 1.1-1.8) pe toata fata verticala intre h=1.5 si
## h=16: citea "bulgari verzi lipiti ca niste baloane" exact unde peretele
## trebuie sa ramana stanca goala, intunecata, uda. Nota coordonatorului:
## ținta e INTRE r1 (stanca goala complet) si r2 (fata acoperita) — un tiv
## JOS CA PROFIL doar pe (a) muchia orizontala de sus, langa unde apa se
## desprinde, si (b) cele doua muchii verticale laterale, unde piatra
## intra/iese din cadru. NIMIC intre h=2 si h=11 pe fata interioara.
##
## Compozitie: fern_cluster/tussock_clump (deja joase si late) + moss_boulder
## TURTIT pe Y la 0.30-0.50 din scara orizontala (Basis neuniform: scala mare
## pe X/Z, mica pe Y) — turtit citeste "perna de muschi", nu "bila" (moss_boulder
## la scara uniforma citeste bila indiferent unde-l pui, per nota
## coordonatorului). Piese MICI (AABB inaltime dupa turtire <= ~1 m).
##
## Ancora ca la r2b: raza ORIZONTALA dinspre drum spre perete gaseste fata
## reala a `stirlingLedge_col`; piesa se lipeste de ea (+0.12 m pe normala).
func _wall_edge_fringe(space_state: PhysicsDirectSpaceState3D, n: int) -> void:
	var placed := 0
	# (a) TIV PE MUCHIA DE SUS: banda ingusta de inaltime, chiar sub Overhang
	# (buza e la +14..+21 local; fata verticala utila urca pana spre ~16.5 m
	# masurat r2b), acolo unde apa se desprinde — languros pe toata lungimea
	# peretelui expus (f 0.2865-0.3085, aceeasi fereastra masurata ca la r2).
	var f0_top := 0.2865
	var f1_top := 0.3085
	var count_top := 14
	for k in range(count_top):
		var f: float = lerpf(f0_top, f1_top, (float(k) + _rng.randf_range(0.15, 0.85)) / float(count_top))
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		var h: float = _rng.randf_range(12.5, 16.5)   # chiar sub muchia de sus
		var from := Vector3(p.x, p.y + h, p.z) + s * _wall_side * 2.5
		var to: Vector3 = from + s * _wall_side * 20.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		var hit := space_state.intersect_ray(query)
		if hit.is_empty() or str((hit.get("collider") as Node).name) != "stirlingLedge_col":
			_skipped += 1
			continue
		var hp: Vector3 = hit["position"]
		var normal: Vector3 = hit.get("normal", -s * _wall_side)
		var anchor: Vector3 = hp + normal * 0.12
		placed += _place_low_fringe(anchor, "muchieSus")
	# (b) TIV PE MUCHIILE LATERALE: aceleasi doua ferestre unde piatra
	# intra/iese din cadru, dar acum DOAR jos ca profil (piese turtite/joase),
	# pe toata inaltimea utila — nu mai e "camp de bolovani", e o dunga
	# subtire care urmareste muchia.
	var edges := [
		{"f0": 0.2865, "f1": 0.2905, "n": 6},   # muchia de intrare (dinspre chei)
		{"f0": 0.3035, "f1": 0.3085, "n": 6},   # muchia de iesire (spre Chasm)
	]
	for edge: Dictionary in edges:
		var f0: float = edge["f0"]
		var f1: float = edge["f1"]
		var cnt: int = edge["n"]
		for k in range(cnt):
			var f: float = lerpf(f0, f1, (float(k) + _rng.randf_range(0.1, 0.9)) / float(cnt))
			var i := int(f * float(n)) % n
			var p: Vector3 = _track.baked[i]
			var s: Vector3 = _track._side_at(i)
			var h: float = _rng.randf_range(1.0, 16.0)
			var from := Vector3(p.x, p.y + h, p.z) + s * _wall_side * 2.5
			var to: Vector3 = from + s * _wall_side * 20.0
			var query := PhysicsRayQueryParameters3D.create(from, to)
			var hit := space_state.intersect_ray(query)
			if hit.is_empty() or str((hit.get("collider") as Node).name) != "stirlingLedge_col":
				_skipped += 1
				continue
			var hp: Vector3 = hit["position"]
			var normal: Vector3 = hit.get("normal", -s * _wall_side)
			var anchor: Vector3 = hp + normal * 0.12
			placed += _place_low_fringe(anchor, "muchieLat")
	print("; tiv subtire (sus + laterale): %d piese" % placed)


## Aseaza O piesa joasa/lata la ancora data (deja pe fata reala a peretelui):
## fern_cluster, tussock_clump, sau moss_boulder TURTIT pe Y. Returneaza
## numarul de piese adaugate (1, uneori +1 daca se adauga o ferigă alaturata).
func _place_low_fringe(anchor: Vector3, prefix: String) -> int:
	var placed := 0
	var pick := _rng.randf()
	if pick < 0.45:
		_raw("fern_cluster", prefix, anchor, _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.8, 1.3), "none")
		placed += 1
	elif pick < 0.75:
		_raw("tussock_clump", prefix, anchor, _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.8, 1.2), "none")
		placed += 1
	else:
		var mdl := "moss_boulder_a" if _rng.randf() < 0.7 else "moss_boulder_b"
		var scl_h := _rng.randf_range(0.6, 1.0)   # orizontal (X/Z)
		var scl_y := scl_h * _rng.randf_range(0.30, 0.50)   # turtit: perna, nu bila
		_raw_nonuniform(mdl, prefix, anchor, _rng.randf_range(0.0, TAU),
			scl_h, scl_y, "none")
		placed += 1
	# ocazional o ferigă mica alaturi, sa rupa marginea dreapta a pernei
	if _rng.randf() < 0.35:
		var off := Vector3(_rng.randf_range(-0.4, 0.4), 0.0, _rng.randf_range(-0.4, 0.4))
		_raw("fern_cluster", prefix, anchor + off, _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.6, 0.9), "none")
		placed += 1
	return placed


## (2) BOLOVANI UZI LA BAZA PERETELUI — intre picioarele peretelui si drum,
## pe partea peretelui, sub linia de cadere a perdelei (bazinul alb, cod).
## Densitate crescatoare spre centrul perdelei (subiectul), rarita spre
## capete.
func _wet_boulders() -> void:
	var n := _track.baked.size()
	var f := F_IN
	var placed := 0
	while f <= F_OUT:
		var dist_to_center := absf(f - F_CENTER) / (F_OUT - F_IN) * 2.0
		var density := lerpf(0.85, 0.25, clampf(dist_to_center, 0.0, 1.0))
		if _rng.randf() < density:
			var i := int(f * float(n)) % n
			var p: Vector3 = _track.baked[i]
			var s: Vector3 = _track._side_at(i)
			var half: float = _track.width_at_index(i)
			# la baza peretelui, langa Shelf (pragul uscat, 3 m), dar dincolo
			# de EDGE_KEEP fata de muchia carosabilului.
			var lat: float = _wall_side * (half + EDGE_KEEP + _rng.randf_range(0.4, 2.0))
			var q: Vector3 = p + s * lat
			var y: float = _sampler.ground_y(q.x, q.z)
			var mdl_r := _rng.randf()
			var mdl := "moss_boulder_b"
			if mdl_r < 0.4:
				mdl = "moss_boulder_a"
			elif mdl_r > 0.75:
				mdl = "moss_boulder_c"
			_raw(mdl, "bolovanUd", Vector3(q.x, y, q.z), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.3), "hull")
			placed += 1
			# uneori un fern_cluster langa bolovan, umed la baza. Offset doar
			# spre AFARA drumului (nu spre ax): un offset negativ (spre ax)
			# putea trece sub half+EDGE_KEEP si iesea "IN DRUM" la probe_manual
			# (gasit la garda r3: fernUd la 8,0 m == prag exact, jitter -1,2
			# il impingea sub 8,4 m minim). Corect e sa nu ne apropiem
			# NICIODATA de asfalt fata de bolovanul-ancora, doar sa variem cat
			# de departe.
			if _rng.randf() < 0.5:
				var off := s * _wall_side * _rng.randf_range(0.0, 1.2)
				var q2: Vector3 = q + off
				var y2: float = _sampler.ground_y(q2.x, q2.z)
				_raw("fern_cluster", "fernUd", Vector3(q2.x, y2, q2.z),
					_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.2), "hull")
				placed += 1
		f += 0.004
	print("; bolovani uzi + ferigi baza: %d piese" % placed)


## (3) FAGI PE PLATOUL DE DEASUPRA PERETELUI — "fara copaci in GLB" (brief
## §1.1): coronamentul vazut deasupra peretelui in bara vine de aici, plantat
## pe teren la cota naturala (deasupra buzei, in spatele ei), NU pe
## Overhang (care e roca goala). Jitter, yaw variat, fara grila.
func _plateau_beeches() -> void:
	var n := _track.baked.size()
	var f := F_SURVEY_IN
	var placed := 0
	while f <= F_SURVEY_OUT:
		if _rng.randf() < 0.55:
			var i := int(f * float(n)) % n
			var p: Vector3 = _track.baked[i]
			var s: Vector3 = _track._side_at(i)
			var half: float = _track.width_at_index(i)
			# dincolo de perete (mult mai departe decat buza, pe platoul de
			# sus, unde solul revine la cota "normala" a versantului) —
			# folosesc >= 16 m ca sa fim clar dupa fata verticala a peretelui.
			var lat: float = _wall_side * _rng.randf_range(16.0, 26.0)
			var q: Vector3 = p + s * lat
			var y: float = _sampler.ground_y(q.x, q.z)
			var mdl_r := _rng.randf()
			var mdl := "beech_b"
			if mdl_r < 0.35:
				mdl = "beech_a"
			elif mdl_r > 0.75:
				mdl = "beech_c"
			var scl := _rng.randf_range(0.85, 1.2)
			_raw(mdl, "fagPlatou", Vector3(q.x, y, q.z), _rng.randf_range(0.0, TAU),
				scl, "trunk")
			placed += 1
			if _rng.randf() < 0.2:
				_raw("beech_dead", "fagUscat", Vector3(q.x + 3.0, y, q.z + 1.5),
					_rng.randf_range(0.0, TAU), 1.0, "trunk")
				placed += 1
		f += 0.005
	print("; fagi pe platou: %d piese" % placed)


## (4) UN RATA_TREE + GUARD_ROCK spre mare — un singur rata_tree in toata
## zona (brief: "3-4 pe TOT turul, nu pe metru"), langa nisa, unde accentul
## rosu-verde citeste. guard_rock pe marginea marii (side opus peretelui).
func _rata_and_guard() -> void:
	var n := _track.baked.size()
	var i := int(F_CENTER * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var s: Vector3 = _track._side_at(i)
	var half: float = _track.width_at_index(i)
	# rata_tree langa nisa, pe partea peretelui, putin inainte de perdea.
	var f_rata := F_CENTER - 0.012
	var i_r := int(f_rata * float(n)) % n
	var p_r: Vector3 = _track.baked[i_r]
	var s_r: Vector3 = _track._side_at(i_r)
	var half_r: float = _track.width_at_index(i_r)
	var lat_r: float = _wall_side * (half_r + EDGE_KEEP + 1.0)
	var q_r: Vector3 = p_r + s_r * lat_r
	var y_r: float = _sampler.ground_y(q_r.x, q_r.z)
	_raw("rata_tree", "rataStirling", Vector3(q_r.x, y_r, q_r.z),
		_rng.randf_range(0.0, TAU), 1.0, "hull")
	# guard_rock spre mare, pe marginea drumului opusa peretelui, la iesirea
	# din zona (spre 0.32, unde cornisa spre mare continua).
	var f_g := F_OUT - 0.005
	var i_g := int(f_g * float(n)) % n
	var p_g: Vector3 = _track.baked[i_g]
	var s_g: Vector3 = _track._side_at(i_g)
	var half_g: float = _track.width_at_index(i_g)
	var lat_g: float = -_wall_side * (half_g + EDGE_KEEP + 0.6)
	var q_g: Vector3 = p_g + s_g * lat_g
	var y_g: float = _sampler.ground_y(q_g.x, q_g.z)
	_raw("guard_rock", "guardMare", Vector3(q_g.x, y_g, q_g.z),
		_rng.randf_range(0.0, TAU), 1.0, "hull")
	# tussock pe umarul dinspre mare, cateva fire, langa guard_rock
	for k in range(3):
		var f_t := f_g + float(k - 1) * 0.006
		var i_t := int(f_t * float(n)) % n
		var p_t: Vector3 = _track.baked[i_t]
		var s_t: Vector3 = _track._side_at(i_t)
		var half_t: float = _track.width_at_index(i_t)
		var lat_t: float = -_wall_side * (half_t + EDGE_KEEP + _rng.randf_range(0.3, 1.2))
		var q_t: Vector3 = p_t + s_t * lat_t
		var y_t: float = _sampler.ground_y(q_t.x, q_t.z)
		_raw("tussock_clump", "tussockMare", Vector3(q_t.x, y_t, q_t.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.1), "hull")
	print("; rata_tree 1, guard_rock 1, tussock 3")


# ------------------------------------------------------------------ scriere

func _raw(model: String, prefix: String, pos: Vector3, yaw: float, scl: float,
		collision_override: String) -> void:
	_raw_nonuniform(model, prefix, pos, yaw, scl, scl, collision_override)


## Ca `_raw`, dar cu scara VERTICALA separata de cea orizontala — pentru
## piesele "turtite" (moss_boulder redus pe Y la tiv, runda 3): scl_h se
## aplica pe X/Z, scl_y doar pe Y, ca sa citeasca perna, nu bila.
func _raw_nonuniform(model: String, prefix: String, pos: Vector3, yaw: float,
		scl_h: float, scl_y: float, collision_override: String) -> void:
	var id: String = RES.get(model, "")
	if id == "":
		push_warning("model necunoscut in RES: " + model)
		return
	var name := "%s%d" % [prefix, _n]
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3(scl_h, scl_y, scl_h))
	var t := Transform3D(basis, pos)
	_out.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [
		name, ZONE, id])
	_out.append("transform = %s" % _tscn_transform(t))
	# BUG runda 2 (gasit la garda IN DRUM): parametrul `collision_override` era
	# primit dar NICIODATA scris in .tscn — orice piesa iesea pe implicitul
	# `hull` din PROP_COLLISION (world_prop.gd), inclusiv muschiul de pe buza,
	# suspendat la 20+ m peste sosea. Un hull acolo nu opreste masina (e prea
	# sus ca sa fie atins vreodata), dar `probe_manual` il vede ca IN DRUM
	# (distanta LATERALA, nu si verticala) — zgomot, nu defect real, insa
	# corect e sa transmitem ce am decis, nu sa lasam implicitul sa decida
	# pentru noi. Formatul e cel din `gen_decor_capp_a.gd`
	# (`metadata/coliziune`), citit de `world_prop._collision_mode`.
	if collision_override != "" and collision_override != "hull":
		_out.append('metadata/coliziune = "%s"' % collision_override)
	_out.append("")
	_n += 1
	_tri += int(TRI.get(model, 0))


func _tscn_transform(t: Transform3D) -> String:
	var b := t.basis
	var o := t.origin
	return "Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.4f, %.4f, %.4f)" % [
		b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, o.x, o.y, o.z]


func _write() -> void:
	print("; total %d piese, ~%d triunghiuri, %d sarite" % [_n, _tri, _skipped])
	if _out_path == "":
		print("; --out= lipseste, nu scriu fisier")
		return
	var f := FileAccess.open(_out_path, FileAccess.WRITE)
	if f == null:
		push_error("nu pot scrie " + _out_path)
		return
	for line in _out:
		f.store_line(line)
	f.close()
	print("; scris %s" % _out_path)
