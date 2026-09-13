extends Node
## Masoara intinderea texturii pe fetele INCLINATE ale mesh-ului de teren.
##
## Motivatia: raportul dezvoltatorului, de la volan, pe Serengeti — peretele
## interior de la serpentina arata striat, ca o textura trasa pe verticala.
## Diagnosticul: UV-ul terenului (`track.gd`, `_build_terrain`) e o proiectie
## PLANARA pe (x, z) — `st.set_uv(Vector2(v.x, v.z) * SURFACE_TILING)`. Pe o
## fata aproape verticala, x si z aproape nu se misca intre varful de jos si
## varful de sus al fetei, deci acelasi interval UV se intinde peste o
## distanta mare in lume: textura se lungeste pe verticala.
##
## Cifra: pentru fiecare triunghi, proiecteaza muchiile pe planul orizontal
## (dx, dz) si pe axa verticala (dy), si compara cu intinderea UV
## corespunzatoare (acelasi tiling ca in cod, SURFACE_TILING). Raportul
##   stretch = (lungime_UV pe verticala) / (lungime_metri pe verticala)
## fata de raportul pe orizontala arata cat de anizotrop e mapajul. Pe o fata
## PERFECT verticala, planar xz da stretch_v ~ 0 (UV nu se misca deloc pe
## verticala), deci raportul stretch_v/stretch_h tinde spre 0 — de-asta
## pistele cu pante mari (Alpii) sunt cele mai afectate.
##
## Grupeaza fetele dupa panta (unghiul normalei fata de UP) si raporteaza,
## per grup, media raportului stretch_v/stretch_h. Grupul "orizontal" (<15 deg)
## e testul de NON-REGRESIE: trebuie sa ramana ~1.0 inainte si dupa orice fix.
## Grupul "vertical" (>70 deg) e testul de REPARATIE: trebuie sa se apropie de
## 1.0 dupa fix (inainte de fix e aproape de 0).
##
## A DOUA masuratoare, "dupa fix": simuleaza analitic (in GDScript, aceeasi
## formula ca in terrain_splat.gdshader `vertex()`/`fragment()`) UV-ul
## EFECTIV pe care il vede shaderul dupa blendul triplanar, si aplica acelasi
## Jacobian pe UV-ul simulat. Nu citeste un shader compilat — reconstruieste
## analitic transformarea, ca sa poata rula fara fereastra/GPU (headless).
## Daca formula de aici diverge de shader, verifica manual cele doua fisiere;
## constantele (tri_power, tiling_micro, tiling_macro) sunt copiate mai jos.
##
## Rulare (o pista):
##   godot --headless --path . res://tools/ProbeTerrainUvStretch.tscn -- --track=9
## Toate pistele:
##   godot --headless --path . res://tools/ProbeTerrainUvStretch.tscn

const SURFACE_TILING: float = 0.32
# Copiate din terrain_splat.gdshader (uniform, valorile implicite).
const TRI_POWER: float = 4.0
const TILING_MICRO: float = 0.32
const TILING_MACRO: float = 0.022

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _only: int = -1


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_only = int(arg.trim_prefix("--track="))
	for i in range(1, 20):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if _only < 0 or _only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_terrain_uv_stretch: nu am gasit nicio pista")
		get_tree().quit(1)
		return
	set_process(true)


func _process(_delta: float) -> void:
	if _track == null:
		if _index >= _paths.size():
			get_tree().quit(0)
			return
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		get_tree().root.add_child(_track)
		_frames = 0
		return

	_frames += 1
	if _frames < 3:
		return # lasam rebuild() sa termine (acelasi tipar ca probe_decor)

	_measure(_paths[_index], _track)
	get_tree().root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1


func _find_terrain(root: Node) -> MeshInstance3D:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name == &"Terrain" and n is MeshInstance3D:
			return n as MeshInstance3D
		for c in n.get_children():
			stack.append(c)
	return null


