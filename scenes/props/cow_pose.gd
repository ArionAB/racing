class_name CowPose
extends Node
## POZA VACII DIN ULICIOARA (Jodhpur, Track17, POI D′) — doar vizualul.
##
## `CowGate` muta corpul vacii intre prag si gura si tine starea porții, dar nu
## reda nicio animatie: `zebu_cow.glb` are schelet si clipurile `Stand`,
## `Walk`, `LieDown`, `Lie`, `GetUp`, iar fara ele vaca statea IN PICIOARE si
## cand era „culcata" in gura. Vaca culcata = scurtatura inchisa e chiar
## semnalul gimmick-ului, deci poza trebuie sa spuna starea.
##
## Nodul asta CITESTE starea (`CowGate.current_state()` / `is_pending()`) si
## misca doar modelul: clipul din AnimationPlayer si rotatia modelului in jurul
## verticalei lui. NU scrie nimic in poarta — nici ceas, nici stare, nici
## transformul corpului, nici cutia de coliziune (care ramane cea din
## `CowGate._build_model`). Logica portii si regula de siguranta raman exact
## cum sunt; stergerea nodului readuce vaca statuie, nimic altceva.
##
## Orientarea: corpul portii priveste cu -Z pe laterala benzii, spre PRAG
## (`Basis.looking_at(side)`), iar capul modelului e pe -Z (clopotelul la
## z = -1,08). Deci vaca se intoarce spre gura in telegraph-ul de plecare
## (rotatie de 180° a modelului, nu a corpului) si merge cu botul inainte in
## ambele sensuri, in loc sa mearga cu spatele spre gura.

## Cat dureaza intoarcerea de 180° pe loc (s). Incape in telegraph (3 s).
@export_range(0.3, 3.0, 0.1, "suffix:s") var turn_seconds: float = 1.6

const CLIP_STAND := &"Stand"
const CLIP_WALK := &"Walk"
const CLIP_LIE_DOWN := &"LieDown"
const CLIP_LIE := &"Lie"
const CLIP_GET_UP := &"GetUp"

var _gate: CowGate = null
var _model: Node3D = null
var _ap: AnimationPlayer = null
var _last_state: int = -1
var _state_t: float = 0.0
var _yaw: float = 0.0
var _tries: int = 0


func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint():
		return
	_bind.call_deferred()


## Gaseste poarta (grupul de porti de banda, primul `CowGate`) si modelul carat
## de corpul ei. Poarta isi construieste corpul in `_ready`, deci dupa un cadru
## modelul exista; reincearca cateva cadre pentru ordinile ciudate de sonda.
func _bind() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(Track.BRANCH_GATE_GROUP):
		if n is CowGate:
			_gate = n as CowGate
			break
	if _gate != null:
		var body := _gate.get_node_or_null("CowBody")
		if body != null:
			for c in body.get_children():
				if c is Node3D and not (c is CollisionShape3D):
					var aps := c.find_children("*", "AnimationPlayer", true, false)
					if not aps.is_empty():
						_model = c as Node3D
						_ap = aps[0] as AnimationPlayer
						break
	if _ap == null:
		_tries += 1
		if _tries < 30:
			get_tree().process_frame.connect(_bind, CONNECT_ONE_SHOT)
		return
	for clip in [CLIP_STAND, CLIP_WALK, CLIP_LIE]:
		if _ap.has_animation(clip):
			_ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	set_process(true)


func _process(delta: float) -> void:
	if _gate == null or _ap == null:
		return
	var s := _gate.current_state()
	if s != _last_state:
		_enter(s)
		_last_state = s
		_state_t = 0.0
	else:
		_state_t += delta
	# Mersul inghetat de regula de siguranta (vaca asteapta sa treaca masina):
	# picioarele stau, nu patineaza pe loc.
	var walking := s == CowGate.State.WALKING_TO_MOUTH or s == CowGate.State.WALKING_TO_THRESHOLD
	_ap.speed_scale = 0.0 if (walking and _gate.is_pending()) else 1.0
	# Rotatia: spre gura (PI) din telegraph-ul de plecare pana se ridica din
	# gura; spre prag (0) dupa ce s-a ridicat.
	var target := _target_yaw(s)
	_yaw = move_toward(_yaw, target, delta * PI / maxf(turn_seconds, 0.01))
	_model.rotation.y = _yaw


func _target_yaw(s: int) -> float:
	match s:
		CowGate.State.RISING_TO_MOUTH, CowGate.State.WALKING_TO_MOUTH, \
				CowGate.State.LYING_IN_MOUTH:
			return PI
		CowGate.State.RISING_TO_THRESHOLD:
			# Intai se ridica (GetUp), abia apoi se intoarce spre prag.
			return PI if _state_t < _clip_len(CLIP_GET_UP) else 0.0
	return 0.0


func _enter(s: int) -> void:
	match s:
		CowGate.State.ON_THRESHOLD, CowGate.State.RISING_TO_MOUTH:
			_play(CLIP_STAND)
		CowGate.State.WALKING_TO_MOUTH, CowGate.State.WALKING_TO_THRESHOLD:
			_play(CLIP_WALK)
		CowGate.State.LYING_IN_MOUTH:
			_play(CLIP_LIE_DOWN)
			if _ap.has_animation(CLIP_LIE):
				_ap.queue(CLIP_LIE)
		CowGate.State.RISING_TO_THRESHOLD:
			_play(CLIP_GET_UP)
			if _ap.has_animation(CLIP_STAND):
				_ap.queue(CLIP_STAND)


func _play(clip: StringName) -> void:
	if _ap.has_animation(clip):
		_ap.clear_queue()
		_ap.play(clip, 0.25)


func _clip_len(clip: StringName) -> float:
	return _ap.get_animation(clip).length if _ap != null and _ap.has_animation(clip) else 0.0


## Pentru capturi (`tools/snapshot.gd --cow=stand|lie`): poza FINALA a starii,
## fara tranzitie — culcata cu `Lie`, sau in picioare pe prag cu `Stand` —
## aplicata imediat (seek cu update), fiindca Snapshot nu ruleaza ciclul.
## Nu schimba starea portii: o citeste, ca in joc.
func snap_to_state() -> void:
	if _gate == null or _ap == null:
		return
	var s := _gate.current_state()
	_last_state = s
	_state_t = 999.0
	var lying := s == CowGate.State.LYING_IN_MOUTH
	var clip := CLIP_LIE if lying else CLIP_STAND
	if _ap.has_animation(clip):
		_ap.clear_queue()
		_ap.play(clip)
		_ap.seek(0.0, true)
	_yaw = _target_yaw(s)
	_model.rotation.y = _yaw


func is_bound() -> bool:
	return _ap != null
