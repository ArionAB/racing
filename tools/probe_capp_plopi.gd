extends Node
## Chiparosii ating solul? Dupa rescalarea la 3.5 m (runda 10) unii au ramas cu
## originea la cota veche, iar in captura de la 0.10 se vad plutind in cer.
## Sonda masoara, pentru fiecare plop din scena, distanta de la baza lui pana la
## terenul de sub el.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappPlopi.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sampler: TrackSideSampler = track._sampler
	var bad := 0
	var total := 0
	print("")
	print("=== chiparosi: baza fata de teren ===")
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if not (nd is Node3D):
			continue
		if not String(nd.name).begins_with("plop"):
			continue
		# Corpurile de coliziune generate de world_prop sunt copii cu numele
		# "<prop>_col" si origine LOCALA — nu sunt instante de plop si masurate
		# ca atare dau toate -24 m, adica zgomot care ascunde plopii reali.
		if String(nd.name).ends_with("_col"):
			continue
		var n3 := nd as Node3D
		total += 1
		var pos := n3.global_position
		var g := sampler.ground_y(pos.x, pos.z)
		var d := pos.y - g
		if absf(d) > 0.6:
			bad += 1
			print("  %-22s pos=(%7.1f,%7.2f,%7.1f) teren=%7.2f  DELTA=%+6.2f" % [
				n3.name, pos.x, pos.y, pos.z, g, d])
	print("  %d plopi, %d cu baza departe de teren (>0.6 m)" % [total, bad])
	print("")
	get_tree().quit(0)
