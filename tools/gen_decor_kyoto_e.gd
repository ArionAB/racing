extends Node
## Generator de decor MANUAL pentru POI E — FUSHIMI INARI (Track18, Kyoto,
## frac ~0,47-0,56 pe bucla, plus gura scurtaturii E′ 0,483-0,579).
## Tiparul gen_decor_kyoto_a / gen_decor_jod_a.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoE.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoE.tscn -- \
##       --out=tools/kyoto_decor/poi_e.part
##
## Fisierul .part are doua sectiuni (`;;EXT` si `;;NODES`) pe care
## tools/gen_kyoto_route.py le lipeste in Track18.tscn (blocul DECOR MANUAL).

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneE_Inari"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _ext: Dictionary = {}   # stem -> path
var _n := 0
var _out_path := ""
var _scan := false
var _rng := RandomNumberGenerator.new()
var _tunnel: Node = null


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
	_tunnel = _track.get_node_or_null("ToriiTunel")
	for k in 120:
		if _tunnel != null and bool(_tunnel.get("built")):
			break
		await get_tree().process_frame
	if _scan:
		await _do_scan()
		get_tree().quit(0)
		return
	_rng.seed = 51026
	_build()
	_write()
	get_tree().quit(0)


func _do_scan() -> void:
	var pts := _track.baked
	var n := pts.size()
	print("; baked %d, lungime %.0f" % [n, _track.route_at(0).length()])
	for i in n:
		var f := float(i) / float(n)
		if f < 0.44 or f > 0.60:
			continue
		if i % 2 != 0:
			continue
		var p: Vector3 = pts[i]
		var hw := _track.width_at(f)
		var r: Vector3 = _track.route_at(0).side_at(i)
		var line := "i %4d f %.4f  (%.1f, %.2f, %.1f) hw %.1f r(%.2f,%.2f) sol:" % [i, f, p.x, p.y, p.z, hw, r.x, r.z]
		for lat in [-30.0, -20.0, -12.0, -9.0, 9.0, 12.0, 20.0, 30.0]:
			line += " %+.0f:%.2f" % [lat, _sol_real(p.x + r.x * lat, p.z + r.z * lat) - p.y]
		print(line)
	var br := _track.route_at(1)
	print("; banda E′: %d puncte, lungime %.1f" % [br.baked.size(), br.length()])
	for i in range(0, br.baked.size(), 3):
		var p: Vector3 = br.baked[i]
		var mi := _track.route_at(0).closest_index_global(p)
		var lat := _track.route_at(0).lateral_distance(mi, p)
		print("b %3d d %.1f (%.1f, %.2f, %.1f) lat_bucla %.1f (hw %.1f) mf %.4f" % [i, br.dists[i], p.x, p.y, p.z, lat, _track.width_at_index(mi), float(mi) / float(n)])
	if _tunnel != null:
		print("; tunel: built %s start %.1f end %.1f big_gate %.1f porti %d bulevard %d padure %d" % [
			str(_tunnel.get("built")), float(_tunnel.get("tunnel_start_dist")), float(_tunnel.get("tunnel_end_dist")),
			float(_tunnel.get("big_gate_dist")), int(_tunnel.get("gate_count")), int(_tunnel.get("avenue_count")),
			int(_tunnel.get("forest_count"))])
		for c in _tunnel.get_children():
			if c is FlockProp:
				var fp := c as FlockProp
				var s := "; %s:" % fp.name
				for k in mini(fp.positions.size(), 4):
					s += " (%.1f,%.1f,%.1f)" % [fp.positions[k].x, fp.positions[k].y, fp.positions[k].z]
				print(s)
	for nm in ["Hazarduri/Kogarashi", "Hazarduri/DarumaOtoshi", "Peaks/Inari"]:
		var nd := _track.get_node_or_null(nm) as Node3D
		if nd != null:
			print("; %s la %s" % [nm, str(nd.global_position)])
	await _scan_map()


