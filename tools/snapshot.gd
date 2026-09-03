extends Node
## Randeaza o pista si salveaza PNG in snapshots/. Ruleaza CU FEREASTRA
## (randarea nu merge headless); fereastra apare ~o secunda si se inchide singura.
##
##   --track=N   POZITIA din GameState.TRACK_SCENES (Dunele 0 · Okinawa 1 ·
##               Alpii 2 · Baikal 3 · Stromboli 4). Se accepta si numarul
##               scenei (--track=11 = Track11); un numar care nu e nici una,
##               nici alta opreste cu eroare, nu se retează tăcut.
##
##   --track=0                 ansamblu, de sus (ortografic)
##   --track=0 --frac=0.2      prim-plan inclinat la o fractie din traseu
##   --track=0 --frac=0.2 --driver
##                             POZA DE MASURARE (perspectiva). Vezi mai jos.
##   --track=0 --frac=0.2 --gamecam
##   --track=3 --eye=250,6,-118 --look=232,8,-165
##                             CAMERA LIBERA: ochi si punct privit, in metri
##                             de lume (x,y,z). Pentru ce nu se vede de pe
##                             sosea: viaductul din lateral, de pe gheata.
##                             vederea reala de JOC, cu parametrii curenti ai
##                             camerei de urmarire
##   --track=0 --frac=0.5 --gamecam --route=1
##                             la fel, dar pe BANDA SECUNDARA cu indexul dat
##                             (1 = prima scurtatura, in ordinea din
##                             Track.routes); fractia e din lungimea benzii,
##                             nu din tur. Fara asta, o scurtatura se putea
##                             vedea doar din racorduri, de pe sosea.
##   --track=0 --landmark=2 [--dist=30]
##                             LANDMARK-ul cu id-ul cerut (`_LANDMARKS` din
##                             track.gd), vazut DE PE SOSEA, de la inaltimea
##                             camerei de urmarire. Fara el, singurul mod de a
##                             prinde un prop anume in cadru era sa ghicesti
##                             fractia, iar landmark-urile stau la 10-15 m
##                             lateral, deci ies din cadru la cea mai mica
##                             eroare. Poza asta e pentru VERIFICAREA unui
##                             asset, nu pentru compozitia pistei.
##   --train-at=0.55           muta ceasul trecerii de cale ferata la fractia
##                             ceruta din ciclu, ca trenul sa fie IN cadru la
##                             momentul capturii (implicit e parcat, invizibil)
##   --typhoon-at=0.12         la fel, pentru mini-typhoon: 0 = pe axa soselei,
##                             0.25 = la capatul maturarii, 0.12 = la jumatatea
##                             traversarii. Fara el, captura o prinde mereu pe
##                             mijlocul drumului si nu se vede niciodata trecerea.
##   --wave-at=0.30           la fel, pentru valul care spala soseaua: 0 = abia
##                             intrat in cadru dinspre larg, ~0.30 = pe axa
##                             soselei, peste ~0.60 = in larg, invizibil.
##   --bridge-at=0.24          la fel, pentru podul mobil: 0 = inchis, ~0.24 =
##                             travee sus cu corabia in gol. Fara el, captura
##                             prinde podul la inceputul ciclului, adica exact
##                             starea in care gimmick-ul nu se vede.
##   --lava-stage=1            stadiul limbii de lava (Stromboli): 0 = turul 1,
##                             1 = poarta, 2 = zid. Implicit 0 — adica exact
##                             starea in care gimmick-ul nu se vede.
##   --door-at=0.70            usa de piatra (SlidingHazard.Motion.USA) la o
##                             fractie din ciclul ei: 0 = abia deschisa (in
##                             nisa), ~0.53 = la jumatatea rostogolirii spre
##                             axa, 0.60-0.84 = INCHISA pe banda.
##   --rock-at=3.5             bolovanii cu traseu, la N SECUNDE de la
##                             desprindere (nu fractie: traseele au lungimi
##                             diferite). Se SIMULEAZA cadru cu cadru de la 0,
##                             fiindca lipirea de teren si saltul de pe buza
##                             sunt stare, nu functie de timp. Ceasul din
##                             hazard (`_cross_time`) spune cand e piatra
##                             deasupra soselei; sonda il tipareste.
##
## Vederile ortografice de sus turtesc tot ce e vertical, deci mint despre
## densitatea decorului de pe margine: ceva ce arata presarat de sus poate
## strange cadrul perfect din masina, si invers.
##
## ############################################################################
## --driver ESTE UN INSTRUMENT DE MASURA, NU O CAPTURA DE ECRAN.
##
## Parametrii lui (MEASURE_*) sunt INGHETATI. Sunt etalonul fata de care se
## compara deviatia de luminanta pe suprafete intre build-uri — vezi
## tools/measure_surface.gd si style_bible §14. Daca cineva ii "sincronizeaza"
## cu valorile curente ale camerei, toate cifrele de sigma din istoricul de
## PR-uri devin fara sens si nu mai stim daca lumea s-a imbunatatit sau doar
## s-a mutat camera.
##
## Pentru compozitie si pentru "cum arata cand joc" foloseste --gamecam, care
## citeste chiar constantele lui ChaseCamera.
## ############################################################################

