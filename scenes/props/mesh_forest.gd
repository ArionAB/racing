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
## Felia e si GRANULA LOD-ului (distanta se masoara la centrul ei), deci la 90 m
## un copac la 85 m putea fi la detaliu intreg; 60 m strange eroarea la +-42.
@export_range(32.0, 400.0, 1.0, "suffix:m") var slice_m: float = 60.0
## LOD pe distanta, in TREI trepte (masurate pana la centrul AABB-ului feliei,
## deci +-jumatate de felie): pana la `lod_near_m` mesh-ul intreg, pana la
## `lod_m` nivelul MEDIU (~1/3 din indici), dincolo cel mai GROSIER al speciei
## (meshoptimizer, via ImporterMesh.generate_lods; artarul momiji_a 2696 ->
## 806 -> 408 triunghiuri). `lod_m` 0 = fara LOD; `lod_near_m` 0 sau >= lod_m
## = fara treapta medie. Masurat (ProbePerf --mobile, Kyoto): fara LOD valea de
## artari trimitea ~6,5M triunghiuri/cadru; cu o treapta la 60 m si felii de
## 90 m, 2,7-2,8M in valea D fata de 1,34M media pistei — copacii APROPIATI la
## detaliu intreg, nu numarul lor (acelasi numar de desene). Cu trei trepte,
## felia de 60 m si unghiurile importerului la generare: 1,0-1,2M in vale,
## media 0,87M, desenele +3% (26 oct 2026). Fara fade intre trepte: schimbarea
## la 22 m se judeca la volan; `visibility_range_fade_mode` e optiunea.
@export_range(0.0, 400.0, 1.0, "suffix:m") var lod_near_m: float = 22.0
@export_range(0.0, 400.0, 1.0, "suffix:m") var lod_m: float = 50.0
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
## Triunghiurile unei instante pe fiecare treapta de LOD: stem -> [intreg, mediu, grosier].
var tris_by_lod: Dictionary = {}
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
var _species_mid: Dictionary = {}    # stem -> ArrayMesh la nivelul MEDIU (sau acelasi)
var _species_far: Dictionary = {}    # stem -> ArrayMesh la cel mai grosier (sau acelasi)
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
		print("MeshForest %s: %d instante, %d felii, %d triunghiuri totale, %d ms | specii %s | LOD tri/instanta (intreg, mediu, grosier) %s | zone %s | respinse %s" % [
			name, instance_count, slice_count, total_tris, build_ms,
			counts_by_species, tris_by_lod, counts_by_zone, rejected])
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
	_species_mid.clear()
	_species_far.clear()
	_species_tris.clear()
	for ps in scenes:
		if ps == null:
			continue
		var stem := ps.resource_path.get_file().get_basename()
		var mesh := _species_array_mesh(ps, stem, theme)
		if mesh == null:
			push_warning("MeshForest: %s nu are mesh" % stem)
			continue
		var lods := _lod_variants(mesh) if lod_m > 0.0 else {}
		var far: ArrayMesh = lods.get("far", mesh)
		var mid: ArrayMesh = lods.get("mid", mesh)
		# Netezirea coroanei (Palette.SMOOTH_FOLIAGE) DUPA LOD: simplificarea
		# facuta pe normale netede sudeaza varfurile altfel si lasa coroana
		# departata in cioburi plate (vazut pe captura, oct 2026).
		var foliage := Palette.foliage_surfaces(mesh)
		if not foliage.is_empty():
			var smooth := Palette.smoothed_mesh(mesh, foliage)
			far = smooth if far == mesh else Palette.smoothed_mesh(far, foliage)
			mid = smooth if mid == mesh else Palette.smoothed_mesh(mid, foliage)
			mesh = smooth
		_species_mesh[stem] = mesh
		_species_mid[stem] = mid
		_species_far[stem] = far
		var tris := _mesh_tris(mesh)
		_species_tris[stem] = tris
		tris_by_lod[stem] = [tris, _mesh_tris(mid), _mesh_tris(far)]


