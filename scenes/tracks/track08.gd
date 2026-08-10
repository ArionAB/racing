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
	# DRUM DE NISIP, nu asfalt. A doua abatere a acestei piste de la Okinawa v2
	# (dupa Stramtoarea Kaiun) si prima care schimba SUPRAFATA pe care se conduce.
	#
	# Traseul, cotele si latimea raman neatinse — deci si scenografia, si tot ce
	# se aseaza de mana. Se schimba doar din ce e facut drumul, iar de acolo curg,
	# automat: nisip batatorit in loc de asfalt racoros, zero marcaje pictate,
	# zero urme desenate dinainte, si masini care scot praf si lasa brazde cat
	# timp ruleaza, nu doar cand derapeaza.
	#
	# De ce merita: pe o insula de nisip coraligen, panglica de asfalt era
	# singurul lucru din cadru care venea din alta lume. Vezi Track.road_surface
	# pentru ce anume atarna de linia asta.
	road_surface = "dirt"


## ############################################################################
## DIGUL DE START: apa de pe asfalt vine din mare, nu dintr-o teava.
##
## A treia abatere de la Okinawa v2, si prima care schimba un HAZARD. Traseul,
## cotele si fractia raman neatinse: se schimba doar ce anume uda drumul la
## 0.975.
##
## [b]De ce[/b]. Okinawa v2 pune acolo un `WaterHose` — o conducta sparta — si
## comentariul ei zice, cuvant cu cuvant, „valul care spala digul". Adica
## intentia era deja marea; furtunul era doar ce exista in cod atunci. Pe insula
## teava nici nu se vede (`hose_model: ""` in tema island), deci sectorul arata
## azi ca un jet de apa care tasneste din nimic peste un dig de tetrapozi.
##
## [b]Ce se schimba pentru cel care conduce[/b], si asta e adevaratul motiv:
## conducta uda mereu, deci digul era o TAXA — treci alunecand, indiferent ce
## faci. Valul uda doar cat trece, deci digul devine o DECIZIE: intri acum, sau
## ridici piciorul o secunda si intri pe uscat. Ultima portiune a turului, exact
## unde se decid depasirile, capata astfel o fereastra. E faza 2 din #106, luata
## aici pe pista de lucru — pe Okinawa v2 banda permanenta ramane, ca sa se poata
## simti diferenta una langa alta.
func _hose_fracs() -> Array[float]:
	return []


func _wave_fracs() -> Array[float]:
	return [0.975] # aceeasi fractie pe care o avea furtunul


