class_name MeshCpu
extends RefCounted
## Citirile de mesh-uri de pe GPU, refolosite cat dureaza constructia unei piste
## (timpul de incarcare, oct 2026).
##
## Cu randare reala, `surface_get_arrays` nu e o citire de memorie: aduce
## bufferul inapoi de pe GPU si opreste totul pana termina placa video (cateva
## milisecunde pe citire). In --headless bufferele stau in memorie, deci costul
## se vede doar cu fereastra. Doua surse de citiri inutile:
##
##   - acelasi model importat (.glb) citit de fiecare instanta a lui: aici se
##     citeste o data si se refoloseste (`surface_arrays`);
##   - cititorii care vor doar POZITIILE unui mesh pe care l-am urcat chiar noi
##     (discurile de umbra de sub decor, razele hornului): pozitiile trec prin
##     GPU neatinse, deci se tin pe CPU de la urcare (`add_surface`) si nu se
##     mai citesc deloc (`vertices`).
##
## De ce NU si restul array-urilor unui mesh urcat de noi. Drumul pana la GPU si
## inapoi le schimba: culorile se trunchiaza la 8 biti, iar normalele si
## tangentele trec printr-o codare octaedrica pe 16 biti care nici macar nu e
## idempotenta. S-a incercat emularea ei exacta in GDScript (iese la bit, dar):
## pe Cappadocia costa 16,7 s fata de 6,5 s cu citirile reale — calculul pe
## fiecare vertex e mai scump decat sincronizarile pe care le evita.
##
## Activ doar intre `begin()` si `end()` (Track: din _enter_tree pana dupa
## rebuild) si doar in cadrul de proces in care a pornit: constructia e un
## singur apel sincron, deci o eroare la jumatatea ei nu poate lasa registrul
## deschis peste cadrele urmatoare. In afara lui, totul merge direct la GPU.
##
## Garda: tools/ProbeMeshCpu.tscn compara fiecare raspuns din registru cu o
## citire reala, pe toate pistele.

## RID-ul mesh-ului -> Array cu array-urile citite ale fiecarei suprafete.
static var _arrays: Dictionary = {}
## RID-ul mesh-ului -> Array cu pozitiile fiecarei suprafete urcate de noi.
static var _verts: Dictionary = {}
## RID-ul mesh-ului -> Array cu LOD-urile citite ale fiecarei suprafete.
static var _lods: Dictionary = {}
## Rezultate refolosite pe durata unei constructii (ex. perechile rupte de
## `Palette.split_accents`, pe mesh sursa): instantele aceluiasi GLB impart
## mesh-ul, deci ruperea si LOD-urile se fac o data, nu pe fiecare instanta.
static var build_cache: Dictionary = {}

## Unghiurile de generare a LOD-urilor — cele ale importerului GLB (unire la
## 60°, separare la 25°). Scrise invers (25, 60), coroanele de foi si fatadele
## abia se simplificau (momiji_c: 2696 -> 868 fara nivel mediu; cu ordinea
## corecta 2696 -> 806 -> 188).
const LOD_MERGE_DEG: float = 60.0
const LOD_SPLIT_DEG: float = 25.0
static var _active: bool = false
static var _frame: int = -1

## Mod de control: fiecare raspuns din registru se compara la bit cu o citire
## reala de pe GPU. Doar pentru sonde — anuleaza tot castigul.
static var verify: bool = false
static var verify_checked: int = 0
static var verify_mismatch: int = 0
static var verify_first: String = ""


static func begin() -> void:
	_arrays.clear()
	_verts.clear()
	_lods.clear()
	build_cache.clear()
	_active = true
	_frame = Engine.get_process_frames()


static func end() -> void:
	_active = false
	_arrays.clear()
	_verts.clear()
	_lods.clear()
	build_cache.clear()


static func _on() -> bool:
	if not _active:
		return false
	if Engine.get_process_frames() != _frame:
		end()
		return false
	return true


## Ce ar intoarce `mesh.surface_get_arrays(s)`.
##
## O copie ADANCA: apelantii scriu in array-urile primite (`verts[i] = v`), iar
## un Packed*Array tinut intr-un Array se transmite PRIN REFERINTA — cu o copie
## superficiala, `_erode_arch` isi deforma vertecsii direct in registru (prins
## de ProbeMeshCpu). Copia adanca nu muta date: vectorul se copiaza abia la
## prima scriere.
static func surface_arrays(mesh: Mesh, s: int) -> Array:
	if not _on():
		return mesh.surface_get_arrays(s)
	var key := mesh.get_rid()
	var surfs: Array = _arrays.get(key, [])
	if s < surfs.size() and surfs[s] != null:
		var hit: Array = surfs[s]
		if verify:
			_check(var_to_bytes(hit), var_to_bytes(mesh.surface_get_arrays(s)), mesh)
		return hit.duplicate(true)
	var arr := mesh.surface_get_arrays(s)
	_store(_arrays, key, mesh.get_surface_count(), s, arr)
	return arr.duplicate(true)


