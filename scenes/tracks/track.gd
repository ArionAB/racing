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

## Creasta de fly-off: urcare cu panta CRESCATOARE care se termina intr-o
## muchie (nu un cocoas lin — vezi FlyoffKicker pentru de ce).
const FLYOFF_RISE_LEN: float = 12.0
const FLYOFF_HEIGHT: float = 2.8
## Latura amprentei in care se cauta masini care au ratat aterizarea.
const FLYOFF_NET_EXTENT: float = 130.0

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
## Sursa unica de sloturi pentru tot ce se aseaza langa drum (faleze, decor).
## Se reconstruieste la fiecare rebuild(), dupa ce curba e coapta.
var _sampler: TrackSideSampler

## Materiale flat, refolosite pe culoare. Fara cache-ul asta fiecare mesh
## procedural isi facea propriul StandardMaterial3D — masurat cu
## tools/probe_decor.gd pe Dunele: 76 mesh-uri -> 72 materiale, adica tot atatea
## draw call-uri, exact ce nu ne permitem pe mobil (CLAUDE.md, constrangeri 3D).
## Se goleste la fiecare rebuild(), ca schimbarea de tema sa nu lase gunoi.
var _mat_cache: Dictionary = {}

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

## Excavatoare suplimentare, explicite (pe langa hazardul tematic).
func _excavator_fracs() -> Array[float]:
	return []

## Dinozauri-landmark: (fractie, parte) — plasati cu intentie, nu aleator.
func _dino_spots() -> Array[Vector2]:
	return []

## Landmark-uri hero (turn de apa, benzinarie, moara, semn): fiecare
## (fractie, parte ±1, id-model din _LANDMARKS) — plasate cu intentie.
func _landmark_spots() -> Array[Vector3]:
	return []

## Carusele: moristi uriase cu vane care MATURA soseaua (gimmick de timing).
func _carousel_fracs() -> Array[float]:
	return []

## Deviatoare: bariere oblice care iti schimba traiectoria (gimmick de linie).
func _deflector_fracs() -> Array[float]:
	return []

## Creste de fly-off: te arunca in aer inaintea unui viraj; ratezi aterizarea
## si ajungi in nisipul de sub sosea, de unde te repune un RespawnZone.
func _flyoff_fracs() -> Array[float]:
	return []

func _ready() -> void:
	rebuild()

## Reconstruieste toata pista (folosit si de editor, la Regenerate).
func rebuild() -> void:
	_mat_cache.clear() # altfel raman materialele temei precedente
	for child in get_children():
		if child is Path3D:
			continue # curba editabila a pistelor custom ramane
		child.free()
	_build_curve()
	# Dupa coacerea curbei, inainte de orice generator care aseaza ceva langa
	# drum: toti citesc sloturi de aici.
	_sampler = TrackSideSampler.new(baked, _dists, _points(), half_width)
	_build_environment()
	_build_road()
	_build_walls()
	for frac in _ramp_fracs():
		_build_ramp(frac)
	for frac in _hazard_fracs():
		_build_hazard(frac)
	for frac in _excavator_fracs():
		_build_excavator(frac)
	for spot in _dino_spots():
		_build_dino(spot.x, spot.y)
	for spot in _landmark_spots():
		_build_landmark(spot.x, spot.y, int(spot.z))
	for frac in _hose_fracs():
		_build_hose(frac)
	for frac in _flyoff_fracs():
		_build_flyoff(frac)
	for frac in _deflector_fracs():
		_build_deflector(frac)
	for frac in _carousel_fracs():
		_build_carousel(frac)
	_build_pins()
	_build_start_gate()
	_build_start_line()
	_build_center_line()
	_build_kerbs()
	_build_world_decor()
	_build_world_bounds()

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
		var radius := rng.randf_range(60.0, 140.0)
		# Rama de scanduri de la 380m a disparut odata cu tema de lada de nisip,
		# deci dealurile nu mai sunt stranse intr-un patrat inexistent.
		var dist := rng.randf_range(240.0, 480.0)
		var pos := centroid + Vector3(cos(angle), 0, sin(angle)) * dist
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
		# nuanta in 4 trepte, nu continua: dealurile de fundal impart 4 materiale
		var tint := float(rng.randi_range(0, 3)) / 3.0 * 0.15
		hill.material_override = _flat_material(theme_hill_color.lightened(tint))
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
		# Noi ii cerem maturarea maxima; el isi taie cursa cat sa nu iasa din
		# sosea pe latimea ASTA de drum (vezi SlidingHazard._clamp_travel).
		ball.road_half_width = half_width
		ball.phase = fposmod(frac * 3.7, 1.0) # doua obstacole nu bat la unison
		add_child(ball)
		ball.center = p
		ball.travel = side * half_width * 0.9
		ball.global_position = p
	elif ResourceLoader.exists("res://assets/models/toy_excavator.glb"):
		_build_excavator(frac)
	else:
		var box := SlidingHazard.new()
		box.road_half_width = half_width
		box.phase = fposmod(frac * 3.7, 1.0)
		add_child(box)
		box.center = p
		box.travel = side * half_width * 0.9
		box.global_position = p

