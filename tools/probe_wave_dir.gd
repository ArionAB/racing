extends Node
## SENSUL valului (issue #609, Okinawa): din ce parte vine, incotro impinge, si
## daca geografia il sustine.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWaveDir.tscn -- --track=20
##   ... -- --track=20 --expect=left     # sensul cerut de dezvoltator
##
## `--track=N` = numarul din NUMELE FISIERULUI (20 = Okinawa). `--expect` e
## sensul de mers al crestei VAZUT DIN MASINA, in sensul cursei: `left` = vine
## din dreapta si merge spre stanga. Cod de iesire 1 daca nu se potriveste.
##
## Trei masuratori, toate pe lume reala, nu pe constante:
##   1. GEOGRAFIE: pe fiecare parte a soselei, cota terenului la 3..40 m fata de
##      linia marii, si daca punctul cade in laguna. Spune de ce parte e marea
##      libera si de ce parte golful.
##   2. SENS: `travel_dir` fata de dreapta masinii (produs scalar).
##   3. IMPINGERE: o masina REALA, oprita pe axa, sub creasta; semnul vitezei
##      laterale castigate fata de dreapta ei. Fara aceasta, `travel_dir` poate
##      fi corect si forta, oglindita (sau invers).

var _track: Track
var _expect: String = ""
var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	var only := 20
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--expect="):
			_expect = arg.trim_prefix("--expect=")
	_track = (load("res://scenes/tracks/Track%02d.tscn" % only) as PackedScene).instantiate() as Track
	add_child(_track)
	for i in 6:
		await get_tree().physics_frame
	await _run()


func _run() -> void:
	var waves: Array[WaveSurge] = []
	for node in _track.get_children():
		if node is WaveSurge:
			waves.append(node)
	print("valuri: %d" % waves.size())
	for w in waves:
		await _one(w)
	print("")
	print("VERDICT: ", "PICAT" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _one(w: WaveSurge) -> void:
	var anchor: Vector3 = w.get("_anchor")
	var idx := _track.closest_index_global(anchor)
	var baked: PackedVector3Array = _track.baked
	var n := baked.size()
	var dir := baked[(idx + 4) % n] - baked[idx]
	dir.y = 0.0
	dir = dir.normalized()
	var right := dir.cross(Vector3.UP).normalized()
	var sea_y: float = _track._sampler.mean_road_y() + _track.sea_level_offset
	var lagoon := PackedVector2Array(_track._lagoon_points())
	print("val la frac %.3f, ancora (%.0f, %.0f), linia marii y=%.2f, sosea y=%.2f" % [
		_track.frac_at(idx), anchor.x, anchor.z, sea_y, anchor.y])
	for s in [-1, 1]:
		var line := "  %s: " % ("stanga" if s < 0 else "dreapta")
		for d: float in [3.0, 8.0, 15.0, 25.0, 40.0]:
			var p: Vector3 = anchor + right * float(s) * d
			var gy: float = _track._sampler.ground_y(p.x, p.z)
			var inl := lagoon.size() > 2 and Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), lagoon)
			line += "%2.0fm: %+.1f%s  " % [d, gy - sea_y, "L" if inl else ""]
		print(line, "(cota fata de mare; L = in laguna)")
	var td: Vector3 = w.travel_dir
	var dr := td.dot(right)
	var going := "spre dreapta (vine din stanga)" if dr > 0.0 else "spre stanga (vine din dreapta)"
	print("  creasta merge %s  (travel_dir . dreapta = %+.2f)" % [going, dr])
	if _expect == "left":
		_check(dr < -0.9, "creasta merge spre stanga, din dreapta masinii")
	elif _expect == "right":
		_check(dr > 0.9, "creasta merge spre dreapta, din stanga masinii")

	# --- impingerea, pe o masina reala ---------------------------------------
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	car.track = _track
	_track.add_child(car)
	car.global_position = anchor + Vector3.UP * 0.7
	car.look_at(anchor + dir, Vector3.UP)
	car.road_index = idx
	car.race_active = false
	for i in 20:
		await get_tree().physics_frame
	# Creasta chiar peste masina: offset 0 -> t/span = 0.5.
	var period: float = WaveSurge.PERIOD
	var span: float = WaveSurge.ON_ROAD_FRAC + WaveSurge.LEAD_TIME / period
	var phase: float = w.get("phase")
	w.set("_time", period * (span * 0.5 - phase) - 0.5)
	var peak := 0.0
	var v0 := car.velocity.dot(right)
	var disp := 0.0
	for i in 120:
		await get_tree().physics_frame
		var lat := (car.global_position - anchor).dot(right)
		if absf(lat) > absf(disp):
			disp = lat
		var dv := car.velocity.dot(right) - v0
		if absf(dv) > absf(peak):
			peak = dv
	print("  impingere laterala (dreapta masinii): %+.2f m/s; deplasare maxima %+.1f m (semilatime drum %.1f)"
		% [peak, disp, _track.width_at(_track.frac_at(idx))])
	_check(absf(peak) > 1.0, "valul chiar impinge masina lateral")
	if _expect == "left":
		_check(peak < 0.0, "impingerea e spre STANGA masinii")
	elif _expect == "right":
		_check(peak > 0.0, "impingerea e spre DREAPTA masinii")
	car.queue_free()
	await get_tree().physics_frame
