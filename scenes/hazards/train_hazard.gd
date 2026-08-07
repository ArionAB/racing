@tool
class_name TrainHazard
extends Node3D
## Tren de marfa care taie soseaua la interval fix. Contactul te scoate din cursa
## pentru cateva secunde.
##
## Gimmick-ul e de TIMING, nu de reflexe: linia, barierele si clopotul spun de
## departe daca prinzi trecerea sau nu. Perioada e lunga (26 s la un tur de ~50)
## tocmai ca decizia "fortez sau ridic piciorul" sa apara o data sau de doua ori
## pe tur, nu la fiecare viraj.
##
## Ce inseamna "explodezi", mecanic: nu exista stare de distrus in joc. Trenul
## te turteste complet, iti taie comenzile cat te arunca fizic, apoi te repune.
## Corpul solid face aruncarea — aia E explozia vizuala — iar repunerea
## temporizata garanteaza ca nimeni nu ramane blocat sub tren.
##
## Garnitura e un MODEL (`assets/models/vehicles/train.glb`: locomotiva cu abur, tender,
## vagoane de lemn), nu cutiile din spike. Conteaza pentru gimmick, nu doar
## pentru poza: avertizarea vizuala e silueta care intra in cadru, iar o cutie
## nu spune de la 100 m nici incotro merge, nici cat mai are de trecut. Cotele
## si coliziunile ies din AABB-ul modelului — vezi `_build_model_consist`.

## Cat dureaza un ciclu complet.
const DEFAULT_PERIOD: float = 26.0
## Avertizarea, inainte sa intre trenul in cadru.
const WARN: float = 4.5
## Cat dureaza traversarea.
const CROSS: float = 6.9
## Viteza trenului.
const SPEED: float = 26.0
## Cat de des bate clopotul in timpul avertizarii.
const BELL_INTERVAL: float = 0.6
## Cand suna cornul, masurat de la inceputul ciclului.
const HORN_AT: float = 0.4

## Garnitura: locomotiva cu abur + tender + vagoane de marfa.
## Trei noduri in GLB, vezi tools/blender/build_train.py.
const MODEL_PATH := "res://assets/models/vehicles/train.glb"
const LOCO_NODE := "Train_Loco"
const TENDER_NODE := "Train_Tender"
const WAGON_NODE := "Train_Wagon"

## Cutiile de rezerva, cand modelul lipseste: lungime, latime, inaltime.
const WAGON_LEN: float = 7.0
const WAGON_WIDTH: float = 3.0
const WAGON_HEIGHT: float = 3.4
## Cate vagoane trage locomotiva.
const WAGON_COUNT: int = 3
## Spatiul dintre piese, masurat intre capete.
const WAGON_GAP: float = 1.2

## Ecartamentul: distanta de la axa sinei la firul de sina. NU e o alegere, e o
## masuratoare pe model — rotile stau la |z| = 0.45 (build_train.py). Terasamentul
## avea 0.75, adica trenul ar fi mers cu rotile intre sine, in aer.
const GAUGE_HALF: float = 0.45
## Cota superioara a sinei. Pe ea sta baza modelului (originea lui e la roti).
const RAIL_TOP: float = 0.28
## Lungimea traversei si pasul dintre ele. Traversa iese ~0.3 m de fiecare parte
## a firului de sina, ca la orice cale ferata de macheta.
const SLEEPER_LEN: float = 1.5
const SLEEPER_STEP: float = 1.8

# --------------------------------------------------------------- estacada
#
# Calea ferata era PLATA, la cota drumului, oriunde ar fi fost pusa. Pe Dunele
# asta insemna ca linia trece la 17 m deasupra fundului rapei fara nimic
# dedesubt: o panglica de traverse plutind in aer. Momentul-semnatura al pistei
# din conceptul „Canyon Circuit" (#152) e exact opusul — trenul traverseaza
# prapastia pe un POD DE LEMN, si il vezi de jos in sus cand ratezi aterizarea.
#
# Structura e procedurala, in acelasi SurfaceTool si cu acelasi material ca
# terasamentul, DELIBERAT si nu din comoditate. Issue-ul propunea un GLB nou
# (`train_trestle.glb`), dar sina pe care se sprijina e deja procedurala aici:
# un asset separat ar fi insemnat doua definitii ale aceleiasi geometrii care
# pot diverge la prima schimbare de ecartament, plus inca un material intr-o
# garda unde Dunele e cazul strans. Palei de lemn sunt cutii — nu e clasa de
# geometrie care sa ceara Blender.

