extends Node
## Genereaza fragmentul de .tscn pentru falezele in benzi ale canionului (POI D).
##
## Pozitiile NU se ghicesc: ies din `route.baked` si din `ground_y`. Modulul
## masurat cu ProbeCappModule: 20.30 x 12.40 x 6.07 m, baza la y=0, centrat pe X.
##
## Terenul, masurat cu ProbeCappRavine, decide compozitia — nu simetria:
##   side_v = (d.z, 0, -d.x) e STANGA ECRANULUI — masurat cu ProbeCappSide
##   (dot -1.00 fata de camera), nu dedus din semn. Comentariile de mai jos
##   folosesc partea din IMAGINE, fiindca aia se judeca pe captura.
##
##   STANGA   teren la cota soselei pana la 35 m => aici sta faleza adevarata,
##            in doua trepte (a doua retrasa si mai sus, ca stratul de sus sa
##            iasa in consola peste cel de jos si sa-i puna o umbra pe frunte).
##   DREAPTA  rapa: podea la 11.7 m, adica 14 m SUB sosea, plata pe zeci de
##            metri. Un modul asezat acolo ar sta sub bot, nevazut. Deci pe
##            stanga nu se pune un perete, ci o BUZA: module care ies din malul
##            de sub drum si se vad ca stanca taiata, plus stanci pe podea la
##            baza lor.
##
## Straturile: fiecare treapta e un rand de module. Retragerea intre trepte
## (SETBACK) e ce face umbra — un strat tare care iese peste unul moale. O banda
## pictata pe o panta neteda arata a panza; o TREAPTA arata a roca.

const MOD_LEN := 20.30
const MOD_H := 12.40
const F0 := 0.428
const F1 := 0.534

## CONSOLA (corbel) fiecarui etaj peste cel de dedesubt, in metri.
##
## SEMNUL S-A INVERSAT, si asta e reparatia principala a rundei 2. Inainte era
## o RETRAGERE de +3.6 m: fiecare etaj pleca mai DEPARTE de sosea decat cel de
## sub el. Din masina vedeai atunci o scara care se departeaza, cu treptele
## intoarse in sus si in spate — invizibile. De-aia criticul orb a scris ca
## peretele "n-are NICIO suprafata orizontala luminata" si ca benzile raman
## "dungi pictate": geometric ele existau, dar nu erau intoarse spre nimeni.
##
## Acum etajul de sus IESE peste cel de jos (valoare NEGATIVA fata de convention
## de mai jos), deci:
##   - fruntea etajului de jos ramane vizibila ca o TREAPTA orizontala reala;
##   - buza etajului de sus arunca o UMBRA pe fata etajului de jos.
##
## A doua parte conteaza mai mult decat prima, si asta iese dintr-o masuratoare
## a soarelui, nu din gust. La elevatie 13 grade:
##   dot(fata verticala de perete, soare) = 0.634
##   dot(fata orizontala,          soare) = 0.225
## Adica o treapta orizontala e MAI INTUNECATA decat peretele, nu mai luminata.
## Deci "fata de sus luminata" nu se obtine facand treapta mai stralucitoare —
## se obtine din CONTRAST: banda de umbra proiectata de streasina peste fata
## insorita de dedesubt. Exact ce descrie criticul prin "casts a line of shadow
## on the softer one below it".
##
## 2.4 m e derivat din inaltimea etajului: la 12.4 m si soare de 13 grade,
## streasina arunca 2.4 / tan(13) = 10.4 m de umbra pe verticala de sub ea,
## adica aproape toata inaltimea unui etaj. Sub 1.5 m umbra ar fi o dunga.
const CORBEL := 2.4

## Degajarea minima de la AXUL drumului pana la CENTRUL modulului.
## Modulul are 6.07 m grosime si e centrat, deci fata lui ajunge cu 3.04 m mai
## aproape de sosea decat centrul. In viraj, coarda taie inca ~1.5 m. Prima
## incercare (hw + 5.0) a pus un modul PE carosabil la frac 0.48.
const CLEAR_M := 7.4

## Grosimea modulului, masurata cu ProbeCappModule. ORIGINEA NU E CENTRATA pe
## Z: geometria merge de la -3.82 la +2.25 (bbox "intentionat necentrat", scrie
## si inventarul kitului). Deci fata dinspre sosea poate ajunge cu 3.82 m mai
## aproape decat centrul, nu cu 3.04 cum ar zice jumatatea de latime — exact
## eroarea care lasase un colt de hull peste carosabil la frac 0.452.
const MOD_Z_MIN := -3.82
const MOD_Z_MAX := 2.25

