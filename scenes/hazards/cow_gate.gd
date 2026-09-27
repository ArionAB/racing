@tool
class_name CowGate
extends Node3D
## VACA DIN ULICIOARA (Jodhpur, Track17, brief `docs/track_briefs/jodhpur.md`
## §2 randul D/D', §3 randul „Vaca din ulicioara", §8).
##
## O vaca zebu care, ciclic, se muta intre doua pozitii langa gura unei
## [TrackBranch] (scurtatura desenata ca nod, ca la Cappadocia/Fiordland):
##
##   PRAG (implicit) — lateral, IN AFARA benzii: scurtatura e LIBERA
##   GURA            — culcata PE banda, 2.8 m latime dintr-o banda de 3.2 m:
##                      nimeni nu trece
##
## Ciclul (brief): ~31 s pe prag, 3 s telegraph (se ridica), muta-se in gura,
## ~16 s culcata, 3 s telegraph (se ridica), inapoi pe prag. `shortcut_open()`
## e FALS din clipa in care incepe telegraph-ul spre gura pana cand vaca s-a
## intors complet pe prag — exact ca `LavaFlowHazard.shortcut_open()`, si
## acelasi grup (`Track.BRANCH_GATE_GROUP`) o gaseste pe AIController prin
## `Track.branch_is_open`, generalizat pentru asta (vezi `track.gd`).
##
## [b]REGULA DE SIGURANTA (§8, cerinta de design, nu detaliu tehnic).[/b]
## Vaca NU SE LOVESTE, nu se arunca, nu e ragdoll — respectul pentru animalul
## sacru e o regula de design, nu doar de ton. Un `AnimatableBody3D` mutat DE
## COD in interiorul unei masini o azvarle cu sute de m/s: masurat la turma de
## gnu din Serengeti (282 m/s, ingropat la -6 m — vezi memoria
## `corp-cinematic-aparut-in-masina`). De-asta vaca nu se muta niciodata orb pe
## ceas: inainte de FIECARE tranzitie (spre gura SI inapoi spre prag) se
## verifica `_mouth_is_clear()` — nicio masina la mai putin de `clear_radius_m`
## de gura. Daca nu e libera, faza se AMANA (ceasul de stare sta pe loc, nu
## se reseteaza), pana se elibereaza. Nicio masina nu e oprita de asta: doar
## vaca isi intarzie propriul pas, exact cum ar face un animal real care vede
## trafic.
##
## [b]De ce nu SlidingHazard.Motion.USA.[/b] USA e generic (orice model care
## sta in nisa/pe banda/se intoarce) si nu stie de `TrackBranch` sau de
## `branch_is_open` — hazardul de acolo e citit prin `door_hazards` +
## `door_blocks_in()`, o alta intrebare ("va fi inchisa cand ajung?"), potrivita
## pentru un zid pe BANDA PRINCIPALA cu ocol alaturat. Aici e inversul: vaca
## inchide o SCURTATURA (banda secundara), iar decizia AI-ului e deja acoperita
## de `prefers_shortcut and track.branch_is_open(index)` — acelasi canal ca
## lava. Un CowGate nou, mic, tinut separat de USA, e mai limpede decat inca
## un mod pe o clasa deja incarcata cu trei comportamente.
##
## [b]Cum se pozitioneaza — acelasi tipar ca TorrentCycle._place.[/b] Cere
## `branch_index` + `mouth_dist_m` (distanta in METRI de la INCEPUTUL benzii
## pana la gura), nu un `Vector3` scris de mana: gura scurtaturii se
## recalculeaza din `track.route_at(branch_index).baked` la fiecare
## `Regenerate`, deci supravietuieste redesenarii traseului. Pozitia se cauta
## la `_ready` cu `call_deferred` + reincercare pe cadrul urmator daca ruta
## inca nu exista (Track isi construieste `routes` in `rebuild()`, care poate
## rula dupa `_ready`-ul copiilor in anumite ordini de instantiere — sonde
## izolate, mai ales).
##
## [b]O singura scriere de transform pe tick[/b] (memoria
## `jolt-sync-transform-o-singura-scriere`): sub Jolt, un `AnimatableBody3D`
## cu `sync_to_physics` care primeste `global_position` si apoi
## `global_rotation` in ACELASI cadru ingheata la origine — a doua scriere
## recompune transformul dintr-o citire deja sincronizata de fizica. Corpul de
## aici isi scrie intotdeauna `global_transform` complet, o data.

