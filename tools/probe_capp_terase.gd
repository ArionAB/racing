extends Node
## Verifica GEOMETRIC ca terasele sunt o scara, nu o panta.
##
## De ce nu ajunge captura ca sa dezvolti (dar ea ramane verdictul). Sonda asta
## raspunde la trei intrebari pe care ochiul le confunda:
##
##   1. Exista PERETE VERTICAL sub buza? Se numara fetele cu normala aproape
##      orizontala aflate in fereastra de sub un plan de terasa. Zero = am facut
##      iar o panta, adica exact defectul lui `strata_step`.
##   2. E profilul MONOTON descrescator? Raza maxima pe felii de cota trebuie sa
##      scada de jos in sus, cu salturi la praguri. Daca urca undeva, silueta
##      are un umar si conul devine sticla (memoria rundei 16).
##   3. Cat de mare e saltul? In metri si in procente. Un prag sub 2% din raza
##      nu se vede la 25 m — magnitudinea ceruta e 8-12%.
##
## Rulare:
##   godot --headless --path . res://tools/ProbeCappTerase.tscn -- --n=3

const SLICES: int = 60


func _ready() -> void:
	var only_n := 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			only_n = int(a.substr(4))

	var scn := load("res://scenes/tracks/Track13.tscn")
	if scn == null:
		print("Track13 lipseste")
		get_tree().quit(1)
		return
	var root: Node = scn.instantiate()
	var chimneys: Array[Node] = []
	_collect_shapes(root, chimneys)
	print("hornuri cu ChimneyShape: ", chimneys.size())

	var done := 0
	for node in chimneys:
		if done >= only_n:
			break
		var cs := node as ChimneyShape
		if cs.terrace_count < 2:
			continue
		done += 1
		# `_ready` nu ruleaza pe un arbore neintrat in scena: deformarea se
		# cheama explicit, altfel sonda ar masura mesh-ul din GLB si ar raporta
		# "fara terase" chiar cand codul e corect.
		#
		# POALA SI DESCHIDERILE SE STING pe durata masuratorii, si asta nu e
		# comoditate. Prima versiune a sondei le lasa pornite si citea, pe un
		# horn de 11.2 m, o inaltime de 18.4 m si "cresteri de raza de 60%":
		# grohotisul e o alta suprafata, mult mai lata, lipita la baza. Exact
		# capcana pe care `cone_profile.py` o descrie pe pixeli — umflatura nu e
		# in raza conului, e in poala. Sonda asta masoara PROFILUL CORPULUI, deci
		# corpul e tot ce are voie sa vada; conturul din captura, cu poala cu tot,
		# il judeca `cone_profile.py`.
		var keep_talus := cs.talus_spread
		var keep_doors := cs.door_count
		var keep_windows := cs.window_rows
		cs.talus_spread = 0.0
		cs.door_count = 0
		cs.window_rows = 0
		cs.call("_deform")
		_report(cs)
		cs.talus_spread = keep_talus
		cs.door_count = keep_doors
		cs.window_rows = keep_windows

	if done == 0:
		print("NICIUN horn cu terase — terrace_count nesetat in .tscn?")
	root.queue_free()
	get_tree().quit()


func _collect_shapes(n: Node, out: Array[Node]) -> void:
	if n is ChimneyShape:
		out.append(n)
	for c in n.get_children():
		_collect_shapes(c, out)


func _report(cs: ChimneyShape) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(cs, meshes)
	if meshes.is_empty():
		return
	var mi: MeshInstance3D = meshes[0]
	var best := -1.0
	for m in meshes:
		var v: float = m.mesh.get_aabb().get_volume()
		if v > best:
			best = v
			mi = m
	var mesh := mi.mesh
	var ab := mesh.get_aabb()
	var h: float = maxf(ab.size.y, 0.001)
	var y0: float = ab.position.y
	var cx: float = ab.position.x + ab.size.x * 0.5
	var cz: float = ab.position.z + ab.size.z * 0.5

	# Raza MAXIMA pe felie: silueta e conturul, deci maximul, nu media.
	var rad := PackedFloat32Array()
	rad.resize(SLICES)
	rad.fill(0.0)
	var walls := 0
	var flats := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		for i in verts.size():
			var v := verts[i]
			var t := clampf((v.y - y0) / h, 0.0, 0.9999)
			var k := int(t * SLICES)
			var r := sqrt(pow(v.x - cx, 2.0) + pow(v.z - cz, 2.0))
			if r > rad[k]:
				rad[k] = r
		if norms.size() == verts.size():
			for i in range(0, verts.size() - 2, 3):
				var n := ((norms[i] + norms[i + 1] + norms[i + 2]) / 3.0).normalized()
				var yc := (verts[i].y + verts[i + 1].y + verts[i + 2].y) / 3.0
				var tt := (yc - y0) / h
				if tt > cs.terrace_to:
					continue
				if absf(n.y) < 0.35:
					walls += 1
				elif n.y > 0.75:
					flats += 1

	# Salturile: unde scade raza brusc de la o felie la urmatoarea.
	var jumps: Array = []
	for k in range(SLICES - 1):
		if rad[k] <= 0.001 or rad[k + 1] <= 0.001:
			continue
		var d := (rad[k] - rad[k + 1]) / rad[k]
		if d > 0.03:
			jumps.append([float(k) / SLICES, d, rad[k] - rad[k + 1]])
	# Monotonia: unde CRESTE raza de jos in sus (umar de sticla).
	var rises := 0
	var worst_rise := 0.0
	for k in range(SLICES - 1):
		if rad[k] <= 0.001 or rad[k + 1] <= 0.001:
			continue
		if k > int(SLICES * cs.terrace_to):
			break
		var up := (rad[k + 1] - rad[k]) / rad[k]
		if up > 0.01:
			rises += 1
			worst_rise = maxf(worst_rise, up)

	var lv: PackedFloat32Array = cs.call("_terrace_levels", h)
	var lvs := ""
	for q in lv:
		lvs += "%.3f " % q
	print("--- ", cs.name, "  h=%.1f m  terrace_count=%d drop=%.2f lip=%.2f" % [
		h, cs.terrace_count, cs.terrace_drop, cs.terrace_lip_m])
	print("    plane: ", lvs, " mesh-uri=", meshes.size(), " verts=",
		mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size())
	print("    fete VERTICALE (perete de sub buza): ", walls,
		"   fete ORIZONTALE (fata de sus): ", flats)
	var js := ""
	for j in jumps:
		js += "t=%.2f -%.1f%% (%.2f m)  " % [j[0], j[1] * 100.0, j[2]]
	print("    praguri (scadere de raza intre felii): ", jumps.size())
	print("      ", js if js != "" else "NICIUNUL — profilul e neted")
	print("    cresteri de raza in sus: ", rises, "  cea mai mare: %.1f%%" % (
		worst_rise * 100.0))


func _collect_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		out.append(mi)
	for c in n.get_children():
		_collect_meshes(c, out)
