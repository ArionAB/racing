@tool # vizibil si in preview-ul din editor
class_name TideHazard
extends WaterHazard
## MAREEA (Ha Long, Track22, brief §3): banda de jos a drumului de coasta e
## scurtatura pistei la maree joasa si e SUB APA la maree inalta.
##
## Gimmick-ul: nu e un obstacol care te loveste, e o **stare a lumii** cu ciclu
## lung (un tur intreg), pe care o **citesti de pe belvedere** cu ~30 s inainte
## sa ajungi la ea. Decizia („o iau sau nu?") se ia ACOLO, nu la intrare —
## de-aia ciclul e lung si de-aia telegraful e geografic, nu vizual-local.
##
## [b]Fata de celelalte variante de WaterHazard[/b] (`WaterHose`, `WaveSurge`,
## `ShishiOdoshi`): alea sunt EVENIMENTE de cateva secunde pe drumul principal.
## Mareea e o stare de ~80 s care deschide si inchide o BANDA INTREAGA. Deci:
##  - `_advance` nu numara o trecere, ci rezolva o faza lunga;
##  - pe langa taierea de grip (de la `WaterHazard`), hazardul e si **poarta de
##    banda**: intra in `Track.BRANCH_GATE_GROUP` cu `branch_index` +
##    `shortcut_open()`, exact ca lava de pe Stromboli si vaca de la Jodhpur.
##    Precedentul exista, deci grupul se alatura, nu se creeaza.
##
## [b]DECIZIA 3.1.3 din brief, luata pe cod citit[/b]: briful propunea „apa taie
## grip-ul, banda rămâne deschisa" ca varianta mai ieftina, lasand decizia
## riscanta posibila. Dar `Track.branch_is_open` + `BRANCH_GATE_GROUP` exista
## deja si costa DOUA metode, iar inchiderea e mai onesta: la 1.5 m de apa peste
## terasa, o banda „deschisa cu grip tăiat" ar fi o capcana, nu o decizie — iar
## AI-ul re-alege la fiecare tur (`shortcut_open` se intreaba per tur in
## AIController), deci nu intra in apa fiindca a decis la turul 1.
## Compromisul pastrat: banda se inchide DOAR la apa mare (`closed_frac`), iar
## faza de telegraf si cea de retragere o lasa deschisa cu apa pe ea — adica
## riscul asumat rămâne posibil pe muchie.
##
## [b]Cum se declara in Track22.tscn[/b] (nod separat sub radacina pistei, NU
## prin HazardMarker):
##
##   [node name="Maree" type="Node3D" parent="."]
##   script = ExtResource("tide")
##   branch_index = 1
##   period = 80.0
##   span_m = 120.0
##
## [b]CEASUL PORNESTE IN TELEGRAF[/b] (memoria `ceasul-porneste-in-prima-faza`):
## la `t = 0` faza e TELEGRAF, nu „apa sus". Pe Fiordland, `RainCycle` la 0 era
## deja in ploaie si toate verdictele ProbeRace au ieşit cu ploaie de la start —
## adica se masura alta pista. `phase` implicit 0 cade anume la inceputul
## telegrafului, iar sonda `probe_maree` verifica asta explicit.

## Fazele ciclului, in ordine. Suma fractiilor = 1.
## JOS: terasa descoperita, scurtatura deschisa si uscata.
## URCA: apa vine, banda inca deschisa — ferestra de risc asumat.
## SUS: apa peste terasa, banda INCHISA.
## COBOARA: apa se retrage, banda se redeschide uda.
enum Phase {JOS, URCA, SUS, COBOARA}

