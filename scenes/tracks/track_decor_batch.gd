class_name TrackDecorBatch
extends RefCounted
## Coace decorul deja construit in [MultiMeshInstance3D]-uri: acelasi vizual, la
## jumatate din draw call-uri.
##
## Masurat cu tools/ProbeFrame.tscn, varf pe tur, cu umbre:
##   Dunele          1001 -> 512
##   Stramtoarea      790 -> 471
##   Okinawa manual  1364 -> 657
## Geometria e IDENTICA — coloana `tri (frustum)` din aceeasi sonda da acelasi
## numar inainte si dupa, pana la ultima cifra. Coacerea nu schimba ce exista si
## unde, doar cum se trimite.
##
## MASURATOAREA CARE A CERUT-O (tools/ProbeFrame.tscn, Dunele):
##   721 draw calls fara umbre, la 1017 mesh-uri in scena.
## Adica aproape fiecare prop e propriul lui apel de desenare, desi toate
## impart acelasi material de atlas. Godot NU uneste noduri [MeshInstance3D]
## separate — materialul comun tine jos numarul de SCHIMBARI DE STARE, dar nu
## numarul de apeluri. Garda din tools/probe_decor.gd numara materiale si are
## dreptate ca un material e *cel putin* un draw call; ce n-a spus niciodata e
## ca factorul care leaga in practica e cate OBIECTE distincte sunt in cadru.
##
## DE CE O TRECERE DE COACERE, si nu emisie directa in multimesh din
## `_place_band_prop`: logica de plasare din track_decor.gd e partea cea mai
## tunata din tot proiectul (benzi, goluri, grupari, steaguri de siguranta,
## siruri rng calibrate). O rescriere ca sa emita altfel ar fi pus in joc luni
## de tuning pentru un castig care e strict de randare. Aici geometria e deja
## asezata; noi doar o mutam din N noduri intr-un buffer.
##
## CE RAMANE NOD:
##   - corpurile fizice ([StaticBody3D] + forma). Un MultiMesh n-are coliziune,
##     dar nici nu costa draw call-uri, deci raman exact cum erau.
##   - [SwayDriver], care nu mai misca noduri ci scrie direct in buffer —
##     vezi `add_instance` acolo.
##
## DE CE PE CELULE si nu un singur multimesh pe pista: un MultiMesh se deseneaza
## INTREG sau deloc — n-are culling per instanta. Un buffer pe toata pista ar
## trimite la GPU si tot ce e in spatele camerei, si tot ce e dincolo de ceata.
## Impartit pe celule, culling-ul de frustum lucreaza mai departe pe celula.

## Latura celulei de grupare, in metri.
##
## Compromisul teoretic: celule mici = taiere fina, dar mai multe buffere (deci
## mai multe apeluri); celule mari = putine apeluri, dar trimitem geometrie care
## nu se vede.
##
## Masurat pe Dunele (varf de draw calls, fara umbre) — nu ales din teorie:
##    60 m -> 559     150 m -> 478     250 m -> 423     1000 m -> 421
## Curba se aplatizeaza la 250; peste, nu se mai castiga nimic. Iar partea de
## sus a compromisului s-a dovedit mult mai ieftina decat pare: media de
## geometrie pe cadru a stat la 89-94k pe TOT intervalul, fiindca pistele sunt
## bucle compacte in care oricum vezi mai toata scena. Deci celulele mari nu
## costa aici aproape nimic.
##
## 250 si nu 1000, desi dau acelasi numar: la 250 o celula tot NU acopera toata
## pista, deci taierea ramane reala pe o pista mai lunga sau mai intortocheata
## decat cele de azi. Aceeasi cifra, mai putina credinta ca lumea nu se schimba.
const CELL_M: float = 250.0

## Marcheaza un nod ca fiind vegetatie care se leagana. Se pune la plasare, se
## citeste la coacere: dupa ce nodul dispare in buffer, singurul mod de a mai sti
## care instanta era tufa e sa fi lasat semnul dinainte.
const SWAY_META: StringName = &"sway"