signal state_changed(state: int)

## Starile ciclului. Numele descriu unde ESTE vaca / ce FACE, nu doar
## "deschis/inchis" — sondele si mesajele de eroare citesc starea exacta.
##
## Doua stari de MERS separate de cele de asteptare (nu doar un flag `_walk_t`
## citit peste `LYING_IN_MOUTH`/`ON_THRESHOLD`): scurtatura trebuie sa ramana
## INCHISA cat timp vaca e FIZIC intre prag si gura, in ambele sensuri — o
## masina care intra chiar cand vaca a pornit spre prag, dar inca n-a ajuns,
## ar trece prin ea daca `shortcut_open()` ar raspunde adevarat din clipa in
## care incepe mersul, nu cand chiar s-a terminat.
enum State {
	ON_THRESHOLD,        ## pe prag, in picioare — scurtatura DESCHISA
	RISING_TO_MOUTH,     ## telegraph: se ridica, se pregateste sa mearga in gura
	WALKING_TO_MOUTH,    ## in mers, intre prag si gura — INCHISA
	LYING_IN_MOUTH,      ## culcata in gura — INCHISA
	RISING_TO_THRESHOLD, ## telegraph: se ridica din gura, se intoarce pe prag
	WALKING_TO_THRESHOLD,## in mers, intre gura si prag — tot INCHISA, pana ajunge
}

## Indexul benzii pe care o inchide (in Track.routes / TrackBranch), acelasi
## camp ca LavaFlowHazard.branch_index — Track.branch_is_open il citeste
## generic, prin duck typing, indiferent de tipul nodului.
@export var branch_index: int = 1

## Distanta (m) de la INCEPUTUL benzii (`route.baked[0]`) pana la gura pe care
## o pazeste vaca. Se masoara pe traseul construit, nu se ghiceste.
@export_range(0.0, 500.0, 0.5, "suffix:m") var mouth_dist_m: float = 20.0

## Cat de departe de axa benzii sta PRAGUL, lateral, in afara benzii (m). Se
## adauga la jumatatea latimii benzii, ca pragul sa nu se suprapuna cu ea
## indiferent de `TrackBranch.branch_half_width`.
@export_range(0.5, 8.0, 0.1, "suffix:m") var threshold_offset_m: float = 2.5

## Durata unui ciclu complet (s). Brief: ~47 s (≈31 pe prag + 3 telegraph +
## ≈16 culcata + 3 telegraph — restul cursei pana la 47 e drumul dus-intors,
## instant fata de starile de mai sus, care sunt cele care conteaza pentru
## decizie).
@export_range(10.0, 120.0, 1.0, "suffix:s") var period: float = 47.0

## Cat sta culcata in gura (s), inchizand scurtatura.
@export_range(2.0, 60.0, 0.5, "suffix:s") var lie_seconds: float = 16.0

## Telegraph-ul de ridicare (s), la ambele capete — vaca se ridica, scutura
## capul, clopotelul suna, INAINTE sa porneasca spre cealalta pozitie. Scurta
## dinadins (SlidingHazard.CROSS_TELEGRAPH e 1.2 s pentru un vehicul; vaca e
## mai lenta de anuntat, brief cere 3 s).
@export_range(0.5, 10.0, 0.1, "suffix:s") var telegraph_seconds: float = 3.0

## Cat dureaza mersul propriu-zis intre prag si gura (s). Nu e un ceas separat
## din brief — e miscarea vizuala dintre cele doua telegraph-uri, tinuta
## scurta ca vaca sa nu petreaca mult timp "pe jumatate" intr-o pozitie
## ambigua (nici deschis, nici inchis: cat timp se misca, e deja INCHIS —
## vezi `shortcut_open()`).
@export_range(0.5, 8.0, 0.1, "suffix:s") var walk_seconds: float = 2.0

