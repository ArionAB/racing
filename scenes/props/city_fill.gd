extends Node3D
class_name CityFill
## UMPLUTURA DE ORAS: sute de case asezate pe terenul din INTERIORUL buclei,
## desenate ca MultiMesh feliat pe celule (Jodhpur, Track17 — orasul albastru
## pe care il vezi de pe bastion, brief §2.0/§5.6 „casele din spate, dincolo de
## 40 m de drum, sunt MultiMesh feliat pe zone").
##
## De ce nu noduri in .tscn: peste ~1000 de piese, nodurile de scena blocheaza
## incarcarea (memoria `decor-in-masa-cere-multimesh`: 5633 de noduri = 25 min
## la „incarc pista"). De ce nu `FlockProp`: stolul ia UN mesh si UN material,
## iar o casa are peretele pe o clasa (varul albastru) si restul pe atlas.
## De ce nu `TrackDecorBatch` direct pe noduri instantiate: ar insemna sute de
## instantieri GLB la fiecare incarcare doar ca sa fie aruncate.
##
## Ce REFOLOSESTE: materialele vin din `WorldProp` (acelasi `_split_shutters`,
## `CLASSES_BY_MODEL`, metadata `indigo`), aplicat pe UN SABLON per (model,
## tenta) — deci o casa din umplutura arata exact ca aceeasi casa pusa de mana
## in DecorManual, si orice schimbare de clasa se propaga singura. Feliile sunt
## ideea din `TrackDecorBatch` (un MultiMesh intreg pe pista se deseneaza mereu,
## deci culling-ul moare): celule de `cell_m`.
##
## Pe fiecare model: UN mesh de perete (clasa, tenta deschisa sau indigo) si UN
## mesh de atlas (usi, balustrade, geamuri, accentele rupte — toate pe
## materialul lumii, deci unite intr-un singur ArrayMesh). Pe celula: cel mult
## 3 buffere pe model.
##
## Pozitiile se genereaza la rulare, pe TERENUL REAL (raycast pe TerrainBody,
## nu sampler-ul neted — memoria `terrain-mesh-y-extrapoleaza`), deci se mut
## singure cand se redeseneaza traseul (memoria `flockprop-snap-si-ordinea-ready`:
## listele scrise in .tscn nu afla ca terenul s-a resapat). Determinist: acelasi
## `seed_value` + acelasi teren = aceleasi case.
##
## Fara coliziune: cea mai apropiata casa e la `min_road_m` de axul oricarei
## benzi (implicit 40 m). Primul rand, langa drum, e al DecorManual (cu corpuri).
##
## `--indigo=0.4` pe linia de comanda suprascrie `indigo_ratio` (unealta de
## captura pentru amestecul de tente, punctul 3d al fundatiei).

## Casele din care se trage (ponderi in `weights`, aceeasi ordine).
@export var models: Array[PackedScene] = []
@export var weights: PackedFloat32Array = PackedFloat32Array()
## Fractia de case pe INDIGO (`blue_lime_indigo`), restul pe albastru deschis.
## Decizia de amestec e a dezvoltatorului (vezi raportul fundatiei, 3d).
@export_range(0.0, 1.0, 0.01) var indigo_ratio: float = 0.4
## Pasul grilei (m). Casele au 6,3-7,7 m latura; la 10 m raman ulite de ~2,5 m.
@export var spacing_m: float = 10.0
@export var jitter_m: float = 1.0
## Distanta minima de la axul ORICAREI benzi (bucla + scurtaturi).
@export var min_road_m: float = 40.0
## Diferenta maxima de teren sub amprenta (m); peste = panta de stanca, fara casa.
@export var max_step_m: float = 2.5
## Cat se ingroapa baza sub cel mai JOS colt (m), ca nicio casa sa nu pluteasca.
@export var sink_m: float = 0.3
## Latura celulei de feliere (m).
## 250 m, masurat de TrackDecorBatch pe Dunele (curba de draw calls se
## aplatizeaza la 250; sub, fiecare celula in plus e un buffer in plus pe model).
@export var cell_m: float = 250.0
## Genereaza LOD-uri pe mesh-urile sabloanelor (peretele rupt si atlasul unit
## sunt ArrayMesh-uri NOI, fara LOD-urile importului). Godot alege LOD-ul unui
## MultiMesh dupa AABB-ul lui, deci celulele departate coboara singure.
@export var generate_lods: bool = true
@export var seed_value: int = 20260929
## Zone fara case (centru XZ in coordonate de lume + raza), pe langa
## golurile `TerrainHollow` (fantana) care se exclud singure.
@export var exclude_xz: PackedVector3Array = PackedVector3Array()
## ZONA PROPRIE (opt-in; gol = interiorul buclei, comportamentul dinainte):
## poligon XZ in coordonate de lume care INLOCUIESTE bucla ca zona de umplut.
## Kyoto (Track18, POI A): orasul vechi e doar o parte din interior (iazul F,
## dealul gradinii si padurile raman libere), iar cartierul din jurul pagodei
## Yasaka e in AFARA buclei, la nord de B. Restul regulilor (distanta de banda,
## goluri, treapta de teren) raman aceleasi.
@export var region_xz: PackedVector2Array = PackedVector2Array()

