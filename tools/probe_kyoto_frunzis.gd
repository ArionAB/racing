extends Node
## VITRINA CLASELOR DE FRUNZIS (Kyoto, brief §7 pasul 1e): iese roșul din tentă
## după remap? Cate o coroană + o placă verticală pe fiecare clasă nouă, plus
## `red_valley_tuff` (Cappadocia) alături, ca arțarul să se judece față de tuf.
##
##   Godot_v4.7-stable_win64_console.exe --path . res://tools/ProbeKyotoFrunzis.tscn
##
## CERE FEREASTRA (randare; memoria `snapshot-nu-merge-headless`).
##
## Ce măsoară, pe PIXELI (nu pe calcule), 5 eșantioane de cameră (memoria
## `o-captura-nu-e-un-verdict`):
##   1. ALBEDO: aceleași materiale ale jocului, dar UNSHADED + tonemap liniar +
##      fără ajustări: media sRGB a plăcii = albedo-ul efectiv (tentă x dală,
##      după CLASS_LIFT), de comparat cu hex-ul slotului-țintă.
##   2. LUMINA din brief §4 (soare 22°, #FFD8A8, ambient 0,35 rece, FILMIC,
##      saturație 1,18, contrast 1,05 ca Track._build_environment): media sRGB a
##      plăcii de clasă față de media unei plăci pe ATLAS (slotul-țintă) sub
##      aceeași lumină — adică "arată clasa ca slotul pe care îl înlocuiește?".
## Plăcile de MĂSURĂ sunt ziduri verticale cu fața spre soare (N·L = cos 22°), cu
## latura egală cu un NUMĂR ÎNTREG de repetiții ale clasei (1 / CLASS_TRIPLANAR_
## SCALE): proiecția e în spațiul lumii, deci o fereastră mai mică decât o
## repetiție ar măsura o bucată din dală (golurile mari ale frunzișului ar fi
## ori în ea, ori nu), nu media ei. Pe o repetiție întreagă media e exactă.
## Imaginea se randează într-un SubViewport 1920x1080 (independent de fereastră).
## Coroanele (grupul `Visual`) sunt separate de ziduri (grupul `Measure`): se
## fotografiază pe rând, ca să nu se acopere.
##
## Ieșire: snapshots/kyoto_frunzis_{albedo,lit,vitrina,back,close}.png + cifre.

const IMG := Vector2i(1920, 1080)
const SUN_ROT := Vector3(-22.0, 225.0, 0.0)
const SPACING := 5.6

## [clasă, slotul-țintă din atlas (-1 = doar referință vizuală)]
const ITEMS := [
	["red_valley_tuff", -1],
	["maple_crimson", Palette.KERB_RED],
	["maple_orange", Palette.CAR_RED],
	["ginkgo_gold", Palette.CAR_YELLOW],
	["leaf_litter", Palette.LARCH_RUST],
	["machiya_wood", Palette.LOG_DARK],
	["moss", Palette.TROPICAL_GREEN],
]

## [yaw cameră (grade, față de axa soarelui), distanță, înălțime]
## ferestre de ~1/3 din zid (centre in coordonate normalizate -1..1): cat variaza
## media pe un petic mai mic decat o repetitie (o coroana de 8 m nu vede toata dala)
const WINDOWS := [[-0.55, 0.55], [0.55, 0.55], [-0.55, -0.55], [0.55, -0.55], [0.0, 0.0]]

const SAMPLES := [[0.0, 95.0, 6.0], [4.0, 88.0, 7.0], [-4.0, 100.0, 5.0],
	[7.0, 92.0, 6.5], [-7.0, 98.0, 5.5]]

var _sub: SubViewport
var _cam: Camera3D
var _n := Vector3.ZERO           # normala plăcilor (spre soare), orizontală
var _center := Vector3(0.0, 2.5, 0.0)
var _slabs: Array = []           # [{cls, slot, slab: MeshInstance3D, ref: MeshInstance3D}]
var _all_meshes: Array = []      # [{mi, lit: Material, flat: Material}]
var _env_lit: Environment
var _env_albedo: Environment
var _only_pass := ""
var _measure: Node3D
var _visual: Node3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pass="):
			_only_pass = a.trim_prefix("--pass=")
	await get_tree().process_frame
	_build()
	for i in 6:
		await get_tree().process_frame

	var report := {}
	_measure.visible = true
	_visual.visible = false
	var passes := [["albedo", _env_albedo, true], ["lit", _env_lit, false]]
	for p: Array in passes:
		if _only_pass != "" and _only_pass != p[0]:
			continue
		_set_flat(p[2])
		_cam.environment = p[1]
		report[p[0]] = await _run_pass(p[0], true)
	# vedere în contralumină (doar vizual, fără cifre)
	if _only_pass == "" or _only_pass == "back":
		_set_flat(false)
		_cam.environment = _env_lit
		_measure.visible = false
		_visual.visible = true
		await _shoot_visual()
	_print_report(report)
	get_tree().quit(0)


