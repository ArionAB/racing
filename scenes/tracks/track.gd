@tool
class_name Track
extends Node3D
## Generator de pista 3D din puncte de control. O pista noua = o subclasa
## care da alte puncte + fractiile pentru rampe/hazarde — atat.
## @tool: pista se construieste si IN EDITOR (preview la deschiderea
## scenei); nodurile generate nu se salveaza (nu primesc owner).
##
## Filosofia peretilor (stil Ignition): pe EXTERIORUL circuitului gard peste
## tot; pe INTERIOR doar unde soseaua e inaltata. La nivelul solului
## interiorul e deschis -> scurtaturi prin iarba lenta = risc/recompensa.

const WALL_HEIGHT: float = 1.3
## Soseaua e un "dig" solid: un mesh fara grosime lasa masina sa treaca
## prin el la viteza (depenetrarea o poate impinge pe partea gresita).
const ROAD_THICKNESS: float = 3.0

## Personalitatea pistei — suprascrise de subclase.
var track_name: String = "Pista"
var half_width: float = 7.0 # ingust = tehnic, lat = vitezomanie

## Tema vizuala: fiecare pista isi defineste LUMEA (teren, cer, decor).
var theme_decor: String = "forest" # "forest" sau "desert"
var theme_ground_tint := Color(0.45, 0.72, 0.33)
var theme_sky_top := Color(0.30, 0.50, 0.80)
var theme_sky_horizon := Color(0.72, 0.84, 0.95)
var theme_fog := Color(0.75, 0.85, 0.95)
var theme_hill_color := Color(0.25, 0.45, 0.22)
var theme_sun_color := Color(1.0, 0.97, 0.9)

## Paleta completa a unei teme, dintr-un singur apel.
## Stil: FLAT-COLOR saturat (stilul masinilor RgsDev, extins la lume) —
## fara texturi de zgomot; culoarea si lumina fac treaba.
func apply_theme(theme: String) -> void:
	theme_decor = theme
	if theme == "desert":
		theme_ground_tint = Color(0.93, 0.76, 0.47)
		theme_sky_top = Color(0.25, 0.52, 0.92)   # albastru adanc, contrast cu nisipul
		theme_sky_horizon = Color(1.0, 0.86, 0.6)
		theme_fog = Color(0.98, 0.87, 0.68)
		theme_hill_color = Color(0.88, 0.62, 0.36)
		theme_sun_color = Color(1.0, 0.92, 0.78)
	else:
		theme_ground_tint = Color(0.45, 0.72, 0.33) # verde viu, nu pastel
		theme_sky_top = Color(0.22, 0.48, 0.9)
		theme_sky_horizon = Color(0.72, 0.87, 1.0)
		theme_fog = Color(0.78, 0.88, 0.98)
		theme_hill_color = Color(0.3, 0.56, 0.27)
		theme_sun_color = Color(1.0, 0.97, 0.88)

var curve: Curve3D
var baked: PackedVector3Array
var _dists: PackedFloat32Array # distanta cumulata pana la fiecare punct copt

# --- API pentru subclase ---

func _points() -> Array[Vector3]:
	push_error("Track: suprascrie _points() in subclasa")
	return []

## Fractii (0..1) din traseu unde apar rampe de saritura.
func _ramp_fracs() -> Array[float]:
	return []

## Fractii unde apar bariere mobile.
func _hazard_fracs() -> Array[float]:
	return []

## Fractii unde furtunul de gradina pulseaza apa peste drum.
func _hose_fracs() -> Array[float]:
	return []

func _ready() -> void:
	rebuild()

## Reconstruieste toata pista (folosit si de editor, la Regenerate).
func rebuild() -> void:
	for child in get_children():
		if child is Path3D:
			continue # curba editabila a pistelor custom ramane
		child.free()
	_build_curve()
	_build_environment()
	_build_road()
	_build_walls()
	for frac in _ramp_fracs():
		_build_ramp(frac)
	for frac in _hazard_fracs():
		_build_hazard(frac)
	for frac in _hose_fracs():
		_build_hose(frac)
	_build_pins()
	_build_start_gate()
	_build_start_line()
	_build_center_line()
	_build_kerbs()
	_build_decor()

