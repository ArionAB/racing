extends SceneTree
## INVENTARUL TEHNIC AL KITULUI MACHU PICCHU, citit din GLB-urile importate.
##
## De ce exista: brief-ul (docs/asset_briefs/machu_picchu_inventory.md) a gresit
## deja de doua ori la kitul asta (main_gate 4 m vs 8,4 m; axa trenului -Z vs
## +X). Maparile din world_prop.gd (PROP_COLLISION / SPLIT_MODELS /
## CLASSES_BY_MODEL) se scriu pe NUMELE REAL al nodului de mesh si pe SLOTURILE
## REALE ale piesei — amandoua se citesc aici din fisier, nu din docs.
##
## Ce raporteaza, per fisier si per nod de mesh:
##   - numele exact al nodului, clasa, vizibilitatea
##   - triunghiuri, AABB in spatiul radacinii (pozitie + dimensiune)
##   - raza la baza: raza maxima in XZ a vertecsilor din prima 15% din
##     inaltimea piesei (sta la baza tiparului "trunk" din world_prop.gd)
##   - histograma de sloturi de atlas: procent de vertecsi + intervalul de y
##     (memoria `clase-pe-piese-de-kit`: o clasa triplanara pe un nod cu mai
##     multe sloturi le STERGE pe toate; intervalul de y spune daca ruptura de
##     accente e posibila — memoria `ruptura-accente-doua-sloturi`)
##   - u_min..u_max pe fiecare surface, ca sa se vada daca UV-ul e COLAPSAT pe
##     centrul slotului (contractul atlasului) sau matura latimea atlasului
##     (memoria `uv-colapsat-nu-e-un-interval`: se testeaza valori DISTINCTE)
##   - AnimationPlayer cu lista de clipuri, Skeleton3D cu oasele
##
## Se ruleaza ca script, nu ca scena:
##   godot --headless --path <worktree> --script res://tools/probe_machupicchu_kit.gd
##
## Optional: --dir=machupicchu pentru alt kit (aceleasi subfoldere).

const BASE_SLICE: float = 0.15  ## fractia de jos din inaltime = "baza"


func _init() -> void:
	var kit := "machupicchu"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			kit = a.trim_prefix("--dir=")
	var base := "res://assets/models/%s" % kit
	var files: Array[String] = []
	var root_dir := DirAccess.open(base)
	if root_dir == null:
		push_error("probe_machupicchu_kit: nu pot deschide %s" % base)
		quit(1)
		return
	for cat in root_dir.get_directories():
		var d := DirAccess.open("%s/%s" % [base, cat])
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".glb"):
				files.append("%s/%s/%s" % [base, cat, f])
	files.sort()
	print("=== KIT %s — %d fisiere .glb ===" % [kit, files.size()])
	for path in files:
		_report_file(path)
	quit()