## Raza (m) in jurul GURII in care, daca e o masina, vaca NU se misca (in
## niciun sens) — isi amana faza. Regula de siguranta din §8: masurata de la
## gura, nu de la vaca insasi, ca sa acopere si masina care a intrat deja pe
## scurtatura inaintea vacii.
@export_range(4.0, 30.0, 0.5, "suffix:m") var clear_radius_m: float = 12.0

## Modelul carat. Implicit (null) = cutia placeholder alba cu doua "coarne"
## portocalii (brief §3: nu se hardcodeaza o cale de model — placeholder pana
## exista `assets/models/jodhpur/animals/zebu_cow.glb`).
@export var model: PackedScene = null

## SABOTAJ DE SONDA (nu de joc): dezactiveaza regula de siguranta, ca sa se
## poata demonstra ca sonda chiar o masoara (memoria
## `garda-circulara-propria-functie`: o garda care nu poate pica niciodata nu
## verifica nimic). Implicit pornita (`false` = regula activa); o sonda o
## stinge explicit cu `--no-safety` sau direct pe nod.
@export var debug_disable_safety: bool = false

## Placeholder: cutie de vaca culcata. AXELE sunt in spatiul CORPULUI, unde
## local -Z e directia "side" (peste banda — vezi _place: Basis.looking_at(side, UP))
## si local X e de-a lungul benzii. Vaca sta CULCATA DE-A LATUL benzii (brief:
## "2.8 m latime dintr-o banda de 3.2 m"), deci lungimea ei (2.8 m, cap-coada)
## trebuie sa fie pe Z (peste banda, ca sa blocheze), iar grosimea trupului
## (1.4 m) pe X (de-a lungul benzii, ingusta). Inversarea asta a fost o eroare
## reala, prinsa de sonda: cu lungimea pe X, cutia bloca doar o fasie de 1.4 m
## din cei 8 m ai benzii de pe Track09 — masinile treceau pe langa ea cu
## lat pana la 0.05 m, adica practic ATINGAND cutia, fara sa se opreasca
## (245 de treceri fizice masurate, 0 contacte reale — cutia era acolo, dar cu
## latimea gresita spre cine trecea).
const BOX_SIZE := Vector3(1.4, 1.3, 2.8)
const HORN_SIZE := Vector3(0.12, 0.12, 0.5)

var _state: State = State.ON_THRESHOLD
var _clock: float = 0.0
## Cat s-a asteptat in starea curenta cu tranzitia gata, dar amanata de
## siguranta — separat de `_clock`, ca timpul de asteptare sa NU se scada din
## durata starii (altfel vaca ar "sari" faza cand se elibereaza gura).
var _pending: bool = false

var _track: Track = null
var _track_searched: bool = false
var _placed: bool = false
var _threshold_xf: Transform3D = Transform3D.IDENTITY
var _mouth_xf: Transform3D = Transform3D.IDENTITY

var _body: AnimatableBody3D = null
## Poza curenta intre prag (0.0) si gura (1.0) — folosita in timpul mersului,
## interpoleaza liniar intre `_threshold_xf` si `_mouth_xf`. Ramane 0 sau 1 in
## restul starilor.
var _walk_t: float = 0.0


func _ready() -> void:
	set_physics_process(not Engine.is_editor_hint())
	_build_body()
	# Track.BRANCH_GATE_GROUP (generalizat din LavaFlowHazard, vezi track.gd):
	# duck typing pe `branch_index` + `shortcut_open()`, deci intrarea in grup
	# e tot ce trebuie ca AIController sa gaseasca poarta asta.
	add_to_group(Track.BRANCH_GATE_GROUP)
	_place.call_deferred()


func _build_body() -> void:
	_body = AnimatableBody3D.new()
	_body.name = "CowBody"
	_body.sync_to_physics = true
	add_child(_body)
	if model != null:
		_build_model()
	else:
		_build_placeholder()