## Linia discontinua de mijloc, din geometrie (fara texturi): placute albe
## la fiecare 6.5m de-a lungul curbei.
func _build_center_line() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var total := _dists[n]
	var lift := Vector3.UP * 0.045
	var d := 4.0
	var idx := 0
	while d < total - 5.0:
		while idx + 1 < _dists.size() and _dists[idx + 1] < d:
			idx += 1
		var i := idx % n
		var dir := (baked[(i + 1) % n] - baked[i]).normalized()
		var side := _side_at(i)
		var a := baked[i] + dir * (d - _dists[i]) + lift
		var b := a + dir * 2.8
		st.add_vertex(a - side * 0.18); st.add_vertex(a + side * 0.18)
		st.add_vertex(b - side * 0.18)
		st.add_vertex(a + side * 0.18); st.add_vertex(b + side * 0.18)
		st.add_vertex(b - side * 0.18)
		d += 6.5
	st.generate_normals()
	_add_visual_mesh(st.commit(), Color(0.92, 0.9, 0.78))

## Lumea pistei: cer, soare, teren si dealuri/dune de fundal — tematice.
func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = theme_sky_top
	sky_mat.sky_horizon_color = theme_sky_horizon
	sky_mat.ground_bottom_color = theme_fog.darkened(0.4)
	sky_mat.ground_horizon_color = theme_sky_horizon
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	# Ceata doar IN JOC: camera editorului sta la kilometri deasupra scenei
	# in vederile ortogonale, iar ceata ar acoperi totul intr-o pata uniforma.
	env.fog_enabled = not Engine.is_editor_hint()
	env.fog_light_color = theme_fog
	env.fog_density = 0.0035
	# Culorile flat au nevoie de un pic de "pop": saturatie si contrast.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.05
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.shadow_enabled = false # masinile au umbre blob (ieftin, mobil)
	sun.light_color = theme_sun_color
	sun.light_energy = 1.25
	add_child(sun)

	_build_terrain()
	var centroid := _centroid()
	var ground_body := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(2000, 1, 2000)
	ground_shape.shape = ground_box
	# ATENTIE: doar XZ din centroid — centroid.y include media dealurilor
	# si ar ridica podeaua de coliziune deasupra soselei (perete invizibil).
	ground_shape.position = Vector3(centroid.x, -0.8, centroid.z)
	ground_body.add_child(ground_shape)
	add_child(ground_body)

	# Dealuri/dune la orizont: adancime vizuala aproape gratis. Verificam
	# distanta REALA fata de sosea — centroidul nu ajunge, pista nu e rotunda.
	var rng := RandomNumberGenerator.new()
	rng.seed = track_name.hash() + 1
	var placed := 0
	var attempts := 0
	while placed < 12 and attempts < 80:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(300.0, 480.0)
		var pos := centroid + Vector3(cos(angle), 0, sin(angle)) * dist
		var radius := rng.randf_range(60.0, 140.0)
		var nearest := 1e12
		for i in range(0, baked.size(), 4):
			var dx := baked[i].x - pos.x
			var dz := baked[i].z - pos.z
			nearest = minf(nearest, dx * dx + dz * dz)
		if sqrt(nearest) < radius + 60.0:
			continue # ar intra peste sosea — cautam alt loc
		placed += 1
		var hill := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 0.5
		hill.mesh = sphere
		hill.position = Vector3(pos.x, -6.0, pos.z) # y absolut, nu din centroid
		var hill_mat := StandardMaterial3D.new()
		hill_mat.albedo_color = theme_hill_color.lightened(rng.randf_range(0.0, 0.15))
		hill.material_override = hill_mat
		add_child(hill)

func _centroid() -> Vector3:
	var sum := Vector3.ZERO
	for p in baked:
		sum += p
	return sum / float(baked.size())

