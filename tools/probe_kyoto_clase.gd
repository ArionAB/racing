extends Node
## A ajuns clasa PE OBIECT pe Kyoto (Track18), sau doar in numaratoare? Tiparul
## probe_fiord_fagi_clase.gd (memoria `sonda-masura-alt-obiect`), extins la cele
## trei drumuri prin care kitul Kyoto ajunge pe pista:
##
##  1. noduri `WorldProp` (DecorManual, ModulePlacer): material_override pe
##     MeshInstance3D-ul din GLB;
##  2. `CityFill` / `MeshForest`: un MultiMeshInstance3D per (model, nod);
##  3. `FlockProp` (tunelul de torii, cedrii lui): un MultiMesh per stol.
##
## Raportul e pe (model, nod) cu instante si clasa citita inapoi din cache-ul
## de materiale al paletei (`Palette._tri_mats`) — un material care nu e acolo
## iese „atlas" (materialul lumii) sau „alt".
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoClase.tscn -- --track=18

func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(18)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 20:
		await get_tree().process_frame
	var acc := {}
	_walk(track, acc)
	var keys: Array = acc.keys()
	keys.sort()
	print("%-44s %7s  %s" % ["model/nod", "inst", "clasa"])
	for k in keys:
		var d: Dictionary = acc[k]
		var by := PackedStringArray()
		for c in (d as Dictionary):
			by.append("%s=%d" % [c, d[c]])
		var n := 0
		for c in d:
			n += int(d[c])
		print("%-44s %7d  %s" % [k, n, " ".join(by)])
	var cls := PackedStringArray()
	for c in Palette._tri_mats:
		cls.append(String(c))
	cls.sort()
	print("CLASE CONSTRUITE (%d): %s" % [cls.size(), " ".join(cls)])
	get_tree().quit(0)


func _class_name(m: Material) -> String:
	if m == null:
		return "null"
	if m == Palette.world_material():
		return "atlas"
	for c in Palette._tri_mats:
		if Palette._tri_mats[c] == m:
			return String(c)
	return "alt"


func _add(acc: Dictionary, key: String, cls: String, n: int) -> void:
	if not acc.has(key):
		acc[key] = {}
	acc[key][cls] = int((acc[key] as Dictionary).get(cls, 0)) + n


func _walk(n: Node, acc: Dictionary) -> void:
	var model := n as Node3D
	if model != null and model.scene_file_path.contains("/models/kyoto/"):
		var stem := model.scene_file_path.get_file().get_basename()
		for mi in _meshes(model):
			_add(acc, "%s/%s" % [stem, mi.name], _class_name(mi.material_override), 1)
		return
	var mmi := n as MultiMeshInstance3D
	if mmi != null and mmi.multimesh != null and mmi.multimesh.mesh != null:
		var cnt: int = mmi.multimesh.instance_count
		if mmi.multimesh.visible_instance_count >= 0:
			cnt = mmi.multimesh.visible_instance_count
		var label := "MM:%s|%s" % [mmi.multimesh.mesh.resource_name, mmi.name]
		var flock := mmi as FlockProp
		if flock != null and flock.model != null:
			label = "MM:%s|%s" % [flock.model.resource_path.get_file().get_basename(), mmi.name]
		# Etichetele de felie ale MeshForest (`25_2_-3_ginkgo_0[_far]`) se strang
		# pe specie: coordonatele feliei si LOD-ul nu conteaza pentru clasa.
		var rx := RegEx.create_from_string("^MM:\\|-?\\d+_-?\\d+_-?\\d+_(.+?)(_far)?$")
		var hit := rx.search(label)
		if hit != null:
			label = "MF:" + hit.get_string(1)
		rx = RegEx.create_from_string("^MM:\\|CityFill_(.+?)__p(\\d+)_.*$")
		hit = rx.search(label)
		if hit != null:
			label = "CF:%s#p%s" % [hit.get_string(1), hit.get_string(2)]
		if mmi.material_override != null:
			_add(acc, label, _class_name(mmi.material_override), cnt)
		else:
			# MeshForest: o suprafata per parte (trunchi, coroana), material pe
			# suprafata, nu override.
			var mesh := mmi.multimesh.mesh
			for si in mesh.get_surface_count():
				_add(acc, "%s#s%d" % [label, si], _class_name(mesh.surface_get_material(si)), cnt)
	for c in n.get_children():
		_walk(c, acc)


func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o
