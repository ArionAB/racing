extends Node
## Fractiile REALE ale reperelor de pe Track21 (Transfagarasan), pentru contractul
## de gauntlet (docs/track_briefs/transfagarasan_poi_gauntlet.md).
## Brief-ul §2 are fractiile schitei; aici se citesc de pe scena.
##
##   godot --headless --path . res://tools/SvTfFractii.tscn
##
## Tipareste fractia pe INDEX (i/n: cea pe care o iau `Snapshot --frac`,
## `custom_width_segments`, ProbeRace `--slice`) si pe LUNGIME (dists[i]/total: cea
## a rapelor, parapetelor, terenului), plus cota si pozitia. Memoria
## `fractia-pe-index-vs-pe-lungime`.
##
## Pe Transfagarasan conteaza in plus: APA (lacurile Vidraru si Balea, Oltul, hau-ul
## barajului) si RAPELE: fiecare celula laterala e marcata `w` daca `water_level_at`
## spune ca e apa deasupra terenului, `L` daca e in discul lacului Balea (mesh pe
## scena, nu apa de rapa). Sursa de adevar e masuratoarea, nu brief-ul §2.
##
## Nu e garda. Vizibilitatea (azimut + elevatie + ocluzie pe teren) e pe camera
## reala: 10 m sus, 12,5 m in spate, FOV 68 -> jumatate de cadru ~50 grade pe
## orizontala, margine de sus la +5,25 grade (brief §2.0). Ocluzia e doar pe
## terenul `_terrain_mesh_y` (nu pe decor).
##
## Convenție de hartă: x est, z SUD (z = -y din brief). Sens ANTIORAR pe plan.
## Latura STANGA = offset lateral negativ, DREAPTA = pozitiv.

const SCENE := "res://scenes/tracks/Track21.tscn"
const CAM_UP := 10.0
const CAM_BACK := 12.5
const TOP_DEG := 5.25
const HALF_AZ := 50.0

## Schita din brief §2.1 (x, y-nord, eticheta): se mapeaza pe index.
const WPTS := [
	[-115, -262, "A start"], [-60, -266, "A sat"], [-5, -262, "B urcare"],
	[50, -250, "B baraj V"], [95, -238, "B baraj"], [140, -240, "B baraj E"],
	[195, -205, "C mal"], [215, -130, "C tunele"], [195, -70, "C coada urs"],
	[265, -30, "D Capra"], [180, 5, "D stana"], [255, 40, "D zapada"],
	[215, 85, "D portal S"], [205, 140, "E portal N"], [195, 175, "E Balea Lac"],
	[165, 195, "F sus"], [80, 195, "F ac1a"], [80, 227, "F ac1b"],
	[165, 227, "F ac2a"], [165, 259, "F ac2b"], [80, 259, "F ac3a"],
	[80, 291, "F ac3b"], [165, 291, "F ac4a"], [165, 323, "F ac4b"],
	[40, 328, "F jos"], [-40, 335, "G cascada"], [-120, 318, "H Olt N"],
	[-185, 250, "H defileu"], [-200, 130, "H cale ferata"], [-205, 0, "H Olt"],
	[-195, -140, "H Olt S"], [-160, -238, "H spre Arges"],
]

## Zonele POI (fractii pe INDEX). Granitele sunt colturile de viraj masurate (vezi
## `_turns`); coltul apartine POI-ului care se termina cu el (ca la Okinawa):
##   H se termina cu coltul -40 grade de la 0.9766 (-> A incepe la 0.978);
##   B cu coltul -45 de la 0.1515, C cu acul -110 (r~21) de la 0.2423 (-> D de la 0.252);
##   D cu portalul de S (0.3171); E cu coltul -49 de la 0.3686 (-> F de la 0.372);
##   F cu sfarsitul parapetelor / ultimul ac (0.5631) + dreapta spre cascada (0.6268);
##   G cu coltul -36 de la 0.7016 (-> H de la 0.7036).
## Sursa pentru nodurile `ZonaA..ZonaH` din Track21.tscn (metadata `fractii`).
const ZONES := {
	"A": [[0.9786, 1.0], [0.0, 0.0640]],
	"B": [[0.0640, 0.1535]],
	"C": [[0.1535, 0.2520]],
	"D": [[0.2520, 0.3171]],
	"E": [[0.3171, 0.3720]],
	"F": [[0.3720, 0.6268]],
	"G": [[0.6268, 0.7036]],
	"H": [[0.7036, 0.9786]],
}