## Poza de MASURARE. Nu se schimba niciodata.
const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2

func _vec3(text: String) -> Vector3:
	var p := text.split(",")
	if p.size() != 3:
		return Vector3.ZERO
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _ready() -> void:
	var track_index := 0
	var zoom_frac := -1.0 # >= 0: prim-plan la fractia respectiva din traseu
	var span_at := -1.0   # >= 0: faza pasajului rotativ (0 = deschis)
	var zoom_size := 60.0
	var driver_view := false
	# --cine: dupa captura, listeaza CE obiect cade pe fiecare coloana de ecran.
	# Sonda de silueta raporteaza conuri dupa X; asta spune al cui e conul.
	var cine := false
	var hide_terrain := false
	var game_cam := false
	## --cave: aplica presetul si intunericul celei mai apropiate [CameraZone].
	##
	## Fara el, orice captura din subteran MINTE. Zona se aprinde cand masina
	## jucatorului intra in ea, iar Snapshot nu instantiaza nicio masina — deci
	## sala apare cu ambientul si ceata de la suprafata, adica luminata de
	## soarele de zori. Exact asa a iesit prima runda a POI-ului F: o hala
	## portocalie in loc de o caverna. Acelasi motiv pentru care exista
	## `--train-at` si `--rock-at`: ce are ceas sau declansator trebuie ADUS in
	## starea in care il vede jucatorul, altfel poza arata alt joc.
	var cave_view := false
	var free_cam := false
	var eye_pos := Vector3.ZERO
	var look_pos := Vector3.ZERO
	var landmark_id := -1
	var landmark_dist := 30.0
	var train_at := -1.0
	var bridge_at := -1.0
	var typhoon_at := -1.0
	var wave_at := -1.0
	var rock_at := -1.0
	var door_at := -1.0
	var lava_stage := -1
	var route_idx := 0
	var hide_node := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--span-at="):
			span_at = float(arg.trim_prefix("--span-at="))
		elif arg.begins_with("--frac="):
			zoom_frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--hide="):
			hide_node = arg.trim_prefix("--hide=")
		elif arg.begins_with("--size="):
			zoom_size = float(arg.trim_prefix("--size="))
		elif arg.begins_with("--landmark="):
			landmark_id = int(arg.trim_prefix("--landmark="))
		elif arg.begins_with("--dist="):
			landmark_dist = float(arg.trim_prefix("--dist="))
		elif arg.begins_with("--train-at="):
			train_at = float(arg.trim_prefix("--train-at="))
		elif arg.begins_with("--bridge-at="):
			bridge_at = float(arg.trim_prefix("--bridge-at="))
		elif arg.begins_with("--typhoon-at="):
			typhoon_at = float(arg.trim_prefix("--typhoon-at="))
		elif arg.begins_with("--wave-at="):
			wave_at = float(arg.trim_prefix("--wave-at="))
		elif arg.begins_with("--rock-at="):
			rock_at = float(arg.trim_prefix("--rock-at="))
		elif arg.begins_with("--door-at="):
			door_at = float(arg.trim_prefix("--door-at="))
		elif arg.begins_with("--lava-stage="):
			lava_stage = int(arg.trim_prefix("--lava-stage="))
		elif arg.begins_with("--route="):
			route_idx = int(arg.trim_prefix("--route="))
		elif arg == "--cave":
			cave_view = true
		elif arg.begins_with("--eye="):
			eye_pos = _vec3(arg.trim_prefix("--eye="))
			free_cam = true
		elif arg.begins_with("--look="):
			look_pos = _vec3(arg.trim_prefix("--look="))
		elif arg == "--cine":
			cine = true
			driver_view = true
		elif arg == "--driver":
			driver_view = true
		elif arg == "--gamecam":
			driver_view = true
			game_cam = true
		elif arg == "--no-terrain":
			# Diagnostic: ascunde panza de teren, ca sa se vada ce e SUB ea.
			# „Exista in scena" si „se vede in cadru" sunt intrebari diferite —
			# cu terenul stins se afla instant daca o geometrie lipseste sau
			# doar e acoperita.
			hide_terrain = true
	if driver_view and zoom_frac < 0.0:
		zoom_frac = 0.0
	# `--track=` accepta si pozitia din lista (Stromboli = 4), si numarul
	# scenei (Track11 = 11) — vezi GameState.resolve_track_index. Inainte era
	# un clampi() tacut, care transforma un numar gresit in alta pista si o
	# captura de "verificare" intr-un fals pozitiv.
	var resolved := GameState.resolve_track_index(track_index)
	if resolved < 0:
		push_error("snapshot: --track=%d nu e nici pozitie in lista (0..%d), nici numar de pista din lista. Vezi GameState.TRACK_SCENES."
			% [track_index, GameState.TRACK_SCENES.size() - 1])
		get_tree().quit(1)
		return
	track_index = resolved
	print("snapshot: pista %s" % GameState.track_label(track_index))

	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	if hide_terrain:
		var tb := track.get_node_or_null("TerrainBody")
		if tb != null:
			for ch in tb.get_children():
				if ch is MeshInstance3D:
					(ch as MeshInstance3D).visible = false
	if "--smooth" in OS.get_cmdline_user_args():
		_smooth_organics(track)
	if train_at >= 0.0:
		_set_train_phase(track, train_at)
	if door_at >= 0.0:
		await _set_door_phase(track, door_at)
	if bridge_at >= 0.0:
		_set_bridge_phase(track, bridge_at)
	if span_at >= 0.0:
		_set_span_phase(track, span_at)
	if typhoon_at >= 0.0:
		_set_typhoon_phase(track, typhoon_at)
	if wave_at >= 0.0:
		_set_wave_phase(track, wave_at)
	if rock_at >= 0.0:
		# Metronomul eruptiei isi resincronizeaza bombele AMANAT (dupa ce
		# pista le construieste) si le-ar calca ceasul pus de --rock-at:
		# captura ar prinde bolovanii unde i-a asezat pulsul, nu simularea.
		# Cu grupul golit inainte sa ruleze resync-ul amanat, ceasul ramane
		# al capturii.
		for child in track.get_children():
			if child is EruptionCycle:
				(child as EruptionCycle).hazard_group = &""
		await _set_rock_time(track, rock_at)
	# Stadiul limbii de lava (Stromboli): 0 = turul 1 ... 2 = zid. Fara el,
	# captura prinde mereu stadiul 1 — exact starea in care gimmick-ul nu se
	# vede (aceeasi clasa de capcana ca la --bridge-at).
	if lava_stage >= 0:
		for child in track.get_children():
			if child is LavaFlowHazard:
				var lf := child as LavaFlowHazard
				while lf.current_stage() < lava_stage:
					lf.on_lap_completed()
				print("--lava-stage=%d: %s" % [lava_stage, lf.name])
	# `--hide` se aplica DUPA doua cadre, nu la `add_child`.
	#
	# Hazardele isi construiesc geometria AMANAT (`call_deferred` in
	# `RotatingSpanHazard._ready`, ca sa apuce pista sa-si coaca rutele), deci
	# in `_ready`-ul capturii nodurile lor inca nu exista in arbore. Cautate
	# atunci, `Deck`/`Span`/`SpanRoad` dau „nu am gasit" — si asta a costat o
	# runda intreaga: A/B-ul care trebuia sa arate CE deseneaza dala tan a
	# raportat „ascunderea nu schimba nimic", fiindca nu ascunsese nimic.
	#
	# `owned=false` din acelasi motiv: mesh-urile construite in cod n-au
	# `owner`, iar cele din GLB-urile instantiate stau sub radacina scenei lor.
	if hide_node != "":
		await get_tree().process_frame
		await get_tree().process_frame
		var h := track.find_child(hide_node, true, false) as Node3D
		if h != null:
			h.visible = false
			print("snapshot: ascuns %s (%s)" % [hide_node, h.get_path()])
		else:
			print("snapshot: nu am gasit %s" % hide_node)

	# Ceata se stinge doar pentru vederile DE SUS (ansamblul ortografic), unde
	# camera e la sute de metri si ceata ar spala tot intr-o pata uniforma.
	#
	# Pentru vederile DE JOC (--driver, --gamecam, --landmark, camera libera)
	# ceata TREBUIE sa ramana: ea e ce vede jucatorul, si fara ea capturile mint
	# exact despre fundal — siluetele de orizont stau la 190-300 m, adica in
	# plina ceata, si pe captura ieseau la contrast plin. Runda 34: 13 runde de
	# reglaje pe Erciyes s-au judecat pe capturi fara ceata, deci pe o imagine
	# pe care jucatorul n-o vede niciodata.
	var keep_fog := driver_view or game_cam or free_cam or landmark_id >= 0
	if not keep_fog:
		for child in track.get_children():
			if child is WorldEnvironment:
				(child as WorldEnvironment).environment.fog_enabled = false

	# Incadram pista (nu terenul urias): bounds din punctele coapte.
	var bmin := track.baked[0]
	var bmax := track.baked[0]
	for p in track.baked:
		bmin = bmin.min(p)
		bmax = bmax.max(p)
	var center := (bmin + bmax) * 0.5
	var extent_x := bmax.x - bmin.x + 90.0
	var extent_z := bmax.z - bmin.z + 90.0
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y
	var cam := Camera3D.new()
	add_child(cam)
	if free_cam:
		# CAMERA LIBERA: ochi + punct privit in coordonate de lume. Pentru
		# lucruri care nu se vad nici de pe sosea, nici de sus: un viaduct se
		# judeca din lateral, de pe gheata, si nicio fractie nu te duce acolo.
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = ChaseCamera.BASE_FOV
		cam.far = 600.0
		cam.position = eye_pos
		cam.look_at(look_pos, Vector3.UP)
		cam.current = true
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var fimg := get_viewport().get_texture().get_image()
		var fdir := ProjectSettings.globalize_path("res://snapshots")
		DirAccess.make_dir_recursive_absolute(fdir)
		var fout := "%s/%s_liber.png" % [fdir, GameState.TRACK_NAMES[track_index].to_lower()]
		fimg.save_png(fout)
		print("SNAPSHOT: ", fout)
		get_tree().quit()
		return
	if landmark_id >= 0:
		await _shoot_landmark(track, cam, track_index, landmark_id, landmark_dist)
		return
	if driver_view:
		# Perspectiva de la inaltimea camerei de urmarire. Doua variante:
		#   --driver  = poza INGHETATA de masurare (MEASURE_*, vezi antetul)
		#   --gamecam = parametrii REALI ai camerei, pentru compozitie
		var dist := MEASURE_DIST
		var cam_h := MEASURE_HEIGHT
		var fov := MEASURE_FOV
		var look_ahead := MEASURE_LOOK_AHEAD
		var look_h := MEASURE_LOOK_HEIGHT
		if game_cam:
			dist = ChaseCamera.DEFAULT_DISTANCE
			cam_h = ChaseCamera.DEFAULT_HEIGHT
			fov = ChaseCamera.BASE_FOV
			look_ahead = ChaseCamera.LOOK_AHEAD
			look_h = ChaseCamera.LOOK_HEIGHT
		# Banda ceruta (0 = soseaua): pe o scurtatura fractia e din lungimea
		# EI si nu se infasoara — capatul benzii e capat, nu tur.
		var route := track.route_at(clampi(route_idx, 0, track.routes.size() - 1))
		var pts := route.baked
		var n := pts.size()
		var idx := int(zoom_frac * float(n)) % n
		var focus: Vector3 = pts[idx]
		if cave_view:
			# Presetul de camera si intunericul zonei, aplicate MANUAL: vezi
			# `cave_view` pentru de ce o captura din subteran fara ele minte.
			#
			# Fractia se trece prin `frac_at`, nu se da bruta: pe o banda
			# secundara `zoom_frac` e din lungimea EI (0.25 din ocol), dar
			# zonele pe interval lucreaza cu fractia BUCLEI (0.718 acolo) —
			# exact cum o citeste jocul din `Car.road_index` in
			# `CameraZone._player_in_frac_span`. Cu fractia bruta, captura de
			# pe ocol alegea zona dupa distanta (Sala2, alt tavan, alt preset)
			# si masura o camera care nu exista in joc. Pe ruta 0 `frac_at`
			# intoarce chiar `zoom_frac`, deci nimic nu se schimba acolo.
			var zone := _nearest_cave_zone(track, focus, route.frac_at(idx))
			if zone != null:
				var solved := ChaseCamera.solve_preset(
					zone.height, zone.look_height, dist, look_ahead,
					fov + zone.fov_bonus, zone.ceiling, zone.ceiling_dist)
				cam_h = solved[0]
				fov = solved[1]
				look_h = zone.look_height
				cam.fov = fov
				zone.force_dark()
				await get_tree().process_frame
				print("--cave: zona %s, tavan %.1f m -> h %.2f fov %.1f"
					% [zone.name, zone.ceiling, cam_h, fov])
			else:
				print("--cave: nicio CameraZone langa frac %.3f" % zoom_frac)
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = fov
		cam.far = 400.0
		var want := focus - dir * dist + Vector3.UP * cam_h
		if game_cam:
			# ANTI-CLIPPING, ca in joc. Fara el captura minte exact acolo unde
			# conteaza: pe portiunea prin holul blocului Liziba camera de joc e
			# trasa in fata plafonului (`ChaseCamera._unclip`), dar captura o
			# lasa in plansee si iese un cadru negru — adica poza arata un
			# defect pe care jocul nu-l are, sau ascunde unul pe care il are.
			var look := focus + Vector3.UP * ChaseCamera.LOOK_HEIGHT
			var space := get_viewport().world_3d.direct_space_state
			var q := PhysicsRayQueryParameters3D.create(look, want,
				Track.CAMERA_BLOCKER_LAYER)
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				want = (hit["position"] as Vector3).move_toward(look,
					ChaseCamera.CLIP_MARGIN)
		cam.position = want
		cam.look_at(focus + dir * look_ahead + Vector3.UP * look_h, Vector3.UP)
		cam.current = true
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var dimg := get_viewport().get_texture().get_image()
		var ddir := ProjectSettings.globalize_path("res://snapshots")
		DirAccess.make_dir_recursive_absolute(ddir)
		var dout := "%s/%s_%s%s.png" % [ddir,
			GameState.TRACK_NAMES[track_index].to_lower(),
			"joc" if game_cam else "sofer",
			"" if route_idx == 0 else "_ruta%d" % route_idx]
		dimg.save_png(dout)
		print("SNAPSHOT: ", dout)
		if cine:
			_cine_e_in_cadru(track, cam)
		get_tree().quit()
		return
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	if zoom_frac >= 0.0:
		# Prim-plan inclinat la un punct de pe traseu (vezi si inaltimile).
		var idx := int(zoom_frac * float(track.baked.size())) % track.baked.size()
		var focus: Vector3 = track.baked[idx]
		cam.size = zoom_size
		cam.position = focus + Vector3(0, zoom_size * 0.9, zoom_size * 0.6)
		cam.look_at(focus, Vector3.UP)
	else:
		# `size` e extinderea VERTICALA; orizontala = size * aspect.
		# Cu --size fortezi cadrul (ex. 950 ca sa vezi si zidul lumii).
		cam.size = zoom_size if zoom_size > 100.0 else maxf(extent_z, extent_x / aspect)
		cam.position = center + Vector3.UP * 400.0
		cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.far = 1000.0
	cam.current = true

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/%s.png" % [dir, GameState.TRACK_NAMES[track_index].to_lower()]
	img.save_png(out)
	print("SNAPSHOT: ", out)
	get_tree().quit()


