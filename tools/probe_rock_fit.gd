extends SceneTree
## Cat din silueta unei stanci NU e acoperita de coliziune.
##
## Simptomul care a cerut sonda: masina intra pana la jumatate intr-o stanca de
## pe marginea drumului si se opreste abia acolo. Doua cauze, iar sonda le
## separa, fiindca se repara diferit:
##   (a) stanca n-are nimic solid in ea — se trece prin ea ca prin aer;
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
## (Geometry3D.ray_intersects_triangle) si ce e solid acolo (intersect_ray prin
## serverul de fizica). Diferenta dintre punctele de intrare e exact cati metri
## intra botul masinii in piatra inainte sa fie oprit.
##
## DECORUL E COPT IN MULTIMESH (vezi TrackDecorBatch), deci sonda citeste si
## bufferele, nu doar nodurile: dupa coacere vizualul unei stanci nu mai e un
## [MeshInstance3D] cu numele variantei, ci o intrare intr-un
## [MultiMeshInstance3D] botezat `<Varianta>_<celula>`. Prima versiune se uita
## doar la noduri si, dupa ce coacerea a intrat pe main, gasea 0 stanci langa
## drum — trecea fara sa masoare nimic. O garda vacua e mai rea decat niciuna,
## fiindca arata verde.
##
## Din acelasi motiv corpul fizic nu se mai cauta ca stramos al nodului (nu mai
## exista nod): raza intreaba serverul de fizica ce e acolo, orice ar fi. Ceea
## ce e si masuratoarea corecta — jucatorul simte "cat intru in piatra pana ma
## opreste ceva", nu "care nod m-a oprit".
##
## Rulare:
##   godot --headless --fixed-fps 60 --path . --script res://tools/probe_rock_fit.gd
##   ... -- --track=1                 o singura pista
##   ... -- --track=1 --dump=Kit_M4   detaliul pe raze, pentru o varianta anume
##
## Cod de iesire 1 daca vreo stanca lasa in afara a ce e solid mai mult de
## REPORT_MIN metri din silueta ei.

## Banda de inaltime prin care trece caroseria, masurata de la baza stancii.
const CAR_LOW: float = 0.15
const CAR_HIGH: float = 1.30

## Sub atat nu raportam o gaura: e in marja formei, nu o problema de joc.
const REPORT_MIN: float = 0.35

## Cat de aproape de asfalt trebuie sa fie o gaura ca sa PICE garda.
##
## Se raporteaza toate, dar cade doar ce e pe linia de curse. Reziduul de azi e
## de 0.40-0.48 m pe cateva sectiuni de faleza aflate la 2.7-6 m de asfalt, si
## vine dintr-o decizie explicita: inclinarea de "asezat de mana" sta doar pe
## nodul vizual, fiindca un corp de coliziune inclinat deschide pene intre
## sectiuni vecine — exact felul de colt in care se intepeneste o masina (vezi
## nota din TrackCliffs). Adica e un compromis ales, nu o scapare, si nu e unul
## pe care il simte cineva la 4 m in afara drumului.
const GUARD_EDGE: float = 2.5

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
## Fetele unui mesh se citesc o singura data per resursa: cele 34 de variante se
## repeta de sute de ori pe pista, iar `get_faces()` copiaza toata geometria.
var _faces_cache: Dictionary = {}


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
	var pieces: Array[Dictionary] = []
	_collect_rocks(track, pieces)
	var half: float = track.half_width
	var near: Array[Dictionary] = []
	for piece in pieces:
		var info := _fit(piece, track, half)
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
		"path": path, "name": track.track_name,
		"rocks": pieces.size(), "near": near.size(),
		"no_body": no_body, "holed": holed, "bodied": bodied,
		"avg": sum_pen / float(maxi(bodied, 1)),
	}


