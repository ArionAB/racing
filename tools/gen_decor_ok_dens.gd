extends Node
## Trecerea GLOBALA de densitate pe Okinawa (Track20): umple banda de 2,4-16 m de langa
## margine, pe zonele A, C si D (criticii valului 1 au cerut aceeasi diferenta: banda goala
## dintre bordura si decorul principal). Genereaza `DecorManual/Densitate` in Track20.tscn:
##   - hibiscus ca FlockProp (MultiMesh, cate un desen per mesh si bucata de ~60 m); toate tipurile
##     (hibiscus, bougainvillea, cycad, pandanus) sunt stoluri, zero noduri WorldProp noi.
## Nu atinge nodurile din ZonaA-H: le citeste ca amprente (rect in plan + inaltime) si se
## fereste de ele. Interzis: culoarele hazardelor (pod 0.612-0.737, tromba 0.775-0.79,
## valul 0.86-0.90) - zonele de mai jos nu le ating; fereastra portii D; aleea B.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkDens.tscn -- --out=C:/cale/dens.part
##   python tools/apply_dens.py C:/cale/dens.part

const TRACK := "res://scenes/tracks/Track20.tscn"
const POOL := "DecorManual/Densitate"
const GATE_F := 0.4298

const PATHS := {
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"bougain": "res://assets/models/okinawa/plants/bougainvillea.glb",
	"cycad": "res://assets/models/okinawa/plants/cycad.glb",
	"pandanus": "res://assets/models/trees/pandanus.glb",
}
const NAMES := {"bougain": "Bougainvillea", "cycad": "Cicas", "pandanus": "Pandanus"}
# raza de baza (m) a fiecarei piese la scara 1; distanta minima de la MARGINEA asfaltului
const RADIUS := {"hibiscus": 0.75, "bougain": 1.15, "cycad": 1.1, "pandanus": 1.7}
const MIN_EDGE := {"hibiscus": 2.4, "bougain": 3.2, "cycad": 3.4, "pandanus": 4.6}

const ZONES := [
	{"id": "A", "f0": 0.976, "f1": 0.1023, "pandanus": true},
	{"id": "C", "f0": 0.215, "f1": 0.333, "pandanus": false},
	{"id": "D", "f0": 0.335, "f1": 0.474, "pandanus": false},
	# F: doar malurile, fara pasajul 0.630-0.685 (rampe, travee, repuneri)
	{"id": "F1", "f0": 0.612, "f1": 0.630, "pandanus": true},
	{"id": "F2", "f0": 0.685, "f1": 0.737, "pandanus": true},
]

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid := RID()
var _space: PhysicsDirectSpaceState3D
var _sus_y := 0.0
var _sea := 0.05
var _out_path := ""
var _rng := RandomNumberGenerator.new()
var _fr: Array[Vector4] = []  # x0, z0, x1, z1
var _fh: Array[float] = []    # inaltimea
var _fname: Array[String] = []
var _hitn := {}
var _fobb: Array = []         # null (dreptunghi) sau [Transform3D invers, AABB local, scara]
var _grid := {}
var _new: Array[Vector4] = []  # x, z, raza, tip
var _new_grid := {}
var _hib := {}   # cheie chunk -> {pos, yaw, sc}
var _nodes: Array[String] = []
var _counts := {"hibiscus": 0, "bougain": 0, "cycad": 0, "pandanus": 0}
var _skipped := 0
var _cur_name := ""
var _why := {}

func _no(k: String) -> bool:
	_why[k] = int(_why.get(k, 0)) + 1
	return false

var _seq := {}
var _used_kinds := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for k in 8:
		await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_sampler = _track._sampler
	_sea = float(_sampler.mean_road_y()) + float(_track.sea_level_offset)
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 410123
	_collect_footprints()
	for z in ZONES:
		_zone(z)
	print("; motive: ", _why)
	var kk := _hitn.keys()
	kk.sort_custom(func(a, b): return _hitn[a] > _hitn[b])
	for q in range(mini(25, kk.size())):
		print(";; HIT ", kk[q], " ", _hitn[kk[q]])
	_write()
	get_tree().quit(0)


# ---------------------------------------------------------------- teren / traseu
func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(round(fposmod(frac, 1.0) * float(n))) % n


func _tangent(i: int) -> Vector3:
	var n := _track.baked.size()
	var d: Vector3 = _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
	d.y = 0.0
	return d.normalized()


func _left(i: int) -> Vector3:
	var t := _tangent(i)
	return Vector3(t.z, 0.0, -t.x)


func _sol(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)


