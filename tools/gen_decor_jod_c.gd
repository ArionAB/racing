extends Node
## Generator de decor pentru POI C — Fantana in trepte (Track17, Jodhpur).
##   godot --headless --path . res://tools/GenDecorJodC.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorJodC.tscn -- --out=<fisier>

const SCENE := "res://scenes/tracks/Track17.tscn"

var tr: Track
var n: int


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	n = tr.baked.size()
	if "--survey" in args:
		_survey()
	for a in args:
		if a.begins_with("--out="):
			_generate2(a.substr(6))
	if "--check" in args:
		_check()
	if "--camcheck" in args:
		_camcheck()
	if "--lines" in args:
		_lines()
	if "--inspect" in args:
		for m in ["stepwell_flight_module", "stepwell_corner", "stepwell_pavilion", "diya", "floating_diya"]:
			_inspect("res://assets/models/jodhpur/%s.glb" % (("structures/" if m.begins_with("stepwell") else "props/") + m))
	get_tree().quit(0)


func _survey() -> void:
	var wet: Dictionary = tr.get("_ravine_wet")
	var step: float = tr.get("_terr_step")
	var org: Vector3 = tr.get("_terr_origin")
	print("grila %.2f origine %s" % [step, org])
	var line := "       "
	var x := -235.0
	while x <= -50.0:
		line += "|" if int(x) % 25 == 0 else " "
		x += 2.5
	print(line)
	var z := 15.0
	while z <= 110.0:
		line = "%6.1f " % z
		x = -235.0
		while x <= -50.0:
			var p := Vector3(x, 0, z)
			var i := tr.closest_index_global(p)
			var q: Vector3 = tr.baked[i]
			var s := tr._side_at(i)
			var lat := (p - q).dot(s)
			var along := Vector2(p.x - q.x, p.z - q.z).length()
			var y: float = tr._terrain_mesh_y(x, z)
			var cell := Vector2i(int(floor((x - org.x) / step)), int(floor((z - org.z) / step)))
			if along < tr.width_at_index(i) + 0.1 and absf(y - q.y) < 2.0:
				line += "#"
			elif wet.has(cell) and y < -9.5:
				line += "~"
			elif y > 0.5:
				line += "+"
			else:
				line += str(clampi(int(-y), 0, 9))
			x += 2.5
		print(line)
		z += 2.5
	for f in [0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 0.195, 0.198, 0.2, 0.205, 0.21, 0.22, 0.23, 0.24, 0.25, 0.26]:
		var i := int(f * n)
		print("frac %.3f idx %d p %s side %s hw %.1f" % [f, i, tr.baked[i], tr._side_at(i), tr.width_at_index(i)])


func _inspect(path: String) -> void:
	var root := (load(path) as PackedScene).instantiate() as Node3D
	add_child(root)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var xf := root.global_transform.affine_inverse() * m.global_transform
		var arr := m.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for v in vs:
			var w := xf * v
			lo = lo.min(w)
			hi = hi.max(w)
		# ce parte are relief (trepte): numara vertecsii in banda exterioara de 0.6 m pe X si pe Z
		var zp := 0
		var zn := 0
		var xp := 0
		var xn := 0
		for v in vs:
			var w := xf * v
			if w.z > hi.z - 0.6: zp += 1
			if w.z < lo.z + 0.6: zn += 1
			if w.x > hi.x - 0.6: xp += 1
			if w.x < lo.x + 0.6: xn += 1
		print("%s %s: aabb %s .. %s | vertecsi +z %d -z %d +x %d -x %d (din %d)" % [path.get_file(), m.name, lo, hi, zp, zn, xp, xn, vs.size()])
	root.queue_free()


## Unde trece terenul peretelui prin cotele de baza ale etajelor (-3.12, -6.24,
## -9.36), masurat perpendicular pe perete, de la marginea asfaltului in afara.
func _contour(start: Vector3, dir: Vector3, level: float) -> float:
	var d := 0.0
	while d < 40.0:
		var q := start + dir * d
		if tr._terrain_mesh_y(q.x, q.z) >= level:
			return d
		d += 0.25
	return -1.0


func _lines() -> void:
	var levels := [-3.12, -6.24, -9.36]
	print("brat de intrare (perete la +z): x, drum y, z-ul conturului per etaj")
	var x := -195.0
	while x <= -90.0:
		var i := tr.closest_index_global(Vector3(x, 0, 73))
		var q: Vector3 = tr.baked[i]
		var st := Vector3(x, 0, q.z + tr.width_at_index(i))
		var out := "  x %6.1f y %+5.1f edge z %.1f :" % [x, q.y, st.z]
		for L in levels:
			var d := _contour(st, Vector3(0, 0, 1), L)
			out += "  %5.1f" % (st.z + d if d >= 0.0 else -1.0)
		print(out)
		x += 5.0
	print("brat de iesire (perete la -z)")
	x = -200.0
	while x <= -95.0:
		var i := tr.closest_index_global(Vector3(x, 0, 51))
		var q: Vector3 = tr.baked[i]
		var st := Vector3(x, 0, q.z - tr.width_at_index(i))
		var out := "  x %6.1f y %+5.1f edge z %.1f :" % [x, q.y, st.z]
		for L in levels:
			var d := _contour(st, Vector3(0, 0, -1), L)
			out += "  %5.1f" % (st.z - d if d >= 0.0 else -1.0)
		print(out)
		x += 5.0
	print("perete de est (perete la +x), pornind de la x -84")
	var z := 30.0
	while z <= 95.0:
		var st := Vector3(-84.0, 0, z)
		var out := "  z %6.1f teren %+5.1f :" % [z, tr._terrain_mesh_y(-84.0, z)]
		for L in levels:
			var d := _contour(st, Vector3(1, 0, 0), L)
			out += "  %6.1f" % (st.x + d if d >= 0.0 else -1.0)
		print(out)
		z += 5.0


