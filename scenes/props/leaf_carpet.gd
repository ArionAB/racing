class_name LeafCarpet
extends Node3D
## COVORUL DE FRUNZE (Kyoto, Track18, POI D si E; brief kyoto.md §3).
##
## Un panou transparent, la 4 cm peste asfalt, pe zonele cerute, cu frunzele
## desenate din clasa de textura `leaf_litter` (assets/shaders/leaf_carpet.gdshader).
## Masinile il CURATA pe unde trec: RoadWear folosit invers.
##
## DE CE RoadWear NU SE POATE FOLOSI CHIAR ASA (masurat pe cod, oct 2026):
##  1. [Track._snow_road_material] il leaga de `road_surface == "snow"`: foaia
##     se naste doar acolo, iar shaderul soselei de zapada e cel care o citeste.
##     Kyoto e asfalt, deci nu exista foaie.
##  2. [Car._drop_trail] scrie in foaie doar cand `loose` (nisip/pamant/zapada):
##     pe asfalt nu se cheama niciodata `Track.stamp_wear`.
## Asa ca: (a) clasa [RoadWear] se refoloseste NESCHIMBATA, instantiata aici,
## intr-un singur exemplar pentru ambele zone (coordonate "cusute": D apoi E, una
## dupa alta); (b) Track primeste un registru de "wear sinks" (`register_wear_sink`)
## si masina stampileaza prin el, independent de `loose` (Car._drop_leaf_wear);
## (c) shaderul citeste foaia pe panoul de frunze, nu pe sosea.
##
## UN SINGUR MATERIAL pentru tot panoul (+1 pe pista), partajat de ambele zone.
## Nu atinge fizica: grip-ul nu citeste nimic de aici.

## Zonele: (fractie_de la, fractie_pana_la, densitate 0..1). Fractii din
## lungimea buclei, ca in tools/gen_kyoto_route.py (scrise de generator).
@export var zones: Array[Vector3] = []
## Cat sta panoul peste suprafata vizibila a soselei (care are coroana de 3 cm).
@export_range(0.01, 0.2, 0.005, "suffix:m") var lift: float = 0.04
## Pe cati metri se topeste panoul la capetele fiecarei zone.
@export_range(2.0, 80.0, 1.0, "suffix:m") var fade_m: float = 22.0
## Cat de aproape de marginea soselei se opreste panoul (m).
@export_range(0.0, 1.0, 0.05, "suffix:m") var edge_inset: float = 0.15
@export_range(2, 24, 1) var columns: int = 8
## Acoperirea pe axa fata de margine (1.0). Vezi shaderul.
@export_range(0.0, 1.0, 0.01) var center_cover: float = 0.55
## Puterea unei stampile de roata (RoadWear.STAMP_ALPHA = 0.20 per trecere).
## 0.30 = ~4 treceri pe aceeasi linie curata complet: dupa trei tururi cu un
## pluton, linia de cursa e gol de asfalt printre frunze.
@export_range(0.1, 2.0, 0.05) var stamp_strength: float = 0.30

const SHADER_PATH: String = "res://assets/shaders/leaf_carpet.gdshader"
const CROWN: float = 0.03 # = Track.ROAD_CROWN; panoul urmareste bomba soselei
## Marja in spatiul foii: stampilele de la buza foii se dubleaza pe buza opusa
## (RoadWear.stamp), deci zonele nu pornesc chiar de la 0.
const SHEET_PAD: float = 8.0

var _track: Track = null
var _wear: RoadWear = null
var _material: ShaderMaterial = null
## Per zona: (dist_start, dist_end, offset_in_foaie), metri.
var zone_spans: Array[Vector3] = []
var built: bool = false
var triangle_count: int = 0
var stamps_received: int = 0
## Pentru sonde: stampilele pe benzi laterale de 1 m (de la -8 m la +8 m).
var lateral_hist: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var lane_len: float = 1.0
var lane_span: float = 1.0


func _ready() -> void:
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


func _build() -> void:
	if not is_inside_tree() or built:
		return
	var track := _find_track()
	if track == null or track.routes.is_empty() or track.route_at(0).baked.size() < 2:
		# Ruta coapta apare abia dupa rebuild() (copiii isi fac _ready primii).
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_build, CONNECT_ONE_SHOT)
		return
	var route := track.route_at(0)
	var total := route.dists[route.baked.size()]
	# Latimea maxima din zone: foaia acopera toata latimea + o marja de 1 m.
	var max_w := 0.0
	var ranges: Array[Vector2i] = []
	for z in zones:
		var r := _index_range(route, z.x * total, z.y * total)
		ranges.append(r)
		for i in range(r.x, r.y + 1):
			max_w = maxf(max_w, track.width_at_index(i))
	lane_span = max_w * 2.0 + 2.0
	# Foaia de uzura: un singur exemplar, zonele "cusute" una dupa alta.
	var offset := SHEET_PAD
	zone_spans.clear()
	for k in zones.size():
		var d0 := zones[k].x * total
		var d1 := zones[k].y * total
		zone_spans.append(Vector3(d0, d1, offset))
		offset += d1 - d0 + SHEET_PAD
	lane_len = maxf(offset, 1.0)
	_wear = RoadWear.new()
	_wear.name = "FoaieUzura"
	_wear.setup(lane_len, lane_span)
	add_child(_wear)
	_material = _make_material()
	for k in zones.size():
		_build_zone(track, route, k, ranges[k])
	track.register_wear_sink(self)
	built = true


