extends Node
## CASELE DE RAND de pe Track25 (brief san_francisco.md §7 pasul 8, kitul `sf_row_*`): randurile
## din FATA, scrise de tools/gen_sf_route.py sub `DecorManual/Case<zona>`, cu cutiile de coliziune
## sub `CaseCorpuri`. Doua moduri:
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfCase.tscn -- \
##       --dump-ground=res://tools/data/sf_case_ground.tsv
##       Harta cotelor TERENULUI (raze verticale pe `TerrainBody`, trecand prin sosea, cutii,
##       acostament) pe o grila de 1 m peste benzile in care stau casele. Generatorul o citeste
##       ca sa aseze podeaua fiecarei case pe teren (Track25 n-are trotuar: podeaua = cota cea mai
##       inalta a terenului pe linia fatadei, adica capatul de SUS al casei pe strada in panta).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfCase.tscn -- ##       --dump-baked=res://tools/data/sf_route_baked.tsv
##       Punctele coapte ale buclei (ruta 0, x y z Godot, in ordinea indicilor). Generatorul (pasul
##       8d) le citeste ca sa puna ferestrele trotuarelor pe punctele coapte si sa stie cota EXACTA a
##       trotuarului (placa la cota buzei asfaltului, liniara intre doua puncte coapte). Se reface
##       odata cu harta de fractii, adica doar daca se muta traseul.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfCase.tscn [-- --sabotaj]
##       GARDA, pe scena reala (coliziunea reala a terenului, curbele coapte):
##         1. pe linia fatadei terenul nu iese peste podea (> 0,05 m = casa ingropata in fata);
##            (pasul 8d) „terenul" e suprafata de sus: trotuarul, unde exista, altfel terenul — deci si
##            trotuarul ridicat peste prag ingroapa usa si pica garda;
##         2. fusta (podeaua - 2,4) nu ramane in aer nicaieri pe fatada si pe laturile LIBERE
##            (capetele de rand) — altfel se vede golul de sub casa;
##         3. cutia de coliziune (amprenta) sta la >= semilatimea + 1,5 m de axa soselei si a
##            scurtaturii, la >= 0,6 m de mașinile parcate, la >= 2,0 m de axa tramvaielor;
##         4. casele nu se suprapun (amprentele, cu 2 cm toleranta);
##         5. fiecare casa are cutia ei (`CaseCorpuri/Corp_<nume>`), cu amprenta casei.
##       Informativ: cat se ingroapa spatele casei in deal, fusta pe spate.
##         6. (pasul 8c) nicio latura LIBERA (fara casa lipita la 0,5 m) a unei case care nu e colt nu
##            e perete orb: e latura finisata a unei case de CAPAT (`sf_row_end_*`: baza pe -X, `_m`
##            pe +X), iar latura finisata a unei case de capat e libera. Casele pictate de pe coama
##            (zona C, cutiile sub `CasePictateCorpuri`) au cutia cu adancimea pridvorului
##            (metadata `sf_case_porch`).
##       `--sabotaj` coboara podeaua masurata cu 1 m: garda TREBUIE sa pice (punctul 1).
##       `--sabotaj-capat` le trateaza pe casele de capat ca pe case de rand: garda TREBUIE sa pice
##       (punctul 6, peretii orbi).
## Exit 1 daca pica ceva sau daca n-a masurat nicio casa.

const SKIRT: float = 2.4
const POKE_MAX: float = 0.05
const ROAD_SHOULDER: float = 1.5
const CAR_GAP: float = 0.6
const TRAM_GAP: float = 2.0
const TRAM_HALF_W: float = 1.25
const OVERLAP_TOL: float = 0.02
## Benzile in care se cere harta terenului (x0, z0, x1, z1 in Godot; nord = -Z). Largi: generatorul
## poate muta randurile fara o noua harta, cat raman inauntru.
const GROUND_RECTS: Array[Rect2] = [
	Rect2(-30.0, -275.0, 60.0, 282.0),      # D lantul, x 0, y -7..275
	Rect2(114.0, -190.0, 62.0, 312.0),      # B strada tramvaiului 1, x 144, y -122..190
	Rect2(116.0, -428.0, 30.0, 162.0),      # G strada de intors, latura de V
	Rect2(-156.0, -436.0, 62.0, 122.0),     # E ocolul, strada spre N (x -124,7)
	Rect2(-106.0, -346.0, 84.0, 28.0),      # E ocolul, strada spre V (y 315), latura de N
]

