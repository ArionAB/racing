extends Node
## Fractiile REALE ale reperelor de pe Track19 (Monument Valley), pentru
## contractul de gauntlet (docs/track_briefs/monument_poi_gauntlet.md).
## Brief-ul §2 are fractiile de dinainte de generator; aici se citesc de pe scena.
##
##   godot --headless --path . res://tools/SvMvFractii.tscn
##
## Tipareste fractia pe INDEX (i/n: cea pe care o iau `Snapshot --frac`,
## `custom_width_segments`, `custom_dirt_ranges`, ProbeRace `--slice`) si pe
## LUNGIME (dists[i]/total: cea a rapelor/terenului), plus cota si pozitia.
## Memoria `fractia-pe-index-vs-pe-lungime`.
##
## Nu e gardă. Vizibilitatea (azimut + elevatie + ocluzie pe teren) e pe camera
## reala: 10 m sus, 12,5 m in spate, FOV 68 -> jumatate de cadru ~50 grade pe
## orizontala, margine de sus la +5,25 grade (brief §2.0). Ocluzia e doar pe
## terenul `_terrain_mesh_y` (nu pe decor).

const SCENE := "res://scenes/tracks/Track19.tscn"
const CAM_UP := 10.0
const CAM_BACK := 12.5
const TOP_DEG := 5.25
const HALF_AZ := 50.0

var tr: Track
var n: int
var L: float


func _ready() -> void:
	var ps := load(SCENE) as PackedScene
	tr = ps.instantiate() as Track
	add_child(tr)
	for k in 6:
		await get_tree().process_frame
	var r0: TrackRoute = tr.route_at(0)
	n = r0.count()
	L = r0.length()
	print("")
	print("=== Track19 %s: %d puncte coapte, lungime %.1f m, pas mediu %.2f m, rute %d ===" % [
		tr.track_name, n, L, L / float(n), tr.routes.size()])
	_divergence()
	_profile()
	_turns()
	_widths()
	_scene_nodes()
	_mittens()
	_vis_A_B()
	_branch()
	_belvedere()
	_homestead()
	_gabarit()
	_coama()
	_vis_g2()
	_vis_points()
	_lateral("A plato (nord = stanga la heading est)", [0.0, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06])
	_lateral("B coama", [0.055, 0.063, 0.07, 0.08, 0.10, 0.12, 0.13])
	_lateral("D poarta", [0.19, 0.21, 0.23, 0.25, 0.27, 0.29])
	_lateral("E trecatoare", [0.30, 0.33, 0.36, 0.40, 0.43, 0.44, 0.46])
	_lateral("F cornisa", [0.45, 0.48, 0.52, 0.56, 0.60])
	_lateral("G campie", [0.62, 0.66, 0.70, 0.74, 0.78, 0.82])
	_lateral("G2/H", [0.82, 0.84, 0.86, 0.90, 0.95])
	get_tree().quit(0)


func _fl(i: int) -> float:
	var d: PackedFloat32Array = tr.get("_dists")
	return d[i] / d[n]


func _line(tag: String, i: int) -> void:
	i = ((i % n) + n) % n
	var p: Vector3 = tr.baked[i]
	print("  %-44s idx %.4f | lung %.4f | %6.1f m | y %+6.2f | semi %.1f | (%.1f, %.1f)" % [
		tag, float(i) / float(n), _fl(i), _fl(i) * L, p.y, tr.width_at_index(i), p.x, p.z])


func _heading(i: int) -> float:
	var a: Vector3 = tr.baked[((i - 2) % n + n) % n]
	var b: Vector3 = tr.baked[(i + 2) % n]
	return atan2(b.x - a.x, -(b.z - a.z)) # 0 = nord (-Z), 90 = est (+X)


func _divergence() -> void:
	var worst := 0.0
	var wi := 0
	for i in n:
		var d: float = float(i) / float(n) - _fl(i)
		if absf(d) > absf(worst):
			worst = d
			wi = i
	print("divergenta maxima index-lungime: %+.4f (%+.1f m) la idx %.3f" % [worst, worst * L, float(wi) / float(n)])


