extends Node
## Fractiile REALE ale reperelor de pe Track20 (Okinawa), pentru contractul de
## gauntlet (docs/track_briefs/okinawa_poi_gauntlet.md).
## Brief-ul §2 are fractiile schitei; aici se citesc de pe scena.
##
##   godot --headless --path . res://tools/SvOkFractii.tscn
##
## Tipareste fractia pe INDEX (i/n: cea pe care o iau `Snapshot --frac`,
## `custom_width_segments`, `custom_dirt_ranges`, ProbeRace `--slice`) si pe
## LUNGIME (dists[i]/total: cea a rapelor/terenului), plus cota si pozitia.
## Memoria `fractia-pe-index-vs-pe-lungime`.
##
## Pe Okinawa conteaza in plus FAPTUL DE APA: fiecare celula laterala e marcata
## `w` daca terenul e sub nivelul marii (mare sau golf) si `g` daca punctul e in
## poligonul golfului (`custom_lagoon`), ca sa se vada ce e larg si ce e golf.
##
## Nu e gardă. Vizibilitatea (azimut + elevatie + ocluzie pe teren) e pe camera
## reala: 10 m sus, 12,5 m in spate, FOV 68 -> jumatate de cadru ~50 grade pe
## orizontala, margine de sus la +5,25 grade (brief §2.0). Ocluzia e doar pe
## terenul `_terrain_mesh_y` (nu pe decor).
##
## Convenție de hartă: x est, z SUD (z = -y din brief). Sens orar pe plan.

const SCENE := "res://scenes/tracks/Track20.tscn"
const CAM_UP := 10.0
const CAM_BACK := 12.5
const TOP_DEG := 5.25
const HALF_AZ := 50.0

## Schita din brief §2.1 (x, y-nord, raza, cota, eticheta): se mapeaza pe index.
const WPTS := [
	[35, -165, "A start"], [-60, -168, "A sat port"], [-175, -150, "A colt N"],
	[-215, -60, "B fukugi"], [-205, 0, "B sicana"], [-228, 55, "B iesire"],
	[-178, 140, "C trestie"], [-95, 185, "C urcare"], [-35, 245, "D ziduri"],
	[20, 232, "D S"], [85, 265, "D varf"], [150, 248, "D poarta"],
	[232, 222, "E colt S cap"], [272, 140, "E cornisa far"], [278, 40, "E3"],
	[255, -45, "F cap pod"], [288, -110, "F pod start"], [322, -148, "F traveea"],
	[360, -188, "F pod capat"], [412, -252, "G insula"], [400, -338, "G plaja tromba"],
	[310, -375, "G3"], [225, -338, "H dig val"], [140, -252, "H2"], [95, -168, "H colt port"],
]

var tr: Track
var n: int
var L: float
var sea_y: float


func _ready() -> void:
	var ps := load(SCENE) as PackedScene
	tr = ps.instantiate() as Track
	add_child(tr)
	for k in 6:
		await get_tree().process_frame
	var r0: TrackRoute = tr.route_at(0)
	n = r0.count()
	L = r0.length()
	var samp: Object = tr.get("_sampler")
	sea_y = float(samp.call("mean_road_y")) + float(tr.get("sea_level_offset"))
	print("")
	print("=== Track20 %s: %d puncte coapte, lungime %.1f m, pas mediu %.2f m, rute %d, nivelul marii y = %+.2f ===" % [
		tr.track_name, n, L, L / float(n), tr.routes.size(), sea_y])
	_divergence()
	_waypoints()
	_profile()
	_turns()
	_widths()
	_scene_nodes()
	_windows()
	_poi_matrix()
	var poi := {
		"A port + sat (spre V)": [0.975, 0.99, 0.0, 0.02, 0.04, 0.06, 0.08, 0.10],
		"B aleea de fukugi": [0.11, 0.14, 0.17, 0.20],
		"C trestia (urcarea)": [0.22, 0.26, 0.30, 0.32],
		"D castelul": [0.34, 0.38, 0.42, 0.44, 0.46],
		"E capul + cornisa": [0.48, 0.52, 0.56, 0.60],
		"F coborarea + podul": [0.62, 0.65, 0.67, 0.70, 0.72],
		"G insula mica": [0.74, 0.76, 0.78, 0.80, 0.82],
		"H digul": [0.84, 0.88, 0.92, 0.96],
	}
	for k in poi:
		_lateral(k, poi[k])
		_sides(poi[k])
	get_tree().quit(0)


