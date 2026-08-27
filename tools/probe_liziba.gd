extends SceneTree
## Sectiune reala prin liziba_block.glb: numara triunghiuri in celule de grila.
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var n := ps.instantiate()
	var mi: MeshInstance3D = _find(n)
	var mesh := mi.mesh
	var verts := PackedVector3Array()
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		for i in idx: verts.append(v[i])
	print("triunghiuri: %d" % (verts.size() / 3))
	# harta: pentru fiecare celula 1x1 in XZ, cea mai mica cota a unui triunghi
	# cu centrul in ea si cota intre 0.3 si 6 (adica peretii de la parter)
	print("--- ziduri intre y=0.5 si y=6 (X -21..21, Z -14..14)")
	var occ := {}
	for t in range(verts.size() / 3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		var lo := minf(a.y, minf(b.y, c.y))
		var hi := maxf(a.y, maxf(b.y, c.y))
		if hi < 0.5 or lo > 6.0: continue
		# esantioneaza triunghiul
		for u in range(0, 11):
			for w in range(0, 11 - u):
				var fu := u / 10.0; var fw := w / 10.0
				var p := a + (b - a) * fu + (c - a) * fw
				if p.y < 0.5 or p.y > 6.0: continue
				occ[Vector2i(int(round(p.x)), int(round(p.z)))] = true
	var z := -14
	while z <= 14:
		var line := ""
		var x := -21
		while x <= 21:
			line += "#" if occ.has(Vector2i(x, z)) else "."
			x += 1
		print("z%4d %s" % [z, line])
		z += 1
	# profil de inaltime pe axa x=0 (unde e golul?)
	print("--- cota minima a geometriei peste fiecare (x,z), y in 0..25, pe linia z=0")
	quit()

func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