func _idx_at(f: float) -> int:
	return int(f * n) % n


func _profile() -> void:
	print("\n--- profil de cota (idx, y, panta pe 20 m) ---")
	var step := maxi(1, int(round(20.0 / (L / float(n)))))
	var f := 0.0
	while f < 1.0:
		var i := _idx_at(f)
		var dy: float = tr.baked[(i + step) % n].y - tr.baked[i].y
		print("  %.3f  y %+6.2f  pante %+5.1f %%  heading %03.0f" % [f, tr.baked[i].y, 100.0 * dy / 20.0, fposmod(rad_to_deg(_heading(i)), 360.0)])
		f += 0.02
	# coama: maximul local de y in [0, 0.15] si primul punct cu panta < -3 %
	var ymax := -INF
	var imax := 0
	for i in range(0, int(0.15 * n)):
		if tr.baked[i].y > ymax:
			ymax = tr.baked[i].y
			imax = i
	_line("max y in 0..0.15 (platou/coama)", imax)
	var dsc := -1
	for i in range(0, int(0.2 * n)):
		var dy: float = tr.baked[i + step].y - tr.baked[i].y
		if dy / 20.0 < -0.03:
			dsc = i
			break
	_line("inceputul coborarii B (panta < -3 %)", dsc)
	var flat := -1
	for i in range(maxi(dsc, 0), int(0.3 * n)):
		if tr.baked[i].y < 0.5:
			flat = i
			break
	_line("coborare terminata (y < 0.5)", flat)
	var fm := -INF
	var fi := 0
	for i in range(int(0.40 * n), int(0.70 * n)):
		if tr.baked[i].y > fm:
			fm = tr.baked[i].y
			fi = i
	_line("cota maxima F", fi)
	var dm := INF
	var di := 0
	for i in range(int(0.7 * n), int(0.95 * n)):
		if tr.baked[i].y < dm:
			dm = tr.baked[i].y
			di = i
	_line("cel mai jos G2 (0.7-0.95)", di)
	_line("capatul (idx n-1)", n - 1)
	var smax := 0.0
	var si := 0
	for i in n:
		var s: float = absf(tr.baked[(i + step) % n].y - tr.baked[i].y) / 20.0
		if s > smax:
			smax = s
			si = i
	_line("panta maxima %.1f %%" % (100.0 * smax), si)


func _turns() -> void:
	print("\n--- viraje (schimbare de directie > 30 grade pe 40 m) ---")
	var step := maxi(1, int(round(20.0 / (L / float(n)))))
	var last := -1000
	var i := 0
	while i < n:
		var a := _heading(i - step)
		var b := _heading(i + step)
		var d := wrapf(rad_to_deg(b - a), -180.0, 180.0)
		if absf(d) > 30.0 and i - last > 2 * step:
			var best := i
			var bestd := absf(d)
			for j in range(i, mini(i + 2 * step, n)):
				var dj := absf(wrapf(rad_to_deg(_heading(j + step) - _heading(j - step)), -180.0, 180.0))
				if dj > bestd:
					bestd = dj
					best = j
			var dd := wrapf(rad_to_deg(_heading(best + step) - _heading(best - step)), -180.0, 180.0)
			var hin := fposmod(rad_to_deg(_heading(best - step)), 360.0)
			var hout := fposmod(rad_to_deg(_heading(best + step)), 360.0)
			var rad := (2.0 * step * (L / float(n))) / maxf(deg_to_rad(absf(dd)), 0.01)
			_line("viraj %+4.0f (%s) %03.0f->%03.0f r~%.0f" % [dd, "dr" if dd > 0 else "st", hin, hout, rad], best)
			last = best
			i = best + 2 * step
			continue
		i += 1


