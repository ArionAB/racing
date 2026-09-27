extends Node
## A ajuns clasa PE OBIECT (padurea de fagi, Fiordland), sau doar in
## numaratoare? Acelasi tipar ca probe_capp_clase.gd (memoria
## `sonda-masura-alt-obiect`): un material in plus la probe_decor dovedeste ca
## s-a construit un material, nu ca l-a primit cineva.
##
## Fiordland e tema pistei (`Track.theme_decor`), iar clasele beech intra prin
## CLASSES_BY_MODEL (nu CLASSES_BY_THEME), aplicate SINCRON din
## `_apply_model_classes()` in DecorManual._ready() — nu ar trebui sa aiba
## nevoie de call_deferred (spre deosebire de SLOT_REMAP_BY_THEME/
## CLASSES_BY_THEME, care citesc tema-stramos). Asteptam totusi cateva cadre,
## ca sa prindem orice alta ruptura amanata din lant (memoria
## `decor-ready-inaintea-temei`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordFagiClase.tscn -- --track=16

func _ready() -> void:
	await get_tree().process_frame
	var idx := 16
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 10:
		await get_tree().process_frame
	var per_model := {}
	_walk(track, per_model)
	var keys: Array = per_model.keys()
	keys.sort()
	print("model                       instante  clasate   fara  clase prezente")
	var total := 0
	var with_cls := 0
	for k in keys:
		var d: Dictionary = per_model[k]
		var by := PackedStringArray()
		for c in (d["by"] as Dictionary):
			by.append("%s=%d" % [c, d["by"][c]])
		print("%-28s %6d %8d %6d  %s" % [
			k, d["n"], d["cls"], d["n"] - d["cls"], " ".join(by)])
		total += int(d["n"])
		with_cls += int(d["cls"])
	print("TOTAL mesh-uri de kit: %d, cu clasa (bark_beech/beech_canopy): %d" %
		[total, with_cls])
	get_tree().quit(0)


func _walk(n: Node, acc: Dictionary) -> void:
	var model := n as Node3D
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/fiordland/plants/"):
		var stem := model.scene_file_path.get_file().get_basename()
		if not acc.has(stem):
			acc[stem] = {"n": 0, "cls": 0, "by": {}}
		for mi in _meshes(model):
			acc[stem]["n"] = int(acc[stem]["n"]) + 1
			var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
			var name := "?"
			if m != null and m.albedo_texture != null and m.uv1_triplanar:
				for cls in ["bark_beech", "beech_canopy"]:
					if m == Palette.triplanar_class_material(cls):
						name = cls
						break
			acc[stem]["by"][name] = int((acc[stem]["by"] as Dictionary).get(name, 0)) + 1
			if name != "?":
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