## ---------------------------------------------------------------------------
## GENERAREA
##
## Treptele sunt ETAJE ORIZONTALE la cote fixe, ca intr-o fantana reala: varful
## etajului k e la -3.12*k (buza debleului e la 0), baza la -3.12*(k+1). Drumul
## coboara PRIN etaje (rampa de ~9 %), deci pe capul rampei se vede doar etajul
## de sus, la fund toate trei.
##
## Fata fiecarui etaj urmeaza CONTURUL terenului la cota bazei lui (sondat cu
## `_contour`), ca baza sa fie ingropata si nu suspendata: linia etajului e
## regresia liniara a conturului pe brat, impinsa spre perete pana acopera
## toate esantioanele. Etajul de jos (baza -9.36, sub fundul drumului) nu are
## contur: fata lui e la 2 m de marginea asfaltului (banda + 0.5 m, cu
## rezerva), paralel cu drumul.
##
## Modulul `stepwell_flight_module`: 12.2 x 3.12 x 3.0, originea la baza,
## treptele pe fata -Z (masurat cu --inspect: 1678 de vertecsi pe -z fata de
## 28 pe +z). Deci bazisul pune +Z local pe normala spre perete. Adancimea se
## scaleaza ca etajul sa ajunga pana la fata etajului de deasupra (terasa
## plina, nu panta de pamant intre etaje).

const MOD_W := 12.2
const MOD_D := 3.0
const TIER_H := 3.12
const TIER_TOP := [0.0, -3.12, -6.24]
const LANE_KEEP := 1.2  # fata etajului de jos: metri de la marginea asfaltului

var _out := PackedStringArray()
var _diya := PackedVector3Array()
var _diya_yaw := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _node_i := 0


## Linia fetei unui etaj: d = a + b*u (u = coordonata de-a lungul peretelui),
## impinsa spre perete (outward = +1/-1) pana acopera toate esantioanele.
func _fit(us: Array, ds: Array, outward: float) -> Vector2:
	var m := us.size()
	var su := 0.0
	var sd := 0.0
	var suu := 0.0
	var sud := 0.0
	for k in m:
		su += us[k]
		sd += ds[k]
		suu += us[k] * us[k]
		sud += us[k] * ds[k]
	var den := m * suu - su * su
	var b := 0.0 if absf(den) < 1e-6 else (m * sud - su * sd) / den
	var a := (sd - b * su) / m
	# fara impingere globala: linia da doar ORIENTAREA; fiecare modul isi ia
	# fata din conturul local (`_local_front`), altfel un singur esantion
	# departat impinge tot etajul in teren si il ingroapa (runda 1: 17 module).
	return Vector2(a, b)


## Cat trebuie mutata fata modulului spre perete (outward) ca baza lui sa fie
## pe teren pe toata latimea: conturul cotei `level` pe trei esantioane
## (capete si mijloc), relativ la `mid`. Negativ = conturul e mai aproape de
## drum decat linia (modulul se trage in fata, dar niciodata mai mult de 3 m).
func _local_front(mid: Vector3, along: Vector3, outward: Vector3, level: float) -> float:
	var best := -3.0
	for sft: float in [-5.5, 0.0, 5.5]:
		var p := mid + along * sft - outward * 3.0
		var d := _contour(p, outward, level)
		if d >= 0.0:
			best = maxf(best, d - 3.0)
	return best


func _xf(front_mid: Vector3, along: Vector3, outward: Vector3, sx: float, sz: float, y: float) -> Transform3D:
	var bx := along.normalized() * sx
	var bz := outward.normalized() * sz
	var basis := Basis(bx, Vector3.UP, bz)
	var origin := front_mid + outward.normalized() * (MOD_D * sz * 0.5)
	origin.y = y
	return Transform3D(basis, origin)


func _emit(name: String, res: String, xf: Transform3D, anchor := Vector3.INF) -> void:
	_out.append('[node name="%s" parent="DecorManual/ZoneC_Fantana" instance=ExtResource("%s")]' % [name, res])
	_out.append("transform = " + var_to_str(xf))
	if anchor != Vector3.INF:
		# fatada lipita de perete: probe_manual judeca muchia de jos a fetei
		_out.append("metadata/ancora_sol = " + var_to_str(anchor))
	_out.append("")


## Pozitiile locale ale treptelor unui modul (pentru candele): 3 V-uri,
## varfuri la x -4/0/4, puncte joase la -6/-2/2/6, treapta de 0.3 m, treapta
## iese 0.45 m din fata (z local -1.5 .. -1.05).
func _step_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for a: float in [-4.0, 0.0, 4.0]:
		for side: float in [-1.0, 1.0]:
			for k in range(1, 10, 2):
				var t := float(k) / 9.0
				var x: float = a + side * 2.0 * (1.0 - t)
				var y := 0.3 + (3.0 - 0.3) * t
				out.append(Vector3(x, y, -1.3))
	return out


## probe_manual judeca muchia de jos a fetei pe `_sampler.ground_y` (campul
## neted), nu pe suprafata randata: pe peretele debleului cele doua difera cu
## 2-3 m (grila de 7,9 m). Modulul se trage spre drum pana cand campul il
## accepta (|delta| < 2), dar niciodata sub suprafata randata cu mai mult de
## 0,4 m (atunci ar pluti vizibil) si niciodata pe banda. Altfel se renunta.
func _sampler_ok(front_mid: Vector3, outward: Vector3, base: float) -> float:
	var pull := 0.0
	while pull <= 2.5:
		var p := front_mid - outward * pull
		var g: float = tr._sampler.ground_y(p.x, p.z)
		var m: float = tr._terrain_mesh_y(p.x, p.z)
		if m < base - 0.4:
			return -1.0
		if g - base < 1.9 and base - g < 2.9:
			return pull
		pull += 0.25
	return -1.0


## Modul intr-o stiva: fara tragerea spre drum din `_sampler_ok` (ar rupe
## stiva: fata etajului de sus trebuie sa stea pe spatele celui de jos).
func _module_at(tag: String, k: int, front_mid: Vector3, along: Vector3, outward: Vector3, sx: float, sz: float, base_y := INF) -> void:
	var y: float = TIER_TOP[k] - TIER_H
	var sy := 1.0
	if base_y != INF:
		# etajul de jos al stivei, scurtat pe verticala: varful ramane la cota
		# etajului, baza coboara doar 0,3 m sub teren (altfel s-ar ingropa 2-3 m)
		sy = (TIER_TOP[k] - base_y) / TIER_H
		y = base_y
	var xf := _xf(front_mid, along, outward, sx, sz, y)
	xf.basis.y *= sy
	# probe_manual judeca muchia fetei pe campul neted (`_sampler`), care pe
	# peretele debleului difera de suprafata randata cu 2-3 m. Unde campul
	# respinge baza, piesa nu se pune (raportat), nu se falsifica ancora.
	var fb := xf * Vector3(0, 0, -1.5)
	var gs: float = tr._sampler.ground_y(fb.x, fb.z)
	if gs - fb.y > 1.95 or fb.y - gs > 2.95:
		print("  sar peste %s etaj %d la %s: campul %.2f fata de baza %.2f" % [tag, k, fb, gs, fb.y])
		return
	_node_i += 1
	_emit("Trepte_%s_E%d_%02d" % [tag, k, _node_i], "s_stepwell_flight_module", xf, Vector3(0, 0, -1.5))
	_candles(xf, sx)


