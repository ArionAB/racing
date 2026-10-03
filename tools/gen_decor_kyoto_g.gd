extends Node
## Generator de decor MANUAL pentru POI G + G2 — PADUREA DE BAMBUS DE LA
## ARASHIYAMA si TRECEREA PE SUB PODUL TRENULETULUI (Track18, Kyoto,
## frac 0,68-0,82). Tiparul gen_decor_kyoto_a.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoG.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoG.tscn -- \
##       --out=tools/kyoto_decor/poi_g.part
##
## Fisierul .part (`;;EXT` + `;;NODES`) il lipeste tools/gen_kyoto_route.py in
## Track18.tscn (blocul DECOR MANUAL), deci decorul supravietuieste regenerarii.

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneG_Bambus"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _ext: Dictionary = {}   # stem -> path
var _n := 0
var _out_path := ""
var _scan := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--scan":
			_scan = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_prep()
	if _scan:
		await _do_scan()
		get_tree().quit(0)
		return
	_rng.seed = 61026
	_build()
	_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ scanarea

func _do_scan() -> void:
	var pts := _track.baked
	var n := pts.size()
	print("; baked %d, lungime %.0f" % [n, _total])
	for i in n:
		var f := float(i) / float(n)
		if f < 0.665 or f > 0.835:
			continue
		var p: Vector3 = pts[i]
		var hw := _track.width_at(f)
		var fr := _frame(_cum[i])
		var right: Vector3 = fr[2]
		var line := "i %4d f %.4f s %.0f (%.1f, %.2f, %.1f) hw %.1f k %+.4f sol:" % [i, f, _cum[i], p.x, p.y, p.z, hw, _curv(_cum[i])]
		for lat in [-12.0, -8.0, -6.5, 6.5, 8.0, 12.0]:
			var q: Vector3 = p + right * lat
			line += " %+.0f:%.2f" % [lat, _sol_real(q.x, q.z) - p.y]
		print(line)
	# Piesele kitului: AABB in coordonatele GLB-ului (axele lungimii).
	for it in [["props", "shiba_fence"], ["plants", "bamboo_crown"], ["vehicles", "jinrikisha"],
			["vehicles", "sagano_train"], ["structures", "iron_truss_bridge"]]:
		var inst := (load("res://assets/models/kyoto/%s/%s.glb" % it) as PackedScene).instantiate() as Node3D
		add_child(inst)
		print("; GLB %s AABB %s" % [it[1], str(_aabb_of(inst, Transform3D.IDENTITY))])
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			print(";    %s %s" % [mi.name, str(_aabb_of(mi, Transform3D.IDENTITY))])
		inst.queue_free()
	# Podul trenului, asezat de ModulePlacer.
	var holder := _track.get_node("Poduri/PodulTrenului").get_child(0) as Node3D
	var hx := holder.global_transform
	print("; pod: origine %s  X=%s  Z=%s" % [str(hx.origin), str(hx.basis.x), str(hx.basis.z)])
	for mi in holder.find_children("*", "MeshInstance3D", true, false):
		print(";    %s lume %s" % [mi.name, str(_world_aabb(mi as MeshInstance3D))])
	# Profilul solului pe axa X a podului (unde poate merge trenul).
	var ax := Vector3(hx.basis.x.x, 0.0, hx.basis.x.z).normalized()
	var o := hx.origin
	var line := "; sol pe axa podului (x: cota-pod_y):"
	for k in range(-200, 201, 10):
		var q := o + ax * float(k)
		line += " %d:%.1f" % [k, _sol_real(q.x, q.z) - o.y]
	print(line)
	# cel mai apropiat drum de axa podului, pe lungime
	var line2 := "; dist la drum pe axa podului:"
	for k in range(-200, 201, 20):
		var q := o + ax * float(k)
		line2 += " %d:%.0f" % [k, _road_edge(Vector2(q.x, q.z))]
	print(line2)
	await _scan_forest()


