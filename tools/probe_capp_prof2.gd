extends Node
## Profilul VERTICAL al modulului de faleza: cat de mult iese fata dinspre
## sosea (z minim) la fiecare cota. Asta spune daca modulul are trepte reale
## in profil sau e o placa dreapta pe care benzile sunt doar textura.
##
## Runda 3: trei critici cer trepte reale in PROFIL. Inainte de a le construi
## trebuie stiut ce profil are piesa acum — altfel se adauga o rama peste un
## perete, capcana rundei 17.

const P := "res://assets/models/cappadocia/rocks/cliff_band_module.glb"

func _ready() -> void:
	var inst := (load(P) as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	var verts: PackedVector3Array = PackedVector3Array()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				verts.append(xf * v)
	var ymin := 1e9
	var ymax := -1e9
	for v in verts:
		ymin = minf(ymin, v.y); ymax = maxf(ymax, v.y)
	print("verts=", verts.size(), " y=", "%.2f..%.2f" % [ymin, ymax])
	# Felii de 0.5 m: z minim (fata spre sosea) si z maxim.
	var step := 0.5
	var y := ymin
	while y < ymax:
		var zmin := 1e9
		var zmax := -1e9
		var cnt := 0
		for v in verts:
			if v.y >= y and v.y < y + step:
				zmin = minf(zmin, v.z); zmax = maxf(zmax, v.z); cnt += 1
		if cnt > 0:
			print("y %5.1f  n=%4d  zmin %6.2f  zmax %6.2f" % [y, cnt, zmin, zmax])
		y += step
	get_tree().quit(0)
