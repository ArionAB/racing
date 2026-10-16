## Sonda: la coordonatele unde am asezat satul plutitor, exista APA sau e TEREN?
##
## Intrebarea e specifica si are un singur raspuns corect. Pe captura din joc
## casele pareau sa stea pe nisip. Doua explicatii posibile, care cer reparatii
## OPUSE:
##   (a) cota lor e gresita  -> se muta pe Y;
##   (b) locul e gresit (acolo e uscat, nu golf) -> se muta pe XZ.
## Masurat, nu presupus (memoria `procent-de-culoare-nu-e-dovada`).
##
## Rulare (ca SCENA, are nevoie de autoload-uri):
##   godot --headless --path . res://tools/SvHalongApa.tscn
extends Node


func _ready() -> void:
	var scene := load("res://scenes/tracks/Track22.tscn") as PackedScene
	var track := scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sampler = track.get("_sampler")
	if sampler == null:
		print("!! fara _sampler")
		get_tree().quit(1)
		return

	var sea_y: float = 0.0
	if track.has_method("sea_level_y"):
		sea_y = track.sea_level_y()
	else:
		var mean_y: float = sampler.mean_road_y()
		sea_y = mean_y + float(track.get("sea_level_offset"))

	print("=== cota marii in lume: %+.2f ===" % sea_y)
	print("")
	print("%-20s %10s %10s %8s  %s" % ["nod", "teren_y", "cota_mea", "delta", "verdict"])

	var decor := track.get_node_or_null("DecorManual")
	if decor == null:
		print("!! fara DecorManual")
		get_tree().quit(1)
		return

	var pe_uscat := 0
	var pe_apa := 0
	for ch in decor.get_children():
		var nm := String(ch.name)
		if not (nm.begins_with("CasaPlutitoare") or nm.begins_with("TarcPeste")
				or nm.begins_with("BarcaMica")):
			continue
		# Corpurile de coliziune generate de `world_prop` (`<nume>_col`) NU se
		# masoara: ele stau la originea lor proprie si `ground_y` le raporta o
		# cota CONSTANTA (+5.61 pe toate), adica o cifra identica la bit pentru
		# pozitii diferite — semnul clasic ca sonda masoara altceva decat crede
		# (memoria `sonda-masura-alt-obiect`). Prima varianta le numara si
		# bilantul iesea "14 pe apa, 14 pe uscat" pe un sat complet corect.
		if nm.ends_with("_col"):
			continue
		var p: Vector3 = (ch as Node3D).position
		var gy: float = sampler.ground_y(p.x, p.z)
		# Apa exista acolo unde TERENUL e sub cota marii.
		var e_apa: bool = gy < sea_y - 0.3
		var verdict := "APA (teren %+.2f sub mare)" % (gy - sea_y) if e_apa \
			else "USCAT (teren %+.2f peste mare)" % (gy - sea_y)
		if e_apa:
			pe_apa += 1
		else:
			pe_uscat += 1
		print("%-20s %+10.2f %+10.2f %+8.2f  %s" % [nm, gy, p.y, p.y - gy, verdict])

	print("")
	print("=== BILANT: %d pe apa, %d pe uscat ===" % [pe_apa, pe_uscat])
	if pe_uscat > 0:
		print("CAUZA (b): locul e gresit — piesele stau unde terenul e peste cota marii.")
		print("           se muta pe XZ (lateral mai mare), nu pe Y.")
	else:
		print("CAUZA (a): locul e bun, deci daca pe captura par pe nisip e o")
		print("           chestiune de COTA sau de randare a apei, nu de pozitie.")
	get_tree().quit(0)