func _candles(xf: Transform3D, sx: float) -> void:
	for sp in _step_spots():
		if _rng.randf() < 0.7:
			_diya.append(xf * sp)
			_diya_yaw.append(_rng.randf() * TAU)
	var n_edge := int(MOD_W * sx / 1.1)
	for e in n_edge:
		if _rng.randf() < 0.8:
			var lx := -MOD_W * 0.5 + (float(e) + 0.5 + _rng.randf_range(-0.3, 0.3)) * MOD_W / n_edge
			_diya.append(xf * Vector3(lx, 3.24, -1.3))
			_diya_yaw.append(_rng.randf() * TAU)


func _module(tag: String, k: int, front_mid: Vector3, along: Vector3, outward: Vector3, sx: float, sz: float) -> void:
	var y: float = TIER_TOP[k] - TIER_H
	var pull := _sampler_ok(front_mid, outward, y)
	if pull < 0.0:
		print("  sar peste %s etaj %d la %s: campul nu accepta baza" % [tag, k, front_mid])
		return
	front_mid -= outward * pull
	if _clear_road(front_mid, along, outward) > 0.0:
		print("  sar peste %s etaj %d la %s: ar intra pe banda" % [tag, k, front_mid])
		return
	var xf := _xf(front_mid, along, outward, sx, sz, y)
	_node_i += 1
	_emit("Trepte_%s_E%d_%02d" % [tag, k, _node_i], "s_stepwell_flight_module", xf, Vector3(0, 0, -1.5))
	for sp in _step_spots():
		if _rng.randf() < 0.7:
			_diya.append(xf * sp)
			_diya_yaw.append(_rng.randf() * TAU)
	var n_edge := int(MOD_W * sx / 1.1)
	for e in n_edge:
		if _rng.randf() < 0.8:
			var lx := -MOD_W * 0.5 + (float(e) + 0.5 + _rng.randf_range(-0.3, 0.3)) * MOD_W / n_edge
			_diya.append(xf * Vector3(lx, 3.24, -1.3))
			_diya_yaw.append(_rng.randf() * TAU)


## Cat trebuie impinsa fata spre perete ca fiecare punct al ei (capete si
## mijloc) sa stea la >= semilatime + LANE_KEEP de axa drumului. Decorul e
## fara coliziune: pe banda ar fi o fantoma prin care trece masina.
func _clear_road(front: Vector3, along: Vector3, outward: Vector3) -> float:
	var push := 0.0
	for it in 40:
		var ok := true
		for sft: float in [-6.1, -3.0, 0.0, 3.0, 6.1]:
			var p := front + outward * push + along * sft
			var i := tr.closest_index_global(p)
			var q: Vector3 = tr.baked[i]
			var dd := Vector2(p.x - q.x, p.z - q.z).length()
			if dd < tr.width_at_index(i) + LANE_KEEP:
				ok = false
				break
		if ok:
			return push
		push += 0.25
	return push


## Vizibil daca terenul din fata etajului e cu cel putin 1 m sub varful lui.
func _visible_at(p: Vector3, k: int) -> bool:
	return tr._terrain_mesh_y(p.x, p.z) < TIER_TOP[k] - 1.0