func _fit(piece: Dictionary, track: Node, half: float) -> Dictionary:
	var tris := _triangles(piece)
	if tris.is_empty():
		return {}
	var base := 1e12
	for v in tris:
		base = minf(base, v.y)
	# Fiecare al treilea varf pentru silueta: forma nu se schimba, dar sonda
	# merge de trei ori mai repede pe sute de stanci.
	var band: Array[Vector3] = []
	for i in range(0, tris.size(), 3):
		var v := tris[i]
		if v.y >= base + CAR_LOW and v.y <= base + CAR_HIGH:
			band.append(v)
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
	# Incotro e soseaua fata de piesa: din directia asta vine masina.
	var road_dir := Vector3.FORWARD
	var best := 1e12
	for i in range(0, track.baked.size(), 2):
		var q: Vector3 = track.baked[i]
		var d := Vector2(q.x - center.x, q.z - center.z)
		if d.length() < best:
			best = d.length()
			road_dir = Vector3(d.x, 0.0, d.y).normalized()

	_dump = _dump_id != "" and String(piece["id"]) == _dump_id
	if _dump:
		print("  -- %s la %s" % [piece["id"], center])
	var res := _penetration(tris, center, span, piece.get("body"), road_dir)
	# O stanca despre care STIM ca n-are corp nu poate "avea gaura": ce a oprit
	# raza e vecina din spatele ei. Patrunderea ramane raportata (spune cat de
	# adanc intri in piatra pe care o vezi), dar la categoria corecta.
	if piece.get("body") is bool and not bool(piece["body"]):
		res[0] = false
	_dump = false
	return {
		"id": String(piece["id"]), "edge": nearest - half, "span": span,
		"has_body": bool(res[0]), "pen": float(res[1]),
	}


## Patrunderea, masurata pe ACEEASI raza pentru ambele suprafete.
## Intoarce [a_intalnit_ceva_solid, cea_mai_mare_patrundere].
##
## Se trag raze DOAR din emisfera dinspre sosea (+-60 grade fata de directia
## drumului). Prima versiune trimitea 24 de raze in cerc, ceea ce pe o faleza de
## 15 m lungime masura si razele care merg PARALEL cu peretele: ele intra in
## mesh la capatul sectiunii, unde colizorul se termina si el, si ieseau
## "patrunderi" de 15 m care nu inseamna nimic pentru un sofer. Masina vine
## dinspre asfalt; doar directia aia se poate simti.
const ROAD_ARC: float = 0.5 # cos(60 grade)

func _penetration(tris: PackedVector3Array, center: Vector3,
		span: float, body: Variant, road_dir: Vector3) -> Array:
	var space := root.world_3d.direct_space_state
	var worst := 0.0
	var touched := false
	var start := span + 3.0
	for i in RAYS:
		var a := TAU * float(i) / float(RAYS)
		var dir := Vector3(cos(a), 0.0, sin(a))
		if dir.dot(road_dir) < ROAD_ARC:
			continue
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
			if _dump:
				print("      dir %2d: mesh %.2f, NIMIC solid" % [i, d_vis])
			continue
		if body is StaticBody3D and hit["collider"] != body:
			# Alt obiect (teren, piesa vecina). Nu masoara piesa asta.
			continue
		var d_col: float = (Vector3(hit["position"]) - center).dot(dir)
		if d_col > d_vis + 0.05:
			# Ceva se interpune INAINTEA piesei. Nu o masoara pe ea.
			continue
		touched = true
		var gap := d_vis - d_col
		worst = maxf(worst, gap)
		if _dump and gap > 0.1:
			print("      dir %2d: mesh %.2f, colizor %.2f -> %.2f"
				% [i, d_vis, d_col, gap])
	return [touched, worst]


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


## Triunghiurile piesei in spatiul lumii.
func _triangles(piece: Dictionary) -> PackedVector3Array:
	var mesh: Mesh = piece["mesh"]
	if mesh == null:
		return PackedVector3Array()
	var key := mesh.get_rid()
	if not _faces_cache.has(key):
		_faces_cache[key] = mesh.get_faces()
	var src: PackedVector3Array = _faces_cache[key]
	var xf: Transform3D = piece["xform"]
	var out := PackedVector3Array()
	out.resize(src.size())
	for i in src.size():
		out[i] = xf * src[i]
	return out


