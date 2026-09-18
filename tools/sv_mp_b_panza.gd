extends Node
## Unde stau VERTECSII panzelor `cut_wall`, pe fractii — nu AABB (fara sens peste
## o curba) si nu raze (panzele n-au corp de coliziune, deci razele trec prin
## ele: memoria efecte-invizibile-nu-se-numara, in varianta "sonda a masurat
## altceva").
##
## Ia mesh-ul prin ArrayMesh, transforma fiecare vertex in lume, il asociaza
## celui mai apropiat punct de traseu si raporteaza, per felie de fractie,
## intervalul lateral (+ = dreapta) si de cota. Aia e pozitia reala a peretelui.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _track.baked.size()
	var cf := _find(_track, "CliffFaces")
	if cf == null:
		print("LIPSA CliffFaces"); get_tree().quit(0); return
	for m in cf.get_children():
		var mi := m as MeshInstance3D
		if mi == null:
			for c in m.get_children():
				if c is MeshInstance3D: mi = c as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var arr: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		print("--- ", m.name, "  ", vs.size(), " vertecsi")
		# Transformul nodului: daca `CliffFaces` sau mesh-ul are o translatie,
		# vertecsii construiti in coordonate de LUME ajung mutati cu ea. Asta ar
		# explica un decalaj constant intre aritmetica din `_cut_column` (talpa
		# la -7,60 m de ax, verificat) si pozitia masurata (-19,5 m).
		print("    transform mesh: origin=(%.2f,%.2f,%.2f)" % [mi.global_transform.origin.x, mi.global_transform.origin.y, mi.global_transform.origin.z])
		print("    primul vertex local=(%.2f,%.2f,%.2f)" % [vs[0].x, vs[0].y, vs[0].z])
		# bucket pe fractie
		var lo := {}; var hi := {}; var ylo := {}; var yhi := {}; var cnt := {}
		var lgmax := 0.0
		for v in vs:
			var wp: Vector3 = mi.global_transform * v
			var bi := _nearest(wp)
			var bp: Vector3 = _track.baked[bi]
			var dr: Vector3 = (_track.baked[(bi + 1) % n] - bp); dr.y = 0.0
			var lt := dr.normalized().cross(Vector3.UP).normalized()
			var d: float = (wp - bp).dot(lt) - _track.width_at_index(bi)
			# Reziduul LONGITUDINAL: cat de departe pe directia de mers cade
			# vertexul fata de punctul cu care l-am asociat. Daca e mare, cifra
			# laterala e un artefact de curba, nu o masuratoare.
			var fw: Vector3 = dr.normalized()
			var lg: float = absf((wp - bp).dot(fw))
			lgmax = maxf(lgmax, lg)
			var key := int(round(float(bi) / float(n) * 200.0))  # felii de 0.005
			if not cnt.has(key):
				cnt[key] = 0; lo[key] = 1e9; hi[key] = -1e9; ylo[key] = 1e9; yhi[key] = -1e9
			cnt[key] = int(cnt[key]) + 1
			lo[key] = minf(float(lo[key]), d); hi[key] = maxf(float(hi[key]), d)
			ylo[key] = minf(float(ylo[key]), wp.y - bp.y)
			yhi[key] = maxf(float(yhi[key]), wp.y - bp.y)
		print("    rezidu longitudinal maxim: %.2f m (peste ~3 m, cifra laterala e artefact)" % [lgmax])
		var keys: Array = cnt.keys(); keys.sort()
		for k: int in keys:
			print("    frac %.3f  n=%4d  lateral fata de MARGINE %+7.2f..%+7.2f m (+=dr)  cota fata de ax %+6.1f..%+6.1f" % [float(k) / 200.0, int(cnt[k]), float(lo[k]), float(hi[k]), float(ylo[k]), float(yhi[k])])
	get_tree().quit(0)

func _nearest(w: Vector3) -> int:
	var best := 0; var bd := 1e18
	for i in _track.baked.size():
		var d: float = (_track.baked[i] as Vector3).distance_squared_to(w)
		if d < bd: bd = d; best = i
	return best

func _find(nod: Node, nm: String) -> Node:
	if nod.name == nm: return nod
	for c in nod.get_children():
		var r := _find(c, nm)
		if r != null: return r
	return null
