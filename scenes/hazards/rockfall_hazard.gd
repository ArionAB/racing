@tool
class_name RockfallHazard
extends Node3D
## Bolovan care se desprinde din faleza, se rostogoleste peste sosea si isi
## vede de drum.
##
## Doua moduri, acelasi hazard:
##
##   1. CU TRASEU (`route`, un Curve3D desenat in editor sub HazardMarker ca
##      Path3D): piatra PORNESTE de unde ai pus primul punct (sus, pe deal),
##      URMEAZA curba pana la ultimul punct si se ROSTOGOLESTE tot timpul —
##      unghiul rotit = distanta parcursa / raza, fara nicio faza in care sta.
##      Traseul e drumul pe care CALCA piatra (il desenezi pe suprafata);
##      centrul sta cu o raza mai sus. Dupa ce ajunge la capat dispare, sta
##      `pause` secunde si o ia de la inceput. Asta e modul cerut de
##      dezvoltator: bolovanul trebuie sa vina de undeva anume, sa se vada de
##      unde, si sa nu pluteasca. Fara traseu, piatra ori cadea din cer, ori
##      cobora pe o dreapta inventata din cod — „pare ca pluteste in aer".
##
##   2. FARA TRASEU (pistele vechi, `custom_rockfall_fracs`): ciclul de dinainte
##      — telegraf, cadere de pe versantul masurat de pista, asezare pe drum,
##      retragere. Ramane pentru compatibilitate; nu se atinge.
##
## Cronologia e DETERMINISTA, fara zar la runtime — la fel ca la sweeper, un
## hazard care se poate invata e o decizie, unul care surprinde e o taxa.
##
## Pedeapsa e ~3 secunde, nu cursa: Car.crush() taie plafonul de viteza pentru
## putin timp. Nu exista stare de "distrus" in joc si nici nu ne trebuie.

## Cat tine fiecare faza, in secunde (modul fara traseu; TELEGRAPH e si
## fereastra in care creste umbra pe asfalt inaintea trecerii, in modul cu
## traseu).
const TELEGRAPH: float = 1.4
const FALL: float = 0.55
const SETTLE: float = 1.1
## De la ce inaltime cade (fara traseu).
const DROP_HEIGHT: float = 9.0
## Cat de departe LATERAL porneste bolovanul, ca multiplu al razei lui (fara
## traseu). Sablonul e la [AvalancheHazard], care coboara la fel de pe panta.
const SLOPE_REACH: float = 5.2
## Raza implicita a bolovanului, cand nu exista model din care s-o masuram.
const ROCK_RADIUS: float = 1.15
## Cu cat e mai mare zona care detecteaza masina decat piatra — ca lovitura sa
## se simta cand piatra te atinge, nu doar cand te patrunde.
const IMPACT_MARGIN: float = 0.95
## Zona de impact pentru raza implicita (pastrat pentru sondele vechi).
const IMPACT_RADIUS: float = ROCK_RADIUS + IMPACT_MARGIN
## Cat de des cade (fara traseu). Nu se schimba per instanta; faza da defazarea.
const DEFAULT_PERIOD: float = 5.5
## Cat sta o masina imuna dupa ce a fost lovita.
const HIT_COOLDOWN: float = 0.6
## Imbranceala laterala a bolovanului rostogolit, in m/s.
##
## Mai mica decat ghiontul barierei mobile (5.5): acolo imbranceala e TOT
## efectul, aici vine peste o strivire de 3 secunde. Insumate, ar arunca masina
## de pe drum si pedeapsa ar deveni repunere — iar pedeapsa in jocul asta e
## mereu timp pierdut, nu cursa pierduta.
const SHOVE_PUSH: float = 3.2

## Modelul implicit: bolovanul modelat PENTRU rostogolire (origine in centru,
## convex, 5 m diametru — vezi docs/asset_briefs/boulder_roller.md). Pana acum
## se folosea `Cluster_L1` din rock_cluster.glb, o movila cu baza plata care se
## dadea peste cap ca un zar; ala ramane bolovanul STATIC din decor.
const DEFAULT_MODEL := "res://assets/models/rocks/boulder_roller.glb"
## 5 m -> 2.5 m in joc, adica raza 1.25 (aproape de vechiul 1.15).
const DEFAULT_MODEL_SCALE: float = 0.5
## Rezerva daca lipseste bolovanul: vechiul cluster.
const FALLBACK_MODEL := "res://assets/models/rocks/rock_cluster.glb"
const FALLBACK_NODE := "Cluster_L1"

