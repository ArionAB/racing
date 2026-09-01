extends Node
## Acopera GAURILE de tavan ale POI-ului F: gatul dintre sali si intrarea gurii.
##
## [b]De ce exista, separat de `gen_decor_capp_f.gd`.[/b] Generatorul mare
## acopera doar cele doua SALI (`_hall` pe 0.664-0.698 si 0.720-0.753). Intre
## ele, gatul cu piatra de moara (0.698-0.720) primeste lacas si torte, dar
## NICIO lespede — si la fel bucata dinaintea gurii (0.640-0.664). Masurat cu
## raza in sus de pe axa benzii: 12 fractii din 36 raspund "TAVAN LIPSA", iar
## captura de sofer la frac 0.68 iese cu 4.32% din treimea de sus a cadrului
## CER ALB — adica exact "desert cu stalpi", accidentul impotriva caruia sunt
## scrisi peretii salilor.
##
## Nu se rescrie `_capp_f_nodes.txt`: sursa de adevar e acum .tscn-ul, editat si
## de mana. Sonda asta emite DOAR nodurile care lipsesc, de adaugat la sfarsit.
##
## Gatul e un CULOAR, nu o sala: tavanul coboara la 9 m (piatra de moara are
## 6.4 m si trebuie sa incapa rostogolindu-se), fara coloane si fara arcade —
## strangerea lui e chiar ce face saritura de scara cand intri in sala 2.
const OUT := "res://tools/_capp_f_gat_nodes.txt"

## Tavanul gatului. Mai jos decat salile (16/18 m): un culoar strans intre doua
## sali inalte e ce da scara salilor. Peste piatra de moara (6.4 m) ramane
## degajare, iar `ProbeBuried` cere minimum 4.5 m — 9.0 trece amandoua.
const GAT_H: float = 9.0
## Lespedea, ca in generatorul mare.
const CEIL_TILE: float = 12.0
## Peretele: aceeasi piesa si aceeasi scara ca in sali, ca sa cada in aceleasi
## sloturi intunecate si sa se stinga odata cu ele.
const WALL_SCALE: float = 2.6
const COL_OUT: float = 2.6

## Conul de grohotis de la piciorul peretelui: gradient de la blocuri de ~1 m
## (0.42 * 2.6 m de piesa) la pietris (0.17). Aceleasi randuri ca in sali.
const TALUS := [
	{"back": 0.9, "sc": 0.90, "dy": -0.55},
	{"back": 0.0, "sc": 0.58, "dy": -0.80},
	{"back": -0.9, "sc": 0.34, "dy": -1.00},
]

## Intervalele fara tavan, masurate cu `_pf_gap`: gatul si intrarea gurii.
## Se suprapun 0.004 peste sali ca sa nu ramana un rost la imbinare.
## Imbinarile unde tavanul face TREAPTA, si care raman deschise spre cer daca
## nu se pune un frontal. `lo`/`hi` sunt cotele celor doua tavane, peste drum.
const JOINTS := [
	{"f": 0.6975, "lo": 9.0, "hi": 16.6, "group": "F3_Gat", "tag": "gat1"},
	{"f": 0.7225, "lo": 9.0, "hi": 19.2, "group": "F3_Gat", "tag": "gat2"},
	{"f": 0.6650, "lo": 12.0, "hi": 16.6, "group": "F1_Gura", "tag": "gura1"},
]

