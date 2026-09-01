extends Node3D
## Coordonate LUMII pentru decorul din dreapta la POI E, cu cota din teren.
## Se tipareste direct in forma in care intra in .tscn, ca sa nu se strecoare
## nicio cota ghicita (memoria `decor-manual-din-cod`: originile se pun pe
## terenul REAL, nu pe cota drumului).
func _ready() -> void:
	var track := get_parent().get_node_or_null("Track13")
	await get_tree().process_frame
	var route = track.get("routes")[0]
	var baked: PackedVector3Array = route.baked
	var n := baked.size()
	var sampler = track.get("_sampler")
	# (fractie, distanta in fata, lateral dreapta)
	# Bazinul din dreapta e PLAT si cu 8-12 m SUB drum, pe 160 m (masurat cu
	# ProbeERight dupa ce s-a corectat semnul lui `rt`). Deci hornurile de
	# acolo se vad de SUS, iar varfurile lor cad sub linia orizontului — se
	# desprind pe coama departata, nu pe cer. Aia e ce umple treimea dreapta
	# fara sa taie cerul: exact greseala rundei 17 de pe padurea de hornuri,
	# unde ramele treceau silueta in cer si a trebuit revenit.
	var spots := [
		[0.552, 38.0, 26.0], [0.556, 72.0, 44.0], [0.562, 120.0, 34.0],
		[0.575, 45.0, 30.0], [0.582, 88.0, 52.0], [0.590, 145.0, 40.0],
		[0.598, 40.0, 24.0], [0.604, 78.0, 46.0], [0.612, 130.0, 60.0],
		[0.622, 52.0, 32.0], [0.632, 96.0, 50.0], [0.645, 60.0, 36.0],
	]
	for s in spots:
		var i := int(float(s[0]) * n) % n
		var p: Vector3 = baked[i]
		var fw: Vector3 = (baked[(i + 6) % n] - p).normalized()
		# DREAPTA = fw.cross(UP) = (-fw.z, 0, fw.x). Prima versiune avea semnul
		# invers si a asezat toate hornurile pe coama din STANGA — se vedeau
		# lespezi iesind din dealul din stanga pe captura r2k. Se deriva, nu se
		# ghiceste (memoria `rotatii-in-builder-semnul`).
		var rt := Vector3(-fw.z, 0, fw.x)
		var q: Vector3 = p + fw * float(s[1]) + rt * float(s[2])
		var gy: float = sampler.ground_y(q.x, q.z)
		print("frac %.3f fwd %5.1f lat %5.1f -> (%.3f, %.3f, %.3f)  dy_fata_de_drum %+.1f" % [
			s[0], s[1], s[2], q.x, gy, q.z, gy - p.y])
	get_tree().quit()
