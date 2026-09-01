extends Node
## ECARTUL DE LUMINANTA PE CAROSABIL — cifra cu care se judeca "se vad umbrele?".
##
## Doi critici orbi au raportat, independent, "soseaua n-are nicio umbra: pete
## difuze, fara margine, fara directie". A/B-ul cu umbre ON/OFF arata insa ca
## 29.7% dintre pixelii de sosea difera cu peste 6 niveluri. Deci umbrele
## EXISTA; ce lipseste e CONTRASTUL. O intunecare moale si mica se citeste ca
## murdarie pe asfalt, nu ca umbra.
##
## Sonda masoara exact ce vede ochiul: distributia luminantei DOAR pe pixelii de
## carosabil, si ecartul p90 - p10. Referinta (Beach Buggy Racing) are 115; noi
## aveam 76. Tinta rundei: >= 105.
##
## Cum se afla ce pixel e sosea: pentru fiecare pixel (subesantionat) se trage
## un raycast prin proiectia camerei si se pastreaza doar loviturile in corpuri
## de RULARE (aceeasi lista ca ProbeLaneClear). Nu se ghiceste dupa culoare —
## culoarea e chiar marimea masurata, deci un filtru pe ea ar taia raspunsul.
##
##   godot --path . --rendering-driver vulkan res://tools/ProbeEcartSol.tscn -- \
##       --track=6 --frac=0.06 --var=base
##
## RULEAZA CU FEREASTRA (ca Snapshot): headless nu randeaza, imaginea ar iesi
## goala si toate cifrele ar fi zero.
##
## Variante (se pot combina cu virgula), fiecare stinge sau muta O veriga:
##   noshadow      umbrele stinse (etalonul A/B)
##   nbias<val>    shadow_normal_bias = val (ex. nbias0.2)
##   bias<val>     shadow_bias = val
##   blur<val>     shadow_blur = val
##   sun<val>      light_energy = val
##   amb<val>      ambient_light_energy = val
##   nofog / noglow / nossao / notone / nogi

const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const W: int = 1280
const H: int = 720
## Pasul de esantionare a mastii. 2 = un raycast la 2x2 pixeli; sub asta timpul
## creste fara ca histograma sa se schimbe.
const PAS: int = 2
## Corpurile pe care se ruleaza — copiat din ProbeLaneClear, aceeasi definitie
## de "carosabil".
const DRIVABLE := [
	"RoadTop", "RoadSides", "RoadOverpassDeck", "Shoulders",
	"BranchDeck", "BranchDirt", "BranchSand", "BranchRails",
	"Ramp", "ChannelKicker", "FlyoffRamp", "HummockBody",
	"IceSheet",
]


