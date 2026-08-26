@tool
class_name FireballGeyser
extends Node3D
## GHEIZERELE DE FOC DIN CRATER (Stromboli, brief §3).
##
## Doua (sau mai multe) coloane de lava care tasnesc din cuva si recad, in
## OPOZITIE DE FAZA: cand una e sus, cealalta e jos. Nu e un obstacol de
## reflex, e unul de CITIT — te uiti in fata, vezi care gheizer e in cadere si
## te asezi pe culoarul lui inainte sa ajungi acolo.
##
## DE CE OPOZITIE DE FAZA, si nu fiecare cu ritmul lui:
##
## Cu ritmuri independente, craterul devine zgomot: la orice moment jumatate
## din culoare sunt blocate aleatoriu, iar jucatorul nu are ce sa invete —
## incetineste si asteapta, exact esecul masurat la carusel (vezi
## `CarouselHazard.STRADDLE_LANE_FRAC`). In opozitie, invariantul e simplu si
## se tine cu ochii: EXISTA MEREU un culoar liber, si se stie care. Pedeapsa
## nu mai e pentru ghinion, ci pentru pozitionare proasta — adica e skill.
##
## Din acelasi motiv `_slot_phase` imparte cercul de faza EGAL intre gheizere:
## cu 2, unul e sus cand celalalt e jos; cu 3, defazate la o treime. Numarul
## lor se alege din cate CULOARE are drumul acolo, nu din cat de plin arata
## craterul.
##
## CE PATESTI (decizia dezvoltatorului, aug 2026): NU moarte, si nici
## `Car.scorch()` — arderea de lava exista deja pe limba de lava, iar craterul
## n-are nevoie de a doua pedeapsa identica. Aici te ZVARLE (impuls radial, ca
## o forta care impinge in afara) si masina ARDE cateva secunde: flacari pe
## capota care mananca partea de sus a ecranului, plafon de viteza taiat, bara
## de turbo golita. Pedeapsa e INFORMATIONALA — nu esti atat de incetinit cat
## esti orbit, exact acolo unde vederea era ce conta. Si e recuperabila: daca
## stii pista, conduci prin fum.
##
## MATERIALE: coloana si bulgarele folosesc `Palette.finish_material("lava")` —
## ACELASI material ca limba de lava, gurile si bombele. Garda din
## `tools/probe_decor.gd` numara materialele per pista, deci gheizerele adauga
## ZERO la numaratoare.

## Cate secunde dureaza un ciclu complet al UNUI gheizer (tasnire + cadere +
## asteptare). Toate gheizerele impart aceeasi perioada — asta e ce face
## opozitia posibila.
@export var period: float = 4.6:
	set(value):
		period = maxf(value, 1.2)

## Decalajul intregului grup fata de ceasul lumii. Se pune cand vrei ca
## gheizerele sa nu bata odata cu alt hazard din apropiere.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

## Cat de sus ajunge varful coloanei peste gura ei.
##
## Trebuie sa treaca de plafonul masinii ca sa fie zid, nu prag: sub ~3 m ai
## trece pur si simplu peste el si gheizerul n-ar mai fi obstacol.
@export var height: float = 9.0:
	set(value):
		height = maxf(value, 3.0)

## Raza coloanei. Ea decide si cat de larg e culoarul blocat.
@export var radius: float = 1.6:
	set(value):
		radius = maxf(value, 0.4)

## Cat din ciclu sta coloana SUS la inaltime plina (fractie). Peste ea vin
## caderea si asteptarea jos.
##
## 0.30, si valoarea NU e la alegere libera: bila e periculoasa si cat urca, si
## cat cade, deci fereastra ei blocata e `up_fraction * (1 + FALL_FRAC)`, nu
## `up_fraction`. Ca sa nu fie doua coloane sus deodata, fereastra aia trebuie
## sa incapa in decalajul de faza dintre doua guri vecine (1/n).
##
## Prima incercare a fost 0.38 si a PICAT sonda invariantului: fereastra iesea
## 0.51 din ciclu la un decalaj de 0.5, deci ~0.3 secunde pe ciclu ambele
## culoare erau blocate — exact situatia pentru care hazardul n-are raspuns.
## `_max_up_fraction` taie acum valoarea la ce incape, oricat ai cere de aici.
@export_range(0.1, 0.8, 0.01) var up_fraction: float = 0.30