## Tulpinile MultiMesh langa carosabil: cheile ocuparii lui MeshForest (celule
## de 2 m; valorile ies goale, memoria append-pe-copie-in-array-netipizat),
## masurate INDEPENDENT de functia padurii (distanta la segmentele copte ale
## tuturor rutelor, minus semilatimea), ca garda sa nu fie circulara.
func _scan_forest() -> void:
	var forest := _track.get_node_or_null("PadureMasa")
	for k in 1200:
		if forest != null and bool(forest.get("done")):
			break
		await get_tree().process_frame
	if forest == null or not bool(forest.get("done")):
		print("; PADUREA nu s-a terminat")
		return
	var occ: Dictionary = forest.get("_occ")
	var s0 := _s_of_frac(0.665)
	var s1 := _s_of_frac(0.83)
	var hist := {}
	var worst: Array = []
	var cnt := 0
	for k in occ:
		var c := Vector2((k as Vector2i).x * 2.0 + 1.0, (k as Vector2i).y * 2.0 + 1.0)
		var ci := _track.closest_index_global(Vector3(c.x, 0.0, c.y))
		var s := _cum[ci]
		if s < s0 or s > s1:
			continue
		cnt += 1
		var e := _road_edge(c)
		var b := clampi(floori(e), -3, 6)
		hist[b] = int(hist.get(b, 0)) + 1
		if e < 1.5:
			worst.append([e, c, s])
	print("; celule ocupate in G/G2: %d  histograma margine (m, celula 2 m): %s" % [cnt, str(hist)])
	worst.sort_custom(func(a, b): return a[0] < b[0])
	for w in worst.slice(0, 12):
		print(";   margine %.2f la %s s %.0f" % [w[0], str(w[1]), w[2]])
	# Densitatea padurii pe axa podului (unde poate intra trenul).
	var holder := _track.get_node("Poduri/PodulTrenului").get_child(0) as Node3D
	var ax := Vector3(holder.global_transform.basis.x.x, 0.0, holder.global_transform.basis.x.z).normalized()
	var o := holder.global_position
	var line := "; celule de padure la < 6 m de axa podului:"
	for k in range(-120, 121, 10):
		var q := o + ax * float(k)
		var nc := 0
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				if occ.has(Vector2i(floori(q.x / 2.0) + dx, floori(q.z / 2.0) + dy)):
					nc += 1
		line += " %d:%d" % [k, nc]
	print(line)
	# Pozitiile EXACTE (transformarile MultiMesh se citesc doar cu fereastra:
	# headless ies (0,0,0), memoria multimesh-masuratoare-moarta).
	var on_road := 0
	var near := 0
	var zero := 0
	var tot := 0
	var list: Array = []
	for mmi in forest.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (mmi as MultiMeshInstance3D).multimesh
		if mm == null:
			continue
		var stem := str(mmi.name)
		for i in mm.instance_count:
			var t := (mmi as MultiMeshInstance3D).global_transform * mm.get_instance_transform(i)
			tot += 1
			if t.origin == Vector3.ZERO:
				zero += 1
				continue
			var c := Vector2(t.origin.x, t.origin.z)
			var ci := _track.closest_index_global(t.origin)
			if _cum[ci] < s0 or _cum[ci] > s1:
				continue
			var e := _road_edge(c)
			if e < 0.0:
				on_road += 1
				list.append([e, c, _cum[ci], stem])
			elif e < 1.0:
				near += 1
	print("; MultiMesh exact: instante %d (zero %d); in G/G2 pe carosabil %d, la < 1 m de margine %d"
		% [tot, zero, on_road, near])
	list.sort_custom(func(a, b): return a[0] < b[0])
	for w in list.slice(0, 20):
		print(";   PE CAROSABIL %.2f m la %s s %.0f (%s)" % [w[0], str(w[1]), w[2], w[3]])


