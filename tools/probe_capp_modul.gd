extends Node
## Profilul REAL al modulului: pentru fiecare felie de inaltime, cat de departe
## ajunge geometria pe fiecare directie orizontala. Fara asta, garda de
## carosabil se bazeaza pe o cutie care nu exista.

const PATH := "res://assets/models/cappadocia/rocks/cliff_band_module.glb"

func _ready() -> void:
	var inst := (load(PATH) as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	var vs: PackedVector3Array = PackedVector3Array()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		var xf := (mi as MeshInstance3D).transform
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				vs.append(xf * v)
	print("vertecsi: ", vs.size())
	for band in range(0, 14, 2):
		var lo := float(band)
		var hi := float(band) + 2.0
		var zmin := 1e9
		var zmax := -1e9
		var xmin := 1e9
		var xmax := -1e9
		for v in vs:
			if v.y >= lo and v.y < hi:
				zmin = minf(zmin, v.z); zmax = maxf(zmax, v.z)
				xmin = minf(xmin, v.x); xmax = maxf(xmax, v.x)
		if zmax > zmin:
			print("  y %4.1f-%4.1f : z %6.2f .. %6.2f   x %6.2f .. %6.2f" % [
				lo, hi, zmin, zmax, xmin, xmax])
	get_tree().quit(0)
