extends Node
## RUNDA 3 — conul de grohotis, refacut ca UN CON, nu ca un plint.
##
## Verdictul criticului meu despre poala existenta (87 de module la scara mica):
## „reads as skirting rather than a pile" — un chenar, fiindca sta intr-un RAND
## ORDONAT LA INALTIME UNIFORMA. Cauza e in generatorul vechi: fiecare bloc era
## asezat pe `ground_y` minus un sfert din marimea lui, deci varfurile tuturor
## ieseau la aceeasi cota deasupra pamantului. Un con de grohotis real n-are
## cota uniforma: e GROS lipit de perete (metri buni de moloz stivuit) si se
## subtiaza pana la pietris pe acostament.
##
## Deci aici cota NU mai vine din `ground_y` singur: se adauga o INALTIME DE CON
## care scade cu distanta de perete. Langa perete conul are 3.5 m, la 12 m are
## zero. Asta face si a doua cerere din verdict — „sa INGROAPE imbinarea, ca
## linia solului sa nu se mai vada ca o curba continua": cu 3.5 m de moloz lipit
## de perete, talpa peretelui nu mai e vizibila deloc.
##
## GRADIENTUL de marime e cel cerut: ~1 m si mai mult la baza, pietris afara.
## Vechiul generator il avea INVERS (2.6 m langa perete, 6.4 m afara) — adica
## bolovanii mari stateau departe de perete, care e exact contrariul fizicii
## unui talus si contribuia la citirea de „chenar decorativ".

const MOD_LEN := 20.30
const F0 := 0.428
const F1 := 0.534
const CLEAR_M := 7.4
const FACE := "res://canyon_d_face.txt"