## Harta pe celule de 10 m in jurul lui E: R = bucla la < hw+3, B = banda E′,
## T = copaci (PadureMasa), ~ = sol sub cota drumului cu > 2 m, cifra = urcare.
func _scan_map() -> void:
	var forest0 := _track.get_node_or_null("PadureMasa")
	for k in 900:
		if forest0 != null and bool(forest0.get("done")):
			break
		await get_tree().process_frame
	var occ: Dictionary = {}
	if forest0 != null:
		occ = forest0.get("_occ")
	var main := _track.route_at(0)
	var br := _track.route_at(1)
	var cell := 8.0
	for gz in range(180, 400, 8):
		var line := "%5d " % gz
		for gx in range(250, 460, 8):
			var c := Vector3(gx + 4, 0, gz + 4)
			var mi := main.closest_index_global(c)
			var ml := main.lateral_distance(mi, Vector3(c.x, main.baked[mi].y, c.z))
			var bi := br.closest_index_global(c)
			var bl := Vector2(c.x, c.z).distance_to(Vector2(br.baked[bi].x, br.baked[bi].z))
			var ch := "."
			var nt := 0
			for dx in range(0, int(cell), 2):
				for dz in range(0, int(cell), 2):
					if occ.has(Vector2i(int(floor((gx + dx) / 2.0)), int(floor((gz + dz) / 2.0)))):
						nt += 1
			if ml < _track.width_at_index(mi) + 1.0:
				ch = "R"
			elif bl < 4.5:
				ch = "B"
			elif nt > 0:
				ch = "T"
			else:
				var dy := _sol_real(c.x, c.z) - main.baked[mi].y
				if dy < -2.0:
					ch = "~"
				elif dy > 2.0:
					ch = str(clampi(int(dy / 4.0), 0, 9))
			line += ch
		print(line)


## ------------------------------------------------------------------------
## DECIZIILE (randul E/E′ din docs/track_briefs/kyoto.md §2, §2.0, §3)
##
## Conventii masurate (`side_at` = dreapta soferului; pe E dreapta = INTERIORUL
## U-ului, spre muntele Inari si tunel):
##  - kitsune a/b: fata = -Z (baveta la z -0,36), capul lui `a` la -X, al lui
##    `b` la +X. Perechea: `a` pe STANGA masinii care vine, `b` pe dreapta,
##    deci capetele se intorc spre drum.
##  - inari_romon: golul pe axa X (±7,05, coliziune `mesh`), trecerea pe Z,
##    acoperisul ±6,25 pe Z, aripile la ±14,25.
##  - votive_torii_cluster: sirul pe X (11,5 m), poarta mare (4,2 m) la -X.
##
## - POARTA-TURN ROMON peste drumul principal, pe CREASTA U-ului (f ~0,531,
##   +23,5): regula coordonatorului e „nimic cu coliziune intre 0,47 si 0,52"
##   (palnia E′), iar inainte de 0,47 e podul Tsutenkyo. Pe creasta drumul e
##   plat si curba e cea mai larga (R ~130 m), deci golul de 14,1 m lasa ~1 m
##   pe fiecare parte a soselei de ±6 m. Urcarea de 9% duce drept in ea.
## - VULPILE: o pereche la Romon (hull, la 3,5 m de bordura, inainte de
##   poarta) si una la gura E′, langa poarta mare a tunelului (coliziune
##   `none`, motiv scris: e zona palniei, unde AI-ul taie coltul — un corp nou
##   acolo ar fi o capcana noua). Vulpile cutie din torii_tunnel.gd se sting
##   (`foxes_enabled = false` in gen_kyoto_route.py).
## - SIRURI DE TORII VOTIVE pe ambele flancuri ale U-ului, la ~30° de drum,
##   pornind de la ~3,6 m de bordura si urcand in cedri (fara corp).
## - ALTARASE: altarel + doua felinare de piatra + ema, in grupuri, pe
##   exteriorul si interiorul U-ului dupa creasta; chozuya langa Romon.
## - ARTARI rosii ca accente in spatele altaraselor (masa e PadureMasa).

