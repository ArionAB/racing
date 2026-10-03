class_name SikaBow
extends Node
## CERBUL SIKA CARE SE INCLINA (Kyoto, Track18, POI D; brief kyoto.md §1, §5.6).
##
## Se pune ca nod COPIL al instantei `animals/sika_deer.glb` din DecorManual.
## Cerbul sta in `Stand` (bucla); cand o masina trece la mai putin de
## `trigger_m` de el, joaca o data `Bow`, apoi revine la `Stand`. Pauza
## `cooldown_s` intre doua plecaciuni, ca plutonul sa nu-l tina aplecat.
##
## Doar vizual, opt-in: nu are corp, nu scrie nimic in masini sau in pista,
## citeste doar pozitiile din grupul `cars`. Stergerea nodului readuce cerbul
## static in poza de repaus. Proximitate pe distanta (nu Area3D), verificata
## de 5 ori pe secunda: un cerb, 8 masini, cost neglijabil.

@export_range(4.0, 60.0, 0.5, "suffix:m") var trigger_m: float = 22.0
@export_range(0.5, 30.0, 0.1, "suffix:s") var cooldown_s: float = 5.0
@export var idle_clip: StringName = &"Stand"
@export var bow_clip: StringName = &"Bow"

const _CHECK_S: float = 0.2

var _deer: Node3D = null
var _ap: AnimationPlayer = null
var _cool: float = 0.0
var _tick: float = 0.0


func _ready() -> void:
	set_physics_process(false)
	if Engine.is_editor_hint():
		return
	_bind.call_deferred()


func _bind() -> void:
	_deer = get_parent() as Node3D
	if _deer == null:
		return
	var aps := _deer.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty():
		return
	_ap = aps[0] as AnimationPlayer
	if not _ap.has_animation(bow_clip):
		return
	if _ap.has_animation(idle_clip):
		_ap.get_animation(idle_clip).loop_mode = Animation.LOOP_LINEAR
		_ap.play(idle_clip)
	_ap.animation_finished.connect(_on_finished)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_cool -= delta
	_tick -= delta
	if _tick > 0.0 or _cool > 0.0:
		return
	_tick = _CHECK_S
	var p := _deer.global_position
	var r2 := trigger_m * trigger_m
	for c in get_tree().get_nodes_in_group(&"cars"):
		var n3 := c as Node3D
		if n3 != null and n3.global_position.distance_squared_to(p) < r2:
			bow()
			return


## Pleaciunea (publica, ca sondele/capturile s-o poata forta).
func bow() -> void:
	if _ap == null:
		return
	_ap.play(bow_clip, 0.25)
	_cool = cooldown_s


func _on_finished(clip: StringName) -> void:
	if clip == bow_clip and _ap.has_animation(idle_clip):
		_ap.play(idle_clip, 0.3)
