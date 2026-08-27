@tool
class_name FogCorridorHazard
extends Node3D
## Culoarul de ceata de pe malul Yangtze (Chongqing, brief §2 POI E si §3): 60-80
## m de drum in care ceata se ingroasa treptat si din care IESI BRUSC.
##
## [b]E generalizarea „albirii" fumarolei, mutata din rafala in ZONA[/b].
## [FumaroleHazard] iti taie vederea 0.5 s cand treci prin dreptul ei: un
## eveniment, cu un ceas al lui, la care reactionezi. Aici nu exista ceas si nu
## exista eveniment — ceata e o proprietate a BUCATII DE DRUM, mereu acolo,
## si singurul lucru care se schimba e cat de adanc esti in ea. De aia nu
## foloseste `Car.blind()`: albirea aia e o clipa alba peste tot ecranul, iar
## ce trebuie aici e o vizibilitate care SCADE cu distanta — vezi la 20 m, nu
## vezi la 60, si stii ca virajul e undeva acolo.
##
## [b]Fara volumetrie[/b] (brief §3, si constrangerea de mobil din CLAUDE.md:
## fara post-procesare scumpa). Se misca `fog_depth_begin` / `fog_depth_end` /
## `fog_light_color` din `Environment`-ul pistei, adica exact ceata ieftina pe
## care motorul o deseneaza oricum. Costul e zero draw call-uri.
##
## Culoarul aduce UN material peste atlasul lumii, si e o decizie, nu o
## scapare: benzile reflectorizante de pe repere ard
## (`Palette.glow_material(marker_slot)`, un material partajat de toate
## reperele — vezi CLAUDE.md, „o clasa de assets poate primi un material
## partajat deliberat"). Fara el, cerinta din brief „marcajele raman vizibile
## (emisive slabe)" era indeplinita din intamplare: reperele la 12 m, ceata
## care inghite la 46. Un culoar in care poti conduce fiindca reperele sunt
## din fericire aproape nu e un culoar proiectat.
##
## [b]Ceata e a CAMEREI, nu a masinii[/b]. Environment-ul e unul singur pentru
## toata scena, deci culoarul se uita numai dupa masina jucatorului
## (`is_player`): un AI care intra in ceata nu are de ce sa albeasca ecranul
## cuiva care e cu 200 m mai in fata. Cand nu e nimeni inauntru, valorile de
## pornire se pun la loc — [b]toate[/b], inclusiv modul, fiindca altfel prima
## trecere prin culoar ar schimba definitiv atmosfera pistei.
##
## [b]Contract de cost: ZERO[/b] (aceeasi clasa cu fumarola). Nu incetineste,
## nu impinge, nu taie grip, nu are colizor. Pedeapsa e ca trebuie sa conduci
## pe memorie, si aia se plateste singura in linia pe care o ratezi. Daca
## cineva vrea sa-i adauge o incetinire „ca sa conteze", atunci nu mai e un
## culoar de ceata, e o portiune de off-road cu efect vizual.

const WorldProp = preload("res://scenes/props/world_prop.gd")
const MARKER_MODEL: String = "res://assets/models/chongqing/props/chevron_post.glb"

@export_group("Culoar")
## Lungimea culoarului (m). Brief: 60-80.
@export_range(10.0, 200.0, 1.0) var length: float = 70.0:
	set(value):
		length = value
		_rebuild()
## Semilatimea zonei. Ceva mai lata decat soseaua, ca sa prinda si masina care
## intra taind coltul.
@export_range(3.0, 30.0, 0.5) var half_width: float = 9.0:
	set(value):
		half_width = value
		_rebuild()
