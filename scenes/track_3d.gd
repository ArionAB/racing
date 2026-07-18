class_name Track3D
extends Node3D
## Pista 3D generata din puncte de control — aceeasi idee ca in racing 2D,
## dar cu inaltime (Y). Din Curve3D coacem puncte dese, apoi "extrudam" un
## dig solid pentru sosea si benzi pentru pereti.
##
## Filosofia peretilor (stil Ignition/Micro Machines):
## - pe EXTERIORUL circuitului: gard peste tot (sa nu evadezi de pe harta)
## - pe INTERIOR: gard doar unde soseaua e inaltata (sa nu cazi de pe dig);
##   la nivelul solului interiorul e deschis -> scurtaturi prin iarba, care
##   e lenta (vezi SpikeCar) = risc/recompensa gratuit, fara geometrie noua.

const HALF_WIDTH: float = 7.0
const WALL_HEIGHT: float = 1.3
## Grosimea "digului" de sosea. Un mesh fara grosime (foaie de hartie) lasa
## masina sa treaca prin el la viteza; cu volum solid, cea mai apropiata
## iesire din penetrare e mereu inapoi in sus.
const ROAD_THICKNESS: float = 3.0

## Punctele de control: (x, inaltime, z).
const POINTS: Array[Vector3] = [
	Vector3(0, 0, 0),        # start/finish, mers spre +X
	Vector3(80, 0, 0),
	Vector3(150, 2, -10),
	Vector3(210, 7, -40),    # urcare pe deal
	Vector3(240, 9, -95),    # creasta
	Vector3(215, 5, -150),   # coborare in viraj — cel mai "3D" moment
	Vector3(155, 1, -180),
	Vector3(80, 0, -200),
	Vector3(0, 4, -190),     # al doilea deal, mai abrupt
	Vector3(-70, 6, -150),
	Vector3(-110, 2, -85),
	Vector3(-88, 0, -28),
	Vector3(-40, 0, -6),
]

var curve: Curve3D
var baked: PackedVector3Array

func _ready() -> void:
	_build_curve()
	_build_road()
	_build_walls()
	_build_ramp()
	_build_start_gate()

func start_point() -> Vector3:
	return baked[0]

func start_direction() -> Vector3:
	return (baked[1] - baked[0]).normalized()

# -------------------------------------------------------------- constructie

func _build_curve() -> void:
	curve = Curve3D.new()
	curve.bake_interval = 3.0
	var n := POINTS.size()
	for i in n + 1:
		var p := POINTS[i % n]
		var prev := POINTS[(i - 1 + n) % n]
		var next := POINTS[(i + 1) % n]
		var tangent := (next - prev) * 0.22
		curve.add_point(p, -tangent, tangent)
	baked = curve.get_baked_points()
	if baked.size() > 1 and baked[0].distance_to(baked[baked.size() - 1]) < 0.5:
		baked.remove_at(baked.size() - 1)

func _side_at(i: int) -> Vector3:
	var n := baked.size()
	var dir := (baked[(i + 1) % n] - baked[i]).normalized()
	return dir.cross(Vector3.UP).normalized()

## Soseaua ca volum solid ("dig"): asfaltul deasupra, plus flancuri si talpa.
func _build_road() -> void:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var down := Vector3.DOWN * ROAD_THICKNESS
	var n := baked.size()
	for i in n:
		var j := (i + 1) % n
		var l0 := baked[i] - _side_at(i) * HALF_WIDTH
		var r0 := baked[i] + _side_at(i) * HALF_WIDTH
		var l1 := baked[j] - _side_at(j) * HALF_WIDTH
		var r1 := baked[j] + _side_at(j) * HALF_WIDTH
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
	_add_mesh_with_collision(sides.commit(), Color(0.5, 0.45, 0.4)) # beton

func _build_walls() -> void:
	# Conturul circuitului in plan (XZ), pentru testul interior/exterior.
	var loop_poly := PackedVector2Array()
	for p in POINTS:
		loop_poly.append(Vector2(p.x, p.z))
	var n := baked.size()
	for side_sign: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var emitted := false
		for i in n:
			var j := (i + 1) % n
			var b0 := baked[i] + _side_at(i) * HALF_WIDTH * side_sign
			var b1 := baked[j] + _side_at(j) * HALF_WIDTH * side_sign
			var mid := (b0 + b1) * 0.5
			var exterior := not Geometry2D.is_point_in_polygon(
				Vector2(mid.x, mid.z), loop_poly)
			var elevated := mid.y > 1.0 # soseaua e sus fata de iarba (-0.3)
			if not exterior and not elevated:
				continue # interior la nivelul solului: deschis (scurtatura)
			var t0 := b0 + Vector3.UP * WALL_HEIGHT
			var t1 := b1 + Vector3.UP * WALL_HEIGHT
			st.add_vertex(b0); st.add_vertex(t0); st.add_vertex(b1)
			st.add_vertex(t0); st.add_vertex(t1); st.add_vertex(b1)
			emitted = true
		if emitted:
			st.generate_normals()
			_add_mesh_with_collision(st.commit(), Color(0.9, 0.25, 0.2))

