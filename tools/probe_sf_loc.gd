extends Node
## SONDA TESTULUI DE LOC SAN FRANCISCO (docs/track_briefs/san_francisco.md §7 pasul 0).
## Masoara contractele pe strada sintetica `tools/SfLoc.tscn`:
##
##   1. SOARE PE CAROSABIL: fractia din carosabilul strazii la soare, pe LANT (muchia 1 ->
##      capatul blocului 2) si pe portiuni. Raze din grila de pe sosea (0,5 m x 1 m) spre
##      soarele TEMEI, contra corpurilor de coliziune (casele au trimesh din geometria
##      randata, deci raza vede exact ce umbreste in harta de umbre). Tinta: >= 80%.
##   2. MATERIALELE scenei: unice, pe tot ce se deseneaza (material_override, suprafete).
##   3. (doar CU FEREASTRA) CADRE DE MASURA: pentru fiecare vedere, cadrul normal si un cadru
##      de IDENTITATE (fetele de scandura in culori de cod: R = pastelul, G = orientarea fata
##      de soare — 250 spre soare, 125 razant, 0 cu spatele —, B = 128; restul negru, fara ceata/tonemap). `tools/sf_loc_stats.py` scoate
##      din perechi ΔV soare/umbra pe fatade si distanta dintre pasteluri DUPA remap.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfLoc.tscn
##   godot --path . res://tools/ProbeSfLoc.tscn -- --frames      (cu fereastra: + cadrele)
##   python tools/sf_loc_stats.py
##
## Optiuni: `--sun=EL,AZ` suprascrie rotatia soarelui (grade, conventia temei) INAINTE de
## constructie — reglajul se cauta aici, apoi se scrie in tema.
## Iese: snapshots/sf_loc_meas.json (+ snapshots/sf_loc_meas_<k>_{cadru,noshade,cls,id}.png).
##
## Pasul 7 (pilotul kitului, `--glb`: casele din `sf_row_b_canted.glb`, vezi sf_loc_decor.gd):
##   - cadrul de IDENTITATE are nevoie de fetele de scandura pe orientari. Casele din cod le au
##     ca suprafete separate; `Row_Wall` din GLB e un singur mesh, deci DOAR pentru cadrul de
##     identitate (dupa cadrele normale, care raman pe calea jocului) fiecare `Row_Wall` se
##     rupe in lit/graze/shade dupa normala fetei IN LUME fata de soarele temei, cu aceleasi
##     praguri ca `_clap_st` (N.L >= GRAZE_NL / > 0 / <= 0). `--resplit` aplica aceeasi rupere
##     si pe casele din cod (verificarea ca ruperea inseamna acelasi lucru ca suprafetele lor).
##   - cadrul FARA UMBRA DE CASE (`_noshade`): aceleasi vederi cu cast_shadow stins pe case;
##     raportul pixel cu pixel fata de cadrul normal = umbra aruncata pe fatade (bovindoul).
##   - cadrul de CLASE (`_cls`): pixelii caselor pe categorii (pastel / alb / sticla / acoperis /
##     parter de piatra / fusta / usi / altele), dupa slotul de atlas, normala si cota fata de
##     podea; restul negru.
##   - verificarea `wall_class` (materialul real de pe fiecare `Row_Wall`), triunghiurile
##     caselor, soclul (fusta fata de trotuar si teren), umbra geometrica pe fatade.
##   - `--mirror-test`: langa strada, o pereche normala + oglindita sub `WorldProp` si aceeasi
##     pereche intr-un `MultiMesh` (ca `CityFill`); se fotografiaza cu `--shot`.
##   - `--shot=nume:px,py,pz:tx,ty,tz[:fov]` (repetabil): cadre normale din camere date, in
##     snapshots/sf_loc_shot_<nume>.png; `py`/`ty` cu prefixul `r` = peste soseaua de la acel z;
##     cu `--shot`, sonda sare peste cadrele de masura.

const SCENE := "res://tools/SfLoc.tscn"
## Vederile de masura = vederile capturilor (z-ul masinii pe strada, cu camera de joc).
const VIEWS: Array[float] = [44.0, 20.0, -6.0, -58.0, -104.0]
const LIP1_Z: float = 24.0
const CHAIN_END_Z: float = -96.0

var _track: Track
var _out: Dictionary = {}
var _decor: Node
var _to_sun: Vector3

