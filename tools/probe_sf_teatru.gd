extends Node
## TEATRUL de pe Track25 (brief san_francisco.md §7 pasul 8e): poarta, lampioanele, pescarusii,
## papagalii, velierele si feribotul, gradinita de la intrarea in serpentine. Scrise de
## tools/gen_sf_route.py (blocul „PASUL 8e"). Doua moduri:
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfTeatru.tscn -- --dump-perch --no-manual-batch
##       Pentru fiecare cerere din `tools/data/sf_8e_perch_req.tsv` (cheie x0 z0 x1 z1 n, Godot): n
##       raze verticale pe segmentul (x0,z0)-(x1,z1), pe TRIUNGHIURILE VIZUALE ale modelelor din scena
##       (nu pe coliziune, nu pe samplerul terenului); scrie cel mai inalt punct atins in
##       `tools/data/sf_8e_perch.tsv` (cheie x y z nod). De acolo generatorul pune picioarele pasarilor.
##       `--no-manual-batch` tine nodurile DecorManual necoapte (altfel coacerea le ascunde).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfTeatru.tscn [-- --sabotaj=...]
##       GARDA:
##         1. pasarile cocotate (stolurile `*Cocotati*`): picioarele la <= FEET_TOL de suprafata
##            vizuala de sub ele (nici in aer, nici ingropate); cele in zbor: >= FLY_MIN peste orice
##            suprafata;
##         2. barcile (`Barci/*`, PathMover): fiecare punct al traseului pe apa (terenul sub el la
##            <= -WATER_MIN), la >= BOAT_ROAD m de orice banda (deci si de ponton) si fara coliziune;
##         3. poarta: soclurile pe teren (niciunul in aer peste PLINTH_FLOAT, niciunul ingropat peste
##            PLINTH_BURY), amprenta in afara carosabilului si a trotuarului (`is_on_road` NU pe niciun
##            punct al conturului);
##         4. lampioanele: punctul cel mai jos (prinderea - 1,55) la >= LANTERN_CLEAR peste drum;
##         5. gradinita: pe teren (|baza - teren| <= 0,15).
##       `--sabotaj=pasari` coboara pasarile cocotate cu 0,3 m, `barci` muta un punct pe ponton,
##       `poarta` ridica poarta cu 0,4 m, `lampioane` le coboara cu 2,5 m: fiecare TREBUIE sa pice.
##         6. (a doua trecere) curtea portii si pasarile in miscare: vezi `_check_curte` si
##            `_check_movers`; sabotajele `curte` si `zbor`.
## Exit 1 daca pica ceva sau daca n-a gasit nimic de masurat.

const REQ_PATH := "res://tools/data/sf_8e_perch_req.tsv"
const OUT_PATH := "res://tools/data/sf_8e_perch.tsv"
const FEET_TOL: float = 0.06
const FLY_MIN: float = 2.0
const WATER_Y: float = 0.0       # golful (custom_sea_level_offset aduce apa la cota 0)
const WATER_MIN: float = 1.0
const BOAT_ROAD: float = 60.0
const PLINTH_FLOAT: float = 0.05
const PLINTH_BURY: float = 0.35
const LANTERN_CLEAR: float = 6.0
const LANTERN_SAG: float = 1.55
const GATE_PLINTHS := [Vector3(-5.10, 0.66, 1.40), Vector3(-3.40, 0.80, 2.20), Vector3(3.40, 0.80, 2.20),
	Vector3(5.10, 0.66, 1.40)]

var _sabotage := ""
var _track: Track
var _meshes: Array = []          # [MeshInstance3D, Transform3D global, AABB global, TriangleMesh]
var _space: PhysicsDirectSpaceState3D
var _fails := 0


func _ready() -> void:
	var dump := false
	var path := "res://scenes/tracks/Track25.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			path = a.trim_prefix("--scene=")
		elif a == "--dump-perch":
			dump = true
		elif a.begins_with("--sabotaj="):
			_sabotage = a.trim_prefix("--sabotaj=")
	_track = (load(path) as PackedScene).instantiate() as Track
	add_child(_track)
	for _i in 4:
		await get_tree().process_frame
		await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state
	print("=== ProbeSfTeatru: %s%s ===" % [_track.track_name, (" [SABOTAJ: %s]" % _sabotage) if _sabotage != "" else ""])
	if dump:
		_collect_meshes()
		_dump_perch()
		get_tree().quit(0)
		return
	_collect_meshes()
	var n := 0
	n += _check_birds()
	n += _check_boats()
	n += _check_gate()
	n += _check_lanterns()
	n += _check_garden()
	n += _check_curte()
	n += _check_movers()
	if n == 0:
		_fails += 1
		print("nimic de masurat (scena fara pasul 8e?)")
	print("VERDICT: %s%s" % ["PICA (%d)" % _fails if _fails > 0 else "OK", " [sabotaj]" if _sabotage != "" else ""])
	get_tree().quit(1 if _fails > 0 else 0)