## Perioada intregului ciclu (s). Brief §3: ~75-90 s, adica un tur intreg, ca
## decizia de pe belvedere sa fie despre TURUL ASTA.
@export_range(20.0, 200.0, 1.0) var period: float = 80.0
## Defazaj 0..1. Implicit 0 = ceasul porneste la inceputul TELEGRAFULUI (URCA),
## nu cu apa sus (vezi antetul).
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Cat din ciclu e fiecare faza. Se normalizeaza, deci nu trebuie sa dea exact 1.
@export_range(0.05, 0.6, 0.01) var low_frac: float = 0.34
@export_range(0.05, 0.4, 0.01) var rise_frac: float = 0.14
@export_range(0.05, 0.6, 0.01) var high_frac: float = 0.38
@export_range(0.05, 0.4, 0.01) var fall_frac: float = 0.14
## Indexul benzii secundare pe care o inchide (ordinea din Track.routes).
@export var branch_index: int = 1
## Lungimea benzii de jos (m): de atat are nevoie pelicula de apa ca sa acopere
## terasa, nu doar un petec de sosea. Se masoara pe scena, nu se ghiceste.
@export_range(10.0, 300.0, 1.0) var span_m: float = 120.0
## Latimea benzii de jos (m).
@export_range(3.0, 20.0, 0.5) var lane_width: float = 8.0
## Cat urca apa peste terasa la maree plina (m). Brief §1: mareea reala din
## golful Tonkin e 3-4 m; in joc e „scara e decizie" (§8) — 1.5 m e destul ca
## banda sa fie impracticabila si putin pentru ca pereţii sa nu para inundati.
@export_range(0.3, 4.0, 0.1) var rise_m: float = 1.5
## Plafonul de viteza prin apa, din plafonul NOMINAL al masinii (cererea
## dezvoltatorului, 26 nov 2026: „80% din viteza cat conduci prin apa"). Cu
## digul imprejmuit, alunecarea singura nu mai costa nimic — gardul te tine pe
## banda — deci banda inundata era aproape gratis. Taie si turbo-ul (vezi
## `Car._current_max_speed`).
##
## 0.70, nu 0.80, MASURAT (`ProbeMareeVad`): pe digul uscat masinile nu-si
## ating plafonul nominal (taxi 30.0 din 35 m/s, cu gaz tinut), deci un plafon
## de 0.80 (28 m/s) costa doar ~7%. Cu 0.70 viteza prin apa iese 81-82% din cea
## de pe uscat (taxi, buggy) si 87% la autobuz, care e oricum mai lent pe dig.
@export_range(0.3, 1.0, 0.05) var wade_speed_factor: float = 0.7

signal phase_changed(phase: Phase)

var _time: float = 0.0
var _phase: Phase = Phase.URCA
var _level: float = 0.0
var _film: MeshInstance3D
## Foaia a fost reconstruita PE BANDA (`fit_to_route`): mesh-ul are baza la
## cota marii (y = 0 local), deci se scaleaza de la baza, nu din centru.
var _film_on_route: bool = false


func _ready() -> void:
	super()
	# Grupul comun de „porti de banda" (Track.branch_is_open). Precedentul e
	# lava de pe Stromboli si vaca de la Jodhpur, deci grupul se ALATURA.
	add_to_group(Track.BRANCH_GATE_GROUP)


# ---------------------------------------------------------- contractul WaterHazard

## Apa acoperă toata banda de jos, nu un petec de sosea: de-aia `span_m` si
## `lane_width` sunt exporturi masurate pe scena, nu derivate din `road_width`
## (care e latimea drumului PRINCIPAL, irelevanta aici).
func _wet_patch_size() -> Vector3:
	return Vector3(lane_width, maxf(rise_m * 2.0, 2.0), span_m)


## Pelicula sta la cota curenta a apei, nu la cea a soselei: aici apa URCA, deci
## inaltimea e starea hazardului, nu o constanta. (La conducta sparta si la val,
## apa e mereu pe asfalt — de-aia implicitul e 0.06.)
func _wet_patch_offset() -> float:
	return 0.06


## Ceasul: rezolva faza lunga si nivelul apei. `true` cat timp banda e udata —
## adica in URCA, SUS si COBOARA (in JOS terasa e descoperita).
func _advance(delta: float) -> bool:
	_time += delta
	var sum := low_frac + rise_frac + high_frac + fall_frac
	var t := fposmod(_time / maxf(period, 0.1) + phase, 1.0) * sum
	# Ordinea e URCA -> SUS -> COBOARA -> JOS, ca `phase = 0` sa cada la
	# inceputul TELEGRAFULUI (vezi antetul: ceasul porneste in prima faza).
	var ph: Phase
	var level: float
	if t < rise_frac:
		ph = Phase.URCA
		level = t / rise_frac
	elif t < rise_frac + high_frac:
		ph = Phase.SUS
		level = 1.0
	elif t < rise_frac + high_frac + fall_frac:
		ph = Phase.COBOARA
		level = 1.0 - (t - rise_frac - high_frac) / fall_frac
	else:
		ph = Phase.JOS
		level = 0.0
	_level = level
	if ph != _phase:
		_phase = ph
		phase_changed.emit(ph)
	_update_film()
	return level > 0.02


