extends Node
## Generator de decor MANUAL pentru POI D — ORASUL ALBASTRU, cu D′ (ulicioara
## si vaca) — Track17, Jodhpur, frac 0.267-0.474.
##
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track17.tscn sub
## `DecorManual/ZoneD_Oras` (tiparul gen_decor_jod_e.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorJodD.tscn -- \
##       --out=C:/cale/zoneD.part
##
## ------------------------------------------------------------------------
## CONTRACTUL (jodhpur_poi_gauntlet.md, D si D′)
##
## - Frontul de strada pe 0-40 m de drum, pe AMBELE parti: `OrasFill`
##   (MultiMesh, fara coliziune) umple deja interiorul buclei de la 40 m de
##   ORICE banda. Pozitiile lui se recalculeaza aici cu ACELASI generator
##   (`CityFill._generate`, determinist) si se ocolesc: nicio casa dublata.
## - Randuri paralele cu banda, NU grila: latimea fiecarei case, golul dintre
##   ele, retragerea si yaw-ul variaza; randurile interioare pot sta si
##   rotite cu 90°. Randul 1 are golurile sub latimea unei masini (<= 1,2 m),
##   deci e zid continuu.
## - Toate casele au coliziune (`hull`, implicitul kitului): randul 1 e
##   peretele strazii; randurile din spate nu pot fi atinse prin golurile
##   randului 1, dar pot fi atinse de o masina care a sarit peste el, deci nu
##   le facem fantome (memoria `coliziune-none-e-fantoma-nu-stearsa`).
## - Ulicioara: case-ziduri pe ambele parti, fata la >= 3,2 + 1,0 m de axa
##   benzii, doar DUPA gura reala (25,4 m); nimic pe cei 6,4 m ai benzii, nimic
##   langa stalpii `AlleyGate` si nimic pe pragul vacii (partea departe de
##   bucla). `CowGate`, `AlleyGate`, `TrackBranch` nu se ating.
## - ~40 % indigo (metadata `indigo`). Ocru: NU exista in kit (fara clasa,
##   fara tenta) — cerere de material, vezi raportul.
## - Rezervoare negre (`rooftop_tank`) pe acoperisurile plate ale caselor
##   fara rezervor propriu (b si c il au in mesh), rufe (`rooftop_clutter`)
##   pe unele.
## - Candele in SIRURI pe muchia parapetului (fata spre drum, pas regulat),
##   ca lampi `FortLamps` (acelasi material si acelasi halou ca E si H).
## - Pauni pe parapetele din primul rand (5-7 pe tur, `none`).

const TRACK := "res://scenes/tracks/Track17.tscn"
const ZONE := "DecorManual/ZoneD_Oras"

const F_IN := 0.274
const F_OUT := 0.466

## Pozitia pe traseu a vacii / portii (le citim din noduri, nu le recalculam).
const MOUTH_REAL_M := 25.4

## Modelele de case: jumatatile AABB (x, z), inaltimea, axa fetei (+Z sau +X)
## si ponderea. Masurate din GLB (tools: house_inspect, `jodhpur_masuratori.md`).
const HOUSES := {
	"blue_house_a": {"hx": 3.575, "hz": 3.31, "front": Vector2(1, 0), "w": 0.16},
	"blue_house_b": {"hx": 3.41, "hz": 3.775, "front": Vector2(1, 0), "w": 0.22},
	"blue_house_c": {"hx": 3.75, "hz": 3.835, "front": Vector2(0, -1), "w": 0.2},
	"blue_house_d": {"hx": 3.75, "hz": 4.005, "front": Vector2(1, 0), "w": 0.18},
	"blue_house_e": {"hx": 3.7, "hz": 3.13, "front": Vector2(0, -1), "w": 0.18},
	"haveli_facade": {"hx": 5.46, "hz": 3.7125, "front": Vector2(0, -1), "w": 0.06},
}
## Casele care au deja rezervorul in mesh (nu primesc altul).
const HAS_TANK := ["blue_house_b", "blue_house_c"]

const RES := {
	"blue_house_a": "s_blue_house_a",
	"blue_house_b": "s_blue_house_b",
	"blue_house_c": "s_blue_house_c",
	"blue_house_d": "s_blue_house_d",
	"blue_house_e": "s_blue_house_e",
	"haveli_facade": "s_haveli_facade",
	"peacock_fanned": "s_peacock_fanned",
	"peacock_closed": "s_peacock_closed",
	"neem_tree": "s_neem_tree",
	"market_gate": "s_market_gate",
	"textile_strip": "s_textile_strip",
	"laundry_line": "s_laundry_line",
	"street_shrine": "s_street_shrine",
}