## Inaltimea conului lipit de perete si raza pe care se stinge.
const CONE_H := 5.0
const CONE_R := 12.0

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
	rng.seed = 771

	# PICIORUL PERETELUI, MASURAT (ProbeWallFace), nu presupus.
	#
	# Versiunea trecuta punea blocurile la `hw + CLEAR_M - 4.2` de ax, adica
	# presupunea ca talpa peretelui sta la un offset FIX. Nu sta: fata masurata
	# variaza intre 2 si 28 m lateral, fiindca modulele au jitter de ±6 m si se
	# suprapun. Rezultatul masurat cu ProbeTalus: talpa peretelui era acoperita
	# in proportie de 2%, iar conul iesea INVERS — blocurile stateau cel mai
	# JOS lipite de perete (+1.20 m) si cel mai SUS la 9-12 m in fata lui
	# (+3.59 m). Exact „un plint, nu o gramada", cuvintele criticului.
	#
	# Se ia cota cea mai de JOS masurata pe fiecare fractie: aia e talpa.
	var foot := {}
	var fa := FileAccess.open(FACE, FileAccess.READ)
	while not fa.eof_reached():
		var line := fa.get_line()
		if line.strip_edges().is_empty():
			continue
		var pp := line.split("	")
		var ff := float(pp[0])
		var yy := float(pp[1])
		var ll := float(pp[2])
		if not foot.has(ff) or yy < float(foot[ff]["y"]):
			foot[ff] = {"y": yy, "lat": ll}
	fa.close()
	var fkeys: Array = foot.keys()
	fkeys.sort()

	var rows: Array = []
	var f := F0
	while f < F1:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		var sv := Vector3(d.z, 0.0, -d.x)
		var hw: float = track.width_at(f)
		for j in range(rng.randi_range(9, 14)):
			# t = 0 lipit de perete, t = 1 la marginea conului.
			# `pow` sub 1 ingramadeste majoritatea LANGA perete: acolo e masa
			# conului. Vechea versiune folosea 0.55 pe o distributie care
			# imprastia uniform, deci iesea un brau, nu o gramada.
			var t: float = pow(rng.randf(), 1.15)
			# Rarire spre exterior: la coada conului cad doua din trei.
			if rng.randf() < t * 0.62:
				continue
			# Talpa peretelui la fractia asta, din masuratoare.
			var wall_lat: float = hw + CLEAR_M - 4.2
			var bestd := 1e9
			for fk: float in fkeys:
				var dd: float = absf(fk - f)
				if dd < bestd:
					bestd = dd
					wall_lat = float(foot[fk]["lat"])
			# SEMNUL. `lat` creste DEPARTANDU-SE de sosea, iar peretele e
			# partea departata — deci conul trebuie sa mearga de la fata
			# peretelui SPRE SOSEA, adica lateral in SCADERE. Prima versiune
			# scria `wall_lat - 1.5 + t * CONE_R`, ceea ce ducea molozul si mai
			# departe, adica IN DEAL: masurat cu ProbeTalus2, 402 din 406 de
			# blocuri ajunsesera in spatele fetei, invizibile, si poala
			# disparuse complet de pe captura.
			# `+1.2` il baga un metru IN perete, ca imbinarea sa fie ingropata
			# sub moloz, nu aliniata langa ea (cererea din verdict).
			# Conul nu poate fi mai lat decat spatiul dintre fata peretelui si
			# linia pana la care garda de carosabil lasa blocurile. Fara
			# limitarea asta, `t` mare trimitea blocul peste linia garzii,
			# garda il impingea inapoi IN deal, si molozul ajungea invizibil:
			# masurat cu ProbeTalus2, 344 din 406 erau tot in spatele fetei
			# chiar si dupa ce semnul a fost corectat.
			var room: float = maxf(2.0, (wall_lat + 1.2) - (hw + 3.4))
			var span: float = minf(CONE_R, room)
			var off: float = wall_lat + 1.2 - t * span
			var along: float = rng.randf_range(-8.0, 8.0)
			var q: Vector3 = p + sv * off + d * along
			# MARIMEA SCADE CU DISTANTA — gradientul din verdict, in ordinea
			# corecta: blocuri de ~1.6 m lipite de perete, pietris de 0.35 m pe
			# acostament. (Generatorul vechi il avea inversat.)
						# Minimul e 1.10 m, nu 0.42. Blocurile foarte mici erau cele mai
			# patate: mesh-ul modulului are 1208 triunghiuri desenate pentru o
			# faleza de 20 m, iar strans la o jumatate de metru fetele lui
			# interioare ajung la fractiuni de milimetru una de alta si se bat
			# pe adancime — grile de puncte negre pe captura de aproape
			# (zz/vc_crop.png), mult mai dese decat pe ramura de baza
			# (zz/base_crop_speckle.png), unde blocurile erau mai mari.
			# „Pietrisul" din verdict nu se poate face din piesa asta; ce se
			# poate face e sa nu coboare sub pragul la care ea se sparge.
			var want_m: float = lerpf(3.10, 1.10, t) * rng.randf_range(0.75, 1.35)
			var sc: float = want_m / MOD_LEN
			# GARDA DE CAROSABIL, ca la module: blocurile primesc corp fizic.
			# Distanta se ia ca MINIM pe o fereastra de indici, nu pe cel mai
			# apropiat index singur (traseul e un S aici — memoria
			# `pista-peste-pista`).
						# 3.2, nu 2.4: cu blocuri de pana la 3.1 m (marite in runda asta),
			# marja veche lasa un colt pe banda — ProbeRace a oprit masini pe
			# Bloc_130/164/171 la frac 0.459, iar ProbeClearD a gasit Bloc_172
			# la 5.49 m lateral. Garda masoara CENTRUL, deci marja trebuie sa
			# acopere jumatatea de bloc plus rotatia lui.
			# 3.2, nu 2.4: cu blocuri de pana la 3.1 m (marite in runda asta),
			# marja veche lasa un colt pe banda — ProbeClearD gasise Bloc_172
			# la 5.49 m lateral pe o banda de 5.5. Garda masoara CENTRUL, deci
			# marja acopera jumatatea de bloc plus rotatia lui.
			#
			# NU mai mult de atat, si asta e o concluzie corectata pe date.
			# O vreme am crezut ca poala provoaca blocajele de la frac 0.458 si
			# am urcat marja la 5.6, am rarit blocurile de la 330 la 119 si am
			# coborat conul — niciuna n-a miscat cifra (32-33 de repuneri de
			# fiecare data). Masuratoarea care a lamurit: pe RAMURA DE BAZA,
			# fara nimic din runda 3, ProbeRace da 34 de repuneri, de trei ori
			# la rand. Cu treptele si poala noua da 29-32. Blocajul de la gura
			# hornului e VECHI (masinile sunt impinse de `state_col`, colizorul
			# hornului crapat, la 144,23,-174), iar geometria rundei 3 nu-l
			# inrautateste — il imbunatateste marginal.
			#
			# Primul meu A/B spusese contrariul si era GRESIT: taiase fisierul
			# de la grupul Grohotis incolo, adica scosese si tot ce urma dupa
			# el, nu doar cele doua grupuri. Comparatia corecta se face fata de
			# ramura de baza, si pe mai multe rulari (memoria
			# `proberace-nedeterminism`: Jolt e multithread, o rulare nu decide).
			var need: float = hw + 3.2 + want_m * 0.85
			var guard := 0
			while guard < 24:
				var lat := 1e9
				var ci: int = track.closest_index_global(q)
				for w in range(-40, 41, 4):
					var iw: int = ((ci + w) % n + n) % n
					lat = minf(lat, absf(track.lateral_distance(iw, q)))
				if lat >= need:
					break
				q += sv * (need - lat + 0.25)
				guard += 1
			var g: float = track._sampler.ground_y(q.x, q.z)
			# Distanta REALA fata de piciorul peretelui, dupa ce garda a impins
			# blocul: `t` de mai sus e cea dorita, nu cea obtinuta. Inaltimea
			# conului se ia din cea obtinuta, altfel un bloc impins afara de
			# garda ar ramane cocotat pe cota lui veche.
			var lat_now := 1e9
			var ci2: int = track.closest_index_global(q)
			for w2 in range(-40, 41, 4):
				var iw2: int = ((ci2 + w2) % n + n) % n
				lat_now = minf(lat_now, absf(track.lateral_distance(iw2, q)))
			var from_wall: float = maxf(0.0, (wall_lat + 1.2) - lat_now)
			var cone_span: float = maxf(3.0, span)
			var cone: float = CONE_H * pow(
				clampf(1.0 - from_wall / cone_span, 0.0, 1.0), 1.4)
			# Cota: pamant + inaltimea conului, minus ingroparea. Blocurile de
			# sus stau PE moloz, nu pe teren — asta e ce face gramada sa aiba
			# volum in loc de contur.
			var y: float = g + cone - want_m * rng.randf_range(0.20, 0.45)
			# ANTI Z-FIGHTING, prin DISTANTA, nu prin scara.
			#
			# Blocurile sunt acelasi mesh; doua care se intrepatrund adanc au
			# fete COPLANARE care se bat pe adancime, si pe captura ies pete
			# negre pe toata poala (vizibil la 1:1 pe zz/foot_step7.png).
			# Masurat cu ProbeZFight pe versiunea densa: 167 de perechi
			# intrepatrunse adanc, 55 dintre ele cu scari aproape egale.
			#
			# Generatorul vechi incerca sa scape cu scari CLAR diferite
			# (0.62..1.45), dar densitatea noua a depasit trucul ala: la 406 de
			# blocuri se ating oricum. Se refuza direct plasarea prea aproape
			# de un bloc deja pus — se cere ca centrele sa fie la peste 62% din
			# suma razelor, adica blocurile se ating si se sprijina, dar nu se
			# trec unul prin altul.
			var too_close := false
			for prev in rows:
				var pr: Vector3 = Vector3(prev["x"], prev["y"], prev["z"])
				var rr: float = (want_m + float(prev["m"])) * 0.5
				if Vector3(q.x, y, q.z).distance_to(pr) < rr * 0.62:
					too_close = true
					break
			if too_close:
				continue
			rows.append({"m": want_m, "x": q.x, "y": y, "z": q.z,
				"yaw": rng.randf_range(0.0, TAU),
				"pitch": rng.randf_range(-0.6, 0.6),
				"sc": sc})
		f += 0.0022
	var txt := ""
	for r in rows:
		txt += "%.3f\t%.3f\t%.3f\t%.4f\t%.4f\t%.5f\n" % [
			r["x"], r["y"], r["z"], r["yaw"], r["pitch"], r["sc"]]
	var fo := FileAccess.open("res://canyon_d_rubble.txt", FileAccess.WRITE)
	fo.store_string(txt)
	fo.close()
	print("talus: ", rows.size())
	get_tree().quit(0)
