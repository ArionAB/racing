extends Node
## ACOPERIREA DE PIXELI DE ANIMAL (POI B — raul de gnu, Serengeti Track14).
##
## De ce nu ProbeMasca: turma e MultiMeshInstance3D (2 loturi, Herd + Herd-
## Zebra), iar `probe_masca.gd._collect` colecteaza doar MeshInstance3D — un
## MultiMesh n-are un singur transform de instanta, deci n-ar aparea deloc in
## masca. Un heuristic de culoare (HSV) a fost incercat si respins: blana de
## gnu, drumul in umbra si iarba cad in acelasi interval H 20-40 / S 0.6-0.8 /
## V 0.35-0.55 pe captura reala (masurat), deci pragurile de culoare confunda
## animal cu fundal in ambele directii.
##
## Ce face: acelasi rasterizator soft (z-buffer, triunghi cu triunghi) ca
## ProbeMasca, dar iterat si peste INSTANTELE unui MultiMesh (transformul
## fiecarei instante * mesh-ul ei), nu doar peste MeshInstance3D simple.
## Fiecare pixel e marcat "animal" (apartine unei instante din loturile
## Herd/HerdZebra ale HerdHazard-ului cerut) sau "altceva", cu test de
## adancime fata de TOATA geometria vizibila (ca un animal ocluzionat de alt
## animal sau de un copac sa nu se numere de doua ori si sa nu se numere prin
## ocluzor).
##
## Camera: aceiasi parametri ca `Snapshot.tscn --gamecam` (ChaseCamera.
## DEFAULT_DISTANCE/HEIGHT/BASE_FOV/LOOK_AHEAD/LOOK_HEIGHT), turma adusa la
## `--herd-at` ca in `snapshot.gd._set_herd_time`, ca cifra sa fie comparabila
## cu capturile deja facute.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHerdCoverage.tscn -- \
##       --track=7 --frac=0.06 --herd-at=4 --box=0.20,0.62,0.0,1.0
##
## `--box=y0,y1,x0,x1`: fractia din cadru unde se calculeaza acoperirea
## (caseta turmei). Implicit acopera banda unde turma traverseaza drumul.
## Scrie si `snapshots/herd_coverage_<frac>.png` (cadrul) si `..._masca.png`
## (alb = animal) pentru inspectie vizuala.
##
## Implicit (`--fast`, mereu pornit fara `--full`): ocluzia se calculeaza
## DOAR intre instantele de animal (Herd/HerdZebra) — teren, copaci, iarba nu
## intra in rasterizator. Un rasterizator soft peste toata geometria din
## raza camerei (mii de instante de vegetatie) a masurat minute intregi fara
## sa termine un cadru; `--fast` reduce la exact ce cere criteriul (suprapu-
## nere ANIMAL-peste-ANIMAL) si ruleaza in secunde. `--full` reactiveaza
## rasterizarea completa (mai corecta, mult mai lenta — de folosit doar daca
## se suspecteaza ca un copac ascunde vizibil animale in caseta).

var _w: int = 1280
var _h: int = 720