## Toate MeshInstance3D vizibile ale pistei, cu triunghiurile lor (fara barci si pasarile in zbor: se misca).
func _collect_meshes() -> void:
	var stack: Array[Node] = [_track]
	var cache := {}
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if String(nd.name) in ["Barci", "PasariZbor"]:
			continue
		for c in nd.get_children():
			stack.append(c)
		var mi := nd as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var xf := mi.global_transform
		var aabb := xf * mi.mesh.get_aabb()
		if aabb.size.x > 600.0 or aabb.size.z > 600.0:
			continue          # terenul si apa: se masoara separat, pe coliziune
		var tm: TriangleMesh = cache.get(mi.mesh)
		if tm == null:
			tm = mi.mesh.generate_triangle_mesh()
			cache[mi.mesh] = tm
		if tm != null:
			_meshes.append([mi, xf, aabb, tm])
	print("modele cu triunghiuri: %d" % _meshes.size())


## Cel mai inalt punct VIZUAL sub (x, z): [y, nume nod] sau [NAN, ""]. `skip`: nodurile de ignorat.
func _visual_top(x: float, z: float, skip: Array = []) -> Array:
	var best := -INF
	var name := ""
	for m: Array in _meshes:
		var aabb: AABB = m[2]
		if x < aabb.position.x or x > aabb.end.x or z < aabb.position.z or z > aabb.end.z:
			continue
		var mi: MeshInstance3D = m[0]
		if skip.has(mi):
			continue
		var inv: Transform3D = (m[1] as Transform3D).affine_inverse()
		var from := inv * Vector3(x, aabb.end.y + 1.0, z)
		var to := inv * Vector3(x, aabb.position.y - 1.0, z)
		var hit: Dictionary = (m[3] as TriangleMesh).intersect_ray(from, (to - from).normalized())
		if hit.is_empty():
			continue
		var p: Vector3 = (m[1] as Transform3D) * (hit["position"] as Vector3)
		if p.y > best:
			best = p.y
			name = String(mi.get_parent().name) + "/" + String(mi.name)
	var t := _terrain(x, z)
	if not is_nan(t) and t > best:
		best = t
		name = "TerrainBody"
	return [best if best > -INF else NAN, name]


func _terrain(x: float, z: float) -> float:
	var excl: Array[RID] = []
	for _k in 10:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 300.0, z), Vector3(x, -100.0, z))
		q.exclude = excl
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name) == "TerrainBody":
			return float((hit["position"] as Vector3).y)
		excl.append(hit["rid"])
	return NAN


func _dump_perch() -> void:
	var f := FileAccess.open(REQ_PATH, FileAccess.READ)
	if f == null:
		print("lipseste %s (ruleaza intai generatorul)" % REQ_PATH)
		return
	var out := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	var n := 0
	while not f.eof_reached():
		var tk := f.get_line().split(" ", false)
		if tk.size() < 6:
			continue
		var x0 := float(tk[1])
		var z0 := float(tk[2])
		var x1 := float(tk[3])
		var z1 := float(tk[4])
		var cnt := maxi(1, int(tk[5]))
		var best := [-INF, "", 0.0, 0.0]
		for k in cnt:
			var t := float(k) / float(maxi(cnt - 1, 1))
			var x := lerpf(x0, x1, t)
			var z := lerpf(z0, z1, t)
			var r: Array = _visual_top(x, z)
			if not is_nan(float(r[0])) and float(r[0]) > float(best[0]):
				best = [float(r[0]), r[1], x, z]
		if float(best[0]) > -INF:
			out.store_line("%s %.3f %.3f %.3f %s" % [tk[0], float(best[2]), float(best[0]), float(best[3]),
				String(best[1]).replace(" ", "_")])
			n += 1
	out.close()
	print("cocotari: %d -> %s" % [n, OUT_PATH])


func _flock_xforms(fl: Node) -> Array:
	var pos: PackedVector3Array = fl.get("positions")
	return Array(pos)