## Sub atat, linia sta pur si simplu pe pamant: nu se ridica nimic.
const TRESTLE_MIN_DROP: float = 1.6
## Pasul dintre palei. Multiplu de SLEEPER_STEP ca sa cada mereu sub o traversa.
const TRESTLE_BENT_STEP: float = SLEEPER_STEP * 4.0
## Deschiderea palei la varf si cat se departeaza picioarele la fiecare metru de
## inaltime. Bataia (batter-ul) nu e ornament: o pala inalta cu picioare
## verticale citeste ca doi tepusi, una evazata citeste ca structura care duce
## greutate.
const TRESTLE_TOP_HALF: float = 0.85
const TRESTLE_BATTER: float = 0.13
## Grosimea grinzilor. Style_bible §3 cere minime — sub ~14 cm, la 60 km/h si pe
## un ecran de telefon, o grinda dispare si structura pare desenata cu creionul.
const TRESTLE_LEG: float = 0.26
const TRESTLE_BRACE: float = 0.17
## Cat de des se pune o cruce de contravantuire pe inaltime.
const TRESTLE_BRACE_SPAN: float = 4.5
## Cat de adanc intra piciorul in pamant, ca sa nu se vada talpa plutind pe o
## panta esantionata mai rar decat geometria.
const TRESTLE_FOOT_SINK: float = 0.5

## Cat sta o masina imuna dupa ce a fost lovita — mai lung decat la bolovan,
## fiindca urmeaza o repunere si n-are rost sa fie lovita de doua ori.
const HIT_COOLDOWN: float = 2.0
## Cat tine masina fara comenzi, cat o arunca trenul.
const STUN_SECONDS: float = 0.9
## Cat de departe in spate te repune. Mai mult decat implicitul de 14 m: trenul
## inca trece, iar o repunere prea aproape te-ar pune inapoi sub el.
const RESPAWN_BACKOFF: float = 20.0

@export var period: float = DEFAULT_PERIOD
## Lungimea sinei de fiecare parte a soselei. Se scurteaza automat daca ar da
## peste alta bucla a pistei — vezi Track._build_train.
@export var half_rail: float = 90.0
## Latimea soselei in punctul de trecere, pentru bariere.
@export var road_half_width: float = 7.0
## Cota terenului sub sina, in coordonate LOCALE (0 = nivelul traverselor),
## esantionata din TRESTLE_BENT_STEP in TRESTLE_BENT_STEP de la -half_rail la
## +half_rail. Goala = teren plat, deci fara estacada.
##
## Vine de la Track, nu se citeste de aici: hazardul e o scena de sine
## statatoare si n-are cum sa cunoasca samplerul pistei. Track are deja singura
## sursa de adevar pentru cotele terenului (TrackSideSampler.ground_y) si o
## esantioneaza in Track._build_train.
@export var ground_drop: PackedFloat32Array = PackedFloat32Array()

var _train: AnimatableBody3D
var _hit: Area3D
var _audio: AudioStreamPlayer3D
var _gate_lights: Array[MeshInstance3D] = []
var _time: float = 0.0
var _last_bell: int = -1
var _horn_done: bool = false
var _cooldown: Dictionary = {}
## Lungimea totala a garniturii, pentru pozitionare.
var _train_len: float = 0.0

## Materiale STATICE, partajate. Terasamentul si stalpii folosesc acelasi
## material de structura: sunt amandoua "beton si lemn vechi" si nimeni nu vede
## diferenta la 60 km/h, dar garda de draw call-uri o vede.
static var _struct_mat: StandardMaterial3D
static var _body_mat: StandardMaterial3D
static var _light_mat: StandardMaterial3D


func _ready() -> void:
	_build()


func _build() -> void:
	_build_bed()
	_build_gates()
	_build_train()
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 140.0
	add_child(_audio)


