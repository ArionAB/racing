extends Node
## REPARATIA DE VIZIBILITATE, runda 1 (Chongqing / Track12).
##
## Nu genereaza decor nou: RECALCULEAZA transformarile pieselor care exista
## deja in `Track12.tscn` si care au picat verdictul de la volan. Tipareste
## liniile `transform = ...` per nod, ca sa se lipeasca peste cele vechi.
##
## Rulare (ca SCENA):
##   godot --headless --fixed-fps 60 --path . res://tools/FixCqVizibil.tscn
##
## REGULA CARE DECIDE TOT (brief 2.0): la distanta orizontala `d` camera vede
## in sus cel mult `10 + 0.093*d` metri peste cota drumului, si vede mult in
## jos (63 grade). Consecinta pe care runda trecuta a ratat-o: o piesa asezata
## corect GEOMETRIC (talpa pe teren, langa drum) poate sa nu apara in cadru
## deloc. De-aia fiecare grup de aici isi verifica singur INALTIMEA APARENTA
## si tipareste cifra: cat urca piesa peste drum, la ce distanta, si daca
## fereastra frustumului o cuprinde.
const TRACK := "res://scenes/tracks/Track12.tscn"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _ex: Array[RID] = []
var _sampler: TrackSideSampler
var _path
var _out: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	for i in 6:
		await get_tree().physics_frame
	_sampler = _track._sampler
	_path = TrackScenography._Path.new(_sampler)
	_space = _track.get_world_3d().direct_space_state
	_collect_excluded()
	_fix_piata()
	_fix_hongya()
	_fix_alee()
	_fix_pasarela()
	_fix_shibati()
	print("")
	print("===== LINII PENTRU .tscn =====")
	for l in _out:
		print(l)
	get_tree().quit(0)


func _collect_excluded() -> void:
	for root_name in ["DecorManual", "Decor"]:
		var r := _track.get_node_or_null(NodePath(root_name))
		if r == null:
			continue
		var st: Array = [r]
		while not st.is_empty():
			var x = st.pop_back()
			for c in x.get_children():
				st.append(c)
			var b := x as CollisionObject3D
			if b != null:
				_ex.append(b.get_rid())