## Cat de repede se rostogoleste pe traseu, la viteza de croaziera (m/s).
## Masina de referinta merge cu ~25-30 m/s, deci 9 m/s se citeste ca „bolovan
## greu care coboara", nu ca proiectil.
const DEFAULT_ROUTE_SPEED: float = 9.0
## Acceleratia de la 0 la croaziera, la inceputul traseului: piatra se
## desprinde si prinde viteza, nu apare deja lansata (m/s^2).
const ROUTE_ACCEL: float = 4.0
## Cat sta ascunsa intre doua treceri (secunde), implicit.
const DEFAULT_ROUTE_PAUSE: float = 3.0
## Cat mai ramane umbra pe asfalt dupa ce piatra a trecut.
const SHADOW_LINGER: float = 0.4
## Sonda de teren pentru `stick_to_ground`: de cat deasupra centrului porneste
## raza si cat coboara. 60 m in jos acopera si o faleza inalta plus rapa.
const GROUND_PROBE_UP: float = 2.0
const GROUND_PROBE_DOWN: float = 60.0
## Gravitatia cand terenul fuge de sub piatra (buza falezei): cade in
## parabola, nu se teleporteaza pe cota noua.
const GRAVITY: float = 14.0
## Cat poate cobori terenul intr-un cadru fara ca piatra sa se desprinda de
## el (o denivelare, o treapta de stanca); peste atat e buza si piatra
## pleaca in aer.
const STEP_UP: float = 0.6
## Panta maxima pe care piatra URCA lipita de teren (dy/dx; 1.0 = 45°). Un
## perete de faleza intra in raza ca un salt de 10 m dintr-un cadru — fara
## limita, piatra s-ar teleporta pe creasta. Asa urca cel mult in panta de
## 45°, vizibil, si e semn ca traseul trebuie oprit inaintea peretelui.
const MAX_CLIMB: float = 1.0

## Efectul strivirii: durata, plafon de viteza, turtire, cat din viteza ramane.
##
## Cifrele vin din #242, unde strivirea a fost ceruta explicit: masina ramane
## APLATIZATA cu ~30% mai mult decat inainte, merge cu ~30% mai incet, si isi
## revine dupa 3 secunde. Punct de plecare pentru tunat la playtest, ca tot ce
## tine de feel.
const CRUSH_SECONDS: float = 3.0
const CRUSH_FACTOR: float = 0.70
const CRUSH_KEEP_SPEED: float = 0.50
const CRUSH_SQUASH := Vector3(1.55, 0.245, 1.45)

## Setter-ele exista pentru RESINCRONIZAREA de dupa `_ready`: metronomul
## eruptiei (EruptionCycle) scrie period + phase pe hazardele din grupul lui
## DUPA ce pista le-a construit, iar fara re-derivarea lui `_time` scrierea
## ar fi ramas litera moarta — ceasul intern pornise deja din faza veche.
@export var period: float = DEFAULT_PERIOD:
	set(value):
		period = maxf(value, 0.1)
		_time = fposmod(phase, 1.0) * period
## Defazare 0..1, ca doua bolovanuri sa nu cada la unison.
@export var phase: float = 0.0:
	set(value):
		phase = value
		_time = fposmod(phase, 1.0) * period
## Culoarea umbrei de avertisment.
@export var telegraph_color: Color = Color(0.05, 0.03, 0.02, 0.55)