var _dump := ""
var _dump_baked := ""
var _sabotage := false
var _sabotage_end := false
## `--spate`: tipareste fiecare casa cu fusta din spate in aer > 0,3 m (pasul 8d, informativ).
var _detail_back := false
var _space: PhysicsDirectSpaceState3D
var _fails := 0


func _ready() -> void:
	var path := "res://scenes/tracks/Track25.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			path = a.trim_prefix("--scene=")
		elif a.begins_with("--dump-ground="):
			_dump = a.trim_prefix("--dump-ground=")
		elif a.begins_with("--dump-baked="):
			_dump_baked = a.trim_prefix("--dump-baked=")
		elif a == "--sabotaj":
			_sabotage = true
		elif a == "--spate":
			_detail_back = true
		elif a == "--sabotaj-capat":
			_sabotage_end = true
	var track := (load(path) as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 3:
		await get_tree().process_frame
		await get_tree().physics_frame
	_space = track.get_world_3d().direct_space_state
	print("=== ProbeSfCase: %s (%s) ===" % [track.track_name, path.get_file()])
	if not _dump.is_empty():
		_dump_ground()
		get_tree().quit(0)
		return
	if not _dump_baked.is_empty():
		var f := FileAccess.open(_dump_baked, FileAccess.WRITE)
		for p: Vector3 in track.baked:
			f.store_line("%.4f %.4f %.4f" % [p.x, p.y, p.z])
		f.close()
		print("bucla coapta: %d puncte -> %s" % [track.baked.size(), _dump_baked])
		get_tree().quit(0)
		return
	get_tree().quit(_check(track))


## Cota terenului (primul `TerrainBody` sub punct, trecand prin orice altceva), sau NAN.
func _ground(x: float, z: float) -> float:
	return _first(x, z, ["TerrainBody"])


## Cota SUPRAFETEI pe care sta casa: terenul sau, unde exista, trotuarul (pasul 8d: placa
## `paved_level_zones` din banda `Shoulders`, la cota buzei asfaltului). Ce se vede in fata casei e
## suprafata cea mai de sus dintre ele; terenul de sub trotuar e ascuns. Trotuarul e in `Shoulders`
## sau, cu `paved_level_color`, in corpul lui (`Trotuar`).
func _surface(x: float, z: float) -> float:
	return _first(x, z, ["TerrainBody", "Shoulders", "Trotuar"])


func _first(x: float, z: float, names: Array) -> float:
	var excl: Array[RID] = []
	for _k in 8:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 160.0, z), Vector3(x, -60.0, z))
		q.exclude = excl
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name) in names:
			return float((hit["position"] as Vector3).y)
		excl.append(hit["rid"])
	return NAN


func _dump_ground() -> void:
	var f := FileAccess.open(_dump, FileAccess.WRITE)
	if f == null:
		push_error("ProbeSfCase: nu pot scrie %s" % _dump)
		return
	var n := 0
	var miss := 0
	for r: Rect2 in GROUND_RECTS:
		var x := r.position.x
		while x <= r.end.x + 0.01:
			var z := r.position.y
			while z <= r.end.y + 0.01:
				var y := _ground(x, z)
				if is_nan(y):
					miss += 1
				else:
					f.store_line("%.1f %.1f %.3f" % [x, z, y])
					n += 1
				z += 1.0
			x += 1.0
	f.close()
	print("harta terenului: %d puncte (%d fara teren) -> %s" % [n, miss, _dump])