func _fl(i: int) -> float:
	var d: PackedFloat32Array = tr.get("_dists")
	return d[i] / d[n]


func _line(tag: String, i: int) -> void:
	i = ((i % n) + n) % n
	var p: Vector3 = tr.baked[i]
	print("  %-46s idx %.4f | lung %.4f | %6.1f m | y %+6.2f | semi %.1f | (%.1f, %.1f)" % [
		tag, float(i) / float(n), _fl(i), _fl(i) * L, p.y, tr.width_at_index(i), p.x, p.z])


func _heading(i: int) -> float:
	var a: Vector3 = tr.baked[((i - 2) % n + n) % n]
	var b: Vector3 = tr.baked[(i + 2) % n]
	return atan2(b.x - a.x, -(b.z - a.z)) # 0 = nord (-Z), 90 = est (+X)


func _idx_at(f: float) -> int:
	return int(f * n) % n


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


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out


func _divergence() -> void:
	var worst := 0.0
	var wi := 0
	for i in n:
		var d: float = float(i) / float(n) - _fl(i)
		if absf(d) > absf(worst):
			worst = d
			wi = i
	print("divergenta maxima index-lungime: %+.4f (%+.1f m) la idx %.3f" % [worst, worst * L, float(wi) / float(n)])


## Fiecare waypoint din schita -> cel mai apropiat punct pe bucla coapta.
func _waypoints() -> void:
	print("\n--- waypoint-urile schitei -> idx real (inceput/sfarsit de POI se citesc de aici) ---")
	for w in WPTS:
		var p := Vector3(float(w[0]), 0.0, -float(w[1]))
		var i := _closest(p)
		var b: Vector3 = tr.baked[i]
		print("  %-16s schita (%4.0f, %4.0f) -> idx %.4f lung %.4f | %6.1f m | y %+6.2f | pe bucla (%.1f, %.1f) la %.1f m de punct" % [
			w[2], p.x, p.z, float(i) / float(n), _fl(i), _fl(i) * L, b.y, b.x, b.z,
			Vector2(b.x - p.x, b.z - p.z).length()])


func _profile() -> void:
	print("\n--- profil de cota (idx, y, panta pe 20 m, heading) ---")
	var step := maxi(1, int(round(20.0 / (L / float(n)))))
	var f := 0.0
	while f < 1.0:
		var i := _idx_at(f)
		var dy: float = tr.baked[(i + step) % n].y - tr.baked[i].y
		print("  %.3f  y %+6.2f  panta %+5.1f %%  heading %03.0f  semi %.1f" % [
			f, tr.baked[i].y, 100.0 * dy / 20.0, fposmod(rad_to_deg(_heading(i)), 360.0), tr.width_at_index(i)])
		f += 0.02
	var smax := 0.0
	var si := 0
	for i in n:
		var s: float = absf(tr.baked[(i + step) % n].y - tr.baked[i].y) / 20.0
		if s > smax:
			smax = s
			si = i
	_line("panta maxima %.1f %%" % (100.0 * smax), si)
	var ymax := -INF
	var imax := 0
	var ymin := INF
	var imin := 0
	for i in n:
		if tr.baked[i].y > ymax:
			ymax = tr.baked[i].y
			imax = i
		if tr.baked[i].y < ymin:
			ymin = tr.baked[i].y
			imin = i
	_line("cota maxima (culmea D)", imax)
	_line("cota minima", imin)


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


func _idx_of_len(f: float) -> int:
	var d: PackedFloat32Array = tr.get("_dists")
	var target := f * d[n]
	for i in n:
		if d[i] >= target:
			return i
	return n - 1


