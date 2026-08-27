@tool
class_name MonorailHazard
extends Node3D
## Monorailul de la Liziba (Chongqing, brief §2 POI G si §3): garnitura trece
## la interval fix peste sosea, pe grinda ei, si contactul te ARUNCA — nu te
## distruge.
##
## [b]E [TrainHazard] cu doua schimbari, si amandoua sunt de fond.[/b]
##
##  1. [b]Traseul e un [Path3D], nu o dreapta.[/b] Trenul de pe Dune taie
##     soseaua perpendicular pe o sina dreapta; monorailul din Chongqing intra
##     printr-un bloc si iese pe partea cealalta, deci traseul e desenat, nu
##     parametrizat. Curba se pune ca nod copil („Route") si se trage de ea in
##     editor — acelasi tipar ca traseul de rockfall.
##  2. [b]Pedeapsa e ARUNCAREA, nu repunerea.[/b] `TrainHazard` face
##     `race_active = false` + `respawn()`: te scoate din cursa 0.9 s si te
##     pune inapoi. Aici nu exista niciun moment in care jucatorul nu-si
##     conduce masina. Masa mare a garniturii se traduce intr-o aruncare
##     ([HazardThrow]): viteza orizontala e SCRISA (a ta, taiata, plus
##     impinsul trenului), inaltimea trece prin `Car.launch` si e ceruta in
##     METRI, iar garnitura primeste o exceptie de coliziune cat tine zborul.
##     Aterizezi cu ~12 m si o pozitie pierdute, dar volanul a fost al tau tot
##     timpul.
##
##     Aruncarea are un PLAFON, si el e chiar contractul: `side_push` +
##     `throw_height` decid unde aterizezi, iar aterizarea trebuie sa fie pe
##     sosea sau pe umarul ei. Prima versiune aduna un ghiont de 26 m/s la
##     viteza masinii si criticul a masurat rezultatul — 62.75 m lateral, sub
##     cota soselei, masina nemiscata de la t=7 la t=42. Pe POI G, unde orasul
##     e SUB drum, „aruncat departe" nu e o pedeapsa, e o iesire din lume.
##
## De ce nu repunere: pe Chongqing traseul trece PESTE alte benzi (brief §2), si
## o repunere „cu 20 m in spate" pe un nod cu trei etaje suprapuse e o loterie
## de etaj. Un ghiont e local si nu are cum sa te mute pe alt nivel.
##
## [b]Bariera e TEATRU[/b] (cerinta din brief). `crossing_barrier.glb` isi
## coboara brațul (nodul „Boom", pe un pivot la 1.55 m), clopotelul bate si
## luminile clipesc — dar brațul NU are colizor. Cine il ignora nu se opreste
## in el: trece prin el si intra sub garnitura. Pedeapsa e trenul, iar bariera
## e doar cea care ti-a spus.
##
## [b]Grinda ramane joasa peste sosea[/b]. Un monorail adevarat isi poarta
## grinda la 8 m, dar peste carosabil aia ar fi un tunel; aici grinda e o dala
## de 22 cm cu umeri in panta, adica se trece peste ea ca peste o sina de
## tramvai. Memoria `suprafete-cu-goluri-si-praguri`: un prag lateral peste
## 0.3 m e zid, iar raza rotii cade in orice gol.

const WorldProp = preload("res://scenes/props/world_prop.gd")
const TRAIN_MODEL: String = "res://assets/models/chongqing/vehicles/monorail_train.glb"
const BARRIER_MODEL: String = "res://assets/models/chongqing/props/crossing_barrier.glb"
const BOOM_NODE := "Boom"
## Gabaritul garniturii din GLB (3 vagoane, originea la baza).
const TRAIN_SIZE := Vector3(2.96, 4.51, 27.28)
## Inaltimea pivotului brațului pe stalp (docs/asset_briefs/chongqing_inventory.md).
const BOOM_PIVOT_Y: float = 1.55
## Profilul grinzii peste sosea: lata cat sa poarte garnitura, joasa cat sa se
## poata trece peste ea.
const BEAM_TOP: float = 0.22
const BEAM_HALF: float = 1.15
## Cat de late sunt umerii in panta de pe langa grinda. Fara ei, marginea de
## 22 cm e un prag pe care roata il ia ca pe o treapta.
const BEAM_SHOULDER: float = 0.9
## Pasul de esantionare a traseului.
const ROUTE_STEP: float = 3.0
## Cat de departe de trecere mai are voie garnitura sa loveasca, peste
## semilatimea soselei (m).
const HIT_RANGE: float = 25.0