## D′ — piesele ulicioarei (runda 2), pe distanta de la capul benzii (m).
## Arcada de gresie peste poarta de 4 m (bara D2: „arcada de gresie in zid
## albastru"): `market_gate` la scara ARCH_SCALE — golul 18,39 -> 5,5 m (mai
## lat decat golul portii, deci nu-l ingusteaza), cheia 11,34 -> 3,4 m,
## semi-latimea 20,2 -> 6,05 m (sub asfaltul buclei, care e la ~6,1 m de axa
## ulicioarei acolo). Fara coliziune: stalpii invizibili ai `AlleyGate` si
## palnia fac treaba fizica; arcada doar ii arata.
const ARCH_SCALE := 0.3
## Fasii textile si rufe PESTE banda (sub camera: varful la ~5 m).
const TEXTILE_AT := [40.0, 60.0]
const LAUNDRY_AT := [50.0, 70.0]
const TEXTILE_SCALE := Vector3(0.9, 1.9, 1.0)
const LAUNDRY_SCALE := Vector3(1.85, 1.7, 1.0)
## Altarul alb, langa pila de nord a arcadei (partea departe de bucla).
const SHRINE_AT := 35.0
const SHRINE_LAT := -6.6

## Trotuarul pavat de pe D (`shoulder_width_zones`): 3,2 m. Fata randului 1
## sta dupa el, cu o abatere mica.
const SIDEWALK := 3.2
## Randurile pe bucla: retragerea FETEI fata de marginea TROTUARULUI pavat
## (`Track._shoulder_width`, 3,2-4 m dupa asfalt). Runda 2 (criticul orb:
## „benzi largi de nisip intre bordura si case, zid continuu de cuburi in
## bara"): randul 1 lipit de trotuar, goluri <= 0,3 m, cate un neem mic la
## 3-4 case; randurile 2-4 in trepte, fiecare imediat in spatele celui din
## fata (adancimea caselor e 6,3-8 m), pana la umplutura OrasFill.
const MAIN_ROWS := [
	{"front": 0.1, "jit": 0.1, "gap": Vector2(0.0, 0.3), "turn_p": 0.0, "yaw_deg": 1.5},
	{"front": 8.4, "jit": 0.4, "gap": Vector2(0.0, 0.6), "turn_p": 0.15, "yaw_deg": 4.0},
	{"front": 16.8, "jit": 0.6, "gap": Vector2(0.0, 0.9), "turn_p": 0.2, "yaw_deg": 6.0},
	{"front": 25.2, "jit": 0.8, "gap": Vector2(0.2, 1.2), "turn_p": 0.25, "yaw_deg": 8.0},
]
## Neem mic intre casele randului 1, la fiecare 3-4 case (bara: verdeata
## printre cuburi). Scara si amprenta (fanta) pe drum.
const NEEM_ROW1_EVERY := Vector2i(3, 4)
const NEEM_SMALL_SCALE := 0.55
const NEEM_SLOT_HALF := 1.6
## Ulicioara: fata la >= 1,0 m de marginea benzii (3,2), randul 2 in spate.
const ALLEY_ROWS := [
	{"front": 1.0, "jit": 0.3, "gap": Vector2(0.0, 0.4), "turn_p": 0.0, "yaw_deg": 2.0},
	{"front": 9.8, "jit": 1.0, "gap": Vector2(0.4, 2.4), "turn_p": 0.3, "yaw_deg": 10.0},
]
## Marja fata de marginea ORICAREI benzi pentru amprenta intreaga (orice punct
## al dreptunghiului): pe bucla, trotuarul; pe ulicioara, 1 m.
const KEEP_MAIN := 3.2
const KEEP_ALLEY := 0.9
## Casele-ziduri ale ulicioarei din buzunarul dintre ea si bucla: fata dinspre
## bucla are voie pana la 2 m de asfaltul ei (pe trotuar; LaneClear cere
## banda + 0,5). Runda 1 a dat [blocaj] aici, dar cauza era momeala AI-ului
## dupa furca (`TrackBranch.lure_before_entry_only`, runda 2), nu casele.
const KEEP_MAIN_FROM_ALLEY := 2.0
## Amprenta unei case din OrasFill, ca cerc (casele ei au 6,3-7,7 m latura si
## yaw pe multipli de 90° ± 6°; haveli 10,9 m, rar): raza cercului cuprinzator.
const FILL_R := 5.4
## Treapta maxima de teren sub amprenta (ca CityFill) si ingroparea bazei.
const MAX_STEP := 2.5
## Retragerea maxima (si pasul) cand amprenta atinge o banda sau o casa.
const PUSH_MAX := 3.0
const PUSH_STEP := 0.5
## Randul 1 se retrage putin si fin: altfel reapare fasia de nisip.
const PUSH_MAX_ROW1 := 1.5
const PUSH_STEP_ROW1 := 0.25
const SINK := 0.3
## Zone rezervate (x, z, raza): se completeaza la rulare cu pragul vacii si
## stalpii portii. Plus graniste cu alte POI-uri.
const Z_MAX_C := 22.0 # la sud de asta e fantana (C)
const X_MAX_E := 36.0 # la est de asta sunt portile (E)