func _aabb_of(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var a := t * (n as MeshInstance3D).mesh.get_aabb()
		out = a
		first = false
	for c in n.get_children():
		var b := _aabb_of(c, t)
		if b.size == Vector3.ZERO:
			continue
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


func _world_aabb(m: MeshInstance3D) -> AABB:
	return m.global_transform * m.mesh.get_aabb()


## Distanta (2D) pana la MARGINEA celei mai apropiate sosele (negativ = pe ea).
func _road_edge(c: Vector2) -> float:
	var best := INF
	for ri in _track.routes.size():
		var r: TrackRoute = _track.routes[ri]
		var b: PackedVector3Array = r.baked
		for i in b.size() - 1:
			var a := Vector2(b[i].x, b[i].z)
			var bb := Vector2(b[i + 1].x, b[i + 1].z)
			var ab := bb - a
			var l2 := ab.length_squared()
			var t := clampf((c - a).dot(ab) / l2, 0.0, 1.0) if l2 > 1e-8 else 0.0
			var hw: float = _track.width_at_index(i) if ri == 0 else r.half_width
			best = minf(best, c.distance_to(a + ab * t) - hw)
	return best


# ------------------------------------------------------------------ cadrul drumului

var _cum: PackedFloat32Array
var _total := 0.0


func _prep() -> void:
	var pts := _track.baked
	_cum.resize(pts.size() + 1)
	_cum[0] = 0.0
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		_cum[i + 1] = _cum[i] + Vector2(b.x - a.x, b.z - a.z).length()
	_total = _cum[pts.size()]


func _s_of_frac(f: float) -> float:
	return _cum[clampi(int(f * _track.baked.size()), 0, _track.baked.size() - 1)]


## [pozitie, tangenta, dreapta, semilatime] la distanta s de linia de start.
func _frame(s: float) -> Array:
	var pts := _track.baked
	var n := pts.size()
	var ss := fposmod(s, _total)
	var lo := 0
	var hi := n
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if _cum[mid] <= ss:
			lo = mid
		else:
			hi = mid
	var a: Vector3 = pts[lo]
	var b: Vector3 = pts[(lo + 1) % n]
	var t := (ss - _cum[lo]) / maxf(0.001, _cum[lo + 1] - _cum[lo])
	var p := a.lerp(b, t)
	var tan := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	var right := tan.cross(Vector3.UP).normalized()
	var hw: float = lerpf(_track.width_at_index(lo), _track.width_at_index((lo + 1) % n), t)
	return [p, tan, right, hw]


## Curbura cu semn (1/m) la s: > 0 = vireaza la DREAPTA (exteriorul e stanga).
func _curv(s: float) -> float:
	var a: Vector3 = _frame(s - 4.0)[1]
	var b: Vector3 = _frame(s + 4.0)[1]
	var cr := a.cross(b).y   # sin unghiului; y < 0 = rotatie orara = dreapta
	return -cr / 8.0


# ------------------------------------------------------------------ constructia
## DECIZIILE (randurile G si G2 din docs/track_briefs/kyoto.md §2), din --scan:
##
## - Drumul lui G merge de la s 1447 (f 0,680) la s 1702 (f 0,800), cota +0,8
##   -> +5,2, solul la -0,3 de drum pe ambele parti (fara rapa). hw 5 pana la
##   apexul S2 (s ~1600), apoi 6. Curbura max ~0,045/m (R ~22 m) la apexuri.
## - GARDURILE (shiba_fence, `none` din PROP_COLLISION): coarde de 3,0 m pe
##   curba decalata la bordura + FENCE_OFF, pe ambele parti, de la s 1452 la
##   s 1696 (podul trenului e la s 1712: culeea de piatra sta la |x| >= 7,6 si
##   ar taia gardul). Capetele modulelor sunt identice, deci coarda se pune cu
##   +Z local pe directia ei; panta urmeaza solul (basis cu Z pe coarda 3D).
##   Goluri rare: doua pe fiecare parte (6 m), unul cu ricsa.
## - PRIMUL RAND DE BAMBUS (bamboo_crown, `trunk` r 1,2 din PROP_COLLISION)
##   la bordura + CROWN_OFF: cilindrul ramane la >= bordura + 3,2 m, deci
##   respecta regula „nimic cu coliziune la < hw + 3 pe exteriorul S-urilor"
##   (bara pentru H se incarca aici). Tulpinile MultiMesh incep de la
##   bordura + 3 (edge_clear_m al zonei, reparat in mesh_forest.gd).
## - RICSA (jinrikisha, `none`): oprita pe dreapta, in golul de gard de pe
##   dreapta dintre S1 si S2 (s ~1492, curbura ~0), paralela cu drumul.
## - TRENUL (sagano_train pe PathMover, collide = false, -Z inainte): pe axa X
##   a podului, pe puntea de la +7,45 (Truss_Deck: 6,75 + 0,7). G2 NU e un
##   defileu: solul pe axa podului e la -0,4..+0,1 fata de baza culeelor pe
##   +-60 m, deci dincolo de culee (|x| 10,6) linia n-are pe ce sta. Runda 1:
##   trenul (25,5 m, mai lung decat traveea de 21) atarna peste culee. Acum:
##   VIADUCT de trei travee (cate una in plus pe fiecare parte, acelasi GLB,
##   aceeasi cota, culoarul revendicat din padure in gen_kyoto_route.py);
##   trenul sta pe punte cat timp centrul e in |x| <= 19 (capetele in 31,7),
##   apoi intra in DESISUL de tufe de bambus de dincolo de viaduct (|x| 34-52,
##   scara 1,25-1,45, frunzele la 6,3-13 m) si coboara sub teren; intoarcerea
##   e sub pamant, la -20. Lungimea buclei / TRAIN_PERIOD = viteza (~41 s).
##   Leacul complet (rambleu sau portal de tunel) e teren/asset nou: in raport.

const FENCE_OFF := 1.7      # gardul fata de bordura (m)
const CROWN_OFF := 4.4      # centrul tufei de bambus fata de bordura
const MOD := 3.0            # modulul de gard
const S_FROM := 1452.0
const S_TO := 1696.0
const TRAIN_PERIOD := 41.0
const DECK_TOP := 7.45      # puntea podului fata de originea lui

# Goluri de gard: [side, s_centru, lungime]. Cel de pe dreapta la s 1492 e
# al ricsei.
const GAPS := [[1.0, 1492.0, 6.5], [1.0, 1636.0, 6.0], [-1.0, 1520.0, 6.0], [-1.0, 1668.0, 6.0]]


func _build() -> void:
	for side in [-1.0, 1.0]:
		_fence(side)
		_crowns(side)
	_rickshaw()
	_train()


func _in_gap(side: float, s: float) -> bool:
	for g in GAPS:
		if float(g[0]) == side and absf(s - float(g[1])) < float(g[2]) * 0.5:
			return true
	return false


## Punctul de pe curba decalata (lateral = bordura + off) la distanta s.
func _off_pt(s: float, side: float, off: float) -> Vector3:
	var f := _frame(s)
	var p: Vector3 = (f[0] as Vector3) + (f[2] as Vector3) * (side * (float(f[3]) + off))
	p.y = _sol_real(p.x, p.z)
	return p


func _fence(side: float) -> void:
	# Mers pe curba decalata cu pas mic; un modul = coarda de 3,0 m.
	var s := S_FROM
	var a := _off_pt(s, side, FENCE_OFF)
	var count := 0
	while s < S_TO:
		# cauta s2 cu |coarda 2D| = MOD
		var s2 := s + MOD
		var b := _off_pt(s2, side, FENCE_OFF)
		for it in 6:
			var d2 := Vector2(b.x - a.x, b.z - a.z).length()
			s2 += (MOD - d2) * 0.9
			b = _off_pt(s2, side, FENCE_OFF)
		if s2 > S_TO:
			break
		var mid_s := (s + s2) * 0.5
		if not _in_gap(side, mid_s):
			var mid := (a + b) * 0.5
			var z := (b - a).normalized()
			var x := Vector3.UP.cross(z).normalized()
			var y := z.cross(x).normalized()
			# Infipt 6 cm sub capatul mai jos al coardei (solul e aproape plat).
			var pos := Vector3(mid.x, minf(a.y, b.y) - 0.06 + absf(a.y - b.y) * 0.5, mid.z)
			_node_basis("shiba_fence", "props", "gGard", Basis(x, y, z), pos, "")
			count += 1
		s = s2
		a = b
	print("; gard %s: %d module" % ["dreapta" if side > 0.0 else "stanga", count])


func _crowns(side: float) -> void:
	var s := S_FROM + _rng.randf_range(0.0, 2.0)
	var count := 0
	while s < S_TO - 2.0:
		var off := CROWN_OFF + _rng.randf_range(0.0, 0.6)
		var p := _off_pt(s, side, off)
		var y := _sol_min(p.x, p.z, 1.4)
		_raw("bamboo_crown", "plants", "gTufa", Vector3(p.x, y - 0.05, p.z), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.85, 1.1), "")
		count += 1
		s += _rng.randf_range(4.6, 6.0)
	print("; tufe %s: %d" % ["dreapta" if side > 0.0 else "stanga", count])


