extends Node
## CE MATERIAL PRIMESTE FIECARE PARTE A KITULUI JODHPUR, pe pista incarcata.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodClase.tscn -- --track=10
##
## De ce exista: garda de materiale (`probe_decor`) numara materiale, nu
## culori (memoria `tenta-pe-clasa-partajata`), iar mapari GLOBALE pe prefix de
## nume (`WorldProp.prop_classes()`: `Wall_` = varul de Stromboli) pot prinde
## noduri ale unui kit nou fara ca vreo cifra sa se miste (memoria
## `nume-noduri-nu-sunt-unice`). Sonda pune cate o instanta din fiecare GLB
## Jodhpur sub un `WorldProp` COPIL AL PISTEI (ca `DecorManual`, deci tema e
## cea reala — memoria `decor-ready-inaintea-temei`), asteapta apelurile
## amanate, si compara materialul fiecarui MeshInstance3D cu ce cere
## `CLASSES_BY_MODEL`: clasa numita -> materialul clasei; orice altceva
## (inclusiv `_Accente`) -> materialul atlasului. Casele se pun de doua ori,
## a doua oara cu metadata `indigo`, care trebuie sa dea `blue_lime_indigo`.
##
## Iese 1 la orice nepotrivire.

const KIT_DIR := "res://assets/models/jodhpur"


func _ready() -> void:
	await get_tree().process_frame
	var only := 10
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame

	var holder := Node3D.new()
	holder.name = "ProbeJodClase"
	holder.set_script(load("res://scenes/props/world_prop.gd"))
	holder.set("auto_collision", false)
	var files := _kit_files()
	var x := 0.0
	for path in files:
		var inst := (load(path) as PackedScene).instantiate() as Node3D
		inst.position = Vector3(x, 500.0, 0.0)
		holder.add_child(inst)
		x += 60.0
		if path.get_file().begins_with("blue_house") or path.get_file().begins_with("haveli"):
			var ind := (load(path) as PackedScene).instantiate() as Node3D
			ind.set_meta(WorldProp.LIME_INDIGO_META, true)
			ind.position = Vector3(x, 500.0, 0.0)
			holder.add_child(ind)
			x += 60.0
	track.add_child(holder)
	for i in 3:
		await get_tree().process_frame

	var cls_of := {}
	for cls: String in Palette._tri_mats:
		cls_of[Palette._tri_mats[cls]] = "tri:" + cls
	cls_of[Palette.world_material()] = "atlas"
	var bad := 0
	var mats := {}
	print("=== Clasele kitului Jodhpur pe %s (tema %s) ===" % [
		GameState.track_label(only), track.get("theme_decor")])
	for inst in holder.get_children():
		var model := inst as Node3D
		if model == null or model.scene_file_path.is_empty():
			continue
		var stem := model.scene_file_path.get_file().get_basename()
		var indigo := model.has_meta(WorldProp.LIME_INDIGO_META)
		var mapping: Dictionary = WorldProp.CLASSES_BY_MODEL.get(stem, {})
		var stack: Array[Node] = [model]
		var line := ""
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			var mi := n as MeshInstance3D
			if mi == null:
				continue
			var got_mat := mi.material_override
			mats[got_mat] = true
			var got: String = cls_of.get(got_mat, "ALT:%s" % str(got_mat))
			var want := "atlas"
			var nm := String(mi.name)
			if not nm.ends_with(Palette.ACCENT_SUFFIX):
				var best := -1
				for part: String in mapping:
					if nm.begins_with(part) and part.length() > best:
						best = part.length()
						var v := String(mapping[part])
						want = "atlas" if v == Palette.ATLAS_PREFIX else v
				if indigo and want == "tri:" + WorldProp.LIME_LIGHT:
					want = "tri:" + WorldProp.LIME_INDIGO
			var ok := got == want
			if not ok:
				bad += 1
			line += "  %s%s=%s%s" % ["" if ok else "!!", nm, got, "" if ok else "(vrea %s)" % want]
		print("%-24s%s%s" % [stem, " [indigo]" if indigo else "", line])
	print("materiale distincte pe kit: %d" % mats.size())
	for m in mats:
		print("   %s" % cls_of.get(m, "ALT:%s" % str(m)))
	if bad > 0:
		print("VERDICT: %d parti pe materialul gresit" % bad)
		get_tree().quit(1)
	else:
		print("VERDICT: OK — fiecare parte pe clasa ceruta")
		get_tree().quit(0)


func _kit_files() -> Array[String]:
	var out: Array[String] = []
	var root := DirAccess.open(KIT_DIR)
	for cat in root.get_directories():
		var d := DirAccess.open("%s/%s" % [KIT_DIR, cat])
		for f in d.get_files():
			if f.ends_with(".glb"):
				out.append("%s/%s/%s" % [KIT_DIR, cat, f])
	out.sort()
	return out
