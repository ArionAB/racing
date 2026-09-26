extends Node
## Sonda de PERFORMANTA a unui cadru de joc: cate desene, cate triunghiuri si
## cat timp CPU/GPU costa ce vede jucatorul, in mai multe puncte ale pistei.
##
##   godot --path . res://tools/ProbePerf.tscn -- --track=1
##   godot --path . res://tools/ProbePerf.tscn -- --track=16 --mobile
##
## Ruleaza CU FEREASTRA: RenderingServer nu deseneaza (deci nu numara) nimic
## in --headless — sonda o spune si iese cu cod 2, nu cu un tabel de zerouri.
##
## Cifrele sunt ale desktopului, nu ale telefonului: le folosim RELATIV, A/B
## (aceeasi pista, inainte si dupa o schimbare), nu ca prezicere de fps pe
## iPhone. Ce le face comparabile e ca fiecare rulare foloseste aceeasi
## camera (constantele lui ChaseCamera), aceleasi fractii si mediaza acelasi
## numar de cadre. Vezi `docs/style_bible.md` §8 si planul de paritate mobil.
##
##   --track=N        pozitie in GameState.TRACK_SCENES SAU numar de scena
##                    (--track=16 = Track16), ca la snapshot
##   --samples=10     cate puncte pe traseu (echidistante ca fractie)
##   --frames=6       cate cadre se mediaza in fiecare punct (dupa o trecere de incalzire)
##   --mobile         PREVIZUALIZARE DE TELEFON: harta de umbra 2048 (cat
##                    `directional_shadow/size.mobile`), randare 3D la 0.75
##                    si MSAA 4x — adica exact reglajele din planul pentru iOS.
##                    Ce NU poate imita: `force_vertex_shading` (se decide la
##                    compilarea shaderelor, din project.godot)
##   --shadow-size=N  harta de umbra directionala (implicit cea din proiect)
##   --no-shadows     stinge umbrele (theme_shadows) — cat costa cascada
##   --no-glow        stinge glow-ul — cat costa post-procesarea
##   --scale=0.75     factorul de rezolutie 3D (1.0 = nativ)
##   --msaa=4         MSAA 3D: 0, 2, 4, 8
##
## De ce si timp GPU, nu doar desene: pe un GPU cu placi (Apple, Mali) numarul
## de desene e cost de CPU, iar ce doare cu adevarat — overdraw transparent,
## rezolutie, pase de post-procesare — se vede DOAR in milisecundele GPU.
## `viewport_set_measure_render_time` le expune pe backend-urile
## RenderingDevice (D3D12/Vulkan/Metal); pe Compatibility citeste 0.

const WARMUP_FRAMES: int = 4

