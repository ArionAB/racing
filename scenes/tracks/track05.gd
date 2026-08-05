@tool
extends Track
## Okinawa — circuit de insula cu recif.
##
## Tur tinta ~1800 m (≈60 s), fata de 1175 pe Dunele. Style bible §7 cere un
## landmark dominant la 120-180 m, deci 10-13 pe tur.
##
## De ce puncte in cod si nu Path3D editabil ca pe Dunele: traseul are 24 de
## puncte cu cote care conteaza (urcarea pe promontoriu, creasta de fly-off,
## coborarea la nivelul marii) plus o ramificatie ale carei capete trebuie sa
## cada pe fractii anume. Intr-o scena, toate astea sunt un vector binar pe care
## nu-l poti citi intr-un diff si nu-l poti comenta. Stramtoarea e scrisa la fel.
##
## GEOMETRIA NU E NEGOCIABILA (memoria proiectului, pilonul de la Dunele):
## raza fiecarui viraj > half_width, iar doua ramuri paralele la >= 2*half_width.
## Sub pragurile astea asfaltul se plieaza peste el insusi si masinile se
## blocheaza. Se verifica cu tools/probe_layout.gd, nu din ochi.

const SECTORS := [
	"Portul", "Satul", "Poarta shisa", "Urcarea gusuku", "Farul",
	"Creasta si viaductul", "Trestia de zahar", "Causeway",
]

func _init() -> void:
	track_name = "Okinawa"
	half_width = 7.0
	sea_level_offset = -7.0
	apply_theme("island")


## Traseul, sector cu sector. Y-ul e cota in metri deasupra nivelului 0 al
## pistei; marea sta la sea_level_offset sub MEDIA lor.
func _points() -> Array[Vector3]:
	return [
		# --- 1. Portul: dreapta de start, pe faleza portului -----------------
		Vector3(-280, 0.5, 210),  # linia de start
		Vector3(-160, 0.5, 214),
		Vector3(-40, 0.8, 216),
		Vector3(80, 1.2, 212),
		# --- 2. Satul: doua viraje medii printre case cu olane ---------------
		Vector3(185, 2.0, 196),
		Vector3(255, 3.5, 152),
		Vector3(288, 5.5, 92),
		# --- 3. Poarta shisa: drumul trece pe sub torii ----------------------
		Vector3(292, 8.5, 30),
		Vector3(272, 12.5, -28),
		# --- 4. Urcarea gusuku: acul de par, virajul lent al pistei ----------
		Vector3(232, 17.0, -78),
		Vector3(172, 20.5, -104),
		Vector3(108, 22.0, -96),
		Vector3(72, 21.5, -46),
		# --- 5. Farul: sweeper rapid pe promontoriu, marea pe exterior -------
		Vector3(30, 20.0, -12),
		Vector3(-50, 17.5, -18),
		Vector3(-130, 13.0, -46),
		# --- 6. Creasta si viaductul: fly-off, apoi coborare la mare ---------
		Vector3(-196, 7.5, -84),
		Vector3(-244, 3.0, -126),
		# --- 7. Golful de vest: drumul ocoleste un golf pe uscat -------------
		#
		# Carligul asta e MOTIVUL scurtaturii, nu decor. Prima versiune avea aici
		# o linie aproape dreapta, iar bancul de nisip iesea cu 25% mai LUNG
		# decat portiunea pe care o ocolea — adica exact opusul unei scurtaturi.
		# Prins de tools/probe_layout.gd, nu la playtest.
		Vector3(-286, 1.4, -172),
		Vector3(-368, 0.9, -168),
		Vector3(-408, 0.7, -104),
		Vector3(-392, 0.6, -34),
		# --- 8. Causeway: dreapta lunga peste recif, tetrapozi pe ambele -----
		Vector3(-344, 0.4, 42),
		Vector3(-308, 0.4, 132),
	]