## Pe cati metri se ingroasa ceata la intrare. Restul culoarului o tine plina.
@export_range(1.0, 150.0, 1.0) var ramp_in: float = 45.0
## Pe cati metri se limpezeste la IESIRE.
##
## Mic dinadins — asta e tot gimmickul. Brief: „din care iesi brusc". Cu o
## valoare mare culoarul devine o pata de ceata simetrica, prin care intri si
## din care aluneci afara fara sa observi; cu 4 m, iesirea e un pocnet, si
## rasplata e ca vezi iar pana la capatul drumului.
@export_range(0.0, 60.0, 0.5) var ramp_out: float = 4.0

@export_group("Ceata")
## Cat de aproape de camera incepe ceata cand culoarul e plin (m).
@export_range(1.0, 120.0, 1.0) var fog_begin_inside: float = 8.0
## Unde inghite complet, cand culoarul e plin (m). Sub el nu se mai vede nimic.
@export_range(5.0, 300.0, 1.0) var fog_end_inside: float = 46.0
## Densitatea ceruta cand pista foloseste ceata exponentiala in loc de cea pe
## adancime. Se alege singura, dupa ce foloseste `Environment`-ul pistei.
@export_range(0.0, 0.2, 0.001) var fog_density_inside: float = 0.045
## Culoarea cetii din culoar.
@export var fog_color: Color = Color(0.72, 0.75, 0.79)

@export_group("Marcaje")
## Cati metri intre doua repere de pe margine. Trebuie sa ramana sub
## `fog_end_inside`, altfel exista pozitii din care nu se vede NICIUN reper —
## adica un culoar prin care nu poti conduce, doar ghici.
@export_range(2.0, 60.0, 0.5) var marker_spacing: float = 12.0
## Slotul de paleta al benzii reflectorizante de pe fiecare reper. Deschis, ca
## sa se desprinda din ceata.
##
## Banda e si singurul lucru din culoar care ARDE: primeste
## `Palette.glow_material(marker_slot)`, adica atlasul comun cu emisie doar pe
## texelul slotului. Fara ea, „marcajele raman vizibile" (brief §3) se rezolva
## prin distanta — reperele la 12 m, ceata care inghite la 46 — si atunci
## culoarul e citibil din intamplare, nu prin constructie.
@export_range(0, 31) var marker_slot: int = Palette.CAR_YELLOW:
	set(value):
		marker_slot = value
		_rebuild()
## Cat de puternic ard benzile. Mic: un reper care ARDE in ceata devine un far
## si sterge tot ce voia sa marcheze.
@export_range(0.0, 4.0, 0.05) var marker_glow: float = 1.2:
	set(value):
		marker_glow = value
		_rebuild()
## Inaltimea reperelor (m).
##
## Nu e o cota decorativa: e SCARA piesei. Modelul din GLB se masoara si se
## scaleaza ca sa ajunga fix la ea (si tot din ea iese scara stratului
## triplanar), iar banda reflectorizanta se aseaza in treimea de sus. Prima
## versiune o folosea doar pe ramura de rezerva, cu GLB-ul la scara lui — un
## @export mort din doua, exact obiectia criticului.
@export_range(0.3, 4.0, 0.1) var marker_height: float = 1.5:
	set(value):
		marker_height = value
		_rebuild()
@export var marker_model: PackedScene = null

var _zone: Area3D
var _env: Environment
var _amount: float = 0.0
## Valorile pistei, luate o singura data si puse la loc de fiecare data.
var _base_mode: int = Environment.FOG_MODE_DEPTH
var _base_begin: float = 0.0
var _base_end: float = 0.0
var _base_density: float = 0.0
var _base_color: Color = Color.WHITE
var _base_taken: bool = false
var _markers: Array[Node3D] = []
var _bands: Array[MeshInstance3D] = []


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_markers.clear()
	_bands.clear()
	_build_zone()
	_build_markers()


func _build_zone() -> void:
	_zone = Area3D.new()
	_zone.name = "FogZone"
	# Fara masca proprie si fara `monitorable`: culoarul RAPORTEAZA cine e
	# inauntru, nu opreste si nu imbranceste pe nimeni. Contractul de cost zero
	# e vizibil chiar in tipul nodului.
	_zone.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_width * 2.0, 8.0, length)
	shape.shape = box
	shape.position = Vector3.UP * 3.0
	_zone.add_child(shape)
	add_child(_zone)


