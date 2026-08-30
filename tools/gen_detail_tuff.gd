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
			var flute := smoothstep(-0.40, 0.40,
				sin(fx * TAU * 7.0 + meander)) * -0.46
			var fine := smoothstep(-0.6, 0.6,
				sin(fx * TAU * 17.0 + meander * 1.6)) * -0.15
			var depth := 1.0 - 0.40 * fy
			var macro := sin(float(x) * 0.019) * cos(float(y) * 0.023) * 0.10
			var ledge := -0.22 * pow(maxf(0.0,
				sin(fy * TAU * 2.0 + sin(fx * TAU * 1.7) * 1.2)), 40.0)
			var grain := -rng.randf() * 0.24
			return (flute + fine) * depth + macro + ledge + grain + 0.415)


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
