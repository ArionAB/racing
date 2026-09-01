extends Node
## Cati pixeli VIZIBILI ai conurilor din cadru privesc spre soare, si cum se
## schimba asta cu azimutul. Intrebarea rundei 24, dupa ce controlul noambient a
## aratat ca hornUmbra8 si hornGemen9 sunt NEGRE fara ambient: nu "cat de bine
## umbrim", ci "camera vede vreo fata luminata?".
##
## Nu randeaza — proiecteaza geometria si numara pe fata vazuta de camera.
## Deci se poate baleia azimutul fara sa reconstruiasca scena.
const W: int = 1280
const H: int = 720

var _cam: Camera3D
var _depth: PackedFloat32Array
var _owner: PackedInt32Array
var _nx: PackedFloat32Array
var _ny: PackedFloat32Array
var _nz: PackedFloat32Array
var _nume: Array[String] = []

func _ready() -> void:
	var idx := 13
	var frac := 0.06
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame
	_cam = Camera3D.new()
	add_child(_cam)
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var ii := int(frac * float(n)) % n
	var focus: Vector3 = pts[ii]
	var ahead: Vector3 = pts[route.wrap_index(ii + 12)]
	var dir := (ahead - focus).normalized()
	_cam.fov = 68.0
	_cam.near = 0.05
	_cam.far = 400.0
	get_viewport().size = Vector2i(W, H)
	_cam.global_position = focus - dir * 7.5 + Vector3.UP * 3.2
	_cam.look_at(focus + dir * 14.0 + Vector3.UP * 1.2, Vector3.UP)
	_cam.current = true
	await get_tree().process_frame
	print("camera priveste spre %s (azimut %.0f)"
			% [dir.snappedf(0.01), rad_to_deg(atan2(dir.x, dir.z))])

	_depth = PackedFloat32Array(); _depth.resize(W * H); _depth.fill(1e20)
	_owner = PackedInt32Array(); _owner.resize(W * H); _owner.fill(-1)
	_nx = PackedFloat32Array(); _nx.resize(W * H)
	_ny = PackedFloat32Array(); _ny.resize(W * H)
	_nz = PackedFloat32Array(); _nz.resize(W * H)
	_raster(track)

	print("")
	print("procent din pixelii vizibili ai conului cu dot(normala, spre_soare) > 0.1")
	var head := "  azimut "
	var tinte := ["hornUmbra8", "hornGemen9", "hornSoare11", "hornSoare7"]
	for t in tinte:
		head += "%12s" % t
	head += "%12s" % "TOATE"
	print(head)
	for az in range(115, 306, 10):
		var e := deg_to_rad(22.0)
		var a := deg_to_rad(float(az))
		var sun := Vector3(cos(e) * sin(a), sin(e), cos(e) * cos(a)).normalized()
		var lin := PackedInt32Array(); lin.resize(_nume.size()); lin.fill(0)
		var tot := PackedInt32Array(); tot.resize(_nume.size()); tot.fill(0)
		for k in _owner.size():
			var o := _owner[k]
			if o < 0:
				continue
			tot[o] += 1
			if _nx[k] * sun.x + _ny[k] * sun.y + _nz[k] * sun.z > 0.1:
				lin[o] += 1
		var line := "  %6d " % az
		var gl := 0
		var gt := 0
		for t in tinte:
			var pl := 0
			var pt := 0
			for i in _nume.size():
				if _nume[i].contains(t):
					pl += lin[i]
					pt += tot[i]
			line += "%11.1f" % (100.0 * float(pl) / maxf(float(pt), 1.0))
			gl += pl
			gt += pt
		line += "%11.1f" % (100.0 * float(gl) / maxf(float(gt), 1.0))
		print(line)
	get_tree().quit(0)

func _raster(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.is_visible_in_tree():
		var nm := String(mi.name)
		var par := mi.get_parent()
		if par != null:
			nm = String(par.name) + "/" + nm
		var id := _nume.size()
		_nume.append(nm)
		_mesh(mi, id)
	for c in n.get_children():
		_raster(c)

func _mesh(mi: MeshInstance3D, id: int) -> void:
	var xf := mi.global_transform
	var cam_xf := _cam.global_transform.affine_inverse()
	var nb := xf.basis.inverse().transposed()
	for s in mi.mesh.get_surface_count():
		if mi.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arr: Array = mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue
		var idx := PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null:
			idx = arr[Mesh.ARRAY_INDEX]
		var nrms := PackedVector3Array()
		if arr[Mesh.ARRAY_NORMAL] != null:
			nrms = arr[Mesh.ARRAY_NORMAL]
		var wp := PackedVector3Array(); wp.resize(verts.size())
		var sx := PackedFloat32Array(); sx.resize(verts.size())
		var sy := PackedFloat32Array(); sy.resize(verts.size())
		var sz := PackedFloat32Array(); sz.resize(verts.size())
		for i in verts.size():
			var wv: Vector3 = xf * verts[i]
			wp[i] = wv
			var z := -(cam_xf * wv).z
			sz[i] = z
			if z <= 0.06:
				sx[i] = -1e9; sy[i] = -1e9
				continue
			var p := _cam.unproject_position(wv)
			sx[i] = p.x; sy[i] = p.y
		var hi := not idx.is_empty()
		var cnt := idx.size() if hi else verts.size()
		var i2 := 0
		while i2 + 2 < cnt:
			var a := idx[i2] if hi else i2
			var b := idx[i2 + 1] if hi else i2 + 1
			var c := idx[i2 + 2] if hi else i2 + 2
			i2 += 3
			if sz[a] <= 0.06 or sz[b] <= 0.06 or sz[c] <= 0.06:
				continue
			var nr := Vector3.ZERO
			if not nrms.is_empty():
				nr = nb * (nrms[a] + nrms[b] + nrms[c])
			else:
				nr = (wp[b] - wp[a]).cross(wp[c] - wp[a])
			if nr.length_squared() < 1e-12:
				continue
			nr = nr.normalized()
			_tri(sx[a], sy[a], sz[a], sx[b], sy[b], sz[b], sx[c], sy[c], sz[c],
					id, nr)

func _tri(ax: float, ay: float, az: float, bx: float, by: float, bz: float,
		cx: float, cy: float, cz: float, id: int, nr: Vector3) -> void:
	var minx := maxi(int(floor(minf(ax, minf(bx, cx)))), 0)
	var maxx := mini(int(ceil(maxf(ax, maxf(bx, cx)))), W - 1)
	var miny := maxi(int(floor(minf(ay, minf(by, cy)))), 0)
	var maxy := mini(int(ceil(maxf(ay, maxf(by, cy)))), H - 1)
	if maxx < minx or maxy < miny:
		return
	var det := (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
	if absf(det) < 1e-9:
		return
	var inv := 1.0 / det
	for y in range(miny, maxy + 1):
		var fy := float(y) + 0.5
		var row := y * W
		for x in range(minx, maxx + 1):
			var fx := float(x) + 0.5
			var l0 := ((by - cy) * (fx - cx) + (cx - bx) * (fy - cy)) * inv
			if l0 < 0.0 or l0 > 1.0:
				continue
			var l1 := ((cy - ay) * (fx - cx) + (ax - cx) * (fy - cy)) * inv
			if l1 < 0.0 or l1 > 1.0:
				continue
			var l2 := 1.0 - l0 - l1
			if l2 < 0.0:
				continue
			var k := row + x
			var z := l0 * az + l1 * bz + l2 * cz
			if z < _depth[k]:
				_depth[k] = z
				_owner[k] = id
				_nx[k] = nr.x; _ny[k] = nr.y; _nz[k] = nr.z
