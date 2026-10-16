## Cotele de asezare pentru decorul de pe USCAT, masurate pe terenul REAL.
##
##   godot --headless --path . res://tools/SvHalongCote.tscn
##
## DE CE EXISTA. `gen_halong_route.py` stie doar drumul: `at_road(f, lat)` da
## cota SOSELEI la fractia f. Pe apa e exact ce trebuie (turnul intra in mare
## la -1,20 fata de drum). Pe uscat nu: acolo unde un `TerrainPeak` ridica
## solul peste drum, aceeasi formula ingroapa piesa. Masurat pe Track22:
## patru turnuri (04-07) stateau cu 0,88-0,97 m SUB solul pe care ar trebui
## sa calce.
##
## De ce nu recalculez in Python: `TrackSideSampler._lift_peaks` combina domul
## masivului prin `_smax` neted, adauga zgomot de dune si mascheaza totul cu
## banda de protectie a asfaltului. Reimplementata in generator, formula ar
## DIVERGE tacut de cea din joc la prima schimbare. Asa, cifra vine din
## `ground_y()`, adica din exact terenul pe care se conduce.
##
## Iesirea e o lista gata de lipit in generator; nu scrie nimic singura.
extends Node

## Piesele care trebuie sa STEA PE SOL (nu pe apa). Restul decorului e ancorat
## de linia apei si se aseaza corect din formula de drum.
const PREFIXE_DE_SOL := ["TurnCalcar", "Veg", "PavilionBelvedere", "Parapet",
	"Dig", "GuraGrota"]


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

	var decor := track.get_node_or_null("DecorManual")
	if decor == null:
		print("!! fara DecorManual")
		get_tree().quit(1)
		return

	print("=== cota marii: %+.2f ===" % sea_y)
	print("")
	print("%-22s %9s %9s %8s  %s" % ["nod", "teren", "acum", "delta", "stare"])

	var ingropate := 0
	var plutind := 0
	var ok := 0
	for ch in decor.get_children():
		var nm := String(ch.name)
		if nm.ends_with("_col"):
			continue
		var e_de_sol := false
		for pre in PREFIXE_DE_SOL:
			if nm.begins_with(pre):
				e_de_sol = true
				break
		if not e_de_sol:
			continue
		var p: Vector3 = (ch as Node3D).position
		var gy: float = sampler.ground_y(p.x, p.z)
		# Piesele de pe APA (teren mult sub mare) nu se judeca aici: ele sunt
		# ancorate corect de linia apei.
		if gy < sea_y - 1.0:
			continue
		var d: float = p.y - gy
		var stare := "OK"
		if d < -0.25:
			stare = "INGROPATA cu %.2f m" % (-d)
			ingropate += 1
		elif d > 0.35:
			stare = "PLUTESTE cu %.2f m" % d
			plutind += 1
		else:
			ok += 1
		print("%-22s %+9.2f %+9.2f %+8.2f  %s" % [nm, gy, p.y, d, stare])

	# Lista de corectii, gata de folosit: nodul -> cota reala a terenului.
	# Generatorul o citeste si o aplica, in loc sa recalculeze `_lift_peaks`
	# in Python (unde ar diverge tacut de formula din joc).
	# Se scriu TOATE nodurile de sol, nu doar cele gresite acum.
	#
	# Prima versiune tiparea doar abaterile, iar fisierul de corectii se
	# rescria la fiecare rulare — deci fiecare regenerare PIERDEA fixurile
	# aplicate anterior si bilantul se inrautatea (10 gresite -> 15 dupa
	# "reparare"). Tabelul trebuie sa fie complet, nu diferential.
	if true:
		print("")
		print("--- CORECTII (nod: cota_teren) ---")
		for ch2 in decor.get_children():
			var n2 := String(ch2.name)
			if n2.ends_with("_col"):
				continue
			var de_sol := false
			for pre2 in PREFIXE_DE_SOL:
				if n2.begins_with(pre2):
					de_sol = true
					break
			if not de_sol:
				continue
			var q: Vector3 = (ch2 as Node3D).position
			var gy2: float = sampler.ground_y(q.x, q.z)
			if gy2 < sea_y - 1.0:
				continue
			print("COTA %s %.3f" % [n2, gy2])

	print("")
	print("=== BILANT pe uscat: %d bune, %d ingropate, %d plutind ==="
		% [ok, ingropate, plutind])
	if ingropate + plutind == 0:
		print("VERDICT: OK")
	else:
		print("VERDICT: DE REPARAT")
	get_tree().quit(0)