func _rickshaw() -> void:
	var f := _frame(1492.0)
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var p: Vector3 = (f[0] as Vector3) + right * (float(f[3]) + 1.35)
	# -Z inainte, cu fata spre sensul de mers; usor intoarsa spre golul din gard.
	_raw("jinrikisha", "vehicles", "gRicsa", Vector3(p.x, _sol_real(p.x, p.z) - 0.02, p.z),
		atan2(-tan.x, -tan.z) - 0.35, 1.0, "none")


func _train() -> void:
	var holder := _track.get_node("Poduri/PodulTrenului").get_child(0) as Node3D
	var hx := holder.global_transform
	var ax := Vector3(hx.basis.x.x, 0.0, hx.basis.x.z).normalized()
	var az := Vector3(hx.basis.z.x, 0.0, hx.basis.z.z).normalized()
	var o := hx.origin
	var deck := o.y + DECK_TOP
	# Verificarea constantelor din gen_kyoto_route.py (discurile care revendica
	# culoarul viaductului din padurea de bambus).
	var dv := Vector2(o.x - VIADUCT_O.x, o.z - VIADUCT_O.y).length()
	print("; pod: abaterea fata de constantele culoarului %.2f m %s" % [dv, "" if dv < 0.5 else "  <<< ACTUALIZEAZA gen_kyoto_route.py"])
	# VIADUCTUL: cate o travee in plus pe fiecare parte, cu aceeasi baza si
	# aceeasi cota (puntea continua, fara treapta). Solul pe axa e cu 0,1-0,2 m
	# sub baza culeii principale; infigem traveele noi cu 0,15 m.
	for sx in [-1.0, 1.0]:
		var c: Vector3 = o + ax * (sx * SPAN)
		_node_basis("iron_truss_bridge", "structures", "gViaduct", hx.basis,
			Vector3(c.x, o.y - 0.15, c.z), "")
	# [x de-a lungul podului, z lateral (de-a lungul drumului), cota absoluta]
	var under := o.y - 25.0
	var pts_local := [
		[-46.0, 0.0, o.y - 4.0],     # sub teren, in desisul de pe -X
		[-19.0, 0.0, deck],          # capatul trenului la capatul viaductului (31,7)
		[19.0, 0.0, deck],
		[46.0, 0.0, o.y - 4.0],      # intra in desisul de pe +X
		[58.0, 0.0, under],
		[66.0, 40.0, under],         # intoarcerea, pe sub padurea lui G (+Z = sud)
		[-66.0, 40.0, under],
		[-58.0, 0.0, under],
	]
	var pv := PackedVector3Array()
	for q in pts_local:
		var w: Vector3 = o + ax * float(q[0]) + az * float(q[1])
		pv.append(Vector3(w.x, float(q[2]), w.z))
	var length := 0.0
	for i in pv.size():
		length += pv[i].distance_to(pv[(i + 1) % pv.size()])
	pv.append(pv[0])   # BUCLA inchisa
	var speed := length / TRAIN_PERIOD
	var pts_txt: Array[String] = []
	for q in pv:
		pts_txt.append("%.2f, %.2f, %.2f" % [q.x, q.y, q.z])
	_res_id("sagano_train", "res://assets/models/kyoto/vehicles/sagano_train.glb")
	if not _ext_extra.has(PM_EXT):
		_ext_extra.append(PM_EXT)
	_n += 1
	_out.append('[node name="gTren%d" type="Path3D" parent="%s"]' % [_n, ZONE])
	_out.append('script = ExtResource("poig_pathmover")')
	_out.append('model = ExtResource("poig_sagano_train")')
	_out.append("collide = false")
	_out.append("points = PackedVector3Array(%s)" % ", ".join(pts_txt))
	_out.append("speed = %.2f" % speed)
	_out.append("travel_mode = 0")
	# Faza: centrul trenului pe mijlocul puntii la incarcare. Bucla incepe sub
	# teren (punctul 0), iar probe_manual iarta doar PathMover-ul `in zbor`
	# (stick_to_ground = false peste teren), nu si cel sub teren; pe pod e
	# starea reala a teatrului si e si cea pe care o vede captura.
	var phase := (pv[0].distance_to(pv[1]) + pv[1].distance_to(pv[2]) * 0.5) / length
	_out.append("phase = %.3f" % phase)
	_out.append("stick_to_ground = false")
	_out.append("")
	print("; tren: bucla %.0f m, viteza %.2f m/s, perioada %.0f s; puntea la y %.2f" % [length, speed, TRAIN_PERIOD, deck])
	# DESISUL de la capetele podului (runda 1: trenul de 25 m iesea peste
	# culee, plutind 5-15 m peste iarba). Tufe mari de bambus PE linie si de o
	# parte si de alta, dincolo de viaduct (|x| 34-52) pana la capatul coborarii: frunzele
	# (de la ~6,3 m in sus la scara 1,25+) acopera caroseria (7,45..10,7 peste
	# sol), deci trenul intra in bambus la nivelul puntii si coboara in desis.
	var nt := 0
	for sx in [-1.0, 1.0]:
		for xa in [34.0, 38.5, 43.0, 47.5, 52.0]:
			for zl in [-4.6, 0.0, 4.6]:
				var w: Vector3 = o + ax * (sx * (xa + _rng.randf_range(-0.8, 0.8))) 					+ az * (zl + _rng.randf_range(-0.7, 0.7))
				if _road_edge(Vector2(w.x, w.z)) < 5.0:
					continue
				_raw("bamboo_crown", "plants", "gTufaTren", Vector3(w.x, _sol_min(w.x, w.z, 1.4) - 0.05, w.z),
					_rng.randf_range(0.0, TAU), _rng.randf_range(1.25, 1.45), "")
				nt += 1
	print("; desis la capetele podului: %d tufe" % nt)