## Terasamentul: doua sine si traverse. Local, X e de-a lungul sinei si Z de-a
## lungul soselei — nodul e rotit de Track la asezare.
func _build_bed() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sleepers := int(half_rail * 2.0 / SLEEPER_STEP)
	for i in sleepers:
		var x := -half_rail + float(i) * SLEEPER_STEP
		_box(st, Vector3(x, 0.06, 0.0), Vector3(0.8, 0.12, SLEEPER_LEN))
	for side: float in [-1.0, 1.0]:
		_box(st, Vector3(0.0, RAIL_TOP - 0.08, side * GAUGE_HALF),
			Vector3(half_rail * 2.0, 0.16, 0.16))
	_build_trestle(st)
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	# Refolosim sloturi din paleta, nu culori noi: hazardele procedurale intra in
	# raportul mesh-uri/material din garda, iar Dunele e cazul strans.
	inst.material_override = _structure_material()
	add_child(inst)


## Estacada: palei de lemn acolo unde terenul fuge de sub linie.
##
## O pala ("bent", in vocabularul podurilor de lemn) = doua picioare evazate, o
## grinda de cap peste ele si cruci de contravantuire la fiecare
## TRESTLE_BRACE_SPAN de inaltime. Peste deschideri se pune si o LONJERONA
## continua sub traverse: fara ea traversele plutesc una langa alta si podul
## citeste ca o scara suspendata, nu ca un pod.
func _build_trestle(st: SurfaceTool) -> void:
	if ground_drop.size() < 2:
		return
	var bents := ground_drop.size()
	# Lonjeronele se pun pe intervalele DINTRE doua palei ridicate, deci se
	# acumuleaza pe parcurs si se emit cand seria se intrerupe.
	var run_start := INF
	var run_end := -INF
	for i in bents:
		var x := -half_rail + float(i) * TRESTLE_BENT_STEP
		var drop := ground_drop[i]
		if drop < TRESTLE_MIN_DROP:
			if run_start < run_end:
				_trestle_stringers(st, run_start, run_end)
			run_start = INF
			run_end = -INF
			continue
		_trestle_bent(st, x, drop)
		run_start = minf(run_start, x)
		run_end = maxf(run_end, x)
	if run_start < run_end:
		_trestle_stringers(st, run_start, run_end)


## O pala, cu varful sub traverse si talpa pe teren.
func _trestle_bent(st: SurfaceTool, x: float, drop: float) -> void:
	var top := -0.02
	var foot := -drop - TRESTLE_FOOT_SINK
	var bottom_half := TRESTLE_TOP_HALF + drop * TRESTLE_BATTER
	# Grinda de cap: sta SUB traverse si peste amandoua picioarele, deci trebuie
	# sa fie mai lata decat deschiderea de la varf.
	_box(st, Vector3(x, top - 0.13, 0.0),
		Vector3(0.5, 0.26, TRESTLE_TOP_HALF * 2.0 + TRESTLE_LEG))
	for side: float in [-1.0, 1.0]:
		_beam(st,
			Vector3(x, top - 0.26, side * TRESTLE_TOP_HALF),
			Vector3(x, foot, side * bottom_half),
			TRESTLE_LEG)
	# Crucile: pe fiecare palier, doua diagonale intre picioarele evazate.
	# Interpolarea le tine LIPITE de picioare pe toata inaltimea — calculate pe
	# deschiderea de la varf, ar iesi in aer la baza si structura ar arata rupta.
	var levels := maxi(1, int(drop / TRESTLE_BRACE_SPAN))
	for k in levels:
		var t0 := float(k) / float(levels)
		var t1 := float(k + 1) / float(levels)
		var y0 := lerpf(top - 0.26, foot, t0)
		var y1 := lerpf(top - 0.26, foot, t1)
		var h0 := lerpf(TRESTLE_TOP_HALF, bottom_half, t0)
		var h1 := lerpf(TRESTLE_TOP_HALF, bottom_half, t1)
		_beam(st, Vector3(x, y0, -h0), Vector3(x, y1, h1), TRESTLE_BRACE)
		_beam(st, Vector3(x, y0, h0), Vector3(x, y1, -h1), TRESTLE_BRACE)
		# Traversa orizontala la fiecare palier: leaga crucile si da podului
		# liniile orizontale repetate care il fac citibil de departe.
		if k > 0:
			_box(st, Vector3(x, y0, 0.0), Vector3(0.2, TRESTLE_BRACE, h0 * 2.0))


## Lonjeronele continue de sub traverse, pe o deschidere.
func _trestle_stringers(st: SurfaceTool, from_x: float, to_x: float) -> void:
	var span := to_x - from_x + TRESTLE_BENT_STEP
	var mid := (from_x + to_x) * 0.5
	for side: float in [-1.0, 1.0]:
		_box(st, Vector3(mid, -0.16, side * GAUGE_HALF),
			Vector3(span, 0.3, 0.24))