## Terenul: NU un plan infinit de biliard, ci o panza cu valuri blande,
## APLATIZATA in coridorul pistei (fizica ramane plata acolo unde se
## conduce; relieful e scenografie). Variatie de culoare per varf — adanc
## = mai inchis — fara nicio textura.
func _build_terrain() -> void:
	var centroid := _centroid()
	var size := 1500.0
	var cells := 56
	var step := size / float(cells)
	var origin := centroid - Vector3(size * 0.5, 0, size * 0.5)
	var rng_phase := float(track_name.hash() % 1000) * 0.01
	# strida 3 peste punctele pistei: destul pentru distanta aproximativa
	var road_pts: Array[Vector3] = []
	for i in range(0, baked.size(), 3):
		road_pts.append(baked[i])
	var heights: Array[float] = []
	heights.resize((cells + 1) * (cells + 1))
	for gz in cells + 1:
		for gx in cells + 1:
			var wx := origin.x + float(gx) * step
			var wz := origin.z + float(gz) * step
			var h := sin(wx * 0.012 + rng_phase) * 2.2 \
				+ cos(wz * 0.014 + rng_phase * 2.0) * 2.0 \
				+ sin(wx * 0.031) * sin(wz * 0.027) * 1.3
			var nearest := 1e12
			for p in road_pts:
				var dx := p.x - wx
				var dz := p.z - wz
				nearest = minf(nearest, dx * dx + dz * dz)
			var dist := sqrt(nearest)
			# < 45m de sosea: perfect plat (unde se conduce); apoi blend.
			var t := clampf((dist - 45.0) / 70.0, 0.0, 1.0)
			heights[gz * (cells + 1) + gx] = maxf(h, -1.0) * t * t
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gz in cells:
		for gx in cells:
			var idx00 := gz * (cells + 1) + gx
			var corners := [
				Vector3(origin.x + float(gx) * step, -0.3 + heights[idx00],
					origin.z + float(gz) * step),
				Vector3(origin.x + float(gx + 1) * step, -0.3 + heights[idx00 + 1],
					origin.z + float(gz) * step),
				Vector3(origin.x + float(gx) * step,
					-0.3 + heights[idx00 + cells + 1],
					origin.z + float(gz + 1) * step),
				Vector3(origin.x + float(gx + 1) * step,
					-0.3 + heights[idx00 + cells + 2],
					origin.z + float(gz + 1) * step),
			]
			for tri in [[0, 1, 2], [1, 3, 2]]:
				for corner_idx: int in tri:
					var v: Vector3 = corners[corner_idx]
					var shade := clampf(1.0 + v.y * 0.03, 0.82, 1.12)
					st.set_color(theme_ground_tint * shade)
					st.add_vertex(v)
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	inst.material_override = mat
	add_child(inst)

## Textura incarcata doar daca exista (inainte de prima generare lipsesc).
func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func start_point() -> Vector3:
	return baked[0]

func start_direction() -> Vector3:
	return (baked[1] - baked[0]).normalized()

# -------------------------------------------------------------- constructie

func _build_curve() -> void:
	curve = Curve3D.new()
	curve.bake_interval = 3.0
	var pts := _points()
	var n := pts.size()
	for i in n + 1:
		var p := pts[i % n]
		var prev := pts[(i - 1 + n) % n]
		var next := pts[(i + 1) % n]
		var tangent := (next - prev) * 0.22
		curve.add_point(p, -tangent, tangent)
	baked = curve.get_baked_points()
	if baked.size() > 1 and baked[0].distance_to(baked[baked.size() - 1]) < 0.5:
		baked.remove_at(baked.size() - 1)
	# Distante cumulate — pentru coordonate UV continue de-a lungul soselei.
	_dists = PackedFloat32Array()
	_dists.resize(baked.size() + 1)
	_dists[0] = 0.0
	for i in baked.size():
		var j := (i + 1) % baked.size()
		_dists[i + 1] = _dists[i] + baked[i].distance_to(baked[j])