const SPAN := 21.0        # traveea podului de fier (Truss_Deck/Stone: 21,0 pe X)
const VIADUCT_O := Vector2(-65.70, 411.02)
const PM_EXT := '[ext_resource type="Script" path="res://scenes/props/path_mover.gd" id="poig_pathmover"]'


## Cota minima a solului sub o amprenta patrata de semilatura r.
func _sol_min(x: float, z: float, r: float) -> float:
	var m := _sol_real(x, z)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
		m = minf(m, _sol_real(x + d.x, z + d.y))
	return m


# ------------------------------------------------------------------ iesire

func _res_id(stem: String, path: String) -> String:
	if not _ext.has(stem):
		_ext[stem] = path
	return "poig_" + stem


func _node_basis(stem: String, folder: String, base: String, b: Basis, pos: Vector3,
		mode: String) -> void:
	var path := "res://assets/models/kyoto/%s/%s.glb" % [folder, stem]
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, _res_id(stem, path)])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _raw(stem: String, folder: String, base: String, pos: Vector3, yaw: float,
		scl: float, mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_node_basis(stem, folder, base, b, pos, mode)


func _write() -> void:
	var lines: Array[String] = [";;EXT"]
	var stems := _ext.keys()
	stems.sort()
	for s in stems:
		lines.append('[ext_resource type="PackedScene" path="%s" id="poig_%s"]' % [_ext[s], s])
	for l in _ext_extra:
		lines.append(l)
	lines.append(";;NODES")
	lines.append('[node name="ZoneG_Bambus" type="Node3D" parent="DecorManual"]')
	lines.append("")
	lines.append_array(_out)
	print("; asezate %d piese, %d modele" % [_n, stems.size()])
	if _out_path.is_empty():
		for l in lines:
			print(l)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for l in lines:
		fa.store_line(l)
	fa.close()
	print("; scris %s" % _out_path)


var _ext_extra: Array[String] = []


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, 200.0, z), Vector3(x, -200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _track._sampler.ground_y(x, z)
