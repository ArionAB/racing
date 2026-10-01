class_name BastionTheatre
extends Node3D
## Teatrul bastionului (Jodhpur, POI F): salvele tunurilor de salut, tiroliana,
## uliii de sub bastion si artificiile de noapte. DOAR vizual: niciun corp
## fizic, nicio forta, nimic pe banda (brief §3: „fara forta, fara ceata pe
## drum"). Pozitiile vin gata calculate (coordonate de LUME) din
## `tools/gen_decor_jod_f.gd`.
##
## Totul e functie de CEAS, nu stare: pozitia fiecarui puf de fum, a fiecarei
## scantei si a figurii de pe cablu se calculeaza din timpul curent. De aceea
## Snapshot poate ingheta orice faza (`--salute-at`, `--zip-at`,
## `--fireworks-at` -> `force_clock`) fara sa simuleze cadre.
##
## Materiale: flacara si scanteile folosesc haloul comun (`LampHalo.material()`,
## deja numarat); fumul are UN material nou (`jod_smoke.gdshader`, amestecat,
## nu aditiv); cablul foloseste atlasul comun (`Palette.world_material()`).

# ---- salvele (brief §3: ciclu 31 s, 5 salve la 0,8 s, fum si flacara spre oras)
@export var muzzles: PackedVector3Array = PackedVector3Array()
@export var muzzle_dirs: PackedVector3Array = PackedVector3Array()
@export var salute_period: float = 31.0
@export var salute_start: float = 4.0
@export var salvo_gap: float = 0.8
@export var flame_time: float = 0.22
@export var smoke_life: float = 5.5
@export var smoke_puffs: int = 7
@export var smoke_color: Color = Color(0.93, 0.9, 0.86)

# ---- tiroliana (~23 s): cablul de la statia de sus la bastion
@export var zip_from: Vector3 = Vector3.ZERO
@export var zip_to: Vector3 = Vector3.ZERO
@export var zip_sag: float = 2.5
@export var zip_period: float = 23.0
@export var zip_ride: float = 9.0
@export var zip_rider: PackedScene = null

# ---- uliii: cercuri sub bastion
@export var kite_model: PackedScene = null
@export var kite_center: Vector3 = Vector3.ZERO
@export var kite_radii: PackedFloat32Array = PackedFloat32Array([14.0, 19.0, 24.0])
@export var kite_heights: PackedFloat32Array = PackedFloat32Array([-7.0, -11.0, -4.0])
@export var kite_periods: PackedFloat32Array = PackedFloat32Array([17.0, 23.0, 29.0])

# ---- artificiile: la dusk >= 0,8, peste case, maximum 3 simultane
@export var fw_center: Vector3 = Vector3.ZERO
@export var fw_spread: float = 30.0
@export var fw_y_min: float = 20.0
@export var fw_y_max: float = 33.0
@export var fw_dusk_min: float = 0.8
@export var fw_periods: PackedFloat32Array = PackedFloat32Array([2.7, 3.3, 3.9])
@export var fw_life: float = 2.3
@export var fw_sparks: int = 44
@export var fw_speed: float = 9.0

const FW_COLORS := [Color(1.0, 0.72, 0.12), Color(1.0, 0.32, 0.62),
	Color(0.35, 1.0, 0.45), Color(1.0, 0.97, 0.9)]
const GRAVITY := 6.0
const DRAG := 1.4

var _t := {"salute": 0.0, "zip": 0.0, "fw": 0.0, "kite": 0.0}
var _frozen := {}
var _fw_forced := false

var _flame_mm: MultiMesh
var _smoke_mm: MultiMesh
var _fw_mm: MultiMesh
var _rider: Node3D
var _kites: Array[Node3D] = []
var _dusk: Node = null
var _cable_pts := PackedVector3Array()


func _ready() -> void:
	add_to_group(&"bastion_theatre")
	_build_salute()
	_build_zip()
	_build_kites()
	_build_fireworks()
	_update()
	_unmark_flyers.call_deferred()