func _measure(path: String, track: Node) -> void:
	var mi := _find_terrain(track)
	print("")
	print("=== %s ===" % path.get_file())
	if mi == null or mi.mesh == null:
		print("  (fara nod Terrain)")
		return
	var mesh := mi.mesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	# Normalele PE VERTEX (mediate intre celule, generate de
	# st.generate_normals() in track.gd) — shaderul primeste tot pe astea in
	# `vertex()` inainte de `flat`, deci simularea trebuie sa le foloseasca pe
	# ELE (nu normala geometrica a triunghiului) pentru `v_tri_w`, ca sa fie
	# fidela bit cu bit.
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]

	# Grupe pe panta fetei (unghiul normalei geometrice fata de UP).
	# 3 clase: orizontal (<15 deg, non-regresie), mediu (15-45), vertical (>70).
	# "plat (early-out shader)" e testul de non-regresie STRICT: sub pragul de
	# early-out (tri_w >= 0.999, vezi mai jos) shaderul citeste DOAR UV-ul
	# planar, deci INAINTE si DUPA trebuie sa iasa identic la float.
	# "orizontal <15deg" ramane pentru comparatie cu grupele mai vechi, dar
	# include si fete unde blendul triplanar intra cu pondere mica (na.y intre
	# 0.966 si 0.9997) — asta explica o deriva de ~0.2-0.5% acolo, NU o
	# regresie pe fetele cu adevarat plate.
	var groups_before := {
		"plat (early-out shader)": {"sum": 0.0, "n": 0, "area": 0.0},
		"orizontal <15deg": {"sum": 0.0, "n": 0, "area": 0.0},
		"mediu 15-45deg": {"sum": 0.0, "n": 0, "area": 0.0},
		"inclinat 45-70deg": {"sum": 0.0, "n": 0, "area": 0.0},
		"vertical >70deg": {"sum": 0.0, "n": 0, "area": 0.0},
	}
	var groups_after := {
		"plat (early-out shader)": {"sum": 0.0, "n": 0, "area": 0.0},
		"orizontal <15deg": {"sum": 0.0, "n": 0, "area": 0.0},
		"mediu 15-45deg": {"sum": 0.0, "n": 0, "area": 0.0},
		"inclinat 45-70deg": {"sum": 0.0, "n": 0, "area": 0.0},
		"vertical >70deg": {"sum": 0.0, "n": 0, "area": 0.0},
	}

	# Metoda: reconstruim JACOBIANUL 3D-lume -> UV al fiecarui triunghi (o
	# transformare LINIARA intre planul triunghiului si planul UV, exacta,
	# nu aproximata pe o singura muchie — o muchie aleasa "cea mai lunga" se
	# putea intampla sa fie aproape orizontala si pe un triunghi aproape plat,
	# ceea ce da rapoarte instabile/imense pentru grupul orizontal). Din
	# Jacobian citim direct cat se misca UV-ul cand te deplasezi 1 metru STRICT
	# pe verticala (in planul fetei) fata de 1 metru STRICT pe orizontala (tot
	# in planul fetei) — asta e raportul de anizotropie cerut.
	var tri_count := idx.size() / 3
	for t in tri_count:
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		var p0: Vector3 = verts[i0]
		var p1: Vector3 = verts[i1]
		var p2: Vector3 = verts[i2]
		var uv0: Vector2 = uvs[i0]
		var uv1: Vector2 = uvs[i1]
		var uv2: Vector2 = uvs[i2]

		var e1 := p1 - p0
		var e2 := p2 - p0
		var cross := e1.cross(e2)
		var area := cross.length() * 0.5
		if area < 1e-6:
			continue # triunghi degenerat, nu contribuie
		var normal := cross / (area * 2.0)
		var slope_deg := rad_to_deg(acos(clampf(absf(normal.y), 0.0, 1.0)))

		# Baza ortonormala IN PLANUL fetei: `horiz` (orizontala, perpendiculara
		# pe normala si pe UP) si `vert` (verticala IN PLAN, perpendiculara pe
		# `horiz` si pe normala). Pe o fata verticala `vert` tinde spre
		# Vector3.UP; pe o fata orizontala, `horiz`/`vert` sunt orice pereche
		# ortonormala in planul XZ (izotrop, deci alegerea exacta nu conteaza).
		var horiz: Vector3
		if absf(normal.y) > 0.9999:
			horiz = Vector3(1, 0, 0)
		else:
			horiz = Vector3.UP.cross(normal).normalized()
		var vert := normal.cross(horiz).normalized()

		var key := ""
		if slope_deg < 15.0:
			key = "orizontal <15deg"
		elif slope_deg < 45.0:
			key = "mediu 15-45deg"
		elif slope_deg < 70.0:
			key = "inclinat 45-70deg"
		else:
			key = "vertical >70deg"

		# Normala PE VERTEX (mediata intre celule de st.generate_normals(),
		# vezi track.gd) a vertexului "provocator" al triunghiului (v0) —
		# ASTA e ce foloseste shaderul (cu `flat`), nu normala geometrica a
		# triunghiului calculata mai sus. Se calculeaza aici (nu doar in
		# sectiunea DUPA) fiindca strict_key are nevoie de tri_w exact.
		var n_flat: Vector3 = norms[i0]
		var na := n_flat.abs()
		var tri_w: float = pow(clampf(na.y, 0.0, 1.0), TRI_POWER)
		# Grup STRICT (sub-set al lui "orizontal <15deg"), doar pentru testul
		# de non-regresie la float exact: pragul e CHIAR conditia de early-out
		# din shader/_shader_uv (tri_w >= 0.999), nu o presupunere de unghi.
		# Sub pragul asta "dupa" trebuie sa iasa IDENTIC cu "inainte". Peste
		# (chiar daca fata geometrica e aproape plata), normala pe vertex
		# poate fi mediata cu un vecin mai inclinat si pierde early-out-ul —
		# de-asta bucket-ul mai lax "orizontal <15deg" arata o deriva mica
		# (~0.2-0.5%), reala, nu eroare de sonda.
		var strict_key := "plat (early-out shader)" if tri_w >= 0.999 else ""

		# --- INAINTE: UV planar stocat in mesh (Vector2(v.x,v.z)*SURFACE_TILING) ---
		var ratio_before := _stretch_ratio(e1, e2, horiz, vert, uv1 - uv0, uv2 - uv0)
		if ratio_before >= 0.0:
			var gb: Dictionary = groups_before[key]
			gb["sum"] = float(gb["sum"]) + ratio_before * area
			gb["n"] = int(gb["n"]) + 1
			gb["area"] = float(gb["area"]) + area
			groups_before[key] = gb
			if strict_key != "":
				var gbs: Dictionary = groups_before[strict_key]
				gbs["sum"] = float(gbs["sum"]) + ratio_before * area
				gbs["n"] = int(gbs["n"]) + 1
				gbs["area"] = float(gbs["area"]) + area
				groups_before[strict_key] = gbs

		# --- DUPA: UV efectiv simulat (planar amestecat cu proiectia
		# laterala, exact formula din terrain_splat.gdshader). Ponderea
		# (tri_w, mai sus) si proiectia laterala se calculeaza PE VERTEX (ca
		# in `vertex()`), apoi se aplica `flat`-ul: toti cei 3 vertecsi ai
		# triunghiului folosesc ponderea/proiectia primului vertex (v0), exact
		# ce face `varying flat` in shader (vertexul "provocator").
		# GLSL step(n.x, n.z) = 0 daca n.z < n.x (=> mix alege primul arg,
		# VERTEX.zy), = 1 daca n.z >= n.x (=> VERTEX.xy). Deci VERTEX.zy
		# (use_zy=true) exact cand na.x > na.z.
		var use_zy: bool = na.x > na.z
		var uv0_eff := _shader_uv(p0, tri_w, use_zy)
		var uv1_eff := _shader_uv(p1, tri_w, use_zy)
		var uv2_eff := _shader_uv(p2, tri_w, use_zy)
		var ratio_after := _stretch_ratio(e1, e2, horiz, vert,
				uv1_eff - uv0_eff, uv2_eff - uv0_eff)
		if ratio_after >= 0.0:
			var ga: Dictionary = groups_after[key]
			ga["sum"] = float(ga["sum"]) + ratio_after * area
			ga["n"] = int(ga["n"]) + 1
			ga["area"] = float(ga["area"]) + area
			groups_after[key] = ga
			if strict_key != "":
				var gas: Dictionary = groups_after[strict_key]
				gas["sum"] = float(gas["sum"]) + ratio_after * area
				gas["n"] = int(gas["n"]) + 1
				gas["area"] = float(gas["area"]) + area
				groups_after[strict_key] = gas

	_print_groups("INAINTE (UV stocat in mesh, planar xz)", groups_before)
	_print_groups("DUPA (simulat: planar + triplanar lateral, blend pe panta)",
			groups_after)


