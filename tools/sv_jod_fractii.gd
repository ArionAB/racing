extends Node
## Fractiile REALE ale reperelor de pe Track17 (Jodhpur), pentru contractul de
## gauntlet (docs/track_briefs/jodhpur_poi_gauntlet.md). Brief-ul §2 are
## fractiile de dinainte de traseu; aici se citesc de pe scena.
##
##   godot --headless --path . res://tools/SvJodFractii.tscn
##
## Tipareste pentru fiecare reper fractia pe INDEX (i/n — cea pe care o iau
## `Snapshot --frac`, `custom_width_segments`, ProbeRace `--slice`) si pe
## LUNGIME (dists[i]/total — cea a rapelor), plus cota. Memoria
## `fractia-pe-index-vs-pe-lungime`: pe Track15 au divergat cu 29 m.
##
## Reperele se deduc din geometrie (cote, directii, raze), nu din brief:
## buza si fundul fantanii din cota, acele din schimbarea de directie, gura
## ulicioarei din golul margine-margine fata de bucla (memoria
## `banda-inchisa-nu-e-ruta`: gura reala e unde golul devine pozitiv).

const SCENE := "res://scenes/tracks/Track17.tscn"

var tr: Track
var n: int
var L: float


func _ready() -> void:
	var ps := load(SCENE) as PackedScene
	tr = ps.instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	var r0: TrackRoute = tr.route_at(0)
	n = r0.count()
	L = r0.length()
	print("")
	print("=== Track17 %s: %d puncte coapte, lungime %.1f m, pas mediu %.2f m, rute %d ===" % [
		tr.track_name, n, L, L / float(n), tr.routes.size()])
	_divergence()
	_landmarks()
	_turns()
	_widths()
	_branch()
	_extras()
	_views()
	_sides()
	_xsect()
	get_tree().quit(0)


func _fl(i: int) -> float:
	var d: PackedFloat32Array = tr.get("_dists")
	return d[i] / d[n]