const SPANS := [
	{"f0": 0.6955, "f1": 0.7245, "group": "F3_Gat", "tag": "gat", "h": GAT_H},
	{"f0": 0.6380, "f1": 0.6665, "group": "F1_Gura", "tag": "gura", "h": 12.0},
]


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 8:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var lines := PackedStringArray()
	# Numerotarea continua de dupa ultimul nod emis de generatorul mare (249),
	# ca sa nu se ciocneasca numele in .tscn.
	var counter := [500]

	var at := func(f: float) -> Dictionary:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		return {
			"c": c, "fw": fw,
			"side": Vector3(fw.z, 0.0, -fw.x).normalized(),
			"yaw": atan2(fw.x, fw.z),
			"hw": track.width_at(f),
		}

	var emit := func(group: String, nm: String, res: String, pos: Vector3,
			yaw: float, col: String, scale: float, roll: float = 0.0) -> void:
		var b := Basis(Vector3.UP, yaw)
		if not is_zero_approx(roll):
			# Ca in generatorul mare: ruliul e in spatiul piesei DUPA yaw, deci
			# se inmulteste la DREAPTA. La stanga ar fi in axele lumii si
			# bolovanii ar cadea in evantai pe portiunile in viraj.
			b = b * Basis(Vector3.FORWARD, roll)
		b = b.scaled(Vector3.ONE * scale)
		lines.append('[node name="%s_%d" parent="DecorManual/%s" instance=ExtResource("%s")]'
			% [nm, counter[0], group, res])
		lines.append('transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)' % [
			b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
		if not col.is_empty():
			lines.append('metadata/coliziune = "%s"' % col)
		lines.append("")
		counter[0] += 1

	for sp: Dictionary in SPANS:
		var f0: float = sp["f0"]
		var f1: float = sp["f1"]
		var span := f1 - f0
		var ceil_h: float = sp["h"]
		var group: String = sp["group"]
		var tag: String = sp["tag"]
		var a: Vector3 = (at.call(f0) as Dictionary)["c"]
		var b2: Vector3 = (at.call(f1) as Dictionary)["c"]
		var road_len := a.distance_to(b2)

		# --- TAVANUL: acelasi rand de trei lespezi ca in sali.
		var rows := int(ceil(road_len / CEIL_TILE)) + 1
		for row in rows:
			var f: float = f0 + span * (float(row) + 0.5) / float(rows)
			var d: Dictionary = at.call(f)
			var c: Vector3 = d["c"]
			var side: Vector3 = d["side"]
			for k: int in [-1, 0, 1]:
				emit.call(group, "tavan%s" % tag, "hall_ceiling_module",
					c + side * (CEIL_TILE * float(k)) + Vector3.UP * ceil_h,
					d["yaw"] as float, "mesh", 1.0)

		# --- PERETII, pana la tavan. Fara ei gatul ar fi un tunel cu peretii
		# deschisi lateral: cerul ar intra pe langa, adica gaura s-ar muta, nu
		# s-ar inchide.
		var wall_w := 3.2 * WALL_SCALE
		var wall_h := 3.0 * WALL_SCALE
		var wall_cols := int(ceil(road_len / wall_w)) + 1
		var wall_lvls := int(ceil(ceil_h / wall_h))
		for col in wall_cols:
			var f: float = f0 + span * (float(col) + 0.5) / float(wall_cols)
			var d: Dictionary = at.call(f)
			var c: Vector3 = d["c"]
			var side: Vector3 = d["side"]
			var hw: float = d["hw"]
			var yaw: float = d["yaw"]
			for sgn: float in [-1.0, 1.0]:
				for lvl in wall_lvls:
					# STRATELE IN TREPTE, si de ce abia acum pe gat.
					#
					# Variatia rundei 2 (trepte de 3.2 m, skew, jitter de scara)
					# a intrat DOAR in `gen_decor_capp_f.gd`, adica in cele doua
					# SALI. Gatul si gura ies din generatorul asta, si emiteau cu
					# WALL_SCALE fix, offset fix si yaw fix: numarat in .tscn,
					# 72 de panouri cu o singura valoare distincta de scara, fata
					# de 60 din 60 distincte in sali. Iar capturile cerute
					# (0.68, 0.72) cad exact aici — de-aia criticul vedea in
					# continuare "rafturi stantate" dupa ce runda 2 raportase
					# variatia rezolvata. Nu era amplitudine mica, era ZERO.
					#
					# Ce se pune, in cifrele cerute de cei trei critici:
					#   - offset de raza ALTERNANT pe banda: +-0.5 m (in
					#     intervalul cerut 0.4-0.6). Alternanta e pe `lvl`, deci
					#     fiecare etaj iese in consola peste cel de dedesubt si
					#     isi arunca propria linie de umbra. Asta e "pe profil",
					#     nu pe textura.
					#   - peste alternanta, treapta groasa de 0..3.2 m ca in
					#     sali, ca sirul sa nu devina un zigzag regulat — un
					#     perete sapat are si nise adanci, nu doar dantelarie.
					#   - skew de +-11.5 grade, ca fetele sa nu prinda toate
					#     aceeasi lumina (de acolo venea "placa paralela").
					var h := float((col * 73 + lvl * 149 + int(sgn) * 37) % 100) / 100.0
					var h2 := float((col * 31 + lvl * 211 + int(sgn) * 17) % 100) / 100.0
					var h3 := float((col * 97 + lvl * 53 + int(sgn) * 61) % 100) / 100.0
					var ws := WALL_SCALE * (0.94 + 0.18 * h)
					# Alternanta de banda: etajele pare ies, cele impare intra.
					var band := 0.5 if lvl % 2 == 0 else -0.5
					var step := float(int(h2 * 3.0)) * 1.6
					var depth := (hw + COL_OUT + 3.4) - step + band
					var skew := (h3 - 0.5) * 0.40
					emit.call(group, "perete%s" % tag, "hall_alcove",
						c + side * depth * sgn
							+ Vector3.UP * (wall_h * float(lvl)),
						yaw + (PI * 0.5 if sgn > 0.0 else -PI * 0.5) + skew,
						"hull", ws)
				# Poala, ca in sali: inchide fasia de acostament palid.
				emit.call(group, "poala%s" % tag, "hall_alcove",
					c + side * (hw + 0.55) * sgn,
					yaw + (PI * 0.5 if sgn > 0.0 else -PI * 0.5), "hull",
					WALL_SCALE)


		# --- GROHOTISUL, cu pas propriu.
		#
		# Vezi `gen_decor_capp_f.gd` pentru de ce e cerut si de ce tot din
		# `hall_alcove`. Are bucla LUI, nu a peretilor: peretele are pas de
		# 8.3 m, iar la pasul ala blocurile de ~2.9 m ies razlete si linia de
		# imbinare ramane vizibila printre ele. La 1.9 m talpa e continua.
		var tal_cols := int(ceil(road_len / 1.9)) + 1
		for col in tal_cols:
			var f: float = f0 + span * (float(col) + 0.5) / float(tal_cols)
			var d: Dictionary = at.call(f)
			var c: Vector3 = d["c"]
			var side: Vector3 = d["side"]
			var hw: float = d["hw"]
			for sgn: float in [-1.0, 1.0]:
				for ri in TALUS.size():
					var row: Dictionary = TALUS[ri]
					var g1 := float((col * 41 + ri * 167 + int(sgn) * 23) % 100) / 100.0
					var g2 := float((col * 89 + ri * 43 + int(sgn) * 71) % 100) / 100.0
					var g3 := float((col * 13 + ri * 197 + int(sgn) * 59) % 100) / 100.0
					var along := (g1 - 0.5) * 2.6
					var back: float = float(row["back"]) + (g2 - 0.5) * 0.5
					var tsc: float = float(row["sc"]) * (0.72 + 0.56 * g3)
					emit.call(group, "grohotis%s" % tag, "hall_alcove",
						c + (d["fw"] as Vector3) * along
							+ side * (hw - 0.35 + back) * sgn
							+ Vector3.UP * float(row["dy"]),
						g1 * TAU, "hull", tsc, (g3 - 0.5) * 0.9)

	# --- FRONTOANELE: peretii care inchid TREAPTA de tavan.
	#
	# Gatul are 9 m si salile 16/18: la imbinare ramane o rama verticala de
	# 7-9 m INTRE cele doua tavane, prin care se vede cerul. Raza pe verticala
	# nu o gaseste (trece pe langa treapta), dar evantaiul de la nivelul ochiului
	# da CER intre 18 si 20 de grade la frac 0.68 — si pe captura e chiar petecul
	# alb de deasupra drumului. Se inchide cu acelasi perete, pus TRANSVERSAL.
	for jn: Dictionary in JOINTS:
		var fj: float = jn["f"]
		var lo: float = jn["lo"]
		var hi: float = jn["hi"]
		var group: String = jn["group"]
		var d: Dictionary = at.call(fj)
		var c: Vector3 = d["c"]
		var side: Vector3 = d["side"]
		var yaw: float = d["yaw"]
		var wall_h := 3.0 * WALL_SCALE
		var wall_w := 3.2 * WALL_SCALE
		var lvls := int(ceil((hi - lo) / wall_h))
		# Lat cat sa acopere si peretii laterali, nu doar banda.
		var cols := int(ceil((CEIL_TILE * 2.4) / wall_w))
		for lvl in lvls:
			for k in range(-cols, cols + 1):
				emit.call(group, "fronton%s" % jn["tag"], "hall_alcove",
					c + side * (wall_w * float(k))
						+ Vector3.UP * (lo + wall_h * float(lvl)),
					yaw, "hull", WALL_SCALE)

	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(lines))
	fa.close()
	print("scrise %d noduri in %s" % [counter[0] - 500, OUT])
	get_tree().quit()