## Traseul pe care se rostogoleste, in coordonatele PARINTELUI (pista). Se
## converteste in spatiul local la `_ready`. Null = modul fara traseu.
var route: Curve3D = null
## Viteza de croaziera pe traseu (m/s) si pauza dintre treceri (s).
var route_speed: float = DEFAULT_ROUTE_SPEED
var route_pause: float = DEFAULT_ROUTE_PAUSE
## Cu traseu: Y-ul curbei se IGNORA si piatra isi ia cota din teren cu un
## raycast — desenezi traseul din vederea de sus, fara grija cotelor, iar
## bolovanul urca dealul, coboara si SARE de pe buza falezei in parabola
## (vezi GRAVITY). Stins = urmeaza exact cota curbei (acelasi contract ca
## `PathMover.stick_to_ground`).
var stick_to_ground: bool = true

## Modelul bolovanului: GLB-ul, piesa din el (gol = tot), scara. Null = cel
## implicit (`DEFAULT_MODEL`). Vin de pe HazardMarker, grupul „Model".
var model_scene: PackedScene = null
var model_node: String = ""
var model_scale: float = 0.0 # 0 = implicitul modelului ales

## Din ce parte vine bolovanul, FARA traseu: +1 dreapta sensului de mers, -1
## stanga. O pune pista, din latura pe care chiar exista versant. 0 = „nu se
## stie", si atunci piatra cade vertical.
var slope_side: float = 0.0

## Clasa de material triplanar ("" = atlasul comun al lumii).
##
## Granit pe Alpii, gresie pe Dunele: acelasi bolovan arata altfel dupa peisaj,
## fara sa-si aduca texturi proprii (regula claselor din CLAUDE.md).
var tri_class: String = ""

var _rock: AnimatableBody3D
var _pivot: Node3D # modelul, ca sa se roteasca fara sa roteasca si sfera
var _last_pos: Vector3
var _rock_shape: CollisionShape3D
var _telegraph: MeshInstance3D
var _impact: Area3D
var _audio: AudioStreamPlayer3D
var _time: float = 0.0
## Faza precedenta, ca sunetele sa porneasca o singura data la trecere.
var _last_phase: int = -1
var _cooldown: Dictionary = {}
## Raza reala a bolovanului, masurata pe model.
var _radius: float = ROCK_RADIUS
## Ultima axa de rostogolire: pastrata cand miscarea e aproape verticala
## (piatra sare), ca sa continue sa se invarta in aer in loc sa inghete.
var _roll_axis: Vector3 = Vector3.RIGHT
## Directia orizontala a ultimei deplasari — de aici vine imbranceala.
var _move_dir: Vector3 = Vector3.ZERO

## Starea verticala cand piatra e lipita de teren: viteza de cadere si daca
## e in aer (a iesit de pe o buza).
var _vy: float = 0.0
var _airborne: bool = false
## Cota GLOBALA a centrului in cadrul precedent — starea verticala e a
## pietrei, nu a curbei: curba da doar X/Z, iar Y-ul de ieri hotaraste daca
## azi esti pe sol sau in aer.
var _cur_y: float = 0.0
var _last_ground_xz: Vector2 = Vector2.ZERO

## Traseul in spatiul LOCAL al hazardului, lungimea lui si timpii-cheie.
var _route_local: Curve3D = null
var _route_len: float = 0.0
var _route_travel: float = 0.0 # cat dureaza o trecere, in secunde
var _cross_time: float = 0.0   # cand ajunge deasupra soselei (umbra, sunet)

## Materiale STATICE, partajate intre toate instantele.
static var _tele_mat: StandardMaterial3D
static var _rock_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	if route != null:
		_setup_route()
	# Pornim din faza dorita, nu de la zero: altfel toate bolovanurile de pe pista
	# ar cadea simultan in primele secunde ale cursei.
	_time = fposmod(phase, 1.0) * period


