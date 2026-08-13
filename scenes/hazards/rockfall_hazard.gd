@tool
class_name RockfallHazard
extends Node3D
## Bolovan care se desprinde din faleza si cade pe sosea.
##
## Ruda cu [SlidingHazard], dar cu CICLU in loc de oscilatie: telegraf, cadere,
## asezare, retragere. Cronologia e DETERMINISTA, fara zar la runtime — la fel ca
## la sweeper, un hazard care se poate invata e o decizie, unul care surprinde e
## o taxa. Vezi si comentariul de acolo despre "citibil de departe".
##
## Ocupa O BANDA, nu tot drumul. Blocarea completa e treaba caruselului; aici
## trebuie sa ramana mereu o linie curata, ca sa fie alegere, nu franare.
##
## Pedeapsa e ~2 secunde, nu cursa: Car.crush() taie plafonul de viteza pentru
## putin timp. Nu exista stare de "distrus" in joc si nici nu ne trebuie.

## Cat tine fiecare faza, in secunde.
const TELEGRAPH: float = 1.4
const FALL: float = 0.55
const SETTLE: float = 1.1
## De la ce inaltime cade.
const DROP_HEIGHT: float = 9.0
## Cat de departe LATERAL porneste bolovanul, ca multiplu al razei lui.
##
## Piatra nu mai pica vertical din cer: se desprinde din versantul de alaturi si
## se rostogoleste peste sosea. Fara sursa vizibila, hazardul se citea ca
## scripted — nimic din lume nu explica de unde vine. Sablonul e la
## [AvalancheHazard], care coboara la fel de pe panta.
const SLOPE_REACH: float = 5.2
## Raza formei de coliziune a bolovanului.
const ROCK_RADIUS: float = 1.15
## Raza zonei care detecteaza masina — putin mai mare decat piatra, ca lovitura
## sa se simta cand piatra te atinge, nu doar cand te patrunde.
const IMPACT_RADIUS: float = 2.1
## Cat de des cade. Nu se schimba per instanta; faza da defazarea.
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

## Efectul strivirii: durata, plafon de viteza, turtire, cat din viteza ramane.
##
## Cifrele vin din #242, unde strivirea a fost ceruta explicit: masina ramane
## APLATIZATA cu ~30% mai mult decat inainte, merge cu ~30% mai incet, si isi
## revine dupa 3 secunde. Punct de plecare pentru tunat la playtest, ca tot ce
## tine de feel.
##
## `CRUSH_FACTOR` e „cat din plafonul de viteza pastrezi", deci 0.70 = cu 30%
## mai incet. Vechiul 0.55 taia aproape jumatate, dar doar 1.6 s — pedeapsa era
## mai brutala si mai scurta. Acum e mai blanda si de doua ori mai lunga: se
## simte ca o stare in care ai intrat, nu ca o palma.
const CRUSH_SECONDS: float = 3.0
const CRUSH_FACTOR: float = 0.70
const CRUSH_KEEP_SPEED: float = 0.50
## Cat de turtita ramane caroseria. Y-ul e cu 30% sub vechiul 0.35 (adica 0.245),
## exact „cu 30% mai aplatizata"; X/Z cresc cat sa se pastreze volumul — o masina
## strivita se si LATESTE, nu doar coboara.
const CRUSH_SQUASH := Vector3(1.55, 0.245, 1.45)

@export var period: float = DEFAULT_PERIOD
## Defazare 0..1, ca doua bolovanuri sa nu cada la unison.
@export var phase: float = 0.0
## Culoarea umbrei de avertisment.
@export var telegraph_color: Color = Color(0.05, 0.03, 0.02, 0.55)

## Din ce parte vine bolovanul: +1 dreapta sensului de mers, -1 stanga.
##
## O pune pista, din latura pe care chiar exista versant. 0 ar insemna „nu se
## stie", si atunci piatra cade vertical ca inainte — rezerva cinstita pentru
## portiunile fara deal pe nicio parte.
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

