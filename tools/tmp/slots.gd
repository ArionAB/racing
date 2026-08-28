extends Node
## Ce SLOTURI de paleta foloseste un asset, si cu ce arie. Fara asta „aprinde
## slotul 30" e o presupunere: daca ferestrele stau in alt slot, metadata nu
## aprinde nimic si cladirea ramane o placa.
func _ready() -> void:
	for path in ["res://assets/models/chongqing/structures/hongya_dong.glb",
			"res://assets/models/chongqing/buildings/liziba_block.glb"]:
		var sc := (load(path) as PackedScene).instantiate()
		var area := {}
		var total := 0.0
		var stack: Array = [sc]
		while not stack.is_empty():
			var n = stack.pop_back()
			for c in n.get_children(): stack.append(c)
			var mi := n as MeshInstance3D
			if mi == null or mi.mesh == null: continue
			for si in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				if uv == null or uv.is_empty() or ix == null: continue
				var t := 0
				while t + 2 < ix.size():
					var a := v[ix[t]]; var b := v[ix[t+1]]; var c2 := v[ix[t+2]]
					var ar := (b - a).cross(c2 - a).length() * 0.5
					var slot := int(floor(uv[ix[t]].x * 32.0))
					area[slot] = float(area.get(slot, 0.0)) + ar
					total += ar
					t += 3 * 7
		var keys := area.keys()
		keys.sort_custom(func(p, q): return area[p] > area[q])
		var line := path.get_file() + ": "
		for k in keys:
			if area[k] / total > 0.01:
				line += "s%d=%.0f%% " % [k, 100.0 * area[k] / total]
		print(line)
	get_tree().quit(0)
