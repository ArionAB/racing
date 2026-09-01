extends Node
## Citeste CULORILE DE VERTEX ale mesh-urilor mari dintr-o pista incarcata, ca
## sa se vada daca nuanta de uzura a soselei (`Track._wear_shade`) chiar ajunge
## in geometrie si cu ce amplitudine.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRoadWearVC.tscn
##
## De ce exista: uzura drumului nu se poate verifica numarand noduri sau
## materiale — toate trec si cand pe ecran nu e nimic. Ce conteaza e INTERVALUL
## dintre cea mai deschisa si cea mai inchisa valoare, comparat cu amplitudinea
## petelor din textura (~0.15). Sub ea, gradientul exista in date si e invizibil
## in poza.
##
## A prins doua defecte reale, amandoua invizibile din cod:
##   - interval 0.129, adica sub zgomotul texturii: uzura rula si nu se vedea;
##   - 4 valori distincte pe 11 puncte de profil, fiindca ridicarea fagasului
##     se taia la 1.0 si trei pozitii se albeau la fel — fagasele erau de fapt
##     un platou. Numarul de valori DISTINCTE e diagnosticul, nu intervalul.
##
## Filtrul e pe numar de vertecsi (>2000), nu pe nume: mesh-urile procedurale
## ale pistei sunt anonime (`@MeshInstance3D@122`).
func arr_count(m) -> int:
	return m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()

func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var stack: Array = [t]
	var found := 0
	while not stack.is_empty():
		var q = stack.pop_back()
		for c in q.get_children(): stack.append(c)
		if q is MeshInstance3D:
			var m = q.mesh
			if m == null or m.get_surface_count() == 0: continue
			if arr_count(m) < 2000: continue
			var arr = m.surface_get_arrays(0)
			var cols = arr[Mesh.ARRAY_COLOR]
			found += 1
			print("nod=%s vertecsi=%d culori=%s" % [q.name, arr[Mesh.ARRAY_VERTEX].size(), "DA" if cols != null else "NU"])
			if cols != null:
				var lo := 9.0; var hi := -9.0
				for c in cols: lo = minf(lo, c.r); hi = maxf(hi, c.r)
				print("  R: min=%.3f max=%.3f  interval=%.3f" % [lo, hi, hi-lo])
				var uniq := {}
				for c in cols: uniq["%.3f"%c.r] = true
				var keys := uniq.keys(); keys.sort()
				print("  valori R distincte (%d): %s" % [keys.size(), str(keys.slice(0,14))])
	print("mesh-uri mari gasite: %d" % found)
	get_tree().quit(0)
