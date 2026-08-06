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
	# DRUM DE PAMANT, nu asfalt. A doua abatere a acestei piste de la Okinawa v2
	# (dupa Stramtoarea Kaiun) si prima care schimba SUPRAFATA pe care se conduce.
	#
	# Traseul, cotele si latimea raman neatinse — deci si scenografia, si tot ce
	# se aseaza de mana. Se schimba doar din ce e facut drumul, iar de acolo curg,
	# automat: laterita rosie in loc de asfalt racoros, zero marcaje pictate,
	# poteca batatorita pe tot turul in loc de urme doar in viraje, si masini care
	# scot praf si lasa urme cat timp ruleaza, nu doar cand derapeaza.
	#
	# De ce merita: pe o insula de nisip coraligen, panglica de asfalt era
	# singurul lucru din cadru care venea din alta lume. Vezi Track.road_surface
	# pentru ce anume atarna de linia asta.
	road_surface = "dirt"


## ############################################################################
## STRAMTOAREA KAIUN: canalul cu pod mobil de pe coasta de vest.
##
## Singura abatere a acestei piste de la Okinawa v2, si prima care schimba
## LUMEA, nu doar decorul asezat de mana. Traseul ramane neatins — nici un punct
## de control mutat, nici o cota schimbata — deci scenografia mostenita si toate
## fractiile ei raman valabile. Ce se schimba e insula: primeste o taietura.
##
## [b]De ce aici[/b]. Cerinta a fost „pe partea opusa fata de unde avem apa
## acum", iar apa de acum e digul de start: fractiile 0.93..0.05, la SUD, cu
## soseaua la 1.6 m peste valuri. Sonda de tarm (probe_shore --track=8) spune
## unde se poate raspunde la asta:
##   - nordul geografic e creasta, la +27 m — acolo un canal ar fi o prapastie
##     cu apa pe fund, nu o stramtoare;
##   - coasta de vest, 0.28..0.34, e punctul cel mai DEPARTE de apa din tot
##     turul (86-90 m pana la larg, 103-116 m pana la laguna), e dreapta pe
##     100 m si sta la ~7 m, adica 8.5 m peste nivelul marii.
## Deci: locul in care insula nu are apa deloc, si in care soseaua sta exact
## cu „putin mai multa elevatie" decat pe dig. Apa nu se cauta, se sapa — un
## senal taie istmul de la larg pana in laguna, si drumul il sare pe pod.
##
## [b]De ce nu e scurtatura, ci soseaua principala[/b]. Insula e un INEL, deci
## convexa aproape peste tot: orice coarda intre doua fractii trece pe uscat,
## prin interior, iar cele care chiar trec peste apa taie 300+ m dintr-un tur de
## 1800 (masurat in track07.gd, la asezarea pragului de corali). Adica nu exista
## loc pentru o a doua sosea peste apa care sa fie si atractiva, si cinstita. Si
## e mai bine asa: cerinta spunea „trebuie sa intrerupem track-ul", iar un pod
## pe care il ia toata lumea, in fiecare tur, chiar il intrerupe.
##
## Cifrele: gol de 12 m intre buze, rampe de 1.6 m pe 5 m (17.7°), deci pragul
## de trecere iese pe la 24 m/s — 71% din viteza de varf de baza. Cine merge
## tare nici nu simte podul; cine a ridicat piciorul sau a fost imbrancit
## inainte de el inoata. Verificate in motor cu tools/probe_bridge.gd, nu
## calculate pe hartie: acolo se citeste golul OBTINUT (capetele lui cad pe
## puncte coapte, deci nu poate fi exact 12) si degajarea reala sub travee.
func _channel_specs() -> Array[Dictionary]:
	return [{
		"frac": 0.310,
		"label": "Stramtoarea Kaiun",
		"gap": 12.0,
		# 52 m de apa: sub ~40 m nu mai citeste a senal navigabil, ci a sant, iar
		# corabia de 15 m ar parea prinsa intre maluri.
		"water_half": 26.0,
		"bank": 20.0,
		# Fundul la 13 m sub sosea, adica ~4.5 m de apa peste el. Peste pragul de
		# plutire al corabiei si mult sub Track.SEA_REEF_DEPTH, deci senalul iese
		# turcoaz ca laguna, nu bleumarin ca largul.
		"depth": 13.0,
		# Pana la larg sunt 90 m si pana la laguna 116: cu 200 m in fiecare parte
		# taietura ajunge in amandoua si stramtoarea chiar leaga doua ape.
		"reach": 200.0,
		"fade": 55.0,
	}]