## Categoriile cadrului de clase (indexul k -> R = 20 + 28k, G = 77, B = 200).
const CATS: Array[String] = ["pastel", "alb", "sticla", "acoperis", "parter", "fusta", "usi",
	"altele"]


func _ready() -> void:
	var frames := "--frames" in OS.get_cmdline_user_args()
	var sun_over := Vector3.ZERO
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sun="):
			var p := a.trim_prefix("--sun=").split(",")
			sun_over = Vector3(-float(p[0]), float(p[1]), 0.0)
	var scene := load(SCENE) as PackedScene
	_track = scene.instantiate() as Track
	if sun_over != Vector3.ZERO:
		_track.set("custom_sun_rotation_deg", sun_over)
	add_child(_track)
	for _i in 6:
		await get_tree().process_frame
		await get_tree().physics_frame
	var decor := _track.get_node("SfDecor")
	if not decor.has_method("road_y"):
		push_error("ProbeSfLoc: scriptul decorului nu s-a incarcat (vezi eroarea de parsare de mai sus)")
		get_tree().quit(1)
		return
	var sun_rot: Vector3 = _track._sun_rotation_deg()
	var b := Basis.from_euler(Vector3(deg_to_rad(sun_rot.x), deg_to_rad(sun_rot.y),
		deg_to_rad(sun_rot.z)))
	var to_sun := -(b * Vector3.FORWARD)
	print("SfLoc: media soselei %.2f, mare %.2f, soare %s -> spre soare %s"
		% [_track._sampler.mean_road_y(), _track._sampler.mean_road_y()
		+ _track.sea_level_offset, sun_rot, to_sun])
	_out["sun_rotation_deg"] = [sun_rot.x, sun_rot.y, sun_rot.z]
	_out["to_sun"] = [to_sun.x, to_sun.y, to_sun.z]
	_sun_fraction(decor, to_sun)
	_count_materials()
	_out["tints"] = {}
	for cls: String in decor.PASTELS:
		var c: Color = Palette.CLASS_TINT[cls]
		_out["tints"][cls] = [c.r, c.g, c.b]
	_out["pastel_names"] = decor.PASTEL_NAMES
	# ordinea claselor = indexul din cadrul de identitate (JSON.stringify sorteaza cheile)
	_out["pastel_classes"] = decor.PASTELS
	_out["views"] = []
	for z: float in VIEWS:
		_out["views"].append({"z": z, "frac": _frac_at_z(z)})
	_decor = decor
	_to_sun = to_sun
	_out["mode"] = "glb" if decor.glb_mode else "cod"
	_out["resplit"] = "--resplit" in OS.get_cmdline_user_args()
	_check_wall_class()
	_count_house_tris()
	_facade_shadow()
	_plinths()
	var shots: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shots.append(a.trim_prefix("--shot="))
	if "--mirror-test" in OS.get_cmdline_user_args():
		_mirror_test()
		for _i in 3:
			await get_tree().process_frame
	if not shots.is_empty():
		await _shots(shots)
	elif frames:
		await _frames()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://snapshots"))
	var f := FileAccess.open(ProjectSettings.globalize_path("res://snapshots/sf_loc_meas.json"),
		FileAccess.WRITE)
	f.store_string(JSON.stringify(_out, "  "))
	f.close()
	print("SfLoc: scris snapshots/sf_loc_meas.json")
	get_tree().quit()


## Fractia de tur a punctului de pe strada (x = 0) cu z-ul dat — pentru `--frac` la Snapshot.
func _frac_at_z(z: float) -> float:
	var r := _track.route_at(0)
	var best := 0
	var bd := INF
	for i in r.baked.size():
		var p: Vector3 = r.baked[i]
		if absf(p.x) > 1.0:
			continue
		var d := absf(p.z - z)
		if d < bd:
			bd = d
			best = i
	return float(best) / float(r.baked.size())


