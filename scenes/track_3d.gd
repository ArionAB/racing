class_name Track3D
extends Node3D
## Pista 3D generata din puncte de control — aceeasi idee ca in racing 2D,
## dar cu inaltime (Y). Din Curve3D coacem puncte dese, apoi "extrudam" o
## panglica de triunghiuri pentru asfalt si doua benzi verticale pt pereti.
## Coliziunile sunt trimesh (ConcavePolygonShape3D) generate din acelasi mesh.

const HALF_WIDTH: float = 7.0
const WALL_HEIGHT: float = 1.3
## Grosimea "digului" de sosea. Un mesh fara grosime (foaie de hartie) lasa
## masina sa treaca prin el la viteza: cand cutia de coliziune patrunde putin
## prin suprafata, depenetrarea o poate impinge pe partea GRESITA (sub drum).
## Cu volum solid, cea mai apropiata iesire e mereu inapoi in sus.
const ROAD_THICKNESS: float = 3.0

## Punctele de control: (x, inaltime, z). Modifica-le si vezi pe viu cat
## costa design-ul de pista 3D — asta e una din intrebarile spike-ului.
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
	_build_start_gate()

func start_point() -> Vector3:
	return baked[0]

func start_direction() -> Vector3:
	return (baked[1] - baked[0]).normalized()

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

## Soseaua ca volum solid ("dig"): asfaltul deasupra, plus flancuri si talpa
## coborate cu ROAD_THICKNESS. SurfaceTool e "modul manual" de a construi
## mesh-uri, triunghi cu triunghi.
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
		# asfaltul
		top.add_vertex(l0); top.add_vertex(r0); top.add_vertex(l1)
		top.add_vertex(r0); top.add_vertex(r1); top.add_vertex(l1)
		# flancul stang
		sides.add_vertex(l0); sides.add_vertex(l1); sides.add_vertex(l0 + down)
		sides.add_vertex(l0 + down); sides.add_vertex(l1); sides.add_vertex(l1 + down)
		# flancul drept
		sides.add_vertex(r0); sides.add_vertex(r0 + down); sides.add_vertex(r1)
		sides.add_vertex(r0 + down); sides.add_vertex(r1 + down); sides.add_vertex(r1)
		# talpa
		sides.add_vertex(l0 + down); sides.add_vertex(l1 + down); sides.add_vertex(r0 + down)
		sides.add_vertex(r0 + down); sides.add_vertex(l1 + down); sides.add_vertex(r1 + down)
	top.generate_normals()
	sides.generate_normals()
	_add_mesh_with_collision(top.commit(), Color(0.24, 0.24, 0.28))
	_add_mesh_with_collision(sides.commit(), Color(0.5, 0.45, 0.4)) # beton

func _build_walls() -> void:
	for side_sign: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := baked.size()
		for i in n:
			var j := (i + 1) % n
			var b0 := baked[i] + _side_at(i) * HALF_WIDTH * side_sign
			var b1 := baked[j] + _side_at(j) * HALF_WIDTH * side_sign
			var t0 := b0 + Vector3.UP * WALL_HEIGHT
			var t1 := b1 + Vector3.UP * WALL_HEIGHT
			st.add_vertex(b0); st.add_vertex(t0); st.add_vertex(b1)
			st.add_vertex(t0); st.add_vertex(t1); st.add_vertex(b1)
		st.generate_normals()
		_add_mesh_with_collision(st.commit(), Color(0.9, 0.25, 0.2))

func _add_mesh_with_collision(mesh: ArrayMesh, color: Color) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	# Fara culling: panglica se vede din orice parte, indiferent de ordinea
	# in care am emis triunghiurile (pentru un spike, simplitate > perf).
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

## Poarta de start: doi stalpi + o bara — reperul vizual al liniei de finish.
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
