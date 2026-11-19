class_name BumpProp
extends RigidBody3D
## Decor MIC care se imprastie la contact (#489): taburete, scutere, biciclete,
## rucsaci, tumbleweed, butoaie. Principiul 1 din CLAUDE.md — haosul fizic e
## mecanica — aplicat pe tot decorul care n-are ce cauta ca zid sau ca fantoma.
##
## Acelasi tipar ca `RoadMarker`: corp rigid ADORMIT pana il atinge cineva —
## un corp adormit costa aproape nimic in Jolt. Diferenta: modelul nu se
## construieste aici, se IMPRUMUTA. `wrap` ia un model deja asezat in lume (de
## WorldProp sau de un constructor din Track) si il muta sub un corp nou, cu
## aceeasi pozitie si rotatie.
##
## Stratul propriu (`LAYER`) e cheia: masina il loveste (Car isi adauga stratul
## in masca), dar razele suspensiei, camera si cautarea de loc liber la
## repunere folosesc masca implicita, deci NU il vad — roata nu urca pe un
## taburet, camera nu se smuceste dupa o bicicleta, repunerea nu fuge de un
## rucsac. Iar AI-ul nu vede deloc decorul; trece prin el si il imprastie.
##
## Modelul ramane sub un nod CU SCRIPT, deci coacerea in MultiMesh a decorului
## manual (`TrackDecorBatch._collect_manual`) il sare — altfel bufferul static
## ar fi lasat o copie inghetata in locul de unde a zburat.

## Stratul de coliziune al decorului bump-abil (layer 9).
const LAYER: int = 1 << 8
## Pragul de marime (#489, „de decis"): doar ce incape intr-o cutie de 2 m in
## plan si 1,8 m inaltime. O masa cu taburete (1,82 x 1,88 m, masurata) sau un
## scuter da; o masina parcata, un container sau un felinar de piatra nu —
## acelea raman colizori statici.
const MAX_FOOTPRINT_M: float = 2.0
const MAX_HEIGHT_M: float = 1.8
## Plafonul de corpuri per pista (costul pe mobil). Adormite nu costa, dar o
## izbitura in gramada le trezeste pe toate deodata. Peste plafon, piesa ramane
## statica (WorldProp cade pe hull) — nimic nu dispare.
## 128 din nov 2026 (decizia dezvoltatorului; era 64): San Francisco cerea exact 64 (42 de
## masini parcate + 22 de piese de strada), deci nicio piesa noua nu mai incapea acolo, iar
## decorul lovibil se intinde pe toate pistele. Stalpii de bordura (`RoadMarker`, pana la 110)
## se numara separat, deci costul corpurilor adormite era deja acceptat la scara asta. Ce NU
## acopera plafonul: fiecare piesa e un nod in afara coacerii MultiMesh, adica desene in plus —
## o pista care se apropie de plafon se masoara cu `ProbePerf`.
const MAX_PER_TRACK: int = 128
## Masa din volumul cutiei, cu o densitate de JUCARIE (kg/m³): o masina are
## 100-260 kg, iar un butoi de jucarie trebuie sa zboare, nu sa opreasca. Cu
## jumatate din cutie „plina": butoiul ~4 kg, rucsacul ~0,5 kg.
const DENSITY: float = 25.0
const MIN_MASS: float = 0.3
const MAX_MASS: float = 4.0
## Sub cota de pornire cu atat (m): a cazut din lume, se sterge.
const LOST_BELOW_M: float = 25.0
## Cat se ridica talpa cutiei peste talpa modelului (vezi `_setup`).
const SPAWN_LIFT_M: float = 0.03

const PropDebris := preload("res://scenes/props/prop_debris.gd")

## Cat sta o piesa „cu masa" (`opts.home`) neatinsa, oprita, inainte sa se intoarca la locul ei, si
## de la ce distanta de orice masina (m) are voie sa o faca, ca sa nu se mute sub ochii cuiva.
const HOME_DELAY_S: float = 5.0
const HOME_CLEAR_M: float = 30.0