## Un landmark anume, vazut de pe sosea (--landmark=, vezi antetul).
##
## Camera sta pe axa drumului, la inaltimea camerei de urmarire, cu `dist`
## metri inainte de dreptul propului — adica exact de unde il vezi conducand,
## nu de sus si nu din lateral.
func _shoot_landmark(track: Track, cam: Camera3D, track_index: int,
		id: int, dist: float) -> void:
	# Cautare pe eticheta `shot_id`, nu pe grup: prop-urile hero care nu sunt in
	# `_LANDMARKS` (portalul de mina) trebuie sa poata fi cerute la fel.
	var target: Node3D = null
	for node in track.get_children():
		if node is Node3D and node.get_meta("shot_id", -1) == id:
			target = node as Node3D
			break
	if target == null:
		push_error("Snapshot: pista %d n-are prop cu shot_id %d" % [track_index, id])
		get_tree().quit(1)
		return
	# Ceata ramane STINSA (o taie apelantul mai sus) — la 30 m n-ar face nimic,
	# dar la un prop mai indepartat ar spala tocmai suprafata de verificat.
	var aabb := Track.model_aabb(target)
	var focus := aabb.position + aabb.size * 0.5
	# Punctul de pe traseu cel mai apropiat de prop, si directia de mers acolo.
	var best := 0
	var best_d := INF
	for i in track.baked.size():
		var d: float = track.baked[i].distance_squared_to(focus)
		if d < best_d:
			best_d = d
			best = i
	var n := track.baked.size()
	var here: Vector3 = track.baked[best]
	var dir := (track.baked[(best + 6) % n] - here).normalized()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 400.0
	cam.position = here - dir * dist + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir_out := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir_out)
	var out := "%s/%s_landmark%d.png" % [dir_out,
		GameState.TRACK_NAMES[track_index].to_lower(), id]
	get_viewport().get_texture().get_image().save_png(out)
	print("SNAPSHOT: ", out)
	get_tree().quit()


