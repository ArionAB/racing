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
	print("model                    nod                    instante  wet_gneiss   fara  sloturi in mesh (o instanta)")
	for k in keys:
		var d: Dictionary = per_model[k]
		for nod in (d["nodes"] as Dictionary):
			var e: Dictionary = (d["nodes"] as Dictionary)[nod]
			var slot_keys: Array = (e["slots"] as Dictionary).keys()
			slot_keys.sort()
			print("%-24s %-22s %8d %10d %6d  %s" % [
				k, nod, int(e["n"]), int(e["cls"]), int(e["n"]) - int(e["cls"]),
				str(slot_keys)])
	get_tree().quit(0)


func _walk(n: Node, acc: Dictionary) -> void:
	var model := n as Node3D
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/fiordland/"):
		var stem := model.scene_file_path.get_file().get_basename()
		if stem in ["chasm_rock", "guard_rock", "scree_slab", "stirling_ledge",
				"torrent_chute", "moss_boulder_a", "moss_boulder_b", "moss_boulder_c"]:
			_record(acc, stem, model)
			return
	# moss_boulder e in machupicchu/rocks/, nu fiordland/ — cautat separat mai
	# jos ca sa acopere si reuse-ul din Track15.
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/machupicchu/rocks/moss_boulder"):
		var stem2 := model.scene_file_path.get_file().get_basename()
		_record(acc, stem2, model)
		return
	for c in n.get_children():
		_walk(c, acc)


func _record(acc: Dictionary, stem: String, model: Node3D) -> void:
	if not acc.has(stem):
		acc[stem] = {"nodes": {}}
	for mi in _meshes(model):
		var nod := String((mi as Node).name)
		var nodes: Dictionary = acc[stem]["nodes"]
		if not nodes.has(nod):
			nodes[nod] = {"n": 0, "cls": 0, "slots": {}}
		var e: Dictionary = nodes[nod]
		e["n"] = int(e["n"]) + 1
		var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
		if m != null and m == Palette.triplanar_class_material("wet_gneiss"):
			e["cls"] = int(e["cls"]) + 1
		# PURITATEA GEOMETRIEI: ce sloturi de atlas mai raman IN MESH-UL asta,
		# dupa ruptura? Un nod cu material_override triplanar poate raporta
		# corect "clasat" chiar daca geometria n-a fost separata (sabotajul a
		# aratat asta: fara ruptura, Moss_Boulder_B TOT primea wet_gneiss pe
		# tot nodul, muschiul inclusiv) — deci verificam si sloturile brute.
		var slots: Dictionary = e["slots"]
		var mesh := (mi as MeshInstance3D).mesh
		if mesh != null and mesh.get_surface_count() > 0:
			var arr: Array = mesh.surface_get_arrays(0)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			# `_mesh_with_indices` (Palette.split_accents) pastreaza in buffer
			# TOTI vertecsii sursei, si scrie doar alt set de INDICI — un mesh
			# rupt are vertecsi nefolositi din partea cealalta inca in
			# ARRAY_TEX_UV. Cititul direct pe UV (ca in probe_slots.gd, gandit
			# pentru .glb brute, fara indici filtrati) ar raporta gresit
			# ambele sloturi pe fiecare jumatate. Sloturile REALE ale mesh-ului
			# sunt cele pe care le ATING TRIUNGHIURILE, adica prin INDEX.
			if not idx.is_empty():
				for i in range(idx.size()):
					var sl := clampi(int(uv[idx[i]].x * 32.0), 0, 31)
					slots[sl] = int(slots.get(sl, 0)) + 1
			else:
				for i in range(uv.size()):
					var sl := clampi(int(uv[i].x * 32.0), 0, 31)
					slots[sl] = int(slots.get(sl, 0)) + 1
		e["slots"] = slots
		nodes[nod] = e


func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o
