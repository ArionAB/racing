@tool
extends Track
## Pista 6 — "Stramtoarea": doua jumatati care nu seamana deloc.
##
## Gimmick: CONTRASTUL DE RITM. Prima jumatate e desert deschis, cu o dreapta de
## 200 m si viraje de raza uriasa (mediana 350 m) — acolo se arde bara de turbo
## pana la fund si se depaseste in siguranta. A doua jumatate intra intr-un
## defileu unde falezele string drumul de ambele parti si raza mediana cade la
## 97 m, cu un V de 17 m in fund. Acolo nu se depaseste: te lipesti de cel din
## fata si astepti iesirea, sau incerci crapatura.
##
## Nicio alta pista din joc nu are contrastul asta: Dunele alterneaza uniform,
## Serpentina e tehnica peste tot, Muntele e rapid peste tot. Aici jucatorul isi
## schimba complet modul de a conduce la jumatatea turului, de doua ori pe tur.
##
## Numerele NU sunt desenate din ochi. Traseul a fost iterat pe metricile din
## tools/probe_layout.gd inainte sa fie scris aici; fractiile fiecarui element
## sunt derivate din POZITIA FIZICA a lucrului pe care il marcheaza, nu ghicite —
## exact capcana din care a iesit hairpin-ul Dunelor (o modificare de traseu muta
## toate fractiile, deci se recalculeaza, nu se ajusteaza).

func _init() -> void:
	track_name = "Stramtoarea"
	half_width = 7.0
	apply_theme("desert")

## Bucla: 1364 m, anvelopa 520 x 310 m, urcare 13 m.
## Masurat in motor: raza minima 15.5 m, panta maxima 7.9%, apropiere de sine
## 48 m. Toate cu marja fata de pragurile gardei (raza > 7, panta < 22%,
## separare > 14).
##
## Contrastul, in cifre — asta E pista:
##   desert rapid   raza mediana 350 m
##   DEFILEU        raza mediana  97 m, minim 17 m
func _points() -> Array[Vector3]:
	return [
		# --- DESERT DESCHIS: raza mediana 350 m, aici traieste turbo-ul ---
		Vector3(0, 0, 0),        # START/FINISH, mers spre +X
		Vector3(100, 0, 8),
		Vector3(200, 1, 4),      # dreapta de ~200 m
		Vector3(278, 3, -18),    # viraj rapid la dreapta, fara frana
		Vector3(316, 6, -70),
		Vector3(310, 10, -126),  # S larg, urca spre creasta
		Vector3(264, 13, -166),  # CREASTA (fly-off) — punctul cel mai inalt
		Vector3(200, 12, -192),  # aterizare
		# --- DEFILEU: raza mediana 97 m, falezele la 12 m de axa ---
		Vector3(142, 8, -212),   # gura defileului (arcada de stanca)
		Vector3(96, 5, -222),
		Vector3(60, 4, -228),    # A — gura crapaturii (intrare scurtatura)
		# Fundul V-ului, si singurul viraj lent al pistei.
		#
		# Vecinii lui (A si C) stau de-o parte si de alta a axei lobului, deci
		# tangenta calculata de track.gd — (C - A) * 0.22 — iese PERPENDICULARA
		# pe axa. Asta e diferenta dintre un viraj de 17 m si o cuspida in care
		# se plieaza asfaltul (vezi istoricul hairpin-ului de pe Dunele).
		#
		# Adancimea (-302) e rezultatul unei cautari, nu o alegere: e cea mai
		# mare la care raza ramane peste 16 m. Mai adanc inseamna scurtatura mai
		# valoroasa, dar sub ~14 m raza AI-ul incepe sa se opinteasca aici. Daca
		# se muta A, B sau C, se remasoara raza si castigul scurtaturii impreuna
		# — sunt legate, si se schimba in directii opuse.
		Vector3(24, 3, -302),
		Vector3(-60, 3, -230),   # C — iesirea crapaturii
		Vector3(-98, 3, -228),
		Vector3(-144, 3, -240),  # iesirea defileului
		# --- RETUR DESCHIS: se largeste iar, urca inapoi la cota de start ---
		Vector3(-190, 3, -206),
		Vector3(-204, 2, -150),
		Vector3(-182, 1, -96),
		Vector3(-134, 0, -52),
		Vector3(-70, 0, -20),
	]


## Crapatura din peretele canionului — singura scurtatura, si singura decizie
## mare a turului.
##
## Ocoleste V-ul: 198 m de defileu inlocuiti cu ~124 m de crapatura, deci
## castig de ~74 m (~3 s la ritmul din defileu).
##
## CONTRAGREUTATEA e latimea, si e o alegere deliberata in locul lui `wet`.
## Banda uda e contragreutatea Okinawei si tine de apa; aici n-ar avea de ce sa
## fie umed. 5.0 in loc de 7.0 inseamna 10 m de asfalt in loc de 14: singur o
## iei fara sa clipesti, dar in trafic nu incape decat o masina, iar iesirea te
## scuipa in defileu chiar inainte de ultima strangere. Fara costul asta ar fi
## 74 m cadou pe tur si n-ar mai exista nicio decizie — exact ce s-a masurat pe
## bancul de nisip al Okinawei inainte sa primeasca `wet`.
##
## Capetele NU se scriu de mana: se citesc de pe bucla la fractiile date, deci
## raman lipite de asfalt oricat s-ar muta traseul.
func _branch_specs() -> Array[Dictionary]:
	return [{
		"entry": 0.503,   # gura A, derivata din (60, -228)
		"exit": 0.648,    # gura C, derivata din (-60, -230)
		"half_width": 5.0,
		"wet": false,
		"label": "crapatura",
		# Un singur punct intermediar, usor spre nord fata de coarda: crapatura
		# se vede ca ocoleste ceva, nu ca taie in linie dreapta ca o autostrada.
		"points": [
			Vector3(0, 3, -224),
		],
	}]


