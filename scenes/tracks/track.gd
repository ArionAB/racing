class_name Track
extends Node3D
## Generator de pista 3D din puncte de control. O pista noua = o subclasa
## care da alte puncte + fractiile pentru rampe/hazarde — atat.
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

var curve: Curve3D
var baked: PackedVector3Array

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

func _ready() -> void:
	_build_curve()
	_build_road()
	_build_walls()
	for frac in _ramp_fracs():
		_build_ramp(frac)
	for frac in _hazard_fracs():
		_build_hazard(frac)
	_build_start_gate()
	_build_start_line()
	_build_kerbs()
	_build_decor()

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
	for i in n:
		var j := (i + 1) % n
		var l0 := baked[i] - _side_at(i) * half_width
		var r0 := baked[i] + _side_at(i) * half_width
		var l1 := baked[j] - _side_at(j) * half_width
		var r1 := baked[j] + _side_at(j) * half_width
		top.add_vertex(l0); top.add_vertex(r0); top.add_vertex(l1)
		top.add_vertex(r0); top.add_vertex(r1); top.add_vertex(l1)
		sides.add_vertex(l0); sides.add_vertex(l1); sides.add_vertex(l0 + down)
		sides.add_vertex(l0 + down); sides.add_vertex(l1); sides.add_vertex(l1 + down)
		sides.add_vertex(r0); sides.add_vertex(r0 + down); sides.add_vertex(r1)
		sides.add_vertex(r0 + down); sides.add_vertex(r1 + down); sides.add_vertex(r1)
		sides.add_vertex(l0 + down); sides.add_vertex(l1 + down); sides.add_vertex(r0 + down)
		sides.add_vertex(r0 + down); sides.add_vertex(l1 + down); sides.add_vertex(r1 + down)
	top.generate_normals()
	sides.generate_normals()
	_add_mesh_with_collision(top.commit(), Color(0.24, 0.24, 0.28))
	_add_mesh_with_collision(sides.commit(), Color(0.5, 0.45, 0.4))

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
	var hazard := SlidingHazard.new()
	add_child(hazard)
	hazard.center = p
	hazard.travel = side * half_width * 0.9
	hazard.global_position = p

func _add_mesh_with_collision(mesh: ArrayMesh, color: Color) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
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
		if rng.randf() < 0.75:
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
