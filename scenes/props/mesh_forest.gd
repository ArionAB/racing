class_name MeshForest
extends Node3D
## PADURE IN MASA: mii de copaci in cateva sute de MultiMesh-uri feliate pe zone.
##
## Nascut pe Kyoto (Track18, brief kyoto.md §2, §5.3, §5.6; kit §1.2). Un nod de
## scena per copac nu se poate: peste ~1000 de piese Godot nu mai termina de
## incarcat .tscn-ul (memoria `decor-in-masa-cere-multimesh`), iar valea de
## artari plus bambusul inseamna zeci de mii. Primul rand de langa drum ramane
## `DecorManual` (cu coliziune); tot ce e dincolo de el e aici.
##
## De ce sistem nou si nu `TrackDecorBatch` / `FlockProp`: primul NU consuma
## GLB-uri (strange `MeshInstance3D` deja instantiate), iar `FlockProp` ia doar
## PRIMUL `MeshInstance3D` al GLB-ului si o singura clasa — un arbore are trunchi
## SI coroana, pe doua clase diferite. Aici fiecare specie devine UN `ArrayMesh`
## cu cate o suprafata per nod al GLB-ului (trunchi, coroana), fiecare cu
## materialul clasei lui; deci un MultiMesh per (felie, specie), doua draw call-uri
## (doua suprafete), aceeasi transformare pe instanta.
##
## Cum ajunge CLASA pe copaci (memoria `scatter-nu-primeste-clasele-temei`:
## drumul instantei conteaza, nu doar tabelul): aici NU trece prin `WorldProp`,
## deci nici prin `_apply_model_classes`. [method _part_material] citeste
## DIRECT `WorldProp.CLASSES_BY_MODEL` si `WorldProp.CLASSES_BY_THEME[tema]`
## (aceleasi tabele, prefixul cel mai lung castiga, tema peste model), plus
## `SLOT_REMAP_BY_THEME` pentru sloturi. Cand maparile Kyoto intra in tabele,
## padurea le primeste fara nicio modificare aici; pana atunci piesele nemapate
## raman pe atlasul lumii (`Palette.world_material`).
##
## Nimic pe carosabil: distanta fata de MARGINEA soselei (toate rutele, tunelul
## cu o marja in plus), nimic sub plasa de mare, nimic peste zidul lumii sau
## dincolo de panza de teren. Cota vine din `TrackSideSampler.ground_y` (NU din
## `_terrain_mesh_y`, care extrapoleaza — memoria `terrain-mesh-y-extrapoleaza`).
## Oglindirea NU se face cu scale.x negativ (instantele MultiMesh cu determinant
## negativ sunt culled — memoria `multimesh-oglindire-culling`), ci din yaw.
##
## Nodul se aseaza sub pista; `top_level` il pune la identitate de lume, iar
## instantele isi au pozitiile in coordonate de lume.

## GLB-urile speciilor. Numele speciei = numele fisierului fara extensie, deci
## `MeshForestZone.species` o cheama dupa stem (momiji_a, moso_culm, ...).
@export var scenes: Array[PackedScene] = []
@export var zones: Array[MeshForestZone] = []
## Latura feliei de culling (m). O felie mare = putine draw call-uri dar AABB
## larg (se deseneaza si cand doar un colt e in cadru); una mica = invers.
@export_range(32.0, 400.0, 1.0, "suffix:m") var slice_m: float = 90.0
## LOD pe distanta: dincolo de `lod_m` (masurat pana la centrul AABB-ului feliei,
## deci +-jumatate de felie) o felie se deseneaza cu mesh-ul SIMPLIFICAT al
## speciei (meshoptimizer, via ImporterMesh.generate_lods; coroana de artar
## 2880 -> ~280 triunghiuri). 0 = fara LOD. Masurat: fara el, valea de artari
## trimitea ~6,5M triunghiuri/cadru (kyoto, ProbePerf).
@export_range(0.0, 400.0, 1.0, "suffix:m") var lod_m: float = 60.0
## Cat intra trunchiul in pamant (m): relieful palpaie sub radacina.
@export_range(0.0, 1.0, 0.01, "suffix:m") var sink_m: float = 0.25
## Cat de mult mai multa marja fata de o sosea obisnuita cere o scurtatura
## (tunelul de torii isi are deja cedrii lui la 6,6 si 10,4 m).
@export_range(0.0, 20.0, 0.5, "suffix:m") var branch_extra_clear_m: float = 4.0
## Cat de aproape de marginea panzei de teren si a zidului lumii (m).
@export_range(0.0, 60.0, 0.5, "suffix:m") var world_margin_m: float = 12.0
## Stinge tot (sabotaj pentru sonde: A/B cu si fara padure).
@export var enabled: bool = true
## Afiseaza raportul constructiei in log.
@export var verbose: bool = true