func _ready() -> void:
	var frac := 0.06
	var idx := 6
	var variante: Array[String] = []
	var eticheta := "base"
	var salveaza := ""
	## Doar carosabilul propriu-zis, fara umeri: umarul e praf si aduce
	## variatie de culoare care nu e umbra.
	var doar_asfalt := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--png="):
			salveaza = arg.trim_prefix("--png=")
		elif arg == "--doar-asfalt":
			doar_asfalt = true
		elif arg.begins_with("--var="):
			eticheta = arg.trim_prefix("--var=")
			for s in eticheta.split(","):
				if not s.is_empty() and s != "base":
					variante.append(s)

	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame

	var cam := Camera3D.new()
	add_child(cam)
	_aseaza_camera(track, cam, frac)

	var sun := _gaseste_soare(track)
	var env := _gaseste_mediu(track)
	_aplica_variante(track, sun, env, variante)
	for i in 6:
		await get_tree().process_frame

	print("")
	print("=== ecart de luminanta pe carosabil — frac %.3f, var [%s] ===" % [frac, eticheta])
	if sun != null:
		print("  soare  elev %.1f  energie %.3f  umbre %s"
				% [absf(sun.rotation_degrees.x), sun.light_energy, sun.shadow_enabled])
		print("  umbra  bias %.3f  normal_bias %.3f  pancake %.1f  cascada %.1f  blur %.2f"
				% [sun.shadow_bias, sun.shadow_normal_bias,
					sun.directional_shadow_pancake_size,
					sun.directional_shadow_max_distance, sun.shadow_blur])
	if env != null:
		print("  mediu  amb_energie %.3f  ssao %s  glow %s  ceata %s"
				% [env.ambient_light_energy, env.ssao_enabled, env.glow_enabled,
					env.fog_enabled])

	# ---- masca de carosabil, prin raycast ----
	var space := track.get_world_3d().direct_space_state
	var masca := PackedByteArray()
	masca.resize(W * H)
	masca.fill(0)
	var n_masca := 0
	var t0 := Time.get_ticks_msec()
	var y := 0
	while y < H:
		var x := 0
		while x < W:
			var sp := Vector2(float(x), float(y))
			var de := cam.project_ray_origin(sp)
			var spre := cam.project_ray_normal(sp)
			var q := PhysicsRayQueryParameters3D.create(de, de + spre * 260.0)
			q.collide_with_areas = false
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				var col: Object = hit.get("collider")
				if col != null and _e_carosabil(String((col as Node).name), doar_asfalt):
					masca[y * W + x] = 1
					n_masca += 1
			x += PAS
		y += PAS
	print("  masca  %d puncte de carosabil (%d ms, pas %d)"
			% [n_masca, Time.get_ticks_msec() - t0, PAS])
	if n_masca < 400:
		print("VERDICT: prea putin carosabil in cadru la frac %.3f" % frac)
		get_tree().quit(1)
		return

	# ---- imaginea randata ----
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var iw := img.get_width()
	var ih := img.get_height()
	var lum := PackedFloat32Array()
	y = 0
	while y < H:
		var x := 0
		while x < W:
			if masca[y * W + x] == 1 and x < iw and y < ih:
				var c := img.get_pixel(x, y)
				lum.append((0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * 255.0)
			x += PAS
		y += PAS
	var v := Array(lum)
	v.sort()
	var p10 := _pct(v, 0.10)
	var p50 := _pct(v, 0.50)
	var p90 := _pct(v, 0.90)
	print("  imagine %dx%d  pixeli masurati %d" % [iw, ih, v.size()])
	print("")
	print("  p10 %6.1f   p50 %6.1f   p90 %6.1f   ECART %6.1f"
			% [p10, p50, p90, p90 - p10])
	print("  (referinta BBR: p10 80  p50 135  p90 195  ecart 115; tinta rundei >= 105)")
	if not salveaza.is_empty():
		img.save_png(ProjectSettings.globalize_path("res://%s" % salveaza))
		print("  PNG: %s" % salveaza)
	print("VERDICT: ECART %.1f" % (p90 - p10))
	get_tree().quit(0)


func _e_carosabil(nume: String, doar_asfalt: bool) -> bool:
	if doar_asfalt:
		return nume.begins_with("RoadTop")
	for d in DRIVABLE:
		if nume.begins_with(d):
			return true
	return false


func _pct(v: Array, p: float) -> float:
	if v.is_empty():
		return 0.0
	var i := int(round(p * float(v.size() - 1)))
	return float(v[clampi(i, 0, v.size() - 1)])


func _aseaza_camera(track: Track, cam: Camera3D, frac: float) -> void:
	var pts: PackedVector3Array = track.baked
	var n := pts.size()
	var i := int(frac * float(n)) % n
	var focus: Vector3 = pts[i]
	var ahead: Vector3 = pts[(i + 12) % n]
	var dir := (ahead - focus).normalized()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = MEASURE_FOV
	cam.far = 400.0
	cam.position = focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	cam.look_at(focus + dir * MEASURE_LOOK_AHEAD
			+ Vector3.UP * MEASURE_LOOK_HEIGHT, Vector3.UP)
	cam.current = true


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
		if v == "noshadow":
			if sun != null:
				sun.shadow_enabled = false
		elif v == "nofog":
			if env != null:
				env.fog_enabled = false
		elif v == "noglow":
			if env != null:
				env.glow_enabled = false
		elif v == "nossao":
			if env != null:
				env.ssao_enabled = false
		elif v == "notone":
			if env != null:
				env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
				env.tonemap_exposure = 1.0
		elif v == "nogi":
			_stinge_gi(track)
		elif v.begins_with("elev"):
			if sun != null:
				var r := sun.rotation_degrees
				r.x = -float(v.trim_prefix("elev"))
				sun.rotation_degrees = r
		elif v.begins_with("azim"):
			if sun != null:
				var r2 := sun.rotation_degrees
				r2.y = float(v.trim_prefix("azim"))
				sun.rotation_degrees = r2
		elif v.begins_with("pancake"):
			if sun != null:
				sun.directional_shadow_pancake_size = float(v.trim_prefix("pancake"))
		elif v.begins_with("nbias"):
			if sun != null:
				sun.shadow_normal_bias = float(v.trim_prefix("nbias"))
		elif v.begins_with("bias"):
			if sun != null:
				sun.shadow_bias = float(v.trim_prefix("bias"))
		elif v.begins_with("blur"):
			if sun != null:
				sun.shadow_blur = float(v.trim_prefix("blur"))
		elif v.begins_with("sun"):
			if sun != null:
				sun.light_energy = float(v.trim_prefix("sun"))
		elif v.begins_with("amb"):
			if env != null:
				env.ambient_light_energy = float(v.trim_prefix("amb"))
		else:
			push_warning("varianta necunoscuta: %s" % v)


func _stinge_gi(n: Node) -> void:
	var mi := n as GeometryInstance3D
	if mi != null:
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	for c in n.get_children():
		_stinge_gi(c)
