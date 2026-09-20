extends Node
## Cota axului pe intervalul POI F, si ce adancime ar cere rapa 9 ca podeaua
## declarata (-42) sa se aplice cu adevarat.
##
## `target = maxf(target, floor_y)` in track_side_sampler: podeaua e un PLAFON
## INFERIOR, nu o comanda. Daca rapa sapa doar 14 m sub un drum aflat la -25,
## fundul iese la -39 si podeaua de -42 nu se atinge niciodata.
const TRACK := "res://scenes/tracks/Track15.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6:
		await get_tree().process_frame
	var n := t.baked.size()
	print("frac  | cota ax | adancime ca sa atinga -42")
	var f := 0.66
	while f <= 0.74:
		var i := int(round(f * float(n))) % n
		var y: float = t.baked[i].y
		print("%.3f | %+7.1f | %.1f m" % [f, y, y - (-42.0)])
		f += 0.01
	get_tree().quit(0)
