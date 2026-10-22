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
##   · REACTII (feel_checklist: driver-reacts, driver-social), toate vizuale:
##     tresarire la impact (capul si trunchiul sar INAPOI de lovitura, revin
##     in ~0.4 s), tremur de brate pe teren aspru (viteza de compresie a
##     arcurilor), capul se intoarce spre masina de alaturi si, dupa ce esti
##     lovit de alta masina, o scurta agitare a pumnului (< 1 s).
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

## Tresarirea: cat se apleaca trunchiul (rad) la o izbitura maxima; capul
## adauga `FLINCH_HEAD_EXTRA` * asta peste trunchi (el il mosteneste deja).
const FLINCH_TORSO: float = 0.30
const FLINCH_HEAD_EXTRA: float = 0.9
## Arcul tresaririi: 26 rad/s, amortizare 0.3 -> sub 5% in 0.4 s.
const FLINCH_FREQ: float = 26.0
const FLINCH_DAMPING: float = 0.3
## Delta-v (m/s) la care tresarirea e plina.
const FLINCH_FULL_DV: float = 14.0
## Teren aspru: viteza TOTALA de compresie a arcurilor (m/s, suma pe 4 roti,
## netezita) sub care bratele stau pe volan si peste care tremura cu totul.
const ROUGH_MIN: float = 0.6
const ROUGH_FULL: float = 3.0
## Tremurul bratelor la teren aspru, plin (rad).
const ARM_JITTER: float = 0.22
## Privirea spre masina de alaturi: pe latura (m, centru la centru) si pe
## lungime (m), cat de mult se intoarce capul (rad max) si cat de repede.
const GLANCE_LATERAL_M: float = 4.0
const GLANCE_LONGITUDINAL_M: float = 2.5
const GLANCE_MAX_YAW: float = 0.9
const GLANCE_RATE: float = 7.0
## Pumnul: durata (s), cat de sus urca bratul (rad, inainte-sus) si de la ce
## delta-v lovit de alta masina il scoate.
const FIST_DURATION: float = 0.9
const FIST_RAISE: float = -1.9
const FIST_MIN_DV: float = 3.5

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
## Tresarirea: directia (spatiul masinii, orizontala) in care se duce capul si
## marimea in rad, cu viteza ei — un arc subamortizat.
var _flinch: Vector3 = Vector3.ZERO
var _flinch_vel: Vector3 = Vector3.ZERO
var _rough: float = 0.0
var _prev_comp: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _clock: float = 0.0
## Privirea spre masina alaturata: ponderea 0..1 si unghiul tinta (rad).
var _glance: float = 0.0
var _glance_yaw: float = 0.0
## Pumnul: timpul scurs (< 0 = inactiv), brat (+1 dreapta / -1 stanga) si
## unghiul capului spre cel care te-a lovit.
var _fist_t: float = -1.0
var _fist_side: float = 1.0
var _fist_yaw: float = 0.0


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
	_clock += delta
	_update_reactions(delta)

	# Trunchiul se lasa IN AFARA virajului (inertia), inainte la frana.
	# Rotatia laterala e in jurul axei Z (fata), cea longitudinala in jurul X.
	var roll := clampf(_lat_g * LEAN_PER_G, -LEAN_MAX, LEAN_MAX)
	var pitch := clampf(-_lon_g * PITCH_PER_G, -PITCH_MAX, PITCH_MAX)
	if car.is_drifting:
		roll *= 1.35
	# Tresarirea: trunchiul si capul se apleaca spre `_flinch` (varful se duce
	# spre el: rotatie in jurul lui UP x _flinch).
	var torso_flinch := _tilt_basis(_flinch)
	var head_flinch := _tilt_basis(_flinch * FLINCH_HEAD_EXTRA)
	# Capul: priveste in viraj, dar cat timp cineva e alaturi sau tocmai te-a
	# lovit, se intoarce spre el (privirea castiga treptat, nu brusc).
	var look := _glance
	var look_yaw := _glance_yaw
	var fist := _fist_envelope()
	if fist > 0.0:
		look_yaw = lerpf(look_yaw, _fist_yaw, fist)
		look = maxf(look, fist)
	var head_yaw := lerpf(steer * HEAD_YAW_STEER, look_yaw, look)
	# Bratele: pe volan / in aer, plus tremur pe teren aspru.
	var rough_t := clampf(inverse_lerp(ROUGH_MIN, ROUGH_FULL, _rough), 0.0, 1.0)
	var jit_l := rough_t * ARM_JITTER * (
		0.6 * sin(_clock * 47.0) + 0.4 * sin(_clock * 31.3 + 1.7))
	var jit_r := rough_t * ARM_JITTER * (
		0.6 * sin(_clock * 43.0 + 2.1) + 0.4 * sin(_clock * 29.7 + 0.4))
	var arm_l := Basis.from_euler(Vector3(
		lerpf(-steer * ARM_STEER, ARMS_UP_AIR, _arms_up) + jit_l, 0.0, 0.0))
	var arm_r := Basis.from_euler(Vector3(
		lerpf(steer * ARM_STEER, ARMS_UP_AIR, _arms_up) + jit_r, 0.0, 0.0))
	if fist > 0.0:
		var shake := fist * sin(_fist_t * 34.0)
		var raised := Basis.from_euler(Vector3(
			lerpf(0.0, FIST_RAISE, fist) + shake * 0.3, 0.0, shake * 0.35))
		if _fist_side > 0.0:
			arm_r = raised
		else:
			arm_l = raised
	var extra: Dictionary = {
		&"Hips": Basis.IDENTITY,
		&"Torso": torso_flinch * Basis.from_euler(Vector3(pitch, 0.0, roll)),
		&"Head": head_flinch * Basis.from_euler(Vector3(pitch * 0.6, head_yaw,
			roll * 0.5)),
		&"Arm_L": arm_l,
		&"Arm_R": arm_r,
		&"Leg_L": Basis.IDENTITY,
		&"Leg_R": Basis.IDENTITY,
	}
	_apply_pose(extra)


