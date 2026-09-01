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

	# Cat de sus e liber deasupra unui punct din lume, pana la ORICE carosabil
	# care trece pe deasupra. Exista fiindca traseul se suprapune cu el insusi:
	# spirala stancii goale (POI G) se intoarce peste sala 2 la ~15 m
	# (`ProbeLayout`: separare minima 15.1 m la frac 0.75). O lespede de tavan
	# pusa orbeste la 18 m ajunge deci PESTE drumul de sus, si masurat lasa 4.41 m
	# degajare la frac 0.845 — sub minimul de 4.5 m, adica un zid pe carosabil.
	# Defectul era si inainte de runda asta; se repara aici fiindca aici se pun
	# lespezile.
	var headroom := func(pos: Vector3) -> float:
		var best := 1e9
		for j in range(n):
			var q: Vector3 = r.baked[j]
			if Vector2(q.x - pos.x, q.z - pos.z).length() > 8.5:
				continue
			# Se masoara in AMANDOUA sensurile, si asta a fost greseala primei
			# variante: ea cerea `q.y > pos.y`, adica se uita doar la drumul de
			# DEASUPRA lespezii. Dar lespedea vinovata statea la y=30.1 peste un
			# carosabil la y=26.6 — drumul trecea pe DEDESUBT, iar lespedea
			# atarna in el de sus. Testul corect e distanta pe verticala, fara
			# semn: orice carosabil mai apropiat de 4.5 m e o problema, fie ca e
			# peste sau sub piesa.
			best = minf(best, absf(q.y - pos.y))
		return best

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

	# O TORTA CARE CHIAR LUMINEAZA: prop-ul plus un OmniLight in flacara.
	#
	# [b]De ce, si de ce abia acum.[/b] Pana aici tortele erau DOAR emisive
	# (`metadata/lumina`): ardeau, dar nu iluminau nimic — masurat, in toata
	# Track13 erau ZERO noduri de lumina. De aceea criticul rundei 2 a scris ca
	# „16 torte se citesc ca un singur jar", si tot de aceea peretii ies plati:
	# singura lumina din sala era ambientul, care e uniform prin definitie, deci
	# nicio suprafata nu putea avea o fata luminata diferit de alta. Asta e chiar
	# defectul comun #2 al rundei („suprafete fara fata de sus luminata"), doar ca
	# la noi cauza nu era geometria treptelor, ci lipsa unei surse cu DIRECTIE.
	#
	# Racirea pietrei (`metadata/racire`) rezolva croma, dar singura NU putea
	# rezolva modelarea: masurat pe captura, orice umplere aditiva plata scade
	# contrastul relativ al peretelui de la 0.31 la ~0.13, fiindca ridica la fel
	# si luminile si umbrele. Caldura si relieful trebuie sa vina din acelasi loc
	# — flacara.
	#
	# [b]Cost.[/b] Nu incalca „o singura lumina" din CLAUDE.md: acolo e vorba de
	# lumina DIRECTIONALA (cascada de umbre a soarelui), iar caverna e exact locul
	# in care soarele nu ajunge. Tiparul e cel deja livrat pe Chongqing, care are
	# 89 de OmniLight: `shadow_enabled = false` (umbrele dinamice sunt scumpe si
	# aici n-au ce arata — piatra e deja cu AO copt) si `distance_fade`, ca o sala
	# prin care nu treci sa nu coste nimic.
	var torch_light := func(group: String, pos: Vector3) -> void:
		lines.append('[node name="focTorta_%d" type="OmniLight3D" parent="DecorManual/%s"]'
			% [counter[0], group])
		# Flacara sta la ~2.1 m pe piesa; lumina se pune IN ea, nu la origine.
		lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.6f, %.6f, %.6f)'
			% [pos.x, pos.y + 2.1, pos.z])
		lines.append('light_color = Color(1, 0.706, 0.42, 1)')
		# Energie mare, raza mica: o torta lumineaza puternic UN petec de perete.
		# Raza mare ar fi facut exact mocirla uniforma pe care o inlocuim.
		lines.append('light_energy = 4.20')
		lines.append('omni_range = 13.0')
		lines.append('omni_attenuation = 1.6')
		lines.append('light_specular = 0.20')
		lines.append('shadow_enabled = false')
		lines.append('distance_fade_enabled = true')
		lines.append('distance_fade_begin = 70.0')
		lines.append('distance_fade_length = 25.0')
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
		torch_light.call("F1_Gura", p)

	# ------------------------------------------------------------- SALA 1
	_hall(at, emit, headroom, torch_light, 0.664, 0.698, CEIL_H1, "F2_Sala1", "s1", false)
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
		torch_light.call("F3_Gat", tp)

	# ------------------------------------------------------------- SALA 2
	# Biserica rupestra: acelasi schelet, dar cu arcade de biserica si fresce.
	#
	# CAPATUL RAMANE LA 0.753, si asta e o concluzie, nu inertie.
	#
	# Masurat, briefu NU INCAPE aici. El cere sala 2 pe 0.66-0.82, dar de la 0.76
	# drumul urca spre spirala stancii goale (11.9 m la 0.76 -> 27.5 la 0.85) SI
	# spirala se intoarce PE DEASUPRA salii (memoria `pista-peste-pista`): la
	# frac 0.750 drumul e in (-335, 12.2, -16.0), la 0.845 in (-319, 26.6, -16.0)
	# — acelasi z, 14.9 m mai sus. `_sep.gd` masoara degajarea pana la bucla, iar
	# `ProbeLayout` o confirma independent: "separare verticala minima 15.1 m la
	# frac 0.75 (prag 14)". Intr-un spatiu de 15 m nu incape o sala de 18 m plus
	# degajare — dus la 0.800, tavanul lasa 3.88 si 1.99 m peste carosabil, adica
	# ziduri, si `_ceil.gd` le-a prins.
	#
	# Incercarea de a TAIA sala mai devreme (0.745) ca sa scape de coliziune a
	# fost si mai rea, si captura a spus-o: la frac 0.74 cadrul se termina in cer
	# deschis si munte cenusiu, adica exact defectul de la 0.76 mutat cu 20 m mai
	# aproape. Am revenit. O sala mai scurta nu rezolva o sala care se termina
	# prea devreme.
	#
	# Concluzia onesta: intervalul 0.76-0.82 din brief nu poate fi caverna cu
	# geometria actuala a traseului. Ori se coboara tavanul salii 2 sub 14 m (si
	# atunci `CameraZone.ceiling` nu mai are ce arata), ori se muta bucla elicei —
	# amandoua sunt decizii de TRASEU, nu de decor, si nu se iau intr-o runda de
	# arta. Ce tine de runda asta e ca sala existenta sa arate ca o sala.
	_hall(at, emit, headroom, torch_light, 0.720, 0.753, CEIL_H2, "F4_Sala2", "s2", true)
	var v2: Dictionary = at.call(0.737)
	emit.call("F4_Sala2", "putSala2", "vent_shaft",
		(v2["c"] as Vector3) - (v2["side"] as Vector3) * 2.4
			+ Vector3.UP * CEIL_H2, v2["yaw"] as float, "none", 1.0)
	# Al doilea put, catre capatul salii: cu unul singur (la 0.737) toata a doua
	# jumatate ramanea fara nicio gura de lumina. La 0.748 — mai incolo ar intra
	# sub bucla de intoarcere a elicei si ar iesi prin carosabilul de deasupra.
	var v3: Dictionary = at.call(0.748)
	emit.call("F4_Sala2", "putSala3", "vent_shaft",
		(v3["c"] as Vector3) + (v3["side"] as Vector3) * 2.4
			+ Vector3.UP * CEIL_H2, v3["yaw"] as float, "none", 1.0)

	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(lines))
	fa.close()
	print("scrise %d noduri in %s" % [counter[0], OUT])
	get_tree().quit()


