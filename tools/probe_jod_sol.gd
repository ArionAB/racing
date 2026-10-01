extends Node
## SOLUL, APA SI ASFALTUL PE MASCA DE CLASA — Jodhpur (Track17), jodhpur/poi-sol.
##
##   Godot_v4.7-stable_win64_console.exe --path . res://tools/ProbeJodSol.tscn -- ##       [--fracs=0.160,0.505,0.950,0.30,0.05] [--out=snapshots/jod_sol]
##
## CERE FEREASTRA. Copia lui ProbeJodLumina (aceeasi trecere de ID pe GPU, lume
## inghetata, eroziune 3x3, 5 esantioane pe vedere), cu alte clase si alte
## vederi: stratul de SUB decor pe care l-au numit criticii orbi ai valului 1
## (sol nisip gri, apa turcoaz, asfalt bleumarin). Clasele: case (var+indigo),
## sol (teren sub 30 grade), stanca (teren peste 30), asfalt (bucla), umar
## (banda de pietris/pavaj de langa asfalt), apa (rapa + canal), rest.
## Vederile: camera de joc pe fiecare fractie, esantioane la +-0,003/0,006.
## Doar masoara (fara --guard): H/S/V = HSV ale culorii MEDII pe masca (sRGB),
## L = luma Rec.601 0..100.

const DUSKS: Array[float] = [0.0, 1.0]
const SCARP_COS := 0.866 # 30 grade = scarp_slope_deg din tema jodhpur

## Clase de ID: culoarea din trecerea de ID (canale 0/1) -> nume.
const CLS_NAMES := ["cer", "case", "sol", "stanca", "asfalt", "umar", "apa", "rest"]
## Trei trepte pe canal (0 / 0,5 / 1), ca sa incapa opt clase. Materialul de ID
## e unshaded cu tonemap liniar si albedo in sRGB, deci 0,5 iese ~128; se
## decodeaza pe trepte: <40, 100..160, >225 (vezi `_lvl`).
const CLS_COLORS := [
	Color(0, 0, 0), Color(1, 0, 0), Color(0, 1, 0), Color(1, 1, 0),
	Color(0, 0, 1), Color(1, 0.5, 0), Color(0, 0.5, 1), Color(0, 1, 1)]
const MIN_PX := 1500 # sub atatia pixeli (pe 5 esantioane) clasa nu se judeca