## EXPERIMENT (--smooth): normale netede pe geometria organica, pentru A/B.
##
## Ipoteza "arata ca Minecraft" are o cauza precisa de verificat: NIMIC din
## pipeline nu face shade_smooth, deci fiecare fateta e o placa uniforma de
## lumina. Aici rebuild-uim normalele prin mediere pe pozitie — echivalentul
## la runtime al lui shade_smooth din Blender — DOAR ca sa comparam capturi.
## Reparatia reala, daca ipoteza tine, e in exportul Blender, nu aici.
## Muta ceasul trenului la o fractie din ciclul lui, ca sa apuce sa fie IN cadru
## cand se face poza.
##
## Fara asta trenul e nefotografiabil: la pornire ciclul e la 0 (avertizare), iar
## captura are loc dupa doua cadre — deci in orice snapshot garnitura e parcata
## in afara hartii si invizibila. 0.55 il prinde pe la mijlocul traversarii.
func _set_train_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var train := node as TrainHazard
		if train == null:
			continue
		# `_time` e privat prin conventie, nu prin limbaj; sonda are voie, exact
		# ca sa nu adaugam un export doar de dragul unei poze.
		train.set("_time", train.period * clampf(at, 0.0, 0.999))
		train._physics_process(0.0)
		found += 1
	print("--train-at=%.2f: %d treceri de cale ferata mutate in ciclu" % [at, found])


