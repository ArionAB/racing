extends Node
## Ajunge LUMINA DIRECTA pe peretele interior, la cotele la care se judeca?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGSun.tscn
##
## [b]De ce exista sonda asta.[/b] Trei runde au incercat sa faca stratele
## vizibile prin GEOMETRIE — consola de 2.71 m, apoi o buza TARE de 0.3 m cu fata
## de sus orizontala, exact cifra ceruta in verdicte. Niciuna n-a schimbat nimic
## masurabil pe captura (deviatia de luminanta a SCAZUT, 52.09 -> 50.70).
##
## Motivul nu e in geometrie: o treapta se vede fiindca fata ei de sus prinde
## alta lumina decat fata verticala. Daca in punctul ala nu bate NICIO lumina
## directionala, cele doua fete primesc acelasi ambiental si treapta e invizibila
## oricat de adanca ar fi. Sonda intreaba exact asta, cu un raycast spre soare.
func _ready() -> void:
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var sun: DirectionalLight3D = null
	for n in t.get_children():
		if n is DirectionalLight3D:
			sun = n
			break
	if sun == null:
		print("VERDICT: ESEC - nicio lumina directionala")
		get_tree().quit(1)
		return
	# Directia SPRE soare = -Z al luminii, inversat.
	# [b]Semnul, derivat nu ghicit.[/b] O `DirectionalLight3D` lumineaza pe
	# directia -Z a ei, deci raza CADE pe -Z si directia SPRE soare e +Z.
	# Prima versiune a scris `-basis.z` si sonda a raportat elevatie -13 grade,
	# adica un soare sub orizont — cifra insasi a dat greseala pe fata. Memoria
	# `rotatii-in-builder-semnul` spune acelasi lucru: se verifica cu o cifra
	# care trebuie sa iasa pozitiva, nu se alege din cap.
	var to_sun := sun.global_transform.basis.z
	print("soare: rotatie %s | directie spre soare %s (elevatie %.1f grade)" % [
		sun.rotation_degrees, to_sun, rad_to_deg(asin(to_sun.y))])
	var space := t.get_world_3d().direct_space_state
	var axis := Vector2(-302.02, 6.0)
	print("")
	print("cota | azimuturi cu SOARE pe peretele interior (din 24)")
	var first := -1
	var last := -1
	for y: float in [15.0, 20.0, 27.0, 33.0, 40.0, 46.0]:
		var n := 0
		for k in 24:
			var a := deg_to_rad(float(k) * 15.0)
			# Un punct pe fata peretelui, la raza 35.
			var p := Vector3(axis.x + 35.0 * cos(a), y, axis.y + 35.0 * sin(a))
			# Trage spre soare: daca nu loveste nimic, punctul e insorit.
			var q := PhysicsRayQueryParameters3D.create(
				p + to_sun * 0.5, p + to_sun * 400.0)
			if space.intersect_ray(q).is_empty():
				n += 1
		if first < 0:
			first = n
		last = n
		print("  %4.1f m | %2d / 24" % [y, n])
	print("")
	if first == 0:
		print("CONSTATARE: la cota de jos peretele nu primeste lumina DIRECTA")
		print("deloc. Orice treapta de acolo e iluminata doar ambiental, deci")
		print("fata ei de sus si fata ei verticala au ACEEASI valoare si treapta")
		print("nu se vede — oricat de adanca ar fi taiata.")
	get_tree().quit()
