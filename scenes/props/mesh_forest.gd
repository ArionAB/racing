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
@export_range(32.0, 400.0, 1.0, "suffix:m") var slice_m: float = 60.0
## Felia BENZII APROPIATE (m): arborii la mai putin de `lod_near_m` de marginea
## soselei — singurii de care camera se poate apropia — se felieaza mai fin,
## ca pragul lor de LOD sa nu urce prea mult (vezi `lod_near_m`).
@export_range(10.0, 400.0, 1.0, "suffix:m") var slice_near_m: float = 20.0
## LOD pe distanta, in TREI trepte: mesh-ul intreg pana la `lod_near_m`, nivelul
## MEDIU (~1/3 din indici) pana la `lod_m`, dincolo cel mai GROSIER al speciei
## (meshoptimizer via ImporterMesh.generate_lods, plus prisme pentru tulpini
## si rarirea cardurilor de frunze — vezi `_lod_variants`). `lod_m` 0 = fara
## LOD; `lod_near_m` 0 sau >= lod_m = fara treapta medie.
##
## CE INSEAMNA DISTANTA (27 oct 2026). Godot schimba vizibilitatea unei felii
## dupa distanta pana la CENTRUL AABB-ului ei, toata felia deodata, si pe
## rendererul Mobile fara nicio tranzitie (`visibility_range_fade_mode` merge
## doar pe Forward+). Cu pragurile puse direct pe centru, un copac de langa
## camera isi schimba mesh-ul cand centrul feliei lui trece de prag: la volan
## se vedea ca „apar copaci in timp real" (dezvoltatorul, 27 oct). De aceea
## `lod_near_m` si `lod_m` sunt distantele pana la CEL MAI APROPIAT arbore al
## feliei in momentul schimbarii, nu pana la centru: pragul pe centru e
## `lod_x + intinderea feliei` (distanta maxima centru -> arbore), calculat pe
## felie in `_emit`, iar hysteresis-ul de 1 m opreste palpairea pe prag.
## Arborii pe care camera nu-i poate atinge (la peste `lod_x` de marginea
## soselei) nu au nevoie de marja: pragul lor ramane pe centru.
##
## Masurat (ProbePerf --mobile, Kyoto): fara LOD valea de artari trimitea
## ~6,5M triunghiuri/cadru; o treapta la 60 m pe centru cu felii de 90 m:
## 2,7-2,8M in vale; trei trepte la 22/50 m pe centru, felii de 60 m: 1,0-1,2M
## in vale, media 0,81M, dar schimbarea la 22 m se vedea. Cu pragul la cel mai
## apropiat arbore (27 oct 2026), variantele masurate (media / varful vaii D):
##   32 m, felie 20, mediu 1/2, departe 80 -> 0,81M / 1,78M
##   26 m, felie 20, mediu 1/2, departe 80 -> 0,79M / 1,67M
##   26 m, felie 20, mediu 1/3, departe 80 -> 0,71M / 1,29M
##   32 m, felie 20, mediu 1/3, departe 80 -> 0,71M / 1,35M
##   26 m, felie 20, mediu 1/3, departe 65 -> 0,70M / 1,23M   <- aleasa
## Treapta medie e parghia (nu distanta): la 1/2 valea D trecea de 1,6M.
## Bambusul din G a cazut de la 1,39M la 0,59M prin prisme si rarirea cardurilor.
@export_range(0.0, 400.0, 1.0, "suffix:m") var lod_near_m: float = 26.0
@export_range(0.0, 400.0, 1.0, "suffix:m") var lod_m: float = 65.0
## Tinta treptei MEDII: fractia din indicii mesh-ului intreg pe care o cautam
## printre nivelurile generate (se ia nivelul cel mai apropiat de ea). 0,5 =
## primul nivel al generatorului; 0,33 = al doilea, de doua ori mai ieftin
## (artar 2696 -> 718 in loc de 1348), dar schimbarea la `lod_near_m` se vede
## mai mult. Masurat: la 0,5 valea D trecea de 1,6M triunghiuri (vezi `lod_near_m`).
@export_range(0.2, 0.7, 0.01) var mid_lod_ratio: float = MID_LOD_RATIO_DEFAULT
## CELULELE DE DEPARTE (HLOD, 31 oct 2026). Treapta grosiera feliata ca mai sus
## costa in desene, nu in triunghiuri: banda apropiata e taiata in felii de 20 m,
## deci in valea D se vedeau ~210 felii departate cu 3-5 arbori fiecare (cedrul:
## 123 de desene pentru 7k triunghiuri). Peste felii se pune o celula de
## `far_cell_m` cu aceiasi arbori pe treapta grosiera, un MultiMesh pe specie;
## feliile ii sunt copii prin `visibility_parent`, deci se vad doar cat camera e
## mai aproape de celula decat pragul ei. Pragul e pe acelasi contract ca
## `lod_m`: `lod_m` + intinderea celulei, adica schimbarea se face cand CEL MAI
## APROPIAT arbore e la `lod_m` — exact ce garantau deja feliile. 0 = fara celule.
## Masurat (camera de joc, 24 de puncte, impreuna cu `far_shadow` oprit): valea
## D 683+283 -> 491+209 desene (frac 0,29), 680+260 -> 443+158 (0,375); media
## pe tur 406+182 -> 336+152. Marimea celulei abia conteaza (50 m: 347, 80 m:
## 338, 120 m: 336, 180 m: 338 de desene in medie): ce ramane sunt feliile
## dintre 65 m si pragul celulei, nu celulele. Garda: `ProbeForestFar`.
@export_range(0.0, 400.0, 1.0, "suffix:m") var far_cell_m: float = 120.0
## Treapta FOARTE DEPARTATA a celulelor: de la `xfar_m` (tot pana la cel mai
## apropiat arbore) coroanele devin bulgari — cate o bipiramida pe componenta
## (vezi `_with_blobs`). 0 sau <= `lod_m` = fara treapta.
@export_range(0.0, 400.0, 1.0, "suffix:m") var xfar_m: float = 110.0
## Treapta grosiera arunca umbra (doar pe arborii din `shadow_m` ai zonei). Oprit:
## incepe la `lod_m` (65 m) de cel mai apropiat arbore, iar pe telefon umbra se
## opreste oricum la 55 m (`GameState.SHADOW_DISTANCE_MOBILE`). Celulele nu
## arunca niciodata.
@export var far_shadow: bool = false
## Cat intra trunchiul in pamant (m): relieful palpaie sub radacina.
@export_range(0.0, 1.0, 0.01, "suffix:m") var sink_m: float = 0.25
## Cat de mult mai multa marja fata de o sosea obisnuita cere o scurtatura
## (tunelul de torii isi are deja cedrii lui la 6,6 si 10,4 m).
@export_range(0.0, 20.0, 0.5, "suffix:m") var branch_extra_clear_m: float = 4.0
## Cat de aproape de marginea panzei de teren si a zidului lumii (m).
@export_range(0.0, 60.0, 0.5, "suffix:m") var world_margin_m: float = 12.0
## Treapta GROSIERA nu coboara sub atata din indicii mesh-ului intreg: se ia cel mai grosier
## nivel generat care pastreaza cel putin fractia asta (0 = cel mai grosier, comportamentul
## dintotdeauna). Pe castanul Carrara (Track23, POI G, 31 oct 2026) nivelul cel mai grosier
## (188 de triunghiuri din 4244) topea coroana in cioburi: dincolo de 65 m padurea citea crengi
## goale cu frunze plutind (A/B pe captura cu `--forest-far=400`).
@export_range(0.0, 0.5, 0.01) var far_lod_min_ratio: float = 0.0
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
## MultiMesh-urile celulelor de departe (toate treptele, toate speciile).
var hlod_count: int = 0
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
var _species_xfar: Dictionary = {}   # stem -> ArrayMesh cu bulgari (sau acelasi cu far)
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
	# A/B din sonde (ProbePerf), fara sa editam scena: --forest-near=, --forest-far=,
	# --forest-slice-near=, --forest-mid-ratio=, --forest-far-cell=, --forest-xfar=,
	# --forest-far-shadow=0/1. Doar pe sesiune.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--forest-far-cell="):
			far_cell_m = float(a.trim_prefix("--forest-far-cell="))
		elif a.begins_with("--forest-xfar="):
			xfar_m = float(a.trim_prefix("--forest-xfar="))
		elif a.begins_with("--forest-far-shadow="):
			far_shadow = a.trim_prefix("--forest-far-shadow=") == "1"
		if a.begins_with("--forest-near="):
			lod_near_m = float(a.trim_prefix("--forest-near="))
		elif a.begins_with("--forest-far="):
			lod_m = float(a.trim_prefix("--forest-far="))
		elif a.begins_with("--forest-slice-near="):
			slice_near_m = float(a.trim_prefix("--forest-slice-near="))
		elif a.begins_with("--forest-mid-ratio="):
			mid_lod_ratio = float(a.trim_prefix("--forest-mid-ratio="))
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
		print("MeshForest %s: %d instante, %d felii, %d MultiMesh de celule, %d triunghiuri totale, %d ms | specii %s | LOD tri/instanta (intreg, mediu, grosier, bulgari) %s | zone %s | respinse %s" % [
			name, instance_count, slice_count, hlod_count, total_tris, build_ms,
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
	_species_xfar.clear()
	_species_tris.clear()
	for ps in scenes:
		if ps == null:
			continue
		var stem := ps.resource_path.get_file().get_basename()
		var levels := _species_meshes(ps, stem, theme)
		var mesh: ArrayMesh = levels.get("full", null)
		if mesh == null:
			push_warning("MeshForest: %s nu are mesh" % stem)
			continue
		var far: ArrayMesh = levels.get("far", mesh)
		var mid: ArrayMesh = levels.get("mid", mesh)
		# Treapta medie se judeca pe SPECIE, nu pe nod: un trunchi redus la
		# jumatate sub o coroana ramasa intreaga nu e un nivel mediu.
		if mid != mesh and _mesh_tris(mid) > int(MID_LOD_MAX_RATIO * float(_mesh_tris(mesh))):
			mid = mesh
		if far != mesh and _mesh_tris(far) >= _mesh_tris(mesh):
			far = mesh
		# Bulgarii pornesc de la treapta grosiera (trunchiul si tulpinile raman
		# ale ei) si se fac INAINTE de netezire, ca normala bipiramidei sa iasa
		# din aceeasi mediere pe pozitie ca a coroanei grosiere.
		var xfar := _blob_mesh(far) if far != mesh else far
		# Netezirea coroanei (Palette.SMOOTH_FOLIAGE) DUPA LOD: simplificarea
		# facuta pe normale netede sudeaza varfurile altfel si lasa coroana
		# departata in cioburi plate (vazut pe captura, oct 2026).
		# Suprafetele se cauta pe FIECARE treapta (dupa material): treapta
		# departata poate avea mai putine suprafete decat cea intreaga (fara
		# inelele rupte), deci indicii nu se transfera intre ele.
		var foliage := Palette.foliage_surfaces(mesh)
		if not foliage.is_empty():
			var smooth := Palette.smoothed_mesh(mesh, foliage)
			var far_s: ArrayMesh = smooth if far == mesh else Palette.smoothed_mesh(far, Palette.foliage_surfaces(far))
			xfar = far_s if xfar == far else Palette.smoothed_mesh(xfar, Palette.foliage_surfaces(xfar))
			far = far_s
			mid = smooth if mid == mesh else Palette.smoothed_mesh(mid, Palette.foliage_surfaces(mid))
			mesh = smooth
		_species_mesh[stem] = mesh
		_species_mid[stem] = mid
		_species_far[stem] = far
		_species_xfar[stem] = xfar
		var tris := _mesh_tris(mesh)
		_species_tris[stem] = tris
		tris_by_lod[stem] = [tris, _mesh_tris(mid), _mesh_tris(far), _mesh_tris(xfar)]


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
## Vezi `mid_lod_ratio`.
const MID_LOD_RATIO_DEFAULT: float = 0.33
## Peste fractia asta nivelul „mediu" nu merita o treapta (momiji_b: singurul
## nivel negrosier avea 94% din indici — memorie in plus, zero castig).
const MID_LOD_MAX_RATIO: float = 0.7
## Hysteresis-ul pragurilor de LOD (m) si cat creste AABB-ul comun al feliei
## peste uniunea instantelor (simplificarea poate muta un vertex putin in afara).
const LOD_HYSTERESIS_M: float = 1.0
const LOD_AABB_GROW_M: float = 0.5

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
##
## DOUA FORME PE CARE meshoptimizer NU LE POATE REDUCE (27 oct 2026, bambusul
## din G: 768k triunghiuri/cadru la 0,70 doar din tulpini, 513k din coroane):
##   - TULPINILE (componente conexe inalte si subtiri: `moso_culm` 292 -> 220,
##     cele 9 tulpini din `bamboo_crown` deloc) — inelele cu muchii dure sunt
##     granite pentru simplificator. De la 32 m o tulpina de 15 cm are 2-5 px
##     latime, deci devine o PRISMA cu 3 fete (6 triunghiuri), cu culoarea si
##     slotul ei medii; crengile mici raman pe nivelul generat.
##   - CARDURILE DE FRUNZE (zeci de componente mici, `bamboo_crown` 54 x 20):
##     simplificarea le topeste in cioburi; de la distanta coroana citeste la
##     fel cu o parte din carduri, deci se RARESC: mediu 1 din 2, departe 1 din 3.
## Coroanele de artar/ginkgo (9 componente de 280-320) raman pe generator.
static func _lod_variants(src: Mesh, mid_ratio: float = MID_LOD_RATIO_DEFAULT,
		far_min_ratio: float = 0.0) -> Dictionary:
	var im := ImporterMesh.new()
	for si in src.get_surface_count():
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(si), [], {}, src.surface_get_material(si))
	im.generate_lods(MeshCpu.LOD_MERGE_DEG, MeshCpu.LOD_SPLIT_DEG, [])
	var far := ArrayMesh.new()
	var mid := ArrayMesh.new()
	var full_total := 0
	var mid_total := 0
	for si in src.get_surface_count():
		var arr := src.surface_get_arrays(si)
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		var full_n := (idx as PackedInt32Array).size() if idx != null \
			else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var far_idx: PackedInt32Array = idx if idx != null else PackedInt32Array()
		var mid_idx: PackedInt32Array = far_idx
		var nl := im.get_surface_lod_count(si)
		if nl > 0:
			far_idx = im.get_surface_lod_indices(si, nl - 1)
			# `far_lod_min_ratio`: cel mai grosier nivel care pastreaza macar fractia ceruta.
			if far_min_ratio > 0.0:
				for li in range(nl - 1, -1, -1):
					var li_idx := im.get_surface_lod_indices(si, li)
					if float(li_idx.size()) / maxf(float(full_n), 1.0) >= far_min_ratio:
						far_idx = li_idx
						break
			# Nivelul mediu: dintre cele NEgrosiere, cel cu numarul de indici
			# cel mai apropiat de tinta.
			var best := -1
			var best_err := INF
			for li in nl - 1:
				var ratio := float(im.get_surface_lod_indices(si, li).size()) / maxf(float(full_n), 1.0)
				if ratio > MID_LOD_MAX_RATIO:
					continue
				var err := absf(ratio - mid_ratio)
				if err < best_err:
					best_err = err
					best = li
			if best >= 0:
				mid_idx = im.get_surface_lod_indices(si, best)
		var arr_far := arr.duplicate()
		var arr_mid := arr.duplicate()
		if idx != null and full_n >= 24:
			var comps := _components(arr)
			var stalks: PackedInt32Array = comps["stalks"]
			if comps["cards"] == true:
				arr_far = _every_nth_component(arr, comps, CARD_FAR_EVERY)
				arr_mid = _every_nth_component(arr, comps, CARD_MID_EVERY)
			elif not stalks.is_empty():
				arr_far = _with_prisms(arr, comps, far_idx)
				arr_mid = _with_prisms(arr, comps, mid_idx)
			else:
				arr_far[Mesh.ARRAY_INDEX] = far_idx
				arr_mid[Mesh.ARRAY_INDEX] = mid_idx
		else:
			arr_far[Mesh.ARRAY_INDEX] = far_idx
			arr_mid[Mesh.ARRAY_INDEX] = mid_idx
		full_total += full_n
		mid_total += (arr_mid[Mesh.ARRAY_INDEX] as PackedInt32Array).size() \
			if arr_mid[Mesh.ARRAY_INDEX] != null else full_n
		far.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr_far)
		far.surface_set_material(si, src.surface_get_material(si))
		mid.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr_mid)
		mid.surface_set_material(si, src.surface_get_material(si))
	var out := {}
	if _mesh_tris(far) < full_total / 3:
		out["far"] = far
	if mid_total <= int(MID_LOD_MAX_RATIO * float(full_total)):
		out["mid"] = mid
	return out