## ############################################################################
## TESTOASA DE PE DRUM: bariera mobila de la 0.256 nu mai e o barca.
##
## A patra abatere de la Okinawa v2, si a doua care schimba un hazard. Fractia,
## amplitudinea maturarii si perioada raman ale lui `_hazard_fracs()` din
## track07.gd — se schimba doar CE anume traverseaza soseaua.
##
## [b]De ce[/b]. Sabani a ajuns `hazard_model` fiindca era barca pe care o aveam
## deja (#107), si a ramas ca „targ ita peste causeway" — o explicatie care merge
## doar cat timp hazardul chiar sta langa apa. La 0.256 e coasta de vest, adica
## exact bucata din tur pe care sonda de tarm o da drept punctul cel mai DEPARTE
## de apa (86-90 m pana la larg). O barca de 5 m care aluneca inainte si inapoi
## la 90 m de mal nu are nicio poveste in spate; o testoasa care traverseaza spre
## plaja are, si e a insulei.
##
## [b]Ce se schimba pentru cel care conduce: nimic[/b], si asta e intentia.
## Masurat cu o sonda pe ambele piste, nu presupus: barca e 5.01 x 1.02 m si
## matura +/-4.50 m; testoasa e 3.60 x 3.63 m si matura +/-5.19 m. In amandoua
## cazurile marginea obstacolului ajunge exact in marginea soselei (5.19 + 1.81 =
## 4.50 + 2.50 = 7.0 = `half_width`), fiindca `SlidingHazard._clamp_travel` cere
## chiar asta si isi taie singur cursa dupa cat de mare e modelul. Perioada iese
## putin mai lunga (2.72 s fata de 2.35 s) tot din asta — cursa e mai lunga la
## acelasi plafon de viteza de maturare, deci nu obstacolul a incetinit.
##
## Si o cota care merita retinuta: testoasa e cat o masina (3.60 x 0.99 m fata de
## 3.80 x 1.00 m cutia unei masini). Nu e un bolovan care te sterge, e un corp de
## marimea ta pe drum.
##
## `hazard_face_travel` NU e cosmetic, e acelasi soi de steag ca `hazard_roll:
## false` de la barca: un animal are un „inainte", deci trebuie sa se uite
## incotro merge. Vezi Track._build_hazard.
func _theme_overrides() -> Dictionary:
	return {
		# Panglica rosie de pe margini se stinge, coliziunea ei ramane (vezi
		# _build_walls): pe un drum de nisip de coasta, o bariera continua de
		# santier era singurul lucru din cadru care nu apartinea insulei.
		# Bariera VIZUALA e treaba scenografiei si a decorului manual: gard de
		# lemn pe buza lagunei, ziduri gusuku spre interior.
		"wall_visible": false,
		# Umerii isi trag implicit culoarea din nisipul de coral intunecat 25%
		# — pe langa drumul OCRU iesea o bordura gri de agregat, singura dunga
		# rece dintre doua suprafete calde. Pamant batut, putin mai inchis
		# decat marginea drumului, ca umarul sa citeasca drept continuarea
		# prafuita a drumului, nu alt material.
		"dust_color": Color(0.62, 0.50, 0.33),
		# Verdele campului, impins spre iarba grasa din referinta: tinta
		# vizuala e pajistea densa, iar pastelul mostenit citea a fanata.
		# Nuanta se calibreaza pe snapshot (--gamecam), nu pe hex-ul din
		# paleta — lumina insulei (soare 1.5 / expunere 1.0) schimba pixelul.
		"inland_tint": Color(0.30, 0.54, 0.19),
		"inland_strength": 0.95,
		# Lumina din referinta (#207): soare de dupa-amiaza tarzie, nu de
		# amiaza. Elevatia coboara 42° -> 33° (umbrele se lungesc ~1.4x, dealul
		# capata volum), culoarea se incalzeste spre auriu, iar contrastul urca
		# putin — pastelul spalat era jumatate din senzatia de "lume goala".
		# Saturatia NU se atinge (compensarea apei e masurata pe 1.18).
		"sun_rotation_deg": Vector3(-33, 135, 0),
		"sun_color": Color(1.0, 0.93, 0.8),
		"adjust_contrast": 1.12,
		"hazard_model": "res://assets/models/props/sea_turtle.glb",
		"hazard_face_travel": true,
		# Mostenite explicit de la tema, ca sa se citeasca tot contractul
		# hazardului dintr-un loc: nu se rostogoleste (i-ar zbura carapacea peste
		# cap), e la scara ei reala din Blender si sta pe atlasul de paleta —
		# fara `hazard_classes`, fiindca nicio clasa de material nu e o carapace.
		"hazard_roll": false,
		"hazard_scale": 1.0,
		"hazard_classes": {},
	}


