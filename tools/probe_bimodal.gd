extends Node
## Histograma de luminanta a unui HORN NUMIT: un varf lat sau doua varfuri?
##
## De ce inca o sonda de lumina, dupa `probe_fete` si `probe_capp_lumina`.
## Amandoua raspund la "cat de mult difera fata luminata de cea umbrita" — o
## singura cifra, DELTA. Runda 24 a aratat ca intrebarea aia e prost pusa pe
## Cappadocia: masurat cu percentile pe hornSoare11, p10/p50/p90 = 38/95/139,
## adica un ECART de 101 din 255. Conul are contrast; si totusi citeste plat.
##
## Fiindca ecartul nu spune UNDE stau pixelii intre capete. Referinta (masurata
## de criticul orb pe zeci de forme) are DOUA MODURI: o fata clara si una
## distinct inchisa, cu putini pixeli intre ele. Noi avem acelasi interval
## umplut cu un gradient continuu — mediana la 95, adica mijlocul histogramei.
## Un gradient si doua platouri pot avea exact acelasi ecart si acelasi DELTA
## pe jumatati; se despart abia cand te uiti la FORMA distributiei.
##
## Explica si de ce fatetarea rundelor 12-14 "n-a iesit": fatetele exista, dar
## peste ele curge un degrade care le sudeaza intr-un singur mod.
##
## CE MASOARA. Pe pixelii care apartin unui obiect numit (acelasi rasterizator
## cu proprietar de pixel ca in `probe_fete` — depth buffer pe CPU, deci ce e
## acoperit de altceva nu intra in cifra):
##   p10/p50/p90 si ecartul  — nivelul si intinderea, ca sa fie comparabile cu
##                             masuratorile lead-ului din runda 24;
##   GAP    — distanta dintre centrele celor doua grupuri (k-means 1D, doua
##            centre, initializate pe p10/p90 si iterate pana la fix);
##   VALE   — procentul de pixeli din banda de 30% din GAP centrata pe mijlocul
##            dintre centre. ASTA e cifra care separa un gradient de doua
##            moduri: la un degrade uniform valea e la fel de populata ca restul
##            (~30%), la doua platouri se goleste.
##   BALANS — cat de mare e grupul mai mic (%), ca sa nu treaca drept "bimodal"
##            o distributie cu 2% pixeli razleti intr-un capat.
##
## PRAG DE TRECERE, derivat din ce inseamna "doua moduri" si nu ales din ochi:
##   GAP >= 55, VALE <= 18%, BALANS >= 20%.
## Un gradient perfect uniform da VALE ~= 30% prin constructie (banda e 30% din
## gap); orice scadere sub asta inseamna ca pixelii s-au strans in capete.
##
## Mai raporteaza si histograma in 16 cosuri, ca sa se vada cu ochiul liber daca
## e o cocoasa sau doua — o cifra care trece si o histograma care arata a
## clopot ar fi exact capcana din memoria `efecte-invizibile-nu-se-numara`.
##
##   godot --path . --rendering-driver vulkan res://tools/ProbeBimodal.tscn -- \
##       --track=13 --frac=0.06 --nume=hornSoare11,hornSoare12
##
## RULEAZA CU FEREASTRA (fara --headless): headless nu randeaza.

const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const W: int = 1280
const H: int = 720

const PRAG_GAP: float = 55.0
const PRAG_VALE: float = 18.0
const PRAG_BALANS: float = 20.0
## Latimea benzii de vale, ca fractie din GAP. 0.30 e si referinta implicita:
## un gradient uniform pune exact 30% din pixeli intr-o banda de 30%.
const VALE_FRAC: float = 0.30

var _cam: Camera3D
var _depth: PackedFloat32Array
var _owner: PackedInt32Array
var _nume: Array[String] = []
var _dist: PackedFloat32Array