signal built

var _track: Track = null
var _sampler: TrackSideSampler = null

## Rezultatul constructiei (citit de sonde, DUPA semnalul `built`).
var done: bool = false
var instance_count: int = 0
var slice_count: int = 0
var counts_by_species: Dictionary = {}
var counts_by_zone: Dictionary = {}
var tris_by_species: Dictionary = {}
var total_tris: int = 0
var build_ms: int = 0
## Cate candidate au picat si de ce (diagnostic).
var rejected: Dictionary = {}

# Spatiul segmentelor de sosea (pentru distanta fata de margine).
const _SEG_CELL: float = 48.0
var _seg_a: PackedVector2Array = PackedVector2Array()
var _seg_b: PackedVector2Array = PackedVector2Array()
var _seg_hw_a: PackedFloat32Array = PackedFloat32Array()
var _seg_hw_b: PackedFloat32Array = PackedFloat32Array()
var _seg_grid: Dictionary = {}

# Ocuparea: celule de 2 m cu pozitiile deja puse (deduplicare la curbe interioare
# si intre zone suprapuse).
const _OCC_CELL: float = 2.0
var _occ: Dictionary = {}

var _species_mesh: Dictionary = {}   # stem -> ArrayMesh
var _species_far: Dictionary = {}    # stem -> ArrayMesh simplificat (sau acelasi)
var _species_tris: Dictionary = {}   # stem -> int
var _claims: Array[Vector3] = []     # (x, z, raza) ale zonelor cu claim
var _bounds: Rect2 = Rect2()
var _terrain_bounds: Rect2 = Rect2()
var _sea_y: float = -1e9


func _ready() -> void:
	# Sabotaj de A/B pentru sondele cu fereastra (ProbePerf nu are optiune pentru asta):
	# MESHFOREST_OFF=1 stinge padurea fara sa atinga scena.
	if OS.get_environment("MESHFOREST_OFF") != "":
		enabled = false
	if enabled:
		top_level = true
		global_transform = Transform3D.IDENTITY
		_build.call_deferred()


func _find_track() -> Track:
	if _track != null:
		return _track
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			_track = n as Track
			break
		n = n.get_parent()
	return _track


## Pista e gata cand ruta principala e coapta si are sampler (vezi `FlockProp`:
## copiii se pregatesc inaintea parintelui, deci nimic din asta nu exista in
## `_ready`).
func _track_ready(t: Track) -> bool:
	if t == null or t.routes.is_empty() or t.route_at(0).baked.is_empty():
		return false
	var s: Variant = t.get("_sampler")
	return s != null


func _build() -> void:
	if not is_inside_tree():
		return
	var track := _find_track()
	if not _track_ready(track):
		if track != null:
			get_tree().process_frame.connect(_build, CONNECT_ONE_SHOT)
		return
	var t0 := Time.get_ticks_msec()
	_sampler = track.get("_sampler") as TrackSideSampler
	_prepare(track)
	var theme := String(track.theme_decor)
	_build_species(theme)
	var groups: Dictionary = {}
	var main := track.route_at(0)
	for zi in zones.size():
		_fill_zone(zi, zones[zi], track, main, groups)
	_emit(groups)
	build_ms = Time.get_ticks_msec() - t0
	done = true
	if verbose:
		print("MeshForest %s: %d instante, %d felii, %d triunghiuri totale, %d ms | specii %s | zone %s | respinse %s" % [
			name, instance_count, slice_count, total_tris, build_ms,
			counts_by_species, counts_by_zone, rejected])
	built.emit()


# --- pregatire -------------------------------------------------------------

