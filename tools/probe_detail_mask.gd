extends SceneTree
## SONDA: masca de detaliu per slot pe `Palette.world_material()` — functioneaza?
##
## Ruleaza CU FEREASTRA (randeaza). Cere lacatul GPU comun:
##   mkdir D:/GameDev/.render_lock ; ... ; rmdir D:/GameDev/.render_lock
##   godot --path . --resolution 1400x1000 --script res://tools/probe_detail_mask.gd -- --out=<dir>
##
## Trei lucruri, independente unul de altul:
##  1. (codul generat nu se poate cere din GDScript: `get_shader_rid` nu e
##     expus; linia e citata din scene/resources/material.cpp, tag 4.7-stable)
##  2. MASCA IMPORTATA: valorile R si A per slot din textura asa cum o incarca
##     jocul (compresie VRAM + mipmap-uri incluse), fata de PNG-ul sursa.
##  3. EXPERIMENTUL: patrate plate pe sloturi cu alfa cunoscut (0 .. 255),
##     randate de sus cu lumina uniforma, pe cinci variante de material:
##       shipped  materialul lumii exact cum e in joc
##       r0a1     aceeasi, masca cu R=G=B=0 si A=1 peste tot
##       r1a0     aceeasi, masca cu R=G=B=1 si A=0 peste tot
##       fix      aceeasi, masca cu R=G=B=A=taria slotului (necomprimata)
##       off      detail_enabled = false (podeaua: zero granulatie)
##       fade     prop_detail_fade.gdshader cu masca livrata (stingerea departe)
##       fade_fix prop_detail_fade cu masca `fix`
##       grain    Palette.grain_material() (GRAIN_PREFIX): fara masca, plin
##     Daca motorul citeste ALFA: r0a1 = plin, r1a0 = curat, shipped urmeaza
##     alfa. Daca citeste ROSU: invers, iar shipped e plin pe toate sloturile.
##     Iese <out>/quads.png si tabelul granulatiei (std/medie, %) per patrat.
##
## VERDICT (cod de iesire 1 la PICA) — verifica MECANISMUL, nu un tabel anume:
##   - contractul motorului: masca cu R=0 da sub 1%, cu R=1 peste 5% (motorul
##     citeste R; daca o versiune de Godot schimba canalul, pica aici);
##   - pe ambele cai (`shipped` = materialul lumii, `fade` = prop_detail_fade),
##     fiecare slot urmeaza tabelul din PNG-ul sursa: taria 0 sub 1%, taria > 0
##     intre 0.8x si 1.25x fata de masca de referinta din memorie (`fix`,
##     `fade_fix`), construita din acelasi PNG;
##   - `Palette.grain_material()` (GRAIN_PREFIX) da granulatie plina pe orice slot
##     (0.8x..1.25x fata de R=1).
## Masurat 17 nov 2026, RTX 3070, D3D12, cu tabelul GRADAT (ramura B):
##   cu masca veche (alba pe RGB, BC3+mipmap) PICA: 11.0-12.0% pe TOATE sloturile,
##     inclusiv 14; pe D3D12 si `fade` e 27-32% peste tot — textura nu se creeaza
##     (CreateResource 0x80070057) si shaderul cade pe alb;
##   cu masca R=G=B=A, necomprimata, fara mipmap, fara fix_alpha_border: OK
##     (0.25 / 1.48 / 2.21 / 2.40 / 4.30 / 7.53 / 11.15% pe 14/22/5/0/12/8/3).
## Cu un tabel 0/1 (14..16 = 0, restul 1.0; varianta C, respinsa): OK si pe D3D12 si pe Vulkan — 0.25%
##   pe 14, 10.7-12.0% pe restul (= R=1); `fade` 0.21% pe 14, 27-32% pe restul.

const SLOTS_TESTED: Array[int] = [14, 22, 5, 0, 12, 8, 3]
const VARIANTS: Array[String] = ["shipped", "r0a1", "r1a0", "fix", "off", "fade", "fade_fix", "grain"]
const QUAD := 4.0
const STEP := 5.0