## ############################################################################
## PAJISTEA SI PIETRELE: densitatea din imaginea de referinta, declarata, nu
## asezata cu mouse-ul.
##
## Referinta drumului de coasta arata doua lucruri pe care Okinawa v2 nu le
## are: iarba VIE (smocuri, flori, tufe pana in buza drumului) si pietre din
## belsug, in ciorchini, pe fasia dintre drum si garduri. Ambele sunt tipare
## STATISTICE, nu compozitii — exact felul de lucru pentru grove/edge, nu
## pentru decor manual: se reface la fiecare rebuild, se coace in MultiMesh,
## si isi gaseste singur pamantul cu ground_y.
##
## `above_sea` la 1.6 e ce tine pajistea PE CAMP: sub BEACH_SAND_TOP (1.4 m)
## terenul e plaja, si un smoc de iarba grasa pe nisipul spalat de valuri ar
## fi la fel de nelalocul lui ca panglica rosie pe care tocmai am stins-o.
## Plaja isi pastreaza imprastierea ei (island_scatter din benzile mostenite).
func _scenography() -> Array[Dictionary]:
	const M := "res://assets/models/"
	var specs := super._scenography()
	# Decorul care a fost asezat cu mouse-ul, promovat piesa cu piesa (#201):
	# aceleasi coordonate si orientari, dar y-ul se re-deriva din ground_y la
	# fiecare rebuild si totul intra in bake-ul MultiMesh. DecorManual ramane
	# in .tscn ca sketchpad GOL pentru compozitii noi. Preload, nu class_name:
	# sondele headless ruleaza cu cache-ul de clase globale rece, si un nume
	# global nedeclarat inca ar rupe parse-ul intregii piste.
	specs.append_array(
		preload("res://scenes/tracks/track08_manual_specs.gd").specs())
	# Speciile pajistii, declarate O DATA: covorul e taiat in trei lanuri cu
	# goluri intre ele (#209, ritmul plin/gol din style_bible §7) si toate
	# trei trag din aceeasi lista. Speciile ieftine duc greul (smocuri,
	# ~100-250 tri); florile si hibiscusul sunt accentele, nu umplutura.
	var pajiste_species: Array = [
		{"path": M + "rocks/island_scatter.glb",
			"picks": ["Beach_Grass"], "weight": 3.0,
			"scale": [0.9, 1.5], "sink": 0.08},
		{"path": M + "plants/megakit_plants.glb",
			"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
			"weight": 4.0, "scale": [0.8, 1.4], "sink": 0.1},
		{"path": M + "plants/grass_tuft_small.glb", "weight": 2.0,
			"scale": [0.8, 1.3], "sink": 0.08},
		{"path": M + "plants/grass_tuft_large.glb", "weight": 1.2,
			"scale": [0.8, 1.2], "sink": 0.1},
		{"path": M + "flowers/flowers_orange.glb", "weight": 1.2,
			"scale": [0.9, 1.3], "sink": 0.06},
		{"path": M + "flowers/flowers_white.glb", "weight": 0.8,
			"scale": [0.9, 1.3], "sink": 0.06},
		{"path": M + "plants/hibiscus_bush.glb", "weight": 0.8,
			"scale": [0.7, 1.1], "sink": 0.12},
		# Runda 2 (veg_set2): siluetele care lipseau rotatiei — arcul de
		# feriga, tufa plina cu frunze late, a treia culoare de floare
		# (CORAL_SAND, floare decolorata de soare). Ponderile vechi au
		# scazut ca sa faca loc: piesele noi sunt la fel de scumpe ca
		# florile (~750-800 tri), deci amestecul ramane aproape la acelasi
		# cost mediu, doar mai variat la citire.
		{"path": M + "plants/fern_cluster.glb", "weight": 1.0,
			"scale": [0.8, 1.3], "sink": 0.08},
		{"path": M + "plants/broadleaf_shrub.glb", "weight": 0.6,
			"scale": [0.7, 1.1], "sink": 0.1},
		{"path": M + "flowers/flowers_coral.glb", "weight": 0.6,
			"scale": [0.85, 1.2], "sink": 0.06},
	]
	specs.append_array([
		# --- PAJISTEA: trei lanuri cu goluri intre ele. Golurile cad pe
		# strambatoarea cu pod (0.27-0.315) si pe creasta cu ziduri
		# (0.60-0.655) — acolo scenografia mostenita e deja densa, iar un
		# covor continuu pe tot turul citeste a mocheta, nu a camp.
		{"kind": "grove", "label": "Pajiste", "side": 1.0, "both_sides": true,
			"from": 0.03, "to": 0.27, "off": [1.5, 12.0], "spacing": 3.5,
			"above_sea": 1.6, "clear": 2.0, "species": pajiste_species},
		{"kind": "grove", "label": "Pajiste", "side": 1.0, "both_sides": true,
			"from": 0.315, "to": 0.60, "off": [1.5, 12.0], "spacing": 3.5,
			"above_sea": 1.6, "clear": 2.0, "species": pajiste_species},
		{"kind": "grove", "label": "Pajiste", "side": 1.0, "both_sides": true,
			"from": 0.655, "to": 0.93, "off": [1.5, 12.0], "spacing": 3.5,
			"above_sea": 1.6, "clear": 2.0, "species": pajiste_species},
		# --- PATURILE: flori si iarba LIPITE de gardul de pe buza lagunei si
		# de zidul dinspre mare, pe urcarea de coasta — compozitia-semnatura a
		# referintei: nimic nu creste in mijlocul gazonului, totul se aduna la
		# picioarele a ceva. Offseturile stau cu ~0.5 m inauntrul liniei
		# gardului (manual, la ~2.5-3.5 m), deci paturile rasar la baza lui.
		{"kind": "edge", "label": "Paturi_gard", "side": 1.0,
			"from": 0.495, "to": 0.585, "off": 2.0, "spacing": 4.0,
			"jitter": 0.5, "min_ground": 0.8,
			"path": M + "flowers/flowers_orange.glb",
			"scale": [0.9, 1.25], "face": "random", "sink": 0.06,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_A", "Tuft_B"], "count": [1, 2],
				"radius": 1.1, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Paturi_gard", "side": 1.0,
			"from": 0.505, "to": 0.578, "off": 2.6, "spacing": 9.0,
			"jitter": 0.6, "min_ground": 0.8,
			"path": M + "flowers/flowers_white.glb",
			"scale": [0.85, 1.15], "face": "random", "sink": 0.06},
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.452, "to": 0.60, "off": 1.8, "spacing": 4.0,
			"jitter": 0.5, "min_ground": 0.8,
			"path": M + "plants/megakit_plants.glb",
			"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
			"scale": [0.9, 1.4], "face": "random", "sink": 0.1},
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.46, "to": 0.595, "off": 2.7, "spacing": 8.0,
			"jitter": 0.8, "min_ground": 0.8,
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.6, 0.9], "face": "random", "sink": 0.12},
		# Florile lipseau CU TOTUL pe latura zidului (-1): referinta are
		# accente portocalii pe ambele parti ale urcarii, nu doar la gard.
		# Portocaliul conduce (pas 5 vs 10), albul doar puncteaza.
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.462, "to": 0.592, "off": 2.2, "spacing": 5.0,
			"jitter": 0.5, "min_ground": 0.8,
			"path": M + "flowers/flowers_orange.glb",
			"scale": [0.85, 1.2], "face": "random", "sink": 0.06,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_B", "Tuft_D"], "count": [1, 2],
				"radius": 1.1, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Paturi_gard", "side": -1.0,
			"from": 0.47, "to": 0.585, "off": 3.1, "spacing": 10.0,
			"jitter": 0.6, "min_ground": 0.8,
			"path": M + "flowers/flowers_white.glb",
			"scale": [0.8, 1.1], "face": "random", "sink": 0.06},
		# --- PIETRELE DE MARGINE: semnatura referintei pe urcarea de coasta
		# si pe creasta. Doua siruri decalate pe fiecare latura (off si pas
		# diferite), ca sa citeasca a ciorchini cazuti, nu a margele insirate.
		# Fara coliziune: la 2.8-5 m de margine esti in zona de iertare, nu
		# intr-un slalom nedeclarat (regula benzii `hug` din TrackDecor).
		{"kind": "edge", "label": "Pietre_margine", "side": 1.0,
			"from": 0.44, "to": 0.72, "off": 2.8, "spacing": 6.5,
			"jitter": 1.6, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_01", "Coral_Rock_03", "Coral_Rock_05",
				"Coral_Rock_07"],
			"scale": [0.25, 0.55], "face": "random", "sink": 0.15,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_A", "Tuft_C"], "count": [1, 2],
				"radius": 1.0, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Pietre_margine", "side": 1.0,
			"from": 0.45, "to": 0.71, "off": 4.8, "spacing": 12.0,
			"jitter": 1.8, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_02", "Coral_Rock_04", "Coral_Rock_06",
				"Coral_Rock_08"],
			"scale": [0.4, 0.75], "face": "random", "sink": 0.2},
		{"kind": "edge", "label": "Pietre_margine", "side": -1.0,
			"from": 0.44, "to": 0.72, "off": 3.2, "spacing": 7.0,
			"jitter": 1.6, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_02", "Coral_Rock_05", "Coral_Rock_08"],
			"scale": [0.25, 0.6], "face": "random", "sink": 0.15,
			"skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_B", "Tuft_D"], "count": [1, 2],
				"radius": 1.0, "scale": [0.7, 1.1], "sink": 0.1}},
		{"kind": "edge", "label": "Pietre_margine", "side": -1.0,
			"from": 0.46, "to": 0.70, "off": 5.2, "spacing": 13.0,
			"jitter": 2.0, "min_ground": 0.8,
			"path": M + "rocks/coral_rock.glb",
			"picks": ["Coral_Rock_01", "Coral_Rock_04", "Coral_Rock_06"],
			"scale": [0.45, 0.8], "face": "random", "sink": 0.2},
		# --- CIORCHINII: grupuri gata sculptate (rock_cluster), rare, pe tot
		# campul — punctele grele care ancoreaza covorul marunt al pajistii.
		# Cu fusta de smocuri: piatra care sta pe gazon fara iarba la baza e
		# exact citirea de "obiect pus cu mana" pe care o reparam.
		{"kind": "grove", "label": "Ciorchini_pietre", "side": 1.0,
			"both_sides": true, "from": 0.03, "to": 0.93,
			"off": [4.0, 14.0], "spacing": 34.0, "above_sea": 1.6,
			"clear": 3.5, "skirt": {"path": M + "plants/megakit_plants.glb",
				"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
				"count": [1, 3], "radius": 1.7, "scale": [0.8, 1.3],
				"sink": 0.1},
			"species": [
				{"path": M + "rocks/rock_cluster.glb",
					"picks": ["Cluster_S1", "Cluster_S2", "Cluster_M1"],
					"weight": 3.0, "scale": [0.5, 0.9], "sink": 0.2},
				{"path": M + "rocks/coral_rock.glb",
					"picks": ["Coral_Rock_03", "Coral_Rock_06"],
					"weight": 2.0, "scale": [0.5, 0.9], "sink": 0.25},
			]},
		# --- SUBARBORETUL: sub perdelele de palmieri ale urcarii (M05,
		# 0.44-0.72) v2 are gazon gol; referinta are tufaris marunt sub
		# fiecare coroana. Acelasi amestec ca pajistea, dar pas mai strans
		# si mai aproape de drum — si FARA gol pe 0.60-0.655: acolo pajistea
		# tace ca sa respire zidurile, dar sub copaci golul citeste a chelie.
		# Fara fusta: subarboretul E el insusi covorul, fusta pe vegetatie
		# ar fi geometrie dubla fara castig de citire.
		{"kind": "grove", "label": "Sub_Palmieri", "side": 1.0,
			"both_sides": true, "from": 0.44, "to": 0.72,
			"off": [2.0, 9.0], "spacing": 3.0, "above_sea": 1.6,
			"clear": 2.0, "species": pajiste_species},
		# --- PATURILE DE LA ZIDURI: accente la CAPETELE si la rostul
		# zidului gusuku si ale celor doua tronsoane de gard. Bazele
		# dinspre drum au deja paturi (Paturi_gard, oglindite); ce
		# ramanea gol si se vede din masina sunt exact incheieturile:
		# capetele de zid care se termina brusc in gazon si trecerea
		# dintre cele doua bucati de zid (x 40.8 -> 70.8). Pozitiile
		# sunt DERIVATE din coordonatele zidurilor (track08_manual_specs,
		# perpendiculara din yaw-ul segmentului, spre drum) — nu asezate
		# cu mouse-ul, de aia stau aici si nu in fisierul regenerabil.
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(0.46, -191.33), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.85, 0.85], "sink": 0.12},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(2.1, -190.9), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [1.0, 1.0], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(41.45, -215.30), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [1.0, 1.0], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(42.55, -214.62), "face": "world",
			"path": M + "flowers/flowers_coral.glb",
			"scale": [0.9, 0.9], "sink": 0.06},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(71.50, -239.21), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [1.0, 1.0], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(72.9, -238.3), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.75, 0.75], "sink": 0.12},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(106.26, -262.16), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.85, 0.85], "sink": 0.12},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(107.3, -261.5), "face": "world",
			"path": M + "flowers/flowers_coral.glb",
			"scale": [0.9, 0.9], "sink": 0.06},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(13.64, -176.71), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.7, 0.7], "sink": 0.1},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(49.19, -199.34), "face": "world",
			"path": M + "plants/fern_cluster.glb",
			"scale": [0.95, 0.95], "sink": 0.08},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(79.57, -220.66), "face": "world",
			"path": M + "flowers/flowers_coral.glb",
			"scale": [0.9, 0.9], "sink": 0.06},
		{"kind": "spot", "label": "Paturi_ziduri",
			"world": Vector2(104.46, -239.44), "face": "world",
			"path": M + "plants/hibiscus_bush.glb",
			"scale": [0.8, 0.8], "sink": 0.1},
	])
	# --- VERGE-UL: peretele verde de la umarul drumului. Pajistea incepe la
	# 1.5 m si se rarefiaza spre camp; referinta are un tiv CONTINUU in primul
	# metru, pe AMBELE laturi — el face drumul sa citeasca a taiat prin
	# vegetatie, nu asezat peste ea. Trei straturi pe interval (smocuri des,
	# iarba de plaja mediu, flori portocalii rar) — edge cu picks, ca la
	# Paturi: amestecul se face din spec-uri single-source suprapuse, nu din
	# `species` (edge nu stie de ponderi). Aceleasi trei lanuri si aceleasi
	# goluri ca pajistea (#209): tivul tace si el pe pod si pe creasta.
	# `min_ground` 1.6 = regula plajei de la pajiste (sub BEACH_SAND_TOP nu
	# creste iarba grasa).
	var verge_lanuri: Array[Vector2] = [Vector2(0.03, 0.27),
		Vector2(0.315, 0.60), Vector2(0.655, 0.93)]
	for lan: Vector2 in verge_lanuri:
		for latura: float in [1.0, -1.0]:
			specs.append_array([
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.0, "spacing": 3.2,
					"jitter": 0.3, "min_ground": 1.6,
					"path": M + "plants/megakit_plants.glb",
					"picks": ["Tuft_A", "Tuft_B", "Tuft_C", "Tuft_D"],
					"scale": [0.7, 1.1], "face": "random", "sink": 0.1},
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.2, "spacing": 4.2,
					"jitter": 0.4, "min_ground": 1.6,
					"path": M + "rocks/island_scatter.glb",
					"picks": ["Beach_Grass"],
					"scale": [0.8, 1.3], "face": "random", "sink": 0.08},
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.3, "spacing": 18.0,
					"jitter": 0.4, "min_ground": 1.6,
					"path": M + "flowers/flowers_orange.glb",
					"scale": [0.8, 1.1], "face": "random", "sink": 0.06},
				# veg_set2: tufa lata e silueta de gard viu a tivului —
				# rara, dar ea face "peretele"; coralul e accentul pal
				# dintre portocaliuri. Pasii mari nu sunt zgarcenie: linia
				# tivului are ~2.6 km pe ambele laturi, si la 750-800 tri
				# bucata fiecare metru de pas taiat costa zeci de mii.
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.4, "spacing": 40.0,
					"jitter": 0.5, "min_ground": 1.6,
					"path": M + "plants/broadleaf_shrub.glb",
					"scale": [0.8, 1.15], "face": "random", "sink": 0.1},
				{"kind": "edge", "label": "Verge_Umar", "side": latura,
					"from": lan.x, "to": lan.y, "off": 1.3, "spacing": 55.0,
					"jitter": 0.5, "min_ground": 1.6,
					"path": M + "flowers/flowers_coral.glb",
					"scale": [0.85, 1.15], "face": "random", "sink": 0.06},
			])
	return specs


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