func _ready() -> void:
	var idx := 13
	var frac := 0.06
	var f_nume: Array[String] = []
	var minpx := 200
	var top := 8
	var variante: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--nume="):
			for s in arg.trim_prefix("--nume=").split(","):
				if not s.is_empty():
					f_nume.append(s.to_lower())
		elif arg.begins_with("--minpx="):
			minpx = int(arg.trim_prefix("--minpx="))
		elif arg.begins_with("--top="):
			top = int(arg.trim_prefix("--top="))
		elif arg.begins_with("--var="):
			for v in arg.trim_prefix("--var=").split(","):
				if not v.is_empty() and v != "base":
					variante.append(v)

	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame

	_cam = Camera3D.new()
	add_child(_cam)
	_aseaza_camera(track, frac)
	# Variante de CONTROL. Nu tuning — intrebari despre cine face gradientul.
	# `--var=noambient` raspunde la "poate vertex color-ul, oricat de bimodal ar
	# fi, sa produca doua moduri cat timp ambientul lumineaza si fata intoarsa?"
	if not variante.is_empty():
		var env := _gaseste_mediu(track)
		var sun := _gaseste_soare(track)
		for v in variante:
			match v:
				"noambient":
					if env != null:
						env.ambient_light_energy = 0.0
				"noshadow":
					if sun != null:
						sun.shadow_enabled = false
				"novcol":
					_fara_vcol(track)
				_:
					push_warning("varianta necunoscuta: %s" % v)
		print("VARIANTE [%s]" % ", ".join(variante))
		if sun != null:
			print("  soare: energie %.3f  umbre %s  rot %s"
					% [sun.light_energy, sun.shadow_enabled,
						sun.rotation_degrees.snappedf(0.1)])
		if env != null:
			print("  mediu: amb_energie %.3f  expunere %.3f"
					% [env.ambient_light_energy, env.tonemap_exposure])
	for i in 4:
		await get_tree().process_frame

	print("PISTA %s  frac %.3f" % [GameState.TRACK_NAMES[idx], frac])

	_depth = PackedFloat32Array()
	_depth.resize(W * H)
	_depth.fill(1.0e20)
	_owner = PackedInt32Array()
	_owner.resize(W * H)
	_owner.fill(-1)
	_dist = PackedFloat32Array()
	var t0 := Time.get_ticks_msec()
	_rasterizeaza(track)
	var acoperiti := 0
	for o in _owner:
		if o >= 0:
			acoperiti += 1
	print("raster %d ms, %d obiecte, %d pixeli cu proprietar"
			% [Time.get_ticks_msec() - t0, _nume.size(), acoperiti])

	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var iw := img.get_width()
	var ih := img.get_height()

	# Luminantele se strang o singura data pe obiect, intr-o trecere peste
	# buffer: o bucla per obiect peste 921600 de pixeli ar fi durat minute.
	#
	# ATENTIE la felul in care se scrie in ele. `PackedFloat32Array` e tip VALOARE
	# in GDScript: `(lums[o] as PackedFloat32Array).append(v)` construieste o
	# COPIE, ii adauga elementul si o arunca — prima versiune rula corect
	# rasterizarea (896386 de pixeli cu proprietar) si raporta zero pixeli pe toate
	# cele 374 de obiecte. Nici `var buf = lums[o]` nu ajuta: copiaza la fel.
	#
	# Se face deci in doua treceri, cu vectori PLATI si un offset per obiect
	# (bucket sort): prima trecere numara pixelii fiecarui obiect, a doua ii scrie
	# la locul lor. Zero copii, o singura alocare.
	var cate := PackedInt32Array()
	cate.resize(_nume.size())
	cate.fill(0)
	for k in _owner.size():
		var o := _owner[k]
		if o >= 0 and (k % W) < iw and (k / W) < ih:
			cate[o] += 1
	var off := PackedInt32Array()
	off.resize(_nume.size() + 1)
	off[0] = 0
	for i in _nume.size():
		off[i + 1] = off[i] + cate[i]
	var cursor := off.duplicate()
	var plat := PackedFloat32Array()
	plat.resize(off[_nume.size()])
	for k in _owner.size():
		var o := _owner[k]
		if o < 0:
			continue
		var px: int = k % W
		var py: int = k / W
		if px >= iw or py >= ih:
			continue
		var c := img.get_pixel(px, py)
		plat[cursor[o]] = (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * 255.0
		cursor[o] += 1

	var acc: Array = []
	for i in _nume.size():
		if cate[i] < minpx:
			continue
		var l := plat.slice(off[i], off[i + 1])
		if not f_nume.is_empty():
			var ok := false
			for f in f_nume:
				if _nume[i].to_lower().contains(f):
					ok = true
					break
			if not ok:
				continue
		acc.append([l.size(), _nume[i], _dist[i], l])
	acc.sort_custom(func(a, b): return a[0] > b[0])

	print("")
	print("BIMODALITATE per obiect numit (pixeli proprii, imagine randata):")
	print("  nume                            d_m    px    p10  p50  p90  ecart"
			+ "   c_jos c_sus   GAP  VALE   BAL   verdict")
	var shown := 0
	for r in acc:
		if shown >= top:
			break
		shown += 1
		var l: PackedFloat32Array = r[3]
		var s := l.duplicate()
		s.sort()
		var p10 := s[int(float(s.size()) * 0.10)]
		var p50 := s[int(float(s.size()) * 0.50)]
		var p90 := s[mini(int(float(s.size()) * 0.90), s.size() - 1)]
		var cl := _doua_centre(s)
		var c_jos: float = cl[0]
		var c_sus: float = cl[1]
		var n_jos: int = cl[2]
		var gap: float = c_sus - c_jos
		var mid := (c_jos + c_sus) * 0.5
		var half := gap * VALE_FRAC * 0.5
		var n_vale := 0
		for v in s:
			if absf(v - mid) <= half:
				n_vale += 1
		var vale := 100.0 * float(n_vale) / float(s.size())
		var bal := 100.0 * float(mini(n_jos, s.size() - n_jos)) / float(s.size())
		var verdict := "BIMODAL"
		if gap < PRAG_GAP:
			verdict = "un singur mod (gap mic)"
		elif vale > PRAG_VALE:
			verdict = "GRADIENT (valea plina)"
		elif bal < PRAG_BALANS:
			verdict = "un mod + coada"
		print("  %-30s %5.1f %6d  %4.0f %4.0f %4.0f  %5.0f  %5.0f %5.0f %5.0f"
				% [r[1], r[2], r[0], p10, p50, p90, p90 - p10, c_jos, c_sus, gap]
				+ "  %5.1f %5.1f  %s" % [vale, bal, verdict])
		print("       hist " + _histograma(s))
	print("")
	print("  praguri: GAP >= %.0f, VALE <= %.0f, BALANS >= %.0f (procente)"
			% [PRAG_GAP, PRAG_VALE, PRAG_BALANS])
	print("  (un gradient uniform da VALE ~= %.0f prin constructie)"
			% (VALE_FRAC * 100.0))
	get_tree().quit(0)


func _gaseste_soare(n: Node) -> DirectionalLight3D:
	if n is DirectionalLight3D:
		return n as DirectionalLight3D
	for c in n.get_children():
		var r := _gaseste_soare(c)
		if r != null:
			return r
	return null


func _gaseste_mediu(n: Node) -> Environment:
	if n is WorldEnvironment:
		return (n as WorldEnvironment).environment
	for c in n.get_children():
		var r := _gaseste_mediu(c)
		if r != null:
			return r
	return null


## Vertex color complet alb. Nu ajunge `vertex_color_use_as_albedo = false`:
## prop-urile poarta ShaderMaterial (`prop_detail_fade`), unde COLOR intra
## neconditionat. Se albeste chiar atributul mesh-ului.
func _fara_vcol(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh is ArrayMesh:
		var src := mi.mesh as ArrayMesh
		var out := ArrayMesh.new()
		for si in src.get_surface_count():
			var a: Array = src.surface_get_arrays(si)
			var cl: Variant = a[Mesh.ARRAY_COLOR]
			if cl is PackedColorArray and not (cl as PackedColorArray).is_empty():
				var pc: PackedColorArray = cl
				for ci in pc.size():
					pc[ci] = Color.WHITE
				a[Mesh.ARRAY_COLOR] = pc
			out.add_surface_from_arrays(src.surface_get_primitive_type(si), a)
			out.surface_set_material(si, src.surface_get_material(si))
		mi.mesh = out
	for c in n.get_children():
		_fara_vcol(c)


## k-means 1D cu doua centre pe un vector DEJA SORTAT. Initializare pe p10/p90
## (nu min/max: un singur pixel razlet ar fi ancorat un centru pe el), iterat
## pana cand granita nu se mai muta. Intoarce [centru_jos, centru_sus,
## cati_pixeli_in_grupul_de_jos].
func _doua_centre(s: PackedFloat32Array) -> Array:
	var n := s.size()
	var a := s[int(float(n) * 0.10)]
	var b := s[mini(int(float(n) * 0.90), n - 1)]
	var split := 0
	for _it in 40:
		var mid := (a + b) * 0.5
		# Vectorul e sortat, deci granita se cauta binar.
		var lo := 0
		var hi := n
		while lo < hi:
			var m := (lo + hi) / 2
			if s[m] < mid:
				lo = m + 1
			else:
				hi = m
		if lo == split and _it > 0:
			break
		split = lo
		var sa := 0.0
		for i in split:
			sa += s[i]
		var sb := 0.0
		for i in range(split, n):
			sb += s[i]
		a = sa / maxf(float(split), 1.0)
		b = sb / maxf(float(n - split), 1.0)
	return [a, b, split]


## Histograma in 16 cosuri intre p2 si p98, ca text. O cifra care trece si o
## histograma care arata a clopot ar fi exact capcana din memoria
## `efecte-invizibile-nu-se-numara` — de-aia se tiparesc amandoua.
func _histograma(s: PackedFloat32Array) -> String:
	var n := s.size()
	var lo := s[int(float(n) * 0.02)]
	var hi := s[mini(int(float(n) * 0.98), n - 1)]
	var span := maxf(hi - lo, 0.001)
	var bins := PackedInt32Array()
	bins.resize(16)
	bins.fill(0)
	for v in s:
		var b := clampi(int((v - lo) / span * 16.0), 0, 15)
		bins[b] += 1
	var top := 1
	for b in bins:
		top = maxi(top, b)
	var ramp := " .:-=+*#%@"
	var out := "[%3.0f " % lo
	for b in bins:
		out += ramp[clampi(int(float(b) / float(top) * 9.0), 0, 9)]
	out += " %3.0f]" % hi
	return out


func _aseaza_camera(track: Track, frac: float) -> void:
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.fov = MEASURE_FOV
	_cam.near = 0.05
	_cam.far = 400.0
	get_viewport().size = Vector2i(W, H)
	_cam.global_position = focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	_cam.look_at(focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT,
			Vector3.UP)
	_cam.current = true


func _rasterizeaza(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.is_visible_in_tree():
		var nm := String(mi.name)
		var par := mi.get_parent()
		if par != null and String(par.name) != String(mi.name):
			nm = String(par.name) + "/" + String(mi.name)
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		var id := _nume.size()
		_nume.append(nm)
		_dist.append(_cam.global_position.distance_to(ab.get_center()))
		_mesh_in_buffer(mi, id)
	for c in n.get_children():
		_rasterizeaza(c)


func _mesh_in_buffer(mi: MeshInstance3D, id: int) -> void:
	var xf := mi.global_transform
	var cam_xf := _cam.global_transform.affine_inverse()
	for s in mi.mesh.get_surface_count():
		if mi.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue
		var idx := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] != null:
			idx = arrays[Mesh.ARRAY_INDEX]
		var sx := PackedFloat32Array()
		sx.resize(verts.size())
		var sy := PackedFloat32Array()
		sy.resize(verts.size())
		var sz := PackedFloat32Array()
		sz.resize(verts.size())
		for i in verts.size():
			var wv: Vector3 = xf * verts[i]
			var cv: Vector3 = cam_xf * wv
			var z := -cv.z
			sz[i] = z
			if z <= 0.06:
				sx[i] = -1.0e9
				sy[i] = -1.0e9
				continue
			var p := _cam.unproject_position(wv)
			sx[i] = p.x
			sy[i] = p.y
		var has_idx := not idx.is_empty()
		var count := idx.size() if has_idx else verts.size()
		var i2 := 0
		while i2 + 2 < count:
			var a := idx[i2] if has_idx else i2
			var b := idx[i2 + 1] if has_idx else i2 + 1
			var c := idx[i2 + 2] if has_idx else i2 + 2
			i2 += 3
			if sz[a] <= 0.06 or sz[b] <= 0.06 or sz[c] <= 0.06:
				continue
			_triunghi(sx[a], sy[a], sz[a], sx[b], sy[b], sz[b],
					sx[c], sy[c], sz[c], id)


func _triunghi(ax: float, ay: float, az: float, bx: float, by: float, bz: float,
		cx: float, cy: float, cz: float, id: int) -> void:
	var minx := int(floor(minf(ax, minf(bx, cx))))
	var maxx := int(ceil(maxf(ax, maxf(bx, cx))))
	var miny := int(floor(minf(ay, minf(by, cy))))
	var maxy := int(ceil(maxf(ay, maxf(by, cy))))
	if maxx < 0 or minx >= W or maxy < 0 or miny >= H:
		return
	minx = maxi(minx, 0)
	maxx = mini(maxx, W - 1)
	miny = maxi(miny, 0)
	maxy = mini(maxy, H - 1)
	var det := (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
	if absf(det) < 1.0e-9:
		return
	var inv := 1.0 / det
	for y in range(miny, maxy + 1):
		var fy := float(y) + 0.5
		var row := y * W
		for x in range(minx, maxx + 1):
			var fx := float(x) + 0.5
			var l0 := ((by - cy) * (fx - cx) + (cx - bx) * (fy - cy)) * inv
			if l0 < 0.0 or l0 > 1.0:
				continue
			var l1 := ((cy - ay) * (fx - cx) + (ax - cx) * (fy - cy)) * inv
			if l1 < 0.0 or l1 > 1.0:
				continue
			var l2 := 1.0 - l0 - l1
			if l2 < 0.0:
				continue
			var k := row + x
			var z := l0 * az + l1 * bz + l2 * cz
			if z < _depth[k]:
				_depth[k] = z
				_owner[k] = id
