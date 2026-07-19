@tool # @tool NU se mosteneste — fiecare pista il declara ca sa apara in editor
extends Track
## Pista 1 — "Dunele": desert. Dreapta de start cu rampa, urcare pe deal,
## coborare in viraj, chicane la ses, al doilea deal abrupt. Gimmick:
## bariera mobila inainte de al doilea deal. Decor: cactusi, mese de
## piatra rosie, dune la orizont.

func _init() -> void:
	track_name = "Dunele"
	apply_theme("desert")

func _points() -> Array[Vector3]:
	return [
		Vector3(0, 0, 0),        # start/finish, mers spre +X
		Vector3(95, 0, 5),
		Vector3(165, 3, -10),
		Vector3(225, 7, -45),    # urcare pe dreapta
		Vector3(240, 9, -105),   # creasta
		Vector3(205, 10, -150),  # intrarea in hairpin
		Vector3(150, 8, -135),   # HAIRPIN — intoarcere stransa spre interior
		Vector3(120, 6, -95),    # iesirea din hairpin, coborare
		Vector3(85, 5, -115),    # S-ul: stanga...
		Vector3(95, 6, -165),    # ...dreapta...
		Vector3(55, 7, -200),    # ...stanga, urcand spre coltul de sus
		Vector3(-10, 5, -215),
		Vector3(-70, 6, -180),   # top-left
		Vector3(-105, 3, -120),
		Vector3(-95, 1, -60),    # coborare rapida spre start
		Vector3(-45, 0, -12),
	]

func _ramp_fracs() -> Array[float]:
	return [0.055]

func _hazard_fracs() -> Array[float]:
	return [0.58]