## Materiale STATICE, partajate intre toate instantele.
##
## Fiecare instanta isi facea materialul ei, deci costul crestea liniar cu
## numarul de hazarde — exact regresia pe care o vaneaza garda de draw call-uri.
static var _tele_mat: StandardMaterial3D
static var _rock_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	# Pornim din faza dorita, nu de la zero: altfel toate bolovanurile de pe pista
	# ar cadea simultan in primele secunde ale cursei.
	_time = fposmod(phase, 1.0) * period


func _build() -> void:
	_telegraph = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = IMPACT_RADIUS
	disc.bottom_radius = IMPACT_RADIUS
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
	_rock_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ROCK_RADIUS
	_rock_shape.shape = sphere
	_rock.add_child(_rock_shape)
	var model := _rock_model()
	if model != null:
		# Modelul sta intr-un pivot ca sa se poata ROSTOGOLI fara sa roteasca si
		# forma de coliziune: sfera e simetrica, deci rotirea ei n-ar face decat
		# munca in plus la serverul de fizica. Acelasi tipar ca la SlidingHazard.
		_pivot = Node3D.new()
		_rock.add_child(_pivot)
		_pivot.add_child(model)

	_impact = Area3D.new()
	var area_shape := CollisionShape3D.new()
	var area_sphere := SphereShape3D.new()
	area_sphere.radius = IMPACT_RADIUS
	area_shape.shape = area_sphere
	_impact.add_child(area_shape)
	_rock.add_child(_impact)

	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 80.0
	add_child(_audio)


## Bolovanul: cel mai mare cluster din biblioteca, ca sa fie citibil de departe.
## Fara GLB, o sfera cu putine laturi — hazardul trebuie sa functioneze si daca
## lipseste un asset.
func _rock_model() -> Node3D:
	const PATH := "res://assets/models/rocks/rock_cluster.glb"
	if ResourceLoader.exists(PATH):
		var container := (load(PATH) as PackedScene).instantiate() as Node3D
		var kept: Node3D = null
		for child in container.get_children():
			if child.name == "Cluster_L1":
				kept = child
			else:
				child.queue_free()
		if kept != null:
			container.position = -kept.position
			# Cu o clasa ceruta de pista (granit pe Alpii, gresie pe Dunele),
			# textura de clasa ia locul atlasului — dar TRIPLANAR IN SPATIUL
			# OBIECTULUI, fiindca bolovanul se rostogoleste: cu proiectie de
			# lume, textura ar "inota" pe suprafata in timp ce piatra se
			# invarte (style_bible §4, aceeasi nota ca la SlidingHazard).
			if tri_class.is_empty():
				Palette.apply_world_material(container)
			else:
				Palette.apply_object_triplanar_class(container, tri_class, 1.0)
			return container
		container.queue_free()
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


func _physics_process(delta: float) -> void:
	if _rock == null:
		return
	_time = fposmod(_time + delta, period)
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


## Rostogolirea modelului: unghi = distanta parcursa / raza, ca la [SlidingHazard].
##
## Doar in coborare si asezare. La retragere piatra se intoarce pe versant, si
## un bolovan care se da peste cap invers, urcand, ar arata a film rulat inapoi.
func _roll(idx: int, wanted: Vector3) -> void:
	if _pivot == null:
		return
	# Deplasarea se ia din pozitia CERUTA de faze, nu citind `_rock.position`:
	# corpul are `sync_to_physics`, deci transformul il tine serverul de fizica
	# si valoarea scrisa nu se vede inapoi in acelasi cadru. Citita de acolo,
	# deplasarea iesea mereu zero si piatra aluneca fara sa se roteasca —
	# exact ce a prins sonda.
	var moved := wanted - _last_pos
	_last_pos = wanted
	if slope_side == 0.0 or idx > 2:
		return
	var flat := Vector3(moved.x, 0.0, moved.z)
	if flat.length() < 0.0001:
		return
	var axis := Vector3.UP.cross(flat.normalized()).normalized()
	_pivot.rotate(axis, -flat.length() / ROCK_RADIUS)


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
	# Cu versant, piatra se VEDE stand pe panta in tot telegraful: de acolo vine,
	# si asta e chiar informatia care lipsea. Fara versant ramane ascunsa sus, ca
	# inainte — nu are sens sa pluteasca in aer un lucru care „cade din cer".
	_rock.visible = slope_side != 0.0
	return _start_pos()


