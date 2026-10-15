@tool
class_name LavaFlowHazard
extends Node3D
## LIMBA DE LAVA CARE INCHIDE RUTA SCURTA (Stromboli, brief §3, POI F).
##
## Gimmick-ul pistei. Trei stadii, unul pe tur:
##
##   turul 1  `Lava_Stage1`  40 m, un brat   — ruta scurta e LIBERA
##   turul 2  `Lava_Stage2`  60 m, doua brate — poarta de 4.0 m intre ele
##   turul 3  `Lava_Stage3`  80 m, front lat  — ZID, ruta scurta e inchisa
##
## CONTRACTUL CU ASSET-UL (docs/asset_briefs/lava_set.md):
##
## Cele trei stadii sunt noduri in ACELASI `lava_flow.glb` si impart coada la
## origine — masurat, toate pleaca de la y=0 si cresc la 40/60/80 m. De aceea
## hazardul instantiaza scena O SINGURA DATA si comuta doar `visible`: nodul
## NU se muta niciodata. Daca l-ai muta la fiecare stadiu, limba ar SARI in loc
## sa avanseze, si tocmai avansul e ce trebuie sa se citeasca de sus, in timpul
## coborarii pe Sciara.
##
## COLIZIUNEA e TOT aici, si nu din comoditate: `world_prop` construieste
## corpurile o singura data, la `_ready`, pentru mesh-urile vizibile atunci —
## iar copilul (instanta GLB) isi face `_ready` inaintea parintelui care
## stinge stadiile. Rezultatul masurat: toate trei stadiile primeau colizor,
## deci zidul stadiului 3 exista INVIZIBIL inca din turul 1 si taia
## scurtatura. De aceea `lava_flow` e "none" in `world_prop.PROP_COLLISION`,
## iar hazardul isi reconstruieste trimesh-ul (poarta de 4 m trebuie sa
## ramana libera — un hull convex ar sigila-o) la fiecare stadiu.
##
## AI-UL RE-ALEGE. `prefers_shortcut` se trage o data pe cursa in
## AIController, deci fara nimic aici un AI care a decis "o iau pe scurta" ar
## intra in zid la turul 3. Hazardul expune `shortcut_open()`, iar AI-ul il
## intreaba la fiecare tur.

## Cate tururi tine fiecare stadiu. Implicit 1: stadiul creste la fiecare tur.
@export var laps_per_stage: int = 1:
	set(value):
		laps_per_stage = maxi(value, 1)

## Numele nodurilor de stadiu din GLB, in ordinea avansului. Sunt CONTRACT cu
## asset-ul — un nume gresit cade tacut pe "niciun mesh vizibil", nu pe eroare
## (avertismentul din okinawa_kit.md).
@export var stage_nodes: PackedStringArray = PackedStringArray([
	"Lava_Stage1", "Lava_Stage2", "Lava_Stage3",
])

## De la ce stadiu ruta scurta e considerata INCHISA pentru AI. Implicit 2
## (indexat de la 0), adica stadiul 3 din brief: zidul.
##
## Stadiul 2 (poarta de 4 m) ramane DESCHIS: masurat pe mesh, culoarul e de
## 4.00 m liberi, iar masina are 1.8 m — trece, dar cere linie curata. Aia e
## decizia pe care o vindem, deci n-o luam noi de la jucator.
@export var closed_from_stage: int = 2

## Indexul benzii secundare pe care o inchide (in ordinea din Track.routes).
@export var branch_index: int = 1

## Cat de sus porneste raza de asezare pe teren si cat de jos merge (m).
const DRAPE_UP: float = 3.0
const DRAPE_DOWN: float = 120.0

signal stage_changed(stage: int)

var _stage: int = 0
var _laps: int = 0
var _meshes: Array[Node3D] = []
## Stadiile deja asezate pe teren (vezi `_drape_stage`).
var _draped := {}


func _ready() -> void:
	_collect()
	_apply()
	# Asezarea pe teren cere colizorul lumii, care la `_ready` inca nu e in
	# spatiul fizic: masurat, toate cele 217 raze ale stadiului 1 cadeau in gol
	# si limba ramanea exact cum venea din .glb. Se reia dupa primul pas de
	# fizica, cand terenul exista (acelasi tipar ca adormirea din BumpProp).
	if not Engine.is_editor_hint():
		get_tree().physics_frame.connect(func() -> void:
			# TOATE stadiile, nu doar cel curent: 2 si 3 apar la turul 2 si 3,
			# iar atunci terenul de sub ele e acelasi. Asezarea costa cateva
			# sute de raze o singura data, la pornirea cursei, in loc de un
			# hopa vizibil exact in cadrul in care limba creste.
			for si in _meshes.size():
				_drape_stage(si)
			_rebuild_collision(), CONNECT_ONE_SHOT)
	# Grupul comun de "porti de banda" (Track.branch_is_open, generalizat sep
	# 2026 pentru vaca de la Jodhpur): orice nod cu `branch_index` +
	# `shortcut_open()` intra aici, ca pista sa-l gaseasca fara sa-i cunoasca
	# tipul. Precedentul e lava, deci grupul se alatura, nu se creeaza.
	add_to_group(Track.BRANCH_GATE_GROUP)


