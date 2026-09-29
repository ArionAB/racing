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
			_generate(a.substr(6))
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
const LANE_KEEP := 2.0  # fata etajului de jos: metri de la marginea asfaltului

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
