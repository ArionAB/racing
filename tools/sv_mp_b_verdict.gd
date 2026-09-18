extends Node
## `probe_manual` raporteaza 264 de piese "INGROPAT / IN DRUM" in ZoneB. Sonda
## asta verifica daca verdictul e real, fiindca probe_manual compara cu
## `_sampler.ground_y` — CAMPUL NETED — iar memoria `terrain-mesh-y-extrapoleaza`
## spune exact ca acela minte langa o rupere de panta. Zona B are acum un perete
## de 15 m lipit de asfalt, deci e cazul cel mai rau posibil pentru campul neted.
##
## Aici se masoara ce conteaza de fapt, pe coliziunea REALA:
##   1. cat de departe e piesa de suprafata pe care s-ar aseza (raycast), si
##   2. daca gabaritul ei intra in carosabil (proiectie pe normala laterala).
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus := 0.0
var _fam := {}
var _tot_fam := {}

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus = hi + 250.0
	var zone := _track.get_node_or_null("DecorManual/ZoneB_DrumulIncas")
	if zone == null:
		print("nu exista zona"); get_tree().quit(0); return
	var n := _track.baked.size()
	var tot := 0; var rau_sol := 0; var rau_drum := 0
	var worst_sol := 0.0; var worst_drum := 1e9
	for c in zone.get_children():
		var n3 := c as Node3D
		if n3 == null: continue
		tot += 1
		var f0 := ""
		for ch in String(c.name):
			if ch >= "0" and ch <= "9": break
			f0 += ch
		_tot_fam[f0] = int(_tot_fam.get(f0, 0)) + 1
		var p := n3.global_position
		# 1. suprafata REALA sub piesa
		var sp := _track.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, _sus, p.z), Vector3(p.x, -400.0, p.z))
		q.collide_with_areas = false
		var r := sp.intersect_ray(q)
		var d := 0.0
		if not r.is_empty():
			d = p.y - float((r["position"] as Vector3).y)
			if absf(d) > 1.5:
				rau_sol += 1
				if absf(d) > absf(worst_sol): worst_sol = d
				# pe familii de nume, ca sa se vada CARE generator greseste
				var fam := ""
				for ch in String(c.name):
					if ch >= "0" and ch <= "9": break
					fam += ch
				if not _fam.has(fam): _fam[fam] = [0, 0.0]
				var e: Array = _fam[fam]
				e[0] = int(e[0]) + 1
				if absf(d) > absf(float(e[1])): e[1] = d
				_fam[fam] = e
		# 2. cat de departe lateral fata de MARGINEA locala
		var bi := 0; var bd := 1e18
		for i in n:
			var dd: float = Vector2(p.x - _track.baked[i].x, p.z - _track.baked[i].z).length_squared()
			if dd < bd: bd = dd; bi = i
		var bp: Vector3 = _track.baked[bi]
		var fw: Vector3 = (_track.baked[(bi + 1) % n] - bp); fw.y = 0.0
		var lt := fw.normalized().cross(Vector3.UP).normalized()
		var lat: float = absf((p - bp).dot(lt)) - _track.width_at_index(bi)
		if lat < 0.0:
			rau_drum += 1
			worst_drum = minf(worst_drum, lat)
	print("=== ZoneB, verificare pe COLIZIUNEA REALA (nu pe campul neted) ===")
	print("piese: ", tot)
	print("mai mult de 1,5 m fata de suprafata reala: ", rau_sol, "   cel mai rau: %.2f m" % [worst_sol])
	print("cu originea IN carosabil: ", rau_drum, ("   cel mai rau: %.2f m" % [worst_drum]) if rau_drum > 0 else "")
	print("")
	print("pe familii de piese (cate din total sunt departe de suprafata reala):")
	var ks: Array = _tot_fam.keys(); ks.sort()
	for k: String in ks:
		var bad: int = 0; var w: float = 0.0
		if _fam.has(k):
			bad = int((_fam[k] as Array)[0]); w = float((_fam[k] as Array)[1])
		print("  %-14s %3d din %3d   cel mai rau %+7.2f m" % [k, bad, int(_tot_fam[k]), w])
	get_tree().quit(0)
