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
##      de soare, B = 128; restul negru, fara ceata/tonemap). `tools/sf_loc_stats.py` scoate
##      din perechi ΔV soare/umbra pe fatade si distanta dintre pasteluri DUPA remap.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfLoc.tscn
##   godot --path . res://tools/ProbeSfLoc.tscn -- --frames      (cu fereastra: + cadrele)
##   python tools/sf_loc_stats.py
##
## Optiuni: `--sun=EL,AZ` suprascrie rotatia soarelui (grade, conventia temei) INAINTE de
## constructie — reglajul se cauta aici, apoi se scrie in tema.
## Iese: snapshots/sf_loc_meas.json (+ snapshots/sf_loc_meas_<k>_{cadru,id}.png).

const SCENE := "res://tools/SfLoc.tscn"
## Vederile de masura = vederile capturilor (z-ul masinii pe strada, cu camera de joc).
const VIEWS: Array[float] = [44.0, 20.0, -30.0, -58.0, -104.0]
const LIP1_Z: float = 24.0
const CHAIN_END_Z: float = -96.0

var _track: Track
var _out: Dictionary = {}


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
	if frames:
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
	# 2) cadrele de identitate
	var black := _unshaded(Color.BLACK)
	for n in _track.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if gi.is_in_group("sf_clap"):
			var mi := gi as MeshInstance3D
			var p: int = mi.get_meta("sf_pastel")
			var orient: Array = mi.get_meta("sf_orient")
			for s in orient.size():
				var g := 250 if orient[s] == "lit" else 0
				mi.set_surface_override_material(s, _unshaded(Color8(30 + 45 * p, g, 128)))
		else:
			gi.material_override = black
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
	for k in VIEWS.size():
		_place_camera(cam, VIEWS[k])
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/sf_loc_meas_%d_id.png" % [dir, k])
	print("SfLoc: %d perechi de cadre in snapshots/" % VIEWS.size())


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