## Reperele de pe margine: singurul lucru care ramane citibil in ceata.
##
## Nu sunt decor. Ceata pe adancime taie tot ce e peste `fog_end_inside`, deci
## fara ele culoarul ar fi un tunel alb in care volanul e o ghicitoare. Cu ele,
## conduci „din reper in reper" — care e chiar felul in care se conduce prin
## ceata adevarata.
func _build_markers() -> void:
	var scene := marker_model if marker_model != null else load(MARKER_MODEL) as PackedScene
	var n := maxi(int(round(length / maxf(marker_spacing, 1.0))), 1)
	for i in n + 1:
		var z := length * 0.5 - float(i) * (length / float(n))
		for side: float in [-1.0, 1.0]:
			var at := Vector3(side * (half_width - 0.8), 0.0, z)
			var piece: Node3D = null
			var scale := 1.0
			if scene != null:
				piece = scene.instantiate() as Node3D
			if piece != null:
				# Scara se DERIVA din inaltimea ceruta: modelul se masoara
				# (AABB pe mesh-uri), nu se presupune. Asa `marker_height`
				# conteaza si cand GLB-ul exista, si scara stratului triplanar
				# ramane cea a piesei asezate, nu cea a fisierului.
				scale = _fit_scale(piece)
				piece.scale = Vector3.ONE * scale
				piece.position = at
				Palette.apply_object_class_materials(piece,
					WorldProp.prop_classes(), scale)
			else:
				piece = PaletteBox.instance(
					Vector3(0.24, marker_height, 0.24), marker_slot,
					at + Vector3.UP * marker_height * 0.5)
				piece.position = at
			piece.name = "Marker%d%s" % [i, "L" if side < 0.0 else "R"]
			add_child(piece)
			_bands.append(_add_band(piece))
			_markers.append(piece)


## Banda reflectorizanta: o cutie subtire pe slotul de paleta, in treimea de
## sus a reperului, cu materialul care arde.
##
## Se pune pe ORICE reper, si din GLB, si din rezerva: ea e ce ramane citibil
## cand ceata inghite la 46 m, deci n-are voie sa depinda de ce fisier a fost
## gasit. Materialul e unul singur (`Palette.glow_material` e cached per slot),
## deci culoarul aduce un material, nu unul per reper.
func _add_band(piece: Node3D) -> MeshInstance3D:
	var band := PaletteBox.instance(
		Vector3(0.34, marker_height * 0.16, 0.34), marker_slot,
		piece.position + Vector3.UP * marker_height * 0.78)
	band.name = "Band%s" % piece.name
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	band.material_override = Palette.glow_material(marker_slot, marker_glow)
	# Copil al culoarului, nu al piesei: piesa din GLB e scalata ca sa ajunga
	# la `marker_height`, si banda i-ar mosteni scara inca o data.
	add_child(band)
	return band


## Cat trebuie scalat modelul ca inaltimea lui sa fie `marker_height`.
func _fit_scale(piece: Node3D) -> float:
	var h := _model_height(piece)
	if h < 0.01:
		return 1.0
	return marker_height / h


func _model_height(node: Node) -> float:
	var top := -INF
	var bottom := INF
	for child in _walk(node):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		top = maxf(top, box.position.y + box.size.y)
		bottom = minf(bottom, box.position.y)
	if top == -INF:
		return 0.0
	return top - bottom


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out


## `Environment`-ul pistei. Se cauta o singura data, in sus pe arbore: hazardul
## nu stie (si nu trebuie sa stie) cine il tine.
func _find_env() -> Environment:
	var root := get_tree().current_scene if get_tree() != null else null
	if root == null:
		root = get_parent()
	var we := _first_world_env(root)
	return we.environment if we != null else null