## Cat timp inainte de tasnire se vede avertismentul (discul incins la gura).
##
## Fara telegraph, un gheizer care tasneste in fata ta la 30 m/s e o taxa. Cu
## el, e o intrebare pusa la timp.
@export var telegraph: float = 0.8:
	set(value):
		telegraph = maxf(value, 0.0)

## Gurile: pozitii LOCALE, una pentru fiecare gheizer. Fazele se impart singure
## intre ele (vezi `_slot_phase`), deci ordinea din lista e ordinea in cerc.
@export var vents: Array[Vector3] = [
	Vector3(-3.2, 0.0, 0.0),
	Vector3(3.2, 0.0, 0.0),
]:
	set(value):
		vents = value
		if is_inside_tree():
			_rebuild.call_deferred()

## Cat de tare te zvarle coloana care te prinde, in m/s.
@export var throw_push: float = 11.0

## Cat de sus te arunca, in m/s.
@export var throw_lift: float = 7.5

## Cate secunde arde masina dupa lovitura.
@export var burn_seconds: float = 3.2

signal fireball_hit(car: Car)

## Cat de mult scade plafonul de viteza cat arzi. 0.78 = pierzi ~un sfert.
##
## Mai bland decat bolovanul (0.70) DELIBERAT: acolo pedeapsa e turtirea si
## atat, aici peste incetinire vine si ecranul plin de flacari. Doua pedepse
## deodata la aceeasi intensitate ar face craterul o taxa.
const BURN_SPEED_FACTOR: float = 0.78

## Cata viteza pastrezi in momentul impactului.
const BURN_KEEP_SPEED: float = 0.72

## Cat asteapta o masina pana poate fi lovita din nou de ACELASI gheizer.
## Fara el, coloana ridicata sub tine te loveste de 60 de ori pe secunda.
const HIT_COOLDOWN: float = 0.9

## Cat din fereastra de sus dureaza tasnirea, respectiv caderea (fractii din
## `up_fraction`). Caderea e mai lunga decat tasnirea: presiunea impinge
## brusc, gravitatia aduce inapoi mai lent.
##
## Sunt constante, nu numere puse in `_tick`, fiindca `_max_up_fraction`
## trebuie sa socoteasca CU ele — fereastra blocata le include pe amandoua.
const RISE_FRAC: float = 0.25
const FALL_FRAC: float = 0.35

## Marja de siguranta intre fereastra blocata a unei guri si urmatoarea, ca
## fractie din ciclu. Fara ea, „exact cat incape" inseamna ca la un cadru
## nefericit tot se ating.
const GAP_FRAC: float = 0.04

## Segmente pe primitivele coloanei. EXPLICIT, nu implicit: un CylinderMesh
## lasat la valorile din fabrica are 64 de segmente, adica mii de triunghiuri
## pentru un obiect de 1.6 m (CLAUDE.md §triunghiuri — regula sferei).
## Cati bulgari raman in urma bilei, si cat de mult (fractie din zbor).
##
## Coada exista ca sa se vada TRAIECTORIA, nu ca ornament: la o bila care urca
## si cade, ce trebuie sa citesti de departe e „de unde vine si incotro", si
## un singur bulgare in aer nu spune asta.
const TRAIL_COUNT: int = 3
const TRAIL_LAG: float = 0.055

const COLUMN_SEGMENTS: int = 10
const BLOB_RADIAL: int = 10
const BLOB_RINGS: int = 5

var _geysers: Array[Dictionary] = []
var _clock: float = 0.0


func _ready() -> void:
	_rebuild()
	add_to_group(AI_GROUP)
	if Engine.is_editor_hint():
		set_physics_process(false)


func _rebuild() -> void:
	for g in _geysers:
		var n := g.get("root") as Node
		if n != null and is_instance_valid(n):
			n.queue_free()
	_geysers.clear()
	for i in vents.size():
		_geysers.append(_build_geyser(i, vents[i]))


