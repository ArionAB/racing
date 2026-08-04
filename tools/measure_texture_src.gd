extends SceneTree
## Cantareste CANDIDATII de textura sursa inainte sa intre in repo.
##
## Regula invatata prin esec (vezi style_bible §4, avertismentul despre
## `weathered_planks`): o sursa NU se alege din miniatura. Gradarea din
## process_class_textures pastreaza luminanta prin constructie, deci o
## fotografie subexpusa ramane subexpusa oricat de bine ar fi gradata, iar un
## dezechilibru de lumina pe dala devine BENZI pe o suprafata care se repeta.
## Ritualul se repeta la fiecare clasa noua; de aia e o unealta, nu un snippet
## rescris de fiecare data.
##
## Rulare:
##   godot --headless --path . --script res://tools/measure_texture_src.gd -- \
##       --dir=<cale absoluta cu .jpg/.png> [--anchor=D4994D] [--tile=8]
##
## Ce citesti in tabel:
##   medie   luminanta 0..255. Se compara cu luminanta ANCOREI (coloana ratie);
##           sub ~0.85 din ancora, asset-ul iese o silueta intunecata in cadru.
##   sigma   deviatia GLOBALA — cat contrast are fotografia in total.
##   in-dala deviatia mediana INAUNTRUL unei dale de `tile` px dupa scalarea la
##           512. Asta e ce se vede la viteza (aceeasi masura ca
##           measure_surface.gd); o fotografie cu energia in frecvente joase
##           poate avea sigma mare si in-dala mic — exact regresia din #132.
##   dez.    dezechilibrul de lumina stanga/dreapta si sus/jos, in procente din
##           medie. Peste ~5% se vad benzi la repetitie.

const OUT_SIZE: int = 512


func _initialize() -> void:
	var dir_path := ""
	var anchor_hex := ""
	var tile := 8
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir_path = arg.trim_prefix("--dir=")
		elif arg.begins_with("--anchor="):
			anchor_hex = arg.trim_prefix("--anchor=")
		elif arg.begins_with("--tile="):
			tile = maxi(2, int(arg.trim_prefix("--tile=")))
	if dir_path.is_empty():
		push_error("lipseste --dir=<cale>")
		quit(1)
		return
	var anchor_lum := -1.0
	if not anchor_hex.is_empty():
		var a := Color.html(anchor_hex)
		anchor_lum = (a.r * 0.2126 + a.g * 0.7152 + a.b * 0.0722) * 255.0

	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("nu pot deschide " + dir_path)
		quit(1)
		return
	var files: Array[String] = []
	for f in dir.get_files():
		if f.get_extension().to_lower() in ["jpg", "jpeg", "png"]:
			files.append(f)
	files.sort()

	print("\n=== CANDIDATI DE TEXTURA: %s (dala %dpx la %d²) ===" \
		% [dir_path, tile, OUT_SIZE])
	if anchor_lum >= 0.0:
		print("ancora %s -> luminanta %.1f" % [anchor_hex, anchor_lum])
	print("%-26s %7s %7s %7s %8s %8s %7s" \
		% ["sursa", "medie", "ratie", "sigma", "in-dala", "dez.x%", "dez.y%"])
	for f in files:
		var img := Image.new()
		if img.load(dir_path.path_join(f)) != OK:
			print("%-26s  NU SE POATE CITI" % f)
			continue
		img.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
		var m := _measure(img, tile)
		var ratio: float = m["mean"] / anchor_lum if anchor_lum > 0.0 else 0.0
		print("%-26s %7.1f %7.2f %7.1f %8.2f %8.1f %7.1f" % [
			f.get_basename(), m["mean"], ratio, m["sigma"], m["tile_sigma"],
			m["dx"], m["dy"]])
	print("")
	quit()


func _measure(img: Image, tile: int) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var lum := PackedFloat32Array()
	lum.resize(w * h)
	var sum := 0.0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var l := (c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722) * 255.0
			lum[y * w + x] = l
			sum += l
	var n := float(w * h)
	var mean := sum / n
	var acc := 0.0
	for v in lum:
		acc += (v - mean) * (v - mean)
	var sigma := sqrt(acc / n)

	# Deviatia INAUNTRUL dalelor — aceeasi masura ca measure_surface.gd.
	var tile_sigmas: Array[float] = []
	for ty in range(0, h - tile + 1, tile):
		for tx in range(0, w - tile + 1, tile):
			var s := 0.0
			var s2 := 0.0
			for y in range(ty, ty + tile):
				for x in range(tx, tx + tile):
					var v := lum[y * w + x]
					s += v
					s2 += v * v
			var cnt := float(tile * tile)
			var mu := s / cnt
			tile_sigmas.append(sqrt(maxf(s2 / cnt - mu * mu, 0.0)))
	tile_sigmas.sort()
	var tile_sigma: float = tile_sigmas[tile_sigmas.size() / 2] \
		if not tile_sigmas.is_empty() else 0.0

	# Dezechilibrul de lumina pe dala, in procente din medie.
	var dx := absf(_half_mean(lum, w, h, true, false)
		- _half_mean(lum, w, h, true, true)) / maxf(mean, 1e-5) * 100.0
	var dy := absf(_half_mean(lum, w, h, false, false)
		- _half_mean(lum, w, h, false, true)) / maxf(mean, 1e-5) * 100.0
	return {"mean": mean, "sigma": sigma, "tile_sigma": tile_sigma,
		"dx": dx, "dy": dy}


## Media unei jumatati: pe orizontala (`horizontal`) sau verticala, prima
## jumatate sau a doua (`second`).
func _half_mean(lum: PackedFloat32Array, w: int, h: int, horizontal: bool,
		second: bool) -> float:
	var x0 := 0
	var x1 := w
	var y0 := 0
	var y1 := h
	if horizontal:
		if second: x0 = w / 2
		else: x1 = w / 2
	else:
		if second: y0 = h / 2
		else: y1 = h / 2
	var s := 0.0
	for y in range(y0, y1):
		for x in range(x0, x1):
			s += lum[y * w + x]
	return s / float((x1 - x0) * (y1 - y0))