## Caruselul: morisca plantata in mijlocul soselei, cu vane care matura toata
## latimea. Vanele stau sub half_width ca sa nu treaca prin pereti.
##
## ATENTIE la ordine: transformarea se pune INAINTE de add_child. Rotorul e un
## AnimatableBody3D cu sync_to_physics, deci transformarea lui o tine serverul
## de fizica — plasat dupa intrarea in arbore, ramane un pas fizic in origine,
## adica exact peste grila de start, si matura tot plutonul la countdown.
func _build_carousel(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var carousel := CarouselHazard.new()
	carousel.arm_reach = half_width - 0.2
	carousel.position = baked[idx]
	add_child(carousel)

## Deviatorul: bariera oblica ancorata pe o margine, care taie drumul in
## diagonala si te trimite pe cealalta banda.
func _build_deflector(frac: float, side_sign: float = 1.0) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var deflector := DeflectorHazard.new()
	deflector.road_half_width = half_width
	deflector.side_sign = side_sign
	# looking_at: -Z pe sensul cursei, deci +X = marginea din dreapta.
	deflector.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), baked[idx])
	add_child(deflector)

## Zona de fly-off: o CREASTA peste toata latimea soselei, pusa inaintea unui
## viraj. Nu are linie sigura — aici sare toata pista, alegerea e cat de tare
## intri: prea incet si doar treci peste, prea tare si zbori pe langa viraj,
## in nisipul de dedesubt (de unde te repune plasa de siguranta).
func _build_flyoff(frac: float) -> void:
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var spacing := _dists[n] / float(n)
	var steps := maxi(2, int(FLYOFF_RISE_LEN / spacing))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in steps:
		var i := (idx + k) % n
		var j := (idx + k + 1) % n
		# exponent > 1 = panta creste spre buza (rampa de trambulina, nu cocoas)
		var h0 := FLYOFF_HEIGHT * pow(float(k) / float(steps), 1.35)
		var h1 := FLYOFF_HEIGHT * pow(float(k + 1) / float(steps), 1.35)
		var s0 := _side_at(i) * half_width
		var s1 := _side_at(j) * half_width
		var l0 := baked[i] - s0 + Vector3.UP * h0
		var r0 := baked[i] + s0 + Vector3.UP * h0
		var l1 := baked[j] - s1 + Vector3.UP * h1
		var r1 := baked[j] + s1 + Vector3.UP * h1
		# fata de rulare
		st.add_vertex(l0); st.add_vertex(r0); st.add_vertex(l1)
		st.add_vertex(r0); st.add_vertex(r1); st.add_vertex(l1)
		# flancurile, coborate pe asfalt — altfel creasta se vede pe dedesubt
		for pair: Array in [[l0, l1, -s0, -s1], [r0, r1, s0, s1]]:
			var b0: Vector3 = baked[i] + (pair[2] as Vector3)
			var b1: Vector3 = baked[j] + (pair[3] as Vector3)
			st.add_vertex(pair[0]); st.add_vertex(b0); st.add_vertex(pair[1])
			st.add_vertex(b0); st.add_vertex(b1); st.add_vertex(pair[1])
	# Buza: cadere VERTICALA pana la asfalt, ca la rampele pistei. Cu o
	# coborare lina masina ar ramane lipita de panta (floor snap) si creasta ar
	# fi doar o denivelare — desprinderea trebuie sa fie o muchie.
	var last := (idx + steps) % n
	var sl := _side_at(last) * half_width
	var lip_l := baked[last] - sl
	var lip_r := baked[last] + sl
	var top_l := lip_l + Vector3.UP * FLYOFF_HEIGHT
	var top_r := lip_r + Vector3.UP * FLYOFF_HEIGHT
	st.add_vertex(top_l); st.add_vertex(top_r); st.add_vertex(lip_l)
	st.add_vertex(top_r); st.add_vertex(lip_r); st.add_vertex(lip_l)
	st.generate_normals()
	# Portocaliul rampelor: jucatorul stie deja ca portocaliu = sari.
	_add_mesh_with_collision(st.commit(), Color(0.95, 0.6, 0.1))
	_build_flyoff_kicker(last)
	_build_flyoff_net(idx)

