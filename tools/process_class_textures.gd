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
## Al doilea mod, GRI (vezi `surfaces()`): pentru texturile MULTIPLICATIVE ale
## suprafetelor mari (teren, sosea). Alea nu aduc culoare deloc — se inmultesc
## peste albedo — deci nu se gradeaza spre o ancora, ci se desatureaza complet
## si li se normalizeaza media SI deviatia la cele ale texturilor procedurale pe
## care le inlocuiesc. Asa se schimba TIPARUL fara sa se miste expunerea.
##
## Rulare:
##   godot --headless --path . --script res://tools/process_class_textures.gd
##
## Iesire: assets/textures/classes/<clasa>.png (512x512), consumate de
## Palette.class_material(), plus assets/textures/surface_*.png.

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
		# Lemn imbatranit: turnul morii, grinzile portalului de mina, lazile.
		# Sursa: planks_brown_10 (PolyHaven CC0), ALEASA PRIN MASURATOARE dintre
		# cinci candidati, pe doua criterii care s-au dovedit amandoua decisive:
		#
		#   1. media aproape de luminanta ANCOREI (102.9 fata de 97.5). Prima
		#      incercare (weathered_planks) avea media 69 — cu 30% sub ancora —
		#      si turnul morii a iesit o silueta neagra in cadru. Gradarea
		#      pastreaza luminanta sursei prin constructie, deci o fotografie
		#      subexpusa ramane subexpusa oricat de bine ar fi gradata.
		#   2. lumina UNIFORMA pe dala. weathered_planks avea jumatatea dreapta
		#      vizibil mai inchisa decat stanga; pe o suprafata care se repeta,
		#      dezechilibrul ala devine benzi. Masurat aici: 0.4 diferenta
		#      stanga/dreapta.
		#
		# Fara gain: sursa are deja sigma 23.7, cea mai contrastata din toate
		# clasele. Ce lipsea nu era punch, era expunerea.
		"wood": {"src": "wood_src.jpg",
			"anchor": Palette.color(Palette.WOOD_WEATHERED)},
		# Beton de exterior: dala benzinariei, insula pompelor, cosul.
		# Sursa: concrete_floor_02 (PolyHaven CC0).
		#
		# `lift` mare, si e cazul in care parametrul chiar isi merita existenta:
		# ancora CONCRETE (#C8BDA9) are luminanta 190, iar NICIO fotografie de
		# beton nu trece de ~111 — betonul real e gri mediu, slotul din paleta e
		# ales deschis fiindca tine si coamele albe ale casei de sat, si fata
		# ecranului de drive-in. Fara ridicare, dala ar cobori la 0.58 din
		# ancora, cel mai intunecat raport din toate clasele, si s-ar apropia
		# periculos de asfalt — care trebuie sa ramana cea mai inchisa suprafata
		# continua (style_bible §1).
		#
		# Dezechilibrul de lumina al sursei e 5.2 pe o medie de 110 (4.7%), cel
		# mai prost din clasele de azi. Acceptat deliberat: alternativele erau
		# uniforme dar plate (sigma 6-9), iar petele si crapaturile sunt exact
		# detaliul pentru care exista clasa.
		"concrete": {"src": "concrete_src.jpg",
			"anchor": Palette.color(Palette.CONCRETE), "lift": 0.20},
	}


## Texturile GRI, multiplicative, ale suprafetelor mari.
##
## `mean` e MASURAT pe texturile procedurale pe care le inlocuiesc (surface_sand
## 0.838, surface_asphalt 0.865) si reimpus aici. Nu e pedanterie: media
## texturii e o piesa din calibrarea de expunere (style_bible §14), si e
## aplicata de DOUA ori — o data pe UV1 si o data pe UV2, ca strat de detaliu —
## deci contributia ei la luminozitatea terenului e media la patrat. O sursa cu
## alta medie ar muta expunerea intregii lumi in tacere.
##
## DOUA componente, si asta e lectia masurata a issue-ului. Prima incercare a
## folosit doar fotografia, cu media SI deviatia globala normalizate la cele ale
## texturii procedurale — pe hartie o inlocuire neutra. Masurat pe poza de
## sofer, a iesit o REGRESIE: asfaltul a cazut de la sigma 2.91 la 1.69, nisipul
## de la 2.77 la 2.37. Explicatia e ca sonda din §14 masoara deviatia INAUNTRUL
## unei dale de 8 px, iar energia unei fotografii sta la frecvente JOASE — pete
## si gradiente late. Deviatia globala era aceeasi, dar mutata acolo unde nu se
## vede la viteza. Textura procedurala era aproape numai zgomot per pixel.
##
##   `sigma` — cata structura de FOTOGRAFIE (pete, crapaturi, urme de reparatii).
##             Asta aduce sursa externa si asta nu putea da o sinusoida.
##   `grain` — amplitudinea zgomotului alb, la scara de BLOC de 4 texeli, adica
##             exact rezolutia texturii procedurale de 128 pe care o inlocuieste.
##             La 512 fara blocuri, granula ar cadea la 6 mm in lume si ar fi
##             mancata de mipmap inainte sa ajunga pe ecran.
##
## Sursele sunt AERIENE deliberat: la o repetitie de 3.1 m, un prim-plan de
## nisip ar mari granula de trei ori si ar citi ca pietris.
const GRAIN_BLOCK := 4

