class_name Driver
extends Node3D
## Soferul de jucarie ASEZAT in masina (prototipul sofer + ragdoll).
##
## Figurina e un GLB cu 7 piese RIGIDE ca noduri separate (Hips, Torso, Head,
## Arm_L/R, Leg_L/R), fiecare cu originea in articulatia ei. Aici piesele se
## misca PROCEDURAL din ce simte masina — fara animatii coapte:
##   · trunchiul se lasa in afara virajului (acceleratia laterala) si inainte
##     la frana / inapoi la acceleratie;
##   · capul exagereaza trunchiul si se uita in viraj (dupa directie);
##   · bratele „tin volanul": una urca, cealalta coboara cu directia;
##   · in aer, bratele se ridica — momentul de „uuu" al sariturii.
## Piesele sunt frati in GLB, deci ierarhia (cap pe trunchi, trunchi pe
## solduri) e compusa aici din transformarile de repaus.
##
## `eject()` ascunde figurina si preda transformarile globale ale pieselor
## unui [ToyRagdoll], care le face corpuri rigide la `_ready`. `reseat()` o
## arata la loc. Ragdoll-ul nu e copil al masinii: traieste in lume
## (parintele masinii), deci cine il primeste il pune in arbore imediat.

const PART_NAMES: Array[StringName] = [
	&"Hips", &"Torso", &"Head", &"Arm_L", &"Arm_R", &"Leg_L", &"Leg_R"]
## Parintele fiecarei piese in ierarhia figurinei (Hips e radacina).
const PARENT: Dictionary = {
	&"Torso": &"Hips", &"Head": &"Torso",
	&"Arm_L": &"Torso", &"Arm_R": &"Torso",
	&"Leg_L": &"Hips", &"Leg_R": &"Hips",
}

## Cat se lasa trunchiul pe metru/s^2 de acceleratie laterala (rad).
const LEAN_PER_G: float = 0.028
const LEAN_MAX: float = 0.38
const PITCH_PER_G: float = 0.018
const PITCH_MAX: float = 0.25
## Netezirea: acceleratia bruta e zgomotoasa (suspensia), figurina nu trebuie
## sa tremure cu ea.
const SMOOTH: float = 9.0
## Bratele in aer: ridicate cu atat (rad, in jurul axei laterale).
const ARMS_UP_AIR: float = -0.9
const ARM_STEER: float = 0.28
const HEAD_YAW_STEER: float = 0.35

var car: Car
var _scene: PackedScene
var _model: Node3D
var _parts: Dictionary = {}   # StringName -> MeshInstance3D
var _rest: Dictionary = {}    # StringName -> Transform3D (local in figurina)
var _lat_g: float = 0.0       # acceleratie laterala netezita (m/s^2)
var _lon_g: float = 0.0       # acceleratie longitudinala netezita
var _arms_up: float = 0.0     # 0 pe volan .. 1 ridicate
var _prev_vel: Vector3 = Vector3.ZERO
var _ejected: bool = false


func setup(scene: PackedScene, owner_car: Car) -> void:
	car = owner_car
	_scene = scene
	_model = scene.instantiate() as Node3D
	add_child(_model)
	Palette.apply_world_material(_model)
	for child in _model.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var key := StringName(mi.name)
		if key in PART_NAMES:
			_parts[key] = mi
			_rest[key] = mi.transform
	if _parts.size() != PART_NAMES.size():
		push_warning("Driver: figurina are %d/%d piese recunoscute" % [
			_parts.size(), PART_NAMES.size()])


func is_seated() -> bool:
	return not _ejected


