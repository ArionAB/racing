extends SceneTree
## Cat din silueta unei stanci NU e acoperita de coliziunea ei.
##
## Simptomul care a cerut sonda: masina intra pana la jumatate intr-o stanca de
## pe marginea drumului si se opreste abia acolo. Doua cauze, iar sonda le
## separa, fiindca se repara diferit:
##   (a) stanca n-are corp fizic deloc — se trece prin ea ca prin aer;
##   (b) are, dar forma de coliziune e mai mica decat mesh-ul pe care il
##       reprezinta (un cilindru pe 40% din amprenta, cum era inainte).
##
## CUM SE MASOARA, si de ce asa. Prima versiune compara functia de SUPORT a
## siluetei (cat de departe ajunge mesh-ul pe o directie, oriunde lateral) cu
## punctul in care o raza intra in colizor. Cele doua nu sunt comparabile: pe o
## stanca alungita diagonal, suportul se atinge la metri distanta de dreapta pe
## care merge raza, si diferenta iesea "gaura" chiar cand coliziunea acoperea
## totul. Sonda raportase asa 0.60 m medie pe forme al caror hull cuprinde
## mesh-ul prin constructie — un rezultat imposibil, care a demascat metrica.
##
## Acum aceeasi raza taie AMBELE suprafete: triunghiurile mesh-ului
## (Geometry3D.ray_intersects_triangle) si colizorul (intersect_ray prin
## serverul de fizica). Diferenta dintre cele doua puncte de intrare e exact
## cati metri intra botul masinii in piatra inainte sa fie oprit.
##
## Rulare:
##   godot --headless --fixed-fps 60 --path . --script res://tools/probe_rock_fit.gd
##   ... -- --track=1              o singura pista
##   ... -- --track=1 --dump=Kit_M4  detaliul pe raze, pentru un model anume
##
## Cod de iesire 1 daca vreo stanca solida lasa in afara colizorului mai mult
## de REPORT_MIN metri din silueta ei.

## Banda de inaltime prin care trece caroseria, masurata de la baza stancii.
const CAR_LOW: float = 0.15
const CAR_HIGH: float = 1.30

## Sub atat nu raportam o gaura: e in marja formei, nu o problema de joc.
const REPORT_MIN: float = 0.35

## Cat de departe de MARGINEA asfaltului mai conteaza o stanca. Dincolo de asta
## masina ajunge rar, deci coliziunea ei e o discutie teoretica.
const REACH: float = 6.0

## Cate directii orizontale se testeaza per stanca, si la ce inaltime.
## 0.75 m e in dreptul barei de protectie.
const RAYS: int = 24
const RAY_HEIGHT: float = 0.75

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _rows: Array[Dictionary] = []
var _done: bool = false
var _dump: bool = false
var _dump_id: String = ""


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dump="):
			_dump_id = arg.trim_prefix("--dump=")
		elif arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 10):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)


func _process(_delta: float) -> bool:
	if _done:
		return true
	if _track == null:
		if _index >= _paths.size():
			return _report()
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	# Lasam rebuild() sa termine SI fizica sa se aseze: sonda interogheaza
	# serverul de fizica, iar formele intra in broadphase dupa primul pas.
	if _frames < 6:
		return false
	_rows.append(_measure(_paths[_index], _track))
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


func _measure(path: String, track: Node) -> Dictionary:
	var rocks: Array[Node3D] = []
	_collect_rocks(track, rocks)
	var half: float = track.half_width
	var near: Array[Dictionary] = []
	for rock in rocks:
		var info := _fit(rock, track, half)
		if not info.is_empty() and float(info["edge"]) <= REACH:
			near.append(info)
	near.sort_custom(func(a, b): return float(a["edge"]) < float(b["edge"]))

	var no_body: Array[Dictionary] = []
	var holed: Array[Dictionary] = []
	var sum_pen := 0.0
	var bodied := 0
	for info in near:
		if not info["has_body"]:
			no_body.append(info)
			continue
		bodied += 1
		sum_pen += float(info["pen"])
		if float(info["pen"]) >= REPORT_MIN:
			holed.append(info)
	holed.sort_custom(func(a, b): return float(a["pen"]) > float(b["pen"]))
	return {
		"path": path, "name": track.track_name, "half": half,
		"rocks": rocks.size(), "near": near.size(),
		"no_body": no_body, "holed": holed, "bodied": bodied,
		"avg": sum_pen / float(maxi(bodied, 1)),
	}


func _fit(rock: Node3D, track: Node, half: float) -> Dictionary:
	var pts := _silhouette(rock)
	if pts.is_empty():
		return {}
	var base := 1e12
	for p in pts:
		base = minf(base, p.y)
	var band: Array[Vector3] = []
	for p in pts:
		if p.y >= base + CAR_LOW and p.y <= base + CAR_HIGH:
			band.append(p)
	if band.is_empty():
		return {}

	# Cel mai apropiat punct din silueta fata de axul drumului. Minus half_width
	# = distanta pana la marginea asfaltului (negativ = intra peste asfalt).
	var nearest := 1e12
	var span := 0.0
	var center := Vector3.ZERO
	for p in band:
		center += p
	center /= float(band.size())
	center.y = base + RAY_HEIGHT
	for p in band:
		span = maxf(span, Vector2(p.x - center.x, p.z - center.z).length())
		for i in range(0, track.baked.size(), 2):
			var d := Vector2(track.baked[i].x - p.x, track.baked[i].z - p.z)
			nearest = minf(nearest, d.length())

	var body := _body_of(rock)
	var out := {
		"id": String(rock.name), "edge": nearest - half, "span": span,
		"has_body": body != null, "pen": 0.0, "shape": "-",
	}
	if body == null:
		return out
	out["shape"] = _shape_name(body)
	_dump = _dump_id != "" and String(rock.name) == _dump_id
	if _dump:
		print("  -- %s la %s" % [rock.name, center])
	out["pen"] = _penetration(body, _triangles(rock), center, span)
	_dump = false
	return out