func _report_file(path: String) -> void:
	var ps := load(path) as PackedScene
	if ps == null:
		print("=== %s: NU SE INCARCA" % path)
		return
	var root := ps.instantiate()
	print("")
	print("=== %s  (%s)" % [path.get_file().get_basename(), path])
	var stack: Array[Node] = [root]
	var total_tris := 0
	var whole := AABB()
	var first := true
	var meshes: Array[MeshInstance3D] = []
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			meshes.append(n as MeshInstance3D)
		elif n is AnimationPlayer:
			var ap := n as AnimationPlayer
			print("  ANIM  %s: %s" % [ap.name, str(ap.get_animation_list())])
		elif n is Skeleton3D:
			var sk := n as Skeleton3D
			var bones: Array[String] = []
			for b in sk.get_bone_count():
				bones.append(sk.get_bone_name(b))
			print("  SKEL  %s (%d oase): %s" % [sk.name, bones.size(), str(bones)])
		elif n is Node3D and n != root:
			print("  NOD   %s (%s)" % [n.name, n.get_class()])
	# ordine stabila: alfabetic pe nume
	meshes.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool:
		return a.name < b.name)

	# Prima trecere: AABB-ul intregii piese (raza la baza are nevoie de y_min global).
	for mi in meshes:
		var xf := _xf_to_root(mi, root)
		var box := xf * mi.get_aabb()
		if first:
			whole = box
			first = false
		else:
			whole = whole.merge(box)
	var y_min := whole.position.y
	var y_max := whole.position.y + whole.size.y
	var base_cut := y_min + maxf(BASE_SLICE * whole.size.y, 0.05)

	var base_r_all := 0.0
	var multi_slot: Array[String] = []
	for mi in meshes:
		if mi.mesh == null:
			print("  MESH  %-26s (fara mesh)" % mi.name)
			continue
		var xf := _xf_to_root(mi, root)
		var box := xf * mi.get_aabb()
		var tris := 0
		# slot -> [y_min, y_max, numar_vertecsi]
		var per: Dictionary = {}
		var verts := 0
		var u_lo := INF
		var u_hi := -INF
		var u_distinct: Dictionary = {}
		var base_r := 0.0
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var vt: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			tris += (idx.size() / 3) if idx.size() > 0 else (vt.size() / 3)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			for i in range(vt.size()):
				var p: Vector3 = xf * vt[i]
				var r := Vector2(p.x, p.z).length()
				if p.y <= base_cut:
					base_r = maxf(base_r, r)
				if uv.size() == vt.size():
					var u := uv[i].x
					u_lo = minf(u_lo, u)
					u_hi = maxf(u_hi, u)
					u_distinct[snappedf(u, 0.0001)] = true
					var sl := clampi(int(u * float(Palette.SLOTS)), 0,
						Palette.SLOTS - 1)
					var e: Array = per.get(sl, [INF, -INF, 0])
					e[0] = minf(float(e[0]), p.y)
					e[1] = maxf(float(e[1]), p.y)
					e[2] = int(e[2]) + 1
					per[sl] = e
					verts += 1
		base_r_all = maxf(base_r_all, base_r)
		total_tris += tris
		var keys: Array = per.keys()
		keys.sort()
		if keys.size() > 1:
			multi_slot.append(mi.name)
		print("  MESH  %-26s tri %5d  vis=%s  aabb pos(%7.2f,%7.2f,%7.2f) size(%6.2f,%6.2f,%6.2f)  raza_baza %.2f" % [
			mi.name, tris, str(mi.visible),
			box.position.x, box.position.y, box.position.z,
			box.size.x, box.size.y, box.size.z, base_r])
		if verts == 0:
			print("        (fara UV-uri)")
			continue
		print("        u %.4f..%.4f  valori_u_distincte %d  %s" % [
			u_lo, u_hi, u_distinct.size(),
			("COLAPSAT" if u_distinct.size() <= keys.size() else "MATURA")])
		for k in keys:
			var e: Array = per[k]
			var c := Palette.color(int(k))
			print("        slot %2d %-16s #%02X%02X%02X  %5.1f%% verts  y %7.2f..%7.2f" % [
				int(k), _slot_name(int(k)),
				int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0),
				100.0 * float(e[2]) / float(verts), float(e[0]), float(e[1])])
	print("  TOTAL tri %d  inaltime %.3f m  (y %.3f .. %.3f)  baza %.2f x %.2f m  raza_baza %.2f m  noduri_mesh %d  multi_slot %s" % [
		total_tris, whole.size.y, y_min, y_max,
		whole.size.x, whole.size.z, base_r_all, meshes.size(),
		("-" if multi_slot.is_empty() else str(multi_slot))])
	root.free()


func _slot_name(slot: int) -> String:
	const NAMES := [
		"SAND_LIGHT", "SAND_MID", "SAND_SHADOW", "ROCK_LIGHT", "ROCK_DARK",
		"ASPHALT", "ASPHALT_EDGE", "KERB_RED", "CONCRETE", "WOOD_WEATHERED",
		"RUST_METAL", "PAINTED_METAL", "CACTUS_GREEN", "DRY_VEGETATION",
		"CAR_RED", "CAR_BLUE", "CAR_YELLOW", "REEF_SHALLOW", "SEA_DEEP",
		"CORAL_SAND", "VOLCANIC_BLACK", "TROPICAL_GREEN", "FOAM_WHITE",
		"TILE_TERRACOTTA", "ICE_TURQUOISE", "ICE_DEEP", "ICE_CRACK",
		"LARCH_RUST", "LOG_DARK", "MARBLE_GREY", "LAVA_ORANGE", "FLAMINGO_PINK",
	]
	return NAMES[slot] if slot >= 0 and slot < NAMES.size() else "?"


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
