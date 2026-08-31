extends SceneTree

## PROFILUL PALARIEI: cat de mult iese buza peste gat, si pe ce inaltime.
##
## De ce exista. Lead-ul, pe captura de la 0.05: "palariile sunt prea mari si
## prea ciuperca; in referinta sunt palarii conice mai stranse, asezate pe
## umar". Acuzatia e despre SILUETA, iar silueta unei palarii se descrie cu
## doua numere, nu cu unul:
##
##   depasire = raza_max_a_palariei / raza_gatului
##       Cat iese consola in afara. Peste ~1.5 ochiul citeste FARFURIE (o
##       ciuperca), fiindca discul ascunde gatul cand privesti de jos.
##   zveltete = inaltimea_palariei / (2 * raza_max)
##       Cat de conica e. Sub ~0.25 palaria e un disc plat oricat de mica ar
##       fi depasirea; peste ~0.45 e un varf, nu o palarie.
##
## Se masoara pe mesh-ul FINAL din scena (dupa `chimney_shape._deform_mesh` si
## dupa ce `world_prop` reface mesh-ul), nu pe parametrii din .tscn: `cap_flare`
## e un factor pe raza, iar raza de la care porneste difera de la un GLB la
## altul — jumatate din kit avea palaria mai INGUSTA decat gatul inainte de
## consola (vezi comentariul lui `cap_flare`). Deci cifra din inspector nu spune
## cat de lata iese palaria pe ecran.
##
##   godot --headless --path . --script res://tools/probe_capp_palarie.gd

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var rows: Array = []
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var sh := n as ChimneyShape
		if sh == null:
			continue
		var mi := _first_mesh(sh)
		if mi == null:
			continue
		var r := _profile(mi, sh)
		if r.is_empty():
			continue
		r["nume"] = String(sh.name)
		r["flare"] = sh.cap_flare
		r["from"] = sh.cap_from
		rows.append(r)

	if rows.is_empty():
		print("niciun horn cu ChimneyShape")
		quit()
		return

	rows.sort_custom(func(a, b): return a["depasire"] > b["depasire"])
	print("horn                    flare  from   depasire  zveltete  raza_max(m)")
	for r in rows:
		print("%-22s %5.2f  %4.2f   %6.2fx   %6.2f   %6.2f" % [
			r["nume"], r["flare"], r["from"], r["depasire"],
			r["zveltete"], r["rmax"]])

	var sd := 0.0
	var sz := 0.0
	var farfurii := 0
	for r in rows:
		sd += r["depasire"]
		sz += r["zveltete"]
		if r["depasire"] >= 1.5 or r["zveltete"] < 0.25:
			farfurii += 1
	print("")
	print("hornuri: %d   depasire medie %.2fx   zveltete medie %.2f" % [
		rows.size(), sd / rows.size(), sz / rows.size()])
	print("FARFURII (depasire >= 1.5x SAU zveltete < 0.25): %d din %d" % [
		farfurii, rows.size()])
	quit()


func _first_mesh(n: Node) -> MeshInstance3D:
	var stack: Array[Node] = [n]
	var best: MeshInstance3D = null
	var bestf := 0
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():
			stack.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var f: int = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		if f > bestf:
			bestf = f
			best = mi
	return best


## Raza maxima pe felii de cota, deasupra si dedesubtul lui cap_from.
func _profile(mi: MeshInstance3D, sh: ChimneyShape) -> Dictionary:
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	if v.is_empty():
		return {}
	var ab := mi.mesh.get_aabb()
	var h: float = maxf(ab.size.y, 0.001)
	var y0: float = ab.position.y
	var cx: float = ab.position.x + ab.size.x * 0.5
	var cz: float = ab.position.z + ab.size.z * 0.5
	# Scara reala in lume: palaria se judeca in metri pe ecran, nu in unitati
	# de mesh.
	var s: Vector3 = mi.global_transform.basis.get_scale()
	var sxz: float = (absf(s.x) + absf(s.z)) * 0.5

	# Felii de cota. Mesh-ul are putine inele orizontale, deci o felie ingusta
	# poate cadea INTRE doua inele si sa iasa goala — de-aia raza se ia din
	# TRIUNGHIURI, interpoland pe muchie: fiecare fata contribuie la toate
	# feliile pe care le traverseaza. Fara asta profilul iesea ciuruit de zerouri
	# si "inaltimea palariei" se termina dupa o felie, adica orice palarie parea
	# un disc.
	const N := 48
	var rad: PackedFloat32Array = PackedFloat32Array()
	rad.resize(N)
	for tri in v.size() / 3:
		for e in 3:
			var a := v[tri * 3 + e]
			var b := v[tri * 3 + (e + 1) % 3]
			var ta: float = clampf((a.y - y0) / h, 0.0, 0.9999)
			var tb: float = clampf((b.y - y0) / h, 0.0, 0.9999)
			var ka: int = int(ta * N)
			var kb: int = int(tb * N)
			if ka > kb:
				var sw := ka; ka = kb; kb = sw
			for k in range(ka, kb + 1):
				# Cota de mijloc a feliei, exprimata pe muchie.
				var tm: float = (float(k) + 0.5) / float(N)
				var u: float = 0.0
				if not is_equal_approx(ta, tb):
					u = clampf((tm - ta) / (tb - ta), 0.0, 1.0)
				var px: float = lerpf(a.x, b.x, u) - cx
				var pz: float = lerpf(a.z, b.z, u) - cz
				var r: float = sqrt(px * px + pz * pz)
				if r > rad[k]:
					rad[k] = r

	var kfrom: int = clampi(int(sh.cap_from * N), 1, N - 2)
	# Gatul: cea mai stramta felie sub buza (acolo lucreaza `collar_pinch`).
	var rneck := 1e9
	for k in range(maxi(kfrom - 8, 0), kfrom + 1):
		if rad[k] > 0.0 and rad[k] < rneck:
			rneck = rad[k]
	# Palaria: cea mai lata felie de la buza in sus.
	var rmax := 0.0
	var kmax := kfrom
	for k in range(kfrom, N):
		if rad[k] > rmax:
			rmax = rad[k]
			kmax = k
	if rneck >= 1e8 or rmax <= 0.0:
		return {}
	# Inaltimea palariei: de la buza pana unde raza scade sub 15% din maxim.
	var ktop := N - 1
	for k in range(kmax, N):
		if rad[k] < rmax * 0.15:
			ktop = k
			break
	var hp: float = float(ktop - kmax) / float(N) * h
	return {
		"depasire": rmax / rneck,
		"zveltete": hp / maxf(2.0 * rmax, 0.0001),
		"rmax": rmax * sxz,
	}