var _out := "user://"
var _frames := 0
var _cam: Camera3D
var _rects := {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_dump_mask()
	_build()


func _mask_image(fill: Callable) -> ImageTexture:
	var img := Image.create(Palette.SLOTS, 1, false, Image.FORMAT_RGBA8)
	for s in Palette.SLOTS:
		img.set_pixel(s, 0, fill.call(s))
	return ImageTexture.create_from_image(img)


func _src_alpha() -> PackedFloat32Array:
	var src := Image.load_from_file(ProjectSettings.globalize_path(Palette.DETAIL_MASK_PATH))
	var out := PackedFloat32Array()
	for s in Palette.SLOTS:
		out.append(src.get_pixel(s, 0).a)
	return out


func _dump_mask() -> void:
	var tex := load(Palette.DETAIL_MASK_PATH) as Texture2D
	var img := tex.get_image()
	print("MASK imported: class=%s format=%d mipmaps=%s compressed=%s size=%dx%d" % [
		tex.get_class(), img.get_format(), img.has_mipmaps(), img.is_compressed(),
		img.get_width(), img.get_height()])
	if img.is_compressed():
		img.decompress()
	var src := _src_alpha()
	var line := "MASK slot: src_a / imp_r / imp_a :"
	for s in Palette.SLOTS:
		var c := img.get_pixel(s, 0)
		line += " %d:%.3f/%.3f/%.3f" % [s, src[s], c.r, c.a]
	print(line)
	if img.has_mipmaps():
		# Mip 1 (16x1): fiecare texel e media a doua sloturi vecine.
		var ofs := img.get_mipmap_offset(1)
		print("MASK mip1 offset=%d (exista nivelul 16x1: sloturile vecine se amesteca daca e esantionat)" % ofs)


func _quad_mesh(slot: int) -> ArrayMesh:
	var h := QUAD * 0.5
	var v := PackedVector3Array([
		Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h),
		Vector3(-h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)])
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var col := PackedColorArray()
	for i in v.size():
		n.append(Vector3.UP)
		uv.append(Palette.uv(slot))
		col.append(Color.WHITE)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_COLOR] = col
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


func _variant(name: String) -> Material:
	var world := Palette.world_material()
	if name == "shipped":
		return world
	if name == "grain":
		return Palette.grain_material()
	if name.begins_with("fade"):
		# prop_detail_fade cu stingerea impinsa departe (camera sta la 40 m):
		# ramane doar masca, ca sa se compare cu materialul standard.
		var fm := Palette.faded_detail_material().duplicate() as ShaderMaterial
		fm.set_shader_parameter("detail_near_m", 1000.0)
		fm.set_shader_parameter("detail_far_m", 2000.0)
		if name == "fade_fix":
			var aa := _src_alpha()
			fm.set_shader_parameter("detail_mask_tex",
				_mask_image(func(s: int) -> Color: return Color(aa[s], aa[s], aa[s], aa[s])))
		return fm
	var m := world.duplicate() as StandardMaterial3D
	var a := _src_alpha()
	match name:
		"r0a1":
			m.detail_mask = _mask_image(func(_s: int) -> Color: return Color(0, 0, 0, 1))
		"r1a0":
			m.detail_mask = _mask_image(func(_s: int) -> Color: return Color(1, 1, 1, 0))
		"fix":
			m.detail_mask = _mask_image(func(s: int) -> Color: return Color(a[s], a[s], a[s], a[s]))
		"off":
			m.detail_enabled = false
	return m


func _build() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.8
	sun.shadow_enabled = false
	world.add_child(sun)
	sun.look_at_from_position(Vector3(0, 10, 0), Vector3(0, 0, 0), Vector3(0, 0, -1))
	for r in VARIANTS.size():
		var mat := _variant(VARIANTS[r])
		for c in SLOTS_TESTED.size():
			var mi := MeshInstance3D.new()
			mi.mesh = _quad_mesh(SLOTS_TESTED[c])
			mi.material_override = mat
			mi.position = Vector3(c * STEP, 0, r * STEP)
			world.add_child(mi)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = VARIANTS.size() * STEP + 2.0
	var cx := (SLOTS_TESTED.size() - 1) * STEP * 0.5
	var cz := (VARIANTS.size() - 1) * STEP * 0.5
	world.add_child(_cam)
	_cam.look_at_from_position(Vector3(cx, 40, cz), Vector3(cx, 0, cz), Vector3(0, 0, -1))
	_cam.current = true


