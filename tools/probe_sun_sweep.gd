extends Node
## POI D, runda 4 — BALEIEREA CONTINUA a insoririi carosabilului.
##
## Criticul rundei 3 a aratat ca ProbePete masoara noua fractii alese, iar cele
## noua cadeau EXACT pe portile de lumina: raporta mediana 120.6 pe un drum
## care in captura la fractia hero avea mediana 20.8, cu 86.5% din banda sub
## luminanta 45. Diagnostic corect: culoarul de coroane functiona, dar numai in
## dreptul portilor, care sunt la 34 m una de alta.
##
## Deci sonda asta NU esantioneaza fractii. Baleiaza CONTINUU banda din ZoneD
## la pas <= STEP metri, calculeaza pentru fiecare punct daca e la soare
## (geometric, pe sfere de coroana — coroanele au coliziune "trunk", deci
## intersect_ray e orb la ele), si raporteaza CEA MAI PROASTA fereastra
## glisanta de WIN metri, nu media.
##
##   godot --headless --path . res://tools/ProbeSunSweep.tscn -- --track=7
##
## Criteriu (cerut de critic): minimul procentului de insorire pe orice
## fereastra de 20 m >= 28%. Adaug si plafonul: nicio fereastra peste 92%,
## altfel tinta se plateste transformand padurea in poiana (referinta e
## PESTRITA, nu deschisa) — memoria `tinta-pe-o-axa-se-atinge-pe-axa-aia`.
const F_IN := 0.196
const F_OUT := 0.339
const STEP := 2.5   # pas pe traseu, in metri (criticul cere <= 5)
const WIN := 20.0   # fereastra glisanta, in metri
const LAT := 5      # esantioane pe latimea benzii
const MIN_SHARE := 0.28
const MAX_SHARE := 0.92

const CROWN_R := {"fig_tree": 5.6, "fever_tree": 4.4, "acacia_umbrella_a": 5.0}
const CROWN_Y := {"fig_tree": 0.72, "fever_tree": 0.78, "acacia_umbrella_a": 0.85}
const MODEL_H := {"fig_tree": 13.0, "fever_tree": 10.12, "acacia_umbrella_a": 7.0}

var _track: Node3D
var _sun_to: Vector3
var _crowns: Array[PackedFloat32Array] = []


func _ready() -> void:
	await get_tree().process_frame
	var ti := 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			ti = GameState.resolve_track_index(int(a.split("=")[1]))
	_track = (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate()
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sun: DirectionalLight3D = null
	for c in _track.find_children("*", "DirectionalLight3D", true, false):
		sun = c as DirectionalLight3D
		break
	_sun_to = (sun.global_transform.basis.z).normalized()
	if _sun_to.y < 0.0:
		_sun_to = -_sun_to
	print("spre soare = %.3f,%.3f,%.3f (elevatie %.1f grade)" % [
		_sun_to.x, _sun_to.y, _sun_to.z, rad_to_deg(asin(_sun_to.y))])
	_collect()
	print("coroane in ZoneD: %d" % _crowns.size())

	# baleiere continua pe lungime de traseu
	var n: int = _track.baked.size()
	var dists: PackedFloat32Array = _track._dists
	var total: float = float(dists[n])
	var d0 := F_IN * total
	var d1 := F_OUT * total
	var samples: Array[float] = []    # fractiunea insorita a fiecarei sectiuni
	var pos_d: Array[float] = []
	var d := d0
	while d <= d1:
		var i := _idx_at(d, dists, n)
		var p: Vector3 = _track.baked[i]
		var half: float = _track.width_at_index(i)
		var sd: Vector3 = _track._side_at(i)
		var lit := 0
		for k in LAT:
			var t := (float(k) / float(LAT - 1)) * 2.0 - 1.0
			var hp: Vector3 = p + sd * (t * half * 0.8) + Vector3(0, 0.15, 0)
			if not _shaded(hp):
				lit += 1
		samples.append(float(lit) / float(LAT))
		pos_d.append(d)
		d += STEP
	print("esantioane pe traseu: %d (pas %.1f m, %d pe latime)" % [
		samples.size(), STEP, LAT])

	# ferestre glisante de WIN metri
	var w: int = int(round(WIN / STEP))
	var worst := 2.0
	var worst_d := 0.0
	var best := -1.0
	var best_d := 0.0
	var bad := 0
	var wins := 0
	var i2 := 0
	while i2 + w <= samples.size():
		var s := 0.0
		for k in w:
			s += samples[i2 + k]
		var sh := s / float(w)
		wins += 1
		if sh < worst:
			worst = sh
			worst_d = pos_d[i2]
		if sh > best:
			best = sh
			best_d = pos_d[i2]
		if sh < MIN_SHARE or sh > MAX_SHARE:
			bad += 1
			if bad <= 12:
				print("  fereastra la frac %.3f (d=%.0f m): insorit %.0f%% <-- PICA" % [
					pos_d[i2] / total, pos_d[i2], sh * 100.0])
		i2 += 1
	var mean := 0.0
	for s2 in samples:
		mean += s2
	mean /= float(samples.size())
	print("ferestre de %.0f m: %d, din care pica %d" % [WIN, wins, bad])
	print("CEA MAI PROASTA fereastra: %.0f%% la frac %.3f (cere >= %.0f%%)" % [
		worst * 100.0, worst_d / total, MIN_SHARE * 100.0])
	print("cea mai deschisa fereastra: %.0f%% la frac %.3f (cere <= %.0f%%)" % [
		best * 100.0, best_d / total, MAX_SHARE * 100.0])
	print("media pe toata felia: %.0f%%" % (mean * 100.0))
	print("VERDICT %s" % ("OK" if bad == 0 else "PICA"))
	get_tree().quit()


func _idx_at(dist: float, dists: PackedFloat32Array, n: int) -> int:
	var lo := 0
	var hi := n
	while lo < hi:
		var mid := (lo + hi) / 2
		if float(dists[mid]) < dist:
			lo = mid + 1
		else:
			hi = mid
	return clampi(lo, 0, n - 1)


func _collect() -> void:
	var zone := _track.find_child("ZoneD_PadureaDeCeata", true, false)
	if zone == null:
		print("ATENTIE: nu gasesc ZoneD_PadureaDeCeata")
		return
	for c in zone.get_children():
		var nm := str(c.name)
		var mdl := ""
		if nm.begins_with("smochin"):
			mdl = "fig_tree"
		elif nm.begins_with("febra"):
			mdl = "fever_tree"
		elif nm.begins_with("acacie"):
			mdl = "acacia_umbrella_a"
		else:
			continue
		var t: Transform3D = (c as Node3D).global_transform
		var scl: float = t.basis.get_scale().y
		_crowns.append(PackedFloat32Array([t.origin.x,
			t.origin.y + float(MODEL_H[mdl]) * float(CROWN_Y[mdl]) * scl,
			t.origin.z, float(CROWN_R[mdl]) * scl]))


func _shaded(hp: Vector3) -> bool:
	for cr in _crowns:
		var c := Vector3(cr[0], cr[1], cr[2])
		var r: float = cr[3]
		var oc := c - hp
		var tca := oc.dot(_sun_to)
		if tca <= 0.0:
			continue
		if oc.length_squared() - tca * tca <= r * r:
			return true
	return false