const INDIGO_P := 0.4
const TANK_P := 0.7
const CLUTTER_P := 0.25
const NEEM_P := 0.06
## Candele: pas pe muchia fetei, raza lampii.
const DIYA_STEP := 0.7
const DIYA_R := 0.12
const PEACOCKS := 7

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid: RID = RID()
var _sus_y := 200.0
var _rng := RandomNumberGenerator.new()
var _out: Array[String] = []
var _out_path := ""
var _n := 0
## Dreptunghiurile ocupate: {c: Vector2, ax: Vector2 (unitar, semi-axa a), ha, hb}
var _rects: Array = []
## Cercurile ocupate (OrasFill, zone rezervate): Vector3(x, z, r)
var _circles: Array[Vector3] = []
## Casele puse (pentru acoperisuri): {model, xf, row, road_dir}
var _houses: Array = []
var _lamps := PackedVector3Array()
var _tanks := PackedVector3Array()
var _tank_yaws := PackedFloat32Array()
var _clutter := PackedVector3Array()
var _clutter_yaws := PackedFloat32Array()
## Harta de inaltimi a fiecarui model (celula 0,25 m): {model: {"o": Vector2, "n": Vector2i, "h": PackedFloat32Array}}
var _hmaps := {}
var _stats := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for k in 4:
		await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 300926
	for m in HOUSES:
		_hmaps[m] = _heightmap(m)
	_reserve()
	_alley_pieces()
	# Ulicioara intai (zidurile ei sunt contract), apoi bucla, rand cu rand.
	var alley := _track.route_at(1)
	var main := _track.route_at(0)
	for r in ALLEY_ROWS.size():
		for sgn: float in [1.0, -1.0]:
			_row(alley, 1, r, ALLEY_ROWS[r], sgn, MOUTH_REAL_M + 1.0,
				alley.length() - 6.0)
	var s_in := _dist_at(main, F_IN)
	var s_out := _dist_at(main, F_OUT)
	for r in MAIN_ROWS.size():
		for sgn: float in [1.0, -1.0]:
			_row(main, 0, r, MAIN_ROWS[r], sgn, s_in, s_out)
	_roofs()
	_peacocks()
	_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ rezervari

## Punctul, directia si dreapta benzii 1 la distanta d (m) de la capul ei.
func _alley_frame(d: float) -> Array:
	var r := _track.route_at(1)
	var i := _index_at_dist(r, d)
	var j := mini(i + 1, r.baked.size() - 1)
	if j == i:
		i = maxi(i - 1, 0)
	var dir := r.baked[j] - r.baked[i]
	dir.y = 0.0
	dir = dir.normalized()
	return [r.baked[i], dir, dir.cross(Vector3.UP).normalized()]


func _alley_pieces() -> void:
	var gate := _track.get_node_or_null("AlleyGate")
	var gd := 30.0 if gate == null else float(gate.gate_dist_m)
	# Arcada: trecerea pe Z-ul modelului = directia benzii.
	var f := _alley_frame(gd)
	var pos: Vector3 = f[0]
	var dir: Vector3 = f[1]
	var side: Vector3 = f[2]
	var b := Basis(-side, Vector3.UP, dir).scaled(Vector3.ONE * ARCH_SCALE)
	_node("market_gate", "arcadaUlicioara", Vector3(pos.x, _sol_real(pos.x, pos.z) - 0.1, pos.z), b,
		['metadata/coliziune = "none"'])
	# Casele nu intra in pilele arcadei.
	for sg: float in [1.0, -1.0]:
		var q := pos + side * sg * 4.6
		_circles.append(Vector3(q.x, q.z, 1.9))
	for d: float in TEXTILE_AT:
		var ff := _alley_frame(d)
		var p: Vector3 = ff[0]
		var bb := Basis(-(ff[2] as Vector3), Vector3.UP, ff[1]).scaled(TEXTILE_SCALE)
		_node("textile_strip", "textileUlicioara", Vector3(p.x, _sol_real(p.x, p.z) - 0.05, p.z), bb, [])
	for d: float in LAUNDRY_AT:
		var ff := _alley_frame(d)
		var p: Vector3 = ff[0]
		var bb := Basis(-(ff[2] as Vector3), Vector3.UP, ff[1]).scaled(LAUNDRY_SCALE)
		_node("laundry_line", "rufeUlicioara", Vector3(p.x, _sol_real(p.x, p.z) - 0.05, p.z), bb,
			['metadata/coliziune = "none"'])
	var fs := _alley_frame(SHRINE_AT)
	var ps: Vector3 = fs[0] + (fs[2] as Vector3) * SHRINE_LAT
	# Fata altarului (+Z-ul modelului) spre banda.
	var to_lane := -(fs[2] as Vector3) * signf(SHRINE_LAT)
	var bs := Basis.looking_at(-to_lane, Vector3.UP)
	_node("street_shrine", "altar", Vector3(ps.x, _sol_real(ps.x, ps.z), ps.z), bs, [])
	_circles.append(Vector3(ps.x, ps.z, 1.4))
	print("; ulicioara: arcada la %.0f m, %d textile, %d rufe, altar la %.0f m"
		% [gd, TEXTILE_AT.size(), LAUNDRY_AT.size(), SHRINE_AT])


