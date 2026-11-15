extends Node3D
## PASTELUL PE INSTANTA (pasul 8b): casa din `CityFill` cu `wall_classes` deseneaza peretele pe
## materialul clasei de BAZA (`sf_clapboard`) cu culoarea instantei = tenta clasei / tenta bazei.
## Sonda asta arata ca iese ACELASI pixel ca o casa pusa ca nod (`WorldProp` + metadata
## `wall_class`, calea randului din fata), pentru fiecare din cele cinci pasteluri, si ca o casa
## ceruta OGLINDIT (determinant negativ) iese ca fisierul `_m` pus ca nod, nu pe dos.
##
##   godot --path . res://tools/ProbeSfTenta.tscn [-- --sabotaj]
##
## Cu FEREASTRA (randare reala). Camera ortografica pe fatade, lumina directionala fara umbre,
## LOD-urile oprite. Pe un cadru, patru case la 12 m una de alta (3 dale ale proiectiei
## triplanare de 4 m, deci textura cade identic): A = nod cu pastelul, B = CityFill cu pastelul pe
## instanta, C = nodul fisierului `_m` cu pastelul, D = CityFill cu modelul de baza OGLINDIT.
## Compara pixel cu pixel A cu B si C cu D. `--sabotaj` da instantei B pastelul urmator: TREBUIE
## sa pice. `--per-clasa` opreste pastelul pe instanta (`wall_tint_per_instance = false`): CityFill
## cade pe un sablon per clasa, iar pixelii trebuie sa iasa la fel. Exit 1 daca pica.

const STEM := "sf_row_b_square"
const DIR := "res://assets/models/sanfrancisco/buildings/"
const STEP_M: float = 12.0
const PX_PER_M: float = 30.0
const MAX_MEAN: float = 1.5      # diferenta medie admisa pe canal (0-255)
const MAX_BAD: float = 0.5       # % pixeli de casa cu diferenta > 12 pe vreun canal

var _sabotage := false
var _per_class := false
var _fails := 0


