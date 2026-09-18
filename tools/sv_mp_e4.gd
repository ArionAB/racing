extends Node
## RUNDA 4: verdictul orb spune „nu exista gol sub tablier, terenul trece
## continuu la ~2 m sub scanduri". Masuratoarea mea de la runda 1 spune 20.30 m
## la mijloc. AMANDOUA pot fi adevarate daca golul e doar pe o parte a
## tablierului. Aici masor CE VEDE OCHIUL: profilul terenului pe o linie
## paralela cu tablierul, la distante LATERALE mici — adica exact banda de
## teren pe care o vezi printre/langa scanduri din chase cam.
const TRACK := "res://scenes/tracks/Track15.tscn"

var _t: Track
var _rid: RID = RID()
var _sus := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	for i in 6:
		await get_tree().process_frame
	var hi := -INF
	for bp in _t.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 200.0
	for c in _t.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	print("; TerrainBody rid valid: %s" % str(_rid.is_valid()))
	# Tablierul: de la x=+31 la x=-3, la z=-155, y=-20. Latime 11 m => z=-160.5..-149.5
	print("; A. PROFIL LATERAL: sol la z = -155 +- dz, pe lungimea tablierului")
	for dz: float in [0.0, 6.0, 9.0, 12.0, 18.0, 25.0, 40.0]:
		for sgn: float in [1.0, -1.0]:
			if dz == 0.0 and sgn < 0.0:
				continue
			var z := -155.0 + sgn * dz
			var line := ";  dz=%+5.1f (z=%7.1f):" % [sgn * dz, z]
			for x: float in [34.0, 31.0, 26.0, 20.0, 14.0, 8.0, 2.0, -3.0, -6.0]:
				line += " %+.1f" % _sol(x, z)
			print(line + "   (x = 34..-6, tablier -20.00)")
	print("; B. CE VEDE OCHIUL de la intrarea pe pod (36, -16.8, -155), spre -X:")
	print(";    pentru fiecare dz lateral, cel mai MIC unghi sub orizontala pe")
	print(";    primii 60 m — adica cat de adanc pare golul in acea directie.")
	for dz: float in [0.0, 6.0, 9.0, 12.0, 18.0, 25.0]:
		for sgn: float in [1.0, -1.0]:
			if dz == 0.0 and sgn < 0.0:
				continue
			var z := -155.0 + sgn * dz
			var worst := 90.0
			var worst_d := 0.0
			var worst_y := 0.0
			var d := 4.0
			while d <= 60.0:
				var g := _sol(36.0 - d, z)
				var ang := rad_to_deg(atan2(-16.8 - g, d))
				if ang < worst:
					worst = ang
					worst_d = d
					worst_y = g
				d += 2.0
			print(";  dz=%+5.1f: unghi MINIM sub orizontala %5.1f deg (la %4.1f m, sol %+7.2f)" % [
				sgn * dz, worst, worst_d, worst_y])
	print("; C. ADANCIME SUB TABLIER, punct cu punct pe lungimea lui (z=-155):")
	for x: float in [34.0, 32.0, 31.0, 29.0, 26.0, 23.0, 20.0, 17.0, 14.0, 11.0, 8.0, 5.0, 2.0, -1.0, -3.0, -5.0]:
		print(";   x=%+6.1f  sol %+7.2f  gol sub tablier %6.2f m" % [x, _sol(x, -155.0), -20.0 - _sol(x, -155.0)])
	get_tree().quit(0)


func _sol(x: float, z: float) -> float:
	## Raza filtrata pe TerrainBody: sub tablier stau Plate*/AnimatableBody3D
	## ale hazardului si ar raporta „gol 0" (capcana lui E).
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var from := Vector3(x, _sus, z)
	for i in 24:
		q.from = from
		var r := _t.get_world_3d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			return -999.0
		if (r["rid"] as RID) == _rid:
			return float((r["position"] as Vector3).y)
		from = (r["position"] as Vector3) + Vector3(0, -0.05, 0)
	return -999.0
