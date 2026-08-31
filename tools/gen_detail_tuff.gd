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
			# CANELURILE MARI, mai putin adanci decat inainte (-0.46 -> -0.30).
			# Ele dau caracterul de siroire, dar cand erau semnalul dominant si
			# se ridica contrastul, conul iesea cu dungi late de zebra: opt benzi
			# pe toata dala, amplificate, arata a blana pictata, nu a piatra.
			var flute := smoothstep(-0.40, 0.40,
				sin(fx * TAU * 7.0 + meander)) * -0.30
			var fine := smoothstep(-0.6, 0.6,
				sin(fx * TAU * 17.0 + meander * 1.6)) * -0.13
			# SIROIREA FINA (runda 14). Motivul, masurat: referinta are pe latimea
			# unui con din prim-plan ~90 de tranzitii de valoare, adica structuri
			# de ~1.8 px; dala veche avea opt caneluri late si nimic intre ele, si
			# orice incercare de a scoate muchii din ea nu facea decat sa ingroase
			# alea opt dungi. Detaliul fin nu se poate inventa din amplificare —
			# trebuie sa EXISTE in textura.
			#
			# Se adauga doua familii de santuri subtiri, la frecvente
			# neproportionale (37 si 61 de cicluri, numere prime intre ele si fata
			# de cele 7 si 17 de mai sus), fiecare cu meandrul ei: asa nu se
			# aliniaza niciodata intr-o grila, care ar fi citit a tesatura. Fiecare
			# familie e modulata pe verticala, deci santurile se sting si reapar pe
			# inaltime, cum face siroirea reala, in loc sa curga continuu de sus
			# pana jos.
			var rill_a := smoothstep(0.55, 1.0,
				sin(fx * TAU * 37.0 + meander * 2.4 + sin(fy * TAU * 5.0) * 0.9))
			var rill_b := smoothstep(0.62, 1.0,
				sin(fx * TAU * 61.0 - meander * 1.7 + sin(fy * TAU * 8.0) * 1.3))
			var rill_fade := 0.55 + 0.45 * sin(fy * TAU * 2.7 + 1.1)
			var rill := -(rill_a * 0.26 + rill_b * 0.19) * rill_fade
			var depth := 1.0 - 0.40 * fy
			var macro := sin(float(x) * 0.019) * cos(float(y) * 0.023) * 0.10
			var ledge := -0.22 * pow(maxf(0.0,
				sin(fy * TAU * 2.0 + sin(fx * TAU * 1.7) * 1.2)), 40.0)
			# Granulatia, mai fina si mai deasa: e ce umple spatiul dintre santuri
			# cu variatie la scara de pixel, adica exact scara pe care referinta o
			# are si noi nu o aveam.
			var grain := -rng.randf() * 0.38
			return (flute + fine + rill) * depth + macro + ledge + grain + 0.415)


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
