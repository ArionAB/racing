@tool
class_name AvalancheHazard
extends Node3D
## Masa de zapada care se desprinde din versant si traverseaza soseaua.
##
## Gimmickul pistei alpine. Ruda cu [RockfallHazard] prin CICLU (telegraf,
## coborare, trecere, retragere) si cu [TrainHazard] prin PEDEAPSA (te scoate
## din cursa, cu repunere), dar difera de amandoua prin ce se intampla intre
## cele doua: avalansa TE IA CU EA. Vezi `_drag_cars`.
##
## De ce nu e inca un `SlidingHazard` cu alt model: bariera mobila te
## dezechilibreaza si elibereaza drumul, iar asta merge pentru ceva ce mature
## soseaua la nesfarsit. Un perete de zapada de 7 m care doar te ghionteste ar
## contrazice ce vezi — deci pedeapsa e mare, si de-aia hazardul e un EVENIMENT
## rar, cu telegraf lung, nu un obstacol permanent.
##
## Contractul cu pista (`Track._build_avalanche`): hazardul primeste punctul de
## pe sosea, directia drumului si semilatimea, si isi calculeaza singur de unde
## pleaca si unde se opreste. Nu stie nimic despre teren — coboara pe o panta
## declarata, nu pe geometria reala, exact ca sania de busteni.

## ------------------------------------------------------------------ cronologie
##
## Fazele, in secunde. Suma lor da perioada implicita.
##
## TELEGRAPH e enorm fata de cele 1.4 s ale bolovanului, si e deliberat:
## `RockfallHazard` pedepseste cu ~2 secunde, aici pierzi cursa. Regula pe care
## o respecta amandoua e a lui `SlidingHazard` — „un hazard care se poate invata
## e o decizie, unul care surprinde e o taxa" — doar ca pretul deciziei fiind
## mult mai mare, si avertismentul trebuie sa fie pe masura.
const TELEGRAPH: float = 3.2
## Cat dureaza traversarea propriu-zisa. Scurt: o avalansa care sta pe drum ar
## deveni un blocaj semi-static, exact defectul masurat la `SlidingHazard`
## (obstacolul lent aduna toata lumea in el).
const SWEEP: float = 2.6
## Cat sta drumul liber inainte sa reinceapa ciclul.
const RETRACT: float = 2.2

const DEFAULT_PERIOD: float = TELEGRAPH + SWEEP + RETRACT

## ------------------------------------------------------------------- geometrie
##
## Diametrul masei in joc. Modelul are 7 m, deci `model_scale` iese ~1.0 — dar
## cota se scrie AICI, nu se citeste din GLB: e o afirmatie despre gameplay
## (cat de mult din sosea acopera), nu despre asset.
const MASS_DIAMETER: float = 7.0
## De la ce inaltime pe versant porneste, fata de cota soselei.
const START_HEIGHT: float = 14.0
## Cat de departe lateral de axa drumului porneste, ca fractie din semilatime.
## >1 = pleaca din afara soselei, adica de pe versant.
const START_SIDE: float = 2.6
## Cat de departe trece dincolo de drum. Tot >1: masa nu se opreste pe asfalt,
## il traverseaza si dispare in vale, altfel ar ramane un zid parcat pe pista.
const END_SIDE: float = 2.4

## Raza sferei de coliziune, ca fractie din raza modelului. Sub 1 fiindca un
## bolovan e neregulat: o sfera pe conturul exterior ar lovi cu aer.
const HULL_FRACTION: float = 0.82

