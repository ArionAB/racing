extends SceneTree
## Blocheaza nodul de trafic bulevardul, si pe unde se trece?
##
## Nodul de trafic e singurul decor din joc care are voie sa stea PE sosea:
## bulevardul blocat de vehicule, cu o singura trecere (brief chongqing.md §2
## A). Din cauza asta e si singurul care nu poate fi verificat de
## `probe_solid` — ala cere linia libera, iar aici linia TREBUIE sa fie
## blocata, mai putin o fanta.
##
## CE INTREABA SONDA, si ce gresea versiunea de dinainte. Versiunea veche
## masura latimea celei mai stramte benzi libere si o compara cu gabaritul —
## deci raporta „VERDICT OK, fanta 5.15 m" pe un nod de trafic prin care se
## trecea in linie dreapta, fiindca nu intreba niciodata daca exista BLOCAJ.
## O fanta e o fanta doar daca restul carosabilului e inchis.
##
## Deci intrebarea are DOUA jumatati, si amandoua trebuie sa treaca:
##   1. ACOPERIRE: pe fractia cea mai blocata, cat din carosabil (+/- hw) e
##      inchis? Sub 60% nu e blocaj, e decor pe acostament.
##   2. FANTA: pe acea fractie, cea mai lata banda continua libera.
##
## ATENTIE la ce inseamna „lat" aici, fiindca sonda masoara doua lucruri
## diferite si confundarea lor a produs deja o reparatie gresita.
## Ce se plimba e CENTRUL unei cutii de 2.4 m; banda de pozitii de centru in
## care cutia nu atinge nimic e mai INGUSTA cu exact 2.4 m decat golul fizic
## dintre piese. Deci:
##   * `trecere` = latimea benzii de centre = cat loc de manevra are soferul.
##     Zero inseamna „nu se poate trece", oricat de larg ar parea golul.
##   * `fanta fizica` = `trecere + 2.4` = distanta reala dintre bare.
## Brieful cere o fanta FIZICA de ~3 m, adica o trecere de ~0.6-1.5 m: stramt
## cu intentie, dar trecabil. Pragul de aici e pe trecere, nu pe fanta.
##
## Nu socoteste pe AABB-uri (memoria `decor-manual-coliziune`: pe un obiect mare
## orice masuratoare pe cutie minte). Plimba GABARITUL MASINII — 2.4 lat x 1.4
## inalt x 4.0 lung, la inaltimea ei — pe latimea bulevardului, din 5 in 5 cm,
## si intreaba FIZICA pe cine atinge.
##
## De ce lungimea de 4 m conteaza: masina trece printr-un blocaj pe o BANDA, nu
## printr-un punct. Un vehicul pus oblic poate lasa o gaura larga la mijloc si
## totusi sa inchida trecerea cu capetele — exact asa a picat prima versiune a
## nodului, cu autobuze de 10.64 m puse la 3° (fanta masurata: 0.10 m).
##
## Rulare:
##   godot --headless --fixed-fps 60 --path . --script res://tools/probe_fanta.gd ##       -- --frac=0.0315

const CAR_W := 2.4
const CAR_H := 1.4
const CAR_L := 4.0
const RIDE := 0.35

var _t: Node = null
var _f := 0
var _frac := 0.0315

func _process(_d: float) -> bool:
	if _t == null:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--frac="):
				_frac = float(a.trim_prefix("--frac="))
		_t = (load("res://scenes/tracks/Track12.tscn") as PackedScene).instantiate()
		root.add_child(_t)
		return false
	_f += 1
	if _f < 6:
		return false
	_scan()
	quit(0)
	return true