func _emit(rows: Array, side: int, tier: int, s: Dictionary, track: Track,
		rng: RandomNumberGenerator, off_base: float, y_off: float,
		scale_rng: Vector2, road_clear: float, n_pts: int) -> void:
	var p: Vector3 = s["p"]
	var d: Vector3 = s["d"]
	var side_v := Vector3(d.z, 0.0, -d.x) * float(side)
	# CURBURA: un modul de 20 m e o coarda dreapta. Pe un viraj stramt capetele
	# lui intra spre interiorul curbei cu sageata f = L^2 / (8R), iar ProbeRace
	# a prins exact asta — la frac 0.476 ramasesera 0.4 m liberi din 5.5, si
	# trei masini se blocau acolo. Retragerea se CALCULEAZA din raza locala,
	# nu se acopera cu o marja globala care ar indeparta si portiunile drepte.
	var bulge: float = 0.0
	var r_local: float = s.get("radius", 0.0)
	if r_local > 1.0:
		bulge = (MOD_LEN * MOD_LEN) / (8.0 * r_local)
	# VARIATIE DE ADANCIME, in METRI. Vechea valoare (-0.5 .. +2.2) era o
	# fluctuatie de sub 3 m pe un modul de 20 m — la FOV-ul soferului asta e
	# invizibil, aceeasi capcana pentru care criticul lui POI F a respins un
	# jitter de ±9% ("nu e subtil, e INVIZIBIL, si cere METRI"). Acum sunt
	# ±6 m, adica un modul poate sta cu o treime din el in fata vecinului.
	# Nu e zgomot uniform: `pow` de 1.6 tine majoritatea aproape de linie si
	# scoate ocazional cate unul mult in fata, deci iese un mal cu pinteni,
	# nu un zid cu suprafata rugoasa.
	var jut_t: float = rng.randf()
	var jut: float = pow(jut_t, 1.6) * 6.2 - 1.4
	var off: float = off_base + bulge + jut
	var q: Vector3 = p + side_v * off
	# Scara si unghiul se trag INAINTE de garda: altfel garda ar valida alt
	# modul decat cel care ajunge in scena. Prima versiune folosea un `sc_hint`
	# si unghiul necliniat, iar `Strat0_04` (scara 1.15, nu 1.30) ramanea peste
	# carosabil — 4.7 m liberi din 5.5, nemiscat de trei incercari la rand.
	var sc: float = rng.randf_range(scale_rng.x, scale_rng.y)
	# ROTATIE NE-PARALELA. ±0.10 rad (5.7 grade) lasa toate fetele practic
	# paralele intre ele, si un rand de placi paralele citeste ca "rafturi
	# stantate" — reprosul textual al criticului lui POI F, aceeasi cauza.
	# ±0.30 rad (17 grade) e destul cat fetele vecine sa prinda cantitati
	# vizibil diferite de soare: la incidenta de aici, 17 grade schimba
	# cos(theta) cu ~15%, adica zeci de valori pe 255, nu doua.
	var yaw: float = atan2(-side_v.x, -side_v.z) + rng.randf_range(-0.30, 0.30)
	# GARDA DE CAROSABIL, pe COLTURILE REALE ale modulului asezat.
	#
	# Formula sagetii de mai sus corecteaza coarda, dar modulul e un
	# DREPTUNGHI ROTIT: coltul din fata ajunge mai aproape de ax decat centrul,
	# cu atat mai mult cu cat unghiul fata de drum e mai mare. Colturile se
	# construiesc cu `yaw`-ul FINAL si scara FINALA, si se masoara lateral fata
	# de traseu; daca vreunul intra in carosabil plus marja, modulul se impinge
	# in afara pana iese. Nu se sare peste el: o gaura in perete se vede, un
	# modul mai retras nu.
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var nrm := Vector3(cos(yaw), 0.0, -sin(yaw))
	# Amprenta NU e cutia bbox-ului. Modulul e o faleza cu STREASINA: partea
	# lui de sus iese spre sosea mai mult decat baza. Masurat pe vertecsii
	# reali (ProbeCappOne): `Strat0_07` trecea de o garda pe amprenta de la
	# y=0 cu 7.8 m raportati, si totusi avea un vertex la 2.10 m de ax — la
	# cota 29.7, adica sase metri PESTE drum. De-aia garda ia acum silueta pe
	# toata inaltimea: cel mai iesit `z` de pe fiecare felie.
	# Feliile vin din ProbeCappModule (z minim per banda de inaltime).
	var slices := [Vector2(0.0, -3.82), Vector2(2.0, -3.56),
		Vector2(6.0, -1.83), Vector2(12.0, -1.20)]
	var pushed := 0
	while pushed < 24:
		var worst := 1e9
		# NU doar cele 4 colturi: modulul are 20+ m si drumul se curbeaza SUB
		# el, deci punctul cel mai apropiat de ax poate cadea la mijlocul
		# muchiei, la o fractie unde modulul nici nu a fost asezat. Se
		# esantioneaza toata muchia dinspre sosea (9 puncte) plus cea din
		# spate. Asa a iesit `Strat0_07`, care trecea de garda pe colturi si
		# tot lasa 2.9 m din 5.5.
		for t in range(-4, 5):
			var cx: float = MOD_LEN * 0.5 * sc * (float(t) / 4.0)
			for sl in slices:
				var wc: Vector3 = q + fwd * cx + nrm * (sl.y * sc)
				# Distanta se ia ca MINIM pe o fereastra de indici, nu pe cel
				# mai apropiat singur index. Traseul e un S aici: capatul unui
				# modul de 20 m cade langa o bucla ULTERIOARA a drumului, iar
				# `closest_index_global` intoarce indexul de la care punctul
				# pare departe. Asa scapase `Strat0_07`, cu 13.4 m raportati si
				# 2.1 m reali. Aceeasi capcana ca la pasajele suprapuse
				# (memoria `pista-peste-pista`).
				var ci: int = track.closest_index_global(wc)
				for w_off in range(-40, 41, 4):
					var idx_w: int = ((ci + w_off) % n_pts + n_pts) % n_pts
					worst = minf(worst, absf(
						track.lateral_distance(idx_w, wc)))
		if worst >= road_clear:
			break
		q += side_v * (road_clear - worst + 0.15)
		pushed += 1
	var g: float = track._sampler.ground_y(q.x, q.z)
	# INALTIME variata pe modul, nu doar pe etaj. Fara ea creasta fiecarui
	# etaj e o LINIE DREPTA orizontala — asta e ce se vede pe captura de baza
	# la frac 0.48 ca margine de metereze pe o treime din latimea cadrului.
	# ±1.9 m pe un etaj de 12.4 m rupe linia fara sa desfaca randul.
	var y: float = g - 1.6 + y_off + rng.randf_range(-1.9, 1.9)
	rows.append({"side": side, "tier": tier, "f": s["f"], "x": q.x, "y": y,
		"z": q.z, "yaw": yaw, "sc": sc, "g": g})

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210

	var samples: Array = []
	var f := F0
	while f < F1:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		# Raza locala din trei puncte de pe traseu (cerc circumscris): e ce
		# spune cat de tare se strange curba sub un modul de 20 m.
		var back: Vector3 = pts[(idx - 10 + n) % n]
		var a1 := (p - back); a1.y = 0.0
		var a2 := (ahead - p); a2.y = 0.0
		var cross: float = absf(a1.x * a2.z - a1.z * a2.x)
		var radius := 0.0
		if cross > 0.001:
			radius = (a1.length() * a2.length() * (a1 + a2).length()) / (2.0 * cross)
		samples.append({"f": f, "p": p, "d": d, "radius": radius})
		f += 0.0016

	var rows: Array = []
	# --- FALEZA (stanga ecranului): trei trepte -----------------------------
	# Terenul e la cota soselei pana la 35 m (ProbeCappRavine), deci aici sta
	# faleza adevarata. Un singur etaj de 12.4 m e un parapet vazut din masina
	# (captura w1_052): camera sta la 10 m si se uita PESTE el. Trei etaje
	# retrase dau 30+ m si umplu cadrul, ca in referinta.
	for tier in [0, 1, 2]:
		var acc := MOD_LEN * 2.0
		var last := Vector3.ZERO
		var first := true
		for s2 in samples:
			var p2: Vector3 = s2["p"]
			if first: first = false
			else: acc += p2.distance_to(last)
			last = p2
			if acc < MOD_LEN * 0.55: continue
			acc = 0.0
			# RUPTURI. Etajele de sus sar peste module, etajul 0 nu.
			#
			# Asta e "breaks" din verdict, si e opusul rundei trecute: acolo
			# s-a mers de la 47 la 69 module ca sa se INCHIDA golurile de cer,
			# si criticul a spus ca masa a devenit mai uniforma, nu mai bogata.
			# Deci golul e informatie, nu defect — cu o conditie: sa fie SUS.
			# Un gol in etajul 0 ar arata drumul prin perete si ar strica si
			# senzatia de canion inchis; unul in etajul 2 rupe silueta pe cer,
			# adica exact unde se vedea linia dreapta de metereze.
			#
			# 18% pe etajul 1 si 32% pe etajul 2: creste cu inaltimea, ca un
			# mal care se destrama spre creasta.
			if tier > 0 and rng.randf() < (0.18 if tier == 1 else 0.32):
				continue
			var hw: float = track.width_at(s2["f"])
			# Fiecare etaj e retras cu SETBACK si ridicat cu 0.82 din inaltime:
			# creasta celui de jos ramane vizibila ca o TREAPTA, si arunca umbra
			# pe fata celui de dedesubt. Asta face diferenta intre roca si panza.
			# Etajul 0 pleaca cu 2 * CORBEL mai departe de sosea, ca etajele
			# de deasupra sa aiba de unde sa iasa fara sa ajunga peste drum:
			# consola se scade, deci baza trebuie sa stea mai in spate.
			# Degajarea neta a etajului de sus ramane CLEAR_M, ca inainte.
			var out_m: float = hw + CLEAR_M + CORBEL * float(2 - tier)
			# Etajele NU mai sunt egale ca inaltime. Trei felii de 12.4 m
			# citeau ca trei randuri de caramizi identice — "un teanc de
			# module", cuvintele criticului. Un mal real are un strat gros la
			# baza si unul subtire deasupra, fiindca sunt roci diferite.
			var tier_h: float = [0.0, 11.4, 20.8][tier]
			_emit(rows, 1, tier, s2, track, rng,
				out_m,
				tier_h,
				Vector2(1.05, 1.30) if tier == 0 else Vector2(0.90, 1.15),
				hw + 2.2, n)
	# --- BUZA RAPEI (dreapta ecranului) -------------------------------------
	# Rapa are podeaua la 11.7 m, adica 14 m SUB sosea, si e plata pe zeci de
	# metri: nu exista mal in fata pe care sa stea un perete. Deci pe stanga nu
	# se pune un al doilea perete, ci MUCHIA taiata a malului de sub drum —
	# modulul atarna sub buza si i se vede doar coama, ca o cornisa.
	var acc2 := MOD_LEN * 2.0
	var last2 := Vector3.ZERO
	var first2 := true
	for s3 in samples:
		var p3: Vector3 = s3["p"]
		if first2: first2 = false
		else: acc2 += p3.distance_to(last2)
		last2 = p3
		if acc2 < MOD_LEN * 0.70: continue
		acc2 = 0.0
		var hw3: float = track.width_at(s3["f"])
		var side_v := Vector3(s3["d"].z, 0.0, -s3["d"].x) * -1.0
		# Mai DEPARTE de ax decat faleza: pe captura w3_048 modulele stateau
		# peste berma si li se vedea muchia de jos — placi puse pe pamant, nu
		# mal taiat. Se duc dincolo de buza, unde terenul chiar cade.
		# Aceeasi corectie de curbura ca la faleza: buza e tot un modul de 20 m.
		var bulge3: float = 0.0
		var r3: float = s3.get("radius", 0.0)
		if r3 > 1.0:
			bulge3 = (MOD_LEN * MOD_LEN) / (8.0 * r3)
		var off3: float = hw3 + CLEAR_M + 3.0 + bulge3 + rng.randf_range(-0.4, 1.4)
		var q: Vector3 = p3 + side_v * off3
		var sc: float = rng.randf_range(0.90, 1.20)
		# Aceeasi garda pe colturi ca la faleza.
		var pushed3 := 0
		while pushed3 < 24:
			var worst3 := 1e9
			for t3 in range(-4, 5):
				var cx: float = MOD_LEN * 0.5 * sc * (float(t3) / 4.0)
				for cz in [MOD_Z_MIN * sc, MOD_Z_MAX * sc]:
					var fwd3 := Vector3(-side_v.z, 0.0, side_v.x)
					var wc3: Vector3 = q + fwd3 * cx + side_v * cz
					var ci3: int = track.closest_index_global(wc3)
					worst3 = minf(worst3, absf(track.lateral_distance(ci3, wc3)))
			if worst3 >= hw3 + 2.2:
				break
			q += side_v * (hw3 + 2.2 - worst3 + 0.15)
			pushed3 += 1
		# Coama iese doar 0.35 m peste cota soselei (era 0.8): din masina se
		# vede o MUCHIE, nu o placa. Restul modulului sta in rapa, sub buza.
		var y: float = p3.y + 0.35 - MOD_H * sc
		var yaw: float = atan2(-side_v.x, -side_v.z) + rng.randf_range(-0.12, 0.12)
		rows.append({"side": -1, "tier": 0, "f": s3["f"], "x": q.x,
			"y": y, "z": q.z, "yaw": yaw, "sc": sc, "g": p3.y})

	# --- POALA DE GROHOTIS la piciorul falezei ------------------------------
	#
	# Defectul 3 din verdictul comun: "obiecte care se infig intr-un plan".
	# Peretele se termina intr-o muchie matematica pe pamant neted, si asta e
	# ce face un prop sa citeasca drept prop asezat pe podea, nu roca crescuta
	# din teren.
	#
	# PIESA E ACELASI `cliff_band_module.glb`, la scara mica si rotit aiurea.
	# Runda trecuta generase molozul din `rock_medium`/`rock_small` si l-a
	# ARUNCAT dintr-un motiv corect (alea stau 71% pe slotul 3, portocaliu
	# deschis, si langa un perete rosu citeau a saci de nisip), dar concluzia
	# de atunci — "ne trebuie o piesa noua in kit" — sarea peste solutia
	# ieftina. Maparea din CLASSES_BY_MODEL e pe NUMELE FISIERULUI .glb, deci
	# modulul de faleza vine deja imbracat in `red_valley_tuff`: acelasi rosu,
	# ACELASI material, zero materiale in plus la garda.
	#
	# Costul e in triunghiuri (1208 per piesa), si e acceptat constient:
	# CLAUDE.md spune ca triunghiurile se raporteaza si nu pica build-ul, iar
	# axa care doare pe mobil — materialele — ramane neatinsa.
	#
	# GRADIENTUL cerut de verdict: "dense and small against the base, sparser
	# and larger outward". Deci nu un sir de bolovani egali: cele de langa
	# perete sunt multe si mici, cele de departe rare si mari. `t` e distanta
	# normalizata de la picior, si conduce si marimea, si probabilitatea.
	var rubble: Array = []
	var f2 := F0
	while f2 < F1:
		var idx2 := int(f2 * float(n)) % n
		var p4: Vector3 = pts[idx2]
		var ahead2: Vector3 = pts[(idx2 + 10) % n]
		var d4 := (ahead2 - p4); d4.y = 0.0; d4 = d4.normalized()
		var sv := Vector3(d4.z, 0.0, -d4.x)
		var hw4: float = track.width_at(f2)
		# 4-7, nu 7-11. Cu 11 ieseau 224 de blocuri si 396k triunghiuri: garda
		# trece (materialele raman 8 din 22, fiindca e ACELASI GLB), dar 285 de
		# desene pentru o poala de moloz e fix capcana din CLAUDE.md — un chip
		# de 2.6 m care instantiaza un mesh de 1208 triunghiuri. Seama se rupe
		# la fel de bine cu jumatate din piese, fiindca ce o rupe e neregula
		# conturului, nu numarul de blocuri (aceeasi lectie ca "mai mult zid nu
		# e mai mult canion").
		for j in range(rng.randi_range(4, 7)):
			# t = 0 lipit de perete, t = 1 la 9 m in fata lui.
			var t: float = pow(rng.randf(), 0.55)
			# Rarire spre exterior: departe, jumatate din incercari cad.
			if rng.randf() < t * 0.55:
				continue
			var off4: float = hw4 + CLEAR_M - 3.4 + t * 8.0
			# Deplasare mica IN LUNGUL drumului, pe langa cea laterala. Fara
			# ea toate blocurile de pe un pas stau pe aceeasi normala si se
			# aliniaza in evantai; cu ea, poala e imprastiata in doua axe.
			var along: float = rng.randf_range(-7.0, 7.0)
			var q4: Vector3 = p4 + sv * off4 + d4 * along
			# Marimea se trage INAINTE de garda, ca garda sa masoare piesa care
			# chiar ajunge in scena (aceeasi capcana ca la module, unde un
			# `sc_hint` gresit lasase Strat0_04 peste carosabil).
			# Marimea creste cu distanta: 1.4 m langa perete, pana la 4.6 m
			# afara. Modulul are 20.3 m, deci scara e metri / 20.3 — derivata
			# din marimea reala a GLB-ului, nu un factor ghicit.
			# Marimea variaza LARG (0.62..1.45), nu 0.8..1.25, si asta e o
			# reparatie de artefact, nu de compozitie. Blocurile sunt acelasi
			# mesh; cand doua ajung la scari apropiate si se intrepatrund, au
			# fete COPLANARE care se bat pe adancime — pe captura ieseau pete
			# negre pe grohotis (masurat: 69 de perechi din 93 se intrepatrund
			# adanc). Cu scari clar diferite, fetele nu mai cad in acelasi plan.
			var want_m: float = lerpf(2.6, 6.4, t) * rng.randf_range(0.62, 1.45)
			var sc4: float = want_m / MOD_LEN
			# GARDA DE CAROSABIL, obligatorie: blocurile primesc corp fizic
			# automat (`world_prop`), deci unul cazut pe banda nu e decor, e
			# zid. ProbeRace a prins exact asta — `Bloc_42_col` oprea masina
			# la frac 0.469 cu lateral 3.6 m, adica in plin carosabil (half
			# width 6). Se impinge in afara pana iese, ca la module.
			# Distanta se ia ca MINIM pe o fereastra de indici, nu pe cel mai
			# apropiat singur index: traseul e un S aici, si `closest_index`
			# poate intoarce o bucla vecina fata de care blocul pare departe.
			# Exact capcana documentata la module (memoria `pista-peste-pista`)
			# — prima versiune a garzii folosea un singur index si ProbeRace a
			# gasit tot un bloc pe banda (`Bloc_46_col`, lateral 4.8 m).
			# 2.4 m peste jumatatea de banda, plus 0.7 din marimea blocului.
			# S-au incercat si 4.0 (grohotisul mai departe) si CLEAR_M 9.6
			# (tot peretele mai departe): banda 0.45-0.50 a ramas la 13.1-13.4
			# m/s in toate trei. AMANDOUA S-AU REVENIT — nu platesti degajare
			# pentru un efect care nu se masoara. Incetinirea nu vine de la
			# degajare: in banda sunt 0 blocaje si 0 repuneri, iar "peretii"
			# numarati acolo sunt treceri pe langa perete, nu izbituri.
			var need4: float = hw4 + 2.4 + want_m * 0.7
			var guard4 := 0
			while guard4 < 24:
				var lat4 := 1e9
				var ci4: int = track.closest_index_global(q4)
				for w4 in range(-40, 41, 4):
					var iw4: int = ((ci4 + w4) % n + n) % n
					lat4 = minf(lat4, absf(track.lateral_distance(iw4, q4)))
				if lat4 >= need4:
					break
				q4 += sv * (need4 - lat4 + 0.25)
				guard4 += 1
			var g4: float = track._sampler.ground_y(q4.x, q4.z)
			# INGROPAT pe un sfert: un bloc desprins se aseaza in pamant, nu
			# sta pe el. Asta e si ce sterge muchia dintre perete si sol.
			rubble.append({"x": q4.x, "y": g4 - want_m * rng.randf_range(0.16, 0.40), "z": q4.z,
				"yaw": rng.randf_range(0.0, TAU),
				"pitch": rng.randf_range(-0.5, 0.5),
				"sc": sc4})
		f2 += 0.0040
	var rtxt := ""
	for r2 in rubble:
		rtxt += "%.3f	%.3f	%.3f	%.4f	%.4f	%.5f
" % [
			r2["x"], r2["y"], r2["z"], r2["yaw"], r2["pitch"], r2["sc"]]
	var fr := FileAccess.open("res://canyon_d_rubble.txt", FileAccess.WRITE)
	fr.store_string(rtxt)
	fr.close()
	print("rubble: ", rubble.size())

	var txt := ""
	for r in rows:
		txt += "%d\t%d\t%.4f\t%.3f\t%.3f\t%.3f\t%.4f\t%.3f\n" % [
			r["side"], r["tier"], r["f"], r["x"], r["y"], r["z"], r["yaw"], r["sc"]]
	var fa := FileAccess.open("res://canyon_d_rows.txt", FileAccess.WRITE)
	fa.store_string(txt)
	fa.close()
	print("rows: ", rows.size())
	get_tree().quit(0)
