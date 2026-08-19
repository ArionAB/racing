extends Node
## Randeaza o pista si salveaza PNG in snapshots/. Ruleaza CU FEREASTRA
## (randarea nu merge headless); fereastra apare ~o secunda si se inchide singura.
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
	var zoom_size := 60.0
	var driver_view := false
	var game_cam := false
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
	var route_idx := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--frac="):
			zoom_frac = float(arg.trim_prefix("--frac="))
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
		elif arg.begins_with("--route="):
			route_idx = int(arg.trim_prefix("--route="))
		elif arg.begins_with("--eye="):
			eye_pos = _vec3(arg.trim_prefix("--eye="))
			free_cam = true
		elif arg.begins_with("--look="):
			look_pos = _vec3(arg.trim_prefix("--look="))
		elif arg == "--driver":
			driver_view = true
		elif arg == "--gamecam":
			driver_view = true
			game_cam = true
	if driver_view and zoom_frac < 0.0:
		zoom_frac = 0.0
	track_index = clampi(track_index, 0, GameState.TRACK_SCENES.size() - 1)

	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	if "--smooth" in OS.get_cmdline_user_args():
		_smooth_organics(track)
	if train_at >= 0.0:
		_set_train_phase(track, train_at)
	if bridge_at >= 0.0:
		_set_bridge_phase(track, bridge_at)
	if typhoon_at >= 0.0:
		_set_typhoon_phase(track, typhoon_at)
	if wave_at >= 0.0:
		_set_wave_phase(track, wave_at)
	if rock_at >= 0.0:
		await _set_rock_time(track, rock_at)
	# Fara ceata: camera e sus si ceata ar spala imaginea.
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
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = fov
		cam.far = 400.0
		cam.position = focus - dir * dist + Vector3.UP * cam_h
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
		found += 1
		print("--rock-at=%.2f: bolovan la (%.1f, %.1f, %.1f), trecere peste sosea la %.2f s, o trecere = %.2f s"
			% [seconds, rock.global_position.x, rock.global_position.y,
			rock.global_position.z, rock.get("_cross_time"), rock.get("_route_travel")])
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

