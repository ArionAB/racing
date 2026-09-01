extends Node
## Ce spune vertex color-ul, pe fete, INAINTE de lumina: distributia lui `k`.
## Nu masoara pixeli — masoara canalul pe care il scrie `_shade_facets`, ca sa
## se vada daca semnalul pictat e bimodal la sursa sau abia rasterizatorul si
## lumina il netezesc.
func _ready() -> void:
	var idx := 13
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame
	for nm in ["hornUmbra8", "hornSoare11", "hornGemen9"]:
		var n := _gaseste(track, nm)
		if n == null:
			print("%s: negasit" % nm)
			continue
		var mi := _prim_mesh(n)
		if mi == null or mi.mesh == null:
			print("%s: fara mesh" % nm)
			continue
		# NORMALA din atribut fata de normala GEOMETRICA (produsul vectorial al
		# colturilor). Daca cele doua nu sunt de acord, atributul minte si orice
		# sonda care il citeste (inclusiv _shade_facets) numeste "spre soare" o
		# fata pe care randarea o lasa in umbra.
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idxx: Variant = arr[Mesh.ARRAY_INDEX]
		var acord := 0
		var contra := 0
		if nn.size() == vv.size() and (idxx == null):
			for t in vv.size() / 3:
				var i3 := t * 3
				var gn := (vv[i3 + 1] - vv[i3]).cross(vv[i3 + 2] - vv[i3])
				if gn.length_squared() < 1e-12:
					continue
				if gn.normalized().dot(nn[i3].normalized()) > 0.0:
					acord += 1
				else:
					contra += 1
			print("  %s: normale in acord %d, INVERSE %d" % [nm, acord, contra])
		# Cate fete privesc spre soarele real (elev 22, azimut 205), pe mesh in
		# spatiul GLOBAL.
		var e := deg_to_rad(22.0)
		var az := deg_to_rad(205.0)
		var sund := Vector3(cos(e) * sin(az), sin(e), cos(e) * cos(az)).normalized()
		var nb := mi.global_transform.basis.inverse().transposed()
		var spre := 0
		var dinspre := 0
		for i3 in nn.size():
			var wn: Vector3 = nb * nn[i3]
			if wn.length_squared() < 1e-12:
				continue
			if wn.normalized().dot(sund) > 0.1:
				spre += 1
			else:
				dinspre += 1
		print("  %s: vertecsi cu normala spre soare %d, intoarsa %d"
				% [nm, spre, dinspre])
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		if cols.is_empty():
			print("%s: fara vertex color" % nm)
			continue
		var v := PackedFloat32Array()
		for c in cols:
			v.append(c.r)
		v.sort()
		var bins := PackedInt32Array()
		bins.resize(16)
		bins.fill(0)
		for x in v:
			bins[clampi(int(x * 16.0), 0, 15)] += 1
		var top := 1
		for b in bins:
			top = maxi(top, b)
		var ramp := " .:-=+*#%@"
		var hist := ""
		for b in bins:
			hist += ramp[clampi(int(float(b) / float(top) * 9.0), 0, 9)]
		print("%-14s n=%6d  min %.3f  p10 %.3f  p50 %.3f  p90 %.3f  max %.3f  [0 %s 1]"
				% [nm, v.size(), v[0], v[int(v.size() * 0.1)], v[int(v.size() * 0.5)],
					v[int(v.size() * 0.9)], v[v.size() - 1], hist])
	get_tree().quit(0)

func _gaseste(n: Node, nm: String) -> Node:
	if String(n.name) == nm:
		return n
	for c in n.get_children():
		var r := _gaseste(c, nm)
		if r != null:
			return r
	return null

func _prim_mesh(n: Node) -> MeshInstance3D:
	var mi := n as MeshInstance3D
	if mi != null:
		return mi
	for c in n.get_children():
		var r := _prim_mesh(c)
		if r != null:
			return r
	return null