func _side_at(i: int) -> Vector3:
	var n := baked.size()
	var dir := (baked[(i + 1) % n] - baked[i]).normalized()
	return dir.cross(Vector3.UP).normalized()

func _build_road() -> void:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var down := Vector3.DOWN * ROAD_THICKNESS
	var n := baked.size()
	# UV-uri: U de-a latul soselei (0..1, banda din textura cade pe centru),
	# V de-a lungul, in "dale" de 14m — textura curge continuu cu drumul.
	var tile := 14.0
	var side_tile := 8.0
	for i in n:
		var j := (i + 1) % n
		var l0 := baked[i] - _side_at(i) * half_width
		var r0 := baked[i] + _side_at(i) * half_width
		var l1 := baked[j] - _side_at(j) * half_width
		var r1 := baked[j] + _side_at(j) * half_width
		var v0 := _dists[i] / tile
		var v1 := _dists[i + 1] / tile
		top.set_uv(Vector2(0, v0)); top.add_vertex(l0)
		top.set_uv(Vector2(1, v0)); top.add_vertex(r0)
		top.set_uv(Vector2(0, v1)); top.add_vertex(l1)
		top.set_uv(Vector2(1, v0)); top.add_vertex(r0)
		top.set_uv(Vector2(1, v1)); top.add_vertex(r1)
		top.set_uv(Vector2(0, v1)); top.add_vertex(l1)
		var u0 := _dists[i] / side_tile
		var u1 := _dists[i + 1] / side_tile
		sides.set_uv(Vector2(u0, 0)); sides.add_vertex(l0)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(l0 + down)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(l0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1)
		sides.set_uv(Vector2(u1, 1)); sides.add_vertex(l1 + down)
		sides.set_uv(Vector2(u0, 0)); sides.add_vertex(r0)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(r1)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u1, 1)); sides.add_vertex(r1 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(r1)
		sides.set_uv(Vector2(u0, 0)); sides.add_vertex(l0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1 + down)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u0, 1)); sides.add_vertex(r0 + down)
		sides.set_uv(Vector2(u1, 0)); sides.add_vertex(l1 + down)
		sides.set_uv(Vector2(u1, 1)); sides.add_vertex(r1 + down)
	top.generate_normals()
	sides.generate_normals()
	# Flat-color curat, in stilul masinilor: asfaltul racoros-inchis face
	# masinile saturate sa "sara" din ecran; flancurile in tonul temei.
	_add_mesh_with_collision(top.commit(), Color(0.23, 0.24, 0.3))
	_add_mesh_with_collision(sides.commit(), theme_hill_color.darkened(0.2))

func _build_walls() -> void:
	var loop_poly := PackedVector2Array()
	for p in _points():
		loop_poly.append(Vector2(p.x, p.z))
	var n := baked.size()
	for side_sign: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var emitted := false
		for i in n:
			var j := (i + 1) % n
			var b0 := baked[i] + _side_at(i) * half_width * side_sign
			var b1 := baked[j] + _side_at(j) * half_width * side_sign
			var mid := (b0 + b1) * 0.5
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(mid.x, mid.z), loop_poly)
			var elevated := mid.y > 1.0
			if not exterior and not elevated:
				continue
			var t0 := b0 + Vector3.UP * WALL_HEIGHT
			var t1 := b1 + Vector3.UP * WALL_HEIGHT
			st.add_vertex(b0); st.add_vertex(t0); st.add_vertex(b1)
			st.add_vertex(t0); st.add_vertex(t1); st.add_vertex(b1)
			emitted = true
		if emitted:
			st.generate_normals()
			_add_mesh_with_collision(st.commit(), Color(0.9, 0.25, 0.2))

