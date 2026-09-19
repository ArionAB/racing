extends SceneTree
## GOLUL LIBER PE AXA DRUMULUI, pe piesele prin care se CONDUCE.
##
## De ce exista separat de probe_machupicchu_kit.gd: AABB-ul unei porti da
## ANVERGURA ei (main_gate: 16,80 m), nu deschiderea. Contractul de gameplay e
## deschiderea, si ea se masoara turnand raze verticale printr-o grila in planul
## portii: o coloana e LIBERA daca nicio raza nu atinge geometria intre y_lo si
## y_hi. Golul = cea mai lata banda continua de coloane libere.
##
## Brief-ul da 8,390 m pentru main_gate si 14,000 m pentru inti_punku; aici se
## verifica pe geometrie, nu pe docs (memoria justificarea-din-comentariu-se-
## verifica).
##
##   godot --headless --path <worktree> --script res://tools/probe_mp_gaps.gd

const STEP: float = 0.01  ## rezolutia grilei pe axa laterala (1 cm)

## fisier -> [axa_laterala, y_lo, y_hi]
## axa: "x" sau "z" — pe care axa se masoara latimea golului.
const CASES := [
	["structures/main_gate", "x", 0.15, 0.60],      # gol la BAZA (intre usciori)
	["structures/main_gate", "x", 0.15, 5.80],      # gol sub buiandrug
	["structures/inti_punku", "x", 0.15, 4.80],
	["structures/inca_bridge_ledge", "z", 8.00, 11.00],  # la cota cornisei
	["structures/inca_bridge_ledge", "z", 0.15, 12.80],  # pe toata inaltimea
]


func _init() -> void:
	for cfg in CASES:
		var key: String = cfg[0]
		var axis: String = cfg[1]
		var y_lo: float = cfg[2]
		var y_hi: float = cfg[3]
		var path := "res://assets/models/machupicchu/%s.glb" % key
		var ps := load(path) as PackedScene
		if ps == null:
			print("%s: NU SE INCARCA" % key)
			continue
		var root := ps.instantiate() as Node3D
		# Un corp static cu colizoare trimesh pe fiecare mesh, ca sa putem
		# arunca raze prin el.
		var body := StaticBody3D.new()
		var tris: Array[Vector3] = []
		_collect(root, Transform3D.IDENTITY, tris)
		var whole := AABB()
		var first := true
		for t in tris:
			if first:
				whole = AABB(t, Vector3.ZERO)
				first = false
			else:
				whole = whole.expand(t)
		var lo: float = whole.position.x if axis == "x" else whole.position.z
		var hi: float = lo + (whole.size.x if axis == "x" else whole.size.z)
		# Pentru fiecare coloana, cea mai mica / mare y a triunghiurilor care o
		# intersecteaza in proiectie 2D pe (lateral, y).
		var n := int((hi - lo) / STEP) + 1
		var blocked := PackedByteArray()
		blocked.resize(n)
		for ti in range(0, tris.size(), 3):
			var a := tris[ti]
			var b := tris[ti + 1]
			var c := tris[ti + 2]
			var la: float = a.x if axis == "x" else a.z
			var lb: float = b.x if axis == "x" else b.z
			var lc: float = c.x if axis == "x" else c.z
			# Proiectie conservatoare: bbox-ul triunghiului pe (lateral, y).
			var t_lo := minf(la, minf(lb, lc))
			var t_hi := maxf(la, maxf(lb, lc))
			var ty_lo := minf(a.y, minf(b.y, c.y))
			var ty_hi := maxf(a.y, maxf(b.y, c.y))
			if ty_hi < y_lo or ty_lo > y_hi:
				continue
			var i0 := clampi(int(floor((t_lo - lo) / STEP)), 0, n - 1)
			var i1 := clampi(int(ceil((t_hi - lo) / STEP)), 0, n - 1)
			for i in range(i0, i1 + 1):
				blocked[i] = 1
		# cea mai lunga banda de coloane LIBERE, ignorand marginile exterioare
		var best := 0
		var best_start := -1
		var run := 0
		var run_start := 0
		for i in range(n):
			if blocked[i] == 0:
				if run == 0:
					run_start = i
				run += 1
				if run > best:
					best = run
					best_start = run_start
			else:
				run = 0
		var gap := float(best) * STEP
		var g_lo := lo + float(best_start) * STEP
		print("%-32s axa %s  anvergura %6.2f m (%.2f..%.2f)  gol LIBER %6.3f m la %.2f..%.2f  (fereastra y %.2f..%.2f)" % [
			key.get_file(), axis, hi - lo, lo, hi,
			gap, g_lo, g_lo + gap, y_lo, y_hi])
		root.free()
		body.free()
	quit()


func _collect(n: Node, xf: Transform3D, out: Array[Vector3]) -> void:
	var here := xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		var faces := mi.mesh.get_faces()
		for v in faces:
			out.append(here * v)
	for c in n.get_children():
		_collect(c, here, out)