## ############################################################################
## OGLINDIREA NU SUPRAVIETUIESTE COACERII — de aceea exista `_flipped_mesh`.
##
## Un prop asezat cu `scale.x = -1` ramane vizibil cat timp e un
## [MeshInstance3D]: Godot vede determinantul negativ al instantei si intoarce
## singur sensul fetelor (masurat, tools/MirrorTest.tscn — nota din
## `Palette` spune corect ca materialul geaman CULL_FRONT de acolo era un al
## doilea flip, deci o greseala).
##
## Pentru instantele dintr-un MULTIMESH compensarea NU se face: transformarea
## sta in buffer, nu pe nod, iar rasterizatorul primeste triunghiuri cu
## winding-ul deja rasturnat si le culege ca fete din spate. Masurat pe 4.7
## (tools/MultiMeshTest.tscn): acelasi quad CULL_BACK e alb ca MeshInstance3D
## oglindit si NEGRU ca instanta oglindita de multimesh.
##
## Efectul in joc, si motivul pentru care sonda asta a fost scrisa: `TrackCliffs`
## oglindeste jumatate din sectiunile de canion, iar dupa ce coacerea a intrat pe
## main jumatate din peretii fiecarei piste si-au pierdut fata dinspre sofer. Ce
## se vedea prin ea era interiorul sectiunii — bugul „stancile sunt goale pe
## dinauntru". Nu era regresie de asset: exact aceleasi mesh-uri, exact aceleasi
## pozitii, doar trimise altfel la GPU.
##
## Reparatia NU e materialul geaman CULL_FRONT (ar fi corect aici, dar ar adauga
## un material pe clasa oglindita — exact axa pe care o numara garda). E un mesh
## cu triunghiurile intoarse: al doilea flip il aduce inapoi pe cel bun, iar
## normalele raman ale mesh-ului original, deci lumina nu se schimba. Costa un
## [ArrayMesh] per varianta oglindita (sute de triunghiuri), zero materiale.
## ############################################################################


## Coace tot subarborele `root`. Intoarce un dictionar cu ce s-a intamplat, ca
## sondele si log-ul de build sa aiba cifre, nu impresii.
static func bake(root: Node3D, sway: SwayDriver = null) -> Dictionary:
	var groups := {}
	var sources: Array[MeshInstance3D] = []
	# Cache-ul de mesh-uri intoarse traieste cat o coacere: acelasi mesh sursa
	# oglindit de 60 de ori da UN singur ArrayMesh, deci un singur buffer.
	var flipped := {}
	_collect(root, Transform3D.IDENTITY, false, groups, sources, flipped)
	if groups.is_empty():
		return {"instances": 0, "batches": 0, "freed": 0}

	# Sursele se scot INAINTE de a adauga multimesh-urile, ca sa nu existe nici
	# macar un cadru cu geometria dublata.
	for mi in sources:
		# Un copil mesh al unei surse deja eliberate a plecat odata cu ea.
		if not is_instance_valid(mi):
			continue
		mi.get_parent().remove_child(mi)
		mi.free()

	var holder := Node3D.new()
	holder.name = "Batched"
	root.add_child(holder)

	var instances := 0
	for key: String in groups:
		var g: Dictionary = groups[key]
		var xforms: Array = g["xforms"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = g["mesh"]
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i])
		var mmi := MultiMeshInstance3D.new()
		# Numele PASTREAZA numele variantei sursa, si nu din cochetarie:
		# `probe_decor._source_of` atribuie fiecare vizual unui GLB dupa
		# prefixul numelui. Botezat "Batch_17", tot decorul pistei ar fi
		# raportat ca "procedural (track.gd)" si garda ar deveni oarba —
		# exact modul de esec descris in fisierul ala.
		mmi.name = "%s_%s" % [g["name"], g["cell"]]
		mmi.multimesh = mm
		mmi.material_override = g["mat"]
		mmi.cast_shadow = g["shadow"]
		holder.add_child(mmi)
		instances += xforms.size()
		if sway != null:
			for idx: int in g["sway"]:
				sway.add_instance(mmi, idx, xforms[idx])

	var freed := _prune_empty(root)
	return {
		"instances": instances,
		"batches": groups.size(),
		"freed": freed,
	}


## Parcurge subarborele adunand vizualele, cu transformarea acumulata de la
## `root` in jos.
##
## Transformarea se compune de mana in loc sa citim `global_transform` fiindca
## decorul se coace INAINTE sa intre in arbore (TrackDecor.build intoarce un nod
## nelegat, iar Track il adauga dupa). Fara parinte in arbore, `global_transform`
## nu inseamna nimic.
static func _collect(node: Node3D, xf: Transform3D, swaying: bool,
		groups: Dictionary, sources: Array[MeshInstance3D],
		flipped: Dictionary) -> void:
	var here := xf * node.transform
	var sways := swaying or node.has_meta(SWAY_META)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null and mi.material_override != null:
			_add(mi, here, sways, groups, flipped)
			sources.append(mi)
		# NU se opreste aici: un mesh poate avea copii mesh (coroana de molid cu
		# trunchiul sub ea, `Pine_X` > `Trunk_X`). Prima versiune intorcea
		# dupa parinte si trunchiul disparea tacut din padure — pe captura,
		# brazii pluteau fara picior. Coborarea continua cu transformarea
		# parintelui inclusa, deci copilul ajunge exact unde il pune GLB-ul.
	for c in node.get_children():
		if c is Node3D and not c.is_queued_for_deletion():
			_collect(c as Node3D, here, sways, groups, sources, flipped)