## Bolovanii din care se face avalansa: (forma, diametru_m, x, z, viteza_rot).
##
## NOUA bucati din PATRU forme (`avalanche_boulders.glb`). Nimeni nu recunoaste
## ca doi bolovani impart silueta — ii deosebesc marimea, pozitia in gramada si
## faza rotatiei, si toti se rostogolesc oricum in jurul altei axe.
##
## Marimile sunt DELIBERAT inegale (1.0 .. 2.8 m): o gramada de bucati egale
## citeste ca un set de mingi, nu ca material spart dintr-un versant. Cele mari
## dau masa, cele mici dau franjurii care fac frontul sa nu aiba o margine neta.
##
## `x` / `z` sunt in metri fata de centrul gramezii — z e DE-A LUNGUL soselei
## (frontul e lat), x e pe directia de coborare (gramada are adancime, deci
## bucatile din spate se vad printre cele din fata cand se rostogolesc).
##
## Viteza de rotatie e un MULTIPLICATOR peste rostogolirea geometrica: 1.0 =
## exact cat ar da distanta parcursa / raza. Micile abateri (0.85 .. 1.25) sunt
## ce rupe impresia de bloc rigid — bucatile nu se rotesc la unison.
const BOULDERS: Array = [
	# forma, diametru, x, z, spin
	["Boulder_A", 2.8, 0.0, 0.4, 1.00],
	["Boulder_C", 2.4, -1.6, -2.2, 0.90],
	["Boulder_B", 2.2, 1.5, -1.4, 1.15],
	["Boulder_D", 1.9, -0.9, 2.6, 1.05],
	["Boulder_B", 1.7, 1.9, 2.9, 0.85],
	["Boulder_A", 1.5, -2.4, 0.8, 1.20],
	["Boulder_C", 1.3, 2.6, -0.3, 1.10],
	["Boulder_D", 1.1, 0.6, -3.1, 1.25],
	["Boulder_A", 1.0, -0.4, 3.6, 0.95],
]

## ---------------------------------------------------------------------- impact
##
## Cat tine masina „inghitita" inainte de repunere.
const STUN_SECONDS: float = 1.35
## Cat de departe in spate se repune. Mai mult decat cei 14 m impliciti si decat
## trenul: masa te-a carat la vale, deci repunerea in fata ar fi un cadou.
const RESPAWN_BACKOFF: float = 22.0
## Cat sta o masina imuna dupa ce a fost lovita.
const HIT_COOLDOWN: float = 1.0
## Cat de repede se invarte caroseria cat esti dus de masa (rad/s). DOAR VIZUAL,
## vezi `Car.spin_body` — colizorul si directia de mers raman ale masinii.
const SPIN_RATE: float = 7.5

## Cate bucati are norul de zapada.
##
## 34, cu limita ceruta explicit de CLAUDE.md („particule cu limita de count").
## Sub ~20 norul se citeste ca bulgari razleti in loc de masa difuza; peste ~45
## nu se mai vede diferenta, dar fiecare bucata e o suprafata transparenta de
## 1 m care se suprapune peste celelalte — adica exact OVERDRAW, singura axa
## despre care CLAUDE.md spune ca chiar doare pe mobil. E prima cifra de
## coborat daca testul pe device nu tine 60fps.
const PLUME_COUNT: int = 34

## ------------------------------------------------------------------- interfata
##
## Semilatimea soselei aici. 0 = necunoscuta, si atunci cursa ramane cea
## implicita — ca la `SlidingHazard.road_half_width`.
var road_half_width: float = 0.0
## Defazaj 0..1 dintr-o perioada, ca doua avalanse sa nu porneasca la unison.
var phase: float = 0.0
@export var period: float = DEFAULT_PERIOD

## Containerul gramezii. Node3D, nu corp: coliziunea e pe fiecare bolovan.
var _mass: Node3D
## Cate un dictionar per bolovan: body / pivot / area / radius / spin.
var _shards: Array = []
var _telegraph: Node3D
var _plume: CPUParticles3D
var _audio: AudioStreamPlayer3D
var _hit_audio: AudioStreamPlayer3D
var _time: float = 0.0
var _last_phase: int = -1
## Raza GRAMEZII (nu a unui bolovan): din ea ies raza norului si cota la care
## trece frontul peste asfalt. Bolovanii isi au fiecare raza lui, in `_shards`.
var _radius: float = MASS_DIAMETER * 0.5
var _cooldown: Dictionary = {}
## Masinile inghitite acum -> cat mai sunt duse. Golit cand expira stun-ul.
var _carried: Dictionary = {}

## Material static, partajat intre instante — aceeasi regula ca la bolovan:
## un material per instanta ar creste draw call-urile liniar cu numarul de
## hazarde, exact regresia pe care o vaneaza `tools/probe_decor.gd`.
static var _tele_mat: StandardMaterial3D
static var _snow_mat: StandardMaterial3D
static var _plume_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	# Pornim din faza ceruta, nu de la zero: altfel toate avalansele de pe pista
	# ar porni simultan in primele secunde ale cursei.
	_time = fposmod(phase, 1.0) * period