## Pelicula urca si coboara cu apa.
##
## [b]SE INTINDE PE Y, NU SE MUTA[/b] — si asta a fost un defect real, nu o
## precizare de stil. Comentariul de dinainte spunea exact regula corecta ("se
## scaleaza pe Y in loc sa fie mutata, ca marginea sa rămână lipita de terasa:
## o foaie de apa care PLUTESTE la 1.5 m ar citi ca o placa de sticla"), dar
## codul de sub el facea `position.y = _level * rise_m`, adica tocmai mutarea pe
## care comentariul o interzicea. Nicaieri in fisier nu exista vreo scalare.
## Verdictul la volan: mareea "apare ca o banda albastra peste scurtatura" —
## adica se vedea exact placa plutitoare prezisa de propriul comentariu.
## (Memoria `justificarea-din-comentariu-se-verifica`: o justificare scrisa nu
## dovedeste ca e si implementata.)
##
## Forma corecta: marginea de JOS sta la nivelul marii si nu se mişca deloc,
## iar foaia CRESTE in sus pana la `rise_m`. Terasa e la 1.41-1.58 m peste
## mare, deci la nivel plin (1.5 m) apa o acopera, iar la nivel mic se vede
## lingand baza peretelui — ce face diferenţa intre "apa urca" si "o placa
## pluteste". De-aia mesh-ul e o CUTIE, nu un plan: un plan are grosime zero,
## deci nu poate avea o margine de jos care sa rămână pe loc.
func _update_film() -> void:
	if _film == null:
		_film = get_node_or_null("TideFilm") as MeshInstance3D
	if _film == null:
		return
	_film.visible = _level > 0.02
	if _level <= 0.02:
		return
	# Cutia e construita cu inaltimea `rise_m` si centrul la jumatatea ei (vezi
	# `_build_source`). O scalez pe Y cu nivelul si o cobor cu exact cat s-a
	# scurtat, ca fata de JOS sa rămână pe cota marii: centrul unei cutii scalate
	# la `k` sta la `k * rise_m / 2` peste baza, nu la `rise_m / 2`.
	var k := maxf(_level, 0.001)
	_film.scale.y = k
	if _film_on_route:
		# Mesh-ul are baza la y = 0, deci baza ramane pe mare la orice `k`.
		_film.position.y = _sea_offset_y()
	else:
		_film.position.y = _sea_offset_y() + k * rise_m * 0.5


## Cota marii in coordonatele LOCALE ale hazardului. Nodul `Maree` sta la 1.493
## in Track22 (pe terasa), iar marea e la 0.00 absolut, deci baza foii trebuie
## sa coboare cu inaltimea nodului. Se citeste din transformul propriu in loc sa
## fie o constanta, ca sa nu se rupa daca nodul se mută.
func _sea_offset_y() -> float:
	return -global_position.y


func _build_source() -> void:
	# Foaia de apa care urca. Materialul vine de la pista (`film_material` =
	# MATERIALUL MARII pe temele cu apa), deci nu costa niciun material in plus
	# — garda numara materialele per pista (CLAUDE.md).
	var mi := MeshInstance3D.new()
	mi.name = "TideFilm"
	# CUTIE, nu plan: foaia se intinde pe Y de la cota marii in sus (vezi
	# `_update_film`), si un plan cu grosime zero nu poate avea o margine de jos
	# care sa stea pe loc. Inaltimea e `rise_m`, deci scalarea pe Y e direct
	# nivelul mareei.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(lane_width, maxf(rise_m, 0.1), span_m)
	# Primitiva in cod: subdiviziunile se declara EXPLICIT (CLAUDE.md — un mesh
	# lasat la implicit sare cu zeci de mii de triunghiuri).
	mesh.subdivide_width = 1
	mesh.subdivide_height = 1
	mesh.subdivide_depth = 3
	mi.mesh = mesh
	if film_material != null:
		mi.material_override = film_material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	_film = mi


## Primeste materialul marii DUPA ce pista l-a construit (vezi
## `Track._wire_scene_water_hazards`): un nod declarat in .tscn nu trece prin
## `_build_wave`, deci n-ar avea de unde sa-l ia, si ar desena un albastru
## propriu — un material in plus la numaratoarea garzii.
func apply_film_material(mat: Material) -> void:
	if mat == null:
		return
	film_material = mat
	if _film == null:
		_film = get_node_or_null("TideFilm") as MeshInstance3D
	# Toate mesh-urile hazardului: foaia care urca (`TideFilm`) si balta pe care
	# o face `WaterHazard._build_wet_patch` in `_ready`. Amandoua trebuie sa fie
	# pe materialul marii, nu doar prima.
	for c in get_children():
		var mi := c as MeshInstance3D
		if mi != null:
			mi.material_override = mat