const ROMON_F := 0.531
const LAT_CLEAR := 3.5     # marja minima fata de bordura pentru piese cu corp

var _cum: PackedFloat32Array
var _total := 0.0


func _build() -> void:
	_prep()
	_romon()
	_mouth_foxes()
	_votive_rows()
	_shrines()


func _prep() -> void:
	var pts := _track.baked
	_cum.resize(pts.size() + 1)
	_cum[0] = 0.0
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		_cum[i + 1] = _cum[i] + Vector2(b.x - a.x, b.z - a.z).length()
	_total = _cum[pts.size()]


## Distanta pe bucla pentru fractia de INDEX f (ca la hazarde).
func _s_of(f: float) -> float:
	var n := _track.baked.size()
	var fi := f * float(n)
	var i := clampi(int(floor(fi)), 0, n - 1)
	return lerpf(_cum[i], _cum[i + 1], fi - float(i))


## [pozitie, tangenta, dreapta, semilatime] la distanta s pe bucla.
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
	var a2: Vector3 = pts[maxi(lo - 2, 0)]
	var b2: Vector3 = pts[mini(lo + 3, n - 1)]
	var tan := Vector3(b2.x - a2.x, 0.0, b2.z - a2.z).normalized()
	var right := tan.cross(Vector3.UP).normalized()
	var hw: float = _track.width_at(float(lo) / float(n))
	return [p, tan, right, hw]


## Punct la fractia f, la `lat_edge` metri DINCOLO de bordura (semn: + =
## dreapta), si `ds` metri in lungul drumului.
func _at(f: float, lat_edge: float, ds: float = 0.0) -> Array:
	var fr := _frame(_s_of(f) + ds)
	var hw: float = fr[3]
	var lat := (hw + absf(lat_edge)) * signf(lat_edge)
	var p: Vector3 = (fr[0] as Vector3) + (fr[2] as Vector3) * lat
	return [p, fr[1], fr[2], hw]


## yaw care intoarce -Z local spre directia d (orizontala).
func _yaw_face(d: Vector3) -> float:
	return atan2(-d.x, -d.z)


## yaw care duce +X local pe directia d (orizontala).
func _yaw_x_along(d: Vector3) -> float:
	return atan2(-d.z, d.x)


func _romon() -> void:
	var fr := _frame(_s_of(ROMON_F))
	var c: Vector3 = fr[0]
	var tan: Vector3 = fr[1]
	var right: Vector3 = fr[2]
	# Baza pe solul cel mai jos de sub stalpi (aripi ±13,3, adancime ±3,9).
	var y := INF
	for lx in [-13.3, -7.05, 7.05, 13.3]:
		for lz in [-3.9, 3.9]:
			var q: Vector3 = c + right * lx + tan * lz
			y = minf(y, _sol_real(q.x, q.z))
	# yaw: +Z local pe tangenta (trecerea), X peste drum.
	_raw("inari_romon", "structures", "PoartaRomon", Vector3(c.x, y - 0.05, c.z),
		atan2(tan.x, tan.z), 1.0, "")
	print("; romon la (%.1f, %.2f, %.1f), drum %.2f, hw %.1f" % [c.x, y, c.z, c.y, float(fr[3])])
	# Vulpile Romonului: inainte de poarta (spre masina care vine), la 3,5 m
	# de bordura, cu fata spre masina si intoarse ~20° spre ax.
	for side: float in [-1.0, 1.0]:
		var a := _at(ROMON_F, side * (LAT_CLEAR + 0.75), -11.0)
		var p: Vector3 = a[0]
		var t: Vector3 = a[1]
		var r: Vector3 = a[2]
		var look := (-t + r * (-side) * 0.36).normalized()
		var stem := "kitsune_statue_a" if side < 0.0 else "kitsune_statue_b"
		_raw(stem, "props", "eVulpeRomon", Vector3(p.x, _sol_min(p.x, p.z, 0.75) - 0.04, p.z),
			_yaw_face(look), 1.15, "")
	# Felinare de piatra de o parte si de alta a portii.
	for side: float in [-1.0, 1.0]:
		for ds in [-17.0, 9.5]:
			var a := _at(ROMON_F, side * (LAT_CLEAR + 0.7), ds)
			var p: Vector3 = a[0]
			_raw("stone_lantern_a", "props", "eFelinarRomon",
				Vector3(p.x, _sol_min(p.x, p.z, 0.65) - 0.05, p.z), _yaw_face(a[2]), 1.0, "")
	# Chozuya pe interior, dupa poarta.
	var ch := _at(ROMON_F, 6.5, 16.0)
	var cp: Vector3 = ch[0]
	_raw("chozuya", "props", "eChozuya", Vector3(cp.x, _sol_min(cp.x, cp.z, 1.6) - 0.05, cp.z),
		_yaw_face(-(ch[2] as Vector3)), 1.0, "")


