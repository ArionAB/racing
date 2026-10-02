extends Node
## REFLEXIA PAVILIONULUI PE APA v12 (Kyoto, brief §3 / §3.1 / §7 pasul 1d).
##
##   Godot_v4.7-stable_win64_console.exe --path . res://tools/ProbeKyotoReflexie.tscn
##
## CERE FEREASTRA (randare; memoria `snapshot-nu-merge-headless`).
##
## Problema (brief §3): apa v12 e OPACA si unshaded, deci o copie oglindita pusa
## SUB apa nu se vede. Solutia incercata aici, cu un obiect-placeholder (un
## "pavilion" din cutii pe atlas, ~14.5 m, aur pe CAR_YELLOW):
##
##   1. In iazul opac (v12) se taie o GAURA locala, exact acolo unde se vede
##      reflexia (un dreptunghi intre ~0,38 D si D-6 metri de camera: reflexia
##      varfului unei cladiri de 14 m, vazuta de la 10 m inaltime, cade pe apa la
##      d = D * 10 / (10 + 14.5), adica MULT in fata cladirii).
##   2. Sub gaura, la -16 m, o "albie": acelasi material opac al apei (zero
##      materiale noi), ca fundul reflexiei sa aiba culoarea apei.
##   3. Intre ele, copia OGLINDITA a pavilionului: un NOD cu scale.y = -1 (nu
##      MultiMesh; memoria `multimesh-oglindire-culling`), `cast_shadow` OFF.
##   4. Deasupra gaurii, la +`SHEET_LIFT` m, o panza de apa TRANSPARENTA: acelasi
##      shader v12 (copiat la rulare din water.gdshader, cu `blend_mix`,
##      `depth_draw_never` si ALPHA), margini care se topesc in apa opaca.
##      Acesta e SINGURUL material nou (+1).
##
## Moduri (aceeasi scena, aceeasi camera, lumea INGHETATA: nicio animatie in
## apa, memoria `diferenta-on-off-cere-lume-inghetata`):
##   off   iaz opac intreg, fara gaura (starea de azi)
##   sheet gaura + albie + panza, FARA copia oglindita (atribuire: ce da panza)
##   on    tot, cu copia oglindita
## Camera = camera de joc: 10 m sus, pitch -28,7 grade, FOV 68, pavilionul la
## 70-110 m, azimut 20-45 grade (3 variante).
##
## Cifre: diferenta de pixeli pe zona reflexiei (on-off, on-sheet), materiale
## vizibile, obiecte/primitive/desene (RenderingServer), overdraw cu
## Viewport.DEBUG_DRAW_OVERDRAW (luminanta fata de un singur strat) si testul de
## z-fighting al panzei (panza magenta opaca, deasupra apei; pixeli pierduti in
## banda de suprapunere, 5 cadre cu camera tremurata).

const IMG := Vector2i(1920, 1080)
## Soarele sta IN SPATELE camerei, putin la stanga (brief §4, F: "soarele
## lumineaza fata de sud a pavilionului, exact fata dinspre drum"): razele merg
## spre -Z. Cu soarele in fata camerei, apa se aprinde intr-un luciu orb.
const SUN_ROT := Vector3(-22.0, -15.0, 0.0)
const WATER_GAIN := 0.87
const WATER_SAT_FIX := 1.18
const BED_Y := -16.0
## Cat de sus sta panza fata de apa opaca (m). Valoarea implicita a probei; testul
## de z-fighting o variaza.
const SHEET_LIFT := 0.06
const MARGIN := 2.0
## Alfa-ul panzei: potrivirea cu apa din jur cere alfa mare, vizibilitatea copiei
## cere alfa mic (se vede cu 1 - alfa); vezi baleiajul din raport.
const CLEAR_ALPHA := 0.65

## [distanta pana la pavilion (m), azimut (grade, spre dreapta)]
const VARIANTS := [[90.0, 30.0], [70.0, 45.0], [110.0, 20.0]]