## Rampa pe jumatatea exterioara a soselei: alegi intre linia sigura si
## saritura (airtime).
func _build_ramp(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var c := baked[idx]
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var side := _side_at(idx)
	var half_l := 7.0
	var half_w := half_width * 0.5
	var height := 2.6
	var center := c + side * half_width * 0.5
	var fl := center - dir * half_l - side * half_w
	var fr := center - dir * half_l + side * half_w
	var bl := center + dir * half_l - side * half_w + Vector3.UP * height
	var br := center + dir * half_l + side * half_w + Vector3.UP * height
	var bl_low := bl - Vector3.UP * height
	var br_low := br - Vector3.UP * height
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(fl); st.add_vertex(fr); st.add_vertex(bl)
	st.add_vertex(fr); st.add_vertex(br); st.add_vertex(bl)
	st.add_vertex(bl); st.add_vertex(br); st.add_vertex(bl_low)
	st.add_vertex(br); st.add_vertex(br_low); st.add_vertex(bl_low)
	st.add_vertex(fl); st.add_vertex(bl); st.add_vertex(bl_low)
	st.add_vertex(fr); st.add_vertex(br_low); st.add_vertex(br)
	st.generate_normals()
	_add_mesh_with_collision(st.commit(), Color(0.95, 0.6, 0.1))

func _build_hazard(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	# Hazard tematic: in desert, mingea de plaja se rostogoleste peste
	# sosea; in rest, excavatorul de jucarie coboara bratul peste o banda.
	if theme_decor == "desert" and ResourceLoader.exists(
			"res://assets/models/beach_ball.glb"):
		var ball := SlidingHazard.new()
		ball.model_scene = load("res://assets/models/beach_ball.glb")
		ball.model_scale = 0.52 # diametru 5m in model -> 2.6m in joc
		ball.roll_radius = 1.3
		add_child(ball)
		ball.center = p
		ball.travel = side * half_width * 0.9
		ball.global_position = p
	elif ResourceLoader.exists("res://assets/models/toy_excavator.glb"):
		var excavator := ExcavatorHazard.new()
		excavator.model_scene = load("res://assets/models/toy_excavator.glb")
		add_child(excavator)
		# Corpul sta PE marginea soselei (blocheaza banda exterioara),
		# bratul coboara spre centru — lasa o strecuratoare pe interior.
		var park := p + side * (half_width * 0.8)
		excavator.look_at_from_position(park, p, Vector3.UP) # bratul spre drum
	else:
		var box := SlidingHazard.new()
		add_child(box)
		box.center = p
		box.travel = side * half_width * 0.9
		box.global_position = p

func _add_mesh_with_collision(mesh: ArrayMesh, color: Color,
		texture: Texture2D = null) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if texture != null:
		mat.albedo_texture = texture
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inst.material_override = mat
	add_child(inst)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var tri := mesh.create_trimesh_shape() as ConcavePolygonShape3D
	# Trimesh-urile sunt implicit UNILATERALE; fara asta masina cade prin
	# asfalt ca printr-o plasa (winding-ul nostru e arbitrar).
	tri.backface_collision = true
	shape.shape = tri
	body.add_child(shape)
	add_child(body)

## Linia de start in sah: doua randuri de patrate alb/negru peste asfalt.
func _build_start_line() -> void:
	var white := SurfaceTool.new()
	white.begin(Mesh.PRIMITIVE_TRIANGLES)
	var black := SurfaceTool.new()
	black.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dir := start_direction()
	var side := _side_at(0)
	var cols := 8
	var cell_w := half_width * 2.0 / float(cols)
	var cell_l := 1.6
	var lift := Vector3.UP * 0.05 # putin peste asfalt, contra z-fighting
	for row in 2:
		for col in cols:
			var origin := baked[0] + lift \
				+ dir * (float(row) * cell_l) \
				+ side * (-half_width + float(col) * cell_w)
			var st := white if (row + col) % 2 == 0 else black
			var a := origin
			var b := origin + side * cell_w
			var c := origin + dir * cell_l
			var d := origin + side * cell_w + dir * cell_l
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
			st.add_vertex(b); st.add_vertex(d); st.add_vertex(c)
	white.generate_normals()
	black.generate_normals()
	_add_visual_mesh(white.commit(), Color(0.95, 0.95, 0.95))
	_add_visual_mesh(black.commit(), Color(0.08, 0.08, 0.08))

## Borduri rosu-alb pe marginile virajelor stranse — citesti pista de departe.
func _build_kerbs() -> void:
	var red := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := SurfaceTool.new()
	white.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := baked.size()
	var lift := Vector3.UP * 0.04
	var emitted_red := false
	var emitted_white := false
	for i in range(0, n, 2):
		# curbura locala: unghiul dintre directia dinainte si cea de dupa
		var before := (baked[i] - baked[(i - 3 + n) % n]).normalized()
		var after := (baked[(i + 3) % n] - baked[i]).normalized()
		if before.angle_to(after) < 0.08:
			continue
		for side_sign: float in [-1.0, 1.0]:
			var e0 := baked[i] + _side_at(i) * half_width * side_sign + lift
			var e1 := baked[(i + 2) % n] + _side_at((i + 2) % n) * half_width * side_sign + lift
			var in0 := e0 - _side_at(i) * 0.9 * side_sign
			var in1 := e1 - _side_at((i + 2) % n) * 0.9 * side_sign
			var st := red if (i / 2) % 2 == 0 else white
			st.add_vertex(e0); st.add_vertex(e1); st.add_vertex(in0)
			st.add_vertex(in0); st.add_vertex(e1); st.add_vertex(in1)
			if (i / 2) % 2 == 0:
				emitted_red = true
			else:
				emitted_white = true
	if emitted_red:
		red.generate_normals()
		_add_visual_mesh(red.commit(), Color(0.85, 0.15, 0.1))
	if emitted_white:
		white.generate_normals()
		_add_visual_mesh(white.commit(), Color(0.92, 0.92, 0.92))

## Decor de "lume de jucarie": copaci si pietre presarate procedural in
## afara soselei, deterministe per pista (acelasi seed -> acelasi peisaj).
## Trunchiurile au coliziune: un copac lovit in scurtatura e vina ta.
func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = track_name.hash()
	var bounds_min := baked[0]
	var bounds_max := baked[0]
	for p in baked:
		bounds_min = bounds_min.min(p)
		bounds_max = bounds_max.max(p)
	var placed := 0
	var attempts := 0
	while placed < 80 and attempts < 400:
		attempts += 1
		var pos := Vector3(
			rng.randf_range(bounds_min.x - 50.0, bounds_max.x + 50.0),
			0.0,
			rng.randf_range(bounds_min.z - 50.0, bounds_max.z + 50.0))
		# distanta minima (in plan) fata de sosea
		var nearest := 1e9
		for p in baked:
			nearest = minf(nearest,
				Vector2(p.x - pos.x, p.z - pos.z).length_squared())
		nearest = sqrt(nearest)
		if nearest < half_width + 8.0 or nearest > 90.0:
			continue
		placed += 1
		if theme_decor == "desert":
			var roll := rng.randf()
			if roll < 0.45:
				_add_cactus(pos, rng)
			elif roll < 0.7:
				_add_mesa(pos, rng)
			else:
				_add_dry_bush(pos, rng)
		elif rng.randf() < 0.75:
			_add_tree(pos, rng)
		else:
			_add_rock(pos, rng)

func _add_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var tree := StaticBody3D.new()
	add_child(tree)
	tree.global_position = pos + Vector3.UP * -0.3 # din iarba
	var scale_factor := rng.randf_range(0.8, 1.5)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 1.4 * scale_factor
	trunk.mesh = trunk_mesh
	trunk.position = Vector3.UP * 0.7 * scale_factor
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.45, 0.3, 0.18)
	trunk.material_override = trunk_mat
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0 # con
	crown_mesh.bottom_radius = 1.6 * scale_factor
	crown_mesh.height = 3.2 * scale_factor
	crown.mesh = crown_mesh
	crown.position = Vector3.UP * (1.4 * scale_factor + 1.6 * scale_factor)
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color(0.2, rng.randf_range(0.45, 0.65), 0.22)
	crown.material_override = crown_mat
	tree.add_child(crown)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 2.5
	shape.shape = cyl
	shape.position = Vector3.UP * 1.25
	tree.add_child(shape)

func _add_rock(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var rock := StaticBody3D.new()
	add_child(rock)
	rock.global_position = pos + Vector3.UP * -0.2
	rock.rotation.y = rng.randf_range(0.0, TAU)
	var size := rng.randf_range(0.8, 2.2)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size * 0.7, size * 0.8)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3.UP * size * 0.3
	mesh_inst.rotation.z = rng.randf_range(-0.2, 0.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.58)
	mesh_inst.material_override = mat
	rock.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(size, size, size * 0.8)
	shape.shape = col_box
	shape.position = Vector3.UP * size * 0.3
	rock.add_child(shape)

func _build_hose(frac: float) -> void:
	if not ResourceLoader.exists("res://assets/models/garden_hose.glb"):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var hose := WaterHose.new()
	hose.model_scene = load("res://assets/models/garden_hose.glb")
	hose.road_width = half_width * 2.0
	add_child(hose)
	hose.global_position = baked[idx]
	hose.global_basis = Basis.looking_at(dir, Vector3.UP) # +X = marginea din dreapta

## Popice pe marginile DESCHISE ale pistei (interior la nivelul solului,
## unde nu sunt pereti): delimitatoare fizice — stau cuminti pana le lovesti.
func _build_pins() -> void:
	if not ResourceLoader.exists("res://assets/models/bowling_pin.glb"):
		return
	var pin_scene := load("res://assets/models/bowling_pin.glb") as PackedScene
	var loop_poly := PackedVector2Array()
	for p in _points():
		loop_poly.append(Vector2(p.x, p.z))
	var n := baked.size()
	var placed := 0
	for i in range(0, n, 4): # o popica la ~12m de margine deschisa
		if placed >= 110:
			break
		for side_sign: float in [-1.0, 1.0]:
			var edge := baked[i] + _side_at(i) * half_width * side_sign
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(edge.x, edge.z), loop_poly)
			if exterior or edge.y > 1.0:
				continue # acolo sunt pereti; popicele marcheaza doar golurile
			var pin := BowlingPin.new()
			pin.model_scene = pin_scene
			add_child(pin)
			pin.global_position = edge + _side_at(i) * side_sign * 1.7 \
				+ Vector3.UP * 0.2
			placed += 1