func _build_placeholder() -> void:
	# Corpul culcat: o cutie orizontala, ~la nivelul solului (jumatate din
	# inaltime), plus doua coarne portocalii mici in fata-sus, ca placeholder-ul
	# sa se citeasca "vaca", nu "ladă" — cerinta explicita din brief.
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = BOX_SIZE
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.90, 0.85) # alb-crem, ca zebu-ul din brief
	mesh.material_override = mat
	mesh.position = Vector3.UP * (BOX_SIZE.y * 0.5)
	_body.add_child(mesh)

	var horn_mat := StandardMaterial3D.new()
	horn_mat.albedo_color = Color(0.95, 0.5, 0.1) # coarne pictate portocaliu
	# Capul e la un capat al lungimii, care acum e pe Z (vezi BOX_SIZE); cele
	# doua coarne se despart pe X (grosimea trupului), de o parte si de alta a
	# capului.
	for horn_side in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var hbox := BoxMesh.new()
		hbox.size = HORN_SIZE
		horn.mesh = hbox
		horn.material_override = horn_mat
		horn.position = Vector3(horn_side * 0.35, BOX_SIZE.y + 0.05,
			-BOX_SIZE.z * 0.5 + 0.2)
		_body.add_child(horn)

	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = BOX_SIZE
	shape.shape = col
	shape.position = Vector3.UP * (BOX_SIZE.y * 0.5)
	_body.add_child(shape)


func _build_model() -> void:
	var inst := model.instantiate() as Node3D
	if inst == null:
		_build_placeholder()
		return
	_body.add_child(inst)
	var box := Track.model_aabb(inst)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	if box.size.length() > 0.3:
		col.size = box.size
		shape.position = box.position + box.size * 0.5
	else:
		col.size = BOX_SIZE
		shape.position = Vector3.UP * (BOX_SIZE.y * 0.5)
	shape.shape = col
	_body.add_child(shape)


## Acelasi tipar ca TorrentCycle._find_track: urca in parinti pana la primul
## [Track], memorat o singura data.
func _find_track() -> Track:
	if _track_searched:
		return _track
	_track_searched = true
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			_track = n as Track
			break
		n = n.get_parent()
	return _track


## Calculeaza pozitiile PRAG si GURA din ruta coapta. Reincearca pe cadrul
## urmator daca ruta inca nu exista (Regenerate in curs, sau Track inca nu
## si-a rulat `rebuild()` — acelasi motiv ca la TorrentCycle._place).
func _place() -> void:
	if not is_inside_tree():
		return
	var track := _find_track()
	if track == null or track.routes.size() <= branch_index:
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_place, CONNECT_ONE_SHOT)
		return
	var route := track.route_at(branch_index)
	if route == null or route.baked.is_empty():
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_place, CONNECT_ONE_SHOT)
		return
	var n := route.baked.size()
	var spacing := route.length() / float(maxi(n - 1, 1))
	var idx := clampi(int(round(mouth_dist_m / maxf(spacing, 0.001))), 0, n - 1)
	var idx_next := mini(idx + 1, n - 1)
	if idx_next == idx:
		idx_next = maxi(idx - 1, 0)
	var pos := route.baked[idx]
	var dir := (route.baked[idx_next] - route.baked[mini(idx, idx_next)])
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	if idx_next < idx:
		dir = -dir
	var side := dir.cross(Vector3.UP).normalized()
	var lateral := route.half_width + threshold_offset_m
	# GURA: culcata de-a latul benzii (coarnele "coloneaza" banda), deci corpul
	# priveste PE LATERALA (`side`), nu de-a lungul ei — acelasi tipar
	# Basis.looking_at ca TorrentCycle/PathMover, doar cu axa laterala in loc
	# de directia de mers.
	_mouth_xf = Transform3D(Basis.looking_at(side, Vector3.UP), pos)
	# PRAG: acelasi punct de-a lungul benzii, mutat lateral in afara ei,
	# aceeasi orientare (vaca sta tot cu latul spre banda, gata sa intre).
	_threshold_xf = Transform3D(_mouth_xf.basis, pos + side * lateral)
	_placed = true
	_body.global_transform = _threshold_xf


