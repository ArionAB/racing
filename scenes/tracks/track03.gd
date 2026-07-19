@tool
extends Track
## Pista 3 — "Muntele": lata si rapida, cu o urcare uriasa (18m) si o
## coborare care te arunca in aer peste creste. Gimmick: doua rampe si
## altitudinea insasi — turbo pe urcare sau airtime pe coborare, alegi.

func _init() -> void:
	track_name = "Muntele"
	half_width = 8.0

func _points() -> Array[Vector3]:
	return [
		Vector3(0, 0, 0),        # start la ses, mers spre +X
		Vector3(95, 0, 5),
		Vector3(175, 3, -15),    # incepe urcarea
		Vector3(245, 10, -60),
		Vector3(285, 16, -130),  # serpentina de munte
		Vector3(255, 18, -200),  # varful
		Vector3(175, 12, -240),  # coborare rapida
		Vector3(90, 14, -260),   # contra-panta (aer la viteza!)
		Vector3(5, 16, -240),
		Vector3(-65, 10, -190),  # picajul
		Vector3(-115, 4, -120),
		Vector3(-105, 0, -55),
		Vector3(-50, 0, -10),
	]

func _ramp_fracs() -> Array[float]:
	return [0.05, 0.52]