var _sub: SubViewport
var _cam: Camera3D
var _env: Environment
var _pond_local: Node3D
var _plain: MeshInstance3D
var _holed: Node3D
var _bed: Node3D
var _sheet: MeshInstance3D
var _mirror: Node3D
var _pavilion: Node3D
var _opaque_mat: ShaderMaterial
var _clear_mat: ShaderMaterial
var _hole := Rect2() # in coordonate locale (x, z)
var _dist := 90.0
var _az := 30.0
var _sun: DirectionalLight3D


func _ready() -> void:
	await get_tree().process_frame
	_sub = SubViewport.new()
	_sub.size = IMG
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_sub)
	_cam = Camera3D.new()
	_cam.fov = 68.0
	_cam.far = 380.0
	_cam.position = Vector3(0, 10, 0)
	_cam.rotation_degrees = Vector3(-28.7, 0, 0)
	_sub.add_child(_cam)
	_make_env()
	_cam.environment = _env
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = SUN_ROT
	_sun.light_color = Color.html("FFD8A8")
	_sun.light_energy = 1.0
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 90.0
	add_child(_sun)

	var report: Array = []
	for vi in VARIANTS.size():
		_dist = VARIANTS[vi][0]
		_az = VARIANTS[vi][1]
		report.append(await _run_variant(vi))
	await _alpha_sweep()
	await _zfight_test()
	_print(report)
	get_tree().quit(0)


# ---------------------------------------------------------------- scena ----

func _make_env() -> void:
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color.html("8DB8E8")
	sm.sky_horizon_color = Color.html("F2E2C2")
	sm.ground_bottom_color = Color.html("E9D6BC").darkened(0.4)
	sm.ground_horizon_color = Color.html("F2E2C2")
	sm.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sm
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color.html("A9C0E8")
	_env.ambient_light_energy = 0.35
	_env.fog_enabled = true
	_env.fog_light_color = Color.html("E9D6BC")
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_depth_begin = 90.0
	_env.fog_depth_end = 340.0
	_env.fog_depth_curve = 1.4
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.adjustment_enabled = true
	_env.adjustment_saturation = 1.18
	_env.adjustment_contrast = 1.05


func _water_tint(slot: int) -> Color:
	var c := Palette.color(slot)
	var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	var k := 1.0 / WATER_SAT_FIX
	return Color((lum + (c.r - lum) * k) * WATER_GAIN, (lum + (c.g - lum) * k) * WATER_GAIN,
		(lum + (c.b - lum) * k) * WATER_GAIN).srgb_to_linear()


## Aceleasi uniforme ca Track._water_material() pentru un iaz de tema Kyoto,
## cu ANIMATIA stinsa (drift 0, valuri 0, creste 0): lumea inghetata.
func _water_params(mat: ShaderMaterial) -> void:
	var deep := _water_tint(Palette.SEA_DEEP)
	mat.set_shader_parameter("ripple_tex", load(Palette.DETAIL_PATH))
	mat.set_shader_parameter("ramp_strength", 1.0)
	for key in ["shore_col", "shallow_col", "deep_col"]:
		mat.set_shader_parameter(key, Vector3(deep.r, deep.g, deep.b))
	mat.set_shader_parameter("foam_strength", 0.0)
	mat.set_shader_parameter("glint_strength", 0.0)
	mat.set_shader_parameter("crest_strength", 0.0)
	mat.set_shader_parameter("wave_amp", 0.0)
	mat.set_shader_parameter("drift_near", Vector2.ZERO)
	mat.set_shader_parameter("drift_far", Vector2.ZERO)
	var to_sun := -(Basis.from_euler(Vector3(deg_to_rad(SUN_ROT.x),
		deg_to_rad(SUN_ROT.y), 0.0)) * Vector3.FORWARD)
	mat.set_shader_parameter("sun_dir", to_sun)
	mat.set_shader_parameter("lit_strength", 1.0)
	mat.set_shader_parameter("lit_rough", 0.10) # luciu de iaz (brief §4)
	mat.set_shader_parameter("lit_normal", 1.0)
	mat.set_shader_parameter("lit_wave_len", 4.0)
	mat.set_shader_parameter("lit_wave_speed", 0.0)
	mat.set_shader_parameter("lit_fresnel", 0.25)
	mat.set_shader_parameter("lit_spec", 1.0)
	mat.set_shader_parameter("lit_spec_cap", 3.0)
	var fog_lin := Color.html("E9D6BC").srgb_to_linear() # fog_sky_affect 1.0
	mat.set_shader_parameter("sky_zenith", Vector3(fog_lin.r, fog_lin.g, fog_lin.b))
	mat.set_shader_parameter("sky_horizon", Vector3(fog_lin.r, fog_lin.g, fog_lin.b))
	var sc := Color.html("FFD8A8").srgb_to_linear()
	mat.set_shader_parameter("sun_col", Vector3(sc.r, sc.g, sc.b))
	mat.set_shader_parameter("flow_default", Vector2.ZERO)