func _scan() -> void:
	var baked: PackedVector3Array = _t.baked
	var n := baked.size()
	var space := (_t as Node3D).get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(CAR_W, CAR_H, CAR_L)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false

	# Scanam o fereastra de fractii in jurul blocajului, ca sa prindem si
	# adancimea lui (autobuzul are 2.7 m, masinutele stau in spate).
	# Pentru fiecare fractie: cat din carosabil e inchis, si care e cea mai
	# lata banda continua libera. Fractia care conteaza e cea mai BLOCATA.
	var best_cover := -1.0
	var best_gap := 0.0
	var best_frac := 0.0
	var best_a := 0.0
	var best_b := 0.0
	var hw := 7.0
	var fr := _frac - 0.010
	while fr <= _frac + 0.010:
		var idx := int(fr * float(n)) % n
		var p: Vector3 = baked[idx]
		var nx: Vector3 = baked[(idx + 1) % n]
		var pv: Vector3 = baked[(idx - 1 + n) % n]
		var fw := (nx - pv); fw.y = 0.0; fw = fw.normalized()
		var r := Vector3(-fw.z, 0.0, fw.x)
		var basis := Basis(r, Vector3.UP, fw)
		var run := 0.0
		var run_start := 0.0
		var local_best := 0.0
		var local_a := 0.0
		var local_b := 0.0
		var blocked_len := 0.0
		var lat := -hw
		while lat <= hw:
			var pos := p + r * lat + Vector3.UP * (CAR_H * 0.5 + RIDE)
			q.transform = Transform3D(basis, pos)
			var hits := space.intersect_shape(q, 8)
			var blocked := false
			for h in hits:
				var col = h["collider"]
				# Soseaua si terenul nu conteaza (masina sta PE ele); ORICE
				# altceva blocheaza.
				var nm := String(col.name)
				if nm.begins_with("Road") or nm.begins_with("Terrain") 						or nm.begins_with("Ground") or nm == "StaticBody3D":
					continue
				blocked = true
				break
			if blocked:
				blocked_len += 0.05
				if run > local_best:
					local_best = run; local_a = run_start; local_b = lat
				run = 0.0
				run_start = lat + 0.05
			else:
				run += 0.05
			lat += 0.05
		if run > local_best:
			local_best = run; local_a = run_start; local_b = hw
		var cover := 100.0 * blocked_len / (2.0 * hw)
		if cover > best_cover:
			best_cover = cover
			best_gap = local_best
			best_frac = fr
			best_a = local_a
			best_b = local_b
		fr += 0.0005

	# DIAGNOSTIC: pe fractia cea mai blocata, cine sta pe fiecare laterala.
	# Fara asta „100% inchis" nu spune ce sa mut.
	var didx := int(best_frac * float(n)) % n
	var dp: Vector3 = baked[didx]
	var dnx: Vector3 = baked[(didx + 1) % n]
	var dpv: Vector3 = baked[(didx - 1 + n) % n]
	var dfw := (dnx - dpv); dfw.y = 0.0; dfw = dfw.normalized()
	var dr := Vector3(-dfw.z, 0.0, dfw.x)
	var dbasis := Basis(dr, Vector3.UP, dfw)
	print("--- CINE BLOCHEAZA (frac %.4f) ---" % best_frac)
	var dl := -hw
	while dl <= hw:
		var dpos := dp + dr * dl + Vector3.UP * (CAR_H * 0.5 + RIDE)
		q.transform = Transform3D(dbasis, dpos)
		var dh := space.intersect_shape(q, 8)
		var names := ""
		for h in dh:
			var col = h["collider"]
			var nm := String(col.name)
			if nm.begins_with("Road") or nm.begins_with("Terrain") 					or nm.begins_with("Ground") or nm == "StaticBody3D":
				continue
			# Corpul fizic e construit la runtime SUB nodul prop-ului, deci
			# numele util e al bunicului, nu al parintelui (ala e sectiunea).
			var who := nm
			var up: Node = col
			while up != null:
				if String(up.name).begins_with("masina") 						or String(up.name).begins_with("autobuz") 						or String(up.name).begins_with("bolard"):
					who = String(up.name)
					break
				up = up.get_parent()
			names += who + " "
		print("  lat %+5.1f : %s" % [dl, names if names != "" else "LIBER"])
		dl += 0.5

	print("--- NODUL DE TRAFIC (POI A) ---")
	print("carosabil +/-%.1f m; gabarit masina %.1f m" % [hw, CAR_W])
	print("fractia cea mai blocata: %.4f" % best_frac)
	print("  acoperire: %.0f%% din carosabil inchis" % best_cover)
	print("  trecere:   %.2f m (banda de pozitii libere), intre lat %.1f si %.1f"
		% [best_gap, best_a, best_b])
	print("  fanta fizica: %.2f m intre bare" % (best_gap + CAR_W))
	# Doua conditii, amandoua obligatorii. Acoperirea spune ca EXISTA blocaj;
	# fanta spune ca se poate trece prin el.
	var ok_cover := best_cover >= 60.0
	# Trecere intre 0.6 si 2.5 m => fanta fizica intre 3.0 si 4.9 m.
	var ok_gap := best_gap >= 0.6 and best_gap <= 2.5
	if not ok_cover:
		print("VERDICT: NU E BLOCAJ (sub 60%% acoperire — se trece pe langa)")
	elif best_gap < 0.6:
		print("VERDICT: FANTA PREA STRANSA")
	elif best_gap > 2.5:
		print("VERDICT: FANTA PREA LARGA (nu se simte blocajul)")
	else:
		print("VERDICT: OK")