func _build() -> void:
	var rot := Basis.from_euler(Vector3(deg_to_rad(SUN_ROT.x), deg_to_rad(SUN_ROT.y), 0.0))
	var d := rot * Vector3.FORWARD # directia in care bat razele
	var dh := Vector3(d.x, 0.0, d.z).normalized()
	_n = -dh

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = SUN_ROT
	sun.light_color = Color.html("FFD8A8")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

	_env_lit = _make_env(true)
	_env_albedo = _make_env(false)

	_sub = SubViewport.new()
	_sub.size = IMG
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub.msaa_3d = Viewport.MSAA_DISABLED
	add_child(_sub)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	_cam.far = 300.0
	_sub.add_child(_cam)

	# sol (atlas CONCRETE): primeste umbrele coroanelor
	var ground := _atlas_box(Vector3(300, 0.2, 300), Palette.CONCRETE)
	ground.position = Vector3(0, -0.1, 0)
	ground.name = "Ground"
	add_child(ground)
	_register(ground)

	var right := (-_n).cross(Vector3.UP).normalized()
	var yaw := atan2(_n.x, _n.z)
	_measure = Node3D.new()
	_measure.name = "Measure"
	add_child(_measure)
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	# --- ZIDURILE DE MASURA: latura = k repetitii, k ales ca latura sa fie >= 4 m
	var widths: Array[float] = []
	var total := 0.0
	for it in ITEMS:
		var period := 1.0 / float(Palette.CLASS_TRIPLANAR_SCALE[it[0]])
		var k := maxi(1, int(ceil(4.0 / period)))
		widths.append(period * float(k))
		total += period * float(k) + 2.0 + 1.5
	var cursor := -total * 0.5
	for i in ITEMS.size():
		var cls: String = ITEMS[i][0]
		var slot: int = ITEMS[i][1]
		var w: float = widths[i]
		var mat := Palette.triplanar_class_material(cls)
		var cx := cursor + w * 0.5
		var wall := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w, w, 0.3)
		wall.mesh = bm
		wall.material_override = mat
		wall.position = right * cx + Vector3(0, w * 0.5, 0)
		wall.rotation.y = yaw
		wall.name = "Wall_" + cls
		_measure.add_child(wall)
		_register(wall)
		var ref: MeshInstance3D = null
		if slot >= 0:
			ref = _atlas_box(Vector3(2.0, w, 0.3), slot)
			ref.position = right * (cursor + w + 1.0) + Vector3(0, w * 0.5, 0)
			ref.rotation.y = yaw
			ref.name = "Ref_" + cls
			_measure.add_child(ref)
			_register(ref)
		_slabs.append({"cls": cls, "slot": slot, "slab": wall, "ref": ref})
		cursor += w + 2.0 + 1.5

	# --- GRUPUL VIZUAL: coroana + placa mica + referinta pe atlas, pe fiecare clasa
	for i in ITEMS.size():
		var cls: String = ITEMS[i][0]
		var slot: int = ITEMS[i][1]
		var base := right * ((i - (ITEMS.size() - 1) * 0.5) * SPACING)
		var mat := Palette.triplanar_class_material(cls)
		var crown := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 32
		sm.rings = 16
		crown.mesh = sm
		crown.scale = Vector3(1.9, 0.85, 1.9)
		crown.position = base + Vector3(0, 3.7, 0)
		crown.material_override = mat
		_visual.add_child(crown)
		_register(crown)
		var trunk := _atlas_box(Vector3(0.35, 2.2, 0.35), Palette.LOG_DARK)
		trunk.position = base + Vector3(0, 2.2, 0)
		trunk.rotation.y = yaw
		_visual.add_child(trunk)
		_register(trunk)
		var slab := MeshInstance3D.new()
		var sbm := BoxMesh.new()
		sbm.size = Vector3(4.0, 1.6, 0.2)
		slab.mesh = sbm
		slab.material_override = mat
		slab.position = base + Vector3(0, 1.4, 0) + _n * 2.2
		slab.rotation.y = yaw
		_visual.add_child(slab)
		_register(slab)
		if slot >= 0:
			var rf := _atlas_box(Vector3(4.0, 0.7, 0.2), slot)
			rf.position = base + Vector3(0, 0.35, 0) + _n * 2.2
			rf.rotation.y = yaw
			_visual.add_child(rf)
			_register(rf)
		var lab := Label3D.new()
		lab.text = cls + ("" if slot < 0 else "  #" + Palette.HEX[slot])
		lab.font_size = 40
		lab.pixel_size = 0.012
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.shaded = false
		lab.modulate = Color(0.1, 0.1, 0.1)
		lab.position = base + Vector3(0, 5.6, 0)
		_visual.add_child(lab)