func _widths() -> void:
	print("\n--- custom_width_segments, dirt, gorge, arc, rape ---")
	for s in tr.get("custom_width_segments"):
		var v: Vector3 = s
		var i0 := _idx_at(v.x)
		var i1 := _idx_at(v.y)
		print("  semi %.3f-%.3f = %.1f   (%.0f-%.0f m, y %+.1f -> %+.1f)" % [
			v.x, v.y, v.z, _fl(i0) * L, _fl(i1) * L, tr.baked[i0].y, tr.baked[i1].y])
	for v in tr.get("custom_dirt_ranges"):
		var r: Vector2 = v
		_line("dirt (grila C / pamant) inceput %.3f" % r.x, _idx_at(r.x))
		_line("dirt sfarsit %.3f (grila H)" % r.y, _idx_at(r.y))
	for v in tr.get("custom_gorge_ranges"):
		var r: Vector2 = v
		_line("defileu E inceput %.3f" % r.x, _idx_at(r.x))
		_line("defileu E sfarsit %.3f" % r.y, _idx_at(r.y))
	for v in tr.get("custom_arch_fracs"):
		_line("arc E' %.3f" % float(v), _idx_at(float(v)))
	for v in tr.get("custom_ravines"):
		var r: Vector4 = v
		_line("rapa/cornisa %.3f (lung) adanc %.0f" % [r.x, r.z], _idx_of_len(r.x))
		_line("rapa/cornisa sfarsit %.3f (lung)" % r.y, _idx_of_len(r.y))


func _idx_of_len(f: float) -> int:
	var d: PackedFloat32Array = tr.get("_dists")
	var target := f * d[n]
	for i in n:
		if d[i] >= target:
			return i
	return n - 1


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out


func _closest(p: Vector3) -> int:
	var best := 0
	var bd := 1e18
	for i in n:
		var q: Vector3 = tr.baked[i]
		var d := Vector2(q.x - p.x, q.z - p.z).length_squared()
		if d < bd:
			bd = d
			best = i
	return best


func _scene_nodes() -> void:
	print("\n--- noduri de scena -> idx cel mai apropiat pe bucla, distanta pana la axa ---")
	for c in _all(tr):
		if not (c is Node3D):
			continue
		var nm := String(c.name)
		var show := false
		for k in ["Mitten", "Merrick", "Escarpa", "Albia", "Bolovan", "CalC", "CalG", "Vartej", "Plasa", "Cutie", "Dunele", "TerrainPeak"]:
			if nm.contains(k):
				show = true
		if not show:
			continue
		var p: Vector3 = (c as Node3D).global_position
		var i := _closest(p)
		var b: Vector3 = tr.baked[i]
		print("  %-14s (%.1f, %+.1f, %.1f)  idx %.4f lung %.4f  dist axa %.1f m" % [
			nm, p.x, p.y, p.z, float(i) / float(n), _fl(i), Vector2(b.x - p.x, b.z - p.z).length()])
	# pozitii-reper fixe ale schitei
	var pts := {"WM": Vector3(262, 0, 300), "EM": Vector3(338, 0, 318), "MB": Vector3(372, 0, 262)}
	for k in pts:
		var i := _closest(pts[k])
		print("  %s: cel mai aproape pe idx %.4f, dist axa %.1f" % [k, float(i) / float(n), Vector2(tr.baked[i].x - pts[k].x, tr.baked[i].z - pts[k].z).length()])


