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

## Cat de mult se INCLINA, in radiani. Cateva grade — vegetatia se misca, nu
## danseaza. Peste ~0.09 incepe sa se vada ca rotatie rigida, nu ca vant.
const AMPLITUDE: float = 0.06
## Cicluri pe secunda. Lent: o adiere, nu o furtuna.
const FREQUENCY: float = 0.42
## Cat de repede se schimba faza cu distanta (rad/metru). Mic, ca sa se vada
## rafale care trec prin peisaj, nu zgomot per tufa.
const PHASE_PER_METER: float = 0.11
## Peste atatea instante nu mai adaugam — plasa de siguranta, nu buget de arta.
const MAX_ITEMS: int = 240

var _items: Array[Node3D] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _base_x: PackedFloat32Array = PackedFloat32Array()
var _base_z: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0

## --- Vegetatia coapta in MultiMesh (vezi TrackDecorBatch) --------------------
##
## Dupa coacere tufa nu mai are nod propriu: e un rand de 12 numere intr-un
## buffer. Nu se mai poate scrie `node.rotation.x`, deci se recompune toata
## transformarea si se scrie inapoi in buffer.
##
## De ce merita, cand a costat codul asta in plus: fara el, singura optiune era
## sa lasam vegetatia NEcoapta ca sa poata fi miscata — adica exact cele ~270 de
## prop-uri cele mai numeroase de pe pista ar fi ramas cate un draw call fiecare,
## si toata trecerea de coacere ar fi salvat mai putin de jumatate din cat poate.
##
## Costul de rulare: un [MultiMesh] se re-incarca la scriere, deci tine
## vegetatia SEPARATA de restul in buffere. Se intampla de la sine — gruparea e
## pe mesh, iar un smoc si o stanca nu sunt acelasi mesh — dar daca vreodata
## ajung in acelasi buffer, fiecare cadru va re-incarca si stancile degeaba.
var _mm: Array[MultiMesh] = []
var _mm_index: PackedInt32Array = PackedInt32Array()
var _mm_base: Array[Transform3D] = []
var _mm_phases: PackedFloat32Array = PackedFloat32Array()


## Inregistreaza o tufa. Se cheama la construirea decorului, nu la runtime.
func add_item(node: Node3D) -> void:
	if _count() >= MAX_ITEMS:
		return
	_items.append(node)
	_base_x.append(node.rotation.x)
	_base_z.append(node.rotation.z)
	# Faza din pozitia in lume: doua tufe la 10 m distanta se leagana vizibil
	# decalat, iar sirul intreg citeste ca o rafala care trece.
	_phases.append((node.position.x + node.position.z) * PHASE_PER_METER)


## Inregistreaza o instanta dintr-un MultiMesh copt. `base` e transformarea ei
## in repaus — se pastreaza fiindca leganarea se recalculeaza din ea in fiecare
## cadru, nu se acumuleaza peste ce era (altfel tufa s-ar culca dupa un minut).
func add_instance(mmi: MultiMeshInstance3D, index: int,
		base: Transform3D) -> void:
	if _count() >= MAX_ITEMS or mmi.multimesh == null:
		return
	_mm.append(mmi.multimesh)
	_mm_index.append(index)
	_mm_base.append(base)
	_mm_phases.append((base.origin.x + base.origin.z) * PHASE_PER_METER)


func _count() -> int:
	return _items.size() + _mm.size()


## Instantele coapte, pentru sonde (tools/probe_sway.gd). Expuse printr-o
## functie si nu prin variabile publice: tablourile paralele de mai sus sunt
## detaliu de implementare, iar o sonda care le-ar citi direct s-ar rupe la
## prima reorganizare.
func tracked_instances() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in _mm.size():
		out.append({"multimesh": _mm[i], "index": _mm_index[i]})
	return out


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
		# INCLINARE, nu rotatie pe verticala. Prima versiune rotea pe Y, cum
		# cerea issue-ul — dar o tufa aproape rotunda care se invarte in jurul
		# propriei axe nu arata NIMIC; de-aia "nu se vede vegetatia miscandu-se"
		# desi sonda raporta 6.3 grade de amplitudine. Vantul se citeste ca
		# leganare laterala. Cele doua axe cu faze diferite dau un cerc turtit,
		# nu un metronom.
		node.rotation.x = _base_x[i] + sin(w + _phases[i]) * AMPLITUDE
		node.rotation.z = _base_z[i] 			+ cos(w * 0.83 + _phases[i]) * AMPLITUDE * 0.6

	for i in _mm.size():
		var mm := _mm[i]
		if mm == null:
			continue
		var base := _mm_base[i]
		# Inclinarea se aplica in spatiul LOCAL al instantei (inmultita la
		# DREAPTA), deci pivotul e originea modelului — adica baza tufei, exact
		# ca la varianta pe noduri. Inmultita la stanga, tufa s-ar roti in jurul
		# originii pistei si ar zbura prin peisaj.
		var tilt := Basis.from_euler(Vector3(
			sin(w + _mm_phases[i]) * AMPLITUDE,
			0.0,
			cos(w * 0.83 + _mm_phases[i]) * AMPLITUDE * 0.6))
		mm.set_instance_transform(_mm_index[i],
			Transform3D(base.basis * tilt, base.origin))
