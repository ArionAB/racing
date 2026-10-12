extends SceneTree
## Masoara covorul de vegetatie Okinawa (Track20): cate instante pe tip, pe POI
## (zonele din okinawa_poi_gauntlet.md) si pe latura, distanta minima fata de
## MARGINEA asfaltului si triunghiurile pe tip. Citeste bufferul static
## `TrackDecor._mv_buf` (transformarile din MultiMesh se citesc zero in headless).
##   godot --headless --path . --script res://tools/probe_oki_scatter.gd
## Optional: --track=20 (numar de scena).
var _track: Node = null
var _frames: int = 0
var _idx: int = 20

const ZONES := [["A", 0.974, 1.001], ["A", 0.0, 0.1023], ["B", 0.1023, 0.205],
	["C", 0.205, 0.333], ["D", 0.333, 0.474], ["E", 0.474, 0.612],
	["F", 0.612, 0.737], ["G", 0.737, 0.824], ["H", 0.824, 0.974]]


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_idx = int(arg.trim_prefix("--track="))
	var path := "res://scenes/tracks/Track%02d.tscn" % _idx
	_track = (load(path) as PackedScene).instantiate()
	root.add_child(_track)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	_report()
	quit(0)
	return true


func _zone(frac: float) -> String:
	for z: Array in ZONES:
		if frac >= float(z[1]) and frac < float(z[2]):
			return String(z[0])
	return "?"


func _tris(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var ind = arr[Mesh.ARRAY_INDEX]
		if ind != null and (ind as PackedInt32Array).size() > 0:
			n += (ind as PackedInt32Array).size() / 3
		else:
			n += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n


func _report() -> void:
	var sampler = _track.get("_sampler")
	var baked: PackedVector3Array = sampler.get("_baked")
	var dists = sampler.get("_dists")
	var total: float = sampler.total_length()
	var per_key := {}      # key -> {n, tris, min_off, zones{}, bands[3]}
	var per_zone := {}     # zona -> {L: n, R: n}
	var total_tris := 0
	for gk: String in TrackDecor._mv_buf:
		var g: Dictionary = TrackDecor._mv_buf[gk]
		var key := gk.get_slice("|", 0)
		var part_i := int(gk.get_slice("|", 1))
		var xforms: Array = g["xforms"]
		var tri: int = _tris((g["part"] as Dictionary)["mesh"]) * xforms.size()
		total_tris += tri
		if not per_key.has(key):
			per_key[key] = {"n": 0, "tris": 0, "min_off": INF,
				"zones": {}, "bands": [0, 0, 0, 0]}
		var pk: Dictionary = per_key[key]
		pk["tris"] += tri
		if part_i != 0:
			continue
		for xf: Transform3D in xforms:
			var o := xf.origin
			var bi := 0
			var bd := INF
			for q in baked.size():
				var dd := Vector2(baked[q].x - o.x, baked[q].z - o.z).length_squared()
				if dd < bd:
					bd = dd
					bi = q
			var along: Vector3 = (baked[(bi + 1) % baked.size()] - baked[bi]).normalized()
			var side: Vector3 = along.cross(Vector3.UP)
			var rel := Vector3(o.x - baked[bi].x, 0.0, o.z - baked[bi].z)
			var sgn := "R" if rel.dot(side) > 0.0 else "L"
			var off: float = sqrt(bd) - sampler.half_width_at(bi)
			var z := _zone(float(dists[bi]) / total)
			pk["n"] += 1
			pk["min_off"] = minf(float(pk["min_off"]), off)
			var zk := z + sgn
			pk["zones"][zk] = int(pk["zones"].get(zk, 0)) + 1
			var b := 0 if off < 10.0 else (1 if off < 30.0 else (2 if off < 60.0 else 3))
			pk["bands"][b] += 1
			if not per_zone.has(z):
				per_zone[z] = {"L": [0, 0, 0, 0], "R": [0, 0, 0, 0]}
			per_zone[z][sgn][b] += 1
	print("PROBE_OKI_SCATTER track=%d  tri total=%d" % [_idx, total_tris])
	var keys := per_key.keys()
	keys.sort()
	for k in keys:
		var pk: Dictionary = per_key[k]
		print("  %-34s n=%4d  tri=%8d  min_off=%5.1f  0-10:%d 10-30:%d 30-60:%d 60+:%d" % [
			k, pk["n"], pk["tris"], pk["min_off"], pk["bands"][0], pk["bands"][1],
			pk["bands"][2], pk["bands"][3]])
	print("--- pe POI (L/R, benzi 0-10 / 10-30 / 30-60 / 60+) ---")
	var zs := per_zone.keys()
	zs.sort()
	for z in zs:
		print("  %s  L %s   R %s" % [z, str(per_zone[z]["L"]), str(per_zone[z]["R"])])
	print("--- pe POI si tip (cheile fukugi insumate) ---")
	for z in zs:
		var line := "  %s:" % z
		for k in keys:
			var n := 0
			for zk: String in (per_key[k]["zones"] as Dictionary):
				if zk.begins_with(z):
					n += int(per_key[k]["zones"][zk])
			if n > 0:
				line += "  %s=%d" % [String(k).get_file().get_basename(), n]
		print(line)
