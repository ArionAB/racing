@tool
extends "res://scenes/tracks/track07.gd"
## Pista 8 — "Okinawa manual": Okinawa v2 la firul ierbii, ca banc de lucru
## pentru decor asezat DE MANA.
##
## Aceeasi lume, pana la ultimul metru: traseu, cote, laguna, scurtatura,
## creasta, rapi, val — toate mostenite din track07.gd, nu copiate. Copierea
## celor 36 de puncte de control ar fi insemnat doua adevaruri despre acelasi
## traseu, iar cel de-al doilea ar fi ramas in urma la prima ajustare — exact
## capcana pe care o descrie track07.gd despre cotele derivate din fractii.
##
## `world_seed_name` e singurul lucru care NU se schimba odata cu numele, si
## conteaza: faza dunelor, imprastierea decorului si falezele se seamana din
## numele pistei (vezi Track._world_seed). Fara linia aia, "Okinawa manual" ar
## fi primit alt relief in campul departat si alt decor, deci un obiect asezat
## cu mouse-ul aici ar fi plutit sau s-ar fi ingropat pe Okinawa v2 — adica
## fix opusul rostului acestei piste.
##
## CUM SE LUCREAZA PE EA: docs/decor_manual.md. Pe scurt — deschizi
## Track08.tscn (scriptul e @tool, deci pista se construieste in editor),
## adaugi sub radacina un Node3D `DecorManual` cu scenes/props/world_prop.gd,
## si tragi GLB-uri sub el. Tot ce e salvat in .tscn are `owner` setat, deci
## supravietuieste lui rebuild(); tot ce genereaza codul nu, si se sterge.
##
## DE STIUT: decorul procedural mostenit de la Okinawa v2 ramane pornit si NU
## te vede — se poate suprapune peste ce asezi. Daca vrei panza goala, cere
## un intrerupator de decor; nu l-am inventat aici ca sa nu difere de v2 in
## tacere.

func _init() -> void:
	# super() NU e optional, si tacerea lui a costat o masuratoare: fara el,
	# _init-ul din track07.gd nu ruleaza deloc, deci pista ramane pe valorile
	# implicite ale lui Track — tema "forest" in loc de "island". Geometria iese
	# identica (aia vine din metode, nu din constructor) si sondele de traseu dau
	# aceleasi cifre, dar pista pierde marea, laguna si decorul de banda: sonda
	# de scena numara 232 de mesh-uri in loc de 741.
	super()
	track_name = "Okinawa manual"
	# Numele s-a schimbat, lumea nu.
	world_seed_name = "Okinawa v2"
