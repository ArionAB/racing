extends Node
## ACELASI test de fata luminata vs fata umbrita, dar pe ORICE PISTA.
##
## De ce exista, dupa ce `probe_capp_lumina` masura deja asta: aia e legata de
## Track13 si isi alege obiectele dupa `chimney_shape.gd`. Intrebarea rundei 23
## nu e "cat de plate sunt hornurile", ci "sunt hornurile plate FATA DE ce arata
## bine". Daca Chongqing si Stromboli dau tot ~19/255 pe un prop de aceeasi
## clasa, atunci platoul e o proprietate a lantului `world_prop` /
## `prop_detail_fade` si nu are nimic de-a face cu Cappadocia — si asta explica
## de ce fiecare pista din proiect a avut nevoie de AO copt in vertex colors ca
## sa arate a ceva.
##
## Metoda e IDENTICA cu cea din probe_capp_lumina (aceleasi constante de camera,
## acelasi PRAG_DOT, aceeasi luminanta perceptuala pe imaginea randata), ca
## cifrele sa fie comparabile cu masuratorile lead-ului. Se randeaza cadrul real,
## se rasterizeaza pe CPU un buffer cu proprietarul pixelului si
## `dot(normala, spre_soare)`, apoi se mediaza luminanta pixelilor cu dot > +0.35
## fata de cei cu dot < -0.35, PE ACELASI OBIECT.
##
## Selectia obiectelor, fiindca fiecare pista are alta familie de prop-uri:
##   --script=chimney_shape.gd   dupa scriptul nodului proprietar
##   --nume=Turn,Bloc            dupa subsir in numele nodului (case-insensitive)
##   --minpx=400                 prag de pixeli castigati (implicit 200)
##   --top=8                     cate obiecte se raporteaza (dupa aria pe ecran)
## Fara filtru: primele `--top` obiecte dupa aria pe ecran, oricare ar fi ele.
##
## Variante (fiecare stinge o veriga, ca sa se vada care conteaza):
##   --var=novcol     vertex color complet STINS (controlul cerut de lead,
##                    care pana acum fusese incercat doar redus la 35%)
##   --var=noshadow   sun.shadow_enabled = false
##   --var=nodetail   stratul de detaliu stins
##   --var=nocast_horizon   siluetele de orizont nu mai arunca umbra
##
##   godot --path . --rendering-driver vulkan res://tools/ProbeFete.tscn -- \
##       --track=5 --frac=0.10 --top=8
##
## RULEAZA CU FEREASTRA (fara --headless): headless nu randeaza, deci imaginea
## ar iesi neagra si toate mediile ar fi zero.

const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const W: int = 1280
const H: int = 720
const PRAG_DOT: float = 0.35

var _cam: Camera3D
var _depth: PackedFloat32Array
var _owner: PackedInt32Array
var _dotbuf: PackedFloat32Array
var _nume: Array[String] = []
var _scripturi: Array[String] = []
var _dist: PackedFloat32Array
var _spre_soare: Vector3


