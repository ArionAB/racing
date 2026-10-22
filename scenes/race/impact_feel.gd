extends Node
## Reactia camerei si a timpului la izbituri (docs/feel_checklist.md:
## hitstop-shake, who-hit-me, player-big-ai-small).
##
## Asculta UN singur semnal, `Car.impact` al jucatorului (feed-ul comun), si
## decide ce simte jucatorul:
##   - camera e IMPINSA in sensul loviturii (`ChaseCamera.kick`), nu doar scuturata
##     la intamplare; pe margini, un flash scurt din partea loviturii;
##   - la izbituri mari, hit-stop (`HitStop`) cu durata proportionala;
##   - cine a lovit pe cine: jucatorul care loveste simte TARE (kick complet +
##     hit-stop), cel lovit de un AI simte MIC (kick plafonat, fara hit-stop) —
##     imbranceala e o mecanica pe care o castigi, nu o pedeapsa.
##
## De ce un nod separat: race.gd are deja prea multe lambda-uri de feedback, iar
## logica asta (istoric de viteze, atacator, cooldown) se verifica izolat, intr-o
## sonda fara pista (tools/probe_impact_camera.gd).
##
## Fara sunet: partea audio a acestor itemi vine separat.

const HitStopScript := preload("res://scenes/race/hit_stop.gd")

# --- lovitura de camera ---
## Metri de impingere a camerei pe m/s de schimbare de viteza.
@export var kick_per_mps: float = 0.07
## Plafonul unei singure lovituri (m). Camera e la 12.5 m de masina: sub ~0.3 m
## abia se vede, la 1.2 m se simte ca o izbitura plina.
@export var kick_max: float = 1.2
## Ruliul loviturii (grade pe m/s) si plafonul lui.
@export var roll_deg_per_mps: float = 0.18
@export var roll_deg_max: float = 3.0
## Zgomotul (trauma) care insoteste kick-ul la lovituri intre masini, pe m/s.
## Mic: izbitura trebuie sa fie mai ales DIRECTIONALA.
@export var car_trauma_base: float = 0.08
@export var car_trauma_per_mps: float = 0.025
@export var car_trauma_max: float = 0.4

# --- hit-stop ---
## De la ce schimbare de viteza (m/s) se ingheata lumea.
@export var hitstop_min_strength: float = 9.0
## La ce schimbare de viteza se atinge durata maxima.
@export var hitstop_full_strength: float = 20.0
@export var hitstop_min_ms: float = 40.0
@export var hitstop_max_ms: float = 90.0

# --- cine a lovit pe cine ---
## Din ce parte din "apropierea totala" pe linia de contact trebuie sa vina
## jucatorul ca sa conteze atacator. 0.4, nu 0.5: la o ciocnire frontala
## aproape egala jucatorul ramane atacatorul (mecanica e a lui).
@export var attacker_share_min: float = 0.4
## Cand lovitura vine de la un AI: fractia din kick-ul normal si plafonul lui (m).
@export var victim_kick_scale: float = 0.45
@export var victim_kick_cap: float = 0.4
## Cand te loveste un hazard mobil (barierele, autobuzul): kick aproape plin, fara
## hit-stop. Lumea nu "joaca" impotriva ta ca un adversar, dar impingerea trebuie
## sa se vada de unde vine; nu o plafonam ca pe cea de la AI.
@export var hazard_kick_scale: float = 0.8
## Din cat din schimbarea de viteza trebuie sa fi venit apropierea jucatorului ca
## sa fi lovit el un corp mobil (hazard): izbit intr-un perete, aproape tot dv e al
## tau; maturat de o bariera in timp ce stai, aproape nimic.
@export var hazard_attacker_share: float = 0.4
## Si trauma, la fel (fractie).
@export var victim_trauma_scale: float = 0.5

# --- flash de margine (who-hit-me) ---
## Alfa pe m/s de schimbare de viteza, si plafonul. Scurt si discret: arata DIN
## ce parte a venit lovitura, nu acopera cadrul.
@export var flash_per_mps: float = 0.035
@export var flash_max: float = 0.5

var player: Car
var camera: ChaseCamera
var vignette: Vignette
var hit_stop: HitStopScript
## Pe ce fel de curse suntem: hit-stop-ul nu exista in numaratoare inversa si
## dupa final. Implicit mereu activ (sondele nu au Race).
var racing: Callable = func() -> bool: return true

## Ultima decizie, pentru sonde si depanare.
var last_player_attacker: bool = true
var last_kick: float = 0.0
var last_share: float = 1.0

var _cars: Array[Car] = []
var _vel_now: Dictionary = {}
var _vel_prev: Dictionary = {}


func _init() -> void:
	# Inaintea masinilor (prioritate 0): vitezele din `_vel_prev` sunt cele de
	# DINAINTE de impact — vezi `_snapshot`.
	process_physics_priority = -100


func setup(p_player: Car, p_cars: Array, p_camera: ChaseCamera,
		p_vignette: Vignette = null) -> void:
	player = p_player
	camera = p_camera
	vignette = p_vignette
	_cars.clear()
	for c in p_cars:
		_cars.append(c as Car)
	if hit_stop == null:
		hit_stop = HitStopScript.new()
		add_child(hit_stop)
	player.impact.connect(_on_impact)
	# Orice repunere sau aruncare scoate lumea din inghet pe loc.
	player.respawned.connect(func(_c: Car) -> void: cancel_hit_stop())
	player.ejected.connect(func(_c: Car, _r: Node3D) -> void: cancel_hit_stop())
	player.tree_exiting.connect(cancel_hit_stop)


