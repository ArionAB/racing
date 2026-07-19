extends SceneTree
## Genereaza texturi placeholder seamless in res://assets/textures/.
## Ruleaza cu:
##   godot --headless --path . --script res://tools/generate_textures.gd
## Cand vin texturi reale (pictate/din pachete), doar inlocuiesti PNG-urile.

const SIZE: int = 256

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 777
	DirAccess.make_dir_recursive_absolute("res://assets/textures")
	_asphalt()
	_grass()
	_concrete()
	print("Texturi generate in res://assets/textures/")
	quit()

## Asfalt cu banda discontinua pe centru. Pe sosea U merge de-a latul
## (0..1), deci banda din mijlocul texturii cade pe mijlocul drumului si
## se repeta de-a lungul lui.
func _asphalt() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var v := 0.15 + rng.randf() * 0.05
			img.set_pixel(x, y, Color(v, v, v + 0.015))
	for y in SIZE:
		@warning_ignore("integer_division")
		if (y / 24) % 2 == 0: # dash-uri: 24px pline, 24px pauza
			for x in range(124, 132):
				img.set_pixel(x, y, Color(0.82, 0.82, 0.75))
	img.save_png("res://assets/textures/asphalt.png")
	print("  asphalt.png")

func _grass() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var g := 0.5 + rng.randf() * 0.16
			img.set_pixel(x, y, Color(g * 0.55, g, g * 0.45))
	# smocuri mai inchise, ca sa nu fie zgomot uniform
	for i in 260:
		var cx := rng.randi_range(1, SIZE - 2)
		var cy := rng.randi_range(1, SIZE - 2)
		var shade := rng.randf_range(0.75, 0.9)
		for off in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			var p := img.get_pixel(cx + off.x, cy + off.y)
			img.set_pixel(cx + off.x, cy + off.y, p * shade)
	img.save_png("res://assets/textures/grass.png")
	print("  grass.png")

func _concrete() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var v := 0.4 + rng.randf() * 0.09
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.92))
	img.save_png("res://assets/textures/concrete.png")
	print("  concrete.png")