## CASE SUB DRUM (opt-in; 0 = oprit, comportamentul dinainte): o casa poate sta
## mai aproape de `min_road_m` — dar nu sub `below_road_m` — de orice punct de
## banda fata de care terenul ei e cu cel putin `below_drop_m` mai JOS. Regula
## de 40 m exista fiindca umplutura n-are coliziune; o casa cu 20 m sub buza
## unui bastion nu e ceva in care intra o masina, e ce vede soferul cand se
## uita in jos (Jodhpur, POI F: piciorul abruptului e la 36-40 m de drum).
@export var below_road_m: float = 0.0
@export var below_drop_m: float = 15.0

## CASELE CU FATA SPRE UN PUNCT (x, z, raza; raza 0 = oprit, comportamentul
## dinainte). Casele din raza se rotesc — tot in pasi de 90°, ca grila de ulite
## sa ramana dreapta, cu acelasi jitter de ±6° — pe pasul cel mai apropiat de
## directia spre punct. Jodhpur: punctul e varful bastionului (POI F), ca de
## pe bastion orasul de la piciorul stancii sa arate fatade, nu spate.
## Pozitiile nu se schimba (rotirea e dupa alegerea modelului, pe acelasi rng).
@export var face_xz: Vector3 = Vector3.ZERO
## Unde e FATA fiecarui model (aceeasi ordine ca `models`), ca unghi Y in grade
## fata de −Z: 0 = fata pe −Z, −90 = fata pe +X. Gol = toate pe −Z.
@export var front_yaw_deg: PackedFloat32Array = PackedFloat32Array()

var stats := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--indigo="):
			indigo_ratio = clampf(float(a.trim_prefix("--indigo=")), 0.0, 1.0)
	if Engine.is_editor_hint() or models.is_empty():
		return
	_build.call_deferred()


