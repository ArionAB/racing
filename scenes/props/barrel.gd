@tool
class_name Barrel
extends StaticBody3D
## Butoi de metal ruginit — primul prop pe pipeline-ul "diorama": geometrie cu
## nervuri, UV catre slotul de paleta (fara textura proprie) si AO copt in vertex
## colors. Foloseste materialul UNIC al lumii (Palette.world_material) -> se
## grupeaza cu toate celelalte prop-uri in foarte putine draw call-uri.
##
## Asezare de mana: pune noduri Barrel sub containerul "ManualDecor" al pistei
## (supravietuiesc la rebuild — vezi Track.rebuild). @tool = se vad in editor.

const SLOT: int = Palette.RUST_METAL
const SIDES: int = 12
## Profil (inaltime, raza) de jos in sus — nervurile ies putin in afara.
const RINGS: Array = [
	Vector2(0.00, 0.25), # baza
	Vector2(0.10, 0.30), # nervura de jos
	Vector2(0.30, 0.285),
	Vector2(0.60, 0.285),
	Vector2(0.80, 0.30), # nervura de sus
	Vector2(0.90, 0.25), # capac
]

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children():
		c.free()
	var mesh := _build_mesh()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Palette.world_material()
	add_child(mi)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 0.9
	shape.shape = cyl
	shape.position = Vector3.UP * 0.45
	add_child(shape)

## Construieste mesh-ul si il returneaza (static -> refolosibil de un instancer).
static func _build_mesh() -> ArrayMesh:
	var uv := Palette.uv(SLOT)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# --- laterale: benzi intre inele consecutive ---
	for r in RINGS.size() - 1:
		var a: Vector2 = RINGS[r]      # (y, raza) jos
		var b: Vector2 = RINGS[r + 1]  # sus
		for s in SIDES:
			var a0 := float(s) / SIDES * TAU
			var a1 := float(s + 1) / SIDES * TAU
			var p_a0 := _ring_point(a.y, a0, a.x)
			var p_a1 := _ring_point(a.y, a1, a.x)
			var p_b0 := _ring_point(b.y, a0, b.x)
			var p_b1 := _ring_point(b.y, a1, b.x)
			var c_lo := _ao(a.x)
			var c_hi := _ao(b.x)
			_tri(st, uv, p_a0, c_lo, p_b0, c_hi, p_b1, c_hi)
			_tri(st, uv, p_a0, c_lo, p_b1, c_hi, p_a1, c_lo)
	# --- capace (sus/jos), triunghiuri in evantai din centru ---
	var bottom: Vector2 = RINGS[0]
	var top: Vector2 = RINGS[RINGS.size() - 1]
	var c_bottom := _ao(0.0) * 0.7 # baza sta pe sol -> mai intunecata
	var c_top := _ao(top.x)
	var ctr_b := Vector3(0, bottom.x, 0)
	var ctr_t := Vector3(0, top.x, 0)
	for s in SIDES:
		var a0 := float(s) / SIDES * TAU
		var a1 := float(s + 1) / SIDES * TAU
		# jos (normala in jos -> ordine inversa)
		_tri(st, uv, ctr_b, c_bottom,
			_ring_point(bottom.y, a1, bottom.x), c_bottom,
			_ring_point(bottom.y, a0, bottom.x), c_bottom)
		# sus
		_tri(st, uv, ctr_t, c_top,
			_ring_point(top.y, a0, top.x), c_top,
			_ring_point(top.y, a1, top.x), c_top)
	st.generate_normals()
	return st.commit()

static func _ring_point(radius: float, angle: float, y: float) -> Vector3:
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)

## AO copt: gradient vertical (jos mai intunecat, ocluziune de la sol). Se
## inmulteste peste culoarea din atlas prin vertex_color_use_as_albedo.
static func _ao(y: float) -> Color:
	var g := lerpf(0.55, 0.98, clampf(y / 0.9, 0.0, 1.0))
	return Color(g, g, g)

static func _tri(st: SurfaceTool, uv: Vector2,
		p0: Vector3, c0: Color, p1: Vector3, c1: Color, p2: Vector3, c2: Color) -> void:
	st.set_uv(uv); st.set_color(c0); st.add_vertex(p0)
	st.set_uv(uv); st.set_color(c1); st.add_vertex(p1)
	st.set_uv(uv); st.set_color(c2); st.add_vertex(p2)
