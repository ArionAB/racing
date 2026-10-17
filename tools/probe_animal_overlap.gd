extends Node
## Garda #501: animale (figuranti statici din DecorManual + turma de fundal
## HerdBackdrop) asezate IN copaci si stanci, sau COCOTATE pe ele.
##
## Trei defecte, trei teste, pe fiecare animal:
##   1. SUPRAPUNERE — pe amprenta animalului (cutia modelului, stransa la 70%
##      ca sa nu numere atingerile) sta un corp de decor: trunchi, stanca,
##      termitiera, cort, alt figurant.
##   2. COCOTAT — originea sta peste TERENUL real cu mai mult de MAX_PERCH
##      (doar animalele de uscat): raza turmei de fundal lua cota din primul
##      corp lovit, deci un gnu ar fi cazut pe varful unui trunchi sau bolovan.
##   3. INGROPAT — terenul real e deasupra originii cu mai mult de MAX_PERCH.
##
## Decorul fara coliziune ("none": iarba, tufe) nu se numara — prin el se
## trece, si un animal in iarba e chiar locul lui.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAnimalOverlap.tscn -- --track=7
##
## Cu `--fix`, pentru fiecare figurant DecorManual vinovat cauta cea mai
## apropiata pozitie libera (inele de 1 m, pana la 40 m; nu pe sosea) si
## tipareste linii `MOVE <parinte>/<nume> x y z` pentru patch-ul .tscn.

const MAX_PERCH := 0.5
const SHRINK := 0.7
## Animalele de APA (crocodilul, hipopotamul, flamingii) stau la cota apei,
## peste albie: pentru ele „cocotat" e locul lor, conteaza doar suprapunerea
## si ingroparea.
const WATER_STEMS := ["crocodile", "hippo_back", "flamingo"]
const ANIMAL_STEMS := ["cow", "zebu_cow", "wildebeest", "zebra", "elephant",
	"crocodile", "hippo_back", "giraffe", "lion", "flamingo"]

var _track: Track
var _space: PhysicsDirectSpaceState3D


