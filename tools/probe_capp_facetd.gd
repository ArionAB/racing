extends SceneTree

## Cat de departe cad, in valoare de umbrire, doua fatete VECINE de pe acelasi
## horn? Cifra asta decide numarul de trepte din `_shade_facets`.
##
## De ce exista. Dupa ce stratul de detaliu a fost cuantizat pe fata (runda 14),
## gradientul a disparut (66% -> 9%) dar muchiile au SCAZUT (10.5% -> 7%):
## fetele erau plate si aproape de aceeasi valoare. Cauza posibila e ca fetele
## laterale ale unui con au normale apropiate, deci `round(d*4)/4` le snapuieste
## pe ACEEASI treapta si saltul dintre ele e fix zero. Se masoara in loc sa se
## ghiceasca: histograma lui d, si cate perechi vecine cad pe aceeasi treapta.

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var chim: Array[MeshInstance3D] = []
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			chim.append(mi)
	print("mesh-uri gasite: ", chim.size())
	for m in chim.slice(0, 14):
		print("   ", m.name, "  fete=", m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3)
	var sun_elev := deg_to_rad(22.0)
	var sun_azim := deg_to_rad(205.0)
	var sun := Vector3(cos(sun_elev) * sin(sun_azim), sin(sun_elev),
			cos(sun_elev) * cos(sun_azim)).normalized()
	var hist := PackedInt32Array()
	hist.resize(10)
	var total := 0
	var same := 0
	var pairs := 0
	for mi in chim.slice(0, 10):
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if norms.size() != verts.size() or verts.size() % 3 != 0:
				continue
			var ds := PackedFloat32Array()
			for t in verts.size() / 3:
				var i := t * 3
				var nn := norms[i] + norms[i + 1] + norms[i + 2]
				if nn.length_squared() < 0.0001:
					continue
				var d := nn.normalized().dot(sun) * 0.5 + 0.5
				ds.append(d)
				hist[clampi(int(d * 10.0), 0, 9)] += 1
				total += 1
			for i in maxi(ds.size() - 1, 0):
				pairs += 1
				if roundf(ds[i] * 4.0) == roundf(ds[i + 1] * 4.0):
					same += 1
	print("fete masurate: ", total)
	for b in 10:
		print("  d %.1f..%.1f : %d" % [b * 0.1, b * 0.1 + 0.1, hist[b]])
	if pairs > 0:
		print("perechi vecine pe ACEEASI treapta (4 pasi): %.1f%% din %d"
				% [float(same) / float(pairs) * 100.0, pairs])
	quit()