## Uliii si figura de pe cablu sunt in ZBOR prin proiect (ca un PathMover cu
## `stick_to_ground=false`, pe care probe_manual il iarta). Dupa ce DecorManual
## (world_prop) le-a remapat materialele — remaparea e si ea amanata, deci se
## asteapta un cadru — li se sterge `scene_file_path`, ca sa nu mai fie citite
## drept prop-uri asezate pe sol.
func _unmark_flyers() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for n: Node in _kites:
		n.scene_file_path = ""
	if _rider != null:
		_rider.scene_file_path = ""


## Snapshot: ceasul unei parti adus la `seconds` si INGHETAT. `kind` =
## "salute" | "zip" | "fw" | "kite". `fw` forteaza si aprinderea artificiilor
## (fara sa atinga DuskCycle; lumina o da `--dusk`).
func force_clock(kind: String, seconds: float) -> void:
	_t[kind] = seconds
	_frozen[kind] = true
	if kind == "fw":
		_fw_forced = true
	_update()


func _process(delta: float) -> void:
	for k in _t.keys():
		if not _frozen.has(k):
			_t[k] = float(_t[k]) + delta
	_update()


func _update() -> void:
	_update_salute(float(_t["salute"]))
	_update_zip(float(_t["zip"]))
	_update_kites(float(_t["kite"]))
	_update_fireworks(float(_t["fw"]))


# ------------------------------------------------------------------ salvele

func _build_salute() -> void:
	var n := muzzles.size()
	if n == 0:
		return
	_flame_mm = _halo_mm(n)
	_add_mmi("Flacari", _flame_mm, LampHalo.material(), 1)
	_smoke_mm = MultiMesh.new()
	_smoke_mm.transform_format = MultiMesh.TRANSFORM_3D
	_smoke_mm.use_colors = true
	_smoke_mm.use_custom_data = true
	_smoke_mm.mesh = LampHalo.quad()
	_smoke_mm.instance_count = n * smoke_puffs
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/jod_smoke.gdshader")
	_add_mmi("Fum", _smoke_mm, mat, 0)


## Salva k (0..n-1) trage la salute_start + k*salvo_gap in fiecare ciclu.
func _update_salute(t: float) -> void:
	if _flame_mm == null:
		return
	var n := muzzles.size()
	var tc := fposmod(t, salute_period)
	for k in n:
		var fire := salute_start + float(k) * salvo_gap
		var age := tc - fire
		if age < 0.0:
			age += salute_period # fumul salvei din ciclul trecut
		var m := muzzles[k]
		var d := muzzle_dirs[k] if k < muzzle_dirs.size() else Vector3.FORWARD
		# flacara: un fulger scurt la gura, alungit pe directia tragerii
		var fa := 1.0 - clampf(age / flame_time, 0.0, 1.0)
		if age > flame_time:
			fa = 0.0
		_flame_mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, m + d * 0.9))
		_flame_mm.set_instance_custom_data(k, Color(0.55 + 0.4 * fa, 3.5, 1.0, 0.0))
		_flame_mm.set_instance_color(k, Color(1.0, 0.55, 0.15, 2.2 * fa))
		# fumul: pufuri care ies pe directia tragerii, incetinesc, urca, cresc
		for j in smoke_puffs:
			var idx := k * smoke_puffs + j
			var delay := float(j) * 0.06
			var u := (age - delay) / smoke_life
			if u < 0.0 or u > 1.0:
				_smoke_mm.set_instance_color(idx, Color(0, 0, 0, 0))
				_smoke_mm.set_instance_custom_data(idx, Color(0.01, 0, 0, 0))
				_smoke_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, m))
				continue
			var h := _hash(float(k) * 13.1 + float(j) * 3.7)
			var reach := (2.0 + 5.0 * float(j) / float(smoke_puffs)) * (1.0 - exp(-u * 6.0))
			var side := d.cross(Vector3.UP).normalized() * (h - 0.5) * 2.0 * u * 3.0
			var p := m + d * reach + side + Vector3.UP * (u * 5.0 + 0.3 * float(j) * u)
			var r := 0.5 + 3.2 * sqrt(u) * (0.7 + 0.6 * h)
			var a := 0.85 * (1.0 - u) * (1.0 - u) * clampf(u * 30.0, 0.0, 1.0)
			_smoke_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, p))
			_smoke_mm.set_instance_custom_data(idx, Color(r, 0, 0, 0))
			_smoke_mm.set_instance_color(idx, Color(smoke_color.r, smoke_color.g,
				smoke_color.b, a))


