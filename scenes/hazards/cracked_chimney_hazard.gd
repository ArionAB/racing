@tool
class_name CrackedChimneyHazard
extends Node3D
## HORNUL CRAPAT CARE SE PRABUSESTE IN RAMPA (Cappadocia, brief §2 POI D).
##
## Gimmick-ul canionului rosu. Trei stari, doua tranzitii, o singura data pe
## cursa:
##
##   IN PICIOARE  `Cracked_Chimney_A`  16 m, in mijlocul drumului — zid
##   (telegraf)                        2 s: praf, pietricele, tremur
##   RAMPA        `Cracked_Chimney_B`  culcat, cu banda de rulare pe spate
##
## Molozul (`Cracked_Chimney_C`) apare langa rampa odata cu caderea: e partea
## in care aterizezi daca ratezi rampa. Grip-ul lui de 0.8x NU se da de aici,
## ci din `custom_loose_ranges` pe pista — suprafata e o proprietate a soselei,
## nu a hazardului, si asa se tuneaza in acelasi loc cu cenusa Stromboli.
##
## ############################################################################
## DECIZIA DE CICLU — luata explicit, nu strecurata.
##
## Brief-ul §3 lasa dezvoltatorului alegerea intre doua reguli si spune ca a
## doua e mai onesta. Aici e implementata **A DOUA: o data pe cursa, la moment
## fix** — hornul cade cand se apropie PRIMA masina (turul 1) si ramane rampa
## pana la finalul cursei.
##
## De ce asta si nu ciclul strict de ~40 s:
##   - contractul de hazard al proiectului (Chongqing §2) cere ca un obstacol
##     sa fie INVATABIL. Un horn care se reface la 40 s e invatabil intre
##     tururi, dar la 3 tururi de ~74 s faza cade de fiecare data altundeva —
##     adica exact "surpriza", care in ref_notes/sisteme.md e taxa, nu decizie;
##   - o stanca de 16 m care se reface din moloz ar fi singurul lucru din lume
##     care se dezasambleaza si se reasambleaza la vedere. Restul ceasurilor
##     pistei (baloane, piatra de moara, arzator) sunt lucruri care se MISCA,
##     nu care invie.
##
## Ce ar costa alternativa (ciclul strict de ~40 s), daca dezvoltatorul o cere:
##   - inca o stare (moloz -> horn refacut) si un ceas: `_phase` in loc de
##     `_state` terminal, vreo 30 de linii aici;
##   - un al patrulea mesh (hornul care se ridica) SAU animatia inversa a
##     caderii, care la 16 m se citeste fals;
##   - la 3 tururi x ~74 s jucatorul ar prinde hornul in picioare de ~2 ori din
##     3 treceri, dar niciodata la aceeasi fractie — deci decizia "incetinesc
##     si ocolesc / astept si sar" n-ar mai fi repetabila intre curse.
## Codul e acelasi in ambele variante pana la starea terminala, deci decizia se
## poate intoarce ieftin.
## ############################################################################

## Cat tine telegraful (secunde) — brief §2 POI D cere 2 s.
const TELEGRAPH: float = 2.0
## Cat dureaza caderea propriu-zisa.
const FALL: float = 0.85
## De la ce distanta in fata hornului porneste telegraful.
## 2 s de telegraf la ~28 m/s inseamna ca masina trebuie anuntata de la ~56 m;
## sub atat, hornul cade in fata ei fara ca ea sa poata decide nimic.
const TRIGGER_DIST: float = 62.0

## Numele nodurilor de stare. Sunt CONTRACT cu asset-ul: un nume gresit cade
## tacut pe "niciun mesh vizibil", nu pe eroare (avertismentul din okinawa_kit).
@export var standing_node: String = "Cracked_Chimney_A"
@export var ramp_node: String = "Cracked_Chimney_B"
@export var rubble_node: String = "Cracked_Chimney_C"

## Cat de mult se inclina hornul cat cade, in grade. Rampa are propria ei
## geometrie (banda de rulare sapata in spate), deci hornul in picioare doar SE
## CULCA pana dispare; nu incearca sa devina rampa prin rotatie.
@export_range(0.0, 120.0, 1.0) var fall_degrees: float = 92.0