func _widths() -> void:
	print("\n--- custom_width_segments, dirt, rape (pe LUNGIME), golf ---")
	for s in tr.get("custom_width_segments"):
		var v: Vector3 = s
		var i0 := _idx_at(v.x)
		var i1 := _idx_at(v.y)
		print("  semi %.3f-%.3f = %.1f   (%.0f-%.0f m, y %+.1f -> %+.1f)" % [
			v.x, v.y, v.z, _fl(i0) * L, _fl(i1) * L, tr.baked[i0].y, tr.baked[i1].y])
	for v in tr.get("custom_dirt_ranges"):
		var r: Vector2 = v
		_line("nisip (dirt) inceput %.3f" % r.x, _idx_at(r.x))
		_line("nisip (dirt) sfarsit %.3f" % r.y, _idx_at(r.y))
	var k := 0
	for v in tr.get("custom_ravines"):
		var r: Vector4 = v
		_line("rapa %d inceput %.3f (lung) adanc %.1f lat %d" % [k, r.x, r.z, int(r.w)], _idx_of_len(r.x))
		_line("rapa %d sfarsit %.3f (lung)" % [k, r.y], _idx_of_len(r.y))
		k += 1
	var poly: Array = tr.get("custom_lagoon")
	var cx := 0.0
	var cz := 0.0
	for q in poly:
		var v2: Vector2 = q
		cx += v2.x
		cz += v2.y
	print("  golf (custom_lagoon): %d varfuri, centroid (%.0f, %.0f), adancime %.1f" % [
		poly.size(), cx / poly.size(), cz / poly.size(), float(tr.get("lagoon_depth"))])
	var samp: Object = tr.get("_sampler")
	var inside := 0
	for i in n:
		var p: Vector3 = tr.baked[i]
		if float(samp.call("lagoon_signed_dist", p.x, p.z)) > 0.0:
			inside += 1
	print("  puncte de drum DENTRO poligonului golfului: %d din %d (golful e interiorul buclei pe pod/dig)" % [inside, n])


func _scene_nodes() -> void:
	print("\n--- reperele montate -> idx cel mai apropiat, distanta pana la axa, latura (- = stanga, + = dreapta) ---")
	var want := ["PodMobil", "Tromba", "Val", "Poarta_D", "Far_capul_E", "Gusuku00", "Gusuku05", "Gusuku10", "Tetra00", "Tetra21", "Tetra41"]
	for c in _all(tr):
		if not (c is Node3D):
			continue
		var nm := String(c.name)
		if not (nm in want):
			continue
		var p: Vector3 = (c as Node3D).global_position
		var i := _closest(p)
		var b: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var side := Vector2(p.x - b.x, p.z - b.z).dot(right)
		var ty: float = tr.call("_terrain_mesh_y", p.x, p.z)
		print("  %-12s (%.1f, %+.1f, %.1f)  idx %.4f lung %.4f  dist axa %.1f m  lateral %+.1f m  teren sub nod %+.1f (nod - teren %+.1f)%s  vizibil=%s" % [
			nm, p.x, p.y, p.z, float(i) / float(n), _fl(i), Vector2(b.x - p.x, b.z - p.z).length(), side,
			ty, p.y - ty, " APA" if ty < sea_y + 0.1 else "", str((c as Node3D).visible)])
	# poarta: gol fata de latimea drumului la idx-ul ei
	var gate: Node = tr.find_child("Poarta_D", true, false)
	if gate != null:
		var gi := _closest((gate as Node3D).global_position)
		print("  poarta: semilatime drum la idx-ul ei = %.1f m; golul kitului 14,35 x 6,20 m; heading drum %03.0f, yaw poarta %.0f" % [
			tr.width_at_index(gi), fposmod(rad_to_deg(_heading(gi)), 360.0),
			fposmod(rad_to_deg((gate as Node3D).global_rotation.y), 360.0)])
	var zid := 0
	var tetra_vis := 0
	var tetra_all := 0
	for c in _all(tr):
		if String(c.name).begins_with("Gusuku") and c is Node3D:
			zid += 1
		if String(c.name).begins_with("Tetra") and not String(c.name).begins_with("Tetrapod") and c is Node3D:
			tetra_all += 1
			if (c as Node3D).visible:
				tetra_vis += 1
	print("  ziduri provizorii Gusuku*: %d; tetrapozi Tetra*: %d (vizibili %d)" % [zid, tetra_all, tetra_vis])
	# minim dintre bucle: cat de aproape e podul de dig (peste golf)
	var dmin := 1e9
	var a_i := 0
	var b_i := 0
	var i0 := _idx_at(0.64)
	var i1 := _idx_at(0.70)
	var j0 := _idx_at(0.80)
	var j1 := _idx_at(0.90)
	for i in range(i0, i1):
		for j in range(j0, j1):
			var d := Vector2(tr.baked[i].x - tr.baked[j].x, tr.baked[i].z - tr.baked[j].z).length()
			if d < dmin:
				dmin = d
				a_i = i
				b_i = j
	print("  pod (0.64-0.70) <-> dig (0.80-0.90): minim %.1f m (idx %.3f <-> %.3f)" % [dmin, float(a_i) / float(n), float(b_i) / float(n)])


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
		var gy: float = tr.call("_terrain_mesh_y", c.x + d.x * t, c.z + d.z * t)
		if gy > c.y + d.y * t:
			occ = true
			break
	return {"az": az, "el": el, "dist": dh, "occ": occ,
		"vis": (not occ) and absf(az) <= HALF_AZ and el <= TOP_DEG}


