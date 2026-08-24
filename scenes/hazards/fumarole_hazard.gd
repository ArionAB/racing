@tool # vizibil si in preview-ul din editor
class_name FumaroleHazard
extends Node3D
## Fumarola de pe coasta de est a Stromboli: gura din care iese, in rafale, o
## coloana de abur peste drum. Brief §3, clasa „hazard-teatru, cost ZERO".
##
## [b]Ce NU face, si de ce e important[/b]. Nu te incetineste, nu-ti taie
## grip-ul, nu te impinge si nu te repune. Nu are colizor. Singurul lucru pe
## care-l face e sa te lase, pentru ~0.5 s, sa nu vezi — si atat.
##
## Motivul e ritmul turului, nu lipsa de ambitie. POI-ul H din brief e
## „respiro fals, ultima sansa de depasire inainte de sat": ultimul lucru de
## care are nevoie e un obstacol care rupe viteza. Un hazard care sperie fara
## sa coste da exact asta — prima data franezi, a treia oara treci prin el cu
## turbo si te simti expert. Daca vreodata cineva e tentat sa-i adauge o
## pedeapsa „ca sa conteze": exact atunci inceteaza sa mai fie fumarola si
## devine un al doilea gheizer.
##
## [b]Ritm PROPRIU, nu ciclul eruptiei[/b] (decizia dezvoltatorului, aug 2026).
## `EruptionCycle` exista si ar fi fost usor de refolosit, dar ar fi fost
## gresit: metronomul global bate la ~45 s, adica mai rar decat un tur, si
## fumarolele ar fi suflat o data la doua-trei ture, aleatoriu din perspectiva
## soferului. Cu ceas propriu (`period` ~7 s) treci pe langa ele de fiecare
## data si INVETI ritmul — care e tot ce trebuie sa faca un hazard care nu
## costa nimic. Fiecare gura isi primeste si un `phase` diferit, ca cele 2-3 de
## pe coasta sa nu bata la unison ca un semafor.
##
## [b]De ce nu mosteneste WaterHazard[/b]. Structura seamana (sursa fixa, ceas
## propriu, zona care prinde masina) si tentatia e reala, dar baza aia e
## despre APA PE ASFALT: are `_wet_patch`, balta vizibila, `apply_slip`. O
## fumarola nu uda drumul si nu atinge aderenta; ar fi mostenit trei mecanisme
## ca sa le stinga pe toate. Ce SE imprumuta de acolo e tiparul, nu codul:
## `period` / `on_time` / `_time` local, exact ca `WaterHose`.

## Cat dureaza un ciclu complet, in secunde. Sub durata unui tur, deliberat:
## vezi nota despre ritm din antet.
@export var period: float = 7.0:
	set(value):
		period = maxf(value, 1.5)

## Cat din ciclu sufla efectiv aburul, in secunde.
##
## Fereastra „curata" trebuie sa ramana mai lunga decat cea cu abur: altfel
## bariera nu se mai citeste ca rafala, ci ca ceata permanenta prin care
## treci oricum — si atunci nici n-ar mai avea rost sa fie ciclica.
@export var on_time: float = 2.2:
	set(value):
		on_time = maxf(value, 0.3)

## Decalajul fata de ceasul propriu, ca doua guri vecine sa nu sufle la unison.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

## Cat de departe bate coloana peste drum. Din ea se dimensioneaza si zona.
@export var reach: float = 7.0:
	set(value):
		reach = maxf(value, 2.0)

## Cat tine albirea dupa ce masina a iesit din abur.
##
## Scurta dinadins: pedeapsa e sperietura, nu orbirea. La 0.5 s apuci sa
## tresari si ti-a trecut inainte sa apuci sa franezi din reflex — care e exact
## comportamentul pe care vrem sa-l DEZINVATE jucatorul.
@export var blind_seconds: float = 0.5

## Latimea soselei in dreptul gurii. O pune pista la construire; zona se
## intinde pe ea, ca aburul sa acopere banda, nu doar axa.
var road_width: float = 14.0

var _zone: Area3D
var _steam: CPUParticles3D
var _time: float = 0.0
var _blowing: bool = false


func _ready() -> void:
	add_to_group("fumaroles")
	_build_zone()
	_build_steam()
	# Faza se aplica o singura data, la pornire: `_time` curge de acolo mai
	# departe. Adunata in fiecare cadru ar fi fost un decalaj care se plimba.
	_time = phase * period


func _build_zone() -> void:
	_zone = Area3D.new()
	# Fara masca de coliziune proprie: zona doar RAPORTEAZA cine e inauntru
	# (`get_overlapping_bodies`), nu opreste si nu imbranceste nimic. E
	# diferenta dintre un hazard-teatru si unul care conteaza.
	_zone.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Cutia acopera latimea drumului si bate pe lungimea `reach`. Inaltimea 4 m
	# ca sa prinda masina si cand sare peste o denivelare, nu doar cand sta pe
	# roti.
	box.size = Vector3(road_width, 4.0, reach)
	shape.shape = box
	shape.position = Vector3.UP * 1.6
	_zone.add_child(shape)
	add_child(_zone)


func _build_steam() -> void:
	_steam = CPUParticles3D.new()
	_steam.emitting = false
	# Coloana porneste din gura si urca vertical, cu o imprastiere care o face
	# sa se deschida ca o ciuperca in loc sa fie un tub.
	_steam.direction = Vector3(0, 1, 0)
	_steam.spread = 14.0
	_steam.initial_velocity_min = 4.5
	_steam.initial_velocity_max = 7.0
	# Gravitatie usor NEGATIVA: aburul e mai cald decat aerul, deci urca si
	# dupa ce si-a pierdut impulsul. Cu gravitatie normala cadea inapoi in
	# gura si arata a fum de esapament.
	_steam.gravity = Vector3(0, 1.2, 0)
	_steam.amount = 48
	_steam.lifetime = 1.9
	_steam.scale_amount_min = 1.2
	_steam.scale_amount_max = 2.6
	# Bulgarii cresc pe masura ce urca — asa citeste a nor care se destinde,
	# nu a sir de bile de aceeasi marime.
	# CPUParticles3D vrea un Curve DIRECT, nu un CurveTexture — invers fata de
	# GPUParticles3D. Aceeasi capcana e notata si la particulele de boost din
	# car.gd.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(1.0, 1.0))
	_steam.scale_amount_curve = curve
	# Se subtiaza spre varf, ca sa nu aiba o margine taiata cu foarfeca.
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.55))
	grad.set_color(1, Color(0.93, 0.95, 0.97, 0.0))
	_steam.color_ramp = grad

	var puff := SphereMesh.new()
	# Rezolutie mica EXPLICIT: un SphereMesh lasat implicit are 64x32 = 4224 de
	# triunghiuri, si ar fi 48 de bucati din ele pe fiecare gura. Vezi CLAUDE.md,
	# nota despre primitivele la rezolutia implicita.
	puff.radial_segments = 6
	puff.rings = 3
	puff.radius = 0.42
	puff.height = 0.84
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Fara umbre si fara scriere in adancime: e gaz, nu obiect. Cu depth write
	# bulgarii se decupau unul pe altul si norul arata ca un morman de bile.
	mat.no_depth_test = false
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	puff.material = mat
	_steam.mesh = puff
	add_child(_steam)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var blowing := fmod(_time, period) < on_time
	if blowing != _blowing:
		_blowing = blowing
		_steam.emitting = blowing
	if not blowing:
		return
	for body in _zone.get_overlapping_bodies():
		var car := body as Car
		if car != null:
			car.blind(blind_seconds)