enum Phase {
	IDLE,      ## trenul e departe, drumul e liber
	WARNING,   ## clopotel, lumini, brațul coboara
	CROSSING,  ## garnitura trece
}

@export_group("Orar")
## Ciclul complet (s). Brief: ~35, si NU divizor al turului.
@export_range(8.0, 120.0, 0.5) var period: float = 35.0
## Cat inainte de sosirea garniturii incep clopotelul, luminile si coborarea
## brațului (s). Brief §3, contractul comun al hazardelor ciclice: 3.
@export_range(0.0, 10.0, 0.1) var warn_lead: float = 3.0
## Cat dureaza traversarea, din capat in capat de traseu (s).
@export_range(1.0, 30.0, 0.1) var cross_time: float = 6.0
## Decalajul ciclului (0..1 din period).
@export_range(0.0, 1.0, 0.01) var phase_offset: float = 0.0

@export_group("Geometrie")
## Semilatimea soselei in dreptul trecerii — pentru bariere si pentru fereastra
## in care garnitura are voie sa loveasca.
@export_range(2.0, 20.0, 0.5) var road_half_width: float = 7.0
## Lungimea traseului implicit, cand nodul n-are un `Path3D` copil (m de o
## parte si de alta a trecerii).
@export_range(20.0, 400.0, 5.0) var half_route: float = 110.0
## Pe ce parte a drumului stau barierele: +1 dreapta, -1 stanga. Se construiesc
## pe amandoua marginile; asta spune doar incotro se uita brațul.
@export_enum("Dreapta:1", "Stanga:-1") var barrier_side: int = 1
## Cat de sus e brațul cand trecerea e libera (grade fata de orizontala).
@export_range(30.0, 100.0, 1.0) var boom_up_deg: float = 88.0

@export_group("Lovitura")
## Cat de departe te impinge garnitura, pe directia ei de mers (m/s).
##
## [b]Nu se ADUNA la viteza ta, o INLOCUIESTE[/b] (vezi [HazardThrow]): masa
## garniturii e a doua ordine de marime fata de a masinii, deci viteza de dupa
## lovitura e a trenului. Adunarea a fost prima versiune si criticul a masurat
## unde duce: 26 m/s peste 30 m/s de mers = o masina ejectata 62.75 m in
## afara lumii, sub cota soselei, de unde nu mai pleca. Cifra e mica dinadins
## — impreuna cu `throw_height` ea decide unde ATERIZEZI, si aterizarea
## trebuie sa fie langa sosea, nu in oras: pe POI G orasul e SUB drum.
@export_range(0.0, 30.0, 0.5) var side_push: float = 9.0
## Cat de SUS te arunca (m). In metri, nu in m/s: cifra din inspector e chiar
## ce masoara sonda. Zborul trece prin `Car.launch`, care SETEAZA viteza
## verticala — o adunare se pierde in amortizorul suspensiei.
@export_range(0.0, 8.0, 0.05) var throw_height: float = 2.6
## Cat timp dupa lovitura garnitura nu mai are voie sa atinga masina (s).
##
## Fara asta, corpul solid al trenului rezolva patrunderea in cadrul urmator
## si aruncarea moare acolo: masurat vy 12 -> 0 in 0.13 s, cu o urcare de
## 0.45 m. Trebuie sa acopere zborul plus trecerea cozii garniturii.
@export_range(0.0, 6.0, 0.05) var clear_seconds: float = 2.2
## Invartirea VIZUALA a caroseriei dupa lovitura (rad/s) si cat tine (s).
@export_range(0.0, 20.0, 0.5) var spin_rate: float = 9.0
@export_range(0.0, 5.0, 0.1) var spin_seconds: float = 1.4
## Strivirea: scurta si blanda. Nu exista `race_active = false` si nu exista
## repunere — vezi antetul.
@export_range(0.0, 3.0, 0.05) var crush_seconds: float = 0.5
@export_range(0.3, 1.0, 0.01) var crush_factor: float = 0.8
## Cat din viteza ta orizontala ramane in zbor. Se aplica O SINGURA DATA, in
## aruncare — `Car.crush` primeste 1.0, altfel taietura s-ar aplica de doua ori
## si masina ar cadea din aer aproape pe loc.
@export_range(0.0, 1.0, 0.01) var keep_speed: float = 0.55
## Cat sta o masina imuna dupa o lovitura (s).
@export_range(0.05, 4.0, 0.05) var hit_cooldown: float = 1.5

