extends SceneTree
func _init() -> void:
	var d := Node3D.new()
	d.set_script(load("res://scenes/props/fabric_drape.gd"))
	root.add_child(d)
	d.set("width_m", 11.0)
	d.set("pitch_m", 3.0)
	d.set("arches", 3)
	d.set("taper", 0.45)
	print(d.call("report"))
	# amprenta pe sol vs inaltime
	var m: ArrayMesh = d.call("_build")
	var arr: Array = m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var xmin := 1e9; var xmax := -1e9; var zmin := 1e9; var zmax := -1e9; var ymax := -1e9
	for p in v:
		xmin = minf(xmin, p.x); xmax = maxf(xmax, p.x)
		zmin = minf(zmin, p.z); zmax = maxf(zmax, p.z)
		ymax = maxf(ymax, p.y)
	print("amprenta X %.2f  Z %.2f  inaltime %.2f" % [xmax-xmin, zmax-zmin, ymax])
	# cati vertecsi sunt la sol (y < 5% din inaltime)
	var low := 0
	for p in v:
		if p.y < ymax * 0.05: low += 1
	print("vertecsi la sol: %d / %d = %.0f%%" % [low, v.size(), 100.0*low/v.size()])
	quit()