func _build() -> void:
	var hw := road_half_width if road_half_width > 0.0 else 10.0

	_telegraph = _build_telegraph(hw)
	add_child(_telegraph)

	# `_mass` nu mai e un corp, e CONTAINERUL gramezii: el se muta pe traiectorie
	# si duce bolovanii cu el. Fiecare bolovan e insa un corp de sine statator,
	# cu coliziunea si rostogolirea lui.
	#
	# De ce nu un singur corp de 7 m, cum era prima versiune: o masa rigida
	# ARATA rigida oricat de bine e texturata. O avalansa e material in miscare,
	# iar ce spune asta ochiului sunt bucatile de marimi diferite care se
	# rostogolesc fiecare in ritmul ei — chiar imaginea din Ignition.
	_mass = Node3D.new()
	add_child(_mass)

	_shards = _build_boulders()

	# Norul de zapada. Se agata de GRAMADA, nu de un bolovan anume: legat de
	# unul singur, s-ar plimba cu el si ar lasa restul fara praf.
	_plume = _build_plume()
	_mass.add_child(_plume)

	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	# Mai departe decat restul hazardelor (80 m): huruitul e SINGURUL avertisment
	# si trebuie sa ajunga inainte sa se vada ceva pe versant.
	_audio.max_distance = 140.0
	add_child(_audio)

	_hit_audio = AudioStreamPlayer3D.new()
	_hit_audio.bus = &"SFX"
	_hit_audio.max_distance = 90.0
	add_child(_hit_audio)


## Norul de zapada pe care il ridica masa — „fumul alb" din spatele bolovanilor
## din Ignition, si jumatate din motivul pentru care hazardul se citeste ca o
## avalansa si nu ca o bila care se rostogoleste.
##
## Fara el masa are o silueta prea curata: o forma solida care aluneca peste
## drum, fara nimic care sa spuna ca dizloca material. Norul rezolva si o
## problema de LIZIBILITATE — margineste corpul cu ceva difuz, deci masa
## citeste ca volum in miscare de la distanta, cand inca e mica in cadru.
##
## Diferenta fata de vartejul trombei (`_spin_emitter`): acolo `radial_accel`
## negativ trage totul spre axa, fiindca aia e forma unei trombe. Aici norul
## trebuie sa se DESFACA si sa ramana in urma, deci acceleratia e spre exterior
## si in sus, iar viteza initiala e mica: zapada ridicata pluteste, nu tasneste.
func _build_plume() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = PLUME_COUNT
	p.lifetime = 1.5
	p.preprocess = 0.4 # norul e deja format cand masa intra in cadru
	p.emitting = false
	# Emisie pe TOT corpul, nu dintr-un punct: zapada se ridica de pe toata
	# suprafata care freaca versantul, nu dintr-un cos.
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	# Raza GRAMEZII, nu a unui bolovan: norul trebuie sa iasa dintre toate
	# bucatile, altfel praful apare dintr-un singur punct si restul frontului
	# arata uscat.
	p.emission_sphere_radius = _radius * 0.9
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 4.5
	# Spre exterior, invers decat tromba: norul se umfla in jurul masei.
	p.radial_accel_min = 1.5
	p.radial_accel_max = 5.0
	# Gravitatie slaba, ca la praful trombei: zapada pudra sta in aer si se
	# stinge acolo. Cu gravitatia jocului (-28) tot norul ar cadea in prima
	# jumatate de metru si n-ar exista.
	p.gravity = Vector3(0.0, -1.6, 0.0)
	p.scale_amount_min = 1.1
	p.scale_amount_max = 2.8
	# Bucatile CRESC pe durata vietii: asa se comporta un nor care se disipa.
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = grow
	var tint := Palette.color(Palette.FOAM_WHITE)
	var fade := Gradient.new()
	fade.set_color(0, Color(tint.r, tint.g, tint.b, 0.0))
	fade.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	# Aceleasi trei opriri ca la tromba, din acelasi motiv: o particula care
	# apare la opacitate plina POCNESTE in cadru.
	fade.add_point(0.12, Color(tint.r, tint.g, tint.b, 0.75))
	fade.add_point(0.60, Color(tint.r, tint.g, tint.b, 0.45))
	p.color_ramp = fade
	var bit := SphereMesh.new()
	bit.radius = 0.5
	bit.height = 1.0
	# Rezolutia implicita a unei sfere Godot e 64x32 = 4224 de triunghiuri —
	# cu 34 de bucati ar fi 143.000 de triunghiuri de fum. Vezi CLAUDE.md.
	bit.radial_segments = 5
	bit.rings = 3
	bit.material = _plume_material()
	p.mesh = bit
	return p


