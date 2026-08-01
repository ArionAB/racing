extends SceneTree
## Genereaza assets/textures/palette_atlas.png — UNICA textura a lumii.
##
##   godot --headless --path . --script res://tools/generate_palette_atlas.gd
##
## Atlasul are 32 de sloturi pe orizontala. Pana acum fiecare slot era un patrat
## de culoare UNIFORMA (atlas de 32x1 px, 288 bytes). Arata curat in editor, dar
## la viteza o suprafata de sute de m² fara nicio variatie citeste ca plastic —
## asta e diferenta principala fata de Reckless Racing 3 / Beach Buggy Racing,
## nu poligonajul.
##
## Acum fiecare slot e un PATCH TEXTURAT de 16x512 px: nisip cu granulatie, roca
## cu straturi orizontale, asfalt uzat, lemn cu fibra. Costa ~0.5 MB VRAM si
## ZERO draw call-uri in plus — materialul ramane unul singur.
##
## UV-urile existente functioneaza NESCHIMBATE: Palette.uv(slot) intoarce centrul
## slotului, care acum nimereste centrul unui patch texturat in loc de centrul
## unui patrat plat. Cele 5 props hero din Blender nu se refac.
##
## Sursa de adevar pentru culori e Palette.HEX — nu se dubleaza aici.

## Latimea unui slot in pixeli. 32 sloturi x 16 px = 512.
const SLOT_W: int = 16
## Inaltimea atlasului. Verticala e "de-a lungul" texturii: acolo intra
## straturile de roca si fibra lemnului.
const HEIGHT: int = 512
## Cati pixeli de la fiecare margine raman NEATINSI de variatie.
##
## Cu filtrare liniara si mipmap-uri, doi pixeli vecini din sloturi diferite se
## amesteca — nisipul ar capata tenta de asfalt. Marginile pastreaza culoarea
## curata a slotului, deci chiar daca filtrarea "trage" din vecin, trage dintr-o
## zona care arata corect.
const PAD: int = 2

const OUT_PATH: String = "res://assets/textures/palette_atlas.png"

var rng := RandomNumberGenerator.new()


func _init() -> void:
	# Seed fix: acelasi atlas la fiecare rulare. Altfel fiecare regenerare ar
	# produce un PNG diferit binar si ar murdari git-ul fara motiv.
	rng.seed = 20260801
	var img := Image.create(SLOT_W * Palette.SLOTS, HEIGHT, true,
		Image.FORMAT_RGB8)
	for slot in Palette.SLOTS:
		_fill_slot(img, slot)
	DirAccess.make_dir_recursive_absolute("res://assets/textures")
	var err := img.save_png(OUT_PATH)
	if err != OK:
		push_error("Nu am putut scrie %s (eroare %d)" % [OUT_PATH, err])
		quit(1)
		return
	print("Atlas scris: %s  (%dx%d, %d sloturi)"
		% [OUT_PATH, img.get_width(), img.get_height(), Palette.SLOTS])
	_surface_textures()
	print("Reimporta in Godot, apoi verifica bleeding-ul cu:")
	print("  godot --path . res://tools/Snapshot.tscn -- --track=0 --size=40")
	quit()


## Texturi TILEABILE pentru suprafetele mari (teren, asfalt).
##
## Atlasul rezolva prop-urile, dar nu si terenul: o suprafata de sute de m² care
## esantioneaza un singur punct din atlas ramane o pata plata, oricat de texturat
## ar fi punctul ala. Suprafetele mari au nevoie de tiling real.
##
## Sunt gri-scale si se inmultesc peste albedo-ul din _flat_material, deci NU
## aduc culori noi si nu strica paleta — doar rup uniformitatea. Un singur
## material per suprafata, deci zero draw call-uri in plus.
func _surface_textures() -> void:
	# Deviatiile sunt NEGATIVE (centrul e alb, vezi _write_tileable): textura
	# adauga umbra, nu lumina. Amplitudini mici — la 60 km/h o variatie mai mare
	# devine zgomot vizual si strica citirea liniei de curs.
	_write_tileable("res://assets/textures/surface_sand.png",
		func(x: int, y: int) -> float:
			# granulatie fina + dune foarte lente
			var grain := -rng.randf() * 0.09
			var dune := (sin(float(x) * 0.049
				+ sin(float(y) * 0.024) * 2.0) - 1.0) * 0.035
			return grain + dune)
	_write_tileable("res://assets/textures/surface_asphalt.png",
		func(x: int, y: int) -> float:
			# pietris: granulatie grosiera, cu pietre rare mai inchise
			var grain := -rng.randf() * 0.13
			if rng.randf() < 0.01:
				grain -= 0.12
			return grain)


