extends Node
## Sonda traseului San Francisco (Track25, brief san_francisco.md §2 „Scurtatura", §7 pasul 2):
## contractul de TEREN de la virajele scurtaturii, cu RAZE VERTICALE, nu cu ochiul.
##
##   godot --headless --path . res://tools/ProbeSfRoute.tscn
##   ... -- --scene=res://scenes/tracks/Track25.tscn   (implicit)
##   ... -- --all        si pe partile drepte / exterioare (informativ)
##   ... -- --sabotaj    scoate acostamentul (`SerpentineGri/SerpAcostament`) inainte de masura:
##                       garda TREBUIE sa pice (terenul singur sta la drum - 0,55 m)
##
## Contractul (memoria `treapta-teren-interior-viraj-ramura`): la 0,5 m dincolo de marginea
## INTERIOARA a fiecarui viraj al benzii (raza de curbura < 40 m, interiorul = partea centrului
## de curbura), primul corp lovit de o raza verticala sta la >= cota drumului - 0,3 m. Sub atat,
## marginea benzii e un zid pentru suspensie la revenire (> 0,3 m), iar AI-ul care taie virajul e
## ejectat — 19 din 23 de repuneri ale sondei 1b. Raza porneste de la drum + 3 m si coboara 8 m;
## pe portiunea in care banda e lipita de bucla (< latimea buclei + 3 m de axa ei) proba se sare:
## acolo e soseaua principala, nu terenul.
##
## Tipareste si cota apei (media soselei + `sea_level_offset`, tinta 0) si cota terenului sub
## fiecare muchie a lantului (informativ). Exit 1 daca un punct pica sau daca n-a masurat nimic.

const BEYOND: float = 0.5
const MAX_DROP: float = 0.3
const TURN_R: float = 40.0
const ARM: int = 6

var _all := false
var _sabotage := false
## `--grid=x0,z0,x1,z1`: harta cotelor (primul corp lovit de sus) pe o grila de 1 m, cu numele
## corpului — pentru o repunere care se repeta intr-un punct fix.
var _grid := Vector4.ZERO
## `--dump-branch=res://tools/data/sf_route_branch.tsv`: scrie banda COAPTA (x y z) pentru
## generator (cota acostamentului se ia de pe planul real al benzii, nu de pe cel analitic).
var _dump_branch := ""


