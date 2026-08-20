@tool
class_name IceFieldHazard
extends Node3D
## CAMPUL DE PLACI CRAPATE (Baikal, docs/track_briefs/baikal.md §2 POI C).
##
## Nu e un obiect pus PE drum, e drumul insusi, spart: pe un interval din
## autostrada de gheata suprafata se genereaza ca FRACTURA VORONOI — placi
## poligonale de 5-8 m, ridicate ~0.4 m peste placa lacului (camp de presiune,
## exact cum arata pe Baikalul real), cu fisuri de apa neagra INTRE ele.
## Apa se vede doar in fisuri, deci negrul e semnal, nu chenar — versiunea
## veche (IceSlabHazard, un dreptunghi negru cu patru heptagoane clonate
## deasupra) citea ca un capac de canal si a fost inlocuita de asta.
##
## De ce camp RIDICAT, nu scufundat: sub toata zona sta coliziunea placii
## lacului (un box cu fata la cota drumului, vezi Track._build_water pe tema
## `frozen`). O placa inclinata SUB cota aia ar fi luptat cu colliderul —
## roata (raycast) ar fi calcat pe podeaua invizibila a lacului, si exact asa
## isi pierdea efectul hazardul vechi. Ridicat, tot jocul plăcii ramane
## DEASUPRA lacului, deci fiecare grad de inclinare chiar ajunge la roti.
##
## Placile MOARTE sunt DENIVELATE (panta si cota aleatoare per placa,
## UNEVEN_*): campul e drumul prost al pistei, cu trepte de 8-15 cm intre
## placi vecine pe care suspensia le simte la orice viteza — reglaj din
## playtest, versiunea coplanara nu se simtea deloc in volan.
##
## Placile „VII" (8 din camp, pe culoar, marcate cinstit cu retea de
## crapaturi albe si fata mai inchisa):
##   - se ASAZA 10 cm sub orice masina care calca pe ele, cu trosnet la
##     primul contact — feedback imediat, chiar si solo;
##   - se INCLINA spre coltul incarcat (ambele axe, arc rapid ~0.1 s);
##   - acumuleaza STRICACIUNE la fiecare trecere (masa x timp; turbo
##     dubleaza) si nu se vindeca intre treceri: a 3-a trecere normala /
##     a 2-a cu turbo / prima a unui mastodont boostat o RUPE — trosnet,
##     tasnitura de cioburi, placa se scufunda sub linia apei si cine e pe
##     ea e repus pe traseu. Revine in ~2 s (flotabilitate), cu
##     stricaciunea stearsa.
## Skill-ul e citirea campului: ocolesti placile marcate, sau risti prin
## mijloc si tii minte cate treceri are placa in ea — si a cui e urmatoarea.
##
## AnimatableBody3D cu sync_to_physics pentru placile vii (ca traveea podului
## si trenul): masina e purtata, nu strapunsa. Transformarea se scrie
## INTREAGA, o data pe cadru (Jolt: pozitie + rotatie scrise separat ingheata
## corpul in tacere). Semnele de rotatie sunt DERIVATE din produsul vectorial
## al axelor si verificate geometric in tools/probe_ice_field.gd, nu ghicite.

## Cat de sus pluteste campul peste placa lacului (m).
const RAISE: float = 0.38
## Buza fetei de sus peste profilul de baza.
const LIP: float = 0.05
## Rampa de intrare/iesire (m): profilul urca de la cota drumului la RAISE.
const RAMP_LEN: float = 9.0
## Pasul grilei de seminte Voronoi (m) — placi de ~5-8 m dupa jitter.
const CELL: float = 6.2
## Jitterul semintelor, ca fractie din CELL.
const JITTER: float = 0.38
## Cu cat se retrage fiecare placa din celula ei = jumatate de fisura (m).
const INSET_STATIC: float = 0.18
const INSET_LIVE: float = 0.42
## Denivelarea STATICA a placilor moarte: panta aleatoare (m/m, ~±2.6°) si
## abaterea de cota a centrului (m). Campul de presiune e drumul prost al
## pistei — pragurile de 8-15 cm dintre placi vecine sunt ce simti in volan
## la orice viteza, cu suspensia reala, nu un shake pe camera. Primul reglaj
## (±3 cm, placi coplanare cu profilul) nu se simtea deloc: la 30 m/s o
## fisura de 0.5 m e UN tick de fizica, doar treptele dintre placi raman.
const UNEVEN_GRAD: float = 0.045
const UNEVEN_H: float = 0.06
## Cat iese campul lateral dincolo de semilatimea drumului (m).
const EXTRA_W: float = 5.0
## Grosimea vizuala/de coliziune a unei placi (m).
const THICK: float = 0.55
## Cat cade roata intr-o fisura: apa neagra (cu coliziune) sta atat sub
## fetele placilor. Destul sa se simta, prea putin ca sa te inghita — vezi
## comentariul de la constructia apei.
const GAP_DROP: float = 0.13

