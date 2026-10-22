extends Node
## Legaturile din Race: ImpactFeel exista, e cablat la jucator si la camera, si
## hit-stop-ul nu ruleaza in numaratoare, ci doar in cursa, apoi se opreste la
## final. Incarca Race.tscn REAL (celelalte sonde de camera construiesc lumi
## de mana si nu vad race.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeImpactWiring.tscn

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== Race: ImpactFeel cablat ===")
	GameState.total_laps = 1
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(race)
	# Asteapta sa existe jucatorul si camera (dupa ecranul de incarcare).
	var guard := 0
	while (race.get("impact_feel") == null) and guard < 1500:
		await get_tree().process_frame
		guard += 1
	var feel: Node = race.get("impact_feel")
	_check(feel != null, "Race.impact_feel construit (dupa %d cadre)" % guard)
	if feel == null:
		_finish()
		return
	var player: Car = race.player
	var cam: ChaseCamera = race.camera
	_check(player.impact.get_connections().size() >= 1, "Car.impact are consumator")
	# Numaratoarea: kick da, hit-stop nu.
	_check(race.state == race.State.COUNTDOWN, "cursa e inca in numaratoare")
	player.impact.emit(player, &"wall", 16.0, Vector3.BACK, Vector3.ZERO, null)
	_check(Engine.time_scale == 1.0, "numaratoare: fara hit-stop")
	await get_tree().physics_frame
	_check(cam.kick_offset().length() > 0.1, "numaratoare: camera primeste kick")
	# Cursa pornita.
	guard = 0
	while race.state != race.State.RUNNING and guard < 1500:
		await get_tree().process_frame
		guard += 1
	_check(race.state == race.State.RUNNING, "cursa a pornit")
	await get_tree().create_timer(1.0, true, false, true).timeout
	player.impact.emit(player, &"wall", 16.0, Vector3.BACK, Vector3.ZERO, null)
	_check(Engine.time_scale < 0.1, "in cursa: izbitura mare ingheata")
	# Final de cursa => time_scale readus.
	race.call("_finish_race")
	_check(Engine.time_scale == 1.0, "final de cursa: time_scale 1.0")
	_finish()


func _finish() -> void:
	Engine.time_scale = 1.0
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)
