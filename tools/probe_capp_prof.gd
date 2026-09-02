extends Node
## PROFILUL unei coloane din peretele opus: y si rulaj, banda cu banda.
##
## Capturile arata masa ca pe niste dune netede, desi far_relief_m=1.1 ar trebui
## sa dea trepte de ~27 px la 42 m. Deci ori treapta nu se aplica, ori se aplica
## in DIRECTIA GRESITA (fiecare banda de jos iese SPRE drum, si atunci fata e o
## lespede inclinata care isi ascunde propriile polite, in loc de trepte care
## urca in retragere). Sonda tipareste coloana reala, sa se vada care.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var route := _track.route_at(0)
	var n := route.count()
	var root := _track.find_child("CliffFaces", true, false)
	var mi: MeshInstance3D = null
	for ch in root.get_children():
		if String(ch.name).contains("MalulOpus"):
			mi = ch as MeshInstance3D
	if mi == null:
		print("nu exista panza malului opus")
		get_tree().quit(0)
		return
	# ia vertecsii dintr-o felie subtire in jurul fractiei 0.32
	var idx := 326
	var c := _track.point_at(idx)
	var sd: Vector3 = route.side_at(idx)
	var fwd: Vector3 = (_track.point_at((idx + 1) % n) - c).normalized()
	var arrs: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
	var vs: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
	# Intai: pe ce interval de fractii exista efectiv coloane?
	var fr_lo := 1e9
	var fr_hi := -1e9
	for k in vs.size():
		var w: Vector3 = mi.global_transform * vs[k]
		var bi := 0
		var bd := 1e9
		for i in n:
			var pp := _track.point_at(i)
			var d2 := (pp.x - w.x) * (pp.x - w.x) + (pp.z - w.z) * (pp.z - w.z)
			if d2 < bd:
				bd = d2
				bi = i
		var fr := float(bi) / float(n)
		fr_lo = minf(fr_lo, fr)
		fr_hi = maxf(fr_hi, fr)
	print("   panza acopera fractiile %.3f .. %.3f" % [fr_lo, fr_hi])
	print("   idx cerut = %d (din count()=%d)" % [idx, n])
	# histograma: cate varfuri cad pe fiecare indice, in jurul lui idx
	var hist := {}
	for k in vs.size():
		var w2: Vector3 = mi.global_transform * vs[k]
		var bi2 := 0
		var bd2 := 1e9
		for i in n:
			var pp2 := _track.point_at(i)
			var dd := (pp2.x - w2.x) * (pp2.x - w2.x) + (pp2.z - w2.z) * (pp2.z - w2.z)
			if dd < bd2:
				bd2 = dd
				bi2 = i
		hist[bi2] = int(hist.get(bi2, 0)) + 1
	var keys := hist.keys()
	keys.sort()
	var shown := 0
	for kk in keys:
		if absi(int(kk) - idx) <= 25:
			print("      idx %d: %d varfuri" % [int(kk), int(hist[kk])])
			shown += 1
	if shown == 0:
		print("      NICIUN varf pe +-25 indici de idx; indici prezenti: %d..%d" % [int(keys[0]), int(keys[keys.size() - 1])])
	# Selectia pe INDICE DE TRASEU, nu pe proiectie pe tangenta: la 42 m rulaj
	# lateral pe un viraj, arcul peretelui se departeaza de tangenta drumului,
	# deci o felie "±4.5 m de-a lungul tangentei" cade intre coloane si iese
	# goala. Indicele celui mai apropiat punct de traseu nu are problema asta.
	var rows: Array = []
	for k in vs.size():
		var v: Vector3 = mi.global_transform * vs[k]
		var bi := 0
		var bd := 1e9
		for i in n:
			var pp := _track.point_at(i)
			var d2 := (pp.x - v.x) * (pp.x - v.x) + (pp.z - v.z) * (pp.z - v.z)
			if d2 < bd:
				bd = d2
				bi = i
		if absi(bi - idx) > 0:
			continue
		var cc := _track.point_at(bi)
		var ss: Vector3 = route.side_at(bi)
		rows.append(Vector2((v - cc).dot(ss), v.y))
	rows.sort_custom(func(a, b): return a.y > b.y)
	print("=== COLOANA MALULUI OPUS la frac 0.32 (ax y=%.1f) ===" % c.y)
	print("   rulaj[m]   y[m]   (rulaj creste = spre vale)")
	print("   (%d varfuri in fereastra)" % rows.size())
	var last := Vector2(-999, -999)
	for r in rows:
		if absf(r.y - last.y) < 0.25 and absf(r.x - last.x) < 0.25:
			continue
		print("   %+8.2f  %7.2f" % [r.x, r.y])
		last = r
	get_tree().quit(0)
