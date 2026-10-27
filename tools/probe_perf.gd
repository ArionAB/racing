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
##   --splits=1|2     cascadele umbrei directionale fortate pe lumina
##                    (1 = ortogonal, 2 = PSSM cu felia apropiata la 15%)
##   --lod-px=N       pragul de LOD al mesh-urilor (Viewport.mesh_lod_threshold);
##                    cu --mobile implicit 4 = nivelul Normal pe telefon
##                    (GameState.MESH_LOD_PX_MOBILE), altfel 1 = desktop
##   --lod-bias=X     GeometryInstance3D.lod_bias pe toate MultiMesh-urile
##                    pistei (decor copt, umplutura de oras): sub 1 coboara
##                    LOD-ul mai devreme; masoara cat taie din triunghiuri
##   --attrib=A,B     ATRIBUIRE intr-o singura incarcare: dupa tabelul de baza,
##                    stinge pe rand fiecare grup (potrivire pe NUME de nod sau
##                    pe calea GLB-ului instantiat, substring, fara majuscule;
##                    ex. blue_house, rock_slab, StreetLights, PadureMasa,
##                    moso_culm) si scrie cat scade media si varful de
##                    triunghiuri/desene. Un singur punct nu e un verdict:
##                    atribuirea e pe toate punctele
##   --hide=A,B       stinge nodurile cu numele date de sub pista (ex.
##                    OrasFill, DecorManual, PadureMasa) — ATRIBUIRE: cat din
##                    cadru vine dintr-un grup, prin diferenta fata de rularea
##                    fara --hide
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
	var splits := 0
	var lod_px := 0.0
	var hide: PackedStringArray = []
	var lod_bias := 0.0
	var attrib: PackedStringArray = []
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
		elif arg.begins_with("--splits="):
			splits = int(arg.trim_prefix("--splits="))
		elif arg.begins_with("--lod-px="):
			lod_px = float(arg.trim_prefix("--lod-px="))
		elif arg.begins_with("--hide="):
			hide = arg.trim_prefix("--hide=").split(",", false)
		elif arg.begins_with("--lod-bias="):
			lod_bias = float(arg.trim_prefix("--lod-bias="))
		elif arg.begins_with("--attrib="):
			attrib = arg.trim_prefix("--attrib=").split(",", false)
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
		if lod_px <= 0.0:
			lod_px = GameState.MESH_LOD_PX_MOBILE[1]

	# FARA VSYNC: cu vsync, cadrul de ~1 ms lasa GPU-ul 94% din timp in gol,
	# frecventa lui cade in starea de economie si ACEEASI configuratie iese
	# cand 0,7, cand 1,4 ms de la o rulare la alta (Chongqing, doua rulari
	# identice: 1,45 si 0,68). Cu GPU-ul incarcat continuu, frecventa sta sus
	# si cifrele se compara.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var vp := get_viewport()
	var vp_rid := vp.get_viewport_rid()
	if shadow_size > 0:
		RenderingServer.directional_shadow_atlas_set_size(shadow_size, true)
	if scale != 1.0:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = scale
	if msaa >= 0:
		vp.msaa_3d = _msaa_for(msaa)
	if lod_px > 0.0:
		vp.mesh_lod_threshold = lod_px
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
	# Cascadele, fortate pe lumina (A/B fara editarea temei): 1 = ortogonal
	# pe toata distanta, 2 = PSSM cu felia apropiata la 15%.
	if splits > 0:
		for l in track.find_children("*", "DirectionalLight3D", true, false):
			var sun := l as DirectionalLight3D
			if splits >= 2:
				sun.directional_shadow_mode = \
					DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				sun.directional_shadow_split_1 = 0.15
				sun.directional_shadow_blend_splits = true
			else:
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	# Decorul care se construieste singur (`_build.call_deferred`, stoluri,
	# turme) are nevoie de cadre de proces SI de fizica — aceeasi asteptare ca
	# in snapshot.gd, altfel masuram o pista pe jumatate goala.
	for _i in 8:
		await get_tree().process_frame
		await get_tree().physics_frame
	# Atribuire pe grupuri: nodul se STINGE (visible), nu se scoate, ca nimic
	# altceva (coacerea DecorManual, zonele de sol) sa nu se schimbe.
	for nm in hide:
		var nd := track.get_node_or_null(NodePath(nm)) as Node3D
		if nd == null:
			push_error("ProbePerf: --hide: nu exista nodul '%s' sub pista." % nm)
			get_tree().quit(2)
			return
		nd.visible = false
		print("ProbePerf: stins %s" % nm)
	if lod_bias > 0.0:
		var n_mmi := 0
		for g in track.find_children("*", "MultiMeshInstance3D", true, false):
			(g as GeometryInstance3D).lod_bias = lod_bias
			n_mmi += 1
		print("ProbePerf: lod_bias %.2f pe %d MultiMesh-uri" % [lod_bias, n_mmi])
	await get_tree().process_frame

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = ChaseCamera.FAR_PLANE
	cam.near = ChaseCamera.NEAR_PLANE
	cam.current = true

	var n := track.baked.size()
	var rows: Array[Dictionary] = await _measure(cam, track, vp_rid, samples, frames, n, true)

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
	print("=== PERF: %s | %dx%d x%.2f | msaa %s | umbre %s (%s) | glow %s | lod %.0fpx%s | %d puncte x %d cadre ==="
		% [track.track_name, int(vsize.x), int(vsize.y), vp.scaling_3d_scale,
			_msaa_label(vp.msaa_3d),
			"NU" if no_shadows else "da",
			str(shadow_size) if shadow_size > 0 else "proiect",
			"NU" if no_glow else "da", vp.mesh_lod_threshold,
			("" if hide.is_empty() else " | stins: " + ",".join(hide))
				+ ("" if lod_bias <= 0.0 else " | lod_bias %.2f" % lod_bias),
			samples, frames])
	print("  frac   desene   umbra   obiecte    tri(k)   cpu ms   gpu ms")
	var max_d := 0
	var max_g := 0.0
	var sum_d := 0
	var sum_s := 0
	var sum_p := 0
	var sum_c := 0.0
	var sum_g := 0.0
	for r in rows:
		print("  %.2f   %6d   %5d   %7d   %7d   %6.2f   %6.2f" % [r["frac"],
			r["draw"], r["shadow"], r["obj"], int(r["prim"]) / 1000, r["cpu"],
			r["gpu"]])
		max_d = maxi(max_d, int(r["draw"]))
		max_g = maxf(max_g, float(r["gpu"]))
		sum_d += int(r["draw"])
		sum_s += int(r["shadow"])
		sum_p += int(r["prim"])
		sum_c += float(r["cpu"])
		sum_g += float(r["gpu"])
	var cnt := float(rows.size())
	print("  --- desene:  medie %d, varf %d (umbra: medie %d)"
		% [sum_d / rows.size(), max_d, sum_s / rows.size()])
	print("  --- tri:     medie %dk" % [(sum_p / rows.size()) / 1000])
	print("  --- cpu ms:  medie %.2f" % [sum_c / cnt])
	var gpus: Array[float] = []
	for r in rows:
		gpus.append(float(r["gpu"]))
	gpus.sort()
	print("  --- gpu ms:  medie %.2f, mediana %.2f, varf %.2f"
		% [sum_g / cnt, gpus[gpus.size() / 2], max_g])
	if not attrib.is_empty():
		await _attribution(attrib, cam, track, vp_rid, samples, n, rows)
	get_tree().quit()