func _build_materials() -> void:
	var base := load("res://assets/shaders/water.gdshader") as Shader
	_opaque_mat = ShaderMaterial.new()
	_opaque_mat.shader = base
	_water_params(_opaque_mat)

	# Varianta TRANSPARENTA: acelasi cod, trei modificari. In productie ar fi un
	# fisier de shader (sau un #include); aici e un patch de text la rulare, ca
	# proba sa nu atinga assets/shaders/water.gdshader.
	var code := base.code
	var rm := "render_mode unshaded, cull_back, depth_draw_opaque;"
	assert(code.contains(rm), "render_mode-ul din water.gdshader s-a schimbat")
	code = code.replace(rm, "render_mode unshaded, cull_back, blend_mix, depth_draw_never;\n"
		+ "uniform float clear_alpha : hint_range(0.0, 1.0) = 0.5;\n"
		+ "uniform float clear_edge : hint_range(0.001, 0.5) = 0.08;\n"
		+ "uniform vec3 debug_tint = vec3(1.0, 0.0, 1.0);\n"
		+ "uniform float debug_mix : hint_range(0.0, 1.0) = 0.0;")
	var tail := code.rfind("ALBEDO = base;")
	assert(tail > 0, "ALBEDO = base; lipseste din water.gdshader")
	var end := tail + "ALBEDO = base;".length()
	code = code.substr(0, tail) + "ALBEDO = mix(base, debug_tint, debug_mix);\n" \
		+ "	vec2 ed = min(UV, 1.0 - UV);\n" \
		+ "	ALPHA = mix(clear_alpha, 1.0, debug_mix) * smoothstep(0.0, clear_edge, min(ed.x, ed.y));" \
		+ code.substr(end)
	var sh := Shader.new()
	sh.code = code
	_clear_mat = ShaderMaterial.new()
	_clear_mat.shader = sh
	_water_params(_clear_mat)
	_clear_mat.set_shader_parameter("clear_alpha", CLEAR_ALPHA)


var _pond_step := 0.0  # 0 = un singur patrulater; > 0 = grila (testul cu valuri)
var _sheet_step := 0.0
var _depth_a := 1.0 # COLOR.a al varfurilor: 1 = adanc (valuri 0), 0.357 = varful anvelopei de valuri