## Fracti de esantionare pe POI (prima coloana a tabelului lateral).
const POI := {
	"A valea Argesului": [0.975, 0.99, 0.0, 0.02, 0.04, 0.06],
	"B baraj (urcare + coronament)": [0.07, 0.09, 0.10, 0.115, 0.13, 0.145],
	"C malul lacului + urs": [0.16, 0.18, 0.20, 0.22, 0.235],
	"D valea Caprei + portal": [0.25, 0.27, 0.29, 0.305, 0.315],
	"E tunel + Balea Lac": [0.325, 0.34, 0.355, 0.365],
	"F serpentine": [0.38, 0.40, 0.43, 0.46, 0.49, 0.52, 0.55, 0.58, 0.61],
	"G Balea Cascada": [0.63, 0.65, 0.67, 0.69, 0.70],
	"H defileul Oltului": [0.72, 0.76, 0.80, 0.84, 0.88, 0.92, 0.96],
}

var tr: Track
var n: int
var L: float
var road_y_mean: float


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
	road_y_mean = float(samp.call("mean_road_y"))
	print("")
	print("=== Track21 %s: %d puncte coapte, lungime %.1f m, pas mediu %.2f m, rute %d, cota medie drum %+.2f ===" % [
		tr.track_name, n, L, L / float(n), tr.routes.size(), road_y_mean])
	_divergence()
	_waypoints()
	_profile()
	_turns()
	_widths()
	_scene_nodes()
	_windows()
	_serpentine_reveal()
	_zone_report()
	_poi_matrix()
	for k in POI:
		_lateral(k, POI[k])
		_sides(POI[k])
	_far_ring()
	_dam_void()
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
	for f in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
		var i := _idx_at(f)
		print("    idx %.2f -> lung %.4f (%+.4f)" % [f, _fl(i), _fl(i) - f])


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
	_line("cota maxima", imax)
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
	print("\n--- custom_width_segments, rape (pe LUNGIME), apa de rapa, parapete ---")
	for s in tr.get("custom_width_segments"):
		var v: Vector3 = s
		var i0 := _idx_at(v.x)
		var i1 := _idx_at(v.y)
		print("  semi %.3f-%.3f = %.1f   (%.0f-%.0f m, y %+.1f -> %+.1f) [fractii INDEX, ca in scena]" % [
			v.x, v.y, v.z, _fl(i0) * L, _fl(i1) * L, tr.baked[i0].y, tr.baked[i1].y])
	var floors: Array = tr.get("custom_ravine_floors")
	var waters: Array = tr.get("custom_ravine_water")
	var widths: Array = tr.get("custom_ravine_widths")
	var k := 0
	for v in tr.get("custom_ravines"):
		var r: Vector4 = v
		var fl := "-"
		for q in floors:
			if int((q as Vector2).x) == k:
				fl = "%+.1f" % (q as Vector2).y
		var wd := "-"
		for q in widths:
			if int((q as Vector2).x) == k:
				wd = "%.0f" % (q as Vector2).y
		var wt := "fara apa"
		for q in waters:
			if int((q as Vector3).x) == k:
				wt = "apa la %+.1f" % (q as Vector3).y
		_line("rapa %d (lung) %.3f-%.3f adanc %.0f lat %d, podea %s, latime %s, %s" % [
			k, r.x, r.y, r.z, int(r.w), fl, wd, wt], _idx_of_len(r.x))
		_line("rapa %d sfarsit" % k, _idx_of_len(r.y))
		k += 1
	for v in tr.get("custom_parapets"):
		var p: Vector4 = v
		print("  parapet lung %.3f-%.3f latura %d (%.0f-%.0f m)" % [p.x, p.y, int(p.z), p.x * L, p.y * L])