## Muta usa de piatra la o fractie din ciclul ei (vezi `--door-at` in antet).
##
## Cursa si perioada usii se deduc la primul tick, nu in _ready (pista pune
## `travel` dupa add_child), deci se ruleaza un pas de zero secunde intai, ca
## `door_cycle()` sa aiba o perioada. `phase` se scade ca 0 sa insemne
## „inceputul starii deschise", indiferent de defazajul pistei.
func _set_door_phase(root: Node, at: float) -> void:
	var found := 0
	# Un pas de fizica intai: `sync_to_physics` scrie transformul in server
	# si il citeste inapoi abia dupa un pas, iar cursa usii se taie la primul
	# tick — fara asteptare, pozitia citita e (0,0,0) si cursa nelimitata.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for node in root.get_children():
		var door := node as SlidingHazard
		if door == null or door.motion != SlidingHazard.Motion.USA:
			continue
		var cycle: float = door.door_cycle()
		door.set("_time", cycle * (clampf(at, 0.0, 0.999) - door.phase))
		door._physics_process(0.0)
		found += 1
		print("--door-at=%.2f: usa la %s, cursa %.2f m, inchisa=%s" % [at,
			door.center + door.travel * door.call("_offset_now"),
			door.travel.length(), door.door_closed_now()])
	if found == 0:
		print("--door-at=%.2f: NICIO usa de piatra pe pista asta" % at)


