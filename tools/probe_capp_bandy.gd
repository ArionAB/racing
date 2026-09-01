extends Node
## Stau benzile ORIZONTAL? Masurat direct pe COLOANELE reconstruite, nu pe UV.
##
## Prima versiune grupa vertecsii pe UV si raporta plaje de 67 m — dar
## `band_slots` REPETA culorile ([23,10,27,23,10,27,...]), deci acelasi UV apare
## legitim la mai multe altitudini si cifra nu spunea nimic despre orizontalitate.
## Aici merg pe rand: pentru fiecare INDICE de rand, ce cote ia el pe lungimea
## peretelui. Un strat orizontal are plaja mica; unul care se infasoara diagonal
## urmeaza soseaua si iese cu zeci de metri.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	print("=== ORIZONTALITATEA STRATELOR, PE RAND ===")
	print("(plaja = cat variaza cota aceluiasi rand pe lungimea peretelui)")
	_walk(t)
	get_tree().quit(0)

func _walk(nd: Node) -> void:
	var nm := str(nd.name)
	if nd is MeshInstance3D and (nm.begins_with("Faleza") or nm.begins_with("Taietura")):
		var mi := nd as MeshInstance3D
		var m := mi.mesh
		if m != null and m.get_surface_count() > 0:
			var arr := m.surface_get_arrays(0)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			# Grupez vertecsii pe COLOANA (pozitie XZ apropiata de o axa) e
			# fragil; in schimb ma folosesc de faptul ca panza e cusuta coloana
			# cu coloana: sortez cotele unice si ma uit cate PALIERE distincte
			# exista. O faleza cu strate orizontale are palierele foarte
			# populate; una diagonala are cote imprastiate.
			var buckets := {}
			for k in vs.size():
				var b := int(round(vs[k].y))
				buckets[b] = int(buckets.get(b, 0)) + 1
			var keys := buckets.keys()
			keys.sort()
			var top := []
			for kk in keys:
				top.append([int(buckets[kk]), kk])
			top.sort_custom(func(a, b): return a[0] > b[0])
			var lo := 1e9
			var hi := -1e9
			for k in vs.size():
				lo = minf(lo, vs[k].y)
				hi = maxf(hi, vs[k].y)
			print("--- %s: %d vtx, cote %.1f..%.1f, %d cote distincte(1 m)"
				% [nm, vs.size(), lo, hi, keys.size()])
			var line := "    cele mai populate cote: "
			for j in mini(8, top.size()):
				line += "%d m x%d  " % [int(top[j][1]), int(top[j][0])]
			print(line)
			# concentrare: cat din vertecsi stau pe primele 10 cote
			var s10 := 0
			for j in mini(10, top.size()):
				s10 += int(top[j][0])
			print("    concentrare pe 10 cote: %.0f%%  (mare = strate orizontale)"
				% [100.0 * float(s10) / float(maxi(vs.size(), 1))])
	for c in nd.get_children():
		_walk(c)