## Patrunderea, masurata pe ACEEASI raza pentru ambele suprafete.
func _penetration(body: StaticBody3D, tris: PackedVector3Array,
		center: Vector3, span: float) -> float:
	var space := root.world_3d.direct_space_state
	var worst := 0.0
	var start := span + 3.0
	for i in RAYS:
		var a := TAU * float(i) / float(RAYS)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var from := center + dir * start
		var to := center - dir * 0.5
		var vis = _ray_mesh(tris, from, to)
		if vis == null:
			continue # raza nu atinge stanca pe directia asta
		var d_vis: float = (Vector3(vis) - center).dot(dir)
		var params := PhysicsRayQueryParameters3D.create(from, to)
		params.collide_with_areas = false
		var hit := space.intersect_ray(params)
		if hit.is_empty():
			# Niciun colizor pe directia asta: se trece prin toata stanca.
			worst = maxf(worst, d_vis * 2.0)
			if _dump:
				print("      dir %2d: mesh %.2f, NICIUN colizor" % [i, d_vis])
			continue
		if hit["collider"] != body:
			# Alt obiect (teren, stanca vecina) taie raza mai devreme. Nu masoara
			# aceasta stanca, deci directia nu se numara.
			continue
		var d_col: float = (Vector3(hit["position"]) - center).dot(dir)
		var gap := d_vis - d_col
		worst = maxf(worst, gap)
		if _dump and gap > 0.1:
			print("      dir %2d: mesh %.2f, colizor %.2f -> %.2f"
				% [i, d_vis, d_col, gap])
	return worst


## Cel mai apropiat punct in care segmentul from->to intra in triunghiurile
## date. `null` daca nu atinge niciunul.
func _ray_mesh(tris: PackedVector3Array, from: Vector3, to: Vector3) -> Variant:
	var dir := to - from
	if dir.length() < 0.0001:
		return null
	var best := 1e12
	var out: Variant = null
	var i := 0
	while i + 2 < tris.size():
		var hit = Geometry3D.ray_intersects_triangle(from, dir,
			tris[i], tris[i + 1], tris[i + 2])
		if hit != null:
			var d := (Vector3(hit) - from).length_squared()
			if d < best:
				best = d
				out = hit
		i += 3
	return out


func _shape_name(body: StaticBody3D) -> String:
	var names: Array[String] = []
	for child in body.get_children():
		var cs := child as CollisionShape3D
		if cs != null and cs.shape != null:
			names.append(cs.shape.get_class().replace("Shape3D", ""))
	return "-" if names.is_empty() else "+".join(names)


## Triunghiurile mesh-urilor stancii, in spatiul lumii.
func _triangles(rock: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var stack: Array[Node] = [rock]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			var xf := mi.global_transform
			for v in mi.mesh.get_faces():
				out.append(xf * v)
		for c in node.get_children():
			stack.append(c)
	return out


## Varfurile mesh-urilor stancii, in spatiul lumii. Fiecare al treilea: silueta
## nu se schimba, dar sonda merge de trei ori mai repede pe 400 de stanci.
func _silhouette(rock: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var stack: Array[Node] = [rock]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			var xf := mi.global_transform
			var faces := mi.mesh.get_faces()
			for i in range(0, faces.size(), 3):
				out.append(xf * faces[i])
		for c in node.get_children():
			stack.append(c)
	return out


func _body_of(node: Node) -> StaticBody3D:
	var cur := node
	while cur != null:
		var body := cur as StaticBody3D
		if body != null:
			return body
		cur = cur.get_parent()
	return null


func _collect_rocks(node: Node, out: Array[Node3D]) -> void:
	var n3 := node as Node3D
	if n3 != null and (String(node.name).begins_with("Canyon_")
			or String(node.name).begins_with("Kit_")):
		out.append(n3)
		return
	for c in node.get_children():
		_collect_rocks(c, out)


func _report() -> bool:
	print("\n=== potrivirea coliziunii pe stanci (banda %.2f-%.2f m) ==="
		% [CAR_LOW, CAR_HIGH])
	var bad := 0
	for row in _rows:
		print("\n%s (%s), half_width %.1f m"
			% [row["name"], String(row["path"]).get_file(), row["half"]])
		print("  %d stanci pe pista, %d cu silueta la <= %.0f m de asfalt"
			% [row["rocks"], row["near"], REACH])
		var nb: Array = row["no_body"]
		print("  fara corp fizic: %d din %d" % [nb.size(), row["near"]])
		var buckets := [0, 0, 0, 0, 0, 0]
		for w in nb:
			buckets[clampi(int(floor(float(w["edge"]))), 0, 5)] += 1
		for b in 6:
			if buckets[b] > 0:
				print("    la %d-%d m de asfalt: %d" % [b, b + 1, buckets[b]])
		var hl: Array = row["holed"]
		print("  CU CORP, dar gaura >= %.2f m: %d din %d (medie %.2f m)"
			% [REPORT_MIN, hl.size(), row["bodied"], row["avg"]])
		for w in hl.slice(0, 10):
			print("    %-10s patrunde %.2f m, la %+.2f m de asfalt  [%s]"
				% [w["id"], w["pen"], w["edge"], w["shape"]])
		bad += hl.size()
	if bad > 0:
		print("\nVERDICT: PROBLEMA — %d stanci cu silueta in afara colizorului."
			% bad)
	else:
		print("\nVERDICT: OK — nicio stanca solida nu lasa silueta pe dinafara.")
	_done = true
	quit(1 if bad > 0 else 0)
	return true
