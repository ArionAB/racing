extends SceneTree
## Cat de lata e FANTA din nodul de trafic (Chongqing POI A)?
##
## Nodul de trafic e singurul decor din joc care are voie sa stea PE sosea:
## bulevardul blocat de vehicule, cu o singura trecere (brief chongqing.md §2
## A). Din cauza asta e si singurul care nu poate fi verificat de
## `probe_solid` — ala cere linia libera, iar aici linia TREBUIE sa fie
## blocata, mai putin o fanta.
##
## Nu socoteste pe AABB-uri (memoria `decor-manual-coliziune`: pe un obiect mare
## orice masuratoare pe cutie minte). Plimba GABARITUL MASINII — 2.4 lat x 1.4
## inalt x 4.0 lung, la inaltimea ei — pe latimea bulevardului, din 10 in 10 cm,
## si intreaba FIZICA pe cine atinge. Ce ramane liber, pe o banda continua, e
## fanta reala.
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
	var best_gap := 0.0
	var best_line := ""
	var fr := _frac - 0.006
	while fr <= _frac + 0.006:
		var idx := int(fr * float(n)) % n
		var p: Vector3 = baked[idx]
		var nx: Vector3 = baked[(idx + 1) % n]
		var pv: Vector3 = baked[(idx - 1 + n) % n]
		var fw := (nx - pv); fw.y = 0.0; fw = fw.normalized()
		var r := Vector3(-fw.z, 0.0, fw.x)
		var basis := Basis(r, Vector3.UP, fw)
		# banda libera cea mai lata pe latimea bulevardului
		var run := 0.0
		var run_start := 0.0
		var local_best := 0.0
		var local_a := 0.0
		var local_b := 0.0
		var lat := -11.0
		while lat <= 11.0:
			var pos := p + r * lat + Vector3.UP * (CAR_H * 0.5 + RIDE)
			q.transform = Transform3D(basis, pos)
			var hits := space.intersect_shape(q, 8)
			var blocked := false
			for h in hits:
				var col = h["collider"]
				# soseaua si terenul nu conteaza: masina sta PE ele
				var nm := String(col.name)
				if nm.contains("_col"):
					blocked = true
					break
			if blocked:
				if run > local_best:
					local_best = run; local_a = run_start; local_b = lat
				run = 0.0
				run_start = lat + 0.1
			else:
				run += 0.1
			lat += 0.1
		if run > local_best:
			local_best = run; local_a = run_start; local_b = 11.0
		if local_best > 0.0 and (best_gap == 0.0 or local_best < best_gap):
			best_gap = local_best
			best_line = "f=%.4f fanta=%.2f m intre lat %.1f si %.1f" % [
				fr, local_best, local_a, local_b]
		fr += 0.0015

	print("--- FANTA din nodul de trafic (POI A) ---")
	print(best_line)
	# Latimea gabaritului e 2.4 m; sub 3.0 m fanta devine loterie la viteza.
	var ok := best_gap >= 3.0 and best_gap <= 7.0
	print("gabarit masina = %.1f m; fanta = %.2f m" % [CAR_W, best_gap])
	if best_gap < 3.0:
		print("VERDICT: PREA STRANSA")
	elif best_gap > 7.0:
		print("VERDICT: PREA LARGA (nu se simte blocajul)")
	else:
		print("VERDICT: OK")
