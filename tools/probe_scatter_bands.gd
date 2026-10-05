extends SceneTree
## Masoara decorul procedural al unei piste pe benzi de distanta de MARGINEA
## asfaltului (0-10 / 10-30 / 30-60 m): cate instante pe tip, si cat de GRUPAT
## e vegetatia (indicele Clark-Evans: 1 = uniform-aleator, < 1 grupat,
## > 1 regulat; cat de rare sunt golurile: % din feliile de 10 m de drum fara
## nicio planta in banda 2-25 m). Citeste NODURILE de dinainte de coacere
## (`--no-batch`): transformarile din MultiMesh se citesc ca zero in headless.
##   godot --headless --path . --script res://tools/probe_scatter_bands.gd -- --track=19
var _track: Node = null
var _frames: int = 0
var _idx: int = 12
const PLANTS := ["Sagebrush", "Rabbitbrush", "Juniper", "Yucca"]

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

func _first_mesh_name(n: Node) -> String:
	if n is MeshInstance3D:
		return String(n.name)
	for c in n.get_children():
		var r := _first_mesh_name(c)
		if r != "":
			return r
	return ""

func _kind(n: Node) -> String:
	var nm := String(n.name)
	if nm.begins_with("@") or nm == nm.to_lower():
		nm = _first_mesh_name(n)
	nm = nm.rstrip("0123456789")
	for p in PLANTS:
		if nm.contains(p):
			return p
	if nm.begins_with("Canyon") or nm.begins_with("Kit_") or nm.contains("alus"):
		return "rock"
	return "other:" + nm

func _collect(node: Node, out: Array) -> void:
	for c in node.get_children():
		if c is Node3D and String(c.name).begins_with("Band_"):
			for p in c.get_children():
				if p is Node3D and not (p is MultiMeshInstance3D):
					out.append(p)
		elif c is Node3D and String(c.name) == "Decor":
			_collect(c, out)

func _report() -> void:
	var sampler = _track.get("_sampler")
	var props: Array = []
	for r in _track.get("_decor_roots"):
		if (r as Node).get_node_or_null("Sway") != null:
			_collect(r, props)
	var by_type := {}
	var plant_pts: Array[Vector2] = []
	var plant_off: Array[float] = []
	var hw: float = sampler.half_width()
	for p: Node3D in props:
		var k := _kind(p)
		var o := p.position
		var off: float = sampler.clearance_at(o) - hw
		var b := 0 if off < 10.0 else (1 if off < 30.0 else (2 if off < 60.0 else 3))
		if not by_type.has(k):
			by_type[k] = [0, 0, 0, 0]
		by_type[k][b] += 1
		if k in PLANTS:
			plant_pts.append(Vector2(o.x, o.z))
			plant_off.append(off)
	# Covorul Monument Valley: emis direct in MultiMesh, deci citit din buffer.
	for gk: String in TrackDecor._mv_buf:
		if not gk.contains("|0|"):
			continue
		var key := gk.get_slice("|", 0)
		var k2 := key.get_file().get_basename().capitalize().replace(" ", "")
		if key.begins_with("peb:"):
			k2 = "other:" + key.trim_prefix("peb:")
		elif key.begins_with("rocks/"):
			k2 = "rock"
		for xf: Transform3D in TrackDecor._mv_buf[gk]["xforms"]:
			var o := xf.origin
			var off2: float = sampler.clearance_at(o) - hw
			var b2 := 0 if off2 < 10.0 else (1 if off2 < 30.0 else (2 if off2 < 60.0 else 3))
			if not by_type.has(k2):
				by_type[k2] = [0, 0, 0, 0]
			by_type[k2][b2] += 1
			props.append(null)
			if k2 in PLANTS:
				plant_pts.append(Vector2(o.x, o.z))
				plant_off.append(off2)
	print("PROBE_SCATTER track=%d props=%d" % [_idx, props.size()])
	var names := by_type.keys()
	names.sort()
	var sum := [0, 0, 0, 0]
	for n in names:
		var v: Array = by_type[n]
		print("  %-24s 0-10:%5d  10-30:%5d  30-60:%5d  60+:%5d" % [n, v[0], v[1], v[2], v[3]])
		for q in 4:
			sum[q] += v[q]
	print("  %-24s 0-10:%5d  10-30:%5d  30-60:%5d  60+:%5d" % ["TOTAL", sum[0], sum[1], sum[2], sum[3]])
	# Grupare pe plantele din banda 0-30 m (unde se judeca covorul).
	var pts: Array[Vector2] = []
	for i in plant_pts.size():
		if plant_off[i] < 30.0:
			pts.append(plant_pts[i])
	if pts.size() > 2:
		var nn_sum := 0.0
		var in_clump := 0
		for i in pts.size():
			var best := INF
			for j in pts.size():
				if i != j:
					best = minf(best, pts[i].distance_to(pts[j]))
			nn_sum += best
			if best < 2.5:
				in_clump += 1
		# Aria ocupata: lungimea drumului x 2 parti x 30 m banda (aproximare).
		var area: float = float(sampler.total_length()) * 2.0 * 30.0
		var dens := float(pts.size()) / area
		var expect := 0.5 / sqrt(dens)
		print("CLUMP plante<30m: n=%d  NN mediu=%.2f m  asteptat(Poisson)=%.2f m  Clark-Evans=%.2f  %% cu vecin<2.5m=%.0f" % [
			pts.size(), nn_sum / pts.size(), expect, (nn_sum / pts.size()) / expect,
			100.0 * in_clump / pts.size()])
		# Goluri: felii de 10 m de drum (pe fractie de lungime) fara nicio planta 2-25 m.
		var slices := {}
		var total_len: float = sampler.total_length()
		var n_sl := int(total_len / 10.0) + 1
		for i in plant_pts.size():
			if plant_off[i] < 25.0:
				var v3 := Vector3(plant_pts[i].x, 0, plant_pts[i].y)
				var bk: PackedVector3Array = sampler.get("_baked")
				var ds = sampler.get("_dists")
				var bi := 0
				var bd := INF
				for q in bk.size():
					var dd := (bk[q] - v3).length_squared()
					if dd < bd:
						bd = dd
						bi = q
				slices[int(float(ds[bi]) / 10.0)] = true
		if not slices.is_empty():
			print("GOLURI: %d / %d felii de 10 m fara plante <25 m" % [n_sl - slices.size(), n_sl])