## In ce sens cade, in spatiul LOCAL al nodului: +1 = spre +X, -1 = spre -X.
## Nodul e orientat cu -Z pe directia drumului, deci +1 = spre dreapta soferului.
@export_enum("Dreapta:1", "Stanga:-1") var fall_side: int = 1

signal toppled

var _standing: Node3D
var _ramp: Node3D
var _rubble: Node3D
## 0 = in picioare, 1 = telegraf, 2 = cade, 3 = rampa (terminal)
var _state: int = 0
var _clock: float = 0.0
var _dust: GPUParticles3D
var _trigger: Area3D


func _ready() -> void:
	_standing = _find(self, standing_node)
	_ramp = _find(self, ramp_node)
	_rubble = _find(self, rubble_node)
	for want: String in [standing_node, ramp_node, rubble_node]:
		if _find(self, want) == null:
			push_warning("CrackedChimneyHazard: lipseste nodul '%s'" % want)
	_apply()
	# Nimic de rulat pana nu vine cineva: ceasul porneste din zona.
	set_physics_process(false)
	if not Engine.is_editor_hint():
		_build_trigger()


## Zona care porneste telegraful.
##
## Un Area3D, nu o cautare de masini pe cadru: asa se face in tot restul
## proiectului (fumarola, kickerul, tromba), si tot asa hazardul nu trebuie sa
## stie nimic despre cine conduce. PRIMA masina care intra il darama —
## jucatorul sau un AI, fiindca hornul e o proprietate a lumii, exact ca lava
## de pe Stromboli, care creste pe turul liderului, nu pe al tau.
##
## Sfera e centrata pe horn si are raza `TRIGGER_DIST`, deci prinde masina si
## cand vine pe ocolul din dreapta — hornul nu trebuie sa cada doar in fata
## celui care tinteste rampa.
func _build_trigger() -> void:
	_trigger = Area3D.new()
	_trigger.name = "Declansator"
	# Doar masinile: monitorizeaza corpuri, nu alte zone.
	_trigger.monitorable = false
	var shape := SphereShape3D.new()
	shape.radius = TRIGGER_DIST
	var cs := CollisionShape3D.new()
	cs.shape = shape
	_trigger.add_child(cs)
	_trigger.body_entered.connect(_on_body_entered)
	add_child(_trigger)


func _on_body_entered(body: Node3D) -> void:
	if _state != 0 or (body as Car) == null:
		return
	_state = 1
	_clock = 0.0
	_start_dust()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _state:
		1:
			_clock += delta
			# Tremurul creste spre sfarsit (t^2): primul sfert e doar praf,
			# ultimul se vede. Amplitudinea ramane mica dinadins — un horn de
			# 16 m care se leagana 30 cm arata din cauciuc.
			if _standing != null:
				var t := _clock / TELEGRAPH
				var amp := 0.10 * t * t
				_standing.position = Vector3(
					sin(_clock * 37.0) * amp, 0.0, cos(_clock * 31.0) * amp)
			if _clock >= TELEGRAPH:
				_state = 2
				_clock = 0.0
				if _standing != null:
					_standing.position = Vector3.ZERO
		2:
			_clock += delta
			var t2 := clampf(_clock / FALL, 0.0, 1.0)
			# Cadere ACCELERATA (t^2): o stanca care se culca in viteza
			# constanta se citeste ca usa, nu ca prabusire.
			if _standing != null:
				_standing.rotation.z = deg_to_rad(
					-fall_degrees * t2 * t2 * float(fall_side))
			if t2 >= 1.0:
				_state = 3
				_apply()
				_stop_dust()
				toppled.emit()
				# Starea e terminala (vezi decizia de ciclu din antet): nu mai
				# e nimic de numarat, iar zona nu mai are pe cine sa anunte.
				set_physics_process(false)
				if _trigger != null:
					_trigger.queue_free()
					_trigger = null


## O singura stare vizibila. Variantele stinse nu intra in numaratoarea garzii
## (`probe_decor` numara doar ce se randeaza), deci stau toate in scena.
func _apply() -> void:
	var fallen := _state >= 3
	if _standing != null:
		_standing.visible = not fallen
	if _ramp != null:
		_ramp.visible = fallen
	if _rubble != null:
		_rubble.visible = fallen
	if not Engine.is_editor_hint():
		_rebuild_collision()