func _ready() -> void:
	var track_arg := 0
	var samples := 10
	var frames := 6
	var mobile := false
	var shadow_size := 0
	var no_shadows := false
	var no_glow := false
	var scale := 1.0
	var msaa := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--samples="):
			samples = maxi(1, int(arg.trim_prefix("--samples=")))
		elif arg.begins_with("--frames="):
			frames = maxi(1, int(arg.trim_prefix("--frames=")))
		elif arg == "--mobile":
			mobile = true
		elif arg.begins_with("--shadow-size="):
			shadow_size = int(arg.trim_prefix("--shadow-size="))
		elif arg == "--no-shadows":
			no_shadows = true
		elif arg == "--no-glow":
			no_glow = true
		elif arg.begins_with("--scale="):
			scale = clampf(float(arg.trim_prefix("--scale=")), 0.25, 2.0)
		elif arg.begins_with("--msaa="):
			msaa = int(arg.trim_prefix("--msaa="))
	if DisplayServer.get_name() == "headless":
		push_error("ProbePerf: ruleaza CU FEREASTRA — in --headless nu se deseneaza nimic, deci n-ar fi nimic de masurat.")
		get_tree().quit(2)
		return
	var track_index := GameState.resolve_track_index(track_arg)
	if track_index < 0:
		push_error("ProbePerf: --track=%d nu e nici pozitie in lista (0..%d), nici numar de pista. Vezi GameState.TRACK_SCENES."
			% [track_arg, GameState.TRACK_SCENES.size() - 1])
		get_tree().quit(2)
		return
	if mobile:
		if shadow_size == 0:
			shadow_size = 2048
		scale = minf(scale, 0.75)
		if msaa < 0:
			msaa = 4

	var vp := get_viewport()
	var vp_rid := vp.get_viewport_rid()
	if shadow_size > 0:
		RenderingServer.directional_shadow_atlas_set_size(shadow_size, true)
	if scale != 1.0:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = scale
	if msaa >= 0:
		vp.msaa_3d = _msaa_for(msaa)
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)

	print("ProbePerf: pista %s" % GameState.track_label(track_index))
	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	# Umbrele se sting pe LUMINA, nu prin `theme_shadows` + `rebuild()`: o
	# reconstruire a pistei dupa ce scena e deja in arbore a iesit mai SCUMPA
	# decat varianta cu umbre (1,35 ms fata de 0,93 pe Okinawa), deci ar fi
	# masurat reconstruirea, nu cascada.
	if no_shadows:
		for l in track.find_children("*", "DirectionalLight3D", true, false):
			(l as DirectionalLight3D).shadow_enabled = false
	if no_glow:
		for e in track.find_children("*", "WorldEnvironment", true, false):
			(e as WorldEnvironment).environment.glow_enabled = false
	# Decorul care se construieste singur (`_build.call_deferred`, stoluri,
	# turme) are nevoie de cadre de proces SI de fizica — aceeasi asteptare ca
	# in snapshot.gd, altfel masuram o pista pe jumatate goala.
	for _i in 8:
		await get_tree().process_frame
		await get_tree().physics_frame

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = ChaseCamera.FAR_PLANE
	cam.near = ChaseCamera.NEAR_PLANE
	cam.current = true

	var n := track.baked.size()
	var rows: Array[Dictionary] = []
	var t := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	# INCALZIREA e o trecere intreaga, nu cateva cadre per punct. Godot
	# compileaza pipeline-ul unui material la PRIMA aparitie in cadru, iar
	# GPU-ul isi urca frecventa abia dupa cateva zeci de cadre de sarcina.
	# Prima versiune a sondei a masurat exact asta: primele 3-4 puncte ale
	# oricarei rulari ieseau la 4-7 ms GPU indiferent de continut (un punct cu
	# 65 de desene costa 3,7 ms, unul cu 434 costa 0,8 ms). Vizitand toate
	# punctele o data fara sa notam nimic, materialele sunt compilate si
	# frecventa e sus cand incepe masurarea; cifrele descriu scena.
	for s in samples:
		_aim(cam, track, float(s) / float(samples), n)
		for _k in WARMUP_FRAMES:
			await RenderingServer.frame_post_draw
	for s in samples:
		var frac := float(s) / float(samples)
		_aim(cam, track, frac, n)
		for _k in WARMUP_FRAMES:
			await RenderingServer.frame_post_draw
		var draw_sum := 0
		var prim_sum := 0
		var obj_sum := 0
		var cpu_sum := 0.0
		var gpu_sum := 0.0
		for _k in frames:
			await RenderingServer.frame_post_draw
			draw_sum += RenderingServer.viewport_get_render_info(vp_rid, t,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
			prim_sum += RenderingServer.viewport_get_render_info(vp_rid, t,
				RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
			obj_sum += RenderingServer.viewport_get_render_info(vp_rid, t,
				RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME)
			cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
			gpu_sum += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
		rows.append({
			"frac": frac,
			"draw": draw_sum / frames,
			"prim": prim_sum / frames,
			"obj": obj_sum / frames,
			"cpu": cpu_sum / float(frames),
			"gpu": gpu_sum / float(frames),
		})

	# Garda de "n-am masurat nimic": zero desene pe TOATE punctele nu e o pista
	# ieftina, e un contor neconectat (fereastra ascunsa, backend fara
	# informatii). Iese cu 2, nu cu un tabel verde.
	var any_draw := false
	for r in rows:
		if int(r["draw"]) > 0:
			any_draw = true
	if rows.is_empty() or not any_draw:
		push_error("ProbePerf: zero desene in toate punctele — contorul nu masoara nimic.")
		get_tree().quit(2)
		return

	var vsize := vp.get_visible_rect().size
	print("")
	print("=== PERF: %s | %dx%d x%.2f | msaa %s | umbre %s (%s) | glow %s | %d puncte x %d cadre ==="
		% [track.track_name, int(vsize.x), int(vsize.y), vp.scaling_3d_scale,
			_msaa_label(vp.msaa_3d),
			"NU" if no_shadows else "da",
			str(shadow_size) if shadow_size > 0 else "proiect",
			"NU" if no_glow else "da", samples, frames])
	print("  frac   desene   obiecte    tri(k)   cpu ms   gpu ms")
	var max_d := 0
	var max_g := 0.0
	var sum_d := 0
	var sum_p := 0
	var sum_c := 0.0
	var sum_g := 0.0
	for r in rows:
		print("  %.2f   %6d   %7d   %7d   %6.2f   %6.2f" % [r["frac"], r["draw"],
			r["obj"], int(r["prim"]) / 1000, r["cpu"], r["gpu"]])
		max_d = maxi(max_d, int(r["draw"]))
		max_g = maxf(max_g, float(r["gpu"]))
		sum_d += int(r["draw"])
		sum_p += int(r["prim"])
		sum_c += float(r["cpu"])
		sum_g += float(r["gpu"])
	var cnt := float(rows.size())
	print("  --- desene:  medie %d, varf %d" % [sum_d / rows.size(), max_d])
	print("  --- tri:     medie %dk" % [(sum_p / rows.size()) / 1000])
	print("  --- cpu ms:  medie %.2f" % [sum_c / cnt])
	print("  --- gpu ms:  medie %.2f, varf %.2f" % [sum_g / cnt, max_g])
	get_tree().quit()


## Camera de joc la fractia ceruta: aceleasi constante ca ChaseCamera si ca
## snapshot --gamecam, ca cifrele sa fie ale cadrului pe care il vede jucatorul.
func _aim(cam: Camera3D, track: Track, frac: float, n: int) -> void:
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = track.baked[idx]
	var ahead: Vector3 = track.baked[(idx + 12) % n]
	var dir := (ahead - focus).normalized()
	cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE \
		+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD
		+ Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)


func _msaa_for(n: int) -> Viewport.MSAA:
	match n:
		2: return Viewport.MSAA_2X
		4: return Viewport.MSAA_4X
		8: return Viewport.MSAA_8X
	return Viewport.MSAA_DISABLED


func _msaa_label(m: Viewport.MSAA) -> String:
	match m:
		Viewport.MSAA_2X: return "2x"
		Viewport.MSAA_4X: return "4x"
		Viewport.MSAA_8X: return "8x"
	return "off"