## Cutie orientata intre doua puncte — grinda inclinata, cu secventa patrata.
##
## `_box` face doar cutii aliniate pe axe, si ala e chiar rostul lui (traverse,
## sine). O estacada n-are nicio grinda aliniata: picioarele sunt evazate si
## contravantuirile sunt diagonale prin definitie. Fara asta ar fi trebuit ori
## picioare verticale (care citesc ca tepuse, nu ca structura), ori un GLB.
func _beam(st: SurfaceTool, from: Vector3, to: Vector3, thick: float) -> void:
	var axis := to - from
	var len_sq := axis.length_squared()
	if len_sq < 1e-6:
		return
	var dir := axis / sqrt(len_sq)
	# Referinta pentru primul perpendicular: axa cea mai putin paralela cu grinda,
	# ca produsul vectorial sa nu degenereze pe o grinda verticala.
	var ref := Vector3.RIGHT if absf(dir.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var u := dir.cross(ref).normalized() * (thick * 0.5)
	var v := dir.cross(u).normalized() * (thick * 0.5)
	var c := [
		from - u - v, from + u - v, from + u + v, from - u + v,
		to - u - v, to + u - v, to + u + v, to - u + v,
	]
	const FACES := [
		[4, 5, 6, 7], [1, 0, 3, 2], [0, 1, 5, 4],
		[2, 3, 7, 6], [3, 0, 4, 7], [1, 2, 6, 5],
	]
	for f: Array in FACES:
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[1]]); st.add_vertex(c[f[2]])
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[2]]); st.add_vertex(c[f[3]])


## Barierele de trecere la nivel, de o parte si de alta a soselei. Lumina lor
## clipeste in timpul avertizarii — singurul semnal pe care il vezi din masina
## inainte sa apara trenul.
func _build_gates() -> void:
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 3.2, 0.22)
		post.mesh = mesh
		post.position = Vector3(side * 3.4, 1.6, (road_half_width + 2.2) * side)
		post.material_override = _structure_material()
		add_child(post)

		var light := MeshInstance3D.new()
		var bulb := SphereMesh.new()
		bulb.radius = 0.34
		bulb.height = 0.68
		bulb.radial_segments = 8
		bulb.rings = 4
		light.mesh = bulb
		light.position = post.position + Vector3.UP * 1.8
		if _light_mat == null:
			_light_mat = StandardMaterial3D.new()
			_light_mat.albedo_color = Color(0.85, 0.15, 0.1)
			# UNSHADED: un bec trebuie sa se vada aprins si cand e in umbra.
			_light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		light.material_override = _light_mat
		add_child(light)
		_gate_lights.append(light)


## Terasament si stalpi: acelasi material.
static func _structure_material() -> StandardMaterial3D:
	if _struct_mat == null:
		_struct_mat = StandardMaterial3D.new()
		_struct_mat.albedo_color = Palette.color(Palette.WOOD_WEATHERED)
		_struct_mat.roughness = 0.9
	return _struct_mat


## Garnitura se construieste dinspre COADA (x = 0) spre bot: vagoanele intai,
## locomotiva ultima, la x maxim. Ordinea nu e cosmetica — trenul inainteaza
## spre +X local, deci piesa cu x maxim e cea care intra prima in cadru. Pe
## cutii identice nu se vedea; cu o locomotiva adevarata, inversul inseamna un
## tren care traverseaza cu spatele.
func _build_train() -> void:
	_train = AnimatableBody3D.new()
	_train.sync_to_physics = true
	add_child(_train)
	var gabarit := _build_model_consist()
	if gabarit == Vector2.ZERO:
		gabarit = _build_box_consist()

	_hit = Area3D.new()
	var hit_shape := CollisionShape3D.new()
	var hit_box := BoxShape3D.new()
	# Cu un metru mai gras decat vagoanele: lovitura se simte cand trenul te
	# atinge, nu cand a intrat deja jumatate in tine.
	hit_box.size = Vector3(_train_len, gabarit.x + 1.0, gabarit.y + 1.0)
	hit_shape.shape = hit_box
	hit_shape.position = Vector3(_train_len * 0.5, gabarit.x * 0.5, 0.0)
	_hit.add_child(hit_shape)
	_train.add_child(_hit)


