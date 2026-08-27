extends Node
## Cat din ecran ocupa hero-ul, si CE anume din el, pentru combinatii de
## (distanta laterala, cota talpii). Nu randez: proiectez triunghiurile piesei
## in cadrul camerei de cursa si le sortez in „fatada" (normala orizontala) si
## „acoperis" (normala verticala).
##
## Rostul: incadratura corecta se GASESTE prin masurare, nu prin sase capturi.
const TRACK := "res://scenes/tracks/Track12.tscn"
const GLB := "res://assets/models/chongqing/structures/hongya_dong.glb"

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 4: await get_tree().physics_frame
	var sampler = track._sampler
	var path = TrackScenography._Path.new(sampler)

	# triunghiurile piesei, in spatiul ei local
	var tris: Array = []
	var ps := load(GLB) as PackedScene
	var inst := ps.instantiate()
	var stack: Array = [inst]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children(): stack.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		for si in mi.mesh.get_surface_count():
			var arr = mi.mesh.surface_get_arrays(si)
			var v = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			if v == null: continue
			var cnt: int = idx.size() if idx != null else v.size()
			var i := 0
			while i < cnt - 2:
				var a: Vector3 = v[idx[i]] if idx != null else v[i]
				var b: Vector3 = v[idx[i+1]] if idx != null else v[i+1]
				var c2: Vector3 = v[idx[i+2]] if idx != null else v[i+2]
				tris.append([a, b, c2])
				i += 3

	# camera de cursa la frac 0.30 (ChaseCamera: in spate 6.5 m, sus 2.8 m,
	# uitandu-se spre 8 m in fata)
	var st = path.at(path.total * 0.30)
	var road: Vector3 = st["pos"]
	var fwd: Vector3 = st["forward"]
	var right: Vector3 = st["right"]
	var eye := road - fwd * 6.5 + Vector3.UP * 2.8
	var look := road + fwd * 8.0 + Vector3.UP * 0.5
	var cam := Transform3D().looking_at(look - eye, Vector3.UP)
	cam.origin = eye
	var inv := cam.affine_inverse()
	var fov_y := deg_to_rad(70.0)
	var aspect := 16.0 / 9.0
	var ty := tan(fov_y * 0.5)

	print("lat  talpa_rel | ecran%%  fatada%%  acoperis%%")
	for lat in [9.0, 13.0, 17.0, 22.0, 28.0]:
		for drop in [-2.5, -7.5, -12.5, -17.5, -22.5]:
			var pos := Vector3(road.x + right.x * lat, road.y + drop,
				road.z + right.z * lat)
			var basis := Basis(Vector3.UP, atan2(-right.x, -right.z))
			var xf := Transform3D(basis, pos)
			var facade := 0.0
			var roof := 0.0
			for t: Array in tris:
				var wa: Vector3 = xf * t[0]
				var wb: Vector3 = xf * t[1]
				var wc: Vector3 = xf * t[2]
				var nrm := (wb - wa).cross(wc - wa)
				if nrm.length() < 1e-6: continue
				var un := nrm.normalized()
				# doar fetele spre camera
				if un.dot(wa - eye) > 0.0: continue
				var ca := inv * wa
				var cb := inv * wb
				var cc := inv * wc
				if ca.z > -0.5 or cb.z > -0.5 or cc.z > -0.5: continue
				var pa := Vector2(ca.x / (-ca.z * ty * aspect), ca.y / (-ca.z * ty))
				var pb := Vector2(cb.x / (-cb.z * ty * aspect), cb.y / (-cb.z * ty))
				var pc := Vector2(cc.x / (-cc.z * ty * aspect), cc.y / (-cc.z * ty))
				var ar: float = absf((pb - pa).cross(pc - pa)) * 0.5
				if absf(un.y) > 0.6: roof += ar
				else: facade += ar
			var tot := facade + roof
			# aria normalizata: 1.0 = tot ecranul (NDC -1..1 are aria 4)
			print("%4.0f  %+6.1f    | %6.1f  %6.1f  %6.1f" % [
				lat, drop, 100.0 * tot / 4.0, 100.0 * facade / 4.0,
				100.0 * roof / 4.0])
	get_tree().quit(0)