func _reserve() -> void:
	# OrasFill: aceleasi pozitii pe care le va pune la rulare.
	var fill := _track.get_node_or_null("OrasFill")
	if fill != null and fill.has_method("_generate"):
		var places: Array = fill.call("_generate", _track, _space)
		for p: Dictionary in places:
			var o := (p["xf"] as Transform3D).origin
			_circles.append(Vector3(o.x, o.z, FILL_R))
		print("; OrasFill: %d case ocolite" % places.size())
	# Vaca: pragul (in picioare, lateral) si gura; stalpii portii.
	for g in get_tree().get_nodes_in_group(Track.BRANCH_GATE_GROUP):
		if g is CowGate:
			var thr: Vector3 = (g.get("_threshold_xf") as Transform3D).origin
			_circles.append(Vector3(thr.x, thr.z, 3.6))
			var mouth: Vector3 = (g as CowGate).mouth_position()
			_circles.append(Vector3(mouth.x, mouth.z, 3.0))
			print("; vaca: prag (%.1f, %.1f), gura (%.1f, %.1f)" % [thr.x, thr.z, mouth.x, mouth.z])
	var gate := _track.get_node_or_null("AlleyGate")
	if gate != null:
		for c in gate.get_children():
			if c is Node3D:
				var p := (c as Node3D).global_position
				_circles.append(Vector3(p.x, p.z, 3.2))
				print("; stalp %s (%.1f, %.1f)" % [c.name, p.x, p.z])


# ------------------------------------------------------------------ randuri

func _dist_at(route: TrackRoute, frac: float) -> float:
	var n := route.baked.size()
	var i := clampi(int(round(frac * float(n))), 0, n - 1)
	return route.dists[i]


func _index_at_dist(route: TrackRoute, s: float) -> int:
	var lo := 0
	var hi := route.baked.size() - 1
	while lo < hi:
		var mid := (lo + hi) / 2
		if route.dists[mid] < s:
			lo = mid + 1
		else:
			hi = mid
	return lo


func _tangent(route: TrackRoute, i: int) -> Vector3:
	var n := route.baked.size()
	var a := route.wrap_index(i - 2)
	var b := route.wrap_index(i + 2)
	var d := route.baked[b] - route.baked[a]
	d.y = 0.0
	return d.normalized()


