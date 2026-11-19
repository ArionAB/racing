class_name AmbienceCalls
extends Node
## Strigate rare de ambianta, POZITIONALE, legate de locuri (San Francisco: pescarusii de
## pe chei si de la capul de pod, leii de mare de pe pluta, papagalii din parcul cu
## chiparosi). Nodul-frate al lui [AmbienceBed]: unul tine un pat continuu, asta tine
## evenimente rare. Pus de generatorul pistei; pistele fara el raman cum erau.
##
## Fiecare LOC are un sunet, o raza, un interval si un volum. Un loc striga doar cat
## urechea (camera activa) e in raza lui, la un interval tras la intamplare intre
## `gap.x` si `gap.y`, si niciodata la mai putin de `global_gap_s` de ORICE alt strigat:
## golful e presarat, nu un zid de zgomot. Strigatul pleaca dintr-un punct tras la cel
## mult `scatter_m` de loc (pasarile nu stau intr-un singur punct).
##
## Nu are playere proprii: reda prin `AudioManager.play_sfx_at` cu prioritatea 0 (decor),
## pe cele 4 playere 3D comune. Prioritatea 0 nu fura niciodata un player de la un impact
## sau de la un hazard; daca toate patru sunt ocupate cu ceva mai important, strigatul se
## pierde. Deci locurile nu adauga noduri audio.
##
## Pe pista (.tscn), tablouri paralele, cate o intrare pe loc:
##   spot_pos = PackedVector3Array(...)        # lume
##   spot_sfx = Array[StringName]([&"gull_call", ...])
##   spot_radius = PackedFloat32Array(...)     # m, urechea in raza -> poate striga
##   spot_gap = PackedVector2Array(...)        # s, intervalul (min, max) intre doua strigate
##   spot_db = PackedFloat32Array(...)         # dB la sursa

@export var spot_pos: PackedVector3Array = PackedVector3Array()
@export var spot_sfx: Array[StringName] = []
@export var spot_radius: PackedFloat32Array = PackedFloat32Array()
@export var spot_gap: PackedVector2Array = PackedVector2Array()
@export var spot_db: PackedFloat32Array = PackedFloat32Array()
## Pauza minima intre oricare doua strigate (s).
@export var global_gap_s: float = 1.5
## Cat de departe de loc poate pleca un strigat (m, pe orizontala).
@export var scatter_m: float = 6.0
## Variatia de pitch a unui strigat (+-), ca doua pescarusi sa nu fie acelasi.
@export var pitch_spread: float = 0.08
## Cat de des se verifica locurile (s). Fara alocari: doar distante.
@export var check_every_s: float = 0.25

## Urechea, pentru sonde; gol = camera activa a viewport-ului.
var ear: Node3D = null
## Jurnalul strigatelor, pentru sonde: {t, spot, sfx, pos}. Plafonat la 64.
var call_log: Array[Dictionary] = []
## Generatorul de intervale; o sonda ii pune o samanta.
var rng := RandomNumberGenerator.new()

var _t: float = 0.0
var _check_left: float = 0.0
var _next: PackedFloat32Array = PackedFloat32Array()
var _global_until: float = 0.0


func _ready() -> void:
	rng.randomize()
	_next.resize(spot_pos.size())
	for i in _next.size():
		_next[i] = _t + rng.randf_range(0.5, 3.0)


func _process(delta: float) -> void:
	_t += delta
	_check_left -= delta
	if _check_left > 0.0 or spot_pos.is_empty():
		return
	_check_left = check_every_s
	var e := ear
	if e == null or not is_instance_valid(e):
		var vp := get_viewport()
		e = vp.get_camera_3d() if vp != null else null
	if e == null:
		return
	var p := e.global_position
	for i in spot_pos.size():
		var r := spot_radius[i] if i < spot_radius.size() else 60.0
		if p.distance_to(spot_pos[i]) > r:
			# In afara razei: primul strigat dupa intrare vine dupa o scurta pauza, nu pe loc.
			_next[i] = maxf(_next[i], _t + rng.randf_range(0.8, 2.5))
			continue
		if _t < _next[i] or _t < _global_until:
			continue
		var gap := spot_gap[i] if i < spot_gap.size() else Vector2(6.0, 12.0)
		_next[i] = _t + rng.randf_range(gap.x, gap.y)
		_global_until = _t + global_gap_s
		_call(i)


func _call(i: int) -> void:
	var sfx: StringName = spot_sfx[i] if i < spot_sfx.size() else &""
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null or sfx == &"":
		return
	var ang := rng.randf() * TAU
	var pos := spot_pos[i] + Vector3(cos(ang), 0.0, sin(ang)) * rng.randf() * scatter_m
	var db := spot_db[i] if i < spot_db.size() else -8.0
	var pl: Variant = manager.call("play_sfx_at", sfx, pos,
		1.0 + rng.randf_range(-pitch_spread, pitch_spread), db, 0, 0.0)
	call_log.append({"t": _t, "spot": i, "sfx": sfx, "pos": pos, "played": pl != null})
	if call_log.size() > 64:
		call_log.pop_front()