## Cutia de pe buza crestei care da viteza verticala (vezi FlyoffKicker: panta
## singura nu ridica un CharacterBody3D).
func _build_flyoff_kicker(idx: int) -> void:
	var n := baked.size()
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var kicker := FlyoffKicker.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_width * 2.0, 2.6, 3.0)
	shape.shape = box
	kicker.add_child(shape)
	kicker.transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		baked[idx] - dir * 1.2 + Vector3.UP * (FLYOFF_HEIGHT + 0.9))
	add_child(kicker)

## Plasa de siguranta a unei creste: un volum plat de nisip, mult SUB sosea,
## in jurul zonei de aterizare. Plafonul se calculeaza din cea mai joasa
## bucata de sosea aflata in amprenta, minus o marja — asa nu poate prinde pe
## cineva care conduce normal, indiferent de forma pistei.
func _build_flyoff_net(idx: int) -> void:
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	var center := baked[(idx + int(40.0 / spacing)) % n]
	var half_extent := FLYOFF_NET_EXTENT * 0.5
	var lowest_road := 1e9
	for i in n:
		if absf(baked[i].x - center.x) <= half_extent \
				and absf(baked[i].z - center.z) <= half_extent:
			lowest_road = minf(lowest_road, baked[i].y)
	var top := lowest_road - 5.0
	var bottom := -25.0
	var zone := RespawnZone.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FLYOFF_NET_EXTENT, top - bottom, FLYOFF_NET_EXTENT)
	shape.shape = box
	zone.add_child(shape)
	zone.position = Vector3(center.x, (top + bottom) * 0.5, center.z)
	add_child(zone)

## Materialul flat pentru o culoare (si optional o textura), refolosit intre
## apeluri. Doua mesh-uri de aceeasi culoare = acelasi material = un draw call
## in loc de doua. De aceea variatiile aleatoare de nuanta sunt CUANTIFICATE in
## cateva trepte peste tot: o nuanta continua per instanta ar face cache-ul inutil.
func _flat_material(color: Color, texture: Texture2D = null) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(true),
		texture.resource_path if texture != null else ""]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if texture != null:
		mat.albedo_texture = texture
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache[key] = mat
	return mat


func _add_mesh_with_collision(mesh: ArrayMesh, color: Color,
		texture: Texture2D = null) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _flat_material(color, texture)
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

## Lumea din jurul soselei: peretii de canion si decorul imprastiat.
##
## Amandoua traiesc in fisiere separate ([TrackCliffs], [TrackDecor]) si cer
## sloturi de la [member _sampler]. Motivul e la fel de mult organizatoric cat
## tehnic: track.gd e fisierul pe care il atinge toata lumea, iar decorul e
## partea care se itereaza cel mai des.
func _build_world_decor() -> void:
	add_child(TrackCliffs.build(_sampler, theme_decor, track_name.hash(),
		_landmark_spots()))
	add_child(TrackDecor.build(_sampler, theme_decor, track_name.hash(),
		Callable(self, "_flat_material")))

