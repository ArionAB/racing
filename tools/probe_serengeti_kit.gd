extends SceneTree
## INVENTARUL KITULUI SERENGETI, citit din GLB-urile importate: pentru fiecare
## fisier din assets/models/serengeti/ (plus props/cow.glb) — nodurile
## MeshInstance3D (nume, triunghiuri, AABB in spatiul radacinii, SLOTURILE de
## atlas atinse de UV-uri), AnimationPlayer-ele cu numele animatiilor si
## scheletele cu oasele lor.
##
## De ce exista: maparile din world_prop.gd (SPLIT_MODELS / ACCENT_SPLIT /
## CLASSES_BY_MODEL) se scriu pe NUMELE nodului de mesh si pe sloturile REALE
## ale piesei, nu pe ce zice inventarul din docs — aici se citesc din fisier.
##
##   godot --headless --path . --script res://tools/probe_serengeti_kit.gd

func _init() -> void:
	var files := []
	for cat in ["animals", "rocks", "plants", "buildings", "props"]:
		var dir := DirAccess.open("res://assets/models/serengeti/%s" % cat)
		if dir == null:
			continue
		for f in dir.get_files():
			if f.ends_with(".glb"):
				files.append("res://assets/models/serengeti/%s/%s" % [cat, f])
	files.append("res://assets/models/props/cow.glb")
	files.sort()
	for path in files:
		var ps := load(path) as PackedScene
		if ps == null:
			print("%s: NU SE INCARCA" % path)
			continue
		var root := ps.instantiate()
		print("=== %s" % path.get_file())
		var stack: Array[Node] = [root]
		var total_tris := 0
		var aabb := AABB()
		var first := true
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			if n is MeshInstance3D:
				var mi := n as MeshInstance3D
				var tris := 0
				var slots := {}
				for s in mi.mesh.get_surface_count():
					var arr := mi.mesh.surface_get_arrays(s)
					var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
					tris += idx.size() / 3 if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
					var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
					if uv != null:
						for u in uv:
							slots[int(floor(u.x * 32.0))] = true
				total_tris += tris
				var xf := mi.global_transform if mi.is_inside_tree() else _xf_to_root(mi, root)
				var box := xf * mi.get_aabb()
				if first:
					aabb = box
					first = false
				else:
					aabb = aabb.merge(box)
				var sl := slots.keys()
				sl.sort()
				print("  mesh %-32s tri %5d  aabb pos(%.2f,%.2f,%.2f) size(%.2f,%.2f,%.2f) sloturi %s vis=%s" % [
					mi.name, tris, box.position.x, box.position.y, box.position.z,
					box.size.x, box.size.y, box.size.z, str(sl), str(mi.visible)])
			elif n is AnimationPlayer:
				var ap := n as AnimationPlayer
				print("  anim  %s: %s" % [ap.name, str(ap.get_animation_list())])
			elif n is Skeleton3D:
				var sk := n as Skeleton3D
				var names := []
				for b in sk.get_bone_count():
					names.append(sk.get_bone_name(b))
				print("  skel  %s: %s" % [sk.name, str(names)])
			elif n is Node3D and n != root and not (n is MeshInstance3D):
				print("  node  %s (%s)" % [n.name, n.get_class()])
		print("  TOTAL tri %d  aabb pos(%.2f,%.2f,%.2f) size(%.2f,%.2f,%.2f)" % [
			total_tris, aabb.position.x, aabb.position.y, aabb.position.z,
			aabb.size.x, aabb.size.y, aabb.size.z])
		root.free()
	quit()


func _xf_to_root(n: Node3D, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	if root is Node3D:
		xf = (root as Node3D).transform * xf
	return xf
