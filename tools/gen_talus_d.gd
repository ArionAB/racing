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

## Inaltimea conului lipit de perete si raza pe care se stinge.
const CONE_H := 3.5
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

	var rows: Array = []
	var f := F0
	while f < F1:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		var sv := Vector3(d.z, 0.0, -d.x)
		var hw: float = track.width_at(f)
		for j in range(rng.randi_range(5, 9)):
			# t = 0 lipit de perete, t = 1 la marginea conului.
			# `pow` sub 1 ingramadeste majoritatea LANGA perete: acolo e masa
			# conului. Vechea versiune folosea 0.55 pe o distributie care
			# imprastia uniform, deci iesea un brau, nu o gramada.
			var t: float = pow(rng.randf(), 0.75)
			# Rarire spre exterior: la coada conului cad doua din trei.
			if rng.randf() < t * 0.62:
				continue
			var off: float = hw + CLEAR_M - 4.2 + t * CONE_R
			var along: float = rng.randf_range(-8.0, 8.0)
			var q: Vector3 = p + sv * off + d * along
			# MARIMEA SCADE CU DISTANTA — gradientul din verdict, in ordinea
			# corecta: blocuri de ~1.6 m lipite de perete, pietris de 0.35 m pe
			# acostament. (Generatorul vechi il avea inversat.)
			var want_m: float = lerpf(1.75, 0.38, t) * rng.randf_range(0.62, 1.5)
			var sc: float = want_m / MOD_LEN
			# GARDA DE CAROSABIL, ca la module: blocurile primesc corp fizic.
			# Distanta se ia ca MINIM pe o fereastra de indici, nu pe cel mai
			# apropiat index singur (traseul e un S aici — memoria
			# `pista-peste-pista`).
			var need: float = hw + 2.4 + want_m * 0.7
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
			var from_wall: float = maxf(0.0, lat_now - (hw + CLEAR_M - 4.2))
			var cone: float = CONE_H * pow(
				clampf(1.0 - from_wall / CONE_R, 0.0, 1.0), 1.4)
			# Cota: pamant + inaltimea conului, minus ingroparea. Blocurile de
			# sus stau PE moloz, nu pe teren — asta e ce face gramada sa aiba
			# volum in loc de contur.
			var y: float = g + cone - want_m * rng.randf_range(0.20, 0.45)
			rows.append({"x": q.x, "y": y, "z": q.z,
				"yaw": rng.randf_range(0.0, TAU),
				"pitch": rng.randf_range(-0.6, 0.6),
				"sc": sc})
		f += 0.0034
	var txt := ""
	for r in rows:
		txt += "%.3f\t%.3f\t%.3f\t%.4f\t%.4f\t%.5f\n" % [
			r["x"], r["y"], r["z"], r["yaw"], r["pitch"], r["sc"]]
	var fo := FileAccess.open("res://canyon_d_rubble.txt", FileAccess.WRITE)
	fo.store_string(txt)
	fo.close()
	print("talus: ", rows.size())
	get_tree().quit(0)