## Un gheizer: coloana (corp animat, deci te opreste onest), bulgarele din varf,
## avertismentul de la gura si zona de impact.
##
## Coloana e `AnimatableBody3D` din acelasi motiv ca vanele caruselului: un corp
## mutat din cod are viteza calculata corect de fizica, deci masina care se
## sprijina de el nu vibreaza si nu il traverseaza la viteza mare.
func _build_geyser(index: int, vent: Vector3) -> Dictionary:
	var root := Node3D.new()
	root.name = "Gheizer%d" % (index + 1)
	root.position = vent
	add_child(root)

	# Materialul de lava, DEFAZAT pe faza fizica a gheizerului asta.
	#
	# Nu `finish_material("lava")`, care era aici pana in august 2026 si scotea
	# COLOANE IN DUNGI DE ACADEA: finisajul pastreaza textura atlasului, iar
	# contractul atlasului cere UV-uri colapsate pe centrul slotului. Un
	# CylinderMesh/SphereMesh al lui Godot are insa UV-uri 0..1 si matura tot
	# atlasul — masurat, cilindrul atinge 21 de sloturi si sfera 13, amandoua
	# prin rezerva MAGENTA. Shaderul isi ia culoarea din pozitie, nu din UV,
	# deci pe primitive merge la fel de bine ca pe GLB-uri.
	#
	# Defazajul e ACELASI cu cel al miscarii (`_slot_phase`), inmultit cu TAU ca
	# sa fie unghi: cand un gheizer e sus si altul jos, se vede si in pulsatia
	# jarului, nu doar in pozitie. Curgerea e mai rapida decat pe limba de lava
	# (0.16) fiindca asta chiar tasneste — jetul urca, nu se scurge.
	var lava_mat := Palette.lava_material_phased(_slot_phase(index) * TAU, 0.55)

	# BILA DE FOC. Nu coloana care creste: pana in august 2026 gheizerul era un
	# cilindru scalat pe Y, si arata exact ca ce era — un cilindru care se
	# lungeste si se face mic. Decizia dezvoltatorului: bile de foc aruncate in
	# sus, care recad. Aceeasi mecanica de ritm, alta citire: ce te ameninta e
	# un OBIECT pe o traiectorie, nu un perete care apare.
	#
	# Bila are marime FIXA — se misca, nu se umfla. Un obiect care isi schimba
	# volumul in zbor nu citeste ca materie aruncata.
	var body := AnimatableBody3D.new()
	body.name = "Bila"
	# Contactul cu ea nu e perete de piatra — restul lumii vede foc, nu stanca
	# (aceeasi conventie ca meta `lava` de pe limba).
	body.set_meta(&"fireball", true)
	var ball := MeshInstance3D.new()
	ball.name = "Foc"
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = BLOB_RADIAL
	sph.rings = BLOB_RINGS
	ball.mesh = sph
	ball.material_override = lava_mat
	body.add_child(ball)
	var col_shape := CollisionShape3D.new()
	var col_sphere := SphereShape3D.new()
	col_sphere.radius = radius
	col_shape.shape = col_sphere
	body.add_child(col_shape)
	root.add_child(body)

	# Coada: bulgari mai mici care raman in urma bilei, ca sa se vada de unde a
	# venit si incotro merge. Nu particule — trei mesh-uri refolosite, care se
	# aseaza pe traiectoria de acum cateva zecimi.
	var trail: Array[MeshInstance3D] = []
	for k in TRAIL_COUNT:
		var t_mesh := MeshInstance3D.new()
		t_mesh.name = "Coada%d" % (k + 1)
		var t_sph := SphereMesh.new()
		# Se subtiaza spre coada: bulgarii vechi s-au risipit deja.
		var f := 1.0 - float(k + 1) / float(TRAIL_COUNT + 1)
		t_sph.radius = radius * 0.62 * f
		t_sph.height = radius * 1.24 * f
		t_sph.radial_segments = 6
		t_sph.rings = 3
		t_mesh.mesh = t_sph
		t_mesh.material_override = lava_mat
		root.add_child(t_mesh)
		trail.append(t_mesh)

	# Avertismentul: un disc incins la gura, aprins cu `telegraph` secunde
	# inainte de tasnire. E singurul lucru vizibil cand coloana e jos, deci el
	# e ce citesti ca sa alegi culoarul.
	var warn := MeshInstance3D.new()
	warn.name = "Avertisment"
	var disc := CylinderMesh.new()
	disc.top_radius = radius * 1.5
	disc.bottom_radius = radius * 1.5
	disc.height = 0.12
	disc.radial_segments = COLUMN_SEGMENTS
	disc.rings = 1
	warn.mesh = disc
	warn.material_override = lava_mat
	warn.position = Vector3.UP * 0.1
	warn.visible = false
	root.add_child(warn)

	# Zona de impact: CALATORESTE cu bila (e copil al corpului), deci te arde
	# unde e focul, nu pe toata verticala gurii. La coloana era o capsula cat
	# tot jetul; la bila, o sfera ceva mai larga decat ea — te arde si cand o
	# razuiesti, nu doar cand intri in ea cu botul.
	var area := Area3D.new()
	area.name = "Impact"
	var a_shape := CollisionShape3D.new()
	var a_sphere := SphereShape3D.new()
	a_sphere.radius = radius + 0.8
	a_shape.shape = a_sphere
	area.add_child(a_shape)
	body.add_child(area)

	return {
		"root": root, "body": body, "warn": warn, "area": area,
		"trail": trail,
		"phase": _slot_phase(index), "cooldown": {}, "up": false,
	}


