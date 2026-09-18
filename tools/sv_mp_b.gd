extends Node
## Survey pe zona repunerii reproductibile de la frac 0.186 (POI B, urcarea
## pe treptele Drumului Incas). Masoara, pe fractii dese in jurul defectului:
##   - semi-latimea carosabilului (width_at_index)
##   - cota axului
##   - cota solului REAL (raycast) la +/- offset-uri laterale, in pasi mici
## Scopul: se vede UNDE se termina carosabilul si cat de brusc cade terenul
## dincolo de margine. O cadere abrupta chiar langa margine = masina care
## tine exteriorul pierde contactul si pleaca.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus_y := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var n := _track.baked.size()

	print("=== SURVEY POI B — zona repunerii (frac 0.186, poz ~(243,36,130)) ===")
	print("semi-latimea vine din width_at_index; cotele din raycast pe corpul real.")
	print("")
	print("frac    idx   semi_lat   ax_y     lateral: cota solului la m de AX")
	print("                                   -14   -10    -8    -6    +6    +8   +10   +14")
	for f in range(150, 231, 5):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var nx: Vector3 = _track.baked[(idx + 1) % n]
		var dir := (nx - bp)
		dir.y = 0.0
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()
		var lat := Vector3(-dir.z, 0.0, dir.x)
		var w := _track.width_at_index(idx)
		var row := "%.3f  %4d   %5.2f   %+6.1f  " % [frac, idx, w, bp.y]
		for off: float in [-14.0, -10.0, -8.0, -6.0, 6.0, 8.0, 10.0, 14.0]:
			var p := bp + lat * off
			row += " %+6.1f" % [_sol(p.x, p.z)]
		print(row)

	print("")
	print("=== CADEREA fata de MARGINE (cat coboara solul in primii metri dincolo) ===")
	print("frac    semi_lat   la_margine  +1m   +2m   +3m   +5m   (partea care cade)")
	for f in range(150, 231, 5):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var nx: Vector3 = _track.baked[(idx + 1) % n]
		var dir := (nx - bp)
		dir.y = 0.0
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()
		var lat := Vector3(-dir.z, 0.0, dir.x)
		var w := _track.width_at_index(idx)
		# partea ravenei 0 e +1 (dreapta); masuram ambele si raportam
		for sgn: float in [1.0, -1.0]:
			var base := _sol((bp + lat * (w * sgn)).x, (bp + lat * (w * sgn)).z)
			var row := "%.3f  %5.2f  %s  %+7.1f" % [frac, w, ("dr" if sgn > 0.0 else "st"), base]
			for extra: float in [1.0, 2.0, 3.0, 5.0]:
				var p := bp + lat * ((w + extra) * sgn)
				row += " %+6.1f" % [_sol(p.x, p.z) - base]
			print(row)
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus_y, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	if r.is_empty(): return -999.0
	return float((r["position"] as Vector3).y)
