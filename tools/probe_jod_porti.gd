extends Node
## PORTILE CETATII vs. DRUMUL DIN E (Jodhpur, Track17) — fundatia gauntlet-ului.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodPorti.tscn -- --track=10
##
## Doua intrebari, amandoua cu cifre, nu cu AABB:
##
##  (1) GOLUL fiecarei porti, masurat ca GOL (memoria
##      `cota-de-contract-se-masoara-ca-gol`): triunghiurile TUTUROR nodurilor
##      vizibile (piatra + canaturi + glow) proiectate pe planul lateral x
##      inaltime, rasterizate pe grila de 1 cm; banda libera care contine axa,
##      pe fereastra de inaltime a caroseriei [0,15 .. 2,00] m, si cheia (cea
##      mai mare inaltime libera pe |lat| <= 0,3 m). Axa de trecere a portilor
##      e +X in Godot (AABB 8,64 x 32,74: lungimea e pe Z), deci lateralul e Z.
##      Pentru `market_gate` lateralul e X (AABB 40,35 x 7,00).
##
##  (2) UNDE INCAP pe traseul lui E (frac 0,476 .. 0,582): la fiecare pas de
##      fractie, semilatimea drumului, raza de curbura (pe 8 m), panta si
##      profilul TERENULUI REAL (raycast pe corpurile fizice, nu sampler-ul
##      neted — memoria `terrain-mesh-y-extrapoleaza`) sub amprenta turnurilor
##      (|lat| 3,6 .. 16,4 m, pe +-4,3 m in lungul drumului), fata de cota
##      drumului. Asta spune daca un turn de 32,7 m intra in taluz (se
##      ingroapa) sau atarna peste rapa (pluteste).

const GATES := {
	"fort_gate_jai": "res://assets/models/jodhpur/structures/fort_gate_jai.glb",
	"fort_gate_fateh": "res://assets/models/jodhpur/structures/fort_gate_fateh.glb",
	"fort_gate_loha": "res://assets/models/jodhpur/structures/fort_gate_loha.glb",
	"market_gate": "res://assets/models/jodhpur/structures/market_gate.glb",
}
const CELL: float = 0.01
const WIN_LO: float = 0.15
const WIN_HI: float = 2.0
const CROWN_HALF: float = 0.3

const E_FROM: float = 0.470
const E_TO: float = 0.590
const E_STEP: float = 0.004
## Amprenta portii (masurata mai sus): semi-latime 16,37, adancime 8,64.
const HALF_SPAN_1: float = 16.37
const HALF_DEPTH_1: float = 4.32
## `--scale=1.3`: amprenta portii la scara uniforma data (implicit 1,0).
var HALF_SPAN: float = HALF_SPAN_1
var HALF_DEPTH: float = HALF_DEPTH_1


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== (1) GOLUL portilor, masurat ca GOL (grila 1 cm) ===")
	print("%-16s %8s %8s %8s %8s %8s" % ["poarta", "gol_m", "lat_min", "lat_max",
		"cheie_m", "latime"])
	for stem: String in GATES:
		_measure_gate(stem, GATES[stem])

	var only := 10
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--scale="):
			var k := float(arg.trim_prefix("--scale="))
			HALF_SPAN = HALF_SPAN_1 * k
			HALF_DEPTH = HALF_DEPTH_1 * k
			print("amprenta la scara %.2f: semi-latime %.2f m, semi-adancime %.2f m" % [
				k, HALF_SPAN, HALF_DEPTH])
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	for i in 4:
		await get_tree().physics_frame
	print("")
	print("=== (2) %s: traseul lui E (%.3f..%.3f) ===" % [
		GameState.track_label(only), E_FROM, E_TO])
	_survey_e(track)
	get_tree().quit(0)