func _mittens() -> void:
	print("\n--- poarta D: distanta axa drumului -> centrul fiecarui monolit, pe fractii ---")
	var wm := Vector2(262.0, 300.0)
	var em := Vector2(338.0, 318.0)
	var mb := Vector2(372.0, 262.0)
	var i0 := _idx_at(0.12)
	var i1 := _idx_at(0.32)
	for f in [0.14, 0.16, 0.18, 0.19, 0.20, 0.21, 0.22, 0.23, 0.24, 0.25, 0.26, 0.28]:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var s := "  idx %.3f (%.0f, %.0f) semi %.1f :" % [f, p.x, p.z, tr.width_at_index(i)]
		for pair in [["WM", wm], ["EM", em], ["MB", mb]]:
			var q: Vector2 = pair[1]
			s += "  %s %.0f m az %+.0f" % [pair[0], Vector2(p.x, p.z).distance_to(q), _rel(i, q)]
		print(s)
	var dmin_wm := 1e9
	var imin_wm := 0
	var dmin_em := 1e9
	var imin_em := 0
	for i in range(i0, i1):
		var p: Vector3 = tr.baked[i]
		var d1 := Vector2(p.x, p.z).distance_to(wm)
		var d2 := Vector2(p.x, p.z).distance_to(em)
		if d1 < dmin_wm:
			dmin_wm = d1
			imin_wm = i
		if d2 < dmin_em:
			dmin_em = d2
			imin_em = i
	_line("WM cel mai aproape (dist axa-centru %.1f)" % dmin_wm, imin_wm)
	_line("EM cel mai aproape (dist axa-centru %.1f)" % dmin_em, imin_em)
	var mid := Vector2((wm.x + em.x) * 0.5, (wm.y + em.y) * 0.5)
	var im := _closest(Vector3(mid.x, 0, mid.y))
	_line("poarta (cel mai aproape de mijlocul WM-EM)", im)
	# in cadru pe ambii, de la coama la poarta
	var inside := 0
	var tot := 0
	for i in range(_idx_at(0.063), imin_wm):
		tot += 1
		if absf(_rel(i, wm)) <= HALF_AZ and absf(_rel(i, em)) <= HALF_AZ:
			inside += 1
	print("  ambii Mittens la <= 50 grade azimut, de la coama la poarta: %d / %d (%.0f %%)" % [inside, tot, 100.0 * inside / maxf(tot, 1)])


## Azimutul unei tinte (x,z) fata de directia de mers, grade (+ = dreapta).
func _rel(i: int, q: Vector2) -> float:
	var p: Vector3 = tr.baked[i]
	var b := atan2(q.x - p.x, -(q.y - p.z))
	return wrapf(rad_to_deg(b - _heading(i)), -180.0, 180.0)


func _cam_pos(i: int) -> Vector3:
	var p: Vector3 = tr.baked[i]
	var h := _heading(i)
	var fwd := Vector3(sin(h), 0.0, -cos(h))
	return p + Vector3(0.0, CAM_UP, 0.0) - fwd * CAM_BACK


## (azimut, elevatie, distanta, ocluzie pe teren) camera -> tinta.
func _view(i: int, target: Vector3) -> Dictionary:
	var c := _cam_pos(i)
	var d := target - c
	var dh := Vector2(d.x, d.z).length()
	var az := _rel(i, Vector2(target.x, target.z))
	var el := rad_to_deg(atan2(d.y, dh))
	var occ := false
	var steps := int(dh / 3.0)
	for k in range(4, steps):
		var t := float(k) / float(steps)
		var x := c.x + d.x * t
		var z := c.z + d.z * t
		var ry := c.y + d.y * t
		var gy: float = tr.call("_terrain_mesh_y", x, z)
		if gy > ry:
			occ = true
			break
	return {"az": az, "el": el, "dist": dh, "occ": occ,
		"vis": (not occ) and absf(az) <= HALF_AZ and el <= TOP_DEG}