## O componenta e TULPINA daca e de cel putin atatea ori mai inalta decat lata
## si are destule triunghiuri ca sa fie un cilindru, nu o creanga.
const STALK_ASPECT: float = 6.0
const STALK_MIN_TRIS: int = 24
## O suprafata e din CARDURI daca are cel putin atatea componente, toate mici.
const CARDS_MIN_COMPONENTS: int = 12
const CARDS_MAX_TRIS: int = 40
const CARD_MID_EVERY: int = 2
const CARD_FAR_EVERY: int = 3
## Raza prismei fata de raza mediana a tulpinii: un triunghi echilateral cu
## raza circumscrisa R are latimea proiectata medie ~1,6 R, cilindrul 2 r.
const PRISM_RADIUS_GAIN: float = 1.25
const PRISM_SIDES: int = 3

## Componentele conexe ale unei suprafete (sudura pe pozitie la 5 mm): pentru
## fiecare triunghi componenta lui, iar pentru fiecare componenta numarul de
## triunghiuri si cutia. Plus clasificarea: tulpinile si „e din carduri".
static func _components(arr: Array) -> Dictionary:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var pos_id := {}
	var remap := PackedInt32Array()
	remap.resize(v.size())
	for i in v.size():
		var k := Vector3i((v[i] * 200.0).round())
		if not pos_id.has(k):
			pos_id[k] = pos_id.size()
		remap[i] = pos_id[k]
	var parent := PackedInt32Array()
	parent.resize(pos_id.size())
	for i in parent.size():
		parent[i] = i
	var tri_n := idx.size() / 3
	for t in tri_n:
		var a := remap[idx[3 * t]]
		_uf_union(parent, a, remap[idx[3 * t + 1]])
		_uf_union(parent, a, remap[idx[3 * t + 2]])
	var comp_id := {}
	var comp_of_tri := PackedInt32Array()
	comp_of_tri.resize(tri_n)
	var tris: PackedInt32Array = []
	var mins: Array[Vector3] = []
	var maxs: Array[Vector3] = []
	for t in tri_n:
		var r := _uf_find(parent, remap[idx[3 * t]])
		if not comp_id.has(r):
			comp_id[r] = comp_id.size()
			tris.append(0)
			mins.append(v[idx[3 * t]])
			maxs.append(v[idx[3 * t]])
		var c: int = comp_id[r]
		comp_of_tri[t] = c
		tris[c] += 1
		for j in 3:
			var p := v[idx[3 * t + j]]
			mins[c] = mins[c].min(p)
			maxs[c] = maxs[c].max(p)
	var stalks := PackedInt32Array()
	var max_tris := 0
	for c in tris.size():
		max_tris = maxi(max_tris, tris[c])
		var sz := maxs[c] - mins[c]
		if tris[c] >= STALK_MIN_TRIS and sz.y > STALK_ASPECT * maxf(sz.x, sz.z):
			stalks.append(c)
	return {
		"comp_of_tri": comp_of_tri, "tris": tris, "mins": mins, "maxs": maxs,
		"stalks": stalks,
		"cards": tris.size() >= CARDS_MIN_COMPONENTS and max_tris <= CARDS_MAX_TRIS,
	}