func _ready() -> void:
	var wanted := 7
	var fix := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			wanted = int(arg.trim_prefix("--track="))
		elif arg == "--fix":
			fix = true
	var idx := GameState.resolve_track_index(wanted)
	if idx < 0:
		push_error("ProbeAnimalOverlap: pista invalida %d" % wanted)
		get_tree().quit(2)
		return
	_track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(_track)
	# Turma de fundal se construieste in primul pas de fizica, WorldProp-urile
	# isi fac corpurile dupa apeluri amanate.
	for i in 12:
		await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--column="):
			# Toate suprafetele de pe verticala unui punct (depanare).
			var xz := arg.trim_prefix("--column=").split(",")
			var from := Vector3(float(xz[0]), 200.0, float(xz[1]))
			var exclude: Array[RID] = []
			for i in 16:
				var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 400.0)
				q.exclude = exclude
				var hit := _space.intersect_ray(q)
				if hit.is_empty():
					break
				print("  column %s: y=%.2f %s (parinte %s)" % [arg, (hit.position as Vector3).y,
					(hit.collider as Node).name, (hit.collider as Node).get_parent().name])
				exclude.append(hit.rid as RID)
	var animals: Array[Dictionary] = []
	var dm := _track.get_node_or_null(^"DecorManual")
	if dm != null:
		for n in dm.find_children("*", "Node3D", true, false):
			var stem := String((n as Node3D).scene_file_path).get_file().get_basename()
			if stem in ANIMAL_STEMS:
				animals.append({"node": n, "kind": stem, "xf": (n as Node3D).global_transform,
					"aabb": _local_aabb(n as Node3D), "own": String(n.name) + "_col"})
	var herd_n := 0
	for hb in _track.find_children("*", "Node3D", true, false):
		if not hb is HerdBackdrop:
			continue
		# Transformurile vin de la nod, nu din MultiMesh: in headless
		# `get_instance_transform` intoarce zero si sonda ar fi masurat 856 de
		# animale in origine (asa a si facut, la prima rulare).
		var mesh := HerdHazard._animal_mesh_from(HerdHazard.WILDEBEEST_GLB)
		var aabb := mesh.get_aabb() if mesh != null else AABB(Vector3(-0.4, 0, -1.2), Vector3(0.8, 1.4, 2.4))
		for xf: Transform3D in (hb as HerdBackdrop).placed_transforms:
			animals.append({"node": hb, "kind": "fundal/" + String(hb.name), "xf": xf,
				"aabb": aabb, "own": ""})
			herd_n += 1
	var at_origin := 0
	for a in animals:
		if (a["xf"] as Transform3D).origin.length() < 0.001:
			at_origin += 1
	if at_origin > 0:
		print("PICAT: %d animale in (0,0,0) — masuratoare moarta, nu asezare" % at_origin)
		get_tree().quit(1)
		return
	print("=== PROBE ANIMAL OVERLAP — %s: %d animale (%d din turma de fundal) ===" % [
		GameState.track_label(idx), animals.size(), herd_n])
	if animals.is_empty():
		print("PICAT: niciun animal — sonda n-a masurat nimic")
		get_tree().quit(1)
		return

	var bad: Array[Dictionary] = []
	var by_kind: Dictionary = {}
	for a in animals:
		var hits := _overlaps(a["xf"], a["aabb"], a["own"], false)
		var perch := _perch(a["xf"])
		var water := String(a["kind"]) in WATER_STEMS
		# Ingropat: generatorul zonei E a asezat elefantii pe `sampler.ground_y`,
		# care extrapoleaza cota campiei pe versant (memoria
		# `terrain-mesh-y-extrapoleaza`) — trei au iesit la 30 m SUB deal.
		var buried := perch < -MAX_PERCH
		var perched := perch > MAX_PERCH and not water
		if hits.is_empty() and not buried and not perched:
			continue
		a["hits"] = hits
		a["perch"] = perch
		bad.append(a)
		by_kind[a["kind"]] = int(by_kind.get(a["kind"], 0)) + 1
	for a in bad.slice(0, 60):
		var where := "DecorManual" if a["own"] != "" else "fundal"
		var n := a["node"] as Node
		print("  %-34s %-10s la %s  peste teren %+.2f m  in: %s" % [
			(String(n.get_parent().name) + "/" + String(n.name)) if where == "DecorManual" else String(a["kind"]),
			where, (a["xf"] as Transform3D).origin.snapped(Vector3.ONE * 0.01),
			float(a["perch"]), ", ".join(a["hits"])])
	for k in by_kind:
		print("  total %-40s %d" % [k, by_kind[k]])

	if fix:
		_fix(bad, animals)

	print("VERDICT: %s (%d animale in/pe decor din %d)" % [
		"TRECUT" if bad.is_empty() else "PICAT", bad.size(), animals.size()])
	get_tree().quit(0 if bad.is_empty() else 1)


## Cutia modelului in spatiul LUI (fara transformul radacinii).
func _local_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf := n.global_transform.affine_inverse() * m.global_transform
		var b := xf * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Numele corpurilor de decor care se suprapun cu amprenta animalului.
func _overlaps(xf: Transform3D, aabb: AABB, own: String, road_blocks: bool) -> Array[String]:
	var out: Array[String] = []
	var scl := xf.basis.get_scale()
	var shape := BoxShape3D.new()
	shape.size = Vector3(aabb.size.x * scl.x, aabb.size.y * scl.y, aabb.size.z * scl.z) * SHRINK
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	var c := xf * aabb.get_center()
	q.transform = Transform3D(xf.basis.orthonormalized(), c)
	for r in _space.intersect_shape(q, 32):
		var body := r["collider"] as Node
		if not body is StaticBody3D:
			continue
		var nm := String(body.name)
		if nm.begins_with("TerrainBody") or nm == own:
			continue
		if body.get_parent() is Track:
			if road_blocks and not nm.begins_with("TerrainBody"):
				out.append(nm)
			continue # sosea, fusta, podeaua: nu e decor
		out.append(nm.trim_suffix("_col"))
	return out