func _prepare(track: Track) -> void:
	_sea_y = _sampler.mean_road_y() + track.sea_level_offset
	var c: Vector3 = track.call("_centroid")
	_bounds = Rect2(c.x - 420.0 + world_margin_m, c.z - 420.0 + world_margin_m,
		840.0 - 2.0 * world_margin_m, 840.0 - 2.0 * world_margin_m)
	var ext: float = track.call("_world_extent")
	var tc: Vector3 = track.call("_terrain_center")
	var half := ext * 0.5 - world_margin_m
	_terrain_bounds = Rect2(tc.x - half, tc.z - half, 2.0 * half, 2.0 * half)
	_seg_a.clear()
	_seg_b.clear()
	_seg_hw_a.clear()
	_seg_hw_b.clear()
	_seg_grid.clear()
	_occ.clear()
	_claims.clear()
	rejected.clear()
	counts_by_species.clear()
	counts_by_zone.clear()
	instance_count = 0
	for ri in track.routes.size():
		var r := track.route_at(ri)
		var n := r.baked.size()
		var segs := n if r.closed else n - 1
		for i in segs:
			var j := (i + 1) % n
			var a := r.baked[i]
			var b := r.baked[j]
			var hw_a: float
			var hw_b: float
			if ri == 0:
				hw_a = track.width_at_index(i)
				hw_b = track.width_at_index(j)
			else:
				hw_a = r.half_width + branch_extra_clear_m
				hw_b = hw_a
			_add_segment(Vector2(a.x, a.z), Vector2(b.x, b.z), hw_a, hw_b)


func _add_segment(a: Vector2, b: Vector2, hw_a: float, hw_b: float) -> void:
	var id := _seg_a.size()
	_seg_a.append(a)
	_seg_b.append(b)
	_seg_hw_a.append(hw_a)
	_seg_hw_b.append(hw_b)
	var lo := Vector2i(floori(minf(a.x, b.x) / _SEG_CELL), floori(minf(a.y, b.y) / _SEG_CELL))
	var hi := Vector2i(floori(maxf(a.x, b.x) / _SEG_CELL), floori(maxf(a.y, b.y) / _SEG_CELL))
	for cx in range(lo.x, hi.x + 1):
		for cy in range(lo.y, hi.y + 1):
			var key := Vector2i(cx, cy)
			# Packed*Array se copiaza la citirea din Dictionary: append pe copie
			# lasa grila goala (edge_clear si pe_drum ar fi moarte). Rescrie cheia.
			var ids: PackedInt32Array = _seg_grid.get(key, PackedInt32Array())
			ids.append(id)
			_seg_grid[key] = ids


## Distanta de la `p` la cea mai apropiata MARGINE de sosea (negativa = pe ea),
## cautata doar in celula si vecinele ei (48 m): suficient cat marja ceruta +
## latimea soselei raman sub 48 m. Fara nicio sosea in jur = INF.
func _edge_dist(p: Vector2) -> float:
	var cx := floori(p.x / _SEG_CELL)
	var cy := floori(p.y / _SEG_CELL)
	var best := INF
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(cx + dx, cy + dy)
			if not _seg_grid.has(key):
				continue
			for id: int in (_seg_grid[key] as PackedInt32Array):
				var a := _seg_a[id]
				var ab := _seg_b[id] - a
				var l2 := ab.length_squared()
				var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0) if l2 > 1e-8 else 0.0
				var d := p.distance_to(a + ab * t)
				d -= lerpf(_seg_hw_a[id], _seg_hw_b[id], t)
				if d < best:
					best = d
	return best


# --- specii ----------------------------------------------------------------

func _build_species(theme: String) -> void:
	_species_mesh.clear()
	_species_tris.clear()
	for ps in scenes:
		if ps == null:
			continue
		var stem := ps.resource_path.get_file().get_basename()
		var mesh := _species_array_mesh(ps, stem, theme)
		if mesh == null:
			push_warning("MeshForest: %s nu are mesh" % stem)
			continue
		_species_mesh[stem] = mesh
		_species_far[stem] = _simplified(mesh) if lod_m > 0.0 else mesh
		var tris := 0
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			tris += (idx as PackedInt32Array).size() / 3 if idx != null \
				else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		_species_tris[stem] = tris