## Un rand de case pe o parte a unei benzi, intre distantele s0..s1.
func _row(route: TrackRoute, ri: int, r: int, cfg: Dictionary, sgn: float,
		s0: float, s1: float) -> void:
	var s := s0 + _rng.randf_range(0.0, 3.0)
	var since_neem := 0
	var next_neem := _rng.randi_range(NEEM_ROW1_EVERY.x, NEEM_ROW1_EVERY.y) + 1
	var placed := 0
	var tried := 0
	while s < s1:
		tried += 1
		var model := _pick_model(r)
		var neem := r > 0 and _rng.randf() < NEEM_P
		var small_neem := false
		if ri == 0 and r == 0:
			since_neem += 1
			if since_neem >= next_neem:
				small_neem = true
				since_neem = 0
				next_neem = _rng.randi_range(NEEM_ROW1_EVERY.x, NEEM_ROW1_EVERY.y) + 1
		var h: Dictionary = HOUSES[model]
		var turned := _rng.randf() < float(cfg["turn_p"])
		# Latimea pe drum (W) si adancimea (D) in functie de axa fetei.
		var fx := absf((h["front"] as Vector2).x) > 0.5
		var w_half: float = h["hz"] if fx else h["hx"]
		var d_half: float = h["hx"] if fx else h["hz"]
		if turned:
			var tmp := w_half
			w_half = d_half
			d_half = tmp
		if neem:
			w_half = 3.0
			d_half = 3.0
		if small_neem:
			w_half = NEEM_SLOT_HALF
			d_half = NEEM_SLOT_HALF
		var sc := s + w_half
		var i := _index_at_dist(route, sc)
		var p := route.baked[i]
		var t := _tangent(route, i)
		var right := t.cross(Vector3.UP).normalized()
		var hw := route.half_width if ri == 1 else _track.width_at_index(i)
		var pave := 0.0
		if ri == 0:
			pave = maxf(_track._shoulder_width(i, sgn), SIDEWALK)
		var front := hw + pave + float(cfg["front"]) + _rng.randf_range(-float(cfg["jit"]), float(cfg["jit"]))
		if ri == 0 and r == 0:
			front = maxf(front, hw + KEEP_MAIN + 0.05)
		if ri == 1 and r == 0:
			front = maxf(front, hw + KEEP_ALLEY + 0.1)
		var to_road := -right * sgn
		var yaw_j := deg_to_rad(_rng.randf_range(-float(cfg["yaw_deg"]), float(cfg["yaw_deg"])))
		var gap := _rng.randf_range(float(cfg["gap"].x), float(cfg["gap"].y))
		s = sc + w_half + gap
		# Axa "a" = de-a lungul drumului (W), "b" = spre drum (D), rotite cu yaw_j.
		var ax := Vector2(t.x, t.z).rotated(-yaw_j)
		# Daca amprenta atinge o banda sau o casa deja pusa, casa se RETRAGE
		# (pana la PUSH_MAX, in pasi de PUSH_STEP), nu se arunca: pe interiorul
		# virajelor si in spatele randului din fata, golul real e mai mare
		# decat retragerea nominala. Zonele rezervate si OrasFill nu se ocolesc
		# prin retragere (acolo casa se sare).
		var c := Vector2.ZERO
		var c3 := Vector3.ZERO
		var why := "?"
		var pushed := 0.0
		var push_max := PUSH_MAX_ROW1 if (ri == 0 and r == 0) else PUSH_MAX
		var push_step := PUSH_STEP_ROW1 if (ri == 0 and r == 0) else PUSH_STEP
		while pushed <= push_max + 0.001:
			c3 = p + right * sgn * (front + pushed + d_half)
			c = Vector2(c3.x, c3.z)
			why = _free_why(c, ax, w_half, d_half)
			if why == "" and not _clear_of_roads(c, ax, w_half, d_half,
					KEEP_MAIN_FROM_ALLEY if ri == 1 else KEEP_MAIN):
				why = "drum"
			if why == "" or why == "fill" or why == "rezervat":
				break
			pushed += push_step
		if c3.z > Z_MAX_C or c3.x > X_MAX_E:
			continue
		if why != "":
			var key := "%d.%d.%+.0f %s" % [ri, r + 1, sgn, why]
			_stats[key] = int(_stats.get(key, 0)) + 1
			continue
		var g := _ground_under(c, ax, w_half, d_half)
		if g.y - g.x > MAX_STEP or is_nan(g.x):
			_stats["treapta"] = int(_stats.get("treapta", 0)) + 1
			continue
		var base_y := g.x - SINK
		# Directia fetei (spre drum), rotita cu yaw_j.
		var face := Vector2(to_road.x, to_road.z).rotated(-yaw_j)
		if turned:
			face = face.rotated(PI * 0.5 * (1.0 if _rng.randf() < 0.5 else -1.0))
		var face3 := Vector3(face.x, 0.0, face.y)
		_rects.append({"c": c, "ax": ax, "ha": w_half, "hb": d_half})
		if small_neem:
			var yawn := _rng.randf_range(0.0, TAU)
			var bn := Basis(Vector3.UP, yawn).scaled(Vector3.ONE * NEEM_SMALL_SCALE)
			_node("neem_tree", "neemMic", Vector3(c.x, g.x - 0.05, c.y), bn, [])
			placed += 1
			continue
		if neem:
			var yaw := _rng.randf_range(0.0, TAU)
			_node("neem_tree", "neem", Vector3(c.x, g.x - 0.05, c.y), Basis(Vector3.UP, yaw), [])
			placed += 1
			continue
		# Fata cu usi/ferestre a modelului (masurata pe golurile *_Glow si
		# ramele *_Trim, constructorul A) intoarsa spre drum: rotatia in jurul
		# Y duce directia de unghi atan2(x, z) in unghi + yaw.
		var fl: Vector2 = h["front"]
		var yaw := atan2(face3.x, face3.z) - atan2(fl.x, fl.y)
		var b := Basis(Vector3.UP, yaw)
		var metas: Array[String] = []
		if _rng.randf() < INDIGO_P:
			metas.append("metadata/indigo = true")
		var tag := "al" if ri == 1 else ("dr" if sgn > 0.0 else "st")
		_node(model, "d%s%d_" % [tag, r + 1], Vector3(c.x, base_y, c.y), b, metas)
		_houses.append({"model": model, "xf": Transform3D(b, Vector3(c.x, base_y, c.y)),
			"row": r, "route": ri, "to_road": face3})
		placed += 1
	print("; banda %d rand %d parte %+.0f: %d puse din %d" % [ri, r + 1, sgn, placed, tried])


## Randurile din spate trag mai des casele inalte (b 10,4 m, haveli 11,1,
## d/e 8,8), ca orasul sa urce in trepte spre spate.
const TALL := ["blue_house_b", "haveli_facade", "blue_house_d", "blue_house_e"]

func _w(m: String, r: int) -> float:
	var w := float(HOUSES[m]["w"])
	if r > 0 and TALL.has(m):
		w *= 1.8
	return w


