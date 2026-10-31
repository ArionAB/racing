extends Node
## TREPTELE DE DEPARTE ALE PADURII (MeshForest, Kyoto/Track18), doua contracte:
##
##   godot --path . res://tools/ProbeForestFar.tscn
##
## Ruleaza CU FEREASTRA (numara pixeli randati si citeste transformarile din
## MultiMesh, care in --headless ies (0,0,0)). Iese cu 0 daca trece, 1 daca
## pica, 2 daca n-a putut masura sau sabotajul nu e prins.
##
## 1. BULGARII TIN SILUETA. Treapta foarte departata (coroane-bipiramide,
##    `MeshForest._with_blobs`) trebuie sa acopere pe ecran cat treapta
##    grosiera pe care o inlocuieste — altfel valea se rareste (sau se umfla)
##    exact la pragul `xfar_m`. Fiecare specie cu bulgari se randeaza alb pe
##    negru, ortografic, la ~10 px/m (dublul densitatii unui arbore la 110 m in
##    captura de joc), din 4 azimuturi, de la 6 grade deasupra orizontului.
##    Raportul de pixeli bulgari / grosier: in [RATIO_MIN, RATIO_MAX].
##    SABOTAJ: castigul `SABOTAGE_GAIN` trebuie sa iasa sub RATIO_MIN.
##
## 2. CELULELE ARATA FIECARE ARBORE EXACT O DATA. Felie -> celula grosiera ->
##    celula de bulgari, legate prin `visibility_parent`. Din camere puse pe
##    traseu (inaltimea si distanta camerei de urmarire), dupa regulile Godot
##    (un nod se vede cat distanta pana la centrul cutiei lui e in
##    [begin, end), si doar cat parintele lui — si toti stramosii — sunt
##    ascunsi FIINDCA sunt mai aproape decat `begin`), fiecare arbore la mai
##    putin de `NEAR_CHECK_M` trebuie sa aiba exact o reprezentare vizibila,
##    oricare altul cel mult una. Plus: o celula nu arata un arbore pe care
##    feliile singure l-ar fi aratat intreg sau mediu, daca e la mai putin de
##    `lod_m` (pragul vazut la volan pe 27 oct 2026).
##    SABOTAJ: cu `visibility_parent` sters de pe felii, trebuie sa apara dubluri.

const RATIO_MIN: float = 0.9
const RATIO_MAX: float = 1.1
const SABOTAGE_GAIN: float = 0.75
const PX_PER_M: float = 10.0
const VIEW_PX: int = 256
const CAMS: int = 24
const NEAR_CHECK_M: float = 100.0
const CAM_BACK_M: float = 12.5
const CAM_UP_M: float = 10.0

var _vp: SubViewport
var _cam: Camera3D
var _mi: MeshInstance3D


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("ProbeForestFar: ruleaza CU FEREASTRA — in --headless nu se deseneaza nimic.")
		get_tree().quit(2)
		return
	var track := (load("res://scenes/tracks/Track18.tscn") as PackedScene).instantiate() as Track
	var forest := track.get_node_or_null("PadureMasa") as MeshForest
	if forest == null:
		print("PROBA: nu exista PadureMasa pe Track18")
		get_tree().quit(2)
		return
	var r1 := await _blobs(forest, String(track.theme_decor))
	add_child(track)
	var guard := 0
	while not forest.done and guard < 3000:
		await get_tree().process_frame
		guard += 1
	var r2 := _cells(track, forest)
	print("ProbeForestFar: bulgari %s, celule %s" % [_word(r1), _word(r2)])
	get_tree().quit(maxi(r1, r2))


func _word(r: int) -> String:
	return ["OK", "PICA", "NEMASURAT"][r]


# --- 1. silueta bulgarilor ---------------------------------------------------