## Coborarea: de pe versant peste sosea (sau, fara versant, cadere verticala).
func _phase_fall(t: float) -> Vector3:
	var k := clampf(t / FALL, 0.0, 1.0)
	_rock.visible = true
	_rock_shape.disabled = false
	var from := _start_pos()
	var to := Vector3(0.0, ROCK_RADIUS, 0.0)
	_telegraph.scale = Vector3.ONE * lerpf(1.0, 0.85, k)
	# Lateralul avanseaza LINIAR (piatra se rostogoleste, nu tasneste), iar
	# inaltimea cade accelerat (k^2 arata a gravitatie). Combinatia da o
	# parabola — exact traiectoria unui bolovan care sare de pe panta, si
	# aceeasi impartire pe care o face si avalansa.
	return Vector3(
		lerpf(from.x, to.x, k),
		lerpf(from.y, to.y, k * k),
		lerpf(from.z, to.z, k))


## Piatra sta pe drum ca obstacol SOLID: trebuie ocolita, nu doar evitata la
## momentul caderii. Aici se transforma dintr-un eveniment intr-o alegere de linie.
func _phase_settle() -> Vector3:
	_rock_shape.disabled = false
	_telegraph.visible = false
	return Vector3(0.0, ROCK_RADIUS, 0.0)


## Se retrage pe unde a venit: inapoi pe versant, nu in sus prin aer.
func _phase_retract(t: float) -> Vector3:
	var span := maxf(period - (TELEGRAPH + FALL + SETTLE), 0.001)
	var k := clampf(t / span, 0.0, 1.0)
	var from := Vector3(0.0, ROCK_RADIUS, 0.0)
	var to := _start_pos()
	_rock_shape.disabled = true
	# Cu versant ramane vizibila pana sus (se „intoarce acasa"); fara, dispare ca
	# inainte, fiindca o piatra care urca singura in cer ar fi mai ciudata decat
	# una care se stinge.
	_rock.visible = slope_side != 0.0 or k < 0.9
	_telegraph.visible = false
	return from.lerp(to, k)


## De unde porneste bolovanul, in coordonate LOCALE fata de punctul de impact.
##
## Nodul e asezat de pista cu +X spre marginea drumului dinspre care vine piatra
## (vezi `Track._build_rockfall`), deci lateralul e pe X local.
func _start_pos() -> Vector3:
	if slope_side == 0.0:
		return Vector3(0.0, DROP_HEIGHT, 0.0) # fara versant: cadere verticala
	return Vector3(ROCK_RADIUS * SLOPE_REACH, DROP_HEIGHT, 0.0)


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
		# care mergi mai incet trei secunde — daca dispare imediat, penalizarea
		# ramane fara cauza vizibila si se citeste ca bug.
		car.crush(CRUSH_SECONDS, CRUSH_FACTOR, CRUSH_SQUASH,
			CRUSH_KEEP_SPEED, true)
		# Impinsa in jos: turtirea trebuie sa se si SIMTA, nu doar sa se vada.
		car.velocity.y = -6.0
		# Lovitura vine din DIRECTIA in care mergea piatra, nu mereu de sus.
		# La caderea verticala nu exista lateral si ramane doar strivirea, ca
		# inainte; la rostogolire, un bolovan care te ia din coasta te si
		# imbranceste — altfel s-ar vedea trecand prin masina fara consecinta.
		#
		# Directia se ia din geometria pornirii, nu din pozitia de la impact:
		# acolo piatra e deja pe axa drumului, deci vectorul ar fi ~zero exact
		# in clipa in care ne trebuie. Bolovanul vine dinspre versant (+X local)
		# spre sosea, deci imbranceala e pe -X local.
		if slope_side != 0.0:
			car.apply_sweep(-global_transform.basis.x.normalized() * SHOVE_PUSH)