func _ready() -> void:
	var idx := 6
	var frac := 0.06
	var f_script := ""
	var f_nume: Array[String] = []
	var minpx := 200
	var top := 10
	var variante: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--script="):
			f_script = arg.trim_prefix("--script=")
		elif arg.begins_with("--nume="):
			for s in arg.trim_prefix("--nume=").split(","):
				if not s.is_empty():
					f_nume.append(s.to_lower())
		elif arg.begins_with("--minpx="):
			minpx = int(arg.trim_prefix("--minpx="))
		elif arg.begins_with("--top="):
			top = int(arg.trim_prefix("--top="))
		elif arg.begins_with("--var="):
			for s in arg.trim_prefix("--var=").split(","):
				if not s.is_empty() and s != "base":
					variante.append(s)

	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame

	_cam = Camera3D.new()
	add_child(_cam)
	_aseaza_camera(track, frac)

	var sun: DirectionalLight3D = _gaseste_soare(track)
	if sun == null:
		push_error("nu am gasit DirectionalLight3D")
		get_tree().quit(1)
		return
	_spre_soare = sun.global_transform.basis.z.normalized()
	var env: Environment = _gaseste_mediu(track)

	_aplica_variante(track, sun, env, variante)
	for i in 4:
		await get_tree().process_frame

	print("PISTA %s  (%s)  frac %.3f  variante [%s]"
			% [GameState.TRACK_NAMES[idx], GameState.TRACK_SCENES[idx].get_file(),
				frac, ", ".join(variante)])
	print("EYE %s" % _cam.global_position.snappedf(0.01))
	print("SOARE  rot %s  energie %.3f  umbre %s  spre_soare %s"
			% [sun.rotation_degrees.snappedf(0.1), sun.light_energy,
				sun.shadow_enabled, _spre_soare.snappedf(0.01)])
	print("UMBRA  bias %.3f  normal_bias %.3f  cascada %.1f  blur %.2f"
			% [sun.shadow_bias, sun.shadow_normal_bias,
				sun.directional_shadow_max_distance, sun.shadow_blur])
	if env != null:
		print("MEDIU  amb_sursa %d  amb_energie %.3f  tonemap %d  expunere %.3f  glow %s  ceata %s"
				% [env.ambient_light_source, env.ambient_light_energy,
					env.tonemap_mode, env.tonemap_exposure, env.glow_enabled,
					env.fog_enabled])

	_depth = PackedFloat32Array()
	_depth.resize(W * H)
	_depth.fill(1.0e20)
	_owner = PackedInt32Array()
	_owner.resize(W * H)
	_owner.fill(-1)
	_dotbuf = PackedFloat32Array()
	_dotbuf.resize(W * H)
	_dotbuf.fill(0.0)
	_dist = PackedFloat32Array()
	var t0 := Time.get_ticks_msec()
	_rasterizeaza(track)
	print("raster %d ms, %d obiecte" % [Time.get_ticks_msec() - t0, _nume.size()])

	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("imagine %dx%d (buffer %dx%d)" % [img.get_width(), img.get_height(), W, H])

	var iw := img.get_width()
	var ih := img.get_height()
	var acc: Array = []
	for i in _nume.size():
		if f_script != "" and not _scripturi[i].ends_with(f_script):
			continue
		if not f_nume.is_empty():
			var ok := false
			for f in f_nume:
				if _nume[i].to_lower().contains(f):
					ok = true
					break
			if not ok:
				continue
		var s_lum := 0.0
		var n_lum := 0
		var s_umb := 0.0
		var n_umb := 0
		var n_tot := 0
		for k in _owner.size():
			if _owner[k] != i:
				continue
			n_tot += 1
			var px: int = k % W
			var py: int = k / W
			if px >= iw or py >= ih:
				continue
			var c := img.get_pixel(px, py)
			var l := (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * 255.0
			var d := _dotbuf[k]
			if d > PRAG_DOT:
				s_lum += l
				n_lum += 1
			elif d < -PRAG_DOT:
				s_umb += l
				n_umb += 1
		if n_tot < minpx:
			continue
		acc.append([n_tot, _nume[i], _dist[i], n_lum,
				s_lum / maxf(float(n_lum), 1.0), n_umb,
				s_umb / maxf(float(n_umb), 1.0), _scripturi[i]])
	acc.sort_custom(func(a, b): return a[0] > b[0])
	print("")
	print("LUMINANTA pe fata, per obiect (imagine randata):")
	print("  nume                 d_m   px_lum  L_lum   px_umb  L_umb    DELTA   px_tot  script")
	var shown := 0
	for r in acc:
		if shown >= top:
			break
		shown += 1
		var delta: float = float(r[4]) - float(r[6])
		var flag := ""
		if int(r[3]) > 50 and int(r[5]) > 50:
			flag = "  OK" if absf(delta) >= 60.0 else "  PLAT"
		else:
			flag = "  (prea putini pixeli pe o fata)"
		print("  %-18s %5.1f  %6d  %6.1f  %6d  %6.1f  %+7.1f  %6d  %-22s%s"
				% [r[1], r[2], r[3], r[4], r[5], r[6], delta, r[0], r[7], flag])
	print("")
	print("  tinta criticului: |DELTA| >= 60/255")
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


func _aplica_variante(track: Node, sun: DirectionalLight3D, env: Environment,
		variante: Array[String]) -> void:
	for v in variante:
		match v:
			"noshadow":
				sun.shadow_enabled = false
			"novcol":
				_fara_vcol(track)
			"nodetail":
				_fara_detaliu(track)
			"nocast_horizon":
				_fara_umbra(track, "horizon")
			"sun3":
				sun.light_energy = 3.0
			"noambient":
				if env != null:
					env.ambient_light_energy = 0.0
			_:
				push_warning("varianta necunoscuta: %s" % v)


## CONTROLUL cerut de lead: vertex color complet stins, nu redus la 35%.
## Se umbla pe materialul EFECTIV al fiecarui mesh, fiindca prop-urile poarta si
## StandardMaterial3D (`world_material`) si ShaderMaterial
## (`faded_detail_material`). Materialele sunt obiecte PARTAJATE pe toata pista,
## deci o singura atingere le schimba peste tot — exact ce vrem la un control.
func _fara_vcol(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null:
		for m in _materiale(mi):
			var sm := m as StandardMaterial3D
			if sm != null:
				sm.vertex_color_use_as_albedo = false
			var shm := m as ShaderMaterial
			if shm != null:
				shm.set_shader_parameter("vcol_amount", 0.0)
	for c in n.get_children():
		_fara_vcol(c)


func _fara_detaliu(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null:
		for m in _materiale(mi):
			var sm := m as StandardMaterial3D
			if sm != null:
				sm.detail_enabled = false
	for c in n.get_children():
		_fara_detaliu(c)


func _materiale(mi: MeshInstance3D) -> Array:
	var out: Array = []
	if mi.material_override != null:
		out.append(mi.material_override)
	if mi.mesh != null:
		for s in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(s)
			if m == null:
				m = mi.mesh.surface_get_material(s)
			if m != null:
				out.append(m)
	return out


func _fara_umbra(n: Node, cheie: String) -> void:
	var mi := n as MeshInstance3D
	if mi != null:
		var potriveste := cheie == "*"
		if not potriveste:
			var a: Node = n
			while a != null:
				if String(a.name).to_lower().contains(cheie):
					potriveste = true
					break
				a = a.get_parent()
		if potriveste:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_fara_umbra(c, cheie)


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
		var own := n
		while own != null and own.get_script() == null:
			own = own.get_parent()
		var nm := String(mi.name)
		var scr := "-"
		if own != null:
			scr = String(own.get_script().resource_path.get_file())
			nm = String(own.name)
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		var id := _nume.size()
		_nume.append(nm)
		_scripturi.append(scr)
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
		var nrms := PackedVector3Array()
		if arrays[Mesh.ARRAY_NORMAL] != null:
			nrms = arrays[Mesh.ARRAY_NORMAL]
		# Normalele se transforma cu inversa transpusa, nu cu transformul.
		var nb := xf.basis.inverse().transposed()
		var wpos := PackedVector3Array()
		wpos.resize(verts.size())
		var sx := PackedFloat32Array()
		sx.resize(verts.size())
		var sy := PackedFloat32Array()
		sy.resize(verts.size())
		var sz := PackedFloat32Array()
		sz.resize(verts.size())
		for i in verts.size():
			var wv: Vector3 = xf * verts[i]
			wpos[i] = wv
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
			# NORMALA din ATRIBUTUL mesh-ului, nu din produsul vectorial al
			# colturilor: pe kituri cu infasurare inversa semnul lui dot iese
			# rasturnat si sonda numeste "luminata" exact fata intoarsa.
			var nrm := Vector3.ZERO
			if not nrms.is_empty():
				nrm = (nb * (nrms[a] + nrms[b] + nrms[c]))
			else:
				nrm = (wpos[b] - wpos[a]).cross(wpos[c] - wpos[a])
			if nrm.length_squared() < 1.0e-12:
				continue
			var d := nrm.normalized().dot(_spre_soare)
			_triunghi(sx[a], sy[a], sz[a], sx[b], sy[b], sz[b],
					sx[c], sy[c], sz[c], id, d)


func _triunghi(ax: float, ay: float, az: float, bx: float, by: float, bz: float,
		cx: float, cy: float, cz: float, id: int, dotv: float) -> void:
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
				_dotbuf[k] = dotv
