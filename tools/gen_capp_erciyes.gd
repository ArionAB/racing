extends Node
## Generator RUNDA 33 pentru POI B: CORNISE PE FLANCUL ERCIYES-ULUI.
##
##   godot --path . --rendering-driver vulkan res://tools/GenCappErciyes.tscn
##
## De ce exista, si de ce pe MUNTE si nu pe roca.
##
## Dupa 32 de runde, sonda de detaliu local (tools/bar/detaliu_local.py) da:
##     hornurile noastre, fata luminata ... 4.03
##     soseaua noastra, aproape ........... 3.98
##     REFERINTA, tot cadrul .............. 3.85
##     REFERINTA, cea mai plata dala ...... 1.63   <- pragul
##     FLANCUL MUNTELUI, dreapta sus ...... 1.12   <- singura dala sub prag
## Adica roca si asfaltul BAT deja referinta; singurul lucru sub ea e conul de
## fundal. Rundele 20-32 au esuat fiindca masurau roca, care era deja buna.
##
## ATRIBUIRE, nu impresie. Sonda de cadru (ProbeFlanc) a proiectat toate
## instantele de orizont in dala care pica (r0 c3, x 768..1024, y 0..144):
##     @Node3D@128/Erciyes ... acopera 100% din dala
## Restul instantelor: 0%. Deci defectul e UN obiect, si stim care.
##
## GEOMETRIA CONULUI, masurata pe triunghiuri (ProbeErciyes), nu presupusa:
##     origine lume 249.8, 9.6, 123.8   scara 1.557
##     axa xz 252.3, 146.8              y 9.6 .. 289.8 (280 m inaltime)
##     raza: 108 m la cota 100, 74 la 140, 54 la 160, 26 la 200
## Portiunea care cade in dala: cota 126..207, azimut -167..-114 grade fata de
## axa (53 grade din con, partea dinspre ochi).
##
## DE CE SE POATE VEDEA CE ADAUG, adica de ce nu e munca in ceata. Suprafata
## din dala e la 294..386 m de ochi, iar fog_end e 300 — deci prima socoteala
## spunea "totul dincolo de ceata, contrast zero, orice adaug se inmulteste cu
## zero". Masurat pe pixeli, e FALS: conul citeste 80..85 gri cald, iar ceata
## temei e 184,189,204 (rece, palida). Daca ar fi fost inghitit de ceata ar fi
## avut culoarea CETII. Are 152 de niveluri de ecart si std 24.4 — MAI MULT
## decat cea mai plata dala a referintei (131 / 22.9). Deci suprafata are
## buget de contrast; ce-i lipseste e detaliu LOCAL, exact ce masoara sonda.
##
## SCARA, derivata din unghi: la 294..386 m si FOV vertical 68 pe 720 px, un
## pixel are 0.55..0.72 m. Piesa `cliff_band_module` e 20.3 x 12.4 m, adica
## 17..22 px inaltime pe ecran — se citeste ca treapta, nu ca zgomot. O piesa
## de marimea celor de la marginea drumului ar fi fost sub-pixel acolo.
##
## ZERO MATERIALE NOI: piesa e deja in Track13.tscn (ExtResource 23_cliff),
## aceeasi folosita pe zidul Vaii Rosii. Garda numara materiale, nu piese.
##
## Coliziune "none": e fundal la 300 m, masina n-ajunge niciodata acolo, iar
## un hull per modul ar fi zeci de corpuri degeaba. Scris ENGLEZESTE, fiindca
## world_prop compara sirul cu un tabel englezesc si ce nu se potriveste cade
## pe implicit, adica HULL (capcana masurata la generatorul crestei).

const TRACK := "res://scenes/tracks/Track13.tscn"
const RES := {"rocks/cliff_band_module": "23_cliff"}

## PLASAREA NU MAI FOLOSESTE UN PROFIL RAZA(COTA), si asta e reparatia care a
## costat prima incercare a rundei. Sonda ProbeErciyes masurase raza pe benzi
## de cota si dadea 55..247 m la ACEEASI cota — piesa nu e axisimetrica in
## jurul centroidului, deci "raza la cota y" nu e o functie. Cornisele asezate
## pe cilindrul acela au cazut IN SPATELE conului (316..398 m, cand suprafata
## e la 294..386) si au schimbat exact ZERO pixeli: 23 din 25 module cadeau
## geometric in dala, cu 19..62 px latime, si nu se vedea niciunul.
##
## Acum punctele vin din RAYCAST pe triunghiurile mesh-ului, pe razele reale
## ale camerei de sofer (ProbeFlancSurf), impreuna cu NORMALA fetei lovite.
## Fiecare cornisa se aseaza pe punctul masurat si se impinge in AFARA pe
## normala lui — singurul mod de a garanta ca sta in fata suprafetei.