## Asaza modelul, piesa cu piesa. Intoarce (inaltime, latime) maxime ale
## garniturii, sau Vector2.ZERO daca modelul lipseste.
##
## Cotele NU se scriu de mana nicaieri: lungimea fiecarei piese, coliziunea ei si
## gabaritul zonei de lovire ies din AABB-ul masurat pe mesh (ca la landmark-uri,
## track.gd:_LANDMARKS). Regenerezi GLB-ul cu alte proportii si totul urmeaza.
func _build_model_consist() -> Vector2:
	if not ResourceLoader.exists(MODEL_PATH):
		return Vector2.ZERO
	var scene := load(MODEL_PATH) as PackedScene
	var order: Array[String] = []
	for i in WAGON_COUNT:
		order.append(WAGON_NODE)
	order.append(TENDER_NODE)
	order.append(LOCO_NODE)

	var x := 0.0
	var gabarit := Vector2.ZERO
	for part in order:
		var piece := _extract(scene, part)
		if piece == null:
			# Un GLB incomplet nu se acopera pe jumatate: mai bine cade tot pe
			# cutii decat sa iasa o garnitura cu goluri in ea.
			for child in _train.get_children():
				_train.remove_child(child)
				child.queue_free()
			return Vector2.ZERO
		# AABB-ul se ia pe piesa asa cum vine din GLB (cu offsetul ei intern deja
		# anulat), iar asezarea se face pe un nod-suport: daca am scrie direct in
		# `piece.position` am sterge exact corectia pe care `_extract` a facut-o.
		var box := Track.model_aabb(piece)
		var holder := Node3D.new()
		holder.add_child(piece)
		# Capatul din coada al piesei ajunge fix la x; originea modelului e in
		# centrul lui pe orizontala, deci offsetul se scade din AABB, nu se
		# presupune.
		holder.position = Vector3(x - box.position.x, RAIL_TOP, 0.0)
		_train.add_child(holder)
		Palette.apply_world_material(piece)

		var shape := CollisionShape3D.new()
		var col := BoxShape3D.new()
		col.size = box.size
		shape.shape = col
		shape.position = holder.position + box.position + box.size * 0.5
		_train.add_child(shape)

		x += box.size.x + WAGON_GAP
		gabarit = Vector2(maxf(gabarit.x, RAIL_TOP + box.size.y),
			maxf(gabarit.y, box.size.z))
	_train_len = x - WAGON_GAP
	return gabarit


## Instantiaza GLB-ul si pastreaza un singur nod, anuland offsetul lui din
## fisier. Acelasi tipar ca `Track._extract_glb_node`, copiat fiindca acolo e
## metoda de instanta a pistei; `Track.model_aabb` e static, deci ala se
## refoloseste (ca in sliding_hazard).
##
## `remove_child` INAINTE de `queue_free`: eliberarea e amanata pana la finalul
## cadrului, iar `model_aabb` masoara imediat dupa — altfel piesele "sterse" ar
## intra in masuratoare si fiecare vagon ar primi cutia intregii garnituri.
func _extract(scene: PackedScene, node_name: String) -> Node3D:
	var container := scene.instantiate() as Node3D
	var kept: Node3D = null
	for child in container.get_children():
		if String(child.name) == node_name:
			kept = child as Node3D
		else:
			container.remove_child(child)
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


## Rezerva pe cutii, pentru cand assets-ul lipseste (clona proaspata, inainte de
## primul import). Pista nu ramane fara gimmick din cauza unui fisier.
func _build_box_consist() -> Vector2:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in WAGON_COUNT + 1:
		# Centrul cutiei, cu coada primei piese fix la x = 0 — aceeasi conventie
		# ca pe model, ca zona de lovire sa cada la fel pe amandoua drumurile.
		var x := float(i) * (WAGON_LEN + WAGON_GAP) + WAGON_LEN * 0.5
		var h := WAGON_HEIGHT if i < WAGON_COUNT else WAGON_HEIGHT + 0.7
		_box(st, Vector3(x, h * 0.5 + 0.5, 0.0),
			Vector3(WAGON_LEN, h, WAGON_WIDTH))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(WAGON_LEN, h, WAGON_WIDTH)
		shape.shape = box
		shape.position = Vector3(x, h * 0.5 + 0.5, 0.0)
		_train.add_child(shape)
	st.generate_normals()
	var inst := MeshInstance3D.new()
	inst.mesh = st.commit()
	if _body_mat == null:
		_body_mat = StandardMaterial3D.new()
		_body_mat.albedo_color = Palette.color(Palette.RUST_METAL)
		_body_mat.roughness = 0.8
	inst.material_override = _body_mat
	_train.add_child(inst)
	_train_len = float(WAGON_COUNT + 1) * WAGON_LEN \
		+ float(WAGON_COUNT) * WAGON_GAP
	return Vector2(WAGON_HEIGHT + 0.7 + 0.5, WAGON_WIDTH)