func _first_world_env(n: Node) -> WorldEnvironment:
	if n == null:
		return null
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for c in n.get_children():
		var found := _first_world_env(c)
		if found != null:
			return found
	return null


func _take_base() -> void:
	if _base_taken or _env == null:
		return
	_base_mode = _env.fog_mode
	_base_begin = _env.fog_depth_begin
	_base_end = _env.fog_depth_end
	_base_density = _env.fog_density
	_base_color = _env.fog_light_color
	_base_taken = true


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _env == null:
		_env = _find_env()
		_take_base()
		if _env == null:
			return
	_amount = _depth_amount()
	_apply(_amount)


## Cat de „in ceata" e masina jucatorului, 0..1.
##
## Se masoara pe adancimea ei in culoar, nu pe timp: hazardul n-are ceas, si
## doi soferi cu viteze diferite trebuie sa vada exact aceeasi ceata in
## acelasi loc.
func _depth_amount() -> float:
	if _zone == null:
		return 0.0
	for body in _zone.get_overlapping_bodies():
		var car := body as Car
		if car == null or not car.is_player:
			continue
		var local := to_local(car.global_position)
		var depth := length * 0.5 - local.z
		return _ramp(depth)
	return 0.0


## Profilul culoarului: urcare lunga, platou, cadere scurta la iesire.
func _ramp(depth: float) -> float:
	if depth <= 0.0 or depth >= length:
		return 0.0
	var rise := 1.0 if ramp_in <= 0.01 else clampf(depth / ramp_in, 0.0, 1.0)
	var left := length - depth
	var fall := 1.0 if ramp_out <= 0.01 else clampf(left / ramp_out, 0.0, 1.0)
	return minf(rise, fall)


## Ceata pistei, impinsa spre cea a culoarului cu `amount`.
##
## Se misca parametrul pe care pista il FOLOSESTE: pe ceata de adancime,
## inceputul si sfarsitul; pe cea exponentiala, densitatea. Comutarea modului
## ar fi fost mai simpla de scris si s-ar fi vazut ca un pocnet la intrare.
func _apply(amount: float) -> void:
	if _env == null or not _base_taken:
		return
	if amount <= 0.0001:
		_env.fog_mode = _base_mode
		_env.fog_depth_begin = _base_begin
		_env.fog_depth_end = _base_end
		_env.fog_density = _base_density
		_env.fog_light_color = _base_color
		return
	if _base_mode == Environment.FOG_MODE_DEPTH:
		_env.fog_depth_begin = lerpf(_base_begin, fog_begin_inside, amount)
		_env.fog_depth_end = lerpf(_base_end, fog_end_inside, amount)
	else:
		_env.fog_density = lerpf(_base_density, fog_density_inside, amount)
	_env.fog_light_color = _base_color.lerp(fog_color, amount)


func _exit_tree() -> void:
	# Un culoar scos din scena nu are voie sa lase pista in ceata lui.
	_apply(0.0)


# ---------------------------------------------------------- pentru sonde

## Cat de densa e ceata culoarului acum (0..1).
func amount() -> float:
	return _amount


## Profilul, evaluat la o adancime data — ca sonda sa-l poata verifica si fara
## sa plimbe o masina prin el.
func ramp_at(depth: float) -> float:
	return _ramp(depth)


## Ceata pistei, asa cum era inainte ca hazardul s-o atinga.
func base_fog() -> Dictionary:
	return {
		"mode": _base_mode,
		"begin": _base_begin,
		"end": _base_end,
		"density": _base_density,
		"color": _base_color,
	}


func environment() -> Environment:
	return _env


func markers() -> Array[Node3D]:
	return _markers


## Benzile reflectorizante — pentru sonda, care trebuie sa poata contrazice
## „marcajele raman vizibile": verifica emisia si numarul de materiale, nu
## faptul ca exista niste noduri.
func bands() -> Array[MeshInstance3D]:
	return _bands
