class_name RoadsideProps
extends Node3D
## Aseaza decorul LOVIBIL de pe marginea drumului (decor lovibil, valul 3, nov 2026) din fisierul
## pistei, `res://scenes/tracks/roadside/TrackNN.tres` (`RoadsideSet`). Fiecare piesa devine
## `BumpProp`: doarme pana o atinge o masina, apoi zboara, se rastoarna sau se rostogoleste.
##
## De ce un nod separat si nu inca un `_build_*` in Track: asezarea se face pe SOLUL REAL, cu o
## raza, dupa ce lumea exista in spatiul fizic (ca la piesele de strada din San Francisco).
## Functia de cota a terenului nu stie de trotuare, punti sau nisipul adus de un POI.
##
## Un loc e bun doar daca (`spot`): raza gaseste sol aproape de cota drumului, solul nu e prea
## inclinat, nu e pe niciun carosabil (bucla sau scurtatura) si nu e ocupat de alt colizor.
## O piesa fara loc bun NU se aseaza (nu pluteste, nu intra in stanca); garda
## `tools/ProbeRoadside.tscn` numara piesele lipsa.
##
## Tiparele (`pattern`), in reperul grupului: `a` = de-a lungul drumului, in sensul de mers,
## `o` = spre exterior, de la marginea carosabilului:
##   "row"      `count` piese in sir, paralel cu drumul;
##   "wall"     `count` x `rows` piese: zid de cauciucuri, stiva de lazi;
##   "pyramid"  `count` la baza, cate una mai putin pe fiecare din cele `layers` etaje;
##   "taper"    sir oblic: prima piesa langa drum, ultima cu `skew` m mai in afara per piesa
##              (conurile care inchid o banda);
##   "cluster"  gramada stransa, pe o spirala determinista.
## `lying`: piesele stau culcate, cu axa PERPENDICULARA pe drum — lovite din sensul de mers, se
## rostogolesc inainte pe acostament.

const SET_DIR: String = "res://scenes/tracks/roadside/"
## Raza de asezare pleaca de atat deasupra cotei drumului si coboara atat sub ea.
const RAY_UP_M: float = 3.0
const RAY_DOWN_M: float = 4.0
## Cat poate diferi cota solului de cea a drumului: peste, e un mal sau un acoperis, nu acostament.
const MAX_STEP_M: float = 1.2
## Sub atat, solul e prea inclinat ca o piesa sa stea pe el.
const MIN_NORMAL_Y: float = 0.78
## Saltul implicit al pieselor la lovitura (m/s in sus; `BumpProp` `pop`): cat sa treaca peste
## capota in loc sa intre sub masina. O piesa il poate schimba cu cheia "pop" din catalog.
const POP_SPEED: float = 3.2
## Distanta de la care o piesa nu se mai deseneaza (m). Masurat cu ProbePerf --mobile pe
## Stromboli (70 de piese): fara prag, +19 desene pe cadru in medie (110 -> 129).
const DRAW_RANGE_M: float = 80.0
## Piesa sta cu cel putin atat in afara oricarui carosabil.
const ROAD_CLEAR_M: float = 0.35

var track: Track
var data: RoadsideSet
## Cate piese au fost asezate si cate n-au avut loc bun (sonde).
var built: int = 0
var skipped: int = 0
## Per grup: {"frac", "side", "pattern", "want", "built"} (sonde).
var report: Array[Dictionary] = []
## Emis dupa ce toate grupurile au fost asezate (sau imediat, fara fisier).
signal placed

var _piece_cache: Dictionary = {}


## Fisierul pistei, daca exista. Fara fisier, pista n-are decor lovibil asezat: nimic de facut.
static func set_path_for(track: Track) -> String:
	var stem := track.scene_file_path.get_file().get_basename()
	return SET_DIR + stem + ".tres" if not stem.is_empty() else ""