## Cactus saguaro: trunchi + doua brate, cu coliziune pe trunchi.
func _add_cactus(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var cactus := StaticBody3D.new()
	add_child(cactus)
	cactus.global_position = pos + Vector3.UP * -0.3
	cactus.rotation.y = rng.randf_range(0.0, TAU)
	var s := rng.randf_range(0.8, 1.4)
	var green := Color(0.24, rng.randf_range(0.45, 0.58), 0.28)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.3
	trunk_mesh.bottom_radius = 0.34
	trunk_mesh.height = 2.6 * s
	trunk.mesh = trunk_mesh
	trunk.position = Vector3.UP * 1.3 * s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = green
	trunk.material_override = mat
	cactus.add_child(trunk)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := CylinderMesh.new()
		arm_mesh.top_radius = 0.18
		arm_mesh.bottom_radius = 0.18
		arm_mesh.height = 1.0 * s
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.55, rng.randf_range(1.1, 1.7) * s, 0)
		arm.rotation.z = side * 0.9 # bratul iese oblic in sus
		arm.material_override = mat
		cactus.add_child(arm)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 2.6 * s
	shape.shape = cyl
	shape.position = Vector3.UP * 1.3 * s
	cactus.add_child(shape)

## Mesa: lespezi de piatra rosiatica suprapuse, cu coliziune.
func _add_mesa(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var mesa := StaticBody3D.new()
	add_child(mesa)
	mesa.global_position = pos + Vector3.UP * -0.2
	mesa.rotation.y = rng.randf_range(0.0, TAU)
	var base := rng.randf_range(1.6, 3.6)
	var levels := 2 + (1 if rng.randf() < 0.4 else 0)
	var y := 0.0
	for level in levels:
		var frac := 1.0 - float(level) * 0.28
		var slab := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(base * frac, base * 0.4, base * 0.85 * frac)
		slab.mesh = box
		y += base * 0.2
		slab.position = Vector3.UP * y
		y += base * 0.2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.42, 0.28).lightened(float(level) * 0.08)
		slab.material_override = mat
		mesa.add_child(slab)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(base, base * 0.8, base * 0.85)
	shape.shape = col
	shape.position = Vector3.UP * base * 0.4
	mesa.add_child(shape)