## (distanta de la marginea asfaltului, indice baked cel mai apropiat)
func _edge_near(x: float, z: float) -> Vector2:
	var best := INF
	var bi := 0
	for j in _track.baked.size():
		var b: Vector3 = _track.baked[j]
		var dx := x - b.x
		var dz := z - b.z
		if absf(dx) > 60.0 or absf(dz) > 60.0:
			continue
		var d := sqrt(dx * dx + dz * dz) - _track.width_at_index(j)
		if d < best:
			best = d
			bi = j
	return Vector2(best, float(bi))


# ---------------------------------------------------------------- amprente existente
func _collect_footprints() -> void:
	var dm := _track.get_node("DecorManual")
	var stack: Array[Node] = [dm]
	var meshes := 0
	var pts := 0
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name == "Densitate":
			continue  # rularile repetate nu se blocheaza pe propriul rezultat
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).is_visible_in_tree():
			var mi := n as MeshInstance3D
			_cur_name = str(mi.get_path()).trim_prefix("/root/Track20/DecorManual/")
			var box: AABB = mi.global_transform * mi.get_aabb()
			_add_fp(box.position.x, box.position.z, box.end.x, box.end.z, box.end.y - box.position.y,
				[mi.global_transform.affine_inverse(), mi.get_aabb(), mi.global_transform.basis.x.length()])
			meshes += 1
			if box.size.x * box.size.z > 300.0 or box.size.y > 20.0:
				print(";; GRANDE %s %.0f m2 h=%.1f" % [str(mi.get_path()).trim_prefix("/root/"), box.size.x * box.size.z, box.size.y])
		elif n is FlockProp:
			var fp := n as FlockProp
			for p in fp.positions:
				_add_fp(p.x - 0.8, p.z - 0.8, p.x + 0.8, p.z + 0.8, 2.5)
				pts += 1
	print("; amprente: %d mesh-uri, %d puncte de stol" % [meshes, pts])


func _add_fp(x0: float, z0: float, x1: float, z1: float, h: float, obb: Array = []) -> void:
	var k := _fr.size()
	_fobb.append(obb)
	_fname.append(_cur_name)
	_fr.append(Vector4(x0, z0, x1, z1))
	_fh.append(h)
	for cx in range(int(floor(x0 / 10.0)), int(floor(x1 / 10.0)) + 1):
		for cz in range(int(floor(z0 / 10.0)), int(floor(z1 / 10.0)) + 1):
			var key := Vector2i(cx, cz)
			if not _grid.has(key):
				_grid[key] = []
			_grid[key].append(k)


## Inaltimea celei mai inalte amprente existente care atinge cercul (x,z,r); -1 = liber.
func _hit_existing(x: float, z: float, r: float) -> float:
	var worst := -1.0
	for cx in range(int(floor((x - r) / 10.0)), int(floor((x + r) / 10.0)) + 1):
		for cz in range(int(floor((z - r) / 10.0)), int(floor((z + r) / 10.0)) + 1):
			var key := Vector2i(cx, cz)
			if not _grid.has(key):
				continue
			for k in _grid[key]:
				var f: Vector4 = _fr[k]
				var qx := clampf(x, f.x, f.z)
				var qz := clampf(z, f.y, f.w)
				if (x - qx) * (x - qx) + (z - qz) * (z - qz) >= r * r:
					continue
				var ob: Array = _fobb[k]
				if not ob.is_empty():
					# test fin in spatiul local al mesh-ului (casele si zidurile rotite)
					var inv: Transform3D = ob[0]
					var bb: AABB = ob[1]
					var lp: Vector3 = inv * Vector3(x, 0.5 * (bb.position.y + bb.end.y), z)
					var ddx := maxf(maxf(bb.position.x - lp.x, 0.0), lp.x - bb.end.x)
					var ddz := maxf(maxf(bb.position.z - lp.z, 0.0), lp.z - bb.end.z)
					var sc: float = ob[2]
					if (ddx * ddx + ddz * ddz) * sc * sc >= r * r:
						continue
				worst = maxf(worst, _fh[k])
				_hitn[_fname[k]] = int(_hitn.get(_fname[k], 0)) + 1
	return worst


func _hit_new(x: float, z: float, r: float) -> bool:
	for cx in range(int(floor((x - 4.0) / 8.0)), int(floor((x + 4.0) / 8.0)) + 1):
		for cz in range(int(floor((z - 4.0) / 8.0)), int(floor((z + 4.0) / 8.0)) + 1):
			var key := Vector2i(cx, cz)
			if not _new_grid.has(key):
				continue
			for k in _new_grid[key]:
				var q: Vector4 = _new[k]
				var rr := (r + q.z) * 0.55  # suprapunere deliberata: palcuri, nu stampile
				if (x - q.x) * (x - q.x) + (z - q.y) * (z - q.y) < rr * rr:
					return true
	return false