## Momentul (kg*m) la care o placa vie atinge inclinarea maxima: o masina de
## referinta (100 kg) la 2.2 m de centru.
const FULL_TORQUE: float = 100.0 * 2.2
## Arcul inclinarii: raspuns in ~0.1 s — se simte CAT esti pe placa.
const TILT_STIFF: float = 80.0
const TILT_DAMP: float = 12.0
## Sarcina de referinta (kg-echivalent) care NORMEAZA stricaciunea: o masina
## medie. Turbo dubleaza apasarea, masinile grele conteaza proportional.
const BREAK_LOAD: float = 165.0
## Stricaciunea CUMULATA (in secunde-de-sarcina-de-referinta) la care placa
## se rupe. Prima versiune cerea sarcina TINUTA 0.55 s peste un prag — adica
## niciodata in cursa: la 30 m/s stai pe o placa de 7 m fix 0.23 s, deci nici
## turbo (200-520 kg-echiv.) nu apuca sa o rupa, si hazardul era mort la
## volan (feedback de playtest). Acum stricaciunea NU se mai vindeca intre
## treceri: o masina normala rupe placa la a 3-a trecere, cu turbo la a 2-a,
## autobuzul cu turbo chiar sub el. Placa revine dupa HOLD_TIME cu
## stricaciunea stearsa — evenimentul se poate repeta, dar nu escaladeaza
## in gauri permanente.
const BREAK_TIME: float = 0.45
## Cat se lasa o placa vie sub PRIMA masina care calca pe ea (m) — feedback
## imediat, cu trosnet, chiar si solo: simti CA e vie inainte sa afli CE face.
const SETTLE_DROP: float = 0.10
## Scufundarea placii rupte si arcul ei (mai moale — e o masa mare in apa).
const SINK_STIFF: float = 34.0
const SINK_DAMP: float = 9.0
## Cat sta scufundata inainte sa revina (s, de la rupere).
const HOLD_TIME: float = 2.0
## Cooldown intre trosnetele mici de avertisment (s).
const CRACK_COOLDOWN: float = 1.4

enum PlateState { SOLID, BROKEN }

## Datele campului, primite de la Track (in spatiul pistei). Vezi setup().
var _pts: PackedVector3Array = PackedVector3Array()
var _sides: PackedVector3Array = PackedVector3Array()
var _hws: PackedFloat32Array = PackedFloat32Array()
var _seed: int = 0
var _plate_mat: Material
## 8, nu 4: cu 4 pe ~110 placi puteai face tururi fara sa atingi una — iar
## distantarea de 12 m tine totusi campul de mine departe (brieful cere
## "cel mult una-doua pe linie", nu zero).
var _live_count: int = 8

var _s: PackedFloat32Array = PackedFloat32Array() # abscisa curbilinie per proba
var _len: float = 0.0
var _wide: float = 0.0 # semilatimea campului (drum + EXTRA_W)
var _area: Area3D
var _audio: AudioStreamPlayer3D
var _live: Array[Dictionary] = []
var _crack_cd: float = 0.0


## Track ii da PROBELE traseului pe intervalul campului (puncte de centru la
## cota drumului, lateralele si semilatimile lor) plus samanta lumii si
## materialul benzii de gheata — aceeasi instanta ca banda, ca sa nu urce
## numaratoarea de materiale si ca placile sa fie, la propriu, din gheata
## drumului. Aceeasi despartire ca la tren: pista calculeaza traseul, hazardul
## primeste numere in spatiul lui.
func setup(pts: PackedVector3Array, sides: PackedVector3Array,
		hws: PackedFloat32Array, world_seed: int, plate_mat: Material,
		live_count: int = 8) -> void:
	_pts = pts
	_sides = sides
	_hws = hws
	_seed = world_seed
	_plate_mat = plate_mat
	_live_count = live_count


func _ready() -> void:
	if _pts.size() >= 2:
		_build()


# ------------------------------------------------------- spatiul (s, t)

## Abscisa curbilinie: s de-a lungul drumului, t lateral (+ spre _sides).
func _prepare_spine() -> void:
	_s.resize(_pts.size())
	_s[0] = 0.0
	for i in range(1, _pts.size()):
		_s[i] = _s[i - 1] + _pts[i - 1].distance_to(_pts[i])
	_len = _s[_pts.size() - 1]
	_wide = 0.0
	for hw in _hws:
		_wide = maxf(_wide, hw)
	_wide += EXTRA_W


func _seg_at(s: float) -> int:
	var lo := 0
	var hi := _s.size() - 2
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if _s[mid] <= s:
			lo = mid
		else:
			hi = mid - 1
	return lo


## Punctul de pe drum la (s, t), la COTA DRUMULUI (y-ul profilului vine peste).
func _map(s: float, t: float) -> Vector3:
	var i := _seg_at(clampf(s, 0.0, _len))
	var f := 0.0
	var span := _s[i + 1] - _s[i]
	if span > 0.001:
		f = clampf((s - _s[i]) / span, 0.0, 1.0)
	var side := _sides[i].lerp(_sides[i + 1], f).normalized()
	return _pts[i].lerp(_pts[i + 1], f) + side * t