## Aduce bolovanii cu traseu la `seconds` de la desprindere, simuland cadrele.
##
## Nu se poate sari direct la un timp: cu `stick_to_ground`, cota vine din
## raycast pe teren si dintr-o cadere libera care are memorie (viteza
## verticala) — deci se ruleaza `_physics_process` de la zero, cu pasul
## fizicii, DUPA ce serverul de fizica a apucat sa vada terenul (un cadru).
func _set_rock_time(root: Node, seconds: float) -> void:
	await get_tree().physics_frame
	var found := 0
	var step := 1.0 / 60.0
	for node in root.get_children():
		var rock := node as RockfallHazard
		if rock == null:
			continue
		rock.set("_time", 0.0)
		rock.set("_last_phase", 3)
		var t := 0.0
		while t < seconds:
			rock._physics_process(step)
			t += step
		# INGHETAT dupa simulare: pana la captura mai trec cadre (fizica ruleaza
		# normal) si piatra ar ajunge in alt loc decat cel tiparit — la vitezele
		# bombelor Stromboli, dincolo de capatul traseului, adica ASCUNSA.
		rock.set_physics_process(false)
		found += 1
		var body := rock.get("_rock") as Node3D
		var bp := body.global_position if body != null else rock.global_position
		print("--rock-at=%.2f: bolovan la (%.1f, %.1f, %.1f), trecere peste sosea la %.2f s, o trecere = %.2f s"
			% [seconds, bp.x, bp.y, bp.z,
			rock.get("_cross_time"), rock.get("_route_travel")])
	print("--rock-at=%.2f: %d bolovani mutati" % [seconds, found])


## Muta tromba intr-un moment ales din traversarea ei.
##
## Fractia e din ciclul complet dus-intors: 0.00 o pune pe axa soselei venind
## dinspre `travel_dir`, 0.25 la capatul maturarii, 0.50 din nou pe axa in sens
## invers. Fara steagul asta, captura o prinde la inceputul ciclului — adica taman
## in mijlocul drumului, ceea ce e util, dar niciodata nu poti fotografia
## traversarea in curs.
##
## `_apply_cycle(0.0)` cu delta zero: aseaza pozitia si inclinarea fara sa mai
## invarta palnia cu un pas de care nu are nevoie o poza.
func _set_typhoon_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var typhoon := node as TyphoonHazard
		if typhoon == null:
			continue
		typhoon.set("_time", TyphoonHazard.PERIOD * clampf(at, 0.0, 0.999))
		typhoon.call("_apply_cycle", 0.0)
		found += 1
	print("--typhoon-at=%.2f: %d trombe mutate in ciclu" % [at, found])


## Muta valul intr-un moment ales din traversarea lui.
##
## Fractia e din ciclul complet: 0 il pune la marginea dinspre larg (abia intrat
## in cadru, telegrafierea), ~0.30 pe axa soselei, iar peste `ON_ROAD_FRAC +
## LEAD_TIME/PERIOD` valul e in larg si INVIZIBIL. Fara steag, captura il prinde
## unde s-a nimerit, si de cele mai multe ori asta inseamna „nicaieri" — exact
## felul in care o poza poate arata un hazard care lipseste ca pe unul in regula.
##
## `_advance(0.0)` cu delta zero: aseaza pozitia si vizibilitatea fara sa mai
## inainteze ceasul cu un pas de care o poza n-are nevoie.
func _set_wave_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var wave := node as WaveSurge
		if wave == null:
			continue
		# Scazut defazajul: `at` inseamna acelasi lucru pe orice val de pe pista,
		# nu „at plus cat s-a nimerit sa fie faza fractiei lui".
		wave.set("_time", WaveSurge.PERIOD * (clampf(at, 0.0, 0.999) - wave.phase))
		wave.call("_advance", 0.0)
		found += 1
	print("--wave-at=%.2f: %d valuri mutate in ciclu" % [at, found])