func _make_env(game_like: bool) -> Environment:
	var env := Environment.new()
	if game_like:
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = Color.html("8DB8E8")
		sm.sky_horizon_color = Color.html("F2E2C2")
		sm.ground_bottom_color = Color.html("E9D6BC").darkened(0.4)
		sm.ground_horizon_color = Color.html("F2E2C2")
		sm.sun_angle_max = 0.0
		var sky := Sky.new()
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color.html("A9C0E8")
		env.ambient_light_energy = 0.35
		# fara ceata: camera de masura sta la ~95 m, in ceata de joc (begin 90 m)
		# culoarea s-ar amesteca cu #E9D6BC; ceata e masurata separat, aici nu.
		env.fog_enabled = false
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 1.0
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.18
		env.adjustment_contrast = 1.05
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.BLACK
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.adjustment_enabled = false
	return env


## Cutie pe ATLAS: BoxMesh cu toate UV-urile pe centrul slotului. NU PaletteBox:
## infasurarea lui e inversata fata de convetia Godot (fata din spate iese
## vizibila, cu normala spre interior), deci o cutie vazuta de afara ar iesi
## luminata ca o fata din umbra — falsifica comparatia cu clasa.
func _atlas_box(size: Vector3, slot: int) -> MeshInstance3D:
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
	return mi


func _register(mi: MeshInstance3D) -> void:
	var lit: Material = mi.material_override
	var flat := (lit as BaseMaterial3D).duplicate() as BaseMaterial3D
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_all_meshes.append({"mi": mi, "lit": lit, "flat": flat})


func _set_flat(flat: bool) -> void:
	for e: Dictionary in _all_meshes:
		(e["mi"] as MeshInstance3D).material_override = e["flat"] if flat else e["lit"]


func _place_cam(yaw_deg: float, dist: float, height: float, flip: bool = false,
		look_y: float = 2.4) -> void:
	var n := _n if not flip else -_n
	var off := n.rotated(Vector3.UP, deg_to_rad(yaw_deg)) * dist
	_cam.position = Vector3(0, height, 0) + off
	_cam.look_at(Vector3(0, look_y, 0), Vector3.UP)


func _run_pass(pass_name: String, save: bool) -> Array:
	var out: Array = []
	for si in SAMPLES.size():
		var s: Array = SAMPLES[si]
		_place_cam(s[0], s[1], s[2], false, 5.0)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sub.get_texture().get_image()
		if si == 0 and save:
			var path := "res://snapshots/kyoto_frunzis_%s.png" % pass_name
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://snapshots"))
			img.save_png(path)
		var row := {}
		for it: Dictionary in _slabs:
			var wins: Array = []
			for wc: Array in WINDOWS:
				wins.append(_mean_rect(img, it["slab"], wc[0], wc[1], 0.28, 0.28))
			row[it["cls"]] = {"slab": _mean_rect(img, it["slab"]), "wins": wins,
				"ref": _mean_rect(img, it["ref"]) if it["ref"] != null else Color(-1, -1, -1)}
		out.append(row)
	return out


func _shoot_visual() -> void:
	_cam.fov = 50.0
	var right := (-_n).cross(Vector3.UP).normalized()
	# [nume, contralumina?, distanta, inaltime, indexul clasei din centru (-1 = tot)]
	for shot: Array in [["vitrina", false, 24.0, 3.2, -1], ["back", true, 24.0, 3.2, -1],
			["close_maple", false, 12.0, 3.3, 1.5], ["close_maple_back", true, 12.0, 3.3, 1.5],
			["close_tail", false, 12.0, 3.0, 4.5]]:
		var cx := 0.0 if float(shot[4]) < 0.0 else (float(shot[4]) - (ITEMS.size() - 1) * 0.5) * SPACING
		var n := _n if not shot[1] else -_n
		_cam.position = right * cx + Vector3(0, shot[3], 0) + n * shot[2]
		_cam.look_at(right * cx + Vector3(0, 3.0, 0), Vector3.UP)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_sub.get_texture().get_image().save_png("res://snapshots/kyoto_frunzis_%s.png" % shot[0])
	_cam.fov = 40.0