## Rotatia care apleaca VARFUL (UP) spre `tilt` (vector orizontal, lungime =
## unghi in rad). Identitate pentru un vector nul.
static func _tilt_basis(tilt: Vector3) -> Basis:
	if tilt.length_squared() < 1e-10:
		return Basis.IDENTITY
	return Basis(Vector3.UP.cross(tilt).normalized(), tilt.length())


## Varful deplasarii pe unitatea de viteza data arcului la lovitura (arc
## subamortizat din repaus) — ca `FLINCH_TORSO` sa fie varful REAL.
static func _flinch_peak_per_velocity() -> float:
	var w := FLINCH_FREQ
	var z := FLINCH_DAMPING
	var wd := w * sqrt(1.0 - z * z)
	var tp := atan2(wd, z * w) / wd
	return exp(-z * w * tp) * sin(wd * tp) / wd


## Directia (spatiul masinii) spre cea mai apropiata masina „alaturi" — in
## frecare cu noi sau in `GLANCE_LATERAL_M` pe lateral — sau ZERO.
func _alongside_direction() -> Vector3:
	if car.rub_car != null:
		var d := car.to_local(car.rub_car.global_position)
		d.y = 0.0
		return d
	var best := Vector3.ZERO
	var best_x := GLANCE_LATERAL_M
	for node in car.get_tree().get_nodes_in_group(&"cars"):
		var other := node as Car
		if other == null or other == car:
			continue
		var d := car.to_local(other.global_position)
		d.y = 0.0
		if absf(d.z) < GLANCE_LONGITUDINAL_M and absf(d.x) < best_x \
				and absf(d.x) > 0.8:
			best_x = absf(d.x)
			best = d
	return best


## Unghiul capului (rad, in jurul lui Y) ca sa priveasca spre `d` (spatiul
## masinii; fata = -Z), limitat la cat poate un gat.
static func _yaw_toward(d: Vector3) -> float:
	return clampf(atan2(-d.x, -d.z), -1.1, 1.1)


## Izbitura primita de masina (din `Car._on_impact_visual`): tresarire, iar
## daca o alta masina te-a lovit, pornesc privirea si pumnul. `n_local` e
## normala (dinspre obstacol spre noi) in spatiul masinii; capul se duce INAPOI
## de ea, spre obstacol. `victim` = nu mergeam noi spre cealalta masina.
func react_impact(kind: StringName, strength: float, n_local: Vector3,
		victim: bool) -> void:
	if _ejected:
		return
	var k := clampf(sqrt(maxf(strength, 0.0) / FLINCH_FULL_DV), 0.0, 1.0)
	n_local.y = 0.0
	if n_local.length_squared() > 1e-6:
		var away := -n_local.normalized()
		_flinch_vel += away * (FLINCH_TORSO * k / maxf(_flinch_peak_per_velocity(), 1e-5))
		if kind == &"car" and victim and strength >= FIST_MIN_DV:
			_fist_t = 0.0
			_fist_side = 1.0 if away.x >= 0.0 else -1.0
			_fist_yaw = _yaw_toward(away)


## 0..1: cat de sus e pumnul acum (urcare rapida, coborare la sfarsit).
func _fist_envelope() -> float:
	if _fist_t < 0.0:
		return 0.0
	return smoothstep(0.0, 0.15, _fist_t) \
		* (1.0 - smoothstep(FIST_DURATION - 0.2, FIST_DURATION, _fist_t))


## Starea reactiilor, un pas: arcul tresaririi, aspritatea terenului, privirea
## spre masina alaturata si ceasul pumnului.
func _update_reactions(delta: float) -> void:
	var dt := minf(delta, 0.05)
	var w := FLINCH_FREQ
	var z := FLINCH_DAMPING
	var sp := Car.spring_step(_flinch, _flinch_vel, w, z, dt)
	_flinch = sp[0]
	_flinch_vel = sp[1]
	_flinch = _flinch.limit_length(FLINCH_TORSO * 1.3)
	# Aspritate: cat de repede se misca arcurile (suma modulelor), netezit.
	var comp_speed := 0.0
	for i in 4:
		var c := car.wheel_compression[i]
		comp_speed += absf(c - _prev_comp[i]) / maxf(delta, 0.0001)
		_prev_comp[i] = c
	if car.wheels_on_ground == 0:
		comp_speed = 0.0
	_rough = lerpf(_rough, comp_speed, 1.0 - exp(-10.0 * dt))
	# Privirea spre cine e alaturi.
	var d := _alongside_direction()
	var want := 0.0
	if d != Vector3.ZERO:
		want = 1.0
		_glance_yaw = clampf(_yaw_toward(d), -GLANCE_MAX_YAW, GLANCE_MAX_YAW)
	_glance = lerpf(_glance, want, 1.0 - exp(-GLANCE_RATE * dt))
	if _fist_t >= 0.0:
		_fist_t += delta
		if _fist_t >= FIST_DURATION:
			_fist_t = -1.0


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
	_flinch = Vector3.ZERO
	_flinch_vel = Vector3.ZERO
	_fist_t = -1.0
	_glance = 0.0
	_prev_vel = car.velocity if car != null else Vector3.ZERO
