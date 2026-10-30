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
##
## REMASURAT pe Jodhpur si Kyoto (27 oct 2026, ProbePerf --mobile --cell=N,
## celulele si pe CityFill): celulele mai mici NU taie triunghiuri, le ADAUGA.
##    Jodhpur  250 m: 800k tri medie / 554 desene    Kyoto 250 m: 812k / 634
##             100 m: 810k / 645                            60 m: 850k / 960
##              60 m: 828k / 729
##              40 m: 848k / 795
## Motivul: Godot alege LOD-ul unui MultiMesh dupa distanta pana la cel mai
## APROPIAT punct al AABB-ului lui, deci o celula mare care contine camera
## trage tot ce e in ea la detaliu intreg, dar restul celulelor mari ajung
## departe si coboara; cu celule mici, celulele de la 40-150 m urca pe
## niveluri intermediare si pierd mai mult decat castiga frustumul. Deci
## pentru triunghiuri parghia e LOD-ul mesh-urilor (MeshCpu.with_lods pe tot
## ce e reconstruit din cod), nu latura celulei.
const CELL_M: float = 250.0

## `--cell=N` pe linia de comanda suprascrie latura celulei (A/B in sonde,
## ex. ProbePerf: cat taie frustumul la 60 fata de 250). Citit o singura data.
static var _cell_override: float = -1.0

static func cell_default() -> float:
	if _cell_override < 0.0:
		_cell_override = 0.0
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--cell="):
				_cell_override = maxf(10.0, float(arg.trim_prefix("--cell=")))
	return _cell_override if _cell_override > 0.0 else CELL_M

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
		extra_key: String = "", cell_m: float = -1.0) -> String:
	if cell_m <= 0.0:
		cell_m = cell_default()
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

## PROIECTIA TRIPLANARA DE LUME iese gresit in MultiMesh cu shaderul generat
## de [StandardMaterial3D] (benzi verticale in loc de orizontale pe stancile
## rock_slab de pe Jodhpur). Pana in oct 2026 piesele astea ramaneau noduri —
## pe Jodhpur ~770 din 3554, adica peretii caselor albastre, lespezile, zidurile
## fortului: ~500 de desene pe cadru plus ~150 in pasa de umbra, partea cea mai
## mare din ce ramasese dupa coacere.
##
## CAUZA, masurata (cutie cu triplanar, nod vs MultiMesh, diff de pixeli la
## prag 0,02): rotatia si pozitia instantei ies IDENTIC (0,00%); doar scalarea
## NEUNIFORMA strica (99,8%). Pe instante MultiMesh `MODEL_NORMAL_MATRIX` nu e
## inversa transpusa a lui `MODEL_MATRIX`, nici cu `NU_SCALE` pe nod, deci
## normala dupa care triplanarul isi alege planul (si lumina) e gresita.
## Reparatia e `_mm_triplanar`: acelasi shader scris de mana, care isi
## calculeaza singur normala din `MODEL_MATRIX` (aceea include instanta) si o
## pune inapoi in NORMAL compensata, ca si lumina sa fie a nodului. Masurat:
## 0,00% fata de nod in toate cazurile, cu sau fara `NU_SCALE`.
##
## O instanta cu bazei degenerata (determinant ~0, de ex. `zidValea52`
## pe Cappadocia, scara pe Y = 0 in .tscn) nu deseneaza nimic ca nod, dar in
## MultiMesh iesea intinsa pe cer. Ramane nod, adica tot nimic.
static func _world_triplanar(m: Material) -> bool:
	var sm := m as StandardMaterial3D
	return sm != null and (sm.uv1_world_triplanar or sm.uv2_world_triplanar)


## Proprietatile pe care `_mm_triplanar` le reproduce. Orice alta proprietate
## diferita de implicit (harta de normale, emisie, transparenta...) inseamna ca
## shaderul scris de mana n-ar mai fi echivalent: piesa ramane nod, ca inainte.
const _MM_TRI_PROPS := {
	"albedo_color": true, "albedo_texture": true, "texture_filter": true,
	"vertex_color_use_as_albedo": true, "roughness": true,
	"metallic_specular": true, "uv1_triplanar": true,
	"uv1_world_triplanar": true, "uv1_scale": true, "uv1_offset": true,
	"uv1_triplanar_sharpness": true,
}

## Comutator de A/B pentru sonde: false = purtarea veche (triplanarul ramane
## nod). In joc ramane mereu true.
static var mm_triplanar_enabled: bool = true

static var _mm_tri_cache: Dictionary = {}
static var _mm_tri_shaders: Dictionary = {}
static var _std_defaults: StandardMaterial3D = null


## Echivalentul MultiMesh al unui material triplanar de lume, sau null daca
## materialul foloseste ceva ce shaderul de mai jos nu reproduce. Unul per
## material sursa, deci tot un material per clasa.
static func _mm_triplanar(m: Material) -> ShaderMaterial:
	var src := m as StandardMaterial3D
	if src == null or not src.uv1_world_triplanar or src.uv2_world_triplanar \
			or not mm_triplanar_enabled:
		return null
	var id := src.get_instance_id()
	if _mm_tri_cache.has(id):
		return _mm_tri_cache[id]
	if _std_defaults == null:
		_std_defaults = StandardMaterial3D.new()
	var ok := true
	for p in src.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE):
			continue
		var pname := String(p["name"])
		if _MM_TRI_PROPS.has(pname) or pname.begins_with("resource_") \
				or pname == "script":
			continue
		if src.get(pname) != _std_defaults.get(pname):
			ok = false
			break
	var out: ShaderMaterial = null
	if ok:
		out = ShaderMaterial.new()
		out.resource_name = src.resource_name
		out.shader = _mm_tri_shader(src.texture_filter, src.vertex_color_use_as_albedo)
		out.set_shader_parameter("albedo", src.albedo_color)
		out.set_shader_parameter("texture_albedo", src.albedo_texture)
		out.set_shader_parameter("uv1_scale", src.uv1_scale)
		out.set_shader_parameter("uv1_offset", src.uv1_offset)
		out.set_shader_parameter("uv1_blend_sharpness", src.uv1_triplanar_sharpness)
		out.set_shader_parameter("roughness", src.roughness)
		out.set_shader_parameter("specular", src.metallic_specular)
	_mm_tri_cache[id] = out
	return out