func _measure_gate(stem: String, path: String) -> void:
	var ps := load(path) as PackedScene
	var root := ps.instantiate() as Node3D
	var lateral_is_x := stem == "market_gate"
	# Triunghiurile in spatiul radacinii, proiectate pe (lateral, y).
	var tris: Array[PackedVector2Array] = []
	var lat_lo := INF
	var lat_hi := -INF
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible:
			continue
		var xf := _xf_to_root(mi, root)
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var vt: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var count := idx.size() if idx.size() > 0 else vt.size()
			for t in range(0, count, 3):
				var tri := PackedVector2Array()
				for k in 3:
					var vi := idx[t + k] if idx.size() > 0 else t + k
					var p: Vector3 = xf * vt[vi]
					var lat := p.x if lateral_is_x else p.z
					tri.append(Vector2(lat, p.y))
					lat_lo = minf(lat_lo, lat)
					lat_hi = maxf(lat_hi, lat)
				tris.append(tri)
	# Coloane de 1 cm pe lateral: cea mai joasa cota ocupata in fereastra si
	# cea mai joasa cota ocupata peste sol (pentru cheie).
	var ncol := int(ceil((lat_hi - lat_lo) / CELL)) + 1
	var blocked_win := PackedByteArray()
	blocked_win.resize(ncol)
	var lowest := PackedFloat32Array()
	lowest.resize(ncol)
	lowest.fill(1e9)
	for tri in tris:
		var a := tri[0]
		var b := tri[1]
		var c := tri[2]
		var x0 := minf(a.x, minf(b.x, c.x))
		var x1 := maxf(a.x, maxf(b.x, c.x))
		var i0 := int(floor((x0 - lat_lo) / CELL))
		var i1 := int(ceil((x1 - lat_lo) / CELL))
		for i in range(maxi(i0, 0), mini(i1, ncol - 1) + 1):
			var cx := lat_lo + (float(i) + 0.5) * CELL
			# intervalul de y al triunghiului pe verticala x = cx
			var span := _tri_y_span(a, b, c, cx)
			if span.x > span.y:
				continue
			if span.y >= WIN_LO and span.x <= WIN_HI:
				blocked_win[i] = 1
			if span.y > 0.05:
				lowest[i] = minf(lowest[i], maxf(span.x, 0.0))
	var i_axis := int(floor((0.0 - lat_lo) / CELL))
	var l := i_axis
	while l > 0 and blocked_win[l - 1] == 0:
		l -= 1
	var r := i_axis
	while r < ncol - 1 and blocked_win[r + 1] == 0:
		r += 1
	var gap_lo := lat_lo + float(l) * CELL
	var gap_hi := lat_lo + float(r + 1) * CELL
	var crown := 1e9
	for i in ncol:
		var cx := lat_lo + (float(i) + 0.5) * CELL
		if absf(cx) <= CROWN_HALF:
			crown = minf(crown, lowest[i])
	print("%-16s %8.3f %8.3f %8.3f %8.3f %8.2f" % [stem, gap_hi - gap_lo,
		gap_lo, gap_hi, crown, lat_hi - lat_lo])
	root.free()