## Tufa uscata: doar vizual, treci prin ea.
func _add_dry_bush(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var bush := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var r := rng.randf_range(0.4, 0.8)
	sphere.radius = r
	sphere.height = r
	bush.mesh = sphere
	bush.position = pos + Vector3.UP * (r * 0.3 - 0.3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.45, 0.25).lightened(rng.randf_range(0.0, 0.2))
	bush.material_override = mat
	add_child(bush)

## Mesh doar vizual (fara coliziune) — pentru linii de start, borduri etc.
func _add_visual_mesh(mesh: ArrayMesh, color: Color) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inst.material_override = mat
	add_child(inst)

func _build_start_gate() -> void:
	var side := _side_at(0)
	for s in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 6.0, 0.8)
		pillar.mesh = box
		pillar.position = baked[0] + side * (half_width + 0.8) * s + Vector3.UP * 3.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.9, 0.95)
		pillar.material_override = mat
		add_child(pillar)
	var bar := MeshInstance3D.new()
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3((half_width + 1.2) * 2.0, 0.7, 0.9)
	bar.mesh = bar_box
	bar.position = baked[0] + Vector3.UP * 6.0
	bar.basis = Basis.looking_at(start_direction(), Vector3.UP)
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.95, 0.55, 0.1)
	bar.material_override = bar_mat
	add_child(bar)