## Doar pozitiile suprafetei `s` — fara citire de pe GPU daca mesh-ul a fost
## urcat prin `add_surface` sau citit deja.
static func vertices(mesh: Mesh, s: int) -> PackedVector3Array:
	if _on():
		var key := mesh.get_rid()
		var surfs: Array = _verts.get(key, [])
		if s < surfs.size() and surfs[s] != null:
			var hit: PackedVector3Array = surfs[s]
			if verify:
				_check(var_to_bytes(hit),
					var_to_bytes(mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]), mesh)
			return hit.duplicate()
	var arr := surface_arrays(mesh, s)
	if arr.size() <= Mesh.ARRAY_VERTEX or not arr[Mesh.ARRAY_VERTEX] is PackedVector3Array:
		return PackedVector3Array()
	return arr[Mesh.ARRAY_VERTEX]


## `mesh.add_surface_from_arrays(TRIANGLES, arrays, [], lods)`, tinand minte
## pozitiile. `lods` (lungime de muchie -> indici) vine din `surface_lods` cand
## indicii raman ai sursei, sau din `generated_lods` cand s-au schimbat.
static func add_surface(mesh: ArrayMesh, arrays: Array, lods: Dictionary = {}) -> void:
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], lods)
	if not _on():
		return
	var v: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not v is PackedVector3Array:
		return
	# Copie: apelantul poate scrie mai departe in array-ul lui.
	_store(_verts, mesh.get_rid(), mesh.get_surface_count(),
		mesh.get_surface_count() - 1, (v as PackedVector3Array).duplicate())


## LOD-urile suprafetei `s` (lungime de muchie -> indici), asa cum le-a scris
## importerul GLB, ca o copie a mesh-ului cu ACEIASI indici (UV mutate pe alt
## slot, culori intunecate) sa le poarte mai departe. O copie facuta fara ele
## se deseneaza la detaliu intreg la orice distanta: pe Jodhpur peretii rupti
## ai caselor albastre (169 de case, 3.150-3.918 tri fiecare) n-aveau niciun
## LOD si erau cea mai mare parte a cadrului (ProbePerf --attrib, 27 oct 2026).
## `mesh_get_surface` e o citire de pe GPU, deci trece prin registru.
static func surface_lods(mesh: Mesh, s: int) -> Dictionary:
	var key := mesh.get_rid()
	if _on():
		var surfs: Array = _lods.get(key, [])
		if s < surfs.size() and surfs[s] != null:
			return (surfs[s] as Dictionary).duplicate()
	var out := {}
	var d := RenderingServer.mesh_get_surface(key, s)
	var lods: Array = d.get("lods", [])
	var index_count := int(d.get("index_count", 0))
	var index_data: PackedByteArray = d.get("index_data", PackedByteArray())
	if not lods.is_empty() and index_count > 0 and index_data.size() > 0:
		# Indicii sunt pe 16 sau pe 32 de biti dupa numarul de vertecsi; latimea
		# se citeste din bufferul de baza, nu se ghiceste.
		var bpi := index_data.size() / index_count
		for l in lods:
			var bytes: PackedByteArray = l["index_data"]
			var idx := PackedInt32Array()
			if bpi == 4:
				idx = bytes.to_int32_array()
			else:
				idx.resize(bytes.size() / 2)
				for i in idx.size():
					idx[i] = bytes.decode_u16(i * 2)
			out[float(l["edge_length"])] = idx
	if _on():
		_store(_lods, key, mesh.get_surface_count(), s, out.duplicate())
	return out


## LOD-uri generate (meshoptimizer, ca la import) pentru array-urile unei
## suprafete cu indici noi: ruperea accentelor, mesh-urile unite din cod
## (bazar, terase, ziduri de var). Fara indici nu se poate genera nimic.
static func generated_lods(arrays: Array) -> Dictionary:
	var out := {}
	if arrays.size() <= Mesh.ARRAY_INDEX or arrays[Mesh.ARRAY_INDEX] == null \
			or (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
		return out
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	im.generate_lods(LOD_MERGE_DEG, LOD_SPLIT_DEG, [])
	for li in im.get_surface_lod_count(0):
		out[im.get_surface_lod_size(0, li)] = im.get_surface_lod_indices(0, li)
	return out


## Copia unui mesh (de obicei iesit dintr-un SurfaceTool) cu LOD-uri generate pe
## fiecare suprafata; suprafetele neindexate se indexeaza intai (sudura pe
## vertex identic), altfel generatorul nu are pe ce lucra. Materialele raman.
static func with_lods(src: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := surface_arrays(src, s)
		if arrays[Mesh.ARRAY_INDEX] == null:
			var st := SurfaceTool.new()
			st.create_from(src, s)
			st.index()
			arrays = st.commit_to_arrays()
		add_surface(out, arrays, generated_lods(arrays))
		var m := src.surface_get_material(s)
		if m != null:
			out.surface_set_material(s, m)
	return out


static func _store(reg: Dictionary, key: RID, count: int, s: int, val: Variant) -> void:
	var surfs: Array = reg.get(key, [])
	if surfs.size() < count:
		surfs.resize(count)
	surfs[s] = val
	reg[key] = surfs


static func _check(got: PackedByteArray, real: PackedByteArray, mesh: Mesh) -> void:
	verify_checked += 1
	if got == real:
		return
	verify_mismatch += 1
	if verify_first.is_empty():
		verify_first = "%s difera" % mesh.resource_path