## Indicii baked cu distanta cumulata in [d0, d1].
func _index_range(route: TrackRoute, d0: float, d1: float) -> Vector2i:
	var n := route.baked.size()
	var a := 0
	while a < n - 1 and route.dists[a] < d0:
		a += 1
	var b := a
	while b < n - 1 and route.dists[b + 1] <= d1:
		b += 1
	return Vector2i(a, maxi(b, a + 1))


func _make_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH) as Shader
	var tex_path := String(Palette.CLASS_TEXTURES["leaf_litter"])
	mat.set_shader_parameter("leaf_tex", load(tex_path))
	mat.set_shader_parameter("wear_tex", _wear.get_texture())
	mat.set_shader_parameter("lane_len", lane_len)
	mat.set_shader_parameter("lane_span", lane_span)
	mat.set_shader_parameter("tex_scale", float(Palette.CLASS_TRIPLANAR_SCALE["leaf_litter"]))
	mat.set_shader_parameter("center_cover", center_cover)
	# Tentele din clasele paletei (aceleasi ca arțarii): carmin, portocaliu, ruginiu.
	mat.set_shader_parameter("col_a", _class_color("maple_crimson"))
	mat.set_shader_parameter("col_b", _class_color("maple_orange"))
	mat.set_shader_parameter("col_c", _class_color("leaf_litter"))
	return mat


static func _class_color(cls: String) -> Color:
	var c: Color = Palette.CLASS_TINT[cls]
	return Color(c.r, c.g, c.b, 1.0)


func _build_zone(track: Track, route: TrackRoute, k: int, r: Vector2i) -> void:
	var span := zone_spans[k]
	var density := zones[k].z
	var baked := route.baked
	var n := baked.size()
	var cols := columns
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols_arr := PackedColorArray()
	var idx := PackedInt32Array()
	var rows := 0
	for i in range(r.x, r.y + 1):
		var a := baked[maxi(i - 1, 0)]
		var b := baked[mini(i + 1, n - 1)]
		var dir3 := b - a
		var dir := Vector3(dir3.x, 0.0, dir3.z)
		if dir.length_squared() < 1e-8:
			continue
		dir = dir.normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var normal := side.cross(dir3.normalized()).normalized()
		if normal.y < 0.0:
			normal = -normal
		var w := maxf(track.width_at_index(i) - edge_inset, 1.0)
		var d := route.dists[i]
		var fade := smoothstep(0.0, fade_m, minf(d - span.x, span.y - d))
		for c in cols + 1:
			var t := float(c) / float(cols) * 2.0 - 1.0
			var lat := t * w
			var p := baked[i] + side * lat \
				+ Vector3.UP * (CROWN * (1.0 - t * t) + lift)
			verts.append(p)
			norms.append(normal)
			uvs.append(Vector2(lat, span.z + (d - span.x)))
			cols_arr.append(Color(fade * density, absf(t), 0.0, 1.0))
		if rows > 0:
			var base := (rows - 1) * (cols + 1)
			for c in cols:
				var q := base + c
				idx.append_array(PackedInt32Array([
					q, q + cols + 1, q + 1, q + 1, q + cols + 1, q + cols + 2]))
		rows += 1
	if rows < 2:
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols_arr
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material)
	var inst := MeshInstance3D.new()
	inst.name = "Panou%d" % k
	inst.mesh = mesh
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	triangle_count += idx.size() / 3


## Zona (indexul in `zones`) care contine distanta `dist_m` a buclei, cu o marja;
## -1 daca niciuna.
func zone_at_dist(dist_m: float, margin_before: float = 0.0,
		margin_after: float = 0.0) -> int:
	for k in zone_spans.size():
		var s := zone_spans[k]
		if dist_m >= s.x - margin_before and dist_m <= s.y + margin_after:
			return k
	return -1


## Lantul `Track.stamp_wear_sinks`: roata la (metri de-a lungul buclei, metri
## lateral de ax). Zonele nu se suprapun; in afara lor nu se face nimic.
func stamp_road(dist_m: float, lateral_m: float) -> void:
	if _wear == null:
		return
	var k := zone_at_dist(dist_m)
	if k < 0:
		return
	var s := zone_spans[k]
	stamps_received += 1
	lateral_hist[clampi(int(floor(lateral_m)) + 8, 0, 15)] += 1
	_wear.stamp(s.z + (dist_m - s.x), lateral_m, stamp_strength / 0.2)


## Pentru sonde si capturi: ceva stampile pe linia ideala, ca dupa `passes` treceri
## ale unui pluton (fagase la +-`gauge`, cu serpuire usoara). NU e fizica, e
## istoria simulata a foii; sonda reala (masinile) trece prin `stamp_road`.
func simulate_passes(passes: int, gauge: float = 0.85) -> void:
	if _wear == null:
		return
	for pass_i in passes:
		for k in zone_spans.size():
			var s := zone_spans[k]
			var d := s.x + 2.0
			while d < s.y - 2.0:
				# Linia de cursa serpuieste; plutonul o tine, cu o abatere mica
				# de la o trecere la alta.
				var wander := 0.9 * sin(d * 0.021) + 0.35 * sin(d * 0.057 + 1.3) \
					+ 0.25 * sin(d * 0.31 + float(pass_i) * 2.1)
				for side: float in [-1.0, 1.0]:
					_wear.stamp(s.z + (d - s.x), wander + gauge * side, stamp_strength / 0.2)
					stamps_received += 1
				d += 2.2
				# Foaia are pool-ul de 32 de sprite-uri pe cadru: lot mic si cadru.
				if int(d / 2.2) % 12 == 0:
					await get_tree().process_frame
