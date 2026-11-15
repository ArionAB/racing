extends Node
## Garda registrului [MeshCpu]: construieste o pista cu `MeshCpu.verify`, deci
## fiecare raspuns servit din registru (o citire refolosita, sau pozitiile tinute
## de la urcare) se compara la bit cu o citire reala de pe GPU. Prinde in
## special scrierea prin referinta in array-urile tinute (vezi
## `MeshCpu.surface_arrays`). Iese cu 1 daca exista vreo diferenta SAU daca toata
## rularea n-a verificat nimic (o garda pe zero masuratori nu dovedeste nimic).
## O pista fara decor procedural pe mesh-uri (Dunele, Alpii...) are legitim zero
## citiri; de-aia pragul e pe total, nu pe pista.
##
##   godot --headless --path . res://tools/ProbeMeshCpu.tscn -- --track=6
##   godot --headless --path . res://tools/ProbeMeshCpu.tscn          # toate

func _ready() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			# index / numar de scena, sau "Track13" / "cappadocia" (#718)
			var track_arg := arg.trim_prefix("--track=")
			only = GameState.resolve_track_arg(track_arg)
			if only < 0:
				push_error("probe_mesh_cpu: pista invalida %s" % track_arg)
				get_tree().quit(2)
				return
			print("probe_mesh_cpu: pista %s" % GameState.track_arg_label(track_arg, only))
	MeshCpu.verify = true
	var bad := 0
	var total := 0
	for i in GameState.TRACK_SCENES.size():
		if only >= 0 and i != only:
			continue
		MeshCpu.verify_checked = 0
		MeshCpu.verify_mismatch = 0
		MeshCpu.verify_first = ""
		var track := (load(GameState.TRACK_SCENES[i]) as PackedScene).instantiate()
		add_child(track)
		var ok := MeshCpu.verify_mismatch == 0
		total += MeshCpu.verify_checked
		print("%-16s citiri din registru %6d, diferente %d %s" % [
			GameState.TRACK_NAMES[i], MeshCpu.verify_checked,
			MeshCpu.verify_mismatch, MeshCpu.verify_first])
		if not ok:
			bad += 1
		remove_child(track)
		track.free()
	if total == 0:
		print("MeshCpu: PICA — zero citiri verificate, registrul nu e conectat")
		bad += 1
	else:
		print("MeshCpu: %s (%d citiri verificate)" % [
			"OK" if bad == 0 else "%d piste PICA" % bad, total])
	get_tree().quit(0 if bad == 0 else 1)
