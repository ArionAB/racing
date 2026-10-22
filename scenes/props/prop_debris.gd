extends Node3D
## Aschii si praf cand o piesa de decor mica e lovita (feel_checklist:
## things-fly). Un SINGUR manager pe scena, cu un grup fix de emitatoare
## refolosite pe rand — nicio piesa nu are noduri de particule proprii, iar
## 110 de stalpi si 64 de BumpProp dorm fara sa coste nimic.
##
## Cum afla ca o piesa a fost lovita, fara sa umble in fizica masinii: piesele
## se inscriu cu `watch()`; managerul tine lista celor TREZITE (semnalul
## `sleeping_state_changed`) si, la fiecare tick, compara viteza lor cu cea
## de la tick-ul trecut. Un salt de viteza peste `MIN_DV` e o lovitura (a
## masinii, a altei piese sau a solului dupa zbor) si aprinde un nor scalat cu
## saltul. Un salt de la repaus conteaza la fel: prima viteza dupa trezire.
##
## Plafonuri: `SLOTS` rafale simultane (fiecare cu `CHUNKS` aschii si `PUFFS`
## pufuri = 10 particule), cel mult o rafala pe cadru (cea mai puternica) si
## o pauza globala `COOLDOWN_S` — o izbitura in gramada trezeste zeci de
## piese deodata si n-are voie sa porneasca zeci de nori.

const SLOTS: int = 4
const CHUNKS: int = 6
const PUFFS: int = 4
const MIN_DV: float = 1.8
const FULL_DV: float = 14.0
const COOLDOWN_S: float = 0.08
const CHUNK_COLOR: Color = Color(0.62, 0.5, 0.36)
const DUST_COLOR: Color = Color(0.78, 0.74, 0.68)

const SELF_PATH: String = "res://scenes/props/prop_debris.gd"

## Fara class_name (cache-ul de clase globale nu se reface fara editor); cine
## il foloseste il preincarca: `const PropDebris := preload(...)`.
static var _instance: Node3D = null
static var _chunk_material: StandardMaterial3D = null
static var _puff_material: StandardMaterial3D = null

var _slots: Array[Dictionary] = []
var _next_slot: int = 0
var _awake: Array[RigidBody3D] = []
var _prev_v: Dictionary = {}
var _cooldown: float = 0.0
## Statistici pentru sonde.
var bursts: int = 0
var last_strength: float = 0.0
## Fractia de aschii vizibile la ultima rafala (0..1).
var last_density: float = 0.0


## Inscrie o piesa. Apelat o data, la construirea ei; fara efect in editor.
static func watch(body: RigidBody3D) -> void:
	if Engine.is_editor_hint() or body == null or not body.is_inside_tree():
		return
	var mgr: Variant = _ensure(body.get_tree())
	body.sleeping_state_changed.connect(mgr._on_sleep_changed.bind(body))
	body.tree_exited.connect(mgr._forget.bind(body))
	if not body.sleeping:
		mgr._on_sleep_changed(body)


static func _ensure(tree: SceneTree) -> Node3D:
	if is_instance_valid(_instance) and not _instance.is_queued_for_deletion():
		return _instance
	var mgr := (load(SELF_PATH) as GDScript).new() as Node3D
	mgr.name = "PropDebris"
	_instance = mgr
	var host: Node = tree.current_scene if tree.current_scene != null else tree.root
	host.add_child.call_deferred(mgr)
	return mgr


## Managerul curent (sau null) — pentru sonde.
static func instance() -> Node3D:
	return _instance if is_instance_valid(_instance) else null


func _ready() -> void:
	top_level = true # in lume, oriunde ar fi pus
	for i in SLOTS:
		var slot := {}
		slot["chunks"] = _make_chunks()
		slot["dust"] = _make_dust()
		add_child(slot["chunks"])
		add_child(slot["dust"])
		_slots.append(slot)


func _on_sleep_changed(body: RigidBody3D) -> void:
	if not is_instance_valid(body):
		return
	if body.sleeping:
		_awake.erase(body)
		_prev_v.erase(body)
	elif not _awake.has(body):
		_awake.append(body)
		_prev_v[body] = Vector3.ZERO


