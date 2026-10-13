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
	var instances := _emit(groups, holder, sway)

	var freed := _prune_empty(root)
	return {
		"instances": instances,
		"batches": groups.size(),
		"freed": freed,
	}


## Scrie cate un [MultiMeshInstance3D] per grup sub `holder`. Comun pentru
## `bake` si `bake_manual`; intoarce numarul de instante scrise.
static func _emit(groups: Dictionary, holder: Node3D, sway: SwayDriver) -> int:
	var instances := 0
	for key: String in groups:
		var g: Dictionary = groups[key]
		var xforms: Array = g["xforms"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = g["mesh"]
		mm.instance_count = xforms.size()
		var nu := bool(g.get("nu", false))
		var undo := Transform3D(Basis.from_scale(NU_SCALE).inverse(), Vector3.ZERO)
		for i in xforms.size():
			mm.set_instance_transform(i, undo * xforms[i] if nu else xforms[i])
		var mmi := MultiMeshInstance3D.new()
		if nu:
			mmi.scale = NU_SCALE
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
	return instances


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
		groups: Dictionary, flipped: Dictionary,
		extra_key: String = "", cell_m: float = CELL_M) -> String:
	var cell := Vector2i(
		int(floor(xf.origin.x / cell_m)), int(floor(xf.origin.z / cell_m)))
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
	# `bake_manual` adauga umbra si latura celulei (vezi acolo).
	key += extra_key
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
	return key


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


## ############################################################################
## DECORUL MANUAL (DecorManual) — aceeasi coacere, la incarcarea cursei.
##
## Masurat pe iPhone 12 Pro (video din 12 oct 2026, Jodhpur): 22-38 fps pe
## dreptele deschise, la 1700-2300 de desene; 60 fps in fort, la 150-350. Iar
## defalcarea pe grupuri (stinge grupul, masoara) la frac 0,917: casele puse de
## mana dau 1264 de desene si tarabele/sacii/coviltirele/ghirlandele inca 672,
## adica ~85% din cadru. Cele 571 de case din OrasFill, deja MultiMesh pe
## celule, costa 80. Fiecare GLB pus de mana e 3-5 noduri de mesh, iar fiecare
## nod e propriul apel de desenare.
##
## DecorManual ramane SURSA DE ADEVAR in .tscn (memoria
## `decor-manual-sursa-de-adevar`): coacerea se face doar in joc, niciodata in
## editor, si nu scrie nimic in scena.
##
## Fata de `bake` sunt cinci diferente, toate din cauza ca aici nodurile sunt
## asezate de mana si unele traiesc:
##   - sursele se ASCUND (visible = false), nu se elibereaza: un script care tine
##     o referinta la un nod de mesh nu ramane cu un obiect mort.
##   - variantele stinse (`visible = false`) ale GLB-urilor multi-varianta nu se
##     coc: n-au fost niciodata pe ecran si nu trebuie sa apara acum.
##   - orice subarbore cu script propriu (felinare, stoluri, lumini, kituri,
##     hazarde, CameraZone) ramane nod, fiindca scriptul poate misca sau schimba
##     ce e sub el. La fel orice GLB cu [AnimationPlayer] sau [Skeleton3D].
##   - umbra intra in cheie: WorldProp stinge umbra pe unele modele
##     (NO_SHADOW_MODELS), iar un grup are o singura setare.
##   - mesh-urile atinse de un [Decal] primesc celule mici, iar cele din raza
##     unei lumini omni/spot raman noduri (vezi mai jos).
## Coliziunea nu se atinge: corpurile [StaticBody3D] raman unde sunt.
##
## DECALURILE: rendererul Mobile plafoneaza la 8 decalurile pe instanta de
## mesh, iar un MultiMesh e O instanta. Pe Jodhpur, decalurile calde de pe
## fatade (`StreetLights.facade_wash`, 83 pe pista) disparusera de pe jumatate
## din case cu celule de 250 m — masurat prin diff de pixeli cu/fara coacere,
## singura diferenta din cadru. Celule de 60 m pe tot decorul le aduceau
## inapoi, dar varful de desene urca de la 695 la 1203. Deci doar mesh-urile
## al caror AABB atinge un decal merg pe celule de `DECAL_CELL_M`; restul pe
## cei 250 m ai lui `bake`.
##
## LUMINILE LOCALE au acelasi plafon (8 omni + 8 spot pe instanta, Mobile): in
## caverna Cappadocia (Track13) peretele isi pierdea lumina calda a
## felinarelor la celule de 250 m, si panourile luminate tot se stingeau la
## 40 m (sala are mai mult de 8 lumini pe o celula). Deci mesh-urile din raza
## unei [OmniLight3D]/[SpotLight3D] a pistei raman noduri — fiecare cu cele
## mai apropiate 8 lumini ale lui, ca inainte.
const DECAL_CELL_M: float = 40.0

## SCALAREA NEUNIFORMA: shaderul Godot alege matricea normalelor dupa steagul
## de scalare neuniforma al NODULUI. Un [MultiMeshInstance3D] cu scala 1 nu-l
## are, deci normalele unei instante turtite pe o axa (225 de piese pe Jodhpur,
## 482 pe Okinawa) se transformau cu matricea modelului, nu cu inversa ei
## transpusa: fetele de sus ale stancilor ieseau mai intunecate (diff de pixeli
## pe Track08). Grupurile cu astfel de instante primesc pe nod o scala
## neuniforma infima, compensata exact in transformarile instantelor, ca
## shaderul sa calculeze normalele corect. Geometria nu se misca.
const NU_SCALE := Vector3(1.0, 1.0, 1.001)