func _sun_fraction(decor: Node, to_sun: Vector3) -> void:
	var space := get_viewport().world_3d.direct_space_state
	var spans := {
		"platou (z 48..24)": Vector2(24.0, 48.0),
		"bloc 1 (z 24..-24)": Vector2(-24.0, 24.0),
		"intersectia (z -24..-48)": Vector2(-48.0, -24.0),
		"bloc 2 (z -48..-96)": Vector2(-96.0, -48.0),
		"LANT (z 24..-96)": Vector2(CHAIN_END_Z, LIP1_Z),
	}
	var res := {}
	for key: String in spans:
		var span: Vector2 = spans[key]
		var lit := 0
		var tot := 0
		var by_house := 0
		var z := span.y
		while z >= span.x:
			var x := -6.75
			while x <= 6.76:
				var top := Vector3(x, decor.road_y(z) + 6.0, z)
				var q := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 12.0)
				var hit := space.intersect_ray(q)
				if not hit.is_empty():
					var p: Vector3 = hit["position"] + Vector3.UP * 0.05
					var q2 := PhysicsRayQueryParameters3D.create(p, p + to_sun * 300.0)
					var h2 := space.intersect_ray(q2)
					tot += 1
					if h2.is_empty():
						lit += 1
					elif (h2["collider"] as Node).is_in_group("sf_house_body"):
						by_house += 1
				x += 0.5
			z -= 1.0
		var frac := float(lit) / maxf(float(tot), 1.0)
		res[key] = {"lit": frac, "samples": tot, "shadow_by_houses": float(by_house) / maxf(float(tot), 1.0)}
		print("  soare pe carosabil  %-26s %5.1f%%  (%d puncte, umbra de case %.1f%%)"
			% [key, frac * 100.0, tot, float(by_house) * 100.0 / maxf(float(tot), 1.0)])
	_out["sun_on_road"] = res


func _count_materials() -> void:
	var mats := {}
	var names := {}
	for n in _track.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var list: Array[Material] = []
		if gi.material_override != null:
			list.append(gi.material_override)
		else:
			var mesh: Mesh = null
			if gi is MeshInstance3D:
				mesh = (gi as MeshInstance3D).mesh
				for s in (gi as MeshInstance3D).get_surface_override_material_count():
					var om := (gi as MeshInstance3D).get_surface_override_material(s)
					if om != null:
						list.append(om)
			elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null:
				mesh = (gi as MultiMeshInstance3D).multimesh.mesh
			if mesh != null and list.is_empty():
				for s in mesh.get_surface_count():
					var m := mesh.surface_get_material(s)
					if m != null:
						list.append(m)
		for m in list:
			var id := m.get_instance_id()
			if not mats.has(id):
				mats[id] = m
				names[id] = "%s <- %s" % [m.get_class(), gi.name]
	print("  materiale unice in scena: %d" % mats.size())
	var arr: Array[String] = []
	for id in names:
		arr.append(names[id])
	arr.sort()
	for s in arr:
		print("    ", s)
	_out["materials"] = mats.size()
	_out["material_list"] = arr


# ---------------------------------------------------------------- cadrele de masura

func _place_camera(cam: Camera3D, z: float) -> void:
	var r := _track.route_at(0)
	var n := r.baked.size()
	var idx := int(_frac_at_z(z) * float(n)) % n
	var focus: Vector3 = r.baked[idx]
	var ahead: Vector3 = r.baked[r.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var want := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	var look := focus + Vector3.UP * ChaseCamera.LOOK_HEIGHT
	var space := get_viewport().world_3d.direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(look, want,
		Track.CAMERA_BLOCKER_LAYER))
	if not hit.is_empty():
		want = (hit["position"] as Vector3).move_toward(look, ChaseCamera.CLIP_MARGIN)
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 400.0
	cam.position = want
	cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT,
		Vector3.UP)