## Formele de coliziune (`opts.shape`). Cutia e implicitul si ramane neschimbata; celelalte sunt
## pentru piese care trebuie sa se ROSTOGOLEASCA (decor lovibil, valul 2, nov 2026): pana aici
## orice piesa era o cutie, deci un butoi lovit aluneca pe o muchie ca o caramida.
##   "cylinder"  cilindru pe axa verticala a modelului: butoaie, cauciucuri, teancuri;
##   "sphere"    sfera: tumbleweed, baloane, bolovani de jucarie;
##   "hull"      infasuratoarea convexa a modelului: conul de trafic (se rastoarna si se
##               rostogoleste in arc, in jurul varfului).
const SHAPES: Array[String] = ["box", "cylinder", "sphere", "hull"]
## Amortizarea pieselor care se rostogolesc. Jolt nu are rezistenta la rulare: o piesa rotunda
## se opreste DOAR din amortizare, care e proportionala cu viteza — deci taie tocmai loviturile
## tari. Prima incercare (0,7 liniar) dadea piese care mergeau MAI PUTIN decat cutia la viteza de
## cursa. Liniara ramane cea a cutiei (0,3), iar unghiulara e mult sub a ei (0,6), altfel rotirea
## se stinge inainte ca piesa sa apuce sa ruleze. Masurat cu tools/ProbeBumpRoll.tscn: impins cu
## 6 m/s pe plat, butoiul culcat ajunge la 6,7 m invartindu-se (17 rad); aceeasi piesa cu cutie
## aluneca 3,6 m fara sa se invarta.
const ROLL_LINEAR_DAMP: float = 0.3
const ROLL_ANGULAR_DAMP: float = 0.2
## „Rezistenta la rulare" de jucarie, in doua trepte. Sub `ROLL_REST_SPEED` amortizarea liniara
## sare la `ROLL_REST_DAMP` (piesa incetineste vizibil, nu ingheata din mers), iar dupa `SETTLE_S`
## secunde sub `SETTLE_SPEED` e adormita. Fara asta, pe orice panta ar cobori la nesfarsit,
## treaza, adica platita la fiecare pas de fizica.
## Ce iese din cifre (cilindru; sfera e aproape la fel): o piesa care ruleaza REPEDE pe o panta
## de peste ~5 grade nu mai coboara sub prag si se duce la vale — asta e de dorit, e un butoi pe
## un deal — pana da de plat sau de un perete. Pe pante mai line incetineste si se opreste. In
## aer pragurile nu conteaza: gravitatia adauga 9,8 m/s in secunda de asteptare.
const ROLL_REST_SPEED: float = 2.0
const ROLL_REST_DAMP: float = 3.0
const SETTLE_SPEED: float = 0.6
const SETTLE_S: float = 1.0

var _spawn_y: float = 0.0
var _rolls: bool = false
## Saltul la lovitura (`opts.pop`, m/s): la primul contact cu o masina piesa primeste viteza asta
## in SUS, deci zboara peste capota in loc sa fie impinsa pe sol in fata barei. E un reglaj de
## feel (decor lovibil, valul 3), nu o reparatie masurata: pe ProbeBumpProps viteza masinii dupa
## lovitura a iesit la fel cu si fara el. 0 = fara (tot ce exista dinainte de valul 3).
var _pop: float = 0.0
var _pop_ready: bool = true
const POP_COOLDOWN_S: float = 0.6
var _settle_t: float = 0.0
var _home: Transform3D = Transform3D.IDENTITY
var _home_back: bool = false
var _home_pending: bool = false


## Muta `model` (deja in arbore, deja asezat) sub un BumpProp nou si il
## intoarce. Null daca piesa e prea mare, daca pista si-a atins plafonul sau
## daca modelul n-are geometrie — apelantul pastreaza atunci calea statica.
##
## `opts` (toate optionale, implicitul = jucaria de 4 kg de mai sus):
##   "mass"  masa in kg, ocolind densitatea de jucarie — pentru piese care trebuie sa
##           cantareasca ca o masina (tuk-tuk-urile Angkorului: Buggy-ul (100 kg) le
##           impinge greu, Autobuzul (260 kg) le arunca);
##   "home"  true: dupa ce a fost lovita si s-a oprit, piesa se intoarce la locul ei
##           (cand nicio masina nu e aproape), ca sa nu ramana blocaj pe drum;
##   "max_footprint"  plafonul de marime in plan (m) pentru piesa asta, in locul celor 2 m —
##           cerut EXPLICIT de cine stie ce face (masinile parcate din San Francisco: 3,7 m,
##           cu masa de masina de joc). Fara cheie, regula de la #489 ramane neschimbata;
##   "max_height"  la fel, plafonul de inaltime (m) in locul celor 1,8 m: duba parcata din foaia
##           de assets San Francisco. Masurat cu tools/ProbeBumpTall.tscn (piesa de 2,4 m lovita
##           la 30 m/s): vezi antetul sondei.
##   "box"   AABB-ul (in spatiul propriu al modelului, fara scara) din care se scoate cutia, in
##           locul celui masurat pe model: un GABARIT de contract, cand modelul vizual se schimba
##           dar coliziunea trebuie sa ramana cea masurata (masinile parcate San Francisco, valul
##           2: modelele GLB inlocuiesc placeholderul, iar contactele pasului 6 sunt pe cutiile
##           lui — tools/ProbeSfParked.tscn --boxes).
##   "shape" forma de coliziune, din `SHAPES`; implicit "box". Vezi constanta.
##   "pop"   viteza in sus (m/s) primita la primul contact cu o masina; vezi `_pop`.
##   "bounce" cat sare piesa (0..1) in locul implicitului de 0,2: mingea de plaja, geamandura.
static func wrap(model: Node3D, opts: Dictionary = {}) -> BumpProp:
	# In editor (Track e @tool) nu: fara simulare, corpul ar fi doar zgomot in
	# arbore, iar scriptul asta nu ruleaza acolo.
	if Engine.is_editor_hint() or model == null or not model.is_inside_tree():
		return null
	var parent := model.get_parent()
	if parent == null:
		return null
	if model.get_tree().get_nodes_in_group(&"bump_props").size() >= MAX_PER_TRACK:
		return null
	# Marimea PROPRIE a piesei (doar cu scara ei): `model_aabb` include
	# transformul radacinii, iar o masa de 1,5 m rotita la 45° ar iesi de 2,1 m.
	var saved := model.transform
	model.transform = Transform3D(Basis.from_scale(saved.basis.get_scale()),
		Vector3.ZERO)
	var aabb := Track.model_aabb(model)
	model.transform = saved
	if opts.has("box"):
		aabb = Transform3D(Basis.from_scale(saved.basis.get_scale()), Vector3.ZERO) * (opts["box"] as AABB)
	var max_foot := float(opts.get("max_footprint", MAX_FOOTPRINT_M))
	var max_h := float(opts.get("max_height", MAX_HEIGHT_M))
	if aabb.size.y <= 0.01 or aabb.size.y > max_h \
			or maxf(aabb.size.x, aabb.size.z) > max_foot:
		return null
	var body := BumpProp.new()
	body.name = "%s_bump" % model.name
	parent.add_child(body)
	# Corpul preia pozitia si ROTATIA modelului; scara ramane pe model (un corp
	# rigid scalat are fizica gresita).
	var g := model.global_transform
	body.global_transform = Transform3D(g.basis.orthonormalized(), g.origin)
	model.reparent(body, true)
	body._setup(model, opts)
	return body