## Colizorul urmeaza starea, si e TOT aici — din exact motivul scris in
## [LavaFlowHazard]: `world_prop` construieste corpurile o data, la `_ready`,
## pentru mesh-urile vizibile ATUNCI, iar copilul GLB isi face `_ready`
## inaintea parintelui care stinge starile. Corpul rampei ar fi existat
## invizibil din primul tur, adica un zid pe mijlocul drumului inainte de orice
## cadere. De aceea cele trei modele sunt "none" in `world_prop.PROP_COLLISION`.
##
## Hornul in picioare e HULL (e un zid, si asa trebuie sa se simta). Rampa si
## molozul sunt TRIMESH: pe ele se CIRCULA, iar un hull convex peste hornul
## culcat ar fi o prisma plina care ar sterge chiar banda de rulare sapata in
## spatele lui.
func _rebuild_collision() -> void:
	_body_for(_standing, "hull", _standing != null and _standing.visible)
	_body_for(_ramp, "mesh", _ramp != null and _ramp.visible)
	_body_for(_rubble, "mesh", _rubble != null and _rubble.visible)


func _body_for(model: Node3D, mode: String, want: bool) -> void:
	if model == null:
		return
	var body := model.get_node_or_null("state_col") as StaticBody3D
	if want and body == null:
		body = StaticBody3D.new()
		body.name = "state_col"
		body.set_meta("mod_coliziune", mode)
		var ok := false
		if mode == "mesh":
			ok = _add_trimesh(body, model)
		else:
			ok = TrackDecor.add_hull_collision(body, model, true)
		if not ok:
			body.free()
			return
		model.add_child(body)
	elif not want and body != null:
		body.queue_free()


## Trimesh in spatiul MODELULUI (corpul e copilul lui), deci forma nu depinde
## de cum e rotit sau scalat nodul in scena.
func _add_trimesh(body: StaticBody3D, model: Node3D) -> bool:
	var added := false
	for entry in TrackDecor.visible_meshes(model, Transform3D.IDENTITY):
		var mi: MeshInstance3D = entry[0]
		var xform: Transform3D = entry[1]
		if mi.mesh == null:
			continue
		var shape := mi.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var faces := shape.get_faces()
		var moved := PackedVector3Array()
		moved.resize(faces.size())
		for i in faces.size():
			moved[i] = xform * faces[i]
		var cshape := ConcavePolygonShape3D.new()
		cshape.set_faces(moved)
		var cs := CollisionShape3D.new()
		cs.shape = cshape
		body.add_child(cs)
		added = true
	return added


## Praful telegrafului. Count mic (constrangerea mobila din CLAUDE.md), si pe
## materialul lumii — deci nu adauga nimic la garda de materiale.
func _start_dust() -> void:
	if _dust != null:
		return
	_dust = GPUParticles3D.new()
	_dust.amount = 24
	_dust.lifetime = 1.6
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 55.0
	mat.initial_velocity_min = 0.8
	mat.initial_velocity_max = 2.6
	mat.gravity = Vector3(0, -3.2, 0)
	mat.scale_min = 0.25
	mat.scale_max = 0.75
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 2.6
	mat.color = Palette.color(Palette.CORAL_SAND)
	_dust.process_material = mat
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.5, 0.5)
	_dust.draw_pass_1 = mesh
	_dust.material_override = Palette.world_material()
	_dust.position = Vector3(0, 1.2, 0)
	add_child(_dust)


func _stop_dust() -> void:
	if _dust == null:
		return
	_dust.emitting = false
	var d := _dust
	_dust = null
	get_tree().create_timer(2.0, false).timeout.connect(
		func() -> void:
			if is_instance_valid(d):
				d.queue_free())


func _find(node: Node, want: String) -> Node3D:
	if want.is_empty():
		return null
	for child in node.get_children():
		if child.name == want and child is Node3D:
			return child as Node3D
		var deep := _find(child, want)
		if deep != null:
			return deep
	return null