## Faza gheizerului `index`: cercul impartit EGAL la numarul de guri.
##
## Cu 2 guri asta da 0.0 si 0.5 — opozitie perfecta, contractul din antet. Cu 3,
## treimi. Nu se pune pe fiecare gheizer de mana fiindca invariantul („exista
## mereu un culoar liber") trebuie sa tina prin constructie, nu prin grija cui
## editeaza scena.
func _slot_phase(index: int) -> float:
	var n := maxi(vents.size(), 1)
	return float(index) / float(n)


## Cat poate sta o coloana sus fara ca doua sa fie ridicate deodata.
##
## Fereastra in care gura e OBSTACOL nu e `up_fraction`: bila e in aer si cat
## urca, si cat cade, deci tine `up_fraction * (1 + FALL_FRAC)` din ciclu
## (tasnirea e deja inauntru — vezi `_tick`, unde ea consuma primul
## `RISE_FRAC` din fereastra). Ca sa existe MEREU un culoar liber, fereastra
## asta trebuie sa incapa in decalajul dintre doua guri vecine, adica 1/n.
##
## Se CALCULEAZA, nu se lasa pe seama cui editeaza scena: invariantul din antet
## e ce vinde hazardul, si o valoare pusa cu ochiul in inspector l-ar rupe in
## tacere. Sonda l-a prins deja o data, la 0.38 cu doua guri.
func _max_up_fraction() -> float:
	var n := maxi(vents.size(), 1)
	if n < 2:
		return up_fraction
	return maxf((1.0 / float(n) - GAP_FRAC) / (1.0 + FALL_FRAC), 0.05)


## Cat de departe pe axa drumului simte AI-ul perechea asta (metri).
##
## Nu e raza de coliziune, e raza de DECIZIE: pe cat de mult inainte incepe
## pilotul sa se aseze pe culoarul bun. Prea mic si intra deja angajat pe
## culoarul gresit; prea mare si tine linia extrema prin toata bucla craterului.
const AI_REACH_M: float = 34.0

## Se pune in grupul asta la `_ready` ca AI-ul sa gaseasca gheizerele fara sa
## le caute prin arbore in fiecare cadru (conventia de la `eruption_bombs`).
const AI_GROUP: StringName = &"fireball_geysers"


## Pe ce parte a drumului e liber peste `ahead` secunde: -1 stanga, +1 dreapta,
## 0 daca nu conteaza (ambele libere, sau perechea nu e in fata ta).
##
## EXISTA PENTRU AI, si nu e o comoditate: prima versiune n-avea nimic aici, iar
## ProbeRace a masurat exact esecul caruselului pe felia craterului — 11.6 m/s
## fata de 23.3 in baseline, 20% din timp „lent", 16 izbituri in pereti si 45 de
## repuneri fata de 2. Pilotii nu stiu sa pandeasca o coloana: intrau in ea,
## ricosau in perete si se aglomerau. Un hazard pe care doar jucatorul il poate
## citi nu e gimmick, e taxa pe AI.
##
## Se intreaba cu `ahead` = cat ii ia masinii sa ajunga aici, deci raspunsul e
## despre momentul SOSIRII, nu despre acum.
func safe_side(ahead: float) -> float:
	if _geysers.is_empty():
		return 0.0
	var t_future := fposmod((_clock + ahead) / period, 1.0)
	var best := 0.0
	var best_free := -1.0
	for g in _geysers:
		# Cat mai are de stat JOS gura asta din momentul sosirii. Cu cat mai
		# mult, cu atat culoarul ei e mai sigur.
		var free := _time_down_from(g, t_future)
		if free > best_free:
			best_free = free
			# Semnul lateral al gurii in spatiul perechii: X local pozitiv =
			# dreapta. Culoarul liber e cel al gurii care sta jos.
			best = signf((g["root"] as Node3D).position.x)
	return best


