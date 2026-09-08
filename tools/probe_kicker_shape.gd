extends SceneTree
## Profilul REAL al rampei din kopje_kicker.glb (POI C, Serengeti): pentru o
## grila de (x, z) in spatiul GLB-ului tipareste cota maxima a suprafetei
## (rasterizare a triunghiurilor), ca sa stim unde e talpa rampei, unde e buza
## si cat de late sunt bolovanii. Brief-ul zicea 8 x 6 x 2,8 m; AABB-ul spune
## 20 x 5,9 x 18. Se masoara, nu se presupune.
##
##   godot --headless --path . --script res://tools/probe_kicker_shape.gd

const GLB := "res://assets/models/serengeti/rocks/kopje_kicker.glb"


func _init() -> void:
	var scene := (load(GLB) as PackedScene).instantiate()
	var tris: Array = []
	_collect(scene, Transform3D.IDENTITY, tris)
	print("triunghiuri: %d" % tris.size())
	var step := 1.0
	var head := "   z\\x "
	var x := -16.0
	while x <= 5.0:
		head += "%5.0f" % x
		x += step
	print(head)
	var z := -9.0
	while z <= 9.0:
		var row := "%5.1f  " % z
		x = -16.0
		while x <= 5.0:
			var h := _height_at(tris, x, z)
			row += "  ---" if h < -100.0 else "%5.1f" % h
			x += step
		print(row)
		z += step
	print("--- profil pe axa x=0, pas 0.5 ---")
	z = -9.0
	while z <= 9.0:
		var h := _height_at(tris, 0.0, z)
		print("z %5.1f  y %s" % [z, "---" if h < -100.0 else "%.2f" % h])
		z += 0.5
	print("--- profil transversal la z=-6 ---")
	x = -10.0
	while x <= 5.0:
		var h := _height_at(tris, x, -6.0)
		print("x %5.1f  y %s" % [x, "---" if h < -100.0 else "%.2f" % h])
		x += 0.5
	quit(0)


func _collect(node: Node, xf: Transform3D, out: Array) -> void:
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				for k in range(0, v.size(), 3):
					out.append([t * v[k], t * v[k + 1], t * v[k + 2]])
			else:
				for k in range(0, idx.size(), 3):
					out.append([t * v[idx[k]], t * v[idx[k + 1]], t * v[idx[k + 2]]])
	for c in node.get_children():
		_collect(c, t, out)


func _height_at(tris: Array, x: float, z: float) -> float:
	var best := -1000.0
	var p := Vector2(x, z)
	for tri in tris:
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		var a2 := Vector2(a.x, a.z)
		var b2 := Vector2(b.x, b.z)
		var c2 := Vector2(c.x, c.z)
		var den := (b2.y - c2.y) * (a2.x - c2.x) + (c2.x - b2.x) * (a2.y - c2.y)
		if absf(den) < 1e-9:
			continue
		var l0 := ((b2.y - c2.y) * (p.x - c2.x) + (c2.x - b2.x) * (p.y - c2.y)) / den
		var l1 := ((c2.y - a2.y) * (p.x - c2.x) + (a2.x - c2.x) * (p.y - c2.y)) / den
		var l2 := 1.0 - l0 - l1
		if l0 < -1e-4 or l1 < -1e-4 or l2 < -1e-4:
			continue
		best = maxf(best, l0 * a.y + l1 * b.y + l2 * c.y)
	return best
