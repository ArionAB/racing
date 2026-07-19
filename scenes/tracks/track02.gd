@tool
extends Track
## Pista 2 — "Serpentina": ingusta si tehnica, aproape plata, un sir de
## S-uri stranse. Gimmick: DOUA bariere mobile pe sectoarele rapide —
## trebuie sa-ti sincronizezi trecerea de doua ori pe tur. Drift-ul e rege
## aici (si hraneste turbo pentru putinele drepte).

func _init() -> void:
	track_name = "Serpentina"
	half_width = 6.0

func _points() -> Array[Vector3]:
	return [
		Vector3(0, 0, 0),        # start, mers spre +X
		Vector3(75, 0, 5),
		Vector3(130, 0, -25),
		Vector3(160, 1, -70),    # primul S
		Vector3(120, 2, -105),
		Vector3(70, 1, -125),
		Vector3(95, 0, -170),    # al doilea S
		Vector3(145, 1, -205),
		Vector3(110, 3, -250),
		Vector3(40, 2, -265),
		Vector3(-35, 1, -240),   # intoarcerea
		Vector3(-65, 2, -185),
		Vector3(-95, 1, -130),
		Vector3(-85, 0, -70),
		Vector3(-45, 0, -18),
	]

func _hazard_fracs() -> Array[float]:
	return [0.32, 0.78]