static func _plume_material() -> StandardMaterial3D:
	if _plume_mat == null:
		_plume_mat = StandardMaterial3D.new()
		_plume_mat.vertex_color_use_as_albedo = true
		# Culorile proiectului sunt autorate ca sRGB. Fara steag, Godot le
		# citeste ca LINIARE si le scoate cu ~1.5 trepte mai deschise — lectia
		# platita deja pe praful de sub roti si pe cel al trombei.
		_plume_mat.vertex_color_is_srgb = true
		_plume_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_plume_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Fara scriere in depth: bucatile se suprapun fara sa se taie una pe alta.
		_plume_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return _plume_mat


## Dara de zapada pe versant: creste cat tine telegraful, ca sa se vada DE UNDE
## vine, nu doar ca vine. Acelasi rol ca umbra bolovanului, dar verticala —
## avalansa nu cade pe tine, coboara spre tine.
func _build_telegraph(hw: float) -> Node3D:
	var node := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(MASS_DIAMETER * 0.8, START_HEIGHT * 1.4)
	# Implicit are subdiviziuni; pentru o pata plata sunt triunghiuri degeaba.
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	node.mesh = plane
	if _tele_mat == null:
		_tele_mat = StandardMaterial3D.new()
		_tele_mat.albedo_color = Color(0.92, 0.95, 1.0, 0.42)
		_tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Fara scriere in depth: dara sta LIPITA de versant, nu taie geometria.
		_tele_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_tele_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = _tele_mat
	# Culcata pe panta dintre punctul de plecare si sosea.
	node.position = (_start_point(hw) + _road_point()) * 0.5
	node.look_at_from_position(node.position, _road_point(), Vector3.UP)
	node.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	return node


