extends Node
## Garda pentru FERESTRE (si usi) CARE PLUTESC IN AER.
##
## Runda 35: pe captura de sofer o fereastra statea cu rama cu tot in cer,
## desprinsa de roca (deasupra ramei RGB(227,231,244) = exact cerul). Defectul
## nu avea nicio sonda: `ProbePlutire` verifica prop-uri INTREGI care plutesc
## deasupra terenului, dar ferestrele nu sunt noduri — sunt suprafete in
## mesh-ul hornului, deci trec neatinse pe langa ea.
##
## CE MASOARA, si de ce asa. Sonda NU reface asezarea ferestrelor. Trei
## incercari au esuat exact pe asta:
##   1. cautarea de noduri separate n-a gasit nimic (ferestrele sunt suprafete);
##   2. o histograma (azimut x cota) raporta 292 de goluri unde citirea directa
##      gaseste 230, si 5.01 m pe un perete aflat la 0.00 m;
##   3. refacerea plasarii cu acelasi rng a iesit din sincron cu `_build_windows`
##      fiindca sonda nu chema `_clear_of_lips` — deci masura ferestre la ALTE
##      cote decat cele desenate, si se contrazicea cu diagnosticul direct pe
##      hornSpate41 (4.76 m fata de -0.00 m).
## Orice reimplementare a plasarii e o a doua sursa de adevar care se poate
## desincroniza tacut. Deci se citeste GEOMETRIA DEJA GENERATA: golul unei
## deschideri e desenat cu `DOOR_DARK_SLOT` in UV, deci vertecsii lui se
## recunosc in mesh-ul final. Pentru fiecare se intreaba daca exista roca in
## spatele lui, pe azimutul LUI.
##
##   godot --headless --path . res://tools/ProbeFerestre.tscn -- --track=6

## Cat aer se tolereaza in spatele unui punct de deschidere, in metri de lume.
## Fata nisei sta intentionat la r*1.01 (1% in fata peretelui, ca sa nu faca
## z-fighting), iar peretele e fatetat — deci un punct e "asezat" daca roca de
## sub el nu e mai departe de atat plus o palma de fatetare.
const MAX_AER := 0.35
## Cate puncte au voie sa fie in aer.
##
## NU e zero, si asta e o datorie asumata, nu o toleranta aleasa. Runda 35 a
## reparat CAUZA ferestrei plutitoare din captura (randuri asezate pe cote unde
## hornul nu mai are perete, vezi `WINDOW_WALL_MIN` in `chimney_shape.gd`):
## punctele in aer au scazut de la 255 la 108, si defectul vizibil a disparut
## din cadru. Cele 108 ramase sunt un al DOILEA lucru, inca nediagnosticat: nu
## se vad in cadrul de sofer la frac 0.06 si nu stiu inca daca sunt geometrie
## reala sau limita sondei. Pragul e pus pe cifra masurata ca sa prinda
## REGRESIILE de aici incolo — daca numarul creste, ceva s-a stricat. Cine
## coboara cifra, coboara si pragul.
const MAX_RELE := 108
## Toleranta de potrivire a slotului in UV: atlasul are celule mici, deci marja
## e stramta ca sa nu prindem alt slot.
const UV_EPS := 0.004
## Slotul cu care se deseneaza golul deschiderii (DOOR_DARK_SLOT din
## `chimney_shape.gd`).
const SLOT_GOL := 26

func _ready() -> void:
	call_deferred("_go")