func _vis_A_B() -> void:
	print("\n--- vizibilitate din A/B: tinte = vf. West Mitten (y 31), vf. East Mitten (y 28), vf. Merrick (y 26), sol valea ---")
	var targets := {
		"WM top": Vector3(262, 31, 300), "EM top": Vector3(338, 28, 318),
		"MB top": Vector3(372, 26, 262), "sol valea (262,0,150)": Vector3(262, 0, 150),
		"sol valea (300,0,200)": Vector3(300, 0, 200),
	}
	for f in [0.0, 0.01, 0.02, 0.03, 0.04, 0.05, 0.055, 0.063, 0.07, 0.08, 0.10, 0.12, 0.13]:
		var i := _idx_at(f)
		var s := "  idx %.3f y %+5.1f :" % [f, tr.baked[i].y]
		for k in targets:
			var v: Dictionary = _view(i, targets[k])
			s += "  [%s az %+4.0f el %+5.1f d %3.0f %s%s]" % [k.left(6), v["az"], v["el"], v["dist"], "OCL" if v["occ"] else "", " VIS" if v["vis"] else ""]
		print(s)


func _branch() -> void:
	print("\n--- scurtatura Dunele (ruta 1) ---")
	if tr.routes.size() < 2:
		print("  LIPSA")
		return
	var r1: TrackRoute = tr.route_at(1)
	var r0: TrackRoute = tr.route_at(0)
	print("  entry_frac %.4f  exit_frac %.4f  lungime banda %.1f m  semi %.1f" % [
		r1.entry_frac, r1.exit_frac, r1.length(), r1.half_width])
	var ie := _idx_at(r1.entry_frac)
	var ix := _idx_at(r1.exit_frac)
	_line("furca (entry_frac pe bucla)", ie)
	_line("revenirea (exit_frac pe bucla)", ix)
	print("  bucla ocolita: %.1f m, banda %.1f m, castig %.1f m (%.0f %%)" % [
		(_fl(ix) - _fl(ie)) * L, r1.length(), (_fl(ix) - _fl(ie)) * L - r1.length(),
		100.0 * (1.0 - r1.length() / maxf((_fl(ix) - _fl(ie)) * L, 0.1))])
	var m := r1.baked.size()
	var spacing := r1.length() / float(maxi(m - 1, 1))
	var mouth := -1
	var mouth_end := -1
	for j in m:
		var p: Vector3 = r1.baked[j]
		var ci := r0.closest_index_global(p)
		var gap := Vector2(p.x - r0.baked[ci].x, p.z - r0.baked[ci].z).length() - tr.width_at_index(ci) - r1.half_width
		if gap > 0.0 and mouth < 0:
			mouth = j
		if gap > 0.0:
			mouth_end = j
	if mouth >= 0:
		var p := r1.baked[mouth]
		var ci := r0.closest_index_global(p)
		print("  GURA REALA (gol margine-margine > 0): la %.1f m pe banda, (%.1f, %.1f) y %+.2f; langa bucla idx %.4f" % [
			mouth * spacing, p.x, p.z, p.y, float(ci) / float(n)])
		var q := r1.baked[mouth_end]
		var cq := r0.closest_index_global(q)
		print("  golul se inchide la %.1f m pe banda (%.1f, %.1f); langa bucla idx %.4f" % [mouth_end * spacing, q.x, q.z, float(cq) / float(n)])
	for j in range(0, m, maxi(1, m / 8)):
		var p: Vector3 = r1.baked[j]
		var ci := r0.closest_index_global(p)
		print("    banda %.0f m: (%.1f, %+.1f, %.1f) dist pana la bucla %.1f m (idx %.3f)" % [j * spacing, p.x, p.y, p.z,
			Vector2(p.x - r0.baked[ci].x, p.z - r0.baked[ci].z).length(), float(ci) / float(n)])
	# vizibilitatea gurii de pe cornisa: ultimele puncte ale lui F
	var mp: Vector3 = r1.baked[maxi(mouth, 0)]
	for f in [0.50, 0.54, 0.58, 0.60, 0.62, 0.64]:
		var v: Dictionary = _view(_idx_at(f), mp + Vector3(0, 1, 0))
		print("  gura G' vazuta de la idx %.3f: az %+4.0f el %+5.1f d %3.0f %s%s" % [f, v["az"], v["el"], v["dist"], "OCL" if v["occ"] else "", " VIS" if v["vis"] else ""])


