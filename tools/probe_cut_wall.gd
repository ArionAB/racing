extends Node
## TAIETURILE (`cut_wall`) au corp solid? Plimba gabaritul masinii de pe axa
## soselei spre perete si cere fizicii unde se opreste.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCutWall.tscn
##   ... -- --track=14            (numarul scenei: 13 Cappadocia, 14 Serengeti,
##                                 15 Machu Picchu, 16 Fiordland)
##   ... -- --thick=0             (starea de DINAINTE de fix: panza fara corp)
##   ... -- --sabotaj             (scoate corpurile si cere sa pice)
##
## Pentru fiecare nod CliffFace cu `cut_wall`, din 3 m in 3 m pe interiorul
## fractiilor lui (fara stingerea de capat), cutia masinii (2.2 x 1.4 x 4.2 m)
## porneste de pe ax si se impinge spre perete in pasi de 0.2 m, pana la
## `thick/2` dincolo de fata. Doua contracte:
##   (a) EXISTA contact cu corpul taieturii (`TaieturaCorp`) — adica nu se poate
##       trece prin perete;
##   (b) contactul se produce cu marginea cutiei la cel putin LANE_MARGIN METRI
##       dinspre ax fata de marginea asfaltului: corpul n-a intrat pe banda.
## Coloanele pe care taietura chiar nu exista (rise < 2 m) se sar.
## Cod de iesire 1 daca (a) sau (b) pica oriunde.

const CAR := Vector3(2.2, 1.4, 4.2)
const STEP_M: float = 0.2
const LANE_MARGIN: float = -0.3

var _track_no: int = 14
var _thick: float = -1.0
var _sabotage: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_no = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--thick="):
			_thick = float(arg.trim_prefix("--thick="))
		elif arg == "--sabotaj":
			_sabotage = true
	var path := "res://scenes/tracks/Track%02d.tscn" % _track_no
	var track := (load(path) as PackedScene).instantiate() as Track
	if _thick >= 0.0:
		for f in track.find_children("*", "CliffFace", true, false):
			(f as CliffFace).cut_thick_m = _thick
	add_child(track)
	for i in 6:
		await get_tree().physics_frame
	if _sabotage:
		for b in track.find_children("TaieturaCorp", "StaticBody3D", true, false):
			b.free()
		await get_tree().physics_frame
		await get_tree().physics_frame
	var bad := 0
	var total := 0
	var space := get_tree().root.world_3d.direct_space_state
	var route := track.route_at(0)
	var n := route.count()
	print("=== %s, cut_thick %s%s ===" % [path.get_file(),
		"scena" if _thick < 0.0 else str(_thick), " SABOTAJ" if _sabotage else ""])
	var step_i := maxi(int(round(5.0 / maxf(route.length() / float(n), 0.1))), 1)
	for node in track.find_children("*", "CliffFace", true, false):
		var cf := node as CliffFace
		if not cf.cut_wall:
			continue
		var wm := _wall_mesh(track, cf) as MeshInstance3D
		if wm == null:
			print("  %-22s NICIUN mesh de taietura" % cf.name)
			continue
		var vs: PackedVector3Array = (wm.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var gt := wm.global_transform
		var wv := PackedVector3Array()
		for k in range(0, vs.size(), 9):
			wv.append(gt * vs[k])
		var tmesh := wm.mesh.generate_triangle_mesh()
		var box_area := (gt * wm.get_aabb()).grow(24.0)
		var tested := 0
		var misses := 0
		var intrude := 0
		var min_clear := 1e9
		var first_miss := Vector3.ZERO
		var i := 0
		while i < n:
			var p: Vector3 = track.point_at(i)
			i += step_i
			if not box_area.has_point(p):
				continue
			# Cel mai apropiat varf de perete, ORIZONTAL, ca sa dea directia.
			var best := 22.0
			var bv := Vector3.ZERO
			for v in wv:
				if absf(v.y - (p.y + 1.0)) > 6.0:
					continue
				var d := Vector2(v.x - p.x, v.z - p.z).length()
				if d < best:
					best = d
					bv = v
			if bv == Vector3.ZERO:
				continue
			var to := Vector3(bv.x - p.x, 0.0, bv.z - p.z).normalized()
			# ADEVARUL e panza VIZUALA: o raza orizontala la cota masinii spre
			# perete. Daca nu atinge panza, aici nu e nimic de testat (peretele
			# trece pe deasupra sau pe dedesubt); daca o atinge, cutia TREBUIE
			# sa fie oprita de corp cel tarziu acolo.
			var lp := gt.affine_inverse() * (p + Vector3.UP * 1.0)
			var lq := gt.affine_inverse() * (p + Vector3.UP * 1.0 + to * 30.0)
			var vis: Dictionary = tmesh.intersect_segment(lp, lq)
			if vis.is_empty():
				continue
			var face_d: float = ((gt * (vis["position"] as Vector3)) - (p + Vector3.UP)).length()
			var fwd := track.point_at((i + 2) % n) - p
			fwd.y = 0.0
			if fwd.length() < 0.01:
				continue
			var basis := Basis.looking_at(fwd.normalized(), Vector3.UP)
			var q := PhysicsShapeQueryParameters3D.new()
			var box := BoxShape3D.new()
			box.size = CAR
			q.shape = box
			var reach := -1.0
			var s := 0.0
			while s <= face_d + 1.5:
				q.transform = Transform3D(basis, p + Vector3.UP * 1.0 + to * s)
				var hit := false
				for h in space.intersect_shape(q, 16):
					var c := h["collider"] as Node
					if c != null and c.name == "TaieturaCorp":
						hit = true
						break
				if hit:
					reach = s
					break
				s += STEP_M
			tested += 1
			# trece prin: nicio atingere, sau cutia a ajuns cu CENTRUL la fata
			if reach < 0.0 or reach > face_d - 0.2:
				misses += 1
				if first_miss == Vector3.ZERO:
					first_miss = p
				continue
			# `best` e distanta pana la fata; cutia (semilatime 1.1) o atinge
			# la ~best - 1.1. Banda: marginea cutiei nu trebuie sa fie mai
			# aproape de ax decat marginea asfaltului minus LANE_MARGIN.
			var hw: float = track.width_at_index(i)
			var clear := (reach + CAR.x * 0.5) - hw
			min_clear = minf(min_clear, clear)
			if clear < LANE_MARGIN:
				intrude += 1
		total += tested
		var fail := intrude > 0 or misses > 0
		if fail:
			bad += 1
		print("  %-22s frac %.3f-%.3f  esantioane %3d  trece prin %3d  pe banda %2d  joc minim %s m  %s"
			% [cf.name, cf.frac_start, cf.frac_end, tested, misses, intrude,
			"-" if min_clear > 1e8 else "%+.2f" % min_clear,
			"PICA" if fail else "ok"]
			+ ("" if misses == 0 else "  (primul la %s)" % first_miss))
	print("VERDICT %s: %d noduri cu probleme din %d esantioane"
		% ["PICA" if bad > 0 else "OK", bad, total])
	get_tree().quit(1 if bad > 0 else 0)


func _wall_mesh(track: Node, cf: CliffFace) -> Node:
	return track.find_child("Taietura " + cf.name, true, false)
