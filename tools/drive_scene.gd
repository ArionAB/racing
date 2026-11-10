extends Node
## Conduci TU (tastatura / touch) o scena de pista care NU e in
## GameState.TRACK_SCENES — o sonda sintetica, o mostra, o pista inca neadaugata.
##
##   godot --path . res://tools/DriveScene.tscn -- --scene=res://tools/SondaSfAngkor.tscn
##   ... --ai=3      adversari (implicit 0: intai feel-ul de unul singur, CLAUDE.md)
##   ... --laps=5    ture (implicit 5)
##   ... --car=3     masina jucatorului, indice GameState.CAR_DATA (implicit: cea salvata)
##
## Cu FEREASTRA, fara --headless. Cursa porneste pe drumul SINCRON al lui
## `Race._ready` (fara ecran de incarcare), singurul care citeste
## `GameState.track_scene_override`; `start_race()` ar incarca
## `TRACK_SCENES[selected_track]` si ar ignora scena ceruta.
##
## [b]Recordurile nu se ating.[/b] `Race` scrie recordul de tur si de cursa sub
## numele pistei `selected_track` (indexul 0), deci un tur pe o sonda scurta ar
## bate recordul Dunelor din salvarea ta. Paznicul de mai jos ramane in arbore
## peste schimbarea de scena si pune la loc ambele dictionare (si fisierul) de
## cate ori cursa le schimba. Mesajul „NEW LAP RECORD" apare, dar nu ramane nimic.

class RecordGuard extends Node:
	var laps: Dictionary = {}
	var races: Dictionary = {}
	func _process(_d: float) -> void:
		if GameState.records != laps or GameState.race_records != races:
			GameState.records = laps.duplicate()
			GameState.race_records = races.duplicate()
			GameState.save_records()


func _ready() -> void:
	var scene := ""
	var ai := 0
	var laps := 5
	var car := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--ai="):
			ai = int(arg.trim_prefix("--ai="))
		elif arg.begins_with("--laps="):
			laps = int(arg.trim_prefix("--laps="))
		elif arg.begins_with("--car="):
			car = int(arg.trim_prefix("--car="))
	if scene == "" or not ResourceLoader.exists(scene):
		push_error("drive_scene: lipseste --scene=res://... (sau scena nu exista): '%s'" % scene)
		get_tree().quit(2)
		return
	var guard := RecordGuard.new()
	guard.name = "DriveSceneRecordGuard"
	guard.laps = GameState.records.duplicate()
	guard.races = GameState.race_records.duplicate()
	get_tree().root.add_child.call_deferred(guard)
	GameState.champ_active = false
	Career.leave()
	GameState.selected_track = 0
	GameState.track_scene_override = scene
	GameState.ai_count = clampi(ai, 0, 7)
	GameState.total_laps = maxi(laps, 1)
	if car >= 0 and car < GameState.CAR_DATA.size():
		GameState.selected_car = car
	print("drive_scene: %s | %d adversari, %d ture, masina %s" % [
		scene, GameState.ai_count, GameState.total_laps,
		(GameState.CAR_DATA[GameState.selected_car] as CarData).display_name])
	get_tree().change_scene_to_file.call_deferred("res://scenes/race/Race.tscn")
