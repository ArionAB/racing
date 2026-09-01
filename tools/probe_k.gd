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
		var arr: Array = mi.mesh.surface_get_arrays(0)
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