func _build_excavator(frac: float) -> void:
	if not ResourceLoader.exists("res://assets/models/toy_excavator.glb"):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var dir := (baked[(idx + 1) % n] - p).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var excavator := ExcavatorHazard.new()
	excavator.model_scene = load("res://assets/models/toy_excavator.glb")
	add_child(excavator)
	# Corpul sta PE marginea soselei (blocheaza banda exterioara),
	# bratul coboara spre centru — lasa o strecuratoare pe interior.
	var park := p + side * (half_width * 0.8)
	excavator.look_at_from_position(park, p, Vector3.UP) # bratul spre drum

## Dinozaurul de plastic: landmark care "priveste" cursa de pe margine.
func _build_dino(frac: float, side_sign: float) -> void:
	if not ResourceLoader.exists("res://assets/models/toy_dino.glb"):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * side_sign
	var dino := StaticBody3D.new()
	dino.add_to_group("dinos")
	var model := (load("res://assets/models/toy_dino.glb") as PackedScene) \
		.instantiate() as Node3D
	dino.add_child(model)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.3
	cyl.height = 5.5
	shape.shape = cyl
	shape.position = Vector3.UP * 2.75
	dino.add_child(shape)
	add_child(dino)
	var stand := p + side * (half_width + 6.0)
	stand.y = maxf(p.y - 0.3, -0.3) # la nivelul solului de langa drum
	dino.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)

## Tabel de landmark-uri hero. id -> model GLB + cum se aseaza:
##   gap    = cat de departe de marginea soselei sta (m)
##   col    = forma de coliziune ("cyl" / "box" / "none")
##   spin   = primeste scriptul windmill.gd (roata "Blades" care se invarte)
## Dimensiunile vin din docs/asset_briefs/ (origine la baza, scara 1:1 m).
const _LANDMARKS := {
	0: {"path": "res://assets/models/water_tower.glb",
		"gap": 10.0, "col": "cyl", "radius": 2.4, "height": 9.5, "spin": false},
	1: {"path": "res://assets/models/gas_station.glb",
		"gap": 9.0, "col": "box", "size": Vector3(8.0, 5.0, 6.0), "spin": false},
	2: {"path": "res://assets/models/windmill.glb",
		"gap": 11.0, "col": "cyl", "radius": 1.6, "height": 9.0, "spin": true},
	3: {"path": "res://assets/models/route66_sign.glb",
		"gap": 3.5, "col": "none", "spin": false},
}

## Prop "hero" asezat cu intentie pe marginea pistei, ca reper vizual
## (style_bible §7: landmark dominant la cateva secunde; NICIODATA inalt in
## apexul virajului). Turnul de apa/moara stau retrase, cu coliziune; semnul
## e doar vizual. Moara primeste windmill.gd ca sa i se invarta roata.
func _build_landmark(frac: float, side_sign: float, id: int) -> void:
	if not _LANDMARKS.has(id):
		return
	var info: Dictionary = _LANDMARKS[id]
	var path: String = info["path"]
	if not ResourceLoader.exists(path):
		return
	var n := baked.size()
	var idx := int(frac * float(n)) % n
	var p := baked[idx]
	var side := _side_at(idx) * side_sign
	var model := (load(path) as PackedScene).instantiate() as Node3D
	if info["spin"]:
		model.set_script(load("res://scenes/props/windmill.gd"))
	var root: Node3D
	if info["col"] == "none":
		root = Node3D.new()
	else:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		if info["col"] == "box":
			var box := BoxShape3D.new()
			box.size = info["size"]
			shape.shape = box
			shape.position = Vector3.UP * (info["size"].y * 0.5)
		else: # "cyl"
			var cyl := CylinderShape3D.new()
			cyl.radius = info["radius"]
			cyl.height = info["height"]
			shape.shape = cyl
			shape.position = Vector3.UP * (info["height"] * 0.5)
		body.add_child(shape)
		root = body
	root.add_to_group("landmarks")
	root.add_child(model)
	add_child(root)
	# Atlasul comun pe tot subarborele (fara el, GLB-ul iese alb). Moara si-l
	# aplica singura in _ready, dar celelalte prop-uri il primesc aici.
	Palette.apply_world_material(root)
	var stand := p + side * (half_width + float(info["gap"]))
	stand.y = maxf(p.y - 0.3, -0.3) # la nivelul solului de langa drum
	root.look_at_from_position(stand, Vector3(p.x, stand.y, p.z), Vector3.UP)

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

