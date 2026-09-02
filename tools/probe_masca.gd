extends Node
## MASCA DE OBIECT pentru masurarea detaliului local.
##
## De ce exista: masuratoarea pe CASETA dreptunghiulara peste un obiect
## neregulat contine fundal in proportie NECUNOSCUTA. Fundalul (cer, teren
## indepartat, ceata) e mai neted, deci dala iese "prea plata" chiar cand
## obiectul e in regula. S-a intamplat de trei ori intr-o singura sesiune, o
## data cu o caseta care era 79% cer.
##
## Ce face: aseaza camera EXACT ca `--driver` din Snapshot (aceiasi parametri
## MEASURE_*), randeaza cadrul, si pe langa el scrie o MASCA alb/negru pentru
## fiecare mesh cerut — rasterizata software din triunghiurile mesh-ului
## proiectate prin aceeasi camera, cu z-buffer pe TOATE mesh-urile vizibile ca
## sa nu marcheze pixeli ocluzati.
##
##   godot --rendering-driver vulkan --path . res://tools/ProbeMasca.tscn -- \
##       --track=13 --frac=0.27 --match=Taietura
##
## Iese: snapshots/masca_<frac>_cadru.png si snapshots/masca_<frac>_<nume>.png

const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2

var _w: int = 1280
var _h: int = 720


func _ready() -> void:
	var track_index := 13
	var frac := 0.27
	var matches: Array[String] = []
	var no_shadow := false
	var caster := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--caster="):
			caster = arg.trim_prefix("--caster=")
		elif arg == "--no-shadow":
			no_shadow = true
		elif arg.begins_with("--match="):
			matches.append(arg.trim_prefix("--match="))
	if matches.is_empty():
		matches.append("Taietura")

	var idx := GameState.resolve_track_index(track_index)
	var scene: PackedScene = load(GameState.TRACK_SCENES[idx])
	var track: Track = scene.instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var cam := Camera3D.new()
	add_child(cam)
	var pts := track.route_at(0).baked
	var n := pts.size()
	var i := int(frac * float(n)) % n
	var focus: Vector3 = pts[i]
	var ahead: Vector3 = pts[track.route_at(0).wrap_index(i + 12)]
	var dir := (ahead - focus).normalized()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = MEASURE_FOV
	cam.far = 400.0
	cam.position = focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	cam.look_at(focus + dir * MEASURE_LOOK_AHEAD
		+ Vector3.UP * MEASURE_LOOK_HEIGHT, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	# A/B DE ATRIBUIRE (--no-shadow): stinge umbrele directionalei ca sa se vada
	# cat din intunericul unei suprafete e UMBRA si cat e ALBEDO. Fara pasul asta
	# nu se poate spune daca un perete inchis are culoarea gresita sau doar sta
	# in umbra — si cele doua cer reparatii opuse.
	# --caster=NUME: stinge cast_shadow doar pe mesh-urile al caror nume contine
	# NUME. Asa se afla CINE arunca umbra, nu doar CA exista una.
	if caster != "":
		var stk2: Array[Node] = [get_tree().root]
		var off := 0
		while not stk2.is_empty():
			var nn: Node = stk2.pop_back()
			if nn is GeometryInstance3D and nn.name.contains(caster):
				(nn as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				off += 1
			for c in nn.get_children():
				stk2.append(c)
		print("cast_shadow OFF pe %d mesh-uri care contin \"%s\"" % [off, caster])
		if off == 0:
			print("  (niciun mesh cu numele asta — vezi lista de mai jos)")
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

	if no_shadow:
		var stk: Array[Node] = [get_tree().root]
		while not stk.is_empty():
			var nn: Node = stk.pop_back()
			if nn is DirectionalLight3D:
				(nn as DirectionalLight3D).shadow_enabled = false
			for c in nn.get_children():
				stk.append(c)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

	var vp := get_viewport()
	_w = vp.get_texture().get_width()
	_h = vp.get_texture().get_height()
	var dir_out := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir_out)
	var tag := ("%.3f" % frac) + ("_noumbra" if no_shadow else ("_fara_" + caster.to_lower() if caster != "" else ""))
	vp.get_texture().get_image().save_png(
		"%s/masca_%s_cadru.png" % [dir_out, tag])
	print("CADRU: %s/masca_%s_cadru.png (%dx%d)" % [dir_out, tag, _w, _h])

	# Z-buffer pe TOT ce se randeaza, apoi masca per obiect cerut.
	var all: Array[MeshInstance3D] = []
	_collect(track, all)
	var zbuf := PackedFloat32Array()
	zbuf.resize(_w * _h)
	zbuf.fill(1e20)
	var owner_id := PackedInt32Array()
	owner_id.resize(_w * _h)
	owner_id.fill(-1)
	for k in all.size():
		_raster(all[k], cam, zbuf, owner_id, k)

	# Numaratoare pe TOATE mesh-urile vizibile, ca atribuirea sa fie completa:
	# altfel nu se stie ce acopera restul cadrului.
	var per := {}
	for pix in _w * _h:
		var k: int = owner_id[pix]
		if k >= 0:
			per[k] = int(per.get(k, 0)) + 1
	var order: Array = per.keys()
	order.sort_custom(func(x, y): return int(per[x]) > int(per[y]))
	print("--- ce acopera cadrul (primele 12) ---")
	for k in order.slice(0, 12):
		print("  %7d px  %5.2f%%  %s" % [per[k],
			100.0 * float(per[k]) / float(_w * _h), all[k].name])

	for m in matches:
		for k in all.size():
			if not all[k].name.contains(m):
				continue
			if int(per.get(k, 0)) < 200:
				continue
			var img := Image.create(_w, _h, false, Image.FORMAT_L8)
			img.fill(Color.BLACK)
			for pix in _w * _h:
				if owner_id[pix] == k:
					img.set_pixel(pix % _w, pix / _w, Color.WHITE)
			var safe: String = all[k].name.to_lower().replace(" ", "_")
			var out := "%s/masca_%s_%s.png" % [dir_out, tag, safe]
			img.save_png(out)
			print("MASCA %s: %d px (%.2f%%) -> %s"
				% [all[k].name, int(per[k]),
				100.0 * float(per[k]) / float(_w * _h), out])
	get_tree().quit()


func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).visible \
			and (node as MeshInstance3D).mesh != null:
		var vis := true
		var p: Node = node
		while p != null:
			if p is Node3D and not (p as Node3D).visible:
				vis = false
				break
			p = p.get_parent()
		if vis:
			out.append(node as MeshInstance3D)
	for c in node.get_children():
		_collect(c, out)


## Rasterizeaza triunghiurile unui mesh in z-buffer, marcand proprietarul.
func _raster(mi: MeshInstance3D, cam: Camera3D, zbuf: PackedFloat32Array,
		owner_id: PackedInt32Array, id: int) -> void:
	var xf := mi.global_transform
	var mesh := mi.mesh
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		if arr.is_empty():
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ind := PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null:
			ind = arr[Mesh.ARRAY_INDEX]
		# Proiecteaza o data toti vertecsii.
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
			_tri(sp[a], sp[b], sp[c], zbuf, owner_id, id)


func _tri(a: Vector3, b: Vector3, c: Vector3, zbuf: PackedFloat32Array,
		owner_id: PackedInt32Array, id: int) -> void:
	# Orice vertex in spatele camerei: se sare (clipping-ul complet n-ar
	# schimba concluzia pe un obiect care e in fata).
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
				owner_id[k] = id