func _ready() -> void:
	_sabotage = "--sabotaj" in OS.get_cmdline_user_args()
	_per_class = "--per-clasa" in OS.get_cmdline_user_args()
	get_window().size = Vector2i(int(4.0 * STEP_M * PX_PER_M), int(15.0 * PX_PER_M))
	get_viewport().mesh_lod_threshold = 0.0
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0, 0, 0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30.0, 15.0, 0.0)
	sun.shadow_enabled = false
	add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 15.0
	cam.position = Vector3(1.5 * STEP_M, 6.0, 40.0)
	add_child(cam)
	cam.make_current()
	var classes: Array[String] = WorldProp.WALL_CLASSES
	print("=== ProbeSfTenta: %s, %d pasteluri%s ===" % [STEM, classes.size(), " [sabotaj]" if _sabotage else ""])
	for ci in classes.size():
		var holder := Node3D.new()
		add_child(holder)
		# fata casei e -Z local: rotita cu 180 de grade, fatada priveste camera (+Z)
		var rot := Basis(Vector3.UP, PI)
		holder.add_child(_node_house(DIR + STEM + ".glb", classes[ci], Transform3D(rot, Vector3.ZERO)))
		holder.add_child(_node_house(DIR + STEM + "_m.glb", classes[ci], Transform3D(rot, Vector3(2.0 * STEP_M, 0, 0))))
		var fill := CityFill.new()
		fill.models = [load(DIR + STEM + ".glb") as PackedScene]
		fill.mirror_models = [load(DIR + STEM + "_m.glb") as PackedScene]
		fill.wall_classes = PackedStringArray(classes)
		fill.wall_tint_per_instance = not _per_class
		var mir := Basis(rot.x * -1.0, rot.y, rot.z)
		var xf := PackedFloat32Array()
		for t: Array in [[rot, STEP_M], [mir, 3.0 * STEP_M]]:
			var b: Basis = t[0]
			xf.append_array([0, b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, float(t[1]), 0, 0])
		fill.explicit_xforms = xf
		var wi := (ci + 1) % classes.size() if _sabotage else ci
		fill.explicit_wall = PackedInt32Array([wi, ci])
		holder.add_child(fill)
		for _i in 90:
			if not fill.stats.is_empty():
				break
			await get_tree().process_frame
		for _i in 8:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		_compare(img, classes[ci], fill.stats)
		if ci == 0:
			# LOD-urile partilor din MultiMesh: peretele si atlasul raman mesh-urile importului (cu
			# LOD-urile lui), umbra unita le are generate (CLAUDE.md, „LOD-uri pe tot ce e reconstruit").
			for c in fill.get_children():
				var mmi := c as MultiMeshInstance3D
				if mmi != null and mmi.multimesh != null:
					var m := mmi.multimesh.mesh
					print("    %-48s LOD-uri %d, %d tri la LOD0%s" % [String(mmi.name),
						MeshCpu.surface_lods(m, 0).size(), _tris0(m),
						" (umbra)" if mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY else ""])
		holder.queue_free()
		await get_tree().process_frame
	print("VERDICT: %s" % ("OK" if _fails == 0 else "PICA (%d comparatii)" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)


func _node_house(path: String, cls: String, xf: Transform3D) -> Node3D:
	var wp := Node3D.new()
	wp.set_script(load("res://scenes/props/world_prop.gd"))
	wp.set("auto_collision", false)
	var inst := (load(path) as PackedScene).instantiate() as Node3D
	inst.transform = xf
	inst.set_meta(WorldProp.WALL_CLASS_META, cls)
	wp.add_child(inst)
	return wp


func _compare(img: Image, cls: String, st: Dictionary) -> void:
	var shift := int(round(STEP_M * PX_PER_M))
	for pair: Array in [[0, "A nod / B CityFill"], [2, "C nod _m / D CityFill oglindit"]]:
		var x0 := int(pair[0]) * shift
		var n := 0
		var bad := 0
		var sum := 0.0
		var ma := Vector3.ZERO
		var mb := Vector3.ZERO
		for y in img.get_height():
			for x in range(x0, x0 + shift):
				var a := img.get_pixel(x, y)
				var b := img.get_pixel(x + shift, y)
				if a.get_luminance() < 0.02 and b.get_luminance() < 0.02:
					continue      # fundalul negru
				n += 1
				var d := Vector3(absf(a.r - b.r), absf(a.g - b.g), absf(a.b - b.b)) * 255.0
				sum += (d.x + d.y + d.z) / 3.0
				if maxf(d.x, maxf(d.y, d.z)) > 12.0:
					bad += 1
				ma += Vector3(a.r, a.g, a.b)
				mb += Vector3(b.r, b.g, b.b)
		var mean := sum / maxf(float(n), 1.0)
		var bad_p := 100.0 * float(bad) / maxf(float(n), 1.0)
		var ok := n > 2000 and mean <= MAX_MEAN and bad_p <= MAX_BAD
		if not ok:
			_fails += 1
		ma /= maxf(float(n), 1.0)
		mb /= maxf(float(n), 1.0)
		print("  %-20s %-30s pixeli %6d  dif. medie %.2f  >12: %.2f%%  media A %s / B %s  %s" % [cls, pair[1], n,
			mean, bad_p, _rgb(ma), _rgb(mb), "OK" if ok else "PICA"])
	print("    CityFill: %s pe %s, oglindite pe _m %s, pe dos %s" % [str(st.get("per_wall")),
		str(st.get("wall_mode")), str(st.get("mirrored")), str(st.get("inside_out"))])


static func _tris0(m: Mesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		n += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


static func _rgb(v: Vector3) -> String:
	return "(%d,%d,%d)" % [int(v.x * 255.0), int(v.y * 255.0), int(v.z * 255.0)]
