extends Node
## Harta de inaltime a pistei Carrara, de sus, cu relief umbrit si curbe de nivel -- pentru a
## ITERA pe geometria terenului fara fereastra (headless).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraHmap.tscn -- \
##       --out=C:/.../hmap.png [--mpp=1.5] [--x0=-400 --x1=480 --y0=-200 --y1=170] [--field]
##
## Coordonate de HARTA (x est, y nord), ca in `tools/gen_carrara_route.py`: Godot gz = -y.
## Implicit citeste SUPRAFATA RANDATA (`_terrain_mesh_y`: grila de 7.9 m + randurile fine);
## cu `--field` citeste campul `ground_y` al samplerului (adevarul inainte de grila).
## Culoare = cota (hipsometric), alb = drumul, gri = curbe de nivel la fiecare 5 m.

func _arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.trim_prefix("--%s=" % name)
	return fallback


func _has(name: String) -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "--%s" % name:
			return true
	return false


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(_arg("scene", "res://scenes/tracks/Track23.tscn")) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for _i in 6:
		await get_tree().process_frame
	var smp := _arg("sample", "")
	if smp != "":
		var sp: Variant = track.get("_sampler")
		for pair in smp.split(";"):
			var xy := pair.split(",")
			var sx := float(xy[0])
			var sz := -float(xy[1])
			print("  y=%.1f,%.1f: campul %.2f  mesh %.2f" % [sx, -sz,
				(sp as TrackSideSampler).ground_y(sx, sz), track._terrain_mesh_y(sx, sz)])
	var out := _arg("out", "res://hmap.png")
	var mpp := float(_arg("mpp", "1.5"))
	var x0 := float(_arg("x0", "-400"))
	var x1 := float(_arg("x1", "480"))
	var y0 := float(_arg("y0", "-200"))
	var y1 := float(_arg("y1", "170"))
	var use_field := _has("field")
	var w := int((x1 - x0) / mpp)
	var h := int((y1 - y0) / mpp)
	var sampler: TrackSideSampler = track.get("_sampler")
	var hts := PackedFloat32Array()
	hts.resize(w * h)
	for j in h:
		for i in w:
			var x := x0 + (float(i) + 0.5) * mpp
			var y := y1 - (float(j) + 0.5) * mpp
			var z := -y
			hts[j * w + i] = sampler.ground_y(x, z) if use_field else track._terrain_mesh_y(x, z)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var sun := Vector3(-0.6, 0.55, 0.58).normalized()
	for j in h:
		for i in w:
			var c := hts[j * w + i]
			var l := hts[j * w + maxi(i - 1, 0)]
			var r := hts[j * w + mini(i + 1, w - 1)]
			var up := hts[maxi(j - 1, 0) * w + i]
			var dn := hts[mini(j + 1, h - 1) * w + i]
			var n := Vector3((l - r) / (2.0 * mpp), 1.0, (dn - up) / (2.0 * mpp)).normalized()
			# n.z: j creste spre sud (y scade) => z lume creste cu j; (dn-up) e dy/dj.
			var shade := clampf(n.dot(sun), 0.0, 1.0) * 0.55 + 0.45
			var t := clampf((c + 5.0) / 55.0, 0.0, 1.0)
			var col := Color(0.35 + 0.55 * t, 0.55 + 0.30 * t, 0.30 + 0.45 * t)
			if c < 5.0:
				col = Color(0.30, 0.55, 0.62).lerp(Color(0.55, 0.75, 0.55), c / 5.0)
			col = col * shade
			# curbe de nivel la 5 m
			var cl := floorf(c / 5.0)
			var is_edge := floorf(l / 5.0) != cl or floorf(r / 5.0) != cl \
				or floorf(up / 5.0) != cl or floorf(dn / 5.0) != cl
			if is_edge:
				col = col.lerp(Color(0.1, 0.1, 0.1), 0.35)
			img.set_pixel(i, j, Color(col.r, col.g, col.b))
	# Drumul
	var route := track.routes[0]
	var n_pts: int = route.count()
	for k in n_pts:
		var p: Vector3 = route.baked[k]
		var px := int((p.x - x0) / mpp)
		var pj := int((y1 - (-p.z)) / mpp)
		for dj in range(-1, 2):
			for di in range(-1, 2):
				var ii := px + di
				var jj := pj + dj
				if ii >= 0 and ii < w and jj >= 0 and jj < h:
					img.set_pixel(ii, jj, Color(1, 1, 1))
	img.save_png(out)
	print("hmap: %dx%d @ %.2f m/px -> %s (%s)" % [w, h, mpp, out, "camp" if use_field else "mesh"])
	get_tree().quit()
