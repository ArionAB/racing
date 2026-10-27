@tool
class_name ChhatriKit
extends Node3D
## CHHATRI-URI DE MARMURA (Jodhpur, Track17, POI G2, runda 2): pavilioane mici
## cu stalpi, streasina (chajja) si cupola, generate din cod pe atlasul lumii.
## Criticul orb (runda 1): „in referinta domina cadrul un GRUP de 4-6 chhatri
## albe cu cupole, in trepte pe stanca de riolit, chiar deasupra apei". Kitul
## are doar `jaswant_thada` (un singur pavilion, piesa centrala); chhatri-urile
## sunt pe lista cererilor de asset, iar coordonatorul a permis sa fie facute
## din cod, tiparul `RoofKit` / `BazaarKit`: UN material
## (`Palette.world_material()`), marmura pe slotul 22 (FOAM_WHITE, acelasi ca
## cenotaful), umbra din vertex color (AO), totul unit intr-un singur mesh.
##
## Fara coliziune: stau pe terasele de stanca de peste lac, la >= 30 m de
## asfalt, dincolo de apa (repunere).
##
## Construit in `_ready` (pozitiile sunt in coordonate de LUME, scrise de
## `tools/gen_decor_jod_g.gd`), ca sa apara in capturi (memoria
## `decorul-amanat-nu-e-in-captura`); materialul se pune amanat.

## Baza fiecarui chhatri (lume, centrul soclului, la cota blatului pe care
## sta), scara (1 = soclu de 3,2 m, varf la ~5,6 m) si yaw (rad).
@export var bases: PackedVector3Array = PackedVector3Array()
@export var scales: PackedFloat32Array = PackedFloat32Array()
@export var yaws: PackedFloat32Array = PackedFloat32Array()
## Numarul de stalpi: 4 (patrat) sau 6/8 (poligon), per chhatri.
@export var sides: PackedInt32Array = PackedInt32Array()

const MARBLE := 22
const SHADE := 29
const DOME_SEG := 10
const DOME_RINGS := 4

var _built := false
var _mesh: MeshInstance3D = null


func _ready() -> void:
	if _built:
		return
	_built = true
	global_transform = Transform3D.IDENTITY
	if bases.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in bases.size():
		var s := scales[i] if i < scales.size() else 1.0
		var y := yaws[i] if i < yaws.size() else 0.0
		var n := sides[i] if i < sides.size() else 4
		_chhatri(st, bases[i], s, y, n)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Chhatri"
	_mesh.mesh = MeshCpu.with_lods(st.commit())
	add_child(_mesh)
	_apply_material.call_deferred()


func _apply_material() -> void:
	if _mesh != null:
		_mesh.material_override = Palette.world_material()


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, slot: int,
		ca: float = 1.0, cb: float = 1.0, cc: float = 1.0) -> void:
	var n := (c - a).cross(b - a).normalized()
	var uv := Palette.uv(slot)
	for pr: Array in [[a, ca], [b, cb], [c, cc]]:
		st.set_normal(n)
		st.set_uv(uv)
		var v: float = pr[1]
		st.set_color(Color(v, v, v))
		st.add_vertex(pr[0])


## Prisma poligonala (n laturi, raza de colt r0 jos / r1 sus), cu capac sus
## si jos. `ao0` = umbrirea muchiei de jos.
func _prism(st: SurfaceTool, c: Vector3, r0: float, r1: float, h: float, n: int,
		yaw: float, slot: int, ao0: float, ao_top: float = 1.0, cap_bottom: bool = false) -> void:
	var off := yaw + (PI / float(n) if n == 4 else 0.0)
	for k in n:
		var a0 := off + TAU * float(k) / float(n)
		var a1 := off + TAU * float(k + 1) / float(n)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var b0 := c + d0 * r0
		var b1 := c + d1 * r0
		var t0 := c + d0 * r1 + Vector3.UP * h
		var t1 := c + d1 * r1 + Vector3.UP * h
		_tri(st, b0, b1, t0, slot, ao0, ao0, ao_top)
		_tri(st, b1, t1, t0, slot, ao0, ao_top, ao_top)
		_tri(st, t0, t1, c + Vector3.UP * h, slot, ao_top, ao_top, ao_top)
		if cap_bottom:
			_tri(st, b1, b0, c, slot, 0.55, 0.55, 0.55)