func _build() -> void:
	_telegraph = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.height = 0.04
	# Implicit are 64 de laturi. Pentru o pata de umbra e absurd — vezi nota din
	# CLAUDE.md despre primitive lasate la rezolutia implicita.
	disc.radial_segments = 14
	disc.rings = 1
	_telegraph.mesh = disc
	if _tele_mat == null:
		_tele_mat = StandardMaterial3D.new()
		_tele_mat.albedo_color = telegraph_color
		_tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Fara scriere in depth: umbra sta LIPITA de asfalt, nu taie geometria.
		_tele_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_telegraph.material_override = _tele_mat
	_telegraph.position = Vector3.UP * 0.05
	add_child(_telegraph)

	_rock = AnimatableBody3D.new()
	# Ca la celelalte hazarde mobile: fara asta, masina vede un salt de pozitie
	# in loc de o coliziune cu viteza.
	_rock.sync_to_physics = true
	add_child(_rock)
	# Modelul sta intr-un pivot ca sa se poata ROSTOGOLI fara sa roteasca si
	# forma de coliziune: sfera e simetrica, deci rotirea ei n-ar face decat
	# munca in plus la serverul de fizica. Acelasi tipar ca la SlidingHazard.
	_pivot = Node3D.new()
	_rock.add_child(_pivot)
	var model := _rock_model()
	if model != null:
		_pivot.add_child(model)
		_center_and_measure(model)

	_rock_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = _radius
	_rock_shape.shape = sphere
	_rock.add_child(_rock_shape)

	disc.top_radius = _radius + IMPACT_MARGIN
	disc.bottom_radius = disc.top_radius

	_impact = Area3D.new()
	var area_shape := CollisionShape3D.new()
	var area_sphere := SphereShape3D.new()
	area_sphere.radius = _radius + IMPACT_MARGIN
	area_shape.shape = area_sphere
	_impact.add_child(area_shape)
	_rock.add_child(_impact)

	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 80.0
	add_child(_audio)


## Bolovanul: modelul cerut de nod, altfel `boulder_roller.glb`, altfel vechiul
## cluster. Fara niciun GLB, o sfera cu putine laturi — hazardul trebuie sa
## functioneze si daca lipseste un asset.
func _rock_model() -> Node3D:
	var scene := model_scene
	var piece := model_node
	var scl := model_scale
	if scene == null:
		if ResourceLoader.exists(DEFAULT_MODEL):
			scene = load(DEFAULT_MODEL)
			piece = ""
			if scl <= 0.0:
				scl = DEFAULT_MODEL_SCALE
		elif ResourceLoader.exists(FALLBACK_MODEL):
			scene = load(FALLBACK_MODEL)
			piece = FALLBACK_NODE
	if scl <= 0.0:
		scl = 1.0
	if scene != null:
		var container := scene.instantiate() as Node3D
		if container != null:
			if not piece.is_empty():
				var kept: Node3D = null
				for child in container.get_children():
					if child.name == piece:
						kept = child as Node3D
					else:
						# `remove_child` inainte de `queue_free`: eliberarea e
						# amanata, iar pana atunci piesele s-ar randa si ar
						# intra in masuratoarea de raza.
						container.remove_child(child)
						child.queue_free()
				if kept == null:
					push_warning("RockfallHazard: piesa '%s' lipseste din %s"
						% [piece, scene.resource_path])
			container.scale = Vector3.ONE * scl
			# Cu o clasa ceruta de pista (granit pe Alpii, gresie pe Dunele),
			# textura de clasa ia locul atlasului — dar TRIPLANAR IN SPATIUL
			# OBIECTULUI, fiindca bolovanul se rostogoleste: cu proiectie de
			# lume, textura ar "inota" pe suprafata in timp ce piatra se
			# invarte (style_bible §4, aceeasi nota ca la SlidingHazard).
			if tri_class.is_empty():
				# Fara clasa de pista: modelul isi tine sloturile din atlas,
				# dar trece prin maparea de clase pe PARTI — bombele vulcanice
				# isi iau finisajul emisiv (`Bomb_` -> finish:lava), restul
				# raman pe materialul lumii, exact ca la decorul manual. In
				# spatiul OBIECTULUI, fiindca piatra se rostogoleste.
				Palette.apply_object_class_materials(container,
					WorldProp.prop_classes(), scl)
			else:
				Palette.apply_object_triplanar_class(container, tri_class, scl)
			return container
	var fallback := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = ROCK_RADIUS
	mesh.height = ROCK_RADIUS * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	fallback.mesh = mesh
	if _rock_mat == null:
		_rock_mat = StandardMaterial3D.new()
		_rock_mat.albedo_color = Palette.color(Palette.ROCK_DARK)
	fallback.material_override = _rock_mat
	return fallback