func _generate(path: String) -> void:
	_rng.seed = 20260929
	var levels := [-3.12, -6.24, -9.36]
	var south := {}
	var north := {}
	var east := {}
	for k in 3:
		var us := []
		var ds := []
		var usn := []
		var dsn := []
		var x := -195.0
		while x <= -100.0:
			var i := tr.closest_index_global(Vector3(x, 0, 73))
			var q: Vector3 = tr.baked[i]
			var edge := q.z + tr.width_at_index(i)
			if k == 2:
				us.append(x)
				ds.append(edge + LANE_KEEP)
			elif q.y < levels[k] + 0.5:
				var d := _contour(Vector3(x, 0, edge), Vector3(0, 0, 1), levels[k])
				if d > 0.5:
					us.append(x)
					ds.append(edge + d)
			var j := tr.closest_index_global(Vector3(x, 0, 51))
			var r: Vector3 = tr.baked[j]
			var edge_n := r.z - tr.width_at_index(j)
			if k == 2:
				usn.append(x)
				dsn.append(edge_n - LANE_KEEP)
			elif r.y < levels[k] + 0.5:
				var d2 := _contour(Vector3(x, 0, edge_n), Vector3(0, 0, -1), levels[k])
				if d2 > 0.5:
					usn.append(x)
					dsn.append(edge_n - d2)
			x += 2.0
		south[k] = _fit(us, ds, 1.0)
		north[k] = _fit(usn, dsn, -1.0)
		var xe := -84.0
		if k == 2:
			var apex_x := -INF
			for i2 in range(int(0.19 * n), int(0.207 * n)):
				apex_x = maxf(apex_x, tr.baked[i2].x + tr.width_at_index(i2))
			xe = apex_x + LANE_KEEP
		else:
			var z := 50.0
			while z <= 70.0:
				var d3 := _contour(Vector3(-84.0, 0, z), Vector3(1, 0, 0), levels[k])
				xe = maxf(xe, -84.0 + d3)
				z += 2.0
		east[k] = xe
		print("etaj %d: sud z = %.2f %+.4f x (%d es) | nord z = %.2f %+.4f x (%d es) | est x = %.2f" % [k, south[k].x, south[k].y, us.size(), north[k].x, north[k].y, usn.size(), east[k]])

	# ---- STIVE (runda 1, a doua trecere): pe fiecare statie a peretelui
	# etajele se aseaza de jos in sus, fiecare cu fata EXACT pe spatele celui
	# de dedesubt. Prima trecere punea fiecare etaj pe conturul lui propriu,
	# independent, iar intre etaje ramanea o fasie de nisip in panta de ~2 m:
	# pe captura 0.160 modulele citeau ca banci suspendate peste nisip, nu
	# ca zid de piatra in trepte. Adancimea fiecarui etaj ajunge pana unde
	# terenul atinge varful lui (spatele ingropat), deci terasa e piatra.
	var stations: Array[Dictionary] = []
	# bratul de intrare (sud) si de iesire (nord): statii la 12.2 m pe x,
	# de la acul de est spre vest
	for arm in ["S", "N"]:
		var z_ref := 73.0 if arm == "S" else 51.0
		var x := -92.0
		while x >= -205.0:
			var i := tr.closest_index_global(Vector3(x, 0, z_ref))
			var q: Vector3 = tr.baked[i]
			var sd := tr._side_at(i)
			# peretele e pe DREAPTA drumului (debleul): +side pe ambele brate
			var tang := sd.cross(Vector3.UP) * -1.0
			var edge := q + sd * tr.width_at_index(i)
			edge.y = 0.0
			# peretele sub ~2,5 m (capul rampelor) nu tine o stiva: un etaj de
			# 3,12 m cu terasa de 7 m iesea punte suspendata peste panta
			# (capturile 0.130 si 0.260)
			if q.y > -2.3:
				x -= MOD_W
				continue
			stations.append({"tag": arm, "edge": edge, "n": sd, "a": tang, "sx": 1.0})
			x -= MOD_W
	# peretele de est (in spatele acului): normala +x, statii pe z
	var apex_x := -INF
	for i2 in range(int(0.19 * n), int(0.207 * n)):
		apex_x = maxf(apex_x, tr.baked[i2].x + tr.width_at_index(i2))
	for zc: float in [49.8, 62.0, 74.2]:
		stations.append({"tag": "Est", "edge": Vector3(apex_x, 0, zc), "n": Vector3(1, 0, 0), "a": Vector3(0, 0, -1), "sx": 1.0})

	var pav_front := -INF
	for st in stations:
		var edge: Vector3 = st["edge"]
		var nv: Vector3 = st["n"]
		var av: Vector3 = st["a"]
		# mana dreapta: X = Y x Z -> a trebuie sa fie UP x n ... verifica
		if av.cross(Vector3.UP).dot(nv) < 0.0:
			av = -av
		var f_prev := -1.0
		for k in [2, 1, 0]:
			var base: float = TIER_TOP[k] - TIER_H
			var top: float = TIER_TOP[k]
			var f: float
			var base_y := INF
			if f_prev < 0.0:
				# etajul de jos: fata la LANE_KEEP de asfalt (nu la contur, altfel
				# ramane o panta de nisip intre drum si zid); se alege etajul in
				# care cade terenul de acolo, iar baza lui se ridica la teren - 0,3
				var fr := edge + nv * LANE_KEEP
				fr += nv * _clear_road(fr, av, nv)
				var gmin := INF
				var gmax := -INF
				for sft: float in [-5.5, 0.0, 5.5]:
					var pp := fr + av * sft + nv * 0.3
					var gy: float = tr._terrain_mesh_y(pp.x, pp.z)
					gmin = minf(gmin, gy)
					gmax = maxf(gmax, gy)
				# primul etaj (de jos in sus) al carui varf trece de teren cu 0,25 m;
				# baza lui se muta la teren - 0,3 (scurtat sau lungit pe verticala)
				if top < gmax + 0.25:
					continue
				if (top - (gmin - 0.3)) / TIER_H > 1.6:
					continue
				f = (fr - edge).dot(nv)
				base_y = gmin - 0.3
			else:
				f = f_prev
				var probe2 := edge + nv * (f + 0.3)
				if tr._terrain_mesh_y(probe2.x, probe2.z) > top - 0.3:
					break  # restul stivei e sub teren
			# adancimea: pana unde terenul atinge varful etajului (max pe latime)
			var reach := -1.0
			for sft2: float in [-5.5, 0.0, 5.5]:
				var c2 := _contour(edge + av * sft2, nv, top - 0.3)
				if c2 > reach:
					reach = c2
			var depth := clampf(reach - f, MOD_D, 7.5) if reach > 0.0 else 7.5
			var front := edge + nv * f
			front += nv * _clear_road(front, av, nv)
			_module_at(String(st["tag"]), k, front, av, nv, float(st["sx"]), depth / MOD_D, base_y)
			f_prev = (front - edge).dot(nv) + depth
		if st["tag"] == "Est" and absf(edge.z - 62.0) < 1.0:
			pav_front = edge.x + maxf(f_prev, 0.0)

	# ---- pavilionul pe buza peretelui de est, cu fata (-Z local) spre groapa,
	# pe axa acului, cu fata pe spatele etajului de sus (1 m inapoi)
	var pc := Vector3(pav_front - 1.0 + 4.19, 0, 62.0)
	var pb := INF
	for dx: float in [-4.0, 0.0, 4.0]:
		for dz: float in [-10.0, 0.0, 10.0]:
			pb = minf(pb, tr._terrain_mesh_y(pc.x + dx, pc.z + dz))
	pc.y = clampf(pb, -1.9, 0.0)
	_emit("Pavilion", "s_stepwell_pavilion", Transform3D(Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0)), pc))
	print("pavilion la %s (teren minim %.2f)" % [pc, pb])

	# ---- candele plutitoare pe apa (celule ude, fundul sub -9.8), mai dese spre ac
	var wet: Dictionary = tr.get("_ravine_wet")
	var step: float = tr.get("_terr_step")
	var org: Vector3 = tr.get("_terr_origin")
	var fl := PackedVector3Array()
	var fly := PackedFloat32Array()
	var gx := -210.0
	while gx <= -88.0:
		var gz := 52.0
		while gz <= 72.0:
			var px := gx + _rng.randf_range(-1.1, 1.1)
			var pz2 := gz + _rng.randf_range(-1.1, 1.1)
			var cell := Vector2i(int(floor((px - org.x) / step)), int(floor((pz2 - org.z) / step)))
			var ty: float = tr._terrain_mesh_y(px, pz2)
			if wet.has(cell) and ty < -9.8:
				var w := clampf((px + 210.0) / 120.0, 0.0, 1.0)
				if _rng.randf() < 0.35 + 0.5 * w:
					fl.append(Vector3(px, -9.5, pz2))
					fly.append(_rng.randf() * TAU)
			gz += 2.2
		gx += 2.2
	print("module %d, candele pe trepte %d, candele plutitoare %d" % [_node_i, _diya.size(), fl.size()])
	_flock("Candele_Trepte", "s_diya", _diya, _diya_yaw, 3.2, 4.2)
	_flock("Candele_Apa", "s_floating_diya", fl, fly, 2.4, 3.2)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(_out))
	f.close()


