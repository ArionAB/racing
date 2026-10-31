class_name StrideDriver
extends Node
## Pasul unui animal cu picioare rigide, legat de DISTANTA parcursa (#613).
##
## Problema: clipul `Walk` al elefantului invartea picioarele dupa timp
## (viteza de redare = viteza / constanta), cu un pendul sinusoidal de 14 grade
## si fara nicio faza de zbor: laba nu se ridica niciodata, deci animalul patina
## pe loc cat vreme picioarele se legana. Aici faza vine din metri, nu din
## secunde: `phase += metri / lungimea_pasului`. Cat un picior sta pe sol
## (stance), laba aluneca inapoi in raport cu corpul EXACT cu viteza corpului,
## deci in lume sta pe loc — fara patinaj, la orice viteza. Parcat, amplitudinea
## se stinge la zero (picioare drepte, nu inghetate in plin pas).
##
## Se aplica pe scheletul GLB-ului (oasele `LegFL/FR/RL/RR`, `Body`). Clipul
## are piste pe aceleasi oase si le-ar rescrie la fiecare cadru, deci [method
## attach] le scoate din `Walk` (restul clipului — trompa, urechi, coada —
## ramane). Rotatia se face in jurul soldului (capul osului), in spatiul
## scheletului, deci nu depinde de orientarea osului in GLB.

const LEGS := {
	&"LegFL": 0.0, &"LegRR": 0.0, # perechi diagonale
	&"LegFR": 0.5, &"LegRL": 0.5,
}
const BODY := &"Body"

## Cat din ciclu sta laba pe sol (restul = zbor). Peste 0.5 ca mereu sa sprijine
## cel putin o pereche.
@export_range(0.5, 0.8, 0.01) var stance: float = 0.6
## Balansul piciorului fata/spate fata de verticala (grade).
@export_range(5.0, 35.0, 0.5) var swing_deg: float = 20.0
## Cat se ridica laba in zbor (fractie din lungimea piciorului).
@export_range(0.0, 0.2, 0.005) var lift: float = 0.05
## Saltul corpului la fiecare pas (fractie din lungimea piciorului).
@export_range(0.0, 0.05, 0.001) var bob: float = 0.012
## Cat de repede se stinge/revine amplitudinea (1/s) cand animalul porneste/se opreste.
@export_range(1.0, 20.0, 0.5) var amp_rate: float = 6.0

var phase: float = 0.0
var amp: float = 0.0
var _sk: Skeleton3D
var _leg_idx := {}
var _leg_hip := {}   # os -> pozitia soldului in spatiul scheletului (repaus)
var _leg_rest := {}  # os -> transform local de repaus
var _body_idx: int = -1
var _body_rest := Transform3D.IDENTITY
var _leg_len: float = 1.0
var _world_scale: float = 1.0
var _moved: float = 0.0
## Pentru sonde/sabotaj: oprit, oasele raman cum le-a lasat clipul.
var enabled: bool = true


## Cauta scheletul si oasele; scoate din `Walk` pistele pe care le conduce
## codul. Intoarce false daca modelul nu are oasele cerute (alte animale).
func attach(model: Node, walk_anim: Animation) -> bool:
	var sks := model.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return false
	_sk = sks[0] as Skeleton3D
	for leg: StringName in LEGS:
		var i := _sk.find_bone(String(leg))
		if i < 0:
			return false
		_leg_idx[leg] = i
	_body_idx = _sk.find_bone(String(BODY))
	if _body_idx < 0:
		return false
	_body_rest = _sk.get_bone_rest(_body_idx)
	var h := 0.0
	for leg: StringName in LEGS:
		var i: int = _leg_idx[leg]
		var rest := _sk.get_bone_global_rest(i)
		_leg_hip[leg] = rest.origin
		_leg_rest[leg] = _sk.get_bone_rest(i)
		h = maxf(h, rest.origin.y)
	_leg_len = maxf(h, 0.5) # laba la y = 0 in spatiul scheletului
	if walk_anim != null:
		_strip_tracks(walk_anim)
	_world_scale = _sk.global_transform.basis.get_scale().x
	return true


func _strip_tracks(anim: Animation) -> void:
	for t in range(anim.get_track_count() - 1, -1, -1):
		var bone := String(anim.track_get_path(t).get_concatenated_subnames())
		if StringName(bone) in LEGS or StringName(bone) == BODY:
			anim.remove_track(t)


## Lungimea pasului (m in lume): cat parcurge corpul intr-un ciclu intreg, ca
## laba sa stea pe sol exact cat dureaza `stance`.
func stride_length() -> float:
	var travel := 2.0 * _leg_len * sin(deg_to_rad(swing_deg))
	return travel / stance * _world_scale


func advance(meters: float, delta: float) -> void:
	if _sk == null or not enabled:
		return
	_moved = meters
	var moving := delta > 0.0 and meters / delta > 0.15
	amp = move_toward(amp, 1.0 if moving else 0.0, amp_rate * delta)
	phase = fposmod(phase + meters / maxf(stride_length(), 0.01), 1.0)
	_apply()


func _apply() -> void:
	# Corpul primul: soldurile picioarelor se rezolva pe pozitia lui de acum.
	var bob_amt := bob * _leg_len * amp * absf(sin(phase * TAU))
	var body_pose := _body_rest
	# translatia in spatiul PARINTELUI (scheletul): sus = +Y al scheletului
	body_pose.origin += _parent_basis_inv(_body_idx) * Vector3(0.0, bob_amt, 0.0)
	_sk.set_bone_pose(_body_idx, body_pose)
	var swing := deg_to_rad(swing_deg) * amp
	for leg: StringName in LEGS:
		var i: int = _leg_idx[leg]
		var phi := fposmod(phase + float(LEGS[leg]), 1.0)
		var theta := 0.0
		var up := 0.0
		if phi < stance:
			theta = swing * (1.0 - 2.0 * phi / stance)
		else:
			var u := (phi - stance) / (1.0 - stance)
			theta = swing * (-1.0 + 2.0 * smoothstep(0.0, 1.0, u))
			up = lift * _leg_len * amp * sin(PI * u)
		var parent := _sk.get_bone_parent(i)
		var parent_g := _sk.get_bone_global_pose(parent)
		var rest_g: Transform3D = parent_g * _leg_rest[leg]
		# Rotatie in jurul soldului, axa X a scheletului (lateral). Pozitiv =
		# laba spre fata (-Z), cum merge modelul dupa #502.
		var hip: Vector3 = rest_g.origin
		var rot := Transform3D(Basis(Vector3.RIGHT, theta), Vector3.ZERO)
		var about_hip := Transform3D(Basis.IDENTITY, hip) * rot * Transform3D(Basis.IDENTITY, -hip)
		var desired := Transform3D(Basis.IDENTITY, Vector3(0.0, up, 0.0)) * about_hip * rest_g
		_sk.set_bone_pose(i, parent_g.affine_inverse() * desired)


func _parent_basis_inv(i: int) -> Basis:
	var p := _sk.get_bone_parent(i)
	if p < 0:
		return Basis.IDENTITY
	return _sk.get_bone_global_pose(p).basis.inverse()