@export_group("Constructie")
@export var train_model: PackedScene = null
@export var barrier_model: PackedScene = null
@export_range(0.2, 3.0, 0.05) var model_scale: float = 1.0
## Slotul de paleta al grinzii.
@export_range(0, 31) var beam_slot: int = Palette.CONCRETE

var _train: AnimatableBody3D
var _hit_zone: Area3D
var _booms: Array[Node3D] = []
var _lamps: Array[HazardLamp] = []
var _audio: AudioStreamPlayer3D
var _curve: Curve3D
var _time: float = 0.0
var _started: bool = false
var _phase: Phase = Phase.IDLE
var _cooldown: Dictionary = {}
var _last_bell: int = -1
var _train_dir: Vector3 = Vector3.RIGHT


func _ready() -> void:
	add_to_group("hazards")
	_curve = _route_curve()
	_build_beam()
	_build_train()
	_build_barriers()
	if not Engine.is_editor_hint():
		_audio = AudioStreamPlayer3D.new()
		_audio.bus = &"SFX"
		_audio.max_distance = 160.0
		add_child(_audio)
	_apply_cycle(1.0 / 60.0)


# ------------------------------------------------------------------- traseu

## Curba pe care merge garnitura: un `Path3D` copil daca exista, altfel o
## dreapta pe X local.
##
## Nodul copil e sursa de adevar cand exista, ca sa se poata trage de traseu in
## editor fara sa se atinga codul (acelasi tipar ca `RockfallHazard`).
func _route_curve() -> Curve3D:
	for c in get_children():
		var path := c as Path3D
		if path != null and path.curve != null and path.curve.point_count >= 2:
			return path.curve
	var curve := Curve3D.new()
	curve.add_point(Vector3(-half_route, 0.0, 0.0))
	curve.add_point(Vector3(half_route, 0.0, 0.0))
	return curve


func _route_length() -> float:
	return _curve.get_baked_length() if _curve != null else 1.0


## Punctul de pe traseu la distanta `d` de la inceput.
func _at(d: float) -> Vector3:
	return _curve.sample_baked(clampf(d, 0.0, _route_length()), true)


## Directia traseului la distanta `d`.
func _dir_at(d: float) -> Vector3:
	var a := _at(maxf(d - 0.5, 0.0))
	var b := _at(minf(d + 0.5, _route_length()))
	var v := b - a
	return v.normalized() if v.length_squared() > 1e-6 else Vector3.RIGHT


## Distanta pe traseu la care el trece cel mai aproape de axa soselei (adica
## de originea nodului). Din ea ies si orarul, si fereastra de lovire.
func _crossing_distance() -> float:
	var best := 0.0
	var best_d := INF
	var n := maxi(int(_route_length() / ROUTE_STEP), 8)
	for i in n + 1:
		var d := _route_length() * float(i) / float(n)
		var p := _at(d)
		var flat := Vector2(p.x, p.z).length()
		if flat < best_d:
			best_d = flat
			best = d
	return best


# --------------------------------------------------------------- constructie

