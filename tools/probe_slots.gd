extends Node
## CE CULOARE au de fapt sloturile pe care le foloseste faleza.
##
## Regula platita deja o data pe kitul asta: sloturile au fost alese DUPA NUME
## si SAND_MID/SAND_SHADOW s-au dovedit portocaliu de desert, nu crem de tuf.
## Deci nu se mai crede niciun nume — se citeste pixelul din atlas.
func _ready() -> void:
	var slots := [19, 23, 10, 27, 3, 4, 2]
	var tex := Palette.world_material().albedo_texture
	if tex == null:
		print("fara textura de atlas")
		get_tree().quit(0)
		return
	var img := tex.get_image()
	# Atlasul e comprimat pe GPU; fara decomprimare get_pixel intoarce negru si
	# sonda ar „masura" ca toate sloturile sunt identice.
	if img.is_compressed():
		img.decompress()
	print("atlas %dx%d" % [img.get_width(), img.get_height()])
	print("  slot     hex      H     S     V   verdict")
	for s in slots:
		var uv := Palette.uv(s)
		var x := clampi(int(uv.x * float(img.get_width())), 0, img.get_width() - 1)
		var y := clampi(int(uv.y * float(img.get_height())), 0, img.get_height() - 1)
		var c := img.get_pixel(x, y)
		var verdict := ""
		var hh := c.h * 360.0
		if c.s < 0.30:
			verdict = "PALID (nu citeste ca stanca rosie)"
		elif hh > 32.0:
			verdict = "prea galben/ocru"
		else:
			verdict = "ok, in fereastra rosie"
		print("  %4d   #%s   %5.1f  %.2f  %.2f   %s"
			% [s, c.to_html(false), hh, c.s, c.v, verdict])
	get_tree().quit(0)