func _blobs(forest: MeshForest, theme: String) -> int:
	forest._build_species(theme)
	_setup()
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_mi.material_override = white
	var ok := true
	var measured := 0
	var sabotage_caught := 0
	var stems: Array = forest._species_far.keys()
	stems.sort()
	for stem: String in stems:
		var far: Mesh = forest._species_far[stem]
		var xfar: Mesh = forest._species_xfar[stem]
		if xfar == far:
			print("  %-14s fara treapta de bulgari" % stem)
			continue
		var a_far := await _coverage(far)
		var a_x := await _coverage(xfar)
		var a_sab := await _coverage(MeshForest._blob_mesh(far as ArrayMesh, SABOTAGE_GAIN))
		if a_far <= 0:
			print("MASURATOARE MOARTA: %s nu acopera niciun pixel" % stem)
			return 2
		measured += 1
		var r := float(a_x) / float(a_far)
		var rs := float(a_sab) / float(a_far)
		var pass_ := r >= RATIO_MIN and r <= RATIO_MAX
		ok = ok and pass_
		if rs < RATIO_MIN:
			sabotage_caught += 1
		print("  %-14s grosier %6d px  bulgari %6d px  raport %.3f %s | sabotaj (castig %.2f) %.3f" % [
			stem, a_far, a_x, r, "OK" if pass_ else "PICA", SABOTAGE_GAIN, rs])
	_vp.queue_free()
	if measured == 0:
		print("MASURATOARE MOARTA: nicio specie cu treapta de bulgari")
		return 2
	if sabotage_caught < measured:
		print("SABOTAJ NEPRINS (bulgari): %d/%d specii" % [sabotage_caught, measured])
		return 2
	return 0 if ok else 1


func _setup() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(VIEW_PX, VIEW_PX)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.msaa_3d = Viewport.MSAA_DISABLED
	_vp.own_world_3d = true
	add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	env.environment = e
	_vp.add_child(env)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = float(VIEW_PX) / PX_PER_M
	_cam.near = 0.1
	_cam.far = 200.0
	_vp.add_child(_cam)
	_cam.current = true
	_mi = MeshInstance3D.new()
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vp.add_child(_mi)


## Pixelii acoperiti de mesh, insumati pe 4 azimuturi.
func _coverage(mesh: Mesh) -> int:
	_mi.mesh = mesh
	var c := mesh.get_aabb().get_center()
	var total := 0
	for k in 4:
		var yaw := TAU * float(k) / 4.0 + 0.3
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		dir = (dir * cos(deg_to_rad(6.0)) + Vector3.UP * sin(deg_to_rad(6.0))).normalized()
		_cam.position = c + dir * 80.0
		_cam.look_at(c, Vector3.UP)
		for _f in 3:
			await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).r > 0.5:
					total += 1
	return total


# --- 2. exact o reprezentare -------------------------------------------------

func _cells(track: Track, forest: MeshForest) -> int:
	var mmis: Array[MultiMeshInstance3D] = []
	for c in forest.get_children():
		if c is MultiMeshInstance3D:
			mmis.append(c as MultiMeshInstance3D)
	var n_cells := 0
	for m in mmis:
		if m.name.begins_with("celula_"):
			n_cells += 1
	if n_cells == 0:
		print("MASURATOARE MOARTA: padurea nu are celule (far_cell_m = 0?)")
		return 2
	# Arborele = pozitia lui (la cm); reprezentarile = (index mmi) pe arbore.
	var reps: Dictionary = {}
	var nonzero := 0
	for mi in mmis.size():
		var mm := mmis[mi].multimesh
		for i in mm.instance_count:
			var o := mm.get_instance_transform(i).origin
			if o != Vector3.ZERO:
				nonzero += 1
			var key := Vector3i((o * 100.0).round())
			if not reps.has(key):
				reps[key] = PackedInt32Array()
			var r: PackedInt32Array = reps[key]
			r.append(mi)
			reps[key] = r
	if nonzero == 0:
		print("MASURATOARE MOARTA: transformarile din MultiMesh ies (0,0,0)")
		return 2
	var res := _check_cells(track, forest, mmis, reps, false)
	print("  celule: %d MultiMesh, %d arbori, %d camere | dubluri %d, lipsa %d, celula prea aproape %d" % [
		n_cells, reps.size(), CAMS, res[0], res[1], res[2]])
	var ok: bool = res[0] == 0 and res[1] == 0 and res[2] == 0
	# Sabotaj: feliile fara parinte -> celula si felia se vad deodata.
	var saved: Dictionary = {}
	for m in mmis:
		if not m.name.begins_with("celula_") and not m.visibility_parent.is_empty():
			saved[m] = m.visibility_parent
			m.visibility_parent = NodePath()
	var sab := _check_cells(track, forest, mmis, reps, true)
	for m: MultiMeshInstance3D in saved:
		m.visibility_parent = saved[m]
	print("  sabotaj (felii fara visibility_parent): dubluri %d" % sab[0])
	if sab[0] == 0:
		print("SABOTAJ NEPRINS (celule): fara parinte n-a aparut nicio dublura")
		return 2
	return 0 if ok else 1