## Grinda: o dala joasa cu umeri in panta, esantionata pe traseu.
func _build_beam() -> void:
	var body := StaticBody3D.new()
	body.name = "Beam"
	add_child(body)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := _route_length()
	var n := maxi(int(total / ROUTE_STEP), 2)
	for i in n:
		var d0 := total * float(i) / float(n)
		var d1 := total * float(i + 1) / float(n)
		var a := _at(d0)
		var b := _at(d1)
		var dir := b - a
		dir.y = 0.0
		if dir.length_squared() < 1e-6:
			continue
		dir = dir.normalized()
		var lat := Vector3(-dir.z, 0.0, dir.x)
		# Trei fasii: platoul si doi umeri care coboara la cota terenului.
		# Un singur bloc de 22 cm ar fi lasat doua praguri verticale exact pe
		# linia de rulare (memoria `suprafete-cu-goluri-si-praguri`).
		var top := Vector3.UP * BEAM_TOP
		_quad(st, body, a - lat * BEAM_HALF + top, a + lat * BEAM_HALF + top,
			b + lat * BEAM_HALF + top, b - lat * BEAM_HALF + top)
		for side: float in [-1.0, 1.0]:
			var inner := lat * (side * BEAM_HALF)
			var outer := lat * (side * (BEAM_HALF + BEAM_SHOULDER))
			_quad(st, body, a + inner + top, a + outer, b + outer, b + inner + top)
	var mi := PaletteBox.emit(st, "BeamMesh")
	if mi != null:
		body.add_child(mi)


func _quad(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3) -> void:
	PaletteBox.quad_slab(st, a, b, c, d, 0.35, beam_slot)
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = PackedVector3Array([a, b, c, d,
		a + Vector3.DOWN * 0.35, b + Vector3.DOWN * 0.35,
		c + Vector3.DOWN * 0.35, d + Vector3.DOWN * 0.35])
	shape.shape = hull
	body.add_child(shape)


func _build_train() -> void:
	_train = AnimatableBody3D.new()
	_train.name = "Train"
	_train.sync_to_physics = true
	add_child(_train)
	var size := TRAIN_SIZE * model_scale
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	# Originea modelului e la baza garniturii, deci colizorul urca de la grinda.
	col.position = Vector3(0.0, size.y * 0.5, 0.0)
	_train.add_child(col)

	var scene := train_model if train_model != null else load(TRAIN_MODEL) as PackedScene
	var inst: Node3D = scene.instantiate() as Node3D if scene != null else null
	if inst != null:
		inst.scale = Vector3.ONE * model_scale
		Palette.apply_object_class_materials(inst, WorldProp.prop_classes(), model_scale)
		_train.add_child(inst)
	else:
		_train.add_child(PaletteBox.instance(size, beam_slot,
			Vector3(0.0, size.y * 0.5, 0.0)))

	# Zona de lovire: putin mai grasa decat garnitura, ca sa prinda contactul
	# inainte ca solverul sa fi apucat sa impinga masina sub ea.
	_hit_zone = Area3D.new()
	_hit_zone.name = "HitZone"
	_hit_zone.monitorable = false
	var zs := CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = size + Vector3(2.4, 0.4, 1.6)
	zs.shape = zbox
	zs.position = col.position
	_hit_zone.add_child(zs)
	_train.add_child(_hit_zone)


## Barierele de trecere: stalp cu braț rotitor si lumini, pe ambele margini.
## Brațul NU primeste colizor — vezi antetul.
func _build_barriers() -> void:
	var scene := barrier_model if barrier_model != null else load(BARRIER_MODEL) as PackedScene
	var cross := _at(_crossing_distance())
	var dir := _dir_at(_crossing_distance())
	var lat := Vector3(-dir.z, 0.0, dir.x).normalized()
	for side: float in [-1.0, 1.0]:
		var at := cross + lat * (side * (road_half_width + 1.4))
		var holder := Node3D.new()
		holder.name = "Barrier%s" % ("L" if side < 0.0 else "R")
		holder.position = at
		# Stalpul se uita de-a lungul soselei, ca brațul sa cada peste banda.
		holder.basis = Basis.looking_at(lat * -side, Vector3.UP)
		add_child(holder)

		var post: Node3D = scene.instantiate() as Node3D if scene != null else null
		if post != null:
			post.scale = Vector3.ONE * model_scale
			Palette.apply_object_class_materials(post, WorldProp.prop_classes(),
				model_scale)
			# Brațul se desprinde din GLB si trece pe un pivot la cota lui de pe
			# stalp. `remove_child` INAINTE de `queue_free` nu e nevoie aici —
			# nodul nu se elibereaza, se muta.
			var boom := post.find_child(BOOM_NODE, true, false) as Node3D
			holder.add_child(post)
			if boom != null:
				boom.get_parent().remove_child(boom)
				var pivot := Node3D.new()
				pivot.name = "BoomPivot"
				pivot.position = Vector3(0.0, BOOM_PIVOT_Y * model_scale, 0.0)
				holder.add_child(pivot)
				pivot.add_child(boom)
				_booms.append(pivot)
		else:
			var fake := Node3D.new()
			fake.name = "BoomPivot"
			fake.position = Vector3(0.0, BOOM_PIVOT_Y, 0.0)
			holder.add_child(fake)
			fake.add_child(PaletteBox.instance(Vector3(5.0, 0.18, 0.18),
				Palette.KERB_RED, Vector3(2.2, 0.0, 0.0)))
			_booms.append(fake)

		var lamp := HazardLamp.new()
		lamp.name = "CrossingLights"
		lamp.slots = [Palette.KERB_RED]
		lamp.vertical = false
		lamp.housing_slot = -1
		holder.add_child(lamp)
		lamp.position = Vector3(0.0, 2.6 * model_scale, 0.0)
		_lamps.append(lamp)