## Ferestrele de vizibilitate (intervale de idx, pas 0,005) ale reperelor fixe,
## cu FUNDUL si VARFUL cerute: varful = tinta de sus, "intreg" cere ambele in cadru.
func _windows() -> void:
	print("\n--- ferestre de vizibilitate pe camera de joc (varf in cadru, fara ocluzie pe teren), pas 0.005 ---")
	var gy := func(x: float, z: float) -> float:
		return tr.call("_terrain_mesh_y", x, z)
	var targets := {
		"palat (110,-285) +16": Vector3(110, float(gy.call(110.0, -285.0)) + 16.0, -285),
		"poarta (143,-250) +14.7": Vector3(142.79, 30.0 + 14.7, -249.88),
		"far (318,-170) +20": Vector3(318, 21.4 + 20.0, -170),
		"travee (321,147) catarg +10": Vector3(320.6, 8.5 + 10.0, 146.4),
		"tromba (397,330) +18": Vector3(397.2, 2.985 + 18.0, 330.3),
		"val (207,320) +3": Vector3(207.0, 1.6 + 3.0, 319.8),
	}
	for k in targets:
		var tgt: Vector3 = targets[k]
		var ranges: Array[String] = []
		var start := -1.0
		var last := -1.0
		var f := 0.0
		while f < 1.0:
			var i := _idx_at(f)
			var v: Dictionary = _view(i, tgt)
			if v["vis"]:
				if start < 0.0:
					start = f
				last = f
			elif start >= 0.0:
				ranges.append("%.3f-%.3f" % [start, last])
				start = -1.0
			f += 0.005
		if start >= 0.0:
			ranges.append("%.3f-%.3f" % [start, last])
		var dmin := 1e9
		var dmin_f := 0.0
		for q in range(0, n, 4):
			var dd := Vector2(tr.baked[q].x - tgt.x, tr.baked[q].z - tgt.z).length()
			if dd < dmin:
				dmin = dd
				dmin_f = float(q) / float(n)
		print("  %-30s in cadru: %s | cel mai aproape %.0f m la idx %.3f" % [k, ", ".join(ranges), dmin, dmin_f])