## Punctele de suprafata masurate: pozitie (x,y,z) + normala (x,y,z).
## Regenerate cu: godot --path . res://tools/ProbeFlancSurf.tscn
const SURF := [
	[Vector3(225.4, 217.0, 97.6), Vector3(-0.636, 0.559, -0.532), 399],
	[Vector3(207.1, 205.2, 115.9), Vector3(-0.817, 0.559, -0.143), 380],
	[Vector3(204.5, 200.9, 135.0), Vector3(-0.779, 0.559, 0.285), 380],
	[Vector3(205.1, 192.8, 95.7), Vector3(-0.598, 0.627, -0.500), 370],
	[Vector3(181.2, 180.1, 111.8), Vector3(-0.801, 0.575, -0.165), 346],
	[Vector3(184.7, 178.8, 130.9), Vector3(-0.732, 0.627, 0.268), 353],
	[Vector3(212.2, 183.3, 75.4), Vector3(-0.598, 0.627, -0.500), 371],
	[Vector3(183.1, 169.6, 93.6), Vector3(-0.768, 0.627, -0.134), 341],
	[Vector3(175.7, 164.4, 111.4), Vector3(-0.750, 0.649, -0.131), 335],
	[Vector3(168.6, 159.5, 127.7), Vector3(-0.750, 0.649, -0.131), 331],
	[Vector3(187.5, 159.3, 74.3), Vector3(-0.584, 0.649, -0.488), 340],
	[Vector3(166.7, 150.1, 92.1), Vector3(-0.750, 0.649, -0.131), 319],
	[Vector3(160.0, 145.9, 109.1), Vector3(-0.750, 0.649, -0.131), 314],
	[Vector3(153.9, 142.0, 124.8), Vector3(-0.750, 0.649, -0.131), 311],
	[Vector3(192.6, 148.1, 53.4), Vector3(-0.584, 0.649, -0.488), 341],
	[Vector3(164.6, 137.9, 73.3), Vector3(-0.584, 0.649, -0.488), 312],
	[Vector3(151.5, 132.3, 90.7), Vector3(-0.756, 0.642, -0.132), 300],
	[Vector3(145.9, 129.0, 107.1), Vector3(-0.756, 0.642, -0.132), 296],
	[Vector3(140.7, 126.0, 122.2), Vector3(-0.756, 0.642, -0.132), 294],
]

## Cat de mult iese cornisa din flanc, pe normala. 6 m: la 300 m un pixel are
## 0.55 m, deci 6 m sunt ~11 px de desprindere — destul ca piesa sa aiba fata
## proprie si muchie de umbra, fara sa pluteasca vizibil peste silueta.
const PUSH := 6.0

var _out: PackedStringArray = []
var _n := 0


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	_bands()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d module de cornisa pe flancul Erciyes" % _n)
	get_tree().quit(0)


func _bands() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 330033
	for i in range(SURF.size()):
		var e: Array = SURF[i]
		var p: Vector3 = e[0]
		var nrm: Vector3 = e[1]
		var dist: float = e[2]
		# Doua module per punct masurat, decalate lateral, ca braul sa fie
		# continuu intre esantioane: punctele sunt la ~40 px unul de altul,
		# iar o piesa acopera ~50 px, deci un singur modul per punct lasa
		# fante prin care se vede iar flancul neted.
		var tang := nrm.cross(Vector3.UP).normalized()
		for k in range(2):
			var off := (float(k) - 0.5) * 14.0
			var q := p + nrm * PUSH + tang * off
			# Cota unduieste: un brau perfect orizontal citeste a inel de
			# metal pe un con.
			q.y += 2.0 * sin(float(i) * 0.8 + float(k) * 1.7)
			# Fata piesei se uita pe NORMALA masurata: benzile ei sunt pe X,
			# deci X tangent la flanc, Z pe normala.
			var yaw := atan2(nrm.x, nrm.z)
			# Scara scade cu distanta doar putin: la 294..399 m diferenta de
			# unghi e 35%, deci piesele de sus se micsoreaza vizibil daca nu
			# li se compenseaza.
			var sy := 0.62 * (dist / 320.0)
			var sx := (1.0 + rng.randf_range(-0.10, 0.10)) * (dist / 320.0)
			_raw("rocks/cliff_band_module", "cornisaErciyes",
				q, yaw, sx, sy)


func _raw(model: String, base: String, pos: Vector3, yaw: float,
		scl: float, scl_y: float) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="DecorManual/FlanculErciyes" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl_y, s, c, pos.x, pos.y, pos.z])
	_out.append('metadata/coliziune = "none"')
	_out.append("")