# ---------------------------------------------- interogari (AI + progres)

func closest_index(from_index: int, pos: Vector3) -> int:
	var n := baked.size()
	var best := ((from_index % n) + n) % n
	var best_d := pos.distance_squared_to(baked[best])
	for off in range(-8, 25):
		var idx := ((from_index + off) % n + n) % n
		var d := pos.distance_squared_to(baked[idx])
		if d < best_d:
			best_d = d
			best = idx
	return best

func closest_index_global(pos: Vector3) -> int:
	var best := 0
	var best_d := pos.distance_squared_to(baked[0])
	for i in baked.size():
		var d := pos.distance_squared_to(baked[i])
		if d < best_d:
			best_d = d
			best = i
	return best

func frac_at(index: int) -> float:
	return float(index) / float(baked.size())

func lateral_distance(index: int, pos: Vector3) -> float:
	var p := baked[index]
	return Vector2(pos.x - p.x, pos.z - p.z).length()

func is_on_road(index: int, pos: Vector3) -> bool:
	return lateral_distance(index, pos) <= half_width + 0.5

func lookahead_point(index: int, ahead_m: float, lateral_frac: float) -> Vector3:
	var n := baked.size()
	var steps := int(ahead_m / curve.bake_interval)
	var idx := ((index + steps) % n + n) % n
	return baked[idx] + _side_at(idx) * lateral_frac * half_width

func spawn_transforms(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var n := baked.size()
	for i in count:
		var back_m := 8.0 + float(i / 2) * 8.0
		var idx := ((n - int(back_m / curve.bake_interval)) % n + n) % n
		var side := (-1.0 if i % 2 == 0 else 1.0) * half_width * 0.4
		var pos := baked[idx] + _side_at(idx) * side + Vector3.UP * 0.5
		var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
		result.append(Transform3D(Basis.looking_at(dir, Vector3.UP), pos))
	return result