## Modelul: GLB-ul de avalansa, cu materialul de clasa aplicat IN SPATIUL
## OBIECTULUI (masa se roteste, iar o proiectie de lume i-ar face textura sa
## „inoate" pe suprafata — style_bible §4, acelasi motiv ca la bolovan).
##
## Fara GLB, o sfera cu putine laturi: hazardul trebuie sa functioneze si daca
## lipseste un asset, ca peste tot in proiect.
## Construieste cei noua bolovani. Intoarce lista de descriptori, fiecare cu
## corpul, pivotul de rostogolire si raza masurata.
##
## Fiecare bucata e un `AnimatableBody3D` PROPRIU, nu o forma in plus pe un corp
## unic, si asta e diferenta care conteaza si pentru fizica: masina care intra
## in gramada loveste bolovanul cu care s-a ciocnit, nu o sfera de 7 m in jurul
## a tot. Ciocnirea la marginea frontului se simte altfel decat cea in mijloc.
func _build_boulders() -> Array:
	var shapes := _boulder_shapes()
	var out: Array = []
	for spec in BOULDERS:
		var shape_name: String = spec[0]
		var diameter: float = spec[1]

		var body := AnimatableBody3D.new()
		# Ca la toate hazardele mobile: fara asta masina vede un salt de pozitie
		# in loc de o coliziune cu viteza.
		body.sync_to_physics = true
		body.position = Vector3(spec[2], 0.0, spec[3])
		# Copil al hazardului, NU al containerului, si asta e capcana pe care o
		# repeta tot proiectul: cu `sync_to_physics`, transformul corpului il
		# tine serverul de fizica in spatiul GLOBAL si nu mai urmareste parintele.
		#
		# Masurat cand erau copii ai lui `_mass`: containerul urca la y=2.5 iar
		# bolovanii ramaneau la y=0 — gramada nu se misca deloc, desi codul
		# „muta masa". Deci pozitia fiecarui bolovan se scrie explicit, in
		# `_place_shards`, si `_mass` ramane doar starea traiectoriei.
		add_child(body)

		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = diameter * 0.5 * HULL_FRACTION
		col.shape = sphere
		body.add_child(col)

		# Pivotul, ca la `SlidingHazard._build_model`: modelul are originea in
		# CENTRU, deci se aseaza in pivot si rostogolirea roteste pivotul. Cu
		# originea la baza, rotatia s-ar face in jurul unui punct de pe sol —
		# bolovanul ar sari in loc sa se rostogoleasca.
		var pivot := Node3D.new()
		body.add_child(pivot)

		var model: Node3D = null
		if shapes.has(shape_name):
			model = (shapes[shape_name] as Node3D).duplicate() as Node3D
			var measured := Track.model_aabb(model)
			var d := maxf(measured.size.x, measured.size.z)
			var fit := 1.0
			if d > 0.02:
				fit = diameter / d
				model.scale = Vector3.ONE * fit
			# Textura de clasa, TRIPLANAR IN SPATIUL OBIECTULUI: bolovanul se
			# rostogoleste, iar proiectia de lume ar lasa textura pe loc in timp
			# ce corpul se invarte pe sub ea (style_bible §4).
			#
			# `fit` intra in socoteala ca zapada sa masoare la fel pe toate
			# bucatile: fara el, bolovanul de 1 m ar avea crusta de trei ori mai
			# mare decat cel de 2.8 m si gramada n-ar arata din acelasi material.
			#
			# CUANTIZAT, si asta nu e cosmetica — e chiar garda de draw calls.
			# `Palette.object_triplanar_class_material` cacheaza pe
			# (clasa, scale), deci noua scari distincte = NOUA materiale pentru
			# aceeasi textura. Masurat pe un singur hazard: 9 materiale unice,
			# exact regresia pe care o vaneaza `tools/probe_decor.gd` (un
			# material = cel putin un draw call).
			#
			# Pasul e 0.5, ales prin numarare, nu din ochi — fit-urile reale
			# (0.50 .. 1.40) cad astfel:
			#   pas 0.25 -> 5 galeti (masurat: 5 materiale snow, prea multe)
			#   pas 0.50 -> 3 galeti   <- ales
			#   pas 1.00 -> 1 galeata, dar bolovanul de 1 m si cel de 2.8 m ar
			#               primi aceeasi scara de crusta, adica exact eroarea
			#               pe care `fit` exista sa o repare.
			var bucket := maxf(snappedf(fit, 0.5), 0.5)
			Palette.apply_object_triplanar_class(model, "snow", bucket)
			pivot.add_child(model)
		else:
			pivot.add_child(_fallback_boulder(diameter))

		# Zona de impact, putin mai mare decat corpul: lovitura trebuie sa se
		# simta cand te atinge, nu doar cand te patrunde (acelasi motiv ca
		# `RockfallHazard.IMPACT_RADIUS`).
		var area := Area3D.new()
		var area_col := CollisionShape3D.new()
		var area_sphere := SphereShape3D.new()
		area_sphere.radius = diameter * 0.5 * 1.05
		area_col.shape = area_sphere
		area.add_child(area_col)
		body.add_child(area)

		out.append({
			"body": body,
			"pivot": pivot,
			"area": area,
			"radius": diameter * 0.5,
			"spin": float(spec[4]),
			# Offsetul in gramada, pastrat: pozitia finala se recalculeaza in
			# fiecare cadru ca `centrul gramezii + offset`.
			"offset": Vector3(spec[2], 0.0, spec[3]),
		})
	return out


## Formele din GLB, o singura incarcare pentru toate instantele.
func _boulder_shapes() -> Dictionary:
	const PATH := "res://assets/models/effects/avalanche_boulders.glb"
	var out := {}
	if not ResourceLoader.exists(PATH):
		return out
	var root := (load(PATH) as PackedScene).instantiate() as Node3D
	for child in root.get_children():
		if child is Node3D:
			out[child.name] = child
	return out


