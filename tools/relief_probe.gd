extends "res://tools/sv_tf_fractii.gd"
## Sonda de relief pentru Track21 (nivel-relief), peste unealta de fractii.
##
##   godot --headless --path . res://tools/ReliefProbe.tscn -- [--lat=f,f] [--dam] [--far]
##         [--pts=x,z;x,z] [--line=x0,z0,x1,z1,pas]
##
## --lat   profil lateral + `_sides` pe fractiile date (index);
## --dam   profilul coronamentului (hau/lac);
## --far   inelele de teren la 250-500 m de centroid;
## --pts   cota terenului (mesh si sampler) in puncte de lume;
## --line  profil de teren pe un segment, pas in metri.
## Nu e garda; masoara terenul care se vede (`_terrain_mesh_y`), nu pe cel din head.


func _arg(name: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a == name:
			return "1"
		if a.begins_with(name + "="):
			return a.substr(name.length() + 1)
	return ""


func _ready() -> void:
	var ps := load(SCENE) as PackedScene
	tr = ps.instantiate() as Track
	add_child(tr)
	for k in 6:
		await get_tree().process_frame
	var r0: TrackRoute = tr.route_at(0)
	n = r0.count()
	L = r0.length()
	var samp: Object = tr.get("_sampler")
	road_y_mean = float(samp.call("mean_road_y"))
	print("cota medie drum %+.2f, n=%d, L=%.1f" % [road_y_mean, n, L])
	var lat := _arg("--lat")
	if lat != "":
		var fr: Array = []
		for s in lat.split(","):
			fr.append(float(s))
		_lateral("relief", fr)
		_sides(fr)
	if _arg("--dam") != "":
		_dam_void()
	if _arg("--far") != "":
		_far_ring()
	var pts := _arg("--pts")
	if pts != "":
		for s in pts.split(";"):
			var xz := s.split(",")
			var x := float(xz[0])
			var z := float(xz[1])
			var ty: float = tr.call("_terrain_mesh_y", x, z)
			var gy: float = samp.call("ground_y", x, z)
			print("  pt (%.0f, %.0f): mesh %+.1f  sampler %+.1f  (fata de drum mediu %+.1f)" % [
				x, z, ty, gy, ty - road_y_mean])
	var line := _arg("--line")
	if line != "":
		var v := line.split(",")
		var a := Vector2(float(v[0]), float(v[1]))
		var b := Vector2(float(v[2]), float(v[3]))
		var step := float(v[4])
		var len := a.distance_to(b)
		var d := 0.0
		while d <= len + 0.01:
			var p := a.lerp(b, d / len)
			var ty: float = tr.call("_terrain_mesh_y", p.x, p.y)
			var wl := _wl(p.x, p.y, ty)
			print("  d %5.0f (%.0f, %.0f): %+.1f%s" % [d, p.x, p.y, ty,
				"  apa %+.1f" % wl if wl > ty + 0.05 else ""])
			d += step
	get_tree().quit(0)