## Aduce modelul cu CENTRUL geometric in originea pivotului si masoara raza.
##
## Un bolovan din kit poate avea originea la baza (rock_large), altul in centru
## (boulder_roller). Rotit in jurul originii lui, primul ar sari ca o minge
## dezumflata; centrat pe cutia lui, orice model se rostogoleste in jurul
## propriului mijloc. Raza se masoara — nu se presupune — ca sfera de coliziune
## sa fie cat se vede, la orice scara.
func _center_and_measure(model: Node3D) -> void:
	var box := Track.model_aabb(model)
	if box.size.length() < 0.02:
		return
	model.position -= box.get_center()
	_radius = maxf(box.size.x, box.size.z) * 0.5


## Traseul vine in coordonatele PISTEI; il aducem in spatiul local, calculam
## lungimea, durata unei treceri si momentul in care trece peste sosea.
func _setup_route() -> void:
	var inv := transform.affine_inverse()
	_route_local = Curve3D.new()
	_route_local.bake_interval = 0.25
	for i in route.point_count:
		var p := route.get_point_position(i)
		var lp := inv * p
		_route_local.add_point(lp,
			inv.basis * route.get_point_in(i),
			inv.basis * route.get_point_out(i))
	_route_len = _route_local.get_baked_length()
	_route_travel = _travel_time(_route_len)
	period = _route_travel + maxf(route_pause, 0.0)
	# Punctul de trecere: esantionul de pe traseu cel mai apropiat (in plan) de
	# originea hazardului, care e pe sosea. Aici creste umbra si suna impactul.
	var best := 0.0
	var best_d := INF
	var d := 0.0
	while d <= _route_len:
		var s := _route_local.sample_baked(d, true)
		var flat := Vector2(s.x, s.z).length()
		if flat < best_d:
			best_d = flat
			best = d
		d += 0.25
	_cross_time = _time_for_distance(best)
	_last_pos = _route_pos(0.0)


## Cand ajunge piatra DEASUPRA soselei, in secunde de la plecare. Public
## pentru metronomul eruptiei: pulsul trebuie sa prinda bomba peste drum,
## nu la plecarea de sus, deci faza se calculeaza scazand timpul asta.
func cross_time() -> float:
	return _cross_time


## Distanta parcursa dupa `t` secunde: acceleratie constanta pana la croaziera,
## apoi viteza constanta.
func _distance_at(t: float) -> float:
	var v := maxf(route_speed, 0.1)
	var t_acc := v / ROUTE_ACCEL
	if t < t_acc:
		return 0.5 * ROUTE_ACCEL * t * t
	return 0.5 * v * t_acc + v * (t - t_acc)


func _travel_time(dist: float) -> float:
	return _time_for_distance(dist)


func _time_for_distance(dist: float) -> float:
	var v := maxf(route_speed, 0.1)
	var d_acc := 0.5 * v * v / ROUTE_ACCEL
	if dist <= d_acc:
		return sqrt(2.0 * dist / ROUTE_ACCEL)
	return v / ROUTE_ACCEL + (dist - d_acc) / v


## Pozitia CENTRULUI la distanta `d` pe traseu: traseul e drumul pe care calca
## piatra, centrul e cu o raza mai sus.
func _route_pos(d: float) -> Vector3:
	return _route_local.sample_baked(clampf(d, 0.0, _route_len), true) \
		+ Vector3.UP * _radius