## Fara GLB: o sfera cu putine laturi. Hazardul trebuie sa functioneze si daca
## lipseste un asset, ca peste tot in proiect.
func _fallback_boulder(diameter: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = diameter * 0.5
	mesh.height = diameter
	# Rezolutia implicita a unei sfere Godot e 64x32 = 4224 de triunghiuri.
	# Cu noua bucati ar fi 38.000 dintr-un foc. Vezi CLAUDE.md.
	mesh.radial_segments = 9
	mesh.rings = 5
	mi.mesh = mesh
	if _snow_mat == null:
		_snow_mat = StandardMaterial3D.new()
		_snow_mat.albedo_color = Palette.color(Palette.FOAM_WHITE)
	mi.material_override = _snow_mat
	return mi


# ------------------------------------------------------------------ traiectorie

## Punctul de pe sosea, in spatiul hazardului. Hazardul e plantat PE drum de
## `Track`, deci axa lui e chiar punctul de trecere.
func _road_point() -> Vector3:
	return Vector3.ZERO


## De unde pleaca masa: sus si lateral, pe versant.
##
## +X local e lateralul drumului (constructorul din `Track` orienteaza nodul cu
## `looking_at(dir)`, aceeasi conventie ca la tren si deflector).
func _start_point(hw: float) -> Vector3:
	return Vector3(hw * START_SIDE, START_HEIGHT, 0.0)


## Unde se opreste: dincolo de sosea, mai jos, in vale.
func _end_point(hw: float) -> Vector3:
	return Vector3(-hw * END_SIDE, -START_HEIGHT * 0.35, 0.0)


func _physics_process(delta: float) -> void:
	if _mass == null:
		return
	_time = fposmod(_time + delta, period)
	var hw := road_half_width if road_half_width > 0.0 else 10.0

	var idx := 0
	if _time < TELEGRAPH:
		idx = 0
		_phase_telegraph(_time / TELEGRAPH, hw)
	elif _time < TELEGRAPH + SWEEP:
		idx = 1
		_phase_sweep((_time - TELEGRAPH) / SWEEP, hw)
	else:
		idx = 2
		_phase_retract(hw)

	if idx != _last_phase:
		_on_phase_enter(idx)
		_last_phase = idx

	if Engine.is_editor_hint():
		return
	_tick_cooldowns(delta)
	if idx == 1:
		_hit_cars()
	_drag_cars(delta, hw)


func _on_phase_enter(idx: int) -> void:
	if Engine.is_editor_hint():
		return
	match idx:
		0:
			_start_rumble()
		2:
			# Huruitul se opreste cand masa a trecut: altfel pista ar avea un
			# zgomot de fond permanent si avertismentul n-ar mai avertiza nimic.
			_audio.stop()


## Aseaza bolovanii fata de centrul gramezii.
##
## Exista fiindca `sync_to_physics` scoate corpurile din ierarhia de transformari
## (vezi nota din `_build_boulders`): parintele se poate muta cat vrea, ele stau
## unde le-a lasat serverul de fizica. Deci pozitia se scrie de mana.
##
## Offsetul se roteste odata cu bolovanul? NU: gramada isi pastreaza forma, doar
## bucatile se invart in jurul propriului centru. Un offset rotit ar face
## bolovanii sa se invarta unul in jurul altuia ca un carusel.
func _place_shards(center: Vector3) -> void:
	for sh in _shards:
		# Cota fiecarui bolovan se DERIVA din raza lui, nu e zero: centrul unei
		# bile de 1 m si al uneia de 2.8 m nu pot sta pe acelasi plan daca
		# amandoua ating solul. Cu offset zero pe Y, randarea a aratat gramada
		# plutind — bucatile mici atarnau, cele mari erau ingropate.
		#
		# `center.y` e cota la care trece CENTRUL gramezii (0.72 din raza ei,
		# vezi `_phase_sweep`), deci un bolovan sta cu talpa acolo unde ar sta
		# talpa unui bolovan de raza medie: coboram cu raza gramezii si urcam cu
		# a lui.
		var r: float = sh["radius"]
		var lift := r - _radius * 0.72
		var off: Vector3 = sh["offset"]
		(sh["body"] as Node3D).position = center + off + Vector3(0.0, lift, 0.0)


## Aprinde sau stinge toti bolovanii deodata.
##
## Coliziunea se comuta pe fiecare corp, dar prin `set_deferred`: Godot nu are
## voie sa schimbe forme de coliziune in mijlocul pasului de fizica, iar un
## `disabled = ...` direct din `_physics_process` scoate un avertisment si poate
## fi ignorat tacut.
func _set_shards_active(on: bool) -> void:
	for sh in _shards:
		(sh["body"] as Node3D).visible = on
		var body := sh["body"] as AnimatableBody3D
		for child in body.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).set_deferred("disabled", not on)