func _check_birds() -> int:
	var n := 0
	for fl in _track.get_children():
		if not fl.has_meta("sf_8e_stol"):
			continue
		var perched := String(fl.name).contains("Cocotati")
		var worst := 0.0
		var worst_at := Vector3.ZERO
		var bad := 0
		var minfly := INF
		var worst_name := ""
		for p: Vector3 in _flock_xforms(fl):
			var py := p.y - (0.3 if perched and _sabotage == "pasari" else 0.0)
			var s: Array = _visual_top(p.x, p.z)
			if is_nan(float(s[0])):
				bad += 1
				continue
			var surf := float(s[0])
			if not perched and surf < WATER_Y:
				surf = WATER_Y          # in zbor peste golf: fata apei, nu fundul
				s[1] = "apa"
			var d := py - surf
			n += 1
			if perched:
				if absf(d) > absf(worst):
					worst = d
					worst_at = p
				if absf(d) > FEET_TOL:
					bad += 1
			else:
				if d < minfly:
					minfly = d
					worst_at = p
					worst_name = String(s[1])
				if d < FLY_MIN:
					bad += 1
		if perched:
			print("  %-20s %3d pasari, picioare - suprafata: cel mai departe %+.3f m la (%.1f, %.1f, %.1f) [prag %.2f], peste prag %d%s"
				% [fl.name, _flock_xforms(fl).size(), worst, worst_at.x, worst_at.y, worst_at.z, FEET_TOL, bad,
					"   PICA" if bad > 0 else ""])
		else:
			print("  %-20s %3d pasari in zbor, cel mai jos la %.1f m peste suprafata (%s, la %.0f, %.1f, %.0f) [prag %.1f]%s"
				% [fl.name, _flock_xforms(fl).size(), minfly, worst_name, worst_at.x, worst_at.y, worst_at.z, FLY_MIN,
					"   PICA" if bad > 0 else ""])
		if bad > 0:
			_fails += 1
	return n


func _check_boats() -> int:
	var b := _track.get_node_or_null(^"Barci")
	if b == null:
		return 0
	var n := 0
	for pm in b.get_children():
		var pts: PackedVector3Array = pm.get("points")
		var xf := (pm as Node3D).global_transform
		var min_depth := INF
		var min_road := INF
		var collide := bool(pm.get("collide"))
		var k := 0
		for lp in pts:
			var p := xf * lp
			if _sabotage == "barci" and k == 0 and n == 0:
				p = Vector3(80.0, 0.0, -460.0)      # langa ponton
			k += 1
			var t := _terrain(p.x, p.z)
			min_depth = minf(min_depth, -t if not is_nan(t) else 99.0)
			for ri in _track.routes.size():
				var r: TrackRoute = _track.routes[ri]
				var bi := r.closest_index_global(p)
				min_road = minf(min_road, Vector2(r.baked[bi].x - p.x, r.baked[bi].z - p.z).length())
		n += 1
		var bad := min_depth < WATER_MIN or min_road < BOAT_ROAD or collide
		if bad:
			_fails += 1
		print("  barca %-10s %2d puncte: apa sub ea >= %.1f m, cea mai apropiata banda %.0f m, coliziune %s%s" % [
			pm.name, pts.size(), min_depth, min_road, "DA" if collide else "nu", "   PICA" if bad else ""])
	return n


func _check_gate() -> int:
	var g := _track.get_node_or_null(^"DecorManual/Poarta/PoartaDragonului") as Node3D
	if g == null:
		return 0
	var xf := g.global_transform
	if _sabotage == "poarta":
		xf.origin.y += 0.4
	var worst_float := -INF
	var worst_bury := -INF
	for pl: Vector3 in GATE_PLINTHS:
		for dx: float in [-pl.y / 2.0, 0.0, pl.y / 2.0]:
			for dz: float in [-pl.z / 2.0, 0.0, pl.z / 2.0]:
				var p := xf * Vector3(pl.x + dx, 0.0, dz)
				var t := _terrain(p.x, p.z)
				worst_float = maxf(worst_float, p.y - t)
				worst_bury = maxf(worst_bury, t - p.y)
	var on_road := 0
	var x := -6.0
	while x <= 6.001:
		for z: float in [-1.83, 0.0, 1.83]:
			var p := xf * Vector3(x, 0.0, z)
			for ri in _track.routes.size():
				var bi := _track.closest_index_global(p, ri)
				if _track.is_on_road(bi, p + Vector3.UP * 0.5, ri):
					on_road += 1
		x += 0.5
	var bad := worst_float > PLINTH_FLOAT or worst_bury > PLINTH_BURY or on_road > 0
	if bad:
		_fails += 1
	print("  poarta la (%.1f, %.2f, %.1f): soclu in aer max %+.3f m [prag %.2f], ingropat max %.3f m [prag %.2f], puncte pe carosabil/trotuar %d%s"
		% [xf.origin.x, xf.origin.y, xf.origin.z, worst_float, PLINTH_FLOAT, worst_bury, PLINTH_BURY, on_road,
			"   PICA" if bad else ""])
	return 1