func _belvedere() -> void:
	print("\n--- cornisa F: teren plat langa drum (loc pentru belvedere, camioane, turisti) ---")
	print("  (y teren - y drum la offset lateral; - = stanga, + = dreapta; dreapta = caderea)")
	var offs := [-70.0, -50.0, -35.0, -25.0, -18.0, -12.0, -8.0, 8.0, 12.0, 18.0, 25.0, 35.0, 50.0]
	var hdr := "                  "
	for o in offs:
		hdr += "%6.0f" % o
	print(hdr)
	for f in [0.436, 0.45, 0.47, 0.49, 0.51, 0.53, 0.55, 0.57, 0.59, 0.61]:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f y%+5.1f " % [f, p.y]
		for off in offs:
			var y: float = tr.call("_terrain_mesh_y", p.x + right.x * off, p.z + right.y * off)
			out += "%+6.1f" % (y - p.y)
		print(out)
	# cea mai larga fasie plata (|dy|<1.0) pe stanga, in primii 60 m, pe fiecare idx F
	print("  fasie plata stanga (|dy|<=1.0 m fata de drum) pe F, cea mai mare latime (m) si lungimea de drum pe care exista >=15 m:")
	var run := 0.0
	var best_run := 0.0
	var best_f := 0.0
	var run_start := 0
	for i in range(_idx_at(0.436), _idx_at(0.60)):
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var w := 0.0
		var off := 8.0
		while off <= 70.0:
			var y: float = tr.call("_terrain_mesh_y", p.x - right.x * off, p.z - right.y * off)
			if absf(y - p.y) <= 1.0:
				w = off
			else:
				break
			off += 2.0
		if w >= 25.0:
			if run == 0.0:
				run_start = i
			run += L / float(n)
			if run > best_run:
				best_run = run
				best_f = float(run_start) / float(n)
		else:
			run = 0.0
	print("  cea mai lunga bucata cu >= 25 m plat pe stanga: %.0f m, incepe la idx %.3f" % [best_run, best_f])


func _homestead() -> void:
	print("\n--- gospodaria: candidati la est de B/C (x 360..480), fiecare cu planeitate, dist de drum si vizibilitate de pe B/C ---")
	var cands: Array = []
	for x in range(350, 490, 10):
		for z in range(-120, 260, 10):
			var c := Vector3(float(x), 0.0, float(z))
			var i := _closest(c)
			var dr := Vector2(tr.baked[i].x - c.x, tr.baked[i].z - c.z).length()
			if dr < 60.0:
				continue
			if Vector2(c.x, c.z).distance_to(Vector2(372, 262)) < 55.0 					or Vector2(c.x, c.z).distance_to(Vector2(338, 318)) < 55.0 					or Vector2(c.x, c.z).distance_to(Vector2(262, 300)) < 55.0:
				continue
			var ymin := 1e9
			var ymax := -1e9
			var y0: float = tr.call("_terrain_mesh_y", c.x, c.z)
			for dx in [-12.0, 0.0, 12.0]:
				for dz in [-12.0, 0.0, 12.0]:
					var y: float = tr.call("_terrain_mesh_y", c.x + dx, c.z + dz)
					ymin = minf(ymin, y)
					ymax = maxf(ymax, y)
			# distanta la monoliti si la inelul lumii
			var vis := 0
			var tot := 0
			for f in range(int(0.063 * 1000), int(0.20 * 1000), 5):
				var ii := _idx_at(float(f) / 1000.0)
				var v: Dictionary = _view(ii, Vector3(c.x, y0 + 3.0, c.z))
				tot += 1
				if v["vis"]:
					vis += 1
			if ymax - ymin > 1.6:
				continue
			cands.append([vis, Vector3(c.x, y0, c.z), dr, ymax - ymin, tot, i])
	cands.sort_custom(func(a, b): return a[0] > b[0])
	for k in mini(cands.size(), 14):
		var a: Array = cands[k]
		var p: Vector3 = a[1]
		print("  (%.0f, %+.1f, %.0f) dist drum %.0f m, relief 24x24 m %.1f m, vizibil din B-C-D start pe %d / %d puncte (de langa idx %.3f)" % [
			p.x, p.y, p.z, a[2], a[3], a[0], a[4], float(a[5]) / float(n)])
	print("  (referinta diorama: gospodaria e la est de coborarea B, intre platou si Merrick, spre colt NE)")


