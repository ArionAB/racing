extends Node
## SONDA TEMPORARA — dovada ca Stromboli (Track11, LavaFlowHazard) e
## NESCHIMBAT dupa generalizarea Track.branch_is_open (grupul BRANCH_GATE_GROUP,
## Jodhpur/sonda-vaca). Compara, la fiecare stadiu de lava, raspunsul metodei
## generalizate cu apelul DIRECT pe hazard (lava.shortcut_open()) — daca cele
## doua diverg vreodata, generalizarea a stricat ceva pentru Stromboli.
##
##   godot --headless --fixed-fps 60 --path . res://tools/VerifyStromboliUnchanged.tscn

func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track11.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var lavas: Array[LavaFlowHazard] = []
	for child in track.get_children():
		if child is LavaFlowHazard:
			lavas.append(child as LavaFlowHazard)
	print("=== Verificare Stromboli neschimbat (branch_is_open generalizat) ===")
	print("LavaFlowHazard gasite: %d" % lavas.size())

	var failed := false
	for lava in lavas:
		print("  %s: branch_index=%d in grupul '%s'? %s" % [
			lava.name, lava.branch_index, Track.BRANCH_GATE_GROUP,
			lava.is_in_group(Track.BRANCH_GATE_GROUP)])
		if not lava.is_in_group(Track.BRANCH_GATE_GROUP):
			failed = true

	# Simuleaza cele 3 stadii (start, dupa 1 tur, dupa 2 tururi) si compara
	# Track.branch_is_open(1) cu apelul direct pe FIECARE LavaFlowHazard care
	# raspunde de branch_index 1 — trebuie sa fie identice la fiecare stadiu.
	for stage in range(3):
		if stage > 0:
			for lava in lavas:
				lava.on_lap_completed()
		var direct := true
		for lava in lavas:
			if lava.branch_index == 1:
				direct = lava.shortcut_open()
		var generalized := track.branch_is_open(1)
		var match_ok := direct == generalized
		if not match_ok:
			failed = true
		print("  stadiu %d: shortcut_open() direct=%s · branch_is_open(1) generalizat=%s · %s"
			% [stage, direct, generalized, "OK" if match_ok else "DIVERGENTA!"])

	print("=== %s ===" % ("PROBLEME" if failed else "STROMBOLI NESCHIMBAT — TOATE OK"))
	get_tree().quit(1 if failed else 0)