# ---------------------------------------------------------------- plasare
func _try_piece(kind: String, x: float, z: float, sc: float) -> bool:
	var r: float = float(RADIUS[kind]) * sc
	var en := _edge_near(x, z)
	var edge := en.x
	var bi := int(en.y)
	var fi := float(bi) / float(_track.baked.size())
	if edge < float(MIN_EDGE[kind]) or edge > 16.5:
		return _no("edge")
	# fereastra portii D: nimic 12 m de-a lungul drumului in jurul ei
	if absf(fi - GATE_F) < 0.0062:
		return _no("gate")
	# inainte de poarta (cadrul reper): doar vegetatie joasa
	if kind != "hibiscus" and fi > 0.398 and fi < 0.4315:
		return _no("prepoarta")
	# hibiscusul (stol) poate trece peste muchia unui zid de corali scund (flori peste zid, brief A);
	# restul pieselor cer loc liber
	var hh := _hit_existing(x, z, r * 0.85 + 0.25)
	if hh >= 0.0:
		if kind != "hibiscus" or hh > 1.6 or _hit_existing(x, z, r * 0.4) >= 0.0:
			return _no("existent")
	# langa constructii inalte (case, ziduri > 2,2 m): doar hibiscus, ca fatada sa ramana vizibila
	if kind != "hibiscus" and _hit_existing(x, z, r + 2.5) > 2.2:
		return _no("inalt")
	if _hit_new(x, z, r):
		return _no("nou")
	var gy := _sol(x, z)
	if gy < _sea + 0.3:
		return _no("mare")
	var road_y: float = (_track.baked[bi] as Vector3).y
	if absf(gy - road_y) > 2.6:
		return _no("cota")
	var rr := minf(r * 0.7, 1.2)
	for off in [Vector2(rr, 0), Vector2(-rr, 0), Vector2(0, rr), Vector2(0, -rr)]:
		if absf(_sol(x + off.x, z + off.y) - gy) > 0.7:
			return _no("panta")
	_commit(kind, x, gy, z, sc, bi)
	return true


func _commit(kind: String, x: float, gy: float, z: float, sc: float, bi: int) -> void:
	var yaw := _rng.randf() * TAU
	var ni := _new.size()
	_new.append(Vector4(x, z, float(RADIUS[kind]) * sc, 0.0))
	var key := Vector2i(int(floor(x / 8.0)), int(floor(z / 8.0)))
	if not _new_grid.has(key):
		_new_grid[key] = []
	_new_grid[key].append(ni)
	_counts[kind] += 1
	_used_kinds[kind] = true
	var ck := "%s_%02d" % [kind, int(bi / 30)]
	if not _hib.has(ck):
		_hib[ck] = {"kind": kind, "pos": [], "yaw": [], "sc": []}
	var d: Dictionary = _hib[ck]
	d["pos"].append(Vector3(x, gy - 0.04, z))
	d["yaw"].append(yaw)
	d["sc"].append(Vector3(sc * _rng.randf_range(0.95, 1.1), sc * _rng.randf_range(0.9, 1.15), sc * _rng.randf_range(0.95, 1.1)))


func _scale_of(kind: String) -> float:
	match kind:
		"hibiscus": return _rng.randf_range(1.0, 1.55)
		"bougain": return _rng.randf_range(1.0, 1.35)
		"cycad": return _rng.randf_range(0.9, 1.3)
		"pandanus": return _rng.randf_range(1.4, 1.8)
	return 1.0


## Un palc: n incercari in jurul unui centru; amestecul decide tipurile.
func _cluster(cx: float, cz: float, rad: float, n: int, mix: Array) -> void:
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 10:
		tries += 1
		var a := _rng.randf() * TAU
		var d := rad * sqrt(_rng.randf())
		var kind: String = mix[_rng.randi() % mix.size()]
		if _try_piece(kind, cx + cos(a) * d, cz + sin(a) * d, _scale_of(kind)):
			placed += 1
		else:
			_skipped += 1