func _scene_nodes() -> void:
	print("\n--- reperele montate -> idx cel mai apropiat, distanta pana la axa, latura (- = stanga, + = dreapta) ---")
	var skip := ["ZonaTunel", "ZonaBaraj", "ZonaZiduri", "ZonaZapada", "ZonaRepere"]
	for c in _all(tr):
		if not (c is Node3D):
			continue
		var nm := String(c.name)
		if nm in skip or nm.ends_with("_col") or nm == "Batched":
			continue
		var par := c.get_parent()
		var pn := String(par.name)
		var want := false
		if pn in ["Hazarduri", "Peaks", "ZonaTunel", "ZonaRepere", "ZonaBaraj", "DecorManual"]:
			want = true
		if nm in ["ZidC01", "ZidC10", "ZidC20", "ZidC34", "Zapada_S00", "Zapada_D00", "Zapada_S11",
				"Jalon00", "Jalon16", "Lampa", "LacBalea"]:
			want = true
		if not want:
			continue
		var p: Vector3 = (c as Node3D).global_position
		var i := _closest(p)
		var b: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var side := Vector2(p.x - b.x, p.z - b.z).dot(right)
		var ty: float = tr.call("_terrain_mesh_y", p.x, p.z)
		print("  %-16s (%.1f, %+.1f, %.1f)  idx %.4f lung %.4f  dist axa %.1f m  lateral %+.1f m  teren sub nod %+.1f (nod - teren %+.1f)  vizibil=%s" % [
			nm, p.x, p.y, p.z, float(i) / float(n), _fl(i), Vector2(b.x - p.x, b.z - p.z).length(), side,
			ty, p.y - ty, str((c as Node3D).visible)])
	print("  start/grila: idx 0.0000 = %s" % str(tr.baked[0]))


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


func _node_pos(nm: String) -> Vector3:
	var c: Node = tr.find_child(nm, true, false)
	if c == null:
		return Vector3.INF
	return (c as Node3D).global_position


## Ferestrele de vizibilitate (intervale de idx, pas 0,005) ale reperelor, cu
## VARFUL cerut: varful = tinta de sus, "in cadru" cere azimut + elevatie + ocluzie.
func _windows() -> void:
	print("\n--- ferestre de vizibilitate pe camera de joc (varf in cadru, fara ocluzie pe teren), pas 0.005 ---")
	var targets := {}
	var mapping := {
		"Dam_Tower (turn priza) +8": ["Dam_Tower", 8.0],
		"Dam_Centrala +0": ["Dam_Centrala", 0.0],
		"Prometeu +9": ["Prometeu", 9.0],
		"Portal_Stanca +8": ["Portal_Stanca", 8.0],
		"Portal_S +13": ["Portal_S", 13.0],
		"Portal_N +13": ["Portal_N", 13.0],
		"Poenari +28": ["Poenari", 28.0],
		"Trecere_nivel_A +4": ["Trecere_nivel_A", 4.0],
		"Urs +3": ["Urs", 3.0],
		"Lampa semafor +6": ["Lampa", 6.0],
		"Tren +4": ["Tren", 4.0],
	}
	for k in mapping:
		var p := _node_pos(mapping[k][0])
		if p != Vector3.INF:
			targets[k] = p + Vector3(0, float(mapping[k][1]), 0)
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
		print("  %-26s in cadru: %s | cel mai aproape %.0f m la idx %.3f" % [k, ", ".join(ranges), dmin, dmin_f])


## Dezvaluirea serpentinelor (brief §2.0): de pe fiecare pozitie a camerei din E,
## cate din punctele ramurilor F (la 0,5 m deasupra suprafetei) sunt in cadru, fara
## ocluzie pe teren? Intrebarea: se vede stiva de SUB tine de la iesirea din tunel?
func _serpentine_reveal() -> void:
	print("\n--- dezvaluirea serpentinelor: din E, cate puncte de drum F in cadru (pas 4 din 8) ---")
	var f0 := 0.3700
	var f1 := 0.6260
	var pts: Array[Vector3] = []
	var i := _idx_at(f0)
	while i < _idx_at(f1):
		pts.append(tr.baked[i])
		i += 4
	var f := 0.30
	while f <= 0.40:
		var ci := _idx_at(f)
		var vis := 0
		var occ := 0
		var inside := 0
		var near := INF
		var far := 0.0
		for q in pts:
			var v: Dictionary = _view(ci, q + Vector3(0, 0.5, 0))
			if v["vis"]:
				vis += 1
				near = minf(near, float(v["dist"]))
				far = maxf(far, float(v["dist"]))
			if v["occ"]:
				occ += 1
			if absf(float(v["az"])) <= HALF_AZ and float(v["el"]) <= TOP_DEG:
				inside += 1
		print("  camera la idx %.3f (y %+.1f): in cadru %d din %d (in unghi %d, ocluzate %d), %s" % [
			f, tr.baked[ci].y, vis, pts.size(), inside, occ,
			("la %.0f-%.0f m" % [near, far]) if vis > 0 else "NICIUNA"])
		f += 0.01