func _chhatri(st: SurfaceTool, p: Vector3, s: float, yaw: float, n: int) -> void:
	var rc := 1.6 * s * (1.41 if n == 4 else 1.0) # raza de colt a soclului
	# Soclu in doua trepte (umbra de treapta din geometrie, nu din textura).
	_prism(st, p + Vector3.DOWN * 0.3 * s, rc * 1.12, rc * 1.12, 0.45 * s, n, yaw, MARBLE, 0.6)
	_prism(st, p + Vector3.UP * 0.15 * s, rc, rc, 0.35 * s, n, yaw, MARBLE, 0.75)
	var floor_y := 0.5 * s
	var col_h := 2.3 * s
	var rp := rc * 0.82
	# Stalpii: prisme cu 4 laturi, la colturi.
	var off := yaw + (PI / float(n) if n == 4 else 0.0)
	for k in n:
		var a := off + TAU * float(k) / float(n)
		var q := p + Vector3(cos(a), 0, sin(a)) * rp + Vector3.UP * floor_y
		_prism(st, q, 0.13 * s, 0.11 * s, col_h, 4, a, MARBLE, 0.7)
	# Grinda + streasina (chajja): lespede larga si subtire, cu dedesubtul
	# intunecat (umbra puternica sub streasina = silueta pavilionului).
	var ey := floor_y + col_h
	_prism(st, p + Vector3.UP * ey, rc * 0.9, rc * 0.9, 0.3 * s, n, yaw, MARBLE, 0.8)
	_prism(st, p + Vector3.UP * (ey + 0.3 * s), rc * 1.32, rc * 1.12, 0.22 * s, n, yaw,
		MARBLE, 0.45, 1.0, true)
	# Tambur + cupola (emisfera turtita pe DOME_SEG x DOME_RINGS).
	var dy := ey + 0.52 * s
	_prism(st, p + Vector3.UP * dy, rc * 0.62, rc * 0.62, 0.35 * s, n, yaw, MARBLE, 0.85)
	var c := p + Vector3.UP * (dy + 0.35 * s)
	var rr := rc * 0.62
	var hh := rr * 1.05
	for i in DOME_RINGS:
		var p0 := 0.5 * PI * float(i) / float(DOME_RINGS)
		var p1 := 0.5 * PI * float(i + 1) / float(DOME_RINGS)
		for k in DOME_SEG:
			var a0 := TAU * float(k) / float(DOME_SEG)
			var a1 := TAU * float(k + 1) / float(DOME_SEG)
			var v00 := c + Vector3(cos(p0) * cos(a0) * rr, sin(p0) * hh, cos(p0) * sin(a0) * rr)
			var v01 := c + Vector3(cos(p0) * cos(a1) * rr, sin(p0) * hh, cos(p0) * sin(a1) * rr)
			var v10 := c + Vector3(cos(p1) * cos(a0) * rr, sin(p1) * hh, cos(p1) * sin(a0) * rr)
			var v11 := c + Vector3(cos(p1) * cos(a1) * rr, sin(p1) * hh, cos(p1) * sin(a1) * rr)
			var ao := lerpf(0.82, 1.0, float(i) / float(DOME_RINGS))
			_tri(st, v00, v01, v10, MARBLE, ao, ao, ao)
			if i < DOME_RINGS - 1:
				_tri(st, v01, v11, v10, MARBLE, ao, ao, ao)
	# Finialul (kalash): con subtire, gri.
	_prism(st, c + Vector3.UP * hh * 0.97, 0.12 * s, 0.02 * s, 0.7 * s, 4, yaw, SHADE, 0.9)