func _frames() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	# 1) cadrele normale
	for k in VIEWS.size():
		_place_camera(cam, VIEWS[k])
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/sf_loc_meas_%d_cadru.png" % [dir, k])
	# 1b) aceleasi vederi, fara umbra aruncata de case (doar casele isi sting umbra)
	var house_geo: Array[GeometryInstance3D] = []
	for grp: String in ["sf_clap", "sf_house_atlas", "sf_clap_glb", "sf_trim_glb"]:
		for n in get_tree().get_nodes_in_group(grp):
			house_geo.append(n as GeometryInstance3D)
	for gi in house_geo:
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in VIEWS.size():
		_place_camera(cam, VIEWS[k])
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/sf_loc_meas_%d_noshade.png" % [dir, k])
	# mediul fara ceata/tonemap pentru cadrele codate
	_flat_environment()
	# 2) cadrele de CLASE (categoriile pixelilor caselor)
	var black := _unshaded(Color.BLACK)
	for n in _track.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if gi.is_in_group("sf_clap") or gi.is_in_group("sf_clap_glb"):
			gi.material_override = _unshaded(_cat_color(0))
		elif gi.is_in_group("sf_house_atlas") or gi.is_in_group("sf_trim_glb"):
			_classify_trim(gi as MeshInstance3D)
		else:
			gi.material_override = black
	for k in VIEWS.size():
		_place_camera(cam, VIEWS[k])
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/sf_loc_meas_%d_cls.png" % [dir, k])
	# 3) cadrele de identitate
	var resplit := "--resplit" in OS.get_cmdline_user_args()
	for n in get_tree().get_nodes_in_group("sf_clap_glb"):
		_split_by_sun(n as MeshInstance3D)
		(n as Node).add_to_group("sf_clap")
	if resplit:
		for n in get_tree().get_nodes_in_group("sf_clap"):
			if not (n as Node).is_in_group("sf_clap_glb"):
				_split_by_sun(n as MeshInstance3D)
	for n in _track.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if gi.is_in_group("sf_clap"):
			var mi := gi as MeshInstance3D
			# (casele din cod n-au override; Row_Wall din GLB are materialul clasei de la WorldProp)
			mi.material_override = null
			var p: int = mi.get_meta("sf_pastel")
			var orient: Array = mi.get_meta("sf_orient")
			for s in orient.size():
				var g := 250 if orient[s] == "lit" else (125 if orient[s] == "graze" else 0)
				mi.set_surface_override_material(s, _unshaded(Color8(30 + 45 * p, g, 128)))
		else:
			gi.material_override = black
	for k in VIEWS.size():
		_place_camera(cam, VIEWS[k])
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/sf_loc_meas_%d_id.png" % [dir, k])
	print("SfLoc: %d perechi de cadre in snapshots/" % VIEWS.size())


func _flat_environment() -> void:
	for we in _track.find_children("*", "WorldEnvironment", true, false):
		var env := (we as WorldEnvironment).environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.BLACK
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.glow_enabled = false
		env.ssao_enabled = false
		env.adjustment_enabled = false
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.tonemap_exposure = 1.0
		env.tonemap_white = 1.0


func _cat_color(k: int) -> Color:
	return Color8(20 + 28 * k, 77, 200)


## Rupe un mesh de scandura in suprafete lit/graze/shade dupa normala fetei IN LUME fata de
## soarele temei, cu pragurile din `sf_loc_decor.gd::_clap_st`. Mesh-ul ramane in coordonate
## locale; normala in lume trece prin inversa transpusa (corecta si pentru instanta oglindita).
func _split_by_sun(mi: MeshInstance3D) -> void:
	var src := mi.mesh
	var nb := mi.global_transform.basis.inverse().transposed()
	var graze: float = _decor.GRAZE_NL
	var sts := {}
	for key: String in ["lit", "graze", "shade"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts[key] = st
	var counts := {"lit": 0, "graze": 0, "shade": 0}
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var col: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var ntri := (idx.size() if idx.size() > 0 else v.size()) / 3
		for t in ntri:
			var ids := [t * 3, t * 3 + 1, t * 3 + 2]
			if idx.size() > 0:
				ids = [idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]]
			var n := Vector3.ZERO
			for i: int in ids:
				n += nn[i]
			var wn := (nb * n).normalized()
			var nl := wn.dot(_to_sun)
			var key := "lit" if nl >= graze else ("graze" if nl > 0.0 else "shade")
			counts[key] += 1
			var st: SurfaceTool = sts[key]
			for i: int in ids:
				st.set_normal(nn[i])
				if not uv.is_empty():
					st.set_uv(uv[i])
				if not col.is_empty():
					st.set_color(col[i])
				st.add_vertex(v[i])
	var out := ArrayMesh.new()
	var orient: Array[String] = []
	for key: String in ["lit", "graze", "shade"]:
		if counts[key] == 0:
			continue
		var st: SurfaceTool = sts[key]
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		orient.append(key)
	mi.mesh = out
	mi.set_meta("sf_orient", orient)


## Slotul de atlas al unui UV colapsat pe centrul slotului (32 de sloturi orizontale).
static func _slot_of(uv: Vector2) -> int:
	return clampi(int(floor(uv.x * 32.0)), 0, 31)