## Scrie o textura gri de 128x128 in care `noise` da deviatia fata de ALB.
##
## Centrul e 1.0, nu 0.5: textura se INMULTESTE peste albedo, deci un gri mediu
## ar intuneca totul cu 50% si ar spala culoarea (nisipul cald #D8A86A ar vira
## spre gri-maroniu). Cu centrul in alb, textura doar moduleaza — culoarea din
## paleta ramane cea din style_bible.
func _write_tileable(path: String, noise: Callable) -> void:
	const N := 128
	var img := Image.create(N, N, true, Image.FORMAT_RGB8)
	for y in N:
		for x in N:
			var v := clampf(1.0 + float(noise.call(x, y)), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  %s  (%dx%d, gri, tileabila)" % [path.get_file(), N, N])


## Umple un slot cu textura potrivita rolului lui.
func _fill_slot(img: Image, slot: int) -> void:
	var base := _base_color(slot)
	var x0 := slot * SLOT_W
	for y in HEIGHT:
		for x in range(x0, x0 + SLOT_W):
			var local_x := x - x0
			var c := base
			# Marginile raman curate — vezi PAD.
			if local_x >= PAD and local_x < SLOT_W - PAD:
				c = _texture_for(slot, base, local_x, y)
			img.set_pixel(x, y, c)


## Culoarea de baza a slotului. Sloturile fara culoare definita (17..31, rezerva)
## raman magenta, ca o greseala de UV sa sara in ochi imediat.
func _base_color(slot: int) -> Color:
	if slot < Palette.HEX.size():
		return Palette.color(slot)
	return Color(1.0, 0.0, 1.0)


## Textura per rol. Amplitudinile sunt mici intentionat (±4-8%): scopul e sa
## rupa suprafata plata, nu sa atraga atentia. La 60 km/h, o variatie mai mare
## devine zgomot vizual si strica citirea liniei de curs.
func _texture_for(slot: int, base: Color, x: int, y: int) -> Color:
	match slot:
		Palette.SAND_LIGHT, Palette.SAND_MID, Palette.SAND_SHADOW:
			return _sand(base, x, y)
		Palette.ROCK_LIGHT, Palette.ROCK_DARK:
			return _rock(base, x, y)
		Palette.ASPHALT, Palette.ASPHALT_EDGE:
			return _asphalt(base, x, y)
		Palette.CONCRETE:
			return _concrete(base, x, y)
		Palette.WOOD_WEATHERED:
			return _wood(base, x, y)
		Palette.RUST_METAL:
			return _rust(base, x, y)
		Palette.PAINTED_METAL:
			return _painted(base, x, y)
		Palette.CACTUS_GREEN, Palette.DRY_VEGETATION:
			return _vegetation(base, x, y)
		_:
			# Accentele de masina (14-16) raman plate: masinile trebuie sa fie
			# cele mai saturate si mai curate suprafete din cadru (style_bible §1).
			return base


## Nisip: granulatie fina, cu valuri foarte lente peste ea. Fara granulatie,
## dunele arata ca plastic turnat.
func _sand(base: Color, x: int, y: int) -> Color:
	var grain := (rng.randf() - 0.5) * 0.08
	var ripple := sin(float(y) * 0.09 + float(x) * 0.4) * 0.022
	return _shade(base, grain + ripple)


## Roca: straturi ORIZONTALE (style_bible §3 — stanca sedimentara, niciodata
## zimtata), cu granulatie peste. Straturile sunt semnatura falezelor de canion.
func _rock(base: Color, x: int, y: int) -> Color:
	# Grosime neregulata de strat: doua sinusuri necomensurabile, ca sa nu se
	# vada perioada.
	var strata := sin(float(y) * 0.075) * 0.5 + sin(float(y) * 0.031) * 0.5
	var band := smoothstep(-0.25, 0.25, strata) * 0.09 - 0.045
	var grain := (rng.randf() - 0.5) * 0.05
	# Crapaturi rare, orizontale.
	var crack := 0.0
	if fposmod(float(y) * 0.075, TAU) < 0.16:
		crack = -0.07
	return _shade(base, band + grain + crack)


## Asfalt: granulatie grosiera. Ramane cea mai INCHISA suprafata continua din
## scena (style_bible §1), deci variatia trage mai mult in jos decat in sus.
func _asphalt(base: Color, x: int, y: int) -> Color:
	var grain := (rng.randf() - 0.62) * 0.10
	# pete rare de uzura, mai deschise
	if rng.randf() < 0.012:
		grain += 0.06
	return _shade(base, grain)


func _concrete(base: Color, x: int, y: int) -> Color:
	var grain := (rng.randf() - 0.5) * 0.05
	var mottle := sin(float(y) * 0.05 + float(x) * 0.7) * 0.018
	return _shade(base, grain + mottle)


## Lemn: fibra VERTICALA (de-a lungul scandurii), cu noduri rare.
func _wood(base: Color, x: int, y: int) -> Color:
	var fiber := sin(float(x) * 2.1 + sin(float(y) * 0.02) * 1.5) * 0.035
	var grain := (rng.randf() - 0.5) * 0.03
	return _shade(base, fiber + grain)


## Metal ruginit: pete neregulate, mai inchise jos (apa se scurge in jos).
func _rust(base: Color, x: int, y: int) -> Color:
	var blotch := sin(float(y) * 0.041 + float(x) * 0.9) \
		* cos(float(y) * 0.017) * 0.06
	var grain := (rng.randf() - 0.5) * 0.05
	var vertical := (float(y) / float(HEIGHT) - 0.5) * -0.04
	return _shade(base, blotch + grain + vertical)


## Metal vopsit: aproape curat, doar o urma de decolorare. E singura suprafata
## de decor care are voie sa arate ingrijita.
func _painted(base: Color, x: int, y: int) -> Color:
	var streak := sin(float(x) * 1.3) * 0.012
	return _shade(base, streak + (rng.randf() - 0.5) * 0.02)


## Vegetatie: pestrita, cu jumatatea de jos mai inchisa (style_bible §4).
func _vegetation(base: Color, x: int, y: int) -> Color:
	var speckle := (rng.randf() - 0.5) * 0.09
	var vertical := (float(y) / float(HEIGHT) - 0.5) * -0.06
	return _shade(base, speckle + vertical)


## Aplica o deviatie de luminozitate pastrand nuanta. Lucreaza in HSV ca sa nu
## se "spele" culoarea la valori mari, cum s-ar intampla adunand direct in RGB.
func _shade(base: Color, delta: float) -> Color:
	var v := clampf(base.v + delta, 0.0, 1.0)
	return Color.from_hsv(base.h, base.s, v, 1.0)