func _build() -> void:
	var track := _find_track()
	if track == null:
		push_warning("CityFill %s: nu gasesc pista" % name)
		return
	# Terenul trebuie sa fie in spatiul fizic inainte de raycast-uri.
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var t0 := Time.get_ticks_msec()
	var places := _generate(track, space)
	var parts := await _templates()
	var groups := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	var counts := PackedInt32Array()
	counts.resize(models.size())
	var indigo_n := 0
	for p: Dictionary in places:
		var mi: int = _pick(rng)
		var ind := rng.randf() < indigo_ratio
		if ind:
			indigo_n += 1
		counts[mi] += 1
		var xf: Transform3D = p["xf"]
		if face_xz.z > 0.0:
			xf = _faced(xf, mi)
		var cell := Vector2i(floori(xf.origin.x / cell_m), floori(xf.origin.z / cell_m))
		for part: Dictionary in parts[mi]:
			if part["variant"] != -1 and int(part["variant"]) != int(ind):
				continue
			var key := "%d|%d|%d|%d" % [mi, part["id"], cell.x, cell.y]
			if not groups.has(key):
				groups[key] = {"part": part, "xfs": [], "cell": cell, "model": mi}
			(groups[key]["xfs"] as Array).append(xf * (part["local"] as Transform3D))
	var batches := 0
	var tris := 0
	for key: String in groups:
		var g: Dictionary = groups[key]
		var part: Dictionary = g["part"]
		var xfs: Array = g["xfs"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = part["mesh"]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "CityFill_%s__p%d_%d_%d" % [
			models[int(g["model"])].resource_path.get_file().get_basename(),
			int(part["id"]), (g["cell"] as Vector2i).x, (g["cell"] as Vector2i).y]
		mmi.multimesh = mm
		mmi.material_override = part["material"]
		add_child(mmi)
		batches += 1
		tris += int(part["tris"]) * xfs.size()
	var cen := Vector3.ZERO
	for p: Dictionary in places:
		cen += (p["xf"] as Transform3D).origin
	cen /= maxf(float(places.size()), 1.0)
	var rej: Dictionary = stats.get("rejected", {})
	stats = {"below_road": stats.get("below_road", 0), "houses": places.size(), "indigo": indigo_n, "batches": batches, "centroid": cen, "rejected": rej,
		"tris": tris, "ms": Time.get_ticks_msec() - t0, "per_model": counts}
	print("CityFill %s: %d case (%d indigo, raport %.2f), %d buffere, %d tri, %d ms, centroid (%.0f, %.1f, %.0f), respinse %s" % [
		name, places.size(), indigo_n, indigo_ratio, batches, tris, stats["ms"],
		cen.x, cen.y, cen.z, str(stats.get("rejected", {}))])


## Rotirea spre `face_xz` (vezi exportul): pasul de 90° cel mai apropiat de
## directia spre punct, pastrand jitterul original al casei.
func _faced(xf: Transform3D, mi: int) -> Transform3D:
	var o := xf.origin
	var to := Vector2(face_xz.x - o.x, face_xz.y - o.z)
	if to.length() > face_xz.z or to.length() < 1.0:
		return xf
	var q := PI * 0.5
	# yaw-ul curent, din baza (Basis(UP, yaw) duce -Z in (-sin, 0, -cos)).
	var f := xf.basis * Vector3(0, 0, -1)
	var yaw := atan2(-f.x, -f.z)
	var jitter := yaw - roundf(yaw / q) * q
	var front := deg_to_rad(front_yaw_deg[mi]) if mi < front_yaw_deg.size() else 0.0
	# fata in lume = Basis(UP, yaw + front) * (0, 0, -1); vrem sa fie `to`.
	var want := atan2(-to.x, -to.y) - front
	return Transform3D(Basis(Vector3.UP, roundf(want / q) * q + jitter), o)


func _pick(rng: RandomNumberGenerator) -> int:
	if weights.size() != models.size():
		return rng.randi_range(0, models.size() - 1)
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return models.size() - 1


## Pozitiile: grila cu jitter pe AABB-ul buclei, pastrand doar punctele din
## INTERIORUL buclei principale, la `min_road_m` de orice banda, in afara
## golurilor de teren si a zonelor excluse, pe teren fara treapta.
func _generate(track: Track, space: PhysicsDirectSpaceState3D) -> Array:
	var loop := PackedVector2Array()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in track.baked:
		var q := Vector2(p.x, p.z)
		loop.append(q)
		lo = lo.min(q)
		hi = hi.max(q)
	if not region_xz.is_empty():
		loop = region_xz
		lo = Vector2(INF, INF)
		hi = Vector2(-INF, -INF)
		for q in region_xz:
			lo = lo.min(q)
			hi = hi.max(q)
	var roads := PackedVector2Array()
	var road_y := PackedFloat32Array()
	for r: TrackRoute in track.routes:
		var b: PackedVector3Array = r.baked
		for i in range(0, b.size(), 2):
			roads.append(Vector2(b[i].x, b[i].z))
			road_y.append(b[i].y)
	var holes: Array[Vector3] = []
	for n in _all(track):
		if n is TerrainHollow:
			var h := n as TerrainHollow
			holes.append(Vector3(h.global_position.x, h.global_position.z,
				h.radius_m + h.wall_m + 6.0))
	for e in exclude_xz:
		holes.append(e)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	var rejected := {"road": 0, "hole": 0, "step": 0, "nohit": 0}
	var min2 := min_road_m * min_road_m
	var below2 := below_road_m * below_road_m
	var below_n := 0
	var y := lo.y
	while y <= hi.y:
		var x := lo.x
		while x <= hi.x:
			var c := Vector2(x + rng.randf_range(-jitter_m, jitter_m),
				y + rng.randf_range(-jitter_m, jitter_m))
			var yaw := float(rng.randi_range(0, 3)) * PI * 0.5 \
				+ deg_to_rad(rng.randf_range(-6.0, 6.0))
			x += spacing_m
			if not Geometry2D.is_point_in_polygon(c, loop):
				continue
			var near := false
			var below := false
			var g0 := NAN
			for qi in roads.size():
				var d2 := c.distance_squared_to(roads[qi])
				if d2 >= min2:
					continue
				if below_road_m > 0.0 and d2 >= below2:
					if is_nan(g0):
						g0 = _ground(space, track, c)
					if not is_nan(g0) and road_y[qi] - g0 >= below_drop_m:
						below = true
						continue
				near = true
				break
			if near:
				rejected["road"] += 1
				continue
			if below:
				below_n += 1
			var in_hole := false
			for h in holes:
				if c.distance_to(Vector2(h.x, h.y)) < h.z:
					in_hole = true
					break
			if in_hole:
				rejected["hole"] += 1
				continue
			var hmin := INF
			var hmax := -INF
			var ok := true
			for off: Vector2 in [Vector2.ZERO, Vector2(3.8, 3.8), Vector2(-3.8, 3.8),
					Vector2(3.8, -3.8), Vector2(-3.8, -3.8)]:
				var g := _ground(space, track, c + off)
				if is_nan(g):
					ok = false
					break
				hmin = minf(hmin, g)
				hmax = maxf(hmax, g)
			if not ok:
				rejected["nohit"] += 1
				continue
			if hmax - hmin > max_step_m:
				rejected["step"] += 1
				continue
			out.append({"xf": Transform3D(Basis(Vector3.UP, yaw),
				Vector3(c.x, hmin - sink_m, c.y))})
		y += spacing_m
	stats["rejected"] = rejected
	stats["below_road"] = below_n
	return out


## Cota terenului REAL (TerrainBody) sub (x, z); NAN daca raza nu-l gaseste.
func _ground(space: PhysicsDirectSpaceState3D, track: Track, c: Vector2) -> float:
	var from := Vector3(c.x, 400.0, c.y)
	var to := Vector3(c.x, -200.0, c.y)
	var exclude: Array[RID] = []
	for i in 6:
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name).begins_with("TerrainBody"):
			return (hit["position"] as Vector3).y
		exclude.append(hit["rid"])
	return NAN