## Intervalul de y [min, max] pe care triunghiul abc il taie pe verticala x.
func _tri_y_span(a: Vector2, b: Vector2, c: Vector2, x: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for e in [[a, b], [b, c], [c, a]]:
		var p: Vector2 = e[0]
		var q: Vector2 = e[1]
		if (p.x - x) * (q.x - x) > 0.0:
			continue
		if absf(q.x - p.x) < 1e-6:
			lo = minf(lo, minf(p.y, q.y))
			hi = maxf(hi, maxf(p.y, q.y))
		else:
			var t := (x - p.x) / (q.x - p.x)
			var y := p.y + t * (q.y - p.y)
			lo = minf(lo, y)
			hi = maxf(hi, y)
	return Vector2(lo, hi)


func _xf_to_root(n: Node3D, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _survey_e(track: Track) -> void:
	var space := track.get_world_3d().direct_space_state
	var n := track.baked.size()
	print("%6s %5s %7s %6s %7s | %-24s | %-24s | %s" % ["frac", "semi", "raza_m",
		"panta%", "drum_y", "stanga dy min/max", "dreapta dy min/max",
		"loc fata de alt brat (st/dr, m; <0 = turn pe alt drum)"])
	var f := E_FROM
	while f <= E_TO + 1e-6:
		var i := int(round(f * n)) % n
		var p := track.baked[i]
		var tan := _tangent(track, i)
		var side := Vector3(-tan.z, 0.0, tan.x).normalized() # stanga
		var slope := 100.0 * _slope(track, i)
		var rad := _radius(track, i)
		var left := _profile(space, p, tan, side, 1.0)
		var right := _profile(space, p, tan, side, -1.0)
		var cl := _clearance(track, i, p, tan, side, 1.0)
		var cr := _clearance(track, i, p, tan, side, -1.0)
		print("%6.3f %5.1f %7.1f %6.1f %7.2f | %8.2f %8.2f        | %8.2f %8.2f        | %6.1f %6.1f" % [
			f, track.width_at(f), rad, slope, p.y,
			left.x, left.y, right.x, right.y, cl, cr])
		f += E_STEP


func _tangent(track: Track, i: int) -> Vector3:
	var n := track.baked.size()
	var a := track.baked[(i - 2 + n) % n]
	var b := track.baked[(i + 2) % n]
	var d := b - a
	d.y = 0.0
	return d.normalized()


func _slope(track: Track, i: int) -> float:
	var n := track.baked.size()
	var a := track.baked[(i - 2 + n) % n]
	var b := track.baked[(i + 2) % n]
	var h := Vector2(b.x - a.x, b.z - a.z).length()
	return (b.y - a.y) / maxf(h, 0.01)


## Raza pe o coarda de ~8 m (3 puncte), in metri; 9999 = drept.
func _radius(track: Track, i: int) -> float:
	var n := track.baked.size()
	var step := 4
	var a := track.baked[(i - step + n) % n]
	var b := track.baked[i]
	var c := track.baked[(i + step) % n]
	var A := Vector2(a.x, a.z)
	var B := Vector2(b.x, b.z)
	var C := Vector2(c.x, c.z)
	var ab := (B - A).length()
	var bc := (C - B).length()
	var ca := (A - C).length()
	var cross := absf((B - A).cross(C - A))
	if cross < 1e-4:
		return 9999.0
	return ab * bc * ca / (2.0 * cross)


## Min/max (teren - drum) sub amprenta unui turn: lateral 3,6..16,4 m pe
## partea `sgn` (+1 stanga), longitudinal -4,3..+4,3 m, pas 1 m. Raycast de
## sus pe TOT ce e solid (terenul real, nu sampler-ul).
func _profile(space: PhysicsDirectSpaceState3D, p: Vector3, tan: Vector3,
		side: Vector3, sgn: float) -> Vector2:
	var lo := INF
	var hi := -INF
	var lat := 3.6
	while lat <= HALF_SPAN + 0.01:
		var s := -HALF_DEPTH
		while s <= HALF_DEPTH + 0.01:
			var q := p + side * (sgn * lat) + tan * s
			var from := Vector3(q.x, p.y + 80.0, q.z)
			var to := Vector3(q.x, p.y - 80.0, q.z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
			if not hit.is_empty():
				var dy: float = (hit["position"] as Vector3).y - p.y
				lo = minf(lo, dy)
				hi = maxf(hi, dy)
			s += 1.0
		lat += 1.0
	return Vector2(lo, hi)


## Cel mai mic loc (m) dintre amprenta unui turn (partea `sgn`) si marginea
## ORICARUI ALT brat de drum (puncte baked la peste 40 m de-a lungul traseului
## fata de i). Negativ = turnul sta pe asfaltul altui brat al zigzagului.
func _clearance(track: Track, i: int, p: Vector3, tan: Vector3, side: Vector3,
		sgn: float) -> float:
	var n := track.baked.size()
	var skip := int(ceil(40.0 / (2042.0 / float(n))))
	var best := INF
	var lat := 3.6
	while lat <= HALF_SPAN + 0.01:
		var s := -HALF_DEPTH
		while s <= HALF_DEPTH + 0.01:
			var q := p + side * (sgn * lat) + tan * s
			for j in n:
				var dj := absi(j - i)
				dj = mini(dj, n - dj)
				if dj <= skip:
					continue
				var b := track.baked[j]
				if absf(b.y - p.y) > 12.0:
					continue
				var d := Vector2(q.x - b.x, q.z - b.z).length() - track.width_at_index(j)
				best = minf(best, d)
			s += 2.0
		lat += 2.0
	return best
