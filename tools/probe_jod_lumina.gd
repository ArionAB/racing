extends Node
## LUMINA PE MASCA DE CLASA — Jodhpur (Track17), ceasul DuskCycle la 0 / 0,5 / 1.
##
##   Godot_v4.7-stable_win64_console.exe --path . res://tools/ProbeJodLumina.tscn -- \
##       [--indigo=0.4] [--guard] [--out=snapshots/jod_lumina] [--dump]
##
## CERE FEREASTRA (randare; memoria `snapshot-nu-merge-headless`).
##
## De ce exista: la dusk=0 casele din orasul albastru ieseau bej-gri (lumina
## portocalie #FFB27A x var albastru = gri), iar la dusk=1 TOATA scena devenea
## albastra (soare + ambient + ceata indigo). Procentul de culoare pe cadru nu
## prinde asta (memoria `procent-de-culoare-nu-e-dovada`), iar caseta prinde
## cer (memoria `caseta-de-masura-contine-cer`). Deci: masca DE CLASA, randata
## pe GPU, pe exact acelasi cadru.
##
## Cum: pentru fiecare cadru (vedere x esantion) se randeaza lumea reala la
## fiecare `dusk`, apoi O TRECERE DE ID: fiecare GeometryInstance3D primeste un
## material unshaded, fara ceata, cu culoarea clasei lui (case var deschis,
## case indigo, sol, stanca = teren cu panta > 30 grade, drum, restul), cerul
## devine negru, tonemap liniar. Pixelii se atribuie dupa ID, cu eroziune 3x3
## (muchiile dintre clase si antialiasing-ul nu intra in medie). Lumea e
## INGHETATA (`get_tree().paused`), deci trecerea de ID si cadrele reale sunt
## aceeasi geometrie la pixel (memoria `diferenta-on-off-cere-lume-inghetata`).
##
## 5 esantioane pe vedere (memoria `o-captura-nu-e-un-verdict`): pozitii de
## camera diferite, nu acelasi cadru de 5 ori. Se tiparesc toate, verdictul
## e pe media de pixeli pe cele 5.
##
## Cifre: H si S sunt HSV ale culorii MEDII (sRGB, pe masca); L = luma Rec.601
## medie, 0..100. `--guard` aplica tintele (vezi `_verdict`) si iese 1 la orice
## abatere; fara el doar masoara.
##
## Abateri fata de joc (memoria `unealta-de-captura-e-parte-din-masuratoare`):
## camera e pusa direct (fara scuturare/FOV de viteza), fara masini pe pista,
## lumea e oprita din proces. Ceata, umbrele, tonemap-ul si ajustarile sunt ale
## jocului in cadrele reale; se schimba DOAR in trecerea de ID si se restaureaza.

const DUSKS: Array[float] = [0.0, 0.5, 1.0]
const SCARP_COS := 0.866 # 30 grade = scarp_slope_deg din tema jodhpur

## Clase de ID: culoarea din trecerea de ID (canale 0/1) -> nume.
## `gresie` (clasele red_sandstone/rose_sandstone: fortul, portile, turnul,
## fantana) si `cer` sunt DOAR masurate (a doua trecere de lumina, „cald +
## albastru"): `_verdict` nu le citeste, deci garda e aceeasi.
const CLS_NAMES := ["cer", "case_var", "case_indigo", "sol", "stanca", "drum", "rest", "gresie"]
const CLS_COLORS := [
	Color(0, 0, 0), Color(1, 0, 0), Color(1, 0, 1), Color(0, 1, 0),
	Color(1, 1, 0), Color(0, 0, 1), Color(0, 1, 1), Color(1, 1, 1)]
const MIN_PX := 1500 # sub atatia pixeli (pe 5 esantioane) clasa nu se judeca
const MIN_PX_CMP := 40000 # esantion minim pentru „indigo mai inchis decat varul"

