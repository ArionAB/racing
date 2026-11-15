extends Node
## RANDURILE DIN SPATE ale caselor de pe Track25 (brief san_francisco.md §7 pasul 8b): umplutura
## `CityFill` (nodul `CaseSpate`, `explicit_xforms` scrise de tools/gen_sf_route.py) din spatele
## randurilor din fata. Doua moduri:
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfSpate.tscn -- \
##       --dump-ground=res://tools/data/sf_spate_ground.tsv
##       Harta cotelor TERENULUI (raze verticale pe `TerrainBody`, trecand prin orice altceva) pe o
##       grila de 2 m peste tot orasul. Generatorul o citeste ca sa aseze fiecare casa din spate pe
##       teren. Se reface daca se schimba traseul sau terenul (ca `sf_case_ground.tsv`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfSpate.tscn [-- --sabotaj]
##       GARDA, pe scena reala (terenul real, nodul `CaseSpate` construit):
##         1. fiecare casa din spate: terenul nu iese peste podea pe linia fatadei (> 0,05 m) si
##            fusta (podeaua - 2,4) nu ramane in aer pe niciun punct VIZIBIL al conturului (fara
##            alta casa, din fata sau din spate, lipita de el la 0,3 m);
##         2. nicio latura vizibila nu e ingropata peste `BURY_MAX` (4 m, ca generatorul: un etaj in deal);
##         3. amprenta (cu bovindoul, 7 x 12,9 m) nu atinge amprenta niciunei case din fata
##            (`DecorManual`, metadata `sf_case`) si a niciunei alte case din spate;
##         4. distanta de la amprenta la axa soselei / scurtaturii / tramvaielor; sub `ROAD_FREE`
##            (40 m) casa TREBUIE sa aiba cutia ei sub `CaseSpateCorpuri`;
##         5. nicio casa in apa (podeaua sub `WATER_Y`) si niciuna oglindita in buffer
##            (determinant negativ = casa pe dos in MultiMesh);
##         6. `CityFill.stats`: case construite = case cerute, buffere > 0 (masuratoare vie).
##       `--sabotaj` coboara podeaua masurata cu 1 m: garda TREBUIE sa pice (punctul 1).
## Exit 1 daca pica ceva sau daca n-a masurat nicio casa.

const SKIRT: float = 2.4
const POKE_MAX: float = 0.05
const BURY_MAX: float = 4.05
const ROAD_FREE: float = 40.0
## Ca in generator (`SPATE_ROAD_MIN`, `SPATE_TRAM_MIN`): amprenta fata de axa benzii / tramvaiului.
const ROAD_MIN: float = 20.0
const TRAM_MIN: float = 6.0
const WATER_Y: float = 1.0
const OVERLAP_TOL: float = 0.02
## Zona hartii (Godot x0, z0, latime, adancime): tot orasul, de la flancul de V pana la strâmtoare.
const GROUND_RECT := Rect2(-260.0, -470.0, 530.0, 620.0)
const GROUND_STEP: float = 2.0

var _dump := ""
var _sabotage := false
var _space: PhysicsDirectSpaceState3D
var _fails := 0


func _ready() -> void:
	var path := "res://scenes/tracks/Track25.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			path = a.trim_prefix("--scene=")
		elif a.begins_with("--dump-ground="):
			_dump = a.trim_prefix("--dump-ground=")
		elif a == "--sabotaj":
			_sabotage = true
	var track := (load(path) as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 3:
		await get_tree().process_frame
		await get_tree().physics_frame
	_space = track.get_world_3d().direct_space_state
	print("=== ProbeSfSpate: %s (%s) ===" % [track.track_name, path.get_file()])
	if not _dump.is_empty():
		_dump_ground()
		get_tree().quit(0)
		return
	get_tree().quit(await _check(track))


## Cota terenului (primul `TerrainBody` sub punct, trecand prin orice altceva), sau NAN.
func _ground(x: float, z: float) -> float:
	var excl: Array[RID] = []
	for _k in 8:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 160.0, z), Vector3(x, -60.0, z))
		q.exclude = excl
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name) == "TerrainBody":
			return float((hit["position"] as Vector3).y)
		excl.append(hit["rid"])
	return NAN