func _check_lanterns() -> int:
	var d := _track.get_node_or_null(^"DecorManual/Lampioane")
	if d == null:
		return 0
	var low := INF
	var n := 0
	for c in d.get_children():
		var p := (c as Node3D).global_position
		if _sabotage == "lampioane":
			p.y -= 2.5
		var bi := _track.closest_index_global(p)
		var road_y := _track.baked[bi].y
		low = minf(low, p.y - LANTERN_SAG - road_y)
		n += 1
	var bad := low < LANTERN_CLEAR
	if bad:
		_fails += 1
	print("  lampioane: %d module, punctul cel mai jos la %.2f m peste drum [prag %.1f]%s" % [n, low, LANTERN_CLEAR,
		"   PICA" if bad else ""])
	return n


func _check_garden() -> int:
	var d := _track.get_node_or_null(^"DecorManual/GradinaSerpentine")
	if d == null:
		return 0
	var worst := 0.0
	var n := 0
	for c in d.get_children():
		var p := (c as Node3D).global_position
		var t := _terrain(p.x, p.z)
		if absf(p.y - t) > absf(worst):
			worst = p.y - t
		n += 1
	var bad := absf(worst) > 0.15
	if bad:
		_fails += 1
	print("  gradinita: %d module, baza - teren cel mai departe %+.2f m [prag 0,15]%s" % [n, worst, "   PICA" if bad else ""])
	return n


## PASUL 8e, a doua trecere: CURTEA PORTII. Pavajul (`Track.paved_patches`) NU e drum (`is_on_road` fals
## in centrul fiecarui triunghi) si e suprafata de deasupra (prima suprafata de rulare e `Trotuar`, nu
## nisip peste el); casele ulitei (`DecorManual/CurtePoarta`, metadata `sf_case`) au amprenta in afara
## carosabilului si a trotuarului; ghirlandele ulitei la >= CURTE_CLEAR peste pavaj.
## `--sabotaj=curte` muta pavajul si casele cu 20 m spre N (pe carosabilul coltului): TREBUIE sa pice.
const CURTE_CLEAR: float = 4.0
const CURTE_ROAD_GAP: float = 3.0


func _walk_name(x: float, z: float) -> String:
	var excl: Array[RID] = []
	for _k in 12:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 300.0, z), Vector3(x, -100.0, z))
		q.exclude = excl
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return ""
		var col := hit["collider"] as Node
		var nm := String(col.name) if col != null else ""
		if nm in ["Trotuar", "TerrainBody", "RoadTop", "RoadSides", "Shoulders"]:
			return nm
		excl.append(hit["rid"])
	return ""


func _check_curte() -> int:
	var pp := _track.paved_patches
	if pp.size() < 3:
		return 0
	var on_road := 0
	var sand := 0
	var n := 0
	for k in range(0, pp.size() - 2, 3):
		var c := (pp[k] + pp[k + 1] + pp[k + 2]) / 3.0
		if _sabotage == "curte":
			c.z -= 20.0
		n += 1
		var bi := _track.closest_index_global(c)
		if _track.is_on_road(bi, c + Vector3.UP * 0.5):
			on_road += 1
		if _sabotage != "curte" and _walk_name(c.x, c.z) != "Trotuar":
			sand += 1
	# casele: amprenta cutiilor de coliziune (`CurtePoartaCorpuri`), colturile bazei cu 0,5 m inauntru;
	# fiecare la >= half_width + CURTE_ROAD_GAP de axul oricarei benzi si nu pe trotuarul/pavajul de sub ele
	var houses := 0
	var h_bad := 0
	var min_gap := INF
	var body := _track.get_node_or_null(^"CurtePoartaCorpuri")
	if body != null:
		for cs in body.get_children():
			var box := (cs as CollisionShape3D).shape as BoxShape3D
			if box == null:
				continue
			houses += 1
			var xf := (cs as Node3D).global_transform
			var hx := box.size.x * 0.5 - 0.5
			var hz := box.size.z * 0.5 - 0.5
			for c2: Vector2 in [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]:
				var p := xf * Vector3(c2.x, -box.size.y * 0.5, c2.y)
				if _sabotage == "curte":
					p.z -= 20.0
				for r: TrackRoute in _track.routes:
					var bi := r.closest_index_global(p)
					var dh := Vector2(r.baked[bi].x - p.x, r.baked[bi].z - p.z).length() - _track.half_width
					min_gap = minf(min_gap, dh)
					if dh < CURTE_ROAD_GAP:
						h_bad += 1
				if _walk_name(p.x, p.z) == "Trotuar":
					h_bad += 1
	var low := INF
	var d := _track.get_node_or_null(^"DecorManual/CurtePoarta")
	if d != null:
		for h in d.get_children():
			var h3 := h as Node3D
			if h3.has_meta("sf_curte_ghirlanda"):
				low = minf(low, h3.global_position.y - LANTERN_SAG - float(h3.get_meta("sf_curte_ghirlanda")))
	var bad := on_road > 0 or sand > 0 or h_bad > 0 or (low < CURTE_CLEAR)
	if bad:
		_fails += 1
	print("  curtea portii: %d triunghiuri de pavaj, pe drum %d, nisip peste pavaj %d; %d case, cel mai aproape de marginea drumului %.1f m [prag %.1f], colturi prea aproape/pe trotuar %d; ghirlandele ulitei la %.2f m peste pavaj [prag %.1f]%s"
		% [n, on_road, sand, houses, min_gap, CURTE_ROAD_GAP, h_bad, low, CURTE_CLEAR, "   PICA" if bad else ""])
	return n