func _physics_process(delta: float) -> void:
	if _rock == null:
		return
	_time = fposmod(_time + delta, period)
	if _route_local != null:
		_process_route(delta)
		return
	var t := _time
	var idx := 0
	# Fazele CALCULEAZA pozitia, `_physics_process` o aplica: asa exista un
	# singur loc care stie unde e piatra intr-un cadru, si acelasi numar
	# hraneste si rostogolirea.
	var pos := Vector3.ZERO
	if t < TELEGRAPH:
		pos = _phase_telegraph(t)
	elif t < TELEGRAPH + FALL:
		idx = 1
		pos = _phase_fall(t - TELEGRAPH)
	elif t < TELEGRAPH + FALL + SETTLE:
		idx = 2
		pos = _phase_settle()
	else:
		idx = 3
		pos = _phase_retract(t - (TELEGRAPH + FALL + SETTLE))
	_rock.position = pos
	if idx != _last_phase:
		_on_phase_enter(idx)
		_last_phase = idx
	_roll(idx, pos)
	if Engine.is_editor_hint():
		return
	# Doar in ultima clipa a caderii si la inceputul asezarii: intre timp piatra e
	# sus sau se retrage, si o lovitura acolo n-ar avea sens vizual.
	var live := (idx == 1 and t - TELEGRAPH > FALL - 0.12) \
		or (idx == 2 and t - TELEGRAPH - FALL < 0.15)
	_tick_cooldowns(delta)
	if live:
		_hit_cars()


## Modul cu traseu: o singura miscare continua, de la primul punct la ultimul.
##
## Fazele de aici sunt doar pentru sunete si umbra (0 = coboara, 1 = umbra
## creste pe asfalt, 2 = a trecut, 3 = pauza); pozitia si rostogolirea nu depind
## de ele — piatra se invarte cat timp se misca, adica tot drumul.
func _process_route(delta: float) -> void:
	var t := _time
	var moving := t < _route_travel
	var idx := 3
	if moving:
		if t < _cross_time - TELEGRAPH:
			idx = 0
		elif t < _cross_time:
			idx = 1
		else:
			idx = 2
	var pos := _route_pos(_distance_at(t)) if moving else _route_pos(0.0)
	var fresh := _last_phase == 3 or _last_phase < 0
	if stick_to_ground and moving:
		pos = _grounded(pos, delta, fresh)
	_rock.position = pos
	_rock.visible = moving
	_rock_shape.disabled = not moving
	# Umbra: creste in ultimele TELEGRAPH secunde inainte de trecere si mai
	# ramane putin dupa — e AVERTISMENTUL citibil de la distanta de franare,
	# chiar daca piatra insasi se vede coborand pe versant.
	var shadow := moving and t >= _cross_time - TELEGRAPH \
		and t <= _cross_time + SHADOW_LINGER
	_telegraph.visible = shadow
	if shadow:
		var k := clampf((t - (_cross_time - TELEGRAPH)) / TELEGRAPH, 0.0, 1.0)
		_telegraph.scale = Vector3.ONE * lerpf(0.2, 1.0, k)
	if idx != _last_phase:
		if idx == 0 and _last_phase == 3:
			# Piatra tocmai s-a desprins: teleportare la start, fara sa se
			# „rostogoleasca" toata lungimea traseului inapoi intr-un cadru.
			_last_pos = pos
		_on_phase_enter_route(idx)
		_last_phase = idx
	if moving:
		_roll_along(pos)
	if Engine.is_editor_hint():
		return
	_tick_cooldowns(delta)
	if moving:
		_hit_cars()