## Categoria unui triunghi de "restul casei" (Row_Trim / Atlas_<n>), vezi CATS.
func _cat_of(slot: int, wn: Vector3, h: float) -> int:
	if slot == Palette.FOAM_WHITE:
		return 1
	if slot == Palette.VOLCANIC_BLACK or slot == Palette.ICE_CRACK:
		return 2 if absf(wn.y) < 0.5 else 3
	if slot == Palette.CONCRETE:
		return 4 if h >= -0.05 else 5
	if slot == Palette.WOOD_WEATHERED or slot == Palette.LOG_DARK:
		return 6
	return 7


func _classify_trim(mi: MeshInstance3D) -> void:
	var src := mi.mesh
	var xf := mi.global_transform
	var nb := xf.basis.inverse().transposed()
	var yf: float = mi.get_meta("sf_floor_y")
	var sts: Array[SurfaceTool] = []
	var used: Array[bool] = []
	for k in CATS.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts.append(st)
		used.append(false)
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var ntri := (idx.size() if idx.size() > 0 else v.size()) / 3
		for t in ntri:
			var ids := [t * 3, t * 3 + 1, t * 3 + 2]
			if idx.size() > 0:
				ids = [idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]]
			var n := Vector3.ZERO
			var c := Vector3.ZERO
			for i: int in ids:
				n += nn[i]
				c += v[i]
			var wn := (nb * n).normalized()
			var h := (xf * (c / 3.0)).y - yf
			var k := _cat_of(_slot_of(uv[ids[0]]), wn, h)
			used[k] = true
			for i: int in ids:
				sts[k].set_normal(nn[i])
				sts[k].add_vertex(v[i])
	var out := ArrayMesh.new()
	var mats: Array[Material] = []
	for k in CATS.size():
		if not used[k]:
			continue
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sts[k].commit_to_arrays())
		mats.append(_unshaded(_cat_color(k)))
	mi.mesh = out
	mi.material_override = null
	for s in mats.size():
		mi.set_surface_override_material(s, mats[s])


# ------------------------------------------------------------- verificari pas 7

## Materialul REAL de pe fiecare `Row_Wall` (GLB) fata de cel cerut prin `wall_class`.
func _check_wall_class() -> void:
	var walls := get_tree().get_nodes_in_group("sf_clap_glb")
	if walls.is_empty():
		return
	var ok := 0
	var bad: Array[String] = []
	var per := {}
	for n in walls:
		var mi := n as MeshInstance3D
		var want: String = _decor.PASTELS[int(mi.get_meta("sf_pastel"))]
		var mat := mi.material_override
		var got := "null"
		if mat != null:
			got = "%s#%d" % [mat.get_class(), mat.get_instance_id()]
			for cls: String in _decor.PASTELS:
				if mat == Palette.triplanar_class_material(cls):
					got = cls
		per[got] = int(per.get(got, 0)) + 1
		if mat == Palette.triplanar_class_material(want):
			ok += 1
		elif bad.size() < 8:
			bad.append("%s: vrea %s, are %s" % [mi.get_parent().name, want, got])
	var trim_ok := 0
	var trims := get_tree().get_nodes_in_group("sf_trim_glb")
	for n in trims:
		if (n as MeshInstance3D).material_override == Palette.world_material():
			trim_ok += 1
	print("  wall_class: %d/%d Row_Wall pe pastelul cerut; Row_Trim pe atlas %d/%d; pe clase %s"
		% [ok, walls.size(), trim_ok, trims.size(), per])
	for b in bad:
		print("    GRESIT ", b)
	_out["wall_class"] = {"ok": ok, "n": walls.size(), "trim_ok": trim_ok, "trim_n": trims.size(),
		"per_class": per, "bad": bad}