## O cutie in SurfaceTool. Doua triunghiuri per fata, fara indexare.
func _box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var c := [
		center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z), center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z), center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z),
	]
	const FACES := [
		[4, 5, 6, 7], [1, 0, 3, 2], [0, 1, 5, 4],
		[2, 3, 7, 6], [3, 0, 4, 7], [1, 2, 6, 5],
	]
	for f: Array in FACES:
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[1]]); st.add_vertex(c[f[2]])
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[2]]); st.add_vertex(c[f[3]])


func _physics_process(delta: float) -> void:
	if _train == null:
		return
	_time = fposmod(_time + delta, period)
	var warning := _time < WARN
	var crossing := _time >= WARN and _time < WARN + CROSS

	# Luminile clipesc doar in avertizare; in rest sunt stinse, ca sa nu obisnuiesti
	# ochiul cu ele si sa nu le mai vezi cand conteaza.
	var blink := warning and fmod(_time, 0.5) < 0.25
	for light in _gate_lights:
		var m := light.material_override as StandardMaterial3D
		m.albedo_color = Color(1.0, 0.25, 0.15) if blink \
			else Color(0.28, 0.06, 0.05)

	if crossing:
		var k := (_time - WARN) / CROSS
		# Traverseaza de la un capat la altul al sinei, cu garnitura cu tot.
		var span := half_rail * 2.0 + _train_len
		_train.position.x = -half_rail - _train_len + span * k
		_train.visible = true
	else:
		# Parcat departe, cu coliziunea inactiva prin distanta. Mai simplu si mai
		# sigur decat sa comutam disabled pe cinci forme in fiecare cadru.
		_train.position.x = -half_rail - _train_len * 3.0
		_train.visible = false

	if Engine.is_editor_hint():
		return
	_tick_audio()
	_tick_cooldowns(delta)
	if crossing:
		_hit_cars()


func _tick_audio() -> void:
	if _time < WARN:
		if not _horn_done and _time >= HORN_AT:
			_horn_done = true
			_play(&"train_horn")
		var bell := int(_time / BELL_INTERVAL)
		if bell != _last_bell:
			_last_bell = bell
			_play(&"crossing_bell")
	else:
		_horn_done = _time < WARN + CROSS
		_last_bell = -1


func _play(sfx: StringName) -> void:
	var stream := AudioManager.stream(sfx)
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


func _tick_cooldowns(delta: float) -> void:
	for car: Car in _cooldown.keys():
		var left: float = float(_cooldown[car]) - delta
		if left <= 0.0:
			_cooldown.erase(car)
		else:
			_cooldown[car] = left


func _hit_cars() -> void:
	for body in _hit.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car):
			continue
		# Doar la TRECEREA propriu-zisa. Sina e dreapta, soseaua e curba, deci pe
		# o pista care se intoarce in ea insasi linia poate trece a doua oara pe
		# langa asfalt — fara bariere, fara clopot, fara nicio avertizare. Acolo
		# trenul n-are voie sa loveasca: ar fi o moarte din senin.
		if absf(to_local(car.global_position).x) > road_half_width + 10.0:
			continue
		_cooldown[car] = HIT_COOLDOWN
		# Turtit complet si oprit. Corpul solid al trenului o arunca in
		# continuare cat tine stun-ul — aia e "explozia".
		car.crush(0.0, 1.0, Vector3(1.6, 0.25, 1.4), 0.0)
		car.race_active = false
		var hit_car := car
		get_tree().create_timer(STUN_SECONDS, false).timeout.connect(
			func() -> void:
				if not is_instance_valid(hit_car):
					return
				hit_car.race_active = true
				hit_car.respawn(RESPAWN_BACKOFF))