func _dump_ground() -> void:
	var f := FileAccess.open(_dump, FileAccess.WRITE)
	if f == null:
		push_error("ProbeSfSpate: nu pot scrie %s" % _dump)
		return
	var n := 0
	var miss := 0
	var r := GROUND_RECT
	var x := r.position.x
	while x <= r.end.x + 0.01:
		var z := r.position.y
		while z <= r.end.y + 0.01:
			var y := _ground(x, z)
			if is_nan(y):
				miss += 1
			else:
				f.store_line("%.0f %.0f %.2f" % [x, z, y])
				n += 1
			z += GROUND_STEP
		x += GROUND_STEP
	f.close()
	print("harta terenului: %d puncte (%d fara teren), pas %.0f m -> %s" % [n, miss, GROUND_STEP, _dump])


## Amprenta in XZ (4 colturi, in sens), din transformare: latimea `w`, adancimea de la `z0` la `z1`.
static func _fp(xf: Transform3D, w: float, z0: float, z1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c: Vector2 in [Vector2(-w * 0.5, z0), Vector2(w * 0.5, z0), Vector2(w * 0.5, z1), Vector2(-w * 0.5, z1)]:
		var p := xf * Vector3(c.x, 0.0, c.y)
		out.append(Vector2(p.x, p.z))
	return out


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _inside(p: Vector2, poly: PackedVector2Array, tol: float) -> bool:
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


## Distanta de la amprenta (colturi, mijloacele laturilor, centru) la o polilinie.
static func _poly_line_dist(poly: PackedVector2Array, line: PackedVector2Array) -> float:
	var pts := PackedVector2Array(poly)
	var c := Vector2.ZERO
	for i in poly.size():
		pts.append((poly[i] + poly[(i + 1) % poly.size()]) * 0.5)
		c += poly[i]
	pts.append(c / float(poly.size()))
	var best := INF
	for j in line.size() - 1:
		for p in pts:
			best = minf(best, _seg_dist(p, line[j], line[j + 1]))
	return best


func _check(track: Track) -> int:
	var fill: CityFill = null
	for n in track.find_children("*", "CityFill", true, false):
		if (n as Node).has_meta("sf_spate"):
			fill = n as CityFill
	if fill == null:
		print("FARA nodul CaseSpate (CityFill cu metadata sf_spate)")
		return 1
	# `_build` e amanat si asteapta un cadru de fizica: statisticile apar dupa el.
	for _i in 600:
		if not fill.stats.is_empty():
			break
		await get_tree().process_frame
	if fill.stats.is_empty():
		print("MASURATOARE MOARTA: CityFill n-a construit nimic")
		return 1
	# --- casele din fata (DecorManual, metadata sf_case): amprentele, fara bovindou
	var front: Array[PackedVector2Array] = []
	var dm := track.get_node_or_null(^"DecorManual")
	if dm != null:
		var stack: Array[Node] = [dm]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			if n is Node3D and n.has_meta("sf_case"):
				front.append(_fp((n as Node3D).global_transform, float(n.get_meta("sf_case_w", 7.0)), -6.0, 6.0))
	# --- casele din spate, din instantele explicite (citite din export: MultiMesh-ul nu se poate
	# citi inapoi headless, memoria `multimesh-masuratoare-moarta`)
	var f := fill.explicit_xforms
	var xfs: Array[Transform3D] = []
	var neg := 0
	var i := 0
	while i + 13 <= f.size():
		var b := Basis(Vector3(f[i + 1], f[i + 2], f[i + 3]), Vector3(f[i + 4], f[i + 5], f[i + 6]),
			Vector3(f[i + 7], f[i + 8], f[i + 9]))
		var xf := Transform3D(b, Vector3(f[i + 10], f[i + 11], f[i + 12]))
		if b.determinant() < 0.0:
			neg += 1
			# imaginea e aceeasi cu casa oglindita `_m` sub transformarea pozitiva
			xf.basis.x = -xf.basis.x
		xfs.append(xf)
		i += 13
	print("case din spate: %d (cerute oglindit: %d); din fata: %d" % [xfs.size(), neg, front.size()])
	if xfs.is_empty():
		return 1
	var back: Array[PackedVector2Array] = []
	var back_bay: Array[PackedVector2Array] = []
	for xf in xfs:
		back.append(_fp(xf, 7.0, -6.0, 6.0))
		back_bay.append(_fp(xf, 7.0, -6.9, 6.0))
	# --- liniile (soseaua, scurtatura, tramvaiele) si cutiile
	var lines: Array = []
	for ri in track.routes.size():
		var pl := PackedVector2Array()
		for p: Vector3 in (track.routes[ri] as TrackRoute).baked:
			pl.append(Vector2(p.x, p.z))
		if ri == 0:
			pl.append(pl[0])
		lines.append(["soseaua" if ri == 0 else "scurtatura", pl, false])
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
			lines.append([String(p3.name), pl, true])
	var boxes: Array[Vector3] = []
	var corp := track.get_node_or_null(^"CaseSpateCorpuri")
	if corp != null:
		for c in corp.get_children():
			boxes.append((c as Node3D).global_transform.origin)
	var all_fp: Array[PackedVector2Array] = front.duplicate()
	all_fp.append_array(back)
	var worst := {"poke": -INF, "skirt": INF, "bury": -INF, "road": INF, "tram": INF, "floor": INF}
	var n_body := 0
	var n_near := 0
	for hi in xfs.size():
		var xf := xfs[hi]
		var floor_y := xf.origin.y - (1.0 if _sabotage else 0.0)
		var why: Array[String] = []
		# 1. linia fatadei
		var x := -3.5
		while x <= 3.501:
			var p := xf * Vector3(x, 0.0, -6.0)
			var g := _ground(p.x, p.z)
			if not is_nan(g):
				worst["poke"] = maxf(worst["poke"], g - floor_y)
				if g - floor_y > POKE_MAX:
					why.append("teren peste podea pe fatada %+.2f m" % (g - floor_y))
					break
			x += 0.5
		# 2 + 3. conturul VIZIBIL (fara alta amprenta lipita la 0,3 m in afara)
		var fp := back[hi]
		var cen := (fp[0] + fp[2]) * 0.5
		var skirt := INF
		var bury := -INF
		for e in 4:
			var a := fp[e]
			var b := fp[(e + 1) % 4]
			var nrm := Vector2(b.y - a.y, -(b.x - a.x)).normalized()
			if nrm.dot((a + b) * 0.5 - cen) < 0.0:
				nrm = -nrm
			var steps := int(ceil(a.distance_to(b) / 0.5))
			for k in steps + 1:
				var p := a.lerp(b, float(k) / float(steps))
				var po := p + nrm * 0.3
				var covered := false
				for q in all_fp.size():
					if all_fp[q] != fp and absf(all_fp[q][0].x - p.x) < 30.0 and absf(all_fp[q][0].y - p.y) < 30.0 \
							and _inside(po, all_fp[q], 0.0):
						covered = true
						break
				if covered:
					continue
				var g := _ground(p.x, p.y)
				if is_nan(g):
					continue
				skirt = minf(skirt, g - (floor_y - SKIRT))
				bury = maxf(bury, g - floor_y)
		worst["skirt"] = minf(worst["skirt"], skirt)
		worst["bury"] = maxf(worst["bury"], bury)
		if skirt < 0.0:
			why.append("fusta in aer %.2f m" % -skirt)
		if bury > BURY_MAX:
			why.append("ingropata %.2f m" % bury)
		# 4. benzile si cutia
		var d_road := INF
		var d_tram := INF
		for L: Array in lines:
			var d := _poly_line_dist(back_bay[hi], L[1])
			if bool(L[2]):
				d_tram = minf(d_tram, d)
			else:
				d_road = minf(d_road, d)
		worst["road"] = minf(worst["road"], d_road)
		worst["tram"] = minf(worst["tram"], d_tram)
		if d_road < ROAD_MIN - 0.05:
			why.append("banda la %.2f m (prag %.0f)" % [d_road, ROAD_MIN])
		if d_tram < TRAM_MIN - 0.05:
			why.append("tramvai la %.2f m (prag %.0f)" % [d_tram, TRAM_MIN])
		var has_box := false
		for bo in boxes:
			if Vector2(bo.x - xf.origin.x, bo.z - xf.origin.z).length() < 0.05:
				has_box = true
				break
		if has_box:
			n_body += 1
		if d_road < ROAD_FREE:
			n_near += 1
			if not has_box:
				why.append("la %.1f m de banda FARA cutie" % d_road)
		# 5. apa
		worst["floor"] = minf(worst["floor"], floor_y)
		if floor_y < WATER_Y:
			why.append("podeaua la %.2f (apa)" % floor_y)
		# suprapuneri (cu bovindoul) cu orice alta casa
		for q in all_fp.size():
			var other := all_fp[q]
			if other == fp or absf(other[0].x - fp[0].x) > 30.0 or absf(other[0].y - fp[0].y) > 30.0:
				continue
			var ov := false
			for p in back_bay[hi]:
				if _inside(p, other, OVERLAP_TOL):
					ov = true
			for p in other:
				if _inside(p, back_bay[hi], OVERLAP_TOL):
					ov = true
			if ov:
				why.append("se suprapune cu o casa %s" % ("din fata" if q < front.size() else "din spate"))
				break
		if not why.is_empty():
			_fails += 1
			if _fails <= 40:
				print("  PICA casa %d la (%.1f, %.1f, %.1f): %s" % [hi, xf.origin.x, xf.origin.y, xf.origin.z, "; ".join(why)])
	# 6. CityFill: ce a construit
	var st := fill.stats
	var mmis := 0
	var inst := 0
	var colored := 0
	var shadow_inst := 0
	for c in fill.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		mmis += 1
		inst += mmi.multimesh.instance_count
		if mmi.multimesh.use_colors:
			colored += 1
		if mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			shadow_inst += mmi.multimesh.instance_count
	print("CityFill: %s case, %s buffere, %d MultiMeshInstance3D (%d cu pastelul pe instanta), %d instante (%d in umbra), oglindite pe _m %s, pe dos %s, %s ms" % [
		str(st.get("houses")), str(st.get("batches")), mmis, colored, inst, shadow_inst,
		str(st.get("mirrored")), str(st.get("inside_out")), str(st.get("ms"))])
	if int(st.get("houses", 0)) != xfs.size() or int(st.get("batches", 0)) <= 0 or mmis == 0:
		print("  PICA: CityFill a construit altceva decat i s-a cerut")
		_fails += 1
	if int(st.get("inside_out", -1)) != 0 or int(st.get("mirrored", -1)) != neg:
		print("  PICA: case pe dos in MultiMesh (oglindite cerute %d, puse pe _m %s, pe dos %s)" % [
			neg, str(st.get("mirrored")), str(st.get("inside_out"))])
		_fails += 1
	print("teren-podea pe fatada max %+.2f m | rezerva fustei (contur vizibil) min %+.2f m | ingropare max %+.2f m" % [
		worst["poke"], worst["skirt"], worst["bury"]])
	print("banda min %.1f m | tramvai min %.1f m | podeaua min %.2f | la < %.0f m de banda: %d, cu cutie: %d (cutii %d)" % [
		worst["road"], worst["tram"], worst["floor"], ROAD_FREE, n_near, n_body, boxes.size()])
	print("VERDICT: %s%s" % ["PICA (%d case)" % _fails if _fails > 0 else "OK",
		" [sabotaj: podeaua -1 m]" if _sabotage else ""])
	return 1 if _fails > 0 else 0
