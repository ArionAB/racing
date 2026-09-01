extends Node
## RUNDA 3 — treptele de strat, ca GEOMETRIE REALA lipita pe FATA MASURATA.
##
## De ce nu se putea in placement: modulul de faleza NU are trepte in profil.
## Masurat cu ProbeCappProf2 pe vertecsii reali, fata dinspre sosea merge NETED
## de la z = -3.82 (baza) la z = -1.20 (creasta) pe 12.4 m — un taper continuu,
## fara nicio suprafata orizontala. „Benzile" de pe captura sunt EXCLUSIV
## textura, si niciun aranjament de module nu le putea face sa arunce umbra: nu
## exista muchie care s-o arunce.
##
## PRIMA VERSIUNE A ACESTUI GENERATOR A PICAT, si merita scris de ce, fiindca e
## capcana centrala a POI-ului. Treptele erau derivate din `canyon_d_rows.txt`
## — centrul fiecarui modul — plus profilul LOCAL al modulului. Dar modulele au
## jitter de ±6 m pe normala si se SUPRAPUN, deci fata vizibila a peretelui la o
## fractie data e ANVELOPA lor, nu profilul modulului de acolo. Masurat cu
## ProbeLedge: din 8 trepte, 6 erau ingropate cu 3.8..8.0 m IN perete si 2
## ieseau cu 3.4..4.9 m in aer. Pe captura, peretele arata neschimbat — 184 de
## cutii invizibile. Cifra corecta nu se putea GHICI din datele de rand.
##
## Acum fata vine din ProbeWallFace (`canyon_d_face.txt`): pentru un caroiaj
## (fractie x cota), distanta laterala pana la cel mai apropiat vertex de
## perete. Treapta se aseaza pe distanta AIA, deci iese exact cat trebuie
## oriunde ar fi ajuns modulele.

const MOD_LEN := 20.30
const F0 := 0.428
const F1 := 0.534
const FACE := "res://canyon_d_face.txt"

## Cat iese fiecare treapta din fata peretelui, in METRI.
##
## VERDICTUL CEREA 0.4..0.6 m, S-A CONSTRUIT ASA, SI NU S-A VAZUT. Captura de
## la 1:1 (zz/crop_step3_wall.png) arata treptele ca pe o tenta mai inchisa in
## textura, nu ca pe o muchie. Cifra din verdict nu e gresita — e data pentru
## HORNURI, care au raza de 2-4 m; aici peretele are 25 m inaltime si module de
## 20 m cu jitter de ±6 m pe normala. O buza de 0.5 m e 2% din inaltimea
## peretelui, adica SUB zgomotul de asezare al modulelor: ochiul o citeste ca
## variatie de textura, exact ca „jitterul de ±9%" pe care alt critic il
## respinsese ca invizibil.
##
## Marimea se DERIVA din perete, nu se copiaza din verdict: pentru ca o treapta
## sa se citeasca drept treapta trebuie sa iasa comparabil cu neregularitatea pe
## care o intrerupe. Jitterul modulelor e ±6 m, deci o consola de 1.6..2.6 m e
## primul prag la care muchia nu mai poate fi confundata cu asezarea. Umbra
## proiectata creste la fel: la soare de 13 grade, 2 m dau 2/tan(13) = 8.7 m de
## banda umbrita, adica o TREIME din inaltimea peretelui.
const OUT_MIN := 1.60
const OUT_MAX := 2.60

