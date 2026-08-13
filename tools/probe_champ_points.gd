extends Node
## Punctajul de campionat suporta grila reala, oricat de mare e.
##
## Intrebarea la care raspunde: cate masini incap in tabloul de puncte? Pana la
## grila de 6, `champ_points` era o lista scrisa de mana cu 4 zerouri si
## `CHAMP_POINTS` avea 4 intrari — al cincilea si al saselea participant ar fi
## iesit din tablou la prima cursa terminata. Sonda ruleaza campionatul pe
## sloturi, fara pista si fara masini: verifica exact aritmetica.
##
## Ruleaza CA SCENA (are nevoie de autoload-ul GameState):
##   godot --headless --path . res://tools/ProbeChampPoints.tscn

var _failed: bool = false


func _ready() -> void:
	print("")
	print("=== Puncte de campionat ===")
	print("masini in cursa: ", GameState.ai_count + 1)
	print("barem CHAMP_POINTS: ", GameState.CHAMP_POINTS, " (",
		GameState.CHAMP_POINTS.size(), " pozitii punctate)")

	GameState.champ_active = true
	GameState.champ_round = 0
	GameState.champ_points.clear()
	GameState.champ_points.resize(GameState.ai_count + 1)
	var slots := GameState.ai_count + 1
	_check(GameState.champ_points.size() == slots,
		"tabloul are un slot per masina (%d)" % slots)

	# Trei curse, ca un campionat intreg. Ordinea se roteste, ca sa nu punctam
	# mereu acelasi slot si sa ratam o eroare de indexare pe pozitiile de jos.
	for race in GameState.CHAMP_ROUNDS:
		var order: Array = []
		for i in slots:
			order.append((i + race) % slots)
		GameState.record_results(order)
		print("  cursa %d, ordinea %s -> %s"
			% [race + 1, str(order), str(GameState.champ_points)])

	# Fiecare masina a trecut prin primele CHAMP_ROUNDS pozitii, deci totalul
	# general trebuie sa fie suma baremului acordat, de CHAMP_ROUNDS ori.
	var per_race := 0
	for rank in slots:
		if rank < GameState.CHAMP_POINTS.size():
			per_race += int(GameState.CHAMP_POINTS[rank])
	var total := 0
	for p in GameState.champ_points:
		total += int(p)
	_check(total == per_race * GameState.CHAMP_ROUNDS,
		"total acordat %d = %d pe cursa x %d curse"
			% [total, per_race, GameState.CHAMP_ROUNDS])

	# Nimeni nu ramane pe zero daca grila e mai mare decat baremul: verificam ca
	# ultimul loc chiar nu primeste nimic, in loc sa crape.
	var last := slots - 1
	print("  ultimul loc (slot %d) are %d puncte"
		% [last, int(GameState.champ_points[last])])

	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true