## Rezolva Jacobianul world(plan fata)->UV pentru un triunghi si intoarce
## stretch_v/stretch_h ( -1.0 daca degenerat/nesemnificativ ).
func _stretch_ratio(e1: Vector3, e2: Vector3, horiz: Vector3, vert: Vector3,
		duv1: Vector2, duv2: Vector2) -> float:
	var a11 := e1.dot(horiz); var a12 := e1.dot(vert)
	var a21 := e2.dot(horiz); var a22 := e2.dot(vert)
	var det := a11 * a22 - a12 * a21
	if absf(det) < 1e-9:
		return -1.0
	var j_horiz := (duv1 * a22 - duv2 * a12) / det
	var j_vert := (duv2 * a11 - duv1 * a21) / det
	var stretch_h := j_horiz.length()
	var stretch_v := j_vert.length()
	if stretch_h < 1e-9:
		return -1.0
	return stretch_v / stretch_h


## Reproduce UV-ul EFECTIV pe care fragment() il foloseste dupa blend, pentru
## un singur vertex al triunghiului — pondere si proiectie laterala `flat`
## (calculate o singura data per triunghi, in apelant), pozitia variaza.
## Foloseste micro-tiling (TILING_MICRO); UV2 (macro) e la aceeasi scara
## relativa, deci raportul stretch_v/stretch_h iese identic — nu se simuleaza
## separat.
func _shader_uv(p: Vector3, tri_w: float, use_zy: bool) -> Vector2:
	var uv_planar := Vector2(p.x, p.z) * SURFACE_TILING
	if tri_w >= 0.999:
		return uv_planar # early-out: identic cu shaderul (if v_tri_w < 0.999)
	var side: Vector2 = Vector2(p.z, p.y) if use_zy else Vector2(p.x, p.y)
	var uv_side := side * TILING_MICRO
	return uv_side.lerp(uv_planar, tri_w)


