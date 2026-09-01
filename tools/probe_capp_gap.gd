extends Node3D
## Unde e teren si unde e GOL, lateral fata de banda, la POI B.
##
## Pentru rosul din referinta: masa rosie trebuie sa stea SUB cota drumului si
## dincolo de un gol, nu langa banda. Sonda cauta directia in care terenul cade
## cel mai mult, la 40-120 m — adica pe unde s-ar vedea peste o rapa.
##
## CE NU DOVEDESTE: ca se si VEDE de la volan. Cotele nu spun nimic despre
## frustum; verdictul ramane captura --driver.

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var track := get_node("Track13") as Track
	var path := track.get_node("Path") as Path3D
	var curve := path.curve
	var L := curve.get_baked_length()
	for frac in [0.06, 0.08, 0.10, 0.12, 0.14]:
		var p: Vector3 = curve.sample_baked(L * frac)
		var ahead: Vector3 = curve.sample_baked(fmod(L * frac + 6.0, L))
		var fwd := (ahead - p).normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x).normalized()
		print("--- frac=", frac, " road_y=%.1f" % p.y, " pos=(%.0f, %.0f)" % [p.x, p.z])
		for side in [-1.0, 1.0]:
			var side_name := "stanga" if side < 0.0 else "dreapta"
			var line := "   " + side_name + ": "
			for d in [40.0, 60.0, 80.0, 100.0, 120.0]:
				var q: Vector3 = p + right * side * d
				var y := _ground_y(track, q)
				line += "%dm:%+.0f " % [int(d), y - p.y]
			print(line)
	print("=== HARTA IN FRUSTUM (fata x lateral), cota RELATIVA la drum ===")
	# Doar ce e in con: unghi < 34 grade fata de axa, deci lateral < fata/1.483
	for frac in [0.10, 0.14]:
		var pp: Vector3 = curve.sample_baked(L * frac)
		var aa: Vector3 = curve.sample_baked(fmod(L * frac + 6.0, L))
		var ff := (aa - pp).normalized()
		var rr := Vector3(-ff.z, 0.0, ff.x).normalized()
		print("--- de la frac=", frac, " (drum y=%.1f)" % pp.y)
		for ahead in [80.0, 110.0, 140.0, 170.0, 200.0]:
			var row := "   fata %3d: " % int(ahead)
			for lat in [-110.0, -70.0, -35.0, 0.0, 35.0, 70.0, 110.0]:
				if absf(lat) > ahead / 1.483:
					row += "  ...  "
					continue
				var qq: Vector3 = pp + ff * ahead + rr * lat
				var yy := _ground_y(track, qq)
				row += "%+5.0f " % (yy - pp.y)
			print(row)
	print("=== COTA TERENULUI SUB MASA ROSIE ===")
	var red := track.get_node_or_null("DecorManual/ZoneB_CanionulRosu")
	if red != null:
		for c in red.get_children():
			var n3 := c as Node3D
			var gy := _ground_y(track, n3.position)
			print("  ", n3.name, " nod_y=%.1f" % n3.position.y,
				" teren=%.1f" % gy, " => ", ("INGROPAT" if n3.position.y < gy else "peste teren"))
	get_tree().quit()


func _ground_y(track: Node3D, at: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	var par := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, 400.0, at.z), Vector3(at.x, -200.0, at.z))
	var hit := space.intersect_ray(par)
	if hit.is_empty():
		return -999.0
	return float((hit["position"] as Vector3).y)


## MASURATOAREA CARE A CONFIRMAT UMBRELE (runda 4), pastrata ca nota fiindca e
## singura din sesiunea asta care NU s-a certat cu poza:
##
##   sigma luminantei pe fasia de carosabil (y 62-92%, x 25-75% din cadru)
##     frac 0.06:  13.1 -> 25.1
##     frac 0.10:  13.0 -> 22.1
##     frac 0.14:  18.6 -> 15.9   <-- SCADE
##
## Primele doua cresc, si acolo se si VAD umbre lungi taind drumul. A treia
## scade, si acolo captura chiar nu arata umbre — sunt putini casteri langa
## banda la 0.14. Cifra care da si verdictul negativ e cifra in care se poate
## avea incredere; una care iesea verde peste tot ar fi fost al patrulea fals
## pozitiv al pistei.