## Cota fetei de sus a campului la (s, t), fara jitterul per placa.
##
## Profilul coboara la cota lacului pe TOATE marginile, nu doar la capete:
## fara rampa laterala, campul avea un perete de 0.38 m pe 146 m de lungime,
## iar o masina impinsa de pe placi pe lac nu mai putea urca inapoi — se
## batea cu peretele pana la anti-blocaj. Sortul lateral de EXTRA_W devine
## panta de ~8%, urcabila din mers, si campul ramane traversabil din orice
## directie, ca orice alta bucata de lume (regula scurtaturilor risc/rasplata).
func _top_y(s: float, t: float = 0.0) -> float:
	var base := _map(s, 0.0).y
	var ramp_in := smoothstep(0.0, RAMP_LEN, s)
	var ramp_out := smoothstep(0.0, RAMP_LEN, _len - s)
	var ramp_side := smoothstep(_wide, _wide - EXTRA_W, absf(t))
	return base + LIP + RAISE * ramp_in * ramp_out * ramp_side


## (s, t) pentru un punct din lume — cautare liniara pe probe (~70), apelata
## doar pentru masinile din zona de incarcare, deci ieftina.
func _to_st(p: Vector3) -> Vector2:
	var best := 0
	var best_d := INF
	for i in _pts.size():
		var d := Vector2(p.x - _pts[i].x, p.z - _pts[i].z).length_squared()
		if d < best_d:
			best_d = d
			best = i
	var i0 := clampi(best, 0, _pts.size() - 2)
	var seg := _pts[i0 + 1] - _pts[i0]
	seg.y = 0.0
	var rel := p - _pts[i0]
	rel.y = 0.0
	var f := 0.0
	if seg.length_squared() > 0.001:
		f = clampf(rel.dot(seg) / seg.length_squared(), 0.0, 1.0)
	var s := _s[i0] + f * (_s[i0 + 1] - _s[i0])
	var side := _sides[i0].lerp(_sides[i0 + 1], f).normalized()
	return Vector2(s, rel.dot(side))


# ------------------------------------------------------------- Voronoi

## Celulele Voronoi ale dreptunghiului [0,L] x [-W,W] in spatiul (s, t).
## Fiecare celula = intersectia semiplanurilor fata de bisectoarele vecinilor
## — O(n^2) pe ~150 de seminte, o data la generare.
func _voronoi_cells(rng: RandomNumberGenerator) -> Array[PackedVector2Array]:
	var seeds: Array[Vector2] = []
	var cols := maxi(int(_len / CELL), 2)
	var rows := maxi(int(_wide * 2.0 / CELL), 2)
	for c in cols:
		for r in rows:
			var s := (float(c) + 0.5) * _len / float(cols) \
				+ rng.randf_range(-JITTER, JITTER) * CELL
			var t := -_wide + (float(r) + 0.5) * _wide * 2.0 / float(rows) \
				+ rng.randf_range(-JITTER, JITTER) * CELL
			seeds.append(Vector2(clampf(s, 0.5, _len - 0.5),
				clampf(t, -_wide + 0.3, _wide - 0.3)))
	var cells: Array[PackedVector2Array] = []
	var reach := CELL * 2.7
	for k in seeds.size():
		var poly := PackedVector2Array([
			Vector2(0.0, -_wide), Vector2(_len, -_wide),
			Vector2(_len, _wide), Vector2(0.0, _wide)])
		for m in seeds.size():
			if m == k or seeds[k].distance_to(seeds[m]) > reach:
				continue
			poly = _clip(poly, (seeds[k] + seeds[m]) * 0.5,
				(seeds[k] - seeds[m]).normalized())
			if poly.size() < 3:
				break
		if poly.size() >= 3 and _poly_area(poly) > 2.0:
			cells.append(poly)
	return cells