## Masa nu se vede inca; se aud huruitul si se vede dara pe versant.
func _phase_telegraph(k: float, hw: float) -> void:
	_telegraph.visible = true
	_telegraph.scale = Vector3(lerpf(0.25, 1.0, k), 1.0, lerpf(0.15, 1.0, k))
	_mass.position = _start_point(hw)
	_place_shards(_mass.position)
	_set_shards_active(false)
	_plume.emitting = false
	# Volumul creste cat se apropie: e mecanica, nu ambianta.
	_audio.unit_size = lerpf(2.0, 9.0, k)


## Traversarea. Masa coboara pe panta si trece peste sosea, rostogolindu-se.
##
## Traiectoria NU e o interpolare dreapta intre cele doua capete, si asta a fost
## un bug real: cu `from.lerp(to, k)` masa cobora liniar de la +14 m la -4.9 m,
## deci exact cand ajungea in dreptul soselei (x = 0, la mijlocul cursei) se afla
## la ~+5 m — plutea pe deasupra drumului si nu atingea pe nimeni. Sonda a
## raportat „masina nu a fost prinsa niciodata" cu masa vizibila si ciclul corect.
##
## Corectia: X-ul se interpoleaza liniar (viteza laterala constanta), dar Y-ul
## se ia dintr-o parabola care trece prin ZERO la traversare. Masa vine de sus,
## atinge cota drumului cand e pe el, si pleaca mai jos in vale — adica exact ce
## se vede in referinte, si singura forma in care hazardul chiar loveste.
func _phase_sweep(k: float, hw: float) -> void:
	var from := _start_point(hw)
	var to := _end_point(hw)
	_set_shards_active(true)
	_telegraph.visible = false
	_plume.emitting = true
	var prev := _mass.position
	var x := lerpf(from.x, to.x, k)
	# `t` = 0 pe axa drumului, negativ inainte, pozitiv dupa. Cota se leaga de
	# POZITIA LATERALA, nu de timp: asa raman corecte si daca se schimba
	# START_SIDE / END_SIDE, fara alt numar de tunat.
	# Cota la care trece CENTRUL gramezii peste asfalt.
	#
	# 0.72 din raza gramezii, nu raza celui mai mare bolovan: bucatile stau la
	# cote diferite in jurul centrului, iar cele mari trebuie sa atinga drumul
	# in timp ce cele mici trec putin peste el. Cu centrul la zero, jumatate din
	# gramada ar fi ingropata in asfalt.
	var base := _radius * 0.72
	var t := 0.0
	if x > 0.0 and absf(from.x) > 0.01:
		t = x / from.x         # 1 la plecare -> 0 pe sosea
		_mass.position = Vector3(x, base + (from.y - base) * t * t, 0.0)
	elif absf(to.x) > 0.01:
		t = x / to.x           # 0 pe sosea -> 1 la capat
		_mass.position = Vector3(x, base + (to.y - base) * t * t, 0.0)
	else:
		_mass.position = Vector3(x, base, 0.0)
	_place_shards(_mass.position)
	# Rostogolirea: unghi = distanta parcursa / raza, ca la `SlidingHazard`, dar
	# PER BOLOVAN — fiecare are alta raza, deci alta viteza unghiulara la aceeasi
	# distanta parcursa. Exact asta rupe impresia de bloc rigid: bucata mica se
	# invarte vizibil mai repede decat cea mare, cum se intampla si in realitate.
	var travelled := (_mass.position - prev).length()
	for sh in _shards:
		var r: float = sh["radius"]
		if r > 0.01:
			# Pe Z local, fiindca gramada se deplaseaza pe X local.
			(sh["pivot"] as Node3D).rotate_z(-travelled / r * float(sh["spin"]))
	_audio.unit_size = 9.0


## Drumul e liber. Masa sta parcata departe, cu coliziunea oprita — mai simplu
## si mai sigur decat sa comutam `disabled` in fiecare cadru (nota din
## `TrainHazard`).
func _phase_retract(hw: float) -> void:
	_mass.position = _end_point(hw) + Vector3(0.0, -START_HEIGHT * 2.0, 0.0)
	_place_shards(_mass.position)
	_set_shards_active(false)
	_telegraph.visible = false
	# Norul se stinge odata cu masa, dar particulele deja emise isi traiesc
	# viata: `emitting = false` nu le sterge, deci coada se disipa natural in
	# loc sa dispara dintr-un cadru in altul.
	_plume.emitting = false


# ----------------------------------------------------------------------- impact