## Amprenta casei in XZ (4 colturi), din transformarea ei si latimea `w` (7 sau 9 m).
static func _footprint(xf: Transform3D, w: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c: Vector2 in [Vector2(-w * 0.5, -6.0), Vector2(w * 0.5, -6.0), Vector2(w * 0.5, 6.0), Vector2(-w * 0.5, 6.0)]:
		var p := xf * Vector3(c.x, 0.0, c.y)
		out.append(Vector2(p.x, p.z))
	return out


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _inside(p: Vector2, poly: PackedVector2Array, tol: float) -> bool:
	# convex, colturile in ordine; `tol` > 0 micsoreaza poligonul
	var sgn := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var c := (b - a).cross(p - a) / maxf((b - a).length(), 1e-9)
		if absf(c) < tol:
			return false
		if sgn == 0.0:
			sgn = signf(c)
		elif signf(c) != sgn:
			return false
	return true


## Punctele de pe conturul poligonului, din 0,5 in 0,5 m.
static func _edge_pts(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := maxi(1, int(ceil(a.distance_to(b) / 0.5)))
		for k in n:
			out.append(a.lerp(b, float(k) / float(n)))
	return out


static func _poly_poly_dist(pa: PackedVector2Array, pb: PackedVector2Array) -> float:
	var best := INF
	for p in _edge_pts(pa):
		if _inside(p, pb, 0.0):
			return 0.0
		for i in pb.size():
			best = minf(best, _seg_dist(p, pb[i], pb[(i + 1) % pb.size()]))
	for p in _edge_pts(pb):
		if _inside(p, pa, 0.0):
			return 0.0
	return best


static func _poly_line_dist(poly: PackedVector2Array, line: PackedVector2Array) -> float:
	var best := INF
	var pts := _edge_pts(poly)
	for j in line.size() - 1:
		var a := line[j]
		var b := line[j + 1]
		if _inside(a, poly, 0.0):
			return 0.0
		for p in pts:
			best = minf(best, _seg_dist(p, a, b))
	return best


func _check(track: Track) -> int:
	var dm := track.get_node_or_null(^"DecorManual")
	var corp := track.get_node_or_null(^"CaseCorpuri")
	var corp_pl := track.get_node_or_null(^"CasePictateCorpuri")
	if dm == null:
		print("FARA DecorManual")
		return 1
	# casele: instantele cu metadata `sf_case` (zona), oricat de adanc sub DecorManual
	var houses: Array[Node3D] = []
	var stack: Array[Node] = [dm]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is Node3D and n.has_meta("sf_case"):
			houses.append(n as Node3D)
	print("case: %d" % houses.size())
	if houses.is_empty():
		return 1
	# liniile de comparat (XZ)
	var lines: Array = []   # [nume, PackedVector2Array, prag]
	for ri in track.routes.size():
		var r: TrackRoute = track.routes[ri]
		var pl := PackedVector2Array()
		for p: Vector3 in r.baked:
			pl.append(Vector2(p.x, p.z))
		if ri == 0:
			pl.append(pl[0])
		var hw := 7.0 if ri == 0 else 4.5
		lines.append(["soseaua" if ri == 0 else "scurtatura", pl, hw + ROAD_SHOULDER])
	var trams := track.get_node_or_null(^"Tramvaie")
	if trams != null:
		for t in trams.get_children():
			var p3 := t as Path3D
			if p3 == null or p3.curve == null:
				continue
			var pl := PackedVector2Array()
			for p: Vector3 in p3.curve.get_baked_points():
				var w := p3.global_transform * p
				pl.append(Vector2(w.x, w.z))
			lines.append([String(p3.name), pl, TRAM_HALF_W + TRAM_GAP])
	var cars: Array[PackedVector2Array] = []
	var mp := track.get_node_or_null(^"MasiniParcate")
	if mp != null:
		for c in mp.get_children():
			var xf := (c as Node3D).global_transform
			var poly := PackedVector2Array()
			for q: Vector2 in [Vector2(-0.95, -1.85), Vector2(0.95, -1.85), Vector2(0.95, 1.85), Vector2(-0.95, 1.85)]:
				var w := xf * Vector3(q.x, 0.0, q.y)
				poly.append(Vector2(w.x, w.z))
			cars.append(poly)
	var fps: Array[PackedVector2Array] = []
	for h in houses:
		fps.append(_footprint(h.global_transform, float(h.get_meta("sf_case_w", 7.0))))
	var zones := {}
	for hi in houses.size():
		var h := houses[hi]
		var zone := String(h.get_meta("sf_case"))
		if not zones.has(zone):
			zones[zone] = {"n": 0, "corner": 0, "poke": -INF, "skirt": INF, "back": -INF,
				"back_skirt": INF, "road": INF, "car": INF, "tram": INF, "bad": 0}
		var z: Dictionary = zones[zone]
		z["n"] += 1
		var w := float(h.get_meta("sf_case_w", 7.0))
		if w > 8.0:
			z["corner"] += 1
		var xf := h.global_transform
		var floor_y := xf.origin.y - (1.0 if _sabotage else 0.0)
		var why: Array[String] = []
		# 1 + 2: linia fatadei
		var x := -w * 0.5
		var poke := -INF
		var skirt := INF
		while x <= w * 0.5 + 0.001:
			var p := xf * Vector3(x, 0.0, -6.0)
			var g := _surface(p.x, p.z)
			if not is_nan(g):
				poke = maxf(poke, g - floor_y)
				skirt = minf(skirt, g - (floor_y - SKIRT))
			x += 0.5
		# laturile libere (fara vecin la 0,5 m) si spatele
		var back := -INF
		var back_skirt := INF
		var free_sides: Array[float] = []
		for sx: float in [-1.0, 1.0]:
			var probe_out := xf * Vector3(sx * (w * 0.5 + 0.5), 0.0, 0.0)
			var free := true
			for hj in houses.size():
				if hj != hi and _inside(Vector2(probe_out.x, probe_out.z), fps[hj], 0.0):
					free = false
					break
			if not free:
				continue
			free_sides.append(sx)
			var zz := -6.0
			while zz <= 6.001:
				var p := xf * Vector3(sx * w * 0.5, 0.0, zz)
				var g := _surface(p.x, p.z)
				if not is_nan(g):
					skirt = minf(skirt, g - (floor_y - SKIRT))
				zz += 0.5
		x = -w * 0.5
		while x <= w * 0.5 + 0.001:
			var p := xf * Vector3(x, 0.0, 6.0)
			var g := _surface(p.x, p.z)
			if not is_nan(g):
				back = maxf(back, g - floor_y)
				back_skirt = minf(back_skirt, g - (floor_y - SKIRT))
			x += 0.5
		# 6: peretii orbi. Casa de capat: latura finisata pe -X (baza) sau +X (`_m`).
		var stem := h.scene_file_path.get_file().get_basename()
		var is_end := stem.begins_with("sf_row_end_") and not _sabotage_end
		var fin := (1.0 if stem.ends_with("_m") else -1.0) if is_end else 0.0
		if is_end:
			z["end"] = int(z.get("end", 0)) + 1
		if w <= 8.0:
			for sx in free_sides:
				if sx != fin:
					why.append("perete orb spre exterior (latura %s)" % ("+X" if sx > 0.0 else "-X"))
			if is_end and not (fin in free_sides):
				why.append("latura finisata a casei de capat e lipita de alta casa")
		if poke > POKE_MAX:
			why.append("teren peste podea pe fatada %+.2f m" % poke)
		if skirt < 0.0:
			why.append("fusta in aer %.2f m" % -skirt)
		# 3: distante
		var fp := fps[hi]
		for L: Array in lines:
			var d := _poly_line_dist(fp, L[1])
			var key := "road" if String(L[0]) in ["soseaua", "scurtatura"] else "tram"
			z[key] = minf(z[key], d)
			if d < float(L[2]):
				why.append("%s la %.2f m (prag %.2f)" % [L[0], d, L[2]])
		for cp in cars:
			var d := _poly_poly_dist(fp, cp)
			z["car"] = minf(z["car"], d)
			if d < CAR_GAP:
				why.append("masina parcata la %.2f m" % d)
		# 4: suprapuneri (o singura data pe pereche)
		for hj in range(hi + 1, houses.size()):
			var ov := false
			for p in fps[hi]:
				if _inside(p, fps[hj], OVERLAP_TOL):
					ov = true
			for p in fps[hj]:
				if _inside(p, fps[hi], OVERLAP_TOL):
					ov = true
			# centrul uneia in cealalta (amprente egale, suprapuse exact)
			var ci := (fps[hi][0] + fps[hi][2]) * 0.5
			if _inside(ci, fps[hj], OVERLAP_TOL):
				ov = true
			if ov:
				why.append("se suprapune cu %s" % houses[hj].name)
		# 5: cutia
		var body: Node = null
		for cb: Node in [corp, corp_pl]:
			if cb != null and body == null:
				body = cb.get_node_or_null(NodePath("Corp_%s" % h.name))
		# casele pictate: cutia are si adancimea pridvorului (spre -Z, in fata fatadei)
		var porch := float(h.get_meta("sf_case_porch", 0.0))
		if body == null:
			why.append("fara cutie de coliziune")
		else:
			var cs := body as CollisionShape3D
			var bx := cs.shape as BoxShape3D if cs != null else null
			if bx == null or absf(bx.size.x - w) > 0.01 or absf(bx.size.z - 12.0 - porch) > 0.01:
				why.append("cutia nu are amprenta casei")
			else:
				var c := cs.global_transform.origin
				var lc := xf.affine_inverse() * c
				if Vector2(lc.x, lc.z + porch * 0.5).length() > 0.02 or absf(c.y - bx.size.y * 0.5 - (xf.origin.y - SKIRT)) > 0.02:
					why.append("cutia e mutata fata de casa")
		if _detail_back and back_skirt < -0.3:
			var bc := xf * Vector3(0.0, 0.0, 6.0)
			print("  spate in aer %-10s %+.2f m, mijlocul spatelui la (%.1f, %.1f, %.1f)" % [h.name, back_skirt,
				bc.x, xf.origin.y - SKIRT, bc.z])
		z["poke"] = maxf(z["poke"], poke)
		z["skirt"] = minf(z["skirt"], skirt)
		z["back"] = maxf(z["back"], back)
		z["back_skirt"] = minf(z["back_skirt"], back_skirt)
		if not why.is_empty():
			z["bad"] += 1
			_fails += 1
			print("  PICA %s (%s): %s" % [h.name, zone, "; ".join(why)])
	print("%-6s %5s %6s %16s %16s %14s %14s %12s %12s %8s" % ["zona", "case", "colt",
		"teren-podea max", "rezerva fusta", "spate ingropat", "fusta spate", "sosea min",
		"masini min", "tramvai"])
	var keys := zones.keys()
	keys.sort()
	for k in keys:
		var z: Dictionary = zones[k]
		print("%-6s %5d %6d %+15.2fm %+15.2fm %+13.2fm %+13.2fm %11.2fm %11.2fm %7.1fm%s" % [k, z["n"],
			z["corner"], z["poke"], z["skirt"], z["back"], z["back_skirt"], z["road"], z["car"],
			z["tram"], ("   PICA %d" % z["bad"]) if z["bad"] > 0 else ""])
	var n_end := 0
	for k in keys:
		n_end += int((zones[k] as Dictionary).get("end", 0))
	print("case de capat: %d (cu latura finisata libera, fara pereti orbi la capetele fara colt)%s" % [n_end,
		" [sabotaj: capetele tratate ca case de rand]" if _sabotage_end else ""])
	if corp != null:
		print("cutii de coliziune: %d + %d sub CasePictateCorpuri (case %d)" % [corp.get_child_count(),
			corp_pl.get_child_count() if corp_pl != null else 0, houses.size()])
	print("VERDICT: %s%s" % ["PICA (%d case)" % _fails if _fails > 0 else "OK",
		" [sabotaj: podeaua -1 m]" if _sabotage else ""])
	return 1 if _fails > 0 else 0