func _quad(x0: float, x1: float, z0: float, z1: float, y: float, mat: Material,
		node_name: String, step: float = 0.0) -> MeshInstance3D:
	var nx := 1 if step <= 0.0 else maxi(1, int(ceil((x1 - x0) / step)))
	var nz := 1 if step <= 0.0 else maxi(1, int(ceil((z1 - z0) / step)))
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	for iz in nz + 1:
		for ix in nx + 1:
			var u := float(ix) / float(nx)
			var v := float(iz) / float(nz)
			verts.append(Vector3(lerpf(x0, x1, u), y, lerpf(z0, z1, v)))
			norms.append(Vector3.UP)
			uvs.append(Vector2(u, v))
			cols.append(Color(0, 0, 0, _depth_a))
	var idx := PackedInt32Array()
	for iz in nz:
		for ix in nx:
			var i0 := iz * (nx + 1) + ix
			var i1 := i0 + 1
			var i2 := i0 + (nx + 1) + 1
			var i3 := i0 + (nx + 1)
			# sens orar vazut de sus (conventia Godot): 0-1-2, 0-2-3
			idx.append_array(PackedInt32Array([i0, i1, i2, i0, i2, i3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	mi.name = node_name
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Patrulater vertical, colturile in ordinea acelor de ceasornic vazute din
## interiorul bazinului (conventia Godot: fata = sens orar).
func _poly(c: Array, mat: Material, node_name: String) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([c[0], c[1], c[2], c[3]])
	var n := ((c[1] as Vector3) - (c[0] as Vector3)).cross((c[3] as Vector3) - (c[0] as Vector3)).normalized()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([n, n, n, n])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray([Color(0, 0, 0, 1), Color(0, 0, 0, 1), Color(0, 0, 0, 1), Color(0, 0, 0, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	mi.name = node_name
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _atlas_box(size: Vector3, slot: int, at: Vector3) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var arrays := bm.get_mesh_arrays()
	var uvs := PackedVector2Array()
	uvs.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	uvs.fill(Palette.uv(slot))
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = Palette.world_material()
	mi.position = at
	return mi


## Pavilionul placeholder: etaj de jos in lemn, doua etaje aurii, acoperisuri
## intunecate, un varf. 14.5 m. Baza la y=0 in coordonatele nodului.
func _make_pavilion() -> Node3D:
	var root := Node3D.new()
	var parts := [
		[Vector3(14, 4.2, 10), Palette.LOG_DARK, 2.1],
		[Vector3(15, 0.5, 11), Palette.VOLCANIC_BLACK, 4.45],
		[Vector3(12, 3.6, 8.6), Palette.CAR_YELLOW, 6.5],
		[Vector3(13, 0.5, 9.6), Palette.VOLCANIC_BLACK, 8.55],
		[Vector3(9, 3.2, 7), Palette.CAR_YELLOW, 10.4],
		[Vector3(10.4, 0.5, 8), Palette.VOLCANIC_BLACK, 12.25],
		[Vector3(0.6, 2.0, 0.6), Palette.CAR_YELLOW, 13.5],
	]
	for p: Array in parts:
		root.add_child(_atlas_box(p[0], p[1], Vector3(0, p[2], 0)))
	return root


func _clear_scene() -> void:
	if _pond_local != null:
		_pond_local.queue_free()
		await get_tree().process_frame
	_pond_local = null


func _build_scene() -> void:
	_pond_local = Node3D.new()
	_pond_local.name = "Iaz"
	_pond_local.rotation_degrees = Vector3(0, -_az, 0)
	add_child(_pond_local)

	var d := _dist
	_hole = Rect2(-16.0, -(d - 6.0), 32.0, (d - 6.0) - 0.38 * d) # x, z0, w, h  (z0 = capatul indepartat)
	var z_far := -(d - 6.0)
	var z_near := -0.38 * d
	_plain = _quad(-320, 320, -520, 120, 0.0, _opaque_mat, "IazOpacIntreg")
	_pond_local.add_child(_plain)
	_holed = Node3D.new()
	_holed.name = "IazOpacCuGaura"
	_pond_local.add_child(_holed)
	_holed.add_child(_quad(-320, -16, -520, 120, 0.0, _opaque_mat, "StangaGaura", _pond_step))
	_holed.add_child(_quad(16, 320, -520, 120, 0.0, _opaque_mat, "DreaptaGaura"))
	_holed.add_child(_quad(-16, 16, z_near, 120, 0.0, _opaque_mat, "FataGaura"))
	_holed.add_child(_quad(-16, 16, -520, z_far, 0.0, _opaque_mat, "SpateGaura"))
	# ALBIA: o a doua panza de apa OPACA (acelasi material, zero materiale noi),
	# la -16 m. Nu poate fi cat gaura: privit de la 10 m, prin gaura
	# vezi pe sub apa mult dincolo de ea (raza care trece planul la 6-15 grade
	# ajunge la -16 m la ~2,6x distanta, adica pana la ~230 m si ~40 m lateral),
	# iar o albie sau un bazin cu pereti lasa raza sa iasa si se vede cerul sau
	# dungi verticale de textura pe pereti. Albia se vede NUMAI prin gaura (restul
	# e sub iazul opac).
	_bed = Node3D.new()
	_bed.name = "Albie"
	_pond_local.add_child(_bed)
	# trapez-dreptunghi calculat din raze: gaura scalata cu (10 + 16) / 10 = 2,6 fata
	# de camera (rotunjit la 2,8 pentru marja), nu tot iazul.
	_bed.add_child(_quad(-16.0 * 2.8, 16.0 * 2.8, -(d - 6.0) * 2.8, -0.38 * d * 2.2,
		BED_Y, _opaque_mat, "AlbiePanza"))
	# panza transparenta: gaura + MARGIN pe toate laturile, UV 0..1 pentru topirea marginii
	_sheet = _quad(-16 - MARGIN, 16 + MARGIN, z_far - MARGIN, z_near + MARGIN, 0.0,
		_clear_mat, "PanzaTransparenta", _sheet_step)
	_sheet.position.y = SHEET_LIFT # inaltimea sta pe NOD, ca testul de z-fighting sa o poata varia
	_pond_local.add_child(_sheet)

	# insula (piatra) si pavilionul
	var island := _atlas_box(Vector3(34, 1.0, 21), Palette.MARBLE_GREY,
		Vector3(0, -0.05, -(d + 5.5)))
	island.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_pond_local.add_child(island)
	_pavilion = _make_pavilion()
	_pavilion.position = Vector3(0, 0.45, -d)
	_pond_local.add_child(_pavilion)
	# copia oglindita: NOD cu scale.y = -1, in oglinda planului apei (y = 0)
	_mirror = _make_pavilion()
	_mirror.position = Vector3(0, -0.45, -d)
	_mirror.scale = Vector3(1, -1, 1)
	for c in _mirror.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pond_local.add_child(_mirror)


func _set_mode(mode: String) -> void:
	_plain.visible = mode == "off"
	_holed.visible = mode != "off"
	_bed.visible = mode != "off"
	_sheet.visible = mode != "off"
	_mirror.visible = mode == "on"


# --------------------------------------------------------------- masuri ----

func _grab(label: String, save_path: String = "") -> Image:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sub.get_texture().get_image()
	if save_path != "":
		img.save_png(save_path)
	return img


## Cele 4 colturi ale gaurii proiectate pe ecran (y = 0).
func _hole_poly() -> PackedVector2Array:
	var z_far := -(_dist - 6.0)
	var z_near := -0.38 * _dist
	var pts := PackedVector2Array()
	for c: Vector2 in [Vector2(-16, z_far), Vector2(16, z_far), Vector2(16, z_near), Vector2(-16, z_near)]:
		pts.append(_cam.unproject_position(_pond_local.to_global(Vector3(c.x, 0.0, c.y))))
	return pts


func _in_poly(p: Vector2, poly: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(p, poly)


func _rect_of(poly: PackedVector2Array) -> Rect2i:
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for p in poly:
		mn = mn.min(p)
		mx = mx.max(p)
	mn = mn.max(Vector2.ZERO)
	mx = mx.min(Vector2(IMG.x - 1, IMG.y - 1))
	return Rect2i(Vector2i(mn), Vector2i(mx - mn))


## Diferenta medie absoluta (0..255, pe canale) si fractia de pixeli cu
## diferenta > 8 trepte, DOAR in interiorul poligonului zonei.
func _diff(a: Image, b: Image, poly: PackedVector2Array) -> Dictionary:
	var r := _rect_of(poly)
	var sum := 0.0
	var n := 0
	var over := 0
	for y in range(r.position.y, r.end.y + 1):
		for x in range(r.position.x, r.end.x + 1):
			if not _in_poly(Vector2(x + 0.5, y + 0.5), poly):
				continue
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var dd := (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0 * 255.0
			sum += dd
			n += 1
			if dd > 8.0:
				over += 1
	return {"n": n, "mean": sum / maxf(n, 1.0), "frac": float(over) / maxf(n, 1.0)}


func _mean_lum(img: Image, poly: PackedVector2Array) -> float:
	var r := _rect_of(poly)
	var sum := 0.0
	var n := 0
	for y in range(r.position.y, r.end.y + 1):
		for x in range(r.position.x, r.end.x + 1):
			if poly.is_empty() or _in_poly(Vector2(x + 0.5, y + 0.5), poly):
				sum += img.get_pixel(x, y).get_luminance()
				n += 1
	return sum / maxf(n, 1.0)


func _frame_lum(img: Image) -> float:
	var sum := 0.0
	var n := 0
	for y in range(0, IMG.y, 2):
		for x in range(0, IMG.x, 2):
			sum += img.get_pixel(x, y).get_luminance()
			n += 1
	return sum / float(n)


func _visible_materials() -> Dictionary:
	var out := {}
	var stack: Array[Node] = [_pond_local]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi == null or not mi.is_visible_in_tree():
			continue
		var m: Material = mi.material_override
		if m == null:
			m = mi.mesh.surface_get_material(0)
		var nm := "atlas (world_material)"
		if m == _opaque_mat:
			nm = "apa v12 opaca"
		elif m == _clear_mat:
			nm = "apa v12 TRANSPARENTA (nou)"
		out[nm] = int(out.get(nm, 0)) + 1
	return out


func _info() -> Dictionary:
	var rid := _sub.get_viewport_rid()
	var t := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	return {
		"obiecte": RenderingServer.viewport_get_render_info(rid, t, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME),
		"primitive": RenderingServer.viewport_get_render_info(rid, t, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
		"desene": RenderingServer.viewport_get_render_info(rid, t, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
	}


func _run_variant(vi: int) -> Dictionary:
	await _clear_scene()
	_build_materials()
	_build_scene()
	for i in 4:
		await get_tree().process_frame
	var tag := "v%d_d%d_az%d" % [vi, int(_dist), int(_az)]
	var poly := _hole_poly()
	var res := {"tag": tag, "dist": _dist, "az": _az, "hole_px": 0}
	var imgs := {}
	var mats := {}
	var info := {}
	for mode: String in ["off", "sheet", "on"]:
		_set_mode(mode)
		_sub.debug_draw = Viewport.DEBUG_DRAW_DISABLED
		imgs[mode] = await _grab(mode, "res://snapshots/kyoto_reflexie_%s_%s.png" % [tag, mode])
		mats[mode] = _visible_materials()
		info[mode] = _info()
	# overdraw
	var ov := {}
	for mode: String in ["off", "sheet", "on"]:
		_set_mode(mode)
		_sub.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
		var oi := await _grab(mode, "res://snapshots/kyoto_reflexie_%s_%s_overdraw.png" % [tag, mode])
		ov[mode] = {"zona": _mean_lum(oi, poly), "cadru": _frame_lum(oi)}
	_sub.debug_draw = Viewport.DEBUG_DRAW_DISABLED
	var ctrl := PackedVector2Array([Vector2(60, 560), Vector2(900, 560), Vector2(900, 1040), Vector2(60, 1040)])
	res["control"] = _diff(imgs["on"], imgs["off"], ctrl)
	res["imgs_diff_on_off"] = _diff(imgs["on"], imgs["off"], poly)
	res["imgs_diff_on_sheet"] = _diff(imgs["on"], imgs["sheet"], poly)
	res["imgs_diff_sheet_off"] = _diff(imgs["sheet"], imgs["off"], poly)
	res["poly"] = poly
	res["mats"] = mats
	res["info"] = info
	res["overdraw"] = ov
	res["lum_zone"] = {"off": _mean_lum(imgs["off"], poly), "on": _mean_lum(imgs["on"], poly)}
	# imagine de diferenta amplificata x4 (on - off), pentru ochi
	var dimg := Image.create(IMG.x, IMG.y, false, Image.FORMAT_RGB8)
	for y in IMG.y:
		for x in IMG.x:
			var a: Color = (imgs["on"] as Image).get_pixel(x, y)
			var b: Color = (imgs["off"] as Image).get_pixel(x, y)
			dimg.set_pixel(x, y, Color(minf(absf(a.r - b.r) * 4.0, 1.0),
				minf(absf(a.g - b.g) * 4.0, 1.0), minf(absf(a.b - b.b) * 4.0, 1.0)))
	dimg.save_png("res://snapshots/kyoto_reflexie_%s_diff_x4.png" % tag)
	return res


## Z-fighting: panza devine magenta OPACA (debug_mix 1) si se pune la cate o
## inaltime fata de apa opaca; in banda de suprapunere (MARGIN m, in stanga
## gaurii) toti pixelii trebuie sa fie magenta. Camera tremura cu 5 deplasari de
## ordinul milimetrilor.
var _zf := {}
var _sweep := []

func _zfight_test() -> void:
	for waves in [false, true]:
		_dist = 90.0
		_az = 30.0
		await _clear_scene()
		_pond_step = 9.5 if waves else 0.0  # grila fina a iazului din track.gd (9,5 m)
		_sheet_step = 4.0 if waves else 0.0
		_depth_a = 0.357 if waves else 1.0   # varful anvelopei de valuri
		_build_materials()
		var amp := 0.12 if waves else 0.0    # SEA_WAVE_AMP din track.gd
		_opaque_mat.set_shader_parameter("wave_amp", amp)
		_clear_mat.set_shader_parameter("wave_amp", amp)
		if waves:
			_opaque_mat.set_shader_parameter("wave_reef", 0.357)
			_clear_mat.set_shader_parameter("wave_reef", 0.357)
		_build_scene()
		_set_mode("sheet")
		_clear_mat.set_shader_parameter("debug_mix", 1.0)
		_clear_mat.set_shader_parameter("clear_edge", 0.001)
		var z_far := -(_dist - 6.0)
		var z_near := -0.38 * _dist
		var strip := [Vector2(-16 - MARGIN + 0.1, z_far), Vector2(-16 - 0.1, z_far),
			Vector2(-16 - 0.1, z_near), Vector2(-16 - MARGIN + 0.1, z_near)]
		var jitters := [Vector3(0, 0, 0), Vector3(0.0007, 0, 0), Vector3(-0.0011, 0.0004, 0),
			Vector3(0.0003, -0.0009, 0.0006), Vector3(0.0015, 0.0006, -0.0004)]
		var lifts: Array = [-0.002, 0.0, 0.002, 0.01, 0.03, 0.06] if not waves 			else [0.0, 0.03, 0.06, 0.12, 0.2, 0.3]
		for lift: float in lifts:
			_sheet.position.y = lift
			var row := []
			for jv: Vector3 in jitters:
				_cam.position = Vector3(0, 10, 0) + jv
				var img := await _grab("zf")
				var poly := PackedVector2Array()
				for c: Vector2 in strip:
					poly.append(_cam.unproject_position(_pond_local.to_global(Vector3(c.x, 0.0, c.y))))
				var r := _rect_of(poly)
				var tot := 0
				var mag := 0
				for y in range(r.position.y, r.end.y + 1):
					for x in range(r.position.x, r.end.x + 1):
						if not _in_poly(Vector2(x + 0.5, y + 0.5), poly):
							continue
						tot += 1
						var c := img.get_pixel(x, y)
						if c.r > 0.5 and c.b > 0.5 and c.g < 0.5 * c.r:
							mag += 1
				row.append([tot, mag])
			_zf["%s|%.3f" % ["valuri 0.12 m, grila 9.5/4 m" if waves else "calm (wave_amp 0)", lift]] = row
		_cam.position = Vector3(0, 10, 0)
	_pond_step = 0.0
	_sheet_step = 0.0
	_depth_a = 1.0


## Cat de opaca sa fie panza: un alfa mare potriveste mai bine apa din jur (panza
## are aceeasi culoare ca iazul), dar estompeaza copia oglindita (se vede cu
## 1 - alfa). Pe varianta 0.
func _alpha_sweep() -> void:
	_dist = 90.0
	_az = 30.0
	await _clear_scene()
	_build_materials()
	_build_scene()
	for i in 3:
		await get_tree().process_frame
	var poly := _hole_poly()
	_set_mode("off")
	var off := await _grab("sw_off")
	for a: float in [0.35, 0.5, 0.65, 0.8, 0.9]:
		_clear_mat.set_shader_parameter("clear_alpha", a)
		_set_mode("sheet")
		var sh := await _grab("sw_sheet")
		_set_mode("on")
		var on := await _grab("sw_on", "res://snapshots/kyoto_reflexie_alfa_%d.png" % int(a * 100.0))
		_sweep.append([a, _diff(sh, off, poly), _diff(on, sh, poly)])


# --------------------------------------------------------------- raport ----

func _print(report: Array) -> void:
	print("=== REFLEXIA PAVILIONULUI (apa v12, panza transparenta locala) ===")
	print("camera de joc: 10 m sus, pitch -28.7, FOV 68; imagine %dx%d; lume inghetata" % [IMG.x, IMG.y])
	for r: Dictionary in report:
		print("--- varianta %s: pavilion la %.0f m, azimut %.0f grade ---" % [r["tag"], r["dist"], r["az"]])
		var d1: Dictionary = r["imgs_diff_on_off"]
		var d2: Dictionary = r["imgs_diff_on_sheet"]
		var d3: Dictionary = r["imgs_diff_sheet_off"]
		print("zona reflexiei (poligonul gaurii proiectat): %d px = %.2f%% din cadru" % [
			d1["n"], 100.0 * d1["n"] / float(IMG.x * IMG.y)])
		print("diferenta medie pe canal (0-255) / fractie de pixeli cu delta > 8:")
		print("   ON  - OFF   : %6.2f  /  %5.1f%%   (tot ce aduce reflexia)" % [d1["mean"], 100.0 * d1["frac"]])
		print("   ON  - SHEET : %6.2f  /  %5.1f%%   (doar copia oglindita: atribuire)" % [d2["mean"], 100.0 * d2["frac"]])
		print("   SHEET - OFF : %6.2f  /  %5.1f%%   (doar panza + albia, fara copie)" % [d3["mean"], 100.0 * d3["frac"]])
		var cz: Dictionary = r["control"]
		print("   control (apa departe de zona, ON-OFF): %6.2f  /  %5.1f%%   (zgomotul de fond al masuratorii)" % [cz["mean"], 100.0 * cz["frac"]])
		var lz: Dictionary = r["lum_zone"]
		print("luminanta medie pe zona: OFF %.3f  ON %.3f" % [lz["off"], lz["on"]])
		print("materiale vizibile (mesh-uri pe material):")
		for mode: String in ["off", "sheet", "on"]:
			var m: Dictionary = r["mats"][mode]
			print("   %-5s %d materiale  %s" % [mode, m.size(), JSON.stringify(m)])
		print("RenderingServer (obiecte / primitive / desene):")
		for mode: String in ["off", "sheet", "on"]:
			var i: Dictionary = r["info"][mode]
			print("   %-5s %s / %s / %s" % [mode, i["obiecte"], i["primitive"], i["desene"]])
		print("overdraw (luminanta medie, DEBUG_DRAW_OVERDRAW; un strat opac = referinta OFF pe zona):")
		var ref: float = r["overdraw"]["off"]["zona"]
		for mode: String in ["off", "sheet", "on"]:
			var o: Dictionary = r["overdraw"][mode]
			print("   %-5s zona %.4f (x%.2f fata de OFF)   cadru intreg %.4f" % [
				mode, o["zona"], o["zona"] / maxf(ref, 1e-6), o["cadru"]])
	print("--- varianta 0, alfa panzei: potrivire cu apa din jur (SHEET-OFF) vs vizibilitatea copiei (ON-SHEET) ---")
	for e: Array in _sweep:
		print("   alfa %.2f:  SHEET-OFF %5.2f / %4.1f%%    ON-SHEET %5.2f / %4.1f%%" % [
			e[0], e[1]["mean"], 100.0 * e[1]["frac"], e[2]["mean"], 100.0 * e[2]["frac"]])
	print("--- z-fighting: banda de suprapunere (2 m) panza magenta opaca peste apa opaca ---")
	print("(pixeli magenta / pixeli in banda, pe 5 cadre cu camera tremurata; 100% = fara z-fighting)")
	for key: String in _zf:
		var row: Array = _zf[key]
		var parts := PackedStringArray()
		for e: Array in row:
			parts.append("%d/%d=%.0f%%" % [e[1], e[0], 100.0 * float(e[1]) / maxf(float(e[0]), 1.0)])
		print("   %-40s %s" % [key.replace("|", "  panza la +") + " m:", "  ".join(parts)])
