extends Node
## Unde stau, in metri fata de AX si pe ce LATURA, mesh-urile celor 3 noduri
## [CliffFace] ale POI B. Verdictul rundei 3 spune "stanca sta la 20+ m in
## stanga"; survey-ul de teren spune ca stanga e platou. Una din doua minte,
## si asta arata care: proiecteaza AABB-ul fiecarui mesh pe normala laterala a
## drumului la fractia lui de mijloc.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _track.baked.size()
	# Mesh-urile NU stau sub Marker3D: `CliffFace.build_all` le pune intr-un nod
	# separat `CliffFaces`, copil al pistei. Prima versiune a sondei cauta sub
	# marker si raporta "0 mesh-uri" — memoria `sonda-masura-alt-obiect`.
	var cf := _find(_track, "CliffFaces")
	print("nod CliffFaces: ", ("LIPSA" if cf == null else str(cf.get_child_count()) + " copii"))
	if cf != null:
		for m in cf.get_children():
			var mm: Array[MeshInstance3D] = []
			_collect(m, mm)
			if m is MeshInstance3D: mm.append(m as MeshInstance3D)
			for mi in mm:
				var ab := mi.get_aabb()
				var wc: Vector3 = mi.global_transform * ab.get_center()
				var bi := _nearest(wc)
				var bp: Vector3 = _track.baked[bi]
				var dr: Vector3 = (_track.baked[(bi + 1) % n] - bp); dr.y = 0.0
				var lt := dr.normalized().cross(Vector3.UP).normalized()
				var lo := 1e9; var hi := -1e9; var ylo := 1e9; var yhi := -1e9
				for k in 8:
					var wp: Vector3 = mi.global_transform * ab.get_endpoint(k)
					var d: float = (wp - bp).dot(lt)
					lo = minf(lo, d); hi = maxf(hi, d)
					ylo = minf(ylo, wp.y); yhi = maxf(yhi, wp.y)
				print("  %-30s frac~%.3f semi=%.2f  lateral %+7.1f..%+7.1f (+=dr)  y %+6.1f..%+6.1f (ax %+.1f)" % [m.name + "/" + mi.name, float(bi) / float(n), _track.width_at_index(bi), lo, hi, ylo, yhi, bp.y])
	var fal := _track.get_node_or_null("Faleze")
	if fal == null:
		print("NU exista nodul Faleze"); get_tree().quit(0); return
	for nod in fal.get_children():
		print("--- ", nod.name, " side=", nod.get("side"), " cut_offset_m=", nod.get("cut_offset_m"))
		var meshes: Array[MeshInstance3D] = []
		_collect(nod, meshes)
		print("    ", meshes.size(), " mesh-uri copil")
		var fmid: float = (float(nod.get("frac_start")) + float(nod.get("frac_end"))) * 0.5
		var idx := int(round(fmid * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var dir: Vector3 = (_track.baked[(idx + 1) % n] - bp); dir.y = 0.0
		dir = dir.normalized()
		var lat := dir.cross(Vector3.UP).normalized()
		print("    frac mijloc %.3f  ax=(%.1f,%.1f,%.1f)  lat=(%.2f,%.2f)  semi=%.2f" % [fmid, bp.x, bp.y, bp.z, lat.x, lat.z, _track.width_at_index(idx)])
		for m in meshes:
			var ab := m.get_aabb()
			var lo := 1e9; var hi := -1e9; var ylo := 1e9; var yhi := -1e9
			for k in 8:
				var c := ab.get_endpoint(k)
				var wp: Vector3 = m.global_transform * c
				var d: float = (wp - bp).dot(lat)
				lo = minf(lo, d); hi = maxf(hi, d)
				ylo = minf(ylo, wp.y); yhi = maxf(yhi, wp.y)
			print("      %-28s lateral %+7.1f .. %+7.1f m  (+=dreapta)   y %+6.1f..%+6.1f (ax %+.1f)" % [m.name, lo, hi, ylo, yhi, bp.y])
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


func _collect(nod: Node, out: Array[MeshInstance3D]) -> void:
	for c in nod.get_children():
		if c is MeshInstance3D: out.append(c as MeshInstance3D)
		_collect(c, out)