func _line(tag: String, i: int) -> void:
	i = ((i % n) + n) % n
	var p: Vector3 = tr.baked[i]
	print("  %-34s idx %.4f | lung %.4f | %6.1f m | y %+6.2f | semi %.1f | (%.1f, %.1f)" % [
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


func _landmarks() -> void:
	print("\n--- repere pe cota ---")
	_line("grila (frac 0)", 0)
	var ymin := INF
	var imin := 0
	var ymax := -INF
	var imax := 0
	for i in n:
		var y: float = tr.baked[i].y
		if y < ymin and float(i) / float(n) < 0.4:
			ymin = y
			imin = i
		if y > ymax:
			ymax = y
			imax = i
	# buza fantanii: ultimul punct >= -0.25 inainte de fund; iesirea: primul
	# punct >= -0.25 dupa fund.
	var lip := imin
	while lip > 0 and tr.baked[lip].y < -0.25:
		lip -= 1
	var out := imin
	while out < n - 1 and tr.baked[out].y < -0.25:
		out += 1
	_line("buza fantanii (y ultima >= -0.25)", lip)
	# fundul: cel mai estic punct (acul) — varful acului
	var iax := lip
	for i in range(lip, out):
		if tr.baked[i].x > tr.baked[iax].x:
			iax = i
	var bot0 := lip
	while bot0 < out and tr.baked[bot0].y > -8.95:
		bot0 += 1
	var bot1 := out
	while bot1 > lip and tr.baked[bot1].y > -8.95:
		bot1 -= 1
	_line("fund: inceput palier -9", bot0)
	_line("fund: VARFUL acului (x maxim)", iax)
	_line("fund: sfarsit palier -9", bot1)
	_line("iesirea din fantana (y >= -0.25)", out)
	var hc := Vector3(-152.5, -9.0, 60.0)
	var ent := -1
	var ext := -1
	for i in range(0, int(0.4 * n)):
		var p: Vector3 = tr.baked[i]
		var d := Vector2(p.x - hc.x, p.z - hc.z).length()
		if d <= 72.0 and ent < 0:
			ent = i
		if d <= 72.0:
			ext = i
	if ent >= 0:
		_line("intra in palnia hollow (r<=72)", ent)
		_line("iese din palnia hollow (r<=72)", ext)
	_line("cota maxima", imax)
	# primul punct >= 39.9 si ultimul
	var top0 := -1
	var top1 := -1
	for i in n:
		if tr.baked[i].y >= 39.9:
			if top0 < 0:
				top0 = i
			top1 = i
	_line("platou >= 39.9: inceput", top0)
	_line("platou >= 39.9: sfarsit", top1)
	# inceputul coborarii: primul punct dupa top1 unde panta pe 10 m < -3 %
	var step := maxi(1, int(round(10.0 / (L / float(n)))))
	var dsc := top1
	for i in range(top1, n - step):
		var dy: float = tr.baked[i + step].y - tr.baked[i].y
		var ds: float = (_fl(i + step) - _fl(i)) * L
		if ds > 0.0 and dy / ds < -0.03:
			dsc = i
			break
	_line("inceputul coborarii (panta < -3%)", dsc)
	# Devkund: cel mai jos punct dupa 0.7
	var dmin := INF
	var di := 0
	for i in range(int(0.7 * n), n):
		if tr.baked[i].y < dmin:
			dmin = tr.baked[i].y
			di = i
	_line("Devkund: punctul cel mai jos", di)
	_line("capatul dreptei H (idx n-1)", n - 1)
	# cotele la pragurile Jai Pol (+18) — primul punct >= 18
	for lvl in [5.0, 10.0, 15.0, 18.0, 25.0, 30.0, 35.0]:
		for i in n:
			if tr.baked[i].y >= lvl:
				_line("prima trecere peste y=%+.0f" % lvl, i)
				break


func _turns() -> void:
	print("\n--- ace si viraje (schimbare de directie > 45 grade pe 40 m) ---")
	var step := maxi(1, int(round(20.0 / (L / float(n)))))
	var last := -1000
	var i := 0
	while i < n:
		var a := _heading(i - step)
		var b := _heading(i + step)
		var d := wrapf(rad_to_deg(b - a), -180.0, 180.0)
		if absf(d) > 45.0 and i - last > 2 * step:
			# cauta varful: maximul local de |d| in fereastra
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
			# raza aproximativa: arc 40 m / unghi
			var rad := (2.0 * step * (L / float(n))) / maxf(deg_to_rad(absf(dd)), 0.01)
			_line("viraj %+4.0f (%s) %03.0f->%03.0f r~%.0f" % [dd, "dr" if dd > 0 else "st", hin, hout, rad], best)
			last = best
			i = best + 2 * step
			continue
		i += 1


func _widths() -> void:
	print("\n--- custom_width_segments (fractii pe INDEX) cu cotele capetelor ---")
	var segs: Array = tr.get("custom_width_segments")
	for s in segs:
		var v: Vector3 = s
		var i0 := int(v.x * n) % n
		var i1 := int(v.y * n) % n
		print("  %.3f-%.3f semi %.1f   (%.0f-%.0f m, y %+.1f -> %+.1f)" % [
			v.x, v.y, v.z, _fl(i0) * L, _fl(i1) * L, tr.baked[i0].y, tr.baked[i1].y])


func _branch() -> void:
	print("\n--- ulicioara (ruta 1) ---")
	if tr.routes.size() < 2:
		print("  LIPSA")
		return
	var r1: TrackRoute = tr.route_at(1)
	var r0: TrackRoute = tr.route_at(0)
	print("  entry_frac %.4f  exit_frac %.4f  lungime banda %.1f m  semi %.1f" % [
		r1.entry_frac, r1.exit_frac, r1.length(), r1.half_width])
	var ie := int(r1.entry_frac * n) % n
	var ix := int(r1.exit_frac * n) % n
	_line("furca (entry_frac pe bucla)", ie)
	_line("revenirea (exit_frac pe bucla)", ix)
	print("  lungimea buclei ocolite: %.1f m (banda %.1f m, castig %.1f m = %.0f %%)" % [
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
		print("  golul se inchide din nou la %.1f m pe banda (%.1f, %.1f) — capatul de revenire" % [
			mouth_end * spacing, q.x, q.z])
	for c in _all(tr):
		if c.has_method("mouth_position"):
			var mp: Vector3 = c.mouth_position()
			var cj := r1.closest_index_global(mp)
			print("  CowGate.mouth_position (%.1f, %+.2f, %.1f) = %.1f m pe banda (mouth_dist_m %.1f)" % [
				mp.x, mp.y, mp.z, cj * spacing, float(c.get("mouth_dist_m"))])
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("alley_gate.gd"):
			print("  AlleyGate gate_dist_m %.1f, deschidere %.1f m" % [float(c.get("gate_dist_m")), 2.0 * float(c.get("half_opening_m"))])


func _extras() -> void:
	print("\n--- rape (fractii pe LUNGIME) ---")
	var rv: Array = tr.get("custom_ravines")
	for v in rv:
		var r: Vector4 = v
		var i0 := _idx_of_len(r.x)
		var i1 := _idx_of_len(r.y)
		print("  rapa %.3f-%.3f (lung) = idx %.4f-%.4f, adanc %.1f, tip %d" % [
			r.x, r.y, float(i0) / float(n), float(i1) / float(n), r.z, int(r.w)])
	print("\n--- noduri de gameplay prezente in scena ---")
	var kinds := {}
	for c in _all(tr):
		var nm := c.get_class()
		if c.get_script() != null:
			nm = str(c.get_script().resource_path).get_file()
		if nm.contains("channel") or nm.contains("respawn") or nm.contains("camera_zone") \
				or nm.contains("hazard") or nm.contains("dusk") or nm.contains("cow") \
				or nm.contains("traffic") or nm.contains("gate") or nm.contains("ramp"):
			kinds[nm] = int(kinds.get(nm, 0)) + 1
	for k in kinds:
		print("  %s x%d" % [k, kinds[k]])
	var cent := Vector2.ZERO
	for i in n:
		cent += Vector2(tr.baked[i].x, tr.baked[i].z)
	cent /= float(n)
	var far := 0.0
	for i in n:
		far = maxf(far, Vector2(tr.baked[i].x, tr.baked[i].z).distance_to(cent))
	print("  centroidul buclei (%.1f, %.1f); punctul cel mai departe la %.0f m (zidul lumii la 420)" % [cent.x, cent.y, far])


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


## Azimutul unei tinte fata de directia de mers, in grade (+ = dreapta).
func _rel(i: int, q: Vector2) -> float:
	var p: Vector3 = tr.baked[i]
	var b := atan2(q.x - p.x, -(q.y - p.z))
	return wrapf(rad_to_deg(b - _heading(i)), -180.0, 180.0)


## Pe ce procent din punctele intervalului e tinta in jumatatea de cadru
## (+-50 grade pe azimut, fara verticala si ocluzie: acelea le da tabelul de
## frustum, nu sonda asta) si la ce distanta.
func _views() -> void:
	print("
--- azimut (doar axa laterala, +-50 grade; + = dreapta) ---")
	var cent := Vector2.ZERO
	for i in n:
		cent += Vector2(tr.baked[i].x, tr.baked[i].z)
	cent /= float(n)
	var fort := Vector2(135.0, -275.0)
	var well := Vector2(-152.5, 60.0)
	var checks := [
		["B spre buza fantanii", 0.05, 0.135, well],
		["D spre stanca fortului", 0.264, 0.474, fort],
		["E (portile) spre centroidul orasului", 0.474, 0.588, cent],
		["F brat de intrare 0.622-0.666 spre centroid", 0.622, 0.666, cent],
		["F brat de intrare spre fantana", 0.622, 0.666, well],
		["F brat de iesire 0.666-0.699 spre centroid", 0.666, 0.699, cent],
		["F brat de iesire spre fantana", 0.666, 0.699, well],
		["F fatada 0.588-0.622 spre centroid", 0.588, 0.622, cent],
		["G coborarea 0.699-0.86 spre centroid", 0.699, 0.86, cent],
		["H 0.906-1.0 spre grila (turnul e langa ea)", 0.906, 0.999, Vector2(-30.0, 196.0)],
	]
	for c in checks:
		var i0 := int(float(c[1]) * n)
		var i1 := int(float(c[2]) * n)
		var inside := 0
		var tot := 0
		var rmin := 999.0
		var rmax := -999.0
		var dmin := 1e9
		var dmax := 0.0
		for i in range(i0, i1):
			var r := _rel(i, c[3])
			var p: Vector3 = tr.baked[i]
			var d := Vector2(p.x, p.z).distance_to(c[3])
			tot += 1
			if absf(r) <= 50.0:
				inside += 1
			rmin = minf(rmin, r)
			rmax = maxf(rmax, r)
			dmin = minf(dmin, d)
			dmax = maxf(dmax, d)
		print("  %-46s in cadru %3.0f %%  azimut %+4.0f..%+4.0f  dist %3.0f-%3.0f m" % [
			c[0], 100.0 * inside / maxf(tot, 1), rmin, rmax, dmin, dmax])
	print("  (centroid oras = centroidul buclei (%.1f, %.1f); fantana = centrul TerrainHollow; fortul = centrul TerrainPeak)" % [cent.x, cent.y])


## Cota terenului la stanga / dreapta axei (+-10 si +-25 m), ca sa se vada pe
## ce parte e apa lacului si caderea bastionului.
func _sides() -> void:
	print("
--- terenul lateral (y teren - y drum), st / dr ---")
	for f in [0.13, 0.17, 0.20, 0.24, 0.52, 0.60, 0.64, 0.665, 0.68, 0.75, 0.80, 0.86, 0.875, 0.89, 0.905, 0.95]:
		var i := int(f * n)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h)) # (x, z) la dreapta: heading+90
		var out := ""
		for off in [-25.0, -10.0, 10.0, 25.0]:
			var x: float = p.x + right.x * off
			var z: float = p.z + right.y * off
			var y: float = tr.call("_terrain_mesh_y", x, z)
			out += "  %+3.0f:%+6.1f" % [off, y - p.y]
		print("  idx %.3f dir %03.0f  %s" % [f, fposmod(rad_to_deg(h), 360.0), out])


## Profil transversal mai fin (y teren - y drum) pe fantana, porti, bastion,
## Devkund: unde e peretele, unde e apa, unde e caderea.
func _xsect() -> void:
	print("
--- profil transversal (y teren - y drum) la -40..+40 m; st = negativ ---")
	var offs := [-40.0, -30.0, -20.0, -14.0, -9.0, -6.0, 6.0, 9.0, 14.0, 20.0, 30.0, 40.0]
	var hdr := "                         "
	for o in offs:
		hdr += "%6.0f" % o
	print(hdr)
	for f in [0.136, 0.15, 0.17, 0.185, 0.198, 0.21, 0.23, 0.25, 0.262, 0.48, 0.505, 0.53, 0.555, 0.575, 0.60, 0.63, 0.655, 0.666, 0.675, 0.69, 0.70, 0.72, 0.865, 0.88, 0.895, 0.91]:
		var i := int(f * n)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f y%+5.1f %03.0f " % [f, p.y, fposmod(rad_to_deg(h), 360.0)]
		for off in offs:
			var y: float = tr.call("_terrain_mesh_y", p.x + right.x * off, p.z + right.y * off)
			out += "%+6.1f" % (y - p.y)
		print(out)