## Varianta de departare: acelasi mesh, cu indicii celui mai grosier LOD
## (ImporterMesh.generate_lods) pe fiecare suprafata care are unul. Varfurile
## raman toate (cele nefolosite costa doar memorie); materialele se pastreaza.
static func _simplified(src: ArrayMesh) -> ArrayMesh:
	var im := ImporterMesh.new()
	for si in src.get_surface_count():
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(si), [], {}, src.surface_get_material(si))
	im.generate_lods(25.0, 60.0, [])
	var out := ArrayMesh.new()
	for si in src.get_surface_count():
		var arr := src.surface_get_arrays(si)
		var nl := im.get_surface_lod_count(si)
		if nl > 0:
			arr[Mesh.ARRAY_INDEX] = im.get_surface_lod_indices(si, nl - 1)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(si, src.surface_get_material(si))
	return out


## UN ArrayMesh per specie: o suprafata per `MeshInstance3D`, cu transformul
## nodului COPT in varfuri (un MultiMesh nu stie de ierarhia din care vine
## mesh-ul) si materialul clasei ei.
func _species_array_mesh(ps: PackedScene, stem: String, theme: String) -> ArrayMesh:
	var root := ps.instantiate()
	var nodes: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null \
				and (n as MeshInstance3D).visible:
			nodes.append(n as MeshInstance3D)
	# Ordine stabila (arborele de noduri se parcurge pe stiva): trunchiul inaintea
	# coroanei nu conteaza, dar determinismul da.
	nodes.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool:
		return String(a.name) < String(b.name))
	var remap: Dictionary = {}
	var by_theme: Variant = WorldProp.SLOT_REMAP_BY_THEME.get(theme, null)
	if by_theme is Dictionary and (by_theme as Dictionary).has(stem):
		remap = (by_theme as Dictionary)[stem]
	var out: ArrayMesh = null
	var mats: Array[Material] = []
	for mi in nodes:
		var xf := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != root:
			if cur is Node3D:
				xf = (cur as Node3D).transform * xf
			cur = cur.get_parent()
		var src: Mesh = mi.mesh
		if not remap.is_empty():
			src = WorldProp._mesh_with_slots_moved(src, remap)
		var mat := _part_material(stem, theme, String(mi.name))
		for si in src.get_surface_count():
			var st := SurfaceTool.new()
			st.append_from(src, si, xf)
			out = st.commit(out)
			mats.append(mat)
	root.free()
	if out == null:
		return null
	for i in mats.size():
		out.surface_set_material(i, mats[i])
	return out


## Materialul unei parti (nume de nod) a unei specii. Aceleasi tabele ca
## `WorldProp._apply_classes_mapping`: CLASSES_BY_MODEL, apoi CLASSES_BY_THEME
## (tema bate modelul), prefixul cel mai lung castiga; fara potrivire = atlasul.
static func _part_material(stem: String, theme: String, part: String) -> Material:
	var cls := ""
	var best := -1
	var tables: Array[Dictionary] = [WorldProp.CLASSES_BY_MODEL]
	if WorldProp.CLASSES_BY_THEME.has(theme):
		tables.append(WorldProp.CLASSES_BY_THEME[theme])
	for table in tables:
		if not table.has(stem):
			continue
		var mapping: Dictionary = table[stem]
		best = -1
		for prefix: String in mapping:
			if part.begins_with(prefix) and prefix.length() > best:
				best = prefix.length()
				cls = String(mapping[prefix])
	if cls == "" or cls == Palette.ATLAS_PREFIX:
		return Palette.world_material()
	if cls == Palette.PLAIN_PREFIX:
		return Palette.plain_material()
	if cls.begins_with(Palette.GLOW_PREFIX):
		return Palette._glow_from_spec(cls.trim_prefix(Palette.GLOW_PREFIX))
	if cls.begins_with(Palette.FINISH_PREFIX):
		return Palette.finish_material(cls.trim_prefix(Palette.FINISH_PREFIX))
	if cls.begins_with(Palette.SHADER_PREFIX):
		return Palette.shader_material(cls.trim_prefix(Palette.SHADER_PREFIX))
	return Palette.triplanar_class_material(cls.trim_prefix(Palette.TRI_PREFIX))


# --- plasare ---------------------------------------------------------------

func _reject(why: String) -> void:
	rejected[why] = int(rejected.get(why, 0)) + 1