# --------------------------------------------------------------- 1) PIATA
## PROBLEMA 1: cele trei blocuri de sub piata nu se vad de la volan.
##
## Masurat: varful lor e la y=65.0 si soseaua tot la 65.0, la 14 m lateral.
## Adica acoperisul e EXACT in planul platoului. Runda trecuta a facut asta
## intentionat (acoperisul la cota drumului taie linia terenului), dar un
## acoperis coplanar cu pamantul nu e o margine, e pamant: nu iese niciun
## pixel peste orizontul local, deci nu exista pe ecran.
##
## Platoul e plat la 65 m pe 46 m in TOATE directiile (masurat cu raze,
## probe_fx9), deci nu exista rapa in care sa cobori ceva. Prin urmare masa
## trebuie sa URCE: blocurile se ridica pana cand ultimele lor etaje stau
## PESTE cota drumului, in fereastra pe care camera chiar o vede.
##
## Cat de sus au voie: la distanta laterala `d` fereastra e `10 + 0.093*d`.
## La 13 m sunt 11.2 m — dar nu se umple toata, fiindca 2.0 interzice
## "orasul in sus" langa carosabil (fatadele de langa drum raman pereti de
## coridor). Se lasa deci 7-10 m peste drum: doua-trei randuri de ferestre
## aprinse care se ridica dincolo de parapet, si sub ele restul blocului care
## coboara in gol. Asta e chiar citirea POI-ului ("parterul e etajul 22"):
## vezi varful unui bloc care creste de sub tine.
func _fix_piata() -> void:
	print("=== 1) PIATA KUIXINGLOU ===")
	# frac, lateral, cat urca varful peste sosea
	#
	# CIFRELE VIN DINTR-O CAPTURA, nu din fereastra frustumului. Prima
	# incercare a folosit fereastra intreaga (varf +8.5 m la 13 m lateral) si
	# a iesit invers decat problema 1: blocul umple jumatate de ecran ca o
	# placa palida si ascunde chiar golul pe care trebuia sa-l arate
	# (captura v1_0.01). Un bloc de 40 m latime la 13 m distanta e un zid, nu
	# o margine.
	#
	# Deci: mai DEPARTE (20-34 m, unde 40 m de latime se citesc ca o cladire
	# intreaga, nu ca un perete).
	#
	# CAT DE SUS se decide din FERESTRE, nu din silueta. Masurat pe model
	# (probe_fx10): `liziba_block` are ferestrele intre y=1.0 si y=21.0, si
	# doar pe fetele de Z (214 m2 pe -Z, 176 pe +Z, sub 13 pe X). Acoperisul
	# e o placa fara nimic pe ea.
	#
	# A doua incercare (varf +3.5..5.5 m) a picat exact aici: de la inaltimea
	# camerei se vedea PLACA, o terasa palida la nivelul ochiului, fiindca
	# banda de ferestre ramasese toata sub cota drumului (captura v2_0.01).
	# Un bloc recunoscut ca bloc cere ferestre in cadru.
	#
	# Cu talpa la `drum + h - 24.9`, banda de ferestre (1..21) ajunge peste
	# drum pe portiunea `h - 3.9` de sus. La h = 11 m raman ~7 m de ferestre
	# aprinse deasupra parapetului si 14 m sub el: se citeste si masa care
	# urca, si golul in care coboara. Peste 12 m redevine zidul din prima
	# incercare, sub 8 se vede iar doar placa.
	#
	# LATERALUL, a treia oara: 21 m inca umple o treime din cadru cu perete
	# (captura v3_0.01 — se vad etajele, dar blocul e un zid la marginea
	# drumului, nu o cladire de sub piata). Blocul are 40.6 m latime; ca sa
	# incapa in cadru ca OBIECT, centrul lui trebuie sa stea la o distanta
	# comparabila cu latimea lui, nu la jumatate din ea. De la 32 m in sus se
	# vede intreg, cu cer deasupra si cu parapetul pietei in fata lui.
	var specs := [
		Vector3(0.010, 34.0, 10.0),
		Vector3(0.026, 38.0, 8.5),
		Vector3(0.019, 52.0, 12.0),
	]
	var i := 1
	for sp: Vector3 in specs:
		var st := _at(sp.x)
		var road: float = (st["pos"] as Vector3).y
		var p := _off(st, 1.0, sp.y)
		# liziba_block: 40.6 x 24.9 x 27.2, originea pe talpa.
		p.y = road + sp.z - 24.9
		var top := p.y + 24.9
		var window: float = 10.0 + 0.093 * sp.y
		var verdict := "NU"
		if top - road > 1.0 and top - road < window:
			verdict = "VIZIBIL"
		print("bloc_sub_piata%d: lat=%.0f varf=%+.1f peste sosea (fereastra %.1f m) -> %s"
			% [i, sp.y, top - road, window, verdict])
		# ROTIT CU ~35 GRADE fata de „cu fata la drum", si asta nu e estetica.
		# Ferestrele stau NUMAI pe fetele de Z (214 + 176 m2), pe X sunt 12.
		# `_yaw_to_road` pune -Z spre drum, deci frontal ar fi corect — dar
		# blocurile stau in SIRUL de pe dreapta si soferul le vede din mers,
		# aproape pe muchie: la 0 grade ce ajunge in cadru e capatul de 27 m
		# fara ferestre (captura v4_0.01, blocul citit ca placa intunecata).
		# Din trei sferturi intra in cadru si fata lunga aprinsa, si adancimea.
		_emit("bloc_sub_piata%d" % i, p,
			_yaw_to_road(st, 1.0) + deg_to_rad(38.0), 1.0)
		i += 1