## Taie poligonul cu semiplanul { p : (p - point) . normal >= 0 }.
func _clip(poly: PackedVector2Array, point: Vector2,
		normal: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var da := (a - point).dot(normal)
		var db := (b - point).dot(normal)
		if da >= 0.0:
			out.append(a)
		if (da > 0.0) != (db > 0.0) and absf(da - db) > 0.000001:
			out.append(a.lerp(b, da / (da - db)))
	return out


func _poly_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return absf(a) * 0.5


func _poly_centroid(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	return c / float(poly.size())


## Retrage poligonul CONVEX cu `d` pe fiecare muchie = fisura dintre placi.
## Muchiile de pe marginea campului NU se retrag (2 cm doar), ca sa nu apara
## un sant de apa pe tot conturul — chenarul negru e exact boala pe care o
## reparam. Celulele-s convexe prin constructie (intersectie de semiplanuri),
## deci muchiile mutate spre interior se pot re-intersecta pereche cu pereche.
func _inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var n := poly.size()
	# orientare CCW, ca normala interioara sa fie rotirea cu +90 a muchiei
	var signed := 0.0
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		signed += p.x * q.y - q.x * p.y
	var ccw := signed > 0.0
	var pts: Array[Vector2] = []
	var dirs: Array[Vector2] = []
	var offs: Array[float] = []
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var e := (b - a)
		if e.length() < 0.001:
			continue
		e = e.normalized()
		var inward := Vector2(-e.y, e.x) if ccw else Vector2(e.y, -e.x)
		var dd := d
		if _on_rim(a) and _on_rim(b):
			dd = 0.02
		pts.append(a + inward * dd)
		dirs.append(e)
		offs.append(dd)
	n = pts.size()
	if n < 3:
		return PackedVector2Array()
	var out := PackedVector2Array()
	for i in n:
		var j := (i - 1 + n) % n
		# intersectia dreptelor (pts[j], dirs[j]) si (pts[i], dirs[i])
		var cross := dirs[j].x * dirs[i].y - dirs[j].y * dirs[i].x
		if absf(cross) < 0.000001:
			out.append(pts[i])
			continue
		var diff := pts[i] - pts[j]
		var u := (diff.x * dirs[i].y - diff.y * dirs[i].x) / cross
		out.append(pts[j] + dirs[j] * u)
	if out.size() < 3 or _poly_area(out) < 1.2 \
			or _poly_area(out) > _poly_area(poly) * 1.05:
		return PackedVector2Array()
	# La celulele inguste doua muchii mutate spre interior se pot incrucisa si
	# poligonul iese "fundita" (bowtie) — evantaiul lui ar iesi cu triunghiuri
	# intoarse, vizibile ca un crater negru in camp (prins pe captura, nu
	# dedus). Convexitatea se verifica pe semnul produselor vectoriale.
	var turn_sign := 0.0
	for i in out.size():
		var a := out[i]
		var b := out[(i + 1) % out.size()]
		var c := out[(i + 2) % out.size()]
		var cr := (b - a).cross(c - b)
		if absf(cr) < 0.000001:
			continue
		if turn_sign == 0.0:
			turn_sign = signf(cr)
		elif signf(cr) != turn_sign:
			return PackedVector2Array()
	return out


func _on_rim(p: Vector2) -> bool:
	return p.x < 0.05 or p.x > _len - 0.05 \
		or absf(p.y) > _wide - 0.05


# ------------------------------------------------------------- constructie

func _build() -> void:
	_prepare_spine()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed ^ 0x1CEF1E1D
	var cells := _voronoi_cells(rng)

	# placile vii: pe culoarul de rulare, dincolo de rampe, distantate — ca
	# fiecare linie de AI (si fiecare alegere a jucatorului) sa intalneasca
	# cel mult una-doua, nu un camp de mine.
	var live_idx: Array[int] = []
	# shuffle determinist cu rng-ul nostru, nu cu cel global al lui Godot:
	# doua rulari ale aceleiasi piste trebuie sa dea acelasi camp.
	var order := range(cells.size())
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	for k: int in order:
		if live_idx.size() >= _live_count:
			break
		var c := _poly_centroid(cells[k])
		var hw_here := _hws[_seg_at(c.x)]
		if c.x < RAMP_LEN + 8.0 or c.x > _len - RAMP_LEN - 8.0:
			continue
		if absf(c.y) > hw_here * 0.75:
			continue
		var ok := true
		for li: int in live_idx:
			if _poly_centroid(cells[li]).distance_to(c) < 12.0:
				ok = false
				break
		if ok:
			live_idx.append(k)

	# --- apa neagra: o banda sub tot campul, vizibila DOAR prin fisuri ------
	#
	# Apa are si COLIZIUNE, si sta la doar GAP_DROP sub fetele placilor, nu pe
	# fundul lacului. Nu e o scapare: raycast-ul rotii cade in ORICE fisura,
	# oricat de ingusta (raza e o linie), deci cu apa la -0.4 m fiecare fisura
	# era o capcana — o masina incetinita ramanea cu roata in sant si sasiul
	# agatat de muchiile placilor. Cu podeaua la -0.13, fisura se SIMTE sub
	# roti dar nu te inghite — iar placa vie rupta se scufunda SUB planul
	# apei: masina de pe ea ramane o clipa pe apa neagra (podeaua), stropii
	# tasnesc, apoi repunerea. Adancimea apei e pictata (culoarea aproape
	# neagra), nu geometrica.
	# Coloane laterale, ca podeaua sa urmeze SI rampa laterala a profilului —
	# plata pe toata latimea, ar fi iesit DEASUPRA placilor din sortul care
	# coboara spre lac.
	var cols: Array[float] = [-_wide, -_wide + EXTRA_W, 0.0,
		_wide - EXTRA_W, _wide]
	# Pe muchiile exterioare podeaua se scufunda sub placa lacului (marja
	# dubla): planurile placilor din sort aproximeaza liniar smoothstep-ul
	# rampei, iar o podea prea sus acolo ar iesi prin fetele lor.
	var drops: Array[float] = [GAP_DROP * 2.3, GAP_DROP, GAP_DROP,
		GAP_DROP, GAP_DROP * 2.3]
	var water := SurfaceTool.new()
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(_pts.size() - 1):
		for c in range(cols.size() - 1):
			var a0 := _map(_s[i], cols[c])
			var a1 := _map(_s[i], cols[c + 1])
			var b0 := _map(_s[i + 1], cols[c])
			var b1 := _map(_s[i + 1], cols[c + 1])
			a0.y = _top_y(_s[i], cols[c]) - drops[c]
			a1.y = _top_y(_s[i], cols[c + 1]) - drops[c + 1]
			b0.y = _top_y(_s[i + 1], cols[c]) - drops[c]
			b1.y = _top_y(_s[i + 1], cols[c + 1]) - drops[c + 1]
			water.add_vertex(a0)
			water.add_vertex(b0)
			water.add_vertex(a1)
			water.add_vertex(a1)
			water.add_vertex(b0)
			water.add_vertex(b1)
	water.generate_normals()
	var wmesh := MeshInstance3D.new()
	wmesh.name = "Water"
	wmesh.mesh = water.commit()
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.05, 0.09, 0.12)
	wmat.roughness = 0.35
	wmat.metallic_specular = 0.45
	wmesh.material_override = wmat
	add_child(wmesh)
	var wbody := StaticBody3D.new()
	wbody.name = "WaterFloor"
	var wcol := CollisionShape3D.new()
	wcol.shape = (wmesh.mesh as ArrayMesh).create_trimesh_shape()
	wbody.add_child(wcol)
	add_child(wbody)

	# --- placile ------------------------------------------------------------
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var static_body := StaticBody3D.new()
	static_body.name = "Plates"
	add_child(static_body)
	var live_k := 0
	for k in cells.size():
		var is_live := k in live_idx
		var poly := _inset(cells[k], INSET_LIVE if is_live else INSET_STATIC)
		if poly.is_empty():
			poly = cells[k] # celula prea mica pentru retragere: fara fisura
		var c2 := _poly_centroid(poly)
		# planul fetei de sus: cota + pantele profilului la centroid (rampele
		# de capat SI cea laterala); placa ramane PLANA — se inclina in bloc.
		#
		# Placile MOARTE primesc peste profil o panta si o cota aleatoare
		# (UNEVEN_*): campul de presiune e denivelat pe bune, cu trepte de
		# 8-15 cm intre vecine, si suspensia le simte la orice viteza.
		# Mesh-ul si coliziunea ies din ACEIASI parametri, deci raman
		# consistente. Placile VII raman plane la cota profilului: gheata
		# subtire, proaspata — netezimea lor e parte din semnal, iar bugetul
		# lor de inclinare (theta_max) ramane intreg pentru joc.
		var h_c := _top_y(c2.x, c2.y)
		var grad_s := _top_y(c2.x + 0.5, c2.y) - _top_y(c2.x - 0.5, c2.y)
		var grad_t := _top_y(c2.x, c2.y + 0.5) - _top_y(c2.x, c2.y - 0.5)
		if not is_live:
			h_c += rng.randf_range(-UNEVEN_H, UNEVEN_H)
			grad_s += rng.randf_range(-UNEVEN_GRAD, UNEVEN_GRAD)
			grad_t += rng.randf_range(-UNEVEN_GRAD, UNEVEN_GRAD)
		if is_live:
			_build_live_plate(poly, c2, h_c, grad_s, grad_t, live_k, rng)
			live_k += 1
		else:
			var tint := Color(1, 1, 1).lerp(Color(0.88, 0.95, 0.96),
				rng.randf() * 0.8)
			_emit_plate(st, poly, c2, h_c, grad_s, grad_t, tint,
				func(v: Vector3) -> Vector3: return v)
			var shape := CollisionShape3D.new()
			shape.shape = _plate_shape(poly, c2, h_c, grad_s, grad_t,
				Vector3.ZERO)
			static_body.add_child(shape)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "PlatesMesh"
	mi.mesh = st.commit()
	mi.material_override = _plate_mat
	static_body.add_child(mi)

	# --- zona care aduna masinile (pentru placile vii si repunere) ----------
	_area = Area3D.new()
	_area.name = "Load"
	_area.monitoring = true
	_area.monitorable = false
	add_child(_area)
	var step := 12.0
	var s := step * 0.5
	while s < _len:
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(_wide * 2.0, 4.0, step + 2.0)
		col.shape = box
		var i := _seg_at(s)
		var fwd := (_pts[i + 1] - _pts[i]).normalized()
		var origin := _map(s, 0.0) + Vector3.UP * (RAISE * 0.5 + 1.0)
		col.transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), origin)
		_area.add_child(col)
		s += step

	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 90.0
	_audio.unit_size = 14.0
	add_child(_audio)