func _fill_zone(zi: int, z: MeshForestZone, track: Track, main: TrackRoute,
		groups: Dictionary) -> void:
	# LUMINISUL: un disc cu `claim` si FARA specii nu pune nimic, doar isi
	# rezerva suprafata pentru decorul manual (sala Kiyomizu pe esafodaj,
	# pagodele, deschiderea de vedere spre scena de pe C1). Trebuie asezat in
	# lista INAINTEA zonelor pe care le goleste.
	if z.species.is_empty() and z.claim and z.kind == MeshForestZone.Kind.DISC:
		_claims.append(Vector3(z.center.x, z.center.z, z.radius))
		counts_by_zone[z.label] = 0
		return
	if z.species.is_empty() or z.species.size() != z.weights.size():
		push_warning("MeshForest: zona %s are specii/ponderi nepotrivite" % z.label)
		return
	var total_w := 0.0
	for w in z.weights:
		total_w += w
	if total_w <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = z.seed_value
	var cands := _candidates(z, main, rng)
	var min_sep := z.spacing * 0.35
	var placed := 0
	var zone_centers := PackedVector2Array()
	for c in cands:
		var reason := _check(c, z, min_sep)
		if reason != "":
			_reject(reason)
			continue
		var gy := _sampler.ground_y(c.x, c.y)
		if gy < _sea_y + 1.0:
			_reject("sub_mare")
			continue
		var edge := _edge_dist(c)
		if z.max_below_road_m < 199.0:
			# Cota soselei in dreptul punctului: cel mai apropiat punct copt.
			var ri := main.closest_index_global(Vector3(c.x, 0.0, c.y))
			if gy < main.baked[ri].y - z.max_below_road_m:
				_reject("sub_drum")
				continue
		# Specia, dupa pondere.
		var pick := rng.randf() * total_w
		var si := 0
		for k in z.weights.size():
			pick -= z.weights[k]
			if pick <= 0.0:
				si = k
				break
		var stem := z.species[si]
		if not _species_mesh.has(stem):
			_reject("specie_lipsa")
			continue
		var s := rng.randf_range(z.scale_min, z.scale_max)
		var sc := Vector3(s, s * rng.randf_range(0.92, 1.1), s)
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(sc),
			Vector3(c.x, gy - sink_m, c.y))
		var shadow := z.shadow_m > 0.0 and edge <= z.shadow_m
		var cell := Vector2i(floori(c.x / slice_m), floori(c.y / slice_m))
		var key := "%d|%d|%d|%s|%d" % [zi, cell.x, cell.y, stem, 1 if shadow else 0]
		if not groups.has(key):
			groups[key] = {"zone": zi, "stem": stem, "shadow": shadow, "xf": [] as Array[Transform3D]}
		(groups[key]["xf"] as Array[Transform3D]).append(xf)
		_occupy(c)
		placed += 1
		counts_by_species[stem] = int(counts_by_species.get(stem, 0)) + 1
		instance_count += 1
		total_tris += int(_species_tris[stem])
		tris_by_species[stem] = int(tris_by_species.get(stem, 0)) + int(_species_tris[stem])
	counts_by_zone[z.label] = placed
	if z.claim and z.kind == MeshForestZone.Kind.DISC:
		_claims.append(Vector3(z.center.x, z.center.z, z.radius))


## Puncte candidate (XZ) cu zgomot, in zona ceruta.
func _candidates(z: MeshForestZone, main: TrackRoute, rng: RandomNumberGenerator) -> PackedVector2Array:
	var out := PackedVector2Array()
	var jit := z.spacing * 0.45
	if z.kind == MeshForestZone.Kind.DISC:
		var r := z.radius
		var cx := z.center.x
		var cz := z.center.z
		var x := cx - r
		while x <= cx + r:
			var y := cz - r
			while y <= cz + r:
				var p := Vector2(x + rng.randf_range(-jit, jit), y + rng.randf_range(-jit, jit))
				if p.distance_to(Vector2(cx, cz)) <= r:
					out.append(p)
				y += z.spacing
			x += z.spacing
		return out
	var n := main.baked.size()
	var i0 := clampi(int(z.frac_from * n), 0, n - 1)
	var i1 := clampi(int(z.frac_to * n), 0, n - 1)
	var d0 := main.dists[i0]
	var d1 := main.dists[i1]
	var sides: Array[float] = []
	match z.side:
		MeshForestZone.Flank.RIGHT: sides = [1.0]
		MeshForestZone.Flank.LEFT: sides = [-1.0]
		_: sides = [-1.0, 1.0]
	var d := d0
	while d <= d1:
		var sm := _sample(main, d)
		var p3: Vector3 = sm[0]
		var dir: Vector3 = sm[1]
		var right := dir.cross(Vector3.UP).normalized()
		var lat := z.lat_min
		while lat <= z.lat_max:
			for sgn in sides:
				var off := right * sgn * (lat + rng.randf_range(-jit, jit)) \
					+ dir * rng.randf_range(-jit, jit)
				out.append(Vector2(p3.x + off.x, p3.z + off.z))
			lat += z.spacing
		d += z.spacing
	return out