## Apelat de Track la sfarsitul constructiei. In editor nu: fara simulare, n-are ce aseza.
static func attach(track: Track) -> RoadsideProps:
	if Engine.is_editor_hint() or track == null:
		return null
	var old := track.get_node_or_null(^"RoadsideProps")
	if old != null:
		track.remove_child(old)
		old.queue_free()
	var path := set_path_for(track)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res := load(path) as RoadsideSet
	if res == null or res.groups.is_empty():
		return null
	var node := RoadsideProps.new()
	node.name = "RoadsideProps"
	node.track = track
	node.data = res
	track.add_child(node)
	return node


func _ready() -> void:
	_activate.call_deferred()


func _activate() -> void:
	# Doua cadre de fizica: colizoarele lumii (teren, decor, trotuare) trebuie sa fie in spatiu.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree() or track == null or track.baked.size() < 8:
		placed.emit()
		return
	for gi in data.groups.size():
		_build_group(gi, data.groups[gi])
	placed.emit()


## Indexul din bucla principala pentru o fractie de tur.
func index_at(frac: float) -> int:
	var n := track.baked.size()
	return int(roundf(fposmod(frac, 1.0) * float(n))) % n


## Planul unui grup, fara sa aseze nimic: reperul lui si, per loc, piesa si solul gasit
## ("hit" gol = fara loc bun). Public: `tools/SurveyRoadside.tscn` verifica o propunere cu el
## inainte s-o scrie, deci masoara cu exact regula cu care se aseaza.
func plan(g: Dictionary) -> Dictionary:
	var ids: Array = []
	var piece: Variant = g.get("piece", "")
	if piece is Array:
		ids = piece
	else:
		ids = [String(piece)]
	if ids.is_empty() or _piece(String(ids[0])).is_empty():
		return {}
	var n := track.baked.size()
	var i := index_at(float(g.get("frac", 0.0)))
	var side_sign := 1.0 if int(g.get("side", 1)) >= 0 else -1.0
	var out := track._side_at(i) * side_sign
	out.y = 0.0
	out = out.normalized()
	var along := track.baked[(i + 1) % n] - track.baked[i]
	along.y = 0.0
	along = along.normalized()
	var yaw := deg_to_rad(float(g.get("yaw", 0.0)))
	if not is_zero_approx(yaw):
		out = out.rotated(Vector3.UP, yaw)
		along = along.rotated(Vector3.UP, yaw)
	var lying := bool(g.get("lying", false))
	var first: Dictionary = _piece(String(ids[0]))
	var size: Vector3 = first["size"]
	var dia := maxf(size.x, size.z)
	# Gabaritul unei piese in reperul grupului: de-a lungul drumului, spre exterior, in sus.
	var ext := Vector3(size.x, size.z, size.y)
	if lying:
		ext = Vector3(dia, size.y, dia) # a = diametru, o = lungimea axei, sus = diametru
	var spacing := float(g.get("spacing", ext.x + 0.08))
	var edge := track.baked[i] + out * (track.width_at_index(i) + float(g.get("gap", 1.2)))
	var road_y := track.baked[i].y
	var slots: Array[Dictionary] = []
	var k := 0
	for s: Dictionary in _slots(g, ext, spacing):
		var id := String(ids[k % ids.size()])
		k += 1
		var hit := {}
		# Etajele de sus stau pe piesele de dedesubt, nu pe sol: locul lor se afla la asezare.
		if int(s["layer"]) == 0:
			var at := edge + along * float(s["a"]) + out * (float(s["o"]) + ext.y * 0.5)
			hit = spot(at, road_y, maxf(0.25, dia * 0.4))
		slots.append({"id": id, "layer": int(s["layer"]), "a": float(s["a"]), "hit": hit})
	return {"along": along, "out": out, "lying": lying, "ext": ext, "spacing": spacing,
		"slots": slots}