func _print_groups(title: String, groups: Dictionary) -> void:
	print("  -- %s --" % title)
	var total_area := 0.0
	for key in ["orizontal <15deg", "mediu 15-45deg", "inclinat 45-70deg", "vertical >70deg"]:
		total_area += float((groups[key] as Dictionary)["area"]) # "plat (early-out)" e subset, exclus
	for key in ["plat (early-out shader)", "orizontal <15deg", "mediu 15-45deg", "inclinat 45-70deg", "vertical >70deg"]:
		var g: Dictionary = groups[key]
		var n := int(g["n"])
		var area := float(g["area"])
		# "plat (early-out shader)" e SUB-SET al lui "orizontal <15deg" — nu se
		# aduna la total_area (ar dubla-numara), procentul lui se raporteaza
		# tot fata de total_area, doar ca informatie.
		var pct := 0.0
		if total_area > 0.0:
			pct = area / total_area * 100.0
		if n == 0:
			print("    %-24s   0 fete   (0.0%% din arie)" % key)
			continue
		var mean_ratio := float(g["sum"]) / area
		print("    %-24s %5d fete  aria %8.1f m2 (%5.1f%%)  stretch_v/stretch_h mediu (ponderat pe arie) = %.6f" % [
			key, n, area, pct, mean_ratio])
