extends SceneTree
## Regenereaza DOAR assets/textures/detail_tuff.png (canelurile verticale).
##
##   godot --headless --path . --script res://tools/gen_detail_tuff.gd
##
## Exista separat fiindca generate_palette_atlas.gd rescrie si atlasul, si
## trim-ul, si decalurile — artefacte pe care sunt calibrate cifrele din
## style_bible §14. Pentru o textura noua nu se repune in joc toata calibrarea.
## Semanta cu ACELASI SEED_DETAIL, ca rezultatul sa fie reproductibil identic
## cu al rularii complete.

const SEED_DETAIL: int = 20260803

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED_DETAIL
	_detail_tuff()
	quit()


func _detail_tuff() -> void:
	_write_tileable_n("res://assets/textures/detail_tuff.png", 256,
		func(x: int, y: int) -> float:
			var fx := float(x) / 256.0
			var fy := float(y) / 256.0
			var meander := sin(fy * TAU * 1.3) * 0.55 + sin(fy * TAU * 3.1) * 0.18
			# TUFUL E PIATRA PALIDA. Runda 15, si asta e regula care rescrie
			# functia — masurat pe referinta, nu ales din gust: mediana de
			# luminanta 144 din 255, saturatie 0.46, si doar 5.7% din pixeli sub
			# 70. La noi erau 106 / 0.66 / 24.8%.
			#
			# Dala rundei 14 avea 53.7% texeli la ALB PUR si o coada subtire de
			# santuri pana la 36 din 255. Asta nu e o suprafata de piatra, e un
			# desen sparse cu contrast mare: inmultita cu castigul de 2.8 din
			# shader, coada aia ajungea la -321 (deci clamp pe negru, 2% din
			# texeli) iar percentila 5 cadea de la 172 la 59. Alea erau dungile
			# de funingine. Restul dalei, fiind alb plat, nu contribuia nimic.
			#
			# Deci se inverseaza compozitia: in loc de plat-cu-santuri-negre, o
			# modulatie DEASA si PUTIN ADANCA in jurul unei valori palide. Toate
			# amplitudinile de mai jos sunt acum in zecimi, nu in jumatati.
			var flute := smoothstep(-0.40, 0.40,
				sin(fx * TAU * 7.0 + meander)) * -0.085
			var fine := smoothstep(-0.6, 0.6,
				sin(fx * TAU * 17.0 + meander * 1.6)) * -0.045
			# Rilele fine RAMAN — ele dau tranzitiile pe care le cere sonda, si
			# masurat pe referinta platourile au mediana de 3 px, deci structura
			# fina chiar exista acolo. Ce se schimba e ADANCIMEA lor: 0.26/0.19
			# -> 0.055/0.040. Un sant de tuf e crem mai inchis, nu o crestatura
			# neagra; saltul de pe muchie il face lumina, nu pigmentul.
			var rill_a := smoothstep(0.55, 1.0,
				sin(fx * TAU * 37.0 + meander * 2.4 + sin(fy * TAU * 5.0) * 0.9))
			var rill_b := smoothstep(0.62, 1.0,
				sin(fx * TAU * 61.0 - meander * 1.7 + sin(fy * TAU * 8.0) * 1.3))
			var rill_fade := 0.55 + 0.45 * sin(fy * TAU * 2.7 + 1.1)
			var rill := -(rill_a * 0.055 + rill_b * 0.040) * rill_fade
			var depth := 1.0 - 0.40 * fy
			var macro := sin(float(x) * 0.019) * cos(float(y) * 0.023) * 0.035
			var ledge := -0.065 * pow(maxf(0.0,
				sin(fy * TAU * 2.0 + sin(fx * TAU * 1.7) * 1.2)), 40.0)
			# Granulatia e acum SIMETRICA in jurul lui zero, nu doar negativa.
			# Inainte `-rng.randf() * 0.38` nu putea decat sa INTUNECE, deci
			# muta media in jos si adauga o coada intr-un singur sens. Centrata,
			# aceeasi cantitate de variatie la scara de pixel nu mai schimba
			# expunerea — si ea e ce umple spatiul dintre santuri.
			var grain := (rng.randf() - 0.5) * 0.13
			# Media tintita ~0.90, ca dala sa fie palida si stratul sa modifice
			# putin. Vezi `detail_pivot` din shader: pivotul se REMASOARA dupa
			# fiecare redesenare, altfel cuantizarea e asimetrica.
			return (flute + fine + rill) * depth + macro + ledge + grain - 0.10)


func _write_tileable_n(path: String, n: int, noise: Callable) -> void:
	var img := Image.create(n, n, true, Image.FORMAT_RGB8)
	var lo := 1.0
	var hi := 0.0
	var sum := 0.0
	for y in n:
		for x in n:
			var v := clampf(1.0 + float(noise.call(x, y)), 0.0, 1.0)
			lo = minf(lo, v)
			hi = maxf(hi, v)
			sum += v
			img.set_pixel(x, y, Color(v, v, v))
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  %s  (%dx%d, min %.2f  max %.2f  medie %.2f)"
		% [path.get_file(), n, n, lo, hi, sum / float(n * n)])