## Rampa de saritura pe dreapta lunga de start, doar pe jumatatea din afara:
## alegi intre linia sigura si saritura (airtime = distractia Ignition).
func _build_ramp() -> void:
	var n := baked.size()
	var idx := int(0.055 * float(n))
	var c := baked[idx]
	var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
	var side := _side_at(idx)
	var half_l := 7.0   # jumatate din lungimea rampei
	var half_w := HALF_WIDTH * 0.5
	var height := 2.6
	# Rampa ocupa jumatatea "exterioara" (side +1) a soselei.
	var center := c + side * HALF_WIDTH * 0.5
	var fl := center - dir * half_l - side * half_w
	var fr := center - dir * half_l + side * half_w
	var bl := center + dir * half_l - side * half_w + Vector3.UP * height
	var br := center + dir * half_l + side * half_w + Vector3.UP * height
	var bl_low := bl - Vector3.UP * height
	var br_low := br - Vector3.UP * height
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# panta
	st.add_vertex(fl); st.add_vertex(fr); st.add_vertex(bl)
	st.add_vertex(fr); st.add_vertex(br); st.add_vertex(bl)
	# spatele vertical
	st.add_vertex(bl); st.add_vertex(br); st.add_vertex(bl_low)
	st.add_vertex(br); st.add_vertex(br_low); st.add_vertex(bl_low)
	# lateralele
	st.add_vertex(fl); st.add_vertex(bl); st.add_vertex(bl_low)
	st.add_vertex(fr); st.add_vertex(br_low); st.add_vertex(br)
	st.generate_normals()
	_add_mesh_with_collision(st.commit(), Color(0.95, 0.6, 0.1))

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
	# Coliziunile trimesh sunt implicit UNILATERALE (doar pe fata data de
	# ordinea varfurilor). Triunghiurile noastre au winding arbitrar, deci
	# fara asta masina cade prin asfalt ca printr-o plasa.
	tri.backface_collision = true
	shape.shape = tri
	body.add_child(shape)
	add_child(body)

func _build_start_gate() -> void:
	var side := _side_at(0)
	for s in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 6.0, 0.8)
		pillar.mesh = box
		pillar.position = baked[0] + side * (HALF_WIDTH + 0.8) * s + Vector3.UP * 3.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.9, 0.95)
		pillar.material_override = mat
		add_child(pillar)
	var bar := MeshInstance3D.new()
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3((HALF_WIDTH + 1.2) * 2.0, 0.7, 0.9)
	bar.mesh = bar_box
	bar.position = baked[0] + Vector3.UP * 6.0
	bar.basis = Basis.looking_at(start_direction(), Vector3.UP)
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.95, 0.55, 0.1)
	bar.material_override = bar_mat
	add_child(bar)

# ---------------------------------------------- interogari (AI + progres)

## Cautare locala in jurul ultimului index cunoscut — O(fereastra), nu O(n).
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

## Distanta laterala (in plan XZ) fata de centrul soselei la indexul dat.
func lateral_distance(index: int, pos: Vector3) -> float:
	var p := baked[index]
	return Vector2(pos.x - p.x, pos.z - p.z).length()

func is_on_road(index: int, pos: Vector3) -> bool:
	return lateral_distance(index, pos) <= HALF_WIDTH + 0.5

func lookahead_point(index: int, ahead_m: float, lateral_frac: float) -> Vector3:
	var n := baked.size()
	var steps := int(ahead_m / curve.bake_interval)
	var idx := ((index + steps) % n + n) % n
	return baked[idx] + _side_at(idx) * lateral_frac * HALF_WIDTH

## Grila de start: pozitii in spatele liniei, pe doua coloane.
func spawn_transforms(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var n := baked.size()
	for i in count:
		var back_m := 8.0 + float(i / 2) * 8.0
		var idx := ((n - int(back_m / curve.bake_interval)) % n + n) % n
		var side := (-1.0 if i % 2 == 0 else 1.0) * HALF_WIDTH * 0.4
		var pos := baked[idx] + _side_at(idx) * side + Vector3.UP * 0.5
		var dir := (baked[(idx + 1) % n] - baked[idx]).normalized()
		result.append(Transform3D(Basis.looking_at(dir, Vector3.UP), pos))
	return result
