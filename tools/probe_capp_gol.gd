extends Node
## CAT DE MARE e o deschidere, in METRI DE LUME, si la ce cota deasupra bazei.
##
## Exista fiindca `window_height_m` e nominal in metri, dar trece prin doua
## conversii (scara nodului, apoi unitatea interna a mesh-ului GLB) inainte sa
## ajunga pe ecran — iar reprosul criticului e despre PROPORTIA VAZUTA. O
## fereastra "de 1.3 m" care iese de 4 m nu se vede ca un bug de cod, se vede
## ca o stanca de 8 m.
##
## Masoara pe geometria FINALA: ia AABB-ul triunghiurilor care poarta UV-ul
## slotului intunecat (fundul nisei) si il raporteaza in metri de lume.
##
## Raza de grupare e 0.9 m si NU mai mult: la 3 m, prima versiune a sondei lipea
## usa cu ferestrele de deasupra ei intr-un singur "gol" si raporta 2-4 m acolo
## unde geometria avea 1.3. O sonda care aduna doua obiecte intr-unul da exact
## simptomul pe care il cauti (deschideri prea mari) fara sa existe — si atunci
## se repara scara, care era buna.
##
##   godot --headless --path . res://tools/ProbeCappGol.tscn -- --track=6

const DARK_SLOT := 26


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	var only: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--horn="):
			only.append(arg.trim_prefix("--horn="))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().process_frame

	var shapes: Array[Node] = []
	_collect(track, shapes)
	var du := Palette.uv(DARK_SLOT)
	print("")
	print("=== deschideri, in metri de lume ===")
	print("  horn              n_goluri  lat x inalt (m)   raport   cota_baza (m)")
	for s in shapes:
		var n3 := s as Node3D
		if not only.is_empty() and not only.has(String(n3.name)):
			continue
		var mis: Array[MeshInstance3D] = []
		_meshes(n3, mis)
		var groups: Array = []
		var base_y := 1e9
		for mi in mis:
			if mi.mesh == null:
				continue
			var ab := mi.global_transform * mi.mesh.get_aabb()
			base_y = minf(base_y, ab.position.y)
		for mi in mis:
			if mi.mesh == null:
				continue
			for sf in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(sf)
				var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				if uvs.size() != vs.size():
					continue
				# Triunghiurile pe slotul intunecat, grupate pe proximitate:
				# fiecare nisa e un ciorchine separat.
				for t in vs.size() / 3:
					var i := t * 3
					if absf(uvs[i].x - du.x) > 0.002:
						continue
					var c := mi.global_transform * ((vs[i] + vs[i + 1] + vs[i + 2]) / 3.0)
					var hit := -1
					for gi in groups.size():
						if (groups[gi]["c"] as Vector3).distance_to(c) < 0.9:
							hit = gi
							break
					var pa := mi.global_transform * vs[i]
					var pb := mi.global_transform * vs[i + 1]
					var pc := mi.global_transform * vs[i + 2]
					if hit < 0:
						var ab2 := AABB(pa, Vector3.ZERO)
						ab2 = ab2.expand(pb).expand(pc)
						groups.append({"c": c, "ab": ab2})
					else:
						var ab3: AABB = groups[hit]["ab"]
						groups[hit]["ab"] = ab3.expand(pa).expand(pb).expand(pc)
		if groups.is_empty():
			continue
		var wsum := 0.0
		var hsum := 0.0
		var ysum := 0.0
		for g in groups:
			var ab4: AABB = g["ab"]
			wsum += maxf(ab4.size.x, ab4.size.z)
			hsum += ab4.size.y
			ysum += ab4.position.y - base_y
		var n := float(groups.size())
		print("  %-16s %5d     %5.2f x %5.2f      %5.2f    %6.2f" % [
			n3.name, groups.size(), wsum / n, hsum / n,
			(wsum / n) / maxf(hsum / n, 0.01), ysum / n])
	get_tree().quit()


func _collect(node: Node, out: Array[Node]) -> void:
	if node is ChimneyShape:
		out.append(node)
	for c in node.get_children():
		_collect(c, out)


func _meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	var mi := node as MeshInstance3D
	if mi != null:
		out.append(mi)
	for c in node.get_children():
		_meshes(c, out)
