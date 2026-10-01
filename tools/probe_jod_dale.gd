extends Node
## Media sRGB a dalelor de clasa candidate pentru Jodhpur (fundatia gauntlet-ului)
## si ce tenta/ridicare ar cere fiecare tinta din brief §4. Masuratoare, nu gust:
## CLASS_TINT doar INTUNECA (multiplicator), deci un raport tinta/dala > 1 pe
## vreun canal cere CLASS_LIFT (memoria monocromia-se-masoara-dupa-remap).
##   godot --headless --path . res://tools/ProbeJodDale.tscn
const DALE := ["plaster", "stone_wall", "rock", "alpine_granite", "concrete"]
const TINTE := {
	"blue_lime_light": Color("#8FB0DC"), "blue_lime_indigo": Color("#4F6FB8"),
	"red_sandstone": Color("#A5553A"), "rhyolite": Color("#9A6A5A"),
	"rose_sandstone": Color("#D4957A"),
}

func _ready() -> void:
	for d: String in DALE:
		var m := _mean(load(Palette.CLASS_TEXTURES[d]) as Texture2D)
		print("dala %-15s medie sRGB (%.3f, %.3f, %.3f) luminanta %.3f" % [d, m.r, m.g, m.b, m.get_luminance()])
	var vp := _mean(Palette._class_texture("village_plaster"))
	print("village_plaster RIDICATA (lift 0.88) medie (%.3f, %.3f, %.3f) lum %.3f" % [vp.r, vp.g, vp.b, vp.get_luminance()])
	for cls: String in Palette.CLASS_TEXTURES:
		if TINTE.has(cls):
			var t: Color = TINTE[cls]
			var m2 := _mean(Palette._class_texture(cls))
			var mat := Palette.triplanar_class_material(cls)
			var a := mat.albedo_color
			print("CLASA %-16s dala efectiva (%.3f,%.3f,%.3f) x tenta (%.3f,%.3f,%.3f) = (%.3f,%.3f,%.3f)  tinta (%.3f,%.3f,%.3f)" % [
				cls, m2.r, m2.g, m2.b, a.r, a.g, a.b, m2.r * a.r, m2.g * a.g, m2.b * a.b, t.r, t.g, t.b])
	get_tree().quit()

func _mean(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img == null:
		return Color.BLACK
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGB8)
	var s := Vector3.ZERO
	var n := 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			s += Vector3(c.r, c.g, c.b)
			n += 1
	s /= float(n)
	return Color(s.x, s.y, s.z)
