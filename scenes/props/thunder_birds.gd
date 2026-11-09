class_name ThunderBirds
extends MultiMeshInstance3D
## PASARILE CARE SE RIDICA LA TUNET (Angkor, brief §3 „Teatrul": „pasari care se ridica din
## coronament la tunet"). Legatura OPTIONALA tunet -> stol: `LightningFlash.thunder` ridica un
## stol mic dintr-un cuib din coronament, din fata jucatorului, care zboara in lateral si
## dispare.
##
## Cat costa: UN MultiMesh (un draw call, doar cat dureaza stolul; in rest `visible = false`
## si zero), fara fizica, fara noduri per pasare. Pozitiile se scriu in `_process` doar cat
## stolul e in aer: ~10 transformari pe cadru.
##
## [b]Cuiburile[/b] (`roosts`, in lume) vin din generator (`ROOSTS` din fisierele de zona): puncte
## in coronament, la 20-30 m de drum, la cota drumului + ~15 m. La tunet se alege unul dintre cele
## aflate INAINTEA masinii jucatorului (30-130 m): stolul trebuie vazut, nu aflat din urma.
## Daca niciunul nu e in fata (inceputul/sfarsitul pistei), nu se ridica nimic — mai bine nimic
## decat pasari din spatele camerei.
##
## Mesh-ul e al unui egret deja in repo (Okinawa, poza de zbor, 415 triunghiuri: alb pe cerul de furtuna) (`model`), cu materialul comun de lume: zero materiale
## noi. Aripile nu se bat (poza de zbor, mesh rigid): stolul se inclina si salta din faza, ceea ce de la 30 m
## si in miscare citeste ca batut de aripi.

@export var model: PackedScene = null
## Nodul de mesh folosit din GLB (egretul din Okinawa are `Pose_Fly`, aripi desfacute, si `Pose_Stand`).
@export var mesh_name: String = ""
## Calea spre `LightningFlash`-ul pistei (fulgerul e un nod frate, nu un copil).
@export var flash_path: NodePath = NodePath()
## Cuiburile (lume, m).
@export var roosts: PackedVector3Array = PackedVector3Array()
@export_range(3, 24) var birds: int = 11
## Scara modelului in lume (egretul are 1,4 m anvergura; de la 40-100 m trebuie mai mare ca sa se vada).
@export_range(0.5, 12.0, 0.1) var bird_scale: float = 2.5
@export var fly_speed: Vector2 = Vector2(9.0, 13.0)
@export var climb_speed: Vector2 = Vector2(5.0, 8.0)
## Durata zborului pana la disparitie (s).
@export_range(2.0, 14.0, 0.5) var flight_time: float = 7.0
## Fereastra de distanta fata de jucator in care un cuib e eligibil (m).
@export var pick_range: Vector2 = Vector2(30.0, 130.0)
## Pentru sonde: de cate ori s-a ridicat un stol.
var lifts: int = 0
var active: bool = false

var _t: float = 0.0
var _origin: PackedVector3Array = PackedVector3Array()
var _vel: PackedVector3Array = PackedVector3Array()
var _delay: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 24024
	visible = false
	set_process(false)
	if model == null or roosts.is_empty():
		return
	var mesh: Mesh = FlockProp._mesh_of(model, mesh_name)
	if mesh == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = birds
	multimesh = mm
	material_override = Palette.world_material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_origin.resize(birds)
	_vel.resize(birds)
	_delay.resize(birds)
	_phase.resize(birds)
	# Dupa ce toti fratii sunt in arbore.
	_connect.call_deferred()


func _connect() -> void:
	var flash := get_node_or_null(flash_path) as LightningFlash
	if flash == null:
		push_warning("ThunderBirds: `flash_path` nu arata un LightningFlash; stolul nu se ridica.")
		return
	flash.thunder.connect(_on_thunder)