func _ready() -> void:
	print("PROBE START")
	var track_index := 7
	var frac := 0.06
	var herd_at := 4.0
	var box := [0.20, 0.62, 0.0, 1.0]
	var fast_mode := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--herd-at="):
			herd_at = float(arg.trim_prefix("--herd-at="))
		elif arg.begins_with("--box="):
			var parts := arg.trim_prefix("--box=").split(",")
			box = [float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3])]
		elif arg == "--full":
			fast_mode = false

	print("PROBE ARGS PARSED, se incarca pista %d" % track_index)
	var idx := GameState.resolve_track_index(track_index)
	var scene: PackedScene = load(GameState.TRACK_SCENES[idx])
	var track: Track = scene.instantiate() as Track
	add_child(track)
	print("PISTA INSTANTIATA, astept fizica")
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("FIZICA GATA")

	# Turma la faza ceruta (identic cu snapshot.gd._set_herd_time).
	var herds := track.find_children("*", "HerdHazard", true, false)
	print("HERZI GASITE: %d" % herds.size())
	var total_instances := 0
	for node in herds:
		var herd := node
		herd.set("_time", herd_at)
		herd.call("_advance_animals", 0.0)
		print("  _advance_animals gata pentru %s" % herd.name)
		herd.call("_place_visuals")
		print("  _place_visuals gata pentru %s" % herd.name)
		herd.set_physics_process(false)
		total_instances += int(herd.call("count"))
	print("TURME PROCESATE, total_instances=%d" % total_instances)
	if herds.is_empty():
		print("ProbeHerdCoverage: nicio turma (HerdHazard) pe pista asta")
		get_tree().quit(1)
		return

	# Camera: parametrii REALI ai --gamecam din Snapshot (ChaseCamera).
	var route := track.route_at(0)
	print("ROUTE OBTINUTA")
	var pts := route.baked
	print("PTS BAKED: %d" % pts.size())
	var n := pts.size()
	var idx2 := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx2]
	var ahead_idx := route.wrap_index(idx2 + 8)
	var dir := (pts[ahead_idx] - focus).normalized()
	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 400.0
	cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var vp := get_viewport()
	_w = vp.get_texture().get_width()
	_h = vp.get_texture().get_height()

	# Multimile de animale (id-urile lor de MultiMeshInstance3D) ale turmelor
	# cerute — orice alt MultiMeshInstance3D (decor, vegetatie) ramane "altceva".
	var animal_mmis: Dictionary = {}
	for node in herds:
		for lot_name in ["_mmi", "_mmi_zebra"]:
			var mmi := node.get(lot_name) as MultiMeshInstance3D
			if mmi != null:
				animal_mmis[mmi.get_instance_id()] = true

	var zbuf := PackedFloat32Array()
	zbuf.resize(_w * _h)
	zbuf.fill(1e20)
	var is_animal := PackedByteArray()
	is_animal.resize(_w * _h)
	is_animal.fill(0)
	var touched := PackedByteArray()
	touched.resize(_w * _h)
	touched.fill(0)

	# Doar geometria de langa camera poate ocluziona turma din cadru: un
	# rasterizator software pe TOATA pista (teren + vegetatie, 1.1M tri
	# raportate de probe_decor) e prea lent in GDScript — masurat, minute
	# intregi si tot nu termina. `--fast` (implicit) sare peste TOT ce nu e
	# turma: singura ocluzie masurata e animal-peste-animal (exact ce cere
	# criteriul de suprapunere), cu riscul mic de a numara un animal ascuns
	# de-a dreptul dupa un copac ca vizibil. Fara `--fast`, acelasi cod merge
	# dar poate dura minute.
	const CULL_RADIUS: float = 55.0
	var cam_pos := cam.global_position

	# 1) Toate MeshInstance3D simple (decor, teren, masina) — doar ocluzori.
	var t_start := Time.get_ticks_msec()
	var mesh_used := 0
	var meshes: Array[MeshInstance3D] = []
	if not fast_mode:
		_collect_meshes(track, meshes)
		print("MeshInstance3D gasite: %d (%.1f s)" % [meshes.size(), float(Time.get_ticks_msec() - t_start) / 1000.0])
		for mi in meshes:
			var aabb_c: Vector3 = mi.global_transform * mi.get_aabb().get_center()
			if aabb_c.distance_to(cam_pos) > CULL_RADIUS + mi.get_aabb().get_longest_axis_size():
				continue
			mesh_used += 1
			_raster_mesh(mi.mesh, mi.global_transform, cam, zbuf, is_animal, touched, false)
	print("faza 1 (mesh-uri simple) gata: %.1f s, %d/%d in raza (fast=%s)"
		% [float(Time.get_ticks_msec() - t_start) / 1000.0, mesh_used, meshes.size(), fast_mode])

	# 2) Toate MultiMeshInstance3D (turma + orice alt decor pe MultiMesh):
	# animalele marcheaza is_animal=1, restul doar ocluzor. Acelasi cull de
	# distanta, per INSTANTA (o vegetatie cu 1000 instante pe toata pista,
	# doar cateva langa camera).
	var mmis: Array[MultiMeshInstance3D] = []
	_collect_multimesh(track, mmis)
	var animal_instances := 0
	var other_instances := 0
	for mmi in mmis:
		var animal := animal_mmis.has(mmi.get_instance_id())
		if fast_mode and not animal:
			continue
		var mm := mmi.multimesh
		if mm == null or mm.mesh == null:
			continue
		var base_xf := mmi.global_transform if not mmi.top_level else Transform3D.IDENTITY
		var mesh_radius := mm.mesh.get_aabb().get_longest_axis_size()
		for ii in mm.instance_count:
			var ixf := mm.get_instance_transform(ii)
			var world_xf := base_xf * ixf if not mmi.top_level else ixf
			if world_xf.origin.distance_to(cam_pos) > CULL_RADIUS + mesh_radius:
				continue
			_raster_mesh(mm.mesh, world_xf, cam, zbuf, is_animal, touched, animal)
			if animal:
				animal_instances += 1
			else:
				other_instances += 1
	print("faza 2 (multimesh) gata: %.1f s, %d instante MultiMesh (din care animal %d)"
		% [float(Time.get_ticks_msec() - t_start) / 1000.0, other_instances + animal_instances, animal_instances])

	# Caseta turmei, in pixeli.
	var y0 := int(box[0] * _h)
	var y1 := int(box[1] * _h)
	var x0 := int(box[2] * _w)
	var x1 := int(box[3] * _w)
	y0 = clampi(y0, 0, _h)
	y1 = clampi(y1, 0, _h)
	x0 = clampi(x0, 0, _w)
	x1 = clampi(x1, 0, _w)
	var n_box := 0
	var animal_box := 0
	var mask_img := Image.create(_w, _h, false, Image.FORMAT_L8)
	mask_img.fill(Color.BLACK)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var k := y * _w + x
			n_box += 1
			if is_animal[k] == 1:
				animal_box += 1
	for y in _h:
		for x in _w:
			var k := y * _w + x
			if is_animal[k] == 1:
				mask_img.set_pixel(x, y, Color.WHITE)

	var dir_out := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir_out)
	var tag := "%.3f" % frac
	vp.get_texture().get_image().save_png("%s/herd_coverage_%s_cadru.png" % [dir_out, tag])
	mask_img.save_png("%s/herd_coverage_%s_masca.png" % [dir_out, tag])

	var pct := 100.0 * float(animal_box) / float(maxi(n_box, 1))
	print("=== ACOPERIRE ANIMAL (Track%d, frac=%.3f, herd-at=%.2f) ===" % [track_index, frac, herd_at])
	print("instante turma (count() insumat pe toate HerdHazard): %d" % total_instances)
	print("instante animal RASTERIZATE (Herd+HerdZebra, toate loturile MultiMesh): %d" % animal_instances)
	print("caseta turmei: y[%.2f-%.2f] x[%.2f-%.2f], %d px" % [box[0], box[1], box[2], box[3], n_box])
	print("ACOPERIRE ANIMAL IN CASETA: %.1f%% (%d / %d px)" % [pct, animal_box, n_box])
	print("cadru: %s/herd_coverage_%s_cadru.png" % [dir_out, tag])
	print("masca: %s/herd_coverage_%s_masca.png" % [dir_out, tag])
	get_tree().quit()


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).visible and (node as MeshInstance3D).mesh != null:
		if _visible_chain(node):
			out.append(node as MeshInstance3D)
	for c in node.get_children():
		_collect_meshes(c, out)