## PROIECTIA TRIPLANARA DE LUME nu supravietuieste coacerii pe rendererul
## Mobile: in MultiMesh textura iese proiectata ca si cum instanta n-ar avea
## rotatia ei (benzi verticale in loc de orizontale pe stancile rock_slab de pe
## Jodhpur; diff de pixeli 0,63% -> 0,06% cand le scoti din coacere). Piesele
## pe astfel de materiale (clasele `tri:` — roca, tuf, riolit) raman noduri.
## Pe Jodhpur sunt ~770 din 3554; restul se coace.
##
## La fel, o instanta cu bazei degenerata (determinant ~0, de ex. `zidValea52`
## pe Cappadocia, scara pe Y = 0 in .tscn) nu deseneaza nimic ca nod, dar in
## MultiMesh iesea intinsa pe cer. Ramane nod, adica tot nimic.
static func _world_triplanar(m: Material) -> bool:
	var sm := m as StandardMaterial3D
	return sm != null and (sm.uv1_world_triplanar or sm.uv2_world_triplanar)

static func _non_uniform(b: Basis) -> bool:
	var s := b.get_scale().abs()
	return maxf(s.x, maxf(s.y, s.z)) > minf(s.x, minf(s.y, s.z)) * 1.001

static func bake_manual(dm: Node3D, decal_cell_m: float = DECAL_CELL_M) -> Dictionary:
	var groups := {}
	var sources: Array[MeshInstance3D] = []
	var flipped := {}
	var to_local := dm.global_transform.affine_inverse()
	# Decalurile si luminile locale din toata pista (StreetLights sta in
	# DecorManual, dar un decal sau o lumina poate fi si in afara lui), ca AABB
	# de lume. O lumina omni/spot se aproximeaza cu cutia sferei ei de raza.
	var decals: Array[AABB] = []
	var lights: Array[AABB] = []
	var scope: Node = dm.get_parent() if dm.get_parent() != null else dm
	for d in scope.find_children("*", "Decal", true, false):
		var dec := d as Decal
		decals.append(dec.global_transform * AABB(-dec.size * 0.5, dec.size))
	for l in scope.find_children("*", "Light3D", true, false):
		var r := 0.0
		if l is OmniLight3D:
			r = (l as OmniLight3D).omni_range
		elif l is SpotLight3D:
			r = (l as SpotLight3D).spot_range
		if r > 0.0:
			var c := (l as Node3D).global_position
			lights.append(AABB(c - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	var ctx := {"to_local": to_local, "decals": decals, "lights": lights,
		"cell": decal_cell_m,
		"groups": groups, "sources": sources, "flipped": flipped}
	for c in dm.get_children():
		if c is Node3D:
			_collect_manual(c as Node3D, ctx)
	if groups.is_empty():
		return {"instances": 0, "batches": 0, "hidden": 0}
	for mi in sources:
		mi.visible = false
	var holder := Node3D.new()
	holder.name = "Batched"
	dm.add_child(holder)
	var instances := _emit(groups, holder, null)
	return {
		"instances": instances,
		"batches": groups.size(),
		"hidden": sources.size(),
	}


static func _collect_manual(node: Node3D, ctx: Dictionary) -> void:
	if not node.visible or node.is_queued_for_deletion():
		return
	if node.get_script() != null:
		return
	# Radacina unui GLB instantiat: daca are animatie sau schelet, tot modelul
	# ramane nod (oasele misca mesh-urile, iar bufferul ar ingheta poza).
	if node.scene_file_path != "":
		if not node.find_children("*", "AnimationPlayer", true, false).is_empty() \
				or not node.find_children("*", "Skeleton3D", true, false).is_empty():
			return
	if node is MeshInstance3D and _bakeable(node as MeshInstance3D, ctx["lights"]):
		var mi := node as MeshInstance3D
		var world := mi.global_transform * mi.get_aabb()
		var cell_m := CELL_M
		for box: AABB in ctx["decals"]:
			if box.intersects(world):
				cell_m = float(ctx["cell"])
				break
		var xf := (ctx["to_local"] as Transform3D) * mi.global_transform
		var nu := _non_uniform(xf.basis)
		var key := _add(mi, xf, false, ctx["groups"], ctx["flipped"],
			"|s%d|c%d|n%d" % [mi.cast_shadow, int(cell_m), int(nu)], cell_m)
		if nu:
			(ctx["groups"][key] as Dictionary)["nu"] = true
		(ctx["sources"] as Array).append(mi)
	# Coborarea continua si sub un mesh necopt: copiii lui (trunchiul de sub
	# coroana) se judeca separat.
	for c in node.get_children():
		if c is Node3D:
			_collect_manual(c as Node3D, ctx)


## Un nod de mesh se coace doar daca nimic din el nu depinde de instanta: un
## singur material pe tot mesh-ul, fara schelet, fara proiectie de lume, cu
## baza nedegenerata si in afara razei oricarei lumini locale.
static func _bakeable(mi: MeshInstance3D, lights: Array) -> bool:
	if mi.mesh == null or mi.material_override == null or mi.skin != null:
		return false
	if _world_triplanar(mi.material_override):
		return false
	if absf(mi.global_transform.basis.determinant()) <= 1e-6:
		return false
	var world := mi.global_transform * mi.get_aabb()
	for box: AABB in lights:
		if box.intersects(world):
			return false
	return true