func _pick_model(r: int = 0) -> String:
	var total := 0.0
	for m in HOUSES:
		total += _w(m, r)
	var x := _rng.randf() * total
	for m in HOUSES:
		x -= _w(m, r)
		if x <= 0.0:
			return m
	return "blue_house_b"


## Puncte pe dreptunghi (centru c, semi-axa a de-a lungul `ax`, semi-axa b).
func _samples(c: Vector2, ax: Vector2, ha: float, hb: float) -> Array[Vector2]:
	var bx := Vector2(-ax.y, ax.x)
	var out: Array[Vector2] = []
	for u: float in [-1.0, -0.66, -0.33, 0.0, 0.33, 0.66, 1.0]:
		for v: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			out.append(c + ax * (u * ha) + bx * (v * hb))
	return out


func _free_why(c: Vector2, ax: Vector2, ha: float, hb: float) -> String:
	for ci in _circles.size():
		var cir: Vector3 = _circles[ci]
		var d := c.distance_to(Vector2(cir.x, cir.y))
		if d > cir.z + ha + hb:
			continue
		for q in _samples(c, ax, ha, hb):
			if q.distance_to(Vector2(cir.x, cir.y)) < cir.z:
				return "fill" if cir.z == FILL_R else "rezervat"
	for rc: Dictionary in _rects:
		if _obb_overlap(c, ax, ha - 0.1, hb - 0.1, rc["c"], rc["ax"], float(rc["ha"]) - 0.1,
				float(rc["hb"]) - 0.1):
			return "casa"
	return ""


## SAT pe doua dreptunghiuri orientate.
func _obb_overlap(c1: Vector2, a1: Vector2, h1a: float, h1b: float,
		c2: Vector2, a2: Vector2, h2a: float, h2b: float) -> bool:
	var b1 := Vector2(-a1.y, a1.x)
	var b2 := Vector2(-a2.y, a2.x)
	var d := c2 - c1
	for axis: Vector2 in [a1, b1, a2, b2]:
		var r1 := absf(a1.dot(axis)) * h1a + absf(b1.dot(axis)) * h1b
		var r2 := absf(a2.dot(axis)) * h2a + absf(b2.dot(axis)) * h2b
		if absf(d.dot(axis)) > r1 + r2:
			return false
	return true


## Fiecare punct al amprentei la >= KEEP de marginea fiecarei benzi (bucla:
## KEEP_MAIN; ulicioara: KEEP_ALLEY), pe toata pista (orice cota apropiata).
func _clear_of_roads(c: Vector2, ax: Vector2, ha: float, hb: float,
		keep_main: float = KEEP_MAIN) -> bool:
	var pts := _samples(c, ax, ha, hb)
	var reach := ha + hb + 20.0
	for ri in _track.routes.size():
		var route := _track.route_at(ri)
		var keep := keep_main if ri == 0 else KEEP_ALLEY
		for j in route.baked.size():
			var bp := route.baked[j]
			var bp2 := Vector2(bp.x, bp.z)
			if bp2.distance_to(c) > reach:
				continue
			var hw := _track.width_at_index(j) if ri == 0 else route.half_width
			for q in pts:
				if q.distance_to(bp2) < hw + keep:
					return false
	return true


## (min, max) al terenului REAL sub amprenta.
func _ground_under(c: Vector2, ax: Vector2, ha: float, hb: float) -> Vector2:
	var lo := INF
	var hi := -INF
	var bx := Vector2(-ax.y, ax.x)
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var q := c + ax * (u * ha * 0.95) + bx * (v * hb * 0.95)
			var y := _sol_real(q.x, q.y)
			if is_nan(y):
				return Vector2(NAN, NAN)
			lo = minf(lo, y)
			hi = maxf(hi, y)
	return Vector2(lo, hi)


# ------------------------------------------------------------------ acoperisuri

## Harta de inaltimi a unui model (celula 0,25 m, max y pe celula), din
## triunghiurile mesh-ului. Pentru rezervoare (acoperis plat) si candele
## (muchia parapetului de pe fata).
func _heightmap(model: String) -> Dictionary:
	var path := "res://assets/models/jodhpur/buildings/%s.glb" % model
	var inst := (load(path) as PackedScene).instantiate() as Node3D
	add_child(inst)
	var h: Dictionary = HOUSES[model]
	var cell := 0.25
	var o := Vector2(-float(h["hx"]) - 0.25, -float(h["hz"]) - 0.25)
	var n := Vector2i(int(ceil((float(h["hx"]) * 2.0 + 0.5) / cell)) + 1,
		int(ceil((float(h["hz"]) * 2.0 + 0.5) / cell)) + 1)
	var hm := PackedFloat32Array()
	hm.resize(n.x * n.y)
	hm.fill(0.0)
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var xf := inst.global_transform.affine_inverse() * mi.global_transform
		for sidx in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(sidx)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			if idx == null or (idx as PackedInt32Array).size() == 0:
				continue
			var ia := idx as PackedInt32Array
			for t in range(0, ia.size(), 3):
				var a := xf * v[ia[t]]
				var b := xf * v[ia[t + 1]]
				var c := xf * v[ia[t + 2]]
				var ext := maxf(maxf(a.distance_to(b), b.distance_to(c)), c.distance_to(a))
				var steps := clampi(int(ceil(ext / (cell * 0.5))), 1, 80)
				for ui in steps + 1:
					for vi in steps + 1 - ui:
						var uu := float(ui) / float(steps)
						var vv := float(vi) / float(steps)
						var q := a + (b - a) * uu + (c - a) * vv
						var cx := int((q.x - o.x) / cell)
						var cz := int((q.z - o.y) / cell)
						if cx < 0 or cz < 0 or cx >= n.x or cz >= n.y:
							continue
						var k := cz * n.x + cx
						if q.y > hm[k]:
							hm[k] = q.y
	inst.queue_free()
	return {"o": o, "n": n, "h": hm, "cell": cell}