## [dubluri, lipsa, celula prea aproape], insumate pe camere.
func _check_cells(track: Track, forest: MeshForest, mmis: Array[MultiMeshInstance3D],
		reps: Dictionary, quiet: bool) -> Array:
	var route := track.route_at(0)
	var n := route.baked.size()
	var centers: Array[Vector3] = []
	var parent_of := PackedInt32Array()
	var index_of: Dictionary = {}
	for mi in mmis.size():
		index_of[mmis[mi]] = mi
	for m in mmis:
		centers.append((m.global_transform * m.custom_aabb).get_center())
	for m in mmis:
		var p := -1
		if not m.visibility_parent.is_empty():
			p = int(index_of.get(m.get_node(m.visibility_parent), -1))
		parent_of.append(p)
	var dup := 0
	var miss := 0
	var close := 0
	var shown := 0
	for ci in CAMS:
		var i := int(float(ci) / CAMS * n) % n
		var dir := route.baked[(i + 4) % n] - route.baked[i]
		dir.y = 0.0
		dir = dir.normalized()
		var cam := route.baked[i] - dir * CAM_BACK_M + Vector3.UP * CAM_UP_M
		# Vizibil dupa propriul interval, si "ascuns pentru ca e prea aproape".
		var own := PackedByteArray()
		var near_hidden := PackedByteArray()
		var fine_only := PackedByteArray()
		own.resize(mmis.size())
		near_hidden.resize(mmis.size())
		for mi in mmis.size():
			var m := mmis[mi]
			var d := cam.distance_to(centers[mi])
			var ok_b := m.visibility_range_begin <= 0.0 or d >= m.visibility_range_begin
			var ok_e := m.visibility_range_end <= 0.0 or d < m.visibility_range_end
			own[mi] = 1 if ok_b and ok_e else 0
			near_hidden[mi] = 1 if m.visibility_range_begin > 0.0 and d < m.visibility_range_begin else 0
		fine_only = own.duplicate()
		var vis := PackedByteArray()
		vis.resize(mmis.size())
		for mi in mmis.size():
			var v := own[mi] == 1
			var p := parent_of[mi]
			while v and p >= 0:
				v = near_hidden[p] == 1
				p = parent_of[p]
			vis[mi] = 1 if v else 0
		for key: Vector3i in reps:
			var r: PackedInt32Array = reps[key]
			var count := 0
			var cell_shown := false
			var fine_detail := false
			for mi in r:
				if vis[mi] == 1:
					count += 1
					if mmis[mi].name.begins_with("celula_"):
						cell_shown = true
				if fine_only[mi] == 1 and not mmis[mi].name.begins_with("celula_") \
						and not mmis[mi].name.ends_with("_far"):
					fine_detail = true
			var d := cam.distance_to(Vector3(key) / 100.0)
			if count > 1:
				dup += 1
				if not quiet and dup <= 3:
					print("    dublura: arbore %s la %.0f m, cam %d" % [Vector3(key) / 100.0, d, ci])
			elif count == 0 and d < NEAR_CHECK_M:
				miss += 1
				if not quiet and miss <= 3:
					print("    lipsa: arbore %s la %.0f m, cam %d" % [Vector3(key) / 100.0, d, ci])
			if count > 0:
				shown += 1
			if cell_shown and fine_detail and d < forest.lod_m - 1.0:
				close += 1
				if not quiet and close <= 3:
					print("    celula prea aproape: arbore la %.1f m, cam %d" % [d, ci])
	if shown == 0:
		return [0, 1, 0]
	return [dup, miss, close]
