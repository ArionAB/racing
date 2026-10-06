class_name TelegraphWires
extends Node3D
## Firele de telegraf dintre stalpii `telegraph_pole.glb` (Monument Valley).
##
## Kitul n-are fire ("firele nu sunt in GLB, le face codul"). Nodul asta le
## deseneaza: pentru fiecare pereche de stalpi consecutivi, cate o catenara
## (parabola cu sageata `sag_m`) intre izolatorii omologi, intr-un singur
## ArrayMesh. Opt-in: exista doar pe pistele care instantiaza nodul (azi
## Track19); nimic din restul pistelor nu il atinge.
##
## Folosire (A scrie, B si H refolosesc):
##   [node name="Fire" type="Node3D" parent="DecorManual/ZonaB"]
##   script = ExtResource("telegraph_wires")
##   poles = PackedVector3Array(x, y, z, ...)   # BAZA fiecarui stalp, in LUME
##   yaws = PackedFloat32Array(...)             # yaw-ul fiecarui stalp (rad)
##   breaks = PackedInt32Array(3)               # optional: nu lega stalpul 3 de 4
## Stalpii insisi sunt instante `s_telegraph_pole` puse de mana (coliziune
## `trunk` din PROP_COLLISION) cu ACELEASI transformari: `yaw` se alege ca X-ul
## local al stalpului (traversa) sa fie perpendicular pe sosea — firele merg pe
## sosea. Pozitiile sunt in coordonate de lume si zona ramane la identitate.
##
## Geometrie: prisma triunghiulara subtire (3 laturi, 6 triunghiuri pe segment),
## FARA coliziune si FARA umbra (un fir de 4 cm n-are ce umbra sa dea). Material:
## `Palette.world_material()`, cu UV-ul colapsat pe slotul `wire_slot` — acelasi
## material partajat al lumii, deci nu creste numaratoarea de materiale.

## Varfurile izolatorilor in cadrul LOCAL al stalpului (masurat pe GLB:
## traversa pe X la +-1,0 / y 7,5, izolatorul din varf la y 8,0).
const INSULATORS: Array[Vector3] = [
	Vector3(-1.0, 7.5, 0.0), Vector3(1.0, 7.5, 0.0), Vector3(0.0, 8.0, 0.0)]

## Baza fiecarui stalp (lume) si yaw-ul lui. Listele sunt paralele.
@export var poles: PackedVector3Array = PackedVector3Array()
@export var yaws: PackedFloat32Array = PackedFloat32Array()
## Scara stalpilor (1 = cum vine din GLB, 8 m).
@export var pole_scale: float = 1.0
## Indicii `i` dupa care firul se intrerupe (nu se leaga `i` de `i+1`).
@export var breaks: PackedInt32Array = PackedInt32Array()
## Sageata mijlocului unui lant de 26-30 m (m). Sub ~0,5 pare intins ca o
## sfoara, peste ~1,5 se vede lasat; 0,9 e „fir de telegraf”.
@export var sag_m: float = 0.9
@export var segments: int = 10
@export var wire_radius: float = 0.05
@export var wire_slot: int = Palette.LOG_DARK


## In `_ready`, nu amanat: pozitiile sunt de lume si nu cer traseul copt
## (memoria `decorul-amanat-nu-e-in-captura`).
func _ready() -> void:
	var mesh := build_mesh(poles, yaws, pole_scale, breaks, sag_m, segments,
		wire_radius, wire_slot)
	if mesh == null:
		return
	var inv := global_transform.affine_inverse()
	var mi := MeshInstance3D.new()
	mi.name = "Fire"
	mi.mesh = mesh
	mi.transform = inv
	mi.material_override = Palette.world_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Meshul firelor (coordonate de lume), sau null daca n-are nicio deschidere.
## Static, ca sa-l poata chema si sondele fara scena.
static func build_mesh(p_poles: PackedVector3Array, p_yaws: PackedFloat32Array,
		scl: float, p_breaks: PackedInt32Array, sag: float, segs: int,
		radius: float, slot: int) -> ArrayMesh:
	if p_poles.size() < 2:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	var n := 0
	for i in p_poles.size() - 1:
		if p_breaks.has(i):
			continue
		var ya := p_yaws[i] if i < p_yaws.size() else 0.0
		var yb := p_yaws[i + 1] if i + 1 < p_yaws.size() else 0.0
		var ba := Basis.from_euler(Vector3(0.0, ya, 0.0))
		var bb := Basis.from_euler(Vector3(0.0, yb, 0.0))
		for ins in INSULATORS:
			var a := p_poles[i] + ba * (ins * scl)
			var b := p_poles[i + 1] + bb * (ins * scl)
			_wire(st, a, b, sag, segs, radius, uv)
			n += 1
	if n == 0:
		return null
	return st.commit()


static func _wire(st: SurfaceTool, a: Vector3, b: Vector3, sag: float, segs: int,
		r: float, uv: Vector2) -> void:
	var pts: Array[Vector3] = []
	for k in segs + 1:
		var t := float(k) / float(segs)
		var p := a.lerp(b, t)
		p.y -= sag * 4.0 * t * (1.0 - t)
		pts.append(p)
	for k in segs:
		var d := (pts[k + 1] - pts[k]).normalized()
		var side := d.cross(Vector3.UP)
		if side.length() < 0.001:
			side = Vector3.RIGHT
		side = side.normalized()
		var up := side.cross(d).normalized()
		# Sectiune triunghiulara: varf sus, doua colturi jos.
		var offs: Array[Vector3] = [up * r, (-up * 0.5 + side * 0.866) * r,
			(-up * 0.5 - side * 0.866) * r]
		for s in 3:
			var s2 := (s + 1) % 3
			var q0: Vector3 = pts[k] + offs[s]
			var q1: Vector3 = pts[k] + offs[s2]
			var q2: Vector3 = pts[k + 1] + offs[s2]
			var q3: Vector3 = pts[k + 1] + offs[s]
			var nrm := ((offs[s] + offs[s2]) * 0.5).normalized()
			for tri in [[q0, q2, q1], [q0, q3, q2]]:
				var v: Array = tri
				var fn: Vector3 = ((v[1] - v[0]) as Vector3).cross(v[2] - v[0])
				if fn.dot(nrm) < 0.0:
					v = [v[0], v[2], v[1]]
				for pv in v:
					st.set_normal(nrm)
					st.set_uv(uv)
					st.set_color(Color.WHITE)
					st.add_vertex(pv)