## Cate piese ale grupului n-ar avea loc bun (etajele de sus cad odata cu sprijinul lor).
func missing(g: Dictionary) -> int:
	var p := plan(g)
	if p.is_empty():
		return 1
	var gone := 0
	var ok_by_layer := {}
	for s: Dictionary in p["slots"]:
		var layer := int(s["layer"])
		var ok := false
		if layer == 0:
			ok = not (s["hit"] as Dictionary).is_empty()
		else:
			ok = _supports(ok_by_layer.get(layer - 1, []), float(s["a"]), float(p["spacing"])).size() == 2
		if ok:
			if not ok_by_layer.has(layer):
				ok_by_layer[layer] = []
			(ok_by_layer[layer] as Array).append({"a": float(s["a"])})
		else:
			gone += 1
	return gone


## Cele doua piese de pe etajul de dedesubt pe care sta o piesa de la `a`.
func _supports(below: Array, a: float, spacing: float) -> Array:
	var out: Array = []
	for b: Dictionary in below:
		if absf(absf(float(b["a"]) - a) - spacing * 0.5) < 0.06:
			out.append(b)
	return out


func _build_group(gi: int, g: Dictionary) -> void:
	var entry := {"frac": float(g.get("frac", 0.0)), "side": int(g.get("side", 1)),
		"pattern": String(g.get("pattern", "row")), "want": 0, "built": 0}
	report.append(entry)
	var p := plan(g)
	if p.is_empty():
		push_warning("RoadsideProps: grupul %d cere o piesa necunoscuta (%s)" % [gi, str(g.get("piece", ""))])
		return
	var lying: bool = p["lying"]
	var ext: Vector3 = p["ext"]
	var slots: Array = p["slots"]
	entry["want"] = slots.size()
	# Pe etaje: {"a", "top", "n"} — varful piesei in picioare sau centrul celei culcate.
	var by_layer := {}
	var k := 0
	for s: Dictionary in slots:
		k += 1
		var layer := int(s["layer"])
		var hit: Dictionary = s["hit"]
		if layer > 0:
			# Piesa de sus sta PE cele doua de dedesubt, oriunde au ajuns ele pe solul denivelat:
			# asezata dupa solul ei, ar fi intrat in ele si solverul le-ar fi imprastiat la nastere.
			var sup := _supports(by_layer.get(layer - 1, []), float(s["a"]), float(p["spacing"]))
			if sup.size() < 2:
				skipped += 1
				continue
			var t1: Vector3 = sup[0]["top"]
			var t2: Vector3 = sup[1]["top"]
			var nrm := ((sup[0]["n"] as Vector3) + (sup[1]["n"] as Vector3)).normalized()
			var mid := (t1 + t2) * 0.5
			if lying:
				# centrul nou la r*sqrt(3) peste linia centrelor; `_place` adauga raza la loc
				hit = {"position": mid + nrm * (ext.x * 0.5 * 0.732), "normal": nrm}
			else:
				var lift := maxf((t1 - mid).dot(nrm), (t2 - mid).dot(nrm)) + 0.02
				hit = {"position": mid + nrm * lift, "normal": nrm}
		if hit.is_empty():
			skipped += 1
			continue
		var body := _place(String(s["id"]), hit, p["along"], p["out"], lying,
			_jitter(gi, k) * (0.25 if lying or layer > 0 else 1.0))
		if body == null:
			skipped += 1
			continue
		var nn: Vector3 = hit["normal"]
		var pos: Vector3 = hit["position"]
		var top := pos + nn * (ext.x * 0.5 + 0.01) if lying else pos + nn * ext.z
		if not by_layer.has(layer):
			by_layer[layer] = []
		(by_layer[layer] as Array).append({"a": float(s["a"]), "top": top, "n": nn})
		body.set_meta(&"roadside_group", gi)
		built += 1
		entry["built"] = int(entry["built"]) + 1


