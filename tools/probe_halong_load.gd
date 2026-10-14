extends Node
## Incarca Track22 (Ha Long) si verifica fundatia: ca scena se construieste fara
## erori, si ca CIFRELE CARE CONTEAZA sunt cele pe care le-a promis generatorul.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHalongLoad.tscn
##
## De ce o sonda proprie si nu verify_all_tracks_load: aia e o sonda temporara
## din sesiunea Jodhpur, cu lista inghetata la Track19. Aici verific anume
## contractele fundatiei Ha Long (brief §7 pasul 3), nu doar "se incarca".
##
## CE VERIFICA, si de ce fiecare (brief §2, memoria
## cota-marii-e-relativa-la-media-drumului):
##  1. scena se incarca si se construieste fara erori;
##  2. COTA MARII iese la ~0.0. E testul care conteaza: `sea_level_offset` e
##     relativ la media cotelor soselei, deci cifra din .tscn e corecta doar
##     daca media e cea masurata de generator. Daca cineva muta o cota si uita
##     offsetul, marea urca peste pontoane si asta o prinde;
##  3. media cotelor soselei e cea pe care a raportat generatorul (+5.99);
##  4. drumul de pe apa (cheiul, pontoanele) e DEASUPRA apei;
##  5. lungimea si numarul de puncte coapte.

const TRACK_PATH := "res://scenes/tracks/Track22.tscn"
## Din tools/gen_halong_route.py (garda de apa).
const MEAN_EXPECTED := 5.99
const MEAN_TOL := 0.25
const SEA_TOL := 0.20
## Cotele pentru care sunt desenate suprafetele de pe apa (brief §2).
const PONTON_Y := 0.6


func _ready() -> void:
	var fails: Array[String] = []

	var packed := load(TRACK_PATH) as PackedScene
	if packed == null:
		print("[PICAT] nu pot incarca ", TRACK_PATH)
		get_tree().quit(1)
		return
	var track := packed.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== ProbeHalongLoad (Track22) ===")
	print("  s-a instantiat: ", track.name, " (", track.get_class(), ")")

	# --- cotele soselei, din punctele coapte ---------------------------------
	var curve: Curve3D = null
	var path := track.get_node_or_null("Path") as Path3D
	if path != null:
		curve = path.curve
	if curve == null:
		fails.append("fara Path/curve: nu pot citi cotele")
	else:
		var baked := curve.get_baked_points()
		var ys: Array[float] = []
		for p in baked:
			ys.append(p.y)
		ys.sort()
		var mean := 0.0
		for y in ys:
			mean += y
		mean /= float(maxi(ys.size(), 1))
		print("  puncte coapte: %d   lungime %.0f m" % [baked.size(), curve.get_baked_length()])
		print("  cote: min %.2f  max %.2f  medie %.2f" % [ys[0], ys[ys.size() - 1], mean])
		if absf(mean - MEAN_EXPECTED) > MEAN_TOL:
			fails.append("media cotelor %.2f, generatorul a raportat %.2f (toleranta %.2f): "
				% [mean, MEAN_EXPECTED, MEAN_TOL]
				+ "daca ai mutat o cota, RECALCULEAZA sea_level_offset")
		else:
			print("  [OK] media cotelor %.2f ~ %.2f (cea din care s-a calculat offsetul)"
				% [mean, MEAN_EXPECTED])

		# --- COTA MARII: testul principal -----------------------------------
		# Track.sea_level_offset e @export; marea iese la mean_road_y + offset.
		var off: float = track.get("sea_level_offset")
		var sea_y := mean + off
		print("  sea_level_offset = %.2f  ->  marea la %.2f" % [off, sea_y])
		if absf(sea_y) > SEA_TOL:
			fails.append("marea la %.2f, tinta 0.00 +/- %.2f (cota pentru care sunt "
				% [sea_y, SEA_TOL] + "desenate cheiul si pontoanele)")
		else:
			print("  [OK] marea la %.2f (tinta 0.00 +/- %.2f)" % [sea_y, SEA_TOL])
		if sea_y > PONTON_Y - 0.3:
			fails.append("marea %.2f INUNDA pontoanele (%.2f): offsetul e greşit"
				% [sea_y, PONTON_Y])
		else:
			print("  [OK] pontoanele (%.2f) deasupra marii (%.2f)" % [PONTON_Y, sea_y])
		if ys[0] < sea_y:
			fails.append("cel mai jos punct de drum (%.2f) e SUB mare (%.2f)" % [ys[0], sea_y])
		else:
			print("  [OK] cel mai jos drum (%.2f) peste mare (%.2f)" % [ys[0], sea_y])

	# --- nodurile pe care le promite brieful --------------------------------
	for nm in ["Hazarduri/JoncaCanal", "Hazarduri/MaimutePerete", "Peaks", "DecorManual"]:
		if track.get_node_or_null(nm) == null:
			fails.append("lipseste nodul " + nm)
	print("  noduri de hazard/decor: ",
		"toate prezente" if fails.is_empty() else "vezi mai jos")

	print()
	if fails.is_empty():
		print("TOATE TREC")
		get_tree().quit(0)
		return
	print("PICAT:")
	for f in fails:
		print("  - ", f)
	get_tree().quit(1)