## Reperele hero, sector cu sector. (fractie, latura ±1, id din
## `Track._LANDMARKS`).
##
## Fractiile respecta regula din style_bible §7: un reper dominant la 120-180 m,
## deci ~10-13 pe un tur de 1800 m, si NICIODATA unul inalt in apexul virajului
## — acolo ar acoperi exact linia pe care trebuie s-o citesti.
##
## Fiecare sector isi capata identitatea din reperul lui: fara asta, "Farul" si
## "Urcarea gusuku" erau doua nume de sectoare cu acelasi nisip.
func _landmark_spots() -> Array[Vector3]:
	return [
		# --- 2. Satul: case cu olane, alternate pe laturi ca drumul sa treaca
		# PRINTRE ele, nu pe langa un rand.
		Vector3(0.185, 1.0, 6),
		Vector3(0.215, -1.0, 6),
		Vector3(0.245, 1.0, 6),
		# --- 3. Poarta shisa: poarta straddle peste drum, cu perechea de lei
		# de o parte si de alta, la aceeasi fractie. Gura deschisa in dreapta
		# (id 9), cea inchisa in stanga (id 10) — conventia de la porti.
		Vector3(0.300, 1.0, 8),
		Vector3(0.306, 1.0, 9),
		Vector3(0.306, -1.0, 10),
		# --- 4. Urcarea gusuku: trei segmente de zid pe INTERIORUL acului de
		# par. Pe exterior ar fi fost un perete in fata iesirii din viraj; pe
		# interior, il vezi tot urcusul si nu-ti ascunde apexul.
		Vector3(0.355, -1.0, 11),
		Vector3(0.378, -1.0, 11),
		Vector3(0.401, -1.0, 11),
		# --- 5. Farul: pe EXTERIORUL sweeper-ului de promontoriu, unde curba il
		# tine in cadru tot lungul virajului. Fractia 0.50, adica exact la
		# jumatatea turului: reperul care iti spune ca esti la jumate.
		Vector3(0.500, 1.0, 7),
	]


## Scurtatura: bancul de nisip care taie golful de vest.
##
## Coarda peste apa, in timp ce soseaua ocoleste golful pe uscat. Capetele cad
## pe fractiile 0.70 si 0.85 — adica exact pe intrarea si iesirea carligului
## din sectorul 7.
##
## Latimea de 6.5 (fata de 7.0 a soselei) e putin mai ingusta, dar nu mult: la
## 11 m, cat avea prima versiune, banda uda devenea o capcana — AI-ul aluneca in
## apa si tururile scadeau de la 2.5 la 1.6. Ingustimea trebuie sa descurajeze
## depasirea, nu sa pedepseasca simpla prezenta acolo.
##
## Castigul geometric il masoara tools/probe_layout.gd si il tipareste la
## fiecare rulare. E intentionat vizibil: singura contragreutate e grip-ul taiat
## de banda uda, iar echilibrul dintre cele doua se gaseste la playtest, nu aici.
func _branch_specs() -> Array[Dictionary]:
	return [{
		"entry": 0.70,
		"exit": 0.85,
		"half_width": 6.5,
		"wet": true,
		"label": "bancul de nisip",
		"points": [
			Vector3(-287, 1.4, -113),
			Vector3(-326, 0.8, -94),
			Vector3(-361, 0.7, -67),
		],
	}]


## Causeway-ul: teren sapat pe AMBELE laturi, ca marea sa vina pana la asfalt.
##
## Fara asta, drumul peste recif ar fi fost un drum pe o limba de nisip lata de
## 90 m — terenul urmareste soseaua pe 45 m in fiecare parte (ground_y), deci
## apa n-ar fi ajuns niciodata langa el. Rapa declarata taie inapoi terenul sub
## nivelul marii, iar apa umple singura.
##
## Adancimea 15 e peste cei 7 m ai nivelului marii, deci fundul iese clar
## submers; sub atat, ar fi ramas o plaja lipita de sosea.
func _ravines() -> Array[Vector4]:
	return [
		Vector4(0.86, 0.99, 15.0, 0.0), # causeway, ambele laturi
		Vector4(0.40, 0.46, 18.0, 1.0), # prapastia de sub creasta de fly-off
	]


func _flyoff_fracs() -> Array[float]:
	return [0.43] # creasta de la iesirea de pe promontoriu, spre viaduct


func _ramp_fracs() -> Array[float]:
	return [0.20]


## Banda uda de pe causeway: marea spala asfaltul, grip-ul cade.
##
## `_hose_fracs` ramane sursa TAIERII de grip (zona umeda si baltile), dar
## conducta sparta nu se mai vede — pe o insula, o teava de santier era exact
## genul de piesa importata din alta pista care rupe tema. `hose_model: ""` in
## tema `island` o stinge, iar valul de mai jos ii ia locul vizual.
func _hose_fracs() -> Array[float]:
	return [0.91]


## Valul care matura causeway-ul (#106), pe aceeasi fractie cu banda uda.
##
## Gimmick-ul sectorului 8: udatura e permanenta, dar valul spune CAND. Faza 2
## din issue — sincronizarea ferestrei de grip taiat cu ciclul valului — ramane
## o decizie de playtest, nu una de scris aici: mai intai trebuie simtit daca un
## drum permanent alunecos plus un ceas vizual e destul.
func _wave_fracs() -> Array[float]:
	return [0.91]


func _hazard_fracs() -> Array[float]:
	return [0.33]
