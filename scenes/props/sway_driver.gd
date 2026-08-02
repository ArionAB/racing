class_name SwayDriver
extends Node3D
## Leagana vegetatia din decor — un singur nod care misca TOATE tufele.
##
## De ce un driver unic si nu cate un script per tufa: banda lipita de drum are
## peste 100 de instante. O suta de noduri cu `_process` propriu inseamna o suta
## de apeluri de script pe cadru, pentru o rotatie de cateva grade. Aici e un
## singur `_process` care scrie intr-o bucla stransa.
##
## De ce nu shader: ar cere ca materialul lumii sa devina ShaderMaterial si sa
## reimplementeze stratul triplanar si inmultirea cu vertex color. Miscarea asta
## nu merita riscul — vezi #29.
##
## Nu tine stare per instanta: faza vine din POZITIE, deci doua tufe vecine se
## leagana defazat fara sa memoram nimic despre ele.

## Cat de mult se leagana, in radiani. Cateva grade — vegetatia se misca, nu
## danseaza. Peste ~0.09 incepe sa se vada ca rotatie rigida, nu ca vant.
const AMPLITUDE: float = 0.055
## Cicluri pe secunda. Lent: o adiere, nu o furtuna.
const FREQUENCY: float = 0.42
## Cat de repede se schimba faza cu distanta (rad/metru). Mic, ca sa se vada
## rafale care trec prin peisaj, nu zgomot per tufa.
const PHASE_PER_METER: float = 0.11
## Peste atatea instante nu mai adaugam — plasa de siguranta, nu buget de arta.
const MAX_ITEMS: int = 240

var _items: Array[Node3D] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _base_yaw: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


## Inregistreaza o tufa. Se cheama la construirea decorului, nu la runtime.
func add_item(node: Node3D) -> void:
	if _items.size() >= MAX_ITEMS:
		return
	_items.append(node)
	_base_yaw.append(node.rotation.y)
	# Faza din pozitia in lume: doua tufe la 10 m distanta se leagana vizibil
	# decalat, iar sirul intreg citeste ca o rafala care trece.
	_phases.append((node.position.x + node.position.z) * PHASE_PER_METER)


func _ready() -> void:
	# In editor decorul se regenereaza des; fara asta ar acumula rotatie.
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_time += delta
	var w := _time * TAU * FREQUENCY
	for i in _items.size():
		var node := _items[i]
		if node == null or not is_instance_valid(node):
			continue
		node.rotation.y = _base_yaw[i] + sin(w + _phases[i]) * AMPLITUDE