# ------------------------------------------------------------- 4) HONGYA
## PROBLEMA 4: hero-ul pluteste.
##
## Masurat: varful lui e la y=21.0 cu soseaua la 26.0 — adica INTREG hero-ul
## sta sub cota drumului — si la 22 m lateral. La distanta aia, ce se vede din
## el e o silueta aurie in golul de deasupra apei, fara nimic in jur: nu
## atinge faleza, nu atinge terasa, nu se sprijina pe nimic. De-aia pluteste
## — literal, obiectul nu are contact vizibil cu lumea.
##
## Brief 8 cere explicit "incepe la 5 m sub buza cornisei, nu la 50". Deci:
##  * coama la 5 m SUB cota soselei,
##  * lateral MULT mai aproape — 13 m, nu 22: la 13 m camera vede in jos pana
##    la `ochi - 1.96*13` sub ea, adica tot corpul, iar peretele de stanca de
##    sub buza intra in acelasi cadru cu el. Contactul cu faleza e ce
##    transforma "silueta in gol" in "casa agatata de stanca".
##  * talpa ingropata sub terenul de acolo, ca piesa sa iasa din faleza, nu sa
##    stea pe o masa.
func _fix_hongya() -> void:
	print("")
	print("=== 4) CORNISA HONGYA DONG ===")
	var st := _at(0.345)
	var road: float = (st["pos"] as Vector3).y
	var top := road - 5.0
	# Profilul falezei, ca sa alegem lateralul cu date, nu din ochi.
	for d: float in [8.0, 11.0, 14.0, 18.0, 22.0, 28.0, 34.0, 42.0]:
		var pp := _off(st, 1.0, d)
		print("  lat %.0f m -> teren y=%.1f (%.1f sub sosea)" % [d, _ground(pp.x, pp.z, road), road - _ground(pp.x, pp.z, road)])
	# LATERALUL se alege din profilul de mai sus, nu din ochi. Masurat la
	# frac 0.345: buza tine cota pana la 8 m (-1.9), cade abrupt intre 11 si
	# 18 m (-8.1 -> -19.8) si de la 18 m incolo e TERASA PLATA la 5.7 m
	# (-20.3, neschimbat pana la 42 m).
	#
	# 16 m e ultimul punct DE PE PANTA: acolo faleza inca coboara, deci piesa
	# lipita de el are perete de stanca in spate pe toata inaltimea ei — exact
	# contactul care lipsea. La 22 m (unde statea) terenul e deja terasa plata
	# si piesa nu mai atinge nimic pe verticala: de-aia plutea.
	const HERO_LAT := 16.0
	var probe := _off(st, 1.0, HERO_LAT)
	var terrain := _ground(probe.x, probe.z, road)
	print("sosea y=%.1f, teren la %.0f m lateral y=%.1f (cadere %.1f m)"
		% [road, HERO_LAT, terrain, road - terrain])
	# Talpa sub terasa (5.7): partea aia nu se vede si nu trebuie sa se vada,
	# e ce face piesa sa para ca iese din faleza, nu ca sta pe o masa.
	var base := 1.5
	var scale := (top - base) / 47.74
	var p := _off(st, 1.0, HERO_LAT)
	p.y = base
	print("hongya_hero227: lat=%.0f coama=%+.1f fata de sosea, talpa y=%.1f, scara=%.2f (inaltime %.1f m)"
		% [HERO_LAT, top - road, base, scale, top - base])
	_emit("hongya_hero227", p, _yaw_to_road(st, 1.0) + deg_to_rad(35.0), scale)

	# Registrul 2: mai jos si mai in afara, dar tot in contact — coama lui sub
	# talpa vizibila a hero-ului, ca masa sa continue in jos fara gol intre ele.
	var st2 := _at(0.332)
	var road2: float = (st2["pos"] as Vector3).y
	var p2 := _off(st2, 1.0, 26.0)
	var terr2 := _ground(p2.x, p2.z, road2)
	var top2 := road2 - 16.0
	var base2 := terr2 - 4.0
	var scale2: float = (top2 - base2) / 47.74
	p2.y = base2
	print("hongya_registru2228: lat=26 coama=%+.1f fata de sosea, talpa y=%.1f, scara=%.2f"
		% [top2 - road2, p2.y, scale2])
	_emit("hongya_registru2228", p2, _yaw_to_road(st2, 1.0) + deg_to_rad(-22.0),
		scale2)