func _forget(body: RigidBody3D) -> void:
	_awake.erase(body)
	_prev_v.erase(body)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var best_dv := 0.0
	var best: RigidBody3D = null
	for body in _awake:
		if not is_instance_valid(body):
			continue
		var v := body.linear_velocity
		var dv := (v - (_prev_v.get(body, Vector3.ZERO) as Vector3)).length()
		_prev_v[body] = v
		if dv > best_dv:
			best_dv = dv
			best = body
	if best != null and best_dv >= MIN_DV and _cooldown <= 0.0:
		_burst(best, best_dv)


func _burst(body: RigidBody3D, dv: float) -> void:
	_cooldown = COOLDOWN_S
	bursts += 1
	last_strength = dv
	var k := clampf(inverse_lerp(MIN_DV, FULL_DV, dv), 0.0, 1.0)
	var slot: Dictionary = _slots[_next_slot]
	_next_slot = (_next_slot + 1) % SLOTS
	# O piesa grea scoate aschii mai mari decat un stalp subtire.
	var size := clampf(body.mass / 2.0, 0.6, 1.4)
	var heading := body.linear_velocity
	heading.y = 0.0
	heading = heading.normalized() if heading.length_squared() > 0.01 else Vector3.ZERO
	var dir := heading * 0.8 + Vector3.UP * 0.9
	var at := body.global_position + Vector3.UP * 0.2

	var chunks := slot["chunks"] as CPUParticles3D
	chunks.global_position = at
	chunks.direction = dir.normalized()
	chunks.initial_velocity_min = lerpf(1.5, 3.0, k)
	chunks.initial_velocity_max = lerpf(3.0, 8.0, k)
	chunks.scale_amount_min = 0.7 * size
	chunks.scale_amount_max = 1.3 * size
	# Cate aschii se vad: partea opaca a rampei de culoare initiala.
	var cg := chunks.color_initial_ramp as Gradient
	last_density = lerpf(0.35, 1.0, k)
	cg.set_offset(1, last_density)
	chunks.restart()

	var dust := slot["dust"] as CPUParticles3D
	dust.global_position = at
	dust.initial_velocity_max = lerpf(1.2, 3.0, k)
	dust.scale_amount_max = lerpf(0.9, 1.5, k) * size
	var dg := dust.color_initial_ramp as Gradient
	dg.set_offset(1, lerpf(0.4, 1.0, k))
	dust.restart()


func _make_chunks() -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.name = "Chunks"
	e.emitting = false
	e.one_shot = true
	e.explosiveness = 1.0
	e.amount = CHUNKS
	e.lifetime = 0.7
	e.local_coords = false
	e.spread = 55.0
	e.initial_velocity_min = 2.0
	e.initial_velocity_max = 5.0
	e.gravity = Vector3(0, -20.0, 0)
	e.angle_min = -180.0
	e.angle_max = 180.0
	e.angular_velocity_min = -360.0
	e.angular_velocity_max = 360.0
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.75, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	e.color_ramp = fade
	e.color = CHUNK_COLOR
	var ini := Gradient.new()
	ini.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	ini.set_offsets(PackedFloat32Array([0.0, 1.0]))
	ini.set_colors(PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	e.color_initial_ramp = ini
	if _chunk_material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		m.roughness = 1.0
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_chunk_material = m
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.14, 0.18) # destul de mari sa se vada de la 16 m
	box.material = _chunk_material
	e.mesh = box
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return e


func _make_dust() -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.name = "Dust"
	e.emitting = false
	e.one_shot = true
	e.explosiveness = 0.9
	e.amount = PUFFS
	e.lifetime = 0.6
	e.local_coords = false
	e.direction = Vector3.UP
	e.spread = 80.0
	e.initial_velocity_min = 0.6
	e.initial_velocity_max = 2.0
	e.gravity = Vector3(0, 0.3, 0)
	e.damping_min = 1.5
	e.damping_max = 2.5
	e.scale_amount_min = 0.6
	e.scale_amount_max = 1.1
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.0))
	e.scale_amount_curve = grow
	e.angle_min = -180.0
	e.angle_max = 180.0
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.15, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)]))
	e.color_ramp = fade
	e.color = DUST_COLOR
	var ini := Gradient.new()
	ini.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	ini.set_offsets(PackedFloat32Array([0.0, 1.0]))
	ini.set_colors(PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	e.color_initial_ramp = ini
	if _puff_material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		m.roughness = 1.0
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_puff_material = m
	var sph := SphereMesh.new()
	sph.radius = 0.35
	sph.height = 0.7
	sph.radial_segments = 8
	sph.rings = 4
	sph.material = _puff_material
	e.mesh = sph
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return e