func _physics_process(delta: float) -> void:
	if not _placed:
		return
	var threshold_wait := period - lie_seconds - telegraph_seconds * 2.0 - walk_seconds * 2.0
	match _state:
		State.ON_THRESHOLD:
			_clock += delta
			if _clock >= threshold_wait:
				_try_advance(State.RISING_TO_MOUTH, threshold_wait)
		State.RISING_TO_MOUTH:
			_clock += delta
			if _clock >= telegraph_seconds:
				_try_advance(State.WALKING_TO_MOUTH, telegraph_seconds)
		State.WALKING_TO_MOUTH:
			_clock += delta
			_walk_t = clampf(_clock / walk_seconds, 0.0, 1.0)
			if _clock >= walk_seconds:
				_state = State.LYING_IN_MOUTH
				_clock = 0.0
				state_changed.emit(_state)
		State.LYING_IN_MOUTH:
			_clock += delta
			if _clock >= lie_seconds:
				_try_advance(State.RISING_TO_THRESHOLD, lie_seconds)
		State.RISING_TO_THRESHOLD:
			_clock += delta
			if _clock >= telegraph_seconds:
				_try_advance(State.WALKING_TO_THRESHOLD, telegraph_seconds)
		State.WALKING_TO_THRESHOLD:
			_clock += delta
			_walk_t = 1.0 - clampf(_clock / walk_seconds, 0.0, 1.0)
			if _clock >= walk_seconds:
				_state = State.ON_THRESHOLD
				_clock = 0.0
				state_changed.emit(_state)
	# O SINGURA scriere de transform pe tick (memoria
	# jolt-sync-transform-o-singura-scriere): interpolarea da direct
	# transformul intreg, nicio scriere separata de pozitie/rotatie.
	_body.global_transform = _threshold_xf.interpolate_with(_mouth_xf, _walk_t)


## Incepe o tranzitie DOAR daca gura e libera de masini — altfel ramane in
## starea curenta, cu ceasul BLOCAT chiar la pragul care a cerut tranzitia
## (nu mai creste — `_physics_process` l-ar re-testa in fiecare cadru,
## ceea ce e corect: verificam din nou pana se elibereaza). Vezi antetul
## clasei, §8.
func _try_advance(next: State, at_clock: float) -> void:
	if not _mouth_is_clear():
		_clock = at_clock
		_pending = true
		return
	_pending = false
	_state = next
	_clock = 0.0
	state_changed.emit(_state)


## Nicio masina la mai putin de `clear_radius_m` de GURA — nu de vaca insasi,
## ca regula sa acopere si o masina deja angajata pe scurtatura inaintea ei
## (brief: "daca ai intrat in ulicioara si vaca intra dupa tine, intra doar
## daca gura e libera 12 m in fata si 12 m in spate").
func _mouth_is_clear() -> bool:
	if debug_disable_safety:
		return true
	if not is_inside_tree():
		return true
	var mouth_pos := _mouth_xf.origin
	for car in get_tree().get_nodes_in_group(&"cars"):
		var c := car as Node3D
		if c == null:
			continue
		if c.global_position.distance_to(mouth_pos) < clear_radius_m:
			return false
	return true


## Citit de Track.branch_is_open (grupul BRANCH_GATE_GROUP, vezi track.gd):
## INCHIS din clipa in care incepe telegraph-ul de culcare pana cand vaca s-a
## intors COMPLET pe prag — adica exact starile in care vaca nu mai e in
## picioare pe prag.
func shortcut_open() -> bool:
	return _state == State.ON_THRESHOLD


func current_state() -> int:
	return _state


## Pozitia GURII (nu a corpului, care poate fi oriunde intre prag si gura in
## timpul mersului) — pentru sonde: "a trecut vreo masina de punctul asta cat
## poarta era inchisa?" e intrebarea reala, nu doar "s-a atins route == branch_index",
## care se poate intampla si la fork, la zeci de metri inainte de gura (vezi
## Track.resolve_route: comuta pe proximitate, indiferent de branch_is_open).
func mouth_position() -> Vector3:
	return _mouth_xf.origin


## Are o tranzitie amanata de siguranta ACUM? Pentru sonde — verdictul
## "0 contacte" nu spune nimic daca vaca nu s-a miscat niciodata pentru ca
## regula de siguranta a tinut-o blocata tot timpul cursei.
func is_pending() -> bool:
	return _pending


func _get_configuration_warnings() -> PackedStringArray:
	var out := PackedStringArray()
	if lie_seconds + telegraph_seconds * 2.0 + walk_seconds * 2.0 >= period:
		out.append("CowGate: lie_seconds + 2*telegraph_seconds + 2*walk_seconds "
			+ "trebuie sa fie mai mic decat period, altfel vaca n-are timp pe prag.")
	return out