## Creasta de fly-off, pe ultima cadere dinaintea defileului. Fara linie sigura:
## aici sare toata pista, alegerea e cat de tare intri. Sub ea trebuie sa existe
## rapa — vezi _ravines(), altfel plasa de respawn ramane ingropata si garda din
## _build_flyoff_net avertizeaza.
func _flyoff_fracs() -> Array[float]:
	return [0.345]

## Rampa pe returul deschis: singurul airtime pe care il POTI evita, spre
## deosebire de creasta. Alegere de linie, nu de curaj.
func _ramp_fracs() -> Array[float]:
	return [0.893]

## Bolovanul rostogolitor, imediat dupa fundul V-ului.
##
## In desert `hazard_model` e boulder_roller, iar defileul e singurul loc din
## joc unde un bolovan care vine spre tine chiar nu are pe unde fi ocolit
## comod — falezele sunt la 12 m de axa. Plasat DUPA V, nu inainte: inainte de
## viraj n-ai fi avut ce decide, doar ai fi franat.
func _hazard_fracs() -> Array[float]:
	return [0.598]

## Caderi de pietre in defileu, de-o parte si de alta a V-ului.
##
## Bolovanul cade pe O banda si lasa mereu una curata, cu latura alternand
## determinist cu fractia — deci pe un drum strans intre faleze devine exact
## ce trebuie: nu un blocaj, ci o strangere si mai mare a liniei.
func _rockfall_fracs() -> Array[float]:
	return [0.470, 0.700]

## Bariera oblica pe dreapta lunga.
##
## Fara ea, cele 200 m de la start ar fi turbo gratis. Asa trebuie sa alegi:
## treci pe banda pe care te impinge si pierzi linia pentru virajul rapid, sau
## franezi si ocolesti, si arzi mai putin.
func _deflector_fracs() -> Array[float]:
	return [0.110]

## Trecerea de cale ferata, pe returul deschis.
##
## Pusa aici, si nu pe dreapta de start, dintr-un motiv de cursa: la 0.844
## garnitura rupe plutonul INAINTE de sectorul rapid, deci cine ramane in spate
## are dreapta intreaga sa recupereze cu turbo. Pe dreapta de start ar fi lovit
## plutonul strans din primul tur, cand masinile sunt inca umar la umar.
## Sina cere spatiu lateral, iar returul e cea mai deschisa parte a pistei.
func _train_fracs() -> Array[float]:
	return [0.844]

## Arcada de stanca peste sosea, fix la gura defileului: poarta care anunta
## schimbarea de ritm. Jucatorul trebuie sa VADA ca intra in altceva.
func _arch_fracs() -> Array[float]:
	return [0.441]

## Defileul: intervalul in care falezele string drumul de ambele parti.
## De la gura (0.441) pana la iesire (0.713) — 371 de metri de tur, adica
## peste un sfert din el.
func _gorge_ranges() -> Array[Vector2]:
	return [Vector2(0.441, 0.713)]

## Rapa de sub creasta de fly-off. Adancimea 16 e peste pragul din
## _build_flyoff_net (plafonul plasei coboara 6 m, garda cere > 10), deci cine
## rateaza aterizarea chiar cade si e repus, nu ateriseaza pe nisip.
func _ravines() -> Array[Vector4]:
	return [Vector4(0.330, 0.425, 16.0, 1.0)]

## Portalul de mina langa gura crapaturii: explica DE CE exista o gaura in
## peretele canionului. Decor cu rol de semnalizare — il vezi din defileu si
## stii ca acolo se desprinde ceva.
func _mine_spots() -> Array[Vector2]:
	return [Vector2(0.498, -1.0)]

## Oase de dinozaur pe intinderea deschisa, ca desertul sa nu fie gol intre
## dreapta de start si primul viraj rapid.
func _dino_spots() -> Array[Vector2]:
	return [Vector2(0.200, 1.0)]

## Landmark-uri hero: (fractie, latura ±1, id-model din _LANDMARKS).
## Puse pe sectoarele DESCHISE — in defileu n-ar avea unde incapea, falezele
## sunt la 12 m de axa.
##   0 turn de apa · 1 benzinarie · 3 semn Route 66 · 5 semn de benzinarie pe
##   stalp (se vede de departe, deci marcheaza intrarea in viraj)
func _landmark_spots() -> Array[Vector3]:
	return [
		Vector3(0.045, 1.0, 1.0),   # benzinaria, langa grila de start
		Vector3(0.145, -1.0, 5.0),  # semnul pe stalp, pe dreapta lunga
		Vector3(0.280, 1.0, 0.0),   # turnul de apa, inainte de creasta
		Vector3(0.780, -1.0, 3.0),  # Route 66 pe retur
	]