func _flock(name: String, res: String, pos: PackedVector3Array, yw: PackedFloat32Array, smin: float, smax: float) -> void:
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="DecorManual/ZoneC_Fantana"]' % name)
	_out.append('script = ExtResource("flock")')
	_out.append('model = ExtResource("%s")' % res)
	_out.append("positions = " + var_to_str(pos))
	_out.append("yaws = " + var_to_str(yw))
	_out.append("scale_min = %.2f" % smin)
	_out.append("scale_max = %.2f" % smax)
	# candelele ard: flacara + haloul fals (FlockProp.halo_enabled, LampHalo)
	if res.contains("diya"):
		_out.append("halo_enabled = true")
	_out.append("")


## Profilul fiecarui modul asezat: terenul randat sub muchia fetei, la mijloc
## si la spate, fata de baza si varful modulului (pe trei puncte pe latime).
func _check() -> void:
	var zone := tr.get_node("DecorManual/ZoneC_Fantana")
	for c in zone.get_children():
		if not String(c.name).begins_with("Trepte_"):
			continue
		var xf: Transform3D = (c as Node3D).global_transform
		var base := xf.origin.y
		var out := "%-20s baza %+6.2f |" % [c.name, base]
		for lz: float in [-1.5, 0.0, 1.5]:
			var worst := -INF
			var best := INF
			for lx: float in [-5.5, 0.0, 5.5]:
				var p := xf * Vector3(lx, 0, lz)
				var y: float = tr._terrain_mesh_y(p.x, p.z) - base
				worst = maxf(worst, y)
				best = minf(best, y)
			out += "  z%+.1f: %+5.2f..%+5.2f" % [lz, best, worst]
		print(out)


## Camera (fara coliziune pe decor, deci ProbeCameraSolid nu vede treptele):
## punctul camerei aproximat ca in ChaseCamera cu CameraFantana (13 m sus,
## 12,5 m in spate pe tangenta) si distanta pana la cutia locala a fiecarei
## piese din ZoneC. Negativ = camera in piesa.
func _camcheck() -> void:
	var zone := tr.get_node("DecorManual/ZoneC_Fantana")
	var boxes := []
	for c in zone.get_children():
		var nm := String(c.name)
		var aabb: AABB
		if nm.begins_with("Trepte_"):
			aabb = AABB(Vector3(-6.1, 0, -1.5), Vector3(12.2, 3.24, 3.0))
		elif nm == "Pavilion":
			aabb = AABB(Vector3(-10.28, 0, -4.19), Vector3(20.56, 10.9, 8.38))
		else:
			continue
		boxes.append([nm, (c as Node3D).global_transform, aabb])
	# runda 2: modulele sunt in MultiMesh-ul `Trepte` (FlockProp)
	var mm := zone.get_node_or_null("Trepte")
	if mm != null:
		var pos: PackedVector3Array = mm.get("positions")
		var yw: PackedFloat32Array = mm.get("yaws")
		var sc: Array = mm.get("scale3_list")
		for j in pos.size():
			var xf := Transform3D(Basis(Vector3.UP, yw[j]) * Basis.from_scale(sc[j]), pos[j])
			boxes.append(["Trepte#%d" % j, xf, AABB(Vector3(-6.1, 0, -1.5), Vector3(12.2, 3.24, 3.0))])
	var worst := INF
	var worst_at := ""
	for i in range(int(0.125 * n), int(0.275 * n)):
		var p: Vector3 = tr.baked[i]
		var back: Vector3 = (tr.baked[i] - tr.baked[maxi(i - 6, 0)]).normalized()
		var cam := p - back * 12.5 + Vector3.UP * 13.0
		for b in boxes:
			var xf: Transform3D = b[1]
			var loc := xf.affine_inverse() * cam
			var bb: AABB = b[2]
			# distanta in metri (aproximativ, scala locala ~1..2.5)
			var q := loc.clamp(bb.position, bb.end)
			var d := (xf * q).distance_to(cam)
			if bb.has_point(loc):
				d = -1.0
			if d < worst:
				worst = d
				worst_at = "%s la frac %.3f (camera %s)" % [b[0], float(i) / n, cam]
	print("camera: cea mai mica distanta la o piesa din C = %.2f m, %s" % [worst, worst_at])


## ===========================================================================
## RUNDA 2 — IMBRACAMINTE CONTINUA
##
## Verdictul orb al rundei 1: „treptele sunt blocuri disparate, ca niste mici
## fortificatii pe nisip, cu pete goale intre ele". Cauza: stive independente
## pe statii de 12,2 m, fiecare cu fata si adancimea ei. Acum:
##
##  * PERETELE DIN DREAPTA e un singur contur care inconjoara groapa (bratul
##    de intrare -> acul -> bratul de iesire), la offset fata de marginea
##    asfaltului. Pe fiecare statie (pas 2 m pe drum) se calculeaza etajul de
##    jos (cel in care cade terenul de la 2 m de asfalt) si fetele etajelor
##    de deasupra (conturul terenului la cota bazei lor, netezit pe +-14 m).
##    Pe fiecare etaj modulele se INLANTUIE pe acea polilinie: coarda se
##    inchide la 12,2 m sau cand sageata trece de 0,35 m (acul), iar ultimul
##    modul dintr-o serie se scurteaza. Modulele se lungesc cu
##    adancime*tan(unghi/2) la fiecare capat, ca pe curba sa nu ramana pene
##    de nisip intre spatele lor.
##  * TERASELE ADANCI: adancimea unui etaj se umple cu RANDURI de module
##    nescalate (3 m fiecare, lipite spate-fata), nu cu un modul intins pe Z —
##    un modul intins de 2,5x isi intindea si treptele (0,45 -> 1,1 m) si
##    citea ca punte. Treptele randurilor din spate intra in plinul
##    randului din fata, deci nu se vad; fetele de sus sunt la aceeasi cota,
##    deci terasa e o suprafata de piatra continua.
##  * MALUL DINSPRE APA (stanga): un rand de module cu fata spre apa, spatele
##    la 0,3 m de asfalt, varful la 0,35 m SUB drum, baza sub apa/teren.
##  * Totul intr-un singur MultiMesh (`FlockProp`, clasa `rose_sandstone`,
##    aceeasi ca `Well_Stone` in world_prop): sute de module ar fi sute de
##    desene ca noduri.

