extends Node
## Ce sloturi de atlas foloseste cliff_band_module (si red_mesa, pentru
## comparatie). Zidul iese cenusiu in captura, langa un desert cald — sonda
## spune daca vina e in sloturile din .glb sau in lumina.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappZidUV.tscn

func _ready() -> void:
	await get_tree().process_frame
	for m in ["rocks/cliff_band_module", "rocks/red_mesa", "rocks/chimney_a"]:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		var counts := {}
		var stack: Array[Node] = [inst]
		while not stack.is_empty():
			var nd: Node = stack.pop_back()
			for c in nd.get_children():
				stack.append(c)
			var mi := nd as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			for si in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(si)
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				for u in uv:
					var slot := int(floor(u.x * float(Palette.SLOTS)))
					counts[slot] = int(counts.get(slot, 0)) + 1
		var keys := counts.keys()
		keys.sort()
		print("")
		print("=== %s ===" % m)
		for k in keys:
			print("  slot %2d  %s  %6d vertecsi" % [
				k, Palette.HEX[int(k)], counts[k]])
		inst.queue_free()
	print("")
	get_tree().quit(0)
