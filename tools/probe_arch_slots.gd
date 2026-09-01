extends SceneTree
## Intreaba DACA remap-ul de sloturi a ajuns pe arcele din stanca goala.
## Nu numara instante: citeste UV-ul din mesh-ul VIU si spune pe ce sloturi sta.
## (Lectia `efecte-invizibile-nu-se-numara`: o sonda care numara ar fi trecut
## verde si cu arcele ruginii pe ecran.)

func _initialize() -> void:
	var track: Node = load("res://scenes/tracks/Track13.tscn").instantiate()
	root.add_child(track)
	await process_frame
	await process_frame
	var win: Node = track.get_node_or_null("DecorManual/G) Stanca goala/Ferestre")
	if win == null:
		print("VERDICT: FAIL - nu exista nodul Ferestre")
		quit(1); return
	var seen := {}
	var n_arch := 0
	for child in win.get_children():
		if not String(child.name).begins_with("Fereastra"):
			continue
		n_arch += 1
		var stack: Array[Node] = [child]
		while not stack.is_empty():
			var nd: Node = stack.pop_back()
			for c in nd.get_children():
				stack.append(c)
			var mi := nd as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			for s in mi.mesh.get_surface_count():
				var arr: Array = mi.mesh.surface_get_arrays(s)
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				for i in uv.size():
					var slot := int(floor(uv[i].x * 32.0))
					seen[slot] = int(seen.get(slot, 0)) + 1
	var slots: Array = seen.keys()
	slots.sort()
	print("arce=%d sloturi=%s" % [n_arch, str(slots)])
	# Ruginiul vine de pe 4, 10, 20, 23, 27. Dupa remap NICIUNUL nu mai are voie
	# sa apara: totul trebuie sa fie in familia tufului (2 = SAND_SHADOW,
	# 19 = CORAL_SAND).
	var rust: Array = []
	for s: int in slots:
		if s in [4, 10, 20, 23, 27]:
			rust.append(s)
	if rust.is_empty():
		print("VERDICT: OK - niciun slot ruginit pe arce")
		quit(0)
	else:
		print("VERDICT: FAIL - sloturi ruginite ramase: %s" % str(rust))
		quit(1)