## Cota piatrei lipita de teren, cu cadere libera cand terenul dispare de sub
## ea. `fresh` = tocmai a aparut la start: se aseaza direct pe sol, fara sa
## „cada" din cota curbei.
##
## Raza porneste de deasupra CENTRULUI curent, nu de deasupra curbei: cand
## piatra e in aer dupa o buza, terenul de sub ea e cel de la baza falezei, si
## acolo trebuie sa aterizeze. Masinile si alte corpuri mobile se sar — o raza
## care ar da de o masina ar salta bolovanul pe capota ei.
func _grounded(pos: Vector3, delta: float, fresh: bool) -> Vector3:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return pos
	var g := to_global(pos)
	# Cand tocmai a aparut, sondam din cota curbei (plus o palma); altfel din
	# cota REALA de ieri — curba nu stie ca piatra e inca in aer.
	if not fresh:
		g.y = _cur_y
	var cur_y := g.y if not fresh else g.y + GROUND_PROBE_UP
	var exclude: Array[RID] = [_rock.get_rid()]
	var ground_y := -INF
	for _attempt in 4:
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(g.x, cur_y + GROUND_PROBE_UP, g.z),
			Vector3(g.x, cur_y - GROUND_PROBE_DOWN, g.z), 0xFFFFFFFF, exclude)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var col: Object = hit["collider"]
		if col is RigidBody3D or col is CharacterBody3D:
			exclude.append(hit["rid"])
			continue
		ground_y = (hit["position"] as Vector3).y
		break
	if ground_y == -INF:
		_cur_y = to_global(pos).y
		return pos # nimic sub piatra (teren negenerat in editor): cota curbei
	# Scara hazardului e 1, deci raza e aceeasi in local si global.
	var rest_y := ground_y + _radius
	var y := g.y
	if fresh:
		y = rest_y
		_vy = 0.0
		_airborne = false
		_last_ground_xz = Vector2(g.x, g.z)
	elif _airborne:
		_vy -= GRAVITY * delta
		y += _vy * delta
		if y <= rest_y:
			y = rest_y
			_vy = 0.0
			_airborne = false
	elif rest_y < y - STEP_UP:
		# Terenul a fugit de sub piatra: buza. Pleaca in aer cu viteza
		# verticala zero, gravitatia face restul.
		_airborne = true
		_vy = 0.0
	else:
		# Lipita de sol: coboara oricat (pana la STEP_UP), urca cel mult in
		# panta MAX_CLIMB fata de pasul orizontal facut in cadrul asta.
		var flat_step := Vector2(g.x - _last_ground_xz.x,
			g.z - _last_ground_xz.y).length()
		y = minf(rest_y, y + maxf(flat_step, 0.01) * MAX_CLIMB)
	_last_ground_xz = Vector2(g.x, g.z)
	g.y = y
	_cur_y = y
	return to_local(g)


func _on_phase_enter_route(idx: int) -> void:
	if Engine.is_editor_hint():
		return
	match idx:
		1:
			_play(&"rock_warn")
		2:
			_play(&"rock_impact")


## Rostogolire continua: unghi = distanta parcursa / raza, in jurul axei
## perpendiculare pe directia de mers. Cand deplasarea e aproape verticala
## (piatra sare de pe o buza), pastram ultima axa — un bolovan in aer isi
## tine inertia de rotatie, nu ingheata.
func _roll_along(wanted: Vector3) -> void:
	var moved := wanted - _last_pos
	_last_pos = wanted
	var dist := moved.length()
	if dist < 0.0001:
		return
	var flat := Vector3(moved.x, 0.0, moved.z)
	if flat.length() > 0.001:
		_move_dir = flat.normalized()
		_roll_axis = Vector3.UP.cross(_move_dir).normalized()
	_pivot.rotate(_roll_axis, -dist / _radius)


## Rostogolirea modelului FARA traseu: doar in coborare si asezare. La
## retragere piatra se intoarce pe versant, si un bolovan care se da peste cap
## invers, urcand, ar arata a film rulat inapoi.
func _roll(idx: int, wanted: Vector3) -> void:
	if _pivot == null:
		return
	# Deplasarea se ia din pozitia CERUTA de faze, nu citind `_rock.position`:
	# corpul are `sync_to_physics`, deci transformul il tine serverul de fizica
	# si valoarea scrisa nu se vede inapoi in acelasi cadru.
	var moved := wanted - _last_pos
	_last_pos = wanted
	if slope_side == 0.0 or idx > 2:
		return
	var flat := Vector3(moved.x, 0.0, moved.z)
	if flat.length() < 0.0001:
		return
	_move_dir = flat.normalized()
	var axis := Vector3.UP.cross(_move_dir).normalized()
	_pivot.rotate(axis, -flat.length() / _radius)


func _on_phase_enter(idx: int) -> void:
	if Engine.is_editor_hint():
		return
	match idx:
		0:
			_play(&"rock_warn")
		2:
			_play(&"rock_impact")


func _play(sfx: StringName) -> void:
	var stream := AudioManager.stream(sfx)
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