# --------------------------------------------------------------------- ciclu

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _started:
		_started = true
		_time = phase_offset * period
	_time += delta
	_apply_cycle(delta)
	_tick_cooldowns(delta)
	if _phase == Phase.CROSSING:
		_hit_cars()


## Cate secunde mai sunt pana cand garnitura ajunge la trecere.
##
## Nu e „pana intra pe traseu": avertizarea trebuie sa masoare timpul pana la
## momentul in care conteaza, adica pana cand botul garniturii e pe asfalt.
func seconds_to_crossing() -> float:
	var t := fposmod(_time, period)
	var arrive := _arrival_time()
	return fposmod(arrive - t, period)


## Momentul din ciclu la care botul garniturii ajunge la trecere.
func _arrival_time() -> float:
	var frac := _crossing_distance() / maxf(_route_length(), 0.01)
	return warn_lead + cross_time * frac


func _apply_cycle(_delta: float) -> void:
	var t := fposmod(_time, period)
	var start := 0.0
	var end := warn_lead + cross_time
	if t < warn_lead:
		_phase = Phase.WARNING
	elif t < end:
		_phase = Phase.CROSSING
	else:
		_phase = Phase.IDLE

	if _train != null:
		if _phase == Phase.CROSSING:
			var k := (t - warn_lead) / maxf(cross_time, 0.01)
			var total := _route_length()
			var half := TRAIN_SIZE.z * 0.5 * model_scale
			# Garnitura intra cu botul de la 0 si iese cu coada la capat.
			var d := lerpf(-half, total + half, k)
			var at := _at(clampf(d, 0.0, total))
			_train_dir = _dir_at(clampf(d, 0.0, total))
			# O SINGURA scriere de transform pe cadru (memoria
			# `jolt-sync-transform-o-singura-scriere`).
			_train.global_transform = Transform3D(
				Basis.looking_at(_train_dir, Vector3.UP),
				to_global(at + Vector3.UP * BEAM_TOP))
			_train.visible = true
		else:
			# Parcata SUB lume, nu doar departe: lectia din `TrainHazard` —
			# o garnitura parcata pe traseu ramane un perete invizibil acolo
			# unde soseaua se intoarce.
			_train.global_transform = Transform3D(Basis.IDENTITY,
				to_global(Vector3(0.0, -300.0, 0.0)))
			_train.visible = false

	_tick_booms(t)
	_tick_lamps(t)
	if not Engine.is_editor_hint():
		_tick_audio(t)


## Avertizarea e ancorata in SOSIRE, nu in intrarea pe traseu.
##
## Prima versiune pornea brațul la t = 0, adica `warn_lead` inainte ca
## garnitura sa intre pe traseu — dar traseul e lung, iar trecerea e pe la
## mijlocul lui, deci sonda a masurat un telegraph de 5.95 s pentru unul cerut
## de 3. Contractul din brief e despre momentul care conteaza pentru sofer:
## cu cat inainte sa-i ajunga trenul in fata i se spune. Cat traseu mai are de
## strabatut garnitura pana acolo e treaba hazardului, nu a jucatorului.
func _warning_on(t: float) -> bool:
	return t < warn_lead + cross_time and _arrival_time() - t <= warn_lead