static func surfaces() -> Dictionary:
	return {
		# grain 0.20 = exact amplitudinea uniforma a texturii procedurale
		# (deviatie 0.20/sqrt(12) = 0.058), sigma 0.045 = structura adaugata.
		#
		# `mean` 0.838 -> 0.850, si NU e un numar rotunjit: la 0.838 (media
		# exacta a texturii procedurale) nisipul randat a iesit cu 3% mai
		# intunecat, adica eroare 14/255 pe rosu fata de #D4994D, peste pragul
		# de 12 din style_bible §14. Cauza e ca a doua trecere (UV2, o repetitie
		# la 45 m) acopera cam cat tot cadrul, deci contributia ei nu mai e
		# media texturii, ci media BUCATII de fotografie care nimereste acolo.
		# Cu 0.850, nisipul randat revine la 203,156,87 — identic cu inainte.
		"surface_sand": {"src": "surface_sand_src.jpg",
			"mean": 0.850, "sigma": 0.045, "grain": 0.20},
		"surface_asphalt": {"src": "surface_asphalt_src.jpg",
			"mean": 0.865, "sigma": 0.050, "grain": 0.26},
	}


func _initialize() -> void:
	_do_surfaces()
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


const SURFACE_DIR := "res://assets/textures/"

func _do_surfaces() -> void:
	for name: String in surfaces():
		var cfg: Dictionary = surfaces()[name]
		var src_path: String = SRC_DIR + cfg["src"]
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(src_path)) != OK:
			push_error("Nu am putut citi " + src_path)
			continue
		img.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
		var got := _to_grayscale(img, float(cfg["mean"]), float(cfg["sigma"]),
			float(cfg["grain"]))
		var out: String = SURFACE_DIR + name + ".png"
		if img.save_png(out) != OK:
			push_error("Nu am putut scrie " + out)
			continue
		print("  %s.png  (%dx%d, gri, medie %.4f sigma %.4f — tinta %.3f/%.3f)"
			% [name, OUT_SIZE, OUT_SIZE, got.x, got.y, cfg["mean"], cfg["sigma"]])


## Zgomot determinist din POZITIE, nu dintr-un flux de rng — aceeasi regula ca
## in generate_palette_atlas._hash01, si din acelasi motiv: un artefact nu are
## voie sa se schimbe fiindca altul de langa el a consumat extrageri.
func _hash01(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393) ^ (y * 668265263) ^ (salt * 2147483647)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFFFF) / float(0x1000000)


## Desaturare completa + remapare liniara la (mean, sigma) + granulatie pe
## blocuri. Intoarce media si deviatia REALE de dupa clamp, ca sa se vada cat
## s-a pierdut la margini.
func _to_grayscale(img: Image, mean_t: float, sigma_t: float,
		grain: float) -> Vector2:
	var w := img.get_width()
	var h := img.get_height()
	var n := float(w * h)
	var vals := PackedFloat32Array()
	vals.resize(w * h)
	var sum := 0.0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			vals[y * w + x] = l
			sum += l
	var mean_src := sum / n
	var var_src := 0.0
	for v in vals:
		var_src += (v - mean_src) * (v - mean_src)
	var sd_src := sqrt(var_src / n)
	var k := sigma_t / maxf(sd_src, 1e-5)
	var got_sum := 0.0
	var got_sq := 0.0
	for y in h:
		for x in w:
			# Granulatia se scade, nu se aduna: textura moduleaza in JOS peste
			# albedo (centrul e alb), la fel ca varianta procedurala. Media
			# tintita se corecteaza cu jumatatea amplitudinii, ca adaugarea
			# granulatiei sa nu intunece suprafata — adica sa nu clatine
			# expunerea, care e tot rostul normalizarii.
			var g := _hash01(x / GRAIN_BLOCK, y / GRAIN_BLOCK, 1) * grain
			var v: float = clampf(
				mean_t + grain * 0.5 - g + (vals[y * w + x] - mean_src) * k,
				0.0, 1.0)
			got_sum += v
			got_sq += v * v
			img.set_pixel(x, y, Color(v, v, v))
	var got_mean := got_sum / n
	return Vector2(got_mean, sqrt(maxf(got_sq / n - got_mean * got_mean, 0.0)))


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