## Emite o placa (fata de sus ca evantai + fusta laterala) in SurfaceTool-ul
## dat. `warp` lasa placile vii sa-si aduca vertecsii in spatiul lor local.
func _emit_plate(st: SurfaceTool, poly: PackedVector2Array, c2: Vector2,
		h_c: float, grad_s: float, grad_t: float, tint: Color,
		warp: Callable) -> void:
	var top: Array[Vector3] = []
	for p in poly:
		var v := _map(p.x, p.y)
		v.y = h_c + grad_s * (p.x - c2.x) + grad_t * (p.y - c2.y)
		top.append(warp.call(v))
	# Orientarea NU se ghiceste: maparea (s,t) -> lume poate intoarce bucla in
	# oricare sens, dupa cum arata lateralul drumului. Normala buclei (Newell)
	# trebuie sa iasa in sus, altfel fata de sus e culled si placa se vede
	# doar de dedesubt — fix clasa de bug pe care materialul CULL_BACK o face
	# invizibila in cod si evidenta doar pe captura.
	var normal_y := 0.0
	for i in top.size():
		var a := top[i]
		var b := top[(i + 1) % top.size()]
		normal_y += (a.z + b.z) * (a.x - b.x)
	if normal_y < 0.0:
		top.reverse()
	var n := top.size()
	var center := _map(c2.x, c2.y)
	center.y = h_c
	center = warp.call(center)
	var deep := Color(0.42, 0.62, 0.68)
	for i in n:
		var j := (i + 1) % n
		# fata de sus (evantai din centroid; poligonul e convex)
		st.set_color(tint)
		st.add_vertex(center)
		st.add_vertex(top[i])
		st.add_vertex(top[j])
		# fusta: alb spart sus, turcoaz adanc jos. Emisa pe AMBELE orientari:
		# cateva sute de triunghiuri in plus pe tot campul, si nicio muchie
		# nu dispare dupa directia din care o privesti.
		var bi := top[i] + Vector3.DOWN * THICK
		var bj := top[j] + Vector3.DOWN * THICK
		for flip in 2:
			st.set_color(tint)
			st.add_vertex(top[j] if flip == 0 else top[i])
			st.add_vertex(top[i] if flip == 0 else top[j])
			st.set_color(deep)
			st.add_vertex(bi if flip == 0 else bj)
			st.add_vertex(bi if flip == 0 else bj)
			st.add_vertex(bj if flip == 0 else bi)
			st.set_color(tint)
			st.add_vertex(top[j] if flip == 0 else top[i])