func _process(_d: float) -> bool:
	_frames += 1
	if _frames == 2:
		print("DRIVER %s / %s" % [RenderingServer.get_current_rendering_driver_name(),
			RenderingServer.get_current_rendering_method()])
	if _frames < 12:
		return false
	var img := root.get_texture().get_image()
	img.save_png(_out.path_join("quads.png"))
	var rects := []
	for r in VARIANTS.size():
		for c in SLOTS_TESTED.size():
			rects.append({"variant": VARIANTS[r], "slot": SLOTS_TESTED[c]})
	var f := FileAccess.open(_out.path_join("quads.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"src_alpha": Array(_src_alpha()), "rects": rects}))
	f.close()
	print("WROTE %s" % _out.path_join("quads.png"))
	return _measure(img)


## Patratele se gasesc IN IMAGINE (randuri/coloane cu pixeli diferiti de fundal),
## nu prin proiectie: sistemul poate redimensiona fereastra, si atunci
## dreptunghiurile proiectate nu mai cad pe pixeli.
func _runs(on: Array[bool]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var start := -1
	for i in on.size() + 1:
		var v := i < on.size() and on[i]
		if v and start < 0:
			start = i
		elif not v and start >= 0:
			if i - start > 20:
				out.append(Vector2i(start, i))
			start = -1
	return out


func _lum(c: Color) -> float:
	return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0


## Granulatia = abaterea standard a luminantei in interiorul patratului, relativa
## la medie (%). Pe un patrat plat, cu lumina uniforma, singura variatie e stratul
## de detaliu. Verdictul e descris in antetul fisierului.
func _measure(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var bg := img.get_pixel(2, 2)
	var col_on: Array[bool] = []
	var row_on: Array[bool] = []
	for x in w:
		var n := 0
		for y in range(0, h, 2):
			var c := img.get_pixel(x, y)
			if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > 0.05:
				n += 1
		col_on.append(n > h / 2 * 0.2)
	for y in h:
		var n := 0
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > 0.05:
				n += 1
		row_on.append(n > w / 2 * 0.2)
	var cols := _runs(col_on)
	var rows := _runs(row_on)
	if cols.size() != SLOTS_TESTED.size() or rows.size() != VARIANTS.size():
		print("VERDICT: EROARE — am gasit %d coloane si %d randuri de patrate" % [cols.size(), rows.size()])
		quit(1)
		return true
	var a := _src_alpha()
	var rel := {}
	var head := "%-9s" % "slot/taria"
	for c in SLOTS_TESTED.size():
		head += "  %2d/%.2f" % [SLOTS_TESTED[c], a[SLOTS_TESTED[c]]]
	print(head)
	for r in VARIANTS.size():
		var line := "%-9s" % VARIANTS[r]
		rel[VARIANTS[r]] = []
		for c in SLOTS_TESTED.size():
			var x0 := cols[c].x + (cols[c].y - cols[c].x) / 10
			var x1 := cols[c].y - (cols[c].y - cols[c].x) / 10
			var y0 := rows[r].x + (rows[r].y - rows[r].x) / 10
			var y1 := rows[r].y - (rows[r].y - rows[r].x) / 10
			var s := 0.0
			var s2 := 0.0
			var n := 0
			for y in range(y0, y1):
				for x in range(x0, x1):
					var l := _lum(img.get_pixel(x, y))
					s += l
					s2 += l * l
					n += 1
			var mean := s / n
			var sd := sqrt(maxf(s2 / n - mean * mean, 0.0))
			rel[VARIANTS[r]].append(sd / maxf(mean, 1.0) * 100.0)
			line += "  %7.2f" % rel[VARIANTS[r]][c]
		print(line)
	# Verdictul NU presupune un tabel anume: verifica MECANISMUL, adica faptul ca
	# granulatia livrata urmeaza tabelul din PNG-ul sursa, oricare ar fi el.
	var ok := true
	var why := []
	# 1. Contractul motorului: StandardMaterial3D citeste R. Daca o versiune de
	#    Godot trece pe alt canal, astea doua se inverseaza.
	for c in SLOTS_TESTED.size():
		if rel["r0a1"][c] > 1.0 or rel["r1a0"][c] < 5.0:
			ok = false
			why.append("contract R schimbat pe slotul %d (R=0: %.2f%%, R=1: %.2f%%)" % [
				SLOTS_TESTED[c], rel["r0a1"][c], rel["r1a0"][c]])
			break
	# 2. Ambele cai (materialul lumii, prop_detail_fade) urmeaza tabelul: taria 0
	#    da sub 1%, taria > 0 da intre 0.8x si 1.25x fata de masca de referinta
	#    construita in memorie din acelasi tabel. Pe `fade` asta prinde si textura
	#    care nu se creeaza (D3D12 cu BC3 pe 32x1: shaderul cade pe alb).
	for pair in [["shipped", "fix"], ["fade", "fade_fix"]]:
		for c in SLOTS_TESTED.size():
			var got: float = rel[pair[0]][c]
			var want: float = rel[pair[1]][c]
			if a[SLOTS_TESTED[c]] <= 0.0:
				if got > 1.0:
					ok = false
					why.append("%s slotul %d (taria 0): %.2f%%" % [pair[0], SLOTS_TESTED[c], got])
				continue
			var ratio := got / maxf(want, 0.01)
			if ratio < 0.8 or ratio > 1.25:
				ok = false
				why.append("%s slotul %d: %.2f%% fata de %.2f%% asteptat" % [
					pair[0], SLOTS_TESTED[c], got, want])
	# 3. Palette.grain_material() (GRAIN_PREFIX): granulatie plina pe ORICE slot,
	#    adica la fel ca masca alba (R=1).
	for c in SLOTS_TESTED.size():
		var gr: float = rel["grain"][c] / maxf(rel["r1a0"][c], 0.01)
		if gr < 0.8 or gr > 1.25:
			ok = false
			why.append("grain slotul %d: %.2f%% fata de %.2f%% (plin)" % [
				SLOTS_TESTED[c], rel["grain"][c], rel["r1a0"][c]])
	print("VERDICT: %s %s" % ["OK" if ok else "PICA", "; ".join(why)])
	quit(0 if ok else 1)
	return true
