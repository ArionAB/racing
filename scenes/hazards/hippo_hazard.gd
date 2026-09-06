class_name HippoHazard
extends AnimatableBody3D
## HIPOPOTAMUL DIN VAD (Serengeti, docs/track_briefs/serengeti.md §3).
##
## O spinare care se ridica de sub apa, in banda, pe ciclu: bule (telegraf),
## urcare brusca, sta, se scufunda. NU e un impuls scriptat — e o movila care
## apare sub roti, iar fizica intreaga (suspensia pe raycast + panta) face
## restul: la viteza te arunca, incet te urca si te lasa. Aceeasi familie de
## miscare ca BalloonHazard/LiftBridgeHazard (traiectorie verticala pe ceas),
## cu un singur corp si o singura forma.
##
## Scufundat, sta sub albia raului: NU lasa gol in carosabil (memoria
## `suprafete-cu-goluri-si-praguri`) fiindca albia e un corp separat; spinarea
## doar coboara sub ea.

signal surfacing(hippo: HippoHazard)

## Spinarea din kitul de savana (PR #376): 2,5 x 4,8 x 1,35 m, origine la
## baza, -Z inainte. Se aseaza cu VARFUL spinarii la `rest_top`, exact ca
## elipsoidul procedural pe care il inlocuieste VIZUAL. Coliziunea RAMANE
## jumatatea de elipsoid (`width` x `length`), nu hull-ul mesh-ului: masurat cu
## ProbeSerengeti, hull-ul din mesh are crupa aproape verticala (0,9 m in 0,4 m)
## si masina se oprea in ea in loc sa fie ridicata (y max 0,85, 0 cadre in
## aer); elipsoidul e o movila lina, si movila e mecanica (vezi antetul).
## Mesh-ul e cu 0,4 m mai lung la fiecare capat decat colizorul — capul si
## crupa ies din apa fara corp, ceea ce nu se simte de la volan.
## Fara fisier (alt worktree, kit neimportat) se vede elipsoidul, ca sondele
## sa nu pice din cauza unui asset.
const HIPPO_GLB := "res://assets/models/serengeti/animals/hippo_back.glb"

@export_group("Ritm")
@export_range(4.0, 120.0, 0.5) var period: float = 20.0
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Bule + pufnit inainte sa iasa.
@export_range(0.0, 5.0, 0.1) var telegraph: float = 1.0
@export_range(0.1, 3.0, 0.05) var rise_time: float = 0.4
@export_range(0.2, 10.0, 0.1) var hold: float = 2.0
@export_range(0.1, 3.0, 0.05) var sink_time: float = 0.8

@export_group("Forma")
## Cat iese spinarea deasupra apei (m).
@export_range(0.3, 3.0, 0.05) var rise_m: float = 1.2
@export_range(2.0, 8.0, 0.1) var length: float = 4.0
@export_range(1.0, 5.0, 0.1) var width: float = 2.5
## Cota de repaus a varfului spinarii, sub apa (negativ = ingropat).
@export_range(-3.0, 0.0, 0.05) var rest_top: float = -0.3

var _rest: Vector3
var _time: float = 0.0
var _announced: bool = false
var _mesh: MeshInstance3D


func _ready() -> void:
	sync_to_physics = true
	_rest = global_position
	_time = phase * period
	_build()


func _build() -> void:
	# Jumatate de elipsoid (spinarea): varful la y = rest_top fata de origine
	# (in repaus, sub apa), baza la rest_top - H, cu H destul de mare ca
	# ridicata cu rise_m sa nu i se vada fundul.
	var top := rest_top
	var hgt := rise_m - rest_top + 0.3
	var rx := width * 0.5
	var rz := length * 0.5
	var segs := 12
	var rings := 4
	var pts: Array[PackedVector3Array] = []
	for r in rings + 1:
		var ang := float(r) / float(rings) * PI * 0.5 # 0 = varf, PI/2 = baza
		var ring := PackedVector3Array()
		for s in segs:
			var u := float(s) / float(segs) * TAU
			ring.append(Vector3(cos(u) * rx * sin(ang), top - hgt * (1.0 - cos(ang)),
				sin(u) * rz * sin(ang)))
		pts.append(ring)
	var base := pts[rings]
	if not _build_from_kit():
		_build_procedural_mesh(pts, base, segs, rings)
	# Coliziunea: mereu elipsoidul (vezi HIPPO_GLB pentru de ce nu mesh-ul).
	var shape := CollisionShape3D.new()
	var convex := ConvexPolygonShape3D.new()
	var cloud := PackedVector3Array()
	for ring in pts:
		cloud.append_array(ring)
	for s in segs:
		cloud.append(base[s] + Vector3.DOWN * 2.0)
	convex.points = cloud
	shape.shape = convex
	add_child(shape)


