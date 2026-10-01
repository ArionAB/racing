@tool
class_name AlleyGate
extends Node3D
## POARTA INGUSTATA la gura unei scurtaturi (Jodhpur, Track17, brief §2 randul
## D/D', runda 2 a coordonatorului §7 pct. 1).
##
## Banda insasi (`TrackBranch.branch_half_width`) ramane suficient de lata
## pentru manevra fizica a masinilor (6,4 m pe ulicioara Jodhpur), dar chiar
## la gura doi stalpi de coliziune ingusteaza culoarul la o deschidere fixa
## (implicit 4 m liber — gabaritul celei mai late masini + marja, memoria
## `cota-de-contract-se-masoara-ca-gol`). Acolo se pune [CowGate]: cutia ei
## (2,8 m) peste o gura de 4 m inseamna ca nimeni nu trece cat sta culcata.
##
## [b]De ce nod cu pozitionare la RUNTIME, nu coordonate scrise de mana in
## .tscn.[/b] Generatorul de traseu (`gen_jodhpur_route.py`) construieste
## traseul din waypoints cu fillet-uri de arc, aproximate in Python — dar
## Godot coace efectiv curba benzii cu propriul Catmull-Rom
## (`TrackRoute.from_points`), care poate deplasa punctul de INTRARE cu
## metri buni fata de aproximarea Python, mai ales langa un colt de fillet
## (exact unde se ataseaza scurtaturile). Masurat direct (runda 2): gura
## reala (raportata de ProbeLayout) statea la ~7-9 m de pozitia calculata in
## generator pentru stalpii de poarta — suficient cat un stalp sa ajunga in
## AFARA benzii reale, iar cealalta jumatate a culoarului sa ramana complet
## deschisa (fara nicio ingustare), producand ambuteiaje grele la fiecare
## masina care incerca sa treaca (17 repuneri/cursa masurate). Solutia:
## acelasi tipar ca [CowGate]/[TorrentCycle]: nodul se ancoreaza la
## `Track.routes[branch_index]`, citit dupa ce pista si-a rulat `rebuild()`,
## exact ca porecla vacii insasi — deci poarta si vaca ajung ÎNTOTDEAUNA in
## acelasi loc REAL, indiferent cat de mult difera bake-ul de aproximarea
## Python.

## Indexul benzii (in Track.routes) pe gura careia se pune poarta.
@export var branch_index: int = 1

## Distanta (m) de la INCEPUTUL benzii pana la poarta. Acelasi camp si aceeasi
## semantica ca [member CowGate.mouth_dist_m] — se recomanda sa fie IDENTICA
## cu valoarea de acolo, ca poarta si vaca sa coincida (brief: "acolo se
## culca vaca").
@export_range(0.0, 500.0, 0.5, "suffix:m") var gate_dist_m: float = 9.0

## Cat ramane liber intre stalpi (m). Vezi antetul clasei pentru cum se alege
## (gabaritul caroseriei celei mai late + marja).
@export_range(2.0, 10.0, 0.1, "suffix:m") var half_opening_m: float = 2.0

## Semilatimea stalpului insusi (m), dincolo de deschidere.
@export_range(0.3, 3.0, 0.1, "suffix:m") var post_half_width_m: float = 1.3

## Inaltimea stalpului (m).
@export_range(1.0, 6.0, 0.1, "suffix:m") var post_height_m: float = 3.0

## Grosimea stalpului pe directia benzii (m).
@export_range(0.3, 3.0, 0.1, "suffix:m") var post_depth_m: float = 1.0

var _track: Track = null
var _track_searched: bool = false
var _post_a: StaticBody3D = null
var _post_b: StaticBody3D = null


func _ready() -> void:
	set_process(false)
	_build_posts()
	_place.call_deferred()


func _build_posts() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(post_half_width_m * 2.0, post_height_m, post_depth_m)
	_post_a = StaticBody3D.new()
	_post_a.name = "AlleyGatePostA"
	var shape_a := CollisionShape3D.new()
	shape_a.shape = box
	shape_a.position = Vector3.UP * (post_height_m * 0.5)
	_post_a.add_child(shape_a)
	add_child(_post_a)

	_post_b = StaticBody3D.new()
	_post_b.name = "AlleyGatePostB"
	var shape_b := CollisionShape3D.new()
	shape_b.shape = box
	shape_b.position = Vector3.UP * (post_height_m * 0.5)
	_post_b.add_child(shape_b)
	add_child(_post_b)


## Acelasi tipar ca CowGate._find_track: urca in parinti pana la primul Track.
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


## Calculeaza pozitia REALA a portii din ruta coapta (nu din aproximarea
## Python a generatorului). Reincearca pe cadrul urmator daca ruta inca nu
## exista — acelasi motiv ca CowGate._place.
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
	var idx := clampi(int(round(gate_dist_m / maxf(spacing, 0.001))), 0, n - 1)
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
	var half_span := half_opening_m + post_half_width_m
	# Basis: local -Z pe directia benzii (ca stalpul sa fie transversal),
	# acelasi tipar ca CowGate._place (Basis.looking_at(side, UP) e pentru
	# corpul culcat de-a latul; aici vrem stalpul aliniat CU banda, deci
	# looking_at(dir, UP) — fata stalpului (local -Z) priveste in lungul
	# benzii, iar latimea lui (local X) taie culoarul transversal).
	var basis := Basis.looking_at(dir, Vector3.UP)
	_post_a.global_transform = Transform3D(basis, pos + side * half_span)
	_post_b.global_transform = Transform3D(basis, pos - side * half_span)
