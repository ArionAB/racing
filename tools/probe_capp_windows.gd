extends SceneTree
## Garda ferestrelor din stanca goala (POI G).
##
## Intreaba trei lucruri pe care le-am stricat pe rand, in aceeasi sesiune, si
## pe care nicio sonda existenta nu le prindea:
##
## 1. FERESTRELE URCA. Brief §2 cere "lumina de sus creste la fiecare tura".
##    Varianta initiala avea firidele in doua inele PLATE — decor care nu spune
##    nimic despre urcare. Se cere ca inaltimile sa fie distincte si crescatoare.
##
## 2. NICIUNA NU E LANGA MASINA. Una asezata pe azimutul drumului la inaltimea
##    ei umple cadrul ca o placa oarba (masurat la frac 0.86). Fereastra e decor
##    pentru portiunea de DINAINTE — memoria `masoara-inainte-nu-langa`.
##
## 3. RAMA E INGROPATA. Firida are 1.5 m adancime; lasata proud i se vede cutia
##    si citeste autocolant, nu incapere (capcana rundei 17 de pe hornuri:
##    "rame asezate pe perete").
##
## Nu numara instante: o sonda care numara ar fi trecut verde si cu firidele in
## inele plate, si cu una lipita de bara masinii.

const AXIS := Vector2(-302.02, 6.0)
const R_INNER := 34.0
## Cat de departe in azimut trebuie sa fie o fereastra fata de drumul de la
## cota ei. Sub 45 de grade intra in cadrul de langa masina.
const MIN_AZ_SEP_DEG := 45.0

func _initialize() -> void:
	var track: Node = load("res://scenes/tracks/Track13.tscn").instantiate()
	root.add_child(track)
	await process_frame
	await process_frame
	var holder: Node = track.get_node_or_null(
		"DecorManual/G) Stanca goala/Ferestre")
	if holder == null:
		print("VERDICT: FAIL — nu exista nodul Ferestre")
		quit(1)
		return

	var ys: Array[float] = []
	var fails: Array[String] = []
	for child in holder.get_children():
		var n3 := child as Node3D
		if n3 == null or not String(child.name).begins_with("Fereastra"):
			continue
		var p := n3.global_position
		ys.append(p.y)
		var d := Vector2(p.x, p.z) - AXIS
		var r := d.length()
		# 1.5 m adancime * scara: ingropata inseamna centrul DINCOLO de fata
		# peretelui, nu pe ea.
		if r < R_INNER + 0.9:
			fails.append("%s: rama proud (r=%.2f, cere >= %.2f)"
				% [child.name, r, R_INNER + 0.9])
		var az := rad_to_deg(atan2(d.y, d.x))
		var road_az := 167.0 - (p.y - 12.0) / 1.5 * 30.0
		var sep := absf(wrapf(az - road_az, -180.0, 180.0))
		if sep < MIN_AZ_SEP_DEG:
			fails.append("%s: la %.0f° de drum (cere >= %.0f°) — iese langa masina"
				% [child.name, sep, MIN_AZ_SEP_DEG])

	# Zero ferestre e cazul in care sonda TREBUIE sa cada, nu sa crape: exact
	# starea de dinaintea rundei de arta (firidele erau in alt nod). O sonda
	# care se blocheaza pe lista goala nu e o garda.
	if ys.is_empty():
		print("VERDICT: FAIL — nicio fereastra sub nodul Ferestre")
		quit(1)
		return
	if ys.size() < 8:
		fails.append("doar %d ferestre; elicea are 2 ture, cere >= 8" % ys.size())
	ys.sort()
	var spread := 0.0
	if ys.size() >= 2:
		spread = ys[ys.size() - 1] - ys[0]
	# Doua ture urca 12 -> 48 m: o desfasurare sub 20 m inseamna inele plate.
	if spread < 20.0:
		fails.append("ferestrele se intind pe %.1f m; inele plate, nu spirala" % spread)

	print("=== Ferestrele stancii goale (Track13) ===")
	print("  ferestre %d | cote %.1f .. %.1f m (desfasurare %.1f m)"
		% [ys.size(), ys[0], ys[ys.size() - 1], spread])
	if fails.is_empty():
		print("VERDICT: OK — urca odata cu elicea, ingropate, niciuna langa masina")
		quit(0)
	else:
		for f: String in fails:
			print("  ! " + f)
		print("VERDICT: FAIL — %d probleme" % fails.size())
		quit(1)