## Perechea de la gura E′: in fata portii mari, pe ambele parti ale benzii,
## fara corp (zona palniei).
func _mouth_foxes() -> void:
	var br := _track.route_at(1)
	var main := _track.route_at(0)
	var d0: float = float(_tunnel.get("big_gate_dist")) if _tunnel != null else 16.8
	for dd in [-1.5, 0.0, 1.5, 3.0, 4.5, 6.0]:
		var d: float = d0 - 3.0 + float(dd)
		var s := _br_sample(br, d)
		var p: Vector3 = s[0]
		var dir: Vector3 = s[1]
		var side := dir.cross(Vector3.UP).normalized()
		var ok := true
		var cand: Array = []
		for sg: float in [-1.0, 1.0]:
			var q: Vector3 = p + side * sg * 5.6
			var mi := main.closest_index_global(q)
			var ml := main.lateral_distance(mi, q)
			if ml < _track.width_at_index(mi) + 3.0:
				ok = false
			cand.append([q, sg])
		if not ok:
			continue
		# fata spre masina care vine dinspre furca, intoarsa spre bucla
		var mi0 := main.closest_index_global(p)
		var mdir := main.baked[mini(mi0 + 2, main.baked.size() - 1)] - main.baked[maxi(mi0 - 2, 0)]
		mdir.y = 0.0
		var fdir := (dir * 0.5 + mdir.normalized() * 0.5).normalized()
		for c in cand:
			var q: Vector3 = c[0]
			var sg: float = c[1]
			# side = dreapta celui care merge pe banda; stanga lui -> `a`
			var stem := "kitsune_statue_a" if sg < 0.0 else "kitsune_statue_b"
			_raw(stem, "props", "eVulpeTunel", Vector3(q.x, _sol_min(q.x, q.z, 0.75) - 0.04, q.z),
				_yaw_face(-fdir), 1.25, "none")
		print("; vulpi la gura E′: d %.1f" % d)
		return
	print("; vulpi la gura E′: nu incap (bucla prea aproape)")


func _br_sample(br: TrackRoute, d: float) -> Array:
	var n := br.baked.size()
	var k := 0
	while k < n - 2 and br.dists[k + 1] < d:
		k += 1
	var t := clampf((d - br.dists[k]) / maxf(0.001, br.dists[k + 1] - br.dists[k]), 0.0, 1.0)
	var p := br.baked[k].lerp(br.baked[k + 1], t)
	var a := br.baked[maxi(k - 1, 0)]
	var b := br.baked[mini(k + 2, n - 1)]
	var dir := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	return [p, dir]


## Siruri de torii votive pe flancuri: [f, parte (+1 dreapta), unghi fata de
## drum (grade; sirul se departeaza de drum spre inainte)].
const VOTIVE := [[0.5005, -1.0, 32.0], [0.5115, 1.0, 28.0], [0.5175, -1.0, 36.0],
	[0.5390, 1.0, 30.0], [0.5440, -1.0, 34.0], [0.5525, -1.0, 30.0], [0.5620, -1.0, 28.0]]