## Dupa `bake_manual`: nodurile de mesh ramase in toata pista care poarta o
## clasa triplanara convertita (`converted`, chei = id-ul materialului sursa)
## trec pe echivalent, ca clasa sa ramana un singur material. Pe nod
## echivalentul e identic la pixel (ProbeTriMultiMesh), deci nu se schimba
## nimic vizibil. MultiMesh-urile construite altundeva (padurea, CityFill) nu
## se ating: acolo shaderul lor ar schimba aspectul instantelor neuniforme.
static func unify_triplanar(root: Node, converted: Dictionary) -> int:
	if converted.is_empty():
		return 0
	var changed := 0
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.material_override != null 				and converted.has(mi.material_override.get_instance_id()):
			mi.material_override = _mm_triplanar(mi.material_override)
			changed += 1
	return changed


static func _mm_tri_shader(filter: BaseMaterial3D.TextureFilter,
		vertex_color: bool) -> Shader:
	var hint: String = {
		BaseMaterial3D.TEXTURE_FILTER_NEAREST: "filter_nearest",
		BaseMaterial3D.TEXTURE_FILTER_LINEAR: "filter_linear",
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS: "filter_nearest_mipmap",
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC: "filter_nearest_mipmap_anisotropic",
		BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC: "filter_linear_mipmap_anisotropic",
	}.get(filter, "filter_linear_mipmap")
	var key := "%s|%d" % [hint, int(vertex_color)]
	if _mm_tri_shaders.has(key):
		return _mm_tri_shaders[key]
	var sh := Shader.new()
	sh.code = _MM_TRI_CODE.replace("__FILTER__", hint) \
		.replace("__VCOLOR__", "albedo_tex *= COLOR;" if vertex_color else "")
	_mm_tri_shaders[key] = sh
	return sh


## Formula shaderului generat de StandardMaterial3D pentru triplanar de lume,
## cu o singura diferenta: normala. `transpose(inverse(mat3(MODEL_MATRIX)))`
## e normala corecta si pe nod (unde e exact `MODEL_NORMAL_MATRIX`) si pe
## instanta MultiMesh (unde `MODEL_NORMAL_MATRIX` greseste); NORMAL se rescrie
## astfel incat matricea motorului, aplicata dupa, sa dea tot normala corecta.
const _MM_TRI_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, __FILTER__, repeat_enable;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform float uv1_blend_sharpness = 1.0;
uniform float roughness = 1.0;
uniform float specular = 0.5;

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

void vertex() {
	vec3 normal = transpose(inverse(mat3(MODEL_MATRIX))) * NORMAL;
	NORMAL = inverse(MODEL_NORMAL_MATRIX) * normal;
	uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	__VCOLOR__
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = 0.0;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
"""

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
	# Triplanarul de lume se strica in buffer DOAR pe instantele scalate
	# neuniform (vezi `_mm_triplanar`); numai grupurile alea primesc shaderul
	# echivalent. Restul pastreaza materialul clasei, deci clasa nu apare de
	# doua ori: aceleasi materiale le poarta deja MultiMesh-urile padurii si ale
	# CityFill, iar pe Kyoto (Track18) o conversie a tuturor grupurilor urca
	# numarul de materiale de la 37 la 55, peste plafonul de 38 al garzii.
	#
	# O clasa convertita trece INTREAGA pe echivalent — si grupurile ei
	# uniforme, si nodurile ramase (`unify_triplanar`) — altfel ar aparea de
	# doua ori (pe Kyoto: `stone_wall` si `macchia`, 39 de materiale).
	var converted := {}
	for key in groups:
		var g: Dictionary = groups[key]
		if bool(g.get("nu", false)) and _world_triplanar(g["mat"]) 				and _mm_triplanar(g["mat"]) != null:
			converted[(g["mat"] as Material).get_instance_id()] = true
	for key in groups:
		var g: Dictionary = groups[key]
		if converted.has((g["mat"] as Material).get_instance_id()):
			g["mat"] = _mm_triplanar(g["mat"])
	var holder := Node3D.new()
	holder.name = "Batched"
	dm.add_child(holder)
	var instances := _emit(groups, holder, null)
	return {
		"instances": instances,
		"batches": groups.size(),
		"hidden": sources.size(),
		"tri_converted": converted,
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
		var cell_m := cell_default()
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
	if _world_triplanar(mi.material_override) \
			and _mm_triplanar(mi.material_override) == null:
		return false
	if absf(mi.global_transform.basis.determinant()) <= 1e-6:
		return false
	var world := mi.global_transform * mi.get_aabb()
	for box: AABB in lights:
		if box.intersects(world):
			return false
	return true
