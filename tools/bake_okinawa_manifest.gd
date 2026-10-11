extends SceneTree
## Pasul 1 al coacerii decorului Okinawa (vezi tools/bake_okinawa_decor.py).
##
## Incarca Track20 EXACT ca in joc (WorldProp isi face singur _ready-ul, inclusiv
## partile amanate pe tema) si scrie, pentru fiecare model de sub DecorManual FARA
## coliziune efectiva, ce ar fi vazut jucatorul: nodurile de mesh vizibile, cu
## transformul lor fata de radacina modelului, clasa de material aplicata de
## WorldProp si daca mesh-ul a fost modificat fata de cel din GLB (remap de sloturi,
## netezire, intunecare de vertex color etc.).
##
## Rezultatul e SURSA DE ADEVAR a convertorului: el nu reimplementeaza maparile
## din world_prop.gd, doar citeste rezultatul lor. Orice mapare noua (CLASSES_*,
## SLOT_REMAP_*) intra automat.
##
##   godot --headless --path . --script res://tools/bake_okinawa_manifest.gd -- --out=C:/cale/manifest.json
##   (Track20 implicit; --scene=res://scenes/tracks/AltaPista.tscn pentru alt fisier)

const META_BLOCK := ["lumina", "racire", "indigo", "clasa_triplanara", "camera_blocker"]

var _out_path := ""
var _scene := "res://scenes/tracks/Track20.tscn"
var _track: Node = null
var _frame := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a.begins_with("--scene="):
			_scene = a.trim_prefix("--scene=")
	_track = (load(_scene) as PackedScene).instantiate()
	root.add_child(_track)


func _process(_d: float) -> bool:
	_frame += 1
	if _frame < 4:  # lasa call_deferred-urile WorldProp sa ruleze
		return false
	_dump()
	return true


func _mat_kind(mat: Material) -> String:
	if mat == null:
		return "none"
	if mat == Palette.world_material():
		return "atlas"
	for n: String in Palette.ATLAS_TINTS:
		if mat == Palette.atlas_tint_material(n):
			return Palette.ATINT_PREFIX + n
	for c: String in Palette.CLASS_TRIPLANAR_SCALE:
		if mat == Palette.triplanar_class_material(c):
			return Palette.TRI_PREFIX + c
	for c: String in Palette._class_mats:
		if mat == Palette._class_mats[c]:
			return "class:" + c
	return "other"


func _walk(n: Node, out: Array[Node]) -> void:
	out.append(n)
	for c in n.get_children():
		_walk(c, out)


## Vizibil fata de radacina modelului (modelul insusi are `visible` pe instanta).
func _vis_chain(n: Node3D, model: Node3D) -> bool:
	var cur: Node = n
	while cur != null:
		if cur is Node3D and not (cur as Node3D).visible:
			return false
		if cur == model:
			break
		cur = cur.get_parent()
	return true


func _xf_rel(n: Node3D, model: Node3D) -> Array:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != model:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	var b := xf.basis
	return [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
		xf.origin.x, xf.origin.y, xf.origin.z]


func _dump() -> void:
	var dm: Node = _track.get_node_or_null("DecorManual")
	var res := {"scene": _scene, "theme": String(_track.get("theme_decor")), "nodes": {}}
	if dm == null:
		_write(res)
		return
	var models: Array[Node3D] = []
	dm._collect_models(dm, models)
	var pristine := {}  # glb path -> {nume nod: mesh original}
	for model in models:
		var glb := model.scene_file_path
		var rel := String(dm.get_path_to(model))
		var mode: String = dm._collision_mode(model)
		var entry := {"glb": glb, "mode": mode, "blocked": false, "anim": false, "meshes": [],
			"discs": [], "circle": null}
		# Amprenta pe care Track o citeste din nodurile originale: discul de contact
		# (umbra moale de sub piesa) si cercul de excludere a vegetatiei procedurale.
		# Un stol nu are mesh-uri de masurat, deci le poarta el (FlockProp.contact_discs).
		if mode == "none" and model.visible:
			# Track::_prop_contact_discs merge pe TOT subarborele: radacina modelului si
			# fiecare Node3D vizibil din GLB (nodurile de mesh) dau cate un disc; coacerea
			# le pastreaza pe toate, ca umbra moale de sub piesa sa iasa identica.
			var subs: Array[Node] = []
			_walk(model, subs)
			var discs: Array = []
			for sn in subs:
				var sn3 := sn as Node3D
				if sn3 == null or not sn3.visible:
					continue
				var d: Vector4 = _track._contact_disc_for(sn3, dm)
				if is_nan(d.x):
					continue
				var fl := 0
				if not _track._contact_flat.is_empty() and _track._in_flat_model(sn3, dm):
					fl = 1
				discs.append([d.x, d.y, d.z, d.w, fl])
			entry["discs"] = discs
			if String(_track.get("theme_decor")) == "okinawa" or String(_track.theme_flag("props", "desert")) == "okinawa":
				var c: Vector3 = _track._oki_veg_circle_for(model)
				if not is_nan(c.x):
					entry["circle"] = [c.x, c.y, c.z]
		# metadata ereditata pe lant care schimba materialul/lumina
		var p: Node = model
		while p != null and p != _track:
			for k in META_BLOCK:
				if p.has_meta(k):
					entry["blocked"] = true
			p = p.get_parent()
		if not pristine.has(glb):
			var fresh: Node = (load(glb) as PackedScene).instantiate()
			var meshes := {}
			var all: Array[Node] = []
			_walk(fresh, all)
			for n in all:
				if n is MeshInstance3D:
					if meshes.has(n.name):
						meshes[n.name] = null  # nume duplicat -> ambiguu
					else:
						meshes[n.name] = (n as MeshInstance3D).mesh
			pristine[glb] = meshes
			fresh.free()
		var nodes: Array[Node] = []
		_walk(model, nodes)
		var names := {}
		for n in nodes:
			if n is Skeleton3D or n is AnimationPlayer or n is CollisionObject3D:
				entry["anim"] = true
			if n is MeshInstance3D:
				var mi := n as MeshInstance3D
				if mi.mesh == null or not _vis_chain(mi, model):
					continue
				names[mi.name] = int(names.get(mi.name, 0)) + 1
				var orig: Variant = pristine[glb].get(mi.name, null)
				var sm: Material = null
				if mi.mesh.get_surface_count() == 1:
					sm = mi.mesh.surface_get_material(0)
				(entry["meshes"] as Array).append({
					"name": String(mi.name),
					"xf": _xf_rel(mi, model),
					"mat": _mat_kind(mi.material_override),
					"surf_mat": _mat_kind(sm),
					"mesh_orig": orig != null and orig == mi.mesh,
					"cast": int(mi.cast_shadow),
					"vr_end": mi.visibility_range_end,
					"vr_begin": mi.visibility_range_begin,
					"surfaces": mi.mesh.get_surface_count(),
					"tris": _tris(mi.mesh),
				})
		for k: String in names:
			if int(names[k]) > 1 or pristine[glb].get(k, 0) == null:
				entry["ambiguous"] = true
		res["nodes"][rel] = entry
	_write(res)


func _tris(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		var idx: Variant = a[Mesh.ARRAY_INDEX]
		if idx != null and (idx as PackedInt32Array).size() > 0:
			t += (idx as PackedInt32Array).size() / 3
		else:
			t += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t


func _write(res: Dictionary) -> void:
	var s := JSON.stringify(res)
	if _out_path.is_empty():
		print(s)
		return
	var f := FileAccess.open(_out_path, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("manifest: %d modele -> %s" % [(res["nodes"] as Dictionary).size(), _out_path])
