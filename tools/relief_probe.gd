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
	if _arg("--horizon") != "":
		for c in _all(tr):
			var nm := String(c.name)
			if c is Node3D and (nm.begins_with("CloudSea") or nm.begins_with("Fagaras")):
				var q := (c as Node3D).global_position
				var bb := AABB()
				for m in c.find_children("*", "MeshInstance3D", true, false):
					var mi := m as MeshInstance3D
					bb = bb.merge(mi.global_transform * mi.get_aabb()) if bb.size != Vector3.ZERO else mi.global_transform * mi.get_aabb()
				print("  %s pos (%.1f, %.1f, %.1f) aabb y %.1f..%.1f x %.0f..%.0f z %.0f..%.0f" % [nm, q.x, q.y, q.z,
					bb.position.y, bb.end.y, bb.position.x, bb.end.x, bb.position.z, bb.end.z])
	if _arg("--nodes") != "":
		for c in tr.get_children():
			var extra := ""
			if c is MeshInstance3D:
				var mi := c as MeshInstance3D
				var bb: AABB = mi.global_transform * mi.get_aabb()
				extra = " aabb x %.0f..%.0f y %.1f..%.1f z %.0f..%.0f" % [bb.position.x, bb.end.x,
					bb.position.y, bb.end.y, bb.position.z, bb.end.z]
			print("  %s [%s]%s" % [c.name, c.get_class(), extra])
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
	var grid := _arg("--grid")
	if grid != "":
		# --grid=x0,z0,x1,z1,pas : tabel de cote absolute (rand = z in rand, x in antet);
		# `w` = apa, `R` = pe sosea (la <= 8 m de un punct copt)
		var g := grid.split(",")
		var gx0 := float(g[0])
		var gz0 := float(g[1])
		var gx1 := float(g[2])
		var gz1 := float(g[3])
		var gst := float(g[4])
		var hdr := "        z per x "
		var xx := gx0
		while xx <= gx1 + 0.01:
			hdr += "%6.0f" % xx
			xx += gst
		print(hdr)
		var zz := gz0
		while zz <= gz1 + 0.01:
			var out := "  %7.0f " % zz
			xx = gx0
			while xx <= gx1 + 0.01:
				var ty: float = tr.call("_terrain_mesh_y", xx, zz)
				var tag := " "
				if _wl(xx, zz, ty) > ty + 0.05:
					tag = "w"
				var ci := _closest(Vector3(xx, 0, zz))
				if Vector2(tr.baked[ci].x - xx, tr.baked[ci].z - zz).length() <= 8.0:
					tag = "R"
				out += "%5.0f%s" % [ty, tag]
				xx += gst
			print(out)
			zz += gst
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