# --------------------------------------------------------------- 3) ALEEA
## PROBLEMA 3: fatadele aleii sunt intoarse spre exterior si coridorul e larg.
##
## Masurat pe scena construita: pravaliile aleii au `-Z.dot(spre_sosea)` intre
## -0.58 si -0.85 (adica spatele spre drum), in timp ce ACELEASI mesh-uri de pe
## cornisa au +0.93 (fatada spre drum, si se vede in captura f0.30: vitrine
## aprinse). Deci nu modelul e problema — kitul are ferestre pe amandoua fetele
## de Z, masurat: shophouse_a are 11.8 m2 slot 30 si pe +Z si pe -Z — ci yaw-ul
## cu care au fost scrise in .tscn.
##
## Si latimea: `_clear(st, 3.6)` da 11.6-12.5 m in alee, unde brief 2 C cere
## coridor STRANS de 6 m. Un coridor de 12 m intre fatade nu e coridor.
##
## Aici se rescriu amandoua: fatada verificata cu `dot` la emitere (nu dedusa),
## si lateral tras la marginea benzii + gabarit, ca peretii sa fie chiar
## pereti.
func _fix_alee() -> void:
	print("")
	print("=== 3) ALEEA HOT-POT ===")
	var root := _track.get_node("DecorManual/3) Aleea hot-pot")
	var names: Array[String] = []
	for ch in root.get_children():
		if (ch as Node3D) != null and String(ch.name).begins_with("pravalie"):
			names.append(String(ch.name))
	print("pravalii de rearanjat: %d" % names.size())
	var f := 0.168
	var placed := 0
	var bad := 0
	while f < 0.240 and placed < names.size():
		var st := _at(f)
		for sd: float in [-1.0, 1.0]:
			if placed >= names.size():
				break
			# LATERAL: marginea benzii plus jumatatea piesei plus trotuar.
			# Piesa e ~7 m latime, deci centrul la `half + 0.6 + 3.5`. In aleea
			# de 6 m latime utila (half_width 3.0) asta da ~7.1 m, adica exact
			# coridorul strans din brief, si nu intra in carosabil.
			var lat := _half(st) + 0.6 + 3.5
			var p := _off_ground(st, sd, lat)
			var yaw := _yaw_to_road(st, sd)
			# VERIFICAREA, nu deducerea: -Z al bazei scrise trebuie sa arate
			# spre sosea. Daca nu arata, se corecteaza cu PI si se numara.
			var b := Basis(Vector3.UP, yaw)
			var mz := -b.z
			mz.y = 0.0
			var rp: Vector3 = st["pos"]
			var to_road := Vector3(rp.x - p.x, 0.0, rp.z - p.z).normalized()
			if mz.normalized().dot(to_road) < 0.0:
				yaw += PI
				bad += 1
			_emit(names[placed], p, yaw, 1.0)
			placed += 1
		f += 6.4 / _path.total
	print("asezate %d, dintre care %d au cerut intoarcere de 180" % [placed, bad])
	# Ce a ramas se duce in randul al doilea, in spatele primului: adancime,
	# nu piese aruncate pe mijlocul aleii.
	var f2 := 0.170
	while placed < names.size():
		var stx := _at(f2)
		var sdx := -1.0
		if placed % 2 == 0:
			sdx = 1.0
		var px := _off_ground(stx, sdx, _half(stx) + 11.5)
		_emit(names[placed], px, _yaw_to_road(stx, sdx) + deg_to_rad(18.0), 1.0)
		placed += 1
		f2 += 7.6 / _path.total
		if f2 > 0.238:
			f2 = 0.170


# ------------------------------------------------------------------ unelte

func _at(frac: float) -> Dictionary:
	return _path.at(_path.total * frac)


func _half(st: Dictionary) -> float:
	var n := _track.baked.size()
	var idx := int(float(st["frac"]) * float(n)) % n
	return _sampler.half_width_at(idx)


func _off(st: Dictionary, side: float, dist: float) -> Vector3:
	var road: Vector3 = st["pos"]
	var r: Vector3 = st["right"] * side
	return Vector3(road.x + r.x * dist, road.y, road.z + r.z * dist)


func _off_ground(st: Dictionary, side: float, dist: float) -> Vector3:
	var p := _off(st, side, dist)
	p.y = _ground(p.x, p.z, p.y)
	return p


func _ground(wx: float, wz: float, hint: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(wx, hint + 90.0, wz), Vector3(wx, hint - 400.0, wz))
	q.exclude = _ex
	var hit := _space.intersect_ray(q)
	if hit.is_empty():
		return _sampler.ground_y(wx, wz)
	return (hit["position"] as Vector3).y


func _yaw_to_road(st: Dictionary, side: float) -> float:
	var r: Vector3 = st["right"] * side
	return atan2(-r.x, -r.z)


func _emit(node_name: String, pos: Vector3, yaw: float, scl: float) -> void:
	_emit_basis(node_name, pos, Basis(Vector3.UP, yaw), scl)