func _hm_at(model: String, lx: float, lz: float) -> float:
	var d: Dictionary = _hmaps[model]
	var o: Vector2 = d["o"]
	var n: Vector2i = d["n"]
	var cell: float = d["cell"]
	var cx := int((lx - o.x) / cell)
	var cz := int((lz - o.y) / cell)
	if cx < 0 or cz < 0 or cx >= n.x or cz >= n.y:
		return 0.0
	return (d["h"] as PackedFloat32Array)[cz * n.x + cx]


## Max pe un disc de raza r (local), si min — ca sa stim daca e plat.
func _hm_disc(model: String, lx: float, lz: float, r: float) -> Vector2:
	var lo := INF
	var hi := -INF
	var k := -r
	while k <= r + 0.001:
		var j := -r
		while j <= r + 0.001:
			if k * k + j * j <= r * r + 0.001:
				var y := _hm_at(model, lx + k, lz + j)
				lo = minf(lo, y)
				hi = maxf(hi, y)
			j += 0.25
		k += 0.25
	return Vector2(lo, hi)


## Muchia de pe latura `dir` (unitar pe o axa, local x,z): capete + spre interior.
func _edge(dir: Vector2, hx: float, hz: float) -> Array:
	var c := Vector2(dir.x * hx, dir.y * hz)
	var t := Vector2(absf(dir.y) * hx, absf(dir.x) * hz)
	return [c - t, c + t, -dir]


func _roofs() -> void:
	for hs: Dictionary in _houses:
		var model: String = hs["model"]
		var xf: Transform3D = hs["xf"]
		var h: Dictionary = HOUSES[model]
		var hx: float = h["hx"]
		var hz: float = h["hz"]
		# Fata spre drum in coordonate LOCALE ale modelului.
		var fl: Vector2 = h["front"]
		# --- candelele pe muchia fetei (si pe laturi, la randul 1) ---
		var edges: Array = [_edge(fl, hx, hz)]
		if int(hs["row"]) == 0:
			var perp := Vector2(-fl.y, fl.x)
			edges.append(_edge(perp, hx, hz))
			edges.append(_edge(-perp, hx, hz))
		for e: Array in edges:
			var a: Vector2 = e[0]
			var b: Vector2 = e[1]
			var inward: Vector2 = e[2]
			var len := a.distance_to(b)
			var cnt := int(floor((len - 0.4) / DIYA_STEP))
			if cnt < 1:
				continue
			var off := (len - float(cnt - 1) * DIYA_STEP) * 0.5
			for k in cnt:
				var q := a + (b - a).normalized() * (off + float(k) * DIYA_STEP)
				# Varful muchiei: maxul intr-o fasie de 0,5 m spre interior.
				var top := 0.0
				var hit_at := q
				for step in 3:
					var qq := q + inward * (0.08 + 0.18 * float(step))
					var y := _hm_at(model, qq.x, qq.y)
					if y > top:
						top = y
						hit_at = qq
				if top < 2.5:
					continue
				var lp := Vector3(hit_at.x, top + DIYA_R * 0.9, hit_at.y)
				_lamps.append(xf * lp)
		# --- rezervorul pe acoperisul plat ---
		if not HAS_TANK.has(model) and _rng.randf() < TANK_P:
			var spots := [Vector2(hx - 1.3, -hz + 1.3), Vector2(-hx + 1.3, -hz + 1.3),
				Vector2(hx - 1.3, hz - 1.6), Vector2(-hx + 1.3, hz - 1.6), Vector2(0, -hz + 1.3)]
			spots.shuffle()
			for sp: Vector2 in spots:
				var dd := _hm_disc(model, sp.x, sp.y, 0.75)
				if dd.x > 4.0 and dd.y - dd.x < 0.12:
					_tanks.append(xf * Vector3(sp.x, dd.y, sp.y))
					_tank_yaws.append(_rng.randf_range(0.0, TAU))
					break
		if _rng.randf() < CLUTTER_P:
			var spots2 := [Vector2(0, 0), Vector2(hx - 1.8, 0), Vector2(-hx + 1.8, 0)]
			spots2.shuffle()
			for sp: Vector2 in spots2:
				var dd := _hm_disc(model, sp.x, sp.y, 1.6)
				if dd.x > 4.0 and dd.y - dd.x < 0.12:
					var basis_yaw := xf.basis.get_euler().y
					_clutter.append(xf * Vector3(sp.x, dd.y, sp.y))
					_clutter_yaws.append(basis_yaw + _rng.randf_range(-0.3, 0.3))
					break
	print("; candele %d, rezervoare %d, rufe %d" % [_lamps.size(), _tanks.size(), _clutter.size()])