## Locurile unui grup: {"a", "o", "layer"} in metri, in reperul grupului.
func _slots(g: Dictionary, ext: Vector3, spacing: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var count := maxi(1, int(g.get("count", 3)))
	var half := float(count - 1) * 0.5
	match String(g.get("pattern", "row")):
		"wall":
			for r in maxi(1, int(g.get("rows", 2))):
				for c in count:
					out.append({"a": (float(c) - half) * spacing,
						"o": float(r) * (ext.y + 0.06), "layer": 0})
		"pyramid":
			for l in mini(count, maxi(1, int(g.get("layers", 2)))):
				for c in count - l:
					out.append({"a": (float(c) - half + float(l) * 0.5) * spacing,
						"o": 0.0, "layer": l})
		"taper":
			var skew := float(g.get("skew", 0.55))
			for c in count:
				out.append({"a": (float(c) - half) * spacing, "o": float(c) * skew, "layer": 0})
		"cluster":
			# Spirala cu unghiul de aur: gramada stransa, aceeasi la fiecare incarcare.
			var step := maxf(ext.x, ext.y) * 0.9 + 0.06
			var reach := step * sqrt(float(count))
			for c in count:
				var r := step * sqrt(float(c) + 0.35)
				var th := float(c) * 2.39996
				out.append({"a": cos(th) * r, "o": reach + sin(th) * r - ext.y * 0.5, "layer": 0})
		_:
			for c in count:
				out.append({"a": (float(c) - half) * spacing, "o": 0.0, "layer": 0})
	return out


## Solul de sub `at`, daca locul e bun pentru o piesa: {"position", "normal"}, altfel gol.
## `road_y` = cota drumului in dreptul grupului; `radius` = cat loc liber cere piesa.
## Publica: `tools/SurveyRoadside.tscn` masoara locurile cu EXACT regula cu care se aseaza.
func spot(at: Vector3, road_y: float, radius: float, need_clear: bool = true) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var from := Vector3(at.x, road_y + RAY_UP_M, at.z)
	var to := Vector3(at.x, road_y - RAY_DOWN_M, at.z)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	var cars: Array[RID] = []
	for c in get_tree().get_nodes_in_group(&"cars"):
		if c is CollisionObject3D:
			cars.append((c as CollisionObject3D).get_rid())
	q.exclude = cars
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return {}
	var pos: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	if normal.y < MIN_NORMAL_Y or absf(pos.y - road_y) > MAX_STEP_M:
		return {}
	if on_any_road(pos, radius):
		return {}
	if not need_clear:
		return {"position": pos, "normal": normal}
	# Loc liber: o sfera ridicata putin de la sol nu atinge alt colizor al lumii (stanca, zid,
	# stalp de bordura). Piesele aceluiasi grup nu se cauta aici: tiparul le tine despartite.
	var ball := SphereShape3D.new()
	ball.radius = radius
	var sq := PhysicsShapeQueryParameters3D.new()
	sq.shape = ball
	sq.transform = Transform3D(Basis.IDENTITY, pos + normal * (radius + 0.12))
	sq.collision_mask = 1
	sq.exclude = cars
	if not space.intersect_shape(sq, 1).is_empty():
		return {}
	return {"position": pos, "normal": normal}


## E punctul pe vreun carosabil (bucla principala sau o scurtatura), cu `margin` m de rezerva?
func on_any_road(pos: Vector3, margin: float) -> bool:
	for r in track.routes.size():
		var route: TrackRoute = track.routes[r]
		if route == null or route.baked.size() < 2:
			continue
		var i := route.closest_index_global(pos)
		if route.is_other_level(i, pos):
			continue
		var half := track.width_at_index(i) if r == 0 else route.half_width
		if route.lateral_distance(i, pos) < half + ROAD_CLEAR_M + margin:
			return true
	return false


func _place(id: String, hit: Dictionary, along: Vector3, out: Vector3, lying: bool,
		yaw_jitter: float) -> BumpProp:
	var info: Dictionary = _piece(id)
	if info.is_empty():
		return null
	var model := _instance(info)
	if model == null:
		return null
	var normal: Vector3 = hit["normal"]
	var pos: Vector3 = hit["position"]
	# Reperul piesei sta PE sol: sus = normala, restul din directiile grupului proiectate pe el.
	var fwd := (along - normal * along.dot(normal)).normalized().rotated(normal, yaw_jitter)
	var side := fwd.cross(normal).normalized()
	var size: Vector3 = info["size"]
	var xf := Transform3D.IDENTITY
	if lying:
		# Axa modelului (Y) culcata spre exterior; centrul la o raza deasupra solului.
		var axis := (out - normal * out.dot(normal)).normalized()
		var radius := maxf(size.x, size.z) * 0.5
		var x := normal.cross(axis).normalized()
		xf.basis = Basis(x, axis, x.cross(axis).normalized())
		xf.origin = pos + normal * (radius + 0.01) - axis * (size.y * 0.5)
	else:
		xf.basis = Basis(side, normal, side.cross(normal).normalized())
		xf.origin = pos
	xf.basis = xf.basis.orthonormalized().scaled_local(Vector3.ONE * float(info["scale"]))
	model.name = "%s_%d" % [id, get_child_count()]
	add_child(model)
	model.global_transform = xf
	var opts := {"shape": String(info["shape"]), "pop": float(info.get("pop", POP_SPEED))}
	if info.has("mass"):
		opts["mass"] = float(info["mass"])
	if info.has("bounce"):
		opts["bounce"] = float(info["bounce"])
	var body := BumpProp.wrap(model, opts)
	if body == null:
		model.queue_free()
	return body


## Piesa din catalogul fisierului, cu scena incarcata si gabaritul masurat: {"scene", "node",
## "shape", "scale", "size", "classes"[, "mass", "bounce"]}. Gol daca id-ul sau modelul lipseste.
func _piece(id: String) -> Dictionary:
	if _piece_cache.has(id):
		return _piece_cache[id]
	var out := {}
	var def: Dictionary = data.pieces.get(id, {})
	var glb := String(def.get("glb", ""))
	if not glb.is_empty() and ResourceLoader.exists(glb):
		out = {"scene": load(glb), "node": String(def.get("node", "")),
			"shape": String(def.get("shape", "box")), "scale": float(def.get("scale", 1.0)),
			"classes": String(def.get("classes", ""))}
		if def.has("mass"):
			out["mass"] = float(def["mass"])
		if def.has("bounce"):
			out["bounce"] = float(def["bounce"])
		if def.has("pop"):
			out["pop"] = float(def["pop"])
		var probe := _instance(out)
		if probe == null:
			out = {}
		else:
			out["size"] = Track.model_aabb(probe).size * float(out["scale"])
			probe.free()
	_piece_cache[id] = out
	return out


func _instance(info: Dictionary) -> Node3D:
	var scene := info["scene"] as PackedScene
	if scene == null:
		return null
	var model: Node3D
	if String(info["node"]).is_empty():
		model = scene.instantiate() as Node3D
	else:
		model = track._extract_glb_node(scene, String(info["node"]))
	if model == null:
		return null
	if String(info["classes"]) == "junk":
		Palette.apply_class_materials(model, Track.PROPS_JUNK_CLASSES)
	else:
		Palette.apply_world_material(model)
	# Piesele nu intra in coacerea MultiMesh (se misca), deci fiecare e un desen in plus. Peste
	# DRAW_RANGE_M o piesa de jumatate de metru are cativa pixeli: nu se mai deseneaza.
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visibility_range_end = DRAW_RANGE_M
	if model is MeshInstance3D:
		(model as MeshInstance3D).visibility_range_end = DRAW_RANGE_M
	return model


## Rotatie mica, determinista, per piesa: un sir de lazi perfect aliniate arata a raft.
func _jitter(gi: int, k: int) -> float:
	var h := hash(Vector2i(gi * 131 + 7, k * 977 + 3))
	return (float(h % 2001) / 1000.0 - 1.0) * deg_to_rad(14.0)
