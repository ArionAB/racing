extends Node
## TAIE PERETELE ORIZONTUL, sau nu?
##
## Testul cerut de amandoi criticii in runda 10 se poate pune ca o singura
## intrebare masurabila: pornind din ochiul soferului si mergand IN SUS pe
## jumatatea dreapta a cadrului, intalnesti geometrie inainte sa ajungi la cer?
##
## Sonda trage raze reale din ochi, in evantai pe exterior (azimut fata de
## directia de mers) si la unghiuri verticale de la -20 la +12 grade. Pentru
## fiecare azimut se cauta cel mai INALT unghi la care raza mai loveste ceva.
## Daca cel mai inalt unghi lovit e NEGATIV, masa sta sub orizont si e o dunga
## la baza cerului. Daca e POZITIV, peretele chiar taie linia orizontului.
##
## Nu numara vertecsi si nu se uita la AABB: amandoua trec si cand pe ecran nu e
## nimic (vezi „efecte-invizibile-nu-se-numara").
##
## Razele se trag pe TRIUNGHIURILE panzei, nu prin motorul de fizica: `_build_far`
## intoarce un MeshInstance3D fara corp de coliziune (peretele e la 45 m, nu se
## conduce pe el), deci un intersect_ray trece prin el ca prin aer si ar raporta
## fals „sub orizont". Prima varianta a sondei chiar a facut greseala asta.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const EYE_M: float = 6.0
const FRACS: Array[float] = [0.20, 0.28, 0.32]
const AZIM: Array[float] = [20.0, 40.0, 60.0, 80.0, 100.0]
const REACH: float = 400.0

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== TAIE ORIZONTUL? (raze din ochi, exterior dreapta) ===")
	for f in FRACS:
		_scan(f)
	get_tree().quit(0)


func _scan(frac: float) -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var idx := clampi(int(round(frac * float(n))), 0, n - 1)
	var c := _track.point_at(idx)
	var side := route.side_at(idx)
	var fwd: Vector3 = (_track.point_at((idx + 1) % n) - c).normalized()
	var eye := c + Vector3.UP * EYE_M
	print("  --- frac %.2f, ochi (%.0f,%.1f,%.0f) ---" % [frac, eye.x, eye.y, eye.z])
	# Toate triunghiurile panzelor de faleza, in coordonate globale.
	var tris: Array[PackedVector3Array] = []
	var root := _track.find_child("CliffFaces", true, false)
	if root != null:
		for ch in root.get_children():
			var mi := ch as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var xf := mi.global_transform
			var arrs: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
			var vs: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
			var ixv: Variant = arrs[Mesh.ARRAY_INDEX]
			var ix: PackedInt32Array = ixv if ixv != null else PackedInt32Array()
			var t := PackedVector3Array()
			if ix.size() > 0:
				for k in ix.size():
					t.append(xf * vs[ix[k]])
			else:
				for k in vs.size():
					t.append(xf * vs[k])
			tris.append(t)
	var cut := 0
	for az in AZIM:
		var a := deg_to_rad(az)
		var dir_h: Vector3 = (fwd * cos(a) + side * sin(a)).normalized()
		var top_hit := -99.0
		var top_d := 0.0
		var vang := -20.0
		while vang <= 12.0:
			var v := deg_to_rad(vang)
			var dir: Vector3 = (dir_h * cos(v) + Vector3.UP * sin(v)).normalized()
			var d := _hit(tris, eye, dir)
			if d > 0.0:
				top_hit = vang
				top_d = d
			vang += 1.0
		if top_hit > 0.0:
			cut += 1
		print("    azimut %+4.0f gr: cel mai sus lovit %+5.1f gr la %5.1f m   %s"
			% [az, top_hit, top_d,
			"TAIE ORIZONTUL" if top_hit > 0.0 else ("la orizont" if top_hit > -1.5 else "sub orizont")])
	print("    -> %d din %d azimuturi taie orizontul" % [cut, AZIM.size()])


## Cea mai apropiata lovitura a razei in oricare triunghi de faleza; -1 daca nimic.
func _hit(tris: Array[PackedVector3Array], from: Vector3, dir: Vector3) -> float:
	var best := -1.0
	for t in tris:
		var i := 0
		while i + 2 < t.size():
			var r = Geometry3D.ray_intersects_triangle(from, dir, t[i], t[i + 1], t[i + 2])
			if r != null:
				var d := from.distance_to(r as Vector3)
				if d <= REACH and (best < 0.0 or d < best):
					best = d
			i += 3
	return best