func _setup(model: Node3D, opts: Dictionary = {}) -> void:
	add_to_group(&"bump_props")
	collision_layer = LAYER
	# Lumea si masinile (stratul 1) + celelalte piese bump-abile.
	collision_mask = 1 | LAYER
	# Cutia se masoara in spatiul CORPULUI: modelul e copilul lui acum.
	var aabb := Track.model_aabb(model)
	if opts.has("box"):
		aabb = model.transform * (opts["box"] as AABB)
	var kind := String(opts.get("shape", "box"))
	if not SHAPES.has(kind):
		push_warning("BumpProp %s: forma necunoscuta '%s', ramane cutie" % [name, kind])
		kind = "box"
	# Putin sub vizual, ca sa nu se agate de colturi invizibile, si cu talpa
	# ridicata cu SPAWN_LIFT_M: piesele sunt asezate pe teren cu talpa la cota
	# solului, iar pe o panta sau langa o vecina cutia intra cativa cm in ele.
	# Solverul o scotea afara la nastere, o trezea, si teancul de oale de la
	# capatul randului din Cappadocia aluneca 1,38 m singur (ProbeBumpProps).
	var height := maxf(aabb.size.y - SPAWN_LIFT_M, aabb.size.y * 0.5)
	var shape := CollisionShape3D.new()
	shape.position = aabb.get_center() + Vector3(0.0, (aabb.size.y - height) * 0.5, 0.0)
	match kind:
		"cylinder":
			# Raza INTREAGA, nu 85% ca la cutie: piesa e rotunda, deci n-are colturi
			# invizibile, iar o raza mai mica ar ingropa butoiul in sol cand ruleaza culcat.
			var cyl := CylinderShape3D.new()
			cyl.radius = (aabb.size.x + aabb.size.z) * 0.25
			cyl.height = height
			shape.shape = cyl
		"sphere":
			var ball := SphereShape3D.new()
			ball.radius = (aabb.size.x + aabb.size.y + aabb.size.z) / 6.0
			shape.shape = ball
			shape.position = aabb.get_center()
		"hull":
			var hull := _hull_shape(model)
			if hull == null:
				kind = "box"
			else:
				shape.shape = hull
				shape.position = Vector3.ZERO
	if kind == "box":
		var box := BoxShape3D.new()
		var foot := Vector2(aabb.size.x, aabb.size.z) * 0.85
		box.size = Vector3(foot.x, height, foot.y)
		shape.shape = box
	add_child(shape)
	_rolls = kind != "box"
	# Centrul de masa: la mijlocul formei, nu in originea corpului (talpa modelului). La
	# infasuratoare il calculeaza Jolt din forma — conul il are jos, la un sfert din inaltime.
	if kind != "hull":
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = shape.position
	mass = clampf(aabb.size.x * aabb.size.y * aabb.size.z * 0.5 * DENSITY,
		MIN_MASS, MAX_MASS)
	if opts.has("mass"):
		mass = float(opts["mass"])
	_home_back = bool(opts.get("home", false))
	_pop = maxf(0.0, float(opts.get("pop", 0.0)))
	if _pop > 0.0:
		contact_monitor = true
		max_contacts_reported = 2
		body_entered.connect(_on_body_entered)
	var mat := PhysicsMaterial.new()
	# 0,35, nu 0,7: un teanc inalt de 4 kg lovit jos se rastoarna peste capota
	# si, cu frecare mare, se freca sub caroserie — masina cadea de la 13 la
	# 5,8 m/s pe o oala (ProbeBumpProps, Cappadocia). La 0,35 pierde ~20%.
	mat.friction = 0.35
	mat.bounce = clampf(float(opts.get("bounce", 0.2)), 0.0, 1.0)
	physics_material_override = mat
	linear_damp = ROLL_LINEAR_DAMP if _rolls else 0.3
	angular_damp = ROLL_ANGULAR_DAMP if _rolls else 0.6
	_spawn_y = global_position.y
	# Aschii si praf la lovitura (things-fly): managerul comun, nu noduri proprii.
	PropDebris.watch(self)
	sleeping = true
	set_physics_process(false)
	sleeping_state_changed.connect(func() -> void:
		set_physics_process(not sleeping)
		if _home_back and sleeping:
			_home_after_rest())
	# Adormirea ceruta inainte ca corpul sa ajunga in spatiul fizic nu tine:
	# masurat, la primul pas piesele erau TREZE — pe teren plat stateau, pe
	# panta din piata Goreme alunecau pana la 1,7 m fara sa le atinga nimeni.
	# Se reaplica dupa primul pas de fizica, cand corpul exista in Jolt.
	get_tree().physics_frame.connect(func() -> void:
		_home = global_transform
		sleeping = true, CONNECT_ONE_SHOT)