## Marginea LUMII: patru pereti INVIZIBILI care opresc masina sa iasa din
## harta. Inainte era rama de scanduri a unei lazi de nisip (tema "jucarii in
## sandbox"); tema desert a devenit canion, iar o rama de placaj la 380m
## contrazicea direct citirea. Coliziunea ramane — doar decorul dispare.
## Bariera sta DINCOLO de silueta de la orizont, ca sa nu se loveasca de ea
## nimeni in mod normal: e plasa de siguranta, nu element de pista.
func _build_world_bounds() -> void:
	var centroid := _centroid()
	var half_extent := 420.0
	for side_idx in 4:
		var outward := [Vector3(0, 0, -1), Vector3(1, 0, 0),
			Vector3(0, 0, 1), Vector3(-1, 0, 0)][side_idx] as Vector3
		var wall := StaticBody3D.new()
		wall.add_to_group("world_bounds")
		add_child(wall)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var span := half_extent * 2.0 + 40.0
		box.size = Vector3(span, 30.0, 2.0) if absf(outward.z) > 0.5 \
			else Vector3(2.0, 30.0, span)
		shape.shape = box
		shape.position = Vector3(centroid.x, 14.0, centroid.z) \
			+ outward * half_extent
		wall.add_child(shape)

## Mesh doar vizual (fara coliziune) — pentru linii de start, borduri etc.
func _add_visual_mesh(mesh: ArrayMesh, color: Color) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _flat_material(color)
	add_child(inst)

func _build_start_gate() -> void:
	# Arcada de start din Blender, scalata pe latimea pistei; picioarele
	# au coliziune. Fallback pe stalpii procedurali daca lipseste modelul.
	if ResourceLoader.exists("res://assets/models/start_arch.glb"):
		var target_width := (half_width + 1.2) * 2.0
		var s := target_width / 22.8 # latimea masurata a modelului
		var gate := StaticBody3D.new()
		gate.add_to_group("start_arch")
		var model := (load("res://assets/models/start_arch.glb") as PackedScene) \
			.instantiate() as Node3D
		model.scale = Vector3.ONE * s
		gate.add_child(model)
		for sx: float in [-1.0, 1.0]:
			var pillar := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(1.4, 8.7 * s, 1.6)
			pillar.shape = box
			pillar.position = Vector3(sx * (target_width * 0.5 - 0.9),
				8.7 * s * 0.5, 0)
			gate.add_child(pillar)
		add_child(gate)
		gate.global_position = baked[0]
		gate.global_basis = Basis.looking_at(start_direction(), Vector3.UP)
		return
	var side := _side_at(0)
	for s in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 6.0, 0.8)
		pillar.mesh = box
		pillar.position = baked[0] + side * (half_width + 0.8) * s + Vector3.UP * 3.0
		pillar.material_override = _flat_material(Color(0.9, 0.9, 0.95))
		add_child(pillar)
	var bar := MeshInstance3D.new()
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3((half_width + 1.2) * 2.0, 0.7, 0.9)
	bar.mesh = bar_box
	bar.position = baked[0] + Vector3.UP * 6.0
	bar.basis = Basis.looking_at(start_direction(), Vector3.UP)
	bar.material_override = _flat_material(Color(0.95, 0.55, 0.1))
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

## Punctul de repunere pe pista: centrul soselei cu `backoff_m` metri INAINTE
## de checkpoint-ul dat, orientat in sensul cursei. Retragerea da spatiu de
## elan — repus exact pe buza crestei, ai cadea din nou, iar bucla aia ar
## bloca cursa (exact ce nu vrem).
func recovery_transform(index: int, backoff_m: float) -> Transform3D:
	var n := baked.size()
	var spacing := _dists[n] / float(n)
	var idx := ((index - int(backoff_m / spacing)) % n + n) % n
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	return Transform3D(Basis.looking_at(dir, Vector3.UP),
		baked[idx] + Vector3.UP * 1.2)

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