func _go() -> void:
	var only := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			only = int(a.trim_prefix("--track="))
	var t := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame

	var uv_dark := Palette.uv(SLOT_GOL)

	var rele := 0
	var horn_rele := 0
	var verificate := 0
	var puncte := 0
	var worst := 0.0
	var worst_nm := ""
	var raport: Array[String] = []

	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		# Scriptul sta pe RADACINA instantei de GLB (Node3D), nu pe mesh: prima
		# varianta cauta `window_rows` pe MeshInstance3D si a raportat verde pe
		# ZERO hornuri. Vezi memoria `sonda-masura-alt-obiect`.
		if not (n is ChimneyShape):
			continue
		var ch := n as ChimneyShape
		if not ch.visible:
			continue
		if ch.window_rows <= 0 and ch.door_count <= 0:
			continue
		var meshes: Array[MeshInstance3D] = []
		_aduna(ch, meshes)
		if meshes.is_empty():
			continue
		# ACELASI mesh gazda pe care `_deform` pune deschiderile: cel mai mare
		# ca volum de AABB.
		var mi: MeshInstance3D = meshes[0]
		var best := -1.0
		for m in meshes:
			var vol: float = m.mesh.get_aabb().get_volume()
			if vol > best:
				best = vol
				mi = m
		if not mi.visible:
			continue
		verificate += 1
		var rez := _verifica(ch, mi, uv_dark)
		puncte += int(rez["puncte"])
		var n_rele := int(rez["rele"])
		if n_rele > 0:
			horn_rele += 1
			rele += n_rele
			raport.append("  %s: %d puncte in aer, cel mai rau %.2f m" % [
				ch.name, n_rele, float(rez["worst"])])
		if float(rez["worst"]) > worst:
			worst = float(rez["worst"])
			worst_nm = str(ch.name)

	print("ProbeFerestre — pista %d" % only)
	print("  hornuri cu deschideri : %d" % verificate)
	print("  puncte verificate     : %d" % puncte)
	print("  puncte in aer         : %d (prag %d)" % [rele, MAX_RELE])
	print("  cel mai mare gol      : %.2f m pe %s (prag %.2f)" % [
		worst, worst_nm, MAX_AER])
	for r in raport:
		print(r)
	if puncte == 0:
		# O sonda care nu masoara nimic nu are voie sa treaca verde.
		print("PICAT: n-am gasit nicio deschidere — sonda nu masoara nimic")
		get_tree().quit(1)
		return
	if rele > MAX_RELE:
		print("PICAT: %d puncte de deschidere nu au roca in spate, pe %d hornuri"
			% [rele, horn_rele])
		get_tree().quit(1)
		return
	print("OK")
	get_tree().quit(0)


func _aduna(node: Node, out: Array[MeshInstance3D]) -> void:
	var m := node as MeshInstance3D
	if m != null and m.mesh != null:
		out.append(m)
	for c in node.get_children():
		_aduna(c, out)


## Un horn: se iau vertecsii golurilor (slotul intunecat) din mesh-ul final si,
## pentru fiecare, se intreaba daca peretele ajunge pana la el.
func _verifica(ch: ChimneyShape, mi: MeshInstance3D,
		uv_dark: Vector2) -> Dictionary:
	var src := mi.mesh
	var aabb := src.get_aabb()
	var cx := aabb.position.x + aabb.size.x * 0.5
	var cz := aabb.position.z + aabb.size.z * 0.5
	var y0 := aabb.position.y
	var h := maxf(aabb.size.y, 0.001)
	var ws: float = maxf(ch.global_basis.get_scale().y, 0.001)

	# Vertecsii ROCII: tot ce nu e gol de deschidere. Ei sunt referinta fata de
	# care se judeca plutirea.
	var rock: PackedVector3Array = []
	var gol: PackedVector3Array = []
	for sfc in src.get_surface_count():
		var arrays := src.surface_get_arrays(sfc)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		if uvs.size() != verts.size():
			for v in verts:
				rock.append(v)
			continue
		for i in verts.size():
			if uvs[i].distance_to(uv_dark) < UV_EPS:
				gol.append(verts[i])
			else:
				rock.append(verts[i])
	if gol.is_empty() or rock.is_empty():
		return {"rele": 0, "worst": 0.0, "puncte": 0}

	# Fundul nisei e intentionat INAPOIA peretelui (nisa are adancime), deci
	# masurat singur ar spune mereu "ingropat", nu plutire. Ce se judeca e daca
	# punctul iese IN FATA peretelui, adica exact plutirea.
	var rele := 0
	var worst := 0.0
	var n_ver := 0
	for v in gol:
		var a := atan2(v.z - cz, v.x - cx)
		var r := Vector2(v.x - cx, v.z - cz).length()
		var fy := (v.y - y0) / h
		var r_rock := _raza_rock(rock, cx, cz, y0, h, fy, a)
		if r_rock <= 0.001:
			continue
		n_ver += 1
		var g := (r - r_rock) * ws
		if g > worst:
			worst = g
		if g > MAX_AER:
			rele += 1
	return {"rele": rele, "worst": worst, "puncte": n_ver}


## Raza rocii pe un azimut si o cota, cu fereastra care se largeste pana gaseste
## piatra — ca in `_radius_at`. Fara largire, o felie stramta iese goala fara ca
## peretele sa lipseasca: masurat, 42 din 72 de azimuturi ale lui hornFund42
## pareau "aer" cu felie stramta si 0 cu felie larga.
func _raza_rock(rock: PackedVector3Array, cx: float, cz: float, y0: float,
		h: float, frac: float, azim: float) -> float:
	for win: float in [0.06, 0.12, 0.25, 0.5]:
		var best := 0.0
		for v in rock:
			if absf((v.y - y0) / h - frac) >= win:
				continue
			var da := absf(fposmod(
				atan2(v.z - cz, v.x - cx) - azim + PI, TAU) - PI)
			if da > 0.20:
				continue
			var r := Vector2(v.x - cx, v.z - cz).length()
			if r > best:
				best = r
		if best > 0.001:
			return best
	return 0.0