## PASUL 8e, a doua trecere: PASARILE IN MISCARE (`PasariZbor/*`, PathMover). Fiecare punct al buclei:
## nu intra in nimic (>= MOVER_SOLID peste suprafata vizuala), iar fata de benzi: cele marcate
## `sf_8e_zbor = true` (papagalii care traverseaza strada coamei) pot trece peste carosabil doar la
## >= MOVER_ROAD_H peste el si niciodata in fereastra unei muchii (`jump_crests`, unde masinile zboara);
## restul stau la >= MOVER_LANE m de orice punct al oricarei benzi (pescarusii de langa tablier).
## `--sabotaj=zbor` coboara toate buclele cu 4 m: TREBUIE sa pice.
const MOVER_SOLID: float = 1.0
const MOVER_ROAD_H: float = 4.0
const MOVER_LANE: float = 12.0


func _check_movers() -> int:
	var root := _track.get_node_or_null(^"PasariZbor")
	if root == null:
		return 0
	var crests: Array = _track.get_meta("jump_crests", [])
	var n := 0
	for pm in root.get_children():
		var pts: PackedVector3Array = pm.get("points")
		var xf := (pm as Node3D).global_transform
		var over_ok := bool(pm.get_meta("sf_8e_zbor", false))
		var min_solid := INF
		var min_lane := INF
		var min_road_h := INF
		var in_crest := 0
		var worst := Vector3.ZERO
		for lp in pts:
			var p := xf * lp
			if _sabotage == "zbor":
				p.y -= 4.0
			var s: Array = _visual_top(p.x, p.z)
			var surf := maxf(float(s[0]) if not is_nan(float(s[0])) else -INF, WATER_Y)
			if p.y - surf < min_solid:
				min_solid = p.y - surf
				worst = p
			for ri in _track.routes.size():
				var r: TrackRoute = _track.routes[ri]
				var bi := r.closest_index_global(p)
				var dh := Vector2(r.baked[bi].x - p.x, r.baked[bi].z - p.z).length()
				min_lane = minf(min_lane, dh)
				if dh < _track.half_width + 2.0:
					min_road_h = minf(min_road_h, p.y - r.baked[bi].y)
					if ri == 0:
						var f := float(bi) / float(r.baked.size())
						for cw: Vector2 in crests:
							if f >= cw.x and f <= cw.y:
								in_crest += 1
		n += 1
		var bad := min_solid < MOVER_SOLID
		if over_ok:
			bad = bad or (min_road_h < MOVER_ROAD_H) or in_crest > 0
		else:
			bad = bad or min_lane < MOVER_LANE
		if bad:
			_fails += 1
		print("  in zbor %-14s %2d puncte: peste suprafata >= %.1f m (la %.0f, %.1f, %.0f), cea mai apropiata banda %.1f m%s, viteza %.1f m/s%s"
			% [pm.name, pts.size(), min_solid, worst.x, worst.y, worst.z, min_lane,
				(", peste carosabil la >= %.1f m, in ferestrele muchiilor %d" % [min_road_h, in_crest]) if over_ok else "",
				float(pm.get("speed")), "   PICA" if bad else ""])
	return n