## Se apeleaza din Race la fiecare tur incheiat de LIDER (nu de jucator: lava
## e o proprietate a lumii, nu a cursei tale).
func on_lap_completed() -> void:
	_laps += 1
	var want := mini(_laps / laps_per_stage, stage_nodes.size() - 1)
	if want != _stage:
		_stage = want
		_apply()
		stage_changed.emit(_stage)


## Poate AI-ul sa mai ia scurtatura? Intrebat la fiecare tur, nu o data pe cursa.
func shortcut_open() -> bool:
	return _stage < closed_from_stage


func current_stage() -> int:
	return _stage


## Strange nodurile de stadiu din subarbore, dupa NUME.
##
## Cauta recursiv fiindca importul GLB baga mesh-urile sub un nod-radacina cu
## numele fisierului; daca schimbi structura scenei, numele raman ancora.
func _collect() -> void:
	_meshes.clear()
	for n in stage_nodes:
		var found := _find_by_name(self, String(n))
		if found == null:
			push_warning("LavaFlowHazard: lipseste nodul '%s' — verifica "
				% n + "numele din lava_flow.glb (sunt contract)")
		_meshes.append(found)


func _find_by_name(node: Node, want: String) -> Node3D:
	for child in node.get_children():
		if child.name == want and child is Node3D:
			return child as Node3D
		var deep := _find_by_name(child, want)
		if deep != null:
			return deep
	return null


## Un singur stadiu vizibil. Variantele stinse NU intra in numaratoarea garzii
## (`probe_decor` numara doar ce se randeaza) — de-asta stau toate trei in
## scena, in loc sa se instantieze la schimbare.
func _apply() -> void:
	for i in _meshes.size():
		var m := _meshes[i]
		if m != null:
			m.visible = (i == _stage)
	_rebuild_collision()


## CURGE PE TEREN, nu pluteste peste el (#512).
##
## Limba din .glb e o placa de 1 m grosime si pana la 48 m lungime, asezata cu
## un singur transform: o inclinare medie, buna la coada si gresita peste tot
## in rest. Masurat cu `ProbeLavaFit` pe Track11 inainte de reparatie, talpa
## statea in aer cu mediana 0,84–1,37 m si pana la 96% din puncte peste 0,5 m —
## adica o limba intreaga plutind la inaltimea unei masini.
##
## Aici fiecare vertex e COBORAT pe relief: o raza in jos din vertex gaseste
## terenul, iar vertexul se muta la cota aia plus inaltimea lui fata de talpa
## limbii (deci crusta isi pastreaza grosimea si bombarea, doar urmeaza panta).
## Raza merge pe colizorul real al lumii, nu pe `TrackSideSampler.ground_y`:
## limbile stau departe de sosea, pe flancul conului, iar `ground_y` deriva
## terenul din punctele DRUMULUI si extrapoleaza acolo (memoria
## `terrain-mesh-y-extrapoleaza` — exact asa ajung prop-urile sa pluteasca).
##
## Se face o SINGURA data per stadiu, la pornirea cursei (vezi `_ready`), nu pe
## cadru si nu la schimbarea stadiului: sunt cateva sute de raze per stadiu,
## iar terenul de sub limba e acelasi in toate trei.
func _drape_stage(stage: int) -> void:
	if Engine.is_editor_hint() or stage < 0 or stage >= _meshes.size():
		return
	var m := _meshes[stage] as MeshInstance3D
	if m == null or m.mesh == null or _draped.has(stage):
		return
	var space := get_world_3d().direct_space_state
	if space == null:
		if OS.get_environment("LAVA_DRAPE_TRACE") == "1":
			print("[drape] %s stadiu %d: FARA space" % [name, stage + 1])
		return
	var src := m.mesh
	var arrays := src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return
	var xf := m.global_transform
	var inv := xf.affine_inverse()
	# Reperul de la care se masoara inaltimea fiecarui vertex.
	#
	# NU minimul global: masurat pe `lava_flow.glb`, limba nu are burta — e o
	# fata de sus la y~0,7-0,9 plus o fusta subtire de ~44-63 vertecsi la y=0.
	# Cu minimul (0,0) ca reper, fata de sus pastra un `rise` de ~0,8 m si
	# limba ramanea exact atat in aer (masurat: mediana 0,81, toate valorile
	# gramada la 0,86 — offset fix, nu eroare de panta).
	#
	# Reperul e deci MEDIANA lui y: coada de jos a distributiei e fusta, iar
	# corpul limbii se aseaza pe teren cu grosimea lui reala deasupra.
	var ys: PackedFloat32Array = PackedFloat32Array()
	for v in verts:
		ys.append(v.y)
	ys.sort()
	var base_y: float = ys[ys.size() / 2]
	# Cache de teren pe o grila de 1 m: vertecsii vin in grupuri dese, iar o
	# raza per vertex ar fi de cateva ori mai multe decat e nevoie.
	var cache := {}
	var moved := 0
	for i in verts.size():
		var local := verts[i]
		var w := xf * local
		var key := Vector2i(roundi(w.x), roundi(w.z))
		var gy: float = cache.get(key, INF)
		if is_inf(gy):
			gy = _ground_under(space, w)
			cache[key] = gy
		if is_inf(gy):
			continue
		# Inaltimea vertexului peste talpa, PE VERTICALA LUMII.
		var foot_w := xf * Vector3(local.x, base_y, local.z)
		var rise := w.y - foot_w.y
		var target := Vector3(w.x, gy + rise, w.z)
		if absf(target.y - w.y) > 0.01:
			moved += 1
		verts[i] = inv * target
	if OS.get_environment("LAVA_DRAPE_TRACE") == "1":
		print("[drape] %s stadiu %d: %d/%d vertecsi mutati" % [
			name, stage + 1, moved, verts.size()])
	if moved == 0:
		return
	arrays[Mesh.ARRAY_VERTEX] = verts
	# Normalele vin din .glb pentru placa PLANA; dupa ce vertecsii urmeaza
	# panta, ele mint, iar crusta se umbreste ca si cum ar fi tot orizontala.
	# Se recalculeaza din triunghiurile noi, cu acelasi criteriu de netezire
	# ca importul (medie pe vertex).
	arrays[Mesh.ARRAY_NORMAL] = _recalc_normals(verts,
		arrays[Mesh.ARRAY_INDEX] as PackedInt32Array)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	for si in src.get_surface_count():
		if si == 0:
			am.surface_set_material(0, src.surface_get_material(0))
	m.mesh = am
	_draped[stage] = true


