extends Node
## A ajuns clasa PE OBIECT, sau doar in numaratoare?
##
## Un material in plus la `probe_decor` dovedeste ca s-a construit un material,
## nu ca l-a primit cineva — capcana din memoria `scatter-nu-primeste-clasele-temei`,
## unde o mapare corecta n-ajungea la obiect. Sonda umbla pe pista incarcata si
## raporteaza, per model, cate MeshInstance3D au `material_override` cu textura
## de clasa si cate au ramas pe materialul lumii.

##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappClase.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().process_frame
	var per_model := {}
	_walk(track, per_model)
	var keys: Array = per_model.keys()
	keys.sort()
	var with_cls := 0
	var total := 0
	print("model                       instante  tuff_cr   fara  clase prezente")
	for k in keys:
		var d: Dictionary = per_model[k]
		var by := PackedStringArray()
		for c in (d["by"] as Dictionary):
			by.append("%s=%d" % [c, d["by"][c]])
		print("%-28s %6d %8d %6d  %s" % [
			k, d["n"], d["cls"], d["n"] - d["cls"], " ".join(by)])
		with_cls += int(d["cls"])
		total += int(d["n"])
	print("TOTAL mesh-uri de kit: %d, cu tuff_cream: %d" % [total, with_cls])
	get_tree().quit(0)

func _walk(n: Node, acc: Dictionary) -> void:
	var model := n as Node3D
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/cappadocia/"):
		var stem := model.scene_file_path.get_file().get_basename()
		if not acc.has(stem):
			acc[stem] = {"n": 0, "cls": 0, "by": {}}
		for mi in _meshes(model):
			acc[stem]["n"] = int(acc[stem]["n"]) + 1
			var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
			if m == null or m.albedo_texture == null or not m.uv1_triplanar:
				continue
			# Identifica CLASA, nu doar "are o textura triplanara": rocile
			# purtau deja `rock_material()`, tot triplanar, dinainte de
			# maparile astea. Fara comparatia cu materialul clasei, sonda ar
			# raporta drept castig ceva ce exista deja.
			var name := "?"
			for cls in ["tuff_cream", "red_valley_tuff", "rock", "fresco"]:
				if m == Palette.triplanar_class_material(cls):
					name = cls
					break
			acc[stem]["by"][name] = int((acc[stem]["by"] as Dictionary).get(name, 0)) + 1
			if name == "tuff_cream":
				acc[stem]["cls"] = int(acc[stem]["cls"]) + 1
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
