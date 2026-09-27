extends Node
## Lotul STANCA UDA (Fiordland/Track16): a ajuns `wet_gneiss` PE OBIECT, sau
## doar in numaratoare de materiale?
##
## Acelasi tipar ca tools/probe_capp_clase.gd (memoria
## `scatter-nu-primeste-clasele-temei`): un material in plus la probe_decor
## dovedeste ca s-a construit un material, nu ca o instanta anume l-a primit.
## Sonda umbla pe Track16 INCARCAT (nu pe .glb brut) si raporteaza, per model
## si per nod de mesh, cate MeshInstance3D au material_override == clasa
## wet_gneiss si cate au ramas pe materialul lumii (atlas).
##
## Ruleaza si pe Track15 (--track=15) ca sa arate ca moss_boulder de-acolo (tema
## "machupicchu") NU e atins de nimic scopat pe tema "fiordland" (memoria
## `probe-decor-numar-de-scena`: probe_decor/probe_manual iau numar de SCENA;
## asta ia indexul din GameState.TRACK_SCENES, ca ProbeCappClase).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordStancaClase.tscn -- --track=16
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordStancaClase.tscn -- --track=15

func _ready() -> void:
	await get_tree().process_frame
	var idx := 16
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	# call_deferred pe _apply_theme_classes/_remap_model_slots cere mai multe
	# cadre decat un singur process_frame (memoria `decor-ready-inaintea-temei`).
	for i in 10:
		await get_tree().process_frame
	var per_model := {}
	_walk(track, per_model)
	var keys: Array = per_model.keys()
	keys.sort()
	print("=== %s (tema citita din scena) ===" % GameState.track_label(idx))
	print("model                    nod            instante  wet_gneiss   fara")
	for k in keys:
		var d: Dictionary = per_model[k]
		for nod in (d["nodes"] as Dictionary):
			var e: Dictionary = (d["nodes"] as Dictionary)[nod]
			print("%-24s %-14s %8d %10d %6d" % [
				k, nod, int(e["n"]), int(e["cls"]), int(e["n"]) - int(e["cls"])])
	get_tree().quit(0)


func _walk(n: Node, acc: Dictionary) -> void:
	var model := n as Node3D
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/fiordland/"):
		var stem := model.scene_file_path.get_file().get_basename()
		if stem in ["chasm_rock", "guard_rock", "scree_slab", "stirling_ledge",
				"torrent_chute", "moss_boulder_a", "moss_boulder_b", "moss_boulder_c"]:
			if not acc.has(stem):
				acc[stem] = {"nodes": {}}
			for mi in _meshes(model):
				var nod := String((mi as Node).name)
				var nodes: Dictionary = acc[stem]["nodes"]
				if not nodes.has(nod):
					nodes[nod] = {"n": 0, "cls": 0}
				var e: Dictionary = nodes[nod]
				e["n"] = int(e["n"]) + 1
				var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
				if m != null and m == Palette.triplanar_class_material("wet_gneiss"):
					e["cls"] = int(e["cls"]) + 1
				nodes[nod] = e
			return
	# moss_boulder e in machupicchu/rocks/, nu fiordland/ — cautat separat mai
	# jos ca sa acopere si reuse-ul din Track15.
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/machupicchu/rocks/moss_boulder"):
		var stem2 := model.scene_file_path.get_file().get_basename()
		if not acc.has(stem2):
			acc[stem2] = {"nodes": {}}
		for mi in _meshes(model):
			var nod2 := String((mi as Node).name)
			var nodes2: Dictionary = acc[stem2]["nodes"]
			if not nodes2.has(nod2):
				nodes2[nod2] = {"n": 0, "cls": 0}
			var e2: Dictionary = nodes2[nod2]
			e2["n"] = int(e2["n"]) + 1
			var m2 := (mi as MeshInstance3D).material_override as StandardMaterial3D
			if m2 != null and m2 == Palette.triplanar_class_material("wet_gneiss"):
				e2["cls"] = int(e2["cls"]) + 1
			nodes2[nod2] = e2
		return
	for c in n.get_children():
		_walk(c, acc)


func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o
