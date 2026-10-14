extends Node
## #491: TURBO apasat pe ecranul de incarcare misca masina jucatorului?
##
## Porneste cursa pe drumul din joc (GameState.start_race -> ecran de
## incarcare), apasa `turbo` din primul cadru si il tine apasat (sau il
## elibereaza la `--release=S` secunde), apoi scrie de 4 ori pe secunda starea
## cursei, pozitia si viteza jucatorului, pana la 3 s dupa GO.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLoadingTurbo.tscn -- --track=0 [--release=2.0] [--touch]
## `--touch` apasa butonul TURBO de pe ecran (GameState.touch_*) in loc de tasta.

var _t := 0.0
var _release := -1.0
var _touch := false
var _start_pos := Vector3.INF
var _go_t := -1.0
var _clock := 0.0
var _touched := false
## `--rocket`: tasta se apasa abia cu 0,5 s inainte de GO (rocket start
## legitim), nu de pe ecranul de incarcare — controlul ca fixul nu-l strica.
var _rocket := false


func _ready() -> void:
	var idx := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--release="):
			_release = float(arg.trim_prefix("--release="))
		elif arg == "--touch":
			_touch = true
		elif arg == "--rocket":
			_rocket = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Sonda supravietuieste schimbarii de scena: change_scene elibereaza
	# `current_scene`, deci i se da un manechin in locul sondei.
	var dummy := Node.new()
	get_tree().root.add_child.call_deferred(dummy)
	(func() -> void: get_tree().current_scene = dummy).call_deferred()
	GameState.selected_track = idx
	# Tasta se apasa acum; atingerea abia dupa start_race (care o reseteaza).
	if not _touch and not _rocket:
		_press(true)
	GameState.start_race.call_deferred()


func _press(on: bool) -> void:
	if _touch:
		GameState.touch_turbo = on
		GameState.touch_active = on
	elif on:
		Input.action_press("turbo")
	else:
		Input.action_release("turbo")


func _physics_process(delta: float) -> void:
	_t += delta
	if _release >= 0.0 and _t >= _release and _release < 1e8:
		_press(false)
		_release = 1e9
	var race := get_tree().current_scene as Race
	if race == null:
		return
	if _touch and not _touched and not _rocket:
		_touched = true
		_press(true)
	if race.player == null:
		return
	if _rocket and race.state == Race.State.COUNTDOWN \
			and race._countdown_left < 0.5 and not _touched:
		_touched = true
		_press(true)
	var p := race.player
	if _start_pos == Vector3.INF:
		_start_pos = p.global_position
	_clock += delta
	if race.state == Race.State.RUNNING and _go_t < 0.0:
		_go_t = _t
		print("[loading-turbo] GO la t=%.2f" % _t)
	if _clock >= 0.25:
		_clock = 0.0
		var moved := Vector2(p.global_position.x - _start_pos.x,
			p.global_position.z - _start_pos.z).length()
		print("[loading-turbo] t=%5.2f stare=%-9s deplasare=%5.2f m v=%5.2f turbo=%s boost=%s grila=%s activ=%s" % [
			_t, Race.State.keys()[race.state], moved, p.horizontal_speed(),
			Input.is_action_pressed("turbo") or GameState.touch_turbo,
			p.is_boosting, p.on_start_grid, p.race_active])
	if _go_t >= 0.0 and _t > _go_t + 3.0:
		get_tree().quit(0)
	if _t > 600.0:
		print("[loading-turbo] timeout")
		get_tree().quit(1)