## Muta podul mobil intr-un moment ales din ciclul lui.
##
## Ceasul podului merge pe bucla CORABIILOR (de doua ori mai lunga decat a
## traveei, vezi LiftBridgeHazard.SHIP_PERIOD), fiindca doar asa se stie care
## dintre cele doua corabii e in dreptul golului. Fractia ceruta e din bucla aia:
## 0.24 pune traveea sus cu prima corabie in gol, 0.74 la fel cu a doua.
## Muta pasajul rotativ intr-un punct din ciclul lui. Fara asta capturile ies
## in ce stare o fi nimerit ceasul — si acceptarea din brief cere anume starea
## DESCHISA („continua rampa"), care e cea de la faza 0.
func _set_span_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var span := node as RotatingSpanHazard
		if span == null:
			continue
		span.set("clock_running", false)
		span.set("_started", true)
		span.set("_time", span.period * clampf(at, 0.0, 0.999))
		span.call("_apply_cycle", 0.0)
		found += 1
	print("--span-at=%.2f: %d pasaje rotative mutate in ciclu" % [at, found])


func _set_bridge_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var bridge := node as LiftBridgeHazard
		if bridge == null:
			continue
		var t := LiftBridgeHazard.SHIP_PERIOD * clampf(at, 0.0, 0.999)
		bridge.set("_time", t)
		bridge.call("_apply_cycle", fposmod(t, LiftBridgeHazard.PERIOD))
		found += 1
	print("--bridge-at=%.2f: %d poduri mobile mutate in ciclu" % [at, found])


func _smooth_organics(root: Node) -> void:
	const PREFIXES := ["cliff", "butte", "mesa", "cluster", "arch", "boulder",
		"rock", "pebbles", "bush", "portal", "dino", "bone"]
	var count := 0
	for node in _walk_meshes(root):
		var nm := String(node.name).to_lower()
		var hit := false
		for p in PREFIXES:
			if nm.begins_with(p):
				hit = true
				break
		if not hit or node.mesh == null:
			continue
		node.mesh = _smoothed(node.mesh)
		count += 1
	print("--smooth: %d mesh-uri organice cu normale netede" % count)


func _walk_meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var mi := node as MeshInstance3D
	if mi != null:
		out.append(mi)
	for c in node.get_children():
		out.append_array(_walk_meshes(c))
	return out


## Normale medii pe pozitie cuantizata: toate fetele care impart un varf isi
## amesteca normalele, deci suprafata curge in loc sa fie placi.
func _smoothed(mesh: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var acc := {}
		var tri_count := idx.size() / 3 if idx.size() > 0 else verts.size() / 3
		for t in tri_count:
			var i0: int = idx[t * 3] if idx.size() > 0 else t * 3
			var i1: int = idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1
			var i2: int = idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2
			var fn := (verts[i1] - verts[i0]).cross(verts[i2] - verts[i0])
			for i in [i0, i1, i2]:
				var key := (verts[i] * 200.0).round()
				acc[key] = acc.get(key, Vector3.ZERO) + fn
		var normals := PackedVector3Array()
		normals.resize(verts.size())
		for i in verts.size():
			var key := (verts[i] * 200.0).round()
			normals[i] = (acc[key] as Vector3).normalized()
		arrays[Mesh.ARRAY_NORMAL] = normals
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out



## Ce obiect cade pe fiecare coloana din cadru, cu aceeasi camera ca poza.
##
## De ce e nevoie. `skyline_cones.py` raporteaza siluete dupa coloana X si
## atat. Cand reglezi un parametru de horn si cifra conului din stanga-fata nu
## se misca, sunt doua explicatii — parametrul n-are efect, sau conul ala nu e
## un horn. Fara lista asta se poate itera la nesfarsit pe prima.
func _cine_e_in_cadru(track: Node, cam: Camera3D) -> void:
	var rows: Array = []
	_proiecteaza(track, cam, rows)
	rows.sort_custom(func(a, b): return a[1] < b[1])
	print("CINE: obiecte cu peste 40 px inaltime, sortate pe coloana:")
	var spans: Array = []
	for r in rows:
		print("  x=%5d  h=%4d px  d=%5.1f m  %-24s %s"
			% [r[1], r[2], r[4], r[0], r[3]])
		var b: Rect2 = r[5]
		spans.append({
			"nume": r[0], "script": r[3], "x": r[1], "h_px": r[2],
			"d": snappedf(r[4], 0.1),
			"x0": int(floor(b.position.x)), "x1": int(ceil(b.end.x)),
			"y0": int(floor(b.position.y)), "y1": int(ceil(b.end.y)),
		})
	# Sidecar cu intervalele de coloane, ca sonda de pixeli sa poata masura
	# profilul DOAR inauntrul hornului numit. Fara el orice cifra de contur e
	# neatribuibila: runda 20 a demonstrat ca cel mai mare con din cadru e
	# TEREN de la 380 m, nu horn.
	var jdir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(jdir)
	var jout := "%s/cine_spans.json" % jdir
	var f := FileAccess.open(jout, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"view": [get_viewport().size.x, get_viewport().size.y],
			"obiecte": spans}, "  "))
		f.close()
		print("CINE-SPANS: ", jout)