## Terenul lateral: y teren - y drum la offseturi laterale (- stanga, + dreapta).
## `w` = terenul sub nivelul marii (apa); `g` = punctul e in poligonul golfului.
func _lateral(title: String, fr: Array) -> void:
	print("\n--- profil lateral (y teren - y drum; w = apa, g = golf): %s ---" % title)
	var offs := [-100.0, -50.0, -25.0, -10.0, 10.0, 25.0, 50.0, 100.0]
	var hdr := "                              "
	for o in offs:
		hdr += "%8.0f" % o
	print(hdr)
	var samp: Object = tr.get("_sampler")
	for f in fr:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f y%+5.1f hdg %03.0f mare %+5.1f" % [f, p.y, fposmod(rad_to_deg(h), 360.0), sea_y - p.y]
		for off in offs:
			var x: float = p.x + right.x * off
			var z: float = p.z + right.y * off
			var y: float = tr.call("_terrain_mesh_y", x, z)
			var flag := ""
			if y < sea_y + 0.1:
				flag = "w"
			if float(samp.call("lagoon_signed_dist", x, z)) > 0.0:
				flag += "g"
			out += "%+7.1f%s" % [y - p.y, flag if flag != "" else " "]
		print(out)


## Pe fiecare fractie: la ce distanta (m, pe perpendiculara pe drum) incepe apa
## pe STANGA/DREAPTA (pas 2 m, pana la 200 m), daca e golf (`g`) sau larg, si cat
## urca terenul cel mai mult peste cota drumului in primii 100 m (dealul).
func _sides(fr: Array) -> void:
	var samp: Object = tr.get("_sampler")
	print("  -- apa si deal pe laturi (stanga | dreapta): prima apa la X m [golf/larg] ; urcare maxima in 100 m --")
	for f in fr:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f :" % f
		for sg in [-1.0, 1.0]:
			var water := -1.0
			var gulf := false
			var rise := -INF
			var off := 2.0
			while off <= 200.0:
				var x: float = p.x + right.x * off * sg
				var z: float = p.z + right.y * off * sg
				var y: float = tr.call("_terrain_mesh_y", x, z)
				if off <= 100.0:
					rise = maxf(rise, y - p.y)
				if water < 0.0 and y < sea_y + 0.1:
					water = off
					gulf = float(samp.call("lagoon_signed_dist", x, z)) > 0.0
				off += 2.0
			var w := "apa la %3.0f m %s" % [water, "[golf]" if gulf else "[larg]"] if water >= 0.0 else "fara apa <200 m"
			out += "  %s: %-24s urcare %+5.1f m %s" % ["ST" if sg < 0.0 else "DR", w, rise, "|" if sg < 0.0 else ""]
		print(out)


## Limitele POI-urilor (fractii pe index, MASURATE: virajele-colt si segmentele de
## latime) si distanta minima intre drumurile lor, pentru compunerea valurilor.
const POI_RANGES := {
	"A": [[0.974, 1.0], [0.0, 0.1023]], "B": [[0.1023, 0.205]], "C": [[0.205, 0.333]],
	"D": [[0.333, 0.474]], "E": [[0.474, 0.612]], "F": [[0.612, 0.737]],
	"G": [[0.737, 0.824]], "H": [[0.824, 0.974]],
}


func _poi_pts(k: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for r in POI_RANGES[k]:
		for i in range(_idx_at(r[0]), mini(_idx_at(r[1]) if r[1] < 1.0 else n, n)):
			out.append(Vector2(tr.baked[i].x, tr.baked[i].z))
	return out


func _poi_matrix() -> void:
	print("
--- distanta minima (m) intre drumurile POI-urilor (curba coapta) ---")
	var keys := POI_RANGES.keys()
	var hdr := "      "
	for k in keys:
		hdr += "%7s" % k
	print(hdr)
	for a in keys:
		var pa := _poi_pts(a)
		var row := "  %-4s" % a
		for b in keys:
			var pb := _poi_pts(b)
			var dm := 1e9
			for u in pa:
				for v in pb:
					dm = minf(dm, u.distance_to(v))
			row += "%7.0f" % dm
		print(row)
	for k in keys:
		var pts := _poi_pts(k)
		var rect := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			rect = rect.expand(q)
		print("  %s: %d puncte, x %.0f..%.0f, z %.0f..%.0f" % [k, pts.size(), rect.position.x, rect.end.x, rect.position.y, rect.end.y])