## Sabloanele: fiecare model de doua ori (deschis / indigo) sub un WorldProp
## temporar copil al acestui nod — deci sub pista, cu tema reala (memoria
## `decor-ready-inaintea-temei`) — si citite DUPA apelurile amanate.
## Intoarce, per model, lista de parti {id, mesh, material, local, variant, tris};
## `variant` = -1 (comuna), 0 (deschis), 1 (indigo).
func _templates() -> Array:
	var holder := Node3D.new()
	holder.name = "CityFillTemplates"
	holder.set_script(load("res://scenes/props/world_prop.gd"))
	holder.set("auto_collision", false)
	var roots: Array = []
	for m in models:
		var pair: Array = []
		for v in 2:
			var inst := m.instantiate() as Node3D
			if v == 1:
				inst.set_meta(WorldProp.LIME_INDIGO_META, true)
			holder.add_child(inst)
			pair.append(inst)
		roots.append(pair)
	add_child(holder)
	await get_tree().process_frame
	await get_tree().process_frame
	var world := Palette.world_material()
	var out: Array = []
	for mi_idx in roots.size():
		var parts: Array = []
		var atlas_st: ArrayMesh = null
		var atlas_tris := 0
		for v in 2:
			var root: Node3D = roots[mi_idx][v]
			for mi in _meshes(root):
				var local := _xf_to(mi, root)
				var mat := mi.material_override
				if mat == world or mat == null:
					if v == 1:
						continue # atlasul e comun celor doua tente
					for s in mi.mesh.get_surface_count():
						var st := SurfaceTool.new()
						st.append_from(mi.mesh, s, local)
						atlas_st = st.commit(atlas_st)
						atlas_tris += _tris(mi.mesh, s)
				else:
					var tr := 0
					for s in mi.mesh.get_surface_count():
						tr += _tris(mi.mesh, s)
					parts.append({"id": parts.size() + 1, "mesh": mi.mesh,
						"material": mat, "local": local, "variant": v, "tris": tr})
		if generate_lods:
			for part: Dictionary in parts:
				part["mesh"] = _with_lods(part["mesh"])
		if atlas_st != null:
			parts.append({"id": 0, "mesh": _with_lods(atlas_st) if generate_lods else atlas_st, "material": world,
				"local": Transform3D.IDENTITY, "variant": -1, "tris": atlas_tris})
		out.append(parts)
	holder.queue_free()
	return out


## Acelasi mesh, cu LOD-uri generate (ImporterMesh, ca la importul GLB).
func _with_lods(src: Mesh) -> Mesh:
	var im := ImporterMesh.new()
	for s in src.get_surface_count():
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(s))
	im.generate_lods(25.0, 60.0, [])
	var out := im.get_mesh()
	return out if out != null and out.get_surface_count() > 0 else src


func _tris(mesh: Mesh, s: int) -> int:
	var arr: Array = mesh.surface_get_arrays(s)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	return (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		for k in c.get_children():
			st.append(k)
		var mi := c as MeshInstance3D
		if mi != null and mi.mesh != null and mi.visible:
			out.append(mi)
	return out


func _xf_to(n: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		out.append(c)
		for k in c.get_children():
			st.append(k)
	return out


func _find_track() -> Track:
	var cur: Node = get_parent()
	while cur != null:
		if cur is Track:
			return cur as Track
		cur = cur.get_parent()
	return null