## Cat trece apa peste planul benzii la maree plina (m). Destul ca banda sa
## para acoperita, putin cat stalpii gardului (1,25 m) sa ramana in apa pana
## la genunchi, nu ingropati — se vede pe unde era drumul.
const ROUTE_FILM_OVER: float = 0.12
## Cat de IN INTERIORUL marginii benzii sta marginea foii (m). Apa ramane intre
## garduri, pe drum: o foaie mai lata decat banda iesea, pe portiunea de dig
## peste mare, ca o placa albastra ridicata la 1,7 m peste apa adevarata —
## exact „banda albastra peste scurtatura" din verdictul de la volan. Peretii
## laterali ai foii stau astfel sub marginea coborata a benzii, nevazuti.
const ROUTE_FILM_INSET: float = 0.3
## Adancimea apei pe dig la maree plina, in unitatile shaderului marii (alfa de
## vertex): mica, ca sa iasa jadul de langa mal, nu albastrul de larg.
const ROUTE_FILM_DEPTH: float = 0.3
## Pe cati metri de la capetele foii adancimea urca de la spuma la
## ROUTE_FILM_DEPTH.
const ROUTE_FILM_FADE: float = 10.0
## Cat sta pelicula de „banda uda" peste planul benzii (m).
const ROUTE_PUDDLE_LIFT: float = 0.05
## Cati metri de langa soseaua principala raman fara apa (capetele benzii stau
## pe axa soselei: apa de pe banda nu trebuie sa curga peste asfaltul buclei).
const ROUTE_ROAD_CLEAR: float = 1.0
## Lungimea unei cutii din zona de pe banda (m) si inaltimea ei: de la 0.5 m sub
## banda pana peste apa plina si acoperisul masinii.
const ZONE_SEG_M: float = 8.0
const ZONE_HEIGHT: float = 4.0


