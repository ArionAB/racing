class_name RangoliDecal
extends Decal
## Rangoli pictat pe caldaram (Jodhpur, POI A — startul sub Ghanta Ghar;
## brief §4 / §5.1: „decal `rangoli` (start)", **decal, nu textura pe drum**).
##
## Textura se DESENEAZA in cod, o data, din sloturile paletei cerute de brief
## (CAR_RED 14, FLAMINGO_PINK 31, CAR_YELLOW 16, TROPICAL_GREEN 21,
## FOAM_WHITE 22, plus LAVA_ORANGE 30 ca accent de galbenele): niciun fisier de
## textura nou in repo si nicio culoare din afara atlasului. Un decal nu e un
## material, deci garda de materiale nu se misca.
##
## Modelul: mandala concentrica — petale in coroana, inele de puncte, lotus cu
## opt petale, stea alba in centru. Pulberea colorata acopera aproape tot
## discul; printre petale se vede caldaramul (alpha 0), ca la un rangoli real.
##
## Proiectia e de sus in jos (-Y local); `normal_fade` o tine doar pe fetele
## orizontale (nu pe flancurile masinilor care trec prin cutie), iar cutia e
## joasa (`size.y`), deci caroseria de deasupra nu se picteaza.

## Rezolutia texturii (patrat). 256 la 11 m = ~4 cm/texel: mai fin decat vede
## camera de joc la 10 m sus.
@export var resolution: int = 256
## Varianta de model (numarul de petale din coroana, rotirea inelelor):
## doua decaluri alaturate nu trebuie sa fie identice.
@export var variant: int = 0

static var _cache: Dictionary = {}


func _ready() -> void:
	texture_albedo = _texture(resolution, variant)
	normal_fade = 0.5
	upper_fade = 0.15
	lower_fade = 0.15
	albedo_mix = 1.0


static func _texture(res: int, v: int) -> ImageTexture:
	var key := "%d_%d" % [res, v]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(res, res, false, Image.FORMAT_RGBA8)
	var red := Palette.color(Palette.CAR_RED)
	var pink := Palette.color(Palette.FLAMINGO_PINK)
	var yellow := Palette.color(Palette.CAR_YELLOW)
	var green := Palette.color(Palette.TROPICAL_GREEN)
	var white := Palette.color(Palette.FOAM_WHITE)
	var orange := Palette.color(Palette.LAVA_ORANGE)
	var outer_petals := 16 if v % 2 == 0 else 12
	var mid_petals := 8
	var rot := 0.0 if v % 2 == 0 else PI / 12.0
	var half := float(res) * 0.5
	for py in res:
		for px in res:
			# Coordonate normalizate: r in [0, 1] pe raza discului.
			var dx := (float(px) + 0.5 - half) / half
			var dy := (float(py) + 0.5 - half) / half
			var r := sqrt(dx * dx + dy * dy)
			var a := atan2(dy, dx) + rot
			var c := _paint(r, a, outer_petals, mid_petals,
				red, pink, yellow, green, white, orange)
			img.set_pixel(px, py, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Culoarea (cu alpha) la raza r si unghiul a. Straturile, din afara spre
## centru: puncte albe de contur, coroana de petale rosu/roz, inel galben,
## inel de puncte portocalii, lotusul verde cu miez roz, inel alb, steaua
## galbena, centrul rosu.
static func _paint(r: float, a: float, n_out: int, n_mid: int,
		red: Color, pink: Color, yellow: Color, green: Color, white: Color,
		orange: Color) -> Color:
	var clear := Color(0, 0, 0, 0)
	if r > 1.0:
		return clear
	# Contur: puncte albe pe cerc.
	if r > 0.93:
		var sd := _dot(r, a, 0.965, n_out * 2, 0.028)
		return Color(white, 1.0) if sd else clear
	# Coroana de petale: forma de lacrima cu varful in afara.
	if r > 0.62:
		var sector := TAU / float(n_out)
		var t := fposmod(a, sector) / sector - 0.5 # -0.5..0.5 in sector
		var u := (r - 0.62) / 0.31 # 0 la baza, 1 la varf
		var w := 0.48 * sin(PI * clampf(u, 0.0, 1.0) * 0.5 + PI * 0.5) * (1.0 - u * 0.7)
		if absf(t) < w:
			var idx := int(floor(fposmod(a, TAU) / sector))
			var inner := absf(t) < w * 0.45 and u < 0.7
			if idx % 2 == 0:
				return Color(pink if inner else red, 1.0)
			return Color(yellow if inner else orange, 1.0)
		return clear
	# Inel galben plin.
	if r > 0.55:
		return Color(yellow, 1.0)
	# Inel de puncte (portocaliu pe verde).
	if r > 0.47:
		if _dot(r, a, 0.51, n_out * 2, 0.03):
			return Color(white, 1.0)
		return Color(green, 1.0)
	# Lotusul cu opt petale.
	if r > 0.2:
		var sector2 := TAU / float(n_mid)
		var t2 := fposmod(a + sector2 * 0.5, sector2) / sector2 - 0.5
		var u2 := (r - 0.2) / 0.27
		var w2 := 0.5 * (1.0 - u2 * u2)
		if absf(t2) < w2:
			return Color(pink if absf(t2) < w2 * 0.5 else red, 1.0)
		return Color(green, 1.0)
	# Inel alb.
	if r > 0.15:
		return Color(white, 1.0)
	# Steaua galbena pe fond rosu.
	var star := 0.1 + 0.05 * cos(a * 8.0)
	if r < star:
		return Color(yellow, 1.0)
	return Color(red, 1.0)


## Adevarat daca (r, a) cade intr-unul din n puncte rotunde de raza `pr`
## asezate pe cercul de raza `rc`.
static func _dot(r: float, a: float, rc: float, n: int, pr: float) -> bool:
	var sector := TAU / float(n)
	var ac := (floorf(a / sector) + 0.5) * sector
	var cx := rc * cos(ac)
	var cy := rc * sin(ac)
	var x := r * cos(a)
	var y := r * sin(a)
	return (x - cx) * (x - cx) + (y - cy) * (y - cy) < pr * pr