## Stinge pe rand fiecare grup si re-masoara (fara incalzire: pipeline-urile
## sunt deja compilate). Diferenta fata de baza = cat costa grupul in cadru.
func _attribution(groups: PackedStringArray, cam: Camera3D, track: Track,
		vp_rid: RID, samples: int, n: int, base: Array[Dictionary]) -> void:
	var base_avg := 0
	var base_peak := 0
	var base_draw := 0
	for r in base:
		base_avg += int(r["prim"])
		base_peak = maxi(base_peak, int(r["prim"]))
		base_draw += int(r["draw"])
	base_avg /= base.size()
	base_draw /= base.size()
	print("")
	print("=== ATRIBUIRE (baza: tri medie %dk, varf %dk, desene medie %d) ===" % [
		base_avg / 1000, base_peak / 1000, base_draw])
	print("  %-22s %6s %8s %8s %8s   %s" % ["grup", "noduri", "tri med", "tri varf", "desene", "punctul cel mai greu al grupului"])
	for g in groups:
		var hidden: Array[Node3D] = []
		var needle := g.to_lower()
		for c in track.find_children("*", "Node3D", true, false):
			var nd := c as Node3D
			if not nd.visible:
				continue
			if String(nd.name).to_lower().contains(needle) 					or nd.scene_file_path.to_lower().contains(needle):
				# Doar radacinile potrivite: un copil al unui nod deja stins
				# nu se mai numara (altfel „noduri" ar minti).
				var anc := nd.get_parent()
				var covered := false
				while anc != null and anc != track:
					if hidden.has(anc):
						covered = true
						break
					anc = anc.get_parent()
				if not covered:
					hidden.append(nd)
		for nd in hidden:
			nd.visible = false
		await RenderingServer.frame_post_draw
		var rows := await _measure(cam, track, vp_rid, samples, 2, n, false)
		for nd in hidden:
			nd.visible = true
		var avg := 0
		var peak := 0
		var draw := 0
		var worst := 0
		var worst_frac := 0.0
		for i in rows.size():
			var d := int(base[i]["prim"]) - int(rows[i]["prim"])
			avg += int(rows[i]["prim"])
			peak = maxi(peak, int(rows[i]["prim"]))
			draw += int(rows[i]["draw"])
			if d > worst:
				worst = d
				worst_frac = float(rows[i]["frac"])
		avg /= rows.size()
		draw /= rows.size()
		print("  %-22s %6d %7dk %7dk %8d   -%dk la %.2f" % [g, hidden.size(),
			(base_avg - avg) / 1000, (base_peak - peak) / 1000, base_draw - draw,
			worst / 1000, worst_frac])