## Punct si directie orizontala la distanta `d` pe ruta (ca `ToriiTunnel._sample`).
func _sample(route: TrackRoute, d: float) -> Array:
	var n := route.baked.size()
	var lo := 0
	var hi := n - 1
	while lo < hi - 1:
		var mid := (lo + hi) / 2
		if route.dists[mid] <= d:
			lo = mid
		else:
			hi = mid
	var span := maxf(route.dists[hi] - route.dists[lo], 0.0001)
	var t := clampf((d - route.dists[lo]) / span, 0.0, 1.0)
	var p := route.baked[lo].lerp(route.baked[hi], t)
	var a := route.baked[maxi(lo - 1, 0)]
	var b := route.baked[mini(hi + 1, n - 1)]
	var dir := b - a
	dir.y = 0.0
	dir = dir.normalized() if dir.length_squared() > 1e-6 else Vector3.FORWARD
	return [p, dir]


## Motivul respingerii unui candidat, sau "" daca e bun (fara cota solului).
func _check(c: Vector2, z: MeshForestZone, min_sep: float) -> String:
	if not _bounds.has_point(c):
		return "zidul_lumii"
	if not _terrain_bounds.has_point(c):
		return "peste_panza"
	if _edge_dist(c) < z.edge_clear_m:
		return "pe_drum"
	for cl in _claims:
		if c.distance_squared_to(Vector2(cl.x, cl.y)) < cl.z * cl.z:
			return "revendicat"
	if _occupied(c, min_sep):
		return "ocupat"
	return ""


func _occupy(c: Vector2) -> void:
	var key := Vector2i(floori(c.x / _OCC_CELL), floori(c.y / _OCC_CELL))
	# Aceeasi capcana ca la _seg_grid: append pe copie, deci rescriem cheia.
	var pts: PackedVector2Array = _occ.get(key, PackedVector2Array())
	pts.append(c)
	_occ[key] = pts


func _occupied(c: Vector2, min_sep: float) -> bool:
	var cx := floori(c.x / _OCC_CELL)
	var cy := floori(c.y / _OCC_CELL)
	var reach := ceili(min_sep / _OCC_CELL)
	var m2 := min_sep * min_sep
	for dx in range(-reach, reach + 1):
		for dy in range(-reach, reach + 1):
			var key := Vector2i(cx + dx, cy + dy)
			if not _occ.has(key):
				continue
			for q in (_occ[key] as PackedVector2Array):
				if q.distance_squared_to(c) < m2:
					return true
	return false


# --- emiterea --------------------------------------------------------------

func _emit(groups: Dictionary) -> void:
	slice_count = 0
	var keys := groups.keys()
	keys.sort()
	for key in keys:
		var g: Dictionary = groups[key]
		var xfs: Array[Transform3D] = g["xf"]
		var z := zones[int(g["zone"])]
		var stem := String(g["stem"])
		var far_used: bool = lod_m > 0.0 and _species_far[stem] != _species_mesh[stem]
		for far in ([false, true] if far_used else [false]):
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = _species_far[stem] if far else _species_mesh[stem]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = String(key).replace("|", "_") + ("_far" if far else "")
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(g["shadow"]) 				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if far_used:
				if far:
					mmi.visibility_range_begin = lod_m
				else:
					mmi.visibility_range_end = lod_m
			if z.view_m > 0.0:
				mmi.visibility_range_end = z.view_m if (far or not far_used) else minf(z.view_m, lod_m)
			add_child(mmi)
		slice_count += 1