## Muleaza apa pe banda REALA, pe care o construieste pista (`Track.routes`).
##
## De ce: foaia si pelicula erau o cutie si o elipsa DREPTE, pe coarda benzii
## (`span_m` x `lane_width`), cu nodul pus la mijlocul ei. Banda e insa o curba:
## capetele ei stau la ~6 m lateral de coarda. Cat timp banda era ingropata sub
## nisipul platoului (masurat, nov 2026: terenul la 1,65-1,88 m, banda la
## 1,43-1,53), nici apa nu se vedea, deci nepotrivirea nu se vedea nici ea. De
## cand banda e un dig de pamant deasupra platoului, apa dreapta iesea pe
## langa drum, peste nisip.
##
## Contractul foii ramane acelasi (sonda `probe_maree`, garda 7): baza pe cota
## marii la orice nivel, marginea de sus urca cu nivelul. Doar amprenta se
## schimba: o panglica pe banda, intre garduri, cu pereti laterali pana la mare.
##
## Zona care te prinde (`_zone`: alunecare + plafon de viteza) urmeaza si ea
## banda, din 26 nov 2026 (vezi `_fit_zone`): de cand apa te si franeaza,
## nepotrivirea dintre ce vezi si ce te prinde nu mai e un detaliu.
func fit_to_route(track: Node3D) -> void:
	var routes: Array = track.get("routes")
	if routes == null or branch_index >= routes.size():
		return
	var r = routes[branch_index]
	var main = routes[0]
	var n: int = r.count()
	if n < 3:
		return
	# Punctele benzii care NU stau pe soseaua principala: capetele benzii sunt
	# pe axa buclei, iar apa nu trebuie sa curga peste asfalt.
	var keep: Array[int] = []
	for i in n:
		var g: Vector3 = track.to_global(r.baked[i])
		var mi: int = main.closest_index_global(r.baked[i])
		if main.lateral_distance(mi, r.baked[i]) 				> float(track.call("width_at_index", mi)) + r.half_width * 0.5 				+ ROUTE_ROAD_CLEAR:
			keep.append(i)
	if keep.size() < 3:
		return
	_fit_zone(track, r, keep)
	var hw: float = r.half_width - ROUTE_FILM_INSET
	var phw: float = r.half_width - ROUTE_FILM_INSET
	var film := SurfaceTool.new()
	film.begin(Mesh.PRIMITIVE_TRIANGLES)
	var puddle := SurfaceTool.new()
	puddle.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shallow := Color(0.30, 0.55, 0.90, FILM_DEPTH)
	# Adancimea foii (alfa = contractul shaderului marii): de la `FILM_DEPTH`
	# la capete (nisip ud cu spuma, deci capatul taiat drept nu se vede ca o
	# muchie) la ROUTE_FILM_DEPTH pe ROUTE_FILM_FADE metri. Apa de pe dig e mica:
	# cu adancime 1 iesea albastrul de larg, nu jadul de langa mal.
	var d_first: float = r.dists[keep[0]]
	var d_last: float = r.dists[keep[keep.size() - 1]]
	var prev: Array = []
	for i: int in keep:
		var c: Vector3 = track.to_global(r.baked[i])
		var side: Vector3 = (track.global_transform.basis * r.side_at(i)).normalized()
		var top_y: float = c.y + ROUTE_FILM_OVER
		var from_end: float = minf(r.dists[i] - d_first, d_last - r.dists[i])
		var col := Color(0.30, 0.55, 0.90, lerpf(FILM_DEPTH, ROUTE_FILM_DEPTH,
			smoothstep(0.0, ROUTE_FILM_FADE, from_end)))
		var row := [
			_local_at(c - side * hw, top_y), _local_at(c + side * hw, top_y),
			_local_at(c - side * hw, 0.0), _local_at(c + side * hw, 0.0),
			to_local(c - side * phw + Vector3.UP * ROUTE_PUDDLE_LIFT),
			to_local(c + side * phw + Vector3.UP * ROUTE_PUDDLE_LIFT),
		]
		if not prev.is_empty() and i == int(prev[6]) + 1:
			# Fata de sus (in sus), apoi peretii laterali (spre exterior).
			# Shaderul marii e `cull_back`: winding-ul decide daca se vede.
			var out_l: Vector3 = row[0] - row[1]
			out_l.y = 0.0
			out_l = out_l.normalized()
			var pc: Color = prev[7]
			_quad(film, prev[0], row[0], prev[1], row[1], Vector3.UP, pc, col)
			_quad(film, prev[2], row[2], prev[0], row[0], out_l, pc, col)
			_quad(film, prev[1], row[1], prev[3], row[3], -out_l, pc, col)
			_quad(puddle, prev[4], row[4], prev[5], row[5], Vector3.UP,
				shallow, shallow)
		row.append(i)
		row.append(col)
		prev = row
	var film_mesh := film.commit()
	var puddle_mesh := puddle.commit()
	if film_mesh.get_surface_count() == 0:
		return
	if _film == null:
		_film = get_node_or_null("TideFilm") as MeshInstance3D
	if _film != null:
		_film.mesh = film_mesh
		_film.position = Vector3.ZERO
		_film_on_route = true
	if _puddle != null and puddle_mesh.get_surface_count() > 0:
		_puddle.mesh = puddle_mesh
		_puddle.position = Vector3.ZERO
	_update_film()


## Zona care te prinde (alunecare + plafon) pe banda REALA, nu pe coarda.
##
## Cutia veche statea pe coarda dreapta dintre capete, iar banda se arcuieste
## ~6 m in afara ei: la capete erai in apa cu aderenta plina, sau iti taia
## aderenta pe uscat. Pe un hazard de timing, ce vezi trebuie sa fie ce te
## prinde (vezi `WaterHazard._build_wet_patch`) — deci zona urmeaza aceleasi
## puncte ca foaia: o cutie la ~`ZONE_SEG_M` metri, latimea intreaga a benzii.
func _fit_zone(track: Node3D, r, keep: Array[int]) -> void:
	if _zone == null:
		return
	for c in _zone.get_children():
		_zone.remove_child(c)
		c.queue_free()
	var inv := global_transform.affine_inverse()
	var i0: int = keep[0]
	var prev: int = keep[0]
	for k in range(1, keep.size()):
		var i: int = keep[k]
		var gap: bool = i != prev + 1
		var last: bool = k == keep.size() - 1
		var end_i: int = prev if gap else i
		if gap or last or r.dists[i] - r.dists[i0] >= ZONE_SEG_M:
			_add_zone_box(track, r, i0, end_i, inv)
			i0 = i if gap else end_i
		prev = i