func _on_body_entered(body: Node) -> void:
	if not _pop_ready or not body.is_in_group(&"cars"):
		return
	_pop_ready = false
	var v := linear_velocity
	v.y = maxf(v.y, _pop)
	linear_velocity = v
	get_tree().create_timer(POP_COOLDOWN_S).timeout.connect(func() -> void: _pop_ready = true)


## O singura infasuratoare convexa peste toate mesh-urile VIZIBILE ale modelului, in spatiul
## corpului (modelul e copilul lui). Null daca modelul n-are varfuri.
static func _hull_shape(model: Node3D) -> ConvexPolygonShape3D:
	var pts := PackedVector3Array()
	for entry in TrackDecor.visible_meshes(model, model.transform):
		var mi: MeshInstance3D = entry[0]
		var xform: Transform3D = entry[1]
		var src := mi.mesh.create_convex_shape(true, false) as ConvexPolygonShape3D
		if src == null:
			continue
		for p in src.points:
			pts.append(xform * p)
	if pts.size() < 4:
		return null
	var hull := ConvexPolygonShape3D.new()
	hull.points = pts
	return hull


## Piesa cu `home`: la 5 s dupa ce a adormit, daca s-a mutat si nicio masina nu e la mai putin de
## 30 m, se intoarce la locul ei (transformarea de la nastere), nemiscata. Altfel reincearca.
func _home_after_rest() -> void:
	if _home_pending or _home == Transform3D.IDENTITY:
		return
	if global_position.distance_to(_home.origin) < 0.4:
		return
	_home_pending = true
	get_tree().create_timer(HOME_DELAY_S).timeout.connect(_try_home)


func _try_home() -> void:
	_home_pending = false
	if not is_inside_tree() or not sleeping:
		return # s-a trezit din nou: adormirea urmatoare reporneste numaratoarea
	for c in get_tree().get_nodes_in_group(&"cars"):
		if (c as Node3D).global_position.distance_to(global_position) < HOME_CLEAR_M:
			_home_pending = true
			get_tree().create_timer(HOME_DELAY_S).timeout.connect(_try_home)
			return
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = _home
	sleeping = true


## Ruleaza doar cat corpul e treaz: piesa aruncata peste o faleza se sterge
## cand iese din lume, ca sa nu cada la infinit pe solver.
func _physics_process(delta: float) -> void:
	if global_position.y < _spawn_y - LOST_BELOW_M:
		queue_free()
		return
	if not _rolls:
		return
	var v2 := linear_velocity.length_squared()
	linear_damp = ROLL_REST_DAMP if v2 < ROLL_REST_SPEED * ROLL_REST_SPEED else ROLL_LINEAR_DAMP
	if v2 >= SETTLE_SPEED * SETTLE_SPEED:
		_settle_t = 0.0
		return
	_settle_t += delta
	if _settle_t >= SETTLE_S:
		_settle_t = 0.0
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		sleeping = true
