extends SceneTree
## SONDA (headless): pe ce CALE trece stratul de detaliu, si pe ce sloturi.
##
##   godot --headless --path . --script res://tools/probe_detail_census.gd -- --track=25
##   godot --headless --path . --script res://tools/probe_detail_census.gd -- --cars
##
## --track = NUMARUL SCENEI (TrackNN.tscn), ca la probe_decor.
##
## Pentru fiecare suprafata randata (MeshInstance3D si MultiMeshInstance3D) se
## afla materialul efectiv si se clasifica:
##   std_mask   BaseMaterial3D cu detaliu pornit SI masca detail_mask.png
##              (materialul lumii si copiile lui: atint, finish, glow, foliage)
##   fade       ShaderMaterial pe prop_detail_fade.gdshader (citeste .a explicit)
##   std_nodet  BaseMaterial3D pe atlas fara strat de detaliu (plain, crown, core)
##   std_other  alt BaseMaterial3D (clase triplanare, drum, teren standard)
##   shader     alt ShaderMaterial (teren, drum, apa, frunze...)
## si se aduna ARIA triunghiurilor (m², cu scara instantei) per slot de atlas
## (slotul = floor(uv.x * 32) pe primul varf al triunghiului).

var _paths: Array[String] = []
var _cars := false
var _index := 0
var _track: Node = null
var _frames := 0
var _mask_tex: Texture2D
var _arr_cache := {}


func _initialize() -> void:
	_mask_tex = load(Palette.DETAIL_MASK_PATH)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			for t in arg.trim_prefix("--track=").split(","):
				_paths.append("res://scenes/tracks/Track%02d.tscn" % int(t))
		elif arg == "--cars":
			_cars = true


func _classify(mat: Material) -> String:
	if mat == null:
		return "none"
	if mat is ShaderMaterial:
		var sh := (mat as ShaderMaterial).shader
		if sh != null and sh.resource_path.ends_with("prop_detail_fade.gdshader"):
			return "fade"
		return "shader:" + (sh.resource_path.get_file() if sh != null else "?")
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		if bm.detail_enabled and bm.detail_mask == _mask_tex:
			return "std_mask"
		if bm.albedo_texture != null and bm.albedo_texture.resource_path == Palette.ATLAS_PATH:
			return "std_nodet" if not bm.detail_enabled else "std_atlas_detail_nomask"
		return "std_other"
	return mat.get_class()


## Aria per slot a unei suprafete, in spatiul mesh-ului. Cache pe (mesh, surf).
func _slot_area(mesh: Mesh, s: int) -> Dictionary:
	var key := "%d:%d" % [mesh.get_instance_id(), s]
	if _arr_cache.has(key):
		return _arr_cache[key]
	var out := {}
	var arr := mesh.surface_get_arrays(s)
	if arr.is_empty() or arr[Mesh.ARRAY_TEX_UV] == null:
		_arr_cache[key] = out
		return out
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var n := idx.size() if idx.size() > 0 else v.size()
	for t in range(0, n - 2, 3):
		var i0 := idx[t] if idx.size() > 0 else t
		var i1 := idx[t + 1] if idx.size() > 0 else t + 1
		var i2 := idx[t + 2] if idx.size() > 0 else t + 2
		var area := (v[i1] - v[i0]).cross(v[i2] - v[i0]).length() * 0.5
		var slot := clampi(int(floor(uv[i0].x * Palette.SLOTS)), 0, Palette.SLOTS - 1)
		out[slot] = out.get(slot, 0.0) + area
	_arr_cache[key] = out
	return out


func _scale2(b: Basis) -> float:
	return pow(absf(b.determinant()), 2.0 / 3.0)


func _census(root_node: Node) -> Dictionary:
	# res[path_class][slot] = {"area": float, "who": {name: area}}
	var res := {}
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for c in node.get_children():
			stack.append(c)
		if node is Node3D and not (node as Node3D).is_visible_in_tree():
			continue
		var mesh: Mesh = null
		var override: Material = null
		var k2 := 0.0
		var mi := node as MeshInstance3D
		if mi != null:
			mesh = mi.mesh
			override = mi.material_override
			k2 = _scale2(mi.global_transform.basis)
		elif node is MultiMeshInstance3D:
			var mmi := node as MultiMeshInstance3D
			if mmi.multimesh == null:
				continue
			mesh = mmi.multimesh.mesh
			override = mmi.material_override
			var g := mmi.global_transform.basis
			for i in mmi.multimesh.instance_count:
				k2 += _scale2(g * mmi.multimesh.get_instance_transform(i).basis)
		if mesh == null:
			continue
		var who := String(node.name)
		if mesh.resource_name != "":
			who = mesh.resource_name
		for s in mesh.get_surface_count():
			var mat := override
			if mat == null and mi != null:
				mat = mi.get_surface_override_material(s)
			if mat == null:
				mat = mesh.surface_get_material(s)
			var cls := _classify(mat)
			if not res.has(cls):
				res[cls] = {}
			var sa := _slot_area(mesh, s)
			for slot in sa:
				var a: float = sa[slot] * k2
				if not res[cls].has(slot):
					res[cls][slot] = {"area": 0.0, "who": {}}
				res[cls][slot].area += a
				res[cls][slot].who[who] = res[cls][slot].who.get(who, 0.0) + a
	return res


func _print(label: String, res: Dictionary) -> void:
	var mask := Image.load_from_file(ProjectSettings.globalize_path(Palette.DETAIL_MASK_PATH))
	print("=== CENSUS %s" % label)
	for cls in res:
		var tot := 0.0
		for slot in res[cls]:
			tot += res[cls][slot].area
		print("  PATH %-28s total %10.0f m2" % [cls, tot])
	for cls in ["std_mask", "fade"]:
		if not res.has(cls):
			continue
		var slots: Array = res[cls].keys()
		slots.sort_custom(func(a, b): return res[cls][a].area > res[cls][b].area)
		for slot in slots:
			var e: Dictionary = res[cls][slot]
			var names: Array = e.who.keys()
			names.sort_custom(func(a, b): return e.who[a] > e.who[b])
			var top := []
			for nm in names.slice(0, 4):
				top.append("%s(%.0f)" % [nm, e.who[nm]])
			print("  SLOT %-8s %2d  a=%.2f  %10.1f m2  %s" % [cls, slot,
				mask.get_pixel(slot, 0).a, e.area, ", ".join(top)])


func _process(_d: float) -> bool:
	if _cars:
		_cars = false
		var dir := DirAccess.open("res://scenes/cars/data")
		for f in dir.get_files():
			if not f.ends_with(".tres"):
				continue
			var data := load("res://scenes/cars/data/" + f)
			if data == null or data.get("model") == null:
				continue
			var inst: Node = (data.model as PackedScene).instantiate()
			root.add_child(inst)
			if data.palette_model:
				Palette.apply_world_material(inst)
			_print("car " + f, _census(inst))
			inst.free()
		return _paths.is_empty()
	if _track == null:
		if _index >= _paths.size():
			return true
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 3:
		return false
	_print(_paths[_index].get_file(), _census(_track))
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false
