extends Node
## Cauta cea mai buna asezare a blocului Liziba: pentru fiecare fractie-centru
## si fiecare lungime de hol, cat de mult se abate axa soselei de la axa
## holului (in coordonate MODEL, unde nucleele stau la |x| 2.97..4.0).
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var L := r.length()
	print("centru  scaleZ  jum.hol  | abatere max a AXEI (m lume) | necesar model-x liber")
	for fc: float in [0.878, 0.881, 0.884, 0.8855, 0.888, 0.891]:
		for sz: float in [1.0, 1.2, 1.4]:
			var halfz := 13.62 * sz
			var ic := int(round(fc * float(n))) % n
			var c := r.baked[ic]
			var fwd := (r.baked[(ic + 1) % n] - r.baked[(ic - 1 + n) % n]).normalized()
			fwd.y = 0.0
			fwd = fwd.normalized()
			var sidev := Vector3(fwd.z, 0.0, -fwd.x)
			var dev := 0.0
			var d := -halfz
			while d <= halfz:
				# punctul de pe axa soselei la distanta d de-a lungul rutei
				var idx := ic + int(round(d / L * float(n)))
				var p := r.baked[(idx % n + n) % n]
				var rel := p - c
				dev = maxf(dev, absf(rel.dot(sidev)))
				d += 1.0
			print("%.4f  %.1f    %5.1f    | %6.2f   -> %6.2f" % [
				fc, sz, halfz, dev, dev + 7.0 + 0.15])
	get_tree().quit()