## Cat sta originea peste terenul REAL (TerrainBody).
func _perch(xf: Transform3D) -> float:
	var g := _terrain_y(xf.origin)
	return 0.0 if is_nan(g) else xf.origin.y - g


func _terrain_y(at: Vector3) -> float:
	var from := Vector3(at.x, at.y + 60.0, at.z)
	var exclude: Array[RID] = []
	for i in 12:
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 200.0)
		q.exclude = exclude
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		if String((hit.collider as Node).name).begins_with("TerrainBody"):
			return (hit.position as Vector3).y
		exclude.append(hit.rid as RID)
	return NAN


## Raza orizontala a animalului: jumatate din cea mai mare latura a cutiei.
func _radius(a: Dictionary) -> float:
	var aabb := a["aabb"] as AABB
	var scl := (a["xf"] as Transform3D).basis.get_scale()
	return 0.5 * maxf(aabb.size.x * scl.x, aabb.size.z * scl.z)


## Cea mai apropiata pozitie libera pentru figurantii DecorManual vinovati:
## inele de 1 m in jurul pozitiei vechi (pana la 40), 16 directii; libera = pe teren real,
## fara decor si fara sosea sub amprenta, la cel putin 1,5 m de alt animal.
func _fix(bad: Array[Dictionary], animals: Array[Dictionary]) -> void:
	# Distanta fata de celelalte animale tine cont de MARIME: un elefant la
	# scara 1,7 are ~10 m lungime, deci doi la 1,5 m unul de altul se
	# intrepatrund (prima varianta a fixului facea exact asta).
	var taken: Array[Vector3] = []
	var taken_r: Array[float] = []
	for a in animals:
		taken.append((a["xf"] as Transform3D).origin)
		taken_r.append(_radius(a))
	for a in bad:
		if a["own"] == "":
			continue
		var n := a["node"] as Node3D
		var xf := a["xf"] as Transform3D
		# Acelasi MEDIU ca intentia: animalul de apa ramane la cota lui, cu
		# albia dedesubt; cel de uscat calca pe teren, la cel mult 1,5 m de cota
		# la care l-a pus generatorul (elefantii ingropati erau pe crusta lacului,
		# nu pe coama de deasupra lor).
		var in_water := String(a["kind"]) in WATER_STEMS and float(a["perch"]) > MAX_PERCH
		var done := false
		for ring in range(1, 41):
			for k in 16:
				var ang := TAU * float(k) / 16.0
				var p := xf.origin + Vector3(cos(ang), 0.0, sin(ang)) * float(ring)
				var g := _terrain_y(p)
				if is_nan(g):
					continue
				if in_water:
					if g > xf.origin.y - 0.3:
						continue # mal uscat, nu albie
				elif absf(g - xf.origin.y) > 1.5:
					continue
				else:
					p.y = g
				var cand := Transform3D(xf.basis, p)
				if not _overlaps(cand, a["aabb"], a["own"], true).is_empty():
					continue
				var crowded := false
				var r_me := _radius(a)
				for j in taken.size():
					var o := taken[j]
					if o.distance_to(xf.origin) < 0.01:
						continue # el insusi, la pozitia veche
					var o2 := Vector2(o.x, o.z)
					if o2.distance_to(Vector2(p.x, p.z)) < 0.8 * (r_me + taken_r[j]):
						crowded = true
						break
				if crowded:
					continue
				# Coordonatele din .tscn sunt ale PARINTELUI (zona POI-ului).
				var lp := n.get_parent_node_3d().global_transform.affine_inverse() * p
				print("MOVE %s/%s %.4f %.4f %.4f   (%.0f m)" % [
					String(_track.get_path_to(n.get_parent())), n.name, lp.x, lp.y, lp.z, float(ring)])
				taken.append(p)
				taken_r.append(r_me)
				done = true
				break
			if done:
				break
		if not done:
			print("NOMOVE %s/%s — niciun loc liber in 40 m" % [
				String(_track.get_path_to(n.get_parent())), n.name])
