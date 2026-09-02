extends Node
## Cat de REALE sunt stratele taieturii: masoara profilul de rulaj lateral pe
## verticala, direct pe mesh-ul construit, si separat pe UNGHIUL fetelor.
##
## De ce nu se masoara pe captura: o captura spune daca stratul SE VEDE, nu daca
## exista. Aici se raspunde la intrebarea din finding — „benzile sunt geometrie
## sau doar vertex color pe un perete neted?" — pe geometrie, nu pe pixeli.

func _ready() -> void:
	var idx := GameState.resolve_track_index(13)
	var track: Track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mesh="):
			target = a.trim_prefix("--mesh=")
	if target == "":
		target = "Taietura TaieturaInterioara"
	var mi := _find(track, target)
	if mi == null:
		print("NU EXISTA mesh-ul ", target)
		get_tree().quit(1)
		return
	var arr := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	print("mesh %s: %d vertecsi, %d normale" % [target, verts.size(), norms.size()])
	# 1. Cate NORMALE distincte pe verticala: un perete neted are o singura
	#    familie de normale; strate reale au fete de sus (n.y > 0.3).
	var up := 0
	var side_n := 0
	var down := 0
	for n in norms:
		if n.y > 0.30:
			up += 1
		elif n.y < -0.30:
			down += 1
		else:
			side_n += 1
	print("normale: %d fete de SUS (y>0.3), %d verticale, %d in jos"
		% [up, side_n, down])
	# 2. Amplitudinea rulajului lateral pe o coloana (la aceeasi x,z aproximativ)
	#    -> daca stratele ies in consola, coloana are dinti.
	var aabb := mi.mesh.get_aabb()
	print("AABB: pozitie %s marime %s" % [aabb.position, aabb.size])
	# 3. UV: cate sloturi distincte
	# Sloturile, ponderate cu ARIA triunghiurilor: un slot prezent pe doi
	# vertecsi si unul care acopera jumatate de perete nu sunt acelasi lucru.
	# Exact capcana din memoria `aria-slotului-spune-cat-nu-ce`.
	var slots := {}
	for u in uvs:
		slots[int(u.x * 32.0)] = true
	var ks := slots.keys()
	ks.sort()
	print("sloturi de atlas folosite (u*32): ", ks)
	var ind := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		ind = arr[Mesh.ARRAY_INDEX]
	var area := {}
	var tot_a := 0.0
	var tri := (ind.size() / 3) if ind.size() > 0 else (verts.size() / 3)
	for t in tri:
		var ia: int = ind[t * 3] if ind.size() > 0 else t * 3
		var ib: int = ind[t * 3 + 1] if ind.size() > 0 else t * 3 + 1
		var ic: int = ind[t * 3 + 2] if ind.size() > 0 else t * 3 + 2
		var a2 := 0.5 * (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia]).length()
		var sl := int(uvs[ia].x * 32.0)
		area[sl] = float(area.get(sl, 0.0)) + a2
		tot_a += a2
	var kk: Array = area.keys()
	kk.sort()
	print("ARIE pe slot (m2 si %% din fata):")
	for k in kk:
		print("   slot %2d: %8.1f m2  %5.1f%%" % [k, area[k], 100.0 * float(area[k]) / maxf(tot_a, 1e-5)])
	# 4. Vertex color: plaja
	if cols.size() > 0:
		var lo := 2.0
		var hi := -1.0
		var sum := 0.0
		for c in cols:
			lo = minf(lo, c.r)
			hi = maxf(hi, c.r)
			sum += c.r
		print("vertex color r: min %.3f max %.3f mediu %.3f" % [lo, hi, sum / float(cols.size())])
	# LUMINA: cat prinde fata din soare. Explica de ce doua mesh-uri cu ACELEASI
	# sloturi ies la luminante diferite — nu e albedo, e orientare.
	var sun: DirectionalLight3D = null
	var st: Array[Node] = [track]
	while not st.is_empty():
		var nn: Node = st.pop_back()
		if nn is DirectionalLight3D:
			sun = nn as DirectionalLight3D
		for c in nn.get_children():
			st.append(c)
	if sun == null:
		for c in get_tree().root.get_children():
			if c is DirectionalLight3D:
				sun = c as DirectionalLight3D
	if sun != null:
		var sdir := -sun.global_transform.basis.z.normalized()
		var xfb := mi.global_transform.basis
		var tot := 0.0
		var cnt := 0.0
		# Doar fetele care se VAD dinspre drum conteaza: media pe tot mesh-ul
		# amesteca spatele, care e intors prin definitie.
		var lit := 0.0
		var unlit := 0.0
		for n in norms:
			var wn := (xfb * n).normalized()
			var nd := wn.dot(-sdir)
			tot += maxf(nd, 0.0)
			cnt += 1.0
			if nd > 0.05:
				lit += 1.0
			else:
				unlit += 1.0
		print("fete cu NdotL>0.05: %d   fete INTOARSE de la soare: %d (%.1f%%)"
			% [int(lit), int(unlit), 100.0 * unlit / maxf(lit + unlit, 1.0)])
		print("soare dir %s | NdotL mediu %.3f | energie %.2f"
			% [sdir, tot / maxf(cnt, 1.0), sun.light_energy])
		var env := get_tree().root.world_3d.environment
		if env != null:
			print("ambient energie %.2f culoare %s" % [env.ambient_light_energy, env.ambient_light_color])
	get_tree().quit()


func _find(node: Node, want: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == want:
		return node as MeshInstance3D
	for c in node.get_children():
		var r := _find(c, want)
		if r != null:
			return r
	return null
