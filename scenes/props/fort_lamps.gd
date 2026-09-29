class_name FortLamps
extends Node3D
## Lampile calde de pe coama zidurilor si tortele portilor fortului (Jodhpur,
## POI E): in bara, linia zigzagului se deseneaza in puncte de lumina — o
## lampa la cateva merloane, torte la stalpii portilor.
##
## Nu e un sistem general: pozitiile vin gata calculate (coordonate de LUME)
## din `tools/gen_decor_jod_e.gd`, care le ia din varfurile REALE ale
## merloanelor (`fort_wall_segment`: merloni la z = -4,8 / -2,4 / 0 / 2,4 / 4,8,
## varful la y 13,98, pe x 0,8..1,5). Nodul doar le deseneaza, intr-un singur
## MultiMesh, fara coliziune si fara umbra.
##
## `diya` din kit are 9 cm: din camera de joc (10 m sus, 12,5 m in spate) e sub
## un pixel. Lampa e deci o bipiramida emisiva de ~0,5 m, geometria si
## materialul identice cu becurile din `StreetLights` (POI H): acelasi
## `Palette.glow_material_slots([30], 1.3, tint)`, deci la integrare cele doua
## impart UN material (cheia din cache e aceeasi).

## Pozitiile (lume), raza si alungirea pe verticala (1 = glob, >1 = flacara de
## torta) per lampa. Listele sunt paralele.
@export var positions: PackedVector3Array = PackedVector3Array()
@export var radii: PackedFloat32Array = PackedFloat32Array()
@export var stretch: PackedFloat32Array = PackedFloat32Array()
@export var glow_slot: int = 30
@export var glow_energy: float = 1.3
@export var glow_tint: Color = Color(1.0, 0.33, 0.04)


## Construit in `_ready`, NU amanat: pozitiile sunt deja in lume, n-au nevoie
## de traseul copt, iar un build amanat nu apare in capturi (memoria
## `decorul-amanat-nu-e-in-captura`).
func _ready() -> void:
	if positions.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _bipyramid(1.0, glow_slot)
	mm.instance_count = positions.size()
	var inv := global_transform.affine_inverse()
	for k in positions.size():
		var r := radii[k] if k < radii.size() else 0.25
		var s := stretch[k] if k < stretch.size() else 1.0
		var b := Basis.from_scale(Vector3(r, r * s, r))
		mm.set_instance_transform(k, inv * Transform3D(b, positions[k]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Lampi"
	mmi.multimesh = mm
	mmi.material_override = Palette.glow_material_slots(
		[glow_slot], glow_energy, glow_tint)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Bipiramida hexagonala (12 triunghiuri), UV colapsat pe slot — aceeasi forma
## ca becul din StreetLights, ca sa citeasca glob, nu romb.
static func _bipyramid(r: float, slot: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	var top := Vector3(0, r, 0)
	var bot := Vector3(0, -r, 0)
	for k in 6:
		var a0 := TAU * float(k) / 6.0
		var a1 := TAU * float(k + 1) / 6.0
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		for tri in [[top, p0, p1], [bot, p1, p0]]:
			var a: Vector3 = tri[0]
			var b: Vector3 = tri[1]
			var c: Vector3 = tri[2]
			var nrm := (b - a).cross(c - a).normalized()
			if nrm.dot(a + b + c) < 0.0:
				var t := b
				b = c
				c = t
				nrm = -nrm
			for p in [a, c, b]:
				st.set_normal(nrm)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(p)
	return st.commit()
