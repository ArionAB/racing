extends Node
## TRIPLANARUL DE LUME IN MULTIMESH: echivalentul din coacere
## (`TrackDecorBatch._mm_triplanar`) trebuie sa arate PIXEL CU PIXEL ca
## materialul original pe un nod.
##
##   godot --path . res://tools/ProbeTriMultiMesh.tscn
##
## Ruleaza CU FEREASTRA (compara cadre randate). Iese cu 0 daca trece, 1 daca
## pica, 2 daca n-a putut masura.
##
## Cutie texturata cu benzi, aceeasi transformare desenata o data ca
## [MeshInstance3D] cu [StandardMaterial3D]-ul triplanar (etalonul) si o data
## ca instanta [MultiMesh] cu echivalentul. Trei cazuri: rotatie, rotatie +
## scalare neuniforma (cazul care strica shaderul standard), translatie; fiecare
## cu si fara `NU_SCALE` pe nod, ca in coacere.
##
## SABOTAJUL: acelasi test cu materialul standard pus direct in MultiMesh
## TREBUIE sa pice pe scalarea neuniforma (masurat: 99,8% din pixeli). Daca nu
## pica, sonda nu mai vede bugul pe care il pazeste — iese cu 2, nu cu verde.

const PASS_MAX_PCT: float = 0.05
const SABOTAGE_MIN_PCT: float = 20.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("ProbeTriMultiMesh: ruleaza CU FEREASTRA — in --headless nu se deseneaza nimic.")
		get_tree().quit(2)
		return
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	env.environment = e
	add_child(env)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.3, 1.2, 6.0)
	cam.look_at(Vector3(0.3, 0.5, 0.0))
	cam.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.5, 0.0)
	add_child(sun)

	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var band := (y / 8) % 2 == 0
			var col := (x / 16) % 2 == 0
			img.set_pixel(x, y, Color(1, 0.2, 0.1) if band
				else (Color(0.1, 0.3, 1) if col else Color(0.1, 1, 0.3)))
	# Aceleasi reglaje ca `Palette.triplanar_class_material`, cu filtru
	# nearest ca o diferenta de proiectie sa schimbe pixeli intregi.
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mat.metallic_specular = 0.15
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(0.7, 0.7, 0.7)
	mat.uv1_triplanar_sharpness = 4.0
	mat.albedo_color = Color(0.95, 0.9, 1.0)
	var mm_mat := TrackDecorBatch._mm_triplanar(mat)
	if mm_mat == null:
		push_error("ProbeTriMultiMesh: _mm_triplanar a refuzat un material triplanar de clasa.")
		get_tree().quit(1)
		return

	var box := BoxMesh.new()
	box.size = Vector3(2.0, 1.0, 1.5)
	var cases := {
		"rotatie": Transform3D(Basis.from_euler(Vector3(0.4, 0.9, 1.2)),
			Vector3(0.5, 0.4, 0.2)),
		"rotatie + scala neuniforma": Transform3D(
			Basis.from_euler(Vector3(0.4, 0.9, 1.2)).scaled(Vector3(1.6, 0.6, 1.0)),
			Vector3(0.5, 0.4, 0.2)),
		"translatie": Transform3D(Basis.IDENTITY, Vector3(0.9, 0.4, 0.2)),
	}
	var failed := false
	var sabotage := 0.0
	for name: String in cases:
		var xf: Transform3D = cases[name]
		var ref := await _shot_node(box, mat, xf)
		var plain := await _shot_mm(box, mm_mat, xf, Vector3.ONE)
		var nu := await _shot_mm(box, mm_mat, xf, TrackDecorBatch.NU_SCALE)
		var std := await _shot_mm(box, mat, xf, Vector3.ONE)
		var d1 := _diff(ref, plain)
		var d2 := _diff(ref, nu)
		var ds := _diff(ref, std)
		sabotage = maxf(sabotage, ds)
		var ok := d1 <= PASS_MAX_PCT and d2 <= PASS_MAX_PCT
		failed = failed or not ok
		print("  %-28s echivalent: %5.2f%%  cu NU_SCALE: %5.2f%%  (standard in MultiMesh: %5.2f%%)  %s"
			% [name, d1, d2, ds, "OK" if ok else "PICA"])
	if sabotage < SABOTAGE_MIN_PCT:
		push_error("ProbeTriMultiMesh: sabotajul nu pica (%.2f%% < %.0f%%) — sonda nu mai vede bugul."
			% [sabotage, SABOTAGE_MIN_PCT])
		get_tree().quit(2)
		return
	print("ProbeTriMultiMesh: %s" % ("PICA" if failed else "OK"))
	get_tree().quit(1 if failed else 0)


func _shot_node(mesh: Mesh, mat: Material, xf: Transform3D) -> Image:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	add_child(mi)
	var img := await _grab()
	mi.queue_free()
	return img


## Ca in coacere: nodul poarta scala lui, instanta e compensata.
func _shot_mm(mesh: Mesh, mat: Material, xf: Transform3D,
		node_scale: Vector3) -> Image:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 1
	var node_xf := Transform3D(Basis.from_scale(node_scale), Vector3.ZERO)
	mm.set_instance_transform(0, node_xf.affine_inverse() * xf)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.scale = node_scale
	add_child(mmi)
	var img := await _grab()
	mmi.queue_free()
	return img


func _grab() -> Image:
	for _i in 3:
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## Procentul de pixeli desenati care difera (suma |dRGB| > 0,02).
func _diff(a: Image, b: Image) -> float:
	var n := 0
	var bad := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca.v < 0.02 and cb.v < 0.02:
				continue
			n += 1
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.02:
				bad += 1
	return 100.0 * bad / maxf(n, 1)