## Masoara toate punctele; `warm` = trecerea de incalzire inainte (vezi nota).
func _measure(cam: Camera3D, track: Track, vp_rid: RID, samples: int, frames: int,
		n: int, warm: bool) -> Array[Dictionary]:
	var t := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	var rows: Array[Dictionary] = []
	# INCALZIREA e o trecere intreaga, nu cateva cadre per punct. Godot
	# compileaza pipeline-ul unui material la PRIMA aparitie in cadru, iar
	# GPU-ul isi urca frecventa abia dupa cateva zeci de cadre de sarcina.
	# Prima versiune a sondei a masurat exact asta: primele 3-4 puncte ale
	# oricarei rulari ieseau la 4-7 ms GPU indiferent de continut (un punct cu
	# 65 de desene costa 3,7 ms, unul cu 434 costa 0,8 ms). Vizitand toate
	# punctele o data fara sa notam nimic, materialele sunt compilate si
	# frecventa e sus cand incepe masurarea; cifrele descriu scena.
	if warm:
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
		var shadow_sum := 0
		var prim_sum := 0
		var obj_sum := 0
		var cpu_sum := 0.0
		# Timpul GPU se ia ca MEDIANA a cadrelor, nu media: un singur cadru cu
		# sughit de sistem (3-4 ms intr-o rulare de 0,5) tragea media punctului
		# in sus si facea doua rulari identice sa difere cu 60%.
		var gpu_frames: Array[float] = []
		for _k in frames:
			await RenderingServer.frame_post_draw
			draw_sum += RenderingServer.viewport_get_render_info(vp_rid, t,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
			# Desenele din PASA DE UMBRA sunt un tip separat de informatie:
			# coloana "desene" nu le contine, deci o cascada in plus nu s-ar
			# vedea acolo deloc.
			shadow_sum += RenderingServer.viewport_get_render_info(vp_rid,
				RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
			prim_sum += RenderingServer.viewport_get_render_info(vp_rid, t,
				RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
			obj_sum += RenderingServer.viewport_get_render_info(vp_rid, t,
				RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME)
			cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
			gpu_frames.append(
				RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		gpu_frames.sort()
		rows.append({
			"frac": frac,
			"draw": draw_sum / frames,
			"shadow": shadow_sum / frames,
			"prim": prim_sum / frames,
			"obj": obj_sum / frames,
			"cpu": cpu_sum / float(frames),
			"gpu": gpu_frames[gpu_frames.size() / 2],
		})
	return rows


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