func _plate_shape(poly: PackedVector2Array, c2: Vector2, h_c: float,
		grad_s: float, grad_t: float,
		origin_off: Vector3) -> ConvexPolygonShape3D:
	var points := PackedVector3Array()
	for p in poly:
		var v := _map(p.x, p.y)
		v.y = h_c + grad_s * (p.x - c2.x) + grad_t * (p.y - c2.y)
		points.append(v - origin_off)
		points.append(v - origin_off + Vector3.DOWN * THICK)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape


## Placa VIE: corp propriu (AnimatableBody3D) cu originea in centroid, mesh
## si coliziune in spatiul lui local, marcata cinstit cu crapaturi albe.
func _build_live_plate(poly: PackedVector2Array, c2: Vector2, h_c: float,
		grad_s: float, grad_t: float, idx: int,
		rng: RandomNumberGenerator) -> void:
	var origin := _map(c2.x, c2.y)
	origin.y = h_c
	var body := AnimatableBody3D.new()
	body.name = "LivePlate%d" % idx
	body.sync_to_physics = true
	var rest := Transform3D(Basis.IDENTITY, origin)
	body.transform = rest
	add_child(body)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Fata VIZIBIL mai inchisa decat placile moarte: gheata subtire e mai
	# intunecata (se vede apa prin ea) — asta e semnalul care se citeste de la
	# chase cam. Prima incercare a fost pe dos (placa vie ALBA + panza alba):
	# alb pe alb, invizibil pe captura. Pe fondul inchis, panza alba de
	# crapaturi chiar contrasteaza.
	_emit_plate(st, poly, c2, h_c, grad_s, grad_t, Color(0.58, 0.82, 0.85),
		func(v: Vector3) -> Vector3: return v - origin)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _plate_mat
	body.add_child(mi)

	# reteaua de crapaturi albe — semnalul cinstit ca placa e vie (brief §2 C).
	# Panza de paianjen, nu doar raze: bratele radiale singure se pierdeau in
	# crapaturile pictate ale texturii de gheata (verificat pe captura de sus);
	# inelul care le leaga e ce o desparte de placile moarte la 30 m/s.
	var cr := SurfaceTool.new()
	cr.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := poly.size()
	var uv := Palette.uv(Palette.FOAM_WHITE)
	var ring: Array[Vector2] = []
	for arm in 5:
		@warning_ignore("integer_division")
		var a := poly[(arm * n) / 5]
		var to := (a - c2) * rng.randf_range(0.6, 0.92)
		_emit_crack(cr, c2, c2 + to, h_c, grad_s, grad_t, c2, origin, uv, rng)
		ring.append(c2 + to * rng.randf_range(0.5, 0.7))
	for i in ring.size():
		_emit_crack(cr, ring[i], ring[(i + 1) % ring.size()], h_c, grad_s,
			grad_t, c2, origin, uv, rng)
	# ...si o bordura alba pe tot conturul: crapaturile late din jurul placii
	# au muchii de gheata pisata. E semnalul care se vede de departe — panza
	# singura se pierdea in crapaturile pictate ale texturii (pe captura).
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var ai := a + (c2 - a).normalized() * 0.5
		var bi := b + (c2 - b).normalized() * 0.5
		var quad: Array[Vector2] = [a, b, bi, ai]
		var w: Array[Vector3] = []
		for q in quad:
			var v3 := _map(q.x, q.y)
			v3.y = h_c + grad_s * (q.x - c2.x) + grad_t * (q.y - c2.y) + 0.014
			w.append(v3 - origin)
		var flip := (w[1] - w[0]).cross(w[3] - w[0]).y < 0.0
		cr.set_uv(uv)
		cr.set_color(Color(1, 1, 1))
		if flip:
			cr.add_vertex(w[0])
			cr.add_vertex(w[2])
			cr.add_vertex(w[1])
			cr.add_vertex(w[0])
			cr.add_vertex(w[3])
			cr.add_vertex(w[2])
		else:
			cr.add_vertex(w[0])
			cr.add_vertex(w[1])
			cr.add_vertex(w[2])
			cr.add_vertex(w[0])
			cr.add_vertex(w[2])
			cr.add_vertex(w[3])
	var cmi := MeshInstance3D.new()
	cmi.name = "Cracks"
	cmi.mesh = cr.commit()
	cmi.material_override = Palette.world_material()
	body.add_child(cmi)

	var shape := CollisionShape3D.new()
	shape.shape = _plate_shape(poly, c2, h_c, grad_s, grad_t, origin)
	body.add_child(shape)

	# semnele rotatiei DERIVATE, nu ghicite: dy al unui punct la offsetul r
	# fata de axa a e theta * (a x r).y — vrem dy < 0 unde apasa masina
	var i := _seg_at(c2.x)
	var axis_u := (_pts[i + 1] - _pts[i]).normalized() # in lungul drumului
	var axis_v := _sides[i].normalized() # lateral
	var r_max := 0.1
	for p in poly:
		r_max = maxf(r_max, Vector2(p.x - c2.x, p.y - c2.y).length())
	var theta_max := asin(clampf((RAISE - 0.10) / r_max, 0.05, 0.6))
	var splash := _make_splash()
	body.add_child(splash)
	splash.position = Vector3.ZERO
	_live.append({
		"body": body, "poly": poly, "c2": c2, "rest": rest,
		"u": axis_u, "v": axis_v,
		"cu": signf(axis_u.cross(axis_v).y),
		"cv": signf(axis_v.cross(axis_u).y),
		"theta_max": theta_max,
		"au": 0.0, "au_v": 0.0, "av": 0.0, "av_v": 0.0,
		"sink": 0.0, "sink_v": 0.0,
		"stress": 0.0, "state": PlateState.SOLID, "timer": 0.0,
		"warned": false, "splash": splash,
	})


