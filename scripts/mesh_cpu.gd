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
	_active = true
	_frame = Engine.get_process_frames()


static func end() -> void:
	_active = false
	_arrays.clear()
	_verts.clear()


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


## `mesh.add_surface_from_arrays(TRIANGLES, arrays)`, tinand minte pozitiile.
static func add_surface(mesh: ArrayMesh, arrays: Array) -> void:
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if not _on():
		return
	var v: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not v is PackedVector3Array:
		return
	# Copie: apelantul poate scrie mai departe in array-ul lui.
	_store(_verts, mesh.get_rid(), mesh.get_surface_count(),
		mesh.get_surface_count() - 1, (v as PackedVector3Array).duplicate())


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