## Brațul coboara pe durata avertizarii si se ridica dupa ce garnitura a iesit.
func _tick_booms(t: float) -> void:
	var end := warn_lead + cross_time
	var down := 0.0
	if t < end:
		var to_arrival := _arrival_time() - t
		if to_arrival <= 0.0:
			down = 1.0
		else:
			# Coborarea se termina inainte de sosire (in 70% din avertizare):
			# o bariera care se aseaza fix cand trece trenul n-a avertizat pe
			# nimeni. Telegraph-ul INCEPE la 3 s, brațul e jos pe la 0.9 s.
			down = clampf((warn_lead - to_arrival) / maxf(warn_lead * 0.7, 0.01),
				0.0, 1.0)
	else:
		var after := t - end
		down = clampf(1.0 - after / maxf(warn_lead, 0.01), 0.0, 1.0)
	# Brațul din GLB e orizontal pe +X; rotit cu +90° pe Z arata in sus.
	var angle := deg_to_rad(boom_up_deg) * (1.0 - down)
	for pivot in _booms:
		pivot.rotation.z = angle


func _tick_lamps(t: float) -> void:
	var blink := _warning_on(t) and fmod(t, 0.5) < 0.25
	for lamp in _lamps:
		lamp.blink(0, blink)


func _tick_audio(t: float) -> void:
	if not _warning_on(t):
		_last_bell = -1
		return
	var bell := int(t / 0.6)
	if bell != _last_bell:
		_last_bell = bell
		var stream := AudioManager.stream(&"crossing_bell")
		if stream != null and _audio != null:
			_audio.stream = stream
			_audio.play()


# ------------------------------------------------------------------ lovitura

func _tick_cooldowns(delta: float) -> void:
	# Netipat dinadins: `for car: Car in` ar atribui si cheile deja eliberate
	# intr-o variabila tipata, si chiar atribuirea da „previously freed
	# instance" (nota din TrainHazard._tick_cooldowns).
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
	if _hit_zone == null:
		return
	for body in _hit_zone.get_overlapping_bodies():
		var car := body as Car
		if car == null or _cooldown.has(car):
			continue
		# Doar la TRECEREA propriu-zisa: pe o pista care se intoarce in ea
		# insasi, grinda poate trece a doua oara pe langa alt etaj de asfalt,
		# fara bariere si fara clopot. Lectia lui `TrainHazard._hit_cars`.
		if car.global_position.distance_to(crossing_point()) 				> road_half_width + HIT_RANGE:
			continue
		_cooldown[car] = hit_cooldown
		# Viteza de dupa lovitura: ce ti-a mai ramas din a ta, plus impinsul
		# garniturii pe directia ei. Se SCRIE (vezi [HazardThrow]) — cu o
		# adunare, aruncarea devine ejectare in afara hartii.
		var mine := Vector3(car.velocity.x, 0.0, car.velocity.z) * keep_speed
		var horizontal := mine + _train_dir * side_push
		HazardThrow.throw(car, _train, horizontal, throw_height, clear_seconds)
		var sign := signf(_train_dir.cross(Vector3.UP).dot(
			-car.global_transform.basis.z))
		car.spin_body(spin_rate * (sign if absf(sign) > 0.01 else 1.0),
			spin_seconds)
		# Strivire SCURTA, si nimic altceva: fara `race_active = false`, fara
		# repunere. `keep_speed` e 1.0 aici — taietura de viteza s-a facut deja
		# in aruncare, iar aplicata a doua oara ar opri masina in aer.
		car.crush(crush_seconds, crush_factor, Vector3(1.3, 0.7, 1.3), 1.0)


# ---------------------------------------------------------- pentru sonde

func phase() -> Phase:
	return _phase


func cycle_time() -> float:
	return fposmod(_time, period)


## Cat de coborat e brațul: 0 = ridicat (liber), 1 = culcat peste banda.
func boom_down() -> float:
	if _booms.is_empty():
		return 0.0
	return 1.0 - _booms[0].rotation.z / deg_to_rad(boom_up_deg)


func lights_on() -> bool:
	for lamp in _lamps:
		if lamp.lit() == 0:
			return true
	return false


func train_body() -> AnimatableBody3D:
	return _train


func crossing_point() -> Vector3:
	return to_global(_at(_crossing_distance()))


func route_length() -> float:
	return _route_length()


func arrival_time() -> float:
	return _arrival_time()
