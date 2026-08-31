extends Node
## Cat de departe e cel mai apropiat punct de drum (ORICE tur) fata de niste
## centre candidate de scobitura. Daca distanta < raza + jumatate de banda,
## scobitura ar manca asfaltul.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var cands := [
		Vector2(112, 104), Vector2(140, 112), Vector2(170, 122),
		Vector2(96, 96), Vector2(205, 132), Vector2(150, 150),
		Vector2(120, 78), Vector2(160, 88),
	]
	for c in cands:
		var best := 1e9
		var by := 0.0
		for r in t.routes:
			for p in r.baked:
				var d: float = Vector2(p.x, p.z).distance_to(c)
				if d < best:
					best = d
					by = p.y
		print("centru (%.0f, %.0f): cel mai apropiat drum la %.1f m, cota lui %.1f" % [c.x, c.y, best, by])
	get_tree().quit(0)
