extends Node
## UNDE MOARE COMPONENTA DIRECTIONALA? (runda 22)
##
## Lead-ul a masurat pe hornuri numite: fata luminata 98.9 vs fata umbrita 98.5
## (hornSoare11), adica 0.4/255, acolo unde Lambert cu lumina temei ar da ~185.
## Normalele, shaderul, masca de lumina si vertex color-ul au fost excluse fiecare
## cu cate un test. Sonda asta cauta veriga rupta INTRE normale si pixel.
##
## Cum. Se randeaza chiar scena, cu chiar camera de la `--driver`, si se citeste
## imaginea randata. In paralel se rasterizeaza pe CPU (reteta din
## probe_capp_horn) un buffer care tine PROPRIETARUL pixelului SI
## `dot(normala_fetei, spre_soare)`. Deci fiecare pixel din imaginea reala stie
## al cui e si cat de mult ii bate soarele. Media luminantei pe pixelii cu
## dot > +0.35 fata de cei cu dot < -0.35, pe ACELASI horn, e masuratoarea cu
## care se judeca orice ipoteza.
##
## De ce nu se poate mai simplu: rasterizarea trebuie sa fie a NOASTRA, fiindca
## doar asa stim normala din spatele fiecarui pixel. Godot nu da inapoi
## G-buffer-ul din GDScript.
##
## Variante (fiecare stinge O veriga din lantul de lumina, ca sa se vada care):
##   --var=base       asa cum e pista acum
##   --var=noshadow   sun.shadow_enabled = false
##   --var=noambient  ambient_light_energy = 0
##   --var=nogi       gi_mode = DISABLED pe toate MeshInstance3D
##   --var=noglow     env.glow_enabled = false
##   --var=notone     tonemap LINEAR, expunere 1.0
##   --var=nofog      ceata stinsa (ca la --driver)
##   --var=sun3       sun_energy 3.0 (testul decisiv al lead-ului, reprodus)
##   --var=pancake20  pancake inapoi la implicitul de 20 m
##   --var=nbias0     shadow_normal_bias = 0
##   --var=bias0      shadow_bias = 0
##   --var=casc75     cascada 75 m in loc de 130
##   --var=noblur     shadow_blur = 0
## Se pot combina: --var=noshadow,nogi
##
##   godot --path . --rendering-driver vulkan res://tools/ProbeCappLumina.tscn -- \
##       --frac=0.06 --nume=hornSoare7,hornSoare11 --var=noshadow
##
## RULEAZA CU FEREASTRA, ca Snapshot: headless nu randeaza, deci imaginea ar iesi
## goala si toate mediile ar fi zero.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const W: int = 1280
const H: int = 720
## Cat de mult trebuie sa bata soarele ca fata sa conteze drept "luminata"
## (respectiv "umbrita"). 0.35 e ~20 de grade de la razant, deci nicio fata
## ambigua nu intra in vreuna dintre medii.
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
	var frac := 0.06
	var filtru: Array[String] = []
	var variante: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--nume="):
			for s in arg.trim_prefix("--nume=").split(","):
				if not s.is_empty():
					filtru.append(s)
		elif arg.begins_with("--var="):
			for s in arg.trim_prefix("--var=").split(","):
				if not s.is_empty() and s != "base":
					variante.append(s)

	await get_tree().process_frame
	var track := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
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
	# Directia SPRE soare: lumina bate pe -Z al nodului, deci spre soare e +Z.
	_spre_soare = sun.global_transform.basis.z.normalized()
	var env: Environment = _gaseste_mediu(track)

	_aplica_variante(track, sun, env, variante)
	for i in 4:
		await get_tree().process_frame

	print("EYE %s  frac %.3f  variante [%s]"
			% [_cam.global_position.snappedf(0.01), frac, ", ".join(variante)])
	print("SOARE  rot %s  energie %.3f  umbre %s  spre_soare %s"
			% [sun.rotation_degrees.snappedf(0.1), sun.light_energy,
				sun.shadow_enabled, _spre_soare.snappedf(0.01)])
	print("SOARE  cull_mask %d  layers(soare) %d  vizibil %s"
			% [sun.light_cull_mask, sun.layers, sun.is_visible_in_tree()])
	print("UMBRA  bias %.3f  normal_bias %.3f  pancake %.1f  cascada %.1f  blur %.2f"
			% [sun.shadow_bias, sun.shadow_normal_bias,
				sun.directional_shadow_pancake_size,
				sun.directional_shadow_max_distance, sun.shadow_blur])
	if env != null:
		print("MEDIU  amb_sursa %d  amb_energie %.3f  tonemap %d  expunere %.3f  glow %s  ceata %s  ssao %s"
				% [env.ambient_light_source, env.ambient_light_energy,
					env.tonemap_mode, env.tonemap_exposure, env.glow_enabled,
					env.fog_enabled, env.ssao_enabled])

	# ---- rasterizare CPU: proprietar + dot(normala, soare) per pixel ----
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

	# ---- imaginea REALA, randata de motor ----
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("imagine %dx%d (buffer %dx%d)" % [img.get_width(), img.get_height(), W, H])

	print("")
	print("LUMINANTA pe fata, per horn (pixeli castigati, imagine randata):")
	print("  nume                d_m   px_lum  L_lum   px_umb  L_umb    DELTA   px_tot")
	var rows: Array = []
	for i in _nume.size():
		if not filtru.is_empty():
			if filtru.has(_nume[i]):
				rows.append(i)
		elif _scripturi[i].ends_with("chimney_shape.gd"):
			rows.append(i)

	var iw := img.get_width()
	var ih := img.get_height()
	var acc: Array = []
	for i in rows:
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
			# Luminanta perceptuala, pe valorile din poza (ca la lead).
			var l := (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * 255.0
			var d := _dotbuf[k]
			if d > PRAG_DOT:
				s_lum += l
				n_lum += 1
			elif d < -PRAG_DOT:
				s_umb += l
				n_umb += 1
		if n_tot < 200:
			continue
		var l_lum := s_lum / maxf(float(n_lum), 1.0)
		var l_umb := s_umb / maxf(float(n_umb), 1.0)
		acc.append([n_tot, _nume[i], _dist[i], n_lum, l_lum, n_umb, l_umb])
	acc.sort_custom(func(a, b): return a[0] > b[0])
	for r in acc:
		var delta: float = float(r[4]) - float(r[6])
		var flag := ""
		if int(r[3]) > 50 and int(r[5]) > 50:
			flag = "  OK" if absf(delta) >= 60.0 else "  PLAT"
		else:
			flag = "  (prea putini pixeli pe o fata)"
		print("  %-18s %5.1f  %6d  %6.1f  %6d  %6.1f  %+7.1f  %6d%s"
				% [r[1], r[2], r[3], r[4], r[5], r[6], delta, r[0], flag])
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
			"sun3":
				sun.light_energy = 3.0
			"noambient":
				if env != null:
					env.ambient_light_energy = 0.0
			"amb26":
				if env != null:
					env.ambient_light_energy = 0.26
			"amb30":
				if env != null:
					env.ambient_light_energy = 0.30
			"amb22":
				if env != null:
					env.ambient_light_energy = 0.22
			"cand":
				# Perechea rundei 30: ambient 0.20 cu soare 1.70. Ambientul
				# coborat scoate umbra de pe carosabil din spoiala; soarele
				# urcat pune la loc NIVELUL pe care ambientul il tinea.
				if env != null:
					env.ambient_light_energy = 0.20
				sun.light_energy = 1.70
			"noglow":
				if env != null:
					env.glow_enabled = false
			"nofog":
				if env != null:
					env.fog_enabled = false
			"notone":
				if env != null:
					env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
					env.tonemap_exposure = 1.0
			"nogi":
				_stinge_gi(track)
			"pancake20":
				sun.directional_shadow_pancake_size = 20.0
			"nbias0":
				sun.shadow_normal_bias = 0.0
			"bias0":
				sun.shadow_bias = 0.0
			"casc75":
				sun.directional_shadow_max_distance = 75.0
			"casc60":
				sun.directional_shadow_max_distance = 60.0
			"casc90":
				sun.directional_shadow_max_distance = 90.0
			"casc110":
				sun.directional_shadow_max_distance = 110.0
			"casc115":
				sun.directional_shadow_max_distance = 115.0
			"casc120":
				sun.directional_shadow_max_distance = 120.0
			"casc125":
				sun.directional_shadow_max_distance = 125.0
			"casc128":
				sun.directional_shadow_max_distance = 128.0
			"nocast_horizon":
				_fara_umbra(track, "horizon")
			"nocast_terrain":
				_fara_umbra(track, "terrain")
			"nocast_decor":
				_fara_umbra(track, "decor")
			"nocast_all":
				_fara_umbra(track, "*")
			"nocast_self11":
				_fara_umbra(track, "hornsoare11")
			"nocast_horn":
				_fara_umbra(track, "horn")
			"nocast_zid":
				_fara_umbra(track, "zid")
			"nocast_track":
				_fara_umbra(track, "track13")
			"listcast":
				_listeaza_casteri(track, "")
			"nocast_erciyes":
				_fara_umbra(track, "erciyes")
			"nocast_mesa":
				_fara_umbra(track, "mesarosie")
			"nocast_terrainbody":
				_fara_umbra(track, "terrainbody")
			"atlas4k":
				get_viewport().positional_shadow_atlas_size = 4096
				RenderingServer.directional_shadow_atlas_set_size(4096, true)
			"atlas8k":
				RenderingServer.directional_shadow_atlas_set_size(8192, true)
			"noblur":
				sun.shadow_blur = 0.0
			_:
				push_warning("varianta necunoscuta: %s" % v)


## Scoate din UMBRA (nu din cadru) o familie de obiecte, ca sa se vada CINE
## arunca umbra care inghite padurea de hornuri. `cheie` se cauta in numele
## nodului cu script, cu minuscule; "*" = toata scena.
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
			# Siluetele de orizont stau sub noduri auto-numite (@Node3D@231),
			# deci cheia trebuie cautata si in numele MESH-ului, nu doar in
			# lantul de parinti.
			if not potriveste and mi.mesh != null:
				for si in mi.mesh.get_surface_count():
					pass
		if potriveste:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_fara_umbra(c, cheie)


## Toate mesh-urile care ARUNCA umbra, cu numele lor de cale si gabaritul.
## Fara asta, "cine arunca umbra peste padure" ramane o ghicitoare: numele de
## nod nu sunt unice si o cheie ca "decor" prinde jumatate din scena.
func _listeaza_casteri(n: Node, cale: String) -> void:
	var c2 := cale + "/" + String(n.name)
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.is_visible_in_tree() 			and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		if ab.size.length() > 30.0:
			print("  CASTER %-64s  dim %s  centru %s  mod %d"
					% [c2, ab.size.snappedf(0.1), ab.get_center().snappedf(0.1),
						mi.cast_shadow])
	for c in n.get_children():
		_listeaza_casteri(c, c2)


func _stinge_gi(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null:
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	for c in n.get_children():
		_stinge_gi(c)


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
			# Normala GEOMETRICA a fetei, in lume. Pe mesh-uri deindexate e chiar
			# normala pe care o vede shaderul; oricum ea decide daca fata
			# "priveste" spre soare.
			# NORMALA din ATRIBUTUL mesh-ului, nu din produsul vectorial al
			# colturilor. Diferenta a costat o masuratoare intreaga: produsul
			# `(b-a)x(c-a)` depinde de infasurare, iar pe kitul de hornuri
			# infasurarea e inversa fata de conventia Godot — deci semnul lui
			# `dot(soare)` iesea rasturnat si sonda numea "luminata" exact fata
			# intoarsa. Se compara cu normala pe care o vede chiar shaderul.
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