func _emit_crack(st: SurfaceTool, from: Vector2, to: Vector2, h_c: float,
		grad_s: float, grad_t: float, c2: Vector2, origin: Vector3,
		uv: Vector2, rng: RandomNumberGenerator) -> void:
	# linie franta din 3 segmente subtiri, la 1.2 cm peste fata placii
	var pts: Array[Vector2] = [from]
	for k in [0.35, 0.7]:
		var p: Vector2 = from.lerp(to, k)
		p += Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4))
		pts.append(p)
	pts.append(to)
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var dir := (b - a)
		if dir.length() < 0.05:
			continue
		var nrm := Vector2(-dir.y, dir.x).normalized() * 0.06
		var quad: Array[Vector2] = [a + nrm, b + nrm, b - nrm, a - nrm]
		var w: Array[Vector3] = []
		for q in quad:
			var v3 := _map(q.x, q.y)
			v3.y = h_c + grad_s * (q.x - c2.x) + grad_t * (q.y - c2.y) + 0.012
			w.append(v3 - origin)
		# normala in sus, aceeasi poveste ca la placi: maparea (s,t) poate
		# intoarce bucla, iar o crapatura culled e un semnal care nu exista
		if (w[1] - w[0]).cross(w[3] - w[0]).y < 0.0:
			var tmp := w[1]
			w[1] = w[3]
			w[3] = tmp
		st.set_uv(uv)
		st.set_color(Color(1, 1, 1))
		st.add_vertex(w[0])
		st.add_vertex(w[1])
		st.add_vertex(w[2])
		st.add_vertex(w[0])
		st.add_vertex(w[2])
		st.add_vertex(w[3])


## UN material si UN mesh pentru toate tasniturile: garda din probe_decor
## numara materialele per pista, si patru cuburi identice nu au de ce sa
## aduca patru materiale.
static var _splash_mesh: BoxMesh

func _make_splash() -> CPUParticles3D:
	if _splash_mesh == null:
		_splash_mesh = BoxMesh.new()
		_splash_mesh.size = Vector3(0.16, 0.16, 0.16)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.75, 0.88, 0.92)
		mat.roughness = 0.4
		_splash_mesh.surface_set_material(0, mat)
	var p := CPUParticles3D.new()
	p.name = "Splash"
	p.emitting = false
	p.one_shot = true
	p.amount = 42
	p.lifetime = 0.7
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 7.0
	p.gravity = Vector3(0, -14.0, 0)
	p.scale_amount_min = 0.10
	p.scale_amount_max = 0.28
	p.mesh = _splash_mesh
	return p


# --------------------------------------------------------------- runtime

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _area == null or _live.is_empty():
		return
	_crack_cd = maxf(_crack_cd - delta, 0.0)
	var cars: Array[Car] = []
	for b in _area.get_overlapping_bodies():
		var car := b as Car
		if car != null:
			cars.append(car)
	for plate in _live:
		_step_plate(plate, cars, delta)