func _ready() -> void:
	await get_tree().process_frame
	var path := "res://scenes/tracks/Track25.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			path = arg.trim_prefix("--scene=")
		elif arg == "--all":
			_all = true
		elif arg == "--sabotaj":
			_sabotage = true
		elif arg.begins_with("--dump-branch="):
			_dump_branch = arg.trim_prefix("--dump-branch=")
		elif arg.begins_with("--grid="):
			var g := arg.trim_prefix("--grid=").split(",")
			_grid = Vector4(float(g[0]), float(g[1]), float(g[2]), float(g[3]))
	var track := (load(path) as PackedScene).instantiate() as Track
	if _sabotage:
		var slab := track.get_node_or_null("SerpentineGri/SerpAcostament")
		if slab != null:
			slab.get_parent().remove_child(slab)
			slab.free()
			print("--sabotaj: acostamentul scos")
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	var sampler: Variant = track.get("_sampler")
	var mean_y: float = sampler.mean_road_y() if sampler != null else NAN
	print("=== %s (%s) ===" % [track.track_name, path.get_file()])
	print("apa: media soselei %.2f + sea_level_offset %.3f = %.2f (tinta 0)" % [
		mean_y, track.sea_level_offset, mean_y + track.sea_level_offset])
	if track.routes.size() < 2:
		print("FARA scurtatura")
		get_tree().quit(1)
		return
	var main: TrackRoute = track.routes[0]
	var b: TrackRoute = track.routes[1]
	if not _dump_branch.is_empty():
		var f := FileAccess.open(_dump_branch, FileAccess.WRITE)
		for q: Vector3 in b.baked:
			f.store_line("%.3f %.3f %.3f" % [q.x, q.y, q.z])
		f.close()
		print("%s: %d puncte ale benzii coapte" % [_dump_branch, b.baked.size()])
	if _grid != Vector4.ZERO:
		for zz in range(int(_grid.y), int(_grid.w) + 1):
			var row := "z %4d:" % zz
			for xx in range(int(_grid.x), int(_grid.z) + 1):
				var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(
					Vector3(xx, 80.0, zz), Vector3(xx, -20.0, zz)))
				if h.is_empty():
					row += "   ----"
				else:
					var nm := String((h["collider"] as Node).name) if h["collider"] is Node else "?"
					row += " %5.2f%s" % [(h["position"] as Vector3).y, nm.substr(0, 1) if nm != "RoadTop" else "r"]
			print(row)
	var hw := b.half_width
	var n := b.baked.size()
	var tested := 0
	var bad := 0
	var worst := INF
	var worst_at := Vector3.ZERO
	var worst_name := ""
	var hist := {}
	var info_min := INF
	for i in range(ARM, n - ARM):
		var a: Vector3 = b.baked[i - ARM]
		var p: Vector3 = b.baked[i]
		var c: Vector3 = b.baked[i + ARM]
		var t1 := Vector2(p.x - a.x, p.z - a.z)
		var t2 := Vector2(c.x - p.x, c.z - p.z)
		var cross := t1.x * t2.y - t1.y * t2.x
		var rad := _circ(a, p, c)
		var d := Vector3(c.x - a.x, 0.0, c.z - a.z).normalized()
		var right := d.cross(Vector3.UP).normalized()
		# cross > 0 in (x, z) = viraj spre +z fata de directie... interiorul se ia geometric:
		# partea pe care sta centrul cercului prin cele trei puncte.
		var mid := (a + c) * 0.5
		var inner_sign := 1.0 if right.dot(Vector3(p.x - mid.x, 0.0, p.z - mid.z)) < 0.0 else -1.0
		for side: float in [inner_sign, -inner_sign]:
			var is_turn_inner := side == inner_sign and rad < TURN_R and absf(cross) > 1e-4
			if not is_turn_inner and not _all:
				continue
			var q := p + right * side * (hw + BEYOND)
			var ci := main.closest_index_global(q)
			if main.lateral_distance(ci, q) < track.width_at_index(ci) + 3.0:
				continue
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 3.0, q.z), Vector3(q.x, p.y - 5.0, q.z)))
			var dy := -8.0
			var nm := "(nimic pana la -5 m)"
			if not hit.is_empty():
				dy = (hit["position"] as Vector3).y - p.y
				var col: Object = hit["collider"]
				nm = String((col as Node).name) if col is Node else str(col)
			if not is_turn_inner:
				info_min = minf(info_min, dy)
				continue
			tested += 1
			var key := nm
			hist[key] = int(hist.get(key, 0)) + 1
			if dy < worst:
				worst = dy
				worst_at = q
				worst_name = nm
			if dy < -MAX_DROP:
				bad += 1
				if bad <= 20:
					print("  PICA  frac %.3f  R %5.1f  teren %+.2f m fata de drum  (%s)  la (%.1f, %.1f, %.1f)" % [
						b.frac_at(i), rad, dy, nm, q.x, q.y, q.z])
	print("interiorul virajelor benzii: %d probe la %.1f m dincolo de margine; cel mai jos %+.2f m (%s, la %.0f, %.0f)" % [
		tested, BEYOND, worst, worst_name, worst_at.x, worst_at.z])
	print("  corpuri lovite: %s" % str(hist))
	if _all:
		print("  (informativ) restul marginilor: cel mai jos %+.2f m" % info_min)
	# Lantul: muchiile si cota terenului la 1 m dincolo de margine, pe ambele parti.
	if track.has_meta("sf_lips"):
		for L: Vector3 in track.get_meta("sf_lips"):
			var li := main.closest_index_global(L)
			print("  muchia la frac %.4f (%.1f, %.1f, %.1f)" % [main.frac_at(li), L.x, L.y, L.z])
	var ok := tested > 0 and bad == 0
	print("VERDICT: %s — %d / %d probe sub drum - %.1f m" % ["OK" if ok else "PICA", bad, tested, MAX_DROP])
	get_tree().quit(0 if ok else 1)


static func _circ(a: Vector3, b: Vector3, c: Vector3) -> float:
	var p := Vector2(a.x, a.z)
	var q := Vector2(b.x, b.z)
	var s := Vector2(c.x, c.z)
	var area2 := absf((q.x - p.x) * (s.y - p.y) - (s.x - p.x) * (q.y - p.y))
	if area2 < 1e-6:
		return INF
	return p.distance_to(q) * q.distance_to(s) * s.distance_to(p) / (2.0 * area2)
