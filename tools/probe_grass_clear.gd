extends SceneTree
## Sonda TEMPORARA de verificare non-regresie pentru degajarea de iarba din
## jurul prop-urilor (TrackGrass.prop_exclusions / GRASS_CLEAR_MODELS).
##
## Tipareste numarul de smocuri (grass_patches, suma pe toate nodurile
## DenseGrass) pentru pista ceruta. Se compara Track14 (steag ON) fata de
## Track09/Track13 (steag OFF, trebuie sa ramana NESCHIMBATE fata de main).
##
##   godot --headless --path . --script res://tools/probe_grass_clear.gd -- --track=14

func _initialize() -> void:
	var track_num := 14
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_num = int(arg.trim_prefix("--track="))
	var path := "res://scenes/tracks/Track%02d.tscn" % track_num
	if not ResourceLoader.exists(path):
		push_error("nu exista: %s" % path)
		quit(1)
		return
	var track := (load(path) as PackedScene).instantiate()
	root.add_child(track)
	await process_frame
	await process_frame
	await process_frame
	var total := 0
	var grass_nodes := 0
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n.name == &"DenseGrass":
			grass_nodes += 1
			var p := int(n.get_meta(&"grass_patches", 0))
			total += p
			print("  DenseGrass node: grass_patches=%d" % p)
	print("TRACK %s: DenseGrass roots=%d total_grass_patches=%d"
		% [path, grass_nodes, total])
	quit(0)