func _step_plate(plate: Dictionary, cars: Array[Car], delta: float) -> void:
	var poly: PackedVector2Array = plate["poly"]
	var c2: Vector2 = plate["c2"]
	var torque_s := 0.0
	var torque_t := 0.0
	var load_kg := 0.0
	var on_plate: Array[Car] = []
	for car in cars:
		var st := _to_st(car.global_position)
		if not _in_poly(poly, st):
			continue
		on_plate.append(car)
		var w := car.mass * (2.0 if car.is_boosting else 1.0)
		load_kg += w
		torque_s += w * clampf(st.x - c2.x, -6.0, 6.0)
		torque_t += w * clampf(st.y - c2.y, -6.0, 6.0)

	var state: int = plate["state"]
	var theta_max: float = plate["theta_max"]
	var tgt_u := 0.0
	var tgt_v := 0.0
	var tgt_sink := 0.0
	if state == PlateState.SOLID:
		# inclinare spre incarcare; semnele derivate din (axa x brat).y
		tgt_u = -plate["cu"] * clampf(torque_t / FULL_TORQUE, -1, 1) * theta_max
		tgt_v = -plate["cv"] * clampf(torque_s / FULL_TORQUE, -1, 1) * theta_max
		# Asezarea: placa se lasa sub ORICE masina care calca pe ea, cu
		# trosnet la primul contact. Inainte, avertismentul era legat de
		# inclinare (>40% din theta_max) — prin centrul placii cuplul e ~0,
		# deci majoritatea trecerilor nu declansau nimic si placa parea
		# moarta. Contactul e semnalul cinstit: esti pe gheata subtire.
		if not on_plate.is_empty():
			tgt_sink = SETTLE_DROP
			if not plate["warned"] and _crack_cd <= 0.0:
				plate["warned"] = true
				_crack_cd = CRACK_COOLDOWN
				_play_crack(plate, 1.35, -8.0)
		else:
			plate["warned"] = false
		# Stricaciunea se ACUMULEAZA si nu se vindeca intre treceri (vezi
		# BREAK_TIME): fiecare traversare lasa urme, proportional cu masa
		# si cu turbo. Se sterge doar cand placa rupta revine la suprafata.
		plate["stress"] = float(plate["stress"]) \
			+ delta * load_kg / BREAK_LOAD
		if float(plate["stress"]) >= BREAK_TIME:
			print("DBG IceField: placa rupta, %d masini" % on_plate.size())
			plate["state"] = PlateState.BROKEN
			plate["timer"] = 0.0
			_play_crack(plate, 0.62, 2.0)
			(plate["splash"] as CPUParticles3D).restart()
	else:
		plate["timer"] = float(plate["timer"]) + delta
		# rupta: cade plat sub linia apei, pastrand putin din inclinare
		tgt_u = float(plate["au"]) * 0.35
		tgt_v = float(plate["av"]) * 0.35
		tgt_sink = RAISE - 0.04 if float(plate["timer"]) < HOLD_TIME else 0.0
		# cine e inca pe ea cand s-a dus sub apa e repus pe traseu
		if float(plate["sink"]) > (RAISE - 0.04) * 0.45:
			for car in on_plate:
				car.respawn()
		if float(plate["timer"]) >= HOLD_TIME and float(plate["sink"]) < 0.03:
			plate["state"] = PlateState.SOLID
			plate["stress"] = 0.0

	plate["au_v"] = float(plate["au_v"]) + (TILT_STIFF * (tgt_u
		- float(plate["au"])) - TILT_DAMP * float(plate["au_v"])) * delta
	plate["au"] = float(plate["au"]) + float(plate["au_v"]) * delta
	plate["av_v"] = float(plate["av_v"]) + (TILT_STIFF * (tgt_v
		- float(plate["av"])) - TILT_DAMP * float(plate["av_v"])) * delta
	plate["av"] = float(plate["av"]) + float(plate["av_v"]) * delta
	plate["sink_v"] = float(plate["sink_v"]) + (SINK_STIFF * (tgt_sink
		- float(plate["sink"])) - SINK_DAMP * float(plate["sink_v"])) * delta
	plate["sink"] = float(plate["sink"]) + float(plate["sink_v"]) * delta

	# transformarea INTREAGA, o singura scriere (Jolt)
	var rest: Transform3D = plate["rest"]
	var tilt := Basis(plate["u"] as Vector3, float(plate["au"])) \
		* Basis(plate["v"] as Vector3, float(plate["av"]))
	(plate["body"] as AnimatableBody3D).transform = Transform3D(tilt,
		rest.origin + Vector3.DOWN * float(plate["sink"]))


func _in_poly(poly: PackedVector2Array, p: Vector2) -> bool:
	var n := poly.size()
	var sign_ref := 0.0
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var cr := (b - a).cross(p - a)
		if absf(cr) < 0.000001:
			continue
		if sign_ref == 0.0:
			sign_ref = signf(cr)
		elif signf(cr) != sign_ref:
			return false
	return true


func _play_crack(plate: Dictionary, pitch: float, vol_db: float) -> void:
	if _audio == null:
		return
	var stream: AudioStream = AudioManager.SFX.get(&"ice_crack")
	if stream == null:
		return
	_audio.global_position = (plate["body"] as Node3D).global_position
	_audio.stream = stream
	_audio.pitch_scale = pitch * randf_range(0.94, 1.06)
	_audio.volume_db = vol_db
	_audio.play()


# --------------------------------------------------------------- pentru sonde

func live_plates() -> Array[Dictionary]:
	return _live


func plate_tilt_deg(idx: int) -> float:
	var p := _live[idx]
	return rad_to_deg(absf(float(p["au"])) + absf(float(p["av"])))


func plate_sink(idx: int) -> float:
	return float(_live[idx]["sink"])


func field_length() -> float:
	return _len