var _out_dir := "res://snapshots/jod_lumina"
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
	var fracs: Array = []
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
			# `r1:0.360` = fractia pe ruta 1 (ulicioara D'), altfel ruta 0.
			for x in a.trim_prefix("--fracs=").split(","):
				fracs.append(x)
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
	print("ProbeJodLumina: indigo=%s, DuskCycle=%s, env=%s" % [
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
	# --fracs=a,b,c: in loc de vederile garzii, o vedere de joc per fractie,
	# fiecare pe 5 esantioane la +-0,002 / +-0,004 (masuratoarea „orasul sub
	# tine" pe cadrele eroului F; fara --guard, doar cifre).
	var views := _views() if fracs.is_empty() else _frac_views(fracs)
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
			for c in range(0, CLS_NAMES.size()):
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


## Tintele (docs/track_briefs/jodhpur.md §4, sarcina de lumina):
## dusk 0: var 195..230 grade, S >= 0,25; indigo albastru si mai inchis;
##         sol si stanca CALDE (H < 45 sau > 340).
## dusk 1: var albastru (195..250, S >= 0,20); sol si drum NU albastru saturat
##         (H in afara 190..250 sau S < 0,15); luma cadrului >= 12.
## dusk 0,5: var tot albastru (195..250, S >= 0,20), sol nu albastru saturat.
## Indigo: aceeasi fereastra de nuanta, si mai inchis decat varul (vezi mai jos).
func _verdict(vname: String, d: float, st: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var tag := "%s dusk=%.1f" % [vname, d]
	var var_ok := st.has("case_var") and int(st["case_var"]["px"]) >= MIN_PX
	if not var_ok:
		out.append("%s: case_var sub %d px — vederea nu vede orasul" % [tag, MIN_PX])
		return out
	var hv: float = st["case_var"]["h"]
	var sv: float = st["case_var"]["s"]
	var lo := 195.0
	var hi := 230.0 if d < 0.25 else 250.0
	var smin := 0.25 if d < 0.25 else 0.20
	if hv < lo or hv > hi or sv < smin:
		out.append("%s: case_var H %.0f S %.2f (vrea %.0f..%.0f, S>=%.2f)" % [tag, hv, sv, lo, hi, smin])
	if st.has("case_indigo") and int(st["case_indigo"]["px"]) >= MIN_PX:
		var hi2: float = st["case_indigo"]["h"]
		if hi2 < 195.0 or hi2 > 250.0 or float(st["case_indigo"]["s"]) < smin:
			out.append("%s: case_indigo H %.0f S %.2f nu e albastru" % [tag, hi2, st["case_indigo"]["s"]])
		# „Mai inchis" compara DOUA MULTIMI DIFERITE de case (cele deschise si
		# cele indigo din cadru). Cu putine case indigo in cadru (amestec 20%:
		# 25 000 px pe 5 esantioane pe D_joc) media e a catorva fatade insorite
		# de aproape, nu a tentei — deci comparatia se face doar pe esantion mare.
		if int(st["case_indigo"]["px"]) >= MIN_PX_CMP and float(st["case_indigo"]["l"]) >= float(st["case_var"]["l"]):
			out.append("%s: case_indigo L %.1f nu e mai inchis decat varul %.1f" % [
				tag, st["case_indigo"]["l"], st["case_var"]["l"]])
	for c in ["sol", "stanca", "drum"]:
		if not st.has(c) or int(st[c]["px"]) < MIN_PX:
			continue
		var h: float = st[c]["h"]
		var s: float = st[c]["s"]
		if d < 0.25 and c != "drum":
			# Nuanta unui pixel aproape gri e zgomot: stanca indepartata din
			# D_joc, in ceata, iese S 0.12-0.13 si H 339/344 dupa cat din ea
			# ascund zidurile lui E (7449 -> 5146 px, integrarea valului 1).
			# „Cald" se cere doar unde exista culoare, ca pragul de noapte
			# de mai jos; un gri nu e nici cald, nici albastru.
			if s >= 0.15 and not (h < 45.0 or h > 340.0):
				out.append("%s: %s H %.0f nu e cald (vrea < 45)" % [tag, c, h])
		elif d >= 0.25:
			if h >= 190.0 and h <= 250.0 and s >= 0.15:
				out.append("%s: %s albastru saturat H %.0f S %.2f" % [tag, c, h, s])
	if d > 0.75 and float(st["frame_luma"]) < 12.0:
		out.append("%s: cadrul prea intunecat, luma %.1f" % [tag, st["frame_luma"]])
	return out


## Vederile: D (ochiul fix al fundatiei + camera de joc pe urcare) si F (camera
## de joc pe bratul de INTRARE al bastionului). Cate 5 esantioane.
func _views() -> Array:
	var out := []
	var city := _city_centroid()
	# D, ochiul fundatiei (0,27,-140) privind spre centroidul caselor; esantioane
	# = ochiul deplasat cu 6 m pe orizontala (aceeasi privire).
	var eye := Vector3(0, 27, -140)
	var look := Vector3(city.x, _track.terrain_height_at(city.x, city.z) + 4.0, city.z) \
		if _track.has_method("terrain_height_at") else city
	var d_eyes := []
	for off in [Vector3.ZERO, Vector3(6, 0, 0), Vector3(-6, 0, 0), Vector3(0, 0, 6), Vector3(0, 0, -6)]:
		d_eyes.append([eye + off, look])
	out.append({"name": "D_ochi", "eyes": d_eyes})
	out.append({"name": "D_joc", "eyes": _gamecam_eyes([0.35, 0.375, 0.40, 0.425, 0.45])})
	# F: bratul de intrare (0,59-0,62, cerut initial) are < 6 000 px de case pe
	# cadru (masurat cu --scan: orasul e in afara cadrului, urcarea priveste
	# spre SV). Orasul intra in cadru la varful bastionului, 0,64-0,665.
	out.append({"name": "F_joc", "eyes": _gamecam_eyes([0.64, 0.645, 0.65, 0.655, 0.66])})
	# F, ochiul fundatiei (142,50,-253) spre centroidul caselor.
	var f_eyes := []
	var f_eye := Vector3(142, 50, -253)
	for off in [Vector3.ZERO, Vector3(6, 0, 0), Vector3(-6, 0, 0), Vector3(0, 0, 6), Vector3(0, 0, -6)]:
		f_eyes.append([f_eye + off, look])
	out.append({"name": "F_ochi", "eyes": f_eyes})
	print("centroid oras (%.0f, %.1f, %.0f), D_ochi priveste la %s" % [city.x, city.y, city.z, str(look)])
	return out


func _frac_views(fracs: Array) -> Array:
	var out := []
	for fr in fracs:
		var sfr := String(fr)
		var route := 0
		if sfr.begins_with("r1:"):
			route = 1
			sfr = sfr.trim_prefix("r1:")
		var f := float(sfr)
		out.append({"name": ("r1_" if route == 1 else "") + "f%04d" % roundi(f * 1000.0),
			"eyes": _gamecam_eyes([f - 0.004, f - 0.002, f, f + 0.002, f + 0.004], route)})
	return out


func _gamecam_eyes(fracs: Array, route: int = 0) -> Array:
	var out := []
	var r = _track.route_at(route)
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

## TERENUL DEPARTAT NU E SOL, E CEATA. Dupa decorul lui D (runda 3-4:
## LimeWall, RoofKit) ochiul fix al D_ochi (0,27,-140) nu mai vede nisipul de
## aproape: tot ce ramanea in masca „sol" era banda de teren de la orizont,
## la > 250 m (id_D_ochi.png: 8 126 px, toti pe randurile 307-357), iesita
## (172,176,211) = culoarea cetii albastre, H 234. Verdictul „solul e cald"
## judeca atunci ceata, nu solul. Terenul mai departe decat distanta la care
## ceata acopera o TREIME din culoare trece in clasa „rest" (nejudecata).
## Distanta se deriva din ceata scenei la dusk 0 (FOG_MODE_DEPTH:
## f = fog_density * ((d - begin) / (end - begin)) ^ curve), nu e ghicita:
## pe tema jodhpur (90 / 300 / 1,4 / 0,85) iese 197 m.
const FAR_FOG_FRACTION := 1.0 / 3.0


func _far_terrain_m() -> float:
	var b := _env.fog_depth_begin
	var e := maxf(_env.fog_depth_end, b + 1.0)
	var dens := maxf(_env.fog_density, 1e-3)
	var c := maxf(_env.fog_depth_curve, 1e-3)
	if dens <= FAR_FOG_FRACTION:
		return 1.0e6
	var d := b + (e - b) * pow(FAR_FOG_FRACTION / dens, 1.0 / c)
	print("ProbeJodLumina: teren peste %.0f m = ceata (clasa rest, nejudecat)" % d)
	return d


func _make_id_materials() -> void:
	for c in CLS_COLORS.size():
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
void fragment() {
	if (length(VERTEX) > %f) { ALBEDO = vec3(0.0, 1.0, 1.0); }
	else { ALBEDO = abs(wy) < %f ? vec3(1.0, 1.0, 0.0) : vec3(0.0, 1.0, 0.0); }
}
""" % [_far_terrain_m(), SCARP_COS]
	_terrain_id = ShaderMaterial.new()
	_terrain_id.shader = sh


## Clasa unui (nod, material efectiv).
func _cls_of(gi: GeometryInstance3D, mat: Material) -> int:
	var tri: Dictionary = Palette._tri_mats
	if tri.has("blue_lime_light") and mat == tri["blue_lime_light"]:
		return 1
	if tri.has("blue_lime_indigo") and mat == tri["blue_lime_indigo"]:
		return 2
	for k in ["red_sandstone", "rose_sandstone"]:
		if tri.has(k) and mat == tri[k]:
			return 7
	var nm := String(gi.name)
	if nm == "Terrain" or nm.begins_with("Terrain"):
		return 3 # sol / stanca se despart in shader dupa panta
	# Carosabilul (bucla, umerii, ulicioara) e generat in track.gd ca
	# MeshInstance3D FARA nume, copil direct al pistei, lung de sute de metri
	# (verificat cu --dump: 454x515, 468x529, 465x527 road_detail_fade, 81x26
	# ulicioara). Restul copiilor anonimi mici (linia de start 4x13) raman "rest".
	if nm.begins_with("@") and gi.get_parent() == _track:
		var sz := gi.get_aabb().size
		if maxf(sz.x, sz.z) > 50.0:
			return 5
	return 6


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
				mi.set_surface_override_material(s, _terrain_id if c == 3 else _id_mats[c])
			entry[2] = ov
		else:
			var c := _cls_of(gi, gi.material_override)
			gi.material_override = _terrain_id if c == 3 else _id_mats[c]
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
		var clean := (r < 30 or r > 225) and (g < 30 or g > 225) and (b < 30 or b > 225)
		if not clean:
			raw[p] = -1
			continue
		var key := (1 if r > 127 else 0) * 4 + (1 if g > 127 else 0) * 2 + (1 if b > 127 else 0)
		# rgb bits -> clasa: 000 cer, 100 var, 101 indigo, 010 sol, 110 stanca, 001 drum, 011 rest
		raw[p] = [0, 5, 3, 6, 1, 2, 4, 7][key]
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
		if c < 0:
			continue
		var a: Array = loc[c]
		a[0] += r
		a[1] += g
		a[2] += b
		a[3] += y
		a[4] += 1
	var cls := {}
	for c in range(0, CLS_NAMES.size()):
		var a: Array = loc[c]
		var t: Array = acc_row[c]
		for j in 5:
			t[j] += a[j]
		if int(a[4]) > 0:
			var col := Color(a[0] / a[4], a[1] / a[4], a[2] / a[4])
			cls[CLS_NAMES[c]] = {"h": col.h * 360.0, "s": col.s, "px": a[4]}
	return {"cls": cls, "frame_luma": fl / float(npx) * 100.0}


## --scan=a,b: pixelii de case (var+indigo) in camera de joc, pe fractii din
## 0,005 in 0,005 — ca sa se aleaga fractiile de pe care orasul e in cadru.
func _scan(a: float, b: float) -> void:
	var fr := a
	while fr <= b + 1e-6:
		var pair: Array = _gamecam_eyes([fr])[0]
		_cam.global_position = pair[0]
		_cam.look_at(pair[1], Vector3.UP)
		var ids := await _render_ids()
		var m := _classify(ids)
		var cnt := [0, 0, 0, 0, 0, 0, 0, 0]
		for p in m.size():
			if m[p] >= 0:
				cnt[m[p]] += 1
		print("SCAN frac %.3f  case_var %6d  case_indigo %6d  sol %7d  stanca %6d  drum %6d  cam %s" % [
			fr, cnt[1], cnt[2], cnt[3], cnt[4], cnt[5], str(pair[0].round())])
		fr += 0.005


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