static func _add(mi: MeshInstance3D, xf: Transform3D, swaying: bool,
		groups: Dictionary, flipped: Dictionary) -> void:
	var cell := Vector2i(
		int(floor(xf.origin.x / CELL_M)), int(floor(xf.origin.z / CELL_M)))
	# Instanta oglindita primeste mesh-ul cu triunghiurile intoarse (vezi nota
	# de la inceputul fisierului). Se separa de la sine in alt grup, fiindca
	# cheia contine mesh-ul.
	var mesh := mi.mesh
	var mirrored := xf.basis.determinant() < 0.0
	if mirrored:
		mesh = _flipped_mesh(mesh, flipped)
	# Cheia trebuie sa contina mesh SI material: acelasi mesh cu doua materiale
	# sunt doua desenari oricum, iar un multimesh are un singur material.
	var key := "%d|%d|%d|%d" % [mesh.get_instance_id(),
		mi.material_override.get_instance_id(), cell.x, cell.y]
	if not groups.has(key):
		groups[key] = {
			"mesh": mesh,
			"mat": mi.material_override,
			# Sufixul pastreaza numele variantei (de care depinde `probe_decor`
			# ca sa stie din ce GLB vine geometria) si spune totusi care buffer
			# e cel oglindit, fara sa lase Godot sa dezambiguizeze cu un "2".
			"name": String(mi.name) + ("_m" if mirrored else ""),
			"cell": "%d_%d" % [cell.x, cell.y],
			"shadow": mi.cast_shadow,
			"xforms": [] as Array[Transform3D],
			"sway": [] as Array[int],
		}
	var g: Dictionary = groups[key]
	var xforms: Array = g["xforms"]
	if swaying:
		(g["sway"] as Array).append(xforms.size())
	xforms.append(xf)


## Acelasi mesh cu triunghiurile parcurse invers.
##
## Se schimba DOAR ordinea indicilor: pozitiile, normalele si UV-urile raman
## bit-identice, fiindca oglindirea le face deja transformarea instantei (pentru
## o scalare pe o axa, matricea normalelor e chiar ea insasi). Singurul lucru pe
## care transformarea NU-l poate repara e sensul in care rasterizatorul vede
## triunghiul, si exact ala se inverseaza aici.
##
## Mesh-urile fara buffer de indici primesc unul: e mai ieftin decat sa
## rescriem toate atributele vertexilor, si la scara asta (sute de triunghiuri)
## nu se simte.
static func _flipped_mesh(src: Mesh, cache: Dictionary) -> Mesh:
	var id := src.get_instance_id()
	if cache.has(id):
		return cache[id]
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			var count := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			idx.resize(count)
			for i in count:
				idx[i] = i
		var tri := idx.size() / 3
		for t in tri:
			var a := idx[t * 3]
			idx[t * 3] = idx[t * 3 + 2]
			idx[t * 3 + 2] = a
		arrays[Mesh.ARRAY_INDEX] = idx
		var prim := Mesh.PRIMITIVE_TRIANGLES
		if src is ArrayMesh:
			prim = (src as ArrayMesh).surface_get_primitive_type(s)
		if prim != Mesh.PRIMITIVE_TRIANGLES:
			# Nimic din decor nu e linie sau punct azi; daca ajunge sa fie,
			# intoarcerea indicilor n-ar insemna nimic pentru primitiva aia.
			continue
		out.add_surface_from_arrays(prim, arrays)
	cache[id] = out
	return out


## Sterge nodurile ramase goale dupa ce vizualul lor a plecat in buffer:
## containerele de GLB si suportii prop-urilor fara coliziune.
##
## Conditia e stricta INTENTIONAT — `get_class() == "Node3D"` plus fara script
## si fara copii. Corpurile fizice raporteaza "StaticBody3D" si scapa; iar fara
## testul de script ar cadea si [SwayDriver], care e tot un Node3D fara copii si
## a carui disparitie ar opri vantul fara nicio eroare in consola.
static func _prune_empty(root: Node) -> int:
	var freed := 0
	# Doua treceri: prima goleste containerele de GLB, a doua suportii ramasi
	# goi in urma lor.
	for _pass in 2:
		for node in _walk(root):
			if node == root or node.get_child_count() > 0:
				continue
			if node.get_class() != "Node3D" or node.get_script() != null:
				continue
			node.get_parent().remove_child(node)
			node.free()
			freed += 1
	return freed


static func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_walk(c))
	return out
