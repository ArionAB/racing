extends Node
## PUNCTUL 4: "balonul aterizat e TRANSPARENT".
##
## Doua cauze posibile si diferite, deci se masoara amandoua:
##   (a) FETE LIPSA — panza e o suprafata deschisa de grosime zero; cu
##       CULL_BACK jumatate din ea nu se deseneaza si prin ea se vede drumul.
##   (b) PANZA NU ATINGE SOLUL — daca marginea sta in aer, printre cupole se
##       vede pamant si foaia citeste panglica, nu invelis.
##
## Pentru (b) se ia conturul mesh-ului (vertecsii de pe marginea grilei) si se
## compara cota lui cu terenul de dedesubt.
##
##   godot --headless --path . res://tools/ProbeCappPanzaTalpa.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var space := t.get_world_3d().direct_space_state

	var drapes: Array[Node] = []
	_collect(t, drapes)
	print("=== PANZELE DE BALON DEZUMFLAT ===")
	for d in drapes:
		var mi := d.get_node_or_null("Drape") as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var mat := mi.material_override as BaseMaterial3D
		var cull := "?" 
		if mat != null:
			cull = ["BACK", "FRONT", "DISABLED"][int(mat.cull_mode)]
		var arrays := (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var vs_all: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		# NUMAI CONTURUL. Media pe toti vertecsii masoara inaltimea CUPOLEI
		# (~1 m prin constructie, si asa trebuie sa fie) — nu spune nimic
		# despre ce a reclamat dezvoltatorul. Ce citeste "pluteste" e MARGINEA:
		# daca rama panzei nu atinge pamantul, pe sub foaie se vede sol si
		# umbra. Grila e (total+1) randuri x (seg_width+1) coloane, deci
		# conturul e primul/ultimul rand plus prima/ultima coloana.
		var mi_node := d as FabricDrape
		var wcols: int = mi_node.seg_width + 1
		var rows: int = int(vs_all.size() / wcols)
		var vs := PackedVector3Array()
		for r in rows:
			for cc in wcols:
				if r == 0 or r == rows - 1 or cc == 0 or cc == wcols - 1:
					vs.append(vs_all[r * wcols + cc])
		var sus := 0
		var jos := 0
		var max_gol := 0.0
		var sum_gol := 0.0
		var n := 0
		for v in vs:
			var w: Vector3 = mi.global_transform * v
			var q := PhysicsRayQueryParameters3D.create(
				w + Vector3.UP * 60.0, w + Vector3.DOWN * 60.0)
			q.collide_with_areas = false
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var gy: float = float(hit["position"].y)
			var gol: float = w.y - gy
			n += 1
			sum_gol += gol
			max_gol = maxf(max_gol, gol)
			if gol > 0.30: sus += 1
			else: jos += 1
		print("  %-18s cull %-8s | %d vertecsi de CONTUR | peste sol > 30 cm: %d (%.0f%%) | gol mediu %.2f m, maxim %.2f m"
			% [d.name, cull, n, sus, 100.0 * float(sus) / maxf(float(n), 1.0),
			   sum_gol / maxf(float(n), 1.0), max_gol])
	get_tree().quit(0)


func _collect(node: Node, out: Array[Node]) -> void:
	if node is FabricDrape:
		out.append(node)
	for c in node.get_children():
		_collect(c, out)