func _add_zone_box(track: Node3D, r, i0: int, i1: int, inv: Transform3D) -> void:
	if i1 <= i0:
		return
	var a: Vector3 = track.to_global(r.baked[i0])
	var b: Vector3 = track.to_global(r.baked[i1])
	var fwd := b - a
	fwd.y = 0.0
	if fwd.length() < 0.1:
		return
	var box := BoxShape3D.new()
	# +1 m pe lungime: cutiile vecine se suprapun, ca un viraj sa nu lase
	# o pana uscata intre ele.
	box.size = Vector3(r.half_width * 2.0, ZONE_HEIGHT, fwd.length() + 1.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	# Ca la `_build_wet_patch`: cutia incepe cu o jumatate de metru sub banda.
	var center := (a + b) * 0.5 + Vector3.UP * (ZONE_HEIGHT * 0.5 - 0.5)
	shape.transform = inv * Transform3D(
		Basis.looking_at(fwd.normalized(), Vector3.UP), center)
	_zone.add_child(shape)


## Un punct de lume in coordonatele foii, cu cota data fata de MARE (y = 0 pe
## cota marii), cum o cere scalarea de la baza din `_update_film`.
func _local_at(p: Vector3, y_over_sea: float) -> Vector3:
	var l := to_local(p)
	l.y = y_over_sea
	return l


## Un patrulater (a0 a1 b0 b1, a = randul precedent) cu fata spre `want`.
##
## Winding-ul se ALEGE, nu se presupune: semnul lui `side_at` depinde de sensul
## in care a fost desenata banda, iar shaderul marii e `cull_back`, deci o fata
## intoarsa ar fi apa invizibila exact din masina. Fata din fata in Godot e cea
## cu varfurile in sensul acelor de ceas, adica normala (c - a) x (b - a).
## `c0` = culoarea randului precedent (a0, b0), `c1` = a randului curent.
static func _quad(st: SurfaceTool, a0: Vector3, a1: Vector3, b0: Vector3,
		b1: Vector3, want: Vector3, c0: Color, c1: Color) -> void:
	_tri(st, [a0, a1, b0], [c0, c1, c0], want)
	_tri(st, [b0, a1, b1], [c0, c1, c1], want)


static func _tri(st: SurfaceTool, v: Array, c: Array, want: Vector3) -> void:
	var a: Vector3 = v[0]
	var b: Vector3 = v[1]
	var d: Vector3 = v[2]
	var order := [0, 1, 2]
	if (d - a).cross(b - a).dot(want) < 0.0:
		order = [0, 2, 1]
	for k: int in order:
		st.set_color(c[k])
		st.set_normal(want)
		st.add_vertex(v[k])


## Apa de maree taie grip-ul si te tine in loc (plafon la `wade_speed_factor`),
## dar NU imbranceste: nu e un val care trece, e o foaie care sta. (Valul de pe
## Okinawa impinge — vezi `WaveSurge._touch_car`.)
func _touch_car(car: Car, _delta: float) -> void:
	car.apply_slip()
	car.apply_wade(wade_speed_factor)


# ---------------------------------------------------------- poarta de banda

## Contractul cu `Track.branch_is_open`: banda de jos e deschisa in toate fazele
## IN AFARA de apa plina.
##
## Faza URCA si faza COBOARA o lasa deschisa CU APA PE EA, deliberat: acolo sta
## riscul asumat (brief §3.1.3 — „decizie, nu taxa"). Doar SUS o inchide.
func shortcut_open() -> bool:
	return _phase != Phase.SUS


# ---------------------------------------------------------- pentru sonde

func tide_phase() -> Phase:
	return _phase


func tide_level() -> float:
	return _level


func water_y_offset() -> float:
	return _level * rise_m


## Faza la un moment dat, fara sa avansezi ceasul (sonde, capturi).
func phase_at(t: float) -> Phase:
	var sum := low_frac + rise_frac + high_frac + fall_frac
	var u := fposmod(t / maxf(period, 0.1) + phase, 1.0) * sum
	if u < rise_frac:
		return Phase.URCA
	if u < rise_frac + high_frac:
		return Phase.SUS
	if u < rise_frac + high_frac + fall_frac:
		return Phase.COBOARA
	return Phase.JOS


## Cat timp (s) rămâne banda inchisa per ciclu, si cat e deschisa. Contractul
## gimmickului se verifica pe cifrele astea, nu pe senzatie.
func closed_seconds() -> float:
	var sum := low_frac + rise_frac + high_frac + fall_frac
	return period * high_frac / sum


func open_seconds() -> float:
	return period - closed_seconds()


func set_clock(t: float) -> void:
	_time = t