const PAV_HALF_D := 4.19
var DEBUG := false
const SAG_MAX := 0.35
const FRAC_A := 0.135
const FRAC_B := 0.264

var _mm_pos := PackedVector3Array()
var _mm_yaw := PackedFloat32Array()
var _mm_sc: Array[Vector3] = []
var _road_diya := PackedVector3Array()


func _gy(p: Vector3) -> float:
	return tr._terrain_mesh_y(p.x, p.z)


## Un modul in MultiMesh. `front_mid` = mijlocul fetei (cu trepte), `outward`
## = +Z local (dinspre fata spre spate).
func _mm_module(front_mid: Vector3, along: Vector3, outward: Vector3, sx: float, sz: float, base: float, top: float, candles: bool) -> void:
	var sy := (top - base) / TIER_H
	if sy < 0.08:
		return
	var o := outward.normalized()
	var a := along.normalized()
	if a.cross(Vector3.UP).dot(o) < 0.0:
		a = -a
	var origin := front_mid + o * (MOD_D * sz * 0.5)
	origin.y = base
	var xf := Transform3D(Basis(a * sx, Vector3.UP * sy, o * sz), origin)
	_mm_pos.append(origin)
	_mm_yaw.append(atan2(o.x, o.z))
	_mm_sc.append(Vector3(sx, sy, sz))
	if not candles:
		return
	# sir des pe buza terasei (1,1-1,5 m) + candele pe V-uri (doar unde
	# modulul e destul de inalt ca V-urile sa se vada)
	var span := MOD_W * sx
	var cnt := int(span / 1.3)
	for e in cnt:
		var lx := -MOD_W * 0.5 + (float(e) + 0.5 + _rng.randf_range(-0.25, 0.25)) * MOD_W / cnt
		_diya.append(xf * Vector3(lx, 3.24, -1.32))
		_diya_yaw.append(_rng.randf() * TAU)
	if sy > 0.6:
		for sp in _step_spots():
			if _rng.randf() < 0.45:
				_diya.append(xf * sp)
				_diya_yaw.append(_rng.randf() * TAU)


func _median(arr: Array, i: int, w: int) -> float:
	var vals: Array = []
	for j in range(maxi(0, i - w), mini(arr.size(), i + w + 1)):
		if arr[j] > -900.0:
			vals.append(arr[j])
	if vals.is_empty():
		return -999.0
	vals.sort()
	return vals[vals.size() / 2]


## Inlantuie module pe o serie de statii [s0, s1] la offset-urile date.
## pts[i] = punctul fetei, nrm[i] = normala spre perete, depth[i], base[i].
func _chain(pts: Array, nrm: Array, depth: Array, base: Array, top: float, s0: int, s1: int, candles: bool) -> int:
	var placed := 0
	var a := s0
	while a < s1:
		# cauta capatul corzii
		var b := a + 1
		while b < s1:
			var nb := b + 1
			var chord: float = (pts[nb] - pts[a]).length()
			if chord > MOD_W:
				break
			var sag := 0.0
			for m in range(a + 1, nb):
				var d: Vector3 = pts[m] - pts[a]
				var c: Vector3 = (pts[nb] - pts[a]).normalized()
				sag = maxf(sag, (d - c * d.dot(c)).length())
			if sag > SAG_MAX:
				break
			b = nb
		# ultima bucata prea scurta: lipeste-o la coarda curenta
		if s1 - b <= 2 and s1 - b > 0 and (pts[s1] - pts[a]).length() < MOD_W * 1.35:
			b = s1
		var pa: Vector3 = pts[a]
		var pb: Vector3 = pts[b]
		var chord_v := pb - pa
		chord_v.y = 0.0
		var L := chord_v.length()
		if L < 1.0:
			a = b
			continue
		var al := chord_v / L
		var nv := Vector3.ZERO
		var dep := 0.0
		var bs := INF
		for m in range(a, b + 1):
			nv += nrm[m]
			dep = maxf(dep, depth[m])  # max: spatele intra in etajul de sus, nu lasa nisip
			bs = minf(bs, base[m])
		nv = (nv - al * nv.dot(al)).normalized()
		# unghiul cu vecinii -> prelungire ca sa inchida penele din spate
		var ext := 0.3
		if a > s0:
			var prev: Vector3 = (pts[a] - pts[maxi(s0, a - 3)])
			prev.y = 0.0
			if prev.length() > 0.5:
				ext = maxf(ext, dep * tan(prev.normalized().angle_to(al) * 0.5))
		if b < s1:
			var nxt: Vector3 = (pts[mini(s1, b + 3)] - pts[b])
			nxt.y = 0.0
			if nxt.length() > 0.5:
				ext = maxf(ext, dep * tan(al.angle_to(nxt.normalized()) * 0.5))
		ext = minf(ext, 2.5)
		var sx := (L + 2.0 * ext) / MOD_W
		var mid := (pa + pb) * 0.5
		mid.y = 0.0
		# randuri de 3 m pe adancime, nescalate pe Z
		var rows := maxi(1, int(ceil(dep / MOD_D - 0.2)))
		var sz := clampf(dep / (rows * MOD_D), 0.5, 1.25)
		for r in rows:
			_mm_module(mid + nv * (r * MOD_D * sz), al, nv, sx, sz, bs, top, candles and r == 0)
			placed += 1
		a = b
	return placed


