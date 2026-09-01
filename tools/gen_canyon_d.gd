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

## Retragerea celui de-al doilea etaj fata de primul (metri). Sub 2 m umbra e o
## dunga; peste 5 m al doilea etaj se desprinde si nu mai citeste ca acelasi mal.
const SETBACK := 3.6

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
	var off: float = off_base + bulge + rng.randf_range(-0.5, 2.2)
	var q: Vector3 = p + side_v * off
	# Scara si unghiul se trag INAINTE de garda: altfel garda ar valida alt
	# modul decat cel care ajunge in scena. Prima versiune folosea un `sc_hint`
	# si unghiul necliniat, iar `Strat0_04` (scara 1.15, nu 1.30) ramanea peste
	# carosabil — 4.7 m liberi din 5.5, nemiscat de trei incercari la rand.
	var sc: float = rng.randf_range(scale_rng.x, scale_rng.y)
	var yaw: float = atan2(-side_v.x, -side_v.z) + rng.randf_range(-0.10, 0.10)
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
	var y: float = g - 1.6 + y_off
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
			if acc < MOD_LEN * 0.86: continue
			acc = 0.0
			var hw: float = track.width_at(s2["f"])
			# Fiecare etaj e retras cu SETBACK si ridicat cu 0.82 din inaltime:
			# creasta celui de jos ramane vizibila ca o TREAPTA, si arunca umbra
			# pe fata celui de dedesubt. Asta face diferenta intre roca si panza.
			_emit(rows, 1, tier, s2, track, rng,
				hw + CLEAR_M + SETBACK * float(tier),
				MOD_H * 0.82 * float(tier),
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
		if acc2 < MOD_LEN * 0.95: continue
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

	# --- MOLOZ la piciorul falezei — GENERAT, DAR NEFOLOSIT IN SCENA ---------
	#
	# NU e in Track13.tscn, si e o decizie luata pe captura, nu pe cifra.
	# Bolovanii au fost pusi (snapshots/poid/w5_*.png), priviti la 1:1 si
	# SCOSI: `rock_medium`/`rock_small` stau 71% pe slotul 3 (#C18446, masurat
	# cu ProbeCappSlots) — portocaliu deschis. Langa un perete acum ROSU ei
	# citesc a saci de nisip, nu a roca desprinsa din faleza. Jonctiunea
	# curata perete-pamant arata mai bine decat o poala de pete portocalii.
	#
	# Ce ar rezolva: o piesa de moloz din kitul cappadocia, care sa poata primi
	# clasa `red_valley_tuff` fara sa vopseasca rosu stancile de pe Track08 si
	# scatterul din track_decor (maparea din CLASSES_BY_MODEL e GLOBALA, iar
	# `Rock_Medium`/`Rock_Small` sunt nume comune — memoria
	# `nume-noduri-nu-sunt-unice`). Pana atunci, generatorul ramane aici cu
	# cifrele masurate, ca urmatoarea incercare sa nu porneasca de la zero.
	# --- (generarea de mai jos scrie fisierul, dar nimeni nu-l consuma) ------
	#
	# In referinta, jonctiunea perete-pamant NU e o linie: e o poala de
	# bolovani. Fara ea peretele se termina intr-o muchie matematica si se
	# vede ca primitiva asezata pe teren (exact reprosul de pe prima captura).
	#
	# Mesh-uri MICI pentru obiecte mici: rock_small/medium au 80 de triunghiuri
	# fiecare (masurate cu ProbeCappModule). Un bolovan de 1,5 m nu are voie sa
	# instantieze un mesh de mii de triunghiuri — lectia din CLAUDE.md.
	# Scara e in METRI derivati din marimea reala a GLB-ului, nu un factor
	# ghicit: rock_small are 1.63 m, rock_medium 3.04 m.
	var rubble: Array = []
	var f2 := F0
	while f2 < F1:
		var idx2 := int(f2 * float(n)) % n
		var p4: Vector3 = pts[idx2]
		var ahead2: Vector3 = pts[(idx2 + 10) % n]
		var d4 := (ahead2 - p4); d4.y = 0.0; d4 = d4.normalized()
		var sv := Vector3(d4.z, 0.0, -d4.x)
		var hw4: float = track.width_at(f2)
		# 2-3 pietre pe pas, la piciorul falezei (stanga ecranului).
		for j in range(rng.randi_range(3, 5)):
			# LIPIT de piciorul falezei, nu imprastiat pe berma. Pe captura
			# w4_044 pietrele ieseau pietricele portocalii pe pietris fiindca
			# stateau in mijlocul bermei, departe de perete. Poala de grohotis
			# se sprijina PE perete.
			var off4: float = hw4 + 4.2 + rng.randf_range(0.0, 3.4)
			var q4: Vector3 = p4 + sv * off4
			var g4: float = track._sampler.ground_y(q4.x, q4.z)
			# Cele mai multe mici, cateva medii: o poala de grohotis, nu un
			# sir de bolovani egali.
			# Bolovani, nu pietris: referinta are blocuri de 2-4 m cazute din
			# perete. La 0.45-1.15 m ieseau pietricele — sub pragul la care
			# ochiul le mai citeste ca roca desprinsa.
			var big: bool = rng.randf() < 0.45
			var base_m: float = 3.04 if big else 1.63
			var want_m: float = rng.randf_range(2.4, 4.2) if big else rng.randf_range(1.1, 2.1)
			rubble.append({"big": big, "x": q4.x, "y": g4 - want_m * 0.22,
				"z": q4.z, "yaw": rng.randf_range(0.0, TAU),
				"sc": want_m / base_m})
		f2 += 0.0055
	var rtxt := ""
	for r2 in rubble:
		rtxt += "%d	%.3f	%.3f	%.3f	%.4f	%.4f
" % [
			1 if r2["big"] else 0, r2["x"], r2["y"], r2["z"], r2["yaw"], r2["sc"]]
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