static func _uf_find(p: PackedInt32Array, i: int) -> int:
	while p[i] != i:
		p[i] = p[p[i]]
		i = p[i]
	return i


static func _uf_union(p: PackedInt32Array, a: int, b: int) -> void:
	var ra := _uf_find(p, a)
	var rb := _uf_find(p, b)
	if ra != rb:
		p[ra] = rb


## Aceleasi array-uri, cu doar triunghiurile componentelor 0, n, 2n, ...
static func _every_nth_component(arr: Array, comps: Dictionary, n: int) -> Array:
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var comp_of_tri: PackedInt32Array = comps["comp_of_tri"]
	var out_idx := PackedInt32Array()
	for t in comp_of_tri.size():
		if comp_of_tri[t] % n == 0:
			out_idx.append(idx[3 * t])
			out_idx.append(idx[3 * t + 1])
			out_idx.append(idx[3 * t + 2])
	var out := arr.duplicate()
	out[Mesh.ARRAY_INDEX] = out_idx
	return out


## Array-urile cu tulpinile inlocuite de prisme: triunghiurile nivelului
## `base_idx` care NU sunt pe o tulpina raman (indicii nivelului arata spre
## vertecsii originali, iar o colapsare de muchie nu trece dintr-o componenta
## in alta, deci componenta unui triunghi simplificat e cea a primului lui
## vertex), iar fiecare tulpina devine o prisma cu [constant PRISM_SIDES] fete
## pe axa ei (centrul bazei -> centrul varfului), cu raza mediana a vertecsilor
## fata de axa, culoarea si UV-ul medii ale componentei.
static func _with_prisms(arr: Array, comps: Dictionary, base_idx: PackedInt32Array) -> Array:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var full_idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var comp_of_tri: PackedInt32Array = comps["comp_of_tri"]
	var stalks: PackedInt32Array = comps["stalks"]
	# Componenta fiecarui VERTEX (dupa triunghiurile intregi care il folosesc).
	var comp_of_vertex := PackedInt32Array()
	comp_of_vertex.resize(v.size())
	comp_of_vertex.fill(-1)
	for t in comp_of_tri.size():
		for j in 3:
			comp_of_vertex[full_idx[3 * t + j]] = comp_of_tri[t]
	var is_stalk := {}
	for c in stalks:
		is_stalk[c] = true
	var out_idx := PackedInt32Array()
	for t in base_idx.size() / 3:
		var c := comp_of_vertex[base_idx[3 * t]]
		if is_stalk.has(c):
			continue
		out_idx.append(base_idx[3 * t])
		out_idx.append(base_idx[3 * t + 1])
		out_idx.append(base_idx[3 * t + 2])
	var out := arr.duplicate()
	var nv: PackedVector3Array = v.duplicate()
	var normals: PackedVector3Array = (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate() \
		if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var tangents: PackedFloat32Array = (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).duplicate() \
		if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var colors: PackedColorArray = (arr[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate() \
		if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var uvs: PackedVector2Array = (arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array).duplicate() \
		if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var uv2s: PackedVector2Array = (arr[Mesh.ARRAY_TEX_UV2] as PackedVector2Array).duplicate() \
		if arr[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	for c in stalks:
		# Vertecsii componentei, o singura data (cei sudati pe pozitie numara o data).
		var members := PackedInt32Array()
		for i in v.size():
			if comp_of_vertex[i] == c:
				members.append(i)
		if members.is_empty():
			continue
		var lo: Vector3 = (comps["mins"] as Array)[c]
		var hi: Vector3 = (comps["maxs"] as Array)[c]
		var h := hi.y - lo.y
		var bottom := Vector3.ZERO
		var top := Vector3.ZERO
		var nb := 0
		var nt := 0
		var col := Color(0, 0, 0, 0)
		var uv := Vector2.ZERO
		var uv2 := Vector2.ZERO
		for i in members:
			if v[i].y < lo.y + 0.15 * h:
				bottom += v[i]
				nb += 1
			if v[i].y > hi.y - 0.15 * h:
				top += v[i]
				nt += 1
			if not colors.is_empty():
				col += colors[i]
			if not uvs.is_empty():
				uv += uvs[i]
			if not uv2s.is_empty():
				uv2 += uv2s[i]
		bottom /= maxf(float(nb), 1.0)
		top /= maxf(float(nt), 1.0)
		col /= float(members.size())
		uv /= float(members.size())
		uv2 /= float(members.size())
		var axis := (top - bottom)
		if axis.length() < 0.05:
			axis = Vector3.UP * maxf(h, 0.05)
		var dir := axis.normalized()
		var dists := PackedFloat32Array()
		for i in members:
			var rel := v[i] - bottom
			dists.append((rel - dir * rel.dot(dir)).length())
		dists.sort()
		var r := maxf(dists[dists.size() / 2], 0.02) * PRISM_RADIUS_GAIN
		var side := dir.cross(Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var side2 := dir.cross(side).normalized()
		var base := nv.size()
		for ring in 2:
			var center := bottom if ring == 0 else bottom + axis
			for k in PRISM_SIDES:
				var ang := TAU * float(k) / float(PRISM_SIDES)
				var radial := (side * cos(ang) + side2 * sin(ang)).normalized()
				nv.append(center + radial * r)
				if not normals.is_empty():
					normals.append(radial)
				if not tangents.is_empty():
					var tg := dir
					tangents.append_array(PackedFloat32Array([tg.x, tg.y, tg.z, 1.0]))
				if not colors.is_empty():
					colors.append(col)
				if not uvs.is_empty():
					uvs.append(uv)
				if not uv2s.is_empty():
					uv2s.append(uv2)
		for k in PRISM_SIDES:
			var k2 := (k + 1) % PRISM_SIDES
			var b0 := base + k
			var b1 := base + k2
			var t0 := base + PRISM_SIDES + k
			var t1 := base + PRISM_SIDES + k2
			# Sensul fetei: normala triunghiului trebuie sa iasa din axa.
			var outward := nv[b0] + nv[b1] + nv[t0] - 3.0 * (bottom + axis * 0.5)
			var n_tri := (nv[b1] - nv[b0]).cross(nv[t0] - nv[b0])
			if n_tri.dot(outward) >= 0.0:
				out_idx.append_array(PackedInt32Array([b0, b1, t0, b1, t1, t0]))
			else:
				out_idx.append_array(PackedInt32Array([b0, t0, b1, b1, t0, t1]))
	out[Mesh.ARRAY_VERTEX] = nv
	if not normals.is_empty():
		out[Mesh.ARRAY_NORMAL] = normals
	if not tangents.is_empty():
		out[Mesh.ARRAY_TANGENT] = tangents
	if not colors.is_empty():
		out[Mesh.ARRAY_COLOR] = colors
	if not uvs.is_empty():
		out[Mesh.ARRAY_TEX_UV] = uvs
	if not uv2s.is_empty():
		out[Mesh.ARRAY_TEX_UV2] = uv2s
	out[Mesh.ARRAY_INDEX] = out_idx
	return out


## Fetele bipiramidei care inlocuieste o componenta de coroana pe treapta de
## bulgari: 2 x BLOB_SIDES triunghiuri (6 -> 12, fata de ~20-40 cat lasa
## generatorul pe o componenta de artar). Raza fata de semi-latura cutiei
## componentei: o bipiramida hexagonala vazuta din lateral acopera ~1,87 a*b,
## elipsa ~3,14 a*b, dar coroana grosiera nu umple cutia — castigul se
## potriveste pe silueta masurata, nu pe calcul (vezi `ProbeForestFar`): la
## 1,1 bulgarii acopereau 0,87-0,94 din grosier, la 1,2 acopera 0,98-1,02.
## Triunghiuri pe arbore, grosier -> bulgari: momiji_a 348 -> 124, momiji_b
## 242 -> 112, momiji_c 212 -> 100, ginkgo 484 -> 112.
const BLOB_SIDES: int = 6
const BLOB_GAIN: float = 1.2
## O componenta mai mica (in triunghiuri, pe treapta grosiera) ramane cum e.
const BLOB_MIN_TRIS: int = 2 * BLOB_SIDES + 1

## Treapta de bulgari a unei specii: pe suprafetele de coroana
## (`Palette.foliage_surfaces`), fiecare componenta destul de mare devine o
## bipiramida; trunchiul, tulpinile si cardurile raman ale treptei grosiere.
## Intoarce chiar `far` daca nu castiga nimic.
static func _blob_mesh(far: ArrayMesh, gain: float = BLOB_GAIN) -> ArrayMesh:
	var foliage := Palette.foliage_surfaces(far)
	if foliage.is_empty():
		return far
	var out := ArrayMesh.new()
	var changed := false
	for si in far.get_surface_count():
		var arr := far.surface_get_arrays(si)
		if foliage.has(si):
			var b: Variant = _with_blobs(arr, gain)
			if b != null:
				arr = b
				changed = true
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(si, far.surface_get_material(si))
	if not changed or _mesh_tris(out) >= _mesh_tris(far):
		return far
	return out


## Array-urile cu componentele de coroana inlocuite de bipiramide pe axa Y a
## cutiei lor. Fiecare varf nou ia culoarea si UV-urile varfului componentei
## cel mai apropiat de el: varful de jos ramane in AO-ul de sub coroana, cel de
## sus in lumina — media pe componenta ar fi sters gradientul. null = nimic de
## inlocuit (sau array-uri pe care nu stim sa le prelungim).
static func _with_blobs(arr: Array, gain: float = BLOB_GAIN) -> Variant:
	if arr[Mesh.ARRAY_INDEX] == null:
		return null
	for a in [Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS, Mesh.ARRAY_CUSTOM0,
			Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
		if arr[a] != null:
			return null
	var comps := _components(arr)
	if comps["cards"] == true:
		return null
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var comp_of_tri: PackedInt32Array = comps["comp_of_tri"]
	var tris: PackedInt32Array = comps["tris"]
	var is_stalk := {}
	for c in (comps["stalks"] as PackedInt32Array):
		is_stalk[c] = true
	var members := {}   # componenta -> PackedInt32Array de varfuri folosite
	for t in comp_of_tri.size():
		var c := comp_of_tri[t]
		if tris[c] < BLOB_MIN_TRIS or is_stalk.has(c):
			continue
		var m: PackedInt32Array = members.get(c, PackedInt32Array())
		for j in 3:
			m.append(idx[3 * t + j])
		members[c] = m
	if members.is_empty():
		return null
	var out_idx := PackedInt32Array()
	for t in comp_of_tri.size():
		if not members.has(comp_of_tri[t]):
			out_idx.append_array(PackedInt32Array([idx[3 * t], idx[3 * t + 1], idx[3 * t + 2]]))
	var out := arr.duplicate()
	var nv: PackedVector3Array = v.duplicate()
	var normals: PackedVector3Array = (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate() \
		if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var tangents: PackedFloat32Array = (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).duplicate() \
		if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var colors: PackedColorArray = (arr[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate() \
		if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var uvs: PackedVector2Array = (arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array).duplicate() \
		if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var uv2s: PackedVector2Array = (arr[Mesh.ARRAY_TEX_UV2] as PackedVector2Array).duplicate() \
		if arr[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	var keys := members.keys()
	keys.sort()
	for c: int in keys:
		var m: PackedInt32Array = members[c]
		var lo := v[m[0]]
		var hi := v[m[0]]
		for i in m:
			lo = lo.min(v[i])
			hi = hi.max(v[i])
		var center := (lo + hi) * 0.5
		var half := (hi - lo) * 0.5 * gain
		# Varfurile: 0 = sus, 1 = jos, 2.. = inelul la mijloc.
		var pts: Array[Vector3] = [center + Vector3(0.0, half.y, 0.0), center - Vector3(0.0, half.y, 0.0)]
		for k in BLOB_SIDES:
			var ang := TAU * float(k) / float(BLOB_SIDES)
			pts.append(center + Vector3(cos(ang) * half.x, 0.0, sin(ang) * half.z))
		var base := nv.size()
		for p in pts:
			var best := m[0]
			var best_d := INF
			for i in m:
				var d := v[i].distance_squared_to(p)
				if d < best_d:
					best_d = d
					best = i
			nv.append(p)
			var radial := (p - center) / Vector3(maxf(half.x, 0.01), maxf(half.y, 0.01), maxf(half.z, 0.01))
			radial = radial.normalized()
			if not normals.is_empty():
				normals.append(radial)
			if not tangents.is_empty():
				var tg := Vector3.UP.cross(radial)
				tg = tg.normalized() if tg.length_squared() > 1e-6 else Vector3.RIGHT
				tangents.append_array(PackedFloat32Array([tg.x, tg.y, tg.z, 1.0]))
			if not colors.is_empty():
				colors.append(colors[best])
			if not uvs.is_empty():
				uvs.append(uvs[best])
			if not uv2s.is_empty():
				uv2s.append(uv2s[best])
		for k in BLOB_SIDES:
			var r0 := base + 2 + k
			var r1 := base + 2 + (k + 1) % BLOB_SIDES
			for apex in [base, base + 1]:
				# Sensul fetei ca la prisme: normala triunghiului iese din centru.
				var outward := nv[apex] + nv[r0] + nv[r1] - 3.0 * center
				var n_tri := (nv[r0] - nv[apex]).cross(nv[r1] - nv[apex])
				if n_tri.dot(outward) >= 0.0:
					out_idx.append_array(PackedInt32Array([apex, r0, r1]))
				else:
					out_idx.append_array(PackedInt32Array([apex, r1, r0]))
	out[Mesh.ARRAY_VERTEX] = nv
	if not normals.is_empty():
		out[Mesh.ARRAY_NORMAL] = normals
	if not tangents.is_empty():
		out[Mesh.ARRAY_TANGENT] = tangents
	if not colors.is_empty():
		out[Mesh.ARRAY_COLOR] = colors
	if not uvs.is_empty():
		out[Mesh.ARRAY_TEX_UV] = uvs
	if not uv2s.is_empty():
		out[Mesh.ARRAY_TEX_UV2] = uv2s
	out[Mesh.ARRAY_INDEX] = out_idx
	return out


## UN ArrayMesh per specie SI PER TREAPTA DE LOD: o suprafata per
## `MeshInstance3D` (plus una pentru accentele rupte), cu transformul nodului
## COPT in varfuri (un MultiMesh nu stie de ierarhia din care vine mesh-ul) si
## materialul clasei ei. Intoarce {"full", "mid", "far"} (mid/far pot fi
## acelasi obiect cu full cand nodul n-are nivel).
##
## LOD-UL SE FACE PE NODUL INTREG, INAINTEA RUPERII ACCENTELOR: inelele de
## bambus rupte pe alta suprafata taie tulpina in segmente scurte, si pe
## segmente niciun test de „inalt si subtire" nu mai vede o tulpina (vazut
## 27 oct 2026: moso_culm ramanea 292 -> 292 -> 108). Fiecare treapta se rupe
## apoi separat; treapta departata, care n-are inele, iese cu o suprafata mai
## putin — e normal, suprafetele unei trepte sunt ale ei.
func _species_meshes(ps: PackedScene, stem: String, theme: String) -> Dictionary:
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
	var outs := {"full": null, "mid": null, "far": null}
	var mats := {"full": [] as Array[Material], "mid": [] as Array[Material], "far": [] as Array[Material]}
	var any_lod := false
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
		var levels := {"full": src, "mid": src, "far": src}
		if lod_m > 0.0:
			var lv := _lod_variants(src, mid_lod_ratio, far_lod_min_ratio)
			levels["mid"] = lv.get("mid", src)
			levels["far"] = lv.get("far", src)
			any_lod = any_lod or levels["mid"] != src or levels["far"] != src
		for level: String in levels:
			var pm_src: Mesh = levels[level]
			var pieces: Array = [[pm_src, _part_material(stem, theme, String(mi.name))]]
			var accent: Variant = _split_part(stem, theme, mi, pm_src)
			if accent != null:
				pieces = [[accent[0], pieces[0][1]], [accent[1], accent[2]]]
			for piece: Array in pieces:
				var pm: Mesh = piece[0]
				for si in pm.get_surface_count():
					var st := SurfaceTool.new()
					st.append_from(pm, si, xf)
					outs[level] = st.commit(outs[level])
					(mats[level] as Array[Material]).append(piece[1])
	root.free()
	if outs["full"] == null:
		return {}
	for level: String in outs:
		var out: ArrayMesh = outs[level]
		var ml: Array[Material] = mats[level]
		for i in ml.size():
			out.surface_set_material(i, ml[i])
	if not any_lod:
		outs["mid"] = outs["full"]
		outs["far"] = outs["full"]
	return outs


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
		# Banda apropiata (camera poate ajunge la `lod_near_m` de arbore) se
		# felieaza mai fin — vezi `slice_near_m` / `lod_near_m`.
		var near := lod_m > 0.0 and edge < lod_near_m
		var sm := slice_near_m if near else slice_m
		var cell := Vector2i(floori(c.x / sm), floori(c.y / sm))
		var key := "%d|%d|%d|%s|%d|%d" % [zi, cell.x, cell.y, stem, 1 if shadow else 0, 1 if near else 0]
		if not groups.has(key):
			# Array tipizat, nu Packed*Array: un Packed citit din Dictionary e o
			# COPIE, iar append-ul pe ea nu ajunge in grup (memoria
			# `append-pe-copie-in-array-netipizat`; vezi si `_add_segment`).
			groups[key] = {"zone": zi, "stem": stem, "shadow": shadow,
				"xf": [] as Array[Transform3D], "edge": [] as Array[float]}
		(groups[key]["xf"] as Array[Transform3D]).append(xf)
		(groups[key]["edge"] as Array[float]).append(edge)
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
	hlod_count = 0
	# Celulele de departe: "zona|cx|cz" -> arborii lor pe specie si MultiMesh-urile
	# feliilor care le devin copii (vezi `far_cell_m`).
	var cells: Dictionary = {}
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
		# AABB-ul feliei (uniunea AABB-urilor instantelor, cu mesh-ul intreg) si
		# intinderea ei: cat de departe de centru poate fi un arbore al feliei
		# pe care camera il poate atinge. Pragul pe centru = distanta ceruta
		# pana la cel mai apropiat arbore + intinderea (vezi `lod_near_m`).
		# Acelasi `custom_aabb` pe toate treptele: Godot masoara distanta pana
		# la centrul AABB-ului INSTANTEI, iar mesh-urile simplificate au alt
		# AABB — doua centre diferite ar lasa o fasie fara niciun mesh (sau cu
		# doua) la fiecare prag.
		var edges: Array[float] = g["edge"]
		var box := full.get_aabb()
		var union := xfs[0] * box
		for i in range(1, xfs.size()):
			union = union.merge(xfs[i] * box)
		var cen := union.get_center()
		var ext_near := 0.0
		var ext_far := 0.0
		for i in xfs.size():
			var d := cen.distance_to((xfs[i] * box).get_center())
			if edges[i] < lod_near_m:
				ext_near = maxf(ext_near, d)
			if edges[i] < lod_m:
				ext_far = maxf(ext_far, d)
		var steps: Array = [[full, 0.0, 0.0, ""]]
		if lod_m > 0.0:
			var mid: ArrayMesh = _species_mid.get(stem, full)
			if mid != full and lod_near_m > 0.0 and lod_near_m < lod_m:
				steps[-1][2] = lod_near_m + ext_near
				steps.append([mid, lod_near_m + ext_near, 0.0, "_mid"])
			var far: ArrayMesh = _species_far.get(stem, full)
			if far != steps[-1][0]:
				steps[-1][2] = lod_m + ext_far
				steps.append([far, lod_m + ext_far, 0.0, "_far"])
		var kids: Array[MultiMeshInstance3D] = []
		for k in steps.size():
			var begin := float(steps[k][1])
			var end := float(steps[k][2])
			if z.view_m > 0.0:
				end = z.view_m if end <= 0.0 else minf(end, z.view_m)
				if begin >= end:
					continue
			var shadow := bool(g["shadow"]) and (far_shadow or String(steps[k][3]) != "_far")
			var mmi := _slice_mmi(String(key).replace("|", "_") + String(steps[k][3]),
				steps[k][0], xfs, union, begin, end, shadow)
			add_child(mmi)
			kids.append(mmi)
		slice_count += 1
		# Doar feliile care ajung pe treapta grosiera intra in celula: una fara
		# LOD s-ar vedea intreaga pana la `view_m` si in celula ar fi grosiera.
		if far_cell_m > 0.0 and steps.size() > 1 and String(steps[-1][3]) == "_far" \
				and not kids.is_empty() and kids[-1].name.ends_with("_far"):
			var ck := "%d|%d|%d" % [int(g["zone"]), floori(cen.x / far_cell_m), floori(cen.z / far_cell_m)]
			if not cells.has(ck):
				cells[ck] = {"zone": int(g["zone"]), "xf": {}, "edge": {},
					"kids": [] as Array[MultiMeshInstance3D]}
			var cell: Dictionary = cells[ck]
			if not (cell["xf"] as Dictionary).has(stem):
				cell["xf"][stem] = [] as Array[Transform3D]
				cell["edge"][stem] = [] as Array[float]
			(cell["xf"][stem] as Array[Transform3D]).append_array(xfs)
			(cell["edge"][stem] as Array[float]).append_array(edges)
			(cell["kids"] as Array[MultiMeshInstance3D]).append_array(kids)
	var cks := cells.keys()
	cks.sort()
	for ck in cks:
		_emit_cell(String(ck), cells[ck])


## Un MultiMesh de felie (sau de celula) cu pragurile lui de vizibilitate.
func _slice_mmi(nm: String, mesh: Mesh, xfs: Array[Transform3D], union: AABB,
		begin: float, end: float, shadow: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.custom_aabb = union.grow(LOD_AABB_GROW_M)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Hysteresis (pe Mobile `fade_mode` DISABLED = margini de hysteresis):
	# pragul se trece la +1 m la indepartare si la -1 m la apropiere,
	# deci o camera care sta pe prag nu palpaie intre doua mesh-uri.
	if begin > 0.0:
		mmi.visibility_range_begin = begin
		mmi.visibility_range_begin_margin = LOD_HYSTERESIS_M
	if end > 0.0:
		mmi.visibility_range_end = end
		mmi.visibility_range_end_margin = LOD_HYSTERESIS_M
	return mmi


## Celula de departe: un MultiMesh pe specie cu toti arborii ei pe treapta
## grosiera, de la `lod_m` + intinderea celulei, iar peste el (daca `xfar_m`
## o cere) acelasi lucru cu bulgari de la `xfar_m` + intindere. Lantul de
## `visibility_parent`: felie -> celula grosiera -> celula de bulgari; Godot
## arata un nod doar cat parintele lui e ascuns FIINDCA e mai aproape decat
## `visibility_range_begin` al lui, deci la orice distanta se vede exact un nivel.
## Toate speciile unei trepte au aceeasi cutie (a celulei), deci acelasi centru
## si acelasi prag: comuta impreuna, si oricare poate fi parintele.
func _emit_cell(ck: String, cell: Dictionary) -> void:
	var z := zones[int(cell["zone"])]
	var stems: Array = (cell["xf"] as Dictionary).keys()
	stems.sort()
	var union := AABB()
	var first := true
	for stem: String in stems:
		var box := (_species_mesh[stem] as ArrayMesh).get_aabb()
		for xf: Transform3D in cell["xf"][stem]:
			union = xf * box if first else union.merge(xf * box)
			first = false
	var cen := union.get_center()
	# Intinderea, ca la felii: doar arborii de care camera se poate apropia.
	var ext := 0.0
	for stem: String in stems:
		var box := (_species_mesh[stem] as ArrayMesh).get_aabb()
		var xfs: Array[Transform3D] = cell["xf"][stem]
		var edges: Array[float] = cell["edge"][stem]
		for i in xfs.size():
			if edges[i] < lod_m:
				ext = maxf(ext, cen.distance_to((xfs[i] * box).get_center()))
	var levels: Array = [[_species_far, lod_m + ext, "_celula"]]
	if xfar_m > lod_m:
		levels.append([_species_xfar, xfar_m + ext, "_bulgari"])
	var children: Array[MultiMeshInstance3D] = cell["kids"]
	for lv in levels:
		var begin := float(lv[1])
		if z.view_m > 0.0 and begin >= z.view_m:
			break
		var made: Array[MultiMeshInstance3D] = []
		for stem: String in stems:
			var mmi := _slice_mmi("celula_" + ck.replace("|", "_") + "_" + stem + String(lv[2]),
				(lv[0] as Dictionary)[stem], cell["xf"][stem], union, begin, z.view_m, false)
			add_child(mmi)
			made.append(mmi)
		for kid in children:
			kid.visibility_parent = kid.get_path_to(made[0])
		children = made
		hlod_count += made.size()