func _physics_process(delta: float) -> void:
	if car == null or _ejected or _parts.is_empty():
		return
	# Acceleratia masinii in spatiul ei: dreapta = +X, fata = -Z.
	var vel := car.velocity
	var acc := (vel - _prev_vel) / maxf(delta, 0.0001)
	_prev_vel = vel
	var basis := car.global_transform.basis
	var lat := acc.dot(basis.x)
	var lon := acc.dot(-basis.z)
	var k := 1.0 - exp(-SMOOTH * delta)
	_lat_g = lerpf(_lat_g, lat, k)
	_lon_g = lerpf(_lon_g, lon, k)
	var in_air := car.wheels_on_ground == 0
	_arms_up = lerpf(_arms_up, 1.0 if in_air else 0.0, 1.0 - exp(-6.0 * delta))
	var steer := 0.0
	if car.controller != null:
		steer = clampf(car.controller.get_steer(), -1.0, 1.0)

	# Trunchiul se lasa IN AFARA virajului (inertia), inainte la frana.
	# Rotatia laterala e in jurul axei Z (fata), cea longitudinala in jurul X.
	var roll := clampf(_lat_g * LEAN_PER_G, -LEAN_MAX, LEAN_MAX)
	var pitch := clampf(-_lon_g * PITCH_PER_G, -PITCH_MAX, PITCH_MAX)
	if car.is_drifting:
		roll *= 1.35
	var extra: Dictionary = {
		&"Hips": Basis.IDENTITY,
		&"Torso": Basis.from_euler(Vector3(pitch, 0.0, roll)),
		&"Head": Basis.from_euler(Vector3(pitch * 0.6, steer * HEAD_YAW_STEER,
			roll * 0.5)),
		&"Arm_L": Basis.from_euler(Vector3(
			lerpf(-steer * ARM_STEER, ARMS_UP_AIR, _arms_up), 0.0, 0.0)),
		&"Arm_R": Basis.from_euler(Vector3(
			lerpf(steer * ARM_STEER, ARMS_UP_AIR, _arms_up), 0.0, 0.0)),
		&"Leg_L": Basis.IDENTITY,
		&"Leg_R": Basis.IDENTITY,
	}
	_apply_pose(extra)


## Compune ierarhia din transformarile de repaus: piesa copil pleaca din
## pozitia ei relativa fata de parinte, iar rotatia suplimentara se aplica in
## ORIGINEA piesei (articulatia) — de asta originile GLB-ului sunt in umeri,
## gat si solduri.
func _apply_pose(extra: Dictionary) -> void:
	var xf: Dictionary = {}
	for key in PART_NAMES:
		var rest: Transform3D = _rest[key]
		var local := Transform3D(rest.basis * (extra[key] as Basis), rest.origin)
		if PARENT.has(key):
			var parent: StringName = PARENT[key]
			var parent_rest: Transform3D = _rest[parent]
			xf[key] = (xf[parent] as Transform3D) * parent_rest.affine_inverse() * local
		else:
			xf[key] = local
		(_parts[key] as MeshInstance3D).transform = xf[key]


## Arunca figurina din masina: ascunde soferul asezat si intoarce ragdoll-ul,
## construit pe transformarile GLOBALE ale pieselor din acest cadru, ca sa
## plece exact de unde stateau. Cine cheama il pune in lume (nu sub masina).
## `fling` e viteza initiala (m/s, spatiul lumii) — a masinii de dinainte de
## impact plus un salt in sus, decisa de Car.
func eject(fling: Vector3, exclude: Array) -> ToyRagdoll:
	if _ejected or _parts.is_empty():
		return null
	var xforms: Dictionary = {}
	for key in PART_NAMES:
		xforms[key] = (_parts[key] as MeshInstance3D).global_transform
	_ejected = true
	visible = false
	var rag := ToyRagdoll.new()
	rag.name = "Ragdoll"
	rag.prepare(_scene, xforms, fling, exclude)
	return rag


## Soferul reapare pe scaun (la repunere). Poza se recalculeaza din primul tick.
func reseat() -> void:
	_ejected = false
	visible = true
	_lat_g = 0.0
	_lon_g = 0.0
	_arms_up = 0.0
	_prev_vel = car.velocity if car != null else Vector3.ZERO
