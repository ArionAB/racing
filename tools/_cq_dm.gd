extends Node
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track12.tscn") as PackedScene).instantiate()
	add_child(t)
	for i in 6:
		await get_tree().process_frame
	var dm := t.get_node_or_null("DecorManual")
	print("DecorManual: ", dm)
	if dm:
		var mi := 0
		var stack: Array[Node] = [dm]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is MeshInstance3D: mi += 1
			for c in n.get_children(): stack.append(c)
		print("copii directi: ", dm.get_child_count(), "  MeshInstance3D in subarbore: ", mi)
		for z in dm.get_children():
			print("  ", z.name, " -> ", z.get_child_count())
	get_tree().quit()
