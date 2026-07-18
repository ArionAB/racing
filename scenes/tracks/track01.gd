extends Track
## Pista 1: dreapta de start cu rampa, urcare pe deal, coborare in viraj,
## chicane la ses, al doilea deal abrupt. Gimmick: bariera mobila inainte
## de al doilea deal.

func _points() -> Array[Vector3]:
	return [
		Vector3(0, 0, 0),        # start/finish, mers spre +X
		Vector3(80, 0, 0),
		Vector3(150, 2, -10),
		Vector3(210, 7, -40),    # urcare pe deal
		Vector3(240, 9, -95),    # creasta
		Vector3(215, 5, -150),   # coborare in viraj
		Vector3(155, 1, -180),
		Vector3(80, 0, -200),
		Vector3(0, 4, -190),     # al doilea deal, mai abrupt
		Vector3(-70, 6, -150),
		Vector3(-110, 2, -85),
		Vector3(-88, 0, -28),
		Vector3(-40, 0, -6),
	]

func _ramp_fracs() -> Array[float]:
	return [0.055]

func _hazard_fracs() -> Array[float]:
	return [0.58]
