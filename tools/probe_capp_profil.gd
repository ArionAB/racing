extends Node
## Profilul de cota al soselei, ca sa se stie UNDE trece traseul prin dreptul
## stratului rosu de teren (`custom_strata_line` = 43 pe Track13) si unde e pe
## platoul crem. Fara asta nu se poate spune daca un cadru "ar trebui" sa aiba
## rosu in el sau nu.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 5:
		await get_tree().process_frame
	var route: Object = t.route_at(0)
	var pts: PackedVector3Array = route.baked
	var n: int = pts.size()
	print("=== cota soselei pe tur (%d puncte) ===" % n)
	var linie := 43.0
	for k in 20:
		var f := float(k) / 20.0
		var i: int = int(f * float(n)) % n
		var y: float = pts[i].y
		print("  frac %.2f   Y = %6.2f   %s" % [f, y,
			("SUB linia de strat (%.0f)" % linie) if y < linie + 6.0 else ""])
	get_tree().quit()
