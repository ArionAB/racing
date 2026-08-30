extends Node
## Generator pentru POI F — ORASUL SUBTERAN (frac 0.655-0.760).
##
## Asaza piesele pe geometria REALA a motorului (routes[0].baked + width_at),
## nu pe cotele din brief: masurat, drumul de acolo coboara 13.68 -> 12.10 m si
## coteste ~80 de grade intre gura si iesire, deci o sala desenata pe cifre fixe
## ar fi iesit stramba fata de banda.
##
## [b]DE CE TAVANUL E DIN PIESE, NU DIN TEREN.[/b] Campul de inaltime e o
## functie de (x,z): peste un punct nu poate avea si podea, si tavan. In plus
## `_lift_peaks` mascheaza masivele cu banda de protectie a asfaltului
## (PEAK_ROAD_CLEAR 6 m -> PEAK_ROAD_FULL 32 m), deci terenul nu are voie sa
## treaca peste sosea — prin constructie, nu din intamplare. Caverna se face
## deci din lespezi (`hall_ceiling_module`), iar masivul din jur (`TerrainPeak`)
## da muntele in care e sapata gura. Consecinta pentru garda: `ProbeBuried`
## intreaba doar `TerrainBody`, deci `tavane` ramane 0 — vezi raportul.
const OUT := "res://tools/_capp_f_nodes.txt"