func cancel_hit_stop() -> void:
	if hit_stop != null:
		hit_stop.cancel()


func _physics_process(_delta: float) -> void:
	_snapshot()


## Vitezele orizontale ale masinilor la inceputul tick-ului. `impact` se emite
## in tick-ul N, dupa ce solverul a schimbat deja vitezele; cele de DINAINTE de
## lovitura sunt cele citite in tick-ul N-1, adica `_vel_prev` (acest nod ruleaza
## inaintea masinilor, deci la momentul semnalului `_vel_now` e deja post-impact).
func _snapshot() -> void:
	_vel_prev = _vel_now
	_vel_now = {}
	for c in _cars:
		if is_instance_valid(c):
			_vel_now[c] = Vector3(c.linear_velocity.x, 0.0, c.linear_velocity.z)


func _on_impact(car: Car, kind: StringName, strength: float, normal: Vector3,
		_point: Vector3, other: Node) -> void:
	if car != player or camera == null:
		return
	var attacker := _player_is_attacker(kind, normal, other, strength)
	last_player_attacker = attacker
	var kick_m := clampf(strength * kick_per_mps, 0.0, kick_max)
	var roll := minf(strength * roll_deg_per_mps, roll_deg_max)
	if not attacker:
		if other is Car:
			kick_m = minf(kick_m * victim_kick_scale, victim_kick_cap)
			roll *= victim_kick_scale
		else:
			# Hazard mobil: impingere clara, fara hit-stop (vezi mai jos).
			kick_m *= hazard_kick_scale
			roll *= hazard_kick_scale
	last_kick = kick_m
	camera.kick(normal, kick_m, roll)
	_flash_hit_side(normal, strength, attacker, other is Car)
	if kind == &"car":
		var tr := clampf(car_trauma_base + strength * car_trauma_per_mps,
			0.0, car_trauma_max)
		camera.add_trauma(tr if attacker else tr * victim_trauma_scale)
	if attacker and strength >= hitstop_min_strength and racing.call():
		var k := clampf((strength - hitstop_min_strength)
			/ maxf(hitstop_full_strength - hitstop_min_strength, 0.01), 0.0, 1.0)
		hit_stop.trigger(lerpf(hitstop_min_ms, hitstop_max_ms, k) * 0.001)


## Flash pe marginea ecranului dinspre obstacol (invers normalei: normala arata
## DINSPRE obstacol spre masina). Dreapta/fata ecranului se iau din camera.
func _flash_hit_side(normal: Vector3, strength: float, attacker: bool,
		other_is_car: bool) -> void:
	if vignette == null:
		return
	var right := camera.global_transform.basis.x
	var fwd := -camera.global_transform.basis.z
	right.y = 0.0
	fwd.y = 0.0
	if right.length_squared() < 1e-6 or fwd.length_squared() < 1e-6:
		return
	var toward := -Vector3(normal.x, 0.0, normal.z)
	var a := clampf(strength * flash_per_mps, 0.0, flash_max)
	if not attacker:
		a *= victim_kick_scale if other_is_car else hazard_kick_scale
	vignette.flash_edge(Vector2(toward.dot(right.normalized()),
		toward.dot(fwd.normalized())), a)


## Cine a lovit? Pereti: jucatorul (te-ai izbit tu de el). Masini: comparam cat
## se apropia fiecare de celalalt PE LINIA DE CONTACT, inainte de lovitura.
##
## `normal` arata dinspre celalalt spre jucator, deci jucatorul se apropie cu
## `v_jucator . -normal`, iar celalalt cu `v_celalalt . normal`. Cine are cota
## mai mare din apropierea totala a lovit. Din spate peste un AI stationar:
## cota jucatorului e 100%. AI din spate peste jucator: 0%. Frontal egal: 50%,
## deci jucatorul (pragul e sub 50%): mecanica e a lui.
##
## Pereti: jucatorul loveste (te-ai izbit tu), cu o exceptie: un corp cinematic
## (AnimatableBody3D = hazard mobil) care te matura cat stai pe loc. Acolo
## jucatorul e atacator doar daca cota lui din schimbarea de viteza (cat se
## apropia de obstacol INAINTE) trece de `hazard_attacker_share`.
func _player_is_attacker(kind: StringName, normal: Vector3, other: Node,
		strength: float = 0.0) -> bool:
	if kind != &"car":
		if other is AnimatableBody3D and strength > 0.01:
			var nn := Vector3(normal.x, 0.0, normal.z)
			if nn.length_squared() > 1e-6:
				var vpp: Vector3 = _vel_prev.get(player, Vector3.ZERO)
				last_share = maxf(vpp.dot(-nn.normalized()), 0.0) / strength
				return last_share >= hazard_attacker_share
		return true
	var o := other as Car
	var n := Vector3(normal.x, 0.0, normal.z)
	if o == null or n.length_squared() < 1e-6:
		return true
	n = n.normalized()
	var vp: Vector3 = _vel_prev.get(player, Vector3.ZERO)
	var vo: Vector3 = _vel_prev.get(o, Vector3.ZERO)
	var toward_p := maxf(vp.dot(-n), 0.0)
	var toward_o := maxf(vo.dot(n), 0.0)
	var total := toward_p + toward_o
	last_share = 1.0 if total < 0.5 else toward_p / total
	return last_share >= attacker_share_min