func _zone(z: Dictionary) -> void:
	var n := _track.baked.size()
	var i0 := _idx(float(z["f0"]))
	var i1 := _idx(float(z["f1"]))
	var span := (i1 - i0 + n) % n
	var allow_pand: bool = z["pandanus"]
	var hib_mix := ["hibiscus", "hibiscus", "hibiscus", "hibiscus", "hibiscus", "bougain"]
	var patch_mix := ["bougain", "bougain", "hibiscus", "hibiscus", "hibiscus"]
	var grove_mix := ["pandanus", "hibiscus", "hibiscus", "hibiscus", "bougain"]
	var cyc_mix := ["cycad", "hibiscus", "hibiscus", "hibiscus"]
	# benzi (de la MARGINE): lo, hi, probabilitate de palc pe pas de 4 m, raza, n min, n max
	var bands := [
		[2.6, 5.5, 0.5, 2.0, 3, 6],
		[5.5, 9.5, 0.6, 2.8, 4, 8],
		[9.5, 15.5, 0.6, 3.4, 5, 9],
	]
	var k := 0
	while k < span:
		var i := (i0 + k) % n
		var p: Vector3 = _track.baked[i]
		var left := _left(i)
		var hw := _track.width_at_index(i)
		for side in [1.0, -1.0]:
			for bnd in bands:
				if _rng.randf() > float(bnd[2]):
					continue
				var lat := hw + _rng.randf_range(float(bnd[0]), float(bnd[1]))
				var along := _tangent(i) * _rng.randf_range(-2.0, 2.0)
				var c: Vector3 = p + left * float(side) * lat + along
				var mix: Array = hib_mix
				var roll := _rng.randf()
				if roll < 0.20:
					mix = patch_mix
				elif roll < 0.34 and allow_pand:
					mix = grove_mix
				elif roll < 0.42 and float(bnd[0]) >= 5.0:
					mix = cyc_mix
				_cluster(c.x, c.z, float(bnd[3]), _rng.randi_range(int(bnd[4]), int(bnd[5])), mix)
		k += 2
	print("; zona %s: %s %s" % [z["id"], str(_counts), str(_why)])
	_why.clear()


# ---------------------------------------------------------------- iesire
func _fmt_v3(v: Vector3) -> String:
	return "%.3f, %.3f, %.3f" % [v.x, v.y, v.z]


func _write() -> void:
	var lines: Array[String] = []
	lines.append("; --- EXT_RESOURCES (de lipit in antet) ---")
	for kind in PATHS:
		if _used_kinds.has(kind):
			lines.append('[ext_resource type="PackedScene" path="%s" id="o_%s"]' % [PATHS[kind], kind])
	lines.append("; --- NODURI (de lipit la sfarsit) ---")
	lines.append('[node name="Densitate" type="Node3D" parent="DecorManual"]')
	lines.append('metadata/info = "trecerea globala de densitate: banda 2,4-16 m de margine pe A/C/D; tools/gen_decor_ok_dens.gd"')
	lines.append("")
	# mesh-urile fiecarui tip: [nume mesh, clasa/tenta]; fara materiale noi (tentele exista deja)
	var parts := {
		"hibiscus": [["Hibiscus", ""]],
		"bougain": [["Bougainvillea_Leaves", "atint:ok_leaves"], ["Bougainvillea_Bloom", "atint:ok_bloom"]],
		"cycad": [["Cycad_Leaves", "atint:ok_leaves"], ["Cycad_Bark", ""]],
		"pandanus": [["Pandanus_Leaves", ""], ["Pandanus_Bark", ""]],
	}
	var keys := _hib.keys()
	keys.sort()
	for key in keys:
		var d: Dictionary = _hib[key]
		var ps: Array[String] = []
		for v in d["pos"]:
			ps.append(_fmt_v3(v))
		var ys: Array[String] = []
		for y in d["yaw"]:
			ys.append("%.3f" % y)
		var ss: Array[String] = []
		for s2 in d["sc"]:
			ss.append("Vector3(%s)" % _fmt_v3(s2))
		for part in parts[d["kind"]]:
			lines.append('[node name="%s_%s" type="MultiMeshInstance3D" parent="%s"]' % [key, str(part[0]).get_slice("_", 1) if str(part[0]).contains("_") else "M", POOL])
			lines.append('script = ExtResource("c_flock")')
			lines.append('model = ExtResource("o_%s")' % d["kind"])
			lines.append('mesh_name = "%s"' % part[0])
			if part[1] != "":
				lines.append('tri_class = "%s"' % part[1])
			lines.append("view_m = 170.0")
			lines.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
			lines.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
			lines.append("scale3_list = Array[Vector3]([%s])" % ", ".join(ss))
			lines.append("")
	print("; total %s, sarite %d, stoluri %d" % [str(_counts), _skipped, _hib.size()])
	if _out_path.is_empty():
		for l in lines:
			print(l)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	for l in lines:
		fa.store_line(l)
	fa.close()
	print("; scris %s" % _out_path)