## Spinarea procedurala (fara kit): elipsoidul din `pts` + o fusta pana la
## -2 m, ca sa nu se vada fundul cand e sus.
func _build_procedural_mesh(pts: Array[PackedVector3Array], base: PackedVector3Array,
		segs: int, rings: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(0.32, 0.30, 0.31)
	for r in rings:
		for s in segs:
			var s2 := (s + 1) % segs
			var a := pts[r][s]
			var b := pts[r][s2]
			var c := pts[r + 1][s2]
			var d := pts[r + 1][s]
			st.set_color(col)
			st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
			st.add_vertex(a); st.add_vertex(d); st.add_vertex(c)
	for s in segs:
		var s2 := (s + 1) % segs
		var a := base[s]
		var b := base[s2]
		st.set_color(col)
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(b + Vector3.DOWN * 2.0)
		st.add_vertex(a); st.add_vertex(b + Vector3.DOWN * 2.0); st.add_vertex(a + Vector3.DOWN * 2.0)
	st.generate_normals()
	_mesh = MeshInstance3D.new()
	_mesh.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.6
	_mesh.material_override = mat
	add_child(_mesh)


## Spinarea din GLB (doar vizual). Intoarce false daca kitul lipseste.
func _build_from_kit() -> bool:
	if not ResourceLoader.exists(HIPPO_GLB):
		return false
	var ps := load(HIPPO_GLB) as PackedScene
	if ps == null:
		return false
	var model := ps.instantiate() as Node3D
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		model.free()
		return false
	var aabb := Track.model_aabb(model)
	# Varful spinarii la rest_top: modelul are originea la baza, deci coboara
	# cu toata inaltimea lui. Sub albie ramane si cand e sus (1,35 > rise_m).
	model.position = Vector3(0.0, rest_top - aabb.end.y, 0.0)
	Palette.apply_world_material(model)
	add_child(model)
	_mesh = meshes[0] as MeshInstance3D
	return true


## Inaltimea spinarii fata de repaus, la momentul `t` din ciclu.
func lift_at(t: float) -> float:
	t = fposmod(t, period)
	var t_rise := telegraph
	var t_hold := t_rise + rise_time
	var t_sink := t_hold + hold
	var t_end := t_sink + sink_time
	if t < t_rise:
		return 0.0
	if t < t_hold:
		var k := (t - t_rise) / rise_time
		return rise_m * (1.0 - (1.0 - k) * (1.0 - k)) # iese brusc, se opreste moale
	if t < t_sink:
		return rise_m
	if t < t_end:
		var k := (t - t_sink) / sink_time
		return rise_m * (1.0 - k * k)
	return 0.0


func is_up() -> bool:
	return lift_at(_time) > rise_m * 0.9


## Secunde pana la urmatoarea urcare completa (pentru sonde si AI).
func seconds_to_up() -> float:
	var t := 0.0
	while t < period + 0.1:
		if lift_at(_time + t) > rise_m * 0.95:
			return t
		t += 0.02
	return period


## Secunde pana la un interval de `window` s in care spinarea sta scufundata.
func seconds_to_calm(window: float) -> float:
	var t := 0.0
	while t < period * 2.0:
		var calm := true
		var k := 0.0
		while k < window:
			if lift_at(_time + t + k) > 0.001:
				calm = false
				break
			k += 0.05
		if calm:
			return t
		t += 0.05
	return 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	var cyc := fposmod(_time, period)
	if cyc < telegraph:
		if not _announced:
			_announced = true
			surfacing.emit(self)
	else:
		_announced = false
	global_transform = Transform3D(Basis.IDENTITY, _rest + Vector3.UP * lift_at(_time))