func _mesh_tris(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


## Triunghiurile caselor (LOD 0), pe tot decorul.
func _count_house_tris() -> void:
	var total := 0
	var cache := {}
	for grp: String in ["sf_clap", "sf_house_atlas", "sf_clap_glb", "sf_trim_glb"]:
		for n in get_tree().get_nodes_in_group(grp):
			var m := (n as MeshInstance3D).mesh
			if not cache.has(m):
				cache[m] = _mesh_tris(m)
			total += int(cache[m])
	print("  triunghiuri case (LOD 0): %d pe %d case" % [total, _decor.houses.size()])
	_out["house_tris"] = total
	_out["houses"] = _decor.houses.size()


## Umbra GEOMETRICA pe fatadele randului din fata (strada principala): puncte pe planul fatadei
## (0,25 m), de la 3,4 la 9,4 m peste podea (zona de scandura a pilotului; parterul e de piatra),
## gasite cu o raza dinspre strada (doar fata plana, +-0,15 m: bovindoul si golurile adanci ies);
## din fiecare, o raza spre soare: umbrit de casa EI (bovindou, cornisa) / de ALTA casa / la soare.
func _facade_shadow() -> void:
	var space := get_viewport().world_3d.direct_space_state
	var res := {}
	for side: int in [1, -1]:
		var pts := 0
		var own := 0
		var other := 0
		for hd: Dictionary in _decor.houses:
			if hd["kind"] != "main" or int(hd["s"]) != side:
				continue
			var o: Vector3 = hd["facade_o"]
			var n: Vector3 = hd["n"]
			var u: Vector3 = hd["u"]
			var body: StaticBody3D = hd["body"]
			var a := -3.3
			while a <= 3.31:
				var h := 3.4
				while h <= 9.41:
					var p := o + u * a + Vector3.UP * h
					var q := PhysicsRayQueryParameters3D.create(p + n * 1.6, p - n * 0.4)
					var hit := space.intersect_ray(q)
					if not hit.is_empty() and hit["collider"] == body \
							and absf(((hit["position"] as Vector3) - p).dot(n)) <= 0.15:
						pts += 1
						var s0: Vector3 = hit["position"] + n * 0.03
						var q2 := PhysicsRayQueryParameters3D.create(s0, s0 + _to_sun * 300.0)
						var h2 := space.intersect_ray(q2)
						if not h2.is_empty():
							if h2["collider"] == body:
								own += 1
							else:
								other += 1
					h += 0.25
				a += 0.25
		var key := "est" if side > 0 else "vest"
		var nl := Vector3(-float(side), 0, 0).dot(_to_sun)
		res[key] = {"pts": pts, "nl": nl, "own": float(own) / maxf(pts, 1),
			"other": float(other) / maxf(pts, 1)}
		print("  umbra pe fatada %-4s (N.L %+.2f) %5d puncte: de casa ei %.1f%%, de alta casa %.1f%%, la soare %.1f%%"
			% [key, nl, pts, 100.0 * own / maxf(pts, 1), 100.0 * other / maxf(pts, 1),
			100.0 * (pts - own - other) / maxf(pts, 1)])
	_out["facade_shadow"] = res


## SOCLUL: pe fiecare casa din randul din fata de pe strada principala, (1) fusta (podeaua -2,4
## in GLB; in cod soclul coboara la cota de jos -3) fata de trotuarul din capatul de JOS, pe
## linia fatadei; (2) terenul (coliziunea pistei, fara casele) pe un inel la 0,15 m in afara
## pertilor laterali si din spate: cat iese PESTE podea si cat lasa GOL sub fusta;
## (3) terenul din amprenta (cat iese peste podea, inauntru).
func _plinths() -> void:
	var space := get_viewport().world_3d.direct_space_state
	var excl: Array[RID] = []
	for hd: Dictionary in _decor.houses:
		var b: StaticBody3D = hd["body"]
		if b != null:
			excl.append(b.get_rid())
	var skirt: float = _decor.GLB_SKIRT if _decor.glb_mode else -1.0
	var rows: Array = []
	var worst_gap := -99.0
	var worst_poke_out := -99.0
	var worst_poke_in := -99.0
	for hd: Dictionary in _decor.houses:
		if hd["kind"] != "main":
			continue
		var yf: float = hd["yf"]
		var zb: float = hd["zb"]
		var za: float = hd["za"]
		var s: int = hd["s"]
		var bottom: float = (yf - skirt) if skirt > 0.0 else (_decor.road_y(zb) - 3.0)
		var walk_lo: float = _decor.road_y(zb) + _decor.CURB_H
		var bury := walk_lo - bottom # > 0: fusta ingropata sub trotuar; < 0: gol vizibil
		var o: Vector3 = hd["facade_o"]
		var n: Vector3 = hd["n"]
		var u: Vector3 = hd["u"]
		var back := -n
		# vecinii pe acelasi rand: o latura fara vecin e EXPUSA (capat de rand)
		var up_open := true
		var lo_open := true
		for h2: Dictionary in _decor.houses:
			if h2["kind"] == "main" and int(h2["s"]) == s:
				if absf(float(h2["za"]) - (za + 7.0)) < 0.1:
					up_open = false
				if absf(float(h2["za"]) - (za - 7.0)) < 0.1:
					lo_open = false
		# inelul la 0,15 m in afara peretilor: latura de sus (u = +3,65), de jos (u = -3,65),
		# spatele (12,15 m de la fatada). Gol = fundul fustei peste teren; peste podea = teren.
		var parts := {"sus": [], "jos": [], "spate": []}
		var d := 0.25
		while d <= 11.8:
			(parts["sus"] as Array).append(o + back * d + u * 3.65)
			(parts["jos"] as Array).append(o + back * d - u * 3.65)
			d += 0.5
		var a := -3.4
		while a <= 3.41:
			(parts["spate"] as Array).append(o + back * 12.15 + u * a)
			a += 0.5
		var pr := {}
		for key: String in parts:
			var gap := -99.0
			var poke := -99.0
			for p: Vector3 in parts[key]:
				var g := _ground(space, p, yf, excl)
				if is_nan(g):
					continue
				gap = maxf(gap, bottom - g)
				poke = maxf(poke, g - yf)
			pr[key] = {"gap": gap, "poke": poke}
		var in_poke := -99.0
		d = 1.0
		while d <= 11.0:
			a = -3.0
			while a <= 3.01:
				var g2 := _ground(space, o + back * d + u * a, yf, excl)
				if not is_nan(g2):
					in_poke = maxf(in_poke, g2 - yf)
				a += 1.0
			d += 1.0
		# nisa intrarii (GLB: -X, adica spre capatul de SUS, u ~ +1,2..+2,3; 1 m adanca):
		# terenul din ea si trotuarul (care merge pana la 0,5 m in spatele fatadei) fata de podea
		var niche := -99.0
		for dn: float in [0.25, 0.5, 0.75]:
			for un: float in [1.2, 1.75, 2.3]:
				var g3 := _ground(space, o + back * dn + u * un, yf, excl)
				if not is_nan(g3):
					niche = maxf(niche, g3 - yf)
		var walk_niche: float = _decor.road_y(za - 3.5 + 1.75) + _decor.CURB_H - yf
		var row := {"s": s, "za": za, "drop": _decor.road_y(za) - _decor.road_y(zb),
			"bury_lo": bury, "up_open": up_open, "lo_open": lo_open, "ring": pr,
			"in_poke": in_poke, "niche_terrain": niche, "niche_walk": walk_niche}
		rows.append(row)
		var vis_gap := -bury
		for key: String in ["sus", "jos"]:
			if (key == "sus" and up_open) or (key == "jos" and lo_open):
				vis_gap = maxf(vis_gap, float(pr[key]["gap"]))
		worst_gap = maxf(worst_gap, vis_gap)
		for key: String in pr:
			worst_poke_out = maxf(worst_poke_out, float(pr[key]["poke"]))
		worst_poke_in = maxf(worst_poke_in, in_poke)
	print("  soclu (%s, fundul la %s). Coloane: cadere pe casa | fusta sub trotuarul de jos (>0 ok) | gol sub fusta sus/jos/spate (>0 = gol; * = capat de rand, expus) | teren peste podea sus/jos/spate, amprenta | nisa: teren, trotuar fata de podea"
		% [_out["mode"], ("podea -%.1f" % skirt) if skirt > 0.0 else "cota de jos -3"])
	for r: Dictionary in rows:
		var pr: Dictionary = r["ring"]
		print("    %s za %6.1f  cad %4.2f | %+5.2f | gol %+5.2f%s %+5.2f%s %+5.2f | peste %+5.2f %+5.2f %+5.2f, %+5.2f | nisa %+5.2f, trotuar %+5.2f"
			% ["E" if int(r["s"]) > 0 else "V", r["za"], r["drop"], r["bury_lo"],
			pr["sus"]["gap"], "*" if r["up_open"] else " ", pr["jos"]["gap"], "*" if r["lo_open"] else " ",
			pr["spate"]["gap"], pr["sus"]["poke"], pr["jos"]["poke"], pr["spate"]["poke"], r["in_poke"],
			r["niche_terrain"], r["niche_walk"]])
	_out["plinths"] = {"rows": rows, "worst_gap": worst_gap, "worst_poke_ring": worst_poke_out,
		"worst_poke_in": worst_poke_in}


func _ground(space: PhysicsDirectSpaceState3D, p: Vector3, yf: float, excl: Array[RID]) -> float:
	var top := Vector3(p.x, yf + 30.0, p.z)
	var q := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 60.0)
	q.exclude = excl
	var hit := space.intersect_ray(q)
	return NAN if hit.is_empty() else (hit["position"] as Vector3).y