## Media sRGB (0..1) din centrul (60%) proiectiei placii pe ecran, fara marginile
## (muchii, antialiasing, plana vecina).
func _mean_rect(img: Image, mi: MeshInstance3D, cx: float = 0.0, cy: float = 0.0,
		hx: float = 0.6, hy: float = 0.6) -> Color:
	var box := (mi.mesh as Mesh).get_aabb()
	var c := box.get_center()
	var h := box.size * 0.5
	var pts: Array[Vector3] = []
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			pts.append(mi.global_transform * (c + Vector3(h.x * (cx + sx * hx), h.y * (cy + sy * hy), h.z)))
	var minp := Vector2(1e9, 1e9)
	var maxp := Vector2(-1e9, -1e9)
	for p in pts:
		var q := _cam.unproject_position(p)
		minp = minp.min(q)
		maxp = maxp.max(q)
	var x0 := clampi(int(minp.x), 0, img.get_width() - 1)
	var x1 := clampi(int(maxp.x), 0, img.get_width() - 1)
	var y0 := clampi(int(minp.y), 0, img.get_height() - 1)
	var y1 := clampi(int(maxp.y), 0, img.get_height() - 1)
	var sum := Vector3.ZERO
	var n := 0
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var px := img.get_pixel(x, y)
			sum += Vector3(px.r, px.g, px.b)
			n += 1
	if n == 0:
		return Color(-1, -1, -1)
	sum /= float(n)
	return Color(sum.x, sum.y, sum.z)


func _fmt(c: Color) -> String:
	return "(%3d,%3d,%3d)" % [roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0)]


func _hsv(c: Color) -> String:
	return "H%3d S%.2f V%.2f" % [roundi(c.h * 360.0), c.s, c.v]


func _avg(rows: Array, cls: String, key: String) -> Color:
	var s := Vector3.ZERO
	for r: Dictionary in rows:
		var c: Color = r[cls][key]
		s += Vector3(c.r, c.g, c.b)
	s /= float(rows.size())
	return Color(s.x, s.y, s.z)


func _print_report(rep: Dictionary) -> void:
	print("=== VITRINA FRUNZIS KYOTO: 5 esantioane de camera, medie pe placa (sRGB) ===")
	if rep.has("albedo"):
		print("--- 1. ALBEDO (unshaded, tonemap liniar): clasa vs hex-ul slotului-tinta ---")
		var rows: Array = rep["albedo"]
		for it: Dictionary in _slabs:
			var cls: String = it["cls"]
			var per := PackedStringArray()
			for r: Dictionary in rows:
				per.append(_fmt(r[cls]["slab"]))
			var m := _avg(rows, cls, "slab")
			if it["slot"] >= 0:
				var t := Palette.color(it["slot"])
				print("%-15s tinta #%s %s %s" % [cls, Palette.HEX[it["slot"]], _fmt(t), _hsv(t)])
				var rfa := _avg(rows, cls, "ref")
				print("                 atlas unshaded %s" % _fmt(rfa))
				print("                 masurat %s %s   delta (%+d,%+d,%+d)" % [
					_fmt(m), _hsv(m), roundi((m.r - t.r) * 255.0),
					roundi((m.g - t.g) * 255.0), roundi((m.b - t.b) * 255.0)])
			else:
				print("%-15s (fara tinta) masurat %s %s" % [cls, _fmt(m), _hsv(m)])
			print("                 5 esantioane: %s" % " ".join(per))
			var wl := PackedStringArray()
			for wi in WINDOWS.size():
				wl.append(_fmt((rows[0][cls]["wins"] as Array)[wi]))
			print("                 5 ferestre de ~1/3 din zid: %s" % " ".join(wl))
	if rep.has("lit"):
		print("--- 2. LUMINA brief §4 (FILMIC, sat 1.18): clasa vs placa pe ATLAS sub aceeasi lumina ---")
		var rows2: Array = rep["lit"]
		for it: Dictionary in _slabs:
			var cls: String = it["cls"]
			var per := PackedStringArray()
			for r: Dictionary in rows2:
				per.append(_fmt(r[cls]["slab"]))
			var m := _avg(rows2, cls, "slab")
			if it["slot"] >= 0:
				var rf := _avg(rows2, cls, "ref")
				print("%-15s clasa %s %s | atlas #%s %s %s | delta (%+d,%+d,%+d)" % [
					cls, _fmt(m), _hsv(m), Palette.HEX[it["slot"]], _fmt(rf), _hsv(rf),
					roundi((m.r - rf.r) * 255.0), roundi((m.g - rf.g) * 255.0),
					roundi((m.b - rf.b) * 255.0)])
			else:
				print("%-15s clasa %s %s" % [cls, _fmt(m), _hsv(m)])
			print("                 5 esantioane: %s" % " ".join(per))
