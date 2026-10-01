extends Node
## Ecranul de incarcare pe DRUMUL REAL al jocului: GameState.start_race(), deci
## change_scene -> Race -> LoadingScreen -> pista -> numaratoare. Pentru fiecare
## pista tipareste duratele fazelor si timpul pana la READY?.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLoading.tscn
##   godot --path . res://tools/ProbeLoading.tscn -- --track=16 --shots
##
##   --track=N   o singura pista (pozitie sau numar de scena); implicit toate
##   --sync      drumul VECHI (change_scene direct, fara ecran): A/B pentru
##               timpul pana la READY? si pentru avertismentele din consola
##   --shots     CU FEREASTRA: salveaza in user:// cadrul desenat de mana la
##               cateva faze ale constructiei (dovada ca force_draw chiar
##               deseneaza ecranul, nu doar ca bara isi schimba scala)
##
## Sonda se muta singura sub radacina arborelui: change_scene elibereaza scena
## curenta, iar ea trebuie sa supravietuiasca de la o cursa la alta.

const SHOT_STEPS: Array[StringName] = [&"pregatire", &"umeri", &"umbre"]
const TIMEOUT_S: float = 180.0

var _queue: Array[int] = []
var _shots := false
var _sync := false
var _t0 := 0
var _rows: PackedStringArray = []
var _moved := false

func _ready() -> void:
	if not _moved:
		_moved = true
		var only := -1
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--track="):
				only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
			elif arg == "--shots":
				_shots = true
			elif arg == "--sync":
				_sync = true
		if _shots and DisplayServer.get_name() == "headless":
			push_error("ProbeLoading: --shots cere fereastra")
			get_tree().quit(2)
			return
		for i in GameState.TRACK_SCENES.size():
			if only < 0 or i == only:
				_queue.append(i)
		get_tree().node_added.connect(_on_node_added)
		# Sub radacina, ca sa nu fie eliberata de change_scene.
		_reparent_to_root.call_deferred()

func _reparent_to_root() -> void:
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	get_tree().current_scene = null
	_next()

func _next() -> void:
	if _queue.is_empty():
		print("\n".join(_rows))
		print("=== GATA ===")
		get_tree().quit(0)
		return
	var idx: int = _queue.pop_front()
	GameState.ai_count = 5
	if _sync:
		GameState.champ_active = false
		GameState.selected_track = idx
		get_tree().change_scene_to_file(GameState.RACE_SCENE)
	else:
		GameState.start_quick_race(idx)
	_t0 = Time.get_ticks_usec()
	_wait_for_countdown(idx)

func _wait_for_countdown(idx: int) -> void:
	var screen_times := {}
	while true:
		await get_tree().process_frame
		var race := get_tree().current_scene as Race
		if race != null:
			for c in race.get_children():
				if c is LoadingScreen:
					screen_times = (c as LoadingScreen).measured()
			if race.state == Race.State.COUNTDOWN and race.player != null:
				break
		if (Time.get_ticks_usec() - _t0) / 1000000.0 > TIMEOUT_S:
			_rows.append("%-14s TIMEOUT" % GameState.TRACK_NAMES[idx])
			_next()
			return
	var total := (Time.get_ticks_usec() - _t0) / 1000000.0
	var parts: PackedStringArray = []
	for p in LoadingScreen.PHASES:
		if screen_times.has(p):
			parts.append("%s %.2f" % [p, screen_times[p]])
	_rows.append("%-14s pana la READY? %5.1f s | %s" % [GameState.TRACK_NAMES[idx],
		total, ", ".join(parts)])
	print(_rows[-1])
	# Doua cadre de cursa, ca sa vedem ca fizica si HUD-ul pornesc fara erori.
	for i in 30:
		await get_tree().physics_frame
	_next()

func _on_node_added(n: Node) -> void:
	if _shots and n is Track:
		(n as Track).build_step.connect(_on_step.bind(n))

func _on_step(step: StringName, track: Track) -> void:
	if not SHOT_STEPS.has(step):
		return
	var img := get_viewport().get_texture().get_image()
	var path := "user://incarcare_%s_%s.png" % [track.name, step]
	img.save_png(path)
	print("captura %s -> %s" % [step, ProjectSettings.globalize_path(path)])
