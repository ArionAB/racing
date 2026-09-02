extends Node
## _redden_cliff prinde nodurile zidului? Sonda listeaza ce vede
## `_collect_models` pentru DecorManual si daca numele incepe cu "zidValea".
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappZidHit.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 4:
		await get_tree().process_frame
	var zid := 0
	var named := 0
	var stack: Array[Node] = [track]
	var samples: Array[String] = []
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		var n3 := nd as Node3D
		if n3 == null or n3.scene_file_path.is_empty():
			continue
		if n3.scene_file_path.get_file().get_basename() != "cliff_band_module":
			continue
		zid += 1
		if String(n3.name).begins_with("zidValea"):
			named += 1
		elif samples.size() < 6:
			samples.append("%s (parinte %s)" % [n3.name, n3.get_parent().name])
	print("")
	print("=== cliff_band_module in scena ===")
	print("  instante gasite:            %d" % zid)
	print("  cu numele zidValea*:        %d" % named)
	for sx in samples:
		print("  nume NEPOTRIVIT: %s" % sx)
	# Si culorile de vertex: exista?
	var st: Array[Node] = [track]
	while not st.is_empty():
		var nd: Node = st.pop_back()
		for c in nd.get_children():
			st.append(c)
		var n3 := nd as Node3D
		if n3 == null or n3.scene_file_path.is_empty():
			continue
		if n3.scene_file_path.get_file().get_basename() != "cliff_band_module":
			continue
		var s2: Array[Node] = [n3]
		while not s2.is_empty():
			var q: Node = s2.pop_back()
			for c in q.get_children():
				s2.append(c)
			var mi := q as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var arr := mi.mesh.surface_get_arrays(0)
			var rc: Variant = arr[Mesh.ARRAY_COLOR]
			print("  primul mesh: culori de vertex = %s" % (
				"DA (%d)" % (rc as PackedColorArray).size() if rc is PackedColorArray else "NU (null)"))
			# Ce VALORI au, dupa ce a rulat tot lantul din _ready? Daca tenta
			# rosie a supravietuit, mediile pe canale trebuie sa fie inegale.
			if rc is PackedColorArray:
				var cc: PackedColorArray = rc
				var ar := 0.0
				var ag := 0.0
				var ab := 0.0
				for k in cc.size():
					ar += cc[k].r
					ag += cc[k].g
					ab += cc[k].b
				var m := float(maxi(cc.size(), 1))
				print("  medii vertex color: r=%.3f g=%.3f b=%.3f" % [
					ar / m, ag / m, ab / m])
			var mat := mi.get_active_material(0)
			print("  material activ: %s  vertex_color_as_albedo=%s" % [
				mat.resource_name if mat != null else "<null>",
				str((mat as StandardMaterial3D).vertex_color_use_as_albedo) if mat is StandardMaterial3D else "?"])
			get_tree().quit(0)
			return
	get_tree().quit(0)