func _tick_cooldowns(delta: float) -> void:
	for car: Car in _cooldown.keys():
		var left: float = float(_cooldown[car]) - delta
		if left <= 0.0:
			_cooldown.erase(car)
		else:
			_cooldown[car] = left


## Fiecare bolovan are zona LUI de impact, deci se intreaba toate.
##
## Rezultatul e diferit de o sfera unica de 7 m in jurul gramezii, si in bine:
## intre bucati exista spatii reale, asa ca o masina poate trece printre doi
## bolovani cand frontul e rarefiat la margine. E chiar alegerea pe care o cere
## `RockfallHazard` in comentariul lui — sa ramana o linie de scapare, ca
## hazardul sa fie decizie, nu taxa — dar aici iese din geometrie, nu dintr-o
## regula scrisa.
func _hit_cars() -> void:
	for sh in _shards:
		for body in (sh["area"] as Area3D).get_overlapping_bodies():
			var car := body as Car
			if car == null or _cooldown.has(car) or _carried.has(car):
				continue
			_cooldown[car] = HIT_COOLDOWN
			_swallow(car)


## Inghitita: turtita, oprita, scoasa din cursa si INVARTITA cat e dusa.
##
## `race_active = false` (ca la tren) opreste controlul si cronometrarea cat
## tine stun-ul. `spin_body` e doar vizual — vezi nota din `Car.spin_body`
## despre de ce o rotatie reala a bazei ar fi un tete-a-queue nemeritat.
func _swallow(car: Car) -> void:
	car.crush(0.0, 1.0, Vector3(1.5, 0.3, 1.35), 0.0)
	car.race_active = false
	car.spin_body(SPIN_RATE, STUN_SECONDS)
	_carried[car] = STUN_SECONDS
	_play_hit()
	var hit_car := car
	get_tree().create_timer(STUN_SECONDS, false).timeout.connect(
		func() -> void:
			if not is_instance_valid(hit_car):
				return
			_carried.erase(hit_car)
			hit_car.race_active = true
			hit_car.respawn(RESPAWN_BACKOFF))


## Masina inghitita e CARATA cu masa, si asta e ce desparte avalansa de tren.
##
## Trenul te loveste lateral si te lasa in urma; o avalansa te acopera si te
## duce la vale cateva zeci de metri inainte sa te scuipe. Fara bucata asta,
## hazardul ar fi „inca un tren cu alt model" — exact ce nu vrem de la gimmickul
## unei piste (principiul 3: fiecare pista are personalitatea ei).
##
## Se muta `global_position`, nu `velocity`: masina e un CharacterBody3D cu
## `race_active = false`, deci nu se mai integreaza nimic din viteza ei. O
## impingere ar fi fost inghitita tacut de `move_and_slide`.
func _drag_cars(delta: float, hw: float) -> void:
	if _carried.is_empty():
		return
	# Directia de coborare a masei, in spatiul lumii.
	var dir := (to_global(_end_point(hw)) - to_global(_start_point(hw)))
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return
	dir = dir.normalized()
	# Viteza masei: toata cursa in `SWEEP` secunde.
	var speed := (_end_point(hw) - _start_point(hw)).length() / maxf(SWEEP, 0.01)
	for car: Car in _carried.keys():
		if not is_instance_valid(car):
			_carried.erase(car)
			continue
		var left: float = float(_carried[car]) - delta
		if left <= 0.0:
			_carried.erase(car)
			continue
		_carried[car] = left
		car.global_position += dir * speed * delta


# ------------------------------------------------------------------------ sunet

## Huruitul, cerut prin ARBORE si nu prin identificatorul de autoload.
##
## `AudioManager.stream(...)` ar fi mai scurt, dar in modul `--script`
## autoload-urile nu exista, deci identificatorul nu se rezolva si SCRIPTUL NU
## COMPILEAZA — iar clasa necompilata inseamna ca `AvalancheHazard.new()`
## intoarce eroare si pista se construieste fara avalansa, in tacere. Lectia e
## a podului mobil, repetata de tromba.
func _start_rumble() -> void:
	var stream := _sfx(&"avalanche_rumble")
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


func _play_hit() -> void:
	var stream := _sfx(&"avalanche_hit")
	if stream == null:
		return
	_hit_audio.stream = stream
	_hit_audio.play()


func _sfx(sfx_name: StringName) -> AudioStream:
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null:
		return null
	return manager.call("stream", sfx_name)