# ------------------------------------------------------------------ tiroliana

func _build_zip() -> void:
	if zip_from == zip_to:
		return
	var segs := 28
	for s in segs + 1:
		var u := float(s) / float(segs)
		var p := zip_from.lerp(zip_to, u)
		p.y -= zip_sag * 4.0 * u * (1.0 - u)
		_cable_pts.append(p)
	# Cablul: tub cu 4 fete, r 5 cm, pe atlasul comun (slot fier inchis).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(Palette.VOLCANIC_BLACK)
	var r := 0.05
	for s in segs:
		var a := to_local(_cable_pts[s])
		var b := to_local(_cable_pts[s + 1])
		var dir := (b - a).normalized()
		var n1 := dir.cross(Vector3.UP).normalized()
		var n2 := dir.cross(n1).normalized()
		var ring := [n1, n2, -n1, -n2]
		for k in 4:
			var o0: Vector3 = ring[k] * r
			var o1: Vector3 = ring[(k + 1) % 4] * r
			var nrm: Vector3 = (ring[k] + ring[(k + 1) % 4]).normalized()
			for v: Vector3 in [a + o0, b + o0, b + o1, a + o0, b + o1, a + o1]:
				st.set_normal(nrm)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "Cablu"
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if zip_rider != null:
		_rider = zip_rider.instantiate() as Node3D
		_rider.name = "Tiroliana"
		add_child(_rider)
		_no_shadow(_rider)


func _cable_at(u: float) -> Vector3:
	var p := zip_from.lerp(zip_to, u)
	p.y -= zip_sag * 4.0 * u * (1.0 - u)
	return p


func _update_zip(t: float) -> void:
	if _rider == null:
		return
	var tc := fposmod(t, zip_period)
	if tc > zip_ride:
		_rider.visible = false
		return
	_rider.visible = true
	# pornire lenta, viteza, frana la capat
	var x := tc / zip_ride
	var u := x * x * (3.0 - 2.0 * x)
	var p := _cable_at(u)
	var fwd := _cable_at(minf(u + 0.01, 1.0)) - _cable_at(maxf(u - 0.01, 0.0))
	fwd.y = 0.0
	fwd = fwd.normalized()
	# originea piesei e scripetele; figura atarna sub el, cu fata pe -Z
	var b := Basis.looking_at(fwd, Vector3.UP)
	_rider.global_transform = Transform3D(b, p)


# ------------------------------------------------------------------ uliii

func _build_kites() -> void:
	if kite_model == null:
		return
	for k in kite_radii.size():
		var bird := kite_model.instantiate() as Node3D
		bird.name = "Uliu%d" % k
		add_child(bird)
		_no_shadow(bird)
		var ap := bird.find_children("*", "AnimationPlayer", true, false)
		if not ap.is_empty():
			var player := ap[0] as AnimationPlayer
			var names := player.get_animation_list()
			var clip := "Fly" if names.has("Fly") else (names[0] if names.size() > 0 else "")
			if clip != "":
				player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				player.play(clip)
				player.seek(float(k) * 0.37, true)
		_kites.append(bird)


func _update_kites(t: float) -> void:
	for k in _kites.size():
		var per := kite_periods[k] if k < kite_periods.size() else 20.0
		var r := kite_radii[k]
		var ang := TAU * (t / per) + float(k) * 2.1
		var sgn := 1.0 if k % 2 == 0 else -1.0
		ang *= sgn
		var h := kite_heights[k] if k < kite_heights.size() else -8.0
		var p := kite_center + Vector3(cos(ang) * r, h + 1.2 * sin(t * 0.7 + float(k)), sin(ang) * r)
		var tan := Vector3(-sin(ang), 0.0, cos(ang)) * sgn
		# inclinat spre centrul cercului
		var b := Basis.looking_at(tan, Vector3.UP).rotated(tan, -0.35 * sgn)
		_kites[k].global_transform = Transform3D(b, p)