# --------------------------------------------------------------- 8) PASARELA
## PROBLEMA 8, partea a doua: "pasarela verde sta acolo fara niciun sens".
##
## Avea dreptate: statea PARALEL cu drumul, la 19 m lateral, la 0.9075 — adica
## dupa iesirea din hol, langa el, fara sa lege nimic de nimic. Brief 2 G cere
## "iesirea pe o pasarela spre piata": o pasarela care nu traverseaza nimic nu
## e o iesire, e un obiect.
##
## De ce statea asa: prima versiune o pusese perpendicular si `probe_cq_hall`
## a masurat 56 de atingeri — picioarele ei (cadre in V la +/-6.7 m) cadeau fix
## pe benzile extreme ale unei sosele de 14 m. Concluzia de atunci a fost
## "deci nu traverseaza"; concluzia corecta e "deci trebuie RIDICATA".
##
## Acum traverseaza pe deasupra: tablierul la 9 m peste carosabil, adica peste
## gabaritul oricarei masini si peste orice saritura de pe rampa dinainte, iar
## picioarele cad la +/-6.7 * scara. Cu scara 1.45 ajung la +/-9.7 m, in afara
## semicarosabilului de 7 m plus acostament. Se citeste ca tavan scurt de doua
## secunde la iesirea din bloc — exact limbajul din brief 2.0 ("burta pasajului
## cand treci pe sub el").
func _fix_pasarela() -> void:
	print("")
	print("=== 8) PASARELA LIZIBA ===")
	const FRAC := 0.897
	const SCALE := 1.30
	const CLEAR := 8.0
	var st := _at(FRAC)
	var road: Vector3 = st["pos"]
	var half := _half(st)
	var legs: float = 6.7 * SCALE
	print("frac %.3f: sosea y=%.1f, semicarosabil %.1f m" % [FRAC, road.y, half])
	print("picioarele la +/-%.1f m (semicarosabil %.1f) -> %s"
		% [legs, half, "IN AFARA" if legs > half + 1.5 else "PE DRUM"])
	print("tablier la %.1f m peste carosabil" % CLEAR)
	var p := Vector3(road.x, road.y + CLEAR, road.z)
	# `_yaw_across` pune Z-ul local pe `right`, adica lungimea de 24.3 m
	# DE-A CURMEZISUL drumului: asta e chiar traversarea.
	var r: Vector3 = st["right"]
	_emit("pasarela224", p, atan2(r.x, r.z), SCALE)