## Cat de lateral trebuie sa stea o masina ca sa fie sigura pe culoarul liber,
## ca fractie din semilatimea drumului (adica in unitatile lui `line` din AI).
##
## SE DERIVA din geometria perechii, nu se alege: culoarul liber tine de la
## marginea drumului pana la buza zonei de impact a coloanei ridicate, iar
## masina trebuie la MIJLOCUL lui. Cu numerele craterului (gura la 2.73 m,
## impact 2.40 m, semilatime 6.5 m) iese 0.47.
##
## Prima versiune a AI-ului avea aici 0.55 „ca sa nu fie lipit de perete" si
## trimitea masina FIX in coloana: 0.55 * 6.5 = 3.58 m, iar coloana ocupa
## 0.33..5.13. Un numar rotund ales cu ochiul pe o geometrie in care marginea
## sigura e la 0.33 m de axa — de-asta se socoteste.
func ai_line_offset() -> float:
	var half := _road_half()
	if half <= 0.0:
		return 0.5
	# Cea mai laterala gura decide: buza dinspre axa a zonei ei de impact e
	# marginea culoarului liber de partea cealalta.
	var vent_x := 0.0
	for v in vents:
		vent_x = maxf(vent_x, absf(v.x))
	var impact_r := radius + 0.8 # oglindeste raza zonei din `_build_geyser`
	# Zona prinde CORPUL masinii, nu centrul ei: Area3D raporteaza suprapunerea
	# colizoarelor. Deci marginea sigura se ia cu raza efectiva a masinii
	# (diagonala semi-gabaritului, ~2.2 m — masina poate fi si oblica in drift).
	#
	# Fara termenul asta iesea 0.49 si masinile erau lovite stand la ~1.3 m de
	# axa, adica „in afara" coloanei dupa socoteala pe centre: masurat pe
	# ProbeRace, 80 de loviri in 120 s. Distanta centru-centru nu e distanta
	# dintre corpuri.
	var car_reach := 2.2
	# Marginea dinspre exterior a culoarului liber, fata de gura OPUSA.
	var lo := -vent_x + impact_r + car_reach
	# Cat de aproape de perete poate sta masina si sa ramana pe asfalt.
	var hi := half - 0.9
	if lo >= hi:
		# Coloanele nu lasa culoar utilizabil aici — nu avem ce recomanda.
		# Semnaleaza cu 0.0 (AI-ul isi pastreaza linia si incetineste).
		return 0.0
	return clampf(((lo + hi) * 0.5) / half, 0.1, 0.92)


## Semilatimea drumului aici. O ia de la pista, ca sa nu fie inca un numar
## scris de doua ori: daca se largeste soseaua pe crater, culoarul se muta
## odata cu ea.
func _road_half() -> float:
	# URCA prin arbore, nu `get_parent()`: perechile stau grupate sub un nod
	# de organizare („GheizereCrater"), deci parintele direct nu e pista.
	# Masurat: cu get_parent() iesea 0 si `ai_line_offset` cadea pe implicitul
	# 0.5, care pe crater trimite masina fix in coloana.
	var t: Track = null
	var n := get_parent()
	while n != null and t == null:
		t = n as Track
		n = n.get_parent()
	if t == null:
		return 0.0
	var idx: int = t.closest_index_global(global_position)
	return t.width_at(t.frac_at(idx))


## Cat timp (fractie de ciclu) mai sta gura jos, incepand de la faza `t`.
## 0 = e sus chiar acum.
func _time_down_from(g: Dictionary, t_world: float) -> float:
	var up := minf(up_fraction, _max_up_fraction())
	# Fereastra in care gura e periculoasa = cat e bila in aer (vezi `_tick`).
	var blocked := up * (1.0 + FALL_FRAC)
	var t := fposmod(t_world - phase - float(g["phase"]), 1.0)
	if t < blocked:
		return 0.0 # e ridicata la momentul ala
	return 1.0 - t # cat mai e pana la urmatoarea tasnire