func _on_thunder(strength: float) -> void:
	if active or strength < 0.25:
		return
	var car := _player()
	if car == null:
		return
	var roost := pick_roost(car.global_position, -car.global_basis.z)
	if roost == Vector3.INF:
		return
	lift(roost, car.global_position)


## Cuibul eligibil din fata `from` (directia `fwd`), la distanta din `pick_range`;
## `Vector3.INF` daca nu e niciunul. Public ca sa-l poata proba o sonda.
func pick_roost(from: Vector3, fwd: Vector3) -> Vector3:
	var f := Vector3(fwd.x, 0.0, fwd.z).normalized()
	var ok: Array[Vector3] = []
	for r in roosts:
		var d := r - from
		var flat := Vector3(d.x, 0.0, d.z)
		var dist := flat.length()
		if dist < pick_range.x or dist > pick_range.y:
			continue
		if flat.normalized().dot(f) < 0.5:
			continue
		ok.append(r)
	if ok.is_empty():
		return Vector3.INF
	return ok[_rng.randi() % ok.size()]


## Ridica stolul din `roost`, departandu-se de `away_from`.
func lift(roost: Vector3, away_from: Vector3) -> void:
	if multimesh == null:
		return
	lifts += 1
	active = true
	_t = 0.0
	var away := Vector3(roost.x - away_from.x, 0.0, roost.z - away_from.z).normalized()
	for i in birds:
		_origin[i] = roost + Vector3(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-2.0, 1.5),
			_rng.randf_range(-4.0, 4.0))
		# Impraștiat in evantai in jurul directiei „departe de jucator".
		var dir := away.rotated(Vector3.UP, _rng.randf_range(-1.1, 1.1))
		var sp := _rng.randf_range(fly_speed.x, fly_speed.y)
		_vel[i] = dir * sp + Vector3.UP * _rng.randf_range(climb_speed.x, climb_speed.y)
		_delay[i] = _rng.randf_range(0.0, 0.7)
		_phase[i] = _rng.randf() * TAU
	visible = true
	set_process(true)
	_write()


func _process(delta: float) -> void:
	_t += delta
	if _t >= flight_time + 0.8:
		active = false
		visible = false
		set_process(false)
		return
	_write()


func _write() -> void:
	var mm := multimesh
	for i in birds:
		mm.set_instance_transform(i, pose(i))


## Pozitia pasarii `i` la timpul curent al zborului. Separat de `_write` ca sondele sa o poata citi:
## `MultiMesh.get_instance_transform` intoarce zero pe randarea headless.
func pose(i: int) -> Transform3D:
	var t := _t - _delay[i]
	if t < 0.0:
		# Inca pe ramura: invizibila (scara zero) pana isi vine randul.
		return Transform3D(Basis.from_scale(Vector3.ZERO), _origin[i])
	var v := _vel[i]
	# Urcarea se domoleste (zboara spre peisaj, nu spre luna).
	var rise := 1.0 - clampf(t / 3.0, 0.0, 1.0) * 0.8
	var p := _origin[i] + Vector3(v.x * t, v.y * t * rise, v.z * t)
	var heading := Vector3(v.x, 0.0, v.z).normalized()
	# -Z al modelului = inainte; Basis.looking_at pune -Z pe directie.
	var b := Basis.looking_at(heading, Vector3.UP)
	var flap := sin(t * 14.0 + _phase[i])
	b = b * Basis(Vector3.FORWARD, flap * 0.45) * Basis(Vector3.RIGHT, 0.2 + 0.1 * flap)
	# Se micsoreaza la sfarsit, ca sa nu „plesneasca" disparitia.
	var fade := clampf((flight_time - t) / 1.5, 0.0, 1.0)
	return Transform3D(b.scaled(Vector3.ONE * bird_scale * fade), p + Vector3.UP * flap * 0.15)


func _player() -> Node3D:
	for c in get_tree().get_nodes_in_group(&"cars"):
		if c.get("is_player") == true:
			return c as Node3D
	return null