# -------------------------------------------------------------- 2) SHIBATI
## PROBLEMA 2: "casele sunt orientate cu spatele la pista, si scarile sunt sub
## pamant". Amandoua confirmate cu masuratori, si amandoua au cauze diferite.
##
## SCARILE. Masurat pe scena: cele 19 bucati au talpa cu 10.2 m SUB terenul de
## sub ele, iar 13 din 19 stau la peste 8 m sub cota soselei. Nu erau
## "asezate gresit", erau ingropate.
##
## Cauza e in reteta veche: piesele se INLANTUIAU in jos (7 m mai jos si 7.5 m
## mai in afara la fiecare pas) pe presupunerea ca terenul coboara lateral.
## Nu coboara: masurat cu raze pe toata coborarea (frac 0.048-0.108), terenul
## de pe latura -1 e PLAT — intre -0.2 si -1.4 m fata de cota soselei, pana la
## 44 m lateral. Ce coboara aici e DRUMUL (64.4 -> 56.9 m), si terenul coboara
## odata cu el. Deci un lant care coboara 7 m pe bucata intra direct in pamant.
##
## Reparatia: fiecare bucata sta pe TERENUL EI (raycast), si coborarea o face
## panta drumului, nu lantul. Piesa coboara deja singura 7.69 m pe 12.61 m de
## adancime — atat trebuie, si nimic in plus.
##
## ORIENTAREA. 13 din 15 pravalii, 6 din 8 pravalii_jos, 8 din 9 rufe si 10
## din 11 felinare aveau `-Z.dot(spre_sosea)` negativ: exact aceeasi eroare de
## 180 grade ca in alee. Se verifica acum cu dot la emitere.
##
## LATERALA. Erau la 21-33 m, unde o pravalie de 7.6 m e un punct pe camp.
## Brief 2 B cere ca treptele sa fie "primul lucru sub tine cand te uiti in
## stanga": scara vine la 12-16 m, pravaliile in spatele ei la 22-26.
func _fix_shibati() -> void:
	print("")
	print("=== 2) COBORAREA SHIBATI ===")
	var root := _track.get_node("DecorManual/2) Coborarea Shibati")
	var by_base := {}
	for ch in root.get_children():
		var n3 := ch as Node3D
		if n3 == null:
			continue
		var nm := String(n3.name)
		if nm.ends_with("_col"):
			continue
		var base := nm.rstrip("0123456789")
		if not by_base.has(base):
			by_base[base] = []
		(by_base[base] as Array).append(nm)
	for k in by_base:
		print("  %s: %d" % [k, (by_base[k] as Array).size()])

	# SCARA: pe terenul ei, la 13 m, cu -Z spre drum (piesa coboara spre -Z,
	# deci asa coboara DINSPRE drum in jos si o vezi din profil, nu din spate).
	var stairs: Array = by_base.get("scara", [])
	var f := 0.048
	var i := 0
	while i < stairs.size():
		var st := _at(f)
		# Alterneaza doua benzi laterale, ca scara sa aiba latime de scara
		# uriasa (brief: "trepte late"), nu un sir subtire.
		var lat := 13.0 + float(i % 2) * 10.5
		var p := _off_ground(st, -1.0, lat)
		# ORIENTAREA SE MASOARA, NU SE DEDUCE (probe_fx17, sectiune prin
		# suprafata calcabila): treptele COBOARA SPRE +Z — y mediu 3.50 la z
		# mic, 1.42 la z mare — si piesa e lata pe X (10.36 m).
		#
		# `_yaw_to_road(-1)` pune -Z spre drum, deci +Z (coborarea) pleaca DE
		# LA drum in jos: exact ce trebuie. Fara `+PI` si fara tangaj.
		# Prima incercare le avea pe amandoua si a iesit un gard de panouri de
		# lemn in picioare pe marginea drumului: `+PI` intorcea coborarea spre
		# sosea, iar tangajul de -8 grade ridica fata lata pe verticala.
		var b := Basis(Vector3.UP, _yaw_to_road(st, -1.0))
		_emit_basis(stairs[i], p, b, 1.0)
		i += 1
		f += 6.6 / _path.total
		if f > 0.112:
			f = 0.048

	# PRAVALIILE: in spatele scarii, cu fatada VERIFICATA spre drum.
	_row(by_base.get("pravalie", []), 0.050, 0.110, 22.0, -1.0, 0.0)
	_row(by_base.get("pravalie_jos", []), 0.054, 0.108, 30.0, -1.0, 0.22)
	# Rufele intre case, la inaltime de etaj (stau intinse, deci peste teren).
	_row(by_base.get("rufe", []), 0.056, 0.106, 25.0, -1.0, 0.0, 3.2)
	# Hamalii pe scara, sub linia camerei.
	_row(by_base.get("hamal", []), 0.058, 0.100, 15.0, -1.0, 0.7)
	# Felinarele langa drum, ca sirul de lumini sa insoteasca coborarea.
	_row(by_base.get("felinar_scara", []), 0.050, 0.110, 9.5, -1.0, 0.0)


## Un sir de piese de-a lungul unei fractii, pe teren, cu fatada verificata.
func _row(names: Array, f0: float, f1: float, lat: float, side: float,
		yaw_extra: float, lift: float = 0.0) -> void:
	if names.is_empty():
		return
	var n := names.size()
	var bad := 0
	for i in n:
		var f: float = f0 + (f1 - f0) * float(i) / maxf(1.0, float(n - 1))
		var st := _at(f)
		var d: float = lat + float(i % 3) * 2.0
		var p := _off_ground(st, side, d)
		p.y += lift
		var yaw := _yaw_to_road(st, side)
		var b := Basis(Vector3.UP, yaw)
		var mz := -b.z
		mz.y = 0.0
		var rp: Vector3 = st["pos"]
		var to_road := Vector3(rp.x - p.x, 0.0, rp.z - p.z).normalized()
		if mz.normalized().dot(to_road) < 0.0:
			yaw += PI
			bad += 1
		_emit(names[i], p, yaw + yaw_extra, 1.0)
	print("  %s: %d piese, %d intoarse 180" % [String(names[0]).rstrip("0123456789"), n, bad])


func _emit_basis(node_name: String, pos: Vector3, basis: Basis,
		scl: float) -> void:
	var b := basis.scaled(Vector3(scl, scl, scl))
	_out.append("# %s" % node_name)
	# ORDINEA E PE LINII, nu pe coloane. Prima versiune scria `b.x, b.y, b.z`
	# una dupa alta, adica TRANSPUSA — iar pentru rotatii in jurul lui Y
	# transpusa e rotatia inversa, deci fiecare piesa "reparata" iesea intoarsa
	# in partea cealalta. Vezi `tools/fix_cq_fatade.gd`.
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x,
			b.x.y, b.y.y, b.z.y,
			b.x.z, b.y.z, b.z.z, pos.x, pos.y, pos.z])