func _physics_process(delta: float) -> void:
	_clock = fposmod(_clock + delta, period)
	for g in _geysers:
		_tick(g, delta)


func _tick(g: Dictionary, delta: float) -> void:
	var t := fposmod(_clock / period - phase - float(g["phase"]), 1.0)
	# Cat din ciclu e bila IN AER. Plafonat, ca invariantul sa nu depinda de ce
	# s-a tastat in inspector (vezi `_max_up_fraction`).
	var flight := minf(up_fraction * (1.0 + FALL_FRAC), _max_up_fraction()
		* (1.0 + FALL_FRAC))

	var body := g["body"] as AnimatableBody3D
	var area := g["area"] as Area3D
	var trail := g["trail"] as Array[MeshInstance3D]

	var airborne := t < flight
	if airborne:
		# ARC BALISTIC: y = 4h * k * (1 - k), k = 0..1.
		#
		# Parabola, nu doua rampe lipite: bila urca incetinind si cade
		# accelerand, dintr-o singura formula — asa arata ceva aruncat, si
		# varful iese exact la `height` la mijlocul zborului.
		var k := t / flight
		body.position = Vector3.UP * (4.0 * height * k * (1.0 - k))
		# Coada: unde era bila cu cateva zecimi in urma, pe ACEEASI parabola.
		for idx in trail.size():
			var lag := TRAIL_LAG * float(idx + 1)
			var kt := clampf(k - lag, 0.0, 1.0)
			var m := trail[idx]
			m.position = Vector3.UP * (4.0 * height * kt * (1.0 - kt))
			# Coada dispare cand bila abia a plecat (n-are ce lasa in urma).
			m.visible = kt > 0.001
	else:
		body.position = Vector3.ZERO
		for m in trail:
			m.visible = false

	body.visible = airborne
	# `monitoring` pe zona, nu process_mode pe corp: colizorul unui
	# AnimatableBody3D ramane in spatiul fizic si cu procesarea stinsa, deci
	# oprirea trebuie facuta pe forma, nu pe nod.
	area.monitoring = airborne
	body.process_mode = Node.PROCESS_MODE_INHERIT if airborne 		else Node.PROCESS_MODE_DISABLED

	# Avertismentul: discul incins de la gura, aprins inainte de plecare, cat
	# bila e inca jos. Pulseaza, ca sa se citeasca drept ceas, nu decor.
	var warn := g["warn"] as MeshInstance3D
	var to_rise := fposmod(1.0 - t, 1.0)
	var warning := not airborne and to_rise <= telegraph / period
	warn.visible = warning
	if warning:
		var pulse := 1.0 + 0.35 * sin(t * TAU * 14.0)
		warn.scale = Vector3(pulse, 1.0, pulse)

	if airborne and not bool(g["up"]):
		g["up"] = true
		AudioManager.play_sfx(&"avalanche_hit", 0.85)
	elif not airborne:
		g["up"] = false

	var cooldown := g["cooldown"] as Dictionary
	for key: Variant in cooldown.keys():
		var left := float(cooldown[key]) - delta
		if left <= 0.0:
			cooldown.erase(key)
		else:
			cooldown[key] = left

	# Doar cat bila e in aer: cazuta, nu exista si nu are ce arde.
	if bool(g["up"]):
		_hit_cars(g)


func _hit_cars(g: Dictionary) -> void:
	var area := g["area"] as Area3D
	var cooldown := g["cooldown"] as Dictionary
	for b in area.get_overlapping_bodies():
		var car := b as Car
		if car == null or cooldown.has(car):
			continue
		cooldown[car] = HIT_COOLDOWN
		car.ignite(burn_seconds, BURN_SPEED_FACTOR, BURN_KEEP_SPEED)
		# Zvarlirea: RADIAL, dinspre gura spre masina. Coloana e o forta care
		# impinge in afara, nu una cu directie proprie — deci te scoate de pe
		# linie in partea in care ai intrat, si asta se citeste ca fizica, nu
		# ca o palma dintr-o directie aleasa de designer.
		var away := car.global_position - (g["root"] as Node3D).global_position
		away.y = 0.0
		if away.length() < 0.2:
			away = -car.global_transform.basis.z
		car.apply_sweep(away.normalized() * throw_push + Vector3.UP * throw_lift)
		fireball_hit.emit(car)
