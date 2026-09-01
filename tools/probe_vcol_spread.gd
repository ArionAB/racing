extends Node
func _ready() -> void:
	call_deferred("_go")
func _go() -> void:
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 15: await get_tree().process_frame
	var done := 0
	var stack: Array[Node] = [t]
	while not stack.is_empty() and done < 3:
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if not str(n.name).begins_with("horn"): continue
		var mi: MeshInstance3D = null
		var q: Array[Node] = [n]
		while not q.is_empty():
			var x: Node = q.pop_back()
			for c in x.get_children(): q.append(c)
			if x is MeshInstance3D: mi = x; break
		if mi == null or mi.mesh == null: continue
		done += 1
		var arr = mi.mesh.surface_get_arrays(0)
		var cols = arr[Mesh.ARRAY_COLOR]
		if cols == null:
			print("%s: FARA vertex color (deci COLOR=alb, lumina e libera)" % n.name)
			continue
		var cc: PackedColorArray = cols
		var lo := 9.0; var hi := -9.0; var s := 0.0
		for c in cc:
			var v: float = (c.r+c.g+c.b)/3.0
			lo=minf(lo,v); hi=maxf(hi,v); s+=v
		print("%s: vcol N=%d  min=%.3f max=%.3f medie=%.3f ecart=%.3f" % [
			n.name, cc.size(), lo, hi, s/cc.size(), hi-lo])
	get_tree().quit(0)