func _collect_multimesh(node: Node, out: Array[MultiMeshInstance3D]) -> void:
	if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).visible:
		if _visible_chain(node):
			out.append(node as MultiMeshInstance3D)
	for c in node.get_children():
		_collect_multimesh(c, out)


func _visible_chain(node: Node) -> bool:
	var p: Node = node
	while p != null:
		if p is Node3D and not (p as Node3D).visible:
			return false
		p = p.get_parent()
	return true


func _raster_mesh(mesh: Mesh, xf: Transform3D, cam: Camera3D,
		zbuf: PackedFloat32Array, is_animal: PackedByteArray, touched: PackedByteArray,
		animal: bool) -> void:
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		if arr.is_empty():
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ind := PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null:
			ind = arr[Mesh.ARRAY_INDEX]
		var sp := PackedVector3Array()
		sp.resize(verts.size())
		for vi in verts.size():
			var wp: Vector3 = xf * verts[vi]
			var behind := cam.is_position_behind(wp)
			var p2 := cam.unproject_position(wp)
			var d := cam.global_position.distance_to(wp)
			sp[vi] = Vector3(p2.x, p2.y, -d if behind else d)
		var tri_count := (ind.size() / 3) if ind.size() > 0 else (verts.size() / 3)
		for t in tri_count:
			var a: int = ind[t * 3] if ind.size() > 0 else t * 3
			var b: int = ind[t * 3 + 1] if ind.size() > 0 else t * 3 + 1
			var c: int = ind[t * 3 + 2] if ind.size() > 0 else t * 3 + 2
			_tri(sp[a], sp[b], sp[c], zbuf, is_animal, touched, animal)


func _tri(a: Vector3, b: Vector3, c: Vector3, zbuf: PackedFloat32Array,
		is_animal: PackedByteArray, touched: PackedByteArray, animal: bool) -> void:
	if a.z <= 0.1 or b.z <= 0.1 or c.z <= 0.1:
		return
	var minx := int(floorf(minf(a.x, minf(b.x, c.x))))
	var maxx := int(ceilf(maxf(a.x, maxf(b.x, c.x))))
	var miny := int(floorf(minf(a.y, minf(b.y, c.y))))
	var maxy := int(ceilf(maxf(a.y, maxf(b.y, c.y))))
	if maxx < 0 or minx >= _w or maxy < 0 or miny >= _h:
		return
	minx = maxi(minx, 0)
	maxx = mini(maxx, _w - 1)
	miny = maxi(miny, 0)
	maxy = mini(maxy, _h - 1)
	var d := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	if absf(d) < 1e-9:
		return
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var l0 := ((b.y - c.y) * (px - c.x) + (c.x - b.x) * (py - c.y)) / d
			var l1 := ((c.y - a.y) * (px - c.x) + (a.x - c.x) * (py - c.y)) / d
			var l2 := 1.0 - l0 - l1
			if l0 < 0.0 or l1 < 0.0 or l2 < 0.0:
				continue
			var z := l0 * a.z + l1 * b.z + l2 * c.z
			var k := y * _w + x
			if z < zbuf[k]:
				zbuf[k] = z
				is_animal[k] = 1 if animal else 0
				touched[k] = 1