## O sala: tavan din lespezi, coloane si alcove pe pereti, arcade transversale,
## torte. `church` schimba arcada cu cea de biserica (fresce) — sala 2.
func _hall(at: Callable, emit: Callable, headroom: Callable, torch_light: Callable,
		f0: float, f1: float, ceil_h: float,
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
			var at_pos := c + side * (CEIL_TILE * float(k)) + Vector3.UP * ceil_h
			# Lespedea are 1.99 m si creste IN SUS de la origine, deci ocupa pana
			# la +2 m. Sub carosabilul de deasupra trebuie sa ramana degajarea de
			# 4.5 m ceruta de `ProbeBuried`: daca nu incape, lespedea se SARE.
			# Gaura ramasa da chiar in masivul de teren de deasupra, deci nu se
			# vede cer — s-a verificat pe captura, nu doar pe cifra.
			# Lespedea ocupa [y, y+2]. Sub ea trebuie sa ramana degajarea de 4.5 m
			# ceruta de `ProbeBuried`; deasupra ei, la fel — daca drumul de
			# intoarcere al elicei trece pe acolo, lespedea intra in el.
			if (headroom.call(at_pos) as float) < 6.5:
				continue
			emit.call(group, "tavan%s" % tag, "hall_ceiling_module",
				at_pos, d["yaw"] as float, "mesh", 1.0)

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
		# Torta: lumina care face modelarea sub pamant.
		#
		# UNA PE FIECARE PAS, alternand malul — inainte era `s % 2 == 0`, adica o
		# flacara la ~22 m, si captura arata de ce e prea putin: la 0.68 nu se
		# vedea NICIUNA, iar la 0.72 doua atat de departe incat citeau ca litere
		# "T", nu ca foc. Referinta (`v3_crops/F_underground.png`) e chiar pe dos:
		# vreo douasprezece flacari, si tot ce e cald in cadru vine din ele.
		# Cu ambientul la 0.30 tortele nu sunt accent, sunt SINGURA sursa; una la
		# 22 m lasa jumatate din sala fara nimic care s-o modeleze.
		# Alternarea malului da si ritm lateral: pe un sir de coloane simetrice,
		# lumina care sare stanga-dreapta e ce arata ca sala are LATIME.
		var torch_pos := c + side * (hw + 0.6) * (1.0 if s % 2 == 0 else -1.0)
		emit.call(group, "torta%s" % tag, "torch", torch_pos,
			(d["yaw"] as float) + (-PI * 0.5 if s % 2 == 0 else PI * 0.5),
			"none", 1.0, 0.0, TORCH_GLOW)
		torch_light.call(group, torch_pos)

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
				#
				# VARIATIA. Cu toate piesele la aceeasi scara si acelasi offset,
				# captura de la 0.68 iesea un sir de firide IDENTICE care marsaluia
				# spre punctul de fuga — cel mai artificial lucru din cadru, si
				# singurul pe care ochiul il prinde inaintea oricarui detaliu:
				# 268 de exemplare ale aceleiasi piese, aliniate la milimetru.
				# Peretele e SAPAT cu tarnacopul, deci nu are cum sa fie regulat.
				# Se clatina deci scara (±12%) si adancimea (±0.9 m) dupa un hash
				# al pozitiei — determinist (aceeasi pista la fiecare regenerare,
				# ca sonda sa poata compara A/B), dar necorelat intre vecini.
				# Nu costa niciun material si nicio piesa in plus: aceleasi
				# instante, doar ca nu mai sunt stantate.
				# Jitterul e DOAR SPRE INTERIOR, niciodata spre afara. Prima
				# varianta il facea simetric (±0.9) si captura de la 0.76 a
				# aratat de ce e gresit: panourile impinse in afara ies din
				# masivul de teren, iar prin rosturile ramase intra stanca
				# CENUSIE de exterior — pete palide de-a lungul intregului sir,
				# adica taman lumina de afara pe care peretii exista s-o
				# opreasca. Peretele sapat poate avansa in sala (mai multa
				# piatra), dar nu poate da inapoi in munte fara sa-l gaureasca.
				#
				# [b]CAT DE MULT, si de ce cifra veche nu se vedea.[/b] Runda
				# trecuta clatina scara cu ±12% si adancimea cu 0.9 m, si
				# criticul orb a raspuns ca sirul citeste „rafturi stantate" —
				# nu „prea subtil", ci INVIZIBIL. Are dreptate aritmetic: pe o
				# piesa de 8.3 m, 12% inseamna 1 m pe o suprafata privita din
				# capat, adica sub un pixel de deplasare la punctul de fuga.
				# Regula platita deja de proiect (10/255 luminanta, ±9% pe
				# lespezi paralele) spune ca variatia trebuie sa fie in METRI,
				# nu in procente.
				#
				# Deci: adancimea se clatina cu pana la 3.2 m (de la 0.9), pe
				# trei trepte discrete in loc de continuu — un perete sapat are
				# nise si pinteni, nu o unda lina. Treptele sunt ce da UMBRA
				# proprie: doi vecini la aceeasi adancime nu se ocultau niciodata.
				var h := float((col * 73 + lvl * 149 + int(sgn) * 37) % 100) / 100.0
				var h2 := float((col * 31 + lvl * 211 + int(sgn) * 17) % 100) / 100.0
				var h3 := float((col * 97 + lvl * 53 + int(sgn) * 61) % 100) / 100.0
				var ws := wall_scale * (0.94 + 0.18 * h)
				# Trei trepte de adancime: 0 / 1.6 / 3.2 m spre interior.
				var step := float(int(h2 * 3.0)) * 1.6
				var depth := (hw + COL_OUT + 3.4) - step
				# ROTATIE NE-PARALELA, cererea explicita a criticului. Fara ea,
				# oricat ai varia adancimea, toate fetele raman pe acelasi plan
				# si prind exact aceeasi lumina — de acolo venea „placa paralela".
				# ±0.20 rad (11.5°) e destul cat fata sa-si schimbe valoarea fata
				# de vecina, si prea putin cat sa deschida rosturi spre munte.
				var skew := (h3 - 0.5) * 0.40
				emit.call(group, "perete%s" % tag, "hall_alcove",
					c + side * depth * sgn
						+ Vector3.UP * (wall_h * float(lvl)),
					yaw + (PI * 0.5 if sgn > 0.0 else -PI * 0.5) + skew,
					"hull", ws)

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