## Umbra creste pe asfalt: singurul avertisment, si trebuie sa fie lizibil de la
## distanta de franare.
func _phase_telegraph(t: float) -> Vector3:
	var k := clampf(t / TELEGRAPH, 0.0, 1.0)
	_telegraph.visible = true
	_telegraph.scale = Vector3.ONE * lerpf(0.2, 1.0, k)
	_rock_shape.disabled = true
	# Cu versant, piatra se VEDE stand pe panta in tot telegraful: de acolo vine.
	# Fara versant ramane ascunsa sus — nu are sens sa pluteasca in aer un
	# lucru care „cade din cer".
	_rock.visible = slope_side != 0.0
	return _start_pos()


## Coborarea: de pe versant peste sosea (sau, fara versant, cadere verticala).
func _phase_fall(t: float) -> Vector3:
	var k := clampf(t / FALL, 0.0, 1.0)
	_rock.visible = true
	_rock_shape.disabled = false
	var from := _start_pos()
	var to := Vector3(0.0, _radius, 0.0)
	_telegraph.scale = Vector3.ONE * lerpf(1.0, 0.85, k)
	# Lateralul avanseaza LINIAR (piatra se rostogoleste, nu tasneste), iar
	# inaltimea cade accelerat (k^2 arata a gravitatie).
	return Vector3(
		lerpf(from.x, to.x, k),
		lerpf(from.y, to.y, k * k),
		lerpf(from.z, to.z, k))


## Piatra sta pe drum ca obstacol SOLID: trebuie ocolita, nu doar evitata la
## momentul caderii.
func _phase_settle() -> Vector3:
	_rock_shape.disabled = false
	_telegraph.visible = false
	return Vector3(0.0, _radius, 0.0)


## Se retrage pe unde a venit: inapoi pe versant, nu in sus prin aer.
func _phase_retract(t: float) -> Vector3:
	var span := maxf(period - (TELEGRAPH + FALL + SETTLE), 0.001)
	var k := clampf(t / span, 0.0, 1.0)
	var from := Vector3(0.0, _radius, 0.0)
	var to := _start_pos()
	_rock_shape.disabled = true
	_rock.visible = slope_side != 0.0 or k < 0.9
	_telegraph.visible = false
	return from.lerp(to, k)


## De unde porneste bolovanul FARA traseu, in coordonate LOCALE fata de punctul
## de impact. Nodul e asezat de pista cu +X spre marginea drumului dinspre care
## vine piatra (vezi `Track._build_rockfall`), deci lateralul e pe X local.
func _start_pos() -> Vector3:
	if slope_side == 0.0:
		return Vector3(0.0, DROP_HEIGHT, 0.0) # fara versant: cadere verticala
	return Vector3(_radius * SLOPE_REACH, DROP_HEIGHT, 0.0)


func _tick_cooldowns(delta: float) -> void:
	# Netipat: `for car: Car in` ar ATRIBUI si cheile-masini deja eliberate
	# in variabila tipata, si chiar atribuirea da "previously freed instance"
	# (vezi nota din TyphoonHazard._steer_lofted).
	for key in _cooldown.keys():
		if not is_instance_valid(key):
			_cooldown.erase(key)
			continue
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0:
			_cooldown.erase(key)
		else:
			_cooldown[key] = left


func _hit_cars() -> void:
	for body in _impact.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = HIT_COOLDOWN
		# `hold_squash`: masina RAMANE latita cat tine incetinirea, nu sare
		# inapoi la forma normala in doua zecimi. Turtirea e explicatia pentru
		# care mergi mai incet trei secunde.
		car.crush(CRUSH_SECONDS, CRUSH_FACTOR, CRUSH_SQUASH,
			CRUSH_KEEP_SPEED, true)
		# Impinsa in jos: turtirea trebuie sa se si SIMTA, nu doar sa se vada.
		car.velocity.y = -6.0
		# Lovitura vine din DIRECTIA in care mergea piatra, nu mereu de sus:
		# un bolovan care te ia din coasta te si imbranceste — altfel s-ar
		# vedea trecand prin masina fara consecinta. Directia e cea a ultimei
		# deplasari orizontale (pe traseu, oriunde ar duce; fara traseu, de pe
		# versant spre sosea). La caderea verticala nu exista lateral si
		# ramane doar strivirea.
		if _move_dir.length() > 0.5:
			car.apply_sweep(global_transform.basis * _move_dir * SHOVE_PUSH)
