extends Node
## Randeaza o pista si salveaza PNG in snapshots/. Ruleaza CU FEREASTRA
## (randarea nu merge headless); fereastra apare ~o secunda si se inchide singura.
##
##   --track=0                 ansamblu, de sus (ortografic)
##   --track=0 --frac=0.2      prim-plan inclinat la o fractie din traseu
##   --track=0 --frac=0.2 --driver
##                             POZA DE MASURARE (perspectiva). Vezi mai jos.
##   --track=0 --frac=0.2 --gamecam
##                             vederea reala de JOC, cu parametrii curenti ai
##                             camerei de urmarire
##   --track=0 --landmark=2 [--dist=30]
##                             LANDMARK-ul cu id-ul cerut (`_LANDMARKS` din
##                             track.gd), vazut DE PE SOSEA, de la inaltimea
##                             camerei de urmarire. Fara el, singurul mod de a
##                             prinde un prop anume in cadru era sa ghicesti
##                             fractia, iar landmark-urile stau la 10-15 m
##                             lateral, deci ies din cadru la cea mai mica
##                             eroare. Poza asta e pentru VERIFICAREA unui
##                             asset, nu pentru compozitia pistei.
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

func _ready() -> void:
	var track_index := 0
	var zoom_frac := -1.0 # >= 0: prim-plan la fractia respectiva din traseu
	var zoom_size := 60.0
	var driver_view := false
	var game_cam := false
	var landmark_id := -1
	var landmark_dist := 30.0
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
		var n := track.baked.size()
		var idx := int(zoom_frac * float(n)) % n
		var focus: Vector3 = track.baked[idx]
		var ahead: Vector3 = track.baked[(idx + 12) % n]
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
		var dout := "%s/%s_%s.png" % [ddir,
			GameState.TRACK_NAMES[track_index].to_lower(),
			"joc" if game_cam else "sofer"]
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
	var target: Node3D = null
	for node in track.get_tree().get_nodes_in_group("landmarks"):
		if node.get_meta("landmark_id", -1) == id:
			target = node as Node3D
			break
	if target == null:
		push_error("Snapshot: pista %d n-are landmark cu id %d" % [track_index, id])
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