# ------------------------------------------------------------- test de oglindire

## Langa strada, pe teren liber: [WorldProp normal][WorldProp oglindit]  [MultiMesh normal]
## [MultiMesh oglindit], fatadele spre +Z (spre soare), pastel roz. Coordonatele in `_out`.
func _mirror_test() -> void:
	var space := get_viewport().world_3d.direct_space_state
	var base := Vector3(110.0, 0.0, -20.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(base + Vector3.UP * 200.0,
		base + Vector3.DOWN * 200.0))
	base.y = (hit["position"] as Vector3).y + 0.5 if not hit.is_empty() else 20.0
	var packed := load(_decor.ROW_GLB) as PackedScene
	var rot := Basis(Vector3.UP, PI) # fatada (-Z local) spre +Z in lume
	var mir := rot * Basis.from_scale(Vector3(-1, 1, 1))
	var wp := WorldProp.new()
	wp.name = "TestOglinda"
	wp.auto_collision = false
	var xs: Array[Transform3D] = [Transform3D(rot, base), Transform3D(mir, base + Vector3(7.0, 0, 0))]
	for i in 2:
		var inst := packed.instantiate() as Node3D
		inst.transform = xs[i]
		inst.set_meta(WorldProp.WALL_CLASS_META, "sf_clapboard_pink")
		wp.add_child(inst)
	_track.add_child(wp)
	# MultiMesh, ca CityFill: un MultiMeshInstance3D pe parte, materialul pe material_override
	var tmpl := packed.instantiate() as Node3D
	var mm_off := Vector3(20.0, 0, 0)
	for c in tmpl.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mi.mesh
		mm.instance_count = 2
		for i in 2:
			mm.set_instance_transform(i, Transform3D(xs[i].basis, xs[i].origin + mm_off) * mi.transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "TestOglindaMM_%s" % mi.name
		mmi.multimesh = mm
		mmi.material_override = Palette.triplanar_class_material("sf_clapboard_pink") \
			if String(mi.name).begins_with("Row_Wall") else Palette.world_material()
		_track.add_child(mmi)
	tmpl.free()
	print("  test oglinda: baza %s (WorldProp x %.0f / %.0f, MultiMesh x %.0f / %.0f), fatadele spre +Z"
		% [base, base.x, base.x + 7.0, base.x + 20.0, base.x + 27.0])
	_out["mirror_base"] = [base.x, base.y, base.z]


func _parse_pt(s: String) -> Vector3:
	var p := s.split(",")
	var x := float(p[0])
	var z := float(p[2])
	var ys := p[1]
	var y := 0.0
	if ys.begins_with("r"):
		y = _decor.road_y(z) + float(ys.trim_prefix("r"))
	elif ys.begins_with("m"):
		y = float(_out.get("mirror_base", [0, 0, 0])[1]) + float(ys.trim_prefix("m"))
	else:
		y = float(ys)
	return Vector3(x, y, z)


func _shots(specs: Array[String]) -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.far = 600.0
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	for spec in specs:
		var parts := spec.split(":")
		var pos := _parse_pt(parts[1])
		var tgt := _parse_pt(parts[2])
		cam.fov = float(parts[3]) if parts.size() > 3 else ChaseCamera.BASE_FOV
		cam.position = pos
		cam.look_at(tgt, Vector3.UP)
		for _i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/sf_loc_shot_%s.png" % [dir, parts[0]]
		get_viewport().get_texture().get_image().save_png(path)
		print("SfLoc: shot %s  cam %s -> %s" % [path, pos, tgt])


static var _unshaded_cache: Dictionary = {}

func _unshaded(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if _unshaded_cache.has(key):
		return _unshaded_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.disable_fog = true
	_unshaded_cache[key] = m
	return m