func _lateral(title: String, fr: Array) -> void:
	print("\n--- profil lateral (y teren - y drum): %s ---" % title)
	var offs := [-60.0, -40.0, -25.0, -14.0, -9.0, 9.0, 14.0, 25.0, 40.0, 60.0]
	var hdr := "                    "
	for o in offs:
		hdr += "%6.0f" % o
	print(hdr)
	for f in fr:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f y%+5.1f %03.0f " % [f, p.y, fposmod(rad_to_deg(h), 360.0)]
		for off in offs:
			var y: float = tr.call("_terrain_mesh_y", p.x + right.x * off, p.z + right.y * off)
			out += "%+6.1f" % (y - p.y)
		print(out)


## Gabaritul real al monolitilor din DecorManual (AABB in lume al fiecarui
## MeshInstance3D), distanta pana la axa drumului si pana la MARGINEA lui.
func _gabarit() -> void:
	print("
--- gabarit monoliti (AABB lume) si distanta pana la marginea asfaltului ---")
	var dm: Node = tr.get_node_or_null("DecorManual")
	if dm == null:
		print("  fara DecorManual")
		return
	for c in dm.get_children():
		if not (c is Node3D) or String(c.name).begins_with("Zona"):
			continue
		for mi in _all(c):
			if not (mi is MeshInstance3D):
				continue
			var m := mi as MeshInstance3D
			var ab: AABB = m.global_transform * m.get_aabb()
			# cel mai apropiat punct al AABB (in plan) de axa drumului
			var best := 1e9
			var bi := 0
			for i in range(0, n, 1):
				var q: Vector3 = tr.baked[i]
				var cx := clampf(q.x, ab.position.x, ab.end.x)
				var cz := clampf(q.z, ab.position.z, ab.end.z)
				var d := Vector2(q.x - cx, q.z - cz).length()
				if d < best:
					best = d
					bi = i
			print("  %-14s %-16s x %.0f..%.0f z %.0f..%.0f y %.1f..%.1f | cel mai aproape de axa: %.1f m (idx %.3f) = %.1f m de MARGINE (semi %.1f)" % [
				c.name, m.name, ab.position.x, ab.end.x, ab.position.z, ab.end.z, ab.position.y, ab.end.y,
				best, float(bi) / float(n), best - tr.width_at_index(bi), tr.width_at_index(bi)])


## Raza verticala minima pe coama: airtime cere R < v^2/g = 34^2/28 = 41 m.
func _coama() -> void:
	print("
--- coama: raza verticala (airtime cere R < 41 m la 34 m/s, g 28) ---")
	var step := 4 # 8 m
	var rmin := 1e9
	var ri := 0
	for i in range(_idx_at(0.04), _idx_at(0.14)):
		var s1: float = (tr.baked[i].y - tr.baked[i - step].y) / (step * L / float(n))
		var s2: float = (tr.baked[i + step].y - tr.baked[i].y) / (step * L / float(n))
		var dth := absf(atan(s2) - atan(s1))
		var r := (step * L / float(n)) / maxf(dth, 1e-6)
		if r < rmin:
			rmin = r
			ri = i
	_line("raza verticala minima %.0f m" % rmin, ri)
	rmin = 1e9
	for i in range(_idx_at(0.83), _idx_at(0.86)):
		var s1: float = (tr.baked[i].y - tr.baked[i - step].y) / (step * L / float(n))
		var s2: float = (tr.baked[i + step].y - tr.baked[i].y) / (step * L / float(n))
		var dth := absf(atan(s2) - atan(s1))
		var r := (step * L / float(n)) / maxf(dth, 1e-6)
		if r < rmin:
			rmin = r
			ri = i
	_line("(G2) raza verticala minima %.0f m" % rmin, ri)


## Albia G2 vazuta din G: tinta = centrul albiei (y -5), malul si fundul.
func _vis_g2() -> void:
	print("
--- albia G2 vazuta de pe drum (camera reala): tinta centrul albiei la y=-4, la +-15 m lateral ---")
	var a := Vector3(-95.8, -4.0, 13.0)
	for f in [0.78, 0.80, 0.81, 0.82, 0.825, 0.83, 0.835, 0.838]:
		var i := _idx_at(f)
		var v: Dictionary = _view(i, a)
		print("  idx %.3f (%.0f, %.0f) y %+.1f: az %+4.0f el %+6.1f d %3.0f %s%s" % [f, tr.baked[i].x, tr.baked[i].z, tr.baked[i].y, v["az"], v["el"], v["dist"], "OCL" if v["occ"] else "", " VIS" if v["vis"] else ""])
	print("  malul albiei (y 0) la 40 m lateral, vazut de la 0.80-0.83:")
	for f in [0.80, 0.82, 0.83]:
		var i := _idx_at(f)
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var a2 := Vector3(-95.8 + right.x * 25.0, 0.0, 13.0 + right.y * 25.0)
		var v: Dictionary = _view(i, a2)
		print("    idx %.3f: az %+4.0f el %+5.1f d %3.0f %s%s" % [f, v["az"], v["el"], v["dist"], "OCL" if v["occ"] else "", " VIS" if v["vis"] else ""])


## Pe ce fractii intra in cadru (azimut +-50, elevatie < 5,25, fara ocluzie pe
## teren) puncte fixe: unde se pun gospodaria, postul de negot, turnul de apa.
func _vis_points() -> void:
	print("
--- fereastre de vizibilitate pentru puncte fixe (fractii pe index in care sunt in cadru) ---")
	var pts := {
		"gospodarie (430,5,60)": Vector3(430, 7, 60), "gospodarie (440,5,100)": Vector3(440, 7, 100),
		"gospodarie (450,5,140)": Vector3(450, 7, 140), "gospodarie (430,6,180)": Vector3(430, 8, 180),
		"gospodarie (445,6,230)": Vector3(445, 8, 230), "gospodarie (365,0,190) 65 m": Vector3(365, 3, 190),
		"post negot (250,12,-75)": Vector3(250, 14, -75), "post negot (240,12,-70)": Vector3(240, 14, -70),
		"turn apa (325,12,-40)": Vector3(325, 20, -40), "moara (335,12,-45)": Vector3(335, 18, -45),
		"belvedere F (-215,13,330)": Vector3(-215, 15, 330), "belvedere F (-215,13,380)": Vector3(-215, 15, 380),
		"belvedere F (-215,13,300)": Vector3(-215, 15, 300),
		"arc E' (-68,8,445)": Vector3(-68, 14, 445),
		"gura G' (-76,5,151)": Vector3(-76, 6, 151),
	}
	for k in pts:
		var runs := ""
		var in_run := false
		var start := 0.0
		var cnt := 0
		var total := 0
		var f := 0.0
		while f < 1.0:
			var v: Dictionary = _view(_idx_at(f), pts[k])
			total += 1
			var ok: bool = v["vis"] and float(v["dist"]) < 330.0
			if ok:
				cnt += 1
			if ok and not in_run:
				in_run = true
				start = f
			if (not ok) and in_run:
				in_run = false
				runs += " %.3f-%.3f" % [start, f - 0.005]
			f += 0.005
		if in_run:
			runs += " %.3f-1.000" % start
		print("  %-34s in cadru pe %3d / %d puncte; ferestre:%s" % [k, cnt, total, runs])