## Cotele de tavan, pe sala (brief §2 POI F). Sunt aceleasi cifre care se pun pe
## `CameraZone.ceiling`: implicitul de 15.0 le-ar rata pe amandoua (masurat in
## cappadocia_geometrie.md §F — 25.1 m si 30.3 m, peste pragul de 25).
const CEIL_H1: float = 16.0
const CEIL_H2: float = 18.0
## Lespedea de tavan: 12x12 m, si creste IN SUS de la origine (masurat AABB
## y[0.00 +1.99]). Originea se pune deci la cota tavanului, iar nervurile si
## stalactitele atarna sub ea.
const CEIL_TILE: float = 12.0
## Coloanele: piesa are 5.44 m (masurat), sala are 16-18 m. Se scaleaza pe
## inaltimea salii — o coloana "sapata" se ingroasa la ambele capete, deci
## scalarea uniforma ramane citibila (spre deosebire de un fus clasic).
const COL_H: float = 5.44
## Cat de departe de marginea benzii stau coloanele.
const COL_OUT: float = 2.6
## Flacara tortei: slotul 30 (LAVA_ORANGE) aprins peste atlas.
##
## Nu e cosmetica — e SINGURA sursa de lumina din sala. Cu ambientul stins de
## `CameraZone.darkness`, o torta care nu arde e un fier ruginit intr-o pestera
## neagra, iar referinta (`v3_crops/F_underground.png`) traieste tocmai din
## contrastul dintre petele calde si restul. Energia e mare fiindca in jur nu
## mai e nimic care sa lumineze.
const TORCH_GLOW := "30|4.5|#FFB061"


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var lines := PackedStringArray()
	var counter := [0]

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

	# Emite un nod. `col` = metadata de coliziune ("" = implicitul hull).
	# `roll` inclina piesa in jurul axei ei de INAINTARE (dupa yaw), ca o
	# lespede de tavan sa poata deveni panou de perete fara o piesa noua.
	var emit := func(group: String, nm: String, res: String, pos: Vector3,
			yaw: float, col: String, scale: float, roll: float = 0.0,
			glow: String = "") -> void:
		var b := Basis(Vector3.UP, yaw)
		if not is_zero_approx(roll):
			# Rotatia e in spatiul piesei DUPA yaw, deci se inmulteste la
			# DREAPTA: b * R. La stanga ar fi fost in axele lumii, si panourile
			# ar fi cazut in evantai pe portiunile in viraj.
			b = b * Basis(Vector3.FORWARD, roll)
		b = b.scaled(Vector3.ONE * scale)
		lines.append('[node name="%s_%d" parent="DecorManual/%s" instance=ExtResource("%s")]'
			% [nm, counter[0], group, res])
		# Cele 12 numere sunt pe LINII: basis.x = (a0, a3, a6). Scrise pe coloane
		# iese transpusa, adica rotatia inversa (lectia din fix_cq_fatade.gd).
		lines.append('transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)' % [
			b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
		if not col.is_empty():
			lines.append('metadata/coliziune = "%s"' % col)
		if not glow.is_empty():
			lines.append('metadata/lumina = "%s"' % glow)
		lines.append("")
		counter[0] += 1

	# ---------------------------------------------------------------- GURA
	# Arcul sapat in faleza: 15 m lat, 12.5 m inalt (masurat), deci acopera banda
	# de 8 m si lasa buiandrug deasupra. Coliziune "mesh": hull-ul unui arc e un
	# bloc plin, adica un zid invizibil peste sosea.
	var g: Dictionary = at.call(0.658)
	emit.call("F1_Gura", "gura", "cave_entrance", g["c"] as Vector3,
		g["yaw"] as float, "mesh", 1.0)
	for sgn: float in [-1.0, 1.0]:
		var p: Vector3 = (g["c"] as Vector3) + (g["side"] as Vector3) * 5.6 * sgn
		emit.call("F1_Gura", "tortaGura", "torch", p,
			(g["yaw"] as float) + (PI * 0.5 if sgn > 0.0 else -PI * 0.5),
			"none", 1.0, 0.0, TORCH_GLOW)

	# ------------------------------------------------------------- SALA 1
	_hall(at, emit, 0.664, 0.698, CEIL_H1, "F2_Sala1", "s1", false)
	# Putul de ventilatie: coloana de lumina care cade PE DRUM (brief §2 POI F).
	# Se aseaza IN tavan, cu axul putin lateral, ca fasciculul sa taie banda in
	# diagonala in loc s-o urmeze.
	var v1: Dictionary = at.call(0.679)
	emit.call("F2_Sala1", "putSala1", "vent_shaft",
		(v1["c"] as Vector3) + (v1["side"] as Vector3) * 2.4
			+ Vector3.UP * CEIL_H1, v1["yaw"] as float, "none", 1.0)

	# --------------------------------------------------- GATUL CU PIATRA
	# Lacasul din care iese piatra: in peretele culoarului SCURT (dreapta).
	# Piesa e un bloc de perete cu jgheab — se uita spre sosea.
	var m: Dictionary = at.call(0.7065)
	emit.call("F3_Gat", "lacasPiatra", "millstone_slot",
		(m["c"] as Vector3) + (m["side"] as Vector3) * ((m["hw"] as float) + 1.9),
		(m["yaw"] as float) - PI * 0.5, "hull", 1.0)
	# Torte pe gat: singura lumina intre cele doua sali.
	for ff: float in [0.701, 0.712]:
		var t: Dictionary = at.call(ff)
		var tp: Vector3 = (t["c"] as Vector3) - (t["side"] as Vector3) * ((t["hw"] as float) - 0.4)
		emit.call("F3_Gat", "tortaGat", "torch", tp,
			(t["yaw"] as float) + PI * 0.5, "none", 1.0, 0.0, TORCH_GLOW)

	# ------------------------------------------------------------- SALA 2
	# Biserica rupestra: acelasi schelet, dar cu arcade de biserica si fresce.
	_hall(at, emit, 0.720, 0.753, CEIL_H2, "F4_Sala2", "s2", true)
	var v2: Dictionary = at.call(0.737)
	emit.call("F4_Sala2", "putSala2", "vent_shaft",
		(v2["c"] as Vector3) - (v2["side"] as Vector3) * 2.4
			+ Vector3.UP * CEIL_H2, v2["yaw"] as float, "none", 1.0)

	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(lines))
	fa.close()
	print("scrise %d noduri in %s" % [counter[0], OUT])
	get_tree().quit()


## O sala: tavan din lespezi, coloane si alcove pe pereti, arcade transversale,
## torte. `church` schimba arcada cu cea de biserica (fresce) — sala 2.
func _hall(at: Callable, emit: Callable, f0: float, f1: float, ceil_h: float,
		group: String, tag: String, church: bool) -> void:
	var span := f1 - f0
	# Lungimea salii se ia din pozitii REALE, nu din fractie: pe fractie pasul
	# ar varia cu curbura si lespezile ar lasa rosturi in viraj.
	var a: Vector3 = (at.call(f0) as Dictionary)["c"]
	var b: Vector3 = (at.call(f1) as Dictionary)["c"]
	var road_len := a.distance_to(b)

	# --- TAVANUL: randuri de cate trei lespezi, cat sa acopere si peretii.
	var rows := int(ceil(road_len / CEIL_TILE)) + 1
	for row in rows:
		var f: float = f0 + span * (float(row) + 0.5) / float(rows)
		var d: Dictionary = at.call(f)
		var c: Vector3 = d["c"]
		var side: Vector3 = d["side"]
		# Trei lespezi in latime: caverna e mai lata decat banda (brief §2.0 —
		# camera sta la 10 m si `_unclip` o impinge afara din pereti).
		for k: int in [-1, 0, 1]:
			emit.call(group, "tavan%s" % tag, "hall_ceiling_module",
				c + side * (CEIL_TILE * float(k)) + Vector3.UP * ceil_h,
				d["yaw"] as float, "mesh", 1.0)

	# --- COLOANELE: perechi la ~11 m, scalate pe inaltimea salii.
	# Scara e pe inaltime: coloana e ce a RAMAS din stanca, deci se ingroasa la
	# ambele capete si suporta scalarea uniforma fara sa arate ca un fus intins.
	var col_scale := ceil_h / COL_H
	var steps := maxi(2, int(road_len / 11.0))
	for s in steps:
		var f: float = f0 + span * (float(s) + 0.5) / float(steps)
		var d: Dictionary = at.call(f)
		var c: Vector3 = d["c"]
		var side: Vector3 = d["side"]
		var hw: float = d["hw"]
		for sgn: float in [-1.0, 1.0]:
			emit.call(group, "coloana%s" % tag, "hall_column",
				c + side * (hw + COL_OUT) * sgn, d["yaw"] as float,
				"hull", col_scale)
		# Alcova pe peretele din stanga, intre coloane.
		if s % 2 == 1:
			var fa2: float = f0 + span * (float(s) + 0.05) / float(steps)
			var da: Dictionary = at.call(fa2)
			emit.call(group, "alcova%s" % tag, "hall_alcove",
				(da["c"] as Vector3)
					- (da["side"] as Vector3) * ((da["hw"] as float) + 1.2),
				(da["yaw"] as float) + PI * 0.5, "hull", 1.0)
		# Torta pe peretele din dreapta: lumina care face modelarea sub pamant.
		if s % 2 == 0:
			emit.call(group, "torta%s" % tag, "torch",
				c + side * (hw + 0.6), d["yaw"] as float - PI * 0.5,
				"none", 1.0, 0.0, TORCH_GLOW)

	# --- PERETII. Fara ei sala e o pergola: prima captura la frac 0.68 a iesit
	# cu cer si dune pe amandoua partile, adica exact "desert cu stalpi".
	# Referinta (v3_crops/F_underground.png) e un spatiu INCHIS in care singura
	# lumina vine din torte — inchiderea e ce face subteranul, nu culoarea.
	#
	# Piesa e `hall_alcove` in sir: singura din kit care CHIAR e perete de sala.
	#
	# Doua incercari inainte, amandoua respinse pe captura:
	#   1. `hall_ceiling_module` pus pe muchie — build-ul ii retagheaza fata de
	#      SUS pe `CAVE_LIT` (`where="up"`) si lasa nervurile pe cea de jos, deci
	#      intr-un sens iese o dunga palida la piciorul peretelui, in celalalt un
	#      panou portocaliu cu desen de scandura. O piesa gandita ca tavan n-are
	#      o fata buna de perete; nu era o problema de semn.
	#   2. `cliff_band_module` — e un perete adevarat (20.3 x 12.4 x 6.0 m), dar
	#      poarta clasa de TUF a temei, adica cremul insorit de la suprafata. In
	#      sala, cu ambientul la 0.30, iesea alb: peretii inghiteau cadrul si
	#      drumul ramanea o crapatura intre doua faleze luminoase. Piatra de
	#      afara nu se poate muta inauntru doar fiindca are forma buna.
	#
	# `hall_alcove` e din chiar kitul subteranului (`CAVE`/`CAVE_LIT`, AO adanc),
	# are 3.2 m latime si 3.0 inaltime, si e MODELATA ca bucata de perete cu nisa.
	# Pusa in sir si stivuita pe inaltime, da un perete sapat, in aceleasi sloturi
	# intunecate ca restul salii — deci se stinge odata cu ele cand zona stinge
	# lumina.
	# SCALATA x2.6: la scara ei (3.2 x 3.0 m) ar fi trebuit ~650 de piese pentru
	# cele doua sali, adica sute de draw call-uri pentru un perete. La 8.3 x 7.8 m
	# ies sub 90, si nisa devine o firidă de om, nu una de pahar — la scara de
	# jucarie citeste mai bine asa.
	var wall_scale := 2.6
	var wall_w := 3.2 * wall_scale
	var wall_h := 3.0 * wall_scale
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
				# Nisa se uita spre banda: piesa e modelata cu fata pe +Z, deci
				# partea din stanga se intoarce cu 180 grade.
				# DINCOLO de coloane, si asta e ce face SALA in loc de tunel.
				# Lipit de carosabil (incercat: `hw + 0.7`) peretele inchidea
				# ordonat acostamentul, dar ascundea si coloanele — iar o galerie
				# fara coloane nu mai e "orasul subteran", e un tunel. Coloanele
				# stau la `hw + COL_OUT`; peretele trece cu inca 3.4 m in spatele
				# lor, deci raman intre banda si piatra, vizibile pe toata
				# inaltimea. Acostamentul il inchide poala peretelui de jos.
				emit.call(group, "perete%s" % tag, "hall_alcove",
					c + side * (hw + COL_OUT + 3.4) * sgn
						+ Vector3.UP * (wall_h * float(lvl)),
					yaw + (PI * 0.5 if sgn > 0.0 else -PI * 0.5), "hull",
					wall_scale)

	# --- POALA de la marginea benzii. Peretele inalt sta in spatele coloanelor
	# (ca sala sa aiba latime), si intre el si asfalt ramanea o fasie de
	# acostament PALID — pe captura, doua dungi albe de-a lungul drumului, adica
	# lumina de afara pe podeaua unei caverne. Poala e acelasi perete, la un
	# singur etaj si lipit de carosabil: inchide fasia fara sa acopere coloanele.
	for col in wall_cols:
		var f: float = f0 + span * (float(col) + 0.5) / float(wall_cols)
		var d: Dictionary = at.call(f)
		var c: Vector3 = d["c"]
		var side: Vector3 = d["side"]
		var hw: float = d["hw"]
		var yaw: float = d["yaw"]
		for sgn: float in [-1.0, 1.0]:
			emit.call(group, "poala%s" % tag, "hall_alcove",
				c + side * (hw + 0.55) * sgn,
				yaw + (PI * 0.5 if sgn > 0.0 else -PI * 0.5), "hull", wall_scale)

	# --- ARCADELE transversale: doua pe sala, la treimi. Ele dau scara verticala
	# din mers — se vad venind, iar bolta lor citeste cota tavanului.
	for t: float in [0.28, 0.72]:
		var f: float = f0 + span * t
		var d: Dictionary = at.call(f)
		var hw: float = d["hw"]
		# Masurat: hall_arch 11.36 m latime / 8.19 inalt; church_arch 9.4 / 8.04.
		var need := (hw + COL_OUT) * 2.0
		var have := 9.4 if church else 11.36
		var sc := maxf(1.0, need / have)
		emit.call(group, "arcada%s" % tag,
			"church_arch" if church else "hall_arch",
			d["c"] as Vector3, d["yaw"] as float, "mesh", sc)