## Limitele de proprietate ale zonelor, din ZONES.
func _zone_report() -> void:
	print("\n--- ZONELE (fractii index; granitele din ZONES, de verificat fata de colturile din 'viraje') ---")
	for k in ZONES:
		var segs: Array = ZONES[k]
		var out := ""
		var xs: Array[float] = []
		var zs: Array[float] = []
		var len_m := 0.0
		for s in segs:
			var a: float = s[0]
			var b: float = s[1]
			out += " [%.4f-%.4f]" % [a, b]
			var i0 := _idx_at(a)
			var i1 := _idx_at(b) if b < 1.0 else n - 1
			len_m += (_fl(i1) - _fl(i0)) * L
			for i in range(i0, i1 + 1):
				xs.append(tr.baked[i].x)
				zs.append(tr.baked[i].z)
		xs.sort()
		zs.sort()
		print("  zona %s:%s  ~%.0f m  x %.0f..%.0f  z %.0f..%.0f" % [k, out, len_m, xs[0], xs[-1], zs[0], zs[-1]])


## Distanta minima (m) intre drumurile POI-urilor, ca sa se aleaga valurile de 3
## (doua POI-uri care se calca pe decor nu merg in acelasi val).
func _poi_matrix() -> void:
	print("
--- distanta minima intre drumurile POI-urilor (m, pe curba coapta) ---")
	var keys := ZONES.keys()
	var idxs := {}
	for k in keys:
		var arr: Array[int] = []
		for s in ZONES[k]:
			var i0 := _idx_at(float(s[0]))
			var i1 := _idx_at(float(s[1])) if float(s[1]) < 1.0 else n - 1
			for i in range(i0, i1 + 1, 2):
				arr.append(i)
		idxs[k] = arr
	var hdr := "      "
	for k in keys:
		hdr += "%6s" % k
	print(hdr)
	for a in keys:
		var out := "  %s   " % a
		for b in keys:
			if a == b:
				out += "%6s" % "."
				continue
			var dmin := 1e9
			for i in idxs[a]:
				var pi: Vector3 = tr.baked[i]
				for j in idxs[b]:
					var pj: Vector3 = tr.baked[j]
					var d := Vector2(pi.x - pj.x, pi.z - pj.z).length_squared()
					if d < dmin:
						dmin = d
			out += "%6.0f" % sqrt(dmin)
		print(out)


func _wl(x: float, z: float, ty: float) -> float:
	var w: float = tr.call("water_level_at", Vector3(x, ty, z))
	return w


## Terenul lateral: y teren - y drum la offseturi de la MARGINEA asfaltului
## (semi + 3 / 10 / 20 / 40 / 80 m); `w` = apa deasupra terenului, `L` = in discul
## lacului Balea.
func _lateral(title: String, fr: Array) -> void:
	print("\n--- profil lateral (y teren - y drum; offset de la MARGINEA asfaltului; w = apa): %s ---" % title)
	var offs := [80.0, 40.0, 20.0, 10.0, 3.0]
	var h2 := "      STANGA, m de la margine:  "
	for o in offs:
		h2 += "%9.0f" % o
	h2 += "  | DREAPTA, m de la margine:"
	for o in offs:
		h2 += "%9.0f" % o
	print(h2)
	var lac := _node_pos("LacBalea")
	for f in fr:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var semi := tr.width_at_index(i)
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f y%+6.1f semi %.1f hdg %03.0f " % [f, p.y, semi, fposmod(rad_to_deg(h), 360.0)]
		for sgn in [-1.0, 1.0]:
			for off in offs:
				var d: float = sgn * (semi + off)
				var x: float = p.x + right.x * d
				var z: float = p.z + right.y * d
				var y: float = tr.call("_terrain_mesh_y", x, z)
				var flag := " "
				var w := _wl(x, z, y)
				if w > y + 0.05:
					flag = "w"
				if lac != Vector3.INF and Vector2(x - lac.x, z - lac.z).length() < 34.0:
					flag = "L"
				out += "%+8.1f%s" % [y - p.y, flag]
			out += "  |"
		print(out)


## Pe fiecare fractie: la ce distanta (m, de la MARGINEA drumului, pas 2 m, pana la
## 200 m) incepe apa pe STANGA/DREAPTA, prima cadere de > 3 m sub drum, primul perete
## de > 3 m peste drum, si cat urca/coboara terenul cel mai mult in primii 100 m.
func _sides(fr: Array) -> void:
	print("  (apa / cadere>3m / perete>3m, de la marginea drumului; max sus/jos pe 100 m)")
	for f in fr:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var semi := tr.width_at_index(i)
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f " % f
		for sgn in [-1.0, 1.0]:
			var water := -1.0
			var drop := -1.0
			var wall := -1.0
			var mx := -INF
			var mn := INF
			var off := 2.0
			while off <= 200.0:
				var d: float = sgn * (semi + off)
				var x: float = p.x + right.x * d
				var z: float = p.z + right.y * d
				var y: float = tr.call("_terrain_mesh_y", x, z)
				var dy: float = y - p.y
				if water < 0.0 and _wl(x, z, y) > y + 0.05:
					water = off
				if drop < 0.0 and dy < -3.0:
					drop = off
				if wall < 0.0 and dy > 3.0:
					wall = off
				if off <= 100.0:
					mx = maxf(mx, dy)
					mn = minf(mn, dy)
				off += 2.0
			out += "| %s: apa %s cad %s per %s max %+.0f/%+.0f " % [
				"ST" if sgn < 0.0 else "DR",
				"%.0f" % water if water >= 0.0 else "-", "%.0f" % drop if drop >= 0.0 else "-",
				"%.0f" % wall if wall >= 0.0 else "-", mx, mn]
		print(out)


## Fundalul: cota terenului (y teren - cota medie a drumului) pe inele de 250-500 m
## in jurul centroidului, pe 12 azimuturi. Daca ~0 peste tot, nu exista vale in care
## sa coboare marea de nori si campia (inventar: „Terenul de la 300-400 m e plat”).
func _far_ring() -> void:
	var cx := 0.0
	var cz := 0.0
	for i in n:
		cx += tr.baked[i].x
		cz += tr.baked[i].z
	cx /= float(n)
	cz /= float(n)
	print("\n--- teren la distanta de centroid (%.0f, %.0f): y teren - cota medie drum %+.1f ---" % [cx, cz, road_y_mean])
	var rs := [250.0, 300.0, 340.0, 380.0, 420.0, 500.0]
	var hdr := "  azimut(0=N,90=E)  "
	for r in rs:
		hdr += "%8.0f" % r
	print(hdr)
	var samp: Object = tr.get("_sampler")
	for a in range(0, 360, 30):
		var out := "  %3d               " % a
		var dx := sin(deg_to_rad(float(a)))
		var dz := -cos(deg_to_rad(float(a)))
		for r in rs:
			var x: float = cx + dx * r
			var z: float = cz + dz * r
			var y: float = tr.call("_terrain_mesh_y", x, z)
			out += "%+8.1f" % (y - road_y_mean)
		print(out)
	print("  (`_terrain_mesh_y` extrapoleaza dincolo de panza: citeste cota ultimei celule)")
	var gy: float = samp.call("ground_y", cx + 400.0, cz)
	print("  sampler.ground_y la 400 m est: %+.1f" % (gy - road_y_mean))


## Hau-ul barajului: terenul de pe coronament (dreapta = aval) si apa lacului (stanga).
func _dam_void() -> void:
	print("\n--- baraj: profil lateral pe coronament, de la AXA (- stanga = lac, + dreapta = hau) ---")
	var offs := [-60.0, -40.0, -20.0, -10.0, -7.0, 7.0, 10.0, 20.0, 40.0, 60.0, 100.0]
	var hdr := "                  "
	for o in offs:
		hdr += "%8.0f" % o
	print(hdr)
	for f in [0.070, 0.078, 0.090, 0.100, 0.110, 0.123, 0.135]:
		var i := _idx_at(f)
		var p: Vector3 = tr.baked[i]
		var h := _heading(i)
		var right := Vector2(cos(h), sin(h))
		var out := "  idx %.3f y%+5.1f" % [f, p.y]
		for off in offs:
			var x: float = p.x + right.x * off
			var z: float = p.z + right.y * off
			var y: float = tr.call("_terrain_mesh_y", x, z)
			var w := _wl(x, z, y)
			out += "%+7.1f%s" % [y - p.y, "w" if w > y + 0.05 else " "]
		print(out)
	print("  (w = apa; valoarea e terenul fata de cota coronamentului)")