func _generate2(path: String) -> void:
	_rng.seed = 20260930
	DEBUG = "--debug" in OS.get_cmdline_user_args()
	var i0 := int(FRAC_A * n)
	var i1 := int(FRAC_B * n)
	var levels := [-3.12, -6.24, -9.36]
	# ---- statiile peretelui din dreapta
	var E: Array = []    # marginea asfaltului
	var N: Array = []    # normala spre perete
	var Y: Array = []    # cota drumului
	var G2: Array = []   # terenul la 2 m de asfalt
	var C: Array = [[], [], []]  # contururile bazelor (etaj 0, 1) + buza (-0.3)
	for i in range(i0, i1 + 1):
		var q: Vector3 = tr.baked[i]
		var sd := tr._side_at(i)
		var e := q + sd * tr.width_at_index(i)
		e.y = 0.0
		E.append(e)
		N.append(sd)
		Y.append(q.y)
		var p2 := e + sd * (LANE_KEEP + 0.3)
		G2.append(_gy(p2))
		for k in 2:
			var d := _contour(e, sd, levels[k])
			C[k].append(d if d >= 0.0 else -999.0)
		var dl := _contour(e, sd, -0.3)
		C[2].append(dl if dl >= 0.0 else -999.0)
	var S := E.size()
	var Cs: Array = [[], [], []]
	# mediana pe +-24 m, apoi medie pe +-8 m: fetele etajelor trebuie sa fie
	# linii line, altfel coarda dintre doua statii cu offset-uri diferite iese
	# modul pus in diagonala (runda 2, prima captura)
	for k in 3:
		var med: Array = []
		for i in S:
			med.append(_median(C[k], i, 12))
		for i in S:
			var acc := 0.0
			var cn := 0
			for j in range(maxi(0, i - 4), mini(S, i + 5)):
				if med[j] > -900.0:
					acc += med[j]
					cn += 1
			Cs[k].append(acc / cn if cn > 0 else -999.0)
	# anvelopa Lipschitz de jos: fata unui etaj nu se departeaza de drum cu
	# mai mult de 0,5 m pe statie (2 m), altfel coarda iese in diagonala
	# (runda 2: pene inclinate langa camera la 0.150-0.166). Unde fata vine
	# mai aproape decat conturul, etajul sta pe spatele celui de dedesubt.
	for k in 3:
		var env: Array = []
		for i in S:
			var best := 999.0
			for j in S:
				if Cs[k][j] > -900.0:
					best = minf(best, float(Cs[k][j]) + 0.4 * absf(i - j))
			env.append(best if Cs[k][i] > -900.0 else -999.0)
		Cs[k] = env
	# etajul de jos pe statie, apoi filtru de moda (+-3) ca sa nu clipeasca
	var braw: Array = []
	for i in S:
		var b := -1
		for k in [2, 1, 0]:
			if TIER_TOP[k] >= float(G2[i]) + 0.25:
				b = k
				break
		# pe capul rampelor etajul de jos ar fi o placa sub 1,2 m: citea
		# scanduri puse pe nisip (captura r2 0.130 / 0.260), deci nimic
		if b == 0 and float(G2[i]) > -1.2 + 0.3:
			b = -1
		braw.append(b)
	var bot: Array = []
	for i in S:
		var cnt := {}
		for j in range(maxi(0, i - 3), mini(S, i + 4)):
			cnt[braw[j]] = int(cnt.get(braw[j], 0)) + 1
		var best: int = braw[i]
		for key in cnt:
			if cnt[key] > cnt.get(best, 0):
				best = key
		bot.append(best)
	# offset-urile fetelor pe statie: front[k][i] (-1 = etajul nu exista)
	var front: Array = [[], [], []]
	var back: Array = [[], [], []]
	for i in S:
		var b: int = bot[i]
		for k in 3:
			front[k].append(-1.0)
			back[k].append(-1.0)
		if b < 0:
			continue
		var f_prev := -1.0
		for k in range(b, -1, -1):
			var f: float
			if k == b:
				f = LANE_KEEP
			else:
				f = maxf(float(Cs[k][i]) if Cs[k][i] > -900.0 else f_prev + 3.0, f_prev + 2.0)
			front[k][i] = f
			f_prev = f
		for k in range(b, -1, -1):
			var bk: float
			if k > 0 and front[k - 1][i] > 0.0:
				bk = front[k - 1][i]
			else:
				var lip: float = Cs[2][i] if Cs[2][i] > -900.0 else front[k][i] + 3.0
				bk = clampf(lip, front[k][i] + 3.0, front[k][i] + 12.0)
			back[k][i] = bk
	if DEBUG:
		for i in range(0, S, 4):
			print("  perete f %.3f drum %+.2f G2 %+.2f bot %d | C0 %.1f C1 %.1f lip %.1f | fronts %.1f %.1f %.1f backs %.1f %.1f %.1f" % [float(i0 + i) / n, Y[i], G2[i], bot[i], Cs[0][i], Cs[1][i], Cs[2][i], front[0][i], front[1][i], front[2][i], back[0][i], back[1][i], back[2][i]])
	# ---- inlantuirea pe etaje, pe serii continue cu acelasi rol (jos / sus)
	var total := 0
	for k in 3:
		var i := 0
		while i < S:
			if front[k][i] < 0.0:
				i += 1
				continue
			var role: bool = bot[i] == k
			var j := i
			while j + 1 < S and front[k][j + 1] >= 0.0 and (bot[j + 1] == k) == role:
				j += 1
			var pts: Array = []
			var dep: Array = []
			var bas: Array = []
			for m in S:
				var f: float = front[k][m] if front[k][m] >= 0.0 else LANE_KEEP
				pts.append(E[m] + N[m] * f)
				dep.append(maxf(float(back[k][m]) - f, MOD_D))
				if role:
					bas.append(float(G2[m]) - 0.3)
				else:
					bas.append(float(levels[k]))
			if j > i:
				total += _chain(pts, N, dep, bas, TIER_TOP[k], i, j, true)
			i = j + 1
	print("perete: %d module" % total)
	# ---- malul dinspre apa (stanga): randuri de trepte care coboara spre
	# mijlocul vaii / apa, fata spre apa. Randul r: fata la 3,3 + 3r m de
	# asfalt, varful la (drum - 0,35) - 1,56 r (jumatate de etaj pe rand).
	# Se opreste la apa, la teren mai sus decat varful, sau la jumatatea
	# distantei pana la celalalt brat.
	var bank := 0
	for r in 4:
		var W: Array = []
		var WN: Array = []
		var WD: Array = []
		var WB: Array = []
		var WT: Array = []
		var ok: Array = []
		for i in range(i0, i1 + 1):
			var q: Vector3 = tr.baked[i]
			var sd := -tr._side_at(i)  # spre apa
			var hw := tr.width_at_index(i)
			var e := q + sd * hw
			e.y = 0.0
			var f := float(i) / n
			var inner := f > 0.186 and f < 0.212
			var off0 := 0.3 + MOD_D * r
			var off1 := off0 + MOD_D
			var low := INF
			for d: float in [off0 + 0.5, (off0 + off1) * 0.5, off1]:
				low = minf(low, _gy(e + sd * d))
			var top := q.y - 0.35 - 1.56 * r
			var basey := maxf(low, -10.2) - 0.3
			var pf := e + sd * (off1 + 0.5)
			# ramai pe jumatatea ta de vale: fata randului nu trece de mijlocul
			# dintre bratul tau si celalalt
			var pm := e + sd * off1
			var ci := tr.closest_index_global(pm)
			var own := absf(ci - i) < 20
			if not own:
				var qo: Vector3 = tr.baked[ci]
				var d_other := Vector2(pm.x - qo.x, pm.z - qo.z).length() - tr.width_at_index(ci)
				var d_own := off1
				# latimea libera pana la mijloc: taie randul la jumatate
				var half := (d_other + d_own) * 0.5
				if half - off0 >= 1.5:
					off1 = half - 0.15
					low = INF
					for d: float in [off0 + 0.5, off1]:
						low = minf(low, _gy(e + sd * d))
					basey = maxf(low, -10.2) - 0.3
					own = true
			var need := 0.9
			# randurile din spate doar pe vale USCATA: peste apa ar acoperi
			# apa (bara: apa verde intre maluri, cu trepte doar pe margine)
			if r > 0 and low < -9.4:
				own = false
			ok.append(not inner and own and top - basey > need and top > -9.3 and top > low + 0.4)
			if DEBUG and i % 5 == 0:
				print("  mal r%d f %.3f drum %+.2f low %+.2f top %+.2f base %+.2f own %s -> %s" % [r, f, q.y, low, top, basey, own, ok[ok.size() - 1]])
			W.append(e + sd * off1)
			WN.append(-sd)
			WD.append(off1 - off0)
			WB.append(basey)
			WT.append(top)
			if r == 0:
				var er := q + tr._side_at(i) * (hw + 0.5)
				er.y = _gy(er)
				_road_diya.append(er)
				if ok[ok.size() - 1]:
					var el := e + sd * 0.5
					el.y = top + 0.12 * (top - basey) / TIER_H
					_road_diya.append(el)
		var s := 0
		while s < ok.size():
			if not ok[s]:
				s += 1
				continue
			var t := s
			while t + 1 < ok.size() and ok[t + 1]:
				t += 1
			var aa := s
			while aa < t:
				var bb := mini(t, aa + 6)
				var tp: float = WT.slice(aa, bb + 1).min()
				bank += _chain(W, WN, WD, WB, tp, aa, bb, true)
				aa = bb
			s = t + 1
	print("mal: %d module" % bank)
	# ---- pavilionul: pe axa acului, in spatele etajului de sus
	var ia := int((0.198 - FRAC_A) * n)
	var pav_off := 12.0
	if ia < S and back[0][ia] > 0.0:
		pav_off = back[0][ia]
	var pe: Vector3 = E[ia] + N[ia] * (pav_off - 1.0 + PAV_HALF_D)
	var pb := INF
	for dx: float in [-4.0, 0.0, 4.0]:
		for dz: float in [-10.0, 0.0, 10.0]:
			pb = minf(pb, tr._terrain_mesh_y(pe.x + dx, pe.z + dz))
	pe.y = clampf(pb, -1.9, 0.0)
	var pz: Vector3 = N[ia]
	var px := Vector3.UP.cross(pz).normalized()
	if px.cross(Vector3.UP).dot(pz) < 0.0:
		px = -px
	_emit("Pavilion", "s_stepwell_pavilion", Transform3D(Basis(px, Vector3.UP, pz), pe))
	print("pavilion la %s (offset %.1f, teren %.2f)" % [pe, pav_off, pb])
	# ---- candele plutitoare (nu sub modulele malului)
	var wet: Dictionary = tr.get("_ravine_wet")
	var step: float = tr.get("_terr_step")
	var org: Vector3 = tr.get("_terr_origin")
	var fl := PackedVector3Array()
	var fly := PackedFloat32Array()
	var gx := -210.0
	while gx <= -88.0:
		var gz := 52.0
		while gz <= 72.0:
			var p := Vector3(gx + _rng.randf_range(-1.0, 1.0), 0, gz + _rng.randf_range(-1.0, 1.0))
			var cell := Vector2i(int(floor((p.x - org.x) / step)), int(floor((p.z - org.z) / step)))
			var ci := tr.closest_index_global(p)
			var q2: Vector3 = tr.baked[ci]
			var dd := Vector2(p.x - q2.x, p.z - q2.z).length() - tr.width_at_index(ci)
			if wet.has(cell) and _gy(p) < -9.8 and dd > 3.8:
				var w := clampf((p.x + 210.0) / 120.0, 0.0, 1.0)
				if _rng.randf() < 0.45 + 0.5 * w:
					fl.append(Vector3(p.x, -9.5, p.z))
					fly.append(_rng.randf() * TAU)
			gz += 1.9
		gx += 1.9
	var ry := PackedFloat32Array()
	for k in _road_diya.size():
		ry.append(_rng.randf() * TAU)
	print("module %d, candele pe trepte %d, pe drum %d, plutitoare %d" % [_mm_pos.size(), _diya.size(), _road_diya.size(), fl.size()])
	# ---- iesirea
	_out.append('[node name="Trepte" type="MultiMeshInstance3D" parent="DecorManual/ZoneC_Fantana"]')
	_out.append('script = ExtResource("flock")')
	_out.append('model = ExtResource("s_stepwell_flight_module")')
	_out.append("positions = " + var_to_str(_mm_pos))
	_out.append("yaws = " + var_to_str(_mm_yaw))
	_out.append("scale3_list = " + var_to_str(_mm_sc))
	_out.append('tri_class = "rose_sandstone"')
	_out.append("")
	var all_d := _diya.duplicate()
	all_d.append_array(_road_diya)
	var all_y := _diya_yaw.duplicate()
	all_y.append_array(ry)
	_flock("Candele_Trepte", "s_diya", all_d, all_y, 3.2, 4.0)
	_flock("Candele_Apa", "s_floating_diya", fl, fly, 2.4, 3.2)
	var fo := FileAccess.open(path, FileAccess.WRITE)
	fo.store_string("\n".join(_out))
	fo.close()