## Pauni pe parapetul fetei, la case din primul rand de pe bucla, raspanditi.
func _peacocks() -> void:
	var cands: Array = []
	for hs: Dictionary in _houses:
		if int(hs["row"]) == 0 and int(hs["route"]) == 0:
			cands.append(hs)
	if cands.is_empty():
		return
	var step := maxi(cands.size() / PEACOCKS, 1)
	var k := step / 2
	var put := 0
	while k < cands.size() and put < PEACOCKS:
		var hs: Dictionary = cands[k]
		k += step
		var model: String = hs["model"]
		var xf: Transform3D = hs["xf"]
		var h: Dictionary = HOUSES[model]
		var hx: float = h["hx"]
		var hz: float = h["hz"]
		# Pe muchia fetei, spre un capat (nu in mijloc, unde sta candela).
		var fl: Vector2 = h["front"]
		var perp := Vector2(-fl.y, fl.x)
		var ext := Vector2(hx, hz)
		var lx := fl.x * (ext.x - 0.3) + perp.x * ext.x * 0.45
		var lz := fl.y * (ext.y - 0.3) + perp.y * ext.y * 0.45
		var top := _hm_disc(model, lx, lz, 0.25).y
		if top < 2.5:
			continue
		var fanned := put % 3 == 1
		var stem := "peacock_fanned" if fanned else "peacock_closed"
		# Pe parapet: paunul inchis are corpul pe Z (lung 2,1 m) — il asezam
		# de-a lungul muchiei; evantaiul (1,6 pe X) cu fata spre drum.
		var to_road: Vector3 = hs["to_road"]
		var along := to_road.cross(Vector3.UP)
		var b := Basis.looking_at(along if not fanned else -to_road, Vector3.UP)
		if fanned:
			b = Basis.looking_at(-to_road, Vector3.UP)
		_node(stem, "paun", xf * Vector3(lx, top, lz), b, [])
		put += 1
	print("; pauni %d" % put)


# ------------------------------------------------------------------ iesire

func _node(model: String, base: String, pos: Vector3, b: Basis, metas: Array) -> void:
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	for m: String in metas:
		_out.append(m)
	_out.append("")


func _flock(name_: String, res: String, pts: PackedVector3Array,
		yaws: PackedFloat32Array) -> void:
	if pts.is_empty():
		return
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [name_, ZONE])
	_out.append('script = ExtResource("flock")')
	_out.append('model = ExtResource("%s")' % res)
	var ps: Array[String] = []
	for v in pts:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
	var ys: Array[String] = []
	for y in yaws:
		ys.append("%.3f" % y)
	_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
	_out.append("scale_min = 0.95")
	_out.append("scale_max = 1.05")
	_out.append("")


func _write() -> void:
	_flock("Rezervoare", "s_rooftop_tank", _tanks, _tank_yaws)
	_flock("Rufe", "s_rooftop_clutter", _clutter, _clutter_yaws)
	_out.append('[node name="CandeleOras" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("e_fort_lamps")')
	var ps: Array[String] = []
	var rs: Array[String] = []
	var ss: Array[String] = []
	for v in _lamps:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
		rs.append("%.2f" % DIYA_R)
		ss.append("1.00")
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
	_out.append("radii = PackedFloat32Array(%s)" % ", ".join(rs))
	_out.append("stretch = PackedFloat32Array(%s)" % ", ".join(ss))
	_out.append("")
	_out.append('[node name="VacaPoza" type="Node" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("d_cow_pose")')
	_out.append("")
	print("; asezate %d noduri; respinse %s" % [_n, str(_stats)])
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
	# Axele benzilor (pentru planul de sus, unealta de verificare).
	var fr := FileAccess.open(_out_path + ".routes.csv", FileAccess.WRITE)
	for ri in _track.routes.size():
		var route := _track.route_at(ri)
		for j in route.baked.size():
			var hw := _track.width_at_index(j) if ri == 0 else route.half_width
			fr.store_line("%d,%.2f,%.2f,%.2f,%.2f" % [ri, route.baked[j].x, route.baked[j].y, route.baked[j].z, hw])
	fr.close()


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _track._sampler.ground_y(x, z)