func _votive_rows() -> void:
	for it in VOTIVE:
		var f: float = it[0]
		var side: float = it[1]
		var ang := deg_to_rad(float(it[2]))
		var a := _at(f, side * 3.6)
		var p0: Vector3 = a[0]
		var t: Vector3 = a[1]
		var r: Vector3 = a[2]
		# directia sirului: inainte si spre exteriorul drumului
		var dir := (t * cos(ang) + r * side * sin(ang)).normalized()
		var c := p0 + dir * 5.75
		var e := p0 + dir * 11.5
		var y := minf(minf(_sol_real(p0.x, p0.z), _sol_real(c.x, c.z)), _sol_real(e.x, e.z))
		# poarta mare (-X local) langa drum, cele mici urca in cedri: +X pe dir.
		_raw("votive_torii_cluster", "structures", "eToriiVotive", Vector3(c.x, y - 0.08, c.z),
			_yaw_x_along(dir), 1.0, "")


## Altarase in grupuri: [f, parte, ds] -> altarel cu fata spre drum, doua
## felinare de piatra la colturi, ema alaturi (la un grup din doua), artar in spate.
const SHRINES := [[0.5130, 1.0, 0.0], [0.5370, -1.0, 0.0], [0.5500, 1.0, 0.0], [0.5470, -1.0, 6.0]]


func _shrines() -> void:
	var k := 0
	for it in SHRINES:
		var f: float = it[0]
		var side: float = it[1]
		var ds: float = it[2]
		var a := _at(f, side * 6.0, ds)
		var p: Vector3 = a[0]
		var t: Vector3 = a[1]
		var r: Vector3 = a[2]
		var to_road: Vector3 = -r * side
		_raw("small_shrine", "structures", "eAltar", Vector3(p.x, _sol_min(p.x, p.z, 1.7) - 0.06, p.z),
			_yaw_face(to_road), 1.0, "")
		for sg: float in [-1.0, 1.0]:
			var lp: Vector3 = p + t * (2.6 * sg) + to_road * 1.8
			_raw("stone_lantern_b", "props", "eFelinarAltar",
				Vector3(lp.x, _sol_min(lp.x, lp.z, 0.65) - 0.05, lp.z), _yaw_face(to_road), 1.0, "")
		if k % 2 == 0:
			var ep: Vector3 = p + t * 5.6 + to_road * 0.6
			_raw("ema_rack", "props", "eEma", Vector3(ep.x, _sol_min(ep.x, ep.z, 1.6) - 0.05, ep.z),
				_yaw_face(to_road), 1.0, "")
		var tp: Vector3 = p - to_road * 4.5 + t * _rng.randf_range(-2.0, 2.0)
		var trees := ["momiji_a", "momiji_b", "momiji_c"]
		_raw(trees[k % 3], "plants", "eArtar", Vector3(tp.x, _sol_real(tp.x, tp.z) - 0.05, tp.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 0.95), "")
		k += 1


# ------------------------------------------------------------------ iesire

func _res_id(stem: String, path: String) -> String:
	if not _ext.has(stem):
		_ext[stem] = path
	return "poie_" + stem


func _raw(stem: String, folder: String, base: String, pos: Vector3, yaw: float,
		scl: float, mode: String) -> void:
	var path := "res://assets/models/kyoto/%s/%s.glb" % [folder, stem]
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
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


func _write() -> void:
	var lines: Array[String] = [";;EXT"]
	var stems := _ext.keys()
	stems.sort()
	for s in stems:
		lines.append('[ext_resource type="PackedScene" path="%s" id="poie_%s"]' % [_ext[s], s])
	lines.append(";;NODES")
	lines.append('[node name="ZoneE_Inari" type="Node3D" parent="DecorManual"]')
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


## Cota minima a solului sub o amprenta patrata de semilatura r.
func _sol_min(x: float, z: float, r: float) -> float:
	var m := _sol_real(x, z)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
		m = minf(m, _sol_real(x + d.x, z + d.y))
	return m


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