# ------------------------------------------------------------------ artificiile

func _build_fireworks() -> void:
	if fw_center == Vector3.ZERO:
		return
	_fw_mm = _halo_mm(fw_periods.size() * fw_sparks)
	_add_mmi("Artificii", _fw_mm, LampHalo.material(), 1)


func _update_fireworks(t: float) -> void:
	if _fw_mm == null:
		return
	var lit := _fw_forced or _dusk_value() >= fw_dusk_min
	for e in fw_periods.size():
		var per := fw_periods[e]
		var tt := t + float(e) * per / float(fw_periods.size())
		var cyc := floorf(tt / per)
		var age := tt - cyc * per
		var alive := lit and age < fw_life
		var h1 := _hash(cyc * 7.3 + float(e) * 31.7)
		var h2 := _hash(cyc * 3.1 + float(e) * 11.3 + 5.0)
		var h3 := _hash(cyc * 5.9 + float(e) * 17.9 + 9.0)
		var c := fw_center + Vector3((h1 - 0.5) * 2.0 * fw_spread, 0.0, (h2 - 0.5) * 2.0 * fw_spread)
		c.y = lerpf(fw_y_min, fw_y_max, h3)
		var col: Color = FW_COLORS[int(h1 * 97.0) % FW_COLORS.size()]
		var u := age / fw_life
		for j in fw_sparks:
			var idx := e * fw_sparks + j
			if not alive:
				_fw_mm.set_instance_color(idx, Color(0, 0, 0, 0))
				_fw_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, c))
				continue
			# directii pe sfera Fibonacci, viteza usor variata
			var z := 1.0 - 2.0 * (float(j) + 0.5) / float(fw_sparks)
			var rr := sqrt(maxf(1.0 - z * z, 0.0))
			var phi := float(j) * 2.39996 + cyc
			var dir := Vector3(cos(phi) * rr, z, sin(phi) * rr)
			var v := fw_speed * (0.85 + 0.3 * _hash(float(j) + cyc))
			var dist := v * (1.0 - exp(-DRAG * age)) / DRAG
			var p := c + dir * dist + Vector3.DOWN * 0.5 * GRAVITY * age * age * 0.5
			var a := pow(1.0 - u, 1.4) * (1.0 if u < 0.7 else 0.6 + 0.4 * sin(age * 40.0 + float(j)))
			_fw_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, p))
			# miezul de 0,45 m: dincolo de 60 m haloul se strange pana la miez
			# (lamp_halo.gdshader), iar artificiile stau la 80-110 m de camera
			_fw_mm.set_instance_custom_data(idx, Color(0.45, 1.6, 1.6, 0.0))
			_fw_mm.set_instance_color(idx, Color(col.r, col.g, col.b, 2.0 * a))


func _dusk_value() -> float:
	if _dusk == null:
		var nodes := get_tree().get_nodes_in_group(&"dusk_cycle")
		if nodes.is_empty():
			return 0.0
		_dusk = nodes[0]
	return float(_dusk.get("dusk"))


# ------------------------------------------------------------------ utilitare

func _halo_mm(n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = LampHalo.quad()
	mm.instance_count = n
	for k in n:
		mm.set_instance_color(k, Color(0, 0, 0, 0))
	return mm


func _add_mmi(label: String, mm: MultiMesh, mat: Material, prio: int) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# instantele se misca departe de origine: AABB larg, altfel culling fals
	mmi.custom_aabb = AABB(Vector3(-400, -200, -400), Vector3(800, 400, 800))
	add_child(mmi)


func _no_shadow(n: Node) -> void:
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _hash(x: float) -> float:
	return fposmod(sin(x * 12.9898 + 78.233) * 43758.5453, 1.0)