## Buza de sus, TARE (o singura cutie, fara tesire). Ramane cifra din verdict
## ca ORDIN DE MARIME dar scalata la fel: fata orizontala trebuie sa se vada de
## la 40 m, iar 0.3 m la distanta aia e sub un pixel.
const LIP := 0.85

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	# Fata masurata: fractie -> [{y, lat}]
	var face := {}
	var fa := FileAccess.open(FACE, FileAccess.READ)
	while not fa.eof_reached():
		var line := fa.get_line()
		if line.strip_edges().is_empty():
			continue
		var p := line.split("\t")
		var f := float(p[0])
		if not face.has(f):
			face[f] = []
		face[f].append({"y": float(p[1]), "lat": float(p[2]),
			"cnt": int(p[3])})
	fa.close()

	# VERTECSII PERETELUI, pentru garda finala. Densitatea pe felie (`cnt`) NU
	# e un discriminant suficient: masurat, o felie „bogata" poate avea toata
	# roca la alta cota decat cea aleasa, iar treapta iese in gol. Singurul
	# test care tine e cel direct — exista roca IN SPATELE cutiei asezate?
	var faleza_n := track.get_node_or_null(
		"DecorManual/D) Canionul rosu/Faleza")
	var wall: PackedVector3Array = PackedVector3Array()
	for mi in faleza_n.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null:
			continue
		var xfw := (mi as MeshInstance3D).global_transform
		for si in mm.get_surface_count():
			var arr := mm.surface_get_arrays(si)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				wall.append(xfw * v)

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	var keys: Array = face.keys()
	keys.sort()

	var rows: Array = []
	# Un pas de ~7 m in lungul peretelui: treptele sunt piese de 9-16 m care se
	# suprapun putin, deci banda arata continua fara sa fie un singur bloc.
	var last_f := -1.0
	for f: float in keys:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		if last_f >= 0.0:
			var pl: Vector3 = pts[int(last_f * float(n)) % n]
			if p.distance_to(pl) < 5.0:
				continue
		last_f = f
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		var sv := Vector3(d.z, 0.0, -d.x)
		var lst: Array = face[f]
		# Peretele nu e la fel de inalt peste tot: se iau doar cotele la care
		# chiar exista perete APROAPE (sub 26 m lateral). Mai departe de atat e
		# alt mal, iar o treapta acolo ar pluti in aer.
		var usable: Array = []
		for e in lst:
			# Se cere si ROCA, nu doar o cota valida: sub 14 vertecsi in felie
			# peretele e doar cateva varfuri de creasta, iar o treapta pusa
			# acolo iese in cer dezlipita (placa de langa varf de pe
			# zz/r3_step3_048.png, gasita cu ProbeLedge3).
			if float(e["lat"]) < 26.0 and int(e["cnt"]) >= 14:
				usable.append(e)
		if usable.size() < 2:
			continue
		# 3-4 trepte pe felie, la cote alese din cele masurate. RITM RUPT CU
		# DISTANTA — cererea explicita a criticului: „ritmul se repeta identic
		# la 15 m si la 200 m, deci citeste ca ZIDARIE". Cotele se trag la
		# intamplare din lista, nu la pas fix, deci doua felii vecine n-au
		# straturile la aceeasi inaltime si linia de curs nu mai trece continuu
		# prin trei module.
		var want: int = rng.randi_range(5, 7)
		var picked: Array = []
		var tries := 0
		while picked.size() < want and tries < 40:
			tries += 1
			var e: Dictionary = usable[rng.randi() % usable.size()]
			var ey: float = float(e["y"]) + rng.randf_range(-1.3, 1.3)
			var dup := false
			for q in picked:
				if absf(float(q["y"]) - ey) < 2.2:
					dup = true
					break
			if dup:
				continue
			picked.append({"y": ey, "lat": float(e["lat"])})
		for e in picked:
			var ey: float = float(e["y"])
			var lat: float = float(e["lat"])
			# Cat iese. Alterneaza tare: o treapta groasa, una subtire, ca
			# profilul sa fie o scara crestata, nu o panta.
			var outw: float = rng.randf_range(OUT_MIN, OUT_MAX)
			if rng.randf() < 0.4:
				outw *= 0.55
			# Lungimea: 9-17 m, NU tot peretele. O banda continua ar reface
			# exact „cursul de zidarie" pentru care a picat runda 2.
			var blen: float = rng.randf_range(9.0, 17.0)
			var along: float = rng.randf_range(-3.0, 3.0)
			# NU se ia minimul fetei pe toata lungimea treptei. S-A INCERCAT
			# SI S-A REVENIT, si e cea mai instructiva greseala a rundei.
			# Ideea parea corecta — o treapta de 9-17 m acopera mai multe
			# felii, deci sa iasa in fata celui mai avansat perete de sub ea —
			# dar pe captura (zz/r3_step2_048.png) a produs exact capcana
			# rundei 17: peretele are pinteni de ±6 m, deci „cel mai avansat"
			# insemna 6 m in fata fetei locale, iar treptele au iesit ca niste
			# SCANDURI plutind peste sosea si peste cer, dezlipite de roca.
			# Detaliul pus ca RAMA peste perete arata mai rau decat lipsa lui.
			# Treapta ramane ancorata pe fata din dreptul ei; ce se acopera
			# dupa un pinten, se acopera.
			# Cutia se INFIGE in perete cu 1.4 m, deci imbinarea sta in
			# interiorul rocii: extrudat din profil, nu rama pusa peste
			# (capcana rundei 17).
			var depth: float = 2.20 + outw
			var cl: float = lat - outw + depth * 0.5
			var pos: Vector3 = p + d * along + sv * cl
			pos.y = ey
			var yaw: float = atan2(-sv.x, -sv.z) + rng.randf_range(-0.06, 0.06)
			# GARDA „IN AER", pe ROCA REALA din spatele cutiei asezate.
			# Punctul se ia din spatele treptei (spre deal), acolo unde ea
			# trebuie sa fie ingropata; daca nu e niciun vertex de perete la
			# mai putin de 3 m, treapta pluteste si se arunca.
			# Masurat cu ProbeLedge3: fara garda, 9-10 din 74 ieseau in cer,
			# grupate pe portiunea unde peretele se retrage (x≈120, z≈-165) si
			# fata masurata venea de pe un modul indepartat.
			# Se verifica DOUA puncte din spatele cutiei, nu unul: o treapta
			# lunga poate avea un capat in roca si celalalt in gol, iar un
			# singur esantion in mijloc n-ar prinde-o. Pragul e reglat pe
			# masuratoare, nu ales: la 3.0 m treceau tot 8 din 72 in aer, la
			# 2.0 m ramaneau doar 26 de trepte pe tot peretele (prea putine ca
			# sa faca strate). 2.3 m e compromisul masurat.
			var ok_rock := true
			for tt in [-0.3, 0.3]:
				var back: Vector3 = pos + sv * (depth * 0.35) 					+ d * (blen * tt)
				var near_rock := 1e9
				for wv in wall:
					var dsq: float = back.distance_squared_to(wv)
					if dsq < near_rock:
						near_rock = dsq
				if sqrt(near_rock) > 2.3:
					ok_rock = false
					break
			if not ok_rock:
				continue
			rows.append({"x": pos.x, "y": pos.y, "z": pos.z, "yaw": yaw,
				"len": blen, "lip": LIP, "depth": depth})
	var txt := ""
	for r in rows:
		txt += "%.3f\t%.3f\t%.3f\t%.4f\t%.3f\t%.3f\t%.3f\n" % [
			r["x"], r["y"], r["z"], r["yaw"], r["len"], r["lip"], r["depth"]]
	var fo := FileAccess.open("res://canyon_d_strata.txt", FileAccess.WRITE)
	fo.store_string(txt)
	fo.close()
	print("strata: ", rows.size())
	get_tree().quit(0)