## Normale per vertex din triunghiurile date: media normalelor fetelor care
## ating vertexul. Fara ele, o limba asezata pe panta ramane umbrita ca o placa
## orizontala.
func _recalc_normals(verts: PackedVector3Array,
		idx: PackedInt32Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in out.size():
		out[i] = Vector3.ZERO
	var tri := idx.size() / 3
	for t in tri:
		var a := idx[t * 3]
		var b := idx[t * 3 + 1]
		var c := idx[t * 3 + 2]
		var n := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		out[a] += n
		out[b] += n
		out[c] += n
	for i in out.size():
		var v := out[i]
		out[i] = v.normalized() if v.length_squared() > 1e-12 else Vector3.UP
	return out


## Cota terenului sub un punct din lume, sau INF daca nu e nimic.
##
## Ignora corpurile propriei limbi (si pe ale celorlalte stadii): altfel prima
## raza ar gasi crusta de deasupra si limba s-ar ridica singura, tur dupa tur.
func _ground_under(space: PhysicsDirectSpaceState3D, w: Vector3) -> float:
	var from := w + Vector3.UP * DRAPE_UP
	var to := w + Vector3.DOWN * DRAPE_DOWN
	var q := PhysicsRayQueryParameters3D.create(from, to)
	for _try in 4:
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return INF
		var node := hit.collider as Node
		if node != null and not is_ancestor_of(node):
			return (hit.position as Vector3).y
		# A lovit propria crusta: continua de sub ea.
		q.from = (hit.position as Vector3) + Vector3.DOWN * 0.05
	return INF


## Colizorul urmeaza stadiul (vezi antetul: de ce nu e treaba lui world_prop).
## Trimesh pe mesh-ul vizibil, copil al lui — mosteneste transformul, deci nu
## depinde de cum e rotit/inclinat nodul in scena.
func _rebuild_collision() -> void:
	if Engine.is_editor_hint():
		return
	for i in _meshes.size():
		var m := _meshes[i] as MeshInstance3D
		if m == null:
			continue
		var body := m.get_node_or_null("stage_col") as StaticBody3D
		if i == _stage and body == null:
			body = StaticBody3D.new()
			body.name = "stage_col"
			body.set_meta("mod_coliziune", "mesh")
			# Contactul cu lava e distrugere, nu perete: Car._process_contacts
			# citeste meta si se arde (turtire + repunere din stand).
			body.set_meta("lava", true)
			var cs := CollisionShape3D.new()
			cs.shape = m.mesh.create_trimesh_shape()
			body.add_child(cs)
			m.add_child(body)
		elif i != _stage and body != null:
			body.queue_free()
