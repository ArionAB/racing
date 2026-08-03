extends SceneTree
## Proceseaza texturile de CLASA din surse externe (PolyHaven / ComfyUI / orice
## PNG-JPG) in variante gata de joc: 512², gradate spre culorile paletei.
##
## De ce exista pasul asta si nu folosim sursele direct: texturile externe sunt
## fotografii, fiecare cu lumina, saturatia si temperatura ei. Puse netratate
## una langa alta, dau "asset soup" — un colaj in care nimic nu se leaga.
## Gradarea trage fiecare pixel spre ancora lui din paleta pastrand luminanta
## (deci detaliul), asa ca textura devine o EXTENSIE a paletei, nu o culoare
## straina. Sursa se schimba liber (azi PolyHaven, maine ComfyUI pictat) —
## pasul asta ramane.
##
## Rulare:
##   godot --headless --path . --script res://tools/process_class_textures.gd
##
## Iesire: assets/textures/classes/<clasa>.png (512x512), consumate de
## Palette.class_material().

const SRC_DIR := "res://assets/textures/classes/src/"
const OUT_DIR := "res://assets/textures/classes/"
const OUT_SIZE := 512

## Cat de tare se desatureaza sursa inainte de gradare (0..1).
const DESAT := 0.25
## Cat de tare se trage spre ancora de paleta (0..1). 0 = sursa neatinsa,
## 1 = doar luminanta sursei colorata integral in ancora.
const GRADE := 0.45

## Clasele pilotului: sursa -> ancora de paleta.
## Ancorele NU sunt decorative: ele garanteaza ca olanele raman in familia
## TILE_TERRACOTTA din style_bible §1, tencuiala in CONCRETE etc.
static func classes() -> Dictionary:
	return {
		"roof_tiles": {"src": "roof_tiles_src.jpg",
			"anchor": Palette.color(Palette.TILE_TERRACOTTA)},
		"plaster": {"src": "plaster_src.jpg",
			"anchor": Palette.color(Palette.CONCRETE)},
		"stone_wall": {"src": "stone_wall_src.jpg",
			"anchor": Palette.color(Palette.CORAL_SAND)},
		# Familia de roca a Dunelor (faleze/butte/arcada/bolovani): inlocuieste
		# continutul procedural al trim-ului, prin acelasi rock_material
		# triplanar — conversia intregului canion fara niciun re-export.
		# Gain-ul intinde contrastul: fotografia originala e plata fata de
		# trim-ul pictat, iar la distanta (mipmap) se topea in noroi — masurat,
		# sigma pe faleza cadea de la 10.3 la 8.4 fara corectie.
		"rock": {"src": "rock_src.jpg",
			"anchor": Palette.color(Palette.ROCK_LIGHT), "gain": 1.35,
			"lift": 0.06},
		# Metal ruginit: turn de apa, excavator, conducta.
		"rust_metal": {"src": "rust_metal_src.jpg",
			"anchor": Palette.color(Palette.RUST_METAL), "gain": 1.15},
	}


func _initialize() -> void:
	var spec := classes()
	for cls: String in spec:
		var src_path: String = SRC_DIR + spec[cls]["src"]
		var img := Image.new()
		var err := img.load(ProjectSettings.globalize_path(src_path))
		if err != OK:
			push_error("Nu am putut citi %s (eroare %d)" % [src_path, err])
			continue
		img.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
		_grade(img, spec[cls]["anchor"], float(spec[cls].get("gain", 1.0)),
			float(spec[cls].get("lift", 0.0)))
		var out: String = OUT_DIR + cls + ".png"
		DirAccess.make_dir_recursive_absolute(OUT_DIR)
		if img.save_png(out) != OK:
			push_error("Nu am putut scrie " + out)
			continue
		print("  %s.png  (%dx%d, ancora %s)"
			% [cls, OUT_SIZE, OUT_SIZE, spec[cls]["anchor"].to_html(false)])
	quit()


## Gradarea unui pixel, in doi pasi:
##  1. desaturare partiala (DESAT) — taie varfurile de culoare ale fotografiei;
##  2. amestec spre "ancora scalata la luminanta pixelului" (GRADE) — nuanta
##     converge spre paleta, dar detaliul (variatia de luminanta) ramane intact.
## `gain` intinde contrastul in jurul mediei de luminanta (1.0 = neatins);
## `lift` ridica uniform luminozitatea DUPA gain. Ambele per clasa: o
## fotografie plata are nevoie de punch ca sa supravietuiasca mipmap-urilor,
## una contrastata nu.
func _grade(img: Image, anchor: Color, gain: float = 1.0,
		lift: float = 0.0) -> void:
	var anchor_lum := anchor.r * 0.2126 + anchor.g * 0.7152 + anchor.b * 0.0722
	# media de luminanta a imaginii — pivotul in jurul caruia se intinde
	var mean := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			mean += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	mean /= float(img.get_width() * img.get_height())
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			c = Color(
				clampf(mean + (c.r - mean) * gain + lift, 0.0, 1.0),
				clampf(mean + (c.g - mean) * gain + lift, 0.0, 1.0),
				clampf(mean + (c.b - mean) * gain + lift, 0.0, 1.0))
			var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			var desat := Color(
				lerpf(c.r, lum, DESAT),
				lerpf(c.g, lum, DESAT),
				lerpf(c.b, lum, DESAT))
			var scale := lum / maxf(anchor_lum, 0.001)
			var target := Color(
				clampf(anchor.r * scale, 0.0, 1.0),
				clampf(anchor.g * scale, 0.0, 1.0),
				clampf(anchor.b * scale, 0.0, 1.0))
			img.set_pixel(x, y, Color(
				lerpf(desat.r, target.r, GRADE),
				lerpf(desat.g, target.g, GRADE),
				lerpf(desat.b, target.b, GRADE)))