var _out_dir := "res://snapshots/jod_sol"
var _fracs: Array = [0.160, 0.505, 0.950, 0.30, 0.05]
var _track: Track
var _env: Environment
var _dc: Node
var _cam: Camera3D
var _id_mats: Array[Material] = []
var _terrain_id: ShaderMaterial
var _saved: Array = [] # [node, material_override, [surface overrides]]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var guard := false
	var dump := false
	var indigo := -1.0
	var scan_from := -1.0
	var scan_to := -1.0
	for a in OS.get_cmdline_user_args():
		if a == "--guard":
			guard = true
		elif a == "--dump":
			dump = true
		elif a.begins_with("--out="):
			_out_dir = a.trim_prefix("--out=")
		elif a.begins_with("--scan="):
			var sp := a.trim_prefix("--scan=").split(",")
			scan_from = float(sp[0])
			scan_to = float(sp[1])
		elif a.begins_with("--indigo="):
			indigo = float(a.trim_prefix("--indigo="))
		elif a.begins_with("--fracs="):
			_fracs = []
			for x in a.trim_prefix("--fracs=").split(","):
				_fracs.append(float(x))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var idx := GameState.resolve_track_index(10)
	_track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	# Pista pe RADACINA (nu copil al sondei, care e PROCESS_MODE_ALWAYS): asa
	# `paused` chiar o ingheata.
	get_tree().root.add_child.call_deferred(_track)
	await get_tree().process_frame
	# CityFill: _build amanat + physics_frame in interior; asteptam statisticile.
	var fills := _track.find_children("*", "CityFill", true, false)
	for i in 240:
		await get_tree().process_frame
		await get_tree().physics_frame
		var done := true
		for f in fills:
			if (f as CityFill).stats.is_empty():
				done = false
		if done and i > 4:
			break
	for i in 4:
		await get_tree().process_frame
	get_tree().paused = true
	_dc = get_tree().get_nodes_in_group(&"dusk_cycle")[0]
	_env = _dc.call("environment")
	print("ProbeJodSol: indigo=%s, DuskCycle=%s, env=%s" % [
		str(indigo) if indigo >= 0.0 else "din scena", _dc.name, _env != null])

	_make_id_materials()
	if dump:
		_dump()

	_cam = Camera3D.new()
	_cam.fov = ChaseCamera.BASE_FOV
	_cam.far = ChaseCamera.FAR_PLANE
	_cam.near = ChaseCamera.NEAR_PLANE
	add_child(_cam)
	_cam.current = true

	if scan_from >= 0.0:
		await _scan(scan_from, scan_to)
		get_tree().quit(0)
		return
	var views := _views()
	# acc[view][dusk_i][cls] = [sumR, sumG, sumB, sumLuma, n]
	var acc := {}
	var per_sample := []
	var frame_luma := {}
	for v: Dictionary in views:
		var vname: String = v["name"]
		acc[vname] = []
		for di in DUSKS.size():
			var row := []
			for c in CLS_NAMES.size():
				row.append([0.0, 0.0, 0.0, 0.0, 0])
			acc[vname].append(row)
		var eyes: Array = v["eyes"]
		for s in eyes.size():
			var pair: Array = eyes[s]
			_cam.global_position = pair[0]
			_cam.look_at(pair[1], Vector3.UP)
			var ids := await _render_ids()
			var mask := _classify(ids)
			if s == 0:
				_save_id_preview(ids, "%s/id_%s.png" % [_out_dir, vname])
			for di in DUSKS.size():
				_dc.call("force_value", DUSKS[di])
				var img := await _render()
				if s == 0:
					img.save_png(ProjectSettings.globalize_path(
						"%s/%s_dusk%s.png" % [_out_dir, vname, _dtag(DUSKS[di])]))
				var st := _accumulate(img, mask, acc[vname][di])
				var fl: Array = frame_luma.get("%s|%d" % [vname, di], [])
				fl.append(st["frame_luma"])
				frame_luma["%s|%d" % [vname, di]] = fl
				per_sample.append({"view": vname, "s": s, "dusk": DUSKS[di], "cls": st["cls"]})

	# ---- raport
	var report := {"indigo": indigo, "views": {}}
	var bad: Array[String] = []
	for v: Dictionary in views:
		var vname: String = v["name"]
		report["views"][vname] = {}
		for di in DUSKS.size():
			var fl: Array = frame_luma["%s|%d" % [vname, di]]
			var fsum := 0.0
			for x in fl:
				fsum += float(x)
			var stats := {"frame_luma": fsum / float(fl.size())}
			print("=== %s dusk=%.1f  (luma cadru %.1f; esantioane: %s)" % [
				vname, DUSKS[di], stats["frame_luma"], _fmt_list(fl)])
			for c in range(1, CLS_NAMES.size()):
				var a: Array = acc[vname][di][c]
				var n: int = a[4]
				if n == 0:
					continue
				var col := Color(a[0] / n, a[1] / n, a[2] / n)
				var h := col.h * 360.0
				var e := {"px": n, "h": h, "s": col.s, "v": col.v, "l": a[3] / n * 100.0,
					"rgb": [roundi(col.r * 255), roundi(col.g * 255), roundi(col.b * 255)]}
				stats[CLS_NAMES[c]] = e
				var samples := []
				for ps: Dictionary in per_sample:
					if ps["view"] == vname and is_equal_approx(ps["dusk"], DUSKS[di]):
						var cs: Dictionary = ps["cls"]
						if cs.has(CLS_NAMES[c]):
							samples.append("%.0f/%.2f" % [cs[CLS_NAMES[c]]["h"], cs[CLS_NAMES[c]]["s"]])
				print("  %-12s px %7d  H %5.1f  S %.2f  V %.2f  L %5.1f  rgb %s   [H/S pe esantion: %s]" % [
					CLS_NAMES[c], n, h, col.s, col.v, e["l"], str(e["rgb"]), " ".join(samples)])
			report["views"][vname][str(DUSKS[di])] = stats
			bad.append_array(_verdict(vname, DUSKS[di], stats))
	var f := FileAccess.open(ProjectSettings.globalize_path(
		"%s/cifre.json" % _out_dir), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	if guard:
		if bad.is_empty():
			print("VERDICT: OK — tintele de lumina tin pe toate vederile si fazele")
			get_tree().quit(0)
		else:
			for b in bad:
				print("  !! " + b)
			print("VERDICT: REGRESIE — %d abateri" % bad.size())
			get_tree().quit(1)
	else:
		print("(masurare; --guard aplica tintele) abateri: %d" % bad.size())
		for b in bad:
			print("  ~ " + b)
		get_tree().quit(0)


## Fara tinte: sonda doar masoara (garda de lumina ramane ProbeJodLumina).
func _verdict(_vname: String, _d: float, _st: Dictionary) -> Array[String]:
	return []


## Vederile: camera de joc pe fiecare fractie din `--fracs`, 5 esantioane.
func _views() -> Array:
	var out := []
	for fr in _fracs:
		var f := float(fr)
		out.append({"name": "f%.3f" % f, "eyes": _gamecam_eyes([
			fposmod(f, 1.0), fposmod(f - 0.003, 1.0), fposmod(f + 0.003, 1.0),
			fposmod(f - 0.006, 1.0), fposmod(f + 0.006, 1.0)])})
	return out


func _gamecam_eyes(fracs: Array) -> Array:
	var out := []
	var r = _track.route_at(0)
	var pts: PackedVector3Array = r.baked
	var n := pts.size()
	for fr in fracs:
		var i := int(float(fr) * float(n)) % n
		var focus: Vector3 = pts[i]
		var ahead: Vector3 = pts[r.wrap_index(i + 12)]
		var dir := (ahead - focus).normalized()
		var pos := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var lk := focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
		out.append([pos, lk])
	return out


func _city_centroid() -> Vector3:
	for f in _track.find_children("*", "CityFill", true, false):
		var st: Dictionary = (f as CityFill).stats
		if st.has("centroid"):
			return st["centroid"]
	return Vector3.ZERO


func _dtag(d: float) -> String:
	return ("%.1f" % d).replace(".", "")


func _fmt_list(a: Array) -> String:
	var s := []
	for x in a:
		s.append("%.1f" % float(x))
	return " ".join(s)


func _render() -> Image:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


# ------------------------------------------------------------ trecerea de ID

func _make_id_materials() -> void:
	for c in CLS_COLORS.size():
		var cc: Color = CLS_COLORS[c]
		_code_cls[roundi(cc.r * 2) * 9 + roundi(cc.g * 2) * 3 + roundi(cc.b * 2)] = c
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.disable_fog = true
		m.albedo_color = CLS_COLORS[c]
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_id_mats.append(m)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
varying float wy;
void vertex() { wy = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y; }
void fragment() { ALBEDO = abs(wy) < %f ? vec3(1.0, 1.0, 0.0) : vec3(0.0, 1.0, 0.0); }
""" % SCARP_COS
	_terrain_id = ShaderMaterial.new()
	_terrain_id.shader = sh


## Clasa unui (nod, material efectiv).
func _cls_of(gi: GeometryInstance3D, mat: Material) -> int:
	var tri: Dictionary = Palette._tri_mats
	for k in ["blue_lime_light", "blue_lime_indigo"]:
		if tri.has(k) and mat == tri[k]:
			return 1
	var nm := String(gi.name)
	if nm == "Terrain" or nm.begins_with("Terrain"):
		return 2 # sol / stanca se despart in shader dupa panta
	if nm.begins_with("RavineWaterSurface") or nm.begins_with("ChannelWater"):
		return 6
	# Carosabilul si umerii: MeshInstance3D FARA nume, copii directi ai pistei,
	# lungi de sute de metri (vezi ProbeJodLumina). Umarul se recunoaste dupa
	# dala lui (pietris sau pavaj), restul e asfalt.
	if nm.begins_with("@") and gi.get_parent() == _track:
		var sz := gi.get_aabb().size
		if maxf(sz.x, sz.z) > 50.0:
			var sm := mat as StandardMaterial3D
			if sm != null and sm.albedo_texture != null:
				var p := sm.albedo_texture.resource_path
				if p.contains("gravel") or p.contains("alpine_granite"):
					return 5
			return 4
	return 7


func _geoms(n: Node, out: Array[GeometryInstance3D]) -> void:
	if n is GeometryInstance3D:
		out.append(n as GeometryInstance3D)
	for c in n.get_children():
		_geoms(c, out)


func _swap_to_ids() -> void:
	_saved.clear()
	var all: Array[GeometryInstance3D] = []
	_geoms(_track, all)
	for gi in all:
		var entry := [gi, gi.material_override, []]
		var mi := gi as MeshInstance3D
		if gi.material_override == null and mi != null and mi.mesh != null:
			var ov := []
			for s in mi.mesh.get_surface_count():
				ov.append(mi.get_surface_override_material(s))
				var eff := mi.get_active_material(s)
				var c := _cls_of(gi, eff)
				mi.set_surface_override_material(s, _terrain_id if c == 2 else _id_mats[c])
			entry[2] = ov
		else:
			var c := _cls_of(gi, gi.material_override)
			gi.material_override = _terrain_id if c == 2 else _id_mats[c]
		_saved.append(entry)
	_env_saved = [_env.background_mode, _env.background_color, _env.fog_enabled,
		_env.tonemap_mode, _env.adjustment_enabled, _env.glow_enabled, _env.tonemap_exposure]
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color.BLACK
	_env.fog_enabled = false
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_env.adjustment_enabled = false
	_env.glow_enabled = false
	_env.tonemap_exposure = 1.0


var _env_saved := []


func _restore() -> void:
	for entry in _saved:
		var gi: GeometryInstance3D = entry[0]
		var ov: Array = entry[2]
		var mi := gi as MeshInstance3D
		if not ov.is_empty() and mi != null:
			for s in ov.size():
				mi.set_surface_override_material(s, ov[s])
		else:
			gi.material_override = entry[1]
	_saved.clear()
	_env.background_mode = _env_saved[0]
	_env.background_color = _env_saved[1]
	_env.fog_enabled = _env_saved[2]
	_env.tonemap_mode = _env_saved[3]
	_env.adjustment_enabled = _env_saved[4]
	_env.glow_enabled = _env_saved[5]
	_env.tonemap_exposure = _env_saved[6]


func _render_ids() -> Image:
	_swap_to_ids()
	var img := await _render()
	_restore()
	return img


var _code_cls := {}


## Treapta unui canal din trecerea de ID: 0, 1 (jumatate) sau 2 (plin); -1 =
## muchie / antialiasing.
func _lvl(v: int) -> int:
	if v < 40:
		return 0
	if v > 225:
		return 2
	if v >= 100 and v <= 160:
		return 1
	return -1


## Clasa pe pixel, cu eroziune 3x3 (-1 = muchie / amestec, exclus).
func _classify(img: Image) -> PackedInt32Array:
	var w := img.get_width()
	var h := img.get_height()
	var raw := PackedInt32Array()
	raw.resize(w * h)
	var data := img.get_data()
	var fmt := img.get_format()
	var bpp := 4 if fmt == Image.FORMAT_RGBA8 else 3
	for p in w * h:
		var r := data[p * bpp]
		var g := data[p * bpp + 1]
		var b := data[p * bpp + 2]
		var lr := _lvl(r)
		var lg := _lvl(g)
		var lb := _lvl(b)
		if lr < 0 or lg < 0 or lb < 0:
			raw[p] = -1
			continue
		raw[p] = _code_cls.get(lr * 9 + lg * 3 + lb, -1)
	var out := PackedInt32Array()
	out.resize(w * h)
	out.fill(-1)
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var k := y * w + x
			var c := raw[k]
			if c < 0:
				continue
			if raw[k - 1] == c and raw[k + 1] == c and raw[k - w] == c and raw[k + w] == c \
					and raw[k - w - 1] == c and raw[k - w + 1] == c and raw[k + w - 1] == c and raw[k + w + 1] == c:
				out[k] = c
	return out


func _save_id_preview(img: Image, path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(path))


func _accumulate(img: Image, mask: PackedInt32Array, acc_row: Array) -> Dictionary:
	var data := img.get_data()
	var bpp := 4 if img.get_format() == Image.FORMAT_RGBA8 else 3
	var loc := []
	for c in CLS_NAMES.size():
		loc.append([0.0, 0.0, 0.0, 0.0, 0])
	var fl := 0.0
	var npx := mask.size()
	for p in npx:
		var r := data[p * bpp] / 255.0
		var g := data[p * bpp + 1] / 255.0
		var b := data[p * bpp + 2] / 255.0
		var y := 0.299 * r + 0.587 * g + 0.114 * b
		fl += y
		var c := mask[p]
		if c <= 0:
			continue
		var a: Array = loc[c]
		a[0] += r
		a[1] += g
		a[2] += b
		a[3] += y
		a[4] += 1
	var cls := {}
	for c in range(1, CLS_NAMES.size()):
		var a: Array = loc[c]
		var t: Array = acc_row[c]
		for j in 5:
			t[j] += a[j]
		if int(a[4]) > 0:
			var col := Color(a[0] / a[4], a[1] / a[4], a[2] / a[4])
			cls[CLS_NAMES[c]] = {"h": col.h * 360.0, "s": col.s, "px": a[4]}
	return {"cls": cls, "frame_luma": fl / float(npx) * 100.0}


func _scan(_a: float, _b: float) -> void:
	pass


# ------------------------------------------------------------ --dump

func _dump() -> void:
	var all: Array[GeometryInstance3D] = []
	_geoms(_track, all)
	var by := {}
	for gi in all:
		var nm := String(gi.name)
		var k := nm.substr(0, 18) + " | " + gi.get_class() + " | "
		var m := gi.material_override
		var mi := gi as MeshInstance3D
		if m == null and mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			m = mi.get_active_material(0)
		k += (m.get_class() + ":" + m.resource_name) if m != null else "null"
		k += " -> " + CLS_NAMES[_cls_of(gi, m)]
		if nm.begins_with("@"):
			k += "  %s aabb %s" % [str(gi.get_parent().name), str(gi.get_aabb().size.round())]
			if m is ShaderMaterial:
				k += " shader " + str((m as ShaderMaterial).shader.resource_path)
		by[k] = int(by.get(k, 0)) + 1
	var keys := by.keys()
	keys.sort()
	for k in keys:
		print("DUMP %4d  %s" % [by[k], k])