## Toate stancile din cele doua biblioteci de canion, ca perechi (mesh,
## transformare in lume) — si cele ramase noduri, si cele coapte in buffer.
func _collect_rocks(node: Node, out: Array[Dictionary]) -> void:
	var nm := String(node.name)
	var mmi := node as MultiMeshInstance3D
	if mmi != null and mmi.multimesh != null and _is_rock(nm):
		var mm := mmi.multimesh
		var base := mmi.global_transform
		for i in mm.instance_count:
			out.append({"id": _variant(nm), "mesh": mm.mesh,
				"xform": base * mm.get_instance_transform(i)})
		return
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null and _is_rock(nm):
		# Trei stari, nu doua:
		#   StaticBody3D — corpul piesei, deci raza stie ce sa accepte;
		#   false        — stim ca piesa n-are corp (holderul e Node3D): fantoma;
		#   lipsa        — nu se POATE sti. Falezele isi tin coliziunea intr-un
		#                  corp comun pe latura (CliffBodyL/R), care e FRATE, nu
		#                  stramos; si scena coapta pierde oricum nodurile.
		var body := _body_of(mi)
		var piece := {"id": nm, "mesh": mi.mesh, "xform": mi.global_transform}
		if body != null:
			piece["body"] = body
		elif not nm.begins_with("Cliff_"):
			piece["body"] = false
		out.append(piece)
		return
	for c in node.get_children():
		_collect_rocks(c, out)


## Corpul fizic al piesei, daca mai exista ca nod. Cu el, raza stie sa distinga
## "stanca ASTA m-a oprit" de "m-a oprit vecina din spatele ei" — distinctia
## dintre un colizor prea mic si o stanca fantoma cu noroc.
func _body_of(node: Node) -> StaticBody3D:
	var cur: Node = node
	while cur != null:
		var body := cur as StaticBody3D
		if body != null:
			return body
		cur = cur.get_parent()
	return null


## Falezele intra si ele in masuratoare, si nu ca supliment: ele sunt peretele
## pe care il atingi cel mai des, si tot ele au avut cea mai mare gaura
## (proxy-ul `_col` era cu 1.35-1.60 m in spatele fetei vizibile).
func _is_rock(nm: String) -> bool:
	if nm.begins_with("Canyon_") or nm.begins_with("Kit_"):
		return true
	return nm.begins_with("Cliff_") and not nm.ends_with("_col")


## `Canyon_S1_0_-1` -> `Canyon_S1`: nodul copt poarta varianta plus celula.
func _variant(nm: String) -> String:
	var parts := nm.split("_")
	return "%s_%s" % [parts[0], parts[1]] if parts.size() >= 2 else nm


func _report() -> bool:
	print("\n=== potrivirea coliziunii pe stanci (banda %.2f-%.2f m) ==="
		% [CAR_LOW, CAR_HIGH])
	var bad := 0
	for row in _rows:
		print("\n%s (%s)" % [row["name"], String(row["path"]).get_file()])
		print("  %d stanci pe pista, %d cu silueta la <= %.0f m de asfalt"
			% [row["rocks"], row["near"], REACH])
		var nb: Array = row["no_body"]
		print("  fara nimic solid in ele: %d din %d" % [nb.size(), row["near"]])
		var buckets := [0, 0, 0, 0, 0, 0]
		for w in nb:
			buckets[clampi(int(floor(float(w["edge"]))), 0, 5)] += 1
		for b in 6:
			if buckets[b] > 0:
				print("    la %d-%d m de asfalt: %d" % [b, b + 1, buckets[b]])
		var hl: Array = row["holed"]
		print("  CU CEVA SOLID, dar gaura >= %.2f m: %d din %d (medie %.2f m)"
			% [REPORT_MIN, hl.size(), row["bodied"], row["avg"]])
		for w in hl.slice(0, 10):
			print("    %-10s patrunde %.2f m, la %+.2f m de asfalt"
				% [w["id"], w["pen"], w["edge"]])
		for w in hl:
			if float(w["edge"]) <= GUARD_EDGE:
				bad += 1
	if bad > 0:
		print("\nVERDICT: PROBLEMA — %d stanci cu silueta in afara colizorului."
			% bad)
	else:
		print("\nVERDICT: OK — nicio stanca solida nu lasa silueta pe dinafara.")
	_done = true
	quit(1 if bad > 0 else 0)
	return true