static func _mesh_tris(mesh: ArrayMesh) -> int:
	var tris := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		tris += (idx as PackedInt32Array).size() / 3 if idx != null \
			else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return tris


## Tinta treptei MEDII de LOD: fractia din indicii mesh-ului intreg pe care o
## cautam printre nivelurile generate (se ia nivelul cel mai apropiat de ea).
const MID_LOD_RATIO: float = 0.33
## Peste fractia asta nivelul „mediu" nu merita o treapta (momiji_b: singurul
## nivel negrosier avea 94% din indici — memorie in plus, zero castig).
const MID_LOD_MAX_RATIO: float = 0.7

## Variantele de departare: acelasi mesh, cu indicii altui nivel LOD
## (ImporterMesh.generate_lods) pe fiecare suprafata care are unul — `far` cu
## cel mai grosier, `mid` cu cel mai apropiat de [constant MID_LOD_RATIO] din
## indicii intregi. Varfurile raman toate (cele nefolosite costa doar memorie);
## materialele se pastreaza. Cheia `mid` lipseste cand specia n-are un nivel
## intermediar care sa merite (sub [constant MID_LOD_MAX_RATIO] din intreg).
##
## Unghiurile sunt ALE IMPORTERULUI (meshes/lods/normal_merge_angle 60,
## normal_split_angle 25), adica ce primeste orice GLB din proiect la import.
## Prima versiune le dadea inversate (25, 60): sudarea mai zgarcita a varfurilor
## lasa coroanele de foi (geometrie deconectata) aproape nesimplificate —
## momiji_c 2696 -> 868 si NICIUN nivel intermediar, ginkgo 3080 -> 914. Cu
## unghiurile importerului: momiji_c 2696 -> 806 -> 188, ginkgo 3080 -> 1640
## -> 436, momiji_b 2160 -> 542 -> 190 (ProbeForest, 26 oct 2026).
static func _lod_variants(src: ArrayMesh) -> Dictionary:
	var im := ImporterMesh.new()
	for si in src.get_surface_count():
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(si), [], {}, src.surface_get_material(si))
	im.generate_lods(60.0, 25.0, [])
	var far := ArrayMesh.new()
	var mid := ArrayMesh.new()
	var full_total := 0
	var mid_total := 0
	for si in src.get_surface_count():
		var arr_far := src.surface_get_arrays(si)
		var arr_mid := src.surface_get_arrays(si)
		var idx: Variant = arr_far[Mesh.ARRAY_INDEX]
		var full_n := (idx as PackedInt32Array).size() if idx != null \
			else (arr_far[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var mid_n := full_n
		var nl := im.get_surface_lod_count(si)
		if nl > 0:
			arr_far[Mesh.ARRAY_INDEX] = im.get_surface_lod_indices(si, nl - 1)
			# Nivelul mediu: dintre cele NEgrosiere, cel cu numarul de indici
			# cel mai apropiat de tinta.
			var best := -1
			var best_err := INF
			for li in nl - 1:
				var ratio := float(im.get_surface_lod_indices(si, li).size()) / maxf(float(full_n), 1.0)
				if ratio > MID_LOD_MAX_RATIO:
					continue
				var err := absf(ratio - MID_LOD_RATIO)
				if err < best_err:
					best_err = err
					best = li
			if best >= 0:
				arr_mid[Mesh.ARRAY_INDEX] = im.get_surface_lod_indices(si, best)
				mid_n = (arr_mid[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
		full_total += full_n
		mid_total += mid_n
		far.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr_far)
		far.surface_set_material(si, src.surface_get_material(si))
		mid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr_mid)
		mid.surface_set_material(si, src.surface_get_material(si))
	var out := {"far": far}
	# Treapta medie se judeca pe SPECIE, nu pe suprafata: un trunchi redus la
	# jumatate sub o coroana ramasa intreaga nu e un nivel mediu.
	if mid_total <= int(MID_LOD_MAX_RATIO * float(full_total)):
		out["mid"] = mid
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
		var pieces: Array = [[src, _part_material(stem, theme, String(mi.name))]]
		var accent: Variant = _split_part(stem, theme, mi, src)
		if accent != null:
			pieces = [[accent[0], pieces[0][1]], [accent[1], accent[2]]]
		for piece: Array in pieces:
			var pm: Mesh = piece[0]
			for si in pm.get_surface_count():
				var st := SurfaceTool.new()
				st.append_from(pm, si, xf)
				out = st.commit(out)
				mats.append(piece[1])
	root.free()
	if out == null:
		return null
	for i in mats.size():
		out.surface_set_material(i, mats[i])
	return out


## Ruptura de accente pe TEMA (`WorldProp.SPLIT_MODELS_BY_THEME` /
## `ACCENT_SPLIT_BY_THEME`), aceeasi ca pe decorul manual: altfel tulpinile de
## bambus din padure ar fi luat clasa pe tot nodul si ar fi pierdut inelele.
## Intoarce [corp, accente, material_accente] sau null daca nu se rupe. Accentul
## ia clasa doar daca e NUMIT explicit in tabele (ca in `_apply_classes_mapping`).
static func _split_part(stem: String, theme: String, mi: MeshInstance3D,
		src: Mesh) -> Variant:
	var models: Dictionary = WorldProp.SPLIT_MODELS_BY_THEME.get(theme, {})
	if not models.has(stem):
		return null
	var rules: Dictionary = WorldProp.ACCENT_SPLIT_BY_THEME.get(theme, {})
	var nm := String(mi.name)
	for prefix: String in rules:
		if not nm.begins_with(prefix):
			continue
		var tmp := MeshInstance3D.new()
		tmp.name = nm
		tmp.mesh = src
		if not Palette.split_accents(tmp, rules[prefix]):
			tmp.free()
			return null
		var acc := tmp.get_node(NodePath(nm + Palette.ACCENT_SUFFIX)) as MeshInstance3D
		var out: Array = [tmp.mesh, acc.mesh, _accent_material(stem, theme,
			nm + Palette.ACCENT_SUFFIX)]
		tmp.free()
		return out
	return null


static func _accent_material(stem: String, theme: String, name: String) -> Material:
	for table: Dictionary in [WorldProp.CLASSES_BY_MODEL,
			WorldProp.CLASSES_BY_THEME.get(theme, {})]:
		if table.has(stem) and (table[stem] as Dictionary).has(name):
			return _part_material(stem, theme, name)
	return Palette.world_material()


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
		# Treptele de LOD ale feliei: [mesh, de la (m), pana la (m; 0 = fara
		# limita)]. Treptele cu acelasi mesh ca precedenta se topesc in ea, deci
		# o specie fara nivel mediu are doua trepte, una fara niciun LOD una.
		var full: ArrayMesh = _species_mesh[stem]
		var steps: Array = [[full, 0.0, 0.0, ""]]
		if lod_m > 0.0:
			var mid: ArrayMesh = _species_mid.get(stem, full)
			if mid != full and lod_near_m > 0.0 and lod_near_m < lod_m:
				steps[-1][2] = lod_near_m
				steps.append([mid, lod_near_m, 0.0, "_mid"])
			var far: ArrayMesh = _species_far.get(stem, full)
			if far != steps[-1][0]:
				steps[-1][2] = lod_m
				steps.append([far, lod_m, 0.0, "_far"])
		for k in steps.size():
			var begin := float(steps[k][1])
			var end := float(steps[k][2])
			if z.view_m > 0.0:
				end = z.view_m if end <= 0.0 else minf(end, z.view_m)
				if begin >= end:
					continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = steps[k][0]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = String(key).replace("|", "_") + String(steps[k][3])
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(g["shadow"]) 				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if begin > 0.0:
				mmi.visibility_range_begin = begin
			if end > 0.0:
				mmi.visibility_range_end = end
			add_child(mmi)
		slice_count += 1