func _proiecteaza(n: Node, cam: Camera3D, out: Array) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.is_visible_in_tree():
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		var ctr := ab.get_center()
		if not cam.is_position_behind(ctr):
			var p := cam.unproject_position(ctr)
			if p.x > -300.0 and p.x < 1580.0:
				var top := cam.unproject_position(
					Vector3(ctr.x, ab.position.y + ab.size.y, ctr.z))
				var bot := cam.unproject_position(
					Vector3(ctr.x, ab.position.y, ctr.z))
				var hpx := int(absf(bot.y - top.y))
				if hpx > 40:
					var own := n
					while own != null and own.get_script() == null:
						own = own.get_parent()
					var scr := "-"
					var nm := String(mi.name)
					if own != null:
						scr = String(own.get_script().resource_path.get_file())
						nm = String(own.name)
					var box := _cutie_ecran(ab, cam)
					out.append([nm, int(p.x), hpx, scr,
						cam.global_position.distance_to(ctr), box])
	for c in n.get_children():
		_proiecteaza(c, cam, out)


## Cutia pe ecran a unui AABB din lume: TOATE cele 8 colturi proiectate.
##
## De ce 8 colturi si nu centrul. Coloana de ecran a unui obiect e ce trebuie sa
## stie sonda de silueta ca sa masoare NUMAI hornul si nu vecinul; un singur
## punct (centrul) da o coloana, nu un interval, si atunci sonda tot ghiceste
## unde se termina obiectul. Un colt in spatele camerei ar da o proiectie
## intoarsa, deci se sare peste el si cutia ramane a colturilor vizibile.
func _cutie_ecran(ab: AABB, cam: Camera3D) -> Rect2:
	var r := Rect2()
	var first := true
	for i in 8:
		var c := ab.position + Vector3(
			ab.size.x if (i & 1) != 0 else 0.0,
			ab.size.y if (i & 2) != 0 else 0.0,
			ab.size.z if (i & 4) != 0 else 0.0)
		if cam.is_position_behind(c):
			continue
		var q := cam.unproject_position(c)
		if first:
			r = Rect2(q, Vector2.ZERO)
			first = false
		else:
			r = r.expand(q)
	return r


## Cea mai apropiata [CameraZone] de un punct de pe traseu, sau null.
##
## Cauta pe TOT arborele pistei fiindca zonele stau grupate intr-un nod propriu
## in .tscn (ZoneCamera/...), nu direct sub radacina.
func _nearest_cave_zone(track: Node, at: Vector3,
		frac: float = -1.0) -> CameraZone:
	var best: CameraZone = null
	var best_d := INF
	for node in track.find_children("*", "Area3D", true, false):
		var z := node as CameraZone
		if z == null:
			continue
		# INTERVALUL DE FRACTIE BATE DISTANTA, cand zona il declara. O zona pe
		# interval (gatul, elicea) are cutia redusa la un marcaj de 2 m, deci
		# „cea mai apropiata" ar alege-o aproape niciodata — si mai rau, pe
		# elice distanta e ambigua prin constructie: cele doua ture trec prin
		# acelasi loc in plan. Fractia raspunde exact, si e chiar criteriul pe
		# care il foloseste zona in joc, deci captura si jocul nu pot diverge.
		if z.frac_to > z.frac_from and frac >= 0.0:
			var inside := (frac >= z.frac_from and frac <= z.frac_to) 				if z.frac_from <= z.frac_to 				else (frac >= z.frac_from or frac <= z.frac_to)
			if inside:
				return z
			continue
		# Zona pe CUTIE: se ia doar daca punctul e chiar in cutia ei (cu o
		# marja de 3 m), exact cum o decide `Area3D`-ul in joc. Prima versiune
		# lua „cea mai apropiata sub 120 m", si la frac 0.93 pe elice (40 m de
		# Sala 2, dar in afara cutiei ei) captura primea presetul salii cu
		# tavan de 18 m — o camera care in joc nu exista acolo. Masurat pe
		# 3 sep 2026; captura fusese citita ca „butoi inchis".
		var lp := z.to_local(at)
		var half := z.size * 0.5
		var inside_box := absf(lp.x) <= half.x + 3.0 and absf(lp.z) <= half.z + 3.0 			and lp.y >= -3.0 and lp.y <= z.size.y + 3.0
		if not inside_box:
			continue
		var d := z.global_position.distance_to(at)
		if d < best_d:
			best_d = d
			best = z
	return best
